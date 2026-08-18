# RAWAEA ERP — MASTER PROJECT AWARENESS REPORT

Date: 2026-08-18
Execution mode: CTO Continuity Recovery
Authority: Direct GitHub + Supabase Production verification

## SELF-AUDIT

Business Understanding: CONFIRMED
Architecture Understanding: CONFIRMED
Database Understanding: CONFIRMED for the inspected scope
Historical Understanding: CONFIRMED for the inspected historical corpus
Production Understanding: CONFIRMED for the inspected deployed functions/core
Current Understanding: CONFIRMED for the inspected Current corpus
Execution Confidence: HIGH

Confirmed Facts:
- RAWAEA ERP is an FMCG/distribution ERP using Supabase/PostgreSQL, Edge Functions and PWA clients.
- The governing architectural principle is ONE CORE / ONE SOURCE OF TRUTH / controlled domain execution.
- Physical inventory movement is centralized in `post_stock_movement`.
- Reservation is separate through `reserve_stock` and reservation release.
- `complete_runsheet_picking` uses reservation only and does not post physical movement.
- Loading/Unloading cores resolve the Vehicle-owned `VAN-{vehicle_code}` branch and use `post_stock_movement`.
- `setup-van-branch` is Production ACTIVE at version 3 and is vehicle-owned.
- Current `setup-van-branch` exists at `Current/Edge_Functions/setup-van-branch`.
- Current `send-stock-voucher` is already a thin adapter to `send_stock_voucher_atomic`.
- Production currently contains a large deployed Edge Function surface, including picking, loading, returns, vouchers, purchasing, inventory and reporting capabilities.

Unknowns:
- Complete Production contract for every Manual Voucher COMPLETE/CANCEL audit effect is not yet proven from the current persisted evidence set.
- Partial RECEIVE request-level idempotency is not proven as an independent contract.
- DirectSale / DirectReturn custody semantics remain a reconciliation point where historical/target material and current Production behavior differ.
- The legacy/current planning documents are internally inconsistent with the newer deployed state and must not be treated as execution truth without reconciliation.

Conflicts:
- `CTO/PLAN-STATUS-CURRENT.md` still describes TASK-017 as the current position and queues later work, while actual Production contains significantly newer deployed versions and additional runtime harnesses.
- Historical/manual-voucher documentation contains schema assumptions that are contradicted by captured Production schema evidence.
- Some older documents describe broader inventory/audit structures than the current Production schema.

Unverified Claims:
- Any percentage-based project completeness claim is intentionally excluded.
- Any claim that all historical technical debt is already closed is rejected.

## SOURCE AUTHORITY

Priority used:
1. Latest direct Production SQL/function evidence.
2. Actual deployed Edge Function definitions/version/package identity.
3. Current source.
4. Architecture/governance.
5. Historical/Original/Archive.
6. Unreleased migrations only as target candidates.

Historical Repository:
`papamohammed77-glitch/rawaie-erp-review`

Key historical layers found:
- `Edge_Functions/original/`
- `Edge_Functions/current/`
- `Edge_Functions/archive/`
- `PWA/`
- `Architecture/`
- `Edge_Function_Reports/`
- `docs/`
- `SQL_Evidence/`

Active Repository:
`papamohammed77-glitch/rawaie-erp-New`

Key current layers found:
- `CTO/`
- `Current/`
- `Original/`
- `Inventory/`
- `Rescue/`
- `Evidence/`
- `Governance/`
- `SQL_Evidence/`
- `supabase/`
- `doc/`

## PROJECT DIAGNOSIS

Historical root problem:
`DISTRIBUTED BUSINESS LOGIC`

Multiple Edge Functions historically performed stock mutation, inventory logging, order/runsheet state changes, accounting, backorders and ledger effects independently. This created double deduction, conflicting histories, multiple sources of truth and Production drift.

Current rescue direction:

`Business Event`
→ `Capability / Core`
→ `central domain engine`
→ `authoritative state + authoritative history`

For inventory:

`Business Event`
→ `post_stock_movement`
→ `stock_branches + inventory_log`

For reservation:

`Business Event`
→ `reserve_stock / release_stock_reservation`
→ `allocated_qty`

## CURRENT INVENTORY CORE

Production directly exposes and uses:
- `post_stock_movement(...)`
- `reserve_stock(...)`
- `release_stock_reservation(...)`

`post_stock_movement` currently supports the deployed movement vocabulary including:
- PurchaseIn
- TransferOut
- TransferIn
- DirectSale
- DirectReturn
- SupplierReturn
- POSSale
- VanSale
- SalesReturn
- PurchaseReturn
- InventoryIncrease
- InventoryDecrease
- Loading
- Unloading

Loading and Unloading require event-level idempotency keys.

The current implementation validates branch/company context, locks stock rows, checks available/reserved balances according to movement type, updates stock and writes `inventory_log` in the same core transaction path.

## WAREHOUSE / RUNSHEET REALITY

Verified lifecycle boundary:

Open / Confirmed
→ Picking
→ Picked
→ Loading
→ Loaded
→ Delivery / Return / Unloading

Picking:
- `complete_runsheet_picking` is Core-driven.
- It uses `reserve_stock`.
- Physical `qty` is not changed by Picking.
- Picking does not create an inventory movement log.

Loading:
- `complete_runsheet_loading` resolves the Vehicle's `VAN-{vehicle_code}` branch.
- Physical movement is `MAIN → VAN` through `post_stock_movement`.

Reopen Loading:
- Current Production Core uses the previous loading cycle as the historical event context.
- Existing loaded quantities are unloaded through the central engine.
- A new `loading_cycle_id` is created.
- Event idempotency is tied to the reopen operation context.

Unloading:
- `complete_runsheet_unloading` resolves the same Vehicle-owned Van branch.
- Physical movement is `VAN → MAIN` through `post_stock_movement`.

## VAN / VEHICLE MODEL

The current canonical model is:

`Vehicle`
→ `vehicle_code`
→ `VAN-{vehicle_code}`
→ `branches`
→ `stock_branches`

Driver identity is metadata through `vehicles.driver_id` and is not the physical stock-location identity.

`setup-van-branch` is an Initialization Capability only.
It does not perform commercial stock movement.
`setup_van_stock` creates missing zero-balance stock rows only.

## PRODUCTION DEPLOYMENT SNAPSHOT

Production project:
`fiilmooggumokxanwiyx`

Key deployed functions verified during continuity recovery:
- `save-sales-invoice` v14
- `create-runsheet` v26
- `start-picking` v33
- `complete-picking` v15
- `start-loading` v5
- `complete-loading` v11
- `complete-return` v23
- `unload-runsheet` v6
- `send-stock-voucher` v19
- `receive-stock-voucher` v21
- `receive-purchase` v9
- `bulk-stock-adjustment` v5
- `setup-van-branch` v3

Important: version existence is not equivalent to Closure. Runtime proof is required for implementation/test tasks.

## CURRENT SOURCE SNAPSHOT

Key inspected Current artifacts include:
- `Current/Edge_Functions/setup-van-branch`
- `Current/Edge_Functions/send-stock-voucher`
- `Current/Edge_Functions/complete-picking`
- `Current/Edge_Functions/complete-loading`
- `Current/Edge_Functions/complete-return`
- `Current/Edge_Functions/unload-runsheet`
- `Current/Edge_Functions/save-sales-invoice`
- `Current/Edge_Functions/bulk-stock-adjustment`
- `Current/Edge_Functions/receive-stock-voucher`
- `Current/Edge_Functions/create-runsheet`

## IMPORTANT PRODUCTION FINDINGS

### Manual Voucher schema contradictions
Captured Production evidence proves:
- `stock_vouchers` does not contain `completed_by`.
- `inventory_log` does not contain `branch_id`.
- `stock_voucher_details` contains `received_qty`.

Any migration assuming those absent columns is a TARGET CANDIDATE until reconciled.

### Partial RECEIVE
Production behavior allows cumulative partial receive using `received_qty`.
Independent request-level idempotency for legitimate repeated partial receives is not yet proven.

