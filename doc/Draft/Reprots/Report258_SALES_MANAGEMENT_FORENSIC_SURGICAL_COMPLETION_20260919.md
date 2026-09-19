# تقرير 258 — الإكمال الجراحي لتبويب إدارة المبيعات
**التاريخ:** 2026-09-19  
**النطاق:** إدارة المبيعات وتبويباتها الفرعية فقط  
**Mother main.html:** لم يُعدّل في المستودع.

## 1) قاعدة الحقيقة المعتمدة

- System repo: `papamohammed77-glitch/rawaie-erp-New`
- System HEAD عند بدء الجلسة: `25a0aaffb011edea6000ed7cc596b0c193000d51`
- System parent: `a444293af0dc1b9fc550596cb95d3ae8300e9c77`
- Mother repo: `papamohammed77-glitch/erp-frontend`
- Mother HEAD: `b999145eaf6faef295f4ce7437db07d18da7e8dd`
- Mother parent: `492a2bc81df5b85d6691833689073612c47367b1`
- Current Mother main.html blob: `638aa5745aa8f11cb20bf74102a1fd701073a348`
- Current Mother main.html: 29,244 lines.
- Current Production project: `fiilmooggumokxanwiyx`

التقارير السابقة استُخدمت كـhistorical evidence فقط. لم تُعتبر أرقامها أو حالاتها Production current.

## 2) Production snapshot — لحظة التحقيق

| العنصر | Production الحالي |
|---|---:|
| companies | 1 |
| active branches | 2 |
| active items | 16 |
| stock rows | 20 |
| inventory_log | 3 |
| orders | 0 |
| order_details | 0 |
| sales_quotes | 0 |
| commercial_catalogs | 0 |
| promotions | 0 |
| payment_receipts | 0 |
| payment_allocations | 0 |
| return_reviews | 0 |
| sales_target_plans | 0 |
| loyalty_programs | 0 |
| loyalty_transactions | 0 |

**قاعدة:** هذه هي الحالة الحالية؛ كل أرقام سابقة مختلفة عن ذلك تاريخية فقط.

## 3) التحقيق الجنائي — ما ثبت فعلاً

### 3.1 Mother navigation
الموضع الحالي: `Current/PWA/main.html`، lines 1488–1502.
إدارة المبيعات موجودة، لكن **لا يوجد route لمركز موحد لإدارة المبيعات**؛ العناصر الحالية تشمل Telesales, Customers, Online Store, POS, Orders, Quotes, Price Lists, Promotions, Decision Center, Targets, Loyalty, Runsheets, Sales Returns.

### 3.2 Mother dispatcher
الموضع الحالي: `RW_Views` يبدأ عند line 27026.
هناك routes فعلية لـ:
`orders`, `quotes`, `price-lists`, `promotions`, `sales-returns`, `loyalty`, `sales-decision-center`, `sales-targets`.
**لا يوجد route لـ`sales-management-center`.**

### 3.3 Current Mother heavy modals
ثبت وجود شاشات عمل كاملة داخل modals، وليس confirmations فقط:
- `RW_Orders._showDetails(code)` line 10151
- `RW_TeleSales._showNewCustomerForm()` line 9256
- `RW_SalesReturnsManagement._openDetail(id)` line 28067
- `RW_SalesQuotes.openEditor(quote)` line 28454
- `RW_SalesQuotes.detail(code)` line 28537
- `RW_PriceLists.openEditor(list)` line 28790
- `RW_PriceLists.assign(catalogId)` line 28847
- `RW_PriceLists.detail(id)` line 28859
- `RW_Promotions.showDetail(id)` line 29000
- `RW_Promotions.openEditor(id)` line 29017
- `RW_LoyaltyMain.newProgram()` line 4033
- `RW_LoyaltyMain.newReward()` line 4039

نوافذ التأكيد القصيرة مثل Confirm/Delete/Cancel لم تُحوّل إلى Pages؛ لأنها confirmation surfaces وليست work surfaces.

## 4) Production backend الحالي

### 4.1 Sales Management Center
`public.sales_management_center_read(company_id, actor_email, from_date, to_date)` موجود كـSECURITY DEFINER ومتاح للمستخدمين المصادق عليهم.

تم إصلاحه مباشرة في Production عبر migration:
`sales_management_center_read_integrity_and_analytics_20260919`

الإصلاحات المنفذة:
1. `decision_center.approved` أصبح `decision='ALLOW'` بدل `APPROVE`، لأن Production constraint الرسمي يسمح فقط:
   `ALLOW | WARN | REQUIRE_APPROVAL | BLOCK`.
2. `top_reps LIMIT 10` أصبح داخل الاستعلام قبل `jsonb_agg`، حتى يصبح الحد فعليًا.
3. أضيفت قراءة موحدة من نفس RPC لـ:
   - top_items
   - top_customers
   - branch_sales
   - payment_mix
   مع الإبقاء على order/quote/return/payment/runsheet/decision/commercial/targets/channels/recent_orders.

### 4.2 No new Edge Function
لم يُنشأ Edge جديد.
الـcenter يعتمد RPC مصادقًا عليه مباشرة، وهو مناسب لحد Functions/Spend Cap الحالي.

### 4.3 E2E database verification
تم إنشاء سيناريو بيع مؤقت داخل Transaction:
- Order Delivered
- Order Detail لصنف 1001
- Decision Evaluation بقيمة `ALLOW`
- استدعاء `sales_management_center_read`

الناتج الفعلي:
- total orders = 1
- sales_value = 500
- top item 1001 = qty 10 / value 500
- top customer = محمد حسن / 500
- branch sales = الفرع الرئيسي / 500
- decision approved = 1

ثم `ROLLBACK` كامل.
إعادة القراءة بعد rollback:
- orders = 0
- order_details = 0
- temp decision = 0

إذن Production لم تُلوث بالتجربة.

**مهم:** Browser E2E لم يُنفذ لأن أداة العمل الحالية لا توفر متصفحًا حقيقيًا للتشغيل. لذلك لا يُكتب Browser E2E PASS.

## 5) مقارنة تنافسية

### Odoo
Odoo يربط quotation → sales order → delivery → invoice → payment ضمن مسار متسق، وتدعم quotation حقول customer, delivery/invoicing, price lists, payment terms, deadlines, discounts وغيرها. كما أن pricelists تعمل حسب العميل/المجموعة/الطلب/الفترة الزمنية.  
Sources: https://www.odoo.com/documentation/18.0/applications/sales/sales/sales_quotations.html  
https://www.odoo.com/documentation/18.0/applications/sales/sales/products_prices/prices/pricing.html

### Dynamics 365
Dynamics يربط Quote/Order/Invoice ويعتمد Product Catalog + Price List + Currency + Quantity + Discounts، مع تاريخ استحقاق/صلاحية وتسليم، ويميز بين Current Pricing وPrices Locked.  
Sources: https://learn.microsoft.com/en-us/dynamics365/sales/create-edit-quote-sales  
https://learn.microsoft.com/en-us/dynamics365/sales/sales-transactions

### SAP
SAP يستخدم Sales Pricing Conditions لتخزين الأسعار والخصومات والرسوم والضرائب، ويمكن تخصيصها بالعميل/المادة/العملة والوحدة التنظيمية ثم نقلها إلى sales order/billing.  
Source: https://help.sap.com/docs/s4hana-cloud-best-practices/create-sales-pricing-condition-mds-bet/purpose

### Daftra
Daftra يجمع POS، Price Lists, Offers, Installments, Sales Targets & Commissions, Loyalty، وتقارير الأداء ضمن نطاق المبيعات.  
Source: https://www.daftra.com/en/sales/

### Manager.io
Manager يفصل بوضوح بين Sales Quotes وSales Invoices، ويربط quote/order/invoice عبر Copy to/Quote Number/Order Number، ويعطي تقارير مبيعات حسب العميل والصنف، مع دعم customer statements وcredit notes.  
Sources:
https://www2.manager.io/guides/7238
https://www2.manager.io/guides/7178
https://www2.manager.io/guides/36043
https://www2.manager.io/guides/12310

### الاستنتاج البنيوي المطبق على RAWAEA
الـgap الحقيقي ليس “غياب الأساسيات”؛ الأساسيات موجودة بالفعل. الفجوة الحالية هي:
**عدم وجود Mother Sales Command Page تجمع هذه المحركات وتعرض دورة المستند/القناة/الفرع/المندوب/الصنف/العميل/السداد/القرار في سطح قيادة واحد، مع بقاء التطبيقات التشغيلية المنفصلة هي صاحبة التنفيذ الميداني.**

## 6) مصفوفة المسؤوليات قبل/بعد

| المسؤولية | Historical | Current Production | Target بعد التعديل |
|---|---|---|---|
| Physical Stock | مركز Inventory | قائم | بدون تغيير |
| Reservation | reserve_stock | قائم | بدون تغيير |
| Sales Order | Orders + field apps | قائم | Mother command surface فقط |
| Runsheet | field apps | قائم | Mother visibility فقط |
| Quote | Quotes engine | قائم | Page بدل modal |
| Pricing | resolve pricing engine | قائم | Page فوق المحرك |
| Promotions | promotion engine | قائم | Page فوق المحرك |
| Payment | payment allocation engine | قائم | Visibility فقط |
| Returns | sales return engine | قائم | Page + review |
| Loyalty | loyalty engine | قائم | Page config |
| Targets | target engine | قائم | بدون إعادة بناء |
| Decision Center | decision engine | قائم | المركز الموحد يعرضه |
| Accounting | finance engine | قائم | بدون تغيير |

لا توجد Business Responsibility تم حذفها؛ التعديل المقترح للـMother يغير **presentation/orchestration surface** فقط.

# 7) التعديلات الجراحية الجاهزة للمالك

## PATCH-01 — إضافة مركز إدارة المبيعات إلى Navigation

**الملف:** `Current/PWA/main.html`  
**الأسطر الحالية:** 1488–1502  
**ابحث عن العنصر المحدد بالكامل:**

