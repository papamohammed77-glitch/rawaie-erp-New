# SEND-STOCK-VOUCHER — CENTRAL REWIRE PRE-STAGING RECORD

## STATUS
INCOMPLETE — HTTP E2E GATE REMAINS

## CURRENT
Current/Edge_Functions/send-stock-voucher was converted to a thin wrapper calling public.send_stock_voucher_atomic.

## CORE CHANGE
public.send_stock_voucher_atomic now delegates physical movement to public.post_stock_movement and no longer updates stock_branches or inventory_log directly.

Movement mapping:
- Transfer -> TransferOut
- DirectSale -> TransferOut for voucher-send physical issue; voucher type remains in reference
- SupplierReturn -> SupplierReturn

Deterministic idempotency key:
StockVoucherSend:<company_id>:<voucher_id>:<item_id>

## STAGING EVIDENCE
Transactional Core test:
- MAIN stock 92 -> 91 for qty 1
- inventory_log rows = 1
- idempotency rows = 1
- voucher status = Sent
- retry rejected after Sent
- insufficient stock rejected
- stock unchanged on failure
- no test data persisted because tests used transaction rollback

## NOT VERIFIED YET
Real HTTP Edge E2E for send-stock-voucher in staging.

Available execution channels were checked:
- Supabase connector: no Edge invoke operation exposed
- staging PostgreSQL: pg_net/http extensions absent
- external runtime curl: DNS/network unavailable
- temporary GitHub workflow creation: rejected by security checks

Therefore Production deployment is intentionally NOT executed.

## SOURCE
Historical send-stock-voucher:
rawaie-erp-review/Edge_Functions/original/08_inventory/send-stock-voucher.ts
SHA: 811f458b172db1210adbb15fd483be856b45a0be

Current baseline had the same legacy SHA and was reworked in this branch.

## ARCHITECTURAL CLASSIFICATION
send-stock-voucher = physical stock movement capability.
reserve_stock = reservation engine; retained separately.
setup_van_stock = initialization; retained separately.

## NEXT GATE
Obtain a safe HTTP invocation channel in staging, execute real Edge E2E, then Production deploy + verification.
