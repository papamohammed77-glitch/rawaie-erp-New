# Report400 — إصلاح تكامل بيانات POS والبحث عن الأصناف
**التاريخ:** 2026-10-10  
**النطاق:** `erp-frontend/companies/company-1/sales/pos.html` + Supabase Production `fiilmooggumokxanwiyx`  
**حدود التعديل:** لم أعدّل `main.html` أو `core.js` أو `pos.html`. نُشرت RPC في Production ووُثقت هجرتها؛ تغييرات الواجهة أدناه جراحية ليطبقها المالك على ملف الواجهة التشغيلي.

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** POS يحتاج فهرس الأصناف، العملاء، أرصدة الفرع المختار، قائمة الفروع المصرح بها، والعملة، مع إتمام البيع عبر المسار المركزي الموجود.
- **Architecture Understanding:** POS → authenticated Supabase RPC → PostgreSQL. لا حاجة إلى Edge Function جديدة، ولا إلى تعديل عقد البيع المركزي.
- **Database Understanding:** جداول `items` و`customers` و`stock_branches` لا تسمح لمستخدم `pos` فقط بالقراءة المباشرة وفق RLS الحالي. جدول `branches` له عقد قراءة مختلف؛ `get_pos_branches()` هو الإصلاح السابق المطبق في المصدر.
- **Historical Understanding:** Report398/399 مرجعان استرشاديان. تمت إعادة قراءة Production وCurrent Git في هذه الدورة؛ لا أعتبر هذين التقريرين بديلًا عن الفحص الحي.
- **Production Understanding:** جرى فحص السياسات والـRPC المنشورة، ثم نشر `get_pos_bootstrap_data()` والتحقق من ACL ونتيجتها بهوية cashier.
- **Current Understanding:** الملف التشغيلي الحالي `companies/company-1/sales/pos.html`، Git blob SHA `7ddd87f06b1ee9244b449b4d5a39630d359b87d1`، commit `83cf87b8a856b151aff6d37dfc4e4a2cddcdf7aa`. يحتوي بالفعل على استدعاء `get_pos_branches()` داخل `self.syncDown`، فلا تعِد إصلاح ذلك.
- **Execution Confidence:** مرتفع في عيب RLS وعمل RPC في اختبار قاعدة البيانات؛ واجهة المتصفح والنشر الأمامي واختبار البيع الكامل لم تثبت بعد.

## 1. أدلة Production الحالية

وقت الفحص: `2026-10-10 01:07:24 UTC` وما بعده مباشرة.

1. `items_select_company` يشترط صلاحية `items` أو `warehouse`; لا يذكر `pos`.
2. `customers_select_company` يشترط `customers`; لا يذكر `pos`.
3. `stock_branches_select_company` يشترط `warehouse` أو `runsheets` أو `reports`; وسياسات المبيعات الأخرى تخص `telesales/orders/van-sales` ولا تشمل `pos`.
4. لذلك فإن استدعاءات `supabase.from('customers').select('*')`, `supabase.from('items').select('*')`, و`supabase.from('stock_branches').select('*')` لا تمثل عقدًا صالحًا لكاشير POS-only. `self.syncDown` يتحقق من الأخطاء الآن، ولذلك قد يفشل التحديث ويُبقي Cache قديمًا بدل أن يمسحه؛ هذا أفضل من إتلاف Cache لكنه لا يكمل التكامل.
5. المصدر الحالي يحتوي بالفعل `supabase.rpc('get_pos_branches')`؛ التغيير السابق وصل إلى Git في commit `83cf87b8a856b151aff6d37dfc4e4a2cddcdf7aa`.
6. جدول `items` في Production: 17 صفًا، كلها `is_active=true` و`show_in_store=true` وقت الفحص.
7. `save_sales_invoice_atomic(jsonb,jsonb,text,text)` موجودة وتتحقق من `operation_id` وتختار الفرع داخل الشركة؛ لا يوجد دليل يستدعي تغيير عقد البيع المركزي في هذه المهمة.

## 2. الإصلاح المنفذ في Production

