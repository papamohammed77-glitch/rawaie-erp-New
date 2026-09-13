# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-13
**Checkpoint:** Report156 — CTO E2E للنظام الأم — Current Gaps.

## GOVERNANCE
لا تعتمد الحالة الحالية على التقارير السابقة. المرجع الوحيد:
`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`.

Source of Truth للواجهة:
`https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/main.html`

`Current/PWA/main2/*` و`Original/PWA/main/*` = historical/reference only.

## CURRENT GIT
Repository: `papamohammed77-glitch/erp-frontend`

HEAD: `5bdb2863570085edd19265465937aea3c674b52c`
Direct parent: `02166a9f8e94ac0b2cc15257eb0aec8e039848bd`
Parent of parent: `06264f8eefc5e0d5281538c80e9c7aaa454ecf9b`
Current main.html blob: `2485901f759b88995ac80e1060883554b1177bbe`

الـparent كان يحتوي regression في قوس إغلاق `_renderTable`; HEAD الحالي أصلحه. لا تعاد إصلاحات Syntax القديمة.

## FORENSIC ASSEMBLY
`forensic_main_assembly.yml` صحيح:
`source_of_truth.repository=papamohammed77-glitch/erp-frontend`
`source_of_truth.path=companies/company-1/main.html`
`source_of_truth.ref=main`
`assembly_status=reference_only; published_main_is_authoritative`

## PRODUCTION
Project: `fiilmooggumokxanwiyx`
Latest migration observed: `20260913082923`
Company 1: `00000000-0000-0000-0000-000000000001`

Current facts:
`categories=5; items=17; unresolved category links=0; active branches=2; active direct-sales reps=1; active vehicles=0`.

Relevant Edge deployments:
`create-stock-voucher v10; send-stock-voucher v20; receive-stock-voucher v22; bulk-stock-adjustment v6; save-item v13; save-category v4; receive-purchase v12; complete-return v25; complete-order-delivery v14`.

## ITEMS / CATEGORIES
Category lookups in current main.html are company-scoped. Production category integrity is repaired. No category query patch is justified now.

Current Items functions include list/search/filter/sort, branch matrix, movement, Excel export, CSV/XLS/XLSX upload, bulk adjustment, Category/Item CRUD, opening stock and item-form fields.

## OPEN OWNER PATCH 1 — UPDATE BALANCES
File: `erp-frontend/companies/company-1/main.html`
Function: `_renderUploadPreview()`
Current lines 3358–3359:
```javascript
                            entry._valid =
                                !!item && !status;
```
Replace exactly with:
```javascript
                            entry._valid =
                                !!item &&
                                !duplicateBarcodeMap[entry.barcode] &&
                                status === '✅ صالح';
```

## OPEN OWNER PATCH 2 — DETAILED REPORTS / itemSales
Current area around line 12860:
```javascript
        if (types.indexOf('sales-by-item') !== -1) {
            var itemSales = {};
```
Replace exactly with:
```javascript
        var itemSales = {};

        if (types.indexOf('sales-by-item') !== -1) {
```

## OPEN OWNER PATCH 3 — DETAILED REPORTS / inventoryRows
Current area around line 13022:
```javascript
        if (
            types.indexOf('inventory-low') !== -1 ||
            types.indexOf('inventory-top') !== -1 ||
            types.indexOf('inventory-dormant') !== -1
        ) {
            var inventoryRows = [];
```
Replace exactly with:
```javascript
        var inventoryRows = [];

        if (
            types.indexOf('inventory-low') !== -1 ||
            types.indexOf('inventory-top') !== -1 ||
            types.indexOf('inventory-dormant') !== -1
        ) {
```

These three are proven Source-of-Truth frontend defects. `main.html` was not modified because it is owner-managed.

## DETAILED REPORTS ROOT CAUSE
`inventoryRows` was scoped only inside the inventory checkbox block, but `rec-purchase/rec-offers` later calls `inventoryRows.length`; default selection therefore produces `Cannot read properties of undefined (reading 'length')`.

`itemSales` had the same conditional declaration problem for `inventory-top`.

`rec-customers` and `rec-expansion` currently show a Capability Gate. Do not invent a recommendation policy without authoritative Production/business evidence.

## WAREHOUSE TRANSFERS
Current frontend queries branches/users/vehicles company-scoped. Production has zero active vehicles, so an empty vehicle list is currently explained by Production data.

Canonical movement contracts in current Production:
`Transfer=Branch→Branch`
`DirectSale=Branch→Vehicle`
`DirectReturn=Vehicle→Branch`
`SupplierReturn=Branch→Supplier`

No proven frontend patch is justified for these queries.

## INVENTORY CONTRACT
Current canonical Physical Stock path:
`Physical Movement → post_stock_movement → stock_branches + inventory_log`.

A historical 9-arg `post_stock_movement` overload remains but is not executable by `service_role`; 10-arg is the active service surface.

## E2E STATUS
Browser click-by-click E2E is not proven in this environment. No Browser PASS is claimed.
Production changes required by the three current frontend defects: **0**.

## SESSION ARTIFACT
`doc/Draft/Reprots/Report156_CTO_E2E_Main_Current_Gaps_20260913.md`
Commit: `fb46ed43214f1bc225f78710fb14a7ba636925fb`

## NEXT SESSION START RULE
`CURRENT GIT HEAD → DIRECT PARENT/COMMITS → CURRENT main.html → CURRENT Supabase/DB → CURRENT deployments/runtime → exact symptom → exact line/function → root cause → surgical owner/Production fix → reread → verify → report`.

Never start from an old report status, never re-fix already proven work, never invent data or Business Rules, and never equate static/staging PASS with Production PASS.

**الحقيقة الحالية أولًا، ثم الإصلاح المثبت، ثم التحقق.**
