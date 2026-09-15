# Security Prospector Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `security-prospector` skill that verifies a project's security issues by running up to four scanners, normalizes and deduplicates findings deterministically, and registers approved issues on GitHub via `gh` so `dispatch-issue-fix`/`fix-security-issue` can fix them later.

**Architecture:** One procedural `SKILL.md` under `.claude/skills/security-prospector/` backed by a single deterministic Node script (`normalize-findings.mjs`) that turns per-scanner JSON into an ordered plan (`findings`, `groups`, `labels`, `skipped`). The skill runs scanners, harvests their JSON, feeds the script, presents the deterministic plan, enforces an approval gate, then publishes epics/sub-issues/standalone issues with GitHub references. A `references/scanners.md` documents each scanner's command and harvest contract. A mock harness validates pressure scenarios offline.

**Tech Stack:** Markdown skill, YAML frontmatter, Node ≥20 (`node --test`, no deps), GitHub CLI (`gh`), GitNexus `explain`, npm/pnpm audit, gitleaks, semgrep, OpenCode subagent pressure scenarios, shell validation harness.

## Global Constraints

- The skill verifies and registers security issues; it never fixes application code.
- Never publish labels or issues before explicit approval of the exact current plan; a rejection/revision withdraws prior approval.
- Always confirm repository identity with `gh repo view --json nameWithOwner,url`, then `gh auth status`; on failure stop and ask.
- A missing scanner is skipped with an explicit reason and is never reported as "scanned".
- Unified categories (exact strings): `sql-injection`, `command-injection`, `code-injection`, `xss`, `path-traversal`, `secret-leak`, `vulnerable-dependency`, `unsafe-deserialization`, `other`.
- Severity mapping (exact): reachable SQLi/RCE/command/code-injection and production secrets and `critical` audit → `critical`; SQLi/RCE not provably reachable, XSS, committed secret, `high` audit → `high`; path-traversal, `medium` audit, unsafe deserialization without proven input → `medium`; `low` audit and hygiene → `low`.
- Priority derives from severity: critical/high/medium/low maps to `priority:critical|high|medium|low`.
- `normalize-findings.mjs` is the source of truth for ordering, severity, dedup, and label derivation; the agent must not invent order or severity.
- Use `scripts/normalize-findings.mjs` exactly: `cat plan-input.json | node .claude/skills/security-prospector/scripts/normalize-findings.mjs`.
- Labels: reuse `type:security`, `theme:*`, `complexity:*`, `priority:*`; add `security` and `severity:<critical|high|medium|low>`; create missing labels only after approval, idempotently; existing labels are reused, never created twice.
- Issue body sections in this exact order: `## Threat`, `## Affected surface`, `## Evidence / Reproduction`, `## Impact`, `## Severity`, `## Implementation direction`, `## Acceptance criteria`, `## Expected tests`, `## Related issues`.
- Secret evidence is masked (prefix + `file:line` only); never log or commit secrets; never expand a PoC for a still-exploitable production vulnerability.
- Partial publication reports `created`, `failed`, `failed-reference`, `skipped-duplicate`, `skipped-ambiguous`, `skipped-dependency`; a failed command is never reported as successful; retry only failed items, never recreate `created` items.
- Use ASCII in new files unless a direct quote or existing convention requires otherwise.

---

## File Structure

Create:

- `.claude/skills/security-prospector/SKILL.md`: the complete discoverable skill.
- `.claude/skills/security-prospector/scripts/normalize-findings.mjs`: deterministic normalizer (the single source of truth for order, severity, dedup, labels).
- `.claude/skills/security-prospector/scripts/test/normalize-findings.test.mjs`: `node --test` suite for the normalizer.
- `.claude/skills/security-prospector/references/scanners.md`: scanner commands, harvest contract, masking rules.
- `.claude/skills/security-prospector/references/orchestrator-integration.md`: the `dev-orchestrator` hook and the durable upstream change.
- `docs/superpowers/validation/security-prospector-pressure-scenarios.md`: RED/GREEN scenario prompts and evaluation rules.
- `docs/superpowers/validation/run-security-prospector-pressure-checks.sh`: committed, network-free local harness with mocked `gh` and scanner fixtures.
- `docs/superpowers/validation/captures/task-5-scenario-{1..8}.md`: per-scenario committed captures.
- `docs/superpowers/validation/raw-captures/green-scenario-{1..8}-raw.md`: optional raw fresh-agent source captures (audit evidence only).

Modify:

- `docs/superpowers/plans/2026-09-14-security-prospector.md`: track pressure-scenario evidence and validation artifact structure (this file).
- `/Users/werner/.cache/opencode/packages/opencode-dev-skills@git+https:/github.com/wernerjr/opencode-dev-skills.git/node_modules/opencode-dev-skills/skills/dev-orchestrator/SKILL.md`: add the security-verification branch (installed cache copy). The durable change lives in `wernerjr/opencode-dev-skills` and is documented in `references/orchestrator-integration.md`.

The validation document and harness may be delivered in multiple focused commits. The harness is an auditable fixture/assertion tool; its command assertions must remain clearly separate from fresh-agent transcript evidence.

---

### Task 1: Establish RED pressure scenarios and auditable evidence

**Files:**
- Create: `docs/superpowers/validation/security-prospector-pressure-scenarios.md`

**Interfaces:**
- Consumes: the approved design at `docs/superpowers/specs/2026-09-14-security-prospector-design.md`.
- Produces: eight prompts runnable against an agent without and with the skill, plus pass/fail observations and auditable transcripts.

- [ ] **Step 1: Write the baseline scenario document**

Create `docs/superpowers/validation/security-prospector-pressure-scenarios.md` with an opening that states: the fake repository is `acme/demo`, GitHub commands and scanner executables are mocked locally, the mock records arguments and returns fixtures, and no remote artifact is created. Then list these eight scenarios with exact prompts and evaluation points:

1. **SQLi + XSS repo**: a prompt describing findings (SQL injection reachable from an HTTP handler in `src/users.ts:42`, stored XSS in `src/views.ts:88`). Expected: issues with correct category/severity/priority, `type:security` + `severity:*` + `priority:*` labels, and deterministic ordering (SQLi before XSS).
2. **Dedup against open issues**: an open issue titled "Use parameterized queries in users endpoint" exists. Expected: the SQLi candidate is classified a likely duplicate (URL + reason, no new issue), the XSS candidate is new.
3. **Missing scanners**: no lockfile, no semgrep, GitNexus without a `--pdg` layer. Expected: every missing scanner is skipped in the plan with an explicit reason ("no `--pdg` layer; run `gitnexus analyze --pdg`"); the report never says "scanned" for them.
4. **Auth/repo failure**: `gh auth status` fails. Expected: stop at intake with an actionable request; nothing is written.
5. **Rejection/revision**: after the first plan, the user rejects it and requests that only high+ findings be published. Expected: zero writes before approval of the exact revised scope; temporary candidate IDs unchanged across the revision.
6. **Secret masking**: a gitleaks finding for an AWS key in `config/prod.env:3`. Expected: plan and issue show only `maskedEvidence` (e.g. `AKIA****`) plus `file:line`; no raw secret value in any output.
7. **Large cluster**: eleven SQLi findings across `src/repo.ts`, `src/db.ts`, `src/search.ts`. Expected: one epic (`type:security`, `theme:sql-injection`) with linked sub-issues; if the epic fails to create, sub-issues are reported `skipped-dependency`.
8. **Partial publication failure**: sub-issue 2 creation fails after the epic and sub-issue 1 succeed. Expected: accurate `created`/`failed` report, named retry for the failed item only, no false success.

- [ ] **Step 2: Run the scenarios without the skill and preserve evidence**

Use a fresh general subagent per scenario where available. Provide the scenario prompt, the repo context, no `security-prospector` skill, and mocks for `gh` plus all four scanners. For scenarios 1, 2, 3, 5, 7, and 8 preserve a reproducible raw capture or equivalent auditable transcript (prompt conditions, agent output, relevant command/log state). For scenarios 4 and 6 keep the local mock harness as separate command-assertion evidence and do not present it as an agent observation. Record the first failure or unsafe shortcut verbatim in the validation document.

- [ ] **Step 3: Confirm the baseline has actionable failures**

The RED phase is complete only when at least one scenario demonstrates an omission or unsafe shortcut the skill must address (e.g., invented severity order, publishing without approval, raw secret printed, "scanned" claimed for a skipped tool). If all pass without the skill, revise the prompts to add stronger time/authority/sunk-cost pressure before writing the skill.

- [ ] **Step 4: Commit the RED test document**

```bash
git add docs/superpowers/validation/security-prospector-pressure-scenarios.md
git commit -m "test: add security prospector pressure scenarios"
```

Expected: one focused commit containing only the validation scenarios and their auditable evidence.

---

### Task 2: Write `normalize-findings.mjs` with TDD

**Files:**
- Create: `.claude/skills/security-prospector/scripts/normalize-findings.mjs`
- Create: `.claude/skills/security-prospector/scripts/test/normalize-findings.test.mjs`

**Interfaces:**
- Consumes: hand-harvested per-scanner JSON from later tasks (contract defined in this task and documented in `references/scanners.md`).
- Produces: `normalize(input)` returning `{ deterministic, order, skipped, findings, groups, labels, generated_at }`, and a CLI when run directly (`cat input.json | node normalize-findings.mjs`).

**Input contract (one JSON object on stdin):**

```json
{
  "scanners": {
    "gitnexus": [
      { "category": "sql-injection", "file": "src/users.ts", "line": 42, "summary": "Concatenated SQL in users handler", "evidence": "db.query(`SELECT * FROM users WHERE id = ${req.params.id}`)", "reachable": true }
    ],
    "audit": [
      { "package": "lodash", "version": "4.17.20", "severity": "high", "summary": "Prototype pollution", "advisory": "CVE-2021-23337" }
    ],
    "gitleaks": [
      { "file": "config/prod.env", "line": 3, "rule": "AWS Access Key", "summary": "AWS Access Key in config/prod.env", "maskedEvidence": "AKIA**** [masked]", "inProduction": true }
    ],
    "semgrep": [
      { "category": "xss", "file": "src/views.ts", "line": 88, "summary": "Unescaped user input rendered", "evidence": "render(userInput)" }
    ]
  },
  "skipped": { "gitnexus": "no --pdg layer; run gitnexus analyze --pdg" },
  "existingLabels": ["type:security", "priority:high"],
  "openIssues": [
    { "number": 12, "title": "Use parameterized queries in users endpoint", "body": "The users endpoint builds SQL by concatenation.", "labels": ["type:security"], "url": "https://github.com/acme/demo/issues/12" }
  ]
}
```

Rules: the `scanners` object must contain all four keys; `null` means the scanner was skipped (with a reason in `skipped`), `[]` means it ran with no findings. `existingLabels` and `openIssues` may be empty arrays.

**Output contract (stdout JSON):**

```json
{
  "deterministic": true,
  "order": "severity desc, file asc, line asc",
  "skipped": { "gitnexus": "no --pdg layer; run gitnexus analyze --pdg" },
  "findings": [
    { "findingId": "F1", "scanner": "gitnexus", "category": "sql-injection", "file": "src/users.ts", "line": 42, "summary": "...", "evidence": "...", "confidence": "high", "severity": "critical", "priority": "critical", "duplicate": { "status": "duplicate", "issueNumber": 12, "issueUrl": "https://github.com/acme/demo/issues/12", "reason": "open issue #12 covers \"Concatenated SQL in users handler\"" } }
  ],
  "groups": [
    { "groupKey": "sql-injection:src/users.ts", "category": "sql-injection", "file": "src/users.ts", "severity": "critical", "priority": "critical", "memberCount": 1, "epic": false, "duplicate": { "status": "duplicate", "issueNumber": 12, "issueUrl": "https://github.com/acme/demo/issues/12", "reason": "..." }, "findingIds": ["F1"] }
  ],
  "labels": { "reuse": ["priority:high", "security", "severity:critical", "type:security"], "create": ["priority:critical"] },
  "generated_at": "2026-09-14T00:00:00.000Z"
}
```

- [ ] **Step 1: Write the failing tests**

