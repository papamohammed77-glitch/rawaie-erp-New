# Report420 — إضافة فلاتر المصدر والمنشئ إلى جدول أوردرات المبيعات

**التاريخ:** 2026-10-13  
**النطاق الوحيد:** `RW_Orders` داخل `erp-frontend/companies/company-1/main.html`.  
**ملكية التطبيق:** لم يتم تعديل `main.html` أو أي تطبيق تشغيلي؛ المالك يطبق التغيير الجراحي.  
**قاعدة Production:** `SMART ERP / fiilmooggumokxanwiyx` — فحص قراءة فقط، دون تعديل بيانات أو بنية.

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** المطلوب إضافة فلترين علويين لجدول أوردرات المبيعات: المصدر والمنشئ، مع استمرار عمل الفلاتر الموجودة، الفرز، اختيار الأوردرات المؤهلة للرانشيت، التحديث الدوري وRealtime.
- **Architecture Understanding:** الفلترة محلية على `ordersData` التي يجلبها `RW_Orders` من جدول `orders` للشركة الحالية. هذا تعديل واجهة فقط؛ لا يحتاج Edge Function أو RPC جديدًا.
- **Database Understanding:** الأعمدة الحية موجودة في `public.orders`: `source` و`created_by`.
- **Historical Understanding:** `CURRENT_STATE.md` وتقارير Report418/419 كانت تشير إلى نقص تسمية `van-sales`، لكن فحص المصدر الفعلي الحالي يثبت أن التسمية موجودة بالفعل. لا تعِد تطبيق هذا الإصلاح.
- **Production Understanding:** فحص SQL للقراءة فقط في `2026-10-12 21:53:53.461163+00 UTC` أعاد 9 أوردرات، 3 قيم مصدر متميزة و3 قيم منشئ متميزة، دون أي قيمة مصدر أو منشئ فارغة. توزيع المصدر: `order-taker=4`، `pos=3`، `telesales=2`. لم تتغير البيانات.
- **Current Understanding:** جرى جلب محتوى الملف الحالي من GitHub عبر blob SHA `a192704e07d984fdbecd00ce40a73e95fa806a7e`؛ 1,762,271 حرفًا و32,437 سطرًا عند التقسيم البرمجي. آخر commit تعديل مباشر ظاهر للملف هو `27e6687b2101a9efb91c6fb65a1ae218096679e7` بتاريخ `2026-10-12 21:39:56 UTC`، وتغييره تنسيق كائن `sourceLabel` فقط.
- **Execution Confidence:** مرتفع في مصدر Git الحالي ومخطط/عينة Production. لم يُنفّذ Browser E2E لأن دور المالك هو تطبيق ملف الواجهة ونشره.

## ما ثبت من المصدر الحالي

1. الفلاتر الحالية عند السطور 10230–10241 هي: من تاريخ، إلى تاريخ، العميل، الحالة، المنطقة، الرانشيت. لا يوجد فلتر مصدر أو منشئ.
2. `_applyFilters()` لا يقرأ `source` أو `created_by` حاليًا.
3. `_resetFilters()` يعيد تعيين ستة عناصر فقط.
4. عمودا المصدر والمنشئ موجودان بالفعل في الجدول، وكذلك تسمية `van-sales` إلى «بيع مباشر». لا تغيّر الأعمدة ولا أهلية الرانشيت.
5. `_refreshData()` يعيد تحميل `ordersData`؛ يجب إعادة بناء خيارات الفلترين بعد كل تحديث كي لا تبقى الخيارات قديمة عند وصول مصدر أو منشئ جديد.

## التعديل الجراحي

### 1. إضافة عنصرَي المصدر والمنشئ إلى شبكة الفلاتر

- **الملف:** `erp-frontend/companies/company-1/main.html`
- **الوحدة:** `RW_Orders.render()`
- **الموضع الحالي:** السطور 10230–10241.
- **محدد البحث:** داخل `var RW_Orders = (function() {` ابحث عن:
  `'<div class="grid grid-cols-2 md:grid-cols-6 gap-2">' +`
- **الإجراء:** استبدل كتلة شبكة الفلاتر كاملة حتى إغلاق الشبكة مباشرة قبل إغلاق بطاقة الفلاتر. لا تحذف أزرار التحديث/بدون رانشيت/إعادة تعيين.

```javascript
            '<div class="grid grid-cols-2 md:grid-cols-4 xl:grid-cols-8 gap-2">' +
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
                '<select id="f-source" onchange="RW_Orders._applyFilters()" class="p-2 bg-gray-50 rounded text-sm">' +
                    '<option value="">كل المصادر</option>' +
                '</select>' +
                '<select id="f-creator" onchange="RW_Orders._applyFilters()" class="p-2 bg-gray-50 rounded text-sm">' +
                    '<option value="">كل المنشئين</option>' +
                '</select>' +
            '</div>' +
```

