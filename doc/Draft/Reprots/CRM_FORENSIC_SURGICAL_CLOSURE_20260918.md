# RAWAEA ERP — CRM FORENSIC / SURGICAL CLOSURE
## 2026-09-18 — Customer Relationship Management only

> نطاق هذا التقرير: **CRM فقط**.  
> لا تغيير في inventory / picking / loading / delivery / returns / finance / HR.  
> `companies/company-1/main.html` لم يُعدَّل بواسطة CTO.  
> تقارير الماضي استُخدمت كقرائن فقط؛ الحالة الحالية ثبتت من Git + Mother source + Production DB + Production functions + permissions + runtime SQL tests.

---

## 1. مصدر الحقيقة عند بداية الجلسة

### System repository
`papamohammed77-glitch/rawaie-erp-New`

Current System HEAD observed:
`0ccfe870adcb5dccded96684ae347f3dbe6a3e89`

Previous CURRENT_STATE commit immediately before it in the current sequence:
`96cbd83bf3e69600910ae655eb832a72e3d710c1`

### Mother repository
`papamohammed77-glitch/erp-frontend`

Current Mother HEAD recorded by the latest CURRENT_STATE:
`9a0b72ef746f2f6f5c1b149edd2a490df39377c6`

Current Mother `companies/company-1/main.html` blob:
`8ba8ef60c2875ea68ed85283ce772e023c0ef771`

Current CRM module exact location:
- `companies/company-1/main.html`
- current blob: `8ba8ef60c2875ea68ed85283ce772e023c0ef771`
- `RW_CRM` begins at line **23899**
- current module ends at line **24017**
- module length: **10,605 bytes**

No `main.html` write was performed.

---

## 2. Governance and historical continuity

The governing directive requires:

`UNDERSTAND → RECONSTRUCT HISTORICAL CONTRACT → TRACE CURRENT BEHAVIOR → TRACE DATA/AUTH FLOW → COMPARE TARGET → IDENTIFY GAP → SURGICAL FIX → VERIFY → DEPLOY → PRODUCTION VERIFY`

Current CRM was therefore not treated as defective merely because it is small.

Historical source inspection proved that:
- `RW_Customers` is the existing customer-master management surface (CRUD/search/sort).
- `RW_CRM` is a separate relationship/follow-up cockpit.
- Older `Original/Edge Functions/save-customer.ts` and `delete-customer.ts` are legacy and are not the current CRM runtime.
- The current CRM source has **no direct INSERT/UPDATE/DELETE** on customer tables; it reads data and writes follow-ups through `crm_save_customer_followup`.
- The current navigation already maps:
  - `crm` → permission `customers`
  - `crm` → `RW_CRM.render()`
- This route is already correct and was not changed.

---

## 3. Current CRM behavior — proven

The current CRM module only provided:

1. Customer list.
2. Search by name/code/phone.
3. Four KPIs:
   - total customers
   - active customers
   - aggregate `customers.debt`
   - open followups
4. Customer follow-up modal.
5. Phone / WhatsApp quick contact.
6. Follow-up creation through:
   `crm_save_customer_followup`
7. Follow-up history read directly from `customer_followups`.

It did **not** provide a real Customer 360.

Missing proven capabilities:
- consolidated customer profile;
- order/sales history;
- runsheet/delivery context;
- customer ledger history;
- overdue vs today follow-up visibility;
- next scheduled follow-up;
- customer assignment management;
- follow-up status transitions after creation;
- centralized CRM read contract;
- integrated customer metrics.

This is not an inventory/business-engine defect. It is a **CRM surface incompleteness**.

---

## 4. Production database reality

Supabase project:
`fiilmooggumokxanwiyx`

CRM-domain tables verified:

| Table | Production rows |
|---|---:|
| customers | 3 |
| customer_followups | 0 |
| customer_assignments | 0 |
| customer_ledger | 0 |
| orders | 0 |
| promotion_customers | 0 |

All three Production customers currently belong to:
`00000000-0000-0000-0000-000000000001`

Current Production customer master is intentionally small and contains no historical order/follow-up/ledger fixtures.

Therefore:
- no fake CRM business history was inserted;
- zero metrics in current Production are real zeroes;
- no historical CRM transaction could legitimately be claimed from live data.

---

## 5. Existing Production contract that must be preserved

### Customer identity
`customers` has:
`UNIQUE (company_id, customer_code)`

The CRM follow-up table currently stores:
`customer_followups.customer_id = customer_code` as TEXT.

This is a legacy contract used by:
- `crm_save_customer_followup`
- `app_private.customer_belongs_to_current_company(customer_code)`

Because Production currently contains **0 follow-up rows**, but the historical contract is already used by the security helper, the field was **not replaced** in this CRM closure.

No speculative schema rewrite was performed.

### Financial identity
`customer_ledger.customer_id` is UUID and references `customers.id`.

The canonical financial writer already available is:
`post_customer_ledger_entry(company_id, operation_id, customer_id,...)`

It is company-scoped and idempotent through `erp_operation_registry`.

CRM therefore reads financial data; it does not create a second ledger engine.

### Order / fulfillment identity
`orders.customer_id` is the customer UUID.
`orders.runsheet_id` links the order to the existing runsheet lifecycle.
`order_details` remains the existing fulfillment detail source.

CRM therefore **reads** fulfillment context and does not create a second fulfillment source.

---

## 6. Root cause

### Root cause A — CRM stopped at the skeleton
The current module implements a follow-up list, not a relationship cockpit.

### Root cause B — latent CRM data domains were disconnected
Production already had:
- `customer_assignments`
- `customer_followups`
- `customer_ledger`
- `orders`
- `runsheets`
- `promotion_customers`

But the CRM UI consumed almost none of these domains.

### Root cause C — no controlled status-management contract
Follow-ups could be created with a status, but an existing follow-up had no canonical UI operation to:
- complete;
- reopen;
- cancel.

