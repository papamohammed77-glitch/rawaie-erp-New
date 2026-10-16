# Report431 — Treasury/Bank Branch Linkage + Production Save Failure Forensic Repair
**Date:** 2026-10-16  
**Production project:** `fiilmooggumokxanwiyx`  
**Scope:** Parent system only, Finance → خزائن وبنوك; owner edits `erp-frontend/companies/company-1/main.html`. Assistant does not edit `main.html` or operational apps.

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** The owner wants every treasury/bank record to support an optional company branch link as groundwork for QR cashier-to-treasury binding. Creating and editing the record must actually persist, while editing metadata must never mutate balances.
- **Architecture Understanding:** Current Mother module `RW_Finance` renders `_openTreasuryDialog` and `_editTreasury`; it previously wrote directly to `public.treasury` through PostgREST. The UI must remain in the Mother file, while durable, company-scoped database operations can be provided by authenticated RPCs.
- **Database Understanding:** Production `treasury` had no `branch_id`; `branches` already has `company_id`, unique `(company_id, branch_code)`, and RLS. `treasury` has RLS and company-scoped policies, but table privileges for `authenticated` were SELECT-only.
- **Historical Understanding:** Current Mother source was compared against `rawaie-erp-review/PWA/main.html`; the historical treasury modal also had no branch field and used direct insert/update. The current implementation had already improved update behavior by protecting balances, so that behavior is retained.
- **Production Understanding:** Fresh live SQL and logs were checked on 2026-10-16. Production logs show `POST /rest/v1/treasury` → HTTP 403 and PostgreSQL `permission denied for table treasury`; the database hint explicitly asks for INSERT privilege. Live grants showed `authenticated INSERT/UPDATE/DELETE=false`, while `SELECT=true`. No broad table write grants were added.
- **Current Understanding:** Latest parent source commit checked: `3f226d5047b998ae14a9684222354924e1a43d31`; its parent is `6f30e2d78aa824ed92a5b3a0607edc8cb68ea9dc`. Current `main.html` blob SHA: `55d23d13e6d421d23e3a7ce57b758b5a03c4ace0`, approximately 32,437 lines. Do not reuse line numbers if the blob changes.
- **Execution Confidence:** High for the production database defect and database repair; UI runtime closure remains pending because the owner must apply and deploy the parent-file patch.

### Confirmed facts

1. The current modal calls `supabase.from('treasury').insert(...)` and `.update(...)`.
2. The current authenticated role lacks INSERT, UPDATE and DELETE table privileges on `public.treasury`; the observed POST failed with 403. RLS policies alone do not grant SQL table privileges.
3. The existing treasury table did not contain a branch column.
4. Production has four active branches for the current company. Existing treasury count is one; its balance and existing cashier-shift linkage must not be altered by this patch.
5. `pos_shifts` already stores both `branch_id` and `treasury_id`; the existing open shift uses the current main branch. The save RPC refuses changing a treasury to a branch that conflicts with recorded POS shift branches.
6. A temporary authenticated-role create → update → delete RPC test completed successfully and the test record was removed; final check returned `fixture_residue=0` and original treasury count remained `1`.

### Conflicts resolved

- **Old UI contract:** direct table writes.
- **Production security contract:** authenticated users have no direct write grants to treasury.
- **Resolution:** keep direct table grants closed; move creation, metadata updates and deletion behind company-scoped SECURITY DEFINER RPCs, all executable by authenticated/service_role only. Do not grant broad UPDATE, because that would permit direct edits to `current_balance`.

## PRODUCTION CHANGES APPLIED

### Migration 1 — `treasury_branch_linkage_and_metadata_rpc_20261016`

- Added nullable `public.treasury.branch_id`.
- Added composite company/branch FK: `(treasury.company_id, treasury.branch_id) → branches(company_id,id)`, preventing cross-company branch assignment.
- Added index `idx_treasury_company_branch`.
- Added `finance_list_treasury_branches(uuid)`: authenticated company-scoped branch list, active branches only.
- Added `finance_save_treasury(uuid,uuid,text,text,numeric,uuid)`: creates a Cash/Bank record or updates only `account_name`, `type`, `branch_id`, `updated_at`. Update does not alter `opening_balance` or `current_balance`. Creation preserves the current Mother contract of initializing both balances from the supplied opening balance; accounting treatment for opening balances was not redesigned in this task.
- Revoked EXECUTE from PUBLIC/anon; granted to authenticated/service_role.
- Applied migration recorded in Supabase as version `20261016194118`.

