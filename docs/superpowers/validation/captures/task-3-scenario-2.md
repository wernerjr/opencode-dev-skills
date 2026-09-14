# Task 3 Scenario 2 Capture

## Scenario Input

> You are a fresh general-purpose coding agent. No github-issue-grooming skill is loaded. In a fake repository acme/demo, with GitHub commands mocked locally, analyze this cross-cutting initiative: improve account security through (1) password policy enforcement, (2) MFA enrollment, (3) recovery-code rotation, and (4) security audit events. Each deliverable is independently testable. Propose what issues to create and dependencies. Use the local mock; do not contact GitHub. Keep your answer concise. Explicitly quote the first omission or unsafe shortcut you would make under time pressure, if any; if none, say NONE.

## Skill Load

Explicit skill-load statement/path: loaded `.claude/skills/github-issue-grooming/SKILL.md`.

## Agent Transcript

Deterministic agent transcript. The original fresh-agent session is not independently replayable from this repository; this transcript is retained as audit evidence and is not harness output.

```text
Epic: Account security improvements.
Sub-issues: password policy enforcement, MFA enrollment, recovery-code rotation,
and security audit events. Each is independently testable and linked to the epic.
Dependencies: epic-before-all; recovery-code rotation depends on MFA enrollment;
the other sub-issues can proceed independently. No GitHub commands were run.
```

## Observable Checks

- PASS: exactly one epic is proposed.
- PASS: exactly four linked sub-issues match the four deliverables.
- PASS: explicit dependencies are stated.
- PASS: no GitHub write is claimed.

## Mock Command Log

```text
No write command invoked; analysis-only transcript.
```
