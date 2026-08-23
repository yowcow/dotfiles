#!/usr/bin/env bash
# Table test for ai/skills/review-code/scripts/resolve-range.sh: which of its
# two input shapes -- a PR number, or none -- the script resolves a reviewed
# range from, and the exact line it prints for each answer.
#
# git is not stubbed. The range is the thing under test, and a git stub would
# encode the test author's belief about what a range should be rather than
# git's own behaviour -- exactly the failure mode ai/tests/pr-to-ready's
# resolve-pr-base_test.sh documents for the same reason. Each row that reaches
# the no-PR path therefore builds a real bare repository to play the remote
# and a real work repository cloned from it, both under $HARNESS_TMP and both
# offline.
#
# Limitation: the SUT extracts the PR record's two oids through a --jq filter
# passed to `gh pr view`, and the fake `gh` matches stubs on the *exact*
# argv. A mutation confined to that filter's text changes the argv itself, so
# such a mutant makes the stub report an unstubbed call rather than exercising
# the mutated filter against a fixture body: gh_stub_raw_response does run the
# filter this file wrote, for real, through jq -- but never a mutated copy of
# it, so a defect that lives only inside the filter string is invisible here.
#
# RED verification (see ai/tests/README.md) -- resolve-range.sh has never been
# tested before this file, so there is no historical fix commit to check it
# against the way the other table tests in this suite do. Task 5 confirms
# coverage instead by hand-mutating a copy of the script and re-running this
# file per mutant; the four below are recorded as prose pending that
# measurement, and Task 5 corrects this list if a measurement disagrees:
#   1. Swap emit_range's two arguments (the PR-record shape would then print
#      the head before the base) -- pr-shape-uses-the-pr-record should read
#      `RANGE hhh222..bbb111` and fail against the row's `bbb111..hhh222`.
#   2. Drop emit_range's `$1 = $2` check, so it always prints RANGE -- then
#      pr-shape-empty-when-ends-coincide should read `RANGE same111..same111`
#      instead of `EMPTY` and fail.
#   3. Remove the `if ! ENDS=...` guard around the `gh pr view` call, so a
#      failing lookup aborts the script instead of printing a STOP -- then
#      pr-lookup-fails should fail on exit status and empty stdout instead of
#      `STOP pr-lookup-failed`.
#   4. Loosen the `[ "$#" -gt 1 ]` guard (e.g. to `-gt 2`) -- then
#      too-many-arguments should stop asserting exit 1 with empty stdout, since
#      the extra argument would be let through instead of rejected.
set -euo pipefail

# shellcheck source-path=SCRIPTDIR
# shellcheck source=../lib/harness.sh
# shellcheck disable=SC1091
. "$(dirname -- "${BASH_SOURCE[0]}")/../lib/harness.sh"
# shellcheck source-path=SCRIPTDIR
# shellcheck source=../lib/gitrepo.sh
# shellcheck disable=SC1091
. "$(dirname -- "${BASH_SOURCE[0]}")/../lib/gitrepo.sh"

SUT="${SUT:-${REPO_ROOT}/ai/skills/review-code/scripts/resolve-range.sh}"

PR_VIEW_JQ='"\(.baseRefOid) \(.headRefOid)"'

failed=0
total=0

# commit_msg <subject> <base-branch|-> -- a commit message, carrying a
# Base-Branch trailer unless the second argument is `-`. The trailer goes in a
# paragraph of its own because that is where git's trailer parser looks.
commit_msg() {
  if [ "$2" = '-' ]; then
    printf '%s\n' "$1"
  else
    printf '%s\n\nBase-Branch: %s\n' "$1" "$2"
  fi
}

