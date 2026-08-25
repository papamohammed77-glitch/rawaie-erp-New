# RAWAEA ERP — Hytham Continuous Execution Event Log

Date: 2026-08-25
Role: Hytham
Authority: Production SMART ERP > Current main > Current CTO evidence > historical sources > reports

## Mission
Continue from Prompt 60 through the broader ERP plan without waiting for phase-specific prompts, while refusing false closure. Every material event is recorded here for memory transfer and future continuation.

## Current Production Baseline (latest direct query during execution)

- Company count: 1
- Company: `00000000-0000-0000-0000-000000000001`
- Branches: 2 (`BR-01`, `BR-2`)
- Items: 17
- Stock rows: 20
- Inventory log: 3
- Stock vouchers: 0
- Customers: 3
- Suppliers: 1
- Vehicles: 0
- Drivers by current role filter: 0
- Orders: 0
- Purchase Orders: 0
- Runsheets: 0
- Treasury: 1 (`CASH-01`)
- Treasury current balance: `10000.00`
- COA: 17

## Event 01 — Global Inventory Writer Discovery

Finding:
`post_stock_movement(...)` is the only Production function directly mutating Physical Stock and `inventory_log`.

Separate classifications:
- `reserve_stock` / `release_stock_reservation` = reservation state only.
- `setup_van_stock` = initialization only.

Trigger sweep found no parallel stock writer.

Decision:
`Physical Writers outside post_stock_movement = 0` at SQL function/trigger level.

Remaining gates:
HTTP runtime, Edge source/version parity, PWA consumer proof, two-session concurrency.

## Event 02 — Production Core Canary

Canary:
`PH2-CANARY-0001`

Movement:
InventoryIncrease quantity 1 against existing stock.

Result:
- first call accepted;
- second identical call returned duplicate;
- temporary inventory log count = 1;
- transaction rolled back.

Decision:
Central movement idempotency/rollback behavior verified at SQL level.

## Event 03 — Manual Voucher Closure

Transactional tests:
- Create Transfer Draft.
- SEND -> Sent.
- RECEIVE 1.0 -> Received.
- Repeat same operation_id -> duplicate.
- Partial RECEIVE 0.4 -> Sent.
- Final RECEIVE 0.6 -> Received.
- Complete -> Completed.

All test data rolled back.

Legacy function discovery:
`receive_manual_stock_voucher_v2` existed in Production but had no EXECUTE privilege for the inspected roles and no current Edge consumer.

Action:
Retired the function in Production.

Git migration:
`supabase/migrations/20260825210000_retire_receive_manual_stock_voucher_v2.sql`

## Event 04 — Inventory Adjustment Closure

Canary:
`PH2-ADJ-CANARY-20260825`

Result:
First adjustment succeeded; exact retry produced no second movement; transaction rolled back.

## Event 05 — Picking / Reservation Closure

Canary constructed with temporary Runsheet/Order/Order Detail.

Result:
- `complete_runsheet_picking` succeeded.
- `reserve_stock` was used.
- `inventory_log_written=false`.
- same operation_id returned duplicate=true.
- transaction rolled back.

Decision:
Picking is Reservation, not Physical Movement.

## Event 06 — Financial Security Boundary

Before change:
`anon` and `authenticated` had broad DML privileges on financial state tables.

Consumer check:
Current Accountant PWA reads financial tables and submits Receipt/Payment through Edge functions; no approved Current financial path was found that requires client direct DML.

Production change:
Revoke INSERT/UPDATE/DELETE/TRUNCATE/REFERENCES/TRIGGER from anon/authenticated on:
- journal_entries
- journal_lines
- customer_ledger
- supplier_ledger
- driver_ledger
- treasury
- cash_box
- daily_settlements

Preserve SELECT.

Git migration:
`supabase/migrations/20260825213000_financial_table_dml_boundary.sql`

Verification:
anon/authenticated = SELECT only on those tables.

