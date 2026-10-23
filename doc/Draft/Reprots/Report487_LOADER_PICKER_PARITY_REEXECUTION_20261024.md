# Report487 — إعادة تنفيذ التحقيق الجنائي لتكامل Loader مع Picker وتوحيد رقعة المالك
**التاريخ:** 2026-10-24  
**معرّف الحدث:** LVE-2026-10-24-488  
**المستودع التشغيلي:** `papamohammed77-glitch/erp-frontend` / `main`  
**مستودع الحوكمة:** `papamohammed77-glitch/rawaie-erp-New` / `main`  
**الحالة:** LIVE SOURCE + PRODUCTION SCHEMA REVALIDATED / LOADER TARGET CONFIRMED / OWNER PATCH CONSOLIDATED IN THIS REPORT / NO SOURCE OR PRODUCTION MUTATION / NOT DEPLOYED / NOT CLOSED

---

## 1. PRE-CHANGE SELF-AUDIT

- **Business Understanding:** Loader يستقبل الرانشيت بعد التحضير ويعرض الكمية المحضّرة `qty_picked` كأساس للتحميل؛ Picker هو المرجع الوظيفي والبصري المطلوب للمعلومات التفصيلية، لكن دلالات الكميات ومراحل الحالة لا تُنقل بين التطبيقين.
- **Architecture Understanding:** `loader.html` تطبيق مستقل يعتمد `core.js` و`RW_Auth` و`RW_API` و`RW_ImageCache`. لا يجوز نسخ Picker كاملًا، ولا تغيير عقد بدء/إتمام التحميل لمعالجة نقص العرض.
- **Database Understanding:** Production يثبت أن `items.description` و`items.image_url` موجودان في `public.items`، وأن `run_sheet_details.item_id` يرتبط بـ`items.id`. لا توجد أعمدة `description` أو `image_url` أو `notes` في `run_sheet_details`. القراءة الصحيحة للبيانات التفصيلية عبر العلاقة الحالية؛ لا حاجة إلى migration من أجل الوصف والصورة.
- **Historical Understanding:** تمت مراجعة `CURRENT_STATE.md` كاملًا، وقراءة توجيه `writing-block.md` كاملًا (1,410 سطرًا)، وفحص سلسلة التقارير الحديثة. التقارير التاريخية للاستدلال فقط؛ أعيد جلب المصدر التشغيلي وقاعدة Production في هذه الدورة.
- **Production Understanding:** قراءة مباشرة جديدة من مشروع Supabase `fiilmooggumokxanwiyx`، PostgreSQL `17.6`، `now() = 2026-10-23 23:45:21.172585+00`. لا توجد كتابة في قاعدة البيانات أو Edge Functions.
- **Current Understanding:** أعيد جلب ملفات المصدر كاملة من `erp-frontend/main`: Loader SHA `97b83d68a683df77c1e0557838c24a1b4fb65169` (1 سطرًا)، Picker SHA `d483bd15b36585b975b63c2ef641481a01d5d084` (1 سطرًا)، Core SHA `ff2f581d9900543c16f7cb026e13446520c0329d` (1 سطرًا).
- **Execution Confidence:** مرتفعة لتشخيص المصدر وعقد قاعدة البيانات؛ غير كافية للإغلاق التشغيلي لأن التعديل المصدرّي لا يُطبّق بواسطة المساعد وفق التفويض، ولم يُثبت HTML المخدوم أو Browser E2E بعد الرقعة.

### CONFIRMED FACTS

1. تعليمات المالك الصريحة في الرسالة الحالية تجعل **Loader هو الملف المستهدف** و**Picker هو المرجع للمطابقة**. هذا يتقدم على اتجاه المهمة الأقدم داخل النص الملصق الذي عكس الهدف والمرجع.
2. قواعد الحوكمة داخل `writing-block.md` تحظر على المساعد تعديل ملفات التطبيق التشغيلي مباشرةً عندما تنص المهمة على أن المالك يطبق التغيير؛ لذا المخرج الصحيح هو رقعة كاملة قابلة للتطبيق، لا commit على `erp-frontend/loader.html`.
3. لم يتغير SHA الحالي عن بصمات آخر checkpoint، لكن ذلك لا يثبت أن Cloudflare يقدم الملف نفسه.
4. لا يتطلب نقص الوصف والصورة تعديل Edge/RPC/DB؛ العلاقة الحالية كافية.

