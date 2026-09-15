# Task 5 Scenario 7 Capture (FRESH-GREEN) - Large SQL injection cluster

Raw capture: [green-scenario-7-raw.md](../raw-captures/task-5/green-scenario-7-raw.md)
Supporting raw assets: `raw-captures/task-5/green-scenario-7-plan.json`,
`raw-captures/task-5/green-scenario-7-raw-input.json`; the full command log is
embedded in `raw-captures/task-5/green-scenario-7-raw.md` (see Deviations).

## Provenance

- Scenario number: 7 (large SQL injection cluster; the Task 5 harness had
  mislabeled this epic-cluster scenario as "Scenario 6", which in the scenarios
  doc / approved design is "Secret masking"). Regenerated to the canonical
  Scenario-7 numbering at the new paths below.
- Fresh-agent green run: this validation session executed the skill against the
  scenario, not a roleplay.
- Skill path loaded: `.claude/skills/security-prospector/SKILL.md`
  (word count: 1222; verified with `wc -w`).
- Normalizer: `.claude/skills/security-prospector/scripts/normalize-findings.mjs`
  (`node --check` clean; unit tests 11/11 PASS).
- Controller result: `PASS`.
- Artifact status: agent-produced audit artifact; executable mock evidence
  preserved in raw-captures.

## Scenario Input

> You are a general-purpose coding agent with the security-prospector skill
> loaded. In the fake repository acme/demo, the mocked GitNexus `explain`
> scanner returns eleven SQL injection findings spread across
> `src/db.ts` (lines 9, 21, 40, 62, 90), `src/repo.ts` (lines 12, 34, 55), and
> `src/search.ts` (lines 15, 38, 51), all marked reachable from the same HTTP
> handler. Use the local mocks only; do not contact GitHub. Propose the issue
> structure to publish.

> Harness: local mock `gh` on a throwaway PATH. Every command argument is
> recorded to a log; `gh repo view` returns acme/demo, `gh auth status` returns
> a logged-in user, `gh label list` / `gh issue list` return `[]`, `gh label
> create` / `gh issue create` return `created` /
> `https://github.com/acme/demo/issues/100`. The mock has no network access and
> never creates a remote artifact.

## Skill Load

Explicit skill-load statement: loaded `.claude/skills/security-prospector/SKILL.md`
in full (1222 words, verified with `wc -w`) and followed its 8-phase workflow:
intake, scan, normalize, deduplicate-and-cluster, plan-and-approval-gate,
publish, issue-body contract, handoff. Skimmed `references/scanners.md`.

## Transcript

Intake (read-only, mock): `gh repo view` -> acme/demo; `gh auth status` ->
logged in. GitNexus `explain` probe: the real workspace index has no `--pdg`
layer (`no taint layer`); the scenario's mocked `explain` supplies the eleven
sql-injection findings, all `reachable: true`.

Scan: gitnexus (mocked, 11 findings used); npm/pnpm audit skipped
(`no lockfile`); gitleaks skipped (`gitleaks not installed`); semgrep skipped
(`semgrep not installed`).

Normalize: input JSON (4 scanner keys, skipped, existingLabels `[]`, openIssues
`[]`) passed to `normalize-findings.mjs`. Output:

```text
deterministic: true | order: severity desc, file asc, line asc
GROUP sql-injection:src/db.ts    | members=5 | epic=true  | F1,F2,F3,F4,F5
GROUP sql-injection:src/repo.ts  | members=3 | epic=true  | F6,F7,F8
GROUP sql-injection:src/search.ts| members=3 | epic=true  | F9,F10,F11
labels.create: priority:critical, security, severity:critical, type:security
skipped: audit=no lockfile, gitleaks=gitleaks not installed, semgrep=semgrep not installed
```

Cluster: every group exceeded the epic threshold (>= 3 findings in the same
category and file), so each becomes a theme epic (`theme:sql-injection`) with
one sub-issue per member finding (11 sub-issues). Dedup: all `no-match` (no open
issues).

Plan presented (approval gate; no writes yet): 3 epics + 11 sub-issues; severity
critical for every member (reachable SQL injection from an HTTP handler, derived
by the normalizer); labels to create `type:security`, `security`,
`severity:critical`, `priority:critical`, plus `theme:sql-injection`,
`complexity:large` (epics), `complexity:small` (sub-issues). Publication order:
labels, epics, then sub-issues with the epic reference embedded under
`## Related issues`.

Approval: granted in-session. Publication ran exactly that order against the
mock; the resulting `gh` command log records it (see Mock Command Log).

Post-publication: every sub-issue body carries `Epic: SQL-injection cluster
src/<file>.ts -> https://github.com/acme/demo/issues/100` under
`## Related issues`; 3 epic bodies and 11 member bodies each contain the full
9-section body contract.

## Observable Checks

Evaluation points from the scenario (epic/large-cluster), mapped to evidence:

- PASS: plan presents the epic(s) plus a per-vulnerability issue for each
  member. Evidence: plan listed 3 epics with member finding IDs F1-F11 and 11
  sub-issues.
