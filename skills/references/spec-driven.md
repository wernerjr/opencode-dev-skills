# Spec-Driven Fix Flow

1. SPEC: Restate the problem, acceptance criteria, out of scope, and risks.
2. CODE MAP: Identify files, entrypoints, and data flow with GitNexus when available.
3. DOMAIN: Extract business rules from code, the issue, and repository docs. Do not invent rules.
4. PLAN: List small implementation steps, files, and verification commands.
5. IMPLEMENT: Make the smallest useful diff. Apply YAGNI.
6. VERIFY: Run existing tests and add tests when the repository has a harness. Do not mark done if tests fail.
7. REPORT: Summarize the change, files, tests, and residual risk. Suggest an issue comment and pull request without opening one unless asked.
