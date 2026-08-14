# TASK-028 CONTRACT RECONCILIATION REPORT

Date: 2026-08-14
Authority: Supervised CTO / Principal CTO review required
Status: CONTRACT RECONCILIATION COMPLETE TO THE EXTENT SUPPORTED BY EVIDENCE
Implementation: NO-GO
Production Mutation: NONE

## Executive Decision

Evidence Acquisition is now materially complete for the Loading/Unloading boundary. The remaining blocker is not lack of repository reconnaissance; it is an irreducible business/stock-topology decision:

**BLOCKER: TARGET STOCK BOUNDARY REQUIRES OWNER DECISION**

The evidence proves that current Production deducts MAIN stock during Loading, while the established Owner Contract separately defines DirectSale as MAIN → VAN custody and explicitly distinguishes Loading from DirectSale. Production also currently has zero VAN stock for the RS-1 fixture. Therefore the available evidence is insufficient to safely select between:

A. Loading itself performs MAIN → VAN physical stock transfer;
B. Loading performs no physical stock mutation and remains an operational state/quantity transition;
C. Loading moves stock to another operational branch/location; or
D. Loading changes a reservation/allocation state without physical transfer.

No implementation may be based on intuition here.

---

## A. Confirmed Facts

1. RS-1 is the current Golden Fixture and is Open with 12 detail rows; at the audited point qty_picked and qty_loaded were zero and there were no corresponding Loading inventory log entries.
2. Production has MAIN branch BR-01 and a VAN branch for VEH-92yrzb; audited stock for the RS-1 item set was present in MAIN and zero in the VAN branch.
3. Production `post_stock_movement` exists as a security-definer stock engine with row locking, but its accepted movement types do not currently include Loading or Unloading.
4. Deployed `complete-loading` currently performs direct MAIN stock mutation, inventory logging, run-sheet quantity updates, order quantity updates, accounting, backorder processing, and state transition. This is current deployed behavior, not target design.
5. Deployed `unload-runsheet` currently restores MAIN stock and resets operational quantities/state. This is current deployed behavior, not target design.
6. Production has `order_details -> sync_run_sheet_details()` trigger behavior. Therefore dual-writing `order_details` and `run_sheet_details` without an explicit contract is unsafe.
7. `stock_branches.available_qty` is generated from `qty - allocated_qty` and is not a direct writable stock field.
8. Production does not currently have a demonstrated unique constraint on `(runsheet_id,item_code)` in `run_sheet_details`. This is a concurrency/design risk, not a proven runtime failure.
9. Production has an `app_settings.company_id` / `app_settings.company_name` naming conflict with the corresponding `companies` row. This is a real conflict but is not the primary TASK-028 stock-boundary blocker.
10. Historical `complete-loading` also directly reduced MAIN stock, wrote Loading inventory logs, updated `run_sheet_details` and `order_details`, recalculated order totals, and posted accounting. This historical implementation is evidence of prior behavior, not authority for the target architecture.

## B. Owner Contract

These decisions are already established and are NOT reopened:

- Order → Runsheet → Picking/Preparation → Loading → Loaded → Delivery Order-by-Order → Delivered.
- Emergency Unloading: Loaded → Full Unloading → Picked.
- Customer Return occurs Order-by-Order during Delivery.
- Vehicle ≠ Representative.
- Vehicle is a mobile stock container / operating unit.
- Representative is the custodian/accountable party.
- DirectSale = MAIN → VAN custody.
- VanSale = VAN → Customer.
- DirectReturn = VAN → MAIN.
- SupplierReturn = Branch/Warehouse → Supplier.
- Loading ≠ DirectSale.
- Unloading ≠ Customer Return.
- Original source remains immutable.
- Current is the development workspace.
- Production evidence outranks migration intent and historical documentation.

## C. Current Production Deviations

