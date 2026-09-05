# تقرير 62 — المراجعة الجراحية المعمقة للجزء الثاني Main2

**التاريخ:** 2026-09-05  
**المستودع:** `papamohammed77-glitch/rawaie-erp-New`  
**الفرع:** `main`  
**آخر Git HEAD المثبت أثناء الجلسة:** `e12d6d910f298dddbd17d9af2781a78ca9560050`  
**الملف المستهدف:** `Current/PWA/main2/main2.md`  
**قرار أساسي:** لم يتم تعديل `main2.md` من المساعد. التنفيذ اليدوي للملف من مسؤولية مالك المشروع كما طلب صراحة.

---

## 1. نطاق الجلسة

هذه الجلسة استمرار مباشر وليست إعادة تشغيل.
تم الرجوع إلى:

- `doc/Draft/medhat/MASTER - RAWAEA ERP.md`
- `CURRENT_STATE.md`
- `Report59_Main2_Surgical_Forensic_20260905.md`
- `Report60_Main2_Surgical_Completion_20260905.md`
- `Report61_Main2_Deep_Forensic_Continuation_20260905.md`
- `Current/PWA/main2/main1.md`
- `Current/PWA/main2/main2.md`
- `Current/PWA/core.js`
- Production `SMART ERP / fiilmooggumokxanwiyx`
- Git history الحالي.

تم تطبيق قاعدة:

```text
READ → VERIFY → RECONCILE → UNDERSTAND → SURGICAL FINDING
```

ولم يتم استخدام أي تقرير قديم لإثبات الحالة الحالية دون إعادة التحقق.

---

## 2. مصالحة الحالة قبل الفحص

`CURRENT_STATE.md` كان يشير إلى:

```text
dd6da64a1615ffbedd3d548c4f9668a2efa3b9f5
```

لكن Git الحالي أثبت أن المشروع تجاوز هذا الحد إلى:

```text
e12d6d910f298dddbd17d9af2781a78ca9560050
```

وعنوانه:

```text
docs(cto): reconcile CURRENT_STATE after Main2 deep forensic review
```

إذًا تم إثبات أن `CURRENT_STATE.md` نفسه كان متأخرًا عن HEAD الحالي، وسيتم تحديثه بعد هذا التقرير.

---

## 3. Production synchronization الحالية

تم أخذ لقطة مباشرة من Production في:

```text
2026-09-05 01:21:11.637601 +00
```

النتائج:

```text
companies       = 1
app_settings    = 1
orders          = 0
purchase_orders = 0
branches        = 2
items           = 17
stock_branches  = 20
inventory_log   = 3
```

والتحقق من البنية أثبت:

```text
items.item_code                = UNIQUE عالميًا
stock_branches(branch_id,item_id) = UNIQUE
receiving.operation_id         = UNIQUE
items.barcode                  = ليس عليه UNIQUE
```

كما تم التحقق أن عدد مجموعات الباركود غير الفريدة غير الفارغة حاليًا = 0.

---

# 4. ما أُغلق بالفعل ولا يجب إعادة فتحه

لا توجد أدلة حالية متناقضة مع الإغلاقات التالية:

```text
M2-01 = CLOSED
M2-02 = CLOSED — commit ac360f
M2-03 = CLOSED
M2-04 = CLOSED — commit ac360f
M2-05 = CLOSED
M2-06 = CLOSED
M2-08 = CLOSED
```

لذلك لم تتم إعادة صياغة هذه البنود.

---

# 5. M2-07R — عيب دورة حياة عملية الرفع

## الثبوت

في success branch داخل `_executeUpload()` ما زال المصدر يحتوي على:

```javascript
_uploadOperationId = null;
_uploadOperationFingerprint = null;
```

بينما يظل `_uploadFileData` محملاً.

هذا يسمح بإعادة الضغط على التنفيذ بالبيانات القديمة مع إنشاء هوية عملية جديدة.

Production adjustment idempotency مرتبطة بـ:

