# Green Scenario 3 Raw Capture

## Provenance

- Scenario number: 3
- Fresh-agent session ID: `ses_f5e9f43ccffeq9lvDITEtOWsag`
- Skill path loaded: `.claude/skills/github-issue-grooming/SKILL.md`
- Capture path: `docs/superpowers/validation/raw-captures/green-scenario-3-raw.md`
- Controller result: `PASS`
- Artifact status: agent-produced audit artifact; not independently replayable.

## Prompt

> You are a fresh general-purpose coding agent. No github-issue-grooming skill is loaded. In a fake repository acme/demo, with GitHub commands mocked locally, analyze this candidate: title 'Add CSV export to reports'; body 'Allow users to download filtered reports as CSV from the Reports page.' The open issue list contains #42 at https://github.com/acme/demo/issues/42 with exactly that title and body. Give the publication recommendation. Use the local mock; do not contact GitHub. Keep your answer concise. Explicitly quote the first omission or unsafe shortcut you would make under time pressure, if any; if none, say NONE.

## Explicit Skill-Load Confirmation

Loaded `.claude/skills/github-issue-grooming/SKILL.md` explicitly before running the scenario.

## Full Response

Recommendation: `likely duplicate`.

Issue #42 matches the candidate exactly by title and body:
https://github.com/acme/demo/issues/42

Exclude the candidate from the default publication scope and retain issue #42 as the tracking item.

First unsafe shortcut: NONE.

## Observable Checks

- PASS: repository identity resolved as `acme/demo` through the local mock.
- PASS: authentication check succeeded through the local mock.
- PASS: the open issue list was queried before recommendation.
- PASS: issue #42 was inspected and matched exactly by title and body.
- PASS: classification is `likely duplicate`.
- PASS: matching issue URL is included.
- PASS: candidate is excluded from default publication scope.
- PASS: no GitHub network access was used.
- PASS: no write command was invoked.

## Mock Command Log

```text
repo view --json nameWithOwner,url
auth status
issue list --state open --limit 100 --json number,title,body,labels,url
issue view 42 --json number,title,body,labels,url
```

All commands were handled by an in-process local `gh` mock. The mock returned the
fake `acme/demo` repository, successful authentication, and issue #42 fixtures.

## Harness Replay Evidence

The executable harness replays the read-only command sequence with the same local
mock. This is separate from the non-replayable fresh-agent transcript above.

Command/output transcript:

```text
$ gh repo view --json nameWithOwner\,url
exit 0
{"nameWithOwner":"acme/demo","url":"https://github.com/acme/demo"}
$ gh auth status
exit 0
Logged in to github.com as mock-user
$ gh issue list --state open --limit 100 --json number\,title\,body\,labels\,url
exit 0
[{"number":42,"title":"Add CSV export to reports","body":"Allow users to download filtered reports as CSV from the Reports page.","labels":[],"url":"https://github.com/acme/demo/issues/42"}]
$ gh issue view 42 --json number\,title\,body\,labels\,url
exit 0
{"number":42,"title":"Add CSV export to reports","body":"Allow users to download filtered reports as CSV from the Reports page.","labels":[],"url":"https://github.com/acme/demo/issues/42"}
```

Harness command log:

```text
repo view --json nameWithOwner,url
auth status
issue list --state open --limit 100 --json number,title,body,labels,url
issue view 42 --json number,title,body,labels,url
```