### Root cause D — no centralized CRM read contract
The CRM UI queried `customers` and `customer_followups` directly.
The security boundary remained present through RLS, but cross-domain business aggregation was left to the browser.

---

## 7. Competitive benchmark — verified current official documentation

### Odoo
Odoo 19 documents CRM activities as follow-up tasks attached to CRM records, with custom activity types and **activity plans** that can automatically schedule sequences and assign responsibilities. It also emphasizes keeping activities updated as Done so the pipeline does not accumulate stale overdue activity.

Source:
https://www.odoo.com/documentation/19.0/applications/sales/crm/optimize/utilize_activities.html

### Microsoft Dynamics 365
Dynamics 365 provides a unified **timeline** for account/contact activities such as email, appointments, phone calls, notes and tasks, with filtering/sorting. Its sales work-list model also keeps the seller in context while completing calls, emails, meetings and other activities.

Sources:
https://learn.microsoft.com/en-us/dynamics365/sales/timeline-activities
https://learn.microsoft.com/en-gb/dynamics365/sales/manage-activities
https://learn.microsoft.com/en-us/dynamics365/sales/connect-with-customers

### SAP Sales Cloud
SAP documents:
- 360-degree customer information for field visits;
- planning visits and activities;
- action plans;
- timeline/chronological customer process visibility;
- route planning.

Sources:
https://help.sap.com/docs/r/24765b551a014b779b95c7b07d8e9079/CLOUD/en-
https://help.sap.com/docs/CX_NG_SALES/ea5ff8b9460a43cb8765a3c07d3421fe/38fd5132e8024d8fbca380e1f4276864.html
https://help.sap.com/docs/PRODUCT_ID/d6b1239c62d34c118fd2a59073358496/29cf7874113d4ea2ab0d8dfe599ca281.html

### Daftra
Daftra documents a customer-centric CRM screen with:
- search/filtering;
- customer status;
- follow-up;
- appointments/actions;
- customer invoices and other related records;
- staff assignment;
- notes and attachments;
- timeline-oriented communication.

Sources:
https://docs.daftra.com/en/user_manual/crm-comprehensive-guide/
https://www.daftra.com/crm/
https://www.daftra.com/en/features/sub_feature/2

### Manager.io
Manager treats the customer as the accounting relationship anchor and provides customer statements covering:
- unpaid invoices;
- transactions;
- balances;
- aging;
- customer history.

Sources:
https://www2.manager.io/guides/7018
https://www2.manager.io/guides/7022
https://www2.manager.io/guides/17468

### Benchmark conclusion
The recurring pattern across the documented products is not “more buttons”.
It is:

**one customer context → activities → financial position → commercial history → next action**

That is the target applied here without copying another product’s business engine.

---

## 8. Surgical Production closure implemented

### 8.1 CRM Directory RPC
Created:

`public.crm_customer_directory(text, boolean, integer, integer)`

Responsibilities:
- resolve company from authenticated user context;
- enforce `customers` permission;
- company-scope all customer data;
- search by:
  - name
  - code
  - phone
  - area
  - contact person
- return customer master data;
- return order count;
- return sales total;
- return last order date;
- return open/overdue/next followup metrics;
- return active company users for CRM assignment;
- return aggregate CRM KPIs.

### 8.2 Customer 360 RPC
Created:

`public.crm_customer_360(uuid)`

Returns:
- customer master/profile;
- debt/credit limit/loyalty;
- order count and sales total;
- ledger balance;
- open/overdue/next follow-up;
- assignments;
- last 20 customer orders;
- runsheet status linked to those orders;
- fulfillment quantities:
  - ordered
  - picked
  - loaded
  - delivered
  - refused
  - returned
- last 50 follow-ups;
- last 50 customer-ledger entries.

This is a **read cockpit only**.
It does not replace any sales, fulfillment, inventory or finance engine.

### 8.3 Customer assignment RPC
Created:

`public.crm_set_customer_assignment(uuid, uuid, boolean, text)`

Controls:
- current company;
- customer ownership;
- assigned user ownership;
- caller identity;
- active assignment.

It writes to existing `customer_assignments`.

### 8.4 Follow-up status RPC
Created:

`public.crm_set_customer_followup_status(uuid, text, text, text)`

Supported normalized states:
- Open
- completed
- cancelled

It also controls:
- reopening;
- completion timestamp;
- optional assignment/notes retention.

### 8.5 Audit boundary
Created audit triggers for:
- `customer_followups`
- `customer_assignments`

using the existing authoritative:
`public.fn_audit_trigger()`

Existing `customers` audit trigger was retained and not duplicated.

### 8.6 Read indexes
Added:
- `idx_orders_company_customer_date`
- `idx_customer_followups_company_customer_date`
- `idx_customer_ledger_customer_date`
- `idx_customer_assignments_customer_active`

---

## 9. Production migrations actually applied

1. `crm_customer_360_closure_20260918`
2. `crm_customer_360_ordered_arrays_fix_20260918`

The second migration was a real self-test correction of ordered JSON aggregation inside Customer 360.

No customer, order, ledger or follow-up Production data was left behind.

---

## 10. Production verification

### Permission/context verification
A real company CRM user was used in JWT context:
- user: `sales.manager@rawaea.com`
- company:
  `00000000-0000-0000-0000-000000000001`

Verified:
- `auth.uid()`
- company resolution through `app_private.current_user_company_id()`
- `app_private.current_user_has_permission('customers')`
- Customer 360 access for a real Production customer.

### Customer 360 runtime result
For:
`f159c414-f7f8-4909-ac75-f971b08ee508`

Production returned:
- customer profile successfully;
- orders = [];
- followups = [];
- ledger = [];
- order_count = 0;
- sales_total = 0;
- open_followups = 0;
- overdue_followups = 0.

This exactly matches current Production data.

### Mutation transaction test
Inside one JWT-context transaction:
1. `crm_save_customer_followup` created a test follow-up.
2. `crm_set_customer_followup_status` completed it.
3. `crm_set_customer_assignment` created an assignment.
4. Audit records were generated.
5. Transaction was rolled back.

