# Report466 — إصلاح معاينة الرانشيت في Loader لتعمل داخل الصفحة
**التاريخ:** 2026-10-21 UTC  
**النطاق:** `papamohammed77-glitch/erp-frontend/companies/company-1/warehouse/loader.html` فقط كتعديل واجهة يطبقه المالك. لم يتم تعديل ملف التطبيق أو `main.html` من المساعد.  
**المستودع المرجعي للتوثيق:** `papamohammed77-glitch/rawaie-erp-New`  
**الحالة:** `ROOT CAUSE PROVEN / OWNER SURGICAL PATCH READY / NO PRODUCTION CHANGE REQUIRED FOR THE MODAL / FULL LOADING INTEGRATION NOT CLOSED`

## 1. PRE-CHANGE SELF-AUDIT

- **Business Understanding:** معاينة الرانشيت قبل التحميل يجب أن تكون شاشة داخل `mainContent` مثل Picker، مع بقاء بدء التحميل عملية مستقلة تتطلب تأكيد المستخدم وتُنفذ عبر المسار الحالي.
- **Architecture Understanding:** `loader.html` يحمّل `../core.js` ويستخدم `RW_Auth` للمصادقة، و`RW_UI` للعرض، و`RW_API.call('start-loading', ...)` لبدء دورة التحميل، و`RW_API.call('complete-loading', ...)` لإنهائها. لا حاجة إلى Edge Function جديدة لهذا التعديل.
- **Database Understanding:** Production `fiilmooggumokxanwiyx` يحتوي `runsheets.company_id` و`run_sheet_details`، مع RLS للقراءة بحسب الشركة وصلاحيات المستخدم. لا توجد حاجة إلى تعديل قاعدة البيانات لتغيير طريقة عرض المعاينة.
- **Historical Understanding:** ملف `rawaie-erp-review/PWA/warehouse/loader.html` والملف الحالي في `erp-frontend` أُرجعا بنفس blob SHA `7e61b04d0d9a480d43763e8b7b21f9cbed78409a`. تمت مقارنة نمط المعاينة الحالي مع نمط Picker الحالي، الذي يعرض تفاصيل الرانشيت داخل `mainContent` بدل استخدام نافذة معاينة منفصلة.
- **Production Understanding:** Production Edge `start-loading` هو v5، `verify_jwt=true`؛ و`complete-loading` هو v11، `verify_jwt=true`. مصدر `complete-loading` الحالي في Git blob SHA `0dd221173aee7f3aa15d16202f034ae94f4104f3` يتطابق دلاليًا مع المصدر المنشور v11 الذي تم فتحه مباشرة.
- **Current Understanding:** `loader.html` blob SHA `7e61b04d0d9a480d43763e8b7b21f9cbed78409a`، 266 سطرًا. موضع العيب `App._showPreviewModal` عند السطر 162.
- **Execution Confidence:** مرتفع في تحديد سبب ظهور النافذة المنفصلة؛ غير كافٍ لإعلان اكتمال تجربة المستخدم قبل أن يطبق المالك التغيير ويختبر النسخة المنشورة في المتصفح.

### سجل المصادر

| المصدر | النتيجة |
|---|---|
| `erp-frontend/companies/company-1/warehouse/loader.html` | قُرئ كاملًا؛ SHA `7e61b04d0d9a480d43763e8b7b21f9cbed78409a`؛ 266 سطرًا |
| `erp-frontend/companies/company-1/warehouse/picker.html` | قُرئ كاملًا؛ SHA `d483bd15b36585b975b63c2ef641481a01d5d084`؛ 55069 حرفًا |
| `erp-frontend/companies/company-1/core.js` | SHA `ff2f581d9900543c16f7cb026e13446520c0329d`؛ تمت مراجعة `RW_Auth`, `RW_API`, `RW_UI.safeHTML`, و`RW_ImageCache` |
| Production Edge `start-loading` | ACTIVE v5؛ `verify_jwt=true` |
| Production Edge `complete-loading` | ACTIVE v11؛ `verify_jwt=true`؛ `ezbr_sha256=c0ca692a29d14d64ec3729ae4bd12b9b84268e826ffc1c6993a48617b552b286` |
| Production SQL/RLS | تمت مراجعة أعمدة `runsheets` و`run_sheet_details` وسياسات القراءة ذات الصلة |
| Production logs | شوهدت طلبات فعلية لقراءة قوائم الرانشيت من `rawaea-erp.pages.dev` في 2026-10-21؛ هذا لا يثبت تطابق كل HTML المنشور مع Git |

## 2. السبب الجذري

