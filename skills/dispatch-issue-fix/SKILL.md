---
name: dispatch-issue-fix
description: Use after the user selects a GitHub issue to fix. Routes security issues to fix-security-issue and all other issues to fix-code-issue. Do not implement the fix yourself.
license: MIT
compatibility: opencode
metadata:
  workflow: github-issues
---

# Dispatch Issue Fix

Receive the selected issue context: repository, number, URL, title, labels, body, cited files, and acceptance criteria. Re-validate whether it is security-related using `skills/references/security-triage.md`.

- Security issue: load `fix-security-issue`.
- Other issue: load `fix-code-issue`.

Pass compact context. Trim the body to 4,000 characters. Do not duplicate the child skill's investigation or implementation work.