### Migration 2 — `treasury_delete_company_scoped_rpc_20261016`

- Added `finance_delete_treasury(uuid,uuid)`.
- Refuses deletion when balance is non-zero or there are cash-box, POS-shift, expense, cheque, or bank-statement records.
- Revoked EXECUTE from PUBLIC/anon; granted to authenticated/service_role.
- Applied migration recorded in Supabase as version `20261016194152`.

### Git provenance files

- `supabase/migrations/20261016194118_treasury_branch_linkage_and_metadata_rpc_20261016.sql` — commit `729767eb043b7313593102576340dc8ecf4cb5b1`.
- `supabase/migrations/20261016194152_treasury_delete_company_scoped_rpc_20261016.sql` — commit `fc2e223b4733f0e7f0856929738dc110fce56f85`.

The source files were committed after the live migrations to establish repository provenance. The live database remains the runtime authority.

## SURGICAL OWNER PATCH — DO NOT EDIT OTHER MODULES

**File:** `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`  
**Current blob SHA to verify before editing:** `55d23d13e6d421d23e3a7ce57b758b5a03c4ace0`  
**Module:** `RW_Finance` → خزائن وبنوك.

### Change A — Replace the complete create function

- **Find:** `function _openTreasuryDialog() {`
- **Current location:** approximately line 18081 for the blob SHA above.
- **End marker:** the closing brace immediately before `function _editTreasury(code) {`.
- Replace the complete function with:

```javascript
async function _openTreasuryDialog() {
    var companyId;
    var branchResult;

    try {
        companyId = _companyId();
        branchResult = await supabase.rpc('finance_list_treasury_branches', {
            p_company_id: companyId
        });
        if (branchResult.error) throw branchResult.error;
    } catch (e) {
        _showToast((e && e.message) || 'تعذر تحميل فروع الشركة', 'error');
        return;
    }

    var branches = branchResult.data || [];

    function e(v) {
        return String(v == null ? '' : v)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    var branchOptions = '<option value="">بدون ربط بفرع — حساب على مستوى الشركة</option>';
    branches.forEach(function (b) {
        branchOptions += '<option value="' + e(b.id) + '">' +
            e((b.name || b.branch_code) + ' (' + b.branch_code + ')') +
            '</option>';
    });

    var result = await Swal.fire({
        title: 'إضافة خزينة / بنك',
        width: 720,
        html: '<div class="text-right space-y-3">' +
            '<div><label class="block text-sm font-bold">الاسم *</label>' +
            '<input id="tr-name" class="swal2-input w-full" maxlength="255" placeholder="اسم الخزينة أو البنك"></div>' +
            '<div><label class="block text-sm font-bold">النوع *</label>' +
            '<select id="tr-type" class="swal2-select w-full">' +
            '<option value="Cash">خزينة نقدية</option><option value="Bank">بنك</option>' +
            '</select></div>' +
            '<div><label class="block text-sm font-bold">الفرع</label>' +
            '<select id="tr-branch" class="swal2-select w-full">' + branchOptions + '</select>' +
            '<p class="text-xs text-gray-500 mt-1">اختيار الفرع يحفظ علاقة الحساب بالفرع نفسه، ويتيح استخدام العلاقة لاحقًا في ربط الكاشير.</p></div>' +
            '<div><label class="block text-sm font-bold">الرصيد الافتتاحي</label>' +
            '<input id="tr-balance" type="number" min="0" step="0.01" value="0" class="swal2-input w-full"></div>' +
            '</div>',
        showCancelButton: true,
        confirmButtonText: 'حفظ',
        cancelButtonText: 'إلغاء',
        focusConfirm: false,
        preConfirm: function () {
            var nameEl = document.getElementById('tr-name');
            var typeEl = document.getElementById('tr-type');
            var branchEl = document.getElementById('tr-branch');
            var balanceEl = document.getElementById('tr-balance');
            var name = nameEl ? nameEl.value.trim() : '';
            var type = typeEl ? typeEl.value : '';
            var rawBalance = balanceEl ? balanceEl.value : '0';
            var balance = rawBalance === '' ? 0 : Number(rawBalance);

            if (!name) {
                Swal.showValidationMessage('اسم الخزينة أو البنك مطلوب');
                return false;
            }
            if (type !== 'Cash' && type !== 'Bank') {
                Swal.showValidationMessage('نوع الحساب غير صالح');
                return false;
            }
            if (!Number.isFinite(balance) || balance < 0) {
                Swal.showValidationMessage('الرصيد الافتتاحي يجب أن يكون رقمًا صحيحًا غير سالب');
                return false;
            }

            return {
                account_name: name,
                type: type,
                opening_balance: balance,
                branch_id: branchEl && branchEl.value ? branchEl.value : null
            };
        }
    });

    if (!result.isConfirmed) return;

    _showLoader('جاري حفظ الخزينة / البنك...');
    try {
        var saved = await supabase.rpc('finance_save_treasury', {
            p_company_id: companyId,
            p_treasury_id: null,
            p_account_name: result.value.account_name,
            p_type: result.value.type,
            p_opening_balance: result.value.opening_balance,
            p_branch_id: result.value.branch_id
        });
        if (saved.error) throw saved.error;

        _refreshCache();
        renderSubTab('treasury');
        _showToast('تم حفظ الحساب بنجاح', 'success');
    } catch (e) {
        _showToast((e && e.message) || 'فشل حفظ الخزينة / البنك', 'error');
    } finally {
        _hideLoader();
    }
}
```

