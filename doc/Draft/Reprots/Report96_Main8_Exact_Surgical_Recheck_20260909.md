# Report96 — Main8 Exact Surgical Re-check — 2026-09-09

## 1. الهدف الحاكم
هناك نقص شديد في التبويبات القادمة التابعة للإدارة المالية وإدارة الموارد البشرية وCRM والتقارير، وكثير منها هيكلي فقط. الهدف العام للمشروع هو استكمال هذا النقص للوصول إلى ERP منافس فعليًا للأنظمة المنافسة مثل Odoo وDynamics وSAP وDaftra وManager.io وغيرها.

هذا الهدف محفوظ كهدف Gold/Diamond للمشروع، لكن هذه الجلسة مخصصة لإغلاق الجراحة الدقيقة المتبقية في Main8 دون خلطها بمرحلة إضافة الوحدات الجديدة.

## 2. منهج التحقيق
تم اتباع قاعدة الحوكمة:
READ → VERIFY → RECONCILE → UNDERSTAND → PATCH DECISION → VERIFY → DOCUMENT → UPDATE CURRENT_STATE.

تمت مراجعة:
- MASTER - RAWAEA ERP.md
- MASTER - RAWAEA ERP FORENSIC CONTINUITY GOVERNANCE v2.md
- MASTER - RAWAEA ERP - UNIFIED CONTINUITY & MAIN1 EXECUTION.md
- تقرير المبادئ الحاكمة
- برومبت استكمال المهام
- Report94
- Report95
- CURRENT_STATE.md
- CURRENT_STATE_Report94_Update.md
- Current/PWA/main2/main8.md كاملًا من المصدر الحالي
- Current/PWA/accountant.html
- .github/workflows/forensic_main_assembly.yml
- Production Supabase schema / constraints / functions / Edge Functions / data

## 3. Current Git Truth
- Repository: papamohammed77-glitch/rawaie-erp-New
- Branch: main
- Current HEAD observed: 694245eb8f2ee4f706dbecc6f33b333902e79f89
- Current Main8 blob: b3cdbbc79e04f5be9b2e92f9c4e98ce1e7b668c33d62
- Commit 694245eb8f2ee4f706dbecc6f33b333902e79f89 هو آخر commit المرئي لتحديث Main8 قبل هذا التقرير، ولذلك Report95 الذي كان يثبت SHA أقدم لا يمثل حالة Main8 الحالية.

