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
Repository: `papamohammed77-glitch/erp-frontend`
Branch: `main`
HEAD: `48714c33d5fc12646d0c2ea38033d902a52c4d1a`
HEAD message: `Initialize customer payment real-time updates`
Direct Parent: `c379674711d6e67d5c2c01305ae8449dd3c0947e`
Parent message: `Add real-time customer payment updates functionality`
Current main.html blob: `0bd8dd2fce45802f2383f6157e3e43aea51483f0`

The current HEAD already contains the customer-payment realtime wiring fix. Do not re-add it.

## CURRENT MASTER SOURCE FACTS
The current `companies/company-1/main.html` was directly inspected.

Confirmed:
- `RW_Navigation.menuTree` exists.
- Finance contains Treasury / Accounts / Journal / Receipts / Payments / Transfers / Reports / Installments / Budgets.
- Installments UI is already present in Current Source; prior state notes claiming it was absent are stale.
- Installment realtime wiring is present.
- `Commission` / `commission` is absent from Current Source.
- `RW_Finance.renderSubTab(subTab)` exists around source line ~10400.
- `_renderBudgets()` follows the installment block.
- `RW_Finance` export object exists near the end of the Finance module.

## FORENSIC ASSEMBLY
`forensic_main_assembly.yml` is already correct and requires no change:
- repository: `papamohammed77-glitch/erp-frontend`
- path: `companies/company-1/main.html`
- ref: `main`
- mode: `published_main_is_authoritative`
- fragment_mode: `historical_reference_only`

## CURRENT PRODUCTION — COMMISSION ENGINE
Supabase project: `fiilmooggumokxanwiyx`

Before this closure, Commission-specific tables/functions were absent.

Now deployed in Production:
- `commission_plans`
- `commission_rules`
- `commission_assignments`
- `commission_runs`
- `commission_run_lines`
- `commission_engine_atomic`
- `commission_assignment_guard`
- `commission_rule_guard`
- `commission_audit_trigger`

All Commission tables have Company foreign keys, RLS, service-role write policy, audit triggers, indexes, and required uniqueness constraints.

Realtime publication includes:
- `commission_plans`
- `commission_assignments`
- `commission_runs`
- `commission_run_lines`

`commission_engine_atomic` is `SECURITY DEFINER` and its EXECUTE grant is restricted to `service_role`.

Supported operations:
`PLAN_SAVE`
`PLAN_APPROVE`
`PLAN_ASSIGN`
`PREVIEW`
`POST`
`APPROVE_RUN`
`MARK_PAID`
`REVERSE_RUN`

Business basis:
- `invoiced_amount`
- `gross_profit`
- `invoiced_qty`

Net quantity basis is `qty - qty_returned`.
Only Company-scoped `Invoiced` orders in the selected period are eligible.

POST idempotency is based on caller-supplied `operation_id` with unique `(company_id, operation_id)`.

## CURRENT PRODUCTION — COMMISSION EDGE
Edge Function:
`commission-engine`

Status: `ACTIVE`
Version: `1`
`verify_jwt = true`
Deployment id: `1c84ef81-16d8-4ae6-8ded-394e4db5588e`
SHA: `9683d13b7c59ce41c78cdf18a6aad29e9a77ec10972a2fc3f2583d149eaf29fe`

The wrapper derives `company_id` from authenticated JWT -> `users.auth_id`, never from browser-supplied company context.

Canonical Git source:
`Current/Edge_Functions/commission-engine/index.ts`

Canonical migration:
`supabase/migrations/20260914010000_commission_engine_gold_closure.sql`

## COMMISSION PRODUCTION E2E
Verified directly against Production RPC runtime:

- Plan saved and approved.
- Tier rules applied.
- Sales Rep assigned.
- Test invoice base = 200.
- Target = 100.
- Achievement = 200%.
- Selected rate = 4%.
- Commission = 8.
- POST = `Posted`.
- Repeat same operation = `duplicate=true` and no second run.
- APPROVE = `Approved`.
- MARK_PAID = `Paid`.
- REVERSE = independent reversal run created and original marked `Reversed`.

Test data was removed after verification.
Final test-data state:
`commission_plans = 0`
`commission_rules = 0`
`commission_assignments = 0`
`commission_runs = 0`
`commission_run_lines = 0`
`E2E-COMM test orders = 0`

Commission audit rows were intentionally retained.

## COMMISSION FRONTEND STATUS
The master frontend was intentionally NOT modified by the assistant because frontend Master UI changes are owner-controlled.

Current master source has no Commission UI.

Owner surgical work is documented completely in:
`doc/Draft/Reprots/Report172_COMMISSION_ENGINE_GOLD_CLOSURE_20260914.md`

Required master UI changes:
1. Add Finance navigation item `العمولات`.
2. Add `commission` Finance subtab.
3. Add dispatch to `_renderCommission()`.
4. Add the complete Commission UI/helper block immediately before `_renderBudgets()`.
5. Export Commission UI helpers from `RW_Finance`.
6. Run browser E2E on the published master.

## OTHER CURRENT CLOSED AREAS
Installment backend is Production-deployed and Current Source already contains its UI/realtime wiring.
Customer-payment realtime wiring is already in current HEAD.
Do not re-fix either unless current evidence proves a new regression.

## CURRENT OPEN CONTRACTS
```text
Commission Production Database        = CLOSED
Commission Production RPC             = CLOSED
Commission Company Isolation          = CLOSED
Commission Tier Calculation            = VERIFIED
Commission Idempotent POST             = VERIFIED
Commission Approve/Paid/Reversal       = VERIFIED
Commission Audit                        = DEPLOYED
Commission Realtime                     = DEPLOYED
Commission Edge Function                = DEPLOYED
Commission Canonical Git                = ADDED
Commission Master UI                    = OWNER SURGERY REQUIRED
Commission Browser E2E                  = OPEN
Price List                              = OPEN / OWNER + E2E
Promotion                               = PRODUCTION DEPLOYED / OWNER + E2E
Full browser E2E                        = OPEN
```

## NEXT ASSISTANT RESUMPTION RULE
لا تبدأ من التقرير كحالة حالية.

ابدأ:
`CURRENT GIT HEAD`
`-> DIRECT PARENT`
`-> CURRENT MASTER SOURCE`
`-> CURRENT DATABASE`
`-> CURRENT FUNCTION DEFINITIONS`
`-> CURRENT EDGE DEPLOYMENT`
`-> CURRENT REALTIME PUBLICATION`
`-> CURRENT RLS / TRIGGERS / CONSTRAINTS`
`-> CURRENT PRODUCTION DATA COUNTS`
`-> CURRENT BROWSER / CONSOLE`

ثم:
`historical contract -> current behavior -> target contract -> actual gap -> surgical change -> test -> deploy -> Production verify -> runtime verify -> document -> close`

لا تعيد إصلاح ما ثبت إغلاقه.
لا تستخدم `Current/PWA/main2` أو `New-main` كـSource of Truth.
لا تعتبر Backend closure = Browser E2E closure.
لا تعتبر وجود جدول/RPC مساويًا لاكتمال Business Lifecycle.
أي نسبة أو تقرير يجب أن يكون مطابقًا لـProduction في نفس سياق القياس.

## CURRENT REPORT
`doc/Draft/Reprots/Report172_COMMISSION_ENGINE_GOLD_CLOSURE_20260914.md`
