# Report443 — فلتر المصدر وأوردرات العمليات في مركز أوردرات المبيعات

**التاريخ:** 2026-10-19  
**النطاق:** وحدة RW_Orders في erp-frontend/companies/company-1/main.html فقط، مع فحص تكامل المتجر الإلكتروني وعقود Production ذات الصلة.  
**ملكية المصدر:** المالك يطبق التعديلات في main.html وملفات التطبيقات؛ لم أعدّل أي ملف تشغيلي.  
**Production:** قراءة مباشرة فقط؛ لم أغيّر Schema أو RPC أو ACL أو بيانات.

## PRE-CHANGE SELF-AUDIT

- Business Understanding: المطلوب فلتر مصدر مستقل، وزر «أوردرات عمليات» يعرض فقط الأوردرات المؤهلة فعليًا للضم إلى الرانشيت، لا مجرد الأوردرات التي تحمل مصدرًا معينًا.
- Architecture Understanding: RW_Orders يجلب أوردرات الشركة الحالية من public.orders، ويعرضها محليًا من ordersData. يجب أن تتطابق قاعدة الزر مع أهلية checkbox الحالية ومع عقد إنشاء/ضم الرانشيت في Production.
- Database Understanding: مصدر الأوردر محفوظ في public.orders.source، وحالة الأوردر في order_status، والارتباط بالرانشيت في runsheet_id.
- Historical Understanding: Report420 سابقًا اقترح فلاتر المصدر والمنشئ. الطلب الحالي أضيق ومحدد: فلتر المصدر وزر أوردرات العمليات؛ لذلك لا أضيف فلتر المنشئ ولا أعيد أي تغيير قديم لا يحتاجه هذا الطلب.
- Production Understanding: فحص SQL مباشر في 2026-10-19 14:26:33 UTC أثبت 12 أوردرًا: online_store=1، order-taker=4، pos=5، telesales=2. لم تُنشأ بيانات تجريبية.
- Current Understanding: main.html blob SHA الحالي e8c163e1856bc9cd0ca88eff6c2a2fed1b091b36، 32,749 سطرًا. HEAD هو 16511abe1af392c0e9cb55bc9bd204d23f46e0e3، وparent هو 3109c5d38fd151c8f3e349add15875cf21713bf9.
- Execution Confidence: مرتفع في مصدر Git وعقد قاعدة البيانات وRPCs. النشر وBrowser E2E غير مثبتين، لأن المالك هو من يطبق ملف الواجهة.

## CURRENT REALITY — VERIFIED

### 1. التعديل الأخير في Git

مقارنة HEAD مع parent أثبتت أن commit 16511abe1af392c0e9cb55bc9bd204d23f46e0e3 غيّر main.html أيضًا، رغم أن رسالة commit تتحدث عن كمية عرض المتجر.

في main.html، السطر الحالي 5543 يحتوي نهاية سطر نص الشارة ثم تعبيرًا زائدًا مكررًا خارج إسناد html. هذا أثر جانبي غير مطلوب من التعديل الأخير ويجب حذفه جراحيًا قبل دمج أي تعديل آخر.

### 2. حالة فلاتر RW_Orders

- الفلاتر الحالية في السطور 10232–10243: التاريخ من/إلى، العميل، الحالة، المنطقة، الرانشيت.
- لا يوجد فلتر source.
- _applyFilters الحالية في السطور 10381–10413 لا تطبق source ولا وضع «أوردرات عمليات».
- _resetFilters في السطور 10415–10422 يعيد ستة حقول فقط.
- منطق أهلية checkbox الحالي في السطور 10493–10497: source بعد normalization أحد (telesales, tele-sales, order-taker, online-store)، والحالة Confirmed أو Pending، ولا يوجد runsheet_id.
- _refreshData تنتهي من إعادة بناء ordersData عند السطر 11068 ثم تستدعي _applyFilters عند 11069؛ يجب تحديث خيارات المصدر قبل الفلترة.
- مصدر المتجر في Production هو online_store، ويجب تطبيعه إلى online-store مثلما تفعل دوال الرانشيت.

