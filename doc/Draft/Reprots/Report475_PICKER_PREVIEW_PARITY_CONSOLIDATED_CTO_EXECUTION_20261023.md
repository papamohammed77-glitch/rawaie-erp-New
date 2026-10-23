# Report475 — التقرير التشغيلي الموحد لإصلاح معاينة Picker

هذا التقرير هو المرجع التشغيلي الموحّد لهذه المهمة. الحالة: READY FOR OWNER PATCH / NOT CLOSED.

## 1. الحالة التنفيذية

فُحص المصدر التشغيلي الحالي في مستودع `erp-frontend` والـProduction بقراءة فقط. لا يُعلن إغلاق المهمة قبل تطبيق التغييرات واختبارها والنشر.

## 2. هدف العمل وحدوده

RAWAEA ERP منظومة متكاملة وليست مجموعة شاشات منفصلة. مسار المخازن محل هذه المهمة هو: `Confirmed Orders → Runsheet → Picking/Allocation → Loading → Delivery/Return/Unloading → Stock/Ledger/Audit`. Picker مسؤول عن معاينة الرانشيت، تسجيل الكميات المحضّرة والملاحظات، حفظ مسودة Dexie، ثم استدعاء Edge Functions القائمة لإتمام التحضير. المعاينة نفسها لا يجوز أن تغيّر المخزون أو `allocated_qty` أو القيود المالية.

لماذا نعدل كتلة صغيرة فقط؟ تاريخ Picker يثبت وجود نطاق شركة، تحقق ملكية الجلسة، استعادة Dexie، تحقق الكميات، `operation_id`/Idempotency-Key ومعالجة خطأ نقص المخزون. إعادة كتابة `App.openRunsheet` كاملة قد تفسد هذه الضمانات؛ لذلك تبقى الجلسة النشطة وتدفق العمل كما هما.

## 3. مصادر الحقيقة وبصمات المصدر

المستودع التشغيلي: `papamohammed77-glitch/erp-frontend` على `main`. مستودع `rawaie-erp-New` للحوكمة والتقارير لا يثبت ما يعمل على Cloudflare. تمت قراءة وثيقة الحوكمة كاملة (2606 سطرًا) و`CURRENT_STATE.md` وذاكرة المشروع، والمصدر الكامل الحالي لكل من Loader وPicker، مع مقارنة تاريخية مع PWA القديمة.

| المصدر | البصمة الحالية |
|---|---|
| `companies/company-1/warehouse/loader.html` | `97b83d68a683df77c1e0557838c24a1b4fb65169`, 332 سطرًا |
| `companies/company-1/warehouse/picker.html` | `d483bd15b36585b975b63c2ef641481a01d5d084`, 1058 سطرًا |
| أحدث refactor لمعاينة Loader | commit `152e5b1d22aab94d2cf01070778b357df4701aff`, parent `e69c9af4b56d99ba29a4fa74282f78438b9f7010` |
| Core المشترك | `companies/company-1/core.js`, SHA `ff2f581d9900543c16f7cb026e13446520c0329d` |
| Picker التاريخي | `rawaie-erp-review/PWA/warehouse/picker.html`, SHA `7626ba320021a607854bf219f4bacd81fc3d1d92`, 623 سطرًا |
| Loader التاريخي | `rawaie-erp-review/PWA/warehouse/loader.html`, SHA `7e61b04d0d9a480d43763e8b7b21f9cbed78409a`, 266 سطرًا |

Loader يستورد `core.js` ويستخدم `RW_Auth/RW_UI/RW_API`. Picker لا يستورد النواة حاليًا؛ ينشئ Supabase client مستقلًا، ويتحقق من المستخدم والشركة محليًا، ويستخدم Dexie باسم `RW_Picker`. هذا اختلاف معماري قائم ويجب عدم دمج إصلاحه داخل رقعة العرض.

## 4. عقد Production التي تم التحقق منها

استعلام مباشر بوضع القراءة فقط في Supabase Production `SMART ERP` (`fiilmooggumokxanwiyx`) عند **2026-10-23 12:24:37 UTC**، PostgreSQL 17.6:

