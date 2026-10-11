# Report411 — تحقيق تكامل مرتجع POS مع أوردرات المبيعات في النظام الأم
**التاريخ:** 2026-10-11  
**المهمة:** تصحيح عدد الأصناف بعد المرتجع، تحديث الجدول لحظيًا، إظهار المصدر والمنشئ، وإظهار القيم النهائية في تفاصيل الأوردر دون تعديل الملف الأم أو تطبيق POS بواسطة المساعد.  
**Production:** Supabase project `fiilmooggumokxanwiyx`  
**Frontend:** `papamohammed77-glitch/erp-frontend`  
**حالة الملف الأم الحي:** تعذرت قراءة محتواه عبر GitHub connector؛ blob SHA الذي أعاده المصدر الحي `4f94f9c6ebdde1b59632384628c72767d3bb950d`، والمحتوى فارغ حتى مع طلب نطاقات أسطر. لذلك لا أدّعي مطابقة snapshot مع النص الحي، ولا أقدم هذا التقرير كأنه تعديل مطبق على الملف الحي.

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** عند إرجاع صنف من فاتورة POS، يجب أن يبقى سجل البيع الأصلي للتدقيق، بينما يعرض النظام عدد أسطر الأصناف ذات الكمية المتبقية، والكمية المرتجعة والمتبقية، والإجمالي النهائي المسجل في رأس الأوردر.
- **Architecture Understanding:** POS منفصل عن النظام الأم، لكن كليهما يقرأ/يكتب عقد الأوردر المركزي. مشكلة العدد والتفاصيل الظاهرة في snapshot هي مشكلة قراءة/عرض وتحديث مشتقات في `RW_Orders`، وليست مبررًا لإنشاء Edge Function أو تغيير Core.
- **Database Understanding:** Production يؤكد وجود `orders.source`, `orders.created_by`, `orders.total_amount`, `orders.original_total_amount`, وحقول التفاصيل `order_details.qty`, `qty_returned`, `line_amount`, `reason_return`.
- **Historical Understanding:** تمت مراجعة CURRENT_STATE.md، وReport408، وReport409، وReport410. عوملت التقارير كدلائل، ثم أُعيد فحص Production وGit في هذه الدورة.
- **Production Understanding:** استعلام مباشر في نفس الدورة أثبت أن `ORD-1006` حالتها `Partially Returned`، الإجمالي الحالي 135.00، الأصلي 185.00، صفا تفاصيل، الكمية الأصلية 2، المرتجع 1، والمتبقي 1.
- **Current Understanding:** snapshot `rawaie-erp-New/Current/PWA/main.html` blob `27b777528665dcc985809648f006452c861ae36e` يحتوي `RW_Orders` التي تعدّ كل تفاصيل الأوردر دون `qty_returned`، ويحدّث Realtime كائن رأس الأوردر فقط، ويعرض تفاصيل بالقيم الأصلية. هذا snapshot مرجع تاريخي/حالي للمستودع وليس إثباتًا أن الملف الأم المنشور مطابق له.
- **Execution Confidence:** مرتفع في عقد بيانات Production وسبب الخلل الظاهر في snapshot؛ غير كافٍ لإثبات أن النص الحي للملف الأم يطابق snapshot أو أن الإصلاح منشور.

### Evidence snapshot

1. Live Production order query:
   - `ORD-1006`: source=`pos`, created_by=`cashier@rawaea.com`, status=`Partially Returned`, total=`135.00`, company=`00000000-0000-0000-0000-000000000001`, branch=`a38332b6-6cea-480a-ada1-6eb6ab0590db`.
   - details: 2 rows; original quantity sum 2; returned quantity sum 1; remaining quantity sum 1.
2. Production RPC `public.get_pos_invoice_data(text,text)`:
   - SECURITY DEFINER = true; `search_path=""`.
   - `anon EXECUTE=false`, `authenticated EXECUTE=true`, `service_role EXECUTE=true`.
   - No RPC/ACL/schema change was warranted for the display defect.
3. Production source distribution query returned currently observed values `pos` and `order-taker`. Other source labels below are defensive display mapping for known source names requested by the owner, not a claim that Production currently contains those values.
4. Production Edge list and historical checkpoint show `complete-return v26` and `save-sales-invoice v18` active with `verify_jwt=true` in the latest prior verified snapshot. No Edge was deployed in this cycle.
5. Current snapshot function positions are in `Current/PWA/main.html` around lines 2327–2465. Live `erp-frontend/companies/company-1/main.html` fetch returned empty content for the same range; exact live source remains unverified.

