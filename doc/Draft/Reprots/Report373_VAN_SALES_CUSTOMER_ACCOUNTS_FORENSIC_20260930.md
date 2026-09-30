# تقرير تدقيقي جنائي — إغلاق وحدة Van Sales: عملائي / مديونية العملاء / الحساب / التحصيل
## التاريخ: 2026-09-30

# 1. SELF-AUDIT — قبل التنفيذ

- فهم الأعمال: 99/100
- فهم المعمارية: 99/100
- فهم قاعدة البيانات: 100/100
- فهم التاريخ: 98/100
- فهم Production: 100/100
- فهم Current: 100/100
- ثقة التنفيذ: 97/100

**حقائق مؤكدة:** 14+
**مجهول مؤثر:** لا يوجد مؤثر على تصميم الجراحة
**تعارض:** لا يوجد في عقد حساب العميل؛ يوجد تعارض مصدر تسمية المندوب في الواجهة مقابل نموذج التخصيص الفعلي
**ادعاء غير مثبت:** الاختبار البصري داخل المتصفح لم يُنفذ آليًا

---

# 2. نقطة البداية الفعلية

المستودع الأم:
`papamohammed77-glitch/rawaie-erp-New`

آخر commits ذات صلة:
- `1305d05b515109fe3a0586aadd6c733fb805210b` — تسجيل RPC قراءة حسابات Van Sales
- `52efb18c62ecfa1eceab4b6bc720ac7b70a02363` — تحديث الحالة
- `d217d8881122483fe5a3c8479b55ba3d013256a1` — Report372

المستودع الأم للواجهة:
`papamohammed77-glitch/erp-frontend`

آخر commit فعلي للواجهة:
`8a972680d3a34ae61cb2d12811d14283c6d99361`
والـparent الظاهر في تاريخ المشروع هو `cf90684a3b1afd017a97e7b7802e9308d6ae158c`.

الملف المحمي:
`companies/company-1/sales/van-sales.html`
ولا يتم تعديله آليًا في هذه الوحدة.

---

# 3. الحقيقة الفعلية من Production

Production Supabase:
`fiilmooggumokxanwiyx`

الموجود فعليًا:

- `get_van_sales_customer_accounts(text,uuid,text)`
- `get_van_sales_customer_account(uuid,text)`
- `post_van_sales_collection_atomic(...)`
- `enforce_van_sales_customer_assignment()`

صلاحيات RPC القراءة:
- anon = لا
- authenticated = نعم
- service_role = نعم

صلاحية التحصيل:
- anon = لا
- authenticated = لا
- service_role = نعم

هذا صحيح أمنيًا لأن التحصيل يتم عبر Edge/الخدمة المصرح بها، بينما قراءة حساب العميل متاحة للمستخدم المصادق عليه وفق صلاحيات Van Sales.

---

# 4. نموذج المندوب الحقيقي

المصدر التنفيذي الحالي ليس `customers.sales_rep`.

العلاقة الفعلية المخصصة للمندوب هي:

`customer_assignments`

بالحقول:

`user_id`
`customer_id`
`assigned_by`
`assigned_at`
`is_active`

Production الحالي يحتوي **0 assignments**.

كما أن `customers.sales_rep` موجود، لكنه حاليًا NULL لجميع العملاء الثلاثة.

**النتيجة:** يجب أن يكون "المندوب" في الواجهة انعكاسًا لعلاقة `customer_assignments`، وليس Lookup على `customers.sales_rep`.

---

# 5. الخطأ الفعلي في Van Sales

الدالة الحالية:

`loadMyCustomers()`
السطر: **389**

تبحث في:

`orders.created_by = currentUser.email`

ثم تحسب:

`totalDebt = مجموع إجمالي الفواتير الآجلة`

وهذا خطأ وظيفي لأنه:

1. لا يعتمد على العميل المخصص للمندوب.
2. لا يعتمد على `customer_ledger` كمصدر المديونية.
3. لا يعالج السداد الجزئي.
4. لا يعكس الرصيد الحقيقي بعد التحصيل.
5. يعتمد على سجل المبيعات السابق بدل نطاق العملاء المسندين.

الدالة الحالية:

`showCustomerDetail()`
تبدأ عند السطر **932**.

