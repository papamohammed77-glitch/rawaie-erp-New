# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-13
**Checkpoint:** Report159 — CTO Forensic E2E للنظام الأم ومقارنة إدارة المبيعات مع دفترة.

## GOVERNANCE
التقارير السابقة Historical/Reference فقط وليست حالة حالية.
الحالة المعتمدة هي فقط:
`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`.

**الهدف الحاكم — يُقرأ بعناية:** ملف النظام الأم الحالي المنشور هو Source of Truth، والمهمة هي التحقق الجنائي من حالته الحالية وإكماله وظيفيًا دون إعادة إصلاح ما ثبت إغلاقه.

## SOURCE OF TRUTH
Repository: `papamohammed77-glitch/erp-frontend`
Path: `companies/company-1/main.html`
Ref: `main`

`Current/PWA/main2/*` و`Original/PWA/main/*` وNew-main = Historical/Reference فقط.

## CURRENT GIT
HEAD:
`3573c92026557cb56a7782babe6f6cf690243072`

Direct parent:
`28f39b351bb44a4cd885ba784d505aadaeb13cf1`

HEAD message: `Update main.html`

HEAD current main.html contains the already-fixed Transfer query:
`.select('id, branch_code, name')`

The previous `branch_name` Transfer defect is therefore **CLOSED in CURRENT GIT**. Do not re-patch it unless fresh served-browser evidence proves an older asset is being served.

Current `main.html` was read through EOF; last line = `35521`.

## FORENSIC ASSEMBLY
`rawaie-erp-New/forensic_main_assembly.yml` is correct and requires no change:
```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
assembly_status: reference_only; published_main_is_authoritative
```

## CURRENT PRODUCTION / DATABASE
Project: `fiilmooggumokxanwiyx`

Latest direct Production schema enumeration in this checkpoint shows the current database is materially different from older reports; do not reuse historical row counts.

Current structural facts:
- `companies`: 1
- `branches`: 2
- `items`: 17
- `customers`: 3
- `orders`: 0
- `runsheets`: 0
- `stock_vouchers`: 0
- `inventory_log`: 3
- `credit_notes`: table exists
- `installments`: table exists
- `installment_details`: table exists
- `loyalty_points`: table exists
- `coupons`: table exists
- `fulfillment_backorders`: table exists
- `orders.operation_id`: present for sales operation identity

`items.item_code` is globally UNIQUE in the current schema.

Do not infer Company-scoped item-code identity against this current schema.

## INVENTORY CORE
Physical Stock contract:
`Physical Movement → post_stock_movement → stock_branches + inventory_log`

Production discovery proves:
`Physical Writers outside post_stock_movement = 0`

`reserve_stock` and `release_stock_reservation` are reservation-only.
`setup_van_stock` / `create_vehicle_atomic` initialize stock rows and are not movement writers.

**Inventory Physical Writer Zero-Debt = CLOSED.**

Do not reopen this closure without fresh CURRENT evidence.

## TRANSFER E2E
Production transactional test already closed the backend transfer path:
`BR-01 → BR-2 → item 1001 → create_manual_stock_voucher_atomic → send_stock_voucher_atomic`

Result:
`create=success`
`send=success`
`status=Sent`
`movement_count=1`

Second SEND returned `duplicate=true`.
Test transaction was rolled back.

**Transfer backend = CLOSED / PRODUCTION VERIFIED.**

## FRONTEND TRANSFER STATUS
Current Source of Truth has the historical `branch_name` defect removed.
No assistant modification was made to `erp-frontend/companies/company-1/main.html`; frontend remains owner-managed.

Browser click-by-click E2E is **NOT VERIFIED** in this environment because no Browser Automation channel is available.

## CURRENT SALES FORENSICS
Current Sales Navigation contains exactly:
- التلي سيلز
- العملاء
- المتجر الإلكتروني
- نقطة البيع
- أوردرات المبيعات
- الرانشيتات

Current `RW_POS` exists and saves invoices through `save-sales-invoice`.
The current source explicitly sets POS save header `status: 'Invoiced'` and `paymentType: 'نقدي'`.

Current `RW_TeleSales` exists with customer/item search, cart, delivery fee, tax and save order.

Current `RW_Orders` exists for sales order management and runsheet linkage.

Current Sales Navigation has no independently proven view for:
- عروض الأسعار
- قوائم الأسعار
- العروض/التسعير المتقدم
- عمولات المبيعات
- أهداف المبيعات
- أقساط المبيعات
- واجهة ولاء
- مرتجعات وإشعارات دائنة كمسار Sales مستقل

The database contains foundations for several of these capabilities, but UI/transaction contracts are not automatically proven by table existence.

## CURRENT SALES DEPLOYMENTS
Current Production Edge deployments observed:
- `save-sales-invoice` v15, JWT required
- `confirm-order` v4, JWT required
- `update-order` v3, JWT required — **updated in Report159**
- `create-credit-note` v2, JWT required — **updated in Report159**
- `complete-return` v25, JWT required

`save-sales-invoice` currently supports operation identity from request/header/body and forwards to `save_sales_invoice_atomic`.

`complete-return` currently obtains the authenticated user's company and forwards to `complete_return_atomic`.

