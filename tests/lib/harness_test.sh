#!/usr/bin/env bash
# Self-test of the harness mechanism. The three properties tested here are the
# ones the suite's trustworthiness rests on: an argv nobody stubbed must fail
# the case instead of reaching the real `gh` (and the network), the stub must
# count calls so a poll loop's second iteration can differ from its first, and
# stdout must be compared byte-for-byte — a defect whose whole signature is one
# stray newline is invisible to a line-count comparison.
set -euo pipefail

# harness.sh is linted on its own, so following it from here buys nothing. The
# disable keeps a bare `shellcheck <file>` clean — verified clean under
# `shellcheck -x` too, so item 2's CI is free to invoke it either way.
# shellcheck source-path=SCRIPTDIR
# shellcheck source=harness.sh
# shellcheck disable=SC1091
. "$(dirname -- "${BASH_SOURCE[0]}")/harness.sh"

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

# --- property 4: an argv element the manifest cannot represent is rejected -----
total=$((total + 1))
stub_dir_new
fails_here=0
status=0
gh_stub_response 1 0 api "$(printf 'a\tb')" </dev/null 2>/dev/null || status=$?
if ! check_eq "helper rejects a tab in argv" 1 "$status"; then fails_here=1; fi
status=0
gh_stub_response 0 0 api ok </dev/null 2>/dev/null || status=$?
if ! check_eq "helper rejects index 0" 1 "$status"; then fails_here=1; fi
if [ "$fails_here" -ne 0 ]; then failed=$((failed + 1)); fi

harness_exit "$failed" "$total"
