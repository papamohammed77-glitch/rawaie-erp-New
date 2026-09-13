# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-14

## GOVERNANCE / SOURCE OF TRUTH
الحالة الحالية لا تُستمد من التقارير السابقة؛ التقارير Historical/Reference فقط.

الحقيقة المعتمدة:
`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

Source of Truth للنظام الأم:
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

Historical reference only:
`Current/PWA/main2/*`, `Original/PWA/main/*`, `New-main`.

## CURRENT FRONTEND GIT
Repository: `papamohammed77-glitch/erp-frontend`
Branch: `main`
HEAD: `48714c33d5fc12646d0c2ea38033d902a52c4d1a`
HEAD: `Initialize customer payment real-time updates`
Direct Parent: `c379674711d6e67d5c2c01305ae8449dd3c0947e`
Parent: `Add real-time customer payment updates functionality`
Current main.html blob: `0bd8dd2fce45802f2383f6157e3e43aea51483f0`

Current Source facts verified:
- `RW_Navigation.menuTree` exists.
- Finance currently has treasury/accounts/journal/receipts/payments/transfers/reports/installments/budgets.
- Installments UI and realtime are already present; do not recreate them.
- Commission UI is absent.
- `forensic_main_assembly.yml` already correctly points to the published master and requires no change.

## PRODUCTION — COMMISSION ENGINE
Supabase project: `fiilmooggumokxanwiyx`

Production tables:
- `commission_plans`
- `commission_rules`
- `commission_assignments`
- `commission_runs`
- `commission_run_lines`

Production core:
- `commission_engine_atomic`
- `commission_assignment_guard`
- `commission_rule_guard`
- `commission_audit_trigger`

Security:
- Commission tables use Company foreign keys and RLS.
- Service-role write policy is used for the application capability layer.
- Commission RPC is SECURITY DEFINER and EXECUTE is restricted to `service_role`.

Realtime publication:
- commission_plans
- commission_assignments
- commission_runs
- commission_run_lines

Supported operations:
`LIST_PLANS`, `LIST_RUNS`, `PLAN_SAVE`, `PLAN_APPROVE`, `PLAN_ASSIGN`, `PREVIEW`, `POST`, `APPROVE_RUN`, `MARK_PAID`, `REVERSE_RUN`.

## PRODUCTION — COMMISSION EDGE
Function: `commission-engine`
Status: `ACTIVE`
Version: `2`
verify_jwt: `true`
Deployment id: `1c84ef81-16d8-4ae6-8ded-394e4db5588e`
Current deployment SHA: `47607c4bb60105c9233e91fbcd013c7dd544c95e19cd6997133cfda22bc6e28c`

The Edge wrapper derives Company context from JWT -> `users.auth_id` -> `users.company_id`.

Canonical Git source:
`Current/Edge_Functions/commission-engine/index.ts`

Canonical DB sources:
- `supabase/migrations/20260914010000_commission_engine_gold_closure.sql`
- `supabase/migrations/20260914011000_commission_engine_read_api.sql`

## COMMISSION E2E — PRODUCTION RPC
Verified directly against Production:
- Target = 100
- Base = 200
- Achievement = 200%
- Tier rate = 4%
- Commission = 8
- POST = Posted
- Repeated same Operation ID = duplicate=true, no second run
- APPROVE = Approved
- MARK_PAID = Paid
- REVERSE = independent reversal run, original becomes Reversed

All temporary Commission test records and E2E test orders were removed after the test.
Audit records were intentionally retained.

## CURRENT OPEN CONTRACTS
```text
Commission Database / Core RPC        = CLOSED
Commission Read API                   = CLOSED
Commission Edge                       = DEPLOYED v2
Commission Production RPC E2E         = VERIFIED
Commission Master UI                  = OWNER SURGERY REQUIRED
Commission Browser E2E                = OPEN
Installment backend                   = CLOSED / deployed
Installment Master UI                 = PRESENT in current master source
Customer-payment realtime             = PRESENT in current HEAD
Price List                             = OPEN / OWNER + E2E
Promotion                              = DEPLOYED / OWNER + E2E
Full browser E2E                       = OPEN
```

## OWNER SURGERY LOCATION — COMMISSION
Target only:
`erp-frontend/companies/company-1/main.html`

Exact Current Source locations verified:
- Finance navigation: source line `1147`.
- `renderSubTab(subTab)` starts at approximately source line `10399`; Finance tab list item is at source line `10409`.
- Commission dispatch follows the existing `installments` dispatch around source line `10425`.
- Insert the full Commission UI/helper block immediately before exact source line `12299`: `function _renderBudgets() {`.
- Finance export tail is near the end of `RW_Finance`, around source line `12885+`.

Complete surgical instructions are in:
`doc/Draft/Reprots/Report172_COMMISSION_ENGINE_GOLD_CLOSURE_20260914.md`

## NEXT ASSISTANT RESUMPTION RULE
لا تبدأ من Report172 كحالة حالية؛ ابدأ من المصادر الحالية.

`CURRENT GIT HEAD`
`-> DIRECT PARENT`
`-> CURRENT MASTER main.html`
`-> CURRENT DATABASE`
`-> CURRENT FUNCTIONS`
`-> CURRENT EDGE DEPLOYMENT`
`-> CURRENT REALTIME`
`-> CURRENT RLS / TRIGGERS / CONSTRAINTS`
`-> CURRENT PRODUCTION DATA`
`-> CURRENT BROWSER / CONSOLE`

ثم:
`historical contract -> current behavior -> actual gap -> surgical change -> test -> deploy -> Production verify -> runtime verify -> document -> close`

لا تعيد إصلاح ما ثبت إغلاقه.
لا تجعل التقرير بديلًا عن Production evidence.
لا تستخدم `Current/PWA/main2` أو `New-main` كـSource of Truth.
لا تعتبر وجود Backend مساويًا لـBrowser E2E closure.