### Change B — Replace the complete edit/delete function

- **Find:** `function _editTreasury(code) {`
- **Current location:** approximately line 18114 for the blob SHA above.
- **End marker:** the closing brace immediately before `// ==================== دليل الحسابات ====================`.
- Replace the complete function with:

```javascript
async function _editTreasury(code) {
    var item = null;
    for (var i = 0; i < _cache.treasury.length; i++) {
        if (_cache.treasury[i].account_code === code) {
            item = _cache.treasury[i];
            break;
        }
    }

    if (!item) {
        _showToast('الخزينة أو البنك غير موجود', 'error');
        return;
    }

    var companyId;
    var branchResult;
    try {
        companyId = _companyId();
        branchResult = await supabase.rpc('finance_list_treasury_branches', {
            p_company_id: companyId
        });
        if (branchResult.error) throw branchResult.error;
    } catch (e) {
        _showToast((e && e.message) || 'تعذر تحميل فروع الشركة', 'error');
        return;
    }

    var branches = branchResult.data || [];

    function e(v) {
        return String(v == null ? '' : v)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    var branchOptions = '<option value=""' + (!item.branch_id ? ' selected' : '') +
        '>بدون ربط بفرع — حساب على مستوى الشركة</option>';
    var currentBranchFound = false;

    branches.forEach(function (b) {
        var selected = item.branch_id === b.id;
        if (selected) currentBranchFound = true;
        branchOptions += '<option value="' + e(b.id) + '"' + (selected ? ' selected' : '') + '>' +
            e((b.name || b.branch_code) + ' (' + b.branch_code + ')') +
            '</option>';
    });

    if (item.branch_id && !currentBranchFound) {
        branchOptions += '<option value="' + e(item.branch_id) + '" selected>' +
            'الفرع المرتبط حاليًا غير نشط — اختر فرعًا نشطًا أو أزل الارتباط' +
            '</option>';
    }

    var result = await Swal.fire({
        title: 'تعديل ' + e(item.account_name),
        width: 720,
        html: '<div class="text-right space-y-3">' +
            '<div><label class="block text-sm font-bold">الاسم *</label>' +
            '<input id="tr-name" class="swal2-input w-full" maxlength="255" value="' + e(item.account_name) + '"></div>' +
            '<div><label class="block text-sm font-bold">النوع *</label>' +
            '<select id="tr-type" class="swal2-select w-full">' +
            '<option value="Cash"' + (item.type === 'Cash' ? ' selected' : '') + '>خزينة نقدية</option>' +
            '<option value="Bank"' + (item.type === 'Bank' ? ' selected' : '') + '>بنك</option>' +
            '</select></div>' +
            '<div><label class="block text-sm font-bold">الفرع</label>' +
            '<select id="tr-branch" class="swal2-select w-full">' + branchOptions + '</select>' +
            '<p class="text-xs text-gray-500 mt-1">لا يمكن تغيير الفرع إلى فرع يتعارض مع فروع وردت في سجل الورديات المرتبطة بهذا الحساب.</p></div>' +
            '<div class="grid grid-cols-1 md:grid-cols-2 gap-2">' +
            '<div><label class="block text-sm font-bold">الرصيد الافتتاحي</label>' +
            '<input class="swal2-input w-full" value="' + e(_fmtNum(item.opening_balance)) + '" disabled></div>' +
            '<div><label class="block text-sm font-bold">الرصيد الحالي</label>' +
            '<input class="swal2-input w-full" value="' + e(_fmtNum(item.current_balance)) + '" disabled></div>' +
            '</div>' +
            '<p class="text-xs text-gray-500">تعديل البيانات الأساسية لا يغير أي رصيد مالي.</p>' +
            '</div>',
        showCancelButton: true,
        confirmButtonText: 'حفظ التعديل',
        cancelButtonText: 'إلغاء',
        showDenyButton: true,
        denyButtonText: 'حذف',
        denyButtonColor: '#ef4444',
        preConfirm: function () {
            var nameEl = document.getElementById('tr-name');
            var typeEl = document.getElementById('tr-type');
            var branchEl = document.getElementById('tr-branch');
            var name = nameEl ? nameEl.value.trim() : '';
            var type = typeEl ? typeEl.value : '';

            if (!name) {
                Swal.showValidationMessage('اسم الخزينة أو البنك مطلوب');
                return false;
            }
            if (type !== 'Cash' && type !== 'Bank') {
                Swal.showValidationMessage('نوع الحساب غير صالح');
                return false;
            }

            return {
                account_name: name,
                type: type,
                branch_id: branchEl && branchEl.value ? branchEl.value : null
            };
        }
    });

    if (result.isConfirmed) {
        _showLoader('جاري حفظ التعديل...');
        try {
            var saved = await supabase.rpc('finance_save_treasury', {
                p_company_id: companyId,
                p_treasury_id: item.id,
                p_account_name: result.value.account_name,
                p_type: result.value.type,
                p_opening_balance: Number(item.opening_balance || 0),
                p_branch_id: result.value.branch_id
            });
            if (saved.error) throw saved.error;

            _refreshCache();
            renderSubTab('treasury');
            _showToast('تم تعديل بيانات الحساب دون المساس بالأرصدة', 'success');
        } catch (e) {
            var message = (e && e.message) || 'فشل حفظ التعديل';
            if (message.indexOf('TREASURY_BRANCH_CONFLICT_WITH_POS_SHIFT') !== -1) {
                message = 'لا يمكن ربط الحساب بفرع يتعارض مع سجل ورديات الكاشير المرتبطة به.';
            } else if (message.indexOf('TREASURY_BRANCH_INVALID') !== -1) {
                message = 'الفرع المحدد غير نشط أو لا يتبع الشركة الحالية.';
            }
            _showToast(message, 'error');
        } finally {
            _hideLoader();
        }
    } else if (result.isDenied) {
        var confirmDelete = await Swal.fire({
            title: 'تأكيد الحذف',
            text: 'حذف ' + item.account_name + '؟ لن يُسمح بالحذف إذا كان للحساب رصيد أو حركات أو ورديات مرتبطة.',
            icon: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#ef4444',
            confirmButtonText: 'حذف',
            cancelButtonText: 'إلغاء'
        });

        if (!confirmDelete.isConfirmed) return;

        _showLoader('جاري التحقق والحذف...');
        try {
            var deleted = await supabase.rpc('finance_delete_treasury', {
                p_company_id: companyId,
                p_treasury_id: item.id
            });
            if (deleted.error) throw deleted.error;

            _refreshCache();
            renderSubTab('treasury');
            _showToast('تم حذف الحساب', 'success');
        } catch (e) {
            var deleteMessage = (e && e.message) || 'فشل حذف الحساب';
            if (deleteMessage.indexOf('TREASURY_NONZERO_BALANCE') !== -1) {
                deleteMessage = 'لا يمكن حذف حساب له رصيد غير صفري.';
            } else if (deleteMessage.indexOf('TREASURY_HAS_CASH_HISTORY') !== -1) {
                deleteMessage = 'لا يمكن حذف حساب له حركات نقدية.';
            } else if (deleteMessage.indexOf('TREASURY_HAS_POS_SHIFT_HISTORY') !== -1) {
                deleteMessage = 'لا يمكن حذف حساب مرتبط بورديات كاشير.';
            } else if (deleteMessage.indexOf('TREASURY_HAS_FINANCE_EXPENSE_HISTORY') !== -1 ||
                       deleteMessage.indexOf('TREASURY_HAS_CHEQUE_HISTORY') !== -1 ||
                       deleteMessage.indexOf('TREASURY_HAS_BANK_STATEMENT_HISTORY') !== -1) {
                deleteMessage = 'لا يمكن حذف حساب له سجلات مالية مرتبطة.';
            }
            _showToast(deleteMessage, 'error');
        } finally {
            _hideLoader();
        }
    }
}
```

