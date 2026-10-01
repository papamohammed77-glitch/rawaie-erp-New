# تقرير 384 — تصحيح الهدف الفعلي لملف النظام الأم والتعديل الجراحي لعمود مندوب صرف/مرتجع السيارة

**التاريخ:** 2026-10-01  
**المشروع:** RAWAEA ERP  
**الوحدة:** النظام الأم → الأذونات المخزنية → صرف سيارة بيع مباشر / مرتجع سيارة بيع مباشر → إسقاط هوية المندوب  
**الحالة:** OWNER SURGICAL PATCH READY — المصدر لم يُعدّل بواسطة المساعد

---

## 1. نطاق التحقيق

الهدف المحدد في هذه الدورة هو إصلاح شاشة الأذونات المخزنية داخل ملف النظام الأم بحيث يظهر **المندوب صاحب عهدة صرف/مرتجع السيارة** في الجدول، مع الحفاظ الكامل على دورة المستندات، المخزون، العهدة، المحاسبة، التطبيقات التشغيلية المنفصلة، وعدم إنشاء Edge Function أو RPC جديد.

الملف المطلوب فعليًا من المالك هو:

`papamohammed77-glitch/erp-frontend`
→ `companies/company-1/main.html`

وليس:

`rawaie-erp-New/Current/PWA/main.html`

---

# 2. نقطة البداية المعتمدة

تمت مراجعة:

1. `MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`
2. `CURRENT_STATE.md` حتى آخر Append.
3. أحدث الحالة التاريخية Report381 وReport382 وReport383.
4. Current Git وCommit history وParent/Compare.
5. المصدر الفعلي للملف المطلوب في مستودع `erp-frontend`.
6. Production Supabase.
7. مخطط `stock_vouchers` وعلاقات `users`.
8. سياسات RLS ذات الصلة.
9. التاريخ الفعلي لتطبيق `warehouse/vouchers.html`.
10. الاختبار الجراحي In-Memory على المصدر الحالي.
11. Benchmark حديث مع Odoo / Dynamics 365 / SAP / Daftra / Manager.io.

**قاعدة التحقيق:** التقارير السابقة استُخدمت كإرشاد تاريخي فقط. الحالة الحالية حُسمت من Current Git + Current Source + Current Production + Current Database + Current Deployment Evidence.

---

# 3. الخطأ الذي تسبب في تعذر الوصول إلى العنصر

المساعدون السابقون حددوا الجراحة داخل:

`Current/PWA/main.html`

وكتبوا Anchors تعتمد على بنية غير موجودة داخل الملف المطلوب حاليًا، ومنها:

`order('created_at',{ascending:false})`

وكذلك:

`_vouchersRepMap`

و:

`custodian_user_id`

كانت موجودة في التقرير كهدف مستقبلي، لكنها **غير موجودة في المصدر الفعلي الحالي**.

نتيجة ذلك أن المالك يبحث عن نص لا وجود له في الملف:

`companies/company-1/main.html`

وهذا هو سبب الفشل السابق في العثور على موضع التعديل.

**هذا التقرير يلغي تلك الـanchors القديمة ويعتمد فقط على النص الحالي الحرفي للمصدر الفعلي.**

---

# 4. Current Frontend Git

## آخر Commit يمس main.html

Repository:

`papamohammed77-glitch/erp-frontend`

Commit:

`d13537d0f4d8d7f0e2c0ac6d25d779bc4062760e`

Message:

`Update main.html`

تاريخ التنفيذ:

2026-09-24

المقارنة مع:

`f32f970ad395ad163f770d3cdf56f9015198e3a6`

أثبتت أن آخر سلسلة تغييرات main.html كانت مرتبطة بوحدة Fleet والصلاحيات وربط المركبة بالعملية، ولم تكن إصلاحًا لقائمة الأذونات المخزنية.

## Current main.html blob

`810e4f5440f5975f55099a124deb42b086a49183`

حجم المصدر:

`1,754,145` حرفًا.

عدد الأسطر:

`32,316` سطرًا.

---

# 5. Current Source — الملف الصحيح

المسار الحاكم:

`companies/company-1/main.html`

العنصر المطلوب:

`async function loadVouchers()`

الموضع الحالي:

**حوالي السطر 14858**

