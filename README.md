# opencode-dev-skills

An OpenCode plugin for issue-driven development:

1. `dev-orchestrator` confirms the repository and starts the workflow.
2. `rank-github-issues` uses `gh` and a deterministic zero-dependency scorer.
3. `dispatch-issue-fix` routes the selected issue to security or code work.
4. The fix skill uses optional GitNexus for graph evidence and optional Superpowers for disciplined implementation.
5. Without those optionals, the skills use a compact spec-driven fallback.

The plugin registers its bundled `skills/` directory through the OpenCode config hook. It does not require a local symlink or copying folders into a global skills directory.

## Prerequisites

- A recent OpenCode release
- Git
- Authenticated GitHub CLI: `gh auth login`

Optional integrations:

- GitNexus: `npx gitnexus analyze` plus its OpenCode MCP setup
- Superpowers: `superpowers@git+https://github.com/obra/superpowers.git`

## Install

Follow [INSTALL.md](INSTALL.md) for the remote git-backed install. Restart OpenCode after changing configuration.

## Usage

Ask OpenCode:

- "Triage the issues in this repository."
- "Rank the issues and fix #42."
- "Take the most critical security issue."

The orchestrator waits for a selection before changing application code unless the request explicitly names an issue or asks for the top issue.

## Ranking Script

The ranking script reads an issue array from stdin and writes JSON to stdout:

```bash
printf '%s' '[
  {"number":1,"title":"Fix crash","labels":[{"name":"bug"}],"comments":[],"reactionGroups":[]},
  {"number":2,"title":"Possible XSS","labels":[{"name":"security"}],"comments":[],"reactionGroups":[]},
  {"number":3,"title":"Improve docs","labels":[{"name":"enhancement"}],"comments":[],"reactionGroups":[]}
]' | node scripts/rank-issues.mjs
```

The expected order is issue 2, issue 1, then issue 3 because security receives the highest base priority.

## Updates

After a git push, the plugin checks `main` at session start and reports when GitHub is ahead. Clear the OpenCode plugin cache and restart to refresh a pinned Bun/OpenCode git SHA. See [INSTALL.md](INSTALL.md) for manual, automatic, and pinned update options.
