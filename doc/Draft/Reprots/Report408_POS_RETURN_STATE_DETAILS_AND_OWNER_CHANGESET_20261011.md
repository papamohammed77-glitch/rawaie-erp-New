# Report408 — معالجة عرض المرتجعات في POS والنظام الأم
**التاريخ:** 2026-10-11  
**النطاق:** عرض تفاصيل فاتورة POS في التطبيق المنفصل، وعدد الأصناف وتفاصيل الأوردر في النظام الأم بعد المرتجع.  
**قاعدة Production:** Supabase `fiilmooggumokxanwiyx`  
**مصدر POS الحي:** `papamohammed77-glitch/erp-frontend/companies/company-1/sales/pos.html`

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** يجب حفظ سطور الفاتورة الأصلية لأغراض التدقيق وعدم حذف الصنف أو تغيير هويته بسبب المرتجع؛ لكن العرض التشغيلي يجب أن يوضح الكمية المرتجعة والمتبقية والملاحظة، وأن يعرض الإجمالي الحالي المسجل.
- **Architecture Understanding:** واجهة POS تقرأ من `get_pos_invoice_data(text,text)`. عقد المرتجع الحالي يحدّث `order_details.qty_returned` وحالة/قيمة `orders`; لا يجوز تعديل كميات البيع الأصلية لإخفاء المرتجع.
- **Database Understanding:** Production schema يحتوي `orders.total_amount`, `orders.original_total_amount`, `order_details.qty`, `qty_returned`, `reason_return`, `notes`, `unit_price`. RPC القراءة الحالية تعيد `qty`, `qty_returned`, `qty_delivered`, `line_amount`.
- **Historical Understanding:** تمت مراجعة `CURRENT_STATE.md` وأحدث التقارير Report403 وReport407. تم التعامل مع التقارير كدلائل توجيهية ثم فحص المصدر الحي وProduction مباشرة.
- **Production Understanding:** فُحصت تعريفات الجداول وRPC مباشرة. بيانات Production لـ`ORD-1006` تثبت حالة `Partially Returned`, و`total_amount=135`, و`original_total_amount=185`; الصنف `1001` له `qty=1` و`qty_returned=1`, والصنف `1003` له `qty=1` و`qty_returned=0`. هذا مثال حي على أن قيمة/حالة رأس الأوردر تتغير بينما الكمية الأصلية تبقى محفوظة.
- **Current Understanding:** ملف POS الحي قبل التعديل كان blob `fc52e51c185d945bff1ebc1c55b76601410db824`. تمت قراءة `self._viewActiveInvoice` كاملة؛ كانت تعرض `det.qty` و`qty * unit_price` فقط ولا تعرض `qty_returned` أو الملاحظات.
- **Execution Confidence:** مرتفع لإصلاح عرض POS. متوسط لتشخيص مصدر خطأ النظام الأم من snapshot متاح؛ لا يجوز الادعاء بأن تغييرات النظام الأم قد طُبقت.

## 1. السبب الجذري المثبت

### POS
دالة `self._viewActiveInvoice(orderCode)` كانت تعرض الكمية الأصلية `det.qty` وقيمة السطر الأصلية `qty * unit_price`، رغم أن RPC تعيد `qty_returned`. لذلك كان رأس الفاتورة يعرض `orders.total_amount` الحالي بينما جدول التفاصيل يعرض الأصناف كما لو لم يقع مرتجع.