والدالة التالية:

`function _applyVouchers()`

تبدأ عند:

**حوالي السطر 14884**

---

# 6. السبب الجذري المثبت

الجدول الحالي في النظام الأم يقوم بالآتي:

`stock_vouchers`
→ `select('*')`
→ `_applyVouchers()`
→ عرض:

- رقم الإذن
- النوع
- التاريخ
- الحالة
- المرجع
- من
- إلى
- الإجراءات

ولا توجد فيه أي إسقاط لهوية:

`stock_vouchers.custodian_user_id`

إلى اسم المستخدم.

إذن البيانات التشغيلية ليست مفقودة من النظام.

العيب هو:

**Mother UI Read-Model Projection Gap**

بمعنى أن هوية المندوب موجودة في عقد المستند، لكن طبقة العرض في main.html لا تعرضها.

---

# 7. Production Database Contract

Production:

`SMART ERP`

Project Ref:

`fiilmooggumokxanwiyx`

الحالة:

`ACTIVE_HEALTHY`

PostgreSQL:

`17.6.1.121`

## الحقل الحاكم

`public.stock_vouchers.custodian_user_id`

النوع:

`uuid`

Nullable:

نعم.

## العلاقة الحاكمة

Foreign Key:

`stock_vouchers_custodian_user_fk`

من:

`stock_vouchers.custodian_user_id`

إلى:

`public.users.id`

إذن المرجع الصحيح للمندوب هو:

`custodian_user_id → users.id`

وليس:

`vehicles.driver_id`

---

# 8. Production Representatives

Production الحالي يحتوي مندوبي بيع مباشر نشطين للشركة الحالية:

### Representative 1

ID:

`1fc1a0f7-e8bf-44f4-93fb-002e8cb9cbf9`

Name:

`van-sales2`

Email:

`van-sales2@rawaea.com`

Role:

`مندوب بيع مباشر`

Status:

`Active`

Permissions:

`["van-sales"]`

### Representative 2

ID:

`111b0730-a977-4d11-bcd0-2427b178a9e5`

Name:

`مندوب مبيعات بيع مباشر`

Email:

`vansales@rawaea.com`

Role:

`مندوب بيع مباشر`

Status:

`Active`

Permissions:

`["van-sales"]`

### Representative 3

ID:

`cb086d71-ba61-4392-8d3d-c4bec02ec913`

Name:

`مندوب مبيعات بيع مباشر 2`

Email:

`vansales2@rawaea.com`

Role:

`مندوب بيع مباشر`

Status:

`Active`

Permissions:

`["van-sales"]`

---

# 9. RLS Verification

سياسة قراءة `stock_vouchers` الحالية مقيدة بالشركة:

`company_id = app_private.current_user_company_id()`

وسياسات قراءة `users` الحالية تسمح بقراءة مندوبي البيع المباشر من خلال سياسة:

`users_select_direct_reps_warehouse`

عندما يكون:

- المستخدم في نفس الشركة.
- المندوب Active.
- role = `مندوب بيع مباشر`.
- للمستخدم المنفذ صلاحية warehouse.
- للمندوب صلاحية `van-sales`.

Production الحالي يحقق عقد المندوبين الثلاثة المشار إليه أعلاه.

وبالتالي فإن lookup المطلوب يمكن تنفيذه من main.html بدون كشف مستخدمين من شركة أخرى ودون كسر RLS.

---

# 10. Historical Source Evidence

تمت مراجعة Commit:

`5801db5d15673c49e88ccfc69e84f0a53cd8866d`

في:

`companies/company-1/warehouse/vouchers.html`

وهذا commit أضاف صراحةً:

`custodian_user_id`

إلى العرض، مع lookup:

`custodian_user_id → s.refs.reps → rep.name / rep.email`

كما يعرض في DirectSale وDirectReturn:

**المستلم والمسؤول عن العهدة**

إذن هذا ليس تصميمًا جديدًا تم اختراعه في هذه الدورة.

إنه عقد موجود فعليًا في التطبيق التشغيلي المنفصل، والجراحة الحالية تسد الفجوة المقابلة في النظام الأم.

---

# 11. التصميم المعماري الصحيح

العقد يجب أن يبقى:

`DirectSale / DirectReturn`

→ `stock_vouchers`

