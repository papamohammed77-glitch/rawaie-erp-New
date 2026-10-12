# Report421 — التحقيق الجنائي لتكامل تطبيق الكاشير POS
**التاريخ:** 2026-10-13  
**النطاق:** `erp-frontend/companies/company-1/sales/pos.html` + عقود POS في Supabase Production  
**قاعدة الالتزام:** لم يتم تعديل `main.html` أو `pos.html`، ولم تُنشأ بيانات بيع تجريبية في Production.  
**الحالة:** `SOURCE + PRODUCTION CONTRACTS VERIFIED / SURGICAL OWNER PATCH READY / FULL POS CLOSURE NOT YET PROVEN`

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** نقطة البيع يجب أن تسجل البيع النقدي مرة واحدة، وتخصم المخزون من الفرع المحدد عبر قلب المخزون، وتنتج الآثار المحاسبية، وتدعم مراجعة الفواتير والمرتجعات دون إظهار نجاح غير حقيقي.
- **Architecture Understanding:** POS تطبيق PWA منفصل، ويستخدم `core.js` للمصادقة و`RW_API` لاستدعاء Edge الحالية. مسار البيع الحالي هو `POS checkout → save-sales-invoice Edge → save_sales_invoice_atomic RPC → stock/accounting/ledger`. لا توجد حاجة مثبتة لإنشاء Edge جديدة.
- **Database Understanding:** Production يحتوي `orders.source/order_status/operation_id`، و`save_sales_invoice_atomic(jsonb,jsonb,text,text)`، و`get_pos_bootstrap_data()`، و`get_pos_branches()`، و`get_pos_invoice_data(text,text)`، و`complete_sales_return_credit_note_atomic(...)`.
- **Historical Understanding:** تمت قراءة النسخة التاريخية `rawaie-erp-review/PWA/sales/pos.html` (1115 سطرًا، blob `6ad4da791b72260b922847246ebce93b552d2bad`) ومقارنتها بالمصدر الحالي. النسخة الحالية أطول (1564 سطرًا) وتحتوي RPCs مقيدة بالشركة، وإظهارًا أكثر صرامة لأخطاء البيع والمرتجع. لم يُستبدل البناء التاريخي أو تُعد كتابة التطبيق.
- **Production Understanding:** فُحصت Edge functions وقواعد RPC/ACL مباشرة في مشروع `fiilmooggumokxanwiyx`.
- **Current Understanding:** المصدر الحالي `pos.html` blob SHA `0160f7cf9c4f194d954d2c7498d91fc639a5f419`، بطول 91,752 حرفًا و1564 سطرًا.
- **Execution Confidence:** مرتفع في مطابقة المصدر والعقود المنشورة التي تم استعلامها؛ غير كافٍ لإعلان اكتمال Runtime E2E لأننا لم ننفذ بيعًا مصادقًا حقيقيًا في واجهة Production ولم نغيّر بيانات البيع لاختبارها.

### سجل الفحص

