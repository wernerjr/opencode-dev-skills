# Green Extra Raw Capture - Ambiguity

date: 2026-09-15, repo: fake acme/demo, harness: local mock gh only (no network)
Regeneration replay of the original GREEN scenario-3 raw capture (original file
overwritten during a file reorganization); same fixture and workflow, replayed
verbatim against a fresh mock gh.

## Actors and fixture

- SKILL loaded: .claude/skills/security-prospector/SKILL.md (1222 words)
- Mock gh (throwaway bin): returns repo view/acme-demo, auth ok, empty label list, one open issue #1
- Open issue #1 (mock fixture, verbatim): number 1, title "SQL in users views", body "user settings table view SQL", url https://github.com/acme/demo/issues/1
- Simulated GitNexus explain output (scenario fixture): one stored XSS finding at src/users.ts:88, summary "Stored XSS in users view", reachable false
- audit skipped (no lockfile); semgrep skipped (not installed); gitleaks ran, no findings; gitnexus index assumed --pdg (explain returned the finding)

## 1. Intake (mock gh, read-only)

```
$ gh repo view --json nameWithOwner,url
{"nameWithOwner":"acme/demo","url":"https://github.com/acme/demo"}
$ gh auth status
Logged in to github.com as mock-user
$ gh label list --json name,color
[]
$ gh issue list --state open --limit 100 --json number,title,body,labels,url
[{"number":1,"title":"SQL in users views","body":"user settings table view SQL","labels":[],"url":"https://github.com/acme/demo/issues/1"}]
```

## 2. Token-level ambiguity analysis (why this is ambiguous, not duplicate)

normalized open-issue hay = "sql in users views user settings table view sql"
normalized finding needle = "stored xss in users view"
xss category terms = {"xss","cross-site","cross site"}; open issue contains no xss term (hasTerm=false)
shared long tokens (>=5 chars, category terms excluded): "users" appears in both -- weak surface term, not a distinct identifier
category of finding=xss vs category suggested by issue=sql-injection : symmetric overlap on surface words only
duplicate rule is hay.includes(needle) OR (hasTerm AND shared); hasTerm=false so shared token cannot confirm duplicate

## 3. plan-input.json (harvested scanner input to the normalizer)

```json
{
  "scanners": {
    "gitnexus": [
      { "category": "xss", "file": "src/users.ts", "line": 88, "summary": "Stored XSS in users view", "evidence": "el.innerHTML = user.bio; // on users view render", "reachable": false }
    ],
    "audit": null,
    "gitleaks": [],
    "semgrep": null
  },
  "skipped": {
    "audit": "no lockfile",
    "semgrep": "semgrep not installed"
  },
  "existingLabels": [],
  "openIssues": [
    { "number": 1, "title": "SQL in users views", "body": "user settings table view SQL", "labels": [], "url": "https://github.com/acme/demo/issues/1" }
  ]
}
```

## 4. Normalize (authoritative pipeline output)

```
$ node .claude/skills/security-prospector/scripts/normalize-findings.mjs < plan-input.json
{
  "deterministic": true,
  "order": "severity desc, file asc, line asc",
  "skipped": {
    "audit": "no lockfile",
    "semgrep": "semgrep not installed"
  },
  "findings": [
    {
      "findingId": "F1",
      "scanner": "gitnexus",
      "category": "xss",
      "file": "src/users.ts",
      "line": 88,
      "summary": "Stored XSS in users view",
      "evidence": "el.innerHTML = user.bio; // on users view render",
      "confidence": "high",
      "severity": "high",
      "priority": "high",
      "duplicate": {
        "status": "no-match",
        "issueNumber": null,
        "issueUrl": null,
        "reason": ""
      }
    }
  ],
  "groups": [
    {
      "groupKey": "xss:src/users.ts",
      "category": "xss",
      "file": "src/users.ts",
      "severity": "high",
      "priority": "high",
      "memberCount": 1,
      "epic": false,
      "duplicate": {
        "status": "no-match",
        "issueNumber": null,
        "issueUrl": null,
        "reason": ""
      },
      "findingIds": [
        "F1"
      ]
    }
  ],
  "labels": {
    "reuse": [],
    "create": [
      "priority:high",
      "security",
      "severity:high",
      "type:security"
    ]
  },
  "generated_at": "2026-09-15T00:39:56.147Z"
}
```

## 5. mock gh command log (post-run, full)

```
$ cat gh.log
repo view --json nameWithOwner,url
auth status
label list --json name,color
issue list --state open --limit 100 --json number,title,body,labels,url
```

tail (last 5) == full log above; grep for `issue create|label create|issue edit`
returns zero matches. Only read commands were ever recorded; no write was
invoked before approval.