# Report 210 — GLOBAL INVENTORY CONTROL / MOTHER SURGICAL CLOSURE

**التاريخ:** 2026-09-16

## تنبيه حاكم — نقطة البداية

الهدف الأساسي لهذه الجلسة هو الوصول إلى **الحالة الفعلية الحالية** لمشروع الروائع، وليس إعادة إنتاج أو تكرار ما ورد في تقارير سابقة. تم التعامل مع التقارير السابقة كمراجع تاريخية فقط.

الحقيقة المعتمدة في هذه الجلسة:

`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

ولا يتم رفع أي Closure إلى حالة مكتملة إلا بما تم إثباته من هذه المصادر الحالية.

النظام الأم المعتمد هو:

`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

ولم يتم تعديل هذا الملف مباشرة من جانبي.

---

## 1. Current Git forensic state

بعد بداية التحقيق تم إنشاء أداة استخراج جنائية للمصدر الحالي بسبب ضخامة `main.html`، دون تعديل الملف نفسه.

Latest frontend HEAD أثناء إغلاق الجلسة:

`6533ab8924c2a2fe76a78aabec413b4dae3019f0`

والـparent المباشر:

`2430b5b4922b53f218f7e4bd4c52a603e7ef8f0b`

والـbusiness commit الذي سبق أدوات الاستخراج:

`e0c806e47a761561fc4177ffd2a4d9fc8d7d7dc9`

الـbusiness commit أضاف فقط:

- `inventory-control` إلى قائمة إدارة المخازن والمخزون.
- route إلى `RW_Warehouse.loadInventoryControl()`.

المصدر الحالي المجمّع بقي هو Source of Truth؛ ملفات `Current/PWA/main2/*` و`Original/PWA/main/*` و`Current/PWA/main` و`New-main` لم تعامل كـSource of Truth.

---

## 2. Current Mother exact finding

الـforensic extraction أثبت:

- حجم الملف الحالي: `22,739` سطرًا.
- الحجم: `1,254,184` بايت.
- `loadInventoryControl` ظهر في **السطر 20,937 فقط**.
- لا يوجد تعريف تنفيذي مستقل آخر باسم `loadInventoryControl`.
- تعريف `RW_Warehouse` يبدأ في السطر `10,950`.
- الـreturn object الخاص بـ`RW_Warehouse` يبدأ في السطر `13,236`.
- آخر سطر في الـreturn object قبل الإغلاق هو السطر `13,297`.

السطر الحالي:

```js
20937: if (view === 'inventory-control') { RW_Warehouse.loadInventoryControl(); return; }
```

إذن Route موجود، لكن Control Plane نفسه غير موجود.

**النتيجة: هذا Defect حقيقي ومثبت، وليس مجرد نقص شكلي.**

---

## 3. Forensic review of existing Inventory workflow

الـMother الحالي يحتوي على:

- Receiving
- Picking
- Loading
- Delivery
- Return
- Unloading
- Stock Vouchers
- Vehicle Count
- Branch Count
- General Count
- Settlement

والعمليات الميدانية بقيت كما هي.

لم تتم إزالة أو إعادة بناء أي تطبيق ميداني منفصل.

كما أن `run_sheet_details` ما زال derived من `order_details` عبر trigger قائم؛ لذلك لم يتم إدخال Dual Write جديد.

---

## 4. Production Physical Stock forensic closure

فحص PostgreSQL الحالي وجد فقط ثلاث دوال تلمس `stock_branches` / `inventory_log` على مستوى النص التنفيذي:

1. `post_stock_movement`
2. `reserve_stock`
3. `release_stock_reservation`

الاثنتان الثانية والثالثة Reservation Engine وليستا Physical Stock Movement Engine.

ولا توجد triggers على `stock_branches` أو `inventory_log`.

وبالتالي:

```text
Physical Writers outside post_stock_movement = 0
```

وهذا تم التحقق منه من Production مباشرة.

---

## 5. forensic findings in Report209 — what remained open

النقاط التي كانت مفتوحة فعليًا:

### A. Mother Inventory Control

كان route موجودًا بلا implementation.

### B. Authenticated Mother / Inventory Control data path

كان مطلوبًا مسار مركزي من النظام الأم إلى تقارير المخزون والجرد وطلبات المخزون.

### C. Request tables security

ثبت أن:

`inventory_stock_requests`
`inventory_stock_request_details`

لم تكونا تحملان RLS فعالًا.

### D. Realtime completeness

`erp_operation_registry` لم تكن ضمن `supabase_realtime`.

### E. Production function identity

`inventory_stock_snapshot`
`inventory_movement_report`
`inventory_replenishment_report`
`inventory_count_engine`
`inventory_stock_request_engine`

كانت طبقة التنفيذ لديها صلاحية `service_role/postgres` فقط، ولا توجد صلاحية مباشرة للـauthenticated.

---

# 6. التنفيذ الفعلي في Production

## 6.1 Inventory Stock Request Security

تم تفعيل RLS فعليًا على:

- `inventory_stock_requests`
- `inventory_stock_request_details`

وتم إنشاء سياسات company-scoped تعتمد على:

`app_private.current_user_company_id()`

مع منع `anon` من التعامل المباشر مع الجدولين.

## 6.2 Realtime

تمت إضافة:

`erp_operation_registry`

إلى `supabase_realtime`.

أما:

- `inventory_stock_requests`
- `inventory_stock_request_details`
- `inventory_counts`
- `inventory_count_details`

فهي كانت أصلًا ضمن الـpublication الحالية، وتم التحقق من ذلك بدل محاولة إضافتها تكراريًا.

## 6.3 Inventory report/count/request RPC security

تم منع التنفيذ المباشر لهذه الدوال من `public/anon/authenticated`، وأصبح التنفيذ التشغيلي من خلال طبقة Control Plane الموحّدة.

---

# 7. الحل المعماري لعائق Edge Function limit

تمت تجربة إنشاء Edge Function باسم:

`inventory-control`

لكن Production رفضت الإنشاء برسالة:

`Max number of functions reached, please upgrade Plan or disable spend cap`

ولم يتم التحايل عبر إعادة استخدام Harness قديم أو كسر endpoint تشغيلي قائم.