Observed before rollback:
- test followups = 1
- test assignments = 1
- audit rows = 2

After rollback, Production remained:
- customers = 3
- customer_followups = 0
- customer_assignments = 0
- customer_ledger = 0

Therefore no artificial business history remains.

---

## 11. Current CRM source gap

### Exact defective current element

File:
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

Current Mother blob:
`8ba8ef60c2875ea68ed85283ce772e023c0ef771`

Exact current module:
- starts line 23899
- ends line 24017

Search for this exact element:

`// RW_CRM – إدارة علاقات العملاء (CRM)`

Delete the complete block starting at that marker and ending at:

`window.RW_CRM = RW_CRM;`

Do **not** delete the following `RW_SalesReturnsManagement` module.

---

## 12. Complete surgical replacement — READY

Replace the exact current CRM block above with the following complete block:

```javascript
var RW_CRM = (function() {
    'use strict';

    var state = {
        customers: [],
        assignees: [],
        kpi: {},
        search: '',
        activeOnly: false,
        searchTimer: null
    };

    function _esc(s) {
        return String(s == null ? '' : s)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    function _fmtNum(n) {
        return Number(n || 0).toLocaleString('ar-EG');
    }

    function _fmtMoney(n) {
        return Number(n || 0).toLocaleString('ar-EG') + ' EGP';
    }

    function _today() {
        var d = new Date();
        var local = new Date(d.getTime() - d.getTimezoneOffset() * 60000);
        return local.toISOString().slice(0, 10);
    }

    function _statusLabel(s) {
        var map = {
            Open: 'مفتوحة',
            'معلقة': 'معلقة',
            completed: 'مكتملة',
            'مكتملة': 'مكتملة',
            cancelled: 'ملغاة',
            'ملغاة': 'ملغاة'
        };
        return map[s] || s || 'غير محددة';
    }

    function _statusClass(s) {
        if (s === 'completed' || s === 'مكتملة') return 'bg-green-100 text-green-700';
        if (s === 'cancelled' || s === 'ملغاة') return 'bg-gray-100 text-gray-600';
        return 'bg-amber-100 text-amber-700';
    }

    function _assignedLabel(customer) {
        var rows = Array.isArray(customer && customer.assigned_to) ? customer.assigned_to : [];
        if (!rows.length) return 'غير مسند';
        var active = rows.filter(function(x) { return x && x.active !== false; });
        if (!active.length) active = rows;
        return active.slice(0, 2).map(function(x) {
            return x.name || x.email || '—';
        }).join('، ') + (active.length > 2 ? ' +' + (active.length - 2) : '');
    }

    async function _loadDirectory() {
        var res = await supabase.rpc('crm_customer_directory', {
            p_search: state.search || null,
            p_active_only: state.activeOnly,
            p_limit: 200,
            p_offset: 0
        });
        if (res.error) throw res.error;

        var payload = res.data || {};
        state.customers = Array.isArray(payload.customers) ? payload.customers : [];
        state.assignees = Array.isArray(payload.assignees) ? payload.assignees : [];
        state.kpi = payload.kpi || {};
        return payload;
    }

    function _renderKpis() {
        var k = state.kpi || {};
        return '<div class="grid grid-cols-2 md:grid-cols-3 xl:grid-cols-6 gap-4">' +
            '<div class="bg-white rounded-2xl border p-4"><div class="text-xs text-gray-500">إجمالي العملاء</div><div class="text-2xl font-black text-indigo-600 mt-2">' + _fmtNum(k.total_customers) + '</div></div>' +
            '<div class="bg-white rounded-2xl border p-4"><div class="text-xs text-gray-500">عملاء نشطون</div><div class="text-2xl font-black text-green-600 mt-2">' + _fmtNum(k.active_customers) + '</div></div>' +
            '<div class="bg-white rounded-2xl border p-4"><div class="text-xs text-gray-500">ذمم مسجلة</div><div class="text-2xl font-black text-red-600 mt-2">' + _fmtMoney(k.master_debt_total) + '</div></div>' +
            '<div class="bg-white rounded-2xl border p-4"><div class="text-xs text-gray-500">متابعات مفتوحة</div><div class="text-2xl font-black text-amber-600 mt-2">' + _fmtNum(k.open_followups) + '</div></div>' +
            '<div class="bg-white rounded-2xl border p-4"><div class="text-xs text-gray-500">متأخرة</div><div class="text-2xl font-black text-rose-600 mt-2">' + _fmtNum(k.overdue_followups) + '</div></div>' +
            '<div class="bg-white rounded-2xl border p-4"><div class="text-xs text-gray-500">مستحقة اليوم</div><div class="text-2xl font-black text-blue-600 mt-2">' + _fmtNum(k.due_today) + '</div></div>' +
        '</div>';
    }

    function _renderTable() {
        if (!state.customers.length) {
            return '<div class="text-center py-16 text-gray-400"><div class="text-5xl mb-3">👥</div><div class="font-black text-lg">لا توجد عملاء مطابقون</div><div class="text-sm mt-2">غيّر البحث أو الفلاتر ثم أعد المحاولة.</div></div>';
        }

        var html = '<div class="overflow-x-auto"><table class="w-full text-sm">' +
            '<thead class="bg-slate-50"><tr>' +
            '<th class="p-3 text-right">العميل</th>' +
            '<th class="p-3 text-right">التواصل</th>' +
            '<th class="p-3 text-right">التصنيف</th>' +
            '<th class="p-3 text-center">المبيعات</th>' +
            '<th class="p-3 text-center">الأوردرات</th>' +
            '<th class="p-3 text-center">المتابعة القادمة</th>' +
            '<th class="p-3 text-right">المسؤول</th>' +
            '<th class="p-3 text-center">الإجراء</th>' +
            '</tr></thead><tbody>';

        for (var i = 0; i < state.customers.length; i++) {
            var c = state.customers[i] || {};
            var overdue = Number(c.overdue_followups || 0) > 0;
            var next = c.next_followup_date ? String(c.next_followup_date) : '—';

            html += '<tr class="border-b hover:bg-slate-50">' +
                '<td class="p-3"><div class="font-black">' + _esc(c.name) + '</div><div class="text-xs text-gray-400">' + _esc(c.customer_code) + '</div></td>' +
                '<td class="p-3"><div>' + _esc(c.phone || '—') + '</div><div class="text-xs text-gray-400">' + _esc(c.area || '—') + '</div></td>' +
                '<td class="p-3"><div class="font-bold">' + _esc(c.customer_type || '—') + '</div><div class="text-xs text-gray-400">' + _esc(c.payment_type || '—') + '</div></td>' +
                '<td class="p-3 text-center font-black">' + _fmtMoney(c.sales_total) + '</td>' +
                '<td class="p-3 text-center font-black">' + _fmtNum(c.order_count) + '</td>' +
                '<td class="p-3 text-center"><span class="px-2 py-1 rounded-full text-xs font-black ' + (overdue ? 'bg-rose-100 text-rose-700' : 'bg-slate-100 text-slate-700') + '">' + _esc(next) + '</span></td>' +
                '<td class="p-3">' + _esc(_assignedLabel(c)) + '</td>' +
                '<td class="p-3 text-center"><button type="button" data-crm-open360="' + _esc(c.id) + '" class="px-4 py-2 bg-indigo-600 text-white rounded-xl font-black">Customer 360</button></td>' +
            '</tr>';
        }

        return html + '</tbody></table></div>';
    }

    function _bindDirectory() {
        var search = byId('crm-search');
        if (search) {
            search.value = state.search;
            search.addEventListener('input', function() {
                state.search = search.value.trim();
                clearTimeout(state.searchTimer);
                state.searchTimer = setTimeout(function() {
                    _loadDirectory().then(function() {
                        safeHTML(byId('crm-customers-list'), _renderTable());
                        _bindOpen360();
                        safeHTML(byId('crm-kpis'), _renderKpis());
                    }).catch(function(e) {
                        showToast(e.message || 'فشل البحث', 'error');
                    });
                }, 250);
            });
        }

        var active = byId('crm-active-only');
        if (active) {
            active.checked = state.activeOnly;
            active.addEventListener('change', function() {
                state.activeOnly = active.checked;
                render();
            });
        }

        var refresh = byId('crm-refresh');
        if (refresh) refresh.addEventListener('click', render);

        _bindOpen360();
    }

    function _bindOpen360() {
        var buttons = document.querySelectorAll('[data-crm-open360]');
        for (var i = 0; i < buttons.length; i++) {
            buttons[i].addEventListener('click', function() {
                _openCustomer360(this.getAttribute('data-crm-open360'));
            });
        }
    }

    async function render() {
        var container = byId('rw-page-container');
        if (!container) return;

        safeText(byId('rw-header-title'), 'إدارة علاقات العملاء (CRM)');
        safeText(byId('rw-header-subtitle'), 'Customer 360 • المتابعة • المبيعات • الذمم • التعيينات');

        showLoader('جاري تحميل مركز علاقات العملاء...');
        try {
            await _loadDirectory();
        } catch (e) {
            hideLoader();
            safeHTML(container, '<div class="rw-card p-8 text-center"><div class="text-5xl mb-3">⚠️</div><h3 class="font-black text-xl">تعذر تحميل CRM</h3><p class="text-gray-500 mt-2">' + _esc(e.message || 'خطأ غير معروف') + '</p></div>');
            return;
        }
        hideLoader();

        var html = '<div class="space-y-5">' +
            '<div id="crm-kpis">' + _renderKpis() + '</div>' +
            '<div class="bg-white rounded-2xl border p-4">' +
                '<div class="flex flex-col xl:flex-row gap-3 xl:items-center">' +
                    '<div class="flex-1"><input id="crm-search" type="search" autocomplete="off" class="w-full p-3 bg-slate-50 border rounded-xl" placeholder="بحث بالاسم أو الكود أو الهاتف أو المنطقة"></div>' +
                    '<label class="flex items-center gap-2 px-3 py-2 rounded-xl bg-slate-50 border text-sm font-bold"><input id="crm-active-only" type="checkbox"> <span>النشط فقط</span></label>' +
                    '<button id="crm-refresh" type="button" class="px-5 py-3 bg-slate-900 text-white rounded-xl font-black">تحديث</button>' +
                '</div>' +
            '</div>' +
            '<div id="crm-customers-list" class="bg-white rounded-2xl border overflow-hidden">' + _renderTable() + '</div>' +
        '</div>';

        safeHTML(container, html);
        _bindDirectory();
    }

    function _assignmentOptions(assignments, selectedId) {
        var html = '<option value="">اختر موظفًا</option>';
        for (var i = 0; i < state.assignees.length; i++) {
            var a = state.assignees[i] || {};
            html += '<option value="' + _esc(a.id) + '"' + (selectedId === a.id ? ' selected' : '') + '>' +
                _esc(a.name || a.email) + (a.role ? ' — ' + _esc(a.role) : '') + '</option>';
        }
        return html;
    }

    function _firstActiveAssignment(assignments) {
        var rows = Array.isArray(assignments) ? assignments : [];
        for (var i = 0; i < rows.length; i++) {
            if (rows[i] && rows[i].is_active !== false) return rows[i];
        }
        return null;
    }

    function _renderProfile(c) {
        return '<div class="bg-indigo-50 rounded-2xl p-5">' +
            '<div class="flex flex-col md:flex-row md:items-start md:justify-between gap-4">' +
                '<div><div class="text-xs text-indigo-700 font-black">' + _esc(c.customer_code) + '</div>' +
                '<h3 class="text-2xl font-black mt-1">' + _esc(c.name) + '</h3>' +
                '<div class="text-sm text-slate-600 mt-2">' + _esc(c.customer_type || '—') + ' • ' + _esc(c.payment_type || '—') + '</div></div>' +
                '<div class="flex flex-wrap gap-2">' +
                    (c.phone ? '<a href="tel:' + _esc(c.phone) + '" class="px-4 py-2 bg-green-600 text-white rounded-xl text-xs font-black">اتصال</a>' : '') +
                    (c.phone ? '<a href="https://wa.me/' + _esc(String(c.phone).replace(/\D/g, '')) + '" target="_blank" rel="noopener" class="px-4 py-2 bg-emerald-600 text-white rounded-xl text-xs font-black">واتساب</a>' : '') +
                '</div>' +
            '</div>' +
            '<div class="grid grid-cols-2 md:grid-cols-4 gap-3 mt-4">' +
                '<div class="bg-white/80 rounded-xl p-3"><div class="text-xs text-slate-500">الهاتف</div><div class="font-black mt-1">' + _esc(c.phone || '—') + '</div></div>' +
                '<div class="bg-white/80 rounded-xl p-3"><div class="text-xs text-slate-500">المنطقة</div><div class="font-black mt-1">' + _esc(c.area || '—') + '</div></div>' +
                '<div class="bg-white/80 rounded-xl p-3"><div class="text-xs text-slate-500">جهة الاتصال</div><div class="font-black mt-1">' + _esc(c.contact_person || '—') + '</div></div>' +
                '<div class="bg-white/80 rounded-xl p-3"><div class="text-xs text-slate-500">حد الائتمان</div><div class="font-black mt-1">' + _fmtMoney(c.credit_limit) + '</div></div>' +
            '</div>' +
            '<div class="text-sm text-slate-700 mt-4">' + _esc(c.address || c.location || 'لا يوجد عنوان مسجل') + '</div>' +
            '</div>';
    }

    function _renderMetrics(m) {
        return '<div class="grid grid-cols-2 md:grid-cols-5 gap-3">' +
            '<div class="bg-white border rounded-xl p-3"><div class="text-xs text-gray-500">الأوردرات</div><div class="text-xl font-black mt-1">' + _fmtNum(m.order_count) + '</div></div>' +
            '<div class="bg-white border rounded-xl p-3"><div class="text-xs text-gray-500">قيمة المبيعات</div><div class="text-xl font-black mt-1">' + _fmtMoney(m.sales_total) + '</div></div>' +
            '<div class="bg-white border rounded-xl p-3"><div class="text-xs text-gray-500">رصيد الدفتر</div><div class="text-xl font-black mt-1">' + (m.ledger_balance == null ? 'لا يوجد دفتر' : _fmtMoney(m.ledger_balance)) + '</div></div>' +
            '<div class="bg-white border rounded-xl p-3"><div class="text-xs text-gray-500">متابعات مفتوحة</div><div class="text-xl font-black mt-1 text-amber-600">' + _fmtNum(m.open_followups) + '</div></div>' +
            '<div class="bg-white border rounded-xl p-3"><div class="text-xs text-gray-500">متابعات متأخرة</div><div class="text-xl font-black mt-1 text-rose-600">' + _fmtNum(m.overdue_followups) + '</div></div>' +
        '</div>';
    }

    function _renderAssignments(assignments) {
        var rows = Array.isArray(assignments) ? assignments : [];
        var selected = _firstActiveAssignment(rows);
        var html = '<div class="bg-white border rounded-2xl p-4">' +
            '<div class="flex flex-col md:flex-row md:items-center md:justify-between gap-3">' +
                '<div><h4 class="font-black">مسؤولو العميل</h4><div class="text-xs text-gray-500 mt-1">التعيين هنا لإدارة العلاقة فقط ولا يغير المندوب التاريخي في الأوردرات.</div></div>' +
                '<div class="flex gap-2">' +
                    '<select id="crm-assignee-select" class="p-2 border rounded-xl min-w-[230px]">' + _assignmentOptions(rows, selected ? selected.user_id : null) + '</select>' +
                    '<button type="button" id="crm-assign-save" class="px-4 py-2 bg-indigo-600 text-white rounded-xl font-black">حفظ</button>' +
                '</div>' +
            '</div>' +
            '<div class="flex flex-wrap gap-2 mt-3">';

        if (!rows.length) {
            html += '<span class="text-sm text-gray-400">لا يوجد تعيينات حالية.</span>';
        } else {
            for (var i = 0; i < rows.length; i++) {
                var a = rows[i] || {};
                html += '<span class="px-3 py-2 rounded-full text-xs font-black ' + (a.is_active ? 'bg-indigo-100 text-indigo-700' : 'bg-gray-100 text-gray-500') + '">' +
                    _esc(a.name || a.email) + (a.is_active ? '' : ' (غير نشط)') + '</span>';
            }
        }

        return html + '</div></div>';
    }

    function _renderOrders(rows) {
        var list = Array.isArray(rows) ? rows : [];
        if (!list.length) return '<div class="text-center py-8 text-gray-400">لا توجد أوردرات مرتبطة بهذا العميل.</div>';

        var html = '<div class="overflow-auto max-h-[34vh]"><table class="w-full text-sm"><thead class="bg-slate-50"><tr>' +
            '<th class="p-2 text-right">الأوردر</th><th class="p-2 text-right">التاريخ</th><th class="p-2 text-right">الحالة</th>' +
            '<th class="p-2 text-right">الرانشيت</th><th class="p-2 text-center">المطلوب</th><th class="p-2 text-center">المسلم</th><th class="p-2 text-left">القيمة</th>' +
            '</tr></thead><tbody>';

        for (var i = 0; i < list.length; i++) {
            var o = list[i] || {};
            html += '<tr class="border-b"><td class="p-2 font-black">' + _esc(o.order_code) + '</td>' +
                '<td class="p-2">' + _esc(o.order_date) + '</td>' +
                '<td class="p-2">' + _esc(o.order_status || '—') + '</td>' +
                '<td class="p-2">' + _esc(o.runsheet_code || '—') + (o.runsheet_status ? ' <span class="text-xs text-gray-400">(' + _esc(o.runsheet_status) + ')</span>' : '') + '</td>' +
                '<td class="p-2 text-center">' + _fmtNum(o.qty_ordered) + '</td>' +
                '<td class="p-2 text-center">' + _fmtNum(o.qty_delivered) + '</td>' +
                '<td class="p-2 text-left font-black">' + _fmtMoney(o.total_amount) + '</td></tr>';
        }

        return html + '</tbody></table></div>';
    }

    function _renderFollowups(rows) {
        var list = Array.isArray(rows) ? rows : [];
        if (!list.length) return '<div class="text-center py-8 text-gray-400">لا توجد متابعات سابقة.</div>';

        var html = '';
        for (var i = 0; i < list.length; i++) {
            var f = list[i] || {};
            var isOpen = f.status === 'Open' || f.status === 'معلقة';
            html += '<div class="border-b py-3">' +
                '<div class="flex flex-col md:flex-row md:items-start md:justify-between gap-2">' +
                    '<div><div class="font-black">' + _esc(f.subject || f.followup_type || 'متابعة') + '</div>' +
                    '<div class="text-xs text-gray-500 mt-1">' + _esc(f.followup_date) + ' • ' + _esc(f.assigned_to || 'غير مسند') + ' • أنشأها ' + _esc(f.created_by || '—') + '</div></div>' +
                    '<span class="px-2 py-1 rounded-full text-xs font-black ' + _statusClass(f.status) + '">' + _esc(_statusLabel(f.status)) + '</span>' +
                '</div>' +
                '<div class="text-sm text-slate-700 mt-2">' + _esc(f.notes || '—') + '</div>' +
                '<div class="flex flex-wrap gap-2 mt-2">' +
                    (isOpen ?
                        '<button type="button" data-crm-followup-status="completed" data-crm-followup-id="' + _esc(f.id) + '" class="px-3 py-1 rounded-lg bg-green-50 text-green-700 text-xs font-black">إتمام</button>' +
                        '<button type="button" data-crm-followup-status="cancelled" data-crm-followup-id="' + _esc(f.id) + '" class="px-3 py-1 rounded-lg bg-rose-50 text-rose-700 text-xs font-black">إلغاء</button>' :
                        '<button type="button" data-crm-followup-status="Open" data-crm-followup-id="' + _esc(f.id) + '" class="px-3 py-1 rounded-lg bg-indigo-50 text-indigo-700 text-xs font-black">إعادة فتح</button>') +
                '</div>' +
            '</div>';
        }

        return html;
    }

    function _renderLedger(rows) {
        var list = Array.isArray(rows) ? rows : [];
        if (!list.length) return '<div class="text-center py-8 text-gray-400">لا توجد حركة دفترية لهذا العميل.</div>';

        var html = '<div class="overflow-auto max-h-[30vh]"><table class="w-full text-sm"><thead class="bg-slate-50"><tr>' +
            '<th class="p-2 text-right">التاريخ</th><th class="p-2 text-right">المرجع</th><th class="p-2 text-right">الوصف</th>' +
            '<th class="p-2 text-left">مدين</th><th class="p-2 text-left">دائن</th><th class="p-2 text-left">الرصيد</th>' +
            '</tr></thead><tbody>';

        for (var i = 0; i < list.length; i++) {
            var l = list[i] || {};
            html += '<tr class="border-b"><td class="p-2">' + _esc(l.entry_date) + '</td>' +
                '<td class="p-2 font-bold">' + _esc(l.reference || '—') + '</td>' +
                '<td class="p-2">' + _esc(l.description || '—') + '</td>' +
                '<td class="p-2 text-left">' + _fmtMoney(l.debit) + '</td>' +
                '<td class="p-2 text-left">' + _fmtMoney(l.credit) + '</td>' +
                '<td class="p-2 text-left font-black">' + _fmtMoney(l.balance) + '</td></tr>';
        }

        return html + '</tbody></table></div>';
    }

    function _followupTypeOptions() {
        return '<option value="Call">هاتف</option>' +
            '<option value="WhatsApp">واتساب</option>' +
            '<option value="Visit">زيارة</option>' +
            '<option value="Email">بريد</option>' +
            '<option value="Other">أخرى</option>';
    }

    async function _saveFollowup(customerCode) {
        var current = (RW_STATE && RW_STATE.app && RW_STATE.app.currentUser) || {};
        var assigned = byId('crm-followup-assignee') ? byId('crm-followup-assignee').value : '';
        var r = await supabase.rpc('crm_save_customer_followup', {
            p_customer_code: customerCode,
            p_followup_date: byId('crm-followup-date').value,
            p_followup_type: byId('crm-followup-type').value,
            p_status: byId('crm-followup-status').value,
            p_subject: byId('crm-followup-subject').value.trim() || null,
            p_notes: byId('crm-followup-notes').value.trim() || null,
            p_assigned_to: assigned || current.email || null
        });
        if (r.error) throw r.error;
        return r.data;
    }

    async function _setFollowupStatus(id, status) {
        var r = await supabase.rpc('crm_set_customer_followup_status', {
            p_followup_id: id,
            p_status: status
        });
        if (r.error) throw r.error;
        return r.data;
    }

    async function _setAssignment(customerId) {
        var select = byId('crm-assignee-select');
        if (!select || !select.value) {
            showToast('اختر موظفًا أولًا', 'warning');
            return null;
        }

        var r = await supabase.rpc('crm_set_customer_assignment', {
            p_customer_id: customerId,
            p_user_id: select.value,
            p_is_active: true,
            p_notes: 'تعيين من CRM'
        });
        if (r.error) throw r.error;
        return r.data;
    }

    async function _refreshAfterMutation(customerId) {
        await _loadDirectory();
        safeHTML(byId('crm-kpis'), _renderKpis());
        safeHTML(byId('crm-customers-list'), _renderTable());
        _bindOpen360();
        if (customerId) await _openCustomer360(customerId);
    }

    function _bind360(customerId, customerCode) {
        var save = byId('crm-save-followup');
        if (save) {
            save.addEventListener('click', async function() {
                try {
                    if (!byId('crm-followup-date').value) {
                        showToast('تاريخ المتابعة مطلوب', 'warning');
                        return;
                    }
                    showLoader('جاري حفظ المتابعة...');
                    await _saveFollowup(customerCode);
                    hideLoader();
                    showToast('تم حفظ المتابعة', 'success');
                    await _refreshAfterMutation(customerId);
                } catch (e) {
                    hideLoader();
                    showToast(e.message || 'فشل حفظ المتابعة', 'error');
                }
            });
        }

        var assign = byId('crm-assign-save');
        if (assign) {
            assign.addEventListener('click', async function() {
                try {
                    showLoader('جاري حفظ التعيين...');
                    var result = await _setAssignment(customerId);
                    hideLoader();
                    if (!result) return;
                    showToast('تم تحديث مسؤول العميل', 'success');
                    await _refreshAfterMutation(customerId);
                } catch (e) {
                    hideLoader();
                    showToast(e.message || 'فشل تحديث التعيين', 'error');
                }
            });
        }

        var actionButtons = document.querySelectorAll('[data-crm-followup-status]');
        for (var i = 0; i < actionButtons.length; i++) {
            actionButtons[i].addEventListener('click', async function() {
                var id = this.getAttribute('data-crm-followup-id');
                var status = this.getAttribute('data-crm-followup-status');
                if (status === 'cancelled') {
                    var confirm = await Swal.fire({
                        title: 'إلغاء المتابعة؟',
                        text: 'سيتم إبقاء السجل مع حالة ملغاة.',
                        icon: 'warning',
                        showCancelButton: true,
                        confirmButtonText: 'إلغاء المتابعة',
                        cancelButtonText: 'تراجع'
                    });
                    if (!confirm.isConfirmed) return;
                }

                try {
                    showLoader('جاري تحديث حالة المتابعة...');
                    await _setFollowupStatus(id, status);
                    hideLoader();
                    showToast('تم تحديث المتابعة', 'success');
                    await _refreshAfterMutation(customerId);
                } catch (e) {
                    hideLoader();
                    showToast(e.message || 'فشل تحديث المتابعة', 'error');
                }
            });
        }
    }

    async function _openCustomer360(customerId) {
        showLoader('جاري تحميل Customer 360...');
        var res = await supabase.rpc('crm_customer_360', { p_customer_id: customerId });
        hideLoader();

        if (res.error) {
            showToast(res.error.message || 'تعذر تحميل ملف العميل', 'error');
            return;
        }

        var payload = res.data || {};
        var c = payload.customer || {};
        var m = payload.metrics || {};
        var assignments = payload.assignments || [];
        var orders = payload.orders || [];
        var followups = payload.followups || [];
        var ledger = payload.ledger || [];
        var firstAssignment = _firstActiveAssignment(assignments);

        var html = '<div class="text-right space-y-4">' +
            _renderProfile(c) +
            _renderMetrics(m) +
            _renderAssignments(assignments) +
            '<div class="bg-white border rounded-2xl p-4">' +
                '<div class="flex flex-col md:flex-row md:items-center md:justify-between gap-2 mb-3">' +
                    '<h4 class="font-black">إضافة متابعة</h4>' +
                    '<span class="text-xs text-gray-500">حدد الإجراء القادم واحفظه داخل سجل العميل.</span>' +
                '</div>' +
                '<div class="grid grid-cols-1 md:grid-cols-4 gap-2">' +
                    '<input id="crm-followup-date" type="date" class="p-2 border rounded-xl" value="' + _today() + '">' +
                    '<select id="crm-followup-type" class="p-2 border rounded-xl">' + _followupTypeOptions() + '</select>' +
                    '<select id="crm-followup-status" class="p-2 border rounded-xl"><option value="Open">مفتوحة</option><option value="completed">مكتملة</option><option value="cancelled">ملغاة</option></select>' +
                    '<select id="crm-followup-assignee" class="p-2 border rounded-xl">' + _assignmentOptions(assignments, firstAssignment ? firstAssignment.user_id : null) + '</select>' +
                '</div>' +
                '<input id="crm-followup-subject" class="w-full mt-2 p-2 border rounded-xl" placeholder="موضوع المتابعة">' +
                '<textarea id="crm-followup-notes" class="w-full mt-2 p-2 border rounded-xl" rows="3" placeholder="الملاحظات والإجراء المطلوب"></textarea>' +
                '<div class="flex justify-end mt-2"><button id="crm-save-followup" type="button" class="px-6 py-2 bg-indigo-600 text-white rounded-xl font-black">حفظ المتابعة</button></div>' +
            '</div>' +
            '<div class="bg-white border rounded-2xl p-4"><h4 class="font-black mb-3">آخر الأوردرات والتوصيل</h4>' + _renderOrders(orders) + '</div>' +
            '<div class="bg-white border rounded-2xl p-4"><h4 class="font-black mb-3">سجل المتابعات</h4>' + _renderFollowups(followups) + '</div>' +
            '<div class="bg-white border rounded-2xl p-4"><h4 class="font-black mb-3">الحركة المالية</h4>' + _renderLedger(ledger) + '</div>' +
        '</div>';

        Swal.fire({
            title: 'Customer 360 — ' + _esc(c.name || c.customer_code),
            html: html,
            width: '1100px',
            showCloseButton: true,
            showConfirmButton: false,
            customClass: { popup: 'rounded-3xl overflow-hidden' },
            didOpen: function() {
                _bind360(c.id, c.customer_code);
            }
        });
    }

    return {
        render: render,
        openCustomer360: _openCustomer360
    };
})();
window.RW_CRM = RW_CRM;
```

