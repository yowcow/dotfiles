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

# --- gitrepo.sh: git cannot leave the machine, whatever URL it is handed ---
#
# This is the guarantee that makes it safe to let a script under test run a
# real `git push`. Convention is not enough: `retarget-pr.sh` pushes to
# whatever `origin` says, and a test that mis-wired a remote would otherwise
# push to a real repository. GIT_ALLOW_PROTOCOL (exported by gitrepo.sh) makes
# git itself refuse every network transport before it opens a socket, so the
# guarantee holds even for a URL no test author looked at.
#
# The URL points at 127.0.0.1:1 rather than a real host so that a *regression*
# — the guard being dropped — fails against a closed local port instead of
# reaching out over the network. The assertion is on the message, not just the
# non-zero status, because "connection refused" is also non-zero and would let
# a dropped guard pass.
total=$((total + 1))
proto_fails=0
proto_repo="$(git_repo_scratch proto)"
git_repo_init "$proto_repo" main
git_repo_commit "$proto_repo" README.md 'x\n' 'only commit'
for proto_url in 'https://127.0.0.1:1/acme/widgets.git' \
  'git@127.0.0.1:acme/widgets.git' 'git://127.0.0.1:1/acme/widgets.git'; do
  git_repo_remote "$proto_repo" origin "$proto_url"
  proto_out="$(git -C "$proto_repo" push origin 'refs/heads/main:refs/heads/main' 2>&1)" && proto_status=0 || proto_status=$?
  if ! check_eq "gitrepo: ${proto_url} push is refused" '128' "$proto_status"; then proto_fails=1; fi
  case "$proto_out" in
    *"not allowed"*) ;;
    *)
      printf 'FAIL gitrepo: %s was refused for the wrong reason: %s\n' \
        "$proto_url" "$(printf '%s' "$proto_out" | head -1)"
      proto_fails=1
      ;;
  esac
done
if [ "$proto_fails" -ne 0 ]; then failed=$((failed + 1)); fi

# --- gitrepo.sh: a clone of a local bare remote can be pushed to ------------
total=$((total + 1))
clone_fails=0
clone_bare="$(git_repo_bare acme pushable)"
clone_seed="$(git_repo_scratch pushable-seed)"
git_repo_init "$clone_seed" main
git_repo_commit "$clone_seed" README.md 'common\n' 'base'
git_repo_push "$clone_seed" "$clone_bare" main
clone_work="$(git_repo_clone pushable-work "$clone_bare" main)"
if ! check_eq 'gitrepo: clone checked out the requested branch' \
  'main' "$(git -C "$clone_work" rev-parse --abbrev-ref HEAD)"; then clone_fails=1; fi
if ! check_eq 'gitrepo: clone origin is the bare repo' \
  "$clone_bare" "$(git -C "$clone_work" remote get-url origin)"; then clone_fails=1; fi
git_repo_commit "$clone_work" README.md 'changed\n' 'a change to push'
clone_status=0
git -C "$clone_work" push -q origin 'refs/heads/main:refs/heads/main' 2>/dev/null || clone_status=$?
if ! check_eq 'gitrepo: pushing to the local bare remote succeeds' '0' "$clone_status"; then clone_fails=1; fi
if ! check_eq 'gitrepo: the bare repo received the commit' \
  'a change to push' "$(git -C "$clone_bare" log -1 --format=%s main)"; then clone_fails=1; fi
if [ "$clone_fails" -ne 0 ]; then failed=$((failed + 1)); fi

# --- gitrepo.sh: a push can be made to fail, and then to succeed again -------
#
# A push that fails while everything around it works is the state #170 was
# about, and there is no way to reach it with a correctly configured remote.
# The hook is the only lever that produces it without breaking anything else,
# so that a *later* run in the same repository can then succeed.
total=$((total + 1))
deny_fails=0
git_repo_commit "$clone_work" README.md 'denied\n' 'a change the hook rejects'
deny_before="$(git -C "$clone_bare" rev-parse refs/heads/main)"
git_repo_deny_push "$clone_bare"
deny_status=0
git -C "$clone_work" push -q origin 'refs/heads/main:refs/heads/main' 2>/dev/null || deny_status=$?
if [ "$deny_status" -eq 0 ]; then
  echo 'FAIL gitrepo: the push succeeded while the deny hook was installed'
  deny_fails=1
fi
if ! check_eq 'gitrepo: a denied push moved nothing' \
  "$deny_before" "$(git -C "$clone_bare" rev-parse refs/heads/main)"; then deny_fails=1; fi
git_repo_allow_push "$clone_bare"
deny_status=0
git -C "$clone_work" push -q origin 'refs/heads/main:refs/heads/main' 2>/dev/null || deny_status=$?
if ! check_eq 'gitrepo: the push succeeds once the hook is removed' '0' "$deny_status"; then deny_fails=1; fi
if ! check_eq 'gitrepo: the bare repo caught up' \
  'a change the hook rejects' "$(git -C "$clone_bare" log -1 --format=%s main)"; then deny_fails=1; fi
if [ "$deny_fails" -ne 0 ]; then failed=$((failed + 1)); fi

# --- gitrepo.sh: a ref that points at a blob rather than a commit ------------
#
# retarget-pr.sh's ancestor gate has a third branch for `git merge-base
# --is-ancestor` failing for a reason of its own, rather than returning either
# verdict. A ref pointing at a non-commit is how that is reachable with real
# git and no stub: the fetch succeeds, FETCH_HEAD is a blob, and the ancestor
# check exits 128.
total=$((total + 1))
blob_fails=0
git_repo_blob_ref "$clone_bare" blobref 'not a commit\n'
git -C "$clone_work" fetch -q origin -- blobref
blob_sha="$(git -C "$clone_work" rev-parse FETCH_HEAD)"
if ! check_eq 'gitrepo: the fetched ref is a blob' \
  'blob' "$(git -C "$clone_work" cat-file -t "$blob_sha")"; then blob_fails=1; fi
git -C "$clone_work" fetch -q origin -- main
blob_status=0
git -C "$clone_work" merge-base --is-ancestor "$blob_sha" "$(git -C "$clone_work" rev-parse FETCH_HEAD)" 2>/dev/null || blob_status=$?
if ! check_eq 'gitrepo: is-ancestor on a blob is neither verdict' '128' "$blob_status"; then blob_fails=1; fi
if [ "$blob_fails" -ne 0 ]; then failed=$((failed + 1)); fi

harness_exit "$failed" "$total"
