# RAWAEA ERP — CURRENT STATE

**Last updated:** 2026-09-12
**Current checkpoint:** Main8 forensic recheck completed; Production finance contracts reverified; Main8 owner surgical replacement package recreated; Main8 source fragment itself was not edited by the assistant.

## Governing Rules

- Production is a first-class source of truth and must be rechecked at the time of every report.
- Reports are evidence, not truth.
- `NO EVIDENCE = NO CLAIM`.
- `NO FUNCTIONAL TEST = NO FUNCTIONAL VERIFICATION`.
- `NO PRODUCTION CHECK = NO PRODUCTION VERIFICATION`.
- `NO CROSS-MODULE TRACE = NO BUSINESS COMPLETION`.
- `NO DATA CHECK = NO DATA CLOSURE`.
- Study/history reconstruction precedes surgical change.
- Owner edits the `Current/PWA/main2/main1..main11.md` source fragments; assistant performs Production DB/Edge/data verification and changes when a proven Production gap exists.
- Assembly remains deferred until all eleven fragments are owner-verified.

## Gold/Diamond Mission

هناك نقص شديد في كل التبويبات ، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا تتعامل معه كإضافات شكلية.
وهذا متسق حرفيًا مع مبدأ الحوكمة: الدراسة أولًا، ثم إعادة بناء العقد التاريخي، ثم تتبع السلوك الحالي، ثم تحديد الفجوة، ثم التعديل الجراحي، ثم الاختبار والتحقق.

## Source of Truth

- `Current/PWA/main2/main1.md`
- `Current/PWA/main2/main2.md`
- `Current/PWA/main2/main3.md`
- `Current/PWA/main2/main4.md`
- `Current/PWA/main2/main5.md`
- `Current/PWA/main2/main6.md`
- `Current/PWA/main2/main7.md`
- `Current/PWA/main2/main8.md`
- `Current/PWA/main2/main9.md`
- `Current/PWA/main2/main10.md`
- `Current/PWA/main2/main11.md`

Historical reference only:
`Original/PWA/main/*`

Forbidden/retired sources:
`Current/PWA/main/*`
`Current/PWA/New-main/*`

`forensic_main_assembly.yml` is correctly configured for `Current/PWA/main2`, with `Original/PWA/main` as historical reference and assembly deferred until all fragments are owner-verified. fileciteturn1308file0L1-L6

## Fragment SHAs — latest directory evidence

- main1 `f68d47c7574c34f678cfba2aafa5ad294aadbfe5`
- main2 `65815e23b03e29c125957e6fe283cc1e253a7f7d`
- main3 `eeb56daf8cd01b31b8a7e5f5ada4f1a09df30bfe`
- main4 `e9f967859aeda729cd0811739a280ceec5266d7c`
- main5 `800ad51c88a2e80d060480990836a3c975c7435a`
- main6 `1dc500849a600e6436c1d319bdc93f3d270f6af9`
- main7 `5839252a9807ae1758939dad754a4f3a4505c76f`
- main8 `2131fbf3096d926b2486acb2ab58a4266ddd1bbc`
- main9 `b9f10ae4e727cb9495aaecbe2d752dabf13ec776`
- main10 `169025a6836c7fdc7281ea86523b975a84d889f1`
- main11 `2adfc787c3e5f0ca56abfcc85232e7a971773c3b`

Directory evidence confirms the eleven Source-of-Truth fragments exist under `Current/PWA/main2`. fileciteturn1312file0L1-L10

## Previous Checkpoints

Report125 established Main6 forensic recheck and owner replacement status.
Report126/Report127 established Main7/Main8 forensic checkpoints and surgical-owner methodology.

## Main8 — 2026-09-12

Current source:
`Current/PWA/main2/main8.md`
Current SHA:
`2131fbf3096d926b2486acb2ab58a4266ddd1bbc`

Main8 was re-read from the beginning through EOF using the repository blob, then targeted ranges were re-opened around every known surgical anchor. The source SHA remained unchanged because the assistant did not edit the owner fragment. fileciteturn1296file0L2-L6

Historical reference inspected:
`Original/PWA/main/main8.md`

The prior replacement file was independently checked and was genuinely missing at the expected path. A replacement package was created at:
`doc/Draft/Reprots/MAIN8_OWNER_SURGICAL_REPLACEMENTS_20260912.js`
SHA:
`ec92a73e81169f5aa653b14e3185b8b2934c419d` fileciteturn1341file0L2-L6

### Confirmed Main8 source gaps

1. `_editTreasury(code)` rewrote both opening/current balance during a name/type edit and allowed deletion without checking cash history.
2. `_filterAccounts()` searched only root nodes and missed child matches.
3. `_openAccountDialog(editId)` made new account code readonly and allowed account type changes during edit.
4. `_profitLoss()` displayed revenue only although Production returns revenue, expenses and totals/net profit.
5. `_balanceSheet()` displayed assets/liabilities but omitted equity.
6. `_renderReports()` did not expose the Production `get_cash_flow` capability.
7. `_editBudget()` always wrote `cost_center_id = null` and performed direct table upsert rather than the established atomic/idempotent RPC.
8. Production exposes additional authenticated accounting-control RPCs that were not exposed in Main8: GL activity, period readiness, reconciliation summary, exception center, customer aging, supplier aging.

### Main8 production contracts reverified

