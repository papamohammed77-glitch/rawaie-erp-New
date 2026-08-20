# RAWAEA ERP — VOUCHERS DIAMOND FORENSIC CLOSEOUT
## 2026-08-20

### Authority
This record was produced from direct inspection of:
- `doc/Draft/Hussin/HISTORICAL_SEQUENCE_PROMPTS_11_TO_39.md`
- current `main` source tree
- deployed Production PostgreSQL metadata and function definitions
- deployed Supabase Edge Function versions

The governing execution order was: Understand → Reconstruct Historical Contract → Trace Current Behavior → Trace Data/Auth/Control Flow → Compare Target → Identify Gap → Minimal Safe Change → Implement → Verify.

### Historical contract established
1. Manual stock vouchers and Van Sales are related but not the same bounded context.
2. Voucher lifecycle is limited to `Transfer`, `DirectSale`, `DirectReturn`, `SupplierReturn`.
3. `DirectSale` is `Branch → Vehicle`; `DirectReturn` is `Vehicle → Branch`.
4. Vehicle physical stock is represented by its canonical `VAN-<vehicle_code>` branch.
5. `Scrap` and `Adjustment` use the Adjustment Engine and are not fake voucher types.
6. Physical stock mutation belongs only to `post_stock_movement`.
7. `order_details` is the authoritative fulfillment detail; runsheet detail is derived.
8. Warehouse item details must not expose sales/cost prices.

### Production findings and repairs

#### Manual Voucher CREATE
`create_manual_stock_voucher_atomic` was repaired to:
- require a non-empty reference;
- enforce the four voucher contracts above;
- validate Branch/Vehicle/Supplier ownership against `company_id`;
- validate the canonical vehicle stock branch `VAN-<vehicle_code>`;
- use the global Item Master identity contract (`item_code` is globally unique);
- generate voucher numbers under an advisory transaction lock.

#### Manual Voucher SEND / RECEIVE
`send_stock_voucher_atomic` and `post_manual_stock_voucher_atomic` were repaired to:
- support `DirectReturn`;
- resolve Vehicle source/target to the canonical VAN branch;
- preserve physical movement centralization through `post_stock_movement`;
- reject invalid direction/context combinations;
- preserve event idempotency keys.

#### Purchase Receiving
Production `receive_purchase_atomic` now requires a persistent `p_operation_id` and uses the existing `receiving.operation_id` unique contract for idempotency.
The Production Edge Function `receive-purchase` was then updated to version **12** to:
- derive company from the authenticated `users` record instead of `app_settings LIMIT 1`;
- accept explicit `operation_id` / `Idempotency-Key`;
- deterministically derive a UUID when the client does not supply one;
- invoke the current five-argument Production RPC.

#### Sales Invoice
Production `save_sales_invoice_atomic` uses `orders.operation_id` for retry identity.
The Production Edge Function `save-sales-invoice` was updated to version **15** to provide a deterministic operation UUID when the client does not provide one.

#### Delivery
Production `complete_order_delivery_atomic` is tenant scoped and idempotent.
The Production Edge Function `complete-order-delivery` was updated to version **13** and no longer derives company context through `app_settings LIMIT 1`; it uses the authenticated user's `company_id`.

### Production verification performed
Transaction-scoped forensic smoke tests were run directly against Production PostgreSQL and rolled back after verification.

Verified:
- `DirectSale`: source MAIN stock decreases and vehicle VAN stock increases across SEND/RECEIVE/COMPLETE lifecycle through the central stock engine.
- `DirectReturn`: vehicle VAN stock decreases and MAIN stock increases through the same contract.
- `Transfer`: Branch → Branch SEND/RECEIVE/COMPLETE lifecycle executes through the central stock engine.
- Test rows and test stock effects were rolled back; no forensic test vouchers remained after rollback.

### Global Physical Writer Sweep
Direct source inspection of deployed PostgreSQL functions found:
- `post_stock_movement` as the only direct physical stock writer;
- `reserve_stock` / `release_stock_reservation` as reservation-only writers;
- `setup_van_stock` as stock-row initialization, not a business movement;
- no additional function containing an independent `inventory_log` INSERT or `stock_branches` physical-movement UPDATE outside these boundaries.

### vouchers.html Diamond Master
`Current/PWA/vouchers.html` was replaced in `main` by a consolidated single-file Diamond Master implementation, commit:
`430d697d45ea03498bee377aec4482e31da01287`

The current file:
- keeps authentication/recovery;
- uses company-scoped reference loading;
- maps Vehicle → `VAN-*` branch;
- supports Transfer / DirectSale / DirectReturn / SupplierReturn;
- separates Scrap / Adjustment to the Adjustment Engine;
- performs no direct `stock_branches` mutation;
- does not load or expose `sales_price` / `cost_price`;
- uses persistent receive operation identity in localStorage;
- keeps keyboard/mobile interaction and item-detail access.

### Source evidence
Historical sequence source:
https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Hussin/HISTORICAL_SEQUENCE_PROMPTS_11_TO_39.md

Current Diamond Master:
https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/Current/PWA/vouchers.html

### Remaining explicit limitation
A real JWT-authenticated HTTP end-to-end run of the newly redeployed Edge Functions was not executed from an authenticated browser session during this forensic pass. Production PostgreSQL transaction smoke and deployed source/version verification were completed.
Therefore this record does **not** classify the new Edge releases as "HTTP E2E 100% proven" merely from DB smoke results.

### Final classification
- Historical contract reconstruction: **CLOSED**
- Manual Voucher vehicle lifecycle contract: **CLOSED**
- Physical stock centralization: **CLOSED by direct writer sweep**
- Tenant/company context defects identified in inspected wrappers: **CORRECTED**
- Current `vouchers.html` Diamond Master committed: **CLOSED**
- Production PostgreSQL smoke verification: **PASSED**
- Production Edge deploy verification: **PASSED**
- Real JWT HTTP E2E: **OPEN EVIDENCE GATE**
