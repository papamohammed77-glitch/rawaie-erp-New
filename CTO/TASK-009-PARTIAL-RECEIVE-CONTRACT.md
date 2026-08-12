# TASK-009 — Partial Receive Contract

## Status
**COMPLETE / GO TO TASK-010**

## Objective
Freeze the Production Partial RECEIVE behavior without conflating cumulative receipt with idempotency.

## Proven Production Contract
From `post_manual_stock_voucher_atomic`:

1. `RECEIVE` is supported only for `Transfer` and `DirectReturn`.
2. The Voucher must currently be `Sent`.
3. For each detail, the requested receive quantity must not exceed:
   `detail.qty - detail.received_qty`.
4. On successful inbound movement, `stock_voucher_details.received_qty` is increased cumulatively.
5. The function computes the remaining detail count after the receive.
6. If any detail remains incomplete, Voucher status remains `Sent`.
7. When all detail quantities are fully received, Voucher status becomes `Received` and `received_date` is populated.
8. The inbound stock movement and `received_qty` update are performed in the same RPC transaction path.

## Partial Receive State Model

```text
Sent
  │
  ├── RECEIVE q < remaining
  │       ├── target stock qty += q
  │       ├── received_qty += q
  │       └── status remains Sent
  │
  └── RECEIVE q = remaining
          ├── target stock qty += q
          ├── received_qty += q
          ├── status → Received
          └── received_date populated
```

## Idempotency Boundary
Partial Receive is **cumulative quantity processing**, not proof of idempotency.

The captured Production definition validates quantity against the remaining quantity but does not establish an independent operation identity/key that distinguishes a legitimate second receive from replay of the same request. The project therefore keeps Partial Receive replay/idempotency as the dedicated TASK-010 contract.

## Source of Truth
- Requested quantity: `stock_voucher_details.qty`.
- Cumulative received quantity: `stock_voucher_details.received_qty`.
- Current physical destination stock: `stock_branches.qty`.
- Movement history: `inventory_log`.
- Voucher lifecycle state: `stock_vouchers.status`.

## Gate
**TASK-009 CLOSED / GO.**

Partial Receive behavior is sufficiently proven from the Production RPC definition. Idempotency and replay safety are intentionally not inferred and proceed to TASK-010.

## Next Task
**TASK-010 — Idempotency Contract**
