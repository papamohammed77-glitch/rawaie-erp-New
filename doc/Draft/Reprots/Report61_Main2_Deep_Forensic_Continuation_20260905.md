# تقرير 61 — الاستكمال الجنائي العميق للجزء الثاني Main2

**التاريخ:** 2026-09-05
**المستودع:** `papamohammed77-glitch/rawaie-erp-New`
**الفرع:** `main`
**آخر Git HEAD مثبت عند بدء هذا التقرير:** `e9d0ec685737abf9b752d40acc2d97cd2aa4907e`
**الملف المستهدف:** `Current/PWA/main2/main2.md`
**الحالة:** مراجعة جنائية مستمرة — لم يتم تعديل `main2.md` في هذه الجلسة.

---

## 1. نطاق المهمة والحكم الحاكم

هذه الجلسة استمرار مباشر للعمل السابق وليست إعادة تشغيل من الصفر.
تم تطبيق:

```text
CURRENT_STATE
→ LAST VERIFIED EVENT
→ CURRENT GIT
→ CURRENT PRODUCTION
→ ACTIVE DEPLOYMENTS / RUNTIME CONTRACTS
→ CURRENT SOURCE
→ RECONCILIATION
→ SURGICAL FINDINGS
```

لم يتم اعتبار Report60 أو CURRENT_STATE مصدرًا نهائيًا للحاضر؛ لأن Git الحالي تجاوزهما بوضوح.

المبدأ الحاكم هو أن الدراسة تسبق التعديل، وأن `UNKNOWN != BUG` و`UNKNOWN != REMOVE`، وأن كل Claim يحتاج دليلًا حاليًا، وأن Main2 جزء منطقي من النظام الأم وليس ملفًا مستقلًا.

---

## 2. استرجاع الحالة ومصالحة الانحراف الزمني

### CURRENT_STATE عند بداية المهمة

`CURRENT_STATE.md` كان يعلن أن آخر حالة موثقة هي `dde004b94b...` وأن Report60 ترك M2-02 وM2-04 مفتوحين.

### CURRENT GIT الحالي

أثبت Git history أن الحالة تجاوزت ذلك بالفعل:

```text
ac360fbe6626979e4dd43cec34b04a1c3e61b210
fix(main2): remove residual undefined orderIds and scope barcode lookup
```

وهذا commit غيّر فعليًا `Current/PWA/main2/main2.md` بحذف الاستعلام القديم الذي يستخدم `orderIds` وإضافة `company_id` إلى barcode lookup.

ثم:

```text
e9d0ec685737abf9b752d40acc2d97cd2aa4907e
 docs(cto): add Report60 Main2 surgical completion and self-audit
```

هو آخر commit حالي، وهو توثيقي فقط.

### CURRENT SOURCE

تمت إعادة قراءة `Current/PWA/main2/main2.md` مباشرة من `main`، وSHA الحالي للملف:

```text
15f101d3bea93baa5419bdca48e401ad71bbac6c
```

وبالتالي أصبح تقرير60 مرجعًا تاريخيًا لا يصلح لإثبات أن M2-02/M2-04 ما زالا مفتوحين.

---

## 3. Production Reality — لقطة مستقلة حديثة

تم إجراء استعلام مباشر على Production `SMART ERP / fiilmooggumokxanwiyx`.

اللقطة الحالية التي تم إثباتها أثناء هذه الجلسة:

```text
companies      = 1
app_settings   = 1
orders         = 0
purchase_orders= 0
branches       = 2
items          = 17
stock_branches = 20
inventory_log  = 3
```

كما تم التحقق مباشرة من أن:

```text
items.item_code = UNIQUE عالميًا
```

ولم توجد حاليًا باركودات مكررة في `items`.

لم يتم إدخال بيانات دائمة إلى Production ضمن هذه الجلسة.

---

## 4. Production Contract Verification المرتبط بـMain2

تمت قراءة `post_inventory_adjustment_atomic` من Production مباشرة.

العقد الحالي:

```text
SECURITY DEFINER
Authenticated user → users.email → users.company_id
Branch must belong to company
Item identity = item_id + item_code
Physical mutation → post_stock_movement
Idempotency key = InventoryAdjustment:<company_id>:<voucher_code>:<item_id>
Return = success + duplicate + movement_count + voucher_code + company_id
```

تم إجراء اختبار Transactional على Production باستخدام بيانات موجودة فعليًا ثم `ROLLBACK`.

النتيجة المثبتة:

```text
Same voucher_code → idempotency path
Different voucher_code → movement executes again
```

والاختبار لم يترك أثرًا دائمًا لأن العملية انتهت بـ`ROLLBACK`.

النتيجة مهمة مباشرة لـM2-07.

---

# 5. حالة الإصلاحات السابقة M2-01 … M2-08

| البند | الحكم الحالي | الدليل |
|---|---|---|
| M2-01 | مغلق في المصدر الحالي | استعلام Dashboard مع company scope |
| M2-02 | مغلق في المصدر الحالي | commit `ac360f…` حذف `orderIds` |
| M2-03 | مغلق في المصدر الحالي | Category replacement scoped |
| M2-04 | مغلق في المصدر الحالي | commit `ac360f…` أضاف company scope للـbarcode lookup |
| M2-05 | مغلق في المصدر الحالي | `_valid` + تنفيذ الصفوف المعتمدة فقط |
| M2-06 | مغلق في المصدر الحالي | `movement_count` متوافق مع Production |
| M2-07 | **أعيد فتحه كعيب ثانوي جديد** | stale upload state بعد النجاح + Production key contract |
| M2-08 | مغلق في المصدر الحالي | movement voucher query company-scoped |

مهم: إعادة فتح M2-07 ليست إعادة فتح للإصلاح السابق نفسه؛ بل عيب replay مختلف ظهر بعد مراجعة ما بعد الكتابة.

---

# 6. العيب الجديد M2-07R — إعادة تنفيذ التسوية بعد نجاحها

## FINDING

في `_executeUpload()` يتم إنشاء:

```javascript
_uploadOperationId
_uploadOperationFingerprint
```

ثم عند النجاح يتم تنفيذ:

```javascript
_uploadOperationId = null;
_uploadOperationFingerprint = null;
```

لكن `_uploadFileData` لا يتم تنظيفها.

وبالتالي يظل الملف السابق محملًا وتظل الصفوف `_valid` موجودة.

عند الضغط على «تنفيذ التحديث» مرة أخرى دون اختيار ملف جديد:

1. `items` تعاد بناؤها من `_uploadFileData` القديمة.
2. يتغير `voucherCode` لأن `_uploadOperationId` أصبح `null`.
3. Production ترى `voucher_code` مختلفًا.
4. idempotency السابقة لا تحمي العملية.
5. نفس adjustment يمكن أن ينفذ مرة أخرى.

هذا مثبت من المصدر ومن عقد Production، وليس استنتاجًا نظريًا.

## ROOT CAUSE

دورة حياة عملية الرفع غير مكتملة:

```text
File selected
→ Preview
→ Execute
→ Success
```

لكن state الخاصة بالملف لا تنتهي مع نجاح العملية.

## SURGICAL FIX — المطلوب من المستخدم تنفيذه في Main2

في success branch داخل `_executeUpload()`، استبدل:

```javascript
_uploadOperationId = null;
_uploadOperationFingerprint = null;
```

بـ:

```javascript
_uploadFileData = [];
_uploadOperationId = null;
_uploadOperationFingerprint = null;
var uploadFileInput = byId('upload-file-input');
if (uploadFileInput) uploadFileInput.value = '';
```

ويُفضّل إبقاء بقية success flow كما هي.

### لماذا هذا هو الإصلاح الصحيح؟

لأنه لا يعبث بعقد Production ولا يحاول اختراع idempotency جديدة؛ بل يغلق lifecycle المحلي للعملية بعد نجاحها.

### ما الذي يجب عدم فعله؟

لا تغيّر Production idempotency key لتصبح أقل حساسية.

