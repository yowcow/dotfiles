#!/usr/bin/env bash
# Table test for ai/skills/plan-work/scripts/close-dropped-sub-issue.sh.
#
# The script's header names two guards and one non-action, and the rows hold all
# three.
#
# 1. The reason must be "not planned". `gh issue close` is stubbed with that
#    exact argv, and the stub matches argv whole, so a version closing with the
#    default reason is an unstubbed call rather than a silent pass. The
#    read-back row pins the same thing from the other side: stdout carries the
#    stateReason a caller would see.
# 2. The reason body comes from a file and reaches gh on stdin as one JSON
#    document. The payload is compared byte for byte, so `jq -R` — same argv —
#    is detectable, and the fixture's $PLAN_CANARY substitutions catch a body
#    that reached a shell.
# 3. Nothing removes the sub-issue link: the row asserts exactly three
#    responses, so a version that also deleted the relation makes a fourth,
#    unstubbed call.
#
# The three calls are stubbed by index, which is what pins the order — post the
# reason, then close. A version closing first answers call 1 with the comment
# entry's argv and is reported as unstubbed.
#
# RED verification (mutations are not committed) — see ai/tests/README.md:
#   tmp="$(mktemp -d)"; cp ai/skills/plan-work/scripts/close-dropped-sub-issue.sh "$tmp/mut.sh"
#   SUT="$tmp/mut.sh" ai/tests/run.sh ai/tests/plan-work/close-dropped-sub-issue_test.sh
set -euo pipefail

# shellcheck source-path=SCRIPTDIR
# shellcheck source=../lib/harness.sh
# shellcheck disable=SC1091
. "$(dirname -- "${BASH_SOURCE[0]}")/../lib/harness.sh"

SUT="${SUT:-${REPO_ROOT}/ai/skills/plan-work/scripts/close-dropped-sub-issue.sh}"
HERE="$(dirname -- "${BASH_SOURCE[0]}")"

BODY="${HERE}/fixtures/plan-body.md"
MISSING="${HARNESS_TMP}/no-such-reason.md"
PLAN_CANARY="${HARNESS_TMP}/canary"
export PLAN_CANARY

# Byte-identical to the script's own --jq expression.
VIEW_JQ='"#\(.number) \(.state) (\(.stateReason))"'

failed=0
total=0

# fail_at: which of the three calls answers non-zero (`-` for none). Every row
# stubs all three, because a row that stubbed only up to its failure could not
# tell "the script stopped there" from "the script called something nobody
# stubbed".
while IFS='|' read -r name args fail_at want_exit want_calls want_stdout want_payload; do
  case "$name" in '' | '#'*) continue ;; esac
  total=$((total + 1))
  stub_dir_new

  s1=0 s2=0 s3=0
  case "$fail_at" in
    1) s1=1 ;;
    2) s2=1 ;;
    3) s3=1 ;;
  esac
  gh_stub_response 1 "$s1" \
    api --method POST "repos/acme/widgets/issues/7/comments" --input - \
    <"${HERE}/fixtures/not-found.json"
  gh_stub_response 2 "$s2" \
    issue close 7 --repo acme/widgets --reason "not planned" </dev/null
  gh_stub_raw_response 3 "$s3" \
    issue view 7 --repo acme/widgets --json number,state,stateReason --jq "$VIEW_JQ" \
    <"${HERE}/fixtures/issue-closed.json"

  args="${args//@BODY/$BODY}"
  args="${args//@MISSING/$MISSING}"
  read -ra argv <<<"$args"
  run_sut bash "$SUT" ${argv[@]+"${argv[@]}"}

  want_paths=(/dev/null)
  if [ "$want_stdout" != '-' ]; then want_paths=("${HERE}/${want_stdout}"); fi

  fails_here=0
  if ! check_eq "${name}: exit" "$want_exit" "$SUT_STATUS"; then fails_here=1; fi
  if ! check_eq "${name}: gh responses" "$want_calls" "$(gh_call_count)"; then fails_here=1; fi
  if ! check_stdout_files "${name}: stdout" "${want_paths[@]}"; then fails_here=1; fi
  if ! check_no_violations "${name}: argv"; then fails_here=1; fi
  if [ "$want_payload" != '-' ]; then
    if ! check_gh_stdin "${name}: payload" 1 "${HERE}/${want_payload}"; then fails_here=1; fi
  fi
  if [ -e "$PLAN_CANARY" ]; then
    printf 'FAIL %s: the body was interpreted by a shell (%s exists)\n' "$name" "$PLAN_CANARY"
    rm -f "$PLAN_CANARY"
    fails_here=1
  fi
  if [ "$fails_here" -ne 0 ]; then
    failed=$((failed + 1))
    printf '  stderr: %s\n' "$(head -c 400 "$SUT_STDERR")"
  fi
done <<'ROWS'
# name|args|fail_at|exit|calls|stdout|payload
closes-as-not-planned|acme widgets 7 @BODY|-|0|3|expected/closed.out|expected/plan-body.payload.json
reason-post-fails-nothing-is-closed|acme widgets 7 @BODY|1|1|1|-|expected/plan-body.payload.json
close-fails|acme widgets 7 @BODY|2|1|2|-|expected/plan-body.payload.json
read-back-fails|acme widgets 7 @BODY|3|1|3|fixtures/issue-closed.json|expected/plan-body.payload.json
missing-reason-file|acme widgets 7 @MISSING|-|1|0|-|-
non-numeric-child|acme widgets abc @BODY|-|1|0|-|-
too-few-args|acme widgets 7|-|1|0|-|-
too-many-args|acme widgets 7 @BODY extra|-|1|0|-|-
no-args||-|1|0|-|-
ROWS

harness_exit "$failed" "$total"
