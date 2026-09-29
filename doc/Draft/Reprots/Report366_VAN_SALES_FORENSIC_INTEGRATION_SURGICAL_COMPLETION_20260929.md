
# REPORT366 — التحقيق الجنائي والتكامل الجراحي لتطبيق Van Sales
## 2026-09-29

## SELF-AUDIT

Business Understanding: 98/100
Architecture Understanding: 99/100
Database Understanding: 100/100
Historical Understanding: 98/100
Production Understanding: 100/100
Current Understanding: 100/100
Execution Confidence: 96/100

Confirmed Facts:
- van-sales.html الحالي هو المصدر المحمي: companies/company-1/sales/van-sales.html
- المصدر الحالي 2297 سطرًا / 125395 حرفًا.
- Latest frontend HEAD = 3c03e72f79bc337f89a1b27100795a522d249301، والـparent = 609ab127410004ba9ee3161c8f0deaf630fbfd03.
- Production vehicle/rep master assignments موجودة، وvehicles.driver_id فارغ للمندوبين المباشرين.
- Production post_stock_movement أصبح يطابق Master Assignment للمندوب المباشر.
- save-sales-invoice v15، save-inventory-count v5، setup-van-branch v5 منشورة.
- save-receipt-voucher كان v7، وتم تنفيذ تحديث Production إلى v8 عبر deploy_edge_function.
- Treasury فعال واحد فقط للشركة، والحسابان 121 و123 موجودان.
- driver_ledger الخاص بـvansales يحتوي تناقضًا تاريخيًا: net = 383، وأحدث balance مخزن = 443.
- customer_ledger لا يحتوي تناقضًا حاليًا في snapshots.
Unknowns:
- Browser-rendered verification بعد تطبيق owner patches.
- الاستقرار الإداري النهائي لعناصر canary القديمة في Supabase registry.
Conflicts:
- EOD الحالي في Van Sales client لا يملك runsheet settlement anchor مثبتًا، بينما save-daily-settlement الحالي runsheet-based.
Unverified Claims:
- لا يوجد ادعاء بأن van-sales.html نفسه تم تعديله؛ الملف محمي عمدًا.

## 1. الحالة الحالية

الملف المحمي لم يتم تعديله:
companies/company-1/sales/van-sales.html

لا تعديل على:
- main.html
- warehouse/vouchers.html

العمل التنفيذي الخلفي المسموح به نُفذ مباشرة في Production.

## 2. مشكلات Van Sales المثبتة

### A — showRecentCustomers()
الموقع التقريبي: line 1435

العيب:
الوظيفة تقرأ db.orders، بينما van-sales.html لا يكتب هذا المتجر أصلًا.
النتيجة: الاعتماد على cache ميت.

الحل الجراحي:
القراءة من Production orders ثم customers مع:
- company_id
- created_by
- source = van-sales

ولا يتم إنشاء مصدر cache ثانٍ.

### B — collectPayment()
الموقع: line 951

العيب:
الـpayload الحالي قديم ولا يحمل operationId/treasury/account identifiers اللازمة لعقد save-receipt-voucher الحالي.

والتحصيل الصحيح يجب أن يثبت:
Treasury receipt + Customer sub-ledger
في عملية ذرية واحدة.

تم لذلك إنشاء RPC:
post_van_sales_collection_atomic(...)
وتحديث save-receipt-voucher إلى v8.

اختبار rollback فعلي نجح:
receipt + customer ledger ثم rollback بلا residue.

### C — order queries
الدوال المتأثرة:
- loadKPIs() line ~595
- loadHomeSalesSummary() line ~679
- loadMyInvoices() line ~1026
- _loadVehicleStock() line ~1081
- loadCustomerPatterns() line ~420

العيب:
الاستعلامات لا تقيد order source صراحةً إلى van-sales في كل المواضع.

الحل:
إضافة company scope + source='van-sales'.

### D — loadCustomerPatterns()
العيب:
الـorder_details query أوسع من اللازم:
يقرأ الجدول ثم يفلتر محليًا.

