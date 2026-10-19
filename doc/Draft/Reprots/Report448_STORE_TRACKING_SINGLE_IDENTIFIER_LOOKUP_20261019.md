# Report448 — دعم تتبّع الطلب برقم الهاتف أو رقم الطلب منفردًا

**التاريخ:** 2026-10-19  
**النطاق:** erp-frontend/companies/company-1/store/track.html + عقد القراءة العام في Supabase Production.  
**حدود التعديل:** لم أعدّل main.html أو store/index.html أو track.html نيابةً عن المالك. نُفذ تغيير Production المبرر فقط، وأُعدّ أدناه التعديل الجراحي للواجهة. لم تُنشأ طلبات أو بيانات أعمال تجريبية.

## 1. PRE-CHANGE SELF-AUDIT

- **Business Understanding:** المطلوب أن يستطيع العميل البحث برقم الهاتف وحده أو رقم الطلب وحده، مع الإبقاء على تفاصيل الطلب الكاملة عند إدخال الرقمين معًا.
- **Architecture Understanding:** الصفحة العامة تستخدم Supabase client من core.js. جداول الطلبات عليها RLS ولا يجوز تجاوزها بقراءات مباشرة من الصفحة العامة؛ الاستعلام يمر عبر RPC عام محدود.
- **Database Understanding:** Production يحتوي public.get_public_store_order_tracking(text,text,text)، وorders مرتبط بـorder_details عن طريق order_id. يوجد unique index على (company_id, order_code).
- **Historical Understanding:** تمت مراجعة rawaie-erp-review/PWA/store/track.html (SHA bca9cddc3977bd4beb164acb811a0c82138a2d70) ومقارنته بتقرير Report447. المصدر التاريخي كان يقرأ الجداول مباشرة؛ إصلاح Report447 نقل القراءة إلى RPC وأضاف الهاتف، لكنه جعل الحقلين إلزاميين.
- **Production Understanding:** قُرئ تعريف RPC الحي، وACL، ومخطط الجداول، وفُحصت طريقة إنشاء الطلبات. submit_online_order_atomic يولّد أكوادًا تسلسلية من نمط ORD-...؛ لذلك لا يصح كشف اسم العميل أو منطقته أو الإجمالي أو تفاصيل الأصناف عند البحث برقم الطلب وحده.
- **Current Understanding:** آخر commit لصفحة التتبع هو 92d7a307f502f9601889acb9d5fccb3c94d4b38c (2026-10-19 19:59 +03)، وSHA الحالي للملف b798587e8deccfdd875d70d1eecc0416731f91ad، 245 سطرًا. يحتوي الصفحة بالفعل على حقل الهاتف وRPC وHTML escaping، لكن lookup() يرفض الطلب إذا غاب أي من الحقلين.
- **Execution Confidence:** مرتفع في عقد Production بعد اختبارات SQL الحية؛ لم يُثبت بعد سلوك الصفحة بعد تطبيق Patch المالك ونشرها.

### المصادر التي تمت مطابقتها

1. erp-frontend/companies/company-1/store/track.html — SHA b798587e8deccfdd875d70d1eecc0416731f91ad.
2. آخر commit للصفحة: https://github.com/papamohammed77-glitch/erp-frontend/commit/92d7a307f502f9601889acb9d5fccb3c94d4b38c.
3. المصدر التاريخي: rawaie-erp-review/PWA/store/track.html.
4. تقرير سابق: Report447_STORE_ORDER_TRACKING_FORENSIC_REPAIR_20261019.md.
5. تعريف Production الحي لـ get_public_store_order_tracking(text,text,text)، و submit_online_order_atomic(...).
6. مخطط orders و order_details وفهارس orders.
7. Migration المصدر: https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/supabase/migrations/20261019170525_store_order_tracking_single_identifier_lookup_20261019.sql.

## 2. Root cause المثبت

الخلل ليس في وجود حقل الهاتف ولا في RPC call ذاته؛ commit 92d7a307... أضاف الحقل والـRPC، لكنه جعل هذا الشرط إلزاميًا:

~~~javascript
if (!orderCode || !customerPhone) {
    Swal.fire({ icon: 'warning', title: 'أدخل رقم الطلب ورقم الهاتف المستخدم عند الشراء' });
    return;
}
~~~