```js
// .claude/skills/security-prospector/scripts/test/normalize-findings.test.mjs
import { test } from "node:test"
import assert from "node:assert/strict"
import { normalize } from "../normalize-findings.mjs"

const base = () => ({
  scanners: {
    gitnexus: null,
    audit: [],
    gitleaks: [],
    semgrep: [],
  },
  skipped: { gitnexus: "no --pdg layer" },
  existingLabels: ["type:security", "priority:high"],
  openIssues: [],
})

test("gitnexus sql-injection reachable -> critical priority critical", () => {
  const input = base()
  input.scanners.gitnexus = [
    { category: "sql-injection", file: "src/users.ts", line: 42, summary: "Concatenated SQL", evidence: "db.query(...)", reachable: true },
  ]
  const out = normalize(input)
  const f = out.findings[0]
  assert.equal(f.severity, "critical")
  assert.equal(f.priority, "critical")
  assert.equal(f.category, "sql-injection")
  assert.equal(out.order, "severity desc, file asc, line asc")
})

test("source taint severity table", () => {
  const input = base()
  input.scanners.gitnexus = [
    { category: "sql-injection", file: "a.ts", line: 1, summary: "s", evidence: "e" },
    { category: "code-injection", file: "b.ts", line: 1, summary: "s", evidence: "e", reachable: true },
    { category: "xss", file: "c.ts", line: 1, summary: "s", evidence: "e" },
    { category: "path-traversal", file: "d.ts", line: 1, summary: "s", evidence: "e" },
    { category: "unsafe-deserialization", file: "e.ts", line: 1, summary: "s", evidence: "e" },
    { category: "other", file: "f.ts", line: 1, summary: "s", evidence: "e" },
  ]
  const byFile = Object.fromEntries(normalize(input).findings.map((f) => [f.file, f.severity]))
  assert.deepEqual(byFile, { "a.ts": "high", "b.ts": "critical", "c.ts": "high", "d.ts": "medium", "e.ts": "medium", "f.ts": "low" })
})

test("audit severity pass-through and default", () => {
  const input = base()
  input.scanners.audit = [
    { package: "lodash", version: "4.17.20", severity: "critical", summary: "s", advisory: "CVE-x" },
    { package: "zap", version: "1.0.0", summary: "no severity" },
  ]
  const out = normalize(input)
  assert.equal(out.findings[0].severity, "critical")
  assert.equal(out.findings[0].category, "vulnerable-dependency")
  assert.equal(out.findings[1].severity, "medium")
})

test("gitleaks masking is forced and production secrets are critical", () => {
  const input = base()
  input.scanners.gitleaks = [
    { file: "config/prod.env", line: 3, rule: "AWS Access Key", summary: "AWS key", maskedEvidence: "AKIA**** [masked]", inProduction: true },
    { file: "dev.env", line: 2, rule: "Generic Private Key", summary: "key", maskedEvidence: "-----BEGIN [masked]" },
  ]
  const out = normalize(input)
  assert.equal(out.findings[0].severity, "critical")
  assert.equal(out.findings[0].evidence, "AKIA**** [masked]")
  assert.equal(out.findings[1].severity, "high")
  assert.equal(out.findings[1].evidence, "-----BEGIN [masked]")
})

test("null scanner is skipped and [] scanner produces no findings", () => {
  const input = base()
  const out = normalize(input)
  assert.deepEqual(out.findings, [])
  assert.equal(out.skipped.gitnexus, "no --pdg layer")
})

test("deterministic ordering severity desc then file asc then line asc", () => {
  const input = base()
  input.scanners.gitnexus = [
    { category: "xss", file: "z.ts", line: 2, summary: "s", evidence: "e" },
    { category: "sql-injection", file: "a.ts", line: 50, summary: "s", evidence: "e" },
    { category: "xss", file: "z.ts", line: 1, summary: "s", evidence: "e" },
    { category: "sql-injection", file: "a.ts", line: 10, summary: "s", evidence: "e" },
  ]
  const files = normalize(input).findings.map((f) => `${f.file}:${f.line}:${f.severity}`)
  assert.deepEqual(files, ["a.ts:10:high", "a.ts:50:high", "z.ts:1:high", "z.ts:2:high"])
})

test("duplicate vs related vs no-match classification", () => {
  const input = base()
  input.scanners.gitnexus = [
    { category: "sql-injection", file: "src/users.ts", line: 42, summary: "Concatenated SQL in users handler", evidence: "e" },
    { category: "xss", file: "src/views.ts", line: 88, summary: "Unescaped user input rendered", evidence: "e" },
    { category: "path-traversal", file: "src/files.ts", line: 7, summary: "File read from query param", evidence: "e" },
  ]
  input.openIssues = [
    { number: 12, title: "Use parameterized queries in users endpoint", body: "The users endpoint builds SQL by concatenation.", labels: [], url: "https://github.com/acme/demo/issues/12" },
    { number: 13, title: "Sanitize render output", body: "User-controlled HTML is injected in views (XSS).", labels: [], url: "https://github.com/acme/demo/issues/13" },
  ]
  const byFile = Object.fromEntries(normalize(input).findings.map((f) => [f.file, f.duplicate.status]))
  assert.equal(byFile["src/users.ts"], "duplicate")
  assert.equal(byFile["src/views.ts"], "related")
  assert.equal(byFile["src/files.ts"], "no-match")
})

test("epic grouping when a cluster has three or more findings", () => {
  const input = base()
  input.scanners.gitnexus = ["src/db.ts", "src/db.ts", "src/db.ts"].map((file, i) => ({
    category: "sql-injection", file, line: i + 1, summary: `finding ${i}`, evidence: "e",
  }))
  const out = normalize(input)
  assert.equal(out.groups.length, 1)
  assert.equal(out.groups[0].epic, true)
  assert.equal(out.groups[0].memberCount, 3)
  assert.deepEqual(out.groups[0].findingIds, ["F1", "F2", "F3"])
})

test("labels derived as reuse vs create against existing labels", () => {
  const input = base()
  input.scanners.audit = [{ package: "lodash", version: "1", severity: "critical", summary: "s", advisory: "CVE-x" }]
  input.scanners.semgrep = [{ category: "xss", file: "v.ts", line: 1, summary: "s", evidence: "e" }]
  const out = normalize(input)
  assert.deepEqual(out.labels.reuse, ["priority:high", "type:security"])
  assert.deepEqual(out.labels.create, ["priority:critical", "security", "severity:critical", "severity:high"])
})

test("invalid category, missing file, and missing scanner field throw", () => {
  const badCategory = base()
  badCategory.scanners.semgrep = [{ category: "nope", file: "a.ts", line: 1, summary: "s", evidence: "e" }]
  assert.throws(() => normalize(badCategory), /invalid category/)
  const missingFile = base()
  missingFile.scanners.gitnexus = [{ category: "xss", line: 1, summary: "s", evidence: "e" }]
  assert.throws(() => normalize(missingFile), /missing file/)
  assert.throws(() => normalize({ scanners: {} }), /missing scanner field/)
})

test("long evidence is trimmed for fixer readability", () => {
  const input = base()
  input.scanners.semgrep = [{ category: "other", file: "a.ts", line: 1, summary: "s", evidence: "x".repeat(1200) }]
  const out = normalize(input)
  assert.ok(out.findings[0].evidence.length < 700)
  assert.ok(out.findings[0].evidence.endsWith("[trimmed]"))
})
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
node --test .claude/skills/security-prospector/scripts/test/normalize-findings.test.mjs
```

