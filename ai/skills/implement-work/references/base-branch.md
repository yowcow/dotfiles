# Base-Branch trailer

The `Base-Branch:` trailer is a **shared mechanism with one writer and two readers**. `implement-work` writes it when it cuts a branch; `pr-to-ready` reads it to settle `gh pr create --base`; `review-code` reads it as the base of the range it reviews. **What the trailer records is which prerequisite the branch sits on, and only that.** Whether that prerequisite is still in flight is not recorded and could not be — time passes between cutting the branch and reading the trailer. So neither reader re-derives *which* prerequisite it is; both re-read *what state it is now in*, and settle the base from that.

This file holds the contract and the reasons. The snippets below illustrate them; the command a skill actually runs belongs in that skill's `scripts/`.

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

**The exact flags differ by caller, and that difference is intentional rather than drift.** `pr-to-ready` compares the result against a branch name, so it needs the bare name: it takes `--short` and `--jq '.defaultBranchRef.name'`, and strips the `origin/` prefix before comparing. `review-code` only needs the branch to resolve a range, so it pins neither flag. Each skill's own form belongs in its own `scripts/`; what is shared, and what this file fixes, is the three-rung order and the rule never to guess a branch name.

## Reading the trailer back

Both readers scan from a tip backwards and take the first trailer found. Where a stack runs deeper than one, the nearest one wins — an earlier task's trailer sits further back in the same history.

When a trailer is found, look the prerequisite's PR up by its head branch name:

```bash
gh pr list --head <recorded> --state all --json number,state --jq '.[] | "\(.number) \(.state)"'
```

Take **the exit status and the line count together**, and print every match with `.[]` rather than indexing `.[0]`. Neither signal settles anything on its own. A `gh` failure — auth, network, repo context — prints nothing and exits non-zero, which looks exactly like "no PR", so a non-zero exit is "couldn't tell" and stops the run instead of falling through to a base. And `.[0]` would pick one of several PRs arbitrarily, or interpolate `null` as text where there is none, producing non-empty output that reads as a match.

That gives four readings: non-zero = stop; zero lines = no PR found; one line = the number and the state; two or more = the branch carries more than one PR.

The base then follows from that state:

| trailer / prerequisite PR state | `review-code`'s `<base>` | `pr-to-ready`'s `--base` |
| --- | --- | --- |
| no trailer | the default branch | omit |
| `OPEN` | `git fetch origin <recorded>`, then `FETCH_HEAD` | `<recorded>` |
| `MERGED` | `git fetch origin refs/pull/<n>/head`, then `FETCH_HEAD` | the default branch — omit `--base`, and retarget an existing PR that still points at `<recorded>` |
| `CLOSED` without merging | **stop** | **stop** |
| no PR found | **stop** and report it | **stop** and report it |
| two or more PRs | **stop and ask** | **stop and ask** |

`<n>` is the PR number the lookup printed beside the state. The no-trailer row needs no lookup: the absence of a trailer is itself the answer, as **The contract** says.

The last two rows both stop, and they differ in what they put to the person. No PR on the recorded branch leaves the base unknowable, so there is nothing to choose between and the run reports what it found — the same answer `implement-work`'s writer-side table gives an unimplemented prerequisite. Two or more PRs leaves a genuine choice: the trailer already fixed *which* prerequisite this is, so what is open is which of that one branch's PR records the base should follow. That one asks.

### Why the state is re-read and the branch is not

The test this replaced asked `git ls-remote --exit-code --heads origin <recorded>` — whether the branch still exists. That is the wrong question, because nothing ties a branch's existence to its PR's state:

- `deleteBranchOnMerge` is false here, so merging never deletes the prerequisite's branch. Deleting it is a person's step, taken whenever they get round to it. So a surviving branch may be long merged, and a vanished one proves only that somebody tidied up.
- Read as "still in flight", a surviving merged branch hands `pr-to-ready` that branch as `--base`. Merging a PR into an already-merged branch puts nothing into the default branch, so the change silently fails to land.
- Read as "finished with", a vanished branch sent `review-code` to the default branch — and **that leg was wrong on its own terms**, which is the failure that actually bites. Squash and rebase merges rewrite the prerequisite's commits under fresh SHAs, so the SHAs this branch's history carries are nowhere in the default branch. `merge-base(<default>, HEAD)` therefore lands *below* the prerequisite and sweeps its commits into the reviewed range. Squash merge is the ordinary operation in this repository, so this is the common case rather than an edge one.

Keying on state answers both at once, and it needs no branch to exist: the lookup is by head branch *name*, which the PR record keeps after the branch is gone.

### Why the `MERGED` row's base is `refs/pull/<n>/head`

