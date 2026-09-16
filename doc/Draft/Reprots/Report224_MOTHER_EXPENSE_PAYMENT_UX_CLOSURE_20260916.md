# Report224 — إغلاق جنائي لتجربة سند الصرف / المصروفات — 2026-09-16

> **تنبيه حاكم في البداية:** الهدف في هذه المهمة لم يكن إصلاح شاشة فقط، بل إغلاق عقد **سند صرف / مصروف جديد / المصروفات** وظيفيًا بحيث يصبح المستند الواحد قادرًا على الصرف من خزينة محددة إلى حساب واحد أو عدة حسابات، مع بقاء القيد والخزينة والمصروفات مترابطة دون محركات موازية. 
>
> المصدر الحالي الوحيد للحقيقة في الواجهة هو:
> `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`
>
> ولا تُعامل أي تقارير تاريخية أو fragments كحالة حالية. الحالة الحالية بُنيت من:
> **CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE**.

## 1. نقطة البداية — ليست من الصفر

تمت مراجعة:

- `Report223_MOTHER_FINANCE_COMPLETION_20260916.md` كمرجع سياقي فقط.
- `CURRENT_STATE.md` السابق.
- `forensic_main_assembly.yml`.
- أحدث Git commit الخاص بالـMother.
- الـParent commit.
- المصدر الحالي الفعلي لـ`main.html`.
- Production Supabase وSchema وRPCs وEdge Functions.

الحالة الحديثة في Git:

```text
Repository: papamohammed77-glitch/erp-frontend
Current Mother path: companies/company-1/main.html
Latest verified HEAD: 509724e811c78d60875bde7bc45129512ba5ca20
Latest HEAD message: forensic: persist current Mother inventory extract
Latest HEAD date: 2026-09-16T16:50:14Z
Parent: 68be2badf21790da2f8a9473ad6639e8beb80ee7
Current forensic extract:
  FILE_LINES = 24854
  FILE_BYTES = 1394331
  SHA256 = d1be7eb82cd9237945dd977c686369f467cb489b56b6350e228bc026fe013a1b
```

الـlatest commit لم يغيّر `main.html` نفسه؛ لذلك موضع المشكلة الذي تمت قراءته هو نفس Mother الحالية.

`forensic_main_assembly.yml` تمت مطابقة محتواه، وهو صحيح حاليًا ويشير إلى:

```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
assembly_status:
  mode: published_main_is_authoritative
  fragment_mode: historical_reference_only
```

ولم يتم تغييره.

## 2. ما كشفه التحقيق الجنائي في Mother

الموضع الأساسي هو دالة:

```text
function _newPayment() {
```

وهي تبدأ حاليًا عند السطر التقريبي المثبت من الـforensic source:

```text
15836
```

وتأتي معها الدوال:

```text
_addPaymentLine
_removePaymentLine
_recalcPaymentTotal
_savePayment
```

قبل:

```text
function _renderTransfers() {
```

### السبب الجذري

واجهة سند الصرف كانت تعرض:

- خزينة.
- حساب رئيسي واحد.
- سطور متعددة شكلية.

لكن السطر نفسه لم يحمل `account_id`؛ بل كان يحمل اسمًا نصيًا للمستفيد.

ثم `save-payment-voucher` كان يجمع جميع السطور في إجمالي واحد ويرسل:

```text
offsetAccountId
```

واحدًا فقط إلى:

```text
post_cash_payment_atomic
```

وبذلك كانت الواجهة تبدو وكأنها متعددة البنود، بينما محركها المحاسبي الفعلي كان:

```text
خزينة واحدة
→ حساب مقابل واحد
→ إجمالي السطور
```

وهذا هو السبب الحقيقي للمشكلة.

### المشكلة الثانية

هناك مسار آخر باسم:

```text
async function newExpense(){
```

في `RW_Finance_GoldExtension`، وكان ينشئ مصروفًا مستقلًا بسطر محاسبي واحد.

هذا خلق مفهومين متوازيين:

```text
سند صرف
مصروف جديد
```

بدل مستند مالي واحد متكامل.

## 3. العقد الموجود بالفعل في Production

التحقيق في Production أثبت أن المشروع لا يحتاج محركًا جديدًا للمصروفات.

الموجود أصلًا:

```text
finance_expenses
finance_expense_lines
journal_entries
journal_lines
cash_box
treasury
finance_save_expense
finance_list_expenses
post_journal_entry
```

والـRPC الأصلي `finance_save_expense` يدعم أصلًا `p_lines jsonb`، أي أكثر من حساب في العملية الواحدة.

