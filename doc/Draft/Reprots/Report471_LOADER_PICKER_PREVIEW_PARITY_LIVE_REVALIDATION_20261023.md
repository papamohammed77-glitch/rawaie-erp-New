# Report471 — حزمة التعديل الجراحي المستقلة لمعاينة Loader / Picker

**تاريخ التنفيذ:** 2026-10-23  
**النطاق:** معاينة الرانشيت في Picker فقط، بمقارنة مباشرة مع معاينة Loader الحالية.  
**قاعدة الملكية:** لا يغيّر المساعد ملفات التطبيقات التشغيلية. المالك هو من يدمج التعديلات في Picker.  
**نتيجة هذا التحديث:** تقرير Report471 أصبح يحتوي جميع الكتل البديلة كاملةً، ولا يعتمد على نسخ كتلة من تقرير أقدم. لم تُعدّل ملفات التشغيل ولم تتغير بيانات Production.

## 1. SELF-AUDIT قبل التعديل

**Business Understanding:** Picker يعرض الصنف والكمية المطلوبة والوصف قبل بدء التحضير؛ Loader يعرض الكمية التي تم تحضيرها والكميات التي ستُحمّل والتقدير المرتبط بمرحلة التحميل. يجب تحقيق اتساق التجربة البصرية دون نسخ حقول مرحلة التحميل إلى مرحلة التحضير.

**Architecture Understanding:** التطبيقان منفصلان لكنهما يستخدمان قاعدة البيانات المشتركة وCore الحالي. بدء التحضير يجب أن يبقى عبر startPicking الحالية وEdge الحالية، دون إنشاء Endpoint جديد أو تعديل دورة الحجز.

**Database Understanding:** الوصف لا يأتي من run_sheet_details. المصدر الصحيح هو items.description عبر FK run_sheet_details_item_id_fkey.

**Historical Understanding:** تمت مراجعة Master Governance OS، وCURRENT_STATE، والتقارير 466–470، وGit commits ذات الصلة. التقارير السابقة عوملت كدلائل تاريخية، ثم تمت مطابقة ملفات المصدر وقاعدة Production مجددًا.

**Production Understanding:** Supabase project: fiilmooggumokxanwiyx. فحص مباشر للـSchema والعلاقات وRLS وEdge. لا يتطلب التغيير المعروض تعديل Production.

**Current Understanding:** Loader SHA 97b83d68a683df77c1e0557838c24a1b4fb65169؛ Picker SHA d483bd15b36585b975b63c2ef641481a01d5d084؛ Core SHA ff2f581d9900543c16f7cb026e13446520c0329d.

**Execution Confidence:** مرتفع في التشخيص وعقد البيانات. لا يوجد دليل على تطبيق المالك أو النشر أو نجاح اختبار المتصفح بعد التعديل.

### الحقائق والشكوك

**Confirmed Facts**
- Loader يعرض معاينة داخل mainContent مع ملخصات وبطاقات أصناف، زر رجوع، وزر بدء تحميل منفصل.
- Picker ما زال يعرض معاينة مختصرة داخل App.openRunsheet.
- run_sheet_details.description غير موجود.
- items.description وitems.image_url موجودان.
- run_sheet_details.item_id يرتبط بـitems.id عبر run_sheet_details_item_id_fkey.
- Edge الحالية: start-picking v35، complete-picking v18، start-loading v5، complete-loading v11؛ كلها ACTIVE وverify_jwt=true.
- فحص Production في 2026-10-23 11:56:09 UTC وجد رانشيتين بحالة Picked ضمن بيانات الشركة المعنية، ولا توجد رانشيتات Open أو Confirmed عند العد الحالي.

**Unknowns**
- هل الملف الذي يخدمه Cloudflare مطابق لنسخة Git الحالية.
- هل المالك سيدمج التعديل وينشره، ونتيجة Browser E2E بعد النشر.
- لا يوجد في هذا الفحص إثبات لعرض حالة Open أو Confirmed في المتصفح الحي؛ هذه الحالات غير موجودة في العد الحالي بقاعدة Production.

