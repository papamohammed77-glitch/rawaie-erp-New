# Report271 — التحقيق الجنائي وإغلاق Runtime Boot لتطبيق الأذونات المخزنية
## 2026-09-20

> هذه الجولة محصورة في:
> `erp-frontend/companies/company-1/warehouse/vouchers.html`
> مع التحقق من Mother وProduction والهوية التشغيلية للتطبيق.
> لا تعديل في `main.html` ولا كتابة في `vouchers.html` من هذا المنفذ.

---

## 1. قاعدة الحقيقة المعتمدة

تمت إعادة بناء الحالة من:

- CURRENT GIT.
- CURRENT SOURCE.
- CURRENT PRODUCTION.
- CURRENT DATABASE.
- CURRENT DEPLOYMENT / Edge inventory.
- ثم مقارنة ذلك بالتقارير التاريخية باعتبارها Evidence فقط.

### آخر System Git

Repository:
`papamohammed77-glitch/rawaie-erp-New`

HEAD الحالي قبل كتابة هذا التقرير:
`b5fddb21c4e4ab879eedde7fd7f4dbe448677dc8`

Parent:
`84df2a14f2165acb940c7c9da8aa170c7d2ce122`

وهذا أحدث من تقرير Report270؛ لذلك لا تُستخدم SHA القديمة للحالة الحالية.

### آخر Mother Git

Repository:
`papamohammed77-glitch/erp-frontend`

أحدث commit تم التحقق منه:
`3516a2465c0a5a10563fda0f4726f1647c75c9b9`

Parent:
`d1aaac986f9f729ec47baf56a943dc90477950ef`

والـcommitان الأخيران أثّرا في `companies/company-1/warehouse/vouchers.html` رغم أن رسائل commit لا تعكس طبيعة التعديل الحقيقي.

Mother:
`companies/company-1/main.html`

Current blob:
`453565c39a50fdcf73eb03a97a1fc7d7ac10bb2f`

لم يتم تعديل Mother.

---

## 2. Current Standalone Source — المثبت فعليًا

الملف:

`erp-frontend/companies/company-1/warehouse/vouchers.html`

Current SHA:

`6a69faa4443e72b20ff6701b0d0dfe0bf77dc44e`

الحجم:
69,346 bytes

عدد الأسطر:
741

EOF:
PASS — ينتهي بـ `</html>`

### المكونات الحالية المثبتة

التطبيق الحالي يحتوي على:

- Authentication.
- Company context.
- Warehouse-role gate.
- Live synchronization.
- Manual voucher list.
- Text/type/date filters.
- Voucher details.
- Audit/movement evidence.
- CREATE operation identity.
- RECEIVE operation identity.
- DirectSale.
- DirectReturn.
- SupplierReturn.
- Transfer.
- Scrap/Adjustment delegated to the adjustment engine.
- Barcode search/scanning.
- Responsive catalog/cart.
- Realtime refresh.
- Account view.

الـ`filterList` موجود حاليًا مرة واحدة، والـinline JavaScript يمر باختبار parser في النسخة الحالية.

**لا تعاد معالجة Report270 الخاصة بـ`filterList` وescaping؛ ثبت أنها موجودة في المصدر الحالي.**

---

## 3. CURRENT CORE — إثبات موقع النواة

`companies/company-1/core.js`

SHA:
`b3da51ee5a577e1aef346beb0ed4a866df7d563c`

الحجم:
25,009 bytes

Syntax:
PASS

ويعرّف فعليًا:

- `RW_Auth`
- `RW_DB`
- `RW_API`
- `RW_UI`
- `RW_ImageCache`
- `RW_SW`

هذه حقيقة مصدرية، وليست افتراضًا.

### Service Worker

`companies/company-1/sw.js`

SHA:
`6123fce8b99391d70e6937bde5c4fcbd3f2d8f48`

Syntax:
PASS

### register-sw

`companies/company-1/register-sw.js`

SHA:
`9a8f8b14be0cfb92e82077c36b36fab9b452c8ec`

الملف يحتوي على شرط صريح يمنع التسجيل على مسار vouchers.html، وبالتالي استدعاؤه داخل صفحة vouchers ليس جزءًا لازمًا من boot path.

---

# 4. ROOT CAUSE — الخطأ الحقيقي في آخر الرسالة

Console:

```
GET .../companies/company-1/warehouse/core.js 404
GET .../companies/company-1/warehouse/register-sw.js 404
RW_SW is not defined
RW_UI is not defined
Service Worker ... /warehouse/sw.js 404
```

## السبب الأول — Relative Path Drift