- `items` يحتوي `id/company_id/item_code/name/unit/description/image_url`.
- `run_sheet_details` يحتوي `item_id/runsheet_id/item_code/item_name/unit/unit_price/qty_ordered/qty_picked`، ولا يحتوي `description`.
- FK `run_sheet_details_item_id_fkey`: `item_id → items.id`؛ وFK `run_sheet_details_runsheet_id_fkey`: `runsheet_id → runsheets.id`.
- `runsheets.company_id → companies.id`.
- 18 صنفًا، و12 سجل تفاصيل رانشيت؛ حالات الرانشيت التي رجعها استعلام الحالة: `Picked: 2` فقط، ولا توجد `Open/Confirmed` في العينة الحالية.

إذًا وصف الصنف الصحيح يأتي من relation `items!run_sheet_details_item_id_fkey(description)`، وليس من `run_sheet_details.description`. لا تُنشأ حالات اختبار في Production؛ يلزم Staging معتمد لتجربة بدء التحضير.

الوظائف الحالية ذات الصلة كما رجعت من قائمة Production، ACTIVE وJWT verification مفعّل:
- `start-picking` v35، SHA `fca0377fce2d02d52a17bdbbdd98cfe9cc449d052533df0a3b021be11c79914a`.
- `complete-picking` v18، SHA `14b4d650253e73abc7c7a1b1f25a8674849c11e32d21ae9928701f19705b0537`.
- `start-loading` v5، SHA `afcfe32707382c57a15ebb744dec61e95a4079abb9ee8d32f479f322091230c7`.
- `complete-loading` v11، SHA `c0ca692a29d14d64ec3729ae4bd12b9b84268e826ffc1c6993a48617b552b286`.

لم يتم تغيير Schema أو RLS/RPC أو Edge Functions أو بيانات Production.

سياق تاريخ المصدر الذي روجع: commit `b903c403c8bebf7f98307d22f9c7ca286c72382e` عالج أخطاء قراءة الرانشيت والجلسة؛ `0c1ea67bc81ee5e001af69d0366de90ede8795f7` أضاف حفظ المسودة ومعرّف العملية؛ `67748842e6030c81ab8a2046b197f256d53a9c75` حسّن تحقق الكمية؛ و`fbcd4c7e1845236455f026eb3f7ae0ccfa8ba407` حسّن رسالة نقص المخزون. هذه التغييرات تفسر لماذا نحافظ على دورة التحضير الحالية ولا نعيد كتابتها.

## Owner patch A/A2 (complete selectors)
In `App.openRunsheet(code)`, replace the detail query `.from('run_sheet_details').select('*').eq('runsheet_id', rs.id)` with `.from('run_sheet_details').select('*, items!run_sheet_details_item_id_fkey(description)').eq('runsheet_id', rs.id)`. Replace active session mapping `description: items[i].description || ''` with `description: (items[i].items && items[i].items.description) || ''`. No schema changes.

## Owner patch B — full preview-block replacement
Replace the non-active preview block in `App.openRunsheet(code)` only, from its `var html = '';` after the active-session `return;` through `safeHTML(byId('mainContent'), html);` before the existing `.then` closures. Keep all surrounding control flow.

