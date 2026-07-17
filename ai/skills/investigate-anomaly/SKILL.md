---
name: investigate-anomaly
description: Use when root-causing an observed anomaly — production errors, an outage, a crashed job, an error-rate spike, unexplained cost or resource growth, or a metric drifting the wrong way — before any fix is proposed. Frames vague concerns into measurable symptoms, preserves evidence, reconstructs the timeline, correlates logs and metrics with changes (deploys, config, data, expiries), tests hypotheses against evidence, and produces a blameless findings report. Triggers on "why did this break", "root-cause this incident", "errors spiked", "costs keep growing", "this metric looks wrong", "what happened last night", "write the postmortem".
---

# Investigate Anomaly

Root-cause an observed anomaly: a failure, an incident, or an unexplained change in a metric such as error rate, cost, or resource usage. The deliverable is a blameless findings report, not a diff. The hypothesis discipline is `superpowers:systematic-debugging` — this skill does not restate it; it adds the anomaly-specific layers: framing, evidence preservation, timeline, change correlation, and reporting. For a bug that reproduces locally on demand, `superpowers:systematic-debugging` alone may suffice; this skill earns its keep when the anomaly is historical, distributed, or environment-bound. For a performance shortfall with a clear metric, prefer `investigate-performance`.

## Rules

- Tag every statement in notes and the report as **observed** or **conjectured**.
- Blameless: name systems and conditions, never people.
- Investigation is read-only: never mutate production state (restarts, config, data) without explicit user approval.
- Preserve volatile evidence before anything else.

## Orchestration (subagents)

When parallel workers are available, run this skill as an orchestrator: delegate independent, read-only evidence-gathering; keep hypothesis selection, conclusions, and the report in the main loop (per the Investigation workflow in the shared AI guidelines).

- Step 2 sources (logs, dashboards, queue/process state, usage exports) can be captured by one worker per source.
- Step 4 change classes are independent — fan out one worker per class; the orchestrator merges the results into the timeline.
- Hypothesis testing (Step 5) stays sequential in the orchestrator: each verdict informs the next hypothesis choice.

## Step 1: Frame the symptom

- Turn a vague concern ("costs keep growing", "something has felt off lately") into a measurable statement: which metric, where, since when, at what scope, and how large the deviation is against what baseline or expectation.
- If no number can be attached yet, producing one is the first evidence-gathering task — an anomaly that cannot be measured cannot be root-caused.

## Step 2: Capture and preserve

- Record the symptom as observed: exact error text/codes or metric values and their source, first and last occurrence, scope (which users/hosts/requests/services), and current status (ongoing vs recovered).
- Snapshot anything that rotates or expires: logs, dashboards, queue depths, process state, billing/usage exports.

## Step 3: Reconstruct the timeline

- Use a single stated timezone.
- Anchor **last known good** and **first known bad**, then interleave symptoms with events.
- A gap you cannot narrow between last-good and first-bad is itself a finding — record it.

## Step 4: Correlate with changes

Sweep every change class across the last-good → first-bad window:

- deploys and rollbacks
- config and feature flags
- infrastructure changes
- dependency and upstream-service changes
- data shape or volume shifts; traffic pattern shifts
- scheduled jobs
- time-based expiries: certs, tokens, TTLs, quotas, disk filling
- pricing, plan, or quota changes (for cost anomalies)

## Step 5: Test hypotheses

- Cheapest decisive check first; one variable at a time.
- Seek disconfirming evidence: "if this were the cause, X would also be true — is it?"
- Distinguish **root cause** (the defect) from **trigger** (what activated it now) from **contributing factors** (what widened the blast radius).

## Evidence log

Keep a running table — it is the backbone of the report:

| hypothesis | check performed | result | verdict (confirmed/refuted/inconclusive) |
|---|---|---|---|

## Exit criteria

- The explanation accounts for the timeline (why then), the scope (why those and not others), and the symptom's shape; or
- the unknowns are explicitly documented, with the monitoring or logging needed to catch the next occurrence.

## Report format (blameless)

1. **Summary** — one paragraph.
2. **Impact** — who/what, duration, severity.
3. **Timeline**
4. **Root cause / Trigger / Contributing factors**
5. **Detection gaps** — why it wasn't caught sooner.
6. **Remediation options** — immediate mitigation vs preventive fixes.
7. **Open questions**

Language and tone follow the shared AI guidelines' Communication rules when the report is posted anywhere. Fixes go through the Change workflow in the shared AI guidelines — do not start editing from this skill.
