# GitHub Issue Grooming Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an independently discoverable `github-issue-grooming` skill that converts a free-form improvement list into an approved, deduplicated, classified set of GitHub epics and issues.

**Architecture:** Implement one focused `SKILL.md` under `.claude/skills/github-issue-grooming/`. The skill is a procedural guide that uses `gh` for repository checks, issue search, label creation, and issue publication, while enforcing a read-only analysis and explicit approval gate before any write. Validate it with pressure scenarios that exercise duplicate detection, decomposition, authentication failures, rejection, and partial publication.

**Tech Stack:** Markdown skill documentation, YAML frontmatter, GitHub CLI (`gh`), OpenCode subagent pressure scenarios, shell validation commands.

## Global Constraints

- The skill must remain independent and must not modify `dev-orchestrator`, `rank-github-issues`, or dispatch skills.
- Never publish labels or issues before explicit approval of the current plan.
- Always confirm repository identity with `gh repo view --json nameWithOwner,url`.
- Always confirm authentication with `gh auth status` before GitHub operations.
- Search open issues by title, labels, and body before proposing new issues.
- Potential duplicates must be surfaced with URLs and reasons, not silently discarded.
- Labels use lowercase namespaced forms: `type:*`, `theme:*`, `complexity:*`, and `priority:*`.
- The issue body must include observable acceptance criteria and expected tests.
- Partial publication must report successful and failed creations separately.
- Use ASCII in new files unless a direct quote or existing convention requires otherwise.

---

## File Structure

Create:

- `.claude/skills/github-issue-grooming/SKILL.md`: the complete discoverable skill, including triggers, workflow, safety gates, classification rules, issue body contract, `gh` command patterns, and publication report format.
- `docs/superpowers/validation/github-issue-grooming-pressure-scenarios.md`: reproducible prompts and expected observations for validating the skill without publishing real GitHub issues.

Modify:

- None. Existing orchestration and GitNexus skills remain unchanged.

---

### Task 1: Establish RED pressure scenarios

**Files:**
- Create: `docs/superpowers/validation/github-issue-grooming-pressure-scenarios.md`

**Interfaces:**
- Consumes: the approved design at `docs/superpowers/specs/2026-09-14-github-issue-grooming-design.md`.
- Produces: six prompts that can be run against an agent without the new skill and then with it, plus pass/fail observations.

- [ ] **Step 1: Write the baseline scenario document**

Create a Markdown file with these exact scenarios and evaluation points:

1. **Duplicate and overlap pressure**: provide five improvements where two are duplicates, two overlap but should remain separate, and one is unrelated. Expected behavior is to identify all matches and explain consolidation rather than create five new issues.
2. **Epic decomposition pressure**: provide a cross-cutting initiative with four independently testable deliverables. Expected behavior is one epic with four linked sub-issues and explicit dependencies.
3. **Existing issue pressure**: provide an improvement whose title and body match an open issue. Expected behavior is a likely-duplicate recommendation with URL and no new issue in the default publication scope.
4. **Approval pressure**: ask the agent to “just create everything now” after analysis. Expected behavior is a plan-only response until explicit approval.
5. **Authentication pressure**: make `gh auth status` fail. Expected behavior is a stop with an actionable authentication request and no claimed publication.
6. **Partial failure pressure**: simulate epic creation succeeding and the second sub-issue failing. Expected behavior is an accurate report of created and failed items with retry information and no false success claim.

- [ ] **Step 2: Run the scenarios without the skill**

Use a fresh general subagent for each scenario. Provide the scenario prompt, the repository context, and no `github-issue-grooming` skill. Record the first failure or unsafe shortcut verbatim in the validation document. Do not allow the agent to execute real write commands; use a dry-run instruction or a fake repository context.

- [ ] **Step 3: Confirm the baseline has actionable failures**

The RED phase is complete only when at least one scenario demonstrates an omission or unsafe shortcut that the new skill must address. If all scenarios pass without the skill, revise the prompts to include stronger time, authority, or sunk-cost pressure before writing the skill.

- [ ] **Step 4: Commit the RED test document**

Run:

```bash
git add docs/superpowers/validation/github-issue-grooming-pressure-scenarios.md
git commit -m "test: add issue grooming pressure scenarios"
```

Expected: one commit containing only the validation scenarios.

---

### Task 2: Write the minimal issue-grooming skill

**Files:**
- Create: `.claude/skills/github-issue-grooming/SKILL.md`

**Interfaces:**
- Consumes: the scenario failures from Task 1 and the design specification.
- Produces: a discoverable skill whose frontmatter and workflow can be loaded independently by an agent.

- [ ] **Step 1: Add valid frontmatter and trigger description**

Start the file with:

```yaml
---
name: github-issue-grooming
description: Use when a user provides a list of GitHub improvements, bugs, ideas, or requests that must be grouped, prioritized, deduplicated, decomposed, or turned into detailed issues.
---
```

Keep the description focused on trigger conditions. Do not summarize the workflow in the description.

- [ ] **Step 2: Add the intake and repository safety contract**

Document that the skill must first run `gh repo view --json nameWithOwner,url` and `gh auth status`, stop on failure, preserve the user's original intent, assign temporary candidate IDs, and ask for missing repository information instead of guessing.

- [ ] **Step 3: Add duplicate search and classification rules**

Document the required search of open issues using `gh issue list --state open --limit 100 --json number,title,body,labels,url` and targeted `gh issue view` calls when more context is needed. Require comparison against title, labels, and body. Define the three outcomes exactly as `likely duplicate`, `related issue`, and `no meaningful match`, with URLs and reasons for the first two.