### 2. إضافة دالة آمنة لتعبئة الخيارات من بيانات الشركة الحالية

- **الموضع:** مباشرة قبل التعليق `// ========== الفلترة والفرز ==========` (حاليًا قرب السطر 10378).
- **الإجراء:** أدرج الدالة التالية كاملة دون حذف الدوال المجاورة:

```javascript
    function _populateSourceCreatorFilters() {
        var sourceEl = byId('f-source');
        var creatorEl = byId('f-creator');
        var sourceLabels = {
            'pos': 'كاشير / POS',
            'telesales': 'تلي سيلز',
            'tele-sales': 'تلي سيلز',
            'order-taker': 'أوردر تيكر',
            'online-store': 'المتجر الإلكتروني',
            'van-sales': 'بيع مباشر'
        };

        function normalizedSource(value) {
            return String(value || '').trim().toLowerCase().replace(/[ _]+/g, '-');
        }

        function refill(selectEl, values, labelForValue) {
            if (!selectEl) return;
            var selectedValue = selectEl.value;
            while (selectEl.options.length > 1) selectEl.remove(1);

            values.forEach(function(value) {
                var option = document.createElement('option');
                option.value = value;
                option.textContent = labelForValue ? labelForValue(value) : value;
                selectEl.appendChild(option);
            });

            selectEl.value = values.indexOf(selectedValue) !== -1 ? selectedValue : '';
        }

        var sourceSet = {};
        var creatorSet = {};
        ordersData.forEach(function(order) {
            var source = normalizedSource(order.source);
            var creator = String(order.created_by || '').trim();
            if (source) sourceSet[source] = true;
            if (creator) creatorSet[creator] = true;
        });

        var sources = Object.keys(sourceSet).sort();
        var creators = Object.keys(creatorSet).sort(function(a, b) {
            return a.localeCompare(b, 'ar');
        });

        refill(sourceEl, sources, function(source) {
            return sourceLabels[source] || source;
        });
        refill(creatorEl, creators);
    }
```

عناصر الخيارات تُنشأ عبر `textContent` لا عبر تركيب HTML من قيم قاعدة البيانات.

### 3. استبدال دالة الفلترة كاملة

- **الدالة:** `_applyFilters()`
- **محدد البحث:** ابحث عن `function _applyFilters() {` داخل وحدة `RW_Orders`.
- **الإجراء:** استبدل الدالة كاملة حتى قوسها الختامي مباشرة قبل `function _resetFilters()` بالنص التالي:

```javascript
    function _applyFilters() {
        var filtered = ordersData.slice();
        var fdEl = byId('f-date-from'), tdEl = byId('f-date-to'), custEl = byId('f-cust'),
            stEl = byId('f-status'), areaEl = byId('f-area'), rsEl = byId('f-rs'),
            sourceEl = byId('f-source'), creatorEl = byId('f-creator');

        var fd = fdEl ? fdEl.value : '';
        var td = tdEl ? tdEl.value : '';
        var cust = custEl ? (custEl.value || '').toLowerCase() : '';
        var st = stEl ? stEl.value : '';
        var area = areaEl ? (areaEl.value || '').toLowerCase() : '';
        var rs = rsEl ? (rsEl.value || '').toLowerCase() : '';
        var source = sourceEl ? sourceEl.value : '';
        var creator = creatorEl ? creatorEl.value : '';

        if (fd) filtered = filtered.filter(function(o) { return o.order_date >= fd; });
        if (td) filtered = filtered.filter(function(o) { return o.order_date <= td; });
        if (cust) filtered = filtered.filter(function(o) { return (o.customer_name || '').toLowerCase().indexOf(cust) !== -1; });
        if (st) filtered = filtered.filter(function(o) { return o.order_status === st; });
        if (area) filtered = filtered.filter(function(o) { return (o.area || '').toLowerCase().indexOf(area) !== -1; });
        if (rs) filtered = filtered.filter(function(o) { return String(o._runsheetCode || '').toLowerCase().indexOf(rs) !== -1; });
        if (source) filtered = filtered.filter(function(o) {
            return String(o.source || '').trim().toLowerCase().replace(/[ _]+/g, '-') === source;
        });
        if (creator) filtered = filtered.filter(function(o) {
            return String(o.created_by || '').trim() === creator;
        });

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
```

### 4. استبدال قائمة إعادة التعيين

