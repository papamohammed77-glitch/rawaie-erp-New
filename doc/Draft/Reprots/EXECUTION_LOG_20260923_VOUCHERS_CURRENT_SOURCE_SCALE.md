# Execution Log — Vouchers Current Source Scale — 2026-09-23

Execution ID: VCH-CURRENT-SOURCE-SCALE-20260923

Current Frontend:
HEAD 5cf09bac46aa65fa1e94ba34dfbdc3760cd446e2
vouchers.html blob fe0cbf6a6bbacc7086ea4fd8e9e78339e94820a8

Production snapshot UTC 2026-09-23 10:23:36:
companies=1
branches=1354
active_branches=1352
vehicles=1202
active_vehicles=1200
direct_sales_reps=10001
suppliers=501
active_suppliers=500
stock_vouchers=42
inventory_log=45
audit_log=3950
active_drafts=0

Verified defects:
- prefetchStock builds branch_id=in.(...) for 1352 branches; measured filter size 50038 chars; this explains current 400.
- updateSource does not refresh source-specific stock.
- subscribeRealtime repeats the all-branch filter pattern.
- pickArr performs nested vehicle->branch and vehicle->rep searches at current scale.

Verified contracts:
- Transfer is open to all active same-company branches for warehouse vouchers role.
- DirectReturn has 1200 valid mobile vehicle candidates.
- DirectSale eligibility remains governed by the backend rep/source-branch contract; BR-01 currently yields 1 eligible candidate and was not relaxed.

Production E2E:
CREATE -> SEND -> RECEIVE -> RECEIVE REPLAY -> COMPLETE -> FINAL CHECK -> ROLLBACK.
IN-43 was transient only.
CREATE PASS.
SEND PASS.
RECEIVE PASS.
REPLAY duplicate=true PASS.
COMPLETE PASS.
movement_logs=2.
allocated_qty=0.
ROLLBACK PASS.

No new Production schema/RPC/Edge Function was required.

Owner patch:
Report317_WAREHOUSE_VOUCHERS_CURRENT_SOURCE_FORENSIC_SCALE_20260923.md
PATCH-317-01 through PATCH-317-06
Target file: companies/company-1/warehouse/vouchers.html
main.html and van-sales.html untouched.

Status:
Production backend CLOSED / VERIFIED
Current source diagnosis PROVEN
Owner source patch READY
Published artifact OPEN / UNVERIFIED
Authenticated browser E2E OPEN / UNVERIFIED

Next exact step:
Apply PATCH-317-01 through PATCH-317-06, parse, publish, verify served artifact, run authenticated E2E, then refresh CURRENT_STATE.
