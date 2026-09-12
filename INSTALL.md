# Install opencode-dev-skills

Use the remote git-backed plugin entry. Do not use `file:` URLs, a local plugin path, or a copied folder as the official installation method.

## Prerequisites

Install OpenCode and GitHub CLI, then authenticate GitHub:

```bash
gh auth login
```

## Installation

Edit the global `~/.config/opencode/opencode.json` so the plugin applies everywhere, or add the same entry to a project `opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": [
    "opencode-dev-skills@git+https://github.com/wernerjr/opencode-dev-skills.git"
  ]
}
```

Keep existing plugin entries. Restart OpenCode after editing the configuration.

Verify in a new session that the native skill tool lists:

- `dev-orchestrator`
- `rank-github-issues`
- `dispatch-issue-fix`
- `fix-security-issue`
- `fix-code-issue`

## Updates

The plugin checks GitHub on `session.created`. If `main` has a newer commit, it shows a warning with the commit SHA.

For a manual refresh, clear the package cache and restart:

```bash
rm -rf ~/.cache/opencode/node_modules/opencode-dev-skills
```

The exact cache directory may vary by OpenCode and Bun version. Clearing `~/.cache/opencode` is the broader fallback.

For automatic cache clearing when GitHub is ahead:

```bash
export OPENCODE_DEV_SKILLS_AUTO_UPDATE=1
```

The plugin only clears its cache; restart OpenCode to pull the new version. Bun/OpenCode may pin a git SHA in its cache, so a restart alone may not refresh a pushed commit.

To pin the initial tag:

```json
{
  "plugin": [
    "opencode-dev-skills@git+https://github.com/wernerjr/opencode-dev-skills.git#v0.1.0"
  ]
}
```

## Windows fallback

Keep `git+https` as the preferred path. If a Windows OpenCode build cannot install that URL, use npm as a fallback:

```powershell
npm install opencode-dev-skills@git+https://github.com/wernerjr/opencode-dev-skills.git --prefix "$HOME\.config\opencode"
```

Then point the plugin entry at the installed package path supported by that OpenCode build. This is a platform fallback, not the primary installation method.
