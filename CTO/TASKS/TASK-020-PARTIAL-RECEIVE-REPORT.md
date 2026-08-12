# TASK-020 — Partial Receive

## Status
**CLOSED / GO**

## Production Result
`TASK-020 — PARTIAL RECEIVE PASS`

## Verified State Model
- Voucher quantity: 100
- First receive: 60
- State after first receive: `Sent`
- Remaining quantity: 40
- Second receive: 40
- State at full receipt: `Received`

## Production Boundary Tests
- Attempted receive above remaining quantity (`41` while `40` remained): rejected.
- Rejected over-receive generated no inventory movement.
- Attempted receive after full receipt: rejected.
- `received_qty` is cumulative.
- Each successful partial receive creates its own inventory movement through the central stock engine.
- Final physical stock delta equals the total actually received.
- Test data was rolled back.

## Architecture Decision
Partial Receive is a cumulative receipt process. The voucher remains `Sent` until cumulative `received_qty == qty`; only then does it transition to `Received`.

## Production RPC
`public.receive_manual_stock_voucher_v2(uuid,text,text,jsonb)`

## Evidence Classification
**PROVEN — actual Production execution.**

## Gate
**TASK-020 CLOSED / GO → TASK-021**