وتحتوي خطأ أقوى:

`orders.customer_id = code`

بينما `customers.id` و`orders.customer_id` من النوع UUID، و`code` هنا هو `customer_code`.

كما أنها تحسب المديونية من إجمالي الفواتير الآجلة، بدل دفتر العميل.

---

# 6. Backend الصحيح الموجود بالفعل

لا حاجة لإنشاء Edge Function جديدة.

RPC:

`get_van_sales_customer_accounts`

مخصص مباشرة لهذا السيناريو.

### List

يعيد فقط:
- العملاء داخل الشركة
- العملاء المسندين للمندوب
- العملاء ذوي الرصيد > 0
- البحث بالاسم/الكود/الهاتف/المنطقة
- إجمالي مديونية كل العملاء
- آخر فاتورة
- عدد الفواتير

### Detail

يعيد:
- بيانات العميل
- إجمالي المديونية
- الفواتير
- السداد
- كشف الحساب
- الأقساط

وقد تم اختبار هذا العقد فعليًا داخل Transaction تجريبية ثم `ROLLBACK`.

تم إثبات:
- فاتورة 100
- سداد 20 في نفس اليوم
- الرصيد = 80
- قسط 4 أقساط
- المتبقي = 80
- ظهور الفاتورة والسداد والقسط في payload
- عدم بقاء أي بيانات اختبار في Production.

---

# 7. الحكم المعماري

العقد الصحيح:

`van-sales.html`
→ `get_van_sales_customer_accounts`
→ `customer_assignments`
→ `customer_ledger`
→ invoices / payments / installments

والتحصيل:

`collectPayment()`
→ `save-receipt-voucher`
→ `post_van_sales_collection_atomic`
→ customer ledger + driver ledger + cash receipt

ولا نضيف Edge Function جديدة.

---

# 8. الجراحة المطلوبة في Van Sales

## OWNER SURGICAL PATCH — محفوظ فقط ولا يتم تطبيقه آليًا على الملف المحمي

### A) استبدال الدالة:
`renderCustomersView()`
السطر الحالي: **828**

بالكامل بالنسخة الموجودة في قسم Replacement A أدناه.

### B) استبدال:
`loadMyCustomers()`
السطر الحالي: **389**

بالكامل بالنسخة الموجودة في Replacement B.

### C) استبدال:
`renderMyCustomersList()`
السطر الحالي: **846**

بالكامل بالنسخة الموجودة في Replacement C.

### D) استبدال:
`filterMyCustomers()`
السطر الحالي: **901**

بالكامل بالنسخة الموجودة في Replacement D.

### E) استبدال:
`showCustomerDetail()`
السطر الحالي: **932**

بالكامل بالنسخة الموجودة في Replacement E.

**لا يتم تعديل `picker` أو `main.html` أو `warehouse/vouchers.html` في هذه الوحدة.**

---

# 9. Replacement A — renderCustomersView

```javascript
renderCustomersView: function() {
    var self = this;

    RW_UI.showSkeleton('mainContent', 4, 'card');

    var html = '<div class="p-4 animate-fadeIn">';

    html += '<div class="flex items-center justify-between mb-4">';
    html += '<div>';
    html += '<h2 class="text-xl font-black text-slate-800">👥 عملائي</h2>';
    html += '<p class="text-xs text-slate-400 mt-1">العملاء المسندون إليّ ممن لديهم مديونية قائمة</p>';
    html += '</div>';
    html += '<span class="text-xs bg-orange-50 text-orange-600 px-3 py-1 rounded-full font-bold">المندوب</span>';
    html += '</div>';

    html += '<div class="bg-gradient-to-r from-red-500 to-orange-500 text-white rounded-2xl p-5 mb-4 shadow-lg">';
    html += '<div class="flex items-center justify-between">';
    html += '<div>';
    html += '<p class="text-xs opacity-80">إجمالي مديونية عملائي</p>';
    html += '<p id="myCustomersTotalDebt" class="text-3xl font-black mt-1">0 ج.م</p>';
    html += '</div>';
    html += '<div class="text-right">';
    html += '<p id="myCustomersCount" class="text-2xl font-black">0</p>';
    html += '<p class="text-[11px] opacity-80">عميل مدين</p>';
    html += '</div>';
    html += '</div>';
    html += '</div>';

    html += '<div class="bg-white p-3 rounded-2xl border border-slate-100 shadow-sm mb-4">';
    html += '<label class="text-xs font-bold text-slate-500 block mb-2">بحث ذكي في العملاء المسندين إليك</label>';
    html += '<div class="relative">';
    html += '<input type="text" id="myCustSearch" oninput="App.filterMyCustomers()" placeholder="🔍 الاسم أو الكود أو الهاتف أو المنطقة..." class="w-full p-3 pr-10 bg-slate-50 rounded-xl border-2 border-slate-100 focus:border-orange-400 outline-none font-bold text-sm">';
    html += '<i class="fa-solid fa-magnifying-glass absolute right-3 top-3.5 text-slate-400"></i>';
    html += '</div>';
    html += '</div>';

    html += '<div class="overflow-x-auto bg-white rounded-2xl border border-slate-100 shadow-sm">';
    html += '<div id="myCustomersList"></div>';
    html += '</div>';

    html += '</div>';

    setTimeout(function() {
        RW_UI.safeHTML(RW_UI.byId('mainContent'), html);
        self.loadMyCustomers();
    }, 250);
},
```

