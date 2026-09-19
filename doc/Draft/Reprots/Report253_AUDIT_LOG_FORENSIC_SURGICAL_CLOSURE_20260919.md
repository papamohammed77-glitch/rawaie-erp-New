# RAWAEA ERP — Report 253
# سجل التدقيق — Forensic Surgical Completion
## 2026-09-19

> النطاق الوحيد لهذه الجلسة: **Audit Log / سجل التدقيق**.
> لم يتم تعديل `erp-frontend/companies/company-1/main.html`.
> أي تغيير في ملف النظام الأم موجود هنا كتعليمات جراحية للمستخدم فقط.
> كل بنية Production الواردة أدناه تم تنفيذها مباشرة على Supabase Production ثم تم فحصها.

---

# 1. قاعدة الحقيقة

تمت مطابقة نقطة الانطلاق وفق:

**CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE**

التقارير السابقة استُخدمت كأدلة تاريخية فقط، ولم تُعامل كحالة حالية.

## CURRENT SYSTEM GIT قبل التقرير

Repository:
`papamohammed77-glitch/rawaie-erp-New`

HEAD قبل هذه الجلسة:
`51fd5a919a43a7c3b53979e1a0fe195bc3d54620`

Parent:
`b4b0ebbc03d227772257b59d6fc036e772a0d803`

## CURRENT MOTHER GIT

Repository:
`papamohammed77-glitch/erp-frontend`

HEAD:
`f45b5511fe3965d012c9f94e09f0dd2102c55140`

Parent:
`adeda04609723e221249e51621cc674b05dfc5ce`

Current `companies/company-1/main.html` blob:
`94a30d3d7fda02967b6a1f3b112ea2ced6d77ac9`

The latest Mother HEAD contains only the subsequent forensic extract commit; the latest actual `main.html` mutation is the parent commit `adeda046...`. No CTO write was made to Mother in this session.

---

# 2. التاريخ الوظيفي لتبويب سجل التدقيق

## ما هو موجود أصلًا

التبويب الحالي ليس Stub:

- route `audit-log` موجود.
- permission = `owner`.
- page container موجود.
- filters موجودة.
- pagination موجودة.
- table موجود.
- detail موجود.
- export كان جزئيًا/غير ناضجًا.
- الـdetail كان يفتح `Swal.fire` كـModal.

Current source points المثبتة:

- `RW_Audit_log` — line 250.
- `RW_Audit_renderTab` — line 567.
- `RW_Audit_loadData` — line 598.
- `RW_Audit_renderTable` — line 646.
- `RW_Audit_renderPagination` — line 737.
- `RW_Audit_goPage` — line 755.
- `RW_Audit_filterTable` — line 760.
- `RW_Audit_showDetails` — line 765، والنهاية عند line 848.
- route `audit-log` — line 25310.
- permission map `audit-log: owner` — line 25196.
- menu registration — line 1226.

## ما وصل إليه البناء ولماذا

السبب المعماري المثبت لوجود الشكل الحالي هو أن المشروع بدأ بسجل تدقيق عام بسيط داخل `main.html`، ثم أضيفت إليه:

1. قراءة مباشرة من `audit_log`.
2. client-side audit helper.
3. Modal للتفاصيل.
4. pagination من الواجهة.

لكن Production تطورت لاحقًا إلى Trigger-based audit على قاعدة البيانات، وأصبحت هناك محركات Atomic/Edge/Database متعددة. النتيجة أن واجهة Audit القديمة بقيت تعمل بمنطق أقدم من العقد الحالي.

لم يتم العثور في سلسلة Mother الحالية على Commit مخصص حديث يعيد تصميم `RW_Audit` نفسه؛ آخر تغييرات `main.html` الحالية كانت في وحدات أخرى. لذلك تعاملنا مع Audit كتراكم Legacy UI فوق عقد Production أحدث.

---

# 3. التحقيق الجنائي — ما تم تنفيذه فعليًا

## 3.1 Production Audit Table

Production كانت تحتوي:

- total rows = 2015
- first row = `2026-07-16 12:07:28.52253+00`
- last row قبل هذه الجراحة = `2026-09-19 06:56:33.775868+00`

العميل القديم كان يعتمد على `audit_log` مباشرة.

## 3.2 جودة الهوية التاريخية

قبل الجراحة:

- actor_user_id = غير موجود كعمود.
- company_id = غير موجود كعمود.
- operation_id = غير موجود كعمود.
- source_type = غير موجود كعمود.
- system = 1752 صفًا.
- anonymous = 25 صفًا.
- actor verified بعد إعادة الربط التاريخي = 190 صفًا.
- company context resolved بعد enrichment = 1047 صفًا.
- operation identity resolved من البيانات التاريخية = 26 صفًا.

هذا يثبت أن `user_email` وحده لم يعد كافيًا ليكون Audit Actor Identity.

## 3.3 ازدواجية التسجيل

Current Mother `RW_Audit_log` كان يرسل:

- create
- update
- delete
- login
- logout
- failed_login

إلى `log-action`.

في الوقت نفسه، Production Database Triggers كانت بالفعل تسجل:

- create
- update
- delete

على الجداول السلطوية، ومنها:

- orders
- order_details
- runsheets
- items
- stock_vouchers
- suppliers
- customers
- journal_entries
- journal_lines
- وغيرها.

إذن create/update/delete من الـclient لم تعد مصدر الحقيقة.

## 3.4 خطورة التفاصيل الخام

فحص Production أثبت:

- 0 سجل يحتوي كلمة password.
- 246 سجلًا يحتوي token داخل old/new JSON.
- هذه السجلات شملت orders create/update/delete.

إذن عرض old/new الخام داخل Audit UI كان يسمح بتمرير بيانات حساسة إلى الواجهة.

---

# 4. Production الإصلاحات المنفذة

## 4.1 Audit identity contract

أضيفت إلى `public.audit_log`:

- `company_id uuid`
- `actor_user_id uuid`
- `source_type text`
- `operation_id text`

وأضيفت الفهارس:

- `idx_audit_log_company_created`
- `idx_audit_log_actor_created`
- `idx_audit_log_table_record_created`
- `idx_audit_log_operation_created`

## 4.2 Historical enrichment

تمت إعادة ربط البيانات التاريخية فقط عندما توجد قرينة حقيقية داخل السجل نفسه:

- user_email → actor_user_id عبر users.email.
- actor_user_id → company_id عبر users.company_id.
- company_id من old/new JSON عندما تكون UUID صالحة.
- operation_id من old/new JSON عندما يكون موجودًا.

لم يتم اختلاق هوية تاريخية غير مثبتة.

## 4.3 Canonical Database Trigger

تم تعديل `fn_audit_trigger()` ليكتب:

- actor_user_id
- company_id
- source_type = `database_trigger`
- operation_id عندما يكون موجودًا
- actor email الحقيقي عندما يكون متاحًا
- fallback system فقط عندما لا توجد جلسة مستخدم.

Row company identity لها أولوية على company context الخاص بالمنفذ.

## 4.4 Read Model

تم إنشاء:

`public.audit_log_query(...)`

وهو Owner-only ويعيد:

- total
- summary
- trust_summary
- page
- page_size
- rows
- occurred_at
- actor_email
- actor_user_id
- action
- table_name
- record_id
- company
- source_type
- operation_id
- actor_trust
- changed_fields

وتم إنشاء:

`public.audit_log_detail(uuid)`

للتفاصيل داخل الصفحة.

## 4.5 Sensitive-data redaction

تم إنشاء:

`public.audit_log_redact_jsonb(jsonb)`

وهو يحجب مفاتيح مثل:

- token
- password
- secret
- authorization
- api_key
- access_key
- refresh_token

ويتم تطبيقه على old_data/new_data عند قراءة التفاصيل.

## 4.6 Direct table access

Production access أصبح:

- anon SELECT = false
- authenticated INSERT = false
- service_role INSERT = true
- service_role DELETE = false

والـAudit query/detail هما واجهة القراءة الرسمية.

تم إبقاء authenticated SELECT على `audit_log` لأن هناك consumers حاليين مثبتين خارج Audit page يحتاجون القراءة، ولم يثبت بعد وجود عقد يسمح بإزالة ذلك السطح دون Regression.

---

# 5. log-action Production Gateway

تمت ترقية Edge Function:

`log-action`

Production version:

**5 ACTIVE**

verify_jwt:

**true**

العقد الجديد:

### Authentication events

مسموح:

- login
- logout
- failed_login

وتُكتب كمصدر:

`application_event`

### Legacy row events

الطلبات القديمة:

- create
- update
- delete

تُقبل للتوافق المؤقت، لكن:

**لا تُكتب إلى audit_log.**

وتعود:

`ignored=true`

والسبب:

`Database audit trigger is authoritative for row changes.`

هذا يمنع كسر Mother الحالية قبل تطبيق Patch ويمنع استمرار الازدواجية في Production.

---

# 6. CURRENT Mother Source — السبب الحقيقي للفجوة

## العيب 1

`RW_Audit_loadData` يقرأ:

`supabase.from('audit_log').select('*')`

مباشرة.

هذا كان مناسبًا للمرحلة القديمة، لكنه لا يعكس الآن:

- actor identity
- company identity
- source
- operation
- trust
- derived changed fields
- redaction policy
- unified read contract.

## العيب 2

`RW_Audit_showDetails`

ينتهي إلى:

`Swal.fire`

وهذا يحقق Modal behavior بدل Record Detail Page.

## العيب 3

`RW_Audit_log`

كان يحاول تسجيل create/update/delete من العميل رغم أن Database Trigger هو المصدر السلطوي لتغييرات الصفوف.

## العيب 4

الـtable الحالي لا يعرض:

- source
- trust
- company
- operation
- changed field count.

## العيب 5

التفاصيل كانت تعتمد على JSON الخام.

---

# 7. سبب الخطأ المطلوب التحقق منه

لا يوجد في خاتمة رسالة المستخدم **نص Error literal محدد** يمكن نسبته إلى سطر غير موجود في الرسالة نفسها، ولذلك لم يتم اختلاق Error.

السبب المثبت في Audit الحالي ليس SyntaxError؛ بل **Contract/Architecture mismatch**:

`Client Audit Event`
↓
`log-action`
↓
`audit_log`

في الوقت نفسه:

`Database Mutation`
↓
`Database Trigger`
↓
`audit_log`

أي أن التبويب كان يعرض سجلًا مبنيًا على مسارين متداخلين، مع actor identity أضعف من العقد الحالي، وdetail Modal منفصل عن Record Audit History.

الجراحة أغلقت هذا التعارض بدون تغيير عقد التشغيل.

---

# 8. مقارنة تنافسية — ما الذي ثبت أنه ناقص

## Odoo

Odoo 19 يوثق Audit Trail يحتوي:

- التاريخ والوقت
- المستخدم
- نوع التغيير
- القيمة السابقة
- القيمة الجديدة

كما يضع Audit Trail كتقرير مستقل، ويدعم restrictive audit mode لإتاحة تحكم أقوى في عدم حذف السجلات المتتبعة.

المصدر الرسمي:
https://www.odoo.com/documentation/19.0/applications/finance/accounting/reporting.html

## Microsoft Dynamics / Dataverse

يوفر:

- Audit History للسجل الواحد.
- Audit Summary على مستوى البيئة.
- Who / When / What.
- field-level history.
- previous value.
- user access auditing.
- filtering.
- APIs.

المصدر الرسمي:
https://learn.microsoft.com/en-us/power-platform/admin/manage-dataverse-auditing

## SAP

Change Documents تتضمن:

- Who
- When
- What
- Old Value
- New Value
- Field
- Context / Application
- ويمكن استخدام Correlation ID لتجميع تغييرات العملية الواحدة.

المصادر الرسمية:
https://help.sap.com/docs/successfactors-platform/implementing-and-managing-data-protection-and-privacy/interpreting-change-audit-report
https://help.sap.com/docs/successfactors-platform/implementing-and-managing-data-protection-and-privacy/interpreting-change-audit-report

## Daftra

System Activity Log يثبت:

- all actions
- user
- time
- action filter
- keyword
- date range

ويعرض branch في Activity Log الخاص بالإعدادات مع إمكانية الانتقال للسجل المتأثر.

المصادر الرسمية:
https://docs.daftra.com/en/tutorial/system-activity-log-report/
https://docs.daftra.com/en/user_manual/sales-and-inventory-activity-log/

## Manager.io

History يقدم:

- timestamp
- user
- description
- action category
- View individual action
- filter by user
- filter by action
- per-transaction history

المصدر الرسمي:
https://www2.manager.io/guides/29733

---

# 9. Target Audit UX بعد الجراحة

التبويب أصبح مستهدفًا ليعمل كصفحة رقابية، لا مجرد جدول Log.

## الصفحة الرئيسية

تحتوي:

- إجمالي النتائج
- إنشاء
- تعديل
- حذف
- موثق
- نظام / تاريخي
- Refresh
- Export CSV

## البحث والفلاتر

- بحث شامل
- Action
- Table / Entity
- Actor
- Record ID
- From
- To
- Page size
- Clear Filters

## أعمدة القائمة

- التاريخ
- المنفذ
- العملية
- المصدر
- الثقة
- الشركة
- الكيان
- السجل
- عدد الحقول المتغيرة
- التفاصيل

## Detail Page داخل نفس الصفحة

بدل Modal:

