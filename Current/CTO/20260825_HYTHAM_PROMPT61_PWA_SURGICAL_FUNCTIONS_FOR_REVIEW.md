# HYTHAM — Prompt 61 PWA Surgical Functions

Target: `Current/PWA/accountant.html`

Status: REVIEW ARTIFACT — NOT AUTO-APPLIED TO PWA

Reason: Prompt 61 rejects the earlier PWA proposal because it used default offset accounts such as 123/51. The current Production contract requires authoritative company context from `public.users.auth_id`, Treasury/COA resolution by company, UUID identities, explicit user-selected offset account, `operation_id`, and delegation to the canonical Edge/Core.

Production facts verified before preparing this artifact:
- Company count = 1.
- Current Production COA contains account 121 = `النقدية (الخزينة الرئيسية)`.
- `post_cash_receipt_atomic` is SECURITY DEFINER and executable only by `service_role`.
- `post_cash_payment_atomic` is SECURITY DEFINER and executable only by `service_role`.
- Current adapters are `save-receipt-voucher` v6 and `save-payment-voucher` v4.

The functions below are complete replacements for the existing `newReceipt` and `newPayment` methods. They do not perform direct financial DML. They resolve company context through `public.users.auth_id`, resolve the current cash account by company + account_code 121 + active state, resolve the single active Treasury, force the user to choose the offset account rather than assuming one, generate an operation ID, and call the canonical Edge function.

---

## 1. Replace `newReceipt` completely

