# gh mechanics

This file holds the reasons behind `pr-to-ready`'s `gh` invocations — why a particular command is used over the obvious alternative, and why its result is tested the way it is. The commands themselves, and how each result is tested, stay in `SKILL.md`: a session that never reads this file must still not misread a `gh` result. What is lost by skipping this file is only the understanding of *why* a test is written that way.

Every trap below has the same shape: **a `gh` failure and a genuine negative look identical on stdout.** Auth, network, and repo-context failures print nothing and exit non-zero; an empty result prints nothing and exits 0. Collapsing the two is how a run opens a second PR, drives the wrong one, or reports a reviewer as unavailable when the request was merely never read back.

## Asking whether a PR exists — `gh pr list`, not `gh pr view`

`gh pr view` reads a selector made entirely of digits as a PR *number*, so a branch literally named `123` would resolve PR #123 instead of that branch's own PR. `gh pr list --head` is a literal branch-name filter with no such ambiguity, and it already returns everything the check needs.

The result takes **output and exit status together**. Exit 0 with `[]` is the only thing that means "no PR". A non-zero exit does not mean there is none: the failures above print nothing on stdout and look exactly like absence, and the message wording varies by `gh` version, so neither signal alone can be keyed off. A non-zero exit is "couldn't tell" — and opening a second PR on top of one you couldn't see is worse than stopping.

## Reading the PR number back — `.[]`, never `.[0]`

Print every match and count the lines. Two things go wrong with indexing:

- A branch can carry more than one open PR, since a second PR may target a different base. `.[0]` would pick one of them arbitrarily and hand every later step the wrong `<PR>`.
- On a branch with no PR at all, `.[0]` is `null`, which jq interpolates as text — printing `PR=null draft=null`. That is non-empty output, so it would bind `<PR>` to a string rather than reading as absence.

`.[]` yields nothing for an empty list and one line per match, so the line count answers both questions at once. That is what makes the four outcomes in `SKILL.md` distinguishable from each other.
