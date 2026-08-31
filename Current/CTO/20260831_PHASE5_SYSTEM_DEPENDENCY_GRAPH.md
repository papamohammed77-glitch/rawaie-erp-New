# RAWAEA ERP — PHASE 5 SYSTEM DEPENDENCY GRAPH

**Date:** 2026-08-31  
**Phase:** 5 — System Dependency / Runtime Graph  
**Status:** CLOSED  
**Production mutation:** None.

## GRAPH OVERVIEW

The current system is best understood as a layered dependency graph:

`PWA Shell / Specialized PWAs`
→ `Edge Function orchestration`
→ `Database atomic business functions`
→ `PostgreSQL tables + constraints + triggers + RLS`
→ `Audit / operational / financial ledgers`

External deployment surfaces include GitHub and Cloudflare, while Supabase provides Auth, Storage, Edge Functions, and PostgreSQL.

## BUSINESS PROCESS GRAPH

### Sales

`POS / Van Sales / Telesales / Order Taker / Store`
→ `save-sales-invoice`
→ `save_sales_invoice_atomic`
→ `orders + order_details`
→ when immediately invoiced: `post_stock_movement(POSSale|VanSale)`
→ financial writers (`post_journal_entry`, cash receipt, customer ledger, driver ledger where applicable).

Current `save-sales-invoice` source confirms authenticated caller handling, operation-id derivation, and delegation to `save_sales_invoice_atomic`. fileciteturn45file0L2-L2

### Picking / Loading

`runsheets + run_sheet_details`
→ `start-picking / complete-picking`
→ reservation state (`allocated_qty`)
→ `start-loading / complete-loading`
→ `complete_runsheet_loading`
→ `post_stock_movement(Loading)`
→ `stock_branches + inventory_log`
→ runsheet/order status transitions.

The current `complete-loading` wrapper resolves authenticated company context, validates the runsheet, then calls `complete_runsheet_loading`. fileciteturn46file0L2-L2

### Delivery / Return / Settlement

`runsheet`
→ delivery workflow
→ order quantities / collection state / customer ledger
→ return workflow
→ `stock movement SalesReturn/DirectReturn`
→ driver liability / daily settlement / financial closure.

The historical workflow document provides the intended state-machine and affected entities; current runtime implementation must still be traced end-to-end in later phases. fileciteturn40file0L2-L2

### Purchase Receiving

`purchase_orders + purchase_order_details`
→ `receive-purchase`
→ `receive_purchase_atomic`
→ `post_stock_movement(PurchaseIn)`
→ `receiving + receiving_details`
→ `post_journal_entry`
→ `post_supplier_ledger_entry`.

The current purchase wrapper and current Production RPC establish this chain. fileciteturn47file0L2-L2

### Stock Vouchers

`stock_vouchers + stock_voucher_details`
→ `send-stock-voucher`
→ `send_stock_voucher_atomic`
→ underlying stock-voucher core
→ physical movement / audit / financial side effects as defined by the core contract.

The current wrapper explicitly resolves the caller's company context and delegates to the atomic writer. fileciteturn48file0L2-L2

## DATABASE RELATIONAL GRAPH

Fresh Production FK evidence shows the core relationships:

### Identity / tenancy

`companies`
→ `users.company_id`
→ `branches.company_id`
→ `items.company_id`
→ `customers.company_id`
→ `suppliers.company_id`
→ `orders.company_id`
→ `runsheets.company_id`
→ `purchase_orders.company_id`
→ `stock_vouchers.company_id`
→ `inventory_log.company_id`
→ `journal_entries.company_id`
→ `treasury.company_id`
→ `daily_settlements.company_id`
→ `vehicles.company_id`.

`users.default_branch_id → branches.id`, `users.role_id → roles.id`, and `users.auth_id` is the authentication linkage field used by current critical Edge Function paths.

### Order fulfillment

`orders`
→ `order_details.order_id`
→ `run_sheet_details` via `item_id/runsheet_id` and business synchronization
→ `runsheets`
→ users through picker/loader/deliverer/return-handler/driver IDs
→ vehicles via `runsheets.vehicle_id`.

### Stock

`stock_branches.branch_id → branches.id`
`stock_branches.item_id → items.id`

`inventory_log.company_id → companies.id`
`inventory_log.item_id → items.id`

`stock_voucher_details.voucher_id → stock_vouchers.id`
`stock_voucher_details.item_id → items.id`
`stock_vouchers.from_branch_id/to_branch_id → branches.id`.

### Procurement

`purchase_orders.supplier_id → suppliers.id`
`purchase_orders.branch_id → branches.id`
`purchase_order_details.po_id → purchase_orders.id`
`purchase_order_details.item_id → items.id`.

### Accounting

`journal_entries.company_id → companies.id`
`journal_lines.entry_id → journal_entries.id`
`journal_lines.account_id → chart_of_accounts.id`
`journal_lines.cost_center_id → cost_centers.id`.

`customer_ledger.customer_id → customers.id`
`supplier_ledger.supplier_id → suppliers.id`.

### Delivery / settlement

`daily_settlements.runsheet_id → runsheets.id`
`daily_settlements.driver_id → users.id`
`daily_settlements.vehicle_id → vehicles.id`.

`vehicles.driver_id → users.id`
`vehicles.mobile_branch_id → branches.id`.

## CRITICAL FUNCTION GRAPH

The current Production source establishes the following canonical relations:

`save-sales-invoice`
→ `save_sales_invoice_atomic`
→ `post_stock_movement`
→ `post_journal_entry`
→ `post_cash_receipt_atomic` / `post_customer_ledger_entry` / `post_driver_ledger_entry`.

`receive-purchase`
→ `receive_purchase_atomic`
→ `post_stock_movement`
→ `post_journal_entry`
→ `post_supplier_ledger_entry`.

`complete-loading`
→ `complete_runsheet_loading`
→ `post_stock_movement`.

`send-stock-voucher`
→ `send_stock_voucher_atomic`
→ stock-voucher core.

This is the core transaction graph that must remain consistent across every interface.

## GRAPH RISK POINTS IDENTIFIED

1. **Operation boundary:** Some flows span multiple tables and multiple atomic writers; the complete transaction boundary must be verified per workflow.
2. **Tenant propagation:** `stock_branches` lacks a direct `company_id`, so tenant safety depends on branch/item relationships and writer validation.
3. **Ledger propagation:** customer/supplier/driver ledgers use domain-specific foreign keys and do not all carry direct `company_id`; scoping depends on relational context.
4. **Legacy endpoint residue:** repeated HTTP 410 calls indicate residual callers or stale routes that must be attributed before removal.
5. **Candidate UI delegation:** New-main deliberately delegates many domains to specialized PWAs; route/consumer verification is required before declaring the shell complete.

## CURRENT GRAPH BOUNDARY

The graph is structurally proven at the database relationship and critical-function level. It is **not yet** a complete runtime call graph for every PWA, Edge Function, RPC, trigger, scheduled job, or external consumer.

## EXIT GATE

`PHASE 5 CLOSED`

The core current business/dependency graph has been established from fresh Production FK data plus current Edge/RPC source. No destructive cleanup or deployment change was performed.
