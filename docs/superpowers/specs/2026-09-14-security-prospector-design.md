# Security Prospector

## Objective

Create an independent skill that verifies security issues in a project by running multiple scanners, normalizes and deduplicates the findings, and registers them as GitHub issues via `gh` so the existing fix flow (`dev-orchestrator` → `dispatch-issue-fix` → `fix-security-issue`) can execute corrections when the user asks. The skill verifies and registers; it never fixes code.

## Scope

The skill will:

- accept the current repository or a named repository;
- run four scanners, skipping any that are unavailable with an explicit reason;
- normalize every scanner output into a unified finding record;
- cluster findings by vulnerability and group large clusters into epic + sub-issues;
- deduplicate against existing open GitHub issues;
- map severity to priority and assign consistent labels;
- produce a deterministic, reviewable plan for user approval;
- create missing labels and publish approved issues via `gh`;
- report created, failed, and skipped items precisely;
- hand off fixing to the existing security-fix flow.

The skill will not modify application code, publish without user approval, treat an ambiguous duplicate as confirmed, or claim a skipped scanner was run.

## Location and Integration

The skill lives at:

`.claude/skills/security-prospector/SKILL.md`

with `scripts/normalize-findings.mjs` and `references/scanners.md` beside it.

The skill is standalone: it works for the current repo or a named repo, the same way `dev-orchestrator` does.

Integration hook: `dev-orchestrator/SKILL.md` gains a branch that loads `security-prospector` when the user asks to scan or verify security issues, before ranking issues. `dev-orchestrator` is consumed from a `node_modules` cache, so the installed copy is patched for local behavior and the durable change is registered for a pull request in the `wernerjr/opencode-dev-skills` repository.

## Scanner Contract

The scanner phase runs each scanner in sequence. A missing scanner is skipped with an explicit reason and is never reported as "scanned."

1. **GitNexus taint** — `explain` enumerates source→sink findings (sql-injection, command-injection, code-injection, xss, path-traversal). Requires a `--pdg` index; without one the scanner is skipped and the plan suggests `gitnexus analyze --pdg`.
2. **npm/pnpm audit** — `npm audit --json` or `pnpm audit --json`. Requires the corresponding lockfile; otherwise skipped.
3. **gitleaks** — `gitleaks detect --report-format json`. Only when the executable is available.
4. **semgrep** — `semgrep scan --json`, best-effort default rules. Only when the executable is available.

Unified categories (fixed set): `sql-injection`, `command-injection`, `code-injection`, `xss`, `path-traversal`, `secret-leak`, `vulnerable-dependency`, `unsafe-deserialization`, `other`.

## Severity and Priority

Severity is assigned per finding by `normalize-findings.mjs`:

- `critical` — RCE / command-injection / SQL injection reachable from an HTTP handler (evidenced), a secret committed in production, or a dependency with `critical` audit severity.
- `high` — SQL injection / RCE not provably reachable, reflected or stored XSS, a committed secret, or a `high` dependency.
- `medium` — limited path-traversal, `medium` dependency, or unsafe deserialization without proven external input.
- `low` — `low` dependency or hygiene issues without demonstrated impact.

Static taint reaching a `source→sink` path is high-confidence evidence of a flow, not of exploitability. Unless exploitation is proven, the issue body states "possible vulnerability — verify."

Priority derives from severity: `critical→priority:critical`, `high→priority:high`, `medium→priority:medium`, `low→priority:low`.

## Label Policy

Reuse the existing naming conventions:

- `type:security`
- `theme:<subsystem>`
- `complexity:<small|medium|large>`
- `priority:<critical|high|medium|low>`

Add two namespace labels:

- `security`
- `severity:<critical|high|medium|low>`

Missing labels are created only after approval, idempotently. Existing labels are reused and never receive a second `gh label create`.

Inspect the repository's existing labels before finalizing the plan; list each required label as `reuse` or `create`.

## Workflow

### 1. Intake (read-only)

`gh repo view --json nameWithOwner,url` confirms the target repository, then `gh auth status` confirms publishing is possible. If either fails, stop and ask for the missing repository or authentication; never guess and never present local-only output as published.

### 2. Scan

Run each available scanner (Scanner Contract). Collect raw outputs. Skip absent scanners with a reason.

### 3. Normalize

`normalize-findings.mjs` converts every scanner output into unified finding records: `candidateId`, scanner, category, `file:line`, summary, evidence, severity, confidence. The script is the source of truth for deterministic ordering and dedup; the agent does not invent order or grouping.

### 4. Deduplicate and cluster