### UNKNOWNS / UNVERIFIED

- هوية HTML الذي يقدمه Cloudflare Pages في لحظة هذا التقرير: **UNKNOWN**.
- تطبيق المالك للرقعة: **NOT APPLIED / UNVERIFIED**.
- Staging E2E وBrowser E2E بعد التعديل: **NOT RUN**.
- سلامة عقد التحميل الخاص بالكميات صفر والملاحظات: **مشكلة منفصلة مثبتة في العقد الحالي ولم تُصلح ضمن رقعة العرض**.

### CONFLICTS RESOLVED

- **اتجاه المهمة:** حُسم من تعليمات المالك الأحدث: Loader هدف، Picker مرجع.
- **عدد الأوصاف غير الفارغة:** استعلام Production الحالي أعاد 2 من 12، بينما لقطات تاريخية أعادت عددًا مختلفًا. تُعتمد القراءة الحالية فقط لهذه الدورة؛ لا يؤثر اختلاف عدد البيانات في قرار الربط أو schema.
- **Source vs served artifact:** لا يوجد دليل كافٍ لمساواتهما؛ لم يتم ادعاء parity.

---

## 2. سجل المصادر والبصمات

| المصدر | الدليل الحالي |
|---|---|
| Prompt | `doc/Draft/Reprots/writing-block.md`; SHA `de3f4640a6e706f23eba44b3d99fae9158ffe273`; 1,410 سطرًا |
| Operational HEAD | `152e5b1d22aab94d2cf01070778b357df4701aff` |
| Parent commit | `e69c9af4b56d99ba29a4fa74282f78438b9f7010` |
| HEAD commit title | `Refactor preview modal HTML generation`; الـdiff يعيد بناء `_showPreviewModal` في Loader |
| Loader current | `97b83d68a683df77c1e0557838c24a1b4fb65169`; 332 سطرًا |
| Picker current | `d483bd15b36585b975b63c2ef641481a01d5d084`; 1,058 سطرًا |
| Core current | `ff2f581d9900543c16f7cb026e13446520c0329d`; 773 سطرًا |
| Historical Loader | `rawaie-erp-review/PWA/warehouse/loader.html`; SHA `7e61b04d0d9a480d43763e8b7b21f9cbed78409a`; 266 سطرًا |
| Historical Picker | `rawaie-erp-review/PWA/warehouse/picker.html`; SHA `7626ba320021a607854bf219f4bacd81fc3d1d92`; 623 سطرًا |

### مراجعة التقارير الخمسين الأخيرة

تم استرجاع وفحص 50 تقريرًا من سلسلة المشروع الأحدث، وقراءة التقارير الأقرب إلى هذه المهمة بتفصيل أكبر، وبالأخص 481–486 و482 و483 و484 و485 و486. أُخذ من نمط التقارير المطلوب: Self-Audit، أدلة المصدر والبصمات، Production snapshot، فصل CONFIRMED/UNKNOWN/CONFLICT، مصفوفة المسؤوليات، رقع كاملة ذات محددات واضحة، ثم اختبارات وحالة إغلاق صادقة.

التقارير التي شملتها مراجعة السلسلة (الأرقام حسب ملفات التقارير المتاحة، مع وجود فجوات في الترقيم):  
`486, 485, 484, 483, 482, 481, 480, 479, 478, 477, 476, 475, 472, 471, 470, 469, 468, 467, 466, 465, 464, 463, 462, 461, 460, 459, 458, 457, 456, 455, 454, 453, 452, 451, 450, 449, 448, 447, 446, 445, 444, 443, 442, 441, 440, 439, 438, 437, 436, 435`.

---

## 3. LIVE PRODUCTION — إعادة التحقق في هذه الدورة

**المشروع:** SMART ERP / `fiilmooggumokxanwiyx`  
**وقت قاعدة البيانات المباشر:** `2026-10-23 23:45:21.172585+00`  
**إصدار PostgreSQL:** `17.6`

