# Report137 — إعادة التحقق الجنائي للملف المنشور main.html — 2026-09-12

## 0. الرسالة الهدف — لا تضيع

**هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا نتعامل معه كإضافات شكلية. وهذا متسق حرفيًا مع مبدأ الحوكمة: الدراسة أولًا، ثم إعادة بناء العقد التاريخي، ثم تتبع السلوك الحالي، ثم تحديد الفجوة، ثم التعديل الجراحي، ثم الاختبار والتحقق.**

هذه الجلسة لا تعيد بناء المشروع من الصفر. الهدف الحالي المحدد هو إغلاق بوابة syntax للملف المنشور نفسه قبل أي Assembly/Helper integration.

---

## 1. مصادر الحقيقة التي تم الرجوع إليها

- `erp-frontend/companies/company-1/main.html` — Source of Truth الحالي.
- `rawaie-erp-New/CURRENT_STATE.md` — تم التحقق من حالته الحالية قبل التعديل.
- `rawaie-erp-New/doc/Draft/Reprots/Report136_Published_Main_Forensic_Recheck_20260912.md` — استُخدم كدليل تاريخي فقط، ثم تمت مطابقة النقاط مع المصدر الحالي.
- `rawaie-erp-New/.github/workflows/forensic_main_assembly.yml` — مساره الحالي صحيح ويشير إلى الملف المنشور في `erp-frontend`، ولا يعيد تركيب الملف من الأجزاء التاريخية.
- آخر GitHub Actions على `erp-frontend` للبوابة الدائمة: commit `cfd9801b13b5601fe5d13777a20bf4f2f9a0eff7`، run `34689230824`.

---

## 2. الحالة الحالية المثبتة من Production Source / GitHub Actions

الملف الحالي:

`erp-frontend/companies/company-1/main.html`

الحالة الحالية المثبتة في آخر تشغيل للبوابة:

```text
LINES    = 17,415
BYTES    = 933,483
SHA256   = 3d60ffd0b85537fcef6e2941081b6b01ea5568f2ae071cdc38c45dd7f02ab885
EOF      = </script> / </body> / </html>
```

بوابة البنية الكاملة:

```text
HTML_OPEN/CLOSE   = 1/1
HEAD_OPEN/CLOSE   = 1/1
BODY_OPEN/CLOSE   = 1/1
STYLE_OPEN/CLOSE  = 1/1
SCRIPT_OPEN/CLOSE = 6/6
INCOMPLETE_MARKERS = []
DIRECT_PHYSICAL_WRITERS = []
```

لكن:

```text
NODE_CHECK_ORIGINAL = FAIL
```

والفشل الحالي المحدد حيًا هو:

```text
/tmp/main-positioned.js:2278
SyntaxError: Invalid or unexpected token
```

السبب المثبت من النص الحالي: `onclick` داخل string في السطر 2278 يحتوي escaping مضاعفًا `\\'` بدل `\'`.

---

## 3. ما الذي تغير منذ Report136

تمت مطابقة نقاط Report136 مع الملف الحالي. لا تعاد نقاط أصبحت صحيحة.

### تم إصلاحها بالفعل ولا تُلمس

```text
1971  = صحيح في النسخة الحالية
9010  = صحيح في النسخة الحالية
```

وبالتالي لا يوجد طلب تعديل جديد لهذين السطرين.

---

# 4. OWNER CHANGESET — التعديلات المتبقية فقط

## MHTML-02 — السطر 2278

ابحث عن السطر **2278** كاملًا.

احذف السطر كاملًا، وآخر السطر الحالي هو:

```text
</td><td class="p-3 text-center font-bold">' + (item._totalStock||0) + '</td>';
```

واستبدله كاملًا بهذا السطر:

```js
        var rowHtml = '<tr class="border-t hover:bg-gray-50"><td class="p-3 cursor-pointer font-bold text-blue-600" onclick="RW_Items._switchSubTab(\'movement\'); setTimeout(function(){ RW_Items._renderStockMovementReport(' + _jsAttr(item.item_code) + ',' + _jsAttr(item.name) + ',null); },200);">' + _esc(item.name) + ' <span class="text-xs text-gray-400">(' + _esc(item.item_code) + ')</span></td><td class="p-3 text-center font-bold">' + (item._totalStock||0) + '</td>';
```

---

## MHTML-03 — السطر 2283

ابحث عن السطر **2283** كاملًا داخل نفس كتلة `RW_Table.paginate('matrix-tbody', ...)`.

احذف السطر كاملًا، وآخر السطر الحالي هو:

```text
' + st.qty + '</td>';
```

واستبدله كاملًا بهذا السطر:

```js
         rowHtml += '<td class="p-3 text-center cursor-pointer underline text-blue-600 text-xs" onclick="RW_Items._switchSubTab(\'movement\'); setTimeout(function(){ RW_Items._renderStockMovementReport(' + _jsAttr(item.item_code) + ',' + _jsAttr(item.name) + ',' + _jsAttr(bid2) + ',' + _jsAttr(branchName2) + '); },200);">' + st.qty + '</td>';
```

