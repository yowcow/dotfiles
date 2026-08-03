# Base-Branch trailer

The `Base-Branch:` trailer is a **shared mechanism with one writer and two readers**. `implement-work` writes it when it cuts a branch; `pr-to-ready` reads it to pass as `gh pr create --base`; `review-code` reads it as the base of the range it reviews. Neither reader derives the base again — the decision is made once, by the writer, from the relation as it stood when the branch was cut.

This file holds the contract and the reasons. The commands, and how each command's result is tested, stay in each skill's own `SKILL.md`: a session that never reads this file must still not take a wrong branch. What is lost by skipping this file is only the understanding of *why* a test is written that way.

## The contract

A single `Base-Branch: <base>` line in the trailer block of the task's **first** commit. `<base>` is the bare branch name — no `origin/` prefix, no `refs/heads/` path — because both readers parse this exact form.

Branching from the default branch records **nothing**. That absence is what tells both readers to fall back to the default branch, so it is a value, not an omission.

## Why the first commit

The branch's history only grows from the first commit, and both readers scan it from the tip backwards, stopping at the first hit. A trailer added on a later commit would therefore shadow the first one for a task stacked on top of this branch.

## Resolving the default branch

Never guess a branch name. Three rungs, in order — `git symbolic-ref`, then `gh repo view`, then ask the user:

```bash
git symbolic-ref refs/remotes/origin/HEAD    # exit 0 prints the ref; with --short, the bare origin/<default>
gh repo view --json defaultBranchRef         # with --jq '.defaultBranchRef.name', the bare name
```

A non-zero exit from `symbolic-ref` means the remote HEAD is not set in this checkout, **not** that there is no default branch: fall to `gh repo view`, and if that fails too, ask.

**The exact flags differ by caller, and that difference is intentional rather than drift.** `pr-to-ready` compares the result against a branch name, so it needs the bare name: it takes `--short` and `--jq '.defaultBranchRef.name'`, and strips the `origin/` prefix before comparing. `review-code` only needs the branch to resolve a range, so it pins neither flag. Each skill keeps its own form in its own `SKILL.md`; what is shared, and what this file fixes, is the three-rung order and the rule never to guess a branch name.

## Reading the trailer back

Both readers scan from a tip backwards and take the first trailer found. Where a stack runs deeper than one, the nearest one wins — an earlier task's trailer sits further back in the same history.

When a trailer is found, check whether its branch survives:

```bash
git ls-remote --exit-code --heads origin <recorded>   # 0 = still there, 2 = gone
```

Any other non-zero exit is a network or auth failure rather than absence, and it stops the run. Reading it as "gone" would silently widen the range or retarget the PR to the default branch — the one outcome the trailer exists to prevent.

Three outcomes:

- **no trailer** → the default branch. This is the ordinary unstacked case, and the absence of a trailer is what says so.
- **trailer found, branch still on the remote** → that branch.
- **trailer found, branch gone** → the default branch. That prerequisite is finished with, and its commits are in the default branch already.

### `pr-to-ready` — scan `FETCH_HEAD`

```bash
git fetch --quiet origin <branch>                                                   # 0 = fetched; non-zero = stop
trailers="$(git log --format='%(trailers:key=Base-Branch,valueonly)' FETCH_HEAD)"    # 0 = history read; non-zero = stop
printf '%s\n' "$trailers" | grep -m1 .                                              # 0 = recorded base on stdout, 1 = no trailer
```

It scans `FETCH_HEAD` rather than a local ref because a session entered without the branch checked out has no local ref for it, and the history that matters is the pushed one the PR will be opened from.

### `review-code` — scan local `HEAD`

```bash
trailers="$(git log --format='%(trailers:key=Base-Branch,valueonly)' HEAD)"   # 0 = history read; non-zero = stop
printf '%s\n' "$trailers" | grep -m1 .                                       # 0 = recorded base on stdout, 1 = no trailer
```

It scans `HEAD` because it reviews the checkout it is in, so the history it must read is the local one.

Everything in the rest of this subsection concerns `review-code` alone: `pr-to-ready` passes `<recorded>` to `--base` as a literal branch name and never resolves it to a ref, so none of it bears on that skill. When `review-code` finds a trailer whose branch survives, the base it reviews from is **`FETCH_HEAD`** after `git fetch origin <recorded>`, not `origin/<recorded>`. Stop the run if that fetch exits non-zero rather than going on to use the ref, since a failed fetch leaves whatever `origin/<recorded>` a previous fetch wrote sitting at its old commit. And take `FETCH_HEAD` even when the fetch succeeds: `git fetch` always writes it, whereas updating `origin/<recorded>` depends on the repository's `remote.origin.fetch` refspec — in a single-branch or otherwise narrowed clone the fetch exits 0 and `origin/<recorded>` is never created at all. Either way, resolving the base to a stale or missing ref quietly widens the range.

### Why the two readers differ

The difference is intentional, not duplication — the two subsections above give the reason for each. Each skill keeps its own command in its own `SKILL.md` for that reason.

## Why the reads are captured before they are tested

Capture `git log` into a variable before testing it, rather than piping straight into `grep`. A pipe reports only `grep`'s status, and `grep` exits 1 on empty input whether the trailer is genuinely absent or `git log` just failed — so the two are indistinguishable. `set -o pipefail` does not separate them either: `grep` is the rightmost command and its 1 is a real exit code, not a masked one.

The same trap sits one line up in `pr-to-ready`'s form: a failed fetch (bad ref, auth, network) truncates `FETCH_HEAD` to empty, which then makes the scan exit 1 as well. Reading either as "no trailer" would fall back to the default branch — opening the PR against the wrong target, or widening the reviewed range to sweep in a prerequisite's commits.

## Why the branch-lookup tests are written the way they are

- **`grep -Fxq "branch refs/heads/<branch>"` — `-F` and `-x` are load-bearing, and they replace the `^`/`$` anchors rather than joining them.** A branch name may contain `.`, which as a regex matches any character, so an anchored pattern can match a *different* branch and hand back the wrong workspace.
- **`git branch --list` exits 0 whether or not it matched**, so branching on its exit status is always true. Use `git show-ref --verify --quiet refs/heads/<branch>`, or test output emptiness: `[ -n "$(git branch --list <branch>)" ]`.
- **A branch that exists only on the remote must be attached, not recreated.** A resumed task whose branch was already pushed, in a session or a checkout that never held it locally, has no local ref; creating one afresh would start it from the default branch, diverge from the pushed branch under the same name, and have its first push rejected as a non-fast-forward. Since force-pushing is barred, the earlier work would be stranded rather than resumed.
- **Prerequisites are tested by count, not presence.** `blockedBy` and `closedByPullRequestsReferences` both come back as `{nodes, totalCount}`, so "is it empty" cannot tell one prerequisite from three.
- **A PR's state is tested by `state`, not by "not merged".** `OPEN`, `CLOSED`, `MERGED` are three cases: a PR closed without merging means abandoned work rather than work still in flight.
- **The stop rows stop rather than falling through to the default branch.** Falling through makes an unimplemented or abandoned prerequisite indistinguishable from an independent task — and that only surfaces later, as a failure whose cause is not in the diff.
- **A task stacked on a prerequisite whose PR is still `OPEN` must branch from that PR's head.** Branch from the default instead and the prerequisite's changes are simply absent, so the task's own checks fail for a reason that is nowhere in its diff.
