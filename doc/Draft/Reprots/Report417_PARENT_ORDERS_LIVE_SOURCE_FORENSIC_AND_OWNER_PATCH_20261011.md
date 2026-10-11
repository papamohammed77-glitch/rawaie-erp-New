# Report417 — التحقيق الحي لجدول أوردرات المبيعات والتعديل الجراحي الدقيق
**التاريخ:** 2026-10-11  
**وقت إعادة فحص Production:** 16:34:18 UTC  
**النطاق الوحيد:** \`RW_Orders\` في الملف الأم \`erp-frontend/companies/company-1/main.html\`.  
**سياسة التنفيذ:** لم ألمس \`main.html\` أو أي تطبيق تشغيلي. لا يوجد تغيير SQL/Edge مبرر حاليًا؛ الإصلاح المطلوب في هذا النطاق هو تعديل واجهة يطبقه المالك.

## 1. PRE-CHANGE SELF-AUDIT

- **Business:** يجب أن يعكس الجدول الكمية المتبقية بعد المرتجع، ويحافظ على الكمية الأصلية للتدقيق، ويعرض المصدر/المنشئ/وقت الإنشاء، ويمنع اختيار POS أو مصدر غير مؤهل للرانشيت.
- **Architecture:** الـUI في مسؤولية المالك. الحماية النهائية لمصادر الرانشيت موجودة في RPCs المركزية، ولا يجوز إضعافها أو استبدالها بحماية checkbox.
- **Database:** جرى الاستعلام المباشر عن \`orders\` و\`order_details\`، وتعريفات RPCs وACL وسياسات RLS.
- **Historical:** تمت مراجعة CURRENT_STATE وتقارير 413/415/416 و408 باعتبارها أدلة تاريخية، ثم مطابقة العناصر مع المصدر الحي الفعلي.
- **Production:** المشروع \`SMART ERP / fiilmooggumokxanwiyx\` حالته \`ACTIVE_HEALTHY\`.
- **Current source:** الملف الحالي \`erp-frontend/companies/company-1/main.html\`، blob SHA \`4f94f9c6ebdde1b59632384628c72767d3bb950d\`; عدد الأسطر 32,363. تم جلب الـblob مباشرة وقراءة مقاطع RW_Orders الحية؛ لذلك أرقام الأسطر بهذا التقرير هي أرقام المصدر الفعلي الحالي، وليست أرقام snapshot.
- **Execution confidence:** مرتفع في تشخيص كود المصدر الحي وProduction Core/DB؛ غير مثبت في نشر واجهة جديدة أو Browser E2E بعد الدمج، لأن الدمج لم يتم احترامًا لملكية المالك.

## 2. ما أثبته Production الآن

وقت القراءة: \`2026-10-11 16:34:18.647178+00\`.

\`ORD-1006\`:
- المصدر \`pos\`، المنشئ \`cashier@rawaea.com\`.
- الحالة \`Partially Returned\`.
- \`total_amount=135.00\`، و\`original_total_amount=185.00\`.
- \`runsheet_id=NULL\`.
- صفا تفاصيل، والكمية المتبقية الإجمالية 1، وعدد سطور التفاصيل ذات كمية متبقية 1.
- لم تُعدّل بيانات أعمال أو مخزون أو حسابات.

تعريفات Production الحية لـ\`create_runsheet_atomic(uuid,text[],text)\` و\`append_orders_to_runsheet_atomic(uuid,text,text[],text)\` تتضمن رفض أي مصدر خارج \`telesales / tele-sales / order-taker / online-store\`. صلاحيات التنفيذ: \`anon=false\`, \`authenticated=false\`, \`service_role=true\`. لم يتغير تعريفهما منذ آخر Migration ذات صلة، ولا يوجد Defect في هذا الحارس يبرر تعديل Production الآن.

سجلات Supabase أظهرت طلبات مصادق عليها إلى \`GET /rest/v1/orders?select=*,runsheets(runsheet_code)&company_id=...\` بحالة HTTP 200 عند 16:32 و16:33 UTC. هذا يثبت نجاح قراءة الجدول من Runtime، ولا يثبت أن تعديلات الواجهة المطلوبة نُشرت.

## 3. المصدر الحي — مواضع العيوب الدقيقة

**المستودع:** \`papamohammed77-glitch/erp-frontend\`  
**الملف:** \`companies/company-1/main.html\`  
**Blob:** \`4f94f9c6ebdde1b59632384628c72767d3bb950d\`  
**رابط الملف:** https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/main.html

| السطور الحالية | العنصر | العيب المثبت |
|---|---|---|
| 10255 | معالج \`id="check-all"\` | يحدد كل \`.order-checkbox\` بلا استثناء المعطل. |
| 10257–10264 | رؤوس الجدول | يعرض \`order_date\` ولا يعرض \`source\` أو \`created_by\`. |
| 10267 | صف التحميل | \`colspan=9\`؛ يجب أن يطابق عدد الأعمدة بعد إضافة عمودين. |
| 10290–10305 | تحميل الأوردرات داخل \`render()\` | يجلب \`item_code\` فقط ويعد كل سطر؛ لا يستبعد \`qty_returned\` من الكمية الأصلية. |
| 10388–10398 | الفرز داخل \`_applyFilters()\` | يتعرف على \`order_date\` فقط كحقل تاريخ. |
| 10444–10491 | \`_renderTable(data)\` | كل مصدر قابل للتحديد؛ لا يعرض المصدر/المنشئ؛ تاريخ الجدول هو \`order_date\`; \`colspan=9\`. |
| 10631–10636 | تحديث العدد بعد التأكيد | يعيد عدّ جميع تفاصيل الأوردر دون استبعاد المرتجع. |
| 10661–10767 | \`_showDetails(code)\` | يعرض الكمية الأصلية فقط ويجمع \`line_amount\` الأصلي ليحسب إجماليًا قد يخالف \`orders.total_amount\`. |
| 10800–10844 | \`_buildPrintWindow(order,items,settings)\` | الطباعة تعرض الكميات الأصلية دون المرتجع/المتبقي، وتبني ضريبة/إجماليًا فرعيًا من السطور الأصلية. |
| 10969–10994 | \`_refreshData()\` | إعادة التحديث اللحظي تعيد عدّ كل تفاصيل الأوردر؛ فيعود العيب بعد أي Realtime refresh. |
| 10236–10238 | خيارات فلتر الحالة | لا تحتوي \`Partially Returned\`. |

لا يوجد تعريف منفصل باسم \`loadData()\` أو \`refreshRealtimeChannel()\` داخل وحدة \`RW_Orders\` الحالية؛ التحميل الأول داخل \`render()\` والتحديث في \`_refreshData()\`. لا تستخدم تواقيع snapshot القديمة في هذه النسخة.

## 4. التعديل الجراحي — يطبقه المالك في الملف الأم

### A. رؤوس الجدول وتحديد الكل
في السطر 10255، استبدل قيمة المحدد فقط:
\`\`\`javascript
document.querySelectorAll('.order-checkbox')
\`\`\`
بـ:
\`\`\`javascript
document.querySelectorAll('.order-checkbox:not(:disabled)')
\`\`\`

في السطر 10257 استبدل رأس التاريخ الحالي:
\`\`\`javascript
'<th class="p-3 text-center cursor-pointer text-xs font-bold uppercase" onclick="RW_Orders._sort(\\'order_date\\')">التاريخ <i class="fa-solid fa-sort"></i></th>' +
\`\`\`
بـ:
\`\`\`javascript
'<th class="p-3 text-center cursor-pointer text-xs font-bold uppercase" onclick="RW_Orders._sort(\\'created_at\\')">تاريخ ووقت الإنشاء <i class="fa-solid fa-sort"></i></th>' +
\`\`\`

بعد سطر عمود «العميل والمنطقة» الحالي (10258)، أضف:
\`\`\`javascript
'<th class="p-3 text-center cursor-pointer text-xs font-bold uppercase" onclick="RW_Orders._sort(\\'source\\')">المصدر <i class="fa-solid fa-sort"></i></th>' +
'<th class="p-3 text-center cursor-pointer text-xs font-bold uppercase" onclick="RW_Orders._sort(\\'created_by\\')">المنشئ <i class="fa-solid fa-sort"></i></th>' +
\`\`\`
ثم اجعل \`colspan="9"\` في سطر التحميل 10267 = \`colspan="11"\`. أضف خيارًا واحدًا داخل قائمة الحالة بعد \`<option>Returned</option>\` في السطر 10237:
\`\`\`html
<option>Partially Returned</option>
\`\`\`

### B. استبدال كتلة عدّ الأصناف في التحميل الأول
داخل \`render()\`، احذف من السطر 10293 حتى 10305 شاملًا، واستبدل الكتلة كاملة:
\`\`\`javascript
var detRes = orderIds.length
    ? await supabase.from('order_details')
        .select('order_id, item_code, qty, qty_returned')
        .in('order_id', orderIds)
    : { data: [], error: null };

if (detRes.error) throw detRes.error;

var itemsCountMap = {};
var details = detRes.data || [];
for (var i = 0; i < details.length; i++) {
    var d = details[i];
    var originalQty = Math.max(0, Number(d.qty) || 0);
    var returnedQty = Math.min(originalQty, Math.max(0, Number(d.qty_returned) || 0));
    if (originalQty - returnedQty > 0) {
        itemsCountMap[d.order_id] = (itemsCountMap[d.order_id] || 0) + 1;
    }
}
for (var j = 0; j < ordersData.length; j++) {
    ordersData[j].itemsCount = itemsCountMap[ordersData[j].id] || 0;
}
\`\`\`
وأضف فحص الخطأ مباشرة بعد استعلام \`ordRes\` في السطر 10290:
\`\`\`javascript
if (ordRes.error) throw ordRes.error;
\`\`\`
هذا لا يحذف سطرًا أصليًا من قاعدة البيانات؛ يعد فقط أسطر الكمية المتبقية.

### C. استبدال \`_renderTable(data)\` كاملة
ابحث عن التوقيع الدقيق عند السطر 10444:
\`\`\`javascript
function _renderTable(data) {
\`\`\`
واحذف الدالة كاملة حتى القوس الذي يغلقها عند السطر 10491، واستبدلها بالنص الكامل:
\`\`\`javascript
function _renderTable(data) {
    var tbody = byId('orders-table-body');
    if (!tbody) return;

    if (!data || data.length === 0) {
        safeHTML(tbody, '<tr><td colspan="11" class="text-center py-8 text-gray-500">لا توجد أوردرات</td></tr>');
        var pc = byId('orders-table-body-controls');
        if (pc) safeHTML(pc, '');
        return;
    }

    var checkAll = byId('check-all');
    if (checkAll) checkAll.checked = false;

    RW_Table.paginate('orders-table-body', data, 1, 50, function(o) {
        var sc = 'bg-gray-100 text-gray-700';
        if (o.order_status === 'Draft') sc = 'bg-yellow-100 text-yellow-700';
        else if (o.order_status === 'Confirmed') sc = 'bg-blue-100 text-blue-700';
        else if (o.order_status === 'Pending') sc = 'bg-purple-100 text-purple-700';
        else if (o.order_status === 'Invoiced' || o.order_status === 'Delivered') sc = 'bg-green-100 text-green-700';
        else if (o.order_status === 'Returned') sc = 'bg-orange-100 text-orange-700';
        else if (o.order_status === 'Partially Returned') sc = 'bg-amber-100 text-amber-700';
        else if (o.order_status === 'Cancelled') sc = 'bg-red-100 text-red-700';

        var actions = '';
        if (o.order_status === 'Draft') {
            actions += '<button onclick="event.stopPropagation();RW_Orders._confirm(\\'' + esc(o.order_code) + '\\')" class="text-green-600 mx-1" title="تأكيد"><i class="fa-solid fa-check-circle"></i></button>';
        }

        var currentUser = (typeof RW_STATE !== 'undefined' && RW_STATE.app) ? RW_STATE.app.currentUser : null;
        var permissions = (currentUser && Array.isArray(currentUser.permissions)) ? currentUser.permissions : [];
        var canDeleteInvoiced = !!(currentUser && (currentUser.isOwner === true || permissions.indexOf('*') !== -1 || permissions.indexOf('general_manager') !== -1 || permissions.indexOf('sales_manager') !== -1 || permissions.indexOf('sales_supervisor') !== -1));
        var canDelete = (o.order_status === 'Draft' || o.order_status === 'Confirmed' || o.order_status === 'Pending' || (o.order_status === 'Invoiced' && canDeleteInvoiced)) && !o.runsheet_id;
        if (canDelete) {
            actions += '<button onclick="event.stopPropagation();RW_Orders._delete(\\'' + esc(o.order_code) + '\\')" class="text-red-500 mx-1" title="حذف"><i class="fa-solid fa-trash-can"></i></button>';
        }

        var source = String(o.source || '').trim().toLowerCase().replace(/[ _]+/g, '-');
        var sourceEligible = ['telesales', 'tele-sales', 'order-taker', 'online-store'].indexOf(source) !== -1;
        var runsheetEligible = sourceEligible &&
            ['Confirmed', 'Pending'].indexOf(o.order_status) !== -1 &&
            !o.runsheet_id;
        var codeForAttr = String(o.order_code || '').replace(/[&<>"']/g, function(ch) {
            return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch];
        });
        var checkbox = '<input type="checkbox" class="order-checkbox" data-id="' + codeForAttr + '"' +
            (runsheetEligible ? '' : ' disabled title="المصدر أو الحالة لا يسمحان بإدخال الأوردر في رانشيت"') +
            ' aria-label="اختيار ' + codeForAttr + ' للرانشيت">';

        var sourceLabel = {
            'pos': 'كاشير / POS',
            'telesales': 'تلي سيلز',
            'tele-sales': 'تلي سيلز',
            'order-taker': 'آخذ أوردر',
            'online-store': 'المتجر الإلكتروني'
        }[source] || (String(o.source || '').trim() || 'غير معروف');

        var createdAt = o.created_at ? new Date(o.created_at).toLocaleString('ar-EG') : '—';
        return '<tr class="border-b hover:bg-gray-50 cursor-pointer" onclick="RW_Orders._showDetails(\\'' + esc(o.order_code) + '\\')">' +
            '<td class="p-3 text-center" onclick="event.stopPropagation()">' + checkbox + '</td>' +
            '<td class="p-3 text-center font-bold text-blue-600">' + esc(o.order_code || '') + '</td>' +
            '<td class="p-3 text-center">' + createdAt + '</td>' +
            '<td class="p-3 text-center"><p class="font-semibold">' + esc(o.customer_name || '') + '</p><p class="text-xs text-gray-500">' + esc(o.area || '') + '</p></td>' +
            '<td class="p-3 text-center">' + esc(sourceLabel) + '</td>' +
            '<td class="p-3 text-center text-xs">' + esc(o.created_by || 'غير محدد') + '</td>' +
            '<td class="p-3 text-center font-bold">' + (o.itemsCount || 0) + '</td>' +
            '<td class="p-3 text-center font-bold">' + Number(o.total_amount || 0).toLocaleString('ar-EG') + ' ' + esc(currency) + '</td>' +
            '<td class="p-3 text-center"><span class="px-2 py-1 rounded-full text-xs font-semibold ' + sc + '">' + esc(o.order_status || '') + '</span></td>' +
            '<td class="p-3 text-center">' + esc(o._runsheetCode || '---') + '</td>' +
            '<td class="p-3 text-center">' + actions + '</td>' +
        '</tr>';
    });
}
\`\`\`

### D. تعديل فرز التاريخ
داخل \`_applyFilters()\`، استبدل الشرط عند السطر 10392:
\`\`\`javascript
} else if (sortField === 'order_date') {
\`\`\`
بـ:
\`\`\`javascript
} else if (sortField === 'order_date' || sortField === 'created_at') {
\`\`\`
اترك فلاتر التاريخ \`f-date-from/f-date-to\` على \`order_date\`؛ فهي فلاتر تاريخ الطلب التجاري، بينما العمود الجديد يعرض وقت الإنشاء.

### E. استبدال عدّ الأصناف في \`_refreshData()\` كاملة
احذف الدالة من السطر 10969 إلى 10994 شاملًا، واستبدلها:
\`\`\`javascript
async function _refreshData() {
    var ordRes = await supabase.from('orders')
        .select('*, runsheets(runsheet_code)')
        .eq('company_id', _rwCompanyId());
    if (ordRes.error) throw ordRes.error;

    ordersData = (ordRes.data || []).map(function(o) {
        o._runsheetCode = o.runsheets && o.runsheets.runsheet_code
            ? o.runsheets.runsheet_code
            : null;
        return o;
    });

    var orderIds = ordersData.map(function(o) { return o.id; }).filter(Boolean);
    var detRes = orderIds.length
        ? await supabase.from('order_details')
            .select('order_id, qty, qty_returned')
            .in('order_id', orderIds)
        : { data: [], error: null };
    if (detRes.error) throw detRes.error;

    var itemsCountMap = {};
    var details = detRes.data || [];
    for (var i = 0; i < details.length; i++) {
        var d = details[i];
        var originalQty = Math.max(0, Number(d.qty) || 0);
        var returnedQty = Math.min(originalQty, Math.max(0, Number(d.qty_returned) || 0));
        if (originalQty - returnedQty > 0) {
            itemsCountMap[d.order_id] = (itemsCountMap[d.order_id] || 0) + 1;
        }
    }
    for (var j = 0; j < ordersData.length; j++) {
        ordersData[j].itemsCount = itemsCountMap[ordersData[j].id] || 0;
    }
    _applyFilters();
}
\`\`\`

### F. إصلاح إعادة العد بعد تأكيد الأوردر
داخل \`_confirmOrderFromDetails(code)\`، احذف أسطر إعادة العد الحالية 10631–10636:
\`\`\`javascript
// ✅ إعادة حساب itemsCount لهذا الأوردر
supabase.from('order_details').select('id', { count: 'exact', head: true }).eq('order_id', found.id).then(function(countRes) {
    if (countRes && countRes.count !== undefined) {
        found.itemsCount = countRes.count;
    }
});
\`\`\`
واستبدلها:
\`\`\`javascript
_refreshData().catch(function(refreshError) {
    console.error('Orders refresh after confirmation failed:', refreshError);
});
\`\`\`
هذا يمنع عودة عدّ السطور المرتجعة بالكامل بعد التأكيد.

### G. استبدال \`_showDetails(code)\` كاملة
احذف الدالة الحالية من السطر 10661 حتى 10767 شاملًا، واستبدلها:
\`\`\`javascript
function _showDetails(code) {
    showLoader('جاري تحميل التفاصيل...');
    supabase.from('orders').select('*')
        .eq('company_id', _rwCompanyId())
        .eq('order_code', code)
        .maybeSingle()
        .then(function(oRes) {
            if (oRes.error) throw oRes.error;
            var order = oRes.data;
            if (!order) throw new Error('الأوردر غير موجود');

            return supabase.from('order_details').select('*')
                .eq('order_id', order.id)
                .then(function(itemsRes) {
                    if (itemsRes.error) throw itemsRes.error;
                    var items = itemsRes.data || [];
                    var originalItemsTotal = 0;
                    var remainingItemsTotal = 0;
                    var returnedLineCount = 0;
                    var remainingLineCount = 0;
                    var itemsHtml = '';

                    items.forEach(function(it) {
                        var qty = Math.max(0, Number(it.qty) || 0);
                        var returned = Math.min(qty, Math.max(0, Number(it.qty_returned) || 0));
                        var remaining = Math.max(0, qty - returned);
                        var price = Math.max(0, Number(it.unit_price) || 0);
                        var originalValue = Number(it.line_amount);
                        if (!Number.isFinite(originalValue)) originalValue = qty * price;
                        var remainingValue = remaining * price;
                        var note = String(it.reason_return || it.notes || '').trim();
                        if (!note && qty > 0 && remaining === 0) note = 'مرتجع بالكامل';
                        else if (!note && returned > 0) note = 'مرتجع جزئي';
                        else if (!note) note = '—';

                        originalItemsTotal += originalValue;
                        remainingItemsTotal += remainingValue;
                        if (returned > 0) returnedLineCount++;
                        if (remaining > 0) remainingLineCount++;

                        itemsHtml += '<tr class="' + (qty > 0 && remaining === 0 ? 'bg-red-50' : (returned > 0 ? 'bg-amber-50' : '')) + '">' +
                            '<td class="p-2 font-semibold">' + esc(it.item_name || it.item_code || '') + '</td>' +
                            '<td class="p-2 text-center">' + esc(it.unit || 'حبة') + '</td>' +
                            '<td class="p-2 text-center">' + qty.toLocaleString('ar-EG') + '</td>' +
                            '<td class="p-2 text-center text-red-600">' + returned.toLocaleString('ar-EG') + '</td>' +
                            '<td class="p-2 text-center font-bold">' + remaining.toLocaleString('ar-EG') + '</td>' +
                            '<td class="p-2 text-center">' + price.toLocaleString('ar-EG') + '</td>' +
                            '<td class="p-2 text-center font-bold">' + remainingValue.toLocaleString('ar-EG') + '</td>' +
                            '<td class="p-2 text-center">' + esc(note) + '</td></tr>';
                    });

                    if (!itemsHtml) itemsHtml = '<tr><td colspan="8" class="text-center py-4 text-gray-500">لا توجد أصناف مسجلة لهذا الأوردر</td></tr>';
                    var deliveryFee = Number(order.delivery_fee) || 0;
                    var finalTotal = Number(order.total_amount);
                    if (!Number.isFinite(finalTotal)) finalTotal = remainingItemsTotal + deliveryFee;

                    var warningHtml = order.runsheet_id
                        ? '<div class="bg-amber-50 border-r-4 border-amber-500 p-3 mb-4 rounded"><p class="text-amber-700 text-sm"><i class="fa-solid fa-link ml-2"></i> مرتبط بالرانشيت: <strong>' + esc(order.runsheet_id) + '</strong></p></div>'
                        : '';
                    var actionButtons = '';
                    if ((order.order_status === 'Draft' || order.order_status === 'Pending') && !order.runsheet_id) {
                        actionButtons += '<button id="btn-confirm-order-modal" class="bg-blue-600 text-white px-6 py-2 rounded-xl font-bold shadow"><i class="fa-solid fa-check-circle ml-2"></i> تأكيد الأوردر</button>';
                    }
                    var currentUser = (typeof RW_STATE !== 'undefined' && RW_STATE.app) ? RW_STATE.app.currentUser : null;
                    var permissions = (currentUser && Array.isArray(currentUser.permissions)) ? currentUser.permissions : [];
                    var canDeleteInvoiced = !!(currentUser && (currentUser.isOwner === true || permissions.indexOf('*') !== -1 || permissions.indexOf('general_manager') !== -1 || permissions.indexOf('sales_manager') !== -1 || permissions.indexOf('sales_supervisor') !== -1));
                    var canDelete = ['Draft', 'Pending', 'Confirmed'].indexOf(order.order_status) !== -1 ||
                        (order.order_status === 'Invoiced' && canDeleteInvoiced);
                    if (canDelete && !order.runsheet_id) {
                        actionButtons += '<button id="btn-delete-order-modal" class="bg-red-600 text-white px-6 py-2 rounded-xl font-bold shadow"><i class="fa-solid fa-trash ml-2"></i> حذف الأوردر</button>';
                    }
                    actionButtons += '<button id="btn-print-order-modal" class="bg-emerald-600 text-white px-6 py-2 rounded-xl font-bold shadow"><i class="fa-solid fa-print ml-2"></i> طباعة الفاتورة</button>';

                    var html = '<div class="text-right">' + warningHtml +
                        '<div class="grid grid-cols-2 gap-4 bg-gray-50 p-4 rounded-2xl mb-4">' +
                        '<div><p><b>العميل:</b> ' + esc(order.customer_name || '') + '</p><p><b>المنطقة:</b> ' + esc(order.area || '') + '</p></div>' +
                        '<div><p><b>الحالة:</b> <span class="font-bold">' + esc(order.order_status || '') + '</span></p><p><b>الرانشيت:</b> ' + esc(order.runsheet_id || '---') + '</p></div></div>' +
                        '<div class="overflow-x-auto"><table class="w-full border text-sm"><thead class="bg-gray-100"><tr>' +
                        '<th class="p-2">الصنف</th><th class="p-2">الوحدة</th><th class="p-2">الكمية الأصلية</th><th class="p-2">المرتجع</th><th class="p-2">المتبقي</th><th class="p-2">السعر</th><th class="p-2">قيمة المتبقي التقريبية</th><th class="p-2">سبب/ملاحظة</th>' +
                        '</tr></thead><tbody>' + itemsHtml + '</tbody></table></div>' +
                        '<div class="text-xs text-gray-500 mt-2">أسطر الفاتورة الأصلية: ' + items.length +
                        ' | أسطر بها مرتجع: ' + returnedLineCount + ' | أسطر متبقية: ' + remainingLineCount + '</div>' +
                        '<div class="bg-gray-50 p-4 rounded-2xl mt-4">' +
                        '<div class="flex justify-between mb-2"><span>قيمة الأصناف الأصلية المسجلة/المحسوبة:</span><span>' + originalItemsTotal.toLocaleString('ar-EG') + ' ' + esc(currency) + '</span></div>' +
                        '<div class="flex justify-between mb-2"><span>قيمة المتبقي بسعر الوحدة قبل الخصومات:</span><span>' + remainingItemsTotal.toLocaleString('ar-EG') + ' ' + esc(currency) + '</span></div>' +
                        '<div class="flex justify-between mb-2"><span>رسوم التوصيل المسجلة:</span><span>' + deliveryFee.toLocaleString('ar-EG') + ' ' + esc(currency) + '</span></div>' +
                        '<div class="flex justify-between pt-2 border-t"><span class="font-bold">الإجمالي النهائي المسجل بالنظام:</span><span class="font-bold text-emerald-600 text-lg">' + finalTotal.toLocaleString('ar-EG') + ' ' + esc(currency) + '</span></div>' +
                        '<p class="text-xs text-gray-500 mt-2">الإجمالي النهائي مأخوذ من orders.total_amount؛ قيمة المتبقي المعروضة تقريبية قبل تسوية الخصومات والرسوم.</p></div>' +
                        '<div class="flex justify-center gap-3 mt-6 pt-4 border-t">' + actionButtons + '</div></div>';

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
                });
        })
        .catch(function(e) {
            showToast('فشل تحميل التفاصيل', 'error');
            console.error('Order details error:', e);
        })
        .finally(function() { hideLoader(); });
}
\`\`\`

### H. استبدال \`_buildPrintWindow(order, items, settings)\` كاملة
احذف الدالة الحالية من السطر 10800 إلى 10844 شاملًا، واستبدلها:
\`\`\`javascript
function _buildPrintWindow(order, items, settings) {
    hideLoader();
    settings = settings || {};

    var companyName = settings.company_name || 'الروائع';
    var taxRate = Number(settings.tax_rate) || 0;
    var vatNumber = settings.vat_number || '310000000000003';
    var registeredName = settings.registered_name || companyName;
    var businessAddress = settings.business_address || '';
    var printWindow = window.open('', '_blank');
    if (!printWindow) {
        showToast('الرجاء السماح بالنوافذ المنبثقة', 'warning');
        return;
    }

    var itemsHtml = '';
    for (var i = 0; i < items.length; i++) {
        var it = items[i];
        var qty = Math.max(0, Number(it.qty) || 0);
        var returned = Math.min(qty, Math.max(0, Number(it.qty_returned) || 0));
        var remaining = Math.max(0, qty - returned);
        var price = Math.max(0, Number(it.unit_price) || 0);
        var remainingValue = remaining * price;
        var note = String(it.reason_return || it.notes || '').trim();
        if (!note && qty > 0 && remaining === 0) note = 'مرتجع بالكامل';
        else if (!note && returned > 0) note = 'مرتجع جزئي';
        else if (!note) note = '—';

        itemsHtml += '<tr>' +
            '<td class="border p-2">' + esc(it.item_name || it.item_code || '') + '</td>' +
            '<td class="border p-2 text-center">' + esc(it.unit || 'حبة') + '</td>' +
            '<td class="border p-2 text-center">' + qty.toLocaleString('ar-EG') + '</td>' +
            '<td class="border p-2 text-center">' + returned.toLocaleString('ar-EG') + '</td>' +
            '<td class="border p-2 text-center">' + remaining.toLocaleString('ar-EG') + '</td>' +
            '<td class="border p-2 text-center">' + price.toLocaleString('ar-EG') + '</td>' +
            '<td class="border p-2 text-center">' + remainingValue.toLocaleString('ar-EG') + '</td>' +
            '<td class="border p-2">' + esc(note) + '</td></tr>';
    }
    if (!itemsHtml) itemsHtml = '<tr><td colspan="8" class="border p-2 text-center">لا توجد أصناف</td></tr>';

    var deliveryFee = Number(order.delivery_fee) || 0;
    var finalTotal = Number(order.total_amount);
    if (!Number.isFinite(finalTotal)) finalTotal = deliveryFee;
    var taxAmount = Math.round((finalTotal * taxRate / 100) * 100) / 100;
    var invoiceDate = order.order_date ? new Date(order.order_date).toISOString() : new Date().toISOString();
    var qrBase64 = generateQRInvoiceBase64(registeredName, vatNumber, invoiceDate, String(finalTotal), String(taxAmount));

    var html = '<!DOCTYPE html><html dir="rtl" lang="ar"><head><meta charset="UTF-8"><title>فاتورة ' + esc(order.order_code) + '</title>' +
        '<script src="https://cdn.jsdelivr.net/npm/qrcodejs@1.0.0/qrcode.min.js"><\/script>' +
        '<style>body{font-family:"Cairo",sans-serif;padding:20px}table{width:100%;border-collapse:collapse}th,td{border:1px solid #ddd;padding:8px;text-align:right}th{background:#f2f2f2}.muted{color:#666;font-size:11px}</style></head>' +
        '<body><div style="text-align:center;border-bottom:2px solid #000;padding-bottom:10px"><h1>فاتورة بيع</h1><p>رقم: ' + esc(order.order_code) + '</p><p>التاريخ: ' + (order.order_date ? new Date(order.order_date).toLocaleDateString('ar-EG') : '') + '</p></div>' +
        '<p><strong>البائع:</strong> ' + esc(registeredName) + ' | <strong>رقم ضريبي:</strong> ' + esc(vatNumber) + '</p>' +
        '<p><strong>العنوان:</strong> ' + esc(businessAddress) + '</p><p><strong>العميل:</strong> ' + esc(order.customer_name || '') + '</p><p><strong>المنطقة:</strong> ' + esc(order.area || '') + '</p>' +
        '<p><strong>الحالة:</strong> ' + esc(order.order_status || '') + '</p>' +
        '<table><thead><tr><th>الصنف</th><th>الوحدة</th><th>الأصلي</th><th>المرتجع</th><th>المتبقي</th><th>السعر</th><th>قيمة المتبقي التقريبية</th><th>سبب/ملاحظة</th></tr></thead><tbody>' + itemsHtml + '</tbody></table>' +
        '<p class="muted">الكميات الأصلية محفوظة للتدقيق؛ قيمة المتبقي تقريبية قبل تسوية الخصومات.</p>' +
        '<div style="margin-top:20px"><p>رسوم التوصيل المسجلة: ' + deliveryFee.toLocaleString('ar-EG') + ' ' + esc(currency) + '</p>' +
        '<p style="font-weight:bold;font-size:18px">الإجمالي النهائي المسجل: ' + finalTotal.toLocaleString('ar-EG') + ' ' + esc(currency) + '</p>' +
        '<p>ضريبة القيمة المضافة المحسوبة على الإجمالي النهائي وفق الإعداد: ' + taxAmount.toLocaleString('ar-EG') + '</p></div>' +
        '<div style="text-align:center;margin-top:20px;padding-top:15px;border-top:1px dashed #ccc"><p style="font-weight:bold">رمز الفاتورة الإلكترونية</p><div id="print-qrcode-container" style="display:inline-block"></div></div>' +
        '<script>window.onload=function(){try{var c=document.getElementById("print-qrcode-container");if(c&&typeof QRCode!=="undefined"){c.innerHTML="";new QRCode(c,{text:"' + qrBase64 + '",width:150,height:150,colorDark:"#000000",colorLight:"#ffffff",correctLevel:QRCode.CorrectLevel.M});}}catch(e){}window.print();};<\/script></body></html>';
    printWindow.document.write(html);
    printWindow.document.close();
}
\`\`\`

**تنبيه محاسبي:** قيمة المتبقي المعروضة بجمع \`qty المتبقية × unit_price\` قيمة توضيحية قبل الخصومات العامة؛ لا تستخدمها بدل \`orders.total_amount\` أو بدل أي Ledger. الإجمالي النهائي في التفاصيل والطباعة يؤخذ من رأس الأوردر المركزي. إذا كان نظام الخصومات/الضريبة يملك عقدًا آخر في المصدر، يجب الحفاظ عليه عند الدمج وعدم استنتاج تسوية مالية من عدد الوحدات وحده.

## 5. ما لا يتغير في Production
- لا تعديل RPC أو ACL؛ الحارس المركزي في Production يمنع مصادر POS/المجهولة من ضم الرانشيت.
- لا توسيع RLS لجدول \`users\` من أجل اسم المنشئ؛ الجدول يعرض \`created_by\` نفسه كمعرف موثوق.
- لا إنشاء Edge Function جديدة.
- لا تغيير في \`ORD-1006\` ولا إنشاء Fixture في Production.
- لا تعديل \`main.html\` من المساعد؛ المالك يطبق الـOwner Patch أعلاه.

## 6. اختبار المالك بعد الدمج والنشر
1. \`ORD-1006\`: يجب أن يظهر المصدر POS، المنشئ \`cashier@rawaea.com\`، الحالة \`Partially Returned\`، الإجمالي النهائي 135.00، والأصلي 185.00 في التفاصيل إن أُضيف عرض الإجمالي الأصلي.
2. عدّ الأصناف يجب أن يساوي 1، لا 2، لأن سطر item 1001 مرتجع بالكامل وسطر item 1003 ما زال متبقيًا.
3. checkbox الخاص بـPOS معطل؛ تحديد الكل لا يحدده. مصدر \`order-taker\` المؤهل والحالة \`Confirmed/Pending\` وغير المرتبط برانشيت يظل قابلًا للاختيار.
4. Realtime بعد تغير \`qty_returned\` يحدّث عدّ الأصناف ولا يعيده إلى العدد الأصلي.
5. التفاصيل والطباعة تعرض الأصلي/المرتجع/المتبقي والملاحظة؛ الإجمالي النهائي يطابق \`orders.total_amount\`.
6. اختبر الفلاتر والفرز، تأكيد/حذف، إنشاء رانشيت/ضم، وعزل الشركة.
7. بعد النشر، سجّل SHA للملف المخدوم واختبر المتصفح والـConsole/Network. طلبات القراءة الحالية HTTP 200 لا تكفي لإثبات نشر الـpatch.

## SELF-AUDIT FINAL

- **What I Proved:** النص الحي الحالي، SHA، أرقام الأسطر، عيوب عدّ التفاصيل/الجدول/التفاصيل/الطباعة، حالة Production لـORD-1006، تعريفات RPC وACL، وسياسات RLS.
- **What I Did Not Prove:** نشر واجهة بعد التعديل أو Browser E2E؛ لم يجر المالك الدمج بعد.
- **What I Fixed:** لا تغيير مباشر في ملفات الواجهة أو Production؛ جهزت Owner Patch دقيقًا من المصدر الحي، ولم أعدّل Core الصحيح.
- **What I Initially Missed:** النسخة الحية لا تستخدم \`loadData()\` أو \`refreshRealtimeChannel()\` منفصلتين؛ التحميل داخل \`render()\`، لذا كانت تواقيع snapshot القديمة غير مطابقة.
- **What Could Still Be Wrong:** عقد الخصومات/الضريبة في الطباعة يجب أن يطابق إعدادات المحاسبة قبل اعتبار الإخراج الضريبي مغلقًا؛ الواجهة لم تُنشر ولم تُختبر بعد الدمج.
- **Final Confidence:** 0.94 في تشخيص المصدر الحي وProduction Core؛ 0.00 في إثبات نشر patch غير مطبق.
- **Final Closure Status:** \`OWNER SURGICAL PATCH PREPARED / PRODUCTION CORE VERIFIED / OWNER MERGE + SERVED ARTIFACT + BROWSER E2E OPEN\`.
- **NEXT EXACT TASK:** طبّق عناصر A–H في الملف الحالي بعد مطابقة SHA \`4f94f9c6ebdde1b59632384628c72767d3bb950d\`; ثم انشر واختبر وفق القسم 6. لا تغيّر Production Core ما لم يظهر Defect جديد مثبت.
