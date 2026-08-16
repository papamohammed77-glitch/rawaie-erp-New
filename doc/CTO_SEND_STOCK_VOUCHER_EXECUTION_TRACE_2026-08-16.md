# SEND-STOCK-VOUCHER — EXECUTION TRACE
Date: 2026-08-16

## Current Gate
The Production create/send consumer dependency was identified and repaired:
- `create-stock-voucher` now derives `company_id` from `app_settings`.
- `create-stock-voucher` resolves and persists `item_id` by company + item_code.
- Production `create-stock-voucher` deployed as version 4.
- Staging `create-stock-voucher` deployed as version 1.

## Evidence Before Final Close
Staging `send-stock-voucher` HTTP E2E passed after canonical send Core verification:
- first HTTP 200 / success=true / status=Sent / movement_count=1
- one physical stock decrement
- one inventory log
- retry rejected because voucher was no longer Draft
- no second physical movement
- fixture baseline restored

Production HTTP run #94 is classified as OBSOLETE TEST RUN because it started before `create-stock-voucher` v4 finished deploying and therefore exercised the pre-fix v3 producer. Its failure was the expected old company-context mismatch.

A fresh Production HTTP run is required after the v4 deployment. No final 100% closure claim is made in this trace.
