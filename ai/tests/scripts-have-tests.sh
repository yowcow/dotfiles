#!/usr/bin/env bash
# The coverage gate: every script under ai/skills/*/scripts/ must have a test
# file under ai/tests/, or a line in ai/tests/scripts-have-tests.allowlist.
# Usage: scripts-have-tests.sh [<repo-root>]
#
# Why this exists: without it a script can land under ai/skills/*/scripts/ with
# no test, nobody observes the absence, and the suite reports green — the
# amplifier #180 identified (nobody is running the code) reappearing through a
# door the per-script tests do not cover. The gate is permanent: it stays after
# coverage is complete, because the property it holds is about the *next*
# script, not the current ones.
#
# It is a script rather than a check inlined in scripts-have-tests_test.sh for
# the same reason run.sh has run_test.sh: its own conditions — a comment line is
# not an entry, an empty enumeration is an error, a stale entry is an error, an
# empty test file is not coverage — are prose until something runs them. As a
# script it is drivable against synthetic trees and against a deliberately
# broken copy through the suite's documented `SUT=` path. What run.sh collects is
# still the *_test.sh, whose first cases run this gate against the real tree, so
# `make -C ai test` runs it with no Makefile or workflow change.
#
# `set -e` is deliberately absent, as in run.sh: this is an accumulating
# reporter, and one uncovered script must not stop it from naming the rest.
set -uo pipefail

HERE="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# The root is anchored on this file's own location, never the cwd: `make -C ai
# test` runs with cwd ai/ and a direct invocation from the repository root runs
# with cwd at the root. A cwd-relative default would find nothing in one of
# those and report success having checked no file — the failure recorded in
# ai/tests/lint.sh's header. The optional argument exists so the test file can
# point the gate at a synthetic tree; it is the same shape, so the derivation
# below is the one under test rather than a second copy of it.
ROOT="${1:-}"
if [ -z "$ROOT" ]; then
  ROOT="$(CDPATH='' cd -- "${HERE}/../.." && pwd)"
fi

SKILLS_ROOT="${ROOT}/ai/skills"
TESTS_ROOT="${ROOT}/ai/tests"
ALLOWLIST="${TESTS_ROOT}/scripts-have-tests.allowlist"

# The listing is a plain foreground pipeline into a temp file, not a process
# substitution feeding the loop. In `done < <(find ...)` the producer's exit
# status is unreachable: a `find` that dies partway through the tree — an
# unreadable subdirectory, say — leaves the loop running on whatever it managed
# to emit, and a gate that enumerated half the tree would report the half it read
# as fully covered. Measured in ai/tests/lint.sh and ai/tests/run.sh, which both
# hit this and record it. `pipefail` is what makes the single `if !` sufficient:
# it catches a failure in either stage.
#
# A missing ai/skills reaches the same message rather than an empty enumeration,
# and that is correct — the tree really was not read.
LISTING="$(mktemp)"
trap 'rm -f "$LISTING"' EXIT

if ! find "$SKILLS_ROOT" -type f -print0 | sort -z >"$LISTING"; then
  printf 'scripts-have-tests: listing %s failed — the tree was not fully read\n' "$SKILLS_ROOT" >&2
  exit 1
fi

# Selection is by position in the tree, not by shebang: the question is "did
# something land in a scripts/ directory", and a shebang matcher restricted to
# sh and bash — which is what ai/tests/lint.sh must use, because ShellCheck
# supports only those — would leave a python or perl script under scripts/
# silently exempt. Depth is not limited either, so scripts/<subdir>/x.sh is
# enumerated too; the expected test path mirrors the subdirectory.
#
# The second path segment must be exactly `scripts`, tested after stripping the
# skill segment rather than with a `*/scripts/*` glob: the glob also matches
# ai/skills/<skill>/references/scripts/x.sh, which is not a skill's script
# directory.
scripts=()
while IFS= read -r -d '' abs; do
  rel="${abs#"${SKILLS_ROOT}/"}"
  if [ "$rel" = "$abs" ]; then
    continue
  fi
  case "${rel#*/}" in
    scripts/*) ;;
    *) continue ;;
  esac
  scripts+=("$rel")
done <"$LISTING"

# An empty enumeration can only mean the selection above broke: this repository
# has skill scripts, and a gate that reports "nothing to check, all good" is
# indistinguishable from a fully covered tree. That is the "absent" versus
# "could not ask" confusion this suite exists to catch, pointed at the gate
# itself.
if [ "${#scripts[@]}" -eq 0 ]; then
  printf 'scripts-have-tests: no script found under %s/*/scripts/ — the enumeration is broken\n' "$SKILLS_ROOT" >&2
  exit 1
