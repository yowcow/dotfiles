---
name: investigate-failure
description: Use when root-causing an observed failure or incident — production errors, an outage, a crashed job, or a bug that only manifests in a live environment — before any fix is proposed. Preserves evidence, reconstructs the timeline, correlates logs and metrics with changes (deploys, config, data, expiries), tests hypotheses against evidence, and produces a blameless findings report. Triggers on "why did this break", "root-cause this incident", "errors spiked", "what happened last night", "write the postmortem".
---

# Investigate Failure

Root-cause an observed failure or incident. The deliverable is a blameless findings report, not a diff. The hypothesis discipline is `superpowers:systematic-debugging` — this skill does not restate it; it adds the failure-specific layers: evidence preservation, timeline, change correlation, and reporting. For a bug that reproduces locally on demand, `superpowers:systematic-debugging` alone may suffice; this skill earns its keep when the failure is historical, distributed, or environment-bound.

## Rules

- Tag every statement in notes and the report as **observed** or **conjectured**.
- Blameless: name systems and conditions, never people.
- Investigation is read-only: never mutate production state (restarts, config, data) without explicit user approval.
- Preserve volatile evidence before anything else.

## Step 1: Capture and preserve

- Record the exact error text/codes, first and last occurrence, scope (which users/hosts/requests), and current status (ongoing vs recovered).
- Snapshot anything that rotates or expires: logs, dashboards, queue depths, process state.

## Step 2: Reconstruct the timeline

- Use a single stated timezone.
- Anchor **last known good** and **first known bad**, then interleave symptoms with events.
- A gap you cannot narrow between last-good and first-bad is itself a finding — record it.

## Step 3: Correlate with changes

Sweep every change class across the last-good → first-bad window:

- deploys and rollbacks
- config and feature flags
- infrastructure changes
- dependency and upstream-service changes
- data shape or volume shifts; traffic pattern shifts
- scheduled jobs
- time-based expiries: certs, tokens, TTLs, quotas, disk filling

## Step 4: Test hypotheses

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
