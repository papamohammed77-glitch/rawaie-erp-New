# Report388 — إغلاق جنائي لجسر المندوب في DirectSale / DirectReturn
**التاريخ:** 2026-10-01  
**النطاق:** النظام الأم RAWAEA ERP — `companies/company-1/main.html`  
**الحالة:** Production RPC مغلق ✅ / جراحة `main.html` جاهزة للتطبيق يدويًا / Browser Runtime مفتوح حتى إعادة النشر والاختبار

---

## 1. مرجعية الحقيقة في هذه الجلسة

تم تطبيق ترتيب الإثبات التالي:

1. **CURRENT GIT**
   - المستودع: `papamohammed77-glitch/erp-frontend`
   - HEAD: `bc4d7a02919dcaf82d11bb599e879281cd550737`
   - Parent: `80b5dc00da7aae08d442acef4beb6857681de481`
   - Current `main.html` blob: `6cb0ac47e8b3c8459ac5672d6fc3b0ec4bf9eaa3`

2. **CURRENT SOURCE**
   - `loadVouchers()` موجودة عند المنطقة الحالية حول السطر 14859.
   - جدول عرض الأذونات العام يحتوي بالفعل على عمود المندوب ويستخدم `v._custodian_name`.
   - لذلك لم تتم إعادة لمس هذا الجزء.
   - جدول DirectSale / DirectReturn المختلف موجود داخل:
     `async function _renderVoucherHistory(type)`
     حول السطر 14432.

3. **CURRENT PRODUCTION**
   - مشروع Supabase: `fiilmooggumokxanwiyx`
   - `stock_vouchers.custodian_user_id` موجود كهوية المندوب.
   - Trigger `trg_stock_vouchers_custodian` يفرض أن هوية العهدة لمستند DirectSale/DirectReturn هي مندوب بيع مباشر نشط من نفس الشركة وله `van-sales`.

4. **CURRENT DEPLOYMENT EVIDENCE**
   - لم يتم إثبات hash جديد للـserved artifact في هذه الجلسة.
   - لذلك لا يتم إعلان Browser Runtime PASS قبل تطبيق جراحة المصدر وإعادة النشر.

---

## 2. العنصر المعيب — السبب الجذري

العنصر المعيب ليس جدول `loadVouchers()` ولا هوية المندوب في قاعدة البيانات.

العنصر المعيب هو **عرض السجل داخل**:

`async function _renderVoucherHistory(type)`

والسبب مركب من جزأين:

### A. عقد Production الناقص

`inventory_voucher_report(LIST)` كان يعيد صفوف DirectSale / DirectReturn بدون:

- `custodian_user_id`
- `custodian_name`

وبالتالي الجدول المنفصل لم يكن يملك قيمة مندوب ليعرضها.

### B. عقد UI الناقص

الـHTML في `_renderVoucherHistory()` كان يرسم 10 أعمدة فقط:

`رقم الإذن، التاريخ، الحالة، المرجع، من، إلى، المنشئ، بنود، كميات، رقابة`

ولا يوجد فيه عمود `المندوب`.

النتيجة: حتى بعد وجود `custodian_user_id` في المستند نفسه، فإن هذه الواجهة تحديدًا لا تعرضه.

---

## 3. ما تم إصلاحه مباشرة في Production

تم تحديث **RPC الموجود نفسه** فقط:

`public.inventory_voucher_report(text,jsonb)`

Migration:

`direct_voucher_report_representative_projection_20261001`

### التعديل

أصبح صف `LIST` يعيد:

- `custodian_user_id`
- `custodian_name`

ويتم حل اسم المندوب عبر `public.users` مع تقييد `company_id`.

### ما لم يتم إنشاؤه أو تغييره

- Edge Function جديدة: **لا**
- RPC جديدة: **لا**
- جدول جديد: **لا**
- عمود جديد: **لا**
- RLS جديد: **لا**
- تغيير هوية المندوب: **لا**
- تغيير دورة المخزون: **لا**
- تغيير المحاسبة: **لا**

---

## 4. الاختبار الجنائي قبل الإصلاح

