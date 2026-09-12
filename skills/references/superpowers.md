# Superpowers Guidance

Detect the skills `brainstorming`, `writing-plans`, `test-driven-development`, `systematic-debugging`, `verification-before-completion`, `subagent-driven-development`, and `using-git-worktrees`.

For bugs, use systematic debugging; for features, use brainstorming. Then use writing-plans, an isolating worktree when available, test-driven development, subagent-driven development for substantial multi-file work, and verification-before-completion. Use only the skills that apply. If only a subset exists, use that subset and fill the gaps with `spec-driven.md`.

OpenCode mappings: todos to `todowrite`, subagents to `task` with `subagent_type` `general` or `explore`, skills to the native skill tool, reads to `read`, edits to `apply_patch`, shell to `bash`, searches to `grep` and `glob`, and URLs to `webfetch`.