```
{ icon: 'fa-chart-line', label: 'إدارة المبيعات', submenu: [
    { view: 'sales-management-center', label: 'مركز إدارة المبيعات', perm: ['sales_manager','sales_supervisor','general_manager','reports'] },
    { view: 'telesales', label: 'التلي سيلز' },
    { view: 'customers', label: 'العملاء' },
    { view: 'online-store', label: 'المتجر الإلكتروني' },
    { view: 'pos', label: 'نقطة البيع' },
    { view: 'orders', label: 'أوردرات المبيعات' },
    { view: 'quotes', label: 'عروض الأسعار' },
    { view: 'price-lists', label: 'قوائم الأسعار' },
    { view: 'promotions', label: 'العروض والخصومات' },
    { view: 'sales-decision-center', label: 'مركز قرار المبيعات', perm: ['sales_manager','sales_supervisor','general_manager','reports'] },
    { view: 'sales-targets', label: 'أهداف المبيعات', perm: ['sales_manager','sales_supervisor','general_manager','reports'] },
    { view: 'loyalty', label: 'الولاء والمكافآت', perm: ['sales_manager','sales_supervisor','general_manager','reports','customers','pos','telesales','orders','van-sales'] },
    { view: 'runsheets', label: 'الرانشيتات' },
    { view: 'sales-returns', label: 'إدارة مرتجعات المبيعات' }
] }
```

**احذف الكتلة الحالية بالكامل واستبدلها بالكتلة أعلاه.**

---

## PATCH-02 — إضافة Icon

**الملف:** `Current/PWA/main.html`  
**ابحث عن السطر الحالي داخل object `viewIcons`:**

```
'sales-decision-center': 'fa-bullseye',
```

**استبدله بالكامل بـ:**

```
'sales-decision-center': 'fa-bullseye',
'sales-management-center': 'fa-gauge-high',
```

---

## PATCH-03 — RW_Views permission/title/route

**الملف:** `Current/PWA/main.html`  
**الكائن:** `var RW_Views = {`  
**بداية الكائن:** line 27026.

### PATCH-03-A — بعد `var c = byId('rw-page-container');`
ابحث عن بداية:
```
var permissionMap = {
```

وقبل:
```
var permKey = permissionMap[view];
```
أضف منطق الوصول التالي:

```
if (view === 'sales-management-center') {
    var salesUser = (typeof RW_STATE !== 'undefined' && RW_STATE && RW_STATE.app) ? RW_STATE.app.currentUser : null;
    var salesPerms = (salesUser && Array.isArray(salesUser.permissions)) ? salesUser.permissions : [];
    var salesAllowed = !!(salesUser && (
        salesUser.isOwner === true ||
        salesPerms.indexOf('*') !== -1 ||
        salesPerms.indexOf('sales_manager') !== -1 ||
        salesPerms.indexOf('sales_supervisor') !== -1 ||
        salesPerms.indexOf('general_manager') !== -1 ||
        salesPerms.indexOf('reports') !== -1
    ));
    if (!salesAllowed) {
        safeHTML(c, '<div class="rw-card" style="text-align:center;padding:60px 20px"><div style="font-size:64px;margin-bottom:20px">🔒</div><h2>غير مصرح</h2><p>ليس لديك صلاحية الوصول إلى مركز إدارة المبيعات</p></div>');
        return;
    }
}
```

### PATCH-03-B — titles
ابحث عن:
```
'orders':'أوردرات المبيعات',
```
واستبدله بـ:
```
'orders':'أوردرات المبيعات',
'sales-management-center':'مركز إدارة المبيعات',
```

### PATCH-03-C — route
ابحث عن:
```
if (view === 'orders') { RW_Orders.render(); return; }
```
واستبدله بـ:
```
if (view === 'orders') { RW_Orders.render(); return; }
if (view === 'sales-management-center') { RW_SalesManagementCenter.render(); return; }
```

---

## PATCH-04 — وحدة Mother الجديدة: Sales Management Center

**الملف:** `Current/PWA/main.html`  
**موضع الإدراج:** قبل العنصر الحالي:

```
var RW_SalesDecisionCenter = (function(){
```

**أدرج كامل الوحدة التالية قبل هذا السطر مباشرة:**