→ `custodian_user_id`

→ `public.users.id`

→ `rep.name / rep.email`

ولا يتم اشتقاق المندوب من:

`vehicles.driver_id`

لأن:

**Owner/Master Assignment**

و

**Document Custody**

ليسا الشيء نفسه.

المندوب المسجل على المستند هو الشخص الذي يجب أن يظهر في سجل الأذن الرقابي، حتى لا نعيد تفسير المستند من حالة السيارة الحالية.

---

# 12. العنصر المعيب الأول — تحميل بيانات المندوب

## الملف

`companies/company-1/main.html`

## الدالة

`async function loadVouchers()`

## الموضع

**السطر 14879 تقريبًا**

## ابحث حرفيًا عن هذا العنصر كاملًا

```js
var res = await supabase.from('stock_vouchers').select('*').eq('company_id', companyId).order('voucher_date', { ascending: false });
        window._vouchersData = res.data || [];
        _applyVouchers();
```

## احذف هذا العنصر كاملًا.

## واستبدله بهذا العنصر كاملًا

```js
var res = await supabase.from('stock_vouchers').select('*').eq('company_id', companyId).order('voucher_date', { ascending: false });
        if (res.error) throw res.error;
        var voucherRows = res.data || [];
        var custodianIds = [];
        var custodianSeen = Object.create(null);
        for (var vi = 0; vi < voucherRows.length; vi++) {
            var voucher = voucherRows[vi];
            if ((voucher.type === 'DirectSale' || voucher.type === 'DirectReturn') && voucher.custodian_user_id) {
                var custodianKey = String(voucher.custodian_user_id);
                if (!custodianSeen[custodianKey]) {
                    custodianSeen[custodianKey] = true;
                    custodianIds.push(voucher.custodian_user_id);
                }
            }
        }
        window._vouchersRepMap = Object.create(null);
        if (custodianIds.length) {
            var repsRes = await supabase.from('users')
                .select('id,name,email')
                .eq('company_id', companyId)
                .in('id', custodianIds);
            if (repsRes.error) throw repsRes.error;
            (repsRes.data || []).forEach(function(rep) {
                window._vouchersRepMap[String(rep.id)] = rep.name || rep.email || '';
            });
        }
        window._vouchersData = voucherRows.map(function(v) {
            var isDirectVehicleVoucher = v.type === 'DirectSale' || v.type === 'DirectReturn';
            v._custodian_name = isDirectVehicleVoucher && v.custodian_user_id
                ? (window._vouchersRepMap[String(v.custodian_user_id)] || '-')
                : '-';
            return v;
        });
        _applyVouchers();
```

### لماذا هذا البديل هو الصحيح؟

- يحافظ على company scope الأصلي.
- يضيف فحص `res.error`.
- لا يستعلم عن جميع المستخدمين.
- يجمع فقط `custodian_user_id` المستخدمة فعليًا في الأذونات.
- يستعلم عن IDs المطلوبة فقط.
- لا يغير حالة المستند.
- لا يكتب قاعدة البيانات.
- لا يغير workflow.
- لا يشتق المندوب من السيارة.
- يحافظ على DirectSale وDirectReturn فقط.
- الأنواع الأخرى تحصل على `-`.

---

# 13. العنصر المعيب الثاني — عنوان العمود

## الدالة

`loadVouchers()`

## الموضع

**السطر 14874 تقريبًا**

## ابحث حرفيًا عن هذا العنصر

```html
<th class="p-3">إلى</th><th class="p-3 text-center">إجراءات</th></tr></thead><tbody id="vouchers-tbody"><tr><td colspan="8" class="text-center py-8">جاري التحميل...</td></tr>
```

## احذفه كاملًا واستبدله بهذا

```html
<th class="p-3">إلى</th><th class="p-3">المندوب</th><th class="p-3 text-center">إجراءات</th></tr></thead><tbody id="vouchers-tbody"><tr><td colspan="9" class="text-center py-8">جاري التحميل...</td></tr>
```

---

# 14. العنصر المعيب الثالث — Empty State

## الدالة

`function _applyVouchers()`

## الموضع

**السطر 14902 تقريبًا**

## ابحث حرفيًا عن

