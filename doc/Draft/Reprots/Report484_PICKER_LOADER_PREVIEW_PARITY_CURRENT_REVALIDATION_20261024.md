# Report484 — إعادة التحقق الحالية ومجموعة التعديل الجراحي لمعاينة Picker مقابل Loader

**التاريخ:** 2026-10-24
**الحالة:** CURRENT SOURCE REVALIDATED / OWNER PATCH READY / NOT APPLIED / NOT DEPLOYED / NOT CLOSED
**النطاق:** مطابقة معاينة الرانشيت وأصنافه في `picker.html` مع مستوى العرض الحالي في `loader.html`، دون تعديل الملفين تشغيليًا من المساعد.

## 1. PRE-CHANGE SELF-AUDIT

- **فهم العمل:** Picker يعرض الرانشيت قبل التحضير، ويسمح ببدء التحضير فقط في Open/Confirmed؛ Loader يعرض الرانشيت بعد التحضير في Picked/Loading. لا يجوز نسخ دلالات الكميات بين المرحلتين: Picker يلخص `qty_ordered × unit_price`، بينما Loader يعرض الكمية المحضّرة `qty_picked`.
- **المعمارية:** المسار التشغيلي Confirmed Orders → Runsheet → Picking/Reservation → Loading → Delivery/Returns → Stock/Ledger/Audit. المعاينة قراءة فقط ولا يجوز أن تغيّر المخزون أو الحجز أو سجل الحركة.
- **Production:** تحقق مباشر قراءة فقط في Supabase `fiilmooggumokxanwiyx` بتاريخ 2026-10-23 23:06:38 UTC، PostgreSQL 17.6. `items=18`, `run_sheet_details=12`, `runsheets=2`؛ كل الحالات المرصودة `Picked=2`. علاقة `run_sheet_details.item_id → items.id` موجودة باسم `run_sheet_details_item_id_fkey`، وجدول `items` يحوي `description` و`image_url` بينما `run_sheet_details` لا يحوي `description`. تحديث `run_sheet_details` غير ممنوح لـauthenticated، ولا توجد سياسة UPDATE لذلك الجدول.
- **Production Edge:** `start-picking v35`, `complete-picking v18`, `start-loading v5`, `complete-loading v11`، كلها ACTIVE و`verify_jwt=true`. لم تكن هناك حاجة لتعديل Edge/RPC/Schema لهذه الفجوة المرئية.
- **المصدر الحالي:** `erp-frontend` على `main`، HEAD `152e5b1d22aab94d2cf01070778b357df4701aff`، والـparent `e69c9af4b56d99ba29a4fa74282f78438b9f7010`. Loader SHA `97b83d68a683df77c1e0557838c24a1b4fb65169` (332 سطرًا)، Picker SHA `d483bd15b36585b975b63c2ef641481a01d5d084` (1058 سطرًا)، Core SHA `ff2f581d9900543c16f7cb026e13446520c0329d`.
- **Historical:** أُعيد جلب Picker التاريخي SHA `7626ba320021a607854bf219f4bacd81fc3d1d92` (623 سطرًا) وLoader التاريخي SHA `7e61b04d0d9a480d43763e8b7b21f9cbed78409a` (266 سطرًا). سجل Report477 يثبت أسباب الحفاظ على Dexie، نطاق الشركة، التحقق من ملكية الجلسة، `operation_id` وIdempotency-Key وتدفق الكميات.
- **الثقة التنفيذية:** عالية لتحديد النقص وصياغة الرقعة استنادًا إلى Git وProduction؛ غير كافية لإعلان الإغلاق لأن تعديل المالك والنشر واختبار المتصفح غير مثبتة.

### CONFIRMED
- تفاصيل Picker تستخدم `.select('*')` ولا تجلب وصف الصنف المرتبط.
- التعيين النشط يقرأ `items[i].description` من جدول لا يملك هذا العمود.
- معاينة Picker الحالية مختصرة، وتفتقر إلى عرض الوصف وملخص الكمية/القيمة وبطاقات التفاصيل المتجاوبة الآمنة؛ وتستخدم حقن HTML وinline handlers.
- أحدث تغيير في Loader هو إعادة بناء المعاينة داخل الصفحة، لا تعديل Picker.

### UNKNOWN / UNVERIFIED
- لم يُثبت أن HTML المنشور على Cloudflare يطابق بصمة Git الحالية.
- لم يُطبّق المالك الرقع بعد، ولم يُجرَ browser E2E.
- بيئة `rawaea-staging` موصوفة في أحدث سجل بأنها INACTIVE؛ لا يجوز استخدام بيانات Production الحالية كبيانات اختبار للتحضير.

## 2. القرار

**لا تغيير على Production/Supabase مطلوب لهذا الخلل المرئي.** لا تُمنح صلاحية UPDATE مباشرة على `run_sheet_details` ولا تُنشأ Edge Function جديدة. التعديل المطلوب على `picker.html` فقط ويطبقه المالك، وفق الرقع الجراحية أدناه. لا تعديل على `loader.html` أو `main.html` أو `core.js` ضمن تغيير Picker هذا.

## 3. التعديل الجراحي — النصوص الكاملة