| Aspect | Current Production | Classification |
|---|---|---|
| Runsheet lifecycle | Loading/Loaded states are implemented | CONFIRMED |
| qty_ordered | Order requested quantity | CONFIRMED |
| qty_picked | Updated during Picking | CONFIRMED |
| qty_loaded | Updated during Loading | CONFIRMED |
| allocated_qty | Used for reservation; Picking calls `reserve_stock` | CONFIRMED |
| MAIN stock | Directly reduced by deployed complete-loading | CONFIRMED |
| VAN stock | Not increased by deployed complete-loading; audited VAN stock is zero for RS-1 items | CONFIRMED |
| inventory_log | Loading log is written directly by deployed complete-loading | CONFIRMED |
| accounting | Deployed complete-loading creates accounting entries | CONFIRMED |
| backorder | Historical/current loading logic includes backorder handling | CONFIRMED FROM SOURCE; target boundary unresolved |
| idempotency | No proven business idempotency key for Loading | UNKNOWN / GAP |
| atomicity | Multi-step writes exist; no single transaction boundary has been proven | UNKNOWN / GAP |
| Unloading | Restores MAIN and resets operational quantities/state | CONFIRMED CURRENT |
| partial Loading | Code supports item quantities, but target invariant/partial contract is not formally approved | PARTIALLY CONFIRMED / TARGET UNRESOLVED |
| failure recovery | No proven atomic rollback across all side effects | UNKNOWN / GAP |

## D. Target Loading Contract

The operational target is fixed:

1. Runsheet must be in Loading state.
2. Loading quantity cannot exceed the approved/picked quantity for the relevant business line/event.
3. Loading must be idempotent: retrying the same business event cannot duplicate stock, log, accounting, backorder, or quantity effects.
4. All effects that constitute one Loading business event must share a single defined atomic boundary.
5. The authoritative quantity table must be explicitly selected; `order_details` and `run_sheet_details` must not be independently dual-written without trigger-aware justification.
6. `available_qty` must never be written directly.
7. Any physical stock mutation must occur through the approved central stock engine once its Loading semantics are defined.
8. Accounting must occur exactly at the business event defined by the Owner Contract; the current historical accounting behavior cannot be copied merely because it exists.
9. The physical stock source/target is NOT yet safely determined.

**BLOCKER: TARGET STOCK BOUNDARY REQUIRES OWNER DECISION.**

## E. Target Unloading Contract

Unloading must be the formal inverse of the approved Loading contract.

Therefore, until Loading stock semantics are approved, Unloading cannot be finalized independently.

The invariant is:

`Loading + Unloading = reversible state transition`

For every approved Loading mutation there must be an exact inverse covering:

- stock quantity,
- inventory history,
- allocation/reservation state,
- run-sheet quantities,
- order quantities where applicable,
- accounting if Loading posts accounting,
- backorder state if Loading creates one.

## F. Quantity Invariants

The minimum candidate invariants are:

`qty_loaded <= qty_picked <= qty_ordered`

and:

`qty_delivered + qty_refused + qty_returned <= qty_loaded`

These are suitable acceptance invariants but are not declared a final Production contract where the existing implementation semantics differ. The exact per-order/per-item aggregation rules still require approval as part of the final contract.

## G. Stock Mutation Boundary

### Proven

- Picking reserves stock through `reserve_stock`; it does not transfer physical stock between MAIN and VAN.
- Current complete-loading reduces MAIN stock directly.
- Current complete-loading does not establish a VAN stock increase.
- DirectSale is independently defined as MAIN → VAN custody.

### Not proven

Whether the target Loading event itself should perform:

`MAIN → VAN`

or should remain operational-only / reservation-driven.

### Decision

**BLOCKER — OWNER DECISION REQUIRED.**

No `Loading` or `Unloading` movement type may be added to `post_stock_movement` until this boundary is approved.

## H. Atomicity Model

Required target property: one logical Loading business event must not leave stock, inventory log, operational quantities, accounting, or backorder in a partially committed inconsistent state.

However, the exact implementation boundary is not yet approved because the stock boundary and accounting boundary are unresolved.

No claim is made that the current Edge Function is atomic.

## I. Idempotency Model

A retry must not duplicate:

- stock effect,
- inventory log,
- journal entry,
- backorder,
- quantity transitions.

No existing Production Loading idempotency key has been proven. Candidate keys such as `runsheet_id + operation` or an explicit operation/event UUID are design candidates only and require contract approval.

