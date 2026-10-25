# Report492 — تسوية رقعة Loader/Picker وتحديد الاستبدالات المصدرية الدقيقة

**التاريخ:** 2026-10-25  
**آخر فحص Production مباشر:** 2026-10-25 13:26:50.668276 UTC — PostgreSQL 17.6  
**المستودع التشغيلي:** `papamohammed77-glitch/erp-frontend` / `main`  
**مستودع الحالة والتقارير:** `papamohammed77-glitch/rawaie-erp-New` / `main`  
**الحالة:** SOURCE + SCHEMA REVALIDATED / PATCH LINEAGE RECONCILED / OWNER-APPLIED SOURCE PATCH REQUIRED / NO OPERATIONAL MUTATION / NOT CLOSED

## 1. القرار التنفيذي

المهمة الحالية هي استكمال عرض تفاصيل الصنف داخل Loader مقارنةً بـPicker، مع عدم تغيير دورة التحميل أو حركة المخزون. تعليمات `writing-block.md` تمنع تعديل `loader.html` مباشرةً في هذه المهمة؛ لذلك لم أعدّل مستودع `erp-frontend` أو Production. جهزت هذه الوثيقة لتكون التعديل المصدري الدقيق الذي يطبقه المالك.

**تصحيح لازم للتقرير السابق Report485:** اعتمد Report485 على A–F من Report482 مع G من Report483، لكنه لم يدمج تصحيح العزل الأحدث في Report484 دمجًا كاملًا. لا تُطبق Report485 حرفيًا؛ لأن الرجوع إلى `RW_ImageCache.getImageUrl(item_code)` أو `RW_ImageCache.getImageHTML(item_code)` قد يعرض صورة من شركة أخرى عند تكرار `item_code`. هذه الوثيقة توحّد الرقعة على مبدأ واحد: **صورة الصنف تأتي فقط من علاقة `items` المرتبطة بسطر الرانشيت، أو من `image_url` المنسوخ من تلك العلاقة إلى جلسة التحميل؛ لا fallback إلى كاش الصور العام.**

## 2. PRE-CHANGE SELF-AUDIT

| المجال | الحالة | الدليل |
|---|---|---|
| فهم الأعمال | CONFIRMED ضمن نطاق العرض | معاينة Picked يجب ألا تبدأ التحميل؛ جلسة Loading تبقى محررًا للكمية |
| فهم المصدر الحالي | CONFIRMED | جلب مباشر لملفات GitHub في هذه الدورة |
| فهم قاعدة البيانات | CONFIRMED | استعلام Production قراءة فقط عند 13:26:50.668276 UTC |
| Historical / patch lineage | CONFIRMED جزئيًا | تمت مراجعة Report482 وReport483 وReport484 وReport485 وCURRENT_STATE.md |
| Production runtime للواجهة | UNKNOWN | لا يوجد إثبات مستقل لهوية HTML التي يقدمها Cloudflare |
| Staging / Browser E2E | UNVERIFIED | لم ينفذ اختبار بعد تطبيق الرقعة؛ المصدر لم يُعدّل |
| Execution confidence | مرتفع في تشخيص المصدر والمخطط؛ غير كافٍ لإغلاق Runtime | التغيير لم يُطبّق ولم يُنشر |

### البصمات التي جُلبت مباشرةً

- `loader.html`: `97b83d68a683df77c1e0557838c24a1b4fb65169` — 332 سطرًا.
- `picker.html`: `d483bd15b36585b975b63c2ef641481a01d5d084` — 1,058 سطرًا.
- `core.js`: `ff2f581d9900543c16f7cb026e13446520c0329d` — 773 سطرًا.

هذه Git blob SHAs، وليست بصمات نشر Cloudflare.

### Production schema / security — قراءة فقط

