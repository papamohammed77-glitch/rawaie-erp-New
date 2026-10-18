# Report440 — التحقيق الجنائي وإصلاح تكامل المتجر الإلكتروني — 2026-10-18

## 1. الحالة التنفيذية

الحالة: **PRODUCTION FOUNDATION REPAIRED / OWNER SOURCE PATCH REQUIRED / NOT CLOSED**.

لم أعدّل الملف التشغيلي للمتجر ولا main.html؛ التزمت بقاعدة أن المالك يطبق تغييرات الواجهة، بينما نُفذت تغييرات Supabase/Production المبرهنة مباشرة.

## 2. PRE-CHANGE SELF-AUDIT

- Business Understanding: 94/100 — فهم مسار المتجر العام وطلب Pending، لكن التسعير النهائي والكوبونات ما زالا يحتاجان عقدًا موحدًا.
- Architecture Understanding: 95/100 — فصل قراءة الكتالوج العام عن جداول ERP الخاصة، مع إبقاء مسار النظام الأم المصادق عليه.
- Database Understanding: 96/100 — تم فحص RLS والجداول وRPC وبيانات الفرع الرئيسي.
- Historical Understanding: 92/100 — تمت مقارنة Original وCurrent وقراءة سجل commits المتاح وملف الحوكمة كاملًا.
- Production Understanding: 97/100 — تمت قراءة Edge الحي وRPC/schema/ACL والبيانات الحالية.
- Current Understanding: 100/100 — الملف الحالي فُحص كاملًا إلى EOF.
- Execution Confidence قبل التغيير: 86/100؛ بعد اختبارات SQL: 94/100؛ لا تُرفع إلى 100 بسبب غياب HTTP/browser E2E وتغييرات الواجهة التي ينفذها المالك.

Confirmed Facts:
- ملف المتجر الحالي: papamohammed77-glitch/erp-frontend/companies/company-1/store/index.html
- Current blob SHA: 2d227aa2bbd44df38071313fc0fb848127678f72 — 503 سطرًا.
- Original/Review store/index.html: SHA مطابق 2d227aa2bbd44df38071313fc0fb848127678f72. آخر 10 commits الخاصة بالملف تعود إلى 2026-07-21؛ لم يظهر تعديل لاحق في تاريخ هذا المسار.
- Production project: fiilmooggumokxanwiyx.
- قبل الإصلاح كان submit-online-order v9 مع verify_jwt=true وhash fc0be3c018b5041d670b70576a9a16aabd91c429d601bbf488f3fe142cc64c7a.
- Production app_settings كانت تحتوي صفًا واحدًا للشركة 00000000-0000-0000-0000-000000000001، والفرع الرئيسي a38332b6-6cea-480a-ada1-6eb6ab0590db.
- جدول items لا يحتوي عمود qty؛ الواجهة كانت تقرأ item.qty رغم عدم وجوده.
- قراءة items وapp_settings مباشرة من متصفح anon لا تحصل على الصفوف بسبب سياسات RLS الحالية؛ وجود GRANT على الجدول لا يتجاوز RLS.
- submit_online_order_atomic يستقبل operation_id، لكن الواجهة المستقلة لا ترسله.
- حلقة التحقق في submit_online_order_atomic كانت تقرأ v_effective_items قبل أن يتم بناؤه، كما أن lookup للصنف لم يكن مقيّدًا بـcompany_id.

Unknowns / Unverified:
- لم يتسن تنفيذ POST HTTP حقيقي من بيئة الأدوات؛ محاولة curl فشلت قبل الاتصال بسبب تعذر DNS الخارجي. لذلك لا أدّعي HTTP E2E أو browser E2E.
- لم يُثبت بعد تطابق Cloudflare-served HTML مع Git في المتصفح.
- عقد الكوبونات والتسعير المعروض مقابل السعر النهائي ما زال غير مكتمل.

## 3. Historical / Original / Current / Production

