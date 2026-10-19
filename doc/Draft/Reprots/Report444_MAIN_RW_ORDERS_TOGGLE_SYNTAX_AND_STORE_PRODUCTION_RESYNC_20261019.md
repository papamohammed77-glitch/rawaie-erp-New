# Report444 — إصلاح SyntaxError في RW_Orders ومزامنة عقد المتجر الإلكتروني
**التاريخ:** 2026-10-19  
**النطاق:** `erp-frontend/companies/company-1/main.html` — خطأ الإقلاع في `RW_Orders`، مع تحقق محدود من عقد متجر الروائع في Production.  
**قاعدة الملكية:** لم أعدّل `main.html` أو `store/index.html`. التعديل الجراحي في الواجهة يطبقه المالك. لم أجرِ تغييرات Production لأن الخلل الحالي في JavaScript وليس في قاعدة البيانات أو RPC.

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** 97/100 — خطأ parsing في النظام الأم يمنع الإقلاع قبل أن يمكن اختبار تكامل التبويبات.
- **Architecture Understanding:** 97/100 — `RW_Orders` واجهة النظام الأم؛ أهلية الرانشيت يجب أن تبقى مطابقة لعقد Production.
- **Database Understanding:** 98/100 للأجزاء المفحوصة — فُحصت RPCs العامة والخاصة بالطلب وACL المرتبطة بالمتجر.
- **Historical Understanding:** 96/100 — تمت مراجعة Report443 وcommit الحالي ووالده؛ لم أعد تطبيق تغييرات تاريخية عمياء.
- **Production Understanding:** 98/100 — فحص SQL مباشر بتاريخ `2026-10-19 15:50 UTC`، وقراءة Edge المنشور `submit-online-order v11`.
- **Current Understanding:** 100/100 للنطاق المحدد — قُرئ مصدر `main.html` الحالي من Git blob حول موضع الخطأ، وفُحصت القطعة الحالية من المتجر.
- **Execution Confidence:** 98/100 لتشخيص السطر؛ إغلاق الواجهة بعد تطبيق المالك يتطلب فحص syntax ثم Browser E2E.

## 1. Current Git / Provenance

- المستودع: `papamohammed77-glitch/erp-frontend`.
- الملف: `companies/company-1/main.html`.
- Current blob SHA: `ad5360b7eeb8dcbeaefdd54760dccd4111b0fdd6`.
- آخر commit: `159b3113a14a1f8a23be759b7085fe7ae148ce21` — `Update main.html` — 2026-10-19 15:38:47 UTC.
- Parent commit: `ae287de38618d3de46ccbb93470a84b53434b535`.
- الملف التشغيلي للمتجر: `companies/company-1/store/index.html`, Current blob SHA `4af4e2f2f7727f84bdad5afb91932d5f7efe2a3e`.
- لم يتم تعديل أي ملف تشغيلي أو إنشاء commit للواجهة.

## 2. Root Cause — SyntaxError

أضاف commit `159b3113a14a1f8a23be759b7085fe7ae148ce21` السطر التالي داخل نهاية `RW_Orders._refreshData()`، بعد استدعاء `_applyFilters()` وقبل إغلاق الدالة:

```javascript
    _toggleOperationsOnly: _toggleOperationsOnly,
```

هذا السطر ليس ضمن كائن `return`; وجوده هنا يحوّل النص إلى تعبير غير صالح بسبب الفاصلة الختامية، ويطابق خطأ المتصفح `Unexpected token '}'` قرب السطر 11141. الدالة `_toggleOperationsOnly` موجودة بالفعل داخل الوحدة؛ الخلل في موضع تصديرها فقط، وليس مبررًا لإعادة كتابة `RW_Orders` أو تغيير قواعد checkbox.

## 3. التعديل الجراحي — يطبقه المالك فقط

**الملف:** `erp-frontend/companies/company-1/main.html`  
**الكائن:** `RW_Orders`  
**الموضع:** نهاية `_refreshData()`، قرب الأسطر 11138–11141، ثم كائن التصدير `return { ... }` قرب السطر 11142.

### PATCH A — احذف السطر من الموضع الخطأ

ابحث عن المقطع المطابق:

```javascript
    _populateSourceFilter();
    _applyFilters();        
	_toggleOperationsOnly: _toggleOperationsOnly,
}
    return {
```

واستبدله بهذا المقطع:

```javascript
    _populateSourceFilter();
    _applyFilters();
}
    return {
```

### PATCH B — صدّر الدالة داخل الكائن الصحيح

داخل كائن `return {`، ابحث عن السطر:

```javascript
        _showWithoutRS: _showWithoutRS,
```

وأضف تحته مباشرة:

```javascript
        _toggleOperationsOnly: _toggleOperationsOnly,
```

يجب أن يبقى السطر مرة واحدة فقط، ضمن كائن التصدير، وليس داخل جسم `_refreshData()`. لا تستبدل الدالة أو الكائن كاملًا، ولا تغيّر قائمة مصادر checkbox: `telesales`, `tele-sales`, `order-taker`, `online-store`.

