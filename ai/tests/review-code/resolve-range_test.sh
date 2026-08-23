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
# RED verification (see ai/tests/README.md). resolve-range.sh has never been
# tested before this file, so there is no pre-fix commit to point SUT= at the
# way this suite's other table tests do. Each guard named in the script's own
# header was removed instead, one at a time, in a copy under `mktemp -d` --
# never inside ai/, where lint.sh would select it by shebang -- and this file
# re-run against it as `SUT=<copy> ai/tests/run.sh <this file>`. What each
# mutant actually produced, measured:
#
#   1. The trailer read guarded as well as captured (resolve-range.sh:69-83).
#      Replacing the `if ! TRAILER_LOG=...` block with
#      `TRAILER_LOG="$(git log ... 2>/dev/null || true)"` failed
#      `trailer-read-fails` alone: want `STOP trailer-read-failed`, got
#      `STOP merge-base-failed`, with the mutant's stderr showing it had
#      fetched `main` on the way. That is the widening this file exists to
#      pin -- a read that failed, taken for a trailer that was absent, sends
#      the range to the default branch.
#   2. The MERGED boundary being the prerequisite's own head (:129-134).
#      Replacing `FETCH_SPEC="refs/pull/${PREREQ_PR}/head"` with
#      `FETCH_SPEC="$(resolve_default_branch)"` failed three rows:
#      `prereq-merged-uses-the-pr-head`, `merged-base-is-not-the-default-branch`
#      (which named the default branch tip it had used), and
#      `merged-pull-ref-absent` -- the last because a MERGED path that never
#      builds a `refs/pull/<n>/head` spec cannot fail to fetch one.
#   3. An empty PR list being "no prerequisite PR" (:112-115). Deleting the
#      `[ "$LINE_COUNT" -eq 0 ]` block failed `prereq-has-no-pr` on both exit
#      status (want 0, got 1) and stdout: the empty list fell through to the
#      unexpected-state branch instead.
#   4. Both shapes answering through emit_range (:32-42). Replacing its body
#      with an unconditional `echo "RANGE $1..$2"` failed both EMPTY rows --
#      `pr-shape-empty-when-ends-coincide` and
#      `no-trailer-empty-when-head-is-the-default-tip`.
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

PR_LIST_JQ='.[] | "\(.number) \(.state)"'

# stub_pr_list <head-branch> <exit-status> -- the prerequisite lookup, raw
# body on stdin. Raw, not filtered, because the filter is itself one of the
# guards the SUT's header names: `.[]` rather than `.[0]` is what makes an
# empty list yield zero lines instead of one interpolated "null null", and a
# pre-filtered fixture would decide that rather than test it. Measured
# through this stub's own jq: `.[0] | "\(.number) \(.state)"` on `[]` prints
# `null null`, which the SUT would read as one PR in an unknown state.
stub_pr_list() {
  gh_stub_raw_response '*' "$2" pr list --head "$1" --state all --json number,state --jq "$PR_LIST_JQ"
}

DEP_SHA="$(bare_sha "$REMOTE" dep)"
TASK_SHA="$(bare_sha "$REMOTE" task)"

# ---- a trailer the branch recorded itself -------------------------------

total=$((total + 1))
stub_dir_new
printf '[{"number":9,"state":"OPEN"}]\n' | stub_pr_list dep 0
W="$(work_repo prereq-open "$REMOTE" task main)"
run_in "$W"
assert_row 'prereq-open-uses-its-branch' 0 "RANGE ${DEP_SHA}..${TASK_SHA}\n" 1

