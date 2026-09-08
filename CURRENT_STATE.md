# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-08 — Report95 Main8 Forensic Surgical Reconciliation

### Source-of-Truth Governance
- Production Supabase is the execution reference.
- Historical reports are evidence indexes; they do not override current Production.
- No assumption-based patching.
- UNKNOWN != BUG and UNKNOWN != REMOVE.
- One Closure Unit at a time.
- Physical Stock contract remains:
  `post_stock_movement -> stock_branches + inventory_log`
- `reserve_stock` / `release_stock_reservation` remain Reservation-only.
- Editable Parent Source of Truth:
  `Current/PWA/main2/main1.md ... main11.md`
- `Current/PWA/main/*` = historical evidence only.
- `Original/PWA/main/*` = historical reference only.
- `Current/PWA/New-main` = generated target only; never Source of Truth.

## Current Git
- Repository: `papamohammed77-glitch/rawaie-erp-New`
- Branch: `main`
- Latest session HEAD before Report95/state writes: `e1b6168a091ebb5188828d479a5bab4254b9aae4`
- Current Main8 source SHA:
  `20f77481133d3e55ced949de16f88dadb0a69980`
- Current Main7 source SHA confirmed by Report94:
  `d6ee5ed58faf82d23bd8d0ab73f70d5979d41f19`
- Latest Main7 source commit referenced by Report94:
  `bf9baf2571790e9000a7db99ca93bf250d07c9e6`

## Latest Reports / State Record
- `Report95_Main8_Forensic_Surgical_Reconciliation_20260908.md` = latest session report.
- `Report94_Main7_Exact_Surgical_Reconciliation_20260908.md` = latest Main7 forensic reconciliation before Main8.
- `CURRENT_STATE_Report94_Update.md` = owner-supplied state checkpoint incorporated into this file.

## Production Snapshot — latest verified before this state write
Checked directly at:
`2026-09-08 13:48:15.956937+00 UTC`

- companies = 1
- branches = 2
- users = 24
- items = 17
- stock_branches = 20
- orders = 0
- order_details = 0
- runsheets = 0
- run_sheet_details = 0
- stock_vouchers = 0
- inventory_log = 3
- inventory_counts = 0
- inventory_count_details = 0

## Production Change Executed in Report95
### `get_balance_sheet_data(date)`
- Previous defect: SECURITY DEFINER function read `chart_of_accounts` without current-company filtering.
- Fixed in Production by deriving:
  `v_company_id := app_private.current_user_company_id()`
  and applying `ca.company_id = v_company_id` to assets/liabilities/equity queries.
- EXECUTE surface was restricted to authenticated/service_role; anon/public execution was removed.
- Production migration version:
  `20260908134417`
- Canonical Git migration:
  `supabase/migrations/20260908134417_fix_balance_sheet_company_scope_20260908.sql`
- Audit entry recorded in `audit_log` using the schema-approved `action='update'`.

## Main7 — Current Status
`Current/PWA/main2/main7.md` was NOT modified by the assistant.

The Report94 owner surgeries remain the only Main7 source actions blocking assembly:

### M7-15A
Replace the four configuration values using string sentinel `'null'` with real JavaScript `null` values at the exact four lines documented in Report94 (current lines 126–129 in that checkpoint).

### M7-14
Replace the complete `_showLoadingDetails(code)` function documented in Report94 (current lines 762–772 in that checkpoint) with its company-scoped version, ending immediately before:
`// ==================== DELIVERY ====================`

Protected Main7 contracts remain unchanged:
- lifecycle: `Open / Confirmed -> Picking -> Picked -> Loading -> Loaded -> Delivering -> Delivered -> Returning -> Returned`
- driver order-by-order delivery
- `complete_order_delivery_atomic`
- `complete_return_atomic`
- `_openDeliveryModal(rsCode)`
- `_showUnloadingDetails()`

## Main8 — Current Status
Target file:
`Current/PWA/main2/main8.md`

The file was read/reconciled against:
- Governance masters
- Report94
- `Current/PWA/accountant.html`
- Production schema, constraints, RLS and Edge contracts
- historical finance reconstruction evidence

### Confirmed Main8 gaps
1. `_loadAllData()` performs treasury/account reads without explicit company scope and builds the account tree using account-code keys while `parent_account_id` is UUID.
2. `_openAccountDialog()` sends account-code values into `parent_account_id`, which is a UUID foreign key; CRUD calls also omit explicit tenant filters.
3. `_seedAccounts()` uses account codes as parent IDs and `onConflict: account_code` against a company-scoped unique contract.
4. Treasury creation omits required `company_id`; treasury update/delete omit explicit company scope.
5. Receipt/payment lists read `cash_box` without company scope.
6. Receipt/payment UI currently sends `cashBoxId` as `account_code` and sends no `operationId`, while Production requires Treasury UUID + Account UUID + operation identity in `header`.
7. Transfer UI currently sends `fromCashId/toCashId` only, while Production requires operation identity plus source/target Treasury UUIDs and source/target Account UUIDs.

