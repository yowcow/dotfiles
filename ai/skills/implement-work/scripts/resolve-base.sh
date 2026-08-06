#!/usr/bin/env bash
# Resolve which branch a new task should be cut from, by its issue's native
# `blockedBy` relation rather than issue-body prose. Branching from the
# default while a prerequisite PR is still OPEN would simply omit that
# prerequisite's changes, so the task's own checks then fail for a reason
# nowhere in its diff.
# Usage: resolve-base.sh [issue-number]
set -euo pipefail

if [ "$#" -gt 1 ]; then
  echo "Usage: $0 [issue-number]" >&2
  exit 1
fi

ISSUE="${1:-}"

# Three-rung ladder, never guessing a branch name: the local remote-HEAD
# symref, then the GitHub API, then give up and let the caller ask a person.
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

if [ -z "$ISSUE" ]; then
  if DEFAULT="$(resolve_default_branch)"; then
    echo "BASE ${DEFAULT}"
  else
    echo "STOP ask-default-branch"
  fi
  exit 0
fi

# blockedBy and closedByPullRequestsReferences must be counted, never merely
# checked for emptiness — "is it empty" cannot tell one prerequisite from
# three, and both need the opposite answer here.
BLOCKED_COUNT="$(gh issue view "${ISSUE}" --json blockedBy --jq '.blockedBy.totalCount')"

if [ "${BLOCKED_COUNT}" -eq 0 ]; then
  DEFAULT="$(resolve_default_branch)" || { echo "STOP ask-default-branch"; exit 0; }
  echo "BASE ${DEFAULT}"
  exit 0
fi

if [ "${BLOCKED_COUNT}" -ge 2 ]; then
  echo "STOP ask-multiple-prereqs"
  exit 0
fi

PREREQ="$(gh issue view "${ISSUE}" --json blockedBy --jq '.blockedBy.nodes[0].number')"

# closedByPullRequestsReferences comes back as a plain array here (unlike
# blockedBy's {nodes, totalCount}), so it is counted with `length`.
PR_COUNT="$(gh issue view "${PREREQ}" --json closedByPullRequestsReferences --jq '.closedByPullRequestsReferences | length')"

if [ "${PR_COUNT}" -eq 0 ]; then
  echo "STOP not-implemented"
  exit 0
fi

if [ "${PR_COUNT}" -ge 2 ]; then
  echo "STOP ask-multiple-prs"
  exit 0
fi

PR="$(gh issue view "${PREREQ}" --json closedByPullRequestsReferences --jq '.closedByPullRequestsReferences[0].number')"

PR_INFO="$(gh pr view "${PR}" --json headRefName,state --jq '"\(.headRefName) \(.state)"')"
HEAD_REF="${PR_INFO% *}"
STATE="${PR_INFO##* }"

case "${STATE}" in
  MERGED)
    DEFAULT="$(resolve_default_branch)" || { echo "STOP ask-default-branch"; exit 0; }
    git fetch origin "${DEFAULT}" >&2
    echo "BASE ${DEFAULT}"
    ;;
  OPEN)
    git fetch origin "${HEAD_REF}" >&2
    echo "BASE ${HEAD_REF}"
    ;;
  CLOSED)
    echo "STOP abandoned-prerequisite"
    ;;
  *)
    echo "error: unexpected PR state '${STATE}' for PR ${PR}" >&2
    exit 1
    ;;
esac