تم إنشاء DirectSale وDirectReturn مؤقتين داخل Transaction ثم استدعاء RPC القديم.

النتيجة الفعلية:

- الصفوف ظهرت.
- `custodian_user_id` لم يكن ضمن الناتج.
- `custodian_name` لم يكن ضمن الناتج.

إذن العطل مثبت وليس استنتاجًا.

---

## 5. الاختبار الجنائي بعد الإصلاح

تم تنفيذ Projection Test جديد داخل Transaction.

### DirectSale

RPC أعاد:

`custodian_user_id = 111b0730-a977-4d11-bcd0-2427b178a9e5`

`custodian_name = مندوب مبيعات بيع مباشر`

### DirectReturn

RPC أعاد القيمة نفسها لهوية العهدة واسم المندوب.

إذن عقد البيانات المطلوب للواجهة أصبح مغلقًا.

---

# 6. الجراحة المطلوبة في main.html

## لا تحذف الدالة `_renderVoucherHistory()` كلها

ابحث داخل:

`async function _renderVoucherHistory(type)`

ولا تعدل أي شيء خارج القطع الثلاثة التالية.

### الجراحة 1 — خلية المندوب داخل rowsHtml

**ابحث حرفيًا عن هذا العنصر:**

```html
'<td class="p-3 max-w-[220px]">'+esc(r.to_label||'—')+'</td>' +
'<td class="p-3">'+esc(r.custodian_name||'—')+'</td>' +
'<td class="p-3">'+esc(r.created_by||'—')+'</td>' +
```

**احذفه بالكامل واستبدله بهذا العنصر بالكامل:**

```html
'<td class="p-3 max-w-[220px]">'+esc(r.to_label||'—')+'</td>' +
'<td class="p-3">'+esc(r.custodian_name||'—')+'</td>' +
'<td class="p-3">'+esc(r.created_by||'—')+'</td>' +
```

موضعه: داخل `render()` في `_renderVoucherHistory(type)`، داخل بناء `rowsHtml`.

---

## الجراحة 2 — عدد الأعمدة في حالة الفراغ

**ابحث حرفيًا عن:**

```html
rowsHtml = '<tr><td colspan="11" class="p-8 text-center text-slate-400">لا توجد عمليات مطابقة للفلاتر الحالية</td></tr>';
```

**احذفه بالكامل واستبدله بهذا العنصر بالكامل:**

```html
rowsHtml = '<tr><td colspan="11" class="p-8 text-center text-gray-500">لا توجد عمليات مطابقة للمرشحات.</td></tr>';
```

السبب: إضافة عمود المندوب رفعت عدد الأعمدة من 10 إلى 11.

---

## الجراحة 3 — رأس الجدول

**ابحث حرفيًا عن جزء رأس الجدول هذا:**

```html
'<tr><th class="p-3 text-right">رقم الإذن</th><th class="p-3 text-right">التاريخ</th><th class="p-3 text-right">الحالة</th><th class="p-3 text-right">المرجع</th><th class="p-3 text-right">من</th><th class="p-3 text-right">إلى</th><th class="p-3 text-right">المندوب</th><th class="p-3 text-right">المنشئ</th><th class="p-3 text-center">بنود</th><th class="p-3 text-center">كميات</th><th class="p-3 text-center">رقابة</th></tr>'
```

**احذفه بالكامل واستبدله بهذا العنصر بالكامل:**

```html
'<tr><th>رقم الإذن</th><th>التاريخ</th><th>الحالة</th><th>المرجع</th><th>من</th><th>إلى</th><th>المندوب</th><th>المنشئ</th><th>بنود</th><th>كميات</th><th>رقابة</th></tr>'
```

موضعه: داخل `safeHTML(root, ...)` في نفس `_renderVoucherHistory(type)`.

---

# 7. النتيجة المتوقعة بعد الجراحة

DirectSale:

`... | من | إلى | المندوب | المنشئ | بنود | كميات | رقابة`

DirectReturn:

`... | من | إلى | المندوب | المنشئ | بنود | كميات | رقابة`

