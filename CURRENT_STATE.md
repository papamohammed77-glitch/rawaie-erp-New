# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-13
**Current checkpoint:** Report162 — CTO Forensic Reconciliation للنظام الأم واختبار E2E/Source/Production.

## GOVERNANCE — اقرأ هذه القاعدة أولًا

التقارير السابقة Historical/Reference فقط وليست حالة حالية.

الحالة المعتمدة فقط:
`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

**Source of Truth الحالي هو:**
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

لا تعاد أي Closure أغلقت، إلا بدليل CURRENT متناقض.

القاعدة الدائمة:
`REPORT = POINTER`
`PRIMARY SOURCE = AUTHORITY`
`CURRENT PRODUCTION = TRUTH`
`NO ASSUMPTION`
`NO SPECULATIVE UI`
`NO CLOSED-CLOSURE REOPEN`
`ONE CLOSURE AT A TIME`
`CLOSE → VERIFY → DOCUMENT → NEXT`

## SOURCE OF TRUTH

Repository: `papamohammed77-glitch/erp-frontend`
Path: `companies/company-1/main.html`
Ref: `main`

Current main.html blob SHA:
`1cc6f17b8531a8353b28f89acdfde2e992774931`

`Current/PWA/main2/*`, `Original/PWA/main/*`, `Current/PWA/New-main` = Historical/Reference فقط.

## CURRENT GIT

Current HEAD:
`aaebffbdd732b9861d96631f5d01c5a6697bd1e4`

HEAD message:
`Refactor orderHeader creation with operation IDs`

Direct Parent:
`3573c92026557cb56a7782babe6f6cf690243072`

Parent of Parent:
`28f39b351bb44a4cd885ba784d505aadaeb13cf1`

آخر HEAD patch في `main.html` يحتوي إصلاح Operation Identity في:
- `RW_POS.save()`
- `RW_TeleSales._saveOrder()`

وتصفير Operation ID يحدث فقط بعد نجاح العملية.

HEAD/Parent لا توجد لهما CI status checks منشورة؛ لا يسجل هذا كـCI PASS.

## FORENSIC ASSEMBLY

الملف المرجعي موجود في `rawaie-erp-New/forensic_main_assembly.yml`، ومحتواه الحالي يثبت:

```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
assembly_status: reference_only; published_main_is_authoritative
```

assembly SHA:
`7b3c6d64958cb729e86e26d6b743a7128ed05d9e`

**القرار:** المسار صحيح، ولا تعديل مطلوب.

## CURRENT PRODUCTION / DATABASE

Supabase project:
`fiilmooggumokxanwiyx`

Fresh counts:

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
- `stock_branches(branch_id,item_id)` = UNIQUE.
- `receiving.operation_id` = UNIQUE.
- `orders(company_id,operation_id)` = canonical unique operation identity.
- `credit_notes.operation_key` = unique per company when present.

## CURRENT DATA INTEGRITY

Fresh direct checks:

```text
stock_cross_company            = 0
inventory_log_cross_company    = 0
order_detail_item_cross_company= 0
duplicate_item_code_global     = 0
```

لا يوجد مبرر حالي لإعادة تنظيف هذه النقاط.

## INVENTORY CORE — CLOSED

Physical Stock contract:

`Physical Movement → post_stock_movement → stock_branches + inventory_log`

Fresh PostgreSQL writer discovery يثبت:

`Physical Writers outside post_stock_movement = 0`

`reserve_stock` و`release_stock_reservation` هما Reservation/Allocated Quantity فقط.

**لا تعاد Inventory Writer closure دون contradictory CURRENT evidence.**

## CURRENT EDGE DEPLOYMENTS

أهم النسخ الحالية:

```text
save-sales-invoice      = v15
complete-return         = v26
complete-order-delivery = v14
receive-purchase        = v12
create-stock-voucher    = v10
send-stock-voucher      = v20
receive-stock-voucher   = v22
bulk-stock-adjustment   = v6
create-credit-note      = v3
complete-picking        = v17
complete-loading        = v11
complete-delivery       = v4
start-return            = v4
unload-runsheet         = v6
```

Current operational functions are JWT-protected where applicable; known historical harness/canary endpoints returning 410 are not treated as production business paths.

## RECEIVE PURCHASE — CLOSED

Current RPC:
`receive_purchase_atomic(p_company_id uuid, p_po_code text, p_user_email text, p_items jsonb, p_operation_id uuid)`

Current `receive-purchase` Edge = v12.

Fresh transactional test:
- temporary PO/detail created inside transaction;
- first receiving executed;
- exact same `operation_id` retried;
- retry returned `success=true`, `duplicate=true`, `status=Received`;
- full transaction rolled back.

Therefore:
`Receive Purchase Idempotency = VERIFIED / CLOSED`

Test setup initially failed بسبب محاولة إدخال قيمة إلى `purchase_order_details.line_amount` وهو Generated Column. هذا كان خطأ Fixture فقط وتم تصحيحه.

## SALES RETURN / CREDIT NOTE — CLOSED BACKEND

Current backend contract:
`authenticated user → company context → operation identity → complete_return_atomic → post_stock_movement → credit note → audit`

Current Edge:
- `complete-return = v26`
- `create-credit-note = v3`

Runtime return retry was previously verified and current Production state remains consistent with that closure.

**Do not reopen `complete_return_atomic` without contradictory CURRENT runtime/DB evidence.**

## PARENT SYSTEM / APPS

Parent main role:
`Control / Oversight / Integration / Administration / Monitoring / Exceptions / Analytics`

Separate apps role:
`Operational Execution`

including POS, Telesales, Order Taker, Van Sales, Picking, Loading, Delivery, Return, Unloading, Receiving, Inventory Count and related workflows.

لا تنقل التنفيذ التشغيلي إلى Parent لمجرد زيادة عدد التبويبات.

## CURRENT MAIN FUNCTIONALITY

Current `main.html` has actual render paths for:

- Dashboard
- Items
- Customers
- Suppliers
- Branches
- Settings
- HR
- CRM
- Users / Roles / License
- Telesales
- POS
- Orders
- Runsheets
- Online Store
- Purchases / Purchase POS
- Receiving / Picking / Loading / Delivery / Return / Unloading
- Stock Vouchers / Transfer / Direct Sale / Direct Return / Supplier Return
- Vehicle / Branch / General Counts
- Settlement
- Finance
- Detailed / Comprehensive Reports
- Audit Log

Static source search found no literal `(قيد التطوير)` / `قيد التطوير` in the current published repository search result.

Current reports include real Production calls for finance/CRM/inventory/sales analytics. Tax reporting intentionally uses a Capability Gate where no authoritative Production tax source is proven.

## CURRENT SALES GAPS — OPEN

The following are genuine Business Contract gaps, not merely missing buttons:

```text
Sales Returns Parent Management UI           = OPEN
Quote lifecycle                               = OPEN
Price List engine                             = OPEN
Promotion engine                              = OPEN
Multiple / Partial Payment allocation        = OPEN
Installment lifecycle                         = OPEN
Commission engine                             = OPEN
Sales Targets engine                          = OPEN
Loyalty transaction engine                    = OPEN
Sales Decision Center                         = OPEN
Browser click-by-click E2E                    = OPEN
```

Item-level fields such as:
`discount_percent`, `discount_start`, `discount_end`, `is_daily_deal`, `badge_text`

remain valid item merchandising capabilities, but do not constitute a full Promotion Engine.

## DAFTRA CURRENT REFERENCE

Official Daftra material currently exposes Sales capabilities including Quotes, POS, Offers, Price Lists, Installments, Targets, Commissions, Loyalty and flexible/partial payment scenarios.

References:
- https://www.daftra.com/
- https://www.daftra.com/plans
- https://www.daftra.com/برنامج-المبيعات-وإدارة-الفواتير/
- https://docs.daftra.com/

RAWAEA must preserve its differentiated operational field-sales chain:
`Order → Runsheet → Picking → Loading → Delivery → Return → Unloading`

The current competitive gap is mainly institutional Sales Management contracts, not the operational app model.

## PARENT main.html OWNER STATUS

The latest Git commit already contains the POS/Telesales Operation Identity changes documented previously.

Current verified source areas:
- `RW_POS.save()` around source lines ~5020–5105.
- `RW_TeleSales._saveOrder()` around source lines ~6000–6085.

The current source contains the corrected blocks.

**No new surgical main.html patch was issued in Report162.**

Reason:
No contradictory current evidence justified another change.

The next main.html action is Browser E2E verification, not speculative surgery.

## BROWSER E2E STATUS

Browser click-by-click E2E remains OPEN.

This environment did not provide direct browser automation, so the following cannot honestly be marked PASS here:

- real browser navigation;
- clicking every tab;
- direct browser console monitoring;
- user-visible POS/Telesales retry from the browser.

Production/runtime/database/source verification is not equivalent to browser PASS.

## LATEST ACTIONS / REPORTS

Latest report written:
`doc/Draft/Reprots/Report162_CTO_E2E_Main_Forensic_Reconciliation_20260913.md`

Report161 remains historical pointer only.

## NEXT EXACT SEQUENCE

```text
CURRENT GIT HEAD
→ DIRECT PARENT
→ PARENT OF PARENT when needed
→ CURRENT main.html blob SHA
→ CURRENT forensic_main_assembly.yml
→ CURRENT Production schema
→ CURRENT Production data
→ Physical Writer Discovery
→ Current PostgreSQL RPC definitions
→ Current Edge source/version
→ Current runtime/log evidence
→ classify VERIFIED / STALE / CONTRADICTED / UNKNOWN
→ DO NOT reopen closed closures
→ Browser click-by-click E2E on CURRENT published main.html
→ Production operation_id verification
→ close Browser E2E gate
→ Sales Returns Parent Management UI
→ Quote contract
→ Price List contract
→ Promotion contract
→ Partial/Multiple Payment contract
→ Installment contract
→ Commission/Targets contracts
→ Loyalty contract
→ Sales Decision Center
→ final Browser E2E
```

## INSTRUCTIONS TO NEXT CTO / ASSISTANT

ابدأ دائمًا من Production/Git الحالي لا من التقرير.

لا تثق بأي نسبة أو حالة سابقة قبل إعادة المطابقة.

قبل أي تعديل أجب صراحة:

`ما العقد التاريخي؟`
`ما السلوك الحالي المثبت؟`
`ما الذي تغير؟`
`ما المطلوب أن يحكمه مستقبلًا؟`
`ما الدليل أن هذا Bug وليس Contract؟`

ثم:

`UNDERSTAND → TRACE → GAP → SURGICAL CHANGE → TEST → DEPLOY → PRODUCTION VERIFY → RUNTIME VERIFY → DOCUMENT → CLOSE`

وحدة واحدة فقط في كل مرة.

لا تنقل Operational execution إلى Parent.
لا تبنِ UI فوق Business Contract غير مثبت.
لا تعيد إصلاح شيء مغلق دون contradictory CURRENT evidence.

## FINAL STATE

```text
Current Git                         = VERIFIED
Current Parent / Parent chain      = VERIFIED
Current main.html                  = VERIFIED SOURCE
Current Database                   = VERIFIED
Current Edge Deployments           = VERIFIED
Inventory Physical Writer Core     = 100% CLOSED
Inventory Tenant/Item Integrity    = CLOSED / 0 violations
Receive Purchase Idempotency       = CLOSED / VERIFIED
Sales Return + Credit Backend      = CLOSED / VERIFIED
forensic_main_assembly.yml         = CORRECT / NO CHANGE
POS/Telesales source repair        = PRESENT / VERIFIED
Browser click-by-click E2E         = OPEN
Parent Sales Returns UI            = OPEN
Quote / Pricing / Promotions      = OPEN
Payments / Installments            = OPEN
Commissions / Targets              = OPEN
Loyalty / Decision Center          = OPEN
```
