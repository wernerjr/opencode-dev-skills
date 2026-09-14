---
name: fix-code-issue
description: Use when fixing a non-security GitHub issue such as a bug, regression, feature, chore, or refactor. Prefer GitNexus if available. Prefer Superpowers if available; otherwise use spec-driven development.
license: MIT
compatibility: opencode
metadata:
  workflow: code-github-fix
---

# Fix Code Issue

Detect capabilities quietly with `scripts/detect-capabilities.mjs` and record `gitnexus=yes/no` and `superpowers=yes/no`.

If GitNexus is available, read `skills/references/gitnexus.md`, use graph tools before blind search, and run impact analysis before editing symbols. If unavailable, use `grep`, `glob`, and `read` without pretending a graph exists. Do not install GitNexus unless asked.

If Superpowers is available, read `skills/references/superpowers.md` and use the applicable flow. Otherwise follow `skills/references/spec-driven.md`.

Use branch `fix/issue-<n>-<slug>` and a conventional commit beginning `fix:`. Implement the smallest correct diff, add or update tests when the repository has a test harness, run the project's verification command, and do not mark the task complete while tests fail.

Report the summary, changed files, verification commands and results, and residual risk. Do not close the issue yourself.

Required final step — after the report, ask the user to choose exactly one of:
1. Open a pull request linked to the issue — put `Closes #N` in the PR body so the issue auto-closes on merge.
2. Merge directly to the base branch and close the issue automatically.

Act (open the PR or merge and close) only after the user answers.
