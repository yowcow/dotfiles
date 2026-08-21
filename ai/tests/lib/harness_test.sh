#!/usr/bin/env bash
# Self-test of the harness mechanism. The properties tested here are the ones
# the suite's trustworthiness rests on: an argv nobody stubbed must fail the
# case instead of reaching the real `gh` (and the network), the stub must count
# calls so a poll loop's second iteration can differ from its first, stdout must
# be compared byte-for-byte — a defect whose whole signature is one stray
# newline is invisible to a line-count comparison — an argv the manifest cannot
# represent must be refused when stubbed rather than never matching, and the
# call index must count invocations rather than lines of argv. An argv
# spanning lines must be stubbable and must match only itself. `--jq` must be
# applied to a successful body and never to a failing one. One `--paginate`
# invocation must serve a page sequence, truncating at a failing page.
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

# --- property 4: only an argv the manifest cannot disambiguate is rejected ----
# The joined argv lives in its own file, so a tab or a newline inside an element
# is representable and must match. \x1f is different in kind: it is the element
# separator, so ["a\x1fb"] and ["a","b"] join to the same bytes and one case's
# body would be served to the other. That one stays refused.
total=$((total + 1))
stub_dir_new
fails_here=0
status=0
gh_stub_response 1 0 api "$(printf 'a\x1fb')" </dev/null 2>/dev/null || status=$?
if ! check_eq "helper rejects \\x1f in argv" 1 "$status"; then fails_here=1; fi
status=0
gh_stub_response 0 0 api ok </dev/null 2>/dev/null || status=$?
if ! check_eq "helper rejects index 0" 1 "$status"; then fails_here=1; fi
status=0
gh_stub_response 1 300 api ok </dev/null 2>/dev/null || status=$?
if ! check_eq "helper rejects an exit status above 255" 1 "$status"; then fails_here=1; fi
if [ "$fails_here" -ne 0 ]; then failed=$((failed + 1)); fi

# --- property 6: an argv spanning lines can be stubbed and matched exactly ----
# The GraphQL query list-unresolved-threads.sh passes as `-f query='...'` spans
# 23 lines. Refusing it would leave that script untestable; matching it loosely
# would let a different query be served this case's body.
total=$((total + 1))
stub_dir_new
fails_here=0
multi="$(printf 'query {\n  field\n}')"
other="$(printf 'query {\n  other\n}')"
# `*` rather than index 1, so the near-miss probe below can only fail on the
# argv. With an exact index it would fail for want of an entry at index 2
# whatever argv it carried, and would prove nothing about matching.
#
# The status is captured rather than left to `set -e`. This file runs under
# `set -euo pipefail`, and until the fix below lands the helper refuses this
# argv — an unguarded call would abort the whole file right here, so the run
# would report nothing about which property failed. Capturing it also makes
# "a multi-line argv can be stubbed at all" an assertion in its own right,
# which is the property being added.
status=0
gh_stub_response '*' 0 api graphql -f "query=${multi}" <<<'matched' || status=$?
if ! check_eq "multi-line argv: stubbable" 0 "$status"; then fails_here=1; fi
if ! check_eq "multi-line argv: matched" 'matched' \
  "$(gh api graphql -f "query=${multi}")"; then fails_here=1; fi
if ! check_no_violations "multi-line argv: no violations"; then fails_here=1; fi
status=0
gh api graphql -f "query=${other}" >/dev/null 2>&1 || status=$?
if ! check_eq "a different multi-line argv is not matched" 99 "$status"; then fails_here=1; fi
if check_no_violations "multi-line argv: probe" >/dev/null 2>&1; then
  echo "FAIL multi-line argv: a near-miss argv recorded no violation"
  fails_here=1
fi
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

# --- property 7: --jq is applied to a successful body, never to a failing one -
# Real `gh` filters a 200 through --jq and prints an error body verbatim
# (measured: a 200 carrying `errors` and a 401 both reach stdout raw, and
# `jq -r -c` reproduces gh's --jq byte for byte). Fixtures are therefore raw API
# bodies and the filter under test really runs. Getting this backwards would
# filter every error fixture down to nothing, and the error cases would assert
# emptiness where reality has a body.
total=$((total + 1))
stub_dir_new
fails_here=0
gh_stub_response 1 0 api graphql --jq '.items[] | select(.keep == true)' \
  <<<'{"items":[{"keep":false,"n":1},{"keep":true,"n":2}]}'
