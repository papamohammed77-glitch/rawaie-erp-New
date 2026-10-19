# Report442 — التعديل الجراحي لكمية العرض في المتجر الإلكتروني
**التاريخ:** 2026-10-19  
**النطاق:** `erp-frontend/companies/company-1/main.html` + `erp-frontend/companies/company-1/store/index.html` + عقود Supabase المرتبطة فقط.  
**قاعدة التنفيذ:** لم يتم تعديل أي من ملفي الواجهة؛ التعديلات التالية جاهزة ليطبقها المالك. لم تُجرَ تغييرات في Production لأن البنية اللازمة موجودة بالفعل.

## 1. PRE-CHANGE SELF-AUDIT

- **Business Understanding:** 97/100 — الحقل يحدد حصة العرض في المتجر، وليس كمية المخزون الفعلية أو حد الطلب الواحد.
- **Architecture Understanding:** 97/100 — النظام الأم يحفظ إعداد الصنف عبر `save-item`، والكتالوج العام يعرض المتجر، وRPC الطلب يفرض الحصة من جهة الخادم.
- **Database Understanding:** 100/100 للأجزاء ذات الصلة — تم فحص العمود، دالة حفظ الصنف، RPC الكتالوج، وعقد إنشاء الطلب في Production.
- **Historical Understanding:** 94/100 — تمت مراجعة Report440 بوصفه سجلًا تاريخيًا ومقارنته بالمصدر الحي؛ لم تُعامل ملاحظاته القديمة كحالة حالية.
- **Production Understanding:** 98/100 — تم الاستعلام مباشرة من Production في 2026-10-19؛ لم يُنفذ HTTP/browser E2E.
- **Current Understanding:** 100/100 للأجزاء المستهدفة — تمت قراءة الملفين الحاليين كاملين عبر مصدر GitHub الحالي وتحديد مواضع العناصر الدقيقة.
- **Execution Confidence قبل تعديل الواجهة:** 96/100 — Backend support مثبت، لكن تطبيق المالك ونشر الواجهة واختبار المتصفح لم تحدث بعد.

### Confirmed Facts

1. ملف النظام الأم الحالي: `companies/company-1/main.html`, blob SHA `3f9c6727154b72a742b881ecb3050fc2c9d76305`, 32,747 سطرًا.
2. ملف المتجر المستقل الحالي: `companies/company-1/store/index.html`, blob SHA `d8b3f963e81f64b20e6b70494995fc0ddd2ae3f2`, 523 سطرًا.
3. Production يحتوي `public.items.store_display_qty numeric`.
4. Production `save-item` v15 يقرأ `item.store_display_qty`، يحول القيمة الفارغة إلى `NULL`، ويرفض القيم السالبة أو غير الرقمية، ويكتب الحقل عند تعديل الصنف.
5. Production `create_item_with_opening_stock(uuid,jsonb,uuid,numeric,text)` يحفظ `store_display_qty` عند إنشاء الصنف من `p_item`.
6. Production `get_public_store_catalog(text)` يعيد `store_display_qty` و`store_sold_qty` و`store_remaining_qty`. المتبقي محسوب كـ `greatest(store_display_qty - store_sold_qty, 0)`، وتكون قيمته `NULL` عندما لا توجد حصة محددة.
7. Production `submit_online_order_atomic(..., p_operation_id uuid)` يقفل صفوف الأصناف المطلوبة، ويحسب طلبات `online_store` غير الملغاة، ويرفض الطلب الذي يتجاوز حصة العرض. تنفيذ هذا الـRPC محصور في `service_role`؛ لم تُمنح صلاحيات مباشرة للزوار.
8. استعلام Production الحالي للشركة `00000000-0000-0000-0000-000000000001`: عدد الأصناف 17، الأصناف التي لها حصة عرض محددة 0، الأصناف النشطة الظاهرة في المتجر 16. لا توجد حاجة لتغيير البيانات أو المخطط لتحقيق الميزة.
9. لم تُنشأ بيانات اختبار دائمة، ولم تُعدّل جداول أو صلاحيات Production.

