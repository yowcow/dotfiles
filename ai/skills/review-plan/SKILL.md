---
name: review-plan
description: Use to review an implementation plan itself — before implementation starts, on a revision, or as a later check on a plan already written or posted. Reviews whether the work is warranted at all, and where the plan has gaps, contradictions, unverified assumptions, or mismatches with the repository's actual state. Dispatches independent read-only reviewers on separate lenses, judges their findings, and reports the surviving ones. One invocation is one review pass; it never edits the plan.
---

# Review Plan

Use on a written implementation plan (from `superpowers:writing-plans`) — before any code is written, on a revision, or as a later check on a plan already posted. This reviews the plan, not the code.

One invocation is one review pass: dispatch reviewers, judge their findings, report. It never edits the plan and never re-reviews on its own. Revising the plan and re-running this skill until it comes back clean belongs to the caller — in the Change workflow, the guidelines' **Plan** phase owns that loop.

## Roles

- The orchestrator owns this pass: it dispatches reviewers, judges their findings, and reports. It does not edit the plan and does not declare the Plan phase done — it reports only whether this pass found a blocking finding.
- Reviewers are read-only workers. Each gets its assigned lenses, the plan text, the original request, and the paths the plan touches. A reviewer reports findings and never edits the plan or the code, and never declares the plan clean.
- Every reviewer takes the same stance: try to make the plan fail. A plan you cannot break is a plan that passes — but a finding you cannot evidence is not a finding.

## Lenses

Each lens is a distinct failure mode. How many reviewers they map to is decided in **Dispatch** below.

- **Necessity** — whether the work is warranted at all: steps the request never asked for, scope the plan grew on its own, a smaller path to the same outcome, or an existing feature that already covers it. This lens reads the whole plan and questions that it should exist, not just how it reads.
- **Completeness** — requirements not covered; missing edge cases, error paths, migration, rollback, or docs; a task with no verification step.
- **Consistency** — steps that contradict each other, ordering or dependency errors, tasks assuming state no earlier task produces, terminology drift.
- **Reality** — mismatch with the repo as it is: paths, symbols, or commands that don't exist; existing utilities or patterns the plan reinvents; existing failures, constraints, or config the plan ignores.
- **Assumptions** — what the plan takes for granted without checking: unstated preconditions, dependency behavior nobody verified, assumed environment, permissions, or data shape. Where Reality catches what the repo contradicts, this catches what nobody has confirmed either way — list each assumption and mark it verified or unverified.
- **Executability** — tasks too large or too vague to implement and verify independently; shared files that break task independence; verification that isn't a concrete command, or one that wouldn't actually show the change worked.
- **Risk** — blast radius, backward compatibility, data and security implications, and what happens if a task half-lands.

## Dispatch

Reviewers run in parallel (`superpowers:dispatching-parallel-agents` — this is independent fact-finding, not implementation). Splitting lenses across reviewers buys independence: none of them sees another's findings, so none anchors on them. Splitting further than the plan warrants only pays handoff cost, so size the fan-out to the plan:

- **Default** — three reviewers, one bundle each: **Intent** (Necessity, Completeness, Consistency — needs the plan and the original request, not the repo), **Ground truth** (Reality, Assumptions), **Execution** (Executability, Risk).
- **Small plan** — one reviewer takes every lens, when the work is mechanical or confined to a single file.
- **Large, risky, or spanning subsystems** — one reviewer per lens.

When the caller hands over the record of an earlier pass — a revised plan coming back — dispatch only the lenses that produced an accepted finding, plus Reality, since the plan changed under it, and pass the record to the reviewers so rejected findings are not re-litigated. Skip a lens only when it cannot apply, and say which and why.

## Finding contract

Each reviewer returns findings only — never a rewritten plan — with:

- **lens** and **severity**: Critical (the design or approach is wrong), Important (must be resolved before implementation), Minor (worth noting).
- **claim** — one sentence on what is wrong with the plan.
- **evidence** — `path:line` from the repo, or the quoted plan line. No evidence, no finding.
- **suggested change** — what the plan should say instead.

Report "no findings" explicitly rather than inventing one. Confine every search to the project root or narrower.

## Pass

1. Gather the inputs: the plan text, the original request, the paths the plan touches, and the record of an earlier pass if the caller supplied one.
2. Dispatch reviewers against the plan, sized per **Dispatch**.
3. Evaluate every finding with `superpowers:receiving-code-review`: verify the claim against the repo before accepting it, and reject — with a stated reason — findings that are wrong, that only reflect reviewer preference, or that ask for work beyond the request.
4. Report per **Report**, and stop there — revising the plan and re-reviewing it are the caller's job.

This pass is clean when no Critical or Important finding survives step 3. Minor findings are recorded, not blocking.

## Report

Report, for this pass:

- the fan-out used, and any lens skipped with why
- accepted findings with lens, severity, evidence, and suggested change
- rejected findings with the reason
- the remaining Minor findings
- the verdict: clean, or the blocking findings that remain — flagging separately any Critical finding that invalidates the approved design, since that needs design approval again rather than a plan edit
