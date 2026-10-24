# Report488 — مراجعة RAWAEA اليومية وإعادة تصحيح حزمة Loader/Picker
**التاريخ:** 2026-10-24  
**الحدث:** LVE-2026-10-24-489  
**نطاق العمل:** Loader target / Picker comparison reference  
**الحالة:** LIVE SOURCE REVALIDATED / PRODUCTION CONTRACT CONFLICT CONFIRMED / OWNER PATCH REBUILT AND STATIC-PARSED IN MEMORY / DEPLOYMENT UNKNOWN / NOT CLOSED

## 1. نقطة البداية الإلزامية

- تمت قراءة CURRENT_STATE.md كاملًا من المستودع المرجعي، بما في ذلك EOF: SHA `29973b1d7c05c05309bfdc2a51cf8cbcc84feec8`, 1 سطرًا. أحدث نقطة في أعلاه هي LVE-2026-10-24-488، وتشير إلى Report487. الحالة التشغيلية المستهدفة هي تكامل تفاصيل الصنف في `companies/company-1/warehouse/loader.html` مع اعتبار `picker.html` مرجع مقارنة فقط. لا توجد حالة إغلاق موثقة لهذه الوحدة.
- تمت قراءة MASTER CTO governance كاملًا حتى علامة النهاية: SHA `b03feec14a417ca9032d714774f2687b4542a373`, 1 سطرًا.
- تمت قراءة سجل الذاكرة 117-02: SHA `fc384d03068aa1c7d2df5683ed55cb67b43ae689`, 1 سطرًا. الذاكرة والتقارير أدلة تاريخية؛ مصدر الحالة الحية هو GitHub/Production/Runtime.
- لم يُطبّق أي تغيير تشغيلي خلال هذه المراجعة، ولم تُجرَ أي كتابة في Production.

## 2. CONFIRMED — GitHub/source

**المستودع التشغيلي:** `papamohammed77-glitch/erp-frontend`, branch `main`.  
**HEAD:** `152e5b1d22aab94d2cf01070778b357df4701aff`; parent `e69c9af4b56d99ba29a4fa74282f78438b9f7010`. المقارنة الحية تظهر commit واحدًا فوق parent، وملفًا واحدًا تغيّر: `loader.md → loader.html` (78 إضافة، 12 حذفًا). لا يوجد دليل على commit أحدث.

| الملف | SHA الحالي | السطور | نتيجة V8 parse للـJavaScript الكامل داخل الملف |
|---|---|---:|---|
| Loader | `97b83d68a683df77c1e0557838c24a1b4fb65169` | 332 | PASS — كتلة inline واحدة، 28,505 حرفًا |
| Picker | `d483bd15b36585b975b63c2ef641481a01d5d084` | 1058 | PASS — كتلة inline واحدة، 48,383 حرفًا |
| Core | `ff2f581d9900543c16f7cb026e13446520c0329d` | 773 | PASS — الملف كاملًا، 28,074 حرفًا |

- Loader ما زال بلا `_showItemDetail` أو `_loaderImageHTML`، ولا يحتوي استعلام التفاصيل على `items!run_sheet_details_item_id_fkey(description, image_url)`. بطاقات معاينة الأصناف لا تفتح تفاصيل، بينما `openRunsheet` ومسار النقر موجودان بالفعل.
- `RW_Auth.toClientUser()` يمرّر `company_id` داخل `currentUser`؛ لذلك يمكن وضع نطاق شركة صريح في الاستعلامات.
- **تصحيح مهم:** غياب مرشح `company_id` الصريح من استعلامات Loader مثبت في المصدر، لكن RLS الحالي في Production يقيّد قراءة الرانشيتات والتفاصيل بالشركة والصلاحيات. لا يوجد دليل على تسرب بيانات بين الشركات؛ المرشح الصريح دفاع إضافي، وليس إصلاحًا لتسرب مثبت.
- سلوك Loader الحالي للرانشيت `Loading` المسند إلى محمّل آخر هو عرض read-only، لا فتح جلسة تحرير. لم يثبت أن هذا السلوك خطأ. حزمة التصحيح أدناه تحافظ على read-only ولا تحوّله إلى رفض كامل بلا متطلب أعمال موثق.
- تقرير Report487 الأصلي يحتوي خطأ توثيقيًا: في قسم self-audit وصف بصمات Loader/Picker/Core بأنها «1 سطر»، بينما جدول المصدر نفسه يسجل 332/1,058/773. نعتمد عدد السطور المقاس أعلاه.