كذلك يوجد قيد:

```text
UNIQUE(company_id, operation_id)
```

في `finance_expenses`، ما يجعل العملية قابلة للحماية من التكرار.

والـTreasury لديها:

```text
company_id
current_balance
is_active
```

والـCashBox يحتوي على `type='Payment'`.

الخلاصة: **المحرك الأساسي كان موجودًا؛ الفجوة كانت في ربط تجربة سند الصرف بهذا العقد.**

## 4. القرار المعماري

تم اعتماد المسار التالي:

```text
سند صرف / مصروف جديد
        ↓
Treasury + Branch
        ↓
1..N Expense Lines
        ↓
finance_save_expense
        ↓
post_journal_entry
        ↓
finance_expenses + finance_expense_lines
        ↓
cash_box
        ↓
treasury.current_balance
        ↓
تبويب المصروفات
```

لا يوجد محرك دفع محاسبي ثانٍ للمصروفات.

`post_cash_payment_atomic` يبقى عقدًا عامًا لدفعة أحادية الحساب ولا يتم تحويله إلى محرك آخر للمصروفات متعددة الحسابات.

## 5. ما تم تنفيذه في Production

### 5.1 إضافة هوية الفرع إلى المصروف

تم تنفيذ:

```text
finance_expenses.branch_id uuid
```

مع FK إلى:

```text
branches(id)
```

حتى يصبح المصروف ظاهرًا في سياق الفرع وليس فقط الخزينة.

### 5.2 إضافة عقد حفظ مصروف خاص بسند الصرف

تم نشر overload جديد لـ:

```text
finance_save_expense
```

بتوقيع يتضمن:

```text
p_branch_id uuid
```

مع التحقق من:

- المستخدم ينتمي إلى `p_company_id`.
- الفرع موجود ونشط ويتبع الشركة.
- الخزينة موجودة ونشطة وتتبع الشركة.
- `operation_id` لا يُعاد استخدامه بسياق فرع/خزينة مختلف.
- السطور متعددة الحسابات.

### 5.3 استعلام جديد للمصروفات

تم إنشاء:

```text
finance_list_expenses_v2
```

ويعيد:

```text
branch_id
branch_name
treasury_id
treasury_name
line_count
```

إضافة إلى بيانات المصروف والقيد.

### 5.4 Edge Function

تم تحديث ونشر:

```text
save-payment-voucher
```

إلى الإصدار:

```text
version 7
status ACTIVE
verify_jwt = true
```

وأصبح:

```text
Browser/Auth
  ↓
resolve user company
  ↓
validate branch + treasury
  ↓
normalize N lines
  ↓
finance_save_expense
```

وبالتالي لم يعد يعتمد على:

```text
post_cash_payment_atomic
```

لتجميع كل السطور في حساب واحد.

## 6. لماذا لم ننشئ جدولًا جديدًا لسند الصرف

لأن ذلك كان سيخلق:

```text
Payment Header
Payment Lines
Expense Header
Expense Lines
Journal
Cash Box
```

مع احتمالية dual write ومشكلات reconciliation.

الموجود بالفعل:

```text
finance_expenses
finance_expense_lines
```

هو العقد المناسب لهذا المستند.

لذلك أصبح سند الصرف نفسه هو واجهة إدخال المصروف المتعدد البنود.

## 7. اختبارات Production التي تم تنفيذها

### اختبار Multi-Line

تم تشغيل العملية داخل Transaction واحدة باستخدام:

```text
Line 1 = 10
Line 2 = 20
Total = 30
```

والنتيجة:

```text
success = true
duplicate = false
branch_id = a38332b6-6cea-480a-ada1-6eb6ab0590db
treasury_id = 0a9d9357-b5f3-4dfa-886f-7c73de4f274e
total = 30
```

ثم تم `ROLLBACK`.

أي لا توجد بيانات اختبار متبقية.

### اختبار Idempotency

تم تنفيذ نفس `operation_id` مرتين داخل Transaction.

النداء الثاني أعاد:

```text
duplicate = true
success = true
```

ثم تم `ROLLBACK`.

### حالة البيانات قبل/بعد

```text
finance_expenses      = 0
finance_expense_lines = 0
```

وبالتالي لم تُترك بيانات تجريبية دائمة.

## 8. الجراحة المطلوبة في Mother — تنفذ من المالك فقط

### الجراحة A — استبدال مجموعة سند الصرف كاملة

**في الملف:**

```text
companies/company-1/main.html
```