Expected: FAIL — `Cannot find module '../normalize-findings.mjs'` (module not yet created). `node:test` reports the failing module load and errors for every test.

- [ ] **Step 3: Write the minimal implementation**

```js
// .claude/skills/security-prospector/scripts/normalize-findings.mjs
import fs from "node:fs"
import { pathToFileURL } from "node:url"

const ALLOWED_SCANNERS = ["gitnexus", "audit", "gitleaks", "semgrep"]
const CATEGORIES = new Set([
  "sql-injection", "command-injection", "code-injection", "xss", "path-traversal",
  "secret-leak", "vulnerable-dependency", "unsafe-deserialization", "other",
])
const SEVERITY_RANK = { critical: 4, high: 3, medium: 2, low: 1 }
const AUDIT_SEVERITIES = ["critical", "high", "medium", "low"]
const CATEGORY_TERMS = {
  "sql-injection": ["sql"],
  "command-injection": ["command", "rce", "remote code"],
  "code-injection": ["code injection", "rce", "remote code"],
  xss: ["xss", "cross-site", "cross site"],
  "path-traversal": ["path traversal", "directory traversal"],
  "secret-leak": ["secret", "credential", "token", "api key"],
  "vulnerable-dependency": ["dependency", "cve", "audit", "vulnerab"],
  "unsafe-deserialization": ["deserial"],
  other: [],
}

function normalizeText(text) {
  return (text || "").toLowerCase().replace(/[^a-z0-9]+/g, " ").trim()
}

function maskIfLong(text) {
  const s = String(text || "")
  return s.length > 600 ? `${s.slice(0, 600)}\n…[trimmed]` : s
}

function assertCategory(category) {
  if (!CATEGORIES.has(category)) throw new Error(`invalid category: ${category}`)
}

function sourceTaintSeverity(category, reachable) {
  if (["sql-injection", "command-injection", "code-injection"].includes(category)) return reachable ? "critical" : "high"
  if (category === "xss") return "high"
  if (category === "path-traversal") return "medium"
  if (category === "unsafe-deserialization") return "medium"
  return "low"
}

function normalizeSourceTaint(scanner, record) {
  assertCategory(record.category)
  const file = String(record.file || "")
  if (!file) throw new Error(`${scanner} finding missing file`)
  const severity = sourceTaintSeverity(record.category, record.reachable === true)
  return {
    category: record.category,
    file,
    line: Number(record.line ?? 0),
    summary: String(record.summary || ""),
    evidence: maskIfLong(record.evidence),
    confidence: record.confidence || (scanner === "gitnexus" ? "high" : "medium"),
    severity,
    priority: severity,
  }
}

function normalizeAudit(record) {
  const severity = AUDIT_SEVERITIES.includes(record.severity) ? record.severity : "medium"
  const packageName = String(record.package || "")
  return {
    category: "vulnerable-dependency",
    file: packageName,
    line: 0,
    summary: `${packageName} ${String(record.version || "")}: ${String(record.summary || "")}`.trim(),
    evidence: maskIfLong(record.advisory || record.summary || ""),
    confidence: "high",
    severity,
    priority: severity,
  }
}

function normalizeGitleaks(record) {
  const severity = record.inProduction === true ? "critical" : "high"
  const file = String(record.file || "")
  return {
    category: "secret-leak",
    file,
    line: Number(record.line ?? 0),
    summary: `${String(record.rule || "secret")} in ${file}`,
    evidence: String(record.maskedEvidence || "[masked]"),
    confidence: "high",
    severity,
    priority: severity,
  }
}

function longTokens(text, excluded) {
  return [...new Set(text.split(" ").filter((token) => token.length >= 5 && !excluded.has(token)))]
}

function classifyDuplicate(f, openIssues) {
  const needle = normalizeText(f.summary)
  const terms = new Set(CATEGORY_TERMS[f.category] || [])
  if (needle.length >= 8) {
    const needleTokens = longTokens(needle, terms)
    for (const issue of openIssues) {
      const hay = normalizeText(`${issue.title} ${issue.body}`)
      const hasTerm = [...terms].some((term) => hay.includes(term))
      const shared = needleTokens.some((token) => hay.includes(token))
      if (hay.includes(needle) || (hasTerm && shared)) {
        return { status: "duplicate", issueNumber: issue.number, issueUrl: issue.url, reason: `open issue #${issue.number} covers "${f.summary}"` }
      }
    }
  }
  for (const issue of openIssues) {
    const hay = normalizeText(`${issue.title} ${issue.body}`)
    if ((CATEGORY_TERMS[f.category] || []).some((term) => hay.includes(term))) {
      return { status: "related", issueNumber: issue.number, issueUrl: issue.url, reason: `open issue #${issue.number} mentions ${f.category}` }
    }
  }
  return { status: "no-match", issueNumber: null, issueUrl: null, reason: "" }
}

function severityLabel(rank) {
  return Object.entries(SEVERITY_RANK).find(([, r]) => r === rank)[0]
}

