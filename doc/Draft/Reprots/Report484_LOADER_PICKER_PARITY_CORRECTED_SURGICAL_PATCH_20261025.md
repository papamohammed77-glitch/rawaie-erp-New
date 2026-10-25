# Report484 — إعادة تدقيق جراحية لتكامل Loader/Picker وعلاج نقص رقعة الصور والعزل

**التاريخ:** 2026-10-25  
**المستودع التشغيلي:** `papamohammed77-glitch/erp-frontend` / `main`  
**المستودع التوثيقي:** `papamohammed77-glitch/rawaie-erp-New` / `main`  
**نطاق المهمة:** `companies/company-1/warehouse/loader.html` فقط من ناحية المصدر التشغيلي  
**الحالة:** ROOT CAUSE CONFIRMED / PATCH A–F FROM REPORT482 STILL NOT APPLIED / PATCH G REQUIRED / NO PRODUCTION MUTATION / NOT CLOSED

## 1. التدقيق الذاتي قبل التعديل

- **فهم الأعمال:** Loader يعرض الرانشيتات الجاهزة `Picked` ويتيح بدء التحميل، ثم يحرر كميات التحميل وينهي الدورة. المعاينة وحدها لا يجب أن تحرك المخزون.
- **فهم المعمارية:** Loader يستعمل `core.js` للمصادقة وواجهات المستخدم والصور، بينما Picker له مسار عرض مستقل. لا يجوز نسخ Picker أو تغيير دورة التحميل.
- **فهم قاعدة البيانات:** تحقق حيًّا من Production بتاريخ `2026-10-25 13:18:30.156271+00`؛ PostgreSQL 17.6. `items` يحتوي `name, unit, description, image_url, company_id`. `run_sheet_details` لا يحتوي `description` أو `image_url`، ويرتبط بـ`items.id` عبر `run_sheet_details_item_id_fkey`. `runsheets` يحتوي `company_id, loader_id, status`. الجداول الثلاثة مفعّل عليها RLS.
- **Current Loader:** SHA `97b83d68a683df77c1e0557838c24a1b4fb65169`، 332 سطرًا.
- **Current Picker:** SHA `d483bd15b36585b975b63c2ef641481a01d5d084`، 1,058 سطرًا.
- **Core:** SHA `ff2f581d9900543c16f7cb026e13446520c0329d`.
- **Production runtime/browser:** لم يُجر اختبار Browser E2E في هذه الدورة؛ لا أدّعي تطابق HTML المنشور مع Git.
- **التعديلات:** لم يتغير أي ملف تشغيلي، ولم تُنفذ كتابة DDL/RPC/Edge أو بيانات أعمال في Production.

## 2. النتيجة الحاسمة

تقرير `Report482_LOADER_PICKER_RUNSHEET_ITEM_DETAIL_PARITY_20261023.md` يحدد رقعة A–F كاملة. إعادة جلب Loader الآن تؤكد أن بصمة المصدر ما زالت SHA المذكور أعلاه، وأن عناصر الرقعة لم تُطبّق: الاستعلامات ما زالت بلا نطاق شركة صريح، وفتح التفاصيل ما زال يستخدم `select('*')` على `run_sheet_details`، وبطاقات المعاينة لا تفتح مودال تفاصيل للصنف، ومودال التحرير يعرض صورة صغيرة.

لكن مراجعة إضافية كشفت نقصًا في الرقعة A–F نفسها: الاعتماد على `RW_ImageCache.getImageHTML(item_code)` أو الرجوع إلى `RW_ImageCache.getImageUrl(item_code)` يعيد استخدام كاش `core.js` الذي يجلب الصور من `items` دون فلتر `company_id`. مع وجود أصناف من شركات مختلفة تحمل `item_code` نفسه، قد تظهر صورة من سياق شركة أخرى. لذلك لا تكفي إضافة `company_id` لاستعلامات الرانشيت؛ يجب أن تستعمل صور التفاصيل مصدر `items` المرتبط بالرانشيت الحالي، لا الكاش العام غير المقيد.