**الموضع:** يبدأ عند السطر التقريبي:

```text
15836
```

**ابحث حرفيًا عن:**

```text
function _newPayment() {
```

**واحذف الكتلة كاملة حتى آخر سطر من `_savePayment`، وقبل هذا السطر مباشرة:**

```text
function _renderTransfers() {
```

**واستبدلها بالكتلة التالية كاملة:**

```javascript
    function _renderPayments() {
        var content = byId('finance-content'); if (!content) return;
        content.innerHTML = '<div class="text-center py-8">جاري تحميل سندات الصرف...</div>';
        supabase.from('cash_box').select('*').eq('company_id', _companyId()).eq('type', 'Payment').order('voucher_date', { ascending: false }).then(function(r) {
            if (r.error) throw r.error;
            var data = r.data || [];
            var html = '<div class="bg-white rounded-2xl shadow-sm border p-4">' +
                '<div class="flex justify-between items-center mb-4">' +
                    '<h2 class="text-xl font-bold"><i class="fa-solid fa-arrow-up ml-2 text-red-600"></i>سندات الصرف</h2>' +
                    '<button onclick="RW_Finance._newPayment()" class="bg-red-600 text-white px-4 py-2 rounded-xl"><i class="fa-solid fa-plus ml-1"></i> سند صرف جديد</button>' +
                '</div>' +
                '<div id="payments-list">' + _buildReceiptsTable(data) + '</div>' +
            '</div>';
            safeHTML(content, html);
        }).catch(function(e) {
            _showToast(e.message || 'فشل تحميل سندات الصرف', 'error');
        });
    }

    function _newPayment() {
        var content = byId('finance-content');
        if (!content) return;

        var treasuryOptions = _cache.treasury.map(function(t) {
            return '<option value="' + _esc(t.id) + '">' +
                _esc(t.account_name) + ' (' + _esc(t.account_code) + ')' +
            '</option>';
        }).join('');

        var branchOptions = (_cache.branches || []).map(function(b) {
            return '<option value="' + _esc(b.id) + '">' +
                _esc(b.name || b.branch_code) +
            '</option>';
        }).join('');

        var accountOptions = _cache.accountsFlat.map(function(a) {
            return '<option value="' + _esc(a.id) + '">' +
                _esc(a.account_name) + ' (' + _esc(a.account_code) + ')' +
            '</option>';
        }).join('');

        var operationId = (window.crypto && crypto.randomUUID) ? crypto.randomUUID() : String(Date.now()) + '-' + Math.random();
        content.dataset.paymentOperationId = operationId;

        var html =
            '<div class="bg-white rounded-2xl shadow-sm border p-5">' +
                '<div class="flex flex-wrap justify-between items-center gap-3 mb-5">' +
                    '<div>' +
                        '<h2 class="text-xl font-black"><i class="fa-solid fa-arrow-up ml-2 text-red-600"></i>مصروف جديد</h2>' +
                        '<div class="text-sm text-gray-500 mt-1">صرف من خزينة محددة إلى حساب واحد أو عدة حسابات.</div>' +
                    '</div>' +
                    '<button type="button" onclick="RW_Finance.renderSubTab(\'payments\')" class="text-gray-500 hover:text-gray-700">' +
                        '<i class="fa-solid fa-xmark text-xl"></i>' +
                    '</button>' +
                '</div>' +

                '<div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-5">' +
                    '<div>' +
                        '<label class="block text-sm font-bold mb-1">التاريخ</label>' +
                        '<input type="date" id="pmt-date" class="border rounded-xl p-3 w-full" value="' + new Date().toISOString().slice(0,10) + '">' +
                    '</div>' +
                    '<div>' +
                        '<label class="block text-sm font-bold mb-1">الفرع</label>' +
                        '<select id="pmt-branch" class="border rounded-xl p-3 w-full"><option value="">اختر الفرع</option>' + branchOptions + '</select>' +
                    '</div>' +
                    '<div>' +
                        '<label class="block text-sm font-bold mb-1">الخزينة</label>' +
                        '<select id="pmt-cashbox" class="border rounded-xl p-3 w-full"><option value="">اختر الخزينة</option>' + treasuryOptions + '</select>' +
                    '</div>' +
                    '<div>' +
                        '<label class="block text-sm font-bold mb-1">المستفيد</label>' +
                        '<input type="text" id="pmt-beneficiary" class="border rounded-xl p-3 w-full" placeholder="اسم المستفيد / الجهة">' +
                    '</div>' +
                    '<div class="md:col-span-4">' +
                        '<label class="block text-sm font-bold mb-1">المرجع</label>' +
                        '<input type="text" id="pmt-reference" class="border rounded-xl p-3 w-full" placeholder="رقم فاتورة، مستند، إيصال...">' +
                    '</div>' +
                '</div>' +

                '<div class="border rounded-2xl overflow-hidden">' +
                    '<div class="bg-slate-50 p-3 flex flex-wrap justify-between items-center gap-2">' +
                        '<div class="font-black">بنود المصروف</div>' +
                        '<button type="button" onclick="RW_Finance._addPaymentLine()" class="text-red-600 font-bold">' +
                            '<i class="fa-solid fa-plus-circle ml-1"></i> إضافة حساب' +
                        '</button>' +
                    '</div>' +
                    '<div class="hidden md:grid grid-cols-12 gap-2 px-3 py-2 text-xs font-bold text-gray-500 border-b">' +
                        '<div class="col-span-5">الحساب</div>' +
                        '<div class="col-span-3">البيان</div>' +
                        '<div class="col-span-3">المبلغ</div>' +
                        '<div class="col-span-1"></div>' +
                    '</div>' +
                    '<div id="pmt-lines" class="p-3"></div>' +
                '</div>' +

                '<div class="grid grid-cols-1 md:grid-cols-3 gap-3 mt-4">' +
                    '<div class="rounded-xl bg-slate-50 border p-4"><div class="text-xs text-gray-500">عدد الحسابات</div><div id="pmt-count" class="text-xl font-black">0</div></div>' +
                    '<div class="rounded-xl bg-red-50 border border-red-100 p-4"><div class="text-xs text-red-700">إجمالي المصروف</div><div id="pmt-total" class="text-2xl font-black text-red-700">0.00</div></div>' +
                    '<div class="rounded-xl bg-emerald-50 border border-emerald-100 p-4"><div class="text-xs text-emerald-700">حالة الخزينة</div><div id="pmt-balance-status" class="font-black text-emerald-700">اختر الخزينة</div></div>' +
                '</div>' +

                '<div class="mt-4">' +
                    '<label class="block text-sm font-bold mb-1">وصف العملية</label>' +
                    '<textarea id="pmt-notes" class="border rounded-xl p-3 w-full" rows="3" placeholder="بيان السند أو الملاحظات"></textarea>' +
                '</div>' +

                '<div class="flex justify-end gap-3 mt-5">' +
                    '<button type="button" onclick="RW_Finance.renderSubTab(\'payments\')" class="px-5 py-2 border rounded-xl">إلغاء</button>' +
                    '<button type="button" onclick="RW_Finance._savePayment()" class="px-6 py-2 bg-red-600 text-white rounded-xl font-black">' +
                        '<i class="fa-solid fa-check ml-1"></i> حفظ وترحيل' +
                    '</button>' +
                '</div>' +
            '</div>';

        safeHTML(content, html);
        _addPaymentLine();
        _recalcPaymentTotal();
    }

    function _addPaymentLine() {
        var accountOptions = _cache.accountsFlat.map(function(a) {
            return '<option value="' + _esc(a.id) + '">' +
                _esc(a.account_name) + ' (' + _esc(a.account_code) + ')' +
            '</option>';
        }).join('');

        var html =
            '<div class="pmt-line grid grid-cols-1 md:grid-cols-12 gap-2 mb-3 bg-gray-50 border rounded-xl p-3">' +
                '<div class="md:col-span-5">' +
                    '<label class="md:hidden block text-xs font-bold mb-1">الحساب</label>' +
                    '<select class="pmt-line-account border rounded-lg p-2 w-full text-sm">' +
                        '<option value="">اختر الحساب</option>' + accountOptions +
                    '</select>' +
                '</div>' +
                '<div class="md:col-span-3">' +
                    '<label class="md:hidden block text-xs font-bold mb-1">البيان</label>' +
                    '<input type="text" class="pmt-line-desc border rounded-lg p-2 w-full text-sm" placeholder="بيان البند">' +
                '</div>' +
                '<div class="md:col-span-3">' +
                    '<label class="md:hidden block text-xs font-bold mb-1">المبلغ</label>' +
                    '<input type="number" step="0.01" min="0.01" class="pmt-line-amount border rounded-lg p-2 w-full text-sm" placeholder="0.00" oninput="RW_Finance._recalcPaymentTotal()">' +
                '</div>' +
                '<div class="md:col-span-1 flex items-end justify-center">' +
                    '<button type="button" onclick="RW_Finance._removePaymentLine(this)" class="text-red-500 px-2 py-2" title="حذف البند">' +
                        '<i class="fa-solid fa-circle-minus"></i>' +
                    '</button>' +
                '</div>' +
            '</div>';

        var host = byId('pmt-lines');
        if (host) host.insertAdjacentHTML('beforeend', html);
        _recalcPaymentTotal();
    }

    function _removePaymentLine(btn) {
        var row = btn && btn.closest ? btn.closest('.pmt-line') : null;
        if (row) row.remove();
        _recalcPaymentTotal();
    }

    function _recalcPaymentTotal() {
        var total = 0;
        var count = 0;
        var lines = document.querySelectorAll('.pmt-line');
        lines.forEach(function(l) {
            var account = l.querySelector('.pmt-line-account');
            var amount = l.querySelector('.pmt-line-amount');
            if (account && account.value) count++;
            total += parseFloat(amount && amount.value || 0) || 0;
        });

        safeText(byId('pmt-total'), _fmtNum(total));
        safeText(byId('pmt-count'), String(count));

        var treasuryId = byId('pmt-cashbox') ? byId('pmt-cashbox').value : '';
        var status = byId('pmt-balance-status');
        if (!status) return;
        if (!treasuryId) {
            safeText(status, 'اختر الخزينة');
            return;
        }
        var treasury = null;
        for (var i = 0; i < _cache.treasury.length; i++) {
            if (_cache.treasury[i].id === treasuryId) { treasury = _cache.treasury[i]; break; }
        }
        if (!treasury) {
            safeText(status, 'الخزينة غير متاحة');
            return;
        }
        var balance = Number(treasury.current_balance || 0);
        if (total > balance) {
            safeText(status, 'الرصيد غير كافٍ: ' + _fmtNum(balance));
            status.className = 'font-black text-red-700';
        } else {
            safeText(status, 'متاح: ' + _fmtNum(balance));
            status.className = 'font-black text-emerald-700';
        }
    }

    async function _savePayment() {
        var host = byId('finance-content');
        if (!host) return;

        var branchId = byId('pmt-branch') ? byId('pmt-branch').value : '';
        var treasuryId = byId('pmt-cashbox') ? byId('pmt-cashbox').value : '';
        var date = byId('pmt-date') ? byId('pmt-date').value : '';
        var beneficiary = byId('pmt-beneficiary') ? byId('pmt-beneficiary').value.trim() : '';
        var reference = byId('pmt-reference') ? byId('pmt-reference').value.trim() : '';
        var notes = byId('pmt-notes') ? byId('pmt-notes').value.trim() : '';
        var lines = [];

        document.querySelectorAll('.pmt-line').forEach(function(l) {
            var accountId = l.querySelector('.pmt-line-account') ? l.querySelector('.pmt-line-account').value : '';
            var description = l.querySelector('.pmt-line-desc') ? l.querySelector('.pmt-line-desc').value.trim() : '';
            var amount = parseFloat(l.querySelector('.pmt-line-amount') ? l.querySelector('.pmt-line-amount').value : 0) || 0;
            if (accountId && amount > 0) {
                lines.push({
                    accountId: accountId,
                    description: description,
                    amount: amount,
                    taxAmount: 0
                });
            }
        });

        if (!branchId) { _showToast('اختر الفرع', 'warning'); return; }
        if (!treasuryId) { _showToast('اختر الخزينة', 'warning'); return; }
        if (!date) { _showToast('حدد تاريخ السند', 'warning'); return; }
        if (!lines.length) { _showToast('أضف حسابًا واحدًا على الأقل', 'warning'); return; }

        var duplicateAccounts = {};
        for (var i = 0; i < lines.length; i++) {
            duplicateAccounts[lines[i].accountId] = (duplicateAccounts[lines[i].accountId] || 0) + 1;
        }
        for (var k in duplicateAccounts) {
            if (duplicateAccounts[k] > 1) {
                _showToast('لا تكرر نفس الحساب داخل السند؛ اجمع القيمة في بند واحد.', 'warning');
                return;
            }
        }

        var total = lines.reduce(function(sum, x) { return sum + x.amount + x.taxAmount; }, 0);
        var treasury = null;
        for (var t = 0; t < _cache.treasury.length; t++) {
            if (_cache.treasury[t].id === treasuryId) { treasury = _cache.treasury[t]; break; }
        }
        if (!treasury) { _showToast('الخزينة غير موجودة', 'error'); return; }
        if (Number(treasury.current_balance || 0) < total) {
            _showToast('رصيد الخزينة غير كافٍ', 'error');
            return;
        }

        var operationId = host.dataset.paymentOperationId || ((window.crypto && crypto.randomUUID) ? crypto.randomUUID() : String(Date.now()) + '-' + Math.random());
        host.dataset.paymentOperationId = operationId;

        _showLoader('جاري حفظ المصروف وترحيله...');
        try {
            var result = await supabase.rpc('finance_save_expense', {
                p_company_id: _companyId(),
                p_expense_id: null,
                p_expense_code: 'EXP-' + operationId.replace(/-/g, '').slice(0, 16).toUpperCase(),
                p_expense_date: date,
                p_beneficiary_name: beneficiary || null,
                p_category_id: null,
                p_treasury_id: treasuryId,
                p_description: notes || 'سند صرف',
                p_attachment_url: null,
                p_reference: reference || null,
                p_created_by: (RW_STATE.user && RW_STATE.user.email) || 'mother',
                p_operation_id: operationId,
                p_branch_id: branchId,
                p_lines: lines
            });

            if (result.error) throw result.error;
            var data = result.data || {};
            delete host.dataset.paymentOperationId;
            _showToast(data.duplicate ? 'السند موجود بالفعل ولم يُكرر.' : 'تم حفظ المصروف وترحيله بنجاح', 'success');
            await renderSubTab('payments');
        } catch (e) {
            _showToast(e.message || 'فشل حفظ سند الصرف', 'error');
        } finally {
            _hideLoader();
        }
    }
```