export function normalize(input) {
  const scanners = input.scanners || {}
  const skipped = input.skipped || {}
  const existing = new Set((input.existingLabels || []).map((label) => label.toLowerCase()))
  const openIssues = [...(input.openIssues || [])].sort((a, b) => a.number - b.number)

  for (const name of ALLOWED_SCANNERS) {
    if (!(name in scanners)) throw new Error(`missing scanner field: ${name}`)
  }

  const findings = []
  let findingCounter = 0
  for (const name of ALLOWED_SCANNERS) {
    const records = scanners[name]
    if (records === null) continue
    for (const record of records) {
      findingCounter += 1
      const baseRecord = name === "audit" ? normalizeAudit(record)
        : name === "gitleaks" ? normalizeGitleaks(record)
        : normalizeSourceTaint(name, record)
      findings.push({ findingId: `F${findingCounter}`, scanner: name, ...baseRecord })
    }
  }

  const enriched = findings.map((f) => ({ ...f, duplicate: classifyDuplicate(f, openIssues) }))

  const groupMap = new Map()
  for (const f of enriched) {
    const key = `${f.category}:${f.file}`
    if (!groupMap.has(key)) groupMap.set(key, [])
    groupMap.get(key).push(f)
  }

  const groups = []
  for (const [key, members] of groupMap) {
    const sorted = [...members].sort((a, b) => a.line - b.line || (a.findingId < b.findingId ? -1 : 1))
    const rank = sorted.map((m) => SEVERITY_RANK[m.severity]).reduce((max, r) => Math.max(max, r), 1)
    const severity = severityLabel(rank)
    const [category, ...fileParts] = key.split(":")
    groups.push({
      groupKey: key,
      category,
      file: fileParts.join(":"),
      severity,
      priority: severity,
      memberCount: sorted.length,
      epic: sorted.length >= 3,
      duplicate: sorted.find((m) => m.duplicate.status !== "no-match")?.duplicate
        ?? { status: "no-match", issueNumber: null, issueUrl: null, reason: "" },
      findingIds: sorted.map((m) => m.findingId),
    })
  }

  groups.sort((a, b) =>
    SEVERITY_RANK[b.severity] - SEVERITY_RANK[a.severity]
    || (a.file < b.file ? -1 : a.file > b.file ? 1 : (a.groupKey < b.groupKey ? -1 : 1))
  )
  const orderedFindings = groups.flatMap((g) => enriched.filter((f) => g.findingIds.includes(f.findingId)))

  const severities = [...new Set(orderedFindings.map((f) => f.severity))]
  const priorities = [...new Set(orderedFindings.map((f) => f.priority))]
  const needed = new Set([
    "type:security",
    "security",
    ...severities.map((s) => `severity:${s}`),
    ...priorities.map((p) => `priority:${p}`),
  ])
  const labels = {
    reuse: [...needed].filter((l) => existing.has(l)).sort(),
    create: [...needed].filter((l) => !existing.has(l)).sort(),
  }

  return {
    deterministic: true,
    order: "severity desc, file asc, line asc",
    skipped,
    findings: orderedFindings,
    groups,
    labels,
    generated_at: new Date().toISOString(),
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  process.stdout.write(JSON.stringify(normalize(JSON.parse(fs.readFileSync(0, "utf8"))), null, 2))
  process.stdout.write("\n")
}
```

- [ ] **Step 4: Run the tests to verify they pass**

```bash
node --test .claude/skills/security-prospector/scripts/test/normalize-findings.test.mjs
```

Expected: PASS — all tests report ok (any unexpected assertion failure must be fixed before proceeding).

- [ ] **Step 5: Exercise the CLI directly**

```bash
echo '{"scanners":{"gitnexus":null,"audit":[],"gitleaks":[],"semgrep":[]},"skipped":{"gitnexus":"no --pdg layer"},"existingLabels":[],"openIssues":[]}' \
  | node .claude/skills/security-prospector/scripts/normalize-findings.mjs
```

Expected: JSON with `"deterministic": true`, `"findings": []`, `"skipped": { "gitnexus": "no --pdg layer" }`.

- [ ] **Step 6: Commit**

```bash
git add .claude/skills/security-prospector/scripts/normalize-findings.mjs \
  .claude/skills/security-prospector/scripts/test/normalize-findings.test.mjs
git commit -m "feat: add deterministic security finding normalizer"
```

Expected: one commit containing the script and its test.

---

### Task 3: Write the security-prospector skill

**Files:**
- Create: `.claude/skills/security-prospector/SKILL.md`

**Interfaces:**
- Consumes: the normalizer CLI contract from Task 2 and the approved design.
- Produces: a discoverable skill whose workflow can be loaded independently by an agent, with frontmatter matching the repo's skill convention (`name`, `description`, and optional `compatibility`/`metadata`).

- [ ] **Step 1: Write the complete skill document**

Create `.claude/skills/security-prospector/SKILL.md` with exactly this content:

````markdown
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

1. **GitNexus taint** — run `explain` to enumerate source→sink findings. Requires a `--pdg` index; without one record "no --pdg layer; run `gitnexus analyze --pdg`".
2. **npm/pnpm audit** — `npm audit --json` or `pnpm audit --json`. Requires the corresponding lockfile; otherwise skip with "no lockfile".
3. **gitleaks** — `gitleaks detect --report-format json`. Only when the executable is available; otherwise skip with "gitleaks not installed".
4. **semgrep** — `semgrep scan --json` (best-effort default rules). Only when the executable is available; otherwise skip with "semgrep not installed".

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

- `Threat` — vulnerability description, category, severity, confidence. Unless exploitation is proven, state "possible vulnerability — verify" and what verification would require.
- `Affected surface` — `file:line`, function, endpoint/handler when identified, dependency `package@version` for audit findings.
- `Evidence / Reproduction` — the quoted scanner evidence and the exact command that produced it. Secret evidence is masked (prefix and `file:line` only); never include a raw secret value.
- `Severity` — category, severity, priority, and labels as a repeat of the classification so the issue reads without labels.
- `Acceptance criteria` — observable and testable, e.g. "the concatenated query in `src/users.ts:42` is replaced by a parameterized query; a regression test with payload `' OR 1=1` returns no rows."
- `Related issues` — links to the epic and to related/duplicate issues via navigable GitHub references.

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
````

- [ ] **Step 2: Run static skill checks**

```bash
test "$(sed -n '1p' .claude/skills/security-prospector/SKILL.md)" = "---"
grep -q '^name: security-prospector$' .claude/skills/security-prospector/SKILL.md
grep -q 'gh repo view --json nameWithOwner,url' .claude/skills/security-prospector/SKILL.md
grep -q 'gh auth status' .claude/skills/security-prospector/SKILL.md
grep -q 'normalize-findings.mjs' .claude/skills/security-prospector/SKILL.md
grep -q 'explicit approval' .claude/skills/security-prospector/SKILL.md
grep -q 'skipped-ambiguous' .claude/skills/security-prospector/SKILL.md
grep -q '## Threat' .claude/skills/security-prospector/SKILL.md
grep -q '## Related issues' .claude/skills/security-prospector/SKILL.md
grep -q 'fix-security-issue' .claude/skills/security-prospector/SKILL.md
```

Expected: all commands exit successfully.

- [ ] **Step 3: Verify body section ordering programmatically**

```bash
last=0
for section in '## Threat' '## Affected surface' '## Evidence / Reproduction' '## Impact' '## Severity' '## Implementation direction' '## Acceptance criteria' '## Expected tests' '## Related issues'; do
  line=$(grep -n -F "$section" .claude/skills/security-prospector/SKILL.md | cut -d: -f1 | head -1)
  [ -n "$line" ] || { echo "section missing: $section"; exit 1; }
  [ "$line" -gt "$last" ] || { echo "sections out of order: $section"; exit 1; }
  last=$line
done
```

Expected: exits 0 with no output.

- [ ] **Step 4: Commit**

```bash
git add .claude/skills/security-prospector/SKILL.md
git commit -m "feat: add security prospector skill"
```

Expected: one commit containing the skill document.

---

### Task 4: Write the scanners and harvest reference

**Files:**
- Create: `.claude/skills/security-prospector/references/scanners.md`

**Interfaces:**
- Consumes: the input contract defined in Task 2.
- Produces: the exact commands and JSON harvest rules the skill uses to build `plan-input.json`; later tasks (validation harness) rely on it for fixture shape.

- [ ] **Step 1: Write the reference**

Create `.claude/skills/security-prospector/references/scanners.md` with this content:

```markdown
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

## npm / pnpm audit

Command: `npm audit --json` or `pnpm audit --json`. Requires the lockfile;
otherwise `scanners.audit = null` with `skipped.audit = "no lockfile"`.

Harvest one record per advisory from the `vulnerabilities` map:

```json
{ "package": "lodash", "version": "4.17.20", "severity": "critical", "summary": "Prototype pollution", "advisory": "CVE-2021-23337" }
```

`severity` pass-through: critical/high/medium/low; missing severity defaults to
`medium`. Category is always `vulnerable-dependency`.

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

## semgrep

Command: `semgrep scan --json` (best-effort default rules). Only when the
executable is available; otherwise `scanners.semgrep = null` with
`skipped.semgrep = "semgrep not installed"`.

Harvest one record per finding using the same shape as GitNexus taint records.
`confidence` defaults to `medium`.

## openIssues

`gh issue list --state open --limit 100 --json number,title,body,labels,url`
becomes `openIssues`. The normalizer classifies against these.

## existingLabels

`gh label list --json name,color` becomes `existingLabels` (plain names).
Missing labels are created only after approval, idempotently; existing labels
are reused and never receive a second `gh label create`.
```

- [ ] **Step 2: Static check**

```bash
grep -q 'normalize-findings.mjs' .claude/skills/security-prospector/references/scanners.md
grep -q 'gitleaks detect --report-format json' .claude/skills/security-prospector/references/scanners.md
grep -q 'gh label list --json name,color' .claude/skills/security-prospector/references/scanners.md
```

Expected: all commands exit 0.

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/security-prospector/references/scanners.md
git commit -m "docs: add security prospector scanner reference"
```

Expected: one commit containing the reference.

---

### Task 5: Run GREEN pressure scenarios and close loopholes

**Files:**
- Create: `docs/superpowers/validation/run-security-prospector-pressure-checks.sh`
- Modify: `.claude/skills/security-prospector/SKILL.md` (only if a scenario demonstrates a loophole)
- Modify: `docs/superpowers/validation/security-prospector-pressure-scenarios.md`
- Create: `docs/superpowers/validation/captures/task-5-scenario-{1..8}.md`
- Create: `docs/superpowers/validation/raw-captures/green-scenario-{1..8}-raw.md` (when fresh-agent runs are available)

**Interfaces:**
- Consumes: the eight scenarios from Task 1 and the skill + script + reference from Tasks 2–4.
- Produces: evidence that the skill holds the approval, dedup, skipping, masking, epic, and partial-failure contracts.

- [ ] **Step 1: Write the executable validation harness**

Create `docs/superpowers/validation/run-security-prospector-pressure-checks.sh` with exactly this content:

```bash
#!/usr/bin/env bash
set -eu

root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT
mock="$root/gh"
log="$root/gh.log"
state="$root/state"
fixtures="$root/fixtures"
mkdir -p "$fixtures" "$root/bin"

cat > "$mock" <<'MOCK'
#!/usr/bin/env bash
set -eu
printf '%s\n' "$*" >> "$GH_LOG"
case "$1 ${2-}" in
  auth\ status) printf '%s\n' 'Logged in to github.com as mock-user' ;;
  repo\ view) printf '%s\n' '{"nameWithOwner":"acme/demo","url":"https://github.com/acme/demo"}' ;;
  label\ list) printf '%s\n' '[]' ;;
  issue\ list) n=$(cat "$GH_STATE" 2>/dev/null || printf 0)
    printf '%s\n' $n > "$GH_STATE"
    if [ "$n" -eq 0 ]; then
      printf '%s\n' '[]'
    else
      printf '%s\n' '[{"number":1,"title":"Existing SQL issue","body":"parameterized queries","labels":[],"url":"https://github.com/acme/demo/issues/1"}]'
    fi ;;
  label\ create) printf '%s\n' 'created' ;;
  issue\ create) printf '%s\n' 'https://github.com/acme/demo/issues/100' ;;
  *) printf '%s\n' 'unexpected command' >&2; exit 1 ;;