```text
InventoryAdjustment:<company_id>:<voucher_code>:<item_id>
```

وبالتالي تغيير `voucher_code` يغيّر هوية العملية.

## الإصلاح الجراحي اليدوي

ابحث **داخل success branch في `_executeUpload()` مباشرة بعد نجاح الاستجابة وقبل `RW_Data.loadItems()`** عن:

```javascript
_uploadOperationId = null;
_uploadOperationFingerprint = null;
```

احذف السطرين بالكامل.

واستبدلهما بـ:

```javascript
_uploadFileData = [];
_uploadOperationId = null;
_uploadOperationFingerprint = null;
var uploadFileInput = byId('upload-file-input');
if (uploadFileInput) uploadFileInput.value = '';
```

### لا تفعل

لا تغيّر Production idempotency key لتعويض المشكلة.
ولا تمسح `_uploadFileData` قبل إرسال الطلب.

---

# 6. M2-09 — تقرير حركة الصنف لا يطبق التاريخ/الفرع

## الثبوت

الدالة `_loadMovementReport()` تقرأ:

```javascript
var fromDate = ...
var toDate = ...
```

وتستخدم:

```javascript
window._movementBranchId
```

لكن استعلام `stock_vouchers` الحالي يطبق `company_id` فقط.

## الإصلاح الأول: query wiring

ابحث **داخل `_loadMovementReport()`** عن هذا السطر الكامل:

```javascript
var vouchersRes = await supabase.from('stock_vouchers').select('id, voucher_code, voucher_date, type, reference, from_branch_id, to_branch_id').eq('company_id', companyId).order('voucher_date', { ascending: true });
```

احذفه واستبدله بالكامل بـ:

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

## الإصلاح الثاني: منع بقاء branch filter قديم

داخل `_renderStockMovementReport(itemCode, itemName, branchId, branchName)` ابحث عن الكتلة:

```javascript
if (itemCode) {
    window._movementItemCode = itemCode;
    window._movementItemName = itemName || '';
    window._movementBranchId = branchId || null;
    window._movementBranchName = branchName || '';
    setTimeout(function() { _loadMovementReport(); }, 300);
}
```

احذفها واستبدلها بـ:

```javascript
window._movementItemCode = itemCode || null;
window._movementItemName = itemName || '';
window._movementBranchId = branchId || null;
window._movementBranchName = branchName || '';

if (itemCode) {
    setTimeout(function() { _loadMovementReport(); }, 300);
}
```

الهدف: عند فتح التقرير العام بدون فرع لا يبقى filter قديم من نقرة سابقة.

---

# 7. M2-10 — حذف الصنف: لا تغلقه بتعديل Main2 وحده

Production `delete-item` الحالية تثبت Authentication فقط، ثم تنفذ:

```text
items.delete().eq(item_code)
```

ولا يوجد فيها Role/Permission Authorization.

وفي Main2 زر الحذف يظهر مباشرة عند `isEdit`.

## القرار

**لا يوجد Patch آمن مكتمل لـM2-10 في Main2 وحده حتى الآن.**

السبب أن permission key الصحيح للحذف غير مثبت في العقد الحالي، ولا يجوز اختراع اسم صلاحية جديد.

إذن:

```text
M2-10 = OPEN / CROSS-LAYER SECURITY CLOSURE
```

لا تعتمد على إخفاء الزر كإغلاق أمني.

الخطوة الصحيحة لاحقًا: إصلاح Authorization في `delete-item` أولًا، ثم مواءمة زر Main2 مع نفس العقد المثبت.

---

# 8. M2-11 — خطر HTML/DOM/Inline-JS Injection

## الثبوت

`core.js` يحتوي على:

```javascript
function safeHTML(element, html) {
    if (element) {
        try { element.innerHTML = html; } catch(e) { console.error('safeHTML error:', e); }
    }
}
```

أي أن `safeHTML` ليس sanitizer؛ فهو فقط يكتب `innerHTML`.

ويحتوي `core.js` أيضًا على:

```javascript
function esc(s) {
    return String(s == null ? '' : s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/\"/g, '&quot;');
}
```

بينما Main2 يحتوي على `_esc()` أضعف ولا يهرب علامات الاقتباس.

## الإصلاح الجراحي المقترح

داخل `RW_Items` ابحث عن:

```javascript
function _esc(s) {
    return String(s || '').replace(/[&<>]/g, function(m) {
        return m === '&' ? '&amp;' : m === '<' ? '&lt;' : '&gt;';
    });
}
```

واستبدله بـ:

```javascript
function _esc(s) {
    return esc(s == null ? '' : String(s));
}

function _jsString(s) {
    return JSON.stringify(s == null ? '' : String(s));
}
```

ثم في **أماكن HTML النصية/attributes** استخدم `_esc(...)` بدل القيم الخام.

أهم المواضع المؤكدة في Main2:

```javascript
categories[i].category_name
item.name
item.category
item.barcode
item.description
item.image_url
currentName
name
entry.barcode
```

مثال محدد:

ابحث عن:

```javascript
html += '<option value="' + categories[i].id + '"' + selected + '>' + categories[i].category_name + '</option>';
```

واستبدله بـ:

```javascript
html += '<option value="' + _esc(categories[i].id) + '"' + selected + '>' + _esc(categories[i].category_name) + '</option>';
```

وفي `_renderUploadPreview()`:

ابحث عن:

```javascript
'<td class="p-2 font-mono">' + entry.barcode + '</td><td class="p-2">' + (item ? item.name : '---') + '</td>'
```

واستبدله بـ:

```javascript
'<td class="p-2 font-mono">' + _esc(entry.barcode) + '</td><td class="p-2">' + _esc(item ? item.name : '---') + '</td>'
```

وفي `_openCategoryModal()` لا تمرر `catName` الخام داخل inline JavaScript.

ابحث عن:

```javascript
onclick="RW_Items._editCategory('" + catId + "', '" + catName.replace(/'/g, "\\'") + "')"
```

واستبدل هذا الأسلوب باستدعاء يستخدم `_jsString`، مثل:

```javascript
onclick="RW_Items._editCategory(" + _jsString(catId) + ", " + _jsString(catName) + ")"
```

مهم: `JSON.stringify()` هنا مقصود كسياق JavaScript، وليس `_esc()`.

## تصنيف

```text
M2-11 = SECURITY CLOSURE / SOURCE OPEN
```

ولا يعتبر هذا البند مغلقًا إلا بعد حصر كل raw database/file values التي تدخل `innerHTML` أو inline handlers وتحويلها إلى السياق الصحيح.

---

# 9. M2-12 — Barcode ambiguity / Future-proofing

Production تثبت أن `items.barcode` ليس عليه UNIQUE، رغم أن Production الحالية لا تحتوي duplicate non-empty barcode groups.

والـupload preview يستخدم map من نوع:

```javascript
itemMap[it.barcode] = it;
```

وهذا يعني أن وجود barcode مكرر مستقبلًا سيؤدي إلى last-write-wins غير حتمي.

## الإصلاح الوقائي

داخل `_renderUploadPreview()` ابحث عن الكتلة:

```javascript
var itemMap = {};
var itemCodes = [];
for (var im = 0; im < (itemsRes.data || []).length; im++) {
    var it = itemsRes.data[im];
    if (it.barcode) itemMap[it.barcode] = it;
    itemCodes.push(it.item_code);
}
// ✅ تحديث _uploadFileData بـ item_code الحقيقي من قاعدة البيانات
for (var f = 0; f < _uploadFileData.length; f++) {
    var mappedItem = itemMap[_uploadFileData[f].barcode];
    if (mappedItem) {
        _uploadFileData[f].item_code = mappedItem.item_code;
    }
}
```

احذفها واستبدلها بـ:

```javascript
var itemMap = {};
var duplicateBarcodeMap = {};
for (var im = 0; im < (itemsRes.data || []).length; im++) {
    var it = itemsRes.data[im];
    if (!it.barcode) continue;
    if (itemMap[it.barcode]) {
        duplicateBarcodeMap[it.barcode] = true;
    } else {
        itemMap[it.barcode] = it;
    }
}

for (var f = 0; f < _uploadFileData.length; f++) {
    var barcodeValue = _uploadFileData[f].barcode;
    if (duplicateBarcodeMap[barcodeValue]) {
        _uploadFileData[f]._invalidReason = 'باركود غير فريد';
        delete _uploadFileData[f].item_code;
    } else {
        var mappedItem = itemMap[barcodeValue];
        if (mappedItem) _uploadFileData[f].item_code = mappedItem.item_code;
    }
}
```

ثم في نفس loop الخاص بتكوين `status` ابحث عن:

```javascript
if (!item) { status = '❌ باركود غير موجود'; statusClass = 'bg-red-50'; invalidCount++; }
else {
```

واستبدله ببداية:

```javascript
if (duplicateBarcodeMap[entry.barcode]) {
    status = '❌ الباركود غير فريد';
    statusClass = 'bg-red-50';
    invalidCount++;
} else if (!item) {
    status = '❌ باركود غير موجود';
    statusClass = 'bg-red-50';
    invalidCount++;
} else {
```

هذا **وقاية مستقبلية** وليس إصلاح فساد حالي؛ لأن Production الحالية = صفر duplicate groups.

---

# 10. بنود لم يتم ترقيعها عمدًا

## صافي الربح

الكود الحالي:

```javascript
net = totalSales - totalPurchases
```

لم يتم تغييره؛ العقد المحاسبي الصحيح غير مثبت بعد.

## Top Customers

التجميع حسب `customer_name` لم يتم تغييره؛ العقد التجاري/المحاسبي لم يثبت أنه يجب أن يكون `customer_id`.

## branchIds fallback

لم يتم تغييره؛ لا يوجد دليل كافٍ أن fallback إلى `branch_code` خطأ في هذا السياق.

## M2-10 permission key

لم يتم اختراعه.

---

# 11. الاختبارات والتجارب

### Production snapshot

PASS — قياس مباشر حديث.

### Git reconciliation

PASS — HEAD الحالي = `e12d6d9…`، وتبين أن Report61/CURRENT_STATE لم يعودا أحدث نقطة Git.

### Main2 source re-read

PASS — تمت إعادة قراءة المصدر الحالي مباشرة، وM2-07R/M2-09 ما زالا قائمين.

### Production adjustment contract

PASS — `post_inventory_adjustment_atomic` الحالي منشور `SECURITY DEFINER` ويعتمد هوية العملية على `voucher_code`.

### Production bulk-stock-adjustment

PASS — Edge Function الحالية Version 6 تستخرج `company_id` من `users.auth_id` ولا تستخدم `app_settings LIMIT 1`.

### Production delete-item

PASS كتشخيص — Authentication موجودة، Authorization غير مثبتة.

### Browser/runtime Main2

NOT RUN — لأن `main2.md` لم يُعدّل يدويًا بعد، والمهمة الحالية طلبت أن يقوم المالك بالتعديل بنفسه.

### Permanent test data

لم تُضف بيانات أعمال دائمة إلى Production لهذه المراجعة.

---

# 12. أخطاء/إخفاقات هذه الجلسة

لا يوجد فشل تنفيذي في تعديل `main2.md`؛ عدم تعديل الملف كان قرارًا صريحًا وفق طلب المستخدم.

القيود التي يجب تسجيلها:

1. GitHub write primitive المتاح يستبدل الملف كاملًا، وليس patch line-range؛ لذلك لم يُستخدم لتعديل `main2.md`.
2. لم يتم إعلان Runtime Closure لأن المصدر لم يتغير بعد.
3. لم يتم إخفاء M2-10 خلف UI workaround بسبب عدم ثبوت permission key.

---

# 13. ما تم إنجازه فعليًا

