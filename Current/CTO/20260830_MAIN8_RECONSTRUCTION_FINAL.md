# MAIN8 FORENSIC RECONSTRUCTION — FINAL

EVENT ID: EVENT-20260830-MAIN8-FORENSIC-RECONSTRUCTION
DATE: 2026-08-30
SOURCE: Current Git + Production Supabase + current Edge Functions + historical governance records + accountant control-center application
OBJECTIVE: Rebuild Current/PWA/main/main8.md from zero without losing the existing finance surface or public RW_Finance contract, and align its data/auth/posting boundaries with the current Production architecture.

## PRE-SWEEP SELF-AUDIT

Business Understanding: Finance fragment covering treasury, chart of accounts, manual journals, receipts, payments, treasury transfers, financial reports and budgets.
Architecture Understanding: main8 is a UI/orchestration fragment. Posting ownership remains in current Edge/RPC capabilities; it is not a financial engine.
Database Understanding: Current Production uses company_id on treasury/chart_of_accounts/journal_entries; journal_lines are scoped through journal_entries; budgets derive tenant ownership through account_id → chart_of_accounts; cost_centers are global/shared in current schema.
Historical Understanding: Governance requires UNDERSTAND → historical contract → current behavior → data/auth flow → target → surgical change → verify. Reports 89–103 were treated as historical evidence, not as Current Production truth.
Current Git Understanding: Previous main8 blob was 20f77481133d3e55ced949de16f88dadb0a69980. Final rewritten blob is da64f6e68070bc296e6672fb032cfcc54efe90a5a. Final main HEAD is 30c99cb3e4418eff7e096c3972bbb78ea8ac4ea8.
Current Production Understanding: One company, 24 users, 2 branches, 17 items, 20 stock rows, 3 inventory logs, 0 orders, 0 purchase orders, 0 cash_box rows, 0 budgets, 10,000 current treasury balance. These figures were re-read directly immediately before closure.
Deployment Understanding: Production database migration `main8_finance_tenant_and_budget_closure` was applied successfully. The PWA fragment itself is not independently deployable; it becomes runtime-active only after final main.html assembly and hosting.
Runtime Understanding: Current PostgreSQL cash/journal capabilities were executed transactionally against the real Production schema and rolled back. Browser authenticated PWA E2E remains a separate assembly-stage verification and is not falsely claimed here.

## CONFIRMED FACTS

- Current `Current/PWA/main/main8.md` was opened in chunks through its end before replacement.
- Current `Original/PWA/main/main8.md` existed and initially matched the current main8 SHA.
- `items.item_code` is globally UNIQUE in Production.
- `chart_of_accounts` is unique by `(company_id, account_code)` and `parent_account_id` is a UUID FK to the same table.
- `treasury` is unique by `(company_id, account_code)`.
- `budgets` is unique by `(cost_center_id, account_id, budget_year, budget_month)`.
- `post_journal_entry`, `post_cash_receipt_atomic`, `post_cash_payment_atomic`, and `post_treasury_transfer_atomic` are active SECURITY DEFINER cores in Production.
- Current receipt/payment Edge adapters require `{header, lines}`, explicit operation_id, treasury UUID, cash account UUID and offset account UUID.
- Current transfer Edge adapter requires operationId, source/target treasury UUIDs and source/target account UUIDs.
- Accountant Control Center also uses authenticated user → users.auth_id → company_id and explicit UUID account/treasury identities.
- Finance report functions `get_trial_balance`, `get_profit_loss`, `get_balance_sheet`, and `get_pnl_by_cost_center` are current company-aware report contracts.
- `get_balance_sheet_data` and `get_account_balance_as_of` are older SECURITY DEFINER helpers; main8 does not use the broader unsafe helper path and instead calls `get_balance_sheet`.

## HISTORICAL CONTRACT

The original main8 public module was `RW_Finance` with the following public functions, and all were preserved:

render
renderSubTab
_filterTreasury
_openTreasuryDialog
_editTreasury
_filterAccounts
_openAccountDialog
_seedAccounts
_addJournalLine
_removeJournalLine
_recalcJournalTotal
_saveJournalEntry
_newReceipt
_addReceiptLine
_removeReceiptLine
_recalcReceiptTotal
_saveReceipt
_newPayment
_addPaymentLine
_removePaymentLine
_recalcPaymentTotal
_savePayment
_newTransfer
_saveTransfer
_trialBalance
_profitLoss
_renderBudgets
_loadBudgetsList
_editBudget
_balanceSheet
_costCenterProfitLoss