في `loader.html`، السطر 162، الدالة `App._showPreviewModal(code, rs, items)` تنشئ HTML للمعاينة ثم تستدعي:

```js
Swal.fire({ title:'معاينة الرانشيت قبل التحميل', html:h, width:'700px', showCloseButton:true, showConfirmButton:false, customClass:{popup:'!rounded-3xl'} });
```

هذا الاستدعاء هو السبب المباشر لظهور المعاينة في نافذة منفصلة. أما Picker فيضع محتوى المعاينة مباشرة داخل `mainContent` بواسطة `safeHTML(byId('mainContent'), html)`.

## 3. OWNER CHANGESET — تعديل جراحي واحد

**الملف:** `papamohammed77-glitch/erp-frontend/companies/company-1/warehouse/loader.html`  
**SHA الحالي:** `7e61b04d0d9a480d43763e8b7b21f9cbed78409a`  
**الدالة:** `App._showPreviewModal(code, rs, items)`  
**الأسطر الحالية:** 162–174

### محدد البحث

ابحث داخل الكائن `App` عن السطر التالي، واستبدل الدالة `_showPreviewModal` كاملة من هذا السطر حتى الفاصلة التي تنهي الدالة:

```js
_showPreviewModal: function(code, rs, items) {
```

### العنصر الحالي المعيب

الدالة الحالية تنتهي بعرض المعاينة من خلال `Swal.fire(...)`، وهذا ينشئ modal منفصلًا.

### النص الكامل البديل

استبدل الدالة كاملة بالنص التالي. لا تستبدل الكائن `App` ولا الملف كاملًا:

```js
_showPreviewModal: function(code, rs, items) {
    var self = this;
    var totalQty = 0;
    var totalValue = 0;

    function esc(value) {
        return String(value == null ? '' : value)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    var h = '<div class="space-y-4 text-right slide-in">';
    h += '<div class="flex items-center gap-3 mb-5">';
    h += '<button type="button" id="loaderPreviewBack" class="w-10 h-10 bg-white rounded-2xl flex items-center justify-center text-orange-600 shadow-sm" aria-label="العودة إلى قائمة الرانشيتات"><i class="fa-solid fa-arrow-right"></i></button>';
    h += '<div class="min-w-0 flex-1"><h2 class="font-black text-xl text-slate-800">معاينة الرانشيت</h2>';
    h += '<p class="text-xs text-slate-400 mt-1">راجع الأصناف والكميات قبل بدء التحميل</p></div></div>';

    h += '<div class="bg-orange-50 rounded-3xl p-5 mb-5">';
    h += '<div class="flex items-start justify-between gap-3"><div><p class="text-xs text-orange-500 font-bold mb-1">رقم الرانشيت</p><h3 class="font-black text-2xl text-slate-800">' + esc(code) + '</h3>';
    h += '<p class="text-xs text-slate-500 mt-2">التاريخ: ' + esc(rs.run_date || '') + ' | الحالة: جاهز للتحميل</p></div>';
    h += '<span class="px-3 py-1 rounded-full bg-white text-orange-600 text-xs font-bold">جاهز</span></div></div>';

    h += '<div class="grid grid-cols-1 sm:grid-cols-3 gap-3 mb-5">';
    h += '<div class="card"><p class="text-xs text-slate-400">عدد الأصناف</p><p class="font-black text-xl text-slate-800 mt-1">' + items.length + '</p></div>';
    h += '<div class="card"><p class="text-xs text-slate-400">إجمالي الكمية المحضّرة</p><p id="loaderPreviewTotalQty" class="font-black text-xl text-slate-800 mt-1">0</p></div>';
    h += '<div class="card"><p class="text-xs text-slate-400">القيمة التقديرية</p><p id="loaderPreviewTotalValue" class="font-black text-xl text-orange-600 mt-1">0</p><p class="text-[11px] text-slate-400 mt-1">جنيه مصري</p></div>';
    h += '</div>';

    h += '<div class="flex items-center justify-between mb-3"><h3 class="font-black text-slate-800">أصناف الرانشيت</h3><span class="text-xs text-slate-400">الكمية المحضّرة هي أساس التحميل</span></div>';

    if (!items.length) {
        h += '<div class="card text-center py-10"><i class="fa-solid fa-box-open text-3xl text-slate-300 mb-3"></i><p class="font-bold text-slate-500">لا توجد أصناف في هذا الرانشيت.</p></div>';
    } else {
        for (var i = 0; i < items.length; i++) {
            var it = items[i];
            var qty = Number(it.qty_picked) || 0;
            var price = Number(it.unit_price) || 0;
            var lineTotal = qty * price;
            totalQty += qty;
            totalValue += lineTotal;

            h += '<div class="card mb-3"><div class="flex items-start gap-3">';
            h += '<div class="shrink-0">' + RW_ImageCache.getImageHTML(it.item_code) + '</div>';
            h += '<div class="min-w-0 flex-1">';
            h += '<p class="font-bold text-slate-800">' + esc(it.item_name || '') + '</p>';
            h += '<p class="text-xs text-slate-400 mt-1">' + esc(it.item_code || '') + ' | ' + esc(it.unit || 'حبة') + '</p>';
            h += '<div class="grid grid-cols-2 sm:grid-cols-4 gap-2 mt-3 text-sm">';
            h += '<div class="bg-slate-50 rounded-xl p-2"><p class="text-[11px] text-slate-400">مطلوب</p><p class="font-bold">' + (Number(it.qty_ordered) || 0) + '</p></div>';
            h += '<div class="bg-blue-50 rounded-xl p-2"><p class="text-[11px] text-slate-400">محضّر</p><p class="font-black text-blue-700">' + qty + '</p></div>';
            h += '<div class="bg-slate-50 rounded-xl p-2"><p class="text-[11px] text-slate-400">سعر الوحدة</p><p class="font-bold">' + esc(RW_UI.formatNumber(price)) + '</p></div>';
            h += '<div class="bg-orange-50 rounded-xl p-2"><p class="text-[11px] text-slate-400">الإجمالي</p><p class="font-black text-orange-700">' + esc(RW_UI.formatNumber(lineTotal)) + '</p></div>';
            h += '</div></div></div></div>';
        }
    }

    h += '<div class="sticky-top pt-2 pb-3 bg-slate-50">';
    h += '<button type="button" id="loaderPreviewStart" class="btn-primary"><i class="fa-solid fa-play ml-2"></i> بدء التحميل</button>';
    h += '<p class="text-center text-xs text-slate-400 mt-2">لن يتغير المخزون بمجرد المعاينة؛ الحركة الفعلية تتم عند إتمام التحميل.</p>';
    h += '</div></div>';

    RW_UI.safeHTML(RW_UI.byId('mainContent'), h);

    var totalQtyEl = RW_UI.byId('loaderPreviewTotalQty');
    var totalValueEl = RW_UI.byId('loaderPreviewTotalValue');
    if (totalQtyEl) totalQtyEl.textContent = RW_UI.formatNumber(totalQty);
    if (totalValueEl) totalValueEl.textContent = RW_UI.formatNumber(totalValue);

    var backButton = RW_UI.byId('loaderPreviewBack');
    if (backButton) backButton.addEventListener('click', function() {
        self.renderPendingTab();
    });

    var startButton = RW_UI.byId('loaderPreviewStart');
    if (startButton) startButton.addEventListener('click', function() {
        self._startLoadingFromPreview(code);
    });
},
```

