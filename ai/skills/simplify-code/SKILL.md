---
name: simplify-code
description: Use after implementation and before code review or PR creation to simplify recently modified code while preserving behavior. Applies project standards, improves clarity and maintainability, avoids clever rewrites, and verifies the result. Triggers on "simplify this", "clean up the diff", "run a code-simplifier pass", "tidy this up before review".
---

# Simplify Code

Use after code changes and before `superpowers:requesting-code-review`.

One invocation is one simplification pass, and the pass owns its apply-verify loop: refine, run the checks, refine again, until nothing actionable is left. What it does not own is re-entry — simplifying again after something else changes the code belongs to the caller; in the Change workflow, the guidelines' completion gate owns that.

## Scope

- Focus on recently modified code and the current diff; don't broaden cleanup unless the user asks.
- If a worthwhile simplification needs files outside the diff, report it instead of changing it.
- Preserve behavior exactly: outputs, public APIs, data migrations, test intent, and user-visible semantics.
- When the existing checks can't prove a simplification behavior-preserving, add the minimal characterization test that can, and say so in the report. That's the proof, not scope creep.

## Standards

Follow local standards over generic preferences — check `AGENTS.md`/`CLAUDE.md`/`GEMINI.md` or shared guidelines, README and contributor docs, the formatter/linter/typechecker/test config, and nearby code for style.

## What to simplify (behavior-preserving)

- unnecessary complexity, nesting, or branching; redundant or duplicated logic
- avoidable abstractions; unclear names; related logic scattered where it could be consolidated
- formatting churn unrelated to the task; comments that merely restate the code
- tests that can be clearer without weakening coverage

## Don't over-simplify

- No clever one-liners or dense expressions just to cut lines; no nested ternaries for multi-branch logic (prefer `if`/`else` or `switch`).
- Keep helpful abstractions and separation of concerns; don't merge unrelated concerns into one unit.
- Don't make code harder to debug, extend, or review.

## Process

1. From the diff, identify the recently modified code and apply only behavior-preserving refinements.
2. Verify with the concrete commands the project defines — in the README, Makefile, package scripts, or CI — and read their actual output. Loop back to step 1 while actionable simplification remains.
3. Report what changed, what behavior was preserved, what verification ran, and any simplification left undone.