**Conflicts / Historical Corrections**
- الاقتراح القديم في Report467 كان يقرأ it.description رغم أن العمود غير موجود في run_sheet_details؛ لا تستخدمه.
- Report468 صحح علاقة الوصف، وReport469/470 صححا حالة Picked. هذه النسخة تضم التصحيحات كاملة.
- سطر وصف الصنف داخل مسار استعادة جلسة Picking النشطة كان أيضًا يقرأ الحقل القديم غير الموجود؛ لذلك تضيف الحزمة تصحيحًا جراحيًا لسطر واحد حتى لا تبقى البيانات ناقصة في نافذة تعديل الصنف بعد إضافة العلاقة.

**Unverified Claims**
- لم يجرِ Browser E2E بعد تطبيق التعديل.
- لم يثبت تطابق Cloudflare served HTML مع SHA الخاص بـGit.
- لا تُعلن هذه المهمة مغلقة نهائيًا قبل الدمج والنشر والتحقق الفعلي.

## 2. المصادر الحالية وGit history

| المصدر | الحالة المثبتة |
|---|---|
| companies/company-1/warehouse/loader.html | SHA 97b83d68a683df77c1e0557838c24a1b4fb65169، 332 سطرًا |
| companies/company-1/warehouse/picker.html | SHA d483bd15b36585b975b63c2ef641481a01d5d084، 1058 سطرًا |
| companies/company-1/core.js | SHA ff2f581d9900543c16f7cb026e13446520c0329d، 773 سطرًا |
| Loader preview refactor | commit 152e5b1d22aab94d2cf01070778b357df4701aff؛ parent e69c9af4b56d99ba29a4fa74282f78438b9f7010 |
| آخر Picker commit مطابق | commit eee31fe44d8fc1cee384ad66a8d7a36be2e3c1b7؛ parent fbcd4c7e1845236455f026eb3f7ae0ccfa8ba407 |

هذه المراجع خاصة بلقطة المصدر المذكورة. يجب إعادة جلب Picker والتحقق من SHA قبل التطبيق، وإعادة تحديد مواضع التعديل إذا تغير.

## 3. Production — قاعدة البيانات والصلاحيات

فحص SQL للـProduction عند 2026-10-23 11:56:09 UTC أثبت:
- items.description = موجود.
- items.image_url = موجود.
- run_sheet_details.description = غير موجود.
- run_sheet_details_item_id_fkey يربط run_sheet_details.item_id بـitems.id.
- run_sheet_details_runsheet_id_fkey يربط تفاصيل الرانشيت بـrunsheets.id.
- سياسات RLS الحية تقصر runsheets وitems على الشركة الحالية والصلاحيات، وتتيح تفاصيل الرانشيت فقط عندما يكون الرانشيت الأب ضمن الشركة الحالية ويتوافر إذن runsheets أو warehouse أو reports.
- يوجد حاليًا رانشيتان بحالة Picked: RS-1 (5 تفاصيل، إجمالي qty_ordered = 14) وRS-2 (7 تفاصيل، إجمالي qty_ordered = 9). ليس هناك Open أو Confirmed حاليًا في العد المباشر.
- لم تُكتب أو تُعدّل أو تُحذف بيانات أعمال، ولم تُنشأ بيانات اختبار.

لا يوجد سبب تقني لتغيير schema أو RLS أو RPC أو Edge؛ فجوة المهمة عرضية وقراءة الحقول المطلوبة متاحة عبر العلاقة الصحيحة. لا تنشئ سجلات تجريبية في بيانات Production لعرض معاينة فقط.

## 4. Owner Change Set — تعديل جراحي

### Patch A — إحضار الوصف من العلاقة الصحيحة

**الملف:** companies/company-1/warehouse/picker.html  
**الدالة:** App.openRunsheet(code)  
**الموضع الحالي:** سطر 516–518 تقريبًا في SHA أعلاه.

**ابحث عن هذا المقطع بالضبط:**

~~~js
    .from('run_sheet_details')
    .select('*')
    .eq('runsheet_id', rs.id)
~~~

**استبدل الأسطر الثلاثة فقط بهذا النص:**

~~~js
    .from('run_sheet_details')
    .select('*, items!run_sheet_details_item_id_fkey(description)')
    .eq('runsheet_id', rs.id)
~~~

هذا يستعمل اسم FK المثبت في Production، ولا يضيف عمودًا ولا يغيّر schema.

### Patch A2 — تصحيح قراءة وصف الصنف في الجلسة النشطة

