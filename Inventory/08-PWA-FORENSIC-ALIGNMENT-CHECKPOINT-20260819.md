# RAWAEA ERP — PWA FORENSIC ALIGNMENT CHECKPOINT
## 2026-08-19

## Source of Truth
This checkpoint is based on direct inspection of:
- GitHub current PWA sources under `Current/PWA`.
- Production Supabase PostgreSQL and deployed Edge Functions.
- Historical Prompts 6–10 and the Hussin assessment only as historical context, not as current truth.

## Production Facts Confirmed
1. `post_stock_movement` remains the Physical Stock mutation engine.
2. `complete_runsheet_picking` currently does NOT write `inventory_log`; it uses `reserve_stock` for reservation and updates fulfillment state.
3. `stock_branches` and `inventory_log` application roles currently have SELECT only; direct INSERT/UPDATE/DELETE privileges are closed.
4. `erp_operation_registry` is application-internal and has no application table grants.
5. Production cross-company residue was cleaned:
   - 143 `stock_branches` rows removed.
   - 86 `inventory_log` rows removed.
   - Post-cleanup cross-company counts = 0 / 0.
6. Final cleanup did not touch owner-company business data.

## Picker Core Change Applied in Production
`complete_runsheet_picking` now has an additional 5-argument overload:
`(p_company_id, p_runsheet_code, p_user_email, p_items, p_operation_id uuid)`.

`erp_operation_registry` now has:
`UNIQUE(company_id, operation_type, operation_key)`.

The duplicate/replay guard was transactionally verified in Production:
- same `operation_id` + identical request returned `success=true, duplicate=true`.
- test data was rolled back.

The existing 4-argument function remains for compatibility until the PWA and Edge consumer are updated and runtime-verified. It must be retired from application EXECUTE only after the new consumer path is live.

## Current PWA Gaps Confirmed
### 1. `Current/PWA/van-sales.html`
`_createVanBranch()` still performs direct `branches` INSERT and contains a hardcoded owner company UUID. It also derives `VAN-` code from user email. This is not the target capability.

Correct target: `setup-van-branch`, which is deployed and company-aware.

### 2. `Current/PWA/van-sales.html`
`submitQuickSale()` does not pass `operation_id` into `orderHeader`.
Therefore Van Sales is not yet aligned with the already-idempotent `save_sales_invoice_atomic` core.

### 3. `Current/PWA/picker.html`
`completePicking()` currently posts only `runsheet_code` + `items`.
It does not pass an operation identity to `complete-picking`.

### 4. `complete-picking` Edge Function
Current deployed version 15 does not accept/pass `operation_id` to `complete_runsheet_picking`.

### 5. `Current/PWA/vouchers.html`
The current details reader filters `stock_voucher_details` by `voucher_code`, while the table uses `voucher_id` and does not expose a `voucher_code` column. This is a real P2 consumer defect, separate from the central Physical Stock contract.

## Current Closure Status
- Inventory Physical Writer Centralization: CLOSED structurally.
- Production Stock/Data Integrity: PASS after cleanup.
- Picker replay/idempotency Core: DEPLOYED + transactional duplicate-path verified.
- Picker end-to-end idempotency: OPEN until PWA + Edge pass `operation_id` and Production HTTP E2E is run.
- Van Branch capability alignment: OPEN.
- Van Sales idempotency alignment: OPEN.
- Voucher-details reader defect: OPEN (P2).

## Governance Rule
Do not mark Global Inventory / PWA alignment as 100% CLOSED until the open consumer changes are implemented and the corresponding Production runtime paths are freshly verified.