والـRPC المنشور سابقًا كان يرفض كذلك p_order_code الفارغ أو الهاتف الفارغ. لذلك لم يكن البحث المنفرد ممكنًا من الواجهة أو من عقد Production.

## 3. إصلاح Production — نُفذ وتحقق

### Migration مطبقة

- **Migration version:** 20261019170525.
- **الاسم:** store_order_tracking_single_identifier_lookup_20261019.
- **ملف المصدر:** supabase/migrations/20261019170525_store_order_tracking_single_identifier_lookup_20261019.sql.
- **Commit ملف migration:** bdcf317c24b29ceacc28f6aa5ec35660dfc6ccee.
- **الدالة الحالية:** public.get_public_store_order_tracking(text,text,text) — لا توجد Edge Function جديدة.

### عقد النتائج الجديد

| المدخل | النتيجة |
|---|---|
| رقم الطلب فقط | حالة الطلب ورقمه وتاريخه فقط؛ لا اسم عميل أو منطقة أو مبلغ أو أصناف. |
| الهاتف فقط | حتى 10 ملخصات حديثة لطلبات المتجر: رقم الطلب والتاريخ والحالة فقط؛ لا بيانات شخصية أو مالية أو أصناف. |
| رقم الطلب + الهاتف المطابق | التفاصيل الحالية الكاملة المسموح بها: الاسم والمنطقة والإجمالي والأصناف. |
| لا يوجد مدخل صالح / متجر غير صالح / طلب غير موجود / هاتف غير مطابق | نتيجة فشل عامة موحدة. |

- البحث مقيد بمفتاح متجر منشور واحد وشركة واحدة وبـ source = 'online_store'.
- تطبيع الهاتف يزيل علامات التنسيق غير الرقمية، ويشترط 7 أرقام على الأقل.
- بحث الهاتف محدود بعشرة طلبات مرتبة بالأحدث لتجنب استجابة عامة غير محدودة.
- ACL بعد الإصلاح: anon EXECUTE=true، authenticated EXECUTE=true، service_role EXECUTE=false. بقيت الدالة SECURITY DEFINER لأن القراءة العامة تحتاج تجاوز RLS، مع إسقاطات نتائج محدودة والتحقق من الشركة والمصدر.
- لم يتغير المخزون أو الحجز أو الحسابات أو حالة أي طلب.

### اختبارات SQL حية بعد النشر

| الاختبار | النتيجة |
|---|---|
| رقم الطلب وحده على طلب متجر موجود | PASS |
| الهاتف وحده على طلب متجر موجود | PASS |
| الرقم والهاتف المطابقان | PASS |
| رقم طلب غير موجود | مرفوض كما هو مطلوب |
| عدم إدخال أي حقل | مرفوض كما هو مطلوب |
| مفتاح متجر غير صالح | مرفوض كما هو مطلوب |
| رقم الطلب وحده يكشف اسم العميل | لا |
| رقم الطلب وحده يكشف الإجمالي أو الأصناف | لا |
| الهاتف وحده يكشف اسم العميل أو الإجمالي أو الأصناف | لا |
| وضع التفاصيل الكاملة يعيد مصفوفة أصناف | PASS |
| anon/authenticated/service_role ACL | PASS حسب العقد أعلاه |

الاختبارات استخدمت طلب Production موجودًا عبر subqueries؛ لم تُظهر رقم الهاتف أو بيانات العميل في نتائج الاختبار، ولم تُنشئ أو تعدّل أو تحذف أي صف أعمال.

## 4. التعديل الجراحي المطلوب من المالك

**الملف:** erp-frontend/companies/company-1/store/track.html  
**SHA الأساس:** b798587e8deccfdd875d70d1eecc0416731f91ad  
**آخر commit معروف:** 92d7a307f502f9601889acb9d5fccb3c94d4b38c  
**لا تعدّل main.html أو store/index.html.**

### Patch A — توضيح أن أحد الحقلين يكفي

**الموضع:** السطر 29، النص أسفل عنوان الصفحة.

ابحث عن:
~~~html
<p class="text-blue-100 text-sm">أدخل رقم الطلب لمعرفة حالته</p>
~~~