- Historical POS: **OPENED / READ** — `rawaie-erp-review/PWA/sales/pos.html`, SHA `6ad4da791b72260b922847246ebce93b552d2bad`.
- Current POS: **OPENED / READ** — `erp-frontend/companies/company-1/sales/pos.html`, SHA `0160f7cf9c4f194d954d2c7498d91fc639a5f419`.
- Production Edge: **CHECKED** — `save-sales-invoice v18`, `verify_jwt=true`, `ezbr_sha256=43d20f1465725c4e273f717ac927c070d4b28be48241bd2c9c46a6d43bb40308`; `complete-return v26`, `verify_jwt=true`, `ezbr_sha256=801e390b195522caedfcf68bae8262bb91da06e909c1d43e9344490e3a81f34d`.
- Production RPC ACL: **CHECKED** — `save_sales_invoice_atomic` و`complete_sales_return_credit_note_atomic` و`post_stock_movement` غير قابلة للتنفيذ من `anon/authenticated` ومسموح بها لـ`service_role`. `get_pos_bootstrap_data`, `get_pos_branches`, `get_pos_invoice_data` مسموحة لـ`authenticated`، وتتحقق من `auth.uid()` وصلاحية POS/سياق الشركة.
- Production schema/data: **CHECKED READ-ONLY** — جدول `orders` يحتوي `source`, `order_status`, `operation_id`, `company_id`, `branch_id`, `amount_paid` وغيرها. العينة الحالية التي أرجعها الاستعلام: `order-taker/Pending=4`, `pos/Invoiced=2`, `pos/Partially Returned=1`, `telesales/Pending=2`. لم تُنشأ أو تُعدّل بيانات.
- Production logs: الاستعلام المحدد عن أحداث POS بين `2026-10-12T00:00:00Z` و`2026-10-13T00:00:00Z` لم يُرجع سجلات مطابقة؛ هذا **لا يثبت** غياب الاستخدام أو خلو كل سجلات المشروع من الأخطاء.
- Proposal link: تعذر فتح `doc/Draft/Reprots/اقتراح تطبيق الكاشير-من مساعددد` عبر GitHub Contents API (404)، وكذلك جُرّبت امتدادات `.md` و`.txt` ومسار `Reports`. لذلك لا أدّعي أنني قيّمت نص الاقتراح غير المتاح؛ تم التقييم أدناه بناءً على المصدر التاريخي والحالي والعقود الحية فقط.

## ما ثبت عن مسار البيع والمرتجع

1. `POS.syncDown()` يستدعي `get_pos_bootstrap_data()`. الـRPC يحدد المستخدم من `auth.uid()`، ويتحقق من صلاحية `pos`، ويحدد `company_id` من سياق المستخدم، ويعيد الفروع المسموحة والأصناف والمخزون والعملة ضمن الشركة.
2. `save-sales-invoice v18` يتحقق من Bearer token عبر `auth.getUser`، ويربط المستخدم من `public.users.auth_id = auth.users.id`، ويتحقق من الحالة والصلاحيات والفرع ومصدر البيع، ثم يستدعي `save_sales_invoice_atomic` مع `operation_id`.
3. `save_sales_invoice_atomic` يتطلب `operation_id` ويعيد الفاتورة الموجودة عند تكرار العملية، ويستخدم `post_stock_movement` للمخزون ويستدعي عقود المحاسبة/التحصيل ضمن المعاملة. لم يُمنح RPC صلاحية مباشرة لـauthenticated، وهذا صحيح ما دام Edge هو طبقة المصادقة والتحقق الحالية.
4. `complete-return v26` يتحقق من المستخدم والشركة ثم يستدعي `complete_sales_return_credit_note_atomic`. هذا العقد يربط إنشاء الإشعار الدائن بنتيجة `complete_return_atomic`؛ المسار النقدي POS يتحقق من إيصال القبض الأصلي والخزينة والمبلغ، بينما رد البطاقة/المحفظة غير مدعوم ويُرفض بدل ادعاء رد مالي.
5. يوجد فرق مهم بين **Offline app shell/cache** و**Offline sales**: التطبيق يفتح ببيانات محلية قديمة عند انقطاع الشبكة، لكن لا يوجد في الملف الحالي أي `pending_updates.add/put/bulkAdd` ينشئ عملية بيع محلية قابلة للمزامنة. `syncPendingOrders()` قارئ لطابور لا يكتب التطبيق إليه في هذا الملف. لذلك لا يجوز وصف البيع دون اتصال بأنه مكتمل؛ فشل استدعاء Edge يبقي السلة ولا يعلن نجاحًا، لكنه لا يحقق طابور بيع Offline دائمًا.
6. واجهة الدفع تعرض `cash/card/split`، لكن `checkout` يرفض كل ما عدا `cash`. هذا حارس صحيح لحماية المحاسبة من بيع غير مسوّى، لكن عرض الخيارات غير المدعومة على أنها قابلة للاختيار تجربة مربكة.
7. شاشة المرتجع الحالية تعرض نصًا يقول إن الشاشة تسجل الإشعار الدائن فقط ولا ترد النقد، بينما `_finalizeReturn()` ينتظر `refund_posted === true` ويعرض تفاصيل رد نقدي فعلية. عقد Production يدعم رد POS النقدي فقط عند التحقق من إيصال البيع الأصلي؛ لذا النص الحالي متناقض مع التنفيذ. يجب أن يوضح أن المرتجع النقدي فقط مدعوم، وأن البطاقة/المحفظة غير مدعومتين.

