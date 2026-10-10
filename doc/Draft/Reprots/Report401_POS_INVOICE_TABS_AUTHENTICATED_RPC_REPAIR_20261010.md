# Report401 — إصلاح تبويبي فواتير اليوم والمرتجع في POS
**التاريخ:** 2026-10-10  
**Production:** Supabase project `fiilmooggumokxanwiyx`  
**Current Git:** `papamohammed77-glitch/erp-frontend`  
**الحدود:** لم يتم تعديل `main.html` أو `companies/company-1/sales/pos.html`. نُشر عقد القراءة في Production ووُثقت الجراحة الأمامية للمالك.

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** فواتير اليوم تعرض فواتير POS التي أنشأها الكاشير الحالي في يوم العمل المحلي. المرتجع يحتاج قراءة فاتورة POS وتفاصيلها والكميات المرتجعة سابقًا قبل استدعاء Edge القائمة `complete-return`.
- **Architecture Understanding:** POS ← authenticated RPC ← PostgreSQL. لا حاجة إلى Edge Function جديدة ولا إلى توسيع RLS على جداول الأعمال.
- **Database Understanding:** سياسات `orders_select_current_tenant` و`order_details_select_current_tenant` لا تمنح دور `pos` القراءة المباشرة.
- **Historical Understanding:** راجعت Report398 وReport400 كمرجعين، ثم قارنت Current Git وProduction schema وRLS وlogs. لم أكرر إصلاحات bootstrap والبحث الموجودة.
- **Production Understanding:** `get_pos_branches()` و`get_pos_bootstrap_data()` موجودتان. نُشرت الآن `get_pos_invoice_data(text,text)` واختُبرت بهوية الكاشير داخل DB.
- **Current Understanding:** أحدث commit هو `559a2fe399ec218cb1ab7b1b32ec13bc56b661aa` بتاريخ `2026-10-10T16:23:10Z`. Blob الحالي لملف POS: `49eae1c7898aca76d0deecfa74a55fc31808d149`، بطول 88,092 حرفًا و1,363 سطرًا.
- **Execution Confidence:** مرتفع في تشخيص RLS وRPC/ACL ومحاكاة DB؛ لم تُختبر الواجهة بعد تطبيق المالك للجراحة.

### Confirmed Facts

1. مصدر POS الحالي يحتوي بالفعل على bootstrap RPC، وfast-selling cache، وبحث يشمل `search_label` والتصنيف والفرع، و`operation_id` للبيع.
2. سجل Production عند `2026-10-10T01:07:32.735Z` أظهر طلب `GET /rest/v1/orders?select=*&created_by=eq.cashier%40rawaea.com&order_date=eq.2026-10-10&order=order_date.desc` بنتيجة HTTP 200 وحجم body يساوي 2 بايت؛ أي نتيجة فارغة بسبب RLS، وليس دليلًا على عدم وجود فاتورة.
3. توجد فاتورة POS حقيقية `ORD-1004` للكاشير `cashier@rawaea.com` بتاريخ `2026-10-10`، حالتها `Invoiced` وإجماليها 275 وثلاثة أسطر. لم أُنشئ بيانات تجريبية جديدة.
4. واجهة المرتجع الحالية تسجل المرتجع والإشعار الدائن فقط، ولا تنفذ ردًا نقديًا أو ردًا للبطاقة.
5. جدول `treasury` الحالي لا يثبت وجود درج/وردية مستقلة لكل كاشير. لم أختلق عقدًا محاسبيًا غير موجود.

### Unknowns / Conflicts / Unverified Claims

- **Resolved:** فواتير اليوم فارغة لأن RLS تحجب القراءة المباشرة بصمت.
- **Resolved:** البحث عن فاتورة المرتجع وقراءة تفاصيلها يستخدمان الاستعلامات المباشرة المحجوبة نفسها.
- **Unverified:** Browser/HTTP E2E بعد تطبيق الجراحة الأمامية ونشرها.
- **Business Contract Debt:** رد النقد/البطاقة من درج مستقل للكاشير غير مثبت في Production؛ لا يجوز عرض الإشعار الدائن على أنه رد نقدي مكتمل.

## 1. Production repair

