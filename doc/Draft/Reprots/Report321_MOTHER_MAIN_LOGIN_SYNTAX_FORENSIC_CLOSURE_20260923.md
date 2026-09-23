# تقرير 321 — التحقيق الجنائي لعطل Mother main.html ومنع تجاوز شاشة الدخول
## التاريخ: 2026-09-23
## الحالة: ROOT CAUSE PROVEN / SURGICAL OWNER PATCH READY

---

## 1. نطاق هذه الجلسة

هذه الوحدة تخص عطل النظام الأم فقط:

`main:6805 Uncaught SyntaxError: Unexpected token 'var'`

والأثر التشغيلي الظاهر:
- عدم تجاوز شاشة الدخول.
- عدم اكتمال Boot للـMother ERP.

تحذير Tailwind:
`cdn.tailwindcss.com should not be used in production`
تم تصنيفه كـInfrastructure/production-build warning غير حاجز لهذه الأزمة، وليس سبب العطل النحوي.

لم يتم تعديل `companies/company-1/main.html` بواسطة المساعد.

---

## 2. مصادر الحقيقة التي تم التحقق منها

تمت مطابقة:
- MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS.
- Report318.
- Report319.
- Report320.
- CURRENT_STATE التاريخي، ثم إعادة مطابقة كل ادعاء مؤثر مع Git الحالي.
- CURRENT Git في `papamohammed77-glitch/erp-frontend`.
- CURRENT SOURCE للـMother.
- Git history والـparent commit.
- GitHub Actions execution evidence.
- Service Worker / redirect / cache boundary.
- Production Supabase عند الحاجة إلى استبعاد أثر Backend.

القاعدة المستخدمة:
CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.

---

## 3. Git الحالي المثبت

### Frontend HEAD
`3eedbc60a940f8d4fffadb9d152bd362c3f8be04`

Message:
`forensic: persist current Mother HR extract`

Parent:
`9429006baa94eb92ffd5f215e2b085288681b94f`

Commit `3eedbc...` لم يعدّل `main.html`؛ عدّل فقط forensic extract.

### الـcommit الذي أدخل العطل
`9429006baa94eb92ffd5f215e2b085288681b94f`

Parent:
`6d505d30dcad981932b3f3562ea9bb37901fecb4`

الـdiff الرسمي أثبت حذف سطر:
`function openModal(code) {`

في موضعين:
1. داخل `RW_Customers`
2. داخل `RW_Suppliers`

مع بقاء جسم الدالة والـclosing brace وباقي البنية.

---

## 4. CURRENT main.html

المسار الحاكم:
`companies/company-1/main.html`

Current blob:
`6ea44f1a26ce6069855842dc9010a21acc726ad9`

الحجم:
31,612 lines تقريبًا.

الـparser الحالي باستخدام Node على الـinline JavaScript أعاد:

`SyntaxError: Unexpected token 'var'`

والسطر المشار إليه:

`6805: var _handleSave = function(c, isEdit) {`

---

## 5. ROOT CAUSE النهائي

الخطأ ليس في:

`var _handleSave`

هذا السطر هو نقطة ظهور الخطأ فقط.

الخطأ الحقيقي هو فقدان declaration للدالة:

`function openModal(code) {`

في بداية جسمي:
- Customer modal.
- Supplier modal.

بعد حذف declaration أصبحت أوامر مثل:

`const c = code ? data.find(...)`

داخل سياق غير صالح، ثم يصل parser إلى:

`var _handleSave`

فيعتبر `var` رمزًا غير متوقع.

إذن:

FOUND
→ ROOT CAUSE = حذف declaration مرتين
→ ليست مشكلة Supabase
→ ليست مشكلة Auth
→ ليست مشكلة Edge Function
→ ليست مشكلة Service Worker
→ ليست مشكلة Tailwind
→ ليست مشكلة `_handleSave`

---

## 6. الإثبات التجريبي

تم أخذ CURRENT blob كما هو.

### قبل الجراحة
Node parse:
`FAIL — Unexpected token 'var'`

### الجراحة الافتراضية في الذاكرة فقط
تمت إضافة سطر واحد فقط في كل موضع:

`function openModal(code) {`

قبل:
`const c = code ? data.find(x => x.customer_code === code) : null;`

وقبل:
`const s = code ? data.find(x => x.supplier_code === code) : null;`

### بعد الجراحة الافتراضية
Node parse:
`PASS`

لم تُجرَ الكتابة على `main.html`.

---

## 7. إثبات GitHub Actions

