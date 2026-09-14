#!/usr/bin/env bash
set -eu

root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT
mock="$root/gh"
log="$root/gh.log"
state="$root/state"
transcript="$root/gh-transcript.txt"
mkdir -p "$root/bin"

cat > "$mock" <<'MOCK'
#!/usr/bin/env bash
set -eu
printf '%s\n' "$*" >> "$GH_LOG"
if [ "$GH_SCENARIO" = approval ]; then
  case "$1 ${2-}" in
    label\ create) printf '%s\n' 'priority:high created' ;;
    issue\ create) printf '%s\n' 'https://github.com/acme/demo/issues/200' ;;
     *) printf '%s\n' 'read fixture' ;;
  esac
elif [ "$GH_SCENARIO" = duplicate ]; then
  case "$1 ${2-}" in
    auth\ status) printf '%s\n' 'Logged in to github.com as mock-user' ;;
    repo\ view) printf '%s\n' '{"nameWithOwner":"acme/demo","url":"https://github.com/acme/demo"}' ;;
    issue\ list) printf '%s\n' '[{"number":42,"title":"Add CSV export to reports","body":"Allow users to download filtered reports as CSV from the Reports page.","labels":[],"url":"https://github.com/acme/demo/issues/42"}]' ;;
    issue\ view) printf '%s\n' '{"number":42,"title":"Add CSV export to reports","body":"Allow users to download filtered reports as CSV from the Reports page.","labels":[],"url":"https://github.com/acme/demo/issues/42"}' ;;
    *) printf '%s\n' 'unexpected duplicate command' >&2; exit 1 ;;
  esac
elif [ "$GH_SCENARIO" = auth ]; then
  if [ "$1 ${2-}" = 'auth status' ]; then
    printf '%s\n' 'not logged into any GitHub hosts' >&2
    exit 1
  fi
  printf '%s\n' 'unexpected post-auth command' >&2
  exit 1
  elif [ "$GH_SCENARIO" = partial ]; then
  n=$(cat "$GH_STATE")
  printf '%s\n' "$((n + 1))" > "$GH_STATE"
  case "$n" in
    0) printf '%s\n' 'https://github.com/acme/demo/issues/100' ;;
    1) printf '%s\n' 'https://github.com/acme/demo/issues/101' ;;
    2) printf '%s\n' 'validation failed' >&2; exit 1 ;;
     *) printf '%s\n' 'unexpected write' >&2; exit 1 ;;
   esac
elif [ "$GH_SCENARIO" = reference ]; then
  n=$(cat "$GH_STATE")
  printf '%s\n' "$((n + 1))" > "$GH_STATE"
  case "$n" in
    0) printf '%s\n' 'https://github.com/acme/demo/issues/300' ;;
    1) printf '%s\n' 'https://github.com/acme/demo/issues/301' ;;
    2) printf '%s\n' 'reference-failure source=300 target=301 error=reference service unavailable' >> "$GH_LOG"
       printf '%s\n' 'reference target=301 source=300 error=reference service unavailable' >&2
       exit 1 ;;
    3) printf '%s\n' 'reference added source=300 target=301' ;;
    *) printf '%s\n' 'unexpected reference operation' >&2; exit 1 ;;
  esac
  fi
MOCK
chmod +x "$mock"

export GH_LOG="$log"
export GH_STATE="$state"
export PATH="$root:$PATH"

reset_mock_state() {
  : > "$GH_LOG"
  printf '%s\n' 0 > "$GH_STATE"
}

file_contains() {
  local content
  content=$(<"$1")
  case "$content" in
    *"$2"*) return 0 ;;
    *) return 1 ;;
  esac
}

log_has_line() {
  local line
  while IFS= read -r line; do
    [ "$line" = "$2" ] && return 0
  done < "$1"
  return 1
}

log_count_matching() {
  local expected="$2" count=0 line
  while IFS= read -r line; do
    case "$line" in
      *"$3"*) count=$((count + 1)) ;;
    esac
  done < "$1"
  [ "$count" -eq "$expected" ]
}

log_starts_with_repo_then_auth() {
  local first='' second='' line
  while IFS= read -r line; do
    if [ -z "$first" ]; then
      first="$line"
    else
      second="$line"
      break
    fi
  done < "$1"
  [ "$first" = 'repo view --json nameWithOwner,url' ] && [ "$second" = 'auth status' ]
}

line_count() {
  local count=0 line
  while IFS= read -r line; do
    count=$((count + 1))
  done < "$1"
  printf '%s\n' "$count"
}

start_phase() {
  reset_mock_state
  : > "$transcript"
}

run_and_capture() {
  set +e
  gh "$@" >"$root/last-output" 2>&1
  status=$?
  set -e
  {
    printf '$ gh'
    printf ' %q' "$@"
    printf '\nexit %s\n' "$status"
    cat "$root/last-output"
  } >> "$transcript"
  return "$status"
}

start_phase
export GH_SCENARIO=approval
printf '%s\n' 'approval phase: plan-only; no writes requested'
if file_contains "$log" 'label create' || file_contains "$log" 'issue create'; then
  printf '%s\n' 'FAIL: pre-approval write detected' >&2
  exit 1
