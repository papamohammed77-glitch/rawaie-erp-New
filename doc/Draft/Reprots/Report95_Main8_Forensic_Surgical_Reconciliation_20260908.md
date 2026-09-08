# Report95 — Main8 Forensic Surgical Reconciliation — 2026-09-08

## 1. الغرض

استكمال العمل بعد `Report94_Main7_Exact_Surgical_Reconciliation_20260908.md` دون إعادة بناء من الصفر، مع:

- إعادة مطابقة Git وProduction.
- تثبيت أن `Current/PWA/main2/main7.md` ما زال غير مكتمل يدويًا وفق الجراحتين المسجلتين في Report94.
- قراءة `Current/PWA/main2/main8.md` كاملًا ومراجعته مع `Current/PWA/accountant.html` والعقود المالية المنشورة.
- تنفيذ إصلاح Production الذي ثبت أنه خلل حقيقي.
- تحديد جراحات Main8 بدقة بصيغة `ابحث / احذف / استبدل` دون قيام المساعد بتعديل ملف Main8 نفسه.
- منع أي تعديل يكسر العقود التاريخية أو يخلط بين `Current/PWA/main2` وبين المراحل التاريخية.

---

## 2. مصادر الحقيقة التي تمت مراجعتها

### Governance / Continuity
- `doc/Draft/medhat/MASTER - RAWAEA ERP.md`
- `doc/Draft/medhat/MASTER - RAWAEA ERP FORENSIC CONTINUITY GOVERNANCE v2.md`
- `doc/Draft/medhat/MASTER - RAWAEA ERP - UNIFIED CONTINUITY & MAIN1 EXECUTION.md`
- `doc/Draft/medhat/تقرير مبادئ حاكمة`
- `doc/Draft/medhat/برومبت استكمال مهام`

### Latest Main7 records
- `doc/Draft/Reprots/Report94_Main7_Exact_Surgical_Reconciliation_20260908.md`
- `doc/Draft/Reprots/CURRENT_STATE_Report94_Update.md`
- `CURRENT_STATE.md`

### Main2 / Finance
- `Current/PWA/main2/main8.md`
- `Current/PWA/accountant.html`
- `Current/PWA/main2/main7.md`
- `Original/PWA/main/*` عند الحاجة للمقارنة التاريخية
- `Current/PWA/New-main` كدليل تاريخي/Generated Target فقط، وليس Source of Truth
- `.github/workflows/forensic_main_assembly.yml`

### Production
- SMART ERP / Supabase Production: `fiilmooggumokxanwiyx`
- PostgreSQL schema / constraints / RLS / functions / Edge Functions / migrations

---

## 3. Git reconciliation

### آخر HEAD قبل تسجيل Report95
`e1b6168a091ebb5188828d479a5bab4254b9aae4`

ظهر هذا الـHEAD بعد رفع `CURRENT_STATE_Report94_Update.md`.

### Current Main8
- Path: `Current/PWA/main2/main8.md`
- Blob SHA: `20f77481133d3e55ced949de16f88dadb0a69980`

### Current Main7
- Report94 أثبت أن المصدر الحالي عند:
  `d6ee5ed58faf82d23bd8d0ab73f70d5979d41f19`
- آخر commit مخصص لـMain7 الذي اعتمد عليه Report94:
  `bf9baf2571790e9000a7db99ca93bf250d07c9e6`

### Assembly path
`.github/workflows/forensic_main_assembly.yml` صحيح حاليًا ويستخدم:

`Current/PWA/main2/**`

كمصدر الأجزاء، ويعتبر `Current/PWA/New-main` Generated Target. لا يوجد تصحيح مسار مطلوب في هذه الجلسة.

---

## 4. Main7 — النتيجة النهائية لإعادة الفحص

لم يتم تعديل `Current/PWA/main2/main7.md`.

الجراحتان المسجلتان في Report94 ما زالتا هما الجراحتين اليدويتين المطلوبتين قبل Assembly:

### M7-15A
المواضع: السطور 126–129 في نسخة Main7 التي اعتمدها Report94.

ابحث عن السطور الأربعة الكاملة التي تحتوي على:

`fromId: 'null'`

واستبدلها بالقيم الحقيقية:

`fromId: null`

ولـ`toId` استخدم `null` بدل string sentinel في الحالات الأربع التي حددها Report94.

### M7-14
الدالة:

`_showLoadingDetails(code)`

تبدأ في السطر 762 وتنتهي في السطر 772 وفق Report94.

يجب استبدال الدالة كاملة بالنسخة company-scoped الواردة حرفيًا في Report94، من:

`async function _showLoadingDetails(code) {`

حتى آخر `}` للدالة مباشرة قبل:

`// ==================== DELIVERY ====================`

### Assembly

`FULL MAIN2 ASSEMBLY = BLOCKED UNTIL OWNER APPLIES 2 EXACT MAIN7 SURGERIES`

لا يجوز تشغيل Assembly لمجرد أن Main8 أصبح جاهزًا؛ شرط Main7 ما زال قائمًا.

---

## 5. Production snapshot — لحظة التقرير

تمت مطابقة Production مباشرة قبل كتابة الحالة النهائية:

`2026-09-08 13:48:15.956937+00 UTC`

- companies = 1
- branches = 2
- users = 24
- items = 17
- stock_branches = 20
- orders = 0
- order_details = 0
- runsheets = 0
- run_sheet_details = 0
- stock_vouchers = 0
- inventory_log = 3
- inventory_counts = 0
- inventory_count_details = 0

