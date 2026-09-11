# RAWAEA ERP — OWNER SOURCE CHANGE SET
## MAIN1 — R2 — 2026-09-11

## حالة الوثيقة
هذه الوثيقة هي الإصدار النشط من تعليمات التعديل الجراحي لملف:
`Current/PWA/main2/main1.md`

ملف Main1 الحالي لم يتم تعديله مباشرة لأن نطاق `Current/PWA/main2/main1.md ... main11.md` من اختصاص المالك وفق MASTER CTO GOVERNANCE.

الـR1 السابق `OWNER_CHANGESETS_20260911_MAIN1.md` أصبح **SUPERSEDED / STALE** بالنسبة إلى المصدر الحالي، لأنه بُني على SHA قديم `4d1b42250cfe2b3a8ec7d02b7b482eca8e27bade` بينما المصدر الحالي أصبح `eda2319c13084e351a21061b74cebc235478a6e5`، كما أن إصلاحات Finance/CRM/HR التي وصفها R1 أصبحت موجودة بالفعل في المصدر الحالي.

---

# 1. SOURCE IDENTITY

- File: `Current/PWA/main2/main1.md`
- Current SHA: `eda2319c13084e351a21061b74cebc235478a6e5`
- Current EOF: تم تجاوز السطر 1049 دون محتوى، وبالتالي EOF الحالي قبل/عند هذه الحدود.
- Historical original: `Original/PWA/main/main1.md`
- Original SHA: `14b12a471c20ad23a2c18f456dbc4d59783a0d1f`
- Governing Master SHA: `b03feec14a417ca9032d714774f2687b4542a373`

---

# 2. WHAT IS ALREADY CORRECT — DO NOT REAPPLY

المصدر الحالي يحتوي بالفعل على:

```javascript
{ action: 'showFinanceTab', arg: 'treasury', label: 'الخزائن والبنوك', perm: ['finance', 'finance_manager'] }
{ action: 'showFinanceTab', arg: 'accounts', label: 'دليل الحسابات', perm: ['finance', 'finance_manager'] }
{ action: 'showFinanceTab', arg: 'journal', label: 'قيود يومية', perm: ['finance', 'finance_manager'] }
{ action: 'showFinanceTab', arg: 'receipts', label: 'سندات القبض', perm: ['finance', 'finance_manager'] }
{ action: 'showFinanceTab', arg: 'payments', label: 'سندات الصرف', perm: ['finance', 'finance_manager'] }
{ action: 'showFinanceTab', arg: 'transfers', label: 'التحويلات', perm: ['finance', 'finance_manager'] }
{ action: 'showFinanceTab', arg: 'reports', label: 'التقارير المالية', perm: ['finance', 'finance_manager'] }
```

ومعها:

```javascript
{ view: 'hr', icon: 'fa-id-card', label: 'الموارد البشرية', perm: 'hr' }
{ view: 'crm', icon: 'fa-handshake', label: 'إدارة علاقات العملاء (CRM)', perm: 'customers' }
```

كما أن `isAllowed(item)` الحالي يدعم `perm` النصي و`perm` كمصفوفة OR و`view` fallback.

**لا تعدل هذه الأجزاء مرة أخرى إلا إذا تغير العقد بعد دليل جديد.**

---

# 3. MAIN1-E — AUDIT TABLE STORED-XSS / UNSAFE HTML SINK

## Exact function to locate
ابحث عن الدالة كاملة بالنص التالي:

```javascript
function RW_Audit_renderTable(data) {
```

ولا تعتمد على رقم السطر وحده.

## Exact current defective behavior
الدالة الحالية تبني `html` كنص ثم تدخل مباشرة إلى `safeHTML()`، وتضع داخل HTML قيمًا قادمة من `audit_log` دون escaping:

- `log.user_email`
- `log.action`
- `log.table_name`
- `log.record_id`
- `dateStr`

وبالتالي فإن بيانات Audit غير الموثوقة تدخل إلى `innerHTML`.

## Full replacement
احذف الدالة الحالية كاملة واستبدلها بالدالة التالية:

```javascript
function RW_Audit_renderTable(data) {
    var container = byId('audit-table-container');
    if (!container) return;

    if (!data || data.length === 0) {
        safeHTML(container, '<div class="text-center py-10 text-gray-400">لا توجد سجلات</div>');
        return;
    }

    var table = document.createElement('table');
    table.className = 'w-full text-sm';

    var thead = document.createElement('thead');
    thead.className = 'bg-gray-50 sticky top-0';
    var headRow = document.createElement('tr');

    var headers = ['التاريخ', 'المستخدم', 'الإجراء', 'الجدول', 'رقم السجل', 'تفاصيل'];
    for (var h = 0; h < headers.length; h++) {
        var th = document.createElement('th');
        th.className = 'p-2' + (h === 5 ? ' text-center' : '');
        th.textContent = headers[h];
        headRow.appendChild(th);
    }
    thead.appendChild(headRow);
    table.appendChild(thead);

    var tbody = document.createElement('tbody');

    for (var i = 0; i < data.length; i++) {
        var log = data[i] || {};
        var tr = document.createElement('tr');
        tr.className = 'border-t hover:bg-gray-50';

        var dateCell = document.createElement('td');
        dateCell.className = 'p-2 text-xs';
        dateCell.textContent = log.created_at ? new Date(log.created_at).toLocaleString('ar-EG') : '';

        var userCell = document.createElement('td');
        userCell.className = 'p-2';
        userCell.textContent = log.user_email || '';

        var actionCell = document.createElement('td');
        actionCell.className = 'p-2';
        var actionLabel = log.action === 'create' ? 'إنشاء' :
            log.action === 'update' ? 'تعديل' :
            log.action === 'delete' ? 'حذف' :
            log.action === 'login' ? 'دخول' :
            log.action === 'logout' ? 'خروج' :
            String(log.action || '');
        actionCell.textContent = actionLabel;

        var tableCell = document.createElement('td');
        tableCell.className = 'p-2';
        tableCell.textContent = log.table_name || '-';

        var recordCell = document.createElement('td');
        recordCell.className = 'p-2 text-xs';
        var recordId = String(log.record_id || '');
        recordCell.textContent = recordId ? recordId.substring(0, 8) + '...' : '-';

        var detailCell = document.createElement('td');
        detailCell.className = 'p-2 text-center';
        var detailButton = document.createElement('button');
        detailButton.className = 'text-blue-600';
        detailButton.type = 'button';
        detailButton.title = 'عرض التفاصيل';
        detailButton.innerHTML = '<i class="fa-solid fa-eye" aria-hidden="true"></i>';
        detailButton.addEventListener('click', (function(id) {
            return function(e) {
                e.stopPropagation();
                RW_Audit_showDetails(id);
            };
        })(log.id));
        detailCell.appendChild(detailButton);

        tr.appendChild(dateCell);
        tr.appendChild(userCell);
        tr.appendChild(actionCell);
        tr.appendChild(tableCell);
        tr.appendChild(recordCell);
        tr.appendChild(detailCell);
        tbody.appendChild(tr);
    }

    table.appendChild(tbody);

    safeHTML(container, '');
    container.appendChild(table);
    RW_Audit_renderPagination();
}
```

## Responsibility preserved
- نفس الـpagination.
- نفس الـaction labels.
- نفس فتح التفاصيل.
- لا يوجد تغيير في مصدر البيانات.
- لا يوجد تغيير في RLS أو Audit contract.
- تم نقل القيم غير الموثوقة إلى `textContent` بدل `innerHTML`.

---

# 4. MAIN1-F — AUDIT DETAILS STORED-XSS / SWEETALERT HTML SINK

## Exact function to locate
ابحث عن:

```javascript
function RW_Audit_showDetails(logId) {
```

## Full replacement
احذف الدالة الحالية كاملة واستبدلها بـ:

