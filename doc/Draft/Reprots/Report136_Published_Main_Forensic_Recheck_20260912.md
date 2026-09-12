# Report136 — Published Main.html Forensic Recheck — 2026-09-12

## 0. الرسالة الهدف — يجب ألا تضيع

**هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا نتعامل معه كإضافات شكلية. وهذا متسق حرفيًا مع مبدأ الحوكمة: الدراسة أولًا، ثم إعادة بناء العقد التاريخي، ثم تتبع السلوك الحالي، ثم تحديد الفجوة، ثم التعديل الجراحي، ثم الاختبار والتحقق.**

هذا هو الهدف الوظيفي النهائي. لكن هذه الجلسة كانت نقطة تحقق حاسمة بعد دمج الأجزاء الأحد عشر في ملف النشر؛ لذلك لم يُعتبر الدمج مكتملًا قبل اجتياز الاختبارات الفعلية.

## 1. النطاق

النطاق المنفذ في هذه الجلسة هو:

`erp-frontend/companies/company-1/main.html`

وهذا هو **Source of Truth الحالي للنظام الأم المنشور**.

الملفات التالية بقيت مرجعًا تاريخيًا ولم يُعاد استخدامها كمصدر Assembly:

- `Current/PWA/main2/main1..main11.md`
- `Original/PWA/main/*`
- `Current/PWA/main/*`
- `Current/PWA/New-main/*`

لم يتم تعديل `main.html` بواسطة المساعد؛ وفق فصل المسؤوليات، التصحيح في هذا الملف يقوم به المالك يدويًا بعد استلام العناصر الدقيقة أدناه.

## 2. التحقق المباشر من الملف المنشور

تم التحقق من النسخة الفعلية الحالية في GitHub مباشرة، وليس من تقرير سابق فقط.

**الملف:** `companies/company-1/main.html`

**Blob SHA:** `327e2d966d1520c1391a0b0dc72cc0352f944ca7`

**الحجم:** `933,355 bytes`

**عدد الأسطر:** `17,415`

**SHA-256:** `64211035d623a75e17d2452e2c2f5916230dd00b5e9d0e9439b9515188e98294`

**EOF:**

```text
</script>
</body>
</html>
```

### Structural gate

التحقق الكامل للنص المنشور أثبت:

```text
HTML_OPEN/CLOSE   = 1/1
HEAD_OPEN/CLOSE   = 1/1
BODY_OPEN/CLOSE   = 1/1
STYLE_OPEN/CLOSE  = 1/1
SCRIPT_OPEN/CLOSE = 6/6
INCOMPLETE_MARKERS = []
DIRECT_PHYSICAL_WRITERS = []
```

وبالتالي لا يوجد خلل HTML بنيوي في هذه القياسات، ولا توجد عبارة `(قيد التطوير)` أو `TODO` أو `FIXME` أو `Coming Soon` في الملف المنشور وفق البحث الكامل.

## 3. النتيجة الحاسمة — الملف لم يجتز JavaScript Syntax

بعد تحويل أجسام الـ`script` فقط إلى ملف فحص مع المحافظة على أرقام أسطر `main.html`، فشل `node --check`.

تم إجراء أكثر من جولة من التحقق؛ فشل بعض الجولات الأولى كان في أدوات الفحص نفسها وتم تصحيحه، ثم ظهرت أخطاء حقيقية في `main.html` نفسه.

الاختبارات المؤكدة أثبتت وجود **ثلاثة أخطاء Template/String حقيقية** إضافة إلى مجموعة محددة من حالات escaping مزدوج داخل HTML constructors.

## 4. التصحيحات المطلوبة للمالك — لا تعدل أي شيء آخر

### MHTML-01 — السطر 1971

ابحث عن السطر **1971** كاملًا، وهو داخل `RW_Items`.

احذف السطر الحالي كاملًا واستبدله بهذا السطر كاملًا:

```js
                rowHtml += '<td class="p-4 text-center cursor-pointer underline text-blue-600 text-xs" onclick="RW_Items._switchSubTab(\'movement\'); setTimeout(function(){ RW_Items._renderStockMovementReport(' + _jsAttr(item.item_code) + ',' + _jsAttr(item.name) + ',' + _jsAttr(bid2) + ',' + _jsAttr(branchName2) + '); },200);">' + st.qty + '</td>';
```