### 3.1 الجداول والأعمدة

- `public.items` يحتوي `id`, `company_id`, `item_code`, `name`, `unit`, `description`, `image_url` وغيرها.
- `public.run_sheet_details` يحتوي `id`, `runsheet_id`, `item_id`, `item_code`, `item_name`, `unit`, `unit_price`, `qty_ordered`, `qty_picked`, `qty_loaded`، ولا يحتوي `description` أو `image_url` أو `notes`.
- `public.runsheets` يحتوي `company_id`, `status`, `loader_id`, `runsheet_code`, `loading_cycle_id` وغيرها.

### 3.2 العلاقات

- `run_sheet_details_item_id_fkey`: `run_sheet_details.item_id → items.id`.
- `run_sheet_details_runsheet_id_fkey`: `run_sheet_details.runsheet_id → runsheets.id`.
- `runsheets_company_id_fkey`: `runsheets.company_id → companies.id`.

### 3.3 بيانات القراءة الحالية

| الفحص | النتيجة |
|---|---:|
| `items` | 18 صفًا |
| `run_sheet_details` | 12 صفًا |
| `runsheets` | صفّان |
| حالة الرانشيتات المرصودة | `Picked = 2` |
| تفاصيل مرتبطة بـ`item_id` | 12/12 |
| تفاصيل لها صف `items` مرتبط | 12/12 |
| تفاصيل لها وصف غير فارغ من `items` | 2/12 |
| تفاصيل لها صورة غير فارغة من `items` | 12/12 |

### 3.4 RLS وGRANT

- سياسة `run_sheet_details_select_current_tenant` تسمح بقراءة التفاصيل ضمن شركة المستخدم وصلاحية runsheets/warehouse/reports.
- سياسات `runsheets` تقيد القراءة بالشركة والصلاحيات.
- `authenticated` لديه `SELECT` على `run_sheet_details`، ولا يظهر له امتياز `UPDATE`.
- `service_role` و`postgres` لديهما `UPDATE`; لذلك لا ينبغي للواجهة أن تعتمد على تحديث مباشر من authenticated لتغيير بيانات لا يجيزها العقد الحالي.
- لا يوجد مبرر لمنح `authenticated UPDATE` أو إنشاء RPC جديد من أجل عرض التفاصيل.

### 3.5 Edge dependency — registry مباشر

`complete-loading`: **v11 / ACTIVE / verify_jwt=true / ezbr_sha256=c0ca692a29d14d64ec3729ae4bd12b9b84268e826ffc1c6993a48617b552b286**.

هذه بيانات Registry مباشرة؛ لم يتم تنزيل المصدر المنشور في هذه الدورة، ولا يُدّعى أن `ezbr_sha256` يساوي Git SHA. مصدر العرض لا يحتاج تعديل Edge.

### 3.6 عقد التحميل المنفصل

الدليل السابق المباشر على `complete-loading` و`complete_runsheet_loading` يثبت أن طلب الإكمال لا يمرر الملاحظات إلى Core، وأن الكمية المحملة صفرًا تُرفض. كما أن `run_sheet_details` لا يحتوي `notes`. هذه ليست فجوة عرض تُحل بإضافة حقل UI، ولا يجوز الادعاء أن الرقعة التالية تصلحها. تُبقى كـ**OPEN CONTRACT DEFECT** مستقلًا.

---

## 4. تحليل المصدر الحالي والسبب الجذري

### 4.1 ما يعمل بالفعل ويجب الحفاظ عليه

- Loader يملك قائمة `Loading` الخاصة بالمحمّل وقائمة `Picked` الجاهزة للتحميل.
- معاينة الرانشيت داخل `mainContent`، وملخص عدد الأصناف والكمية المحضرة والقيمة التقديرية.
- زر بدء التحميل لا يغيّر المخزون بمجرد فتح المعاينة؛ الحركة تتم عند الإكمال عبر عقد التحميل.
- الجلسة النشطة تعرض `qty_picked` و`qty_loaded` وتدعم تحرير الكمية والملاحظات محليًا، ومؤقتًا وإلغاءً وإكمالًا.
- Picker يوفّر مرجعًا لتفاصيل الصنف والصورة والوصف، لكن لا تُنقل منه دلالات التحضير أو التخزين المحلي أو مسارات API إلى Loader.