### DirectSale / DirectReturn
Current Production behavior is authoritative for the deployed path, while historical/target material contains competing custody interpretations. No unproven Target behavior is promoted.

### CANCEL / audit
Persisted rescue evidence does not fully prove every current COMPLETE/CANCEL audit effect. This remains an evidence/contract item, not a reason to invent schema.

### Security / RLS
Production advisory review found:
- leaked-password protection disabled at Auth level (warning).
- numerous RLS init-plan optimization warnings.
- many unindexed foreign-key recommendations.
- multiple permissive policy warnings.
- duplicate branch indexes (`branches_company_id_branch_code_key` and `ux_branches_company_branch_code`).
These are real governance/debt findings, but not all belong inside the current inventory closure unless they affect the active Closure Unit.

## APPLICATION / CONSUMERS

Primary Golden/critical applications found:
- `PWA/warehouse/vouchers.html`
- `PWA/sales/van-sales.html`
- warehouse picker/loader/unloader/returns applications
- delivery applications
- purchasing applications

Application rule:
Applications are event sources and consumers of backend contracts, not autonomous business engines.
Any future UI modification must reconcile Original + Historical + Current + Production + Consumer Contract before patching.

## CURRENT CLOSURE STATE

Verified from direct current evidence and recent execution records:

- `complete-picking`: Production runtime verified.
- `setup-van-branch`: Production runtime verified and closed in the preceding Stage-28 execution.
- `send-stock-voucher`: Production uses the central atomic path; Current source is already an adapter.
- Manual Voucher contract work has substantial Production evidence but still contains reconciliation debt around partial RECEIVE idempotency, DirectSale/DirectReturn target semantics, and full audit/CANCEL proof.
- `vouchers.html`: candidate work is quarantined and not Production-ready until Gold parity is demonstrated.
- Broader rescue work remains open: receive-stock-voucher, receive-purchase, bulk-stock-adjustment, save-sales-invoice, complete-return, complete-order-delivery, global stock-writer sweep, Accounting/Audit/Security, full E2E and final Production gate.

## NEXT EXECUTION PRIORITY

The next work item must be selected from direct Production truth, not the stale numeric plan alone.

Immediate candidate sequence:
1. Reconcile/close `send-stock-voucher` source-vs-Production gate if any mismatch remains.
2. Execute `receive-stock-voucher` Closure Unit end-to-end.
3. Execute `receive-purchase` Closure Unit.
4. Execute `bulk-stock-adjustment` Closure Unit.
5. Execute `save-sales-invoice` Closure Unit.
6. Execute `complete-return` Closure Unit.
7. Execute `complete-order-delivery` Closure Unit.
8. Perform global physical stock writer sweep.
9. Reconcile Accounting / Audit / Security.
10. Final full-system Production proof.

No future unit is considered closed merely by documentation.

## FINAL SELF-AUDIT

What I Proved:
- Both repositories exist and contain the expected Historical/Original/Current/Archive/governance layers.
- Production has a deployed centralized inventory core and a large deployed capability surface.
- Warehouse Loading/Unloading and Picking boundaries are materially aligned with the Inventory Rescue contract.
- `setup-van-branch` is a Vehicle-owned initialization capability in Production.
- `send-stock-voucher` is already a thin Production adapter to atomic Core.

What I Did Not Prove:
- Full project-wide zero debt.
- Every application screen's Production parity.
- Full Accounting centralization.
- Full manual-voucher audit semantics.
- Final Partial RECEIVE idempotency contract.

What I Fixed:
- Nothing in application or Production was changed during the awareness/recovery phase.
- The awareness report itself was created as a durable CTO artifact.

What I Initially Missed:
- The existing numeric execution plan is stale relative to the deployed Production function surface.

What Could Still Be Wrong:
- Some Current files may still represent historical or candidate behavior despite current naming.
- Some Production functions may have semantic drift that version numbers alone do not reveal.
- The broader writer sweep is not yet complete.

Final Confidence: HIGH for the inspected scope; not a claim of project-wide closure.
Final Closure Status: AWARENESS RESTORED — CONTINUE DIRECT EXECUTION.