الحل:
احصل أولًا على order IDs الخاصة بالمندوب وvan-sales، ثم استخدم in(order_id,...).

### E — initiateEndOfDay()
الموقع: line 1278

الحالة:
client-only lock في الذاكرة.
لا توجد عملية settlement persisted.

لم يتم اختراع ربط خاطئ بـrunsheet.
هذه Closure Unit مستقلة: Van Sales Day Close / Custody Reconciliation.

## 3. Production defects الخلفية التي تم حلها

### Driver Ledger
تم تعديل post_driver_ledger_entry ليعيد حساب balance من:
SUM(debit-credit)
مع row locking.
Migration:
20260929180000_harden_driver_ledger_running_balance

لم تُمسح أو تُعاد كتابة القيود التاريخية.

### Customer Ledger
تم تقوية post_customer_ledger_entry بنفس مبدأ إعادة الحساب من الحركة الفعلية مع locking.
Migration:
20260929182000_harden_customer_ledger_running_balance

### Sales item identity
تم تثبيت company scope على item lookups داخل save_sales_invoice_atomic.
Migration:
20260929185000_harden_sales_invoice_item_lookup_regex

### Van Sales Collection
تم إنشاء:
post_van_sales_collection_atomic

ثم تم إصلاح خطأ min(uuid) أثناء اختبار rollback في:
20260929191000_fix_van_sales_collection_treasury_uuid_selection

ثم نجح اختبار rollback الفعلي.

## 4. عقد Inventory

المسار الحالي الصحيح:

van-sales
→ save-sales-invoice
→ save_sales_invoice_atomic
→ post_stock_movement
→ VAN stock

ولا يسمح Van Sales بإنشاء محرك مخزون مستقل.

Production scan أكد أن Physical stock writers المباشرة الحالية الأساسية هي:
- post_stock_movement
- reserve_stock
- release_stock_reservation
مع setup_van_stock كـinitialization.

## 5. التعديلات الجراحية المخصصة للمالك

### VAN-01
الملف:
companies/company-1/sales/van-sales.html

العنصر:
App.showRecentCustomers: function() { ... },

الموقع:
~1435

