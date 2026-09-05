# تقرير 65 — إعادة المطابقة الجنائية لـ Main2 بعد Report64

**التاريخ:** 2026-09-05  
**المستودع:** `papamohammed77-glitch/rawaie-erp-New`  
**الفرع:** `main`  
**الملف المستهدف:** `Current/PWA/main2/main2.md`  
**Production:** `SMART ERP / fiilmooggumokxanwiyx`

## 1. نطاق الجلسة

هذه الجلسة استمرار مباشر وليست بداية جديدة.
تمت قراءة ومراجعة:

- `doc/Draft/medhat/MASTER - RAWAEA ERP.md` بالكامل.
- `CURRENT_STATE.md` بالكامل.
- `Report63_Main2_Surgical_InlineJS_Recheck_20260905.md`.
- `Report64_Main2_Surgical_Reconciliation_20260905.md` بالكامل.
- `Current/PWA/main2/main2.md` مباشرة من Git في نقاط متتابعة حتى نهاية الملف.
- تاريخ Git الخاص بـ Main2، وبالأخص سلسلة التعديلات بعد Report64.
- Production الحالية مباشرة.

لم يتم تعديل `main2.md` في هذه الجلسة تنفيذياً، التزامًا بتعليمات المالك بأن يكون التعديل يدويًا من جانبه.

## 2. قاعدة الحوكمة المطبقة

تم تطبيق القواعد التالية من MASTER:

```text
CURRENT REALITY
→ CURRENT GIT
→ CURRENT PRODUCTION
→ CURRENT DEPLOYMENTS
→ CURRENT DATABASE CONTRACTS
→ HISTORICAL CONTRACT
→ SURGICAL CHANGE
```

ولا يجوز اعتماد Report64 كحقيقة حالية بمجرد وجوده. كما لا يجوز حذف شيء من المصدر الحالي دون إثبات مباشر.

## 3. حالة Git الحالية — تعارض تم حسمه

`CURRENT_STATE.md` الحالي عند بداية الجلسة كان يثبت:

```text
HEAD = 681ac43d50cbe16f5fb85f847b9594a8db6c0c92
Main2 blob = b9d1249b390935e51d784836de7f4473969ece77
```

لكن Git الحالي الفعلي يثبت:

```text
CURRENT HEAD = c02d937f88604c22520c7f2a63651d5997a8b885
CURRENT Main2 blob = 567224dfb0429f62849d2e82ba5414c070add4bb
```

وآخر commit هو:

```text
c02d937f88604c22520c7f2a63651d5997a8b885
Update main2.md
2026-09-05 06:16:28 UTC
```

إذًا `CURRENT_STATE.md` كان **STALE** عند بدء هذه الجلسة، وتم حسم التعارض اعتمادًا على Git الحالي المباشر.

## 4. ماذا حدث بعد Report64

Report64 كان مبنيًا على HEAD `40a7fdc94b8c1feae64f2de40c6a3322c9b50e9d`، وطلب حذف ثلاثة بقايا نصية فقط.

بعده حدثت ثلاثة commits مباشرة على Main2:

### 4.1 commit `a5d9d117f5e422fbd4248bcd42d5d4ecdef80f68`

التاريخ: `2026-09-05 06:03:33 UTC`

الـdiff يثبت أن حذف البقايا في `_renderTable()` حذف أيضًا قوس الإغلاق `}` الخاص بحلقة `for`.

النتيجة الحالية:

```text
for (var b2 = 0; b2 < branchIds.length; b2++) {
    ...
    rowHtml += branch-cell;
rowHtml += status-cell;
```

أي أن القوس `}` مفقود قبل `status-cell`.

### 4.2 commit `ce435fdd04082631e3d10f8db47d545deed1fed6`

التاريخ: `2026-09-05 06:08:48 UTC`

الـdiff استبدل `var rowHtml` الصحيح داخل `_renderBranchStockMatrix()` بسطر مقطوع ينتهي بعد:

```javascript
onclick="RW_Items._switchSubTab(\\'movement\\');
```

ثم جاء `setTimeout` في السطر التالي خارج السلسلة.

### 4.3 commit `c02d937f88604c22520c7f2a63651d5997a8b885`

التاريخ: `2026-09-05 06:16:28 UTC`