# build_remote <name> <with-dep|no-dep> -- prints the path of a new bare repo
# holding five branches, built in this order: `main` (one commit, no
# trailer), `dep` (branched off main, one commit, no trailer -- a
# prerequisite branch of its own), `task` (branched off dep, TWO commits, the
# older recording `Base-Branch: older-base` and the newer `Base-Branch: dep`,
# so a scan reading the stack in the wrong order picks a different answer),
# back to `main`, `plain` (branched off main, one commit, no trailer), and
# `fresh` (branched off main with no commit of its own, so it sits exactly on
# main's tip).
#
# Two pushes. The branch list omits `dep` alone when the second argument is
# `no-dep` -- `task` is always pushed, and pushing it carries dep's commit
# object along as part of task's own history, so the commit stays reachable
# while the branch ref is gone. That is precisely the state a merged
# prerequisite leaves behind: the branch deleted, the commits still there.
# The second push is `dep:refs/pull/9/head`, which is what a MERGED
# prerequisite's own head survives as after the branch itself is deleted.
build_remote() {
  local name="$1" depmode="$2" bare seed branches
  bare="$(git_repo_bare acme "$name")"
  seed="$(git_repo_scratch "seed-${name}")"
  git_repo_init "$seed" main
  git_repo_commit "$seed" README.md 'base\n' "$(commit_msg 'base commit' -)"
  git_repo_checkout "$seed" dep main
  git_repo_commit "$seed" DEP.md 'dep\n' "$(commit_msg 'dep commit' -)"
  git_repo_checkout "$seed" task dep
  git_repo_commit "$seed" T1.md 'task one\n' "$(commit_msg 'task commit 1' older-base)"
  git_repo_commit "$seed" T2.md 'task two\n' "$(commit_msg 'task commit 2' dep)"
  git_repo_checkout "$seed" main
  git_repo_checkout "$seed" plain main
  git_repo_commit "$seed" PLAIN.md 'plain\n' "$(commit_msg 'plain commit' -)"
  git_repo_checkout "$seed" fresh main
  if [ "$depmode" = with-dep ]; then
    branches='main dep task plain fresh'
  else
    branches='main task plain fresh'
  fi
  # shellcheck disable=SC2086
  git_repo_push "$seed" "$bare" $branches
  git_repo_push "$seed" "$bare" dep:refs/pull/9/head
  printf '%s\n' "$bare"
}

# bare_sha <bare-repo> <rev> -- the sha <rev> resolves to in <bare-repo>. Any
# rev, not just a branch: the MERGED rows need `refs/pull/9/head`, which is
# the one boundary in this file that is deliberately not a branch at all.
bare_sha() {
  git -C "$1" rev-parse "$2"
}

# work_repo <name> <origin-url> <checkout-branch> <origin-head|-> -- prints
# the path of a work repository cloned for real from <origin-url> with
# <checkout-branch> checked out, so HEAD holds real commits the way any clone
# of one of build_remote's branches would. refs/remotes/origin/HEAD is set to
# <origin-head> unless that is `-`. No cleanup step is needed for the `-`
# case: build_remote never creates a branch the bare repo's own (compiled-in)
# HEAD name would resolve, so that HEAD always dangles and a real clone never
# writes refs/remotes/origin/HEAD on its own (measured) -- it is this helper,
# not the clone, that puts the symref there at all.
work_repo() {
  local dir
  dir="$(git_repo_clone "$1" "$2" "$3")"
  if [ "$4" != '-' ]; then
    git_repo_origin_head "$dir" "$4"
  fi
  printf '%s\n' "$dir"
}

# run_in <work-dir> [<pr-number>] -- the SUT reads cwd's origin, HEAD and
# trailers, so every row runs from inside its own work repository and returns
# to the repository root. Arguments after <work-dir> are forwarded as-is, so
# a row can pass none, one, or two (the last of which exercises the SUT's own
# argument-count guard).
run_in() {
  local dir="$1"
  shift
  cd "$dir"
  run_sut bash "$SUT" "$@"
  cd "$REPO_ROOT"
}

# assert_row <name> <want-exit> <want-stdout> [<want-gh-calls>]
assert_row() {
  local name="$1" want_exit="$2" want_out="$3" want_calls="${4:-}" fails=0
  if ! check_eq "${name}: exit" "$want_exit" "$SUT_STATUS"; then fails=1; fi
  if ! check_bytes "${name}: stdout" "$want_out"; then fails=1; fi
  if [ -n "$want_calls" ] && ! check_eq "${name}: gh calls" "$want_calls" "$(gh_call_count)"; then fails=1; fi
  if ! check_no_violations "${name}: argv"; then fails=1; fi
  if [ "$fails" -ne 0 ]; then
    failed=$((failed + 1))
    printf '  stderr: %s\n' "$(head -c 400 "$SUT_STDERR")"
  fi
}

# ---- the PR-number shape: the PR record's own endpoints -----------------
#
# The first row runs from a directory that is not a git repository at all, so
# no answer derived from a local checkout is even reachable: the range can
# only have come from the PR record. The oids are deliberately not shas of
# anything in the fixture, for the same reason.