```javascript
function RW_Audit_showDetails(logId) {
    var log = null;
    for (var i = 0; i < RW_AUDIT_DATA.length; i++) {
        if (RW_AUDIT_DATA[i].id === logId) {
            log = RW_AUDIT_DATA[i];
            break;
        }
    }

    if (!log) return;

    function text(value, fallback) {
        return value === null || value === undefined || value === '' ? (fallback || '') : String(value);
    }

    var wrapper = document.createElement('div');
    wrapper.className = 'text-right text-sm';

    var pUser = document.createElement('p');
    var bUser = document.createElement('b');
    bUser.textContent = 'المستخدم: ';
    pUser.appendChild(bUser);
    pUser.appendChild(document.createTextNode(text(log.user_email)));

    var pAction = document.createElement('p');
    var bAction = document.createElement('b');
    bAction.textContent = 'الإجراء: ';
    pAction.appendChild(bAction);
    pAction.appendChild(document.createTextNode(text(log.action)));

    var pTable = document.createElement('p');
    var bTable = document.createElement('b');
    bTable.textContent = 'الجدول: ';
    pTable.appendChild(bTable);
    pTable.appendChild(document.createTextNode(text(log.table_name, '-')));

    var pRecord = document.createElement('p');
    var bRecord = document.createElement('b');
    bRecord.textContent = 'رقم السجل: ';
    pRecord.appendChild(bRecord);
    pRecord.appendChild(document.createTextNode(text(log.record_id, '-')));

    var pDate = document.createElement('p');
    var bDate = document.createElement('b');
    bDate.textContent = 'التاريخ: ';
    pDate.appendChild(bDate);
    pDate.appendChild(document.createTextNode(log.created_at ? new Date(log.created_at).toLocaleString('ar-EG') : ''));

    var oldTitle = document.createElement('b');
    oldTitle.textContent = 'البيانات القديمة:';
    var oldPre = document.createElement('pre');
    oldPre.className = 'bg-gray-100 p-2 rounded-lg mt-1 text-xs overflow-auto max-h-32';
    oldPre.textContent = log.old_data ? JSON.stringify(log.old_data, null, 2) : 'لا يوجد';
    var oldWrap = document.createElement('div');
    oldWrap.className = 'mt-4';
    oldWrap.appendChild(oldTitle);
    oldWrap.appendChild(oldPre);

    var newTitle = document.createElement('b');
    newTitle.textContent = 'البيانات الجديدة:';
    var newPre = document.createElement('pre');
    newPre.className = 'bg-gray-100 p-2 rounded-lg mt-1 text-xs overflow-auto max-h-32';
    newPre.textContent = log.new_data ? JSON.stringify(log.new_data, null, 2) : 'لا يوجد';
    var newWrap = document.createElement('div');
    newWrap.className = 'mt-2';
    newWrap.appendChild(newTitle);
    newWrap.appendChild(newPre);

    wrapper.appendChild(pUser);
    wrapper.appendChild(pAction);
    wrapper.appendChild(pTable);
    wrapper.appendChild(pRecord);
    wrapper.appendChild(pDate);
    wrapper.appendChild(oldWrap);
    wrapper.appendChild(newWrap);

    Swal.fire({
        title: 'تفاصيل سجل التدقيق',
        html: wrapper.outerHTML,
        width: '800px',
        showCloseButton: true,
        showConfirmButton: false
    });
}
```

## Note
لا توجد هنا ثقة مطلقة في `outerHTML` كمبدأ عام؛ كل النصوص الديناميكية تم إدخالها أصلًا عبر `textContent`, لذلك لا يوجد markup صادر من البيانات نفسها. لا تعيد إدخال `oldDataText` أو `newDataText` كنص داخل HTML string.

---

# 5. MAIN1-G — NOTIFICATION PANEL STORED-XSS / UNSAFE HTML SINK

## Exact function to locate
ابحث عن:

```javascript
function showPanel() {
```

داخل:

```javascript
var RW_Notification = (function() {
```

## Full replacement
استبدل الدالة الحالية كاملة بالدالة التالية:

```javascript
function showPanel() {
    var email = RW_STATE.app.currentUser ? RW_STATE.app.currentUser.email : null;
    if (!email) return;

    supabase.from('notifications')
        .select('*')
        .eq('user_email', email)
        .order('created_at', { ascending: false })
        .limit(50)
        .then(function(res) {
            var notifs = res.data || [];

            var root = document.createElement('div');
            root.dir = 'rtl';
            root.style.width = '420px';
            root.style.maxHeight = '500px';
            root.style.overflowY = 'auto';

            var header = document.createElement('div');
            header.style.cssText = 'padding:16px 20px;border-bottom:1px solid #e5e7eb;display:flex;justify-content:space-between;align-items:center;';

            var title = document.createElement('h3');
            title.style.cssText = 'font-size:16px;font-weight:900;color:#111827;';
            title.textContent = 'الإشعارات';
            header.appendChild(title);

            if (notifs.length > 0) {
                var markAll = document.createElement('button');
                markAll.type = 'button';
                markAll.style.cssText = 'font-size:12px;color:#2563eb;font-weight:700;background:none;border:none;cursor:pointer;';
                markAll.textContent = 'قراءة الكل';
                markAll.addEventListener('click', function(e) {
                    e.stopPropagation();
                    RW_Notification.markAllRead();
                });
                header.appendChild(markAll);
            }

            root.appendChild(header);

            if (!notifs.length) {
                var empty = document.createElement('div');
                empty.style.cssText = 'padding:40px 20px;text-align:center;color:#9ca3af;';
                empty.textContent = 'لا توجد إشعارات';
                root.appendChild(empty);
            } else {
                for (var n = 0; n < notifs.length; n++) {
                    var notif = notifs[n] || {};
                    var row = document.createElement('div');
                    row.style.cssText = 'padding:12px 20px;border-bottom:1px solid #f1f5f9;cursor:pointer;' +
                        (notif.is_read ? 'background:white;' : 'background:#eff6ff;');

                    var notifTitle = document.createElement('div');
                    notifTitle.style.cssText = 'font-size:13px;font-weight:800;color:#111827;';
                    notifTitle.textContent = notif.title || '';
                    row.appendChild(notifTitle);

                    if (notif.body) {
                        var notifBody = document.createElement('div');
                        notifBody.style.cssText = 'font-size:12px;color:#6b7280;margin-top:4px;';
                        notifBody.textContent = notif.body;
                        row.appendChild(notifBody);
                    }

                    row.addEventListener('click', (function(id, refTable, refId) {
                        return function(e) {
                            e.stopPropagation();
                            RW_Notification._clickNotif(id, refTable, refId);
                        };
                    })(notif.id, String(notif.reference_table || ''), String(notif.reference_id || '')));

                    root.appendChild(row);
                }
            }

            Swal.fire({
                html: root.outerHTML,
                showConfirmButton: false,
                showCloseButton: true,
                width: 600,
                padding: 0,
                customClass: { popup: 'rounded-2xl overflow-hidden' }
            });
        })
        .catch(function(e) {
            console.warn('Notification panel load error:', e);
        });
}
```