- actor
- company
- source
- action
- operation id
- record
- field list
- old value
- new value
- IP
- User Agent
- redaction indicator

## Export

CSV لا يخرج old/new raw values.

ويعتمد على:

- timestamp
- actor
- action
- source
- trust
- company
- table
- record
- operation
- changed fields

---

# 10. Audit Data Contract

## Source of Truth

### Row changes

`Database Trigger`

### Authentication events

`log-action`

### UI Query

`audit_log_query`

### Record Detail

`audit_log_detail`

### Sensitive values

`audit_log_redact_jsonb`

لا توجد Dual Write جديدة.

---

# 11. Owner Surgical Patch A — RW_Audit_log

## الملف

`erp-frontend/companies/company-1/main.html`

## ابحث حرفيًا

داخل:

`function RW_Audit_log(action, tableName, recordId, oldData, newData)`

وهو حاليًا عند line 250.

## احذف الدالة الحالية بالكامل

من:

`function RW_Audit_log(action, tableName, recordId, oldData, newData) {`

حتى القوس المغلق للدالة عند نهاية block الحالي، قبل:

`// ============================================================`
`// RW_Permissions_check`

## استبدلها بالكامل بـ:

```javascript
function RW_Audit_log(action, tableName, recordId, oldData, newData) {
    try {
        var allowed = action === 'login' || action === 'logout' || action === 'failed_login';
        if (!allowed) return;

        if (typeof supabase === 'undefined' || !supabase || !supabase.auth) return;

        var payload = {
            action: action,
            record_id: recordId || null,
            new_data: action === 'failed_login' ? (newData || null) : null
        };

        supabase.auth.getSession().then(function (sessionRes) {
            var session = sessionRes && sessionRes.data && sessionRes.data.session;
            var token = session ? session.access_token : null;

            if (action !== 'failed_login' && !token) return;

            var headers = { 'Content-Type': 'application/json' };
            if (token) headers.Authorization = 'Bearer ' + token;

            return fetch(RW_SUPABASE_URL + '/functions/v1/log-action', {
                method: 'POST',
                headers: headers,
                body: JSON.stringify(payload)
            }).then(function (res) {
                if (!res.ok) {
                    console.warn('Audit event logging failed: HTTP ' + res.status);
                }
            });
        }).catch(function (e) {
            console.warn('Audit event session error:', e);
        });
    } catch (e) {
        console.warn('Audit event exception:', e);
    }
}
```

### نتيجة Patch A

- create/update/delete لم تعد Client Audit Writer.
- login/logout/failed_login فقط أحداث تطبيقية.
- لا Dual Write.
- لا تغيير في Business Logic.
- لا تغيير في operational applications.

---

# 12. Owner Surgical Patch B — RW Audit Page

## الملف

`erp-frontend/companies/company-1/main.html`

## ابحث حرفيًا عن:

`function RW_Audit_renderTab() {`

ثم حدد block Audit كله حتى نهاية:

`RW_Audit_showDetails`

وقبل:

`// ============================================================`
`// دالة togglePasswordVisibility`

Current block boundary:

- start marker = `function RW_Audit_renderTab() {`
- end = نهاية `RW_Audit_showDetails`
- لا تحذف `togglePasswordVisibility`.

## احذف كاملًا

كل العناصر القديمة التالية في هذا block:

- `RW_AUDIT_PAGE`
- `RW_AUDIT_DATA`
- `RW_Audit_renderTab` القديمة
- `RW_Audit_loadData` القديمة
- `RW_Audit_renderTable` القديمة
- `RW_Audit_renderPagination` القديمة
- `RW_Audit_goPage` القديمة
- `RW_Audit_filterTable` القديمة
- `RW_Audit_showDetails` القديمة

## استبدل الكتلة كاملة بـ:

```javascript
var RW_AUDIT_STATE = {
    page: 1,
    pageSize: 50,
    total: 0,
    rows: [],
    selectedId: null,
    loading: false
};

function RW_Audit_escape(value) {
    var s = value == null ? '' : String(value);
    return s
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
}

function RW_Audit_isOwner() {
    try {
        return !!(
            typeof RW_STATE !== 'undefined' &&
            RW_STATE &&
            RW_STATE.app &&
            RW_STATE.app.currentUser &&
            RW_STATE.app.currentUser.isOwner === true
        );
    } catch (e) {
        return false;
    }
}

function RW_Audit_statusTone(trust) {
    if (trust === 'verified') return 'background:#ecfdf5;color:#047857;';
    if (trust === 'system') return 'background:#eff6ff;color:#1d4ed8;';
    if (trust === 'unverified') return 'background:#fff7ed;color:#c2410c;';
    return 'background:#f8fafc;color:#64748b;';
}

function RW_Audit_actionLabel(action) {
    var map = {
        create: 'إنشاء',
        update: 'تعديل',
        delete: 'حذف',
        login: 'دخول',
        logout: 'خروج',
        failed_login: 'دخول فاشل'
    };
    return map[action] || action || 'غير محدد';
}

function RW_Audit_sourceLabel(source) {
    if (source === 'database_trigger') return 'قاعدة البيانات';
    if (source === 'application_event') return 'حدث تطبيقي';
    if (source === 'legacy') return 'تاريخي';
    return source || 'غير مصنف';
}

function RW_Audit_trustLabel(trust) {
    if (trust === 'verified') return 'موثق';
    if (trust === 'system') return 'نظام';
    if (trust === 'unverified') return 'غير موثق';
    return 'تاريخي';
}

function RW_Audit_formatDate(value) {
    if (!value) return 'غير محدد';
    var d = new Date(value);
    if (isNaN(d.getTime())) return RW_Audit_escape(value);
    try {
        return d.toLocaleString('ar-EG', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit'
        });
    } catch (e) {
        return d.toISOString().replace('T', ' ').slice(0, 19);
    }
}

function RW_Audit_dateValue(value, endOfDay) {
    if (!value) return null;
    var suffix = endOfDay ? 'T23:59:59.999' : 'T00:00:00.000';
    var d = new Date(String(value) + suffix);
    if (isNaN(d.getTime())) return null;
    return d.toISOString();
}

function RW_Audit_filterValue(id) {
    var el = byId(id);
    return el ? String(el.value || '').trim() : '';
}

async function RW_Audit_loadCompanies() {
    if (!RW_Audit_isOwner()) return;
    var select = byId('rw-audit-company');
    if (!select) return;
    try {
        var res = await supabase.from('companies').select('id,name').order('name', { ascending: true });
        if (res.error) throw res.error;
        safeHTML(select,
            '<option value="">كل الشركات</option>' +
            (res.data || []).map(function (c) {
                return '<option value="' + RW_Audit_escape(c.id) + '">' + RW_Audit_escape(c.name || c.id) + '</option>';
            }).join('')
        );
    } catch (e) {
        console.warn('RW_Audit_loadCompanies', e);
    }
}

function RW_Audit_renderTab() {
    var container = byId('rw-page-container');
    if (!container) return;

    safeText(byId('rw-header-title'), 'سجل التدقيق');
    safeText(byId('rw-header-subtitle'), 'مركز رقابي موحد — من يملك حق التغيير، ماذا حدث، وأين ومتى ولماذا');

    if (!RW_Audit_isOwner()) {
        safeHTML(container,
            '<div class="rw-card" style="max-width:760px;margin:50px auto;padding:70px 24px;text-align:center">' +
                '<div style="font-size:64px;margin-bottom:20px">🔒</div>' +
                '<h2 style="font-weight:900;margin-bottom:10px">غير مصرح</h2>' +
                '<p style="color:#64748b;font-weight:700">سجل التدقيق الإداري متاح للمالك فقط.</p>' +
            '</div>'
        );
        return;
    }

    RW_AUDIT_STATE.page = 1;
    RW_AUDIT_STATE.selectedId = null;

    safeHTML(container,
        '<div id="rw-audit-page" style="display:flex;flex-direction:column;gap:22px">' +
            '<section class="rw-card" style="padding:24px">' +
                '<div style="display:flex;justify-content:space-between;align-items:flex-start;gap:18px;flex-wrap:wrap">' +
                    '<div>' +
                        '<div style="font-size:22px;font-weight:900;color:#111827">مركز التدقيق الجنائي</div>' +
                        '<div style="font-size:13px;color:#64748b;font-weight:700;margin-top:5px">السجل السلطوي لتغييرات البيانات وأحداث المصادقة، مع فصل واضح بين الحدث الموثق والتاريخي.</div>' +
                    '</div>' +
                    '<div style="display:flex;gap:10px;flex-wrap:wrap">' +
                        '<button type="button" id="rw-audit-refresh" class="rw-btn-secondary"><i class="fa-solid fa-rotate"></i> تحديث</button>' +
                        '<button type="button" id="rw-audit-export" class="rw-btn-primary"><i class="fa-solid fa-file-export"></i> تصدير CSV</button>' +
                    '</div>' +
                '</div>' +
                '<div id="rw-audit-kpis" style="display:grid;grid-template-columns:repeat(auto-fit,minmax(170px,1fr));gap:12px;margin-top:18px"></div>' +
            '</section>' +
            '<section class="rw-card" style="padding:20px">' +
                '<div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(190px,1fr));gap:12px">' +
                    '<input id="rw-audit-search" class="rw-input" style="height:48px;padding:0 14px;border-radius:14px" placeholder="بحث: مستخدم / جدول / سجل / عملية / قيمة...">' +
                    '<select id="rw-audit-action" class="rw-input" style="height:48px;padding:0 14px;border-radius:14px">' +
                        '<option value="">كل العمليات</option>' +
                        '<option value="create">إنشاء</option>' +
                        '<option value="update">تعديل</option>' +
                        '<option value="delete">حذف</option>' +
                        '<option value="login">دخول</option>' +
                        '<option value="logout">خروج</option>' +
                        '<option value="failed_login">دخول فاشل</option>' +
                    '</select>' +
                    '<input id="rw-audit-table" class="rw-input" style="height:48px;padding:0 14px;border-radius:14px" placeholder="اسم الجدول / الكيان">' +
                    '<input id="rw-audit-actor" class="rw-input" style="height:48px;padding:0 14px;border-radius:14px" placeholder="المنفذ / البريد">' +
                    '<input id="rw-audit-record" class="rw-input" style="height:48px;padding:0 14px;border-radius:14px" placeholder="معرّف السجل"><select id="rw-audit-company" class="rw-input" style="height:48px;padding:0 14px;border-radius:14px"><option value="">كل الشركات</option></select>' +
                    '<input id="rw-audit-from" type="date" class="rw-input" style="height:48px;padding:0 14px;border-radius:14px">' +
                    '<input id="rw-audit-to" type="date" class="rw-input" style="height:48px;padding:0 14px;border-radius:14px">' +
                    '<select id="rw-audit-page-size" class="rw-input" style="height:48px;padding:0 14px;border-radius:14px">' +
                        '<option value="50">50 / صفحة</option>' +
                        '<option value="100">100 / صفحة</option>' +
                        '<option value="200">200 / صفحة</option>' +
                    '</select>' +
                '</div>' +
                '<div style="display:flex;justify-content:flex-end;margin-top:12px">' +
                    '<button type="button" id="rw-audit-clear" class="rw-btn-secondary">مسح الفلاتر</button>' +
                '</div>' +
            '</section>' +
            '<section class="rw-card" style="overflow:hidden">' +
                '<div style="padding:20px 20px 10px;display:flex;justify-content:space-between;gap:12px;align-items:center;flex-wrap:wrap">' +
                    '<div style="font-size:17px;font-weight:900">الحركة المدققة</div>' +
                    '<div id="rw-audit-result-meta" style="font-size:12px;color:#64748b;font-weight:800"></div>' +
                '</div>' +
                '<div style="overflow:auto"><table style="width:100%;border-collapse:separate;border-spacing:0;min-width:1180px">' +
                    '<thead><tr style="background:#f8fafc">' +
                        '<th style="padding:14px;text-align:right;font-size:12px">التاريخ</th>' +
                        '<th style="padding:14px;text-align:right;font-size:12px">المنفذ</th>' +
                        '<th style="padding:14px;text-align:right;font-size:12px">العملية</th>' +
                        '<th style="padding:14px;text-align:right;font-size:12px">المصدر</th>' +
                        '<th style="padding:14px;text-align:right;font-size:12px">الثقة</th>' +
                        '<th style="padding:14px;text-align:right;font-size:12px">الشركة</th>' +
                        '<th style="padding:14px;text-align:right;font-size:12px">الكيان</th>' +
                        '<th style="padding:14px;text-align:right;font-size:12px">السجل</th>' +
                        '<th style="padding:14px;text-align:right;font-size:12px">الحقول المتغيرة</th>' +
                        '<th style="padding:14px;text-align:center;font-size:12px">التفاصيل</th>' +
                    '</tr></thead>' +
                    '<tbody id="rw-audit-tbody"></tbody>' +
                '</table></div>' +
                '<div id="rw-audit-pagination" style="padding:18px"></div>' +
            '</section>' +
            '<section id="rw-audit-detail-card" class="rw-card" style="padding:24px">' +
                '<div style="padding:36px;text-align:center;color:#94a3b8;font-weight:800">اختر سجلًا لعرض التفاصيل الكاملة.</div>' +
            '</section>' +
        '</div>'
    );

    var refresh = byId('rw-audit-refresh');
    if (refresh) refresh.onclick = function () { RW_Audit_loadData(); };
    var exportBtn = byId('rw-audit-export');
    if (exportBtn) exportBtn.onclick = function () { RW_Audit_exportCsv(); };
    var clear = byId('rw-audit-clear');
    if (clear) clear.onclick = function () { RW_Audit_clearFilters(); };
    var pageSize = byId('rw-audit-page-size');
    if (pageSize) pageSize.onchange = function () {
        RW_AUDIT_STATE.pageSize = Number(pageSize.value) || 50;
        RW_AUDIT_STATE.page = 1;
        RW_Audit_loadData();
    };

    ['rw-audit-search', 'rw-audit-action', 'rw-audit-table', 'rw-audit-actor', 'rw-audit-record', 'rw-audit-company', 'rw-audit-from', 'rw-audit-to']
        .forEach(function (id) {
            var el = byId(id);
            if (!el) return;
            el.onkeydown = function (e) {
                if (e.key === 'Enter') {
                    RW_AUDIT_STATE.page = 1;
                    RW_Audit_loadData();
                }
            };
            if (el.tagName === 'SELECT' || el.type === 'date') {
                el.onchange = function () {
                    RW_AUDIT_STATE.page = 1;
                    RW_Audit_loadData();
                };
            }
        });

    RW_Audit_loadCompanies().then(function () {
        RW_Audit_loadData();
    });
}

function RW_Audit_buildParams(page, pageSize) {
    return {
        p_search: RW_Audit_filterValue('rw-audit-search') || null,
        p_action: RW_Audit_filterValue('rw-audit-action') || null,
        p_table_name: RW_Audit_filterValue('rw-audit-table') || null,
        p_actor_email: RW_Audit_filterValue('rw-audit-actor') || null,
        p_record_id: RW_Audit_filterValue('rw-audit-record') || null,
        p_company_id: RW_Audit_filterValue('rw-audit-company') || null,
        p_from: RW_Audit_dateValue(RW_Audit_filterValue('rw-audit-from'), false),
        p_to: RW_Audit_dateValue(RW_Audit_filterValue('rw-audit-to'), true),
        p_page: page || RW_AUDIT_STATE.page,
        p_page_size: pageSize || RW_AUDIT_STATE.pageSize
    };
}

async function RW_Audit_loadData() {
    if (!RW_Audit_isOwner()) return;
    if (RW_AUDIT_STATE.loading) return;
    RW_AUDIT_STATE.loading = true;

    var refresh = byId('rw-audit-refresh');
    if (refresh) refresh.disabled = true;

    try {
        var res = await supabase.rpc('audit_log_query', RW_Audit_buildParams());
        if (res.error) throw res.error;

        var data = res.data || {};
        if (data.success !== true) throw new Error(data.msg || 'فشل تحميل سجل التدقيق');

        RW_AUDIT_STATE.total = Number(data.total || 0);
        RW_AUDIT_STATE.rows = Array.isArray(data.rows) ? data.rows : [];
        RW_AUDIT_STATE.page = Number(data.page || RW_AUDIT_STATE.page || 1);
        RW_AUDIT_STATE.pageSize = Number(data.page_size || RW_AUDIT_STATE.pageSize || 50);

        RW_Audit_renderKpis(data.summary || {}, data.trust_summary || {});
        RW_Audit_renderTable(RW_AUDIT_STATE.rows);
        RW_Audit_renderPagination();

        var meta = byId('rw-audit-result-meta');
        if (meta) {
            var first = RW_AUDIT_STATE.total ? ((RW_AUDIT_STATE.page - 1) * RW_AUDIT_STATE.pageSize + 1) : 0;
            var last = Math.min(RW_AUDIT_STATE.total, RW_AUDIT_STATE.page * RW_AUDIT_STATE.pageSize);
            meta.textContent = first + '–' + last + ' من ' + RW_AUDIT_STATE.total;
        }

        if (RW_AUDIT_STATE.selectedId) {
            var found = RW_AUDIT_STATE.rows.some(function (r) { return r.id === RW_AUDIT_STATE.selectedId; });
            if (found) RW_Audit_showDetails(RW_AUDIT_STATE.selectedId);
        }
    } catch (e) {
        console.error('RW_Audit_loadData', e);
        safeHTML(byId('rw-audit-tbody'),
            '<tr><td colspan="10" style="padding:40px;text-align:center;color:#b91c1c;font-weight:900">تعذر تحميل سجل التدقيق: ' +
            RW_Audit_escape(e.message || e) + '</td></tr>'
        );
    } finally {
        RW_AUDIT_STATE.loading = false;
        if (refresh) refresh.disabled = false;
    }
}

function RW_Audit_renderKpis(summary, trust) {
    var host = byId('rw-audit-kpis');
    if (!host) return;

    var cards = [
        ['إجمالي النتائج', RW_AUDIT_STATE.total, 'fa-list-check'],
        ['إنشاء', Number(summary.create || 0), 'fa-plus'],
        ['تعديل', Number(summary.update || 0), 'fa-pen'],
        ['حذف', Number(summary.delete || 0), 'fa-trash'],
        ['موثق', Number(trust.verified || 0), 'fa-user-check'],
        ['نظام / تاريخي', Number(trust.system || 0) + Number(trust.legacy || 0), 'fa-database']
    ];

    safeHTML(host, cards.map(function (c) {
        return '<div style="padding:15px 16px;border:1px solid #e5e7eb;border-radius:18px;background:#fff">' +
            '<div style="font-size:11px;color:#64748b;font-weight:800;margin-bottom:7px"><i class="fa-solid ' + c[2] + ' ml-1"></i>' + c[0] + '</div>' +
            '<div style="font-size:23px;font-weight:900;color:#111827">' + Number(c[1] || 0).toLocaleString('ar-EG') + '</div>' +
            '</div>';
    }).join(''));
}

function RW_Audit_renderTable(rows) {
    var body = byId('rw-audit-tbody');
    if (!body) return;

    if (!rows.length) {
        safeHTML(body, '<tr><td colspan="10" style="padding:50px;text-align:center;color:#94a3b8;font-weight:800">لا توجد نتائج وفق الفلاتر الحالية.</td></tr>');
        return;
    }

    safeHTML(body, rows.map(function (r) {
        var fields = Array.isArray(r.changed_fields) ? r.changed_fields : [];
        var selected = RW_AUDIT_STATE.selectedId === r.id;

        return '<tr style="border-top:1px solid #eef2f7;background:' + (selected ? '#f8fbff' : '#fff') + '">' +
            '<td style="padding:14px;font-size:12px;font-weight:700;white-space:nowrap">' + RW_Audit_formatDate(r.occurred_at) + '</td>' +
            '<td style="padding:14px;font-size:13px;font-weight:800">' + RW_Audit_escape(r.actor_email || 'غير محدد') + '</td>' +
            '<td style="padding:14px"><span class="rw-status" style="' +
                (r.action === 'delete' ? 'background:#fef2f2;color:#b91c1c;' :
                    r.action === 'update' ? 'background:#eff6ff;color:#1d4ed8;' :
                        'background:#ecfdf5;color:#047857;') + '">' +
                RW_Audit_escape(RW_Audit_actionLabel(r.action)) + '</span></td>' +
            '<td style="padding:14px;font-size:12px;font-weight:800">' + RW_Audit_escape(RW_Audit_sourceLabel(r.source_type)) + '</td>' +
            '<td style="padding:14px"><span class="rw-status" style="' + RW_Audit_statusTone(r.actor_trust) + '">' +
                RW_Audit_escape(RW_Audit_trustLabel(r.actor_trust)) + '</span></td>' +
            '<td style="padding:14px;font-size:12px;font-weight:800">' +
                RW_Audit_escape(r.company_name || r.company_id || 'غير محدد') + '</td>' +
            '<td style="padding:14px;font-size:12px;font-weight:800">' + RW_Audit_escape(r.table_name || 'غير محدد') + '</td>' +
            '<td style="padding:14px;font-size:11px;color:#64748b;max-width:180px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap" title="' +
                RW_Audit_escape(r.record_id || '') + '">' + RW_Audit_escape(r.record_id || '—') + '</td>' +
            '<td style="padding:14px;font-size:12px;font-weight:800">' + Number(fields.length).toLocaleString('ar-EG') + '</td>' +
            '<td style="padding:14px;text-align:center">' +
                '<button type="button" class="rw-btn-secondary rw-audit-open-detail" data-id="' + RW_Audit_escape(r.id) + '">' +
                    '<i class="fa-solid fa-eye"></i> عرض</button></td>' +
            '</tr>';
    }).join(''));

    Array.prototype.forEach.call(document.querySelectorAll('.rw-audit-open-detail'), function (btn) {
        btn.onclick = function () {
            RW_Audit_showDetails(btn.getAttribute('data-id'));
        };
    });
}

function RW_Audit_renderPagination() {
    var host = byId('rw-audit-pagination');
    if (!host) return;

    var totalPages = Math.max(1, Math.ceil(RW_AUDIT_STATE.total / RW_AUDIT_STATE.pageSize));
    var current = RW_AUDIT_STATE.page;
    var pages = [];
    var start = Math.max(1, current - 2);
    var end = Math.min(totalPages, current + 2);

    for (var i = start; i <= end; i++) pages.push(i);

    safeHTML(host,
        '<div style="display:flex;justify-content:center;gap:7px;flex-wrap:wrap;align-items:center">' +
            '<button type="button" class="rw-btn-secondary" ' + (current <= 1 ? 'disabled' : '') + ' id="rw-audit-prev">السابق</button>' +
            pages.map(function (p) {
                return '<button type="button" class="rw-btn-secondary rw-audit-page-btn" style="min-width:40px;' +
                    (p === current ? 'background:#2563eb;color:#fff;border-color:#2563eb;' : '') +
                    '" data-page="' + p + '">' + p + '</button>';
            }).join('') +
            '<button type="button" class="rw-btn-secondary" ' + (current >= totalPages ? 'disabled' : '') + ' id="rw-audit-next">التالي</button>' +
            '<span style="font-size:12px;color:#64748b;font-weight:800;margin-right:8px">صفحة ' + current + ' من ' + totalPages + '</span>' +
        '</div>'
    );

    var prev = byId('rw-audit-prev');
    if (prev) prev.onclick = function () { RW_Audit_goPage(current - 1); };

    var next = byId('rw-audit-next');
    if (next) next.onclick = function () { RW_Audit_goPage(current + 1); };

    Array.prototype.forEach.call(host.querySelectorAll('[data-page]'), function (btn) {
        btn.onclick = function () {
            RW_Audit_goPage(Number(btn.getAttribute('data-page')));
        };
    });
}

function RW_Audit_goPage(page) {
    var totalPages = Math.max(1, Math.ceil(RW_AUDIT_STATE.total / RW_AUDIT_STATE.pageSize));
    if (page < 1 || page > totalPages) return;
    RW_AUDIT_STATE.page = page;
    RW_Audit_loadData();
}

function RW_Audit_clearFilters() {
    ['rw-audit-search', 'rw-audit-action', 'rw-audit-table', 'rw-audit-actor', 'rw-audit-record', 'rw-audit-company', 'rw-audit-from', 'rw-audit-to'].forEach(function (id) {
        var el = byId(id);
        if (el) el.value = '';
    });

    RW_AUDIT_STATE.page = 1;
    RW_Audit_loadData();
}

async function RW_Audit_showDetails(auditId) {
    if (!RW_Audit_isOwner() || !auditId) return;

    var host = byId('rw-audit-detail-card');
    if (!host) return;

    RW_AUDIT_STATE.selectedId = auditId;
    RW_Audit_renderTable(RW_AUDIT_STATE.rows);

    safeHTML(host,
        '<div style="padding:40px;text-align:center;color:#64748b;font-weight:800">' +
            '<i class="fa-solid fa-spinner fa-spin"></i> جاري تحميل التفاصيل...</div>'
    );

    try {
        var res = await supabase.rpc('audit_log_detail', { p_audit_id: auditId });
        if (res.error) throw res.error;

        var data = res.data || {};
        if (data.success !== true || !data.row) {
            throw new Error(data.msg || 'تعذر قراءة سجل التدقيق');
        }

        var r = data.row;
        var fields = Array.isArray(r.changed_fields) ? r.changed_fields : [];
        var oldData = r.old_data || null;
        var newData = r.new_data || null;
        var diffFields = [];
        var keys = {};

        if (oldData && typeof oldData === 'object') {
            Object.keys(oldData).forEach(function (k) { keys[k] = true; });
        }
        if (newData && typeof newData === 'object') {
            Object.keys(newData).forEach(function (k) { keys[k] = true; });
        }

        Object.keys(keys).sort().forEach(function (k) {
            var ov = oldData && Object.prototype.hasOwnProperty.call(oldData, k) ? oldData[k] : undefined;
            var nv = newData && Object.prototype.hasOwnProperty.call(newData, k) ? newData[k] : undefined;

            if (JSON.stringify(ov) !== JSON.stringify(nv)) {
                diffFields.push([k, ov, nv]);
            }
        });

        var changedRows = diffFields.map(function (x) {
            var oldText = x[1] === undefined ? '—' : JSON.stringify(x[1], null, 2);
            var newText = x[2] === undefined ? '—' : JSON.stringify(x[2], null, 2);

            return '<tr>' +
                '<td style="padding:12px;font-weight:900;vertical-align:top">' + RW_Audit_escape(x[0]) + '</td>' +
                '<td style="padding:12px;white-space:pre-wrap;word-break:break-word;color:#b91c1c">' + RW_Audit_escape(oldText) + '</td>' +
                '<td style="padding:12px;white-space:pre-wrap;word-break:break-word;color:#047857">' + RW_Audit_escape(newText) + '</td>' +
            '</tr>';
        }).join('');

        var cards = [
            ['التاريخ', RW_Audit_formatDate(r.occurred_at)],
            ['المنفذ', r.actor_email || 'غير محدد'],
            ['العملية', RW_Audit_actionLabel(r.action)],
            ['المصدر', RW_Audit_sourceLabel(r.source_type)],
            ['الشركة', r.company_name || r.company_id || 'غير محدد'],
            ['الكيان', r.table_name || 'غير محدد'],
            ['السجل', r.record_id || '—'],
            ['Operation ID', r.operation_id || '—']
        ];

        safeHTML(host,
            '<div style="display:flex;justify-content:space-between;align-items:flex-start;gap:15px;flex-wrap:wrap;margin-bottom:20px">' +
                '<div><div style="font-size:19px;font-weight:900">تفاصيل السجل</div>' +
                '<div style="font-size:12px;color:#64748b;font-weight:700;margin-top:4px">التفاصيل داخل الصفحة، ومصدرها Read Model التدقيقي في Production.</div></div>' +
                '<span class="rw-status" style="' + RW_Audit_statusTone(r.actor_trust) + '">' +
                    RW_Audit_escape(RW_Audit_trustLabel(r.actor_trust)) + '</span>' +
            '</div>' +

            '<div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(210px,1fr));gap:12px;margin-bottom:18px">' +
                cards.map(function (x) {
                    return '<div style="padding:14px;border:1px solid #e5e7eb;border-radius:16px;background:#f8fafc">' +
                        '<div style="font-size:10px;color:#64748b;font-weight:800;margin-bottom:5px">' + RW_Audit_escape(x[0]) + '</div>' +
                        '<div style="font-size:13px;font-weight:900;word-break:break-word">' + RW_Audit_escape(x[1]) + '</div>' +
                    '</div>';
                }).join('') +
            '</div>' +

            '<div style="margin-bottom:18px;padding:14px;border:1px solid #e5e7eb;border-radius:16px;background:#fff">' +
                '<div style="font-size:13px;font-weight:900;margin-bottom:8px">الحقول التي تغيّرت (' +
                    Number(fields.length || diffFields.length) + ')</div>' +
                '<div style="display:flex;gap:7px;flex-wrap:wrap">' +
                    (fields.length ?
                        fields.map(function (f) {
                            return '<span class="rw-status" style="background:#eff6ff;color:#1d4ed8">' +
                                RW_Audit_escape(f) + '</span>';
                        }).join('') :
                        '<span style="color:#94a3b8;font-weight:800">لا توجد قائمة حقول مسجلة لهذا السجل.</span>') +
                '</div>' +
            '</div>' +

            '<div style="overflow:auto;border:1px solid #e5e7eb;border-radius:16px">' +
                '<table style="width:100%;border-collapse:collapse;min-width:760px">' +
                    '<thead><tr style="background:#f8fafc">' +
                        '<th style="padding:12px;text-align:right">الحقل</th>' +
                        '<th style="padding:12px;text-align:right">قبل</th>' +
                        '<th style="padding:12px;text-align:right">بعد</th>' +
                    '</tr></thead>' +
                    '<tbody>' +
                        (changedRows ||
                            '<tr><td colspan="3" style="padding:30px;text-align:center;color:#94a3b8;font-weight:800">لا يوجد فرق حقلي قابل للعرض.</td></tr>') +
                    '</tbody>' +
                '</table>' +
            '</div>' +

            '<div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:12px;margin-top:18px">' +
                '<div style="padding:14px;border:1px solid #e5e7eb;border-radius:16px">' +
                    '<div style="font-size:10px;color:#64748b;font-weight:800;margin-bottom:6px">IP</div>' +
                    '<div style="font-size:13px;font-weight:800;word-break:break-word">' + RW_Audit_escape(r.ip_address || 'غير مسجل') + '</div>' +
                '</div>' +
                '<div style="padding:14px;border:1px solid #e5e7eb;border-radius:16px">' +
                    '<div style="font-size:10px;color:#64748b;font-weight:800;margin-bottom:6px">User Agent</div>' +
                    '<div style="font-size:12px;font-weight:700;word-break:break-word;color:#475569">' + RW_Audit_escape(r.user_agent || 'غير مسجل') + '</div>' +
                '</div>' +
            '</div>' +

            '<div style="margin-top:18px;color:#94a3b8;font-size:11px;font-weight:800">' +
                'القيم الحساسة (مثل token/password/secret) تُحجب في Read Model.' +
            '</div>'
        );
    } catch (e) {
        console.error('RW_Audit_showDetails', e);
        safeHTML(host,
            '<div style="padding:36px;text-align:center;color:#b91c1c;font-weight:900">تعذر تحميل التفاصيل: ' +
            RW_Audit_escape(e.message || e) + '</div>'
        );
    }
}

async function RW_Audit_exportCsv() {
    if (!RW_Audit_isOwner()) return;

    try {
        showLoader('جاري تجهيز التصدير...');

        var res = await supabase.rpc('audit_log_query', RW_Audit_buildParams(1, 5000));
        if (res.error) throw res.error;

        var data = res.data || {};
        if (data.success !== true) throw new Error(data.msg || 'فشل تجهيز التصدير');

        var rows = Array.isArray(data.rows) ? data.rows : [];
        var csvRows = [[
            'occurred_at',
            'actor_email',
            'action',
            'source_type',
            'actor_trust',
            'company',
            'table_name',
            'record_id',
            'operation_id',
            'changed_fields'
        ]];

        rows.forEach(function (r) {
            csvRows.push([
                r.occurred_at || '',
                r.actor_email || '',
                r.action || '',
                r.source_type || '',
                r.actor_trust || '',
                r.company_name || r.company_id || '',
                r.table_name || '',
                r.record_id || '',
                r.operation_id || '',
                Array.isArray(r.changed_fields) ? r.changed_fields.join('|') : ''
            ]);
        });

        var csv = csvRows.map(function (row) {
            return row.map(function (v) {
                return '"' + String(v == null ? '' : v).replace(/"/g, '""') + '"';
            }).join(',');
        }).join('\r\n');

        var blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8;' });
        var url = URL.createObjectURL(blob);
        var a = document.createElement('a');

        a.href = url;
        a.download = 'rawaea-audit-log-' + new Date().toISOString().slice(0, 10) + '.csv';

        document.body.appendChild(a);
        a.click();
        a.remove();
        URL.revokeObjectURL(url);
    } catch (e) {
        console.error('RW_Audit_exportCsv', e);
        showToast(e.message || 'فشل التصدير', 'error');
    } finally {
        hideLoader();
    }
}
```