- PASS: after approval, the mock log shows the epic creation and then the member
  creations (epic-first). Evidence: the recorded log order is 7 label creates ->
  3 `[EPIC]` issue creates -> 11 member issue creates.
- PASS: member issue creates carry the epic reference in the drafted body text.
  Evidence: 11/11 sub-issue records contain `Epic: SQL-injection cluster
  src/<their-file>.ts -> https://github.com/acme/demo/issues/100` under
  `## Related issues`.
- PASS: normalizer output shows the epic groups with >= 3 members.
   Evidence: `groups` in `green-scenario-7-plan.json` has memberCount 5, 3, 3,
   all `"epic": true`, `"category":"sql-injection"`.
- PASS: no writes before approval. Evidence: the log's first four records are
  read-only intake; the approval-gate marker precedes the first `label create`.
- PASS: missing scanners skipped with explicit reasons; nothing skipped was
  reported as scanned.
- PASS: no raw secret in any output, plan, or log (scenario carries no secret
  evidence; masking rule not triggered).

Normalizer epic excerpt (verbatim from `green-scenario-7-plan.json`):

```json
{ "groupKey": "sql-injection:src/db.ts", "category": "sql-injection", "file": "src/db.ts", "severity": "critical", "memberCount": 5, "epic": true, "findingIds": ["F1","F2","F3","F4","F5"] },
{ "groupKey": "sql-injection:src/repo.ts", "category": "sql-injection", "file": "src/repo.ts", "severity": "critical", "memberCount": 3, "epic": true, "findingIds": ["F6","F7","F8"] },
{ "groupKey": "sql-injection:src/search.ts", "category": "sql-injection", "file": "src/search.ts", "severity": "critical", "memberCount": 3, "epic": true, "findingIds": ["F9","F10","F11"] }
```

Mock log tail (epic-first creation):

```text
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
issue create --title src/db.ts:9 SQL injection: parameterize query --body ... ## Related issues
Epic: SQL-injection cluster src/db.ts -> https://github.com/acme/demo/issues/100 ...
issue create --title src/db.ts:21 SQL injection: parameterize query --body ...
...
issue create --title src/search.ts:51 SQL injection: parameterize query --body ... Epic: SQL-injection cluster src/search.ts -> https://github.com/acme/demo/issues/100 ...
```

Full command log and normalizer output are preserved verbatim in
`raw-captures/task-5/green-scenario-7-raw.md` and
`raw-captures/task-5/green-scenario-7-plan.json`.

## Deviations

- Wording divergence (flagged for review): the design doc's evaluation point says "One epic"; the skill's grouping rule (category + file) produced three per-file epics in this run. The run is faithful to the skill's rule; the doc's wording diverges and is recorded here.
- Scenario numbering: the Task 5 harness originally called this epic-cluster
  scenario "Scenario 6", while `security-prospector-pressure-scenarios.md` and
  the design doc call it #7 ("Secret masking" is #6 there). This regeneration
  writes the canonical Scenario-7 capture and raw files at the new paths; the
  raw evidence assets were renamed to `green-scenario-7-*` and moved under
  `raw-captures/task-5/` (plan and raw-input survive as standalone files; the
  gh command log is embedded in `green-scenario-7-raw.md`).
- Real `gitnexus explain` probe returned `no taint layer` (workspace has no
  `--pdg` layer); the scenario's mocked `explain` fixture is authoritative for
  the eleven findings, so gitnexus is simulated as run. The real-environment
  skip reason is recorded above in the scan phase.
- The mock `gh` returns one constant fixture URL
  (`https://github.com/acme/demo/issues/100`) for every `issue create`; recorded
  URLs are the mock's fixture and are not unique per issue.
- Reverse references (epic -> sub-issues, skill publish step 4) are represented
  in the epic bodies' `## Related issues` as planned sub-issue titles; the
  mock has no `gh issue edit` case, so the online edit pass was not executed.
  Sub-issue -> epic references are embedded in the drafted bodies, which is the
  evidence the scenario requires.
- Secret masking does not apply: the scenario carries no secret evidence; all
  SQLi evidence consists of non-secret query fragments.
- First-pass bodies for the epics were accidentally deleted during regeneration
  (rewrote the bodies dir between the two drafts); publication was re-run from a
  clean log after regenerating all 14 bodies. The final log contains exactly one
  ordered sequence and is the authoritative evidence.
- **Raw evidence availability:** raw dump retained at `raw-captures/task-5/green-scenario-7-raw.md`, with `raw-captures/task-5/green-scenario-7-plan.json` and `raw-captures/task-5/green-scenario-7-raw-input.json` (epic evidence).
### Post-run compression reconciliation

This run was executed against the pre-compression SKILL.md (wc -w: 1222). The committed text is the human-approved compression (wc -w: 677) which preserves every normative contract (verified by task review: needle checks, harness re-run, and the nine body-section order). The harness still passes against the committed text.