الـcommit `9429006...` شغّل:

### RAWAEA CTO — published main.html full forensic gate
Run:
`35876538098`

Job:
`107233790170`

النتيجة:
`failure`

لكن:

### Full-file structural audit
`PASS`

وأثبت:
- HTML tags متوازنة.
- EOF صحيح.
- لا توجد incomplete markers.
- لا توجد direct physical stock writers.

### Exact JavaScript syntax gate
`FAIL`

والـlog يثبت حرفيًا:

`/tmp/main-positioned.js:6805`
`var _handleSave = function(c, isEdit) {`
`SyntaxError: Unexpected token 'var'`

إذن Console report والـCI report متطابقان مع CURRENT SOURCE.

---

## 8. منع تفسير خاطئ للـTailwind warning

`cdn.tailwindcss.com` موجود في:
- `app.html`
- صفحات أخرى تاريخية/تشغيلية بحسب بنية المشروع.

هذا تحذير production-build وليس SyntaxError.

لا يوجد دليل أنه يمنع parser من قراءة Mother JavaScript.

لذلك لم يتم إدخال أي تعديل unrelated إلى هذه الوحدة.

---

## 9. Service Worker / Cache forensic check

CURRENT `sw.js` ينص على:
- Navigation/HTML network-backed.
- عدم caching لـHTML shell.
- static assets فقط تستخدم versioned cache.
- activate يعمل clients.claim.
- HTML لا يُعاد من cache.

لذلك لا يوجد أساس لإعادة فتح أزمة cache كـRoot Cause لهذه الحادثة.

كما أن الـCI أجرى checkout مباشرًا للـcommit المعيب ونجح structural audit ثم فشل JavaScript parse؛ أي أن العطل موجود في Source نفسه.

---

## 10. العلاقة مع أعمال Report320

الـcommit `9429006...` احتوى أيضًا أعمال Report320 الخاصة بـ:
- Branch code preview.
- VAN semantic badge.
- Fleet edit.
- openVehicleEdit.

هذه الأعمال مثبتة بالفعل في CURRENT main ويجب عدم إعادة تنفيذها.

العطل الحالي نتج من تعديل مستقل داخل Customer/Supplier functions.

قاعدة عدم إعادة ما تم إنجازه تنطبق هنا:
لا تُعاد أعمال Branch/Fleet.

---

## 11. الأم Mother ERP والعلاقات المعمارية

`forensic_main_assembly.yml` ما زال يثبت:

- repository: `papamohammed77-glitch/erp-frontend`
- path: `companies/company-1/main.html`
- ref: `main`
- `published_main_is_authoritative`
- historical fragments = reference only.

إذن Mother ERP هو الـcontrol center، والتطبيقات التشغيلية المنفصلة تبقى مستقلة في مهامها الميدانية.

لا يوجد في هذا العطل ما يبرر تغيير:
- دورة الأوردر.
- runsheet workflow.
- picker/loader/delivery/return contracts.
- inventory core.
- Vehicle/representative custody.
- stock writer architecture.

---

## 12. مراجعة تنافسية مختصرة

تمت مراجعة قدرات منافسة حالية لدعم roadmap، لا لتغيير هذا الـclosure:

### Odoo
يدعم عمليات Barcode تشمل receipts, deliveries, batch transfers, inventory adjustment, transfers.

### Microsoft Dynamics 365 Business Central
يدعم Transfer Orders بين المواقع، مع Ship ثم Receive وتتبع Stock in Transit.

### SAP
يوثق one-step / two-step stock transfers وStock in Transfer.

### Daftra
يوفر:
- Detailed Inventory Transactions.
- فلاتر حسب المنتج والمخزن والنوع والتاريخ.
- تتبع الوارد والمنصرف والمرجع والمخزن.
- Stock transfer بين المخازن.
- Stocktaking بالباركود.

الملاحظة المعمارية المهمة لـRAWAEA:
الميزة التنافسية ليست مجرد وجود Transfer/Inventory UI، بل الحفاظ على السلسلة الميدانية المتصلة مع التحكم المركزي في Mother.

هذه المراجعة لا تُنشئ Business Contract جديدًا في هذه الجلسة.

---

## 13. Production Supabase

لا يوجد Production backend defect مطلوب لإغلاق أزمة `main:6805`.

لذلك:
- لا Migration جديدة.
- لا RPC جديد.
- لا Edge Function جديدة.
- لا تعديل Production غير ضروري.

عدم تنفيذ backend change هنا مقصود ومثبت، وليس توقفًا عن العمل.

