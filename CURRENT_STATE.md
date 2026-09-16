# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-16 — CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT evidence were rechecked for the Mother Inventory Consumer / Daftra gap closure. Historical reports remain reference-only.

## SOURCE OF TRUTH

Historical reports are clues only; they are not current state.

Current truth:
`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

Full authenticated E2E additionally requires:
`CURRENT BROWSER + CURRENT CONSOLE + CURRENT NETWORK`

**Mother Source of Truth:**
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

Historical/reference only:
`Current/PWA/main2/*`
`Original/PWA/main/*`
`New-main`

## CURRENT FRONTEND GIT

Repository: `papamohammed77-glitch/erp-frontend`
Branch: `main`

Current HEAD:
`06468385d01bbddab4e078dc2fc24282cea43733`

Direct parent:
`3ecdfdc9747fae7de8b7a99e02d65971071ae7e0`

Earlier forensic parent:
`898a31dc65ea0e2d91b3c8ba292fc26c9b0c4d39`

The current frontend commits created during this closure modify only forensic tooling/guards; Mother HTML was not modified by the assistant.

## CURRENT MOTHER

Current source:
`companies/company-1/main.html`

Verified file size during the latest Browser Forensic Run:
`1,254,016 bytes`

Inventory menu:
`line 1145`

Current Inventory dispatcher:
`20953` picking
`20954` loading
`20955` delivery
`20956` return
`20961` unloading
`20962` receiving
`20963` vouchers
`20964` transfer
`20965` direct-sale
`20966` direct-return
`20967` supplier-return
`20968` vehicle-count
`20969` branch-count
`20970` general-count
`20971` settlement

Current smoke audit passed with no placeholder markers:
`قيد التطوير / جاري التطوير / TODO / FIXME`

## CURRENT MOTHER BROWSER EVIDENCE

The latest proven Mother Browser Smoke:
`MOTHER_BROWSER_SMOKE=PASS`
`Console errors = 0`
`Page errors = 0`

This remains Browser Smoke, not authenticated full business E2E.

## FORENSIC WORKFLOWS

`.github/workflows/forensic_main_assembly.yml`

The guard requires `companies/company-1/main.html`, rejects `Current/PWA/main2` references inside Mother, and runs inline JavaScript syntax validation.

`.github/workflows/mother_inventory_source_extract_20260916.yml`

Manual-run forensic extractor for exact current Mother anchors/enclosing functions. It is intentionally not triggered on every push.

## CURRENT PRODUCTION — SUPABASE

Project:
`fiilmooggumokxanwiyx`

Central Physical Stock Contract:

```text
Physical Movement
        ↓
post_stock_movement
        ↓
stock_branches + inventory_log
```

Reservation only:
`reserve_stock`
`release_stock_reservation`

### Inventory capabilities present

`inventory_stock_snapshot`
`inventory_replenishment_report`
`inventory_movement_report`
`inventory_count_engine`
`inventory_stock_request_engine`

### Stock Request tables

`inventory_stock_requests`
`inventory_stock_request_details`

Lifecycle:
`CREATE → GET → APPROVE → REJECT → CONVERT → CANCEL`

### Realtime

Enabled for:
`inventory_stock_requests`
`inventory_stock_request_details`

### Inventory Gateway

`save-inventory-count` — version `4` — `verify_jwt=true`

Supports:
`COUNT_* / REQUEST_* / SNAPSHOT / MOVEMENTS / REPLENISHMENT`

### Receive Purchase

RPC:
`receive_purchase_atomic(p_company_id, p_po_code, p_user_email, p_items, p_operation_id uuid)`

Edge:
`receive-purchase` — version `12` — `verify_jwt=true`

Production now validates tenant/user context, stable operation identity, duplicate/conflict semantics, item identity, quantity limits, physical movement via `post_stock_movement`, PO status/detail, accounting, and audit.

### Manual Voucher CREATE

`create_manual_stock_voucher_atomic` no longer derives tenant context from an unscoped `app_settings LIMIT 1` lookup.

## DATA SAFETY

Transactional testing left no temporary PO/receiving/movement residue.

The previously observed cross-company stock/item associations were not deleted or reassigned because the current schema makes `items.item_code` globally UNIQUE and there is not enough direct source evidence to classify every mismatch as corruption.

## OPEN MOTHER CONSUMER GAP

Production capabilities exist, but Mother consumer integration remains open.

Required Mother control plane:
`SNAPSHOT`
`MOVEMENTS`
`REPLENISHMENT`
`COUNT_*`
`REQUEST_*`

Field applications remain the operational execution layer.

## OWNER PATCHES

### PATCH-A

Current exact menu anchor:
`line 1145`

Add:
`inventory-control`

Full replacement is recorded in `doc/Draft/Reprots/Report208_INVENTORY_MOTHER_CONSUMER_E2E_FORENSIC_20260916.md`.

### PATCH-B

Current dispatcher anchor area:
`20932+`

Required route:
`if (view === 'inventory-control') { RW_Warehouse.loadInventoryControl(); return; }`

**Important:** `loadInventoryControl()` itself has not been proven to exist in the current Mother source. Therefore PATCH-B is a routing requirement only, not a claim of functional closure. The next extraction must prove the target implementation before the Owner pastes any new dispatcher route.

### RECEIVE PURCHASE

Production is operation-id aware, but the exact current enclosing Mother consumer was not safely extracted from the huge Mother Blob in this session.

No guessed line number was recorded.

Do not patch the Mother receive consumer until the exact current enclosing function and operation state are extracted from the current source.

## OPEN WRITER CLOSURES

`complete-return`

`complete-order-delivery`

`picking`

`loading`

`unloading`

Each is a separate Closure Unit:
`Discover → Root Cause → Historical Context → Surgical Fix → Test → Deploy → Production Verify → Close`

## CURRENT CLOSURE STATUS

```text
Current Git / direct Parent              VERIFIED
Current Mother Source                   VERIFIED
Mother HTML modified by assistant       NO
Mother Browser Smoke                    PASS
Console/Page Errors                     0 in smoke
Inventory Engines                       PRESENT + VERIFIED
Stock Request Engine                    PRESENT + VERIFIED
Inventory Count Engine                  PRESENT + VERIFIED
Inventory Intelligence                  PRESENT + VERIFIED
Inventory Realtime                      DEPLOYED
Manual Voucher CREATE                   DEPLOYED + VERIFIED
Receive Purchase Identity               DEPLOYED + VERIFIED TRANSACTIONALLY
Receive Purchase Accounting             DEPLOYED
Mother Inventory Consumer               OPEN
Owner PATCH-A                           READY
Owner PATCH-B                           ROUTE IDENTIFIED; IMPLEMENTATION UNPROVEN
Receive Purchase Mother Identity        OPEN
Complete Return Writer                 OPEN
Complete Order Delivery Writer         OPEN
Full Authenticated Mother E2E           OPEN
Global Inventory Zero-Debt              OPEN
Gold/Diamond Inventory                  OPEN
```

## NEXT SESSION EXACT START

1. Open current HEAD `06468385...` and direct parent `3ecdfdc9...`, inspect diff.
2. Open current Mother `companies/company-1/main.html` as the only Source of Truth.
3. Run the manual forensic extractor to obtain exact `RW_Warehouse`, `loadReceiving`, receive-purchase consumer, and dispatcher blocks.
4. Take a fresh Production snapshot at the same moment.
5. Match Mother → Edge → RPC → DB → audit → realtime for one capability at a time.
6. Prove whether `loadInventoryControl()` already exists; do not route to a nonexistent method.
7. Build the Owner replacement only after exact function boundaries are known.
8. After Owner merge, re-read current Git/blob and run Browser + Console + Network + DB + Realtime evidence.
9. Continue separate Writer Closures for returns/delivery/picking/loading/unloading.
10. Never declare `100% CLOSED` while any material Unknown, Conflict, or Unverified Claim remains.
