# Report138 — Owner ChangeSet النهائي لإغلاق Syntax للملف المنشور `main.html`

## 0. الرسالة الهدف — يجب أن تبقى أمام أي تنفيذ

**هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا نتعامل معه كإضافات شكلية. وهذا متسق حرفيًا مع مبدأ الحوكمة: الدراسة أولًا، ثم إعادة بناء العقد التاريخي، ثم تتبع السلوك الحالي، ثم تحديد الفجوة، ثم التعديل الجراحي، ثم الاختبار والتحقق.**

هذا التقرير لا يعيد بناء أي شيء. وهو خاص بالـ`main.html` المنشور فقط، ويعطي المالك عناصر الحذف/الاستبدال الدقيقة التي ثبتت من النسخة الحالية.

---

# 1. Current Reality

المصدر الحالي:

```text
erp-frontend/companies/company-1/main.html
```

آخر نسخة فحصتها البوابة الدائمة:

```text
Git HEAD = cfd9801b13b5601fe5d13777a20bf4f2f9a0eff7
LINES    = 17,415
BYTES    = 933,483
SHA256   = 3d60ffd0b85537fcef6e2941081b6b01ea5568f2ae071cdc38c45dd7f02ab885
EOF      = </script> / </body> / </html>
```

التحقق البنيوي:

```text
HTML_OPEN/CLOSE   = 1/1
HEAD_OPEN/CLOSE   = 1/1
BODY_OPEN/CLOSE   = 1/1
STYLE_OPEN/CLOSE  = 1/1
SCRIPT_OPEN/CLOSE = 6/6
INCOMPLETE_MARKERS = []
DIRECT_PHYSICAL_WRITERS = []
```

الـJavaScript لا يزال يفشل حاليًا عند:

```text
/tmp/main-positioned.js:2278
SyntaxError: Invalid or unexpected token
```

---

# 2. Already Correct — DO NOT TOUCH

```text
1971 = صحيح في المصدر الحالي
9010 = صحيح في المصدر الحالي
```

لا تعِد إصلاحهما.

---

# 3. Exact Owner Repairs — 13 Remaining Items

## 3.1 السطر 2278 — `RW_Table.paginate('matrix-tbody', ...)`

**ابحث عن السطر 2278 كاملًا واحذفه بالكامل.**

الاستبدال الكامل:

```js
        var rowHtml = '<tr class="border-t hover:bg-gray-50"><td class="p-3 cursor-pointer font-bold text-blue-600" onclick="RW_Items._switchSubTab(\'movement\'); setTimeout(function(){ RW_Items._renderStockMovementReport(' + _jsAttr(item.item_code) + ',' + _jsAttr(item.name) + ',null); },200);">' + _esc(item.name) + ' <span class="text-xs text-gray-400">(' + _esc(item.item_code) + ')</span></td><td class="p-3 text-center font-bold">' + (item._totalStock||0) + '</td>';
```

## 3.2 السطر 2283 — نفس كتلة الـmatrix

**ابحث عن السطر 2283 كاملًا واحذفه بالكامل.**

الاستبدال الكامل:

```js
         rowHtml += '<td class="p-3 text-center cursor-pointer underline text-blue-600 text-xs" onclick="RW_Items._switchSubTab(\'movement\'); setTimeout(function(){ RW_Items._renderStockMovementReport(' + _jsAttr(item.item_code) + ',' + _jsAttr(item.name) + ',' + _jsAttr(bid2) + ',' + _jsAttr(branchName2) + '); },200);">' + st.qty + '</td>';
```

## 3.3 السطر 2311 — `RW_Table.paginate('matrix-tbody', data, ...)`

**احذف السطر 2311 كاملًا.**

الاستبدال الكامل:

```js
            var rowHtml = '<tr class="border-t hover:bg-gray-50"><td class="p-3 cursor-pointer font-bold text-blue-600" onclick="RW_Items._switchSubTab(\'movement\'); setTimeout(function(){ RW_Items._renderStockMovementReport(' + _jsAttr(item.item_code) + ',' + _jsAttr(item.name) + ',null); },200);">' + _esc(item.name) + ' <span class="text-xs text-gray-400">(' + _esc(item.item_code) + ')</span></td><td class="p-3 text-center font-bold">' + (item._totalStock||0) + '</td>';
```

## 3.4 السطر 2316 — نفس كتلة الـmatrix

**احذف السطر 2316 كاملًا.**

الاستبدال الكامل:

```js
    rowHtml += '<td class="p-3 text-center cursor-pointer underline text-blue-600 text-xs" onclick="RW_Items._switchSubTab(\'movement\'); setTimeout(function(){ RW_Items._renderStockMovementReport(' + _jsAttr(item.item_code) + ',' + _jsAttr(item.name) + ',' + _jsAttr(bid2) + ',' + _jsAttr(branchName2) + '); },200);">' + st.qty + '</td>';
```

## 3.5 السطر 4806 — `RW_POS.search`

**احذف السطر 4806 كاملًا.**

الاستبدال الكامل:

```js
                '<div class="font-bold text-blue-600">' + Number(it.sales_price || 0).toLocaleString() + ' ' + currency + '</div>' +
```

## 3.6 السطر 4904 — `renderCart`

**احذف السطر 4904 كاملًا.**

الاستبدال الكامل:

```js
                '<td class="p-4 border-y font-bold text-blue-600">' + it.price.toLocaleString() + ' ' + currency + '</td>' +
```

## 3.7 السطر 4908 — `renderCart`

**احذف السطر 4908 كاملًا.**

الاستبدال الكامل:

```js
                '<td class="p-4 border-y font-black">' + line.toLocaleString() + ' ' + currency + '</td>' +
```

## 3.8 السطر 11142 — `RW_Finance` / سند قبض جديد

**احذف السطر 11142 كاملًا.**

الاستبدال الكامل للسطر:

```js
        var html = '<div class="bg-white rounded-2xl shadow-sm border p-4"><div class="flex justify-between items-center mb-4"><h2 class="text-xl font-bold"><i class="fa-solid fa-arrow-down ml-2 text-green-600"></i>سند قبض جديد</h2><button type="button" onclick="RW_Finance.renderSubTab(\'receipts\')" class="text-gray-500 hover:text-gray-700"><i class="fa-solid fa-xmark text-xl"></i></button></div><div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4"><div><label class="block text-sm font-bold">التاريخ</label><input type="date" id="rcpt-date" class="border rounded-lg p-2 w-full" value="' + new Date().toISOString().slice(0,10) + '"></div><div><label class="block text-sm font-bold">الخزينة</label><select id="rcpt-cashbox" class="border rounded-lg p-2 w-full">' + treasuryOptions + '</select></div><div><label class="block text-sm font-bold">الحساب المقابل</label><select id="rcpt-main-account" class="border rounded-lg p-2 w-full"><option value="">اختر الحساب</option>' + accountOptions + '</select></div></div><div class="mb-4"><h4 class="font-bold mb-2">بنود السند</h4><div id="rcpt-lines"></div><button type="button" onclick="RW_Finance._addReceiptLine()" class="mt-2 text-green-600 font-bold"><i class="fa-solid fa-plus-circle ml-1"></i> إضافة بند</button></div><div class="p-3 bg-gray-50 rounded-lg flex justify-between mb-4"><span>الإجمالي: <span id="rcpt-total">0.00</span></span></div><div class="flex justify-end gap-3"><button type="button" onclick="RW_Finance.renderSubTab(\'receipts\')" class="px-4 py-2 border rounded-lg">إلغاء</button><button type="button" onclick="RW_Finance._saveReceipt()" class="px-6 py-2 bg-green-600 text-white rounded-lg font-bold"><i class="fa-solid fa-check ml-1"></i> حفظ</button></div></div>';
```