---

# 10. Replacement B — loadMyCustomers

```javascript
loadMyCustomers: function() {
    var self = this;
    if (!this.currentUser) return;

    var db = RW_DB.getDB('VanSales');

    RW_UI.showLoader('جاري تحميل عملائي والمديونيات...');

    supabase.rpc('get_van_sales_customer_accounts', {
        p_mode: 'list',
        p_customer_id: null,
        p_search: null
    }).then(function(res) {
        RW_UI.hideLoader();

        if (res.error) {
            throw res.error;
        }

        var payload = res.data || {};
        if (!payload.success) {
            throw new Error(payload.msg || 'تعذر تحميل عملائي');
        }

        var customers = Array.isArray(payload.customers)
            ? payload.customers
            : [];

        var totalDebt = Number(payload.total_customer_debt) || 0;

        var mapped = customers.map(function(c) {
            return {
                customer_id: c.id || c.customer_id || null,
                customer_code: c.customer_code || '',
                name: c.name || c.customer_name || '',
                area: c.area || '',
                phone: c.phone || '',
                payment_type: c.payment_type || '',
                credit_limit: Number(c.credit_limit) || 0,
                totalDebt: Number(c.total_debt) || 0,
                lastOrderDate: c.last_invoice_date || null,
                orderCount: Number(c.invoice_count) || 0
            };
        });

        if (db && db.myCustomers) {
            return db.myCustomers.clear().then(function() {
                return db.myCustomers.bulkPut(mapped);
            }).then(function() {
                self._myCustomersServerTotalDebt = totalDebt;
                self._myCustomersServerCount = mapped.length;

                var totalEl = RW_UI.byId('myCustomersTotalDebt');
                var countEl = RW_UI.byId('myCustomersCount');

                if (totalEl) {
                    RW_UI.safeText(
                        totalEl,
                        RW_UI.formatNumber(totalDebt) + ' ج.م'
                    );
                }

                if (countEl) {
                    RW_UI.safeText(
                        countEl,
                        String(mapped.length)
                    );
                }

                self.renderMyCustomersList(mapped);
            });
        }

        self._myCustomersServerTotalDebt = totalDebt;
        self._myCustomersServerCount = mapped.length;

        var totalEl2 = RW_UI.byId('myCustomersTotalDebt');
        var countEl2 = RW_UI.byId('myCustomersCount');

        if (totalEl2) {
            RW_UI.safeText(
                totalEl2,
                RW_UI.formatNumber(totalDebt) + ' ج.م'
            );
        }

        if (countEl2) {
            RW_UI.safeText(
                countEl2,
                String(mapped.length)
            );
        }

        self.renderMyCustomersList(mapped);
    }).catch(function(err) {
        RW_UI.hideLoader();

        console.error('loadMyCustomers:', err);

        RW_UI.safeHTML(
            RW_UI.byId('myCustomersList'),
            '<div class="text-center py-12">' +
            '<p class="text-red-400 font-bold">تعذر تحميل عملائك والمديونيات</p>' +
            '<p class="text-xs text-slate-400 mt-2">تحقق من اتصال الحساب وصلاحيات المندوب وتخصيص العملاء.</p>' +
            '</div>'
        );
    });
},
```

