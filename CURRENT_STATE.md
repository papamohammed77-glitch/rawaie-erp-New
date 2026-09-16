# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-16

## GOVERNING BASIS

Current truth is derived only from:
`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

Historical reports are reference-only.

## SOURCE OF TRUTH

Mother Finance/UI Source of Truth:
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

Historical/reference only:
`rawaie-erp-New/Current/PWA/main2/*`
`rawaie-erp-New/Original/PWA/main/*`

`forensic_main_assembly.yml` was rechecked and already points to the correct published Mother file. No change was required.

## CURRENT FRONTEND GIT

Repository: `papamohammed77-glitch/erp-frontend`
Branch: `main`
Latest HEAD: `0849e7e04fe79e9391f7388624dd9aa42de33a0f`
Latest message: `forensic: persist current Mother inventory extract`
Direct parent: `2afa7465a18023f7bba5f60b8d0a08d69de3fd80`
Parent message: `Update finance management sections in main.html`

HEAD `0849...` does not modify `main.html`; the latest Mother Finance source change remains parent `2afa...`.

Current `main.html` blob SHA observed: `9c49f77167107e0f56c3c0093bb9c70ccff2ac68`.

## CURRENT MOTHER FINANCE FORENSIC FINDING

`2afa...` added the Finance navigation and dispatch for:
- treasury
- accounts
- journal-list
- journal
- recurring-journals
- receipts
- payments
- expenses
- transfers
- cheques
- bank-reconcile
- tax
- assets
- budgets
- periods
- reports
- installments
- commission

But the GoldExtension contained only:
`journalList, renderAssets, renderTax, renderPeriods, renderBankReconcile, renderRecurring`

while dispatch/buttons referenced missing handlers including:
`_renderExpenses`, `_renderCheques`, `_goldAddAsset`, `_goldTaxCode`, `_goldOpenPeriod`, `_goldClosePeriod`, `_goldNewBankStatement`, `_goldNewRecurring`.

A complete surgical patch was prepared and recorded in:
`doc/Draft/Reprots/Report214_MOTHER_FINANCE_EXECUTION_20260916.md`

The assistant did not edit `erp-frontend/companies/company-1/main.html`; owner surgery remains required.

## PRODUCTION FINANCE IMPLEMENTATION — ACTUAL

Supabase Production project:
`fiilmooggumokxanwiyx`

Implemented/expanded Production contracts:
- Journal detail / reverse / central posting protection.
- Recurring journal templates + lines + runtime execution + run history.
- Expense categories + expenses + expense lines + journal linkage.
- Tax transaction source reference + tax settlement + settlement report.
- Bank statement + statement lines + match/unmatch/exclude/include + close validation.
- Fixed asset acquisition + depreciation existing contract + disposal lifecycle.
- Cheque register + lifecycle events + state transitions.
- Period open/close/reopen + period guard at central journal posting.
- Finance runtime health snapshot.
- Realtime publication and RLS for newly introduced finance operational tables.
- Legacy cheque direct write permissions removed from authenticated/anon.

The production financial mutation design intentionally does not create a second accounting engine:
`Finance operation → post_journal_entry → journal_entries/journal_lines`

## IMPORTANT PRODUCTION CORRECTIONS MADE DURING SESSION

1. Expense posting was corrected so a non-treasury expense has a valid payable credit (account 211) instead of leaving an unbalanced journal.
2. Period protection was moved to the central `post_journal_entry` engine, not left to UI behavior.
3. Tax settlement links transactions to a settlement and, when available, the containing finance period.
4. Bank statement closing now requires balance agreement and no unmatched non-excluded lines.
5. Legacy cheque writes were disabled to prevent dual-write paths.
6. Legacy inventory voucher v2 writes were revoked; field/stock operational chains were otherwise left intact.

## PRODUCTION DATA SAFETY

No destructive cleanup of business inventory fixtures was performed in this Finance session. Existing fixture-like inventory records previously observed remain untouched because this session did not establish sufficient evidence to delete them safely.

## OPEN VERIFICATION

```text
Authenticated Mother Finance Browser E2E = OPEN
Tax full lifecycle = BACKEND IMPLEMENTED / BROWSER OPEN
Asset full lifecycle = BACKEND IMPLEMENTED / BROWSER OPEN
Bank full reconciliation = BACKEND IMPLEMENTED / BROWSER OPEN
Recurring journal runtime execution = BACKEND IMPLEMENTED / SCHEDULER + BROWSER OPEN
```

The current Production environment has no `pg_cron` or `pg_net`, so recurring automation is not yet an automatic scheduler contract.

## WHY 100% FINANCE CLOSURE IS NOT CLAIMED

The current Mother source still contains UI/runtime holes found from the actual current Git diff. The surgical replacement is prepared but has not been merged into the owner-controlled Mother repository.

A true authenticated browser pass is therefore still required and must not be replaced by SQL-only tests.

## LATEST REPORT

`doc/Draft/Reprots/Report214_MOTHER_FINANCE_EXECUTION_20260916.md`

## NEXT SESSION START ORDER

1. Start from current HEAD `0849...` and parent `2afa...`.
2. Re-fetch current `main.html` and recalculate its fingerprint before using any line number.
3. Verify Production schema and deployed function definitions again.
4. Check whether the owner merged Report214 Mother surgery; do not reapply a completed change.
5. Run authenticated Mother Finance browser E2E.
6. Verify Console = 0 and inspect Network for every finance RPC.
7. Execute one finance closure unit at a time and compare UI results with same-moment Production.
8. Close authenticated Mother Finance E2E before moving to another department.