---

## 13. What the new source does

The replacement keeps the existing CRM route and permission untouched.

It changes only the CRM experience:

`Customer List`
→ `CRM KPIs`
→ `Customer 360`
→ `Orders + Runsheet/Delivery context`
→ `Financial Ledger`
→ `Assignments`
→ `Follow-up creation`
→ `Follow-up completion / reopen / cancel`

Important contract boundaries:
- no inventory write;
- no stock mutation;
- no order mutation;
- no runsheet mutation;
- no delivery mutation;
- no financial ledger write from CRM;
- no duplicate customer-master CRUD;
- no new fulfillment engine.

The CRM is a **relationship cockpit**, not a replacement ERP subsystem.

---

## 14. Required owner execution on Mother

### Exact surgical action

Search:
`// RW_CRM – إدارة علاقات العملاء (CRM)`

Delete the entire current `RW_CRM` module through:
`window.RW_CRM = RW_CRM;`

Paste the complete replacement in Section 12.

Do not modify:
- `RW_Views`
- `RW_Customers`
- `RW_Orders`
- `RW_Runsheets`
- `RW_SalesReturnsManagement`
- `main.html` outside this exact CRM block.

---

## 15. 100% closure criteria

### Already proven
- Production CRM read contract = READY
- Production Customer 360 = PASS
- Production assignment contract = PASS
- Production follow-up status contract = PASS
- Production audit = PASS
- Production data cleanliness = PASS
- company isolation in RPC contract = PASS
- current CRM source reconstructed = PASS
- no Mother `main.html` modification by CTO = PASS

