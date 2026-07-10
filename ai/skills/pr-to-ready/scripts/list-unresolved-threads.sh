#!/usr/bin/env bash
# List unresolved PR review threads (with up to the first 50 comments each) via GitHub GraphQL.
# Usage: list-unresolved-threads.sh <owner> <repo> <pr-number>
set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <owner> <repo> <pr-number>" >&2
  exit 1
fi

OWNER="$1"
REPO="$2"
PR="$3"

# --paginate follows pageInfo.hasNextPage/endCursor automatically as long as
# the query names the cursor variable $endCursor and threads it through
# reviewThreads(after: $endCursor) — needed because a long-running PR's
# cumulative thread count (resolved + unresolved) can exceed a single page.
gh api graphql --paginate \
  -f owner="$OWNER" \
  -f repo="$REPO" \
  -F pr="$PR" \
  -f query='
    query($owner: String!, $repo: String!, $pr: Int!, $endCursor: String) {
      repository(owner: $owner, name: $repo) {
        pullRequest(number: $pr) {
          reviewThreads(first: 100, after: $endCursor) {
            pageInfo { hasNextPage endCursor }
            nodes {
              id
              isResolved
              comments(first: 50) {
                nodes {
                  databaseId
                  author { login }
                  path
                  line
                  body
                }
              }
            }
          }
        }
      }
    }' \
  --jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false)'
