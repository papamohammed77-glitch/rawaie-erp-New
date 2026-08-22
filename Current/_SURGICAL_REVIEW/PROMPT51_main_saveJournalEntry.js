/*
 RAWAEA ERP — Prompt 51 surgical replacement for Current/PWA/main.html
 Target function: _saveJournalEntry

 IMPORTANT:
 - Review artifact only. Current/PWA/main.html is intentionally NOT rewritten here.
 - DOM selectors are adapted to the CURRENT published main.html contract:
   journal-ref, journal-desc, jl-cost-center.
 - Architectural contract comes from Prompt 51 + verified Production:
   save-journal-entry v8 -> public.post_journal_entry(...).
 - No direct DB write.
 - No RW_Audit_log call; authoritative journal audit belongs to Production Core.
*/

function _saveJournalEntry() {
    var host = byId('journal-lines');
    if (host && host.dataset.journalSaving === '1') return;

    var lines = [];
    var lineEls = document.querySelectorAll('.journal-line');
    var totalDebit = 0;
    var totalCredit = 0;

    for (var i = 0; i < lineEls.length; i++) {
        var l = lineEls[i];
        var accEl = l.querySelector('.jl-account');
        var acc = accEl ? String(accEl.value || '').trim() : '';
        var debEl = l.querySelector('.jl-debit');
        var credEl = l.querySelector('.jl-credit');
        var deb = Number(debEl ? debEl.value : 0);
        var cred = Number(credEl ? credEl.value : 0);

        if (!Number.isFinite(deb) || !Number.isFinite(cred)) {
            _showToast('يوجد مبلغ غير صالح في السطر ' + (i + 1), 'error');
            return;
        }
        if (deb < 0 || cred < 0) {
            _showToast('لا يجوز إدخال مبالغ سالبة في السطر ' + (i + 1), 'error');
            return;
        }
        if (deb > 0 && cred > 0) {
            _showToast('لا يجوز أن يحتوي السطر ' + (i + 1) + ' على مدين ودائن معًا', 'error');
            return;
        }

        if (acc && (deb || cred)) {
            var selected = accEl && accEl.selectedOptions && accEl.selectedOptions[0];
            var ccEl = l.querySelector('.jl-cost-center');

            lines.push({
                accountId: acc,
                accountName: selected ? selected.textContent : '',
                costCenterId: ccEl && ccEl.value ? ccEl.value : null,
                debit: deb,
                credit: cred
            });

            totalDebit += deb;
            totalCredit += cred;
        }
    }

    if (lines.length < 2) {
        _showToast('يجب إدخال سطرين على الأقل للقيد', 'warning');
        return;
    }

    if (Math.abs(totalDebit - totalCredit) >= 0.01 || totalDebit <= 0 || totalCredit <= 0) {
        _showToast('القيد غير متوازن: المدين ' + _fmtNum(totalDebit) + ' / الدائن ' + _fmtNum(totalCredit), 'error');
        return;
    }

    var operationId = (host && host.dataset.journalOperationId) || '';
    if (!operationId) {
        if (window.crypto && typeof window.crypto.randomUUID === 'function') {
            operationId = window.crypto.randomUUID();
        } else if (window.crypto && typeof window.crypto.getRandomValues === 'function') {
            var bytes = new Uint8Array(16);
            window.crypto.getRandomValues(bytes);
            bytes[6] = (bytes[6] & 0x0f) | 0x40;
            bytes[8] = (bytes[8] & 0x3f) | 0x80;
            operationId = '';
            for (var b = 0; b < bytes.length; b++) {
                if (b === 4 || b === 6 || b === 8 || b === 10) operationId += '-';
                operationId += bytes[b].toString(16).padStart(2, '0');
            }
        } else {
            function hex4() { return Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1); }
            operationId = hex4() + hex4() + '-' + hex4() + '-4' + hex4().substring(1) + '-' + ((8 + Math.floor(Math.random() * 4)).toString(16)) + hex4().substring(1) + '-' + hex4() + hex4() + hex4();
        }
        if (host) host.dataset.journalOperationId = operationId;
    }

    if (host) host.dataset.journalSaving = '1';

    var payload = {
        operation_id: operationId,
        date: byId('journal-date') ? (byId('journal-date').value || new Date().toISOString().slice(0, 10)) : new Date().toISOString().slice(0, 10),
        reference: byId('journal-ref') ? (byId('journal-ref').value || '') : '',
        description: byId('journal-desc') ? (byId('journal-desc').value || '') : '',
        entryType: 'Manual',
        lines: lines
    };

    var saveUrl = RW_SUPABASE_URL + '/functions/v1/save-journal-entry';

    if (typeof supabase === 'undefined' || !supabase || !supabase.auth) {
        if (host) host.dataset.journalSaving = '0';
        _showToast('جلسة Supabase غير متاحة', 'error');
        return;
    }

    _showLoader();

    supabase.auth.getSession().then(function (ses) {
        var token = ses && ses.data && ses.data.session ? ses.data.session.access_token : null;
        if (!token) throw new Error('انتهت الجلسة');

        return fetch(saveUrl, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ' + token
            },
            body: JSON.stringify(payload)
        });
    }).then(function (res) {
        return res.json().then(function (json) {
            if (!res.ok || !json || !json.success) {
                throw new Error((json && json.error) || 'فشل حفظ القيد');
            }
            return json;
        });
    }).then(function (json) {
        _hideLoader();
        if (host) {
            host.dataset.journalSaving = '0';
            delete host.dataset.journalOperationId;
        }
        _showToast((json.duplicate ? 'القيد موجود بالفعل: ' : 'تم حفظ القيد ') + (json.entry_code || json.entryCode || ''), 'success');
        renderSubTab('journal');
    }).catch(function (e) {
        _hideLoader();
        if (host) host.dataset.journalSaving = '0';
        _showToast(e && e.message ? e.message : 'فشل الحفظ', 'error');
        console.error('Journal save error:', e);
    });
}
