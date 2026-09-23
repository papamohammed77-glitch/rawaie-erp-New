# Execution Log — 2026-09-23 — Warehouse Vouchers Transfer Scope

## Execution ID
VCH-TRANSFER-SCOPE-20260923

## Scope
Warehouse → Inventory Management → Stock Vouchers

## Starting checkpoint
- System HEAD: b3cc3c7fe405e502c243f4d74ac5680304e5259e
- Frontend HEAD: 751f6175675ffe99023337e523501bd35e9553c6
- vouchers.html blob: 751e7b4fc814dd7011ee903e1703dc8df9896f0c

## Production changes executed
1. create_manual_stock_voucher_atomic (10 args)
2. create_manual_stock_voucher_atomic (12 args)
3. send_stock_voucher_atomic
4. post_manual_stock_voucher_atomic

Contract:
Transfer is allowed for role=مخزني + active_warehouse_role=أذونات across active branches of the same company.

No new Edge Function.
No new table.
No new RLS.
No Physical Stock engine change.

## QA retained
IN-28, IN-29, IN-30, IN-31 retained.

## Persistent E2E
IN-32: BR-01 → BR-2, Transfer, Completed.
IN-33: BR-2 → BR-01, Transfer, Completed.

## Verification
- Create PASS
- Send PASS
- Receive PASS
- Complete PASS
- Reverse Transfer PASS
- Create idempotency PASS
- Unauthorized vansales@rawaea.com Transfer rejected
- Stock total conserved at 79 for Item 1001
- IN-32 inventory logs: 2
- IN-33 inventory logs: 2
- IN-32 audit rows: 4
- IN-33 audit rows: 4

## Final production counters
companies=1
branches=4
vehicles=2
suppliers=1
direct_reps=1
stock_vouchers=33
stock_voucher_details=35
inventory_log=30
audit_log=2123

## Owner source action
File:
companies/company-1/warehouse/vouchers.html

Exact element:
App.allowedBranch

Current SHA:
751e7b4fc814dd7011ee903e1703dc8df9896f0c

Owner must replace the complete function with the version in Report315.

Do not modify:
main.html
van-sales.html
loadRefs
pickArr
pickSearch
pickSelect
vehicleBranch
norm
routeHtml
submit
prepare

## Closure
Production Transfer Contract: CLOSED
Production Transfer E2E: VERIFIED
Backend: VERIFIED
Frontend source: OWNER PATCH READY
Browser authenticated E2E: OPEN
Published served artifact: OPEN

## Next exact action
Owner patch → parse → publish → authenticated browser E2E → served artifact identity → fresh Production snapshot → CURRENT_STATE update.
