# تقرير 353 — إغلاق جنائي لنقطة «وجهة التحويل الداخلي = جميع الفروع»

**التاريخ:** 2026-09-28  
**النطاق:** `companies/company-1/warehouse/vouchers.html`  
**المطلوب المحدد:** في «إذن تحويل داخلي فرع» يجب أن تظهر **جميع الفروع النشطة التابعة للشركة الحالية** في حقل «الفرع الوجهة».  
**قاعدة التعديل:** تعديل جراحي واحد فقط في المصدر؛ لا تعديل على `main.html` ولا تعديل مباشر على `vouchers.html` من هذه الجلسة.

---

## 1. نقطة الاستئناف والحقيقة الحالية

تم الاستئناف من آخر نقطة مثبتة، ثم تمت قراءة كامل الملفات المرجعية التالية حتى النهاية:

- `doc/Draft/Reprots/MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`
- `doc/Draft/Reprots/Report350_WAREHOUSE_VOUCHERS_FORENSIC_CLOSURE_20260928.md`
- `doc/Draft/Reprots/Report351_WAREHOUSE_VOUCHERS_FORENSIC_SOURCE_CONTRACT_AND_CURRENT_UI_CLOSURE_20260928.md`
- `doc/Draft/Reprots/Report352_WAREHOUSE_VOUCHERS_FORENSIC_CURRENT_HEAD_RUNTIME_CLOSURE_20260928.md`
- `CURRENT_STATE.md`

التقارير استُخدمت كخريطة تاريخية فقط. الحكم الحالي بُني على Git الحالي + Source الحالي + Production/Database الحالي + أدلة النشر الحالية.

التوجيه الحاكم الذي تم تثبيته من ملف Governance هو الاستمرار من آخر حقيقة مثبتة، والتحقق من المصدر الحالي، وعدم إعادة إصلاح ما أُغلق، وعدم التوقف عند مجرد وجود الكود أو النشر، بل إثبات الإغلاق وظيفيًا وتوثيقه وتحديث الحالة.

---

# 2. Current GIT

## System Repository

`papamohammed77-glitch/rawaie-erp-New`

- **HEAD:** `15c23f5f751ad1193cfd51c232516f89d521c926`
- **Parent:** `db6b6acd900c2b29a8f914a748b6db550446633f`
- التغيير الأخير يسجل نتائج Report352 الحالية، ولا توجد إشارة إلى تغيير مطلوب في `main.html`.

## Frontend Repository

`papamohammed77-glitch/erp-frontend`

- **HEAD:** `1d2103a8903296a33110e83803a355f224c489c5`
- **Parent:** `dd9e53f573ba8e10dd8692cb712cac22e3b001e8`
- **Target blob:** `00aa998bc2b5223bc147951427f523842c52963e`

### أحدث تسلسل حقيقي

Commit `dd9e53f...` أعاد تركيب الجزء الذي كان يسبب Regression سابقًا، وCommit `1d2103...` أصلح فاصلة زائدة كانت تنتج `},,` إلى `},`.

هذه النقطة مهمة لأن Report352 كان يشير إلى HEAD أقدم. **لا يجوز إعادة تطبيق T13–T16 من Report352 على HEAD الحالي.**

---

# 3. Current Source — vouchers.html

## الملف

`companies/company-1/warehouse/vouchers.html`

- **HEAD blob:** `00aa998bc2b5223bc147951427f523842c52963e`
- **الحجم:** 209,976 حرفًا
- **السطور:** 6,321

## ما ثبت أنه أصبح صحيحًا بالفعل

التحقق الحالي أثبت:

- `cards:function(rows,scope){` موجودة مرة واحدة.
- `vehicleBranch:function(v){` موجودة.
- عدد استدعاءات `vehicleBranch(` = 9، أي أن T16 لم يعد مفقودًا.
- `var h=topActions+` موجودة مرة واحدة، أي أن T14 مطبق.
- الهيكل الحالي لـ`receive:function(code,full)` يحتوي على إغلاق شرط `full===true`، أي أن T15 لم يعد هو الخلل الحالي.
- `topActions+` موجودة داخل `details()`، أي أن T05 السابق مطبق.
- لا توجد حاجة لإعادة T13/T14/T15/T16.

---

# 4. التحقيق الجنائي في الخطأ الحالي

## العقد الصحيح قبل العرض