ولا تستخدم نفس `voucherCode` بعد نجاح مستقل جديد.

ولا تعتبر الضغط الثاني duplicate إذا كان المستخدم حمّل ملفًا جديدًا.

---

# 7. العيب الجديد M2-09 — فلاتر تقرير حركة الصنف لا تدخل في الاستعلام

## FINDING

`_loadMovementReport()` يقرأ:

```javascript
var fromDate = ...
var toDate = ...
```

ويستخدم `window._movementBranchId` في موضع التخزين، لكن استعلام `stock_vouchers` الحالي هو فعليًا:

```javascript
var vouchersRes = await supabase.from('stock_vouchers')
    .select('id, voucher_code, voucher_date, type, reference, from_branch_id, to_branch_id')
    .eq('company_id', companyId)
    .order('voucher_date', { ascending: true });
```

لا يوجد فيه date scope، ولا branch scope.

إذًا واجهة التقرير توهم المستخدم بأن التاريخ/الفرع يحددان النتيجة، بينما الاستعلام لا يطبقهما.

## ROOT CAUSE

الـUI contract موجود، لكن الـdata query لم يُوصل به.

## SURGICAL FIX — استبدال استعلام vouchers فقط

استبدل الكتلة الحالية:

```javascript
var vouchersRes = await supabase.from('stock_vouchers').select('id, voucher_code, voucher_date, type, reference, from_branch_id, to_branch_id').eq('company_id', companyId).order('voucher_date', { ascending: true });
```

بالكتلة التالية:

```javascript
var vouchersQuery = supabase.from('stock_vouchers')
    .select('id, voucher_code, voucher_date, type, reference, from_branch_id, to_branch_id')
    .eq('company_id', companyId);

if (fromDate) {
    vouchersQuery = vouchersQuery.gte('voucher_date', fromDate);
}
if (toDate) {
    vouchersQuery = vouchersQuery.lte('voucher_date', toDate);
}
if (window._movementBranchId) {
    vouchersQuery = vouchersQuery.or(
        'from_branch_id.eq.' + window._movementBranchId + ',to_branch_id.eq.' + window._movementBranchId
    );
}

var vouchersRes = await vouchersQuery.order('voucher_date', { ascending: true });
```

هذا الإصلاح يحافظ على company scope الحالي ويضيف فقط القيود التي يعلنها الـUI بالفعل.

---

# 8. عيب أمني مستقل M2-10 — مسار حذف الصنف غير محمي على مستوى الخادم

هذا العيب يقع بين Main2 وEdge Function، لذلك لا يجوز إغلاقه بتعديل الواجهة وحدها.

## FINDING

Main2 يعرض زر:

```text
حذف الصنف
```

داخل `openItemPage()` عند التعديل دون شرط صلاحية مستقل.

ثم يرسل:

```javascript
fetch(...'/functions/v1/delete-item' ... body: JSON.stringify({item_code:item.item_code}))
```

والـProduction Edge Function الحالية `delete-item`:

- تتحقق من وجود Authorization.
- تتحقق من جلسة المستخدم.
- ثم تنفذ delete باستخدام service role.
- ولا تتحقق من role/permission المناسبة للحذف.

لذلك المصادقة ليست Authorization كافية هنا.

## CONTRACT CONCLUSION

لأن `item_code` UNIQUE عالميًا، عدم وجود company filter في lookup نفسه ليس أصل المشكلة.

أصل المشكلة هو:

```text
Authenticated != Authorized to Delete
```

## Main2 mitigation — ليس إغلاقًا كاملًا

يمكن إخفاء زر الحذف في Main2 عن غير المصرح لهم، مثلًا باستخدام عقد الصلاحيات الموجود:

```javascript
var canDeleteItem = isEdit && (
    RW_STATE.app.currentUser && RW_STATE.app.currentUser.isOwner === true ||
    RW_Permissions_check('item_delete')
);

if (canDeleteItem) {
    html += '<button onclick="RW_Items._handleDeleteFromPage()" class="px-5 py-2.5 bg-red-600 text-white rounded-xl font-bold mr-auto"><i class="fa-solid fa-trash ml-1"></i> حذف الصنف</button>';
}
```