```js
var html = '', totalRequestedQty = 0, totalRequestedValue = 0;
function fmt(v){var n=Number(v);return isFinite(n)?n.toLocaleString('en-US',{maximumFractionDigits:2}):'0';}
function esc(v){return String(v==null?'':v).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;').replace(/'/g,'&#39;');}
var canStart=(rs.status==='Open'||rs.status==='Confirmed');
var labels={Open:'مفتوح',Confirmed:'مؤكد',Picked:'مكتمل التحضير',Picking:'قيد التحضير',Loading:'قيد التحميل',Loaded:'تم التحميل'};
html+='<div class="space-y-4 text-right slide-in"><div class="flex items-center gap-3 mb-5"><button type="button" id="pickerPreviewBack" class="w-10 h-10 bg-white rounded-2xl flex items-center justify-center text-indigo-600 shadow-sm" aria-label="العودة"><i class="fa-solid fa-arrow-right"></i></button><div><h2 class="font-black text-xl text-slate-800">معاينة الرانشيت</h2><p class="text-xs text-slate-400 mt-1">راجع الأصناف والكميات قبل بدء التحضير</p></div></div>';
html+='<div class="bg-indigo-50 rounded-3xl p-5"><p class="text-xs text-indigo-500 font-bold mb-1">رقم الرانشيت</p><h3 class="font-black text-2xl text-slate-800">'+esc(code)+'</h3><p class="text-xs text-slate-500 mt-2">التاريخ: '+esc(rs.run_date||'')+'</p><span class="px-3 py-1 rounded-full bg-white text-indigo-600 text-xs font-bold">'+esc(labels[rs.status]||rs.status||'غير محدد')+'</span></div>';
html+='<div class="grid grid-cols-1 sm:grid-cols-3 gap-3"><div class="card"><p class="text-xs text-slate-400">عدد الأصناف</p><p class="font-black text-xl">'+items.length+'</p></div><div class="card"><p class="text-xs text-slate-400">إجمالي الكمية المطلوبة</p><p id="pickerPreviewTotalQty" class="font-black text-xl">0</p></div><div class="card"><p class="text-xs text-slate-400">القيمة التقديرية للمطلوب</p><p id="pickerPreviewTotalValue" class="font-black text-xl text-indigo-600">0</p><p class="text-[11px] text-slate-400">جنيه مصري</p></div></div><h3 class="font-black text-slate-800">أصناف الرانشيت</h3>';
if(!items.length){html+='<div class="card text-center py-10"><i class="fa-solid fa-box-open text-3xl text-slate-300 mb-3"></i><p class="font-bold text-slate-500">لا توجد أصناف في هذا الرانشيت.</p></div>';}
else for(var k=0;k<items.length;k++){var it=items[k]||{},q=Number(it.qty_ordered)||0,picked=Number(it.qty_picked)||0,p=Number(it.unit_price)||0,v=q*p;totalRequestedQty+=q;totalRequestedValue+=v;
html+='<div class="card w-full text-right mb-3 slide-in cursor-pointer" role="button" tabindex="0" data-picker-item-index="'+k+'"><div class="flex items-start gap-3"><div class="relative shrink-0 w-14 h-14 rounded-2xl overflow-hidden bg-slate-100"><div class="absolute inset-0 flex items-center justify-center text-slate-400"><i class="fa-solid fa-box"></i></div>'+self._img(it.item_code)+'</div><div class="min-w-0 flex-1"><p class="font-bold text-slate-800">'+esc(it.item_name||'')+'</p><p class="text-xs text-slate-400 mt-1">'+esc(it.item_code||'')+' | '+esc(it.unit||'حبة')+'</p><div class="grid grid-cols-2 sm:grid-cols-4 gap-2 mt-3 text-sm"><div class="bg-slate-50 rounded-xl p-2"><p class="text-[11px] text-slate-400">مطلوب</p><p class="font-bold">'+fmt(q)+'</p></div><div class="bg-indigo-50 rounded-xl p-2"><p class="text-[11px] text-slate-400">محضّر</p><p class="font-black text-indigo-700">'+fmt(picked)+'</p></div><div class="bg-slate-50 rounded-xl p-2"><p class="text-[11px] text-slate-400">سعر الوحدة</p><p class="font-bold">'+fmt(p)+'</p></div><div class="bg-indigo-50 rounded-xl p-2"><p class="text-[11px] text-slate-400">قيمة المطلوب</p><p class="font-black text-indigo-700">'+fmt(v)+'</p></div></div></div></div></div>';
}
if(canStart){html+='<div class="sticky-top pt-2 pb-3 bg-slate-50"><button type="button" id="pickerPreviewStart" class="btn-primary"><i class="fa-solid fa-play ml-2"></i> بدء التحضير</button><p class="text-center text-xs text-slate-400 mt-2">المعاينة لا تغيّر المخزون؛ يبدأ التحضير بعد تأكيد البدء.</p></div>';}
else if(rs.status==='Picked'){html+='<div class="card text-center text-sm text-emerald-700 bg-emerald-50">اكتمل التحضير. معاينة للقراءة فقط.</div>';}

else{html+='<div class="card text-center text-sm text-slate-500">معاينة للقراءة فقط في الحالة الحالية.</div>';}
html+='</div>';safeHTML(byId('mainContent'),html);
var qe=byId('pickerPreviewTotalQty');if(qe)qe.textContent=fmt(totalRequestedQty);
var ve=byId('pickerPreviewTotalValue');if(ve)ve.textContent=fmt(totalRequestedValue);
var back=byId('pickerPreviewBack');if(back)back.addEventListener('click',function(){self.renderPendingTab();});
var start=byId('pickerPreviewStart');if(start)start.addEventListener('click',function(){self.startPicking(code);});
function openCard(ev){if(ev.type==='keydown'){if(ev.key!=='Enter'&&ev.key!==' ')return;ev.preventDefault();}var index=Number(this.getAttribute('data-picker-item-index')),it=items[index];if(!it)return;self.showItemDetail(it.item_code||'',it.item_name||'',it.unit||'حبة',Number(it.qty_ordered)||0,(it.items&&it.items.description)||'');}
var cards=byId('mainContent').querySelectorAll('[data-picker-item-index]');for(var ci=0;ci<cards.length;ci++){cards[ci].addEventListener('click',openCard);cards[ci].addEventListener('keydown',openCard);}
var imgs=byId('mainContent').querySelectorAll('img[data-picker-safe-image]');for(var ii=0;ii<imgs.length;ii++){imgs[ii].addEventListener('error',function(){this.style.display='none';},{once:true});if(imgs[ii].complete&&imgs[ii].naturalWidth===0)imgs[ii].style.display='none';}
```