### Root Cause

المشكلة المتبقية في الواجهة وليست نقصًا في قاعدة البيانات:
- نموذج الصنف في `main.html` لا يحتوي عنصر إدخال لـ`store_display_qty`.
- كائن `payload` الذي يرسله النظام الأم إلى Edge Function `save-item` لا يتضمن `store_display_qty`.
- بطاقة المنتج في المتجر المستقل تعرض حاليًا `تبقت X فقط` استنادًا إلى `item.qty` (المخزون الفعلي)، حتى عندما لا تكون هناك حصة تسويقية محددة. هذا يخالف المطلوب.
- إضافة الطلب في الواجهة لا تحدّ من السلة وفق حصة العرض؛ الحماية النهائية موجودة في RPC الخادم، ويجب أن تبقى هي المرجع الحاسم.

## 2. التعديلات الجراحية — يطبقها المالك فقط

> قبل كل تعديل، تحقق أن SHA الحالي ما زال مطابقًا. إذا تغيّر، أعد تحديد السطور من النص الحالي ولا تستخدم أرقام هذا التقرير القديمة.

### Patch A — حقل كمية العرض داخل مودال الصنف

**الملف:** `erp-frontend/companies/company-1/main.html`  
**الموضع الحالي:** `RW_Items`، تبويب `item-panel-marketing`، السطر 5542.  
**محدد البحث الفريد:**
```js
html += '<div class="flex flex-col"><label class="text-sm font-bold">نص الشارة</label><input id="item-badge-text" value="'
```

**استبدل السطر كاملًا بالسطرين التاليين:**
```js
        html += '<div class="flex flex-col"><label class="text-sm font-bold">كمية العرض في المتجر (اختياري)</label><input id="item-store-display-qty" type="number" min="0" step="any" value="' + _esc(item && item.store_display_qty != null ? item.store_display_qty : '') + '" class="p-2.5 bg-gray-50 border rounded-lg" placeholder="اتركه فارغًا لعرض غير محدود"><p class="text-xs text-gray-500 mt-1">عند تحديد كمية، يعرض المتجر المتبقي منها بعد الطلبات. اترك الحقل فارغًا لإلغاء حد العرض.</p></div>';
        html += '<div class="flex flex-col"><label class="text-sm font-bold">نص الشارة</label><input id="item-badge-text" value="' + _esc(item ? (item.badge_text || '') : '') + '" class="p-2.5 bg-gray-50 border rounded-lg" placeholder="جديد، الأكثر مبيعاً، عرض محدود"></div>';
```

**النتيجة:** القيمة الفارغة تعني `NULL` / لا توجد حصة عرض محددة. الصفر قيمة صريحة تعني أن حصة العرض صفر، وليس قيمة فارغة.

### Patch B — تمرير الحقل عند الحفظ

**الملف:** `erp-frontend/companies/company-1/main.html`  
**الموضع الحالي:** بناء `payload` في `RW_Items`، السطر 5649.  
**محدد البحث الفريد:**
```js
max_qty_per_order: parseFloat(byId('item-maxqty-per-order') ? byId('item-maxqty-per-order').value : 0) || 0,
```

**استبدل هذا السطر بالسطرين التاليين:**
```js
                store_display_qty: byId('item-store-display-qty') && String(byId('item-store-display-qty').value).trim() !== '' ? Number(byId('item-store-display-qty').value) : null,
                max_qty_per_order: parseFloat(byId('item-maxqty-per-order') ? byId('item-maxqty-per-order').value : 0) || 0,
```

لا تغيّر مسار `save-item` أو RPC إنشاء الصنف؛ فهما يدعمان الحقل بالفعل. يتحقق Production Edge من كون القيمة رقمًا غير سالب أو `NULL`.

### Patch C — عدم الخلط بين المخزون الفعلي وحصة العرض

