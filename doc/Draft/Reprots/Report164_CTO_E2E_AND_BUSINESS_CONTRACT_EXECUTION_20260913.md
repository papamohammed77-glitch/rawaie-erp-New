# تقرير 164 — CTO Current-Reality + Browser E2E + Business Contracts Execution

**التاريخ:** 2026-09-13

## 0. الرسالة الحاكمة — اقرأها أولًا

**النقطة الأهم هي اختبار E2E بالنقر الحقيقي على ملف النظام الأم الحالي المنشور:**
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

لا يجوز تحويل فحص Source أو RPC أو Deployment إلى Browser E2E PASS.

وتُكرر القاعدة هنا صراحةً: **الهدف ليس مجرد توفر الأساسيات أو وجود تبويبات؛ الهدف هو أن تصبح وظائف النظام الأم مكتملة وظيفيًا وقابلة للتكامل مع التطبيقات التشغيلية، دون هدم العقود الميدانية التي تم بناؤها خلال المراحل السابقة.**

الحالة المعتمدة في هذا التقرير فقط هي ما ثبت من:
`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`.

التقارير السابقة pointers فقط، ولا يجوز أخذ أرقامها أو حالاتها كحقيقة حالية دون المطابقة المباشرة.

## 1. CURRENT GIT — VERIFIED

Repository: `papamohammed77-glitch/erp-frontend`

Branch: `main`

HEAD: `aaebffbdd732b9861d96631f5d01c5a6697bd1e4`

Message: `Refactor orderHeader creation with operation IDs`

Direct Parent: `3573c92026557cb56a7782babe6f6cf690243072`

Parent Message: `Update main.html`

Parent of Parent: `28f39b351bb44a4cd885ba784d505aadaeb13cf1`

HEAD diff ثبت مباشرة أنه غيّر `companies/company-1/main.html` فقط وفي نقطتين:
- `RW_POS.save()`
- `RW_TeleSales._saveOrder()`

الغرض المثبت هو الاحتفاظ بـ `operation_id` بعد فشل الاتصال حتى لا يؤدي Retry إلى عملية جديدة، ومسح الهوية بعد النجاح فقط.

تم فحص HEAD والـDirect Parent مباشرة، ولا يوجد سبب حالي لإعادة فتح هذه الجزئية.

## 2. CURRENT SOURCE OF TRUTH — VERIFIED

الملف الحاكم:
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

Blob SHA:
`1cc6f17b8531a8353b28f89acdfde2e992774931`

الملفات التاريخية/المرجعية فقط:
- `Current/PWA/main2/*`
- `Original/PWA/main/*`
- `Current/PWA/New-main`

`forensic_main_assembly.yml` يحدد الملف المنشور في `erp-frontend` كمصدر الحقيقة.

لا يوجد تعديل صادر في هذه المهمة على `main.html`.

## 3. CURRENT DATABASE — FRESH DIRECT EVIDENCE

المطابقة المباشرة في Production أظهرت أن Report163 أصبح STALE:

- Companies = 3.
- Company `00000000-0000-0000-0000-000000000001`: 23 users، فرع واحد، 17 items، 17 stock rows، 6 orders، 1 runsheet.
- Company `73a141bd-157a-4c2c-8693-34e21325b943`: مستخدم واحد، بلا فروع، 31 items، بلا orders/runsheets.
- Company `da4ef704-88ac-4120-aa0e-65b92b2aa2bc`: مستخدم واحد، 3 فروع، 2 items في دليل الشركة، 149 stock rows.

Current integrity findings:
- 143 صفًا في `stock_branches` يظهر فيها اختلاف Company بين Branch وItem.
- 86 حالة في `inventory_log` يظهر فيها اختلاف Company/Item.
- 6 حالات في `order_details` يظهر فيها اختلاف Company/Item.
- لم تظهر حالات مماثلة في `run_sheet_details` في الفحص الحالي.

الحكم: ممنوع حذف أو نقل هذه البيانات تلقائيًا؛ يجب أولًا تحديد ما إذا كانت Fixtures/Legacy أو بيانات تشغيلية حقيقية.

Schema facts المثبتة:
- `items.item_code` عليه UNIQUE عالمي.
- `stock_branches(branch_id,item_id)` عليه UNIQUE.
- `receiving.operation_id` عليه UNIQUE.
- `orders.operation_id` موجود.
- `credit_notes.operation_key` موجود.
- `audit_log` يعتمد على `fn_audit_trigger()` في مسار `stock_vouchers`.

## 4. CURRENT DEPLOYMENT EVIDENCE

تمت مطابقة النسخ الحالية مباشرة من Supabase، ومن النسخ التي تم فحصها:

- `send-stock-voucher` = v19
- `receive-stock-voucher` = v21
- `receive-purchase` = v9
- `save-sales-invoice` = v14
- `complete-return` = v23
- `complete-order-delivery` = v11
- `bulk-stock-adjustment` = v5