تم اختيار حل معماري أقوى وأكثر ثباتًا:

```text
Authenticated User
        ↓
public.inventory_control()
        ↓
Current user from auth.uid()
        ↓
Company context from users.auth_id
        ↓
Existing inventory engines
        ↓
Current production DB
```

تم إنشاء:

`public.inventory_control(text,jsonb)`

وتم منحه فقط إلى:

- `authenticated`
- `service_role`

ويستخرج المستخدم من `auth.uid()`، ولا يعتمد على `app_settings LIMIT 1` لتحديد Tenant.

هذا يغلق مشكلة تمرير company_id من العميل بشكل قابل للتلاعب.

---

# 8. inventory_control contract

يدعم الـRPC المركزي العمليات:

`SNAPSHOT`

`MOVEMENTS`

`REPLENISHMENT`

`COUNT`

`REQUEST`

ويتعامل داخليًا مع العمليات الفرعية الموجودة حاليًا في:

`inventory_count_engine`

و:

`inventory_stock_request_engine`

مع المحافظة على صلاحيات الأدوار الحالية:

- wildcard `*`
- مدير مخازن
- مشرف مخازن
- مدير عام
- warehouse / warehouse_manager / warehouse_supervisor
- reports للقراءة

ولم تتم إزالة Owner wildcard semantics.

---

# 9. Production verification of canonical Control RPC

تم تنفيذ اختبار transactional باستخدام هوية Owner حقيقية من auth context داخل PostgreSQL:

النتيجة:

`inventory_control('SNAPSHOT', ...) => success=true`

وأعاد Snapshot فعليًا من Production، منها على سبيل المثال:

- Item `1001`
- physical quantity `2`
- available quantity `2`
- reorder point `5`
- suggested replenishment `3`

وتم تنفيذ اختبار آخر بمستخدم Picker فعلي:

`picker@rawaea.com`

والنتيجة:

`inventory_control('SNAPSHOT', ...) => success=true`

إذن:

- Company context حقيقي.
- User context حقيقي.
- Permission path حقيقي.
- Snapshot data حقيقية.

---

# 10. No Production data cleanup was done blindly

فحص المخزون الحالي ما زال يظهر rows تبدو cross-company لأن `items.item_code` في Production لديه:

`UNIQUE (item_code)`

وبالتالي لا يجوز تحويل كل mismatch إلى corruption أو حذف rows.

لم يتم حذف بيانات حالية على أساس count فقط.

---

# 11. CURRENT forensic source alignment file

`forensic_main_assembly.yml` في `rawaie-erp-New` تم التحقق من أنه يشير إلى:

```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
```

ولا يحتاج تعديلًا في هذه الجلسة.

---

# 12. CURRENT Mother surgical fix — MUST be applied by owner

## التعديل رقم 1 — إضافة implementation حقيقية لمركز التحكم في المخزون

### لا تعدّل الـroute الحالي

السطر الحالي:

```js
20937: if (view === 'inventory-control') { RW_Warehouse.loadInventoryControl(); return; }
```

**يُترك كما هو.**

### ابحث عن السطر الحالي 13236 حرفيًا:

```js
return {
```

وهذا السطر موجود داخل:

```js
var RW_Warehouse = (function() {
```

## المطلوب

**أضف المقطع التالي كاملًا فوق السطر 13236 `return {` مباشرة.**

