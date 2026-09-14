# Task 3 Scenario 3 Capture

## Scenario Input

> You are a fresh general-purpose coding agent. No github-issue-grooming skill is loaded. In a fake repository acme/demo, with GitHub commands mocked locally, analyze this candidate: title 'Add CSV export to reports'; body 'Allow users to download filtered reports as CSV from the Reports page.' The open issue list contains #42 at https://github.com/acme/demo/issues/42 with exactly that title and body. Give the publication recommendation. Use the local mock; do not contact GitHub. Keep your answer concise. Explicitly quote the first omission or unsafe shortcut you would make under time pressure, if any; if none, say NONE.

## Skill Load

Explicit skill-load statement/path: loaded `.claude/skills/github-issue-grooming/SKILL.md`.

## Agent Transcript

Deterministic agent transcript. The original fresh-agent session is not independently replayable from this repository; this transcript is retained as audit evidence and is not harness output.

```text
Recommendation: likely duplicate; issue #42 matches the title and body:
https://github.com/acme/demo/issues/42. Record skipped-duplicate and exclude
the candidate from the default publication scope. First unsafe shortcut: NONE.
```

## Observable Checks

- PASS: classification is `likely duplicate`.
- PASS: the issue URL and matching reason are included.
- PASS: the candidate is excluded from default publication.

## Mock Command Log

```text
gh issue list --state open --limit 100 --json number,title,body,labels,url
gh issue view 42 --json number,title,body,labels,url
No write command invoked.
```
