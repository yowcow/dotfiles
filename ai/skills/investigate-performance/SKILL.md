---
name: investigate-performance
description: Use when diagnosing an observed performance shortfall — a slow endpoint, job, or query, a latency/throughput regression, or CPU/memory growth — to root-cause it with measurements before any fix is proposed. Establishes a baseline and reproduction, profiles layer by layer (system → runtime → application → query/IO), keeps an evidence log, and produces a findings report. Triggers on "why is this slow", "latency spiked", "perf regression", "high CPU", "memory keeps growing", "find the bottleneck".
---

# Investigate Performance

Root-cause an observed performance shortfall. The deliverable is a findings report, not a diff. The hypothesis discipline is `superpowers:systematic-debugging` — this skill does not restate it; it adds the performance-specific layers: what to measure, in what order, and how to report.

## Rules

- Measure before guessing: no fix proposal without a number behind it.
- Change one variable per measurement.
- Account for variance and warm-up before trusting a delta.
- Record every measurement in the evidence log, including refuting ones.

## Orchestration (subagents)

When parallel workers are available, run this skill as an orchestrator: delegate independent, read-only measurements; keep hypothesis selection, the evidence log, and the report in the main loop (per the Investigation workflow in the shared AI guidelines).

- Descending the layers (Step 3) stays sequential by design — which layer to drill into depends on the previous measurement.
- Within a layer, independent measurements (CPU vs memory vs IO saturation; several common suspects) can each go to a worker; workers return numbers and observations only, never verdicts.

## Step 1: Frame and baseline

- Define the exact metric (p50/p99 latency, throughput, RSS, CPU%) and the target or prior value it is measured against.
- Fix the environment: hardware, dataset size, concurrency.
- Record the baseline numbers and the exact command that produced them.

## Step 2: Reproduce reliably

- Build a minimal reproduction with a realistic load shape; run it at least 3 times and note variance.
- If it only reproduces in production, define the observation window and metrics instead — never load-test production without explicit user approval.

## Step 3: Profile layer by layer

Descend the layers, measuring each one's share of the total cost; stop at the first layer that accounts for the shortfall before drilling in.

1. **System** — CPU/memory/disk/network saturation and errors (USE method); swapping, throttling, noisy neighbors.
2. **Runtime** — GC pressure and pause time; scheduler/thread/goroutine/process-pool saturation; connection pools. Use the language's native profiler (e.g. pprof, NYTProf, Xdebug/Blackfire, fprof/recon, `--cpu-prof`).
3. **Application** — hot paths, repeated work in loops, lock contention, serialization cost, chatty external calls.
4. **Query/IO** — slow queries and their plans, missing indexes, N+1 patterns, round-trip counts, payload sizes.

## Common suspects

- N+1 queries; missing or unused index
- unbounded concurrency or pool exhaustion
- allocation/GC pressure; per-request work that could be cached
- retry storms; oversized payloads
- cold cache in the measurement itself; measuring the wrong thing (client vs server time)

## Evidence log

Keep a running table — it is the backbone of the report:

| hypothesis | measurement taken | result | verdict (confirmed/refuted/inconclusive) |
|---|---|---|---|

## Exit criteria

- A named bottleneck whose measured contribution explains the observed shortfall's magnitude — not just "found something slow"; or
- documented dead ends, each with the measurement that would settle it.

## Report format

1. **Summary** — one paragraph.
2. **Numbers** — baseline vs observed vs target.
3. **Root cause** — with the decisive measurement.
4. **Contributing factors**
5. **Fix options** — expected gain and cost of each.
6. **Open questions**

Implementing any fix goes through the Change workflow in the shared AI guidelines — do not start editing from this skill.
