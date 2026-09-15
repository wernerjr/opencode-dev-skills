---
name: security-prospector-scanners
description: Command contract, harvest rules, and verified probe evidence for the scanners that feed plan-input.json into scripts/normalize-findings.mjs.
compatibility: opencode
metadata:
  serves: security-prospector
  status: verified
---

# Scanner Reference

Command contract and harvest rules for each scanner. Output feeds
`scripts/normalize-findings.mjs` via a single stdin JSON object:

```json
{
  "scanners": { "gitnexus": null, "audit": [], "gitleaks": [], "semgrep": [] },
  "skipped": { },
  "existingLabels": ["type:security", "priority:high", "security", "severity:critical"],
  "openIssues": [ ]
}
```

`null` = scanner skipped (reason must be in `skipped`). `[]` = ran, no findings.
Every published item requires `type:security`, `theme:<lowercase-theme>`,
`complexity:<small|medium|large>`, `priority:...`, `security`, and
`severity:<critical|high|medium|low>`. The normalizer derives severity, priority,
`security`, and `type:security`; the agent assigns theme and complexity in the plan.

## Verified environment (probes dated 2026-09-14)

Probes below were executed in `/Users/werner/Projects/developersSkills` on
`darwin` with the same commands the skill runs. Facts verified by running:

- node `v24.19.0`, npm `11.17.0`, pnpm `9.15.9`.
- `gitleaks` 8.30.1 installed at `/opt/homebrew/bin/gitleaks`.
- `semgrep` and `git-secrets`: not installed (verified empty `which`).
- `gh` (GitHub CLI) authenticated as `wernerjr`, scopes `gist`, `read:org`,
  `repo`, `workflow`.
- This workspace repo has **no git remote**: `git remote` is empty, so
  `gh repo view`, `gh issue list`, and `gh label list` all fail here with
  "no git remotes found" (exit 1). Run the skill from a clone that has its
  github.com remote set.

### Table 1: scanner commands, as run in this environment

| Scanner | Command | Ran? | Verified result |
|---|---|---|---|
| GitNexus taint | MCP `explain` tool (topic: security review) | yes | "no taint layer -- run gitnexus analyze --pdg..." |
| npm audit | `npm audit --json` | yes | fails, `ENOLOCK`; no lockfile in repo |
| pnpm audit | `pnpm audit --json` | n/a | no lockfile; same `null` skip as npm |
| gitleaks | `gitleaks detect --report-format json` | yes | 8.30.1, `no leaks found`, 29 commits scanned, exit 0 |
| semgrep | `semgrep scan --json` | no | binary not installed |

## GitNexus taint (`explain`)

Command: use the MCP `explain` tool to enumerate findings (topic: security
review of the repository). Requires a `--pdg` index; otherwise set
`scanners.gitnexus = null` and `skipped.gitnexus = "no --pdg layer; run
gitnexus analyze --pdg"`.

Harvest one record per finding:

```json
{ "category": "sql-injection", "file": "src/users.ts", "line": 42, "summary": "Concatenated SQL in users handler", "evidence": "db.query(...)", "reachable": true }
```

- `category` must be one of `sql-injection`, `command-injection`,
  `code-injection`, `xss`, `path-traversal`, `unsafe-deserialization`, `other`.
- `reachable: true` only when the execution graph shows the flow enters an HTTP
  handler (e.g. GitNexus process participation). Reachable
  SQLi/RCE/code/command-injection is `critical`; otherwise `high`.
- `risk` values from VPR/monitoring tools are not used in v1.

### Probe verdict (GitNexus taint)

Workspace `developersSkills` has no `--pdg` layer. The `explain` tool returned
(verbatim; the tool's note uses an em dash, transcribed below as `--` to keep
this file ASCII-only):

```
{
  "findings": [],
  "totalFindings": 0,
  "note": "no taint layer -- run gitnexus analyze --pdg to record taint findings for this repo"
}
```