### ملاحظة جراحية

لا تعدل:

- route `audit-log`
- permission map `audit-log: owner`
- menu registration
- `RW_Views`
- أي كود تشغيلي آخر.

الـroute الموجود أصلًا يكفي لأن Audit كان Page بالفعل؛ التحويل المطلوب هنا هو:

**Modal Detail → In-Page Detail**

وليس Route migration.

---

# 13. ما لم يُلمس

لم يتم تعديل:

- POS
- Telesales
- Order Taker
- Van Sales
- Picker
- Loader
- Delivery
- Returns
- Purchasing
- Runsheet
- Inventory
- Counting
- Financial writers
- CRM
- HR
- Owner License
- System Settings
- Roles / Users
- Comprehensive Reports
- Main Router

---

# 14. Production Verification

تم التحقق من:

## Read API

Owner JWT context:

**PASS**

`audit_log_query`

- success = true
- total = 2015
- rows returned = 5 في اختبار الصفحة
- trust_summary = present
- changed_fields = present

## Detail API

`audit_log_detail`

- success = true
- owner guard = pass
- actor_trust = verified في السجل المختبر
- source_type = legacy في التاريخ القديم عند عدم وجود source classification.

## Redaction

`audit_log_redact_jsonb`

تم تشغيله على Read Model؛ old/new أصبحا يمران عبر redaction قبل خروج التفاصيل.

