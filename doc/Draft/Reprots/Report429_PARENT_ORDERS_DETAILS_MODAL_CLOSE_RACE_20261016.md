# Report429 — إصلاح سباق إغلاق مودال تفاصيل الأوردر في النظام الأم
**التاريخ:** 2026-10-16  
**النطاق:** `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`، الوحدة `RW_Orders._showDetails(code)`.  
**حدود التنفيذ:** لم يُعدّل المساعد `main.html` أو أي تطبيق تشغيلي؛ المالك هو من يطبق تعديل الواجهة. لم تُنفذ أي كتابة على Production ولم تتغير بيانات أو Schema أو ACL.

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** الضغط على صف الأوردر يجب أن يعرض مودال التفاصيل ويبقيه ظاهرًا حتى يغلقه المستخدم.
- **Architecture Understanding:** `RW_Orders._showDetails(code)` يفتح مؤشر تحميل عبر SweetAlert، يقرأ `orders` ثم `order_details`، ثم يستدعي SweetAlert مرة أخرى لعرض التفاصيل، وبعدها ينفذ `.finally(hideLoader)`.
- **Database Understanding:** Production يحتوي سجل `ORD-1002` للشركة `00000000-0000-0000-0000-000000000001` وثلاثة صفوف تفاصيل مرتبطة به. لا يوجد دليل على نقص بيانات هذا الأوردر.
- **Historical Understanding:** تمت مقارنة الدالة الحالية مع النسخة التاريخية `rawaie-erp-review/PWA/main.html`، blob SHA `e81ae6fe3e0e473b98927ff5cb2d54ba6ef18d8d`. النسخة التاريخية كانت تغلق مؤشر التحميل قبل فتح مودال التفاصيل، ولم تكن تستخدم `.finally(hideLoader)` بعد استدعاء المودال.
- **Production Understanding:** استعلام SQL للقراءة فقط عند `2026-10-16 19:12:41.863949 UTC` أكد وجود `ORD-1002` وثلاثة صفوف تفاصيل. سجلات Supabase الحديثة تعرض استجابات HTTP 200 لطلبات `order_details`، لكن لا يمكن ربط جميع تلك الطلبات بنقرة مستخدم محددة؛ لا أدعي نجاح Browser E2E.
- **Current Understanding:** جرى جلب محتوى Git blob الحالي كاملًا من `erp-frontend/companies/company-1/main.html`، SHA `a192704e07d984fdbecd00ce40a73e95fa806a7e`، بطول 1,762,271 حرفًا و32,437 سطرًا. المساعد لم يكتب إلى هذا الملف.
- **Execution Confidence:** مرتفع في السبب الجذري على مستوى تدفق Promise وSweetAlert؛ غير مثبت بعد أن الإصلاح نُشر أو نجح في متصفح المستخدم.

## CURRENT / PRODUCTION SNAPSHOT

- **Current source:** `companies/company-1/main.html`, blob SHA `a192704e07d984fdbecd00ce40a73e95fa806a7e`.
- **Current source lines:** `showLoader` line 1218؛ `hideLoader` line 1219؛ `RW_Orders._showDetails(code)` يبدأ line 10693؛ استدعاء مودال التفاصيل line 10786؛ `.finally(hideLoader)` line 10809.
- **Production database:** 10 أوردرات للشركة عند الفحص؛ `ORD-1002` موجود، ID `4a2288df-b580-4736-bbac-7367f4edcc30`، وحالته `Pending` ومصدره `order-taker`، وله 3 صفوف `order_details`.
- **Latest relevant parent commit checked:** `27e6687b2101a9efb91c6fb65a1ae218096679e7`، بتاريخ 2026-10-12، غيّر تنسيق كائن `sourceLabel` فقط في منطقة صف الجدول؛ لا يفسر سباق إغلاق المودال.
- **Served Pages artifact parity:** UNVERIFIED. لم يثبت أن نسخة Cloudflare Pages المخدومة مطابقة لملف Git الحالي.

## ROOT CAUSE — PROVEN

التعريف الحالي عند line 1218:
```js
const showLoader = (title = 'جاري التحميل...') => { try { Swal.fire({ title, allowOutsideClick: false, didOpen: () => Swal.showLoading() }); } catch(e) { console.error(e); } };
const hideLoader = () => { try { Swal.close(); } catch(e) {} };
```

داخل `_showDetails(code)`، بعد تحميل التفاصيل، ينفذ callback:
```js
Swal.fire({
    title: 'تفاصيل الأوردر: ' + esc(code),
    // ...
});
```

لكنه **لا يعيد Promise الخاص بـ `Swal.fire`**. لذلك ينتهي callback فور استدعاء المودال، وتكتمل سلسلة القراءة، ثم ينفذ `.finally(function() { hideLoader(); })` فورًا. وبما أن `hideLoader()` يستدعي `Swal.close()` على نافذة SweetAlert الحالية، فإنه يغلق مودال التفاصيل الذي فُتح للتو. هذا عيب حقيقي في تدفق التحكم، وليس استنتاجًا من HTTP status.

النسخة التاريخية تؤكد اختلاف ترتيب دورة الحياة: كانت تستدعي `hideLoader()` قبل `Swal.fire` ولا تغلق النافذة بعد إنشائها. هذا يدعم إصلاحًا موضعيًا يحافظ على بنية الدالة الحالية.

