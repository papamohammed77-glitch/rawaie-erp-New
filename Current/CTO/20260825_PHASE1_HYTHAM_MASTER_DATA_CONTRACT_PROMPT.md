# PHASE 1 — HYTHAM EXECUTION DIRECTIVE
# FINANCIAL MASTER DATA CONTRACT / STAGING VALIDATION

## Mission

Act as the technical counterpart to Khalid's forensic COA recovery. Your responsibility is NOT to recover the 87 rows independently unless a new source is discovered during contract verification. Your responsibility is to prove that any source-backed COA dataset can safely enter the current ERP architecture.

## Authority

Production PostgreSQL > Current main > Current evidence > Historical sources > Reports.

Current Production company:
`00000000-0000-0000-0000-000000000001`

Current Production COA count: `0`.
Current Treasury count: `1`.
Current applied migration head: `20260824151259`.
Current public PostgreSQL function overloads: `48`.

Re-query all of the above yourself before acting.

## Phase 1 technical objectives

### 1. COA schema contract

Document directly from Production:

- columns
- data types
- nullability
- PK/FK
- uniqueness
- parent relationship
- indexes
- RLS
- grants
- triggers

Do not redesign the schema during this mission.

### 2. Account identity contract

Prove what current financial cores require for account identity.

Inspect and document the current Production behavior of:

- `post_journal_entry`
- `post_cash_receipt_atomic`
- `post_cash_payment_atomic`
- `receive_purchase_atomic`
- `save_sales_invoice_atomic`
- `complete_return_atomic`
- reporting functions that consume COA/journal data

Determine explicitly:

- account UUID vs account code
- company ownership
- active state
- parent semantics
- whether account names are authoritative or merely descriptive

Do not infer a Treasury↔COA mapping from naming conventions.

### 3. Treasury contract

Verify the existing Production Treasury row and its schema.

Confirm:

- company owner
- account code
- account name
- opening/current balances
- active state
- any explicit COA relation in schema/configuration
- how current cash cores identify treasury and cash account

No Treasury recreation.
No Treasury mutation.

### 4. Khalid replay contract review

When Khalid produces a candidate 87-row dataset, review it independently.

For every row confirm:

- source-backed value
- UUID validity
- account-code uniqueness
- parent existence
- no self-parent
- no cycle
- company remap validity
- current schema compatibility
- financial-core acceptance

Reject anything that depends on convention or guessing.

### 5. Staging validation

Use the staging Supabase project only for replay validation.

Current staging Treasury must be treated as staging data, not Production truth.

Before any replay:

- snapshot staging COA/Treasury relevant state
- record row counts and hashes
- validate permissions and RLS state
- apply only source-backed dataset
- validate FK/unique/parent graph integrity
- run non-destructive financial core compatibility tests
- verify rollback path

Do not weaken staging security merely to make the test pass.

### 6. Production safety gate

No Production COA INSERT/UPDATE/DELETE is permitted under this prompt.

Your output may recommend Production restoration only after:

exact source evidence + staging replay + schema validation + business owner decision.

## Required technical matrix

Produce:

| Contract | Current Production | Historical Evidence | Khalid Dataset | Staging Result | Risk | Status |
|---|---|---|---|---|---|---|
| Account identity | | | | | | |
| Parent relation | | | | | | |
| Company ownership | | | | | | |
| Account code uniqueness | | | | | | |
| Treasury identity | | | | | | |
| Treasury↔COA relation | | | | | | |
| Journal posting compatibility | | | | | | |
| Cash-core compatibility | | | | | | |
| Reporting compatibility | | | | | | |

## Forbidden

- inventing COA rows
- assigning account codes by convention
- mapping CASH-01 to a numeric COA account without evidence
- modifying Production COA or Treasury
- changing Inventory Core
- modifying POS write-side logic
- changing accountant.html or finance-manager.html
- changing financial writer behavior merely to accommodate missing master data
- weakening RLS/grants
- declaring runtime closure from SQL inspection alone

## Required deliverables

1. `20260825_HYTHAM_PHASE1_MASTER_DATA_CONTRACT.md`
2. `20260825_HYTHAM_PHASE1_KHALID_DATASET_REVIEW.md` after Khalid submits candidate source data
3. staging replay/test evidence where applicable
4. explicit list of blockers that require owner decision
5. no Production mutation

## Closure rule

This technical Phase 1 unit is CLOSED only when:

- current COA schema contract is proven;
- account identity contract is proven;
- Treasury contract is proven;
- Khalid's candidate dataset, if any, is independently validated;
- staging replay passes without weakening controls;
- any remaining issue is precisely classified as source gap or owner decision.

Do not declare exact 87-row historical recovery closed unless the row-level source itself is proven.
