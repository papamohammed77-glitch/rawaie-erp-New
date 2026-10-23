# Report474 — إعادة تأسيس رقعة Picker بعد إعادة تصميم معاينة Loader

**التاريخ:** 2026-10-23  
**النطاق:** مطابقة معاينة الرانشيت وأصنافه بين Loader وPicker.  
**قاعدة الملكية:** لم أعدل loader.html أو picker.html أو main.html أو core.js. المالك وحده يدمج رقع التطبيقات التشغيلية.  
**النتيجة:** رقعة Report471 ما زالت صالحة كمرجع للعقد وحماية النصوص/الصور، لكن كتلة المعاينة Patch B أصبحت قديمة بصريًا بعد إعادة تصميم Loader في commit `152e5b1d22aab94d2cf01070778b357df4701aff`. استخدم Patch B الجديدة أدناه، ولا تلصق كتلة Report471 B كما هي.

## 1. الأدلة الحالية — لا تعتمد على تقارير سابقة

| الدليل | نتيجة التحقق الحالي |
|---|---|
| Loader الحالي | `erp-frontend/companies/company-1/warehouse/loader.html`, blob SHA `97b83d68a683df77c1e0557838c24a1b4fb65169`, 332 سطرًا |
| Picker الحالي | `erp-frontend/companies/company-1/warehouse/picker.html`, blob SHA `d483bd15b36585b975b63c2ef641481a01d5d084`, 1058 سطرًا |
| أحدث commit في سلسلة Loader | `152e5b1d22aab94d2cf01070778b357df4701aff`, “Refactor preview modal HTML generation” |
| Parent commit | `e69c9af4b56d99ba29a4fa74282f78438b9f7010` |
| Picker | لا يزال يستخدم معاينة مختصرة عند الأسطر 570–580، ولا يتضمن علاقة وصف الصنف في استعلام التفاصيل |
| Production SQL | `items.description` و`items.image_url` موجودان؛ `run_sheet_details.description` غير موجود؛ FK الخاص بـitem وFK الخاص بالrunsheet موجودان |
| حالة الرانشيت الحية وقت الفحص | `Picked: 2` فقط؛ لا توجد حالات Open/Confirmed في هذا الاستعلام |
| تغييرات Production | لا شيء |

### أثر الـcommit الأحدث

تم توسيع `App._showPreviewModal` في Loader من جدول مختصر إلى معاينة داخل الصفحة: رأس واضح، حالة، ملخص ثلاثي (عدد الأصناف/إجمالي الكمية/القيمة التقديرية)، بطاقات أصناف بصورها وأكوادها ووحداتها والكميات المطلوبة والمحضّرة والسعر والإجمالي، وزر رجوع وبدء تحميل مربوطان بأحداث DOM. لهذا السبب لا يجوز اعتبار كتلة Report471 B الحالية مطابقة تمامًا للتصميم الراهن.

## 2. السبب الجذري المؤكد

1. Picker ما زال يعرض قائمة مختصرة بدل بنية المعاينة الحديثة الموجودة في Loader.
2. `run_sheet_details` لا يحتوي `description`; مصدر الوصف الصحيح هو `items.description` عبر FK `run_sheet_details_item_id_fkey`.
3. بطاقة Picker الحالية تبني `onclick` inline من قيم قاعدة البيانات، كما أن `_img` و`showItemDetail` يدرجان قيمًا غير مهربة؛ هذه مخاطر حقن HTML وليست مجرد اختلاف بصري.
4. يجب أن تظل قواعد الملكية وحالة Picking واستعادة Dexie كما هي؛ الرقعة لا تستبدل الدالة `App.openRunsheet` كاملة ولا تغيّر دورة المخزون.

## 3. الرقع الجراحية المطلوبة

### Patch A — استعلام تفاصيل الرانشيت

**الملف:** `companies/company-1/warehouse/picker.html`  
**الدالة:** `App.openRunsheet(code)`  
**المحدد:** ابحث عن المقطع المطابق حرفيًا:

~~~js
    .from('run_sheet_details')
    .select('*')
    .eq('runsheet_id', rs.id)
~~~

**استبدل الأسطر الثلاثة فقط بـ:**

~~~js
    .from('run_sheet_details')
    .select('*, items!run_sheet_details_item_id_fkey(description)')
    .eq('runsheet_id', rs.id)
~~~

### Patch A2 — الوصف في جلسة Picking النشطة

داخل حلقة بناء `self.session.items`، ابحث عن:

~~~js
                            description: items[i].description || '',
~~~

**استبدل السطر فقط بـ:**

~~~js
                            description: (items[i].items && items[i].items.description) || '',
~~~

لا تعدل حلقة الجلسة أو منطق Dexie.