fi

# The allowlist. Absent means "no exemptions" and is a success: the gate is
# permanent, so the day the last entry goes must not be the day the gate starts
# failing or has to be removed. Present-but-unreadable is an error, because
# reading it as absent would answer "could not ask" with "nothing there" and
# report every exempted script as uncovered.
#
# Entries are newline-joined into one string and matched with a `case` whose
# needle is quoted, so the comparison is literal rather than a glob, and there is
# no array expansion to guard under `set -u`.
ALLOW=$'\n'
if [ -e "$ALLOWLIST" ]; then
  if [ ! -r "$ALLOWLIST" ]; then
    printf 'scripts-have-tests: %s exists but cannot be read\n' "$ALLOWLIST" >&2
    exit 1
  fi
  # `|| [ -n "$line" ]` so a final line with no trailing newline is still read.
  while IFS= read -r line || [ -n "$line" ]; do
    # Trimmed, so an entry with stray indentation or a trailing space still
    # matches rather than turning into a stale entry the author cannot see.
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    if [ -z "$line" ]; then
      continue
    fi
    # Comment lines are not entries. The group separators between TODO items
    # outlive every entry, so reading one as a name would fail the gate on its
    # own allowlist through the stale-entry rule below.
    case "$line" in
      '#'*) continue ;;
    esac
    ALLOW="${ALLOW}${line}"$'\n'
  done <"$ALLOWLIST"
fi

in_allowlist() {
  case "$ALLOW" in
    *$'\n'"$1"$'\n'*) return 0 ;;
  esac
  return 1
}

problems=0
with_tests=0
exempted=0
notes=()

for rel in "${scripts[@]}"; do
  key="ai/skills/${rel}"
  skill="${rel%%/*}"
  rest="${rel#*/scripts/}"
  want="ai/tests/${skill}/${rest%.sh}_test.sh"
  abs_test="${ROOT}/${want}"
  # Non-empty and readable, not merely present. run.sh collects an empty
  # *_test.sh and `bash <empty>` exits 0, so an empty file is a passing test with
  # no detection power; counting it as coverage would let exactly the state this
  # gate exists to prevent through the front door.
  if [ -f "$abs_test" ] && [ -s "$abs_test" ] && [ -r "$abs_test" ]; then
    with_tests=$((with_tests + 1))
    if in_allowlist "$key"; then
      notes+=("scripts-have-tests: allowlist entry no longer needed (the script has a test): ${key}")
    fi
    continue
  fi
  if in_allowlist "$key"; then
    exempted=$((exempted + 1))
    continue
  fi
  printf 'scripts-have-tests: no test for %s (expected %s)\n' "$key" "$want" >&2
  problems=$((problems + 1))
done

# A stale entry is an error: an exemption must not outlive the script it exempts,
# or a rename would silently carry the old script's pass to nothing at all while
# the new name goes unchecked.
if [ "$ALLOW" != $'\n' ]; then
  while IFS= read -r entry; do
    if [ -z "$entry" ]; then
      continue
    fi
    found=0
    for rel in "${scripts[@]}"; do
      if [ "ai/skills/${rel}" = "$entry" ]; then
        found=1
        break
      fi
    done
    if [ "$found" -eq 0 ]; then
      printf 'scripts-have-tests: allowlist names no script under %s/*/scripts/: %s\n' "$SKILLS_ROOT" "$entry" >&2
      problems=$((problems + 1))
    fi
  done <<<"$ALLOW"
fi

if [ "$problems" -ne 0 ]; then
  printf 'scripts-have-tests: %s problem(s)\n' "$problems" >&2
  exit 1
fi

if [ "${#notes[@]}" -ne 0 ]; then
  printf '%s\n' "${notes[@]}"
fi
printf 'scripts-have-tests: %s script(s), %s with tests, %s exempted by the allowlist\n' \
  "${#scripts[@]}" "$with_tests" "$exempted"
