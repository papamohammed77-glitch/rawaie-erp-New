# Report482 — استكمال التكامل الوظيفي والبصري بين معاينة الرانشيت في Loader وPicker

**التاريخ:** 2026-10-23  
**المستودع التشغيلي:** papamohammed77-glitch/erp-frontend — الفرع main  
**الملف المستهدف:** companies/company-1/warehouse/loader.html فقط  
**الملفات غير المستهدفة:** main.html، core.js، picker.html  
**الحالة:** CURRENT SOURCE VERIFIED / FULL PREVIEW-AND-ITEM-DETAIL GAP IDENTIFIED / CONSOLIDATED OWNER PATCH READY / NOT APPLIED / NOT DEPLOYED

## 1. القرار التنفيذي

المطلوب ليس إصلاح حدث النقر على بطاقة الرانشيت فقط. المقارنة تشمل دورة الاستخدام كاملة: فتح الرانشيت داخل مساحة التطبيق، عرض صفحة تفاصيله مع العودة للقائمة، الضغط على صنف وفتح مودال مستقل، عرض صورة كبيرة وبيانات الصنف، والحفاظ على وظائف التحميل الحالية.

لا يُعاد بناء الملف ولا يُستبدل التطبيق. هذه رقعة جراحية داخل Loader، لا تنسخ Picker بالكامل ولا تمسح ملخص Loader أو زر بدء التحميل.

## 2. الأدلة المعاد جلبها من المصدر الحالي

| المصدر | الدليل |
|---|---|
| Loader | companies/company-1/warehouse/loader.html; SHA 97b83d68a683df77c1e0557838c24a1b4fb65169; 332 سطرًا |
| Picker | companies/company-1/warehouse/picker.html; SHA d483bd15b36585b975b63c2ef641481a01d5d084; 1,058 سطرًا |
| Core | companies/company-1/core.js; SHA ff2f581d9900543c16f7cb026e13446520c0329d |
| App HEAD | 152e5b1d22aab94d2cf01070778b357df4701aff; parent e69c9af4b56d99ba29a4fa74282f78438b9f7010 |

### ما هو موجود بالفعل في Loader ويجب الحفاظ عليه

- بطاقة الرانشيت ونتيجة البحث تستدعيان App.openRunsheet(code).
- حالة Picked تفتح المعاينة داخل mainContent، لا داخل SweetAlert منفصل.
- المعاينة الحالية تعرض ملخص الرانشيت وعدد الأصناف وإجمالي الكمية المحضّرة والقيمة التقديرية وزر بدء التحميل.
- حالة Loading المسندة إلى المستخدم الحالي تفتح جلسة التحميل الفعلية وتوفر تحرير الكمية وإنهاء التحميل.

هذه الوظائف موجودة في Git الحالي. لا يصح الادعاء بأن النقر على بطاقة الرانشيت غير موجود في المصدر. فجوة التكامل الأهم هي اختلاف تجربة عرض التفاصيل، وعدم وجود مودال للصنف في معاينة Loader، ونقص بيانات الصور والوصف داخل جلسة التحميل.

### الفرق الوظيفي والبصري المثبت

1. Picker يعرض إرشادًا واضحًا للضغط على الصنف ثم يفتح مودال تفاصيل مستقلًا. بطاقات أصناف معاينة Loader الحالية ليست قابلة للنقر ولا تفتح مودالًا.
2. مودال تفاصيل Picker للمعاينة يعرض صورة كبيرة بارتفاع h-80 واسم الصنف وكوده ووحدته والكمية المطلوبة والوصف.
3. مودال تحرير الصنف في جلسة Picker يستخدم صورة كبيرة بارتفاع h-72 ويحتفظ بوظيفة تحرير الكمية. مقابل ذلك، مودال تحرير Loader الحالي يستخدم صورة صغيرة w-20 h-20 ولا يعرض كود الصنف أو وصفه.
4. استعلام تفاصيل Loader الحالي يستخدم select('*') من run_sheet_details، مع أن هذا الجدول لا يحتوي description أو image_url.
5. استعلامات قائمة/بحث/فتح Loader لا تضيف company_id صراحةً، بينما Picker يقيّدها بالشركة. كما أن بحث Loader قد يعرض رانشيت Loading لمحمّل آخر، ومسار الفتح الحالي يعرضه للقراءة بدل رفض ملكية الجلسة.