- وقت الملاحظة: `2026-10-25 13:26:50.668276+00`.
- `items` يحتوي `id, company_id, item_code, name, unit, description, image_url`.
- `run_sheet_details` يحتوي `item_id, runsheet_id, item_code, item_name, unit, unit_price, qty_ordered, qty_picked, qty_loaded`، ولا يحتوي `description` أو `image_url) أو `notes`.
- `run_sheet_details_item_id_fkey`: `run_sheet_details.item_id → items.id`.
- `run_sheet_details_runsheet_id_fkey`: `run_sheet_details.runsheet_id → runsheets.id`.
- `runsheets.loader_id` مفتاح أجنبي إلى `users.id`؛ لذلك المقارنة الصحيحة لملكية جلسة التحميل تكون مع `currentUser.id`، وليس البريد الإلكتروني.
- RLS مفعّل على الجداول الثلاثة. سياسة قراءة تفاصيل الرانشيت تربطها برانشيت الشركة الحالية والصلاحيات.
- صلاحية `authenticated UPDATE` على `run_sheet_details` = false. لا يجوز تقديم تحديث الواجهة الحالي كحفظ موثوق.
- الإنتاج يحتوي 18 صنفًا و12 سطر تفاصيل ورانشيتين، وكلا الرانشيتين `Picked`. لم يُستخدم أي صف إنتاجي لإجراء اختبار تغيير مخزون.

## 3. تصحيح تاريخ الرقعة

1. **Report482 A–F:** الأساس الوظيفي الصحيح: نطاق الشركة، فتح الرانشيت ومعالجة الأخطاء، جلب علاقة الصنف، تفاصيل الصنف، وتكبير مودال التحرير.
2. **Report483 G:** كشف ضرورة عدم الاكتفاء بمساعد الصور المشترك، لكنه يتضمن fallback إلى الكاش العام؛ هذا لا يكفي لعزل الصور بين الشركات.
3. **Report484:** أثبت خطر استخدام كاش الصور العام غير المقيد بـ`company_id`، وصحح العلاقة إلى `description, image_url, name, unit`، ومنع الرجوع إلى كاش الصور العام. لكن مساعده المقترح يستخدم `onerror` مضمنًا داخل HTML.
4. **Report485:** أعاد تأكيد A–F + G لكنه لم يدمج جميع تصحيحات Report484، ولذلك لا يُعتمد كرقعة نهائية منفردة.
5. **هذه الوثيقة:** تعتمد تصحيحات Report484، وتستبدل `onerror` المضمن بربط أحداث بعد الرسم، وتمنع الرجوع إلى كاش الصور العام، وتثبت أن هوية `loader_id` هي `users.id`.

## 4. الاستبدالات الجراحية

> في كل عنصر أدناه: النص الأصلي هو النص الذي جُلب من Loader الحالي ذي SHA أعلاه. طبّق الاستبدال فقط إذا ظلت بصمة Loader كما هي. إذا تغيّرت البصمة، أعد تحديد المقطع على النسخة الجديدة أولًا.

### A1 — استعلاما قائمة الرانشيتات

**الموضع:** `App.renderPendingTab()`، السطران الحاليان 100–101.

**العنصر المعيب الأصلي:**
```js
supabase.from('runsheets').select('runsheet_code, status, run_date, loader_id, run_sheet_details(count)').eq('status','Loading').eq('loader_id',this.currentUser.id||this.currentUser.email).order('run_date',{ascending:false}).limit(20),
supabase.from('runsheets').select('runsheet_code, status, run_date, loader_id, run_sheet_details(count)').eq('status','Picked').order('run_date',{ascending:false}).limit(50)
```

**العنصر المصحح للاستبدال:**
```js
supabase.from('runsheets').select('runsheet_code, status, run_date, loader_id, run_sheet_details(count)').eq('company_id',this.currentUser.company_id).eq('status','Loading').eq('loader_id',this.currentUser.id).order('run_date',{ascending:false}).limit(20),
supabase.from('runsheets').select('runsheet_code, status, run_date, loader_id, run_sheet_details(count)').eq('company_id',this.currentUser.company_id).eq('status','Picked').order('run_date',{ascending:false}).limit(50)
```

### A2 — استعلام البحث

**الموضع:** `App.onSearchInput(q)`، السطر الحالي 128.

**العنصر المعيب الأصلي:**
```js
supabase.from('runsheets').select('runsheet_code,status,run_date,loader_id,run_sheet_details(count)').or('status.eq.Picked,status.eq.Loading').ilike('runsheet_code','%'+q.trim()+'%').limit(10).then(function(r) { s.searchResults=r.data||[]; s.renderSearchDropdown(); });
```

**العنصر المصحح للاستبدال:**
```js
supabase.from('runsheets')
    .select('runsheet_code,status,run_date,loader_id,run_sheet_details(count)')
    .eq('company_id', s.currentUser.company_id)
    .or('status.eq.Picked,status.eq.Loading')
    .ilike('runsheet_code', '%' + q.trim() + '%')
    .limit(10)
    .then(function(r) {
        if (r.error) {
            console.error('Loader runsheet search error:', r.error);
            s.searchResults = [];
            s.renderSearchDropdown();
            return;
        }
        s.searchResults = r.data || [];
        s.renderSearchDropdown();
    });