### MHTML-02 — السطر 2278

داخل كتلة `RW_Items` الخاصة بمصفوفة الأرصدة.

```js
        var rowHtml = '<tr class="border-t hover:bg-gray-50"><td class="p-3 cursor-pointer font-bold text-blue-600" onclick="RW_Items._switchSubTab(\'movement\'); setTimeout(function(){ RW_Items._renderStockMovementReport(' + _jsAttr(item.item_code) + ',' + _jsAttr(item.name) + ',null); },200);">' + _esc(item.name) + ' <span class="text-xs text-gray-400">(' + _esc(item.item_code) + ')</span></td><td class="p-3 text-center font-bold">' + (item._totalStock||0) + '</td>';
```

### MHTML-03 — السطر 2283

```js
         rowHtml += '<td class="p-3 text-center cursor-pointer underline text-blue-600 text-xs" onclick="RW_Items._switchSubTab(\'movement\'); setTimeout(function(){ RW_Items._renderStockMovementReport(' + _jsAttr(item.item_code) + ',' + _jsAttr(item.name) + ',' + _jsAttr(bid2) + ',' + _jsAttr(branchName2) + '); },200);">' + st.qty + '</td>';
```

### MHTML-04 — السطر 2311

```js
            var rowHtml = '<tr class="border-t hover:bg-gray-50"><td class="p-3 cursor-pointer font-bold text-blue-600" onclick="RW_Items._switchSubTab(\'movement\'); setTimeout(function(){ RW_Items._renderStockMovementReport(' + _jsAttr(item.item_code) + ',' + _jsAttr(item.name) + ',null); },200);">' + _esc(item.name) + ' <span class="text-xs text-gray-400">(' + _esc(item.item_code) + ')</span></td><td class="p-3 text-center font-bold">' + (item._totalStock||0) + '</td>';
```

### MHTML-05 — السطر 2316

```js
    rowHtml += '<td class="p-3 text-center cursor-pointer underline text-blue-600 text-xs" onclick="RW_Items._switchSubTab(\'movement\'); setTimeout(function(){ RW_Items._renderStockMovementReport(' + _jsAttr(item.item_code) + ',' + _jsAttr(item.name) + ',' + _jsAttr(bid2) + ',' + _jsAttr(branchName2) + '); },200);">' + st.qty + '</td>';
```

### MHTML-06 — السطر 4806

الخلل مثبت مباشرة من النص المنشور: `</div>` كانت خارج الـstring.

الحالي:

```js
                '<div class="font-bold text-blue-600">' + Number(it.sales_price || 0).toLocaleString() + ' ' + currency</div>' +
```

الاستبدال الكامل:

```js
                '<div class="font-bold text-blue-600">' + Number(it.sales_price || 0).toLocaleString() + ' ' + currency + '</div>' +
```

### MHTML-07 — السطر 4904

الحالي:

```js
                '<td class="p-4 border-y font-bold text-blue-600">' + it.price.toLocaleString() + ' ' + currency</td>' +
```

الاستبدال الكامل:

```js
                '<td class="p-4 border-y font-bold text-blue-600">' + it.price.toLocaleString() + ' ' + currency + '</td>' +
```

### MHTML-08 — السطر 4908

الحالي:

```js
                '<td class="p-4 border-y font-black">' + line.toLocaleString() + ' ' + currency</td>' +
```

الاستبدال الكامل:

```js
                '<td class="p-4 border-y font-black">' + line.toLocaleString() + ' ' + currency + '</td>' +
```

### MHTML-09 — السطر 9010

هذا السطر يحتوي خطأ escaping مزدوج داخل `onclick`، مع وجود `replace(/'/g, "\\'")` صحيح ويجب الحفاظ عليه.

الاستبدال الكامل:

```js
                html += '<div onclick="RW_Warehouse._selectDriver(\'' + d.email + '\', \'' + (d.name || '').replace(/'/g, "\\'") + '\')" class="p-3 hover:bg-blue-50 cursor-pointer border-b"><div class="font-bold">' + d.name + '</div><div class="text-xs text-slate-400">' + d.email + '</div></div>';
```

### MHTML-10 — السطر 11142

ابحث عن السطر الذي يبدأ كاملًا بـ:

`        var html = '<div class="bg-white rounded-2xl shadow-sm border p-4"><div class="flex justify-between items-center mb-4"><h2 class="text-xl font-bold">...`

وهو سطر إنشاء **سند قبض جديد** داخل `RW_Finance`.

الخلل الوحيد المطلوب في هذا السطر هو تحويل:

```text
\\'receipts\\'
```

إلى:

```text
\'receipts\'
```

في **كل موضعين داخل السطر نفسه** الخاصين بـ `RW_Finance.renderSubTab('receipts')`.

لا تلمس بقية السطر.

### MHTML-11 — السطر 14457

الاستبدال الكامل للسطر:

```js
                return '<tr class="border-t hover:bg-gray-50 cursor-pointer" onclick="RW_Reports_Comprehensive._showRunsheetDetail(\'' + _esc(r.runsheet_code) + '\')">' +
```

### MHTML-12 — السطران 14572–14574

استبدل **السطرين كاملين** داخل `rows8.push` بهذا:

```js
                    'onclick="RW_Reports_Comprehensive._showItemMovementDetail(\'' +
                    _esc(items8[i8].item_code) +
                    '\', \''\')">' +
```

### MHTML-13 — السطران 16221–16223

استبدل **السطرين كاملين** داخل `return (` بهذا:

```js
                        'onclick="RW_Reports_Comprehensive._showSettlementDetail(\'' +
                        _esc(row.settlement_code) +
                        '\')">' +
```

### MHTML-14 — السطر 16569

الاستبدال الكامل للسطر:

```js
    html += '<button type="button" onclick="window.togglePasswordVisibility(\'owner-new-password\', this)" class="absolute left-2 top-2.5 text-gray-500 hover:text-gray-700 p-1"><i class="fa-solid fa-eye"></i></button>';
```

### MHTML-15 — السطر 16574

الاستبدال الكامل للسطر:

```js
    html += '<button type="button" onclick="window.togglePasswordVisibility(\'owner-confirm-password\', this)" class="absolute left-2 top-2.5 text-gray-500 hover:text-gray-700 p-1"><i class="fa-solid fa-eye"></i></button>';
```

## 5. عناصر لم تُعدّل لأنها صحيحة

لا تُجْرِ global replace لـ `\\'` أو `\'` في كامل الملف.

التحقق الجنائي أثبت وجود حالات صحيحة في أسطر كثيرة مثل 219 و225 و231 و1831 و1932–1935 و2345–2347 و3601 وغيرها.

الاستبدال يجب أن يقتصر على العناصر المحددة أعلاه.

## 6. لماذا لم يُعلن الإغلاق

رغم أن:

- حجم الملف صحيح.
- EOF صحيح.
- HTML structural gate ناجح.
- no incomplete markers.
- لا يوجد direct browser physical-stock writer حسب الفحص الساكن.

فإن:

`NODE_CHECK_ORIGINAL != PASS`

وبالتالي لا يجوز إعلان Assembly أو Gold/Diamond closure في هذه المرحلة.

## 7. ما تم في المستودعات

تم تحديث بوابة:

`erp-frontend/.github/workflows/cto_main_html_forensic_20260912.yml`

لتكون بوابة دائمة لفحص `main.html` المنشور فقط.

كما تم تصحيح:

`rawaie-erp-New/.github/workflows/forensic_main_assembly.yml`

ليتحول من reconstruction قديم إلى **published Source-of-Truth verification gate**.

ولا يعيد هذا workflow بناء الملف من `main2` أو `New-main`.

## 8. Production

لم تُنفذ أي migration أو تعديل بيانات في Supabase بسبب هذه الجولة؛ المهمة الحالية أثبتت أن العائق الحالي يقع في ملف النظام الأم المنشور نفسه.

لا يوجد سبب مثبت لتغيير Production قبل إصلاح Syntax في `main.html` وإعادة الاختبار.

## 9. Helper files

لم يتم تعديل:

- `Current/PWA/core.js`
- `Current/PWA/sw.js`
- `Current/PWA/register-sw.js`
- `Current/PWA/manifest.json`

والسبب أن قاعدة العمل الحالية تمنع الانتقال إلى طبقة التكامل قبل اجتياز Syntax/Structural gate للملف المركزي المنشور.

## 10. التجارب

### تجربة ناجحة

