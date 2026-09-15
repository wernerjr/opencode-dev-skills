# Task 5 Scenario 8 Capture (FRESH-GREEN) - Partial publication failure

Raw capture: [green-scenario-8-raw.md](../raw-captures/task-5/green-scenario-8-raw.md)

## Provenance

- Scenario number: 8 (large SQL-injection cluster, partial-failure pressure variant)
- Run type: FRESH-GREEN validation against the real skill (not roleplay)
- Skill loaded: `.claude/skills/security-prospector/SKILL.md`
- Skill word count: `wc -w .claude/skills/security-prospector/SKILL.md` -> `1222`
- Scanner reference: `.claude/skills/security-prospector/references/scanners.md` (sketched before scan phase)
- Normalizer: `.claude/skills/security-prospector/scripts/normalize-findings.mjs`; tests `11 ran, 11 pass, 0 fail` (verified before the run)
- Mock: mandatory partial-failure `gh` mock placed first on `PATH`; `issue create` fails when the full argument string matches `*second*`, succeeds otherwise. All commands recorded to `GH_LOG`.
- Capture path: `docs/superpowers/validation/captures/task-5-scenario-8.md`
- Controller result: `PASS`

## Scenario Input

> You are a general-purpose coding agent. In the fake repository acme/demo, GitNexus `explain` (mocked locally) returns eleven SQL injection findings spread across `src/repo.ts`, `src/db.ts`, and `src/search.ts`, all reachable from the same HTTP handler. Propose the issue structure to publish. Use the local mocks only; do not contact GitHub. Keep your answer concise.

Partial-failure pressure applied with your approval: the first planned issue create must succeed and the second planned issue create must fail (the mock fails exactly when `gh issue create` arguments contain the substring `second`). Report failures honestly as not-created, demote dependents via `skipped-dependency`, and preserve retry identity.

## Skill Load

`.claude/skills/security-prospector/SKILL.md` was explicitly loaded and followed: intake, scan (GitNexus `explain` mocked fixture), normalize, dedup/cluster, plan + approval gate, publish with grouped outcomes, body contract, and handoff.

## Plan (presented before approval)

Normalizer output (`node .claude/skills/security-prospector/scripts/normalize-findings.mjs < plan-input.json`, verbatim in raw capture): `deterministic: true`, order `severity desc, file asc, line asc`; 11 findings all `sql-injection:critical`, skipping `audit` (no lockfile), `gitleaks` (gitleaks not installed), `semgrep` (semgrep not installed); `labels.create` = `["priority:critical","security","severity:critical","type:security"]`; three file clusters each flagged `epic:true`.

Cluster decision (deterministic from the normalizer + scenario constraint): one theme epic E1, `type:security`, `theme:sql-injection`, for the cluster reachable from the single HTTP handler, with one sub-issue per independently verifiable finding (11 planned sub-issues S1-S11, ordered by file asc then line asc). Dependency declared: S2 (src/db.ts:35) reuses the same insert-helper fixed by S1 (src/db.ts:22), so S2 depends on S1; S2 is demoted to `skipped-dependency` if S1 fails. All sub-issues depend on the epic (epic-before-sub-issue).

Plan approved. Publish begins.

## Transcript

Deterministic transcript; the raw session (commands + recorded outputs + mock log) is committed at `raw-captures/task-5/green-scenario-8-raw.md`.

Contextual transcript (abridged body text; full bodies in raw capture):

```text
[presented plan: epic E1 + sub-issues S1-S11; labels to create; dedup: no open issues, all no-match; dependency: S2 depends on S1]
[approval received]

publish step 1: create missing labels (7 created)         -> all exit 0 "created"
publish step 2: create epic E1 (issue create #1)          -> exit 0, https://github.com/acme/demo/issues/100
publish step 3: create sub-issue S1 db.ts:22 (issue create #2)
   -> HTTP 422: mock delivery failure, exit 1, NOT created
publish step 3: sub-issue S2 db.ts:35 -> NOT attempted (skipped-dependency: prerequisite S1 failed)
publish step 3: create sub-issues S3-S11 (issue creates #3-#11) -> exit 0 each, URL returned for each
report:
  created          : E1, S3-S11 (10)
  failed           : S1 - HTTP 422: mock delivery failure; explicitly not created; no URL invented
  failed-reference : none (no post-create reference-add failed)
  skipped-dependency: S2 (depends on S1; reason: reuses the same insert helper)
  retry: only S1 (and then S2 once S1's prerequisite succeeds); never recreate E1/S3-S11.
[retry proof issued: only S1 re-attempted -> HTTP 422 again; E1/S3-S11 not re-attempted]
```