```js
    async function loadInventoryControl() {
        var c = byId('rw-page-container');
        if (!c) return;

        var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) ||
            (typeof _rwCompanyId === 'function' ? _rwCompanyId() : null);
        if (!companyId) {
            showToast('سياق الشركة غير محدد', 'error');
            return;
        }

        var state = {
            tab: 'snapshot',
            branchId: '',
            query: '',
            lowOnly: false,
            movementType: '',
            fromDate: '',
            toDate: '',
            snapshot: [],
            movements: [],
            replenishment: [],
            counts: [],
            requests: [],
            branches: [],
            busy: false
        };

        function escIC(v) {
            return String(v == null ? '' : v)
                .replace(/&/g, '&amp;')
                .replace(/</g, '&lt;')
                .replace(/>/g, '&gt;')
                .replace(/"/g, '&quot;')
                .replace(/'/g, '&#39;');
        }

        function fmtIC(v) {
            return Number(v || 0).toLocaleString('ar-EG');
        }

        async function callIC(operation, payload) {
            var res = await supabase.rpc('inventory_control', {
                p_operation: operation,
                p_payload: payload || {}
            });
            if (res.error) throw res.error;
            var data = res.data;
            if (data && data.success === false) {
                throw new Error(data.msg || 'فشل تنفيذ العملية');
            }
            return data || { success: true };
        }

        function branchOptions(selected) {
            var h = '<option value="">كل المخازن والفروع</option>';
            for (var i = 0; i < state.branches.length; i++) {
                var b = state.branches[i];
                h += '<option value="' + escIC(b.id) + '"' +
                    (String(selected || '') === String(b.id) ? ' selected' : '') + '>' +
                    escIC(b.name || b.branch_code) + '</option>';
            }
            return h;
        }

        function renderShell() {
            safeText(byId('rw-header-title'), 'مركز التحكم في المخزون');
            safeHTML(c,
                '<div class="p-4 space-y-4">' +
                '<div class="bg-white rounded-2xl shadow-sm border p-4">' +
                    '<div class="flex flex-wrap items-center justify-between gap-3 mb-4">' +
                        '<div>' +
                            '<div class="text-xl font-black text-slate-800">مركز التحكم في المخزون</div>' +
                            '<div class="text-sm text-slate-500 mt-1">لوحة رقابة مركزية فوق رصيد المخزون والحركة والاحتياجات والجرد وطلبات المخزون</div>' +
                        '</div>' +
                        '<div class="flex gap-2">' +
                            '<button id="ic-refresh" class="px-4 py-2 rounded-xl bg-slate-800 text-white font-bold">تحديث البيانات</button>' +
                            '<button id="ic-new-count" class="px-4 py-2 rounded-xl bg-indigo-600 text-white font-bold">جلسة جرد جديدة</button>' +
                        '</div>' +
                    '</div>' +
                    '<div class="grid grid-cols-1 md:grid-cols-4 gap-3">' +
                        '<div class="rounded-2xl bg-blue-50 border border-blue-100 p-4"><div class="text-xs text-blue-700 font-bold">بنود المخزون المعروضة</div><div id="ic-kpi-lines" class="text-2xl font-black text-blue-900 mt-1">0</div></div>' +
                        '<div class="rounded-2xl bg-amber-50 border border-amber-100 p-4"><div class="text-xs text-amber-700 font-bold">بنود منخفضة</div><div id="ic-kpi-low" class="text-2xl font-black text-amber-900 mt-1">0</div></div>' +
                        '<div class="rounded-2xl bg-emerald-50 border border-emerald-100 p-4"><div class="text-xs text-emerald-700 font-bold">بنود تحتاج إعادة طلب</div><div id="ic-kpi-repl" class="text-2xl font-black text-emerald-900 mt-1">0</div></div>' +
                        '<div class="rounded-2xl bg-purple-50 border border-purple-100 p-4"><div class="text-xs text-purple-700 font-bold">جلسات الجرد النشطة</div><div id="ic-kpi-counts" class="text-2xl font-black text-purple-900 mt-1">0</div></div>' +
                    '</div>' +
                '</div>' +
                '<div class="bg-white rounded-2xl shadow-sm border p-3">' +
                    '<div class="flex flex-wrap gap-2">' +
                        '<button data-ic-tab="snapshot" class="ic-tab px-4 py-2 rounded-xl font-bold bg-blue-600 text-white">الرصيد</button>' +
                        '<button data-ic-tab="movements" class="ic-tab px-4 py-2 rounded-xl font-bold bg-slate-100 text-slate-700">الحركات</button>' +
                        '<button data-ic-tab="replenishment" class="ic-tab px-4 py-2 rounded-xl font-bold bg-slate-100 text-slate-700">إعادة الطلب</button>' +
                        '<button data-ic-tab="counts" class="ic-tab px-4 py-2 rounded-xl font-bold bg-slate-100 text-slate-700">الجرد</button>' +
                        '<button data-ic-tab="requests" class="ic-tab px-4 py-2 rounded-xl font-bold bg-slate-100 text-slate-700">طلبات المخزون</button>' +
                    '</div>' +
                '</div>' +
                '<div id="ic-filters" class="bg-white rounded-2xl shadow-sm border p-4"></div>' +
                '<div id="ic-content" class="bg-white rounded-2xl shadow-sm border overflow-auto"></div>' +
                '</div>'
            );

            byId('ic-refresh').onclick = refreshAll;
            byId('ic-new-count').onclick = createCountSession;

            var tabs = c.querySelectorAll('.ic-tab');
            for (var i = 0; i < tabs.length; i++) {
                tabs[i].onclick = function() {
                    state.tab = this.getAttribute('data-ic-tab');
                    renderTabButtons();
                    renderFilters();
                    refreshCurrentTab();
                };
            }
        }

        function renderTabButtons() {
            var tabs = c.querySelectorAll('.ic-tab');
            for (var i = 0; i < tabs.length; i++) {
                var active = tabs[i].getAttribute('data-ic-tab') === state.tab;
                tabs[i].className = 'ic-tab px-4 py-2 rounded-xl font-bold ' +
                    (active ? 'bg-blue-600 text-white' : 'bg-slate-100 text-slate-700');
            }
        }

        function renderFilters() {
            var f = byId('ic-filters');
            if (!f) return;
            if (state.tab === 'snapshot') {
                safeHTML(f,
                    '<div class="grid grid-cols-1 md:grid-cols-4 gap-3">' +
                        '<select id="ic-branch" class="p-2.5 border rounded-xl bg-slate-50">' + branchOptions(state.branchId) + '</select>' +
                        '<input id="ic-query" class="p-2.5 border rounded-xl bg-slate-50" placeholder="بحث بالصنف أو الكود أو الفرع" value="' + escIC(state.query) + '">' +
                        '<label class="flex items-center gap-2 p-2.5 border rounded-xl bg-slate-50"><input id="ic-low" type="checkbox" ' + (state.lowOnly ? 'checked' : '') + '> منخفض فقط</label>' +
                        '<button id="ic-apply" class="p-2.5 rounded-xl bg-slate-700 text-white font-bold">تطبيق</button>' +
                    '</div>'
                );
                byId('ic-apply').onclick = function() {
                    state.branchId = byId('ic-branch').value || '';
                    state.query = byId('ic-query').value || '';
                    state.lowOnly = !!byId('ic-low').checked;
                    refreshCurrentTab();
                };
            } else if (state.tab === 'movements') {
                safeHTML(f,
                    '<div class="grid grid-cols-1 md:grid-cols-5 gap-3">' +
                        '<input id="ic-from" type="date" class="p-2.5 border rounded-xl bg-slate-50" value="' + escIC(state.fromDate) + '">' +
                        '<input id="ic-to" type="date" class="p-2.5 border rounded-xl bg-slate-50" value="' + escIC(state.toDate) + '">' +
                        '<select id="ic-mov-branch" class="p-2.5 border rounded-xl bg-slate-50">' + branchOptions(state.branchId) + '</select>' +
                        '<input id="ic-mov-query" class="p-2.5 border rounded-xl bg-slate-50" placeholder="صنف/مرجع" value="' + escIC(state.query) + '">' +
                        '<button id="ic-mov-apply" class="p-2.5 rounded-xl bg-slate-700 text-white font-bold">تطبيق</button>' +
                    '</div>'
                );
                byId('ic-mov-apply').onclick = function() {
                    state.fromDate = byId('ic-from').value || '';
                    state.toDate = byId('ic-to').value || '';
                    state.branchId = byId('ic-mov-branch').value || '';
                    state.query = byId('ic-mov-query').value || '';
                    refreshCurrentTab();
                };
            } else if (state.tab === 'replenishment') {
                safeHTML(f,
                    '<div class="grid grid-cols-1 md:grid-cols-3 gap-3">' +
                        '<select id="ic-repl-branch" class="p-2.5 border rounded-xl bg-slate-50">' + branchOptions(state.branchId) + '</select>' +
                        '<div class="p-2.5 rounded-xl bg-emerald-50 border border-emerald-100 font-bold text-emerald-800">التوصية مبنية على الرصيد المتاح ونقطة إعادة الطلب والحد الأقصى</div>' +
                        '<button id="ic-repl-apply" class="p-2.5 rounded-xl bg-slate-700 text-white font-bold">تحديث التوصيات</button>' +
                    '</div>'
                );
                byId('ic-repl-apply').onclick = function() {
                    state.branchId = byId('ic-repl-branch').value || '';
                    refreshCurrentTab();
                };
            } else if (state.tab === 'counts') {
                safeHTML(f,
                    '<div class="flex flex-wrap items-center justify-between gap-2">' +
                        '<div class="text-sm text-slate-600">الجرد يبدأ من جلسة، ثم Populate/Count/Refresh/Finalize عبر محرك الجرد الحالي.</div>' +
                        '<button id="ic-count-refresh" class="px-4 py-2 rounded-xl bg-slate-700 text-white font-bold">تحديث الجلسات</button>' +
                    '</div>'
                );
                byId('ic-count-refresh').onclick = refreshCounts;
            } else {
                safeHTML(f,
                    '<div class="flex flex-wrap items-center justify-between gap-2">' +
                        '<div class="text-sm text-slate-600">طلبات المخزون تستخدم دورة Pending → Approved → Converted/Rejected/Cancelled.</div>' +
                        '<button id="ic-request-new" class="px-4 py-2 rounded-xl bg-indigo-600 text-white font-bold">طلب نقل مخزني جديد</button>' +
                    '</div>'
                );
                byId('ic-request-new').onclick = createStockRequest;
            }
        }

        function setBusy(on, text) {
            state.busy = on;
            if (on) showLoader(text || 'جاري تحميل مركز التحكم...');
            else hideLoader();
        }

        async function refreshSnapshot() {
            var d = await callIC('SNAPSHOT', {
                branch_id: state.branchId || null,
                query: state.query || null,
                low_only: state.lowOnly,
                limit: 200,
                offset: 0
            });
            state.snapshot = d.rows || [];
            safeText(byId('ic-kpi-lines'), fmtIC(d.count || state.snapshot.length));
            var low = state.snapshot.filter(function(x) { return x.low_stock; }).length;
            safeText(byId('ic-kpi-low'), fmtIC(low));
            renderSnapshot();
        }

        async function refreshMovements() {
            var d = await callIC('MOVEMENTS', {
                from_date: state.fromDate || null,
                to_date: state.toDate || null,
                branch_id: state.branchId || null,
                item_id: null,
                movement_type: state.movementType || null,
                query: state.query || null,
                limit: 200,
                offset: 0
            });
            state.movements = d.rows || [];
            renderMovements();
        }

        async function refreshReplenishment() {
            var d = await callIC('REPLENISHMENT', {
                branch_id: state.branchId || null,
                limit: 200,
                offset: 0
            });
            state.replenishment = d.rows || [];
            safeText(byId('ic-kpi-repl'), fmtIC(state.replenishment.length));
            renderReplenishment();
        }

        async function refreshCounts() {
            var res = await supabase.from('inventory_counts')
                .select('*')
                .eq('company_id', companyId)
                .order('created_at', { ascending: false });
            if (res.error) throw res.error;
            state.counts = res.data || [];
            safeText(byId('ic-kpi-counts'), fmtIC(state.counts.filter(function(x) { return ['InProgress','Draft'].indexOf(x.status) !== -1; }).length));
            renderCounts();
        }

        async function refreshRequests() {
            var res = await supabase.from('inventory_stock_requests')
                .select('*')
                .eq('company_id', companyId)
                .order('created_at', { ascending: false });
            if (res.error) throw res.error;
            state.requests = res.data || [];
            renderRequests();
        }

        function renderSnapshot() {
            var tb = byId('ic-content');
            var h = '<table class="w-full text-sm"><thead class="bg-slate-800 text-white sticky top-0"><tr>' +
                '<th class="p-3">الفرع</th><th class="p-3">الكود</th><th class="p-3">الصنف</th><th class="p-3">فعلي</th><th class="p-3">محجوز</th><th class="p-3">متاح</th><th class="p-3">ROP</th><th class="p-3">إعادة الطلب</th><th class="p-3">القيمة</th></tr></thead><tbody>';
            if (!state.snapshot.length) h += '<tr><td colspan="9" class="p-8 text-center text-slate-500">لا توجد بيانات</td></tr>';
            for (var i = 0; i < state.snapshot.length; i++) {
                var x = state.snapshot[i];
                h += '<tr class="border-b hover:bg-slate-50">' +
                    '<td class="p-3">' + escIC(x.branch_name || x.branch_code) + '</td>' +
                    '<td class="p-3 font-bold">' + escIC(x.item_code) + '</td>' +
                    '<td class="p-3 font-semibold">' + escIC(x.item_name) + '</td>' +
                    '<td class="p-3 text-center">' + fmtIC(x.physical_qty) + '</td>' +
                    '<td class="p-3 text-center text-orange-700">' + fmtIC(x.allocated_qty) + '</td>' +
                    '<td class="p-3 text-center font-black">' + fmtIC(x.available_qty) + '</td>' +
                    '<td class="p-3 text-center">' + fmtIC(x.reorder_point) + '</td>' +
                    '<td class="p-3 text-center font-bold ' + (x.low_stock ? 'text-red-600' : 'text-emerald-600') + '">' + fmtIC(x.suggested_replenishment_qty) + '</td>' +
                    '<td class="p-3 text-center">' + fmtIC(x.stock_value_at_cost) + '</td>' +
                '</tr>';
            }
            h += '</tbody></table>';
            safeHTML(tb, h);
        }

        function renderMovements() {
            var h = '<table class="w-full text-sm"><thead class="bg-slate-800 text-white sticky top-0"><tr>' +
                '<th class="p-3">التاريخ</th><th class="p-3">الحركة</th><th class="p-3">الكود</th><th class="p-3">الصنف</th><th class="p-3">الفرع</th><th class="p-3">الأثر</th><th class="p-3">المرجع</th><th class="p-3">المستخدم</th></tr></thead><tbody>';
            if (!state.movements.length) h += '<tr><td colspan="8" class="p-8 text-center text-slate-500">لا توجد حركات</td></tr>';
            for (var i = 0; i < state.movements.length; i++) {
                var x = state.movements[i];
                h += '<tr class="border-b hover:bg-slate-50">' +
                    '<td class="p-3">' + escIC(x.movement_date || x.created_at) + '</td>' +
                    '<td class="p-3 font-bold">' + escIC(x.movement_type) + '</td>' +
                    '<td class="p-3">' + escIC(x.item_code) + '</td>' +
                    '<td class="p-3">' + escIC(x.item_name) + '</td>' +
                    '<td class="p-3">' + escIC(x.branch_name || x.branch_code || '') + '</td>' +
                    '<td class="p-3 text-center font-black">' + fmtIC(x.effect_qty == null ? x.qty : x.effect_qty) + '</td>' +
                    '<td class="p-3">' + escIC(x.reference || x.voucher_id || '') + '</td>' +
                    '<td class="p-3">' + escIC(x.user_email || '') + '</td>' +
                '</tr>';
            }
            h += '</tbody></table>';
            safeHTML(byId('ic-content'), h);
        }

        function renderReplenishment() {
            var h = '<table class="w-full text-sm"><thead class="bg-slate-800 text-white sticky top-0"><tr>' +
                '<th class="p-3">الفرع</th><th class="p-3">الكود</th><th class="p-3">الصنف</th><th class="p-3">المتاح</th><th class="p-3">ROP</th><th class="p-3">الموصى به</th><th class="p-3">التكلفة</th><th class="p-3">القيمة</th></tr></thead><tbody>';
            if (!state.replenishment.length) h += '<tr><td colspan="8" class="p-8 text-center text-slate-500">لا توجد توصيات حاليًا</td></tr>';
            for (var i = 0; i < state.replenishment.length; i++) {
                var x = state.replenishment[i];
                h += '<tr class="border-b hover:bg-slate-50">' +
                    '<td class="p-3">' + escIC(x.branch_name || x.branch_code) + '</td>' +
                    '<td class="p-3 font-bold">' + escIC(x.item_code) + '</td>' +
                    '<td class="p-3 font-semibold">' + escIC(x.item_name) + '</td>' +
                    '<td class="p-3 text-center">' + fmtIC(x.available_qty) + '</td>' +
                    '<td class="p-3 text-center">' + fmtIC(x.reorder_point) + '</td>' +
                    '<td class="p-3 text-center font-black text-emerald-700">' + fmtIC(x.recommended_order_qty) + '</td>' +
                    '<td class="p-3 text-center">' + fmtIC(x.cost_price) + '</td>' +
                    '<td class="p-3 text-center font-bold">' + fmtIC(x.recommended_order_value) + '</td>' +
                '</tr>';
            }
            h += '</tbody></table>';
            safeHTML(byId('ic-content'), h);
        }

        function renderCounts() {
            var h = '<table class="w-full text-sm"><thead class="bg-slate-800 text-white"><tr><th class="p-3">التاريخ</th><th class="p-3">النوع</th><th class="p-3">الحالة</th><th class="p-3">المرجع</th><th class="p-3">عملية</th><th class="p-3">إجراء</th></tr></thead><tbody>';
            if (!state.counts.length) h += '<tr><td colspan="6" class="p-8 text-center text-slate-500">لا توجد جلسات جرد</td></tr>';
            for (var i = 0; i < state.counts.length; i++) {
                var x = state.counts[i];
                var actionable = ['InProgress','Draft'].indexOf(x.status) !== -1;
                h += '<tr class="border-b hover:bg-slate-50">' +
                    '<td class="p-3">' + escIC(x.count_date || x.created_at) + '</td>' +
                    '<td class="p-3">' + escIC(x.type) + '</td>' +
                    '<td class="p-3 font-bold">' + escIC(x.status) + '</td>' +
                    '<td class="p-3">' + escIC(x.reference || '') + '</td>' +
                    '<td class="p-3 font-mono text-xs">' + escIC(x.operation_id || '') + '</td>' +
                    '<td class="p-3">' +
                        (actionable ? '<button data-count-id="' + escIC(x.id) + '" data-count-action="cancel" class="ic-count-cancel px-3 py-1 rounded-lg bg-red-50 text-red-700 font-bold">إلغاء</button>' : '-') +
                    '</td>' +
                '</tr>';
            }
            h += '</tbody></table>';
            safeHTML(byId('ic-content'), h);
            var btns = c.querySelectorAll('.ic-count-cancel');
            for (var j = 0; j < btns.length; j++) btns[j].onclick = cancelCount;
        }

        function renderRequests() {
            var h = '<table class="w-full text-sm"><thead class="bg-slate-800 text-white"><tr><th class="p-3">الطلب</th><th class="p-3">التاريخ</th><th class="p-3">المصدر</th><th class="p-3">الوجهة</th><th class="p-3">الحالة</th><th class="p-3">إجراء</th></tr></thead><tbody>';
            if (!state.requests.length) h += '<tr><td colspan="6" class="p-8 text-center text-slate-500">لا توجد طلبات مخزون</td></tr>';
            for (var i = 0; i < state.requests.length; i++) {
                var x = state.requests[i];
                var actions = '';
                if (x.status === 'Pending') {
                    actions += '<button data-req-id="' + escIC(x.id) + '" data-req-action="approve" class="ic-req-btn px-2 py-1 rounded-lg bg-emerald-50 text-emerald-700 font-bold ml-1">اعتماد</button>';
                    actions += '<button data-req-id="' + escIC(x.id) + '" data-req-action="reject" class="ic-req-btn px-2 py-1 rounded-lg bg-red-50 text-red-700 font-bold">رفض</button>';
                } else if (x.status === 'Approved') {
                    actions += '<button data-req-id="' + escIC(x.id) + '" data-req-action="convert" class="ic-req-btn px-2 py-1 rounded-lg bg-indigo-50 text-indigo-700 font-bold">تحويل لإذن</button>';
                }
                h += '<tr class="border-b hover:bg-slate-50">' +
                    '<td class="p-3 font-black text-indigo-700">' + escIC(x.request_code) + '</td>' +
                    '<td class="p-3">' + escIC(x.request_date) + '</td>' +
                    '<td class="p-3 font-mono text-xs">' + escIC(x.source_branch_id || '') + '</td>' +
                    '<td class="p-3 font-mono text-xs">' + escIC(x.target_branch_id || '') + '</td>' +
                    '<td class="p-3 font-bold">' + escIC(x.status) + '</td>' +
                    '<td class="p-3">' + actions + '</td>' +
                '</tr>';
            }
            h += '</tbody></table>';
            safeHTML(byId('ic-content'), h);
            var btns = c.querySelectorAll('.ic-req-btn');
            for (var j = 0; j < btns.length; j++) btns[j].onclick = handleRequestAction;
        }

        async function refreshCurrentTab() {
            try {
                setBusy(true, 'جاري مزامنة مركز التحكم مع Production...');
                if (state.tab === 'snapshot') await refreshSnapshot();
                else if (state.tab === 'movements') await refreshMovements();
                else if (state.tab === 'replenishment') await refreshReplenishment();
                else if (state.tab === 'counts') await refreshCounts();
                else await refreshRequests();
            } catch (e) {
                showToast(e.message || 'فشل تحديث مركز التحكم', 'error');
            } finally {
                setBusy(false);
            }
        }

        async function refreshAll() {
            await refreshCurrentTab();
            if (state.tab !== 'replenishment') {
                try {
                    var d = await callIC('REPLENISHMENT', { branch_id: state.branchId || null, limit: 200, offset: 0 });
                    state.replenishment = d.rows || [];
                    safeText(byId('ic-kpi-repl'), fmtIC(state.replenishment.length));
                } catch (e) {}
            }
            try { await refreshCounts(); } catch (e2) {}
        }

        async function createCountSession() {
            var options = '';
            for (var i = 0; i < state.branches.length; i++) options += '<option value="' + escIC(state.branches[i].id) + '">' + escIC(state.branches[i].name || state.branches[i].branch_code) + '</option>';
            var r = await Swal.fire({
                title: 'جلسة جرد جديدة',
                html: '<select id="ic-count-branch" class="swal2-input">' + options + '</select><input id="ic-count-ref" class="swal2-input" placeholder="مرجع الجرد"><textarea id="ic-count-notes" class="swal2-textarea" placeholder="ملاحظات"></textarea>',
                showCancelButton: true,
                confirmButtonText: 'إنشاء',
                cancelButtonText: 'إلغاء',
                preConfirm: function() {
                    return {
                        branch: byId('ic-count-branch').value,
                        ref: byId('ic-count-ref').value || '',
                        notes: byId('ic-count-notes').value || ''
                    };
                }
            });
            if (!r.isConfirmed) return;
            try {
                setBusy(true, 'جاري إنشاء جلسة الجرد...');
                var operationId = (window.crypto && window.crypto.randomUUID) ? window.crypto.randomUUID() : ('IC-' + Date.now());
                var d = await callIC('COUNT', {
                    operation: 'CREATE',
                    operation_id: operationId,
                    payload: { type: 'branch', entity_id: r.value.branch, reference: r.value.ref, notes: r.value.notes }
                });
                showToast(d.duplicate ? 'تم استرجاع جلسة الجرد السابقة' : 'تم إنشاء جلسة الجرد', 'success');
                state.tab = 'counts';
                renderTabButtons();
                renderFilters();
                await refreshCounts();
            } catch (e) {
                showToast(e.message || 'فشل إنشاء جلسة الجرد', 'error');
            } finally {
                setBusy(false);
            }
        }

        async function cancelCount() {
            var id = this.getAttribute('data-count-id');
            if (!id) return;
            try {
                setBusy(true, 'جاري إلغاء جلسة الجرد...');
                await callIC('COUNT', { operation: 'CANCEL', payload: { request_id: id, count_id: id } });
                showToast('تم إلغاء جلسة الجرد', 'success');
                await refreshCounts();
            } catch (e) {
                showToast(e.message || 'فشل إلغاء الجرد', 'error');
            } finally {
                setBusy(false);
            }
        }

        async function handleRequestAction() {
            var id = this.getAttribute('data-req-id');
            var action = this.getAttribute('data-req-action');
            if (!id || !action) return;
            var op = action.toUpperCase();
            var payload = { request_id: id };
            if (action === 'reject') {
                var r = await Swal.fire({ title: 'رفض الطلب', input: 'textarea', inputLabel: 'سبب الرفض', showCancelButton: true, confirmButtonText: 'رفض', cancelButtonText: 'إلغاء' });
                if (!r.isConfirmed) return;
                payload.reason = r.value || '';
            }
            try {
                setBusy(true, 'جاري تحديث طلب المخزون...');
                var d = await callIC('REQUEST', { operation: op, operation_id: null, payload: payload });
                showToast(d.duplicate ? 'تم استرجاع العملية السابقة' : 'تم تنفيذ العملية', 'success');
                await refreshRequests();
            } catch (e) {
                showToast(e.message || 'فشل تحديث طلب المخزون', 'error');
            } finally {
                setBusy(false);
            }
        }

        async function createStockRequest() {
            if (state.branches.length < 2) {
                showToast('يلزم وجود فرعي مصدر ووجهة مختلفين', 'warning');
                return;
            }
            var sourceOptions = '', targetOptions = '';
            for (var i = 0; i < state.branches.length; i++) {
                var b = state.branches[i];
                sourceOptions += '<option value="' + escIC(b.id) + '">' + escIC(b.name || b.branch_code) + '</option>';
                targetOptions += '<option value="' + escIC(b.id) + '">' + escIC(b.name || b.branch_code) + '</option>';
            }
            var r = await Swal.fire({
                title: 'طلب نقل مخزني جديد',
                html: '<select id="ic-r-source" class="swal2-input">' + sourceOptions + '</select><select id="ic-r-target" class="swal2-input">' + targetOptions + '</select><textarea id="ic-r-items" class="swal2-textarea" placeholder="صنف في كل سطر: 1001|5"></textarea><textarea id="ic-r-notes" class="swal2-textarea" placeholder="ملاحظات"></textarea>',
                showCancelButton: true,
                confirmButtonText: 'إنشاء',
                cancelButtonText: 'إلغاء',
                preConfirm: function() {
                    var lines = (byId('ic-r-items').value || '').split('\n');
                    var items = [];
                    for (var k = 0; k < lines.length; k++) {
                        var line = lines[k].trim();
                        if (!line) continue;
                        var parts = line.split('|');
                        if (!parts[0] || Number(parts[1]) <= 0) {
                            Swal.showValidationMessage('صيغة الأصناف: 1001|5');
                            return false;
                        }
                        items.push({ item_code: parts[0].trim(), qty: Number(parts[1]) });
                    }
                    if (!items.length) {
                        Swal.showValidationMessage('أضف صنفًا واحدًا على الأقل');
                        return false;
                    }
                    if (byId('ic-r-source').value === byId('ic-r-target').value) {
                        Swal.showValidationMessage('المصدر والوجهة يجب أن يكونا مختلفين');
                        return false;
                    }
                    return {
                        source: byId('ic-r-source').value,
                        target: byId('ic-r-target').value,
                        items: items,
                        notes: byId('ic-r-notes').value || ''
                    };
                }
            });
            if (!r.isConfirmed) return;
            try {
                setBusy(true, 'جاري إنشاء طلب المخزون...');
                var operationId = (window.crypto && window.crypto.randomUUID) ? window.crypto.randomUUID() : ('SR-' + Date.now());
                var d = await callIC('REQUEST', {
                    operation: 'CREATE',
                    operation_id: operationId,
                    payload: {
                        source_branch_id: r.value.source,
                        target_branch_id: r.value.target,
                        items: r.value.items,
                        notes: r.value.notes
                    }
                });
                showToast(d.duplicate ? 'تم استرجاع الطلب السابق' : 'تم إنشاء طلب المخزون', 'success');
                state.tab = 'requests';
                renderTabButtons();
                renderFilters();
                await refreshRequests();
            } catch (e) {
                showToast(e.message || 'فشل إنشاء طلب المخزون', 'error');
            } finally {
                setBusy(false);
            }
        }

        var branchRes = await supabase.from('branches')
            .select('id,branch_code,name')
            .eq('company_id', companyId)
            .eq('is_active', true)
            .order('name');
        if (branchRes.error) {
            showToast(branchRes.error.message, 'error');
            return;
        }
        state.branches = branchRes.data || [];

        renderShell();
        renderTabButtons();
        renderFilters();
        await refreshAll();

        try {
            if (window._rwInventoryControlChannel) {
                await supabase.removeChannel(window._rwInventoryControlChannel);
            }
            var channel = supabase.channel('rw-inventory-control-' + companyId);
            channel.on('postgres_changes', { event: '*', schema: 'public', table: 'stock_branches' }, function() { refreshCurrentTab(); });
            channel.on('postgres_changes', { event: '*', schema: 'public', table: 'inventory_log' }, function() { if (state.tab === 'movements') refreshCurrentTab(); else refreshSnapshot(); });
            channel.on('postgres_changes', { event: '*', schema: 'public', table: 'inventory_counts' }, function() { if (state.tab === 'counts') refreshCounts(); });
            channel.on('postgres_changes', { event: '*', schema: 'public', table: 'inventory_stock_requests' }, function() { if (state.tab === 'requests') refreshRequests(); });
            window._rwInventoryControlChannel = channel.subscribe();
        } catch (e) {}
    }
```