أبقى نفس التلف البنيوي في `_renderBranchStockMatrix()` بدل الصيغة الصحيحة.

إذًا Report64 لم يعد يصف الإصلاح المطلوب على المصدر الحالي؛ تم استبداله بدليل Git أحدث.

## 5. الحالة الفعلية الحالية لـ `_jsAttr`

المصدر الحالي يحتوي بالفعل على:

```javascript
function _esc(s) {
    return esc(s == null ? '' : String(s));
}

function _jsString(s) {
    return JSON.stringify(s == null ? '' : String(s));
}

function _jsAttr(s) {
    return _esc(_jsString(s));
}
```

**الحكم:** لا تضف `_jsAttr` مرة أخرى.

## 6. التعديلات اليدوية الدقيقة المطلوبة الآن

### التعديل 1 — إصلاح `_renderTable()`

ابحث داخل:

```javascript
function _renderTable(data) {
```

عن السطر الحالي الصحيح الذي ينتهي بـ:

```javascript
+ _jsAttr(branchName2) + '); },200);">' + st.qty + '</td>';
```

وهو داخل حلقة:

```javascript
for (var b2 = 0; b2 < branchIds.length; b2++) {
```

**لا تحذف السطر الصحيح.**

ابحث بعده مباشرة عن هذا السطر:

```javascript
rowHtml += '<td class="p-4 text-center"><span class="px-2 py-1 rounded-full text-xs font-bold ' + status.color + '">' + status.label + '</span></td></tr>';
```

**أضف فوقه مباشرة هذا السطر فقط:**

```javascript
            }
```

النتيجة المطلوبة:

```javascript
                rowHtml += '<td class="p-4 text-center cursor-pointer underline text-blue-600 text-xs" onclick="RW_Items._switchSubTab(\\'movement\\'); setTimeout(function(){ RW_Items._renderStockMovementReport(' + _jsAttr(item.item_code) + ',' + _jsAttr(item.name) + ',' + _jsAttr(bid2) + ',' + _jsAttr(branchName2) + '); },200);">' + st.qty + '</td>';
            }
            rowHtml += '<td class="p-4 text-center"><span class="px-2 py-1 rounded-full text-xs font-bold ' + status.color + '">' + status.label + '</span></td></tr>';
```

هذا هو التصحيح الوحيد المطلوب في هذا الموضع.

---

### التعديل 2 — إصلاح `var rowHtml` داخل `_renderBranchStockMatrix()`

ابحث عن:

```javascript
function _renderBranchStockMatrix() {
```

ثم ابحث عن السطر المقطوع الذي يبدأ حرفيًا بـ:

```javascript
var rowHtml = '<tr class="border-t hover:bg-gray-50"><td class="p-3 cursor-pointer font-bold text-blue-600" onclick="RW_Items._switchSubTab(\\'movement\\');
```

**احذف هذا السطر المقطوع كاملًا.**

واستبدله بالكامل بهذا السطر:

```javascript
            var rowHtml = '<tr class="border-t hover:bg-gray-50"><td class="p-3 cursor-pointer font-bold text-blue-600" onclick="RW_Items._switchSubTab(\\'movement\\'); setTimeout(function(){ RW_Items._renderStockMovementReport(' + _jsAttr(item.item_code) + ',' + _jsAttr(item.name) + ',null); },200);">' + _esc(item.name) + ' <span class="text-xs text-gray-400">(' + _esc(item.item_code) + ')</span></td><td class="p-3 text-center font-bold">' + (item._totalStock||0) + '</td>';
```

**لا تغيّر أي سطر آخر في هذا المقطع.**

#### ثم أصلح خلية الفرع داخل نفس الدالة

ابحث عن السطر الذي يبدأ بـ:

```javascript
rowHtml += '<td class="p-3 text-center cursor-pointer underline text-blue-600 text-xs" onclick="RW_Items._switchSubTab(\\'movement\\'); setTimeout(function(){ RW_Items._renderStockMovementReport(\\''
```

وهو السطر الذي يستخدم:

```javascript
_esc(item.item_code).replace(/'/g, ...)
```

**احذف هذا السطر كاملًا واستبدله بهذا السطر:**