---

# 11. Replacement C — renderMyCustomersList

```javascript
renderMyCustomersList: function(listOverride) {
    var self = this;
    var container = RW_UI.byId('myCustomersList');
    if (!container) return;

    var db = RW_DB.getDB('VanSales');

    var loadList = listOverride
        ? Promise.resolve(listOverride)
        : (db && db.myCustomers
            ? db.myCustomers.toArray()
            : Promise.resolve([]));

    loadList.then(function(list) {
        list = Array.isArray(list) ? list : [];

        list.sort(function(a, b) {
            return (Number(b.totalDebt) || 0) - (Number(a.totalDebt) || 0);
        });

        var totalDebt = 0;

        for (var i = 0; i < list.length; i++) {
            totalDebt += Number(list[i].totalDebt) || 0;
        }

        var totalEl = RW_UI.byId('myCustomersTotalDebt');
        var countEl = RW_UI.byId('myCustomersCount');

        if (totalEl) {
            RW_UI.safeText(
                totalEl,
                RW_UI.formatNumber(totalDebt) + ' ج.م'
            );
        }

        if (countEl) {
            RW_UI.safeText(
                countEl,
                String(list.length)
            );
        }

        if (!list.length) {
            RW_UI.safeHTML(
                container,
                '<div class="text-center py-12">' +
                '<div class="text-6xl mb-4">✅</div>' +
                '<p class="text-slate-400 font-bold">لا توجد مديونيات لعملائك</p>' +
                '<p class="text-xs text-slate-300 mt-1">سيظهر هنا العملاء المسندون إليك الذين لديهم رصيد مستحق.</p>' +
                '</div>'
            );
            return;
        }

        var html = '<table class="w-full text-sm">';
        html += '<thead class="bg-slate-50 border-b border-slate-100">';
        html += '<tr>';
        html += '<th class="p-3 text-right font-black text-slate-500">العميل</th>';
        html += '<th class="p-3 text-right font-black text-slate-500">المديونية</th>';
        html += '<th class="p-3 text-right font-black text-slate-500">آخر فاتورة</th>';
        html += '<th class="p-3 text-center font-black text-slate-500">الإجراءات</th>';
        html += '</tr>';
        html += '</thead><tbody>';

        for (var j = 0; j < list.length; j++) {
            var c = list[j];
            var customerId = String(c.customer_id || '');
            var code = String(c.customer_code || '');
            var name = String(c.name || code);

            var safeName = name.replace(/'/g, "\'");
            var debt = Number(c.totalDebt) || 0;

            html += '<tr class="border-b border-slate-100 hover:bg-orange-50 transition">';
            html += '<td class="p-3">';
            html += '<button onclick="App.showCustomerDetail(\'' + customerId + '\',\'' + safeName + '\')" class="text-right w-full">';
            html += '<div class="font-black text-slate-800">' + name + '</div>';
            html += '<div class="text-xs text-slate-400 mt-1">' + code +
                (c.phone ? ' · ' + String(c.phone) : '') +
                (c.area ? ' · ' + String(c.area) : '') +
                '</div>';
            html += '</button>';
            html += '</td>';

            html += '<td class="p-3">';
            html += '<span class="font-black text-red-600">' +
                RW_UI.formatNumber(debt) +
                ' ج.م</span>';
            html += '</td>';

            html += '<td class="p-3 text-slate-500 text-xs">';
            html += c.lastOrderDate
                ? new Date(c.lastOrderDate).toLocaleDateString('ar-EG')
                : '---';
            html += '<div class="text-[10px] text-slate-300 mt-1">' +
                (Number(c.orderCount) || 0) + ' فاتورة</div>';
            html += '</td>';

            html += '<td class="p-3 text-center">';
            html += '<button onclick="App.collectPayment(\'' + customerId + '\',\'' + safeName + '\')" class="inline-flex items-center justify-center gap-1 bg-emerald-600 text-white px-3 py-2 rounded-xl text-xs font-black shadow-sm active:scale-95 transition">';
            html += '<i class="fa-solid fa-hand-holding-dollar"></i> تحصيل';
            html += '</button>';
            html += '</td>';

            html += '</tr>';
        }

        html += '</tbody></table>';

        RW_UI.safeHTML(container, html);
    }).catch(function(err) {
        console.error('renderMyCustomersList:', err);
        RW_UI.safeHTML(
            container,
            '<div class="text-center py-12">' +
            '<p class="text-red-400 font-bold">تعذر عرض العملاء</p>' +
            '</div>'
        );
    });
},
```