```js
if (!d.length) { safeHTML(tb, '<tr><td colspan="8" class="text-center py-8">لا توجد أذونات</td></tr>'); return; }
```

## احذفه كاملًا واستبدله بـ

```js
if (!d.length) { safeHTML(tb, '<tr><td colspan="9" class="text-center py-8">لا توجد أذونات</td></tr>'); return; }
```

---

# 15. العنصر المعيب الرابع — إسقاط المندوب داخل الصف

## الدالة

`function _applyVouchers()`

## الموضع

**السطر 14910 تقريبًا**

## ابحث حرفيًا عن هذا العنصر كاملًا

```js
return '<tr class="hover:bg-gray-50"><td class="p-3 font-bold text-indigo-700">' + (v.voucher_code||'') + sourceIndicator + '</td><td class="p-3">' + (v.type||'') + '</td><td class="p-3">' + (v.voucher_date||'') + '</td><td class="p-3"><span class="px-2 py-1 rounded-full text-xs ' + statusBadge + '">' + (v.status||'') + '</span></td><td class="p-3">' + (v.reference||'-') + '</td><td class="p-3">' + (v.from_id||'-') + '</td><td class="p-3">' + (v.to_id||'-') + '</td><td class="p-3 text-center">' + actions + '</td></tr>';
```

## احذفه كاملًا.

## واستبدله بهذا العنصر كاملًا

```js
return '<tr class="hover:bg-gray-50"><td class="p-3 font-bold text-indigo-700">' + (v.voucher_code||'') + sourceIndicator + '</td><td class="p-3">' + (v.type||'') + '</td><td class="p-3">' + (v.voucher_date||'') + '</td><td class="p-3"><span class="px-2 py-1 rounded-full text-xs ' + statusBadge + '">' + (v.status||'') + '</span></td><td class="p-3">' + (v.reference||'-') + '</td><td class="p-3">' + (v.from_id||'-') + '</td><td class="p-3">' + (v.to_id||'-') + '</td><td class="p-3">' + esc(v._custodian_name||'-') + '</td><td class="p-3 text-center">' + actions + '</td></tr>';
```

---

# 16. لا تستبدل الدوال كاملة

لا تحذف:

- `loadVouchers()` كاملة.
- `_applyVouchers()` كاملة.
- `_viewVoucherDetails()`.
- `_sendVoucher()`.
- `_receiveVoucher()`.
- `_openNewVoucherModal()`.
- أي وظيفة أخرى.

المطلوب فقط:

**4 substitutions جراحية.**

---

# 17. لماذا هذه الجراحة لا تحتاج Production Modification

التعديل الجديد يستخدم:

- `SELECT stock_vouchers`
- `SELECT users`

ولا ينفذ:

- INSERT
- UPDATE
- DELETE
- RPC mutation
- Edge Function call
- status transition
- stock movement
- custody movement
- accounting posting
- treasury posting

لذلك:

**Production Schema Change = NONE**

**Edge Function Change = NONE**

**RPC Change = NONE**

**Table Change = NONE**

**RLS Change = NONE**

---

# 18. التحقق من عدم المساس بالـDirectReturn Fix

تمت إعادة قراءة Production function:

`post_manual_stock_voucher_atomic_core_20260828`

والعقد الحالي المثبت هو:

`DirectReturn RECEIVE → InventoryIncrease`

ولا توجد حاجة لإعادة فتح هذا الإصلاح.

العقد التشغيلي يبقى:

### DirectSale

فرع

→ سيارة / مخزن متنقل

### DirectReturn SEND

سيارة / مخزن متنقل

→ خصم من عهدة السيارة

### DirectReturn RECEIVE

إضافة إلى الفرع

ولا تتم إعادة خصم السيارة مرتين.

---

# 19. المخزون والعهدة والمحاسبة

الجراحة الحالية **Read Only**.

لذلك أثرها المباشر:

| المجال | الأثر |
|---|---:|
| Branch Stock | 0 |
| Vehicle Stock | 0 |
| Allocated Stock | 0 |
| Custody Balance | 0 |
| Inventory Log | 0 |
| Driver Ledger | 0 |
| General Journal | 0 |
| Customer Ledger | 0 |
| Supplier Ledger | 0 |
| Treasury | 0 |
| Voucher Status | 0 |
| Workflow | 0 |