## 4. Production — تحقق حي دون تعديل

تمت قراءة الحالة الحية للمشروع `fiilmooggumokxanwiyx`:

- `submit-online-order`: **v11 / ACTIVE / verify_jwt=false**، `ezbr_sha256=172eff4fccc8bf43f920e9ab8c83dd39aa988a68c9e5b3170ce320138ff31315`.
- `public.get_public_store_catalog(text)`: `SECURITY DEFINER` مع `search_path='public','pg_temp'`، ويعيد حقول الكتالوج العامة وحصة العرض والمتبقي؛ `anon/authenticated` يستطيعان تنفيذ RPC القراءة المحدود.
- `public.submit_online_order_atomic(..., p_operation_id uuid)`: `anon/authenticated EXECUTE=false` و`service_role EXECUTE=true`. لا توجد حاجة لفتح تنفيذ RPC الحساس للزوار.
- لقطة SQL عند `2026-10-19 15:50:48 UTC`: 17 صنفًا، صنف واحد بحصة عرض محددة، و16 صنفًا نشطًا ظاهرًا بالمتجر.
- لم تتغير قاعدة البيانات أو ACL أو Edge Function، ولم تُنشأ أو تُحذف بيانات أعمال أو Fixtures.

**النتيجة:** لا يوجد إصلاح Production مبرر بسبب خطأ syntax؛ تغيير RPC أو Edge لن يصلح JavaScript parsing.

## 5. ملاحظة تكامل المتجر — فجوة مثبتة لا تُخفى

المصدر الحالي للمتجر يحتوي تغييرات Report442 الخاصة بعرض `store_remaining_qty` وتقييد السلة وتحديث الكتالوج بعد نجاح الطلب. لكن `bodyPayload` الحالي لا يرسل `storefront_key` ولا `operation_id` ثابتًا. Edge v11 يولّد UUID جديدًا عند غياب الاثنين؛ لذلك إعادة إرسال الطلب من المتصفح بعد انقطاع الاستجابة لا تملك ضمان idempotency عبر المحاولات المختلفة. المسار الحالي يظل قادرًا على تحديد المتجر لأن Production لديه متجر منشور واحد، لكنه لا يحقق عقد retry ثابتًا من العميل. هذه فجوة مستقلة تحتاج تعديلًا جراحيًا لاحقًا في `store/index.html`؛ لم أخلطها مع إصلاح SyntaxError ولم ألمس الملف.

## 6. اختبار ما بعد التطبيق

1. نفّذ PATCH A وPATCH B فقط، ثم احفظ الملف.
2. افحص JavaScript parsing قبل النشر؛ يجب ألا يظهر `Unexpected token` أو خطأ syntax جديد.
3. افتح النظام الأم وتأكد من تجاوز شاشة الدخول ووصول `SYSTEM READY`.
4. افتح `RW_Orders` وتحقق من ظهور زر «أوردرات عمليات»، وأن الضغط عليه يعمل دون `RW_Orders._toggleOperationsOnly is not a function`.
5. تحقق من أن checkbox لا يزال يتيح فقط المصادر الأربعة المعتمدة وبالحالات/شروط الرانشيت القائمة.
6. اختبر الفلترة، إعادة التعيين، التحديث، وعرض تفاصيل الأوردرات؛ ثم اختبر المتجر العام وطلبًا معزولًا فقط بعد ضمان عدم تسجيل طلب إنتاجي حقيقي بالخطأ.
7. لم أنفذ Browser/HTTP E2E من هذه الجلسة؛ لا تُعتبر الواجهة مغلقة قبل اختبار المالك للنسخة المنشورة.

## SELF-AUDIT FINAL

- **What I Proved:** موضع السطر المعيب في current Git، commit الذي أدخله، ووجود الدالة في المكان الصحيح داخل الوحدة؛ عقد RPC وACL الحي للكتالوج والطلب.
- **What I Did Not Prove:** لم أنفذ المتصفح أو HTTP E2E، ولم أثبت تطابق artifact المنشور من Cloudflare مع Git.
- **What I Fixed:** لا تغييرات ملفات أو Production نفذتها؛ قدمت نقلًا جراحيًا دقيقًا للسطر المعيب ليطبقه المالك.
- **What I Initially Missed:** أن السطر المضاف داخل جسم `_refreshData` بدل كائن التصدير، وأن واجهة المتجر لا ترسل `operation_id` ثابتًا.
- **What Could Still Be Wrong:** قد توجد أخطاء runtime أخرى لا تظهر إلا بعد إصلاح parsing؛ كما أن idempotency من عميل المتجر ما زالت غير مكتملة.
- **Final Confidence:** 98/100 لتشخيص خطأ parsing؛ 90/100 لتكامل المتجر ضمن الأدلة المتاحة.
- **Final Closure Status:** `ROOT CAUSE VERIFIED / SURGICAL PATCH READY FOR OWNER / PRODUCTION UNCHANGED / BROWSER E2E OPEN / NOT CLOSED`.
