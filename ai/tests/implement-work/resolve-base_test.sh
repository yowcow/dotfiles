#!/usr/bin/env bash
# Table test for ai/skills/implement-work/scripts/resolve-base.sh: which base it
# names for each shape of the issue's native `blockedBy` relation, and -- for
# every answer that names one -- that the branch was really fetched.
#
# git is not stubbed. The claim the SUT's fetch_ref comment makes is about
# git's own behaviour ("`git fetch origin <name>` ... leaves
# refs/remotes/origin/<name> at whatever an earlier fetch wrote whenever the
# clone's remote.origin.fetch refspec doesn't cover it"), so a git stub would
# encode the test author's belief about that rather than git's behaviour.
#
# Every work repository here is cloned with `--single-branch`, which is what
# makes "the fetch actually happened" assertable at all. Measured on git
# 2.43.0: with remote.origin.fetch covering only the cloned branch, the SUT's
# explicit `+refs/heads/X:refs/remotes/origin/X` creates or advances
# refs/remotes/origin/X, while a plain `git fetch origin X` updates FETCH_HEAD
# and leaves that ref untouched -- and BOTH print the same `BASE X` line. In a
# full clone git's opportunistic update advances the ref either way, hiding the
# difference completely. So the stdout assertions carry none of this, and the
# check_tracking assertions carry all of it.
#
# The remote every row shares holds three branches: `main` and `feature` with
# two commits each, and `decoy` with one. `decoy` is what the work repository
# clones, so neither `main` nor `feature` is covered by its refspec, and each
# row plants both tracking refs one commit behind. A row that expects a fetch
# therefore asserts the ref MOVED to the tip, and a row that expects none
# asserts it stayed behind -- which also distinguishes "fetched the default
# branch" from "fetched the prerequisite's head" in the two rows that could
# otherwise be told apart only by their stdout.
#
# Limitation: `resolve_default_branch`'s rung 2 is stubbed with
# gh_stub_response, so the `--jq .defaultBranchRef.name` expression itself is
# not executed. The rung under test is which one answers, not that filter. The
# two `gh issue view` calls carry no --jq, so the SUT's own jq -- the counting
# this file's `two-prerequisites` and `several-prs` rows exist for -- does run.
#
# RED verification (see ai/tests/README.md). The script is new, so there is no
# pre-fix version; each variant below is one mutation of a guard the SUT's own
# header names, and the rows it must fail are named:
#   - fetch_ref's explicit refspec -> plain `git fetch origin "$1"`:
#     every row asserting `tip`, i.e. no-argument-uses-default-branch,
#     no-prerequisite-uses-default-branch, symref-rung-wins-over-api,
#     default-branch-from-api, prerequisite-open-uses-its-head,
#     prerequisite-merged-uses-the-default-branch
#   - blockedBy counted -> checked for emptiness: two-prerequisites-stop
#   - closedByPullRequestsReferences counted with `length` -> checked for
#     emptiness: prerequisite-has-several-prs
#   - rung 2's non-empty check dropped: default-branch-api-answers-empty
set -euo pipefail

# shellcheck source-path=SCRIPTDIR
# shellcheck source=../lib/harness.sh
# shellcheck disable=SC1091
. "$(dirname -- "${BASH_SOURCE[0]}")/../lib/harness.sh"
# shellcheck source-path=SCRIPTDIR
# shellcheck source=../lib/gitrepo.sh
# shellcheck disable=SC1091
. "$(dirname -- "${BASH_SOURCE[0]}")/../lib/gitrepo.sh"

SUT="${SUT:-${REPO_ROOT}/ai/skills/implement-work/scripts/resolve-base.sh}"

PR_JQ='"\(.headRefName) \(.state)"'

failed=0
total=0

# build_remote <name> -- prints the path of a bare repo holding `main` and
# `feature` with two commits each and `decoy` with one. The second commit on
# main and on feature is what a fetch has to bring in: every work repository
# below plants its tracking refs at the first.
build_remote() {
  local bare seed
  bare="$(git_repo_bare acme "$1")"
  seed="$(git_repo_scratch "seed-$1")"
  git_repo_init "$seed" main
  git_repo_commit "$seed" README.md 'root\n' 'root commit'
  git_repo_checkout "$seed" feature main
  git_repo_commit "$seed" F.md 'feature one\n' 'feature commit 1'
  git_repo_commit "$seed" F.md 'feature two\n' 'feature commit 2'
  git_repo_checkout "$seed" main
  git_repo_commit "$seed" M.md 'main two\n' 'main commit 2'
  git_repo_checkout "$seed" decoy main
  git_repo_commit "$seed" D.md 'decoy\n' 'decoy commit'
  git_repo_push "$seed" "$bare" main feature decoy
  printf '%s\n' "$bare"
}