---

# 12. Replacement D — filterMyCustomers

```javascript
filterMyCustomers: function() {
    var self = this;

    var input = RW_UI.byId('myCustSearch');
    var q = input
        ? String(input.value || '').trim().toLowerCase()
        : '';

    var db = RW_DB.getDB('VanSales');
    if (!db || !db.myCustomers) return;

    db.myCustomers.toArray().then(function(list) {
        list = Array.isArray(list) ? list : [];

        if (!q) {
            self.renderMyCustomersList(list);
            return;
        }

        var filtered = [];

        for (var i = 0; i < list.length; i++) {
            var c = list[i];

            var haystack = [
                c.name || '',
                c.customer_code || '',
                c.phone || '',
                c.area || ''
            ].join(' ').toLowerCase();

            if (haystack.indexOf(q) !== -1) {
                filtered.push(c);
            }
        }

        self.renderMyCustomersList(filtered);
    }).catch(function(err) {
        console.error('filterMyCustomers:', err);
    });
},
```

---

# 13. Replacement E — showCustomerDetail

```javascript
showCustomerDetail: function(customerId, name) {
    var self = this;

    customerId = String(customerId || '').trim();

    if (!customerId) {
        RW_UI.toast('هوية العميل غير محددة', 'error');
        return;
    }

    RW_UI.showLoader('جاري تحميل حساب العميل...');

    supabase.rpc('get_van_sales_customer_accounts', {
        p_mode: 'detail',
        p_customer_id: customerId,
        p_search: null
    }).then(function(res) {
        RW_UI.hideLoader();

        if (res.error) {
            throw res.error;
        }

        var data = res.data || {};

        if (!data.success) {
            throw new Error(data.msg || 'تعذر تحميل حساب العميل');
        }

        var customer = data.customer || {};
        var totalDebt = Number(data.total_debt) || 0;
        var invoices = Array.isArray(data.invoices) ? data.invoices : [];
        var payments = Array.isArray(data.payments) ? data.payments : [];
        var statement = Array.isArray(data.statement) ? data.statement : [];
        var installments = Array.isArray(data.installments) ? data.installments : [];

        var html = '<div class="text-right max-h-[75vh] overflow-y-auto pr-1">';

        html += '<div class="bg-gradient-to-r from-orange-500 to-amber-500 text-white rounded-2xl p-5 mb-4">';
        html += '<div class="flex justify-between items-start gap-3">';
        html += '<div>';
        html += '<h3 class="font-black text-xl">' + (customer.name || name || customer.customer_code || 'العميل') + '</h3>';
        html += '<p class="text-xs opacity-80 mt-1">' + (customer.customer_code || '') +
            (customer.phone ? ' · ' + customer.phone : '') +
            (customer.area ? ' · ' + customer.area : '') +
            '</p>';
        html += '</div>';
        html += '<span class="text-xs bg-white/15 px-2 py-1 rounded-lg font-bold">حساب العميل</span>';
        html += '</div>';

        html += '<div class="mt-4 flex justify-between items-end">';
        html += '<div><p class="text-xs opacity-75">الرصيد المستحق</p>';
        html += '<p class="text-3xl font-black">' + RW_UI.formatNumber(totalDebt) + ' ج.م</p></div>';
        html += '<div class="text-left text-xs opacity-80">حد ائتماني: ' +
            RW_UI.formatNumber(Number(customer.credit_limit) || 0) + ' ج.م</div>';
        html += '</div>';
        html += '</div>';

        html += '<div class="grid grid-cols-2 gap-2 mb-4">';
        html += '<div class="bg-red-50 rounded-xl p-3"><p class="text-xs text-red-500">المستحق</p><p class="font-black text-red-700">' +
            RW_UI.formatNumber(totalDebt) + ' ج.م</p></div>';
        html += '<div class="bg-blue-50 rounded-xl p-3"><p class="text-xs text-blue-500">الأقساط القائمة</p><p class="font-black text-blue-700">' +
            RW_UI.formatNumber(installments.reduce(function(sum, x) { return sum + (Number(x.remaining_amount) || 0); }, 0)) +
            ' ج.م</p></div>';
        html += '</div>';

        html += '<div class="card mb-4">';
        html += '<div class="flex justify-between items-center mb-3">';
        html += '<h4 class="font-black text-slate-700">📄 المسحوبات / الفواتير</h4>';
        html += '<span class="text-xs text-slate-400">' + invoices.length + ' فاتورة</span>';
        html += '</div>';

        if (!invoices.length) {
            html += '<p class="text-slate-400 text-center py-5">لا توجد فواتير Van Sales مسجلة.</p>';
        } else {
            html += '<div class="space-y-2">';
            for (var i = 0; i < invoices.length; i++) {
                var inv = invoices[i];
                html += '<div class="p-3 rounded-xl bg-slate-50 border border-slate-100">';
                html += '<div class="flex justify-between items-start gap-2">';
                html += '<div><p class="font-black text-sm">' + (inv.order_code || '---') + '</p>';
                html += '<p class="text-xs text-slate-400">' + (inv.order_date || '---') + '</p></div>';
                html += '<p class="font-black text-orange-600">' +
                    RW_UI.formatNumber(Number(inv.total_amount) || 0) + ' ج.م</p>';
                html += '</div>';
                html += '<div class="text-xs text-slate-500 mt-1">' +
                    (inv.payment_type || '') + ' · ' +
                    (inv.order_status || '') + '</div>';
                html += '</div>';
            }
            html += '</div>';
        }
        html += '</div>';

        html += '<div class="card mb-4">';
        html += '<div class="flex justify-between items-center mb-3">';
        html += '<h4 class="font-black text-slate-700">💳 السداد</h4>';
        html += '<span class="text-xs text-slate-400">' + payments.length + ' حركة</span>';
        html += '</div>';

        if (!payments.length) {
            html += '<p class="text-slate-400 text-center py-5">لا توجد حركات سداد مسجلة.</p>';
        } else {
            html += '<div class="space-y-2">';
            for (var p = 0; p < payments.length; p++) {
                var pay = payments[p];
                html += '<div class="flex justify-between items-center p-3 rounded-xl bg-emerald-50 border border-emerald-100">';
                html += '<div><p class="font-bold text-sm">' + (pay.description || 'سداد') + '</p>';
                html += '<p class="text-xs text-slate-400">' + (pay.entry_date || '---') +
                    (pay.reference ? ' · ' + pay.reference : '') + '</p></div>';
                html += '<span class="font-black text-emerald-600">+' +
                    RW_UI.formatNumber(Number(pay.credit) || 0) + ' ج.م</span>';
                html += '</div>';
            }
            html += '</div>';
        }

        html += '</div>';

        html += '<div class="card mb-4">';
        html += '<h4 class="font-black text-slate-700 mb-3">📆 الأقساط</h4>';

        if (!installments.length) {
            html += '<p class="text-slate-400 text-center py-5">لا توجد أقساط قائمة.</p>';
        } else {
            html += '<div class="space-y-2">';
            for (var k = 0; k < installments.length; k++) {
                var inst = installments[k];
                html += '<div class="p-3 rounded-xl bg-blue-50 border border-blue-100">';
                html += '<div class="flex justify-between items-center">';
                html += '<span class="font-bold text-sm">' + (inst.installment_id || 'قسط') + '</span>';
                html += '<span class="font-black text-blue-700">' +
                    RW_UI.formatNumber(Number(inst.remaining_amount) || 0) + ' ج.م متبقي</span>';
                html += '</div>';
                html += '<div class="text-xs text-slate-400 mt-1">' +
                    'الإجمالي: ' + RW_UI.formatNumber(Number(inst.total_amount) || 0) +
                    ' · المدفوع: ' + RW_UI.formatNumber(Number(inst.paid_amount) || 0) +
                    ' · عدد الأقساط: ' + (inst.installment_count || '---') +
                    '</div>';
                html += '</div>';
            }
            html += '</div>';
        }

        html += '</div>';

        html += '<div class="card mb-4">';
        html += '<h4 class="font-black text-slate-700 mb-3">📒 كشف الحساب</h4>';

        if (!statement.length) {
            html += '<p class="text-slate-400 text-center py-5">لا توجد حركات محاسبية.</p>';
        } else {
            html += '<div class="space-y-2 max-h-64 overflow-y-auto">';
            for (var s = 0; s < statement.length; s++) {
                var row = statement[s];
                var debit = Number(row.debit) || 0;
                var credit = Number(row.credit) || 0;

                html += '<div class="flex justify-between items-center p-2 rounded-lg bg-slate-50">';
                html += '<div><p class="text-xs font-bold text-slate-700">' + (row.description || '') + '</p>';
                html += '<p class="text-[10px] text-slate-400">' + (row.entry_date || '') + '</p></div>';
                html += '<div class="text-left">';
                if (debit > 0) {
                    html += '<span class="font-black text-red-600">+' +
                        RW_UI.formatNumber(debit) + '</span>';
                } else {
                    html += '<span class="font-black text-emerald-600">-' +
                        RW_UI.formatNumber(credit) + '</span>';
                }
                html += '<div class="text-[10px] text-slate-400">الرصيد ' +
                    RW_UI.formatNumber(Number(row.balance) || 0) + '</div>';
                html += '</div></div>';
            }
            html += '</div>';
        }

        html += '</div>';

        html += '<div class="flex gap-2 mt-4 pt-3 border-t border-slate-100">';
        html += '<button onclick="App.openQuickSaleForCustomer(\'' +
            String(customer.customer_code || '').replace(/'/g, "\'") +
            '\')" class="flex-1 bg-orange-600 text-white py-3 rounded-xl font-black text-sm">بيع له</button>';

        html += '<button onclick="App.collectPayment(\'' +
            customerId.replace(/'/g, "\'") +
            '\',\'' +
            String(customer.name || name || '').replace(/'/g, "\'") +
            '\')" class="flex-1 bg-emerald-600 text-white py-3 rounded-xl font-black text-sm">تحصيل</button>';

        html += '</div>';

        html += '</div>';

        Swal.fire({
            title: 'حساب العميل',
            html: html,
            width: '680px',
            showCloseButton: true,
            showConfirmButton: false,
            customClass: { popup: '!rounded-3xl !p-5' }
        });
    }).catch(function(err) {
        RW_UI.hideLoader();
        console.error('showCustomerDetail:', err);
        RW_UI.toast(
            err && err.message
                ? err.message
                : 'فشل تحميل حساب العميل',
            'error'
        );
    });
},
```