هذا تصحيح ضروري لرقعة Report482 وليس مبررًا لتعديل `core.js` أو `picker.html` أو `main.html`.

## 3. العناصر المصدرية المعيبة الدقيقة

### العيب 1 — قائمة/بحث الرانشيتات غير مقيدة بالشركة صراحةً
- **الموضع الحالي:** Loader، السطران 100–101.
- **النص الحالي:**
```js
supabase.from('runsheets').select('runsheet_code, status, run_date, loader_id, run_sheet_details(count)').eq('status','Loading').eq('loader_id',this.currentUser.id||this.currentUser.email).order('run_date',{ascending:false}).limit(20),
supabase.from('runsheets').select('runsheet_code, status, run_date, run_sheet_details(count)').eq('status','Picked').order('run_date',{ascending:false}).limit(50)
```
- **الإجراء:** استبدالهما بنسختي A1 في Report482، اللتين تضيفان `.eq('company_id', this.currentUser.company_id)` مع الحفاظ على بقية الشروط والترتيب والحدود.
- **السبب:** فرض نطاق الشركة على مستوى الاستعلام، وعدم الاتكال على RLS وحده في عرض القوائم.

### العيب 2 — البحث لا يتحقق من خطأ الاستعلام ولا يقيد الشركة
- **الموضع الحالي:** السطر 128.
- **النص الحالي:**
```js
supabase.from('runsheets').select('runsheet_code,status,run_date,loader_id,run_sheet_details(count)').or('status.eq.Picked,status.eq.Loading').ilike('runsheet_code','%'+q.trim()+'%').limit(10).then(function(r) { s.searchResults=r.data||[]; s.renderSearchDropdown(); });
```
- **الإجراء:** استبداله كاملًا بمقطع A2 في Report482، الذي يضيف فلتر الشركة ومعالجة `r.error`.

### العيب 3 — فتح الرانشيت لا يثبت الشركة/ملكية جلسة Loading ولا يحمّل حقول الصنف المرتبطة
- **الموضع الحالي:** `App.openRunsheet` ابتداءً من السطر 141.
- **النص الحالي المميز:** `select('*').eq('runsheet_code',code)`، ثم `run_sheet_details.select('*')` في السطر 147.
- **الإجراء:** استبدال `openRunsheet` وحدها بنص B الكامل في Report482. يضيف فلتر الشركة، ومعالجة أخطاء القراءة، ويرفض فتح جلسة Loading يملكها محمّل آخر، ويجلب الوصف والصورة عبر:
```js
.select('*, items!run_sheet_details_item_id_fkey(description, image_url, name, unit)')
```
**تصحيح مهم:** استخدم قائمة الحقول أعلاه بدل الاقتصار على `description, image_url`، لأن كائن الصنف يحتاج `name` و`unit` عند الرجوع إلى بيانات `items`. هذه الأعمدة مثبتة في مخطط Production الحالي.

### العيب 4 — جلسة التحميل لا تحتفظ ببيانات العرض المرتبطة
- **الموضع الحالي:** السطران 156–158.
- **النص الحالي:**
```js
_startSession: function(code, rs, items) {
    this.session = { runsheet_code:code, runsheet_id:rs.id, start_time:rs.loader_start||new Date().toISOString(), items:[] };
    for(var i=0;i<items.length;i++) { var it=items[i]; this.session.items.push({ item_code:it.item_code, item_name:it.item_name||'', unit:it.unit||'حبة', qty_ordered:Number(it.qty_ordered)||0, qty_picked:Number(it.qty_picked)||0, qty_loaded:Number(it.qty_loaded)||0, notes:it.notes||'' }); }
    this.renderActiveSession();
},
```
- **الإجراء:** استبدال الدالة بنسخة C في Report482، مع إبقاء `description` و`image_url` من علاقة الصنف؛ لا تستخدم كاش الصور العام كـfallback.