هذه نقطة اعتماد مباشرة للـPatch A: بعد أن يصبح الوصف ضمن العلاقة المتداخلة، يجب أن تقرأه تهيئة جلسة Picking من المسار الصحيح بدل قراءة عمود غير موجود.

**داخل App.openRunsheet(code)، في حلقة بناء self.session.items، ابحث عن هذا السطر فقط:**

~~~js
                            description: items[i].description || '',
~~~

**استبدله بهذا السطر:**

~~~js
                            description: (items[i].items && items[i].items.description) || '',
~~~

لا تستبدل حلقة الجلسة ولا دالة استعادة Dexie. هذا السطر يحافظ على السلوك الحالي ويصحح مصدر الوصف فقط.

### Patch B — استبدال المعاينة المختصرة فقط

**الدالة:** App.openRunsheet(code)  
**الموضع الحالي:** يبدأ عند var html = ''; قرب السطر 570، وينتهي عند safeHTML(byId('mainContent'), html); قرب السطر 580 في SHA الحالي.

ابقِ كما هو كل ما قبل هذا المقطع، وبالأخص:
- فحص الشركة وملكية الرانشيت.
- قراءة التفاصيل ومعالجة detRes.error.
- فرع استعادة جلسة Picking النشطة بما فيه Dexie.
- حدّ الإغلاق الخارجي للـthen؛ لا تستبدل App.openRunsheet كاملة.

**احذف فقط كتلة المعاينة الحالية** التي تبدأ بـvar html = ''; وتنتهي بـsafeHTML(byId('mainContent'), html);، ثم الصق البديل الكامل التالي:

~~~js
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
                html += '<p class="text-xs text-slate-400 mt-1">' + (canStart ? 'راجع الأصناف والكميات والوصف قبل بدء التحضير' : 'عرض تفاصيل الرانشيت') + '</p></div></div>';

                html += '<div class="bg-indigo-50 rounded-3xl p-5 mb-5">';
                html += '<div class="flex items-start justify-between gap-3"><div>';
                html += '<p class="text-xs text-indigo-500 font-bold mb-1">رقم الرانشيت</p>';
                html += '<h3 class="font-black text-2xl text-slate-800">' + escHtml(code) + '</h3>';
                html += '<p class="text-xs text-slate-500 mt-2">التاريخ: ' + escHtml(rs.run_date || '') + '</p>';
                html += '</div>';

                var previewStatusLabel =
                    rs.status === 'Picked' ? 'مكتمل التحضير' :
                    rs.status === 'Confirmed' ? 'مؤكد' :
                    rs.status === 'Open' ? 'مفتوح' :
                    rs.status === 'Picking' ? 'قيد التحضير' :
                    rs.status === 'Loading' ? 'قيد التحميل' :
                    rs.status === 'Loaded' ? 'تم التحميل' :
                    (rs.status || 'غير محدد');

                html += '<span class="px-3 py-1 rounded-full bg-white text-indigo-600 text-xs font-bold">' + escHtml(previewStatusLabel) + '</span></div></div>';

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
                        var itemDescription = (it.items && it.items.description) || '';
                        totalRequested += requestedQty;

                        html += '<button type="button" class="card w-full text-right mb-3 slide-in" data-picker-item-index="' + k + '">';
                        html += '<div class="flex items-start gap-3"><div class="shrink-0">' + self._img(it.item_code) + '</div>';
                        html += '<div class="min-w-0 flex-1"><p class="font-bold text-slate-800">' + escHtml(it.item_name || '') + '</p>';
                        html += '<p class="text-xs text-slate-400 mt-1">' + escHtml(it.item_code || '') + ' | ' + escHtml(it.unit || 'حبة') + '</p>';
                        html += '<div class="grid grid-cols-2 gap-2 mt-3 text-sm">';
                        html += '<div class="bg-indigo-50 rounded-xl p-2"><p class="text-[11px] text-slate-400">الكمية المطلوبة</p><p class="font-black text-indigo-700">' + requestedQty + '</p></div>';
                        html += '<div class="bg-slate-50 rounded-xl p-2"><p class="text-[11px] text-slate-400">الوصف</p><p class="font-semibold text-slate-700">' + escHtml(itemDescription || 'لا يوجد وصف مسجل') + '</p></div>';
                        html += '</div></div></div></button>';
                    }
                }

                if (canStart) {
                    html += '<div class="sticky-top pt-2 pb-3 bg-slate-50">';
                    html += '<button type="button" id="pickerPreviewStart" class="btn-primary"><i class="fa-solid fa-play ml-2"></i> بدء التحضير</button>';
                    html += '<p class="text-center text-xs text-slate-400 mt-2">المعاينة لا تغيّر المخزون؛ يبدأ الحجز والتحضير بعد تأكيد البدء.</p></div>';
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
                            (selectedItem.items && selectedItem.items.description) || ''
                        );
                    });
                }