التحقق البنيوي الكامل للملف الحالي:

`17,415 lines / 933,355 bytes / EOF valid / HTML balanced / no incomplete markers`.

### تجارب فاشلة بسبب أداة التحقق

عدة جولات أولية أخطأت بسبب Regex/positioning في test harness نفسه. تم تصحيح أداة التحقق حتى أصبحت نتائجها قابلة للاعتماد، ولم تُعتبر أخطاء الـharness أخطاء في `main.html`.

### تجارب فاشلة بسبب الملف

بعد تصحيح الـharness ظهرت الأخطاء الحقيقية بالتتابع:

```text
line 1971 family -> invalid double escaping
line 4806 -> unterminated HTML string
line 4904 -> unterminated HTML string
line 4908 -> unterminated HTML string
```

وبعد تطبيق التصحيحات المذكورة في نسخة مؤقتة، ظهرت بقية حالات escaping المحددة أعلاه.

## 11. الحالة النهائية للجلسة

```text
HISTORICAL CONTEXT = VERIFIED
PUBLISHED SOURCE OF TRUTH = VERIFIED
FULL FILE SIZE = VERIFIED
FULL FILE LINE COUNT = VERIFIED
EOF = VERIFIED
HTML STRUCTURE = PASS
INCOMPLETE MARKERS = PASS
DIRECT PHYSICAL STOCK WRITER SCAN = PASS
JAVASCRIPT SYNTAX = FAIL
OWNER MAIN.HTML EDIT = REQUIRED
PRODUCTION CHANGE = NOT REQUIRED YET
HELPER FILE INTEGRATION = DEFERRED
ASSEMBLY CLOSURE = NO
GOLD/DIAMOND CLOSURE = NO
```

## 12. الخطوة التالية الوحيدة

بعد قيام المالك بتطبيق **MHTML-01 إلى MHTML-15 فقط** على النسخة الحالية من `companies/company-1/main.html`، تتم إعادة الفحص الكامل للملف نفسه من EOF إلى البداية عبر البوابة الدائمة.

لا توجد صلاحية لاعتبار المهمة مغلقة لمجرد نجاح syntax؛ بعد ذلك يجب الانتقال إلى functional/E2E integration للتأكد أن اكتمال التبويبات ليس شكليًا وأن العمليات المرتبطة بالمخزون والأوردر والرانشيت والتوصيل والجرد والمالية وHR/CRM تعمل كمنظومة واحدة.

# FINAL SELF-AUDIT

### What I Proved

- أن Source of Truth الحالي هو الملف المنشور في `erp-frontend`.
- أن الملف الحالي 17,415 سطرًا و933,355 بايت.
- أن EOF والبنية الأساسية للـHTML سليمان.
- أن عبارات النقص المحددة غير موجودة.
- أن direct physical stock writers غير ظاهرة في هذا الملف.
- أن هناك أخطاء JavaScript حقيقية قابلة للتحديد في المواضع المذكورة.

### What I Did Not Prove

- لم أثبت بعد Syntax PASS للنسخة المعدلة لأن `main.html` لم يُعدل بعد.
- لم أثبت بعد E2E correctness لجميع التبويبات.
- لم أثبت بعد functional Gold/Diamond completion لجميع Finance/HR/CRM/Reports flows.

### What I Fixed

- صححت Source-of-Truth governance في `forensic_main_assembly.yml`.
- بنيت/ثبتت بوابة forensic للملف المنشور.
- لم ألمس `main.html` نفسه وفق فصل المسؤوليات.

### What I Initially Missed

- في أول جولات الفحص تم اكتشاف عيوب في الـtest harness نفسه قبل عزل أخطاء الملف؛ تم تصحيح ذلك وعدم خلطه مع Defects في Production Source.

### What Could Still Be Wrong

أي Syntax defect جديد قد يظهر بعد إصلاح المجموعة الحالية؛ لذلك لا يُغلق الملف إلا بعد `node --check` على النسخة الأصلية المعدلة نفسها ثم functional verification.

### Final Confidence

```text
STRUCTURAL CONFIDENCE = HIGH
SYNTAX DEFECT IDENTIFICATION = HIGH
FUNCTIONAL COMPLETION = NOT PROVEN
ASSEMBLY READINESS = NO
FINAL CLOSURE = OPEN
```

# END REPORT136
