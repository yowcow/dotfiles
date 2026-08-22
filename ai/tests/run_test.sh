#!/usr/bin/env bash
# Tests ai/tests/run.sh itself — specifically that a $SUT naming no existing
# non-empty file stops the run before any test file executes.
#
# Why this file exists: a $SUT pointing at a path that isn't there makes every
# `run_sut bash "$SUT"` in the selected test file exit 127, so nearly every row
# FAILs — the same shape a successful RED verification has. Reading that as
# "the test detects the defect" turns a zero-detection-power test into an
# accepted one (#214, measured while implementing #187).
#
# Whether a test actually ran is asserted by the fixture's own marker file, not
# by parsing the runner's output: the runner prints a summary either way, and
# only the marker distinguishes "refused before running anything" from "ran and
# the rows failed".
#
# The fixture lives under $HARNESS_TMP, which is a bare `mktemp -d` (harness.sh)
# and so sits outside the tree run.sh walks: suite discovery — `find ai/tests
# -name '*_test.sh'` — cannot reach it whatever it is named. Not naming it
# *_test.sh is belt-and-braces for the day a fixture does land under ai/tests.
set -euo pipefail

# shellcheck source-path=SCRIPTDIR
# shellcheck source=lib/harness.sh
# shellcheck disable=SC1091
. "$(dirname -- "${BASH_SOURCE[0]}")/lib/harness.sh"

# The runner under test. Overridable by $SUT for RED verification, same as
# every other file in this suite; the *child* runner invocations below set
# their own SUT explicitly, so this value never leaks into them.
SUT="${SUT:-${REPO_ROOT}/ai/tests/run.sh}"

failed=0
total=0

# A throwaway test file for the runner to select. It records that it ran, then
# passes, so "did anything run" is a file-existence question. The heredoc is
# quoted, so ${MARKER} reaches the fixture literally and is expanded when the
# fixture runs, from the environment run_case hands it.
FIXTURE="${HARNESS_TMP}/fixture-probe.sh"
MARKER="${HARNESS_TMP}/fixture-ran"
cat >"$FIXTURE" <<'FIX'
#!/usr/bin/env bash
printf 'ran\n' >"${MARKER}"
printf 'ok 1/1 fixture-probe.sh\n'
FIX

# run_case <child-sut> -- runs the runner under test with SUT set to
# <child-sut> and the fixture as the only selected test file.
run_case() {
  rm -f "$MARKER"
  run_sut env "SUT=$1" "MARKER=${MARKER}" bash "$SUT" "$FIXTURE"
}

marker_state() {
  if [ -e "$MARKER" ]; then printf 'ran\n'; else printf 'did-not-run\n'; fi
}

# --- case 1: a SUT that does not exist stops the run --------------------------
total=$((total + 1))
fails_here=0
missing="${HARNESS_TMP}/no-such-script.sh"
rm -f "$missing"
run_case "$missing"
if ! check_eq 'missing SUT: exit' 1 "$SUT_STATUS"; then fails_here=1; fi
if ! check_eq 'missing SUT: no test file ran' 'did-not-run' "$(marker_state)"; then fails_here=1; fi
if ! grep -q 'SUT' "$SUT_STDERR"; then
  printf 'FAIL missing SUT: stderr does not name SUT: %s\n' "$(head -c 400 "$SUT_STDERR")"
  fails_here=1
fi
if ! grep -qF -- "$missing" "$SUT_STDERR"; then
  printf 'FAIL missing SUT: stderr does not name the path: %s\n' "$(head -c 400 "$SUT_STDERR")"
  fails_here=1
fi
if [ "$fails_here" -ne 0 ]; then failed=$((failed + 1)); fi

# --- case 2: an empty SUT file stops the run ---------------------------------
# An empty file exists, so an existence-only guard would let it through, and
# `bash <empty>` exits 0 — the script under test would appear to succeed at
# everything, which is a *green* RED verification: even more misleading.
total=$((total + 1))
fails_here=0
empty="${HARNESS_TMP}/empty-script.sh"
: >"$empty"
run_case "$empty"
if ! check_eq 'empty SUT: exit' 1 "$SUT_STATUS"; then fails_here=1; fi
if ! check_eq 'empty SUT: no test file ran' 'did-not-run' "$(marker_state)"; then fails_here=1; fi
if ! grep -qF -- "$empty" "$SUT_STDERR"; then
  printf 'FAIL empty SUT: stderr does not name the path: %s\n' "$(head -c 400 "$SUT_STDERR")"
  fails_here=1
fi
if [ "$fails_here" -ne 0 ]; then failed=$((failed + 1)); fi

# --- case 3: a real SUT still runs the selected file -------------------------
# The guard must not cost the mechanism it protects, and this is what would
# catch a guard whose condition is inverted.
total=$((total + 1))
fails_here=0
good="${HARNESS_TMP}/good-script.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"$good"
run_case "$good"
if ! check_eq 'valid SUT: exit' 0 "$SUT_STATUS"; then fails_here=1; fi
if ! check_eq 'valid SUT: the test file ran' 'ran' "$(marker_state)"; then fails_here=1; fi
if ! grep -qF "SUT override in effect: ${good}" "$SUT_STDOUT"; then
  printf 'FAIL valid SUT: the override was not reported: %s\n' "$(head -c 400 "$SUT_STDOUT")"
  fails_here=1
fi
if [ "$fails_here" -ne 0 ]; then failed=$((failed + 1)); fi

harness_exit "$failed" "$total"