### Still requiring owner source integration
- owner applies exact CRM replacement;
- current Mother `main.html` blob changes only at CRM block;
- JS syntax check;
- browser opens `CRM`;
- Customer 360 modal opens;
- follow-up create works;
- follow-up complete/reopen/cancel works;
- assignment save works;
- orders/runsheet/ledger sections render when corresponding Production data exists;
- no console error;
- no regression to neighboring modules.

Do not convert Git replacement readiness into browser Production PASS.

---

## 16. CRM Writer / Responsibility Matrix

| Responsibility | Historical | Production | Current | Target |
|---|---|---|---|---|
| Customer master | RW_Customers / legacy save-customer | customers + RLS | separate Customers tab | unchanged |
| CRM read | lightweight direct reads | tables exist | direct browser reads | crm_customer_directory / 360 |
| Follow-up write | crm_save_customer_followup | RPC | RPC | retained |
| Follow-up status | incomplete | no status command | UI could only create status | crm_set_customer_followup_status |
| Assignment | latent table | exists, 0 rows | unused | crm_set_customer_assignment |
| Sales history | orders | 0 rows | absent from CRM | read-only 360 |
| Runsheet/delivery context | runsheets/order_details | 0 rows | absent from CRM | read-only 360 |
| Financial history | customer_ledger | 0 rows | absent from CRM | read-only 360 |
| Physical stock | inventory engine | separate | untouched | separate |
| Authorization | customers permission | RLS + current-user context | route maps to customers | retained |
| Audit | customers audited | followups/assignments now audited | incomplete | expanded |