```

### B — استبدال App.openRunsheet(code) كاملةً

**محدد البداية:** `openRunsheet: function(code) {`  
**نهاية الاستبدال:** الفاصلة التي تنهي الدالة قبل `_startSession: function(code, rs, items) {`.

**العنصر المعيب الأصلي المحدد:**
```js
openRunsheet: function(code) {
    var self = this; var dd = RW_UI.byId('searchDropdown'); if(dd) dd.classList.add('hidden');
    RW_UI.showSkeleton('mainContent',3,'card');
    supabase.from('runsheets').select('*').eq('runsheet_code',code).maybeSingle().then(function(rsRes) {
        if(!rsRes.data) { RW_UI.toast('الرانشيت غير موجود','error'); self.renderPendingTab(); return; }
        var rs = rsRes.data;
        supabase.from('run_sheet_details').select('*').eq('runsheet_id',rs.id).then(function(detRes) {
            var items = detRes.data||[], isActive = (rs.status==='Loading'&&(rs.loader_id===self.currentUser.id||rs.loader_id===self.currentUser.email)), isAvail = (rs.status==='Picked');
            if(isActive) { self._startSession(code,rs,items); return; }
            if(isAvail) { self._showPreviewModal(code,rs,items); return; }
            self._renderReadonly(code,items);
        });
    });
},
```

**العنصر المصحح للاستبدال:**
```js
openRunsheet: function(code) {
    var self = this;
    var dropdown = RW_UI.byId('searchDropdown');
    if (dropdown) dropdown.classList.add('hidden');

    if (!self.currentUser || !self.currentUser.company_id || !self.currentUser.id) {
        RW_UI.toast('تعذر تحديد الشركة أو المستخدم الحالي', 'error');
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
            var isActive = rs.status === 'Loading' && rs.loader_id === self.currentUser.id;

            if (rs.status === 'Loading' && !isActive) {
                RW_UI.toast('الرانشيت قيد التحميل بواسطة موظف آخر', 'warning');
                self.renderPendingTab();
                return;
            }

            supabase.from('run_sheet_details')
                .select('*, items!run_sheet_details_item_id_fkey(description, image_url, name, unit)')
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
```

### C — استبدال App._startSession(code, rs, items) كاملةً

**العنصر المعيب الأصلي:**
```js
_startSession: function(code, rs, items) {
    this.session = { runsheet_code:code, runsheet_id:rs.id, start_time:rs.loader_start||new Date().toISOString(), items:[] };
    for(var i=0;i<items.length;i++) { var it=items[i]; this.session.items.push({ item_code:it.item_code, item_name:it.item_name||'', unit:it.unit||'حبة', qty_ordered:Number(it.qty_ordered)||0, qty_picked:Number(it.qty_picked)||0, qty_loaded:Number(it.qty_loaded)||0, notes:it.notes||'' }); }
    this.renderActiveSession();
},
```

**العنصر المصحح للاستبدال:**
```js
_startSession: function(code, rs, items) {
    this.session = {
        runsheet_code: code,
        runsheet_id: rs.id,
        start_time: rs.loader_start || new Date().toISOString(),
        items: []
    };

    for (var i = 0; i < items.length; i++) {
        var it = items[i];
        var product = it.items || {};
        if (Array.isArray(product)) product = product[0] || {};

        this.session.items.push({
            item_code: it.item_code,
            item_name: it.item_name || product.name || '',
            unit: it.unit || product.unit || 'حبة',
            description: product.description || '',
            image_url: product.image_url || '',
            unit_price: Number(it.unit_price) || 0,
            qty_ordered: Number(it.qty_ordered) || 0,
            qty_picked: Number(it.qty_picked) || 0,
            qty_loaded: Number(it.qty_loaded) || 0,
            notes: it.notes || ''
        });
    }

    this.renderActiveSession();
},
```

### D — مساعدا الصورة الآمنان داخل كائن App

**موضع الإضافة:** داخل كائن `App`، مرة واحدة فقط، قبل `_startSession` أو بعده، مع فاصلة صحيحة بين الخصائص.

**العنصر المصحح الكامل للإضافة:**
```js
_loaderImageHTML: function(item, widthClass, heightClass, fitClass) {
    var product = item && item.items ? item.items : {};
    if (Array.isArray(product)) product = product[0] || {};

    var rawUrl = String(
        (product && product.image_url) ||
        (item && item.image_url) ||
        ''
    ).trim();

    function esc(value) {
        return String(value == null ? '' : value)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    var validUrl = /^https?:\/\/[^\s"'<>]+$/i.test(rawUrl) ||
        /^\/(?!\/)[^\s"'<>]*$/.test(rawUrl);
    var w = widthClass || 'w-14';
    var h = heightClass || 'h-14';
    var fit = fitClass || 'object-cover';
    var imageHtml = validUrl
        ? '<img data-loader-image="true" src="' + esc(rawUrl) +
            '" alt="' + esc((item && item.item_name) || (product && product.name) || '') +
            '" class="' + esc(w) + ' ' + esc(h) + ' rounded-2xl ' + esc(fit) +
            ' border-2 border-white shadow-sm">'
        : '';

    var fallbackClass = (validUrl ? 'hidden ' : '') + esc(w) + ' ' + esc(h) +
        ' bg-gradient-to-br from-slate-100 to-slate-200 rounded-2xl ' +
        'flex items-center justify-center text-slate-400';

    return '<span class="inline-flex relative shrink-0">' + imageHtml +
        '<span data-loader-image-fallback="true" class="' + fallbackClass + '">' +
        '<i class="fa-solid fa-box"></i></span></span>';
},

_bindLoaderImageFallbacks: function(root) {
    if (!root) return;

    var images = root.querySelectorAll('img[data-loader-image="true"]');
    for (var i = 0; i < images.length; i++) {
        (function(image) {
            var wrap = image.parentNode;
            var fallback = wrap
                ? wrap.querySelector('[data-loader-image-fallback="true"]')
                : null;

            function showFallback() {
                image.classList.add('hidden');
                if (fallback) fallback.classList.remove('hidden');
            }

            image.addEventListener('error', showFallback);
            if (image.complete && image.naturalWidth === 0) showFallback();
        })(images[i]);
    }
},
```

**مهم:** لا يُستخدم `RW_ImageCache.getImageHTML` أو `RW_ImageCache.getImageUrl` كـfallback في هذه المسارات. مصدر الصورة الوحيد هو علاقة الصنف نفسها. لا تعدّل `core.js`.

### E — استبدال مواضع الصور المصغرة الثلاثة

**العنصر المعيب الأصلي في `_showPreviewModal`:**
```js
h += '<div class="shrink-0">' + RW_ImageCache.getImageHTML(it.item_code) + '</div>';
```

**العنصر المصحح للاستبدال:**
```js
h += '<div class="shrink-0">' + self._loaderImageHTML(it, 'w-14', 'h-14') + '</div>';
```

**العنصر المعيب الأصلي في `_renderReadonly`:**
```js
RW_ImageCache.getImageHTML(it.item_code)
```

**العنصر المصحح للاستبدال:**
```js
this._loaderImageHTML(it, 'w-14', 'h-14')
```

**العنصر المعيب الأصلي في `renderActiveSession`:**
```js
RW_ImageCache.getImageHTML(it.item_code)
```

**العنصر المصحح للاستبدال:**
```js
s._loaderImageHTML(it, 'w-14', 'h-14')
```

بعد كل استدعاء `RW_UI.safeHTML(...)` في هذه الدوال الثلاث، أضف استدعاء ربط fallback على عنصر `mainContent`، باستخدام مرجع الكائن نفسه:
```js
self._bindLoaderImageFallbacks(RW_UI.byId('mainContent'));
```
داخل `_renderReadonly` استخدم:
```js
this._bindLoaderImageFallbacks(RW_UI.byId('mainContent'));
```
وداخل `renderActiveSession` استخدم:
```js
s._bindLoaderImageFallbacks(RW_UI.byId('mainContent'));
```
وفي الجلسة النشطة يجب أن يأتي الاستدعاء قبل `this.startTimer()`.

### F — بطاقات معاينة الصنف

**العنصر المعيب الأصلي:**
```js
h += '<div class="card mb-3"><div class="flex items-start gap-3">';
```

**العنصر المصحح للاستبدال:**
```js
h += '<div class="card mb-3 cursor-pointer loader-preview-item hover:shadow-md transition-all focus:outline-none focus:ring-2 focus:ring-orange-300" role="button" tabindex="0" data-loader-item-index="' + i + '"><div class="flex items-start gap-3">';
```

قبل شرط `if (!items.length)` أضف الإرشاد:
```js
h += '<p class="text-sm text-slate-400 mb-3">اضغط على الصنف لعرض صورته وتفاصيله</p>';
```

بعد `RW_UI.safeHTML(RW_UI.byId('mainContent'), h);` داخل `_showPreviewModal` أضف ربط الصور وربط البطاقات. استخدم مرجع `self` الموجود في بداية الدالة:
```js
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
```

### G — إضافة مودال تفاصيل الصنف

**موضع الإضافة:** داخل `App` بعد `_showPreviewModal` وقبل `_startLoadingFromPreview`. لا تستبدل أي دالة مجاورة.

**العنصر المصحح الكامل للإضافة:**
```js
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
    if (Array.isArray(product)) product = product[0] || {};

    var name = item.item_name || product.name || '';
    var code = item.item_code || '';
    var unit = item.unit || product.unit || 'حبة';
    var description = product.description || '';
    var rawImageUrl = String(product.image_url || item.image_url || '').trim();
    var imageUrl = (/^https?:\/\/[^\s"'<>]+$/i.test(rawImageUrl) ||
        /^\/(?!\/)[^\s"'<>]*$/.test(rawImageUrl)) ? rawImageUrl : '';

    var imageHtml = imageUrl
        ? '<img id="loaderItemDetailImage" data-loader-image="true" src="' + esc(imageUrl) +
            '" alt="' + esc(name) +
            '" class="w-full h-80 rounded-2xl object-contain bg-white mx-auto shadow-sm mb-3">'
        : '';
    imageHtml += '<div id="loaderItemDetailImageFallback" class="' +
        (imageUrl ? 'hidden ' : '') +
        'w-full h-80 rounded-2xl bg-white mx-auto flex items-center justify-center text-slate-400 mb-3">' +
        '<i class="fa-solid fa-box text-4xl"></i></div>';

    var requestedQty = Number(item.qty_ordered) || 0;
    var pickedQty = Number(item.qty_picked) || 0;
    var unitPrice = Number(item.unit_price) || 0;
    var lineValue = pickedQty * unitPrice;
    var descriptionHtml = description
        ? '<p class="text-sm text-slate-500 mt-3 pt-3 border-t border-slate-100 text-right">' + esc(description) + '</p>'
        : '';

    var html = '<div class="text-center mb-4">' + imageHtml + '</div><div class="text-right">';
    html += '<h3 class="font-black text-xl text-slate-800 mb-3">' + esc(name) + '</h3>';
    html += '<div class="text-sm space-y-2">';
    html += '<div class="flex justify-between gap-3"><span class="text-slate-400">الكود</span><strong>' + esc(code) + '</strong></div>';
    html += '<div class="flex justify-between gap-3"><span class="text-slate-400">الوحدة</span><strong>' + esc(unit) + '</strong></div>';
    html += '<div class="flex justify-between gap-3"><span class="text-slate-400">الكمية المطلوبة</span><strong>' + esc(RW_UI.formatNumber(requestedQty)) + '</strong></div>';
    html += '<div class="flex justify-between gap-3"><span class="text-slate-400">الكمية المحضّرة</span><strong>' + esc(RW_UI.formatNumber(pickedQty)) + '</strong></div>';
    html += '<div class="flex justify-between gap-3"><span class="text-slate-400">سعر الوحدة</span><strong>' + esc(RW_UI.formatNumber(unitPrice)) + '</strong></div>';
    html += '<div class="flex justify-between gap-3"><span class="text-slate-400">القيمة التقديرية للمحضّر</span><strong>' + esc(RW_UI.formatNumber(lineValue)) + ' جنيه</strong></div>';
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
                function showFallback() {
                    image.classList.add('hidden');
                    if (fallback) fallback.classList.remove('hidden');
                }
                image.addEventListener('error', showFallback);
                if (image.complete && image.naturalWidth === 0) showFallback();
            }
        }
    });
},
```

### H — استبدال App._renderReadonly(code, items) كاملةً

**العنصر المعيب الأصلي:**
```js
_renderReadonly: function(code, items) {
    var h = '<div class="flex items-center gap-3 mb-6"><button onclick="App.renderPendingTab()" class="w-10 h-10 bg-white rounded-2xl flex items-center justify-center text-orange-600 shadow-sm"><i class="fa-solid fa-arrow-right"></i></button><span class="font-black text-xl text-slate-800">'+code+' | '+items.length+' صنف</span></div>';
    for(var k=0;k<items.length;k++) { var it=items[k]; h += '<div class="card mb-2"><div class="flex items-center gap-4">'+RW_ImageCache.getImageHTML(it.item_code)+'<div><p class="font-bold text-slate-700">'+(it.item_name||'')+'</p><p class="text-xs text-slate-400">'+(it.item_code||'')+' | محضّر: <span class="font-bold text-slate-600">'+(Number(it.qty_picked)||0)+'</span> '+(it.unit||'حبة')+'</p></div></div></div>'; }
    RW_UI.safeHTML(RW_UI.byId('mainContent'), h);
},
```

**العنصر المصحح للاستبدال:**
```js
_renderReadonly: function(code, items) {
    var self = this;

    function esc(value) {
        return String(value == null ? '' : value)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    var h = '<div class="flex items-center gap-3 mb-6">' +
        '<button type="button" id="loaderReadonlyBack" class="w-10 h-10 bg-white rounded-2xl flex items-center justify-center text-orange-600 shadow-sm" aria-label="العودة إلى قائمة الرانشيتات"><i class="fa-solid fa-arrow-right"></i></button>' +
        '<span class="font-black text-xl text-slate-800">' + esc(code) + ' | ' + items.length + ' صنف</span></div>';

    for (var k = 0; k < items.length; k++) {
        var it = items[k];
        h += '<div class="card mb-2"><div class="flex items-center gap-4">' +
            self._loaderImageHTML(it, 'w-14', 'h-14') +
            '<div><p class="font-bold text-slate-700">' + esc(it.item_name || '') + '</p>' +
            '<p class="text-xs text-slate-400">' + esc(it.item_code || '') +
            ' | محضّر: <span class="font-bold text-slate-600">' +
            esc(RW_UI.formatNumber(Number(it.qty_picked) || 0)) + '</span> ' +
            esc(it.unit || 'حبة') + '</p></div></div></div>';
    }

    RW_UI.safeHTML(RW_UI.byId('mainContent'), h);
    self._bindLoaderImageFallbacks(RW_UI.byId('mainContent'));

    var back = RW_UI.byId('loaderReadonlyBack');
    if (back) back.addEventListener('click', function() {
        self.renderPendingTab();
    });
},
```

### I — مودال تحرير الكمية أثناء التحميل

لا تستبدل هذا المودال بمودال قراءة فقط، ولا تغيّر عقد الحفظ في هذه الرقعة. استبدل فقط عنصر الصورة الصغير بإظهار صورة كبيرة من `it.image_url`، مع fallback آمن. لا تستخدم كاش الصور العام.

**العنصر المعيب الأصلي داخل `editLoadedItem`:**
```js
'<div class="text-center">'+RW_ImageCache.getImageHTML(it.item_code,'w-20','h-20')+'</div>'
```

**العنصر المصحح للاستبدال:**
```js
'<div class="text-center mb-3">' +
    s._loaderImageHTML(it, 'w-full max-w-xs', 'h-72', 'object-contain') +
'</div>'
```

بعد بناء المودال الحالي، داخل `didOpen`، اربط fallback على popup:
```js
didOpen: function() {
    var popup = Swal.getPopup();
    s._bindLoaderImageFallbacks(popup);
},
```

يجب أن تبقى حقول الكمية والملاحظات والتحذيرات والحفظ كما هي في هذه الرقعة. عيب الحفظ الحالي منفصل ومثبت: تحديث `run_sheet_details.qty_loaded` المباشر غير مسموح لـauthenticated وتُهمل نتيجته؛ لا تعلن إغلاق هذا العيب بتعديل العرض.

## 5. ما لا يجوز تغييره في هذه المهمة

- لا تعدّل `picker.html` أو `main.html` أو `core.js`.
- لا تنشئ Edge Function أو RPC جديدة لهذا النقص العرضي.
- لا تغيّر المخزون أو الحجز أو دورة حياة الرانشيت.
- لا تمنح `authenticated` صلاحية UPDATE على `run_sheet_details`.
- لا تدّعِ أن عيب حفظ الكميات/الملاحظات قد أُغلق بهذه الرقعة.
- لا تعلن أن التعديل طُبّق أو نُشر؛ لم يتم تعديل الملف التشغيلي في هذه المهمة.

## 6. الاختبارات المطلوبة بعد تطبيق المالك

1. أعد جلب Loader فورًا وتأكد من SHA قبل التطبيق.
2. طبّق العناصر A1–I فقط على المواضع المطابقة؛ لا تلصق الرقعة إذا تغير المصدر دون إعادة مطابقة.
3. نفّذ parse للـJavaScript الكامل داخل HTML بعد التعديل.
4. اختبر شركة A وشركة B، مع تكرار `item_code` واختلاف `image_url`؛ يجب ألا تتسرب صورة من الشركة الأخرى.
5. اختبر قائمة الرانشيت والبحث وفتح Picked، ثم فتح الصنف بالنقر وEnter وSpace.
6. اختبر جلسة Loading للمستخدم نفسه ورفض جلسة محمّل آخر؛ `loader_id` يقارن بـ`currentUser.id`.
7. اختبر صورة صحيحة، URL غير مسموح، URL معطوب، وصورة تفشل قبل ربط الحدث؛ كل حالة يجب أن تعرض fallback.
8. افتح المعاينة وقارن قبل/بعد `stock_branches.qty` و`stock_branches.allocated_qty` و`inventory_log`؛ المتوقع صفر تغيير.
9. لا تختبر إتمام التحميل على Production. استخدم Staging معزولًا بعد التحقق من أنه ACTIVE.
10. بعد النشر، تحقق مستقلًا من HTML الذي يقدمه Cloudflare ومن سلسلة نشره، ثم نفذ Browser E2E مصادقًا عليه.
11. افحص بشكل منفصل عقد إنهاء التحميل: صفر كمية، كميات جزئية، ملاحظات، retry/idempotency، ونتيجة الحفظ في `order_details`/العلاقة المشتقة. هذا دين منفصل لا يغلقه هذا التغيير.

## 7. سجل التغيير في هذه الدورة

- تمت قراءة `writing-block.md` كمصدر تكليف.
- تمت إعادة جلب Loader وPicker وCore من المستودع التشغيلي.
- تمت إعادة قراءة `CURRENT_STATE.md` وتقارير Report482 وReport483 وReport484 وReport485.
- تمت قراءة Production مباشرةً باستعلام SQL للقراءة فقط في `2026-10-25 13:26:50.668276+00`.
- لم يتغير أي ملف تشغيلي في `erp-frontend`.
- لم تتغير قاعدة بيانات Production ولم يُنشر Edge Function أو RPC.
- لم يُنشأ Fixture ولم تُنفذ اختبارات Staging أو Browser E2E.
- تم إنشاء هذا التقرير وتحديث CURRENT_STATE فقط.

## 8. SELF-AUDIT FINAL

**ما أثبته**
- مصدر Loader الحالي ما زال يفتقد علاقة وصف/صورة الصنف.
- بيانات الوصف والصورة تأتي من `items` عبر FK المثبت في Production.
- مقارنة `loader_id` الصحيحة مع `users.id` مثبتة من FK.
- كاش الصور المشترك ليس مصدرًا آمنًا لصور هذا المسار لأنه غير مقيد بالشركة.
- Report485 لم يدمج تصحيح Report484 بالكامل، وهذه الوثيقة تصحح ترتيب الرقعة ومصدر الصور.

**ما لم أثبته**
- لم تُطبق الرقعة على `erp-frontend`.
- لم يُجر Static Parse للملف بعد التطبيق.
- لم تُختبر Staging أو Browser E2E.
- لم تُثبت هوية HTML الذي يقدمه Cloudflare.
- لم يُغلق تعارض إنهاء التحميل الخاص بالكميات الصفرية والملاحظات والحفظ.

**ما أصلحته**
- أصلحت التوثيق وتسوية مصدر الرقعة فقط. لم ألمس المصدر التشغيلي أو Production احترامًا لحدود التكليف.

**ما قد يظل خطأ**
- قد يتغير Loader قبل التطبيق؛ يجب إعادة جلبه وفحص SHA.
- يجب اختبار شكل العلاقة التي يعيدها PostgREST (object/array) في بيئة الاختبار.
- قد توجد فروق في النسخة المنشورة لا تظهر في Git.

**Final Confidence:** مرتفع في التشخيص ومطابقة المخطط؛ غير مثبت في Runtime.  
**Final Closure Status:** `PATCH RECONCILED / OWNER APPLICATION REQUIRED / NOT DEPLOYED / E2E UNVERIFIED / NOT CLOSED`.

## تعليمات المساعد القادم

1. اقرأ هذا التقرير و`CURRENT_STATE.md` أولًا.
2. أعد جلب Loader وتحقق من SHA.
3. طبّق هذه الرقعة الموحدة فقط إذا بقي المصدر مطابقًا للبصمة المحددة.
4. لا تعدّل Picker أو Core أو Main.
5. لا تغيّر Production أو المخزون لاختبار العرض.
6. بعد تطبيق المالك، نفذ Static Parse كاملًا، واختبارات معزولة، وتحقق من Cloudflare artifact وBrowser E2E.
7. أبقِ عيب حفظ الكميات/الملاحظات في حالة OPEN حتى يُعالج بعقد خلفي صحيح ومختبر.
