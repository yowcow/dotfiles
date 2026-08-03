---
name: review-code
description: Use to review code and fix what the review finds — on a diff, a branch, or an uncommitted working tree — running the review-fix-review loop until no blocking finding remains. Resolves what to review itself, dispatches a read-only reviewer, judges its findings, applies the accepted fixes, and verifies them. Triggers on "review this code", "review and fix this", "run the review loop until it's clean".
---

# Review Code

Use on code in any state — a diff just written, a branch, or an uncommitted working tree.

One invocation runs the loop to completion: review, judge, fix, verify, review again, until no blocking finding remains. What it does not own is re-entry — reviewing again after something else changes the code belongs to the caller; in the Change workflow, `implement-work`'s completion gate owns that. The name pairs with `review-plan`, but the shape differs: `review-plan` is one pass with the loop outside it, this skill owns its loop.

## Orchestration model

**This skill dispatches one worker: a read-only reviewer.** Everything else runs in the main loop.

- The orchestrator owns the loop: it resolves the scope, dispatches the reviewer, judges findings, applies accepted fixes, verifies, and decides when the loop ends. A reviewer never declares the code clean.
- The reviewer is a read-only worker, dispatched through `superpowers:requesting-code-review`. It gets the scope and the requirements and returns findings only. It never edits code, never runs the project's checks, and never commits.
- What a read-only worker buys is a fresh context: it reads the code without having written it, so it is not anchored on why the code ended up this way. `simplify-code`'s proposers are dispatched on the same contract, for the same reason.

## Boundaries

- This skill applies fixes but never commits — commits are the caller's.
- Simplification belongs to `simplify-code`; don't fold it in here.
- GitHub-side review — Claude and Copilot on a PR, thread replies, thread resolution — belongs to `pr-to-ready`. Report each round to the caller in chat and never to GitHub, per the guidelines' **Stage boundaries**.

## Scope

Resolve what to review in this order, and declare the resolved scope before dispatching anything:

1. **Caller-supplied** — a SHA range, paths, or a PR. Use it as given.
2. **Uncommitted changes present** — the working tree diff: staged, unstaged, and untracked files.
3. **Clean tree, commits ahead of `<base>`** — the range is `merge-base(<base>, HEAD)..HEAD`, and `<base>` is resolved, not assumed: `implement-work` records a non-default base as a `Base-Branch:` trailer when it cuts a branch from a prerequisite's still-open PR. The contract, the reason each test below is written the way it is, and what a wrong `<base>` costs are all in `<skills-dir>/implement-work/references/base-branch.md` — `<skills-dir>` being wherever your runtime installs skills (e.g. `~/.claude/skills`, `~/.agents/skills`). The commands stay here, so a session that never opens that file still resolves the right base.

   Scan local `HEAD` — this skill reviews the checkout it is in — from the tip backwards, first hit wins. **Capture the `git log` before testing it, rather than piping straight into `grep`:**

   ```bash
   trailers="$(git log --format='%(trailers:key=Base-Branch,valueonly)' HEAD)"   # 0 = history read; non-zero = stop
   printf '%s\n' "$trailers" | grep -m1 .                                        # 0 = recorded base on stdout, 1 = no trailer
   ```

   When a trailer was found, check whether its branch survives:

   ```bash
   git ls-remote --exit-code --heads origin <recorded>   # 0 = still there, 2 = gone; any other non-zero = stop, it is a network or auth failure
   ```

   Two outcomes decide `<base>`:
   - trailer found and its branch still on the remote → `git fetch origin <recorded>` (non-zero = stop), then `<base>` is **`FETCH_HEAD`**, not `origin/<recorded>`;
   - no trailer, or its branch is gone → `<base>` is the default branch. Resolve it rather than assuming `main`, three rungs in order: `git symbolic-ref refs/remotes/origin/HEAD` (0 = prints the ref; non-zero = fall to the next rung, it does not mean there is no default branch), then `gh repo view --json defaultBranchRef`, then ask. Never guess a branch name.

   If the range turns out empty — HEAD is already at `<base>` — fall through to 4.
