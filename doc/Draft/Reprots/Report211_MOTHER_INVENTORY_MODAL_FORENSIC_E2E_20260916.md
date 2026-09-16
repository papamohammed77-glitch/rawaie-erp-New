# Report 211 — التحقيق الجنائي واختبار E2E لمودالات مركز التحكم في مخزون النظام الأم

**التاريخ:** 2026-09-16  
**الحالة:** تنفيذ/إغلاق Backend + جراحة واجهة مطلوبة من المالك  
**النظام الأم المعتمد:** `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

---

## 0. التنبيه الحاكم — نقطة البداية التي يجب عدم تجاوزها

الهدف هنا هو **اختبار E2E لملف النظام الأم الحالي**، وليس إعادة بناء النظام من التاريخ.

الحالة الحالية المعتمدة لا تأتي من Report210 أو أي تقرير سابق. التقارير السابقة استُخدمت فقط لفهم التاريخ واكتشاف أماكن التحقيق.

الحقيقة الحالية التي تم الاعتماد عليها هي:

```text
CURRENT GIT
+
CURRENT SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT EVIDENCE
```

ولإغلاق Mother Browser نهائيًا يلزم بالإضافة إلى ذلك:

```text
CURRENT BROWSER
+
CURRENT CONSOLE
+
CURRENT NETWORK
```

### Source of Truth الوحيد للـMother

```text
papamohammed77-glitch/erp-frontend
└── companies/company-1/main.html
```

الملفات التاريخية التالية ليست Source of Truth:

```text
rawaie-erp-New/Current/PWA/main2/*
rawaie-erp-New/Original/PWA/main/*
rawaie-erp-New/Current/PWA/main
rawaie-erp-New/Current/PWA/New-main
```

---

# 1. Current Git forensic state

## 1.1 آخر Commit فعلي

تمت مراجعة أحدث Commit مباشرة من GitHub:

```text
HEAD
02abd146d7df7703f1c2a18896d8ee3d9e8b0217
```

الرسالة:

```text
forensic: persist current Mother inventory extract
```

التاريخ:

```text
2026-09-16T07:29:00Z
```

## 1.2 الـParent المباشر

```text
0a3d944ed4498620a9c1ade2a43c5208337749c1
```

تم التحقق أن Commit `02abd...` لا يعدل `main.html`؛ التغيير فقط في forensic extract.

## 1.3 آخر Business Mother Commit قبل أدوات التحقيق

```text
e0c806e47a761561fc4177ffd2a4d9fc8d7d7dc9
```

وبالتالي لا يجوز تفسير تقدم أدوات الـforensic على أنه تعديل جديد في النظام الأم.

## 1.4 Current Mother source fingerprint

الـforensic extractor الحالي أثبت:

```text
FILE_LINES = 23,315
FILE_BYTES = 1,288,078
SHA256 = 8358f2f1f267f91b27b0745a6a2f4530366dab712272f74d6cad64e8df8d02a1
```

وآخر مصدر مباشر لـ`main.html` يحمل timestamp حديثًا في أعلى الملف:

```html
<!-- 2026-09-16 10:30 UTC -->
```

لم يتم تعديل `main.html` من جانب المساعد.

---

# 2. Current Mother forensic location of the target logic

الـ`RW_Warehouse` يبدأ عند:

```text
10950
```

الـ`loadInventoryControl()` الحالي يبدأ عند:

```text
13235
```

والـreturn object الخاص بـ`RW_Warehouse` يبدأ عند:

```text
13811
```

ويحوي بالفعل:

```js
loadInventoryControl: loadInventoryControl,
```

في السطر:

```text
13812
```

والـroute الحالي موجود في:

```text
21513
```

بالصيغة:

```js
if (view === 'inventory-control') { RW_Warehouse.loadInventoryControl(); return; }
```

إذن **الوضع الحالي لم يعد هو وضع Report210**. الـControl Plane موجود الآن في المصدر الحالي، ولا يجوز تطبيق patch قديم يفترض أنه مفقود.

---

# 3. مراجعة الوضع الحالي للمودالين

## 3.1 جلسة جرد جديدة

الدالة الحالية:

```text
13635 — 13671
```

الاسم:

```js
async function createCountSession()
```

المشكلة المثبتة:

- تنشئ جلسة فقط.
- تنتقل إلى تبويب `counts`.
- لا تُنشئ تفاصيل الجرد تلقائيًا عبر `POPULATE`.
- لا تفتح للمستخدم جلسة الجرد نفسها للتحرير.
- لا تتيح داخل المودال مقارنة System/Physical/Variance.
- لا تتيح Refresh System Count داخل جلسة الجرد.
- لا تتيح Finalize من نفس المسار.
- بالتالي فهي أقل من تجربة `جرد فرع` الموجودة فعليًا في النظام.

## 3.2 طلب نقل مخزني جديد

الدالة الحالية:

```text
13711 — 13781
```

الاسم:

```js
async function createStockRequest()
```

المشكلة المثبتة:

- إدخال الأصناف في textarea بصيغة `1001|5`.
- لا يوجد بحث حي في دليل الأصناف.
- لا تظهر الكمية المتاحة في الفرع المصدر.
- لا يظهر Available Before / Available After.
- لا يوجد cart واضح لإضافة وحذف وتعديل البنود.
- لا يظهر إجمالي الكمية أو حالة تجاوز المتاح بصورة واضحة.
- الواجهة لا تشبه جودة تجربة `تحويل مخزني` الموجودة.

هذه ليست مشكلة في الـbackend؛ إنها فجوة UX/Control Plane في الـMother.

---

# 4. Daftra benchmark used only as UX evidence

راجعت وثائق Daftra الرسمية الحالية الخاصة بالمخزون والجرد والنقل.

في النقل، يعرض Daftra مصدر ووجهة النقل، الأصناف، الكمية، و`Available Before` و`Available After`، مع بيانات العملية والملاحظات. citeturn309057search0turn309057search1

وفي الجرد، يعرض System Count وPhysical Count والملاحظات، ويدعم إضافة كل أصناف المخزن، المقارنة، تحديث أعداد النظام قبل التسوية، ثم Adjust. كما يدعم الجرد بالباركود/الصنف. citeturn309057search2turn309057search5turn309057search10

كما أن تقرير حركة المخزون التفصيلي في Daftra مبني على تتبع الحركة والمصدر والمخزن والكميات والقيمة عبر الزمن. citeturn309057search11

## ترجمة هذا على RAWAEA

لم يتم نسخ Daftra.

تم أخذ مبادئ UX فقط:

```text
Context
→ Item lookup
→ Live stock context
→ User action
→ Validation
→ Commit
→ Result
```

مع الإبقاء على سلسلة RAWAEA التشغيلية الأصلية:

```text
Orders
→ Picking
→ Reservation
→ Loading
→ Delivery
→ Return
→ Unloading
```

وعدم استبدال تطبيقات التشغيل الميدانية بمركز التحكم.

---

# 5. Current Production infrastructure — forensic result

## 5.1 Inventory Count

Production لديها:

```text
inventory_counts
inventory_count_details
inventory_count_engine
inventory_control
```

`inventory_count_engine` يدعم حاليًا:

```text
CREATE
GET
POPULATE
UPSERT_LINE
REFRESH
FINALIZE
CANCEL
```

وقد تم اختبار دورة:

```text
CREATE
→ POPULATE
→ GET
```

داخل Transaction مع rollback.

النتيجة:

```text
PASS
```

وتم إثبات أن الجلسة تحمل:

```text
company_id
branch_id
entity_id
operation_id
status
started_at
```

وأن تفاصيل الجرد تحمل:

```text
item_id
item_code
item_name
unit
system_qty
counted_qty
variance_qty
adjusted
branch_id
```

ولا توجد حاجة إلى جدول جديد لهذه النقطة.

## 5.2 Inventory Stock Request

Production لديها:

```text
inventory_stock_requests
inventory_stock_request_details
inventory_stock_request_engine
inventory_control
```

والـengine يدعم:

```text
CREATE
GET
APPROVE
REJECT
CONVERT
CANCEL
```

تم اختبار المسار:

```text
CREATE
→ GET
→ APPROVE
→ CONVERT
```

داخل Transaction مع rollback.

النتيجة:

```text
PASS
```

وتم إثبات إنشاء طلب مرتبط بشركة وفروع وأصناف حقيقية ثم تحويله إلى Voucher بدون ترك بيانات دائمة.

## 5.3 Physical Stock

لم يتم إنشاء Physical Writer جديد.

العقد الحالي بقي:

```text
Physical Movement
        ↓
post_stock_movement
        ↓
stock_branches
+
 inventory_log
```

وهذا مهم جدًا لأن المودالين لا يجوز أن يضيفا أي مسار كتابة موازٍ.

---

# 6. Security and tenant boundary

`inventory_control()` الحالي يعتمد على:

```text
auth.uid()
→ users.auth_id
→ users.company_id
```

ولا يعتمد على `app_settings LIMIT 1` لتحديد Tenant.

أما المودالان، فسيستمران في تمرير العمليات إلى:

```text
inventory_control()
```

بدل استدعاء Physical stock tables مباشرة.

ولم يتم توسيع permissions بلا سبب.

---

# 7. No new Production table / no new Edge Function required

تمت مراجعة الحاجة الفعلية قبل البناء.

النتيجة:

```text
New table required = NO
New relation required = NO
New Edge Function required = NO
New Physical Writer required = NO
```

الأساس الحالي مناسب بالفعل.

الناقص هو واجهة Control Plane مكتملة فوقه.

---

# 8. E2E infrastructure created

تم إنشاء Workflow جديد في المستودع:

```text
.github/workflows/inventory_control_modals_e2e_20260916.yml
```

الغرض منه:

- تحميل الـMother الحالي من Git.
- تشغيل Browser عبر Playwright.
- استدعاء `RW_Warehouse.loadInventoryControl()` فعليًا.
- محاكاة Production Control Plane عبر contract stubs دون الكتابة في Production.
- الضغط على `جلسة جرد جديدة`.
- إثبات استدعاء:
  - COUNT/CREATE
  - COUNT/POPULATE
- الضغط على `طلب نقل مخزني جديد`.
- إثبات استدعاء:
  - REQUEST/CREATE
- مراقبة Console/Page Errors.

الـWorkflow **workflow_dispatch فقط** ولا يتم تشغيله تلقائيًا حتى لا يتحول الحارس إلى مصدر فشل لكل push قبل أن يطبق المالك الجراحة المطلوبة.

---

# 9. Owner surgical change #1 — جلسة جرد جديدة

## لا تحذف أي شيء آخر

ابحث في **النسخة الحالية من `main.html`** عن:

```js
async function createCountSession() {
```

المقطع الحالي يبدأ عند السطر:

```text
13635
```

وينتهي عند السطر:

```text
13671
```

وتحديدًا آخر سطر للمقطع الحالي هو:

```js
        }
```

الواقع الحالي المؤكد هو أن هذا الإغلاق تابع لـ`createCountSession`.

### احذف المقطع كاملًا من:

```js
        async function createCountSession() {
```

### حتى آخر سطر:

```js
        }
```

### ثم استبدله بالكامل بالمقطع التالي

```js
        async function createCountSession() {
            var branchOptionsHtml = '';
            for (var i = 0; i < state.branches.length; i++) {
                branchOptionsHtml += '<option value="' + escIC(state.branches[i].id) + '">' +
                    escIC(state.branches[i].name || state.branches[i].branch_code) + '</option>';
            }

            var r = await Swal.fire({
                title: 'جلسة جرد جديدة',
                width: 760,
                html:
                    '<div class="text-right space-y-4">' +
                        '<div class="rounded-2xl bg-indigo-50 border border-indigo-100 p-4">' +
                            '<div class="font-black text-indigo-900">ابدأ جردًا فعليًا للفرع</div>' +
                            '<div class="text-sm text-indigo-700 mt-1">سيتم إنشاء الجلسة ثم تحميل أصناف الفرع تلقائيًا وفتح شاشة العد والمراجعة.</div>' +
                        '</div>' +
                        '<div class="grid grid-cols-1 md:grid-cols-2 gap-3">' +
                            '<div>' +
                                '<label class="block text-sm font-black text-slate-700 mb-2">الفرع</label>' +
                                '<select id="ic-count-branch" class="swal2-input !w-full !m-0">' + branchOptionsHtml + '</select>' +
                            '</div>' +
                            '<div>' +
                                '<label class="block text-sm font-black text-slate-700 mb-2">تاريخ الجرد</label>' +
                                '<input id="ic-count-date" type="date" class="swal2-input !w-full !m-0" value="' + new Date().toISOString().slice(0, 10) + '">' +
                            '</div>' +
                        '</div>' +
                        '<div>' +
                            '<label class="block text-sm font-black text-slate-700 mb-2">مرجع الجرد</label>' +
                            '<input id="ic-count-ref" class="swal2-input !w-full !m-0" placeholder="مثال: جرد نهاية اليوم / جرد دوري / جرد مفاجئ">' +
                        '</div>' +
                        '<div>' +
                            '<label class="block text-sm font-black text-slate-700 mb-2">ملاحظات</label>' +
                            '<textarea id="ic-count-notes" class="swal2-textarea !w-full !m-0" placeholder="ملاحظات الجرد أو تعليمات فريق العد"></textarea>' +
                        '</div>' +
                    '</div>',
                showCancelButton: true,
                confirmButtonText: 'بدء الجرد',
                cancelButtonText: 'إلغاء',
                focusConfirm: false,
                preConfirm: function() {
                    var branch = byId('ic-count-branch').value || '';
                    var countDate = byId('ic-count-date').value || '';
                    if (!branch) {
                        Swal.showValidationMessage('اختر الفرع أولًا');
                        return false;
                    }
                    if (!countDate) {
                        Swal.showValidationMessage('حدد تاريخ الجرد');
                        return false;
                    }
                    return {
                        branch: branch,
                        countDate: countDate,
                        ref: byId('ic-count-ref').value || '',
                        notes: byId('ic-count-notes').value || ''
                    };
                }
            });

            if (!r.isConfirmed) return;

            try {
                setBusy(true, 'جاري إنشاء جلسة الجرد وتجهيز أصناف الفرع...');

                var operationId = (window.crypto && window.crypto.randomUUID) ?
                    window.crypto.randomUUID() : ('IC-' + Date.now() + '-' + Math.floor(Math.random() * 100000));

                var created = await callIC('COUNT', {
                    operation: 'CREATE',
                    operation_id: operationId,
                    payload: {
                        type: 'branch',
                        entity_id: r.value.branch,
                        count_date: r.value.countDate,
                        reference: r.value.ref,
                        notes: r.value.notes
                    }
                });

                var countId = created.count_id;
                if (!countId) throw new Error('لم يتم إرجاع رقم جلسة الجرد');

                await callIC('COUNT', {
                    operation: 'POPULATE',
                    payload: { count_id: countId }
                });

                state.tab = 'counts';
                renderTabButtons();
                renderFilters();
                await refreshCounts();

                async function openCountEditor() {
                    var loaded = await callIC('COUNT', {
                        operation: 'GET',
                        payload: { count_id: countId }
                    });

                    var count = loaded.count || {};
                    var details = loaded.details || [];
                    var catalog = (RW_STATE && RW_STATE.data && Array.isArray(RW_STATE.data.items)) ? RW_STATE.data.items : [];

                    function barcodeOf(code) {
                        for (var bi = 0; bi < catalog.length; bi++) {
                            if (String(catalog[bi].item_code || '') === String(code || '')) {
                                return catalog[bi].barcode || '';
                            }
                        }
                        return '';
                    }

                    function renderCountTable(filter) {
                        filter = String(filter || '').trim().toLowerCase();
                        var rows = '';
                        for (var di = 0; di < details.length; di++) {
                            var d = details[di];
                            var barcode = barcodeOf(d.item_code);
                            var hay = [d.item_code, d.item_name, barcode].join(' ').toLowerCase();
                            if (filter && hay.indexOf(filter) === -1) continue;
                            rows +=
                                '<tr class="border-b hover:bg-slate-50" data-count-row="' + escIC(d.id) + '">' +
                                    '<td class="p-2 font-black text-indigo-700">' + escIC(d.item_code) + '</td>' +
                                    '<td class="p-2 font-semibold">' + escIC(d.item_name) + '</td>' +
                                    '<td class="p-2 text-center">' + escIC(d.unit || '') + '</td>' +
                                    '<td class="p-2 text-center font-bold text-slate-700">' + fmtIC(d.system_qty) + '</td>' +
                                    '<td class="p-2 text-center"><input data-count-input="' + escIC(d.id) + '" type="number" min="0" step="0.001" value="' + (d.counted_qty == null ? '' : escIC(d.counted_qty)) + '" class="w-28 px-2 py-2 border rounded-lg text-center font-black"></td>' +
                                    '<td class="p-2 text-center font-black" data-count-variance="' + escIC(d.id) + '">' + fmtIC(d.variance_qty) + '</td>' +
                                    '<td class="p-2"><input data-count-note="' + escIC(d.id) + '" value="' + escIC(d.notes || '') + '" class="w-40 px-2 py-2 border rounded-lg text-sm" placeholder="ملاحظة"></td>' +
                                '</tr>';
                        }
                        if (!rows) rows = '<tr><td colspan="7" class="p-10 text-center text-slate-500">لا توجد أصناف مطابقة للبحث</td></tr>';
                        return rows;
                    }

                    var editor = await Swal.fire({
                        title: 'جلسة الجرد — ' + escIC(count.reference || count.count_date || ''),
                        width: 1220,
                        showConfirmButton: false,
                        showCancelButton: false,
                        html:
                            '<div id="ic-count-editor" class="text-right">' +
                                '<div class="grid grid-cols-2 md:grid-cols-5 gap-2 mb-4">' +
                                    '<div class="rounded-xl bg-slate-50 border p-3"><div class="text-xs text-slate-500">الفرع</div><div class="font-black">' + escIC(count.branch_id || '') + '</div></div>' +
                                    '<div class="rounded-xl bg-blue-50 border border-blue-100 p-3"><div class="text-xs text-blue-700">إجمالي البنود</div><div id="ic-ce-total" class="font-black text-blue-900">' + fmtIC(details.length) + '</div></div>' +
                                    '<div class="rounded-xl bg-emerald-50 border border-emerald-100 p-3"><div class="text-xs text-emerald-700">تم العد</div><div id="ic-ce-counted" class="font-black text-emerald-900">0</div></div>' +
                                    '<div class="rounded-xl bg-amber-50 border border-amber-100 p-3"><div class="text-xs text-amber-700">عجز/زيادة</div><div id="ic-ce-variance" class="font-black text-amber-900">0</div></div>' +
                                    '<div class="rounded-xl bg-purple-50 border border-purple-100 p-3"><div class="text-xs text-purple-700">الحالة</div><div id="ic-ce-status" class="font-black text-purple-900">' + escIC(count.status || '') + '</div></div>' +
                                '</div>' +
                                '<div class="flex flex-wrap gap-2 mb-3">' +
                                    '<input id="ic-ce-search" class="flex-1 min-w-[240px] px-3 py-2 border rounded-xl" placeholder="ابحث بالكود أو اسم الصنف أو الباركود">' +
                                    '<button id="ic-ce-refresh" class="px-4 py-2 rounded-xl bg-slate-800 text-white font-bold">تحديث أرصدة النظام</button>' +
                                    '<button id="ic-ce-save" class="px-4 py-2 rounded-xl bg-blue-600 text-white font-bold">حفظ العد</button>' +
                                    '<button id="ic-ce-finalize" class="px-4 py-2 rounded-xl bg-emerald-600 text-white font-bold">إتمام وتسوية الجرد</button>' +
                                    '<button id="ic-ce-cancel" class="px-4 py-2 rounded-xl bg-red-50 text-red-700 font-bold">إلغاء الجلسة</button>' +
                                '</div>' +
                                '<div class="overflow-auto border rounded-2xl max-h-[58vh]">' +
                                    '<table class="w-full text-sm">' +
                                        '<thead class="bg-slate-800 text-white sticky top-0"><tr>' +
                                            '<th class="p-2">الكود</th><th class="p-2">الصنف</th><th class="p-2">الوحدة</th><th class="p-2">رصيد النظام</th><th class="p-2">العد الفعلي</th><th class="p-2">الفرق</th><th class="p-2">ملاحظة</th>' +
                                        '</tr></thead>' +
                                        '<tbody id="ic-ce-body">' + renderCountTable('') + '</tbody>' +
                                    '</table>' +
                                '</div>' +
                            '</div>',
                        didOpen: function() {
                            function updateSummary() {
                                var counted = 0;
                                var variance = 0;
                                var inputs = document.querySelectorAll('[data-count-input]');
                                for (var si = 0; si < inputs.length; si++) {
                                    if (inputs[si].value !== '') counted++;
                                }
                                for (var sj = 0; sj < details.length; sj++) {
                                    variance += Number(details[sj].variance_qty || 0);
                                }
                                safeText(byId('ic-ce-counted'), fmtIC(counted));
                                safeText(byId('ic-ce-variance'), fmtIC(variance));
                            }

                            byId('ic-ce-search').oninput = function() {
                                safeHTML(byId('ic-ce-body'), renderCountTable(this.value));
                            };

                            byId('ic-ce-refresh').onclick = async function() {
                                try {
                                    showLoader('جاري تحديث أرصدة النظام قبل استكمال الجرد...');
                                    await callIC('COUNT', { operation: 'REFRESH', payload: { count_id: countId, mode: 'ALL' } });
                                    var refreshed = await callIC('COUNT', { operation: 'GET', payload: { count_id: countId } });
                                    count = refreshed.count || count;
                                    details = refreshed.details || [];
                                    safeHTML(byId('ic-ce-body'), renderCountTable(byId('ic-ce-search').value));
                                    updateSummary();
                                    hideLoader();
                                    showToast('تم تحديث أرصدة النظام للجلسة', 'success');
                                } catch (e) {
                                    hideLoader();
                                    showToast(e.message || 'فشل تحديث أرصدة النظام', 'error');
                                }
                            };

                            byId('ic-ce-save').onclick = async function() {
                                try {
                                    showLoader('جاري حفظ كميات الجرد...');
                                    var inputs = document.querySelectorAll('[data-count-input]');
                                    for (var si = 0; si < inputs.length; si++) {
                                        var dId = inputs[si].getAttribute('data-count-input');
                                        var value = inputs[si].value;
                                        if (value === '') continue;
                                        var noteEl = document.querySelector('[data-count-note="' + dId + '"]');
                                        var detail = null;
                                        for (var di2 = 0; di2 < details.length; di2++) {
                                            if (String(details[di2].id) === String(dId)) { detail = details[di2]; break; }
                                        }
                                        if (!detail) continue;
                                        var countedQty = Number(value);
                                        if (!Number.isFinite(countedQty) || countedQty < 0) throw new Error('كمية جرد غير صالحة للصنف ' + detail.item_code);
                                        await callIC('COUNT', {
                                            operation: 'UPSERT_LINE',
                                            payload: {
                                                count_id: countId,
                                                branch_id: detail.branch_id,
                                                item_code: detail.item_code,
                                                counted_qty: countedQty,
                                                notes: noteEl ? (noteEl.value || '') : (detail.notes || '')
                                            }
                                        });
                                    }
                                    var reloaded = await callIC('COUNT', { operation: 'GET', payload: { count_id: countId } });
                                    count = reloaded.count || count;
                                    details = reloaded.details || [];
                                    safeHTML(byId('ic-ce-body'), renderCountTable(byId('ic-ce-search').value));
                                    updateSummary();
                                    safeText(byId('ic-ce-status'), count.status || 'InProgress');
                                    hideLoader();
                                    showToast('تم حفظ كميات الجرد', 'success');
                                } catch (e) {
                                    hideLoader();
                                    showToast(e.message || 'فشل حفظ الجرد', 'error');
                                }
                            };

                            byId('ic-ce-finalize').onclick = async function() {
                                var confirm = await Swal.fire({
                                    title: 'إتمام وتسوية الجرد؟',
                                    text: 'سيتم اعتماد الفروق وتنفيذ حركات التسوية الرسمية عبر محرك المخزون المركزي.',
                                    icon: 'warning',
                                    showCancelButton: true,
                                    confirmButtonText: 'إتمام الجرد',
                                    cancelButtonText: 'إلغاء'
                                });
                                if (!confirm.isConfirmed) return;
                                try {
                                    showLoader('جاري إتمام الجرد وتنفيذ التسويات...');
                                    await callIC('COUNT', { operation: 'FINALIZE', payload: { count_id: countId } });
                                    hideLoader();
                                    showToast('تم إتمام الجرد وتسوية الفروق بنجاح', 'success');
                                    Swal.close();
                                    await refreshCounts();
                                    await refreshCurrentTab();
                                } catch (e) {
                                    hideLoader();
                                    showToast(e.message || 'فشل إتمام الجرد', 'error');
                                }
                            };

                            byId('ic-ce-cancel').onclick = async function() {
                                var confirm = await Swal.fire({
                                    title: 'إلغاء جلسة الجرد؟',
                                    text: 'لن يتم تنفيذ أي تسوية مخزنية.',
                                    showCancelButton: true,
                                    confirmButtonText: 'إلغاء الجلسة',
                                    cancelButtonText: 'متابعة'
                                });
                                if (!confirm.isConfirmed) return;
                                try {
                                    await callIC('COUNT', { operation: 'CANCEL', payload: { count_id: countId } });
                                    showToast('تم إلغاء جلسة الجرد', 'success');
                                    Swal.close();
                                    await refreshCounts();
                                } catch (e) {
                                    showToast(e.message || 'فشل إلغاء الجلسة', 'error');
                                }
                            };

                            updateSummary();
                        }
                    });

                    return editor;
                }

                await openCountEditor();
            } catch (e) {
                showToast(e.message || 'فشل بدء جلسة الجرد', 'error');
            } finally {
                setBusy(false);
            }
        }
```

### النتيجة الوظيفية المطلوبة بعد الاستبدال

```text
جلسة جرد جديدة
→ تحديد الفرع
→ تحديد التاريخ
→ مرجع/ملاحظات
→ CREATE
→ POPULATE
→ GET
→ شاشة عد فعلية
→ حفظ العد
→ Refresh System Qty
→ Finalize
→ تسويات عبر post_stock_movement
```

وهذا يغلق الفجوة التي كانت تجعل زر الجرد شكليًا.

---

# 10. Owner surgical change #2 — طلب نقل مخزني جديد

## العنصر الحالي

ابحث عن:

```js
async function createStockRequest() {
```

المقطع الحالي يبدأ عند:

```text
13711
```

وينتهي عند:

```text
13781
```

وآخر سطر للمقطع هو:

```js
        }
```

### احذف المقطع كاملًا

من:

```js
        async function createStockRequest() {
```

حتى آخر `}` الخاص بالدالة نفسها.

### واستبدله بالكامل بالمقطع التالي

```js
        async function createStockRequest() {
            if (state.branches.length < 2) {
                showToast('يلزم وجود فرعي مصدر ووجهة مختلفين لإنشاء طلب نقل', 'warning');
                return;
            }

            var sourceOptions = '';
            var targetOptions = '';
            for (var i = 0; i < state.branches.length; i++) {
                var branch = state.branches[i];
                sourceOptions += '<option value="' + escIC(branch.id) + '">' + escIC(branch.name || branch.branch_code) + '</option>';
                targetOptions += '<option value="' + escIC(branch.id) + '">' + escIC(branch.name || branch.branch_code) + '</option>';
            }

            var sourceRows = [];
            var cart = [];

            function findSourceRow(code) {
                for (var ri = 0; ri < sourceRows.length; ri++) {
                    if (String(sourceRows[ri].item_code || '') === String(code || '')) return sourceRows[ri];
                }
                return null;
            }

            function cartIndex(code) {
                for (var ci = 0; ci < cart.length; ci++) {
                    if (String(cart[ci].item_code || '') === String(code || '')) return ci;
                }
                return -1;
            }

            function renderSearchResults(query) {
                query = String(query || '').trim().toLowerCase();
                var html = '';
                var shown = 0;
                for (var i2 = 0; i2 < sourceRows.length; i2++) {
                    var x = sourceRows[i2];
                    var hay = [x.item_code, x.item_name, x.barcode || ''].join(' ').toLowerCase();
                    if (query && hay.indexOf(query) === -1) continue;
                    if (cartIndex(x.item_code) !== -1) continue;
                    html +=
                        '<button type="button" data-ic-add-item="' + escIC(x.item_code) + '" class="w-full text-right p-3 rounded-xl border hover:bg-indigo-50 hover:border-indigo-200 mb-2 bg-white">' +
                            '<div class="flex items-center justify-between gap-3">' +
                                '<div>' +
                                    '<div class="font-black text-slate-800">' + escIC(x.item_name || x.item_code) + '</div>' +
                                    '<div class="text-xs text-slate-500 mt-1">' + escIC(x.item_code) + (x.barcode ? ' • ' + escIC(x.barcode) : '') + '</div>' +
                                '</div>' +
                                '<div class="text-left">' +
                                    '<div class="text-xs text-slate-500">المتاح</div>' +
                                    '<div class="font-black ' + (Number(x.available_qty || 0) > 0 ? 'text-emerald-700' : 'text-red-600') + '">' + fmtIC(x.available_qty) + '</div>' +
                                '</div>' +
                            '</div>' +
                        '</button>';
                    shown++;
                    if (shown >= 25) break;
                }
                if (!html) html = '<div class="p-6 text-center text-slate-500">لا توجد أصناف مطابقة أو تم إضافتها بالفعل</div>';
                return html;
            }

            function renderCart() {
                var html = '';
                var totalQty = 0;
                var totalValue = 0;
                for (var ci = 0; ci < cart.length; ci++) {
                    var x = cart[ci];
                    var before = Number(x.available_qty || 0);
                    var after = before - Number(x.qty || 0);
                    var qty = Number(x.qty || 0);
                    totalQty += qty;
                    totalValue += qty * Number(x.cost_price || 0);
                    html +=
                        '<tr class="border-b">' +
                            '<td class="p-2 font-black text-indigo-700">' + escIC(x.item_code) + '</td>' +
                            '<td class="p-2 font-semibold">' + escIC(x.item_name) + '</td>' +
                            '<td class="p-2 text-center">' + escIC(x.unit || '') + '</td>' +
                            '<td class="p-2 text-center font-bold text-slate-700">' + fmtIC(before) + '</td>' +
                            '<td class="p-2 text-center"><input data-ic-req-qty="' + escIC(x.item_code) + '" type="number" min="0.001" step="0.001" value="' + escIC(qty) + '" class="w-24 px-2 py-2 border rounded-lg text-center font-black"></td>' +
                            '<td class="p-2 text-center font-black ' + (after < 0 ? 'text-red-600' : 'text-emerald-700') + '">' + fmtIC(after) + '</td>' +
                            '<td class="p-2 text-center">' + fmtIC(Number(x.cost_price || 0)) + '</td>' +
                            '<td class="p-2 text-center font-black">' + fmtIC(qty * Number(x.cost_price || 0)) + '</td>' +
                            '<td class="p-2"><button type="button" data-ic-remove-item="' + escIC(x.item_code) + '" class="px-3 py-1 rounded-lg bg-red-50 text-red-700 font-bold">حذف</button></td>' +
                        '</tr>';
                }
                if (!html) html = '<tr><td colspan="10" class="p-10 text-center text-slate-500">لم تتم إضافة أصناف بعد</td></tr>';
                return { html: html, totalQty: totalQty, totalValue: totalValue };
            }

            async function loadSourceSnapshot(branchId) {
                var d = await callIC('SNAPSHOT', {
                    branch_id: branchId,
                    query: null,
                    low_only: false,
                    limit: 500,
                    offset: 0
                });
                sourceRows = d.rows || [];
            }

            var modal = await Swal.fire({
                title: 'طلب نقل مخزني جديد',
                width: 1280,
                showConfirmButton: false,
                showCancelButton: false,
                html:
                    '<div id="ic-request-editor" class="text-right">' +
                        '<div class="grid grid-cols-1 md:grid-cols-4 gap-3 mb-4">' +
                            '<div>' +
                                '<label class="block text-sm font-black text-slate-700 mb-2">من المخزن</label>' +
                                '<select id="ic-r-source" class="!w-full !m-0 swal2-input">' + sourceOptions + '</select>' +
                            '</div>' +
                            '<div>' +
                                '<label class="block text-sm font-black text-slate-700 mb-2">إلى المخزن</label>' +
                                '<select id="ic-r-target" class="!w-full !m-0 swal2-input">' + targetOptions + '</select>' +
                            '</div>' +
                            '<div class="rounded-xl bg-blue-50 border border-blue-100 p-3"><div class="text-xs text-blue-700">عدد البنود</div><div id="ic-r-total-lines" class="text-xl font-black text-blue-900">0</div></div>' +
                            '<div class="rounded-xl bg-emerald-50 border border-emerald-100 p-3"><div class="text-xs text-emerald-700">إجمالي الكمية</div><div id="ic-r-total-qty" class="text-xl font-black text-emerald-900">0</div></div>' +
                        '</div>' +
                        '<div class="grid grid-cols-1 lg:grid-cols-5 gap-4">' +
                            '<div class="lg:col-span-2 rounded-2xl bg-slate-50 border p-3">' +
                                '<div class="font-black text-slate-800 mb-2">إضافة صنف</div>' +
                                '<input id="ic-r-search" class="w-full px-3 py-2 border rounded-xl bg-white" placeholder="ابحث بالكود أو الاسم أو الباركود">' +
                                '<div id="ic-r-results" class="mt-3 max-h-[48vh] overflow-auto"></div>' +
                            '</div>' +
                            '<div class="lg:col-span-3 rounded-2xl bg-white border">' +
                                '<div class="flex items-center justify-between p-3 border-b">' +
                                    '<div class="font-black text-slate-800">بنود الطلب</div>' +
                                    '<div class="text-xs text-slate-500">Available After = Available Before − Requested Qty</div>' +
                                '</div>' +
                                '<div class="overflow-auto max-h-[48vh]">' +
                                    '<table class="w-full text-sm">' +
                                        '<thead class="bg-slate-800 text-white sticky top-0"><tr>' +
                                            '<th class="p-2">الكود</th><th class="p-2">الصنف</th><th class="p-2">الوحدة</th><th class="p-2">المتاح قبل</th><th class="p-2">الطلب</th><th class="p-2">المتاح بعد</th><th class="p-2">التكلفة</th><th class="p-2">الإجمالي</th><th class="p-2">إجراء</th>' +
                                        '</tr></thead>' +
                                        '<tbody id="ic-r-cart"></tbody>' +
                                    '</table>' +
                                '</div>' +
                            '</div>' +
                        '</div>' +
                        '<div class="mt-4">' +
                            '<textarea id="ic-r-notes" class="w-full px-3 py-2 border rounded-xl" rows="3" placeholder="ملاحظات الطلب / سبب النقل"></textarea>' +
                        '</div>' +
                        '<div class="flex flex-wrap justify-end gap-2 mt-4">' +
                            '<button id="ic-r-close" type="button" class="px-5 py-2 rounded-xl bg-slate-100 text-slate-700 font-bold">إغلاق</button>' +
                            '<button id="ic-r-submit" type="button" class="px-5 py-2 rounded-xl bg-indigo-600 text-white font-black">إنشاء طلب النقل</button>' +
                        '</div>' +
                    '</div>',
                didOpen: async function() {
                    function repaintCart() {
                        var p = renderCart();
                        safeHTML(byId('ic-r-cart'), p.html);
                        safeText(byId('ic-r-total-lines'), fmtIC(cart.length));
                        safeText(byId('ic-r-total-qty'), fmtIC(p.totalQty));

                        var qtyInputs = document.querySelectorAll('[data-ic-req-qty]');
                        for (var qi = 0; qi < qtyInputs.length; qi++) {
                            qtyInputs[qi].oninput = function() {
                                var code = this.getAttribute('data-ic-req-qty');
                                var idx = cartIndex(code);
                                if (idx === -1) return;
                                var value = Number(this.value);
                                cart[idx].qty = Number.isFinite(value) && value > 0 ? value : 0.001;
                                repaintCart();
                            };
                        }

                        var removeButtons = document.querySelectorAll('[data-ic-remove-item]');
                        for (var rb = 0; rb < removeButtons.length; rb++) {
                            removeButtons[rb].onclick = function() {
                                var code = this.getAttribute('data-ic-remove-item');
                                var idx = cartIndex(code);
                                if (idx !== -1) cart.splice(idx, 1);
                                repaintCart();
                                safeHTML(byId('ic-r-results'), renderSearchResults(byId('ic-r-search').value));
                                bindSearchButtons();
                            };
                        }
                    }

                    function bindSearchButtons() {
                        var addButtons = document.querySelectorAll('[data-ic-add-item]');
                        for (var ab = 0; ab < addButtons.length; ab++) {
                            addButtons[ab].onclick = function() {
                                var code = this.getAttribute('data-ic-add-item');
                                var row = findSourceRow(code);
                                if (!row) return;
                                if (cartIndex(code) !== -1) return;
                                cart.push({
                                    item_code: row.item_code,
                                    item_name: row.item_name,
                                    unit: row.unit,
                                    available_qty: Number(row.available_qty || 0),
                                    qty: 1,
                                    cost_price: Number(row.cost_price || row.avg_cost || 0)
                                });
                                repaintCart();
                                safeHTML(byId('ic-r-results'), renderSearchResults(byId('ic-r-search').value));
                                bindSearchButtons();
                            };
                        }
                    }

                    byId('ic-r-source').onchange = async function() {
                        var target = byId('ic-r-target').value || '';
                        if (target === this.value) {
                            for (var ti = 0; ti < state.branches.length; ti++) {
                                if (String(state.branches[ti].id) !== String(this.value)) {
                                    target = state.branches[ti].id;
                                    break;
                                }
                            }
                            byId('ic-r-target').value = target;
                        }
                        cart = [];
                        try {
                            showLoader('جاري تحميل رصيد الفرع المصدر...');
                            await loadSourceSnapshot(this.value);
                            safeHTML(byId('ic-r-results'), renderSearchResults(byId('ic-r-search').value));
                            bindSearchButtons();
                            repaintCart();
                            hideLoader();
                        } catch (e) {
                            hideLoader();
                            showToast(e.message || 'فشل تحميل رصيد الفرع', 'error');
                        }
                    };

                    byId('ic-r-target').onchange = function() {
                        if (this.value === byId('ic-r-source').value) {
                            showToast('المصدر والوجهة يجب أن يكونا مختلفين', 'warning');
                            for (var ti2 = 0; ti2 < state.branches.length; ti2++) {
                                if (String(state.branches[ti2].id) !== String(byId('ic-r-source').value)) {
                                    this.value = state.branches[ti2].id;
                                    break;
                                }
                            }
                        }
                    };

                    byId('ic-r-search').oninput = function() {
                        safeHTML(byId('ic-r-results'), renderSearchResults(this.value));
                        bindSearchButtons();
                    };

                    byId('ic-r-close').onclick = function() { Swal.close(); };

                    byId('ic-r-submit').onclick = async function() {
                        var source = byId('ic-r-source').value || '';
                        var target = byId('ic-r-target').value || '';
                        if (!source || !target || source === target) {
                            showToast('اختر مصدرًا ووجهة مختلفين', 'warning');
                            return;
                        }
                        if (!cart.length) {
                            showToast('أضف صنفًا واحدًا على الأقل إلى الطلب', 'warning');
                            return;
                        }
                        for (var vi = 0; vi < cart.length; vi++) {
                            if (!Number.isFinite(Number(cart[vi].qty)) || Number(cart[vi].qty) <= 0) {
                                showToast('كمية غير صالحة للصنف ' + cart[vi].item_code, 'error');
                                return;
                            }
                        }

                        try {
                            setBusy(true, 'جاري إنشاء طلب النقل وربطه بدورة المخزون...');
                            var operationId = (window.crypto && window.crypto.randomUUID) ?
                                window.crypto.randomUUID() : ('SR-' + Date.now() + '-' + Math.floor(Math.random() * 100000));

                            var items = [];
                            for (var ii = 0; ii < cart.length; ii++) {
                                items.push({
                                    item_code: cart[ii].item_code,
                                    qty: Number(cart[ii].qty)
                                });
                            }

                            var d = await callIC('REQUEST', {
                                operation: 'CREATE',
                                operation_id: operationId,
                                payload: {
                                    source_branch_id: source,
                                    target_branch_id: target,
                                    items: items,
                                    notes: byId('ic-r-notes').value || ''
                                }
                            });

                            Swal.close();
                            showToast(d.duplicate ? 'تم استرجاع طلب النقل السابق' : 'تم إنشاء طلب النقل بنجاح', 'success');
                            state.tab = 'requests';
                            renderTabButtons();
                            renderFilters();
                            await refreshRequests();
                        } catch (e) {
                            showToast(e.message || 'فشل إنشاء طلب النقل', 'error');
                        } finally {
                            setBusy(false);
                        }
                    };

                    try {
                        await loadSourceSnapshot(byId('ic-r-source').value);
                        safeHTML(byId('ic-r-results'), renderSearchResults(''));
                        bindSearchButtons();
                        repaintCart();
                    } catch (e2) {
                        showToast(e2.message || 'فشل تحميل بيانات المخزون', 'error');
                    }
                }
            });

            return modal;
        }
```

### النتيجة الوظيفية المطلوبة

```text
اختيار مصدر
→ تحميل Snapshot فعلي للفرع
→ بحث Item/Barcode
→ Add to Cart
→ Available Before
→ Requested Qty
→ Available After
→ Cost / Total
→ Notes
→ REQUEST/CREATE
→ Pending
```

ولا يكتب Physical Stock.

---

# 11. لماذا لم يتم تعديل `loadBranchCount` أو `loadVoucherForm`

لأنها ليست موضع المشكلة المطلوب إغلاقها في هذه الوحدة.

الهدف هو جعل المودالين الجديدين يقدمان Control Plane حقيقي فوق الـengines الموجودة، مع الحفاظ على التطبيقات التشغيلية المنفصلة.

لا يتم استبدال:

```text
جرد فرع
تحويل مخزني
```

بل يتم جعل نقطة الدخول السريعة في مركز التحكم مرتبطة بالعقد نفسه.

---

# 12. أخطاء ومحاولات أثناء التحقيق

## 12.1 خطأ تاريخي من تقرير سابق

Report210 كان يحمل أرقامًا قديمة مثل:

```text
loadInventoryControl = 20937
```

لكن Current Source الآن أثبت:

```text
loadInventoryControl route = 21513
loadInventoryControl implementation = 13235
```

لم يتم إعادة استخدام الأرقام القديمة.

## 12.2 فشل اختبار أولي للجرد

استُخدم UUID الشركة بدل UUID الفرع في اختبار Transaction.

Production رفضت العملية كما يجب:

```text
فرع الجرد غير صالح
```

تم تصحيح الاختبار باستخدام فرع حقيقي من Production، ثم:

```text
CREATE + POPULATE + GET = PASS
```

## 12.3 فحص Git عبر Container

محاولة clone المباشر من GitHub داخل الـcontainer فشلت بسبب عدم توفر DNS خارجي في البيئة.

لم يتم الاعتماد على هذه المحاولة.

تم استخدام GitHub Repository API/Blob evidence مباشرة.

---

# 13. Production current state after this task

لم يتم تنفيذ migration أو Edge Function جديد لأن التحقيق أثبت أن البنية الحالية كافية لهذه النقطة.

آخر migrations ذات الصلة التي ظهرت في Production:

```text
20260916071224  20260916_inventory_control_canonical_rpc
20260916071051  20260916_inventory_control_enable
20260916071027  20260916_inventory_control_realtime_registry_final
20260916070941  20260916_inventory_stock_requests_rls_support
```

هذه ما تزال جزءًا من Current Production evidence.

---

# 14. Current automated E2E guard

الـguard الجديد:

```text
.github/workflows/inventory_control_modals_e2e_20260916.yml
```

يُعتبر PASS بعد تطبيق الجراحات على الـMother عندما يثبت:

```text
Mother loads
+
RW_Warehouse.loadInventoryControl exists
+
Count modal opens
+
COUNT CREATE RPC invoked
+
COUNT POPULATE RPC invoked
+
Request modal opens
+
REQUEST CREATE RPC invoked
+
Console Errors = 0
+
Page Errors = 0
```

---

# 15. Browser closure status

## ما تم إثباته

```text
Current Git                         VERIFIED
Current parent                      VERIFIED
Current Mother source               VERIFIED
Current DB Count Engine             VERIFIED
Current DB Request Engine           VERIFIED
Current Production Control RPC      VERIFIED
Current security path               VERIFIED
Current schema sufficiency          VERIFIED
E2E guard infrastructure            CREATED
```

## ما لم يتم إثباته بعد

لأن `main.html` ملك المالك ولا يتم تعديله من المساعد:

```text
Owner surgical merge                OPEN
Live Browser E2E after merge        OPEN
Live Console E2E after merge        OPEN
Live Network E2E after merge        OPEN
Visual Gold/Diamond judgement       OPEN
```

لا يجوز تسمية هذه النقطة `100% CLOSED` قبل تطبيق الجراحة في `main.html` وتشغيل Browser E2E على النسخة المدمجة.

---

# 16. Global inventory status after this closure

```text
Physical Writers outside post_stock_movement   = 0
Inventory Control backend                     = CLOSED
Inventory Count Engine                        = CLOSED (DB contract)
Inventory Request Engine                      = CLOSED (DB contract)
Request RLS                                   = CLOSED
Realtime support                              = CLOSED
Mother Inventory Control shell                = CURRENT / PRESENT
Count Modal UX                                = OWNER SURGERY REQUIRED
Request Modal UX                              = OWNER SURGERY REQUIRED
Mother Browser E2E                            = OPEN
Global Inventory Zero-Debt                    = NOT 100% CLOSED
```

---

# 17. ماذا يجب أن يحدث بعد الدمج

بعد أن يقوم المالك بتطبيق الجراحتين:

1. افتح `companies/company-1/main.html` من `erp-frontend/main` فقط.
2. شغّل Workflow:

```text
RAWAEA — Inventory Control Modal E2E Guard
```

3. ثم نفّذ Browser E2E حي على البيئة المنشورة.
4. افحص Console.
5. افحص Network وتأكد أن العمليات تصل إلى:

```text
inventory_control
```

ولا تصل مباشرة إلى:

```text
stock_branches UPDATE
inventory_log INSERT
```

من الواجهة.
6. طابق القيم المعروضة لحظيًا مع Snapshot Production في نفس اللحظة.
7. لا تنتقل إلى النقطة التالية قبل إغلاق الأخطاء الناتجة فعليًا.

---

# 18. تعليمات البدء للمساعد/CTO التالي للوصول إلى الحقيقة

هذه هي التعليمات التنفيذية المقصودة أن تقرأها الجلسة القادمة قبل أي قرار:

## Step 1 — ابدأ من Git الحالي

اقرأ:

```text
erp-frontend/main HEAD
```

ثم:

```text
parent commit
```

ولا تعتمد على رقم موجود في تقرير تاريخي.

إذا كان آخر Commit مجرد forensic tooling، اصعد إلى آخر Business Commit وأثبت الفرق بين الاثنين.

## Step 2 — أعد استخراج Mother الحالي

المصدر الوحيد:

```text
companies/company-1/main.html
```

استخرج:

```text
lines
bytes
sha256
exact function locations
```

ولا تستخدم `main2` كحالة حالية.

## Step 3 — خذ Production snapshot قبل التقرير

افحص في نفس جلسة التحقيق:

```text
pg_proc
schema
constraints
RLS
realtime
triggers
grants
Edge Functions
```

## Step 4 — Trace the capability

استخدم هذا المسار:

```text
Mother
→ consumer function
→ inventory_control
→ engine
→ physical writer / ledger / audit / realtime
```

ولا تعتبر وجود زر في HTML دليلًا على وجود وظيفة كاملة.

## Step 5 — أثبت ما إذا كانت المشكلة UI أو Backend

قبل إنشاء جدول أو Edge جديد، ابحث أولًا عن:

```text
existing table
existing relation
existing RPC
existing engine
existing permission path
existing realtime contract
```

ولا تنشئ بنية مكررة.

## Step 6 — Writer Closure

كل إصلاح مستقل يصبح Closure Unit:

```text
Discover
→ Root Cause
→ Historical reconstruction
→ Target comparison
→ Surgical Fix
→ Test
→ Deploy if needed
→ Production Verify
→ Browser Verify
→ Close
```

## Step 7 — Physical Stock rule

لا تسمح بأي اختصار:

```text
post_stock_movement
```

هو العقد الوحيد للحركة الفعلية.

الجرد والتعديلات يجب أن تنتهي إلى الحركة المركزية.

## Step 8 — Tenant rule

عند وجود مستخدم:

```text
auth.uid()
→ users.auth_id
→ users.company_id
```

لا تستخدم `app_settings LIMIT 1` كبديل لحدود الشركة.

## Step 9 — UI E2E rule

لا تعتبر:

```text
RPC PASS
```

أو:

```text
DB PASS
```

إثباتًا للـMother.

لا يغلق الـMother إلا:

```text
Git
+
Production
+
Browser
+
Console
+
Network
+
DB
+
Realtime
```

## Step 10 — بعد الإغلاق

لا تعِد إصلاح شيء ثبت بالفعل.

انتقل فقط إلى أول Defect جديد تثبته الأدلة الحالية.

---

# 19. Final self-audit

## What I Proved

- Current Git HEAD is `02abd146...`.
- Current parent is `0a3d944...`.
- Current Mother is materially newer than the stale state recorded in Report210.
- Current Mother already contains executable `loadInventoryControl()`.
- Current Count Engine already supports a complete lifecycle.
- Current Request Engine already supports a complete lifecycle.
- No new Production table or Edge Function is necessary for the two target modals.
- Count CREATE/POPULATE/GET was verified transactionally.
- Request CREATE/GET/APPROVE/CONVERT was verified transactionally.
- `forensic_main_assembly.yml` already points to the correct Mother source and requires no change.
- An automated modal E2E guard was added to the frontend repository.

## What I Did Not Prove

- Final browser execution after the owner merges the replacements.
- Final live Console/Network state of the merged modal implementation.
- Final visual Gold/Diamond judgement of the rendered modal because the current Source of Truth has not yet incorporated the owner-side surgery.

## What I Fixed / Added

- No new Physical Writer.
- No duplicate inventory engine.
- Added automated E2E contract guard.
- Prepared two complete surgical replacements for the exact current modal functions.
- Preserved current production control/tenant architecture.

## What I Initially Missed / Corrected

- Previous report coordinates were stale.
- The current Mother already contains `loadInventoryControl()`.
- A backend redesign was not required for the requested UX gap.

## What Could Still Be Wrong

Only the owner-side integration of the two surgical replacements and its live Browser/Console/Network behavior remain unverified.

## Final Closure

```text
Backend capability                         CLOSED
Production infrastructure                  CLOSED / SUFFICIENT
Mother modal source                        OPEN — owner surgery
Authenticated Browser E2E                  OPEN
Global Inventory Zero-Debt                 NOT YET 100%
```
