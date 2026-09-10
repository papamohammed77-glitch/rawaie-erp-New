# سجل إعادة الفحص النهائي — Report116
## RAWAEA ERP — Main1 إلى Main11 / Main2 Assembly / Production
### التاريخ: 2026-09-10

## 1. المرجعية التنفيذية
تمت مراجعة MASTER التنفيذي الحالي، Report114، Execution Log الخاص بـReport114، وReport115، ثم تمت إعادة مطابقة المصدر الحالي بدل اعتماد أي تقرير سابق كمصدر حقيقة.

قاعدة الحوكمة المطبقة:
CURRENT VERIFIED REALITY > CURRENT PRODUCTION > CURRENT DATABASE CONTRACT > CURRENT DEPLOYMENT > CURRENT GIT > CURRENT SOURCE > HISTORICAL REPORTS.

ولا يجوز إعلان إغلاق 100% عند وجود Unknown أو Conflict أو Unverified Claim مؤثر.

## 2. Git — الواقع الحالي
Current branch: main
Current HEAD: ce160467fb72c488630dd3d58789f1d4f07a9c1b

Current main2 component SHAs:
- main1: 4d1b42250cfe2b3a8ec7d02b7b482eca8e27bade
- main2: 58dd0da232ccca4c62bc17d87220bf8b705d85e8
- main3: 479060e3d4bea5e2203c87f822b1dbc0e2f7d456
- main4: e89d29e4164c68784c109292f27d4d77df240557
- main5: c4518d05ada50830e819563a55169843679d3e94
- main6: 3b20758459c28ab0b6c055f9a0ad3992f1bd07e5
- main7: a65969f6bdc919d4a8d62a6704a7c556b7d35e91
- main8: 2131fbf3096d926b2486acb2ab58a4266ddd1bbc
- main9: b9f10ae4e727cb9495aaecbe2d752dabf13ec776
- main10: 169025a6836c7fdc7281ea86523b975a84d889f1
- main11: 2adfc787c3e5f0ca56abfcc85232e7a971773c3b

## 3. Production Fresh Snapshot
Snapshot UTC: 2026-09-10 11:08:19.462653+00
- companies=1
- branches=2
- users=24
- items=17
- customers=3
- orders=0
- runsheets=0
- purchase_orders=0
- stock_vouchers=0
- stock_branches=20
- inventory_log=3
- receiving=0
- journal_entries=2
- audit_log=1869

## 4. Main1–Main11 recheck

### Main1
تم فتح المصدر الحالي. لا يوجد في نتيجة الفحص الحالية دليل مثبت على عيب Tenant جديد ضمن نطاق إعادة الفحص الجراحي هذه. لا تُعلن Syntax PASS كاملًا من دون تشغيل parser على الملف الكامل.

### Main2 — OPEN
تم فتح المصدر الحالي. يوجد عيب Runtime/Scope مثبت:

- `RW_Dashboard.loadAll()` يستخدم `companyId` دون تعريف محلي.
- عدة دوال داخل `RW_Items` تستخدم `companyId` دون تعريف محلي، ومنها:
  `_loadMovementReport()` / `buildQuery()`، `_loadCategoriesIntoSelect()`، `_openCategoryModal()`، `_deleteCategory()`، `_buildCategoryFilterFromDB()`، ومسار رفع/معالجة البيانات.

هذا ليس افتراضًا: البحث في المصدر الحالي لم يجد أي declaration من نمط `var companyId` داخل Main2، بينما توجد مراجع فعلية لـ`companyId`.

### Main3
تم فتح المصدر الحالي. يعتمد على `_rwCompanyId()` في مواضع الإعدادات/السياق ذات الصلة. لا يوجد عيب جديد مثبت ضمن نطاق هذه المراجعة.

### Main4
تم فتح المصدر الحالي. `render()` يستخدم `_rwCompanyId()` ويقيد `app_settings` و`branches` بسياق الشركة. لا يوجد عيب جديد مثبت ضمن نطاق هذه المراجعة.

### Main5
تم فتح المصدر الحالي. مسار Orders يستخرج `companyId` محليًا من `_rwCompanyId()` ويقيد orders/settings بالشركة. لا يوجد عيب جديد مثبت ضمن نطاق هذه المراجعة.

### Main6
تم فتح المصدر الحالي. Online Store يستخرج `companyId` من `_rwCompanyId()` ويقيد `app_settings`. لا يوجد عيب جديد مثبت ضمن نطاق هذه المراجعة.

### Main7
تم فتح المصدر الحالي. Warehouse يستخرج Company Context من `RW_STATE.app.companyId` في عدة وظائف ويقيد الاستعلامات بالـcompany. لم يثبت Writer مخزني مباشر من الـPWA في هذا الملف أثناء البحث الحالي.

### Main8
تم فتح المصدر الحالي. Finance لديه `_companyId()` مركزي ويستخدمه في الاستعلامات الكتابية/القرائية الرئيسية. لا يوجد عيب جديد مثبت ضمن نطاق هذه المراجعة.

### Main9
الحالة الحالية: **لا توجد جراحة جديدة** ضمن العيب الذي وصفه Report114.
الفلتر الحالي لـ`logistics-returns / r25` أصبح:
`SalesReturn + DirectReturn`
وليس `SalesReturn + Return`.

### Main10
الحالة الحالية: **لا توجد جراحة جديدة**.
`_loadLicenseData()` يستخرج Company Context من `RW_STATE.app.company.id` ثم fallbacks توافقية، ويقيد `app_settings` بـ`company_id`.

### Main11
الحالة الحالية: **إصلاح Tenant موجود بالفعل**.
`RW_HR.render()` يستخرج `_rwCompanyId()` ويقيد `users` بـ`.eq('company_id', companyId)`.
لا تُعاد جراحة Report114 نفسها.

