#!/usr/bin/env bash
# Resolve the committed range this review covers, printed as two SHAs.
#
# Two input shapes, one purpose. Given a PR number, the range is the PR
# record's own endpoints: anything derived from the local checkout instead
# reviews whatever this working copy happens to sit on, which is not the PR's
# diff wherever the two have diverged, and nothing in the findings would say
# so. Given no argument, the range runs from the base this branch was cut
# from to HEAD, and that base is read back from the Base-Branch trailer
# rather than assumed.
#
# Reading it back is what the reviewed range depends on. Squash and rebase
# merges rewrite a prerequisite's commits under fresh SHAs, so falling back to
# the default branch where a prerequisite is recorded puts merge-base *below*
# that prerequisite and sweeps its whole diff into the range — the reviewer
# then reports findings against code this task never wrote. See
# ../../implement-work/references/base-branch.md, "## The contract",
# "## Reading the trailer back", "### Why the state is re-read and the branch
# is not" and "## Resolving the default branch" — this script implements that
# table's `review-code`'s `<base>` column.
#
# Usage: resolve-range.sh [pr-number]
set -euo pipefail

if [ "$#" -gt 1 ]; then
  echo "Usage: $0 [pr-number]" >&2
  exit 1
fi

PR="${1:-}"

if [ -n "$PR" ]; then
  if ! ENDS="$(gh pr view "$PR" --json baseRefOid,headRefOid --jq '"\(.baseRefOid) \(.headRefOid)"' 2>/dev/null)"; then
    echo "STOP pr-lookup-failed"
    exit 0
  fi
  echo "RANGE ${ENDS%% *}..${ENDS##* }"
  exit 0
fi

# Three-rung ladder, never guessing a branch name: the local remote-HEAD
# symref, then the GitHub API, then give up and let the caller ask a person.
# Both rungs are pinned to the bare name — `--short` and
# `.defaultBranchRef.name` — so the two agree on one form; this caller needs a
# rev, so `origin/` goes back on where the result is used.
resolve_default_branch() {
  local ref
  if ref="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)"; then
    printf '%s\n' "${ref#origin/}"
    return 0
  fi
  if ref="$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name' 2>/dev/null)" && [ -n "$ref" ]; then
    printf '%s\n' "$ref"
    return 0
  fi
  return 1
}

# Capture the trailer scan into a variable before testing it, rather than
# piping into `grep`. A pipe reports only grep's exit status, and grep exits 1
# on empty input whether the trailer is genuinely absent or the read itself
# failed — two causes that must not collapse into "no trailer", since that
# answer sends the range to the default branch. The read is guarded as well as
# captured: under `set -e` a failing `git log` inside a bare command
# substitution would kill the script outright, and the caller would get a
# non-zero exit with nothing on stdout instead of a STOP. Local HEAD, not a
# fetched ref: this skill reviews the checkout it is in. Newest-first (git
# log's default order), since a trailer on a later commit shadows an earlier
# one in the same stack.
if ! TRAILER_LOG="$(git log HEAD --format='%(trailers:key=Base-Branch,valueonly,unfold)')"; then
  echo "STOP trailer-read-failed"
  exit 0
fi

RECORDED=""
while IFS= read -r line; do
  if [ -n "$line" ]; then
    RECORDED="$line"
    break
  fi
done <<<"$TRAILER_LOG"

if [ -z "$RECORDED" ]; then
  DEFAULT="$(resolve_default_branch)" || { echo "STOP ask-default-branch"; exit 0; }
  BASE="origin/${DEFAULT}"
else
  # Read the exit status and the line count together. A non-zero exit prints
  # nothing and looks exactly like "no PR" — auth, network, or repo-context
  # failures behave the same way — so it is "couldn't tell", not "no match".
  # `.[]` rather than `.[0]` so an empty list yields zero lines and several
  # matches yield several, instead of one arbitrary pick or an interpolated
  # "null".
  if ! PR_LOOKUP="$(gh pr list --head "$RECORDED" --state all --json number,state --jq '.[] | "\(.number) \(.state)"' 2>/dev/null)"; then
    echo "STOP prereq-lookup-failed"
    exit 0
  fi

  LINE_COUNT=0
  if [ -n "$PR_LOOKUP" ]; then
    LINE_COUNT="$(printf '%s\n' "$PR_LOOKUP" | wc -l)"
  fi

  if [ "$LINE_COUNT" -eq 0 ]; then
    echo "STOP no-prereq-pr"
    exit 0
  fi

  if [ "$LINE_COUNT" -ge 2 ]; then
    echo "STOP ask-multiple-prs"
    exit 0
  fi

  PREREQ_PR="${PR_LOOKUP%% *}"
  STATE="${PR_LOOKUP##* }"

  case "${STATE}" in
    OPEN)
      FETCH_SPEC="${RECORDED}"
      ;;
    MERGED)
      # The prerequisite's own head, not the default branch: it bounds the
      # range whatever the merge strategy was, and `refs/pull/<n>/head`
      # outlives both the merge and the branch's deletion.
      FETCH_SPEC="refs/pull/${PREREQ_PR}/head"
      ;;
    CLOSED)
      echo "STOP abandoned-prerequisite"
      exit 0
      ;;
    *)
      echo "error: unexpected PR state '${STATE}' for '${RECORDED}'" >&2
      exit 1
      ;;
  esac

  # FETCH_HEAD, never origin/<recorded>: a fetch always writes FETCH_HEAD,
  # whereas updating the remote-tracking ref depends on the clone's
  # remote.origin.fetch refspec — and `refs/pull/<n>/head` sits outside that
  # refspec in every clone — so the tracking ref can stay at a stale commit
  # while the fetch itself exits 0.
  if ! git fetch origin "${FETCH_SPEC}" >&2; then
    echo "STOP fetch-failed"
    exit 0
  fi
  BASE="FETCH_HEAD"
fi

if ! BASE_SHA="$(git merge-base "${BASE}" HEAD)"; then
  echo "STOP merge-base-failed"
  exit 0
fi

HEAD_SHA="$(git rev-parse HEAD)"

if [ "${BASE_SHA}" = "${HEAD_SHA}" ]; then
  echo "EMPTY"
  exit 0
fi

echo "RANGE ${BASE_SHA}..${HEAD_SHA}"
