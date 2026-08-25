# Hytham — Accountant PWA Surgical Replacement

## Target
`Current/PWA/accountant.html`

## Scope
Replace only these functions inside `App`:
- `resolveFinancialContext`
- `resolveActiveTreasury`
- `resolveCashAccount`
- `loadOffsetAccounts`
- `newReceipt`
- `newPayment`

Do not alter any other function.

## Canonical replacements

```javascript
resolveFinancialContext: async function () {
    const {
        data: { user },
        error: authError
    } = await supabase.auth.getUser();

    if (authError || !user || !user.id) {
        throw new Error('INVALID_SESSION');
    }

    const { data: appUser, error: userError } = await supabase
        .from('users')
        .select('company_id,status')
        .eq('auth_id', user.id)
        .maybeSingle();

    if (
        userError ||
        !appUser ||
        !appUser.company_id ||
        (appUser.status && appUser.status !== 'Active')
    ) {
        throw new Error('INVALID_COMPANY_CONTEXT');
    }

    return {
        user: user,
        companyId: appUser.company_id
    };
},

resolveActiveTreasury: async function (companyId) {
    if (!companyId) {
        throw new Error('TREASURY_COMPANY_REQUIRED');
    }

    const { data, error } = await supabase
        .from('treasury')
        .select('id,account_code,current_balance,is_active')
        .eq('company_id', companyId)
        .eq('is_active', true)
        .maybeSingle();

    if (error) {
        throw new Error(error.message || 'TREASURY_LOOKUP_FAILED');
    }

    if (!data) {
        throw new Error('ACTIVE_TREASURY_NOT_CONFIGURED');
    }

    return data;
},

resolveCashAccount: async function (companyId) {
    if (!companyId) {
        throw new Error('CASH_ACCOUNT_COMPANY_REQUIRED');
    }

    const { data, error } = await supabase
        .from('chart_of_accounts')
        .select('id,account_code,account_name,account_type,is_active')
        .eq('company_id', companyId)
        .eq('account_code', '121')
        .eq('is_active', true)
        .maybeSingle();

    if (error) {
        throw new Error(error.message || 'CASH_ACCOUNT_LOOKUP_FAILED');
    }

    if (!data) {
        throw new Error('CASH_ACCOUNT_121_NOT_CONFIGURED');
    }

    return data;
},

loadOffsetAccounts: async function (companyId) {
    if (!companyId) {
        throw new Error('OFFSET_ACCOUNT_COMPANY_REQUIRED');
    }

    const { data, error } = await supabase
        .from('chart_of_accounts')
        .select('id,account_code,account_name,account_type,is_active')
        .eq('company_id', companyId)
        .eq('is_active', true)
        .order('account_code', { ascending: true });

    if (error) {
        throw new Error(error.message || 'OFFSET_ACCOUNT_LOOKUP_FAILED');
    }

    return Array.isArray(data) ? data : [];
},

newReceipt: async function () {
    var s = this;

    try {
        Swal.fire({
            title: 'جاري تحميل الحسابات...',
            allowOutsideClick: false,
            allowEscapeKey: false,
            didOpen: function () { Swal.showLoading(); }
        });

        var context = await s.resolveFinancialContext();
        var treasury = await s.resolveActiveTreasury(context.companyId);
        var cashAccount = await s.resolveCashAccount(context.companyId);
        var accounts = await s.loadOffsetAccounts(context.companyId);

        Swal.close();

        var accountOptions = '<option value="">اختر الحساب المقابل</option>';
        accounts.forEach(function (account) {
            accountOptions +=
                '<option value="' + account.id + '">' +
                String(account.account_code || '') +
                ' — ' +
                String(account.account_name || '') +
                '</option>';
        });

        var result = await Swal.fire({
            title: 'سند قبض جديد',
            html:
                '<div style="text-align:right">' +
                    '<label style="display:block;margin:8px 0 5px;font-weight:700">المبلغ</label>' +
                    '<input id="rcptAmt" class="swal2-input" type="number" min="0.01" step="0.01" placeholder="المبلغ">' +

                    '<label style="display:block;margin:8px 0 5px;font-weight:700">الحساب المقابل</label>' +
                    '<select id="rcptOffsetAccount" class="swal2-select" style="width:80%">' +
                        accountOptions +
                    '</select>' +

                    '<label style="display:block;margin:8px 0 5px;font-weight:700">المرجع</label>' +
                    '<input id="rcptRef" class="swal2-input" placeholder="المرجع">' +

                    '<div style="margin-top:10px;font-size:12px;color:#64748b">' +
                        'الخزينة: ' + String(treasury.account_code || treasury.id) +
                        ' | حساب النقدية: ' + String(cashAccount.account_code || '121') +
                    '</div>' +
                '</div>',
            showCancelButton: true,
            confirmButtonText: 'حفظ',
            cancelButtonText: 'إلغاء',
            focusConfirm: false,
            preConfirm: function () {
                var amount = Number(document.getElementById('rcptAmt').value);
                var offsetAccountId = String(
                    document.getElementById('rcptOffsetAccount').value || ''
                ).trim();
                var reference = String(
                    document.getElementById('rcptRef').value || ''
                ).trim();

                if (!Number.isFinite(amount) || amount <= 0) {
                    Swal.showValidationMessage('أدخل مبلغًا صحيحًا أكبر من صفر');
                    return false;
                }

                if (!offsetAccountId) {
                    Swal.showValidationMessage('اختر الحساب المقابل');
                    return false;
                }

                return {
                    amount: amount,
                    offsetAccountId: offsetAccountId,
                    reference: reference
                };
            }
        });

        if (!result.isConfirmed || !result.value) {
            return;
        }

        var operationId =
            window.crypto && typeof window.crypto.randomUUID === 'function'
                ? window.crypto.randomUUID()
                : 'RCV-' + Date.now() + '-' + Math.random().toString(36).slice(2, 10);

        Swal.fire({
            title: 'جاري الحفظ...',
            allowOutsideClick: false,
            allowEscapeKey: false,
            didOpen: function () { Swal.showLoading(); }
        });

        var response = await fetch(
            SUPABASE_URL + '/functions/v1/save-receipt-voucher',
            {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer ' + (await supabase.auth.getSession()).data.session.access_token
                },
                body: JSON.stringify({
                    header: {
                        operationId: operationId,
                        date: new Date().toISOString().slice(0, 10),
                        reference: result.value.reference || null,
                        notes: 'سند قبض',
                        treasuryId: treasury.id,
                        cashAccountId: cashAccount.id,
                        offsetAccountId: result.value.offsetAccountId
                    },
                    lines: [
                        {
                            description: result.value.reference || 'سند قبض',
                            amount: result.value.amount
                        }
                    ]
                })
            }
        );

        var payload = await response.json().catch(function () {
            return { success: false, error: 'INVALID_SERVER_RESPONSE' };
        });

        Swal.close();

        if (!response.ok || payload.success === false) {
            throw new Error(payload.error || payload.msg || 'فشل حفظ سند القبض');
        }

        RW_UI.toast(
            payload.duplicate
                ? 'العملية موجودة بالفعل ولم تتم إضافة حركة ثانية'
                : 'تم حفظ سند القبض بنجاح',
            'success'
        );

        s.renderReceipts();

    } catch (err) {
        Swal.close();
        RW_UI.toast(
            err && err.message ? err.message : 'فشل حفظ سند القبض',
            'error'
        );
    }
},

newPayment: async function () {
    var s = this;

    try {
        Swal.fire({
            title: 'جاري تحميل الحسابات...',
            allowOutsideClick: false,
            allowEscapeKey: false,
            didOpen: function () { Swal.showLoading(); }
        });

        var context = await s.resolveFinancialContext();
        var treasury = await s.resolveActiveTreasury(context.companyId);
        var cashAccount = await s.resolveCashAccount(context.companyId);
        var accounts = await s.loadOffsetAccounts(context.companyId);

        Swal.close();

        var accountOptions = '<option value="">اختر الحساب المقابل</option>';
        accounts.forEach(function (account) {
            accountOptions +=
                '<option value="' + account.id + '">' +
                String(account.account_code || '') +
                ' — ' +
                String(account.account_name || '') +
                '</option>';
        });

        var result = await Swal.fire({
            title: 'سند صرف جديد',
            html:
                '<div style="text-align:right">' +
                    '<label style="display:block;margin:8px 0 5px;font-weight:700">المبلغ</label>' +
                    '<input id="pmtAmt" class="swal2-input" type="number" min="0.01" step="0.01" placeholder="المبلغ">' +

                    '<label style="display:block;margin:8px 0 5px;font-weight:700">الحساب المقابل</label>' +
                    '<select id="pmtOffsetAccount" class="swal2-select" style="width:80%">' +
                        accountOptions +
                    '</select>' +

                    '<label style="display:block;margin:8px 0 5px;font-weight:700">المرجع</label>' +
                    '<input id="pmtRef" class="swal2-input" placeholder="المرجع">' +

                    '<div style="margin-top:10px;font-size:12px;color:#64748b">' +
                        'الخزينة: ' + String(treasury.account_code || treasury.id) +
                        ' | حساب النقدية: ' + String(cashAccount.account_code || '121') +
                    '</div>' +
                '</div>',
            showCancelButton: true,
            confirmButtonText: 'حفظ',
            cancelButtonText: 'إلغاء',
            focusConfirm: false,
            preConfirm: function () {
                var amount = Number(document.getElementById('pmtAmt').value);
                var offsetAccountId = String(
                    document.getElementById('pmtOffsetAccount').value || ''
                ).trim();
                var reference = String(
                    document.getElementById('pmtRef').value || ''
                ).trim();

                if (!Number.isFinite(amount) || amount <= 0) {
                    Swal.showValidationMessage('أدخل مبلغًا صحيحًا أكبر من صفر');
                    return false;
                }

                if (!offsetAccountId) {
                    Swal.showValidationMessage('اختر الحساب المقابل');
                    return false;
                }

                return {
                    amount: amount,
                    offsetAccountId: offsetAccountId,
                    reference: reference
                };
            }
        });

        if (!result.isConfirmed || !result.value) {
            return;
        }

        var operationId =
            window.crypto && typeof window.crypto.randomUUID === 'function'
                ? window.crypto.randomUUID()
                : 'PMT-' + Date.now() + '-' + Math.random().toString(36).slice(2, 10);

        Swal.fire({
            title: 'جاري الحفظ...',
            allowOutsideClick: false,
            allowEscapeKey: false,
            didOpen: function () { Swal.showLoading(); }
        });

        var sessionResult = await supabase.auth.getSession();
        var session = sessionResult && sessionResult.data && sessionResult.data.session;
        if (!session || !session.access_token) {
            throw new Error('INVALID_SESSION');
        }

        var response = await fetch(
            SUPABASE_URL + '/functions/v1/save-payment-voucher',
            {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer ' + session.access_token
                },
                body: JSON.stringify({
                    header: {
                        operationId: operationId,
                        date: new Date().toISOString().slice(0, 10),
                        reference: result.value.reference || null,
                        notes: 'سند صرف',
                        treasuryId: treasury.id,
                        cashAccountId: cashAccount.id,
                        offsetAccountId: result.value.offsetAccountId
                    },
                    lines: [
                        {
                            description: result.value.reference || 'سند صرف',
                            amount: result.value.amount
                        }
                    ]
                })
            }
        );

        var payload = await response.json().catch(function () {
            return { success: false, error: 'INVALID_SERVER_RESPONSE' };
        });

        Swal.close();

        if (!response.ok || payload.success === false) {
            throw new Error(payload.error || payload.msg || 'فشل حفظ سند الصرف');
        }

        RW_UI.toast(
            payload.duplicate
                ? 'العملية موجودة بالفعل ولم تتم إضافة حركة ثانية'
                : 'تم حفظ سند الصرف بنجاح',
            'success'
        );

        s.renderPayments();

    } catch (err) {
        Swal.close();
        RW_UI.toast(
            err && err.message ? err.message : 'فشل حفظ سند الصرف',
            'error'
        );
    }
},
```

## Important
- No PWA file is modified by this artifact.
- `company_id` comes only from `public.users.auth_id`.
- Cash Account `121` is resolved by current Production account code under the current company, then converted to UUID.
- Offset account is explicitly selected by the accountant; it is never defaulted to `123`, `51`, or any other guessed value.
- Treasury is resolved from the current company and active state.
- The Edge functions remain the authoritative business boundary.
- Direct financial DML remains forbidden from PWA.
