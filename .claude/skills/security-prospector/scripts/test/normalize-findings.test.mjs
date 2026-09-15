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