## Event 07 — Purchase Receiving Defect Discovery

A real Production defect was discovered through a transactional canary.

Observed error:
`22P02 invalid input syntax for type uuid`

Root cause:
`post_journal_entry` returns `jsonb`, while `receive_purchase_atomic` attempted to assign the full JSONB result directly into a UUID variable `entry_id`.

Impact:
Purchase Receiving could perform earlier work inside the transaction and then fail when extracting the journal entry id.

Fix:
Changed only the result extraction to:
`(post_journal_entry(...)->>'entry_id')::uuid`

Production:
Fixed through migration.

Git:
`supabase/migrations/20260825214500_fix_receive_purchase_journal_result_cast.sql`

Self-audit correction:
The first Git migration artifact was mistakenly created as comments only. This was discovered by reviewing the artifact itself, then replaced with the full reproducible CREATE OR REPLACE FUNCTION body containing the surgical cast fix.

Validation after fix:
- Purchase Order test fixture created inside transaction.
- Purchase Receiving succeeded.
- PurchaseIn passed through `post_stock_movement`.
- Journal posting succeeded.
- Supplier ledger posting succeeded.
- Exact operation_id retry returned duplicate=true.
- Transaction rolled back.

## Event 08 — Cash Receipt Core

Canary:
operation_id `bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb`
amount 10
Treasury `CASH-01`
Cash account 121
Offset account 41

Result:
- Posted
- balanced 10/10 journal
- retry returned duplicate=true
- rollback completed

## Event 09 — Cash Payment Core

Canary:
operation_id `cccccccc-cccc-4ccc-8ccc-cccccccccccc`
amount 10
Treasury `CASH-01`
Cash account 121
Offset account 51

Result:
- Posted
- balanced 10/10 journal
- retry returned duplicate=true
- rollback completed

## Event 10 — Daily Settlement Core

Canary:
Temporary Delivered Runsheet
operation_id `eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee`

Result:
- settlement created
- shortage = 0
- no journal required
- exact retry returned duplicate=true
- rollback completed

Decision:
Daily Settlement Core local idempotency/transactional behavior verified.

## Event 11 — Historical VoidInvoice Forensics

Current Production `inventory_log` contains three historical rows with `movement_type='VoidInvoice'`, dated 2026-07-24, no idempotency key.

Historical source identified:
`Original/Edge Functions/delete-order.ts`

That source directly:
- updates `stock_branches`;
- writes `inventory_log`;
- writes journal_entries/journal_lines;
- writes customer_ledger;
- hard-deletes orders.

Classification:
HISTORICAL LEGACY EVIDENCE, not evidence of a current Current-path writer.

Action:
Do not delete the historical log rows. Preserve them as reconciliation evidence.

## Event 12 — Current Financial Direct-Writer Sweep

Production function definitions currently show direct financial DML only in canonical cores:
- `post_journal_entry`
- `post_customer_ledger_entry`
- `post_supplier_ledger_entry`
- `post_driver_ledger_entry`
- `post_cash_receipt_atomic`
- `post_cash_payment_atomic`

`save_sales_invoice_atomic`, `receive_purchase_atomic`, and `complete_return_atomic` no longer directly perform those financial table writes.

## Event 13 — Current Financial Edge Adapters

Current Git sources were opened for:
- `save-receipt-voucher` (canonical v6 source)
- `save-payment-voucher` (canonical v4 source)
- `save-daily-settlement` (canonical v4 source)
- `create-stock-voucher` (company-scoped capability wrapper)
- `receive-stock-voucher` (company-scoped partial/full receive wrapper)

Observed pattern:
- authenticate bearer token;
- resolve `public.users` via `auth_id`;
- derive company context;
- resolve required IDs or require them explicitly;
- delegate business posting to Production Core RPCs.

These adapters do not require client direct DML on the protected financial tables.

## Event 14 — Production Data Integrity Sweep

