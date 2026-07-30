---
name: review-code
description: Use to review code and fix what the review finds — on a diff, a branch, or an uncommitted working tree — running the review-fix-review loop until no blocking finding remains. Resolves what to review itself, dispatches a read-only reviewer, judges its findings, applies the accepted fixes, and verifies them. Triggers on "review this code", "review and fix this", "run the review loop until it's clean".
---

# Review Code

Use on code in any state — a diff just written, a branch, or an uncommitted working tree.

One invocation runs the loop to completion: review, judge, fix, verify, review again, until no blocking finding remains. What it does not own is re-entry — reviewing again after something else changes the code belongs to the caller; in the Change workflow, `implement-work`'s completion gate owns that. The name pairs with `review-plan`, but the shape differs: `review-plan` is one pass with the loop outside it, this skill owns its loop.

## Roles

- The orchestrator owns the loop: it resolves the scope, dispatches the reviewer, judges findings, applies accepted fixes, verifies, and decides when the loop ends. A reviewer never declares the code clean.
- The reviewer is a read-only worker, dispatched through `superpowers:requesting-code-review`. It gets the scope and the requirements and returns findings only. It never edits code, never runs the project's checks, and never commits.
- What a reviewer buys is a fresh context: it reads the code without having written it, so it is not anchored on why the code ended up this way.

## Boundaries

- This skill applies fixes but never commits — commits are the caller's.
- Simplification belongs to `simplify-code`; don't fold it in here.
- GitHub-side review — Claude and Copilot on a PR, thread replies, thread resolution — belongs to `pr-to-ready`. Report to the caller in chat and never post to GitHub: a loop's intermediate state is orchestrator-facing, and one comment per round is noise.

## Scope

Resolve what to review in this order, and declare the resolved scope before dispatching anything:

1. **Caller-supplied** — a SHA range, paths, or a PR. Use it as given.
2. **Uncommitted changes present** — the working tree diff: staged, unstaged, and untracked files.
3. **Clean tree, commits ahead of the default branch** — `merge-base(<default branch>, HEAD)..HEAD`. Resolve the default branch rather than assuming `main`: `git symbolic-ref refs/remotes/origin/HEAD`, then `gh repo view --json defaultBranchRef`, then ask. Never guess a branch name. If the range turns out empty — HEAD is already at the default branch — fall through to 4.
4. **Nothing to review** — no uncommitted change and no commit ahead of the default branch. Ask the user what to review. Never widen to the whole repository on a guess.

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
2. Dispatch one reviewer with the code as it now stands. One reviewer per round, fresh each round — a diff is a smaller object than a plan, and splitting the review further only pays handoff cost.
3. Judge every finding with `superpowers:receiving-code-review`: verify the claim against the code before accepting it, and reject — with a stated reason — findings that are wrong, that only reflect reviewer preference, or that ask for work beyond the request.
4. Apply the accepted Critical and Important findings yourself. When a finding describes a bug, write the failing regression test first and watch it fail, then fix it (`superpowers:test-driven-development`). Record Minor findings; don't fix them.
5. Verify with the concrete commands the project defines — in the README, Makefile, package scripts, or CI — and read their actual output.
6. Return to step 2 while a blocking finding remains.
7. Report per **Report**.

A round is one review → judge → fix → verify cycle. The pass is clean when a round's review produces no Critical or Important finding. Minor findings are recorded, not blocking.

## Escalation

- Five rounds at most. If the fifth round's review still produces blocking findings, apply and verify them as usual, then stop instead of starting a sixth review: report those fixes as applied but not re-reviewed, along with the disagreement, and let the user decide. Never report clean on the strength of fixes no review has seen.
- A Critical finding that invalidates the approved design does not get fixed in the loop. Stop and return to `plan-work` — that flow owns the framing, and re-approving a design is its job, not something to improvise here or inside a sub-skill of it. This matches the guidelines' **Escalation**.

## Report

- the scope reviewed and how it was resolved, including whether requirements were available
- the number of rounds run
- accepted findings, with location and what changed
- rejected findings, with the reason
- the remaining Minor findings
- what verification ran, and its actual result
- the verdict: clean, or the blocking findings that remain