لا تغيّر أي جزء آخر من السطر.

## 3.9 السطر 14457 — تقرير الـRunsheet

**احذف السطر 14457 كاملًا.**

الاستبدال الكامل:

```js
                return '<tr class="border-t hover:bg-gray-50 cursor-pointer" onclick="RW_Reports_Comprehensive._showRunsheetDetail(\'' + _esc(r.runsheet_code) + '\')">' +
```

## 3.10 السطور 14572–14574 — `rows8.push`

**احذف الأسطر 14572 و14573 و14574 كاملة.**

الاستبدال الكامل للأسطر الثلاثة:

```js
                    'onclick="RW_Reports_Comprehensive._showItemMovementDetail(\'' +
                    _esc(items8[i8].item_code) +
                    '\', \'\')">' +
```

## 3.11 السطور 16221–16223 — `return (` داخل تقرير التسويات

**احذف الأسطر 16221 و16222 و16223 كاملة.**

الاستبدال الكامل:

```js
                        'onclick="RW_Reports_Comprehensive._showSettlementDetail(\'' +
                        _esc(row.settlement_code) +
                        '\')">' +
```

## 3.12 السطر 16569 — كلمة المرور الجديدة

**احذف السطر 16569 كاملًا.**

الاستبدال الكامل:

```js
    html += '<button type="button" onclick="window.togglePasswordVisibility(\'owner-new-password\', this)" class="absolute left-2 top-2.5 text-gray-500 hover:text-gray-700 p-1"><i class="fa-solid fa-eye"></i></button>';
```

## 3.13 السطر 16574 — تأكيد كلمة المرور

**احذف السطر 16574 كاملًا.**

الاستبدال الكامل:

```js
    html += '<button type="button" onclick="window.togglePasswordVisibility(\'owner-confirm-password\', this)" class="absolute left-2 top-2.5 text-gray-500 hover:text-gray-700 p-1"><i class="fa-solid fa-eye"></i></button>';
```

---

# 4. لا Global Replace

ممنوع استبدال جميع ظهور:

```text
\\'
```

أو:

```text
\'
```

لأن المصدر الحالي يحتوي مواضع صحيحة بالفعل.

---

# 5. Validation Gate بعد التنفيذ

بعد تنفيذ العناصر أعلاه على المصدر المنشور:

```text
1. اقرأ main.html من أول بايت حتى EOF.
2. احسب SHA256 / Bytes / Lines من جديد.
3. شغّل cto_main_html_forensic_20260912.yml.
4. تحقق من HTML structure.
5. تحقق من incomplete markers.
6. تحقق من direct physical stock writers.
7. شغّل node --check على الـoriginal positioned JS source.
```

لا تعتبر syntax مغلقًا قبل:

```text
NODE_CHECK_ORIGINAL = PASS
```

ولا تنتقل إلى:

```text
core.js
sw.js
register-sw.js
manifest.json
```

إلا بعد ذلك.

---

# 6. Assembly / Source of Truth

مصدر الحقيقة الحالي هو:

```text
erp-frontend/companies/company-1/main.html
```

و`rawaie-erp-New/.github/workflows/forensic_main_assembly.yml` حاليًا يتبع هذا المصدر ولا يعيد Assembly من الأجزاء التاريخية.

الملفات:

```text
Current/PWA/main2/main1..main11.md
Current/PWA/New-main/*
Original/PWA/main/*
Current/PWA/main/*
```

مرجعية/تاريخية فقط.

---

# 7. Final Status

```text
SOURCE OF TRUTH VERIFIED       = PASS
FULL SOURCE STRUCTURE           = PASS
CURRENT SYNTAX                  = OPEN
OWNER CHANGESET                 = 13 ITEMS
HELPER INTEGRATION              = BLOCKED
ASSEMBLY CLOSURE                = NO
GOLD/DIAMOND CLOSURE            = NO
```

# END REPORT138
