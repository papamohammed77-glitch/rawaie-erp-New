# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-09 — Report96 Main8 Exact Surgical Re-check

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

### Project Target
There is still a significant functional gap in the upcoming Finance, HR, CRM and Reporting tabs; many are currently structural. The Gold/Diamond target is to complete them into a competitive ERP capability set comparable in breadth and operational quality to Odoo, Dynamics, SAP, Daftra and Manager.io. This remains a target requirement and must not be implemented through speculative changes that bypass the current historical/production contracts.

## Current Git
- Repository: `papamohammed77-glitch/rawaie-erp-New`
- Branch: `main`
- Current HEAD observed before this state write: `694245eb8f2ee4f706dbecc6f33b333902e79f89`
- Current Main8 source SHA:
  `b3cdbbc79e04f5be9b2e92f9c4e98ce1e7cee64d`
- Latest documentation commit created by this session:
  `94f4128c8203fd1c0e424dca033077c022aa804e`
- Current Main7 source was last confirmed by Report94 as:
  `d6ee5ed58faf82d23bd8d0ab73f70d5979d41f19`
  and must be re-read before treating that SHA as current after later commits.

## Latest Reports / State Record
- `Report96_Main8_Exact_Surgical_Recheck_20260909.md` = latest verified session report.
- `Report95_Main8_Forensic_Surgical_Reconciliation_20260908.md` = preceding Main8 forensic report; its Main8 SHA is stale relative to current Git.
- `Report94_Main7_Exact_Surgical_Reconciliation_20260908.md` = preceding Main7 forensic reconciliation.
- `CURRENT_STATE_Report94_Update.md` = owner-supplied Main7 state checkpoint.

## Production Snapshot — latest direct verification before this state write
- companies = 1
- branches = 2
- users = 24
- items = 17
- treasury = 1
- chart_of_accounts = 17
- cash_box = 0
- orders = 0
- runsheets = 0
- stock_branches = 20
- inventory_log = 3

Current Treasury:
- id = `0a9d9357-b5f3-4dfa-886f-7c73de4f274e`
- company_id = `00000000-0000-0000-0000-000000000001`
- account_code = `CASH-01`
- account_name = `الخزينة الرئيسية`
- type = `Cash`
- current_balance = `10000.00`

Main cash account:
- account_code = `121`
- account_name = `النقدية (الخزينة الرئيسية)`
- id = `d724dae3-874d-4975-9f21-ec423a5a661a`

## Production Financial Contract — verified
Active Edge versions verified:
- `save-journal-entry` v8
- `save-receipt-voucher` v7
- `save-payment-voucher` v5
- `save-transfer-voucher` v4

Current financial cores verified:
- `post_journal_entry`
- `post_cash_receipt_atomic`
- `post_cash_payment_atomic`
- `post_treasury_transfer_atomic`

Payment contract requires Treasury UUID + Cash Account UUID + Offset Account UUID + UUID operation identity inside `header`.
Transfer contract requires source/target Treasury UUIDs + source/target Account UUIDs + UUID operation identity.

## Main8 — Current Status
Target file:
`Current/PWA/main2/main8.md`

### Direct re-check result
The file was read from the current repository state and reconciled against:
- Governance masters
- Report94
- Report95
- CURRENT_STATE_Report94_Update.md
- Current/PWA/accountant.html
- Production schema / constraints
- Current Production financial cores
- Current active financial Edge contracts
- Assembly workflow

### Confirmed applied in current Main8
The current file now contains the previously completed Main8 surgeries including:
- M8-01 company context helper
- M8-02 company-scoped finance loading
- M8-03 UUID-aware account tree
- M8-04/M8-05 treasury company scoping
- M8-06/M8-07 account CRUD/seed UUID handling
- M8-08 company-scoped cash_box reads
- M8-09/M8-10 receipt UUID + operation identity pattern
- M8-12 transfer list company scope
- M8-14 deployed transfer save contract consumer

### Remaining exact Main8 owner surgeries
These are the only Main8 source edits identified by Report96 in the current Main8 state:

1. **M8-11 `_newPayment()`** — current lines 859–864.
   Replace the complete function with the Report96 version so `pmt-cashbox` stores `treasury.id` and `pmt-main-account` stores `chart_of_accounts.id`.

