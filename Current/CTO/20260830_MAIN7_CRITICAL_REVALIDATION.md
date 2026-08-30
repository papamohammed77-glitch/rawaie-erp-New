# MAIN7 CRITICAL REVALIDATION — 2026-08-30

EVENT ID: MAIN7-REVALIDATION-20260830-02
DATE: 2026-08-30
SOURCE: Current Production Supabase + Current Git + direct historical source inspection
OBJECTIVE: Revalidate the complete MAIN7 state after subsequent Production/Git changes and determine whether any previously open MAIN7 source defect remains.

## PRE-SWEEP SELF-AUDIT

Business Understanding:
MAIN7 is the Warehouse Operations UI/orchestration fragment. It reads tenant-scoped operational state, presents warehouse workflows, and invokes capability Edge Functions. Physical stock mutation does not belong in MAIN7.

Architecture Understanding:
The current target contract remains:
UI/orchestrator -> authenticated Edge capability -> canonical PostgreSQL capability/RPC -> canonical stock/accounting engines.
Physical stock movement remains `post_stock_movement` -> `stock_branches` + `inventory_log`.
`reserve_stock` / `release_stock_reservation` are reservation operations on `allocated_qty`, not independent physical movement engines.

Database Understanding:
Current Production `order_details` has no `company_id` column. Tenant ownership of order details is established through the parent `orders.company_id` and `order_details.order_id` relation. `items.item_code` has a formal global UNIQUE constraint. `stock_branches` is identified by `(branch_id,item_id)` and is tenant-scoped through `branches.company_id`.

Historical Understanding:
The governing Engineering Governance Principle and the historical MAIN7 reports 89..102 were reviewed as context only. Historical claims were not treated as current truth.

Current Git Understanding:
`Current/PWA/main/main7.md` was fetched from the current `main` branch and inspected in complete source chunks through its end. Current blob SHA remains `a5ae5139c734217d70d6a0e4363da64285fff4d9`.

Current Production Understanding:
Current Production was queried directly on 2026-08-30 after later changes. Current counts are: companies=1, users=24, branches=2, items=17, stock_branches=20, inventory_log=3, orders=0, order_details=0, runsheets=0, run_sheet_details=0, stock_vouchers=0, stock_voucher_details=0, receiving=0, receiving_details=0, erp_operation_registry=0, audit_log=1866.

Deployment Understanding:
MAIN7 is a source fragment and is not itself the final deployed PWA artifact. The deployed capability layer is tracked independently through Supabase Edge Function versions.

Runtime Understanding:
Production PostgreSQL/RPC definitions and current Edge Function source were inspected directly. A live positive browser transaction for Delivery cannot be truthfully claimed because there is currently no eligible runsheet-backed order in Production and no browser/E2E runtime is available in this execution surface.

Confirmed Facts:
- MAIN7 current source does not contain `order_details.company_id`.
- MAIN7 Delivery already scopes `orders` by `company_id` + `runsheet_id` and then reads `order_details` by `order_id`.
- MAIN7 has no direct `stock_branches` quantity mutation and no direct `inventory_log` insert.
- Current Production physical stock movement is centralized in `post_stock_movement`.
- `reserve_stock` / `release_stock_reservation` update `allocated_qty` only.
- `complete_runsheet_picking`, `complete_runsheet_loading`, `complete_order_delivery_atomic`, `complete_return_atomic`, and `complete_runsheet_unloading` preserve their current separation of responsibilities and tenant checks.
- Current Production inventory integrity is clean: negative_qty=0, negative_allocated=0, available_mismatch=0, cross_company_stock_item=0, cross_company_inventory_item=0.
- Current `create-stock-voucher` v9 is operation-aware and dispatches to the 12-argument manual voucher RPC path when an operation id is supplied.
- Current `receive-purchase` v12 and current Production `receive_purchase_atomic` both use explicit operation identity and the canonical stock movement engine.

Unknowns:
- Browser E2E of the final assembled PWA.
- Positive Delivery transaction runtime against a legitimate live runsheet-backed order.

Conflicts:
- Historical MAIN7 records describe older states in which the Delivery predicate and create-stock-voucher dependency were open. Current Git and current Production have since closed both source/deployment states.

