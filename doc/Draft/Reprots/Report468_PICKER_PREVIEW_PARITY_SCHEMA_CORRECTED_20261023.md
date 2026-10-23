# Report468 — تصحيح جراحي لمعاينة Picker بعد إعادة مطابقة Loader الحي

**التاريخ:** 2026-10-23 UTC  
**النطاق الوحيد:** المقارنة بين `erp-frontend/companies/company-1/warehouse/loader.html` و`picker.html` وإعداد تعديل جراحي يطبقه المالك على `picker.html`.  
**قاعدة الملكية:** لم أعدّل `main.html` أو أي تطبيق HTML تشغيلي. لا يوجد تعديل Production/Supabase مطلوب لهذا التغيير العرضي.  
**الحالة:** `SOURCE DEFECT PROVEN / PATCH CORRECTED FOR REAL SCHEMA / OWNER APPLY + DEPLOY + BROWSER E2E OPEN`

## 1. PRE-CHANGE SELF-AUDIT

- **Business Understanding:** معاينة Picker تعرض الرانشيت قبل بدء التحضير. المطلوب نقل جودة العرض إلى مستوى Loader في البنية داخل الصفحة، مع الاحتفاظ بخصوصية Picker: الكمية المطلوبة والوصف، لا سعر التحميل أو قيمته.
- **Architecture Understanding:** قراءة الرانشيت تتم من Supabase JS، وبدء التحضير يظل عبر Edge Function الحالية `start-picking`. لا نضيف Edge Function ولا نغيّر مسار الحجز.
- **Database Understanding:** فحص Production أثبت أن `run_sheet_details.item_id` مرتبط بـ`items.id` بواسطة FK اسمها `run_sheet_details_item_id_fkey`. جدول `items` يحتوي `description` و`image_url`؛ أما `run_sheet_details` فلا يحتوي عمود `description`. لذلك لا يجوز افتراض أن `it.description` في تفاصيل الرانشيت مصدر صحيح.
- **Historical Understanding:** Report466 وثّق تحويل معاينة Loader من SweetAlert منفصل إلى محتوى داخل `mainContent`. Report467 وثّق فجوة معاينة Picker، لكنه افترض ضمنيًا أن `description` متاحة في صف تفاصيل الرانشيت. الفحص الحالي للـschema يكشف أن هذا الافتراض غير صحيح ويجب تصحيحه قبل تطبيق التعديل.
- **Production Understanding:** مشروع Supabase `fiilmooggumokxanwiyx` حالته `ACTIVE_HEALTHY`. فحص مباشر في هذه الجلسة عند `2026-10-23 11:25:19–11:25:56 UTC` أثبت سياسات SELECT الحالية على `runsheets` و`run_sheet_details` أنها مقيّدة بالشركة والصلاحية، وأثبت FK وحقول الوصف والصورة. Edge `start-loading` ACTIVE v5 و`complete-loading` ACTIVE v11، وكلاهما `verify_jwt=true`. لا يحتاج تعديل عرض Picker إلى أي تغيير في هذه الوظائف.
- **Current Understanding:** Loader الحالي SHA `97b83d68a683df77c1e0557838c24a1b4fb65169`، 332 سطرًا. Picker الحالي SHA `d483bd15b36585b975b63c2ef641481a01d5d084`، 1058 سطرًا. Loader يعرض ملخص الأصناف والكمية المحضّرة وبطاقات تفاصيل. Picker يعرض قائمة مختصرة، ولا يعرض إجمالي الكمية المطلوبة أو الوصف بشكل دائم، ويُدخل نصوصًا من قاعدة البيانات داخل HTML.
- **Execution Confidence:** مرتفع في تشخيص فرق المصدر وعلاقة قاعدة البيانات؛ لم يُنفّذ Browser E2E، ولم تُثبت مطابقة HTML الذي يخدمه Cloudflare مع Git.
- **Confirmed Facts:** SHA للملفين؛ حقول `items.description/image_url`؛ FK `run_sheet_details.item_id → items.id`؛ Production read policies؛ Edge versions/JWT.
- **Unknowns:** نسخة HTML الفعلية التي يخدمها Cloudflare بعد أي تعديل يطبقه المالك؛ نجاح اختبار المتصفح بعد النشر.
- **Conflicts:** تقرير Report467 السابق يقرأ `it.description` مباشرة رغم أن العمود غير موجود في `run_sheet_details`. هذا التعارض عولج في هذا التقرير.
- **Unverified Claims:** لا أدّعي أن patch طُبق أو نُشر أو اجتاز Browser E2E.