---

## 14. التعديل الجراحي المطلوب من المالك

### CHANGE 321-CUST-01

ابحث داخل الكائن:

`RW_Customers`

وابحث عن هذا النص الحرفي:

`const c = code ? data.find(x => x.customer_code === code) : null;`

الموضع الحالي يسبقه declaration مفقود.

استبدل السطر الفارغ/المفقود مباشرة قبله بالمقطع التالي فقط:

```javascript
    function openModal(code) {
        const c = code ? data.find(x => x.customer_code === code) : null;
```

لا تغيّر جسم modal.
لا تغيّر `_handleSave`.
لا تغيّر `_handleDelete`.
لا تستبدل الدالة كاملة.

### CHANGE 321-SUP-01

داخل الكائن:

`RW_Suppliers`

ابحث عن هذا النص الحرفي:

`const s = code ? data.find(x => x.supplier_code === code) : null;`

استبدل السطر الفارغ/المفقود مباشرة قبله بالمقطع التالي فقط:

```javascript
    function openModal(code) {
        const s = code ? data.find(x => x.supplier_code === code) : null;
```

لا تغيّر جسم modal.
لا تغيّر `_handleSave`.
لا تغيّر `_handleDelete`.
لا تستبدل الدالة كاملة.

---

## 15. ما يجب عدم لمسه

في نفس الجلسة لا تعاد معالجة:
- Branch code preview.
- VAN semantic badge.
- Fleet operational fields.
- Fleet edit action.
- Inventory core.
- post_stock_movement.
- voucher backend lifecycle.
- Report318 voucher patches.
- Van Sales integration.

إلا إذا ظهر دليل جديد من CURRENT source/Production.

---

## 16. التحقق بعد تطبيق المالك للجراحة

التسلسل:

1. Apply CHANGE 321-CUST-01.
2. Apply CHANGE 321-SUP-01.
3. لا تضف أي تعديل آخر.
4. Commit `main.html`.
5. يجب أن يعمل `Exact JavaScript syntax gate` بنجاح.
6. Publish.
7. تحقق من served artifact.
8. افتح Mother.
9. نفذ login.
10. راقب أول Console error فقط.
11. نفذ Customer open/new/edit path.
12. نفذ Supplier open/new/edit path.
13. ثم باقي Mother E2E.
14. لا تُحوّل static parse إلى Browser E2E.

---

## 17. Browser E2E

الحالة:
`OPEN`

السبب:
لا توجد جلسة Browser authenticated متاحة لهذه الجلسة تسمح بإثبات click-by-click على artifact المنشور.

لذلك:
Static parse PASS بعد الجراحة الافتراضية ≠ Browser E2E PASS.

---

## 18. Final Self-Audit

### What was proved
- Current Mother HEAD.
- Current parent.
- Current main blob.
- exact root cause.
- exact lines.
- CI reproduced same syntax error.
- in-memory surgical repair restored full JS parse.
- Tailwind warning is unrelated.
- SW cache is not the cause.
- no Production backend change is required for this closure.

### What was not proved
- authenticated browser login on the newly published artifact.
- served artifact SHA after owner publication.
- full click-through E2E after correction.

### What was fixed
لا يوجد source write من المساعد إلى `main.html`.
تم فقط تجهيز الجراحة الدقيقة وإثباتها في الذاكرة.

### What must not be repeated
Do not repair Branch/Fleet work again.
Do not repair _handleSave.
Do not replace Customer/Supplier full functions.
Do not modify Supabase for this frontend syntax incident.

### Final Closure Status
`ROOT CAUSE = CLOSED`
`OWNER PATCH = READY`
`SOURCE FILE = NOT YET PATCHED BY OWNER`
`PUBLISHED ARTIFACT = OPEN`
`BROWSER E2E = OPEN`

---

## 19. تعليمات البداية للجلسة القادمة

ابدأ من:
1. CURRENT_STATE الجديد.
2. Report321.
3. Verify Frontend HEAD and main blob.
4. ابحث عن السطرين الحرفيين أعلاه.
5. إذا كانا موجودين، لا تُصلحهما مرة أخرى.
6. Parse CURRENT main.
7. إذا PASS، لا تفتح أي Closure قديم.
8. Publish/verify artifact.
9. Browser E2E.
10. التقط أول Console error جديد فقط.
11. طابقه مع CURRENT Source ثم Production.
12. حدث CURRENT_STATE.

قاعدة الحوكمة:
لا تقرير سابق يتغلب على CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.