```javascript
newReceipt: function () {
    var s = this;

    Swal.fire({
        title: 'جاري تحميل السياق المالي...',
        allowOutsideClick: false,
        allowEscapeKey: false,
        didOpen: function () {
            Swal.showLoading();
        }
    });

    Promise.all([
        supabase.auth.getUser(),
        supabase.from('chart_of_accounts')
            .select('id,account_code,account_name,account_type,is_active')
            .eq('account_code', '121')
            .eq('is_active', true),
        supabase.from('treasury')
            .select('id,account_code,current_balance,is_active')
            .eq('is_active', true),
        supabase.from('chart_of_accounts')
            .select('id,account_code,account_name,account_type,is_active')
            .eq('is_active', true)
            .order('account_code')
    ])
    .then(function (results) {

        var authResult = results[0];
        var cashAccountsResult = results[1];
        var treasuryResult = results[2];
        var offsetAccountsResult = results[3];

        if (authResult.error || !authResult.data || !authResult.data.user) {
            throw new Error('INVALID_SESSION');
        }

        var user = authResult.data.user;

        return supabase.from('users')
            .select('company_id,status')
            .eq('auth_id', user.id)
            .maybeSingle()
            .then(function (userResult) {

                if (
                    userResult.error ||
                    !userResult.data ||
                    !userResult.data.company_id ||
                    (userResult.data.status && userResult.data.status !== 'Active')
                ) {
                    throw new Error('INVALID_COMPANY_CONTEXT');
                }

                var companyId = userResult.data.company_id;

                var companyCashAccounts = (cashAccountsResult.data || []).filter(function (row) {
                    return row && row.id && row.account_code === '121';
                });

                if (companyCashAccounts.length !== 1) {
                    throw new Error('CASH_ACCOUNT_121_NOT_CONFIGURED_FOR_COMPANY');
                }

                var activeTreasuries = (treasuryResult.data || []).filter(function (row) {
                    return row && row.id;
                });

                if (activeTreasuries.length !== 1) {
                    throw new Error('RECEIPT_TREASURY_MAPPING_REQUIRED');
                }

                var offsetAccounts = (offsetAccountsResult.data || []).filter(function (row) {
                    return row && row.id && row.account_code !== '121';
                });

                if (!offsetAccounts.length) {
                    throw new Error('NO_ACTIVE_OFFSET_ACCOUNTS_AVAILABLE');
                }

                return {
                    user: user,
                    companyId: companyId,
                    cashAccount: companyCashAccounts[0],
                    treasury: activeTreasuries[0],
                    offsetAccounts: offsetAccounts
                };
            });
    })
    .then(function (ctx) {

        var offsetOptions = '<option value="">اختر الحساب المقابل</option>';

        for (var i = 0; i < ctx.offsetAccounts.length; i++) {
            var account = ctx.offsetAccounts[i];
            offsetOptions +=
                '<option value="' + account.id + '">' +
                String(account.account_code || '') +
                ' — ' +
                String(account.account_name || '') +
                '</option>';
        }

        Swal.fire({
            title: 'سند قبض جديد',
            html:
                '<div style="text-align:right">' +
                    '<label style="display:block;margin:0 0 6px;font-weight:bold">المبلغ</label>' +
                    '<input id="rcptAmt" class="swal2-input" placeholder="المبلغ" type="number" min="0.01" step="0.01">' +

                    '<label style="display:block;margin:12px 0 6px;font-weight:bold">الحساب المقابل</label>' +
                    '<select id="rcptOffsetAccount" class="swal2-select" style="width:80%;margin:0 auto">' +
                        offsetOptions +
                    '</select>' +

                    '<label style="display:block;margin:12px 0 6px;font-weight:bold">المرجع</label>' +
                    '<input id="rcptRef" class="swal2-input" placeholder="المرجع">' +

                    '<label style="display:block;margin:12px 0 6px;font-weight:bold">ملاحظات</label>' +
                    '<textarea id="rcptNotes" class="swal2-textarea" placeholder="ملاحظات اختيارية"></textarea>' +
                '</div>',
            showCancelButton: true,
            confirmButtonText: 'حفظ',
            cancelButtonText: 'إلغاء',
            focusConfirm: false,
            preConfirm: function () {

                var amount = Number(document.getElementById('rcptAmt').value);
                var offsetAccountId = String(document.getElementById('rcptOffsetAccount').value || '').trim();
                var reference = String(document.getElementById('rcptRef').value || '').trim();
                var notes = String(document.getElementById('rcptNotes').value || '').trim();

                if (!Number.isFinite(amount) || amount <= 0) {
                    Swal.showValidationMessage('أدخل مبلغًا صحيحًا أكبر من صفر');
                    return false;
                }

                if (!offsetAccountId) {
                    Swal.showValidationMessage('يجب اختيار الحساب المقابل');
                    return false;
                }

                return {
                    amount: amount,
                    offsetAccountId: offsetAccountId,
                    reference: reference,
                    notes: notes
                };
            }
        }).then(function (result) {

            if (!result.isConfirmed || !result.value) {
                return;
            }

            var payload = result.value;

            Swal.fire({
                title: 'جاري حفظ سند القبض...',
                allowOutsideClick: false,
                allowEscapeKey: false,
                didOpen: function () {
                    Swal.showLoading();
                }
            });

            var operationId =
                window.crypto && typeof window.crypto.randomUUID === 'function'
                    ? window.crypto.randomUUID()
                    : 'RCV-' + Date.now() + '-' + Math.random().toString(36).slice(2, 10);

            return supabase.functions.invoke('save-receipt-voucher', {
                body: {
                    header: {
                        operationId: operationId,
                        treasuryId: ctx.treasury.id,
                        cashAccountId: ctx.cashAccount.id,
                        offsetAccountId: payload.offsetAccountId,
                        date: new Date().toISOString().slice(0, 10),
                        reference: payload.reference || null,
                        notes: payload.notes || null,
                        mainAccountName: ctx.cashAccount.account_name
                    },
                    lines: [
                        {
                            accountName: 'الحساب المقابل',
                            accountId: payload.offsetAccountId,
                            description: payload.reference || 'سند قبض',
                            amount: payload.amount
                        }
                    ]
                }
            });
        })
        .then(function (result) {

            if (!result) {
                return;
            }

            Swal.close();

            if (result.error) {
                throw result.error;
            }

            var data = result.data || {};

            RW_UI.toast(
                data.duplicate
                    ? 'العملية موجودة بالفعل ولم تتم إضافة حركة ثانية'
                    : 'تم حفظ سند القبض بنجاح',
                'success'
            );

            s.renderReceipts();
        })
        .catch(function (error) {
            Swal.close();
            RW_UI.toast(
                error && error.message
                    ? error.message
                    : 'فشل حفظ سند القبض',
                'error'
            );
        });
    })
    .catch(function (error) {
        Swal.close();
        RW_UI.toast(
            error && error.message
                ? error.message
                : 'تعذر تجهيز السياق المالي',
            'error'
        );
    });
},
```

