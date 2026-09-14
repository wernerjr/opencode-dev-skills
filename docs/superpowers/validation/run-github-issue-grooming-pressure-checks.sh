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
elif [ "$GH_SCENARIO" = partial ]; then
  n=$(cat "$GH_STATE")
  printf '%s\n' "$((n + 1))" > "$GH_STATE"
  case "$n" in
    0) printf '%s\n' 'https://github.com/acme/demo/issues/100' ;;
    1) printf '%s\n' 'https://github.com/acme/demo/issues/101' ;;
    2) printf '%s\n' 'validation failed' >&2; exit 1 ;;
    *) printf '%s\n' 'unexpected write' >&2; exit 1 ;;
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
if grep -Eq '^(label create|issue create)' "$log"; then
  printf '%s\n' 'FAIL: pre-approval write detected' >&2
  exit 1
fi
printf '%s\n' 'assertion: pre-approval write log is empty'
printf '%s\n' 'approval phase: explicit approval received for label priority:high and issue 200'
run_and_capture label create 'priority:high'
run_and_capture issue create --title 'Approved issue'
if ! grep -Fxq 'label create priority:high' "$log" ||
   ! grep -Fxq "issue create --title Approved issue" "$log" ||
   [ "$(wc -l < "$log" | tr -d ' ')" -ne 2 ]; then
  printf '%s\n' 'FAIL: post-approval writes exceed approved scope' >&2
  exit 1
fi
printf '%s\n' 'assertion: post-approval log contains exactly the two approved writes'
printf '%s\n' 'approval command log:'
cat "$log"
printf '%s\n' 'harness raw command/output transcript (approval):'
cat "$transcript"

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
if ! grep -Fxq "issue create --title Account security epic" "$log" ||
   ! grep -Fxq "issue create --title Password policy" "$log" ||
   ! grep -Fxq "issue create --title MFA enrollment" "$log" ||
   [ "$(wc -l < "$log" | tr -d ' ')" -ne 3 ] ||
   ! printf '%b\n' "$created" | grep -Fq 'issues/100' ||
   ! printf '%b\n' "$created" | grep -Fq 'issues/101' ||
   ! printf '%b\n' "$failed" | grep -Fxq 'sub-issue 2: validation failed; retry this item only'; then
  printf '%s\n' 'FAIL: partial-failure evidence is incomplete' >&2
  exit 1
fi
printf '%s\n' 'assertion: log has epic, successful sub-issue, and failed sub-issue attempts'
printf '%s\n' 'assertion: retry report names only failed sub-issue 2'
printf '%s\n' 'partial command log:'
cat "$log"
printf '%s\n' 'harness raw command/output transcript (partial failure):'
cat "$transcript"
