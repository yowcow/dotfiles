---
name: implement-work
description: Use to take one PR-sized task — a sub-issue, an issue that fits a single PR, or a request of that size — all the way to a pushed branch of verified commits. Establishes the isolated workspace and a verified baseline, drafts the detailed plan for that one PR and reviews it to convergence, declares and runs the execution method, then runs the completion gate and pushes the branch. Triggers on "implement this sub-issue", "start implementing", "work through this task", "run the completion gate", "take this to a branch".
---

# Implement Work

Use once the design is agreed and the work has been cut to one PR's worth. There is no plan yet — drafting and reviewing the detailed plan for this one PR happens here, first.

**The procedure lives in the skills this one calls.** What this skill owns is the wiring: which skill runs when, what each hand-off carries, and where the gates sit. It does not restate model selection, worker dispatch, review loops, progress tracking, or TDD mechanics — those belong to the skills that own them, and duplicating them here means maintaining them twice.

This skill holds two gates: one on the detailed plan, before any code, and the completion gate at the end. It does not own the PR-side loop — once a branch is handed off, `pr-to-ready` runs its own completion path, and neither gate here is re-entered from there.

## Orchestration model

**This skill dispatches no workers of its own.** It runs in the main loop as the orchestrator, and every worker in this flow is dispatched by a sub-skill it calls — `review-plan` on the detailed plan, the execution method on the tasks, `simplify-code` and `review-code` in the completion gate. Each of those declares its own fan-out, so read what it dispatches from its own declaration rather than assuming — and add no fan-out here.

- The orchestrator owns the task, the workspace, both gates, the execution-method choice, every commit, and the hand-off. It decides when a gate is clean — no worker declares that.
- Workers do bounded, single-task work and hand back. A worker is never given an objective spanning more than one task, and never advances the plan or a gate itself.

## Entry

One PR-sized task:

- a sub-issue,
- an issue that fits a single PR,
- or a request of that size.

Work larger than one PR, or a design not yet agreed, goes back to `plan-work`. Don't split it here — splitting is a design decision.

## Isolation

Establish this **before drafting the plan**: the plan file has to live inside the workspace the execution method will read it from, and a workspace created afterwards would not contain it — a new working tree gets the tracked content, not ignored scratch files.

Use `superpowers:using-git-worktrees`, then set the project up and establish a verified baseline there.

The contract behind the `Base-Branch:` trailer, the ladder that resolves the default branch, and why each test below is written the way it is all live in `<skill-dir>/references/base-branch.md` — `<skill-dir>` being wherever your runtime installed this skill (e.g. `~/.claude/skills/implement-work`, `~/.agents/skills/implement-work`). The commands and their result tests stay here, so a session that never opens that file still takes the right branch.

That skill detects existing isolation from the current directory only, and its creation step assumes the branch is new. So on resumption, look before creating:

1. If `git worktree list --porcelain | grep -Fxq "branch refs/heads/<branch>"`, reuse that workspace. Its path comes from the same output: `git worktree list --porcelain | grep -Fx -B2 "branch refs/heads/<branch>" | sed -n 's/^worktree //p'` — each block is `worktree <path>` / `HEAD <sha>` / `branch <ref>`, so the branch line's two predecessors carry the path. Keep `-F` and `-x`; they replace the `^`/`$` anchors rather than joining them.
2. Otherwise, if the branch exists locally, attach a workspace to it with `git worktree add <path> <branch>` — no `-b`. Test existence with `git show-ref --verify --quiet refs/heads/<branch>`, or by output emptiness: `[ -n "$(git branch --list <branch>)" ]`. Don't branch on `git branch --list`'s exit status — it exits 0 whether or not it matched.
3. Otherwise, if the branch exists only on the remote, attach a workspace that tracks it: `git fetch origin <branch>` first, then test with `git show-ref --verify --quiet refs/remotes/origin/<branch>` and run `git worktree add --track -b <branch> <path> origin/<branch>`. Check this before falling through to creating a branch — creating one afresh would strand the pushed work.
4. Otherwise create it normally, from the base that **Base branch** below settles.