**شرط التطبيق:** أعد جلب Picker قبل التعديل. طبّق الرقع فقط إذا بقي SHA الأساس `d483bd15b36585b975b63c2ef641481a01d5d084`. إذا تغيّر SHA، أعد المطابقة ولا تطبق أرقام الأسطر القديمة.

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
else for(var k=0;k<items.length;k++){var it=items[k]||{},desc=(it.items&&it.items.description)||'',q=Number(it.qty_ordered)||0,picked=Number(it.qty_picked)||0,p=Number(it.unit_price)||0,v=q*p;totalRequestedQty+=q;totalRequestedValue+=v;
html+='<div class="card w-full text-right mb-3 slide-in cursor-pointer" role="button" tabindex="0" data-picker-item-index="'+k+'"><div class="flex items-start gap-3"><div class="relative shrink-0 w-14 h-14 rounded-2xl overflow-hidden bg-slate-100"><div class="absolute inset-0 flex items-center justify-center text-slate-400"><i class="fa-solid fa-box"></i></div>'+self._img(it.item_code)+'</div><div class="min-w-0 flex-1"><p class="font-bold text-slate-800">'+esc(it.item_name||'')+'</p>'+(desc?'<p class="text-xs text-slate-500 mt-1">'+esc(desc)+'</p>':'')+'<p class="text-xs text-slate-400 mt-1">'+esc(it.item_code||'')+' | '+esc(it.unit||'حبة')+'</p><div class="grid grid-cols-2 sm:grid-cols-4 gap-2 mt-3 text-sm"><div class="bg-slate-50 rounded-xl p-2"><p class="text-[11px] text-slate-400">مطلوب</p><p class="font-bold">'+fmt(q)+'</p></div><div class="bg-indigo-50 rounded-xl p-2"><p class="text-[11px] text-slate-400">محضّر</p><p class="font-black text-indigo-700">'+fmt(picked)+'</p></div><div class="bg-slate-50 rounded-xl p-2"><p class="text-[11px] text-slate-400">سعر الوحدة</p><p class="font-bold">'+fmt(p)+'</p></div><div class="bg-indigo-50 rounded-xl p-2"><p class="text-[11px] text-slate-400">قيمة المطلوب</p><p class="font-black text-indigo-700">'+fmt(v)+'</p></div></div></div></div></div>';
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

## 4. الاختبارات الإلزامية بعد تطبيق المالك

1. فحص JavaScript كاملًا في `picker.html` بعد التعديل؛ لا يكفي فحص المقاطع وحدها.
2. في Staging معزول ونشط: اختبر Open وConfirmed وPicking وPicked، وتأكد أن زر بدء التحضير يظهر فقط في Open/Confirmed، وأن جلسة Picking النشطة واستعادة Dexie لم تتغيرا.
3. تحقق من وصف الصنف عبر FK relation، وعدد الأصناف، والكمية المطلوبة، والسعر، والقيمة التقديرية، والتصميم المتجاوب، والحالة الفارغة.
4. اختبر نصوصًا عدائية تتضمن `< > & \" '`، وروابط صور HTTPS ومسارات `/` صالحة، وارفض `javascript:`, `data:`, `//host`، والروابط المشوهة أو المكسورة.
5. تحقق من فتح بطاقة الصنف بالنقر وEnter وSpace، والعودة للقائمة، وصورة مكسورة في المعاينة والجلسة النشطة.
6. اختبر مستخدمًا مخولًا وآخر من شركة مختلفة؛ يجب ألا يحدث تسريب بيانات بين الشركات.
7. قارن `stock_branches.qty`, `allocated_qty`, و`inventory_log` قبل/بعد فتح المعاينة؛ المتوقع صفر تغيير. لا تنشئ fixture في Production.
8. انشر عبر مسار Cloudflare الحالي، ثم تحقق مستقلًا من HTML المنشور وارتباطه بالـcommit، ثم نفّذ اختبار متصفح مصادقًا عليه.
9. لا تعلن CLOSED قبل وجود دليل نشر/runtime، وإثبات عدم وجود بقايا اختبار، وتحديث `CURRENT_STATE.md` ببصمة المصدر ودليل التشغيل.

## 5. مسألة منفصلة لا يغلقها هذا التعديل

أثبت تقرير Report483 تعارضًا مستقلًا في عقد التحميل: Loader يرسل عناصر بكمية محمّلة صفر وملاحظات، بينما Production `complete-loading v11` و`complete_runsheet_loading` يرفضان الكمية صفرًا ولا يحفظان الملاحظات. هذه ليست مشكلة معاينة Picker ولا تُحل برقع العرض الحالية. تبقى OPEN ولا تُعدّل Production قبل خطة اختبار معزولة واختبار تعاقدي آمن.

## 6. SELF-AUDIT FINAL

- **What I Proved:** بصمات Git الحالية، الفروق الوظيفية في المعاينة، علاقة FK ووصف الصنف في Production، غياب عمود description من تفاصيل الرانشيت، وعدم وجود حاجة لتغيير قاعدة البيانات لهذا الخلل.
- **What I Did Not Prove:** تطبيق المالك للرقع، تطابق Cloudflare artifact، اختبار المتصفح E2E، أو إغلاق تعارض عقد التحميل.
- **What I Fixed:** لا تغييرات تشغيلية من المساعد؛ أعددت تغييرات جراحية كاملة قابلة للتطبيق من المالك وسجلت الحالة.
- **What I Initially Missed:** الاعتماد على تقرير سابق وحده لا يكفي؛ أُعيد التحقق من ملفات المصدر وProduction في هذه الدورة، وتبين أن HEAD وSHAs ما زالت كما هي.
- **What Could Still Be Wrong:** قد يتغير مصدر Git قبل التطبيق، أو يختلف HTML المنشور عن المصدر، أو يفشل اختبار المتصفح/الشركة/الصور؛ لذلك يجب إعادة فحص SHA ثم إثبات runtime.
- **Final Confidence:** مرتفعة في التشخيص والرقع المصدرية؛ غير كافية للإغلاق التشغيلي.
- **Final Closure Status:** `OWNER PATCH READY / NOT APPLIED / NOT DEPLOYED / NOT CLOSED`.