داخل:

`pickArr:function(key)`

يوجد بالفعل:

```javascript
if(
    key==='wsTo' &&
    s.type==='Transfer'
){
    return allBranches;
}
```

و`allBranches` مبنية من:

- فروع الشركة الحالية.
- `is_active=true`.

إذن مصدر البيانات الصحيح للوجهة **موجود أصلًا** ولا يحتاج إلى إعادة بناء.

## موضع الخلل الحقيقي

الخلل داخل:

`pickSearch:function(key,q)`

**السطر التقريبي:** 3909 في HEAD الحالي.

العنصر المعيب الحالي هو:

```javascript
var allowed=
    type!=='branch' ||
    s.allowedBranch(
        s.user,
        x
    );
```

هذا العنصر يعيد تطبيق نطاق المستخدم على كل كيان من نوع `branch`.

وبالتالي:

1. `pickArr('wsTo')` يعطي جميع الفروع.
2. `pickSearch()` يضع `type='branch'`.
3. شرط `allowedBranch()` يحذف أي فرع خارج نطاق المرسل.
4. النتيجة النهائية في القائمة ليست كل الفروع.

إذن **المشكلة ليست في قاعدة البيانات، وليست في `pickArr()`، وليست في `pickSelect()`؛ المشكلة في Filter العرض داخل `pickSearch()`.**

---

# 5. إثبات Production / Database

تم فحص العقد الحالي في Supabase Production.

المستخدم التشغيلي:

- البريد: `vouchers@rawaea.com`
- الدور: `مخزني`
- `active_warehouse_role`: `أذونات`
- الفرع الأساسي: `BR-01`
- `allowed_branch_ids`: `BR-01`

الوجهة المراد اختبارها:

- `BR-2`
- «فرع الإسكندرية»
- `is_active=true`
- نفس الشركة.

وبالتالي ثبت أن `BR-2` خارج نطاق المرسل، لكن ذلك **لا يعني أن المرسل يجب أن يُمنع من اختيارها كوجهة تحويل**.

### Production contract الحالي

تعريف `create_manual_stock_voucher_atomic(..., p_rep_id, p_operation_id)` في Production يحتوي صراحةً على استثناء خاص بتدفقات تحويلات الأذونات للمخزني، بحيث يتم فرض مسؤولية المصدر، ولا يتم فرض نفس نطاق المصدر على وجهة التحويل.

تعريف Trigger:

`enforce_transfer_responsibility_contract()`

يثبت كذلك:

- مصدر التحويل للمخزني «أذونات» مرتبط بفرعه الأساسي.
- الوجهة يجب أن تكون فرعًا نشطًا في نفس الشركة.
- الوجهة **غير مقيدة بنطاق فروع المرسل**.
- مسؤول الاستلام يتم ربطه من فرع الوجهة عند الإرسال.
- لا يتم السماح بربط المرسل نفسه كمسؤول استلام.

إذن Production contract متوافق مع المطلوب الحالي.

**النتيجة:** لا يوجد نقص Production يحتاج Migration أو RPC جديدًا أو Edge Function جديدة.

---

# 6. Current Database / ACL / Edge

الوظائف ذات الصلة موجودة بالفعل:

- `create-stock-voucher`
- `send-stock-voucher`
- `receive-stock-voucher`
- `complete-stock-voucher`
- `cancel-stock-voucher`

والـEdge الحالي الخاص بالعمليات المخزنية ما زال موجودًا، ومنها:

- `create-stock-voucher` — Version 12
- `send-stock-voucher` — Version 20
- `receive-stock-voucher` — Version 22
- `complete-stock-voucher` — Version 4
- `cancel-stock-voucher` — Version 4

لم يتم إنشاء Edge Function جديدة.

ولم يتم تعديل Edge Function لأن العيب الحالي **قبل الوصول إلى طبقة التنفيذ أصلًا**؛ هو فلتر عرض محلي.

---

# 7. Current Data Hygiene

الحالة الحالية في Production:

- `stock_vouchers`: **5 Completed**
- Draft: **0**
- Sent: **0**
- Received: **0**
- لا توجد QA/non-completed fixtures حالية تحمل QA/TEST.

بذلك لا توجد بيانات تجريبية خاطئة متبقية تستلزم حذفًا جديدًا.