**Migration file:** `supabase/migrations/20261010_pos_authenticated_invoice_read_rpc.sql`  
**Repository commit:** `29382a0fa060013285f6acba90869218417899f1`  
**Production migration:** `20261010164215 / pos_authenticated_invoice_read_rpc_20261010`

`public.get_pos_invoice_data(p_action text, p_order_code text DEFAULT NULL) RETURNS jsonb`:
- `SECURITY DEFINER` و`search_path=''`.
- تتحقق من `auth.uid()` وصلاحية `pos` وسياق الشركة.
- تقصر النتائج على الفروع التي تعيدها `get_pos_branches()`.
- `today` يعيد فواتير المصدر `pos` للكاشير المصادق عليه فقط حسب يوم العمل `Africa/Cairo`.
- `detail` و`return_lookup` يعيدان فاتورة POS وتفاصيلها فقط داخل الشركة والفروع المصرح بها.
- لا توسع RLS ولا تنشئ Edge Function.

### ACL والتحقق الفعلي

| الفحص | النتيجة |
|---|---|
| `anon EXECUTE` | **FALSE** |
| `authenticated EXECUTE` | **TRUE** |
| `service_role EXECUTE` | **TRUE** |
| `SECURITY DEFINER` | **TRUE** |
| `search_path` | فارغ |

محاكاة قاعدة البيانات بهوية الكاشير داخل transaction ثم rollback:
- `today`: `success=true`، التاريخ `2026-10-10`، فاتورة واحدة `ORD-1004`.
- `detail`: أعادت `ORD-1004` وثلاثة أسطر وإجمالي 275.
- لم تتغير أي بيانات تجارية، ولم تُنشأ/تُحذف فاتورة أو حركة مخزون أو قيد.
- هذا DB/JWT-claims simulation، وليس HTTP/Browser E2E.

## 2. التعديلات الجراحية المطلوبة في الواجهة

**الملف:** `papamohammed77-glitch/erp-frontend/companies/company-1/sales/pos.html`  
**Blob الذي تمت مراجعته:** `49eae1c7898aca76d0deecfa74a55fc31808d149`  
لا تلمس `main.html` أو `core.js`، ولا تكرر إصلاحات bootstrap/search السابقة.

### Patch A — إضافة المساعدين

**ابحث عن:** `self._searchReturnInvoice = function() {`  
**أدرج الكود التالي كاملًا قبله:**

~~~javascript
self._getPosInvoiceData = function(action, orderCode) {
    return supabase.rpc('get_pos_invoice_data', {
        p_action: action,
        p_order_code: orderCode || null
    }).then(function(result) {
        if (result.error) {
            throw new Error(result.error.message || 'فشل قراءة بيانات الفاتورة');
        }
        if (!result.data || result.data.success !== true) {
            throw new Error('استجابة قراءة الفاتورة غير صالحة');
        }
        return result.data;
    });
};

