# RAWAEA ERP — PHASE 5 SYSTEM DEPENDENCY GRAPH

**Date:** 2026-08-31  
**Phase:** 5 — System Dependency / Runtime Graph  
**Status:** PARTIAL / OPEN  
**Production mutation:** None.

## GOVERNANCE RECONCILIATION — 2026-08-31
The previous `CLOSED` label was too strong relative to the evidence boundary already documented in this file. The graph is structurally proven at the database/critical-function level, but a complete runtime consumer graph is not yet proven. Under the MASTER continuity command, `CLOSED` is not permitted while critical consumer/deployment unknowns remain.

Current fresh Production facts verified on 2026-08-31:
- Supabase project: `fiilmooggumokxanwiyx` / `SMART ERP`
- PostgreSQL 17.6.1.121
- Public tables: 66
- Public functions: 76
- Public triggers: 20
- Public RLS policies: 110
- Companies: 1
- Users: 24
- Branches: 2
- Items: 17
- Stock rows: 20
- Inventory log: 3
- Orders: 0
- Runsheets: 0
- Journal entries: 2
- Journal lines: 0
- Customer ledger: 0
- Supplier ledger: 0
- Driver ledger: 0
- Daily settlements: 0
- Treasury: 1

Current fresh security evidence:
- `orders` has broad authenticated ALL policy plus two broad INSERT policies for store/anon paths.
- `order_details` has broad authenticated ALL policy.
- `run_sheet_details` has broad authenticated ALL policy.
- `daily_settlements` has public ALL with `true/true`.
- Seven current `SECURITY DEFINER` functions are executable by `anon` and/or `authenticated`, including `create_vehicle_atomic`, vehicle context/guard helpers, `fn_vehicle_audit_trigger`, and `get_budget_vs_actual`.
- Auth leaked-password protection is disabled.

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

### Picking / Loading
`runsheets + run_sheet_details`
→ `start-picking / complete-picking`
→ reservation state (`allocated_qty`)
→ `start-loading / complete-loading`
→ `complete_runsheet_loading`
→ `post_stock_movement(Loading)`
→ `stock_branches + inventory_log`
→ runsheet/order status transitions.

### Delivery / Return / Settlement
`runsheet`
→ delivery workflow
→ order quantities / collection state / customer ledger
→ return workflow
→ `stock movement SalesReturn/DirectReturn`
→ driver liability / daily settlement / financial closure.

### Purchase Receiving
`purchase_orders + purchase_order_details`
→ `receive-purchase`
→ `receive_purchase_atomic`
→ `post_stock_movement(PurchaseIn)`
→ `receiving + receiving_details`
→ `post_journal_entry`
→ `post_supplier_ledger_entry`.

### Stock Vouchers
`stock_vouchers + stock_voucher_details`
→ `send-stock-voucher / receive-stock-voucher`
→ voucher atomic core(s)
→ physical movement / audit / financial side effects as defined by the core contract.

## DATABASE RELATIONAL GRAPH

Fresh Production FK evidence establishes the core relationships already listed in the prior revision:

### Identity / tenancy
`companies` → company-scoped operational records, with `users.auth_id → users.company_id` as the authoritative authenticated identity mapping.

### Order fulfillment
`orders` → `order_details` → `run_sheet_details` / `runsheets` → assigned operational users and `vehicles`.

### Stock
`stock_branches.branch_id → branches.id` and `stock_branches.item_id → items.id`; `inventory_log` is company/item linked; voucher details link to voucher and item; voucher branch endpoints link to branches.

### Procurement
`purchase_orders` link to supplier/branch; details link to purchase order/item.

### Accounting
`journal_entries` → `journal_lines` → `chart_of_accounts` / `cost_centers`; customer/supplier ledgers remain domain-linked.

### Delivery / settlement
`daily_settlements` link to runsheet, driver and vehicle; vehicles link to driver and mobile branch.

## CRITICAL FUNCTION GRAPH

Current proven examples:

`save-sales-invoice`
→ `save_sales_invoice_atomic`
→ `post_stock_movement`
→ accounting/cash/ledger writers as applicable.

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
→ voucher core → physical movement for applicable operations.

## CURRENT SECURITY / AUTHORIZATION GRAPH — OPEN

The following are proven as Production facts but not yet reconciled into a least-privilege consumer contract:

1. `orders` broad authenticated mutation policy and broad store/anon INSERT paths.
2. `order_details` broad authenticated mutation policy.
3. `run_sheet_details` broad authenticated mutation policy.
4. `daily_settlements` public ALL policy with `true/true`.
5. Seven externally executable `SECURITY DEFINER` functions observed by current Security Advisor/privilege inspection.
6. Auth leaked-password protection disabled.

These are not yet patched because the complete consumer/authorization contract has not been proven.

## CURRENT CONSUMER GRAPH — PARTIAL

Representative verified consumer boundaries:
- `vouchers.html` ↔ stock voucher Edge paths.
- `van-sales.html` ↔ sales invoice / vehicle-stock paths.
- picker/loader/unloader/returns PWAs ↔ runsheet fulfillment Edge/Core paths.
- purchasing PWAs ↔ purchase order / receive paths.
- New-main delegates specialized operations rather than implementing duplicate stock/financial writers.

Current status remains `PARTIAL` because a full `CONSUMER → CAPABILITY → EDGE → RPC → TABLE` inventory has not been exhaustively established for every PWA, Edge function, RPC, trigger and external route.

## DEPLOYMENT LINEAGE — PARTIAL

For critical inspected functions, Production versions and deployed behavior are known. However, the complete chain
`Git SHA → source file → package/deployment artifact → Production version → runtime consumer → runtime evidence`
is not exhaustively proven for every critical capability.

Active dated E2E/canary/recovery/harness Edge Functions are not treated as production consumers merely because they are deployed.

## GRAPH RISK POINTS
1. Transaction boundary across multi-writer workflows.
2. Tenant propagation where child tables lack direct company_id.
3. Ledger scoping through relational context.
4. Residual retired/stale HTTP routes.
5. New-main delegation and runtime route verification.
6. Security/grant exposure before consumer proof.
7. Deployment drift between Git and Production.

## CURRENT GRAPH BOUNDARY

`STRUCTURAL GRAPH = VERIFIED`
`CRITICAL FUNCTION GRAPH = VERIFIED FOR INSPECTED PATHS`
`CONSUMER GRAPH = PARTIAL`
`DEPLOYMENT LINEAGE = PARTIAL`
`RUNTIME CALL GRAPH = OPEN`
`AUTHORIZATION GRAPH = OPEN`

## EXIT GATE

Phase 5 is **NOT globally closed**.

Closure requires:
- exhaustive consumer graph,
- critical deployment lineage,
- runtime verification of required paths,
- authorization contract proof,
- no unresolved critical conflicts/unknowns.

Until then the correct state is:

`PHASE 5 = PARTIAL / OPEN`
