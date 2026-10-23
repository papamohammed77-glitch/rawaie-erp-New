# Report467 — استكمال معاينة الرانشيت في Picker وفق نمط Loader

**التاريخ:** 2026-10-23  
**النطاق:** مقارنة معاينة الرانشيت في `erp-frontend/companies/company-1/warehouse/loader.html` و`picker.html` وتحديد تعديل جراحي يطبقه المالك على `picker.html` فقط.  
**القيود:** لم يُعدّل المساعد `main.html` أو أي ملف تشغيلي. لا يوجد تغيير مطلوب في Production/Supabase لهذه المهمة العرضية. لا توجد دعوى بأن النشر أو Browser E2E قد تم.

## 1. PRE-CHANGE SELF-AUDIT

- **Business Understanding:** Picker يعرض الرانشيت قبل بدء التحضير، ويجب أن يتيح معاينة مفهومة للأصناف والكميات ومعلومات الصنف ثم بدء التحضير فقط إذا كانت الحالة `Open` أو `Confirmed`. المعاينة لا تنفذ حركة مخزون.
- **Architecture Understanding:** القراءة الحالية تتم عبر Supabase JS؛ بدء التحضير يمر عبر Edge Function الموجودة `start-picking`. لا حاجة إلى Edge Function أو RPC جديدة لمجرد تحسين المعاينة.
- **Database Understanding:** Production `fiilmooggumokxanwiyx` يثبت وجود أعمدة التفاصيل المستخدمة في العرض، وسياسات القراءة لـ`runsheets` و`run_sheet_details` تقيد البيانات بالشركة والصلاحية. لا يوجد سبب لتغيير schema أو ACL.
- **Historical Understanding:** Loader التاريخي عند SHA `7e61b04d0d9a480d43763e8b7b21f9cbed78409a` كان يعرض المعاينة في SweetAlert منفصل. Report466 وثّق تحويله إلى صفحة داخل `mainContent`. Picker التاريخي SHA `7626ba320021a607854bf219f4bacd81fc3d1d92` يعرض تفاصيل داخل الصفحة، لكن بصورة مختصرة.
- **Production Understanding:** عند `2026-10-23 11:15:55 UTC` كانت قراءة Production تؤكد وجود `start-loading v5` و`complete-loading v11` مع `verify_jwt=true`. سجلات Supabase تُظهر قراءات فعلية لـ`runsheets` من `rawaea-erp.pages.dev` يوم 2026-10-23، لكنها لا تثبت تطابق HTML المنشور مع Git. لم تُجرَ أي كتابة في قاعدة البيانات.
- **Current Understanding:** Loader الحالي من Git SHA `97b83d68a683df77c1e0557838c24a1b4fb65169` (332 سطرًا) يعرض المعاينة داخل `mainContent` ويشمل ملخص الكمية والقيمة وصور الأصناف. Picker الحالي SHA `d483bd15b36585b975b63c2ef641481a01d5d084` (1058 سطرًا) يعرض تفاصيل الرانشيت داخل الصفحة، لكنه يفتقر إلى ملخص إجمالي الكمية، وبطاقات معاينة متسقة، وإظهار الوصف داخل قائمة المعاينة؛ كما يبني HTML من قيم قاعدة البيانات دون escaping في موضع المعاينة/تفاصيل الصنف.
- **Execution Confidence:** مرتفع في موضع النقص بالمصدر الحالي؛ غير مثبت في HTML الذي يخدمه Cloudflare أو في Browser E2E لأن واجهة الإنتاج لم تكن قابلة للفحص عبر أداة المتصفح. لا إعلان إغلاق قبل تطبيق المالك واختبار المتصفح.

## 2. CURRENT SOURCE / HISTORY / PRODUCTION EVIDENCE

| الدليل | النتيجة |
|---|---|
| Current Loader | `companies/company-1/warehouse/loader.html`, blob SHA `97b83d68a683df77c1e0557838c24a1b4fb65169` |
| Current Picker | `companies/company-1/warehouse/picker.html`, blob SHA `d483bd15b36585b975b63c2ef641481a01d5d084` |
| Shared core | `companies/company-1/core.js`, blob SHA `ff2f581d9900543c16f7cb026e13446520c0329d` |
| Loader preview change | commit `152e5b1d22aab94d2cf01070778b357df4701aff`, refactors `App._showPreviewModal` from a modal to inline content |
| Historical Loader | `rawaie-erp-review/PWA/warehouse/loader.html`, SHA `7e61b04d0d9a480d43763e8b7b21f9cbed78409a` |
| Historical Picker | `rawaie-erp-review/PWA/warehouse/picker.html`, SHA `7626ba320021a607854bf219f4bacd81fc3d1d92` |
| Production Edge | `start-loading v5`, `complete-loading v11`; both `verify_jwt=true` |
| Production DB | policies for `runsheets` and `run_sheet_details` constrain reads to current company and authorized warehouse/runsheet/report permission |
| Runtime logs | authenticated browser requests to the runsheet list returned HTTP 200 on 2026-10-23; not proof of served HTML SHA |