Current Production verification:
- `stock_branches.qty < 0` = 0
- `stock_branches.allocated_qty < 0` = 0
- `allocated_qty > qty` = 0
- orphan `inventory_log.item_id` = 0
- orphan `inventory_log.company_id` = 0
- duplicate non-null inventory idempotency keys = 0
- `erp_operation_registry` current rows = 0

Decision:
Current persisted state passes the checked integrity invariants.
Historical `VoidInvoice` logs remain retained evidence.

## Event 15 — Current COA Freshness Correction

During continuous execution, Production COA changed from the earlier 16-row snapshot to 17 rows.
The new current account is:
`216 — التزامات ضريبية`

Decision:
All current references now use the live Production 17-row dataset. No historical snapshot is allowed to override it.

## Event 16 — Phase Status Reclassification

Phase 2:
- Global writer discovery: SQL-level verified.
- Manual Voucher: transactionally verified; runtime/Edge proof remains open.
- Purchase Receiving: defect fixed; transactionally verified; runtime/Edge proof remains open.
- Adjustment: transactionally verified.
- Picking/Reservation: transactionally verified.
- POS/Van/Returns/Loading/Unloading: SQL bridge contract verified; runtime proof remains open due zero live operational data.

Phase 3:
- Journal/Core/Ledger direct-writer convergence: substantively verified.
- Cash Receipt: core canary verified.
- Cash Payment: core canary verified.
- Daily Settlement: core canary verified.
- Financial client DML boundary: fixed and verified.

## Event 17 — Runtime Canary Investigation

The repository contains a Production HTTP E2E/Concurrency canary workflow for Picking.
The current run on `main` (run `32889594729`, commit `6e9387944d5a9e7b574182b1a14e9641dff5f739`) did NOT execute the business test because its prerequisite temporary Production Canary endpoint returned HTTP `410` with `Temporary production canary retired`.

Decision:
- Do not count this run as HTTP E2E proof.
- Do not count it as an Inventory failure.
- Classify as `TEST_HARNESS_RETIRED`.

## Event 18 — Prompt 61 Forensic Re-baseline

Prompt 61 was read as a historical assessment, then re-tested against current Production rather than accepted as current truth.

Findings superseding stale report claims:

1. `save-transfer-voucher` is currently Production **v4**, not the v3 direct-writer described by the report. Its current source is authenticated, company-scoped through `public.users.auth_id`, requires `operation_id`, and delegates to `post_treasury_transfer_atomic`.

2. `update-driver-ledger` is currently Production **v2**, not the v1 direct-insert path described by the report. It authenticates the user, derives company context, supports operation/idempotency keys, and delegates to `post_driver_ledger_entry`.

3. Current PostgreSQL ACL verification shows the following SECURITY DEFINER functions are restricted to `service_role` plus owner `postgres` for the inspected signatures:
- `post_treasury_transfer_atomic`
- `post_daily_settlement_atomic`
- `post_driver_liability_entry`
- `post_driver_ledger_entry`
- `enforce_van_branch_company_context`
- `get_warehouse_team`
- `set_active_warehouse_role`

4. Current Security Advisor results now contain only:
- `erp_operation_registry` RLS enabled without policy (INFO)
- Leaked Password Protection disabled (WARN)
No `anon_security_definer_function_executable` or `authenticated_security_definer_function_executable` finding remains.

5. Current Treasury state is one active treasury only:
`CASH-01` / `0a9d9357-b5f3-4dfa-886f-7c73de4f274e` / balance `10000.00`.
Because there is only one active treasury, a real source→target transfer business transaction cannot be executed without creating a second treasury fixture. No such fixture was created.

6. `Current/PWA/accountant.html` still contains legacy Receipt/Payment consumer functions. They do not yet pass the current canonical Edge contract fields (`operationId`, explicit account UUIDs) and are therefore a genuine open Consumer Contract gap.

Decision:
Do not revert to the stale v3 transfer path. Treat Production v4/v2 as current truth. Continue with Accountant PWA surgical consumer correction and later authenticated HTTP E2E once an approved test harness is available.

