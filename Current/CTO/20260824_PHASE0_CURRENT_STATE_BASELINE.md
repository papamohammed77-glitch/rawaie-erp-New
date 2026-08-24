# RAWAEA ERP — PHASE 0 CURRENT STATE BASELINE

Date: 2026-08-24
Production: SMART ERP (`fiilmooggumokxanwiyx`)
Repository: `rawaie-erp-New`
Baseline owner: Khalid — Governance / Evidence

## 1. Authority

`Current Production Reality > Current main > Current Evidence > Historical Sources > Reports`

This baseline is built from direct Production queries, deployed Edge inventory, applied migrations, current Git `main`, current branches/PRs, and Current/CTO evidence. Historical reports are navigation/evidence only.

## 2. Production timestamp

Direct PostgreSQL `clock_timestamp()` captured:

`2026-08-24T16:05:40.448271+00:00`

## 3. Current Production snapshot

| Item | Production |
|---|---:|
| PostgreSQL | 17.6 |
| Companies | 1 |
| Users | 24 |
| Branches | 2 |
| Items | 17 |
| Stock rows | 20 |
| Inventory log | 3 |
| Stock vouchers | 0 |
| Treasury | 1 |
| Chart of Accounts | 0 |
| Journal entries | 2 |
| Journal lines | 0 |
| Customer ledger | 0 |
| Supplier ledger | 0 |
| Driver ledger | 0 |
| Orders | 0 |
| Purchase Orders | 0 |
| Runsheets | 0 |
| Latest applied migration | `20260824151259` |

Current company:

`00000000-0000-0000-0000-000000000001` / `MAIN` / `الروائع` / active.

Current Treasury:

`0a9d9357-b5f3-4dfa-886f-7c73de4f274e` / `CASH-01` / `الخزينة الرئيسية` / company `00000000-0000-0000-0000-000000000001` / active / opening `10000` / current `10000`.

No COA rows currently exist.

## 4. Current Git truth

`main` HEAD:

`4a1adcee564f65f17abfa03624cd7673994e80cd`

Commit:

`Create برومبت 57`

Parent:

`819b8d1c0b72c29e640ed9ee1c7bc4b7a6f5b515`

The current Git branch is therefore later than the Phase 0 directive creation snapshot itself; the directive remains the governing gate, while this file records the execution-time current state.

## 5. Critical deployed Edge inventory

Direct Production inventory confirms, among others:

| Function | Production version | SHA / evidence | verify_jwt |
|---|---:|---|---|
| `save-sales-invoice` | 15 | `af972338...` | true |
| `receive-purchase` | 12 | `bcf5f3...` | true |
| `complete-return` | 24 | `4b2b23...` | true |
| `complete-order-delivery` | 13 | `386c044...` | true |
| `save-journal-entry` | 8 | `ae9799...` | true |
| `save-receipt-voucher` | 5 | `e79646...` | true |
| `save-payment-voucher` | 3 | `3f2ca4...` | true |
| `save-transfer-voucher` | 3 | `82ba065...` | true |
| `save-daily-settlement` | 3 | `882391...` | true |
| `update-driver-ledger` | 1 | `977033...` | true |
| `create-stock-voucher` | 8 | `892dcd...` | false |
| `send-stock-voucher` | 19 | `ec1b24...` | false |
| `receive-stock-voucher` | 21 | `b4fe30...` | false |
| `complete-stock-voucher` | 4 | `8cf684...` | true |
| `cancel-stock-voucher` | 4 | `b1b717...` | true |
| `create-runsheet` | 26 | `6db690...` | true |
| `start-picking` | 33 | `2ae505...` | false |
| `complete-picking` | 16 | `90bd824...` | false |
| `complete-loading` | 11 | `c0ca692...` | true |
| `unload-runsheet` | 6 | `343239...` | true |

Production also contains many historical/runtime canary, harness, recovery and E2E functions still marked ACTIVE. They are not assumed to be business consumers merely because they exist.

## 6. Current PostgreSQL core state

Critical financial cores currently exist in Production as SECURITY DEFINER:

- `post_journal_entry`
- `post_customer_ledger_entry`
- `post_supplier_ledger_entry`
- `post_driver_ledger_entry`
- `post_cash_receipt_atomic`
- `post_cash_payment_atomic`

Current execute privileges were directly verified as:

`service_role = true`

`anon = false`

`authenticated = false`

for all six financial cores.

Inventory core remains:

- `post_stock_movement` 10-argument form
- `reserve_stock`
- `release_stock_reservation`