## LOSS / GAIN / RESPONSIBILITY MATRIX

| المسؤولية | النتيجة | الدليل |
|---|---|---|
| مصادقة POS والتحقق من صلاحية المستخدم | RETAINED / HARDENED | `get_pos_bootstrap_data` و`get_pos_invoice_data` وEdge `save-sales-invoice v18` |
| عزل الشركة والفروع | RETAINED | `current_user_company_id`, `get_pos_branches`, وفلترة الشركة في Edge |
| منع تكرار فاتورة البيع | RETAINED | `operation_id` في Edge وRPC |
| حركة المخزون المركزية | RETAINED | RPC البيع يستدعي `post_stock_movement` |
| دفع بطاقة/مختلط | MISSING CAPABILITY / GUARDED | UI يعرضه لكن checkout يمنعه؛ لا يوجد عقد تسوية مثبت |
| Offline sales queue | MISSING CAPABILITY | لا يوجد كاتب لـ`pending_updates` في `pos.html` الحالي |
| رد النقد في مرتجع POS | RETAINED, CASH ONLY | `complete-return v26` + `complete_sales_return_credit_note_atomic` + تحقق إيصال القبض |
| نصوص واجهة المرتجع | CONFLICT | النص الظاهر يناقض ما تتوقعه الدالة من `refund_posted` |
| قراءة العملة | REDUNDANT / TENANT-UNSCOPED READ | `_setupUser` يجلب أول `app_settings` بلا `company_id`؛ بينما `syncDown` يجلب العملة من RPC معزول بالشركة |

## التعديلات الجراحية للمالك — لا تُعدّل الملف من المساعد

### Patch 1 — إزالة قراءة إعدادات غير مقيّدة بالشركة

**الملف:** `erp-frontend/companies/company-1/sales/pos.html`  
**العنصر:** `self._setupUser = function(user)`  
**SHA المرجعي:** `0160f7cf9c4f194d954d2c7498d91fc639a5f419`

ابحث عن الدالة `self._setupUser = function(user)` واستبدل **الدالة كاملة** بهذا النص:

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

السبب: `get_pos_bootstrap_data()` يعيد `currency` للشركة الحالية ويُعيّنها `syncDown()`. القراءة المباشرة غير المفلترة زائدة ويمكن أن تختار إعدادًا لا يخص الشركة الحالية إذا سمحت سياسات القراءة بذلك.

### Patch 2 — توحيد نص عقد المرتجع مع Production

**الملف:** `erp-frontend/companies/company-1/sales/pos.html`  
**العنصر:** داخل `#returnPaymentModal`، كتلة التحذير ذات `bg-amber-950/30`.

ابحث عن الكتلة كاملة:

```html
<div class="bg-amber-950/30 border border-amber-700/50 p-3 rounded-xl text-center">
    <p class="text-sm font-bold text-amber-300">هذه الشاشة تسجل المرتجع والإشعار الدائن فقط.</p>
    <p class="text-xs text-slate-300 mt-1">لا يتم رد نقدي أو رد للبطاقة حتى ربط عملية التسوية المحاسبية واعتمادها في النظام.</p>
</div>
```

واستبدلها كاملة:

```html
<div class="bg-amber-950/30 border border-amber-700/50 p-3 rounded-xl text-center">
    <p class="text-sm font-bold text-amber-300">المرتجع النقدي يعيد المخزون وينشئ الإشعار الدائن ويرد المبلغ إلى خزينة إيصال البيع الأصلي ضمن عقد الخادم.</p>
    <p class="text-xs text-slate-300 mt-1">رد البطاقة أو المحفظة غير مدعوم حاليًا؛ لا تعتمد المرتجع غير النقدي من هذه الشاشة.</p>
</div>
```

### Patch 3 — عدم عرض طرق دفع غير مدعومة كخيارات فعالة

**الملف:** `erp-frontend/companies/company-1/sales/pos.html`  
**العنصر:** زرا `#btnPayCard` و`#btnPaySplit` داخل `#paymentModal`.