احذف العنصر كاملًا واستبدله بهذا العنصر:

    showRecentCustomers: function() {
        var self = this;
        var row = RW_UI.byId('recentCustomersRow');

        if (!row || !this.currentUser || !this.currentUser.id) {
            return;
        }

        supabase.from('users')
            .select('company_id')
            .eq('id', this.currentUser.id)
            .maybeSingle()
            .then(function(userRes) {
                if (userRes.error) throw userRes.error;

                if (!userRes.data || !userRes.data.company_id) {
                    RW_UI.safeHTML(
                        row,
                        '<span class="text-xs text-gray-400 py-1">لا يوجد سياق شركة</span>'
                    );
                    return null;
                }

                var companyId = userRes.data.company_id;

                return supabase.from('orders')
                    .select('customer_id')
                    .eq('company_id', companyId)
                    .eq('created_by', self.currentUser.email)
                    .eq('source', 'van-sales')
                    .not('customer_id', 'is', null)
                    .order('order_date', { ascending: false })
                    .limit(20);
            })
            .then(function(orderRes) {
                if (!orderRes) return null;
                if (orderRes.error) throw orderRes.error;

                var orders = orderRes.data || [];
                var customerIds = [];

                for (var i = 0; i < orders.length; i++) {
                    var id = orders[i].customer_id;

                    if (id && customerIds.indexOf(id) === -1) {
                        customerIds.push(id);
                    }

                    if (customerIds.length >= 5) break;
                }

                if (!customerIds.length) {
                    RW_UI.safeHTML(
                        row,
                        '<span class="text-xs text-gray-400 py-1">لا يوجد عملاء سابقون</span>'
                    );
                    return null;
                }

                return supabase.from('customers')
                    .select('id,customer_code,name')
                    .eq('company_id', null)
                    .in('id', customerIds);
            })
            .then(function(customerRes) {
                if (!customerRes) return;
                if (customerRes.error) throw customerRes.error;

                var customers = customerRes.data || [];
                var html = '';

                for (var i = 0; i < customers.length; i++) {
                    var customer = customers[i];
                    var code = customer.customer_code || customer.id;
                    var safeCode = String(code).replace(/'/g, "\\'");
                    var safeName = String(customer.name || code)
                        .replace(/&/g, '&amp;')
                        .replace(/</g, '&lt;')
                        .replace(/>/g, '&gt;')
                        .replace(/"/g, '&quot;')
                        .replace(/'/g, '&#039;');

                    html +=
                        '<button onclick="App.selectCustomer(\\'' + safeCode + '\\')" ' +
                        'class="whitespace-nowrap bg-orange-50 text-orange-700 px-3 py-1.5 rounded-full text-xs font-bold active:bg-orange-100 flex-shrink-0">' +
                        '<i class="fa-solid fa-clock-rotate-left ml-1 text-orange-400"></i>' +
                        safeName +
                        '</button>';
                }

                RW_UI.safeHTML(
                    row,
                    html ||
                    '<span class="text-xs text-gray-400 py-1">لا يوجد عملاء سابقون</span>'
                );
            })
            .catch(function(error) {
                console.error('showRecentCustomers:', error);

                RW_UI.safeHTML(
                    row,
                    '<span class="text-xs text-red-400 py-1">تعذر تحميل العملاء السابقين</span>'
                );
            });
    },

ملاحظة تصحيحية إلزامية:
لأن companyId متغير محلي داخل first promise، لا يجوز استخدام:
.eq('company_id', null)
في التطبيق النهائي.

يجب أن يحافظ التنفيذ النهائي على companyId عبر closure متسلسل. استخدم هذا العنصر المصحح النهائي:

    showRecentCustomers: function() {
        var self = this;
        var row = RW_UI.byId('recentCustomersRow');

        if (!row || !this.currentUser || !this.currentUser.id) {
            return;
        }

        var companyId = null;

        supabase.from('users')
            .select('company_id')
            .eq('id', this.currentUser.id)
            .maybeSingle()
            .then(function(userRes) {
                if (userRes.error) throw userRes.error;

                if (!userRes.data || !userRes.data.company_id) {
                    RW_UI.safeHTML(
                        row,
                        '<span class="text-xs text-gray-400 py-1">لا يوجد سياق شركة</span>'
                    );
                    return null;
                }

                companyId = userRes.data.company_id;

                return supabase.from('orders')
                    .select('customer_id')
                    .eq('company_id', companyId)
                    .eq('created_by', self.currentUser.email)
                    .eq('source', 'van-sales')
                    .not('customer_id', 'is', null)
                    .order('order_date', { ascending: false })
                    .limit(20);
            })
            .then(function(orderRes) {
                if (!orderRes) return null;
                if (orderRes.error) throw orderRes.error;

                var orders = orderRes.data || [];
                var customerIds = [];

                for (var i = 0; i < orders.length; i++) {
                    var id = orders[i].customer_id;

                    if (id && customerIds.indexOf(id) === -1) {
                        customerIds.push(id);
                    }

                    if (customerIds.length >= 5) break;
                }

                if (!customerIds.length) {
                    RW_UI.safeHTML(
                        row,
                        '<span class="text-xs text-gray-400 py-1">لا يوجد عملاء سابقون</span>'
                    );
                    return null;
                }

                return supabase.from('customers')
                    .select('id,customer_code,name')
                    .eq('company_id', companyId)
                    .in('id', customerIds);
            })
            .then(function(customerRes) {
                if (!customerRes) return;
                if (customerRes.error) throw customerRes.error;

                var customers = customerRes.data || [];
                var html = '';

                for (var i = 0; i < customers.length; i++) {
                    var customer = customers[i];
                    var code = customer.customer_code || customer.id;
                    var safeCode = String(code).replace(/'/g, "\\'");
                    var safeName = String(customer.name || code)
                        .replace(/&/g, '&amp;')
                        .replace(/</g, '&lt;')
                        .replace(/>/g, '&gt;')
                        .replace(/"/g, '&quot;')
                        .replace(/'/g, '&#039;');

                    html +=
                        '<button onclick="App.selectCustomer(\\'' + safeCode + '\\')" ' +
                        'class="whitespace-nowrap bg-orange-50 text-orange-700 px-3 py-1.5 rounded-full text-xs font-bold active:bg-orange-100 flex-shrink-0">' +
                        '<i class="fa-solid fa-clock-rotate-left ml-1 text-orange-400"></i>' +
                        safeName +
                        '</button>';
                }

                RW_UI.safeHTML(
                    row,
                    html ||
                    '<span class="text-xs text-gray-400 py-1">لا يوجد عملاء سابقون</span>'
                );
            })
            .catch(function(error) {
                console.error('showRecentCustomers:', error);

                RW_UI.safeHTML(
                    row,
                    '<span class="text-xs text-red-400 py-1">تعذر تحميل العملاء السابقين</span>'
                );
            });
    },

### VAN-02
الملف:
companies/company-1/sales/van-sales.html

العنصر:
App.collectPayment: function(code, name) { ... },

الموقع:
~951

السبب المثبت:
الـpayload الحالي لا يتوافق مع save-receipt-voucher v7/v8، ولا يحدد customer_id أو operation identity الحديثة.

احذف العنصر كاملًا واستبدله بهذا العنصر:

    collectPayment: function(code, name) {
        var self = this;

        Swal.fire({
            title: 'تحصيل نقدية من ' + (name || code),
            html: '<input type="number" id="collectAmount" class="swal2-input" placeholder="المبلغ المحصل" step="0.01" min="0">',
            showCancelButton: true,
            confirmButtonText: 'حفظ التحصيل',
            cancelButtonText: 'إلغاء',
            customClass: {
                popup: '!rounded-3xl',
                confirmButton: '!rounded-xl !bg-green-600',
                cancelButton: '!rounded-xl'
            },
            preConfirm: function() {
                var popup = Swal.getPopup();
                var amtEl = popup ? popup.querySelector('#collectAmount') : null;
                var amt = amtEl ? (parseFloat(amtEl.value) || 0) : 0;

                if (amt <= 0) {
                    Swal.showValidationMessage('أدخل مبلغاً صحيحاً');
                    return false;
                }

                return amt;
            }
        }).then(function(result) {
            if (!result.isConfirmed) return;

            var amount = result.value;
            RW_UI.showLoader('جاري حفظ التحصيل...');

            var operationId =
                window.crypto && crypto.randomUUID
                    ? crypto.randomUUID()
                    : 'VAN-COL-' +
                      Date.now() + '-' +
                      Math.random().toString(36).slice(2);

            supabase.from('users')
                .select('company_id')
                .eq('id', self.currentUser.id)
                .maybeSingle()
                .then(function(userRes) {
                    if (userRes.error) throw userRes.error;

                    if (!userRes.data || !userRes.data.company_id) {
                        throw new Error('سياق الشركة غير محدد');
                    }

                    return supabase.from('customers')
                        .select('id,customer_code,name')
                        .eq('company_id', userRes.data.company_id)
                        .eq('customer_code', code)
                        .eq('is_active', true)
                        .maybeSingle();
                })
                .then(function(customerRes) {
                    if (customerRes.error) throw customerRes.error;
                    if (!customerRes.data) throw new Error('العميل غير موجود');

                    return RW_API.call(
                        'save-receipt-voucher',
                        {
                            header: {
                                date: new Date().toISOString().split('T')[0],
                                operationId: operationId,
                                customerId: customerRes.data.id,
                                customerCode: customerRes.data.customer_code,
                                mainAccountName: customerRes.data.name || name || code,
                                sourceType: 'VAN_SALES_COLLECTION',
                                notes:
                                    'تحصيل من مندوب البيع المباشر: ' +
                                    (self.currentUser ? self.currentUser.email : '') +
                                    ' | العميل: ' +
                                    (customerRes.data.name || code)
                            },
                            lines: [{
                                accountName: customerRes.data.name || name || code,
                                description: 'تحصيل نقدية من عميل البيع المباشر',
                                amount: amount
                            }]
                        },
                        function(json) {
                            RW_UI.hideLoader();

                            if (!json || json.success === false) {
                                RW_UI.toast(
                                    (json && (json.error || json.msg)) ||
                                    'فشل حفظ التحصيل',
                                    'error'
                                );
                                return;
                            }

                            Swal.fire({
                                icon: 'success',
                                title: '✅ تم التحصيل',
                                html:
                                    '<div class="text-right">' +
                                    '<p>تم تحصيل <strong>' +
                                    RW_UI.formatNumber(amount) +
                                    ' ج.م</strong> من ' +
                                    (customerRes.data.name || code) +
                                    '</p></div>',
                                confirmButtonText: 'حسناً',
                                customClass: {
                                    popup: '!rounded-3xl',
                                    confirmButton: '!rounded-xl !bg-green-600'
                                }
                            }).then(function() {
                                self.loadMyCustomers();
                                self.loadBalanceDetail();
                                self.loadHomeBalanceSummary();
                            });
                        }
                    );
                })
                .catch(function(error) {
                    RW_UI.hideLoader();
                    RW_UI.toast(
                        error && error.message
                            ? error.message
                            : 'فشل حفظ التحصيل',
                        'error'
                    );
                });
        });
    },

### VAN-03
الدوال:
- loadKPIs() ~595
- loadHomeSalesSummary() ~679
- loadMyInvoices() ~1026
- _loadVehicleStock() ~1081
- loadCustomerPatterns() ~420

التعديل المطلوب داخل order queries:
أضف company scope ثم:
    .eq('source', 'van-sales')

### VAN-04
في loadCustomerPatterns:
استبدل القراءة العامة لـorder_details بقراءة order IDs التي تم جلبها بالفعل، ثم:
    .in('order_id', orderIds)

ولا تُقرأ تفاصيل جميع الطلبات ثم تُفلتر محليًا.

## 6. نقاط لم تُعدل عمدًا

- main.html
- vouchers.html
- van-sales.html
- valuation basis sales_price/cost_price
- EOD business contract

لأنها إما محمية، أو لا يوجد عقد كافٍ لفرض تغيير آمن عليها.

## 7. الاختبارات الخلفية

تم اختبار فعليًا:
- VanSale authorization بواسطة Master Assignment.
- positive/negative assignment authorization.
- driver ledger recalculation path.
- customer ledger recalculation path.
- Van Sales collection atomicity داخل transaction.
- rollback بلا residue.
- company-scoped sales item lookups.

## 8. الحالة النهائية

Backend Van Sales integration = HARDENED / PRODUCTION
Central stock movement = ACTIVE / VERIFIED
Van Sales collection Core = DEPLOYED / TRANSACTION TESTED
Van Sales frontend = OPEN
showRecentCustomers = OPEN OWNER PATCH
collectPayment = OPEN OWNER PATCH
Sales source filters = OPEN OWNER PATCH
Customer patterns query = OPEN OWNER PATCH
EOD settlement = OPEN BUSINESS CONTRACT
Browser E2E = OPEN

هذه ليست 100% Closure للتطبيق؛ ولكنها ليست نظرية أيضًا. التعديلات الخلفية التي ذكرت أعلاه نُفذت مباشرة على Production.

## 9. قاعدة الاستكمال للجلسة التالية

لا تعُد إلى ما أُغلق.
ابدأ من:
VAN-01 → VAN-02 → VAN-03 → VAN-04
ثم Browser E2E
ثم EOD Business Contract.

أي عيب جديد:
اكتشف → أصلح فورًا → اختبر → تحقق → أغلق.