### النظام الأم
في snapshot المرجعي `rawaie-erp-New/Current/PWA/main.html` (blob `27b777528665dcc985809648f006452c861ae36e`):
- `RW_Orders.loadData()` تعدّ كل سجل في `order_details` كصنف، دون استبعاد السطور التي أصبحت كميتها المتبقية صفرًا بعد المرتجع.
- `RW_Orders._showDetails(code)` تجمع `line_amount` الأصلي وتعرض `qty` الأصلي، ثم تشتق الإجمالي من مجموع السطور + رسوم التوصيل بدل اعتماد `orders.total_amount` كقيمة الرأس النهائية.
- هذه الآلية تفسر التناقض الذي وصفه المالك. **لكن ملف النظام الأم الحي** `erp-frontend/companies/company-1/main.html` له blob SHA `4f94f9c6ebdde1b59632384628c72767d3bb950d`، وأداة GitHub أعادت محتوى فارغًا حتى عند طلب نطاقات أسطر محددة؛ لذلك لم أستبدل الملف الحي ولا أزعم أن snapshot المرجعي يطابقه byte-for-byte.

## 2. التغيير المنفذ — POS

- تم استبدال الدالة الموجودة `self._viewActiveInvoice` في المصدر الحي، دون إنشاء دالة مكررة.
- يعرض الجدول الآن: الصنف، الكمية الأصلية، المرتجع، المتبقي، السعر، قيمة المتبقي، والملاحظات.
- تظهر `مرتجع جزئي` أو `مرتجع بالكامل` تلقائيًا بناءً على `qty_returned`.
- تبقى الكمية الأصلية محفوظة في قاعدة البيانات، ويظل الإجمالي النهائي أعلى النافذة مأخوذًا من `order.total_amount`.
- لم تتغير RPC أو الجداول أو البيانات أو حركة المخزون في هذه الجراحة.

### Git evidence
- Commit: `12e68f21eca5be19beb7e9b678a1917dc1d40d71`
- POS blob بعد التعديل: `0160f7cf9c4f194d954d2c7498d91fc639a5f419`
- رابط الملف: https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/sales/pos.html
- رابط الـcommit: https://github.com/papamohammed77-glitch/erp-frontend/commit/12e68f21eca5be19beb7e9b678a1917dc1d40d71

## 3. التحقق

- أُعيد جلب ملف POS بعد الكتابة وتأكد وجود حقول الكمية المرتجعة والمتبقية وملاحظات المرتجع.
- عدد تعريفات `self._viewActiveInvoice` بعد التعديل: تعريف واحد.
- بيانات Production الحالية تثبت وجود حالة جزئية فعلية `ORD-1006` بالفرق بين الإجمالي الأصلي والحالي.
- **لم يثبت** نشر واجهة الويب إلى الاستضافة أو تشغيل Browser/HTTP E2E بعد هذا الـcommit؛ لذلك الحالة هي `GIT COMMITTED / SOURCE VERIFIED / DEPLOYMENT UNVERIFIED`, وليست Production UI Closed.
- لم تتغير أي بيانات أعمال، ولم تنشأ Fixtures.

## 4. OWNER CHANGESET — النظام الأم

**المالك هو من يدمج تعديلات `main.html`. لا تعدّل الملف الحي مباشرة.**

### مصدر مرجعي للوظائف
- snapshot: `rawaie-erp-New/Current/PWA/main.html`
- blob: `27b777528665dcc985809648f006452c861ae36e`
- الوظيفة الأولى: `RW_Orders.loadData()`
- الوظيفة الثانية: `RW_Orders._showDetails(code)`

**تحذير مزامنة مهم:** لا تستبدل وظائف النظام الأم قبل مقارنة النص الحي الحالي؛ blob المصدر الحي `4f94f9c6ebdde1b59632384628c72767d3bb950d` لم يُرجع محتوى عبر أداة GitHub. الكود أدناه بديل مرجعي كامل مستخرج من العقد والـsnapshot، وليس ادعاءً بأننا قرأنا كل سطر من الملف الحي.

### A. استبدال `async function loadData()` داخل `RW_Orders`

احذف تعريف `loadData()` الحالي كاملًا واستبدله بالتالي:

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
        var remainingQty = Math.max(0, originalQty - returnedQty);
        if (remainingQty > 0) counts[d.order_id] = (counts[d.order_id] || 0) + 1;
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