لكن هذا **ليس إغلاقًا أمنيًا** ما دام `delete-item` نفسه لا يفرض Authorization server-side.

لذلك M2-10 = `OPEN / CROSS-LAYER SECURITY CLOSURE REQUIRED`.

لا ينبغي اعتبار هذا الإغلاق مكتملًا بمجرد إخفاء الزر.

---

# 9. مرشحان للمراجعة — ممنوع ترقيعهما بالتخمين الآن

## 9.1 صافي الربح

الكود يحسب:

```javascript
net = totalSales - totalPurchases
```

ثم يعرضه على أنه `صافي الربح`.

لكن Production/accounting architecture تحتوي COGS وحسابات ومخزون، لذلك لا يوجد دليل كافٍ هنا على أن `purchase_orders.total_amount` هو تعريف صافي الربح المطلوب في RAWAEA.

الحكم:

```text
SEMANTIC CONTRACT UNKNOWN
DO NOT PATCH IN THIS CLOSURE UNIT
```

المطلوب في وحدة لاحقة: تتبع العقد المحاسبي الحالي قبل تغيير المعادلة.

## 9.2 Top Customers

الرسم يجمع حسب:

```javascript
customer_name
```

وليس `customer_id`.

قد يكون ذلك مقصودًا أو قد يدمج عملاء مختلفين لهم الاسم نفسه.

الحكم:

```text
POTENTIAL SEMANTIC DEFECT
CONTRACT NOT YET PROVEN
NO PATCH NOW
```

---

# 10. ملاحظات أمنية إضافية من المصدر

وجدت مواضع في واجهة Main2 تضع بعض قيم قاعدة البيانات مباشرة داخل HTML، خصوصًا أسماء التصنيفات وبعض بيانات الأصناف.

المثال الأوضح في Category Modal:

```javascript
'<span ...>' + catName + '</span>'
```

مع تمرير الاسم أيضًا إلى JavaScript inline.

هذا يفتح احتمال Stored/DOM XSS إذا دخلت قيمة غير موثوقة إلى الحقول.

لم يتم تصنيف هذا ضمن M2-07/M2-09 لأن إصلاحه يحتاج closure أمني منفصل يحافظ على DOM contract بالكامل، ولم يتم تغيير المصدر في هذه الجلسة.

---

# 11. ما لم يتم تغييره في هذه الجلسة

```text
Current/PWA/main2/main2.md     = NOT MODIFIED BY THIS SESSION
Current/PWA/main2/main1.md     = NOT MODIFIED
main3.md … main11.md           = NOT MODIFIED
New-main                         = NOT MODIFIED
core.js                          = NOT MODIFIED
sw.js                            = NOT MODIFIED
register-sw.js                   = NOT MODIFIED
manifest.json                    = NOT MODIFIED
Production data                  = NOT modified permanently
```

التغيير في هذه الجلسة كان تشخيصيًا وتوثيقيًا فقط.

---

# 12. الاختبارات والتجارب

### Test A — Production adjustment contract

تم تنفيذ adjustment داخل Transaction ثم اختبار إعادة نفس المفتاح وتغيير المفتاح، ثم `ROLLBACK`.

النتيجة المثبتة:

```text
Different voucher_code → duplicate=false + movement_count=1
```

وهذا يثبت أن تغيير `voucherCode` يفتح تنفيذًا جديدًا.

### Test B — Production current-state snapshot

تم قياس counts مباشرة من Production.

النتيجة:

```text
companies=1
app_settings=1
orders=0
purchase_orders=0
branches=2
items=17
stock_branches=20
inventory_log=3
```

### Test C — Git reconciliation

تمت مراجعة Git history وأُثبت أن `ac360f…` أغلق فعليًا M2-02 وM2-04 بعد Report60.

---

# 13. WHAT I PROVED