### Base branch

Only step 4 needs this — steps 1-3 attach to a branch that already exists. The table below settles every case, including which of them stop.

A task with no tracking issue — the chat-only entry — has no relation to read at all: branch from the default branch. Everything below applies only when an issue backs the task.

Prerequisites come from the native relation, never from the issue body's prose:

```bash
gh issue view <task> --json blockedBy                          # → prerequisite issues
gh issue view <prereq> --json closedByPullRequestsReferences   # → its PR
gh pr view <pr> --json headRefName,state                       # → the branch, and which of the three states it is in
```

Test the first two by **count**: both come back as `{nodes, totalCount}`. Test the third by `state`, which is `OPEN`, `CLOSED`, or `MERGED`.

| Result | Base |
| --- | --- |
| `blockedBy.totalCount` is 0 | the default branch |
| the prerequisite's PR is `MERGED` | the default branch — fetch first, so that merge is actually in what you branch from |
| the prerequisite's PR is `OPEN` | that PR's `headRefName` |
| the prerequisite's PR is `CLOSED` without merging | **stop.** That work was abandoned, so stacking on it would carry rejected commits forward |
| the prerequisite has no PR at all | **stop.** It isn't implemented yet, so this task cannot start; report that |
| more than one prerequisite, or more than one PR reference | **stop and ask.** A branch takes exactly one base, so this is a human call |

**Record a non-default base** as a single `Base-Branch: <base>` line in the trailer block of this task's **first** commit — `<base>` the bare branch name, no `origin/` prefix and no `refs/heads/` path. Branching from the default branch records nothing. The reference above says why it is the first commit, and what each reader does with it.

Whenever an instruction names a command, say how its result is tested — a command that doesn't vary its exit status will otherwise get branched on wrongly.

If the verified baseline contradicts what the plan assumes — an existing failure, missing tooling — go back to **Plan gate** before starting tasks.

## Plan gate

1. Read the task. Where the design lives depends on the entry: a **sub-issue** carries its own body plus a link to the parent's design comment; an **issue that fits one PR** carries its own comment; a **request with no issue** is itself the input, together with whatever `plan-work` left in chat.
2. Draft the detailed plan with `superpowers:writing-plans`. It goes in the workspace, git-ignored, and is never committed or published — it is scratch for the execution method, not a deliverable. **That skill ends by choosing an execution method and starting it; don't follow it there.** Stop once the plan has been through the skill's own self-review — not the moment the file lands, since that self-review is what makes the plan usable and nothing else performs it.
3. Dispatch `review-plan` with the target declared as the implementation plan. Fold every accepted finding in yourself — except one that invalidates the agreed design, which is not folded in at all: stop and take the **Design invalidated** exit below. Then re-run `review-plan`, handing over the record of the previous pass so it doesn't re-litigate rejected findings.
4. Leave by exactly one of three exits:
   - **Clean** — no blocking finding → **Execution**.
   - **Design invalidated** — a Critical finding that undoes the agreed design → take **Escalation**.
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

**The execution method does not carry the work into integration.** Its own procedure ends by presenting integration options; the completion gate runs first, and **Hand off** owns the terminal step. What that cuts is the transition only — the method's own cleanup before it, such as removing its scratch workspace, still runs.

## Completion gate

Add only what the execution method left undone. Loop until nothing changes, then hand off:

1. **Verify** — `superpowers:verification-before-completion`.
2. **Simplify** — `simplify-code` on the recent diff only. No execution method has a simplification pass, so this is the gate's main job.
3. **Review** — skip `review-code` only when the method's own branch-wide review came back **clean**. Run it when any of these holds: findings were left unresolved or parked; no branch-wide review ran at all; or step 2 produced a diff nobody has reviewed. Record the call and its basis in **Report**.
4. **Commit** the round's work, in the same round that produced it, so the tree is clean before any exit below is taken. A round that changed nothing commits nothing.
   - **What goes in** — whatever steps 2 and 3 changed, plus any `.gitignore` entry added under the third bullet: that entry is part of leaving the tree clean, not a separate concern.
   - **Confirm it worked** — `git status --porcelain`, tested by **output emptiness, not exit status**, since it exits 0 whether or not anything is pending. **Don't leave this step while the tree is dirty**; that is precisely what would break the guarantee in the last bullet.
   - **Account for anything still left, rather than sweeping it in** — work this task produced belongs in the commit; a byproduct of step 1's checks belongs in `.gitignore`, and the byproduct itself is never committed; anything you cannot account for stops the gate and goes to the user, since committing an edit that isn't yours is worse than halting.
   - **Why this precedes the exits** — both of them hand over the branch rather than the worktree. **Hand off** pushes the branch, and a push carries *commits*, so an uncommitted edit never reaches the remote — and it goes down with the worktree whenever that is removed. **Escalation** hands `plan-work` a branch name, and re-approval is judged against what that branch contains, so an edit left uncommitted is simply absent from what the next flow reads.
5. Take the first of these that applies, in order — they are not independent, since a capped `review-code` still applies and verifies its fixes before stopping, so "changed something" and "hit its cap" can both be true at once:
   - **`review-code` reported a Critical finding that invalidates the agreed design** → stop the gate and return to `plan-work`, per **Escalation**. It can report this on any round, not only at its cap, so check for it before the cap condition.
   - **`review-code` stopped at its own cap with blocking findings open** → the whole gate halts here, whatever else changed. Report the open findings and let the user decide. Don't loop back, and don't re-invoke `review-code`.
   - **Step 2 or step 3 changed anything** → back to step 1. Verification and simplification have to run against the code as it now stands.
   - **Nothing changed and step 3 came back clean or was correctly skipped** → **Hand off**. This is the loop's only normal exit.

## Hand off

The deliverable is a **pushed** branch of verified commits with no PR on it — exactly what `pr-to-ready` takes as its entry. Once the completion gate takes its normal exit, push it, unconditionally:

```bash
git push -u origin <branch>
```

The push is what turns the branch into a deliverable rather than local state: `gh pr create` opens a PR from a remote ref, so an unpushed branch leaves the next flow nothing to enter on — in a later session, or a checkout that never held the branch.

Then stop, and name `pr-to-ready` as the next entry **without invoking it**. Which flow runs next is the caller's decision, not this skill's.

Two limits hold at that stop:

- **PR creation belongs to `pr-to-ready`.** Don't run `gh pr create` here.
- **Integration goes through a PR.** Merging this branch into its base instead of handing it over would skip `pr-to-ready`, CI, and PR review entirely. If the user explicitly wants that, confirm they mean to skip the PR before doing it — this skill carries no merge procedure of its own.

Don't call `superpowers:finishing-a-development-branch` here, and don't reinstate the call. Everything it offers is already settled: its verification by the completion gate, the base branch it would confirm by the `Base-Branch:` trailer, and its local-merge option by the limit just above — which leaves only the push, written out above.

## Report

- the execution method chosen, and why
- the base branch the task was created from, and which of **Base branch**'s outcomes chose it
- the `review-plan` rounds run on the detailed plan, and the final verdict
- whether the completion gate ran `review-code`, and on what basis if it didn't
- the concrete checks run, and any that couldn't be
- what changed and why
- the pushed branch, and `pr-to-ready` named as the next entry
- assumptions made, and areas needing manual review

## Escalation

Per the guidelines' **Escalation**: a Critical finding that invalidates the agreed design goes back to `plan-work` for re-approval, and this skill is no exception — not in the plan gate, and not in the completion gate.

What this flow hands over is the branch: its name, and whether it is pushed. `plan-work`'s **Entry** says what it does with that. Where the finding surfaced in the completion gate, the branch already carries the round's commits, since the gate commits before taking either exit.
