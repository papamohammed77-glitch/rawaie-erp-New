# تقرير 64 — إعادة المطابقة الجراحية لـ Main2 بعد التطبيق اليدوي لـ Report63

**التاريخ:** 2026-09-05  
**المستودع:** `papamohammed77-glitch/rawaie-erp-New`  
**الفرع:** `main`  
**Current Git HEAD وقت التحقق:** `40a7fdc94b8c1feae64f2de40c6a3322c9b50e9d`  
**الملف المستهدف:** `Current/PWA/main2/main2.md`  
**Current Main2 blob:** `b9d1249b390935e51d784836de7f4473969ece77`  
**Production:** `SMART ERP / fiilmooggumokxanwiyx`

## 1. نطاق الجلسة

هذه الجلسة ليست بداية جديدة.
تم استرجاع الحالة من `CURRENT_STATE.md`، ومراجعة `MASTER - RAWAEA ERP.md`، وقراءة `Report63_Main2_Surgical_InlineJS_Recheck_20260905.md`، ثم إعادة فحص `main2.md` الحالي مباشرة من Git.

المبدأ الحاكم المطبق هنا هو:

```text
CURRENT REALITY
→
CURRENT GIT
→
CURRENT PRODUCTION
→
CURRENT DEPLOYMENTS
→
HISTORICAL CONTRACT
→
SURGICAL CHANGE
```

ولا يوجد أي تعديل على `main2.md` من جانب هذا التقرير.

## 2. اكتشاف انحراف الحالة عن Report63

Report63 كان قد طلب أربع خطوات يدوية:

1. إضافة `_jsAttr` بعد `_jsString`.
2. إصلاح موضع `_applyFilters()`.
3. إصلاح `rowHtml` داخل `_renderBranchStockMatrix()`.
4. إصلاح `rowHtml` داخل `_renderBranchStockMatrixFiltered()`.

المصدر الحالي يثبت أن خطوة helper تم تنفيذها بالفعل، وكذلك تم إدخال الصيغ الجديدة في المواضع الثلاثة، لكن التنفيذ اليدوي أدخل أيضًا **سطر بقايا زائدًا من الصيغة السابقة** بعد كل واحدة من الصيغ الجديدة.

هذا الانحراف مثبت مباشرة في commit:

```text
40a7fdc94b8c1feae64f2de40c6a3322c9b50e9d
Update print statement from 'Hello' to 'Goodbye'
```

والـdiff الخاص به يثبت إضافة `_jsAttr` والصيغ الجديدة، ثم إضافة السطور الثلاثة الزائدة التي لا تنتمي إلى التعبير الجديد.

## 3. الحالة الحالية الفعلية لـ _jsAttr

المصدر الحالي يحتوي بالفعل على:

```javascript
function _jsAttr(s) {
    return _esc(_jsString(s));
}
```

لذلك **لا تضف `_jsAttr` مرة أخرى**.

## 4. التعديل الجراحي رقم 1 — `_renderTable()`

ابحث داخل:

```javascript
function _renderTable(data) {
```

وابحث بعد هذا السطر الصحيح مباشرة:

```javascript
rowHtml += '<td class="p-4 text-center cursor-pointer underline text-blue-600 text-xs" onclick="RW_Items._switchSubTab(\\'movement\\'); setTimeout(function(){ RW_Items._renderStockMovementReport(' + _jsAttr(item.item_code) + ',' + _jsAttr(item.name) + ',' + _jsAttr(bid2) + ',' + _jsAttr(branchName2) + '); },200);">' + st.qty + '</td>';
```

ستجد بعده مباشرة سطرًا زائدًا يبدأ بهذا النص:

```text
\\' + _esc(item.item_code) + '\\',\\'' + _esc(item.name).replace(/'/g, "\\\\'")
```

**احذف هذا السطر كاملًا فقط.**

لا تحذف السطر السابق الصحيح.

بعد الحذف يجب أن ينتقل التنفيذ مباشرة إلى:

```javascript
}
rowHtml += '<td class="p-4 text-center"><span class="px-2 py-1 rounded-full text-xs font-bold ' + status.color + '">' + status.label + '</span></td></tr>';
```

## 5. التعديل الجراحي رقم 2 — `_renderBranchStockMatrix()`

ابحث عن:

```javascript
function _renderBranchStockMatrix() {
```

ثم ابحث عن السطر الصحيح الذي يبدأ بـ:

```javascript
var rowHtml = '<tr class="border-t hover:bg-gray-50"><td class="p-3 cursor-pointer font-bold text-blue-600" onclick="RW_Items._switchSubTab(\\'movement\\'); setTimeout(function(){ RW_Items._renderStockMovementReport(' + _jsAttr(item.item_code) + ',' + _jsAttr(item.name) + ',null); },200);">'
```

وتحته مباشرة يوجد سطر زائد يبدأ بـ:

```text
setTimeout(function(){ RW_Items._renderStockMovementReport(' + _jsAttr(item.item_code) + ',' + _jsAttr(item.name) + ',null); },200);">
```

ثم يكمل بعرض اسم الصنف.

**احذف هذا السطر الزائد كاملًا فقط.**

لا تحذف `var rowHtml = ...` الصحيح السابق له.

## 6. التعديل الجراحي رقم 3 — `_renderBranchStockMatrixFiltered()`