أي أن كل هذه الآثار لا تتغير بسبب عرض العمود.

---

# 20. آخر Production E2E تشغيلي مثبت

ظل اختبار Report382 هو أحدث دليل تشغيلي موثوق ومطابق للعقد الحالي:

### DirectSale

CREATE → Draft

→ SEND → Sent

→ Branch 8 → 7

→ Mobile 0 → 1

→ custody debit 50

### DirectReturn

CREATE → Draft

→ SEND → Sent

→ Mobile 1 → 0

→ Branch تبقى 7

### DirectReturn RECEIVE

→ Received

→ Branch 7 → 8

→ Mobile تبقى 0

→ custody credit 50

### Duplicate RECEIVE

نفس `operation_id`

→ `duplicate=true`

→ لا توجد حركة إضافية.

### Accounting

Journal:

10 → 10 entries

16 → 16 lines

### Custody

Debit 50

Credit 50

Balance:

0

### Cleanup

QA voucher residue:

0

ولا توجد حاجة لإعادة تنفيذ هذا السيناريو لمجرد أن التعديل الحالي للعرض فقط.

---

# 21. بيانات تجريبية للـUI

بسبب أن Production الحالية بعد عمليات التنظيف الأخيرة لا تحتوي على DirectSale/DirectReturn vouchers للشركة الحالية:

`voucher_count = 0`

تم إنشاء **fixture داخل الذاكرة فقط** لاختبار الإسقاط دون تلويث Production.

### Fixture 1

`type=DirectSale`

`custodian_user_id=111b0730-a977-4d11-bcd0-2427b178a9e5`

النتيجة:

`مندوب مبيعات بيع مباشر`

PASS

### Fixture 2

`type=DirectReturn`

`custodian_user_id=1fc1a0f7-e8bf-44f4-93fb-002e8cb9cbf9`

النتيجة:

`van-sales2`

PASS

### Fixture 3

`type=Transfer`

`custodian_user_id=null`

النتيجة:

`-`

PASS

### Fixture 4

`type=SupplierReturn`

`custodian_user_id=null`

النتيجة:

`-`

PASS

**لم يتم إدخال Fixture تجريبي إلى Production لأن الجراحة لا تحتاج Mutation ولأن قاعدة الاختبار الحالية نظيفة.**

---

# 22. Source Surgical Gate

تم تطبيق substitutions الأربع على نسخة In-Memory من Current Source فقط.

## النتائج

| Gate | النتيجة |
|---|---|
| PATCH 1 anchor uniqueness | PASS — 1 |
| PATCH 2 anchor uniqueness | PASS — 1 |
| PATCH 3 anchor uniqueness | PASS — 1 |
| PATCH 4 anchor uniqueness | PASS — 1 |
| Inline script count | 1 |
| Complete JS parse | PASS |
| DirectSale mapping | PASS |
| DirectReturn mapping | PASS |
| Transfer fallback | PASS |
| SupplierReturn fallback | PASS |
| Header column | PASS |
| Loading colspan 9 | PASS |
| Empty colspan 9 | PASS |
| Row contains escaped rep | PASS |

المصدر الحقيقي بقي دون تعديل.

Current blob ما زال:

`810e4f5440f5975f55099a124deb42b086a49183`

---

# 23. سبب اختيار إسقاط IDs المطلوبة بدل تحميل جميع المستخدمين

تم تجنب تحميل كل مستخدمي الشركة من أجل عمود واحد.

الخوارزمية المقترحة:

`stock_vouchers`

→ استخراج distinct `custodian_user_id`

→ Query محدد:

`users.id IN (custodianIds)`

→ Map:

`id → name/email`

→ projection:

`v._custodian_name`

وهذا أفضل من إنشاء قائمة مستخدمين عامة داخل read-model.

كما أنه أكثر انسجامًا مع نمط RLS الحالي.

---

# 24. Benchmark تنافسي

## Odoo

Odoo 19 يركز في Moves History على:

- Date
- Reference
- Product
- Lot/Serial
- From
- To
- Quantity
- Unit
- Status

ويتيح التصفية والتجميع والتحليل للحركة والمخزون.  
المصدر الرسمي:

https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/reporting/moves_history.html

كما يوفر Locations/History لتتبع مواقع المخزون وحركته:

https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/reporting/locations.html

## Microsoft Dynamics 365

Transfer journals تتطلب From/To dimensions وتسمح بعرض Inventory Transactions بعد ترحيل الحركة.

المصدر الرسمي:

https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/tasks/transfer-physical-inventory-within-warehouse

## SAP

SAP يفرق بين one-step وtwo-step stock transfer، وفي النقل بين company codes تظهر accounting documents أيضًا، ما يؤكد أن نوع الحركة والنطاق المحاسبي يجب أن يظلا منفصلين عن مجرد عرض الحركة.

المصدر الرسمي:

https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/9905622a5c1f49ba84e9076fc83a9c2c/c864bd534f22b44ce10000000a174cb4.html

## Daftra

دفترة تعرض في نقل المخزون:

- From Warehouse
- To Warehouse
- Notes
- Quantity
- Available Before
- Available After

كما توثق تخصيص عهدة المخزون للموظف وربط حركة المخزون بمستودع الموظف وتقارير حركته.

المصادر الرسمية:

https://docs.daftra.com/tutorial/transferring-stock/

https://docs.daftra.com/en/user_manual/how-to-assign-inventory-to-an-employee/

## Manager.io

Manager يتابع Inventory Transfers بين المواقع مع بقاء الحركة مرتبطة بالموقع/المستودع.

المصدر الرسمي:

https://www2.manager.io/guides/11130

---

# 25. نتيجة المقارنة

الحقل الجديد:

**المندوب**

ليس زخرفة UI.

هو Audit Dimension.

ويجعل السطر يقرأ:

**إذن → نوع الحركة → من → إلى → المندوب → الإجراء**

وهو ما يقرب النظام الأم من طريقة الأنظمة الاحترافية في جعل سجل الحركة قابلاً للمراجعة والتحقيق.

لكن لا يتم في هذه الجراحة إدخال:

- Stock Before / After
- Barcode
- Lot / Serial
- Expiry
- Attachments
- Approval metadata
- Exception queue
- SLA
- Timeline

لأنها Business Capabilities مستقلة وليست إصلاحًا لعمود المندوب.

---

# 26. التكامل مع التطبيقات المنفصلة

## النظام الأم

مسؤوليته:

- company context
- authorization context
- parent navigation
- consolidated read-model
- audit visibility

## vouchers.html

مسؤوليته:

- Create
- Edit
- Send
- Receive
- DirectSale
- DirectReturn
- Transfer
- SupplierReturn

## Van Sales

مسؤوليته:

- mobile stock
- customer sales
- direct sales
- collection
- inventory count
- settlement

الجراحة الحالية لا تنقل أي responsibility بين هذه الطبقات.

الهدف فقط:

`Operational Voucher`

→

`Mother Visibility`

---

# 27. Workflow Safety

بعد التعديل لا يتغير:

`CREATE`

ولا:

`SEND`

ولا:

`RECEIVE`

ولا:

`reserve`

ولا:

`post_stock_movement`

ولا:

`inventory_log`

ولا:

`driver_ledger`

ولا:

`general_journal`

ولا:

`treasury`

الموجود الوحيد الجديد هو:

**read projection**

---

# 28. E2E Browser Boundary

لا يوجد في هذه الجلسة Browser-rendered E2E بعد دمج المالك، لأن:

1. main.html لم تُعدل في Git.
2. لم يتم نشر نسخة جديدة.
3. لا توجد هنا أداة dispatch متاحة لتشغيل Workflow المتصفح المخصص.

لذلك:

**Browser E2E = OPEN**

ولا يجوز تسجيله PASS قبل نشر المصدر المعدل وتشغيل الاختبار الفعلي.

---

# 29. Deployment Boundary

Current Source:

`810e4f5440f5975f55099a124deb42b086a49183`

Current Production:

صحيح.

Current source patch:

جاهز.

لكن served artifact بعد merge/publish:

**OPEN**

ولا يوجد ادعاء بأن Production UI أصبحت معدلة قبل الدمج والنشر.

---

# 30. ما لم يتم لمسه

