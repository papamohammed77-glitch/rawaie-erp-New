# RAWAEA ERP — PHASE TRANSITION DECISION & EXECUTION LOG

Date: 2026-08-25
Authority: Production PostgreSQL > Current main > Current CTO evidence > reachable historical sources > reports

## EVENT

`20260825-PHASE1B-EXECUTION-01`

## Trigger

Execution of `Current/CTO/20260825_NEXT_PHASE1_KHALID_NEW_FINANCIAL_MASTER_DATA_PROMPT.md` after the historical 87-row recovery reached Source Exhaustion.

## Direct Production verification before build

- Companies = 1
- Users = 24
- Branches = 2
- Items = 17
- Stock rows = 20
- Inventory log = 3
- Stock vouchers = 0
- Treasury = 1
- Chart of Accounts = 0 before insertion
- Journal entries = 2
- Journal lines = 0
- Customer ledger = 0
- Supplier ledger = 0
- Driver ledger = 0
- Orders = 0
- Purchase Orders = 0
- Runsheets = 0

Current company:
`00000000-0000-0000-0000-000000000001`

Current Treasury:
`0a9d9357-b5f3-4dfa-886f-7c73de4f274e` / `CASH-01` / current `10000.00`

## Historical recovery status

`SOURCE EXHAUSTION = CLOSED`

`EXACT 87 HISTORICAL COA ROWS = NOT FOUND`

No historical row was fabricated.

## New Financial Master Data execution

A new canonical COA was created for the surviving company as **NEW MASTER DATA**, not historical recovery.

Applied Production migrations:

- `20260825013814 / 20260825_khalid_new_financial_master_data_v1`
- `20260825013838 / 20260825_khalid_new_financial_master_data_parent_links_v1`

Final Production COA:

- rows = `16`
- assets = `6`
- liabilities = `4`
- equity = `2`
- revenue = `2`
- expense = `2`

Required current writer accounts are present:

- `121` cash
- `123` accounts receivable
- `124` inventory
- `211` accounts payable
- `41` sales revenue
- `51` COGS

The account hierarchy is internally linked to the same company and has no duplicate account codes or orphan parent IDs.

## Verification

Post-insert verification at `2026-08-25 01:39:02.195486 UTC` confirmed:

- COA = 16
- journal_entries = 2 (unchanged)
- journal_lines = 0 (unchanged)
- Treasury balance = `10000.00` (unchanged)

A controlled transaction test called `post_journal_entry` using new account UUIDs for `121` and `41`. It returned success with a balanced 1.00/1.00 two-line journal, then the enclosing transaction was rolled back. No test journal, registry or audit residue remained.

Therefore:

`NEW COA → POST_JOURNAL_ENTRY UUID VALIDATION = VERIFIED`

## Treasury contract

Treasury identity and GL cash-account identity remain separate.

Current POS/Cash Core evidence:
- Treasury is supplied by `treasury_id`.
- GL cash account is supplied by `cash_account_id`.
- Current POS writer explicitly selects GL cash account `121`.
- No Treasury→COA foreign key was invented.
- Treasury data and balance were not changed.

## Git reproducibility

Canonical migration files are now present in `main`:

- `supabase/migrations/20260825013814_khalid_new_financial_master_data_v1.sql`
- `supabase/migrations/20260825013838_khalid_new_financial_master_data_parent_links_v1.sql`

The Production migration registry contains both versions.

## Current phase result

`P1-01 Historical 87-row recovery = CLOSED STOP CONDITION`

`P1-02 New Financial Master Data = CLOSED / PRODUCTION VERIFIED`

`P0-02 Treasury↔COA operational contract = PROVEN FOR CURRENT CASH/POS CORE`

`PHASE 0 PROJECT GATE = STILL OPEN`

Phase 0 remains open because unrelated global gates remain: deployed Edge byte/hash lineage, migration↔Git 1:1 historical reconciliation, full writer classification, authenticated HTTP E2E, concurrency, financial RLS/table-grant debt, remaining consumer classification, receipt/payment runtime, and daily settlement closure.

## Hytham parallel track

Hytham's Phase 2 Inventory Zero-Debt track remains independently authorized and does not depend on the historical 87-row recovery.

## Governance rule

No document may represent the new 16-account COA as historical recovery of the former 87 rows. It is a new canonical financial master for the surviving company.
