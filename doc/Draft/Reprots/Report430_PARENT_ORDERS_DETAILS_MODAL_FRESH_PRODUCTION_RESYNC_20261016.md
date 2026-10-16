# Report430 — إعادة مزامنة Production وإثبات الإصلاح الجراحي لمودال تفاصيل الأوردر
**التاريخ:** 2026-10-16  
**النطاق الوحيد:** `erp-frontend/companies/company-1/main.html`، وحدة `RW_Orders`، الدالة `_showDetails(code)`.  
**ملكية المصدر:** ملف `main.html` مملوك للمالك؛ لم أعدّله.  
**Production:** فحص مباشر للقراءة فقط؛ لم أغيّر Schema أو ACL أو RPC أو بيانات الأعمال.

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** النقر على صف أوردر يجب أن يفتح نافذة التفاصيل وتظل مفتوحة حتى يغلقها المستخدم، مع بقاء أزرار التأكيد والحذف والطباعة وسلوكها الحالي.
- **Architecture Understanding:** `_showDetails(code)` يقرأ الأوردر ضمن `company_id`، ثم يقرأ `order_details` بواسطة `order.id`، ثم يفتح SweetAlert للتفاصيل. بعد ذلك تنفذ سلسلة Promise `.finally(hideLoader)`.
- **Database Understanding:** استعلام Production المباشر أعاد `ORD-1002` للشركة `00000000-0000-0000-0000-000000000001`، بحالة `Pending` ومصدر `order-taker` وثلاثة صفوف تفاصيل.
- **Historical Understanding:** قارنت الدالة الحالية مع `rawaie-erp-review/PWA/main.html` عند blob SHA `e81ae6fe3e0e473b98927ff5cb2d54ba6ef18d8d`. المسار التاريخي يغلق Loader قبل إنشاء نافذة التفاصيل، ولا يملك finalizer يغلق نافذة التفاصيل بعد فتحها.
- **Production Understanding:** استعلام SQL للقراءة فقط نفّذ في `2026-10-16 19:20:28.412986+00 UTC`. سجلات Supabase الحديثة أظهرت طلبات `order_details` ناجحة HTTP 200، ومنها طلب قراءة مجمعة؛ هذه السجلات لا تثبت وحدها نتيجة نقرة بعينها.
- **Current Understanding:** جلبت Git blob الحالي مباشرة، لا اعتمادًا على مقتطف تقرير فقط: `erp-frontend/companies/company-1/main.html`, SHA `a192704e07d984fdbecd00ce40a73e95fa806a7e`, بطول 1,762,271 حرفًا و32,437 سطرًا. المقطع الفعلي الحالي يحتوي `Swal.fire({...})` دون `return`، ثم `.finally(function() { hideLoader(); })`.
- **Execution Confidence:** مرتفع جدًا في السبب الجذري على مستوى الكود. لم يُثبت بعد نشر الإصلاح أو نجاح Browser E2E بعد التطبيق.

## CURRENT / PRODUCTION FACTS

1. **Current Git SHA:** `a192704e07d984fdbecd00ce40a73e95fa806a7e`.
2. **Relevant parent commit checked:** `27e6687b2101a9efb91c6fb65a1ae218096679e7`; تغييره المعروف يخص تنسيق كائن `sourceLabel` وليس دورة حياة المودال.
3. **Exact current code path:** `_showDetails(code)` → query `orders` scoped by `_rwCompanyId()` → query `order_details` by `order.id` → open details modal → outer `.finally(hideLoader)`.
4. **Production baseline:** `ORD-1002` موجود وله 3 تفاصيل؛ لا حاجة لإنشاء سجل تجريبي أو تغيير بيانات أعمال حية لإثبات وجود البيانات.
5. **Production writes:** NONE. لم يثبت وجود خلل في RPC أو RLS أو Schema يستدعي تعديلًا. لا تجرِ تغييرات Production لهذا العيب الواجهي.

## ROOT CAUSE — PROVEN FROM CURRENT SOURCE

التعريف العام هو:

```javascript
const showLoader = (title = 'جاري التحميل...') => { try { Swal.fire({ title, allowOutsideClick: false, didOpen: () => Swal.showLoading() }); } catch(e) { console.error(e); } };
const hideLoader = () => { try { Swal.close(); } catch(e) {} };
```

داخل `_showDetails(code)`، callback الذي يجهّز التفاصيل يستدعي `Swal.fire({...})` لكنه لا يعيد Promise الخاص به. لذلك تنتهي سلسلة قراءة `order_details` بمجرد استدعاء المودال، ثم ينفّذ `.finally(hideLoader)`. وبما أن `hideLoader()` يستدعي `Swal.close()`، تُغلق نافذة التفاصيل التي افتُتحت للتو.