واستبدله بـ:
~~~html
<p class="text-blue-100 text-sm">أدخل رقم الطلب أو رقم الهاتف لمعرفة حالة طلبك</p>
~~~

**الموضع:** السطر 48، النص أسفل حقلي البحث.

ابحث عن:
~~~html
<p class="text-xs text-gray-400 mt-2">لخصوصيتك، أدخل رقم الطلب ورقم الهاتف المستخدم عند إتمام الشراء.</p>
~~~

واستبدله بـ:
~~~html
<p class="text-xs text-gray-400 mt-2">يمكنك البحث برقم الطلب أو الهاتف فقط. أدخل الرقمين معًا لعرض تفاصيل الطلب والأصناف.</p>
~~~

### Patch B — استبدال Tracker.lookup بالكامل

**الموضع:** يبدأ عند السطر 79، وينتهي عند }, التي تسبق showStatus مباشرةً. احذف دالة lookup الحالية فقط واستبدلها بالنص الكامل التالي:

~~~javascript
    lookup: function() {
        var orderCode = (document.getElementById('orderCodeInput').value || '').trim();
        var customerPhone = (document.getElementById('customerPhoneInput').value || '').trim();

        if (!orderCode && !customerPhone) {
            Swal.fire({ icon: 'warning', title: 'أدخل رقم الطلب أو رقم الهاتف' });
            return;
        }

        if (customerPhone && customerPhone.replace(/[^0-9]/g, '').length < 7) {
            Swal.fire({ icon: 'warning', title: 'راجع رقم الهاتف وأدخل 7 أرقام على الأقل' });
            return;
        }

        var container = document.getElementById('resultContainer');
        container.innerHTML = '<div class="card text-center py-8"><i class="fa-solid fa-spinner fa-spin text-2xl text-blue-600"></i><p class="mt-2 text-gray-500">جاري البحث...</p></div>';

        var self = this;
        supabase.rpc('get_public_store_order_tracking', {
            p_storefront_key: 'company-1',
            p_order_code: orderCode || null,
            p_customer_phone: customerPhone || null
        }).then(function(result) {
            if (result.error) throw result.error;

            var payload = result.data;
            if (!payload || payload.success !== true) {
                container.innerHTML = '<div class="card text-center py-8"><i class="fa-solid fa-circle-xmark text-4xl text-red-400 mb-3"></i><p class="font-bold text-gray-700">تعذر العثور على الطلب بهذه البيانات</p><p class="text-sm text-gray-400 mt-1">راجع البيانات ثم حاول مرة أخرى.</p></div>';
                return;
            }

            if (payload.lookup_mode === 'phone' && Array.isArray(payload.orders)) {
                self.showOrderList(container, payload.orders);
                return;
            }

            if (!payload.order) {
                container.innerHTML = '<div class="card text-center py-8"><p class="font-bold text-gray-700">تعذر العثور على الطلب بهذه البيانات</p></div>';
                return;
            }

            self.showStatus(
                container,
                payload.order,
                Array.isArray(payload.items) ? payload.items : [],
                payload.lookup_mode || 'full'
            );
        }).catch(function(error) {
            console.error('Order tracking RPC failed:', error);
            container.innerHTML = '<div class="card text-center py-8"><i class="fa-solid fa-triangle-exclamation text-4xl text-red-400 mb-3"></i><p class="font-bold text-gray-700">تعذر الاستعلام عن الطلب الآن</p><p class="text-sm text-gray-400 mt-1">تحقق من الاتصال وحاول مرة أخرى.</p></div>';
        });
    },
~~~

### Patch C — إضافة عرض قائمة الطلبات عند البحث بالهاتف فقط

**الموضع:** داخل كائن Tracker، مباشرة بعد نهاية lookup وقبل showStatus. أدرج الدالة التالية كاملة؛ لا تستبدل الكائن:

~~~javascript
    showOrderList: function(container, orders) {
        if (!Array.isArray(orders) || orders.length === 0) {
            container.innerHTML = '<div class="card text-center py-8"><p class="font-bold text-gray-700">لا توجد طلبات مرتبطة بهذا الهاتف</p></div>';
            return;
        }

        var statusLabels = {
            'Draft': 'قيد المراجعة',
            'Confirmed': 'تم التأكيد',
            'Pending': 'قيد الانتظار',
            'Picking': 'جاري التجهيز',
            'Picked': 'تم التجهيز',
            'Loading': 'جاري التحميل',
            'Loaded': 'تم التحميل',
            'Delivering': 'خارج للتوصيل',
            'Delivered': 'تم التسليم',
            'Partially Delivered': 'تم التسليم جزئيًا',
            'Partially Returned': 'تم إرجاع جزء من الطلب',
            'Cancelled': 'ملغي',
            'Canceled': 'ملغي'
        };

        var html = '<div class="space-y-3">';
        html += '<div class="card"><p class="font-bold text-gray-800">طلبات مرتبطة برقم الهاتف</p><p class="text-xs text-gray-500 mt-1">تظهر هنا الحالة فقط. أدخل رقم الطلب مع الهاتف لعرض التفاصيل الكاملة.</p></div>';

        for (var i = 0; i < orders.length; i++) {
            var order = orders[i] || {};
            var status = order.order_status || '';
            var statusLabel = statusLabels[status] || status || 'غير محدد';
            var statusColor = status === 'Delivered' ? 'bg-green-100 text-green-700' :
                (status === 'Cancelled' || status === 'Canceled') ? 'bg-red-100 text-red-700' :
                'bg-blue-100 text-blue-700';
            var orderDate = order.order_date ? new Date(order.order_date).toLocaleDateString('ar-EG') : '';

            html += '<div class="card">';
            html += '<div class="flex items-center justify-between gap-3">';
            html += '<div><p class="text-xs text-gray-500">رقم الطلب</p><p class="font-black text-lg">' + escapeHtml(order.order_code || '') + '</p></div>';
            html += '<span class="px-3 py-1 rounded-full text-xs font-bold ' + statusColor + '">' + escapeHtml(statusLabel) + '</span>';
            html += '</div>';
            html += '<p class="text-xs text-gray-500 mt-2">التاريخ: ' + escapeHtml(orderDate) + '</p>';
            html += '</div>';
        }

        html += '</div>';
        container.innerHTML = html;
    },
~~~

### Patch D — إخفاء بيانات العميل والمبالغ عند البحث برقم الطلب فقط

