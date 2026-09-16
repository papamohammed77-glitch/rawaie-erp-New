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

Current HEAD at final reconciliation:
`d3b411cd0d7557ba0948ce9823fa2465e422ad80`

Its direct parent:
`898a31dc65ea0e2d91b3c8ba292fc26c9b0c4d39`

Parent of that forensic checkpoint:
`5f88f5c3c81bc389e953a9b18e7231c8da6f43c1`

Current frontend commits in this closure changed only forensic tooling/guards; Mother HTML was not modified by the assistant.

## CURRENT MOTHER

Current source:
`companies/company-1/main.html`

Verified file size during Browser Forensic Run:
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

Static inventory contract check on current Mother passed and found no placeholder markers:
`قيد التطوير / جاري التطوير / TODO / FIXME`

## CURRENT MOTHER BROWSER EVIDENCE

Workflow:
`.github/workflows/inventory_mother_forensic_e2e_20260916.yml`

The tested Browser Smoke result was PASS with:
`Console errors = 0`
`Page errors = 0`

This does not equal authenticated business E2E against Production.

## FORENSIC WORKFLOWS

`.github/workflows/forensic_main_assembly.yml`

Current guard explicitly requires:
`companies/company-1/main.html`

and rejects Mother code containing:
`Current/PWA/main2`

`.github/workflows/mother_inventory_source_extract_20260916.yml`

This workflow extracts exact current Mother anchors and enclosing functions for surgical patching.

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

### Inventory capability engines present

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

CONVERT creates a stock voucher; it does not directly mutate physical stock.

### Realtime

Enabled for:
`inventory_stock_requests`
`inventory_stock_request_details`

### Edge Gateway

Existing gateway reused because the project has Edge capacity constraints:
`save-inventory-count` — current version 4

It exposes:
`COUNT_*`
`REQUEST_*`
`SNAPSHOT`
`MOVEMENTS`
`REPLENISHMENT`

### Receive Purchase

Current RPC:
`receive_purchase_atomic(p_company_id, p_po_code, p_user_email, p_items, p_operation_id uuid)`

Current Edge:
`receive-purchase` — version 12 — `verify_jwt=true`

The Edge accepts `operation_id` from the body or `Idempotency-Key` and has deterministic fallback when the client omits one.

Production RPC now validates tenant/user context, stable operation identity, item identity, quantity limits, duplicate/conflict semantics, performs physical receive through `post_stock_movement`, updates PO detail/status, restores journal/supplier-ledger responsibilities, and writes audit evidence.

### Manual Voucher CREATE

`create_manual_stock_voucher_atomic` was hardened so tenant context is not derived from an unscoped `app_settings LIMIT 1` lookup.

## PRODUCTION DATA SAFETY

Transactional E2E tests for Receive Purchase left no temporary PO/receiving/movement residue:
`0 / 0 / 0`

Transactional Manual Voucher test also left no residue.

Do not classify the previously observed cross-company stock/item associations as corruption automatically. `items.item_code` is globally UNIQUE in current schema; no deletion/reassignment is allowed without direct source evidence.

## OPEN MOTHER CONSUMER GAP

Production capabilities exist, but Mother consumer integration is not yet closed.

The Mother must expose a control plane for:
`SNAPSHOT`
`MOVEMENTS`
`REPLENISHMENT`
`COUNT_*`
`REQUEST_*`

while field applications remain responsible for operational execution.

## OWNER SURGICAL PATCHES

### PATCH-A — Inventory Menu

Exact current anchor:
`line 1145`

Add the new Mother control view:
`inventory-control`

See Report208 for the full replacement line.

### PATCH-B — Current Dispatcher

Exact current area:
`20932+`

Required new route:
`if (view === 'inventory-control') { RW_Warehouse.loadInventoryControl(); return; }`

Place immediately before the current settings dispatcher.

### RECEIVE PURCHASE — OWNER PATCH

Production supports stable `operation_id`, but the exact current enclosing Mother function was not safely extracted because the very large Mother Blob line-range fetch returned empty content on the exact target range.

No guessed line number was recorded.

The next session must extract the current enclosing receive-purchase function from the Mother source before issuing the final full replacement.

## OPEN SEPARATE WRITER CLOSURES

`complete-return`

`complete-order-delivery`

`picking`

`loading`

`unloading`

Each must be handled as its own Closure Unit with:
`Discover → Root Cause → Historical Review → Surgical Fix → Test → Deploy → Production Verify → Close`

## CURRENT CLOSURE STATUS

```text
Current Git / direct Parent                 VERIFIED
Current Mother Source                      VERIFIED
Mother HTML changed by assistant            NO
Mother Browser Smoke                       PASS
Console/Page Errors                         0 in smoke
Production Inventory Engines               PRESENT + VERIFIED
Stock Request Engine                        PRESENT + VERIFIED
Inventory Count Engine                     PRESENT + VERIFIED
Inventory Intelligence                     PRESENT + VERIFIED
Inventory Realtime                          DEPLOYED
Manual Voucher Production hardening        DEPLOYED + VERIFIED
Receive Purchase identity                   DEPLOYED + VERIFIED transactionally
Receive Purchase accounting                 DEPLOYED
Mother Inventory Consumer                  OPEN
Owner PATCH-A                               READY
Owner PATCH-B                               READY
Receive Purchase Mother identity patch     OPEN — exact enclosing block not safely extracted
Complete Return Writer                     OPEN
Complete Order Delivery Writer             OPEN
Full Authenticated Mother E2E             OPEN
Global Inventory Zero-Debt                 OPEN
Gold/Diamond Inventory                     OPEN
```

## NEXT SESSION — EXACT START SEQUENCE

1. Read this state only to identify the checkpoint; do not accept any claim without re-verification.
2. Open current frontend HEAD and its direct parent; inspect the diff.
3. Open current Mother `companies/company-1/main.html` and extract the exact full `RW_Warehouse` object plus receive-purchase consumer and dispatcher.
4. Take a fresh Production snapshot at the same moment.
5. Re-check live Edge versions and live RPC definitions; never infer deployment from migrations alone.
6. Trace one flow end-to-end:
   `Mother → Edge → RPC → core engine → DB → audit → realtime`
7. Close only one Writer Closure Unit at a time.
8. For Mother edits, give the owner the exact line number, exact first line, exact final line, complete delete block, and complete replacement block.
9. After Owner merge, re-read current Git/blob before Browser E2E.
10. Capture Browser + Console + Network + Database + Realtime evidence.
11. Update this file and add the next sequential report.

**Never declare `100% CLOSED` while any Unknown, Conflict, or Unverified Claim materially affects the closure.**