**الملف:** `erp-frontend/companies/company-1/store/index.html`  
**SHA الحالي:** `d8b3f963e81f64b20e6b70494995fc0ddd2ae3f2`.  
**الموضع:** `Store.buildProductCard(item)`، السطر 253.  
**ابحث عن:**
```js
    var stockAvail = Number(item.qty) || 0;
```

**استبدله بـ:**
```js
    var displayQty = item.store_display_qty === null || item.store_display_qty === undefined || String(item.store_display_qty).trim() === '' ? null : Number(item.store_display_qty);
    var displayRemaining = item.store_remaining_qty === null || item.store_remaining_qty === undefined || String(item.store_remaining_qty).trim() === '' ? null : Number(item.store_remaining_qty);
```

**ثم في السطر 272 ابحث عن السطر المعيب:**
```js
    if (stockAvail <= 10 && stockAvail > 0) html += '<span class="absolute bottom-2 right-2 bg-red-500 text-white text-[10px] font-black px-2 py-1 rounded-full shadow">تبقت ' + stockAvail + ' فقط!</span>';
```

**واستبدله كاملًا بـ:**
```js
    if (displayQty !== null && isFinite(displayQty) && displayRemaining !== null && isFinite(displayRemaining)) {
        if (displayRemaining > 0) html += '<span class="absolute bottom-2 right-2 bg-red-500 text-white text-[10px] font-black px-2 py-1 rounded-full shadow">تبقت ' + displayRemaining + ' فقط!</span>';
        else html += '<span class="absolute bottom-2 right-2 bg-gray-700 text-white text-[10px] font-black px-2 py-1 rounded-full shadow">انتهت كمية العرض</span>';
    }
```

**النتيجة:** لا تظهر عبارة `تبقت فقط` اعتمادًا على المخزون الفعلي. تظهر فقط عند تحديد حصة عرض، ويكون الرقم من `store_remaining_qty` الذي يحسبه Production. عند الحقل الفارغ لا تظهر العبارة إطلاقًا.

### Patch D — منع زيادة السلة فوق المتبقي المعروض

**الملف:** `erp-frontend/companies/company-1/store/index.html`  
**الموضع:** السطر 312، الدالة ذات السطر الواحد `self.addToCart`.  
**استبدل الدالة كاملة بهذا النص:**
```js
    self.addToCart = function(code) {
        var product = null;
        for (var i = 0; i < products.length; i++) {
            if (products[i].item_code === code) { product = products[i]; break; }
        }
        if (!product) return;
        var existing = null;
        for (var j = 0; j < cart.length; j++) {
            if (cart[j].code === code) { existing = cart[j]; break; }
        }
        var currentQty = existing ? (Number(existing.qty) || 0) : 0;
        var displayLimited = product.store_display_qty !== null && product.store_display_qty !== undefined && String(product.store_display_qty).trim() !== '';
        var displayRemaining = Number(product.store_remaining_qty);
        if (displayLimited && (!isFinite(displayRemaining) || currentQty >= displayRemaining)) {
            Swal.fire({ icon: 'info', title: 'وصلت للكمية المتاحة', text: 'تم الوصول إلى كامل كمية العرض المتبقية لهذا الصنف.' });
            return;
        }
        if (existing) existing.qty++;
        else cart.push({ code: product.item_code, name: product.name, price: Number(product.sales_price)||0, oldPrice: Number(product.old_price)||0, discountPercent: Number(product.discount_percent)||0, image: product.image_url||'', unit: product.unit||'حبة', qty: 1 });
        self.refreshProductCards();
        if (RW_UI.byId('cartPanel').classList.contains('open')) self.renderCartItems();
    };
```