```javascript
                rowHtml += '<td class="p-3 text-center cursor-pointer underline text-blue-600 text-xs" onclick="RW_Items._switchSubTab(\\'movement\\'); setTimeout(function(){ RW_Items._renderStockMovementReport(' + _jsAttr(item.item_code) + ',' + _jsAttr(item.name) + ',' + _jsAttr(bid2) + ',' + _jsAttr(branchName2) + '); },200);">' + st.qty + '</td>';
```

---

### التعديل 3 — إصلاح `var rowHtml` داخل `_renderBranchStockMatrixFiltered()`

ابحث عن:

```javascript
function _renderBranchStockMatrixFiltered(data) {
```

ثم ابحث عن السطر المقطوع الذي يبدأ حرفيًا بـ:

```javascript
var rowHtml = '<tr class="border-t hover:bg-gray-50"><td class="p-3 cursor-pointer font-bold text-blue-600" onclick="RW_Items._switchSubTab(\\'movement\\');
```

**احذف هذا السطر المقطوع كاملًا.**

واستبدله بالكامل بنفس السطر التالي:

```javascript
            var rowHtml = '<tr class="border-t hover:bg-gray-50"><td class="p-3 cursor-pointer font-bold text-blue-600" onclick="RW_Items._switchSubTab(\\'movement\\'); setTimeout(function(){ RW_Items._renderStockMovementReport(' + _jsAttr(item.item_code) + ',' + _jsAttr(item.name) + ',null); },200);">' + _esc(item.name) + ' <span class="text-xs text-gray-400">(' + _esc(item.item_code) + ')</span></td><td class="p-3 text-center font-bold">' + (item._totalStock||0) + '</td>';
```

#### ثم أصلح خلية الفرع داخل نفس الدالة

ابحث عن السطر الذي يستخدم:

```javascript
_esc(item.item_code).replace(/'/g, ...)
```

ويبدأ بـ:

```javascript
rowHtml += '<td class="p-3 text-center cursor-pointer underline text-blue-600 text-xs" onclick="RW_Items._switchSubTab(\\'movement\\'); setTimeout(function(){ RW_Items._renderStockMovementReport(\\''
```

**احذف السطر كاملًا واستبدله بهذا:**

```javascript
                rowHtml += '<td class="p-3 text-center cursor-pointer underline text-blue-600 text-xs" onclick="RW_Items._switchSubTab(\\'movement\\'); setTimeout(function(){ RW_Items._renderStockMovementReport(' + _jsAttr(item.item_code) + ',' + _jsAttr(item.name) + ',' + _jsAttr(bid2) + ',' + _jsAttr(branchName2) + '); },200);">' + st.qty + '</td>';
```

## 7. لا تعدل هذه العناصر

لا تضف `_jsAttr` مرة أخرى.

لا تعدل:

```text
M2-07R
M2-09
M2-12
```

ولا تعدل:

```text
main1.md
main3..main11
core.js
sw.js
register-sw.js
manifest.json
```

ولا تعدل Production data لهذا الإصلاح.

## 8. لماذا هذه التعديلات تختلف عن Report64

Report64 طلب حذف ثلاثة أسطر زائدة فقط.

الدليل الأحدث من Git يثبت أن التطبيق اليدوي اللاحق لم يحذف البقايا فقط، بل حذف أيضًا قوسًا بنيويًا في `_renderTable()`، ثم استبدل `rowHtml` الصحيح في دالتي المصفوفة بسطر يحتوي على literal newline ويؤدي إلى كسر JavaScript.

لذلك:

```text
Report64 = historical instruction
Report65 = current source instruction
```

والـReport65 لا يعيد تنفيذ Report63 من البداية، بل يصحح فقط ما ثبت أنه انكسر بعد Report64.

## 9. Production reconciliation

تمت مطابقة Production مباشرة في:

```text
2026-09-05 06:25:09.463307 UTC
```

والحالة:

```text
companies       = 1
app_settings    = 1
orders          = 0
purchase_orders = 0
branches        = 2
items           = 17
stock_branches  = 20
inventory_log   = 3
duplicate non-empty barcode groups = 0
```

لم يتم إدخال بيانات أعمال دائمة لهذا التحقيق.

## 10. تجارب وفحوص هذه الجلسة

### قراءة المصادر

تمت قراءة MASTER وCURRENT_STATE وReport63 وReport64 والمصدر الحالي لـMain2 مباشرة، مع تتبع Git history بعد Report64.

