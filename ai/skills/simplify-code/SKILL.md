---
name: simplify-code
description: Use after implementation and before code review or PR creation to simplify recently modified code while preserving behavior. Applies project standards, improves clarity and maintainability, avoids clever rewrites, and verifies the result. Triggers on "simplify this", "clean up the diff", "run a code-simplifier pass", "tidy this up before review".
---

# Simplify Code

Use after code changes and before `superpowers:requesting-code-review`.

One invocation is one simplification pass, and the pass owns its apply-verify loop: propose, apply, run the checks, propose again, until nothing actionable is left. What it does not own is re-entry — simplifying again after something else changes the code belongs to the caller; in the Change workflow, the guidelines' completion gate owns that.

## Roles

- The orchestrator owns this pass: it dispatches proposers, judges what they return, applies the accepted proposals, verifies, and reports. It decides when nothing actionable remains — a proposer never does.
- Proposers are read-only workers. Each gets the diff, the paths it touches, the standards that apply, and its assigned lenses, and returns proposals only. A proposer never edits code, never runs the project's checks, and never declares the pass clean.
- Proposers stay read-only for two reasons: it matches how the other local skills treat workers (`pr-to-ready` keeps every code change, commit, and push in the orchestrator), and `superpowers:verification-before-completion` makes the orchestrator re-verify a worker's claims anyway — so letting a worker apply and self-verify buys nothing.
- What a proposer buys is a fresh context: it reads the diff without having written it, so it is not anchored on why the code ended up this way.

## Scope

- Focus on recently modified code and the current diff; don't broaden cleanup unless the user asks.
- If a worthwhile simplification needs files outside the diff, report it instead of changing it.
- Preserve behavior exactly: outputs, public APIs, data migrations, test intent, and user-visible semantics.
- When the existing checks can't prove a simplification behavior-preserving, add the minimal characterization test that can, and say so in the report. That's the proof, not scope creep.

## Standards

Follow local standards over generic preferences — check `AGENTS.md`/`CLAUDE.md`/`GEMINI.md` or shared guidelines, README and contributor docs, the formatter/linter/typechecker/test config, and nearby code for style.

## Lenses

Each lens is a distinct kind of avoidable complexity, and every one is behavior-preserving. How many proposers they map to is decided in **Dispatch** below.

- **Structure** — unnecessary complexity, nesting, or branching; redundant or duplicated logic; avoidable abstractions; unclear names; related logic scattered where it could be consolidated.
- **Cost** — work the change itself added beyond what its result needs, where the excess is evident from reading the diff rather than from a measurement: per-iteration queries or IO that one call covers, recomputed loop invariants, data read twice, intermediate collections nothing consumes, a scan where the code it replaced had a direct lookup. Reshape to the same result at the lower cost.
- **Noise** — formatting churn unrelated to the task; comments that merely restate the code; tests that can be clearer without weakening coverage.

## Don't over-simplify

- No clever one-liners or dense expressions just to cut lines; no nested ternaries for multi-branch logic (prefer `if`/`else` or `switch`).
- Keep helpful abstractions and separation of concerns; don't merge unrelated concerns into one unit.
- Don't make code harder to debug, extend, or review.
- Don't optimize speculatively: anything whose justification needs a measurement — a different algorithm for scale, caching, concurrency, precomputed indexes — is out of scope. Report it and leave it to `investigate-performance`. Repairing cost the diff itself introduced is not speculative, and the baseline decides which it is: restoring the cost the code had before the change is in scope, making it cheaper than it has ever been is not.

## Dispatch

Proposers are read-only and share no mutable state, so they may run in parallel (`superpowers:dispatching-parallel-agents` — this is independent fact-finding, not implementation). Splitting further than the diff warrants only pays handoff cost, so size the fan-out to the diff:

- **Default** — one proposer takes every lens. A diff is a smaller object than a plan, and delegation has to be worth its handoff.
- **Large diff, or one spanning subsystems** — one proposer per lens, dispatched together.

Dispatch a fresh proposer each round and give it the diff as it now stands, not the previous round's proposals — a proposer shown what was just applied anchors on it. Inline **Scope**, **Standards**, **Lenses**, and **Don't over-simplify** into the prompt so the proposer doesn't go hunting for them, and confine its searches to the project root or narrower.

## Proposal contract

Each proposer returns proposals only — never an edited file — with:

- **location** — `path:line` within the diff, numbered as the file now stands.
- **lens**.
- **change** — what the code should say instead.
- **behavior preservation** — why the change cannot alter behavior, and which existing check would catch it if it did. When no existing check can prove it, propose the minimal characterization test that would, per **Scope**.

Report "no proposals" explicitly rather than inventing one.

## Pass

1. Gather the inputs: the diff, the paths it touches, and the standards that apply.
2. Dispatch proposers against the diff, sized per **Dispatch**.
3. Evaluate every proposal with `superpowers:receiving-code-review`: reject — with a stated reason — anything that changes behavior, that needs a measurement to justify it (see **Don't over-simplify**), that reaches outside the diff (see **Scope**), or that only reflects proposer preference.
4. Apply the accepted proposals yourself, then verify with the concrete commands the project defines — in the README, Makefile, package scripts, or CI — and read their actual output.
5. Loop back to step 2 with a fresh proposer while actionable simplification remains.
6. Report per **Report**.

## Report

- the fan-out used
- what changed, and what behavior was preserved
- proposals rejected, with the reason
- what verification ran, and its actual result
- any simplification left undone, including anything reported instead of changed
