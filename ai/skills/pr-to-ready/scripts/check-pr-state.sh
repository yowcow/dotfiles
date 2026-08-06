#!/usr/bin/env bash
# Report a PR's base drift and mergeability. Read-only — it measures, it
# never retargets or pushes anything.
#
# The mergeability field read here is `mergeable` (MERGEABLE / CONFLICTING /
# UNKNOWN), never the sibling field GitHub also exposes on the same query.
# That sibling varies with the caller's own push permission rather than with
# anything about the branch, so a gate keyed on it stops PRs for a reason
# having nothing to do with their content — see ../references/gh-mechanics.md,
# "## Mergeability" (the section warning against that field) for the measured
# case. `UNKNOWN` is not a third verdict, only "not computed yet": it gets a
# short, bounded re-read before falling back to a local check, per the same
# file's section on why that re-read is bounded and what backs it up.
# Usage: check-pr-state.sh <owner> <repo> <pr-number> <expected-base>
set -euo pipefail

if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <owner> <repo> <pr-number> <expected-base>" >&2
  exit 1
fi

OWNER="$1"
REPO="$2"
PR="$3"
EXPECTED_BASE="$4"

# Bounded re-read for `mergeable == UNKNOWN`. GitHub computes it lazily in a
# background job that finishes in seconds, so this bound is deliberately
# short and has nothing in common with the review-wait timeouts elsewhere in
# this skill — polling for a background computation is not polling for a
# person. 5 attempts * 3s = ~15s total.
MERGEABLE_RETRY_MAX=5
MERGEABLE_RETRY_SECONDS=3

# Last-rung local check when GitHub's own answer never resolves. Permission-
# independent and instant, but it answers a narrower question (would these
# two trees merge right now) than `mergeable` (what the merge button will
# say), so it only runs after that authority was given a fair chance to
# answer. Prints MERGEABLE / CONFLICTING / UNKNOWN on stdout.
resolve_mergeable_locally() {
  local base_ref="$1" head_ref="$2"
  local base_sha head_ref_sha

  # Capture each tip immediately after its own fetch: `git fetch` overwrites
  # FETCH_HEAD on every call, so fetching both refs before reading either one
  # would compare a branch with itself and report no conflict — a clean
  # answer to a question nobody asked.
  if ! git fetch origin "$base_ref" >&2; then
    echo "UNKNOWN"
    return
  fi
  base_sha="$(git rev-parse FETCH_HEAD)"

  if ! git fetch origin "$head_ref" >&2; then
    echo "UNKNOWN"
    return
  fi
  head_ref_sha="$(git rev-parse FETCH_HEAD)"

  # Resolve both shas before reading merge-tree's exit status: it exits 1 for
  # a genuine conflict and for a ref that fails to resolve alike (measured on
  # git 2.43.0), so an unresolved ref would otherwise be misread as a
  # conflict that has nothing to do with the branch.
  if ! git rev-parse --verify --quiet "$base_sha" >/dev/null \
    || ! git rev-parse --verify --quiet "$head_ref_sha" >/dev/null; then
    echo "UNKNOWN"
    return
  fi

  if git merge-tree --write-tree "$base_sha" "$head_ref_sha" >/dev/null 2>&1; then
    echo "MERGEABLE"
  else
    echo "CONFLICTING"
  fi
}

if ! PR_INFO="$(gh pr view "$PR" -R "${OWNER}/${REPO}" \
  --json baseRefName,headRefName,mergeable \
  --jq '"\(.baseRefName) \(.headRefName) \(.mergeable)"' 2>/dev/null)"; then
  echo "STOP pr-read-failed"
  exit 0
fi

read -r BASE_REF HEAD_REF MERGEABLE <<<"$PR_INFO"

if [ "$BASE_REF" = "$EXPECTED_BASE" ]; then
  BASE_TOKEN="BASE-OK"
else
  BASE_TOKEN="BASE-DRIFT"
fi

ATTEMPTS=0
while [ "$MERGEABLE" = "UNKNOWN" ] && [ "$ATTEMPTS" -lt "$MERGEABLE_RETRY_MAX" ]; do
  sleep "$MERGEABLE_RETRY_SECONDS"
  ATTEMPTS=$((ATTEMPTS + 1))
  if ! MERGEABLE="$(gh pr view "$PR" -R "${OWNER}/${REPO}" --json mergeable --jq '.mergeable' 2>/dev/null)"; then
    echo "STOP pr-read-failed"
    exit 0
  fi
done

if [ "$MERGEABLE" = "UNKNOWN" ]; then
  MERGEABLE="$(resolve_mergeable_locally "$BASE_REF" "$HEAD_REF")"
fi

echo "${BASE_TOKEN} ${BASE_REF} ${MERGEABLE}"
