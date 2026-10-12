# Report422 — مراجعة تكامل تطبيق الكاشير وتثبيت التعديلات الجراحية
**التاريخ:** 2026-10-13  
**النطاق الحصري:** تطبيق POS المنفصل `erp-frontend/companies/company-1/sales/pos.html`، عقود Supabase Production المرتبطة به، وسجلات الاستمرارية.  
**قيود التنفيذ:** لم أعدّل `main.html` أو ملف POS التشغيلي؛ تعليمات المهمة تحصر تعديل الملف التشغيلي في التغيير الجراحي الذي يطبقه المالك. لم أنشئ بيعًا أو مرتجعًا تجريبيًا في Production، ولم أغيّر Schema/ACL/Edge في Production لأن الأدلة الحالية لا تبرر تغييرًا خلفيًا لهذه الفجوات.

## 1. SELF-AUDIT قبل التغيير

- **Business Understanding:** بيع POS النقدي يجب أن ينتج فاتورة واحدة، حركة مخزون مركزية، آثار التحصيل والمحاسبة، مع منع تكرار العملية وعدم الادعاء بنجاح عملية لم يعتمدها الخادم.
- **Architecture Understanding:** التطبيق PWA منفصل؛ تهيئة البيانات عبر RPC مصادق عليه، البيع عبر Edge `save-sales-invoice` ثم RPC مركزي، والمرتجع عبر Edge `complete-return` ثم عقد مرتجع/إشعار دائن. لا حاجة مثبتة إلى Edge جديدة، وهو مهم مع قيود عدد الدوال.
- **Database Understanding:** Production يحتوي `orders.source/order_status/operation_id`، وRPCs الخاصة بتهيئة POS والفروع وقراءة الفواتير، و`save_sales_invoice_atomic`، و`complete_sales_return_credit_note_atomic`، و`post_stock_movement`.
- **Historical Understanding:** قورنت النسخة التاريخية `rawaie-erp-review/PWA/sales/pos.html` (SHA `6ad4da791b72260b922847246ebce93b552d2bad`, 1,115 سطرًا) بالمصدر الحالي (SHA `0160f7cf9c4f194d954d2c7498d91fc639a5f419`, 1,564 سطرًا). النسخة الحالية تتضمن تشديدات في عزل الشركة، التحقق من البيع والمرتجع، وهوية العملية.
- **Production Understanding:** فُحصت الدوال المنشورة مباشرة من مشروع Supabase `fiilmooggumokxanwiyx` مع تعريفات ACL وبيانات الطلبات الحالية.
- **Current Understanding:** المصدر الحالي يحتوي قراءة إعدادات مكررة غير مقيّدة بالشركة، وعرض وسائل دفع غير مدعومة فعليًا، ونصًا متناقضًا عن رد النقد. لا يوجد كاتب مثبت لطابور المبيعات غير المتصلة في ملف POS.
- **Execution Confidence:** مرتفع بشأن المصدر وعقود Production المستعلم عنها؛ لا يكفي لإعلان E2E مكتملًا لأن اختبار متصفح Production لم ينفذ ولم تُنشأ بيانات اختبار مالية.

## 2. ما تحقق من Production في هذه الدورة

وقت استعلام قاعدة البيانات: `2026-10-12 22:39:53.699289+00` إلى `2026-10-12 22:39:57.912834+00`.

| RPC | anon | authenticated | service_role | الاستنتاج |
|---|---:|---:|---:|---|
| `get_pos_bootstrap_data()` | لا | نعم | نعم | نقطة قراءة POS المصادق عليها |
| `get_pos_branches()` | لا | نعم | نعم | قراءة الفروع المصادق عليها |
| `get_pos_invoice_data(text,text)` | لا | نعم | نعم | قراءة بيانات الفاتورة المصادق عليها |
| `save_sales_invoice_atomic(...)` | لا | لا | نعم | Core البيع محمي خلف Edge |
| `complete_sales_return_credit_note_atomic(...)` | لا | لا | نعم | Core المرتجع محمي خلف Edge |
| `post_stock_movement(..., 10 args)` | لا | لا | لا | overload قديم غير قابل للتنفيذ لأي من الأدوار المفحوصة |
| `post_stock_movement(..., 11 args)` | لا | لا | نعم | Core حركة المخزون مع idempotency |

