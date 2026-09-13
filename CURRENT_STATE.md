# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-13
**Checkpoint:** Report160 — CTO Forensic E2E للنظام الأم ومراجعة المبيعات Gold / Diamond.

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

**Fresh Production row counts from this reconciliation:**
- `companies`: 1
- `branches`: 2
- `items`: 17
- `customers`: 3
- `orders`: 0
- `runsheets`: 0
- `stock_vouchers`: 0
- `inventory_log`: 3
- `credit_notes`: 0
- `installments`: 0
- `loyalty_points`: 0
- `coupons`: 0

`items.item_code` is globally UNIQUE in the current schema.
`orders.operation_id` exists and is used as Sales operation identity.

Do not reuse row counts from stale reports.

## INVENTORY CORE
Physical Stock contract:
`Physical Movement → post_stock_movement → stock_branches + inventory_log`

Production discovery previously proved:
`Physical Writers outside post_stock_movement = 0`

`reserve_stock` and `release_stock_reservation` are reservation-only.
`setup_van_stock` / `create_vehicle_atomic` initialize stock rows and are not movement writers.

**Inventory Physical Writer Zero-Debt = CLOSED.**

Do not reopen this closure without fresh CURRENT evidence.

## TRANSFER E2E
Production transfer backend closure is already closed and must not be reworked without new evidence.

## FRONTEND TRANSFER STATUS
Current Source of Truth has the historical `branch_name` defect removed.
No assistant modification was made to `erp-frontend/companies/company-1/main.html`.

Browser click-by-click E2E remains **NOT VERIFIED** because no Browser Automation channel is available.

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

Current `RW_TeleSales` exists with customer/item search, branch selection, cart, stock availability checks, delivery fee, tax and save order.

Current `RW_Orders` exists for sales order management, filtering, confirmation/deletion and runsheet linkage. It also subscribes to realtime changes on `orders`, `order_details`, and `app_settings`.

## CURRENT SALES DEPLOYMENTS
Fresh Production Edge enumeration:
- `save-sales-invoice` v15, JWT required
- `confirm-order` v4, JWT required
- `update-order` v3, JWT required
- `create-credit-note` v2, JWT required
- `complete-return` v25, JWT required

`complete-return` v25 authenticates the user, derives company through `users.auth_id`, then forwards to `complete_return_atomic`.

## CURRENT SALES DATABASE CONTRACTS
### `save_sales_invoice_atomic`
Current Production function:
- requires Sales `operation_id`;
- detects duplicates through `orders.operation_id`;
- resolves customer and branch inside company context;
- creates the order and order details;
- calls `post_stock_movement` for Invoiced physical stock;
- posts cash receipt or AR/accounting according to payment type;
- posts customer ledger for credit sales;
- posts driver ledger for Van Sales credit operations.

### `complete_return_atomic`
Current Production function provides the current unified return transaction foundation:
- operation registry/idempotency;
- authenticated company context;
- order/runsheet validation;
- order detail return ceiling;
- driver liability;
- `post_stock_movement` for good returns;
- journal entry;
- customer ledger;
- order status adjustment;
- runsheet aggregation;
- operation completion.

### `create-credit-note` v2
Current Edge capability validates company/order/runsheet/detail/quantity and writes a `credit_notes` header. It is **not yet proven as an atomic unified Sales Return + Credit Note transaction** with `complete_return_atomic`.

## CURRENT SALES GAPS — PROVEN IN CURRENT SOURCE / PRODUCTION
Current Sales navigation and source do not contain independently proven complete UI/business contracts for:
- عروض الأسعار
- قوائم الأسعار
- العروض والتسعير المتقدم
- عمولات المبيعات
- أهداف المبيعات
- أقساط المبيعات
- واجهة ولاء
- Sales Returns / Credit Notes as an independent Sales management path

The database contains foundations for some of these (`credit_notes`, `installments`, `installment_details`, `loyalty_points`, `coupons`) but table existence is not proof of a complete transactional/UI contract.

## FRONTEND OWNER DEFECT — SALES IDEMPOTENCY
The current `RW_POS.save()` creates `operation_id: crypto.randomUUID()` inside each save attempt.
The current `RW_TeleSales._saveOrder()` does the same.

This can create a new operation identity after a timeout/retry instead of retrying the same Business Operation.

**Required owner change:** persist one Operation ID across the active Save/Retry lifecycle and clear it only after confirmed success.

