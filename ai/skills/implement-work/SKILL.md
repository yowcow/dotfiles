---
name: implement-work
description: Use to take one PR-sized task — a sub-issue, an issue that fits a single PR, or a request of that size — all the way to a branch of verified commits. Establishes the isolated workspace and a verified baseline, drafts the detailed plan for that one PR and reviews it to convergence, declares and runs the execution method, then runs the completion gate before handing off. Triggers on "implement this sub-issue", "start implementing", "work through this task", "run the completion gate", "take this to a branch".
---

# Implement Work

Use once the design is agreed and the work has been cut to one PR's worth. There is no plan yet — drafting and reviewing the detailed plan for this one PR happens here, first.

**The procedure lives in the skills this one calls.** What this skill owns is the wiring: which skill runs when, what each hand-off carries, and where the gates sit. It does not restate model selection, worker dispatch, review loops, progress tracking, or TDD mechanics — those belong to the skills that own them, and duplicating them here means maintaining them twice.

This skill holds two gates: one on the detailed plan, before any code, and the completion gate at the end. It does not own the PR-side loop — once a branch is handed off, `pr-to-ready` runs its own completion path, and neither gate here is re-entered from there.

## Roles

- The orchestrator owns the task, the workspace, both gates, the execution-method choice, every commit, and the hand-off. It decides when a gate is clean — no worker declares that.
- Workers do bounded, single-task work and hand back. A worker is never given an objective spanning more than one task, and never advances the plan or a gate itself.

## Entry

One PR-sized task:

- a sub-issue,
- an issue that fits a single PR,
- or a request of that size.

Work larger than one PR, or a design not yet agreed, goes back to `plan-work`. Don't split it here — splitting is a design decision.

## Isolation

Establish this **before drafting the plan**, because the plan file has to live inside the workspace the execution method will read it from. A workspace created afterwards would not contain it — a new working tree gets the tracked content, not ignored scratch files — and the execution method fails on the missing file.

Use `superpowers:using-git-worktrees`, then set the project up and establish a verified baseline there.

That skill detects existing isolation from the current directory only; it has no way to find a workspace by branch name, and its creation step assumes the branch is new. So on resumption, look before creating:

1. If `git worktree list --porcelain | grep -Fxq "branch refs/heads/<branch>"`, reuse that workspace. Its path comes from the same output: `git worktree list --porcelain | grep -Fx -B2 "branch refs/heads/<branch>" | sed -n 's/^worktree //p'` — each block is `worktree <path>` / `HEAD <sha>` / `branch <ref>`, so the branch line's two predecessors carry the path. `-F` and `-x` are load-bearing, and they replace the `^`/`$` anchors rather than joining them: a branch name may contain `.`, which as a regex matches any character, so an anchored pattern can match a *different* branch and hand back the wrong workspace.
2. Otherwise, if the branch exists locally, attach a workspace to it with `git worktree add <path> <branch>` — no `-b`. Test existence with `git show-ref --verify --quiet refs/heads/<branch>`; **`git branch --list` exits 0 whether or not it matched**, so branching on its exit status is always true, and on a first run that would send you here to attach a branch that doesn't exist yet. An output-emptiness test works too: `[ -n "$(git branch --list <branch>)" ]`.
3. Otherwise, if the branch exists only on the remote, attach a workspace that tracks it: `git fetch origin <branch>` first, since a fresh checkout may not have the ref yet, then test with `git show-ref --verify --quiet refs/remotes/origin/<branch>` and run `git worktree add --track -b <branch> <path> origin/<branch>`. Check this before falling through to creating a branch — a resumed task whose branch was already pushed, in a session or a checkout that never held it locally, has no local ref, and creating one afresh would start it from the default branch. It would then diverge from the pushed branch under the same name, and its first push would be rejected as a non-fast-forward; since force-pushing is barred, the earlier work is stranded rather than resumed.
4. Otherwise create it normally.

Whenever an instruction names a command, say how its result is tested — a command that doesn't vary its exit status will otherwise get branched on wrongly.

If the verified baseline contradicts what the plan assumes — an existing failure, missing tooling — go back to **Plan gate** before starting tasks.

## Plan gate