## ثم عدّل الـreturn object

ابحث عن هذا الجزء الحالي في السطر `13236` وما بعده:

```js
return {
        loadReceiving: loadReceiving,
```

**لا تحذف `loadReceiving`.**

أضف هذا السطر فوق `loadReceiving` مباشرة:

```js
        loadInventoryControl: loadInventoryControl,
```

فيصبح أول الجزء هكذا:

```js
return {
        loadInventoryControl: loadInventoryControl,
        loadReceiving: loadReceiving,
```

### آخر سطر للعنصر المطلوب قبل التعديل

```js
13235:     }
```

هذا هو إغلاق آخر دالة قبل `return {`.

### أول سطر بعد التعديل مباشرة

```js
    async function loadInventoryControl() {
```

---

# 13. ملاحظة حاسمة حول Count actions

محرك `inventory_count_engine` الحالي يحتاج `p_payload.request_id` للعمليات بعد إنشاء الجلسة، بينما واجهة الإلغاء أعلاه ترسل `count_id` أيضًا.

قبل اعتماد هذا الزر في Production يجب أن يكون المستهلك النهائي هو:

```json
{
  "operation": "CANCEL",
  "payload": { "request_id": "<COUNT_UUID>" }
}
```

وهو ما يجب تثبيته جراحيًا إذا أثبت الاختبار المتصفح ذلك بعد الدمج.

