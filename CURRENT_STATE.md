# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-05

```text
REPOSITORY = papamohammed77-glitch/rawaie-erp-New
BRANCH = main
CURRENT GIT HEAD AFTER THIS STATE UPDATE = THIS COMMIT
PREVIOUS VERIFIED HEAD = c02d937f88604c22520c7f2a63651d5997a8b885
REPORT65 COMMIT = 7dfe2e7da5058f97c50990ed1e0be30b241f9a51
PRODUCTION = SMART ERP / fiilmooggumokxanwiyx
```

## GOVERNANCE

```text
CURRENT REALITY > CURRENT GIT > CURRENT PRODUCTION > CURRENT DEPLOYMENTS > CURRENT DATABASE CONTRACTS > HISTORICAL CONTRACTS > REPORTS > MEMORY > ASSUMPTIONS
UNKNOWN != BUG
UNKNOWN != REMOVE
READ → VERIFY → RECONCILE → UNDERSTAND → PATCH → VERIFY
ONE CLOSURE UNIT AT A TIME
GIT != DEPLOYMENT PROOF
SOURCE != RUNTIME PROOF
NO CLOSURE CLAIM WITHOUT CURRENT EVIDENCE
```

Primary governance source: `doc/Draft/medhat/MASTER - RAWAEA ERP.md`.

## LAST VERIFIED EVENTS

```text
40a7fdc94b8c1feae64f2de40c6a3322c9b50e9d
Report63-derived manual Main2 changes
= _jsAttr added
= corrected inline-JS expressions added

c02d937f88604c22520c7f2a63651d5997a8b885
Latest Main2 source mutation before this session
= current Main2 blob became 567224df...
= introduced/retained structural corruption in matrix rowHtml
= followed earlier manual deletion that removed a required loop brace

7dfe2e7da5058f97c50990ed1e0be30b241f9a51
Report65 current-source reconciliation
= DOCUMENTATION ONLY
= main2.md NOT modified by this session
= current Git/Production/state reconciled
```

Historical reports are preserved. No previous report was deleted.

## PRODUCTION TRUTH — DIRECT

Verified directly at `2026-09-05 06:25:09.463307 UTC`:

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

Relevant schema facts re-confirmed from Production evidence:

```text
items.item_code UNIQUE globally
stock_branches UNIQUE(branch_id,item_id)
receiving.operation_id UNIQUE
items.barcode NOT UNIQUE
```

No permanent business data was added or changed by this Main2 review session.

## MAIN2 SOURCE TRUTH

```text
PATH = Current/PWA/main2/main2.md
CURRENT SOURCE BLOB BEFORE REPORT65 = 567224dfb0429f62849d2e82ba5414c070add4bb
CURRENT GIT HEAD BEFORE REPORT65 = c02d937f88604c22520c7f2a63651d5997a8b885
MAIN2 SOURCE MODIFIED BY THIS SESSION = NO
```

The earlier `b9d1249...` blob recorded by Report64/CURRENT_STATE is historical and superseded by later direct Git evidence.

## REPORT64 RECONCILIATION

Report64 was valid for the source state it inspected (`40a7...`). However, later manual commits changed Main2.

```text
Report64 target state = historical
Current target state = c02d937... / blob 567224...
```

Therefore Report64's delete-only instructions are superseded by the exact current-source corrections in Report65.

## CURRENT MAIN2 MATRIX

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
M2-11 = OPEN / STRUCTURAL + INLINE-JS SOURCE CLEANUP REQUIRED
M2-12 = CLOSED IN CURRENT SOURCE
```

No closed M2 item was reopened based only on old reports; the current findings are limited to directly observed current-source breakage.

## M2-11 — CURRENT EXACT MANUAL PATCH STATUS

The helper already exists and must not be duplicated:

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

### Required correction 1 — `_renderTable()`

The current source contains the correct branch-cell builder but the closing brace of its `for (var b2...)` loop is missing.

Exact action:

```text
ابحث داخل function _renderTable(data) عن السطر الذي يبني خلية الفرع باستخدام _jsAttr(item.item_code) و _jsAttr(branchName2).
اترك هذا السطر كما هو.
ابحث بعده مباشرة عن سطر status-cell الذي يبدأ بـ rowHtml += '<td class="p-4 text-center">.
أضف فوق status-cell مباشرة:
            }
