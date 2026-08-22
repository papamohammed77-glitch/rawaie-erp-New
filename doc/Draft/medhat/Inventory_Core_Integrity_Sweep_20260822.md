# GLOBAL INVENTORY CORE INTEGRITY SWEEP — 2026-08-22

## Governing Contract

This record is executed under the governing-principles report and the direct-completion command for the current phase: **GLOBAL INVENTORY CORE INTEGRITY SWEEP**.

The governing contract used for closure is:

- Physical stock movement has exactly one physical writer: `public.post_stock_movement`.
- `public.reserve_stock` and `public.release_stock_reservation` may change `allocated_qty` only; they are not physical stock movements.
- Tenant context must be explicit and company-scoped.
- Item identity follows the current production schema. `items.item_code` is globally unique; stock scope is branch/company context.
- Workflow-state functions must not be treated as physical stock writers.
- Production evidence supersedes stale reports or theoretical counts.
- A closure is not accepted from code inspection alone when a transactional production verification can be performed safely.

## Production Source

Supabase project: `fiilmooggumokxanwiyx`

Database: PostgreSQL 17.6.1.121

Project status at verification: `ACTIVE_HEALTHY`

## Current Production Integrity Snapshot

The final snapshot was recomputed directly from Production immediately before closure documentation.

| Check | Result |
|---|---:|
| `stock_branches` rows | 26 |
| `inventory_log` rows | 3 |
| negative physical stock | 0 |
| allocated > physical | 0 |
| duplicate `(branch_id,item_id)` stock keys | 0 |
| stock/item cross-company mismatch | 0 |
| inventory-log/item cross-company mismatch | 0 |
| missing inventory-log item references | 0 |
| order-detail/item cross-company mismatch | 0 |
| run-sheet-detail/item cross-company mismatch | 0 |

No destructive data correction was performed because the current Production data already satisfies these integrity checks. Changing clean data without a proven defect would violate the governing no-guessing rule.

## Global Physical Writer Discovery

A production-wide scan of `public` PL/pgSQL function definitions for direct writes to `stock_branches` and `inventory_log` found:

1. `public.post_stock_movement` — the canonical physical stock writer.
2. `public.reserve_stock` — reservation-only writer of `allocated_qty`.
3. `public.release_stock_reservation` — reservation-only writer of `allocated_qty`.

No triggers exist on `stock_branches` or `inventory_log` that independently create physical stock movements.

Therefore the physical-write contract is structurally closed at the database layer.

## Required Writer Matrix

### `send_stock_voucher_atomic`
- Production signature verified.
- Calls `post_stock_movement`.
- Company-scoped voucher lookup.
- Inventory-log idempotency path present.
- Status: **PRODUCTION DEPLOYED / DB CONTRACT VERIFIED**.

### `receive_purchase_atomic`
- Production signature verified: `(uuid,text,text,jsonb,uuid)`.
- Requires `p_operation_id`.
- Calls `post_stock_movement('PurchaseIn',...)`.
- Uses company-scoped PO and branch context.
- Item identity validated through the production item master contract.
- Status: **PRODUCTION RUNTIME VERIFIED**.

#### Transactional Runtime Verification
A temporary PO and PO detail were created inside one transaction, received through the actual Production RPC, and the same operation was immediately retried with the same operation UUID. The first call performed the movement; the second returned `duplicate=true`; the inventory log contained one movement. The entire fixture was rolled back.

No permanent test data remained in Production.

### `post_inventory_adjustment_atomic`
- Validates company/branch context.
- Validates item identity.
- Reads stock state for calculation but does not directly own the physical write.
- Delegates the physical movement to `post_stock_movement`.
- Status: **PRODUCTION DEPLOYED / DB CONTRACT VERIFIED**.

### `save_sales_invoice_atomic`
- Production definition verified.
- Calls `post_stock_movement` for physical sale movement.
- No direct `stock_branches` or `inventory_log` writer found.
- Status: **PRODUCTION DEPLOYED / DB CONTRACT VERIFIED**.

### `complete_return_atomic`
- Production definition verified.
- Uses `erp_operation_registry` for idempotency.
- Good returns call `post_stock_movement('SalesReturn',...)`.
- Damaged/missing returns are workflow/liability paths and do not fabricate good stock.
- Status: **PRODUCTION DEPLOYED / DB CONTRACT VERIFIED**.