السطر الحالي في line 9:

```html
<script src="core.js"></script>
```

يُفسّر من مسار الصفحة:

```
/companies/company-1/warehouse/
```

فتصبح الطلبات:

```
/companies/company-1/warehouse/core.js
```

بينما الملف الحقيقي مثبت هنا:

```
/companies/company-1/core.js
```

إذًا:

```
core.js
```

يجب أن يكون:

```
../core.js
```

## السبب الثاني — إعادة الكتابة القاتلة لعميل Supabase

في line 9 يوجد:

```html
<script>var supabase=window.supabase;</script>
```

وهذا خطأ مستقل.

قبل هذا السطر:

```
core.js
```

ينشئ عميل Supabase الحقيقي في المتغير العام:

```
supabase
```

ولكن السطر اللاحق يعيد إسناد:

```
supabase
```

إلى:

```
window.supabase
```

أي إلى namespace الخاص بمكتبة Supabase وليس إلى الـclient الذي أنشأته النواة.

لذلك حتى لو تم إصلاح path فقط، سيبقى runtime معرضًا للفشل في:

```
supabase.auth.*
supabase.from(...)
supabase.rpc(...)
```

إذن إصلاح path وحده **غير كافٍ**.

## السبب الثالث — Service Worker relative path

السطر الحالي:

```
RW_SW.register('sw.js')
```

وبما أن الصفحة داخل:

```
/companies/company-1/warehouse/
```

فإن المتصفح يبحث عن:

```
/companies/company-1/warehouse/sw.js
```

بينما الملف الحقيقي:

```
/companies/company-1/sw.js
```

إذن يجب أن يكون:

```
RW_SW.register('../sw.js')
```

## السبب الرابع — register-sw.js ليس مطلوبًا لهذه الصفحة

السطر الأخير:

```
<script src="register-sw.js"></script>
```

يعيد طلب:

```
/companies/company-1/warehouse/register-sw.js
```

وهذا 404.

وفوق ذلك، النسخة الحقيقية من `companies/company-1/register-sw.js` تحتوي على شرط يمنع Service Worker registration على vouchers.html.

إذن السطر:

```
<script src="register-sw.js"></script>
```

ليس فقط خاطئ المسار، بل **زائد في هذا التطبيق**.

---

# 5. الإثبات التاريخي — لماذا وصل الملف إلى هذا الشكل؟

النسخة التاريخية من:

`rawaie-erp-review/PWA/warehouse/vouchers.html`

كانت تستخدم:

```html
<script src="../core.js"></script>
```

وتستخدم:

```js
RW_SW.register('../sw.js');
```

ولا تحتوي على:

```var supabase=window.supabase;
```

إذن الجراحة المطلوبة ليست إعادة تصميم؛ بل استعادة الـrelative-path contract الصحيح الذي كان موجودًا تاريخيًا، مع إزالة consumer overwrite الذي ظهر في النسخة اللاحقة.

---

# 6. العلاقة مع Mother

الـMother الحالي يثبت أن الأذونات المخزنية ليست جزيرة منفصلة وظيفيًا.

ضمن:

`إدارة المخازن والمخزون`

توجد مجموعة:

`الأذونات المخزنية`

وتحتها:

- تحويل مخزني.
- صرف سيارة بيع مباشر.
- استلام مرتجع سيارة.
- مرتجع لمورد.
- عرض الأذونات.

كما أن Current Mother يحتوي على:

```
view = 'vouchers'
view = 'transfer'
view = 'direct-sale'
view = 'direct-return'
view = 'supplier-return'
```

ويوجد mapping للصلاحيات إلى:

```
vouchers
transfer
direct-sale
direct-return
supplier-return
```

والـMother router الحالي يوجه:

```
vouchers ightarrow RW_Warehouse.loadVouchers()
```

وليس إلى standalone HTML مباشرة.

### النتيجة المعمارية

النظام مصمم حاليًا بطبقتين متكاملتين:

**Mother Control Plane**
- إدارة المستخدمين.
- الأدوار.
- الصلاحيات.
- التوجيه.
- المراقبة.
- التقارير.
- تشغيل نماذج التحكم المركزية.

**Standalone Operational Consumer**
- تطبيق ميداني/تشغيلي مستقل.
- يعمل مباشرة على نفس Production contracts.
- لا يعيد بناء Physical Stock engine.
- لا يملك صلاحية إنشاء engine بديل.

هذا الفصل صحيح معماريًا ولا ينبغي إلغاؤه.

---

# 7. الدور الوظيفي المثبت للتطبيق

