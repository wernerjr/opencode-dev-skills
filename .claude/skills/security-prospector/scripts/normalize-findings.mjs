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
  const byFindingId = new Map(enriched.map((f) => [f.findingId, f]))
  const orderedFindings = groups.flatMap((g) => g.findingIds.map((id) => byFindingId.get(id)))

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