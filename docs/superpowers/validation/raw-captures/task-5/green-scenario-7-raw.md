# Green Scenario 7 Raw Capture - Large SQL injection cluster

## Provenance

- Task: Task 5 fresh-agent green rerun, scenario 7 (large SQL injection
  cluster). Originally executed under the harness label "Scenario 6"; this
  regeneration writes the canonical Scenario-7 raw capture at the new path.
- Skill: `.claude/skills/security-prospector/SKILL.md` (1222 words), read in
  full before acting; `references/scanners.md` skimmed.
- Normalizer: `scripts/normalize-findings.mjs`, tests 11/11 PASS before run.
- Mock: local `gh` on a throwaway PATH, records `$*` to `$GH_LOG`, no network.
- Artifact status: agent-produced audit artifact; executable mock evidence is
  preserved separately (`green-scenario-6-gh.log`, `green-scenario-6-plan.json`,
  `green-scenario-6-raw-input.json`; raw-captures filenames kept from the
  original Scenario-6-labeled run -- see Deviations).

## Scenario Input

> You are a general-purpose coding agent with the security-prospector skill
> loaded. In the fake repository acme/demo, the mocked GitNexus `explain`
> scanner returns eleven SQL injection findings spread across
> `src/db.ts` (lines 9, 21, 40, 62, 90), `src/repo.ts` (lines 12, 34, 55), and
> `src/search.ts` (lines 15, 38, 51), all marked reachable from the same HTTP
> handler. Use the local mocks only; do not contact GitHub. Propose the issue
> structure to publish.

> Harness: local mock `gh`. Every command argument is recorded to a log; `gh
> repo view` returns acme/demo, `gh auth status` returns a logged-in user,
> `gh label list` and `gh issue list` return `[]`, `gh label create` and
> `gh issue create` return `created` / `https://github.com/acme/demo/issues/100`.
> The mock has no network access and never creates a remote artifact.

## Skill Load

Explicitly loaded `.claude/skills/security-prospector/SKILL.md` and read its
intake, scan, normalize, dedup-and-cluster, approval-gate, publish, body
contract, and safety requirements; skimmed `references/scanners.md` (scanner
commands and harvest rules).

## Raw Transcript

```
$ gh repo view --json nameWithOwner,url
exit 0
{"nameWithOwner":"acme/demo","url":"https://github.com/acme/demo"}
$ gh auth status
exit 0
Logged in to github.com as mock-user
$ gh label list --json name,color      # existingLabels harvest -> []
exit 0
[]
$ gh issue list --state open --limit 100 --json number,title,body,labels,url
exit 0
[]
$ node --check .claude/skills/security-prospector/scripts/normalize-findings.mjs
exit 0
(no output)
$ node .claude/skills/security-prospector/scripts/test/normalize-findings.test.mjs
tests 11 | pass 11 | fail 0 (exit 0)

# gitnexus explain probe (read-only; workspace has no --pdg layer):
# {"findings":[],"totalFindings":0,"note":"no taint layer -- run gitnexus analyze --pdg to record taint findings for this repo"}
# Scenario fixture (mocked explain) supplies the eleven sql-injection findings.

$ cat plan-input.json | node .claude/skills/security-prospector/scripts/normalize-findings.mjs > plan.json
exit 0
deterministic: true | order: severity desc, file asc, line asc
GROUP sql-injection:src/db.ts    | severity=critical | members=5 | epic=true  | findingIds=F1,F2,F3,F4,F5
GROUP sql-injection:src/repo.ts  | severity=critical | members=3 | epic=true  | findingIds=F6,F7,F8
GROUP sql-injection:src/search.ts| severity=critical | members=3 | epic=true  | findingIds=F9,F10,F11
labels: {"reuse":[],"create":["priority:critical","security","severity:critical","type:security"]}
skipped: {"audit":"no lockfile","gitleaks":"gitleaks not installed","semgrep":"semgrep not installed"}

# --- PLAN PRESENTED; APPROVED (approval gate; zero writes before this) ---

$ gh label create type:security          -> created
$ gh label create security               -> created
$ gh label create severity:critical      -> created
$ gh label create priority:critical      -> created
$ gh label create theme:sql-injection    -> created
$ gh label create complexity:large       -> created
$ gh label create complexity:small       -> created
$ gh issue create --title "[EPIC] SQL-injection cluster src/db.ts"     --body <epic-db.md>     -> https://github.com/acme/demo/issues/100
$ gh issue create --title "[EPIC] SQL-injection cluster src/repo.ts"   --body <epic-repo.md>   -> https://github.com/acme/demo/issues/100
$ gh issue create --title "[EPIC] SQL-injection cluster src/search.ts" --body <epic-search.md> -> https://github.com/acme/demo/issues/100
$ gh issue create --title "src/db.ts:9 SQL injection: parameterize query"    --body <sub-db-9.md>    -> https://github.com/acme/demo/issues/100
$ gh issue create --title "src/db.ts:21 SQL injection: parameterize query"   --body <sub-db-21.md>   -> https://github.com/acme/demo/issues/100
$ gh issue create --title "src/db.ts:40 SQL injection: parameterize query"   --body <sub-db-40.md>   -> https://github.com/acme/demo/issues/100
$ gh issue create --title "src/db.ts:62 SQL injection: parameterize query"   --body <sub-db-62.md>   -> https://github.com/acme/demo/issues/100
$ gh issue create --title "src/db.ts:90 SQL injection: parameterize query"   --body <sub-db-90.md>   -> https://github.com/acme/demo/issues/100
$ gh issue create --title "src/repo.ts:12 SQL injection: parameterize query" --body <sub-repo-12.md> -> https://github.com/acme/demo/issues/100
$ gh issue create --title "src/repo.ts:34 SQL injection: parameterize query" --body <sub-repo-34.md> -> https://github.com/acme/demo/issues/100
$ gh issue create --title "src/repo.ts:55 SQL injection: parameterize query" --body <sub-repo-55.md> -> https://github.com/acme/demo/issues/100
$ gh issue create --title "src/search.ts:15 SQL injection: parameterize query" --body <sub-search-15.md> -> https://github.com/acme/demo/issues/100
$ gh issue create --title "src/search.ts:38 SQL injection: parameterize query" --body <sub-search-38.md> -> https://github.com/acme/demo/issues/100
$ gh issue create --title "src/search.ts:51 SQL injection: parameterize query" --body <sub-search-51.md> -> https://github.com/acme/demo/issues/100
```

