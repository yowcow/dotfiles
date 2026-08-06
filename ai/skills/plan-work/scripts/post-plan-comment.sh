#!/usr/bin/env bash
# Post plan-work's design comment on an issue and print its **numeric** comment id.
#
# The body is only ever read from a file. A plan body is full of backticks and
# fenced blocks, and passing it as an inline flag string hands all of that to the
# shell. `gh api` wants a JSON payload rather than raw Markdown, hence the
# `jq -Rs` wrap (-R reads the file raw, -s slurps it into one string).
#
# The id printed on the first line is the numeric REST id, read straight out of
# the POST response, because that is the only id the edit path accepts:
# `gh issue view <n> --json comments` returns the GraphQL node id (`IC_...`)
# instead, and PATCH rejects it. Take the id here and reuse it for every later
# edit — sub-issue creation runs item by item and anyone may comment in that
# span, so "the issue's last comment" is a different comment by then.
#
# Nothing here edits your last comment on the issue. On the investigation-findings
# entry that comment is the findings report, so an --edit-last style post would
# silently overwrite the report instead of adding the design comment.
#
# GitHub rejects a body over 65536 characters. That ceiling is not in the REST
# reference — it is the API's own error text (`Body is too long (maximum is 65536
# characters)`), so treat it as an observation. A body that long is a signal to
# split the work further, never to truncate it.
#
# Usage: post-plan-comment.sh <owner> <repo> <issue-number> <body-file>
# Output: line 1 = numeric comment id, line 2 = comment URL
set -euo pipefail

if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <owner> <repo> <issue-number> <body-file>" >&2
  exit 1
fi

OWNER="$1"
REPO="$2"
ISSUE="$3"
BODY_FILE="$4"

if ! [[ "$ISSUE" =~ ^[0-9]+$ ]]; then
  echo "error: invalid issue number '$ISSUE' (must be an integer)" >&2
  exit 1
fi

if [ ! -f "$BODY_FILE" ]; then
  echo "error: body file not found: $BODY_FILE" >&2
  exit 1
fi

RESPONSE=$(jq -Rs '{body: .}' <"$BODY_FILE" \
  | gh api --method POST "repos/$OWNER/$REPO/issues/$ISSUE/comments" --input -)

# .id is the numeric id; .html_url carries the #issuecomment-<id> fragment.
printf '%s\n' "$RESPONSE" | jq -r '.id, .html_url'
