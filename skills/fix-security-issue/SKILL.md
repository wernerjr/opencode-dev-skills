---
name: fix-security-issue
description: Use when fixing a security vulnerability, CVE, injection, XSS, auth bypass, secret leak, insecure deserialization, or any issue labeled security or sec. Prefer GitNexus if available. Prefer Superpowers if available; otherwise use spec-driven development.
license: MIT
compatibility: opencode
metadata:
  workflow: secure-github-fix
---

# Fix Security Issue

Detect capabilities quietly with `scripts/detect-capabilities.mjs` and record `gitnexus=yes/no` and `superpowers=yes/no`.

If GitNexus is available, read `skills/references/gitnexus.md`, use graph tools before blind search, and run impact analysis before editing symbols. If unavailable, use `grep`, `glob`, and `read` without pretending a graph exists. Do not install GitNexus unless asked.

If Superpowers is available, read `skills/references/superpowers.md` and use the applicable flow. Otherwise follow `skills/references/spec-driven.md`.

Security requirements:

- Prefer structural fixes such as parameterized queries, server-side authorization, and output encoding.
- Never log or commit secrets, `.env` files, keys, or tokens.
- Check the blast radius and search for sibling copies of the unsafe API after the fix.
- Do not expand a proof of concept for a still-exploitable production vulnerability beyond what the fix requires.

Use branch `sec/issue-<n>-<slug>` and a conventional commit beginning `fix(sec):`.

Report the threat, affected surface, fix, verification steps, and residual risk. Suggest an issue comment and pull request, but do not open a pull request unless asked.
