# Issue Ranking Formula

The ranking script is deterministic. For every issue, start at zero and add:

- Security label or security pattern: `+100`, and set `is_security=true`.
- Labels `bug`, `defect`, or `crash`: `+40`.
- Labels `p0`, `critical`, or `blocker`: `+50`; `p1` or `high`: `+30`; `p2` or `medium`: `+10`.
- `good first issue`: `+5` as a tie-break contribution.
- Two points per comment.
- One point per reaction.
- Open more than 14 days with no update: `+10`.
- Assigned to someone: `-15`, unless the user requested their own issues.
- `enhancement` or `chore` without a bug signal: `-10`.

Sort by descending score, then security before non-security at equal score, then ascending issue number. Security classification requires a security label or a concrete vulnerability keyword. A phrase such as "security team" or "security meeting" is not security by itself.
