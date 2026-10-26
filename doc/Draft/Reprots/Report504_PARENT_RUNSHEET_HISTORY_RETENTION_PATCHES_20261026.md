# تقرير 504 — الاحتفاظ بتاريخ الرانشيتات عبر مراحل النظام الأم

**التاريخ:** 2026-10-26  
**النطاق:** `papamohammed77-glitch/erp-frontend`، الفرع `main`، الملف `companies/company-1/main.html`.  
**الحالة:** `FORENSIC REVIEW COMPLETE / SURGICAL PATCHES PROPOSED / NOT APPLIED / RUNTIME NOT VERIFIED`

## 1. SELF-AUDIT قبل التغيير

- **Business Understanding:** CONFIRMED — يجب الاحتفاظ بسجل تاريخي قابل للمراجعة بعد انتقال الرانشيت بين المراحل، مع عدم إتاحة إجراءات مرحلة سابقة بصورة غير صحيحة.
- **Architecture Understanding:** CONFIRMED — النظام الأم يعرض السجلات؛ التطبيقات التشغيلية والعقود الخلفية مسؤولة عن تنفيذ المراحل وآثارها.
- **Database Understanding:** CONFIRMED جزئيًا — تم فحص مخطط Production مباشرة، ووجدت أعمدة stage markers على `runsheets` للتحضير والتحميل والتوصيل والمرتجعات.
- **Historical Understanding:** CONFIRMED — تمت قراءة `CURRENT_STATE.md`، وReport503، وReport502، وملف التوجيه التشغيلي.
- **Current Understanding:** CONFIRMED — استعيد نص `main.html` من Git blob SHA `11f29e07c10ae1767db334fe101c382eca23bd00`؛ النص 1,785,871 حرفًا / 33,101 سطرًا.
- **Production Understanding:** CONFIRMED للـschema وقيم الحالة المرصودة فقط؛ لا يوجد في هذه الدورة تحقق Browser/HTTP E2E أو تحقق من HTML المستضاف.
- **Execution Confidence:** مرتفعة لتشخيص مرشحات الاستعلام المصدرية؛ غير كافية لإعلان التطبيق أو النشر أو الإغلاق.

### أدلة Production المباشرة
- PostgreSQL observation: `2026-10-26 12:56:00.165899+00` — وجود حقول `picker_id/picker_start/picker_end`, `loader_id/loader_start/loader_end`, `deliverer_id/delivery_start/delivery_end`, `return_handler_id/return_start/return_end`.
- PostgreSQL observation: `2026-10-26 12:56:14.704254+00` — جدول `runsheets` يحتوي صفين بحالة `Loaded` في لحظة الاستعلام.
- لا توجد حركة مخزون أو DDL/DML أو نشر Edge نفذ في هذه المراجعة.

## 2. السبب الجذري المثبت

- `loadPicking()` يقيد الرانشيت بالحالات `Open/Confirmed/Picking/Picked`.
- `loadLoading()` يقيدها بالحالة `Loaded`.
- `loadDelivery()` يقيدها بالحالة `Delivered` ولا يفحص `res.error`.
- `loadReturn()` يقيدها بالحالة `Returned` ولا يفحص `res.error`.
- `loadReceiving()` يقرأ سجلات `receiving` التابعة للشركة دون مرشح حالة؛ لا يوجد دليل حالي يبرر تعديل مرشح هذا التبويب.
- لا يوجد حذف صفوف من قاعدة البيانات في المقاطع التي فُحصت؛ المشكلة هي استبعادها من نتائج الاستعلام/العرض بحسب الحالة الحالية.

## 3. الرقع الجراحية المقترحة للمالك

### A. Picking — `loadPicking()`, قرب السطر 15335
استبدل:
```javascript
.in('status', ['Open', 'Confirmed', 'Picking', 'Picked'])
```
بـ:
```javascript
.or('status.in.(Open,Confirmed,Picking,Picked),picker_id.not.is.null,picker_start.not.is.null,picker_end.not.is.null')
```
وأضف إلى `select#pk-f-st`:
```html
<option value="Loaded">تم التحميل</option>
<option value="Delivered">تم التوصيل</option>
<option value="Returned">مرتجع</option>
```
الغرض: إبقاء الرانشيت التي لها دليل على دخول مرحلة التحضير بعد انتقال حالتها، مع الحفاظ على الحالات التشغيلية الحالية.