# work_repo <name> <bare> [<origin-head>] -- prints the path of a work repo
# cloned from <bare> with --single-branch on `decoy`, its origin/main and
# origin/feature planted one commit behind the remote, and
# refs/remotes/origin/HEAD pointed at <origin-head> when one is given.
#
# --single-branch is deliberate and load-bearing: it is what leaves
# remote.origin.fetch covering `decoy` alone, so nothing but the SUT's own
# explicit refspec can advance the other two refs. A plain `git clone` would
# advance them opportunistically and every fetch assertion here would pass
# against a SUT that never fetched.
#
# git_repo_clone is not used for the same reason -- it clones every branch --
# and the --single-branch form is not added to gitrepo.sh because it is this
# file's own fixture concern and that file is shared with eight sibling
# branches.
work_repo() {
  gitrepo_reject_traversal "$1"
  local dir="${HARNESS_TMP}/repos/$1"
  rm -rf "$dir"
  mkdir -p "$(dirname -- "$dir")"
  git clone -q --single-branch --branch decoy -- "$2" "$dir"
  stale_ref "$dir" "$2" main
  stale_ref "$dir" "$2" feature
  # Deleted rather than assumed absent. Measured on git 2.43.0 a
  # --single-branch clone records no refs/remotes/origin/HEAD, so the rows that
  # want the ladder's rung 2 get it for free today -- but a later git that
  # started recording it would send those rows to rung 1 instead, and they
  # would still pass, having stopped testing the rung they name.
  git -C "$dir" symbolic-ref -d refs/remotes/origin/HEAD 2>/dev/null || true
  if [ "$#" -ge 3 ]; then
    git_repo_origin_head "$dir" "$3"
  fi
  printf '%s\n' "$dir"
}

# stale_ref <work> <bare> <branch> -- plant refs/remotes/origin/<branch> at the
# remote's <branch>~1, i.e. one commit behind. "Behind" rather than "absent" on
# purpose: absence would also be reported by a `git fetch` that failed, while a
# ref sitting at the older commit is the exact state the SUT's fetch_ref
# comment describes -- "at whatever an earlier fetch wrote".
stale_ref() {
  local sha
  sha="$(git -C "$2" rev-parse "refs/heads/$3~1")"
  git -C "$1" update-ref "refs/remotes/origin/$3" "$sha"
}

# check_tracking <label> <work> <bare> <branch> <tip|stale|absent>
# Called only indirectly, through check_row's positional dispatch.
# shellcheck disable=SC2317
check_tracking() {
  local got want
  got="$(git -C "$2" rev-parse --verify -q "refs/remotes/origin/$4" || printf 'absent')"
  case "$5" in
    tip) want="$(git -C "$3" rev-parse "refs/heads/$4")" ;;
    stale) want="$(git -C "$3" rev-parse "refs/heads/$4~1")" ;;
    absent) want=absent ;;
    *)
      printf 'check_tracking: unknown expectation %s\n' "$5"
      return 1
      ;;
  esac
  check_eq "$1" "$want" "$got"
}

# stub_blocked <issue> <exit-status> -- `gh issue view <issue> --json blockedBy`
stub_blocked() {
  gh_stub_response '*' "$2" issue view "$1" --json blockedBy
}

# stub_prereq_prs <issue> <exit-status> -- the prerequisite's closing PRs
stub_prereq_prs() {
  gh_stub_response '*' "$2" issue view "$1" --json closedByPullRequestsReferences
}

# stub_pr_view <pr> <exit-status> -- raw, so the SUT's own --jq runs
stub_pr_view() {
  gh_stub_raw_response '*' "$2" pr view "$1" --json headRefName,state --jq "$PR_JQ"
}

# stub_default_branch <exit-status> -- the ladder's rung 2, body already filtered
# Not called by this file's own rows; used by rows appended after them.
# shellcheck disable=SC2317
stub_default_branch() {
  gh_stub_response '*' "$1" repo view --json defaultBranchRef --jq .defaultBranchRef.name
}

# blocked_json <count> <number>... -- the shape `gh issue view --json blockedBy`
# returns: {nodes, totalCount}. totalCount is passed separately from the nodes
# because that is the field the SUT counts.
# The loops below are guarded on `$#` rather than iterating `"$@"` directly:
# under `set -u` an empty `"$@"` is an unbound-variable error in bash before
# 4.4, and the `blocked_json 0` / `prs_json` calls are exactly that case.
blocked_json() {
  local count="$1" sep='' out='' n
  shift
  if [ "$#" -gt 0 ]; then
    for n in "$@"; do
      out="${out}${sep}{\"number\":${n}}"
      sep=','
    done
  fi
  printf '{"blockedBy":{"nodes":[%s],"totalCount":%s}}\n' "$out" "$count"
}

# prs_json <number>... -- closedByPullRequestsReferences is a plain array here,
# which is why the SUT counts it with `length` and not with a totalCount field.
prs_json() {
  local sep='' out='' n
  if [ "$#" -gt 0 ]; then
    for n in "$@"; do
      out="${out}${sep}{\"number\":${n}}"
      sep=','
    done
  fi
  printf '{"closedByPullRequestsReferences":[%s]}\n' "$out"
}

