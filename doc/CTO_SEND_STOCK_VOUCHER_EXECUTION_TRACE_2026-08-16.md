# SEND-STOCK-VOUCHER — EXECUTION TRACE
Date: 2026-08-16

## Current Gate
The Production create/send consumer dependency was repaired and both functions are now deployed from the authenticated-user company resolver:
- `create-stock-voucher` Production v5
- `send-stock-voucher` Production v8
- Staging `create-stock-voucher` v1
- Canonical `send_stock_voucher_atomic` migration applied in Staging and Production

## Evidence Before Final Close
Staging `send-stock-voucher` HTTP E2E passed:
- first HTTP 200 / success=true / status=Sent / movement_count=1
- one physical stock decrement
- one inventory log
- retry rejected because voucher was no longer Draft
- no second physical movement
- fixture baseline restored

Production HTTP runs #94 and #97 are classified as OBSOLETE TEST RUNS because each started before the latest corresponding Edge deployment completed. Their failures therefore do not test the final deployed versions.

A fresh Production HTTP run after v8/v5 deployment is the remaining runtime gate. No final 100% closure claim is made in this trace.