## 3. CONFIRMED — Supabase Production

**المشروع:** SMART ERP / `fiilmooggumokxanwiyx`.  
**وقت الاستعلام المباشر:** `2026-10-24 18:41:23.419779+00`. PostgreSQL 17.6.

- البيانات الحالية: `items=18`, `run_sheet_details=12`, `runsheets=2`; كل الرانشيتات الحالية `Picked=2` ولا توجد جلسة `Loading` فعالة لاستخدامها كاختبار.
- `items` يحتوي `description` و`image_url`. جدول `run_sheet_details` لا يحتوي `description` أو `image_url` أو `notes`. المفتاح `run_sheet_details_item_id_fkey` يربط `item_id → items.id`.
- سياسة `runsheets_select_company` تقيد القراءة بـ`company_id = app_private.current_user_company_id()` والصلاحيات؛ وسياسة `run_sheet_details_select_current_tenant` تتحقق من الشركة والصلاحية عبر الرانشيت الأب.
- دور `authenticated` لديه SELECT على `run_sheet_details` لكنه لا يملك UPDATE؛ لا توجد سياسة UPDATE على الجدول. `order_details` كذلك لا يمنح الواجهة UPDATE مباشرًا في هذا المسار. لا تمنح صلاحية مباشرة ولا تضف عمودًا لمعالجة عيب العرض.
- يوجد trigger لمزامنة `run_sheet_details` من `order_details`. مسار الحفظ المركزي يحدّث `order_details` ثم المزامنة، بينما تحديث الواجهة المباشر لـ`run_sheet_details.qty_loaded` يتجاهل الخطأ؛ لذلك لا يُعتمد عليه كحفظ دائم للجلسة.
- سجل migrations يحتوي 678 migration؛ آخر نسخة مسجلة `20261021161758` باسم `picking_reservation_diagnostic_contract_20261021`. لم يظهر إصلاح أحدث لعقد التحميل.

## 4. CONFLICT — عقد التحميل ومصدر Edge

- `complete-loading` المنشورة: v11 / ACTIVE / `verify_jwt=true` / registry digest `c0ca692a29d14d64ec3729ae4bd12b9b84268e826ffc1c6993a48617b552b286`.
- `start-loading` المنشورة: v5 / ACTIVE / `verify_jwt=true`.
- الدالة `complete_runsheet_loading(uuid,uuid,jsonb,text)` في Production ترفض `req <= 0`، ولا تتعامل مع `notes`، وتستخدم `loading_cycle_id` في مفتاح idempotency.
- الواجهة الحالية ترسل كل عناصر الجلسة، بما فيها `qty_loaded=0`، وترسل `notes`. Edge v11 ترفض أي عنصر `loaded_qty <= 0` ولا تمرّر `notes` إلى RPC؛ وRPC يرفض الصفر أيضًا ولا يحفظ الملاحظات. هذا **تعارض عقد مثبت في المصدر**. لم يُثبت وقوع فشل مستخدم بعينه لأن لا توجد جلسة Loading حية ولا سجل استدعاء مطابق في الاستعلام المستهدف.
- مصدر Git `Current/Edge_Functions/complete-loading` SHA `0dd221173aee7f3aa15d16202f034ae94f4104f3` لا يطابق نص Production المنشور في تفاصيل معالجة JSON غير الصالح وتطبيع `runsheet_code`. هذا drift مؤكد من مقارنة النصين؛ لا نقارن `ezbr_sha256` مباشرةً بـGit SHA لأنهما ليسا نوع البصمة نفسه.
- المسار `Current/Edge_Functions/start-loading` غير موجود في مستودع الحالة (404)، رغم أن Production يسجل v5 نشطة. هذا نقص في مصدر إعادة الإنتاج، لا دليل وحده على فساد الوظيفة المنشورة.
- لا تُصلح هذا التعارض بمنح UPDATE للواجهة أو بإضافة `notes` إلى جدول مشتق. يلزم عقد منفصل يحدد سياسة الأصناف ذات الكمية صفرًا وحفظ الأسباب داخل مسار الإكمال المركزي، مع اختبار idempotency وعدم تكرار حركة المخزون.

