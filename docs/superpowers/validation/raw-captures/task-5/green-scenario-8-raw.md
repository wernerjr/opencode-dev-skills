# Green Scenario 8 Raw Capture - Partial publication failure

Verbatim session: intake, plan, and publish of eleven SQL-injection findings against the mandatory local `gh` mock in acme/demo (issue create fails when the full argument string matches `*second*`). Recorded here: full command transcript + mock command log (GH_LOG), replayed from the original run sources.

## Session transcript (commands and recorded output)

### publish step 1: label create type:security
> gh label create type:security
created
exit=0
### publish step 1: label create security
> gh label create security
created
exit=0
### publish step 1: label create severity:critical
> gh label create severity:critical
created
exit=0
### publish step 1: label create priority:critical
> gh label create priority:critical
created
exit=0
### publish step 1: label create theme:sql-injection
> gh label create theme:sql-injection
created
exit=0
### publish step 1: label create complexity:small
> gh label create complexity:small
created
exit=0
### publish step 1: label create complexity:large
> gh label create complexity:large
created
exit=0
### publish step 2: create epic E1 (issue create #1)
> gh issue create --title Epic: SQL-injection cluster in repo, db and search handlers --body ## Threat
SQL injection cluster: eleven reachable string-built SQL queries across src/repo.ts, src/db.ts, src/search.ts feed one HTTP handler. Category sql-injection, severity critical, confidence high. State at fix time: possible vulnerability -- verify.
## Affected surface
src/repo.ts:11,24,41,63; src/db.ts:22,35,52,78; src/search.ts:18,47,66; shared HTTP handler entry point.
## Evidence / Reproduction
Mocked GitNexus explain returns eleven sql-injection source-to-sink findings, all reachable from the same handler. Representative evidence: db.query built by string concatenation of the owner parameter.
## Impact
Request-controlled values flow into query text; attacker-controllable WHERE, ORDER BY, INSERT and DELETE clauses.
## Severity
Category sql-injection; severity critical; priority critical. Labels type:security, security, severity:critical, priority:critical, theme:sql-injection, complexity:large.
## Implementation direction
Replace every string-built query with parameterized queries behind one shared helper; each sub-issue tracks one file:line.
## Acceptance criteria
No string-built SQL remains in the affected handlers; regression payloads return no rows.
## Expected tests
Per-sub-issue regression tests on each affected query.
## Related issues
Sub-issues S1..S11 (planned, one per finding). --label type:security --label security --label severity:critical --label priority:critical --label theme:sql-injection --label complexity:small --label complexity:large
https://github.com/acme/demo/issues/100
exit=0
### publish step 3: create sub-issue S1 (issue create #2, expected failed)
> gh issue create --title SQL injection in fetchDashboard (src/db.ts:22) --body ## Threat
SQL injection in src/db.ts:22 fetchDashboard hour filter. Category sql-injection, severity critical, confidence high. Possible vulnerability -- verify.
## Affected surface
src/db.ts:22; fetchDashboard; HTTP handler.
## Evidence / Reproduction
db.query built by string concatenation of the hour parameter. This is the second of the eleven string-built queries in the cluster.
## Impact
SQL injection through the hour parameter.
## Severity
Category sql-injection; severity critical; priority critical. Labels type:security, security, severity:critical, priority:critical, theme:sql-injection, complexity:small.
## Implementation direction
Parameterize the hour filter in fetchDashboard.
## Acceptance criteria
fetchDashboard uses a parameterized query; payload OR 1=1 returns no rows.
## Expected tests
Regression test for payload OR 1=1.
## Related issues
Epic E1; prerequisite for sub-issue S2 (logScanEvent reuses the same insert helper). --label type:security --label security --label severity:critical --label priority:critical --label theme:sql-injection --label complexity:small
HTTP 422: mock delivery failure
exit=1
### publish step 3: sub-issue S2 (db.ts:35) skipped-dependency: no gh issue create issued (prerequisite S1 failed)
### publish step 3: create sub-issue S3 (issue create #4)
> gh issue create --title SQL injection in pruneOldRows (src/db.ts:52) --body ## Threat
SQL injection in SQL injection in pruneOldRows (src/db.ts:52). Category sql-injection, severity critical, confidence high. Possible vulnerability -- verify.
## Affected surface
SQL injection in pruneOldRows (src/db.ts:52); HTTP handler.
## Evidence / Reproduction
db.query built by string concatenation of a request-controlled value.
## Impact
SQL injection via the request-controlled value.
## Severity
Category sql-injection; severity critical; priority critical.
## Implementation direction
Parameterize the concatenated value in this query.
## Acceptance criteria
Query is parameterized; payload OR 1=1 returns no rows.
## Expected tests
Regression test for payload OR 1=1.
## Related issues
Epic E1. --label type:security --label security --label severity:critical --label priority:critical --label theme:sql-injection --label complexity:small
https://github.com/acme/demo/issues/100
exit=0
### publish step 3: create sub-issue S4 (issue create #5)
> gh issue create --title SQL injection in aggregateByOwner (src/db.ts:78) --body ## Threat
SQL injection in SQL injection in aggregateByOwner (src/db.ts:78). Category sql-injection, severity critical, confidence high. Possible vulnerability -- verify.
## Affected surface
SQL injection in aggregateByOwner (src/db.ts:78); HTTP handler.
## Evidence / Reproduction
db.query built by string concatenation of a request-controlled value.
## Impact
SQL injection via the request-controlled value.
## Severity
Category sql-injection; severity critical; priority critical.
## Implementation direction
Parameterize the concatenated value in this query.
## Acceptance criteria
Query is parameterized; payload OR 1=1 returns no rows.
## Expected tests
Regression test for payload OR 1=1.
## Related issues
Epic E1. --label type:security --label security --label severity:critical --label priority:critical --label theme:sql-injection --label complexity:small
https://github.com/acme/demo/issues/100
exit=0
### publish step 3: create sub-issue S5 (issue create #6)
> gh issue create --title SQL injection in listRepos owner filter (src/repo.ts:11) --body ## Threat
SQL injection in SQL injection in listRepos owner filter (src/repo.ts:11). Category sql-injection, severity critical, confidence high. Possible vulnerability -- verify.
## Affected surface
SQL injection in listRepos owner filter (src/repo.ts:11); HTTP handler.
## Evidence / Reproduction
db.query built by string concatenation of a request-controlled value.
## Impact
SQL injection via the request-controlled value.
## Severity
Category sql-injection; severity critical; priority critical.
## Implementation direction
Parameterize the concatenated value in this query.
## Acceptance criteria
Query is parameterized; payload OR 1=1 returns no rows.
## Expected tests
Regression test for payload OR 1=1.
## Related issues
Epic E1. --label type:security --label security --label severity:critical --label priority:critical --label theme:sql-injection --label complexity:small
https://github.com/acme/demo/issues/100
exit=0
### publish step 3: create sub-issue S6 (issue create #7)
> gh issue create --title SQL injection in sortRepos ORDER BY (src/repo.ts:24) --body ## Threat
SQL injection in SQL injection in sortRepos ORDER BY (src/repo.ts:24). Category sql-injection, severity critical, confidence high. Possible vulnerability -- verify.
## Affected surface
SQL injection in sortRepos ORDER BY (src/repo.ts:24); HTTP handler.
## Evidence / Reproduction
db.query built by string concatenation of a request-controlled value.
## Impact
SQL injection via the request-controlled value.
## Severity
Category sql-injection; severity critical; priority critical.
## Implementation direction
Parameterize the concatenated value in this query.
## Acceptance criteria
Query is parameterized; payload OR 1=1 returns no rows.
## Expected tests
Regression test for payload OR 1=1.
## Related issues
Epic E1. --label type:security --label security --label severity:critical --label priority:critical --label theme:sql-injection --label complexity:small
https://github.com/acme/demo/issues/100
exit=0
### publish step 3: create sub-issue S7 (issue create #8)
> gh issue create --title SQL injection in getRepoById (src/repo.ts:41) --body ## Threat
SQL injection in SQL injection in getRepoById (src/repo.ts:41). Category sql-injection, severity critical, confidence high. Possible vulnerability -- verify.
## Affected surface
SQL injection in getRepoById (src/repo.ts:41); HTTP handler.
## Evidence / Reproduction
db.query built by string concatenation of a request-controlled value.
## Impact
SQL injection via the request-controlled value.
## Severity
Category sql-injection; severity critical; priority critical.
## Implementation direction
Parameterize the concatenated value in this query.
## Acceptance criteria
Query is parameterized; payload OR 1=1 returns no rows.
## Expected tests
Regression test for payload OR 1=1.
## Related issues
Epic E1. --label type:security --label security --label severity:critical --label priority:critical --label theme:sql-injection --label complexity:small
https://github.com/acme/demo/issues/100
exit=0
### publish step 3: create sub-issue S8 (issue create #9)
> gh issue create --title SQL injection in promoteRepo tier (src/repo.ts:63) --body ## Threat
SQL injection in SQL injection in promoteRepo tier (src/repo.ts:63). Category sql-injection, severity critical, confidence high. Possible vulnerability -- verify.
## Affected surface
SQL injection in promoteRepo tier (src/repo.ts:63); HTTP handler.
## Evidence / Reproduction
db.query built by string concatenation of a request-controlled value.
## Impact
SQL injection via the request-controlled value.
## Severity
Category sql-injection; severity critical; priority critical.
## Implementation direction
Parameterize the concatenated value in this query.
## Acceptance criteria
Query is parameterized; payload OR 1=1 returns no rows.
## Expected tests
Regression test for payload OR 1=1.
## Related issues
Epic E1. --label type:security --label security --label severity:critical --label priority:critical --label theme:sql-injection --label complexity:small
https://github.com/acme/demo/issues/100
exit=0
### publish step 3: create sub-issue S9 (issue create #10)
> gh issue create --title SQL injection in termSearch (src/search.ts:18) --body ## Threat
SQL injection in SQL injection in termSearch (src/search.ts:18). Category sql-injection, severity critical, confidence high. Possible vulnerability -- verify.
## Affected surface
SQL injection in termSearch (src/search.ts:18); HTTP handler.
## Evidence / Reproduction
db.query built by string concatenation of a request-controlled value.
## Impact
SQL injection via the request-controlled value.
## Severity
Category sql-injection; severity critical; priority critical.
## Implementation direction
Parameterize the concatenated value in this query.
## Acceptance criteria
Query is parameterized; payload OR 1=1 returns no rows.
## Expected tests
Regression test for payload OR 1=1.
## Related issues
Epic E1. --label type:security --label security --label severity:critical --label priority:critical --label theme:sql-injection --label complexity:small
https://github.com/acme/demo/issues/100
exit=0
### publish step 3: create sub-issue S10 (issue create #11)
> gh issue create --title SQL injection in filterSearch tag (src/search.ts:47) --body ## Threat
SQL injection in SQL injection in filterSearch tag (src/search.ts:47). Category sql-injection, severity critical, confidence high. Possible vulnerability -- verify.
## Affected surface
SQL injection in filterSearch tag (src/search.ts:47); HTTP handler.
## Evidence / Reproduction
db.query built by string concatenation of a request-controlled value.
## Impact
SQL injection via the request-controlled value.
## Severity
Category sql-injection; severity critical; priority critical.
## Implementation direction
Parameterize the concatenated value in this query.
## Acceptance criteria
Query is parameterized; payload OR 1=1 returns no rows.
## Expected tests
Regression test for payload OR 1=1.
## Related issues
Epic E1. --label type:security --label security --label severity:critical --label priority:critical --label theme:sql-injection --label complexity:small
https://github.com/acme/demo/issues/100
exit=0
### publish step 3: create sub-issue S11 (issue create #12)
> gh issue create --title SQL injection in facetCount bucket (src/search.ts:66) --body ## Threat
SQL injection in SQL injection in facetCount bucket (src/search.ts:66). Category sql-injection, severity critical, confidence high. Possible vulnerability -- verify.
## Affected surface
SQL injection in facetCount bucket (src/search.ts:66); HTTP handler.
## Evidence / Reproduction
db.query built by string concatenation of a request-controlled value.
## Impact
SQL injection via the request-controlled value.
## Severity
Category sql-injection; severity critical; priority critical.
## Implementation direction
Parameterize the concatenated value in this query.
## Acceptance criteria
Query is parameterized; payload OR 1=1 returns no rows.
## Expected tests
Regression test for payload OR 1=1.
## Related issues
Epic E1. --label type:security --label security --label severity:critical --label priority:critical --label theme:sql-injection --label complexity:small
https://github.com/acme/demo/issues/100
exit=0
### retry: re-issue sub-issue S1 create with same identity (must fail again)
> gh issue create --title SQL injection in fetchDashboard (src/db.ts:22) --body ## Threat
SQL injection in src/db.ts:22 fetchDashboard hour filter. Category sql-injection, severity critical, confidence high. Possible vulnerability -- verify.
## Affected surface
src/db.ts:22; fetchDashboard; HTTP handler.
## Evidence / Reproduction
db.query built by string concatenation of the hour parameter. This is the second of the eleven string-built queries in the cluster.
## Impact
SQL injection through the hour parameter.
## Severity
Category sql-injection; severity critical; priority critical. Labels type:security, security, severity:critical, priority:critical, theme:sql-injection, complexity:small.
## Implementation direction
Parameterize the hour filter in fetchDashboard.
## Acceptance criteria
fetchDashboard uses a parameterized query; payload OR 1=1 returns no rows.
## Expected tests
Regression test for payload OR 1=1.
## Related issues
Epic E1; prerequisite for sub-issue S2 (logScanEvent reuses the same insert helper). --label type:security --label security --label severity:critical --label priority:critical --label theme:sql-injection --label complexity:small
HTTP 422: mock delivery failure
exit=1
### mock gh command log (GH_LOG)
label create type:security
label create security
label create severity:critical
label create priority:critical
label create theme:sql-injection
label create complexity:small
label create complexity:large
issue create --title Epic: SQL-injection cluster in repo, db and search handlers --body ## Threat
SQL injection cluster: eleven reachable string-built SQL queries across src/repo.ts, src/db.ts, src/search.ts feed one HTTP handler. Category sql-injection, severity critical, confidence high. State at fix time: possible vulnerability -- verify.
## Affected surface
src/repo.ts:11,24,41,63; src/db.ts:22,35,52,78; src/search.ts:18,47,66; shared HTTP handler entry point.
## Evidence / Reproduction
Mocked GitNexus explain returns eleven sql-injection source-to-sink findings, all reachable from the same handler. Representative evidence: db.query built by string concatenation of the owner parameter.
## Impact
Request-controlled values flow into query text; attacker-controllable WHERE, ORDER BY, INSERT and DELETE clauses.
## Severity
Category sql-injection; severity critical; priority critical. Labels type:security, security, severity:critical, priority:critical, theme:sql-injection, complexity:large.
## Implementation direction
Replace every string-built query with parameterized queries behind one shared helper; each sub-issue tracks one file:line.
## Acceptance criteria
No string-built SQL remains in the affected handlers; regression payloads return no rows.
## Expected tests
Per-sub-issue regression tests on each affected query.
## Related issues
Sub-issues S1..S11 (planned, one per finding). --label type:security --label security --label severity:critical --label priority:critical --label theme:sql-injection --label complexity:small --label complexity:large
issue create --title SQL injection in fetchDashboard (src/db.ts:22) --body ## Threat
SQL injection in src/db.ts:22 fetchDashboard hour filter. Category sql-injection, severity critical, confidence high. Possible vulnerability -- verify.
## Affected surface
src/db.ts:22; fetchDashboard; HTTP handler.
## Evidence / Reproduction
db.query built by string concatenation of the hour parameter. This is the second of the eleven string-built queries in the cluster.
## Impact
SQL injection through the hour parameter.
## Severity
Category sql-injection; severity critical; priority critical. Labels type:security, security, severity:critical, priority:critical, theme:sql-injection, complexity:small.
## Implementation direction
Parameterize the hour filter in fetchDashboard.
## Acceptance criteria
fetchDashboard uses a parameterized query; payload OR 1=1 returns no rows.
## Expected tests
Regression test for payload OR 1=1.
## Related issues
Epic E1; prerequisite for sub-issue S2 (logScanEvent reuses the same insert helper). --label type:security --label security --label severity:critical --label priority:critical --label theme:sql-injection --label complexity:small
issue create --title SQL injection in pruneOldRows (src/db.ts:52) --body ## Threat
SQL injection in SQL injection in pruneOldRows (src/db.ts:52). Category sql-injection, severity critical, confidence high. Possible vulnerability -- verify.
## Affected surface
SQL injection in pruneOldRows (src/db.ts:52); HTTP handler.
## Evidence / Reproduction
db.query built by string concatenation of a request-controlled value.
## Impact
SQL injection via the request-controlled value.
## Severity
Category sql-injection; severity critical; priority critical.
## Implementation direction
Parameterize the concatenated value in this query.
## Acceptance criteria
Query is parameterized; payload OR 1=1 returns no rows.
## Expected tests
Regression test for payload OR 1=1.
## Related issues
Epic E1. --label type:security --label security --label severity:critical --label priority:critical --label theme:sql-injection --label complexity:small
issue create --title SQL injection in aggregateByOwner (src/db.ts:78) --body ## Threat
SQL injection in SQL injection in aggregateByOwner (src/db.ts:78). Category sql-injection, severity critical, confidence high. Possible vulnerability -- verify.
## Affected surface
SQL injection in aggregateByOwner (src/db.ts:78); HTTP handler.
## Evidence / Reproduction
db.query built by string concatenation of a request-controlled value.
## Impact
SQL injection via the request-controlled value.
## Severity
Category sql-injection; severity critical; priority critical.
## Implementation direction
Parameterize the concatenated value in this query.
## Acceptance criteria
Query is parameterized; payload OR 1=1 returns no rows.
## Expected tests
Regression test for payload OR 1=1.
## Related issues
Epic E1. --label type:security --label security --label severity:critical --label priority:critical --label theme:sql-injection --label complexity:small
issue create --title SQL injection in listRepos owner filter (src/repo.ts:11) --body ## Threat
SQL injection in SQL injection in listRepos owner filter (src/repo.ts:11). Category sql-injection, severity critical, confidence high. Possible vulnerability -- verify.
## Affected surface
SQL injection in listRepos owner filter (src/repo.ts:11); HTTP handler.
## Evidence / Reproduction
db.query built by string concatenation of a request-controlled value.
## Impact
SQL injection via the request-controlled value.
## Severity
Category sql-injection; severity critical; priority critical.
## Implementation direction
Parameterize the concatenated value in this query.
## Acceptance criteria
Query is parameterized; payload OR 1=1 returns no rows.
## Expected tests
Regression test for payload OR 1=1.
## Related issues
Epic E1. --label type:security --label security --label severity:critical --label priority:critical --label theme:sql-injection --label complexity:small
issue create --title SQL injection in sortRepos ORDER BY (src/repo.ts:24) --body ## Threat
SQL injection in SQL injection in sortRepos ORDER BY (src/repo.ts:24). Category sql-injection, severity critical, confidence high. Possible vulnerability -- verify.
## Affected surface
SQL injection in sortRepos ORDER BY (src/repo.ts:24); HTTP handler.
## Evidence / Reproduction
db.query built by string concatenation of a request-controlled value.
## Impact
SQL injection via the request-controlled value.
## Severity
Category sql-injection; severity critical; priority critical.
## Implementation direction
Parameterize the concatenated value in this query.
## Acceptance criteria
Query is parameterized; payload OR 1=1 returns no rows.
## Expected tests
Regression test for payload OR 1=1.
## Related issues
Epic E1. --label type:security --label security --label severity:critical --label priority:critical --label theme:sql-injection --label complexity:small
issue create --title SQL injection in getRepoById (src/repo.ts:41) --body ## Threat
SQL injection in SQL injection in getRepoById (src/repo.ts:41). Category sql-injection, severity critical, confidence high. Possible vulnerability -- verify.
## Affected surface
SQL injection in getRepoById (src/repo.ts:41); HTTP handler.
## Evidence / Reproduction
db.query built by string concatenation of a request-controlled value.
## Impact
SQL injection via the request-controlled value.
## Severity
Category sql-injection; severity critical; priority critical.
## Implementation direction
Parameterize the concatenated value in this query.
## Acceptance criteria
Query is parameterized; payload OR 1=1 returns no rows.
## Expected tests
Regression test for payload OR 1=1.
## Related issues
Epic E1. --label type:security --label security --label severity:critical --label priority:critical --label theme:sql-injection --label complexity:small
issue create --title SQL injection in promoteRepo tier (src/repo.ts:63) --body ## Threat
SQL injection in SQL injection in promoteRepo tier (src/repo.ts:63). Category sql-injection, severity critical, confidence high. Possible vulnerability -- verify.
## Affected surface
SQL injection in promoteRepo tier (src/repo.ts:63); HTTP handler.
## Evidence / Reproduction
db.query built by string concatenation of a request-controlled value.
## Impact
SQL injection via the request-controlled value.
## Severity
Category sql-injection; severity critical; priority critical.
## Implementation direction
Parameterize the concatenated value in this query.
## Acceptance criteria
Query is parameterized; payload OR 1=1 returns no rows.
## Expected tests
Regression test for payload OR 1=1.
## Related issues
Epic E1. --label type:security --label security --label severity:critical --label priority:critical --label theme:sql-injection --label complexity:small
issue create --title SQL injection in termSearch (src/search.ts:18) --body ## Threat
SQL injection in SQL injection in termSearch (src/search.ts:18). Category sql-injection, severity critical, confidence high. Possible vulnerability -- verify.
## Affected surface
SQL injection in termSearch (src/search.ts:18); HTTP handler.
## Evidence / Reproduction
db.query built by string concatenation of a request-controlled value.
## Impact
SQL injection via the request-controlled value.
## Severity
Category sql-injection; severity critical; priority critical.
## Implementation direction
Parameterize the concatenated value in this query.
## Acceptance criteria
Query is parameterized; payload OR 1=1 returns no rows.
## Expected tests
Regression test for payload OR 1=1.
## Related issues
Epic E1. --label type:security --label security --label severity:critical --label priority:critical --label theme:sql-injection --label complexity:small
issue create --title SQL injection in filterSearch tag (src/search.ts:47) --body ## Threat
SQL injection in SQL injection in filterSearch tag (src/search.ts:47). Category sql-injection, severity critical, confidence high. Possible vulnerability -- verify.
## Affected surface
SQL injection in filterSearch tag (src/search.ts:47); HTTP handler.
## Evidence / Reproduction
db.query built by string concatenation of a request-controlled value.
## Impact
SQL injection via the request-controlled value.
## Severity
Category sql-injection; severity critical; priority critical.
## Implementation direction
Parameterize the concatenated value in this query.
## Acceptance criteria
Query is parameterized; payload OR 1=1 returns no rows.
## Expected tests
Regression test for payload OR 1=1.
## Related issues
Epic E1. --label type:security --label security --label severity:critical --label priority:critical --label theme:sql-injection --label complexity:small
issue create --title SQL injection in facetCount bucket (src/search.ts:66) --body ## Threat
SQL injection in SQL injection in facetCount bucket (src/search.ts:66). Category sql-injection, severity critical, confidence high. Possible vulnerability -- verify.
## Affected surface
SQL injection in facetCount bucket (src/search.ts:66); HTTP handler.
## Evidence / Reproduction
db.query built by string concatenation of a request-controlled value.
## Impact
SQL injection via the request-controlled value.
## Severity
Category sql-injection; severity critical; priority critical.
## Implementation direction
Parameterize the concatenated value in this query.
## Acceptance criteria
Query is parameterized; payload OR 1=1 returns no rows.
## Expected tests
Regression test for payload OR 1=1.
## Related issues
Epic E1. --label type:security --label security --label severity:critical --label priority:critical --label theme:sql-injection --label complexity:small
issue create --title SQL injection in fetchDashboard (src/db.ts:22) --body ## Threat
SQL injection in src/db.ts:22 fetchDashboard hour filter. Category sql-injection, severity critical, confidence high. Possible vulnerability -- verify.
## Affected surface
src/db.ts:22; fetchDashboard; HTTP handler.
## Evidence / Reproduction
db.query built by string concatenation of the hour parameter. This is the second of the eleven string-built queries in the cluster.
## Impact
SQL injection through the hour parameter.
## Severity
Category sql-injection; severity critical; priority critical. Labels type:security, security, severity:critical, priority:critical, theme:sql-injection, complexity:small.
## Implementation direction
Parameterize the hour filter in fetchDashboard.
## Acceptance criteria
fetchDashboard uses a parameterized query; payload OR 1=1 returns no rows.
## Expected tests
Regression test for payload OR 1=1.
## Related issues
Epic E1; prerequisite for sub-issue S2 (logScanEvent reuses the same insert helper). --label type:security --label security --label severity:critical --label priority:critical --label theme:sql-injection --label complexity:small

