---
name: github-issue-grooming
description: Use when a user provides a list of GitHub improvements, bugs, ideas, or requests that must be grouped, prioritized, deduplicated, decomposed, or turned into detailed issues.
---

# GitHub Issue Grooming

Turn a free-form request into a reviewable, publishable issue plan. Preserve the
user's intent, do not invent requirements, and do not modify application code.

## Intake And Safety

1. First run `gh repo view --json nameWithOwner,url`, then `gh auth status`.
2. If either command fails, stop. Ask for the missing repository information or
   authentication; never guess the repository or present local-only output as
   published.
3. Assign stable temporary IDs such as `C1`, `C2` to normalized candidates.
   Preserve each candidate's original wording and explain any consolidation,
   omission, or ambiguity. Assign each ID once at intake and carry it unchanged
   through every plan revision, publication result, and retry; never renumber a
   candidate because its grouping or wording changes.

## Search And Classification

Before proposing new issues, run:

```bash
gh issue list --state open --limit 100 --json number,title,body,labels,url
```

Use targeted `gh issue view NUMBER --json number,title,body,labels,url` calls when
the list lacks context. Compare every candidate with existing issue titles,
labels, and bodies. Classify each match exactly as:

- `likely duplicate`: do not propose a new issue by default; include the issue
  URL and the matching reason.
- `related issue`: retain the candidate; include the issue URL and why it is
  related but distinct.
- `no meaningful match`: proceed as a new candidate.

Never treat an ambiguous match as a confirmed duplicate. If targeted views do
not resolve whether a candidate duplicates one or more existing issues, classify
it as an ambiguous duplicate and map it explicitly to `skipped-ambiguous`: do
not propose or publish it. Include the candidate, all possible issue URLs, and
the unresolved reason in the plan.

## Grouping And Labels

Group candidates by a concise lowercase theme or subsystem. A theme-level
initiative is an epic when it contains multiple independently verifiable tasks
or supplies shared scope. Make independently implementable and acceptable work
sub-issues of that epic. Keep truly independent work as standalone issues. State
dependencies, including epic-before-sub-issue and task-to-task dependencies.

Every published item must have these labels:

```text
type:<feature|bug|chore|refactor|documentation|security|research>
theme:<lowercase-theme>
complexity:<small|medium|large>
priority:<critical|high|medium|low>
```

Inspect the repository's existing labels before finalizing the plan, compare
names exactly, and mark each required label as `reuse` or `create`. Existing
labels are reused and must never receive a second `gh label create` request.
List missing labels and create them only after approval. Label colors must be
stable by namespace, and missing-label creation must be idempotent.

## Approval Gate

Present a plan before any write. It must contain epics and their rationale,
sub-issues, standalone issues, grouping, dependencies, classifications,
priority and complexity rationale, labels to create or reuse, likely duplicates,
related issues, and the exact publication scope (including what is excluded).

Wait for **explicit approval** of the current plan. A rejection or requested
revision withdraws any earlier approval: show the revised plan with the same
candidate IDs and wait for explicit approval of that exact revised scope.
Before final approval, every GitHub command and API call
must be read-only. Do not run any mutating command or request, including `gh
label create`, label edits or deletes, `gh issue create`, `gh issue edit`, issue
deletes or closes, comments, or issue references (whether made with `gh api` or
another `gh` subcommand). No mutation is allowed merely to probe, prepare,
link, or validate a plan. Stop before publication if high-impact ambiguity
remains unresolved.

## Issue Body Contract

Every published issue uses these sections in this exact order:

```markdown
## Context
## Problem or opportunity
## Objective
## Scope
## Out of scope
## Implementation direction
## Acceptance criteria
## Expected tests
## Dependencies
## Classification
## Related issues
```

Fill every applicable section. If a section is genuinely inapplicable, omit it
only with a stated reason. Acceptance criteria must be observable and testable:
describe behavior or verifiable artifacts, not vague goals such as "improve".
Repeat the classifications in the body, and include epic and related-issue
references where applicable.

## Publication And Reporting

After approval, execute exactly this order:

1. Create missing labels.
2. Create epics.
3. Create sub-issues and standalone issues.
4. Add issue references using GitHub issue references.
5. Report URLs.

Track results in separate groups: `created`, `failed`, `failed-reference`,
`skipped-duplicate`, `skipped-ambiguous`, and `skipped-dependency`. A failed
command is never successful. If missing-label creation fails, mark the label failed and skip
every item that requires it as `skipped-dependency`; do not publish those items.
If an epic creation fails, mark the epic failed and skip all dependent
sub-issues as `skipped-dependency`; independent standalone issues may proceed
only if their own prerequisites succeeded. Report the prerequisite and reason
for every dependency skip.

Give every candidate and publication item a stable retry identity, such as its
temporary candidate ID plus `epic`, `sub-issue`, or `standalone` role. Retain
that identity, every created issue number and URL, and each failed prerequisite
in the report. Retry only failed items and dependency-skipped items whose
prerequisites now succeed; never retry or recreate a `created` item, and never
silently turn a dependency skip into a success. If adding a reference fails
after both issues were created, retain both items in `created`, record the
source, target, failed command, and error in `failed-reference`, and do not
claim that the link exists. Retry only that reference using its candidate and
`reference` role identity; never recreate either issue.

## Worked Example

Raw request: "Add password policy and MFA, with security docs."

Plan: epic `Account security` (`type:feature`, `theme:account-security`,
`complexity:large`, `priority:high`), plus two sub-issues:

- `Password policy`: `type:feature`, `theme:account-security`,
  `complexity:medium`, `priority:high`; acceptance: rejected passwords produce
  a documented validation error and policy tests pass.
- `MFA enrollment`: same theme and priority, `complexity:large`; acceptance:
  enrollment succeeds with a verified second factor and integration tests cover
  recovery; dependency: `Password policy`.

The body records the security documentation in scope and links both sub-issues
to the epic. Ask for explicit approval of this one-epic/two-sub-issue scope and
its labels before creating missing labels or issues.

## Common Mistakes

- Guessing repository identity or continuing after `gh auth status` fails.
- Publishing before approval, including "just" labels.
- Collapsing independently verifiable work into one issue instead of an epic.
- Calling a related or ambiguous issue a duplicate.
- Reporting a failed create as successful or losing URLs from partial publication.
