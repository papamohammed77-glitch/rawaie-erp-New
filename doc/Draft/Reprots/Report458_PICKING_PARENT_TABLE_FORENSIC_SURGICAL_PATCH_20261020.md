# Report458 — تحقيق تكامل جدول التحضير في النظام الأم

التاريخ: 2026-10-20  
المهمة: تعديل جراحي يطبقه المالك في `erp-frontend/companies/company-1/main.html` فقط.  
حدود التنفيذ: لم أعدّل `main.html` أو `warehouse/picker.html`. لم أغيّر Production أو قاعدة البيانات أو Edge Functions أو بيانات الأعمال.

## PRE-CHANGE SELF-AUDIT

- Business Understanding: مرتفع — تم تتبع عرض الرانشيت من النظام الأم إلى بيانات التحضير المحفوظة.
- Architecture Understanding: مثبت جزئيًا — جدول النظام الأم يقرأ runsheets، والكمية المشتقة في run_sheet_details مصدرها order_details عبر trigger.
- Database Understanding: مثبت من Production — الأعمدة المطلوبة موجودة.
- Historical Understanding: تمت مراجعة CURRENT_STATE وتقارير Picker الحديثة 451 و454 و457؛ وهي تخص التطبيق التشغيلي وتؤكد أن تعديل main.html مسؤولية المالك وأن Core التحضير لا يُعدّل دون دليل.
- Production Understanding: فُحصت قاعدة SMART ERP مباشرة ووُجدت قيم تحضير فعلية. أُعيد جلب Edge functions start-picking v35 وcomplete-picking v18.
- Current Source Understanding: ملف main.html جُلب كاملًا عبر Git blob: SHA 1b38c60ff38d439d429474b17ff54b5b169c07b4، 1,777,471 حرفًا، 32,820 سطرًا.
- Execution Confidence: مرتفع لتحديد نقص واجهة الجدول؛ غير كافٍ لإثبات ما يراه المتصفح المنشور، إذ لم تتوفر أدلة Served HTML / Browser E2E.

### المصادر التي تمت مراجعتها

- Current source: `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`, blob SHA أعلاه.
- Current operational source: `companies/company-1/warehouse/picker.html`, blob SHA `ffe18d4483ee074230e32b1c96f60507e5876a4b`; لم يُعدّل.
- Current project state: `rawaie-erp-New/CURRENT_STATE.md`، blob SHA قبل هذا التقرير `84e8af2780d20df9b37c5166e00aa286d28e4330`.
- Historical execution records reviewed: Report451, Report454, Report457. هذه تقارير تاريخية لتطبيق Picker وCore وليست دليلًا على أن تعديل النظام الأم نُشر.
- Production project: `fiilmooggumokxanwiyx`, status ACTIVE_HEALTHY.
- Production Edge: `start-picking` v35 و`complete-picking` v18، وكلاهما `verify_jwt=true`.

## ما أثبته الفحص

1. في المصدر الحالي، `loadPicking()` يجلب حالات Open وConfirmed فقط، بينما صف الجدول يعرض الحالة الثابتة Picked؛ لذلك الحالة المعروضة لا تعكس الحالة الفعلية.
2. الجدول الحالي لا يعرض picker identity أو picker_start أو picker_end أو ملاحظات التحضير.
3. المصدر الحالي لا يحتوي استخدامًا لأسماء الأعمدة `picker_start` أو `picker_end` أو `reason_picking` داخل main.html.
4. تفاصيل التحضير الحالية تقرأ `run_sheet_details.qty_picked` وتعرض هذا الحقل بالفعل. لم يثبت وجود خطأ في اسم جدول الكمية أو اسم العمود في المصدر الحالي.
5. Production SQL الحالي يؤكد أن الرانشيت RS-1 في الشركة ذات المعرّف `00000000-0000-0000-0000-000000000001` حالته Picked، وله picker_id مرتبط بالمستخدم `picker@rawaea.com`، ووقت بداية ونهاية، ومجموع qty_picked = 13 في order_details و13 في run_sheet_details. الرانشيت RS-2 حالته Open ومجموع التحضير 0. هذا يثبت أن قاعدة البيانات الحالية لا تعيد صفرًا للرانشيت RS-1؛ لا يثبت وحده أن HTML المنشور أو المتصفح يعرضان نفس المصدر.
6. سجلات audit_log توثق انتقال RS-1 من Picking إلى Picked في 2026-10-20، وتؤكد أن picker_start وpicker_end كُتبا. لم تُنفذ أي عملية تعديل أو حذف لهذه البيانات.
7. Production Core الحالي يحتوي overload قديمًا وآخر يدعم operation_id في complete_runsheet_picking؛ لا يوجد دليل يربط هذا الأمر بعرض أعمدة الجدول، لذلك لم يُغيّر أي RPC أو Edge Function.