## Mock gh command log (GH_LOG, verbatim)

label create type:security
label create security
label create severity:critical
label create priority:critical
label create theme:sql-injection
label create complexity:small
label create complexity:large
issue create --title Epic: SQL-injection cluster in repo, db and search handlers --body ## Threat
SQL injection cluster: eleven reachable string-built SQL queries across src/repo.ts, src/db.ts, src/search.ts feed one HTTP handler. Category sql-injection, severity critical, confidence high. State at fix time: possible vulnerability -- verify.
## Affected surface
src/repo.ts:11,24,41,63; src/db.ts:22,35,52,78; src/search.ts:18,47,66; shared HTTP handler entry point.
## Evidence / Reproduction
Mocked GitNexus explain returns eleven sql-injection source-to-sink findings, all reachable from the same handler. Representative evidence: db.query built by string concatenation of the owner parameter.
## Impact
Request-controlled values flow into query text; attacker-controllable WHERE, ORDER BY, INSERT and DELETE clauses.
## Severity
Category sql-injection; severity critical; priority critical. Labels type:security, security, severity:critical, priority:critical, theme:sql-injection, complexity:large.
## Implementation direction
Replace every string-built query with parameterized queries behind one shared helper; each sub-issue tracks one file:line.
## Acceptance criteria
No string-built SQL remains in the affected handlers; regression payloads return no rows.
## Expected tests
Per-sub-issue regression tests on each affected query.
## Related issues
Sub-issues S1..S11 (planned, one per finding). --label type:security --label security --label severity:critical --label priority:critical --label theme:sql-injection --label complexity:small --label complexity:large
issue create --title SQL injection in fetchDashboard (src/db.ts:22) --body ## Threat
SQL injection in src/db.ts:22 fetchDashboard hour filter. Category sql-injection, severity critical, confidence high. Possible vulnerability -- verify.
## Affected surface
src/db.ts:22; fetchDashboard; HTTP handler.
## Evidence / Reproduction
db.query built by string concatenation of the hour parameter. This is the second of the eleven string-built queries in the cluster.
## Impact
SQL injection through the hour parameter.
## Severity
Category sql-injection; severity critical; priority critical. Labels type:security, security, severity:critical, priority:critical, theme:sql-injection, complexity:small.
## Implementation direction
Parameterize the hour filter in fetchDashboard.
## Acceptance criteria
fetchDashboard uses a parameterized query; payload OR 1=1 returns no rows.
## Expected tests
Regression test for payload OR 1=1.
## Related issues
Epic E1; prerequisite for sub-issue S2 (logScanEvent reuses the same insert helper). --label type:security --label security --label severity:critical --label priority:critical --label theme:sql-injection --label complexity:small
issue create --title SQL injection in pruneOldRows (src/db.ts:52) --body ## Threat
SQL injection in SQL injection in pruneOldRows (src/db.ts:52). Category sql-injection, severity critical, confidence high. Possible vulnerability -- verify.
## Affected surface
SQL injection in pruneOldRows (src/db.ts:52); HTTP handler.
## Evidence / Reproduction
db.query built by string concatenation of a request-controlled value.
## Impact
SQL injection via the request-controlled value.
## Severity
Category sql-injection; severity critical; priority critical.
## Implementation direction
Parameterize the concatenated value in this query.
## Acceptance criteria
Query is parameterized; payload OR 1=1 returns no rows.
## Expected tests
Regression test for payload OR 1=1.
## Related issues
Epic E1. --label type:security --label security --label severity:critical --label priority:critical --label theme:sql-injection --label complexity:small
issue create --title SQL injection in aggregateByOwner (src/db.ts:78) --body ## Threat
SQL injection in SQL injection in aggregateByOwner (src/db.ts:78). Category sql-injection, severity critical, confidence high. Possible vulnerability -- verify.
## Affected surface
SQL injection in aggregateByOwner (src/db.ts:78); HTTP handler.
## Evidence / Reproduction
db.query built by string concatenation of a request-controlled value.
## Impact
SQL injection via the request-controlled value.
## Severity
Category sql-injection; severity critical; priority critical.
## Implementation direction
Parameterize the concatenated value in this query.
## Acceptance criteria
Query is parameterized; payload OR 1=1 returns no rows.
## Expected tests
Regression test for payload OR 1=1.
## Related issues
Epic E1. --label type:security --label security --label severity:critical --label priority:critical --label theme:sql-injection --label complexity:small
issue create --title SQL injection in listRepos owner filter (src/repo.ts:11) --body ## Threat
SQL injection in SQL injection in listRepos owner filter (src/repo.ts:11). Category sql-injection, severity critical, confidence high. Possible vulnerability -- verify.
## Affected surface
SQL injection in listRepos owner filter (src/repo.ts:11); HTTP handler.
## Evidence / Reproduction
db.query built by string concatenation of a request-controlled value.
## Impact
SQL injection via the request-controlled value.
## Severity
Category sql-injection; severity critical; priority critical.
## Implementation direction
Parameterize the concatenated value in this query.
## Acceptance criteria
Query is parameterized; payload OR 1=1 returns no rows.
## Expected tests
Regression test for payload OR 1=1.
## Related issues
Epic E1. --label type:security --label security --label severity:critical --label priority:critical --label theme:sql-injection --label complexity:small
issue create --title SQL injection in sortRepos ORDER BY (src/repo.ts:24) --body ## Threat
SQL injection in SQL injection in sortRepos ORDER BY (src/repo.ts:24). Category sql-injection, severity critical, confidence high. Possible vulnerability -- verify.
## Affected surface
SQL injection in sortRepos ORDER BY (src/repo.ts:24); HTTP handler.
## Evidence / Reproduction
db.query built by string concatenation of a request-controlled value.
## Impact
SQL injection via the request-controlled value.
## Severity
Category sql-injection; severity critical; priority critical.
## Implementation direction
Parameterize the concatenated value in this query.
## Acceptance criteria
Query is parameterized; payload OR 1=1 returns no rows.
## Expected tests
Regression test for payload OR 1=1.
## Related issues
Epic E1. --label type:security --label security --label severity:critical --label priority:critical --label theme:sql-injection --label complexity:small
issue create --title SQL injection in getRepoById (src/repo.ts:41) --body ## Threat
SQL injection in SQL injection in getRepoById (src/repo.ts:41). Category sql-injection, severity critical, confidence high. Possible vulnerability -- verify.
## Affected surface
SQL injection in getRepoById (src/repo.ts:41); HTTP handler.
## Evidence / Reproduction
db.query built by string concatenation of a request-controlled value.
## Impact
SQL injection via the request-controlled value.
## Severity
Category sql-injection; severity critical; priority critical.
## Implementation direction
Parameterize the concatenated value in this query.
## Acceptance criteria
Query is parameterized; payload OR 1=1 returns no rows.
## Expected tests
Regression test for payload OR 1=1.
## Related issues
Epic E1. --label type:security --label security --label severity:critical --label priority:critical --label theme:sql-injection --label complexity:small
issue create --title SQL injection in promoteRepo tier (src/repo.ts:63) --body ## Threat
SQL injection in SQL injection in promoteRepo tier (src/repo.ts:63). Category sql-injection, severity critical, confidence high. Possible vulnerability -- verify.
## Affected surface
SQL injection in promoteRepo tier (src/repo.ts:63); HTTP handler.
## Evidence / Reproduction
db.query built by string concatenation of a request-controlled value.
## Impact
SQL injection via the request-controlled value.
## Severity
Category sql-injection; severity critical; priority critical.
## Implementation direction
Parameterize the concatenated value in this query.
## Acceptance criteria
Query is parameterized; payload OR 1=1 returns no rows.
## Expected tests
Regression test for payload OR 1=1.
## Related issues
Epic E1. --label type:security --label security --label severity:critical --label priority:critical --label theme:sql-injection --label complexity:small
issue create --title SQL injection in termSearch (src/search.ts:18) --body ## Threat
SQL injection in SQL injection in termSearch (src/search.ts:18). Category sql-injection, severity critical, confidence high. Possible vulnerability -- verify.
## Affected surface
SQL injection in termSearch (src/search.ts:18); HTTP handler.
## Evidence / Reproduction
db.query built by string concatenation of a request-controlled value.
## Impact
SQL injection via the request-controlled value.
## Severity
Category sql-injection; severity critical; priority critical.
## Implementation direction
Parameterize the concatenated value in this query.
## Acceptance criteria
Query is parameterized; payload OR 1=1 returns no rows.
## Expected tests
Regression test for payload OR 1=1.
## Related issues
Epic E1. --label type:security --label security --label severity:critical --label priority:critical --label theme:sql-injection --label complexity:small
issue create --title SQL injection in filterSearch tag (src/search.ts:47) --body ## Threat
SQL injection in SQL injection in filterSearch tag (src/search.ts:47). Category sql-injection, severity critical, confidence high. Possible vulnerability -- verify.
## Affected surface
SQL injection in filterSearch tag (src/search.ts:47); HTTP handler.
## Evidence / Reproduction
db.query built by string concatenation of a request-controlled value.
## Impact
SQL injection via the request-controlled value.
## Severity
Category sql-injection; severity critical; priority critical.
## Implementation direction
Parameterize the concatenated value in this query.
## Acceptance criteria
Query is parameterized; payload OR 1=1 returns no rows.
## Expected tests
Regression test for payload OR 1=1.
## Related issues
Epic E1. --label type:security --label security --label severity:critical --label priority:critical --label theme:sql-injection --label complexity:small
issue create --title SQL injection in facetCount bucket (src/search.ts:66) --body ## Threat
SQL injection in SQL injection in facetCount bucket (src/search.ts:66). Category sql-injection, severity critical, confidence high. Possible vulnerability -- verify.
## Affected surface
SQL injection in facetCount bucket (src/search.ts:66); HTTP handler.
## Evidence / Reproduction
db.query built by string concatenation of a request-controlled value.
## Impact
SQL injection via the request-controlled value.
## Severity
Category sql-injection; severity critical; priority critical.
## Implementation direction
Parameterize the concatenated value in this query.
## Acceptance criteria
Query is parameterized; payload OR 1=1 returns no rows.
## Expected tests
Regression test for payload OR 1=1.
## Related issues
Epic E1. --label type:security --label security --label severity:critical --label priority:critical --label theme:sql-injection --label complexity:small
issue create --title SQL injection in fetchDashboard (src/db.ts:22) --body ## Threat
SQL injection in src/db.ts:22 fetchDashboard hour filter. Category sql-injection, severity critical, confidence high. Possible vulnerability -- verify.
## Affected surface
src/db.ts:22; fetchDashboard; HTTP handler.
## Evidence / Reproduction
db.query built by string concatenation of the hour parameter. This is the second of the eleven string-built queries in the cluster.
## Impact
SQL injection through the hour parameter.
## Severity
Category sql-injection; severity critical; priority critical. Labels type:security, security, severity:critical, priority:critical, theme:sql-injection, complexity:small.
## Implementation direction
Parameterize the hour filter in fetchDashboard.
## Acceptance criteria
fetchDashboard uses a parameterized query; payload OR 1=1 returns no rows.
## Expected tests
Regression test for payload OR 1=1.
## Related issues
Epic E1; prerequisite for sub-issue S2 (logScanEvent reuses the same insert helper). --label type:security --label security --label severity:critical --label priority:critical --label theme:sql-injection --label complexity:small