## J. Accounting Boundary

Historical/current Loading code posts a CostOfGoodsSold-style journal based on loaded cost. This proves existing behavior only.

It does NOT prove that Loading is the correct accounting event in the target architecture.

**TARGET ACCOUNTING EVENT: DECISION REQUIRED unless Owner confirms Loading as the accounting recognition boundary.**

## K. Backorder Boundary

Historical/current Loading logic contains Backorder behavior for unfulfilled quantities. This is confirmed as existing behavior.

The target must define whether Backorder is:

- created during Loading,
- created from a failed/partial Loading event,
- created after a separate fulfillment decision,
- or represented only as an operational remainder.

**TARGET BACKORDER BOUNDARY: DECISION REQUIRED.**

## L. Surgical Patch Plan

No code patch is authorized yet.

Once the stock boundary and accounting/backorder boundaries are approved, the surgical sequence is:

1. Freeze the approved Loading Contract.
2. Define the central movement semantics and exact source/target branches.
3. Define idempotency event identity and duplicate protection.
4. Define the atomic database boundary covering stock/log/quantities/accounting/backorder.
5. Extend the central stock engine only if Loading/Unloading are confirmed as physical stock movements.
6. Refactor `complete-loading` to orchestrate the approved core contract rather than directly mutating stock.
7. Implement Unloading as the exact inverse.
8. Preserve Original unchanged.
9. Modify Current only.
10. Static verification.
11. Non-production runtime tests with boundary, retry, partial, insufficient-stock, and failure scenarios.
12. Production read-only verification.
13. Principal CTO review.
14. Only then consider Production deployment.

## M. Remaining Unknowns

### CRITICAL KNOWLEDGE / OWNER GAPS

1. **Loading stock boundary:** Does Loading physically transfer MAIN → VAN, or is it operational-only/reservation-based?
2. **Accounting boundary:** Is Loading the accounting recognition event, or does accounting occur later at VanSale/another event?
3. **Backorder boundary:** At what exact event is a backorder created and what quantity is represented?
4. **Idempotency identity:** What uniquely identifies one Loading business event?
5. **Partial Loading contract:** Is partial loading allowed per item/order, and how is the remainder represented?
6. **Authoritative quantity table:** Which table owns each phase quantity when trigger synchronization is active?

### NON-BLOCKING / SECONDARY

7. `app_settings.company_name` versus `companies.name` display authority.
8. Potential concurrency risk in `sync_run_sheet_details()` due to check-then-insert behavior without a proven composite unique constraint.

## N. Acceptance Criteria

Before implementation can become GO:

1. Owner-approved Loading stock boundary.
2. Owner-approved accounting boundary.
3. Owner-approved Backorder boundary.
4. Explicit idempotency contract.
5. Explicit partial Loading contract.
6. Explicit authoritative quantity ownership with trigger interaction documented.
7. Atomicity design proven at database boundary.
8. Loading and Unloading are exact inverses for every physical/quantity mutation.
9. No direct writes to generated `available_qty`.
10. No duplicate stock/log/journal/backorder effects on retry.
11. Insufficient-stock and partial-failure tests defined.
12. Original remains untouched.
13. Current-only surgical change prepared.
14. Static verification passes.
15. Runtime verification passes outside Production.
16. Production read-only verification passes.
17. Principal CTO approval obtained before Production mutation/deployment.

## O. Recommended Next Action

**STOP FOR PRINCIPAL CTO REVIEW.**

The Evidence Gate is closed enough to stop broad reconnaissance. The remaining blocker is a narrow business contract decision, not an information-collection problem.

Principal CTO must answer the six CRITICAL questions in section M. Once answered, the CTO can convert this report directly into the exact Target Contract and Surgical Patch Plan without restarting reconnaissance.

### Final Gate

`TASK-028 = CONTRACT RECONCILIATION COMPLETE / IMPLEMENTATION BLOCKED BY OWNER CONTRACT`

`PRODUCTION MUTATION = NONE`

`PRODUCTION DEPLOYMENT = NO-GO`