## Owner patch C — استبدال `App._img(code)` كاملة

**المحدد الحالي قرب السطر 585:** `var url = ITEMS_IMAGE_CACHE[code];` ثم إدراج `url` مباشرة داخل `src`، مع `onerror` inline. استبدل الدالة كلها بهذه النسخة:

```js
    _img: function(code){
        var rawUrl = String(ITEMS_IMAGE_CACHE[code] || '').trim();
        var isHttpUrl = /^https?:\/\/[^\/?#\s"'<>]+(?:[\/?#][^\s"'<>]*)?$/i.test(rawUrl);
        var isRootRelativeUrl = /^\/(?!\/)[^\s"'<>]*$/.test(rawUrl);
        var safeUrl = (isHttpUrl || isRootRelativeUrl) ? rawUrl : '';
        if (safeUrl) {
            safeUrl = safeUrl.replace(/&/g, '&amp;').replace(/"/g, '&quot;')
                .replace(/'/g, '&#39;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
        }
        return safeUrl
            ? '<img src="' + safeUrl + '" data-picker-safe-image="1" alt="" class="w-14 h-14 rounded-2xl object-cover border-2 border-white shadow-sm">'
            : '<div class="w-14 h-14 bg-gradient-to-br from-slate-100 to-slate-200 rounded-2xl flex items-center justify-center text-slate-400"><i class="fa-solid fa-box"></i></div>';
    },
```

يُقبل رابط HTTP(S) صحيح أو مسار نسبي يبدأ بشرطة مائلة واحدة؛ تُرفض `javascript:`, `data:`, `//host`، والمسافات/الاقتباسات وعلامات الزاوية داخل الرابط. لا يوجد inline event handler. يربط Patch B حدث الخطأ بالصورة بعد عرض المعاينة، ويخفي الصورة التالفة لتظهر أيقونة الصنف.

## Owner patch D — استبدال `App.showItemDetail(code, name, unit, qty, desc)` كاملة

**المحدد الحالي قرب السطر 590:** `showItemDetail: function(code, name, unit, qty, desc)`. العيب هو إدراج `name/code/unit/desc` ورابط الصورة داخل HTML دون escaping/whitelist. استبدل الدالة كاملة:

```js
    showItemDetail: function(code, name, unit, qty, desc){
        function esc(value) {
            return String(value == null ? '' : value).replace(/&/g, '&amp;')
                .replace(/</g, '&lt;').replace(/>/g, '&gt;')
                .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
        }
        var rawUrl = String(ITEMS_IMAGE_CACHE[code] || '').trim();
        var validHttp = /^https?:\/\/[^\/?#\s"'<>]+(?:[\/?#][^\s"'<>]*)?$/i.test(rawUrl);
        var validRoot = /^\/(?!\/)[^\s"'<>]*$/.test(rawUrl);
        var safeUrl = validHttp || validRoot ? rawUrl : '';
        if (safeUrl) {
            safeUrl = safeUrl.replace(/&/g, '&amp;').replace(/"/g, '&quot;')
                .replace(/'/g, '&#39;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
        }
        var n = Number(qty);
        if (!isFinite(n)) n = 0;
        var imageHtml = safeUrl
            ? '<div class="relative w-full h-80 bg-white rounded-2xl mb-4 shadow-sm overflow-hidden"><div class="absolute inset-0 flex items-center justify-center text-slate-400"><i class="fa-solid fa-box text-4xl"></i></div><img data-picker-detail-image="1" src="' + safeUrl + '" alt="" class="absolute inset-0 w-full h-full object-contain"></div>'
            : '<div class="w-full h-80 bg-white rounded-2xl flex items-center justify-center text-slate-400 mb-4"><i class="fa-solid fa-box text-4xl"></i></div>';
        Swal.fire({
            html: '<div class="text-right">' + imageHtml +
                '<h3 class="font-black text-xl text-slate-800 mb-2">' + esc(name) + '</h3>' +
                '<div class="space-y-2 text-sm">' +
                '<div class="flex justify-between"><span class="text-slate-400">الكود</span><span class="font-bold text-slate-600">' + esc(code) + '</span></div>' +
                '<div class="flex justify-between"><span class="text-slate-400">الوحدة</span><span class="font-bold text-slate-600">' + esc(unit || 'حبة') + '</span></div>' +
                '<div class="flex justify-between"><span class="text-slate-400">الكمية المطلوبة</span><span class="font-bold text-indigo-600 text-lg">' + n + '</span></div></div>' +
                (desc ? '<p class="text-sm text-slate-500 mt-3 pt-3 border-t border-slate-100">' + esc(desc) + '</p>' : '') + '</div>',
            width: 'min(92vw, 560px)',
            showCloseButton: true,
            showConfirmButton: false,
            customClass: { popup: '!rounded-3xl !p-5', closeButton: '!text-slate-300 !text-lg' },
            didOpen: function() {
                var popup = Swal.getPopup();
                var image = popup ? popup.querySelector('[data-picker-detail-image]') : null;
                if (image) {
                    image.addEventListener('error', function() { image.style.display = 'none'; }, { once: true });
                    if (image.complete && image.naturalWidth === 0) image.style.display = 'none';
                }
            }
        });
    },
```

هذه النسخة لا تحتوي `onerror` داخل سلسلة HTML، وتهرب جميع الحقول النصية وتتحقق من URL. لا تغيّر وظيفة النافذة أو عقد الكميات.


## Owner patch E — preserve broken-image fallback in active Picking session

**Why this patch is required:** `App._img(code)` is also called by `App.renderActiveSession()`, not only by the preview. Patch C deliberately removes inline `onerror`; without this matching event binding, a broken image in the active session would lose the old fallback behavior. This patch preserves the existing active-session UI and timer.

**File/function:** `companies/company-1/warehouse/picker.html`, `App.renderActiveSession()`, around current line 660. Replace the current single line:

```js
        safeHTML(byId('mainContent'), html); this.startTimer();
```

**With this complete replacement:**

```js
        safeHTML(byId('mainContent'), html);
        var activeImages = byId('mainContent').querySelectorAll('img[data-picker-safe-image]');
        for (var imageIndex = 0; imageIndex < activeImages.length; imageIndex++) {
            activeImages[imageIndex].addEventListener('error', function() {
                this.style.display = 'none';
            }, { once: true });
            if (activeImages[imageIndex].complete && activeImages[imageIndex].naturalWidth === 0) {
                activeImages[imageIndex].style.display = 'none';
            }
        }
        this.startTimer();
```

This is a fallback wiring change only. It does not change the active Picking session data, quantities, notes, or timer lifecycle.

## 8. ما يجب إبقاؤه بلا تغيير

- لا تعديل لـ`loader.html` أو `main.html` أو `core.js`.
- لا تحويل Picker إلى `RW_Auth` ضمن هذه المهمة؛ اختلاف المصادقة بين Picker/Loader دين معماري منفصل.
- لا تغيير لنداءات `start-picking`, `complete-picking`, `reopen-picking` أو إضافة Edge Function.
- لا تغيير لـ`picker_id`, `companyId`, `pubUserId`, حالات الرانشيت، `operation_id`, أو استعادة Dexie.
- لا كتابة إلى المخزون أو `allocated_qty` أو دفاتر الحسابات.
- لا إعلان بأن بقية HTML المبني نصيًا في القوائم أو الجلسة النشطة صار آمنًا بالكامل؛ هو خارج هذا التغيير ويحتاج مراجعة أمان منفصلة. على وجه الخصوص، `App.editPickedItem()` ما زالت تبني عنوان/وصف/ملاحظات وصورة داخل HTML مباشرة، وهي مخاطرة مجاورة مهمة يجب أن تكون وحدة أمان مستقلة؛ لا توسّع رقعة المعاينة لإعادة كتابتها ضمن المهمة الحالية.