### طريقة التطبيق

1. افتح `loader.html` على SHA المذكور.
2. ابحث عن `_showPreviewModal: function(code, rs, items) {`.
3. استبدل هذه الدالة وحدها بالنص البديل كاملًا.
4. لا تعدّل `main.html` أو `core.js` أو Edge Functions لتنفيذ تغيير العرض.
5. احفظ التعديل، ثم انشر التطبيق بالطريقة المعتمدة.

## 4. لماذا يحافظ التعديل على العقود الحالية؟

- لا يغيّر `openRunsheet` أو شروط `Loading/Picked`.
- لا يبدأ التحميل تلقائيًا؛ زر بدء التحميل يستدعي `_startLoadingFromPreview(code)` فقط بعد ضغط المستخدم.
- لا ينشئ Edge Function أو RPC أو جدولًا جديدًا.
- يبقي `start-loading` و`complete-loading` ومسار الحركة المركزي كما هما.
- يستخدم `RW_UI.safeHTML` المتاح في `core.js`، ويهرب نصوص بيانات الرانشيت والصنف قبل عرضها.
- يحافظ على عرض الكمية المحضّرة والسعر والإجمالي التقديري، ويعرض العودة إلى القائمة داخل التطبيق نفسه.

## 5. التحقق بعد التطبيق

### اختبار واجهة المعاينة
1. سجّل الدخول بحساب محمّل مخوّل.
2. افتح رانشيت بحالة `Picked`.
3. اضغط على بطاقة الرانشيت.
4. تحقق أن التفاصيل تظهر داخل `mainContent` وأنه لا يظهر `Swal.fire` أو modal معاينة مستقل.
5. تحقق من ظهور رقم الرانشيت والتاريخ والحالة والأصناف والوحدات والكميات والأسعار والإجماليات.
6. اضغط رجوع؛ يجب العودة إلى قائمة الرانشيتات.
7. افتح المعاينة مجددًا واضغط «بدء التحميل»؛ يجب أن يستمر المسار الحالي إلى `start-loading`، ثم تظهر جلسة التحميل الفعلية بعد نجاحه.
8. اختبر شاشة صغيرة/هاتفًا، وعدد أصناف كبيرًا، ورانشيتًا فارغًا إن أمكن في بيئة اختبار معزولة.

