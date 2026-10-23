# Report485 — التحقيق الجنائي في تكامل معاينة الرانشيت بين Picker وLoader

**التاريخ:** 2026-10-24  
**النطاق:** فحص كامل لمصدري Picker وLoader، تاريخ التغيير، عقد قاعدة البيانات، أدلة Runtime، وتجهيز تعديل جراحي للمالك.  
**الحالة:** ROOT CAUSE CONFIRMED / SURGICAL OWNER PATCH READY / NO OPERATIONAL SOURCE CHANGE / NOT DEPLOYED / NOT CLOSED.

## 1. PRE-CHANGE SELF-AUDIT

- **Business Understanding:** Picker يراجع الأصناف والكميات المطلوبة قبل التحضير؛ Loader يعرض الأصناف بعد التحضير ويعتمد في حساب التحميل على qty_picked. لا يجوز نقل دلالة الكمية المحضّرة إلى شاشة Picker أو تغيير دورة الحالة.
- **Architecture Understanding:** واجهتا HTML مستقلتان تتصلان مباشرة بـ Supabase REST. Picker يستخدم Supabase client محليًا وDexie لاستعادة مسودة التحضير؛ Loader يستخدم النواة المشتركة core.js وRW_ImageCache. المعاينة قراءة فقط ولا ينبغي أن تغيّر الكمية الفعلية أو المحجوزة أو سجل الحركة.
- **Database Understanding:** فحص PostgreSQL Production أثبت وجود FK من run_sheet_details.item_id إلى items.id. عمود description موجود في items وليس في run_sheet_details؛ لذلك قراءة items[i].description من سجل التفاصيل لا يمكن أن تجلب الوصف.
- **Historical Understanding:** أُعيد جلب النسختين التاريخيتين من مستودع rawaie-erp-review؛ لم يُعامل أي تقرير سابق كدليل منفرد.
- **Production Understanding:** قراءة مباشرة من مشروع Supabase fiilmooggumokxanwiyx أعادت في 2026-10-23 23:23:25 UTC: PostgreSQL 17.6، items=18، run_sheet_details=12، runsheets=2، والحالات المرصودة Picked=2. أُعيد فحص مخطط العلاقة وامتيازات التحديث والسجلات.
- **Current Understanding:** جُلب الملفان كاملين من erp-frontend/main؛ لم يتغير SHA الخاص بـ Picker أو Loader عن نقطة التحقق السابقة. آخر commit في التطبيق غيّر loader.html فقط.
- **Execution Confidence:** مرتفعة في التشخيص وتحديد الرقعة المصدرية؛ لا تكفي لإعلان الإغلاق لأن المالك لم يطبق الرقعة، ولا توجد بصمة مثبتة لملفات Cloudflare المنشورة أو browser E2E.

### سجل التحقق

| المصدر | ما فُتح وفُحص | النتيجة |
|---|---|---|
| Operational Git | erp-frontend/main: picker.html كاملًا، 1,058 سطرًا | SHA d483bd15b36585b975b63c2ef641481a01d5d084 |
| Operational Git | erp-frontend/main: loader.html كاملًا، 332 سطرًا | SHA 97b83d68a683df77c1e0557838c24a1b4fb65169 |
| Git history | commit 152e5b1d22aab94d2cf01070778b357df4701aff وdiff والـparent | التغيير الأخير أعاد بناء معاينة Loader فقط |
| Shared dependency | core.js، بما فيه RW_ImageCache | SHA ff2f581d9900543c16f7cb026e13446520c0329d |
| Historical repository | PWA/warehouse/picker.html | SHA 7626ba320021a607854bf219f4bacd81fc3d1d92، 623 سطرًا |
| Historical repository | PWA/warehouse/loader.html | SHA 7e61b04d0d9a480d43763e8b7b21f9cbed78409a، 266 سطرًا |
| Production SQL | الجداول، الأعمدة، FK، الامتيازات والسياسات | تمت القراءة المباشرة أدناه |
| Production logs | REST requests من rawaea-erp.pages.dev | توجد طلبات GET ناجحة؛ لا تثبت وحدها أي نسخة HTML أو أي صفحة بعينها |
| Browser/Cloudflare artifact | تعذر إثبات بصمة HTML المنشور أو browser E2E بهذه الأدوات | UNKNOWN — لا ادعاء بالنشر أو التطابق |

