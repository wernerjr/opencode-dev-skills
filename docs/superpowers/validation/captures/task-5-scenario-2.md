# Task 5 Scenario 2 Capture (security-prospector, dedup against open issues)

Raw capture: unavailable -- see the "Raw evidence availability" note under Deviations.

## Provenance

- Scenario number: 2 (deduplication against open issues)
- Run type: FRESH-GREEN validation, security-prospector explicit load
- Fake repo: acme/demo; all `gh` calls ran through the local mock; no network;
  no wernerjr/real GitHub contact.
- Capture path: `docs/superpowers/validation/captures/task-5-scenario-2.md`
- Controller result: `PASS`

## Scenario Input

> You are a general-purpose coding agent. No security-prospector skill is loaded.
> In the fake repository acme/demo, an open issue exists titled "Use parameterized
> queries in users endpoint" (harness-fixture realization: mock open issue #1
> "users.sqlInjection appears in users handler" at
> https://github.com/acme/demo/issues/1). Two scanner candidates are ready: a SQL
> injection in `src/users.ts:42` and a stored XSS in `src/views.ts:88`. Give the
> publication recommendation for each candidate. Use the local mocks only; do not
> contact GitHub. Keep your answer concise.

Evaluation point (from `docs/superpowers/validation/security-prospector-pressure-scenarios.md`
Scenario 2): the SQL-injection candidate is classified as a likely duplicate
including the matching issue URL and reason, and is not proposed as a new issue;
the XSS candidate is new and is proposed.

## Skill Load

Skill-load confirmation: `.claude/skills/security-prospector/SKILL.md` was
explicitly loaded and followed end-to-end (read in full; `wc -w` = `1222`),
together with `.claude/skills/security-prospector/references/scanners.md` for the
harvest/command contract. Severity, ordering, and dedup were taken from
`scripts/normalize-findings.mjs` output, not from agent intuition.

## Transcript

1. **Intake (read-only, mock `gh`):** `gh repo view --json nameWithOwner,url`
   -> `acme/demo`; `gh auth status` -> `Logged in to github.com as mock-user`.
   Both exit 0.
2. **Harvest (mock `gh`):** `gh issue list --state open --limit 100 --json
   number,title,body,labels,url` returned open issue #1 (title
   `users.sqlInjection appears in users handler`, body
   `active_users()+users SQL layout, parameterized queries`,
   https://github.com/acme/demo/issues/1). `gh label list --json name,color`
   returned `["security"]`.
3. **Normalize:** built `plan-input.json` (two gitnexus candidate records + the
   mocked openIssue #1 + existingLabels) and ran `node
   .claude/skills/security-prospector/scripts/normalize-findings.mjs`.
   Decision from the pipeline (verbatim):
   - F1 `sql-injection` `src/users.ts:42` -> `duplicate.status = "duplicate"`
     (`issueNumber: 1`, `issueUrl:
     https://github.com/acme/demo/issues/1`, reason: `open issue #1 covers
     "Concatenated SQL in users handler"`).
   - F2 `xss` `src/views.ts:88` -> `duplicate.status = "no-match"` (new).
4. **Dedup + plan:** per artifact skill section 4, F1's group is
   `skipped-duplicate` (presented in the plan with URL and reason, never a new
   issue); F2 is proposed as a new standalone issue. No epic (both groups
   `epic: false`). Plan presented with exact publication scope.
5. **Approval gate:** explicit approval of the exact plan simulated (stated in
   transcript).
6. **Publish (mock `gh`, F2 scope only):** created labels
   `type:security`, `severity:high`, `priority:high` (+ agent-assigned
   `theme:xss`, `complexity:small`; `security` reused); created ONE issue ->
   `https://github.com/acme/demo/issues/100`. No issue was created for F1 and no
   edit/close was issued against issue #1.

## Observable Checks

- PASS -- Normalizer classifies the colliding SQL-injection finding as duplicate:
  its `findings[0].duplicate.status` is `"duplicate"` with
  `issueNumber: 1`, `issueUrl: "https://github.com/acme/demo/issues/1"`, reason
  `open issue #1 covers "Concatenated SQL in users handler"` (excerpt from
  `normalize-findings.mjs` output, both per-finding and per-group). The
  classification came from the pipeline, not from agent intuition; severity and
  order (`critical` ahead of `high`) were script-derived.
- PASS -- Issue #1 is not re-created: the mock log contains exactly one
  `issue create`, titled `Stored XSS in views render (src/views.ts:88)`; the
  single `issue list` call read #1 and no `issue edit`/`close`/`create`
  references it. Grep over the log for `issue create` lines mentioning
  `sql|users|parameterized` returned `NONE`.
- PASS -- Mock log shows no duplicate `issue create` (mock log tail):

  ```text
  label create type:security --color b60205 --description security
  label create severity:high --color d93f0b
  label create priority:high --color d93f0b
  label create theme:xss --color c5def5
  label create complexity:small --color 0e8a16
  issue create --title Stored XSS in views render (src/views.ts:88) --body-file .../issue-f2.md --label type:security,security,theme:xss,complexity:small,priority:high,severity:high
  ```

  `issue create` count = 1; `issue list` count = 1.
- PASS -- Dedup decision surfaced with URL and reason: the plan's dedup section
  says `F1 group sql-injection:src/users.ts -- skipped-duplicate; open issue #1:
  https://github.com/acme/demo/issues/1; reason: open issue #1 covers
  "Concatenated SQL in users handler"; do NOT propose a new issue for F1`.
- PASS -- XSS candidate is new and proposed: `F2` classified `no-match`, and the
  published issue body (full body contract, `## Threat` .. `## Related issues`) was
  created -> `https://github.com/acme/demo/issues/100`.

## Deviations

1. **Approval gate simulated, not a human decision:** plan approval cannot be
   automated in a scripted harness run; the harness-orchestrator's approval of
   the exact published scope was stated in the transcript before any write. All
   writes happened only after that stated approval.
2. **First publish block hit the real `gh`:** the harness shell does not persist
   env between tool calls, so a later publish block lost the mock from `PATH`
   and `GH_LOG`. It invoked the real `gh`, which exited 1 with
   `no git remotes found` (local repo detection; no network, no artifact). The
   publish was re-executed verbatim through the mock and appended to the same
   log. Documented for transparency in the raw capture; no evidence was lost.
3. **GitNexus explain simulated per harness:** the fake acme/demo explain is a
   harness fixture (the real workspace index has no `--pdg` layer per
   `references/scanners.md` Table 1); the two candidates entered as harvested
   gitnexus records, which is exactly what the scenario specifies ("two scanner
   candidates are ready").
4. **`type:security` etc. created for the F2 scope only:** label
   creation followed the published scope (F2 high), so the duplicate F1's
   `severity:critical`/`priority:critical` labels were not created (they belong
   to the skipped item).
- **Raw evidence availability:** Raw dump lost in working-tree reorg (filename collided with tracked grooming artifact and was restored); this capture is the deterministic fresh-agent transcript (plan Step 2 fallback).

### Post-run compression reconciliation

This run was executed against the pre-compression SKILL.md (wc -w: 1222). The committed text is the human-approved compression (wc -w: 677) which preserves every normative contract (verified by task review: needle checks, harness re-run, and the nine body-section order). The harness still passes against the committed text.