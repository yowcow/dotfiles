#!/usr/bin/env bash
# Find the @claude review workflow and, optionally, block until one of its runs
# finishes. Completion is tied to the workflow run rather than guessed from
# comment counts, which is why this exists as a command at all.
#
# With no run-id: prints the workflow's recent runs on <branch> as JSON, so the
# caller can match a run to its own push by headSha rather than taking the
# newest and risking a stale one.
# With a run-id: blocks on that run.
#
# Usage: watch-claude-review.sh <branch> [run-id]
#
# Exit: 0 = run finished, or the listing printed
#       1 = no @claude workflow in this repository
#       2 = usage error
#       other = gh run watch reporting the watched run's own failure
set -euo pipefail

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  echo "Usage: $0 <branch> [run-id]" >&2
  exit 2
fi

BRANCH="$1"
RUN_ID="${2:-}"

# grep exits 1 when nothing matches, which set -e would turn into an abort, so
# the substitution is guarded and the emptiness of wf is what gets tested.
wf="$({ grep -rl '@claude' .github/workflows/ 2>/dev/null || true; } | head -1)"
if [ -z "$wf" ]; then
  echo "no @claude workflow found in .github/workflows/ — skip the Claude wait" >&2
  exit 1
fi
wf="$(basename "$wf")"

if [ -z "$RUN_ID" ]; then
  gh run list --workflow="$wf" --branch "$BRANCH" --limit 5 \
    --json databaseId,status,headSha,conclusion
  exit 0
fi

gh run watch "$RUN_ID" --exit-status