self._escapePosText = function(value) {
    return String(value == null ? '' : value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
};
~~~

### Patch B — استبدال الدالة `self.renderInvoicesView` بالكامل

**ابحث عن:** `self.renderInvoicesView = function() {`  
احذف الدالة كاملة حتى قوس الإغلاق الخاص بها، واستبدلها:

~~~javascript
self.renderInvoicesView = function() {
    var grid = RW_UI.byId('productsGrid');
    if (!grid) return;

    RW_UI.safeHTML(grid,
        '<div class="col-span-full p-4">' +
            '<h3 class="text-lg font-black text-white mb-4">📄 فواتير اليوم</h3>' +
            '<div id="invoicesTodayList" class="space-y-2">' +
                '<div class="text-center text-slate-400 py-4">جاري التحميل...</div>' +
            '</div>' +
        '</div>'
    );
    RW_UI.safeHTML(RW_UI.byId('cartItemsContainer'),
        '<div class="text-center text-slate-500 py-8">فواتير اليوم</div>'
    );

    self._getPosInvoiceData('today').then(function(payload) {
        var invs = Array.isArray(payload.invoices) ? payload.invoices : [];
        var list = RW_UI.byId('invoicesTodayList');
        if (!list) return;

        if (!invs.length) {
            RW_UI.safeHTML(list,
                '<div class="text-center py-8 text-slate-400">لا توجد فواتير اليوم لهذا الكاشير</div>'
            );
            return;
        }

        var total = 0;
        var cancelledCount = 0;
        var h = '';

        for (var i = 0; i < invs.length; i++) {
            var inv = invs[i];
            var cancelled = inv.order_status === 'Cancelled';
            var code = self._escapePosText(inv.order_code || '');
            var customer = self._escapePosText(inv.customer_name || 'عميل نقدي');
            var amount = Number(inv.total_amount) || 0;

            if (cancelled) cancelledCount++;
            else total += amount;

            h += '<button type="button" data-pos-order-code="' + code +
                '" data-pos-cancelled="' + (cancelled ? 'true' : 'false') + '"' +
                ' class="card-dark w-full flex justify-between items-center text-right ' +
                (cancelled ? 'bg-red-950/20 border-red-900/50' : '') + '">' +
                '<span class="flex-1">' +
                    '<span class="flex items-center gap-2">' +
                        '<span class="font-black text-white text-sm">' + code + '</span>' +
                        (cancelled
                            ? '<span class="text-[10px] font-bold text-red-400 bg-red-950/50 px-2 py-0.5 rounded-full">🚫 ملغاة</span>'
                            : '') +
                    '</span>' +
                    '<span class="block text-xs text-slate-400 mt-1">' + customer + '</span>' +
                    '<span class="block text-[10px] text-slate-500 mt-1">' +
                        self._escapePosText(inv.order_date || '') +
                    '</span>' +
                '</span>' +
                '<span class="font-black ' + (cancelled ? 'text-red-400 line-through' : 'text-emerald-400') +
                    ' text-sm">' + fmtNum(amount) + ' ' + self._escapePosText(currency) + '</span>' +
            '</button>';
        }

        var summary = invs.length + ' فاتورة';
        if (cancelledCount) summary += ' | ' + cancelledCount + ' ملغاة';
        summary += ' | الإجمالي غير الملغى: ' + fmtNum(total) + ' ' + self._escapePosText(currency);

        RW_UI.safeHTML(list,
            '<div class="bg-emerald-900/30 p-3 rounded-xl mb-3 text-center">' +
                '<span class="text-emerald-400 font-bold">' + summary + '</span>' +
            '</div>' + h
        );

        var rows = list.querySelectorAll('[data-pos-order-code]');
        for (var j = 0; j < rows.length; j++) {
            (function(button) {
                button.addEventListener('click', function() {
                    var orderCode = button.getAttribute('data-pos-order-code');
                    if (button.getAttribute('data-pos-cancelled') === 'true') {
                        self._viewCancelledInvoice(orderCode);
                    } else {
                        self._viewActiveInvoice(orderCode);
                    }
                });
            })(rows[j]);
        }
    }).catch(function(err) {
        console.error('POS today invoices read failed:', err);
        var list = RW_UI.byId('invoicesTodayList');
        if (list) {
            RW_UI.safeHTML(list,
                '<div class="text-center py-8 text-red-400">تعذر تحميل فواتير اليوم. أعد المحاولة بعد التحقق من الاتصال.</div>'
            );
        }
    });
};
~~~

### Patch C — استبدال الدالة `self._searchReturnInvoice` بالكامل

**ابحث عن:** `self._searchReturnInvoice = function() {`  
احذف الدالة كاملة واستبدلها:

~~~javascript
self._searchReturnInvoice = function() {
    var input = RW_UI.byId('returnSearch');
    var code = input ? String(input.value || '').trim() : '';

    if (!code) {
        RW_UI.toast('أدخل رقم الفاتورة', 'warning');
        return;
    }

    RW_UI.showLoader('جاري تحميل الفاتورة...');
    self._getPosInvoiceData('return_lookup', code).then(function(payload) {
        RW_UI.hideLoader();

        var order = payload.order;
        var details = Array.isArray(payload.details) ? payload.details : [];

        if (!order) {
            RW_UI.toast('الفاتورة غير موجودة في فروع POS المصرح بها', 'error');
            return;
        }
        if (order.order_status === 'Cancelled') {
            RW_UI.toast('الفاتورة ملغاة ولا يمكن عمل مرتجع عليها', 'error');
            return;
        }
        if (!details.length) {
            RW_UI.toast('الفاتورة لا تحتوي على أصناف', 'warning');
            return;
        }

        var nextReturnCart = [];
        for (var i = 0; i < details.length; i++) {
            var det = details[i];
            var soldQty = Number(det.qty_delivered) || Number(det.qty) || 0;
            var alreadyReturned = Number(det.qty_returned) || 0;
            var remainingQty = Math.max(0, soldQty - alreadyReturned);

            nextReturnCart.push({
                code: det.item_code || '',
                name: det.item_name || '',
                unit: det.unit || 'حبة',
                price: Number(det.unit_price) || 0,
                originalQty: remainingQty,
                returnQty: 0
            });
        }

        var hasReturnable = nextReturnCart.some(function(item) {
            return item.originalQty > 0;
        });

        if (!hasReturnable) {
            returnCart = [];
            returnOriginalInvoice = null;
            RW_UI.toast('جميع أصناف هذه الفاتورة تم إرجاعها سابقًا', 'warning');
            return;
        }

        returnOriginalInvoice = order;
        returnCart = nextReturnCart;
        self._buildReturnScreen(order);
    }).catch(function(err) {
        RW_UI.hideLoader();
        console.error('POS return invoice lookup failed:', err);
        RW_UI.showError('تعذر تحميل الفاتورة للمرتجع: ' +
            (err && err.message ? err.message : 'خطأ غير معروف'));
    });
};
~~~

### Patch D — استبدال الدالة `self._viewActiveInvoice` بالكامل

**ابحث عن:** `self._viewActiveInvoice = function(orderCode) {`  
احذف الدالة كاملة واستبدلها:

~~~javascript
self._viewActiveInvoice = function(orderCode) {
    RW_UI.showLoader('جاري تحميل الفاتورة...');

    self._getPosInvoiceData('detail', orderCode).then(function(payload) {
        RW_UI.hideLoader();

        var order = payload.order;
        var details = Array.isArray(payload.details) ? payload.details : [];
        if (!order) {
            RW_UI.toast('الفاتورة غير موجودة أو خارج نطاق الفروع المصرح بها', 'error');
            return;
        }

        var cancelled = order.order_status === 'Cancelled';
        var esc = self._escapePosText;
        var h = '<div class="text-right text-sm">';

        if (cancelled) {
            h += '<div class="bg-red-950/50 border border-red-700/50 rounded-xl p-3 mb-4 text-center">' +
                '<p class="text-red-400 font-bold text-lg">🚫 فاتورة ملغاة</p>' +
                '<p class="text-xs text-slate-400 mt-1">الحالة معروضة من قاعدة البيانات المركزية.</p>' +
            '</div>';
        }

        h += '<div class="bg-slate-800 rounded-xl p-3 mb-4">' +
            '<p><strong>رقم الفاتورة:</strong> ' + esc(order.order_code) + '</p>' +
            '<p><strong>التاريخ:</strong> ' + esc(order.order_date) + '</p>' +
            '<p><strong>العميل:</strong> ' + esc(order.customer_name || 'عميل نقدي') + '</p>' +
            '<p><strong>الحالة:</strong> ' + esc(order.order_status) + '</p>' +
            '<p><strong>الإجمالي:</strong> <span class="' +
                (cancelled ? 'text-red-400 line-through' : 'text-emerald-400') +
                ' font-bold text-lg">' + fmtNum(Number(order.total_amount) || 0) +
                ' ' + esc(currency) + '</span></p>' +
        '</div>';

        if (details.length) {
            h += '<div class="overflow-x-auto"><table class="w-full text-sm border border-slate-700">' +
                '<thead class="bg-slate-800"><tr>' +
                    '<th class="p-2 border border-slate-700">الصنف</th>' +
                    '<th class="p-2 border border-slate-700 text-center">الكمية</th>' +
                    '<th class="p-2 border border-slate-700 text-center">السعر</th>' +
                    '<th class="p-2 border border-slate-700 text-center">الإجمالي</th>' +
                '</tr></thead><tbody>';

            for (var i = 0; i < details.length; i++) {
                var det = details[i];
                var qty = Number(det.qty) || 0;
                var price = Number(det.unit_price) || 0;
                h += '<tr class="border-b border-slate-700">' +
                    '<td class="p-2 border border-slate-700 font-semibold">' + esc(det.item_name || '') + '</td>' +
                    '<td class="p-2 border border-slate-700 text-center">' + fmtNum(qty) + '</td>' +
                    '<td class="p-2 border border-slate-700 text-center">' + fmtNum(price) + '</td>' +
                    '<td class="p-2 border border-slate-700 text-center font-bold">' + fmtNum(qty * price) + '</td>' +
                '</tr>';
            }

            h += '</tbody></table></div>';
        } else {
            h += '<div class="text-center py-4 text-slate-400">لا توجد أصناف مسجلة</div>';
        }

        h += '</div>';

        Swal.fire({
            title: cancelled ? 'استعراض فاتورة ملغاة' : 'تفاصيل الفاتورة',
            html: h,
            width: '650px',
            showCloseButton: true,
            showConfirmButton: false,
            customClass: {
                popup: '!bg-slate-900 !rounded-3xl !border !border-slate-700',
                closeButton: '!text-slate-400'
            }
        });
    }).catch(function(err) {
        RW_UI.hideLoader();
        console.error('POS invoice detail read failed:', err);
        RW_UI.showError('تعذر تحميل تفاصيل الفاتورة: ' +
            (err && err.message ? err.message : 'خطأ غير معروف'));
    });
};
~~~

### Patch E — استبدال الدالة `self._viewCancelledInvoice` بالكامل

**ابحث عن:** `self._viewCancelledInvoice = function(orderCode) {`  
احذف الدالة كاملة واستبدلها:

~~~javascript
self._viewCancelledInvoice = function(orderCode) {
    self._viewActiveInvoice(orderCode);
};
~~~

## 3. الاختبارات المطلوبة بعد دمج الواجهة

1. تسجيل الدخول بحساب POS-only وفتح «فواتير اليوم»؛ يجب أن تظهر `ORD-1004` للكاشير الذي أنشأها في يوم العمل الحالي.
2. فتح فاتورة نشطة وقراءة الرأس والتفاصيل.
3. البحث عن فاتورة في المرتجع؛ تحميل الأصناف والكميات المرتجعة سابقًا.
4. رفض فاتورة ملغاة أو مستنفدة الكميات، ورفض فاتورة من شركة/فرع خارج النطاق.
5. عند فشل RPC يظهر خطأ واضح، لا رسالة «لا توجد فواتير».
6. التأكد من عدم عرض فواتير `order-taker` أو `van-sales` في قائمة POS.
7. إعادة فحص logs للتأكد من اختفاء الاستعلامات المباشرة إلى `/rest/v1/orders` و`/rest/v1/order_details` من الدوال المتأثرة.
8. إعادة قراءة blob المنشور بعد النشر؛ لا تفترض تطابق Cloudflare Pages/Service Worker مع Git.

## SELF-AUDIT FINAL

- **What I Proved:** RLS هي السبب المباشر للنتيجة الفارغة. RPC الجديدة تعمل في DB simulation بهوية الكاشير، وتعيد فاتورة POS ضمن نطاق الشركة والفروع المصرح بها. ACL مقيدة.
- **What I Did Not Prove:** تشغيل المتصفح بعد تطبيق الجراحة، HTTP E2E من المتصفح إلى RPC، تطابق artifact المنشور مع Git، أو رد نقدي/بطاقة من درج كاشير.
- **What I Fixed:** نشرت `get_pos_invoice_data` وسجلت migration في Git، وجهزت خمس تغييرات جراحية محددة.
- **What I Initially Missed:** إصلاح bootstrap والبحث لا يصلح تبويبي الفواتير والمرتجع؛ لهما استعلامات مباشرة مستقلة محجوبة بـRLS.
- **What Could Still Be Wrong:** قد تظهر فروق في DOM/cache بعد الدمج. عقد رد الأموال النقدية/البطاقة من درج كاشير مستقل غير مثبت.
- **Final Confidence:** مرتفع في التشخيص وRPC/ACL ومحاكاة DB؛ متوسط في نتيجة الواجهة إلى أن تُدمج وتُنشر.
- **Final Closure Status:** `PRODUCTION READ RPC DEPLOYED / OWNER FRONTEND SURGERY PENDING / HTTP-BROWSER E2E PENDING / POS NOT CLOSED`.