# run_in <work> <argv...> -- the SUT reads cwd's repository, so every row runs
# from inside its own work repository and returns to the repository root.
run_in() {
  local w="$1"
  shift
  cd "$w"
  run_sut bash "$SUT" "$@"
  cd "$REPO_ROOT"
}

# assert_row <name> <want-exit> <want-stdout> <want-gh-calls>
assert_row() {
  local name="$1" want_exit="$2" want_out="$3" want_calls="$4" fails=0
  if ! check_eq "${name}: exit" "$want_exit" "$SUT_STATUS"; then fails=1; fi
  if ! check_bytes "${name}: stdout" "$want_out"; then fails=1; fi
  if ! check_eq "${name}: gh calls" "$want_calls" "$(gh_call_count)"; then fails=1; fi
  if ! check_no_violations "${name}: argv"; then fails=1; fi
  if [ "$fails" -ne 0 ]; then
    failed=$((failed + 1))
    printf '  stderr: %s\n' "$(head -c 400 "$SUT_STDERR")"
  fi
}

# check_row <label> -- fold an extra assertion into the row count
check_row() {
  total=$((total + 1))
  if ! "${@:2}"; then
    failed=$((failed + 1))
  fi
}

REMOTE="$(build_remote base)"

# ---- arguments ----------------------------------------------------------
#
# The row runs from a work repository that could have answered, so a failure
# here is the guard's and not the fixture's. Two arguments, not three: the
# guard is `-gt 1`, and the boundary is what a row has to sit on.

total=$((total + 1))
stub_dir_new
W="$(work_repo args-extra "$REMOTE" main)"
run_in "$W" 203 extra
assert_row 'too-many-arguments' 1 '' 0
check_row x check_tracking 'too-many-arguments: origin/main' "$W" "$REMOTE" main stale

total=$((total + 1))
if ! grep -q 'Usage:' "$SUT_STDERR"; then
  printf 'FAIL too-many-arguments: stderr carries no usage line:\n%s\n' \
    "$(head -c 400 "$SUT_STDERR")"
  failed=$((failed + 1))
fi

# ---- no argument at all -------------------------------------------------
#
# A task with no issue behind it has no relation to read, which has to land on
# the same answer as a count of 0 -- and reach `gh issue view` not at all. The
# zero-call assertion is the whole point of the row: an implementation that
# asked about an empty issue number would be answered by the stub as a
# violation, but one that skipped the count and fetched the default anyway
# would still print `BASE main`.

total=$((total + 1))
stub_dir_new
W="$(work_repo no-arg "$REMOTE" main)"
run_in "$W"
assert_row 'no-argument-uses-default-branch' 0 'BASE main\n' 0
check_row x check_tracking 'no-argument: origin/main fetched' "$W" "$REMOTE" main tip
check_row x check_tracking 'no-argument: origin/feature untouched' "$W" "$REMOTE" feature stale

# ---- blockedBy: 0 -------------------------------------------------------

total=$((total + 1))
stub_dir_new
blocked_json 0 | stub_blocked 203 0
W="$(work_repo blocked-none "$REMOTE" main)"
run_in "$W" 203
assert_row 'no-prerequisite-uses-default-branch' 0 'BASE main\n' 1
check_row x check_tracking 'no-prerequisite: origin/main fetched' "$W" "$REMOTE" main tip

# ---- blockedBy: 2 or more ----------------------------------------------
#
# The counting guard's row. `.blockedBy.totalCount` is read rather than
# "are there any", because emptiness cannot tell one prerequisite from three
# and this row is where the two answers differ.
#
# Both downstream calls are stubbed even though a correct SUT makes neither:
# without them a mutation that counted emptiness would fail as "an argv no
# case stubbed", which names the mechanism rather than the defect, while with
# them it fails as `BASE feature` against `STOP ask-multiple-prereqs` -- the
# defect itself. The `gh calls` assertion is what holds the two entries to
# being unused.

total=$((total + 1))
stub_dir_new
blocked_json 2 77 88 | stub_blocked 203 0
prs_json 55 | stub_prereq_prs 77 0
printf '{"headRefName":"feature","state":"OPEN"}\n' | stub_pr_view 55 0
W="$(work_repo blocked-two "$REMOTE" main)"
run_in "$W" 203
assert_row 'two-prerequisites-stop' 0 'STOP ask-multiple-prereqs\n' 1
check_row x check_tracking 'two-prerequisites: no fetch' "$W" "$REMOTE" main stale

# ---- the blockedBy lookup itself fails ---------------------------------
#
# "Could not ask" must not be answered as "there is none". The SUT has no STOP
# for it: the command substitution fails under `set -e` and gh's status
# propagates, which is the loud direction. The row exists to pin that it is not
# `BASE main`.

total=$((total + 1))
stub_dir_new
printf 'gh: HTTP 502\n' | stub_blocked 203 1
W="$(work_repo blocked-fails "$REMOTE" main)"
run_in "$W" 203
assert_row 'blockedBy-lookup-fails-loudly' 1 '' 1
check_row x check_tracking 'blockedBy-lookup-fails: no fetch' "$W" "$REMOTE" main stale

harness_exit "$failed" "$total"
