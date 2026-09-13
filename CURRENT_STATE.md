# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-14

## GOVERNANCE / SOURCE OF TRUTH
الحالة الحالية لا تُستمد من التقارير السابقة؛ التقارير Historical/Reference فقط.

الحقيقة المعتمدة:
`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

Source of Truth للنظام الأم:
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

Historical reference only:
`Current/PWA/main2/*`
`Original/PWA/main/*`
`New-main`

Permanent rules:
`NO ASSUMPTION`
`ONE CLOSURE AT A TIME`
`REPORTS ARE CLUES — NEVER CURRENT STATE`
`CLOSE -> VERIFY -> DOCUMENT -> NEXT`

## CURRENT FRONTEND GIT
Repository:
`papamohammed77-glitch/erp-frontend`
Branch:
`main`

HEAD:
`c379674711d6e67d5c2c01305ae8449dd3c0947e`
Message:
`Add real-time customer payment updates functionality`

Direct Parent:
`4eb99edff261ae350d21c277d51adcaf75d02def`
Message:
`Update main.html`

Current main.html blob:
`a41903730c302ddef82b91edfec4a4a3a400d76c`

The current HEAD added the Customer Payment Realtime consumer. The forensic recheck found two current UI integration defects:
1. `_customerPaymentRealtimeChannel` has no declaration in the current source.
2. `_startCustomerPaymentRealtime()` is called inside `_loadDashboardData()` instead of `_renderReceipts()`.

The Multiple/Partial Customer Payment UI module and its public RW_Finance methods are already present. Do not re-add them.

## OWNER SURGERY — OPEN
Target only:
`erp-frontend/companies/company-1/main.html`

1. Immediately before the exact line `function _startCustomerPaymentRealtime() {` add:
`var _customerPaymentRealtimeChannel = null;`

2. Inside `_renderReceipts()`, immediately after the exact line `var companyId = _companyId();` add:
`_startCustomerPaymentRealtime();`

3. Inside `_loadDashboardData(fromDate, toDate)`, remove the complete exact line:
`_startCustomerPaymentRealtime()`

No other payment allocation patch is required at this checkpoint.

## PRODUCTION — SALES PAYMENT ALLOCATION
Supabase project:
`fiilmooggumokxanwiyx`

Tables verified:
- `sales_payment_receipts`
- `sales_payment_allocations`
- `erp_operation_registry`

Constraints/indexes verified:
- `erp_operation_registry UNIQUE (company_id, operation_type, operation_key)`
- `sales_payment_receipts UNIQUE (company_id, receipt_code)`
- `sales_payment_receipts UNIQUE (company_id, operation_id)`
- `sales_payment_allocations UNIQUE (receipt_id, order_id)`
- indexes on allocation order/receipt

Production RPCs verified:
- `post_sales_payment_allocation_atomic`
- `post_cash_receipt_atomic`

Production Edge:
`sales-payment-allocation`
Status: `ACTIVE`
Version: `1`
`verify_jwt=true`
Deployment SHA:
`9df011f54b67afc9c3e1c73a9948fcb0c77673844a0441cfd54685704fdf2f85`

Production Realtime verified:
- `sales_payment_receipts` in `supabase_realtime`
- `sales_payment_allocations` in `supabase_realtime`

## PRODUCTION E2E CORE VERIFICATION
A real Production transaction was executed with temporary E2E customer/orders.

Scenario:
Receipt `150`
Allocation #1 `60`
Allocation #2 `50`
Unallocated `40`

First execution:
`success=true`
`duplicate=false`
`allocated_amount=110`
`unallocated_amount=40`
`allocation_count=2`

Retry with the same Operation ID:
`success=true`
`duplicate=true`
Same receipt returned; no duplicate financial operation.

Cleanup verification:
E2E customer rows `0`
E2E order rows `0`
E2E receipt rows `0`
E2E cashbox rows `0`
E2E operation registry rows `0`
E2E customer ledger rows `0`

No permanent E2E test data remains.

## FORENSIC ASSEMBLY
`rawaie-erp-New/forensic_main_assembly.yml` exists and is already correct:

`repository: papamohammed77-glitch/erp-frontend`
`path: companies/company-1/main.html`
`ref: main`
`mode: published_main_is_authoritative`

No change required.

## CURRENT REPORT
`doc/Draft/Reprots/Report170_E2E_SALES_PAYMENT_ALLOCATION_FORENSIC_RECHECK_20260914.md`

## OPEN CONTRACTS
```text
Multiple/Partial Payment Backend             = PRODUCTION DEPLOYED
Multiple/Partial Payment Core                = PRODUCTION RUNTIME VERIFIED
Multiple/Partial Payment Realtime             = PRODUCTION VERIFIED
Multiple/Partial Payment Master UI module     = PRESENT
Multiple/Partial Payment UI Realtime wiring   = OWNER FIX REQUIRED
Multiple/Partial Payment Browser E2E          = OPEN
Price List                                    = OPEN / OWNER + E2E
Promotion                                     = PRODUCTION DEPLOYED / OWNER + E2E
Full browser E2E                              = OPEN
```

## NEXT ASSISTANT RESUMPTION RULE
لا تبدأ من Report170 أو Report169 كحالة حالية.

ابدأ دائمًا:
`CURRENT GIT HEAD`
`-> DIRECT PARENT`
`-> CURRENT SOURCE`
`-> CURRENT DATABASE`
`-> CURRENT RPC DEFINITIONS`
`-> CURRENT EDGE DEPLOYMENT`
`-> CURRENT REALTIME PUBLICATION`
`-> CURRENT RUNTIME`

ثم:
`historical contract -> current behavior -> target contract -> actual gap -> surgical change -> test -> deploy -> Production verify -> runtime verify -> document -> close`

لا تعيد إصلاح ما ثبت أنه مغلق.
لا تسجل Browser/E2E closure من دون تشغيل UI فعلي.
لا تستخدم `Current/PWA/main2` أو `New-main` كـSource of Truth.