### Historical / Original
- Original/PWA/store/index.html تمت قراءته كاملًا.
- Current/Edge_Functions/submit-online-order في Git كان SHA: a43d0ec989e637fc32712d9773725710ffaad4de.
- Original/Edge Functions/submit-online-order.ts هو SHA: da0d2c632083b91f5c34799236ac9ddf5f81e619. النسخة التاريخية كانت تنشئ order/details مباشرة، وتولّد order_code خارج transaction، ولا تملك idempotency أو إعادة تسعير موثوقة؛ لم تتم استعادتها.
- Current/Git والـProduction v9 كانا متوافقين في السلوك الذي يتطلب مستخدمًا مسجلًا، لكن هذا السلوك لا يطابق المتجر العام الذي يرسل المفتاح العام بدل user access token.

### Production
- بعد الإصلاح: submit-online-order v11، ACTIVE، verify_jwt=false، ezbr_sha256=172eff4fccc8bf43f920e9ab8c83dd39aa988a68c9e5b3170ce320138ff31315.
- verify_jwt=false مقصود لأن endpoint يخدم guest checkout؛ التحقق أصبح داخل Edge: إما user JWT حقيقي وسياق شركة مصادق عليه للمستهلك داخل النظام الأم، أو متجر منشور ومحدد من app_settings. لم يُمنح anon تنفيذ submit_online_order_atomic؛ ما زال الـRPC service_role-only.
- Current/Edge_Functions/submit-online-order حُدّث في Git commit 63185a9d3950a4c420181d5143d315fbd377824f.

## 4. السبب الجذري

1. المتجر المستقل يقرأ app_settings وitems مباشرة، بينما RLS لا تسمح بقراءة عامة؛ النتيجة كتالوج/إعدادات فارغة للزائر.
2. submit-online-order كان يستدعي auth.getUser() على قيمة Authorization التي يرسلها المتجر المستقل وهي المفتاح العام، ثم يشترط users.auth_id وemail. هذا ليس user access token؛ مسار guest checkout لم يكن ممثلًا.
3. الواجهة تقرأ item.qty، لكن العمود غير موجود في items؛ بيانات المخزون الحقيقية موزعة في stock_branches.
4. الواجهة لا تمرر operation_id ثابتًا، وبالتالي إعادة الطلب بعد انقطاع الشبكة قد تنشئ طلبًا آخر.
5. حلقة التحقق داخل submit_online_order_atomic كانت تقرأ v_effective_items قبل تهيئته؛ لذلك لم تكن تتحقق فعليًا من تكرار الأصناف وحدود الكمية في موضعها المقصود. كما أن item lookup لم يكن company-scoped.
6. ميزة الكوبون ليست عقدًا مكتملًا: الواجهة تستعلم coupons مباشرة من anon، والجدول لا يحتوي بيانات كوبونات حاليًا، وEdge لا يمرر couponCode إلى الـRPC، والـRPC يمرر NULL إلى resolve_sales_pricing_atomic.

## 5. ما تم تنفيذه فعليًا في Production

### 5.1 Public storefront catalog
- أضيف إلى app_settings: storefront_key وstorefront_enabled.
- تم نشر المتجر الحالي بمفتاح company-1 للشركة الحالية فقط.
- أُنشئ RPC: public.get_public_store_catalog(text)، SECURITY DEFINER مع search_path ثابت، ويعيد فقط إعدادات العرض والحقول العامة للمنتجات.
- الكتالوج يشتق qty من stock_branches للفرع الرئيسي: available_qty أو qty - allocated_qty؛ ولا يكشف cost_price أو company_id أو حقول ERP الحساسة.
- صلاحية EXECUTE ممنوحة لـanon وauthenticated على RPC القراءة العامة المحدود فقط. لم تُفتح قراءة الجداول الأصلية للزوار.

### 5.2 Order submission
- حُدث submit-online-order إلى v11.
- يدعم مسارين دون كسر مستهلك النظام الأم:
  1. user JWT صالح: يستخرج company_id من users.auth_id، ويتحقق من status، ويحافظ على email الحقيقي في created_by/audit.
  2. guest checkout: لا يسمح إلا بمتجر منشور؛ يستخدم storefront_key، أو fallback آمنًا فقط عندما يكون هناك متجر منشور واحد. عند وجود عدة متاجر يجب تمرير storefront_key.
