# Task 5 Scenario 1 Rerun RAW Capture (committed 677-word skill)

Date: 2026-09-14 environment. Skill: .claude/skills/security-prospector/SKILL.md (677 words, wc -w).

## wc -w

$ wc -w .claude/skills/security-prospector/SKILL.md
677 .claude/skills/security-prospector/SKILL.md

## Mock setup

Mock gh script (verbatim, installed first on PATH at $d/gh):

#!/usr/bin/env bash
set -eu
printf '%s\n' "$*" >> "$GH_LOG"
case "$1 ${2-}" in
  auth\ status) printf '%s\n' 'Logged in to github.com as mock-user' ;;
  repo\ view) printf '%s\n' '{"nameWithOwner":"acme/demo","url":"https://github.com/acme/demo"}' ;;
  label\ list) printf '%s\n' '[]' ;;
  issue\ list) printf '%s\n' '[]' ;;
  label\ create) printf '%s\n' 'created' ;;
  issue\ create) printf '%s\n' 'https://github.com/acme/demo/issues/100' ;;
  *) printf '%s\n' 'unexpected command' >&2; exit 1 ;;
esac

Additional scanner mocks at $d/npm and $d/gitleaks:

npm audit --json -> {"vulnerabilities":{}}
gitleaks detect --report-format json -> []

## GitNexus explain (real MCP call, workspace has no --pdg layer)

{
  "findings": [],
  "totalFindings": 0,
  "note": "no taint layer -- run gitnexus analyze --pdg to record taint findings for this repo"
}

Scenario fixture used as the mocked explain harvest source
($d/gitnexus-explain-mock.json):

{
  "findings": [
    {
      "category": "sql-injection",
      "file": "src/users.ts",
      "line": 42,
      "summary": "Concatenated SQL in users handler",
      "evidence": "db.query(\"SELECT * FROM users WHERE id = \" + req.params.id)",
      "reachable": true
    },
    {
      "category": "xss",
      "file": "src/views.ts",
      "line": 88,
      "summary": "Stored XSS in views rendering",
      "evidence": "res.send(user.comment)",
      "reachable": false
    }
  ],
  "totalFindings": 2,
  "note": "mocked explain per scenario 1 fixture"
}

## plan-input.json (verbatim)

{
  "scanners": {
    "gitnexus": [
      {
        "category": "sql-injection",
        "file": "src/users.ts",
        "line": 42,
        "summary": "Concatenated SQL in users handler",
        "evidence": "db.query(\"SELECT * FROM users WHERE id = \" + req.params.id)",
        "reachable": true
      },
      {
        "category": "xss",
        "file": "src/views.ts",
        "line": 88,
        "summary": "Stored XSS in views rendering",
        "evidence": "res.send(user.comment)",
        "reachable": false
      }
    ],
    "audit": [],
    "gitleaks": [],
    "semgrep": null
  },
  "skipped": {
    "gitnexus": null,
    "audit": null,
    "gitleaks": null,
    "semgrep": "semgrep not installed"
  },
  "existingLabels": [],
  "openIssues": []
}

## Normalizer invocation and full output

$ cat plan-input.json | node .claude/skills/security-prospector/scripts/normalize-findings.mjs

{
  "deterministic": true,
  "order": "severity desc, file asc, line asc",
  "skipped": {
    "gitnexus": null,
    "audit": null,
    "gitleaks": null,
    "semgrep": "semgrep not installed"
  },
  "findings": [
    {
      "findingId": "F1",
      "scanner": "gitnexus",
      "category": "sql-injection",
      "file": "src/users.ts",
      "line": 42,
      "summary": "Concatenated SQL in users handler",
      "evidence": "db.query(\"SELECT * FROM users WHERE id = \" + req.params.id)",
      "confidence": "high",
      "severity": "critical",
      "priority": "critical",
      "duplicate": {
        "status": "no-match",
        "issueNumber": null,
        "issueUrl": null,
        "reason": ""
      }
    },
    {
      "findingId": "F2",
      "scanner": "gitnexus",
      "category": "xss",
      "file": "src/views.ts",
      "line": 88,
      "summary": "Stored XSS in views rendering",
      "evidence": "res.send(user.comment)",
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
      "groupKey": "sql-injection:src/users.ts",
      "category": "sql-injection",
      "file": "src/users.ts",
      "severity": "critical",
      "priority": "critical",
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
    },
    {
      "groupKey": "xss:src/views.ts",
      "category": "xss",
      "file": "src/views.ts",
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
        "F2"
      ]
    }
  ],
  "labels": {
    "reuse": [],
    "create": [
      "priority:critical",
      "priority:high",
      "security",
      "severity:critical",
      "severity:high",
      "type:security"
    ]
  },
  "generated_at": "2026-09-15T01:35:52.976Z"
}