Unverified Claims:
- Full assembled PWA browser runtime PASS.
- Global application-wide Zero-Debt across every separate application.

Production Opened: YES
Current Git Opened: YES
Historical Opened: YES
Schema Checked: YES
Triggers Checked: YES
RLS Checked: YES
Permissions Checked: YES
Consumers Checked: YES
Dependencies Checked: YES
Git History Checked: YES

## FINDINGS

### FINDING-01 — MAIN7 Delivery company predicate
Status: CLOSED

Current source uses the correct relational path: company-scoped `orders` -> `order_details.order_id`. The previously reported invalid `order_details.company_id` predicate is not present in the current main7 source.

Evidence:
- Current MAIN7 full source inspected through end of file.
- Current Production schema has no `order_details.company_id`.
- Historical closure commit removed the invalid predicate and later commits only documented closure.

Decision:
No additional code change is justified. Re-applying the same fix would create a meaningless/no-op commit and violate surgical-change discipline.

### FINDING-02 — CREATE-STOCK-VOUCHER dependency
Status: CLOSED

Current Production Edge `create-stock-voucher` is v9, authenticates the current user, derives company context from `users.auth_id`, accepts `operation_id` / `Idempotency-Key`, and dispatches to the operation-aware `create_manual_stock_voucher_atomic` overload. The core validates company-scoped branch/vehicle/supplier relationships and uses the globally unique item code contract.

Decision:
No further MAIN7 change required. Current MAIN7 already supplies an operation id when creating the voucher.

### FINDING-03 — Physical writer discovery
Status: VERIFIED

Current Production function inspection found:
- `post_stock_movement`: actual Physical Stock mutation writer and `inventory_log` writer.
- `reserve_stock`: allocated_qty reservation only.
- `release_stock_reservation`: allocated_qty release only.
- `create_vehicle_atomic`: initializes zero-quantity stock rows for a newly created mobile branch; it does not perform a physical movement.
- `setup_van_stock`: initializes missing zero-quantity stock rows; it does not perform a physical movement.
- `post_inventory_adjustment_atomic`: delegates physical adjustment to `post_stock_movement`.
- `complete_runsheet_picking`: reservation only; no physical movement.
- `complete_runsheet_loading`: delegates movement to `post_stock_movement`.
- `complete_runsheet_unloading`: delegates movement to `post_stock_movement`.
- `complete_return_atomic`: delegates SalesReturn movement to `post_stock_movement`.

Conclusion:
No second active Physical Stock movement engine was identified in the current Production function set.

### FINDING-04 — RECEIVE PURCHASE state
Status: VERIFIED CURRENT

The current Production `receive_purchase_atomic` requires an explicit operation UUID and checks `receiving.operation_id` before any movement. A matching existing operation returns duplicate behavior, while a conflicting payload is rejected. New movement uses a deterministic inventory idempotency key built from operation identity and item identity. Current Edge v12 supplies that operation id, deriving one deterministically when the caller does not provide it.

Conclusion:
The earlier receive-purchase idempotency concern is superseded by the current deployed state and is not an open MAIN7 blocker.

### FINDING-05 — Separate application review
Status: PARTIAL / SEPARATE DEBT

`Current/PWA/vouchers.html` is currently tenant-aware at login/reference loading and does not show a direct Physical Stock writer in the inspected source path; it uses capability functions for voucher actions.

`Current/PWA/driver.html` still contains hard-coded company UUID values in its self-registration fallback and in credit/complaint event inserts. This is a genuine tenant-isolation defect in the separate Delivery app and is NOT part of MAIN7's fragment contract. It should be handled as a separate full-file closure after its complete source/history/consumer contract is reconstructed.

Decision:
Do not mix this separate-app repair into MAIN7. Do not claim global PWA Zero-Debt until it is closed.

### FINDING-06 — RLS broad policies
Status: OPEN / HISTORICALLY ACKNOWLEDGED

Current Production still contains broad public `ALL` policies on `orders`, `order_details`, `receiving`, and `receiving_details`. Historical MAIN2 analysis already identified this as independent security debt and deliberately deferred changing it without a dedicated historical/Online-Store contract review.