ويتم أخذ الاسم من:

`r.custodian_name`

ولا يتم إعادة بناء اسم المندوب من `vehicle.driver_id` في الواجهة.

هذا يحافظ على **هوية العهدة المسجلة على مستند الإذن** باعتبارها مصدر الحقيقة.

---

# 8. اختبار Production E2E transactional

تم الاختبار باستخدام:

- مستخدم الأذونات الحقيقي: `vouchers@rawaea.com`
- BR-01
- المركبة `CHV-2025-01`
- الصنف `1001`
- مندوب العهدة: `vansales@rawaea.com`

### DirectSale

`CREATE` → PASS  
`SEND` → PASS  
الفرع: 8 → 7  
مخزن السيارة: 0 → 1  
عهدة المندوب: +50

### DirectReturn

`CREATE` → PASS  
`SEND` → PASS  
مخزن السيارة: 1 → 0

`RECEIVE` → PASS  
الفرع: 7 → 8  
عهدة المندوب: -50

### Projection

الـRPC في الحالة التنفيذية أعاد:

`custodian_name = مندوب مبيعات بيع مباشر`

لـDirectSale وDirectReturn.

### Idempotency

دورة الاستلام الآمنة بقيت كما هي ولم تتغير.

---

# 9. التأثير المحاسبي والمخزني

لم يتم إدخال أي writer محاسبي جديد.

التأثير الموجود تاريخيًا بقي كما هو:

- DirectSale يسجل تحميل عهدة المندوب.
- DirectReturn يسجل تخفيض عهدة المندوب.
- الدورة الكاملة اختبرت بصافي عهدة = 0.
- `journal_entries` بقيت = 10 في الاختبار المعزول.
- رصيد الصنف في BR-01 عاد إلى 8.
- رصيد الصنف في مخزن السيارة عاد إلى 0.

إذن الجراحة **قرائية/Projection فقط** ولا تغير دفتر الأستاذ أو مخزون المؤسسة.

---

# 10. تنظيف البيانات التجريبية

كل اختبارات Production تمت داخل `BEGIN ... ROLLBACK`.

بعد الإلغاء تم التحقق فعليًا:

- QA vouchers = 0
- QA voucher details = 0
- QA operation rows = 0
- QA inventory logs = 0
- QA audit residue = 0
- BR-01 item 1001 = 8
- vehicle item 1001 = 0
- driver ledger net = 0

لا توجد بقايا اختبار.

---

# 11. لماذا لم نلمس الـEdge Functions

المسار الحالي يستخدم:

- `create-stock-voucher`
- `send-stock-voucher`
- `receive-stock-voucher`

وهذه تستدعي الـRPCs المركزية الموجودة بالفعل.

المشكلة ليست في إنشاء/إرسال/استلام الإذن؛ المشكلة في **Projection للعرض**.

لذلك إنشاء Function جديدة أو إعادة بناء دورة الـVoucher كان سيكون تغييرًا غير ضروريًا ومخالفًا للعقد المستقر.

---

# 12. لماذا لم نلمس الجراحة التاريخية للـmain.html

Commit `80b5dc00...` أصلح فسادًا تاريخيًا في السطر الخامس.

Current HEAD `bc4d7a...` لا يعيد هذا العيب.

لذلك:

- لا تعاد جراحة السطر 5.
- لا تعاد إصلاحات Report384/385/386.
- لا يعاد بناء Global Voucher Table.

هذه نقطة حماية من Regression.

---

# 13. تقييم التكامل مع المركز والتطبيقات المنفصلة

المبدأ الصحيح الذي ثبت في التحقيق:

`stock_vouchers.custodian_user_id`

هوية العهدة المركزية.

الـMother تعرض هذه الهوية.

والتطبيقات التشغيلية تبقى مسؤولة عن التنفيذ الميداني:

DirectSale:
`Branch → Vehicle`

DirectReturn:
`Vehicle → Branch`

والرقابة في النظام الأم تقرأ النتيجة من المستند المركزي، ولا تعيد اختراع العملية.