## Root Cause

النقص المثبت في النظام الأم هو **واجهة الجدول وربط بيانات العرض**: لا توجد أعمدة للمحضّر والأوقات والملاحظات، واستعلام القائمة لا يجلب الرانشيتات المكتملة، كما أن الحالة مطبوعة بصورة ثابتة. أما مشكلة كمية التحضير = صفر فلم تتكرر في لقطة Production الحالية، والمصدر الحالي يقرأ العمود الصحيح. يلزم بعد تطبيق تعديل الواجهة التحقق من نسخة HTML المنشورة بذاكرة متصفح معطّلة قبل نسبة الصفر إلى Production.

## التعديل الجراحي A — رأس الجدول وخيارات الحالة

الملف: `companies/company-1/main.html`  
SHA المستهدف: `1b38c60ff38d439d429474b17ff54b5b169c07b4`  
الدالة: `loadPicking()`  
الموضع الحالي: قرابة الأسطر 15305–15318.  
محدد البحث: `id="pk-f-st"` ثم `<tbody id="pk-table"`.

استبدل خيارات الحالة داخل select فقط لتصبح:

~~~html
<option value="">كل الحالات</option>
<option value="Open">Open</option>
<option value="Confirmed">Confirmed</option>
<option value="Picking">Picking</option>
<option value="Picked">Picked</option>
~~~

واستبدل كتلة الجدول الحالية التي تبدأ بـ `<div class="bg-white rounded-2xl shadow-sm border overflow-auto"` وتنتهي بعد `<tbody id="pk-table"...` بهذه الكتلة:

~~~html
<div class="bg-white rounded-2xl shadow-sm border overflow-auto" style="max-height:65vh">
  <table class="w-full">
    <thead class="bg-gray-50 sticky top-0">
      <tr>
        <th class="p-3">الرانشيت</th>
        <th class="p-3">التاريخ</th>
        <th class="p-3">السائق</th>
        <th class="p-3">الحالة</th>
        <th class="p-3">مسؤول التحضير</th>
        <th class="p-3">وقت بداية التحضير</th>
        <th class="p-3">وقت الانتهاء</th>
        <th class="p-3">ملاحظات التحضير</th>
        <th class="p-3 text-center">عرض</th>
      </tr>
    </thead>
    <tbody id="pk-table">
      <tr><td colspan="9" class="text-center py-8">جاري التحميل...</td></tr>
    </tbody>
  </table>
</div>
~~~

## التعديل الجراحي B — جلب بيانات القائمة ضمن الشركة

داخل `loadPicking()`، ابحث عن المقطع الذي يبدأ بـ:

~~~javascript
var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
~~~

وينتهي عند:

~~~javascript
_applyPicking();
~~~

استبدل هذا المقطع فقط بالنص التالي:

~~~javascript
var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) {
    showToast('سياق الشركة غير محدد', 'error');
    return;
}

try {
    var res = await supabase
        .from('runsheets')
        .select('id,company_id,runsheet_code,run_date,driver_id,status,picker_id,picker_start,picker_end')
        .eq('company_id', companyId)
        .in('status', ['Open', 'Confirmed', 'Picking', 'Picked'])
        .order('run_date', { ascending: false });

    if (res.error) throw res.error;

    var runsheets = res.data || [];
    if (!runsheets.length) {
        window._pickingData = [];
        _applyPicking();
        return;
    }

    var runsheetIds = runsheets.map(function(r) { return r.id; });
    var pickerIds = Array.from(new Set(
        runsheets.map(function(r) { return r.picker_id; }).filter(Boolean)
    ));
    var usersById = {};

    if (pickerIds.length) {
        var usersRes = await supabase
            .from('users')
            .select('id,company_id,name,email')
            .eq('company_id', companyId)
            .in('id', pickerIds);

        if (usersRes.error) throw usersRes.error;

        (usersRes.data || []).forEach(function(u) {
            usersById[u.id] = u.name || u.email || '';
        });
    }

    var ordersRes = await supabase
        .from('orders')
        .select('id,runsheet_id,order_code')
        .eq('company_id', companyId)
        .in('runsheet_id', runsheetIds);

    if (ordersRes.error) throw ordersRes.error;

    var ordersById = {};
    var orderIds = [];
    (ordersRes.data || []).forEach(function(o) {
        ordersById[o.id] = o;
        orderIds.push(o.id);
    });

    var notesByRunsheet = {};
    if (orderIds.length) {
        var notesRes = await supabase
            .from('order_details')
            .select('order_id,item_name,reason_picking')
            .in('order_id', orderIds)
            .not('reason_picking', 'is', null);

        if (notesRes.error) throw notesRes.error;

        (notesRes.data || []).forEach(function(d) {
            var note = String(d.reason_picking || '').trim();
            var order = ordersById[d.order_id];
            if (!note || !order) return;

            var entry = [
                order.order_code || '',
                d.item_name || ''
            ].filter(Boolean).join(' / ') + ': ' + note;

            if (!notesByRunsheet[order.runsheet_id]) {
                notesByRunsheet[order.runsheet_id] = [];
            }
            notesByRunsheet[order.runsheet_id].push(entry);
        });
    }

    window._pickingData = runsheets.map(function(r) {
        return Object.assign({}, r, {
            picker_name: r.picker_id ? (usersById[r.picker_id] || '') : '',
            picking_notes: (notesByRunsheet[r.id] || []).join('، ')
        });
    });

    _applyPicking();
} catch (err) {
    console.error('Parent picking list load failed:', err);
    window._pickingData = [];
    _applyPicking();
    showToast('تعذر تحميل بيانات التحضير: ' + (err.message || 'خطأ غير معروف'), 'error');
}
~~~