الدور الحالي لـ`vouchers.html` هو تنفيذ العمليات المخزنية غير الناتجة مباشرة من Order/Runsheet workflow.

### العمليات اليدوية الأساسية

| العملية | المسار |
|---|---|
| Transfer | فرع → فرع |
| DirectSale | فرع → مركبة |
| DirectReturn | مركبة → فرع |
| SupplierReturn | فرع → مورد |

### العمليات التي لا ينبغي دمجها في نفس Physical Voucher lifecycle

- Picking.
- Loading.
- Delivery.
- Return field operation.
- Unloading.

هذه لها تطبيقات ميدانية منفصلة وعقود تشغيلية خاصة بها.

### Scrap / Adjustment

المصدر الحالي يفتحها من نفس workspace لأسباب UX، لكنه يرسلها إلى:

```
bulk-stock-adjustment
```

ولا يسجلها كـmanual stock voucher lifecycle.

وهذا يحافظ على الفصل الصحيح بين:

```
Manual Voucher Lifecycle
]

و:

```
Inventory Adjustment Engine
```

ولا ينبغي دمجهما فقط من أجل شكل موحد.

---

# 8. Production — الوضع الحالي

Supabase:

`fiilmooggumokxanwiyx`

الحالة الحالية المثبتة:

- companies = 1
- branches = 2
- items = 17
- stock_vouchers = 0
- stock_voucher_details = 0
- stock_voucher_operations = 0
- inventory_log = 3
- active users with `active_warehouse_role='أذونات'` = 1
- Item 1001 rows = 1

المستخدم التشغيلي المثبت:

```
email:
vouchers@rawaea.com

name:
مسئول مخازن (أذونات مخزنية)

role:
مخزني

active_warehouse_role:
أذونات

status:
Active

allowed_branch_ids:
BR-01
```

إذن:

**حساب التطبيق موجود، نشط، وله الدور الصحيح.**

رفض الدخول ليس سببه غياب الحساب أو الصلاحية في Production.

---

# 9. Production Voucher Core

Production يحتوي على:

```
create_manual_stock_voucher_atomic
```

بتوقيع canonical الحالي ذي 12 argument:

```
p_company_id
p_type
p_reference
p_from_type
p_from_id
p_to_type
p_to_id
p_notes
p_created_by
p_items
p_rep_id
p_operation_id
```

كما يحتوي على:

```
post_manual_stock_voucher_atomic
send_stock_voucher_atomic
complete_manual_stock_voucher_atomic
cancel_manual_stock_voucher_atomic
inventory_control
post_stock_movement
reserve_stock
```

والـcore rule ما زال:

```
Physical Stock Movement
        ↓
post_stock_movement
        ↓