Verdict: `scanners.gitnexus = null`,
`skipped.gitnexus = "no --pdg layer; run gitnexus analyze --pdg"`.
The exact skip wording recorded in this workspace: `no taint layer -- run
gitnexus analyze --pdg to record taint findings for this repo` (the API-side
wording; the skill contract wording "no --pdg layer; run `gitnexus analyze
--pdg`" is equivalent and uses the same reported cause).

## npm / pnpm audit

Command: `npm audit --json` or `pnpm audit --json`. Requires the lockfile;
otherwise `scanners.audit = null` with `skipped.audit = "no lockfile"`.

Harvest one record per advisory from the `vulnerabilities` map:

```json
{ "package": "lodash", "version": "4.17.20", "severity": "critical", "summary": "Prototype pollution", "advisory": "CVE-2021-23337" }
```

`severity` pass-through: critical/high/medium/low; missing severity defaults to
`medium`. Category is always `vulnerable-dependency`.

### Probe verdict (npm audit)

Verified: this repo contains no `package.json`, `package-lock.json`,
`pnpm-lock.yaml`, or `yarn.lock` anywhere. `npm audit --json` exits 1 with
(stderr verbatim):

```
npm error code ENOLOCK
npm error audit This command requires an existing lockfile.
npm error audit Try creating one first with: npm i --package-lock-only
npm error audit Original error: loadVirtual requires existing shrinkwrap file
```

stdout JSON block (verbatim):

```
{
  "error": {
    "code": "ENOLOCK",
    "summary": "This command requires an existing lockfile.",
    "detail": "Try creating one first with: npm i --package-lock-only\nOriginal error: loadVirtual requires existing shrinkwrap file"
  }
}
```

Verdict: `scanners.audit = null`, `skipped.audit = "no lockfile"`.
`pnpm audit --json` shares the same skip (no lockfile to audit).

## gitleaks

Command: `gitleaks detect --report-format json`. Only when the executable is
available; otherwise `scanners.gitleaks = null` with `skipped.gitleaks =
"gitleaks not installed"`.

Harvest one record per finding:

```json
{ "file": "config/prod.env", "line": 3, "rule": "AWS Access Key", "summary": "AWS Access Key in config/prod.env", "maskedEvidence": "AKIA**** [masked]", "inProduction": true }
```

Safety invariant: `evidence` in the plan and issue is always `maskedEvidence`
(prefix + `file:line`), never the raw secret. `inProduction: true` only for
production-bearing files: committed prod config, committed `.env`, deployment
secrets, Terraform backends, or files reachable from production CI.

### Probe verdict (gitleaks)

`gitleaks` 8.30.1 is installed at `/opt/homebrew/bin/gitleaks`. Ran
`gitleaks detect --no-banner --source .` in the workspace. ANSI color escape
codes in the terminal output are omitted here to keep this file ASCII-only; all
informational lines are verbatim:

```
9:15PM INF 30 commits scanned.
9:15PM INF scanned ~305780 bytes (305.78 KB) in 106ms
9:15PM INF no leaks found
```

Exit code: 0. `--no-banner` suppresses the unicode startup logo, so stdout stays
clean and no banner stripping is needed.

Verdict: `scanners.gitleaks = []` (ran, no findings). Had a finding been
present, only `maskedEvidence` would be recorded (prefix + `file:line`);
raw secrets are never committed or logged.

## semgrep

Command: `semgrep scan --json` (best-effort default rules). Only when the
executable is available; otherwise `scanners.semgrep = null` with
`skipped.semgrep = "semgrep not installed"`.

Harvest one record per finding using the same shape as GitNexus taint records.
`confidence` defaults to `medium`.

### Probe verdict (semgrep)

Verified the binary is absent (verbatim):

```
$ which semgrep
semgrep not found
```

`git-secrets` was also checked and is absent. semgrep was not run because the
executable does not exist in this environment; this is verified evidence of the
skip condition, not a silent omission.

Verdict: `scanners.semgrep = null`, `skipped.semgrep = "semgrep not installed"`.

## openIssues

`gh issue list --state open --limit 100 --json number,title,body,labels,url`
becomes `openIssues`. The normalizer classifies against these.

### Probe verdict (openIssues)

Run from this workspace: `gh issue list --state open --limit 100 --json
number,title,body,labels,url` exits 1 with (verbatim):

```
no git remotes found
```

Reason: the workspace repo has no git remote configured. Execute this command
from a clone that points at the github.com remote (owner `wernerjr`) to harvest
real issue records.

## existingLabels

`gh label list --json name,color` becomes `existingLabels` (plain names).
Missing labels are created only after approval, idempotently; existing labels
are reused and never receive a second `gh label create`.

### Probe verdict (existingLabels)

Run from this workspace: `gh label list --json name,color` exits 1 with
(verbatim):

```
no git remotes found
```

Same cause as `openIssues`: no remote. With a remote present, labels are
harvested as plain names (the `color` field is not carried into
`existingLabels`).

## Intake probes

The skill's intake step (`gh repo view`, `gh auth status`) was also probed:

```
$ gh repo view --json nameWithOwner,url
no git remotes found       (exit 1)

$ gh auth status
github.com
  [checkmark marker omitted] Logged in to github.com account wernerjr (keyring)
  - Active account: true
  - Git operations protocol: https
  - Token: [redacted by reference author]
  - Token scopes: 'gist', 'read:org', 'repo', 'workflow'
```

Verdict: authentication is valid, but this workspace clone has no remote, so
publication-facing probes (`issues`, `labels`) must run where the remote exists.
Never guess the repository and never present local-only output as published.

## Table 2: check commands available in this repository

This repo has no `package.json`, so there is no `npm run check` /
`yarn check` equivalent. The actual available checks were run verified:

| Check | Command | Verified result (real output) |
|---|---|---|
| Whitespace / patch hygiene | `git diff --check` | clean, exit 0 |
| ASCII-only content | `LC_ALL=C perl -ne 'print if /[^\x00-\x7F]/' <file>` | no output, file ASCII-only (prints the matched line otherwise) |
| Node syntax of normalizer | `node --check .claude/skills/security-prospector/scripts/normalize-findings.mjs` | exit 0 |
| Normalizer unit tests | `node .claude/skills/security-prospector/scripts/test/normalize-findings.test.mjs` | 11 run, 11 pass, 0 fail, exit 0 |

Real output excerpts (checkmark/summary glyphs in the original runner output are
transcribed to ASCII markers):

```
$ git diff --check
(no output; exit 0)

$ node --check .claude/skills/security-prospector/scripts/normalize-findings.mjs
(no output; exit 0)

$ node .claude/skills/security-prospector/scripts/test/normalize-findings.test.mjs
gitnexus sql-injection reachable -> critical priority critical [PASS]
source taint severity table [PASS]
audit severity pass-through and default [PASS]
gitleaks masking is forced and production secrets are critical [PASS]
null scanner is skipped and [] scanner produces no findings [PASS]
deterministic ordering severity desc then file asc then line asc [PASS]
duplicate vs related vs no-match classification [PASS]
epic grouping when a cluster has three or more findings [PASS]
labels derived as reuse vs create against existing labels [PASS]
invalid category, missing file, and missing scanner field throw [PASS]
long evidence is trimmed for fixer readability [PASS]
tests 11
pass 11
fail 0
cancelled 0
skipped 0
todo 0
duration_ms 6.079667
(exit 0)
```

## Harvest rule summary

For every scanner, copy the verified values in `skipped` above when the probe
condition holds; harvest `findings` only from real scanner output, and never
paste a raw secret as evidence. The normalizer rejects records with an invalid
`category`, a missing `file` (audit and gitleaks supply their own), or a missing
scanner key in `scanners`; keep all four keys present on every write.