- يتحقق من الحقول الأساسية، والحد الأقصى 100 صنف، وصحة الكميات وUUID.
- لا يثق في total أو delivery أو السعر القادم من المتصفح؛ ينشئ الطلب عبر submit_online_order_atomic فقط.
- لم تتم إضافة Edge Function جديدة.
- verify_jwt=false لا يمنح الزائر صلاحية RPC؛ كل عمليات الإنشاء تظل عبر Edge إلى service_role إلى RPC.

### 5.3 Core surgical repair
تم تعديل جسم submit_online_order_atomic في Production بأداة migration محكومة:
- حلقة التحقق أصبحت تقرأ p_cart_items قبل إعادة التسعير، بدل v_effective_items غير المهيأ.
- item lookup أصبح مقيّدًا بـcompany_id=p_company_id.
- التغيير يرفض drift غير المتوقع بدل تعديل function مختلف بصمت.

### 5.4 بيانات المتجر
وجدت الصنف QA-SR-ITEM-20260927، واسمه ووصفه يثبتان أنه Fixture دائم لاختبار SupplierReturn، لكنه كان منشورًا للمتجر. لم أحذف سجل المخزون/التاريخ؛ عطّلت عرضه فقط بوضع show_in_store=false، مع إبقائه في النظام لأغراض الاختبار والتدقيق.

## 6. Migration lineage

الملفات القانونية في Git:
- supabase/migrations/20261018203420_public_storefront_catalog_and_public_order_contract.sql
- supabase/migrations/20261018203424_online_order_core_validation_scope_fix.sql

Production migration history يثبت:
- 20261018203420 — public_storefront_catalog_and_public_order_contract
- 20261018203424 — online_order_core_validation_scope_fix

تمت إزالة أسماء الملفات المؤقتة السابقة حتى تتطابق أسماء Git مع migration versions المسجلة.

## 7. الاختبارات والنتائج

PASS:
- استدعاء get_public_store_catalog تحت role anon أعاد الإعدادات و16 منتجًا.
- استجابة الكتالوج لا تحتوي cost_price.
- الصنف QA-SR-ITEM-20260927 لم يعد ظاهرًا في الكتالوج.
- اختبار SQL داخل transaction مع ROLLBACK: إنشاء طلب عبر submit_online_order_atomic ثم إعادة نفس operation_id أعاد duplicate=true؛ لم تُترك بيانات دائمة.
- اختبار SQL داخل transaction مع ROLLBACK: تكرار item_code في السلة رُفض برسالة «لا يجوز تكرار الصنف داخل السلة».
- تم التحقق من وجود الإصلاحين في تعريف Production الحالي.
- submit_online_order_atomic ما زال EXECUTE لـservice_role فقط؛ لم نفتح RPC الحساس لـanon/authenticated.
- عدد طلبات Production قبل اختبار rollback كان 11، ولم يُنشأ طلب اختبار دائم.
- الكتالوج الحالي يعرض 16 منتجًا بعد إخفاء Fixture.

NOT VERIFIED:
- HTTP POST حقيقي إلى Edge من هذه البيئة؛ الشبكة الخارجية غير متاحة.
- browser E2E للمتجر المستقل.
- Cloudflare served artifact parity.
- اختبار المستهلك الداخلي RW_OnlineStore في main.html بعد Edge v11؛ لم ألمس main.html، لكن يجب إجراء regression test للمسارين.
- baseline logs لا تثبت وجود طلبات online_store؛ العدد المرصود كان صفرًا قبل الإصلاح.

## 8. Owner Change Set — إلزامي قبل إغلاق المتجر

الملف:
companies/company-1/store/index.html

Current SHA:
2d227aa2bbd44df38071313fc0fb848127678f72

لا تستبدل الملف كله. نفّذ الاستبدالات الجراحية التالية فقط على هذا الـSHA؛ إذا تغير SHA، أعد تحديد مواضع العناصر قبل التطبيق.