stock_branches
+
inventory_log
```

ولا توجد ضرورة لإعادة فتح Inventory Core في هذه الجولة.

---

# 10. Edge inventory — لا توجد حاجة لإنشاء Function جديدة

Current Edge inventory يثبت وجود:

- create-stock-voucher
- send-stock-voucher
- receive-stock-voucher
- complete-stock-voucher
- cancel-stock-voucher
- bulk-stock-adjustment

ولا يتم إنشاء Edge Function جديدة.

هذا يتوافق مع قيد الـgateway / spend cap.

---

# 11. ما تم إصلاحه سابقًا ولا يجب لمسه

ثبت أن المصدر الحالي يحتوي بالفعل على:

### FilterList

```
filterList:function()
```

موجود مرة واحدة.

### escaping

النسخة الحالية تمر في JavaScript parser بعد تحويلها في الذاكرة إلى نسخة boot-correct.

### CREATE identity

التطبيق الحالي يحتفظ بـoperation identity أثناء إعادة المحاولة.

### RECEIVE identity

التطبيق الحالي يحتفظ بـoperation identity عبر localStorage ويرسله إلى receive capability.

### Audit

```
inventory_control
```

يُستخدم لعرض:

- voucher.
- details.
- movements.
- audit evidence.

وبالتالي لا يجوز إعادة بناء هذه الأجزاء في هذه الجولة.

---

# 12. المنافسة — الفجوات التي ثبت أنها ذات قيمة فعلية

## Odoo 19

Odoo يفصل العمليات المخزنية إلى receipts, deliveries, returns, vendor returns, scrap, inventory adjustments، ويدعم barcode-based physical counts مع تعيين مهام الجرد للمستخدمين. كما أن scrap يحمل مصدر العملية والسبب والموقع، ويمكن ربطه بوثيقة مصدر.  
Official:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/barcode/operations/adjustments.html
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/inventory_management/scrap_inventory.html

## Dynamics 365

Dynamics يفصل Inventory Movement وInventory Adjustment وTransfer وItem Arrival وCounting وTag Counting، ويجعل transfer قابلًا للتتبع عبر From/To dimensions والمعاملات الناتجة، بينما counting مخصص لمطابقة physical count.  
Official:
https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/inventory-journals
https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/tasks/transfer-physical-inventory-within-warehouse
https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/inventory-tag-counting

## SAP

SAP Goods Movement يغطي goods receipt, goods issue, physical stock transfer, transfer posting مع documentation/reporting لمسار الحركة.  
Official:
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/91b21005dded4984bcccf4a69ae1300c/742e46e570984d9aa74e468838f6e1ff.html

## القيمة التي تستحق الإكمال في RAWAEA لاحقًا

الفجوات المفيدة التي بقيت Evidence-based وليست تخمينًا:

1. Before / After stock evidence داخل تفاصيل الوثيقة.
2. Bulk import/paste للعمليات الكثيفة.
3. Approval workflow اختياري.
4. Attachments / documents.
5. Lot / serial / expiry إذا أصبح ذلك Business Contract.
6. In-transit lifecycle أكثر عمقًا إذا أصبح النقل متعدد المراحل.
7. Print / export document contract رسمي.

**لا يتم إدخال أي واحدة من هذه الآن داخل Production ما لم يوجد contract حقيقي في RAWAEA يحدد behavior والبيانات المطلوبة.**

القاعدة هنا: المنافس يثبت capability، لكنه لا يثبت أن schema أو workflow المطلوب في RAWAEA هو نفسه.

---

# 13. SURGICAL PATCH — المالك ينفذها في ملف واحد فقط

## الملف

`erp-frontend/companies/company-1/warehouse/vouchers.html`

Current SHA:

`6a69faa4443e72b20ff6701b0d0dfe0bf77dc44e`

---

## PATCH A — إصلاح تحميل core + إزالة Supabase overwrite

### ابحث حرفيًا في السطر 9 عن:

```html
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script><script src="core.js"></script><script>var supabase=window.supabase;</script>
```

### احذف هذا الجزء بالكامل واستبدله حرفيًا بـ:

```html
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script><script src="../core.js"></script>
```

لا تعدل بقية `head`.

---

## PATCH B — إصلاح Service Worker path

### ابحث حرفيًا داخل السطر 739 عن:

```RW_SW.register('sw.js')
```

### استبدله حرفيًا بـ:

```RW_SW.register('../sw.js')
```

لا تعدل بقية منطق السطر.

---

## PATCH C — حذف loader زائد لـ register-sw.js

### ابحث حرفيًا في السطر 740 عن:

```</script><script src="register-sw.js"></script></body></html>
```

### احذفه واستبدله حرفيًا بـ:

```</script></body></html>
```

لا تضف:

```
../register-sw.js
```

لأن `register-sw.js` الحالي يتجاهل صفحة vouchers أصلًا.

---

# 14. ما لا يُسمح بتعديله في هذه الجراحة

لا تعدل:

- `doLogin`
- `init`
- `RW_Auth`
- `filterList`
- `details`
- `receive`
- `submit`
- `newWorkspace`
- `post_stock_movement`
- `reserve_stock`
- `inventory_control`
- Mother `main.html`
- أي Edge Function أخرى.

الـ`doLogin` ليس Root Cause؛ هو الضحية التي تظهر فيها:

```
RW_UI is not defined
```

لأن `core.js` لم يُحمّل.

---

# 15. Static Validation — تم تنفيذها قبل التسليم

تم أخذ المصدر الحالي إلى نسخة مؤقتة في الذاكرة وتطبيق PATCH A+B+C عليها فقط.

النتيجة:

```
patched source differs from current = PASS
wrong core path = 0
correct ../core.js references = 1
wrong SW registration path = 0
correct ../sw.js registration = 1
register-sw.js script tag = 0
supabase overwrite = 0
inline JS parser = PASS
```

كما تم اختبار:

- core.js syntax = PASS
- register-sw.js syntax = PASS
- sw.js syntax = PASS

---

# 16. Expected Runtime After Owner Cutover

بعد تطبيق الجراحة ثم نشر الملف:

يجب أن تختفي الطلبات التالية:

```
/companies/company-1/warehouse/core.js
/companies/company-1/warehouse/register-sw.js
/companies/company-1/warehouse/sw.js
```

ويجب أن تصبح الموارد:

```
/companies/company-1/core.js
/companies/company-1/sw.js
```

ثم يجب أن يصبح boot chain:

```
HTML
 ↓
