#!/usr/bin/env bash
# Run the offline test suite: every tests/**/*_test.sh, each in its own bash
# process so one file's failure neither aborts nor infects the rest.
# Usage: tests/run.sh [test-file ...]
set -uo pipefail

ROOT="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [ "$#" -gt 0 ]; then
  files=("$@")
else
  shopt -s nullglob globstar
  files=("${ROOT}"/**/*_test.sh)
fi

if [ "${#files[@]}" -eq 0 ]; then
  echo "run.sh: no test files found under ${ROOT}" >&2
  exit 1
fi

# SUT names one script under test, so applying it to a whole suite would point
# every test file at the same file. It exists for RED verification against a
# pre-fix script, which is always a single file.
if [ -n "${SUT:-}" ] && [ "${#files[@]}" -ne 1 ]; then
  echo "run.sh: SUT is set but ${#files[@]} test files were selected; name one file" >&2
  exit 1
fi

# Whether the override reaches anything is up to the selected file: one that
# never reads $SUT runs against its own default and passes, so a mistyped file
# name during RED verification would come back green and read as "this test
# cannot detect the defect". Printing what is honoured makes that visible, and
# is printed rather than enforced because a file may consume $SUT indirectly —
# grepping for the name would refuse legitimate runs.
if [ -n "${SUT:-}" ]; then
  printf 'run.sh: SUT override in effect: %s\n' "$SUT"
fi

failed=0
for f in "${files[@]}"; do
  if ! bash "$f"; then
    failed=$((failed + 1))
  fi
done

if [ "$failed" -ne 0 ]; then
  printf '%s of %s test files failed\n' "$failed" "${#files[@]}"
  exit 1
fi
printf 'all %s test files passed\n' "${#files[@]}"