---

# 14. ما لم يتم تغييره في Mother عمدًا

لم يتم تعديل:

- `complete-return`
- `complete-order-delivery`
- `complete-picking`
- `complete-loading`
- `unload-runsheet`
- route الحالي للـinventory-control
- قائمة Inventory الحالية
- أي من ملفات `main2`
- New-main

لأنها لم تحتاج تغييرًا جديدًا مثبتًا في هذه الجلسة.

---

# 15. نتائج المقارنة مع Daftra — Inventory only

المقارنة الحالية تشير إلى مجموعة قدرات يجب أن يحققها Control Plane في RAWAEA:

- multi-warehouse
- stock balance by warehouse
- stock movement reports
- reorder/replenishment recommendation
- stocktaking with system vs actual and variance
- barcode-assisted counting
- transfer workflow
- permissions and auditability
- accounting integration
- serial/lot/expiry as a future item-master extension where required

RAWAEA لديه بالفعل الأساس التشغيلي الأقوى في field execution:

`Picking → Reservation → Loading → Delivery → Return → Unloading`

والمطلوب هو أن يعمل مركز التحكم كـControl Plane فوق هذه العمليات وليس أن يستبدلها.

---

# 16. أخطاء ومحاولات فاشلة في هذه الجلسة

### محاولة 1
محاولة إنشاء Edge Function جديدة `inventory-control`.