---

## 6. Production repair executed in this session

### Defect ثابت
`public.get_balance_sheet_data(date)` كان `SECURITY DEFINER` ويقرأ `chart_of_accounts` دون `company_id` filter.

هذا كان يخرق Tenant Isolation في مسار مالي حساس.

### الإصلاح المنفذ
تم تنفيذ:

`v_company_id := app_private.current_user_company_id()`

ثم إضافة:

`ca.company_id = v_company_id`

في كل استعلامات:

- assets
- liabilities
- equity

كما تم ضبط EXECUTE بحيث لا يكون متاحًا للـanon/public.

### Production migration
`20260908134417_fix_balance_sheet_company_scope_20260908`

### Git canonical migration
تم تسجيل الإصلاح في:

`supabase/migrations/20260908134417_fix_balance_sheet_company_scope_20260908.sql`

### Audit
تم توثيق الإصلاح في `audit_log` باستخدام Action مسموح به من الـschema:

`action = 'update'`

ولم يتم تغيير `audit_log_action_check`.

---

## 7. Main8 — النتيجة الجنائية

### النتيجة الأساسية
`Current/PWA/main2/main8.md` الحالي ليس متوافقًا بالكامل مع Production Financial Contract الحالي.

الخلل ليس في فكرة وحدة المالية نفسها، وإنما في بقايا implementation قديمة داخل Parent Fragment، بينما `accountant.html` والـEdge/RPC layer الحديث انتقلوا إلى:

- company-scoped reads/writes
- UUID-based treasury/account identity
- explicit operation identity
- delegated posting cores

### ما ثبت بالفعل

1. `save-receipt-voucher` Production v7 يطلب:
   - `header.operationId`
   - `header.treasuryId` = Treasury UUID
   - `header.cashAccountId` = Account UUID
   - `header.offsetAccountId` = Account UUID
   - `lines[]`

2. `save-payment-voucher` Production v5 يطلب نفس النمط للقبض/الصرف.

3. `save-transfer-voucher` Production v4 يطلب:
   - `operationId`
   - `sourceTreasuryId`
   - `targetTreasuryId`
   - `sourceAccountId`
   - `targetAccountId`
   - `amount`

4. `treasury` يحتوي `company_id` إلزاميًا وله UNIQUE على:
   `company_id + account_code`

5. `chart_of_accounts` يحتوي `company_id` إلزاميًا وله UNIQUE على:
   `company_id + account_code`

6. `chart_of_accounts.parent_account_id` هو UUID ويشير إلى `chart_of_accounts.id`.

7. `budgets` لا يحمل `company_id`، لكن RLS يربطه بأمان بحساب في `chart_of_accounts` تابع للشركة الحالية؛ لذلك لم يتم تغيير هذا العقد دون حاجة مثبتة.

8. `cost_centers` حاليًا Global في schema ولا يحتوي `company_id`؛ لذلك لم تتم إضافة company filter عليه بالتخمين.

---

# 8. MAIN8 EXACT SURGERIES — OWNER ACTIONS

> **قاعدة التنفيذ:** لا تعدل أي شيء خارج المقطع المحدد. كل استبدال أدناه كامل.

## M8-01 — إضافة Company Context helper

**الموضع الحالي:** بعد الدالة `_esc(...)` مباشرة وقبل:

`var _cache = { loaded: false, accountsTree: [], accountsFlat: [], treasury: [] };`

**ابحث عن السطر الكامل:**

`    var _cache = { loaded: false, accountsTree: [], accountsFlat: [], treasury: [] };`

**أضف فوقه مباشرة:**

```javascript
    function _companyId() {
        var id = null;
        if (typeof RW_STATE !== 'undefined' && RW_STATE && RW_STATE.app) {
            id = RW_STATE.app.companyId || null;
        }
        if (!id && typeof RW_STATE !== 'undefined' && RW_STATE && RW_STATE.user) {
            id = RW_STATE.user.companyId || null;
        }
        if (!id) throw new Error('سياق الشركة غير محدد');
        return id;
    }
```

---

## M8-02 — `_loadAllData()`

**الموضع الحالي:** بداية الملف، الدالة `_loadAllData` في أول 40 سطر تقريبًا.

**ابحث عن بداية الدالة كاملة:**

`    function _loadAllData(callback) {`

**احذف الدالة كاملة حتى `}` الأخيرة التي تسبق:**

`    function _refreshCache() { _cache.loaded = false; }`

**واستبدلها كاملة بـ:**