### Patch A — init
ابحث عن الدالة التي تبدأ بـ self.init = function() { في السطور 108–119، واحذف الدالة كاملة واستبدلها بالآتي:

    self.init = function() {
        self.loadSettings().then(function() {
            RW_ImageCache.loadAll(function() {
                self.syncProducts().then(function() {
                    self.showApp();
                    self.loadCustomerToForm();
                    self.checkDailyDeals();
                    RW_UI.updateConnectionStatus('connDot', 'connLabel');
                }).catch(function(err) {
                    console.error('Store catalog cache failed:', err);
                    self.showApp();
                    Swal.fire({ icon: 'error', title: 'تعذر تجهيز المتجر', text: 'أعد تحميل الصفحة أو حاول لاحقًا.' });
                });
            });
        }).catch(function(err) {
            console.error('Store catalog load failed:', err);
            self.showApp();
            var grid = RW_UI.byId('productsGrid');
            if (grid) grid.innerHTML = '<div class="col-span-full text-center p-8 text-red-600 font-bold">تعذر تحميل المتجر. يرجى إعادة المحاولة لاحقًا.</div>';
            Swal.fire({ icon: 'error', title: 'تعذر تحميل المتجر', text: 'لم نتمكن من جلب إعدادات المتجر والمنتجات.' });
        });
    };

### Patch B — loadSettings
ابحث عن self.loadSettings = function() { في السطور 121–144، واحذف الدالة كاملة واستبدلها:

    self.loadSettings = function() {
        return supabase.rpc('get_public_store_catalog', { p_storefront_key: 'company-1' }).then(function(res) {
            if (res.error) throw res.error;
            if (!res.data || !res.data.settings || !Array.isArray(res.data.products)) {
                throw new Error('Public storefront catalog response is invalid');
            }

            var cfg = res.data.settings;
            settings = {
                storeName: cfg.storeName || 'متجر الروائع',
                storeLogo: cfg.storeLogo || '',
                primaryColor: cfg.primaryColor || '#2563eb',
                secondaryColor: cfg.secondaryColor || '#1e40af',
                deliveryFee: Number(cfg.deliveryFee) || 0,
                taxRate: Number(cfg.taxRate) || 0,
                minInvoiceAmount: Number(cfg.minInvoiceAmount) || 0,
                freeShippingThreshold: Number(cfg.freeShippingThreshold) || 0,
                paymentMethod: cfg.paymentMethod || 'both',
                currency: cfg.currency || 'SAR'
            };
            products = res.data.products;

            RW_UI.byId('storeName').textContent = settings.storeName;
            RW_UI.byId('headerStoreName').textContent = settings.storeName;
            if (settings.storeLogo) {
                var logo = RW_UI.byId('storeLogo');
                logo.src = settings.storeLogo;
                logo.classList.remove('hidden');
            }
        });
    };

### Patch C — syncProducts
ابحث عن self.syncProducts = function() { في السطور 146–156، واحذف الدالة كاملة واستبدلها:

    self.syncProducts = function() {
        var rows = Array.isArray(products) ? products : [];
        return db.items.clear().then(function() {
            return rows.length ? db.items.bulkPut(rows) : undefined;
        }).catch(function(err) {
            console.warn('Store local cache update failed:', err);
        }).then(function() {
            self.extractCategories();
            self.renderCategoryBar();
            currentPage = 0;
            self.loadPage();
        });
    };

### Patch D — submitOrder
ابحث عن self.submitOrder = function(customer, total) { في السطور 416–490، واحذف الدالة كاملة واستبدلها:

    self.submitOrder = function(customer, total) {
        RW_UI.showLoader('جاري إرسال الطلب...');

        var itemsList = [];
        for (var i = 0; i < cart.length; i++) {
            itemsList.push({
                code: cart[i].code,
                name: cart[i].name,
                price: cart[i].price,
                qty: cart[i].qty,
                unit: cart[i].unit
            });
        }

        var signature = JSON.stringify({
            user: customer,
            cartItems: itemsList,
            total: Number(total) || 0,
            couponCode: couponCode || '',
            couponDiscount: Number(couponDiscount) || 0
        });

        var storageKey = 'rw_store_pending_order';
        var pending = null;
        try {
            pending = JSON.parse(localStorage.getItem(storageKey) || 'null');
        } catch (e) {
            pending = null;
        }

        if (!pending || pending.signature !== signature || !pending.operation_id) {
            var operationId = (window.crypto && typeof window.crypto.randomUUID === 'function')
                ? window.crypto.randomUUID()
                : 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
                    var r = Math.random() * 16 | 0;
                    return (c === 'x' ? r : (r & 3 | 8)).toString(16);
                });
            pending = { signature: signature, operation_id: operationId };
            try {
                localStorage.setItem(storageKey, JSON.stringify(pending));
            } catch (e) {
                console.warn('Could not persist storefront idempotency key:', e);
            }
        }

        var operationId = pending.operation_id;
        var bodyPayload = {
            storefront_key: 'company-1',
            operation_id: operationId,
            user: customer,
            cartItems: itemsList,
            total: total,
            delivery: settings.deliveryFee || 0,
            couponCode: couponCode,
            couponDiscount: couponDiscount
        };

        fetch(SUPABASE_URL + '/functions/v1/submit-online-order', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'apikey': SUPABASE_KEY,
                'Idempotency-Key': operationId,
                'x-storefront-key': 'company-1'
            },
            body: JSON.stringify(bodyPayload)
        }).then(function(res) {
            return res.json().then(function(json) {
                if (!res.ok || !json || !json.success) {
                    throw new Error((json && (json.msg || json.error)) || 'فشل إرسال الطلب');
                }
                return json;
            });
        }).then(function(json) {
            RW_UI.hideLoader();
            try {
                var saved = JSON.parse(localStorage.getItem(storageKey) || 'null');
                if (saved && saved.operation_id === operationId) localStorage.removeItem(storageKey);
            } catch (e) {}
            Swal.fire({
                icon: 'success',
                title: 'تم إرسال الطلب بنجاح!',
                text: 'رقم الطلب: ' + (json.orderCode || json.orderID || '') + ' — الإجمالي المعتمد: ' + formatCurrency(json.total, settings.currency || 'SAR'),
                confirmButtonText: 'حسنًا'
            }).then(function() {
                cart = [];
                couponCode = '';
                couponDiscount = 0;
                currentPage = 0;
                self.loadPage();
                self.updateCartBadge();
                self.closeCart();
            });
        }).catch(function(err) {
            console.error('Store order submission failed:', err);
            RW_UI.hideLoader();
            Swal.fire({
                icon: 'error',
                title: 'فشل إرسال الطلب',
                text: err.message || 'فشل الاتصال بالخادم'
            });
        });
    };