### العيب 5 — بطاقات المعاينة والجلسة النشطة والقراءة فقط تتجاوز مصدر الصورة المرتبط
- **المواضع الحالية:** الأسطر 207 و248 و271، وكذلك السطر 281 في مودال تحرير الكمية.
- **النصوص الحالية المميزة:**
```js
RW_ImageCache.getImageHTML(it.item_code)
RW_ImageCache.getImageHTML(it.item_code,'w-20','h-20')
```
- **السبب:** `RW_ImageCache.loadAll()` في `core.js` يقرأ `items` دون `company_id`؛ استخدامه هنا لا يضمن صورة من شركة الرانشيت نفسه.
- **الإجراء:** أضف المساعد المحلي G أدناه داخل كائن `App`، واستبدل نداءات الكاش في هذه الشاشات به. لا تعدّل `core.js`.

## 4. الرقعة الإضافية G — مساعد صور محلي مرتبط بسجل الصنف

أضف هذه الدالة داخل كائن `App`، قبل `_startSession` أو بعده، مع مراعاة الفاصلة الفاصلة بين خصائص الكائن:

```js
_itemImageHTML: function(item, widthClass, heightClass, fitClass) {
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

    if (validUrl) {
        return '<img src="' + esc(rawUrl) + '" alt="' +
            esc((item && item.item_name) || (product && product.name) || '') +
            '" class="' + w + ' ' + h + ' rounded-2xl ' + fit +
            ' border-2 border-white shadow-sm" ' +
            'onerror="this.onerror=null;this.classList.add(\'hidden\');' +
            'if(this.nextElementSibling)this.nextElementSibling.classList.remove(\'hidden\')">' +
            '<div class="hidden ' + w + ' ' + h +
            ' bg-gradient-to-br from-slate-100 to-slate-200 rounded-2xl ' +
            'flex items-center justify-center text-slate-400">' +
            '<i class="fa-solid fa-box"></i></div>';
    }

    return '<div class="' + w + ' ' + h +
        ' bg-gradient-to-br from-slate-100 to-slate-200 rounded-2xl ' +
        'flex items-center justify-center text-slate-400">' +
        '<i class="fa-solid fa-box"></i></div>';
},
```

ثم طبّق الاستبدالات التالية حرفيًا:

**G1 — معاينة الرانشيت، السطر 207:**
```js
h += '<div class="shrink-0">' + self._itemImageHTML(it, 'w-14', 'h-14') + '</div>';
```

**G2 — شاشة القراءة فقط، داخل حلقة السطر 248:**
استبدل `RW_ImageCache.getImageHTML(it.item_code)` بـ:
```js
App._itemImageHTML(it, 'w-14', 'h-14')
```
ويجب أن تظل حقول النص في هذه الشاشة مهربة HTML عند عرضها؛ لا توسّع هذا التغيير إلى إعادة كتابة الدالة إلا إذا كان اختبار XSS يثبت الحاجة.

**G3 — الجلسة النشطة، داخل حلقة السطر 271:**
استبدل `RW_ImageCache.getImageHTML(it.item_code)` بـ:
```js
s._itemImageHTML(it, 'w-14', 'h-14')
```

**G4 — مودال تحرير الكمية:** طبّق نص F في Report482، لكن احذف fallback إلى `RW_ImageCache.getImageUrl(it.item_code)`، واجعل مصدر الصورة `it.image_url` فقط؛ فهو يُملأ من علاقة الصنف بعد تطبيق B وC. استخدم `s._itemImageHTML(it, 'w-full max-w-xs', 'h-72', 'object-contain')` بدل صورة الكاش، مع إبقاء حقول الكمية والملاحظات والتحذيرات وسلوك الحفظ دون تغيير في هذه الرقعة.

**G5 — بطاقات المعاينة:** طبّق D1 وD2 وD3 في Report482، مع استخدام `self._itemImageHTML(it, 'w-14', 'h-14')` في محتوى البطاقة. لا تضف `onclick` ديناميكيًا إلى بيانات قاعدة البيانات؛ اربط الأحداث عبر `addEventListener` كما في D3.

