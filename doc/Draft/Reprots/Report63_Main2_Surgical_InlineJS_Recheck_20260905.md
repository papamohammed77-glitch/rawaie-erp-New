# تقرير 63 — المراجعة الجراحية النهائية لمواضع Inline-JS في Main2

**التاريخ:** 2026-09-05  
**المستودع:** `papamohammed77-glitch/rawaie-erp-New`  
**الفرع:** `main`  
**Current Git HEAD أثناء المراجعة:** `d9509d06a14ee8dde9621f79c72c212022179ef4`  
**Main2 source mutation commit:** `8e5fe0d7427f8e16a8094da9e86a26e486c9cea3`  
**الملف المستهدف:** `Current/PWA/main2/main2.md`  
**Production:** `SMART ERP / fiilmooggumokxanwiyx`

## 1. سبب التقرير

هذه الجلسة استمرار مباشر وليست بداية جديدة.
تمت إعادة مطابقة `CURRENT_STATE.md` مع Git الحالي، ثم تمت قراءة MASTER وتقارير Main2 السابقة، ثم فحص المصدر الحالي للجزء الثاني وتحقق Production مباشرة.

## 2. اكتشاف انحراف الحالة

`CURRENT_STATE.md` السابق كان يثبت `5f3f07e501dcd3642090d74b3e941344f7130b75` كنقطة تحقق سابقة، بينما Git الحالي تجاوزها إلى commits توثيقية ثم إلى:

```text
8e5fe0d7427f8e16a8094da9e86a26e486c9cea3
Refactor functions and enhance voucher query logic
```

وهذا الـcommit عدّل فعليًا `Current/PWA/main2/main2.md`.

لذلك لا يجوز استخدام الحالة السابقة التي قالت إن M2-07R وM2-09 ما زالا مفتوحين كدليل على المصدر الحالي.

## 3. Production synchronization

تمت لقطة Production مباشرة أثناء إعداد هذا التقرير:

```text
verified_at     = 2026-09-05 03:34:01.191895+00
companies       = 1
app_settings    = 1
orders          = 0
purchase_orders = 0
branches        = 2
items           = 17
stock_branches  = 20
inventory_log   = 3
duplicate non-empty barcodes = 0
```

والـschema المعروف من الفحص السابق ما زال يثبت:

```text
items.item_code UNIQUE
stock_branches UNIQUE(branch_id,item_id)
receiving.operation_id UNIQUE
items.barcode NOT UNIQUE
```

## 4. ما تم تطبيقه بالفعل في Main2 قبل هذا التقرير

Commit `8e5fe0d...` يثبت تطبيق الإصلاحات التالية في المصدر الحالي:

```text
M2-07R  = source-fixed
M2-09   = source-fixed
M2-12   = duplicate-barcode detection added
M2-11   = helper _esc/_jsString added, but inline-JS closure remains incomplete
```

## 5. الفحص الخاص بالمقطعين المطلوبين

### المقطع الأول

المصدر الحالي يحتوي على نمط:

```javascript
rowHtml += '<td class="p-4 text-center cursor-pointer underline text-blue-600 text-xs" onclick="RW_Items._switchSubTab(\\'movement\\'); setTimeout(function(){ RW_Items._renderStockMovementReport(\\'' + _esc(item.item_code) + '\\',\\'' + _esc(item.name).replace(/'/g, "\\\\'") + '\\',\\'' + _esc(bid2) + '\\',\\'' + _esc(branchName2).replace(/'/g, "\\\\'") + '\\'); },200);">' + st.qty + '</td>';
```

الحكم:

```text
ليس هناك خطأ نحوي ظاهر في السلسلة الحالية، لكن طريقة بناء inline JavaScript تعتمد escape يدويًا داخل HTML attribute، وهي أضعف وغير متسقة مع helper المقصود للـJavaScript context.
```

### المقطع الثاني

المصدر الحالي في مصفوفة الفروع يحتوي على نفس النمط اليدوي، ويظهر في `var rowHtml = ...` داخل:

```text
_renderBranchStockMatrix()
_renderBranchStockMatrixFiltered()
```

كما أن المستخدم أرسل نسخة تستخدم `_jsAttr(...)`.

الحكم الحاسم:

```text
_git code search لم يجد أي تعريف لـ _jsAttr داخل المستودع_
```

لذلك استخدام `_jsAttr(...)` الآن بدون إضافة helper سيؤدي إلى `ReferenceError` عند التنفيذ.

الدليل المباشر: بحث GitHub عن `_jsAttr` أعاد `total_count = 0`.

## 6. الإصلاح الجراحي النهائي المعتمد

### الخطوة 1 — إضافة helper واحد فقط

داخل `var RW_Items = (function() {` مباشرة بعد:

```javascript
function _jsString(s) {
    return JSON.stringify(s == null ? '' : String(s));
}
```

أضف:

```javascript
function _jsAttr(s) {
    return _esc(_jsString(s));
}
```

ولا تضف helper آخر بنفس الوظيفة.

### الخطوة 2 — إصلاح المقطع الأول

ابحث داخل `_applyFilters()` عن السطر الذي يبدأ حرفيًا بـ:

```javascript
rowHtml += '<td class="p-4 text-center cursor-pointer underline text-blue-600 text-xs" onclick="RW_Items._switchSubTab(\\'movement\\'); setTimeout(function(){ RW_Items._renderStockMovementReport(
```

احذف السطر كاملًا واستبدله بـ:

```javascript
rowHtml += '<td class="p-4 text-center cursor-pointer underline text-blue-600 text-xs" onclick="RW_Items._switchSubTab(\\'movement\\'); setTimeout(function(){ RW_Items._renderStockMovementReport(' + _jsAttr(item.item_code) + ',' + _jsAttr(item.name) + ',' + _jsAttr(bid2) + ',' + _jsAttr(branchName2) + '); },200);">' + st.qty + '</td>';
```

