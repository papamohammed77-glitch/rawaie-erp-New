# Report398 — تحقيق تكامل POS مع النظام الأم والقلب المركزي
**التاريخ:** 2026-10-10  
**النطاق:** `erp-frontend/companies/company-1/sales/pos.html` مع Production Supabase `fiilmooggumokxanwiyx`  
**حدود التغيير:** لم يتم تعديل `main.html` أو `pos.html` أو `core.js`. هذا متعمد وفق تعليمات المالك التي خصصت دمج ملفات الواجهة التشغيلية له. لا توجد تغييرات Production مطلوبة لتصحيح أخطاء الواجهة المثبتة أدناه؛ لا ينبغي إجراء تغييرات قاعدة بيانات أو نشر Edge جديد دون حاجة مثبتة.

## 1. PRE-CHANGE SELF-AUDIT

- **Business Understanding:** POS ينشئ فاتورة مباشرة `Invoiced`، وبالتالي البيع يستهلك مخزون الفرع فورًا ويُنشئ آثاره المحاسبية من خلال المسار المركزي؛ مرتجع POS يمر عبر `complete-return` مع `is_pos_return=true`.
- **Architecture Understanding:** الواجهة ← `RW_API.call` ← Edge موجودة ← RPC مركزي ← المخزون/القيود. لا حاجة إلى Edge Function جديدة.
- **Database Understanding:** `save_sales_invoice_atomic(jsonb,jsonb,text,text)` موجودة، `SECURITY DEFINER`، وACL الفعلي `postgres/service_role` فقط. حركة البيع الفعلية تمر عبر `post_stock_movement`.
- **Historical Understanding:** الملف الحالي في `erp-frontend` يطابق محتوى `rawaie-erp-review/PWA/sales/pos.html` ونسخة الملف التي جرى جلبها من commit تاريخي؛ Blob SHA في الحالتين `6ad4da791b72260b922847246ebce93b552d2bad`. لم أستنتج أن النسخة التاريخية صحيحة لمجرد أنها تاريخية.
- **Production Understanding:** `save-sales-invoice` v18 ACTIVE و`verify_jwt=true`، package SHA-256 `43d20f1465725c4e273f717ac927c070d4b28be48241bd2c9c46a6d43bb40308`. `complete-return` v26 ACTIVE و`verify_jwt=true`، package SHA-256 `801e390b195522caedfcf68bae8262bb91da06e909c1d43e9344490e3a81f34d`.
- **Current Understanding:** `pos.html` الحالي Blob `6ad4da791b72260b922847246ebce93b552d2bad`، 80,447 حرفًا / 1,115 سطرًا. `core.js` Blob `c2e0a7f4ba11f44c11dfc4728ef4a1af1b256b81`.
- **Execution Confidence:** مرتفع في عيوب المصدر وعقد RPC المثبتة؛ غير كافٍ لإعلان تكامل POS مغلق لأن ملف الواجهة لم يُدمج ولم يُنشر ولم ينجح اختبار متصفح مصادق عليه خاص بـPOS.

### لقطة Production التي أُعيد فحصها في هذه الدورة

| العنصر | الحقيقة الحالية المثبتة |
|---|---|
| `save-sales-invoice` | v18 ACTIVE، JWT verification مفعّل |
| `complete-return` | v26 ACTIVE، JWT verification مفعّل |
| `save_sales_invoice_atomic` | `SECURITY DEFINER`; التنفيذ ممنوح لـ`postgres/service_role`، وليس `anon/authenticated` |
| حركة البيع | RPC تستدعي `post_stock_movement` بنوع `POSSale` أو `VanSale` بحسب الفرع |
| سجلات HTTP | وُجدت طلبات ناجحة إلى `save-sales-invoice` v18 بتاريخ 2026-10-09؛ السجلات التي تمت مراجعتها مرتبطة بسياق الطلبات الحالي ولا تثبت وحدها أن شاشة POS نفسها اجتازت Browser E2E |
| بيانات Production | وقت الفحص: orders=3، order_details=11، runsheets=1، run_sheet_details=5، inventory_log=12، journal_entries=10. لم تُحذف أو تُعدّل هذه البيانات؛ سجل الحالة السابق يحذر من حذف ORD-1001 بلا إثبات جديد للسلامة |