```
var RW_SalesManagementCenter = (function () {
    'use strict';

    var state = { timer: null, data: null };

    function esc(v) {
        return String(v == null ? '' : v)
            .replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;')
            .replace(/"/g,'&quot;').replace(/'/g,'&#39;');
    }

    function money(v) {
        return Number(v || 0).toLocaleString('ar-EG', { maximumFractionDigits: 2 });
    }

    function companyId() {
        if (typeof _rwCompanyId === 'function') return _rwCompanyId();
        if (typeof RW_STATE !== 'undefined' && RW_STATE.app && RW_STATE.app.company && RW_STATE.app.company.id) return RW_STATE.app.company.id;
        throw new Error('سياق الشركة غير محدد');
    }

    function actorEmail() {
        var u = (typeof RW_STATE !== 'undefined' && RW_STATE.app) ? RW_STATE.app.currentUser : null;
        var email = u && (u.email || u.user_email);
        if (!email) throw new Error('بريد المستخدم غير محدد');
        return email;
    }

    function today() {
        return new Date().toISOString().slice(0, 10);
    }

    function firstOfMonth() {
        var d = new Date();
        d.setDate(1);
        return d.toISOString().slice(0, 10);
    }

    function nav(view) {
        if (typeof RW_Navigation !== 'undefined' && RW_Navigation.navigate) RW_Navigation.navigate(view);
    }

    function kpi(label, value, icon, sub, action) {
        return '<button type="button" data-smc-nav="' + esc(action || '') + '" class="text-right bg-white border rounded-3xl p-5 shadow-sm hover:-translate-y-1 transition-all w-full">' +
            '<div class="flex items-start justify-between gap-3"><div><div class="text-xs text-slate-500 font-bold">' + esc(label) + '</div>' +
            '<div class="text-2xl font-black mt-2">' + esc(value) + '</div><div class="text-xs text-slate-400 mt-1">' + esc(sub || '') + '</div></div>' +
            '<div class="w-12 h-12 rounded-2xl bg-slate-100 flex items-center justify-center text-xl text-slate-700"><i class="fa-solid ' + esc(icon) + '"></i></div></div></button>';
    }

    function renderTables(d) {
        var reps = d.top_reps || [], items = d.top_items || [], customers = d.top_customers || [];
        var branches = d.branch_sales || [], channels = d.channels || [], payments = d.payment_mix || [];
        var recent = d.recent_orders || [];

        var repRows = reps.length ? reps.map(function(x){
            return '<tr class="border-t"><td class="p-3 font-black">' + esc(x.rep_name) + '</td><td class="p-3">' + esc(x.total_orders) + '</td><td class="p-3 font-black">' + esc(money(x.sales_value)) + '</td></tr>';
        }).join('') : '<tr><td colspan="3" class="p-6 text-center text-slate-400">لا توجد بيانات في الفترة</td></tr>';

        var itemRows = items.length ? items.map(function(x){
            return '<tr class="border-t"><td class="p-3 font-black">' + esc(x.item_code) + '</td><td class="p-3">' + esc(x.item_name) + '</td><td class="p-3">' + esc(x.net_qty) + '</td><td class="p-3 font-black">' + esc(money(x.sales_value)) + '</td></tr>';
        }).join('') : '<tr><td colspan="4" class="p-6 text-center text-slate-400">لا توجد بيانات في الفترة</td></tr>';

        var customerRows = customers.length ? customers.map(function(x){
            return '<tr class="border-t"><td class="p-3 font-black">' + esc(x.customer_name) + '</td><td class="p-3">' + esc(x.total_orders) + '</td><td class="p-3 font-black">' + esc(money(x.sales_value)) + '</td><td class="p-3">' + esc(money(x.outstanding)) + '</td></tr>';
        }).join('') : '<tr><td colspan="4" class="p-6 text-center text-slate-400">لا توجد بيانات في الفترة</td></tr>';

        var branchRows = branches.length ? branches.map(function(x){
            return '<tr class="border-t"><td class="p-3 font-black">' + esc(x.branch_name) + '</td><td class="p-3">' + esc(x.total_orders) + '</td><td class="p-3 font-black">' + esc(money(x.sales_value)) + '</td></tr>';
        }).join('') : '<tr><td colspan="3" class="p-6 text-center text-slate-400">لا توجد بيانات في الفترة</td></tr>';

        var channelRows = channels.length ? channels.map(function(x){
            return '<tr class="border-t"><td class="p-3 font-black">' + esc(x.channel) + '</td><td class="p-3">' + esc(x.total_orders) + '</td><td class="p-3 font-black">' + esc(money(x.sales_value)) + '</td></tr>';
        }).join('') : '<tr><td colspan="3" class="p-6 text-center text-slate-400">لا توجد بيانات في الفترة</td></tr>';

        var paymentRows = payments.length ? payments.map(function(x){
            return '<tr class="border-t"><td class="p-3 font-black">' + esc(x.payment_type) + '</td><td class="p-3">' + esc(x.total_orders) + '</td><td class="p-3 font-black">' + esc(money(x.sales_value)) + '</td><td class="p-3">' + esc(money(x.paid_amount)) + '</td></tr>';
        }).join('') : '<tr><td colspan="4" class="p-6 text-center text-slate-400">لا توجد بيانات في الفترة</td></tr>';

        var orderRows = recent.length ? recent.map(function(x){
            return '<tr class="border-t hover:bg-slate-50"><td class="p-3 font-black">' + esc(x.order_code) + '</td><td class="p-3">' + esc(x.customer_name || 'غير محدد') + '</td><td class="p-3">' + esc(money(x.total_amount)) + '</td><td class="p-3">' + esc(x.order_status) + '</td><td class="p-3"><button type="button" data-smc-order="' + esc(x.order_code) + '" class="px-3 py-2 rounded-xl bg-blue-50 text-blue-700 font-black">فتح</button></td></tr>';
        }).join('') : '<tr><td colspan="5" class="p-8 text-center text-slate-400">لا توجد أوردرات</td></tr>';

        return '<div class="grid grid-cols-1 xl:grid-cols-2 gap-6 mt-6">' +
            '<div class="bg-white border rounded-3xl overflow-hidden"><div class="p-5"><h3 class="font-black text-xl">أفضل مندوبي المبيعات</h3><p class="text-xs text-slate-500 mt-1">بحسب صافي المبيعات المرحّلة/المسلّمة</p></div><div class="overflow-x-auto"><table class="w-full text-sm"><thead class="bg-slate-50"><tr><th class="p-3 text-right">المندوب</th><th class="p-3 text-right">الأوردرات</th><th class="p-3 text-right">المبيعات</th></tr></thead><tbody>' + repRows + '</tbody></table></div></div>' +
            '<div class="bg-white border rounded-3xl overflow-hidden"><div class="p-5"><h3 class="font-black text-xl">أفضل الأصناف</h3><p class="text-xs text-slate-500 mt-1">الكمية الصافية وقيمة البيع</p></div><div class="overflow-x-auto"><table class="w-full text-sm"><thead class="bg-slate-50"><tr><th class="p-3 text-right">الكود</th><th class="p-3 text-right">الصنف</th><th class="p-3 text-right">الكمية</th><th class="p-3 text-right">القيمة</th></tr></thead><tbody>' + itemRows + '</tbody></table></div></div>' +
            '<div class="bg-white border rounded-3xl overflow-hidden"><div class="p-5"><h3 class="font-black text-xl">أفضل العملاء</h3><p class="text-xs text-slate-500 mt-1">المبيعات والرصيد المفتوح</p></div><div class="overflow-x-auto"><table class="w-full text-sm"><thead class="bg-slate-50"><tr><th class="p-3 text-right">العميل</th><th class="p-3 text-right">الأوردرات</th><th class="p-3 text-right">المبيعات</th><th class="p-3 text-right">المستحق</th></tr></thead><tbody>' + customerRows + '</tbody></table></div></div>' +
            '<div class="bg-white border rounded-3xl overflow-hidden"><div class="p-5"><h3 class="font-black text-xl">المبيعات حسب الفرع</h3></div><div class="overflow-x-auto"><table class="w-full text-sm"><thead class="bg-slate-50"><tr><th class="p-3 text-right">الفرع</th><th class="p-3 text-right">الأوردرات</th><th class="p-3 text-right">المبيعات</th></tr></thead><tbody>' + branchRows + '</tbody></table></div></div>' +
            '<div class="bg-white border rounded-3xl overflow-hidden"><div class="p-5"><h3 class="font-black text-xl">المبيعات حسب القناة</h3></div><div class="overflow-x-auto"><table class="w-full text-sm"><thead class="bg-slate-50"><tr><th class="p-3 text-right">القناة</th><th class="p-3 text-right">الأوردرات</th><th class="p-3 text-right">المبيعات</th></tr></thead><tbody>' + channelRows + '</tbody></table></div></div>' +
            '<div class="bg-white border rounded-3xl overflow-hidden"><div class="p-5"><h3 class="font-black text-xl">مزيج السداد</h3></div><div class="overflow-x-auto"><table class="w-full text-sm"><thead class="bg-slate-50"><tr><th class="p-3 text-right">طريقة السداد</th><th class="p-3 text-right">الأوردرات</th><th class="p-3 text-right">المبيعات</th><th class="p-3 text-right">المدفوع</th></tr></thead><tbody>' + paymentRows + '</tbody></table></div></div>' +
            '<div class="bg-white border rounded-3xl overflow-hidden xl:col-span-2"><div class="p-5 flex items-center justify-between gap-3"><div><h3 class="font-black text-xl">آخر الأوردرات</h3><p class="text-xs text-slate-500 mt-1">فتح الأوردر يعيدك إلى دورة المبيعات الأصلية</p></div><button type="button" data-smc-nav="orders" class="px-4 py-2 rounded-xl bg-slate-900 text-white font-black">كل الأوردرات</button></div><div class="overflow-x-auto"><table class="w-full text-sm"><thead class="bg-slate-50"><tr><th class="p-3 text-right">الأوردر</th><th class="p-3 text-right">العميل</th><th class="p-3 text-right">القيمة</th><th class="p-3 text-right">الحالة</th><th class="p-3 text-right">—</th></tr></thead><tbody>' + orderRows + '</tbody></table></div></div>' +
        '</div>';
    }

    function renderData(d) {
        var c = byId('rw-page-container');
        if (!c) return;
        var o = d.orders || {}, q = d.quotes || {}, r = d.returns || {}, p = d.payments || {};
        var rs = d.runsheets || {}, dec = d.decision_center || {}, com = d.commercial || {}, t = d.targets || {};
        var html = '<div class="space-y-6">' +
            '<div class="flex flex-wrap items-end justify-between gap-4"><div><div class="text-sm text-blue-600 font-black">إدارة المبيعات</div><h2 class="text-3xl font-black mt-1">مركز إدارة المبيعات</h2><p class="text-sm text-slate-500 mt-2">نقطة قيادة موحدة فوق دورة المبيعات التجارية والتشغيلية دون إنشاء محرك حركة جديد.</p></div>' +
            '<div class="flex flex-wrap gap-2 items-end"><label class="text-xs font-bold text-slate-500">من<input id="smc-from" type="date" class="block mt-1 p-3 border rounded-xl bg-white"></label><label class="text-xs font-bold text-slate-500">إلى<input id="smc-to" type="date" class="block mt-1 p-3 border rounded-xl bg-white"></label><button id="smc-refresh" type="button" class="px-5 py-3 rounded-xl bg-blue-600 text-white font-black">تحديث</button></div></div>' +
            '<div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">' +
                kpi('قيمة المبيعات', money(o.sales_value), 'fa-sack-dollar', 'Invoiced + Delivered', 'orders') +
                kpi('المستحق', money(o.outstanding), 'fa-file-invoice-dollar', 'على الأوردرات المفتوحة/المسلّمة', 'orders') +
                kpi('عروض الأسعار', String(q.total || 0), 'fa-file-circle-question', 'مسودة / مرسلة / مقبولة / محولة', 'quotes') +
                kpi('المرتجعات', money(r.posted_value || r.value), 'fa-rotate-left', 'المرتجع المسجل', 'sales-returns') +
                kpi('التحصيل', money(p.value), 'fa-money-bill-wave', 'عدد الإيصالات: ' + String(p.receipt_count || 0), 'sales-payment-allocation') +
                kpi('الرانشيتات', String(rs.total || 0), 'fa-route', 'الحالية في الفترة', 'runsheets') +
                kpi('العروض التجارية الفعالة', String(com.active_promotions || 0), 'fa-percent', 'Promotion Engine', 'promotions') +
                kpi('قوائم الأسعار الفعالة', String(com.active_price_lists || 0), 'fa-tags', 'Commercial Catalog', 'price-lists') +
            '</div>' +
            '<div class="grid grid-cols-2 md:grid-cols-5 gap-3">' +
                '<div class="bg-white border rounded-2xl p-4"><div class="text-xs text-slate-500">Draft</div><div class="text-xl font-black">' + esc(o.draft || 0) + '</div></div>' +
                '<div class="bg-white border rounded-2xl p-4"><div class="text-xs text-slate-500">Confirmed</div><div class="text-xl font-black">' + esc(o.confirmed || 0) + '</div></div>' +
                '<div class="bg-white border rounded-2xl p-4"><div class="text-xs text-slate-500">Invoiced</div><div class="text-xl font-black">' + esc(o.invoiced || 0) + '</div></div>' +
                '<div class="bg-white border rounded-2xl p-4"><div class="text-xs text-slate-500">Delivered</div><div class="text-xl font-black">' + esc(o.delivered || 0) + '</div></div>' +
                '<div class="bg-white border rounded-2xl p-4"><div class="text-xs text-slate-500">Cancelled</div><div class="text-xl font-black">' + esc(o.cancelled || 0) + '</div></div>' +
            '</div>' +
            '<div class="grid grid-cols-1 md:grid-cols-4 gap-4">' +
                '<div class="bg-slate-900 text-white rounded-3xl p-5"><div class="text-xs text-slate-300">Decision Center</div><div class="text-2xl font-black mt-2">' + esc(dec.evaluations || 0) + '</div><div class="text-xs text-slate-300 mt-2">ALLOW: ' + esc(dec.approved || 0) + ' · WARN: ضمنيًا بالسياسة · BLOCK: ' + esc(dec.blocked || 0) + '</div><button type="button" data-smc-nav="sales-decision-center" class="mt-4 px-4 py-2 rounded-xl bg-white/10 font-black">فتح المركز</button></div>' +
                '<div class="bg-white border rounded-3xl p-5"><div class="text-xs text-slate-500">أهداف المبيعات</div><div class="text-2xl font-black mt-2">' + esc(t.plans || 0) + '</div><div class="text-xs text-slate-500 mt-2">Approved: ' + esc(t.approved || 0) + ' · Closed: ' + esc(t.closed || 0) + '</div><button type="button" data-smc-nav="sales-targets" class="mt-4 px-4 py-2 rounded-xl bg-blue-50 text-blue-700 font-black">فتح الأهداف</button></div>' +
                '<div class="bg-white border rounded-3xl p-5"><div class="text-xs text-slate-500">الرانشيت</div><div class="text-2xl font-black mt-2">' + esc(rs.total || 0) + '</div><div class="text-xs text-slate-500 mt-2">Picking: ' + esc(rs.picking || 0) + ' · Loading: ' + esc(rs.loading || 0) + ' · Delivery: ' + esc(rs.delivering || 0) + '</div><button type="button" data-smc-nav="runsheets" class="mt-4 px-4 py-2 rounded-xl bg-slate-100 font-black">فتح الرانشيتات</button></div>' +
                '<div class="bg-white border rounded-3xl p-5"><div class="text-xs text-slate-500">التسعير التجاري</div><div class="text-2xl font-black mt-2">' + esc(com.active_price_lists || 0) + ' / ' + esc(com.active_promotions || 0) + '</div><div class="text-xs text-slate-500 mt-2">قوائم أسعار / عروض فعالة</div><button type="button" data-smc-nav="price-lists" class="mt-4 px-4 py-2 rounded-xl bg-amber-50 text-amber-700 font-black">إدارة التسعير</button></div>' +
            '</div>' +
            renderTables(d) +
            '</div>';
        safeHTML(c, html);
        byId('smc-from').value = state.from || firstOfMonth();
        byId('smc-to').value = state.to || today();
        bind();
    }

    async function load() {
        var from = byId('smc-from') ? byId('smc-from').value || null : null;
        var to = byId('smc-to') ? byId('smc-to').value || null : null;
        state.from = from; state.to = to;
        showLoader('جاري تحميل مركز إدارة المبيعات...');
        try {
            var res = await supabase.rpc('sales_management_center_read', {
                p_company_id: companyId(),
                p_actor_email: actorEmail(),
                p_from_date: from,
                p_to_date: to
            });
            if (res.error) throw new Error(res.error.message);
            state.data = res.data || {};
            hideLoader();
            renderData(state.data);
        } catch (e) {
            hideLoader();
            var c = byId('rw-page-container');
            if (c) safeHTML(c, '<div class="p-10 bg-white border rounded-3xl text-red-600 font-black">فشل تحميل مركز إدارة المبيعات: ' + esc(e.message) + '</div>');
        }
    }

    function bind() {
        var c = byId('rw-page-container');
        if (!c) return;
        var b = byId('smc-refresh');
        if (b) b.onclick = load;
        c.onclick = function (e) {
            var navEl = e.target.closest ? e.target.closest('[data-smc-nav]') : null;
            if (navEl) {
                var v = navEl.getAttribute('data-smc-nav');
                if (v === 'sales-payment-allocation') v = 'finance';
                if (v) nav(v);
                return;
            }
            var order = e.target.closest ? e.target.closest('[data-smc-order]') : null;
            if (order) {
                var code = order.getAttribute('data-smc-order');
                nav('orders');
                setTimeout(function () {
                    if (typeof RW_Orders !== 'undefined' && RW_Orders._showDetails) RW_Orders._showDetails(code);
                }, 0);
            }
        };
    }

    async function render() {
        var c = byId('rw-page-container');
        if (!c) return;
        safeHTML(c, '<div class="p-10 text-center text-slate-500 font-bold">جاري تحميل مركز إدارة المبيعات...</div>');
        await load();
        clearInterval(state.timer);
        state.timer = setInterval(function () {
            if (RW_STATE.app.currentView === 'sales-management-center') load().catch(function(){});
        }, 30000);
    }

    return { render: render, refresh: load };
})();
window.RW_SalesManagementCenter = RW_SalesManagementCenter;
```

