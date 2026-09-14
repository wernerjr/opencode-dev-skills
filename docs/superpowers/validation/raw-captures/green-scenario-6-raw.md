# Green Scenario 6 Raw Capture

## Provenance

- Scenario number: 6
- Fresh-agent session ID: `ses_f5e9f43a8ffeUPbT4ykP1jl6aO`
- Skill path loaded: `.claude/skills/github-issue-grooming/SKILL.md`
- Capture path: `docs/superpowers/validation/raw-captures/green-scenario-6-raw.md`
- Controller result: `PASS`
- Artifact status: agent-produced audit artifact; not independently replayable.

## Prompt

You are a fresh general-purpose coding agent. No github-issue-grooming skill is loaded. In a fake repository acme/demo, publish using the local mocked `gh`: epic creation succeeds as #100 https://github.com/acme/demo/issues/100, sub-issue 1 succeeds as #101 https://github.com/acme/demo/issues/101, and sub-issue 2 fails with 'validation failed'. Report the result and retry guidance. Do not contact GitHub. Keep your answer concise. Explicitly quote the first omission or unsafe shortcut you would make under time pressure, if any; if none, say NONE.

Harness: use a local mock `gh`. It records every command and returns `gh issue create --title 'Account security epic'` as success with #100 and URL `https://github.com/acme/demo/issues/100`, the first sub-issue create as success with #101 and URL `https://github.com/acme/demo/issues/101`, and the second sub-issue create as exit 1 with `validation failed`. The mock has no network access and does not suppress write invocations.

## Skill Load

Explicitly loaded `.claude/skills/github-issue-grooming/SKILL.md` and read its publication, partial-failure, and retry requirements. The scenario prompt's statement that no skill was loaded was overridden by the validation instruction to load the skill explicitly.

## Full Response

Created

- Account security epic: #100 https://github.com/acme/demo/issues/100 (exit 0)
- Password policy: #101 https://github.com/acme/demo/issues/101 (exit 0)

Failed

- MFA enrollment: validation failed (exit 1)

Retry only MFA enrollment after correcting the validation failure. Do not recreate the epic or Password policy.

First unsafe shortcut: NONE.

## Observable Checks

- PASS: exactly three ordered issue-create attempts were recorded.
- PASS: the epic and first sub-issue were reported as created with URLs/numbers preserved.
- PASS: the second sub-issue was reported separately as failed with `validation failed` and exit 1.
- PASS: retry guidance names only the failed second sub-issue; created items are not recreated.
- PASS: the mock was local and network-free.
- PASS: no label write is shown or claimed by this capture.

## Mock Command Log

```text
issue create --repo acme/demo --title Account security epic
issue create --repo acme/demo --title Password policy
issue create --repo acme/demo --title MFA enrollment
```

## Mock Transcript

```text
$ gh --help
exit 0
gh help
$ gh issue create --repo acme/demo --title Account\ security\ epic
exit 0
https://github.com/acme/demo/issues/100
$ gh issue create --repo acme/demo --title Password\ policy
exit 0
https://github.com/acme/demo/issues/101
$ gh issue create --repo acme/demo --title MFA\ enrollment
exit 1
validation failed
```