## REPORT159 PRODUCTION CHANGES
### `update-order`
Production moved from v2 to v3.

The current function now enforces:
- authenticated actor company context;
- company-scoped order lookup;
- company-scoped customer lookup;
- company-scoped branch lookup;
- global Item Master identity via `item_code` + returned item record;
- duplicate item-code rejection inside one update request;
- no update of orders already attached to a runsheet.

### `create-credit-note`
Production moved from v1 to v2.

The current function now enforces:
- authenticated actor company context;
- company-scoped order lookup;
- company-scoped runsheet lookup;
- order/runsheet consistency;
- order-detail item membership and return-quantity ceiling;
- explicit `credit_notes.company_id` write.

These were Production changes only; no business data fixtures were created.

## SALES COMPETITOR FORENSICS
The current source/production comparison against Daftra showed that RAWAEA already has the operational foundation but is not yet a complete institutional sales suite.

Daftra documents:
`Quote → Sales Order → Invoice`
with direct/optional starting points, plus price lists, offers, sales targets, commissions, loyalty, installments, multiple/partial payments, and full/partial refunds.

RAWAEA current source does not prove all of those UI/business contracts yet.

**Sales Gold/Diamond is therefore OPEN.**

## FRONTEND SURGICAL RULE
`erp-frontend/companies/company-1/main.html` must be edited only by the owner.

No assistant change was committed to that file in Report159.

The only currently safe owner-facing frontend change identified is to expose Sales Returns in the Sales navigation **only after** the exact return UI is wired to the already-deployed return transaction contract. Do not add a dead navigation item.

No new Quotes/Price Lists/Commission/Installment/Loyalty UI should be invented from table names alone.

## SALES CLOSURE ORDER
Next closures should be executed one at a time:

1. Sales Document Contract — prove whether `orders` is the authoritative Sales Order document and define Quote→Order→Invoice semantics against current Production.
2. Sales Return/Credit Note — extract and verify `complete_return_atomic`, reconcile with `complete-return` and `create-credit-note`, then add a real Sales Return/Refund UI.
3. Sales Pricing — establish Price List + Promotion contract before changing POS/Telesales pricing behavior.
4. Payment — establish multiple/partial payment and accounting reconciliation contract before UI work.
5. Installments — prove lifecycle and ledger/reconciliation before UI.
6. Commissions/Targets — prove period/rep/rule/approval/payment lifecycle before UI.
7. Loyalty — prove earn/redeem/expiry/reference lifecycle before UI.
8. Sales Analytics — build sales-specific decision reports after the transaction contracts are closed.

## DATA GOVERNANCE
Never use stale report counts as current state.
Never fabricate Production business data to make an E2E pass.
Never remove historical or test data without current proof of fixture status.
Never re-open Inventory Writer Zero-Debt or Transfer backend closures without new evidence.

## CURRENT E2E STATUS
`Static forensic source review = CLOSED`
`Production deployment verification = CLOSED for changes listed above`
`Browser click-by-click E2E = OPEN`
`Sales functional Gold/Diamond = OPEN`
`Sales Document Contract = OPEN`
`Sales Pricing Contract = OPEN`
`Sales Payment Contract = OPEN`

## FINAL NEXT-CTO START SEQUENCE
ابدأ دائمًا من الواقع وليس من التقارير:

`CURRENT GIT HEAD`
`→ DIRECT PARENT`
`→ PARENT OF PARENT when material`
`→ CURRENT SOURCE OF TRUTH`
`→ CURRENT DB SCHEMA`
`→ CURRENT DB DATA`
`→ CURRENT EDGE DEPLOYMENTS / SOURCE / VERSION`
`→ CURRENT RUNTIME / LOG EVIDENCE`
`→ REPRODUCE EXACT SYMPTOM`
`→ IDENTIFY EXACT FUNCTION / LINE / QUERY`
`→ HISTORICAL RECONSTRUCTION TO EXPLAIN CONTRACT`
`→ IDENTIFY ACTUAL GAP`
`→ ONE SURGICAL CLOSURE UNIT`
`→ REREAD CURRENT SOURCE`
`→ PRODUCTION TRANSACTIONAL VERIFY`
`→ RUNTIME VERIFY`
`→ AUDIT / SECURITY VERIFY`
`→ REPORT + CURRENT_STATE`
`→ NEXT UNIT ONLY AFTER CLOSURE`

### لا تكسر هذه القواعد
- لا تعتبر أي تقرير قديم حالة حالية.
- لا تستخدم `main2` كمصدر حقيقة.
- لا تعيد إصلاح شيء مثبت أنه مغلق.
- لا تخترع Production data لإنجاح الاختبار.
- لا تحول Backend PASS إلى Browser PASS.
- لا تجمع عدة Function/Writer closures في دفعة واحدة.
- لا تبني UI فوق جدول أو اسم function دون إثبات Consumer/transaction contract.
- لا تستخدم نسبة اكتمال قبل مطابقة Production الحالية في نفس التحقيق.

**الحقيقة الحالية أولًا، ثم العقد، ثم الفجوة المثبتة، ثم الإصلاح الجراحي، ثم التحقق، ثم الإغلاق.**