# `task` records `older-base` on its first commit and `dep` on its second, so
# the two orders of reading the stack disagree about the answer. Both lookups
# are stubbed even though a correct scan makes only one: without the
# `older-base` entry a scan reading oldest-first would fail as "an argv no
# case stubbed", which names the mechanism instead of the defect, while with
# it the row fails on the range it printed. The gh-call assertion is what
# holds the second entry to being unused.
total=$((total + 1))
stub_dir_new
printf '[{"number":9,"state":"OPEN"}]\n' | stub_pr_list dep 0
printf '[{"number":8,"state":"OPEN"}]\n' | stub_pr_list older-base 0
W="$(work_repo shadow "$REMOTE" task main)"
run_in "$W"
assert_row 'newest-trailer-shadows-older' 0 "RANGE ${DEP_SHA}..${TASK_SHA}\n" 1

# ---- MERGED: the boundary is the prerequisite's own head ----------------
#
# This remote is built `no-dep`: branch `dep` never reached it, which is what
# a merged prerequisite leaves behind once its branch is deleted. Its commits
# are still reachable through `task`'s history, and its head still has a name
# -- `refs/pull/9/head` -- which is the only thing left to bound the range
# with. So an implementation fetching the recorded branch name reaches
# `STOP fetch-failed` here, and one falling back to the default branch prints
# a wider range that sweeps the prerequisite's whole diff into the review.
REMOTE_MERGED="$(build_remote merged no-dep)"
PULL9_SHA="$(bare_sha "$REMOTE_MERGED" refs/pull/9/head)"
MERGED_TASK_SHA="$(bare_sha "$REMOTE_MERGED" task)"
MERGED_MAIN_SHA="$(bare_sha "$REMOTE_MERGED" main)"

total=$((total + 1))
stub_dir_new
printf '[{"number":9,"state":"MERGED"}]\n' | stub_pr_list dep 0
W="$(work_repo prereq-merged "$REMOTE_MERGED" task main)"
run_in "$W"
assert_row 'prereq-merged-uses-the-pr-head' 0 "RANGE ${PULL9_SHA}..${MERGED_TASK_SHA}\n" 1

# The measurement the row above is for, asserted on that same run: the base
# must not be the default branch's tip. The first branch is not decoration --
# "the base is not main's tip" proves nothing if the fixture made them the
# same commit, and that is exactly the accident a later edit to build_remote
# could introduce.
total=$((total + 1))
if [ "$PULL9_SHA" = "$MERGED_MAIN_SHA" ]; then
  printf 'FAIL merged-base-is-not-the-default-branch: the fixture cannot discriminate -- refs/pull/9/head and main are the same commit\n'
  failed=$((failed + 1))
elif grep -q "RANGE ${MERGED_MAIN_SHA}" "$SUT_STDOUT"; then
  printf 'FAIL merged-base-is-not-the-default-branch: the range starts at the default branch tip %s\n' "$MERGED_MAIN_SHA"
  failed=$((failed + 1))
fi

# ---- the remaining prerequisite states ---------------------------------
#
# Each stops before any fetch, so the fixture's branches are irrelevant to
# them; what is under test is that four different "cannot proceed" causes
# stay four different answers rather than collapsing into one.

total=$((total + 1))
stub_dir_new
printf '[{"number":9,"state":"CLOSED"}]\n' | stub_pr_list dep 0
W="$(work_repo prereq-closed "$REMOTE" task main)"
run_in "$W"
assert_row 'prereq-closed-stops' 0 'STOP abandoned-prerequisite\n' 1

total=$((total + 1))
stub_dir_new
printf '[]\n' | stub_pr_list dep 0
W="$(work_repo prereq-none "$REMOTE" task main)"
run_in "$W"
assert_row 'prereq-has-no-pr' 0 'STOP no-prereq-pr\n' 1

total=$((total + 1))
stub_dir_new
printf '[{"number":9,"state":"OPEN"},{"number":8,"state":"CLOSED"}]\n' | stub_pr_list dep 0
W="$(work_repo prereq-multiple "$REMOTE" task main)"
run_in "$W"
assert_row 'prereq-has-several-prs' 0 'STOP ask-multiple-prs\n' 1