لم تتم إعادة إنشاء Fixtures backend التي أُغلقت سابقًا؛ ذلك كان سيكرر اختبارًا مغلقًا ويضيف حالة Production بلا فائدة لنقطة UI الحالية.

---

# 8. اختبار العقد في البيانات الحالية

تم أخذ Snapshot حقيقي من Production للفاعل والوجهات النشطة.

الفروع النشطة الحالية للشركة:

```text
BR-01
BR-2
VAN-CHV-2025-01
```

وباستخدام منطق `allowedBranch()` الحالي:

### قبل الإصلاح

القائمة النهائية بعد فلتر `pickSearch()`:

```text
BR-01
```

### بعد الإصلاح الجراحي المقترح

القائمة النهائية:

```text
BR-01
BR-2
VAN-CHV-2025-01
```

وهذا يثبت العيب والنتيجة المتوقعة دون تغيير أي بنية مخزنية.

---

# 9. التعديل الجراحي الوحيد المطلوب

## الملف

`companies/company-1/warehouse/vouchers.html`

## الدالة

`pickSearch:function(key,q)`

## الموضع

العنصر الحالي عند السطر التقريبي **3909** في HEAD:

```javascript
var allowed=
    type!=='branch' ||
    s.allowedBranch(
        s.user,
        x
    );
```

## ابحث عن هذا العنصر حرفيًا

```javascript
var allowed=
    type!=='branch' ||
    s.allowedBranch(
        s.user,
        x
    );
```

**احذفه بالكامل.**

## واستبدله بالكامل بهذا العنصر فقط

```javascript
var allowed=
    type!=='branch' ||
    (
        key==='wsTo' &&
        s.type==='Transfer'
    ) ||
    s.allowedBranch(
        s.user,
        x
    );
```

هذا هو **التعديل الجراحي الوحيد** المطلوب في `vouchers.html`.

لا تحذف `pickSearch()` بالكامل.
لا تعدل `pickArr()`.
لا تعدل `pickSelect()`.
لا تعدل `actionFor()`.
لا تعدل `details()`.
لا تعدل `receive()`.
لا تعدل `vehicleBranch()`.

---

# 10. لماذا هذا التعديل وحده كافٍ؟

بعده يصبح التدفق:

```text
pickArr('wsTo')
        ↓
allBranches
        ↓
pickSearch()
        ↓
type = branch
        ↓
Transfer + wsTo
        ↓
scope bypass for destination only
        ↓
all active company branches
```

أما بقية الحالات فتظل كما هي:

- `wsFrom` لا يزال محكومًا بنطاق المستخدم.
- `DirectReturn` لا يزال محكومًا بنطاق الوجهة.
- `DirectSale` لا يزال محكومًا بعقد المركبة/المندوب.
- `SupplierReturn` لا يتأثر.

وهذا يمنع توسيع الصلاحيات بالخطأ.

---

# 11. عدم لمس النظام الأم

## Current/PWA/main.html

**لم يتم تعديله.**

SHA الحالي:

`27b777528665dcc985809648f006452c861ae36e`

النظام الأم يوجّه إلى وحدة الأذونات المخزنية ويظل مصدر السلطة المركزية للمستخدم والفروع والصلاحيات، بينما `vouchers.html` هي طبقة التشغيل التنفيذي.

لا حاجة لتغيير الـMother App من أجل إصلاح هذا العيب.

---

# 12. التكامل مع van-sales

تمت مراجعة:

`companies/company-1/sales/van-sales.html`

SHA:

`8d61382a8e0025a0d079e71dd94f33d106d9088e`

التطبيق يظل منفصلًا وظيفيًا في العقد الصحيح:

```text
الأذونات المخزنية
فرع → مركبة
        ↓
عهدة المركبة
        ↓
van-sales
مركبة → عميل
```

وبالتالي:

**DirectSale ليس فاتورة عميل.**

هو نقل مخزون/عهدة إلى المركبة، ثم يقوم `van-sales` بعملية البيع الفعلية.

لم يظهر من التحقيق أي سبب لتعديل `van-sales.html` لهذه النقطة.

---

# 13. لماذا وصل هذا البناء لهذه الصورة؟

التصميم الحالي يحافظ على الفصل بين:

