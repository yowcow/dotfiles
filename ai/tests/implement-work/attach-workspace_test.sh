#!/usr/bin/env bash
# Table test for ai/skills/implement-work/scripts/attach-workspace.sh: the one
# line it prints for each of REUSE / ATTACHED / CREATE, and what it leaves on
# disk.
#
# git is not stubbed. Every behaviour under test is git's own -- which ref a
# fetch updates, what `git worktree list --porcelain` prints, which exit status
# `ls-remote --exit-code` uses for "no match" versus "could not ask" -- and a
# stub would encode the test author's belief about that rather than git's
# behaviour. Each row therefore builds a real bare repository to play the remote
# and a real clone whose `origin` points at it, both under $HARNESS_TMP and both
# offline.
#
# No row stubs `gh`: this script never calls it. Every row asserts zero gh
# calls, which is what holds that to being true.
#
# RED verification (see ai/tests/README.md). The script is new, so there is no
# pre-fix version; each variant below removes exactly one guard its header
# names, and the rows that must fail are named:
#   - `grep -Fx` -> `grep -x` (the -F, so a "." in the branch name is a regex
#     metacharacter): `dot-in-name-does-not-grab-another-worktree`
#   - `grep -Fx` -> `grep -F` (the -x, so the match may be a substring of a
#     longer branch's line): `longer-name-does-not-grab-another-worktree`
#   - drop `--exit-code` from `git ls-remote`: `nowhere-is-create`
#   - drop the `elif [ "${status}" -ne 2 ]` arm, falling through to CREATE:
#     `unreachable-remote-is-not-absent`, `no-origin-remote-is-not-absent`
#   - `git fetch origin "+refs/heads/<b>:refs/remotes/origin/<b>"` ->
#     `git fetch origin "<b>"`: `remote-only-attach-is-at-the-remote-tip`
set -euo pipefail

# shellcheck source-path=SCRIPTDIR
# shellcheck source=../lib/harness.sh
# shellcheck disable=SC1091
. "$(dirname -- "${BASH_SOURCE[0]}")/../lib/harness.sh"
# shellcheck source-path=SCRIPTDIR
# shellcheck source=../lib/gitrepo.sh
# shellcheck disable=SC1091
. "$(dirname -- "${BASH_SOURCE[0]}")/../lib/gitrepo.sh"

SUT="${SUT:-${REPO_ROOT}/ai/skills/implement-work/scripts/attach-workspace.sh}"

failed=0
total=0

# build_repo <name> -- prints the path of a work repository cloned from a bare
# repo that holds one commit on `main`.
#
# A clone rather than init + remote add: the SUT reads whatever a real checkout
# has (the fetch refspec, remote-tracking refs), and hand-wiring only the parts
# a test author thought of is how a test comes to pass on a repository no real
# checkout resembles. Rows that need more on the remote push it themselves
# before cloning.
build_repo() {
  local name="$1" bare seed w
  bare="$(git_repo_bare acme "$name")"
  seed="$(git_repo_scratch "${name}-seed")"
  git_repo_init "$seed" main
  git_repo_commit "$seed" main.txt 'on main\n' 'c1'
  git_repo_push "$seed" "$bare" main
  w="$(git_repo_clone "$name" "$bare" main)"
  printf '%s\n' "$w"
}

# wt_path <name> -- a path under $HARNESS_TMP for a worktree, not created here.
wt_path() {
  printf '%s\n' "${HARNESS_TMP}/wt/$1"
}

# run_in <work-dir> <argv...> -- the SUT reads cwd's repository, so every row
# runs from inside its own work repository and returns to the repository root.
run_in() {
  local w="$1"
  shift
  cd "$w"
  run_sut bash "$SUT" "$@"
  cd "$REPO_ROOT"
}

# assert_row <name> <want-exit> <want-stdout>
assert_row() {
  local name="$1" want_exit="$2" want_out="$3" fails=0
  if ! check_eq "${name}: exit" "$want_exit" "$SUT_STATUS"; then fails=1; fi
  if ! check_bytes "${name}: stdout" "$want_out"; then fails=1; fi
  if ! check_eq "${name}: gh calls" 0 "$(gh_call_count)"; then fails=1; fi
  if ! check_no_violations "${name}: argv"; then fails=1; fi
  if [ "$fails" -ne 0 ]; then
    failed=$((failed + 1))
    printf '  stderr: %s\n' "$(head -c 400 "$SUT_STDERR")"
  fi
}

# real_path <path> -- the path as git itself reports it in `worktree list`.
# Compared as bytes, so a symlinked $TMPDIR would otherwise fail every REUSE
# row for a reason that has nothing to do with the script.
real_path() {
  (CDPATH='' cd -- "$1" && pwd -P)
}

# shellcheck disable=SC2317 # invoked indirectly, as `tally check_absent ...`
check_absent() {
  local got=present
  [ -e "$2" ] || got=absent
  check_eq "$1" 'absent' "$got"
}