---

## PATCH-05 — تحويل تفاصيل الأوردر من Modal إلى Page

**الملف:** `Current/PWA/main.html`  
**الدالة:** `RW_Orders._showDetails(code)`  
**السطر:** 10151

**احذف الدالة كاملة واستبدلها بـ:**

```
function _showDetails(code) {
    showLoader('جاري تحميل تفاصيل الأوردر...');
    supabase.from('orders').select('*').eq('company_id', _rwCompanyId()).eq('order_code', code).maybeSingle().then(function(oRes) {
        var order = oRes.data;
        if (!order) { hideLoader(); showToast('الأوردر غير موجود', 'error'); return; }
        return supabase.from('order_details').select('*').eq('order_id', order.id).then(function(itemsRes) {
            var items = itemsRes.data || [];
            hideLoader();
            var c = byId('rw-page-container'); if (!c) return;
            var itemsHtml = items.length ? '<div class="overflow-x-auto"><table class="w-full text-sm"><thead class="bg-slate-50"><tr><th class="p-3 text-right">الصنف</th><th class="p-3">الوحدة</th><th class="p-3">الكمية</th><th class="p-3">السعر</th><th class="p-3">الإجمالي</th></tr></thead><tbody>' +
                items.map(function(it){
                    var lt = Number(it.line_amount) || (Number(it.qty) * Number(it.unit_price));
                    return '<tr class="border-t"><td class="p-3 font-bold">' + esc(it.item_name || it.item_code) + '<div class="text-xs text-slate-400">' + esc(it.item_code) + '</div></td><td class="p-3 text-center">' + esc(it.unit || 'حبة') + '</td><td class="p-3 text-center">' + esc(it.qty) + '</td><td class="p-3 text-center">' + esc(Number(it.unit_price || 0).toLocaleString('ar-EG')) + '</td><td class="p-3 text-center font-black">' + esc(lt.toLocaleString('ar-EG')) + '</td></tr>';
                }).join('') + '</tbody></table></div>' :
                '<div class="p-8 text-center text-slate-400">لا توجد أصناف مسجلة لهذا الأوردر</div>';
            var total = items.reduce(function(s,it){ return s + (Number(it.line_amount) || Number(it.qty || 0) * Number(it.unit_price || 0)); },0);
            var delivery = Number(order.delivery_fee || 0);
            var currentUser = (typeof RW_STATE !== 'undefined' && RW_STATE.app) ? RW_STATE.app.currentUser : null;
            var permissions = (currentUser && Array.isArray(currentUser.permissions)) ? currentUser.permissions : [];
            var canDeleteInvoiced = !!(currentUser && (currentUser.isOwner === true || permissions.indexOf('*') !== -1 || permissions.indexOf('general_manager') !== -1 || permissions.indexOf('sales_manager') !== -1 || permissions.indexOf('sales_supervisor') !== -1));
            var canConfirm = (order.order_status === 'Draft' || order.order_status === 'Pending') && !order.runsheet_id;
            var canDelete = (order.order_status === 'Draft' || order.order_status === 'Pending' || order.order_status === 'Confirmed' || (order.order_status === 'Invoiced' && canDeleteInvoiced)) && !order.runsheet_id;
            safeHTML(c, '<div class="space-y-6">' +
                '<div class="flex flex-wrap items-center justify-between gap-3"><div><div class="text-sm text-blue-600 font-black">أوردرات المبيعات</div><h2 class="text-3xl font-black mt-1">تفاصيل الأوردر ' + esc(code) + '</h2><p class="text-sm text-slate-500 mt-2">' + esc(order.customer_name || 'غير محدد') + ' · ' + esc(order.order_status || '') + '</p></div><button id="od-back" class="px-4 py-2 rounded-xl bg-slate-100 font-black">رجوع للأوردرات</button></div>' +
                (order.runsheet_id ? '<div class="bg-amber-50 border-r-4 border-amber-500 p-4 rounded-2xl">مرتبط بالرانشيت: <b>' + esc(order.runsheet_id) + '</b></div>' : '') +
                '<div class="grid grid-cols-2 md:grid-cols-5 gap-3">' +
                    '<div class="bg-white border rounded-2xl p-4"><div class="text-xs text-slate-500">العميل</div><div class="font-black mt-1">' + esc(order.customer_name || '—') + '</div></div>' +
                    '<div class="bg-white border rounded-2xl p-4"><div class="text-xs text-slate-500">المنطقة</div><div class="font-black mt-1">' + esc(order.area || '—') + '</div></div>' +
                    '<div class="bg-white border rounded-2xl p-4"><div class="text-xs text-slate-500">الحالة</div><div class="font-black mt-1">' + esc(order.order_status || '—') + '</div></div>' +
                    '<div class="bg-white border rounded-2xl p-4"><div class="text-xs text-slate-500">طريقة السداد</div><div class="font-black mt-1">' + esc(order.payment_type || '—') + '</div></div>' +
                    '<div class="bg-emerald-50 border rounded-2xl p-4"><div class="text-xs text-slate-500">الإجمالي</div><div class="font-black text-emerald-700 mt-1">' + esc((total + delivery).toLocaleString('ar-EG')) + ' ' + esc(currency) + '</div></div>' +
                '</div>' +
                '<div class="bg-white border rounded-3xl overflow-hidden"><div class="p-5"><h3 class="font-black text-xl">أصناف الأوردر</h3></div>' + itemsHtml + '</div>' +
                '<div class="flex flex-wrap justify-center gap-3">' +
                    (canConfirm ? '<button id="od-confirm" class="px-6 py-3 rounded-2xl bg-blue-600 text-white font-black">تأكيد الأوردر</button>' : '') +
                    (canDelete ? '<button id="od-delete" class="px-6 py-3 rounded-2xl bg-rose-600 text-white font-black">حذف الأوردر</button>' : '') +
                    '<button id="od-print" class="px-6 py-3 rounded-2xl bg-emerald-600 text-white font-black">طباعة</button>' +
                '</div></div>');
            byId('od-back').onclick = function(){ RW_Navigation.navigate('orders'); };
            var b = byId('od-confirm'); if (b) b.onclick = function(){ _confirmOrderFromDetails(code); };
            b = byId('od-delete'); if (b) b.onclick = function(){ _delete(code); };
            b = byId('od-print'); if (b) b.onclick = function(){ _printOrder(code); };
        });
    }).catch(function(e){ hideLoader(); showToast(e.message || 'فشل التحميل','error'); console.error(e); });
}
```

---

## PATCH-06 — تحويل إضافة عميل Telesales من Modal إلى Page

**الملف:** `Current/PWA/main.html`  
**الدالة:** `_showNewCustomerForm()`  
**السطر:** 9256

**احذف الدالة كاملة واستبدلها بـ:**

```
function _showNewCustomerForm() {
    var c=byId('rw-page-container'); if(!c)return;
    safeHTML(c,'<div class="max-w-5xl mx-auto space-y-6" dir="rtl"><div class="flex justify-between gap-3"><div><div class="text-sm text-emerald-600 font-black">التلي سيلز</div><h2 class="text-3xl font-black mt-1">إضافة عميل جديد</h2><p class="text-sm text-slate-500 mt-2">الرصيد المالي للعميل يُدار من المسار المالي الرسمي ولا يُكتب من شاشة المبيعات.</p></div><button id="cust-back" class="px-4 py-2 rounded-xl bg-slate-100 font-black">رجوع</button></div><div class="bg-white border rounded-3xl p-6 grid grid-cols-1 md:grid-cols-2 gap-4"><input id="cust-code" value="جديد" readonly class="p-3 bg-gray-100 border rounded-xl"><input id="cust-name" class="p-3 border rounded-xl" placeholder="اسم العميل *"><input id="cust-phone" class="p-3 border rounded-xl" placeholder="رقم الهاتف"><input id="cust-area" class="p-3 border rounded-xl" placeholder="المنطقة"><input id="cust-location" class="p-3 border rounded-xl" placeholder="العنوان التفصيلي"><select id="cust-type" class="p-3 border rounded-xl"><option value="عادي">عادي</option><option value="جملة">جملة</option><option value="VIP">VIP</option></select><select id="cust-payment" class="p-3 border rounded-xl"><option value="نقدي">نقدي</option><option value="أجل">أجل</option></select><input id="cust-debt" type="number" value="0" readonly disabled class="p-3 bg-gray-100 border rounded-xl"><select id="cust-visit" class="p-3 border rounded-xl"><option value="">اختر يوم الزيارة</option><option>السبت</option><option>الأحد</option><option>الإثنين</option><option>الثلاثاء</option><option>الأربعاء</option><option>الخميس</option></select><input id="cust-contact" class="p-3 border rounded-xl" placeholder="مسؤول التواصل"><textarea id="cust-notes" rows="3" class="md:col-span-2 p-3 border rounded-xl" placeholder="ملاحظات"></textarea><button id="btn-save-cust" class="md:col-span-2 px-6 py-3 rounded-2xl bg-emerald-600 text-white font-black">حفظ العميل</button></div></div>');
    byId('cust-back').onclick=function(){RW_Navigation.navigate('telesales');};
    byId('btn-save-cust').onclick=function(){var name=byId('cust-name').value.trim();if(!name)return showToast('اسم العميل مطلوب','error');_saveNewCustomer({name:name,phone:byId('cust-phone').value.trim(),area:byId('cust-area').value.trim(),location:byId('cust-location').value.trim(),customer_type:byId('cust-type').value,payment_type:byId('cust-payment').value,debt:0,visit_day:byId('cust-visit').value,contact_person:byId('cust-contact').value.trim(),notes:byId('cust-notes').value.trim()});};
}
```