## Direct access boundary

- anon SELECT = false
- authenticated INSERT = false
- service_role INSERT = true
- service_role DELETE = false

## Deployment

`log-action`

- version 5
- ACTIVE
- verify_jwt = true

---

# 15. E2E Status

## Backend / Database E2E

**PASS**

تم إثبات:

JWT
↓
Owner capability
↓
audit_log_query
↓
audit_log_detail
↓
redaction
↓
structured response

## Mother Source Static Surgery

Patch A:
**PASS — مستقل Syntax Check**

Patch B:
**PASS — مستقل Syntax Check**

## Browser E2E

**OPEN**

السبب الوحيد:

المستخدم منع CTO من الكتابة في `main.html`.

وبالتالي لم يتم الادعاء بأن Browser E2E Production PASS قبل Owner Source Cutover.

---

# 16. SELF-AUDIT

## What I Proved

- Audit route موجود.
- Audit permission موجود.
- Audit الحالي كان Page بالفعل.
- Detail فقط كان Modal.
- Database audit triggers هي المصدر السلطوي لتغييرات الصفوف.
- Client helper كان يسبب ازدواجية.
- audit_log كان يفتقد normalized actor/company/source/operation identity.
- Production تحتوي تاريخًا كبيرًا legacy.
- 246 سجلًا تاريخيًا يحتوي token في JSON الخام.
- Production Read Model الجديد يعمل.
- Owner-only query/detail يعمل.
- Redaction يعمل.
- log-action الجديد لا يكتب row-change events.
- لا يوجد Production Physical Stock أو operational contract touch.
- Mother main.html لم يتم تعديله.