total=$((total + 1))
stub_dir_new
printf '{"headRefOid":"hhh222","baseRefOid":"bbb111"}\n' |
  gh_stub_raw_response '*' 0 pr view 42 --json baseRefOid,headRefOid --jq "$PR_VIEW_JQ"
NOREPO="$(git_repo_scratch pr-shape-norepo)"
run_in "$NOREPO" 42
assert_row 'pr-shape-uses-the-pr-record' 0 'RANGE bbb111..hhh222\n' 1

total=$((total + 1))
stub_dir_new
printf '{"headRefOid":"same111","baseRefOid":"same111"}\n' |
  gh_stub_raw_response '*' 0 pr view 42 --json baseRefOid,headRefOid --jq "$PR_VIEW_JQ"
NOREPO_SAME="$(git_repo_scratch pr-shape-empty)"
run_in "$NOREPO_SAME" 42
assert_row 'pr-shape-empty-when-ends-coincide' 0 'EMPTY\n' 1

total=$((total + 1))
stub_dir_new
: | gh_stub_raw_response '*' 1 pr view 42 --json baseRefOid,headRefOid --jq "$PR_VIEW_JQ"
NOREPO_FAIL="$(git_repo_scratch pr-shape-lookup-fails)"
run_in "$NOREPO_FAIL" 42
assert_row 'pr-lookup-fails' 0 'STOP pr-lookup-failed\n' 1

total=$((total + 1))
stub_dir_new
run_in "$NOREPO" 42 extra
assert_row 'too-many-arguments' 1 '' 0

# stub_default_branch <exit-status> -- the `gh repo view` rung of the
# default-branch ladder, body on stdin. Filtered, not raw: the filter is a
# plain field selection the SUT is not being held to, and the contract under
# test is what the script does with the *answer*.
stub_default_branch() {
  gh_stub_response '*' "$1" repo view --json defaultBranchRef --jq .defaultBranchRef.name
}

REMOTE="$(build_remote ranged with-dep)"
MAIN_SHA="$(bare_sha "$REMOTE" main)"
PLAIN_SHA="$(bare_sha "$REMOTE" plain)"

# ---- no trailer recorded: the default-branch ladder ---------------------
#
# `plain` carries no Base-Branch trailer anywhere in its history, so each of
# these rows exercises one rung of the ladder and nothing else. The first
# asserts zero gh calls: answering from the local symref is the whole point of
# that rung existing, and a run that reached GitHub anyway would still print
# the right range.

total=$((total + 1))
stub_dir_new
W="$(work_repo dflt-symref "$REMOTE" plain main)"
run_in "$W"
assert_row 'no-trailer-symref-names-default' 0 "RANGE ${MAIN_SHA}..${PLAIN_SHA}\n" 0

total=$((total + 1))
stub_dir_new
printf 'main\n' | stub_default_branch 0
W="$(work_repo dflt-gh "$REMOTE" plain -)"
run_in "$W"
assert_row 'no-trailer-gh-names-default' 0 "RANGE ${MAIN_SHA}..${PLAIN_SHA}\n" 1

total=$((total + 1))
stub_dir_new
: | stub_default_branch 1
W="$(work_repo dflt-gh-fails "$REMOTE" plain -)"
run_in "$W"
assert_row 'default-branch-lookup-fails' 0 'STOP ask-default-branch\n' 1

# Status 0 with nothing on stdout is a separate case from the failure above:
# `gh` answered, and the answer was empty. Only the SUT's `&& [ -n "$ref" ]`
# separates them, and without this row the two are one branch.
total=$((total + 1))
stub_dir_new
: | stub_default_branch 0
W="$(work_repo dflt-gh-empty "$REMOTE" plain -)"
run_in "$W"
assert_row 'default-branch-lookup-empty' 0 'STOP ask-default-branch\n' 1

# `fresh` sits exactly on main's tip, so the merge-base *is* HEAD -- the empty
# range, reached through the no-argument shape. Its counterpart for the PR
# shape is `pr-shape-empty-when-ends-coincide` above; both spellings have to
# collapse to EMPTY, since a caller handed `RANGE <sha>..<sha>` would dispatch
# a reviewer over an empty diff and read the no-findings back as a clean
# review.
total=$((total + 1))
stub_dir_new
W="$(work_repo empty-nopr "$REMOTE" fresh main)"
run_in "$W"
assert_row 'no-trailer-empty-when-head-is-the-default-tip' 0 'EMPTY\n' 0

harness_exit "$failed" "$total"