### B. Loading — `loadLoading()`, قرب السطر 15560
استبدل:
```javascript
.eq('status', 'Loaded')
```
بـ:
```javascript
.or('status.eq.Loaded,loader_id.not.is.null,loader_start.not.is.null,loader_end.not.is.null')
```
واستبدل خيارات `select#ld-f-st` بالخيارات:
```html
<option value="">كل الحالات التاريخية</option>
<option value="Loaded">تم التحميل</option>
<option value="Delivered">تم التوصيل</option>
<option value="Returned">مرتجع</option>
```
الغرض: الاحتفاظ بالرانشيتات التي تحمل دليلًا على مرحلة التحميل.

### C. Delivery — `loadDelivery()`, قرب السطر 15716
استبدل كتلة الاستعلام الحالية:
```javascript
var res = await supabase.from('runsheets')
    .select('*')
    .eq('company_id', companyId)
    .in('status', ['Delivered']);
        window._deliveryData = res.data || [];
        _applyDelivery();
```
بـ:
```javascript
try {
    var res = await supabase
        .from('runsheets')
        .select('*')
        .eq('company_id', companyId)
        .or('status.eq.Delivered,status.eq.Returned,deliverer_id.not.is.null,delivery_start.not.is.null,delivery_end.not.is.null')
        .order('run_date', { ascending: false });

    if (res.error) throw res.error;

    window._deliveryData = res.data || [];
    _applyDelivery();
} catch (err) {
    console.error('Parent delivery history load failed:', err);
    window._deliveryData = [];
    _applyDelivery();
    showToast(
        'تعذر تحميل سجل التوصيل: ' + (err.message || 'خطأ غير معروف'),
        'error'
    );
}
```

داخل صف الجدول في `_applyDelivery()`، استبدل النص الثابت:
```javascript
'<td class="p-3"><span class="px-2 py-1 rounded-full text-xs bg-green-100 text-green-700">Delivered</span></td>'
```
بـ:
```javascript
'<td class="p-3"><span class="px-2 py-1 rounded-full text-xs bg-green-100 text-green-700">' + esc(r.status || '—') + '</span></td>'
```
الغرض: إدراج سجلات التوصيل التاريخية والتحقق من أخطاء الاستعلام وعرض الحالة الحالية الفعلية بدل تثبيت النص `Delivered`.

### D. Returns — `loadReturn()`, قرب السطر 15765
استبدل كتلة الاستعلام الحالية:
```javascript
var res = await supabase.from('runsheets')
    .select('*')
    .eq('company_id', companyId)
    .in('status', ['Returned']);
        window._returnData = res.data || [];
        _applyReturn();
```
بـ:
```javascript
try {
    var res = await supabase
        .from('runsheets')
        .select('*')
        .eq('company_id', companyId)
        .or('status.eq.Returned,return_handler_id.not.is.null,return_start.not.is.null,return_end.not.is.null')
        .order('run_date', { ascending: false });

    if (res.error) throw res.error;

    window._returnData = res.data || [];
    _applyReturn();
} catch (err) {
    console.error('Parent return history load failed:', err);
    window._returnData = [];
    _applyReturn();
    showToast(
        'تعذر تحميل سجل المرتجعات: ' + (err.message || 'خطأ غير معروف'),
        'error'
    );
}
```

داخل صف الجدول في `_applyReturn()`، استبدل النص الثابت:
```javascript
'<td class="p-3"><span class="px-2 py-1 rounded-full text-xs bg-rose-100 text-rose-700">Returned</span></td>'
```
بـ:
```javascript
'<td class="p-3"><span class="px-2 py-1 rounded-full text-xs bg-rose-100 text-rose-700">' + esc(r.status || '—') + '</span></td>'
```
الغرض: إدراج السجلات ذات دليل مرحلة المرتجعات، والتحقق من الأخطاء، وعرض الحالة الحالية بدل افتراض أنها `Returned`.

## 4. لماذا لم أقترح تعديل تبويب Receiving؟

`loadReceiving()` يستعلم من `receiving` باستخدام `company_id` ويرتب النتائج حسب التاريخ، دون مرشح حالة. لا يوجد دليل من المصدر الحالي على أن انتقال حالة الرانشيت هو ما يستبعد عمليات الاستلام من هذا الجدول. لذلك لا أقترح تعديلًا بلا سبب مثبت.