إصدارات Edge المنشورة كما أظهرتها قائمة Production:
- `save-sales-invoice`: **v18**, `verify_jwt=true`, `ezbr_sha256=43d20f1465725c4e273f717ac927c070d4b28be48241bd2c9c46a6d43bb40308`.
- `complete-return`: **v26**, `verify_jwt=true`, `ezbr_sha256=801e390b195522caedfcf68bae8262bb91da06e909c1d43e9344490e3a81f34d`.

توزيع الطلبات الموجود حاليًا (قراءة فقط): `order-taker/Pending=4`, `pos/Invoiced=2`, `pos/Partially Returned=1`, `telesales/Pending=2`. لم تُنشأ أو تُعدّل طلبات.

**قرار Production:** لا تغيير ACL ولا إنشاء RPC/Edge جديد. توسيع صلاحية Core للمستخدم `authenticated` سيكسر حد الأمان الحالي دون عقد مصادق عليه بديل؛ عيوب هذه الدورة تقع في عرض/سلوك UI، أما Offline sales والدفع غير النقدي فيحتاجان عقدًا وظيفيًا حقيقيًا لا ترقيعًا في Production.

## 3. مراجعة ملف اقتراح الكاشير

المسار الذي قدمه المالك:
`doc/Draft/Reprots/اقتراح تطبيق الكاشير-من مساعددد`

تعذر جلب الملف عبر GitHub Contents API (404)، كما لم يعثر بحث GitHub في المستودع على نتيجة بالاسم/الكلمات المتاحة. لذلك **نص الاقتراح نفسه غير مقروء وغير مُقيّم**؛ لن أنسب إليه توصية لم أطلع عليها. استُكملت المراجعة الممكنة اعتمادًا على المصدر الحالي والتاريخي وعقود Production فقط. لا يُعد هذا ادعاءً بأن الاقتراح غير موجود في كل commit/branch أو بمسار آخر.

## 4. نتائج التحقيق وقرارات المسؤولية

| المجال | الحالة المثبتة | القرار |
|---|---|---|
| تسجيل الدخول/صلاحية POS | المصدر يمر عبر `RW_Auth`، وتهيئة البيانات عبر RPC مصادق عليه | RETAIN |
| عزل الشركة والفروع | Edge البيع تتحقق من المستخدم وتقرأ ملف `users` عبر `auth_id`; RPC التهيئة يتحقق من `auth.uid()` وصلاحية POS وسياق الشركة | RETAIN |
| تكرار البيع | `operation_id` مستخدم في مسار البيع وCore idempotency | RETAIN |
| حركة المخزون | Core البيع يستعمل `post_stock_movement` | RETAIN |
| قراءة العملة | `_setupUser` ينفذ قراءة `app_settings` غير مقيّدة بالشركة رغم أن `get_pos_bootstrap_data()` يعيد عملة الشركة | REMOVE REDUNDANT READ |
| البطاقة/المختلط | الأزرار فعالة بصريًا، لكن checkout يرفض غير النقدي؛ لا يوجد عقد تسوية مثبت | DISABLE UI UNTIL CONTRACT EXISTS |
| مرتجع POS | عقد Production يدعم ردًا نقديًا فقط عند تحقق إيصال القبض الأصلي؛ النص الحالي ينفي أي رد نقدي | FIX MISLEADING COPY |
| المبيعات دون اتصال | توجد قراءة لطابور `pending_updates` لكن لا يوجد كاتب `add/put/bulkAdd` في ملف POS الحالي | OPEN CAPABILITY; لا تدّعِ اكتمال Offline Sales |
| E2E | لا يوجد اختبار متصفح Production منفذ في هذه الدورة | OPEN; لا بيانات مالية اصطناعية في Production |

## 5. التعديل الجراحي المطلوب من المالك

**لا تعدّل أي موضع آخر، ولا تعِد بناء الملف.** طبّق التعديلات أدناه على المصدر الذي يطابق SHA `0160f7cf9c4f194d954d2c7498d91fc639a5f419`، ثم انشر واختبر.

### Patch 1 — إزالة قراءة الإعدادات غير المقيّدة بالشركة

**الملف:** `erp-frontend/companies/company-1/sales/pos.html`  
**الدالة:** `self._setupUser = function(user)` (تبدأ حاليًا قرب السطر 238؛ أعد البحث داخل SHA المذكور ولا تعتمد على رقم السطر بعد أي commit).  
**الإجراء:** استبدل الدالة كاملة:

```javascript
self._setupUser = function(user) {
    var isOwner = user.isOwner;
    var perms = user.permissions || [];

    if (!isOwner && perms.indexOf('pos') === -1) {
        RW_UI.showError('غير مصرح');
        RW_Auth.doLogout();
        return;
    }

    currentUser = user;
    pubUserId = user.id;

    // Currency is loaded from company-scoped get_pos_bootstrap_data() inside syncDown().
    RW_ImageCache.loadAll(function() {
        self.enterApp();
    });
};
```

**الأثر:** يمنع قراءة إعدادات عامة غير مقيّدة بالشركة ويعتمد على عملة الشركة التي تعيدها تهيئة POS. لا يغير صلاحيات الدخول أو عقد البيع.

### Patch 2 — تصحيح رسالة المرتجع

**الملف:** `erp-frontend/companies/company-1/sales/pos.html`  
**العنصر:** كتلة التحذير داخل `#returnPaymentModal` ذات الصنف `bg-amber-950/30`.  
**ابحث عن النص الحرفي** «هذه الشاشة تسجل المرتجع والإشعار الدائن فقط.» واستبدل كتلة التحذير كاملة:

```html
<div class="bg-amber-950/30 border border-amber-700/50 p-3 rounded-xl text-center">
    <p class="text-sm font-bold text-amber-300">المرتجع النقدي يعيد المخزون وينشئ الإشعار الدائن ويرد المبلغ إلى خزينة إيصال البيع الأصلي ضمن عقد الخادم.</p>
    <p class="text-xs text-slate-300 mt-1">رد البطاقة أو المحفظة غير مدعوم حاليًا؛ لا تعتمد المرتجع غير النقدي من هذه الشاشة.</p>
</div>
```

### Patch 3 — تعطيل خيارات دفع غير مدعومة

**الملف:** `erp-frontend/companies/company-1/sales/pos.html`  
**العنصر:** الزران `id="btnPayCard"` و`id="btnPaySplit"` داخل `#paymentModal`.  
**استبدل الزرين فقط** بالنص الكامل التالي:

```html
<button type="button" id="btnPayCard" disabled aria-disabled="true" title="يتطلب عقد تسوية محاسبيًا معتمدًا" class="py-2.5 rounded-xl border border-slate-700 bg-slate-900 text-slate-500 font-bold text-sm flex flex-col items-center opacity-60 cursor-not-allowed"><span>💳</span><span>بطاقة — قيد الربط</span></button>
<button type="button" id="btnPaySplit" disabled aria-disabled="true" title="يتطلب توزيعًا محاسبيًا معتمدًا لكل وسيلة دفع" class="py-2.5 rounded-xl border border-slate-700 bg-slate-900 text-slate-500 font-bold text-sm flex flex-col items-center opacity-60 cursor-not-allowed"><span>🔀</span><span>مختلط — قيد الربط</span></button>
```

لا تُفعّل البطاقة/المحفظة/المختلط قبل وجود عقد تسوية ذري يثبت المقبوضات، وحسابات التسوية، والإلغاء/الاسترجاع، والـidempotency، والأثر المحاسبي.

### Patch 4 — تسمية زر المرتجع بوضوح

**الملف:** `erp-frontend/companies/company-1/sales/pos.html`  
**العنصر:** الزر `id="btnPayReturn"` الذي يحتوي النص «إتمام المرتجع وإعادة المبلغ للعميل».  
**استبدل النص فقط** بهذا النص:

```html
<i class="fa-solid fa-undo ml-2"></i> تسجيل المرتجع ورد النقد (للفواتير النقدية)
```

## 6. اختبارات إلزامية بعد تطبيق المالك

1. تسجيل دخول مستخدم POS مصادق عليه؛ تحقق من ظهور العملة الصحيحة من `get_pos_bootstrap_data()` دون قراءة إعدادات شركة أخرى.
2. مستخدمان من شركتين: تحقق من عدم تسرب العملة أو الفروع أو الأصناف أو الرصيد.
3. بيع نقدي معتمد في بيئة اختبار/fixture معزولة: تحقق من `orders.operation_id/source/order_status`، تفاصيل الفاتورة، حركة المخزون، إيصال القبض والقيد المحاسبي.
4. إعادة إرسال نفس `operation_id`: يجب أن تعيد نفس الفاتورة بلا خصم أو قيد مكرر.
5. مرتجع نقدي لفاتورة POS لها إيصال قبض أصلي: تحقق من `refund_posted=true` والإشعار الدائن وحركة المخزون وإيصال الصرف والخزينة الأصلية.
6. مرتجع غير نقدي: رفض صريح بلا آثار جزئية.
7. زرا البطاقة والمختلط معطلان، ولا يمكن اختيار أي منهما.
8. انقطاع الشبكة: لا يظهر نجاح بيع قبل اعتماد الخادم؛ لا تصف Offline Sales بأنها مكتملة.
9. اختبر التطبيق المنشور في المتصفح؛ Git SHA وHTTP 200 وحدهما لا يثبتان E2E.
10. أعد فحص `orders` قبل/بعد الاختبار وتأكد من تنظيف fixture وعدم بقاء أي أثر اختبار.