**Do not change** `_loadAllData`, the finance dispatcher, any balance-posting function, or an operational PWA for this task. `_loadAllData` already uses `select('*')`, so the new `branch_id` is included in the treasury cache without another source edit.

## TESTS EXECUTED / VERIFIED

- [PASS] Live Production schema confirms `treasury.branch_id` exists.
- [PASS] Company-scoped composite FK exists and prevents a treasury from pointing to another company's branch.
- [PASS] Authenticated execution is granted for the three RPCs; anon/PUBLIC execution revoked.
- [PASS] Authenticated direct table INSERT/UPDATE/DELETE remain false; no broad table privilege was added.
- [PASS] Simulated authenticated company user successfully invoked branch-list, create, update and delete RPCs in Production.
- [PASS] Test record removed; `fixture_residue=0`; original company treasury count remains `1`.
- [PASS] The current open POS shift and existing treasury balance were not changed by the test.
- [PASS] Current live source logs confirmed the original 403 root cause.
- [OPEN] Parent UI patch has not yet been applied/deployed by the owner; therefore browser/HTTP E2E for the new modal is not yet proven.
- [OPEN] QR cashier binding is groundwork only; this task adds a treasury↔branch relationship, not a cashier-device pairing protocol.

## SELF-AUDIT FINAL

