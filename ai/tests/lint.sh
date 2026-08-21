#!/usr/bin/env bash
# bash -n and ShellCheck over every shell file under ai/, selected by shebang.
# Usage: ai/tests/lint.sh
#
# Selection is by shebang, not by a *.sh glob. The fake `gh` at
# ai/tests/lib/bin/gh has to be named `gh` to work as a PATH stub, so it cannot
# carry an extension, and `find -name '*.sh'` drops exactly that one file — the
# ground truth the whole offline suite rests on. ShellCheck reads the shebang
# when handed a path, so an extensionless file is checked normally.
#
# This script is in its own selection: it lives under ai/ and carries a shebang.
# That is the point of it being a script rather than an inline CI step — the
# gate has to cover the code the suite trusts as ground truth, and a workflow's
# `run:` block or a Makefile recipe carries no shebang and so is checked by
# nothing.
#
# The tree is anchored at this script's own location, never the cwd: `make -C ai
# lint` runs with cwd ai/, `ai/tests/lint.sh` from the repository root runs with
# cwd at the root, and a cwd-relative `find ai` would silently find nothing in
# the first case and report success having checked no file.
#
# ShellCheck is spelled with capitals throughout these comments: a comment line
# starting "# shellcheck " parses as a directive, and prose after it is an
# SC1073 error the day anything lints this file.
set -euo pipefail

AI_ROOT="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

# The first line is read with `read`, not `head | grep`: `grep -q` exits on its
# first match, and the resulting SIGPIPE to `head` would fail the pipeline under
# `pipefail`, silently dropping the file.
#
# Only sh and bash are selected, because those are the shells ShellCheck
# supports. A zsh or ksh script added under ai/ later is silently left out of
# the selection — not checked, and not an error either. The printed list below
# is the only signal for that, so it is printed on every run rather than kept
# quiet.
# The listing is built as a plain foreground pipeline into a temp file, not as
# a process substitution feeding the loop directly. In `done < <(find ...)` the
# producer's exit status is unreachable: a `find` that dies partway through the
# tree — an unreadable subdirectory, say — leaves the loop running on whatever
# it managed to emit before failing, the guard below still sees a non-empty
# selection, and the run prints "bash -n: ok" and "shellcheck: ok" having
# checked only part of ai/. Measured: a chmod-000 subdirectory holding one shell
# file produced exactly that false success, exit 0.
#
# `pipefail` is what makes the single `if !` sufficient here — it catches a
# failure in either stage, so neither `find` nor `sort` can fail unnoticed.
LISTING="$(mktemp)"
trap 'rm -f "$LISTING"' EXIT

if ! find "$AI_ROOT" -type f -print0 | sort -z >"$LISTING"; then
  echo "listing ${AI_ROOT} failed — the tree was not fully read" >&2
  exit 1
fi

# Symlinks are deliberately not followed: `-type f` without `-L` classifies a
# symlink by the link, so a shell script symlinked into ai/ is not selected.
# There is none today (`find ai -type l` is empty) and skills are directories of
# real files, while this repository's Makefile symlinks outward into $HOME
# rather than inward. Following them with -L would let the selection escape the
# tree and would turn any dangling link into a hard failure via the check above.
# Recorded as a decision rather than left as an unstated gap, same as the
# zsh/ksh exclusion above.
files=()
while IFS= read -r -d '' f; do
  if [ ! -r "$f" ]; then
    echo "cannot read ${f}" >&2
    exit 1
  fi
  first=''
  IFS= read -r first <"$f" || true
  case "$first" in
    '#!'*bash* | '#!'*[[:space:]/]sh | '#!'*[[:space:]/]sh[[:space:]]*)
      files+=("$f")
      ;;
  esac
done <"$LISTING"

# An empty selection can only mean the matcher itself broke: this script is
# under AI_ROOT and carries a shebang, so a working matcher always selects at
# least this file. Without the guard a typo in the pattern above would report
# success having checked nothing at all — the same "absent" versus "could not
# ask" confusion this whole suite exists to catch. A pattern that breaks only
# partially still slips through; the printed list above is the signal for that.
if [ "${#files[@]}" -eq 0 ]; then
  echo "no shell file found under ${AI_ROOT} — the selection is broken" >&2
  exit 1
fi

printf 'selected %s shell file(s):\n' "${#files[@]}"
printf '  %s\n' "${files[@]}"

for f in "${files[@]}"; do
  bash -n -- "$f"
done
echo "bash -n: ok"

shellcheck --version
shellcheck -- "${files[@]}"
echo "shellcheck: ok"
