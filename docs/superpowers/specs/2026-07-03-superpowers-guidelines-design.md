# Superpowers-First Shared Guidelines Design

## Goal

Rewrite the shared assistant guidelines so day-to-day agent work assumes superpowers usage by default. The same guideline body should work when linked or copied into different assistant entrypoints, without referring to any concrete source path or client-specific destination path.

## Scope

This change updates the shared guideline text only. It does not change installed skills, plugin configuration, shell tooling, or repository automation. Symlink setup for individual assistants is an installation concern and stays outside the shared guideline body.

## Portability Requirement

The guideline body must be path-agnostic and agent-agnostic:

- Do not mention the physical source path of the shared file.
- Do not mention client destination paths such as Claude, Gemini, Antigravity, or Codex config locations.
- Refer to the document as `these shared instructions`, `this guideline file`, or similar neutral wording.
- Keep symlink and bootstrap details in external setup scripts or documentation, not in the shared instruction body.

This avoids confusing an assistant that reads the same content through a symlink at a different path.

## Priority Model

The rewritten guidelines will define this priority order:

1. Explicit user instructions, including shared guideline content and direct turn-level requests.
2. Applicable superpowers skills and their gates, when available in the current environment.
3. General assistant defaults and local engineering preferences.

This keeps the user in control while making superpowers the default way work is planned, executed, debugged, and verified.

## Document Structure

The new shared guidelines will use these sections:

1. `Operating Principle`
   - State that superpowers-first work is mandatory when applicable skills are available.
   - Require checking and using applicable skills before acting.
   - Explain how user instructions, superpowers, and general defaults compose.
   - Avoid naming concrete client config paths.

2. `Communication Style`
   - Preserve the current casual English "bro" style.
   - Preserve Kansai dialect for chat/conversation and Slack posts.
   - Preserve standard Japanese for anything posted to GitHub or committed as documentation.
   - Keep the friendly, direct, emoji-supported tone.

3. `Superpowers-First Workflow`
   - Require `using-superpowers` at conversation start when available.
   - Require `brainstorming` before feature creation, behavior changes, or other creative work.
   - Require `systematic-debugging` before fixing bugs or test failures.
   - Require implementation planning/TDD/execution skills when they apply.
   - Require `verification-before-completion` before claiming work is complete.
   - Require review-related skills for requesting or receiving review.
   - Clarify that skill gates must not be skipped just because the task looks small.

4. `Implementation Discipline`
   - Keep context-first exploration.
   - Follow existing project patterns and keep changes minimal.
   - Avoid unrelated refactors.
   - Test and verify before reporting success.
   - Surface assumptions and residual risks.

5. `Git & PR Workflow`
   - Preserve autonomous commits at logical breakpoints.
   - Preserve the exception that commits to `master`/`main` require explicit permission.
   - Clarify that "no review needed until the PR" means no step-by-step human review is required, not that the agent should skip self-review.
   - Require the agent to self-review diffs before commits and use AI/code-review workflows when useful for non-trivial changes.
   - Preserve no force-push.
   - Preserve draft PR creation with standard Japanese title and body.
   - Preserve standard Japanese for GitHub comments.
   - Preserve cross-repo issue/PR reference qualification.
   - Preserve closing keyword requirements for target issues in PR bodies.

6. `Tool Preferences`
   - Preserve `rg`, `fd`, and `gh` preferences.
   - Preserve MCP preference for Git/GitHub when available.
   - Preserve MFA and GPG passphrase safety rules.

7. `Technical Preferences`
   - Preserve preferred languages, editor, environment, and pragmatic engineering values.

## Behavioral Requirements

- The guidelines must be explicit that superpowers usage is mandatory when an applicable skill is available.
- The guidelines must not weaken current GitHub language/register rules.
- The guidelines must not permit direct commits to `master`/`main` without explicit user permission.
- The guidelines must distinguish human review gates from agent self-review: do not pause for user review at each step, but do perform appropriate self-review and AI-agent review before PR-ready work.
- The guidelines must not imply bypassing MFA, GPG passphrases, sandbox approvals, or other authentication/security gates.
- The rewritten document should remain concise enough to be used as a shared instruction source.
- The rewritten document must not encode symlink targets or filesystem layout assumptions.

## Testing And Verification

Verification is document-focused:

- Read the rewritten shared guidelines end to end.
- Check that all existing policy areas are still represented.
- Check that superpowers-first behavior is clear and does not contradict the existing Git, language, portability, or security rules.
- Check that no concrete source or destination path appears in the shared guideline body.
- Run `git diff --check` before committing.

## Open Decisions

No open product decisions remain. The user selected mandatory superpowers usage and confirmed that shared guideline content should stay path-agnostic.