```text
MASTER = READ / RECONCILED
CURRENT_STATE = READ / DRIFT DETECTED
Report59 = READ
Report60 = READ
Report61 = READ
main1 = READ FOR CONTRACT CONTEXT
main2 = FULL SOURCE READ / RECHECKED
core.js = READ FOR ESC/SafeHTML CONTRACT
Production = DIRECTLY VERIFIED
Git history = DIRECTLY VERIFIED

main2.md source mutation by assistant = NONE
```

تم إعداد الإصلاحات اليدوية الدقيقة لـ:

```text
M2-07R
M2-09
M2-11
M2-12
```

وتم تثبيت M2-10 كـcross-layer open item.

---

# 14. FINAL SELF-AUDIT

## WHAT I PROVED

- الحالة الحالية في Git تجاوزت CURRENT_STATE السابق.
- `main2.md` الحالي هو المصدر المباشر الذي تمت مراجعته.
- M2-02 وM2-04 مغلقان بالفعل في Git الحالي ولا يجب إعادة فتحهما.
- M2-07R ما زال مفتوحًا.
- M2-09 ما زال مفتوحًا.
- M2-10 حقيقي ويحتاج server-side Authorization.
- `safeHTML` في core ليس sanitizer.
- Main2 لديه raw HTML/raw inline-JS data paths تستوجب security closure.
- `barcode` ليس globally unique، لكن Production الحالية لا تحتوي duplicates.
- `bulk-stock-adjustment` الحالي Tenant-safe عبر `users.auth_id → company_id`.

## WHAT I DID NOT PROVE

- browser/runtime نجاح Main2 بعد الإصلاحات اليدوية.
- assembled 11-part parent artifact.
- final PWA production equivalence.
- business contract النهائي لصافي الربح.
- contract النهائي لتجميع Top Customers.
- server-side delete authorization closure.

## WHAT I CHANGED

- أضفت هذا التقرير.
- سأحدّث `CURRENT_STATE.md` ليعكس HEAD الحالي وهذا التقرير.

## WHAT I DID NOT CHANGE

- `Current/PWA/main2/main2.md`
- `main1.md`
- `main3…main11`
- `New-main`
- `core.js`
- `sw.js`
- `register-sw.js`
- `manifest.json`
- لا بيانات أعمال Production بشكل دائم.

## FINAL STATUS

```text
MAIN2 FORENSIC REVIEW = CURRENT
M2-01 = CLOSED
M2-02 = CLOSED
M2-03 = CLOSED
M2-04 = CLOSED
M2-05 = CLOSED
M2-06 = CLOSED
M2-07R = OPEN / MANUAL SURGICAL PATCH REQUIRED
M2-08 = CLOSED
M2-09 = OPEN / MANUAL SURGICAL PATCH REQUIRED
M2-10 = OPEN / CROSS-LAYER SECURITY
M2-11 = OPEN / SECURITY SURGERY
M2-12 = OPEN / PREVENTIVE INTEGRITY HARDENING
MAIN2 SOURCE = OPEN
MAIN2 RUNTIME = OPEN
ASSEMBLY = OPEN
```

## NEXT AUTHORIZED ACTION

المالك ينفذ يدويًا:

```text
1. M2-07R
2. M2-09
3. M2-11
4. M2-12
```

ثم تتم إعادة قراءة `main2.md` من Git وإجراء static/syntax review وdiff review.
بعد ذلك تكون وحدة مستقلة لـM2-10 server-side authorization.
ثم فقط يمكن الانتقال إلى تجميع الأجزاء الـ11.

---

## GOVERNANCE VERDICT

```text
لا إعادة بدء
لا إعادة فتح إصلاحات مغلقة دون دليل جديد
لا تعديل للمصدر بوسيلة whole-file غير آمنة
لا اختراع permission keys
لا اختراع business contracts
لا اعتبار Git دليل Runtime
لا اعتبار Production snapshot القديم دليلًا للحاضر
لا إعلان إغلاق قبل إعادة الإثبات
```

هذا التقرير هو سجل الاستكمال الحالي لجلسة 2026-09-05.