No business responsibility was moved into CRM from its existing engine.

---

## 17. Why no schema rewrite was performed

The tempting change would be to replace `customer_followups.customer_id TEXT` with UUID.

That was rejected in this closure because:
1. the current security helper explicitly uses the customer-code contract;
2. the current canonical follow-up RPC uses that contract;
3. Production has zero follow-up rows;
4. the CRM objective can be completed without changing that contract;
5. changing it would create unnecessary cross-module migration risk.

This decision is governed by the rule:
**do not rewrite a historical contract merely because another schema shape looks cleaner.**

---

## 18. Self-audit

### Confirmed facts
- Current CRM module was opened from the actual Mother blob.
- Current CRM is only 10,605 bytes.
- CRM route is already correctly permission-bound.
- Production contains 3 customers and no CRM history.
- Existing CRM-related domain tables exist.
- Production functions were applied successfully.
- Production Customer 360 returned valid data.
- mutation path passed inside a rollback transaction.
- audit triggers produced expected rows during test.
- no test business data remains.

### Unknowns
- Final browser rendering after owner applies the replacement.
- Live visual comparison under actual deployed frontend cache.
- Performance of the 360 screen with large production customer/order history.

These are runtime validation items, not unresolved Production architecture defects.

### Conflicts
No current CRM contract conflict was found that requires changing the existing order/runsheet/inventory architecture.