- Cluster findings by (category, file, entry point) into distinct vulnerabilities.
- Search open issues (`gh issue list --search`) and classify each candidate exactly as `duplicate`, `related`, or `no match`. Ambiguous matches are classified `skipped-ambiguous`: never confirmed as duplicates, never published.
- A cluster large enough to contain multiple independently verifiable tasks becomes an epic with sub-issues, mirroring the grooming skill.

### 5. Plan and approval gate

Present the deterministic plan before any write. It must contain: findings and grouping, epics and rationale, sub-issues and standalone issues, dedup classification, severity/priority reasoning, labels to create or reuse, and the exact publication scope.

Wait for explicit approval of the current plan. A rejection or revision withdraws any earlier approval; show the revised plan with the same candidate IDs and wait for approval of that exact revised scope. Before final approval, every command is read-only. No mutation is allowed to probe, prepare, link, or validate a plan.

### 6. Publish

After approval, in this order:

1. create missing labels;
2. create approved epics;
3. create sub-issues and standalone issues;
4. add GitHub issue references;
5. report URLs.

Track results in separate groups: `created`, `failed`, `failed-reference`, `skipped-duplicate`, `skipped-ambiguous`, `skipped-dependency`. A failed command is never successful. If label creation fails, mark the label failed and skip dependent items as `skipped-dependency`. If an epic fails, skip dependent sub-issues as `skipped-dependency`; independent standalone issues proceed only if their own prerequisites succeeded.

Stable retry identity per candidate and role (epic, sub-issue, standalone). Retry only failed and dependency-skipped items whose prerequisites now succeed; never retry or recreate a `created` item.

### 7. Handoff

The skill ends after publication by stating that fixes are executed through the existing flow: the user picks an issue and `dispatch-issue-fix` routes to `fix-security-issue`. The skill itself never fixes code.

## Issue Body Contract

Fixed section order; omit a section only if genuinely inapplicable, with an explicit reason.

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

- `Threat`: vulnerability description, category, severity, confidence; states "possible vulnerability — verify" when exploitation is not proven.
- `Affected surface`: `file:line`, function, endpoint/handler when identified, dependency version for audit findings.
- `Evidence / Reproduction`: quoted scanner evidence and the exact command run; secrets are masked (only prefix and `file:line`), never logged or committed.
- `Acceptance criteria`: observable and testable, e.g. "the concatenated query in `foo.ts:42` is replaced by a parameterized query; a regression test with payload `' OR 1=1` returns no rows."
- `Related issues`: links to the epic and to related/duplicate issues via navigable GitHub references.
- The body repeats `Category / Severity / Priority / Labels` so the issue is readable without labels.

Epics use the same sections, with `Threat` describing the cluster scope and `Related issues` listing planned sub-issues.

## Secrets and Safety

- Never publish without explicit approval of the exact current plan.
- Never treat an ambiguous match as a confirmed duplicate.
- Never assume authentication or repository identity.
- Never log or commit secrets, `.env` files, keys, or tokens; mask secret evidence.
- Never expand a proof of concept for a still-exploitable production vulnerability beyond what the fix requires.
- Stop before publication if unresolved high-impact ambiguity remains.
- Preserve created URLs and IDs during partial failure.

## Error Handling

- Scanner missing → skip with reason; the final report lists what did not run (e.g., "no `--pdg` layer; run `gitnexus analyze --pdg`").
- Long evidence is trimmed for fixer readability while keeping the issue readable via `gh issue view`.
- Partial publication is reported precisely, with stable IDs and honest per-item status.

## Validation Strategy

Pressure scenarios, with evidence recorded under `docs/superpowers/validation/` and harness checks labeled separately from fresh-agent behavior:

1. repo with SQL injection and XSS → issues created with correct categories, severity, and labels in deterministic order;
2. dedup against existing open issues → duplicate not proposed; related proposed with a link;
3. missing scanners (no lockfile, no gitleaks, no semgrep, no `--pdg` layer) → skipped with reason, never "scanned";
4. unauthenticated `gh` or wrong repo → stops at intake, nothing written;
5. plan rejection or revision → zero writes before approval of the exact revised scope; candidate IDs unchanged;
6. secret in a finding → evidence masked in plan and issue; no raw secret value in output;
7. large cluster → epic + sub-issues with correct dependencies; epic failure → sub-issues `skipped-dependency`;
8. partial publication failure → precise groups; retry does not duplicate.

Expected result: a deterministic, reviewable plan before any write and an accurate publication report after writes.

## Out of Scope for the First Version

- fixing code (belongs to the existing fix flow);
- auto-assigning issues or adding them to GitHub Projects;
- GitHub Security Advisories and private vulnerability reporting;
- writing semgrep rules, CI integration, or scheduled scanning;
- modifying `fix-security-issue` or `fix-code-issue` content;
- semantic embeddings or external similarity services.