## 5. UNKNOWN / UNVERIFIED — deployment وruntime

- محاولة فتح `https://rawaea-erp.pages.dev` ومسار Loader المنشور عبر أداة الويب فشلت برسالة أن الرابط غير قابل للوصول. أداة Browser رفضت العمل لغياب originating browser context. لم تظهر أداة Cloudflare MCP ضمن الأدوات المتاحة. لذلك **هوية artifact المخدوم وheaders/cache وcommit lineage = UNKNOWN**.
- مشروع Staging `rawaea-staging / hfzznsiprnwkpayskzhu` حالته `INACTIVE`. لم تتم استعادته ولم تُنشأ بيانات اختبار.
- نافذة السجلات المحددة أعادت 117 سجلًا موزعًا على PostgREST/Edge/Postgres/Realtime/Auth؛ الاستعلام المستهدف عن طلبات Loader/ran sheet/complete-loading لم يُرجع تطابقًا. أحدث السجلات الظاهرة لا تثبت تجربة التحميل. لا نستنتج من غياب السجل أن التطبيق لم يُستخدم.
- لا يوجد authenticated browser E2E، ولا Console/Network capture، ولا اختبار فرق مخزون بعد فتح المعاينة. تبقى هذه البنود UNVERIFIED.

## 6. تصحيح حزمة المالك — لا تطبق Report487 بالترتيب الأصلي

**السبب:** Report487 يأمر بتطبيق Patch G أولًا، لكنه يطلب إدراج helper بعد `_showItemDetail`، وهذه الدالة لا تظهر في Loader الحالي وتُضاف في Patch E. كما أن تعليمات G تعدّل handlers داخل مودالي E وF قبل وجودهما. كذلك replacement السابق لـ`openRunsheet` لم يُرجع Promise الداخلي لتفاصيل الرانشيت، فيمكن أن يفلت رفض الشبكة من `.catch` الخارجي.

**الترتيب الصحيح لحزمة المالك أدناه:**
1. استبدال `renderPendingTab` (A1) كاملًا.
2. استبدال `onSearchInput` (A2) كاملًا.
3. استبدال `openRunsheet` (B) كاملًا — النسخة هنا تعيد Promise الداخلي وتحافظ على read-only للرانشيت المسند لمحمّل آخر.
4. استبدال `_startSession` باستخدام النص الكامل في الملحق الذاتي (C) أسفل هذا التقرير.
5. استبدال `_showPreviewModal` كاملًا بالنص أدناه (D؛ يتضمن click/keyboard وربط الصورة الآمن).
6. إضافة `_showItemDetail` باستخدام النص الكامل في الملحق الذاتي (E) أسفل هذا التقرير.
7. استبدال `_renderReadonly` و`renderActiveSession` بالنصين أدناه.
8. استبدال `editLoadedItem` باستخدام النص الكامل في الملحق الذاتي (F) أسفل هذا التقرير.
9. بعد E وF، أضف helper methods `_loaderImageHTML` و`_bindLoaderImageFallbacks` باستخدام النص الكامل في الملحق الذاتي (G) أسفل هذا التقرير. احتفظ بمالك الدالة الصحيح: في `renderActiveSession` المتغير `s=this` يشير إلى App، لذا `s._loaderImageHTML` و`s._bindLoaderImageFallbacks` صحيحان.
10. طبّق فحص `image.complete && image.naturalWidth === 0` في `didOpen` لمودالي E وF كما هو موضح في قسم G. لا تكرر إدراج helper ولا تكرر استبدال معاينة D بعد استخدام النص الكامل هنا.

النصوص التالية **بدائل كاملة للدوال**، وليست snippets. تستخدم دوال C/E/F/G الكاملة المرفقة في الملحق الذاتي أدناه؛ لا يلزم الرجوع إلى Report487 لتجميع حزمة التطبيق. لا تطبق رقع A1/A2/B/D القديمة مرة ثانية.

### A1 — replacement كامل لـrenderPendingTab