### 4.2 الفجوات المثبتة في Loader

1. **Company isolation ناقص في قائمة الرانشيتات:** استعلاما `renderPendingTab` لا يضيفان `.eq('company_id', this.currentUser.company_id)`.
2. **البحث غير محدد بالشركة:** `onSearchInput` يبحث في `Picked/Loading` دون company scope، ولا يعالج `r.error`.
3. **فتح الرانشيت لا يتحقق بما يكفي من الملكية:** `openRunsheet` يبحث برقم الرانشيت دون company scope، ولا يرفض صراحةً حالة `Loading` المسندة إلى محمّل آخر.
4. **الوصف والصورة لا يجلبهما استعلام التفاصيل:** `openRunsheet` يستخدم `select('*')` من `run_sheet_details` فقط.
5. **بطاقات المعاينة لا تفتح تفاصيل الصنف:** لا توجد أحداث click/keyboard على بطاقة الصنف ولا دالة تفاصيل آمنة داخل Loader.
6. **مودال تحرير الكمية محدود:** الصورة صغيرة، ولا يعرض كود الصنف والوصف بصورة واضحة.
7. **مسار الصورة المشترك غير ملائم لتوسيع الاستخدام:** `RW_ImageCache.getImageHTML` يولد HTML وصورة مع fallback inline؛ الرقعة المقترحة تضيف helper محليًا في Loader بدل تعديل Core المشترك.
8. **حفظ `qty_loaded` المباشر في الواجهة يتجاهل الخطأ:** الاستدعاء الحالي إلى `run_sheet_details.update` لا يفحص نتيجة الكتابة، كما أن `authenticated UPDATE` غير ممنوح. لا تُخفِ هذا الخلل داخل رقعة العرض؛ يُسجل كدين حفظ/عقد مستقل يحتاج معالجة في مسار الإكمال المركزي، وليس توسيع صلاحيات الواجهة.

### 4.3 الربط الصحيح للوصف والصورة

الاستعلام المطلوب يستخدم العلاقة الحالية بالاسم المثبت من Production:

```js
.select('*, items!run_sheet_details_item_id_fkey(description, image_url)')
```

لا تضف عمودًا إلى `run_sheet_details` ولا Migration ولا Edge Function جديدة من أجل الوصف أو الصورة.

---

## 5. LOSS / GAIN / RESPONSIBILITY MATRIX

| المسؤولية | الحالة | الدليل / الإجراء |
|---|---|---|
| قائمة حالات Loader الحالية | RETAINED | تبقى `Loading` و`Picked` كما هي |
| حساب الكمية والقيمة في المعاينة | RETAINED | يستمر الحساب على `qty_picked × unit_price` |
| Company isolation في القراءة | MISSING → HARDENED | إضافة company scope للقائمة والبحث والفتح |
| رفض جلسة Loading لمحمّل آخر | MISSING → ADDED | فحص `loader_id` قبل فتح الجلسة |
| وصف وصورة الصنف | MISSING → ADDED VIA JOIN | الربط عبر FK الحالي |
| بطاقة صنف قابلة للنقر ولوحة المفاتيح | MISSING → ADDED | click + Enter/Space |
| مودال تفاصيل مستقل للصنف | MISSING → ADDED | قيم escaped وURL validation وfallback |
| تفاصيل الصنف في مودال تحرير الكمية | INCOMPLETE → HARDENED | صورة أكبر وكود ووصف وبيانات الكمية |
| حركة المخزون عند فتح المعاينة | INTENTIONALLY ABSENT | يجب أن تبقى delta = 0 |
| تعديل Picker/Core/Main | INTENTIONALLY ABSENT | خارج النطاق؛ لا حاجة مثبتة |
| إصلاح contract الكمية صفر/الملاحظات | OPEN / SEPARATE | يحتاج وحدة تنفيذ واختبار مستقلة |
| Cloudflare artifact identity | UNKNOWN | لا يوجد دليل مباشر على HTML المخدوم |
| Staging / Browser E2E | NOT RUN | الرقعة لم تُطبق |

---

