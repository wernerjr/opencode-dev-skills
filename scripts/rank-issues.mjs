import fs from "node:fs"

const securityPattern = /\b(cve|rce|xss|sqli|sql injection|injection|auth(?:entication|orization)? bypass|privilege escalation|secret leak|vulnerability|arbitrary code|remote code execution)\b/i
const securityLabels = /^(security|sec|vulnerability|cve|rce|xss|sqli|injection|auth-bypass|secret)$/i
const text = fs.readFileSync(0, "utf8")
const issues = JSON.parse(text)

function labels(issue) {
  return (issue.labels || []).map((label) => typeof label === "string" ? label : label.name || "")
}

function isSecurity(issue) {
  const title = issue.title || ""
  const body = issue.body || ""
  return labels(issue).some((label) => securityLabels.test(label)) || securityPattern.test(`${title}\n${body}`)
}

function score(issue) {
  const issueLabels = labels(issue).map((label) => label.toLowerCase())
  const security = isSecurity(issue)
  let value = security ? 100 : 0
  if (issueLabels.some((label) => ["bug", "defect", "crash"].includes(label))) value += 40
  if (issueLabels.some((label) => ["p0", "critical", "blocker"].includes(label))) value += 50
  else if (issueLabels.some((label) => ["p1", "high"].includes(label))) value += 30
  else if (issueLabels.includes("p2") || issueLabels.includes("medium")) value += 10
  if (issueLabels.includes("good first issue")) value += 5
  value += (issue.comments || []).length * 2
  value += (issue.reactionGroups || []).reduce((sum, group) => sum + (group.users?.totalCount || group.totalCount || 0), 0)
  const age = Date.now() - new Date(issue.updatedAt || issue.createdAt || 0).getTime()
  if (age > 14 * 24 * 60 * 60 * 1000 && issue.updatedAt === issue.createdAt) value += 10
  if ((issue.assignees || []).length > 0) value -= 15
  if (issueLabels.includes("enhancement") || issueLabels.includes("chore")) value -= 10
  return value
}

const ranked = issues.map((issue) => {
  const security = isSecurity(issue)
  return { ...issue, score: score(issue), type: security ? "SEC" : "CODE", is_security: security, labels: labels(issue) }
}).sort((a, b) => b.score - a.score || Number(b.is_security) - Number(a.is_security) || a.number - b.number)

process.stdout.write(JSON.stringify({ ranked, generated_at: new Date().toISOString() }))