```

### Required correction 2 — `_renderBranchStockMatrix()` first row

ابحث عن السطر المقطوع الذي يبدأ بـ:

```javascript
var rowHtml = '<tr class="border-t hover:bg-gray-50"><td class="p-3 cursor-pointer font-bold text-blue-600" onclick="RW_Items._switchSubTab(\\'movement\\');
```

احذف السطر المقطوع كاملًا واستبدله بـ:

```javascript
            var rowHtml = '<tr class="border-t hover:bg-gray-50"><td class="p-3 cursor-pointer font-bold text-blue-600" onclick="RW_Items._switchSubTab(\\'movement\\'); setTimeout(function(){ RW_Items._renderStockMovementReport(' + _jsAttr(item.item_code) + ',' + _jsAttr(item.name) + ',null); },200);">' + _esc(item.name) + ' <span class="text-xs text-gray-400">(' + _esc(item.item_code) + ')</span></td><td class="p-3 text-center font-bold">' + (item._totalStock||0) + '</td>';
```

### Required correction 3 — `_renderBranchStockMatrix()` branch cell

ابحث داخل نفس الدالة عن خلية الفرع التي تستخدم `_esc(item.item_code).replace(/'/g, ...)`.

احذف السطر كاملًا واستبدله بـ:

```javascript
                rowHtml += '<td class="p-3 text-center cursor-pointer underline text-blue-600 text-xs" onclick="RW_Items._switchSubTab(\\'movement\\'); setTimeout(function(){ RW_Items._renderStockMovementReport(' + _jsAttr(item.item_code) + ',' + _jsAttr(item.name) + ',' + _jsAttr(bid2) + ',' + _jsAttr(branchName2) + '); },200);">' + st.qty + '</td>';
```

### Required correction 4 — `_renderBranchStockMatrixFiltered()` first row

ابحث عن:

```javascript
function _renderBranchStockMatrixFiltered(data) {
```

ثم ابحث عن نفس السطر المقطوع الذي يبدأ بـ:

```javascript
var rowHtml = '<tr class="border-t hover:bg-gray-50"><td class="p-3 cursor-pointer font-bold text-blue-600" onclick="RW_Items._switchSubTab(\\'movement\\');
```

احذفه كاملًا واستبدله بنفس السطر المصحح:

```javascript
            var rowHtml = '<tr class="border-t hover:bg-gray-50"><td class="p-3 cursor-pointer font-bold text-blue-600" onclick="RW_Items._switchSubTab(\\'movement\\'); setTimeout(function(){ RW_Items._renderStockMovementReport(' + _jsAttr(item.item_code) + ',' + _jsAttr(item.name) + ',null); },200);">' + _esc(item.name) + ' <span class="text-xs text-gray-400">(' + _esc(item.item_code) + ')</span></td><td class="p-3 text-center font-bold">' + (item._totalStock||0) + '</td>';
```

### Required correction 5 — `_renderBranchStockMatrixFiltered()` branch cell

ابحث داخل نفس الدالة عن خلية الفرع التي تستخدم:

```javascript
_esc(item.item_code).replace(/'/g, ...)
```

احذف السطر كاملًا واستبدله بـ:

```javascript
                rowHtml += '<td class="p-3 text-center cursor-pointer underline text-blue-600 text-xs" onclick="RW_Items._switchSubTab(\\'movement\\'); setTimeout(function(){ RW_Items._renderStockMovementReport(' + _jsAttr(item.item_code) + ',' + _jsAttr(item.name) + ',' + _jsAttr(bid2) + ',' + _jsAttr(branchName2) + '); },200);">' + st.qty + '</td>';
```

## DO NOT DO

```text
لا تضف _jsAttr مرة أخرى.
لا تحذف أي قوس إضافي غير القوس المحدد في _renderTable().
لا تستخدم _esc(...).replace(/'/g, ...) في خلايا الفرع المستهدفة.
لا تستخدم _jsAttr(null)؛ يجب أن تبقى ,null,
لا تعدل M2-07R أو M2-09 أو M2-12 الآن.
لا تعدل main1 أو main3..main11.
لا تعدل core.js أو sw.js أو register-sw.js أو manifest.json في هذه الخطوة.
لا تعدل Production business data.
```

## WHY THE CURRENT INSTRUCTIONS DIFFER FROM REPORT64

Report64 كان مبنيًا على `40a7...`، بينما Git الحالي تجاوزه بثلاثة commits يدوية.

الأدلة الحالية تثبت:

```text
a5d9 = حذف البقايا مع حذف قوس loop في _renderTable()
ce435 = كسر var rowHtml في _renderBranchStockMatrix()
c02d = أبقى/كرر الكسر في الحالة الحالية
```

لذلك لا يجوز الآن تنفيذ Report64 حرفيًا.

## SOURCE / RUNTIME STATUS

```text
Main2 source current = OPEN
Browser runtime after correction = NOT VERIFIED
Static/syntax pass after correction = NOT VERIFIED
M2-10 server authorization = OPEN
M2-11 = OPEN
11-part assembly = NOT VERIFIED
Final PWA production equivalence = NOT VERIFIED
```

## SELF-AUDIT

### ما تم إثباته

- تمت قراءة MASTER واستخدامه كمرجع الحوكمة.
- تمت قراءة CURRENT_STATE السابق واكتشاف أنه stale.
- تمت قراءة Report63 وReport64 بالكامل ومقارنتهما بالمصدر الحالي.
- تمت قراءة Main2 الحالي مباشرة من Git بصورة متتابعة.
- تم تتبع Git history بعد Report64 حتى `c02d...`.
- تم إثبات القوس المفقود والسطرين المقطوعين وخلايا الفروع القديمة بالـsource الحالي.
- تم إثبات Production مباشرة عند `2026-09-05 06:25:09.463307 UTC`.
- لم يتم تعديل `main2.md` في هذه الجلسة.
- تم إنشاء Report65 فقط وتحديث CURRENT_STATE.

### ما لم يتم إثباته

- نجاح Browser Runtime بعد الإصلاح اليدوي.
- نجاح static/syntax بعد الإصلاح اليدوي.
- الإغلاق النهائي لـM2-11.
- الإغلاق الأمني لـM2-10.
- تجميع Main1..Main11 النهائي.

### FINAL CLOSURE

```text
MAIN2 = OPEN
M2-10 = OPEN
M2-11 = OPEN
PROJECT CLOSURE = NOT CLAIMED
```

## NEXT AUTHORIZED ACTION

```text
1. نفّذ التصحيحات الخمسة أعلاه يدويًا داخل main2.md فقط.
2. أعد قراءة main2.md من Git بعد الحفظ.
3. تحقق أن _jsAttr موجود مرة واحدة فقط.
4. تحقق أن _renderTable() يحتوي على } قبل status-cell.
5. تحقق أن أول rowHtml في الدالتين المصفوفتين هو السطر المصحح كاملًا وبدون newline داخلي.
6. تحقق أن خلايا الفرع الأربع المستهدفة تستخدم _jsAttr بدل escape اليدوي.
7. نفّذ static/syntax review وunrelated-diff review.
8. بعد نجاحها، سجّل commit Main2 الفعلي ثم حدّث CURRENT_STATE من جديد.
9. بعدها فقط انتقل إلى M2-10.
```