## 5. ما لا يدخل في هذه الرقعة

- لا تعديل على `picker.html` أو `main.html` أو `core.js`.
- لا تغيير في Edge Functions أو RPC أو مخطط Production.
- لا تغيير في Lifecycle أو الكميات أو الحجز أو الحركة الفعلية.
- مشكلة حفظ `notes` ونتيجة تحديث `qty_loaded` التي لا يُفحص خطؤها مسألة تشغيلية منفصلة. لا تدّعِ أن رقعة العرض أغلقتها؛ يلزم لها Closure Unit مستقلة لأن عقد الحفظ الحالي يحتاج اختبارًا ومراجعة خلفية.
- لا يُختبر تغيير المخزون على بيانات Production الحية.

## 6. التحقق المطلوب بعد تطبيق المالك

1. تحقق أن Loader وPicker ما زالا على SHA المذكور قبل بدء التطبيق؛ إذا تغير Loader، أعد مطابقة الرقعة مع المصدر الجديد ولا تلصقها عميانيًا.
2. طبّق A–F من Report482 مع التصحيحات المحددة في هذا التقرير؛ لا تنفّذ نسخًا قديمة أو أجزاء متعارضة.
3. نفّذ JavaScript parse على السكربت الكامل في Loader، لا على snippets فقط.
4. اختبر شركة A وشركة B مع صنف متطابق `item_code` وصورتين مختلفتين؛ يجب أن تعرض كل شركة صورتها المرتبطة فقط.
5. اختبر الرانشيت Picked من البطاقة ومن البحث، وفتح مودال الصنف بالماوس وEnter وSpace، وزر الرجوع، وزر بدء التحميل.
6. اختبر جلسة Loading للمستخدم الحالي، ورفض جلسة محمّل آخر، وعرض الوصف والصورة والكود والكميات.
7. افحص Console وNetwork؛ عالج أي استجابة خطأ أو صفوف فارغة على أنها نتيجة صريحة لا نجاح صامت.
8. قارن قبل/بعد فتح المعاينة: `stock_branches.qty` و`allocated_qty` و`inventory_log`؛ يجب ألا تتغير.
9. اختبر في بيئة Staging فعالة ومعزولة. وفق آخر حالة موثقة، بيئة staging كانت INACTIVE؛ لذلك لا يجوز الادعاء باجتياز Staging قبل إعادة التحقق من حالتها.
10. بعد النشر، افحص HTML الذي تقدمه Cloudflare مستقلًا عن Git، ثم نفّذ Browser E2E مصادقًا عليه.

## 7. الحكم النهائي وSelf-Audit

- **ما ثبت:** المصدر الحالي لم يتغير عن بصمات Report482؛ عقد Production الحالي يدعم join للصورة والوصف عبر FK؛ الجداول المعنية عليها RLS؛ `core.js` يحمّل كاش صور غير مقيد بالشركة.
- **ما لم يثبت:** تطبيق رقعة المالك، Staging PASS، Cloudflare artifact parity، Browser E2E، عدم تغير المخزون بعد التطبيق.
- **ما أُصلح في هذه الدورة:** تصحيح خطة الإصلاح والتوثيق فقط؛ لم يُعدّل التطبيق التشغيلي.
- **ما قد يبقى خطأ:** يجب التحقق من أن PostgREST يرجع العلاقة بصيغة object أو array كما يتعامل معها المساعد المحلي؛ الدالة تتعامل مع الصيغتين. يجب كذلك اختبار سلوك صورة فاشلة وقيود CSP.
- **Final Confidence:** مرتفع في تشخيص المصدر/المخطط، غير مثبت في Runtime.
- **Final Closure Status:** `PATCH DOCUMENTED / OWNER APPLICATION REQUIRED / NOT DEPLOYED / NOT CLOSED`.

**لا يُعلن 100% CLOSED قبل تطبيق الرقعة واختبارها ونشرها والتحقق من النسخة التي تقدمها Cloudflare.**