### ملاحظة مهمة جدًا على الجراحة A

الكتلة أعلاه متعمدة لتغيير `_newPayment` نفسه، وكذلك helper functions التابعة له. لا تترك النسخ القديمة لهذه الدوال في الملف.

## 9. الجراحة B — توحيد زر المصروفات مع سند الصرف

في `main.html` ابحث عن:

```text
if(add) add.onclick=function(){RW_Finance._goldNewExpense();};
```

واستبدله حرفيًا بـ:

```javascript
if(add) add.onclick=function(){RW_Finance._newPayment();};
```

وبذلك يصبح:

```text
Finance → المصروفات → مصروف جديد
```

نفس واجهة:

```text
Finance → سندات الصرف → سند صرف جديد
```

ولا يبقى مساران إدخاليان مختلفان.

## 10. الجراحة C — تحديث قائمة المصروفات إلى العقد الجديد

في `main.html` ابحث عن بداية:

```text
async function renderExpenses(){
```

وهي في المصدر الحالي قرب:

```text
17277
```

واحذف الدالة كاملة حتى السطر:

```text
}
    async function renderCheques(){
```

واستبدلها كاملة بـ:

```javascript
    async function renderExpenses(){
        var cid = companyId();
        var defaultFrom = today().slice(0,8) + '01';
        var defaultTo = today();

        async function paint(from, to){
            var rows = await rpc('finance_list_expenses_v2', {
                p_company_id: cid,
                p_from: from,
                p_to: to
            }) || [];

            var total = 0;
            var count = rows.length;
            rows.forEach(function(x){ total += Number(x.total_amount || 0) + Number(x.tax_amount || 0); });

            var h = '<div class="space-y-4">' +
                '<div class="grid grid-cols-1 md:grid-cols-5 gap-3 items-end">' +
                    '<div><label class="block text-sm font-bold mb-1">من تاريخ</label><input id="fin_exp_from" type="date" value="' + esc(from) + '" class="w-full border rounded-xl p-3"></div>' +
                    '<div><label class="block text-sm font-bold mb-1">إلى تاريخ</label><input id="fin_exp_to" type="date" value="' + esc(to) + '" class="w-full border rounded-xl p-3"></div>' +
                    '<button id="fin_exp_apply" class="bg-slate-800 text-white px-4 py-3 rounded-xl font-bold">تحديث النتائج</button>' +
                    '<button id="fin_exp_new" class="bg-red-600 text-white px-4 py-3 rounded-xl font-bold">مصروف جديد</button>' +
                    '<div class="rounded-xl bg-red-50 border border-red-100 p-3"><div class="text-xs text-red-700">إجمالي الفترة</div><div class="text-lg font-black text-red-700">' + money(total) + '</div></div>' +
                '</div>' +
                '<div class="grid grid-cols-1 md:grid-cols-3 gap-3">' +
                    '<div class="rounded-2xl bg-slate-50 border p-4"><div class="text-xs text-gray-500">عدد المصروفات</div><div class="text-2xl font-black">' + count + '</div></div>' +
                    '<div class="rounded-2xl bg-indigo-50 border p-4"><div class="text-xs text-indigo-700">الحسابات المستخدمة</div><div class="text-2xl font-black text-indigo-700">' + rows.reduce(function(n,x){ return n + Number(x.line_count || 0); },0) + '</div></div>' +
                    '<div class="rounded-2xl bg-emerald-50 border p-4"><div class="text-xs text-emerald-700">المستندات المرحّلة</div><div class="text-2xl font-black text-emerald-700">' + rows.filter(function(x){return x.status === 'POSTED';}).length + '</div></div>' +
                '</div>' +
                '<div class="overflow-x-auto"><table class="w-full text-sm border">' +
                    '<thead><tr class="bg-slate-50">' +
                        '<th class="p-2 border">الكود</th>' +
                        '<th class="p-2 border">التاريخ</th>' +
                        '<th class="p-2 border">الفرع</th>' +
                        '<th class="p-2 border">الخزينة</th>' +
                        '<th class="p-2 border">المستفيد</th>' +
                        '<th class="p-2 border">الحسابات</th>' +
                        '<th class="p-2 border">الإجمالي</th>' +
                        '<th class="p-2 border">الحالة</th>' +
                        '<th class="p-2 border">القيد</th>' +
                    '</tr></thead><tbody>';

            if(!rows.length){
                h += '<tr><td colspan="9" class="p-8 text-center text-gray-500">لا توجد مصروفات ضمن الفترة المحددة.</td></tr>';
            }else{
                rows.forEach(function(x){
                    var gross = Number(x.total_amount || 0) + Number(x.tax_amount || 0);
                    h += '<tr class="border-t hover:bg-slate-50">' +
                        '<td class="p-2 border font-bold">' + esc(x.expense_code) + '</td>' +
                        '<td class="p-2 border">' + esc(x.expense_date) + '</td>' +
                        '<td class="p-2 border">' + esc(x.branch_name || '—') + '</td>' +
                        '<td class="p-2 border">' + esc(x.treasury_name || '—') + '</td>' +
                        '<td class="p-2 border">' + esc(x.beneficiary_name || '—') + '</td>' +
                        '<td class="p-2 border text-center font-black">' + Number(x.line_count || 0) + '</td>' +
                        '<td class="p-2 border text-left font-black text-red-700">' + money(gross) + '</td>' +
                        '<td class="p-2 border">' + esc(x.status || '') + '</td>' +
                        '<td class="p-2 border text-xs">' + esc(x.journal_entry_id || '') + '</td>' +
                    '</tr>';
                });
            }

            h += '</tbody></table></div></div>';
            card('المصروفات','fa-money-bill-wave',h);

            var apply = byId('fin_exp_apply');
            var add = byId('fin_exp_new');
            if(apply){
                apply.onclick = async function(){
                    var f = byId('fin_exp_from').value;
                    var t = byId('fin_exp_to').value;
                    if(!f || !t){ await Swal.fire({icon:'warning',title:'الفترة غير مكتملة',text:'حدد تاريخ البداية والنهاية.'}); return; }
                    if(f > t){ await Swal.fire({icon:'warning',title:'الفترة غير صحيحة',text:'تاريخ البداية لا يجوز أن يتجاوز تاريخ النهاية.'}); return; }
                    await paint(f,t);
                };
            }
            if(add) add.onclick = function(){ RW_Finance._newPayment(); };
        }

        await paint(defaultFrom, defaultTo);
    }
```