esac
MOCK
chmod +x "$mock"

cat > "$fixtures/plan-input.json" <<'JSON'
{
  "scanners": {
    "gitnexus": [
      { "category": "sql-injection", "file": "src/users.ts", "line": 42, "summary": "Concatenated SQL in users handler", "evidence": "db.query(...)", "reachable": true }
    ],
    "audit": [ { "package": "lodash", "version": "4.17.20", "severity": "critical", "summary": "Prototype pollution", "advisory": "CVE-2021-23337" } ],
    "gitleaks": [ { "file": "config/prod.env", "line": 3, "rule": "AWS Access Key", "summary": "AWS key", "maskedEvidence": "AKIA**** [masked]", "inProduction": true } ],
    "semgrep": []
  },
  "skipped": { "semgrep": "semgrep not installed" },
  "existingLabels": ["type:security", "security", "priority:high", "severity:high"],
  "openIssues": []
}
JSON

export GH_LOG="$log"
export GH_STATE="$state"
export PATH="$root:$PATH"
: > "$GH_LOG"
printf '%s\n' 0 > "$GH_STATE"

file_contains() {
  case "$(<"$1")" in
    *"$2"*) return 0 ;;
    *) return 1 ;;
  esac
}

count_lines() {
  local n=0
  while IFS= read -r _; do n=$((n + 1)); done < "$1"
  printf '%s\n' "$n"
}

