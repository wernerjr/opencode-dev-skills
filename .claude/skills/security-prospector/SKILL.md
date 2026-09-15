---
name: security-prospector
description: Use when the user asks to verify or scan the project for security issues and register them as GitHub issues via gh so the existing fix skills can execute corrections when the user asks.
compatibility: opencode
metadata:
  workflow: security-registration
---

# Security Prospector

Verify security issues in a project by running multiple scanners, normalize the findings deterministically, and register approved issues on GitHub. This skill verifies and registers; it never fixes application code. Fixing is handled by the existing flow: the user picks an issue, `dispatch-issue-fix` routes it, and `fix-security-issue` or `fix-code-issue` executes the correction.

The deterministic normalizer at `scripts/normalize-findings.mjs` is the source of truth for severity, ordering, dedup, and label derivation. Do not invent severity, order, or grouping. Read `references/scanners.md` before running the scan phase.

## 1. Intake (read-only)

Run `gh repo view --json nameWithOwner,url`, then `gh auth status`. If either fails, stop and ask for the missing repository or authentication; never guess the repository and never present local-only output as published.

Check whether GitNexus has a `--pdg` layer by running the `explain` tool once. If the tool answers "no taint layer" (or is unavailable), record it as the reason the GitNexus scanner is skipped.

## 2. Scan

Run each scanner in sequence and collect raw output. A scanner that is not available is skipped with an explicit reason and is never reported as "scanned":

1. **GitNexus taint** -- run `explain` to enumerate source->sink findings. Requires a `--pdg` index; without one record "no --pdg layer; run `gitnexus analyze --pdg`".
2. **npm/pnpm audit** -- `npm audit --json` or `pnpm audit --json`. Requires the corresponding lockfile; otherwise skip with "no lockfile".
3. **gitleaks** -- `gitleaks detect --report-format json`. Only when the executable is available; otherwise skip with "gitleaks not installed".
4. **semgrep** -- `semgrep scan --json` (best-effort default rules). Only when the executable is available; otherwise skip with "semgrep not installed".

For every finding, harvest the fields documented in `references/scanners.md` into the input JSON for the normalizer. For taint findings, set `reachable: true` only when evidence from the execution graph shows the flow enters an HTTP handler (for example via GitNexus process participation). For gitleaks findings, set `inProduction: true` only for production-bearing files (prod config, committed `.env`, deployment secrets). Never pass a raw secret as evidence: gitleaks evidence is always the masked value.

## 3. Normalize

Build the input JSON (`scanners` with all four keys, `skipped`, `existingLabels`, `openIssues`) and run:

```bash
cat plan-input.json | node .claude/skills/security-prospector/scripts/normalize-findings.mjs
```

The script emits `findings` (with `findingId`, severity, priority, duplicate status), `groups` (clusters and `epic` flags), `labels` (`reuse`/`create`), and `skipped`. Treat its ordering as fixed: severity desc, file asc, line asc.

## 4. Deduplicate and cluster

Use the script's `duplicate.status` per group: `duplicate` (do not propose; every duplicate must appear in the plan with URL and reason), `related` (propose as new with a link), `no-match` (new). A match that is partial or ambiguous is classified `skipped-ambiguous`: never confirmed as a duplicate and never published; include it in the plan with all candidate issue URLs and the unresolved reason.

A group flagged `epic` (three or more findings in the same category and file cluster) becomes a theme epic with one sub-issue per finding, mirroring the grooming skill's epic/sub-issue structure. State dependencies, including epic-before-sub-issue.

## 5. Plan and approval gate

Present the deterministic plan before any write. It must contain: findings and grouping with `findingId`s, epics and rationale, sub-issues and standalone issues, dedup classification (`skipped-duplicate`, `skipped-related`, `skipped-ambiguous`) with URLs, severity/priority reasoning, labels to create or reuse (from the script, compared against the repository's existing labels), and the exact publication scope.

Wait for explicit approval of the current plan. A rejection or requested revision withdraws any earlier approval: show the revised plan with the same `findingId`/candidate IDs and wait for approval of that exact revised scope. Before final approval every command is read-only. No mutation is allowed to probe, prepare, link, or validate a plan: no `gh label create`, `gh issue create`, `gh issue edit`, comments, closes, or references. Do not publish any item whose requirement is unresolved.

## 6. Publish

After approval, in this exact order:

1. Create missing labels (`labels.create` from the script, compared against the repository's existing labels; an existing label is reused, never created twice).
2. Create approved epics.
3. Create sub-issues and standalone issues using the body contract below.
4. Add GitHub issue references between epics, sub-issues, and related issues.
5. Report URLs.

Track results in separate groups: `created`, `failed`, `failed-reference`, `skipped-duplicate`, `skipped-ambiguous`, `skipped-dependency`. A failed command is never successful. If missing-label creation fails, mark the label failed and skip every item that requires it as `skipped-dependency`. If an epic fails, mark it failed and skip all dependent sub-issues as `skipped-dependency`; independent standalone issues proceed only if their own prerequisites succeeded. Report the prerequisite and reason for every dependency skip.

Give every candidate and publication item a stable retry identity: its finding/group ID plus `epic`, `sub-issue`, or `standalone`. Retain identities, created issue numbers and URLs, and failed prerequisites in the report. Retry only failed items and dependency-skipped items whose prerequisites now succeed; never retry or recreate a `created` item. If adding a reference fails after both issues were created, keep both in `created`, record source, target, failed command, and error in `failed-reference`, and retry only that reference; never recreate either issue.

## 7. Issue body contract

Each published issue uses these sections in this exact order; omit a section only if genuinely inapplicable, with a stated reason:

```markdown
## Threat
## Affected surface
## Evidence / Reproduction
## Impact
## Severity
## Implementation direction
## Acceptance criteria
## Expected tests
## Related issues
```

- `Threat` -- vulnerability description, category, severity, confidence. Unless exploitation is proven, state "possible vulnerability -- verify" and what verification would require.
- `Affected surface` -- `file:line`, function, endpoint/handler when identified, dependency `package@version` for audit findings.
- `Evidence / Reproduction` -- the quoted scanner evidence and the exact command that produced it. Secret evidence is masked (prefix and `file:line` only); never include a raw secret value.
- `Severity` -- category, severity, priority, and labels as a repeat of the classification so the issue reads without labels.
- `Acceptance criteria` -- observable and testable, e.g. "the concatenated query in `src/users.ts:42` is replaced by a parameterized query; a regression test with payload `' OR 1=1` returns no rows."
- `Related issues` -- links to the epic and to related/duplicate issues via navigable GitHub references.

Epics use the same sections with `Threat` describing the cluster scope and `Related issues` listing the planned sub-issues. Shorten long evidence with the script's trim marker; keep the body readable with `gh issue view`.

## 8. Handoff

After publication, state that fixes are executed through the existing flow: the user picks an issue and `dispatch-issue-fix` routes it to `fix-security-issue` (security) or `fix-code-issue` (other). Do not start fixing code yourself.

## Safety and errors

- Never publish without explicit approval of the exact current plan.
- Never treat an ambiguous match as a confirmed duplicate.
- Never assume authentication or repository identity.
- Never log or commit secrets, `.env` files, keys, or tokens; mask secret evidence.
- Never expand a proof of concept for a still-exploitable production vulnerability beyond what the fix requires.
- Stop before publication if unresolved high-impact ambiguity remains.
- Preserve created URLs and IDs during a partial failure; report partial publication honestly.