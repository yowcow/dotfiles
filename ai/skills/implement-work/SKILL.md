---
name: implement-work
description: Use to execute an approved implementation plan — establish an isolated, verified workspace, declare and run the execution method (subagent-driven development by default, executing-plans for a separate session, or a justified manual exception), enforce TDD and per-task code review, then run the completion gate (verify, simplify, review) until clean before handing off for integration. Triggers on "implement this plan", "start implementing", "execute the plan", "work through the TODO checklist", "run the completion gate".
---

# Implement Work

Use once a plan exists — an issue comment, a chat plan, or a plan file — and the diff it describes has not been built yet.

This skill owns the completion gate's loop: verify, simplify, review, repeat until clean, then hand off. It does not own what happens inside `review-code` or `simplify-code` — each owns its own internal review/fix or propose/apply loop. It does not own the PR-side loop either: once a branch is handed off, `pr-to-ready` runs its own completion path, and this gate is never re-entered from there.

## Roles

- The orchestrator (whoever runs this skill) owns the plan, the worktree, the execution-method choice, every commit, the completion gate's loop, and the hand-off decision. It decides when the gate is clean — no worker declares that.
- Workers do the bounded, single-task work: an SDD task runs in a worker isolated from the orchestrator (a separate context, and a separate model where the runtime supports it); an `executing-plans` session follows the plan's own checkpoints. A worker is never given an objective spanning more than one task, and never advances the plan or the gate itself.

## Entry

Implementation requires a written plan; otherwise return to `plan-work` — there is nothing to execute without one.

## Isolation

Use `superpowers:using-git-worktrees`: first detect existing isolation and submodules, prefer a runtime-native worktree, and create a Git worktree only when necessary. Set up the project and establish a clean, verified baseline there before touching the plan's tasks.

## Execution method

Before writing code, declare which execution method was chosen and why — this choice is explicit, never implicit:

- **Same session with independent tasks** → `superpowers:subagent-driven-development`, the default. Tasks are independent when they share no files, no mutable state, and no ordering dependency.
- **Separate session loading an existing plan** → `superpowers:executing-plans`.
- **Manual execution** is a justified exception, not a fallback: first try to replan coupled work into independently verifiable tasks; do it yourself only when the work genuinely cannot be split, or when same-session workers are unavailable or not permitted. Name the reason — never drift into manual silently, and don't treat `executing-plans` as an inline fallback.

## Guardrails

These govern how the chosen execution method is actually run:

- Delegation pays off only when each task is large enough to amortize the handoff (context packaging, the worker re-reading files, and review); inline trivially small independent changes instead.
- `superpowers:dispatching-parallel-agents` is not an alternative to SDD. Use it only for independent fact-finding or problem domains; changes with shared files, mutable state, or ordering dependencies stay sequential.
- Use `superpowers:test-driven-development` for every implementation: RED → verify the expected failure → minimal GREEN → verify → REFACTOR. For throwaway prototypes, configuration, or generated files, ask the user before taking an exception.
- For bug fixes: reproduce the symptom, add a focused regression test, then fix and verify.
- Review boundaries follow the execution method: with SDD, review each task after it completes; with `executing-plans`, review each task or natural checkpoint. Review with `review-code`, which loops review, judgment, and remediation until no blocking finding remains: Critical findings stop progress and Important findings must be resolved before the next task.
- As each task completes and verifies, check it off the TODO checklist — on the issue comment when the plan lives there.
- Test as you go and avoid unrelated refactoring.

## Completion gate

Before calling implementation done, loop in order until all steps are clean, then hand off:

1. **Verify** — Use `superpowers:verification-before-completion` with fresh output from concrete commands in the README, Makefile, package scripts, or CI. Run independent checks in parallel where possible.
2. **Simplify** — Use `simplify-code` on only the recent diff, preserving behavior and the smallest maintainable change.
3. **Repeat as needed** — If the simplify pass changed anything, return to step 1: verification must run against the code as it now stands. Converging the simplification itself is `simplify-code`'s own loop, not this one.
4. **Review** — Use `review-code`: one invocation reviews, judges, and remediates until no blocking finding remains. This step has three exits, and they must not be collapsed into one:
   - **(a) It changed code and came back clean** → return to step 1 (Verify). Verification and simplification must run against the code as it now stands.
   - **(b) It came back clean without changing anything** → proceed to step 5 (Hand off). This is the loop's only normal exit — treat it as distinct from (a), not a variant of it.
   - **(c) It stopped at its round cap with blocking findings still open** → do not re-invoke it. The whole completion gate halts here, not just this step: report the open findings and the disagreement, and let the user decide.
5. **Hand off** — Once every task and the final review are clean, proceed to **Hand off** below.

## Hand off

The deliverable is a branch of verified commits, with no PR on it yet — which is exactly what `pr-to-ready` takes as its entry.

Use `superpowers:finishing-a-development-branch` to present the verified integration options.

That skill's Step 5 Option 2 ("Push and Create PR") pushes the branch **and creates the pull request itself**, with no draft flag and no delegation to anything else. That is overridden here: in this workflow, `pr-to-ready` owns PR creation (its Step 0, which creates the PR as a draft with `gh pr create --draft`). If the user picks Option 2, truncate it to the push (`git push -u origin <branch>`) and stop there — do not create the PR in this skill. Instead, invoke `pr-to-ready` to create the draft PR and take it from there. Without this truncation, a non-draft PR gets created here and `pr-to-ready`'s Step 0 has nothing left to do.

## Report

Report on the finished implementation:

- the concrete checks run, and any that couldn't be run
- what changed and why
- assumptions made
- areas needing manual review

## Escalation

A Critical finding that invalidates the approved design does not get fixed in the gate. Stop and return to `plan-work` — the design needs re-approval, not a workaround here.