~~~

**بعد اللصق:** اترك الإغلاق الخارجي الحالي للـthen كما هو؛ لا تكرره ولا تحذفه.

الأثر: معاينة داخل الصفحة مع عدد الأصناف وإجمالي الكمية المطلوبة وصورة/اسم/كود/وحدة/وصف. حالة Picked تسمى «مكتمل التحضير»، وحالات أخرى تعرض اسم الحالة الملائم. زر بدء التحضير لا يظهر إلا لـOpen/Confirmed. النقر على بطاقة الصنف يستخدم data index بدل بناء inline handler من نصوص قاعدة البيانات.

### Patch C — حماية روابط صور المعاينة

**الدالة:** App._img(code)، قرب السطر 585.  
**محدد البحث:** ابحث عن بداية الدالة الحالية ثم استبدل الدالة فقط حتى الفاصلة التي تنهيها.

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

هذا يقبل HTTP(S) أو مسارًا من نفس الموقع يبدأ بشرطة واحدة، ويرفض الروابط البروتوكولية النسبية التي تبدأ بـ//، وبقية البروتوكولات، ويهَرّب القيمة قبل إدخالها داخل src. عند فشل الصورة يظهر العنصر البديل.

### Patch D — تهريب قيم مودال تفاصيل الصنف

**الدالة:** App.showItemDetail(code, name, unit, qty, desc)، قرب السطر 590.  
**محدد البحث:** ابحث عن بداية الدالة الحالية واستبدل الدالة كاملة فقط.

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
        var safeImg = /^(https?:\/\/|\/(?!\/))/i.test(rawImg) ? escHtml(rawImg) : '';
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
~~~

## 5. ما لن يتغير

- لا تعدّل main.html أو loader.html أو core.js.
- لا تغيّر قواعد ملكية الرانشيت أو حالات Picking.
- لا تغيّر نقطة حفظ الكميات أو إتمام التحضير.
- لا تضف Edge Function أو RPC أو جدولًا أو سياسة RLS.
- لا تغيّر حجز المخزون أو allocated_qty أو qty.
- لا تنشئ بيانات أعمال تجريبية في Production.
- لا تُدخل قيمة السعر أو القيمة التقديرية من Loader إلى دور Picker؛ فهي ليست جزءًا من عقد عرض التحضير الحالي.

## 6. الاختبارات بعد دمج المالك ونشره

1. افتح رانشيتًا Open وConfirmed في بيئة اختبار معتمدة: تظهر معاينة داخل الصفحة والتاريخ والحالة وعدد الأصناف وإجمالي الكمية المطلوبة.
2. افتح رانشيت Picked الذي يسمح عقد الصلاحية بعرضه: تظهر «مكتمل التحضير» ولا يظهر زر بدء التحضير.
3. تأكد من ظهور الوصف من items.description في البطاقة والمودال، ومن أن نصًا يحوي HTML أو علامات اقتباس يظهر كنص ولا ينفذ.
4. تأكد من أن صور HTTP(S) والمسارات المحلية تعمل، والروابط //host أو javascript: لا تُحقن في src، وأن الصورة البديلة تعمل عند فشل التحميل.
5. اختبر الرانشيت الفارغ وBack وبدء التحضير للحالات المسموحة.
6. تحقق أن جلسة Picking النشطة واستعادة Dexie لم تتأثرا.
7. تحقق من الشركة والصلاحيات، وعدم ظهور بيانات شركة أخرى.
8. اختبار هاتف وسطح مكتب وعدم ظهور تمرير أفقي.
9. راقب Network وConsole، ثم تحقق من مطابقة HTML المنشور في Cloudflare للنسخة المنشورة من Git.
10. قارن المخزون والحجوزات قبل/بعد فتح المعاينة؛ يجب أن يبقيا ثابتين. لا تضغط بدء التحضير في Production على رانشيت حي لمجرد اختبار الشاشة.
11. الحالات Open وConfirmed غير موجودة في فحص Production الحالي؛ اختبرهما ببيانات اختبار معتمدة في Staging أو بيئة معزولة بعد النشر.

