# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-16

## GOVERNING BASIS
`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`
Historical reports are reference-only.

## SOURCE OF TRUTH
Mother Finance/UI:
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

Historical/reference only:
`rawaie-erp-New/Current/PWA/main2/*`
`rawaie-erp-New/Original/PWA/main/*`

`forensic_main_assembly.yml` was verified correct and already points to the published Mother file.

## CURRENT FRONTEND GIT
Repository: `papamohammed77-glitch/erp-frontend`
Branch: `main`
Latest HEAD: `0849e7e04fe79e9391f7388624dd9aa42de33a0f`
Direct parent: `2afa7465a18023f7bba5f60b8d0a08d69de3fd80`
Parent message: `Update finance management sections in main.html`
Current `main.html` blob observed: `9c49f77167107e0f56c3c0093bb9c70ccff2ac68`

## MOTHER FINANCE FORENSIC

Commit `2afa...` added Finance menu/tabs and dispatch, but its GoldExtension had missing runtime handlers. Proven missing names included:
`_renderExpenses`, `_renderCheques`, `_goldAddAsset`, `_goldTaxCode`, `_goldOpenPeriod`, `_goldClosePeriod`, `_goldNewBankStatement`, `_goldNewRecurring`.

The assistant did not modify `erp-frontend/main.html`.

Surgical patches are recorded in:
`doc/Draft/Reprots/Report214_MOTHER_FINANCE_EXECUTION_20260916.md`
`doc/Draft/Reprots/Report215_MOTHER_FINANCE_UI_HANDLER_PATCH_20260916.md`

## PRODUCTION FINANCE — IMPLEMENTED

Supabase Production: `fiilmooggumokxanwiyx`

Implemented/expanded:
- central `post_journal_entry` protections and period guard
- journal detail/reverse/list contracts
- recurring journal runtime + run history
- expense categories, expense lines, expenses, payable/cash posting, tax linkage
- tax transaction source references, tax code management, tax settlement/report
- bank statements, bank lines, match/unmatch/exclude/include, reconciliation close
- fixed asset acquisition/depreciation/disposal lifecycle
- cheque register + lifecycle events + guarded transitions
- financial period open/close/reopen
- finance runtime health
- RLS/realtime for new finance operational tables
- legacy cheque direct writes disabled
- legacy inventory voucher v2 direct execution disabled

## IMPORTANT CORRECTIONS

1. Expense without treasury now credits payable account 211 so the journal remains balanced.
2. Period closure is enforced at the central journal writer, not only in UI.
3. Bank close requires balance equality and zero unmatched non-excluded lines.
4. Tax settlement links source transactions to settlement and period where applicable.
5. Tax code management is now backed by `finance_save_tax_code`.
6. Legacy cheque table is historical-only for authenticated/anon writes.

## INVENTORY / FIELD OPS

No field operational redesign was performed in this Finance session.
The established physical stock contract remains:
`Physical Movement → post_stock_movement → stock_branches + inventory_log`

## OPEN VERIFICATION

```text
Authenticated Mother Finance Browser E2E = OPEN
Tax full lifecycle = BACKEND IMPLEMENTED / BROWSER OPEN
Asset full lifecycle = BACKEND IMPLEMENTED / BROWSER OPEN
Bank full reconciliation = BACKEND IMPLEMENTED / BROWSER OPEN
Recurring journal runtime execution = BACKEND IMPLEMENTED / SCHEDULER + BROWSER OPEN
```

Production currently has no `pg_cron`/`pg_net`; recurring automation scheduler remains a separate infrastructure closure.

## WHY NOT 100% CLOSED

The Mother frontend remains owner-controlled and the exact surgical patches have not yet been merged into `erp-frontend/main.html`.
Authenticated Browser/Console/Network E2E was not honestly available from this execution context and remains mandatory.

## LATEST REPORTS

`doc/Draft/Reprots/Report214_MOTHER_FINANCE_EXECUTION_20260916.md`
`doc/Draft/Reprots/Report215_MOTHER_FINANCE_UI_HANDLER_PATCH_20260916.md`

## NEXT SESSION START ORDER

1. Start from current HEAD `0849...` and parent `2afa...`.
2. Re-fetch current `main.html`; never trust a historical line number without recalculating it.
3. Verify Production schema and deployed RPCs again.
4. Check whether Report214/215 surgery has already been merged; do not reapply completed edits.
5. Run authenticated Mother Finance Browser E2E with Console and Network inspection.
6. Verify each Finance closure unit against same-moment Production.
7. Close authenticated Finance E2E before moving to another management area.
