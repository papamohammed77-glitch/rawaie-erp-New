# RAWAEA ERP — CTO Project Execution Ledger

## Purpose
This file is the durable handoff ledger for the Inventory / Manual Vouchers / Van Sales recovery sequence. It is the first place a future CTO should read after `CTO/00_MASTER_CONTEXT.md`.

## Authority
The sole active CTO source repository is `papamohammed77-glitch/rawaie-erp-New`.
Historical/reference material may remain in `rawaie-erp-review`, but it is not the active CTO source.

## Execution discipline
Every task follows: Evidence -> Reconciliation -> Target Decision -> Minimal Permanent Patch -> Tests -> Production Verification -> Durable Record.
No task is CLOSED from design alone. Production implementation and evidence are mandatory where the task changes Production behavior.

## Task status ledger

| Task | Status | Production reality / result |
|---|---|---|
| TASK-001 | CLOSED / GO | Historical/early project gate completed in the running rescue sequence. |
| TASK-002 | CLOSED / GO | Historical/early project gate completed. |
| TASK-003 | CLOSED / GO | Historical/early project gate completed. |
| TASK-004 | CLOSED / GO | Completed state/catalog gate proved `Completed`. |
| TASK-005 | CLOSED / GO | Historical gate completed. |
| TASK-006 | CLOSED / GO | Inventory Movement Matrix completed. |
| TASK-007 | CLOSED / GO | Production verification completed before advancing. |
| TASK-008 | CLOSED / GO | Production verification completed before advancing. |
| TASK-009 | CLOSED / GO | Production verification completed before advancing. |
| TASK-010 | CLOSED / GO | `TASK-010 — NON-IDEMPOTENT PARTIAL RECEIVE PROVEN`. |
| TASK-011 | CLOSED / GO | Concurrency Contract closed with Production evidence. |
| TASK-012 | CLOSED / GO | `TASK-012 — ATOMIC TRANSACTION CONTRACT PASS`. |
| TASK-013 | CLOSED / GO | `TASK-013/014 — PRODUCTION IMPLEMENTATION PASS`; target design was not accepted as a substitute for Production. |
| TASK-014 | CLOSED / GO | Production implementation pass. |
| TASK-015 | CLOSED / GO | `TASK-015 — STOCK ENGINE TESTS PASS`. |
| TASK-016 | CLOSED / GO | `TASK-016 — STOCK ENGINE GATE PASS`. |
| TASK-017 | CLOSED / GO | Closed before TASK-018. |
| TASK-018 | CLOSED / GO | `TASK-018 — SEND VOUCHER PASS`. |
| TASK-019 | CLOSED / GO | `TASK-019 — RECEIVE VOUCHER PASS`. Production schema mismatch was corrected during the path; the final task pass was explicit. |
| TASK-020 | CLOSED / GO | `TASK-020 — PARTIAL RECEIVE PASS`. |
| TASK-021 | CLOSED / GO | `TASK-021 — COMPLETE PASS`. |
| TASK-022 | CLOSED / GO | `TASK-022 — CANCEL PASS`. |
| TASK-023 | CLOSED / GO | `TASK-023 — VOUCHER INTEGRATION PASS`. |
| TASK-024 | CLOSED / GO | `TASK-024 — VOUCHER GATE PASS`. |
| TASK-025 | CLOSED / GO | Original/Owner/Gold reconciliation closed after explicit Owner decisions for DirectReturn, SupplierReturn and DirectSale. |
| TASK-026 | CLOSED / GO | Source implementation and VAN custody baseline completed; candidate remained quarantined until Runtime Gate. |
| TASK-027 | CLOSED / GO | `TASK-027 — VOUCHER E2E PASS`; permanent Production RPC fixes retained, test data rolled back. |

## Owner business decisions recorded during TASK-025/026