استبدل الزرين الحاليين:

```html
<button onclick="POS.setPaymentMethod('card')" id="btnPayCard" class="py-2.5 rounded-xl border border-slate-600 bg-slate-800 text-slate-400 font-bold text-sm flex flex-col items-center"><span>💳</span><span>بطاقة</span></button>
<button onclick="POS.setPaymentMethod('split')" id="btnPaySplit" class="py-2.5 rounded-xl border border-slate-600 bg-slate-800 text-slate-400 font-bold text-sm flex flex-col items-center"><span>🔀</span><span>مختلط</span></button>
```

بهذين الزرين المعطلين إلى أن يكتمل عقد التسوية:

```html
<button type="button" id="btnPayCard" disabled aria-disabled="true" title="يتطلب عقد تسوية محاسبيًا معتمدًا" class="py-2.5 rounded-xl border border-slate-700 bg-slate-900 text-slate-500 font-bold text-sm flex flex-col items-center opacity-60 cursor-not-allowed"><span>💳</span><span>بطاقة — قيد الربط</span></button>
<button type="button" id="btnPaySplit" disabled aria-disabled="true" title="يتطلب توزيعًا محاسبيًا معتمدًا لكل وسيلة دفع" class="py-2.5 rounded-xl border border-slate-700 bg-slate-900 text-slate-500 font-bold text-sm flex flex-col items-center opacity-60 cursor-not-allowed"><span>🔀</span><span>مختلط — قيد الربط</span></button>
```

هذا التصحيح لا يدّعي إكمال الدفع الإلكتروني؛ بل يمنع واجهة المستخدم من عرض قدرة لا يتيحها العقد الخلفي. إكمال البطاقة/المحفظة/المختلط يتطلب عقدًا محاسبيًا كاملًا واختبارًا قبل إعادة تفعيلها.

### Patch 4 — تصحيح تسمية زر المرتجع خارج المودال

ابحث عن الزر `id="btnPayReturn"` الذي يحتوي النص `إتمام المرتجع وإعادة المبلغ للعميل`، واستبدل النص فقط بـ:

```html
<i class="fa-solid fa-undo ml-2"></i> تسجيل المرتجع ورد النقد (للفواتير النقدية)
```

## لماذا لم أغيّر Production أو ACL؟

- صلاحيات RPC الحالية تمنع `anon/authenticated` من تنفيذ Core البيع والمخزون والمرتجع مباشرة، وEdge الحالية تتحقق من المستخدم ثم تستخدم service role. فتح RPC مباشرة للمتصفح دون إعادة بناء عقد مصادق عليه ومقيّد بالشركة سيضعف الأمان؛ لذلك لم أجرِ أي GRANT أو تعديل SQL.
- لم أُنشئ Edge جديدة؛ المسارات الحالية تستعمل الدوال المنشورة بالفعل.
- لم أجرِ بيعًا أو مرتجعًا تجريبيًا في Production؛ لا يوجد Fixture معزول مثبت في هذه الدورة، ولا أريد إدخال أثر مالي/مخزني تجريبي إلى بيانات حقيقية.

## اختبارات ما بعد تطبيق المالك للتعديلات

1. تسجيل الدخول بحساب POS مصادق عليه؛ تأكد أن العملة تأتي من `get_pos_bootstrap_data()` فقط.
2. مستخدمان من شركتين مختلفتين: تحقق أن العملة والفروع والأصناف والمخزون لا تتسرب بين الشركتين.
3. إتمام بيع نقدي واحد: تحقق من `orders.operation_id/source/order_status`، تفاصيل الفاتورة، حركة `post_stock_movement`، إيصال القبض والقيد المحاسبي.
4. Retry بنفس `operation_id`: يجب إرجاع نفس الفاتورة دون حركة مخزون أو قيد مكرر.
5. فتح المرتجع لفاتورة POS نقدية: تحقق من `refund_posted=true`، الإشعار الدائن، إيصال الصرف المرتبط بالخزينة الأصلية، حالة الأوردر، والكمية المتبقية.
6. فتح مرتجع لفاتورة غير نقدية: يجب أن يُرفض بوضوح دون تغيير المخزون أو إنشاء إشعار/قيد جزئي.
7. التأكد من أن زري البطاقة والمختلط معطلان ولا يمكن اختيار أي منهما حتى يكتمل عقد التسوية.
8. Offline: تحقق أن التطبيق لا يعلن نجاح فاتورة لم تصل للخادم. لا تعتبر Offline Sales مكتملة؛ طابور المزامنة الحالي لا يحتوي على كاتب مثبت في هذا الملف.
9. اختبار المتصفح الفعلي بعد النشر، وليس الاكتفاء بفحص Git أو HTTP 200.

