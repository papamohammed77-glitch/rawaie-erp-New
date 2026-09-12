# RAWAEA ERP — CURRENT STATE

**Last updated:** 2026-09-12
**Current checkpoint:** Main9 forensic recheck completed; Main9 owner surgical package created; Main9 source fragment was not edited by the assistant. Production contracts used by Main9 reports were reverified live.

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

`forensic_main_assembly.yml` is verified against `Current/PWA/main2`; assembly remains deferred. fileciteturn1321file0L2-L6

## Fragment SHAs — latest verified source snapshot

- main1 `f68d47c7574c34f678cfba2aafa5ad294aadbfe5` fileciteturn1341file0L2-L6
- main2 `65815e23b03e29c125957e6fe283cc1e253a7f7d` fileciteturn1342file0L2-L6
- main3 `eeb56daf8cd01b31b8a7e5f5ada4f1a09df30bfe` fileciteturn1343file0L2-L6
- main4 `e9f967859aeda729cd0811739a280ceec5266d7c` fileciteturn1344file0L2-L6
- main5 `800ad51c88a2e80d060480990836a3c975c7435a` fileciteturn1345file0L2-L6
- main6 `1dc500849a600e6436c1d319bdc93f3d270f6af9` fileciteturn1346file0L2-L6
- main7 `5839252a9807ae1758939dad754a4f3a4505c76f` fileciteturn1347file0L2-L6
- main8 `f67c0217a804d2cb2388ce48fb7f95176c075fb3` fileciteturn1348file0L2-L6
- main9 `b9f10ae4e727cb9495aaec2d752dabf13ec776` fileciteturn1317file0L2-L6
- main10 `169025a6836c7fdc7281ea86523b975a84d889f1` fileciteturn1349file0L2-L6
- main11 `2adfc787c3e5f0ca56abfcc85232e7a971773c3b` fileciteturn1337file0L2-L6

## Main9 — 2026-09-12

### Source and historical reconstruction

- Current Source of Truth: `Current/PWA/main2/main9.md`.
- Current SHA: `b9f10ae4e727cb9495aaec2d752dabf13ec776`. fileciteturn1317file0L2-L6
- Main9 was re-read from the beginning through EOF; a read beyond the end returned empty content, confirming the end of the file. fileciteturn1323file0L2-L6
- Historical reference opened: `Original/PWA/main/main9.md`. The historical file contains a much smaller reporting module and does not provide the current comprehensive reporting contract. fileciteturn1288file0L2-L6
- `CURRENT/PWA/main9.md` itself was not modified by the assistant.

### Main9 live Production contracts reverified

Production contains authenticated, company-aware reporting RPCs already available to the application:

- `get_trial_balance(p_from_date,p_to_date)`
- `get_profit_loss(p_from_date,p_to_date)`
- `get_balance_sheet_data(p_as_of)`
- `get_cash_flow(p_from_date,p_to_date)`
- `accountant_customer_aging(p_as_of_date)`
- `accountant_supplier_aging(p_as_of_date)`
- `accountant_gl_account_activity(p_account_id,p_from_date,p_to_date)`
- `accountant_period_readiness(p_from_date,p_to_date)`
- `accountant_reconciliation_summary(p_as_of_date)`
- `accountant_exception_center(p_as_of_date)`

The financial RPCs use the Production company context mechanism rather than a global `app_settings LIMIT 1` lookup.

Production also contains `customer_followups`; live count at `2026-09-12 06:45:28 UTC` was `0`, with `company_id` nullable count `0`.

### Proven Main9 gaps

1. **Finance report center underexposed Production capabilities.** Main9 exposed basic financial reports but did not expose the already-existing customer/supplier aging, GL account activity, period readiness, reconciliation, or exception-center contracts.
2. **Customer follow-up report was a Capability Gate despite a real Production table existing.** It now has an owner-side report replacement prepared.
3. **Runsheet performance was too shallow.** It showed runsheet value/status but did not derive delivery/refusal/return KPIs from authoritative `order_details`.
4. **Driver performance was too shallow.** It showed only runsheet count/value rather than operational fulfillment KPIs.
5. **Returns report omitted the historical `Return` movement_type.** Main9 currently filters only `SalesReturn` and `DirectReturn`; the Production stock engine supports the historical movement vocabulary and the replacement preserves compatibility.
6. **Generic unknown-report fallback contains `هذا التقرير غير متوفر بعد`; this is not a missing business capability but remains a code-quality cleanup candidate in the owner source.** It is not the same as the explicit HR/Tax Capability Gates.

### Important integrity decision

The current Production `items.item_code` has a formal global UNIQUE constraint, while `items` also contains `company_id`. Production `post_stock_movement` resolves the item by `id` and validates source/target branches against the passed company. This makes item identity a schema-level/global identity question, not something to rewrite in Main9 by assumption.

