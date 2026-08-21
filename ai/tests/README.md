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
that byte is the separator the joined form uses, so it can't be told from an
element boundary. Tabs and newlines are fine — the joined argv lives in a file
of its own (`argv.N`) rather than a field of the TSV manifest, because a real
argv spans lines: the `--jq` filter `list-copilot-reviews.sh` passes is one
three-line argument. A malformed index or an exit status outside 0-255 is
rejected too.

## Real git: `ai/tests/lib/gitrepo.sh`

Scripts that shell out to `git` are tested against **real repositories**, not a
git stub: they lean on behaviour a stub would only encode an opinion about —
`FETCH_HEAD` being overwritten by each fetch, `git merge-tree` exiting 1 for a
genuine conflict and an unresolvable ref alike. Source `gitrepo.sh` after
`harness.sh`; everything it builds lives under `$HARNESS_TMP` and is removed
with it.

- `git_repo_bare <owner> <repo>` — a new bare repo at
  `$HARNESS_TMP/remotes/<owner>/<repo>.git`; prints the path. The **path is the
  identity**: `check-pr-state.sh` reduces a remote URL to its last two
  segments, so this repo reads as `<owner>/<repo>` while still being a local
  directory `git fetch` can reach offline.
- `git_repo_scratch <name>` — a fresh empty directory; prints the path.
- `git_repo_init <dir> <initial-branch>` — an empty non-bare repo with `HEAD`
  on that branch.
- `git_repo_commit <dir> <file> <content> <message>` — `<content>` goes
  through `printf '%b'`, so `\n` works.
- `git_repo_checkout <dir> <branch> [<start-point>]` — with a start point it
  creates the branch there.
- `git_repo_remote <dir> <name> <url>` / `git_repo_push <dir> <remote> <refspec>...`

`git_repo_scratch` and `git_repo_bare` refuse a name containing `/` or `..`.
Both clear the directory with `rm -rf` before rebuilding it, and a name is a
single path segment by contract, so `..` would aim that rm at a path the
caller never named. `rm` itself only catches the blunt form: POSIX makes it
refuse an operand whose *last* component is `..`, so `../..` is rejected
loudly while `../../x` deletes a sibling of `$HARNESS_TMP` and exits 0 without
printing anything. The guard is for that silent case.

Sourcing the file cuts the developer's own git configuration out of the
picture (`GIT_CONFIG_GLOBAL=/dev/null`, `GIT_CONFIG_NOSYSTEM=1`,
`GIT_TERMINAL_PROMPT=0`, fixed author/committer identity and timestamps). That
is not only determinism: a personal `url.<base>.insteadOf` can rewrite a local
path into a network URL, which would put this suite on the network through a
setting no test can see.

## Instant `sleep`: `stub_sleep_instant`

Call `stub_sleep_instant` in a test file whose script under test polls. It puts
`ai/tests/lib/bin-nosleep/` first on `PATH` and asserts the resolution;
`sleep_call_count` then reports how many sleeps happened in the current stub
directory, so a bounded poll is asserted by **count** rather than by wall
clock. `check-pr-state.sh`'s `UNKNOWN` re-read alone is 5 × 3 s per row.

It is opt-in, not always on, so it cannot change the meaning of a test file
written expecting real waits. Unlike the fake `gh`, it accepts any argv: the
`gh` rule exists because an unstubbed call would be answered by the network,
and `sleep` hands the caller nothing it reads.

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
4. **The one argv the manifest cannot represent is refused when stubbed**,
   rather than silently never matching: a `\x1f` in a stubbed argv, or a
   malformed call index, fails the helper on the spot — while an argv that
   spans lines *is* stubbable and matches.
5. **The call index counts invocations, not lines**, so an argument that
   spans lines — a GraphQL query passed as `-f query='...'` — does not
   advance the index past the call a later exact-index entry was written for.

## RED verification

To confirm a test actually catches the bug it claims to, point it at the
pre-fix version of the script under test:

```bash
git show <fix>^:<path> >"$tmp/old.sh"
SUT="$tmp/old.sh" ai/tests/run.sh <one-test-file>
```

A script that shells out to a sibling needs that sibling beside the copy:
`watch-copilot-review.sh` finds `list-copilot-reviews.sh` through
`dirname "$0"`, so a pre-fix copy alone in a temp dir cannot find it, every
listing comes back empty, and rows fail for a reason that has nothing to do
with the defect.

```bash
cp ai/skills/pr-to-ready/scripts/list-copilot-reviews.sh "$tmp/"
```

`SUT` names one script under test in place of a test file's default. `run.sh`
refuses to run more than one test file while `SUT` is set, since it names a
single script and pointing a whole suite at it would apply it to every file.

`check-pr-state.sh` → `a548e36^` — the local fallback did not verify that the
working tree's `origin` was the PR's repository (#172).

`watch-claude-review.sh` → `2bd1745^` — `--limit 20` pushed the target run out
of the listing, so the filter printed `[]` and the caller read the review as
never arriving (#173). Also `e14114a^`, where the workflow search was
cwd-relative: from a subdirectory it reported Claude as unavailable.
