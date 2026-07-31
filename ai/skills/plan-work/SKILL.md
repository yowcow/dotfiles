---
name: plan-work
description: Use to turn an issue or a planning request into an agreed design and a numbered TODO list at PR granularity, before any code is touched. Researches the issue and the relevant code, reaches design agreement with `superpowers:brainstorming`, drafts the TODO list itself, runs the `review-plan` loop to convergence, publishes once as an issue comment (or in chat), and creates one sub-issue per item when the work spans two or more PRs. Triggers on "plan this", "plan issue #<n>", "turn this into a plan", "break this into PRs", "brainstorm and plan this".
---

# Plan Work

Use to turn an issue or a planning request into work `implement-work` can pick up one PR at a time — before any worktree exists and before any code is touched.

One invocation runs the whole flow to convergence: research, design agreement, a numbered TODO list at PR granularity, and the loop around `review-plan` — up to three rounds — until a pass returns no blocking finding, then one publish and the sub-issues. This skill owns that loop, including its three-round cap. `review-plan` is one pass with no cap of its own — it reports judged findings and never edits what it reviewed — so folding findings in and re-running belongs here.

**This flow stops short of per-task detail** — see **Output contract** for what that excludes. `implement-work` writes that detail one PR at a time, immediately before the work.

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
- **A design invalidated downstream** — `implement-work` or `pr-to-ready` stopped because a finding undid the agreed design, and sent it back for re-approval. It arrives with three things: the finding and which part of the design it undoes, the existing branch's name, and that branch's state (whether it is pushed, and whether a PR is open on it). Re-enter at **Design agreement** with those in hand: what needs re-approval is the design, so the flow restarts there rather than at a fresh research pass. Where an issue tracks the work it is still the canonical record, so the re-approved design updates that same comment in place rather than adding another, per **Publish**. What is new in this case is the existing branch — **Output contract** says how every TODO item has to account for it.

## Design agreement

Reach it with `superpowers:brainstorming`.

That skill ends by moving on to the next skill, and says so emphatically. **Don't follow it.** What it is called for here is a design draft that has been through its own self-review and the user's confirmation, recorded in the issue comment (or chat) — run it to there, and stop. Then come back and draft the TODO list yourself.

**It also writes a design document to a file and commits it. Skip that step outright** — draft the design into the comment body (or the chat draft) instead, and leave the working tree alone, per **Boundaries**. Redirecting where the *final* artifact lives is not enough on its own: the file write is a step of its own, reached before the self-review, and a session working through that procedure literally will perform it unless told not to here.

Two things go wrong if this cut lands in the wrong place. Cut too late and the flow runs on into drafting a detailed plan and writing a file — and since this flow has no worktree, that file gets committed to whatever branch the session is on, usually `master`. Cut too early — the moment the design is agreed, before the self-review and the user's confirmation — and the artifact that gets published, and that sub-issues are then generated from, has had no human sign-off on its actual content.

## Output contract

The published artifact is the design plus a numbered list of PR-sized items. It has to let `implement-work` pick up any one item and plan it — not implement from it directly:

- background — what problem this solves and why
- design and rationale — the approved shape, and why not the alternatives
- the split policy — where the PR boundaries fall and why
- a **numbered** TODO list, one item per PR. Each item states its purpose, its scope boundary (including what it excludes), and its completion criteria.
- for each item, whether it can be started in parallel or must be stacked on an earlier item — named, not implied — plus the dependency order when anything stacks. Every item must be **verifiable** on its own; being **startable** on its own is what stacking gives up, so a stacked item names the item it waits for and why.
- affected area at module or directory granularity
- **only when entering from a design invalidated downstream** — how each item treats the existing branch. This is not one convention but two, and they are written differently:
  - **Reuse it** → write that branch's name in the item. `implement-work`'s **Isolation** finds it and attaches a workspace to it, so the item carries on from those commits.
  - **Discard it** → write a **new** branch name in the item. That Isolation ladder reuses any branch it finds and has no rung that discards one, so an item carrying the old name would quietly resume work on top of the very commits the invalidated design produced — the failure this convention exists to prevent.

  Name the discarded branch and its worktree in the published artifact too, as a person's cleanup. This flow never touches the working tree, so nothing here removes them, and an abandoned branch nobody named is indistinguishable from one still in use.