## What I Did Not Prove

- Browser visual E2E بعد تطبيق Patch على Mother.
- Browser click flow في الصفحة الجديدة.
- Export click من المتصفح بعد Owner cutover.
- Record-level navigation إلى كل module لأن هذه الروابط غير موجودة كعقد موحد في current Audit schema.
- Historical source classification لكل `system` row؛ لا توجد قرينة كافية لإعادة نسبتها.

## What I Fixed

- Audit data identity.
- Audit read contract.
- Sensitive data exposure at detail response.
- Duplicate client row-change audit writer.
- Audit Gateway surface.
- Modal dependency.
- Filtering/read scalability contract.
- Changed-field visibility.

## What I Initially Missed

- ضرورة التمييز بين database-authoritative events وapplication authentication events.
- ضرورة redaction على مستوى Read Model وليس UI فقط.

تم تصحيح ذلك قبل اعتماد الإغلاق.

## What Could Still Be Wrong

- UI cutover قد يحتوي اختلافًا بصريًا عن بقية Mother لم يظهر إلا في Browser.
- قد توجد consumer legacy غير ظاهرة في current searchable source وتحتاج revalidation عند Browser.
- بعض historical audit entries ستظل Legacy عمدًا لأنها لا تحمل قرينة كافية لإعادة بناء المصدر.