## Root cause

في snapshot المرجعي توجد أربعة عيوب عرض/تزامن مترابطة:

1. `loadData()` يقرأ `order_id,item_code` فقط ويعد كل صف؛ لا يقرأ `qty_returned` ولا يستبعد الصنف الذي أصبح المتبقي منه صفرًا.
2. `refreshRealtimeChannel()` يحدّث رأس الأوردر في الذاكرة، لكنه لا يعيد تحميل تفاصيله ولا يعيد حساب `itemsCount` المشتق من `order_details`.
3. `_showDetails(code)` يعرض `qty` و`line_amount` الأصليين ويشتق إجماليًا قد يختلف عن `orders.total_amount`.
4. جدول أوردرات المبيعات في snapshot لا يعرض `source` أو `created_by` رغم توفرهما في جدول `orders`.

لا يوجد Defect مثبت في بيانات `ORD-1006` أو في RPC القراءة يبرر تعديل Production SQL أو Edge لإصلاح هذه المشكلة.

## التعديل الجراحي للمالك فقط

**لا تعدّل `main.html` من خلال المساعد.** نفّذ كل استبدال أدناه فقط بعد فتح الملف الحي ومقارنة الدالة/المقطع الفعلي مع snapshot. إذا اختلفت البنية أو الأحداث، ادمج التغيير في البنية الحية بدل استبدال دالة مختلفة.

### 1. الملف والدوال

- الملف: `erp-frontend/companies/company-1/main.html`
- الوحدة: `RW_Orders`
- العناصر: `loadData()`, `refreshRealtimeChannel()`, مقطع رأس الجدول، `_renderTable(rows)`, `_showDetails(code)`.
- المرجع: `rawaie-erp-New/Current/PWA/main.html`, blob `27b777528665dcc985809648f006452c861ae36e`.
- SHA للملف الأم الحي المرصود: `4f94f9c6ebdde1b59632384628c72767d3bb950d` (المحتوى لم يُسترجع؛ لا يُدّعى أن النص أدناه مطابق حرفيًا له).

### 2. استبدال كامل `async function loadData()`

ابحث داخل `RW_Orders` عن `async function loadData()` واستبدل الدالة كاملة:

```javascript
async function loadData() {
    var companyId = getCompanyId();
    var ordersRes = await sb.from('orders')
        .select('*, runsheets(runsheet_code)')
        .eq('company_id', companyId)
        .order('order_date', { ascending: false })
        .order('order_code', { ascending: true });
    if (ordersRes.error) throw ordersRes.error;

    var rows = ordersRes.data || [];
    if (!rows.length) return [];

    var orderIds = rows.map(function (o) { return o.id; }).filter(Boolean);
    var detailsRes = await sb.from('order_details')
        .select('order_id, item_code, qty, qty_returned')
        .in('order_id', orderIds);
    if (detailsRes.error) throw detailsRes.error;

    var counts = {};
    (detailsRes.data || []).forEach(function (d) {
        if (!d.order_id) return;
        var originalQty = Math.max(0, Number(d.qty) || 0);
        var returnedQty = Math.min(originalQty, Math.max(0, Number(d.qty_returned) || 0));
        if (originalQty - returnedQty > 0) {
            counts[d.order_id] = (counts[d.order_id] || 0) + 1;
        }
    });

    return rows.map(function (o) {
        o.itemsCount = counts[o.id] || 0;
        o._runsheetCode = o.runsheets && o.runsheets.runsheet_code
            ? o.runsheets.runsheet_code
            : null;
        return o;
    });
}
```

### 3. استبدال كامل `async function refreshRealtimeChannel()`

ابحث عن توقيع الدالة داخل `RW_Orders` واستبدلها كاملة:

```javascript
async function refreshRealtimeChannel() {
    if (ordersRealtimeChannel) {
        try {
            await sb.removeChannel(ordersRealtimeChannel);
        } catch (e) {
            console.warn(e);
        }
        ordersRealtimeChannel = null;
    }

    var companyId = getCompanyId();
    ordersRealtimeChannel = sb.channel('orders-realtime-' + companyId)
        .on('postgres_changes', {
            event: '*',
            schema: 'public',
            table: 'orders',
            filter: 'company_id=eq.' + companyId
        }, function () {
            // itemsCount is derived from order_details. Refresh the tenant-scoped
            // datasets when the order header changes after a return.
            _refreshData().catch(function (e) {
                console.warn('Orders/return realtime refresh failed:', e);
            });
        })
        .subscribe();
}
```