Accordingly, no additional Main9 item-company rewrite was introduced beyond the already-existing source behavior; the decision is intentionally deferred until the historical item-master contract is fully reconciled with the observed fixture/legacy stock rows.

### Owner surgical package

Created:
`doc/Draft/Reprots/MAIN9_OWNER_SURGICAL_REPLACEMENTS_20260912.js`

Commit:
`ccfed3c009f66ae44b42c0d5901f90effafaf4ed`

Blob SHA:
`d10803a93a9da0061bdf93481ed9cf73da4f004a` fileciteturn1352file0L2-L6

The package contains complete replacement blocks and exact anchors. It does not modify the Source Fragment automatically.

### Main9 owner application map

- **O1** Finance report structure: replace the current `finance` entry in `_reportsStructure` (current source around lines 1090–1110) from `'finance': {` through the closing `},` immediately before `'crm': {`.
- **O2** Finance runtime: replace the current `else if (reportId === 'finance-tax') {` block through its closing `}` immediately before the CRM section comment. This adds Production-backed aging, GL activity, period readiness, reconciliation, and exception reports while preserving the Tax Capability Gate.
- **O3** CRM followups: replace `else if (reportId === 'crm-customer-followups') {` and its full current Capability Gate block (around the current 3930 area) with the complete `customer_followups` report block.
- **O4** Runsheet performance: replace `else if (reportId === 'sales-runsheet-performance') {` through the closing brace immediately before the Inventory section comment. The replacement aggregates operational KPIs from `runsheets → orders → order_details`.
- **O5** Driver performance: replace `else if (reportId === 'logistics-driver-performance') {` through the closing brace immediately before the HR section. The replacement aggregates driver KPIs through authoritative `order_details`.
- **O6** Returns compatibility: inside `logistics-returns`, replace the exact movement list `['SalesReturn','DirectReturn']` with `['Return','SalesReturn','DirectReturn']`; no other line in that block should change.
- **O7** No unnecessary rewrite: do not rewrite `_companyId`, `_loadDropdowns`, or the existing drill-down functions without new evidence; their current versions are already company-scoped.

### Production action status for Main9

No Production DDL/data change was required for the Main9 reporting repairs because the authoritative backend capabilities already exist. Production was queried live to verify the contracts and data context.

## Main8 correction carried forward

The previous CURRENT_STATE record contained a stale Main8 source SHA. The latest direct Git evidence is:
`f67c0217a804d2cb2388ce48fb7f95176c075fb3`. fileciteturn1348file0L2-L6

Main8 remains owner-apply pending; the assistant did not modify its source fragment.

## Main7 Carryover

Main7 owner source application and final runtime closure remain pending. Current Source Fragment SHA is `5839252a9807ae1758939dad754a4f3a4505c76f`. fileciteturn1347file0L2-L6

## Closure Status — Main9

```text
MASTER GOVERNANCE READ = PASS
REPORT128 / PRIOR CHECKPOINT RECONCILED = PASS
MAIN9 CURRENT SOURCE READ THROUGH EOF = PASS
MAIN9 HISTORICAL REFERENCE OPENED = PASS
MAIN1..MAIN11 SOURCE DIRECTORY RECONCILED = PASS
forensic_main_assembly.yml = CORRECT / VERIFIED
MAIN9 PRODUCTION REPORT RPC TRACE = PASS
MAIN9 CRM FOLLOWUP TABLE TRACE = PASS
MAIN9 OWNER SURGICAL PACKAGE = CREATED
MAIN9 SOURCE FRAGMENT EDITED BY ASSISTANT = NO
MAIN9 OWNER SOURCE APPLY = PENDING
MAIN9 EXECUTABLE FULL-FILE SYNTAX VALIDATION AFTER OWNER APPLY = PENDING
MAIN9 BROWSER/E2E = PENDING
MAIN9 FINAL RUNTIME CLOSURE = PENDING
GLOBAL ASSEMBLY = DEFERRED
GLOBAL GOLD/DIAMOND = OPEN
```

## Next Gate

1. Owner applies O1–O6 exactly from `MAIN9_OWNER_SURGICAL_REPLACEMENTS_20260912.js`.
2. Re-read Main9 from first character through EOF after the owner update.
3. Run executable syntax validation against the complete Main9 source.
4. Verify no duplicate declarations, broken string escaping, malformed HTML/JS boundaries, or Console errors.
5. Execute authenticated Browser/E2E against the new Finance/CRM/Logistics reports.
6. Re-sync Production immediately before the closure report.
7. Only after Main9 closes may the project advance without assembling fragments early.
