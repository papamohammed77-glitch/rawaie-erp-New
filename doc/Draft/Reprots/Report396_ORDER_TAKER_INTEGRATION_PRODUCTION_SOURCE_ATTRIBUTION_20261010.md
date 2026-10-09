# Report396 — تكامل Order Taker مع النظام الأم والقلب المركزي
التاريخ: 2026-10-10
المستودع التشغيلي: `papamohammed77-glitch/erp-frontend`
المستودع التوثيقي: `papamohammed77-glitch/rawaie-erp-New`
Supabase Production: `fiilmooggumokxanwiyx`

## PRE-CHANGE SELF-AUDIT

- Business Understanding: 95/100 — ثبت أن Order Taker ينشئ أوردرات `Confirmed` ويعدل عبر Edge قائم، ولا ينبغي أن ينفذ حركة مخزون عند الإنشاء.
- Architecture Understanding: 97/100 — الإنشاء `order-taker.html → save-sales-invoice → save_sales_invoice_atomic`؛ التعديل `order-taker.html → update-order → update_order_atomic`؛ الربط بالرانشيت مسؤولية مسار الرانشيت في النظام الأم، لا كتابة مباشرة من التطبيق.
- Database Understanding: 97/100 — تمت قراءة تعريف RPC المركزي، ACL، سياسات RLS ذات الصلة، بنية الفروع، وصفوف الأوردرات التجريبية وملحقاتها.
- Historical Understanding: 94/100 — قورنت نسخة Original التاريخية لـsave-sales-invoice مع Current وProduction، واستُخدم Report395 مرجعًا تاريخيًا لا حقيقة حية.
- Production Understanding: 99/100 — تمت قراءة Production Edge قبل التغيير وبعده، والتحقق من الإصدار وJWT وبصمة الحزمة.
- Current Understanding: 98/100 — تم جلب ملفات Current الفعلية من GitHub؛ لم يتم تعديل main.html أو order-taker.html أو core.js.
- Execution Confidence: 90/100 — إصلاح Production نُشر وأعيدت قراءة المصدر وتطابق مع Git؛ لم يتوفر تنفيذ Browser E2E مصادق عليه لهذه الدورة، لذلك لا أدّعي اكتمال التكامل 100%.

### حقائق مؤكدة قبل التغيير

1. `Original/Edge Functions/save-sales-invoice` (blob `eaf9042505a01a24041277d5ecb10a0a0ca095f6`) يمثل مسارًا تاريخيًا كان ينشئ الأوردرات ويكتب أرصدة المخزون مباشرةً عند `Invoiced`، ويحتوي company ID ثابتًا. لا يُعاد هذا السلوك.
2. `Current/Edge_Functions/save-sales-invoice` قبل التعديل كان blob `9ee86c7ee8ed92c79fe37c209ac3392db63f3f87`، مطابقًا لمصدر Production v17 وقت إعادة التحقق السابقة.
3. `order-taker.html` الحالي blob `6fa258e51284bfc8c35fd66fb709d904024f989f`، حجمه 105,353 حرفًا. لم أعدّل الملف.
4. `core.js` الحالي blob `c2e0a7f4ba11f44c11dfc4728ef4a1af1b256b81`، ويستدعي `get_my_effective_profile()`؛ لم أعدّل الملف.
5. Production ACL: `save_sales_invoice_atomic` و`update_order_atomic` غير قابلتين للتنفيذ من `anon` أو `authenticated`، ومسموحتان لـ`service_role` فقط. الاستدعاء الصحيح يمر عبر Edge المصادق عليه.
6. RLS المقروءة تقيد orders حسب company_id والصلاحية، وتقيّد sales-entry users على أوردراتهم المنشأة. كما تقيد branches وstock_branches بالفروع المسموح بها للشركة/المستخدم.
7. Production كان يحتوي مجددًا على ORD-1001/ORD-1002/ORD-1003 وRS-1، رغم أن Report395 سجل تنظيفها سابقًا. الثلاثة Pending، أنشأها `telesales@rawaea.com`، وكميات picked/loaded/delivered/refused/returned صفر. لا توجد حركات مخزون أو قيود محاسبية أو أرصدة عملاء أو تخصيصات دفع/توصيل أو backorders/credit/loyalty/commission/fleet dependencies مرتبطة بها.

## 1. Defect — Source attribution عند إنشاء الأوردر

### Root cause
التطبيق الحالي يبني `hdr` دون حقل `source`. كان Edge يختار مصدرًا واحدًا بترتيب صلاحيات المستخدم:
`telesales → order-taker → van-sales → pos`.
هذا قد يسجل عملية منشأة من Order Taker على أنها telesales إذا كان للمستخدم الصلاحيتان، كما أن المستخدم صاحب `*` بلا source صريح قد ينتهي إلى `pos`.