### Git lineage

تم إثبات سلسلة:

```text
40a7 → a5d9 → ce435 → c02d
```

والتأثيرات الخاصة بكل commit مثبتة في Git مباشرة.

### Production

تمت المراجعة المباشرة ولم يتغير عدد السجلات التجارية أثناء هذا التحقيق.

### Runtime

لم يتم تشغيل Browser Runtime لأن المستخدم طلب أن تكون تعديلات Main2 يدوية أولًا، ولأن المصدر الحالي ما زال يحتاج الإصلاحات الأربع المحددة أعلاه قبل أي runtime claim.

## 11. الأخطاء التي وقعت

### الخطأ الأول

التعامل مع تعليمات Report64 كأنها ما زالت تصف المصدر الحالي حرفيًا.

**السبب:** وجود commits يدوية أحدث من Report64.

**التصحيح المنهجي:** الرجوع إلى Git HEAD الحالي وحسم التعارض بالدليل المباشر.

### الخطأ الثاني الذي وقع في التطبيق اليدوي

حذف قوس `}` مع أحد الأسطر الزائدة في `_renderTable()`.

**الأثر:** كسر بنية حلقة `for`.

### الخطأ الثالث الذي وقع في التطبيق اليدوي

إدخال literal newline داخل سلسلة `rowHtml` في مصفوفة الفروع.

**الأثر:** كسر JavaScript syntax.

هذه المعرفة يجب ألا تضيع؛ لا تكرر نمط:

```text
DELETE LINE
```

إذا كان السطر يحتوي جزءًا من block structure إلا بعد التحقق من حدود الـblock.

## 12. ما لم يتم إثباته

```text
Browser runtime بعد الإصلاح اليدوي = NOT VERIFIED
JavaScript static/syntax pass بعد الإصلاح اليدوي = NOT VERIFIED
M2-11 final closure = OPEN
M2-10 server-side authorization closure = OPEN
11-part assembled artifact = NOT VERIFIED
Final PWA production equivalence = NOT VERIFIED
```

## 13. حالة Main2 الحالية

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
M2-10 = OPEN / CROSS-LAYER SERVER AUTHORIZATION
M2-11 = OPEN / CURRENT SOURCE HAS 4 SURGICAL CORRECTIONS REQUIRED
M2-12 = CLOSED IN CURRENT SOURCE
```

## 14. Self-Audit

### ما تم إثباته

- `CURRENT_STATE.md` السابق كان stale.
- Current Git HEAD هو `c02d937...`.
- Main2 blob الحالي هو `567224df...`.
- `_jsAttr` موجود بالفعل.
- `_renderTable()` يفتقد قوس `for` بسبب commit لاحق.
- `_renderBranchStockMatrix()` يحتوي `rowHtml` مقطوعًا.
- `_renderBranchStockMatrixFiltered()` يحتوي `rowHtml` مقطوعًا.
- دالتا المصفوفة ما زالت تحتويان خلايا فروع تستخدم escape يدويًا بدل `_jsAttr`.
- Production الحالية مستقرة ولم تُضف بيانات تجارية.

### ما لم يتم إثباته

- Browser/runtime بعد الإصلاح اليدوي.
- Static/syntax pass بعد الإصلاح.
- M2-10 closure.
- M2-11 final closure.
- Assembly النهائي.

### قرار الإغلاق

```text
MAIN2 SOURCE = OPEN
M2-11 = OPEN
M2-10 = OPEN
PROJECT CLOSURE = NOT CLAIMED
```

## 15. نقطة الاستمرار الوحيدة المعتمدة

يقوم مالك المشروع الآن بتنفيذ **أربعة تصحيحات فقط**:

```text
1. إضافة قوس } واحد في _renderTable().
2. استبدال var rowHtml المقطوع داخل _renderBranchStockMatrix().
3. استبدال خلية الفرع القديمة داخل _renderBranchStockMatrix().
4. تنفيذ نفس التصحيحين داخل _renderBranchStockMatrixFiltered().
```

ثم:

```text
إعادة قراءة main2.md من Git
→ static/syntax review
→ unrelated-diff review
→ تحديث CURRENT_STATE
→ ثم M2-10
```

لا تعُد إلى Report63 من البداية، ولا تعُد إلى حذف عشوائي للسطور.