### الخطوة 3 — إصلاح المقطع الثاني داخل `_renderBranchStockMatrix()`

ابحث داخل الدالة:

```javascript
function _renderBranchStockMatrix() {
```

عن السطر الذي يبدأ بـ:

```javascript
var rowHtml = '<tr class="border-t hover:bg-gray-50"><td class="p-3 cursor-pointer font-bold text-blue-600" onclick="RW_Items._switchSubTab(\\'movement\\');
```

احذف السطر كاملًا واستبدله بـ:

```javascript
var rowHtml = '<tr class="border-t hover:bg-gray-50"><td class="p-3 cursor-pointer font-bold text-blue-600" onclick="RW_Items._switchSubTab(\\'movement\\'); setTimeout(function(){ RW_Items._renderStockMovementReport(' + _jsAttr(item.item_code) + ',' + _jsAttr(item.name) + ',null); },200);">' + _esc(item.name) + ' <span class="text-xs text-gray-400">(' + _esc(item.item_code) + ')</span></td><td class="p-3 text-center font-bold">' + (item._totalStock||0) + '</td>';
```

### الخطوة 4 — إصلاح المقطع الثاني داخل `_renderBranchStockMatrixFiltered()`

ابحث داخل الدالة:

```javascript
function _renderBranchStockMatrixFiltered(data) {
```

عن السطر الذي يبدأ بـ:

```javascript
var rowHtml = '<tr class="border-t hover:bg-gray-50"><td class="p-3 cursor-pointer font-bold text-blue-600" onclick="RW_Items._switchSubTab(\\'movement\\');
```

احذف السطر كاملًا واستبدله بـ:

```javascript
var rowHtml = '<tr class="border-t hover:bg-gray-50"><td class="p-3 cursor-pointer font-bold text-blue-600" onclick="RW_Items._switchSubTab(\\'movement\\'); setTimeout(function(){ RW_Items._renderStockMovementReport(' + _jsAttr(item.item_code) + ',' + _jsAttr(item.name) + ',null); },200);">' + _esc(item.name) + ' <span class="text-xs text-gray-400">(' + _esc(item.item_code) + ')</span></td><td class="p-3 text-center font-bold">' + (item._totalStock||0) + '</td>';
```

## 7. نقطة مهمة في المقطع الثاني

يجب أن يبقى:

```javascript
,null)
```

وليس:

```javascript
,_jsAttr(null)
```

لأن المطلوب هنا `null` JavaScript حقيقية، لا نص فارغ.

## 8. لماذا التصحيح الحالي أفضل

الـHTML attribute يستخدم:

```text
_jsAttr()
    ↓
_jsString()
    ↓
_esc()
```

وبذلك تحصل قيمة JavaScript آمنة ومشفرة داخل HTML attribute.

لا تستخدم `_esc(...).replace(/'/g, ...)` في هذه المواضع بعد إضافة `_jsAttr`.

## 9. ما لم يتم فعله

```text
main2.md = لم يتم تعديله بواسطة هذا التقرير
New-main  = لم يتم تعديله
main1     = لم يتم تعديله
core.js   = لم يتم تعديله
sw.js     = لم يتم تعديله
register-sw.js = لم يتم تعديله
manifest.json = لم يتم تعديله
Production business data = لم تتم إضافة بيانات دائمة
```

## 10. حالة Main2 بعد هذه المراجعة

```text
M2-01 = CLOSED
M2-02 = CLOSED
M2-03 = CLOSED
M2-04 = CLOSED
M2-05 = CLOSED
M2-06 = CLOSED
M2-07R = CLOSED IN CURRENT SOURCE
M2-08 = CLOSED
M2-09 = CLOSED IN CURRENT SOURCE
M2-10 = OPEN / SERVER-SIDE AUTHORIZATION
M2-11 = OPEN / REMAINING INLINE-JS RAW VALUES
M2-12 = CLOSED IN CURRENT SOURCE
```

## 11. Self-Audit

### ما تم إثباته

- الحالة الحالية تجاوزت `CURRENT_STATE` السابق.
- `main2.md` تغيّر فعليًا في commit `8e5fe0d...`.
- M2-07R وM2-09 تم تطبيق إصلاحاتهما فعليًا في المصدر الحالي.
- `_jsAttr` غير معرف في المستودع.
- استخدام `_jsAttr` في المقاطع التي أرسلها المستخدم يحتاج helper صريح أولًا.
- المقطع الأول والمقطع الثاني يحتاجان توحيد سياق JavaScript/HTML، وليس مجرد تعديل علامة اقتباس.
- Production الحالية تمت مطابقتها مباشرة أثناء التقرير.

### ما لم يتم إثباته

- Browser runtime بعد التعديلات اليدوية النهائية.
- اكتمال M2-11 في جميع raw HTML / inline-JS المواضع.
- إغلاق M2-10.
- assembled parent artifact بعد دمج Main1..Main11.

### القرار

```text
MAIN2 MANUAL INLINE-JS PATCH = EXACTLY SPECIFIED
MAIN2 SOURCE = NOT MODIFIED BY THIS SESSION
MAIN2 GLOBAL CLOSURE = NOT CLAIMED
```

## 12. الخطوة التالية المعتمدة

يقوم مالك المشروع بتطبيق الخطوات الأربع أعلاه فقط داخل `Current/PWA/main2/main2.md`، ثم يعاد قراءة الملف من `main`، ويُجرى static/syntax + unrelated-diff review قبل اعتماد أي assembly لاحق.