## 2. ما يفعله POS الآن — وما هو مثبت

1. تسجيل الدخول واستعادة الجلسة عبر `RW_Auth`، ثم فحص `isOwner` أو صلاحية `pos`.
2. تحميل customers/items/stock_branches/branches إلى Dexie.
3. اختيار فرع وعرض الرصيد المتاح محليًا باستخدام `qty - allocated_qty`.
4. إنشاء البيع عبر `save-sales-invoice`؛ لا توجد كتابة مباشرة إلى `stock_branches` من دالة إتمام البيع.
5. المرتجع يرسل `complete-return` مع `order_code` و`items` و`is_pos_return=true`.

## 3. العيوب المثبتة — الأولوية

### DEFECT A — مزامنة قد تمسح Cache قبل معرفة فشل المصدر
**الملف:** `companies/company-1/sales/pos.html`  
**Blob:** `6ad4da791b72260b922847246ebce93b552d2bad`  
**الدالة:** `self.syncDown`  
**محدد البحث:** `self.syncDown = function() {`  
**السبب:** كل طلب Supabase يستخدم `r.data || []` ثم يمسح جدول Dexie ويعيد ملأه دون فحص `r.error`. إذا فشل طلب واحد، قد يُستبدل Cache صحيح ببيانات فارغة/جزئية، وتظل أخطاء التحميل غير واضحة.  
**الإجراء:** استبدال الدالة كاملة بالنص التالي؛ يجمع البيانات أولًا، يتحقق من جميع الأخطاء، ثم يحدّث الجداول الأربع داخل معاملة Dexie واحدة، ولا يحدّث الذاكرة إلا بعد نجاح المعاملة.

```javascript
self.syncDown = function() {
    if (!db) return Promise.reject(new Error('قاعدة البيانات المحلية غير مهيأة'));

    return Promise.all([
        supabase.from('customers').select('*'),
        supabase.from('items').select('*'),
        supabase.from('stock_branches').select('*'),
        supabase.from('branches').select('*')
    ]).then(function(results) {
        var names = ['customers', 'items', 'stock_branches', 'branches'];
        for (var i = 0; i < results.length; i++) {
            if (results[i].error) {
                throw new Error('فشل تحميل ' + names[i] + ': ' + results[i].error.message);
            }
            if (!Array.isArray(results[i].data)) {
                throw new Error('استجابة غير صالحة من ' + names[i]);
            }
        }

        var customers = results[0].data;
        var items = results[1].data;
        var stock = results[2].data;
        var branches = results[3].data;

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
            return { success: true, offline: false };
        });
    });
};
```

### DEFECT B — فتح التطبيق لا يعالج فشل المزامنة
**الدالة:** `self.enterApp`  
**محدد البحث:** `self.enterApp = function() {`  
**السبب:** يستدعي `syncDown().then(...)` بلا `catch`; فشل الشبكة قد يترك الشاشة في حالة نصف مهيأة ولا يقدم قرارًا واضحًا.  
**الإجراء:** استبدال الدالة كاملة. التعديل يسمح باستعمال Cache الموجود عند عدم الاتصال/فشل التحديث، لكنه يعرض تحذيرًا صريحًا ولا يدّعي نجاح المزامنة. كما يمنع تكرار ربط أحداث `online/offline/keydown` بعد تسجيل خروج ودخول.

```javascript
self.enterApp = function() {
    function openFromLocalCache(stale) {
        RW_UI.hideLoader();
        RW_UI.byId('loginScreen').classList.add('hidden');
        RW_UI.byId('mainApp').classList.remove('hidden');

        if (!self._posEventsBound) {
            window.addEventListener('online', function() {
                self.updateConnectionStatus();
                self.syncDown().then(function() {
                    self.loadBranches();
                    self.loadCustomers();
                    self.loadCategories();
                    self.renderProducts();
                    self.syncPendingOrders();
                }).catch(function(err) {
                    console.error('POS online refresh failed:', err);
                    RW_UI.toast('تعذر تحديث البيانات؛ ما زالت البيانات المحلية محفوظة', 'warning');
                });
            });
            window.addEventListener('offline', function() {
                self.updateConnectionStatus();
            });
            document.addEventListener('keydown', self.handleHotkeys);
            self._posEventsBound = true;
        }

        self.updateConnectionStatus();
        self.loadBranches();
        self.loadCustomers();
        self.loadFastSelling();
        self.loadCategories();
        self.switchView('pos');

        if (stale) {
            RW_UI.toast('تعمل نقطة البيع بالبيانات المحلية؛ لم يتم تأكيد آخر مزامنة', 'warning');
        }
    }

    if (!navigator.onLine) {
        openFromLocalCache(true);
        return;
    }

    RW_UI.showLoader('جاري مزامنة بيانات نقطة البيع...');
    self.syncDown().then(function() {
        openFromLocalCache(false);
    }).catch(function(err) {
        console.error('POS initial sync failed:', err);
        openFromLocalCache(true);
    });
};
```