تنبيه: Patch D يحافظ على operation_id عبر إعادة المحاولة لنفس الحمولة. تغيير العميل أو السلة أو الإجمالي ينشئ operation_id جديدًا. لا يحل Patch D عقد الكوبونات؛ يجب عدم اعتبار خصم الكوبون معتمدًا حتى يُنفذ backend coupon contract.

## 9. مقارنة مرجعية مع الأنظمة المنافسة

- Odoo eCommerce يربط كتالوج المنتج والتسعير/قوائم الأسعار والخصومات وخطوات checkout والتوصيل ومعالجة الطلب والمخزون في دورة واحدة: https://www.odoo.com/documentation/19.0/applications/websites/ecommerce.html و https://www.odoo.com/documentation/18.0/applications/websites/ecommerce/products/prices.html
- Microsoft Dynamics 365 Commerce يوفر inventory availability حسب مخزن القناة، ويمكنه إظهار مستويات المخزون وإخفاء المنتج غير المتوفر أو منعه من الإضافة للسلة: https://learn.microsoft.com/en-us/dynamics365/commerce/dev-itpro/inventory-availability-apis و https://learn.microsoft.com/en-us/dynamics365/commerce/inventory-settings
- SAP Commerce Cloud يعرض توفر المنتج حسب مخزن/مخازن، ويتحقق من التوفر عند إضافة الكمية للسلة، ويدعم availability/order splitting: https://help.sap.com/docs/SAP_COMMERCE_CLOUD_PUBLIC_CLOUD/7e47d40a176d48ba914b50957d003804/8aef948986691014bd5bbb9f2ecfb33f.html
- Daftra يدمج التطبيقات التشغيلية مثل المبيعات والمخزون والمشتريات والمحاسبة ضمن الحساب نفسه: https://docs.daftra.com/en/tutorial/how-the-system-works-and-where-to-start/