الأثر: يحسب عدد أسطر الأصناف المتبقية فقط (`qty - qty_returned > 0`)؛ ولا يحذف أو يعدل أي سطر بيع أصلي.

### B. استبدال `async function _showDetails(code)` داخل `RW_Orders`

احذف تعريف `_showDetails(code)` الحالي كاملًا واستبدله بالتالي:

```javascript
async function _showDetails(code) {
    showLoader('جاري تحميل التفاصيل...');
    try {
        var companyId = getCompanyId();
        var oRes = await sb.from('orders').select('*')
            .eq('company_id', companyId).eq('order_code', code).maybeSingle();
        if (oRes.error) throw oRes.error;
        var order = oRes.data;
        if (!order) throw new Error('الأوردر غير موجود');

        var iRes = await sb.from('order_details').select('*')
            .eq('order_id', order.id).order('created_at', { ascending: true });
        if (iRes.error) throw iRes.error;
        var items = iRes.data || [];
        var originalItemsTotal = 0;
        var remainingItemsTotal = 0;
        var returnedLineCount = 0;
        var remainingLineCount = 0;
        var itemsHtml = '';

        items.forEach(function (it) {
            var originalQty = Math.max(0, Number(it.qty) || 0);
            var returnedQty = Math.min(originalQty, Math.max(0, Number(it.qty_returned) || 0));
            var remainingQty = Math.max(0, originalQty - returnedQty);
            var unitPrice = Math.max(0, Number(it.unit_price) || 0);
            var originalLineValue = originalQty * unitPrice;
            var remainingLineValue = remainingQty * unitPrice;
            var hasReturn = returnedQty > 0;
            var fullyReturned = originalQty > 0 && remainingQty === 0;
            var note = String(it.reason_return || '').trim();
            if (!note && fullyReturned) note = 'مرتجع بالكامل';
            else if (!note && hasReturn) note = 'مرتجع جزئي';
            else if (!note) note = String(it.notes || '').trim() || '—';

            originalItemsTotal += originalLineValue;
            remainingItemsTotal += remainingLineValue;
            if (hasReturn) returnedLineCount++;
            if (remainingQty > 0) remainingLineCount++;

            itemsHtml += '<tr class="' + (fullyReturned ? 'bg-red-50' : (hasReturn ? 'bg-amber-50' : '')) + '">' +
                '<td class="p-2 font-semibold">' + esc(it.item_name || it.item_code || '') + '</td>' +
                '<td class="p-2 text-center">' + esc(it.unit || 'حبة') + '</td>' +
                '<td class="p-2 text-center">' + formatNumber(originalQty) + '</td>' +
                '<td class="p-2 text-center ' + (hasReturn ? 'text-red-600 font-bold' : '') + '">' + formatNumber(returnedQty) + '</td>' +
                '<td class="p-2 text-center font-bold">' + formatNumber(remainingQty) + '</td>' +
                '<td class="p-2 text-center">' + formatNumber(unitPrice) + '</td>' +
                '<td class="p-2 text-center font-bold">' + formatNumber(remainingLineValue) + '</td>' +
                '<td class="p-2 text-center ' + (hasReturn ? 'text-amber-700 font-bold' : 'text-gray-500') + '">' + esc(note) + '</td>' +
            '</tr>';
        });

        if (!itemsHtml) {
            itemsHtml = '<tr><td colspan="8" class="text-center py-4 text-gray-500">لا توجد أصناف مسجلة لهذا الأوردر</td></tr>';
        }

        var deliveryFee = Number(order.delivery_fee) || 0;
        var finalOrderTotal = Number(order.total_amount);
        if (!Number.isFinite(finalOrderTotal)) finalOrderTotal = remainingItemsTotal + deliveryFee;
        var warning = order.runsheet_id
            ? '<div class="bg-amber-50 border-r-4 border-amber-500 p-3 mb-4 rounded"><p class="text-amber-700 text-sm"><i class="fa-solid fa-link ml-2"></i> مرتبط بالرانشيت: <strong>' + esc(order.runsheet_id) + '</strong></p></div>'
            : '';
        var buttons = '';
        if ((order.order_status === 'Draft' || order.order_status === 'Pending') && !order.runsheet_id) {
            buttons += '<button id="btn-confirm-order-modal" class="bg-blue-600 text-white px-6 py-2 rounded-xl font-bold shadow"><i class="fa-solid fa-check-circle ml-2"></i> تأكيد الأوردر</button>';
        }
        if (['Draft', 'Confirmed', 'Pending'].indexOf(order.order_status) !== -1 && !order.runsheet_id) {
            buttons += '<button id="btn-delete-order-modal" class="bg-red-600 text-white px-6 py-2 rounded-xl font-bold shadow"><i class="fa-solid fa-trash ml-2"></i> حذف الأوردر</button>';
        }
        buttons += '<button id="btn-print-order-modal" class="bg-emerald-600 text-white px-6 py-2 rounded-xl font-bold shadow"><i class="fa-solid fa-print ml-2"></i> طباعة الفاتورة</button>';

        var html = '<div class="text-right">' + warning +
            '<div class="grid grid-cols-2 gap-4 bg-gray-50 p-4 rounded-2xl mb-4">' +
                '<div><p><b>العميل:</b> ' + esc(order.customer_name || '—') + '</p><p><b>المنطقة:</b> ' + esc(order.area || '—') + '</p></div>' +
                '<div><p><b>الحالة:</b> <span class="font-bold">' + esc(order.order_status || '—') + '</span></p><p><b>الرانشيت:</b> ' + esc(order.runsheet_id || '---') + '</p></div>' +
            '</div>' +
            '<div class="overflow-x-auto"><table class="w-full border text-sm"><thead class="bg-gray-100"><tr>' +
                '<th class="p-2">الصنف</th><th class="p-2 text-center">الوحدة</th>' +
                '<th class="p-2 text-center">الكمية الأصلية</th><th class="p-2 text-center">المرتجع</th>' +
                '<th class="p-2 text-center">المتبقي</th><th class="p-2 text-center">السعر</th>' +
                '<th class="p-2 text-center">قيمة المتبقي</th><th class="p-2 text-center">ملاحظات</th>' +
            '</tr></thead><tbody>' + itemsHtml + '</tbody></table></div>' +
            '<div class="text-xs text-gray-500 mt-2">عدد أسطر الفاتورة الأصلية: ' + formatNumber(items.length) +
                ' | أسطر بها مرتجع: ' + formatNumber(returnedLineCount) +
                ' | أسطر متبقية: ' + formatNumber(remainingLineCount) + '</div>' +
            '<div class="bg-gray-50 p-4 rounded-2xl mt-4">' +
                '<div class="flex justify-between mb-2"><span>قيمة الأصناف الأصلية:</span><span>' + formatNumber(originalItemsTotal) + ' EGP</span></div>' +
                '<div class="flex justify-between mb-2"><span>قيمة الأصناف المتبقية قبل الخصم العام:</span><span>' + formatNumber(remainingItemsTotal) + ' EGP</span></div>' +
                '<div class="flex justify-between mb-2"><span class="text-blue-600">رسوم التوصيل المسجلة:</span><span class="text-blue-600">' + formatNumber(deliveryFee) + ' EGP</span></div>' +
                '<div class="flex justify-between pt-2 border-t"><span class="font-bold">الإجمالي النهائي المسجل بالنظام:</span><span class="font-bold text-emerald-600 text-lg">' + formatNumber(finalOrderTotal) + ' EGP</span></div>' +
                '<p class="text-[10px] text-gray-500 mt-2">الكمية الأصلية محفوظة للتدقيق. الإجمالي النهائي مأخوذ من سجل الأوردر المركزي، ولا يُعاد اشتقاقه من تفاصيل الأصناف.</p>' +
            '</div><div class="flex justify-center gap-3 mt-6 pt-4 border-t">' + buttons + '</div></div>';

        Swal.fire({
            title: 'تفاصيل الأوردر: ' + esc(code),
            html: html,
            width: '1100px',
            showCloseButton: true,
            showConfirmButton: false,
            showCancelButton: true,
            cancelButtonText: 'إغلاق',
            didOpen: function () {
                var c = byLocalId('btn-confirm-order-modal');
                if (c) c.onclick = function () { Swal.close(); _confirmOrderFromDetails(code); };
                var d = byLocalId('btn-delete-order-modal');
                if (d) d.onclick = function () { Swal.close(); _delete(code); };
                var p = byLocalId('btn-print-order-modal');
                if (p) p.onclick = function () { _printOrder(code); };
            }
        });
    } catch (e) {
        notifyError(e, 'فشل تحميل التفاصيل');
    } finally {
        hideLoader();
    }
}
```