## 11. لماذا لم نحذف `newExpense()` الآن

تم التحقق من أن المستهلك المباشر الظاهر في Mother هو:

```text
RW_Finance._goldNewExpense
```

ولأقل تغيير ممكن، لا نعيد كتابة function تاريخية ضخمة الآن.

بدل ذلك، بعد تنفيذ الجراحة A يصبح المستند الحقيقي هو `_newPayment`، وبعد الجراحة B يصبح زر المصروفات يستدعي `_newPayment` مباشرة.

أي أن `newExpense()` القديمة تصبح غير مستخدمة في المسار التشغيلي.

**لا تحذفها في نفس الجراحة دون حاجة**؛ لأن الحوكمة تمنع حذف كود تاريخي قبل إثبات عدم وجود Consumer مخفي.

## 12. تحسين تجربة المستخدم الذي أصبح مستهدفًا

النسخة الجديدة تحقق:

```text
عنوان واضح = مصروف جديد
فرع واضح
خزينة واضحة
مستفيد
مرجع
1..N حسابات
بيان لكل حساب
مبلغ لكل حساب
إجمالي لحظي
عدد الحسابات
حالة رصيد الخزينة
منع تكرار الحساب داخل السند
منع الصرف بأكثر من رصيد الخزينة
Operation ID ثابت
```

