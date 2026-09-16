# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-16  
**Basis:** CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE. Historical reports are reference-only.

## SOURCE OF TRUTH

Mother:
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

Historical/reference only:
`rawaie-erp-New/Current/PWA/main2/*`
`rawaie-erp-New/Original/PWA/main/*`
`rawaie-erp-New/Current/PWA/main`
`rawaie-erp-New/Current/PWA/New-main`

`forensic_main_assembly.yml` was verified and already points to the Mother Source of Truth; no correction was required.

## CURRENT FRONTEND GIT

Repository: `papamohammed77-glitch/erp-frontend`
Branch: `main`
Latest HEAD: `9f84e24f4dd93381aaaff12ceb04f84ddde95fb0`
Latest message: `test: add inventory control modal E2E guard`
Direct parent: `02abd146d7df7703f1c2a18896d8ee3d9e8b0217`

The latest HEAD adds only the E2E workflow and does not change `main.html`.

Previous forensic-only HEAD: `02abd146d7df7703f1c2a18896d8ee3d9e8b0217`
Parent: `0a3d944ed4498620a9c1ade2a43c5208337749c1`

## CURRENT MOTHER SOURCE

Forensic fingerprint currently recorded:

```text
23,315 lines
1,288,078 bytes
SHA256=8358f2f1f267f91b27b0745a6a2f4530366dab712272f74d6cad64e8df8d02a1
```

`RW_Warehouse` starts at line `10950`.
`loadInventoryControl()` starts at line `13235`.
`RW_Warehouse` return object starts at line `13811`.
`loadInventoryControl: loadInventoryControl,` is exported at line `13812`.
Current route is at line `21513`:

```js
if (view === 'inventory-control') { RW_Warehouse.loadInventoryControl(); return; }
```

No current source hit for `قيد التطوير`, `جاري التطوير`, `TODO`, or `FIXME`.

## TARGET MODAL FORENSIC FINDINGS

### جلسة جرد جديدة

Function: `createCountSession()`
Current lines: `13635–13671`

Current defect: it creates a count session and moves to the counts tab, but the quick action does not create/populate/open a usable counting editor with system quantity, physical quantity, variance, refresh, save and finalize actions.

### طلب نقل مخزني جديد

Function: `createStockRequest()`
Current lines: `13711–13781`

Current defect: it relies on raw `1001|5` textarea entry and does not provide item lookup/cart/live source availability/Available Before/Available After.

## CURRENT PRODUCTION INVENTORY BACKEND

Project: `fiilmooggumokxanwiyx`

Canonical gateway:
`public.inventory_control(text,jsonb)`

Tenant boundary:
`auth.uid() → users.auth_id → users.company_id`

Inventory Count Engine:
`public.inventory_count_engine(...)`

Supports:
`CREATE`, `GET`, `POPULATE`, `UPSERT_LINE`, `REFRESH`, `FINALIZE`, `CANCEL`

Inventory Stock Request Engine:
`public.inventory_stock_request_engine(...)`

Supports:
`CREATE`, `GET`, `APPROVE`, `REJECT`, `CONVERT`, `CANCEL`

## PRODUCTION VERIFICATION

Count transactional proof:
`CREATE → POPULATE → GET = PASS`

Request transactional proof:
`CREATE → GET → APPROVE → CONVERT = PASS`

No persistent test data was intentionally left behind.

## PHYSICAL STOCK CONTRACT

```text
Physical Movement
        ↓
post_stock_movement
        ↓
stock_branches + inventory_log
```

Reservation-only functions:
`reserve_stock`
`release_stock_reservation`

Current forensic discovery remains:
`Physical Writers outside post_stock_movement = 0 discovered`

## PRODUCTION INFRASTRUCTURE DECISION

For the two target modals:

```text
New table        = NOT REQUIRED
New relation     = NOT REQUIRED
New Edge Function= NOT REQUIRED
New stock writer = NOT REQUIRED
```

Existing production engines are sufficient.

## SECURITY / REALTIME

RLS is enabled on:
`inventory_stock_requests`
`inventory_stock_request_details`

Realtime currently includes the required inventory operational tables and `erp_operation_registry`.

## E2E INFRASTRUCTURE ADDED

New frontend workflow:

`.github/workflows/inventory_control_modals_e2e_20260916.yml`

It is `workflow_dispatch` only.

It validates:

```text
Mother loads
+
loadInventoryControl exists
+
Count modal opens
+
COUNT CREATE
+
COUNT POPULATE
+
Request modal opens
+
REQUEST CREATE
+
Console Errors = 0
+
Page Errors = 0
```

It does not alter Production.

## OWNER SURGICAL PATCH STATUS

Assistant did not edit `main.html`.

Full surgical replacements are recorded in:

`doc/Draft/Reprots/Report211_MOTHER_INVENTORY_MODAL_FORENSIC_E2E_20260916.md`

Target 1:
`createCountSession()` lines `13635–13671`

Target 2:
`createStockRequest()` lines `13711–13781`

## CURRENT CLOSURE

```text
Current Git / Parent                     VERIFIED
Current Mother source                   VERIFIED
Production Count Engine                 VERIFIED
Production Request Engine               VERIFIED
Physical Writer centralization          CLOSED
Control Plane backend                   CLOSED
Mother Control Plane shell              PRESENT
Count modal                             OPEN — owner surgery
Request modal                           OPEN — owner surgery
Authenticated Browser/Console/Network  OPEN
Global Inventory Zero-Debt              NOT YET 100% CLOSED
```

## NEXT SESSION START ORDER

1. Read frontend HEAD `9f84e24f4dd93381aaaff12ceb04f84ddde95fb0` and parent `02abd146d7df7703f1c2a18896d8ee3d9e8b0217`.
2. Recompute the current `main.html` fingerprint before trusting any prior line number.
3. Take a fresh Production snapshot.
4. Check whether the owner has merged the two surgical replacements; do not reapply any already-completed change.
5. Run the Modal E2E Guard.
6. Run authenticated live Browser + Console + Network E2E.
7. Compare UI values with same-moment Production values.
8. Only after this unit is proven closed, move to the next current defect.

## LATEST REPORT

`doc/Draft/Reprots/Report211_MOTHER_INVENTORY_MODAL_FORENSIC_E2E_20260916.md`
