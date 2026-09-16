# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-16 — current state rebuilt from CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT. Historical reports are reference-only.

## SOURCE OF TRUTH

Current truth:
`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

Full authenticated browser closure additionally requires:
`CURRENT BROWSER + CURRENT CONSOLE + CURRENT NETWORK`

Mother Source of Truth:
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

Historical/reference only:
`Current/PWA/main2/*`
`Original/PWA/main/*`
`New-main`

## CURRENT FRONTEND GIT

Repository: `papamohammed77-glitch/erp-frontend`
Branch: `main`

Current HEAD:
`e0c806e47a761561fc4177ffd2a4d9fc8d7d7dc9`

Direct parent:
`06468385d01bbddab4e078dc2fc24282cea43733`

Latest HEAD message:
`Update inventory management section in main.html`

## CURRENT MOTHER

Current source:
`companies/company-1/main.html`

Current source SHA:
`33a7c2c9e7e35d546ea960f84f4feee16ec4d632`

Inventory menu anchor:
`line 1145`

Current Mother contains warehouse operational consumers for Receiving, Picking, Loading, Delivery, Return, Unloading, Vouchers, Counts, and Settlement.

Current HEAD route:
`if (view === 'inventory-control') { RW_Warehouse.loadInventoryControl(); return; }`

Forensic search did not find an implementation of `RW_Warehouse.loadInventoryControl()` in the current Mother source. This remains an OPEN Owner-side Mother implementation gap.

No current search hit for:
`قيد التطوير / جاري التطوير / TODO / FIXME`

## FORENSIC WORKFLOWS

`.github/workflows/forensic_main_assembly.yml`
`.github/workflows/mother_inventory_source_extract_20260916.yml`

Both are governed against the current Mother path; historical split files are not the Mother Source of Truth.

## CURRENT PRODUCTION — SUPABASE

Project:
`fiilmooggumokxanwiyx`

Physical Stock Contract:

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

## CLOSED / DEPLOYED CLOSURES

### complete-return
Edge `complete-return` v26.

Validated path:
`Edge → users/auth company → complete_sales_return_credit_note_atomic → complete_return_atomic → post_stock_movement`.

Transactional E2E proved first success, stock delta +1, repeated same business request `duplicate=true`, same credit-note operation identity, rollback clean.

Status:
`CLOSED — DB/RPC transactional proof`

### complete-order-delivery
Edge `complete-order-delivery` v14.

Delivery updates fulfillment only. Physical stock is not mutated here because Loading owns physical movement in the current architecture.

Transactional repeat test and rollback completed successfully.

Status:
`CLOSED — DB/RPC transactional proof`

### picking
Edge `complete-picking` v17.

RPC overload with `p_operation_id uuid` uses `erp_operation_registry` and `reserve_stock` only.

Transactional test proved stock unchanged, allocated_qty +1, qty_picked +1, retry `duplicate=true`, rollback clean.

Status:
`CLOSED — DB/RPC transactional proof`

### loading / unloading
Edges:
`complete-loading` v11
`unload-runsheet` v6

Production RPCs now persist operation identity in `erp_operation_registry` using the loading cycle, detect duplicate/conflict requests, persist response state, and record audit using allowed action `update`.

Loading still requires prior reservation; a test without reservation was correctly rejected.

Status:
`DEPLOYED + DB verified`

Authenticated browser/network runtime verification after the final deployment remains OPEN.

## GLOBAL WRITER DISCOVERY

Direct PostgreSQL discovery found no independent Physical Movement Engine outside:
`post_stock_movement`.

Other stock writers discovered are initialization/reservation only:
`reserve_stock`, `release_stock_reservation`, `create_vehicle_atomic`, `setup_van_stock`.

Therefore:
`Physical Writers outside post_stock_movement = 0`

## DATA / SCHEMA FACTS

`items.item_code` is globally UNIQUE.
`stock_branches` is unique on `(branch_id,item_id)`.
`receiving.operation_id` is UNIQUE.
`erp_operation_registry` is unique on `(company_id,operation_type,operation_key)`.

`order_details` remains the authoritative fulfillment detail for the field chain; `run_sheet_details` is derived by trigger. Do not introduce dual writes.

## REALTIME

Operational publication includes:
`stock_branches`, `inventory_log`, `orders`, `order_details`, `runsheets`, `run_sheet_details`, `stock_vouchers`, `stock_voucher_details`.

`erp_operation_registry` is not in Realtime publication. Do not expose it to Mother blindly; decide the Control Plane need first.

## INVENTORY CONTROL MOTHER GAP

Backend capabilities already present:
`inventory_stock_snapshot`
`inventory_replenishment_report`
`inventory_movement_report`
`inventory_count_engine`
`inventory_stock_request_engine`

Stock request tables:
`inventory_stock_requests`
`inventory_stock_request_details`

Current Mother route exists, but implementation of `loadInventoryControl()` was not proven in the current source. This is OPEN.

## DATA SAFETY

Previously observed cross-company stock/item rows were not deleted or reassigned in this session. Global `items.item_code` uniqueness means mismatch counts alone cannot prove corruption.

Completed transactional fixtures were rolled back.

## SECURITY OBSERVATIONS

Current Supabase advisor still reports RLS disabled on inventory stock-request tables and additional SECURITY DEFINER/search_path findings outside these writer closures. These remain separate security closures requiring consumer mapping before change.

## CURRENT CLOSURE STATUS

```text
Current Git / Parent                 VERIFIED
e0c806e... / parent 064683...
Current Mother Source               VERIFIED
Current Mother SHA                  33a7c2c9e7e35d546ea960f84f4feee16ec4d632
Mother HTML modified by assistant   NO
Complete Return                     CLOSED — DB/RPC proof
Complete Order Delivery             CLOSED — DB/RPC proof
Picking                             CLOSED — DB/RPC proof
Loading                             DEPLOYED — browser runtime OPEN
Unloading                           DEPLOYED — browser runtime OPEN
Physical Writers outside core       0 discovered
Mother Inventory Control            OPEN
Authenticated Mother E2E            OPEN
Global Inventory Zero-Debt          NOT YET 100%
Gold/Diamond Inventory              OPEN
```

## NEXT SESSION — EXACT START ORDER

1. Re-open current frontend HEAD `e0c806...` and parent `064683...`.
2. Re-open only current `companies/company-1/main.html` as Mother Source of Truth.
3. Take a fresh Production snapshot at the same moment.
4. Verify `forensic_main_assembly.yml` still targets only the current Mother path.
5. Extract the exact `RW_Warehouse` function boundaries and implement the missing `loadInventoryControl()` surgically in Mother; owner executes this file change.
6. Re-read the merged Mother source after the owner patch.
7. Run authenticated Browser + Console + Network evidence.
8. Re-check Loading/Unloading runtime after their final Production deployment.
9. Continue Inventory Control functional completion, then Finance/HR/CRM/Reports.
10. Never declare 100% while any material Unknown, Conflict, or Unverified Claim remains.

## GOVERNANCE RULE

Never promote historical reports, percentages, prior assistant claims, or split historical files to current truth. Re-establish current truth from live Git/Source/Production/Database/Deployment before every Closure Unit.