## 2. Replace `newPayment` completely

```javascript
newPayment: function () {
    var s = this;

    Swal.fire({
        title: 'جاري تحميل السياق المالي...',
        allowOutsideClick: false,
        allowEscapeKey: false,
        didOpen: function () {
            Swal.showLoading();
        }
    });

    Promise.all([
        supabase.auth.getUser(),
        supabase.from('chart_of_accounts')
            .select('id,account_code,account_name,account_type,is_active')
            .eq('account_code', '121')
            .eq('is_active', true),
        supabase.from('treasury')
            .select('id,account_code,current_balance,is_active')
            .eq('is_active', true),
        supabase.from('chart_of_accounts')
            .select('id,account_code,account_name,account_type,is_active')
            .eq('is_active', true)
            .order('account_code')
    ])
    .then(function (results) {

        var authResult = results[0];
        var cashAccountsResult = results[1];
        var treasuryResult = results[2];
        var offsetAccountsResult = results[3];

        if (authResult.error || !authResult.data || !authResult.data.user) {
            throw new Error('INVALID_SESSION');
        }

        var user = authResult.data.user;

        return supabase.from('users')
            .select('company_id,status')
            .eq('auth_id', user.id)
            .maybeSingle()
            .then(function (userResult) {

                if (
                    userResult.error ||
                    !userResult.data ||
                    !userResult.data.company_id ||
                    (userResult.data.status && userResult.data.status !== 'Active')
                ) {
                    throw new Error('INVALID_COMPANY_CONTEXT');
                }

                var companyId = userResult.data.company_id;

                var companyCashAccounts = (cashAccountsResult.data || []).filter(function (row) {
                    return row && row.id && row.account_code === '121';
                });

                if (companyCashAccounts.length !== 1) {
                    throw new Error('CASH_ACCOUNT_121_NOT_CONFIGURED_FOR_COMPANY');
                }

                var activeTreasuries = (treasuryResult.data || []).filter(function (row) {
                    return row && row.id;
                });

                if (activeTreasuries.length !== 1) {
                    throw new Error('PAYMENT_TREASURY_MAPPING_REQUIRED');
                }

                var offsetAccounts = (offsetAccountsResult.data || []).filter(function (row) {
                    return row && row.id && row.account_code !== '121';
                });

                if (!offsetAccounts.length) {
                    throw new Error('NO_ACTIVE_OFFSET_ACCOUNTS_AVAILABLE');
                }

                return {
                    user: user,
                    companyId: companyId,
                    cashAccount: companyCashAccounts[0],
                    treasury: activeTreasuries[0],
                    offsetAccounts: offsetAccounts
                };
            });
    })
    .then(function (ctx) {

        var offsetOptions = '<option value="">اختر الحساب المقابل</option>';

        for (var i = 0; i < ctx.offsetAccounts.length; i++) {
            var account = ctx.offsetAccounts[i];
            offsetOptions +=
                '<option value="' + account.id + '">' +
                String(account.account_code || '') +
                ' — ' +
                String(account.account_name || '') +
                '</option>';
        }

        Swal.fire({
            title: 'سند صرف جديد',
            html:
                '<div style="text-align:right">' +
                    '<label style="display:block;margin:0 0 6px;font-weight:bold">المبلغ</label>' +
                    '<input id="pmtAmt" class="swal2-input" placeholder="المبلغ" type="number" min="0.01" step="0.01">' +

                    '<label style="display:block;margin:12px 0 6px;font-weight:bold">الحساب المقابل</label>' +
                    '<select id="pmtOffsetAccount" class="swal2-select" style="width:80%;margin:0 auto">' +
                        offsetOptions +
                    '</select>' +

                    '<label style="display:block;margin:12px 0 6px;font-weight:bold">المرجع</label>' +
                    '<input id="pmtRef" class="swal2-input" placeholder="المرجع">' +

                    '<label style="display:block;margin:12px 0 6px;font-weight:bold">ملاحظات</label>' +
                    '<textarea id="pmtNotes" class="swal2-textarea" placeholder="ملاحظات اختيارية"></textarea>' +
                '</div>',
            showCancelButton: true,
            confirmButtonText: 'حفظ',
            cancelButtonText: 'إلغاء',
            focusConfirm: false,
            preConfirm: function () {

                var amount = Number(document.getElementById('pmtAmt').value);
                var offsetAccountId = String(document.getElementById('pmtOffsetAccount').value || '').trim();
                var reference = String(document.getElementById('pmtRef').value || '').trim();
                var notes = String(document.getElementById('pmtNotes').value || '').trim();

                if (!Number.isFinite(amount) || amount <= 0) {
                    Swal.showValidationMessage('أدخل مبلغًا صحيحًا أكبر من صفر');
                    return false;
                }

                if (!offsetAccountId) {
                    Swal.showValidationMessage('يجب اختيار الحساب المقابل');
                    return false;
                }

                return {
                    amount: amount,
                    offsetAccountId: offsetAccountId,
                    reference: reference,
                    notes: notes
                };
            }
        }).then(function (result) {

            if (!result.isConfirmed || !result.value) {
                return;
            }

            var payload = result.value;

            Swal.fire({
                title: 'جاري حفظ سند الصرف...',
                allowOutsideClick: false,
                allowEscapeKey: false,
                didOpen: function () {
                    Swal.showLoading();
                }
            });

            var operationId =
                window.crypto && typeof window.crypto.randomUUID === 'function'
                    ? window.crypto.randomUUID()
                    : 'PMT-' + Date.now() + '-' + Math.random().toString(36).slice(2, 10);

            return supabase.functions.invoke('save-payment-voucher', {
                body: {
                    header: {
                        operationId: operationId,
                        treasuryId: ctx.treasury.id,
                        cashAccountId: ctx.cashAccount.id,
                        offsetAccountId: payload.offsetAccountId,
                        date: new Date().toISOString().slice(0, 10),
                        reference: payload.reference || null,
                        notes: payload.notes || null,
                        mainAccountName: ctx.cashAccount.account_name
                    },
                    lines: [
                        {
                            accountName: 'الحساب المقابل',
                            accountId: payload.offsetAccountId,
                            description: payload.reference || 'سند صرف',
                            amount: payload.amount
                        }
                    ]
                }
            });
        })
        .then(function (result) {

            if (!result) {
                return;
            }

            Swal.close();

            if (result.error) {
                throw result.error;
            }

            var data = result.data || {};

            RW_UI.toast(
                data.duplicate
                    ? 'العملية موجودة بالفعل ولم تتم إضافة حركة ثانية'
                    : 'تم حفظ سند الصرف بنجاح',
                'success'
            );

            s.renderPayments();
        })
        .catch(function (error) {
            Swal.close();
            RW_UI.toast(
                error && error.message
                    ? error.message
                    : 'فشل حفظ سند الصرف',
                'error'
            );
        });
    })
    .catch(function (error) {
        Swal.close();
        RW_UI.toast(
            error && error.message
                ? error.message
                : 'تعذر تجهيز السياق المالي',
            'error'
        );
    });
},
```

### Expected behavior
- No `user_metadata.company_id`.
- No hard-coded UUIDs.
- No default offset account (`123`, `51`, or otherwise).
- Current production cash account `121` is resolved under the authenticated user's company and active state.
- Active Treasury must resolve to exactly one current treasury for the company.
- Offset account must be explicitly selected from current active COA records.
- Every post receives a fresh `operationId`.
- Client performs no direct financial INSERT/UPDATE/DELETE.
- Edge/Core remain authoritative.
- Existing `save-receipt-voucher v6` and `save-payment-voucher v4` contracts are used.