### Production repair executed
تم تعديل **نفس Edge Function القائمة** `save-sales-invoice` فقط؛ لم يُنشأ Edge جديد ولم يتغير عدد الوظائف.
- قبل: v17، `verify_jwt=true`.
- بعد: v18 ACTIVE، `verify_jwt=true`.
- Production package `ezbr_sha256`: `43d20f1465725c4e273f717ac927c070d4b28be48241bd2c9c46a6d43bb40308`.
- Current Git path: `Current/Edge_Functions/save-sales-invoice`.
- Git blob بعد التحديث: `1864c012f323068ceba5e1f2a0791a2c8bd10dbd`.
- Git commit: `b13814da8c0342aeadc16baf6ff45bb12c40decb`.
- أُعيد جلب Production بعد النشر: المصدر `index.ts` = 6,885 حرفًا، ومصدر Current Git = 6,885 حرفًا؛ **التطابق النصي الكامل مثبت**.
- `ezbr_sha256` بصمة حزمة Production، وليست Git commit SHA.

التغيير يسمح للمستخدم غير المالك بإرسال مصدر صريح فقط إذا كانت لديه الصلاحية المقابلة؛ ويمنع قيم المصدر غير المعروفة. إذا لم يرسل التطبيق source، يبقى fallback السابق متاحًا للتوافق مع المستهلكين الحاليين.

## 2. التنظيف الفعلي لبيانات الاختبار التي عادت بعد Report395

قبل الحذف:
- `orders=3`, `order_details=10`, `runsheets=1`, `run_sheet_details=5`.
- RS-1 كانت Open بلا driver أو vehicle.
- كل الكميات الميدانية في تفاصيل الرانشيت صفر.
- تم فحص مراجع الحركة والمحاسبة ودفتر العميل، ثم التحقق من عدم وجود سجلات في جداول الاعتماديات التالية: commission_run_lines, delivery_collection_receipts, delivery_route_stops, installment_payment_allocations, installments, loyalty_transactions, sales_payment_allocations, delivery_route_plans, daily_settlements, driver_liabilities, credit_block_events, credit_notes, fulfillment_backorders, promotion_redemptions, service_complaints, stock_discrepancies, fleet_expenses, fleet_fuel_transactions, fleet_incidents, fleet_driver_performance_events.
- `audit_log` لم يُحذف.

الإجراء:
- حذف RS-1 المفتوحة الخالية من driver/vehicle.
- حذف ORD-1001/1002/1003 فقط بشرط Pending + `created_by=telesales@rawaea.com` + `source=telesales`.
- حذف تفاصيل الأوردرات والرانشيت تم عبر علاقات قاعدة البيانات.

التحقق بعد الحذف:
- `orders=0`
- `order_details=0`
- `runsheets=0`
- `run_sheet_details=0`
- سجلات حركة المخزون المرتبطة بهذه الأكواد = 0
- قيود اليومية المرتبطة بهذه الأكواد = 0
- تم الإبقاء على audit history.

## 3. التعديل الجراحي المطلوب من المالك في Order Taker

