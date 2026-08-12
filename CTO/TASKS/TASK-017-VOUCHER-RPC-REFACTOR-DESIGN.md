# TASK-017 — Voucher RPC Refactor Design

## Status
**COMPLETE / GO TO TASK-018**

## Objective
Freeze the unified Manual Voucher RPC contract before changing the deployed Voucher implementation or consumers.

## Production evidence basis
The current rescue evidence establishes deployed RPCs for:

- `public.create_manual_stock_voucher_atomic(uuid,text,text,text,uuid,text,uuid,text,text,jsonb)`
- `public.send_stock_voucher_atomic(uuid,text,text)`
- `public.post_manual_stock_voucher_atomic(uuid,text,text,text,jsonb)`
- `public.complete_manual_stock_voucher_atomic(uuid,text,text)`

Production execution already proved the DirectSale lifecycle through TASK-004 and proved the Inventory Core transaction/concurrency properties through TASK-010 to TASK-016.

## Unified lifecycle contract

```text
CREATE
  ↓
Draft
  ↓
SEND
  ↓
Sent
  ├── Transfer / DirectReturn
  │      ├── Partial RECEIVE → Sent
  │      └── Full RECEIVE → Received
  │                    ↓
  │                 COMPLETE
  │                    ↓
  │                 Completed
  │
  └── DirectSale / SupplierReturn
         ↓
      COMPLETE
         ↓
      Completed

Draft → Cancelled
```

## Operation contracts

### CREATE
- Creates Voucher header and detail rows.
- Initial state: `Draft`.
- Creation does not itself perform physical stock mutation.
- Exact deployed signature is the Production CREATE signature listed above.

### SEND
- Valid transition: `Draft → Sent`.
- Physical stock effect is operation-specific and must occur exactly once through the authoritative Stock Engine boundary after consumer refactor.
- `allocated_qty` is not a substitute for physical movement.
- Current Production has more than one SEND-capable RPC; no replacement/removal decision is authorized by TASK-017 alone.
- Current consumer evidence must be reconciled before TASK-018 rewires or replaces the deployed SEND path.

### RECEIVE
- Applies only to Voucher types whose custody model requires receiving.
- Valid transition for a full receipt: `Sent → Received`.
- Partial receipt retains `Sent` and accumulates `received_qty`.
- Receive quantity must never exceed remaining quantity.
- Physical target-side mutation must be exactly once per accepted receipt through the authoritative movement boundary.

### PARTIAL RECEIVE
- `received_qty` is cumulative.
- `remaining_qty = qty - received_qty`.
- Full receipt is required before `Received`.
- TASK-010 already proved the current Production path is non-idempotent for a repeated logical partial RECEIVE. TASK-017 does not silently patch that defect; the finding is carried into implementation/testing tasks.

### COMPLETE
- Administrative lifecycle closure only.
- Does not perform physical stock mutation.
- `Transfer / DirectReturn`: requires `Received`.
- `DirectSale / SupplierReturn`: requires `Sent`.
- Production definition writes `completed_at` and `completed_by`.

### CANCEL
- Administrative cancellation.
- Current established contract permits cancellation from `Draft`; no later-state cancellation behavior is promoted to Target without explicit evidence/decision.
- Must not create an additional physical stock movement.
- Must not leave an unresolved reservation or duplicate history effect.

## Movement / voucher boundary

- `stock_branches.qty` = physical stock state.
- `stock_branches.allocated_qty` = reservation state, separate from movement.
- `inventory_log` = posted movement history.
- `public.post_stock_movement(...)` = central physical-stock posting boundary now deployed and verified by TASK-013/014/015/016.
- Voucher RPCs are workflow/adapters; they must not remain competing physical stock business engines after refactor.

## Security contract

Every modified/new central RPC must preserve the established Production security posture:

- `SECURITY DEFINER` where the deployed contract requires it.
- `SET search_path TO 'public'`.
- No RLS bypass as a workaround.
- No direct client/table-write substitute for the central engine.

## Explicit non-decisions / UNKNOWNs carried forward

The following are intentionally NOT invented by TASK-017:

1. Exact final unified function name/signature for the replacement Voucher orchestrator.
2. Whether `send_stock_voucher_atomic` or `post_manual_stock_voucher_atomic` becomes the single SEND/RECEIVE adapter before TASK-018 reconciliation.
3. Final DirectSale/DirectReturn custody semantics where current and target evidence have historical discrepancies.
4. Accounting and Audit side effects beyond what Production evidence directly proves.
5. Idempotency implementation mechanism for RECEIVE.

## Decision
TASK-017 freezes the lifecycle and responsibility boundaries without prematurely changing Production RPCs.

## Gate
**TASK-017 CLOSED / GO TO TASK-018.**

## Next task
TASK-018 — Send Voucher: reconcile the actual Production SEND consumer path and implement the minimal safe integration with the deployed central Stock Engine, followed by one comprehensive Production test and verification.