---

# 14. لماذا هذه ليست ترقيعات

لا يتم إنشاء حساب مديونية جديد ولا Edge جديدة.

التطبيق يستخدم العقد المالي الموجود بالفعل:

- `customer_assignments` = تحديد العملاء للمندوب
- `customer_ledger` = مصدر الرصيد
- `orders` = فواتير Van Sales
- `installments` = الأقساط
- `post_van_sales_collection_atomic` = التحصيل الذري

وهذا يتفق مع نمط الأنظمة الناضجة التي تفصل بين فواتير العميل وحالته المالية والتحصيل والمتابعة. Odoo يعرض الفواتير المستحقة وكشف الحساب والمتابعة على مستوى العميل، وDynamics 365 يفصل حسابات العملاء والفواتير والمدفوعات، وSAP Direct Store Delivery يدعم تحصيل المدفوعات الحالية والمستحقة من جهاز مندوب البيع وتسوية بيانات الجولة. Manager كذلك يدعم السداد الجزئي وربط التحصيل بالفاتورة أو توزيعه على الفواتير المستحقة. citeturn121619search0turn121619search8turn121619search3turn121619search11

---

# 15. الاختبار الفعلي الذي تم

تم إنشاء Fixture داخل Transaction ثم تنفيذ:

- عميل مسند للمندوب
- فاتورة Van Sales = 100
- سداد نفس اليوم = 20
- رصيد = 80
- 4 أقساط
- المتبقي = 80
- استدعاء List
- استدعاء Detail
- التحقق من invoice/payment/installment payload