Decision:
No RLS change in MAIN7. This is a separate security closure unit and must not be silently bundled into a Warehouse fragment repair.

## WHAT I PROVED

1. The previously open MAIN7 `order_details.company_id` defect is already removed from current Git.
2. The current main7 file has remained unchanged since the surgical delivery fix; later commits are documentation-only.
3. Current Production inventory is clean at the latest direct snapshot.
4. No active second Physical Stock movement engine was found in the current Production function set.
5. Current create-stock-voucher and receive-purchase paths are aligned to operation-aware/canonical capabilities.
6. MAIN7 remains an orchestration fragment rather than a stock writer.
7. Repeating the historical `order_details` fix now would be a false/no-op change.

## WHAT I DID NOT PROVE

1. Browser E2E of the fully assembled PWA.
2. A positive live Delivery transaction.
3. Global application-wide Zero-Debt across all separate applications and all historical generations.
4. Resolution of the separate `driver.html` tenant hard-coding defect.
5. Resolution of the broad RLS security debt.

## WHAT I CHANGED

- No MAIN7 source code change.
- Added this current forensic revalidation record so the current truth is preserved explicitly.

## WHAT I DID NOT CHANGE

- `Current/PWA/main/main7.md`.
- Production stock data.
- Production schema.
- Production Edge implementations.
- RLS policies.
- Separate applications.

## WHAT I DISCOVERED

- Current Production is materially newer than several historical snapshots; it is now a one-company clean dataset for the verified inventory invariants.
- The historical `main7` Delivery defect is already closed in current Git.
- The historical create-stock-voucher blocker is also closed in current Production.
- Separate-app tenant drift still exists in `driver.html` and must not be confused with the closed MAIN7 issue.

## WHAT I INITIALLY MISSED

The historical reports were temporally correct for the states they described, but they were not the current state. The correct response to the user's request is therefore revalidation against the current branch/Production, not repeating already-applied source edits.

## WHAT BECAME OBSOLETE

- The statement that MAIN7 currently contains `order_details.company_id`.
- The statement that create-stock-voucher is currently a direct Physical Stock writer.
- Historical multi-company inventory contamination counts that no longer match the current Production baseline.

## WHAT REMAINS OPEN

- Final assembly of main7 into the final integrated PWA remains a release/integration task.
- Authenticated browser E2E of the assembled PWA remains unproven in this execution surface.
- `driver.html` tenant isolation defect remains separate and open.
- Broad RLS policy hardening remains separate and open.
- Global Inventory/PWA Zero-Debt remains open outside MAIN7.

## WHAT COULD STILL BE WRONG

- Manual assembly may reintroduce stale predicates or omit a fragment.
- A separate app/Edge consumer may still carry contract drift not represented inside main7.
- Browser-only behavior may differ from source/RPC verification.

## FINAL FLAGS

PRODUCTION DEPLOYED?: NO — no Production change was required for MAIN7 because the requested defect was already fixed.
PRODUCTION RUNTIME VERIFIED?: PARTIAL — current PostgreSQL/RPC/Edge contracts were directly verified; browser E2E is not claimed.
AUDIT VERIFIED?: YES for the reviewed inventory/voucher audit path; no test pollution was left in Production.
DATA VERIFIED?: YES — latest direct snapshot is internally consistent for the verified inventory invariants.
CURRENT GIT ALIGNED?: YES — current main7 contains the already-applied fix and later commits did not alter its source.

## FINAL CLOSURE STATUS

MAIN7 DELIVERY SOURCE CLOSURE: 100% CLOSED
MAIN7 CURRENT-GIT REVALIDATION: CLOSED
MAIN7 PRODUCTION CONTRACT ALIGNMENT: VERIFIED
MAIN7 ASSEMBLED BROWSER RUNTIME: OPEN / UNPROVEN
GLOBAL INVENTORY/PWA ZERO-DEBT: NOT CLOSED

Governance conclusion:
No unnecessary code change was made.
No speculative schema or data correction was made.
The historically open MAIN7 defect was verified as already corrected.
A separate real tenant-isolation defect in `driver.html` was discovered and intentionally kept as a separate closure unit.