## 2. مصادر الحقيقة التي فُحصت في هذه الدورة

| المصدر | الدليل الحالي |
|---|---|
| Loader | `companies/company-1/warehouse/loader.html`, blob SHA `97b83d68a683df77c1e0557838c24a1b4fb65169` |
| أحدث تغيير معاينة Loader | commit `152e5b1d22aab94d2cf01070778b357df4701aff`, عنوانه `Refactor preview modal HTML generation` |
| Picker | `companies/company-1/warehouse/picker.html`, blob SHA `d483bd15b36585b975b63c2ef641481a01d5d084` |
| آخر commit معروض للـPicker | `eee31fe44d8fc1cee384ad66a8d7a36be2e3c1b7`, `Update picker.html` |
| Core | `companies/company-1/core.js`, SHA `ff2f581d9900543c16f7cb026e13446520c0329d` |
| Production Edge | `start-loading` v5 ACTIVE/JWT ON؛ `complete-loading` v11 ACTIVE/JWT ON، SHA الحزمة `c0ca692a29d14d64ec3729ae4bd12b9b84268e826ffc1c6993a48617b552b286` |
| Production SQL | `run_sheet_details_item_id_fkey` يربط التفاصيل بالأصناف؛ `items.description` موجود، و`run_sheet_details.description` غير موجود |
| Production RLS | `runsheets_select_company` يقيد الشركة والصلاحية؛ سياسة تفاصيل الرانشيت تتحقق من الرانشيت التابع للشركة والصلاحية |
| Runtime | لا توجد في هذه الدورة نتيجة Browser E2E أو إثبات SHA للـHTML المنشور |

ملاحظة Git: أداة جلب commit أعادت عنوان commit والملفات المتغيرة، لكنها لم تعرض حقل parent SHA؛ لذلك لا أختلق parent commit ولا أدّعي أنني تحققت منه. مصدر Git الحالي والـblob SHA أعلاه تم التحقق منهما مباشرة.

## 3. السبب الجذري

1. فرع المعاينة غير النشطة داخل `App.openRunsheet(code)` في Picker يبني عنوانًا وقائمة أصناف بسيطة، ويحقن الاسم والوحدة والكود والوصف داخل HTML وinline handler دون escaping موثوق.
2. لا يوجد ملخص لإجمالي الكمية المطلوبة ولا وصف دائم داخل البطاقة.
3. **نقص في Report467:** `run_sheet_details` لا يحتوي `description`; لذا قراءة `it.description` وحدها لن تضمن عرض الوصف. مصدره الصحيح جدول `items` عبر FK المثبت.
4. مساعد الصور الحالي `App._img(code)` يُدخل `image_url` مباشرة داخل خاصية `src`; التغيير الجديد سيستخدمه داخل بطاقات المعاينة، لذا ينبغي تقييد البروتوكول وهروب القيمة داخل الخاصية دون تغيير بنية التطبيق.

## 4. التعديل الجراحي رقم 1 — إحضار وصف الصنف من العلاقة الصحيحة

**الملف:** `companies/company-1/warehouse/picker.html`  
**الموضع:** `App.openRunsheet(code)`، استعلام `run_sheet_details` الموجود مباشرة بعد قراءة الرانشيت.  
**ابحث عن:**

```js
    .from('run_sheet_details')
    .select('*')
    .eq('runsheet_id', rs.id)
```

**استبدل الأسطر الثلاثة فقط بـ:**

```js
    .from('run_sheet_details')
    .select('*, items!run_sheet_details_item_id_fkey(description)')
    .eq('runsheet_id', rs.id)
```

**الأثر:** جلب الوصف من `items` عبر FK مثبت في Production، من دون إضافة جدول أو عمود أو تغيير RLS. يبقى فرع جلسة التحضير النشطة قادرًا على قراءة حقول التفاصيل نفسها.

## 5. التعديل الجراحي رقم 2 — معاينة Picker داخل الصفحة

**الدالة:** `App.openRunsheet(code)`  
**الموضع:** داخل `detRes.then(function(detRes){...})`، بعد فرع استعادة جلسة `Picking` النشطة مباشرة.  
**محدد البداية:** `var html = '';` الذي يسبق عنوان الرانشيت الحالي.  
**محدد النهاية:** `safeHTML(byId('mainContent'), html);` الذي ينهي بناء المعاينة المختصرة.  
استبدل هذا المقطع فقط، ولا تستبدل الدالة `openRunsheet` كاملة.