النتيجة:

`Max number of functions reached`

### القرار
عدم إعادة استخدام Harness قديم أو Endpoint تشغيلي قائم.

### الحل
Canonical PostgreSQL `inventory_control()`.

### محاولة forensic SQL
تم استخدام اسم عمود خاطئ في `information_schema.triggers` (`table_name`) وتم تصحيحه إلى `event_object_table`.

لم يحدث أي تعديل على Production بسبب هذا الخطأ.

### محاولة Realtime
محاولة إضافة `inventory_stock_requests` مرة أخرى فشلت لأن الجدول كان بالفعل ضمن publication.

تم التحقق بدل تكرار التغيير، ثم تمت إضافة `erp_operation_registry` فقط.

---

# 17. Runtime status at session end

## CLOSED

- Physical Writer centralization.
- Reservation separation.
- Inventory stock request RLS.
- Canonical `inventory_control` DB gateway.
- Current Source-of-Truth path verification.
- Current Git + Parent forensic verification.
- Production Snapshot through canonical Control RPC.
- Picker access through canonical Control RPC.

## OPEN — owner merge required

- Mother `loadInventoryControl()` implementation still not merged into `erp-frontend/main.html` because the user owns this file.
- Authenticated browser E2E on the Mother remains open until the owner applies the exact surgical patch and the live Browser/Console/Network behavior is rechecked.
- Final visual/functional Gold/Diamond polish of the new Control Plane should be judged only from the merged Mother, not from the unmerged patch text.

