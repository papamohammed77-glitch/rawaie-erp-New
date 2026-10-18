# Report422 — التحقيق الجنائي لتكامل المتجر الإلكتروني مع Production
**التاريخ:** 2026-10-18 UTC  
**النطاق الوحيد:** `erp-frontend/companies/company-1/store/index.html` وعقود Supabase المرتبطة به.  
**قيود المالك:** لم أعدّل `main.html` أو ملف المتجر التشغيلي. تعديل الواجهة أدناه مخصص للمالك؛ أي تغيير في Supabase يجب أن يظل متوافقًا مع العقود المنشورة.

## 1. PRE-CHANGE SELF-AUDIT
- Business understanding: 90/100 — دورة المتجر إلى طلب Pending ثم النظام الأم؛ لم أُثبت بعد E2E من المتصفح.
- Architecture understanding: 92/100 — يوجد RPC كتالوج عام، وEdge Function قائمة، وRPC تسعير مركزي.
- Database understanding: 90/100 — فُحصت عقود التسعير والكatalog والجداول ذات الصلة.
- Historical understanding: 75/100 — راجعت migrations الأخيرة ذات الصلة؛ لم أُثبت بعد كل السجلات التاريخية للواجهة.
- Production understanding: 95/100 — جرى فحص Production مباشرة في 2026-10-18.
- Current understanding: 95/100 — ملف المتجر الحالي قُرئ كاملًا من GitHub حتى EOF.
- Execution confidence: 80/100 — العيوب مثبتة؛ لم أنفذ بعد إصلاحًا ونشرًا واختبار HTTP نهائيًا.

## 2. Snapshot مثبت
- ملف الواجهة: `erp-frontend/companies/company-1/store/index.html`
- Git blob SHA: `2d227aa2bbd44df38071313fc0fb848127678f72`
- الحجم: 37,819 حرفًا / 503 سطرًا؛ قراءة كاملة.
- Production project: `fiilmooggumokxanwiyx`.
- `submit-online-order`: Production v11، `verify_jwt=false`, `ezbr_sha256=172eff4fccc8bf43f920e9ab8c83dd39aa988a68c9e5b3170ce320138ff31315`.
- `get_public_store_catalog(text)` موجودة، SECURITY DEFINER، وEXECUTE مسموح لـanon/authenticated؛ استدعاؤها المباشر نجح وأعاد `settings` و17 صنفًا منشورًا.
- Production بها storefront منشور واحد من أصل صف إعدادات واحد؛ لذلك RPC الكتالوج تقبل حاليًا المفتاح null، لكن هذا لن يبقى آمنًا عند نشر أكثر من متجر.
- `public.orders`: 11 طلبًا، 0 مصدرها `online_store`، 0 طلبات مسجل عليها `coupon_code`، و0 طلبات ذات `discount_amount > 0` وقت الفحص.
- جدول `promotions` لا يحتوي سجلات حاليًا. لا توجد بيانات اختبار/طلبات اصطناعية أنشأتها.

## 3. العيوب المثبتة في Current Store
1. `loadSettings()`، السطر 121، يقرأ `app_settings` مباشرة عبر `select('*').limit(1).single()` بدل RPC الكتالوج المنشورة. هذا يتجاوز واجهة النشر العامة المقصودة ويعتمد على صلاحيات الجدول ووجود صف واحد.
2. `syncProducts()`، السطر 146، يقرأ `items` مباشرة. هذا يتجاوز `get_public_store_catalog` الذي يطبق company scope ويربط المخزون بفرع الشركة الرئيسي.
3. `applyCoupon()`، السطر 332، يستعلم من جدول `coupons` ويحسب الخصم في المتصفح. عقد الخصومات المركزي الموجود فعليًا هو `resolve_sales_pricing_atomic(..., p_coupon_code, ...)` الذي يمرر إلى `resolve_promotion_cart` وجدول `promotions`. هذا اختلاف بين عقد الواجهة وعقد التسعير المركزي.
4. `checkout()` و`updateCartTotals()` يحسبان الإجمالي محليًا من أسعار العميل ورسوم التوصيل والخصم. لا يجوز اعتبار هذا الإجمالي مرجعًا ماليًا.
5. `submitOrder()` يرسل `couponCode` و`couponDiscount` إلى Edge، لكن Production Edge v11 لا يقرأهما عند استدعاء RPC. وهو يستدعي `submit_online_order_atomic` ذي 8 معاملات.
6. Production RPC `submit_online_order_atomic(uuid,text,text,text,text,text,jsonb,uuid)` يستدعي `resolve_sales_pricing_atomic` مع `NULL` بدل كود الكوبون؛ إذن الكوبون المعروض في الواجهة لا يدخل عقد التسعير المركزي. هذه فجوة فعلية وليست تجميلية.
7. الواجهة ترسل `price` من العميل؛ RPC الحالية تعيد التسعير المركزي لاحقًا، لكن يجب إزالة الاعتماد على السعر القادم من العميل من مسار التسعير النهائي وتأكيد أن قيمة الطلب المخزنة دائمًا هي القيمة التي أعادها المحرك المركزي.
8. خصائص المتجر/الشعار/الألوان/التوصيل لها حقول في `app_settings`، والـRPC العامة تعيد اسم المتجر والشعار واللون الأساسي والثانوي ورسوم التوصيل والحد المجاني والحد الأدنى والعملة وطريقة الدفع. الواجهة الحالية تقرأ بعض هذه الحقول مباشرة، لكنها لا تستخدم `secondaryColor` لتطبيق الهوية بصورة كاملة.

