# GitHub Issue Grooming

## Objective

Create an independent skill that turns a free-form list of improvements, bugs, ideas, or requests into a reviewed and publishable set of GitHub issues. The skill prepares the work for `dev-orchestrator`, which remains responsible for ranking existing issues and dispatching selected work to the appropriate implementation skill.

## Scope

The skill will:

- accept a user-provided list of improvements;
- normalize and consolidate overlapping entries;
- search open GitHub issues for likely duplicates or related work;
- group work by theme or subsystem;
- identify dependencies and distinguish epics from implementable tasks;
- classify items by type, theme, complexity, and priority;
- produce a publication plan for user approval;
- create missing labels with a consistent naming scheme;
- create approved epics before their sub-issues;
- link sub-issues to epics and related issues;
- publish a summary with URLs, duplicate candidates, and skipped items.

The skill will not modify application code, choose an implementation issue without user approval, or silently publish a plan that has not been approved.

## Location and Integration

The skill will live at:

`.claude/skills/github-issue-grooming/SKILL.md`

It will be independently discoverable and reusable. `dev-orchestrator` may reference it later, but the first implementation will not modify `dev-orchestrator` itself.

The workflow will use the GitHub CLI:

1. `gh repo view --json nameWithOwner,url` confirms the target repository.
2. `gh auth status` confirms that publishing is possible.
3. `gh issue list` and `gh issue view` provide existing issue context.
4. `gh label create` creates missing labels after approval.
5. `gh issue create` publishes epics and sub-issues.

If repository discovery or authentication fails, the skill stops and requests the missing information rather than guessing or creating local-only output as if it were published.

## Workflow

### 1. Intake and normalization

Parse the user's list into distinct candidate items. Preserve the original intent, remove only obvious repetition, and flag ambiguity instead of inventing requirements. Each candidate receives a stable temporary identifier for the review plan.

### 2. Existing-issue analysis

Search open issues before proposing new ones. Compare candidates against issue titles, labels, and bodies. Results are classified as:

- likely duplicate: do not include as a new issue by default;
- related issue: retain as a new candidate with a link and explanation;
- no meaningful match: continue as a new candidate.

Potential duplicates must appear in the approval plan, including the matching issue URL and the reason for the match.

### 3. Decomposition and classification

Group candidates by theme or subsystem and identify dependencies. A theme-level initiative becomes an epic when it contains multiple independently verifiable tasks or establishes shared scope for those tasks. Tasks that can be implemented and accepted independently become sub-issues. Truly standalone work remains an independent issue.

Every proposed issue receives these classifications:

- `type:*`: feature, bug, chore, refactor, documentation, security, or research;
- `theme:*`: a concise subsystem or domain name;
- `complexity:*`: `small`, `medium`, or `large`;
- `priority:*`: `critical`, `high`, `medium`, or `low`.

The classifications are repeated in the issue body so the issue remains understandable without labels.

### 4. Approval plan

Before any write operation, present:

- proposed epics and their rationale;
- proposed sub-issues and standalone issues;
- grouping and dependency relationships;
- labels to be created or reused;
- priority and complexity reasoning;
- duplicate and related-issue candidates;
- the exact publication scope.

The user must explicitly approve the plan. The skill may revise the plan after feedback, but it must not create labels or issues before approval.

### 5. Publication

After approval:

1. create only missing labels;
2. create approved epics first;
3. create sub-issues and standalone issues;
4. include epic and related-issue URLs in each applicable body;
5. use GitHub issue references so links remain navigable;
6. report successful creations and any individual failures.

Partial publication must be reported precisely. A failed issue creation must not be represented as successful, and the skill should provide enough information to retry without duplicating successfully created issues.

## Issue Body Contract

Each published issue will use these sections, omitting only sections that are genuinely inapplicable and explicitly noting why:

- **Context**
- **Problem or opportunity**
- **Objective**
- **Scope**
- **Out of scope**
- **Implementation direction**
- **Acceptance criteria**
- **Expected tests**
- **Dependencies**
- **Classification**
- **Related issues**

Acceptance criteria must be observable and testable. They must describe behavior or verifiable artifacts, not vague intentions such as “improve” or “handle correctly.”

## Label Policy

Labels use lowercase, namespaced names with a colon:

- `type:*`
- `theme:*`
- `complexity:*`
- `priority:*`

The skill creates missing labels only after approval. Label creation should be idempotent: an existing label is reused, not recreated. Suggested colors should be stable by namespace so labels remain visually consistent across runs.

## Error Handling and Safety

- Never publish without explicit approval of the current plan.
- Never treat an ambiguous match as a confirmed duplicate.
- Never silently discard user input; explain consolidation and omission decisions.
- Never assume authentication or repository identity.
- Preserve created URLs and IDs during a partial failure.
- Stop before publication if the plan contains unresolved high-impact ambiguity.

## Validation Strategy

The skill should be tested with pressure scenarios covering:

- a list containing duplicates and overlapping requirements;
- a large request that must become an epic and several sub-issues;
- an existing issue that is a likely duplicate;
- missing labels and already-existing labels;
- an unauthenticated GitHub CLI;
- a failure after the epic is created but before all sub-issues are published;
- a user rejecting or revising the proposed plan.

The expected result is a deterministic, reviewable plan before writes and an accurate publication report after writes.

## Out of Scope for the First Version

- automatically assigning issues to users;
- adding issues to GitHub Projects;
- generating implementation code;
- editing existing issues beyond adding references when explicitly approved;
- semantic embeddings or external similarity services;
- changing `dev-orchestrator`, `rank-github-issues`, or dispatch skills.