```text
Mother / Control Plane
    ↓
هوية المستخدم
الشركة
الفروع
المخازن
الأدوار
المسؤوليات
المركبات
    ↓
Operational PWA
    ↓
Voucher lifecycle
    ↓
Supabase core / RPC / Edge
    ↓
inventory_log / stock / audit / finance
```

هذه البنية ليست جزراً مستقلة؛ التطبيقات المنفصلة تؤدي المهام الميدانية، بينما Production/Core يثبت الحالة النهائية والأثر.

لذلك تم إصلاح **طبقة الاختيار فقط** وعدم إعادة تصميم العقد.

---

# 14. المراجعة التنافسية

تمت مراجعة الوثائق الحالية للمنافسين الرسميين.

### Odoo

Odoo 19 يقدّم سجل حركات مفصلًا يتضمن المرجع والمنتج والمصدر والوجهة والكمية والوحدة والحالة، مع Filters وGroup By، كما يفرّق بين Internal وIncoming وOutgoing وغيرها. كما يعرض تقارير للمواقع والكميات المحجوزة والحركة عبر الزمن.  
المراجع:
- https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/reporting/moves_history.html
- https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/reporting/locations.html
- https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/reporting/stock.html

### Microsoft Dynamics 365

Dynamics يربط النقل بين المخازن/المواقع بالبنية التنظيمية ويتيح إعداد مصدر إعادة الإمداد ووقت النقل، كما يحتوي على إعدادات مستقلة لعملية الاستلام.  
المراجع:
- https://learn.microsoft.com/en-us/dynamics365/supply-chain/warehousing/transfer-orders-warehouse
- https://learn.microsoft.com/en-us/dynamics365/supply-chain/warehousing/configure-transfer-order-receiving-process

### SAP

SAP يدعم النقل الداخلي عبر Stock Transport Orders أو Transfer Postings، ويتيح نماذج one-step وtwo-step مع تتبع stock in transit، كما يدعم تخطيط الاستلام والإرجاع والنقل بين المواقع.  
المراجع:
- https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/95f56a29a41e4861ba3424598848ee2b/4d6ed2bb174a74dbe10000000a42189c.html
- https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/91b21005dded4984bcccf4a69ae1300c/9e64bd534f22b44ce10000000a174cb4.html

### Daftra

Daftra يدعم التحويل اليدوي بين المخازن مع التاريخ والملاحظات والمخزن المصدر والوجهة والصنف والكمية، ويعرض قبل/بعد للمخزون.  
المراجع:
- https://docs.daftra.com/en/user_manual/transferring-items-from-one-warehouse-to-another/
- https://docs.daftra.com/en/tutorial/transferring-stock/

### Manager.io

Manager يدعم Inventory Transfers كحركة مستقلة عن البيع والشراء، ويتيح التاريخ والمرجع والوصف والصنف والكمية والمصدر والوجهة، وتنعكس الحركة آليًا على أرصدة المواقع.  
المرجع:
- https://www2.manager.io/guides/10707

## الفجوات التنافسية اللاحقة

هذه ليست أسبابًا لفتح هذا العيب مرة أخرى، لكنها Backlog موثق:

- Transit/In-transit KPI صريح.
- Planned Ship / Planned Receive وLead Time.
- Bin/Location hierarchy.
- Lot / Serial / Expiry / Package.
- Batch/Import.
- تقارير Movement History أكثر عمقًا.
- مستندات PDF/Barcode للحركة.
- Evidence attachments.
- مؤشرات Warehouse performance وstagnant stock.

---

# 15. E2E / Deployment Evidence

## Browser E2E الحالي

آخر Run على HEAD الحالي `1d2103...`:

**RAWAEA — Warehouse Vouchers Browser E2E**

Run:
`36438835759`

النتيجة: **FAIL**.

لكن سبب الفشل مثبت من الـRunner نفسه:

```
Error: INLINE_SCRIPT_NOT_FOUND
```

والـworkflow توقف في:

**Validate vouchers source syntax and canonical asset paths**

ولم يصل إلى:

**Execute browser smoke E2E for standalone vouchers**

إذن هذا الـFAIL **ليس دليلًا على فشل JavaScript التطبيق** ولا على فشل عقد الوجهة.

الـworkflow نفسه يبحث بطريقة ضيقة عن:

```javascript
const a=s.indexOf('<script>',s.indexOf('<body>'));
```

بينما المصدر الحالي يحتوي على script block لا يطابق هذا البحث الحرفي.