---

# 18. Final self-audit

## What was proved

- Current repository truth was re-read directly.
- Latest commit and parents were checked.
- Mother source was extracted from the live Git blob, not from historical fragments.
- Physical stock writer discovery in current Production returned zero independent writers outside `post_stock_movement`.
- Inventory Request tables now have RLS.
- Realtime includes the operational tables needed for live Control Plane refresh.
- `inventory_control()` is authenticated and derives company from `auth.uid()`.
- Real Owner and Picker identities successfully executed Snapshot through the canonical Control RPC.

## What was not proved

- Real Browser/Console/Network execution of the owner-applied Mother patch.
- Final visual UX after the merged file is published.
- Full authenticated E2E across every count/request button in a browser session.

## What was fixed

- Inventory Control backend security and gateway.
- Tenant derivation for the Control Plane.
- Request-table isolation.
- Realtime operation visibility.
- Mother exact route target verified and exact missing implementation located.

## What was initially missed

- The latest frontend HEAD had advanced beyond the previous Report209 HEAD because forensic extraction itself created two new non-business commits.
- Edge Function capacity was already exhausted; creating another function was not a valid architecture path.
- Existing count/request engines were already rich enough to be exposed through a single canonical gateway.

## What could still be wrong

The remaining risk is specifically in the owner-applied Mother HTML patch and its real Browser execution. No claim of browser closure is made before that evidence exists.

