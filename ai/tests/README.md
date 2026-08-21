# ai/tests/

An offline test suite for the `gh`-wrapping scripts under `ai/skills/*/scripts/`.
The tree sits beside the skills it tests, but **not inside any skill
directory**: the Makefile symlinks each skill directory whole into five agent
directories, so a `tests/` dir inside a skill would get installed into all of
them. `ai/` itself is never installed as a directory — only `ai/GUIDELINES.md`
and the individual skill directories are — so `ai/tests/` reaches none of them.

## Layout

- `ai/tests/run.sh` — the runner.
- `ai/tests/lib/harness.sh` — sourced by every test file: sets up `PATH`, hands
  out stub directories, runs the script under test, and provides the
  assertion helpers.
- `ai/tests/lib/bin/gh` — the fake `gh`. `harness.sh` puts it first on `PATH`,
  so any script under test that calls `gh` reaches this stub, never the network.
- `ai/tests/lib/harness_test.sh` — a self-test of the harness mechanism itself
  (no script under test).
- `<name>_test.sh` anywhere under `ai/tests/` — the actual test cases.

## Running

- `ai/tests/run.sh` — runs every `*_test.sh` under `ai/tests/`, each in its own
  `bash` process so one file's failure can't infect another, and reports how
  many files failed. Discovery uses `find`, not bash 4's `globstar`, because the
  scripts under test are kept running on bash 3.2 and a degraded `**` would
  silently match only one nesting depth.
- `ai/tests/run.sh <file> [<file> ...]` — runs only the named file(s).

## Writing a table-test case

Each row typically does:

1. `stub_dir_new` — fresh stub directory; resets the call counter and manifest.
2. One or more `gh_stub_response <index|*> <exit-status> <argv...>` calls
   (body on stdin) to script what `gh` should answer.
3. `run_sut <cmd...>` — runs the script under test with stdin `/dev/null`,
   capturing stdout/stderr to `$SUT_STDOUT`/`$SUT_STDERR` and status to
   `$SUT_STATUS`.
4. Assertions: `check_eq`, `check_bytes`, `check_no_violations`, plus a check
   on `$SUT_STATUS`.

## The `gh_stub_response` contract

`gh_stub_response <index> <exit-status> <argv...>` (body from stdin). `<index>`
is a positive integer — the global call number within the stub dir that this
entry answers — or `*`, meaning "any call not otherwise matched exactly." An
exact index wins over `*`. An `<argv>` element containing `\x1f` is rejected:
that byte joins the elements, so `["a\x1fb"]` and `["a","b"]` would be
indistinguishable and one case's body would be served to the other. Tabs and
newlines are fine — the joined argv is written to its own file beside the
body, so a multi-line argv (the GraphQL query `list-unresolved-threads.sh`
passes as `-f query='...'` spans 23 lines) is matched on its exact bytes. A
malformed index or an exit status outside 0-255 is rejected too.

For an argv carrying `--paginate`, successive indices are the **pages of one
invocation**: gh pages internally, so a script that calls it once still sees
every page's output concatenated. The stub stops at the first of — no entry for
the next index (the scripted pages ran out, which is how a real run ends), a
non-zero status (it exits with that status, the pages already served still on
stdout), or an entry matched via `*` (which matches every index and would
repeat forever, so it answers one page). `gh_call_count` therefore counts
responses served: invocations for an ordinary call, pages for a paginated one.

## The mechanism properties (and why they matter)

`ai/tests/lib/harness_test.sh` proves the properties the rest of the suite
depends on:

1. **An unstubbed argv fails the case** rather than passing through to the
   real `gh`. Without this, a missing stub reads as "the test passed" while
   quietly reaching the network — the exact defect this suite exists to catch.
2. **The stub counts calls globally**, so a poll loop can be scripted to
   answer its second call differently from its first.
3. **Stdout is compared byte-for-byte**, not line-by-line — a stray or
   missing trailing newline is invisible to a line-count comparison.
4. **An argv the manifest cannot disambiguate is refused when stubbed**,
   rather than silently never matching: an `\x1f` in a stubbed argv, a
   malformed call index, or an out-of-range exit status fails the helper on
   the spot.
5. **The call index counts invocations, not lines**, so an argument that
   spans lines — a GraphQL query passed as `-f query='...'` — does not
   advance the index past the call a later exact-index entry was written for.
6. **An argv spanning lines is stubbable and matches only itself** — the
   23-line GraphQL query is why, and a near-miss query must still be reported
   as an unstubbed argv rather than served this case's body.
7. **`--jq` is applied to a successful body and never to a failing one** —
   what real `gh` does (measured). Fixtures are therefore raw API bodies and
   the filter in the script under test really runs; an error fixture reaches
   stdout whole, as a caller would see it.
8. **One `--paginate` invocation serves a page sequence, truncating at a
   failing page** — "page 1 arrived, page 2 failed" is the state in which
   stdout is non-empty and the listing is incomplete, and a caller keying on
   emptiness alone cannot tell it from success.

## RED verification

To confirm a test actually catches the bug it claims to, point it at the
pre-fix version of the script under test:

```bash
git show <fix>^:<path> >"$tmp/old.sh"
SUT="$tmp/old.sh" ai/tests/run.sh <one-test-file>
```

`SUT` names one script under test in place of a test file's default. `run.sh`
refuses to run more than one test file while `SUT` is set, since it names a
single script and pointing a whole suite at it would apply it to every file.