## 6. قاعدة تطبيق الرقعة

**الملف المستهدف:** `companies/company-1/warehouse/loader.html`  
**المستودع:** `papamohammed77-glitch/erp-frontend` / `main`  
**SHA الأساسي المطلوب قبل التطبيق:** `97b83d68a683df77c1e0557838c24a1b4fb65169`.

قبل التطبيق مباشرة، أعد جلب Loader. إذا تغير SHA، لا تطبق أي استبدال آليًا؛ أعد تحديد المواضع من النص الجديد. لا تعدل `picker.html` أو `core.js` أو `main.html`.

**ترتيب التطبيق الإلزامي:** Patch G (أمان الصور) → A1/A2 (نطاق الشركة والبحث) → B (فتح الرانشيت) → C (بيانات الجلسة) → D (تفاعل بطاقات المعاينة) → E (مودال تفاصيل الصنف) → F (مودال تحرير الكمية).

### Patch G — أمان الصور المحلي في Loader

## 8. Corrective owner patch G — safe Loader thumbnails

هذه رقعة أمان صور محلية داخل Loader، وتُطبق أولًا قبل رقع الاستعلام والعرض أدناه. Add the two methods below inside the App object after _showItemDetail and before _startLoadingFromPreview. Do not change core.js.

~~~js
_loaderImageHTML: function(item, widthClass, heightClass) {
    function esc(value) {
        return String(value == null ? '' : value)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    var product = item && item.items ? item.items : {};
    var code = typeof item === 'string' ? item : ((item && item.item_code) || '');
    var name = typeof item === 'string' ? '' : ((item && item.item_name) || product.name || '');
    var rawUrl = String(
        (product && product.image_url) ||
        (item && item.image_url) ||
        RW_ImageCache.getImageUrl(code) ||
        ''
    );

    var imageUrl = '';
    if (/^https?:\/\/[^\s"'<>]+$/i.test(rawUrl) ||
        /^\/(?!\/)[^\s"'<>]*$/.test(rawUrl)) {
        imageUrl = rawUrl;
    }

    var w = widthClass || 'w-14';
    var h = heightClass || 'h-14';
    var imageHtml = imageUrl
        ? '<img data-loader-image="true" src="' + esc(imageUrl) +
            '" alt="' + esc(name) +
            '" class="' + esc(w) + ' ' + esc(h) +
            ' rounded-2xl object-cover border-2 border-white shadow-sm">'
        : '';

    var fallbackClass = (imageUrl ? 'hidden ' : '') +
        esc(w) + ' ' + esc(h) +
        ' bg-gradient-to-br from-slate-100 to-slate-200 rounded-2xl ' +
        'flex items-center justify-center text-slate-400';

    return '<span class="inline-flex relative shrink-0">' +
        imageHtml +
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
~~~

بعد إضافة الدالتين، وبعد التأكد من أن SHA الأساسي للـLoader ما زال 97b83d68a683df77c1e0557838c24a1b4fb65169:

1. In _showPreviewModal, replace the expression RW_ImageCache.getImageHTML(it.item_code) with self._loaderImageHTML(it, 'w-14', 'h-14').
2. In _renderReadonly, replace the expression RW_ImageCache.getImageHTML(it.item_code) with this._loaderImageHTML(it, 'w-14', 'h-14').
3. In renderActiveSession, replace the expression RW_ImageCache.getImageHTML(it.item_code) with s._loaderImageHTML(it, 'w-14', 'h-14').
4. After safeHTML in each of those three functions, call _bindLoaderImageFallbacks on mainContent using the same owner variable (self, this, or s). In renderActiveSession, call it before startTimer().
5. In both modal didOpen handlers في مودالي تفاصيل الصنف وتحرير الكمية, after registering the image error listener, also check image.complete && image.naturalWidth === 0 and show the fallback immediately if the image has already failed.

The new helper prefers the joined items.image_url or the session image_url before the asynchronous cache, validates the URL, escapes attributes, and uses event listeners rather than inline onerror. This corrects the specific unsafe thumbnail paths in Report482. It does not claim a full security audit of every pre-existing Loader HTML interpolation.



### Patches A–F — النصوص الكاملة للتطبيق الجراحي

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

**فجوة منفصلة لا تُغلق بهذا التغيير:** استدعاء تحديث run_sheet_details.qty_loaded الحالي ما زال يتجاهل error ونتيجة التحديث، وهي نقطة حفظ تشغيلية مستقلة سبق رصدها في تاريخ تغييرات Loader. لا تدّعِ أن تعديل العرض عالجها، ولا تغيّر مسار الحفظ المركزي ضمن هذه الرقعة.



---

## 7. خطة الاختبارات بعد تطبيق المالك

1. **Static parse:** استخراج كتلة JavaScript الكاملة من `loader.html` بعد دمج كل الرقع وتمرير الملف كاملًا إلى parser؛ لا يكفي فحص كل دالة منفردة.
2. **قائمة الرانشيتات:** اختبار `Picked` و`Loading`، والبحث، والفتح والعودة؛ التأكد من أن كل الاستعلامات محددة بـ`company_id`.
3. **Ownership:** اختبار رانشيت `Loading` مسند إلى المستخدم الحالي ثم إلى مستخدم آخر؛ الحالة الثانية يجب أن تُرفض.
4. **Item detail:** اختبار النقر وEnter وSpace؛ يجب عرض الاسم والكود والوحدة والوصف والصورة والكمية المطلوبة والمحضرة والسعر والقيمة التقديرية.
5. **Image security/fallback:** HTTPS صالح، مسار محلي يبدأ بـ`/`، URL تالف، `javascript:`، `data:`، و`//host`. لا تُقبل الروابط غير المسموحة، والصورة الفاشلة تُظهر placeholder.
6. **Active loading:** تحرير الكمية والملاحظات، التحذير عند زيادة الكمية، إعادة فتح المودال، المؤقت، الإلغاء والإكمال؛ يجب ألا تتغير دلالات دورة التحميل.
7. **No movement on preview:** قارن `stock_branches.qty` و`allocated_qty` و`inventory_log` قبل وبعد فتح المعاينة؛ المتوقع صفر تغيير.
8. **Company isolation:** حساب من الشركة الصحيحة وآخر من شركة مختلفة؛ يجب ألا تظهر بيانات الشركة الأخرى ولا تُفتح.
9. **Staging:** استخدم بيئة اختبار معزولة ونشطة فقط. لا تدّعِ Staging PASS دون إثبات أن البيئة نشطة.
10. **Production UI deployment:** بعد تطبيق المالك ونشره عبر المسار الحالي، تحقق من HTML المخدوم من Cloudflare، ثم نفّذ Browser E2E مصادقًا عليه.
11. **Baseline:** لا تُنشئ بيانات تشغيلية في Production لهذه المهمة. لم تُنشأ fixtures في هذه الدورة؛ لا توجد بقايا اختبار أُنشئت هنا.
12. **Contract follow-up:** لا تغلق مشكلة الكمية صفر/الملاحظات أو تجاهل نتيجة UPDATE بناءً على نجاح رقعة العرض؛ سجّلها كعقد تحميل منفصل.

---

## 8. ما تم وما لم يتم

| البند | الحالة الفعلية |
|---|---|
| قراءة `writing-block.md` كاملًا | VERIFIED |
| قراءة `CURRENT_STATE.md` كاملًا قبل التنفيذ | VERIFIED |
| فحص 50 تقريرًا من السلسلة الحديثة | VERIFIED — مع قراءة تفصيلية للتقارير الأوثق صلة |
| إعادة جلب Loader وPicker وCore كاملين | VERIFIED |
| فحص تاريخ Git والـHEAD والـParent والـdiff | VERIFIED |
| إعادة جلب Historical Loader وPicker | VERIFIED |
| Production clock/schema/FK/RLS/grants/counts | VERIFIED READ-ONLY |
| Edge registry لـ`complete-loading` | VERIFIED READ-ONLY |
| Static parse للنسختين قبل الرقعة | لم يُعد تشغيل parser في هذه الدورة؛ آخر evidence المتاح من checkpoint السابق فقط |
| تطبيق Patch G وA–F | NOT APPLIED — التعديل المصدرّي للمالك |
| تعديل Production SQL/Edge/RPC | NONE — غير مطلوب لفجوة العرض |
| Staging E2E / Browser E2E | NOT RUN |
| Cloudflare served artifact identity | UNKNOWN |
| إغلاق المهمة | NOT CLOSED |

---

## 9. المخاطر والتراجع

- لا تنشر رقعة إذا تغير SHA من `97b83d68a683df77c1e0557838c24a1b4fb65169` قبل التطبيق.
- لا تمنح `authenticated` صلاحية UPDATE على `run_sheet_details` كحل سريع.
- لا تضف أعمدة `description/image_url/notes` إلى جدول التفاصيل لمجرد أن الواجهة تحتاج عرضًا.
- لا تعدّل Core أو Picker أو Main لمعالجة فجوة محلية في Loader.
- احتفظ بنسخة من Loader قبل تطبيق الرقعة، وراجع diff بعد التطبيق.
- إذا فشل اختبار Static أو Company isolation أو فتح الرانشيت، ارجع إلى النسخة السابقة ولا تنشر.
- لا تختبر عقد الكمية صفر/الملاحظات على بيانات تشغيلية حقيقية.

---

## 10. SELF-AUDIT FINAL

- **What I Proved:** اتجاه النطاق الصحيح؛ بصمات المصدر الحالي والتاريخي؛ آخر Commit وParent؛ علاقة FK الحقيقية؛ وجود الوصف والصورة في `items` وعدم وجودهما في `run_sheet_details`; سياسة القراءة ضمن الشركة؛ عدم وجود UPDATE للمستخدم authenticated؛ وجود فجوات Loader المحددة.
- **What I Did Not Prove:** أن الرقعة طُبقت أو اجتازت الاختبار؛ هوية HTML المخدوم؛ Browser E2E؛ إصلاح عقد إكمال التحميل.
- **What I Fixed:** وحّدت التشخيص والرقعة الكاملة في وثيقة واحدة وأعدت مزامنة Production schema في هذه الدورة. لم أعدل ملف تشغيل أو قاعدة Production.
- **What I Initially Missed:** اتجاه المهمة في النص التنفيذي القديم معكوس؛ يجب اتباع تعليمات المالك الأحدث. كما أن تحديث `qty_loaded` المباشر يتجاهل أخطاء الكتابة ولا يملك authenticated امتياز UPDATE، وهذا ليس إصلاحًا بصريًا.
- **What Could Still Be Wrong:** قد يتغير Loader SHA قبل التطبيق؛ قد يختلف Cloudflare artifact؛ قد يفشل PostgREST relationship في Browser رغم وجود FK بسبب cache/permission behavior؛ وقد تظهر أخطاء UI بعد دمج الرقع؛ عقد الكمية صفر/الملاحظات ما زال مفتوحًا.
- **Final Confidence:** مرتفعة في تشخيص المصدر وعقد Production؛ متوسطة في صلاحية الرقعة قبل تطبيقها واختبارها؛ منخفضة/غير مثبتة في Runtime حتى اختبار المتصفح.
- **Final Closure Status:** `OWNER PATCH COMPLETE IN THIS REPORT / SOURCE NOT APPLIED / NOT DEPLOYED / NOT CLOSED`.

---

## 11. الخطوة التنفيذية التالية

1. أعد جلب `loader.html` من `erp-frontend/main` فورًا قبل التطبيق وتأكد من SHA.
2. طبّق Patch G ثم A1/A2 ثم B ثم C ثم D ثم E ثم F من هذا التقرير فقط.
3. أعد قراءة الملف كاملًا، وافحص الـdiff، وشغّل Static parse.
4. نفّذ الاختبارات المعزولة الواردة في القسم 7.
5. انشر عبر مسار Cloudflare الحالي ثم تحقق من Served Artifact وBrowser E2E.
6. افتح Closure منفصلة لعقد الكمية صفر/الملاحظات وحفظ `qty_loaded`؛ لا تدّعِ أن هذه الوثيقة أغلقتها.

**لا يوجد تعديل تشغيلي أو Production نُفذ في هذه الدورة. هذه وثيقة تنفيذ جراحي كاملة للمالك وليست إثباتًا على التطبيق أو النشر.**