```javascript
    function _loadAllData(callback) {
        if (_cache.loaded) { if (callback) callback(); return; }
        var companyId;
        try {
            companyId = _companyId();
        } catch (e) {
            _showToast(e.message || 'سياق الشركة غير محدد', 'error');
            if (callback) callback();
            return;
        }

        _showLoader('جاري تحميل البيانات المالية...');
        Promise.all([
            supabase.from('treasury')
                .select('*')
                .eq('company_id', companyId)
                .eq('is_active', true)
                .order('account_code'),
            supabase.from('chart_of_accounts')
                .select('*')
                .eq('company_id', companyId)
                .eq('is_active', true)
                .order('account_code'),
            supabase.from('cost_centers')
                .select('*')
                .eq('is_active', true)
                .order('code')
        ]).then(function(results) {
            var tRes = results[0], aRes = results[1], ccRes = results[2];
            if (tRes.error) throw tRes.error;
            if (aRes.error) throw aRes.error;
            if (ccRes.error) throw ccRes.error;

            _cache.treasury = tRes.data || [];
            _cache.accountsFlat = aRes.data || [];
            _cache.costCenters = ccRes.data || [];

            var mapById = {}, roots = [];
            for (var i = 0; i < _cache.accountsFlat.length; i++) {
                var a = _cache.accountsFlat[i];
                mapById[a.id] = {
                    id: a.account_code,
                    uuid: a.id,
                    name: a.account_name,
                    type: a.account_type,
                    parent: a.parent_account_id,
                    children: []
                };
            }
            for (var code in mapById) {
                if (mapById.hasOwnProperty(code)) {
                    var node = mapById[code];
                    if (node.parent && mapById[node.parent]) {
                        mapById[node.parent].children.push(node);
                    } else {
                        roots.push(node);
                    }
                }
            }
            _cache.accountsTree = roots;
            _cache.loaded = true;
            _hideLoader();
            if (callback) callback();
        }).catch(function(e) {
            console.error('RW_Finance load error:', e);
            _hideLoader();
            _showToast(e.message || 'فشل تحميل البيانات المالية', 'error');
        });
    }
```

**لماذا:** نفس الوظيفة الحالية محفوظة، لكن القراءة أصبحت Company-scoped، ومعالجة الأخطاء واضحة، وبناء شجرة الحسابات أصبح يعتمد على UUID الحقيقي مع إبقاء `account_code` كمعرف العرض/التعديل.

---

## M8-03 — `_buildAccountTree(nodes, level)`

**الموضع الحالي:** مباشرة بعد `_renderAccounts()`.

**ابحث عن بداية الدالة:**

`    function _buildAccountTree(nodes, level) {`

**احذف الدالة كاملة حتى `}` الأخيرة قبل:**

`    function _filterAccounts() {`

**واستبدلها كاملة بـ:**

```javascript
    function _buildAccountTree(nodes, level) {
        if (!nodes || !nodes.length) return '<div class="text-center py-8 text-gray-500">لا توجد حسابات</div>';
        var html = '';
        for (var i = 0; i < nodes.length; i++) {
            var node = nodes[i], hasChildren = node.children && node.children.length > 0;
            html += '<div class="border-b border-gray-100 py-2" style="margin-right:' + (level * 20) + 'px">' +
                '<div class="flex items-center justify-between hover:bg-gray-50 cursor-pointer rounded px-2 py-1" onclick="RW_Finance._openAccountDialog(\'' + _esc(node.id) + '\')">' +
                '<div class="flex items-center"><i class="fa-solid fa-' + (hasChildren ? 'folder text-yellow-500' : 'file-invoice text-gray-400') + ' ml-2"></i>' +
                '<span class="font-bold">' + _esc(node.name) + '</span>' +
                '<span class="text-xs text-gray-400 mr-2">(' + _esc(node.id) + ')</span></div></div>';
            if (hasChildren) html += '<div>' + _buildAccountTree(node.children, level + 1) + '</div>';
            html += '</div>';
        }
        return html;
    }
```

---

## M8-04 — `_openTreasuryDialog()`

**الموضع الحالي:** بعد `_filterTreasury()`.

**ابحث عن السطر:**

`    function _openTreasuryDialog() {`

**احذف الدالة كاملة حتى `}` الأخيرة التي تسبق:**

`    function _editTreasury(code) {`

**واستبدلها بـ:**

```javascript
    function _openTreasuryDialog() {
        Swal.fire({
            title: 'إضافة خزينة / بنك',
            html: '<div class="text-right"><div class="mb-4"><label class="block text-sm font-bold">الاسم *</label><input id="tr-name" class="swal2-input w-full"></div><div class="mb-4"><label class="block text-sm font-bold">النوع</label><select id="tr-type" class="swal2-input"><option value="Cash">خزينة</option><option value="Bank">بنك</option></select></div><div class="mb-4"><label class="block text-sm font-bold">الرصيد الافتتاحي</label><input id="tr-balance" type="number" step="0.01" value="0" class="swal2-input"></div></div>',
            showCancelButton: true,
            confirmButtonText: 'حفظ',
            preConfirm: function() {
                var name = document.getElementById('tr-name').value.trim();
                if (!name) { Swal.showValidationMessage('الاسم مطلوب'); return false; }
                var balance = parseFloat(document.getElementById('tr-balance').value) || 0;
                return {
                    company_id: _companyId(),
                    account_code: 'CASH-' + Date.now().toString().slice(-5),
                    account_name: name,
                    type: document.getElementById('tr-type').value,
                    opening_balance: balance,
                    current_balance: balance,
                    is_active: true
                };
            }
        }).then(function(r) {
            if (!r.isConfirmed) return;
            _showLoader('جاري حفظ الخزينة...');
            supabase.from('treasury').insert(r.value).then(function(res) {
                if (res.error) throw res.error;
                _refreshCache();
                renderSubTab('treasury');
                _showToast('تمت الإضافة', 'success');
            }).catch(function(e) {
                _showToast(e.message || 'فشل الحفظ', 'error');
            }).finally(_hideLoader);
        });
    }
```

---

## M8-05 — `_editTreasury(code)`

**ابحث عن بداية الدالة:**

`    function _editTreasury(code) {`

**احذفها كاملة حتى `}` الأخيرة قبل:**

`    // ==================== دليل الحسابات ====================`

**واستبدلها بـ:**