هذا السبب مثبت بتدفق التحكم في المصدر الحالي، وليس استنتاجًا من تحذيرات Tailwind أو favicon أو HTTP 200.

## OWNER CHANGESET — تعديل جراحي واحد

- **الملف:** `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`
- **SHA المطلوب مطابقته قبل التطبيق:** `a192704e07d984fdbecd00ce40a73e95fa806a7e`
- **الوحدة:** `RW_Orders`
- **الدالة:** `_showDetails(code)`
- **الموضع:** قرابة السطر 10786 وفق هذا الـSHA فقط.
- **محدد البحث:** داخل `function _showDetails(code)` ابحث عن النص الحرفي:
  `Swal.fire({`
  متبوعًا مباشرةً بـ:
  `title: 'تفاصيل الأوردر: ' + esc(code),`
- **العنصر المعيب كاملًا حاليًا:**

```javascript
Swal.fire({
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

- **احذف العنصر أعلاه كاملًا فقط واستبدله بالنص الكامل التالي:**

```javascript
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

**لا تعدّل ولا تحذف** `.finally(function() { hideLoader(); })`. إضافة `return` تجعل Promise المودال جزءًا من سلسلة Promise؛ فينتظر الـfinalizer حتى يغلق المستخدم نافذة التفاصيل، بدل إغلاقها فورًا.

## IMPACT / PRESERVATION

- يحافظ على إعدادات النافذة وأزرار التأكيد والحذف والطباعة كما هي.
- لا يغيّر استعلامات البيانات أو Company Scope أو عقد الـAPI.
- لا يغيّر Edge Functions أو RPCs أو RLS أو المخزون أو المحاسبة.
- لا ينشئ دوال مكررة، ولا يغيّر polling/Realtime.
- إذا تغيّر SHA قبل التطبيق، لا تستخدم رقم السطر القديم؛ أعد تحديد نفس العنصر في المصدر الحالي.

## VERIFICATION AFTER OWNER DEPLOYMENT

1. تأكد من SHA المصدر قبل التطبيق، ثم نفّذ الاستبدال الوحيد أعلاه.
2. انشر النظام الأم وفق آلية المالك، ثم تحقق من أن النسخة المخدومة تطابق المصدر المعدّل.
3. افتح `ORD-1002`: يجب أن تبقى نافذة التفاصيل ظاهرة، وتعرض الأصناف الثلاثة.
4. أغلق النافذة يدويًا، ثم أعد فتحها وإغلاقها عدة مرات.
5. تحقق من عمل زر التأكيد/الحذف/الطباعة وفق حالة الأوردر والصلاحيات، دون إجراء حذف أو تأكيد فعلي غير مقصود.
6. استخدم DevTools Network مع Preserve log لتوثيق طلب `orders` وطلب `order_details` الخاصين بالنقرة، وراقب Console.
7. لا تُعلن Browser E2E PASS حتى يُنفّذ الاختبار في المتصفح بعد النشر. لا تنشئ أوردرات أو معاملات مالية تجريبية في Production.

## SELF-AUDIT FINAL

- **What I Proved:** المصدر الحالي يحتوي الاستدعاء دون `return`؛ `hideLoader()` يغلق SweetAlert؛ finalizer ينفذ بعد اكتمال سلسلة القراءة؛ Production يحتوي `ORD-1002` وثلاثة صفوف تفاصيل؛ السجلات المرصودة لا تدل على عطل عام في قراءة التفاصيل.
- **What I Did Not Prove:** أن المالك طبق التعديل، أو أن Cloudflare Pages يخدم SHA الجديد، أو نجاح Browser E2E بعد الإصلاح.
- **What I Fixed:** لم أعدّل `main.html` التزامًا بملكية الملف؛ جهزت الاستبدال الجراحي الكامل ووثّقت الحالة الحالية.
- **What I Initially Missed:** لا يجوز إغلاق المهمة اعتمادًا على تقرير سابق؛ أُعيد جلب Git blob وفُحص Production في هذه الدورة.
- **What Could Still Be Wrong:** قد توجد مشكلة مستقلة في الـartifact المخدوم أو المتصفح؛ لا يمكن نفيها قبل النشر والاختبار الفعلي.
- **Final Confidence:** مرتفع جدًا في تشخيص عيب Promise؛ غير مثبت في Runtime بعد الإصلاح.
- **Final Closure Status:** `ROOT CAUSE PROVEN / SURGICAL OWNER PATCH READY / PRODUCTION DATA VERIFIED / OWNER DEPLOY + BROWSER E2E OPEN`.
- **Next exact resumption point:** يطبّق المالك إضافة `return` أمام استدعاء `Swal.fire` المحدد بعد التأكد من SHA، ثم ينشر ويختبر بقاء مودال `ORD-1002` ظاهرًا؛ بعد ذلك فقط تسجل نتيجة Runtime الفعلية في `CURRENT_STATE.md`.