```js
                var html = '';
                var totalRequested = 0;

                function escHtml(value) {
                    return String(value == null ? '' : value)
                        .replace(/&/g, '&amp;')
                        .replace(/</g, '&lt;')
                        .replace(/>/g, '&gt;')
                        .replace(/"/g, '&quot;')
                        .replace(/'/g, '&#39;');
                }

                var canStart = rs.status === 'Open' || rs.status === 'Confirmed';
                html += '<div class="space-y-4 text-right slide-in">';
                html += '<div class="flex items-center gap-3 mb-5">';
                html += '<button type="button" id="pickerPreviewBack" class="w-10 h-10 bg-white rounded-2xl flex items-center justify-center text-indigo-600 shadow-sm" aria-label="العودة إلى قائمة الرانشيتات"><i class="fa-solid fa-arrow-right"></i></button>';
                html += '<div class="min-w-0 flex-1"><h2 class="font-black text-xl text-slate-800">معاينة الرانشيت</h2>';
                html += '<p class="text-xs text-slate-400 mt-1">راجع الأصناف والكميات والوصف قبل بدء التحضير</p></div></div>';

                html += '<div class="bg-indigo-50 rounded-3xl p-5 mb-5"><div class="flex items-start justify-between gap-3"><div>';
                html += '<p class="text-xs text-indigo-500 font-bold mb-1">رقم الرانشيت</p><h3 class="font-black text-2xl text-slate-800">' + escHtml(code) + '</h3>';
                html += '<p class="text-xs text-slate-500 mt-2">التاريخ: ' + escHtml(rs.run_date || '') + '</p></div>';
                html += '<span class="px-3 py-1 rounded-full bg-white text-indigo-600 text-xs font-bold">' + (rs.status === 'Confirmed' ? 'مؤكد' : 'مفتوح') + '</span></div></div>';

                html += '<div class="grid grid-cols-2 gap-3 mb-5">';
                html += '<div class="card"><p class="text-xs text-slate-400">عدد الأصناف</p><p class="font-black text-xl text-slate-800 mt-1">' + items.length + '</p></div>';
                html += '<div class="card"><p class="text-xs text-slate-400">إجمالي الكمية المطلوبة</p><p id="pickerPreviewTotalQty" class="font-black text-xl text-indigo-600 mt-1">0</p></div></div>';
                html += '<div class="flex items-center justify-between mb-3"><h3 class="font-black text-slate-800">أصناف الرانشيت</h3><span class="text-xs text-slate-400">تفاصيل التحضير</span></div>';

                if (!items.length) {
                    html += '<div class="card text-center py-10"><i class="fa-solid fa-box-open text-3xl text-slate-300 mb-3"></i><p class="font-bold text-slate-500">لا توجد أصناف في هذا الرانشيت.</p></div>';
                } else {
                    for (var k = 0; k < items.length; k++) {
                        var it = items[k] || {};
                        var requestedQty = Number(it.qty_ordered) || 0;
                        var itemDescription = (it.items && it.items.description) || '';
                        totalRequested += requestedQty;

                        html += '<button type="button" class="card w-full text-right mb-3 slide-in" data-picker-item-index="' + k + '">';
                        html += '<div class="flex items-start gap-3"><div class="shrink-0">' + self._img(it.item_code) + '</div>';
                        html += '<div class="min-w-0 flex-1"><p class="font-bold text-slate-800">' + escHtml(it.item_name || '') + '</p>';
                        html += '<p class="text-xs text-slate-400 mt-1">' + escHtml(it.item_code || '') + ' | ' + escHtml(it.unit || 'حبة') + '</p>';
                        html += '<div class="grid grid-cols-2 gap-2 mt-3 text-sm">';
                        html += '<div class="bg-indigo-50 rounded-xl p-2"><p class="text-[11px] text-slate-400">الكمية المطلوبة</p><p class="font-black text-indigo-700">' + requestedQty + '</p></div>';
                        html += '<div class="bg-slate-50 rounded-xl p-2"><p class="text-[11px] text-slate-400">الوصف</p><p class="font-semibold text-slate-700">' + escHtml(itemDescription || 'لا يوجد وصف مسجل') + '</p></div>';
                        html += '</div></div></div></button>';
                    }
                }

                if (canStart) {
                    html += '<div class="sticky-top pt-2 pb-3 bg-slate-50"><button type="button" id="pickerPreviewStart" class="btn-primary"><i class="fa-solid fa-play ml-2"></i> بدء التحضير</button>';
                    html += '<p class="text-center text-xs text-slate-400 mt-2">المعاينة لا تغيّر المخزون؛ يبدأ الحجز والتحضير بعد تأكيد البدء.</p></div>';
                }
                html += '</div>';

                safeHTML(byId('mainContent'), html);

                var totalQtyEl = byId('pickerPreviewTotalQty');
                if (totalQtyEl) totalQtyEl.textContent = String(totalRequested);

                var backButton = byId('pickerPreviewBack');
                if (backButton) backButton.addEventListener('click', function() {
                    self.renderPendingTab();
                });

                var startButton = byId('pickerPreviewStart');
                if (startButton) startButton.addEventListener('click', function() {
                    self.startPicking(code);
                });

                var previewCards = byId('mainContent').querySelectorAll('[data-picker-item-index]');
                for (var cardIndex = 0; cardIndex < previewCards.length; cardIndex++) {
                    previewCards[cardIndex].addEventListener('click', function() {
                        var itemIndex = Number(this.getAttribute('data-picker-item-index'));
                        var selectedItem = items[itemIndex];
                        if (!selectedItem) return;
                        self.showItemDetail(
                            selectedItem.item_code || '',
                            selectedItem.item_name || '',
                            selectedItem.unit || 'حبة',
                            Number(selectedItem.qty_ordered) || 0,
                            (selectedItem.items && selectedItem.items.description) || ''
                        );
                    });
                }
```