- **It bounds the range whatever the merge strategy was.** Taking the prerequisite's own head leaves the range holding exactly this task's commits, whether the prerequisite went in squashed, rebased, or as a merge commit. In the merge-commit case that point coincides with `merge-base(<default>, HEAD)`, so the rule does not degrade where the old one happened to work.
- **It is the one form that always resolves.** `refs/pull/<n>/head` outlives both the merge and the branch's deletion, so a single row covers a surviving branch and a deleted one alike. It also takes the same "fetch, then `FETCH_HEAD`" shape as the `OPEN` row, so that row's reason for `FETCH_HEAD` over a remote-tracking ref carries over. The default refspec does not fetch this ref, so the fetch must name it explicitly, and a non-zero fetch stops the run.

### Why the writer and the readers answer `MERGED` differently

`implement-work`'s **Base branch** table sends a task whose prerequisite is already `MERGED` to the default branch and records no trailer at all, while the table above sends `MERGED` to the prerequisite's head. That is not a contradiction, because the two are reading different histories. A branch cut from the default branch *after* the merge has every one of its commits ahead of it. A branch cut while the prerequisite was still `OPEN` carries the prerequisite's commits inside its own history, and the prerequisite merging later does not remove them. Different history, different correct base — so the writer-side table stands as it is.

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

Everything in the rest of this subsection concerns `review-code` alone: on the single row where `pr-to-ready` uses `<recorded>` at all, it passes it to `--base` as a literal branch name and never resolves it to a ref, so none of this bears on that skill. Both of `review-code`'s fetching rows resolve `<base>` to **`FETCH_HEAD`**, never to `origin/<recorded>`. Stop the run if the fetch exits non-zero rather than going on to use a ref, since a failed fetch leaves whatever `origin/<recorded>` a previous fetch wrote sitting at its old commit. And take `FETCH_HEAD` even when the fetch succeeds: `git fetch` always writes it, whereas updating `origin/<recorded>` depends on the repository's `remote.origin.fetch` refspec — in a single-branch or otherwise narrowed clone the fetch exits 0 and `origin/<recorded>` is never created at all. On the `MERGED` row there is not even a ref to fall back on in principle, since `refs/pull/<n>/head` sits outside that refspec in every clone. Either way, resolving the base to a stale or missing ref quietly widens the range.

### Why the two readers differ

The difference is intentional, not duplication — the two subsections above give the reason for each. Each skill's own command belongs in its own `scripts/` for that reason.

## Why the reads are captured before they are tested

Capture `git log` into a variable before testing it, rather than piping straight into `grep`. A pipe reports only `grep`'s status, and `grep` exits 1 on empty input whether the trailer is genuinely absent or `git log` just failed — so the two are indistinguishable. `set -o pipefail` does not separate them either: `grep` is the rightmost command and its 1 is a real exit code, not a masked one.

The same trap sits one line up in `pr-to-ready`'s form: a failed fetch (bad ref, auth, network) truncates `FETCH_HEAD` to empty, which then makes the scan exit 1 as well. Reading either as "no trailer" would fall back to the default branch — opening the PR against the wrong target, or widening the reviewed range to sweep in a prerequisite's commits.

## Why the lookups are tested the way they are

- **`grep -Fxq "branch refs/heads/<branch>"` — `-F` and `-x` are load-bearing, and they replace the `^`/`$` anchors rather than joining them.** A branch name may contain `.`, which as a regex matches any character, so an anchored pattern can match a *different* branch and hand back the wrong workspace.
- **`git branch --list` exits 0 whether or not it matched**, so branching on its exit status is always true. Use `git show-ref --verify --quiet refs/heads/<branch>`, or test output emptiness: `[ -n "$(git branch --list <branch>)" ]`.
- **A branch that exists only on the remote must be attached, not recreated.** A resumed task whose branch was already pushed, in a session or a checkout that never held it locally, has no local ref; creating one afresh would start it from the default branch, diverge from the pushed branch under the same name, and have its first push rejected as a non-fast-forward. Since force-pushing is barred, the earlier work would be stranded rather than resumed.
- **A prerequisite is counted, never merely detected.** `blockedBy` and `closedByPullRequestsReferences` come back as `{nodes, totalCount}`, and the readers' `gh pr list` prints one line per match. In both forms "is it empty" cannot tell one prerequisite from three — only a count separates the single case that may proceed from the two that stop.
- **A PR's state is tested by `state`, and it has three values.** `OPEN`, `CLOSED` and `MERGED` are three cases, so "not merged" collapses the two that need opposite answers: a PR closed without merging is abandoned work, not work still in flight. This binds both sides of the mechanism — the writer reads `state` to choose what to branch from, and both readers read it to choose the base.
- **The stop rows stop rather than falling through to the default branch.** Falling through makes an unimplemented, abandoned, or ambiguous prerequisite indistinguishable from an independent task — and that surfaces only later, as a failure whose cause is nowhere in the diff. Both tables carry stop rows, for that one reason.
- **A task stacked on a prerequisite whose PR is still `OPEN` must branch from that PR's head.** Branch from the default instead and the prerequisite's changes are simply absent, so the task's own checks fail for a reason that is nowhere in its diff.