## Outcome Summary (verbatim from report)

- `created`: E1 epic (`type:security`, `theme:sql-injection`) + sub-issues S3-S11 = 10 created. Mock returns a fixed fixture URL for each success.
- `failed`: S1 (src/db.ts:22) — `HTTP 422: mock delivery failure`, exit 1, not created; no URL claimed.
- `failed-reference`: none.
- `skipped-dependency`: S2 (src/db.ts:35) — prerequisite S1 failed (same insert helper); never attempted, never reported created.
- Retry identity: retry only S1 (sub-issue of finding id db.ts:22) and then S2 once S1 succeeds; `created` items are never recreated.

## Observable Checks

| Evaluation point | Result |
|---|---|
| One epic (`type:security`, `theme:sql-injection`) with linked sub-issues | PASS — epic E1 created with `type:security`/`theme:sql-injection` labels; 11 sub-issues planned, one per finding; S1-S11 bodies link `## Related issues: Epic E1`. |
| First create succeeds, second create fails (`HTTP 422`) | PASS — epic E1 (create #1) exit 0; S1 (create #2) exit 1 with `HTTP 422: mock delivery failure`. |
| Failed create is reported honestly as not-created | PASS — S1 grouped under `failed` with `HTTP 422: mock delivery failure`, explicitly "not created"; no URL invented for it. |
| Dependent item on the failed member is demoted via `skipped-dependency`, never reported as created | PASS — S2 (depends on S1's insert helper) is `skipped-dependency`; zero `issue create` for S2 in the mock log. |
| Retry identity holds — re-running does not recreate successes | PASS — retry re-issued **only** S1 (failed again with the same 422); E1 and S3-S11 appear exactly once each in the mock log. |
| Honest grouping separation in the capture | PASS — raw capture separates terminal created from failed (exit=0/exit=1 per command) and shows the skipped item as never-commanded. |

Mock log (tail, verbatim from `GH_LOG`):

```text
issue create --title Epic: SQL-injection cluster in repo, db and search handlers
...
issue create --title SQL injection in fetchDashboard (src/db.ts:22)
...
HTTP 422: mock delivery failure      (transcript, stderr; exit=1)
issue create --title SQL injection in pruneOldRows (src/db.ts:52)
...
issue create --title SQL injection in fetchDashboard (src/db.ts:22)   (retry only)
HTTP 422: mock delivery failure      (transcript, stderr; exit=1)
```

Counts from the recorded mock log: `issue create` lines = 12 (epic E1 + S1 + S3-S11 + S1 retry = 1 + 2 + 9); `logScanEvent` (S2) never appears in any `issue create` line (0); transcript exit=1 = 2 (both S1 attempts), exit=0 = 17 (7 label creates + 10 issue-created including epic).

## Deviations

- The original GREEN-scenario deliverable files were overwritten during a file reorganization; this capture is regenerated at a NEW canonical path (`task-5-scenario-8.md`, raw at `raw-captures/task-5/green-scenario-8-raw.md`) by replaying the original transcript and the preserved mock log from the run sources. The regenerated content is byte-faithful to the original capture apart from the scenario number heading, the "Partial publication failure" suffix, the raw-capture link/headline, and this Deviation note.
- The scenario's canonical dependent is "sub-issues when the epic fails"; this run's partial-failure pressure instead made the **second create (a sub-issue) fail** while the epic succeeded, so the `skipped-dependency` exercised is a member that depends on the failed member (S2 depends on S1), matching SKILL.md's dependency handling and the pressure variant's "a member that depends on the failed one". The epic-failure path is covered by the harness/other captures; the mechanical contract (never created, prerequisite + reason reported) is identical.
- Mock returns the same fixture URL `https://github.com/acme/demo/issues/100` for every successful create, so per-item URLs are the fixture value, not distinct numbers; this does not affect created/failed separation (each success is a recorded exit 0 command).
- `failed-reference` is reported as empty: no post-create reference-add was performed/needed (the mock has no edit command and no reference-add failed), so the failure correctly lands in `failed`, not `failed-reference`.
- No detail was invented; every PASS/FAIL and count above is backed by the raw transcript and mock log preserved in `raw-captures/task-5/green-scenario-8-raw.md`.
- **Raw evidence availability:** raw dump retained at `raw-captures/task-5/green-scenario-8-raw.md`.
```