~~~js
    renderPendingTab: function() {
        var self = this;
        if (!self.currentUser || !self.currentUser.company_id) {
            RW_UI.showError('تعذر تحديد الشركة المرتبطة بالمستخدم');
            return;
        }
        var companyId = self.currentUser.company_id;
        var loaderId = self.currentUser.id || self.currentUser.email;
        RW_UI.showSkeleton('mainContent', 3, 'card');
        Promise.all([
            supabase.from('runsheets').select('runsheet_code, status, run_date, loader_id, run_sheet_details(count)')
                .eq('company_id', companyId).eq('status', 'Loading').eq('loader_id', loaderId)
                .order('run_date', { ascending: false }).limit(20),
            supabase.from('runsheets').select('runsheet_code, status, run_date, run_sheet_details(count)')
                .eq('company_id', companyId).eq('status', 'Picked')
                .order('run_date', { ascending: false }).limit(50)
        ]).then(function(results) {
            var mineRes = results[0], availableRes = results[1];
            var queryError = (mineRes && mineRes.error) || (availableRes && availableRes.error);
            if (queryError) {
                console.error('Loader pending runsheets query error:', queryError);
                self.allRunsheets = [];
                RW_UI.showEmptyState('mainContent', 'فشل تحميل البيانات', '📡');
                return;
            }
            var mine = (mineRes && mineRes.data) || [];
            var available = (availableRes && availableRes.data) || [];
            self.allRunsheets = mine.concat(available);
            self.renderRunsheetLists(mine, available);
        }).catch(function(error) {
            console.error('Loader pending runsheets request failed:', error);
            self.allRunsheets = [];
            RW_UI.showEmptyState('mainContent', 'فشل تحميل البيانات', '📡');
        });
    },
~~~

### A2 — replacement كامل لـonSearchInput

~~~js
    onSearchInput: function(q) {
        var self = this;
        if (this.searchTimer) clearTimeout(this.searchTimer);
        var query = String(q == null ? '' : q).trim();
        if (!query) {
            this.searchResults = [];
            var dropdown = RW_UI.byId('searchDropdown');
            if (dropdown) dropdown.classList.add('hidden');
            return;
        }
        if (!this.currentUser || !this.currentUser.company_id) {
            this.searchResults = [];
            RW_UI.toast('تعذر تحديد الشركة المرتبطة بالمستخدم', 'error');
            this.renderSearchDropdown();
            return;
        }
        var companyId = this.currentUser.company_id;
        this.searchTimer = setTimeout(function() {
            supabase.from('runsheets').select('runsheet_code,status,run_date,loader_id,run_sheet_details(count)')
                .eq('company_id', companyId)
                .or('status.eq.Picked,status.eq.Loading')
                .ilike('runsheet_code', '%' + query + '%').limit(10)
                .then(function(result) {
                    if (result.error) throw result.error;
                    self.searchResults = result.data || [];
                    self.renderSearchDropdown();
                }).catch(function(error) {
                    console.error('Loader runsheet search failed:', error);
                    self.searchResults = [];
                    self.renderSearchDropdown();
                });
        }, 300);
    },
~~~

### B — replacement كامل لـopenRunsheet

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
        return supabase.from('runsheets').select('*')
            .eq('company_id', self.currentUser.company_id)
            .eq('runsheet_code', code).maybeSingle()
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
                var isActive = rs.status === 'Loading' &&
                    (rs.loader_id === self.currentUser.id || rs.loader_id === self.currentUser.email);
                return supabase.from('run_sheet_details')
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
            }).catch(function(error) {
                console.error('Loader openRunsheet request failed:', error);
                RW_UI.toast('حدث خطأ أثناء فتح الرانشيت', 'error');
                self.renderPendingTab();
            });
    },
~~~

### D — replacement كامل لـ_showPreviewModal

~~~js
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
    h += '<p class="text-sm text-slate-400 mb-3">اضغط على الصنف لعرض صورته وتفاصيله</p>';

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

            h += '<div class="card mb-3 cursor-pointer loader-preview-item hover:shadow-md transition-all focus:outline-none focus:ring-2 focus:ring-orange-300" role="button" tabindex="0" data-loader-item-index="' + i + '"><div class="flex items-start gap-3">';
            h += '<div class="shrink-0">' + self._loaderImageHTML(it, 'w-14', 'h-14') + '</div>';
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

    self._bindLoaderImageFallbacks(RW_UI.byId('mainContent'));
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
                card.addEventListener('keydown', function(event) {
                    if (event.key === 'Enter' || event.key === ' ' || event.keyCode === 13 || event.keyCode === 32) {
                        event.preventDefault();
                        openItemDetails();
                    }
                });
            })(itemCards[ci]);
        }
    }

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
~~~