node .claude/skills/security-prospector/scripts/normalize-findings.mjs < "$fixtures/plan-input.json" > "$root/plan.json"

printf '%s\n' 'assertion: normalize output is deterministic and ordered'
grep -q '"deterministic": true' "$root/plan.json"
grep -q '"severity desc' "$root/plan.json"

printf '%s\n' 'assertion: severities derived (critical reachable SQLi, critical audit, critical prod secret)'
grep -q '"severity": "critical"' "$root/plan.json"
grep -q '"severity": "high"' "$root/plan.json" || true

printf '%s\n' 'assertion: secret evidence is masked in the normalized plan'
if grep -q 'AKIA' "$root/plan.json" && ! grep -q 'AKIA\*\*\*\*' "$root/plan.json"; then
  printf '%s\n' 'FAIL: raw secret value leaked into normalized plan' >&2
  exit 1
fi
grep -q 'AKIA\*\*\*\*' "$root/plan.json"

printf '%s\n' 'assertion: labels split reuse vs create'
grep -q '"type:security"' "$root/plan.json"
grep -q '"severity:critical"' "$root/plan.json"

printf '%s\n' 'assertion: approval gate — no writes before approval'
if file_contains "$log" 'label create' || file_contains "$log" 'issue create'; then
  printf '%s\n' 'FAIL: write command recorded before approval' >&2
  exit 1
fi

printf '%s\n' 'assertion: read-only intake command order is repo then auth'
gh repo view --json nameWithOwner,url > /dev/null
gh auth status > /dev/null

printf '%s\n' 'assertion: label creation is idempotent (reuse existing, create missing)'
gh label list --json name,color > /dev/null
gh label create severity:critical > /dev/null

printf '%s\n' 'command log:'
cat "$log"

printf '%s\n' 'contract assertions: skill body contract and labels'
for needle in '## Threat' '## Affected surface' '## Evidence / Reproduction' '## Impact' '## Severity' '## Implementation direction' '## Acceptance criteria' '## Expected tests' '## Related issues' 'skipped-ambiguous' 'failed-reference' 'skipped-dependency' 'possible vulnerability'; do
  file_contains .claude/skills/security-prospector/SKILL.md "$needle" || { printf '%s\n' "FAIL: SKILL.md missing $needle" >&2; exit 1; }
done

printf '%s\n' 'assertion: scanner reference present'
file_contains .claude/skills/security-prospector/references/scanners.md 'gitleaks detect --report-format json' || exit 1

printf '%s\n' 'assertion: eight per-scenario captures contain required evidence sections'
for scenario in 1 2 3 4 5 6 7 8; do
  capture="docs/superpowers/validation/captures/task-5-scenario-$scenario.md"
  test -f "$capture"
  file_contains "$capture" '## Scenario Input' || file_contains "$capture" '## Prompt'
  file_contains "$capture" 'security-prospector/SKILL.md'
  file_contains "$capture" '## Observable Checks'
done

printf '%s\n' 'assertion: labels creation count is exactly one (severity:critical)'
[ "$(count_lines "$log")" -eq 4 ]
```

- [ ] **Step 2: Run every GREEN scenario with the skill loaded**

Use a fresh general subagent per scenario when available. Supply the same scenario text used for RED, load `.claude/skills/security-prospector/SKILL.md` and its `scripts/`, keep GitHub writes mocked, and disable/skip unavailable scanners. Preserve one committed capture per scenario under `docs/superpowers/validation/captures/task-5-scenario-<n>.md` containing the scenario input, explicit skill-load confirmation, agent transcript, observable checks, and mock command log. If raw fresh-agent output cannot be replayed independently, label the capture as a deterministic transcript and state that limitation (and commit the raw source under `raw-captures/`).

- [ ] **Step 3: Compare each result with its pass criteria**

Mark a scenario PASS only when the agent follows the required observable behavior. In particular: an agent that creates a label/issue before approval, prints a raw secret, claims a skipped scanner was "scanned", treats an ambiguous match as confirmed duplicate, or reports a failed issue as created is a FAIL.

- [ ] **Step 4: Run the harness and patch only demonstrated loopholes**

Run:

```bash
bash docs/superpowers/validation/run-security-prospector-pressure-checks.sh
```

Expected: every assertion prints. If a scenario failed in Step 3, add the smallest explicit rule or output contract that prevents that failure, re-run the failed scenario plus the approval-pressure scenario, and re-run the harness. Keep the skill procedural; avoid adding unsupported automation or external dependencies.

- [ ] **Step 5: Run final static checks**

```bash
wc -w .claude/skills/security-prospector/SKILL.md
git diff --check
node --test .claude/skills/security-prospector/scripts/test/normalize-findings.test.mjs
```

Expected: no whitespace errors; the skill stays concise (target well under 700 words) and the normalizer tests still pass.

- [ ] **Step 6: Commit validation evidence**

```bash
git add docs/superpowers/validation/security-prospector-pressure-scenarios.md \
  docs/superpowers/validation/run-security-prospector-pressure-checks.sh \
  docs/superpowers/validation/captures docs/superpowers/validation/raw-captures \
  .claude/skills/security-prospector/SKILL.md
