# tests/

An offline test suite for the `gh`-wrapping scripts under `ai/skills/*/scripts/`.
The tree lives at the repository root, not inside any skill directory: the
Makefile symlinks each skill directory whole into five agent directories, so a
`tests/` dir inside a skill would get installed everywhere along with it.

## Layout

- `tests/run.sh` — the runner.
- `tests/lib/harness.sh` — sourced by every test file: sets up `PATH`, hands
  out stub directories, runs the script under test, and provides the
  assertion helpers.
- `tests/lib/bin/gh` — the fake `gh`. `harness.sh` puts it first on `PATH`, so
  any script under test that calls `gh` reaches this stub, never the network.
- `tests/lib/harness_test.sh` — a self-test of the harness mechanism itself
  (no script under test).
- `<name>_test.sh` anywhere under `tests/` — the actual test cases.

## Running

- `tests/run.sh` — runs every `tests/**/*_test.sh`, each in its own `bash`
  process so one file's failure can't infect another, and reports how many
  files failed.
- `tests/run.sh <file> [<file> ...]` — runs only the named file(s).

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
exact index wins over `*`. An `<argv>` element containing a tab, a newline, or
`\x1f` is rejected: the manifest is TSV with the joined argv in its last
field, and those bytes can't be represented there. A malformed index or an
exit status outside 0-255 is rejected too.

## The mechanism properties (and why they matter)

`tests/lib/harness_test.sh` proves the properties the rest of the suite
depends on:

1. **An unstubbed argv fails the case** rather than passing through to the
   real `gh`. Without this, a missing stub reads as "the test passed" while
   quietly reaching the network — the exact defect this suite exists to catch.
2. **The stub counts calls globally**, so a poll loop can be scripted to
   answer its second call differently from its first.
3. **Stdout is compared byte-for-byte**, not line-by-line — a stray or
   missing trailing newline is invisible to a line-count comparison.
4. **An argv the manifest cannot represent is refused when stubbed**, rather
   than silently never matching: a tab, a newline or a `\x1f` in a stubbed
   argv, or a malformed call index, fails the helper on the spot.
5. **The call index counts invocations, not lines**, so an argument that
   spans lines — a GraphQL query passed as `-f query='...'` — does not
   advance the index past the call a later exact-index entry was written for.

## RED verification

To confirm a test actually catches the bug it claims to, point it at the
pre-fix version of the script under test:

```bash
git show <fix>^:<path> >"$tmp/old.sh"
SUT="$tmp/old.sh" tests/run.sh <one-test-file>
```

`SUT` names one script under test in place of a test file's default. `run.sh`
refuses to run more than one test file while `SUT` is set, since it names a
single script and pointing a whole suite at it would apply it to every file.