## 3. إثبات عقد قاعدة البيانات مباشرة من Production

أُجريت استعلامات SQL قراءة فقط على مشروع SMART ERP / fiilmooggumokxanwiyx. لم يُنفذ DDL أو تعديل بيانات.

- public.items يحتوي description وimage_url.
- public.run_sheet_details لا يحتوي description أو image_url، لكنه يحتوي item_id وitem_code وitem_name وunit وunit_price وqty_ordered وqty_picked وqty_loaded.
- المفتاح الخارجي run_sheet_details_item_id_fkey يربط run_sheet_details.item_id بـ items.id.
- المفتاح الخارجي run_sheet_details_runsheet_id_fkey يربط run_sheet_details.runsheet_id بـ runsheets.id.
- runsheets يحتوي company_id وstatus وloader_id وrunsheet_code.

إذن شكل الاستعلام الصحيح لبيانات الصورة والوصف هو:

~~~js
.select('*, items!run_sheet_details_item_id_fkey(description, image_url)')
~~~

لا حاجة إلى عمود أو علاقة أو Edge Function أو RPC جديدة لهذه الوظيفة العرضية.

## 4. التعديل الجراحي A — نطاق الشركة في قوائم Loader

### A1. قائمة الرانشيتات

**الموضع:** App.renderPendingTab() داخل Promise.all.

استبدل سطري الاستعلام الحاليين:

~~~js
supabase.from('runsheets').select('runsheet_code, status, run_date, loader_id, run_sheet_details(count)').eq('status','Loading').eq('loader_id',this.currentUser.id||this.currentUser.email).order('run_date',{ascending:false}).limit(20),
supabase.from('runsheets').select('runsheet_code, status, run_date, run_sheet_details(count)').eq('status','Picked').order('run_date',{ascending:false}).limit(50)
~~~

بهذين السطرين:

~~~js
supabase.from('runsheets').select('runsheet_code, status, run_date, loader_id, run_sheet_details(count)').eq('company_id',this.currentUser.company_id).eq('status','Loading').eq('loader_id',this.currentUser.id||this.currentUser.email).order('run_date',{ascending:false}).limit(20),
supabase.from('runsheets').select('runsheet_code, status, run_date, run_sheet_details(count)').eq('company_id',this.currentUser.company_id).eq('status','Picked').order('run_date',{ascending:false}).limit(50)
~~~

لا تغيّر حالات الرانشيت أو ترتيبها أو حدود النتائج.

### A2. البحث

**الموضع:** App.onSearchInput(q)، سطر استعلام البحث داخل setTimeout.

استبدل المقطع:

~~~js
supabase.from('runsheets').select('runsheet_code,status,run_date,loader_id,run_sheet_details(count)').or('status.eq.Picked,status.eq.Loading').ilike('runsheet_code','%'+q.trim()+'%').limit(10).then(function(r) { s.searchResults=r.data||[]; s.renderSearchDropdown(); });
~~~

بهذا المقطع:

~~~js
supabase.from('runsheets').select('runsheet_code,status,run_date,loader_id,run_sheet_details(count)').eq('company_id',s.currentUser.company_id).or('status.eq.Picked,status.eq.Loading').ilike('runsheet_code','%'+q.trim()+'%').limit(10).then(function(r) {
    if (r.error) {
        console.error('Loader runsheet search error:', r.error);
        s.searchResults = [];
        s.renderSearchDropdown();
        return;
    }
    s.searchResults = r.data || [];
    s.renderSearchDropdown();
});
~~~

## 5. التعديل الجراحي B — استبدال App.openRunsheet(code) وحدها