- **RPC:** `public.get_pos_bootstrap_data()`
- **Migration:** `supabase/migrations/20261010_pos_authenticated_bootstrap_rpc.sql`
- **السلوك:** تتحقق من هوية `auth.uid()` وصلاحية `pos` وسياق الشركة، ثم تعيد customers/items للشركة نفسها، ومخزون الفروع المسموح بها فقط عبر `get_pos_branches()`, وقائمة الفروع المصرح بها، وملخص الأكثر مبيعًا، وعملة الشركة.
- **الأمان:** `SECURITY DEFINER`, و`search_path='' `, مراجع مؤهلة بالمخطط، `PUBLIC/anon EXECUTE=false`, `authenticated EXECUTE=true`, `service_role EXECUTE=true`.
- **اختبار Production بــ JWT subject للكاشير** `8dbcede3-3a94-40c6-a6c9-7d500f127f4a`: أعادت RPC فرع `BR-01 / الفرع الرئيسي` فقط، و17 صنفًا، و3 عملاء، و17 صف مخزون، و11 سجلًا لملخص الأكثر مبيعًا، والعملة `SAR`.
- هذا اختبار دالة في سياق هوية مصطنع داخل قاعدة البيانات، **وليس** اختبار HTTP أو متصفح.
- لم تتغير صفوف الفروع أو الأصناف أو المخزون أو الأوردرات أو القيود المحاسبية أثناء هذا الاختبار.

## 3. التعديل الجراحي الأول — `self.syncDown`

**الملف:** `papamohammed77-glitch/erp-frontend/companies/company-1/sales/pos.html`  
**Blob الحالي:** `7ddd87f06b1ee9244b449b4d5a39630d359b87d1`  
**الدالة:** `self.syncDown`  
**محدد البحث الدقيق:** `self.syncDown = function() {`  
**الإجراء:** استبدل جسم الدالة بالكامل بالبديل التالي. لا تغيّر بقية الملف.

```javascript
self.syncDown = function() {
    if (!db) return Promise.reject(new Error('قاعدة البيانات المحلية غير مهيأة'));

    return supabase.rpc('get_pos_bootstrap_data').then(function(result) {
        if (result.error) {
            throw new Error('فشل تحميل بيانات نقطة البيع: ' + result.error.message);
        }

        var payload = result.data;
        if (!payload ||
            !Array.isArray(payload.customers) ||
            !Array.isArray(payload.items) ||
            !Array.isArray(payload.stock) ||
            !Array.isArray(payload.branches) ||
            !Array.isArray(payload.fast_selling)) {
            throw new Error('استجابة بيانات نقطة البيع غير مكتملة أو غير صالحة');
        }

        var customers = payload.customers;
        var items = payload.items;
        var stock = payload.stock;
        var branches = payload.branches;

        return db.transaction('rw', db.customers, db.items, db.stock, db.branches, function() {
            return db.customers.clear()
                .then(function() { return customers.length ? db.customers.bulkPut(customers) : undefined; })
                .then(function() { return db.items.clear(); })
                .then(function() { return items.length ? db.items.bulkPut(items) : undefined; })
                .then(function() { return db.stock.clear(); })
                .then(function() { return stock.length ? db.stock.bulkPut(stock) : undefined; })
                .then(function() { return db.branches.clear(); })
                .then(function() { return branches.length ? db.branches.bulkPut(branches) : undefined; });
        }).then(function() {
            customersCache = customers;
            productsCache = items;
            fastSellingCache = payload.fast_selling;
            if (payload.currency) currency = payload.currency;
            return {
                success: true,
                offline: false,
                branchCount: branches.length,
                itemCount: items.length,
                customerCount: customers.length
            };
        });
    });
};
```

**الأثر المتوقع:** استدعاء واحد مصادق عليه بدل ثلاثة استدعاءات مباشرة لا تسمح بها RLS، مع بقاء تحديث Dexie داخل معاملة واحدة؛ إذا فشل RPC أو كانت الاستجابة غير مكتملة، لا تُمسح الجداول المحلية.

## 4. التعديل الجراحي الثاني — متغير Cache الأكثر مبيعًا

**محدد البحث الدقيق:** `var productsCache = [], customersCache = [];`  
**الإجراء:** استبدل السطر وحده بـ:

```javascript
var productsCache = [], customersCache = [], fastSellingCache = [];
```