## 2. LIVE PRODUCTION SNAPSHOT

**المشروع:** SMART ERP / fiilmooggumokxanwiyx  
**وقت قراءة SQL:** 2026-10-23 23:23:25 UTC؛ فحص join إضافي عند 23:25:08 UTC.  
**PostgreSQL:** 17.6.

| فحص مباشر | النتيجة |
|---|---|
| public.items | 18 صفًا |
| public.run_sheet_details | 12 صفًا |
| public.runsheets | صفّان |
| حالات runsheets المرصودة | Picked: 2 |
| items.description / items.image_url | موجودان |
| run_sheet_details.description / run_sheet_details.notes | غير موجودين |
| FK run_sheet_details.item_id → items.id | موجود: run_sheet_details_item_id_fkey |
| FK run_sheet_details.runsheet_id → runsheets.id | موجود: run_sheet_details_runsheet_id_fkey |
| تفاصيل مرتبطة بالصنف | 12/12 |
| تفاصيل ذات وصف غير فارغ من items | 4/12 |
| تفاصيل ذات صورة من items | 12/12 |
| unit_price وqty_ordered وqty_picked غير فارغة | 12/12 لكل منها |
| UPDATE grants على run_sheet_details | postgres وservice_role فقط |
| RLS policies على run_sheet_details | SELECT للمستخدم authenticated؛ لم تظهر سياسة UPDATE |

### Edge inventory المباشر ذو الصلة

من list_edge_functions في Production وقت هذه المراجعة:

| Function | Version | Status | verify_jwt | ezbr_sha256 |
|---|---:|---|---|---|
| start-picking | 35 | ACTIVE | true | fca0377fce2d02d52a17bdbbdd98cfe9cc449d052533df0a3b021be11c79914a |
| complete-picking | 18 | ACTIVE | true | 14b4d650253e73abc7c7a1b1f25a8674849c11e32d21ae9928701f19705b0537 |
| start-loading | 5 | ACTIVE | true | afcfe32707382c57a15ebb744dec61e95a4079abb9ee8d32f479f322091230c7 |
| complete-loading | 11 | ACTIVE | true | c0ca692a29d14d64ec3729ae4bd12b9b84268e826ffc1c6993a48617b552b286 |

لا يتطلب خلل العرض الحالي تغيير هذه Edge Functions أو RPC أو مخطط قاعدة البيانات. ولا تُعد هذه اللقطة إثباتًا على تطابق حزمة Edge مع Git؛ إنما هي قراءة مباشرة للـRegistry.

### Production logs

أظهرت سجلات Supabase طلبات ناجحة من origin ‏https://rawaea-erp.pages.dev، منها:

- 2026-10-23T09:14:43.233Z — GET /rest/v1/run_sheet_details?select=*&runsheet_id=… — HTTP 200.
- 2026-10-23T09:14:42.723Z — GET /rest/v1/runsheets?select=*&runsheet_code=… — HTTP 200.
- 2026-10-23T09:16:59.741Z — GET على runsheets مع run_sheet_details(count) — HTTP 200.

هذه السجلات تتوافق مع أشكال الاستعلامات الموجودة في ملفات الواجهة، لكنها لا تحدد وحدها إن كان الطلب صادرًا من Picker أم Loader، ولا تثبت SHA للـHTML الذي خدمه Cloudflare. لا تُرفع هذه الأدلة إلى مستوى browser E2E أو deployment parity.

## 3. Source and history reconciliation