## CURRENT PRODUCTION FACT

The previous main8 implementation contained unscoped finance reads, direct treasury writes without company_id, old cash voucher payload semantics, transfer identity by treasury account_code, an invalid parent_account_id assumption for chart-of-accounts, unscoped cash-box transfer reads, and a budget write/read contract that did not enforce tenant ownership.

The current Production finance core is operation-aware and UUID-based. The current receipt/payment adapters sum the UI `lines` into one transaction amount and use one explicit offset account. This is why the reconstructed UI retains multiple detail lines as an allocation/description surface while requiring a single explicit offset account for the accounting posting contract.

## CHANGE MADE

Current/PWA/main/main8.md was rebuilt from scratch and now:

1. Resolves company identity from `RW_ShellContext.getCompanyId()` and fails closed when unavailable.
2. Applies explicit `company_id` filters to all company-owned direct reads.
3. Uses treasury UUIDs rather than account-code strings as transaction identity.
4. Uses chart-of-accounts UUIDs for parent/account identities and preserves account-code labels for user-facing lookup.
5. Uses current `save-journal-entry`, `save-receipt-voucher`, `save-payment-voucher`, and `save-transfer-voucher` contracts.
6. Preserves operation_id for retries for journals, cash vouchers and treasury transfers.
7. Uses `get_balance_sheet` rather than the broader unscoped SECURITY DEFINER helper.
8. Uses the tenant-scoped `get_budget_vs_actual` contract.
9. Explicitly scopes cash-box transfer history by company.
10. Restores budget cost-center selection to the actual selected UUID instead of silently writing NULL.
11. Keeps all legacy RW_Finance public exports so later main1…main11 assembly remains compatible.
12. Adds escaping at rendered finance data boundaries.

## BACKEND DEPENDENCY CHANGE

Production migration applied:
`main8_finance_tenant_and_budget_closure`

It:
- added company-scoped INSERT/UPDATE/DELETE policies for treasury;
- replaced the broad `budgets_access` policy with tenant ownership through `chart_of_accounts.company_id`;
- rebuilt `get_budget_vs_actual` with current-user company scoping;
- kept SECURITY DEFINER only where necessary and removed public/anonymous execute from the rebuilt budget report.

The same migration is now stored in Git as:
`supabase/migrations/20260830090000_main8_finance_tenant_and_budget_closure.sql`

## TESTS

### Static/source verification
- Final main8 blob exists in Git with SHA `da64f6e68070bc296e6672fb032cfcc54efe90a5a`.
- Final main branch points to commit `30c99cb3e4418eff7e096c3972bbb78ea8ac4ea8`.
- Public RW_Finance export surface was preserved explicitly in the final return object.
- The fragment contains no direct stock_branches or inventory_log writer.

### Production transactional runtime verification
A real Production transaction exercised `post_cash_payment_atomic` using the current treasury and chart-of-accounts UUIDs. The returned result was successful, balanced at 0.75 debit / 0.75 credit, created journal and cash-box IDs, then the transaction was rolled back.

### Negative guard verification
A treasury transfer using the same source and target treasury was rejected by Production with `TREASURY_TRANSFER_SOURCE_EQUALS_TARGET`.

### Post-test data verification
After rollback:
- journal_entries = 2
- journal_lines = 0
- cash_box = 0
- budgets = 0
- treasury rows = 1
- treasury balance = 10,000.00
- audit rows = 1,866

No QA cash/journal/transfer data was intentionally left behind.

## DATA FINDING — JOURNAL ENTRIES

Two existing journal headers have zero journal lines:
- `JE-VOID-1784927448473-476`, status `Cancelled`, reference `VOID-ORD-1015`
- `JE-VOID-1784927457858-428`, status `Cancelled`, reference `VOID-ORD-1016`

These were not deleted or rewritten because their explicit Cancelled/VoidInvoice semantics demonstrate historical void records rather than orphaned Posted entries. No data repair was justified by guesswork.

## AUDIT PRESERVATION

