---
name: dev-orchestrator
description: Use when the user wants to triage, rank, pick, or fix GitHub issues in the current repo or a named repo; development skill orchestrator; start here for issue-driven coding.
license: MIT
compatibility: opencode
metadata:
  workflow: github-issues
---

# Development Orchestrator

Start here for issue-driven work.

1. Confirm the repository with `gh repo view --json nameWithOwner,url` in the current directory. If it fails, ask for `owner/repo`.
2. Run `gh auth status`. If unauthenticated, stop and tell the user to run `gh auth login`.
3. Load `rank-github-issues`.
4. Show the deterministic numbered ranking and ask the user to choose by index, issue number, or top issue.
5. After the choice, load `dispatch-issue-fix` with the repository, number, title, labels, body, and URL.

Do not change application code before the user chooses, unless the user explicitly requested a specific issue or the top issue. Keep the todo list visible and do not jump to implementation.

Read `skills/references/ranking.md` or `skills/references/security-triage.md` only when needed.