1. Read the task. Where the design lives depends on the entry: a **sub-issue** carries its own body plus a link to the parent's design comment; an **issue that fits one PR** carries its own comment; a **request with no issue** is itself the input, together with whatever `plan-work` left in chat.
2. Draft the detailed plan with `superpowers:writing-plans`. It goes in the workspace, git-ignored, and is never committed or published — it is scratch for the execution method, not a deliverable. **That skill ends by choosing an execution method and starting it; don't follow it there.** Stop once the plan has been through the skill's own self-review — not the moment the file lands, since that self-review is what makes the plan usable and nothing else performs it.
3. Dispatch `review-plan` with the target declared as the implementation plan. Fold every accepted Critical and Important finding in yourself — except one that invalidates the agreed design, which is not folded in at all: stop and take the **Design invalidated** exit below. Then re-run `review-plan`, handing over the record of the previous pass so it doesn't re-litigate rejected findings.
4. Leave by exactly one of three exits:
   - **Clean** — no blocking finding → **Execution**.
   - **Design invalidated** — a Critical finding that undoes the agreed design → stop and return to `plan-work`. It doesn't get worked around here.
   - **Capped** — three rounds run and a blocking finding survives that doesn't invalidate the design → stop, report the open findings and the disagreement, and let the user decide. Don't start a fourth round.

Don't restate a quality bar for the plan here. `superpowers:writing-plans` owns what a good plan contains, and `review-plan`'s lenses find where a particular plan falls short.

## Execution

Choose the method and say which you chose and why — explicitly, never by drift:

- **Default** → `superpowers:subagent-driven-development`.
- **A separate session picking the plan up later** → `superpowers:executing-plans`.
- **Manual** is an exception that needs a reason. Try first to replan the work into tasks that can each be verified on their own; do it yourself only when it genuinely won't split, or when workers aren't available. Name the reason.

This choice is wiring, so it lives here. `superpowers:writing-plans` would otherwise offer it, but the plan gate stops that skill before it gets there.

Delegate and don't restate: worker dispatch, model selection, the ban on parallel implementers, per-task review, the fix loop, and progress tracking all belong to `superpowers:subagent-driven-development`; TDD to `superpowers:test-driven-development`; parallel workers, for independent fact-finding only, to `superpowers:dispatching-parallel-agents`.

Two judgements stay here: delegation only pays when a task is big enough to cover the hand-off, so inline trivially small independent changes; and don't take on refactoring the task didn't ask for.

**The execution method does not carry the work into integration.** Its own procedure ends by presenting integration options; the completion gate runs first, and **Hand off** owns presenting them. What that cuts is the transition only — the method's own cleanup before it, such as removing its scratch workspace, still runs.

## Completion gate

Add only what the execution method left undone. Loop until nothing changes, then hand off:

1. **Verify** — `superpowers:verification-before-completion`.
2. **Simplify** — `simplify-code` on the recent diff only. No execution method has a simplification pass, so this is the gate's main job.
3. **Review** — skip `review-code` only when the method's own branch-wide review came back **clean**. Run it when any of these holds: findings were left unresolved or parked; no branch-wide review ran at all; or step 2 produced a diff nobody has reviewed. Record the call and its basis in **Report**.
4. Take the first of these that applies, in order — they are not independent, since a capped `review-code` still applies and verifies its fixes before stopping, so "changed something" and "hit its cap" can both be true at once:
   - **`review-code` reported a Critical finding that invalidates the agreed design** → stop the gate and return to `plan-work`, per **Escalation**. It can report this on any round, not only at its cap, so check for it before the cap condition.
   - **`review-code` stopped at its own cap with blocking findings open** → the whole gate halts here, whatever else changed. Report the open findings and let the user decide. Don't loop back, and don't re-invoke `review-code`.
   - **Step 2 or step 3 changed anything** → back to step 1. Verification and simplification have to run against the code as it now stands.
   - **Nothing changed and step 3 came back clean or was correctly skipped** → **Hand off**. This is the loop's only normal exit.

## Hand off

The deliverable is a branch of verified commits with no PR on it — exactly what `pr-to-ready` takes as its entry.

Use `superpowers:finishing-a-development-branch` to present the verified integration options, with two limits:

- **PR creation belongs to `pr-to-ready`.** If an option would push and open the PR, take the push and stop (`git push -u origin <branch>`), then invoke `pr-to-ready` to open it as a draft and drive it.
- **Integration goes through a PR.** Don't take an option that merges the branch into its base and ends the flow — that skips `pr-to-ready`, CI, and PR review entirely. If the user explicitly wants that, confirm they mean to skip the PR, then follow it.

## Report

- the execution method chosen, and why
- the `review-plan` rounds run on the detailed plan, and the final verdict
- whether the completion gate ran `review-code`, and on what basis if it didn't
- the concrete checks run, and any that couldn't be
- what changed and why
- assumptions made, and areas needing manual review

## Escalation

A Critical finding that invalidates the agreed design does not get fixed here — not in the plan gate and not in the completion gate. Stop and return to `plan-work`; the design needs re-approval, not a workaround.