## 3. ROOT CAUSE

The current Picker branch in `App.openRunsheet(code)` (lines 570–581 in the fetched blob) renders a short header and a basic clickable item list. It does not match Loader’s richer in-page preview: no total requested quantity summary, no consistent item metadata card, and no description visible without opening a modal. The list also inserts database text into HTML and inline JavaScript handlers without reliable escaping.

This is a **Picker UI completeness/safety gap**, not a Production inventory-core defect. Preserve the business distinction: Picker displays requested quantities and item descriptions; Loader displays picked/loaded quantities and financial preview. Do not copy Loader’s price/value fields into Picker because they are not required for the picking role.

## 4. OWNER-ONLY SURGICAL CHANGE #1 — Picker preview branch

**File:** `papamohammed77-glitch/erp-frontend/companies/company-1/warehouse/picker.html`  
**Current blob SHA:** `d483bd15b36585b975b63c2ef641481a01d5d084`  
**Function:** `App.openRunsheet(code)`  
**Approximate current lines:** 570–581. Reconfirm the exact block against the SHA before editing; line numbers are not stable after any new commit.

### Locator

Inside the `detRes.then(function(detRes){...})` callback, locate this exact start:

```js
                var html = '';
                html += '<div class="flex items-center gap-3 mb-6"><button onclick="App.renderPendingTab()" class="w-10 h-10 bg-white rounded-2xl flex items-center justify-center text-indigo-600 shadow-sm"><i class="fa-solid fa-arrow-right"></i></button><span class="font-black text-xl text-slate-800">' + code + ' | عدد الأصناف: ' + itemCount + '</span></div>';
```

Replace from `var html = '';` through and including:

```js
                safeHTML(byId('mainContent'), html);
```

Do not replace the enclosing `openRunsheet` function or the preceding active-session logic.

### Complete replacement block

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

                html += '<div class="bg-indigo-50 rounded-3xl p-5 mb-5">';
                html += '<div class="flex items-start justify-between gap-3"><div>';
                html += '<p class="text-xs text-indigo-500 font-bold mb-1">رقم الرانشيت</p>';
                html += '<h3 class="font-black text-2xl text-slate-800">' + escHtml(code) + '</h3>';
                html += '<p class="text-xs text-slate-500 mt-2">التاريخ: ' + escHtml(rs.run_date || '') + '</p>';
                html += '</div><span class="px-3 py-1 rounded-full bg-white text-indigo-600 text-xs font-bold">' + (rs.status === 'Confirmed' ? 'مؤكد' : 'مفتوح') + '</span></div></div>';

                html += '<div class="grid grid-cols-2 gap-3 mb-5">';
                html += '<div class="card"><p class="text-xs text-slate-400">عدد الأصناف</p><p class="font-black text-xl text-slate-800 mt-1">' + items.length + '</p></div>';
                html += '<div class="card"><p class="text-xs text-slate-400">إجمالي الكمية المطلوبة</p><p id="pickerPreviewTotalQty" class="font-black text-xl text-indigo-600 mt-1">0</p></div>';
                html += '</div>';

                html += '<div class="flex items-center justify-between mb-3"><h3 class="font-black text-slate-800">أصناف الرانشيت</h3><span class="text-xs text-slate-400">تفاصيل التحضير</span></div>';

                if (!items.length) {
                    html += '<div class="card text-center py-10"><i class="fa-solid fa-box-open text-3xl text-slate-300 mb-3"></i><p class="font-bold text-slate-500">لا توجد أصناف في هذا الرانشيت.</p></div>';
                } else {
                    for (var k = 0; k < items.length; k++) {
                        var it = items[k] || {};
                        var requestedQty = Number(it.qty_ordered) || 0;
                        totalRequested += requestedQty;

                        html += '<button type="button" class="card w-full text-right mb-3 slide-in" data-picker-item-index="' + k + '">';
                        html += '<div class="flex items-start gap-3"><div class="shrink-0">' + self._img(it.item_code) + '</div>';
                        html += '<div class="min-w-0 flex-1"><p class="font-bold text-slate-800">' + escHtml(it.item_name || '') + '</p>';
                        html += '<p class="text-xs text-slate-400 mt-1">' + escHtml(it.item_code || '') + ' | ' + escHtml(it.unit || 'حبة') + '</p>';
                        html += '<div class="grid grid-cols-2 gap-2 mt-3 text-sm">';
                        html += '<div class="bg-indigo-50 rounded-xl p-2"><p class="text-[11px] text-slate-400">الكمية المطلوبة</p><p class="font-black text-indigo-700">' + requestedQty + '</p></div>';
                        html += '<div class="bg-slate-50 rounded-xl p-2"><p class="text-[11px] text-slate-400">الوصف</p><p class="font-semibold text-slate-700">' + escHtml(it.description || 'لا يوجد وصف مسجل') + '</p></div>';
                        html += '</div></div></div></button>';
                    }
                }

                if (canStart) {
                    html += '<div class="sticky-top pt-2 pb-3 bg-slate-50">';
                    html += '<button type="button" id="pickerPreviewStart" class="btn-primary"><i class="fa-solid fa-play ml-2"></i> بدء التحضير</button>';
                    html += '<p class="text-center text-xs text-slate-400 mt-2">المعاينة لا تغيّر المخزون؛ يبدأ الحجز والتحضير بعد تأكيد البدء.</p>';
                    html += '</div>';
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
                            selectedItem.description || ''
                        );
                    });
                }
