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
`48714c33d5fc12646d0c2ea38033d902a52c4d1a`
Message:
`Initialize customer payment real-time updates`

Direct Parent:
`c379674711d6e67d5c2c01305ae8449dd3c0947e`
Message:
`Add real-time customer payment updates functionality`

Current main.html blob verified:
`0bd8dd2fce45802f2383f6157e3e43aea51483f0`

The current HEAD already contains the former Report170 customer-payment realtime wiring fix. Do not re-add that repair.

Current source facts verified:
- `RW_Navigation.menuTree` exists and contains Finance navigation.
- `RW_Finance.renderSubTab(subTab)` exists around source line 10400.
- Finance already has treasury/accounts/journal/receipts/payments/transfers/reports/budgets.
- No `installment` UI exists yet in the current master source.
- `_renderBudgets()` exists around source line 11980+.
- `RW_Finance` return/export object exists around source line 12520+.

## FORENSIC ASSEMBLY
`rawaie-erp-New/forensic_main_assembly.yml` was rechecked and is already correct:

`repository: papamohammed77-glitch/erp-frontend`
`path: companies/company-1/main.html`
`ref: main`
`mode: published_main_is_authoritative`
`fragment_mode: historical_reference_only`

No change required.

## PRODUCTION — INSTALLMENT LIFECYCLE
Supabase project:
`fiilmooggumokxanwiyx`

Production counts after cleanup:
`installments = 0`
`installment_details = 0`
`installment_payment_allocations = 0`

Backend now includes:
- `installments.company_id/order_id/customer_uuid`
- `installment_details.company_id/installment_uuid/installment_no/remaining_amount`
- `installment_payment_allocations`
- company/order/customer foreign keys
- active-plan uniqueness
- payment-allocation uniqueness
- Company-scoped RLS
- Audit triggers
- Realtime publication entries
- `installment_aging_v`

Production RPCs:
- `create_installment_plan_atomic`
- `cancel_installment_plan_atomic`
- `refresh_installment_plan_atomic`
- `allocate_sales_payment_to_installment_atomic`

Payment integration:
`sales_payment_allocations`
→ `trg_sales_payment_allocation_installment`
→ `allocate_sales_payment_to_installment_atomic`
→ `installment_details`
→ `installments`

No parallel receipt/ledger/payment engine was created.

Production Edge:
`installments`
Status: `ACTIVE`
Version: `1`
`verify_jwt=true`
Deployment SHA:
`770c6a830f9d95bb5efb4f563c1de37b6581bef1f47856468df7259e77598db7`

Canonical Git sources created:
- `supabase/migrations/20260914000000_installment_lifecycle_gold_closure.sql`
- `Current/Edge_Functions/installments/index.ts`

## PRODUCTION E2E — INSTALLMENT
Transactional Production test executed and rolled back.

Verified scenario:
- Order outstanding = 1000
- Schedule = 400 overdue + 600 future
- Create plan
- Reuse same Operation ID path exercised
- Payment allocation = 400
- First installment paid = 400
- Plan status = `Partially Paid`
- installment allocation rows = 1
- refresh executed
- no permanent E2E data remains

Cancel-before-payment test:
- temporary plan created
- cancel executed
- `plan_status = Cancelled`
- one detail line became `Cancelled`
- transaction rolled back

One independent Paid-Cancel SQL test initially failed because the test query used an ambiguous `paid_amount` column. This did not mutate Production. The RPC guard itself remains:
`paid_amount > 0 -> INSTALLMENT_CANNOT_CANCEL_AFTER_PAYMENT`.
Therefore Paid-Cancel is not recorded as an independently successful E2E scenario.

## OPEN MASTER UI SURGERY
The backend is ready, but the master frontend is owner-controlled and was intentionally not modified by the assistant.

Required surgical changes are documented completely in:
`doc/Draft/Reprots/Report171_E2E_INSTALLMENT_LIFECYCLE_EXECUTION_20260914.md`

Target file only:
`erp-frontend/companies/company-1/main.html`

Required changes:
1. Add Finance navigation item `التقسيط والتحصيل الآجل`.
2. Add `installments` to `RW_Finance.renderSubTab()` tabs.
3. Add `else if (tab === 'installments') _renderInstallments();`.
4. Add the full `_renderInstallments` + helper block immediately before `_renderBudgets()`.
5. Export all installment UI functions in `RW_Finance` return object.

No changes to historical fragments are required.

## OPEN CONTRACTS
```text
Installment Production Backend                 = CLOSED
Installment Production E2E Transaction         = VERIFIED
Installment Cancel Before Payment              = VERIFIED
Installment Paid-Cancel standalone E2E         = NOT INDEPENDENTLY VERIFIED
Installment Master UI                           = OWNER SURGERY REQUIRED
Installment Browser E2E                         = OPEN
Multiple/Partial Payment Backend               = PRODUCTION DEPLOYED
Multiple/Partial Payment Core                  = PRODUCTION RUNTIME VERIFIED
Multiple/Partial Payment Realtime              = PRODUCTION VERIFIED
Multiple/Partial Payment Master UI Realtime    = PRESENT IN CURRENT HEAD
Price List                                      = OPEN / OWNER + E2E
Promotion                                       = PRODUCTION DEPLOYED / OWNER + E2E
Full browser E2E                                = OPEN
```

## CURRENT REPORT
`doc/Draft/Reprots/Report171_E2E_INSTALLMENT_LIFECYCLE_EXECUTION_20260914.md`

## NEXT ASSISTANT RESUMPTION RULE
لا تبدأ من Report170 أو Report171 كحالة حالية.

ابدأ دائمًا:
`CURRENT GIT HEAD`
`-> DIRECT PARENT`
`-> CURRENT MASTER SOURCE`
`-> CURRENT DATABASE`
`-> CURRENT FUNCTION DEFINITIONS`
`-> CURRENT EDGE DEPLOYMENT`
`-> CURRENT REALTIME PUBLICATION`
`-> CURRENT RLS / TRIGGERS / CONSTRAINTS`
`-> CURRENT RUNTIME / BROWSER`

ثم:
`historical contract -> current behavior -> target contract -> actual gap -> surgical change -> test -> deploy -> Production verify -> runtime verify -> document -> close`

لا تعيد إصلاح ما ثبت أنه مغلق.
لا تعتبر Backend closure = Browser E2E closure.
لا تستخدم `Current/PWA/main2` أو `New-main` كـSource of Truth.
لا تعتبر أي تقرير حالة حالية إلا بعد مطابقته بالمصادر الحالية.
