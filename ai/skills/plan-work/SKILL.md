---
name: plan-work
description: Use to turn an issue or a planning request into an agreed design and a numbered TODO list at PR granularity, before any code is touched. Researches the issue and the relevant code, reaches design agreement with `superpowers:brainstorming`, drafts the TODO list itself, runs the `review-plan` loop to convergence, publishes once as an issue comment (or in chat), and creates one sub-issue per item when the work spans two or more PRs. Triggers on "plan this", "plan issue #<n>", "turn this into a plan", "break this into PRs", "brainstorm and plan this".
---

# Plan Work

Use to turn an issue or a planning request into work `implement-work` can pick up one PR at a time — before any worktree exists and before any code is touched.

One invocation runs the whole flow to convergence: research, design agreement, a numbered TODO list at PR granularity, and the loop around `review-plan` — up to three rounds — until a pass returns no blocking finding, then one publish and the sub-issues. This skill owns that loop, including its three-round cap. `review-plan` is one pass with no cap of its own — it reports judged findings and never edits what it reviewed — so folding findings in and re-running belongs here.

**This flow stops short of per-task detail.** No exact paths, no per-task verification commands, no edge-case enumeration. That detail is written one PR at a time by `implement-work`, immediately before the work, and reviewing it here — before the design has even settled — is what made planning expensive.

## Roles

- This skill is the orchestrator: it drives research, invokes `superpowers:brainstorming` and `review-plan`, drafts the TODO list itself, judges `review-plan`'s findings, folds the accepted ones in, decides when the loop converges or must escalate, and publishes on convergence.
- `superpowers:brainstorming` and `review-plan` each own their own internal procedure — dispatch model, lenses, self-review, user-review gate. This skill supplies their inputs and acts on their outputs; it does not reach inside them, dispatch reviewers itself, or reimplement what they already do.
- **Nothing else drafts the TODO list.** No sub-skill produces a PR-granularity breakdown, so don't go looking for one to delegate to — write it here, against **Output contract**.

## Boundaries

- Never touch the working tree: no worktree, no branch, no commits, no code edits. Establishing an isolated environment belongs to `implement-work`.
- The canonical record is the tracking issue's comment — chat only when no issue tracks the work. A sub-skill that assumes it should write a file and commit it does neither here: redirect that output to the comment. When a sub-skill asks to self-review its output or to have the user confirm it, run those against the draft comment body (or the chat draft) — those steps are the point of calling it, so keep them.
- Never post an individual `review-plan` pass to GitHub — a pass is orchestrator-facing, and one comment per round is noise. Only the converged result gets published, per **Publish**.

## Entry

- An issue number — read the issue and its comments before anything else.
- A request to be planned with no tracking issue — proceed the same way, minus the issue read. Chat becomes the canonical record (see **Publish** and **Output contract**).

## Design agreement

Reach it with `superpowers:brainstorming`.

That skill ends by moving on to the next skill, and says so emphatically. **Don't follow it.** What it is called for here is a design draft that has been through its own self-review and the user's confirmation, recorded in the issue comment (or chat) — run it to there, and stop. Then come back and draft the TODO list yourself.

Two things go wrong if this cut lands in the wrong place. Cut too late and the flow runs on into drafting a detailed plan and writing a file — and since this flow has no worktree, that file gets committed to whatever branch the session is on, usually `master`. Cut too early — the moment the design is agreed, before the self-review and the user's confirmation — and the artifact that gets published, and that sub-issues are then generated from, has had no human sign-off on its actual content.

## Output contract

The published artifact is the design plus a numbered list of PR-sized items. It has to let `implement-work` pick up any one item and plan it — not implement from it directly:

- background — what problem this solves and why
- design and rationale — the approved shape, and why not the alternatives
- the split policy — where the PR boundaries fall and why
- a **numbered** TODO list, one item per PR. Each item states its purpose, its scope boundary (including what it excludes), and its completion criteria.
- the dependency order, if any, and confirmation that each item can be started and verified on its own
- affected area at module or directory granularity

**Deliberately absent:** exact paths, line numbers, per-task verification commands, edge-case enumeration. Those belong to `implement-work`.

When no issue tracks the work, the same contract binds the version posted in chat — chat is the canonical record in that case, not a lesser one.

## Splitting into sub-issues

Two or more items means sub-issues, one per item. This isn't optional: without them, `implement-work` has no named entry for a single PR and `pr-to-ready` has nothing to check when it decides whether the parent can close.