لا تستخدم أرقام تقرير 163 إذا اختلفت عن هذه النسخ الحالية.

## 5. CURRENT SOURCE FORENSICS

`RW_POS.save()` و`RW_TeleSales._saveOrder()` يحتفظان بهوية العملية في `window` حتى النجاح، ثم يمسحانها بعد النجاح فقط.

**الحكم: لا Patch.**

الـCurrent parent أيضًا يحتوي تشغيلًا مباشرًا لإدخال بعض العمليات المخزنية/الإدارية، ولذلك يجب عدم نقل التنفيذ الميداني من التطبيقات المنفصلة إلى Parent إلا بعقد موثق يثبت الحاجة.

## 6. BROWSER CLICK-BY-CLICK E2E

المطلوب هو E2E بالنقر الحقيقي على النسخة المنشورة الحالية.

لم تتوفر في هذه البيئة آلية authenticated browser automation موثوقة لتنفيذ login ثم click-by-click ثم correlation مع Console/Network/Production.

لم يتم ادعاء PASS.

**Browser E2E = OPEN / NOT VERIFIED**

## 7. BUSINESS CONTRACTS — CURRENT EXECUTION STATE

### Sales Returns Parent Management UI
OPEN.

Backend Return/Credit ليس بديلًا عن Parent Management Contract.
المطلوب إدارة ومراقبة المرتجعات المنفذة في التطبيقات التشغيلية، مع عدم نقل التنفيذ الميداني.
لم يصدر Patch لعدم وجود موضع Current مثبت بما يكفي لبناء تعديل جراحي آمن.

### Quote lifecycle
OPEN.

لا يوجد Domain Model كامل لعروض الأسعار في Production الحالية.
المطلوب:
`Draft → Sent → Accepted/Rejected/Expired/Cancelled → Converted`
مع Customer/Branch/Sales Rep/Item/Price/Discount/Tax/Source/Operation Identity snapshots، وAtomic conversion إلى Order.

تمت محاولة تنفيذ DDL عبر المسار الرسمي للمهاجرات، وتم حظره بواسطة platform security layer.
لا يوجد ادعاء نشر.

### Price List engine
OPEN.

لا يوجد Domain Model مؤسسي مستقل مثبت.
المطلوب: header/lines + scope + channel + dates + precedence + deterministic resolver + snapshot داخل transaction البيعية.

### Promotion engine
OPEN.

`coupons` ليست Promotion Engine مؤسسيًا.
المطلوب: campaign/rules/scope/effectivity/eligibility/stacking/limits/redemption/idempotency/snapshot.

### Multiple / Partial Sales Payment Allocation
OPEN.

لا يوجد Contract مؤسسي مكتمل لتوزيع دفعة جزئيًا وعلى عدة مستندات مع remaining balance.

### Installment lifecycle
OPEN.

`installments` و`installment_details` primitives جزئية، وليست lifecycle كاملًا للعقد والاستحقاق والتحصيل والتأخير والإقفال.

### Commission engine
OPEN.

لا يوجد Domain Model مؤسسي مستقل لقواعد واستحقاقات وتسويات العمولة.

### Sales Targets engine
OPEN.

لا يوجد Domain Model مؤسسي مستقل للأهداف والفترة والموظف/الفريق والقياس والحالة.

### Loyalty transaction engine
OPEN.

`loyalty_points` الحالي جزئي ولا يحتوي `company_id`؛ لذلك لا يمثل Ledger مؤسسيًا company-scoped.

### Sales Decision Center
OPEN.

لا يوجد Domain Model مستقل.
لا يجوز بناؤه كلوحة KPI شكلية قبل إغلاق العقود التي تغذيه.

## 8. PRODUCTION DDL GATE

Production DDL الجديدة لعقود المبيعات لم تُنشر لأن المنصة حظرتها بواسطة security checks.

لم يتم الالتفاف على الحاجز بطرق غير مصرح بها.

**Production Sales DDL = NOT DEPLOYED**

## 9. INVENTORY CLOSURE

لم تُفتح Inventory Core من جديد.

العقد الحالي يظل:
`Physical Movement → post_stock_movement → stock_branches + inventory_log`

المشكلات الحالية في data integrity سجلت كـreconciliation مستقلة، دون حذف أو إصلاح تخميني.

## 10. ERRORS / FAILED EXPERIMENTS

1. Report163 افترض حالة Production أصبحت غير صحيحة؛ تم تصحيح ذلك بأدلة Current مباشرة.
2. محاولة DDL المركبة لعقد Quote حُظرت من platform security.
3. إعادة بناء Operation Identity من mutable state مثل `qty_received` ليست هوية عملية سليمة؛ الهوية يجب أن تأتي من Consumer بشكل ثابت.
4. Browser E2E لم يُنفذ ولم يُسجل نجاح مزيف.