لا تضف اشتراكًا غير مقيّد على `order_details`؛ التحديث يعيد قراءة رأس الأوردر وتفاصيله ضمن الشركة الحالية عبر `loadData()`.

### 4. إضافة عمودي المصدر والمنشئ إلى رأس الجدول

داخل `render()` في `RW_Orders`، ابحث عن هذا المقطع المحدد:

```javascript
'<th class="p-3 text-center cursor-pointer text-xs font-bold uppercase" onclick="RW_Orders._sort(\'customer_name\')">العميل والمنطقة <i class="fa-solid fa-sort"></i></th>' +
'<th class="p-3 text-center cursor-pointer text-xs font-bold uppercase" onclick="RW_Orders._sort(\'itemsCount\')">عدد الأصناف <i class="fa-solid fa-sort"></i></th>' +
```

استبدله بهذا المقطع:

```javascript
'<th class="p-3 text-center cursor-pointer text-xs font-bold uppercase" onclick="RW_Orders._sort(\'customer_name\')">العميل والمنطقة <i class="fa-solid fa-sort"></i></th>' +
'<th class="p-3 text-center cursor-pointer text-xs font-bold uppercase" onclick="RW_Orders._sort(\'source\')">المصدر <i class="fa-solid fa-sort"></i></th>' +
'<th class="p-3 text-center cursor-pointer text-xs font-bold uppercase" onclick="RW_Orders._sort(\'created_by\')">المنشئ / الحساب <i class="fa-solid fa-sort"></i></th>' +
'<th class="p-3 text-center cursor-pointer text-xs font-bold uppercase" onclick="RW_Orders._sort(\'itemsCount\')">عدد الأصناف <i class="fa-solid fa-sort"></i></th>' +
```

### 5. استبدال كامل `function _renderTable(rows)`

ابحث داخل `RW_Orders` عن `function _renderTable(rows)` واستبدل الدالة كاملة:

```javascript
function _renderTable(rows) {
    var tbody = byLocalId('orders-table-body');
    if (!tbody) return;

    if (!rows || !rows.length) {
        safeHTML(tbody, '<tr><td colspan="11" class="text-center py-8 text-gray-500">لا توجد أوردرات</td></tr>');
        var pc = byLocalId('orders-table-body-controls');
        if (pc) safeHTML(pc, '');
        return;
    }

    var checkAll = byLocalId('check-all');
    if (checkAll) checkAll.checked = false;

    RW_Table.paginate('orders-table-body', rows, 1, 50, function (o) {
        var actions = '';
        if (o.order_status === 'Draft' || o.order_status === 'Pending') {
            actions += '<button onclick="event.stopPropagation();RW_Orders._confirm(\'' + escAttr(o.order_code) + '\')" class="text-green-600 mx-1" title="تأكيد"><i class="fa-solid fa-check-circle"></i></button>';
        }
        var canDelete = (o.order_status === 'Draft' || o.order_status === 'Confirmed' || o.order_status === 'Pending') && !o.runsheet_id;
        if (canDelete) {
            actions += '<button onclick="event.stopPropagation();RW_Orders._delete(\'' + escAttr(o.order_code) + '\')" class="text-red-500 mx-1" title="حذف"><i class="fa-solid fa-trash-can"></i></button>';
        }

        var sourceRaw = String(o.source || '').trim();
        var sourceKey = sourceRaw.toLowerCase();
        var sourceLabels = {
            'pos': 'كاشير',
            'telesales': 'تلي سيلز',
            'order-taker': 'أوردر تيكر',
            'order_taker': 'أوردر تيكر',
            'online-store': 'المتجر الإلكتروني',
            'online_store': 'المتجر الإلكتروني'
        };
        var sourceLabel = sourceLabels[sourceKey] || sourceRaw || 'غير محدد';
        var creatorLabel = String(o.created_by || '').trim() || 'غير محدد';
        var sourceTitle = sourceRaw ? ' title="' + escAttr(sourceRaw) + '"' : '';
        var creatorTitle = creatorLabel !== 'غير محدد' ? ' title="' + escAttr(creatorLabel) + '"' : '';

        return '<tr class="border-b hover:bg-gray-50 cursor-pointer" onclick="RW_Orders._showDetails(\'' + escAttr(o.order_code) + '\')">' +
            '<td class="p-3 text-center" onclick="event.stopPropagation()"><input type="checkbox" class="order-checkbox" data-id="' + escAttr(o.order_code) + '"></td>' +
            '<td class="p-3 text-center font-bold text-blue-600">' + esc(o.order_code) + '</td>' +
            '<td class="p-3 text-center">' + esc(formatDate(o.order_date)) + '</td>' +
            '<td class="p-3 text-center"><p class="font-semibold">' + esc(o.customer_name || '—') + '</p><p class="text-xs text-gray-500">' + esc(o.area || '') + '</p></td>' +
            '<td class="p-3 text-center"><span class="inline-flex px-2 py-1 rounded bg-slate-50 text-slate-700 text-xs"' + sourceTitle + '>' + esc(sourceLabel) + '</span></td>' +
            '<td class="p-3 text-center text-xs break-all"' + creatorTitle + '>' + esc(creatorLabel) + '</td>' +
            '<td class="p-3 text-center font-bold">' + formatNumber(o.itemsCount) + '</td>' +
            '<td class="p-3 text-center font-bold">' + formatNumber(o.total_amount) + ' EGP</td>' +
            '<td class="p-3 text-center"><span class="px-2 py-1 rounded-full text-xs font-semibold ' + statusClassOrder(o.order_status) + '">' + esc(o.order_status) + '</span></td>' +
            '<td class="p-3 text-center">' + esc(o._runsheetCode || '---') + '</td>' +
            '<td class="p-3 text-center">' + actions + '</td>' +
        '</tr>';
    });
}
```