هذا يحافظ على فكرة RAWAEA الأساسية:
**التطبيقات الميدانية تنفيذية، والنظام الأم مركزي رقابي/إداري، وقاعدة البيانات هي مصدر الحقيقة.**

---

# 14. مقارنة فجوة العرض مع الأنظمة المنافسة

الأنظمة ERP الاحترافية في إدارة المخزون تعتمد على إظهار هوية العملية، الأطراف، الموقع، الكمية، الحالة، والحركة الناتجة ضمن نفس المستند أو تقرير مرتبط به.

في RAWAEA أصبح لدينا بالفعل:

- المستند
- المصدر
- الوجهة
- المندوب/صاحب العهدة
- الحالة
- تفاصيل الأصناف
- عدد الحركات
- عدد سجلات التدقيق
- Drill-down للرقابة

لكن بقيت بعض تحسينات العرض المستقبلية غير داخلة في هذه الجراحة، ومنها:

- اسم السيارة + اسم المندوب كهوية تشغيلية مزدوجة.
- قيمة العهدة في السجل.
- مستخدم الإرسال والاستلام.
- توقيت الاستلام.
- قبل/بعد الرصيد.
- مرجع العملية Idempotency.
- سبب الرفض أو الإلغاء.
- عرض أثر الحركة المخزنية بجوار المستند.

هذه تحسينات **مستقبلية منفصلة** ولا يجوز إدخالها ضمن إصلاح العمود الحالي.

---

# 15. Self Audit

| بند | النتيجة |
|---|---|
| Production أولًا | PASS |
| فحص Current Git | PASS |
| فحص HEAD وParent | PASS |
| فحص Current Source | PASS |
| Root Cause مثبت | PASS |
| إصلاح Production | PASS |
| Function جديدة | NO |
| Edge Function جديدة | NO |
| Schema change | NO |
| RLS change | NO |
| تغيير هوية custodian | NO |
| تغيير workflow المخزني | NO |
| تغيير المحاسبة | NO |
| إعادة إصلاح العيوب المغلقة | NO |
| تنظيف بيانات الاختبار | PASS |
| Transactional E2E للمسار | PASS |
| Browser-rendered E2E | OPEN |
| Served artifact identity | OPEN |

---

# 16. الإرشاد التنفيذي للجلسة القادمة

ابدأ دائمًا من:

`CURRENT GIT → CURRENT SOURCE → CURRENT PRODUCTION → CURRENT DEPLOYMENT`

ثم:

1. تحقق أن جراحة `_renderVoucherHistory(type)` الثلاثية طبقت حرفيًا.
2. افحص Syntax للـinline script.
3. انشر النسخة الحالية.
4. افتح DirectSale في النظام الأم.
5. افتح DirectReturn في النظام الأم.
6. تحقق من ظهور عمود **المندوب** وقيمة `custodian_name`.
7. تحقق أن Transfer وSupplierReturn لا تعرض قيمة مندوب غير صحيحة.
8. تحقق من empty state وأن `colspan=11`.
9. تحقق من refresh وعدم فقد lookup أو الفلاتر.
10. أخيرًا طابق served artifact مع Current Git.

**لا تعدل Production أو main.html مرة أخرى إلا إذا أثبت اختبار جديد Regression.**

---

# 17. حالة الإغلاق

**CLOSED**
- Root Cause
- Production data contract
- Representative projection
- Transactional backend E2E
- Data cleanup
- Accounting invariance

**OPEN**
- Manual application of the 3 surgical source replacements
- Fresh deploy
- Browser-rendered E2E
- Served artifact verification

---

## الخلاصة التنفيذية

المشكلة ليست أن المندوب غير موجود في قاعدة البيانات، وليست أن Trigger العهدة مفقود.

المشكلة الدقيقة هي أن **سجل DirectSale / DirectReturn داخل `_renderVoucherHistory()` كان مبنيًا بعقد 10 أعمدة وRPC لا يعيد بيانات العهدة**.

تم إغلاق عقد Production دون إنشاء بنية جديدة.

المطلوب على ملف `main.html` هو فقط الجراحات الثلاث المحددة في القسم 6.