## 9. الاختبار المطلوب بعد دمج المالك

نفّذ الاختبار في Staging/بيئة معتمدة، وليس على بيانات Production:

1. أعِد جلب Picker وسجّل SHA الجديدة. إن اختلف SHA الأساس، أعد تحديد مواضع التعديل قبل اللصق.
2. افحص Parsing لملف Picker كاملًا؛ افحص خصوصًا Regex وتكوين سلسلة HTML، إذ لم يُشغّل Browser E2E في هذه الدورة.
3. اختبر `Open` و`Confirmed`: رأس وتاريخ وحالة، عدد الأصناف، إجمالي الكمية المطلوبة والقيمة التقديرية، بطاقات الصور/الكود/الوحدة/الكميات/السعر.
4. اختبر `Picked`: معاينة قراءة فقط، ولا يظهر زر بدء التحضير. اختبر الرانشيت الخالي دون انهيار الواجهة.
5. اختبر الوصف من relation؛ أدخل قيم اختبار نصية تحتوي `< > & " '`، وتأكد أنها نص وليست HTML أو حدثًا.
6. اختبر روابط صور HTTP(S) والمسار النسبي، ثم `javascript:`, `data:`, `//host`، وروابط مكسورة؛ لا تظهر أخطاء parsing ولا ينكسر تخطيط الصفحة.
7. اختبر الرجوع، النقر على بطاقة الصنف وEnter/Space، واستعادة جلسة Picking النشطة وDexie كما كانت.
8. اختبر مستخدمًا مصرحًا وآخر غير مصرح ونطاق شركة صحيحًا؛ لا تعتمد على Owner فقط.
9. قارن `stock_branches.qty`, `allocated_qty`, و`inventory_log` قبل/بعد مجرد فتح المعاينة؛ يجب ألا يتغير أي منها.
10. افحص الهاتف وسطح المكتب وConsole/Network. بعد ذلك طابق HTML المنشور من Cloudflare مع Git ونفّذ Browser E2E موثقًا.

**Rollback:** عند خطأ parsing أو أثر غير متوقع، أوقف نشر Picker وأعد الملف إلى النسخة السابقة فقط بعد إثبات أن التغيير هو السبب. لا يوجد rollback لقاعدة البيانات أو Edge لهذه المهمة لأنهما لم يتغيرا.

## 10. الإغلاق والحالة الحقيقية

**منجز:** إعادة جلب المصدر، قراءة Loader وPicker الحاليين كاملين، مقارنة المعاينة الجديدة في Loader، قراءة تاريخ Picker ذي الصلة، والتحقق من عقد Production المذكور أعلاه، وتحديد الأسباب والجراحة المطلوبة.

**غير منجز:** تطبيق المالك للرقع، نشر Picker، إثبات تطابق HTML المنشور مع Git، واختبارات المتصفح E2E. لم أعدّل ملفات التطبيق أو Production، ولم أنشئ/أحذف بيانات اختبار.

`ROOT CAUSE VERIFIED / OWNER PATCH PREPARED / SOURCE CHANGE NOT APPLIED / DEPLOYMENT UNKNOWN / BROWSER E2E NOT RUN / NOT CLOSED`

### نقطة الاستئناف الدقيقة

الملف الوحيد: `companies/company-1/warehouse/picker.html`. SHA الأساس: `d483bd15b36585b975b63c2ef641481a01d5d084`. بالترتيب: Patch A ثم A2 ثم B ثم C ثم D ثم E من هذا التقرير، ثم syntax + Staging tests + Cloudflare served artifact + Browser E2E. لا تستخدم كتلة Patch D التاريخية، ولا تلمس Loader أو main أو Core لهذه الفجوة.

# END OF CONSOLIDATED REPORT475
