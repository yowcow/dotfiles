---
name: plan-work
description: Use to turn an issue or a planning request into a converged, publishable implementation plan, before any code is touched. Researches the issue and the relevant code, reaches design agreement with `superpowers:brainstorming`, drafts the plan with `superpowers:writing-plans`, runs the `review-plan` loop to convergence, and publishes the result once — as an issue comment, or in chat when no issue tracks the work. Triggers on "plan this", "plan issue #<n>", "turn this into a plan", "write up the implementation plan before we start", "brainstorm and plan this".
---

# Plan Work

Use to turn an issue or a planning request into a plan ready to hand to `implement-work` — before any worktree exists and before any code is touched.

One invocation runs the whole flow to convergence: research, design agreement, a drafted plan, and the loop around `review-plan` — up to five rounds — until a pass returns no blocking finding, then one publish. This skill owns that loop, including its five-round cap. `review-plan` itself is one pass with no cap of its own: it reports judged findings and never edits the plan or re-reviews on its own (`review-plan/SKILL.md:10`) — folding in findings and re-running belongs to the caller, and here the caller is this skill.

## Roles

- This skill is the orchestrator for the whole flow: it drives research, invokes `superpowers:brainstorming`, `superpowers:writing-plans`, and `review-plan` in sequence, judges `review-plan`'s findings, folds the accepted ones into the plan itself, decides when the loop converges or must escalate, and publishes once on convergence.
- `superpowers:brainstorming`, `superpowers:writing-plans`, and `review-plan` each own their own internal procedure — dispatch model, lenses, self-review checklist, user-review gate. This skill supplies their inputs and acts on their outputs; it does not reach inside them, dispatch reviewers itself, or reimplement what they already do.

## Boundaries

- Never touch the working tree: no worktree, no branch, no code edits. Setting up an isolated environment belongs to `implement-work`, once a written plan exists.
- Never post an individual `review-plan` pass to GitHub — same rule as `review-plan`'s own Report section: a pass is orchestrator-facing, and one comment per round is noise. Only the converged, final plan gets published, per **Publish**.

## Entry

- An issue number — read the issue and its comments before anything else.
- A request to be planned with no tracking issue — proceed the same way, minus the issue read. The plan's canonical record becomes chat instead of an issue comment (see **Publish** and **Output contract**).

## Overriding `brainstorming` and `writing-plans`

Both `superpowers:brainstorming` and `superpowers:writing-plans` default to writing a file and committing it, each to its own independent path, with a footnote that user preferences override *that path* (`brainstorming/SKILL.md:107`-`108`, `writing-plans/SKILL.md:18`-`19`). The override here goes further than the path: it replaces the whole mechanism — the file write, the commit, and the review-of-a-file step — not just where the file would live. The canonical record for the whole flow is the tracking issue's comment, or chat when no issue tracks the work.

- **`brainstorming`**: skip "Write design doc" and its commit entirely — do not create `docs/superpowers/specs/...`. Run the **spec self-review** (checklist item 7: placeholder scan, internal consistency, scope check, ambiguity check) against the draft comment body instead of a file. Run the **User Review Gate** (checklist item 8) against the posted comment: post it (or share the draft in chat when there is no issue), then ask the user to review that comment before moving on.
- **`writing-plans`**: this is a second, independent default and needs its own override — overriding `brainstorming`'s default does not cover it. Skip `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md` and its commit. The plan's canonical record is the same issue comment (or chat); its Execution Handoff section (`writing-plans/SKILL.md:150`-) assumes a saved file path — replace every "saved to `<path>`" with "published to `<comment url>`", or "posted in chat" when there is no issue.

## Splitting large work

When the plan won't fit in one PR, split it into sub-issues at PR granularity:

- **Parent issue comment**: the overall design, the split policy, and the list of sub-issues.
- **Each child issue comment**: its own PR-sized plan and TODO checklist — an independently implementable slice of the parent's design.
- Run the `review-plan` loop to convergence against the whole, undivided plan first; only split after it converges. Each child plan is then checked for consistency with what was split out of it, not reviewed as a fresh target.
- A body too large for one comment is itself a signal to split. The observed ceiling is 65536 characters — this is not documented in GitHub's REST reference; it's the API's own error text (`Body is too long (maximum is 65536 characters)`), so treat it as an observation, not a contract.