### Operational Git

- التطبيق التشغيلي هو المستودع papamohammed77-glitch/erp-frontend، الفرع main.
- HEAD: 152e5b1d22aab94d2cf01070778b357df4701aff.
- Parent: e69c9af4b56d99ba29a4fa74282f78438b9f7010.
- commit HEAD عنوانه Refactor preview modal HTML generation؛ والـdiff يغيّر loader.html فقط.
- Loader الحالي 332 سطرًا؛ Picker الحالي 1,058 سطرًا.
- لا توجد في Picker الحالي رقع Report484 A/A2/B/C/D/E؛ بقيت الاستعلامات وطرق العرض القديمة على SHA الحالي المذكور.

### Historical baseline

- Picker التاريخي في rawaie-erp-review/PWA/warehouse/picker.html: SHA 7626ba320021a607854bf219f4bacd81fc3d1d92، 623 سطرًا.
- Loader التاريخي في rawaie-erp-review/PWA/warehouse/loader.html: SHA 7e61b04d0d9a480d43763e8b7b21f9cbed78409a، 266 سطرًا.
- النسخة التاريخية تثبت أن Picker كان يضم أصلًا معاينة/تفاصيل للصنف؛ لكنها لا تبرر استبدال الملف الحالي أو نسخ التطبيق كاملًا.
- التغيير الأخير في Loader أعاد تصميم معاينته إلى بطاقات متجاوبة وملخصات كمية/قيمة. هذا تحسين مرجعي يمكن مطابقة ما يلائم Picker معه، وليس سببًا لنسخ منطق التحميل إلى التحضير.

## 4. Root cause — مثبت

في Picker الحالي:

1. يبدأ استعلام تفاصيل الرانشيت عند السطر 517 تقريبًا بـ select('*') من run_sheet_details فقط.
2. عند بناء الجلسة النشطة، يقرأ الكود description من سجل التفاصيل عند السطر 532، لكن Production يثبت أن العمود غير موجود في هذا الجدول.
3. المعاينة غير النشطة تبدأ عند السطر 570، وتعرض عنوانًا وقائمة أصناف مقتضبة بدل ملخصات Loader المتجاوبة.
4. HTML الخاص بالبطاقات يمرر بيانات من قاعدة البيانات إلى inline onclick ويُدخل بعض النصوص مباشرة دون escaping شامل.
5. _img عند السطر 585 يُدخل image_url داخل src ويستخدم inline onerror؛ وshowItemDetail عند السطر 590 يضع الاسم والكود والوحدة والوصف ورابط الصورة في HTML دون escaping/URL validation.
6. renderActiveSession عند السطر 660 يستخدم _img؛ لذلك إزالة inline onerror من _img تتطلب ربط fallback بديل بعد العرض حتى لا تتراجع الجلسة النشطة.

العلاقة الصحيحة للوصف مثبتة من Production FK: run_sheet_details.item_id → items.id. لا حاجة لإضافة description إلى run_sheet_details أو منح authenticated صلاحية UPDATE.

## 5. Contract boundary: ما يجب الحفاظ عليه

- Picker: يعرض الكمية المطلوبة qty_ordered؛ القيمة التقديرية في معاينة Picker تُحسب من qty_ordered × unit_price.
- Loader: يعرض qty_picked بوصفها الكمية المحضّرة التي يستند إليها التحميل.
- معاينة Picker يجب أن تكون قراءة فقط؛ فتحها لا يغيّر stock_branches.qty أو allocated_qty أو inventory_log.
- تبقى صلاحية بدء التحضير محصورة في Open وConfirmed. حالات Picking وPicked وما بعدها لا تعرض زر بدء التحضير.
- يجب الحفاظ على company_id scoping، pubUserId، استعادة Dexie، operation_id/Idempotency، إلغاء التحضير وإعادة فتحه، ومؤقت الجلسة.
- لا تعديل على main.html أو loader.html أو core.js ضمن إصلاح Picker المطلوب.
- لا تعديل Production أو Edge/RPC لهذه الفجوة المرئية.

