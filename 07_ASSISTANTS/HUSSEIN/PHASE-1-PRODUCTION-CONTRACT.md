# HUSSEIN — PHASE 1 PRODUCTION CONTRACT

## CONFIRMED FACTS

Production schema evidence proves `stock_vouchers` has no `completed_by` while the project execution status records the deployed COMPLETE path attempting to write it.

`complete_manual_stock_voucher_atomic(uuid,text,text)` is deployed as `SECURITY DEFINER`; it locks the voucher, expects `Received` for `Transfer/DirectReturn` and `Sent` for `DirectSale/SupplierReturn`, then attempts `status='Completed', completed_at=now(), completed_by=p_user_email`.

Current `complete-stock-voucher` validates expected status and calls this RPC.

`post_manual_stock_voucher_atomic(uuid,text,text,text,jsonb)` is `SECURITY DEFINER`. Current production behavior proved by the captured definition/evidence includes voucher locking, SEND/RECEIVE state validation, company/branch/item checks, OUT availability validation using `qty - allocated_qty`, stock quantity mutation, `inventory_log` insertion, RECEIVE `received_qty` update, and Sent/Received state transition.

Current SEND builds OUT effects only. Current RECEIVE builds IN effects only and supports partial receipt.

Current shared rules define four lifecycle types: `Transfer`, `DirectSale`, `DirectReturn`, `SupplierReturn`.

CREATE defaults DirectSale to `MAIN → VAN-<user.email>` and DirectReturn to `VAN-<user.email> → MAIN` only when the corresponding endpoint is omitted.

## PRODUCTION CONTRACT

| Stage | Proven behavior | Stock | Inventory log | Status |
|---|---|---|---|---|
| CREATE | creates voucher/details | None proven | None proven | Draft |
| SEND | OUT only for Transfer/DirectSale/SupplierReturn | qty decreases at source | Yes | Sent |
| RECEIVE | IN only for Transfer/DirectReturn; partial supported | qty increases at destination | Yes | Sent / Received when complete |
| COMPLETE | no stock mutation in captured definition | None | None proven | Completed |
| CANCEL | Draft-only status change in captured definition | None | None | Cancelled |

## DISCREPANCIES

### P0 — COMPLETE RPC / Production Schema mismatch
Production has no `stock_vouchers.completed_by`, while deployed COMPLETE writes it.

### P0 — DirectSale Target conflict
Current Production behavior is OUT source only. An unreleased migration proposes OUT source + IN destination. Final Target semantics are unresolved.

### P0 — DirectReturn Target conflict
Current Production behavior is IN destination only. An unreleased migration proposes OUT source + IN destination. Final Target semantics are unresolved.

### P1 — Full schema contract must be treated as Evidence, not reconstructed from memory.

### P1 — Audit path for COMPLETE/CANCEL is not fully proven by the captured evidence.

## ROOT CAUSE

1. Schema/RPC divergence.
2. Competing lifecycle definitions across current code, Production, original code, architecture and unreleased migration.
3. Audit contract not frozen.

## SAFE PATCH BOUNDARY

No implementation patch is authorized by this report until the Target Audit Contract and lifecycle decisions are reconciled.

No Production schema change should be made merely to silence `completed_by`.

## VALIDATION PLAN

1. Static preflight against Production schema and deployed RPC definitions.
2. Self-cleaning lifecycle test: CREATE → SEND → RECEIVE, including partial/full where Target requires → COMPLETE; separate valid CANCEL scenario.
3. Assert exact stock, inventory_log, allocated_qty, voucher state, actor/audit evidence, and duplicate-movement behavior.
4. Negative-path tests must prove no partial mutation.
5. Do not proceed to `vouchers.html` until Architecture → Target → Production schema → deployed RPC → Current Edge → Original preservation analysis → validation evidence are internally consistent.

## GATE

`NO GO — PHASE 1 RECONCILIATION NOT CLOSED`

No SQL execution, Production modification, schema change, or patch was performed by Hussein's analysis.
