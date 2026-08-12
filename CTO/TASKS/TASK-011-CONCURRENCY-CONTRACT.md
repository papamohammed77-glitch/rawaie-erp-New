# TASK-011 — Concurrency Contract

## Status
COMPLETE / GO TO TASK-012

## Evidence reviewed
- `SQL_Evidence/diagnostics/استعلام TASK-011 — Concurrency Contract  .md`
- `SQL_Evidence/diagnostics/TASK-011 — Concurrency Contract .csv`

## Query scope
The diagnostic retrieved the actual deployed definitions of:
- `post_manual_stock_voucher_atomic`
- `send_stock_voucher_atomic`
- `complete_manual_stock_voucher_atomic`

and evaluated row-locking plus conditional stock-update evidence.

## Proven Production result
All three deployed RPCs report `row_lock = YES`.

`send_stock_voucher_atomic` reports `conditional_stock_update = YES`.

`post_manual_stock_voucher_atomic` and `complete_manual_stock_voucher_atomic` report `conditional_stock_update = UNKNOWN` under the diagnostic's static detection rule; this is not converted into a stronger claim.

## Confirmed behavior from actual deployed definitions
- Voucher rows are selected with `FOR UPDATE` in the reviewed lifecycle functions.
- `post_manual_stock_voucher_atomic` locks `stock_branches` rows with `FOR UPDATE` before stock mutation and uses compare-and-set predicates on the observed `qty`/`allocated_qty` values.
- `send_stock_voucher_atomic` locks the voucher row and uses a conditional stock update that checks the observed stock values.
- `complete_manual_stock_voucher_atomic` locks the voucher row and updates only when the expected status still matches.

## Boundary
This task establishes the concurrency contract from deployed Production definitions. It is not a parallel load/stress experiment, so runtime contention timing is not claimed here.

## Evidence classification
PROVEN — Production deployed RPC definitions captured by the supplied diagnostic and result file.

## Gate
TASK-011 CLOSED / GO TO TASK-012