Supabase library
 ↓
../core.js
 ↓
RW_Auth / RW_UI / RW_API / RW_SW
 ↓
session
 ↓
users by auth_id
 ↓
company_id
 ↓
active_warehouse_role
 ↓
loadRefs
 ↓
pending vouchers
```

وبذلك ستنتقل الصفحة أخيرًا إلى مسار الدخول الحقيقي بدل الانهيار عند أول استدعاء `RW_UI`.

---

# 17. Browser E2E

لم يُغلق Browser E2E في هذه الجلسة لأن الملف مملوك للمالك ولم يتم تعديله من هذا المنفذ، وهذا intentional وفق Owner Source Delivery Rule.

حالة البوابة:

```
SOURCE FORENSIC             = CLOSED
ROOT CAUSE                  = CLOSED
SURGICAL PATCH              = READY
PATCH STATIC VALIDATION     = PASS
PRODUCTION CONTRACT         = VERIFIED
MOTHER                       = UNTOUCHED
VOUCHERS FILE               = UNTOUCHED
BROWSER E2E                 = OPEN
GLOBAL VOUCHER CONSUMER     = NOT CLOSED
```

لا يُسمح بتحويل هذا الوضع إلى 100% قبل تشغيل المتصفح على النسخة المنشورة.

---

# 18. E2E المطلوب بعد التطبيق

التسلسل الوحيد المطلوب:

1. فتح التطبيق.
2. تحميل `../core.js`.
3. ظهور login دون ReferenceError.
4. تسجيل الدخول بحساب:
   `vouchers@rawaea.com`
5. إثبات `company_id`.
6. إثبات `active_warehouse_role = أذونات`.
7. ظهور Pending.
8. فتح New Voucher.
9. CREATE Transfer.
10. response-loss retry.
11. SEND.
12. partial RECEIVE.
13. نفس operation retry.
14. remainder RECEIVE.
15. COMPLETE.
16. Details.
17. Movement evidence.
18. Audit evidence.
19. Type filter.
20. Date filter.
21. Search.
22. Realtime refresh.
23. إعادة قراءة Production.
24. التأكد من عدم وجود duplicate movements.
25. التأكد من عدم بقاء test residue.

---

# 19. النتيجة الجنائية النهائية

## What was proved

- حساب الأذونات موجود ونشط.
- role = مخزني.
- active_warehouse_role = أذونات.
- Production voucher core موجود.
- canonical CREATE RPC موجود.
- existing Edge voucher capabilities موجودة.
- Mother يحتوي control-plane للأذونات.
- standalone vouchers هو operational consumer منفصل.
- current vouchers source يحتوي الإصلاحات السابقة ولا يحتاج إعادة إصلاحها.
- الـlogin failure ليس Permission defect.
- Root Cause هو Runtime Boot Path Drift + Supabase client overwrite + redundant register-sw loader.
- النسخة التاريخية تثبت أن `../core.js` و`../sw.js` كانا العقد الصحيح.

## What was not proved

- Browser E2E الحقيقي بعد الـcutover.
- Cloudflare deployed asset behavior بعد نشر التعديل.
- production runtime of the standalone page after the owner patch.

## What was intentionally not changed

- Mother.
- standalone source.
- Inventory Core.
- voucher business contracts.
- existing Edge Function count.
- existing idempotency mechanisms.

## Final closure

```
GLOBAL VOUCHER CONSUMER = OPEN ONLY FOR OWNER PATCH + BROWSER E2E
```

---

# 20. Exact instructions for the next CTO / assistant

ابدأ دائمًا بهذا الترتيب:

```
CURRENT GIT
↓
CURRENT VOUCHERS SHA
↓
CURRENT CORE / SW SHAs
↓
CURRENT MOTHER SHA
↓
CURRENT PRODUCTION
↓
CURRENT USERS / ROLES
↓
CURRENT EDGE DEPLOYMENTS
↓
ONLY THEN runtime verification
```

لا تعتمد على Report269 أو Report270 كحالة حالية.

التقارير السابقة أثبتت التاريخ فقط.

لا تعِد إصلاح:

```
filterList
escaping
CREATE operation_id
RECEIVE operation_id
VOUCHER_AUDIT
post_stock_movement
Inventory Core
```

ما لم يثبت Regression جديد من Current Source/Production.

بعد Browser E2E فقط:
- أغلق Voucher Consumer.
- حدّث CURRENT_STATE.
- ثم افتح Business Contract التالي.
- لا تعد إلى Inventory Core إلا إذا ظهر Regression مثبت.

# END REPORT271
