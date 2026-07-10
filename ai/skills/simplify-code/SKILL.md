---
name: simplify-code
description: Use after implementation and before code review or PR creation to simplify recently modified code while preserving behavior. Applies project standards, improves clarity and maintainability, avoids clever rewrites, and verifies the result.
---

# Simplify Code

Use after code changes and before `superpowers:requesting-code-review`, or whenever asked to "simplify" or run a code-simplifier pass.

## Scope

- Focus on recently modified code and the current diff; don't broaden cleanup unless the user asks.
- If a worthwhile simplification needs files outside the diff, report it instead of changing it.
- Preserve behavior exactly: outputs, public APIs, data migrations, test intent, and user-visible semantics.

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
2. Verify with the relevant tests, lint, build, typecheck, or manual check; repeat until no actionable simplification remains.
3. Report what changed, what behavior was preserved, what verification ran, and any intentionally deferred cleanup.