2. **M8-11 `_savePayment()`** — starts at current line 871 and ends immediately before:
   `    function _renderTransfers() {`
   Replace the complete function with the Report96 version so the payload is `{header:{operationId,treasuryId,cashAccountId,offsetAccountId,date,reference,mainAccountName,notes},lines}` and the operation identity persists across retries.

3. **M8-13 `_newTransfer()`** — current line 906 and ends immediately before:
   `    async function _saveTransfer() {`
   Replace the complete function with the Report96 version so Treasury options use Treasury UUIDs and the missing `trf-source-account` / `trf-target-account` controls use Chart of Accounts UUIDs.

The assistant did **not** edit `Current/PWA/main2/main8.md` in this session.

## Main8 — Protected
Do not change in these surgeries:
- `_addPaymentLine()`
- `_saveTransfer()`
- `_renderTransfers()`
- Journal posting flow
- Reporting consumers
- Inventory/order/runsheet/delivery contracts
- Parent shell / Main1..Main11 assembly logic

## Production Impact of Report96
- No durable Production financial transaction was created.
- No Production financial schema/core change was required for M8-11/M8-13.
- Current Production contract remains the target contract.
- Production was directly queried for current counts and financial master data.

## Main7 — Current Status
Main7 remains open pending the exact owner surgeries from Report94:
- M7-15A
- M7-14

Do not assume completion from historical reports; re-read current Main7 before assembly.

## Assembly
`.github/workflows/forensic_main_assembly.yml` remains correct:
- canonical fragment source = `Current/PWA/main2/**`
- generated target = `Current/PWA/New-main`
- historical evidence = `Current/PWA/main/**` and `Original/PWA/main/**`

### Assembly status
`FULL MAIN2 ASSEMBLY = BLOCKED`

Blocking reasons currently proven:
1. Main7 requires owner verification/application of the two Report94 surgeries.
2. Main8 requires owner application of M8-11 and M8-13.
3. Full reconstruction and browser/E2E must run only after those source changes are present.

## Closure Matrix
- `PRODUCTION INVENTORY WRITER CORE` = CLOSED / VERIFIED
- `MAIN2 RECONSTRUCTION SOURCE PATH` = VERIFIED
- `MAIN7 FORENSIC RECONCILIATION` = COMPLETE / SOURCE SURGERY OPEN
- `MAIN7 DELIVERY CONTRACT` = PROVEN / PROTECTED
- `MAIN8 FINANCE FORENSIC RECHECK` = COMPLETE / TWO SURGERY AREAS OPEN
- `PRODUCTION BALANCE SHEET TENANT REPAIR` = CLOSED / DEPLOYED / MIGRATION RECORDED / AUDITED
- `FULL MAIN2 ASSEMBLY` = BLOCKED
- `PARENT GOLD/DIAMOND` = NOT CLOSED

## Self-Audit — Report96
### What was proved
- Current Git Main8 SHA is `b3cdbbc79e04f5be9b2e92f9c4e98ce1e7cee64d`.
- Report95 Main8 SHA is stale and cannot be used as current truth.
- M8-11 is still incomplete in the current Main8 source.
- M8-13 is still incomplete in the current Main8 source.
- M8-14 is already implemented as the Consumer and expects the account controls that M8-13 must create.
- Production payment and transfer contracts require UUID identities and UUID operation IDs.
- Current Production has one Treasury and zero `cash_box` rows, so a durable financial posting was not created only for test purposes.
- Assembly workflow source path is correct.
- Main8 itself was intentionally not modified by the assistant.

### What was not proved
- Owner has not yet applied M8-11/M8-13 after this report.
- Full Main8 syntax cannot be certified until those exact source edits exist in Git.
- Full Main2 reconstruction cannot be certified until Main7/Main8 owner surgeries are present.
- Parent browser/E2E cannot be certified until assembly is unblocked.

### What could still be wrong
After owner application, the required gate is:
`SOURCE READ -> SYNTAX CHECK -> FULL MAIN2 RECONSTRUCTION -> BROWSER/INTEGRATION -> PRODUCTION RECONCILIATION`

## Last Verified Event
`EVENT: MAIN8-EXACT-SURGICAL-RECHECK-20260909`