1. Report60 أصبح تاريخيًا فيما يتعلق بـM2-02/M2-04؛ Git الحالي أغلقهما.
2. `main2.md` الحالي يحمل SHA `15f101d…` ويتم قراءته من `main` مباشرة.
3. Production الحالية تحتوي شركة واحدة فقط و17 صنفًا و20 stock rows و3 inventory logs ولا تحتوي orders/POs حاليًا.
4. `items.item_code` عليه UNIQUE عالميًا في Production.
5. Production adjustment engine يستخدم `voucher_code` داخل idempotency key.
6. تغيير `voucher_code` يسمح بتنفيذ حركة جديدة.
7. Main2 يمسح `_uploadOperationId` بعد النجاح دون مسح `_uploadFileData`.
8. Main2 يقرأ date/branch filters في movement report لكن لا يمررها إلى voucher query.
9. delete-item الحالي يثبت Authentication لكنه لا يثبت Authorization للحذف.

---

# 14. WHAT I DID NOT PROVE

1. Main2 assembled parent artifact.
2. Browser/runtime verification للـ11-part assembly.
3. أن المعادلة الحالية لصافي الربح خاطئة تجاريًا؛ تم إثبات أنها تحتاج عقدًا قبل التغيير فقط.
4. أن customer_name grouping مرفوض تجاريًا؛ فقط ثبت أنه يحتاج contract review.
5. الإغلاق الأمني الكامل لـdelete-item.

---

# 15. NEXT AUTHORIZED ACTION

العمل المسموح به الآن على Main2 هو:

```text
1. Apply M2-07R surgical state cleanup
2. Apply M2-09 movement report query wiring
3. Re-read changed regions
4. Static/syntax verification
5. Verify no unrelated diff
6. Commit Main2 source mutation
7. Reconcile CURRENT_STATE
8. Close M2-07R and M2-09 only when source evidence is re-read
```

ثم وحدة مستقلة:

```text
M2-10 delete authorization
```

ولا يجوز القفز إلى assembly أو `core.js/sw.js/register-sw.js/manifest.json` قبل اكتمال Main2 source closure الحالي.

---

# 16. FINAL SELF-AUDIT

```text
Business Understanding           = CONFIRMED for reviewed Main2 surfaces
Architecture Understanding      = CONFIRMED for current main1/main2 relationship and inventory contract
Database Understanding           = DIRECTLY VERIFIED
Production Understanding         = DIRECTLY VERIFIED
Current Git Understanding        = DIRECTLY VERIFIED
Current Source Understanding    = DIRECTLY VERIFIED
Historical Understanding         = RECONCILED against Report60/Report59 lineage

CRITICAL UNKNOWN                 = 0 for M2-07R and M2-09 root causes
SECURITY CROSS-LAYER UNKNOWN     = 1 (exact server-side permission contract for item deletion)

WHAT I FIXED                    = Documentation/reconciliation only
WHAT I DID NOT CHANGE           = main2.md and Production business data
WHAT I INITIALLY MISSED         = replay risk after clearing operation id
WHAT REMAINS OPEN               = M2-07R, M2-09, M2-10, semantic review candidates

CURRENT STATUS
MAIN2 SOURCE = NOT CLOSED
M2-02/M2-04  = CLOSED IN CURRENT GIT
M2-07R       = OPEN
M2-09        = OPEN
M2-10        = OPEN / CROSS-LAYER SECURITY
RUNTIME      = OPEN
ASSEMBLY     = OPEN
PRODUCTION PWA RUNTIME = NOT VERIFIED
```

---

## 17. GOVERNANCE VERDICT

تم الحفاظ على قاعدة:

```text
لا إعادة بدء
لا إعادة تطبيق لإصلاح مغلق
لا ثقة عمياء في Report60
لا تخمين في semantic contracts
لا تعديل على main2.md من هذه الجلسة
لا بيانات Production دائمة للاختبار
```

والخطوة الصحيحة ليست "البدء من جديد"، بل تطبيق التعديلين الجراحيين المحددين أعلاه بواسطة مالك الملف، ثم إعادة القراءة والإثبات قبل إعلان أي إغلاق جديد.