**أولًا:** في تعريف الدالة الحالية، ابحث عن:
~~~javascript
showStatus: function(container, order, details) {
~~~

واستبدله بـ:
~~~javascript
showStatus: function(container, order, details, lookupMode) {
~~~

**ثانيًا:** داخل Tracker.showStatus، ابحث عن المقطع الذي يبدأ عند السطر 206 حاليًا:

~~~javascript
        html += '<div class="grid grid-cols-2 gap-2 text-sm">';
        html += '<div><p class="text-xs text-gray-500">التاريخ</p><p class="font-bold">' + (order.order_date ? new Date(order.order_date).toLocaleDateString('ar-EG') : '') + '</p></div>';
        html += '<div><p class="text-xs text-gray-500">العميل</p><p class="font-bold">' + escapeHtml(order.customer_name || '') + '</p></div>';
        html += '<div><p class="text-xs text-gray-500">المنطقة</p><p class="font-bold">' + escapeHtml(order.area || '') + '</p></div>';
        html += '<div><p class="text-xs text-gray-500">الإجمالي</p><p class="font-black text-blue-600 text-lg">' + Number(order.total_amount || 0).toLocaleString() + '</p></div>';
        html += '</div></div>';
~~~

واحذفه واستبدله كاملًا بـ:

~~~javascript
        html += '<div class="grid grid-cols-2 gap-2 text-sm">';
        html += '<div><p class="text-xs text-gray-500">التاريخ</p><p class="font-bold">' + (order.order_date ? new Date(order.order_date).toLocaleDateString('ar-EG') : '') + '</p></div>';
        if (lookupMode === 'full') {
            html += '<div><p class="text-xs text-gray-500">العميل</p><p class="font-bold">' + escapeHtml(order.customer_name || '') + '</p></div>';
            html += '<div><p class="text-xs text-gray-500">المنطقة</p><p class="font-bold">' + escapeHtml(order.area || '') + '</p></div>';
            html += '<div><p class="text-xs text-gray-500">الإجمالي</p><p class="font-black text-blue-600 text-lg">' + Number(order.total_amount || 0).toLocaleString() + '</p></div>';
        }
        html += '</div></div>';
~~~

**مهم:** لا تغيّر escapeHtml أو progress/status logic أو DOMContentLoaded الحالي؛ هذه الأجزاء موجودة في المصدر الحالي ولا حاجة لإعادة بنائها.

## 5. الاختبارات بعد تطبيق Patch المالك

1. **رقم طلب فقط:** يظهر رقم الطلب وتاريخه وحالته ومسار الحالة، ولا يظهر الاسم أو المنطقة أو الإجمالي أو الأصناف.
2. **هاتف فقط:** تظهر قائمة ملخصات لا تتجاوز 10 طلبات، مع الرقم والتاريخ والحالة فقط.
3. **الرقم والهاتف الصحيحان:** تظهر التفاصيل والأصناف كما كانت.
4. **رقم هاتف صحيح شكليًا لكن غير مطابق:** لا يعيد طلبات.
5. **رقم طلب غير موجود أو مفتاح متجر غير صالح:** رسالة فشل عامة.
6. **الحقلان فارغان:** تنبيه واضح ولا يُرسل RPC.
7. **Enter في كل حقل:** يبدأ البحث.
8. **XSS:** أسماء الأصناف/الحالات/أرقام الطلبات التي تحتوي رموز HTML تُعرض كنص.
9. **Network:** استدعاء واحد لـget_public_store_order_tracking، ولا توجد قراءات مباشرة من orders أو order_details.
10. بعد النشر، افحص Cloudflare served artifact مقابل Git، ثم Console/Network في المتصفح. لم يتمكن هذا التغيير من إثبات اختبار المتصفح قبل تطبيق المالك.

## 6. الأثر والحدود

- **Production RPC:** تم التعديل والنشر عبر Migration، والتحقق من الحالات الثلاث (رقم فقط، هاتف فقط، كلاهما) ومن الحالات السلبية.
- **Source artifact:** لم يتم تعديل ملف التطبيق؛ Patch المالك أعلاه جاهز للتطبيق على SHA المحدد.
- **main.html وstore/index.html:** لم يمسهما هذا العمل.
- **بيانات الأعمال:** لا إدخال أو تعديل أو حذف.
- **Browser E2E / served artifact parity:** غير مثبتين حتى يطبق المالك التعديل وينشره ويختبره.
- **Closure:** PRODUCTION RPC VERIFIED / OWNER UI PATCH READY / BROWSER E2E OPEN.

## SELF-AUDIT FINAL

- **What I Proved:** أن عقد Production يدعم الآن البحث المنفرد بالهاتف أو رقم الطلب، وأن اختبارًا حيًا أعاد الحالة في كل مسار، وأن البحث المنفرد لا يعيد بيانات العميل أو المبالغ أو الأصناف.
- **What I Did Not Prove:** أن الواجهة المنشورة تعرض النتائج الجديدة؛ لم يطبق المالك Patch بعد ولم يُنفذ Browser E2E.
- **What I Fixed:** RPC الحالي وعقده، مع الحفاظ على التوقيع وACL ومفتاح المتجر وعزل الشركة والمصدر.
- **What I Initially Missed:** تقرير Report447 أصلح مسار القراءة وأمان HTML لكنه بقي يشترط الحقلين؛ آخر commit للواجهة أكد استمرار هذا الشرط.
- **What Could Still Be Wrong:** قد تختلف طريقة كتابة الهاتف عن الأرقام المخزنة بسبب رمز البلد/مقدمة الاتصال؛ التطبيع الحالي يزيل علامات التنسيق فقط. كما أن بحث رقم الطلب وحده يكشف الحالة العامة فقط عمدًا؛ لا ينبغي توسيع إسقاطه إلى بيانات العميل أو المبالغ دون آلية إثبات ملكية.
- **Final Confidence:** مرتفع في Production RPC/SQL؛ متوسط في إتمام تجربة المستخدم إلى أن تطبق الواجهة وتختبر النسخة المنشورة.
- **Final Closure Status:** PRODUCTION RPC DEPLOYED + SQL VERIFIED / OWNER UI PATCH REQUIRED / NOT END-TO-END CLOSED.
