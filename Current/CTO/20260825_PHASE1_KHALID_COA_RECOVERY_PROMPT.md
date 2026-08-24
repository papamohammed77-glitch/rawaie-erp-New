# PHASE 1 — KHALID EXECUTION DIRECTIVE
# FINANCIAL MASTER DATA RECOVERY — EXACT HISTORICAL COA

## Mission

Own the forensic recovery of the exact historical COA dataset for the CURRENT company. Your objective is not to design a new chart and not to convert a reported count of 87 into 87 fabricated rows.

## Current authority

Production PostgreSQL > Current main > Current evidence > Historical sources > Reports.

Current Production company:
`00000000-0000-0000-0000-000000000001`

Production currently has:
- Treasury: 1
- COA: 0
- Orders: 0
- Purchase Orders: 0
- Runsheets: 0

The exact historical 87 rows remain UNRECOVERED.

## First gate — repeat current snapshot yourself

Before any substantive action:

1. Re-query Production.
2. Record timestamp.
3. Record current company, treasury, COA count and schema.
4. Record current `main` HEAD.
5. Compare your snapshot with `Current/CTO/20260825_PHASE0_FORENSIC_RECONCILIATION_AND_PHASE1_AUTHORIZATION.md`.
6. Do not trust this prompt's numbers without rechecking them.

## Scope

Recover exact historical row-level evidence for the former 87 COA rows.

Search all reachable authoritative surfaces:

- `rawaie-erp-review` history
- `rawaie-erp-New` history
- historical commits before tenant retirement
- migration files
- seed files
- historical trees/blobs reachable from commits
- preserved SQL evidence
- Memory_Transfer records
- audit evidence
- historical exports/snapshots preserved in repository
- exact account codes referenced by current financial writers
- former tenant UUID `da4ef704-88ac-4120-aa0e-65b92b2aa2bc`

Search dimensions must include at minimum:

- `chart_of_accounts`
- `account_code`
- `account_name`
- `account_type`
- `normal_balance`
- `parent_account_id`
- `company_id`
- historical UUIDs
- exact account codes referenced by `post_journal_entry`, `save_sales_invoice_atomic`, `receive_purchase_atomic`, `complete_return_atomic`, and cash cores.

## Evidence rule

A statement such as `87 accounts existed` is NOT row-level recovery.

A source qualifies only when it provides enough verified row-level data to reconstruct each required row without inference.

Record for every candidate source:

SOURCE ID
LOCATION
COMMIT / BLOB / MIGRATION
DATE
ROW COUNT
FIELDS PRESENT
UUID PRESENT?
PARENT UUID PRESENT?
COMPANY OWNER
INTEGRITY RESULT
WHY AUTHORITATIVE / WHY REJECTED

## If exact rows are found

Build a deterministic replay dataset containing only source-backed values.

Preserve verified historical UUIDs where safe.
Change only ownership to the current company where the target schema requires it.
Preserve verified codes, names, types, normal balance, parent UUIDs, notes and timestamps.
Do NOT infer parent hierarchy from numeric account-code patterns.
Do NOT rename accounts.
Do NOT normalize historical values merely because they look unusual.

Validate before insertion:

- unique account codes
- valid UUIDs
- parent graph integrity
- no self-parent
- no cycles
- parent-before-child replay feasibility
- schema defaults/constraints
- company ownership
- downstream RPC compatibility

Produce a canonical replay artifact and SHA-256 hash.

## Treasury rule

Do not recreate Treasury.

Verify the existing `CASH-01` row independently.
Do not map `CASH-01` to an account code by name or convention.
The Treasury↔COA relationship must be demonstrated by schema, historical data, explicit configuration, or current consumer contract.

## Staging rule

Any replay must happen in staging first.

No Production COA INSERT/UPDATE is authorized by this prompt.

For staging replay:

1. snapshot relevant staging rows;
2. replay only source-backed rows;
3. verify counts and identities;
4. verify parent relations;
5. verify financial core acceptance/rejection behavior;
6. verify Treasury contract;
7. produce rollback evidence;
8. leave staging in a documented final state.

## Stop conditions

STOP SOURCE SEARCH and issue `SOURCE EXHAUSTION = CLOSED` when all reachable authoritative source surfaces have been exhaustively searched and no row-level 87 dataset exists.

Do not create another search cycle merely because the owner is uncomfortable with the outcome.

At that point the only remaining decision is:

A) owner supplies a new authoritative historical source;
or
B) owner authorizes a NEW MASTER DATA creation project explicitly labelled as new master data, not historical recovery.

## Forbidden

- fabricate accounts
- expand 16 bootstrap rows into 87
- infer parents from numbering conventions
- modify Production COA
- recreate Treasury
- edit POS
- edit Inventory Core
- edit accountant.html
- edit finance-manager.html
- weaken security to make tests pass
- turn report statements into evidence

## Required deliverables

1. `20260825_KHALID_PHASE1_COA_SOURCE_REGISTER.md`
2. `20260825_KHALID_PHASE1_COA_REPLAY_DATASET.md` if exact rows are found
3. `20260825_KHALID_PHASE1_COA_RECOVERY_CERTIFICATE.md`
4. Issue update with exact evidence and closure state
5. explicit `FOUND` or `SOURCE EXHAUSTION` decision

## Final status values

EXACT 87 SOURCE = FOUND / NOT FOUND
ROW-LEVEL RECOVERY = CLOSED / OPEN
PARENT RELATIONS = VERIFIED / OPEN
CURRENT-COMPANY REMAP = VERIFIED / OPEN
STAGING REPLAY = PASS / FAIL / NOT APPLICABLE
TREASURY CONTRACT = VERIFIED / OPEN
PRODUCTION CHANGE = FORBIDDEN / NOT APPLICABLE

Never report `COA RECOVERY = CLOSED` unless every required gate is evidenced.