**مهم:** عدد الأعمدة أصبح 11 بدل 9. داخل `RW_Orders.render()` غيّر فقط `colspan="9"` في رسالتي التحميل والخطأ إلى `colspan="11"`. لا تنفذ استبدالًا عامًا في بقية الملف.

### 6. تفاصيل الأوردر النهائية

استبدل `async function _showDetails(code)` بالنسخة الكاملة الواردة في:
[Report408 — OWNER CHANGESET](Report408_POS_RETURN_STATE_DETAILS_AND_OWNER_CHANGESET_20261011.md)، القسم `4. OWNER CHANGESET — النظام الأم`، الجزء `B. استبدال async function _showDetails(code)`.

النسخة المرجعية تعرض:
- الكمية الأصلية، المرتجعة، والمتبقية لكل صنف.
- قيمة الكمية المتبقية وملاحظة المرتجع.
- عدد الأسطر الأصلية، وعدد الأسطر التي بها مرتجع، والأسطر المتبقية.
- الإجمالي النهائي من `orders.total_amount` وليس مجموع `line_amount` الأصلي.
- أزرار التأكيد والحذف والطباعة الموجودة في العقد الحالي.

لا تستبدل الدالة قبل مطابقة النص الحي والتأكد من وجود الدوال التابعة `showLoader`, `hideLoader`, `getCompanyId`, `esc`, `formatNumber`, `notifyError`, `byLocalId`, و`_printOrder`.

### 7. حدود التغيير