وبالتالي الاستخدام الطبيعي:

```text
اختيار الفرع
↓
اختيار الخزينة
↓
اختيار حساب 1 + مبلغ
↓
إضافة حساب 2 + مبلغ
↓
إضافة حساب 3 ...
↓
مراجعة الإجمالي وحالة الخزينة
↓
حفظ وترحيل
```

## 13. مثال عملي للعقد الجديد

```text
مصروف جديد
الفرع: الرئيسي
الخزينة: الخزينة الرئيسية

بند 1
الحساب: مصروفات وتكلفة المبيعات
المبلغ: 500

بند 2
الحساب: مصروف آخر عند توفره في دليل الحسابات
المبلغ: 300

الإجمالي: 800
```

النتيجة المطلوبة في Production:

```text
finance_expenses = 1
finance_expense_lines = 2
journal debit lines = 2
journal credit cash line = 1
cash_box Payment = 1
treasury balance decrease = 800
```

ثم يظهر المستند نفسه في تبويب المصروفات.

## 14. ما لم يتم ادعاؤه

لم يتم تشغيل Browser E2E authenticated لهذه الجراحة؛ لأن `main.html` في المستودع لا ينفذ فيه المساعد تعديلات المالك.

لذلك:

```text
Backend Production implementation = DEPLOYED
Production RPC test = PASSED
Idempotency transaction test = PASSED
Current data footprint = CLEAN
Mother surgical replacement = PREPARED
Browser E2E after owner merge = OPEN
```