## 6. التعديل الجراحي رقم 3 — تأمين مصدر صورة الصنف

**الدالة:** `App._img(code)`  
**ابحث عن بداية الدالة الحالية:**

```js
    _img: function(code){
```

استبدل الدالة وحدها حتى الفاصلة التي تنهيها بالنص التالي:

```js
    _img: function(code){
        var url = ITEMS_IMAGE_CACHE[code] || '';
        var safeUrl = /^(https?:\\/\\/|\\/)/i.test(url) ? String(url)
            .replace(/&/g, '&amp;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;') : '';

        return safeUrl
            ? '<img src="' + safeUrl + '" alt="" class="w-14 h-14 rounded-2xl object-cover border-2 border-white shadow-sm" onerror="this.style.display=\\'none\\'">'
            : '<div class="w-14 h-14 bg-gradient-to-br from-slate-100 to-slate-200 rounded-2xl flex items-center justify-center text-slate-400"><i class="fa-solid fa-box"></i></div>';
    },
```

**الأثر:** تبقى الصور الآمنة HTTP(S) أو المسارات المطلقة فقط؛ تُعرض الصورة الافتراضية إذا كانت قيمة الرابط غير مقبولة. هذا تعديل مساعد عرض موجود، وليس تغييرًا في بيانات الصور أو المخزون.

## 7. التعديل الجراحي رقم 4 — هروب قيم مودال تفاصيل الصنف

**الدالة:** `App.showItemDetail(code, name, unit, qty, desc)`، قرب الأسطر 590–594.  
استبدل الدالة وحدها بهذا النص:

```js
    showItemDetail: function(code, name, unit, qty, desc){
        function escHtml(value) {
            return String(value == null ? '' : value)
                .replace(/&/g, '&amp;')
                .replace(/</g, '&lt;')
                .replace(/>/g, '&gt;')
                .replace(/"/g, '&quot;')
                .replace(/'/g, '&#39;');
        }

        var img = ITEMS_IMAGE_CACHE[code] || '';
        var safeImg = /^(https?:\\/\\/|\\/)/i.test(img) ? escHtml(img) : '';
        var imgHtml = safeImg
            ? '<img src="' + safeImg + '" alt="" class="w-full h-80 object-contain bg-white rounded-2xl mb-4 shadow-sm" onerror="this.style.display=\\'none\\'">'
            : '<div class="w-full h-80 bg-white rounded-2xl flex items-center justify-center text-slate-400 mb-4"><i class="fa-solid fa-box text-4xl"></i></div>';

        var safeQty = Number(qty);
        if (!isFinite(safeQty)) safeQty = 0;

        Swal.fire({
            html: '<div class="text-right">' + imgHtml +
                '<h3 class="font-black text-xl text-slate-800 mb-2">' + escHtml(name) + '</h3>' +
                '<div class="space-y-2 text-sm">' +
                '<div class="flex justify-between"><span class="text-slate-400">الكود</span><span class="font-bold text-slate-600">' + escHtml(code) + '</span></div>' +
                '<div class="flex justify-between"><span class="text-slate-400">الوحدة</span><span class="font-bold text-slate-600">' + escHtml(unit || 'حبة') + '</span></div>' +
                '<div class="flex justify-between"><span class="text-slate-400">الكمية المطلوبة</span><span class="font-bold text-indigo-600 text-lg">' + safeQty + '</span></div>' +
                '</div>' + (desc ? '<p class="text-sm text-slate-500 mt-3 pt-3 border-t border-slate-100">' + escHtml(desc) + '</p>' : '') +
                '</div>',
            width: 'min(92vw, 560px)',
            showCloseButton: true,
            showConfirmButton: false,
            customClass: { popup: '!rounded-3xl !p-5', closeButton: '!text-slate-300 !text-lg' }
        });
    },
```