## 7. ما لم يُنفّذ ولماذا

- لم أعدل `pos.html` أو `main.html`: حدود المهمة تطلب أن يكون ملف التطبيق التشغيلي تعديلًا جراحيًا يطبقه المالك، وملف النظام الأم محظور التعديل من المساعد.
- لم أعدل Supabase Production: ACL الحالي سليم، والـRPCs المركزية لا ينبغي فتحها مباشرة للمتصفح. لا يوجد defect خلفي مثبت يستدعي تغييرًا لهذه الفجوات.
- لم أُنشئ مبيعات/مرتجعات اصطناعية في Production؛ لا يوجد fixture معزول مثبت في هذه الدورة.
- لم أنفذ E2E في متصفح Production؛ لذلك لا أدّعي تحقق Runtime أو إغلاق 100%.
- لم أقيّم نص اقتراح الكاشير نفسه لأنه لم يُسترجع. يلزم تصحيح مساره أو توفير رابط raw/commit صالح قبل الحكم على توصياته.

## 8. SELF-AUDIT FINAL

- **What I Proved:** مصدر POS الحالي والتاريخي؛ إصدارات Edge الحية؛ ACL الفعلي للـRPCs؛ حدود عزل الشركة؛ وجود idempotency للبيع؛ الاعتماد على `post_stock_movement`؛ التناقض في نص المرتجع؛ أن خيارات الدفع غير النقدي غير مدعومة في checkout؛ غياب كاتب طابور Offline في ملف POS.
- **What I Did Not Prove:** تطابق artifact الذي تقدمه الاستضافة بايتًا ببايت مع Git؛ نجاح E2E عبر متصفح Production؛ إكمال Offline Sales؛ دعم التسوية غير النقدية؛ محتوى الاقتراح الذي تعذر استرجاعه.
- **What I Fixed:** لا تغيير في الملفات التشغيلية أو Production؛ أعددت أربع تعديلات جراحية دقيقة للمالك لأن هذا هو حد التغيير المسموح.
- **What I Initially Missed:** أن قراءة طابور `pending_updates` لا تعني وجود مسار كتابة/مزامنة Offline مكتملًا، وأن إظهار وسيلة دفع ليس دليلًا على دعم عقد تسويتها.
- **What Could Still Be Wrong:** قد تكون هناك تغييرات أحدث في فرع/commit غير الافتراضي أو artifact منشور غير مطابق للمصدر؛ لم يُثبت browser E2E.
- **Final Confidence:** مرتفع في النتائج المدعومة بالمصدر وProduction SQL، متوسط في التكامل الكلي.
- **Final Closure Status:** `SOURCE + PRODUCTION CONTRACTS RECONCILED / OWNER PATCHES READY / PROPOSAL CONTENT UNVERIFIED / PRODUCTION E2E OPEN / NOT 100% CLOSED`.

## نقطة الاستكمال الدقيقة
1. استرجع ملف الاقتراح من المسار الصحيح/commit صالح واقرأه كاملًا قبل تقييم توصياته.
2. يطبق المالك الـ4 patches أعلاه على SHA المصدر الحالي ثم ينشر POS.
3. نفذ اختبار المتصفح المصدق على بيئة معزولة وأثبت idempotency والآثار المخزنية والمحاسبية.
4. لا تبدأ تطوير Offline Sales أو non-cash settlement بكتابة UI فقط؛ صمم عقدًا كاملاً واختبره أولًا، مع عدم إنشاء Edge جديدة ما دام حد الدوال قائمًا.
5. حدّث هذا السجل و`CURRENT_STATE.md` بعد ظهور دليل النشر والاختبار الفعلي.
