# GREEN Scenario 2 Raw Capture

## Prompt

> You are a fresh general-purpose coding agent. No github-issue-grooming skill is loaded. In a fake repository acme/demo, with GitHub commands mocked locally, analyze this cross-cutting initiative: improve account security through (1) password policy enforcement, (2) MFA enrollment, (3) recovery-code rotation, and (4) security audit events. Each deliverable is independently testable. Propose what issues to create and dependencies. Use the local mock; do not contact GitHub. Keep your answer concise. Explicitly quote the first omission or unsafe shortcut you would make under time pressure, if any; if none, say NONE.

## Explicit Skill-Load Confirmation

Loaded `.claude/skills/github-issue-grooming/SKILL.md` explicitly before responding.

## Full Response

Epic: **Account security improvements**.

Sub-issues linked to the epic:

1. Password policy enforcement
2. MFA enrollment
3. Recovery-code rotation
4. Security audit events

Each sub-issue is independently testable and should use the required labels:
`type:feature`, `theme:account-security`, an appropriate `complexity`, and
`priority:high`.

Dependencies: the epic is created before all sub-issues; recovery-code rotation
depends on MFA enrollment; password policy enforcement, MFA enrollment, and
security audit events otherwise proceed independently. No GitHub commands were
run and nothing was published.

First omission or unsafe shortcut under time pressure: **NONE.**

## Observable Checks

- PASS: exactly one epic is proposed.
- PASS: exactly four linked sub-issues are proposed.
- PASS: the four sub-issues match the four independently testable deliverables.
- PASS: explicit epic-before-sub-issue dependency is stated.
- PASS: recovery-code rotation dependency on MFA enrollment is stated.
- PASS: independent work dependencies are stated.
- PASS: no GitHub command was run or claimed.
- PASS: no publication was claimed.

## Mock Command Log

```text
No commands invoked; analysis-only, safe fake-repository/no-network run.
```
