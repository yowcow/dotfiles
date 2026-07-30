---
name: review-plan
description: Use to review planning work itself, before implementation starts or on a revision — either a task list breaking work into PR-sized items (from `plan-work`), or the detailed implementation plan for one PR (from `implement-work`). Reviews whether the work is warranted at all, and where the plan has gaps, contradictions, unverified assumptions, or mismatches with the repository's actual state. Dispatches read-only reviewers, judges their findings, and reports the surviving ones. One invocation is one review pass; it never edits what it reviewed.
---

# Review Plan

Use on planning work before any code is written, or on a revision of it. This reviews the plan, not the code.

One invocation is one review pass: dispatch reviewers, judge their findings, report. It never edits what it reviewed and never re-reviews on its own. Revising and re-running until it comes back clean belongs to the caller — `plan-work` for a task list, `implement-work` for an implementation plan.

## Targets

One invocation reviews exactly one target, and **the caller declares which**. The target sets the lens list and the fan-out, because the two artifacts fail in different ways.

- **Task list** — from `plan-work`: the design plus a numbered list of PR-sized items. Lenses: **Necessity, Completeness, Consistency, Reality, Risk**.
  - *Skip* **Assumptions** and **Executability**, and say so in the report: there is no task-level detail yet for either to bite on.
- **Implementation plan** — from `implement-work`: the detailed plan for one PR. Lenses: **Completeness, Consistency, Reality, Assumptions, Executability, Risk**.
  - *Skip* **Necessity**, and say so in the report: whether the work is warranted was settled when the task list was reviewed. If this plan reaches past its task's scope boundary, that is not Necessity reopening — raise it under Consistency, against the task's stated completion criteria.
  - Don't redo the self-review the plan-writing skill already performs on its own output — spec coverage, placeholder scanning, name and type consistency. Completeness and Consistency here cover what that self-review cannot see: error paths, migration and rollback, and ordering between tasks.

## Lenses

Each lens is a distinct failure mode. Which ones apply comes from **Targets**; how many reviewers they map to comes from **Dispatch**.

- **Necessity** — whether the work is warranted at all: steps the request never asked for, scope the plan grew on its own, a smaller path to the same outcome, or an existing feature that already covers it. This lens reads the whole thing and questions that it should exist, not just how it reads.
- **Completeness** — requirements not covered; missing edge cases, error paths, migration, rollback, or docs.
  - On an **implementation plan**: also a task with no verification step.
  - On a **task list**: an item with no stated completion criteria. **Not** a missing verification command — the task list is contractually forbidden to carry those, so flagging their absence would manufacture a finding against every item. Verification detail is Executability's business, and Executability is skipped for this target.
- **Consistency** — steps that contradict each other, ordering or dependency errors, tasks assuming state no earlier task produces, terminology drift.
- **Reality** — mismatch with the repo as it is: paths, symbols, or commands that don't exist; existing utilities or patterns the plan reinvents; existing failures, constraints, or config the plan ignores.
- **Assumptions** — what the plan takes for granted without checking: unstated preconditions, dependency behavior nobody verified, assumed environment, permissions, or data shape. Where Reality catches what the repo contradicts, this catches what nobody has confirmed either way — list each assumption and mark it verified or unverified.
- **Executability** — tasks too large or too vague to implement and verify independently; shared files that break task independence; verification that isn't a concrete command, or one that wouldn't actually show the change worked. A named command whose result-testing method is unspecified counts here.
- **Risk** — blast radius, backward compatibility, data and security implications, and what happens if a task half-lands.
  - On a **task list**: also whether every intermediate state is safe — the PRs land one at a time, so a state where only some have merged has to hold together.

## Dispatch

Reviewers are read-only workers. Each gets its assigned lenses, the artifact under review, the original request, and the paths it touches. A reviewer reports findings and never edits anything, and never declares the plan clean. Every reviewer takes the same stance: try to make the plan fail. One you cannot break passes — but a finding you cannot evidence is not a finding.

Size the fan-out to the target, and keep it small. Both targets are small artifacts — a list of PR-sized items, or one PR's plan — and splitting further than that only pays hand-off cost.

- **Default — one reviewer** takes the target's whole lens list.
- **Two reviewers**, when the work is large, risky, or spans subsystems: split the lens list into the ones that need only the artifact and the original request, and the ones that need to read the repo. Independence is what the split buys — neither sees the other's findings, so neither anchors on them.

Use `superpowers:dispatching-parallel-agents` for the dispatch itself when there is more than one; this is independent fact-finding, not implementation. Don't restate its prompt-construction guidance here.

On a revision — the caller hands over the record of an earlier pass — dispatch only the lenses that produced an accepted finding, plus Reality, since the artifact changed under it. Pass the record along so rejected findings are not re-litigated. Skip a lens only when it cannot apply, and say which and why.

## Finding contract

Each reviewer returns findings only — never a rewritten plan — with:

- **lens**, and **severity**: Critical (the design or approach is wrong), Important (must be resolved before implementation), Minor (worth noting).
- **claim** — one sentence on what is wrong.
- **evidence** — `path:line` from the repo, or the quoted line from the artifact. No evidence, no finding.
- **suggested change** — what it should say instead.

Report "no findings" explicitly rather than inventing one. Confine every search to the project root or narrower.

## Pass

1. Gather the inputs: the declared target, the artifact, the original request, the paths it touches, and the record of an earlier pass if the caller supplied one.
2. Dispatch reviewers, sized per **Dispatch**.
3. Evaluate every finding with `superpowers:receiving-code-review`: verify the claim against the repo before accepting it, and reject — with a stated reason — findings that are wrong, that only reflect reviewer preference, or that ask for work beyond the request.
4. Report per **Report**, and stop there — revising and re-reviewing are the caller's job.

This pass is clean when no Critical or Important finding survives step 3. Minor findings are recorded, not blocking.

## Report

Report to the caller in chat. Never post this pass to GitHub — not even when the artifact under review lives in an issue or PR comment: a pass is an orchestrator-facing intermediate, and one comment per loop is noise. Report, for this pass:

- the target reviewed, the fan-out used, and any lens skipped with why
- accepted findings with lens, severity, evidence, and suggested change
- rejected findings with the reason
- the remaining Minor findings
- the verdict: clean, or the blocking findings that remain — flagging separately any Critical finding that invalidates the approved design, since that needs design approval again rather than a plan edit