## 5. حدود الإصلاح

هذه الرقع تجعل قوائم المراحل تحتفظ بالسجلات عندما تبقى stage markers ذات الصلة محفوظة في `runsheets`. وهي لا تنشئ سجل أحداث مستقلًا ولا تستطيع إعادة بناء أحداث لم تُحفظ أصلًا. يلزم بعد التطبيق اختبار أن الحقول التاريخية لا تُمسح عند انتقال الحالة، والتحقق من حالة كل انتقال في Core/Edge عند ظهور دليل على فقدانها.

**ملاحظات التحميل:** ما زالت فجوة عقد بيانات مستقلة. `runsheets.notes` لا يثبت أنه يحتوي ملاحظات الأصناف المحلية في Loader. لا ينبغي تغيير مخطط البيانات أو كتابة هذه الملاحظات في حقل عام دون تصميم عقد تخزين وتحقق من Core/Edge.

## 6. خطة التحقق بعد تطبيق المالك

1. إعادة جلب `main.html` وتأكيد SHA قبل تطبيق كل رقعة.
2. تطبيق الرقع المحددة فقط.
3. تحليل JavaScript المضمن كاملًا بعد التعديل، لا المقطع وحده.
4. اختبار قائمة التحضير برانشيت `Picked` ثم بعد انتقالها إلى `Loaded`.
5. اختبار سجل التحميل بعد انتقال الرانشيت إلى `Delivered` ثم `Returned`.
6. اختبار التوصيل مع رانشيت تم تسليمها ثم رانشيت أصبحت `Returned`.
7. اختبار المرتجعات مع وجود حقول مرحلة محفوظة، مع التأكد من عدم اختلاق حالة نهائية.
8. التحقق من نطاق الشركة وعدم تسرب سجلات شركة أخرى.
9. اختبار الاستعلامات عند الخطأ والنتيجة الفارغة.
10. مقارنة `stock_branches.qty`, `allocated_qty`, و`inventory_log` قبل وبعد فتح القوائم والتفاصيل؛ يجب ألا يحدث أي تغير من العرض.
11. التحقق من HTML الذي تقدمه الاستضافة وتشغيل Browser/HTTP E2E مصادق عليه.
12. لا تعلن `CLOSED` قبل التحقق الفعلي بعد تطبيق المالك.

## 7. Mutation Ledger

- **Operational source:** لم يتغير.
- **Production database/schema/data:** لم يتغير.
- **Edge Functions:** لم تتغير ولم تُنشر.
- **Owner patches:** مقترحة فقط؛ لم تطبق.
- **Tests:** Production schema/status inspection PASS؛ static-after-patch NOT RUN؛ Browser/HTTP E2E NOT RUN.
- **Status:** `PROPOSED / PARTIAL / NOT CLOSED`.

## 8. SELF-AUDIT FINAL

- **What I Proved:** مرشحات الحالة الحالية التي تستبعد التاريخ؛ وجود stage marker columns؛ سجل الاستلام لا يستخدم مرشح حالة؛ Production يحتوي صفين بحالة Loaded وقت الفحص.
- **What I Did Not Prove:** أن Cloudflare يقدم blob الحالي؛ أن الرقع تعمل في المتصفح؛ أن كل مراحل التاريخ محفوظة في كل مسار؛ أن ملاحظات Loader المحلية محفوظة.
- **What I Fixed:** لا تعديل تشغيلي؛ جهزت رقعًا جراحية قابلة للتطبيق.
- **What I Initially Missed:** تقرير503 لم يكن قادرًا على استعادة نص main.html عبر fetch_file؛ استُعيد النص لاحقًا مباشرة من Git blob SHA، مما أتاح إثبات مرشحات الاستعلام الحالية.
- **What Could Still Be Wrong:** إذا كانت حقول stage markers لا تُحفظ أو تُمسح في مسار خلفي، فلن تكفي رقعة الواجهة وحدها. يجب فحص انتقالات Core/Edge عند اختبار المسار.
- **Final Confidence:** مرتفعة في التشخيص المصدرّي؛ متوسطة في ملاءمة كل marker لكل lifecycle حتى الاختبار؛ منخفضة في النشر/runtime حتى تنفيذ E2E.
- **Final Closure Status:** `PARTIAL — PATCHES PROPOSED, OWNER APPLICATION AND RUNTIME VERIFICATION PENDING`.