**لم أعدّل `main.html` ولا `order-taker.html`** وفق التعليمات. طبّق التعديلات التالية على `erp-frontend/companies/company-1/sales/order-taker.html)، ثم انشر الواجهة.

### Patch A — تثبيت المصدر الصحيح عند الإنشاء فقط

- الملف: `companies/company-1/sales/order-taker.html`
- الدالة: `self.submitOrder`
- محدد البحث الدقيق:
`RW_API.call('save-sales-invoice', { orderHeader: hdr, itemsList: items, branchCode: selBranch }, function(json) {`

استبدل السطر أعلاه بهذين السطرين:

```javascript
        hdr.source = 'order-taker';
        RW_API.call('save-sales-invoice', { orderHeader: hdr, itemsList: items, branchCode: selBranch }, function(json) {
```

الموضع داخل فرع `else` الخاص بإنشاء أوردر جديد فقط؛ لا تضف `source` إلى `hdr` المشترك قبل فرع التعديل، حتى لا يتغير مصدر أوردر موجود عند تحديثه.

الأثر: تسجيل مصدر الأوردر `order-taker` بدقة حتى لحساب المالك أو الحساب الذي يجمع أكثر من صلاحية. لا ينفذ هذا التغيير حركة مخزون.

### Patch B — استبدال self.syncDown كاملة

- الملف نفسه.
- الدالة: `self.syncDown`.
- محدد البحث: `self.syncDown = function() {`
- احذف الدالة كاملة حتى `};` الذي يسبق `self.syncNow = function() {`.
- ضع البديل التالي كاملًا:

```javascript
    self.syncDown = function() {
        if (!supabase) {
            return Promise.reject(new Error('Supabase غير مهيأ'));
        }

        return Promise.all([
            supabase.from('customers').select('*'),
            supabase.from('items').select('*'),
            supabase.from('stock_branches').select('*'),
            supabase.from('branches').select('*')
        ]).then(function(results) {
            var labels = ['العملاء', 'الأصناف', 'أرصدة المخازن', 'الفروع'];

            for (var i = 0; i < results.length; i++) {
                if (results[i].error) {
                    throw new Error('فشل تحميل ' + labels[i] + ': ' + results[i].error.message);
                }
            }

            var customers = results[0].data || [];
            var items = results[1].data || [];
            var stock = results[2].data || [];
            var branches = results[3].data || [];

            return db.transaction('rw', db.customers, db.items, db.stock, db.branches, function() {
                return Promise.all([
                    db.customers.clear().then(function() { return db.customers.bulkPut(customers); }),
                    db.items.clear().then(function() { return db.items.bulkPut(items); }),
                    db.stock.clear().then(function() { return db.stock.bulkPut(stock); }),
                    db.branches.clear().then(function() { return db.branches.bulkPut(branches); })
                ]);
            }).then(function() {
                customersCache = customers;
                productsCache = items;
                return {
                    customers: customers.length,
                    items: items.length,
                    stock: stock.length,
                    branches: branches.length
                };
            });
        });
    };
```

الأثر: لا تُمسح بيانات Dexie قبل نجاح الاستعلامات الأربعة؛ ويتم تحديث الجداول المحلية داخل معاملة واحدة.

### Patch C — معالجة فشل المزامنة عند الدخول

- الملف نفسه.
- الدالة: `self.enterApp`.
- محدد البحث الدقيق:
`self.syncDown().then(function() { self.loadBranches(); });`

استبدل هذا السطر فقط:

```javascript
        self.syncDown().then(function() {
            self.loadBranches();
        }).catch(function(error) {
            console.error('فشل مزامنة Order Taker:', error);
            self.loadBranches();
            RW_UI.toast('تعذر تحديث البيانات من الخادم؛ تم الاحتفاظ بالبيانات المحلية', 'warning');
        });
```

الأثر: يبقى التطبيق قادرًا على تحميل الفروع المخزنة محليًا مع إظهار تحذير حقيقي بدل رفض Promise غير معالج.

## 4. Loss / Gain / Responsibility Matrix

| المسؤولية | Original | Current قبل التغيير | النتيجة |
|---|---|---|---|
| تحديد الشركة | company ID ثابت في المسار التاريخي | الشركة من سجل المستخدم المرتبط بـauth_id | RETAINED/HARDENED |
| صلاحيات الإنشاء | تحقق أبسط | direct + role permissions | RETAINED/HARDENED |
| كتابة الأوردر | كتابة مباشرة متعددة الخطوات | RPC ذري مركزي | MOVED/HARDENED |
| حركة مخزون Invoiced | تحديثات مباشرة لـstock_branches وinventory_log | post_stock_movement داخل RPC | MOVED/HARDENED |
| مصدر Order Taker | source من الواجهة أو fallback | fallback مبني على ترتيب الصلاحيات | DEFECT FOUND |
| مصدر Order Taker بعد الإصلاح | — | Edge يقبل مصدرًا صريحًا فقط عند وجود صلاحية مقابلة | FIXED IN PRODUCTION |
| إرسال source من التطبيق | غير مثبت | غير موجود في hdr الحالي | OWNER PATCH REQUIRED |
| مزامنة Dexie | — | مسح قبل فحص result.error | DEFECT FOUND / OWNER PATCH REQUIRED |
| ربط الرانشيت | مسار مستقل في النظام الأم | التطبيق لا يكتب run_sheet_details مباشرة | RETAINED؛ لا تُنقل المسؤولية إلى Order Taker |

## 5. الاختبارات والأدلة

### PASS
- Production Edge `save-sales-invoice` نُشر على الإصدار 18 مع `verify_jwt=true`.
- إعادة جلب Production بعد النشر وتطابق نص `index.ts` كاملًا مع Current Git.
- ACL الحالي يثبت منع anon/authenticated من استدعاء RPCs المركزية مباشرة والسماح لـservice_role.
- RLS الحالية تقيد القراءة بسياق الشركة والصلاحيات، مع نطاق فرعي للمستخدمين الميدانيين.
- إزالة fixture التي عادت إلى Production والتحقق من صفر rows في جداول orders/order_details/runsheets/run_sheet_details.
- لا حركات مخزون أو قيود محاسبية متبقية مرتبطة بالأكواد المحذوفة.

### NOT PROVEN
- لم يُنفذ HTTP E2E مصادق عليه من متصفح حقيقي بعد نشر v18؛ لا توجد في هذه الدورة جلسة مستخدم Order Taker موثقة متاحة لاستدعاء التطبيق end-to-end.
- لم يُثبت artifact Cloudflare Pages أو Service Worker المقدم للمستخدم أنه يطابق Git الحالي.
- لم تُطبّق بعد تعديلات Patch A/B/C على `order-taker.html`؛ بقي الملف دون تغيير امتثالًا لتعليمات عدم لمسه.
- لا أدعي أن التطبيق المنشور يعرض source الصحيح قبل تطبيق Patch A وإعادة النشر.
- لم يتم إنشاء أوردر تجريبي دائم؛ لا توجد حاجة لترك بيانات اختبار في Production. يجب تنفيذ اختبار مصادق عليه بعد Patch A ثم حذف fixture المعزولة والتحقق من baseline.

## SELF-AUDIT FINAL

**What I Proved**
- حالة Production الحالية لـsave-sales-invoice قبل وبعد النشر.
- المصدر التاريخي Original كان يحتوي كتابة مباشرة للمخزون؛ Current/Production ينقلان الحركة إلى RPC المركزي.
- Source attribution defect في Edge، وأُصلح في v18.
- Git Current source وProduction source متطابقان نصيًا بعد النشر.
- بيانات ORD-1001/1002/1003 وRS-1 كانت اختبارية/ميدانية صفرية وفق القرائن المفصلة؛ حُذفت مع الحفاظ على audit_log.

**What I Did Not Prove**
- لم أثبت browser/HTTP E2E مصادقًا عليه بعد v18.
- لم أثبت هوية Cloudflare artifact أو Service Worker المنشور.
- لم أثبت سلوك Patch A/B/C runtime لأن المالك لم يطبقها بعد.

**What I Fixed**
- أصلحت منطق تصنيف source في Edge Function القائمة ونشرت v18.
- حدّثت `Current/Edge_Functions/save-sales-invoice` في Git.
- نظفت fixture التي عادت بعد تقرير Report395 وأعدت baseline إلى الصفر في الجداول التشغيلية الأربعة.

**What I Initially Missed**
- تقرير Report395 سجّل baseline صفرًا، لكن Production أظهر أن fixture أعيد إنشاؤها لاحقًا. أُعيد التحقق من Production بدل الاعتماد على التقرير السابق.
- مصدر العملية لم يكن صريحًا في Order Taker؛ وكان ترتيب الصلاحيات قادرًا على تصنيف المستخدم متعدد الصلاحيات بمصدر تطبيق آخر.

**What Could Still Be Wrong**
- قد يستمر التطبيق المنشور في إرسال source فارغ حتى تطبيق Patch A.
- قد يمسح syncDown الكاش عند فشل استعلام حتى تطبيق Patch B/C.
- نسخة Cloudflare Pages / Service Worker لم تُثبت.
- لم يُنفذ authenticated Browser E2E حديث بعد النشر.

**Final Confidence:** مرتفع في إصلاح Edge المنشور وقراءة Production وتنظيف fixture؛ متوسط في التكامل الكامل لأن الواجهة لم تُعدّل/تُنشر ولم يُنفذ Browser E2E.

**Final Closure Status:** `PRODUCTION SOURCE-ATTRIBUTION FIX DEPLOYED / TEST FIXTURES CLEANED / OWNER FRONTEND PATCHES A-B-C PENDING / NOT CLOSED`.

## تعليمات المساعد التالي
1. ابدأ بقراءة Production Edge الحالية وGit Current في نفس الجلسة؛ لا تعتمد على هذا التقرير كحالة حية.
2. لا تُنشئ Edge Function جديدة ولا تعدّل `main.html` أو `core.js` لهذه المهمة.
3. طبّق Patch A ثم B ثم C في `order-taker.html`، مع الحفاظ على edit flow الحالي الذي يمر عبر update-order.
4. انشر الواجهة ثم اختبر حسابًا له صلاحية `orders` فقط، وحسابًا يجمع `orders+telesales`، وحساب المالك `*`.
5. تحقق من المصدر المسجل لكل حالة: `order-taker` عند الإنشاء من هذا التطبيق، واحتفاظ التعديل بمصدر الأوردر الأصلي.
6. تحقق من أن Confirmed لا يغير stock_branches ولا inventory_log، وأن الأوردر يظهر في النظام الأم ويمكن ربطه بالرانشيت عبر المسار المركزي.
7. اختبر فشل أحد استعلامات syncDown وتأكد أن Dexie لم يُمسح، ثم نجاح مزامنة لاحقة.
8. بعد E2E، نظف fixture المعزولة فقط، وأثبت baseline وserved artifact identity. لا تعلن الإغلاق قبل ذلك.