```

## 5. OWNER-ONLY SURGICAL CHANGE #2 — Escape item values in detail modal

The existing `App.showItemDetail` (current lines 590–594) inserts item name, code, unit and description directly into SweetAlert HTML. Because the preview opens this modal, replace this function too; this is limited to the same preview/detail flow and avoids turning database text into executable markup.

### Locator

Find:

```js
    showItemDetail: function(code, name, unit, qty, desc){
```

Replace only this function, through its closing `},`, with:

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
        var safeImg = /^(https?:\/\/|\/)/i.test(img) ? escHtml(img) : '';
        var imgHtml = safeImg
            ? '<img src="' + safeImg + '" alt="" class="w-full h-80 object-contain bg-white rounded-2xl mb-4 shadow-sm" onerror="this.style.display=\'none\'">'
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

## 6. Why no Production/Supabase change

- The defect is in rendering and escaping of data already read by Picker.
- Existing `start-picking` remains the only start-of-picking operation; no new Edge Function is needed.
- Do not change `reserve_stock`, `post_stock_movement`, RLS, grants, schema, or inventory data for this visual change.
- The preview itself must not reserve or move stock. The actual reservation remains in the existing start/complete picking lifecycle.

## 7. Required verification after owner applies the patch

1. Open an `Open` runsheet and a `Confirmed` runsheet: both show inline preview, status, date, item count, total requested quantity, image, code, unit, requested quantity, and description.
2. Back button returns to pending list and does not start a run.
3. Start button appears only for `Open`/`Confirmed`, invokes the existing `startPicking(code)`, and never invokes a stock movement from the preview itself.
4. An item card opens its detail modal; HTML-like item names/descriptions render as text, not markup.
5. Empty runsheet shows the empty state and does not throw.
6. Mobile viewport: no horizontal overflow; sticky start action remains reachable.
7. Re-run with another company context: no cross-company runsheet/details are exposed.
8. Confirm the active Picking session path remains unchanged and the picker’s offline draft restore remains intact.
9. After deployment, inspect Network response and served HTML identity. Current Supabase logs show authenticated runsheet-list reads returning HTTP 200, but this is not proof of served HTML/source parity.
10. Confirm Production inventory values and allocations are unchanged before/after preview. Do not create synthetic Production orders or alter real stock to test a display-only patch.

## 8. Closure

- **Proved:** current Git source difference, exact Picker preview block, relevant Production read policies, existing authenticated start-loading/complete-loading versions, and that this change needs no DB/Edge deployment.
- **Not proved:** owner application, Cloudflare deployment, served HTML parity, browser E2E, or post-deployment behavior.
- **Production changes performed:** none.
- **Status:** `SURGICAL OWNER PATCH READY / NOT CLOSED UNTIL OWNER DEPLOY + BROWSER VERIFICATION`.

## SELF-AUDIT FINAL

- **What I Proved:** Loader current preview is inline; Picker preview is inline but materially less complete; Production read policies are company/permission constrained; existing Edge workflow remains the correct execution path.
- **What I Did Not Prove:** deployed HTML identity or successful browser E2E after the patch.
- **What I Fixed:** no operational code was changed by the assistant; the two complete owner-applied surgical replacements are specified above.
- **What I Initially Missed:** the old Report466 source SHA predates the latest Loader preview refactor; current files had to be re-fetched and re-compared.
- **What Could Still Be Wrong:** the deployed Cloudflare Pages artifact may differ from current Git; actual item image URLs may use a non-HTTP relative scheme and would then fall back to the placeholder in the patched modal.
- **Final Confidence:** high for source diagnosis and patch targeting; runtime confidence remains unverified until the owner deploys and tests.
- **Final Closure Status:** `OPEN — OWNER PATCH + SERVED BROWSER E2E REQUIRED`.