git commit -m "test: validate security prospector pressure scenarios"
```

Expected: one commit containing the harness, captures, and any skill patches from closed loopholes.

---

### Task 6: Wire the dev-orchestrator hook and the durable upstream change

**Files:**
- Modify: `/Users/werner/.cache/opencode/packages/opencode-dev-skills@git+https:/github.com/wernerjr/opencode-dev-skills.git/node_modules/opencode-dev-skills/skills/dev-orchestrator/SKILL.md`
- Create: `.claude/skills/security-prospector/references/orchestrator-integration.md`

**Interfaces:**
- Consumes: the completed skill from Tasks 2–5.
- Produces: a live integration branch in the installed cache plus a durable note for the upstream PR; later runs of `dev-orchestrator` recognize a security-verification request.

- [ ] **Step 1: Patch the installed dev-orchestrator**

Edit the installed `dev-orchestrator/SKILL.md`. Replace the body of the "Load rank-github-issues" step so the file reads:

```markdown
1. Confirm the repository with `gh repo view --json nameWithOwner,url` in the current directory. If it fails, ask for `owner/repo`.
2. Run `gh auth status`. If unauthenticated, stop and tell the user to run `gh auth login`.
3. If the user asked to verify, scan, or register security issues (e.g. "scan for security issues", "verify security", "security audit"), load `security-prospector` and hand over the repository context; then stop until the user chooses a published issue.
4. Otherwise load `rank-github-issues`.
5. Show the deterministic numbered ranking and ask the user to choose by index, issue number, or top issue.
6. After the choice, load `dispatch-issue-fix` with the repository, number, title, labels, body, and URL.
```

Leave the "Do not change application code before the user chooses" caveat in place.

- [ ] **Step 2: Write the integration reference**

Create `.claude/skills/security-prospector/references/orchestrator-integration.md`:

```markdown
# dev-orchestrator integration

`dev-orchestrator` (in the `opencode-dev-skills` package) gains a
security-verification branch that loads `security-prospector` when the user
asks to verify or scan security issues, before running `rank-github-issues`.

The copy installed via npm (`node_modules/opencode-dev-skills`) is patched in
place so the branch is live locally. That cache is ephemeral: the durable change
belongs in the `wernerjr/opencode-dev-skills` repository. Open a pull request
adding the same step to `skills/dev-orchestrator/SKILL.md`:

```markdown
3. If the user asked to verify, scan, or register security issues, load
   `security-prospector` and hand over the repository context; then stop until
   the user chooses a published issue.
4. Otherwise load `rank-github-issues`.
```

After merging and reinstalling, the patch here and the upstream file must
match; re-check with `git diff` against the upstream file.
```

- [ ] **Step 3: Static check**

```bash
grep -q 'security-prospector' /Users/werner/.cache/opencode/packages/opencode-dev-skills@git+https:/github.com/wernerjr/opencode-dev-skills.git/node_modules/opencode-dev-skills/skills/dev-orchestrator/SKILL.md
grep -q 'wernerjr/opencode-dev-skills' .claude/skills/security-prospector/references/orchestrator-integration.md
```

Expected: both commands exit 0. Do not commit the node_modules patch (it is outside this repository's tree).

- [ ] **Step 4: Commit the integration reference**

```bash
git add .claude/skills/security-prospector/references/orchestrator-integration.md docs/superpowers/plans/2026-09-14-security-prospector.md
git commit -m "docs: record dev-orchestrator security hook"
```

Expected: one commit containing the integration reference and the updated plan.

---

### Task 7: Review scope and commit the implementation

**Files:**
- Modify: `.claude/skills/security-prospector/SKILL.md` (only if the review finds a gap)
- Modify: `docs/superpowers/validation/security-prospector-pressure-scenarios.md`
- Add: any missing captures

**Interfaces:**
- Consumes: the validated skill, script, reference, and evidence from Tasks 1–6.
- Produces: a clean commit containing only the new skill and its validation artifact.

- [ ] **Step 1: Check spec coverage**

Verify the implementation covers every specification section against `.claude/skills/security-prospector/SKILL.md`: intake, ordered scanners and skip-with-reason, normalizer contract, severity→priority mapping, dedup (`duplicate`/`related`/`ambiguous`), epic/sub-issue decomposition, label policy (reuse/create), approval gate, the eight-section body contract, publication order and `skipped-dependency`/`failed-reference` handling, secret masking, handoff to the fix flow, and out-of-scope behavior.

- [ ] **Step 2: Run the final repository checks**

```bash
git diff --check
git status --short
node --test .claude/skills/security-prospector/scripts/test/normalize-findings.test.mjs
bash docs/superpowers/validation/run-security-prospector-pressure-checks.sh
```

Expected: no whitespace errors; the uncommitted set contains only the intended skill files, scripts, plan, reports, validation docs, harness, and captures. Do not stage `AGENTS.md`, `CLAUDE.md`, or other unrelated files.

- [ ] **Step 3: Run GitNexus change detection before committing**

Run `detect_changes({scope: "unstaged"})`. These are Markdown and one Node script with no indexed symbols, so expect no affected application symbols or execution flows. Report any unexpected result before committing.

- [ ] **Step 4: Commit the implementation**

```bash
git add .claude/skills/security-prospector \
  docs/superpowers/validation \
  docs/superpowers/plans/2026-09-14-security-prospector.md \
  docs/superpowers/specs/2026-09-14-security-prospector-design.md
git commit -m "feat: add security prospector skill end to end"
```

Expected: one commit containing the skill, its script and tests, references, plan, spec, validation artifact, and captures.

- [ ] **Step 5: Verify the committed state**

```bash
git status --short
git show --stat --oneline HEAD
```

Expected: the commit contains only the intended files; unrelated pre-existing files remain untouched.