هذا Boundary/Harness issue، وليس عيبًا في العقد الوظيفي المطلوب.

Run reference:
https://github.com/papamohammed77-glitch/erp-frontend/actions/runs/36438835759

كما أن:
**RAWAEA forensic current Mother extract**
Run `36438835531`
نجح بالكامل.

---

# 16. E2E المطلوب بعد تطبيق Patch

بعد أن يطبق Owner التعديل الجراحي:

### UI Test 1
فتح:
**إذن جديد → تحويل داخلي**

### UI Test 2
فتح:
**الفرع الوجهة**

### UI Test 3
التحقق من ظهور:

```text
BR-01
BR-2
VAN-CHV-2025-01
```

### UI Test 4
اختيار `BR-2`.

### UI Test 5
التحقق من عدم ظهور رسالة:
«خارج نطاق فروع المستخدم»

### UI Test 6
إرسال الإذن، مع بقاء Production receiver binding كما هو.

### UI Test 7
التحقق من استمرار Restriction على **المصدر** وعدم تغييره.

---

# 17. الحكم التنفيذي

## CLOSED

- Production destination contract.
- Production same-company active destination validation.
- Source/default-branch responsibility.
- Receiver responsibility.
- Existing RPC architecture.
- Existing Edge architecture.
- Mother-app integration.
- van-sales separation.
- T13/T14/T15/T16 regressions في HEAD الحالي.

## OPEN

نقطة واحدة فقط:

**UI destination filter في `pickSearch()`.**

ولا توجد حاليًا ضرورة لأي:

- Migration.
- RPC جديد.
- Edge Function جديدة.
- تعديل `main.html`.
- تعديل `van-sales.html`.
- إعادة بناء `pickArr()`.
- إعادة بناء `pickSelect()`.

---

# 18. تعليمات الجلسة التالية

ابدأ من:

```text
CURRENT GIT
    ↓
CURRENT SOURCE
    ↓
CURRENT PRODUCTION
    ↓
CURRENT DATABASE
    ↓
CURRENT DEPLOYMENT
```

ثم:

1. تحقق أن Owner طبّق **العنصر الوحيد** في `pickSearch()`.
2. تحقق أن النمط القديم لا يظهر.
3. تحقق أن النمط الجديد يظهر مرة واحدة.
4. شغّل Source Parse صحيحًا.
5. شغّل Browser E2E.
6. تحقق من الاختيار الفعلي لـBR-2.
7. أعد التحقق من Send/Receiver دون إعادة إصلاح Production.
8. لا تعُد إلى T13–T16.
9. لا تنشئ Edge Function جديدة.
10. لا تلمس `main.html`.

---

# SELF AUDIT

- تم فحص آخر System HEAD وParent: **PASS**
- تم فحص آخر Frontend HEAD وParent: **PASS**
- تم تحديث نقطة الحقيقة من HEAD أحدث من Report352: **PASS**
- تم فحص `main.html`: **PASS / UNCHANGED**
- تم فحص `vouchers.html`: **PASS**
- تم فحص `van-sales.html`: **PASS / NO CHANGE**
- تم فحص Production Contract: **PASS**
- تم فحص DB state: **PASS**
- تم فحص Edge inventory: **PASS / NO NEW FUNCTION**
- تم التحقق من QA residue: **0 non-completed QA**
- تم إثبات العيب الحالي في UI filter: **PASS**
- تم إعداد تعديل جراحي واحد فقط: **PASS**
- تم منع إعادة إصلاح الأعمال المغلقة: **PASS**
- Browser E2E: **OPEN بسبب Harness قبل بدء Browser Smoke**
- Owner Source Patch: **OPEN**

# الحالة النهائية للجلسة

**الحقيقة الحالية لا تحتاج إصلاح Backend.**

**المشكلة الحالية محصورة في عنصر واحد داخل `pickSearch()`: فلتر العرض يعيد فرض نطاق المستخدم على وجهة Transfer رغم أن `pickArr()` وProduction contract مصممان لإتاحة أي فرع نشط من نفس الشركة كوجهة.**

**Patch الوحيد:** تجاوز `allowedBranch()` عندما تكون الحالة `key==='wsTo' && s.type==='Transfer'`، مع إبقاء كل حالات الصلاحية الأخرى كما هي.

# END OF REPORT 353