### Unverified claims
No claim of live browser PASS is made in this report.

---

## 19. Next-session instructions

Start from this exact state.

1. Refresh System HEAD and parent.
2. Refresh Mother HEAD and current `main.html` blob.
3. Verify the only intended source delta is the exact CRM block.
4. Verify the Production functions remain:
   - `crm_customer_directory`
   - `crm_customer_360`
   - `crm_set_customer_assignment`
   - `crm_set_customer_followup_status`
   - `crm_save_customer_followup`
5. Verify the CRM audit triggers.
6. Perform browser Login → CRM.
7. Open Customer 360.
8. Create one isolated test follow-up through the real UI, then complete it.
9. Test assignment.
10. Verify customer/order/runsheet/ledger rendering with real data when available.
11. Verify no neighboring module regression.
12. Only after browser evidence is green, move to the next CRM capability.

Do not:
- reopen inventory;
- rewrite customer master;
- rewrite orders;
- rewrite runsheet;
- rewrite delivery;
- rewrite ledger;
- recreate `RW_Customers` inside CRM;
- create a parallel CRM backend;
- mark browser PASS from SQL PASS.

---

## 20. Final closure statement

**CRM Production Core closure = COMPLETE**

**CRM source surgical patch = READY**

**Mother main.html CTO edits = 0**

**Production test data left behind = 0**

**Browser Production closure = OPEN until exact source replacement is integrated and live browser evidence is captured.**
