---
name: review-plan
description: Use after drafting an implementation plan and before implementation starts, to review the plan itself — whether the work is warranted at all, and where it has gaps, contradictions, unverified assumptions, or mismatches with the repository's actual state. Dispatches independent read-only reviewers on separate lenses, judges their findings, and loops until no blocking finding remains.
---

# Review Plan

Use on a written implementation plan (from `superpowers:writing-plans`) before any code is written, and again on each revision until it comes back clean. This reviews the plan, not the code.

## Roles

- The orchestrator owns the loop: it dispatches reviewers, judges findings, edits the plan, and decides when the plan is clean.
- Reviewers are read-only workers. Each gets one lens, the plan text, and the paths the plan touches. A reviewer reports findings and never edits the plan or the code, and never declares the plan clean.
- Every reviewer takes the same stance: try to make the plan fail. A plan you cannot break is a plan that passes — but a finding you cannot evidence is not a finding.

## Lenses

Dispatch one reviewer per lens, in parallel (`superpowers:dispatching-parallel-agents` — this is independent fact-finding, not implementation). Skip a lens only when it cannot apply, and say which and why.

- **Necessity** — whether the work is warranted at all: steps the request never asked for, scope the plan grew on its own, a smaller path to the same outcome, or an existing feature that already covers it. This lens reads the whole plan and questions that it should exist, not just how it reads.
- **Completeness** — requirements not covered; missing edge cases, error paths, migration, rollback, or docs; a task with no verification step.
- **Consistency** — steps that contradict each other, ordering or dependency errors, tasks assuming state no earlier task produces, terminology drift.
- **Reality** — mismatch with the repo as it is: paths, symbols, or commands that don't exist; existing utilities or patterns the plan reinvents; existing failures, constraints, or config the plan ignores.
- **Assumptions** — what the plan takes for granted without checking: unstated preconditions, dependency behavior nobody verified, assumed environment, permissions, or data shape. Where Reality catches what the repo contradicts, this catches what nobody has confirmed either way — list each assumption and mark it verified or unverified.
- **Executability** — tasks too large or too vague to implement and verify independently; shared files that break task independence; verification that isn't a concrete command, or one that wouldn't actually show the change worked.
- **Risk** — blast radius, backward compatibility, data and security implications, and what happens if a task half-lands.

## Finding contract

Each reviewer returns findings only — never a rewritten plan — with:

- **lens** and **severity**: Critical (the design or approach is wrong), Important (must be resolved before implementation), Minor (worth noting).
- **claim** — one sentence on what is wrong with the plan.
- **evidence** — `path:line` from the repo, or the quoted plan line. No evidence, no finding.
- **suggested change** — what the plan should say instead.

Report "no findings" explicitly rather than inventing one. Confine every search to the project root or narrower.

## Loop

1. Dispatch the lenses in parallel against the current plan.
2. Evaluate every finding with `superpowers:receiving-code-review`: verify the claim against the repo before accepting it, and reject wrong or preference-only findings with a stated reason.
3. Fold accepted findings into the plan, keeping a record of each finding, its verdict, and the reason.
4. Re-review the revised plan, handing reviewers the record so rejected findings are not re-litigated.

Clean when a round returns no new Critical or Important finding. Minor findings are recorded, not blocking.

## Stop conditions

- A Critical finding that invalidates the approved design is not a plan edit — return to `superpowers:brainstorming` and get design approval again before resuming.
- Three rounds without converging — stop, report the open findings and the disagreement, and let the user decide.
- Findings that only reflect reviewer preference, or that ask for work beyond the request, are rejected with the reason recorded.

## Report

Report the rounds run, the lenses used (and any skipped, with why), accepted findings and how the plan changed, rejected findings with reasons, and the remaining Minor findings.