الأثر: يعرض الكمية الأصلية والمرتجعة والمتبقية والملاحظة وقيمة المتبقي، ويحافظ على السطور الأصلية، ويأخذ الإجمالي النهائي من `orders.total_amount` بدل إعادة اشتقاقه من `line_amount` الأصلي.

### C. ملاحظات التكامل
- لا تعدّل `order_details.qty` عند المرتجع.
- لا تحذف السطور المرتجعة من قاعدة البيانات؛ هذا يفقد أثر التدقيق.
- لا تحسب رأس الأوردر من مجموع `line_amount` الأصلي.
- طباعة الأوردر في `_buildPrintWindow` ما زالت بحاجة إلى مراجعة متزامنة قبل اعتماد تجربة موحدة للطباعة؛ لم أغيرها لأن التعديل المطلوب الآن هو عرض الجدول والتفاصيل، ولأن الملف الحي الكبير لم يمكن قراءته من الأداة.

## 5. SELF-AUDIT FINAL

- **What I Proved:** Production يحفظ `qty` الأصلية و`qty_returned` منفصلة؛ رأس `ORD-1006` الحالي 135 مقابل الأصلي 185؛ RPC ترجع `qty_returned`; مصدر POS السابق تجاهل هذا الحقل.
- **What I Did Not Prove:** نشر واجهة POS فعليًا، HTTP/Browser E2E، أو أن snapshot النظام الأم يطابق blob المصدر الحي.
- **What I Fixed:** تحديث عرض تفاصيل فاتورة POS إلى المرتجع والمتبقي والملاحظات؛ commit موجود في GitHub.
- **What I Initially Missed:** عرض الكمية الأصلية دون عمود المرتجع يجعل جدول التفاصيل يبدو غير متسق مع رأس الفاتورة.
- **What Could Still Be Wrong:** قد تكون الاستضافة تقدم artifact أقدم؛ ويجب مزامنة `main.html` يدويًا من المالك بعد مقارنة المصدر الحي.
- **Final Confidence:** POS source fix 0.96؛ deployment/runtime 0.40؛ parent app owner changeset 0.75 until compared against live file.
- **Final Closure Status:** `POS SOURCE PATCH COMMITTED / SOURCE VERIFIED / PRODUCTION DEPLOYMENT UNVERIFIED / MAIN APP OWNER CHANGESET PREPARED`.

## نقطة الاستكمال الدقيقة
1. نشر commit `12e68f21eca5be19beb7e9b678a1917dc1d40d71` عبر pipeline المعتمد ثم اختبار فاتورة جزئية المرتجع مثل `ORD-1006` من متصفح فعلي.
2. مقارنة دالتي `RW_Orders.loadData` و`RW_Orders._showDetails` في `erp-frontend/companies/company-1/main.html` بعد إتاحة النص الحي، ثم دمج Owner Changeset.
3. بعد ذلك اختبر جدول الأوردرات والتفاصيل والطباعة وبيانات الشركة/الفرع، وتأكد من أن القيمة النهائية تتطابق مع `orders.total_amount`.