- `main.html` لم يتم تعديله.
- `warehouse/vouchers.html` لم يتم تعديله.
- `van-sales.html` لم يتم تعديله.
- `stock_vouchers` schema لم يتم تعديله.
- `users` schema لم يتم تعديله.
- RLS لم يتم تعديله.
- `inventory_voucher_report` لم يتم تعديله.
- `post_stock_movement` لم يتم تعديله.
- `post_manual_stock_voucher_atomic_core_20260828` لم يتم تعديله في هذه الجراحة.
- `send-stock-voucher` لم يتم تعديله.
- `receive-stock-voucher` لم يتم تعديله.
- navigation لم تُعدل.
- permission authority لم تُعدل.

---

# 31. خطة التنفيذ للمالك

## 1

افتح:

`companies/company-1/main.html`

## 2

طبق PATCH 1 فقط في:

`loadVouchers()`

## 3

طبق PATCH 2 فقط في Header.

## 4

طبق PATCH 3 فقط في Empty State.

## 5

طبق PATCH 4 فقط في Row Projection.

## 6

لا تستبدل أي Function كاملة.

## 7

بعد الحفظ:

- Syntax Gate
- Publish
- Served Artifact Check
- Browser E2E

## 8

اختبر:

DirectSale

→ يظهر اسم المندوب.

DirectReturn

→ يظهر اسم المندوب.

Transfer

→ `-`

SupplierReturn

→ `-`

---

# 32. Closure Conditions

لا تُغلق هذه الوحدة إلا بعد إثبات:

`ROOT CAUSE = PROVEN`

`CURRENT TARGET SOURCE = PROVEN`

`PATCH ANCHORS = UNIQUE`

`STATIC SYNTAX = PASS`

`SEMANTIC MAPPING = PASS`

`PRODUCTION CONTRACT = VERIFIED`

`BROWSER E2E = PASS`

`SERVED ARTIFACT = VERIFIED`

---

# 33. تعليمات الاستكمال للمساعد القادم

لا تبدأ من الصفر.

ابدأ بهذا الترتيب:

1. افتح `CURRENT_STATE.md` حتى آخر Append.
2. اعتبر `Report384` مرجع نقطة الاستئناف الخاصة بهذه الوحدة.
3. أثبت Current Frontend Blob.
4. لا تستخدم أي Anchor من Report382/383 إذا لم يطابق النص الحالي حرفيًا.
5. الملف الحاكم هو:
   `companies/company-1/main.html`
6. طبّق أربع substitutions فقط.
7. لا تعدل Backend لأن الجراحة Read-Only.
8. شغّل Syntax Gate.
9. انشر.
10. تحقق من served artifact.
11. شغّل Browser E2E.
12. أغلق الوحدة فقط بعد runtime evidence.

## لا تعيد

- DirectReturn receive fix.
- Master Assignment contract.
- Owner wildcard.
- voucher operational workflow.
- historical repairs التي ثبتت إغلاقها.

---

# 34. SELF AUDIT

## Proven

- الملف الصحيح.
- SHA الحالي.
- مواضع الدوال.
- السبب الجذري.
- وجود `custodian_user_id`.
- FK إلى `users.id`.
- وجود المندوبين في Production.
- RLS contract.
- historical implementation في `vouchers.html`.
- exact four current anchors.
- anchor uniqueness.
- full inline JS parse.
- semantic mapping.
- صفر تأثير على الكتابة في Production.

## Not Proven

- Browser-rendered main.html بعد merge.
- served artifact بعد publish.
- runtime UI في Production بعد النشر.

## Deliberately Not Changed

- كل الـworkflow التشغيلي.
- كل البنية المخزنية والمحاسبية.
- كل التطبيقات التشغيلية المنفصلة.
- كل الـEdge/RPC الموجودة.

---

# 35. Final Decision

العيب ليس Backend.

العيب ليس Database.

العيب ليس Accounting.

العيب ليس Vehicle Assignment.

العيب هو:

**فقدان إسقاط هوية المندوب من مستند الأذن إلى جدول العرض في النظام الأم، مع وجود contract صحيح داخل قاعدة البيانات والتطبيق التشغيلي المنفصل.**

والحل النهائي المحدد:

**أربع جراحات فقط في `companies/company-1/main.html`:**

1. load representative IDs.
2. add Representative header.
3. correct empty colspan.
4. render representative name escaped.

**لا تعديل آخر.**

---

# END OF REPORT 384