## Important runtime note
هذه الدالة تستخدم DOM construction للقيم غير الموثوقة. لا تعيد `notif.title` أو `notif.body` أو `reference_*` إلى HTML template string.

---

# 6. MAIN1-WF — WORKFLOW FALSE-SUCCESS / INCOMPLETE EXECUTOR

## Exact function

```javascript
function evaluate(tableName, event, recordId, recordData) {
```

داخل `RW_Workflow`.

## Proven defect
الدالة الحالية:
- تبني `executed` بعناصر حالة `pending`.
- لا تنفذ أي Action.
- تكتب `status: 'success'`.
- تخفي الفشل داخل `.catch(function() {})`.

وفي Production توجد 3 Workflow Rules حقيقية:
- `update_inventory`
- `create_journal_entry`
- `create_stock_voucher`

لكن لم يتم إثبات Executor/parameter contract لهذه الـActions من Main1 وحده.

## Mandatory handling
**ممنوع إعطاء Full Replacement تخميني لهذه الدالة الآن.**

المطلوب في الـclosure التالي:

1. Search Current Main2–Main11 for exact strings:
   - `update_inventory`
   - `create_journal_entry`
   - `create_stock_voucher`
2. Search Supabase Production functions / Edge Functions for the same exact action names or workflow dispatchers.
3. Identify actual executor, parameter shape, authorization, transaction boundary, retry/idempotency, and error contract.
4. Reconstruct the actual business responsibility for each action.
5. Only then replace `evaluate()` with a complete executor or explicit dispatcher using the proven contract.
6. Test success, failure, retry, and no-false-success.
7. Verify Production runtime and `workflow_log` records.

## Current status
`ROOT CAUSE PROVEN`
`FIX NOT SAFE TO INVENT`
`ACTIVE INVESTIGATION`
`NOT A BLOCKER`

---

# 7. MAIN1 CLOSURE GATE

لا تعتبر Main1 Fully Closed الآن.

Current classification:

```text
MASTER READ = CLOSED
CURRENT MAIN1 FULL READ = CLOSED
PRODUCTION REFRESH = CLOSED
MAIN1-A FINANCE = ALREADY PRESENT IN CURRENT SOURCE
MAIN1-B CRM = ALREADY PRESENT IN CURRENT SOURCE
MAIN1-C HR = ALREADY PRESENT IN CURRENT SOURCE
MAIN1-E AUDIT TABLE = SURGERY READY
MAIN1-F AUDIT DETAILS = SURGERY READY
MAIN1-G NOTIFICATIONS = SURGERY READY
MAIN1-WF WORKFLOW = ROOT CAUSE PROVEN / EXECUTOR DISCOVERY OPEN
MAIN1 FUNCTIONAL CLOSURE = OPEN
GLOBAL GOLD/DIAMOND = OPEN
```

---

# 8. VERIFICATION AFTER OWNER MERGE

بعد دمج owner surgery:

1. Re-read Main1 from start through EOF.
2. Verify new SHA.
3. Audit table renders DB-controlled text literally; `<img>`, `<script>`, quotes, and markup never execute/render as HTML.
4. Audit detail old/new JSON renders as text only.
5. Notification title/body renders as text only.
6. Finance permissions remain correct for Accountant / Finance Manager / Owner.
7. CRM remains mapped to `customers`.
8. HR remains mapped to `hr`.
9. Settlement remains governed by its own capability.
10. Workflow executor is separately closed only after proven action contract.
11. No duplicate router/state source introduced.
12. No original file modified.

---

# 9. OWNER MERGE RULE

لا تعدل:
`Original/PWA/main/main1.md`

ولا تطبق R1 القديم.

نفذ R2 فقط على:
`Current/PWA/main2/main1.md`

ثم أعد قراءة الملف من البداية إلى EOF قبل أي دعوى إغلاق.