### G — replacement كامل لـ_renderReadonly

~~~js
    _renderReadonly: function(code, items) {
        var h = '<div class="flex items-center gap-3 mb-6"><button onclick="App.renderPendingTab()" class="w-10 h-10 bg-white rounded-2xl flex items-center justify-center text-orange-600 shadow-sm"><i class="fa-solid fa-arrow-right"></i></button><span class="font-black text-xl text-slate-800">'+code+' | '+items.length+' صنف</span></div>';
        for(var k=0;k<items.length;k++) { var it=items[k]; h += '<div class="card mb-2"><div class="flex items-center gap-4">'+this._loaderImageHTML(it, 'w-14', 'h-14')+'<div><p class="font-bold text-slate-700">'+(it.item_name||'')+'</p><p class="text-xs text-slate-400">'+(it.item_code||'')+' | محضّر: <span class="font-bold text-slate-600">'+(Number(it.qty_picked)||0)+'</span> '+(it.unit||'حبة')+'</p></div></div></div>'; }
        RW_UI.safeHTML(RW_UI.byId('mainContent'), h);
        this._bindLoaderImageFallbacks(RW_UI.byId('mainContent'));
    },
~~~

### G — replacement كامل لـrenderActiveSession

~~~js
    renderActiveSession: function() {
        var s=this; if(!this.session) { this.renderPendingTab(); return; }
        var ses=this.session, elapsed='00:00';
        if(ses.start_time) { var d=Math.floor((new Date()-new Date(ses.start_time))/1000), m=Math.floor(d/60), sec=d%60; elapsed=String(m).padStart(2,'0')+':'+String(sec).padStart(2,'0'); }
        var loaded=0; for(var j=0;j<ses.items.length;j++) if(ses.items[j].qty_loaded>0) loaded++;
        var prog=ses.items.length?Math.round((loaded/ses.items.length)*100):0;
        var h = '<div class="bg-orange-50 rounded-3xl p-5 mb-6 slide-in"><div class="flex items-center justify-between mb-4"><span class="font-black text-2xl text-slate-800">'+ses.runsheet_code+'</span><span id="timerDisplay" class="bg-white text-orange-600 px-4 py-2 rounded-2xl text-sm font-black shadow-sm">⏱️ '+elapsed+'</span></div><div class="bg-white rounded-2xl p-4 shadow-sm"><div class="flex justify-between text-xs font-bold text-slate-400 mb-2"><span>تقدم التحميل</span><span>'+loaded+' / '+ses.items.length+' صنف</span></div><div class="w-full h-3 bg-slate-100 rounded-full overflow-hidden"><div class="progress-bar h-full bg-gradient-to-r from-orange-500 to-red-500 rounded-full" style="width:'+prog+'%"></div></div></div></div>';
        h += '<p class="text-sm text-slate-400 mb-4">اضغط على الصنف لإدخال الكمية المحمّلة</p>';
        for(var i=0;i<ses.items.length;i++) { var it=ses.items[i], done=it.qty_loaded>0;
            h += '<div class="card mb-3 cursor-pointer slide-in '+(done?'border-r-4 border-orange-400':'')+'" onclick="App.editLoadedItem('+i+')"><div class="flex items-center justify-between"><div class="flex items-center gap-4">'+s._loaderImageHTML(it, 'w-14', 'h-14')+'<div><p class="font-bold text-slate-700">'+(it.item_name||'')+'</p><p class="text-xs text-slate-400 mt-0.5">محضّر: '+(it.qty_picked||0)+' | مطلوب: '+(it.qty_ordered||0)+' | <span class="font-bold '+(done?'text-orange-600':'text-slate-500')+'">محمّل: '+(it.qty_loaded||0)+'</span></p></div></div><i class="fa-solid fa-pen text-slate-300 text-sm"></i></div></div>'; }
        h += '<button onclick="App.completeLoading()" class="btn-primary mt-6"><i class="fa-solid fa-check ml-2"></i> إنهاء التحميل</button>';
        h += '<button onclick="App.cancelLoading(\''+ses.runsheet_code+'\')" class="btn-danger w-full mt-3"><i class="fa-solid fa-xmark ml-1"></i> إلغاء التحميل</button>';
        RW_UI.safeHTML(RW_UI.byId('mainContent'), h);
        s._bindLoaderImageFallbacks(RW_UI.byId('mainContent'));
        this.startTimer();
    },