```javascript
    function _editTreasury(code) {
        var item = null;
        for (var i = 0; i < _cache.treasury.length; i++) {
            if (_cache.treasury[i].account_code === code) { item = _cache.treasury[i]; break; }
        }
        if (!item) { _showToast('غير موجود', 'error'); return; }

        Swal.fire({
            title: 'تعديل ' + item.account_name,
            html: '<div class="text-right"><div class="mb-4"><label class="block text-sm font-bold">الاسم</label><input id="tr-name" class="swal2-input" value="' + _esc(item.account_name) + '"></div><div class="mb-4"><label class="block text-sm font-bold">النوع</label><select id="tr-type" class="swal2-input"><option value="Cash"' + (item.type === 'Cash' ? ' selected' : '') + '>خزينة</option><option value="Bank"' + (item.type === 'Bank' ? ' selected' : '') + '>بنك</option></select></div><div class="mb-4"><label class="block text-sm font-bold">الرصيد الافتتاحي</label><input id="tr-balance" type="number" step="0.01" value="' + item.opening_balance + '" class="swal2-input"></div></div>',
            showCancelButton: true,
            confirmButtonText: 'حفظ',
            showDenyButton: true,
            denyButtonText: 'حذف',
            denyButtonColor: '#ef4444',
            preConfirm: function() {
                var name = document.getElementById('tr-name').value.trim();
                if (!name) { Swal.showValidationMessage('الاسم مطلوب'); return false; }
                return {
                    account_name: name,
                    type: document.getElementById('tr-type').value,
                    opening_balance: parseFloat(document.getElementById('tr-balance').value) || 0,
                    current_balance: parseFloat(document.getElementById('tr-balance').value) || 0,
                    updated_at: new Date().toISOString()
                };
            }
        }).then(function(r) {
            if (r.isConfirmed) {
                _showLoader('جاري الحفظ...');
                supabase.from('treasury')
                    .update(r.value)
                    .eq('id', item.id)
                    .eq('company_id', _companyId())
                    .then(function(res) {
                        if (res.error) throw res.error;
                        _refreshCache(); renderSubTab('treasury'); _showToast('تم التعديل', 'success');
                    }).catch(function(e) { _showToast(e.message || 'فشل', 'error'); })
                    .finally(_hideLoader);
            } else if (r.isDenied) {
                Swal.fire({ title: 'تأكيد الحذف', text: 'حذف ' + item.account_name + '؟', icon: 'warning', showCancelButton: true, confirmButtonColor: '#ef4444', confirmButtonText: 'حذف' }).then(function(dr) {
                    if (!dr.isConfirmed) return;
                    _showLoader('جاري الحذف...');
                    supabase.from('treasury')
                        .delete()
                        .eq('id', item.id)
                        .eq('company_id', _companyId())
                        .then(function(res) {
                            if (res.error) throw res.error;
                            _refreshCache(); renderSubTab('treasury'); _showToast('تم الحذف', 'success');
                        }).catch(function(e) { _showToast(e.message || 'فشل', 'error'); })
                        .finally(_hideLoader);
                });
            }
        });
    }
```

---

## M8-06 — `_openAccountDialog(editId)`

**الموضع الحالي:** الدالة التي تبدأ تقريبًا بعد `_filterAccounts()`.

**ابحث عن:**

`    function _openAccountDialog(editId) {`

**احذف الدالة كاملة حتى `}` الأخيرة التي تسبق:**

`    function _seedAccounts() {`

**واستبدلها بـ:**

