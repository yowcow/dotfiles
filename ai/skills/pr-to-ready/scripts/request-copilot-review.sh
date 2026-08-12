#!/usr/bin/env bash
# Request a Copilot review on a PR and confirm the request actually took.
#
# This exists as a command because the request cannot be judged from any single
# call's exit status, and because the surface that answers "did it take?" is not
# the obvious one. The reviewer flag and the requested_reviewers REST endpoint
# are alternatives rather than a sequence: neither may be trusted on its status
# or chained with ||, and only a readback settles whether the request took.
#
# That readback reads the issue timeline and never the pull request's
# requested_reviewers: Copilot is a Bot, and that endpoint reports only .users
# and .teams, so Copilot is absent from it even while its request is live. Keyed
# on it, this script reported Copilot permanently unavailable while itself
# successfully requesting the review every run. The measurement:
# ../references/gh-mechanics.md.
#
# The count is taken BEFORE any request is sent, because a previous round's
# event is still on the timeline and an absolute count would read as success
# with nothing having landed. The comparison is monotone, so which of the two
# attempts produced the event does not matter.
#
# Both attempts have their stdout dropped and their exit status ignored, on
# purpose; their stderr is left visible so a stuck run has something to read.
#
# Usage: request-copilot-review.sh <owner> <repo> <pr-number>
#
# Exit: 0 = a Copilot review request landed (the flag took, or the REST form did)
#       2 = usage error
#       3 = no request landed after both forms — the answer, not a failure:
#           treat Copilot as unavailable here and skip it
#       4 = the timeline could not be read. Failing to *read* it is not the same
#           as nothing having landed — stop and inspect
#       other = the run was interrupted, or the shell itself failed — stop and
#           inspect. No gh call reaches this: both attempts have their status
#           discarded, and a readback that fails is the exit 4 above
set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <owner> <repo> <pr-number>" >&2
  exit 2
fi

OWNER="$1"
REPO="$2"
PR="$3"

# The event is not guaranteed to be on the timeline the instant the request call
# returns, so the readback is retried over a few seconds — the same kind of
# bounded re-read as gh-mechanics.md's on `mergeable`, and nothing like 2-2's
# wait for the review itself.
READBACK_TRIES=5
READBACK_INTERVAL=2

# Sets COUNT to the number of Copilot review requests on the timeline. A
# timeline that cannot be read exits 4 rather than answering 0 — which is why
# this is called as a statement and never inside $(...): there, the exit would
# leave the caller reading an empty string as "no request".
#
# The login falls back to "" rather than being indexed directly: an event
# requesting a *team* carries .requested_team and no .requested_reviewer, and
# `null | ascii_downcase` aborts the whole filter — one such event anywhere on
# the PR would otherwise be read as a failure to reach the timeline at all.
#
# --paginate applies --jq once per page, so the per-page lengths are summed
# rather than read as a single number.
COUNT=""
count_requests() {
  if ! COUNT="$(gh api "repos/$OWNER/$REPO/issues/$PR/timeline" --paginate \
    --jq '[.[]
           | select(.event == "review_requested")
           | select((.requested_reviewer.login // "") | ascii_downcase | contains("copilot"))
          ] | length' \
    | awk '{ total += $1 } END { print total + 0 }')"; then
    echo "error: could not read the timeline of $OWNER/$REPO#$PR" >&2
    exit 4
  fi
}

# True once the count passes the pre-request baseline.
landed() {
  local try=1
  while :; do
    count_requests
    if [ "$COUNT" -gt "$BASELINE" ]; then
      return 0
    fi
    if [ "$try" -ge "$READBACK_TRIES" ]; then
      return 1
    fi
    try=$((try + 1))
    sleep "$READBACK_INTERVAL"
  done
}

count_requests
BASELINE="$COUNT"

gh pr edit "$PR" --repo "$OWNER/$REPO" --add-reviewer "@copilot" >/dev/null || true
if landed; then
  exit 0
fi

gh api --method POST "repos/$OWNER/$REPO/pulls/$PR/requested_reviewers" \
  -f "reviewers[]=copilot-pull-request-reviewer[bot]" >/dev/null || true
if landed; then
  exit 0
fi

echo "no copilot review request landed on $OWNER/$REPO#$PR after both forms" >&2
exit 3