### Confirmed Main8 contracts that are already correct and should not be changed
- Journal posting is delegated to `save-journal-entry` and already carries an operation identity.
- Financial reporting RPCs are company-scoped in Production.
- Budget RLS binds `budgets.account_id` to the current company's chart of accounts.
- `cost_centers` is currently global in schema; no company column was invented.

### Exact Main8 owner surgery list
All are documented completely in Report95; the assistant MUST NOT edit `Current/PWA/main2/main8.md` directly.

- M8-01 add `_companyId()` helper.
- M8-02 replace `_loadAllData()`.
- M8-03 replace `_buildAccountTree()`.
- M8-04 replace `_openTreasuryDialog()`.
- M8-05 replace `_editTreasury()`.
- M8-06 replace `_openAccountDialog()`.
- M8-07 replace `_seedAccounts()`.
- M8-08 add company scoping to receipt/payment list reads.
- M8-09 replace `_newReceipt()` to use Treasury UUID and Account UUID selections.
- M8-10 replace `_saveReceipt()` to match the deployed receipt Edge contract and persist operation identity during retry.
- M8-11 replace `_newPayment()` / `_savePayment()` with the same UUID + operation identity contract.
- M8-12 add company scoping to `_renderTransfers()`.
- M8-13 change `_newTransfer()` option values to Treasury UUID / Account UUID.
- M8-14 replace `_saveTransfer()` with the deployed transfer contract.

## Finance Production Contract Evidence
Current Production Edge versions:
- `save-journal-entry` v8
- `save-receipt-voucher` v7
- `save-payment-voucher` v5
- `save-transfer-voucher` v4
- `get-trial-balance` v1
- `get-profit-loss` v1
- `get-balance-sheet` v1
- `get-pnl-by-cost-center` v1

Current financial cores include:
- `post_journal_entry`
- `post_cash_receipt_atomic`
- `post_cash_payment_atomic`
- `post_treasury_transfer_atomic`

## Accountant App Reference
`Current/PWA/accountant.html` is the modern financial workbench reference.
It resolves authenticated `users.company_id`, loads Treasury and Chart of Accounts with company scope, and uses UUID-based financial identities plus operation IDs for transactional posting.
This is a behavioral contract reference, not a reason to replace Main8 wholesale.

## Assembly
`.github/workflows/forensic_main_assembly.yml` is verified correct:
- canonical fragment source = `Current/PWA/main2/**`
- generated target = `Current/PWA/New-main`
- historical evidence = `Current/PWA/main/**` and `Original/PWA/main/**`

### Assembly status
`FULL MAIN2 ASSEMBLY = BLOCKED`

Blocking reasons:
1. Main7 M7-15A not yet owner-applied.
2. Main7 M7-14 not yet owner-applied.
3. Main8 M8-01..M8-14 not yet owner-applied.

## Closure Matrix
- `PRODUCTION INVENTORY WRITER CORE` = CLOSED / VERIFIED
- `MAIN2 RECONSTRUCTION SOURCE PATH` = VERIFIED
- `MAIN7 FORENSIC RECONCILIATION` = COMPLETE / SOURCE SURGERY OPEN
- `MAIN7 DELIVERY CONTRACT` = PROVEN / PROTECTED
- `MAIN8 FINANCE FORENSIC RECONCILIATION` = COMPLETE / SOURCE SURGERY OPEN
- `PRODUCTION BALANCE SHEET TENANT REPAIR` = CLOSED / DEPLOYED / MIGRATION RECORDED / AUDITED
- `FULL MAIN2 ASSEMBLY` = NOT STARTED / BLOCKED
- `PARENT GOLD/DIAMOND` = NOT CLOSED

## Self-Audit — Report95
### What was proved
- Report94 is newer than the stale Report93 checkpoint and its Main7 SHA is confirmed.
- `CURRENT_STATE_Report94_Update.md` is the correct owner-supplied Main7 state checkpoint.
- Current editable source remains `Current/PWA/main2`.
- Assembly workflow path is already correct.
- Main8 current source is identified and its finance behavior was compared with the modern accountant application and deployed Production contracts.
- Production `get_balance_sheet_data` tenant leakage was real and was fixed in Production.
- The Production repair is represented in canonical Git migration form and audited.

### What was not proved
- Main7 owner surgeries have not been confirmed as applied after Report94.
- Main8 owner surgeries have not been applied.
- Full Main2 reconstruction has not been run after those source surgeries.
- Browser/E2E of the resulting assembled Parent has not been run.

### Next execution gate
After the owner applies the exact Main7 and Main8 source surgeries:
`READ SOF -> EOF -> syntax check -> full Main2 reconstruction -> browser/integration checks -> Production reconciliation -> final closure report`

## Last Verified Event
`EVENT: MAIN8-FORENSIC-RECONCILIATION-20260908`