## 4. ما ثبت في عقد Production
- `get_public_store_catalog(text)` يعيد `{ settings, products }`، ويرشح الأصناف حسب `company_id`, `is_active`, `show_in_store`، ويربط المخزون عبر `main_branch_id` مع تحقق أن الفرع تابع للشركة.
- `resolve_sales_pricing_atomic` يستخدم السعر الأساسي/كتالوج الأسعار التجاري ثم `resolve_promotion_cart` مع كود الكوبون.
- `submit_online_order_atomic` الحالي يحسب رسوم التوصيل والضريبة والحد الأدنى ويكتب الطلب والتفاصيل وAudit، لكنه يمرر `NULL` للكوبون ولا يسجل `coupon_code` في INSERT الحالي.
- ACL: RPC الكتالوج مسموحة للزوار؛ RPC التسعير وإنشاء الطلب محجوبتان عن anon/authenticated ومتاحتا لـservice_role، وهو الحد الأمني الصحيح للمسار الحالي.

## 5. التعديل الجراحي المطلوب في ملف الواجهة — ينفذه المالك
**الملف:** `erp-frontend/companies/company-1/store/index.html`  
**لا تعدّل الملف كاملًا.** لا تلمس `main.html`.

### A) استبدال `self.loadSettings` بالكامل (ابتداءً من السطر 121)
استبدل جسم الدالة الحالية بالدالة التالية، مع إضافة المتغير `var storeCatalog = null;` بجوار متغيرات الحالة أعلى IIFE:

```js
self.loadSettings = function() {
    return supabase.rpc('get_public_store_catalog', { p_storefront_key: null })
        .then(function(res) {
            if (res.error) throw res.error;
            if (!res.data || !res.data.settings || !Array.isArray(res.data.products)) {
                throw new Error('تعذر تحميل كتالوج المتجر المنشور');
            }
            storeCatalog = res.data;
            var s = storeCatalog.settings;
            settings = {
                storeName: s.storeName || 'متجر الروائع',
                storeLogo: s.storeLogo || '',
                primaryColor: s.primaryColor || '#2563eb',
                secondaryColor: s.secondaryColor || '',
                deliveryFee: Number(s.deliveryFee) || 0,
                taxRate: Number(s.taxRate) || 0,
                minInvoiceAmount: Number(s.minInvoiceAmount) || 0,
                freeShippingThreshold: Number(s.freeShippingThreshold) || 0,
                paymentMethod: s.paymentMethod || 'both',
                currency: s.currency || 'SAR'
            };
            RW_UI.byId('storeName').textContent = settings.storeName;
            RW_UI.byId('headerStoreName').textContent = settings.storeName;
            if (settings.storeLogo) {
                var logo = RW_UI.byId('storeLogo');
                logo.src = settings.storeLogo;
                logo.classList.remove('hidden');
            }
            document.documentElement.style.setProperty('--store-primary', settings.primaryColor);
            if (settings.secondaryColor) {
                document.documentElement.style.setProperty('--store-secondary', settings.secondaryColor);
            }
        });
};
```