### DEFECT C — عمليات بيع متطابقة قد تشترك في هوية Idempotency مولّدة من الحمولة
**المصدر المرتبط:** Production `save-sales-invoice` v18.  
**السبب:** عند غياب `operation_id` من POS، الـEdge يولّد UUID حتميًا من هوية المستخدم والحمولة والفرع. هذا يمنع تكرار الطلب نفسه، لكنه قد يصطدم بفاتورتين مشروعَتين متطابقتين لنفس المستخدم والفرع إذا كان محتوى الحمولة مطابقًا.  
**الإجراء:** في POS إنشاء `operation_id` مستقل لكل محاولة بيع منطقية، والاحتفاظ به عند retry لنفس الحمولة، وتغييره فقط إذا تغيرت الحمولة أو نجحت الفاتورة. لا يتطلب ذلك Edge Function جديدة أو تغيير RPC.

**الملف:** `companies/company-1/sales/pos.html)  
**الدالة:** `self.finalizeCheckout`  
**محدد البحث:** `self.finalizeCheckout = function() {`  
**استبدل الدالة كاملة:**

```javascript
self.finalizeCheckout = function() {
    var t = self.calcTotals();
    if (!t.count || !cart.length) {
        RW_UI.toast('السلة فارغة', 'warning');
        return;
    }
    if (self._checkoutInFlight) return;
    if (!selBranch || !branchMap[selBranch]) {
        RW_UI.toast('اختر الفرع الذي سيتم الخصم منه قبل إتمام البيع', 'warning');
        return;
    }

    // Production RPC الحالي لا يملك عقدًا مثبتًا لتسوية بطاقة/محفظة/دفع مختلط.
    // لا نسجل هذه الطرق نقدًا ولا نعرضها كأنها سُوّيت محاسبيًا.
    if (activePaymentMethod !== 'cash') {
        RW_UI.showError('طريقة الدفع المختارة غير مربوطة بعد بعقد التسوية المحاسبي في النظام. اختر النقدي أو ألغِ العملية حتى اكتمال ربط البطاقة/المحفظة.');
        return;
    }

    var tendered = Number(RW_UI.byId('txtTendered').value);
    if (!isFinite(tendered) || tendered < t.total) {
        RW_UI.toast('المبلغ المستلم أقل من إجمالي الفاتورة أو غير صالح', 'warning');
        return;
    }

    var items = [];
    for (var i = 0; i < cart.length; i++) {
        var line = cart[i];
        if (!line.code || !isFinite(Number(line.qty)) || Number(line.qty) <= 0 ||
            !isFinite(Number(line.price)) || Number(line.price) < 0) {
            RW_UI.showError('يوجد صنف أو كمية أو سعر غير صالح في السلة');
            return;
        }
        items.push({
            code: line.code,
            name: line.name,
            price: Number(line.price),
            qty: Number(line.qty),
            unit: line.unit
        });
    }

    var custCode = selCust ? selCust.customer_code : '';
    var custName = selCust ? selCust.name : 'عميل نقدي';
    var hdr = {
        customer_code: custCode,
        custName: custName,
        area: selCust ? (selCust.area || '') : '',
        total: t.total,
        deliveryFees: 0,
        status: 'Invoiced',
        source: 'pos',
        paymentType: 'نقدي',
        taxAmount: 0,
        taxRate: 0
    };

    var fingerprint = JSON.stringify({
        orderHeader: hdr,
        itemsList: items,
        branchCode: selBranch
    });

    if (!self._activeCheckoutFingerprint || self._activeCheckoutFingerprint !== fingerprint) {
        var c = window.crypto;
        if (!c) {
            RW_UI.showError('المتصفح لا يوفر مولّد هوية آمنة للعملية؛ لم يتم إرسال الفاتورة');
            return;
        }

        if (typeof c.randomUUID === 'function') {
            self._activeCheckoutOperationId = c.randomUUID();
        } else if (typeof c.getRandomValues === 'function') {
            var bytes = new Uint8Array(16);
            c.getRandomValues(bytes);
            bytes[6] = (bytes[6] & 15) | 64;
            bytes[8] = (bytes[8] & 63) | 128;
            var hex = [];
            for (var b = 0; b < bytes.length; b++) {
                hex.push(bytes[b].toString(16).padStart(2, '0'));
            }
            self._activeCheckoutOperationId =
                hex.slice(0, 4).join('') + '-' +
                hex.slice(4, 6).join('') + '-' +
                hex.slice(6, 8).join('') + '-' +
                hex.slice(8, 10).join('') + '-' +
                hex.slice(10, 16).join('');
        } else {
            RW_UI.showError('المتصفح لا يوفر مولّد هوية للعملية؛ لم يتم إرسال الفاتورة');
            return;
        }
        self._activeCheckoutFingerprint = fingerprint;
    }

    self._checkoutInFlight = true;
    RW_UI.showLoader('جاري حفظ الفاتورة وترحيل آثارها...');
    RW_API.call('save-sales-invoice', {
        operation_id: self._activeCheckoutOperationId,
        orderHeader: hdr,
        itemsList: items,
        branchCode: selBranch
    }, function(json, err) {
        self._checkoutInFlight = false;
        RW_UI.hideLoader();

        if (!err && json && json.success) {
            var orderCode = json.orderID || json.order_code || '';
            var change = Math.max(0, tendered - t.total);

            self.closePaymentModal();
            RW_UI.toast('تم الحفظ: ' + orderCode, 'success');
            self.printReceipt(orderCode, t.total, custName, 'cash', tendered, change);

            cart = [];
            selCust = null;
            self._activeCheckoutOperationId = null;
            self._activeCheckoutFingerprint = null;

            RW_UI.safeText(RW_UI.byId('cartCustName'), 'عميل نقدي (عام)');
            RW_UI.safeHTML(RW_UI.byId('cartCustDetails'), '');
            self.updateCartUI();
            self.renderProducts();
            return;
        }

        RW_UI.byId('paymentModal').classList.remove('hidden');
        RW_UI.showError((json && (json.msg || json.error)) ||
            (err && String(err)) || 'فشل حفظ الفاتورة؛ لم يتم تفريغ السلة');
        // لا نمسح operation_id عند الفشل؛ retry بنفس الحمولة يستخدم المفتاح نفسه.
    });
};
```

**ملاحظة محاسبية حاسمة:** هذا البديل يتعمد منع بطاقة/محفظة/مختلط بدل ترحيلها خطأً. السبب المثبت في Production RPC: `v_is_cash := coalesce(paymentType,'أجل') = 'نقدي'`; المسار المحاسبي الموجود يعالج النقدي عبر `post_cash_receipt_atomic`. لم أجد في العقد الحالي تسوية مستقلة مثبتة للبطاقة أو المحفظة أو split. لا يجوز تمكين هذه الخيارات قبل إضافة حسابات/خزائن تسوية وعقد ذري لها واختباره.

### DEFECT D — اختيار طريقة ردّ المرتجع لا يصل إلى Production
**الملف:** `companies/company-1/sales/pos.html`، الدالة `self._finalizeReturn`.  
**محدد البحث:** `self._finalizeReturn = function(method) {`  
**الدليل:** الواجهة تعرض `method` كـ«نقدي/بطاقة» في رسالة النجاح، لكنها لا ترسله في الطلب. Production `complete-return` v26 يقرأ فقط `runsheet_code`, `order_code`, `items`, `is_pos_return`، ثم يستدعي `complete_sales_return_credit_note_atomic`؛ لا يوجد حقل refund/payment method في عقد Edge الحالي. لذلك الرسالة الحالية توحي بردّ نقدي/بطاقة لم يثبت أنه حدث.

**التصحيح الآمن الآن:** لا تعرض «طريقة الإعادة: نقداً/بطاقة» على أنها تمت. غيّر نص النجاح داخل `self._finalizeReturn` ليقول: «تم تسجيل المرتجع وفق عقد الإشعار الدائن؛ لم يُثبت تنفيذ رد نقدي/بطاقة من هذه الشاشة». لا تنفّذ أو تسجّل ردًا نقديًا يدويًا من الواجهة. الربط الكامل لردّ الأموال يحتاج عقدًا محاسبيًا منفصلًا ومثبت الحسابات؛ لا يجوز اختراعه داخل POS وحده.

### Patch D — استبدال كامل لدالة `self._finalizeReturn`

**محدد البحث:** `self._finalizeReturn = function(method) {`  
احذف جسم الدالة كاملًا حتى `};` واستبدله بالآتي. لا يعلن هذا البديل أن ردًا نقديًا/بطاقة قد تم، ويحافظ على السلة إذا فشل الخادم:

```javascript
self._finalizeReturn = function() {
    var orderCode = returnOriginalInvoice ? returnOriginalInvoice.order_code : null;
    var items = [];

    if (!orderCode) {
        RW_UI.showError('لم يتم تحديد الفاتورة الأصلية؛ لم يُرسل المرتجع');
        return;
    }

    for (var i = 0; i < returnCart.length; i++) {
        var it = returnCart[i];
        if (Number(it.returnQty) > 0) {
            items.push({
                item_code: it.code,
                item_name: it.name,
                unit_price: Number(it.price) || 0,
                returnedQty: Number(it.returnQty),
                return_condition: 'good',
                reason: 'مرتجع نقطة بيع - إشعار دائن'
            });
        }
    }

    if (!items.length) {
        RW_UI.toast('لا توجد أصناف في سلة المرتجع', 'warning');
        return;
    }

    RW_UI.showLoader('جاري تسجيل المرتجع...');
    RW_API.call('complete-return', {
        runsheet_code: null,
        order_code: orderCode,
        items: items,
        is_pos_return: true,
        reason: 'مرتجع نقطة بيع - إشعار دائن'
    }, function(json, err) {
        RW_UI.hideLoader();

        if (!err && json && json.success) {
            var newStatus = json.new_order_status || 'Returned';
            var isPartial = newStatus === 'Partially Returned';

            returnCart = [];
            returnOriginalInvoice = null;
            _returnTotal = 0;

            Swal.fire({
                icon: isPartial ? 'warning' : 'success',
                title: isPartial ? 'تم تسجيل المرتجع جزئيًا' : 'تم تسجيل المرتجع',
                html: '<div class="text-right text-white text-sm">' +
                    '<p>عدد الأصناف المرتجعة: <strong>' + items.length + '</strong></p>' +
                    '<p>القيمة المرجعية: <strong>' + fmtNum(items.reduce(function(sum, item) { return sum + item.unit_price * item.returnedQty; }, 0)) + ' ' + currency + '</strong></p>' +
                    '<p>حالة الفاتورة: <strong>' + newStatus + '</strong></p>' +
                    '<p class="text-amber-300 mt-3">تم تسجيل المرتجع وفق عقد الإشعار الدائن. لم يتم تنفيذ رد نقدي أو رد للبطاقة من هذه الشاشة.</p>' +
                    '</div>',
                confirmButtonText: 'حسنًا',
                customClass: {
                    popup: '!bg-slate-900 !rounded-3xl !border !border-slate-700',
                    confirmButton: isPartial ? '!bg-amber-600 !rounded-xl' : '!bg-emerald-600 !rounded-xl'
                }
            });

            self.switchView('invoices');
            return;
        }

        RW_UI.byId('returnPaymentModal').classList.remove('hidden');
        RW_UI.showError((json && (json.msg || json.error)) ||
            (err && String(err)) || 'فشل تسجيل المرتجع؛ لم يتم تفريغ السلة');
    });
};
```

**تعديل واجهة نافذة المرتجع المرتبط بالدالة:**

ابحث عن هذا العنصر حرفيًا:
```html
<div class="grid grid-cols-2 gap-2">
                <button onclick="POS._finalizeReturn('cash')" class="py-3 rounded-xl border-2 border-red-500 bg-red-950/40 text-red-300 font-bold text-sm">💵 دفع نقدي للعميل</button>
                <button onclick="POS._finalizeReturn('card')" class="py-3 rounded-xl border border-slate-600 bg-slate-800 text-slate-400 font-bold text-sm">💳 إعادة للبطاقة</button>
            </div>
```
واستبدله كاملًا بـ:
```html
<div class="bg-amber-950/30 border border-amber-700/50 p-3 rounded-xl text-center">
    <p class="text-sm font-bold text-amber-300">هذه الشاشة تسجل المرتجع والإشعار الدائن فقط.</p>
    <p class="text-xs text-slate-300 mt-1">لا يتم رد نقدي أو رد للبطاقة حتى ربط عملية التسوية المحاسبية واعتمادها في النظام.</p>
</div>
```

ثم ابحث عن زر التأكيد حرفيًا:
```html
<button onclick="POS._finalizeReturn('cash')" class="w-2/3 bg-red-600 hover:bg-red-500 text-white py-3 rounded-xl font-black text-base shadow-lg">تأكيد المرتجع ✅</button>
```
واستبدله بـ:
```html
<button onclick="POS._finalizeReturn()" class="w-2/3 bg-red-600 hover:bg-red-500 text-white py-3 rounded-xl font-black text-base shadow-lg">تسجيل المرتجع وإنشاء الإشعار الدائن</button>
```

هذا إصلاح لصدق واجهة المستخدم وتوافقها مع العقد الحالي؛ لا يدّعي أنه أضاف رد أموال. إضافة رد نقدي/بطاقة فعلية تتطلب عقدًا محاسبيًا جديدًا مثبت الحسابات والخزائن ومفتاح idempotency، واختبارات ذرية مستقلة.

## 4. ما لم أعدّله ولماذا

- لم أعدل `main.html` أو `pos.html` أو `core.js`؛ هذه ملفات دمج المالك، كما نصّت التعليمات.
- لم أغير Production Edge أو SQL: مسار إنشاء فاتورة POS موجود ومركزي، والخلل المثبت في هذه الدورة هو contract mismatch في المستهلك (الدفع، operation identity، cache handling). إضافة تسوية card/split أو refund تحتاج عقدًا محاسبيًا وتهيئة حسابات/خزائن لم يثبتا في Production.
- لم أحذف ORD-1001/1002/1003 أو بيانات تشغيلية أخرى؛ أحدث حالة سابقة تحذر من حذف ORD-1001، ولم أثبت في هذه الدورة أن جميع الصفوف الحالية fixtures آمنة للحذف.
- لا توجد أدلة كافية على أن POS نفسه اجتاز HTTP/Browser E2E. سجلات `save-sales-invoice` الناجحة لا تثبت أن المستهلك POS هو الذي أرسلها.

## 5. Loss / Gain / Responsibility Matrix

| المسؤولية | الحالة المثبتة | التصنيف |
|---|---|---|
| تسجيل البيع وخصم المخزون | POS → `save-sales-invoice` → `save_sales_invoice_atomic` → `post_stock_movement` | RETAINED / CENTRALIZED |
| منع تكرار الطلب نفسه | Core لديه idempotency؛ POS لا يرسل operation_id مستقلًا لكل بيع منطقي | MISSING IN CONSUMER |
| حفظ Cache عند فشل الشبكة | `syncDown` يمسح قبل فحص الأخطاء | DEFECT |
| الدفع النقدي | Core يرحّل النقدي عبر receipt/treasury/journal | VERIFIED CONTRACT |
| بطاقة/محفظة/مختلط | واجهة موجودة؛ عقد التسوية الحالي لا يثبتها | UI EXISTS / BUSINESS CONTRACT MISSING |
| مرتجع POS | Edge يمرر إلى `complete_sales_return_credit_note_atomic` | CENTRALIZED |
| رد نقدي/بطاقة للمرتجع | الواجهة توحي به لكن Edge لا يستقبله | UI/CONTRACT CONFLICT |
| النظام الأم | لم يُعدل | PRESERVED |
| Edge Functions count | لم تُنشأ أي Function جديدة | PRESERVED |

## 6. خطة الاختبار بعد دمج المالك

1. **Static:** فحص JavaScript syntax، وعدم وجود دوال مكررة، وأن `self.syncDown`, `self.enterApp`, `self.finalizeCheckout` كل منها معرف مرة واحدة.
2. **Cache atomicity:** اجعل أحد طلبات Supabase يفشل؛ تحقق أن الجداول الأربع و`customersCache/productsCache` تبقى كما كانت.
3. **Cash normal:** فرع محدد، صنف متاح، مبلغ مستلم ≥ الإجمالي؛ يجب أن تعود الفاتورة `Invoiced`، المصدر `pos`، حركة `POSSale` واحدة لكل صنف، وأثر محاسبي واحد متوازن.
4. **Idempotent retry:** أعد نفس `operation_id` لنفس الطلب؛ يجب أن يرجع duplicate/same order دون حركة ثانية.
5. **Distinct identical sales:** أنشئ فاتورتين منفصلتين متطابقتين في الأصناف والفرع/المستخدم؛ يجب أن يكون لكل منهما `operation_id` مختلف وأن تنتج كل منهما فاتورة وحركة صحيحة.
6. **Invalid payment:** البطاقة/المحفظة/split يجب أن تفشل بوضوح قبل أي طلب للخادم، حتى يتم بناء عقد التسوية.
7. **Insufficient cash:** يجب ألا تُرسل الفاتورة إذا كان المبلغ المستلم أقل من الإجمالي.
8. **Returns:** تأكد من عدم ظهور ادعاء رد نقدي/بطاقة ما لم توجد عملية تسوية مثبتة، ومن أن المرتجع الجزئي/الكامل يحدّث المخزون والحالة مرة واحدة.
9. **Company/branch isolation:** لا يستطيع مستخدم POS تنفيذ البيع على فرع من شركة أخرى؛ Edge/RPC هما الحاجز النهائي حتى لو تلاعب العميل بالطلب.
10. **Baseline:** بعد اختبار Production عبر جلسة مصادقة مخصصة، أزل fixture الاختبار فقط بعد إثبات عدم وجود runsheet/ledger/journal/movement dependencies، ثم أعد العدّ للتحقق من الصفر.

## 7. SELF-AUDIT FINAL

**What I Proved**
- نسخة POS الحالية وهوية Blob.
- Production versions وJWT status وpackage hashes لـ`save-sales-invoice` و`complete-return`.
- ACL الفعلي لـ`save_sales_invoice_atomic`.
- مسار خصم المخزون المركزي.
- mismatch بين خيارات الدفع في POS وعقد المحاسبة الحالي.
- mismatch بين رسالة طريقة رد المرتجع وما يستقبله Edge.
- عدم وجود دليل كافٍ على POS-specific browser E2E في السجلات التي فُحصت.

**What I Did Not Prove**
- لم أثبت تشغيل Browser E2E بعد دمج الجراحة.
- لم أثبت أن البطاقة/المحفظة/split أو رد الأموال النقدي مدعوم محاسبيًا.
- لم أثبت أن كل سجلات Production الحالية بيانات تجريبية قابلة للحذف.
- لم أثبت تطابق ملف Cloudflare/PWA المنشور مع Git Blob.

**What I Fixed**
- أنشأت Owner Merge Package كاملًا يتضمن بدائل جراحية محددة؛ لم أغير ملفات الواجهة المحمية.

**What I Initially Missed**
- الواجهة كانت تعرض طرق دفع/رد لا يطبقها عقد Production، إضافة إلى خطورة توليد idempotency من الحمولة بدل هوية بيع منفصلة.

**What Could Still Be Wrong**
- قد توجد متطلبات تشغيلية/محاسبية لطرق الدفع الأخرى في إعدادات أو تقارير غير مغطاة بعقد RPC الحالي؛ يجب إثباتها قبل تصميم الترحيل.
- قد يكون التطبيق المنشور مختلفًا عن Blob Git الحالي بسبب Cloudflare/PWA cache.

**Final Confidence:** 0.86 في التشخيص المصدري وعقد Production الذي تمت قراءته؛ غير كافٍ لإغلاق التكامل.

**Final Closure Status:** `NOT CLOSED — OWNER FRONTEND MERGE + AUTHENTICATED POS E2E REQUIRED`.

**Next exact task:** يدمج المالك Patch A/B/C في `companies/company-1/sales/pos.html`، ويصحح نص المرتجع وفق Patch D، ثم ينشر التطبيق ويشغّل الاختبارات في القسم 6. بعد ذلك يُعاد فحص Production/Git/served artifact في نفس الدورة قبل إعلان الإغلاق.