- `get_profit_loss(p_from_date,p_to_date)` — Production callable and company-scoped.
- `get_balance_sheet_data(p_as_of)` — Production returns assets, liabilities, equity.
- `get_cash_flow(p_from_date,p_to_date)` — Production callable and company-scoped.
- `get_budget_vs_actual(p_year,p_month,p_cost_center_id)` — Production callable.
- `save_budget_atomic(...)` — Production callable, company/account/cost-center validated, operation registry supported.
- `accountant_gl_account_activity(...)` — authenticated execute grant exists.
- `accountant_period_readiness(...)` — authenticated execute grant exists.
- `accountant_reconciliation_summary(...)` — authenticated execute grant exists.
- `accountant_exception_center(...)` — authenticated execute grant exists.
- `accountant_customer_aging(...)` — authenticated execute grant exists.
- `accountant_supplier_aging(...)` — authenticated execute grant exists.

### Main8 Production changes performed in this session

1. `main8_budget_report_aggregate_fix`
   - Replaced the budget-vs-actual budget-side join with account-level aggregation to prevent future duplicate account rows when multiple cost centers exist.

2. `main8_budget_actual_cost_center_alignment`
   - Rewrote the Production `get_budget_vs_actual` contract so the actual amount is filtered by `journal_lines.cost_center_id` when a cost center is selected.
   - When the filter is `NULL`, actuals aggregate across the account as the UI label `الكل` indicates.

Both changes preserve the RPC signature and do not create a parallel reporting engine.

### Production data/schema facts used for Main8

- `journal_lines.cost_center_id` exists in Production.
- `budgets` does not carry `company_id`; company isolation is through account/company context.
- `cost_centers` is global in the current schema; no synthetic company column/filter was introduced.
- `items.item_code` is globally unique, but this fact belongs to inventory identity and was not altered by Main8.

### Owner surgical application status

The assistant did not modify `Current/PWA/main2/main8.md`.
The owner must apply only the exact sections in:
`doc/Draft/Reprots/MAIN8_OWNER_SURGICAL_REPLACEMENTS_20260912.js`

Required order:

- O1 `_editTreasury(code)` — current line 181; delete through the final `}` immediately before `// ==================== دليل الحسابات ====================`.
- O2 `_filterAccounts()` — current line about 258; delete through the final `}` immediately before `function _openAccountDialog(editId) {`.
- O3 `_openAccountDialog(editId)` — current line about 272; delete through the final `}` immediately before `async function _seedAccounts() {`.
- O4 `_renderReports()` — current line 1022; delete through the final `}` immediately before `function _trialBalance() {`.
- O5 `_profitLoss()` — current line 1051; delete through the final `}` immediately before `function _renderBudgets() {`.
- O8 `_loadBudgetsList()` — current line 1093; delete through the final `}` immediately before `function _editBudget(accountId, accountName, year, month) {`.
- O9 `_editBudget(...)` — current line 1113; delete through the final `}` immediately before `function _balanceSheet() {`.
- O7 add `_cashFlow()` immediately above `function _balanceSheet() {`.
- O6 replace `_balanceSheet()` before `function _costCenterProfitLoss() {`.
- O11–O16 add the advanced Production-backed report functions immediately before the final `return {`.
- O10 update the final return object to export the newly added report functions.

### Syntax/Runtime honesty

The exact owner replacement file was committed, but an independent executable `node --check` could not be run against the repository blob in this session because the connected GitHub source was not materializable into the local runtime. Therefore no false `SYNTAX_OK` claim is recorded for that artifact.

The final syntax of `main8.md`, Browser E2E, and authenticated runtime behavior remain pending owner application. This is intentional: Main8 source SHA has not changed.

## Main7 Carryover

Main7 owner source application and final runtime closure remain pending from the previous checkpoint. Current directory evidence now reports Main7 SHA `5839252a9807ae1758939dad754a4f3a4505c76f`; previous state SHA was stale. No claim is made here that the pending owner surgeries were applied.

## Production / Source Alignment Rules

- `forensic_main_assembly.yml` remains on `Current/PWA/main2`.
- `Current/PWA/main` and `Current/PWA/New-main` remain retired/forbidden sources.
- No assembly was performed.
- No Main8 source fragment was directly modified by the assistant.

## Closure Status

```text
MAIN8 FULL SOURCE READ = PASS
MAIN8 HISTORICAL REVIEW = PASS
MAIN8 PRODUCTION FINANCIAL CONTRACT TRACE = PASS
MAIN8 PRODUCTION BUDGET FIXES = DEPLOYED
MAIN8 OWNER SURGICAL PACKAGE = RECREATED
MAIN8 OWNER SOURCE APPLY = PENDING
MAIN8 FINAL SOURCE SYNTAX = PENDING
MAIN8 BROWSER E2E = PENDING
MAIN8 AUTHENTICATED RUNTIME = PENDING
MAIN8 MAIN1..MAIN11 FINAL INTEGRATION = PENDING
MAIN8 GOLD/DIAMOND = NOT CLOSED
ASSEMBLY = DEFERRED
```

## Next Gate

1. Owner applies the exact Main8 surgical replacements.
2. Re-read Main8 from first character through EOF.
3. Run executable syntax validation on the complete Main8 source.
4. Check duplicate declarations, braces, strings, template/HTML escaping, and Console errors.
5. Compare Main8 interfaces against Main7 and Main9.
6. Run authenticated Browser/E2E for treasury, COA, journal, receipts, payments, transfers, reports and budgets.
7. Verify Production responses and retry/idempotency behavior where applicable.
8. Re-sync Production immediately before the next report.
9. Only after Main8 closes, continue to the next fragment; assembly remains forbidden until all fragments close.
