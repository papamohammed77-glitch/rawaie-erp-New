# PHASE 0 — HYTHAM EXECUTION ASSIGNMENT

## Role
Production Technical / Database / Runtime Inventory Owner.

## Mission
Do NOT refactor any writer. Build the technical half of the authoritative Phase 0 baseline from live Production.

## Required work

1. Query Production PostgreSQL directly and record a fresh UTC timestamp.
2. Inventory every public function:
   - function name
   - identity arguments
   - SECURITY DEFINER status
   - execute grants
   - whether it is a canonical Core, bridge, legacy capability, report, or unknown
3. Inventory physical/financial writer candidates by inspecting function definitions for:
   - `stock_branches` mutations
   - `inventory_log` inserts
   - `journal_entries` inserts/updates
   - `journal_lines` inserts
   - customer/supplier/driver ledger DML
   - treasury/cash DML
4. Inventory database triggers on relevant tables and retrieve trigger-function definitions where applicable.
5. Inventory RLS status and relevant policies for:
   - companies
   - users
   - branches
   - items
   - stock_branches
   - inventory_log
   - chart_of_accounts
   - treasury
   - journal_entries
   - journal_lines
   - customer_ledger
   - supplier_ledger
   - driver_ledger
   - stock_vouchers / details
6. Capture applied migration versions directly from Production.
7. Inventory all deployed Edge Functions with version, verify_jwt, and deployment hash.
8. Build a Production technical matrix for the critical paths:
   - Manual Voucher
   - Purchase Receiving
   - POS / Sales Invoice
   - Returns
   - Loading
   - Unloading
   - Picking / Reservation
   - Receipts
   - Payments
   - Daily Settlement
9. Compare live Production definitions with `rawaie-erp-New/main` source where the source exists.
10. Record all mismatches as `DRIFT`, never silently choosing one side.
11. Produce:
    - `Current/CTO/20260824_PHASE0_HYTHAM_TECHNICAL_BASELINE.md`

## Required matrices

### Function Inventory
| Function | Args | SECURITY DEFINER | Grants | Role | Writes | Production evidence |
|---|---|---|---|---|---|---|

### Edge Inventory
| Edge | Production version | verify_jwt | Hash | Current Git path | Git match | Status |
|---|---:|---|---|---|---|---|

### Writer Discovery
| Writer | Physical Stock | Journal | Customer Ledger | Supplier Ledger | Driver Ledger | Treasury | Canonical Core | Status |
|---|---:|---:|---:|---:|---:|---:|---|---|

### Trigger Inventory
| Table | Trigger | Timing | Function | Writes data? | Purpose | Status |
|---|---|---|---|---|---|---|

### RLS / Grant Security
| Object | RLS | Policies | EXECUTE grants | Client callable? | Evidence | Status |
|---|---|---|---|---|---|---|

## Restrictions

- No DDL.
- No DML.
- No deployment.
- No PWA changes.
- No Financial Writer refactor.
- No Inventory Core rewrite.
- No deletion of legacy functions.
- Do not call a legacy object a bug merely because it exists; identify whether it is reachable and who consumes it.
- Do not call a Core closed merely because a function exists.

## Completion condition

Every technical claim must have a direct Production query/result or a direct Git source reference.

Final status must be one of:

`VERIFIED`
`DRIFT`
`LEGACY / STILL REACHABLE`
`UNVERIFIED`