---

## PATCH-07 — تصحيح تابع حفظ العميل بعد تحويل الشاشة إلى Page

**الملف:** `Current/PWA/main.html`  
**الدالة:** `_saveNewCustomer(customerData)`  
**السطر:** 9306

**احذف الدالة كاملة واستبدلها بـ:**

```
async function _saveNewCustomer(customerData) {
    showLoader('جاري حفظ العميل...');
    try {
        var ses=await supabase.auth.getSession(), token=ses.data.session&&ses.data.session.access_token;
        if(!token)throw new Error('انتهت الجلسة');
        var res=await fetch(RW_SUPABASE_URL+'/functions/v1/save-customer',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify({customer:customerData,isEdit:false,customer_code:null})});
        var json=await res.json(); hideLoader();
        if(!json.success) return showToast(json.error||'فشل الحفظ','error');
        RW_Audit_log('create','customers',json.customer_code||'',null,customerData);
        await RW_Data.loadCustomers();
        showToast('تم إضافة العميل بنجاح','success');
        RW_Navigation.navigate('telesales');
        setTimeout(function(){if(typeof _selectCustomer==='function'&&json.customer_code)_selectCustomer(json.customer_code);},0);
    }catch(e){hideLoader();showToast(e.message||'فشل الاتصال','error');}
}
```

---

## PATCH-08 — تحويل Quote Editor إلى Page

**الملف:** `Current/PWA/main.html`  
**الدالة:** `RW_SalesQuotes.openEditor(quote)`  
**السطر:** 28454

**احذف الدالة كاملة واستبدلها بـ:**

```
async function openEditor(quote) {
    var detail = quote;
    if (quote && quote.items) detail = quote;
    else if (quote && quote.quote_code) {
        detail = await api('detail', { quote_code: quote.quote_code });
        detail = Object.assign({}, detail.quote, { items: detail.items || [] });
    }
    var q = detail || {}, lines = q.items || [], c = byId('rw-page-container');
    if (!c) return;
    safeHTML(c, '<div class="space-y-6"><div class="flex flex-wrap justify-between gap-3"><div><div class="text-sm text-blue-600 font-black">عروض الأسعار</div><h2 class="text-3xl font-black mt-1">' + esc(q.quote_code ? 'تعديل العرض ' + q.quote_code : 'عرض سعر جديد') + '</h2><p class="text-sm text-slate-500 mt-2">العرض التجاري لا يحجز ولا يصرف مخزونًا.</p></div><button id="sq-close" class="px-4 py-2 rounded-xl bg-slate-100 font-black">رجوع</button></div>' +
        '<div class="grid grid-cols-1 md:grid-cols-4 gap-3"><select id="sq-customer" class="p-3 border rounded-xl">' + customerOptions(q.customer_id || '') + '</select><select id="sq-branch" class="p-3 border rounded-xl">' + branchOptions(q.branch_id || '') + '</select><select id="sq-rep" class="p-3 border rounded-xl">' + repOptions(q.sales_rep_id || '') + '</select><input id="sq-valid" type="date" class="p-3 border rounded-xl" value="' + esc(q.valid_until || plusDays(7)) + '"></div>' +
        '<div class="grid grid-cols-1 md:grid-cols-3 gap-3"><input id="sq-name" class="p-3 border rounded-xl" placeholder="اسم عميل غير مسجل" value="' + esc(q.customer_name || '') + '"><input id="sq-phone" class="p-3 border rounded-xl" placeholder="هاتف العميل" value="' + esc(q.customer_phone || '') + '"><input id="sq-area" class="p-3 border rounded-xl" placeholder="المنطقة" value="' + esc(q.area || '') + '"></div>' +
        '<div class="grid grid-cols-1 md:grid-cols-3 gap-3"><input id="sq-discount" type="number" min="0" step="0.01" class="p-3 border rounded-xl" placeholder="خصم عام" value="' + esc(q.discount_amount || 0) + '"><input id="sq-delivery" type="number" min="0" step="0.01" class="p-3 border rounded-xl" placeholder="رسوم توصيل" value="' + esc(q.delivery_fee || 0) + '"><input id="sq-reference" class="p-3 border rounded-xl" placeholder="مرجع العميل/العرض" value="' + esc(q.reference || '') + '"></div>' +
        '<textarea id="sq-notes" class="w-full p-3 border rounded-xl" rows="2" placeholder="ملاحظات">' + esc(q.notes || '') + '</textarea>' +
        '<div class="bg-white border rounded-3xl p-5"><div class="flex items-center justify-between mb-3"><h3 class="font-black text-xl">الأصناف</h3><button id="sq-add-line" class="px-4 py-2 rounded-xl bg-slate-900 text-white font-black">+ إضافة صنف</button></div><div id="sq-lines" class="space-y-3"></div></div>' +
        '<div class="grid grid-cols-1 md:grid-cols-2 gap-3"><input id="sq-terms" class="p-3 border rounded-xl" placeholder="الشروط" value="' + esc(q.terms || '') + '"><button id="sq-save" class="px-6 py-3 rounded-2xl bg-blue-600 text-white font-black">حفظ مسودة العرض</button></div></div>');
    for (var i=0;i<lines.length;i++) addLine(lines[i]);
    if (!lines.length) addLine({});
    byId('sq-close').onclick=function(){ RW_Navigation.navigate('quotes'); };
    byId('sq-add-line').onclick=function(){ addLine({}); };
    byId('sq-save').onclick=async function(){
        var items=readFormItems(); if(!items.length) return showToast('أضف صنفًا صالحًا واحدًا على الأقل','warning');
        try{
            showLoader('جاري حفظ العرض...');
            var customer=byId('sq-customer').value||null, co=state.catalog.customers.find(function(x){return x.id===customer;})||null;
            var payload={quote_date:q.quote_date||today(),valid_until:byId('sq-valid').value||null,customer_id:customer,customer_name:byId('sq-name').value.trim()||(co&&co.name)||null,customer_phone:byId('sq-phone').value.trim()||(co&&co.phone)||null,area:byId('sq-area').value.trim()||(co&&co.area)||null,branch_id:byId('sq-branch').value||null,sales_rep_id:byId('sq-rep').value||null,currency:'SAR',discount_amount:Number(byId('sq-discount').value||0),delivery_fee:Number(byId('sq-delivery').value||0),reference:byId('sq-reference').value.trim()||null,notes:byId('sq-notes').value.trim()||null,terms:byId('sq-terms').value.trim()||null,items:items};
            if(q.quote_code){payload.quote_code=q.quote_code;await api('update',payload);}else{payload.operation_id=crypto.randomUUID();await api('create',payload);}
            hideLoader();showToast('تم حفظ العرض بنجاح','success');RW_Navigation.navigate('quotes');
        }catch(e){hideLoader();showToast(e.message||'فشل حفظ العرض','error');}
    };
}
```

---

## PATCH-09 — تحويل Quote Details إلى Page

**الملف:** `Current/PWA/main.html`  
**الدالة:** `RW_SalesQuotes.detail(code)`  
**السطر:** 28537

**احذف الدالة كاملة واستبدلها بـ:**

```
async function detail(code) {
    try {
        showLoader('جاري تحميل تفاصيل العرض...');
        var data=await api('detail',{quote_code:code}); hideLoader();
        var q=data.quote||{}, lines=data.items||[], history=data.history||[], c=byId('rw-page-container'); if(!c)return;
        var lh=lines.map(function(x){return '<tr class="border-t"><td class="p-3">'+esc(x.item_code)+'</td><td class="p-3">'+esc(x.item_name)+'</td><td class="p-3">'+esc(x.qty)+'</td><td class="p-3">'+esc(money(x.unit_price))+'</td><td class="p-3 font-black">'+esc(money(x.line_total))+'</td></tr>';}).join('');
        var hh=history.map(function(x){return '<div class="border-b py-3 flex flex-wrap justify-between gap-2"><div><b>'+esc(statusLabel(x.to_status))+'</b><span class="text-xs text-slate-500 mr-2">'+esc(x.action)+'</span></div><div class="text-xs text-slate-500">'+esc(x.actor_email||'')+' · '+esc(x.created_at||'')+'</div></div>';}).join('');
        var actions='<div class="flex flex-wrap gap-2 justify-center"><button id="sqd-edit" class="px-4 py-2 rounded-xl bg-blue-600 text-white font-black">تعديل</button><button id="sqd-convert" class="px-4 py-2 rounded-xl bg-emerald-600 text-white font-black">تحويل لأوردر</button>';
        if(q.status==='Draft') actions+='<button id="sqd-send" class="px-4 py-2 rounded-xl bg-violet-600 text-white font-black">إرسال</button><button id="sqd-cancel" class="px-4 py-2 rounded-xl bg-rose-600 text-white font-black">إلغاء</button>';
        if(q.status==='Sent') actions+='<button id="sqd-accept" class="px-4 py-2 rounded-xl bg-emerald-700 text-white font-black">اعتماد</button><button id="sqd-reject" class="px-4 py-2 rounded-xl bg-amber-600 text-white font-black">رفض</button>';
        actions+='</div>';
        safeHTML(c,'<div class="space-y-6"><div class="flex justify-between gap-3"><div><div class="text-sm text-blue-600 font-black">عروض الأسعار</div><h2 class="text-3xl font-black mt-1">'+esc(q.quote_code)+'</h2><p class="text-sm text-slate-500 mt-2">'+esc(q.customer_name||'—')+' · '+esc(statusLabel(q.status))+'</p></div><button id="sqd-back" class="px-4 py-2 rounded-xl bg-slate-100 font-black">رجوع</button></div><div class="grid grid-cols-2 md:grid-cols-5 gap-3"><div class="bg-white border rounded-2xl p-4">التاريخ<div class="font-black mt-1">'+esc(q.quote_date)+'</div></div><div class="bg-white border rounded-2xl p-4">الصلاحية<div class="font-black mt-1">'+esc(q.valid_until||'بدون')+'</div></div><div class="bg-white border rounded-2xl p-4">الأصناف<div class="font-black mt-1">'+esc(lines.length)+'</div></div><div class="bg-white border rounded-2xl p-4">الإجمالي<div class="font-black mt-1">'+esc(money(q.total_amount))+'</div></div><div class="bg-white border rounded-2xl p-4">التحويل<div class="font-black mt-1">'+esc(q.converted_order_id?'تم التحويل':'—')+'</div></div></div><div class="bg-white border rounded-3xl overflow-hidden"><div class="p-5"><h3 class="font-black text-xl">تفاصيل الأصناف</h3></div><div class="overflow-x-auto"><table class="w-full text-sm"><thead class="bg-slate-50"><tr><th class="p-3 text-right">الكود</th><th class="p-3 text-right">الصنف</th><th class="p-3">الكمية</th><th class="p-3">السعر</th><th class="p-3">الإجمالي</th></tr></thead><tbody>'+lh+'</tbody></table></div></div><div class="bg-white border rounded-3xl p-5"><h3 class="font-black text-xl mb-3">دورة الحياة</h3>'+ (hh||'<div class="text-slate-400">لا يوجد سجل</div>') +'</div>'+actions+'</div>');
        byId('sqd-back').onclick=function(){RW_Navigation.navigate('quotes');};
        byId('sqd-edit').onclick=function(){openEditor(Object.assign({},q,{items:lines}));};
        byId('sqd-convert').onclick=function(){convert(code);};
        var b=byId('sqd-send');if(b)b.onclick=function(){action(code,'send');};
        b=byId('sqd-accept');if(b)b.onclick=function(){action(code,'accept');};
        b=byId('sqd-reject');if(b)b.onclick=function(){action(code,'reject');};
        b=byId('sqd-cancel');if(b)b.onclick=function(){action(code,'cancel');};
    }catch(e){hideLoader();showToast(e.message||'فشل تحميل التفاصيل','error');}
}
```