## 7. ما تم وما لم يتم

**تم:** مطابقة Loader وPicker الحاليين؛ مراجعة تاريخ commit وparent لكل منهما؛ مراجعة التقارير 465–470؛ مطابقة FK والأعمدة وRLS ونسخ Edge وقراءة عدد الرانشيتات الحالي مباشرة من Production؛ إعداد حزمة مستقلة كاملة للتعديل الجراحي وتضمين مصدر الوصف الصحيح في المسار النشط.

**لم يتم:** تطبيق التعديلات على ملفات التشغيل، أو نشر Cloudflare، أو Browser E2E بعد الدمج. لم يحدث تعديل في schema أو RLS أو RPC أو Edge أو بيانات الأعمال.

## SELF-AUDIT FINAL

**What I Proved**
- اختلاف المعاينة الحالي بين Loader وPicker.
- السبب العرضي في Picker: فرع معاينة مختصر، وعدم وجود الإجمالي، والاعتماد على وصف غير موجود في run_sheet_details، وإدخال قيم قاعدة البيانات دون تهريب شامل.
- عقد Production الصحيح للوصف وعلاقة FK وسياسات القراءة.
- نسخ Edge ذات الصلة الحالية وغياب تغير مخزون أو بيانات في هذه الدورة.

**What I Did Not Prove**
- أن المالك طبق Patch A–D.
- أن Cloudflare يقدم الـHTML المطابق للمصدر بعد النشر.
- نجاح الاختبار الفعلي Open/Confirmed/Picked بعد الدمج.

**What I Fixed**
- أصلحت مستند الإجراء السابق ليكون حزمة مستقلة تضم البدائل الكاملة بدل إحالة المالك إلى تقارير تاريخية.
- أضفت التصحيح الجراحي لسطر الوصف في جلسة Picking النشطة.
- شددت سياسة رابط الصورة لرفض //host بجانب رفض البروتوكولات غير المقبولة.
- لم أغيّر ملفات التطبيقات التشغيلية أو قاعدة Production.

**What I Initially Missed**
- التقارير القديمة لم تجعل حزمة التعديل مستقلة بالكامل، كما بقيت قراءة وصف الصنف في مسار الجلسة النشطة تشير إلى العمود القديم غير الموجود.

**What Could Still Be Wrong**
- قد يتغير SHA قبل تطبيق المالك، أو يختلف HTML المنشور عن Git.
- يجب اختبار صيغة العلاقة المتداخلة وعرضها في المتصفح الفعلي بعد النشر.
- لا توجد Open/Confirmed في عد Production الحالي، لذا لا يمكن إثبات هذه الحالات من البيانات الحية الحالية دون fixture معتمد.

**Final Confidence:** مرتفع في التشخيص وحزمة التعديل؛ متوسط في السلوك النهائي إلى حين الدمج والنشر والاختبار.

**Final Closure Status:** OWNER PATCH READY / PRODUCTION SCHEMA VERIFIED / NO PRODUCTION MUTATION / SERVED HTML PARITY + BROWSER E2E OPEN / NOT CLOSED.

## نقطة الاستئناف الدقيقة

1. أعد جلب Picker من GitHub وتحقق من SHA الحالي.
2. إذا كان ما يزال d483bd15b36585b975b63c2ef641481a01d5d084، طبّق Patches A وA2 وB وC وD فقط.
3. إذا تغيّر SHA، أعد تحديد محددات البحث ولا تستخدم أرقام الأسطر القديمة.
4. بعد دمج المالك ونشر الواجهة، اختبر السيناريوهات أعلاه وتحقق من HTML المقدم من Cloudflare.
5. لا تعلن الإغلاق قبل وجود دليل Browser E2E فعلي، ولا تغيّر قاعدة Production من أجل فجوة عرض فقط.
