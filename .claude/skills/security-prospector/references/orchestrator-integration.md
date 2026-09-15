# dev-orchestrator integration

`dev-orchestrator` (in the `opencode-dev-skills` package) gains a
security-verification branch that loads `security-prospector` when the user
asks to verify or scan security issues, before running `rank-github-issues`.

The copy installed via npm (`node_modules/opencode-dev-skills`) is patched in
place so the branch is live locally. That cache is ephemeral: the durable change
belongs in the `wernerjr/opencode-dev-skills` repository. Open a pull request
adding the same step to `skills/dev-orchestrator/SKILL.md`:

```markdown
3. If the user asked to verify, scan, or register security issues, load
   `security-prospector` and hand over the repository context; then stop until
   the user chooses a published issue.
4. Otherwise load `rank-github-issues`.
```

After merging and reinstalling, the patch here and the upstream file must
match; re-check with `git diff` against the upstream file.
