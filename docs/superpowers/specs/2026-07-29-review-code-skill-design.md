# `review-code` Skill Design

## Goal

Add a local skill, `review-code`, that runs the review-and-remediate loop to completion in a single invocation: dispatch a code reviewer, judge its findings, apply the accepted fixes, verify them, and review again until no blocking finding remains.

Two problems motivate it:

- **The loop is currently open-coded in the guidelines, in two places.** `ai/GUIDELINES.md:82` (per-task review during Implement) and `ai/GUIDELINES.md:97` (completion gate step 4) each spell out "request review with `superpowers:requesting-code-review`, then evaluate with `superpowers:receiving-code-review`" and leave the iteration implicit. One skill removes the duplication and makes the loop explicit.
- **There is no entry point for reviewing code in an arbitrary state.** `superpowers:requesting-code-review` is written around a `BASE_SHA`..`HEAD_SHA` range, so an uncommitted working tree has no defined way in. `review-code` resolves the scope itself, so "review this code and fix what's wrong" works whatever state the tree is in.

## Non-goals

- Not a replacement for the completion gate. The gate keeps its Verify → Simplify → Repeat steps; `review-code` replaces only its Review step.
- Not a re-implementation of code review. Reviewers are dispatched through `superpowers:requesting-code-review` and its `code-reviewer.md` template; findings are judged with `superpowers:receiving-code-review`. The skill adds scope resolution, the loop, and remediation — no new lens taxonomy.
- Not GitHub-facing. Review by Claude and Copilot on a PR, thread replies, and thread resolution stay with `pr-to-ready`.
- Does not commit. Applying fixes is in scope; committing them is the caller's, per the guidelines' Git & PR workflow.

## Ownership

`review-code` owns: resolving the review scope, dispatching the reviewer, judging findings, applying accepted fixes, verifying those fixes, and deciding when the loop ends.

`review-code` does not own: re-entry after something else changes the code, the simplification pass, commits, and any GitHub interaction.

The name pairs with `review-plan`, but the behaviour is deliberately asymmetric — `review-plan` is one pass with the loop outside, `review-code` owns its loop, matching `simplify-code`. The skill states this in its opening lines so the asymmetry is never inferred from the name.

## Scope resolution

The skill resolves what to review in this order, and declares the resolved scope before dispatching anything:

1. **Caller-supplied** — a SHA range, paths, or a PR. Use it as given.
2. **Uncommitted changes present** — review the working tree diff: staged, unstaged, and untracked files.
3. **Clean tree** — review `merge-base(<default branch>, HEAD)..HEAD`. Resolve the default branch rather than assuming `main`: `git symbolic-ref refs/remotes/origin/HEAD` (this repository's is `origin/master`), falling back to `gh repo view --json defaultBranchRef` and then to asking the user. Never guess a branch name.
4. **Nothing to review** — ask the user. Never widen to the whole repository on a guess.

### Handing an uncommitted scope to the reviewer

`code-reviewer.md` has a **Git Range to Review** block built from `[BASE_SHA]`/`[HEAD_SHA]`. For an uncommitted scope, substitute that block with the concrete commands that show the same thing — `git status --porcelain`, `git diff`, `git diff --cached`, and the untracked paths — and keep the template's read-only rule.

The template's suggestion to check a revision out into a temporary worktree does not apply to an uncommitted scope: a worktree at any revision will not contain the uncommitted changes. The reviewer reads the files in place, and still must not mutate the working tree, the index, HEAD, or branch state.

### When there are no stated requirements

`[PLAN_OR_REQUIREMENTS]` has no obvious filler when the skill is invoked standalone on arbitrary code. Fill it with the original request when one exists. When none does, state in the prompt that there are no stated requirements and that the review runs against the repository's own standards and the code's evident intent — and say the same in the report, so a reader knows plan alignment was not checked.

## The pass

1. Resolve the scope per **Scope resolution** and declare it.
2. Dispatch one reviewer via `superpowers:requesting-code-review`, filling the template per the sections above.
3. Judge every finding with `superpowers:receiving-code-review`. Verify each claim against the code before accepting it. Reject — with a stated reason — findings that are wrong, that only reflect reviewer preference, or that ask for work beyond the request.
4. Apply the accepted Critical and Important findings yourself. For a finding that describes a bug, write the failing regression test first and watch it fail, then fix it (`superpowers:test-driven-development`). Record Minor findings; do not fix them.
5. Verify with the concrete commands the project defines — in the README, Makefile, package scripts, or CI — and read their actual output.
6. While a blocking finding remains, return to step 2 with a **fresh reviewer**, giving it the code as it now stands plus the record of the previous rounds: what was accepted and fixed, and what was rejected and why. A reviewer shown the previous round's findings anchors on them; a reviewer not shown the rejections re-litigates them.
7. Report per **Report**.

One reviewer per round, always. A diff is a smaller object than a plan, and splitting the review further only pays handoff cost.

The pass is clean when no Critical or Important finding survives step 3. Minor findings are recorded, not blocking.

## Convergence and escalation

- A round is one review → judge → fix → verify cycle. The loop ends clean when a round's review produces no blocking finding.
- Five rounds at most. If the fifth round's review still produces blocking findings, apply and verify them as usual, then stop instead of starting a sixth review — and report those fixes as applied but not re-reviewed, together with any disagreement. Never report clean on the strength of fixes no review has seen.
- Five here, against three for `review-plan`, is deliberate: a plan that needs a fourth pass usually has a disagreement only the user can settle, while code review converges by fixing one concrete finding at a time and a later round often surfaces something the earlier ones could not reach. Don't "align" the two numbers.
- A Critical finding that invalidates the approved design does not get fixed in the loop. Stop and return to `superpowers:brainstorming` for design approval, per the guidelines' **Escalation**.

## Report

Report to the caller in chat. Never post to GitHub — a loop's intermediate state is orchestrator-facing, and one comment per round is noise. Report:

- the scope reviewed and how it was resolved, including whether requirements were available
- the number of rounds run
- accepted findings, with location and what was changed
- rejected findings, with the reason
- the remaining Minor findings
- what verification ran, and its actual result
- the verdict: clean, or the blocking findings that remain

## Wiring

**`ai/skills/review-code/SKILL.md`** — new skill. Frontmatter `name` and `description` follow the local convention: what it is for, what it does, and the trigger phrases (`"review this code"`, `"review and fix"`, `"run the review loop until it's clean"`).

**`ai/GUIDELINES.md`** — replace both open-coded call sites:

- `:82` (Implement) — per-task review becomes a `review-code` invocation. Keep the existing severity rule: Critical stops progress, Important is resolved before the next task.
- `:97` (completion gate step 4) — the Review step becomes a `review-code` invocation that returns clean. Keep the sentence that accepted fixes return to the gate's verification, simplification, and review path: the loop's fixes change the code, so the gate still has to re-verify and re-simplify around it.

**`Makefile:75`** — add `review-code` to `AI_SKILL_NAMES`. The list is hand-maintained, not globbed, so a new skill directory alone installs nothing.

## Verification

- `make -n install | rg review-code` shows symlink targets for all five assistant directories.
- `rg -n 'requesting-code-review|receiving-code-review' ai/GUIDELINES.md` shows the loop is no longer open-coded at the two call sites.
- Read the new `SKILL.md` against `ai/skills/review-plan/SKILL.md` and `ai/skills/simplify-code/SKILL.md`: frontmatter shape, section names, and the roles/loop-ownership statements are consistent with both.