- **Parent issue comment**: the overall design, the split policy, and the list of sub-issues.
- **Each sub-issue**: its purpose, its scope boundary, its completion criteria, and the URL of the parent's design comment. Nothing more — no exact paths, no verification commands, no per-task plan. Writing a PR-sized plan into the child issue would put the detail back where it was and defeat the split.
- Converge the `review-plan` loop against the whole, undivided TODO list before splitting.
- A body too large for one comment is itself a signal to split further. The observed ceiling is 65536 characters — this is not in GitHub's REST reference; it's the API's own error text (`Body is too long (maximum is 65536 characters)`), so treat it as an observation, not a contract.

## Sub-issue linking

Prefer the MCP `sub_issue_write` tool (`method: "add"`, parent as `issue_number`, child as `sub_issue_id`); fall back to `gh api --method POST repos/{owner}/{repo}/issues/<parent>/sub_issues -F sub_issue_id=<child id>` where the MCP tool is unavailable. The child is identified by **id, not issue number** — get it with `gh api repos/{owner}/{repo}/issues/<n> --jq .id`.

GitHub does not auto-close a parent issue when all its sub-issues close. Closing the parent (or leaving a completion comment) is `pr-to-ready`'s responsibility at its finish step, triggered by the merge of the PR that closes the last sub-issue — not this skill's.

## Publish

Publishing and splitting interleave, because each needs something from the other: a sub-issue body carries the design comment's URL, and the parent comment lists the sub-issues. Order them:

1. Converge the `review-plan` loop.
2. **Publish** the design, the split policy, and the numbered TODO list. The comment URL now exists.
3. **Create the sub-issues** if there are two or more items, each carrying that URL, per **Splitting into sub-issues** and **Sub-issue linking**.
4. **Edit the same comment in place** to append the list of sub-issues.

"Publish once" means one comment for this work, not one per round — editing that comment in place is not a second publish.

- Don't commit planning artifacts.
- Don't publish mid-loop — the draft stays in chat until the loop converges.
- Write anything posted to GitHub in 標準語 (standard Japanese, never dialect).
- No issue tracks the work → chat is the canonical record, and there is nothing to split into sub-issues. An issue tracks the work → a comment on that issue, updated in place rather than added to.
- `gh issue comment <n> --edit-last --create-if-none --body-file <file>` covers both the first publish and later updates — but `--edit-last` targets your *most recent* comment on the issue, whatever it is. Once anything else (a reply, a review note) follows it, `--edit-last` would hit the wrong comment: edit by id instead, with `jq -Rs '{body: .}' <file> | gh api --method PATCH repos/{owner}/{repo}/issues/comments/<comment-id> --input -` (`gh api` wants a JSON payload, not raw Markdown, hence the `jq -Rs` wrap).
- Always pass the body from a file, never an inline flag string, so backticks never reach the shell.

## Pass

1. Resolve **Entry**: an issue number, or a planning request with no tracking issue.
2. Research: read the issue (if any) and the relevant code before asking anything or proposing a design.
3. Reach design agreement per **Design agreement**.
4. Draft the design write-up and the numbered TODO list yourself, against **Output contract**.
5. Dispatch `review-plan` with the target declared as the task list.
6. Fold every accepted Critical and Important finding in yourself — `review-plan` never edits what it reviewed — then re-run it, handing over the record of the previous pass (findings accepted and fixed, findings rejected with the reason) so it doesn't re-litigate what was already rejected.
7. Don't leave this pass until `review-plan` comes back with no blocking finding. Return to step 5 while one remains, subject to **Escalation**.
8. Publish and split, per **Publish**.

This is clean when the published artifact satisfies **Output contract** and the last `review-plan` pass returned no blocking finding.

## Escalation

- Three rounds at most. If the third round's `review-plan` pass still returns a blocking finding, stop instead of dispatching a fourth: report the open findings and the disagreement, and let the user decide. A TODO list that won't converge in three rounds usually has a design problem, not a list problem.
- A Critical finding that invalidates the agreed design does not get fixed in the loop. Stop and return to **Design agreement** for approval, per the guidelines' **Escalation**.

## Report

- the entry: issue number, or the chat request when no issue tracks the work
- where the result was published — the comment URL, or "posted in chat"
- the number of `review-plan` rounds run, and the verdict of the final one
- accepted findings folded in, and rejected findings with the reason
- the sub-issues created, or why none were
- assumptions made, and anything that could not be verified
