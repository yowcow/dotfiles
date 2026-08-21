#!/usr/bin/env bash
# Self-test of the harness mechanism. The properties tested here are the ones
# the suite's trustworthiness rests on: an argv nobody stubbed must fail the
# case instead of reaching the real `gh` (and the network), the stub must count
# calls so a poll loop's second iteration can differ from its first, stdout must
# be compared byte-for-byte — a defect whose whole signature is one stray
# newline is invisible to a line-count comparison — the one argv the manifest
# cannot represent — the \x1f separator itself — must be refused when stubbed
# rather than never matching while an argv spanning lines must be stubbable,
# and the call index must count invocations rather than lines of argv.
set -euo pipefail

# harness.sh is linted on its own, so following it from here buys nothing. The
# disable keeps a bare `shellcheck <file>` clean — verified clean under
# `shellcheck -x` too, so item 2's CI is free to invoke it either way.
# shellcheck source-path=SCRIPTDIR
# shellcheck source=harness.sh
# shellcheck disable=SC1091
. "$(dirname -- "${BASH_SOURCE[0]}")/harness.sh"
# shellcheck source-path=SCRIPTDIR
# shellcheck source=gitrepo.sh
# shellcheck disable=SC1091
. "$(dirname -- "${BASH_SOURCE[0]}")/gitrepo.sh"

failed=0
total=0

# --- property 1: an argv with no manifest entry fails the case -----------------
total=$((total + 1))
stub_dir_new
gh_stub_response '*' 0 api "repos/acme/widgets/commits/deadbeef/check-runs" </dev/null
status=0
gh api "repos/acme/widgets/pulls/1" >/dev/null 2>&1 || status=$?
fails_here=0
if ! check_eq "unexpected argv: gh exit status" 99 "$status"; then fails_here=1; fi
if check_no_violations "unexpected argv: probe" >/dev/null 2>&1; then
  echo "FAIL unexpected argv: no violation was recorded"
  fails_here=1
fi
if ! check_eq "unexpected argv: call is still counted" 1 "$(gh_call_count)"; then fails_here=1; fi
if [ "$fails_here" -ne 0 ]; then failed=$((failed + 1)); fi

# --- property 2: the call counter selects per-call responses -------------------
total=$((total + 1))
stub_dir_new
gh_stub_response 1 0 api one <<<'first'
gh_stub_response 2 0 api one <<<'second'
gh_stub_response '*' 0 api one <<<'later'
fails_here=0
if ! check_eq "counter: call 1" 'first' "$(gh api one)"; then fails_here=1; fi
if ! check_eq "counter: call 2" 'second' "$(gh api one)"; then fails_here=1; fi
if ! check_eq "counter: call 3 falls back to *" 'later' "$(gh api one)"; then fails_here=1; fi
if ! check_eq "counter: total" 3 "$(gh_call_count)"; then fails_here=1; fi
if ! check_no_violations "counter: no violations"; then fails_here=1; fi
if [ "$fails_here" -ne 0 ]; then failed=$((failed + 1)); fi

# --- property 3: stdout is compared byte-for-byte -----------------------------
# A bare newline and no output are the same number of lines and different bytes.
total=$((total + 1))
stub_dir_new
fails_here=0
run_sut printf '\n'
if check_bytes "bytes: probe expects a mismatch" '' >/dev/null 2>&1; then
  echo "FAIL bytes: one stray newline compared equal to no output"
  fails_here=1
fi
if ! check_bytes "bytes: newline matches newline" '\n'; then fails_here=1; fi
if [ "$fails_here" -ne 0 ]; then failed=$((failed + 1)); fi

# --- property 4: \x1f is unrepresentable, a multi-line argv is not ------------
# Only the separator itself cannot be represented. Tabs and newlines can: a real
# argv spans lines — list-copilot-reviews.sh:41-43 passes its whole --jq filter
# as one three-line argument — and a manifest that could not hold one would
# leave that call unstubbable, so the pair could not be tested offline at all.
total=$((total + 1))
stub_dir_new
fails_here=0
status=0
gh_stub_response 1 0 api $'a\x1fb' </dev/null 2>/dev/null || status=$?
if ! check_eq "helper rejects \\x1f in argv" 1 "$status"; then fails_here=1; fi
status=0
gh_stub_response 0 0 api ok </dev/null 2>/dev/null || status=$?
if ! check_eq "helper rejects index 0" 1 "$status"; then fails_here=1; fi
multi=$'first\n        second'
# Guarded and asserted, not `|| true`: this file runs under `set -e`, so an
# unguarded call would abort the whole file the moment the helper refuses —
# which is exactly the pre-change state this row has to report on, and the
# remaining properties would never run. `|| true` would keep it running but
# hide a later regression back to refusing, so the status is asserted.
status=0
gh_stub_response 1 0 api "$multi" <<<'matched' || status=$?
if ! check_eq "helper accepts a multi-line argv" 0 "$status"; then fails_here=1; fi
if ! check_eq "multi-line argv matches" 'matched' "$(gh api "$multi")"; then fails_here=1; fi
if ! check_no_violations "multi-line argv: no violations"; then fails_here=1; fi
if [ "$fails_here" -ne 0 ]; then failed=$((failed + 1)); fi

