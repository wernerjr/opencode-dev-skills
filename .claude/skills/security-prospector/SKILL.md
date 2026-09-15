---
name: security-prospector
description: Scan or verify security issues and register them as GitHub issues via gh.
compatibility: opencode
metadata:
  workflow: security-registration
---

# Security Prospector

Run security scanners, normalize findings deterministically, and register approved issues on GitHub. This skill verifies and registers; it never fixes application code. Read `references/scanners.md`; `scripts/normalize-findings.mjs` governs severity, ordering, dedup, labels.

## 1. Intake (read-only)

Run `gh repo view --json nameWithOwner,url`, then `gh auth status`. On failure, stop and request the missing repository or authentication; never guess, never present local output as published. Probe GitNexus with `explain`; "no taint layer" = skip.

## 2. Scan

Run each scanner; a missing one is a skip with a reason, never "scanned":

1. GitNexus taint -- `explain`; skip "no --pdg layer; run `gitnexus analyze --pdg`".
2. npm/pnpm audit -- `npm audit --json` / `pnpm audit --json`; skip "no lockfile".
3. gitleaks -- `gitleaks detect --report-format json`; skip "gitleaks not installed".
4. semgrep -- `semgrep scan --json`; skip "semgrep not installed".

Skipped = `null` in `scanners`, reason in `skipped`; `[]` = ran, none found. `reachable: true` only on HTTP-handler evidence; `inProduction: true` only for production files. Never pass a raw secret.

## 3. Normalize

Build the input JSON (`scanners` all four keys, `skipped`, `existingLabels`, `openIssues`) and run:

```bash
cat plan-input.json | node .claude/skills/security-prospector/scripts/normalize-findings.mjs
```

Output: `findings` (id, severity, priority, duplicate status), `groups` (clusters, `epic` flags), `labels` (`reuse`/`create`), `skipped`; ordered severity desc, file asc, line asc.

## 4. Deduplicate and cluster

Use the script's `duplicate.status` per group: `duplicate` (do not propose; show URL + reason), `related` (propose new, linked), `no-match` (new). Ambiguous matches are `skipped-ambiguous` -- never confirmed duplicate, never published; show all candidate URLs + the unresolved reason. A group of 3+ findings in one category+file cluster becomes a theme epic (one sub-issue per finding); state dependencies, including epic-before-sub-issue.

## 5. Plan and approval gate

Present, before any write, the deterministic plan: findings with IDs and grouping, epics, sub-issues and standalones, dedup classification with URLs, severity/priority reasoning, label reuse/create vs existing, exact publication scope.

Wait for explicit approval of the current plan. Rejection/revision withdraws prior approval: re-present the revised plan with the same candidate IDs, wait for approval of the exact revised scope. Before approval, commands are read-only; no mutation to probe, prepare, link, or validate. Never publish an item with an unresolved requirement.

## 6. Publish

After approval, in order: create missing labels (reuse existing), create epics, sub-issues and standalones, add references, report URLs.

Group results `created`, `failed`, `failed-reference`, `skipped-duplicate`, `skipped-ambiguous`, `skipped-dependency`; a failed command is never successful. Label/epic failure: mark failed, skip dependents `skipped-dependency` (prerequisite + reason); standalones proceed only if their prerequisites succeeded. Retry identity = ID plus epic, sub-issue, or standalone; retain created numbers, URLs, failed prerequisites. Retry only failed/dependency-skipped items with satisfied prerequisites; never recreate `created` items. Failed reference-add: keep both issues, log source/target/command/error in `failed-reference`, retry only that reference.

## 7. Issue body contract

Sections, in exact order, `## Threat`, `## Affected surface`, `## Evidence / Reproduction`, `## Impact`, `## Severity`, `## Implementation direction`, `## Acceptance criteria`, `## Expected tests`, `## Related issues`; omit only if inapplicable, with a reason.

`Threat`: category, severity, confidence; if exploitation unproven, say "possible vulnerability -- verify". `Affected surface`: `file:line`, function, endpoint/handler, dependency `package@version`. `Evidence / Reproduction`: quoted evidence + command; secret evidence is masked prefix + `file:line` only. `Severity`: repeat category, severity, priority, labels. `Acceptance criteria`: observable, testable. `Related issues`: navigable epic/related/duplicate links. Epics use the same sections (`Threat` = cluster, `Related issues` = sub-issues).

Labels: reuse `type:security`, `theme:*`, `complexity:*`, `priority:*`; add `security` and `severity:<critical|high|medium|low>`; create only missing ones, after approval.

## 8. Handoff

State that fixes run through `dev-orchestrator` -> `dispatch-issue-fix` -> `fix-security-issue` (security) or `fix-code-issue` (other). Do not start fixing code.

## Safety and errors

- Never publish without explicit approval of the exact current plan.
- Never treat ambiguous matches as confirmed duplicates.
- Never assume auth/repo identity.
- Never log or commit secrets; mask evidence.
- Never expand a PoC beyond the fix.
- Stop before publication if unresolved high-impact ambiguity remains.
- Preserve URLs/IDs during partial failure; report honestly.