**Deliberately absent:** exact paths, line numbers, per-task verification commands, edge-case enumeration. Those belong to `implement-work`.

When no issue tracks the work, the same contract binds the version posted in chat — chat is the canonical record in that case, not a lesser one.

## Splitting into sub-issues

Two or more items means sub-issues, one per item — and a sub-issue hangs off a tracking issue, so this presumes one exists. Where it does, they aren't optional: without them, `implement-work` has no named entry for a single PR and `pr-to-ready` has nothing to check when it decides whether the parent can close.

**Two or more items and no tracking issue → ask before publishing anything.** Chat has nothing to hang a sub-issue from, and it cannot satisfy the guidelines' requirement that a hand-off stand on its own, so ask the user to create a tracking issue for this work and publish there instead. If they decline, proceed with no sub-issues and chat as the canonical record — and write the consequence into the artifact itself: with no named entry per PR, every item has to be carried to completion in this one session, because a later session inherits nothing to pick up. That premise is what declining accepts, so state it rather than leaving it implicit. One item and no tracking issue needs none of this — there is nothing to split either way.

- **Parent issue comment**: the overall design, the split policy, and the list of sub-issues.
- **Each sub-issue**: its purpose, its scope boundary, its completion criteria, its prerequisites, and the URL of the parent's design comment. Nothing more — no exact paths, no verification commands, no per-task plan. Writing a PR-sized plan into the child issue would put the detail back where it was and defeat the split.
- **The prerequisite line is always present**, and it carries the reason: either the sub-issues that must merge first (`#12 のマージが先行して必要（同一ファイルを触るため）`), or `なし（並列に着手できる）` when the item is independent — that phrasing, parenthetical included. A bare `なし`, or no line at all, reads as an omission rather than as independence, and telling those two apart at a glance is the whole point.
- **When the item has a prerequisite, also set the native relation**: `gh issue edit <child> --add-blocked-by <prerequisite>`. The body line is for the human and carries the why; the native relation is what `implement-work` reads, so it never has to parse prose. Neither replaces the other. Confirm it took — `gh issue view <child> --json blockedBy` should come back with `<prerequisite>` among `nodes` and a non-zero `totalCount`. A relation that didn't stick leaves the count at 0, which `implement-work` reads as "independent": the silent misclassification this whole line exists to prevent.
- **An independent item gets no relation at all** — its `なし（並列に着手できる）` line is the entire record. Setting one anyway would leave `blockedBy.totalCount` non-zero, and `implement-work` would branch on that and treat the item as stacked.
- Converge the `review-plan` loop against the whole, undivided TODO list before splitting.
- A body too large for one comment is itself a signal to split further. The observed ceiling is 65536 characters — this is not in GitHub's REST reference; it's the API's own error text (`Body is too long (maximum is 65536 characters)`), so treat it as an observation, not a contract.

## Sub-issue linking

Prefer the MCP `sub_issue_write` tool (`method: "add"`, parent as `issue_number`, child as `sub_issue_id`); fall back to `gh api --method POST repos/{owner}/{repo}/issues/<parent>/sub_issues -F sub_issue_id=<child id>` where the MCP tool is unavailable. The child is identified by **id, not issue number** — get it with `gh api repos/{owner}/{repo}/issues/<n> --jq .id`.

GitHub does not auto-close a parent issue when all its sub-issues close. Closing the parent (or leaving a completion comment) is `pr-to-ready`'s responsibility at its finish step, triggered by the merge of the PR that closes the last sub-issue — not this skill's.

## Publish

Publishing and splitting interleave, because each needs something from the other: a sub-issue body carries the design comment's URL, and the parent comment lists the sub-issues. Order them:

1. Converge the `review-plan` loop.
2. **Settle where it gets published.** Two or more items and no tracking issue → ask per **Splitting into sub-issues**, before anything is posted. The answer decides whether the artifact lands on a new tracking issue or in chat, and publishing first would put a multi-item list in the wrong place and need it redone.
3. **Publish** the design, the split policy, and the numbered TODO list. The comment URL now exists.
4. **Create the sub-issues** if there are two or more items, each carrying that URL, per **Splitting into sub-issues** and **Sub-issue linking**. Create them in TODO order: a stacked item's body cites its prerequisite's *issue number*, and dependencies always point back at earlier items, so working in order means that number already exists — and `--add-blocked-by` can be set as each child lands.
5. **Edit the same comment in place** to append the list of sub-issues.

"Publish once" means one comment for this work, not one per round — editing that comment in place is not a second publish.

- Don't commit planning artifacts.
- Don't publish mid-loop — the draft stays in chat until the loop converges.
- Write anything posted to GitHub in 標準語 (standard Japanese, never dialect).
- No issue tracks the work → chat is the canonical record. With one item there is nothing to split; with two or more, **Splitting into sub-issues** asks the user for a tracking issue first, and only a declined ask publishes a multi-item list to chat. An issue tracks the work → a comment on that issue, updated in place rather than added to.
- `gh issue comment <n> --edit-last --create-if-none --body-file <file>` covers both the first publish and later updates — but `--edit-last` targets your *most recent* comment on the issue, whatever it is. Once anything else (a reply, a review note) follows it, `--edit-last` would hit the wrong comment: edit by id instead, with `jq -Rs '{body: .}' <file> | gh api --method PATCH repos/{owner}/{repo}/issues/comments/<comment-id> --input -` (`gh api` wants a JSON payload, not raw Markdown, hence the `jq -Rs` wrap).
- Always pass the body from a file, never an inline flag string, so backticks never reach the shell.

## Pass

1. Resolve **Entry**: an issue number, a planning request with no tracking issue, or a design invalidated downstream. The third enters at step 3 rather than step 2 — the design is what needs re-approval, and the research behind it already ran the first time through.
2. Research: read the issue (if any) and the relevant code before asking anything or proposing a design.
3. Reach design agreement per **Design agreement**.
4. Draft the design write-up and the numbered TODO list yourself, against **Output contract**.
5. Dispatch `review-plan` with the target declared as the TODO list.
6. Fold every accepted finding in yourself — `review-plan` never edits what it reviewed — except one that invalidates the agreed design, which is not folded in at all: stop and return to **Design agreement**, per **Escalation**. Then re-run `review-plan`, handing over the record of the previous pass (findings accepted and fixed, findings rejected with the reason) so it doesn't re-litigate what was already rejected.
7. Don't leave this pass until `review-plan` comes back with no blocking finding. Return to step 5 while one remains, subject to **Escalation**.
8. Publish and split, per **Publish**.

This is clean when the published artifact satisfies **Output contract** and the last `review-plan` pass returned no blocking finding.

## Escalation

- Three rounds at most. If the third round's `review-plan` pass still returns a blocking finding, stop instead of dispatching a fourth: report the open findings and the disagreement, and let the user decide. A TODO list that won't converge in three rounds usually has a design problem, not a list problem.
- A Critical finding that invalidates the agreed design does not get fixed in the loop. Stop and return to **Design agreement** for approval, per the guidelines' **Escalation**.

## Report

- the entry: issue number, the chat request when no issue tracks the work, or a design invalidated downstream — for the third, name the finding that invalidated it and the branch it came back with
- where the result was published — the comment URL, or "posted in chat"
- the number of `review-plan` rounds run, and the verdict of the final one
- accepted findings folded in, and rejected findings with the reason
- the sub-issues created, or why none were
- when a design came back invalidated: which branch each item reuses, which items got a new branch name instead, and the branches and worktrees left for a person to clean up
- assumptions made, and anything that could not be verified