ثم:

`ROLLBACK`

ولا بقيت بيانات الاختبار في Production.

---

# 16. ما الذي لم يُنفذ

**لم يتم تعديل الملفات المحمية**:

- `van-sales.html`
- `main.html`
- `warehouse/vouchers.html`

والسبب ليس Block تقنيًا؛ بل لأن تعليمات الملكية لهذه الملفات تجعل الدمج الجراحي من مسؤولية المالك.

ولا توجد حاجة حاليًا إلى Production DDL أو Edge Function جديدة لهذا الجزء.

---

# 17. Owner Execution

على المالك تطبيق التغييرات الخمسة فقط في:

`erp-frontend/companies/company-1/sales/van-sales.html`

ثم تنفيذ Browser E2E من التطبيق الحقيقي.

### السيناريو:

مندوب مباشر
→ عملائي
→ تظهر العملاء المسندة ذات المديونية فقط
→ يظهر إجمالي المديونية بالأعلى
→ بحث ذكي
→ الضغط على العميل
→ المسحوبات
→ السداد
→ الأقساط
→ تحصيل
→ تنفيذ سداد
→ العودة للقائمة والتحقق من انخفاض الرصيد.

---

# 18. ملاحظة Production الحالية

Production الآن:

- customer_assignments = 0
- debtor customers = 0
- orders = 0