---

## PATCH-10 — تحويل Price List Editor إلى Page

**الملف:** `Current/PWA/main.html`  
**الدالة:** `RW_PriceLists.openEditor(list)`  
**السطر:** 28790

**احذف الدالة كاملة واستبدلها بـ:**

```
async function openEditor(list) {
    var detail=list?await api('detail',{catalog_id:list.id}):{catalog:{},rules:[]}, x=detail.catalog||{}, c=byId('rw-page-container'); if(!c)return;
    safeHTML(c,'<div class="space-y-6"><div class="flex justify-between gap-3"><div><div class="text-sm text-blue-600 font-black">قوائم الأسعار</div><h2 class="text-3xl font-black mt-1">'+esc(x.id?'تعديل قائمة الأسعار':'قائمة أسعار جديدة')+'</h2><p class="text-sm text-slate-500 mt-2">طبقة تسعير تجارية فوق items.sales_price.</p></div><button id="pl-close" class="px-4 py-2 rounded-xl bg-slate-100 font-black">رجوع</button></div><div class="grid grid-cols-1 md:grid-cols-5 gap-3"><input id="pl-code" class="p-3 border rounded-xl" placeholder="الكود" value="'+esc(x.code||'')+'"><input id="pl-name" class="p-3 border rounded-xl" placeholder="اسم القائمة" value="'+esc(x.name||'')+'"><input id="pl-currency" class="p-3 border rounded-xl" value="'+esc(x.currency||'SAR')+'"><input id="pl-priority" type="number" min="0" class="p-3 border rounded-xl" value="'+esc(x.priority==null?100:x.priority)+'"><label class="flex items-center gap-2 p-3 border rounded-xl font-black"><input id="pl-default" type="checkbox" '+(x.is_default?'checked':'')+'> افتراضية</label></div><div class="grid grid-cols-1 md:grid-cols-3 gap-3"><input id="pl-from" type="date" class="p-3 border rounded-xl" value="'+esc(x.valid_from||'')+'"><input id="pl-until" type="date" class="p-3 border rounded-xl" value="'+esc(x.valid_until||'')+'"><input id="pl-notes" class="p-3 border rounded-xl" placeholder="ملاحظات" value="'+esc(x.notes||'')+'"></div><div class="bg-white border rounded-3xl p-5"><div class="flex justify-between mb-3"><h3 class="font-black text-xl">قواعد التسعير</h3><button id="pl-add-rule" class="px-4 py-2 rounded-xl bg-emerald-600 text-white font-black">+ قاعدة</button></div><div id="pl-rules" class="space-y-2"></div></div><button id="pl-save" class="px-6 py-3 rounded-2xl bg-blue-600 text-white font-black">حفظ القائمة</button></div>');
    (detail.rules||[]).forEach(addRule); if(!(detail.rules||[]).length)addRule({});
    byId('pl-close').onclick=function(){RW_Navigation.navigate('price-lists');}; byId('pl-add-rule').onclick=function(){addRule({});};
    byId('pl-save').onclick=async function(){try{showLoader('جاري حفظ قائمة الأسعار...');var p={code:byId('pl-code').value.trim(),name:byId('pl-name').value.trim(),currency:byId('pl-currency').value.trim()||'SAR',priority:Number(byId('pl-priority').value||100),is_default:byId('pl-default').checked,is_active:true,valid_from:byId('pl-from').value||null,valid_until:byId('pl-until').value||null,notes:byId('pl-notes').value||null,rules:readRules()};if(!p.code||!p.name)throw new Error('الكود والاسم مطلوبان');if(x.id){p.catalog_id=x.id;await api('update',p);}else{p.operation_id=opId();await api('create',p);}hideLoader();showToast('تم حفظ قائمة الأسعار بنجاح','success');RW_Navigation.navigate('price-lists');}catch(e){hideLoader();showToast(e.message,'error');}};
}
```

---

## PATCH-11 — تحويل Price List Assign إلى Page

**الملف:** `Current/PWA/main.html`  
**الدالة:** `RW_PriceLists.assign(catalogId)`  
**السطر:** 28847

**احذف الدالة كاملة واستبدلها بـ:**

```
async function assign(catalogId) {
    var customers=state.catalog.customers||[], c=byId('rw-page-container'); if(!c)return;
    safeHTML(c,'<div class="max-w-3xl mx-auto space-y-6"><div class="flex justify-between"><div><div class="text-sm text-blue-600 font-black">قوائم الأسعار</div><h2 class="text-3xl font-black mt-1">تخصيص القائمة لعميل</h2></div><button id="pla-back" class="px-4 py-2 rounded-xl bg-slate-100 font-black">رجوع</button></div><div class="bg-white border rounded-3xl p-6"><label class="font-black text-sm">العميل</label><select id="pl-assign-customer" class="w-full p-3 border rounded-xl mt-2">'+optionHtml(customers,'','name')+'</select><button id="pla-save" class="mt-4 px-6 py-3 rounded-2xl bg-blue-600 text-white font-black">تخصيص</button></div></div>');
    byId('pla-back').onclick=function(){RW_Navigation.navigate('price-lists');}; byId('pla-save').onclick=async function(){var id=byId('pl-assign-customer').value;if(!id)return showToast('اختر العميل','warning');try{showLoader('جاري التخصيص...');await api('assign',{catalog_id:catalogId,customer_id:id});hideLoader();showToast('تم تخصيص القائمة للعميل','success');RW_Navigation.navigate('price-lists');}catch(e){hideLoader();showToast(e.message,'error');}};
}
```

---

## PATCH-12 — تحويل Price List Detail إلى Page

**الملف:** `Current/PWA/main.html`  
**الدالة:** `RW_PriceLists.detail(id)`  
**السطر:** 28859

**احذف الدالة كاملة واستبدلها بـ:**

```
async function detail(id) {
    try { showLoader('جاري تحميل التفاصيل...'); var r=await api('detail',{catalog_id:id}); hideLoader(); var c=byId('rw-page-container'); if(!c)return; var rows=(r.rules||[]).map(function(x){return '<tr class="border-t"><td class="p-3">'+esc(x.scope_type)+'</td><td class="p-3">'+esc(x.item_id||x.category_id||'كل الأصناف')+'</td><td class="p-3">'+esc(x.min_qty)+'</td><td class="p-3">'+esc(x.pricing_method)+'</td><td class="p-3 font-black">'+esc(x.unit_price||x.percent_value||0)+'</td></tr>';}).join(''); safeHTML(c,'<div class="space-y-6"><div class="flex justify-between"><div><div class="text-sm text-blue-600 font-black">قوائم الأسعار</div><h2 class="text-3xl font-black mt-1">'+esc(r.catalog.name)+'</h2></div><button id="pld-back" class="px-4 py-2 rounded-xl bg-slate-100 font-black">رجوع</button></div><div class="bg-white border rounded-3xl overflow-hidden"><div class="overflow-x-auto"><table class="w-full text-sm"><thead class="bg-slate-50"><tr><th class="p-3">النطاق</th><th class="p-3">الهدف</th><th class="p-3">الحد الأدنى</th><th class="p-3">الطريقة</th><th class="p-3">القيمة</th></tr></thead><tbody>'+(rows||'<tr><td colspan="5" class="p-8 text-center text-slate-400">لا توجد قواعد</td></tr>')+'</tbody></table></div></div></div>'); byId('pld-back').onclick=function(){RW_Navigation.navigate('price-lists');}; }catch(e){hideLoader();showToast(e.message,'error');}
}
```

---

## PATCH-13 — تحويل Promotion Detail إلى Page

**الملف:** `Current/PWA/main.html`  
**الدالة:** `RW_Promotions.showDetail(id)`  
**السطر:** 29000

**احذف الدالة كاملة واستبدلها بـ:**