## Event 19 — PWA Contract Decision

The currently published Accountant PWA does not require direct financial table DML and continues to call the canonical Receipt/Payment Edge functions, but its payload contract is stale.

Required surgical scope:
- `Current/PWA/accountant.html`
- `App.newReceipt`
- `App.newPayment`

The corrected consumer must:
- obtain the authenticated user through Supabase Auth;
- derive company only from `public.users.auth_id`;
- resolve the active treasury from the current company;
- resolve account UUIDs from `chart_of_accounts` under the current company and active state;
- generate an operation UUID;
- pass the canonical Edge payload;
- never use `user_metadata.company_id`;
- never hard-code an account UUID;
- never make an offset account a hidden default;
- never perform direct financial DML.

No PWA file was auto-modified in this event. The exact surgical replacement is to be reviewed/pasted into the published file under the established Current/PWA manual-review protocol.

## Event 20 — Git Lineage Verification

`Current/Edge_Functions/save-transfer-voucher/index.ts` is already present and matches the current Production v4 adapter.
`Current/Edge_Functions/update-driver-ledger/index.ts` is already present and matches current Production v2 adapter.

Decision:
No duplicate Git files or unnecessary redeployments were performed.

## Event 21 — Self-Audit

Prompt 61 itself was stale in at least the `save-transfer-voucher` and `update-driver-ledger` sections relative to live Production.
The earlier PWA proposal that defaulted offset accounts was rejected because it violated the no-guessing rule.
The current PWA correction therefore resolves account UUIDs dynamically under authoritative company context.

## Current Status

### Substantively closed at SQL/Core level
- Global physical-writer discovery.
- Reservation separation.
- Manual Voucher lifecycle and duplicate protection.
- Inventory Adjustment core canary.
- Picking/Reservation canary.
- Purchase Receiving after defect repair.
- Cash Receipt core canary.
- Cash Payment core canary.
- Daily Settlement core canary.
- Financial table direct-DML boundary for anon/authenticated.
- Current persisted-state integrity invariants checked.
- `save-transfer-voucher` current Production v4 canonical adapter.
- `update-driver-ledger` current Production v2 canonical adapter.

### Still open — cannot be truthfully upgraded without the required evidence
- Published Accountant PWA surgical consumer replacement.
- Authenticated HTTP E2E for every critical writer.
- Two genuinely independent concurrent HTTP sessions for critical writers.
- Exhaustive deployed Edge hash/version parity for every critical consumer.
- Full PWA consumer runtime verification.
- Real Vehicle/Driver/Order/Runsheet runtime proofs while current Production has zero vehicles, drivers, orders and runsheets.
- Full financial RLS policy refinement beyond the current DML boundary.
- End-to-end reconciliation under live business workload.
- Final Phase 2 Zero-Debt certification.
- Final Phase 3–7 certification.

## Hytham Self-Assessment

No completion claim is made beyond the evidence listed above.
Production was modified only where a real defect or security boundary was directly proven.
All temporary canaries used transactions and were rolled back.
No historical COA was recreated.
No Treasury mapping was guessed.
No PWA was auto-modified in this pass.
A real Production defect was discovered, corrected, retested, and made reproducible in Git.
A retired HTTP canary was explicitly prevented from being counted as runtime proof.
Prompt 61 stale claims were corrected against live Production rather than replayed mechanically.

## Next Execution State

Continue directly with:
1. Review/paste the exact surgical Accountant PWA replacement.
2. Verify the published Accountant PWA against the current Edge contract.
3. Continue consumer/Edge/PWA convergence.
4. Replace retired HTTP harness in an allowed location if an approved mechanism is available.
5. Complete runtime/concurrency and reconciliation gates.
6. Evaluate Phase 7 readiness only from accumulated evidence.

Do not reopen completed SQL/core closures unless new evidence contradicts them.