and is not part of this Phase 0 modification track.

## 7. Current migration truth

Production applied migration head:

`20260824151259`

Recent financial migration sequence includes:

- `20260822032213_accounting_core_post_journal_entry_and_report_join`
- `20260822182631_create_atomic_cash_receipt_payment_cores_20260822_v2`
- `20260822182713_fix_atomic_cash_cores_registry_columns_20260822`
- `20260822182733_fix_post_journal_entry_schema_drift_20260822`
- `20260823175139_financial_reporting_tenant_scope_and_runtime_fix_20260823`
- `20260823175324_pos_financial_closure_core_v1`
- `20260823175400_pos_cash_treasury_lookup_fix`
- `20260823175432_pos_cash_treasury_lookup_fix_v2`
- `20260823175537_pos_credit_zero_cogs_fix`
- `20260823185253_retire_nonactive_companies_20260823_forensic_cleanup_v2`
- `20260824144317_create_driver_ledger_core_20260824`
- `20260824144329_converge_pos_driver_ledger_20260824`
- `20260824144437_create_supplier_ledger_core_20260824`
- `20260824144450_converge_purchase_receiving_finance_20260824`
- `20260824144609_converge_return_financial_writers_20260824_v3`
- `20260824145903_20260824_restrict_financial_core_execute_privileges_v2`
- `20260824151259_20260824_canonical_financial_writer_cores`

Git contains corresponding financial migration artifacts for the security and canonical-core work, but not every historical Production object has yet been proven byte-for-byte reproducible from a single current canonical migration/source.

## 8. Current branch / PR truth

Relevant branches currently visible include:

- `main`
- `heytham/20260824-financial-writer-convergence`
- `heytham/prompt53-pos-financial-closure`
- `heytham/prompt51-journal-v8-surgical-review`
- `cto-continuity-20260821`
- `recovery/cto-curated-baseline`
- `cto/curated-baseline-v1`
- `inventory-rescue-20260815`
- `inventory-rescue-receive-20260815`
- `task-028-loading-unloading-refactor`
- `gold-master-vouchers-20260820`
- `vouchers-gold-master-closure-20260820`
- other historical rescue/forensic branches.

PR #24:

`CLOSED / NOT MERGED / DRAFT`

Head: `heytham/20260824-financial-writer-convergence`

Therefore PR #24 is not current `main` truth.

Current `main` separately contains synchronization commits for verified Production `save-sales-invoice`, `receive-purchase`, `save-journal-entry`, and canonical financial-writer migration documentation.

## 9. Known Production / Git drift candidates

1. Some Production Edge functions are current while their exact deployed source lineage is not proven in this baseline as byte-for-byte Current/Git/deployed equality.
2. Production contains PostgreSQL overloads/legacy wrappers that are not equivalent to proof of active application use.
3. Production contains active historical runtime/canary/recovery Edge functions; their business relevance and retirement status are not all classified.
4. PR #24 is closed/unmerged and cannot be used as the current source of truth.
5. Production applied migration `20260824151259` is newer than the Phase 0 directive-creation Git point; migration-to-current-main parity is therefore a reconciliation item, not a closure assumption.

## 10. Security baseline — classification only, no change made

Production currently has a mixed RLS/policy model.

Correctly company-scoped examples include `chart_of_accounts`, `branches`, `customers`, `items`, `inventory_log`, `stock_vouchers`, `purchase_orders`, and `runsheets` policies.

At the same time, several financial and legacy tables still expose broad policies such as `ALL ... USING true`, including `cash_box`, `customer_ledger`, `daily_settlements`, `journal_entries`, `journal_lines`, `supplier_ledger`, and `treasury`.

This is recorded as security debt/drift only. Phase 0 forbids fixing it inside the baseline gate.

## 11. Current truth vs historical truth

The following historical statements must NOT be treated as current without fresh verification:

- pre-cleanup multi-company topology;
- old `da4...` financial-tenant ownership;
- historical `inventory_log`/voucher counts before cleanup;
- PR #24 as a current source;
- earlier claims that a given financial core did not exist;
- older claims about direct writers that were later converged.

The `EXACT 87 COA RECOVERY = OPEN` / `SOURCE EXHAUSTION = CLOSED` distinction remains active.

## 12. Phase 0 status

`PHASE 0 = OPEN`

Reason: Khalid baseline is now directly re-based, but independent Hytham technical baseline and final line-by-line reconciliation have not yet been completed. No functional work is authorized by this Phase 0 gate until that reconciliation closes.