~~~

## 7. Static validation لحزمة التصحيح

- جرى تركيب بدائل A1/A2/B/C/D/E/F/G في نسخة Loader افتراضية داخل الذاكرة، دون كتابة الملف التشغيلي، ثم استخراج كتلة JavaScript inline كاملة وتمريرها إلى V8 parser.
- النتيجة: **PASS** لكتلة inline كاملة طولها 44316 حرفًا. تحققنا أيضًا من وجود company filters في القائمة والبحث والفتح، وربط FK الصحيح، وتفاعل البطاقة بالماوس ولوحة المفاتيح، وربط fallback، وإرجاع Promise تفاصيل الرانشيت، والحفاظ على read-only للرانشيت الآخر.
- هذا اختبار syntax للنسخة المركبة في الذاكرة فقط. ليس اختبار DOM أو API أو Staging أو Browser E2E، ولا يثبت أن المالك طبق التغيير أو أن Cloudflare ينشره.
- لم يُعدل أي ملف في `erp-frontend`. لم تُنفذ أي كتابة على Production schema/RLS/grants/RPC/Edge أو بيانات الأعمال. لم تُنشأ أو تُحذف سجلات اختبار.

## 8. مصفوفة الحالة

| الطبقة | الحالة | الحكم |
|---|---|---|
| GitHub/source | CONFIRMED | المصدر الحالي ثابت والرقع غير موجودة فيه |
| Supabase Production schema/RLS/grants/RPC | CONFIRMED | العلاقة والصلاحيات وعقد الإنهاء فُحصت قراءةً فقط |
| Source ↔ Production Edge | CONFLICT | مصدر complete-loading غير مطابق؛ مصدر start-loading مفقود من snapshot |
| Loader ↔ complete-loading contract | CONFLICT | صفر الكمية والملاحظات لا يتوافقان مع عقد الإنهاء |
| Deployed artifact | UNKNOWN | تعذر الحصول على HTML المنشور أو headers |
| Runtime/E2E | UNVERIFIED | لا Browser session ولا Staging نشط |
| Business-data effects | CONFIRMED: no mutation | لم تتغير بيانات Production بفعل هذه المراجعة |

## 9. الخطوة التالية ذات الأولوية

على المالك إعادة جلب Loader والتأكد أن SHA ما زال `97b83d68a683df77c1e0557838c24a1b4fb65169`، ثم تطبيق حزمة Report488 بالترتيب أعلاه على ملف Loader فقط. بعد ذلك يجب إجراء full-file syntax check على الملف المحفوظ، ثم تفعيل بيئة Staging معزولة وفق تفويض واضح واختبار المعاينة والصور والملكية والرجوع/بدء التحميل مع delta صفر على `stock_branches.qty`, `allocated_qty`, و`inventory_log`.

**يبقى تعارض الصفر/الملاحظات وحفظ `qty_loaded` blocker مستقلًا**؛ لا يُعلن إصلاح التحميل أو الجاهزية الإنتاجية حتى يُصمم ويُختبر عقد مركزي آمن لهذا المسار. لا تُجرِ أي تعديل Production أو تمنح UPDATE للواجهة في هذه المرحلة.


## 10. الملحق الذاتي — بقية بدائل الدوال اللازمة لحزمة Report488

هذه الكتل جزء من حزمة Report488 نفسها، وتكمل بدائل A1/A2/B/D/G أعلاه. تطبق وفق الترتيب في القسم 6. جميعها مهيأة للإدراج داخل كائن App الحالي، مع الحفاظ على الفاصلة الختامية لكل خاصية.

### C — replacement كامل لـ_startSession

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

### E — إضافة _showItemDetail بعد _showPreviewModal

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
                if (image.complete && image.naturalWidth === 0) {
                    image.classList.add('hidden');
                    if (fallback) fallback.classList.remove('hidden');
                }
            }
        }
    });
},
~~~

### F — replacement كامل لـeditLoadedItem

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
                if (image.complete && image.naturalWidth === 0) {
                    image.classList.add('hidden');
                    if (fallback) fallback.classList.remove('hidden');
                }
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

### G — إضافة helper methods بعد _showItemDetail وقبل _startLoadingFromPreview

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

