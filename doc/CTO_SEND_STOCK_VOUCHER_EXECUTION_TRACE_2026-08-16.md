# SEND-STOCK-VOUCHER — EXECUTION TRACE
Date: 2026-08-16

## Current Gate
Production dependency functions are now fully deployed:
- `create-stock-voucher` Production v7
- `send-stock-voucher` Production v8
- company context resolves from authenticated `public.users.company_id`
- item resolution is company-scoped, deterministic, and matches the live Production schema
- canonical `send_stock_voucher_atomic` migration is applied in Staging and Production

## Evidence Before Final Close
Staging `send-stock-voucher` HTTP E2E passed:
- first HTTP 200 / success=true / status=Sent / movement_count=1
- one physical stock decrement
- one inventory log
- retry rejected because voucher was no longer Draft
- no second physical movement
- fixture baseline restored

Production runs #94, #97 and #100 are classified as OBSOLETE TEST RUNS because each exercised a preceding deployment/schema state. The latest create-item correction is now Production v7.

A fresh Production HTTP run after v7/v8 deployment is the remaining runtime gate. No final 100% closure claim is made in this trace.