## 4. Source-of-Truth / Assembly
المسار الصحيح المؤكد:
- Editable source: Current/PWA/main2/main1.md ... main11.md
- Historical evidence: Current/PWA/main/*
- Historical reference: Original/PWA/main/*
- Generated target: Current/PWA/New-main

تم فحص .github/workflows/forensic_main_assembly.yml، وما زال يستخدم Current/PWA/main2 كمصدر الأجزاء. لا يوجد تصحيح مسار مطلوب.

## 5. Production snapshot الحالي
المطابقة المباشرة الحالية أثبتت:
- companies = 1
- branches = 2
- users = 24
- items = 17
- treasury = 1
- chart_of_accounts = 17
- cash_box = 0
- orders = 0
- runsheets = 0
- stock_branches = 20
- inventory_log = 3

الخزينة الحالية الوحيدة:
- id = 0a9d9357-b5f3-4dfa-886f-7c73de4f274e
- company_id = 00000000-0000-0000-0000-000000000001
- account_code = CASH-01
- account_name = الخزينة الرئيسية
- type = Cash
- current_balance = 10000.00

الحساب النقدي الرئيسي المثبت في Chart of Accounts:
- account_code = 121
- account_name = النقدية (الخزينة الرئيسية)
- id = d724dae3-874d-4975-9f21-ec423a5a661a

## 6. Production Financial Contracts التي تم التحقق منها
Production current adapters مثبتة كالتالي:
- save-receipt-voucher v7
- save-payment-voucher v5
- save-transfer-voucher v4

عقد الصرف الحالي يتطلب:
- header.operationId
- header.treasuryId = Treasury UUID
- header.cashAccountId = Account UUID
- header.offsetAccountId = Account UUID
- header.date
- header.reference
- header.mainAccountName
- header.notes
- lines[]

عقد التحويل الحالي يتطلب:
- operationId
- sourceTreasuryId = Treasury UUID
- targetTreasuryId = Treasury UUID
- sourceAccountId = Account UUID
- targetAccountId = Account UUID
- amount
- transferDate

الـProduction cores المقابلة:
- post_cash_payment_atomic
- post_treasury_transfer_atomic

كما أن operation identity جزء من العقد الفعلي، وليس تحسينًا اختياريًا.

## 7. Main8 Current Re-check
### M8-01..M8-10
الفحص المباشر للمصدر الحالي يثبت وجود جراحات company context وUUID financial identity في الأجزاء السابقة من Main8، بما فيها _companyId() وcompany-scoped treasury/accounts والقبض الحالي.

### M8-12
_ renderTransfers الحالي أصبح company-scoped ويعالج خطأ القراءة؛ وهو متوافق مع الجراحة السابقة.

### M8-14
_saveTransfer الحالي يستقبل trf-from / trf-to / trf-source-account / trf-target-account ويكوّن payload مطابقًا لعقد Production v4. لذلك لا يتم تعديل _saveTransfer في هذه الجلسة.

## 8. M8-11 — DEFECT CONFIRMED
### Current location
`_newPayment()` في السطور الحالية 859–864.
`_savePayment()` يبدأ في السطر 871 وينتهي في السطر 883 تقريبًا قبل `_renderTransfers()`.

Current `_newPayment()` uses:
- pmt-cashbox → treasury.account_code
- pmt-main-account → text input

Current `_savePayment()` sends:
- cashBoxId
- mainAccountName
- no header.operationId
- no treasury UUID contract
- no cashAccountId UUID
- no offsetAccountId UUID

هذا Consumer Contract Drift مثبت مباشرة من المصدر الحالي.

### Exact owner surgery — M8-11
لا تعدل أي شيء خارج الدالتين.

ابحث عن بداية:
`    function _newPayment() {`

احذف الدالة كاملة حتى آخر `}` مباشرة قبل:
`    function _addPaymentLine() {`

واستبدلها بـ:

```javascript
    function _newPayment() {
        var content = byId('finance-content'); if (!content) return;
        var treasuryOptions = _cache.treasury.map(function(t) {
            return '<option value="' + _esc(t.id) + '">' + _esc(t.account_name) + ' (' + _esc(t.account_code) + ')</option>';
        }).join('');
        var accountOptions = _cache.accountsFlat.map(function(a) {
            return '<option value="' + _esc(a.id) + '">' + _esc(a.account_name) + ' (' + _esc(a.account_code) + ')</option>';
        }).join('');
        var html = '<div class="bg-white rounded-2xl shadow-sm border p-4"><div class="flex justify-between items-center mb-4"><h2 class="text-xl font-bold"><i class="fa-solid fa-arrow-up ml-2 text-red-600"></i>سند صرف جديد</h2><button onclick="RW_Finance.renderSubTab(\\'payments\\')" class="text-gray-500 hover:text-gray-700"><i class="fa-solid fa-xmark text-xl"></i></button></div><div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4"><div><label class="block text-sm font-bold">التاريخ</label><input type="date" id="pmt-date" class="border rounded-lg p-2 w-full" value="' + new Date().toISOString().slice(0,10) + '"></div><div><label class="block text-sm font-bold">الخزينة</label><select id="pmt-cashbox" class="border rounded-lg p-2 w-full"><option value="">اختر الخزينة</option>' + treasuryOptions + '</select></div><div><label class="block text-sm font-bold">الحساب الرئيسي</label><select id="pmt-main-account" class="border rounded-lg p-2 w-full"><option value="">اختر الحساب</option>' + accountOptions + '</select></div></div><div class="mb-4"><h4 class="font-bold mb-2">بنود السند</h4><div id="pmt-lines"></div><button type="button" onclick="RW_Finance._addPaymentLine()" class="mt-2 text-red-600 font-bold"><i class="fa-solid fa-plus-circle ml-1"></i> إضافة بند</button></div><div class="p-3 bg-gray-50 rounded-lg flex justify-between mb-4"><span>الإجمالي: <span id="pmt-total">0.00</span></span></div><div class="flex justify-end gap-3"><button type="button" onclick="RW_Finance.renderSubTab(\\'payments\\')" class="px-4 py-2 border rounded-lg">إلغاء</button><button type="button" onclick="RW_Finance._savePayment()" class="px-6 py-2 bg-red-600 text-white rounded-lg font-bold"><i class="fa-solid fa-check ml-1"></i> حفظ</button></div></div>';
        safeHTML(content, html);
        _addPaymentLine();
    }
```

ثم ابحث عن بداية:
`    async function _savePayment() {`

احذف الدالة كاملة حتى آخر `}` مباشرة قبل:
`    function _renderTransfers() {`

واستبدلها بـ:

```javascript
    async function _savePayment() {
        var lines = [];
        document.querySelectorAll('.pmt-line').forEach(function(l) {
            var account = l.querySelector('.pmt-line-account').value.trim();
            var description = l.querySelector('.pmt-line-desc').value.trim();
            var amount = parseFloat(l.querySelector('.pmt-line-amount').value) || 0;
            if (account && amount > 0) {
                lines.push({ accountName: account, description: description, amount: amount });
            }
        });
        if (!lines.length) { _showToast('أضف بنداً', 'warning'); return; }

        var host = byId('finance-content');
        var treasuryId = byId('pmt-cashbox').value;
        var offsetAccountId = byId('pmt-main-account').value;
        var cashAccount = null;
        for (var i = 0; i < _cache.accountsFlat.length; i++) {
            if (_cache.accountsFlat[i].account_code === '121') {
                cashAccount = _cache.accountsFlat[i];
                break;
            }
        }
        if (!treasuryId || !offsetAccountId || !cashAccount) {
            _showToast('بيانات الخزينة أو الحساب المقابل غير مكتملة', 'error');
            return;
        }

        var op = host.dataset.paymentOperationId || (window.crypto && crypto.randomUUID ? crypto.randomUUID() : null);
        if (!op) {
            _showToast('تعذر إنشاء معرف العملية', 'error');
            return;
        }
        host.dataset.paymentOperationId = op;
        _showLoader('جاري حفظ سند الصرف...');
        try {
            var ses = await supabase.auth.getSession();
            var token = ses.data && ses.data.session ? ses.data.session.access_token : null;
            if (!token) throw new Error('انتهت الجلسة');
            var selected = byId('pmt-main-account').selectedOptions[0];
            var payload = {
                header: {
                    operationId: op,
                    treasuryId: treasuryId,
                    cashAccountId: cashAccount.id,
                    offsetAccountId: offsetAccountId,
                    date: byId('pmt-date').value,
                    reference: null,
                    mainAccountName: selected ? selected.textContent : null,
                    notes: ''
                },
                lines: lines
            };
            var res = await fetch(RW_SUPABASE_URL + '/functions/v1/save-payment-voucher', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token },
                body: JSON.stringify(payload)
            });
            var json = await res.json();
            if (!res.ok || !json || json.success === false) throw new Error((json && (json.error || json.msg)) || 'فشل الحفظ');
            delete host.dataset.paymentOperationId;
            _showToast(json.duplicate ? 'السند موجود بالفعل ولم يُكرر.' : 'تم الحفظ', 'success');
            renderSubTab('payments');
        } catch (e) {
            _showToast(e.message || 'فشل الحفظ', 'error');
        } finally {
            _hideLoader();
        }
    }
```

### Why this exact replacement
- Treasury field carries Treasury UUID.
- Main account carries Chart of Accounts UUID.
- Cash side remains the proven account code `121` resolved to its UUID from the company-scoped cache.
- Operation ID survives failure/retry and is cleared only after success.
- Payload exactly matches the deployed payment Edge contract.
- No change to payment line business meaning; beneficiary/description/amount remain unchanged.

## 9. M8-13 — DEFECT CONFIRMED
### Current location
`_newTransfer()` is the function beginning at current line 906 and ending immediately before:
`    async function _saveTransfer() {`

Current source uses only Treasury `account_code` values and renders no `trf-source-account` or `trf-target-account` controls.

Meanwhile `_saveTransfer()` already reads:
- `trf-source-account`
- `trf-target-account`
- Treasury values from `trf-from` / `trf-to`

Therefore the current `_newTransfer()` and `_saveTransfer()` are structurally incompatible.

### Exact owner surgery — M8-13
ابحث عن:
`    function _newTransfer() {`

احذف الدالة كاملة حتى آخر `}` مباشرة قبل:
`    async function _saveTransfer() {`

واستبدلها بـ:

```javascript
    function _newTransfer() {
        var content = byId('finance-content'); if (!content) return;
        var treasuryOptions = _cache.treasury.map(function(t) {
            return '<option value="' + _esc(t.id) + '">' + _esc(t.account_name) + ' (' + _esc(t.account_code) + ')</option>';
        }).join('');
        var accountOptions = _cache.accountsFlat.map(function(a) {
            return '<option value="' + _esc(a.id) + '">' + _esc(a.account_name) + ' (' + _esc(a.account_code) + ')</option>';
        }).join('');
        var html = '<div class="bg-white rounded-2xl shadow-sm border p-4"><div class="flex justify-between items-center mb-4"><h2 class="text-xl font-bold"><i class="fa-solid fa-right-left ml-2 text-purple-600"></i>تحويل جديد</h2><button type="button" onclick="RW_Finance.renderSubTab(\\'transfers\\')" class="text-gray-500 hover:text-gray-700"><i class="fa-solid fa-xmark text-xl"></i></button></div><div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4"><div><label class="block text-sm font-bold">من خزينة</label><select id="trf-from" class="border rounded-lg p-2 w-full"><option value="">اختر الخزينة</option>' + treasuryOptions + '</select></div><div><label class="block text-sm font-bold">إلى خزينة</label><select id="trf-to" class="border rounded-lg p-2 w-full"><option value="">اختر الخزينة</option>' + treasuryOptions + '</select></div><div><label class="block text-sm font-bold">حساب المصدر</label><select id="trf-source-account" class="border rounded-lg p-2 w-full"><option value="">اختر الحساب</option>' + accountOptions + '</select></div><div><label class="block text-sm font-bold">حساب الوجهة</label><select id="trf-target-account" class="border rounded-lg p-2 w-full"><option value="">اختر الحساب</option>' + accountOptions + '</select></div></div><div class="mb-4"><label class="block text-sm font-bold">المبلغ</label><input type="number" min="0.01" step="0.01" id="trf-amount" class="border rounded-lg p-2 w-full"></div><div class="flex justify-end gap-3"><button type="button" onclick="RW_Finance.renderSubTab(\\'transfers\\')" class="px-4 py-2 border rounded-lg">إلغاء</button><button type="button" onclick="RW_Finance._saveTransfer()" class="px-6 py-2 bg-purple-600 text-white rounded-lg font-bold"><i class="fa-solid fa-check ml-1"></i> حفظ</button></div></div>';
        safeHTML(content, html);
    }
```

### DO NOT modify M8-14
Current `_saveTransfer()` is already the required Consumer and must remain intact.

## 10. What is NOT changed
- `_addPaymentLine()` remains beneficiary/description/amount input by design.
- `_saveTransfer()` remains unchanged.
- `_renderTransfers()` remains unchanged after company scope is confirmed.
- Journal posting flow is not changed.
- Reporting RPC consumers are not changed.
- Inventory, order, runsheet, delivery and parent-shell contracts are not changed.
- `Current/PWA/main2/main8.md` was NOT edited by the assistant in this session.

## 11. Production impact
No new durable Production financial change was required in this source re-check.
The current Production financial contracts are already the correct target contract. The required corrections are Consumer-side in Main8.

No production data was mutated as part of this Main8 re-check.

A live positive end-to-end payment/transfer write was not executed because Production currently has one Treasury only and `cash_box = 0`; executing a real financial posting merely to test UI would create unnecessary business data.

This does not reduce the proof of the contract mismatch; it only means runtime financial posting remains an explicit post-owner-surgery verification gate.

## 12. Previous failure / learning
Report95 described M8-11 as “same pattern” and M8-13 as “change option values”, which was not sufficiently executable for manual surgical application.
The current re-check corrects that ambiguity by providing:
- exact function start
- exact function boundary
- exact preceding/following marker
- complete replacement code
- explicit preservation points

## 13. Production / Runtime / Assembly status
- Production financial contract = VERIFIED
- Current Main8 source = VERIFIED
- Main8 M8-11 = OPEN / OWNER SURGERY REQUIRED
- Main8 M8-13 = OPEN / OWNER SURGERY REQUIRED
- M8-12 = VERIFIED
- M8-14 = VERIFIED
- Main7 = OPEN / two owner surgeries from Report94 remain
- Full Main2 assembly = BLOCKED
- Parent Gold/Diamond = NOT CLOSED

## 14. Self-audit
### What I proved
- Report94 and its owner checkpoint were read.
- Report95 was read and its stale Main8 SHA was reconciled against current Git.
- Current Main8 source is now identified as blob `b3cdbbc79e04f5be9b2e92f9c4e98ce1e7b668c33d62`.
- Production financial Edge contracts and core UUID requirements were verified directly.
- M8-11 is genuinely incomplete in current Main8.
- M8-13 is genuinely incomplete in current Main8.
- M8-14 already expects the controls that M8-13 failed to render.
- Assembly workflow source path is correct and points to `Current/PWA/main2`.

### What I did not prove
- Owner application of M8-11 and M8-13 has not yet happened.
- Full Main8 syntax after owner edits has not yet been checked.
- Full Main2 reconstruction has not yet been run after owner edits.
- Browser/E2E of the assembled Parent has not yet been run.
- A durable financial write was intentionally not created in Production for testing.

### What I initially missed
- Report95’s wording for M8-11/M8-13 was too abstract for safe manual application.
- M8-13 was not merely a Treasury UUID substitution; it required creating the missing source/target account controls because the already-correct `_saveTransfer()` depends on them.

### What could still be wrong
Only after owner application can we verify final syntax, runtime wiring, and assembled Parent behavior. Any issue found there remains open until Production/runtime evidence closes it.

## 15. Last Verified Event
`EVENT: MAIN8-EXACT-SURGICAL-RECHECK-20260909`

## 16. Next authorized action
Owner applies exactly the three source surgeries documented above: M8-11 `_newPayment`, M8-11 `_savePayment`, M8-13 `_newTransfer`.
No other Main8 changes should be made in the same manual edit unless a new source-evidenced defect is separately opened as a new Closure Unit.