**محدد البحث:** openRunsheet: function(code) {  
**نهاية الاستبدال:** الفاصلة التي تنهي هذه الدالة، قبل _startSession: function(code, rs, items) {.

استبدل الدالة وحدها بالنص التالي:

~~~js
openRunsheet: function(code) {
    var self = this;
    var dropdown = RW_UI.byId('searchDropdown');
    if (dropdown) dropdown.classList.add('hidden');

    if (!self.currentUser || !self.currentUser.company_id) {
        RW_UI.toast('تعذر تحديد الشركة المرتبطة بالمستخدم', 'error');
        return;
    }

    RW_UI.showSkeleton('mainContent', 3, 'card');

    supabase.from('runsheets')
        .select('*')
        .eq('company_id', self.currentUser.company_id)
        .eq('runsheet_code', code)
        .maybeSingle()
        .then(function(rsRes) {
            if (rsRes.error) {
                console.error('Loader runsheet read error:', rsRes.error);
                RW_UI.toast('تعذر قراءة الرانشيت. تحقق من الاتصال والصلاحيات.', 'error');
                self.renderPendingTab();
                return;
            }

            if (!rsRes.data) {
                RW_UI.toast('الرانشيت غير موجود أو لا يتبع الشركة الحالية', 'error');
                self.renderPendingTab();
                return;
            }

            var rs = rsRes.data;
            var isActive = (
                rs.status === 'Loading' &&
                (rs.loader_id === self.currentUser.id ||
                 rs.loader_id === self.currentUser.email)
            );

            if (rs.status === 'Loading' && !isActive) {
                RW_UI.toast('الرانشيت قيد التحميل بواسطة موظف آخر', 'warning');
                self.renderPendingTab();
                return;
            }

            supabase.from('run_sheet_details')
                .select('*, items!run_sheet_details_item_id_fkey(description, image_url)')
                .eq('runsheet_id', rs.id)
                .then(function(detRes) {
                    if (detRes.error) {
                        console.error('Loader runsheet details read error:', detRes.error);
                        RW_UI.toast('تعذر تحميل أصناف الرانشيت.', 'error');
                        self.renderPendingTab();
                        return;
                    }

                    var items = detRes.data || [];

                    if (isActive) {
                        self._startSession(code, rs, items);
                        return;
                    }

                    if (rs.status === 'Picked') {
                        self._showPreviewModal(code, rs, items);
                        return;
                    }

                    self._renderReadonly(code, items);
                });
        })
        .catch(function(err) {
            console.error('Loader openRunsheet error:', err);
            RW_UI.toast('حدث خطأ أثناء فتح الرانشيت', 'error');
            self.renderPendingTab();
        });
},
~~~

يظل فتح الرانشيت داخل mainContent، ولا يبدأ التحميل أو يغير المخزون. يرفض التعديل فتح جلسة Loading مسندة إلى محمّل آخر.

## 6. التعديل الجراحي C — بيانات الصورة والوصف في جلسة التحميل

**الموضع:** App._startSession(code, rs, items). استبدل هذه الدالة وحدها:

~~~js
_startSession: function(code, rs, items) {
    this.session = { runsheet_code:code, runsheet_id:rs.id, start_time:rs.loader_start||new Date().toISOString(), items:[] };
    for (var i = 0; i < items.length; i++) {
        var it = items[i];
        var product = it.items || {};
        this.session.items.push({
            item_code: it.item_code,
            item_name: it.item_name || product.name || '',
            unit: it.unit || product.unit || 'حبة',
            description: product.description || '',
            image_url: product.image_url || RW_ImageCache.getImageUrl(it.item_code) || '',
            unit_price: Number(it.unit_price) || 0,
            qty_ordered: Number(it.qty_ordered) || 0,
            qty_picked: Number(it.qty_picked) || 0,
            qty_loaded: Number(it.qty_loaded) || 0,
            notes: it.notes || ''
        });
    }
    this.renderActiveSession();
},
~~~

هذا يضيف خصائص العرض إلى كائن الجلسة، ولا يغير مسار بدء/إتمام التحميل.

## 7. التعديل الجراحي D — بطاقات أصناف المعاينة وحدث النقر

### D1. إرشاد المستخدم

داخل App._showPreviewModal(code, rs, items)، بعد عنوان «أصناف الرانشيت» وقبل شرط if (!items.length)، أضف:

~~~js
h += '<p class="text-sm text-slate-400 mb-3">اضغط على الصنف لعرض صورته وتفاصيله</p>';
~~~

### D2. جعل بطاقة الصنف قابلة للتفاعل

ابحث داخل حلقة for عن السطر:

~~~js
h += '<div class="card mb-3"><div class="flex items-start gap-3">';
~~~

واستبدله بـ:

~~~js
h += '<div class="card mb-3 cursor-pointer loader-preview-item hover:shadow-md transition-all focus:outline-none focus:ring-2 focus:ring-orange-300" role="button" tabindex="0" data-loader-item-index="' + i + '"><div class="flex items-start gap-3">';
~~~

لا تغيّر محتويات البطاقة ولا طريقة حساب الإجماليات.

### D3. تسجيل أحداث النقر ولوحة المفاتيح

داخل الدالة نفسها، مباشرة بعد السطر:

~~~js
RW_UI.safeHTML(RW_UI.byId('mainContent'), h);
~~~

أضف:

~~~js
var previewRoot = RW_UI.byId('mainContent');
if (previewRoot) {
    var itemCards = previewRoot.querySelectorAll('.loader-preview-item');
    for (var ci = 0; ci < itemCards.length; ci++) {
        (function(card) {
            function openItemDetails() {
                var idx = Number(card.getAttribute('data-loader-item-index'));
                if (items[idx]) self._showItemDetail(items[idx]);
            }

            card.addEventListener('click', openItemDetails);
            card.addEventListener('keydown', function(e) {
                if (e.key === 'Enter' || e.key === ' ' ||
                    e.keyCode === 13 || e.keyCode === 32) {
                    e.preventDefault();
                    openItemDetails();
                }
            });
        })(itemCards[ci]);
    }
}
~~~

يظل حساب الملخص وربط زر الرجوع وزر بدء التحميل كما هو بعد هذا المقطع.

## 8. التعديل الجراحي E — مودال تفاصيل الصنف بالصورة الكبيرة

أضف الدالة التالية داخل كائن App مباشرة بعد _showPreviewModal(...) وقبل _startLoadingFromPreview: function(code) {. لا تستبدل الدالتين المجاورتين.

~~~js
_showItemDetail: function(item) {
    if (!item) return;

    function esc(value) {
        return String(value == null ? '' : value)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    var product = item.items || {};
    var name = item.item_name || product.name || '';
    var code = item.item_code || product.item_code || '';
    var unit = item.unit || product.unit || 'حبة';
    var description = product.description || item.description || '';
    var rawImageUrl = String(
        product.image_url || item.image_url ||
        RW_ImageCache.getImageUrl(code) || ''
    );

    var imageUrl = '';
    if (/^https?:\/\/[^\s"'<>]+$/i.test(rawImageUrl) ||
        /^\/(?!\/)[^\s"'<>]*$/.test(rawImageUrl)) {
        imageUrl = rawImageUrl;
    }

    var requestedQty = Number(item.qty_ordered) || 0;
    var pickedQty = Number(item.qty_picked) || 0;
    var unitPrice = Number(item.unit_price) || 0;
    var lineValue = pickedQty * unitPrice;

    var imageHtml = '';
    if (imageUrl) {
        imageHtml += '<img id="loaderItemDetailImage" src="' + esc(imageUrl) +
            '" alt="' + esc(name) +
            '" class="w-full h-80 rounded-2xl object-contain bg-white mx-auto shadow-sm mb-3">';
    }
    imageHtml += '<div id="loaderItemDetailImageFallback" class="' +
        (imageUrl ? 'hidden ' : '') +
        'w-full h-80 rounded-2xl bg-white mx-auto flex items-center justify-center text-slate-400 mb-3">' +
        '<i class="fa-solid fa-box text-4xl"></i></div>';

    var descriptionHtml = description
        ? '<p class="text-sm text-slate-500 mt-3 pt-3 border-t border-slate-100 text-right">' +
            esc(description) + '</p>'
        : '';

    var html = '<div class="text-center mb-4">' + imageHtml + '</div>';
    html += '<div class="text-right">';
    html += '<h3 class="font-black text-xl text-slate-800 mb-3">' + esc(name) + '</h3>';
    html += '<div class="text-sm space-y-2">';
    html += '<div class="flex justify-between gap-3"><span class="text-slate-400">الكود</span><strong class="text-slate-700">' + esc(code) + '</strong></div>';
    html += '<div class="flex justify-between gap-3"><span class="text-slate-400">الوحدة</span><strong class="text-slate-700">' + esc(unit) + '</strong></div>';
    html += '<div class="flex justify-between gap-3"><span class="text-slate-400">الكمية المطلوبة</span><strong class="text-slate-700">' + esc(RW_UI.formatNumber(requestedQty)) + '</strong></div>';
    html += '<div class="flex justify-between gap-3"><span class="text-slate-400">الكمية المحضّرة</span><strong class="text-blue-700">' + esc(RW_UI.formatNumber(pickedQty)) + '</strong></div>';
    html += '<div class="flex justify-between gap-3"><span class="text-slate-400">سعر الوحدة</span><strong class="text-slate-700">' + esc(RW_UI.formatNumber(unitPrice)) + '</strong></div>';
    html += '<div class="flex justify-between gap-3"><span class="text-slate-400">القيمة التقديرية للمحضّر</span><strong class="text-orange-700">' + esc(RW_UI.formatNumber(lineValue)) + ' جنيه</strong></div>';
    html += '</div>' + descriptionHtml + '</div>';

    Swal.fire({
        title: '<span class="text-slate-800">' + esc(name) + '</span>',
        html: html,
        width: 'min(92vw, 560px)',
        showCloseButton: true,
        showConfirmButton: false,
        customClass: {
            popup: '!rounded-3xl !p-5',
            closeButton: '!text-slate-300 !text-lg'
        },
        didOpen: function() {
            var popup = Swal.getPopup();
            var image = popup ? popup.querySelector('#loaderItemDetailImage') : null;
            var fallback = popup ? popup.querySelector('#loaderItemDetailImageFallback') : null;
            if (image) {
                image.addEventListener('error', function() {
                    image.classList.add('hidden');
                    if (fallback) fallback.classList.remove('hidden');
                });
            }
        }
    });
},
~~~

يستخدم المودال صورة h-80 بعرض min(92vw, 560px)، مثل مودال تفاصيل Picker. ويعرض الاسم والكود والوحدة والكمية المطلوبة والمحضّرة والسعر والقيمة التقديرية والوصف. تُهرّب القيم النصية وتُقبل عناوين صور HTTP/HTTPS أو المسارات المحلية الجذرية فقط. فتح المودال لا يغير بيانات المخزون.

## 9. التعديل الجراحي F — تكبير الصورة وإظهار تفاصيل الصنف في مودال تحرير التحميل

في جلسة Loading، يجب أن يظل الضغط على بطاقة الصنف يفتح مودال تحرير الكمية المحمّلة. لا تستبدل ذلك بمودال قراءة فقط. المطلوب تكبير الصورة وإظهار الكود والوصف مع الحفاظ على إدخال الكمية والملاحظات والحفظ والتحذيرات.

**محدد البحث:** editLoadedItem: function(idx, pre) {  
**نهاية الاستبدال:** الفاصلة التي تنهي الدالة قبل completeLoading: function() {.

استبدل الدالة وحدها:

~~~js
editLoadedItem: function(idx, pre) {
    var s = this;
    var it = s.session && s.session.items ? s.session.items[idx] : null;
    if (!it) return;

    var cur = (typeof pre !== 'undefined') ? pre : it.qty_loaded;

    function esc(value) {
        return String(value == null ? '' : value)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    var rawImageUrl = String(it.image_url || RW_ImageCache.getImageUrl(it.item_code) || '');
    var imageUrl = '';
    if (/^https?:\/\/[^\s"'<>]+$/i.test(rawImageUrl) ||
        /^\/(?!\/)[^\s"'<>]*$/.test(rawImageUrl)) {
        imageUrl = rawImageUrl;
    }

    var imageHtml = '';
    if (imageUrl) {
        imageHtml += '<img id="loaderLoadedItemImage" src="' + esc(imageUrl) +
            '" alt="' + esc(it.item_name || '') +
            '" class="w-full max-w-xs h-72 rounded-2xl object-contain bg-white mx-auto shadow-sm mb-3">';
    }
    imageHtml += '<div id="loaderLoadedItemImageFallback" class="' +
        (imageUrl ? 'hidden ' : '') +
        'w-full max-w-xs h-72 rounded-2xl bg-white mx-auto flex items-center justify-center text-slate-400 mb-3">' +
        '<i class="fa-solid fa-box text-4xl"></i></div>';

    var detailsHtml = '<div class="text-right text-sm space-y-2">';
    detailsHtml += '<div class="flex justify-between gap-3"><span class="text-slate-400">الكود</span><strong>' + esc(it.item_code || '') + '</strong></div>';
    detailsHtml += '<div class="flex justify-between gap-3"><span class="text-slate-400">محضّر</span><strong>' + esc(RW_UI.formatNumber(it.qty_picked)) + '</strong></div>';
    detailsHtml += '<div class="flex justify-between gap-3"><span class="text-slate-400">مطلوب</span><strong>' + esc(RW_UI.formatNumber(it.qty_ordered)) + '</strong></div>';
    if (it.unit) {
        detailsHtml += '<div class="flex justify-between gap-3"><span class="text-slate-400">الوحدة</span><strong>' + esc(it.unit) + '</strong></div>';
    }
    if (Number(it.unit_price) > 0) {
        detailsHtml += '<div class="flex justify-between gap-3"><span class="text-slate-400">سعر الوحدة</span><strong>' + esc(RW_UI.formatNumber(it.unit_price)) + '</strong></div>';
    }
    detailsHtml += '</div>';

    var descriptionHtml = it.description
        ? '<p class="text-sm text-slate-500 mt-3 pt-3 border-t border-slate-100 text-right">' + esc(it.description) + '</p>'
        : '';

    Swal.fire({
        title: '<span class="text-slate-800">' + esc(it.item_name || '') + '</span>',
        width: 'min(92vw, 560px)',
        html: '<div class="text-center mb-3">' + imageHtml + '</div>' +
            detailsHtml + descriptionHtml +
            '<div class="mt-4 text-right">' +
            '<label class="block text-xs font-bold text-slate-500 mb-2">الكمية المحمّلة</label>' +
            '<input id="swal-qty" type="number" class="swal2-input !rounded-xl !text-center !font-bold !text-lg" value="' + esc(cur) + '" min="0" max="' + esc(it.qty_ordered) + '">' +
            '<label class="block text-xs font-bold text-slate-500 mb-2 mt-4">ملاحظات</label>' +
            '<input id="swal-notes" class="swal2-input !rounded-xl" value="' + esc(it.notes || '') + '" placeholder="سبب النقص أو الزيادة...">' +
            '</div>',
        showCancelButton: true,
        confirmButtonText: 'حفظ',
        cancelButtonText: 'إلغاء',
        customClass: {
            popup: '!rounded-3xl',
            confirmButton: '!rounded-xl !bg-orange-600 !px-8',
            cancelButton: '!rounded-xl'
        },
        didOpen: function() {
            var popup = Swal.getPopup();
            var image = popup ? popup.querySelector('#loaderLoadedItemImage') : null;
            var fallback = popup ? popup.querySelector('#loaderLoadedItemImageFallback') : null;
            if (image) {
                image.addEventListener('error', function() {
                    image.classList.add('hidden');
                    if (fallback) fallback.classList.remove('hidden');
                });
            }
        },
        preConfirm: function() {
            var p = Swal.getPopup();
            var qe = p ? p.querySelector('#swal-qty') : null;
            var ne = p ? p.querySelector('#swal-notes') : null;
            return {
                qty: qe ? Math.max(0, Math.min(parseInt(qe.value, 10) || 0, Number(it.qty_ordered) || 0)) : 0,
                notes: ne ? ne.value.trim() : ''
            };
        }
    }).then(function(r) {
        if (!r.isConfirmed) return;

        var nq = r.value.qty;
        var nt = r.value.notes;

        if (nq > it.qty_picked && !nt) {
            Swal.fire({
                title: 'تنبيه',
                text: 'الكمية المحمّلة أكبر من المحضّرة. يجب ذكر السبب.',
                icon: 'warning',
                showCancelButton: true,
                confirmButtonText: 'إضافة سبب',
                cancelButtonText: 'تخطي',
                customClass: {
                    popup: '!rounded-3xl',
                    confirmButton: '!rounded-xl !bg-amber-500 !px-6',
                    cancelButton: '!rounded-xl'
                }
            }).then(function(r2) {
                if (r2.isConfirmed) s.editLoadedItem(idx, nq);
            });
            return;
        }

        if (nq > it.qty_picked) nt = (nt ? nt + ' | ' : '') + 'عدّلها المحمّل';

        s.session.items[idx].qty_loaded = nq;
        s.session.items[idx].notes = nt;

        supabase.from('run_sheet_details')
            .update({ qty_loaded: nq })
            .eq('runsheet_id', s.session.runsheet_id)
            .eq('item_code', it.item_code)
            .then(function() {});

        s.renderActiveSession();

        if (nq < it.qty_picked && !nt) {
            Swal.fire({
                title: 'تنبيه',
                text: 'الكمية المحمّلة أقل من المحضّرة. هل تريد إضافة سبب؟',
                icon: 'question',
                showCancelButton: true,
                confirmButtonText: 'إضافة سبب',
                cancelButtonText: 'تخطي',
                customClass: {
                    popup: '!rounded-3xl',
                    confirmButton: '!rounded-xl !bg-amber-500 !px-6',
                    cancelButton: '!rounded-xl'
                }
            }).then(function(r2) {
                if (r2.isConfirmed) s.editLoadedItem(idx, nq);
            });
        }
    });
},
~~~

**فجوة منفصلة لا تُغلق بهذا التغيير:** استدعاء تحديث run_sheet_details.qty_loaded الحالي ما زال يتجاهل error ونتيجة التحديث، وهي نقطة حفظ تشغيلية وردت تاريخيًا في Report466. لا تدّعِ أن تعديل العرض عالجها، ولا تغيّر مسار الحفظ المركزي ضمن هذه الرقعة.

## 10. اختبارات القبول

### عرض التفاصيل
1. فتح رانشيت Picked من البطاقة ومن البحث يفتح الصفحة داخل mainContent.
2. يظهر زر رجوع وزر بدء التحميل؛ لا يبدأ التحميل قبل الضغط على الزر.
3. الضغط على بطاقة صنف يفتح مودالًا كبير الصورة وبيانات الصنف، ويعمل Enter/Space على البطاقة المركّز عليها.
4. المودال يعرض الاسم والكود والوحدة والكمية المطلوبة والمحضّرة والسعر والقيمة التقديرية والوصف.
5. الصورة المفقودة أو الفاشلة تعرض placeholder ولا تكسر المودال.
6. العودة تعيد القائمة دون بقاء event handlers على عناصر قديمة.

### جلسة التحميل النشطة
1. فتح رانشيت Loading الخاص بالمستخدم يفتح الجلسة النشطة.
2. الضغط على الصنف يبقي مودال تحرير الكمية، لكن بصورة h-72 ووصف وكود ووحدة وكميات ظاهرة.
3. الحفظ والتنبيهات وإعادة فتح المودال وإنهاء التحميل لا تتغير وظيفيًا.
4. فتح رانشيت Loading مملوك لمحمّل آخر يُرفض من البطاقة أو البحث.

### التكامل والعزل
1. استعلامات القائمة والبحث والفتح مقيّدة بـ company_id الخاص بالمستخدم.
2. الوصف والصورة من علاقة items!run_sheet_details_item_id_fkey، لا من أعمدة غير موجودة في run_sheet_details.
3. فحص Console وNetwork.
4. مقارنة stock_branches.qty وstock_branches.allocated_qty وinventory_log قبل وبعد فتح التفاصيل؛ المتوقع صفر تغيّر.
5. اختبار Static JavaScript Parse ثم Staging/Browser E2E بعد تطبيق المالك.
6. لا تُجرى اختبارات تغيير المخزون على بيانات Production الحية. عينة Production الحالية لا تكفي لاختبار كل حالات التحميل؛ استخدم بيئة اختبار معزولة.
7. بعد النشر، تحقّق بشكل مستقل من HTML الذي تقدمه Cloudflare Pages؛ Git SHA وحده ليس دليل نشر.

## 11. ما تم وما لم يتم

- أُعيد جلب ومقارنة Loader وPicker وCore مباشرة.
- تم التحقق قراءة فقط من مخطط Production والعلاقة بين التفاصيل والأصناف.
- لم يُعدّل الملف التشغيلي أو main.html أو core.js أو picker.html.
- لم تُنفذ أي تغييرات DDL/RLS/RPC/Edge أو تعديلات لبيانات Production.
- لم تُنشأ بيانات اختبار في Production.
- لم يُجر اختبار Browser E2E بعد؛ مطلوب بعد تطبيق المالك للرقعة.

## 12. الخلاصة

المعالجة المتماسكة هي: نطاق الشركة وملكية جلسة التحميل عند الفتح؛ جلب الصورة والوصف عبر العلاقة الحالية؛ بطاقات معاينة قابلة للنقر؛ مودال تفاصيل بصورة كبيرة وحقول كاملة؛ وتكبير مودال الصنف أثناء التحميل مع إبقاء تحرير الكمية والملاحظات كما هما.

**الحالة:** COMPARISON CORRECTED / CONSOLIDATED SURGICAL PATCH DOCUMENTED / OWNER APPLICATION REQUIRED / NO OPERATIONAL OR PRODUCTION MUTATION / NOT CLOSED.