---

# 19. تعليمات للـCTO / المساعد القادم — كيف يبدأ وكيف يصل للحقيقة

ابدأ بهذا التسلسل ولا تعكسه:

### Step 1 — Git

اقرأ:

1. أحدث commit في `erp-frontend`.
2. الـparent المباشر.
3. إذا كان أحدث commit أدوات/توثيق، اصعد إلى آخر business commit الذي غيّر Mother.

### Step 2 — Mother Source

المصدر الوحيد:

`companies/company-1/main.html`

لا تبدأ من `main2` ولا `Original` ولا `New-main`.

### Step 3 — Production snapshot

في نفس جلسة المراجعة افحص:

- RPC definitions
- Edge versions
- schema
- constraints
- grants
- RLS
- realtime publication
- triggers
- physical writers

### Step 4 — Trace one capability

لكل مشكلة استخدم:

```text
Mother Consumer
→ Edge / RPC
→ Database
→ Trigger / Constraint
→ Audit
→ Realtime
```

### Step 5 — Historical reconstruction

افتح التاريخ فقط لفهم:

- لماذا أنشئت الدالة؟
- لماذا تغيرت؟
- ما الـbusiness contract المقصود؟
- أين انتقلت responsibility؟

لا تعتبر القديم Current.

### Step 6 — Writer Closure

لا تعالج أكثر من Closure Unit في وقت واحد:

```text
Discover
→ Root Cause
→ Historical Context
→ Surgical Fix
→ Test
→ Deploy
→ Production Verify
→ Close
```

### Step 7 — Physical stock rule

أي تغيير فعلي في المخزون يجب أن ينتهي إلى:

```text
post_stock_movement
→ stock_branches
+ inventory_log
```

ولا تُنشئ Physical Writer ثانيًا.

### Step 8 — Tenant rule

لا تستخدم:

`app_settings LIMIT 1`

لاشتقاق Tenant من مستخدم مصادق.

استخرج المستخدم أولًا من:

`auth.uid()`

ثم:

`users.auth_id`

ثم:

`users.company_id`

### Step 9 — Child structures

قبل لمس `run_sheet_details` افحص trigger الـsync من `order_details`.

لا تضف Dual Write.

### Step 10 — Browser closure

لا تعتبر:

`DB PASS`

أو:

`RPC PASS`

أو:

`Edge PASS`

إثباتًا للـMother.

الإغلاق النهائي يتطلب:

```text
Current Git
+
Current Production
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

ثم فقط يمكن رفع الحالة إلى:

`100% CLOSED`.

---

# 20. الحالة النهائية للجلسة

```text
PHYSICAL WRITERS OUTSIDE post_stock_movement = 0
INVENTORY CONTROL BACKEND = CLOSED
INVENTORY REQUEST RLS = CLOSED
INVENTORY CONTROL AUTH GATEWAY = CLOSED
REALTIME CONTROL SUPPORT = CLOSED
MOTHER INVENTORY CONTROL = OPEN (OWNER PATCH)
AUTHENTICATED MOTHER E2E = OPEN
GLOBAL INVENTORY ZERO-DEBT = NOT YET 100%
```

**المرحلة التالية ليست إعادة التحقيق من الصفر.**

المرحلة التالية تبدأ مباشرة من:

`Current Mother after owner surgical merge`

ثم Browser/Console/Network E2E، وبعدها فقط تُغلق Inventory Control بالكامل أو تُفتح نقطة defect الجديدة المثبتة.