ابحث عن:

```javascript
function _renderBranchStockMatrixFiltered(data) {
```

ثم ابحث عن نفس السطر الصحيح الذي يبدأ بـ:

```javascript
var rowHtml = '<tr class="border-t hover:bg-gray-50"><td class="p-3 cursor-pointer font-bold text-blue-600" onclick="RW_Items._switchSubTab(\\'movement\\'); setTimeout(function(){ RW_Items._renderStockMovementReport(' + _jsAttr(item.item_code) + ',' + _jsAttr(item.name) + ',null); },200);">'
```

وتحته مباشرة يوجد سطر زائد يبدأ بهذا النمط:

```text
setTimeout(function(){ RW_Items._renderStockMovementReport(\\'' + _esc(item.item_code) + '\\',\\'' + _esc(item.name).replace(/'/g, "\\\\'") + '\\',null); },200);">
```

**احذف هذا السطر الزائد كاملًا فقط.**

لا تحذف السطر الصحيح السابق له.

## 7. النتيجة المطلوبة بعد التعديل

يجب أن يبقى في كل موضع:

```javascript
_jsAttr(item.item_code)
_jsAttr(item.name)
,null
```

وفي خلايا الفروع:

```javascript
_jsAttr(bid2)
_jsAttr(branchName2)
```

ولا تعُد إلى:

```javascript
_esc(...).replace(/'/g, ...)
```

داخل هذه الـinline-JS arguments.

ولا تستخدم:

```javascript
_jsAttr(null)
```

## 8. ما تم إثباته من المصدر الحالي

```text
_jsAttr = موجود بالفعل
الصيغة الجديدة في المواضع الثلاثة = موجودة
السطر القديم الزائد = موجود في المواضع الثلاثة
```

وبالتالي فإن سبب الحاجة الحالية ليس فقدان الإصلاح، بل **بقايا نصية زائدة أُضيفت أثناء التطبيق اليدوي**.

## 9. Production reconciliation

تمت مطابقة Production مباشرة أثناء هذه الجلسة عند:

```text
2026-09-05 05:53:42.840035 UTC
```

والنتيجة:

```text
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

لا توجد بيانات أعمال جديدة أُنشئت لهذا الفحص.

## 10. ما لم يتم فعله

```text
main2.md = لم يتم تعديله بواسطة هذا التقرير
New-main = لم يتم تعديله
main1.md = لم يتم تعديله
main3..main11 = لم يتم تعديلها
core.js = لم يتم تعديله
sw.js = لم يتم تعديله
register-sw.js = لم يتم تعديله
manifest.json = لم يتم تعديله
Production business data = لم يتم تغييرها
```

## 11. ما يجب عدم فعله

لا تعُد لإضافة `_jsAttr` مرة ثانية.

لا تُعد إدخال السطر القديم بدل حذفه.

لا تعدل M2-07R أو M2-09 أو M2-12، لأنها موجودة في المصدر الحالي ولا توجد أدلة جديدة تستدعي إعادة فتحها.

لا تنتقل إلى Main3 أو assembly قبل إعادة قراءة `main2.md` والتحقق من اختفاء السطور الثلاثة الزائدة.

## 12. Self-Audit

### ما تم إثباته

- `CURRENT_STATE.md` السابق أصبح متقدمًا عليه Git الحالي.
- Current Git HEAD هو `40a7fdc...`.
- `main2.md` الحالي يحتوي `_jsAttr` بالفعل.
- التطبيق اليدوي لـReport63 وصل إلى المصدر الحالي.
- التطبيق اليدوي ترك ثلاثة أسطر زائدة محددة، واحدًا في `_renderTable()` وواحدًا في `_renderBranchStockMatrix()` وواحدًا في `_renderBranchStockMatrixFiltered()`.
- Production الحالية تمت مطابقتها مباشرة.
- Production لا تحتوي على duplicate non-empty barcodes.

### ما لم يتم إثباته بعد

```text
Browser runtime بعد حذف السطور الثلاثة
JavaScript static/syntax pass بعد الإصلاح اليدوي
Main2 final closure
M2-10 server-side authorization closure
11-part assembled artifact
Final PWA production equivalence
```

### حالة الإغلاق

```text
MAIN2 SOURCE = OPEN / MANUAL SURGICAL CLEANUP REQUIRED
M2-11 = OPEN
M2-10 = OPEN
PROJECT CLOSURE = NOT CLAIMED
```

## 13. نقطة الاستمرار الوحيدة المعتمدة

بعد تنفيذ الحذف الثلاثي أعلاه:

```text
1. أعد قراءة Current/PWA/main2/main2.md من Git.
2. تحقق من وجود _jsAttr مرة واحدة فقط.
3. تحقق من وجود الصيغة الجديدة مرة واحدة في كل موضع مستهدف.
4. تحقق من اختفاء السطور الثلاثة الزائدة.
5. نفذ static/syntax review.
6. نفذ unrelated-diff review.
7. بعدها فقط اعتمد Main2 للانتقال إلى M2-10 أو مرحلة التجميع التالية.
```

**الخلاصة:** لا نعيد الإصلاح من الصفر. المطلوب الآن حذف **ثلاثة أسطر زائدة محددة فقط**؛ الإصلاح الصحيح الذي حدده Report63 موجود بالفعل داخل Main2 الحالي.