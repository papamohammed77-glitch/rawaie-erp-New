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

Current HEAD at end of this session:
`6533ab8924c2a2fe76a78aabec413b4dae3019f0`

Direct parent:
`2430b5b4922b53f218f7e4bd4c52a603e7ef8f0b`

Business commit immediately before forensic extraction:
`e0c806e47a761561fc4177ffd2a4d9fc8d7d7dc9`

Latest two commits created during forensic work only added the extraction workflow/output; they did not modify the Mother source blob.

Current Mother blob SHA remains:
`33a7c2c9e7e35d546ea960f84f4feee16ec4d632`

## CURRENT MOTHER

Current source:
`companies/company-1/main.html`

Forensic extraction established:
`22,739` lines and `1,254,184` bytes at extraction time.

Current Inventory Control route:
`if (view === 'inventory-control') { RW_Warehouse.loadInventoryControl(); return; }`

Exact current route line:
`20937`

Current `RW_Warehouse` starts at line:
`10950`

Current `RW_Warehouse` return object begins at line:
`13236`

The forensic source contains the route call but no executable `loadInventoryControl()` implementation.

No current source hit for:
`قيد التطوير / جاري التطوير / TODO / FIXME`

The owner must apply the Mother patch from Report210. Assistant did not edit `main.html`.

## FORENSIC EXTRACTION

A forensic extractor was added only to obtain exact line mapping from the 1.25 MB Mother file:

`.github/workflows/_forensic_extract_current_main.yml`

and its generated output:

`_forensic_current_main_extract.md`

These are investigative artifacts, not Source of Truth.

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

Fresh PostgreSQL writer discovery at end of session found no independent Physical Movement Writer outside `post_stock_movement`.

## CLOSED INVENTORY CONTROL BACKEND

Canonical gateway now exists:

`public.inventory_control(text,jsonb)`

It derives the authenticated user from `auth.uid()` and derives company context from `users.auth_id` / `users.company_id`.

Supported operations:
`SNAPSHOT`
`MOVEMENTS`
`REPLENISHMENT`
`COUNT`
`REQUEST`

The gateway delegates to the existing inventory engines rather than creating a second stock engine.

Production test with real Owner auth identity returned Snapshot successfully.
Production test with real Picker auth identity returned Snapshot successfully.

## REQUEST SECURITY

RLS is now enabled on:
`inventory_stock_requests`
`inventory_stock_request_details`

Policies are company-scoped through:
`app_private.current_user_company_id()`

`anon` direct access was revoked.

## REALTIME

Current publication includes:
`stock_branches`
`inventory_log`
`orders`
`order_details`
`runsheets`
`run_sheet_details`
`stock_vouchers`
`stock_voucher_details`
`inventory_stock_requests`
`inventory_stock_request_details`
`inventory_counts`
`inventory_count_details`
`erp_operation_registry`

`erp_operation_registry` was added during this session after direct verification that it was missing.

## CLOSED / DEPLOYED FIELD OPERATIONS

### complete-return
Edge `complete-return` v26.

Status:
`CLOSED — DB/RPC transactional proof`

### complete-order-delivery
Edge `complete-order-delivery` v14.

Delivery remains fulfillment-only; no parallel Physical Stock writer.

Status:
`CLOSED — DB/RPC transactional proof`

### picking
Edge `complete-picking` v17.

Reservation-only physical boundary through `reserve_stock`.

Status:
`CLOSED — DB/RPC transactional proof`

### loading / unloading
Edges:
`complete-loading` v11
`unload-runsheet` v6

Operation identity and duplicate protection are deployed and DB-verified.

Status:
`DEPLOYED + DB VERIFIED`

Authenticated Browser/Network runtime verification after final deployment remains OPEN.

## DATA INTEGRITY

`items.item_code` is globally UNIQUE.
`stock_branches` is unique on `(branch_id,item_id)`.
`receiving.operation_id` is UNIQUE.
`erp_operation_registry` is unique on `(company_id,operation_type,operation_key)`.

No cross-company stock rows were deleted or reassigned from count-based assumptions.

`order_details` remains authoritative fulfillment detail.
`run_sheet_details` is derived by trigger.

Do not introduce Dual Write.

## INVENTORY MOTHER GAP

The following backend capabilities are now available to the Mother through `inventory_control()`:

- stock snapshot
- movement report
- replenishment report
- inventory count engine
- inventory stock request engine

The only remaining Mother-side gap is implementation of:
`RW_Warehouse.loadInventoryControl()`

The exact insertion point and complete function are documented in:
`doc/Draft/Reprots/Report210_GLOBAL_INVENTORY_CONTROL_FORENSIC_CLOSURE_20260916.md`

## SECURITY OBSERVATIONS

The remaining security advisor findings outside this closure must stay separate until consumer and authorization mapping is complete.

Do not widen permissions on arbitrary functions just to make the Mother work.

## CURRENT CLOSURE STATUS

```text
Current Git / Parent                     VERIFIED
Latest HEAD                              6533ab8924c2a2fe76a78aabec413b4dae3019f0
Latest Parent                            2430b5b4922b53f218f7e4bd4c52a603e7ef8f0b
Business Mother Commit                   e0c806e47a761561fc4177ffd2a4d9fc8d7d7dc9
Mother Source Blob                       33a7c2c9e7e35d546ea960f84f4feee16ec4d632
Mother HTML modified by assistant       NO
Physical Writers outside core            0 discovered
Inventory Control DB Gateway             CLOSED
Inventory Request RLS                    CLOSED
Inventory Realtime support               CLOSED
Complete Return                          CLOSED — DB/RPC
Complete Order Delivery                  CLOSED — DB/RPC
Picking                                  CLOSED — DB/RPC
Loading                                  DEPLOYED — browser runtime OPEN
Unloading                                DEPLOYED — browser runtime OPEN
Mother Inventory Control                OPEN — owner patch
Authenticated Mother E2E                 OPEN
Global Inventory Zero-Debt               NOT YET 100%
Gold/Diamond Inventory                   OPEN
```

## NEXT SESSION — EXACT START ORDER

1. Read latest frontend HEAD `6533ab8924c2a2fe76a78aabec413b4dae3019f0` and direct parent `2430b5b4922b53f218f7e4bd4c52a603e7ef8f0b`.
2. Open current `companies/company-1/main.html` and verify its blob is still `33a7c2c9e7e35d546ea960f84f4feee16ec4d632` or record the new current blob if the owner has merged changes.
3. Take a fresh Production snapshot before every material conclusion.
4. Apply only the exact `loadInventoryControl()` surgical patch from Report210; do not rebuild the Mother from historical fragments.
5. Re-read the merged Mother source after the owner patch.
6. Run authenticated Browser + Console + Network E2E on the Mother.
7. Re-check Loading/Unloading browser runtime after the latest Production deployment.
8. Compare browser-visible Control Plane values with same-moment Production values.
9. Only then move to the next proven inventory capability gap or the Finance/HR/CRM/Reports gap.
10. Never declare 100% while any material Unknown, Conflict, or Unverified Claim remains.

## GOVERNANCE RULE

Never trust a previous report as a current snapshot. Reconstruct current truth from live Git/Source/Production/Database/Deployment before every Closure Unit.

## LATEST EXECUTION REPORT

`doc/Draft/Reprots/Report210_GLOBAL_INVENTORY_CONTROL_FORENSIC_CLOSURE_20260916.md`