# shellcheck disable=SC2317 # invoked indirectly, as `tally check_head ...`
check_head() {
  check_eq "$1" "$3" "$(git -C "$2" rev-parse HEAD)"
}

# shellcheck disable=SC2317 # invoked indirectly, as `tally check_on_branch ...`
check_on_branch() {
  check_eq "$1" "$3" "$(git -C "$2" symbolic-ref --short HEAD)"
}

# check_local_branch <label> <repo> <branch> <yes|no>
# shellcheck disable=SC2317 # invoked indirectly, as `tally check_local_branch ...`
check_local_branch() {
  local got=yes
  git -C "$2" show-ref --verify --quiet "refs/heads/$3" || got=no
  check_eq "$1" "$4" "$got"
}

# check_stderr_has is unused by Task 1's own rows; Tasks 2-4 call it via tally.
# shellcheck disable=SC2317 # invoked indirectly, as `tally check_stderr_has ...`
check_stderr_has() {
  local got=no
  grep -q -- "$2" "$SUT_STDERR" && got=yes
  check_eq "$1" 'yes' "$got"
}

# tally <label-and-check...> -- run one check and fold its verdict into the
# counters, so a row's extra assertions are counted like its assert_row.
tally() {
  total=$((total + 1))
  if ! "$@"; then
    failed=$((failed + 1))
  fi
}

# ---- REUSE: a worktree already carries the branch ----------------------
#
# The resumption case the ladder in implement-work's SKILL.md is built on. The
# path printed has to be the existing worktree's, not the one asked for: the
# caller works in whatever this names.

total=$((total + 1))
stub_dir_new
W="$(build_repo reuse)"
git_repo_checkout "$W" task main
git_repo_checkout "$W" main
WT_EXISTING="$(wt_path reuse-existing)"
git -C "$W" worktree add -q "$WT_EXISTING" task
WT_NEW="$(wt_path reuse-new)"
run_in "$W" task "$WT_NEW"
assert_row 'existing-worktree-is-reused' 0 "REUSE $(real_path "$WT_EXISTING")\n"
tally check_absent 'existing-worktree-is-reused: the asked-for path was not created' "$WT_NEW"

# The main working tree counts as a worktree: `git worktree list` lists it
# first, and a run from a checkout that is already on the branch must not cut a
# second workspace for it.

total=$((total + 1))
stub_dir_new
W="$(build_repo reusemain)"
git_repo_checkout "$W" task main
WT_NEW="$(wt_path reusemain-new)"
run_in "$W" task "$WT_NEW"
assert_row 'main-working-tree-is-reused' 0 "REUSE $(real_path "$W")\n"
tally check_absent 'main-working-tree-is-reused: the asked-for path was not created' "$WT_NEW"

# ---- ATTACHED: the branch exists locally, with no worktree -------------

total=$((total + 1))
stub_dir_new
W="$(build_repo localonly)"
git_repo_checkout "$W" task main
git_repo_commit "$W" task.txt 'local work\n' 'task work'
TASK_SHA="$(git -C "$W" rev-parse task)"
git_repo_checkout "$W" main
WT_NEW="$(wt_path localonly-new)"
run_in "$W" task "$WT_NEW"
assert_row 'local-branch-is-attached' 0 "ATTACHED ${WT_NEW}\n"
tally check_head 'local-branch-is-attached: the workspace is at the branch tip' "$WT_NEW" "$TASK_SHA"
tally check_on_branch 'local-branch-is-attached: the workspace is on the branch' "$WT_NEW" task

# The local answer must not depend on the remote being reachable: a branch that
# exists locally is settled before `origin` is consulted at all. `origin` is
# pointed at a path that does not exist, so any remote access would exit 128
# and this row would stop being an ATTACHED.

total=$((total + 1))
stub_dir_new
W="$(build_repo localnoremote)"
git_repo_checkout "$W" task main
git_repo_checkout "$W" main
git_repo_remote "$W" origin "${HARNESS_TMP}/remotes/acme/absent.git"
WT_NEW="$(wt_path localnoremote-new)"
run_in "$W" task "$WT_NEW"
assert_row 'local-branch-does-not-consult-the-remote' 0 "ATTACHED ${WT_NEW}\n"
tally check_on_branch 'local-branch-does-not-consult-the-remote: on the branch' "$WT_NEW" task

# ---- CREATE: the branch exists nowhere --------------------------------
#
# This is the row that dies when `--exit-code` is dropped: `ls-remote` then
# exits 0 for a name it never matched, the script takes the "found on the
# remote" arm, and the fetch fails instead of the caller being told to create
# the branch.

total=$((total + 1))
stub_dir_new
W="$(build_repo nowhere)"
WT_NEW="$(wt_path nowhere-new)"
run_in "$W" task "$WT_NEW"
assert_row 'nowhere-is-create' 0 'CREATE\n'
tally check_absent 'nowhere-is-create: no workspace was created' "$WT_NEW"
tally check_local_branch 'nowhere-is-create: no branch was created' "$W" task no

harness_exit "$failed" "$total"
