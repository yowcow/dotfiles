# Entry point for the checks over ai/: `make lint test` from this directory, or
# `make -C ai lint test` from the repository root. CI runs these same targets,
# so what a person runs by hand and what the gate runs cannot drift apart.
#
# This is deliberately not wired into the repository-root Makefile, which is the
# dotfiles installer: its TARGETS list is what decides where things get
# symlinked, and ai/ itself is never installed as a directory (only
# ai/GUIDELINES.md and the individual skill directories are). Keeping this file
# here leaves that untouched — nothing installs ai/Makefile anywhere.
#
# The logic lives in the scripts, not in these recipes. A recipe carries no
# shebang, so ShellCheck would never check it; ai/tests/lint.sh is a script
# precisely so that it appears in its own selection.

# Anchored at this Makefile's own directory rather than CURDIR, so `make -f
# ai/Makefile` from elsewhere still finds the scripts.
HERE := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

.PHONY: all lint test

all: lint test

# bash -n and ShellCheck over every shell file under ai/, selected by shebang.
lint:
	"$(HERE)tests/lint.sh"

# The offline test suite: every *_test.sh under ai/tests/.
test:
	"$(HERE)tests/run.sh"