## 5. التعديل الجراحي الثالث — `self.loadFastSelling`

**محدد البحث:** `self.loadFastSelling = function() {`  
**الإجراء:** استبدل الدالة كاملة؛ الاستعلام المباشر الحالي على `order_details` لا تسمح به سياسة القراءة لكاشير POS-only.

```javascript
self.loadFastSelling = function() {
    var items = Array.isArray(fastSellingCache) ? fastSellingCache : [];
    var map = {};

    for (var i = 0; i < items.length; i++) {
        var code = items[i].item_code;
        if (!code) continue;
        if (!map[code]) map[code] = { name: items[i].item_name || code, count: 0 };
        map[code].count++;
    }

    var arr = [];
    for (var key in map) {
        if (Object.prototype.hasOwnProperty.call(map, key)) {
            arr.push({ code: key, name: map[key].name, count: map[key].count });
        }
    }

    arr.sort(function(a, b) { return b.count - a.count; });
    arr = arr.slice(0, 8);

    var html = '';
    for (var j = 0; j < arr.length; j++) {
        html += '<button onclick="POS.addToCart(\'' +
            String(arr[j].code).replace(/\\/g, '\\\\').replace(/'/g, "\\\'") +
            '\')" class="whitespace-nowrap bg-slate-800 text-slate-300 px-3 py-1.5 rounded-full text-xs font-bold border border-slate-600 hover:bg-slate-700 transition">' +
            String(arr[j].name).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;') +
            '</button>';
    }

    RW_UI.safeHTML(
        RW_UI.byId('fastSellingItems'),
        html || '<span class="text-slate-500">لا توجد مبيعات اليوم</span>'
    );
};
```

## 6. التعديل الجراحي الرابع — البحث الفعلي عن الأصناف

**محدد البحث:** `self._searchProducts = function(q) {`  
**السبب المثبت:** البحث الحالي لا يطبق فلتر التصنيف، ولا يبحث في `search_label`، ولا يشترط اختيار فرع قبل حساب المتاح؛ وقد يعرض في نتائج البحث رصيدًا مجمعًا من فروع أخرى. كما لا يعالج فشل قراءة Dexie أو نتيجة بحث قديمة تصل بعد نتيجة أحدث.

**الإجراء:** استبدل الدالة كاملة بالبديل التالي:

```javascript
self._searchProducts = function(q) {
    var grid = RW_UI.byId('productsGrid');
    if (!grid) return;

    if (!db) {
        RW_UI.safeHTML(grid, '<div class="col-span-full text-center text-red-400 py-10">قاعدة بيانات الأصناف غير متاحة</div>');
        return;
    }

    var query = String(q || '').trim().toLowerCase();
    if (!query) {
        self.renderProducts();
        return;
    }

    var branchAtSearch = selBranch;
    var categoryAtSearch = activeCategory;
    var input = RW_UI.byId('posSearch');

    if (!branchAtSearch || !branchMap[branchAtSearch]) {
        RW_UI.safeHTML(grid, '<div class="col-span-full text-center text-amber-400 py-10">اختر الفرع أولاً لعرض الأصناف ورصيدها الصحيح</div>');
        return;
    }

    db.items.toArray().then(function(items) {
        var matches = [];

        for (var i = 0; i < items.length; i++) {
            var item = items[i];
            if (!item || !item.item_code) continue;

            if (categoryAtSearch && categoryAtSearch !== 'الكل' &&
                (item.category || 'أخرى') !== categoryAtSearch) continue;

            var name = String(item.name || '').toLowerCase();
            var code = String(item.item_code || '').toLowerCase();
            var barcode = String(item.barcode || '').toLowerCase();
            var searchLabel = String(item.search_label || '').toLowerCase();

            if (name.indexOf(query) !== -1 ||
                code.indexOf(query) !== -1 ||
                barcode.indexOf(query) !== -1 ||
                searchLabel.indexOf(query) !== -1) {
                matches.push(item);
                if (matches.length >= 20) break;
            }
        }

        if (input && String(input.value || '').trim().toLowerCase() !== query) return;
        if (selBranch !== branchAtSearch || activeCategory !== categoryAtSearch) return;

        if (!matches.length) {
            RW_UI.safeHTML(grid, '<div class="col-span-full text-center text-slate-500 py-10">🔍 لا توجد نتائج مطابقة في هذا الفرع والتصنيف</div>');
            return;
        }

        return Promise.all(matches.map(function(item) {
            return self.getAvail(item.id);
        })).then(function(avails) {
            if (input && String(input.value || '').trim().toLowerCase() !== query) return;
            if (selBranch !== branchAtSearch || activeCategory !== categoryAtSearch) return;

            var html = '';
            for (var j = 0; j < matches.length; j++) {
                html += self._productCard(matches[j], avails[j]);
            }
            RW_UI.safeHTML(grid, html);
        });
    }).catch(function(err) {
        console.error('POS item search failed:', err);
        RW_UI.safeHTML(grid, '<div class="col-span-full text-center text-red-400 py-10">تعذر البحث عن الأصناف؛ لم تُغيّر بيانات البيع</div>');
    });
};
```

