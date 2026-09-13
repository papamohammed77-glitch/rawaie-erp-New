# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-13 10:20 UTC  
**Current checkpoint:** Report153 — CTO E2E Forensic Review of `RW_Items` / Items Tab.

## GOVERNANCE — CURRENT TRUTH ONLY

لا تُعامل أي تقرير سابق أو حالة ذاكرة سابقة كحالة Production حالية.

الحالة المعتمدة:

```text
CURRENT GIT
+
CURRENT SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT EVIDENCE
```

الـSource of Truth للواجهة:

```text
https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/main.html
```

`Current/PWA/main2/*` و`Original/PWA/main/*` والتقارير السابقة = historical forensic reference only.

## CURRENT GIT

Repository:

```text
papamohammed77-glitch/erp-frontend
```

Current HEAD:

```text
ca91daa29802d161eeb7920bc36dfe4fa3ab2820
```

Direct parent:

```text
b29461b0bf5b3af6d387f39497e8e6cf95dfdbbd
```

Previous functional parent inspected:

```text
1c212f98e89de4de2384080fef9c75c7d93b0e7e
```

Current `main.html` blob:

```text
507a77e7290bbf7c24ce34ce9a121ee2e63e4c44
```

## FORENSIC ASSEMBLY

`rawaie-erp-New/forensic_main_assembly.yml` was rechecked and is correct:

```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
assembly_status: reference_only; published_main_is_authoritative
```

No change required.

## REPORT153 — ITEMS FORENSIC RESULT

Created:

```text
doc/Draft/Reprots/Report153_CTO_E2E_Items_Forensic_20260913.md
```

### Proven current finding

The current `RW_Items._renderTable()` contains a merge regression.

At approximately source line 2008 the pagination callback starts with:

```javascript
RW_Table.paginate('items-tbody', sorted, 1, 50, function(item, idx) {
```

Inside the branch loop the current source redeclares `rowHtml` instead of appending branch cells:

```javascript
var rowHtml = '<tr class="border-t hover:bg-gray-50"> ...';
```

This overwrites the row being built and causes the list renderer to lose its previously assembled cells.

### Proven second regression

The historical branch drill-down passed:

```text
item_code, item_name, bid2, branchName2
```

The current broken list renderer passes:

```text
item_code, item_name, null
```

Therefore branch-specific movement drill-down is also lost from the list view.

### Owner-only frontend action

The assistant must NOT edit:

```text
erp-frontend/companies/company-1/main.html
```

The owner must replace the entire `RW_Table.paginate(...)` callback in `RW_Items._renderTable()` as specified in Report153.

The exact replacement restores:

```text
rowHtml += branch-cell
```

and passes:

```text
bid2 + branchName2
```

into `_renderStockMovementReport()`.

## ITEMS FEATURE INVENTORY

Current source still contains:

```text
List
Search by name/code/barcode
Category filter
Stock-status filter
Reset
Sorting
Branch stock columns
Movement report
Branch stock matrix
Branch filter
Excel export
Bulk stock update from CSV/XLS/XLSX
Category CRUD
Item create
Item edit
Item delete
Three item-form tabs
Opening stock
Marketing fields
Image upload
```

Comparison with `Original/PWA/main/main2.md` did NOT prove broad loss of the Items feature set.

The confirmed loss is the list renderer regression above.

## ITEMS MOVEMENT REPORT

Current implementation is more centralized than the old one:

```text
inventory_log
+
company_id
+
item_id
+
optional branch filter
+
opening balance
+
physical movement type filtering
+
user/reference
```

Do NOT replace it with the older `stock_vouchers`-based implementation.

No frontend change required here in Report153.

## ITEMS MATRIX / UPLOAD / CATEGORIES

Matrix:

```text
present
search present
branch filter present
Excel export present
branch movement drill-down present
```

Bulk stock upload:

```text
present
CSV/XLS/XLSX
preview
replace/add/deduct
operation identity
refresh after success
```

Categories:

```text
present
company-scoped
Production save-category = active version 4
```