```javascript
    function _openAccountDialog(editId) {
        var item = null;
        if (editId) {
            for (var i = 0; i < _cache.accountsFlat.length; i++) {
                if (_cache.accountsFlat[i].account_code === editId) { item = _cache.accountsFlat[i]; break; }
            }
        }
        var isEdit = !!item;
        var companyId = _companyId();
        var types = ['asset:أصول', 'liability:خصوم', 'equity:حقوق ملكية', 'revenue:إيرادات', 'expense:مصروفات'];
        var typeOptions = types.map(function(t) {
            var v = t.split(':');
            return '<option value="' + v[0] + '"' + (isEdit && item.account_type === v[0] ? ' selected' : '') + '>' + v[1] + '</option>';
        }).join('');
        var parentOptions = _cache.accountsFlat.filter(function(a) {
            return !isEdit || a.account_code !== editId;
        }).map(function(a) {
            return '<option value="' + _esc(a.id) + '"' + (isEdit && item.parent_account_id === a.id ? ' selected' : '') + '>' + _esc(a.account_name) + ' (' + _esc(a.account_code) + ')</option>';
        }).join('');

        Swal.fire({
            title: isEdit ? 'تعديل حساب' : 'إضافة حساب جديد',
            html: '<div class="text-right"><div class="mb-3"><label class="block text-sm font-bold">كود الحساب</label><input id="acc-code" class="swal2-input" value="' + (isEdit ? _esc(item.account_code) : '') + '" readonly></div><div class="mb-3"><label class="block text-sm font-bold">اسم الحساب *</label><input id="acc-name" class="swal2-input" value="' + (isEdit ? _esc(item.account_name) : '') + '"></div><div class="mb-3"><label class="block text-sm font-bold">النوع</label><select id="acc-type" class="swal2-input">' + typeOptions + '</select></div><div class="mb-3"><label class="block text-sm font-bold">الحساب الأب</label><select id="acc-parent" class="swal2-input"><option value="">لا يوجد</option>' + parentOptions + '</select></div></div>',
            showCancelButton: true,
            confirmButtonText: isEdit ? 'حفظ' : 'إضافة',
            showDenyButton: isEdit,
            denyButtonText: 'حذف',
            denyButtonColor: '#ef4444',
            preConfirm: function() {
                var name = document.getElementById('acc-name').value.trim();
                if (!name) { Swal.showValidationMessage('الاسم مطلوب'); return false; }
                var accountType = document.getElementById('acc-type').value;
                return {
                    company_id: companyId,
                    account_code: document.getElementById('acc-code').value.trim(),
                    account_name: name,
                    account_type: accountType,
                    parent_account_id: document.getElementById('acc-parent').value || null,
                    normal_balance: ['liability', 'equity', 'revenue'].indexOf(accountType) !== -1 ? 'credit' : 'debit',
                    is_active: true
                };
            }
        }).then(function(r) {
            if (r.isConfirmed) {
                _showLoader('جاري حفظ الحساب...');
                var payload = r.value;
                var promise = isEdit
                    ? supabase.from('chart_of_accounts').update({ account_name: payload.account_name, account_type: payload.account_type, parent_account_id: payload.parent_account_id, normal_balance: payload.normal_balance, is_active: true, updated_at: new Date().toISOString() }).eq('id', item.id).eq('company_id', companyId)
                    : supabase.from('chart_of_accounts').insert(payload);
                promise.then(function(res) {
                    if (res.error) throw res.error;
                    _refreshCache(); renderSubTab('accounts'); _showToast('تم الحفظ', 'success');
                }).catch(function(e) { _showToast(e.message || 'فشل الحفظ', 'error'); })
                  .finally(_hideLoader);
            } else if (r.isDenied) {
                Swal.fire({ title: 'تأكيد الحذف', text: 'حذف ' + item.account_name + '؟', icon: 'warning', showCancelButton: true, confirmButtonColor: '#ef4444', confirmButtonText: 'حذف' }).then(function(dr) {
                    if (!dr.isConfirmed) return;
                    _showLoader('جاري الحذف...');
                    supabase.from('chart_of_accounts').delete().eq('id', item.id).eq('company_id', companyId).then(function(res) {
                        if (res.error) throw res.error;
                        _refreshCache(); renderSubTab('accounts'); _showToast('تم الحذف', 'success');
                    }).catch(function(e) { _showToast(e.message || 'فشل الحذف', 'error'); })
                      .finally(_hideLoader);
                });
            }
        });
    }
```

---

## M8-07 — `_seedAccounts()`

**الموضع الحالي:** مباشرة بعد `_openAccountDialog()`.

**ابحث عن بداية الدالة:**

`    function _seedAccounts() {`

**احذفها كاملة حتى `}` الأخيرة التي تسبق:**

`    // ==================== القيود اليومية ====================`

**واستبدلها بـ:**

```javascript
    async function _seedAccounts() {
        var definitions = [
            ['1', 'الأصول', 'asset', null, 'debit'], ['11', 'الأصول الثابتة', 'asset', '1', 'debit'], ['12', 'الأصول المتداولة', 'asset', '1', 'debit'],
            ['121', 'النقدية (الخزينة الرئيسية)', 'asset', '12', 'debit'], ['123', 'العملاء (ذمم مدينة)', 'asset', '12', 'debit'], ['124', 'المخزون السلعي', 'asset', '12', 'debit'],
            ['2', 'الخصوم', 'liability', null, 'credit'], ['21', 'الخصوم المتداولة', 'liability', '2', 'credit'], ['211', 'الموردون (ذمم دائنة)', 'liability', '21', 'credit'], ['216', 'ضريبة القيمة المضافة المستحقة', 'liability', '21', 'credit'],
            ['3', 'حقوق الملكية', 'equity', null, 'credit'], ['31', 'رأس المال', 'equity', '3', 'credit'],
            ['4', 'الإيرادات', 'revenue', null, 'credit'], ['41', 'إيرادات المبيعات', 'revenue', '4', 'credit'],
            ['5', 'المصروفات', 'expense', null, 'debit'], ['51', 'تكلفة المبيعات', 'expense', '5', 'debit']
        ];
        _showLoader('جاري تهيئة دليل الحسابات...');
        try {
            var companyId = _companyId();
            var codeMap = {};
            for (var i = 0; i < definitions.length; i++) {
                var d = definitions[i];
                var existingRes = await supabase.from('chart_of_accounts').select('id').eq('company_id', companyId).eq('account_code', d[0]).maybeSingle();
                if (existingRes.error) throw existingRes.error;
                if (existingRes.data) {
                    codeMap[d[0]] = existingRes.data.id;
                    continue;
                }
                var parentId = d[3] ? (codeMap[d[3]] || null) : null;
                var res = await supabase.from('chart_of_accounts').insert({
                    company_id: companyId,
                    account_code: d[0],
                    account_name: d[1],
                    account_type: d[2],
                    parent_account_id: parentId,
                    normal_balance: d[4],
                    is_active: true
                }).select('id').single();
                if (res.error) throw res.error;
                codeMap[d[0]] = res.data.id;
            }
            for (var j = 0; j < definitions.length; j++) {
                var x = definitions[j], p = x[3] ? (codeMap[x[3]] || null) : null;
                var u = await supabase.from('chart_of_accounts').update({ parent_account_id: p }).eq('id', codeMap[x[0]]).eq('company_id', companyId);
                if (u.error) throw u.error;
            }
            _refreshCache();
            renderSubTab('accounts');
            _showToast('تمت التهيئة', 'success');
        } catch (e) {
            _showToast(e.message || 'فشلت التهيئة', 'error');
        } finally {
            _hideLoader();
        }
    }
```