- لا تعدّل `main.html` أو `pos.html) من خلال المساعد.
- لا تعدّل `qty` الأصلية ولا تحذف تفاصيل المرتجع.
- لا تغيّر Production SQL/RPC/ACL أو Edge؛ الأدلة الحالية لا تبرر ذلك.
- لا تنشئ Edge Function جديدة.
- لا تعتبر هذه التعديلات مطبقة أو منشورة؛ هذا changeset للمالك لأن الملف الأم حساس ومحتواه الحي لم يُسترجع.
- الطباعة في snapshot ما زالت تحتاج دمجًا مستقلًا لعرض المرتجع والمتبقي؛ لا يُدّعى أنها أُصلحت في هذه الدورة.

## الاختبار بعد الدمج والنشر

استخدم `ORD-1006` كاختبار قراءة فقط؛ لا تُجرِ مرتجعًا إضافيًا على فاتورة حقيقية.

1. جدول أوردرات المبيعات يعرض `المصدر=كاشير` و`المنشئ= cash​ier@rawaea.com` لهذه الفاتورة، وعدد الأصناف المتبقية = 1.
2. إعادة تحميل الصفحة ثم فتح الأوردر يعرض سطر `1001`: أصلي 1، مرتجع 1، متبقي 0؛ وسطر `1003`: أصلي 1، مرتجع 0، متبقي 1.
3. الإجمالي النهائي في التفاصيل = 135.00 EGP، وليس 185.00 EGP.
4. بعد تنفيذ مرتجع جديد في fixture معزول ومعتمد فقط، يتحول رأس الأوردر وتحديث عدد الأصناف دون إعادة تحميل يدوي؛ لا تستخدم فاتورة إنتاج حقيقية لتجربة mutation.
5. اختبر المصدر `order-taker`، والمنشئ، والفلاتر، والفرز، والتحديد، وإنشاء/ضم الرانشيت، والحذف/التأكيد للأوردرات المسموح بها.
6. اختبر الطباعة بعد إضافة عرض المرتجع؛ هذه النقطة تظل مفتوحة إلى حين توحيد الطباعة.
7. افحص Console/Network ونسخة الاستضافة وService Worker بعد النشر، ثم أعد استعلام Production لإثبات عدم وجود test residue.

## Production actions / نتائج هذه الدورة

- أُعيد فحص Production SQL وبيانات `ORD-1006` وRPC ACL.
- لم يُنفّذ أي تغيير في قاعدة البيانات أو Edge أو بيانات الأعمال؛ التعديل اللازم عرضي/Frontend، وأي تغيير SQL سيكون بلا مبرر.
- لم تُنشأ Fixtures ولم تتغير الفاتورة أو المخزون أو الخزينة.
- لم يتم تعديل `main.html` أو `pos.html`.
- لم يُثبت نشر واجهة أو Browser/HTTP E2E؛ لذلك الحالة ليست Closed.

## SELF-AUDIT FINAL

- **What I Proved:** Production يعيد الحالة النهائية الصحيحة للفاتورة؛ الحقول اللازمة موجودة؛ ACL للـRPC صحيحة؛ snapshot يثبت خلل حساب العدد وتحديث Realtime وعرض التفاصيل؛ المصدر والمنشئ متاحان في رأس الأوردر.
- **What I Did Not Prove:** النص الكامل للملف الأم الحي؛ نشر واجهة POS الحالية؛ نشر changeset النظام الأم؛ browser E2E بعد الدمج؛ اتساق الطباعة.
- **What I Fixed:** لم أغير بيانات صحيحة أو backend بلا داعٍ. أعددت changeset جراحيًا محددًا يشمل حساب العدد، Realtime، المصدر، المنشئ، وتفاصيل المرتجع.
- **What I Initially Missed:** إصلاح العدد دون إعادة تحميل التفاصيل لا يكفي؛ وكذلك يجب تعديل عدد الأعمدة/colspan عند إضافة المصدر والمنشئ.
- **What Could Still Be Wrong:** اختلاف الدوال الحية عن snapshot، عدم النشر أو وجود Service Worker قديم، وعدم اكتمال الطباعة.
- **Final Confidence:** مرتفع في تشخيص عقد البيانات وProduction؛ متوسط في انطباق patch على النص الحي؛ غير مثبت في النشر وE2E.
- **Final Closure Status:** `OWNER SURGICAL PATCH READY / PRODUCTION READ PATH VERIFIED / LIVE MAIN SOURCE PARITY UNVERIFIED / DEPLOYMENT AND BROWSER E2E OPEN / PRINT CONSISTENCY OPEN / NOT CLOSED`.

## تعليمات الاستئناف

1. ابدأ بفتح النص الحي لـ`erp-frontend/companies/company-1/main.html` من محرر GitHub أو من مسار النشر المعتمد؛ تحقق من SHA الحالي ومن التوقيعات الدقيقة قبل الدمج.
2. لا تنقل snapshot كله إلى الملف الحي ولا تستبدل دالة مختلفة.
3. طبّق الأجزاء 2–6 فقط بعد الدمج على النص الحي، ثم راجع الطباعة ضمن نفس capability.
4. انشر من مسار الاستضافة المعتمد وامسح/حدّث Service Worker حسب سياسة المشروع.
5. أعد اختبار `ORD-1006` قراءةً، واختبر mutation على fixture معزول فقط، ثم وثّق artifact المنشور ونتائج Browser/HTTP E2E في CURRENT_STATE.md.
