# KHALID — NEXT EXECUTION DIRECTIVE
# CURRENT-COMPANY FINANCIAL MASTER DATA RECOVERY

## Mission

Recover and establish the financial master-data contract for the CURRENT company only.

Current staging company:
`b4cc737e-6431-474e-af9e-92a427a44911` / TASK028 STAGING

Do not use any retired company as the owner of current data.

## Non-negotiable authority

Production PostgreSQL > Current Git main > Current evidence > Historical sources > Reports.

Reports are evidence of what was believed or executed at a time. They are not current truth.

## What is already proven

1. Historical retired tenant had 87 COA rows.
2. Exact 87 row-level records have NOT yet been recovered.
3. The published application seed contains only a small base set; it is NOT the historical 87.
4. The historical treasury row is exactly recoverable.
5. In current staging, treasury `CASH-01` has been restored under the current staging company with historical UUID and balances.
6. The restoration is documented in `audit_log` because staging has no treasury audit trigger.

## Your first task: FORENSIC SOURCE RECOVERY

Search all authoritative sources for the exact 87 rows:

- rawaie-erp-review history
- rawaie-erp-New Git history
- old commits before tenant deletion
- migration files
- seed files
- blobs/trees reachable from historical commits
- documented exports/snapshots
- any preserved evidence artifact containing row-level COA data

Search by:

- `chart_of_accounts`
- exact account codes mentioned in financial writers
- `parent_account_id`
- `account_type`
- `normal_balance`
- historical tenant id `da4ef704-88ac-4120-aa0e-65b92b2aa2bc`

Do NOT count a report saying “87” as row-level recovery.

## If exact 87 rows are found

Prepare a deterministic replay dataset.

Rules:
- preserve verified historical UUIDs when safe;
- change owner `company_id` to the CURRENT company;
- preserve account_code/name/type/normal_balance/notes/timestamps if verified;
- rebuild parent relationships using verified historical UUID relationships;
- never infer parent relationships from numeric code patterns unless the source proves them;
- validate uniqueness and foreign keys before insertion;
- insert parents before children or use a two-phase replay;
- produce before/after row counts and SHA/hash of the replay dataset.

Then deploy only to staging first.

## Treasury contract

Do not recreate treasury again unless necessary.
Verify the already restored `CASH-01` row, its current-company owner, UUID, balances, and relationship to COA.

## Treasury ↔ COA decision

Do not invent a mapping such as CASH-01 → account code 121 unless a source proves it.
Instead determine the actual intended relation from:

- schema
- historical data
- current financial RPC signatures
- current consumers

## Current staging defects you MUST record, but do NOT fix blindly

- 65 public tables have RLS disabled in staging.
- SECURITY DEFINER financial functions are callable by anon/authenticated in staging.
- staging financial tables have missing primary-key/index hardening.
- staging treasury did not have the uniqueness constraint assumed by some historical code.

Do not turn these into random schema changes. Open a separate security/hardening gate if needed.

## Prohibited

- inventing missing accounts;
- expanding a 16-account seed into 87 by convention;
- renaming or rewriting business account codes without evidence;
- changing Production company identity;
- touching POS write-side code;
- modifying accountant.html or finance-manager.html during this mission;
- changing Inventory Core.

## Required output

FORENSIC COA RECOVERY RESULT

- exact source found?
- source commit/blob/migration?
- rows recovered?
- parent relationships verified?
- current-company remap verified?
- duplicate/conflict results?
- staging inserted?
- runtime financial core tests?
- what remains open?

## Closure gate

COA RECOVERY = CLOSED only when:

exact 87 rows are source-backed
+
current-company ownership is verified
+
parent relationships are verified
+
Production-compatible schema constraints pass
+
staging runtime passes

Otherwise leave OPEN with precise evidence.