- **الدالة:** `_resetFilters()`
- **محدد البحث:** ابحث عن `function _resetFilters() {`.
- **الإجراء:** استبدل الدالة كاملة بالنص التالي:

```javascript
    function _resetFilters() {
        var ids = ['f-date-from', 'f-date-to', 'f-cust', 'f-status', 'f-area', 'f-rs', 'f-source', 'f-creator'];
        for (var i = 0; i < ids.length; i++) {
            var el = byId(ids[i]);
            if (el) el.value = '';
        }
        _applyFilters();
    }
```

### 5. مزامنة الخيارات مع التحميل والتحديث اللحظي

**أ. داخل `render()`:** بعد انتهاء الحلقة التي تملأ `itemsCount` مباشرة، وقبل `hideLoader();` عند السطر الحالي 10316، أضف:

```javascript
    _populateSourceCreatorFilters();
```

**ب. داخل `_refreshData()`:** بعد انتهاء الحلقة التي تملأ `ordersData[j].itemsCount` مباشرة، وقبل `_applyFilters();` قرب السطر 11067، أضف:

```javascript
    _populateSourceCreatorFilters();
```

بهذا تُحدّث القائمتان بعد التحميل الأول وبعد Refresh/Realtime، مع الاحتفاظ بالاختيار السابق إذا بقيت قيمته موجودة.

## ما لا يجب تغييره

- لا تغيّر `sourceLabel` الحالي؛ `van-sales: بيع مباشر` موجود بالفعل في المصدر.
- لا تغيّر شروط أهلية الرانشيت أو RPC/Edge Functions أو ACL.
- لا تنشئ أوردرات تجريبية في Production؛ العينة الحالية كافية لاختبار الفلترة يدويًا دون كتابة بيانات.
- لا تعدّل قاعدة البيانات؛ لا يوجد Defect Production مثبت في هذه المهمة.

## اختبار المالك بعد التطبيق

1. افتح تبويب أوردرات المبيعات وتأكد من ظهور «كل المصادر» و«كل المنشئين».
2. تحقق أن خيارات المصدر والمنشئ تطابق القيم الموجودة في أوردرات الشركة الحالية.
3. اختر `telesales` وتأكد أن النتائج كلها من هذا المصدر؛ كرر مع `pos` و`order-taker`.
4. اختر منشئًا وتأكد أن كل النتائج تطابق `created_by` المحدد.
5. اجمع فلتر المصدر مع الحالة أو التاريخ أو العميل؛ يجب أن تتقاطع الشروط.
6. اضغط «إعادة تعيين» وتأكد من رجوع الفلاتر الثمانية إلى الحالة الافتراضية.
7. حدّث أوردرًا عبر المسار التشغيلي المعتاد، ثم تحقق من تحديث الخيارات والنتائج بعد Realtime أو التحديث الدوري.
8. تأكد أن الفلاتر لم تغيّر اختيار الرانشيت أو زر «بدون رانشيت» أو الفرز أو تفاصيل الأوردر.

## SELF-AUDIT FINAL

- **What I Proved:** موضع الفلاتر الحالية؛ وجود المصدر والمنشئ كأعمدة؛ وجود `source` و`created_by` في Production؛ 9 أوردرات حالية بثلاث قيم لكل من المصدر والمنشئ؛ أن `van-sales` label موجود بالفعل.
- **What I Did Not Prove:** تطبيق المالك للتعديل، نشر الملف، أو نجاح Browser E2E بعد النشر.
- **What I Fixed:** لم أعدل `main.html` أو Production؛ أعددت Change Set جراحيًا يشمل الواجهة والفلترة وإعادة التعيين ومزامنة الخيارات.
- **What I Initially Missed:** `CURRENT_STATE.md` وتقارير 418/419 كانت متأخرة عن تعديل المصدر؛ فحص Git الحالي يثبت أن تسمية `van-sales` أُضيفت بالفعل في commit `27e6687b2101a9efb91c6fb65a1ae218096679e7`.
- **What Could Still Be Wrong:** لا يمكن إثبات سلوك المتصفح أو الملف المنشور قبل تطبيق المالك واختباره.
- **Final Confidence:** مرتفع في تشخيص المصدر وعقد البيانات؛ غير مثبت في Browser E2E/النشر.
- **Final Closure Status:** `SURGICAL CHANGESET READY / OWNER APPLICATION + SERVED BROWSER E2E OPEN`.
- **Next exact step:** يطبق المالك التغييرات الخمسة أعلاه على `main.html`، ثم ينشر ويختبر؛ بعدها تُحدّث حالة المشروع بالأدلة الفعلية.