## Sub-issue linking

Prefer the MCP `sub_issue_write` tool (`method: "add"`, parent as `issue_number`, child as `sub_issue_id`); fall back to `gh api --method POST repos/{owner}/{repo}/issues/<parent>/sub_issues -F sub_issue_id=<child id>` where the MCP tool is unavailable. The child is identified by **id, not issue number** — get it with `gh api repos/{owner}/{repo}/issues/<n> --jq .id`.

GitHub does not auto-close a parent issue when all its sub-issues close. Closing the parent (or leaving a completion comment) is `pr-to-ready`'s responsibility at its finish step, triggered by the merge of the PR that closes the last sub-issue — not this skill's.

## Publish

- Don't commit planning artifacts by default.
- Don't publish mid-loop — the plan stays in chat until the `review-plan` loop (see **Pass**) converges.
- Publish the final plan and its TODO checklist exactly once, on convergence, in 標準語 (standard Japanese, never dialect — this applies to anything posted to GitHub).
- No issue tracks the work → chat is the canonical record. An issue tracks the work → a comment on that issue, updating the existing plan comment in place rather than adding a new one.
- `gh issue comment <n> --edit-last --create-if-none --body-file <file>` covers both the first publish and later updates — but `--edit-last` targets your *most recent* comment on the issue, whatever it is. Once anything else (a reply, a review note) follows the plan comment, `--edit-last` would hit the wrong comment: edit the plan comment by id instead, with `jq -Rs '{body: .}' <file> | gh api --method PATCH repos/{owner}/{repo}/issues/comments/<comment-id> --input -` (`gh api` wants a JSON payload, not raw Markdown, hence the `jq -Rs` wrap).
- Always pass the body from a file, never an inline flag string, so backticks in the plan never reach the shell.

## Output contract

The published artifact must be self-contained enough that a fresh session — or `implement-work` — can start implementing from it alone, with nothing else inherited:

- background — what problem this solves and why
- design and rationale — the approved shape, and why not the alternatives
- exact paths — files to create or modify, named precisely
- task granularity that's independently verifiable — each task checkable on its own
- edge cases — part of the quality bar `superpowers:writing-plans` sets alongside exact paths, small tasks, and verification
- concrete verification commands — the actual command and its expected output per task, plus what the downstream completion gate (`implement-work` owns its procedure) will need to run against the whole change
- a TODO checklist

When no issue tracks the work, this same self-containment is required of the plan posted in chat — chat is the canonical record in that case, not a lesser one.

## Pass

1. Resolve **Entry**: an issue number, or a planning request with no tracking issue.
2. Research: read the issue (if any) and the relevant code before asking anything or proposing a design.
3. Reach design agreement with `superpowers:brainstorming`, applying the overrides in **Overriding `brainstorming` and `writing-plans`**.
4. Draft the plan with `superpowers:writing-plans`, satisfying **Output contract** and applying that same section's second override.
5. If the plan won't fit one PR, apply **Splitting large work** and **Sub-issue linking** before continuing.
6. Dispatch `review-plan` against the plan.
7. Fold every accepted Critical and Important finding into the plan yourself — `review-plan` never edits the plan — then re-run it, handing over the record of the previous pass (findings accepted and fixed, findings rejected with the reason) so it doesn't re-litigate what was already rejected.
8. Don't leave this pass until a `review-plan` pass comes back with no blocking finding. Return to step 6 while one remains, subject to **Escalation**.
9. Once a pass returns no blocking finding, publish exactly once, per **Publish**.

This is clean when the published plan satisfies **Output contract** and the last `review-plan` pass returned no blocking finding.

## Escalation

- Five rounds at most. If the fifth round's `review-plan` pass still returns a blocking finding, stop instead of dispatching a sixth: report the open findings and the disagreement, and let the user decide.
- A Critical finding that invalidates the approved design does not get fixed in the loop. Stop and return to `superpowers:brainstorming` for design approval, per the guidelines' Escalation.

## Report

- the entry: issue number, or the chat request when no issue tracks the work
- where the plan was published — the comment URL, or "posted in chat"
- the number of `review-plan` rounds run, and the verdict of the final one
- accepted findings folded in, and rejected findings with the reason
- whether the plan was split into sub-issues, and the list if so
- assumptions made, and anything that could not be verified
