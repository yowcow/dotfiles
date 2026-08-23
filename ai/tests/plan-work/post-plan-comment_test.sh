#!/usr/bin/env bash
# Table test for ai/skills/plan-work/scripts/post-plan-comment.sh.
#
# The script's header names four guards, and each row below exists for one of
# them.
#
# 1. The body is only ever read from a file and reaches `gh` on stdin as a
#    single JSON document (`jq -Rs`, -R raw and -s slurped). Two rows hold that:
#    the payload is compared byte for byte against a hand-written golden — which
#    is what makes `jq -R` (one JSON document per line, same argv) detectable —
#    and the fixture carries two shell substitutions writing to $PLAN_CANARY, so
#    a version that let the body reach the shell leaves a file behind. The
#    golden is hand-written rather than generated with `jq`, which would check
#    the implementation against itself.
# 2. The id printed is the numeric REST id, not the GraphQL node id. The
#    response fixture is raw and carries both, so the script's own --jq runs and
#    a `.node_id` version prints IC_... instead.
# 3. Nothing here edits an existing comment: the argv is POST .../comments, and
#    the stub matches argv exactly, so a PATCH version is an unstubbed call.
# 4. The usage guards refuse before any call: `gh responses` is 0 on every
#    refusing row, so a dropped guard shows up as a call that happened. Two
#    rows cover the issue-number guard rather than one, and the second is the
#    load-bearing half: `abc` proves only that some check exists, while `7x`
#    proves the pattern is **anchored**. Measured — with only the `abc` row,
#    weakening `^[0-9]+$` to `[0-9]+` left this file reporting ok 7/7, so a
#    number like `7x` would have been forwarded to the API.
#
#    These two rows still do not exhaust "looks numeric". Measured: under a
#    UTF-8 locale `[0-9]` also matches fullwidth `２５４４` and Arabic-Indic
#    `٢٥٤٤` (both rejected under `LC_ALL=C`), and the script forwards such an
#    id to `gh` rather than refusing. That is a defect in the script, so the
#    fix is out of this task's scope (`ai/skills/` is excluded) and is tracked
#    in #229. Deliberately NOT given a row here: asserting the current
#    behaviour would pin a defect as correct, and asserting the intended
#    behaviour would leave the suite red against the shipped script.
#
# RED verification (mutations are not committed) — see ai/tests/README.md:
#   tmp="$(mktemp -d)"; cp ai/skills/plan-work/scripts/post-plan-comment.sh "$tmp/mut.sh"
#   # edit one guard out of "$tmp/mut.sh", then:
#   SUT="$tmp/mut.sh" ai/tests/run.sh ai/tests/plan-work/post-plan-comment_test.sh
set -euo pipefail

# harness.sh is linted on its own, so following it from here buys nothing. The
# disable keeps a bare `shellcheck <file>` clean.
# shellcheck source-path=SCRIPTDIR
# shellcheck source=../lib/harness.sh
# shellcheck disable=SC1091
. "$(dirname -- "${BASH_SOURCE[0]}")/../lib/harness.sh"

SUT="${SUT:-${REPO_ROOT}/ai/skills/plan-work/scripts/post-plan-comment.sh}"
HERE="$(dirname -- "${BASH_SOURCE[0]}")"

BODY="${HERE}/fixtures/plan-body.md"
MISSING="${HARNESS_TMP}/no-such-body.md"

# Exported so the fixture's `touch "$PLAN_CANARY"` would land somewhere
# observable if the body ever reached a shell. Nothing in this suite creates it.
PLAN_CANARY="${HARNESS_TMP}/canary"
export PLAN_CANARY

failed=0
total=0

while IFS='|' read -r name args response want_exit want_calls want_stdout want_payload; do
  case "$name" in '' | '#'*) continue ;; esac
  total=$((total + 1))
  stub_dir_new

  # `<fixture>[:<exit-status>]`, or `-` for a row that never reaches the API.
  if [ "$response" != '-' ]; then
    fixture="${response%%:*}"
    status=0
    case "$response" in *:*) status="${response##*:}" ;; esac
    gh_stub_raw_response 1 "$status" \
      api --method POST "repos/acme/widgets/issues/7/comments" --input - \
      --jq '.id, .html_url' <"${HERE}/fixtures/${fixture}.json"
  fi

  # @BODY / @MISSING keep the row table free of absolute paths.
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
# name|args|response|exit|calls|stdout|payload
posts-body-prints-numeric-id|acme widgets 7 @BODY|comment-created|0|1|expected/created.out|expected/plan-body.payload.json
api-failure-is-not-a-post|acme widgets 7 @BODY|not-found:1|1|1|fixtures/not-found.json|expected/plan-body.payload.json
missing-body-file|acme widgets 7 @MISSING|-|1|0|-|-
non-numeric-issue|acme widgets abc @BODY|-|1|0|-|-
partially-numeric-issue|acme widgets 7x @BODY|-|1|0|-|-
too-few-args|acme widgets 7|-|1|0|-|-
too-many-args|acme widgets 7 @BODY extra|-|1|0|-|-
no-args||-|1|0|-|-
ROWS

harness_exit "$failed" "$total"