## SURGICAL OWNER PATCH — سطر واحد

**الملف:** `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`  
**SHA الذي يجب مطابقته قبل التطبيق:** `a192704e07d984fdbecd00ce40a73e95fa806a7e`  
**الدالة:** `RW_Orders._showDetails(code)`  
**الموضع:** line 10786، داخل callback الذي يبني `html`، مباشرة بعد `var html = ...` وقبل خصائص مودال التفاصيل.  
**محدد البحث الدقيق داخل الدالة:**
```js
Swal.fire({
                        title: 'تفاصيل الأوردر: ' + esc(code),
```

**احذف هذا العنصر كاملًا واستبدله بالعنصر التالي كاملًا:**
```js
return Swal.fire({
    title: 'تفاصيل الأوردر: ' + esc(code),
    html: html,
    width: '1100px',
    showCloseButton: true,
    showConfirmButton: false,
    showCancelButton: true,
    cancelButtonText: 'إغلاق',
    didOpen: function() {
        var confirmBtn = document.getElementById('btn-confirm-order-modal');
        if (confirmBtn) confirmBtn.onclick = function() { Swal.close(); _confirmOrderFromDetails(code); };
        var deleteBtn = document.getElementById('btn-delete-order-modal');
        if (deleteBtn) deleteBtn.onclick = function() { Swal.close(); _delete(code); };
        var printBtn = document.getElementById('btn-print-order-modal');
        if (printBtn) printBtn.onclick = function() { _printOrder(code); };
    }
});
```

**مهم:** لا تستبدل `.finally(function() { hideLoader(); })` ولا تحذفها. إضافة `return` تجعل Promise الخاص بمودال التفاصيل جزءًا من سلسلة Promise الحالية؛ وبذلك ينتظر التنفيذ حتى يغلق المستخدم المودال، ثم يعمل `finally`. لا تغيّر polling أو Realtime أو صلاحيات قاعدة البيانات ضمن هذا الإصلاح.

## VERIFICATION PLAN

1. طبّق التعديل فقط إذا ظل SHA الحالي مطابقًا للـSHA أعلاه؛ إن تغير، أعد تحديد الموضع من المصدر الجديد.
2. انشر ملف النظام الأم وفق آلية المالك.
3. افتح تبويب الأوردرات واضغط `ORD-1002`: يجب أن يظل مودال التفاصيل ظاهرًا بدل إغلاقه فورًا.
4. تحقق من ظهور الأصناف الثلاثة ومن إمكانية إغلاق المودال يدويًا.
5. كرر الفتح والإغلاق عدة مرات، ثم اختبر زر التأكيد/الحذف/الطباعة فقط عندما تسمح حالة الأوردر والصلاحيات بذلك.
6. تحقق من أن طلب `orders` وطلب `order_details` المرتبطين بالنقرة ينجحان، وأنه لا يظهر `Order details error` أو خطأ JavaScript.
7. لا تنشئ بيانات أعمال اختبارية في Production. لا يلزم أي تغيير في Production DB لهذا العيب.
8. بعد التطبيق، أعد فحص artifact المخدوم وسجّل نتيجة Browser E2E قبل الإغلاق.

## SELF-AUDIT FINAL

- **What I Proved:** `hideLoader()` يغلق SweetAlert الحالي؛ استدعاء مودال التفاصيل لا يعيد Promise؛ `.finally(hideLoader)` يغلق المودال بعد انتهاء القراءة؛ المصدر التاريخي استخدم ترتيبًا لا يتضمن هذا الإغلاق المتأخر؛ Production يحتوي الأوردر وثلاثة صفوف تفاصيل.
- **What I Did Not Prove:** أن الإصلاح طُبق أو نُشر؛ تطابق Pages artifact مع Git؛ نجاح Browser E2E بعد التعديل.
- **What I Fixed:** لم أعدّل ملف الواجهة لأن ملكية تعديل النظام الأم للمالك. جهزت استبدالًا جراحيًا كاملًا من سطر الاستدعاء حتى نهاية إعداد المودال.
- **What I Initially Missed:** التقارير السابقة ركزت على polling وطلب التفاصيل، ولم تربط `.finally(hideLoader)` بتنفيذ `Swal.close()` بعد إنشاء مودال التفاصيل.
- **What Could Still Be Wrong:** قد توجد مشكلة مستقلة في artifact المخدوم، لكن ذلك لا ينفي العيب المثبت في تدفق Promise بالمصدر الحالي.
- **Final Confidence:** مرتفع في السبب الجذري بالمصدر الحالي؛ Runtime closure لم يثبت بعد.
- **Final Closure Status:** `ROOT CAUSE PROVEN / OWNER PATCH READY / PRODUCTION DB HEALTH NOT IMPLICATED / DEPLOYMENT + BROWSER E2E OPEN`.
- **Next exact resumption point:** يطبق المالك إضافة `return` أمام استدعاء `Swal.fire` المحدد، ثم ينشر ويختبر بقاء مودال `ORD-1002` ظاهرًا؛ بعدها تُحدّث الحالة بالأدلة الفعلية دون إعادة فتح إصلاحات سابقة.