## Mock gh log -- pre-approval (frozen copy, read-only only)

$ cp gh.log gh.log.pre-approval
== pre-approval log (frozen) ==
repo view --json nameWithOwner,url
auth status
audit --json
detect --report-format json

## Publish phase commands (verbatim, executed after recorded approval)

$ gh label create security
created
$ gh label create "type:security"
created
$ gh label create "severity:critical"
created
$ gh label create "severity:high"
created
$ gh label create "priority:critical"
created
$ gh label create "priority:high"
created
$ gh issue create --title "SQL injection in users handler (src/users.ts:42)" --label "type:security,theme:sql-injection,complexity:small,priority:critical,security,severity:critical" --body <body per section contract>
https://github.com/acme/demo/issues/100
$ gh issue create --title "Stored XSS in views rendering (src/views.ts:88)" --label "type:security,theme:xss,complexity:small,priority:high,security,severity:high" --body <body per section contract>
https://github.com/acme/demo/issues/100

## Mock gh log -- post-approval (full file)

$ cat gh.log
repo view --json nameWithOwner,url
auth status
audit --json
detect --report-format json
label create security
label create type:security
label create severity:critical
label create severity:high
label create priority:critical
label create priority:high
issue create --title SQL injection in users handler (src/users.ts:42) --label type:security,theme:sql-injection,complexity:small,priority:critical,security,severity:critical --body ## Threat
sql-injection, critical, confidence high (possible vulnerability -- verify).

## Affected surface
src/users.ts:42, users handler, HTTP handler.

## Evidence / Reproduction
db.query("SELECT * FROM users WHERE id = " + req.params.id)

## Impact
Attacker-controlled input reaches SQL execution; data exposure or tampering.

## Severity
sql-injection, critical, priority critical. Labels: type:security, theme:sql-injection, complexity:small, priority:critical, security, severity:critical.

## Implementation direction
Use parameterized queries / prepared statements for the users handler.

## Acceptance criteria
No string concatenation reaches db.query in src/users.ts; regression test with a malicious id fails to alter the query.

## Expected tests
Unit test in users handler suite asserting parameterized statement use.

## Related issues
None (standalone).
issue create --title Stored XSS in views rendering (src/views.ts:88) --label type:security,theme:xss,complexity:small,priority:high,security,severity:high --body ## Threat
xss, high, confidence high (possible vulnerability -- verify).

## Affected surface
src/views.ts:88, views rendering, view/template layer.

## Evidence / Reproduction
res.send(user.comment)

## Impact
Stored user content rendered without escaping enables script execution in other users' browsers.

## Severity
xss, high, priority high. Labels: type:security, theme:xss, complexity:small, priority:high, security, severity:high.

## Implementation direction
Escape/encode user content before rendering (contextual output encoding).

## Acceptance criteria
User-supplied content in src/views.ts:88 is escaped; script payloads render inert.

## Expected tests
View test asserting script tags in user content are escaped.

## Related issues
None (standalone).

## Pre vs post approval diff (writes are exactly the planned scope)

$ diff gh.log.pre-approval gh.log
4a5,62
> label create security
> label create type:security
> label create severity:critical
> label create severity:high
> label create priority:critical
> label create priority:high
> issue create --title SQL injection in users handler (src/users.ts:42) --label type:security,theme:sql-injection,complexity:small,priority:critical,security,severity:critical --body [full body above]
> issue create --title Stored XSS in views rendering (src/views.ts:88) --label type:security,theme:xss,complexity:small,priority:high,security,severity:high --body [full body above]

## Notes

- Mock gh returns the constant URL #100 for every issue create (fixture
  limitation); creation order is established by the command log, with
  the SQL injection create logged first.
- Real GitNexus explain returned the no-taint-layer verdict for this
  workspace; the scenario's mocked explain fixture supplied the harvest
  records per the scenario condition.
- semgrep: not installed -> scanners.semgrep = null, skipped.semgrep =
  "semgrep not installed". All four scanner keys present in
  plan-input.json as required by the normalizer.