4. **Nothing to review** — no uncommitted change and no commit ahead of the `<base>` that item 3 resolved. Ask the user what to review. Never widen to the whole repository on a guess.

## Reviewer prompt

Fill the `code-reviewer.md` template that `superpowers:requesting-code-review` provides:

- **Committed range** — fill `[BASE_SHA]` and `[HEAD_SHA]` as the template expects.
- **Uncommitted scope** — replace the template's **Git Range to Review** block with the commands that show the same thing: `git status --porcelain`, `git diff`, `git diff --cached`, and the untracked paths. Keep the read-only rule, and drop the template's temporary-worktree suggestion — a worktree at any revision does not contain uncommitted changes. The reviewer reads the files in place and still must not mutate the working tree, the index, HEAD, or branch state.
- **Paths with no range** — the caller named files or directories rather than revisions. Replace the range block with those paths and say the review covers their current state on this checkout, not a diff. Say the same in the report: nothing constrains the review to recent change, so the findings may be about code this work never touched.
- **A PR** — resolve it to the range it represents (`gh pr view <n> --json baseRefOid,headRefOid`) and fill the range block from that. Reviewing the PR's diff locally is this skill's job; posting anything to the PR is not — that belongs to `pr-to-ready`.
- **What was implemented** — fill `[DESCRIPTION]` with a summary of the resolved scope: what the change does, or for a paths-only scope what the code is for. Never leave the placeholder in the dispatched prompt.
- **Requirements** — fill `[PLAN_OR_REQUIREMENTS]` with the plan or the original request. When there is none, say so in the prompt: the review runs against the repository's own standards and the code's evident intent. Say it in the report too, so a reader knows plan alignment was not checked.
- **Later rounds** — hand over the record of the previous rounds: findings accepted and fixed, and findings rejected with the reason. A reviewer not shown the rejections re-litigates them.

Confine every search to the project root or narrower.

## Pass

One invocation is one pass, and a pass is as many rounds as it takes:

1. Resolve the scope per **Scope** and declare it.
2. Dispatch one reviewer with the code as it now stands. One reviewer per round, fresh each round — the fan-out is sized to the diff, per the guidelines' **Subagents & worker safety**.
3. Judge every finding with `superpowers:receiving-code-review`: verify the claim against the code before accepting it, and reject — with a stated reason — findings that are wrong, that only reflect reviewer preference, or that ask for work beyond the request.
4. Apply the accepted Critical and Important findings yourself — except one that invalidates the approved design, which is not fixed here at all: stop the pass, per **Escalation**. When a finding describes a bug, write the failing regression test first and watch it fail, then fix it (`superpowers:test-driven-development`). Record Minor findings; don't fix them.
5. Verify with the concrete commands the project defines — in the README, Makefile, package scripts, or CI — and read their actual output.
6. Return to step 2 while a blocking finding remains, subject to **Escalation**.
7. Report per **Report**.

A round is one review → judge → fix → verify cycle. The pass is clean when a round's review produces no Critical or Important finding. Minor findings are recorded, not blocking.

## Escalation

- Five rounds at most. If the fifth round's review still produces blocking findings, apply and verify them as usual, then stop instead of starting a sixth review: report those fixes as applied but not re-reviewed, along with the disagreement, and let the user decide. Never report clean on the strength of fixes no review has seen.
- A Critical finding that invalidates the approved design is not fixed in this loop. It ends the pass, and what this pass hands over is the finding itself, reported separately from the ordinary verdict so the caller routes it rather than reading the pass as merely unfinished. The guidelines' **Escalation** owns where it goes.

## Report

- the scope reviewed and how it was resolved, including whether requirements were available
- the number of rounds run
- accepted findings, with location and what changed
- rejected findings, with the reason
- the remaining Minor findings
- what verification ran, and its actual result
- the verdict: clean, or the blocking findings that remain — flagging separately any Critical finding that invalidates the approved design, per **Escalation**