تطبيق RAWAEA بعد إصلاح القراءة:
- الكتالوج العام لا يكشف بيانات تكلفة/ERP.
- الكمية المعروضة مصدرها stock_branches للفرع الرئيسي، لا items.qty الوهمي.
- الطلب يمر عبر Edge واحد ثم submit_online_order_atomic، وليس direct table writes.
- ما زال ينقصه عقد quote موحد قبل تأكيد الطلب، وعقد كوبونات company-scoped، والتحقق من كمية الطلب عند الإضافة/checkout وفق قرار المالك حول عدم حجز المخزون قبل runsheet.

## 10. ما لم يتم إغلاقه

1. Owner patches A–D لم تُطبق بعد في الملف التشغيلي؛ لا أستطيع تنفيذها بدل المالك.
2. لم يُنفذ HTTP/browser E2E بسبب عدم توفر outbound network في بيئة الأدوات.
3. الكوبونات ليست مكتملة: جدول coupons بلا صفوف، لا company_id في schema الحالي، والـRPC يتجاهل coupon_code. لا تعتمد على خصم واجهة المتجر.
4. السعر المعروض من discount_percent قد يختلف عن السعر الذي يحسبه resolve_sales_pricing_atomic؛ يجب إنشاء quote RPC آمن ومشترك قبل تأكيد الطلب.
5. add-to-cart لا يمنع طلب كمية تتجاوز available stock، والعقد التاريخي لا يحجز المخزون حتى runsheet؛ يلزم قرار تصميمي وتحقق من السعر/التوفر قبل الإغلاق.
6. يجب اختبار المستهلك الداخلي في main.html بعد تغيير Edge v11؛ main.html لم يُعدّل.

## 11. SELF-AUDIT FINAL

What I Proved:
- RLS كان يمنع المتجر العام من قراءة app_settings/items مباشرة.
- الكتالوج العام يعمل تحت role anon ويعيد 16 منتجًا آمن الحقول.
- Production order core يتحقق الآن من p_cart_items قبل التسعير ويقيد item lookup بالشركة.
- submit-online-order v11 منشور، ويحافظ على مسار user JWT للنظام الأم ويدعم guest checkout لمتجر منشور.
- retry عبر operation_id متماثل يعيد duplicate=true داخل transaction rollback.
- Fixture المورد لا يظهر في الكتالوج، مع الاحتفاظ بسجله التاريخي.

What I Did Not Prove:
- HTTP POST فعلي أو browser E2E أو Cloudflare served artifact parity.
- عمل الواجهة المستقلة قبل تطبيق Owner patches A–D.
- عقد الكوبونات والتسعير المعروض النهائي.

What I Fixed:
- Production catalog RPC/publication identity.
- Production submit-online-order v11.
- Production submit_online_order_atomic cart validation order and company scope.
- إخفاء Fixture QA من المتجر دون حذفه.
- سجلت migrations في Git وProduction.

What I Initially Missed:
- أن submit-online-order له مستهلكان: المتجر العام وRW_OnlineStore داخل النظام الأم. أصلحت Edge v11 للحفاظ على مسار user JWT بدل استبداله بمسار guest فقط.

What Could Still Be Wrong:
- اختلاف السعر الظاهر عن السعر النهائي.
- الكوبونات.
- غياب HTTP/browser test.
- أي سلوك خاص بمتجر متعدد الشركات لم يختبر بعد.

Final Confidence: 94/100 for backend foundation; not 100 for the full store capability.

Final Closure Status:
PRODUCTION BACKEND FOUNDATION REPAIRED / OWNER SOURCE PATCH PENDING / HTTP E2E OPEN / COUPON + PRICE QUOTE OPEN / NOT CLOSED.