### B) استبدال `self.syncProducts` بالكامل (ابتداءً من السطر 146)
```js
self.syncProducts = function() {
    if (!storeCatalog || !Array.isArray(storeCatalog.products)) {
        return Promise.reject(new Error('كتالوج المتجر لم يتم تحميله'));
    }
    products = storeCatalog.products.filter(function(p) {
        return p && p.is_active === true && p.show_in_store === true;
    }).map(function(p) {
        return Object.assign({}, p, {
            price: Number(p.sales_price) || 0,
            qty: Number(p.qty) || 0
        });
    });
    return db.items.clear()
        .then(function() { return db.items.bulkPut(products); })
        .then(function() {
            self.extractCategories();
            self.renderCategoryBar();
            currentPage = 0;
            self.loadPage();
        });
};
```

**مهم:** هذه الخطوتان تصلحان مصدر قراءة الكتالوج فقط. لا تعتبران إصلاحًا للكوبونات أو إغلاقًا كاملًا للمتجر؛ يلزم تعديل Production RPC/Edge الخاصين بالطلب أولًا، ثم تعديل `applyCoupon/checkout` لتعرض نتيجة التسعير الخادمية لا حسابًا محليًا.

## 6. Production repair status
لم أنشر تغييرًا في Edge/RPC خلال هذه الدورة. السبب: إصلاح الكوبون يتطلب تحديثًا متوافقًا ومتزامنًا لعقد `submit_online_order_atomic`، وحفظ `coupon_code`، وتسجيل `promotion_redemptions` بطريقة idempotent، والتحقق من حدود الاستخدام والتزامن؛ نشر تمرير الكوبون وحده سيكون إصلاحًا ناقصًا. لم أغيّر بيانات Production ولم أنشئ طلبات اختبار.

## 7. اختبارات الإغلاق الإلزامية بعد الإصلاح
1. GET/RPC للكتالوج العام يعيد بيانات الشركة المنشورة فقط، ويخفي الأصناف غير النشطة/غير المعروضة.
2. تغيير إعدادات الاسم/الشعار/اللون/رسوم التوصيل في النظام الأم ينعكس في المتجر دون تعديل ملف الواجهة.
3. السعر النهائي المعروض والمرسل للعميل يطابق التسعير الخادمي؛ لا يُقبل `price` أو `total` من العميل كحقيقة مالية.
4. كوبون صالح/منتهي/غير صالح/الحد الأدنى/حد الاستخدام لكل عميل/حد الاستخدام العام.
5. الخصم لا يتجاوز قيمة السلة، ولا يُطبق مرتين مع العروض التلقائية.
6. Retry بنفس `operation_id` لا ينشئ طلبًا أو redemption مكررًا.
7. إنشاء طلب E2E عبر HTTP: Edge → RPC → orders/order_details → audit + redemption، ثم تحقق من عدم وجود خصم/حجز مخزون غير مقصود؛ طلب المتجر يبدأ Pending ولا يخصم المخزون مباشرة.
8. اختبارات متعددة الشركات ومفتاح storefront خاطئ، مع رفض الوصول المتبادل.
9. لا يتم استخدام Production order فعلي للاختبار؛ استخدم Staging أو transaction rollback مع إثبات عدم بقاء أثر.

## 8. SELF-AUDIT FINAL
- What I Proved: الكتالوج العام يعمل في Production؛ 17 صنفًا تُعاد من RPC؛ عقد التسعير المركزي موجود؛ مسار الكوبون الحالي يتجاهل الكود؛ الواجهة الحالية تتجاوز RPC الكتالوج.
- What I Did Not Prove: المتصفح المنشور/E2E الفعلي، كل سياسات RLS على الواجهة الحالية، تجربة كوبون ناجح (لا توجد promotions حاليًا)، مطابقة الواجهة المنشورة مع Git.
- What I Fixed: لا تغيير Production في هذه الدورة؛ جهزت تعديلين جراحيين محددين للمالك لإعادة قراءة الإعدادات والمنتجات من RPC المنشورة.
- What I Initially Missed: أن `submit_online_order_atomic` يمرر `NULL` إلى محرك الخصومات، وأن الواجهة تقرأ `coupons` بدل `promotions`.
- What Could Still Be Wrong: قد توجد قيود/سياسات إضافية أو نشر واجهة مختلف عن Git؛ يجب إعادة الفحص بعد تطبيق التعديل.
- Final Confidence: 85% للتشخيص، وليس للإغلاق الوظيفي.
- Final Closure Status: `OPEN — DEFECTS PROVEN; OWNER UI PATCH READY; PRODUCTION COUPON CONTRACT REPAIR + E2E NOT CLOSED`.