### 3. Production contracts

- create-runsheet: v26، verify_jwt=true، ezbr_sha256=6db690ef3c989fed8967db9b1aa9203e318960532490767cc74dbf8ed50aa798.
- append-to-runsheet: v8، verify_jwt=true، ezbr_sha256=1225b25e21f36c94aa60ce6afacb3933d62e8f3f12f853466ca1fe448c0aa23c.
- Production RPCs create_runsheet_atomic وappend_orders_to_runsheet_atomic تقبل المصادر المطَبّعة telesales/tele-sales/order-taker/online-store، والحالة Confirmed/Pending، وترفض الأوردر المرتبط مسبقًا برانشيت.
- ACL الحالي: anon/authenticated EXECUTE=false، service_role EXECUTE=true لكلا RPCs.
- submit-online-order Production v11، verify_jwt=false، hash=172eff4fccc8bf43f920e9ab8c83dd39aa988a68c9e5b3170ce320138ff31315. يكتب submit_online_order_atomic مصدر online_store. لا يلزم تعديل Production لإنجاز فلاتر العرض.
- لم أعدّل Production ولم أنشئ أوردرات اختبار.

### 4. المتجر الإلكتروني

- المصدر الحالي: companies/company-1/store/index.html، blob SHA 4af4e2f2f7727f84bdad5afb91932d5f7efe2a3e، 576 سطرًا.
- التطبيق يرسل الطلب إلى submit-online-order، والـEdge الحالي يمرر الطلب إلى submit_online_order_atomic؛ مصدر online_store موجود في Production بالفعل.
- لا تعديل مطلوب في ملف المتجر لهذه المهمة. لم ألمس الملف.
- ملاحظة خارج نطاق فلتر الأوردرات: الواجهة الحالية لا ترسل operation_id ثابتًا في body، والـEdge يولّد UUID جديدًا عند غيابه. لذلك لا يجوز اعتبار إعادة محاولة checkout من المتصفح idempotent عبر المحاولات المختلفة دون تغيير منفصل في عقد المتجر. لم أغيّر هذا السلوك ضمن هذه المهمة.

## التعديلات الجراحية — المالك يطبقها

### PATCH 0 — إزالة الجزء المكرر الذي أدخله آخر commit

- الملف: companies/company-1/main.html
- SHA الحالي: e8c163e1856bc9cd0ca88eff6c2a2fed1b091b36
- الموضع: السطر 5543، داخل دالة بناء تبويب العروض والتسويق.
- ابحث عن السطر الكامل التالي واحذفه:

~~~javascript
        html += '<div class="flex flex-col"><label class="text-sm font-bold">نص الشارة</label><input id="item-badge-text" value="' + _esc(item ? (item.badge_text || '') : '') + '" class="p-2.5 bg-gray-50 border rounded-lg" placeholder="جديد، الأكثر مبيعاً، عرض محدود"></div>'; + _esc(item ? (item.badge_text || '') : '') + '" class="p-2.5 bg-gray-50 border rounded-lg" placeholder="جديد، الأكثر مبيعاً، عرض محدود"></div>';
~~~

- استبدله بالسطر الكامل التالي فقط:

~~~javascript
        html += '<div class="flex flex-col"><label class="text-sm font-bold">نص الشارة</label><input id="item-badge-text" value="' + _esc(item ? (item.badge_text || '') : '') + '" class="p-2.5 bg-gray-50 border rounded-lg" placeholder="جديد، الأكثر مبيعاً، عرض محدود"></div>';
~~~

- لا تستبدل كتلة التسويق كاملة. هذا إصلاح لسطر واحد فقط.

### PATCH 1 — إضافة زر «أوردرات عمليات» إلى شريط الفلاتر