## 6. LOSS / GAIN / RESPONSIBILITY MATRIX

| المسؤولية | الحالة | الدليل/الإجراء |
|---|---|---|
| قراءة الرانشيت مع company scope | RETAINED | موجودة في Picker الحالي؛ لا تغيير |
| ملكية جلسة Picking/حالة الرانشيت | RETAINED | فحوص picker_id/status موجودة؛ لا تغيير |
| استعادة مسودة Dexie | RETAINED | مسار restore/save الحالي خارج منطقة الاستبدال |
| وصف الصنف | MISSING في الاستعلام الحالي | عمود الوصف موجود في items فقط؛ ضم FK مطلوب |
| معاينة مفصلة ومتجاوبة قبل التحضير | MISSING جزئيًا | Loader الحالي يعرض ملخصات وبطاقات أكثر اكتمالًا |
| حماية النصوص الديناميكية في المعاينة | HARDENED مطلوب | escaping في الرقعة المقترحة |
| التحقق من image URL ومعالجة الصورة المعطوبة | HARDENED مطلوب | رقعة _img وربط أحداث الخطأ |
| تغيير الكميات أو حركة المخزون عند المعاينة | INTENTIONALLY REMOVED / MUST REMAIN ABSENT | المعاينة قراءة فقط |
| تعديل Core أو Edge أو DB | INTENTIONALLY REMOVED من هذه الوحدة | لا حاجة مثبتة لذلك |
| نسخة Cloudflare المنشورة | UNKNOWN | لا توجد بصمة نشر/HTML مباشرة مثبتة |
| Browser E2E بعد الرقعة | NOT STARTED | الرقعة لم تُطبق بعد |

## 7. OWNER-ONLY SURGICAL PATCH — لا تطبّق على ملف تغيّر SHA الخاص به

**الملف:** companies/company-1/warehouse/picker.html  
**SHA الأساس المطلوب:** d483bd15b36585b975b63c2ef641481a01d5d084  
**ممنوع على المساعد تعديل الملف التشغيلي مباشرة.** المالك هو الذي يطبق التعديل. إذا تغيّر SHA قبل التطبيق، أعد قراءة المصدر وحدد الفروق أولًا.

### Patch A — ضم وصف الصنف في استعلام التفاصيل

**المحدد الحالي:** .from('run_sheet_details') متبوعًا بـ .select('*') في App.openRunsheet، حاليًا قرب السطر 517.

استبدل:

~~~js
supabase
    .from('run_sheet_details')
    .select('*')
    .eq('runsheet_id', rs.id)
~~~

بـ:

~~~js
supabase
    .from('run_sheet_details')
    .select('*, items!run_sheet_details_item_id_fkey(description)')
    .eq('runsheet_id', rs.id)
~~~

لا تغيّر بقية شروط الملكية أو الحالة أو معالجة الخطأ.

### Patch A2 — إصلاح قراءة الوصف في الجلسة النشطة

**المحدد الحالي:** description: items[i].description || ''، حاليًا قرب السطر 532.

استبدل هذا الحقل وحده بـ:

~~~js
description: (items[i].items && items[i].items.description) || ''
~~~

العلاقة المستخدمة هي FK المثبتة في Production؛ لا تضف عمودًا ولا migration.

### Patch B — استبدال كتلة معاينة Picker غير النشطة فقط

**بداية الاستبدال:** كتلة var html = ''; قرب السطر 570 التي تلي فرع الجلسة النشطة الذي ينتهي بـ return.  
**نهاية الاستبدال:** سطر safeHTML(byId('mainContent'), html); قرب السطر 580، شاملًا.  
**لا تغيّر الأقواس أو إغلاقات then الخارجية.**

استبدل الكتلة المحددة كاملة بالنص التالي:

~~~js
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
~~~

### Patch C — استبدال App._img(code) كاملة

**المحدد الحالي:** _img: function(code){ قرب السطر 585. استبدل الدالة كاملة، من تعريفها حتى الفاصلة التي تنهيها، بالنص التالي:

~~~js
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
~~~

### Patch D — استبدال App.showItemDetail(code, name, unit, qty, desc) كاملة

**المحدد الحالي:** showItemDetail: function(code, name, unit, qty, desc){ قرب السطر 590.

~~~js
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
~~~

### Patch E — الحفاظ على fallback للصورة في جلسة التحضير النشطة

**المحدد الحالي:** safeHTML(byId('mainContent'), html); this.startTimer(); قرب السطر 660. استبدله فقط بهذا:

~~~js
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
~~~

Patch E مطلوب لأن _img مستخدمة في renderActiveSession أيضًا. لا يغيّر الكميات أو الملاحظات أو المؤقت.

## 8. ملاحظات نطاق منفصلة لا يجوز إخفاؤها

1. core.js الحالي يعيد HTML للصورة من RW_ImageCache.getImageHTML بإدراج URL مباشرة مع inline onerror. Loader يستدعيه في المعاينة وreadonly والجلسة النشطة. هذه فجوة أمان منفصلة، ولها رقعة Loader-local في Report484 Patch G؛ لا تُطبق ضمن إصلاح Picker لأن loader.html ملف مرجعي ومحظور تعديله في هذه الوحدة.
2. App.editPickedItem في Picker يبني HTML للصورة والاسم والوصف والملاحظات مباشرةً. الرقع A–E تعالج معاينة Picker ودالة تفاصيل الصنف وfallback الذي يتأثر بتغيير _img؛ لكنها لا تمثل تدقيقًا أمنيًا شاملًا لكل interpolation في التطبيق. لا يُعلن إغلاق شامل لأمن HTML بسبب هذه الرقع.
3. يوجد تعارض مستقل في عقد التحميل: Loader يرسل عناصر بكمية محمّلة صفر وملاحظات، لكن Production complete-loading v11 وcomplete_runsheet_loading يرفضان الكمية صفرًا ولا يثبتان الملاحظات؛ كما أن run_sheet_details.notes غير موجود في مخطط Production الحالي. هذا خارج نطاق إصلاح معاينة Picker ويظل OPEN، ولا يبرر تغيير Production ضمن هذه المهمة.

## 9. خطة الاختبار بعد تطبيق المالك

لا يوجد ادعاء بأن الاختبارات التالية نُفذت بعد التعديل؛ الرقعة لم تُطبق بعد.

1. إعادة جلب Picker والتأكد من بقاء SHA الأساس؛ إذا تغيّر، لا تطبق الرقع القديمة.
2. فحص JavaScript الكامل للملف بعد التطبيق، وليس المقاطع فقط.
3. اختبار الحالات Open وConfirmed وPicking وPicked: زر بدء التحضير يظهر فقط في Open/Confirmed، والجلسة النشطة واستعادة Dexie لا تتغيران.
4. إثبات عرض الوصف عبر FK relation، وظهور عدد الأصناف والكمية المطلوبة والسعر والقيمة التقديرية، مع empty state صحيح.
5. اختبار النقر وEnter وSpace على بطاقات الأصناف، والعودة، والصور المكسورة.
6. اختبار نصوص تحتوي < > & " ' وروابط صور HTTPS ومسارات root-relative؛ رفض javascript: وdata: و//host والروابط غير الصالحة.
7. اختبار مستخدمين من شركتين والتحقق من عدم تسريب البيانات؛ الحفاظ على company_id scoping.
8. مقارنة stock_branches.qty وallocated_qty وinventory_log قبل وبعد فتح المعاينة؛ المتوقع صفر تغيير. لا تنشئ بيانات اختبار في Production.
9. Staging معزول ونشط فقط. الحالة التاريخية لبيئة rawaea-staging هي INACTIVE، ولم يثبت أنها أصبحت نشطة في هذه الدورة.
10. النشر عبر مسار Cloudflare الحالي، ثم إثبات الـserved artifact والـcommit، ثم browser E2E مصادق عليه. سجلات REST وحدها لا تكفي.
11. بعد الاختبارات، حدّث CURRENT_STATE بالأدلة الجديدة. لا تسجل APPLIED أو DEPLOYED أو VERIFIED قبل حدوثها فعلًا.

## 10. SELF-AUDIT FINAL

- **What I Proved:** SHAs الحالية والتاريخية، آخر commit والـparent والـdiff، سبب فقدان الوصف، FK الفعلي، غياب عمودي description/notes من run_sheet_details، الامتيازات والسياسات، counts، Edge registry الحالية، وأشكال REST requests المسجلة.
- **What I Did Not Prove:** تطابق HTML المنشور مع Git، تطبيق المالك للرقع، Staging E2E، browser E2E، أو صفر تغيرات مخزون بعد التعديل؛ لم يكن هناك تعديل تشغيلي لاختباره.
- **What I Fixed:** لم أعدّل ملفات التشغيل أو Production. جهزت الرقعة الجراحية كاملة ووثقت الدليل في هذا التقرير.
- **What I Initially Missed:** يجب عدم اعتبار طلبات REST الناجحة دليلًا على أن HTML المنشور يطابق SHA المصدر أو على أن الطلب صدر من Picker تحديدًا.
- **What Could Still Be Wrong:** قد يتغير SHA قبل التطبيق؛ وقد توجد اختلافات بين Cloudflare artifact والمصدر؛ وقد تحتاج سياسة صور/متصفح إلى تعديل بعد الاختبار؛ كما تبقى مخاطر interpolation في editPickedItem وLoader helper خارج نطاق الرقعة الحالية.
- **Final Confidence:** عالية في السبب الجذري؛ متوسطة في الرقعة قبل اختبارها؛ غير مثبتة للنشر أو runtime بعد الإصلاح.
- **Final Closure Status:** ROOT CAUSE CONFIRMED / OWNER PATCH READY / NOT APPLIED / NOT DEPLOYED / NOT CLOSED.

## 11. الإجراء التنفيذي التالي

المالك يعيد جلب Picker. إذا بقي SHA هو d483bd15b36585b975b63c2ef641481a01d5d084، يطبق A ثم A2 ثم B ثم C ثم D ثم E على نفس الملف، ويجري اختبارات القسم 9. لا يُعدل loader.html أو core.js أو main.html في هذه الوحدة. بعد التطبيق فقط يبدأ تحقق النشر والمتصفح؛ إلى ذلك الحين تبقى الحالة NOT CLOSED.

**نهاية Report485.**


## 12. Addendum — live verification of the separate Loading contract

After drafting the main findings, the Production Edge source and PostgreSQL function body were fetched directly again to avoid relying on Report483/484 for this separate issue.

- Live Edge registry/source: complete-loading v11, ACTIVE, verify_jwt=true, ezbr_sha256 c0ca692a29d14d64ec3729ae4bd12b9b84268e826ffc1c6993a48617b552b286.
- The deployed source maps request items to only item_code and loaded_qty, then rejects any item where loaded_qty <= 0. It does not map the per-item notes field into the RPC payload.
- Live PostgreSQL definition: public.complete_runsheet_loading(uuid,uuid,jsonb,text). The function rejects each grouped request where req <= 0; the RPC payload consumed by the core is item_code/loaded_qty only. The current run_sheet_details schema also has no notes column.
- This confirms the zero-quantity/notes mismatch from live Production, not merely from an earlier report. It remains a separate business-contract issue and was not modified because this task is the Picker preview parity unit and no safe isolated E2E fixture was available.
- No Production writes or business-data mutations were performed during this additional verification.