### `complete_order_delivery_atomic`
- Production definition verified.
- Does not call `post_stock_movement` and does not modify physical stock.
- Updates delivery workflow state and derived `run_sheet_details` fields only.
- This is intentionally classified as **workflow state**, not a physical stock movement.
- Status: **PRODUCTION DEPLOYED / WORKFLOW CONTRACT VERIFIED**.

### `post_manual_stock_voucher_atomic`
- Production definition verified.
- Delegates physical movement to `post_stock_movement`.
- Uses inventory-log/idempotency state without becoming a second physical writer.
- Status: **PRODUCTION DEPLOYED / DB CONTRACT VERIFIED**.

### `complete_runsheet_picking`
- Current Production overloads were inspected.
- No physical-stock writer or inventory-log writer was found in these functions.
- This function is reservation/workflow related rather than a physical movement writer.
- Status: **WORKFLOW/RESERVATION CONTRACT VERIFIED**.

## Surgical Production Changes

### `20260819014000_close_manual_voucher_create_tenant_and_item_identity`
Production migration applied to harden manual voucher creation:

- derives company context from the authenticated user path;
- validates branch/vehicle/supplier ownership against the supplied company;
- resolves item identity using the globally unique `item_code` contract rather than a false company-local item-code assumption;
- preserves the existing manual-voucher lifecycle rather than introducing a parallel movement engine.

Transactional Production verification succeeded and was rolled back.

### `20260819021000_order_receive_purchase_idempotency_before_quantity_guard`
Production receive-purchase path was hardened so operation identity is resolved before quantity-state rejection on a retry. The current Production function requires an explicit operation UUID and returns a duplicate result for a previously completed identical operation.

The deployed `receive-purchase` Edge Function is compatible with this contract and already provides an operation UUID when the client does not supply one.

## Current Deployed Runtime Evidence

Relevant active Edge versions observed in Production:

- `create-stock-voucher` v8
- `send-stock-voucher` v19
- `receive-stock-voucher` v21
- `complete-return` v24
- `complete-order-delivery` v13
- `receive-purchase` v12
- `save-sales-invoice` v15

The deployed `create-stock-voucher` source in `Current/Edge_Functions/create-stock-voucher` authenticates the caller, derives `company_id` from `users.auth_id`, and invokes `create_manual_stock_voucher_atomic` rather than writing stock directly.

## Owner Authorization Contract

The Production owner contract remains:

`isOwner = true` + `permissions = ["*"]` + valid `owner_profile` + active license.

The owner wildcard and owner profile linkage were verified separately during the same continuity work and are preserved.

## Audit Trail

Production `audit_log` only accepts the existing action vocabulary (`create`, `update`, `delete`, `login`, `logout`, `failed_login`). Therefore the closure was recorded using the existing legal actions rather than inventing a new action type.

Recorded entries:

- `cecf0ce4-9e6f-49b5-b3da-1e263fdf2068` — `create` — `inventory_integrity_sweep` — `20260822-GLOBAL-INVENTORY-CORE`.
- `1c84fb32-1ed5-4868-a091-264c8952bd29` — `update` — `create_manual_stock_voucher_atomic` — migration closure record.
- `9b0ee6f8-38d8-43cd-b7c4-0c4b9a37709a` — `update` — `receive_purchase_atomic` — migration closure record.

## Data Repair Decision

No permanent data rewrite was executed during this sweep because the latest Production snapshot was already clean across the tested integrity invariants. The correct engineering action was therefore to preserve the data and harden the write paths, not to manufacture a cleanup operation.

## Closure Statement

The **GLOBAL INVENTORY CORE INTEGRITY SWEEP** is structurally closed in Production:

- one physical-stock writer is proven;
- reservation writers are isolated to `allocated_qty`;
- required inventory functions delegate correctly;
- current Production stock data passes integrity checks;
- manual voucher creation and purchase receiving have transactional runtime verification;
- the current owner wildcard contract is preserved;
- durable audit records exist.

Functions that were not safely executable against live business records without fabricating operational history are explicitly classified by contract verification rather than falsely marked as runtime-tested.

Any future CTO must treat this document plus the current Production schema/function definitions as the evidence baseline and must re-synchronize Production before issuing a new metric or closure percentage.