---

## M8-08 — `_renderReceipts()` و`_renderPayments()`

### Receipt
ابحث عن السطر الحالي الذي يحتوي على:

`supabase.from('cash_box').select('*').eq('type', 'Receipt')`

**احذف السطر/السلسلة الكاملة واستبدلها بـ:**

```javascript
        supabase.from('cash_box').select('*').eq('company_id', _companyId()).eq('type', 'Receipt').order('voucher_date', { ascending: false }).then(function(r) {
```

وأضف مباشرة بعد بداية `.then(function(r) {`:

```javascript
            if (r.error) throw r.error;
```

### Payment
ابحث عن السطر الحالي الذي يحتوي على:

`supabase.from('cash_box').select('*').eq('type', 'Payment')`

**استبدله بـ:**

```javascript
        supabase.from('cash_box').select('*').eq('company_id', _companyId()).eq('type', 'Payment').order('voucher_date', { ascending: false }).then(function(r) {
```

وأضف بعد بداية `.then(function(r) {`:

```javascript
            if (r.error) throw r.error;
```

---

## M8-09 — `_newReceipt()`

**ابحث عن:**

`    function _newReceipt() {`

**احذف الدالة كاملة حتى `}` الأخيرة قبل:**

`    function _addReceiptLine() {`

**واستبدلها بـ:**

```javascript
    function _newReceipt() {
        var content = byId('finance-content'); if (!content) return;
        var treasuryOptions = _cache.treasury.map(function(t) {
            return '<option value="' + _esc(t.id) + '">' + _esc(t.account_name) + ' (' + _esc(t.account_code) + ')</option>';
        }).join('');
        var accountOptions = _cache.accountsFlat.map(function(a) {
            return '<option value="' + _esc(a.id) + '">' + _esc(a.account_name) + ' (' + _esc(a.account_code) + ')</option>';
        }).join('');
        var html = '<div class="bg-white rounded-2xl shadow-sm border p-4"><div class="flex justify-between items-center mb-4"><h2 class="text-xl font-bold"><i class="fa-solid fa-arrow-down ml-2 text-green-600"></i>سند قبض جديد</h2><button type="button" onclick="RW_Finance.renderSubTab(\\'receipts\\')" class="text-gray-500 hover:text-gray-700"><i class="fa-solid fa-xmark text-xl"></i></button></div><div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4"><div><label class="block text-sm font-bold">التاريخ</label><input type="date" id="rcpt-date" class="border rounded-lg p-2 w-full" value="' + new Date().toISOString().slice(0,10) + '"></div><div><label class="block text-sm font-bold">الخزينة</label><select id="rcpt-cashbox" class="border rounded-lg p-2 w-full">' + treasuryOptions + '</select></div><div><label class="block text-sm font-bold">الحساب المقابل</label><select id="rcpt-main-account" class="border rounded-lg p-2 w-full"><option value="">اختر الحساب</option>' + accountOptions + '</select></div></div><div class="mb-4"><h4 class="font-bold mb-2">بنود السند</h4><div id="rcpt-lines"></div><button type="button" onclick="RW_Finance._addReceiptLine()" class="mt-2 text-green-600 font-bold"><i class="fa-solid fa-plus-circle ml-1"></i> إضافة بند</button></div><div class="p-3 bg-gray-50 rounded-lg flex justify-between mb-4"><span>الإجمالي: <span id="rcpt-total">0.00</span></span></div><div class="flex justify-end gap-3"><button type="button" onclick="RW_Finance.renderSubTab(\\'receipts\\')" class="px-4 py-2 border rounded-lg">إلغاء</button><button type="button" onclick="RW_Finance._saveReceipt()" class="px-6 py-2 bg-green-600 text-white rounded-lg font-bold"><i class="fa-solid fa-check ml-1"></i> حفظ</button></div></div>';
        safeHTML(content, html);
        _addReceiptLine();
    }
```

---

## M8-10 — `_saveReceipt()`

**ابحث عن بداية الدالة:**

`    async function _saveReceipt() {`

**احذف الدالة كاملة حتى `}` الأخيرة التي تسبق:**

`    function _renderPayments() {`

**واستبدلها بـ:**