# --- property 5: the counter counts invocations, not lines of argv ------------
# A real argv may legitimately carry a newline — the GraphQL query that
# list-unresolved-threads.sh passes as `-f query='...'` spans many lines. If the
# call index were derived by counting lines in the log of past argvs, one such
# call would advance the index by as many lines as it spans, and from then on an
# exact-index entry would answer a different call than the one it was written
# for: the poll-loop tests would silently stub the wrong iteration.
total=$((total + 1))
stub_dir_new
fails_here=0
gh api "$(printf 'first\nsecond')" >/dev/null 2>&1 || true
if ! check_eq "counter: a multi-line argv counts as one call" 1 "$(gh_call_count)"; then fails_here=1; fi
gh api plain >/dev/null 2>&1 || true
if ! check_eq "counter: the next call is index 2" 2 "$(gh_call_count)"; then fails_here=1; fi
if [ "$fails_here" -ne 0 ]; then failed=$((failed + 1)); fi

# --- gitrepo.sh: a repo with the requested remote URL, branches and commits ---
total=$((total + 1))
gr_fails=0
gr_bare="$(git_repo_bare acme widgets)"
gr_seed="$(git_repo_scratch seed)"
git_repo_init "$gr_seed" main
git_repo_commit "$gr_seed" README.md 'common\n' 'base'
git_repo_checkout "$gr_seed" feature main
git_repo_commit "$gr_seed" FEATURE.md 'f\n' 'feature work'
git_repo_push "$gr_seed" "$gr_bare" main feature
gr_work="$(git_repo_scratch work)"
git_repo_init "$gr_work" main
git_repo_remote "$gr_work" origin "$gr_bare"

if ! check_eq 'gitrepo: bare path encodes owner/repo' \
  'acme/widgets.git' "$(basename "$(dirname "$gr_bare")")/$(basename "$gr_bare")"; then gr_fails=1; fi
if ! check_eq 'gitrepo: remote url is the one set' \
  "$gr_bare" "$(git -C "$gr_work" remote get-url origin)"; then gr_fails=1; fi
if ! check_eq 'gitrepo: branches reached the remote' \
  'feature main' "$(git -C "$gr_bare" for-each-ref --format='%(refname:short)' refs/heads | sort | tr '\n' ' ' | sed 's/ $//')"; then gr_fails=1; fi
if ! check_eq 'gitrepo: commit message is the one given' \
  'base' "$(git -C "$gr_bare" log -1 --format=%s main)"; then gr_fails=1; fi
if ! check_eq 'gitrepo: file content is the one given' \
  'common' "$(git -C "$gr_bare" show main:README.md)"; then gr_fails=1; fi
if [ "$gr_fails" -ne 0 ]; then failed=$((failed + 1)); fi

# --- gitrepo.sh: a name that would walk the rm -rf out of its own subtree ---
#
# The victim sits one level up, inside $HARNESS_TMP, rather than beside it:
# that is enough to prove the traversal is refused, while never aiming an
# `rm -rf` anywhere a regression could do damage outside the harness's own
# temp dir. The surviving-file check is the load-bearing half — an exit-status
# check alone would still pass if the guard ever moved below the `rm -rf` it
# exists to prevent. It asserts a *file* specifically, because the unguarded
# path deletes the file and then recreates the name as a directory, which an
# existence test would read as untouched.
total=$((total + 1))
gr_guard_fails=0
: >"${HARNESS_TMP}/victim"
gr_status=0
(git_repo_scratch '../victim') >/dev/null 2>&1 || gr_status=$?
if ! check_eq 'gitrepo: traversing name is refused' '1' "$gr_status"; then gr_guard_fails=1; fi
if ! check_eq 'gitrepo: traversing name deleted nothing' 'yes' \
  "$([ -f "${HARNESS_TMP}/victim" ] && echo yes || echo no)"; then gr_guard_fails=1; fi
if [ "$gr_guard_fails" -ne 0 ]; then failed=$((failed + 1)); fi

# --- the sleep stub: counted, and it does not spend wall clock ---
total=$((total + 1))
sl_fails=0
stub_sleep_instant
stub_dir_new
sl_before="$SECONDS"
sleep 3
sleep 3
sl_elapsed=$((SECONDS - sl_before))
if ! check_eq 'sleep stub: calls counted' '2' "$(sleep_call_count)"; then sl_fails=1; fi
if [ "$sl_elapsed" -ge 2 ]; then
  printf 'FAIL sleep stub: two 3s sleeps took %ss of wall clock\n' "$sl_elapsed"
  sl_fails=1
fi
if ! check_eq 'sleep stub: resolves to the stub' \
  "${HARNESS_LIB_DIR}/bin-nosleep/sleep" "$(command -v sleep)"; then sl_fails=1; fi
if [ "$sl_fails" -ne 0 ]; then failed=$((failed + 1)); fi

harness_exit "$failed" "$total"