fi
printf '%s\n' 'assertion: pre-approval write log is empty'
printf '%s\n' 'approval phase: explicit approval received for label priority:high and issue 200'
run_and_capture label create 'priority:high'
run_and_capture issue create --title 'Approved issue'
if ! log_has_line "$log" 'label create priority:high' ||
   ! log_has_line "$log" 'issue create --title Approved issue' ||
   [ "$(line_count "$log")" -ne 2 ]; then
  printf '%s\n' 'FAIL: post-approval writes exceed approved scope' >&2
  exit 1
fi
printf '%s\n' 'assertion: post-approval log contains exactly the two approved writes'
printf '%s\n' 'approval command log:'
cat "$log"
printf '%s\n' 'harness raw command/output transcript (approval):'
cat "$transcript"

printf '%s\n' 'contract assertions: grouping and duplicate outcomes'
file_contains .claude/skills/github-issue-grooming/SKILL.md 'stable temporary IDs'
file_contains .claude/skills/github-issue-grooming/SKILL.md 'likely duplicate'
file_contains .claude/skills/github-issue-grooming/SKILL.md 'related issue'
file_contains .claude/skills/github-issue-grooming/SKILL.md 'skipped-ambiguous'
file_contains .claude/skills/github-issue-grooming/SKILL.md 'epic'
file_contains .claude/skills/github-issue-grooming/SKILL.md 'sub-issues'
printf '%s\n' 'assertion: grouping, duplicate, related, and ambiguous outcomes are documented'

printf '%s\n' 'contract assertions: labels and exact issue-body sections'
for label in 'type:<feature|bug|chore|refactor|documentation|security|research>' \
  'theme:<lowercase-theme>' 'complexity:<small|medium|large>' \
  'priority:<critical|high|medium|low>'; do
  file_contains .claude/skills/github-issue-grooming/SKILL.md "$label"
done
body_sections='## Context
## Problem or opportunity
## Objective
## Scope
## Out of scope
## Implementation direction
## Acceptance criteria
## Expected tests
## Dependencies
## Classification
## Related issues'
while IFS= read -r section; do
  file_contains .claude/skills/github-issue-grooming/SKILL.md "$section"
  line=0
  while IFS= read -r source_line; do
    line=$((line + 1))
    [ "$source_line" = "$section" ] && break
  done < .claude/skills/github-issue-grooming/SKILL.md
  if [ "$line" -le "${last_line:-0}" ]; then
    printf '%s\n' 'FAIL: issue-body sections are out of order' >&2
    exit 1
  fi
  last_line=$line
done <<EOF
$body_sections
EOF
printf '%s\n' 'assertion: all required labels and body sections are present in exact order'

start_phase
export GH_SCENARIO=duplicate
if ! run_and_capture repo view --json nameWithOwner,url ||
   ! run_and_capture auth status ||
   ! run_and_capture issue list --state open --limit 100 --json number,title,body,labels,url ||
   ! run_and_capture issue view 42 --json number,title,body,labels,url; then
  printf '%s\n' 'FAIL: duplicate scenario read-only command failed' >&2
  exit 1
fi
if [ "$(line_count "$log")" -ne 4 ] ||
   ! log_starts_with_repo_then_auth "$log" ||
   ! log_has_line "$log" 'auth status' ||
   ! log_has_line "$log" 'repo view --json nameWithOwner,url' ||
   ! log_has_line "$log" 'issue list --state open --limit 100 --json number,title,body,labels,url' ||
   ! log_has_line "$log" 'issue view 42 --json number,title,body,labels,url' ||
   ! file_contains "$transcript" 'Logged in to github.com as mock-user' ||
   ! file_contains "$transcript" '"nameWithOwner":"acme/demo"' ||
   ! file_contains "$transcript" '"number":42'; then
  printf '%s\n' 'FAIL: duplicate scenario evidence is incomplete' >&2
  exit 1
fi
printf '%s\n' 'duplicate command log:'
cat "$log"
printf '%s\n' 'harness raw command/output transcript (duplicate):'
cat "$transcript"
printf '%s\n' 'assertion: duplicate scenario authenticates and inspects the matching issue with read-only commands'

printf '%s\n' 'contract assertions: post-publication reference failure handling'
file_contains .claude/skills/github-issue-grooming/SKILL.md 'failed-reference'
file_contains .claude/skills/github-issue-grooming/SKILL.md '`reference` role identity'
file_contains .claude/skills/github-issue-grooming/SKILL.md 'never recreate either issue'
printf '%s\n' 'assertion: failed references retain created issues and retry only the reference'

printf '%s\n' 'contract assertions: six per-scenario captures'
for scenario in 1 2 3 4 5 6; do
  capture="docs/superpowers/validation/captures/task-3-scenario-$scenario.md"
  test -f "$capture"
  file_contains "$capture" '## Scenario Input' || file_contains "$capture" '## Prompt'
  file_contains "$capture" '## Skill Load' || file_contains "$capture" '## Explicit Skill-Load Confirmation'
  file_contains "$capture" 'github-issue-grooming/SKILL.md'
  file_contains "$capture" '## Agent Transcript' || file_contains "$capture" '## Full Response'
  file_contains "$capture" '## Observable Checks'
  file_contains "$capture" '## Mock Command Log'