```javascript
    async function _saveReceipt() {
        var host = byId('finance-content');
        var lines = [];
        document.querySelectorAll('.rcpt-line').forEach(function(l) {
            var account = l.querySelector('.rcpt-line-account').value.trim();
            var amount = parseFloat(l.querySelector('.rcpt-line-amount').value) || 0;
            if (account && amount > 0) {
                lines.push({ accountName: account, description: l.querySelector('.rcpt-line-desc').value || '', amount: amount });
            }
        });
        if (!lines.length) { _showToast('أضف بنداً', 'warning'); return; }

        var treasuryId = byId('rcpt-cashbox').value;
        var offsetAccountId = byId('rcpt-main-account').value;
        var cashAccount = null;
        for (var i = 0; i < _cache.accountsFlat.length; i++) {
            if (_cache.accountsFlat[i].account_code === '121') { cashAccount = _cache.accountsFlat[i]; break; }
        }
        if (!treasuryId || !offsetAccountId || !cashAccount) {
            _showToast('بيانات الخزينة أو الحساب المقابل غير مكتملة', 'error');
            return;
        }

        var op = host.dataset.receiptOperationId || (window.crypto && crypto.randomUUID ? crypto.randomUUID() : String(Date.now()) + '-' + Math.random());
        host.dataset.receiptOperationId = op;
        _showLoader('جاري حفظ سند القبض...');
        try {
            var ses = await supabase.auth.getSession();
            var token = ses.data && ses.data.session ? ses.data.session.access_token : null;
            if (!token) throw new Error('انتهت الجلسة');
            var selected = byId('rcpt-main-account').selectedOptions[0];
            var payload = {
                header: {
                    operationId: op,
                    treasuryId: treasuryId,
                    cashAccountId: cashAccount.id,
                    offsetAccountId: offsetAccountId,
                    date: byId('rcpt-date').value,
                    reference: null,
                    mainAccountName: selected ? selected.textContent : null,
                    notes: ''
                },
                lines: lines
            };
            var res = await fetch(RW_SUPABASE_URL + '/functions/v1/save-receipt-voucher', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token },
                body: JSON.stringify(payload)
            });
            var json = await res.json();
            if (!res.ok || !json || json.success === false) throw new Error((json && (json.error || json.msg)) || 'فشل الحفظ');
            delete host.dataset.receiptOperationId;
            _showToast(json.duplicate ? 'السند موجود بالفعل ولم يُكرر.' : 'تم الحفظ', 'success');
            renderSubTab('receipts');
        } catch (e) {
            _showToast(e.message || 'فشل الحفظ', 'error');
        } finally {
            _hideLoader();
        }
    }
```

---

## M8-11 — `_newPayment()` و`_savePayment()`

نفذ نفس النمط السابق، لكن بأسماء العناصر الموجودة حاليًا:

- `pmt-cashbox` يجب أن يحمل `treasury.id` وليس `account_code`.
- `pmt-main-account` يجب أن يحمل `chart_of_accounts.id` وليس نص الحساب.
- `operationId` يجب أن يكون ثابتًا أثناء محاولة الحفظ.
- Payload يجب أن يكون:

```javascript
{
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
}
```

والـendpoint:

`/functions/v1/save-payment-voucher`

> لا تستخدم `cashBoxId` بعد هذا التعديل.

---

## M8-12 — `_renderTransfers()`

**ابحث عن:**

`    function _renderTransfers() {`

وفي داخله ابحث عن:

`supabase.from('cash_box').select('*').in('type', ['Transfer-Out', 'Transfer-In'])`

**استبدله كاملًا بـ:**

```javascript
        supabase.from('cash_box').select('*').eq('company_id', _companyId()).in('type', ['Transfer-Out', 'Transfer-In']).order('voucher_date', { ascending: false }).then(function(r) {
            if (r.error) throw r.error;
```

ولا تغيّر بقية Business Flow للتحويلات في هذه الجراحة.

---

## M8-13 — `_newTransfer()`

الـselects الحالية تستخدم `account_code`. هذا خطأ لأن Production Transfer Edge يحتاج UUIDs.

ابحث داخل `_newTransfer()` عن:

`<select id="trf-from"`

و`<select id="trf-to"`

واجعل قيم الخيارات هي `t.id` من `_cache.treasury`.

ثم ابحث عن حقلي الحسابين، واجعل قيم الخيارات هي `a.id` من `_cache.accountsFlat`.

الصيغة الدقيقة لكل Treasury option:

```javascript
<option value="' + _esc(t.id) + '">' + _esc(t.account_name) + ' (' + _esc(t.account_code) + ')</option>
```

والصيغة الدقيقة لكل Account option:

```javascript
<option value="' + _esc(a.id) + '">' + _esc(a.account_name) + ' (' + _esc(a.account_code) + ')</option>
```

---

## M8-14 — `_saveTransfer()`

**ابحث عن بداية الدالة:**

`    async function _saveTransfer() {`

**احذف الدالة كاملة حتى `}` الأخيرة التي تسبق:**

`    // ==================== التقارير المالية ====================`

**واستبدلها بـ:**

```javascript
    async function _saveTransfer() {
        var fromId = byId('trf-from').value;
        var toId = byId('trf-to').value;
        var sourceAccountId = byId('trf-source-account').value;
        var targetAccountId = byId('trf-target-account').value;
        var amount = parseFloat(byId('trf-amount').value) || 0;
        if (!fromId || !toId || fromId === toId || !sourceAccountId || !targetAccountId || amount <= 0) {
            _showToast('بيانات التحويل غير صحيحة أو غير مكتملة', 'warning');
            return;
        }

        var host = byId('finance-content');
        var op = host.dataset.transferOperationId || (window.crypto && crypto.randomUUID ? crypto.randomUUID() : String(Date.now()) + '-' + Math.random());
        host.dataset.transferOperationId = op;
        _showLoader('جاري تنفيذ التحويل...');
        try {
            var ses = await supabase.auth.getSession();
            var token = ses.data && ses.data.session ? ses.data.session.access_token : null;
            if (!token) throw new Error('انتهت الجلسة');
            var res = await fetch(RW_SUPABASE_URL + '/functions/v1/save-transfer-voucher', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token },
                body: JSON.stringify({
                    operationId: op,
                    sourceTreasuryId: fromId,
                    targetTreasuryId: toId,
                    sourceAccountId: sourceAccountId,
                    targetAccountId: targetAccountId,
                    amount: amount,
                    transferDate: new Date().toISOString().slice(0, 10),
                    reference: null,
                    notes: ''
                })
            });
            var json = await res.json();
            if (!res.ok || !json || json.success === false) throw new Error((json && (json.error || json.msg)) || 'فشل تنفيذ التحويل');
            delete host.dataset.transferOperationId;
            _showToast(json.duplicate ? 'التحويل موجود بالفعل ولم يُكرر.' : 'تم التحويل', 'success');
            renderSubTab('transfers');
        } catch (e) {
            _showToast(e.message || 'فشل التنفيذ', 'error');
        } finally {
            _hideLoader();
        }
    }
```