**ثم استبدل الدالة كاملة في السطر 313 `self.updateCart` بهذا النص:**
```js
    self.updateCart = function(code, delta) {
        var product = null;
        for (var p = 0; p < products.length; p++) {
            if (products[p].item_code === code) { product = products[p]; break; }
        }
        if (!product) return;
        var currentQty = 0, cartIndex = -1;
        for (var i = 0; i < cart.length; i++) {
            if (cart[i].code === code) { currentQty = Number(cart[i].qty) || 0; cartIndex = i; break; }
        }
        var nextQty = currentQty + Number(delta || 0);
        var displayLimited = product.store_display_qty !== null && product.store_display_qty !== undefined && String(product.store_display_qty).trim() !== '';
        var displayRemaining = Number(product.store_remaining_qty);
        if (Number(delta) > 0 && displayLimited && (!isFinite(displayRemaining) || nextQty > displayRemaining)) {
            Swal.fire({ icon: 'info', title: 'وصلت للكمية المتاحة', text: 'لا يمكن تجاوز كمية العرض المتبقية لهذا الصنف.' });
            return;
        }
        if (cartIndex >= 0) {
            if (nextQty <= 0) cart.splice(cartIndex, 1);
            else cart[cartIndex].qty = nextQty;
        }
        self.refreshProductCards();
        if (RW_UI.byId('cartPanel').classList.contains('open')) self.renderCartItems();
    };
```

**مهم:** هذا حد واجهة لتحسين التجربة، وليس بديلًا عن تحقق الخادم. قد تتغير الحصة بسبب طلب عميل آخر بعد تحميل الصفحة؛ سيظل RPC Production هو الحكم النهائي ويرفض التجاوز.

### Patch E — تحديث المتبقي فور نجاح الطلب

**الملف:** `erp-frontend/companies/company-1/store/index.html`  
**الموضع:** داخل `self.submitOrder`، معالج نجاح الطلب، السطر الحالي الذي يحتوي `self.loadPage();` بعد `cart = [];`.  
**استبدل هذا السطر وحده بـ:**
```js
                self.loadSettings().then(function() {
                    return self.syncProducts();
                }).catch(function(err) {
                    console.error('تعذر تحديث كتالوج المتجر بعد الطلب:', err);
                    self.loadPage();
                });
```

هذا يعيد تحميل الكتالوج من RPC بعد نجاح الطلب، فينعكس الطلب الجديد على `store_sold_qty` و`store_remaining_qty` في الجلسة الحالية أيضًا. اترك `currentPage = 0;` و`self.updateCartBadge();` و`self.closeCart();` كما هي.

## 3. ما لم يتغير

- لا تعديل على `main.html` أو `store/index.html` من قبل المساعد.
- لا تغيير على `items` schema أو `get_public_store_catalog` أو `submit_online_order_atomic` أو `save-item` أو ACL.
- لا تعديل على خصم المخزون الفعلي، ولا على حجز المخزون عند إنشاء طلب المتجر؛ طلبات المتجر تبقى `Pending` ولا تُحوّل حصة العرض إلى حركة مخزون.
- لا إنشاء Edge Function جديد.
- لا بيانات تجريبية دائمة أو تنظيف سجلات أعمال قائمة.

## 4. الاختبار المطلوب بعد التطبيق

