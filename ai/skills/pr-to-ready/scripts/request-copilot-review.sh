#!/usr/bin/env bash
# Request a Copilot review on a PR and confirm the request actually took.
#
# This exists as a command because the request cannot be judged from any single
# call's exit status. The reviewer flag and the requested_reviewers REST endpoint
# are alternatives rather than a sequence: neither may be trusted on its status
# or chained with ||, and only a readback over REST settles whether the request
# took. Why that is the only test that works: ../references/gh-mechanics.md.
#
# The readback matches a lowercased substring of the login rather than one exact
# spelling, because the bot's login differs across GitHub's surfaces.
#
# Both attempts have their stdout dropped and their exit status ignored, on
# purpose; their stderr is left visible so a stuck run has something to read.
#
# Usage: request-copilot-review.sh <owner> <repo> <pr-number>
#
# Exit: 0 = Copilot is requested on the PR (the flag took, or the REST form did)
#       2 = usage error
#       3 = Copilot is still absent after both forms — the answer, not a
#           failure: treat Copilot as unavailable here and skip it
#       4 = the requested reviewers could not be read. Failing to *read* them is
#           not the same as none being requested — stop and inspect
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

# Sets REQUESTED to "yes" or "no". A readback that cannot be performed exits 4
# rather than answering "no" — which is why this is called as a statement and
# never inside $(...): there, the exit would leave the caller reading an empty
# string as "not requested".
REQUESTED=""
read_requested() {
  if ! REQUESTED="$(gh api "repos/$OWNER/$REPO/pulls/$PR/requested_reviewers" \
    --jq 'if any(.users[].login; ascii_downcase | contains("copilot")) then "yes" else "no" end')"; then
    echo "error: could not read the requested reviewers on $OWNER/$REPO#$PR" >&2
    exit 4
  fi
}

gh pr edit "$PR" --repo "$OWNER/$REPO" --add-reviewer "@copilot" >/dev/null || true

read_requested
if [ "$REQUESTED" = "yes" ]; then
  exit 0
fi

gh api --method POST "repos/$OWNER/$REPO/pulls/$PR/requested_reviewers" \
  -f "reviewers[]=copilot-pull-request-reviewer[bot]" >/dev/null || true

read_requested
if [ "$REQUESTED" = "yes" ]; then
  exit 0
fi

echo "copilot is not among the requested reviewers on $OWNER/$REPO#$PR after both forms" >&2
exit 3