- الموضع: السطور 10224–10230.
- ابحث داخل RW_Orders.render() عن بداية كتلة العنوان:

~~~javascript
            '<div class="flex flex-wrap justify-between items-center gap-2 mb-3">' +
                '<h3 class="font-bold text-lg">فلترة الأوردرات</h3>' +
                '<div class="flex gap-2">' +
~~~

- استبدل هذه الأسطر الثلاثة فقط بالنص التالي، واترك الأزرار الموجودة بعدها كما هي، مع إضافة زر العمليات قبل زر إعادة التعيين:

~~~javascript
            '<div class="flex flex-wrap justify-between items-center gap-2 mb-3">' +
                '<h3 class="font-bold text-lg">فلترة الأوردرات</h3>' +
                '<div class="flex flex-wrap gap-2">' +
                    '<button onclick="RW_Orders._applyFilters()" class="bg-blue-50 text-blue-600 px-3 py-1 rounded text-sm font-bold">تحديث</button>' +
                    '<button onclick="RW_Orders._showWithoutRS()" class="bg-amber-50 text-amber-600 px-3 py-1 rounded text-sm font-bold">بدون رانشيت</button>' +
                    '<button id="btn-operations-orders" type="button" aria-pressed="false" onclick="RW_Orders._toggleOperationsOnly()" class="bg-emerald-50 text-emerald-700 px-3 py-1 rounded text-sm font-bold">أوردرات عمليات</button>' +
                    '<button onclick="RW_Orders._resetFilters()" class="bg-gray-50 text-gray-600 px-3 py-1 rounded text-sm font-bold">إعادة تعيين</button>' +
                '</div>' +
            '</div>' +
~~~

### PATCH 2 — إضافة فلتر المصدر إلى شبكة الحقول

- الموضع: السطور 10232–10243.
- ابحث عن بداية الشبكة الحالية:

~~~javascript
            '<div class="grid grid-cols-2 md:grid-cols-6 gap-2">' +
~~~

- استبدل كتلة الشبكة كاملة حتى سطر إغلاق الشبكة مباشرة قبل إغلاق بطاقة الفلاتر بهذا النص:

~~~javascript
            '<div class="grid grid-cols-2 md:grid-cols-4 xl:grid-cols-7 gap-2">' +
                '<input type="date" id="f-date-from" onchange="RW_Orders._applyFilters()" class="p-2 bg-gray-50 rounded text-sm">' +
                '<input type="date" id="f-date-to" onchange="RW_Orders._applyFilters()" class="p-2 bg-gray-50 rounded text-sm">' +
                '<input type="text" id="f-cust" oninput="RW_Orders._applyFilters()" placeholder="العميل" class="p-2 bg-gray-50 rounded text-sm">' +
                '<select id="f-status" onchange="RW_Orders._applyFilters()" class="p-2 bg-gray-50 rounded text-sm">' +
                    '<option value="">الحالة</option>' +
                    '<option>Draft</option><option>Confirmed</option><option>Pending</option>' +
                    '<option>Invoiced</option><option>Delivered</option><option>Returned</option><option>Partially Returned</option><option>Cancelled</option>' +
                '</select>' +
                '<input type="text" id="f-area" oninput="RW_Orders._applyFilters()" placeholder="المنطقة" class="p-2 bg-gray-50 rounded text-sm">' +
                '<input type="text" id="f-rs" oninput="RW_Orders._applyFilters()" placeholder="الرانشيت" class="p-2 bg-gray-50 rounded text-sm">' +
                '<select id="f-source" aria-label="المصدر" onchange="RW_Orders._applyFilters()" class="p-2 bg-gray-50 rounded text-sm">' +
                    '<option value="">المصدر (الكل)</option>' +
                '</select>' +
            '</div>' +
~~~

### PATCH 3 — حالة زر العمليات

- الموضع: السطر 10207 داخل بداية RW_Orders.
- استبدل سطر تعريف الحالة:

~~~javascript
    var sortField = 'order_code', sortAsc = true, ordersData = [], currency = 'SAR';
~~~

- بهذا السطر:

~~~javascript
    var sortField = 'order_code', sortAsc = true, ordersData = [], currency = 'SAR', operationsOnly = false;
~~~

### PATCH 4 — أضف دوال التطبيع والأهلية وتعبئة المصدر والتحكم بالزر

- الموضع: مباشرة قبل التعليق // ========== الفلترة والفرز ========== قرب السطر 10380.
- أدرج الكتلة التالية كاملة، دون حذف أي دالة مجاورة:

~~~javascript
    function _normalizeOrderSource(value) {
        return String(value || '').trim().toLowerCase().replace(/[ _]+/g, '-');
    }

    function _isRunsheetEligible(order) {
        var source = _normalizeOrderSource(order && order.source);
        return ['telesales', 'tele-sales', 'order-taker', 'online-store'].indexOf(source) !== -1 &&
            ['Confirmed', 'Pending'].indexOf(order && order.order_status) !== -1 &&
            !(order && order.runsheet_id);
    }

    function _populateSourceFilter() {
        var selectEl = byId('f-source');
        if (!selectEl) return;

        var labels = {
            'pos': 'كاشير / POS',
            'telesales': 'تلي سيلز',
            'tele-sales': 'تلي سيلز',
            'order-taker': 'أوردر تيكر',
            'online-store': 'المتجر الإلكتروني',
            'van-sales': 'بيع مباشر'
        };
        var selected = selectEl.value;
        var sourceSet = {};

        ordersData.forEach(function(order) {
            var source = _normalizeOrderSource(order.source);
            if (source) sourceSet[source] = true;
        });

        while (selectEl.options.length > 1) selectEl.remove(1);

        Object.keys(sourceSet).sort().forEach(function(source) {
            var option = document.createElement('option');
            option.value = source;
            option.textContent = labels[source] || source;
            selectEl.appendChild(option);
        });

        selectEl.value = sourceSet[selected] ? selected : '';
    }

    function _setOperationsOnly(active) {
        operationsOnly = !!active;
        var button = byId('btn-operations-orders');
        if (!button) return;
        button.setAttribute('aria-pressed', operationsOnly ? 'true' : 'false');
        button.className = operationsOnly
            ? 'bg-emerald-600 text-white px-3 py-1 rounded text-sm font-bold'
            : 'bg-emerald-50 text-emerald-700 px-3 py-1 rounded text-sm font-bold';
    }

    function _toggleOperationsOnly() {
        _setOperationsOnly(!operationsOnly);
        _applyFilters();
    }
~~~

### PATCH 5 — استبدال _applyFilters كاملة

- الموضع الحالي: السطور 10381–10413.
- ابحث عن function _applyFilters() داخل RW_Orders، واستبدل الدالة كاملة حتى قوسها الختامي قبل function _resetFilters() بهذا النص:

~~~javascript
    function _applyFilters() {
        var filtered = ordersData.slice();
        var fdEl = byId('f-date-from'), tdEl = byId('f-date-to'), custEl = byId('f-cust'),
            stEl = byId('f-status'), areaEl = byId('f-area'), rsEl = byId('f-rs'),
            sourceEl = byId('f-source');

        var fd = fdEl ? fdEl.value : '';
        var td = tdEl ? tdEl.value : '';
        var cust = custEl ? (custEl.value || '').toLowerCase() : '';
        var st = stEl ? stEl.value : '';
        var area = areaEl ? (areaEl.value || '').toLowerCase() : '';
        var rs = rsEl ? (rsEl.value || '').toLowerCase() : '';
        var source = sourceEl ? sourceEl.value : '';

        if (fd) filtered = filtered.filter(function(o) { return o.order_date >= fd; });
        if (td) filtered = filtered.filter(function(o) { return o.order_date <= td; });
        if (cust) filtered = filtered.filter(function(o) { return (o.customer_name || '').toLowerCase().indexOf(cust) !== -1; });
        if (st) filtered = filtered.filter(function(o) { return o.order_status === st; });
        if (area) filtered = filtered.filter(function(o) { return (o.area || '').toLowerCase().indexOf(area) !== -1; });
        if (rs) filtered = filtered.filter(function(o) { return String(o._runsheetCode || '').toLowerCase().indexOf(rs) !== -1; });
        if (source) filtered = filtered.filter(function(o) { return _normalizeOrderSource(o.source) === source; });
        if (operationsOnly) filtered = filtered.filter(_isRunsheetEligible);

        var sorted = filtered.sort(function(a, b) {
            var va = a[sortField] || '', vb = b[sortField] || '';
            if (sortField === 'total_amount' || sortField === 'itemsCount') {
                va = Number(va); vb = Number(vb);
            } else if (sortField === 'order_date' || sortField === 'created_at') {
                va = new Date(va); vb = new Date(vb);
            } else {
                va = String(va).toLowerCase(); vb = String(vb).toLowerCase();
            }
            return (va < vb ? -1 : va > vb ? 1 : 0) * (sortAsc ? 1 : -1);
        });

        _renderTable(sorted);
    }
~~~

### PATCH 6 — استبدال _resetFilters كاملة

- الموضع الحالي: السطور 10415–10422.
- استبدل الدالة كاملة بالنص التالي:

~~~javascript
    function _resetFilters() {
        var ids = ['f-date-from', 'f-date-to', 'f-cust', 'f-status', 'f-area', 'f-rs', 'f-source'];
        for (var i = 0; i < ids.length; i++) {
            var el = byId(ids[i]);
            if (el) el.value = '';
        }
        _setOperationsOnly(false);
        _applyFilters();
    }
~~~

### PATCH 7 — وحّد أهلية checkbox مع زر العمليات

- الموضع الحالي: السطور 10493–10497 داخل _renderTable.
- ابحث عن المقطع:

~~~javascript
        var source = String(o.source || '').trim().toLowerCase().replace(/[ _]+/g, '-');
        var sourceEligible = ['telesales', 'tele-sales', 'order-taker', 'online-store'].indexOf(source) !== -1;
        var runsheetEligible = sourceEligible &&
            ['Confirmed', 'Pending'].indexOf(o.order_status) !== -1 &&
            !o.runsheet_id;
~~~

- استبدله بهذا المقطع:

~~~javascript
        var source = _normalizeOrderSource(o.source);
        var runsheetEligible = _isRunsheetEligible(o);
~~~

هذا يحافظ على نفس عقد الأهلية الموجود ويمنع اختلاف منطق الزر عن checkbox.

### PATCH 8 — مزامنة الخيارات بعد التحميل الأول والتحديث

أ) في render()، بعد الحلقة التي تملأ itemsCount عند السطور 10315–10317، أضف السطر التالي مباشرة قبل hideLoader():

~~~javascript
    _populateSourceFilter();
~~~

ب) في _refreshData()، بعد الحلقة التي تملأ itemsCount عند السطور 11066–11068، أضف السطر التالي مباشرة قبل _applyFilters():

~~~javascript
    _populateSourceFilter();
~~~

ج) في _showWithoutRS()، أضف السطر التالي كأول سطر داخل الدالة حتى لا يبقى زر العمليات ظاهرًا كأنه مفعّل بعد اختيار وضع «بدون رانشيت»:

~~~javascript
        _setOperationsOnly(false);
~~~

د) في كائن الإرجاع في نهاية RW_Orders، أضف الخاصية التالية بجوار _applyFilters:

~~~javascript
        _toggleOperationsOnly: _toggleOperationsOnly,
~~~

## الاختبارات المطلوبة بعد التطبيق