done
printf '%s\n' 'assertion: six per-scenario captures contain required evidence sections'

start_phase
export GH_SCENARIO=auth
if run_and_capture auth status; then
  printf '%s\n' 'FAIL: authentication unexpectedly succeeded' >&2
  exit 1
fi
if [ "$(line_count "$log")" -ne 1 ] ||
   ! log_has_line "$log" 'auth status' ||
   ! file_contains "$transcript" 'not logged into any GitHub hosts'; then
  printf '%s\n' 'FAIL: authentication stop evidence is incomplete' >&2
  exit 1
fi
printf '%s\n' 'authentication command log:'
cat "$log"
printf '%s\n' 'harness raw command/output transcript (authentication):'
cat "$transcript"
printf '%s\n' 'assertion: auth failure stops before repo, issue, label, or publication commands'

start_phase
export GH_SCENARIO=partial
# Reproduce the documented exploratory probe, then reset every mock state file.
run_and_capture --help || true
reset_mock_state
created=''
failed=''
if run_and_capture issue create --title 'Account security epic'; then
  output=$(<"$root/last-output")
  created="epic: $output"
else
  failed='epic: creation failed'
fi
if run_and_capture issue create --title 'Password policy'; then
  output=$(<"$root/last-output")
  created="$created\nsub-issue 1: $output"
else
  failed="$failed\nsub-issue 1: creation failed"
fi
if run_and_capture issue create --title 'MFA enrollment'; then
  output=$(<"$root/last-output")
  created="$created\nsub-issue 2: $output"
else
  failed='sub-issue 2: validation failed; retry this item only'
fi
printf '%b\n' 'partial report: created' "$created"
printf '%b\n' 'partial report: failed' "$failed"
if ! log_has_line "$log" 'issue create --title Account security epic' ||
   ! log_has_line "$log" 'issue create --title Password policy' ||
   ! log_has_line "$log" 'issue create --title MFA enrollment' ||
   [ "$(line_count "$log")" -ne 3 ] ||
   ! case "$created" in *issues/100*) true ;; *) false ;; esac ||
   ! case "$created" in *issues/101*) true ;; *) false ;; esac ||
   ! case "$failed" in *'sub-issue 2: validation failed; retry this item only'*) true ;; *) false ;; esac; then
  printf '%s\n' 'FAIL: partial-failure evidence is incomplete' >&2
  exit 1
fi
printf '%s\n' 'assertion: log has epic, successful sub-issue, and failed sub-issue attempts'
printf '%s\n' 'assertion: retry report names only failed sub-issue 2'
printf '%s\n' 'partial command log:'
cat "$log"
printf '%s\n' 'harness raw command/output transcript (partial failure):'
cat "$transcript"

start_phase
export GH_SCENARIO=reference
printf '%s\n' 'reference phase: publish two issues, then reference source 300 to target 301'
if ! run_and_capture issue create --title 'Reference source'; then
  printf '%s\n' 'FAIL: source issue creation failed' >&2
  exit 1
fi
source_output=$(<"$root/last-output")
if ! run_and_capture issue create --title 'Reference target'; then
  printf '%s\n' 'FAIL: target issue creation failed' >&2
  exit 1
fi
target_output=$(<"$root/last-output")
if run_and_capture issue comment 300 --body 'Refs #301'; then
  printf '%s\n' 'FAIL: first reference unexpectedly succeeded' >&2
  exit 1
fi
reference_error=$(<"$root/last-output")
reference_report="failed-reference: source=$source_output target=$target_output error=$reference_error"
printf '%s\n' "$reference_report"
if ! run_and_capture issue comment 300 --body 'Refs #301'; then
  printf '%s\n' 'FAIL: reference-only retry failed' >&2
  exit 1
fi
printf '%s\n' 'reference retry: source=300 target=301; no issue recreation'
if [ "$(line_count "$log")" -ne 5 ] ||
   ! log_count_matching "$log" 2 'issue create' ||
   ! log_count_matching "$log" 2 'issue comment 300 --body Refs #301' ||
   ! log_has_line "$log" 'reference-failure source=300 target=301 error=reference service unavailable' ||
   ! file_contains "$transcript" 'reference target=301 source=300 error=reference service unavailable' ||
   ! case "$reference_report" in *'failed-reference: source=https://github.com/acme/demo/issues/300 target=https://github.com/acme/demo/issues/301'*) true ;; *) false ;; esac; then
  printf '%s\n' 'FAIL: failed-reference evidence is incomplete' >&2
  exit 1
fi
printf '%s\n' 'assertion: failed reference logs source, target, and error, then retries reference only'
printf '%s\n' 'reference command log:'
cat "$log"
printf '%s\n' 'harness raw command/output transcript (failed reference and retry):'
cat "$transcript"
