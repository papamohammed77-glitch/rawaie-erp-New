# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-13  
**Checkpoint:** Report161 — CTO E2E للنظام الأم ومراجعة Sales Gold/Diamond وإغلاق Backend المرتجع + Credit Note.

## GOVERNANCE
التقارير السابقة Historical/Reference فقط وليست حالة حالية.
الحالة المعتمدة فقط:
`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`.

**المبدأ الحاكم — اقرأه بعناية:** ملف النظام الأم الحالي المنشور هو Source of Truth، وأي Closure يجب أن يبدأ من الواقع الحالي ولا يعيد إصلاح شيء ثبت إغلاقه.

## SOURCE OF TRUTH
Repository: `papamohammed77-glitch/erp-frontend`  
Path: `companies/company-1/main.html`  
Ref: `main`

`Current/PWA/main2/*`, `Original/PWA/main/*`, `Current/PWA/New-main` = Historical/Reference فقط.

## CURRENT GIT
HEAD:
`3573c92026557cb56a7782babe6f6cf690243072`

Direct parent:
`28f39b351bb44a4cd885ba784d505aadaeb13cf1`

HEAD message: `Update main.html`

HEAD patch يثبت أن آخر تغيير في Parent main كان إصلاح عرض فرع التحويل من `branch_name` إلى `name`/`branch_code`. هذا CLOSED ولا يعاد فتحه دون Browser/Runtime evidence جديد.

Current main.html blob SHA:
`43ab5c85ee63939404a0c426524f92e406441f07`

Current main.html last known line:
`35521`

## FORENSIC ASSEMBLY
`forensic_main_assembly.yml` صحيح:
```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
assembly_status: reference_only; published_main_is_authoritative
```

لا تعديل مطلوب.

## CURRENT PRODUCTION / DATABASE
Project: `fiilmooggumokxanwiyx`

Fresh current counts:
- companies = 1
- branches = 2
- items = 17
- customers = 3
- orders = 0
- runsheets = 0
- stock_vouchers = 0
- inventory_log = 3
- credit_notes = 0
- installments = 0
- installment_details = 0
- loyalty_points = 0
- coupons = 0

Current schema facts:
- `items.item_code` = UNIQUE globally.
- `orders` has canonical unique `(company_id, operation_id)` index after removing a redundant duplicate index.
- `credit_notes.operation_key` now exists and is unique per company when present.

## INVENTORY CORE — DO NOT REOPEN
Physical Stock contract:
`Physical Movement → post_stock_movement → stock_branches + inventory_log`

Previously closed:
`Physical Writers outside post_stock_movement = 0`

Do not reopen Inventory Writer closure without fresh contradictory CURRENT evidence.

## PARENT SYSTEM / APPS
Parent main = Control / Oversight / Integration / Administration / Monitoring / Exceptions / Analytics.

Separate apps = Operational Execution, including POS, Telesales, Order Taker, Van Sales, Picking, Loading, Delivery, Return, Unloading, Receiving, Inventory Count and related workflows.

Do not move operational execution to main just to increase tab count.

## CURRENT SALES NAVIGATION
Current Sales navigation in parent main contains:
- التلي سيلز
- العملاء
- المتجر الإلكتروني
- نقطة البيع
- أوردرات المبيعات
- الرانشيتات

There is no current independent parent UI proven for Quotes, Price Lists, Promotions, Sales Returns, Payments, Installments, Commissions, Targets or Loyalty.

## CURRENT SALES BACKEND
Production functions currently relevant include:
- `save_sales_invoice_atomic`
- `complete_return_atomic`
- `complete_order_delivery_atomic`
- `post_cash_payment_atomic`
- `delete_order_atomic`
- `submit_online_order_atomic`
- `append_orders_to_runsheet_atomic`

No independent current Production engine is proven for Quote / Price List / Promotion / Commission / Target / Loyalty.

## SALES RETURN + CREDIT NOTE — NEW CURRENT CLOSURE
Production closure implemented in this session:

`complete_sales_return_credit_note_atomic`

Contract:
`authenticated user → company context → idempotent operation key → complete_return_atomic → post_stock_movement → Credit Note → audit`

Current Edge versions:
- `create-credit-note` = v3
- `complete-return` = v26

Both now call the unified atomic transaction.

Current Git canonical backend artifacts:
- `supabase/migrations/20260913_unify_sales_return_credit_note_atomic.sql`
- `Current/Edge_Functions/create-credit-note`
- `Current/Edge_Functions/complete-return`

Runtime test proved:
- first return = success / duplicate false;
- same exact retry = success / duplicate true;
- same Credit Note returned;
- test data completely cleaned.

Therefore:
`Sales Return + Credit Note Backend Transaction = CLOSED`

But:
`Parent Sales Returns UI = OPEN`

## SALES GAP STATUS
```text
Quote lifecycle                        = OPEN
Price List engine                      = OPEN
Promotion engine                       = OPEN
Unified Sales Return/Credit Note UI    = BACKEND CLOSED / UI OPEN
Multiple/Partial Sales Payments        = OPEN
Installment lifecycle                  = OPEN
Commission engine                      = OPEN
Targets engine                         = OPEN
Loyalty engine                         = OPEN
Full Sales Decision Center             = OPEN
Browser Click-by-Click E2E             = OPEN
```

## ITEM OFFERS CONTRACT
Current Item Modal contains item-level fields:
`discount_percent`, `discount_start`, `discount_end`, `is_daily_deal`, `badge_text`.

These remain valid for item-level merchandising / quick offer behavior.

They are NOT a full Promotion Engine.

Future Promotion Engine must be separate and support scope/rules such as item/category/customer/branch, date/time, quantity, priority and stacking.