---

## MHTML-04 — السطر 2311

ابحث عن السطر **2311** كاملًا داخل كتلة `RW_Table.paginate('matrix-tbody', data, ...)`.

احذف السطر كاملًا، وآخر السطر الحالي هو:

```text
' + (item._totalStock||0) + '</td>';
```

واستبدله كاملًا بهذا السطر:

```js
            var rowHtml = '<tr class="border-t hover:bg-gray-50"><td class="p-3 cursor-pointer font-bold text-blue-600" onclick="RW_Items._switchSubTab(\'movement\'); setTimeout(function(){ RW_Items._renderStockMovementReport(' + _jsAttr(item.item_code) + ',' + _jsAttr(item.name) + ',null); },200);">' + _esc(item.name) + ' <span class="text-xs text-gray-400">(' + _esc(item.item_code) + ')</span></td><td class="p-3 text-center font-bold">' + (item._totalStock||0) + '</td>';
```

---

## MHTML-05 — السطر 2316

ابحث عن السطر **2316** كاملًا داخل نفس كتلة `RW_Table.paginate`.

احذف السطر كاملًا، وآخر السطر الحالي هو:

```text
' + st.qty + '</td>';
```

واستبدله كاملًا بهذا السطر:

```js
    rowHtml += '<td class="p-3 text-center cursor-pointer underline text-blue-600 text-xs" onclick="RW_Items._switchSubTab(\'movement\'); setTimeout(function(){ RW_Items._renderStockMovementReport(' + _jsAttr(item.item_code) + ',' + _jsAttr(item.name) + ',' + _jsAttr(bid2) + ',' + _jsAttr(branchName2) + '); },200);">' + st.qty + '</td>';
```

---

## MHTML-06 — السطر 4806

ابحث عن السطر **4806** كاملًا داخل `RW_POS.search`.

احذف السطر كاملًا، وهو السطر الذي ينتهي حاليًا بـ:

```text
+ ' ' + currency</div>' +
```

واستبدله كاملًا بهذا:

```js
                '<div class="font-bold text-blue-600">' + Number(it.sales_price || 0).toLocaleString() + ' ' + currency + '</div>' +
```

---

## MHTML-07 — السطر 4904

ابحث عن السطر **4904** كاملًا داخل `renderCart`.

استبدله كاملًا بهذا:

```js
                '<td class="p-4 border-y font-bold text-blue-600">' + it.price.toLocaleString() + ' ' + currency + '</td>' +
```

---

## MHTML-08 — السطر 4908

ابحث عن السطر **4908** كاملًا داخل `renderCart`.

استبدله كاملًا بهذا:

```js
                '<td class="p-4 border-y font-black">' + line.toLocaleString() + ' ' + currency + '</td>' +
```

---

## MHTML-10 — السطر 11142

ابحث عن **السطر 11142 كاملًا** داخل `RW_Finance`، وهو سطر إنشاء **سند قبض جديد** ويبدأ بـ:

```text
        var html = '<div class="bg-white rounded-2xl shadow-sm border p-4">
```

في هذا السطر تحديدًا غيّر **الموضعين فقط** الخاصين بـ:

```text
RW_Finance.renderSubTab(\\'receipts\\')
```

إلى:

```text
RW_Finance.renderSubTab(\'receipts\')
```

لا تغيّر بقية السطر.

---

## MHTML-11 — السطر 14457

ابحث عن السطر **14457** كاملًا.

احذف السطر كاملًا واستبدله بهذا:

```js
                return '<tr class="border-t hover:bg-gray-50 cursor-pointer" onclick="RW_Reports_Comprehensive._showRunsheetDetail(\'' + _esc(r.runsheet_code) + '\')">' +
```

---

## MHTML-12 — السطور 14572–14574

ابحث عن كتلة `rows8.push` داخل السطور **14572–14574**.

احذف هذه الأسطر الثلاثة كاملة، واستبدلها بهذه الأسطر الثلاثة كاملة:

```js
                    'onclick="RW_Reports_Comprehensive._showItemMovementDetail(\'' +
                    _esc(items8[i8].item_code) +
                    '\', \'\')">' +
```

---

## MHTML-13 — السطور 16221–16223

ابحث عن كتلة `return (` داخل السطور **16221–16223**.

احذف الأسطر الثلاثة كاملة، واستبدلها بهذه الأسطر الثلاثة كاملة:

```js
                        'onclick="RW_Reports_Comprehensive._showSettlementDetail(\'' +
                        _esc(row.settlement_code) +
                        '\')">' +
```

---

## MHTML-14 — السطر 16569

ابحث عن السطر **16569** كاملًا.

احذف السطر كاملًا، وآخر السطر الحالي يحتوي على:

```text
onclick="window.togglePasswordVisibility(\\'owner-new-password\\', this)"
```

واستبدله كاملًا بهذا:

```js
    html += '<button type="button" onclick="window.togglePasswordVisibility(\'owner-new-password\', this)" class="absolute left-2 top-2.5 text-gray-500 hover:text-gray-700 p-1"><i class="fa-solid fa-eye"></i></button>';
```

---

## MHTML-15 — السطر 16574

ابحث عن السطر **16574** كاملًا.

احذف السطر كاملًا، وآخر السطر الحالي يحتوي على:

```text
onclick="window.togglePasswordVisibility(\\'owner-confirm-password\\', this)"
```

واستبدله كاملًا بهذا:

```js
    html += '<button type="button" onclick="window.togglePasswordVisibility(\'owner-confirm-password\', this)" class="absolute left-2 top-2.5 text-gray-500 hover:text-gray-700 p-1"><i class="fa-solid fa-eye"></i></button>';
```

---

# 5. ممنوع إجراء هذه التعديلات

لا تقم بأي Global Replace لـ:

```text
\\'
```

أو:

```text
\'
```

في كامل الملف.

الأسباب مثبتة من المصدر الحالي: توجد escaping صحيحة في مواضع عديدة، وكذلك line 9010 أصبح صحيحًا بالفعل ويحتوي regex صالحًا:

```js
.replace(/'/g, "\\'")
```

ولا يجب تغييره.

---

# 6. ما تم إثباته وما لم يتم إثباته

## مثبت

```text
Source of Truth = erp-frontend/companies/company-1/main.html
Current file exists and is current
17,415 lines
EOF valid
HTML structure valid
No incomplete markers
No direct browser physical stock writers
Current forensic workflow reads the published source itself
Current live syntax failure is line 2278
```

## غير مثبت بعد

```text
NODE_CHECK_ORIGINAL = PASS
Post-fix syntax closure
Functional E2E closure
Helper-file integration
Gold/Diamond closure
```

ولا يجوز تحويل أي منها إلى PASS قبل تشغيل الاختبار على المصدر بعد تطبيق الإصلاحات الفعلية.

---

# 7. Assembly Governance

`rawaie-erp-New/.github/workflows/forensic_main_assembly.yml` في المسار الحالي صحيح من حيث Source of Truth:

```text
erp-frontend/companies/company-1/main.html
```

ولا يعيد بناء الملف من:

```text
Current/PWA/main2/main1..main11.md
New-main
Original/PWA/main/*
Current/PWA/main/*
```

هذه الملفات تاريخية/مرجعية فقط.

لا يوجد داعٍ حالي لتعديل هذا workflow.

---

# 8. الملفات المساعدة

لا انتقال الآن إلى:

```text
Current/PWA/core.js
Current/PWA/sw.js
Current/PWA/register-sw.js
Current/PWA/manifest.json
```

قبل نجاح syntax gate للملف المنشور نفسه.

---

# 9. Production

لا توجد في هذه الجلسة الحالية أي تغييرات Production مطلوبة لإغلاق syntax الخاص بملف `main.html`.

ملكية التعديل مقسمة كما اعتمد المشروع:

```text
main.html owner change = OWNER
Supabase/Edge proven production repair = ASSISTANT
```

---

# 10. Final Self-Audit

```text
Business Understanding        = VERIFIED FOR CURRENT CHECKPOINT
Architecture Understanding    = VERIFIED FOR CURRENT CHECKPOINT
Database Dependency           = NOT NEEDED FOR THIS SYNTAX CHECKPOINT
Historical Understanding      = Report136 + current-source recheck
Production Source             = VERIFIED
Current Source                = VERIFIED
Execution Confidence          = HIGH FOR IDENTIFIED SYNTAX FIXES

Unknowns                      = POST-FIX REMAINING SYNTAX ERRORS NOT YET EXECUTABLE
Conflicts                     = NONE MATERIAL TO THE CURRENT SYNTAX FIX SET
Unverified Claims             = Gold/Diamond functional completion

Published Source Opened       = YES
Current File Identity         = VERIFIED
EOF Verified                  = YES
Workflow Path Verified        = YES
Consumer Integration          = NOT YET

Current Closure Status        = OPEN
Reason                        = OWNER MAIN.HTML REPAIRS PENDING
```

---

# 11. Exact Next Checkpoint

بعد تنفيذ التعديلات الثلاثة عشر أعلاه بواسطة المالك على المصدر المنشور:

```text
READ main.html FROM FIRST BYTE TO EOF
→ RECOMPUTE SHA/LINE COUNT
→ RUN cto_main_html_forensic_20260912.yml
→ RUN NODE CHECK ON ORIGINAL PUBLISHED SOURCE
→ IF FAIL: STOP AT FIRST REAL ERROR AND ISSUE EXACT OWNER CHANGESET
→ IF PASS: BEGIN HELPER FILE INTEGRATION
```

ولا يوجد مبرر لإعلان:

```text
ASSEMBLY CLOSED
```

أو:

```text
GOLD / DIAMOND CLOSED
```

قبل نجاح البوابة الجديدة فعليًا.

# END REPORT137