هذا الربط يقرأ اسم المحضّر من users داخل الشركة نفسها، ويجمع reason_picking من order_details عبر order_id التابعة لأوامر الشركة والرانشيت المحدد. لا ينفذ أي كتابة.

## التعديل الجراحي C — عرض الأعمدة والقيم الفعلية

ابحث عن الدالة `function _applyPicking() {` واستبدل جسمها كاملًا حتى قوس إغلاق الدالة فقط بالنص التالي:

~~~javascript
function _applyPicking() {
    var d = window._pickingData || [];
    var id = (byId('pk-f-id')?.value || '').toLowerCase();
    var st = byId('pk-f-st')?.value;

    if (id) {
        d = d.filter(function(r) {
            return (r.runsheet_code || '').toLowerCase().indexOf(id) !== -1;
        });
    }
    if (st) {
        d = d.filter(function(r) { return r.status === st; });
    }

    var tb = byId('pk-table');
    if (!tb) return;

    if (!d.length) {
        safeHTML(tb, '<tr><td colspan="9" class="text-center py-8">لا توجد رانشيتات في الحالات المحددة</td></tr>');
        return;
    }

    function fmtTime(value) {
        if (!value) return '—';
        var date = new Date(value);
        return Number.isNaN(date.getTime()) ? esc(String(value)) : esc(date.toLocaleString('ar-EG'));
    }

    var statusLabels = {
        Open: 'مفتوح',
        Confirmed: 'مؤكد',
        Picking: 'قيد التحضير',
        Picked: 'اكتمل التحضير'
    };

    RW_Table.paginate('pk-table', d, 1, 50, function(r) {
        var status = statusLabels[r.status] || r.status || '—';
        var notes = r.picking_notes || '—';

        return '<tr class="border-b hover:bg-gray-50 cursor-pointer" onclick="RW_Warehouse._showPickingDetails(\'' +
            String(r.runsheet_code || '').replace(/\\/g, '\\\\').replace(/'/g, "\\'") +
            '\')">' +
            '<td class="p-3 font-bold">' + esc(r.runsheet_code || '') + '</td>' +
            '<td class="p-3">' + esc(r.run_date || '') + '</td>' +
            '<td class="p-3">' + esc(r.driver_id || '—') + '</td>' +
            '<td class="p-3"><span class="px-2 py-1 rounded-full text-xs bg-purple-100 text-purple-700">' + esc(status) + '</span></td>' +
            '<td class="p-3">' + esc(r.picker_name || '—') + '</td>' +
            '<td class="p-3 whitespace-nowrap">' + fmtTime(r.picker_start) + '</td>' +
            '<td class="p-3 whitespace-nowrap">' + fmtTime(r.picker_end) + '</td>' +
            '<td class="p-3 max-w-64"><span title="' + esc(notes) + '" class="block truncate">' + esc(notes) + '</span></td>' +
            '<td class="p-3 text-center"><button class="text-blue-600" aria-label="عرض تفاصيل التحضير"><i class="fa-solid fa-eye"></i></button></td>' +
            '</tr>';
    });
}
~~~

## التعديل الجراحي D — إظهار أخطاء استعلام تفاصيل التحضير بدل إخفائها

في `_showPickingDetails(code)` ابحث عن كتلة الاستعلام التي تبدأ بـ `var rsRes = await supabase.from('runsheets')` وتنتهي عند إنشاء `itemsRes`. استبدل تلك الكتلة فقط بالنص التالي:

~~~javascript
var rsRes = await supabase
    .from('runsheets')
    .select('id,status')
    .eq('company_id', companyId)
    .eq('runsheet_code', code)
    .maybeSingle();

if (rsRes.error) {
    hideLoader();
    showToast('فشل قراءة الرانشيت: ' + rsRes.error.message, 'error');
    return;
}
if (!rsRes.data || !rsRes.data.id) {
    hideLoader();
    showToast('الرانشيت غير موجود في الشركة الحالية', 'error');
    return;
}

var itemsRes = await supabase
    .from('run_sheet_details')
    .select('item_code,item_name,unit,qty_ordered,qty_picked')
    .eq('runsheet_id', rsRes.data.id)
    .order('item_code');

if (itemsRes.error) {
    hideLoader();
    showToast('فشل قراءة كميات التحضير: ' + itemsRes.error.message, 'error');
    return;
}
~~~

اترك بناء الجدول الحالي كما هو؛ فهو يعرض `it.qty_picked` من `run_sheet_details` بالفعل. لا تغيّر مصدر الكمية إلى جدول آخر، ولا تضف أي تحديث SQL أو كتابة مباشرة على projection.

## أثر التعديل

- إظهار اسم المحضّر ووقت البداية والنهاية.
- جمع ملاحظات النقص/التلف من `order_details.reason_picking` مع تعريف الأوردر والصنف وفواصل واضحة.
- إدراج حالات Open وConfirmed وPicking وPicked، وعرض الحالة الفعلية بدل كتابة Picked دائمًا.
- الحفاظ على company scope في استعلام الرانشيتات والمستخدمين والأوردرات.
- لا توجد كتابة في قاعدة البيانات؛ لا تأثير على الحجز أو المخزون أو دورة التحضير.

## اختبارات ما بعد تطبيق المالك

1. افحص Syntax للـ inline JavaScript كاملًا.
2. افتح النظام الأم بعد نشره مع تعطيل Cache، وتحقق من ظهور الأعمدة التسعة.
3. تحقق أن RS-1 أو أي رانشيت Picked يعرض اسم المحضّر ووقت البداية والنهاية، وأن Open لا يعرض بيانات تحضير وهمية.
4. تحقق أن الملاحظات تظهر فقط عند وجود reason_picking غير فارغ، وتضم الأوردر والصنف، وأن عدة ملاحظات تفصل بوضوح.
5. افتح تفاصيل رانشيت تم تحضيره: يجب أن تظهر القيم الفعلية من run_sheet_details.qty_picked. إذا بقيت صفرًا، سجّل Response Network الفعلي لـ run_sheet_details ونسخة HTML المنشورة؛ لا تغيّر Core ما دامت قاعدة Production الحالية تثبت مجموع 13 في RS-1.
6. اختبر شركة ثانية أو مستخدمًا من شركة أخرى: لا يظهر اسم مستخدم أو طلب أو ملاحظة من خارج company_id الحالية.
7. تحقق من Open وConfirmed وPicking وPicked، والبحث، وفلتر الحالة، وزر عرض التفاصيل.
8. أعد فحص Production للقراءة فقط بعد التعديل؛ يجب أن تبقى كميات المخزون والحجوزات كما هي.

## Production / Database / Edge

لم تُجرَ أي تعديلات. السبب: العيب المثبت خاص بعرض النظام الأم؛ ولقطة Production الحالية تثبت وجود picker timestamps وqty_picked. لم يُنشأ اختبار داخل Production ولم تُحذف بيانات.

## Closure Status

`OWNER SURGICAL PATCH READY / PRODUCTION CORE UNCHANGED / HTML DEPLOYMENT AND BROWSER E2E NOT YET VERIFIED`

## SELF-AUDIT FINAL

- What I Proved: غياب أعمدة الجدول المطلوبة، خطأ الحالة الثابتة، عدم جلب picker metadata/reason_picking، ووجود كميات التحضير فعليًا في Production.
- What I Did Not Prove: أن HTML المنشور هو نفس SHA الحالي، أو أن المتصفح الذي أظهر الصفر كان يقرأ هذا المصدر.
- What I Fixed: أعددت تغييرات جراحية محددة للمالك؛ لم أكتب إلى ملفات التشغيل.
- What I Initially Missed: حالة القائمة كانت تعرض Picked ثابتة رغم أن الاستعلام لا يجلب إلا Open وConfirmed.
- What Could Still Be Wrong: سياسات القراءة قد تمنع استعلام users أو order_details في بيئة المستخدم؛ سيظهر الخطأ الآن برسالة بدل إخفائه.
- Final Confidence: مرتفع في تشخيص فجوة الواجهة؛ متوسط في سبب الصفر السابق حتى فحص Served HTML وNetwork.
- Final Closure Status: NOT CLOSED — ينتظر تطبيق المالك والنشر واختبار المتصفح، ولا يجوز إعلان إغلاق كامل قبل ذلك.
