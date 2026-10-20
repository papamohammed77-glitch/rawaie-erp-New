# Report455 — إصلاح جراحي لخطأ SyntaxError في Picker
التاريخ: 2026-10-20  
النطاق الوحيد: `erp-frontend/companies/company-1/warehouse/picker.html`  
المالك يطبق التعديل في التطبيق التشغيلي؛ لا تعديل على `main.html`.

## النتيجة
المصدر الحالي يحوي خطأ JavaScript نحويًا داخل `App.editPickedItem(index)`. يفشل parser في تحليل كتلة السكربت، لذلك `App is not defined` خطأ تابع وليس عيبًا مستقلًا في تعريف الكائن.

## الأدلة
- Current source: `papamohammed77-glitch/erp-frontend/companies/company-1/warehouse/picker.html`
- Current blob SHA: `12e74e484702598b28a2234734fa7dc92db4101e`; 52,798 حرفًا / 1,004 أسطر.
- Commit الحالي: `f99c9bca6a0caeeb933880c1de80185db27d1a0d`, “Update image handling and Swal.fire configurations”, 2026-10-20 14:07 UTC.
- Parent: `15da299daa62262a7a365f58ca5ed118f905c2a7`; blob السابق `b85e81ef1303e6abbb086fa35acdf84bf9638075`.
- في الـparent كان تعريف `title` صحيحًا؛ التعديل الأحدث أدخل `width` في موضع قيمة `title`.
- Historical baseline `rawaie-erp-review/PWA/warehouse/picker.html`, blob `7626ba320021a607854bf219f4bacd81fc3d1d92`, يستخدم نمطًا صحيحًا يفصل `title` و`width` و`html`.
- Report454 يعالج خطأ parsing تاريخيًا مختلفًا في فرع أخطاء تحميل الرانشيت؛ لا تعِد تطبيق إصلاحه باعتباره العيب الحالي.

## السبب الجذري
الموضع الحالي داخل `App.editPickedItem(index)`، السطران 682–683:

```javascript
            title:             
                width: 'min(92vw, 560px)','<span class="text-slate-800">' + it.item_name + '</span>',
```

خاصية `title:` بلا قيمة، ثم يظهر `width:` في موضع غير صالح؛ يتوقف parsing قبل تعريف `App`.

## التعديل الجراحي — ينفذه المالك
**الملف:** `companies/company-1/warehouse/picker.html`  
**الدالة:** `App.editPickedItem(index)`  
**محدد البحث:** `Swal.fire({` داخل الدالة، ثم خاصية `title:` التالية مباشرة.

ابحث عن المقطع أعلاه واحذفه فقط، واستبدله بالمقطع التالي:

```javascript
            title: '<span class="text-slate-800">' + it.item_name + '</span>',
            width: 'min(92vw, 560px)',
```

لا تستبدل الدالة كاملة، ولا تغيّر HTML الكمية والملاحظات أو منطق حفظ الكميات أو `operation_id` أو إدارة الجلسة.

## Production / Supabase
فُحصت قائمة Edge Functions الحية وجُلب `start-picking`: Production v35، `verify_jwt=true`، `ezbr_sha256=fca0377fce2d02d52a17bdbbdd98cfe9cc449d052533df0a3b021be11c79914a`. المصدر المنشور يطابق الهوية عبر `users.auth_id = auth.users.id` ويطبق سياق الشركة والصلاحيات. لا يوجد دليل يربط خطأ الواجهة بخلل في هذه الدالة؛ لم تُجرَ أي تغييرات على Supabase أو البيانات.

## اختبارات ما بعد التطبيق
1. أعد جلب المصدر وسجّل SHA الجديد.
2. افحص syntax لكل كتل JavaScript المضمنة.
3. انشر من المسار المعتمد وافتح التطبيق مع تعطيل cache؛ تحقق من النسخة المقدمة فعليًا.
4. تحقق من اختفاء `Unexpected token ':'` و`App is not defined` وعمل `App.togglePass()` و`App.doLogin()`.
5. بعد دخول مصرح به، افتح عنصرًا وتحقق من نافذة التعديل، العرض المتجاوب، حفظ الكمية والملاحظات وتحديث التقدم.
6. اختبر مساري تحميل الرانشيت: النجاح وخطأ القراءة، ثم تأكد من عدم تغير إكمال التحضير والإلغاء وإعادة الفتح.
7. لا تنشئ بيانات Production لاختبار خطأ syntax، ولا تغيّر SQL/RPC/ACL/Edge لهذا السبب.
8. Git source ليس دليل نشر أو E2E؛ سجّل دليل المتصفح بعد الاختبار.

## SELF-AUDIT FINAL
- **What I Proved:** عيب نحوي محدد؛ الـparent صحيح في خاصية `title`؛ `App is not defined` نتيجة لفشل parsing.
- **What I Did Not Prove:** لم أتحقق من HTML المقدم من نطاق الإنتاج ولم أنفذ Browser E2E بعد الإصلاح.
- **What I Fixed:** لم أعدل التطبيق التشغيلي؛ قدمت استبدالًا جراحيًا للمالك.
- **What I Initially Missed:** Report454 يصف عيبًا أقدم ومختلفًا.
- **What Could Still Be Wrong:** قد يختلف HTML المنشور عن Git أو توجد أخطاء parsing أخرى.
- **Final Confidence:** عالٍ في السبب المحدد؛ لا يكفي لإعلان نجاح النشر أو الإغلاق.
- **Final Closure Status:** `OPEN — OWNER PATCH + RUNTIME VERIFICATION REQUIRED`.