## 8. الاختبارات المطلوبة بعد تطبيق المالك

1. افتح رانشيت `Open` وآخر `Confirmed`: تظهر المعاينة داخل الصفحة، التاريخ والحالة وعدد الأصناف وإجمالي الكمية المطلوبة.
2. تحقق أن الوصف يظهر من علاقة `items`، لا من عمود غير موجود في `run_sheet_details`.
3. تحقق أن الصورة والاسم والكود والوحدة والكمية والوصف تظهر لكل صنف، وأن نصًا يحوي `<script>` أو علامات اقتباس يعرض كنص.
4. زر الرجوع يعيد قائمة الرانشيتات ولا يبدأ التحضير.
5. زر بدء التحضير يظهر فقط لحالتي `Open` و`Confirmed` ويستدعي `startPicking(code)` الحالية.
6. الرانشيت الفارغ يعرض الحالة الفارغة ولا يرمي خطأ.
7. مسار جلسة `Picking` النشطة واستعادة Dexie يظلان كما هما.
8. اختبر هاتفًا/سطح مكتب وعدم وجود تمرير أفقي.
9. تحقق من الشركة والصلاحية؛ لا تعرض تفاصيل شركة أخرى.
10. تحقق من Network ونسخة HTML التي يقدمها Cloudflare بعد النشر، ثم قارن المخزون والحجوزات قبل/بعد المعاينة. يجب ألا يتغير أي منهما بمجرد فتح المعاينة.

## 9. Production / Scope

- لم تتغير قاعدة البيانات أو RLS أو RPC أو Edge Functions.
- `start-loading v5` و`complete-loading v11` ظلا كما هما؛ هذه المهمة تخص معاينة Picker فقط.
- لا حاجة إلى بيانات تجريبية في Production لتغيير عرضي. لا تنشئ طلبات أو تعدّل مخزونًا لاختبار المعاينة.
- سجلات الطلبات السابقة إلى `rawaea-erp.pages.dev` لا تثبت هوية HTML الحالي؛ لم يُثبت served-artifact parity في هذه الدورة.
- لا يمكن إعلان `100% CLOSED` قبل تطبيق المالك والتأكد من النشر واختبارات المتصفح.

## SELF-AUDIT FINAL

- **What I Proved:** فرق العرض بين Loader وPicker؛ حقول Production؛ FK الصحيح للوصف؛ RLS الحالية؛ نسخ Edge الحالية.
- **What I Did Not Prove:** تطبيق المالك للتغييرات، نشر Cloudflare، تطابق HTML المنشور، أو نجاح Browser E2E.
- **What I Fixed:** صححت خطة Report467 حتى لا تعتمد على `run_sheet_details.description` غير الموجود؛ أضفت علاقة الوصف المثبتة، وهروب HTML، والتحقق من روابط الصور.
- **What I Initially Missed:** Report467 السابق استخدم `it.description` مباشرة رغم غياب العمود من جدول التفاصيل.
- **What Could Still Be Wrong:** قد لا تكون نسخة Cloudflare هي blob الحالي؛ كما يجب التأكد بعد التطبيق أن علاقة PostgREST المسماة صراحةً تعمل من خلال schema cache في Production.
- **Final Confidence:** مرتفع في مطابقة المصدر وschema؛ غير مثبت في runtime.
- **Final Closure Status:** `OWNER SURGICAL PATCH READY / DEPLOYMENT + BROWSER E2E OPEN`.
