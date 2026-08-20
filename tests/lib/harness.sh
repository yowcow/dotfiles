#!/usr/bin/env bash
# Sourced by every test file. It puts the fake `gh` on PATH, hands out stub
# directories, runs the script under test, and compares results.
#
# Sourcing this file is what makes a test file offline: PATH is rewritten so
# `gh` resolves to the stub, and that resolution is asserted here rather than
# assumed, because a PATH mistake would send the whole suite to the real `gh`
# and the failure mode is a suite that still passes.

HARNESS_LIB_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(CDPATH='' cd -- "${HARNESS_LIB_DIR}/../.." && pwd)"
export REPO_ROOT

PATH="${HARNESS_LIB_DIR}/bin:${PATH}"
export PATH

if [ "$(command -v gh)" != "${HARNESS_LIB_DIR}/bin/gh" ]; then
  echo "harness: gh resolves to $(command -v gh), not the stub — refusing to run" >&2
  exit 1
fi

HARNESS_TMP="$(mktemp -d)"
trap 'rm -rf "${HARNESS_TMP}"' EXIT

SUT_STDOUT="${HARNESS_TMP}/stdout"
SUT_STDERR="${HARNESS_TMP}/stderr"
SUT_STATUS=0

stub_dir_new() {
  GH_STUB_DIR="$(mktemp -d "${HARNESS_TMP}/stub.XXXXXX")"
  export GH_STUB_DIR
  : >"${GH_STUB_DIR}/calls"
  printf '%s' 0 >"${GH_STUB_DIR}/count"
}

# gh_stub_response <index|*> <exit-status> <argv...>   body on stdin
gh_stub_response() {
  local idx="$1" status="$2"
  shift 2
  if ! [[ "$idx" =~ ^([1-9][0-9]*|\*)$ ]]; then
    echo "gh_stub_response: index must be a positive integer or '*', got '${idx}'" >&2
    return 1
  fi
  if ! [[ "$status" =~ ^([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$ ]]; then
    echo "gh_stub_response: exit status must be 0-255, got '${status}'" >&2
    return 1
  fi
  local arg joined=""
  for arg in "$@"; do
    # The manifest is TSV with one line per entry and the argv in its last
    # field, so an argv carrying a tab, a newline, or the \x1f separator cannot
    # be represented; matching would then silently miss and the case would fail
    # as "unexpected argv" with no hint why.
    case "$arg" in
      *$'\t'* | *$'\n'* | *$'\x1f'*)
        printf '%s\n' "gh_stub_response: argv element contains tab, newline or \\x1f: '${arg}'" >&2
        return 1
        ;;
    esac
    joined="${joined}${arg}"$'\x1f'
  done
  local entry_no body
  entry_no=1
  if [ -f "${GH_STUB_DIR}/manifest" ]; then
    entry_no=$(($(wc -l <"${GH_STUB_DIR}/manifest") + 1))
  fi
  body="${GH_STUB_DIR}/body.${entry_no}"
  cat >"$body"
  printf '%s\t%s\t%s\t%s\n' "$idx" "$status" "$body" "$joined" >>"${GH_STUB_DIR}/manifest"
}

gh_call_count() {
  local n=0
  if [ -f "${GH_STUB_DIR}/count" ]; then
    n="$(cat "${GH_STUB_DIR}/count")"
  fi
  printf '%s\n' "$n"
}

gh_violations() {
  if [ -f "${GH_STUB_DIR}/violations" ]; then
    cat "${GH_STUB_DIR}/violations"
  fi
}

run_sut() {
  # SUT_STATUS is read by the test file that sourced this, which shellcheck
  # cannot see from here; exporting it instead would push it into the
  # environment of the script under test, which has no business seeing it.
  # shellcheck disable=SC2034
  SUT_STATUS=0
  # shellcheck disable=SC2034
  "$@" >"${SUT_STDOUT}" 2>"${SUT_STDERR}" </dev/null || SUT_STATUS=$?
}

check_eq() {
  local label="$1" want="$2" got="$3"
  if [ "$want" = "$got" ]; then
    return 0
  fi
  printf 'FAIL %s: want [%s], got [%s]\n' "$label" "$want" "$got"
  return 1
}

# check_bytes <label> <expected>   expected is a printf '%b' format string
check_bytes() {
  local label="$1" want="$2" wantfile="${HARNESS_TMP}/want"
  printf '%b' "$want" >"$wantfile"
  if cmp -s "$wantfile" "${SUT_STDOUT}"; then
    return 0
  fi
  printf 'FAIL %s: stdout differs\n  want: %s\n  got:  %s\n' \
    "$label" "$(od -An -c <"$wantfile" | tr -s ' \n' ' ')" \
    "$(od -An -c <"${SUT_STDOUT}" | tr -s ' \n' ' ')"
  return 1
}

check_no_violations() {
  local label="$1" v
  v="$(gh_violations)"
  if [ -z "$v" ]; then
    return 0
  fi
  printf 'FAIL %s: the gh stub was called with an argv no case stubbed:\n%s\n' "$label" "$v"
  return 1
}

harness_exit() {
  local failed="$1" total="$2"
  if [ "$failed" -eq 0 ]; then
    printf 'ok %s/%s %s\n' "$total" "$total" "${0##*/}"
    exit 0
  fi
  printf 'not ok %s/%s failed in %s\n' "$failed" "$total" "${0##*/}"
  exit 1
}