### Production evidence
- سجلات Production أظهرت طلبات قراءة فعلية إلى `runsheets` من `https://rawaea-erp.pages.dev/` في 2026-10-21؛ هذا يثبت استخدام التطبيق للـAPI، ولا يثبت وحده تطابق HTML المنشور مع SHA الحالي.
- لم يُنفذ نشر لملف HTML ولم يُجرَ Browser E2E من هذه الجلسة؛ لا يجوز وصف التعديل بأنه Production-verified قبل تطبيقه واختباره.

## 6. فجوات تكامل أخرى مثبتة — لا تُخفَ ولا تُخلط بإصلاح المعاينة

هذه الملاحظات ظهرت أثناء تتبع مسار التحميل، لكنها ليست سبب الـmodal ولا يمكن إغلاقها بمجرد تغيير العرض:

1. **حفظ مسودة الكمية:** `editLoadedItem` ينفذ `supabase.from('run_sheet_details').update({qty_loaded:nq})` ويتجاهل نتيجة الطلب. Production لا يمنح `authenticated` صلاحية `UPDATE` على `run_sheet_details`، ولا توجد سياسة RLS للـUPDATE؛ لذلك هذا الحفظ المباشر لا يملك عقدًا صالحًا، وقد تضيع الكمية عند إعادة تحميل الصفحة. يلزم RPC مصادق عليه ومقيد بالشركة والرانشيت/المحمّل، ثم تعديل مستهلك الواجهة ليستخدمه.
2. **التحميل الجزئي بصفر لبعض الأصناف:** واجهة الكمية تسمح بقيمة `0`، لكن Production `complete-loading v11` يرفض أي عنصر `loaded_qty <= 0`، و`complete_runsheet_loading` يرفض `req <= 0` داخل المعالجة. لذلك لا يطابق العقد الحالي حالات «صنف لم يُحمّل» التي تعرضها واجهة إنهاء التحميل. يلزم حسم العقد التجاري واختباره قبل تعديل core؛ لا ينبغي تمرير كميات صفرية إلى `post_stock_movement`.
3. **تدوين سبب النقص:** الواجهة ترسل `notes`، لكن Edge v11 الحالي يحوّل العناصر إلى `item_code/loaded_qty` فقط ولا يمرر الملاحظات إلى RPC. يلزم إكمال عقد `reason_loading` بشكل يحافظ على ملاحظات التحضير ولا يستبدلها.

لم تُجرَ تغييرات Production في هذه الجلسة؛ لا تتطلب المعاينة داخل الصفحة تغييرًا في قاعدة البيانات، أما النقاط الثلاث أعلاه فهي إصلاحات وظيفية منفصلة يجب إغلاقها قبل إعلان تكامل Loader كاملًا.

## 7. SELF-AUDIT FINAL

- **What I Proved:** سبب النافذة المنفصلة هو `Swal.fire` داخل `App._showPreviewModal`؛ نمط Picker يعرض التفاصيل داخل `mainContent`. مسارات المصادقة وبدء/إنهاء التحميل مرتبطة بالنواة المشتركة وعقود Production المنشورة.
- **What I Did Not Prove:** لم أثبت تطابق HTML الذي يقدمه Cloudflare Pages مع Git blob SHA؛ ولم أنفذ اختبار متصفح بعد تطبيق التغيير.
- **What I Fixed:** جهزت استبدالًا جراحيًا كاملًا للدالة المعيبة، دون تعديل ملف التطبيق بنفسي.
- **What I Initially Missed:** الواجهة تتجاهل خطأ تحديث `run_sheet_details`، وعقد Production لا يقبل صفرًا لبعض أصناف التحميل، كما أن Edge يتجاهل ملاحظات التحميل.
- **What Could Still Be Wrong:** قد تختلف النسخة المقدمة للمتصفح عن Git؛ يلزم Browser E2E بعد نشر المالك.
- **Final Confidence:** مرتفع في Root Cause وOwner Patch؛ غير كافٍ في Runtime/Production UI closure.
- **Final Closure Status:** `PREVIEW ROOT CAUSE PROVEN / SURGICAL OWNER PATCH READY / PRODUCTION UI NOT YET VERIFIED / LOADING LIFECYCLE DEBT OPEN`.
