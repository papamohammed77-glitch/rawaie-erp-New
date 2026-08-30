# RAWAEA ERP — MAIN9 RECONSTRUCTION FINAL
Date: 2026-08-30

## EVENT ID
MAIN9-RECON-20260830

## OBJECTIVE
Reconstruct `Current/PWA/main/main9.md` from current Git/Production contracts, preserve the public reporting surface, eliminate tenant/identity drift, and keep the fragment read-only and integrable into the final main.html.

## PRE-CHANGE SELF-AUDIT
Business Understanding: main9 is the reporting/analytics layer for sales, inventory, finance, CRM, logistics and HR.
Architecture Understanding: fragment is read-only; shell tenant context is supplied by `RW_ShellContext.getCompanyId()` / `RW_STATE.app.companyId`.
Database Understanding: current Production uses UUID identities for customer/item/account/treasury/driver/runsheet; `items.item_code` is globally UNIQUE; company_id exists on major master/transaction tables.
Historical Understanding: previous main9 exposed `RW_Reports` and `RW_Reports_Comprehensive`, with 32 report IDs and drill-down/print capabilities.
Current Git Understanding: prior `main9.md` SHA was `288b642d050f8b5ddeb6d43a7fd2a992fb05bb03` and was effectively the old/original implementation.
Current Production Understanding: current Production snapshot showed 1 company, 24 users, 2 branches, 17 items, 3 inventory logs, 20 stock rows, and no current orders/runsheets/POs/receiving records.
Deployment Understanding: this fragment has no database or Edge deployment requirement by itself.
Runtime Understanding: browser-assembled main.html runtime was not independently executed in this task.

## CONFIRMED FACTS
- Current Production Inventory integrity query returned zero negative quantity, zero negative allocation, zero available-quantity mismatch, and zero cross-company stock rows.
- `stock_branches` is unique by `(branch_id,item_id)`.
- `items.item_code` is protected by a global UNIQUE constraint.
- Current finance reporting RPCs are `get_trial_balance`, `get_profit_loss`, `get_balance_sheet`, `get_cash_flow`, and are company-aware.
- `stock_vouchers` has an audit trigger through `fn_audit_trigger()`.
- Current shell provides a company-scoped context API.

## UNKNOWN / NOT PROVEN
- Full browser E2E of the final assembled `main.html` containing main1..main11 was not executed.
- No claim is made that every visual pixel is identical to the historical fragment.

## CHANGE
Replaced `Current/PWA/main/main9.md` with a complete compact reconstruction preserving:
- `RW_Reports.renderDashboard`
- `RW_Reports.renderDetailedReports`
- `RW_Reports_Comprehensive.render`
- `_openSection`, `_closeSection`, `_openReport`, `_generateReport`, `_printReport`
- `_showCustomerLedgerDetail`, `_showItemMovementDetail`, `_showRunsheetDetail`, `_showSettlementDetail`
- All 32 report IDs across Sales, Inventory/Purchasing, Finance, CRM, Logistics and HR.

## CRITICAL FIXES
- Explicit tenant scoping for company-owned tables.
- UUID-correct selectors for customer, item, account, treasury, driver and runsheet identities.
- Stock reads constrained through company branches; no physical stock writes.
- Order detail reads derive from already company-scoped order IDs.
- General-ledger reads are constrained by joined `journal_entries.company_id`.
- Current finance RPC names are used directly instead of stale Edge-function names.
- Placeholder capabilities remain placeholders where Production has no verified source; no fabricated business data was introduced.
- Drill-downs validate current-company ownership before displaying details.

## PRODUCTION
No database mutation or Edge deployment was required for main9. Production inventory data remained untouched by this reconstruction.

## GIT COMMIT
`eb021df39f4097947e1d7ed61ab40227441d8d3a`
Path: `Current/PWA/main/main9.md`

## PRODUCTION POST-CHECK
Production remained structurally consistent after the source-only change. No inventory correction was performed as part of main9 because the current invariant check was already clean.

## AUDIT PRESERVATION
No historical production row was deleted, rewritten, or migrated by the main9 reconstruction.

## FINAL STATUS
MAIN9 SOURCE RECONSTRUCTION: CLOSED
CURRENT GIT ALIGNED: YES
PRODUCTION DATABASE DEPLOYMENT: NOT REQUIRED
PRODUCTION RUNTIME VERIFIED: NOT PROVEN (requires assembled main.html/browser E2E)
NO NEW DATABASE DEBT INTRODUCED: YES