هذه ليست مفاجآت متوقعة في Production contract، لكنها تمنع ادعاء Browser 100%.

---

# 17. Production Closure Status

**AUDIT BACKEND CONTRACT = CLOSED**

**AUDIT READ MODEL = CLOSED**

**AUDIT DATA IDENTITY = CLOSED**

**AUDIT REDACTION = CLOSED**

**AUDIT DUPLICATE WRITE PATH = CLOSED / BACKWARD COMPATIBLE**

**AUDIT PRODUCTION DEPLOYMENT = CLOSED**

**MOTHER SURGICAL SOURCE PATCH = READY**

**MOTHER main.html = NOT TOUCHED BY CTO**

**BROWSER PRODUCTION E2E = OPEN UNTIL OWNER APPLIES PATCH**

**FULL AUDIT TAB 100% CLOSURE = OPEN ONLY FOR OWNER CUTOVER + BROWSER E2E**

---

# 18. Exact next-session sequence

1. Verify System HEAD and parent.
2. Verify Mother HEAD and `main.html` blob.
3. Confirm Patch A and Patch B were applied literally and nowhere else.
4. Run JavaScript parser gate on assembled Mother source.
5. Run Browser Production E2E as Owner.
6. Open Audit page.
7. Verify KPI counts.
8. Verify search.
9. Verify action filter.
10. Verify table filter.
11. Verify actor filter.
12. Verify date range.
13. Verify pagination.
14. Click تفاصيل.
15. Confirm no Modal opens.
16. Verify old/new redaction.
17. Verify Operation ID.
18. Verify source/trust badges.
19. Export CSV.
20. Verify no raw token/password appears in CSV.
21. Re-read Production audit_log.
22. Verify new mutation produces one DB-trigger record only.
23. Verify login/logout event produces application_event.
24. Verify legacy create/update/delete calls are ignored by log-action.
25. Update CURRENT_STATE.
26. Mark Audit 100% CLOSED.

---

# 19. Continuity Rule

لا تعاد هذه الجراحة من الصفر.

الحالة المستقبلية تبدأ من:

- Production Audit Read Model الحالي.
- `audit_log_query`
- `audit_log_detail`
- `audit_log_redact_jsonb`
- `fn_audit_trigger`
- `log-action v5`
- Patch A
- Patch B

ولا يُعاد إصلاح أي عنصر من هذه العناصر إلا إذا ظهرت Regression جديدة مثبتة من:

**CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT**