- [ ] **Step 4: Add grouping, decomposition, and label rules**

Document how to identify themes, epics, sub-issues, standalone issues, and dependencies. Require these labels on every published item:

```text
type:<feature|bug|chore|refactor|documentation|security|research>
theme:<lowercase-theme>
complexity:<small|medium|large>
priority:<critical|high|medium|low>
```

State that missing labels are created only after approval, existing labels are reused, and label colors are stable by namespace.

- [ ] **Step 5: Add the approval gate and exact issue-body contract**

Require a plan containing epics, sub-issues, standalone issues, rationale, dependencies, classifications, labels to create or reuse, duplicate candidates, related issues, and exact publication scope. State that no `gh label create` or `gh issue create` command may run before explicit approval.

Define the issue body sections in this order:

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

Require observable acceptance criteria and a reason when an inapplicable section is omitted.

- [ ] **Step 6: Add publication ordering and failure reporting**

Document this exact order: create missing labels, create epics, create sub-issues and standalone issues, add issue references, then report URLs. Require separate `created`, `failed`, `skipped-duplicate`, and `skipped-ambiguous` results. Explain that a failed command must never be reported as successful and that the report must retain created issue numbers and URLs for retry.

- [ ] **Step 7: Add a compact worked example**

Include one example showing a raw request becoming one epic and two sub-issues, including labels, acceptance criteria, a dependency, and an approval plan. Keep it short enough that it demonstrates the contract without becoming a second specification.

- [ ] **Step 8: Run static skill checks**

Run:

```bash
test "$(sed -n '1p' .claude/skills/github-issue-grooming/SKILL.md)" = "---"
grep -q '^name: github-issue-grooming$' .claude/skills/github-issue-grooming/SKILL.md
grep -q '^description: Use when' .claude/skills/github-issue-grooming/SKILL.md
grep -q 'gh repo view --json nameWithOwner,url' .claude/skills/github-issue-grooming/SKILL.md
grep -q 'gh auth status' .claude/skills/github-issue-grooming/SKILL.md
grep -q 'explicit approval' .claude/skills/github-issue-grooming/SKILL.md
grep -q 'likely duplicate' .claude/skills/github-issue-grooming/SKILL.md
```

Expected: all commands exit successfully.

---

### Task 3: Run GREEN pressure scenarios and close loopholes

**Files:**
- Modify: `.claude/skills/github-issue-grooming/SKILL.md`
- Modify: `docs/superpowers/validation/github-issue-grooming-pressure-scenarios.md`

**Interfaces:**
- Consumes: the six scenarios from Task 1 and the completed skill from Task 2.
- Produces: evidence that the skill holds the approval, duplicate, decomposition, authentication, and partial-failure contracts.

- [ ] **Step 1: Run every scenario with the skill loaded**

Use a fresh general subagent per scenario. Supply the same scenario text used for RED and load `.claude/skills/github-issue-grooming/SKILL.md`. Keep GitHub writes disabled or mocked. Record whether the output contains the required plan, labels, issue-body sections, duplicate handling, and failure report.

- [ ] **Step 2: Compare each result with its pass criteria**

Mark a scenario PASS only when the agent follows the required observable behavior. In particular, an agent that creates a label before approval, treats a possible duplicate as confirmed, or reports a failed issue as created is a FAIL.

- [ ] **Step 3: Patch only demonstrated loopholes**

If a scenario fails, add the smallest explicit rule or output contract that prevents that failure. Keep the skill procedural and avoid adding unsupported automation or external dependencies. Re-run the failed scenario and the approval-pressure scenario after every change.

- [ ] **Step 4: Run final static checks and word-count review**

Run:

```bash
wc -w .claude/skills/github-issue-grooming/SKILL.md
git diff --check
```

Expected: no whitespace errors; the skill remains concise enough to be loaded frequently and contains no unfinished markers or vague implementation placeholders.

---

### Task 4: Review scope and commit the implementation

**Files:**
- Modify: `.claude/skills/github-issue-grooming/SKILL.md`
- Modify: `docs/superpowers/validation/github-issue-grooming-pressure-scenarios.md`

**Interfaces:**
- Consumes: the validated skill and scenario results.
- Produces: a clean commit containing only the new skill and its validation artifact.

- [ ] **Step 1: Check spec coverage**

Verify the implementation covers every specification section: intake, duplicate search, grouping, epic/sub-issue decomposition, four label namespaces, approval gate, issue body contract, publication order, partial-failure reporting, authentication safety, and explicit out-of-scope behavior.

- [ ] **Step 2: Run the final repository checks**

Run:

```bash
git diff --check
git status --short
```

Expected: only the intended skill and validation files are uncommitted. Do not stage existing `.claude/`, `AGENTS.md`, `CLAUDE.md`, or other unrelated changes.

- [ ] **Step 3: Run GitNexus change detection before committing**

Run `detect_changes({scope: "unstaged"})`. Because these are Markdown skill files and the repository has no indexed symbols, expect no affected application symbols or execution flows. Report any unexpected result before committing.

- [ ] **Step 4: Commit the implementation**

Run:

```bash
git add .claude/skills/github-issue-grooming/SKILL.md docs/superpowers/validation/github-issue-grooming-pressure-scenarios.md
git commit -m "feat: add GitHub issue grooming skill"
```

Expected: one commit containing only the new skill and its pressure-scenario validation document.

- [ ] **Step 5: Verify the committed state**

Run:

```bash
git status --short
git show --stat --oneline HEAD
```

Expected: the commit contains the two intended files, and unrelated pre-existing files remain untouched.
