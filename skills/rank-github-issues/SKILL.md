---
name: rank-github-issues
description: Use when listing, scoring, or ranking GitHub issues to decide what to fix next. Uses the gh CLI. Do not use for implementing a fix.
license: MIT
compatibility: opencode
metadata:
  workflow: github-issues
---

# Rank GitHub Issues

Run:

```bash
gh issue list --repo <owner/repo> --state open --limit 100 --json number,title,body,labels,comments,createdAt,updatedAt,author,assignees,reactionGroups,url
```

Honor requested filters such as `--label`, `--assignee`, `is:issue`, `is:open`, or search terms. Pipe the JSON into the script `rank-issues.mjs` (repo root `scripts/rank-issues.mjs`; when installed as an opencode package, resolve it from `node_modules/opencode-dev-skills/scripts/rank-issues.mjs` — it is NOT inside the skill folder). The script is the source of truth for deterministic ordering; do not invent a sort order.

Present a markdown table with `rank | # | score | type (SEC|CODE) | title | labels | short reason`. Recommend the top three with one sentence each, then stop and wait for a choice. Do not implement a fix.

Read `skills/references/ranking.md` for the exact formula and `skills/references/security-triage.md` for classification boundaries.