## 5. Production Inventory Core
تمت إعادة اكتشاف الدوال ذات الصلة مباشرة من `pg_proc`.

Physical writer الفعلي المركزي هو:
`post_stock_movement(p_company_id, p_movement_type, p_source_branch_id, p_target_branch_id, p_item_id, p_qty, p_voucher_id, p_reference, p_user_email, p_idempotency_key)`
وهو الذي ينفذ `UPDATE stock_branches` و`INSERT inventory_log`.

`reserve_stock` و`release_stock_reservation` يغيران `allocated_qty` فقط، ولا يعملان كـPhysical Movement Engine.

`create_vehicle_atomic` و`setup_van_stock` ينفذان initialization لإطارات المخزون/فروع السيارات، وليس movement posting مستقلًا.

## 6. Production Contract Drift المكتشف

### A) post_stock_movement overload
Production تحتوي على توقيعين:
- 9 معاملات بدون idempotency key.
- 10 معاملات مع idempotency key.

التوقيع العشرة معاملات هو الذي ينفذ الحركة المركزية الحالية ويكتب `inventory_log`.
وجود overload قديم لا يكفي وحده لإثبات أنه Consumer حي، لذلك لا يتم حذفه دون consumer/dependency audit كامل.

### B) receive_purchase_atomic
Production الحالية تحتوي على توقيع 5 معاملات ويتضمن:
`p_operation_id uuid`
بينما Edge Function `receive-purchase` المنشورة التي تمت قراءتها كانت تستدعي RPC بتوقيع 4 معاملات فقط.
هذا **Consumer/Production contract drift مثبت**.

### C) Current Edge receive-purchase
الـEdge الحالية لا تمرر `operation_id` إلى RPC، ولذلك لا يمكن اعتبار idempotency في Purchase Receiving مغلقًا.

## 7. Syntax Validation
تم تشغيل `node --check` فعليًا على بدائل الجراحة المعروفة لـMain2/Main9/Main11، وكانت النتيجة PASS.

لم يتم إعلان Full-file Syntax PASS للملفات Main1–Main11 لأن بيئة المراجعة الحالية لا توفر parser extraction موثوقًا للنص الكامل لكل ملف ضخم بما يسمح بادعاء تحقق حرفي للملف كله.

## 8. Surgical Findings

### Finding 1 — Main2 / RW_Dashboard
العنصر المعيب:
`function loadAll(fromDate, toDate)` يستخدم `companyId` في استعلامات orders/purchase_orders/customers/items دون declaration محلي.

سبب الرفض:
Runtime ReferenceError محتمل عند أول تنفيذ للمسار، مع خرق لمنهج Company Context الصريح.

البديل الجراحي الكامل:
إضافة التعريف في أول الدالة، مباشرة بعد فتحها وقبل أول استخدام لـ`companyId`:

```javascript
var companyId = _rwCompanyId();
if (!companyId) {
    showToast('سياق الشركة غير محدد', 'error');
    return;
}
```

موضع الاستبدال:
داخل `RW_Dashboard` → `function loadAll(fromDate, toDate)` في أول سطر تنفيذي للدالة.

Syntax: PASS على البديل.

### Finding 2 — Main2 / RW_Items / _loadMovementReport
العنصر المعيب:
`buildQuery()` داخل `_loadMovementReport()` يعتمد على `companyId` غير معرف.

سبب الرفض:
ReferenceError محتمل + غياب Company Context صريح.

البديل الجراحي الكامل:
في أول `async function _loadMovementReport()` بعد التحقق من `itemCode`، أضف:

```javascript
var companyId = _rwCompanyId();
if (!companyId) {
    showToast('سياق الشركة غير محدد', 'error');
    return;
}
```

موضع الاستبدال:
داخل `RW_Items` → `async function _loadMovementReport()` قبل `buildQuery()`.

Syntax: PASS على البديل.

### Finding 3 — Main2 / RW_Items category helpers
العناصر المعيبة:
`_loadCategoriesIntoSelect()` / `_openCategoryModal()` / `_deleteCategory()` / `_buildCategoryFilterFromDB()` وبعض مسارات رفع البيانات تستخدم `companyId` بلا declaration محلي.

سبب الرفض:
نفس Runtime/Company Context defect.

البديل الجراحي الكامل الموحد داخل كل دالة متأثرة:

```javascript
var companyId = _rwCompanyId();
if (!companyId) {
    showToast('سياق الشركة غير محدد', 'error');
    return;
}
```

موضع الاستبدال:
أول السطر التنفيذي داخل كل دالة متأثرة، قبل أول استعلام يستعمل `companyId`.

Syntax: PASS على البديل.

## 9. الحالة النهائية
GLOBAL INVENTORY CORE INTEGRITY = NOT YET VERIFIED CLOSED

السبب ليس وجود Physical Writer موازٍ مثبت حاليًا؛ بل لأن:
- Main2 يحتوي Runtime/Company Context defects مثبتة.
- `receive_purchase_atomic` وConsumer `receive-purchase` في حالة contract drift مثبتة.
- Full-file Syntax/Assembly/Runtime verification للـMain1–Main11 لم تُثبت 100% في هذه المراجعة.

## 10. قاعدة التنفيذ التالية
لا يتم إعلان Gold/Diamond أو Inventory Core Closed قبل:
1. جراحة Main2.
2. إعادة قراءة Main2 كاملًا بعد الجراحة.
3. Full-file syntax validation فعلي.
4. مراجعة Main1–Main11 بعد الجراحة.
5. تحديث/تصحيح `receive-purchase` ليتطابق مع توقيع Production الحالي مع operation_id.
6. Fresh Production snapshot بعد آخر نشر.
7. Runtime verification فعلي للمسارات الحرجة.
