# gh mechanics

This file holds the reasons behind `pr-to-ready`'s `gh` invocations — why a particular command is used over the obvious alternative, and why its result is tested the way it is. The commands themselves, and how each result is tested, stay in `SKILL.md`: a session that never reads this file must still not misread a `gh` result. What is lost by skipping this file is only the understanding of *why* a test is written that way.

Every trap below has the same shape: **stdout alone never separates a `gh` failure from a genuine negative.** Auth, network, and repo-context failures print nothing and exit non-zero; a genuine negative exits 0 and prints either nothing or an empty structure such as `[]`, depending on the command. So neither an empty stdout nor a non-empty one settles which you are looking at — only reading it together with the exit status does. Collapsing the two is how a run opens a second PR, drives the wrong one, or reports a reviewer as unavailable when the request was merely never read back.

## Asking whether a PR exists — `gh pr list`, not `gh pr view`

`gh pr view` reads a selector made entirely of digits as a PR *number*, so a branch literally named `123` would resolve PR #123 instead of that branch's own PR. `gh pr list --head` is a literal branch-name filter with no such ambiguity, and it already returns everything the check needs.

The result takes **output and exit status together**. Exit 0 with `[]` is the only thing that means "no PR". A non-zero exit does not mean there is none: the failures above print nothing on stdout and look exactly like absence, and the message wording varies by `gh` version, so neither signal alone can be keyed off. A non-zero exit is "couldn't tell" — and opening a second PR on top of one you couldn't see is worse than stopping.

## Reading the PR number back — `.[]`, never `.[0]`

Print every match and count the lines. Two things go wrong with indexing:

- A branch can carry more than one open PR, since a second PR may target a different base. `.[0]` would pick one of them arbitrarily and hand every later step the wrong `<PR>`.
- On a branch with no PR at all, `.[0]` is `null`, which jq interpolates as text — printing `PR=null draft=null`. That is non-empty output, so it would bind `<PR>` to a string rather than reading as absence.

`.[]` yields nothing for an empty list and one line per match, so the line count answers both questions at once. That is what makes the four outcomes in `SKILL.md` distinguishable from each other.

## Requesting Copilot — the flag and the REST form are alternatives

`gh pr edit --add-reviewer "@copilot"` and the `requested_reviewers` REST endpoint request the same thing two ways. They are alternatives rather than a sequence: running both unconditionally posts a needless request.

**Neither can be judged by its exit status, and they must not be chained with `||`.** The flag can exit 0 and print the PR URL while adding nobody, so a `||` fallback never fires — and the behaviour is intermittent, so one success proves nothing about the next run. The only test that works is reading back who is actually requested after each attempt, and running the REST form only when the flag didn't take.

That readback has to go over REST as well. `gh pr view --json reviewRequests` omits bots and reports none even while Copilot is requested, so it cannot answer the question at all. Copilot counts as unavailable only when it is still absent after the REST form — and failing to *read* the reviewers is not the same as none being requested, which is why that case stops the run instead of reporting unavailable.

## Identifying a bot — match the login, not the timestamp

Bot logins differ across surfaces: Copilot appears both as `Copilot` and as `copilot-pull-request-reviewer[bot]`. Matching a substring of the author login covers the variants. Attributing by timestamp instead misreads a human who happened to comment in the same window as the reviewer.