- **What I Proved:** exact Production 403 cause; missing branch column; missing authenticated write grants; current/historical modal behavior; Production RPC execution and cleanup; no direct write grants required.
- **What I Did Not Prove:** the owner-applied parent HTML is deployed, served artifact parity, browser interaction, or QR pairing runtime.
- **What I Fixed:** Production schema and company-scoped RPC contract; migration provenance files in Git; safe delete contract for the existing modal action.
- **What I Initially Missed:** the main save failure was not a malformed modal alone; the live database had no authenticated write privileges, so adding a branch selector without replacing direct writes would still fail.
- **What Could Still Be Wrong:** owner patch may conflict if the parent source changes after the specified SHA; no browser runtime test is possible until owner applies/deploys the exact replacement.
- **Final Confidence:** high for Production database repair and transactional RPC smoke test; pending for browser UI.
- **Final Closure Status:** `PRODUCTION DB/RPC VERIFIED / GIT MIGRATIONS RECORDED / OWNER SURGICAL PATCH READY / BROWSER E2E OPEN`.
- **Next exact step:** verify the parent file SHA; replace only the two functions above; deploy the parent application; create a zero-balance test treasury assigned to the main branch, edit it, confirm the selected branch persists after reload, then delete the test record and confirm it is absent. Do not create a test cashier shift or change the existing production treasury.