total=$((total + 1))
stub_dir_new
: | stub_pr_list dep 1
W="$(work_repo prereq-unreadable "$REMOTE" task main)"
run_in "$W"
assert_row 'prereq-lookup-fails' 0 'STOP prereq-lookup-failed\n' 1

total=$((total + 1))
stub_dir_new
printf '[{"number":9,"state":"DRAFT"}]\n' | stub_pr_list dep 0
W="$(work_repo prereq-unknown-state "$REMOTE" task main)"
run_in "$W"
assert_row 'prereq-state-unrecognised' 1 '' 1

total=$((total + 1))
if ! grep -q "unexpected PR state 'DRAFT'" "$SUT_STDERR"; then
  printf 'FAIL prereq-state-unrecognised: stderr does not name the state:\n%s\n' \
    "$(head -c 400 "$SUT_STDERR")"
  failed=$((failed + 1))
fi

# ---- the three git failures the script converts into STOP ---------------
#
# The row this file exists for. A work repository with no commits at all
# makes `git log HEAD` exit 128 (measured on git 2.43: "fatal: ambiguous
# argument 'HEAD'"), which is the trailer read *failing* rather than the
# trailer being absent -- two causes that must not collapse, because "absent"
# sends the range to the default branch. refs/remotes/origin/HEAD is pointed
# at `main` deliberately: it gives a collapsing implementation somewhere to
# walk to, so this row fails on the widening itself rather than on a fixture
# that had no answer either way.
total=$((total + 1))
stub_dir_new
W="$(git_repo_scratch trailer-unreadable)"
git_repo_init "$W" task
git_repo_remote "$W" origin "$REMOTE"
git_repo_origin_head "$W" main
run_in "$W"
assert_row 'trailer-read-fails' 0 'STOP trailer-read-failed\n' 0

# Two fetches can fail, and they carry the same slug from different rungs.
# The first row's origin/HEAD names a branch the remote does not have --
# `git symbolic-ref` accepts a dangling target, so the ladder answers `nosuch`
# and the fetch behind it is what fails, without ever reaching gh.
total=$((total + 1))
stub_dir_new
W="$(work_repo fetch-dflt "$REMOTE" plain nosuch)"
run_in "$W"
assert_row 'default-branch-absent-on-remote' 0 'STOP fetch-failed\n' 0

# The second is the MERGED rung: `refs/pull/77/head` exists on no fixture
# remote, so the spec that fails is the one the MERGED path builds itself.
total=$((total + 1))
stub_dir_new
printf '[{"number":77,"state":"MERGED"}]\n' | stub_pr_list dep 0
W="$(work_repo fetch-pull "$REMOTE" task main)"
run_in "$W"
assert_row 'merged-pull-ref-absent' 0 'STOP fetch-failed\n' 1

# Unrelated roots, the spelling absorb-base_test.sh uses: two repositories
# that share no history, so the fetch succeeds and `git merge-base` is what
# fails -- exit 1 printing nothing (measured), which is indistinguishable
# from an answer unless the exit status is read.
total=$((total + 1))
stub_dir_new
printf '[{"number":9,"state":"OPEN"}]\n' | stub_pr_list unrelated 0
LONELY="$(git_repo_bare acme lonely)"
LSEED="$(git_repo_scratch lonely-seed)"
git_repo_init "$LSEED" unrelated
git_repo_commit "$LSEED" only.txt 'unrelated\n' "$(commit_msg 'unrelated root' -)"
git_repo_push "$LSEED" "$LONELY" unrelated
W="$(git_repo_scratch lonely-work)"
git_repo_init "$W" task
git_repo_commit "$W" task.txt 'task\n' "$(commit_msg 'task root' unrelated)"
git_repo_remote "$W" origin "$LONELY"
run_in "$W"
assert_row 'merge-base-fails-on-unrelated-history' 0 'STOP merge-base-failed\n' 1

harness_exit "$failed" "$total"
