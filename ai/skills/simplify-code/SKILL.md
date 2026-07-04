---
name: simplify-code
description: Use after implementation and before code review or PR creation to simplify recently modified code while preserving behavior. Applies project standards, improves clarity and maintainability, avoids clever rewrites, and verifies the result.
---

# Simplify Code

Use this after code changes and before `superpowers:requesting-code-review`, or whenever the user asks for `/simplify`, "simplify", "code-simplifier", or an equivalent cleanup pass.

## Scope

- Focus on recently modified code and the current diff.
- Do not broaden cleanup unless the user explicitly asks.
- Preserve exact behavior, outputs, public APIs, data migrations, test intent, and user-visible semantics.
- Prefer readable, explicit code over overly compact code.

## Project Standards

Before changing code, inspect the relevant local standards and nearby examples:

- `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, or shared AI guidelines when present
- README files and contributor docs
- formatter, linter, typechecker, and test configuration
- nearby code that demonstrates the local style

Apply project-specific standards rather than generic preferences.

## Simplification Checklist

Look for changes that improve clarity, consistency, or maintainability without changing behavior:

- unnecessary complexity, nesting, or branching
- redundant code or duplicated logic
- avoidable abstractions
- unclear names
- scattered related logic that can be consolidated safely
- noisy formatting churn unrelated to the task
- comments that merely restate obvious code
- tests that can be clearer without weakening coverage

## Balance Rules

Avoid over-simplification:

- Do not replace readable code with clever one-liners.
- Do not use dense expressions just to reduce line count.
- Avoid nested ternary operators for multi-branch logic; prefer clear `if`/`else` or `switch` style where available.
- Do not combine too many concerns into one function, component, method, or module.
- Do not remove helpful abstractions or separation of concerns.
- Do not make code harder to debug, extend, or review.

## Process

1. Identify the recently modified code sections from the current diff.
2. Analyze opportunities to improve clarity and consistency.
3. Apply only behavior-preserving refinements.
4. Verify the refined code with the relevant tests, lint, build, typecheck, smoke test, or manual check.
5. Repeat until no actionable simplification remains.
6. Document only significant simplification changes that affect understanding.

## Output

Report:

- what simplification changed
- what behavior was preserved
- what verification was run
- any intentionally deferred cleanup
