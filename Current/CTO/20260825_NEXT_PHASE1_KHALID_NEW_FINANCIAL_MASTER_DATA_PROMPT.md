# PHASE 1B — KHALID EXECUTION DIRECTIVE
# NEW FINANCIAL MASTER DATA — HISTORICAL RECOVERY STOP / NEW CANONICAL BUILD

## Authority

Production PostgreSQL > Current `main` > Current CTO evidence > reachable historical sources > reports.

## Decision context

The historical 87-row Chart of Accounts dataset was not recovered from the accessible/reachable evidence universe.
The historical forensic recovery loop is therefore CLOSED at the Evidence-Exhaustion Stop Condition.

This directive explicitly changes the task from:

`HISTORICAL 87-ROW RECOVERY`

to:

`NEW FINANCIAL MASTER DATA DESIGN + IMPLEMENTATION`

These are not the same thing.

The new accounts MUST NOT be represented as recovered historical accounts.
They are a NEW canonical financial master for the surviving Production company.

## Current Production truth — MUST REFRESH FIRST

Before any mutation:

1. Re-query Production and record timestamp.
2. Record current `main` HEAD.
3. Confirm current company count and surviving company UUID.
4. Confirm current Treasury row; do NOT recreate or mutate Treasury during this unit.
5. Confirm `chart_of_accounts = 0` before first insertion.
6. Record current financial Core definitions and consumers.
7. Record current Open Debt register.

Known current baseline at directive issuance:

- Company: `00000000-0000-0000-0000-000000000001`
- Treasury: `0a9d9357-b5f3-4dfa-886f-7c73de4f274e`
- Treasury account code: `CASH-01`
- Treasury current balance: `10000.00`
- Chart of Accounts: `0` rows

These are baseline facts, not substitutes for the required fresh read.

## Objective

Create a production-ready, internally coherent Chart of Accounts for the surviving company based on:

- RAWAEA's actual current business processes;
- current journal Core requirements;
- current Ledger Core requirements;
- current Cash Core requirements;
- current ERP transaction flows;
- proven database schema/constraints;
- explicit business/financial requirements;
- and standard accounting architecture where a current-system contract does not otherwise determine the requirement.

Do NOT try to reproduce the historical 87 rows.
Do NOT claim historical continuity.

## Required work sequence

### 1. FINANCIAL ACCOUNT REQUIREMENTS MATRIX

Build a source-backed matrix of every account required by current production transaction paths.

At minimum trace:

- Cash / Treasury
- Accounts Receivable
- Inventory
- Accounts Payable
- Sales Revenue
- Cost of Goods Sold
- Purchase / Inventory clearing requirements if used by current flows
- Discounts / returns if current flows require them
- Operating expenses required by currently supported business flows
- Equity / opening balance handling
- Any additional accounts required by current journal Core or financial consumers

For every proposed account record:

`business purpose`
`current consumer/core requiring it`
`evidence source`
`account_type`
`normal_balance`
`proposed account_code`
`proposed account_name`
`parent`
`is_active`
`rationale`

No unexplained account may be inserted.

### 2. NEW COA ARCHITECTURE

Design a clean hierarchy suitable for the current single-company ERP.

Use the actual Production schema:

- `id` = UUID
- `company_id`
- `account_code`
- `account_name`
- `account_type`
- `parent_account_id`
- `normal_balance`
- `is_active`
- `notes`

Respect the actual uniqueness and foreign-key constraints.

Parent relationships MUST be internally valid and acyclic.

### 3. HISTORICAL SEPARATION RULE

The previously observed 16-account bootstrap/base set may be used only as historical evidence or comparison.

Do NOT silently copy it and call it "recovered".
If any account from that set is reused in the new design, explicitly label it as:

`NEW MASTER DATA — reused business concept, NOT historical recovery`

### 4. TREASURY / COA CONTRACT

Do NOT infer:

`CASH-01 = account 121`

or any other mapping from name, code, ordering, or convention alone.

Instead determine the explicit operational contract required by the current Cash Core.

Because `treasury` currently has no direct FK to `chart_of_accounts`, do not invent one inside this unit.

If a configuration/mapping is required for production operation, document the exact contract and the minimal safe implementation path before changing it.

Do not mutate or recreate the existing Treasury row merely to establish the relationship.

### 5. DRY RUN / VALIDATION

Before Production insertion:

- validate required account coverage;
- validate unique account codes;
- validate parent hierarchy;
- validate normal-balance semantics;
- validate compatibility with `post_journal_entry`;
- validate compatibility with customer/supplier/driver ledger cores;
- validate compatibility with cash cores;
- validate compatibility with current transaction writers;
- validate no historical-recovery claim is introduced.

### 6. PRODUCTION INSERTION

Only after the account matrix and design are complete:

`DESIGN`
→ `STRUCTURAL VALIDATION`
→ `DRY RUN`
→ `TRANSACTIONAL INSERT`
→ `VERIFY`

The insertion must be atomic.

No partial COA is acceptable.

### 7. POST-INSERT VERIFICATION

Immediately verify:

- expected row count;
- expected account codes;
- parent tree integrity;
- company ownership;
- active states;
- normal balances;
- compatibility with Core UUID validation;
- no duplicate codes;
- no orphaned parent IDs;
- audit record(s), where applicable;
- Git migration reproducibility.

### 8. DO NOT TOUCH

This Closure Unit must NOT modify:

- Treasury data or Treasury identity;
- Inventory Core;
- `post_stock_movement`;
- POS;
- Accountant UI;
- Finance Manager UI;
- historical audit records;
- old company records;
- historical COA recovery claims;
- security controls merely to make insertion easier.

### 9. GIT / PRODUCTION LINEAGE

Any Production DDL/data mutation MUST be represented in canonical Git.

Record separately:

- migration created;
- migration applied;
- Git commit SHA;
- Production timestamp;
- verification result.

Do not treat Git-only presence as Production completion.

### 10. REQUIRED DELIVERABLES

Create/update:

1. `Current/CTO/20260825_KHALID_NEW_FINANCIAL_MASTER_DATA_EXECUTION.md`
2. a canonical Supabase migration for the new COA
3. an account requirements/source matrix
4. a Treasury↔COA contract record stating what is proven and what remains open
5. updated Open Debt Register
6. final Phase 1B self-audit

## Success condition

`NEW FINANCIAL MASTER DATA = PRODUCTION VERIFIED`

only when:

- the new COA is complete for the currently supported transaction set;
- every inserted account has a documented basis;
- no historical recovery claim is made;
- Treasury remains intact;
- Core UUID validation succeeds against the new accounts;
- Production and Git are aligned;
- the change is auditable and reproducible.

## Forbidden

- No attempt to manufacture the historical 87 rows.
- No statement that the new COA is the recovered historical COA.
- No random account codes.
- No arbitrary Treasury mapping.
- No direct UI patch to compensate for missing master data.
- No broad unrelated refactor.
- No report-only closure.