---

## 9. ما لا نغيّره في Main8

لا تغير في هذه المرحلة:

- `_saveJournalEntry()` من حيث عقد Edge الحالي؛ العملية لديها `operationId` بالفعل.
- `_trialBalance()`.
- `_profitLoss()`.
- `_loadBudgetsList()`.
- `_editBudget()` من حيث Company model الحالي؛ RLS يثبت الربط عن طريق `account_id` داخل `chart_of_accounts`.
- `cost_centers` إلى Company-scoped؛ هذا غير مثبت في schema الحالية.
- أي Business Flow متعلق بالمخزون أو التسليم أو الرانشيت داخل Main8؛ ليس جزءًا من مسؤولية الملف.

---

## 10. أخطاء ظهرت أثناء الجلسة

### الخطأ الأول
محاولة تسجيل Production repair داخل `audit_log` باستخدام Action جديد:

`CTO_PRODUCTION_REPAIR`

فشل بسبب:

`audit_log_action_check`

المسموح فقط:

`create / update / delete / login / logout / failed_login`

تم تصحيح العملية باستخدام:

`action = 'update'`

دون تعديل الـconstraint.

### الخطأ الثاني في الاختبارات التاريخية
ظهر أن بعض اختبارات `receive_purchase` السابقة كانت تبني idempotency على fingerprint يعتمد على `qty_received_before`، وهو غير مناسب كهوية عملية دائمة من دون Client Operation ID ثابت. هذا مسجل كملحوظة تاريخية وليس جزءًا من إصلاح Main8 الحالي.

---

## 11. Production financial contract بعد الإصلاح

ثبت من Production أن:

- `post_journal_entry` هو Core للقيود.
- `post_cash_receipt_atomic` هو Core للقبض.
- `post_cash_payment_atomic` هو Core للصرف.
- `post_treasury_transfer_atomic` هو Core للتحويل.
- `get_trial_balance` / `get_profit_loss` / `get_pnl_by_cost_center` تستخدم Company Context.
- `get_balance_sheet` تستخدم Company Context.
- `get_balance_sheet_data` أصبحت أيضًا Company-scoped بعد الإصلاح الحالي.

---

## 12. Closure status

### Closed in this session
`Production get_balance_sheet_data tenant isolation = CLOSED / PRODUCTION DEPLOYED / MIGRATION RECORDED / AUDIT RECORDED`

### Main8
`MAIN8 FINANCE CONTRACT RECONCILIATION = OPEN / OWNER SOURCE SURGERY REQUIRED`

### Main7
`MAIN7 = OPEN / 2 EXACT OWNER SURGERIES REQUIRED`

### Assembly
`FULL MAIN2 ASSEMBLY = BLOCKED`

### Parent Gold/Diamond
`NOT CLOSED`

سبب عدم إعلان Gold/Diamond: Main8 لم يُعدّل يدويًا بعد، وMain7 لديه جراحتان مسجلتان مسبقًا لم تُنفذا بعد.

---

## 13. Final self-audit

### What I Proved
- Report94 موجود وأحدث من Report93، ومصدر Main7 الحالي مثبت.
- CURRENT_STATE_Report94_Update موجود ويثبت الجراحتين اليدويتين.
- `Current/PWA/main2` هو المصدر الصحيح.
- Assembly workflow صحيح ولا يحتاج path correction.
- `accountant.html` الحديث يستخدم Company Context وUUID financial identities وoperation IDs.
- Main8 الحالي يحتوي Consumer Contract Drift حقيقي مع Production financial adapters.
- Production `get_balance_sheet_data` كان به tenant leak وتم إصلاحه فعليًا وتسجيل migration له.

### What I Did Not Prove
- لم يتم تطبيق جراحات Main7 يدويًا.
- لم يتم تطبيق جراحات Main8 يدويًا.
- لم يتم تنفيذ Full Main2 Assembly.
- لم يتم إجراء browser/E2E على Parent بعد إدخال جراحات Main7/Main8.

### What I Fixed
- Production `get_balance_sheet_data` tenant scope.
- Canonical migration file في Git.
- Audit trail للإصلاح.

### What I Initially Missed
- Main8 ليس مجرد UI fragment قديم؛ بعض أجزاءه كانت متأخرة عن الـProduction financial contract الحالي.
- `chart_of_accounts.parent_account_id` UUID بينما Main8 الحالي كان يتعامل معه كـaccount_code.
- Receipt/Payment/Transfer consumers في Main8 لا يطابقون الـEdge payload contract المنشور.

### What Could Still Be Wrong
أي خطأ جديد في Main8 بعد الجراحات لن يُعتبر مغلقًا حتى يتم:

`SOURCE READ → SYNTAX CHECK → ASSEMBLY → BROWSER CHECK → PRODUCTION RECONCILIATION`

### Final confidence
`HIGH` في الأدلة المذكورة أعلاه.
`NOT 100% CLOSED` لأن Main8/Main7 ownership surgeries لم تُنفذ بعد.

### Last Verified Event
`EVENT: MAIN8-FORENSIC-RECONCILIATION-20260908`

