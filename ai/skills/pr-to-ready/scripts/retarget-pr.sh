#!/usr/bin/env bash
# Retarget a PR onto a new base once the base it currently points at has
# merged, and pull that new base's tip into the branch.
#
# A PR left pointing at an already-merged prerequisite reviews a diff that no
# longer matches what will actually land: merging such a PR puts nothing new
# into the base it is really headed for, since everything in the stale base
# is already there. Retargeting alone would still leave the PR's diff
# spanning the old base's own commits, so this also merges the new base in —
# without that, the PR keeps showing a stack of changes that already shipped
# under a different PR.
#
# Mergeability plays no part here — this script only reads `baseRefName` and
# never branches on either mergeability field (see ../references/gh-mechanics.md,
# "## Mergeability" for why one of those two is never the right one to read).
# Its `BASE-OK <base>` output uses the identical spelling of
# ./check-pr-state.sh's own token of the same name, so a caller can treat the
# two as interchangeable vocabulary.
#
# No automatic rebase, no force-push, no conflict resolution: a merge
# conflict aborts the merge and reports STOP for a person to resolve.
# Conflict resolution is a different, separately tracked concern (#111) and
# is a person's job, not this script's.
#
# Usage: retarget-pr.sh <owner> <repo> <pr-number> <branch> <base>
set -euo pipefail

if [ "$#" -ne 5 ]; then
  echo "Usage: $0 <owner> <repo> <pr-number> <branch> <base>" >&2
  exit 1
fi

OWNER="$1"
REPO="$2"
PR="$3"
BRANCH="$4"
BASE="$5"

if ! CURRENT_BASE="$(gh pr view "$PR" -R "${OWNER}/${REPO}" --json baseRefName --jq '.baseRefName' 2>/dev/null)"; then
  echo "STOP pr-read-failed"
  exit 0
fi

# Early return, unconditional on this path: already pointed at <base>, so
# nothing below — no `gh pr edit`, no fetch, no merge — ever runs.
if [ "$CURRENT_BASE" = "$BASE" ]; then
  echo "BASE-OK ${BASE}"
  exit 0
fi

if ! gh pr edit "$PR" -R "${OWNER}/${REPO}" --base "$BASE" >&2; then
  echo "STOP retarget-failed"
  exit 0
fi

# Pulling the new base in is only possible from the branch's own checkout:
# there is no other working tree to merge into.
CURRENT_HEAD="$(git rev-parse --abbrev-ref HEAD)"
if [ "$CURRENT_HEAD" != "$BRANCH" ]; then
  echo "STOP checkout-required"
  exit 0
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "STOP dirty-worktree"
  exit 0
fi

if ! git fetch origin "$BASE" >&2; then
  echo "STOP fetch-failed"
  exit 0
fi

if ! git merge --no-edit FETCH_HEAD >&2; then
  # Whatever the cause, abort rather than leaving a half-finished merge in
  # the working tree. No rebase, no force-push, no resolution attempt — see
  # the header comment: that is #111's job, done by a person.
  git merge --abort
  echo "STOP merge-conflict"
  exit 0
fi

echo "RETARGETED ${CURRENT_BASE} ${BASE}"
