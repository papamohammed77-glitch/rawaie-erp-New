# TASK-018 — Send Voucher

## Status
**CLOSED / GO TO TASK-019**

## Production execution
The user executed the complete TASK-018 Production SQL as one transaction and returned:

`TASK-018 — SEND VOUCHER PASS`

## What was implemented
- Extended the deployed `public.post_stock_movement(...)` contract to include the proven voucher SEND movement semantics required by `Transfer`, `DirectSale`, and `SupplierReturn`.
- Created `public.send_manual_stock_voucher_v2(uuid,text,text)` as the centralized SEND adapter.
- SEND locks the voucher, validates Draft state and SEND type, resolves item identity from the proven `items` contract, delegates physical stock mutation to `post_stock_movement`, and only then transitions the voucher to `Sent`.

## Production verification
The transactional test verified:
- CREATE succeeds.
- SEND succeeds.
- Voucher becomes `Sent`.
- Source physical stock decreases by exactly the sent quantity.
- `allocated_qty` remains unchanged.
- Exactly one corresponding `inventory_log` row is created.
- Test data is rolled back.
- The deployed functions persist after test rollback.

## Safety / scope
- No Edge Function consumer was rewired by TASK-018.
- No application UI was changed.
- Test voucher and stock/log effects were rolled back.
- The existing current Edge Function consumer remains a separate integration task; this is intentional and must be handled under the planned Edge Function rewire work.

## Evidence classification
**PRODUCTION EXECUTION VERIFIED.**

## Gate
**TASK-018 CLOSED / GO TO TASK-019.**