## 7. لماذا لم أعدّل الملف التشغيلي؟

حسب قاعدة الدمج المعتمدة، المالك هو من يدمج جراحة الواجهة. لم أعدّل `pos.html` أو `main.html` أو `core.js`. تم تنفيذ تغيير Production الذي يقع ضمن نطاقي، وتوثيق النصوص الكاملة البديلة ومحددات البحث لتطبيقها دون تخمين.

## 8. الاختبارات

| الاختبار | النتيجة |
|---|---|
| RLS policies للأصناف والعملاء والمخزون | **VERIFIED:** لا تمنح POS-only القراءة المباشرة المطلوبة |
| RPC موجودة في Production | **VERIFIED** |
| ACL | **VERIFIED:** anon=false، authenticated=true، service_role=true |
| محاكاة JWT subject للكاشير داخل DB | **VERIFIED:** branch_count=1، BR-01 فقط، 17 صنفًا، 3 عملاء، 17 stock rows |
| currency من بيانات الشركة | **VERIFIED:** SAR |
| fast-selling payload | **VERIFIED:** 11 سجلًا في لقطة الاختبار |
| دمج جراحة الواجهة | **PENDING — owner-side merge** |
| نشر الواجهة والتحقق من Cloudflare/service-worker artifact | **PENDING** |
| اختبار متصفح مصادق عليه للبحث/الإضافة للسلة/البيع | **PENDING** |
| HTTP E2E فعلي إلى Edge ثم RPC/Core | **PENDING** |
| استعادة Baseline بعد E2E | **PENDING**؛ لم تُنشأ بيانات تجريبية ولم تُغيّر بيانات تجارية |

## SELF-AUDIT FINAL

- **What I Proved:** سياسات RLS تمنع مسار التحميل المباشر لمستخدم POS-only؛ RPC الجديدة تعمل في سياق هوية الكاشير وتعيد البيانات ضمن نطاق الشركة والفروع المسموح بها.
- **What I Did Not Prove:** اختبار HTTP حقيقي، تشغيل واجهة المتصفح بعد دمج النصوص، تكافؤ artifact المنشور مع Git، أو نجاح فاتورة POS كاملة.
- **What I Fixed:** نشرت `get_pos_bootstrap_data()` بصلاحيات تنفيذ مقيدة، ووثقت migration، وجهزت أربعة تعديلات جراحية دقيقة للواجهة.
- **What I Initially Missed:** إصلاح قائمة الفروع وحده لا يكفي؛ قراءات items/customers/stock وملخص الأكثر مبيعًا لها سياسات RLS مستقلة لا تمنح POS-only حق القراءة.
- **What Could Still Be Wrong:** قد تكشف اختبارات المتصفح اختلافًا في سلوك Dexie أو cache/service worker أو في عقد الاستجابة بين Git والنسخة المنشورة.
- **Final Confidence:** مرتفع في السبب وRPC/ACL/DB simulation؛ متوسط في جراحة الواجهة إلى أن تُدمج وتُختبر فعليًا.
- **Final Closure Status:** `PRODUCTION RPC DEPLOYED / OWNER FRONTEND SURGERY PENDING / BROWSER & HTTP E2E PENDING / NOT CLOSED`.