gh_stub_response 2 1 api graphql --jq '.items[] | select(.keep == true)' \
  <<<'{"errors":[{"message":"nope"}]}'
if ! check_eq "--jq filters a successful body" '{"keep":true,"n":2}' \
  "$(gh api graphql --jq '.items[] | select(.keep == true)')"; then fails_here=1; fi
status=0
out="$(gh api graphql --jq '.items[] | select(.keep == true)')" || status=$?
if ! check_eq "a failing body is printed raw" '{"errors":[{"message":"nope"}]}' "$out"; then fails_here=1; fi
if ! check_eq "a failing body keeps its exit status" 1 "$status"; then fails_here=1; fi
if ! check_no_violations "--jq: no violations"; then fails_here=1; fi
if [ "$fails_here" -ne 0 ]; then failed=$((failed + 1)); fi

# --- property 8: one --paginate invocation serves a page sequence ------------
# gh pages internally, so a script that calls it once still sees several pages'
# output concatenated. Modelling that with one response per invocation would
# make "page 1 arrived, page 2 failed" inexpressible — and that is the state in
# which stdout is non-empty while the listing is incomplete.
total=$((total + 1))
stub_dir_new
fails_here=0
gh_stub_response 1 0 api graphql --paginate --jq '.n' <<<'{"n":1}'
gh_stub_response 2 0 api graphql --paginate --jq '.n' <<<'{"n":2}'
run_sut gh api graphql --paginate --jq '.n'
if ! check_bytes "paginate: both pages, in order" '1\n2\n'; then fails_here=1; fi
if ! check_eq "paginate: exit" 0 "$SUT_STATUS"; then fails_here=1; fi
if ! check_eq "paginate: pages served" 2 "$(gh_call_count)"; then fails_here=1; fi
if ! check_no_violations "paginate: no violations"; then fails_here=1; fi
if [ "$fails_here" -ne 0 ]; then failed=$((failed + 1)); fi

# A failure on page 2 keeps page 1's output and hands back the failing status:
# non-empty stdout with a non-zero exit is precisely "you did not see all of
# it", and a caller reading emptiness alone cannot tell this from success.
total=$((total + 1))
stub_dir_new
fails_here=0
gh_stub_response 1 0 api graphql --paginate --jq '.n' <<<'{"n":1}'
gh_stub_response 2 1 api graphql --paginate --jq '.n' <<<'{"errors":[{"message":"boom"}]}'
run_sut gh api graphql --paginate --jq '.n'
if ! check_bytes "paginate: page 1 then the raw error body" \
  '1\n{"errors":[{"message":"boom"}]}\n'; then fails_here=1; fi
if ! check_eq "paginate: failing exit propagates" 1 "$SUT_STATUS"; then fails_here=1; fi
if ! check_eq "paginate: pages served before the failure" 2 "$(gh_call_count)"; then fails_here=1; fi
if ! check_no_violations "paginate: no violations after a mid-page failure"; then fails_here=1; fi
if [ "$fails_here" -ne 0 ]; then failed=$((failed + 1)); fi

# A `*` entry answers one page and stops. It matches every index, so continuing
# would loop forever; a multi-page sequence needs explicit indices.
total=$((total + 1))
stub_dir_new
fails_here=0
gh_stub_response '*' 0 api graphql --paginate <<<'only'
run_sut gh api graphql --paginate
if ! check_bytes "paginate: a wildcard entry serves one page" 'only\n'; then fails_here=1; fi
if ! check_eq "paginate: wildcard exit" 0 "$SUT_STATUS"; then fails_here=1; fi
if ! check_eq "paginate: wildcard pages served" 1 "$(gh_call_count)"; then fails_here=1; fi
# An unstubbed paginated argv is still a violation on its first page, not a
# quietly empty listing.
stub_dir_new
status=0
gh api graphql --paginate -f nothing=stubbed >/dev/null 2>&1 || status=$?
if ! check_eq "paginate: unstubbed first page fails" 99 "$status"; then fails_here=1; fi
if ! check_eq "paginate: the unstubbed call is counted" 1 "$(gh_call_count)"; then fails_here=1; fi
if [ "$fails_here" -ne 0 ]; then failed=$((failed + 1)); fi

harness_exit "$failed" "$total"