### Vehicle vs Representative
- Vehicle is the mobile inventory container / mobile branch.
- Representative is the custody and financial-responsibility holder.
- Vehicle identity is independent from Representative identity.
- A Representative can move to another vehicle.
- A vehicle reassignment must use strict inventory/custody procedures; custody is not emptied automatically.

### DirectSale
`DirectSale` means **stock issue to the direct-sales vehicle / representative custody**. It is not a final warehouse sale.

Expected stock topology:
`MAIN -> VAN(vehicle)`

### DirectReturn
`DirectReturn` means:
`Vehicle -> MAIN`

Owner decision: source-side responsibility belongs to the vehicle custody, while the representative remains the accountable custodian.

### SupplierReturn
`SupplierReturn` means:
`MAIN/Branch -> Supplier`

## Production vehicle baseline
- Vehicle table exists: `public.vehicles`.
- No new vehicle table is required.
- Official experimental vehicle retained:
  - `vehicle_id = 70e5d809-0505-4e60-b317-feff6e799127`
  - `vehicle_code = VEH-92yrzb`
  - license plate = `أ ب ج 1234`
  - status = `Active`
- Other duplicate experimental vehicles were removed after a reference-safety gate; only the official test vehicle remains.

## Mobile branch baseline
- Mobile branch created and active:
  - `branch_id = dbdef0b7-0909-4f71-a367-30c61d021286`
  - `branch_code = VAN-VEH-92yrzb`
  - name = `سيارة VEH-92yrzb`
- Do not create VAN identities from representative email.

## Demo representative baseline
- `van-sales@rawaea.com`
- user id `a86726d9-d687-4113-a9e2-5f90f4bdb4fa`
- role `مندوب بيع مباشر`
- status `Active`
- No FK references were found for the two historical demo representatives before reuse.
- The first demo representative was moved into the active Production company and bound to `VEH-92yrzb` via `vehicles.driver_id`.

## VAN stock initialization
Production already contained the official RPC:
`public.setup_van_stock(uuid)`

The RPC initially had a defect because it attempted to insert a value into generated column `available_qty`. This was corrected permanently so the database computes `available_qty` from `qty` and `allocated_qty`.

Production verification:
`MISSING_FROM_VAN = 0`

## Permanent Production fixes made during TASK-027

### `post_stock_movement`
DirectSale was originally treated as a source-only deduction. The permanent correction made `DirectSale` a two-sided movement:
- source decreases;
- target increases;
- one inventory movement log is written;
- source/target rows are locked atomically.

### `send_manual_stock_voucher_v2`
The permanent correction passes `voucher.to_id` as the target branch for `DirectSale` and `Transfer`.

## TASK-027 proof
A direct central-engine test passed:
`TASK-027 — CENTRAL DIRECTSALE ENGINE PASS`

Then the complete voucher path passed:
`TASK-027 — VOUCHER E2E PASS`

The E2E proof covered:
`CREATE -> DirectSale -> Send -> MAIN -1 -> VAN +1 -> inventory_log -> Sent -> Complete -> Completed`

Test data was rolled back; permanent RPC changes were not rolled back.

## Critical lesson from failed attempts
Do not confuse a successful `CREATE OR REPLACE FUNCTION` inside a transaction with a permanent Production fix. If the transaction later fails, the function replacement is rolled back too. Permanent fixes must be committed independently from test-data rollback.

## Next active phase
`STAGE-28 — Loading / Unloading Core`

Future CTO must not repeat the closed gates above. Start from this ledger, then read:
1. `CTO/00_MASTER_CONTEXT.md`
2. `CTO/01_SOURCE_AUTHORITY_MAP.md`
3. `Governance/RAWAEA_ARCHITECTURE_CONSTITUTION.md`
4. `Governance/EXECUTION_PROTOCOL.md`
5. this file

## Source migration policy
`rawaie-erp-New` is now the sole active CTO source. `rawaie-erp-review` remains a historical/reference repository only.
