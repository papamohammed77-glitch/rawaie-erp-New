# RAWAEA ERP — PWA Forensic & Production Closure Checkpoint

Date: 2026-08-19
Scope: Current/PWA + Production Inventory Core + Tenant/Write Boundaries

## Source Basis

Reviewed directly from Git:
- Prompt 6 + execution report
- Prompt 7 + execution report
- Inventory/05-GLOBAL-INVENTORY-ZERO-DEBT-RESULT-20260819.md
- Prompt 8 + execution report
- Prompt 9 + execution report
- Hussin evaluation of Prompt 9
- Prompt 10 + execution report
- Current/PWA application files

Historical closure claims were treated as evidence only and re-tested against current Production.

## Current PWA Review

Files reviewed:
- main.html
- picker.html
- pos.html
- van-sales.html
- buyer.html
- vouchers.html
- Returns.html

Observed inventory boundary:
- No direct PWA write to stock_branches was found in the reviewed application paths.
- No direct PWA write to inventory_log was found in the reviewed application paths.
- Picker writes fulfillment state through complete-picking -> complete_runsheet_picking -> reserve_stock.
- Sales/POS and Van Sales use save-sales-invoice capability.
- Returns uses complete-return capability.
- Voucher operations use send-stock-voucher / receive-stock-voucher capabilities.
- Purchase creation uses save-purchase-order capability.

## Production Findings Re-Verified

Current PostgreSQL writer discovery shows:
- post_stock_movement = only Physical Stock Movement Engine.
- reserve_stock = reservation only.
- release_stock_reservation = reservation release only.
- setup_van_stock = initialization/setup only.
- complete_runsheet_picking does not mutate inventory_log or physical qty.
- No stock_branches/inventory_log database triggers were found.

Current integrity snapshot:
- negative_stock = 0
- invalid_allocated = 0
- orphan_stock_branch = 0
- orphan_stock_item = 0
- orphan_inventory_item = 0
- orphan_inventory_company = 0
- direct_stock_triggers = 0
- cross_company_stock_rows = 143
- cross_company_inventory_logs = 86

The 143/86 rows were not deleted. Current Production contract treats Item Master identity as global through item_id + globally unique item_code; therefore those rows are not automatically data corruption.

## Production Fixes Applied During This Review

1. stock_vouchers / stock_voucher_details / inventory_log
   - Application INSERT/UPDATE/DELETE/TRUNCATE capabilities revoked.
   - Permissive Allow-all policies removed.
   - Authenticated SELECT is now company-scoped.

2. purchase_orders / purchase_order_details
   - Application write capabilities revoked.
   - Permissive Allow-all policies removed.
   - Authenticated SELECT is now company-scoped.

3. VAN branch tenant guard
   - BEFORE INSERT/UPDATE trigger enforces current authenticated company for VAN-* branch codes.
   - Runtime test proved a hard-coded company_id is replaced by the authenticated user's company context.

4. Sales operation identity
   - Partial unique index added on (company_id, operation_id) for non-null operation_id.

## PWA Source-Parity Finding

A real source-level defect remains in Current/PWA/van-sales.html:
- _createVanBranch() directly INSERTs branches.
- It contains a hard-coded legacy company_id.
- Current RLS already blocks direct branch INSERT from the application.
- Canonical Production capability setup-van-branch exists and is the correct path: it resolves company from authenticated user, validates vehicle ownership, creates the VAN branch, and initializes stock.

Runtime safety is therefore protected in Production, but source parity is NOT 100% closed until van-sales.html is surgically rewired to setup-van-branch.

## Picker Next Gap

complete-picking / complete_runsheet_picking currently has no request-level operation_id/idempotency registry. This does not create a parallel Physical Stock Writer, but it remains a Picker reliability gap for retry/replay protection and belongs to the next closure unit.

## Final Status

Global Physical Stock Core: VERIFIED 100% CLOSED at the Production engine boundary.
Tenant/write-boundary remediation: VERIFIED CLOSED for stock vouchers, inventory log, and purchase orders.
PWA source parity: NOT 100% CLOSED because van-sales.html still contains the legacy direct branch-create block.
Picker reliability: OPEN — operation-level idempotency not yet closed.

## Required Next Closure Unit

1. Surgically replace _createVanBranch() in Current/PWA/van-sales.html with the canonical setup-van-branch capability while preserving the current UX and local Dexie behavior.
2. Add operation-level idempotency to complete-picking without turning reservation into a physical movement.
3. Re-run the Production snapshot immediately before the next closure report.

## Governance Rule

No percentage is considered authoritative unless matched to the current Production snapshot at report time.