Current Production audit infrastructure includes the `audit_log` table and the current stock-voucher audit trigger path via `fn_audit_trigger()`. The finance posting cores also create auditable records through their posting paths. Test transactions were rolled back, so test audit rows were not retained.

## WHAT I PROVED

- main8 was fully opened before replacement, not inferred from a single snippet.
- Current Production finance contracts were inspected directly.
- Current accountant/finance consumer patterns were inspected.
- The main8 fragment was reconstructed without adding a new financial posting engine.
- All known company-owned finance reads in the fragment are now explicitly scoped.
- Cash/journal/transfer posting uses current operation-aware Edge/RPC contracts.
- Treasury and budget tenant boundaries were strengthened in Production.
- The final source is stored on the main branch and the supporting migration is stored in Git.
- Production transaction smoke testing succeeded and left no test data behind.

## WHAT I DID NOT PROVE

- An authenticated browser E2E session executing the assembled `main.html` after merging main1…main11.
- Live PWA hosting/CDN deployment of the final assembled artifact.
- Full repository-wide zero-debt certification outside the main8 closure unit.

These are explicitly not converted into PASS claims.

## WHAT I CHANGED

- `Current/PWA/main/main8.md`
- `supabase/migrations/20260830090000_main8_finance_tenant_and_budget_closure.sql`
- `Current/CTO/20260830_MAIN8_RECONSTRUCTION_FINAL.md`
- Production RLS/function boundary through the matching migration.

## WHAT I DID NOT CHANGE

- Inventory balances.
- `post_stock_movement`.
- Existing Inventory Writers.
- Orders, purchases, customers, suppliers or stock data.
- Owner wildcard semantics.
- Other main fragments.
- Live PWA hosting configuration.

## WHAT I DISCOVERED

1. main8 was substantially behind the current finance capability layer even though the current accountant application had already adopted UUID-based operation contracts.
2. Chart-of-accounts parent identity had to be corrected from account code semantics to UUID FK semantics.
3. Treasury CRUD had no authenticated write policies; this was a real backend blocker for preserving the historical UI feature.
4. Budget RLS was too broad and its report function was too weakly scoped for a multi-tenant ERP.
5. The current Production dataset is much smaller than historical snapshots; this was reconfirmed before closure.
6. The two zero-line journal headers are explicitly cancelled void records and were therefore preserved.

## WHAT I INITIALLY MISSED

The initial inventory-oriented investigation exposed that finance posting was already operation-aware, but did not initially distinguish the main8 UI transport drift from the backend posting contract. The direct inspection of current accountant and Edge adapters resolved that boundary before the rewrite.

## WHAT BECAME OBSOLETE

- Treasury selection by account-code string in transaction posting.
- Free-text account name as accounting identity for cash vouchers.
- `MAIN`/implicit treasury identity assumptions.
- Chart-of-accounts parent account-code storage in `parent_account_id`.
- Global treasury/cash-box/budget reads from main8.
- Calling the broader balance-sheet JSON helper from main8.

## WHAT REMAINS OPEN

Only integration-stage items that cannot truthfully be certified from a fragment alone:
- final main.html assembly;
- authenticated browser E2E against the assembled artifact;
- live hosting/CDN verification.

These do not invalidate the main8 source closure.

## WHAT COULD STILL BE WRONG

A cross-fragment coupling defect can only be exposed by the final assembly/runtime. No such defect was inferred or fabricated during this closure.

## STATUS

PRODUCTION DEPLOYED? YES — supporting finance tenant/budget migration.
PRODUCTION RUNTIME VERIFIED? PARTIAL — direct PostgreSQL finance posting smoke verified; assembled PWA browser runtime not yet verifiable from this fragment.
AUDIT VERIFIED? YES — infrastructure verified; transactional tests rolled back.
DATA VERIFIED? YES — current counts and post-test state re-read; no test residue.
CURRENT GIT ALIGNED? YES — source and migration are on current main HEAD.

FINAL CLOSURE STATUS

MAIN8 SOURCE RECONSTRUCTION = CLOSED
MAIN8 FINANCE BACKEND DEPENDENCY CLOSURE = CLOSED
MAIN8 PRODUCTION DATABASE INTEGRATION = VERIFIED
MAIN8 ASSEMBLED PWA RUNTIME = PENDING FINAL ASSEMBLY
GLOBAL PWA ZERO-DEBT = NOT CERTIFIED YET