1. **حقل فارغ:** افتح صنفًا بلا قيمة `store_display_qty` واحفظه فارغًا. تحقق أن القيمة في DB هي `NULL` وأن بطاقة المتجر لا تعرض `تبقت فقط`، ولا يُطبق حد حصة العرض.
2. **حصة محددة:** عيّن قيمة 5 واحفظ، ثم أعد تحميل الكتالوج. تحقق أن `store_display_qty=5` وأن `store_remaining_qty=5-store_sold_qty` مع عدم نزول المتبقي عن الصفر.
3. **طلب جزئي:** أنشئ طلب متجر معزولًا بكمية 2؛ يجب أن يظهر المتبقي 3 بعد تحديث الكتالوج. أعد الاختبار مع طلب ثانٍ بكمية 3؛ يجب أن يصبح المتبقي 0.
4. **تجاوز الحصة:** حاول طلب كمية 1 بعد نفاد الحصة؛ يجب أن يرفضه `submit_online_order_atomic` حتى لو تجاوزت الواجهة أو كان الكتالوج قديمًا.
5. **إلغاء طلب:** ألغِ طلبًا اختباريًا وفق مسار الإلغاء الرسمي، وأعد تحميل الكتالوج؛ يجب أن يستثنى الطلب الملغى من `store_sold_qty`.
6. **حفظ الصنف:** جرّب إنشاء صنف وتعديل صنف قائم، وتحقق أن قيمة الحقل تُحفظ وأن `NULL` تبقى فارغة.
7. **اختبار مستقل للنظام الأم:** تحقق أن `RW_OnlineStore` المصادق عليه لا يتعطل وأنه لا يتجاوز عقد إنشاء الطلب الحالي.
8. **Static + Browser:** تحقق من عدم وجود أخطاء JavaScript، ومن صحة العرض على الهاتف وسطح المكتب، ومن أن حصة العرض لا تتغير بسبب مجرد فتح البطاقة أو تعديل السلة.
9. **Production:** بعد نشر الواجهات، نفّذ HTTP/browser E2E مع Fixture معزول، ثم نظّف بيانات الاختبار وتحقق من استعادة baseline. لا تُعلن الإغلاق قبل هذا الدليل.

## 5. Production Evidence / حدود الإثبات

- Production schema: `items.store_display_qty numeric` موجود.
- Production Edge: `save-item v15`, `verify_jwt=true`, يدعم الحقل ويتحقق من صلاحيته.
- Production SQL: `create_item_with_opening_stock` يكتب الحقل عند الإنشاء.
- Production SQL: `get_public_store_catalog(text)` يعيد `store_display_qty/store_sold_qty/store_remaining_qty`.
- Production SQL: `submit_online_order_atomic` يتحقق من الحصة ضمن معاملة ويقفل صفوف الأصناف المطلوبة قبل الفحص.
- ACL الحالي: `get_public_store_catalog` متاح لـ`anon/authenticated` للقراءة العامة المقيدة؛ `submit_online_order_atomic` غير متاح لـ`anon/authenticated` ومتاح لـ`service_role`.
- الحالة الحية: 17 صنفًا للشركة، 0 أصناف بحصة عرض محددة، 16 صنفًا نشطًا ظاهرًا في المتجر.
- لم يُنفذ HTTP/browser E2E ولم يتم التحقق من Artifact المنشور بعد تطبيق التغييرات؛ لأن تغييرات الواجهة لم تُطبق بعد. لذلك الحالة ليست `CLOSED`.

## SELF-AUDIT FINAL

- **What I Proved:** عمود الحصة ومسارات حفظه وإنشاءه واحتسابه وفرضه موجودة بالفعل في Production.
- **What I Did Not Prove:** لم أتحقق من واجهة منشورة بعد تطبيق التعديلات؛ لم أنفذ Browser/HTTP E2E؛ لم أثبت تطابق Cloudflare artifact مع Git.
- **What I Fixed:** لم أغيّر ملفات الواجهة أو Production؛ أعددت تغييرات جراحية دقيقة للمالك، ولم أجر تغييرات DB غير لازمة.
- **What I Initially Missed:** تقرير Report440 أقدم من المصدر الحي الحالي؛ لذلك أُعيد فحص المصدر الحالي بدل افتراض أن تعليماته ما زالت غير مطبقة.
- **What Could Still Be Wrong:** قد يتغير المصدر قبل التطبيق؛ يجب مطابقة SHA والمحددات قبل الاستبدال. وقد تتغير حصة العرض بالتزامن مع مستخدم آخر؛ حماية الخادم هي المرجع النهائي.
- **Final Confidence:** 96/100 للبنية الخلفية والعقد؛ 0/100 لإثبات تطبيق الواجهة حتى يطبق المالك التغييرات ويجري E2E.
- **Final Closure Status:** `BACKEND CONTRACT VERIFIED / OWNER SURGICAL PATCHES READY / UI DEPLOYMENT + HTTP E2E OPEN / NOT CLOSED`.
