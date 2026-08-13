# BACKUP CTO 08 — TASK-BY-TASK MEMORY

## Purpose
This file preserves the execution history needed to prevent a future CTO from repeating closed work, confusing design with Production, or reopening known failures without new contradictory evidence.

## Mandatory rule
A task is CLOSED only from the durable ledger plus Production evidence. Historical wording alone is not enough.

## TASK-001..009
These are early inventory/recovery gates already closed in the running rescue sequence. They must not be treated as speculative. Their detailed evidence remains in the historical/active task records; do not reconstruct them from memory when a task record exists.

## TASK-010
Result: `TASK-010 — NON-IDEMPOTENT PARTIAL RECEIVE PROVEN`.
Lesson: partial RECEIVE is a real concurrency/idempotency concern. Never pretend that cumulative `received_qty` alone proves request idempotency.

## TASK-011
Concurrency Contract closed with Production evidence.
Rule: concurrency must be proven from actual row locking/CAS/transaction behavior, not from function names.

## TASK-012
Result: `TASK-012 — ATOMIC TRANSACTION CONTRACT PASS`.
Rule: atomicity must be verified in Production execution, not inferred from a migration file.

## TASK-013 / 014
Both closed only after Production implementation was actually executed. Earlier target-design-only interpretations were explicitly corrected.
Lesson: a target RPC design is not an implementation until Production shows it exists and works.

## TASK-015
Result: `TASK-015 — STOCK ENGINE TESTS PASS`.

## TASK-016
Result: `TASK-016 — STOCK ENGINE GATE PASS`.

## TASK-017
Closed before TASK-018.

## TASK-018
Result: `TASK-018 — SEND VOUCHER PASS`.

## TASK-019
Result: `TASK-019 — RECEIVE VOUCHER PASS`.
Production schema mismatches encountered during the path were corrected before closing.

## TASK-020
Result: `TASK-020 — PARTIAL RECEIVE PASS`.
Contract includes required quantity, received quantity, remaining quantity, repeat receive behavior, completion threshold, movement generation, and over-receive prevention.

## TASK-021
Result: `TASK-021 — COMPLETE PASS`.

## TASK-022
Result: `TASK-022 — CANCEL PASS`.

## TASK-023
Result: `TASK-023 — VOUCHER INTEGRATION PASS`.

## TASK-024
Result: `TASK-024 — VOUCHER GATE PASS`.

## TASK-025
Owner/Production contract reconciliation was completed.
Owner decisions were explicitly recorded for DirectSale, DirectReturn and SupplierReturn.
Feature-parity matrix became the next gate.

## TASK-026
Source implementation and VAN custody baseline were completed.
The candidate implementation remained quarantined until the Runtime Gold Gate.

## TASK-027
Final result: `TASK-027 — VOUCHER E2E PASS`.

### Production baseline established
Company:
`da4ef704-88ac-4120-aa0e-65b92b2aa2bc`

MAIN:
`151e5cd7-ac4a-4fc3-b703-d73a0dbb0dc6`

Vehicle:
`VEH-92yrzb`
`70e5d809-0505-4e60-b317-feff6e799127`

VAN branch:
`VAN-VEH-92yrzb`
`dbdef0b7-0909-4f71-a367-30c61d021286`

Demo representative:
`van-sales@rawaea.com`
`a86726d9-d687-4113-a9e2-5f90f4bdb4fa`

### Permanent fixes
1. `setup_van_stock` stopped writing to generated `available_qty`.
2. `post_stock_movement` made `DirectSale` two-sided: source OUT + target IN, atomically.
3. `send_manual_stock_voucher_v2` passes `voucher.to_id` as target for `DirectSale` and `Transfer`.

### Final E2E proof
`CREATE -> DirectSale -> Send -> MAIN -1 -> VAN +1 -> inventory_log -> Sent -> Complete -> Completed`

Test data was rolled back. Permanent RPC fixes were retained.

### Critical failure lesson
A `CREATE OR REPLACE FUNCTION` inside a transaction that later fails is not a permanent fix. Separate durable fix commits from rollback test transactions.

## Next point
`STAGE-28 — Loading / Unloading Core`