## SALES RETURNS / PURCHASE RETURNS RULE
`Sales Returns` should be a parent Sales management/monitoring view that shows returns executed by POS/field operational apps and links back to order/runsheet/credit note/accounting.

`Purchase Returns` belongs under Purchases, not Sales, and should centrally display supplier return activity from operational applications.

## OWNER FRONTEND WORK — NOT EXECUTED BY ASSISTANT
### POS idempotency
File:
`erp-frontend/companies/company-1/main.html`

Function:
`RW_POS.save()`

Current area:
~line `22750`.

Replace the current `var orderHeader = { ... };` block whose first property is `operation_id: crypto.randomUUID()` with:
```javascript
var operationId = window.__rwPosOperationId || null;
if (!operationId) {
    operationId = crypto.randomUUID();
    window.__rwPosOperationId = operationId;
}

var orderHeader = {
    operation_id: operationId,
    custId: cust,
    custName: customer ? customer.name : '',
    area: customer ? customer.area : '',
    total: total,
    deliveryFees: del,
    status: 'Invoiced',
    paymentType: 'نقدي',
    taxAmount: taxAmt,
    taxRate: taxRate
};
```
Last line to delete = `};` of this orderHeader block.

After the existing successful `cart = [];` add:
```javascript
window.__rwPosOperationId = null;
```
Do not clear on error.

### Telesales idempotency
File:
`erp-frontend/companies/company-1/main.html`

Function:
`RW_TeleSales._saveOrder()`

Current area:
~line `23740`.

Replace the `var orderHeader = { ... };` block whose first property is `operation_id: crypto.randomUUID()` with:
```javascript
var operationId = window.__rwTeleSalesOperationId || null;
if (!operationId) {
    operationId = crypto.randomUUID();
    window.__rwTeleSalesOperationId = operationId;
}

var orderHeader = {
    operation_id: operationId,
    customer_code: selectedCustomer.customer_code,
    custName: selectedCustomer.name,
    area: selectedCustomer.area || '',
    total: total,
    deliveryFees: deliveryFee,
    status: 'Confirmed',
    paymentType: selectedCustomer.payment_type || 'أجل',
    taxAmount: taxAmt,
    taxRate: taxRate
};
```
After the existing successful cart/customer reset add:
```javascript
window.__rwTeleSalesOperationId = null;
```
Do not clear on error.

## NO REOPEN
Do not rework without fresh evidence:
- Transfer branch_name fix.
- Inventory Writer Zero-Debt closure.
- `post_stock_movement` centralization.
- Runsheet/Picking/Loading/Delivery backend closures already closed.
- `save_sales_invoice_atomic` merely because frontend idempotency is open.
- `complete_return_atomic` core merely because unified wrapper now exists.

## DAFTRA CURRENT REFERENCE
Current official Daftra material confirms Sales capabilities including:
- invoices and Quotes;
- POS;
- Offers;
- Price Lists;
- Installments;
- Sales Targets and Commissions;
- Loyalty;
- flexible/partial/multiple payments and returns/credit-related flows.

RAWAEA is differentiated by the operational field-sales / runsheet / picking / loading / delivery / return chain, but the institutional Sales management layer remains incomplete.

## CURRENT E2E STATUS
```text
Current Git / Parent              = VERIFIED
Current main.html                 = VERIFIED
Current Production                = VERIFIED
Current DB schema/data             = VERIFIED
Current Edge deployments          = VERIFIED
forensic_main_assembly.yml        = VERIFIED / NO CHANGE
Sales Return backend transaction  = CLOSED
Parent Sales Returns UI           = OPEN
POS/Telesales idempotency         = OWNER ACTION OPEN
Browser click-by-click E2E        = OPEN
Sales Gold/Diamond                = OPEN
```

## LATEST RAWARE-ERP-NEW COMMITS
Latest session commits added after Report160:
- `4d26f2c3a7e9facd577aaabeab9a5ff112cf09d7` — unified return/credit note migration
- `c510c0f87cade0934127f92b5a3f14c8296ca93d` — canonical create-credit-note
- `049dd56d210389b5c873163ddfce32b60bb27693` — canonical complete-return
- `16f15412218fbe2350abc8dfc7b407db2ab760e5` — Report161

These are backend/governance artifacts. They do not replace the parent Source of Truth.

## HISTORICAL / REFERENCE REPORTS
Report160 remains historical pointer only.
Report161 is the latest session execution record.
Do not treat either report as a substitute for a fresh Production reconciliation.

## NEXT EXACT SEQUENCE
```text
CURRENT GIT HEAD
→ DIRECT PARENT
→ NEW COMMITS
→ CURRENT main.html SHA
→ CURRENT assembly path
→ CURRENT DB schema/data
→ CURRENT Edge versions/source
→ CURRENT PostgreSQL RPC definitions
→ CURRENT runtime/log evidence
→ classify VERIFIED / STALE / CONTRADICTED / UNKNOWN
→ Owner applies POS idempotency
→ Owner applies Telesales idempotency
→ reread current main.html
→ Browser retry E2E
→ Production operation_id verification
→ close idempotency
→ Sales Document / Quote contract
→ Pricing / Promotion
→ Payments
→ Installments
→ Commissions / Targets
→ Loyalty
→ Sales Decision Center
→ final Browser E2E
```

## PERMANENT RULE
`REPORT = POINTER`
`PRIMARY SOURCE = AUTHORITY`
`CURRENT PRODUCTION = TRUTH`
`NO ASSUMPTION`
`NO SPECULATIVE UI`
`NO DUPLICATE ENGINE`
`ONE CLOSURE AT A TIME`
`CLOSE → VERIFY → DOCUMENT → NEXT`