## 15. SELF-AUDIT

### ما تم إثباته

```text
Current Git identified                 = YES
Current source identified              = YES
Latest commit inspected                = YES
Parent inspected                       = YES
Production schema inspected            = YES
Existing finance engine inspected      = YES
Root cause of multi-account defect     = PROVEN
New Production contract                = DEPLOYED
Edge deployment                         = DEPLOYED
Multi-line transactional test          = PASSED
Idempotency test                        = PASSED
No permanent test data left             = PROVEN
forensic_main_assembly.yml              = CORRECT
```

### ما لم يُثبت بعد

```text
Browser click-path after owner merge    = OPEN
Authenticated browser console           = OPEN
Final UI visual validation              = OPEN
Full end-to-end DB delta through UI     = OPEN
```

ولذلك لا يتم إعلان Gold/Diamond النهائي للـMother Finance UI حتى يتم E2E.

## 16. تعليمات المساعد التالي — تبدأ من الحقيقة لا من التقرير

التسلسل الإلزامي:

```text
CURRENT GIT
↓
CURRENT SOURCE
↓
CURRENT PRODUCTION
↓
CURRENT DATABASE
↓
CURRENT DEPLOYMENTS
↓
LATEST COMMIT + PARENT
↓
افتح الملف الحالي نفسه
↓
حدد الدالة والـConsumer الحقيقي
↓
تتبع RPC / Edge / Schema
↓
قارن المسؤوليات
↓
أثبت الفجوة
↓
Closure Unit واحدة فقط
↓
Production تنفيذ مباشر
↓
Owner-side surgical replacement للـMother
↓
Browser E2E
↓
Console
↓
DB verification
↓
Git/Production synchronization
↓
Report + CURRENT_STATE
```

ولا تبدأ من تقرير تاريخي باعتباره حالة حالية.

ولا تعدّل عنصرًا ثبت إصلاحه بالفعل.

ولا تنشئ جدولًا أو Edge Function أو RPC ثانيًا إذا كان العقد الموجود قادرًا على حمل المسؤولية.

ولا تعتبر:

```text
Migration PASS
```

مساويًا لـ:

```text
Browser PASS
```

## 17. الحكم التنفيذي

تمت معالجة الجذر الخلفي للمشكلة وإغلاقه في Production:

```text
Single-account payment engine
        ↓
تم تحويل مسار سند الصرف
        ↓
Multi-line Expense Contract
        ↓
Journal + CashBox + Treasury + Expense Listing
```

والخطوة الوحيدة المتبقية ليست تصميمًا خلفيًا جديدًا؛ بل **تطبيق الجراحة في Mother ثم تنفيذ E2E authenticated والتحقق من Console وDB**.

بعد ذلك فقط يمكن إغلاق Closure Unit نهائيًا.