لذلك **لن تظهر قائمة عملاء فعلية في الإنتاج حاليًا** حتى يتم تعيين العملاء وإنشاء مديونية فعلية من النظام.

هذا ليس فشلًا في الـRPC؛ بل هو الوضع الحالي للبيانات.

---

# 19. التقرير النهائي للحالة

| العنصر | الحالة |
|---|---|
| Backend customer-account contract | ✅ Production |
| Authorization | ✅ |
| Tenant isolation | ✅ |
| Assigned-customer filtering | ✅ |
| Debtor-only filtering | ✅ |
| Total debt aggregation | ✅ |
| Invoice account | ✅ |
| Same-day payment visibility | ✅ |
| Installment visibility | ✅ |
| Collection backend | ✅ |
| Frontend integration | ⚠️ Owner patch required |
| Browser E2E | ⏳ Owner execution |
| Main modification | ❌ ممنوع |
| Vouchers modification | ❌ ممنوع |
| New Edge Function | ❌ غير مطلوبة |

## حالة وحدة العمل

**Backend Contract = COMPLETE**

**Van Sales Customer UI = OWNER SURGICAL PATCH READY**

**End-to-End Frontend Closure = NOT YET VERIFIED**

---

# 20. SELF-AUDIT — بعد التحقيق

### What I Proved
- Production يحتوي العقد المالي المطلوب فعليًا.
- التخصيص الصحيح هو `customer_assignments`.
- المديونية الصحيحة تأتي من `customer_ledger`.
- الـRPC يستطيع إعادة قائمة المدينين وحساب العميل والفواتير والسداد والأقساط.
- الاختبار التجريبي الكامل مر داخل Transaction ثم عاد Production إلى حالته الأصلية.

### What I Did Not Prove
- الضغط البصري الفعلي على `van-sales.html` بعد تطبيق Owner Patch.

### What I Fixed
- **لا تغيير مباشر في الملفات المحمية.**
- تم تثبيت/التحقق من Backend contract الموجود أصلًا.
- تم إعداد Owner Surgical Patch كامل ودقيق.

### What I Initially Missed
- مصدر "عملائي" الحالي كان يعتمد على المبيعات السابقة لا على التخصيص.
- `showCustomerDetail` يستخدم customer_code في موضع يتطلب customer UUID.

### What Could Still Be Wrong
- أي تعارض في ملف `main.html` عند تطبيق تسمية/إسناد "المندوب" يجب التحقق منه بصريًا بعد الدمج، دون تعديل العقد الخلفي.

### Final Confidence
**97/100 — Backend contract والتحقق المنطقي قوي؛ إغلاق الواجهة يحتاج تطبيق المالك ثم Browser E2E.**

# نقطة الاستكمال التالية

`van-sales.html` — تطبيق Replacement A → E ثم Browser E2E.

ولا توجد حاجة لفتح دالة Edge جديدة.