### Patch B — استبدال معاينة Picker المختصرة بواجهة متوافقة مع Loader الحالي

**الدالة:** `App.openRunsheet(code)`  
**الموقع الحالي في SHA أعلاه:** الأسطر 570–580.  
**المحدد الأول:** `var html = '';` الواقع بعد فرع `if(rs.status === 'Picking' && rs.picker_id === self.pubUserId)` و`return;`.  
**المحدد الأخير:** `safeHTML(byId('mainContent'), html);`

احذف **كتلة المعاينة هذه فقط** والصق البديل التالي. لا تحذف إغلاق `then` بعدها، ولا تستبدل `App.openRunsheet` كاملة.

~~~js
                var html = '';
                var totalRequested = 0;
                var totalPrepared = 0;
                var totalValue = 0;

                function escHtml(value) {
                    return String(value == null ? '' : value)
                        .replace(/&/g, '&amp;')
                        .replace(/</g, '&lt;')
                        .replace(/>/g, '&gt;')
                        .replace(/"/g, '&quot;')
                        .replace(/'/g, '&#39;');
                }

                var canStart = rs.status === 'Open' || rs.status === 'Confirmed';
                var previewStatusLabel =
                    rs.status === 'Picked' ? 'مكتمل التحضير' :
                    rs.status === 'Confirmed' ? 'مؤكد' :
                    rs.status === 'Open' ? 'مفتوح' :
                    rs.status === 'Picking' ? 'قيد التحضير' :
                    rs.status === 'Loading' ? 'قيد التحميل' :
                    rs.status === 'Loaded' ? 'تم التحميل' :
                    (rs.status || 'غير محدد');

                html += '<div class="space-y-4 text-right slide-in">';
                html += '<div class="flex items-center gap-3 mb-5">';
                html += '<button type="button" id="pickerPreviewBack" class="w-10 h-10 bg-white rounded-2xl flex items-center justify-center text-indigo-600 shadow-sm" aria-label="العودة إلى قائمة الرانشيتات"><i class="fa-solid fa-arrow-right"></i></button>';
                html += '<div class="min-w-0 flex-1"><h2 class="font-black text-xl text-slate-800">معاينة الرانشيت</h2>';
                html += '<p class="text-xs text-slate-400 mt-1">راجع الأصناف والكميات قبل بدء التحضير</p></div></div>';

                html += '<div class="bg-indigo-50 rounded-3xl p-5 mb-5">';
                html += '<div class="flex items-start justify-between gap-3"><div><p class="text-xs text-indigo-500 font-bold mb-1">رقم الرانشيت</p>';
                html += '<h3 class="font-black text-2xl text-slate-800">' + escHtml(code) + '</h3>';
                html += '<p class="text-xs text-slate-500 mt-2">التاريخ: ' + escHtml(rs.run_date || '') + '</p></div>';
                html += '<span class="px-3 py-1 rounded-full bg-white text-indigo-600 text-xs font-bold">' + escHtml(previewStatusLabel) + '</span></div></div>';

                html += '<div class="grid grid-cols-1 sm:grid-cols-3 gap-3 mb-5">';
                html += '<div class="card"><p class="text-xs text-slate-400">عدد الأصناف</p><p class="font-black text-xl text-slate-800 mt-1">' + items.length + '</p></div>';
                html += '<div class="card"><p class="text-xs text-slate-400">إجمالي الكمية المطلوبة</p><p id="pickerPreviewTotalQty" class="font-black text-xl text-slate-800 mt-1">0</p></div>';
                html += '<div class="card"><p class="text-xs text-slate-400">القيمة التقديرية للكميات المطلوبة</p><p id="pickerPreviewTotalValue" class="font-black text-xl text-indigo-600 mt-1">0</p><p class="text-[11px] text-slate-400 mt-1">جنيه مصري</p></div>';
                html += '</div>';

                html += '<div class="flex items-center justify-between mb-3"><h3 class="font-black text-slate-800">أصناف الرانشيت</h3><span class="text-xs text-slate-400">تفاصيل التحضير</span></div>';

                if (!items.length) {
                    html += '<div class="card text-center py-10"><i class="fa-solid fa-box-open text-3xl text-slate-300 mb-3"></i><p class="font-bold text-slate-500">لا توجد أصناف في هذا الرانشيت.</p></div>';
                } else {
                    for (var k = 0; k < items.length; k++) {
                        var it = items[k] || {};
                        var requestedQty = Number(it.qty_ordered) || 0;
                        var preparedQty = Number(it.qty_picked) || 0;
                        var unitPrice = Number(it.unit_price) || 0;
                        var lineValue = requestedQty * unitPrice;
                        totalRequested += requestedQty;
                        totalPrepared += preparedQty;
                        totalValue += lineValue;

                        html += '<button type="button" class="card w-full text-right mb-3 slide-in" data-picker-item-index="' + k + '">';
                        html += '<div class="flex items-start gap-3"><div class="shrink-0">' + self._img(it.item_code) + '</div>';
                        html += '<div class="min-w-0 flex-1"><p class="font-bold text-slate-800">' + escHtml(it.item_name || '') + '</p>';
                        html += '<p class="text-xs text-slate-400 mt-1">' + escHtml(it.item_code || '') + ' | ' + escHtml(it.unit || 'حبة') + '</p>';
                        html += '<div class="grid grid-cols-2 sm:grid-cols-4 gap-2 mt-3 text-sm">';
                        html += '<div class="bg-slate-50 rounded-xl p-2"><p class="text-[11px] text-slate-400">مطلوب</p><p class="font-bold">' + escHtml(requestedQty) + '</p></div>';
                        html += '<div class="bg-indigo-50 rounded-xl p-2"><p class="text-[11px] text-slate-400">محضّر</p><p class="font-black text-indigo-700">' + escHtml(preparedQty) + '</p></div>';
                        html += '<div class="bg-slate-50 rounded-xl p-2"><p class="text-[11px] text-slate-400">سعر الوحدة</p><p class="font-bold">' + escHtml(RW_UI.formatNumber(unitPrice)) + '</p></div>';
                        html += '<div class="bg-indigo-50 rounded-xl p-2"><p class="text-[11px] text-slate-400">القيمة المطلوبة</p><p class="font-black text-indigo-700">' + escHtml(RW_UI.formatNumber(lineValue)) + '</p></div>';
                        html += '</div></div></div></button>';
                    }
                }

                if (canStart) {
                    html += '<div class="sticky-top pt-2 pb-3 bg-slate-50">';
                    html += '<button type="button" id="pickerPreviewStart" class="btn-primary"><i class="fa-solid fa-play ml-2"></i> بدء التحضير</button>';
                    html += '<p class="text-center text-xs text-slate-400 mt-2">المعاينة لا تغيّر المخزون؛ يبدأ الحجز والتحضير بعد تأكيد البدء.</p></div>';
                } else if (rs.status === 'Picked') {
                    html += '<div class="card text-center text-sm text-emerald-700 bg-emerald-50">اكتمل التحضير. هذه معاينة للقراءة فقط.</div>';
                }
                html += '</div>';

                safeHTML(byId('mainContent'), html);

                var totalQtyEl = byId('pickerPreviewTotalQty');
                if (totalQtyEl) totalQtyEl.textContent = RW_UI.formatNumber(totalRequested);

                var totalValueEl = byId('pickerPreviewTotalValue');
                if (totalValueEl) totalValueEl.textContent = RW_UI.formatNumber(totalValue);

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
~~~

**ملاحظة عقدية:** قيمة الملخص في Loader هي القيمة المحضّرة؛ في Picker تعرض الرقعة قيمة الكمية المطلوبة (requestedQty × unit_price) لأن الشاشة تمثل مرحلة التحضير. لا تغيّر أي كمية ولا تنشئ حركة مخزون عند فتح المعاينة. القيمة تقديرية للعرض فقط وليست قيدًا محاسبيًا.

### Patch C — حماية رابط الصورة في بطاقة الصنف

استبدل دالة `App._img(code)` وحدها بالنص التالي (النسخة الكاملة موجودة أيضًا في Report471):

~~~js
    _img: function(code){
        var rawUrl = String(ITEMS_IMAGE_CACHE[code] || '').trim();
        var safeUrl = /^(https?:\/\/|\/(?!\/))/i.test(rawUrl) ? rawUrl
            .replace(/&/g, '&amp;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;') : '';

        return safeUrl
            ? '<img src="' + safeUrl + '" alt="" class="w-14 h-14 rounded-2xl object-cover border-2 border-white shadow-sm" onerror="this.style.display=\'none\'">'
            : '<div class="w-14 h-14 bg-gradient-to-br from-slate-100 to-slate-200 rounded-2xl flex items-center justify-center text-slate-400"><i class="fa-solid fa-box"></i></div>';
    },
~~~

### Patch D — تأمين مودال تفاصيل الصنف

استبدل `App.showItemDetail(code, name, unit, qty, desc)` وحدها بالنص الكامل الموجود في Report471، القسم Patch D. هذه الرقعة تهرّب الاسم والكود والوحدة والوصف وتتحقق من رابط الصورة والكمية. لا تستبدل بقية كائن App.

## 4. ما لا يتغير

- لا تلمس `loader.html` أو `main.html` أو `core.js`.
- لا تغيّر قواعد ملكية الرانشيت، أو صلاحيات الشركة، أو حالات Picking، أو استعادة Dexie.
- لا تضف RPC أو Edge Function أو جدولًا أو RLS؛ هذه فجوة عرض ومصدر قراءة.
- لا تعدل المخزون أو `allocated_qty` أو حركات المخزون.
- لا تنشئ أو تحذف بيانات أعمال في Production.
- لا تطبق أي رقعة قبل إعادة جلب Picker والتحقق من SHA الحالي. إذا تغيرت البصمة، أعد تحديد المحددات.

## 5. الاختبارات المطلوبة بعد تطبيق المالك

1. Syntax/parse لملف Picker كاملًا دون أخطاء.
2. Open وConfirmed في Staging: الرأس، التاريخ، الحالة، عدد الأصناف، إجمالي الكمية والقيمة المطلوبة، الصور والبطاقات.
3. Picked: حالة «مكتمل التحضير»، لا يظهر زر بدء التحضير، وتبقى المعاينة للقراءة فقط.
4. بدء التحضير لا يظهر إلا لـOpen/Confirmed ويستدعي `startPicking(code)` مرة واحدة.
5. اختبار الوصف عبر FK، ونصوص HTML والاقتباسات، وروابط الصور HTTP(S)/المسار المحلي مقابل `//host` و`javascript:`.
6. الرانشيت الفارغ، Back، الجلسة النشطة، واستعادة Dexie.
7. اختبار مستخدم مصرح وغير مصرح وعزل الشركة.
8. اختبار هاتف وسطح مكتب، Console/Network، وعدم وجود تمرير أفقي.
9. مقارنة المخزون والحجوزات قبل وبعد فتح المعاينة؛ يجب ألا يتغيرا.
10. تحقق Cloudflare served HTML وBrowser E2E. لا تعتبر المهمة مغلقة قبل هذا الدليل.

## 6. Production وبيانات الاختبار

فحص Production SQL كان قراءة فقط. لا توجد حاجة مثبتة إلى تعديل schema/RLS/RPC/Edge. لم تُنشأ fixtures ولم تُحذف بيانات. حالات Open/Confirmed غير موجودة في العد الحي الحالي؛ اختبرهما في Staging أو بيئة معزولة.

## SELF-AUDIT

- **CONFIRMED:** SHAs الحالية، commit Loader الأحدث وparent، الفرق البنيوي في المعاينة، أعمدة وصف الصنف وعلاقات FK، وعدّ حالات الرانشيت الحي.
- **UNKNOWN:** مطابقة Cloudflare served HTML مع Git.
- **UNVERIFIED:** تطبيق المالك، النشر، Browser E2E، وسلوك Open/Confirmed في المتصفح.
- **CONFLICT RESOLVED:** كتلة Report471 B لم تعد مطابقة تمامًا لتصميم Loader بعد commit `152e5b1`. Patch B في هذا التقرير يحل محلها؛ لا تُعدّل Loader لتوافق تقريرًا أقدم.
- **PRODUCTION CHANGE:** لا شيء.
- **CLOSURE:** `OWNER PATCH READY / CURRENT SOURCE + DB CONTRACT VERIFIED / DEPLOYMENT + BROWSER E2E OPEN / NOT CLOSED`.

## نقطة الاستئناف الدقيقة للمساعد القادم

1. ابدأ بقراءة `CURRENT_STATE.md` و`LAST VERIFIED EVENT` ثم هذا التقرير.
2. أعد جلب Loader وPicker من GitHub وتحقق من SHA وparent commits.
3. إذا بقي Picker على SHA `d483bd15b36585b975b63c2ef641481a01d5d084`، طبّق A/A2/B/C/D فقط. إذا تغير، أعد بناء المحددات من المصدر الجديد.
4. بعد دمج المالك، تحقق من HTML المنشور في Cloudflare ثم Browser E2E قبل الإغلاق.
5. لا تغيّر Production ولا تلمس Loader أو main.html لهذه الفجوة ما لم يظهر دليل جديد يثبت ضرورة مستقلة.


## Addendum — Patch D complete replacement (authoritative)

The following complete block replaces `App.showItemDetail(code, name, unit, qty, desc)` only. It supersedes the short pointer in section 3 above.

~~~js
    showItemDetail: function(code, name, unit, qty, desc){
        function escHtml(value) {
            return String(value == null ? '' : value)
                .replace(/&/g, '&amp;')
                .replace(/</g, '&lt;')
                .replace(/>/g, '&gt;')
                .replace(/"/g, '&quot;')
                .replace(/'/g, '&#39;');
        }

        var rawImg = String(ITEMS_IMAGE_CACHE[code] || '').trim();
        var safeImg = /^(https?:\\/\\/|\\/(?!\\/))/i.test(rawImg) ? escHtml(rawImg) : '';
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
~~~