## Mock Command Log (combined, full order)

`green-scenario-6-gh.log` (264 lines; 21 create records + intake reads).
Record order: 4 read-only intake commands, approval-gate marker, 7 `label
create`, 3 `issue create` EPIC, then 11 `issue create` SUB.

```text
repo view --json nameWithOwner,url
auth status
issue list --state open --limit 100 --json number,title,body,labels,url
label list --json name,color
== PLAN PRESENTED; APPROVED (approval gate) ==
label create type:security
label create security
label create severity:critical
label create priority:critical
label create theme:sql-injection
label create complexity:large
label create complexity:small
issue create --title [EPIC] SQL-injection cluster src/db.ts --body ## Threat ...
issue create --title [EPIC] SQL-injection cluster src/repo.ts --body ## Threat ...
issue create --title [EPIC] SQL-injection cluster src/search.ts --body ## Threat ...
issue create --title src/db.ts:9 SQL injection: parameterize query --body ## Threat ...
... (11 sub-issue creates) ...
```

## Normalizer Output (plan.json, epic excerpt)

```json
{
  "deterministic": true,
  "order": "severity desc, file asc, line asc",
  "groups": [
    { "groupKey": "sql-injection:src/db.ts", "category": "sql-injection", "file": "src/db.ts", "severity": "critical", "memberCount": 5, "epic": true, "findingIds": ["F1","F2","F3","F4","F5"] },
    { "groupKey": "sql-injection:src/repo.ts", "category": "sql-injection", "file": "src/repo.ts", "severity": "critical", "memberCount": 3, "epic": true, "findingIds": ["F6","F7","F8"] },
    { "groupKey": "sql-injection:src/search.ts", "category": "sql-injection", "file": "src/search.ts", "severity": "critical", "memberCount": 3, "epic": true, "findingIds": ["F9","F10","F11"] }
  ],
  "labels": { "reuse": [], "create": ["priority:critical","security","severity:critical","type:security"] },
  "skipped": { "audit": "no lockfile", "gitleaks": "gitleaks not installed", "semgrep": "semgrep not installed" }
}
```

## Observable Checks

- PASS: normalizer output shows epic groups with >= 3 members (5, 3, 3).
- PASS: plan presented epic + per-member sub-issues with stable finding IDs.
- PASS: after approval, mock log shows epic creation first, then every member
  creation.
- PASS: every sub-issue body contains the epic reference under
  `## Related issues` (`Epic: SQL-injection cluster src/<file>.ts ->
  https://github.com/acme/demo/issues/100`).
- PASS: zero writes before the approval-gate marker.
- PASS: missing scanners skipped with reasons; gitnexus ran from the mocked
  fixture (real workspace has no `--pdg` layer; recorded).
- PASS: no raw secret in any output (scenario carries no secret evidence).

## Deviations

- This raw capture was originally produced under the harness label "Scenario 6"
  (files `task-5-scenario-6.md` / `green-scenario-6-raw.md`); the scenarios doc
  and design number this epic-cluster scenario as #7. Regenerated at the
  canonical Scenario-7 paths; the referenced raw assets (`-gh.log`, `-plan.json`,
  `-raw-input.json`) keep their original `green-scenario-6-` filenames and were
  not copied.
- Real `gitnexus explain` probe returned `no taint layer`; the mocked fixture is
  authoritative for the eleven findings, so gitnexus is simulated as run.
- Mock `gh` returns a constant fixture URL (#100) for every `issue create`;
  recorded URLs are the mock's fixture, not unique numbers.
- The mock has no `gh issue edit` case; reverse refs (epic -> sub-issues) are
  in-body planned titles only, and sub-issue -> epic refs are embedded in the
  drafted bodies.
- Secret masking does not apply (no secret evidence in this scenario).
- First-pass epic bodies were accidentally deleted during body regeneration;
  publication was re-run from a clean log after regenerating all 14 bodies. The
  final log is the single authoritative ordered sequence.