```
async function showDetail(id) {
    var r=await api('detail',{promotion_id:id}), p=r.promotion||{}, c=byId('rw-page-container'); if(!c)return;
    var rows=(r.rules||[]).map(function(x){return '<div class="border rounded-2xl p-3 grid grid-cols-2 md:grid-cols-6 gap-2 text-sm"><span>Scope: <b>'+esc(x.scope_type)+'</b></span><span>Trigger: <b>'+esc(x.trigger_qty)+'</b></span><span>Reward: <b>'+esc(x.reward_type)+'</b></span><span>Value: <b>'+esc(x.reward_value)+'</b></span><span>Reward Qty: <b>'+esc(x.reward_qty)+'</b></span><span>Active: <b>'+esc(x.is_active?'نعم':'لا')+'</b></span></div>';}).join('');
    safeHTML(c,'<div class="space-y-6"><div class="flex justify-between"><div><div class="text-sm text-blue-600 font-black">العروض والخصومات</div><h2 class="text-3xl font-black mt-1">تفاصيل العرض: '+esc(p.name)+'</h2></div><button id="pd-back" class="px-4 py-2 rounded-xl bg-slate-100 font-black">رجوع</button></div><div class="grid grid-cols-2 md:grid-cols-5 gap-3"><div class="bg-white border rounded-2xl p-3">الكود<div class="font-black mt-1">'+esc(p.code)+'</div></div><div class="bg-white border rounded-2xl p-3">النوع<div class="font-black mt-1">'+esc(p.promotion_type)+'</div></div><div class="bg-white border rounded-2xl p-3">القناة<div class="font-black mt-1">'+esc(p.channel_scope)+'</div></div><div class="bg-white border rounded-2xl p-3">الحد الأدنى<div class="font-black mt-1">'+esc(p.min_subtotal)+'</div></div><div class="bg-white border rounded-2xl p-3">الحالة<div class="font-black mt-1">'+esc(p.is_active?'نشط':'غير نشط')+'</div></div></div><div class="bg-white border rounded-3xl p-5"><h3 class="font-black text-xl mb-3">قواعد العرض</h3><div class="space-y-2">'+(rows||'<div class="text-slate-400">لا توجد قواعد فعالة</div>')+'</div></div></div>');
    byId('pd-back').onclick=function(){RW_Navigation.navigate('promotions');};
}
```

---

## PATCH-14 — تحويل Promotion Editor إلى Page

**الملف:** `Current/PWA/main.html`  
**الدالة:** `RW_Promotions.openEditor(id)`  
**السطر:** 29017

**احذف الدالة كاملة واستبدلها بـ:**

```
async function openEditor(id) {
    if(!state.catalog.items.length)await loadCatalog();
    var p=id?(await api('detail',{promotion_id:id})).promotion:{}, detail=id?await api('detail',{promotion_id:id}):{rules:[]}, rules=detail.rules||[], c=byId('rw-page-container'); if(!c)return;
    safeHTML(c,'<div class="space-y-6"><div class="flex justify-between"><div><div class="text-sm text-blue-600 font-black">العروض والخصومات</div><h2 class="text-3xl font-black mt-1">'+esc(id?'تعديل العرض':'إنشاء عرض جديد')+'</h2></div><button id="promo-close" class="px-4 py-2 rounded-xl bg-slate-100 font-black">رجوع</button></div><div class="grid grid-cols-1 md:grid-cols-4 gap-3"><input id="promo-code" class="p-3 border rounded-xl" placeholder="كود العرض" value="'+esc(p.code||'')+'"><input id="promo-name" class="p-3 border rounded-xl" placeholder="اسم العرض" value="'+esc(p.name||'')+'"><select id="promo-type" class="p-3 border rounded-xl"><option value="discount">خصم</option><option value="cheapest_item">خصم على الأرخص</option><option value="buy_x_get_y">Buy X Get Y</option></select><select id="promo-stack" class="p-3 border rounded-xl"><option value="exclusive">عرض حصري</option><option value="stackable">قابل للتجميع</option></select></div><div class="grid grid-cols-1 md:grid-cols-5 gap-3"><select id="promo-trigger" class="p-3 border rounded-xl"><option value="automatic">تلقائي</option><option value="code">بكود</option></select><input id="promo-coupon" class="p-3 border rounded-xl" placeholder="Coupon Code" value="'+esc(p.coupon_code||'')+'"><select id="promo-channel" class="p-3 border rounded-xl"><option value="all">كل القنوات</option><option value="pos">POS</option><option value="telesales">Telesales</option><option value="order-taker">Order Taker</option><option value="van-sales">Van Sales</option><option value="online-store">Online Store</option></select><input id="promo-priority" type="number" min="0" class="p-3 border rounded-xl" value="'+esc(p.priority==null?100:p.priority)+'"><input id="promo-min-subtotal" type="number" min="0" step="0.01" class="p-3 border rounded-xl" placeholder="حد أدنى للسلة" value="'+esc(p.min_subtotal||0)+'"></div><div class="grid grid-cols-1 md:grid-cols-4 gap-3"><input id="promo-valid-from" type="date" class="p-3 border rounded-xl" value="'+esc(p.valid_from||'')+'"><input id="promo-valid-until" type="date" class="p-3 border rounded-xl" value="'+esc(p.valid_until||'')+'"><input id="promo-max-discount" type="number" min="0" class="p-3 border rounded-xl" value="'+esc(p.max_discount||0)+'"><label class="flex items-center gap-2 p-3 border rounded-xl font-black"><input id="promo-active" type="checkbox" '+(p.is_active===false?'':'checked')+'> العرض نشط</label></div><div class="bg-white border rounded-3xl p-5"><div class="flex justify-between mb-3"><h3 class="font-black text-xl">قواعد العرض</h3><button id="promo-rule-add" class="px-4 py-2 rounded-xl bg-violet-600 text-white font-black">+ قاعدة</button></div><div id="promo-rules" class="space-y-2"></div></div><button id="promo-save" class="px-6 py-3 rounded-2xl bg-blue-600 text-white font-black">حفظ العرض</button></div>');
    byId('promo-type').value=p.promotion_type||'discount';byId('promo-stack').value=p.stacking_policy||'exclusive';byId('promo-trigger').value=p.trigger_mode||'automatic';byId('promo-channel').value=p.channel_scope||'all';
    rules.forEach(addRuleRow); byId('promo-rule-add').onclick=function(){addRuleRow({});}; byId('promo-close').onclick=function(){RW_Navigation.navigate('promotions');}; byId('promo-save').onclick=function(){save(id);};
}
```

---

## PATCH-15 — تحويل Sales Return Review إلى Page

**الملف:** `Current/PWA/main.html`  
**الدالة:** `RW_SalesReturnsManagement._openDetail(id)`  
**السطر:** 28067

**احذف الدالة كاملة واستبدلها بـ:**

```
async function _openDetail(id) {
    showLoader('جاري تحميل تفاصيل المرتجع...');
    try {
        var res=await _api('detail',{credit_note_id:id}); hideLoader(); var h=res.header||{}, lines=res.lines||[], events=res.events||[], c=byId('rw-page-container'); if(!c)return;
        var lineHtml=lines.map(function(l){return '<tr class="border-t"><td class="p-2">'+_esc(l.item_code)+'</td><td class="p-2 font-bold">'+_esc(l.item_name)+'</td><td class="p-2">'+_esc(l.unit)+'</td><td class="p-2">'+_esc(l.original_qty||0)+'</td><td class="p-2 font-black text-rose-600">'+_esc(l.qty_returned||0)+'</td><td class="p-2">'+_esc(l.return_condition||'—')+'</td></tr>';}).join('');
        var eventHtml=events.map(function(ev){return '<div class="border rounded-xl p-3 bg-slate-50"><div class="flex justify-between gap-3"><b>'+_esc(ev.action)+'</b><span class="text-xs text-gray-500">'+_esc(ev.created_at)+'</span></div><div class="text-xs mt-1">'+_esc(ev.from_status||'—')+' → '+_esc(ev.to_status||'—')+' | '+_esc(ev.actor_email||'')+'</div><div class="text-sm mt-1">'+_esc(ev.note||ev.resolution||'')+'</div></div>';}).join('');
        safeHTML(c,'<div class="space-y-6"><div class="flex justify-between"><div><div class="text-sm text-blue-600 font-black">إدارة مرتجعات المبيعات</div><h2 class="text-3xl font-black mt-1">إدارة المرتجع: '+_esc(h.cn_code||'')+'</h2></div><button id="srm-back" class="px-4 py-2 rounded-xl bg-slate-100 font-black">رجوع</button></div><div class="grid grid-cols-2 md:grid-cols-4 gap-3"><div class="bg-white border rounded-2xl p-3">المصدر<div class="font-black mt-1">'+_esc(h.source_type)+'</div></div><div class="bg-white border rounded-2xl p-3">العميل<div class="font-black mt-1">'+_esc(h.customer_name||'-')+'</div></div><div class="bg-rose-50 border rounded-2xl p-3">القيمة<div class="font-black text-rose-700 mt-1">'+esc(Number(h.total_amount||0).toLocaleString('ar-EG'))+' EGP</div></div><div class="bg-white border rounded-2xl p-3">الحالة<div class="font-black mt-1">'+_esc(h.review_status||'open')+'</div></div></div><div class="bg-white border rounded-3xl overflow-hidden"><div class="p-5"><h3 class="font-black text-xl">تفاصيل الأصناف</h3></div><div class="overflow-x-auto"><table class="w-full text-sm"><thead class="bg-slate-50"><tr><th class="p-2">الكود</th><th class="p-2">الصنف</th><th class="p-2">الوحدة</th><th class="p-2">الأصلي</th><th class="p-2">مرتجع</th><th class="p-2">الحالة</th></tr></thead><tbody>'+lineHtml+'</tbody></table></div></div><div class="bg-white border rounded-3xl p-5"><h3 class="font-black text-xl mb-3">المراجعة الإدارية</h3><div class="grid grid-cols-1 md:grid-cols-3 gap-3"><select id="srm-modal-status" class="p-3 border rounded-xl"><option value="open">مفتوح</option><option value="reviewing">قيد المراجعة</option><option value="resolved">تمت التسوية</option><option value="disputed">متنازع عليها</option><option value="cancelled">ملغاة</option></select><select id="srm-modal-assignee" class="p-3 border rounded-xl">'+_assigneeOptions(h.assigned_to)+'</select><button id="srm-modal-save" class="p-3 bg-indigo-600 text-white rounded-xl font-black">حفظ المراجعة</button></div><input id="srm-modal-note" class="w-full p-3 border rounded-xl mt-3" placeholder="ملاحظة المراجعة" value="'+_esc(h.review_note||'')+'"><textarea id="srm-modal-resolution" class="w-full p-3 border rounded-xl mt-3" rows="3" placeholder="قرار / تسوية / معالجة">'+_esc(h.resolution||'')+'</textarea></div><div class="bg-white border rounded-3xl p-5"><h3 class="font-black text-xl mb-3">سجل المراجعة</h3><div class="space-y-2">'+(eventHtml||'<div class="text-slate-400">لا يوجد سجل</div>')+'</div></div></div>');
        byId('srm-back').onclick=function(){RW_Navigation.navigate('sales-returns');};
        byId('srm-modal-status').value=h.review_status||'open';
        byId('srm-modal-save').onclick=async function(){showLoader('جاري حفظ المراجعة...');try{await _api('review',{credit_note_id:id,status:byId('srm-modal-status').value,assigned_to:byId('srm-modal-assignee').value||null,note:byId('srm-modal-note').value.trim()||null,resolution:byId('srm-modal-resolution').value.trim()||null});hideLoader();showToast('تم حفظ مراجعة المرتجع','success');RW_Navigation.navigate('sales-returns');}catch(e){hideLoader();showToast(e.message||'فشل الحفظ','error');}};
    }catch(e){hideLoader();showToast(e.message||'فشل تحميل التفاصيل','error');}
}
```