## التغييرات التي نُفذت في هذه الدورة

- قراءة ومقارنة المصدر التاريخي والحالي.
- قراءة Production Edge `save-sales-invoice v18` و`complete-return v26`.
- قراءة تعريفات RPC الخاصة بتهيئة POS وقراءة الفواتير وحفظ البيع وإكمال المرتجع.
- فحص ACL الفعلي لـ`authenticated/anon/service_role`.
- استعلام قراءة فقط عن أعمدة `orders` وتوزيع `source/order_status`.
- لا تغيير على قاعدة البيانات أو Production، ولا تعديل على `main.html` أو `pos.html`.

## ما لم يُغلق بعد

- **Offline Sales**: فجوة وظيفية مثبتة. يلزم عقد محلي دائم يحدد هوية العملية، حالة Pending Sync، حماية إعادة الإرسال، معالجة نقص المخزون عند المزامنة، وعدم طباعة إيصال نهائي قبل اعتماد الخادم. لا يجوز إضافة queue صورية.
- **Card / Wallet / Split settlement**: غير مدعوم في عقد التسوية الحالي؛ واجهة المستخدم تُضبط لإظهار ذلك بوضوح، لكن القدرة نفسها لم تُبنَ.
- **Production HTTP E2E من واجهة POS**: لم يُنفذ بيع/مرتجع فعلي مصادق عليه في واجهة Production بهذه الدورة.
- **اقتراح الكاشير المشار إليه**: الرابط المحدد أعاد 404 في أداة GitHub بعد تجربة المسار والامتدادات؛ لا أستطيع تقييم نص لم أتمكن من قراءته.

# SELF-AUDIT FINAL

- **What I Proved:** المصدر الحالي والتاريخي؛ Edge versions؛ RPC definitions؛ ACL؛ عقد عزل الشركة؛ استعمال `post_stock_movement`؛ idempotency في البيع؛ دعم رد نقدي POS بشرط إيصال أصلي؛ تناقض نص المرتجع؛ غياب كاتب `pending_updates` في المصدر الحالي.
- **What I Did Not Prove:** تطابق byte-for-byte بين المصدر والملف الذي يقدمه الاستضافة؛ نجاح E2E عبر متصفح Production؛ إغلاق Offline Sales؛ دعم الدفع غير النقدي؛ محتوى الاقتراح غير المتاح.
- **What I Fixed:** لم أعدّل الملفات التشغيلية أو Production احترامًا لحدود المهمة. جهزت تغييرات جراحية محددة للمالك، بلا تغيير تخميني في Core.
- **What I Initially Missed:** الفرق بين نص المودال وعقد المرتجع النقدي الفعلي؛ ووجود قراءة إعدادات مباشرة غير مقيّدة بالشركة رغم وجود RPC مقيّد.
- **What Could Still Be Wrong:** قد توجد إعدادات RLS تمنع تسرب `app_settings` في التطبيق الحالي؛ إزالة القراءة تظل أفضل لأنها زائدة وغير مقيّدة. وقد تتطلب أسماء/حقول الدفع الإضافية عقدًا محاسبيًا جديدًا قبل التفعيل.
- **Final Confidence:** مرتفع في النتائج الثابتة من المصدر وProduction SQL؛ متوسط في اكتمال التكامل الكلي بسبب غياب اختبار واجهة Production وعدم إغلاق Offline/Card/Split.
- **Final Closure Status:** `PARTIAL — SOURCE/PRODUCTION CONTRACTS AUDITED; OWNER PATCH READY; NOT 100% CLOSED`.
