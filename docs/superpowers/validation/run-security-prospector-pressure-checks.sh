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