Exact surgical replacements and full replacement blocks are documented in:
`doc/Draft/Reprots/Report160_CTO_E2E_Main_Sales_Gold_Diamond_Forensic_20260913.md`

## DAFTRA SALES COMPARISON
Current forensic comparison confirms Daftra documents a broader institutional Sales suite, including:
`Quote → Sales Order → Invoice`, Price Lists, Offers/Discounts, Multiple/Partial Payments, Installments, Targets, Commissions, Loyalty and Refund/Credit Note capabilities.

RAWAEA is stronger/differentiated in its operational field-sales/run-sheet/fulfillment architecture, but Sales Gold/Diamond is still OPEN because the institutional management layer is not yet complete.

## SALES CLOSURE ORDER
Execute one closure unit at a time:

1. POS/Telesales retry idempotency — owner applies the exact surgical changes in Report160, then browser + Production verify.
2. Sales Document Contract — prove Quote → Order → Invoice semantics from current Production before adding Quote UI.
3. Sales Return/Credit Note — reconcile `complete_return_atomic`, `complete-return` v25 and `create-credit-note` v2 and create one coherent transaction contract.
4. Sales Pricing — establish Price List + Promotion contract.
5. Sales Payment — establish multiple/partial payment and reconciliation contract.
6. Installments — prove lifecycle and ledger reconciliation.
7. Commissions/Targets — prove periods, rules, returns impact, approval and payment.
8. Loyalty — prove earn/redeem/expiry/rollback.
9. Sales Analytics / Decision Center — build only after transaction contracts are closed.

## DATA GOVERNANCE
Never use stale report counts as current state.
Never fabricate Production data to make an E2E pass.
Never remove historical or test data without proof.
Never reopen closed Inventory Writer or Transfer backend closures without new evidence.

## CURRENT E2E STATUS
`Current Git / Parent = VERIFIED`
`Current main.html = VERIFIED`
`forensic_main_assembly.yml = VERIFIED / NO CHANGE REQUIRED`
`Current Production Database = VERIFIED`
`Current Sales Edge deployments = VERIFIED`
`Sales source forensic gaps = VERIFIED`
`Browser click-by-click E2E = OPEN`
`Sales Gold/Diamond = OPEN`

## SESSION ARTIFACT
Primary report:
`doc/Draft/Reprots/Report160_CTO_E2E_Main_Sales_Gold_Diamond_Forensic_20260913.md`

Report commit:
`3cbcc3aad967f5a9950699c58e1421d035c49e98`

## FINAL NEXT-CTO START SEQUENCE
ابدأ من الواقع، لا من التقارير:

`CURRENT GIT HEAD`
`→ DIRECT PARENT`
`→ NEWER COMMITS AFTER THIS CHECKPOINT`
`→ CURRENT SOURCE OF TRUTH`
`→ CURRENT DB SCHEMA`
`→ CURRENT DB DATA`
`→ CURRENT EDGE DEPLOYMENT / SOURCE / VERSION`
`→ CURRENT RUNTIME / LOG EVIDENCE`
`→ REPRODUCE EXACT SYMPTOM`
`→ CLASSIFY VERIFIED / STALE / CONTRADICTED / UNKNOWN`
`→ HISTORICAL RECONSTRUCTION`
`→ IDENTIFY EXACT GAP`
`→ ONE CLOSURE UNIT`
`→ SURGICAL IMPLEMENTATION`
`→ REREAD CURRENT SOURCE`
`→ PRODUCTION VERIFY`
`→ RUNTIME VERIFY`
`→ SECURITY / AUDIT VERIFY`
`→ UPDATE REPORT + CURRENT_STATE`
`→ NEXT UNIT ONLY AFTER CLOSURE

### Hard rules
- لا تثق في أي تقرير سابق كحالة حالية.
- لا تستخدم `main2` كمصدر حقيقة.
- لا تعيد إصلاح شيء مثبت أنه مغلق.
- لا تنشئ UI شكليًا فوق table أو function بلا contract مثبت.
- لا تحول Backend PASS إلى Browser PASS.
- لا تجمع عدة Closure Units في دفعة واحدة.
- لا تستخدم نسب اكتمال قبل Production reconciliation.
- أي Unknown مؤثر = Evidence Work، وليس تخمينًا.

**Current truth first → Contract → Gap → Surgical Fix → Test → Deploy → Production Verify → Runtime Verify → Close.**