1. افتح أوردرات المبيعات وتأكد من ظهور فلتر «المصدر» وزر «أوردرات عمليات».
2. تحقق أن مصدر online_store يظهر للمستخدم باسم «المتجر الإلكتروني».
3. اختر كل مصدر على حدة؛ يجب أن تتطابق النتائج مع قيمة source بعد تطبيع المسافات والشرطة السفلية.
4. فعّل «أوردرات عمليات»: يجب أن تظهر فقط الأوردرات ذات المصدر telesales/tele-sales/order-taker/online-store، والحالة Confirmed أو Pending، وrunsheet_id فارغ.
5. تأكد أن أوردرات POS وVan Sales والحالات Invoiced/Delivered/Cancelled والأوردرات المرتبطة برانشيت لا تظهر ضمن «أوردرات عمليات».
6. اجمع فلتر المصدر مع التاريخ والعميل والحالة والمنطقة والرانشيت؛ يجب أن تعمل الفلاتر كتقاطع.
7. اضغط «إعادة تعيين»؛ يجب مسح كل الحقول وإلغاء وضع أوردرات العمليات.
8. تحقق من الفرز، تفاصيل الأوردر، checkbox، إنشاء رانشيت، ضم لرانشيت مفتوح، «بدون رانشيت»، تحديث 30 ثانية وRealtime.
9. افتح شاشة تسويق الصنف في النظام الأم وتأكد أن حقل كمية العرض ونص الشارة يظهران ويُحفظان دون خطأ بعد PATCH 0.
10. لا تنشئ أوردرات إنتاج تجريبية. اختبر على البيانات الموجودة أو بيئة معزولة، ثم تحقق من عدم وجود أي أثر اختبار.

## حدود الإثبات

- Verified: Git source SHA/commit، موضع الخلل في السطر 5543، مواضع فلاتر RW_Orders، عقد أهلية الرانشيت في Production، ACL، أعداد مصادر Production، مصدر online_store من المتجر.
- Not verified: أن المالك طبّق التعديلات، أن الواجهة نُشرت، أو أن Browser E2E نجح.
- No Production changes: لم تُجرَ أي تغييرات على قاعدة البيانات أو Edge Functions أو RPCs أو ACL.
- No operational file changes: لم أعدّل main.html أو store/index.html.

## SELF-AUDIT FINAL

- What I Proved: Current main.html SHA e8c163e1856bc9cd0ca88eff6c2a2fed1b091b36، commit HEAD 16511abe1af392c0e9cb55bc9bd204d23f46e0e3، وparent 3109c5d38fd151c8f3e349add15875cf21713bf9؛ السطر 5543 يحتوي fragment مكررًا؛ فلاتر المصدر والعمليات غير موجودة؛ Production يسمح فقط بالمصادر والحالات المحددة؛ المصدر online_store موجود حيًا.
- What I Did Not Prove: نشر الواجهة أو نجاح اختبار متصفح بعد التعديل.
- What I Fixed: لم أعدل الملفات التشغيلية أو Production؛ جهزت التعديلات الجراحية المحددة ليطبقها المالك.
- What I Initially Missed: رسالة commit الأخيرة ركزت على store_display_qty لكن المقارنة أثبتت أنها عدلت main.html أيضًا وأدخلت fragment مكررًا في سطر الشارة.
- What Could Still Be Wrong: لا يمكن إثبات runtime behavior قبل تطبيق المالك ونشر الملف واختباره.
- Final Confidence: مرتفع في التشخيص والعقد؛ غير مثبت في runtime.
- Final Closure Status: OWNER PATCHES READY / PRODUCTION CONTRACT VERIFIED / DEPLOYMENT + BROWSER E2E OPEN.
- Next exact step: يطبق المالك PATCH 0 ثم PATCH 1–8 على SHA e8c163e1856bc9cd0ca88eff6c2a2fed1b091b36 فقط، ويختبر، ثم تُحدّث الحالة من نتيجة المتصفح المنشور.
