# تقرير 162 — CTO E2E Forensic Reconciliation للنظام الأم

**التاريخ:** 2026-09-13

## 0. الرسالة الحاكمة — اقرأها أولًا

**النقطة الأهم في هذه الجلسة هي اختبار E2E لملف النظام الأم الحالي المنشور:**

`https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/main.html`

لا يجوز اعتبار أي تقرير قديم حالة حالية. التقارير استخدمت كمؤشرات بحث فقط. الحالة المعتمدة في هذا التقرير هي فقط ما تم إثباته مباشرة من:

`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

ولا تُفتح Closure أُغلقت بالفعل إلا بدليل حالي متناقض.

---

## 1. حدود التحقيق ومصدر الحقيقة

### Source of Truth

Repository: `papamohammed77-glitch/erp-frontend`

Path: `companies/company-1/main.html`

Ref: `main`

Current main blob SHA:
`1cc6f17b8531a8353b28f89acdfde2e992774931`

الفحص الحالي للملف يثبت أن النسخة المنشورة تحتوي التعديلات الأحدث الخاصة بـ POS وTelesales، ولا يوجد مبرر حالي لإعادة إصلاحها.

الملفات التاريخية التالية بقيت مرجعًا فقط:

- `Current/PWA/main2/*`
- `Original/PWA/main/*`
- `Current/PWA/New-main`

### forensic_main_assembly.yml

تم فحص الملف في المستودع المرجعي `rawaie-erp-New`، وهو يشير صراحة إلى:

```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
assembly_status: reference_only; published_main_is_authoritative
```

الـassembly path صحيح. لا يوجد تعديل مطلوب.

---

## 2. Current Git — HEAD / Parent / Parent of Parent

تم فحص Git مباشرة.

### Current HEAD

`aaebffbdd732b9861d96631f5d01c5a6697bd1e4`

الرسالة:
`Refactor orderHeader creation with operation IDs`

التاريخ:
`2026-09-13T18:16:59Z`

### Direct Parent

`3573c92026557cb56a7782babe6f6cf690243072`

الرسالة:
`Update main.html`

التاريخ:
`2026-09-13T09:58:01Z`

### Parent of Parent

`28f39b351bb44a4cd885ba784d505aadaeb13cf1`

### HEAD diff

آخر Commit عدّل فقط `companies/company-1/main.html` وأضاف Operation Identity ثابتة نسبيًا أثناء المحاولة:

- `RW_POS.save()`
- `RW_TeleSales._saveOrder()`

ويتم تصفير الـOperation ID فقط بعد نجاح العملية.

هذا التعديل موجود فعليًا في Source الحالي، وليس مجرد تقرير.

### CI / Checks

لم توجد Status Checks منشورة على الـcommit الحالي. لذلك لا يصح تسجيل `CI PASS`.

---

## 3. مراجعة النظام الأم الحالي

الفحص المباشر للـSource يثبت أن `main.html` الحالي ليس مجرد هيكل بصري:

- login يثبت `company_id` من سجل المستخدم عبر `auth_id`.
- bootstrap يحمّل Items/Customers/Branches في سياق الشركة.
- Sidebar يحتوي Sales / Purchasing / Warehouse / Finance / Reports / HR / CRM / Users / Roles / License / Settings.
- `RW_Views.render()` يربط التبويبات بدوال تشغيل حقيقية.
- HR مربوط بـ`hr_list_employees` ويعرض بيانات الموظفين والتعويضات.
- CRM يحتوي customer list / analysis / followups مرتبطة بالبيانات.
- Financial reports تستخدم RPCs حقيقية مثل GL activity وperiod readiness وreconciliation وaging.
- تقارير المبيعات والمخزون والرانشيتات تقرأ البيانات الحالية من Production.
- Warehouse main يحتوي شاشات receiving/picking/loading/delivery/return/unloading/vouchers/counts، بينما التنفيذ التشغيلي التفصيلي ما زال في التطبيقات المنفصلة.

### النتيجة

**لا يوجد دليل حالي يبرر إعادة تقسيم `main.html` إلى أجزاء أو الرجوع إلى `main2` أو `New-main`.**

الـSource of Truth الصحيح الآن هو الملف المنشور نفسه.

---

## 4. التحقق من التعديل الأخير في POS / Telesales

### POS

في `RW_POS.save()` الحالي يظهر فعليًا:

```javascript
var operationId = window.__rwPosOperationId || null;
if (!operationId) {
    operationId = crypto.randomUUID();
    window.__rwPosOperationId = operationId;
}

var orderHeader = {
    operation_id: operationId,
    ...
};
```

وبعد النجاح:

```javascript
cart = [];
window.__rwPosOperationId = null;
```

ولا يتم تصفيره في مسار الخطأ.

### Telesales

في `RW_TeleSales._saveOrder()` الحالي يظهر نفس العقد:

```javascript
var operationId = window.__rwTeleSalesOperationId || null;
if (!operationId) {
    operationId = crypto.randomUUID();
    window.__rwTeleSalesOperationId = operationId;
}
```

ثم بعد النجاح:

```javascript
cart = [];
window.__rwTeleSalesOperationId = null;
```

### الحكم

التعديل الذي كان مطلوبًا في Report161 **موجود بالفعل في Current Source**.

لا يوجد Patch جديد مطلوب له الآن.

Closure المتبقي ليس Source surgery؛ بل Browser E2E + Production operation identity verification.

---

## 5. التحقق من قاعدة البيانات الحالية

Production project:
`fiilmooggumokxanwiyx`

Fresh counts:

| الجدول | العدد |
|---|---:|
| companies | 1 |
| branches | 2 |
| items | 17 |
| customers | 3 |
| orders | 0 |
| runsheets | 0 |
| stock_vouchers | 0 |
| inventory_log | 3 |
| credit_notes | 0 |
| installments | 0 |
| installment_details | 0 |
| loyalty_points | 0 |
| coupons | 0 |

Schema facts مثبتة حاليًا:

- `items.item_code` عليه `UNIQUE` عالمي.
- `stock_branches(branch_id,item_id)` عليه `UNIQUE`.
- `receiving.operation_id` عليه `UNIQUE`.
- `orders(company_id,operation_id)` لها uniqueness canonical.
- `credit_notes.operation_key` موجود مع uniqueness per company.

---

## 6. Inventory Core — إعادة تحقق مستقلة

تم تنفيذ Discovery مستقل من PostgreSQL لكل الدوال التي يمكن أن تمس:

- `stock_branches`
- `inventory_log`

النتيجة الحالية:

```text
Physical Writers outside post_stock_movement = 0
```

المحرك المركزي:

```text
PHYSICAL STOCK MOVEMENT
        ↓
post_stock_movement
        ↓
stock_branches + inventory_log
```

`reserve_stock` / `release_stock_reservation` مسؤولان عن reservation/allocated quantity ولا يمثلان Physical Movement Engine بديلًا.

### Integrity recheck

تمت إعادة فحص علاقات الشركة/الصنف مباشرة:

```text
stock_cross_company                = 0
inventory_log_cross_company        = 0
order_detail_item_cross_company    = 0
duplicate_item_code_global         = 0
```

هذه نتيجة Current Production، ولذلك لا يجوز إعادة تنظيف البيانات التي ثبت أنها سليمة الآن.

---

## 7. Production Deployments الحالية

تمت مطابقة قائمة Edge Functions الحالية.

من أهم المسارات الحالية:

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

لا يجوز استخدام نسخة قديمة من التقرير لإعادة إعلان Function مفقودة أو قديمة إذا أثبت Production خلاف ذلك.

---

## 8. Receive Purchase — الحقيقة الحالية

Current Production signature:

```text
receive_purchase_atomic(
  p_company_id uuid,
  p_po_code text,
  p_user_email text,
  p_items jsonb,
  p_operation_id uuid
)
```

الـRPC الحالي يبني Operation Identity صريحًا ويخزنها في `receiving.operation_id`، الذي عليه Unique constraint.

اختبار Production transactional مؤقت:

1. إنشاء PO مؤقت داخل Transaction.
2. إضافة PO detail حقيقي وفق الـschema الحالي.
3. تنفيذ `receive_purchase_atomic`.
4. إعادة نفس العملية بنفس `operation_id`.
5. التحقق من:

```text
duplicate = true
success = true
status = Received
same operation_id
```

ثم تم `ROLLBACK` كاملًا.

### Failure أثناء الاختبار

المحاولة الأولى لإعداد الاختبار فشلت لأن `purchase_order_details.line_amount` عمود Generated ولا يقبل قيمة مباشرة.

هذا **خطأ في بناء Fixture الاختبارية** وليس Defect في Production.

بعد تصحيح الاختبار، ظهر سلوك idempotency الصحيح.

---

## 9. Sales Return / Credit Note / Delivery

تم فحص وجود الدوال الحالية مباشرة.

الدوال الأساسية موجودة:

- `complete_return_atomic`
- `complete_order_delivery_atomic`
- `save_sales_invoice_atomic`
- `post_inventory_adjustment_atomic`
- `post_stock_movement`

والـReturn/Delivery الحاليان مرتبطان بالعقد المركزي بدل Writer مخزني مستقل.

Sales Return + Credit Note Backend الذي أُغلق سابقًا ما زال متسقًا مع Production الحالية.

لا يوجد دليل حالي يبرر إعادة بنائه.

---

## 10. Audit / RLS / Tenant Isolation

RLS الحالية تحقق Company Isolation على جداول رئيسية مثل:

- `items`
- `branches`
- `customers`
- `orders`
- `order_details`
- `runsheets`
- `run_sheet_details`
- `stock_branches`

وتستخدم `app_private.current_user_company_id()` في السياسات الحالية.

`fn_audit_trigger()` هو مسار Audit مركزي لعمليات الجداول التي لديها trigger audit، ويستخدم JWT email عند توفره، وإلا fallback `system`.

لا توجد حالة حالية مثبتة تبرر إزالة هذا المسار أو اختراع Audit engine جديد.

---

## 11. هل تم استكمال النظام الأم وظيفيًا؟

### الإجابة الدقيقة

**تم استكمال قدر كبير من البنية والوظائف الفعلية، لكن لم يصل النظام بعد إلى Gold/Diamond المكتمل في كل طبقات Sales المؤسسية.**

السبب ليس أن التبويبات الحالية شكلية فقط؛ بل توجد فجوات Business Contracts حقيقية لم تُبنَ بعد.

### نقاط ما زالت مفتوحة

```text
Sales Returns Parent Management UI          = OPEN
Quote lifecycle                              = OPEN
Price List engine                            = OPEN
Promotion engine                             = OPEN
Multiple / Partial Sales Payment allocation = OPEN
Installment lifecycle                        = OPEN
Commission engine                            = OPEN
Sales Targets engine                         = OPEN
Loyalty transaction engine                   = OPEN
Sales Decision Center                        = OPEN
Browser click-by-click E2E                   = OPEN
```

كما أن Financial Tax reporting الحالي يستخدم Capability Gate عندما لا يوجد مصدر Production سلطوي مثبت للضريبة، وهو سلوك صحيح حوكميًا وليس Placeholder صامتًا.

---

## 12. مقارنة Daftra الحالية

المواد الرسمية الحالية لدفترة تعرض ضمن منظومة المبيعات:

- الفواتير وعروض الأسعار.
- POS.
- Price Lists.
- Offers.
- Installments.
- Sales Targets.
- Commissions.
- Loyalty.
- الدفع المرن/الجزئي وبعض سيناريوهات المرتجعات والائتمان.

المراجع الرسمية المستخدمة:

- `https://www.daftra.com/`
- `https://www.daftra.com/plans`
- `https://www.daftra.com/برنامج-المبيعات-وإدارة-الفواتير/`
- `https://docs.daftra.com/`

### الحكم المعماري

RAWAEA لديه نقطة تميّز مهمة جدًا لا ينبغي هدمها أثناء المقارنة:

```text
Order
→ Runsheet
→ Picking
→ Loading
→ Delivery
→ Return
→ Unloading
```

مع تطبيقات تشغيلية منفصلة ومركز أم يراقب ويحلل ويضبط.

هذه ليست فجوة يجب نقلها للـParent؛ بل ميزة يجب الحفاظ عليها.

فجوات المنافسة الحالية تقع أساسًا في institutional Sales Management layer، وليس في ضرورة استبدال operational apps.

---

## 13. هل توجد تبويبات ناقصة أو اختصارات؟

الفحص الحالي يثبت أن التبويبات الرئيسية الموجودة لها render paths فعلية.

لم يظهر literal `قيد التطوير` في بحث Git الحالي للمستودع المنشور.

لكن توجد Capability Gates مقصودة، وبعض القدرات غير موجودة أصلًا كـProduction Contract.

وهذا فرق حاسم:

```text
Capability Gate ≠ Fake completed tab

Missing Business Contract ≠ UI bug
```

لذلك لا يجوز تحويل كل فجوة إلى HTML patch.

---

## 14. هل يوجد Patch جديد لـmain.html الآن؟

**لا.**

لا يوجد في الأدلة الحالية خلل مؤكد يستوجب جراحة جديدة في `main.html` ضمن العناصر التي جرى فحصها.

والسبب:

- POS operation identity موجود بالفعل.
- Telesales operation identity موجود بالفعل.
- Transfer branch field correction موجود بالفعل.
- company scoping موجود في مواضع القراءة الأساسية.
- warehouse navigation مرتبطة بمسارات حقيقية.
- HR/CRM/Finance/Reports ليست مجرد placeholders عامة.

### لذلك لا تنفذ أي حذف/استبدال في `main.html` الآن.

**العمل الصحيح التالي هو اختبار Browser E2E الفعلي للنسخة المنشورة، وليس إنشاء Patch جديد بلا Evidence.**

---

## 15. Browser E2E — حدود الإثبات

لم يتم ادعاء Browser click-by-click PASS.

بيئة الجلسة لا توفر قناة Browser Automation مباشرة، ولذلك لا يمكنني إثبات من هنا:

- فتح الصفحة فعليًا في متصفح.
- الضغط على كل تبويب.
- مراقبة DOM console في browser session حقيقي.
- تنفيذ retry من الواجهة نفسها.

الذي تم إثباته مباشرة هو:

```text
Current Git
Current Parent
Current Source
Current Database
Current RPC definitions
Current Edge deployments
Current Runtime/transactional behavior
Current integrity checks
```

وعليه:

`Browser Click-by-Click E2E = OPEN`

ولا يجوز تحويل ذلك إلى PASS لغويًا.

---

## 16. ماذا تم إنجازه في هذه الجلسة؟

1. إعادة بناء Current Git من HEAD إلى Parent وParent of Parent.
2. التأكد من أحدث commit وتغييره الفعلي في `main.html`.
3. مطابقة Source of Truth الفعلي.
4. إعادة فحص `forensic_main_assembly.yml` وتأكيد أن المسار صحيح.
5. إعادة فحص Current main source في مناطق login/bootstrap/navigation/finance/reports/HR/CRM/warehouse/POS/Telesales.
6. إعادة فحص Production database counts.
7. إعادة فحص Production schema contracts.
8. إعادة Discover لـPhysical Writers.
9. إعادة فحص Tenant/Item integrity.
10. إعادة فحص Current Edge versions.
11. إثبات Receive Purchase idempotency عبر transaction مؤقتة + rollback.
12. التحقق من أن POS/Telesales surgical repair موجود فعلًا في Current Source.
13. عدم إجراء Patch جديد على parent main لأنه غير مبرر بالأدلة الحالية.

---

## 17. أخطاء/تعثرات التنفيذ

### Failure 1
بناء Fixture Purchase Receiving حاول إدخال قيمة في `line_amount` رغم أنه Generated.

**السبب:** Fixture لم تلتزم بالـschema الفعلي.

**الإجراء:** إعادة الاختبار وفق schema الحالي.

**النتيجة:** idempotency أثبت نجاحه.

### Failure 2
تم في مراحل سابقة الاعتماد على قراءات قديمة كانت تسجل عددًا من cross-company rows.

**الإجراء الحالي:** إعادة تنفيذ الفحص من Production مباشرة.

**النتيجة الحالية:**

```text
all cross-company checks = 0
```

لذلك تم تصنيف الادعاءات القديمة على أنها STALE وعدم إعادة استخدامها.

---

## 18. Current Closure Matrix

| Closure Unit | Current | Production | Status |
|---|---|---|---|
| Source of Truth | `erp-frontend/main.html` | N/A | CLOSED |
| forensic assembly path | صحيح | N/A | CLOSED |
| Transfer branch display fix | موجود | N/A | CLOSED |
| Inventory physical writer centralization | `post_stock_movement` | Verified | CLOSED |
| Tenant/Item integrity | scoped/current | Verified | CLOSED |
| Sales Return backend | unified atomic | Verified | CLOSED |
| Credit Note backend | unified atomic | Verified | CLOSED |
| Receive Purchase idempotency | explicit operation_id | Verified | CLOSED |
| POS frontend operation identity | present | Not browser-tested | BACKEND/SOURCE VERIFIED; Browser OPEN |
| Telesales frontend operation identity | present | Not browser-tested | BACKEND/SOURCE VERIFIED; Browser OPEN |
| Browser click-by-click E2E | N/A | Not available | OPEN |
| Parent Sales Returns UI | Partial/No dedicated management view proven | N/A | OPEN |
| Quote | No current independent contract | N/A | OPEN |
| Price Lists | No current engine proven | N/A | OPEN |
| Promotions | Item-level offer fields only | N/A | OPEN |
| Payments allocation | Incomplete | N/A | OPEN |
| Installments | tables only / no completed engine proven | N/A | OPEN |
| Commissions | no engine proven | N/A | OPEN |
| Targets | no engine proven | N/A | OPEN |
| Loyalty | table only / no completed engine proven | N/A | OPEN |
| Decision Center | incomplete | N/A | OPEN |

---

## 19. FINAL SELF-AUDIT

### What I Proved

- Current HEAD and parent chain مباشرة من Git.
- Current `main.html` blob SHA.
- Latest operation-id commit موجود فعليًا في Source الحالي.
- `forensic_main_assembly.yml` صحيح.
- Current Production counts.
- Current DB schema facts.
- Physical writer zero-debt.
- Current tenant/item integrity = zero violations.
- Current Edge deployments.
- Current Receive Purchase operation identity + retry.
- Current main contains real render paths وليس مجرد skeleton خام.

### What I Did Not Prove

- Browser click-by-click E2E.
- Console-free runtime session في متصفح حقيقي.
- User-visible end-to-end retry من واجهة POS/Telesales.
- اكتمال Quote/Pricing/Promotion/Installments/Commission/Targets/Loyalty engines.

### What I Did Not Change

- لم أعدل `erp-frontend/companies/company-1/main.html`.
- لم أعدل `forensic_main_assembly.yml`.
- لم أعد فتح Inventory Core المغلق.

### What Could Still Be Wrong

1. Browser-only defects لا تظهر في static source/DB inspection.
2. Consumer mismatch مع أي Edge version غير الذي تمت مطابقته.
3. وظائف UI مستقبلية تحتاج Contracts جديدة غير موجودة حاليًا.

### Final Confidence

```text
Current Git                  = HIGH
Current Source               = HIGH
Current Production           = HIGH
Current DB                   = HIGH
Current Deployment Evidence = HIGH
Inventory Core               = 100% VERIFIED / CLOSED
Receive Purchase idempotency = VERIFIED / CLOSED
Parent main source repair    = VERIFIED / NO NEW PATCH REQUIRED
Browser E2E                  = OPEN
Sales Gold/Diamond           = OPEN
```

---

## 20. التوجيه التنفيذي للمساعد التالي — ابدأ من هنا

**لا تبدأ من Report161 ولا من أي تقرير آخر. ابدأ من الحقيقة الحالية فقط.**

### ترتيب الوصول للحقيقة

```text
1. اقرأ CURRENT GIT HEAD من repository الحقيقي.
2. اقرأ DIRECT PARENT.
3. اقرأ Parent of Parent عند الحاجة لتفسير التغيير.
4. احصل على CURRENT main.html blob SHA.
5. اقرأ current main.html في المصدر الحقيقي، وليس main2.
6. تحقق من current forensic_main_assembly.yml.
7. افحص Production DB schema الحالي.
8. افحص Production data counts الحالية.
9. أعد Discovery لكل Physical Writer.
10. افحص current PostgreSQL RPC definitions.
11. افحص current Edge deployment versions/source.
12. افحص runtime/log evidence الحديثة.
13. قارن كل ذلك بالعقد التاريخي فقط لفهم السبب، لا لإعادة اعتبار التاريخ حالة حالية.
14. صنّف كل نقطة:
      VERIFIED / STALE / CONTRADICTED / UNKNOWN
15. لا تلمس Closure تم تصنيفها CLOSED دون contradictory CURRENT evidence.
16. افتح Closure واحدة فقط.
17. افهم Historical Contract.
18. Trace Current Behavior.
19. Trace Data/Auth/Control Flow.
20. حدد GAP الحقيقي.
21. نفذ Surgical Fix واحد فقط.
22. اختبر.
23. انشر.
24. تحقق من Production.
25. تحقق Runtime.
26. وثّق.
27. حدّث CURRENT_STATE.
28. ثم انتقل للـClosure التالية.
```

### تسلسل Sales بعد Browser E2E

```text
Browser E2E
→ Production operation_id verification
→ Sales Returns Parent Management View
→ Quote Contract
→ Price List Contract
→ Promotion Contract
→ Partial/Multiple Payment Contract
→ Installment Contract
→ Commission Contract
→ Target Contract
→ Loyalty Contract
→ Sales Decision Center
→ Final Parent Browser E2E
```

### القاعدة الدائمة

```text
REPORT = POINTER
PRIMARY SOURCE = AUTHORITY
CURRENT PRODUCTION = TRUTH
NO ASSUMPTION
NO SPECULATIVE UI
NO CLOSED-CLOSURE REOPEN
NO PARALLEL ENGINE
ONE CLOSURE AT A TIME
CLOSE → VERIFY → DOCUMENT → NEXT
```

## 21. الخلاصة التنفيذية

النسخة الحالية التي تحكم المشروع هي:

`erp-frontend/companies/company-1/main.html`

والتحقيق الحالي لم يثبت وجود جراحة جديدة لازمة داخلها الآن.

المشكلة المتبقية ليست نقصًا في “عدد التبويبات” بقدر ما هي مجموعة Business Contracts مؤسسية لم تُبنَ بعد. الحل الصحيح هو بناء كل Contract كـclosure مستقل مع Production + Security + Accounting + Audit + E2E، مع الحفاظ على التطبيقات التشغيلية المنفصلة وعلى سلسلة العمليات الميدانية التي تمثل إحدى أهم مزايا RAWAEA.

**الخطوة الحتمية التالية: Browser Click-by-Click E2E على النسخة المنشورة الحالية، ثم الإغلاق أو إصدار أول Surgical Patch فقط من Console/Runtime Evidence الحقيقي.**