Delete item:

```text
Production delete-item = active version 4
company-scoped
permission checked
```

## COST PRICE — NOT A CURRENT REGRESSION

Production `save-item` version 13 supports `cost_price`, but the current and historical Items form both omit a Cost Price field.

Therefore:

```text
Cost Price UI restoration = NOT PROVEN
Cost Price = historical/new-capability question
```

Do not add it to `main.html` as a “bug fix” until the historical contract and role/security intent are proven.

## CURRENT PRODUCTION

Supabase project:

```text
SMART ERP
fiilmooggumokxanwiyx
ACTIVE_HEALTHY
Postgres 17.6.1.121
```

Current relevant Edge Functions verified:

```text
save-item     v13
save-category v4
delete-item   v4
```

All three resolve company context from the authenticated `users` record and enforce company/permission checks appropriate to their operation.

No Production migration was required for the Items closure in Report153.

## PRODUCTION / INVENTORY GOVERNANCE FROM PREVIOUS WORK

Physical stock contract remains:

```text
PHYSICAL STOCK MOVEMENT
        ↓
post_stock_movement
        ↓
stock_branches + inventory_log
```

`reserve_stock` remains reservation-only.

Do not reopen previously closed Inventory closures merely because this session is testing the Items UI.

## BROWSER E2E STATUS

This environment does not provide a real browser automation tool, so Browser E2E cannot be honestly marked PASS here.

Proven in this checkpoint:

```text
CURRENT GIT = VERIFIED
HEAD = VERIFIED
PARENT = VERIFIED
CURRENT MAIN SOURCE = VERIFIED
ORIGINAL ITEMS SOURCE = VERIFIED
ITEMS FEATURE INVENTORY = VERIFIED
_LIST TABLE REGRESSION = PROVEN
BRANCH DRILL-DOWN REGRESSION = PROVEN
FORENSIC ASSEMBLY = VERIFIED
PRODUCTION ITEM CRUD EDGE = VERIFIED
```

Pending after owner applies the surgical frontend replacement:

```text
fresh deployment
fresh incognito
login
open Items
list rendering
sorting
branch cells
branch movement drill-down
matrix
upload
item create/edit/delete
console
```

## FILES MODIFIED BY ASSISTANT IN THIS CHECKPOINT

```text
rawaie-erp-New/doc/Draft/Reprots/Report153_CTO_E2E_Items_Forensic_20260913.md
rawaie-erp-New/CURRENT_STATE.md
```

Not modified by assistant:

```text
erp-frontend/companies/company-1/main.html
Current/PWA/main2/*
Original/PWA/main/*
```

## NEXT SESSION START ORDER

1. Re-read current HEAD and direct parent.
2. Re-fetch current `companies/company-1/main.html`; do not trust old snippets.
3. Verify whether owner applied the exact Report153 replacement; if not, do not invent another fix.
4. Reconcile Production immediately before any new report.
5. Run the real browser E2E on the fresh published version when browser tooling is available.
6. Accept only the first currently reproducible defect as the next Closure Unit.
7. Before changing any historical behavior, reconstruct the historical contract and trace current consumers/dependencies.
8. Never repeat a fix already present in current HEAD/Production.

## GOLD / DIAMOND STATUS

```text
Items forensic analysis = COMPLETE
Confirmed frontend regression identification = COMPLETE
Owner surgical fix instruction = COMPLETE
Production Items repair = NOT REQUIRED
Browser E2E = PENDING real browser execution
Global system functional completion = OPEN
Gold/Diamond = OPEN
```

## CRITICAL REMINDER

لا توجد 100% Closure لمجرد أن الكود يبدو صحيحًا.

```text
CODE != DEPLOYMENT != RUNTIME != BROWSER E2E != 100% CLOSED
```

كل إغلاق لاحق يجب أن يبدأ من Current Git + Current Source + Current Production + Current Database + Current Deployment Evidence، وأي تقرير تاريخي يُستخدم فقط لفهم لماذا وصل النظام إلى حالته الحالية.