---

## PATCH-16 — تحويل Loyalty Program Creation إلى Page

**الملف:** `Current/PWA/main.html`  
**الدالة:** `RW_LoyaltyMain.newProgram()`  
**السطر:** 4033

**احذف الدالة كاملة واستبدلها بـ:**

```
async function newProgram(){
    if(!canConfig()) throw new Error('ليس لديك صلاحية إدارة البرامج');
    var c=byId('rw-page-container'); if(!c)return;
    safeHTML(c,'<div class="max-w-4xl mx-auto space-y-6"><div class="flex justify-between"><div><div class="text-sm text-blue-600 font-black">الولاء والمكافآت</div><h2 class="text-3xl font-black mt-1">برنامج ولاء جديد</h2></div><button id="lyp-back" class="px-4 py-2 rounded-xl bg-slate-100 font-black">رجوع</button></div><div class="bg-white border rounded-3xl p-6 grid grid-cols-1 md:grid-cols-2 gap-4"><input id="ly-code" class="p-3 border rounded-xl" placeholder="كود البرنامج"><input id="ly-name" class="p-3 border rounded-xl" placeholder="اسم البرنامج"><input id="ly-earn-amount" type="number" min="0.01" class="p-3 border rounded-xl" placeholder="كل كم جنيه؟" value="10"><input id="ly-earn-points" type="number" min="1" class="p-3 border rounded-xl" placeholder="عدد النقاط" value="1"><input id="ly-min" type="number" min="1" class="p-3 border rounded-xl" placeholder="الحد الأدنى للاستبدال" value="100"><input id="ly-expiry" type="number" min="1" class="p-3 border rounded-xl" placeholder="أيام الانتهاء"><button id="ly-save" class="md:col-span-2 px-6 py-3 rounded-2xl bg-blue-600 text-white font-black">حفظ البرنامج</button></div></div>');
    byId('lyp-back').onclick=function(){RW_Navigation.navigate('loyalty');};
    byId('ly-save').onclick=async function(){var code=String(byId('ly-code').value||'').trim(),name=String(byId('ly-name').value||'').trim();if(!code||!name)return showToast('الكود والاسم مطلوبان','warning');showLoader('جاري حفظ البرنامج...');try{await call('SAVE_PROGRAM',{program_code:code,name:name,status:'Draft',priority:100,earn_amount:Number(byId('ly-earn-amount').value||10),earn_points:Number(byId('ly-earn-points').value||1),minimum_redeem_points:Number(byId('ly-min').value||100),expiry_days:String(byId('ly-expiry').value||'').trim()},uid());await loadPrograms();hideLoader();showToast('تم حفظ البرنامج','success');RW_Navigation.navigate('loyalty');}catch(e){hideLoader();showToast(e.message,'error');}};
}
```

---

## PATCH-17 — تحويل Loyalty Reward Creation إلى Page

**الملف:** `Current/PWA/main.html`  
**الدالة:** `RW_LoyaltyMain.newReward()`  
**السطر:** 4039

**احذف الدالة كاملة واستبدلها بـ:**

```
async function newReward(){
    if(!canConfig()) throw new Error('ليس لديك صلاحية إدارة المكافآت');
    var active=currentPrograms.find(function(x){return x.status==='Active';}); if(!active) throw new Error('اعتمد برنامجًا نشطًا أولًا');
    var c=byId('rw-page-container'); if(!c)return;
    safeHTML(c,'<div class="max-w-4xl mx-auto space-y-6"><div class="flex justify-between"><div><div class="text-sm text-blue-600 font-black">الولاء والمكافآت</div><h2 class="text-3xl font-black mt-1">مكافأة جديدة</h2></div><button id="lyr-back" class="px-4 py-2 rounded-xl bg-slate-100 font-black">رجوع</button></div><div class="bg-white border rounded-3xl p-6 grid grid-cols-1 md:grid-cols-2 gap-4"><input id="ly-r-code" class="p-3 border rounded-xl" placeholder="كود المكافأة"><input id="ly-r-name" class="p-3 border rounded-xl" placeholder="اسم المكافأة"><input id="ly-r-points" type="number" min="1" class="p-3 border rounded-xl" placeholder="تكلفة النقاط" value="100"><input id="ly-r-value" type="number" min="0" class="p-3 border rounded-xl" placeholder="قيمة المكافأة" value="1"><button id="ly-r-save" class="md:col-span-2 px-6 py-3 rounded-2xl bg-blue-600 text-white font-black">حفظ المكافأة</button></div></div>');
    byId('lyr-back').onclick=function(){RW_Navigation.navigate('loyalty');};
    byId('ly-r-save').onclick=async function(){var code=String(byId('ly-r-code').value||'').trim(),name=String(byId('ly-r-name').value||'').trim();if(!code||!name)return showToast('الكود والاسم مطلوبان','warning');showLoader('جاري حفظ المكافأة...');try{await call('SAVE_REWARD',{program_id:active.id,reward_code:code,name:name,reward_type:'discount',points_cost:Number(byId('ly-r-points').value||0),reward_value:Number(byId('ly-r-value').value||0),active:true},uid());await loadRewards(active.id);hideLoader();showToast('تم حفظ المكافأة','success');RW_Navigation.navigate('loyalty');}catch(e){hideLoader();showToast(e.message,'error');}};
}
```

---

# 8) لا تُعدل هذه العناصر

لا تلمس:
- `save-sales-invoice`
- `submit-online-order`
- `sales-decision-center`
- `sales-target-engine`
- `sales-target-dashboard`
- `loyalty-engine`
- `sales-payment-allocation`
- `commercial-catalog`
- `promotion-engine`
- runsheet/picking/loading/delivery/return field applications

سبب المنع: Production evidence تثبت أن هذه محركات/مسارات قائمة، والهدف هنا Mother orchestration + UX وليس إعادة البناء.

# 9) سبب الخطأ الجذري

## خطأ حالي مثبت
الطبقة الموحدة لم تكن موجودة كـMother route رغم وجود المحركات المنفصلة.

## خطأ UI مثبت
شاشات العمل الثقيلة كانت تُرسم داخل modals، مما يمنع بناء تجربة عمل/رقابة متكاملة ويعزل:
- Quote lifecycle
- Price management
- Promotion management
- Return review
- Order detail
- Loyalty setup
- Telesales customer creation

## خطأ Backend مثبت وتم إغلاقه
`sales_management_center_read` كان يحتوي:
- `APPROVE` بدل `ALLOW`
- `LIMIT 10` في المستوى الذي لا يحد aggregate

وتم تصحيح الاثنين مباشرة في Production.

**لا يوجد في رسالة التكليف الحالية نص خطأ literal أخير يمكن نسبته إلى سبب بعينه؛ لذلك لم يتم اختلاق Error message غير مثبت.**

# 10) Business Contract gaps المتبقية بعد هذا الإغلاق

هذه لا تُعاد بناؤها الآن لأنها تتطلب Contract جديدًا لا تؤكده Production الحالية:
1. حفظ `price list/catalog source` داخل quote كـcommercial snapshot دائم.
2. Price Lock رسمي على المستند بعد الإرسال/الاعتماد.
3. Quote revision numbering/history كامل كمستند versioned.
4. Opportunity/CRM → Quote linkage.

هذه نقاط مستقبلية مستقلة. لا تُخلط مع هذا patch.

# 11) Self Audit

### ما تم إثباته
- Current Mother source examined by exact blob SHA.
- Current System HEAD + parent examined.
- Current Production queried مباشرة.
- Current Edge inventory examined.
- Existing sales engines confirmed.
- Sales Management Center RPC exists and works.
- `ALLOW` contract verified from database constraint.
- Top-10 aggregation flaw fixed.
- Transactional E2E passed and rollback verified.

### ما تم إصلاحه في Production
- `sales_management_center_read` contract/analytics definition.
- No new Edge Function.
- No persistent E2E fixture created.

### ما لم يتم إثباته
- Browser E2E after the owner applies Mother patches.
- Visual pixel-level comparison on an actual browser.
- Live interaction with every sales route because the current toolchain has no browser runtime.

### ما لم يتم فعله عمدًا
- No change to Mother `main.html`.
- No rebuild of already-working sales engines.
- No modification of field operations.
- No new Edge Function.

## Final Closure Status

**PRODUCTION SALES MANAGEMENT CENTER BACKEND: CLOSED**

**MOTHER SALES MANAGEMENT COMMAND SURFACE: OWNER PATCH READY**

**HEAVY SALES WORK MODALS → PAGES: OWNER PATCH READY**

**BROWSER E2E: OPEN — requires owner application of the exact patches above**

**GLOBAL SALES MANAGEMENT CORE INTEGRITY: NOT YET 100% CLOSED until owner applies Mother patches and browser runtime verification is performed.**

# 12) تعليمات للمساعد/CTO التالي

ابدأ دائمًا من:
1. System current HEAD + parent.
2. Current Mother main blob SHA.
3. Current Production counts.
4. Current deployed Edge versions.
5. Current definitions of sales RPCs.
6. ثم تحقق فقط من patches التي يدويًا نفذها المالك.

لا تعُد إلى إصلاح `sales_management_center_read` مرة أخرى ما لم يظهر Production diff جديد.

لا تعتبر أي تقرير سابق حقيقة حالية.

لا تعتبر Browser PASS من مجرد Static Source PASS.

بعد تطبيق Mother patches:
- تحقق من navigation.
- افتح Sales Management Center.
- اختبر period filters.
- افتح recent order من المركز.
- افتح Quotes > new/edit/detail.
- افتح Price Lists > new/edit/assign/detail.
- افتح Promotions > new/detail/edit.
- افتح Sales Returns > detail/review.
- افتح Loyalty > new program/new reward.
- افتح Telesales > new customer.
- ثم اختبر العودة من كل Page إلى أصلها.

**الهدف التالي بعد ذلك فقط:** إغلاق Browser E2E ثم إصدار Report259 وتحديث `CURRENT_STATE.md`.