## 11. CURRENT MATRIX

| Closure | Status |
|---|---|
| Inventory Physical Writer Core | CLOSED / NOT REOPENED |
| POS Operation Identity | VERIFIED |
| Telesales Operation Identity | VERIFIED |
| Sales Return/Credit Backend | CLOSED |
| Sales Returns Parent UI | OPEN |
| Quote Lifecycle | OPEN |
| Price List | OPEN |
| Promotion | OPEN |
| Multiple/Partial Payment | OPEN |
| Installment Lifecycle | OPEN |
| Commission | OPEN |
| Sales Targets | OPEN |
| Loyalty Transactions | OPEN |
| Sales Decision Center | OPEN |
| Browser click-by-click E2E | OPEN / NOT VERIFIED |

## 12. FINAL SELF-AUDIT

### What I Proved

- HEAD والـDirect Parent والـParent of Parent.
- Current Source of Truth وBlob SHA.
- صحة mapping في `forensic_main_assembly.yml`.
- Current multi-company Production facts.
- Current cross-company anomaly counts.
- Current versions للـEdge Functions التي تم فحصها.
- صحة Operation Identity في POS/Telesales.
- Item global uniqueness وبعض operation identity constraints.

### What I Did Not Prove

- Browser click-by-click authenticated E2E.
- اكتمال Business Contracts المفتوحة.
- سلامة جميع cross-company anomalies.
- نشر عقود Quote/Price/Promotion/Payment/Installment/Commission/Targets/Loyalty/Decision Center.

### What I Fixed

- لم أعدّل `main.html` لعدم وجود gap مثبت يستحق إعادة فتح الـcurrent operation-id closure.
- أعيد بناء Current Reality من Production/Git بدل الاعتماد على Report163.

### What Could Still Be Wrong

- اختلاط Fixtures/Legacy مع بيانات تشغيلية في بعض company contexts.
- بقاء بعض wrappers ذات `LIMIT 1`.
- غياب العقود المؤسسية الجديدة في Production.
- غياب Browser E2E الموثق.

### Final Confidence

`CURRENT GIT/SOURCE = HIGH`

`CURRENT DATABASE = HIGH for directly queried facts; not a full global integrity certification`

`CURRENT DEPLOYMENT = HIGH for inspected functions`

`BROWSER E2E = NOT VERIFIED`

`BUSINESS CONTRACT COMPLETION = NOT ACHIEVED`

## 13. INSTRUCTIONS TO THE NEXT CTO / ASSISTANT

ابدأ دائمًا من:

`CURRENT GIT → DIRECT PARENT → CURRENT SOURCE → CURRENT PRODUCTION → CURRENT DATABASE → CURRENT DEPLOYMENTS → CURRENT RUNTIME`

ثم:

`historical contract → current behavior → target contract → actual gap → surgical design`

ثم:

`IMPLEMENT → TEST → DEPLOY → PRODUCTION VERIFY → RUNTIME VERIFY → DOCUMENT → NEXT`

واحدة فقط في كل مرة.

لا تثق في التقرير كحالة حالية.

لا تعيد Closure مثبتة إلا بدليل Current contradictory.

لا تنقل Operational execution من التطبيقات المنفصلة إلى Parent لمجرد اكتمال واجهة.

لا تبنِ Business Contract من UI فقط؛ يجب أن يمتلك Domain Model وIdentity وState وSecurity وAudit وAccounting حيث ينطبق.

لا تسجل Browser E2E PASS من Source/Deployment/DB evidence.

قبل أي Data Repair:
`reconstruct provenance → classify fixture/legacy/operational → verify downstream impact → repair atomically → re-query → document`

عند وجود Defect:
`FOUND → ROOT CAUSE → HISTORICAL REVIEW → SURGICAL FIX → TEST → DEPLOY → PRODUCTION VERIFY → RUNTIME VERIFY → CLOSE`

والهدف النهائي لا يتغير:
`FULL FUNCTIONAL COMPLETION + FULL INTEGRATION + FULL SECURITY + FULL AUDITABILITY + PRODUCTION VERIFIED + GOLD/DIAMOND`

## FINAL STATUS

```text
CURRENT GIT                 = VERIFIED
CURRENT SOURCE              = VERIFIED
CURRENT PARENT CHAIN        = VERIFIED
CURRENT DATABASE            = VERIFIED FOR DIRECTLY QUERIED FACTS
CURRENT DEPLOYMENTS         = VERIFIED FOR INSPECTED FUNCTIONS
INVENTORY CORE              = CLOSED / NOT REOPENED
POS/Telesales OP-ID         = VERIFIED
BUSINESS CONTRACTS          = OPEN
BROWSER E2E                 = OPEN / NOT VERIFIED
PRODUCTION SALES DDL        = BLOCKED BY PLATFORM SECURITY GATE
GOLD/DIAMOND                = NOT CLAIMED
```
