// ============================================================
// RAWAEA ERP — MAIN8 / FINANCE & ACCOUNTING
// Governed Reconstruction — preserves the historical public API
// ============================================================
// CONTRACT NOTES
// 1) main8 is a UI/orchestration fragment, not a financial engine.
// 2) Company context is authoritative from RW_ShellContext.
// 3) Financial posting is delegated to current Edge/RPC capabilities.
// 4) Treasury, journal, cash-box and budget writes are never performed
//    without explicit tenant scoping and operation identity where required.
// 5) Public RW_Finance exports are preserved for whole-file assembly.

var RW_Finance = (function () {
    'use strict';

    function _showLoader(message) {
        try {
            if (typeof showLoader === 'function') showLoader(message || 'جاري التحميل...');
            else if (window.RW_UI && typeof RW_UI.showLoader === 'function') RW_UI.showLoader(message || 'جاري التحميل...');
        } catch (e) { console.error(e); }
    }

    function _hideLoader() {
        try {
            if (typeof hideLoader === 'function') hideLoader();
            else if (window.RW_UI && typeof RW_UI.hideLoader === 'function') RW_UI.hideLoader();
        } catch (e) { console.error(e); }
    }

    function _showToast(message, type) {
        try {
            if (typeof showToast === 'function') showToast(message, type || 'success');
            else if (window.RW_UI && typeof RW_UI.showToast === 'function') RW_UI.showToast(message, type || 'success');
            else if (window.Swal) Swal.fire({ toast: true, position: 'top-end', icon: type === 'error' ? 'error' : 'success', title: message, showConfirmButton: false, timer: 2600 });
            else console.log(message);
        } catch (e) { console.error(e); }
    }

    function _showError(message) {
        try {
            if (window.RW_UI && typeof RW_UI.showError === 'function') RW_UI.showError(message);
            else _showToast(message, 'error');
        } catch (e) { console.error(e); }
    }

    function _fmtNum(value) {
        var n = Number(value);
        if (!Number.isFinite(n)) n = 0;
        return n.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    }

    function _esc(value) {
        return String(value == null ? '' : value).replace(/[&<>"']/g, function (c) {
            return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
        });
    }

    function _safeHtml(element, html) {
        if (!element) return;
        if (typeof safeHTML === 'function') safeHTML(element, html);
        else element.innerHTML = html;
    }

    function _safeText(element, text) {
        if (!element) return;
        if (typeof safeText === 'function') safeText(element, text);
        else element.textContent = text == null ? '' : String(text);
    }

    function _byId(id) {
        if (typeof byId === 'function') return byId(id);
        return document.getElementById(id);
    }

    function _today() {
        return new Date().toISOString().slice(0, 10);
    }

    function _uuid() {
        if (window.crypto && typeof window.crypto.randomUUID === 'function') return window.crypto.randomUUID();
        var bytes = new Uint8Array(16);
        if (window.crypto && typeof window.crypto.getRandomValues === 'function') window.crypto.getRandomValues(bytes);
        else for (var i = 0; i < bytes.length; i++) bytes[i] = Math.floor(Math.random() * 256);
        bytes[6] = (bytes[6] & 15) | 64;
        bytes[8] = (bytes[8] & 63) | 128;
        var h = '';
        for (var b = 0; b < bytes.length; b++) h += (b && [4, 6, 8, 10].indexOf(b) !== -1 ? '-' : '') + bytes[b].toString(16).padStart(2, '0');
        return h;
    }

    function _companyId() {
        var context = window.RW_ShellContext;
        if (context && typeof context.getCompanyId === 'function') {
            var id = context.getCompanyId();
            if (id) return id;
        }
        if (window.RW_STATE) {
            if (RW_STATE.app && RW_STATE.app.companyId) return RW_STATE.app.companyId;
            if (RW_STATE.user && RW_STATE.user.companyId) return RW_STATE.user.companyId;
            if (RW_STATE.app && RW_STATE.app.user && RW_STATE.app.user.companyId) return RW_STATE.app.user.companyId;
        }
        throw new Error('TENANT_CONTEXT_UNAVAILABLE');
    }

    function _currentUserId() {
        try {
            if (window.RW_STATE && RW_STATE.app && RW_STATE.app.userId) return RW_STATE.app.userId;
            if (window.RW_STATE && RW_STATE.user && RW_STATE.user.id) return RW_STATE.user.id;
            return null;
        } catch (e) { return null; }
    }

    function _handleResult(result, fallback) {
        if (!result || !result.error) return result;
        var message = result.error.message || result.error.details || result.error.hint || fallback || 'تعذر تنفيذ العملية';
        throw new Error(message);
    }

    var _cache = {
        loaded: false,
        companyId: null,
        treasury: [],
        accountsFlat: [],
        accountsTree: [],
        costCenters: [],
        accountMap: {},
        treasuryMap: {},
        version: 0
    };

    var _pendingOps = {
        journal: null,
        receipt: null,
        payment: null,
        transfer: null
    };

    function _invalidate() {
        _cache.loaded = false;
        _cache.version += 1;
    }

    function _buildAccountsTree(accounts) {
        var byId = {}, roots = [];
        for (var i = 0; i < accounts.length; i++) {
            var a = accounts[i];
            byId[a.id] = {
                id: a.id,
                code: a.account_code,
                name: a.account_name,
                type: a.account_type,
                normalBalance: a.normal_balance,
                parentId: a.parent_account_id,
                children: []
            };
        }
        for (var j = 0; j < accounts.length; j++) {
            var node = byId[accounts[j].id];
            if (node.parentId && byId[node.parentId]) byId[node.parentId].children.push(node);
            else roots.push(node);
        }
        return roots;
    }

    async function _loadAllData(force) {
        var companyId = _companyId();
        if (_cache.loaded && !force && _cache.companyId === companyId) return _cache;

        _showLoader('جاري تحميل البيانات المالية...');
        try {
            var results = await Promise.all([
                supabase.from('treasury').select('id,company_id,account_code,account_name,type,opening_balance,current_balance,is_active,notes,created_at,updated_at').eq('company_id', companyId).eq('is_active', true).order('account_code'),
                supabase.from('chart_of_accounts').select('id,company_id,account_code,account_name,account_type,parent_account_id,normal_balance,is_active,notes,created_at,updated_at').eq('company_id', companyId).eq('is_active', true).order('account_code'),
                supabase.from('cost_centers').select('id,code,name,parent_id,is_active').eq('is_active', true).order('code')
            ]);
            _handleResult(results[0], 'فشل تحميل الخزائن');
            _handleResult(results[1], 'فشل تحميل دليل الحسابات');
            _handleResult(results[2], 'فشل تحميل مراكز التكلفة');

            _cache.companyId = companyId;
            _cache.treasury = results[0].data || [];
            _cache.accountsFlat = results[1].data || [];
            _cache.costCenters = results[2].data || [];
            _cache.accountMap = {};
            _cache.treasuryMap = {};

            for (var i = 0; i < _cache.accountsFlat.length; i++) {
                _cache.accountMap[_cache.accountsFlat[i].id] = _cache.accountsFlat[i];
            }
            for (var t = 0; t < _cache.treasury.length; t++) {
                _cache.treasuryMap[_cache.treasury[t].id] = _cache.treasury[t];
            }

            _cache.accountsTree = _buildAccountsTree(_cache.accountsFlat);
            _cache.loaded = true;
            return _cache;
        } finally {
            _hideLoader();
        }
    }

    function render() {
        return renderSubTab('treasury');
    }

    function renderSubTab(subTab) {
        var tab = subTab || 'treasury';
        _loadAllData(false).then(function () {
            var container = _byId('rw-page-container');
            if (!container) throw new Error('FINANCE_CONTAINER_UNAVAILABLE');
            _safeText(_byId('rw-header-title'), 'الحسابات والمالية');

            var tabs = [
                ['treasury', 'الخزائن والبنوك'], ['accounts', 'دليل الحسابات'], ['journal', 'قيود يومية'],
                ['receipts', 'سندات القبض'], ['payments', 'سندات الصرف'], ['transfers', 'التحويلات'],
                ['reports', 'التقارير المالية'], ['budgets', 'الموازنات']
            ];
            var html = '<div class="p-4"><div class="flex flex-wrap gap-2 border-b pb-3 mb-4">';
            for (var i = 0; i < tabs.length; i++) {
                var cls = tab === tabs[i][0] ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200';
                html += '<button type="button" onclick="RW_Finance.renderSubTab(\'' + _esc(tabs[i][0]) + '\')" class="px-4 py-2 rounded-xl font-bold text-sm transition ' + cls + '">' + _esc(tabs[i][1]) + '</button>';
            }
            html += '</div><div id="finance-content"></div></div>';
            _safeHtml(container, html);

            if (tab === 'treasury') _renderTreasury();
            else if (tab === 'accounts') _renderAccounts();
            else if (tab === 'journal') _renderJournal();
            else if (tab === 'receipts') _renderReceipts();
            else if (tab === 'payments') _renderPayments();
            else if (tab === 'transfers') _renderTransfers();
            else if (tab === 'reports') _renderReports();
            else if (tab === 'budgets') _renderBudgets();
        }).catch(function (e) {
            console.error('RW_Finance render error:', e);
            _showError(e && e.message ? e.message : 'فشل تحميل الحسابات والمالية');
        });
    }

    // ==================== Treasury ====================
    function _renderTreasury() {
        var content = _byId('finance-content'); if (!content) return;
        var html = '<div class="bg-white rounded-2xl shadow-sm border p-4">' +
            '<div class="flex justify-between items-center mb-4"><h2 class="text-xl font-bold"><i class="fa-solid fa-vault ml-2 text-blue-600"></i>الخزائن والبنوك</h2>' +
            '<button type="button" onclick="RW_Finance._openTreasuryDialog()" class="bg-blue-600 text-white px-4 py-2 rounded-xl font-bold"><i class="fa-solid fa-plus ml-1"></i>إضافة</button></div>' +
            '<div class="mb-3"><input type="text" id="tr-search" placeholder="بحث..." class="w-full md:w-80 border rounded-lg px-3 py-2 text-sm" oninput="RW_Finance._filterTreasury()"></div>' +
            '<div id="tr-list" class="overflow-x-auto">' + _buildTreasuryTable(_cache.treasury) + '</div></div>';
        _safeHtml(content, html);
    }

    function _buildTreasuryTable(data) {
        if (!data || !data.length) return '<div class="text-center py-8 text-gray-500">لا توجد خزائن أو بنوك</div>';
        var html = '<table class="w-full text-sm border-collapse"><thead><tr class="bg-gray-50"><th class="p-2 border">الكود</th><th class="p-2 border">الاسم</th><th class="p-2 border">النوع</th><th class="p-2 border">الرصيد</th></tr></thead><tbody>';
        for (var i = 0; i < data.length; i++) {
            var t = data[i];
            html += '<tr class="border-t hover:bg-gray-50 cursor-pointer" onclick="RW_Finance._editTreasury(\'' + _esc(t.id) + '\')">' +
                '<td class="p-2">' + _esc(t.account_code) + '</td>' +
                '<td class="p-2 font-bold">' + _esc(t.account_name) + '</td>' +
                '<td class="p-2">' + (t.type === 'Cash' ? 'خزينة' : 'بنك') + '</td>' +
                '<td class="p-2 font-bold text-blue-600">' + _fmtNum(t.current_balance) + '</td></tr>';
        }
        return html + '</tbody></table>';
    }

    function _filterTreasury() {
        var q = ((_byId('tr-search') || {}).value || '').toLowerCase().trim();
        var data = _cache.treasury.filter(function (t) {
            return String(t.account_code || '').toLowerCase().indexOf(q) !== -1 || String(t.account_name || '').toLowerCase().indexOf(q) !== -1;
        });
        _safeHtml(_byId('tr-list'), _buildTreasuryTable(data));
    }

    function _openTreasuryDialog(editId) {
        var item = editId ? _cache.treasuryMap[editId] : null;
        var isEdit = !!item;
        var code = isEdit ? item.account_code : ('CASH-' + Date.now().toString().slice(-8));
        Swal.fire({
            title: isEdit ? 'تعديل خزينة / بنك' : 'إضافة خزينة / بنك',
            html: '<div class="text-right space-y-3">' +
                '<div><label class="block text-sm font-bold">الكود</label><input id="tr-code" class="swal2-input" value="' + _esc(code) + '" ' + (isEdit ? 'readonly' : '') + '></div>' +
                '<div><label class="block text-sm font-bold">الاسم *</label><input id="tr-name" class="swal2-input" value="' + _esc(isEdit ? item.account_name : '') + '"></div>' +
                '<div><label class="block text-sm font-bold">النوع</label><select id="tr-type" class="swal2-input"><option value="Cash" ' + (isEdit && item.type === 'Cash' ? 'selected' : '') + '>خزينة</option><option value="Bank" ' + (isEdit && item.type === 'Bank' ? 'selected' : '') + '>بنك</option></select></div>' +
                '<div><label class="block text-sm font-bold">الرصيد الافتتاحي</label><input id="tr-balance" type="number" step="0.01" class="swal2-input" value="' + (isEdit ? Number(item.opening_balance || 0) : 0) + '"></div>' +
                '</div>',
            showCancelButton: true,
            showDenyButton: isEdit,
            confirmButtonText: isEdit ? 'حفظ' : 'إضافة',
            denyButtonText: 'حذف',
            denyButtonColor: '#dc2626',
            preConfirm: function () {
                var name = String(document.getElementById('tr-name').value || '').trim();
                if (!name) { Swal.showValidationMessage('الاسم مطلوب'); return false; }
                var balance = Number(document.getElementById('tr-balance').value || 0);
                if (!Number.isFinite(balance)) { Swal.showValidationMessage('الرصيد غير صالح'); return false; }
                return {
                    company_id: _companyId(),
                    account_code: String(document.getElementById('tr-code').value || '').trim(),
                    account_name: name,
                    type: document.getElementById('tr-type').value,
                    opening_balance: balance,
                    current_balance: isEdit ? Number(item.current_balance || 0) : balance,
                    is_active: true
                };
            }
        }).then(function (result) {
            if (result.isConfirmed) {
                _showLoader('جاري حفظ الخزينة...');
                var promise = isEdit
                    ? supabase.from('treasury').update({ account_code: result.value.account_code, account_name: result.value.account_name, type: result.value.type, opening_balance: result.value.opening_balance, is_active: true, updated_at: new Date().toISOString() }).eq('id', item.id).eq('company_id', _companyId())
                    : supabase.from('treasury').insert(result.value);
                promise.then(function (res) {
                    _handleResult(res, 'فشل حفظ الخزينة');
                    _hideLoader();
                    _invalidate();
                    _showToast('تم الحفظ', 'success');
                    renderSubTab('treasury');
                }).catch(function (e) { _hideLoader(); _showError(e.message); });
            } else if (result.isDenied && isEdit) {
                Swal.fire({ title: 'تأكيد الحذف', text: 'سيتم حذف سجل الخزينة إذا سمح المرجع التشغيلي بذلك.', icon: 'warning', showCancelButton: true, confirmButtonText: 'حذف', confirmButtonColor: '#dc2626' }).then(function (r) {
                    if (!r.isConfirmed) return;
                    _showLoader('جاري الحذف...');
                    supabase.from('treasury').delete().eq('id', item.id).eq('company_id', _companyId()).then(function (res) {
                        _handleResult(res, 'فشل حذف الخزينة');
                        _hideLoader(); _invalidate(); _showToast('تم الحذف', 'success'); renderSubTab('treasury');
                    }).catch(function (e) { _hideLoader(); _showError(e.message); });
                });
            }
        });
    }

    function _editTreasury(id) { _openTreasuryDialog(id); }

    // ==================== Chart of Accounts ====================
    function _renderAccounts() {
        var content = _byId('finance-content'); if (!content) return;
        var html = '<div class="bg-white rounded-2xl shadow-sm border p-4">' +
            '<div class="flex justify-between items-center mb-4"><h2 class="text-xl font-bold"><i class="fa-solid fa-sitemap ml-2 text-indigo-600"></i>دليل الحسابات</h2>' +
            '<div><button type="button" onclick="RW_Finance._seedAccounts()" class="bg-amber-500 text-white px-3 py-2 rounded-lg ml-2"><i class="fa-solid fa-seedling ml-1"></i>تهيئة</button>' +
            '<button type="button" onclick="RW_Finance._openAccountDialog()" class="bg-indigo-600 text-white px-4 py-2 rounded-lg"><i class="fa-solid fa-plus ml-1"></i>حساب جديد</button></div></div>' +
            '<div class="mb-3"><input type="text" id="acc-search" placeholder="بحث..." class="w-full md:w-80 border rounded-lg px-3 py-2 text-sm" oninput="RW_Finance._filterAccounts()"></div>' +
            '<div id="acc-tree" class="overflow-auto">' + _buildAccountTreeHtml(_cache.accountsTree, 0) + '</div></div>';
        _safeHtml(content, html);
    }

    function _buildAccountTreeHtml(nodes, level) {
        if (!nodes || !nodes.length) return '<div class="text-center py-8 text-gray-500">لا توجد حسابات</div>';
        var html = '';
        for (var i = 0; i < nodes.length; i++) {
            var node = nodes[i];
            var hasChildren = node.children && node.children.length;
            html += '<div class="border-b border-gray-100 py-2" data-account-node="' + _esc(node.id) + '"><div class="flex items-center justify-between hover:bg-gray-50 cursor-pointer rounded px-2 py-1" onclick="RW_Finance._openAccountDialog(\'' + _esc(node.code) + '\')">' +
                '<div class="flex items-center"><i class="fa-solid fa-' + (hasChildren ? 'folder text-yellow-500' : 'file-invoice text-gray-400') + ' ml-2"></i><span class="font-bold">' + _esc(node.name) + '</span><span class="text-xs text-gray-400 mr-2">(' + _esc(node.code) + ')</span></div></div>';
            if (hasChildren) html += '<div>' + _buildAccountTreeHtml(node.children, level + 1) + '</div>';
            html += '</div>';
        }
        return html;
    }

    function _flattenNodesForSearch(nodes, q, out) {
        out = out || [];
        for (var i = 0; i < nodes.length; i++) {
            var n = nodes[i];
            if (!q || String(n.name || '').toLowerCase().indexOf(q) !== -1 || String(n.code || '').toLowerCase().indexOf(q) !== -1) out.push(n);
            if (n.children && n.children.length) _flattenNodesForSearch(n.children, q, out);
        }
        return out;
    }

    function _filterAccounts() {
        var input = _byId('acc-search');
        var q = String(input ? input.value : '').toLowerCase().trim();
        var nodes = _flattenNodesForSearch(_cache.accountsTree, q, []);
        var wrapper = _byId('acc-tree');
        if (!wrapper) return;
        if (!q) return _safeHtml(wrapper, _buildAccountTreeHtml(_cache.accountsTree, 0));
        var html = '<div class="space-y-1">';
        for (var i = 0; i < nodes.length; i++) {
            html += '<div class="border rounded-lg p-2 cursor-pointer hover:bg-gray-50" onclick="RW_Finance._openAccountDialog(\'' + _esc(nodes[i].code) + '\')"><strong>' + _esc(nodes[i].name) + '</strong> <span class="text-xs text-gray-400">(' + _esc(nodes[i].code) + ')</span></div>';
        }
        _safeHtml(wrapper, html + (nodes.length ? '</div>' : '</div><div class="text-center py-6 text-gray-500">لا توجد نتائج</div>'));
    }

    function _accountByCode(code) {
        for (var i = 0; i < _cache.accountsFlat.length; i++) if (_cache.accountsFlat[i].account_code === code) return _cache.accountsFlat[i];
        return null;
    }

    function _openAccountDialog(editCode) {
        var item = editCode ? _accountByCode(editCode) : null;
        var isEdit = !!item;
        var types = [
            ['asset', 'أصول'], ['liability', 'خصوم'], ['equity', 'حقوق ملكية'],
            ['revenue', 'إيرادات'], ['expense', 'مصروفات']
        ];
        var options = types.map(function (v) { return '<option value="' + v[0] + '" ' + (isEdit && item.account_type === v[0] ? 'selected' : '') + '>' + v[1] + '</option>'; }).join('');
        var parentOptions = '<option value="">لا يوجد</option>' + _cache.accountsFlat.filter(function (a) { return !isEdit || a.id !== item.id; }).map(function (a) {
            return '<option value="' + _esc(a.id) + '" ' + (isEdit && item.parent_account_id === a.id ? 'selected' : '') + '>' + _esc(a.account_name) + ' (' + _esc(a.account_code) + ')</option>';
        }).join('');

        Swal.fire({
            title: isEdit ? 'تعديل حساب' : 'إضافة حساب جديد',
            html: '<div class="text-right space-y-3">' +
                '<div><label class="block text-sm font-bold">كود الحساب *</label><input id="acc-code" class="swal2-input" value="' + _esc(isEdit ? item.account_code : '') + '" ' + (isEdit ? 'readonly' : '') + '></div>' +
                '<div><label class="block text-sm font-bold">اسم الحساب *</label><input id="acc-name" class="swal2-input" value="' + _esc(isEdit ? item.account_name : '') + '"></div>' +
                '<div><label class="block text-sm font-bold">النوع</label><select id="acc-type" class="swal2-input">' + options + '</select></div>' +
                '<div><label class="block text-sm font-bold">الحساب الأب</label><select id="acc-parent" class="swal2-input">' + parentOptions + '</select></div>' +
                '</div>',
            showCancelButton: true,
            showDenyButton: isEdit,
            confirmButtonText: isEdit ? 'حفظ' : 'إضافة',
            denyButtonText: 'حذف', denyButtonColor: '#dc2626',
            preConfirm: function () {
                var code = String(document.getElementById('acc-code').value || '').trim();
                var name = String(document.getElementById('acc-name').value || '').trim();
                if (!code || !name) { Swal.showValidationMessage('الكود والاسم مطلوبان'); return false; }
                return {
                    company_id: _companyId(),
                    account_code: code,
                    account_name: name,
                    account_type: document.getElementById('acc-type').value,
                    parent_account_id: document.getElementById('acc-parent').value || null,
                    normal_balance: ['asset', 'expense'].indexOf(document.getElementById('acc-type').value) !== -1 ? 'debit' : 'credit',
                    is_active: true
                };
            }
        }).then(function (r) {
            if (r.isConfirmed) {
                _showLoader('جاري حفظ الحساب...');
                var promise = isEdit
                    ? supabase.from('chart_of_accounts').update({ account_name: r.value.account_name, account_type: r.value.account_type, parent_account_id: r.value.parent_account_id, normal_balance: r.value.normal_balance, is_active: true, updated_at: new Date().toISOString() }).eq('id', item.id).eq('company_id', _companyId())
                    : supabase.from('chart_of_accounts').insert(r.value);
                promise.then(function (res) { _handleResult(res, 'فشل حفظ الحساب'); _hideLoader(); _invalidate(); _showToast('تم الحفظ', 'success'); renderSubTab('accounts'); }).catch(function (e) { _hideLoader(); _showError(e.message); });
            } else if (r.isDenied && isEdit) {
                Swal.fire({ title: 'تأكيد الحذف', text: 'حذف ' + item.account_name + '؟', icon: 'warning', showCancelButton: true, confirmButtonText: 'حذف', confirmButtonColor: '#dc2626' }).then(function (dr) {
                    if (!dr.isConfirmed) return;
                    _showLoader('جاري الحذف...');
                    supabase.from('chart_of_accounts').delete().eq('id', item.id).eq('company_id', _companyId()).then(function (res) { _handleResult(res, 'فشل حذف الحساب'); _hideLoader(); _invalidate(); _showToast('تم الحذف', 'success'); renderSubTab('accounts'); }).catch(function (e) { _hideLoader(); _showError(e.message); });
                });
            }
        });
    }

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
                var d = definitions[i], existing = _accountByCode(d[0]), parentId = d[3] ? (codeMap[d[3]] || (_accountByCode(d[3]) || {}).id || null) : null;
                if (existing) {
                    codeMap[d[0]] = existing.id;
                    continue;
                }
                var res = await supabase.from('chart_of_accounts').insert({ company_id: companyId, account_code: d[0], account_name: d[1], account_type: d[2], parent_account_id: parentId, normal_balance: d[4], is_active: true }).select('id').single();
                _handleResult(res, 'فشل تهيئة الحساب ' + d[0]);
                codeMap[d[0]] = res.data.id;
            }
            // Re-attach parents for rows which already existed but had stale/null parent links.
            for (var j = 0; j < definitions.length; j++) {
                var x = definitions[j], p = x[3] ? (codeMap[x[3]] || null) : null;
                if (p) await supabase.from('chart_of_accounts').update({ parent_account_id: p }).eq('id', codeMap[x[0]]).eq('company_id', companyId);
            }
            _invalidate();
            _showToast('تمت التهيئة', 'success');
            renderSubTab('accounts');
        } catch (e) {
            _showError(e.message);
        } finally { _hideLoader(); }
    }

    // ==================== Journal ====================
    function _renderJournal() {
        var content = _byId('finance-content'); if (!content) return;
        var html = '<div class="bg-white rounded-2xl shadow-sm border p-4">' +
            '<h2 class="text-xl font-bold mb-4"><i class="fa-solid fa-book ml-2 text-indigo-600"></i>قيد يومي يدوي</h2>' +
            '<div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4"><div><label class="block text-sm font-bold">التاريخ</label><input type="date" id="journal-date" value="' + _today() + '" class="border rounded-lg p-2 w-full"></div><div><label class="block text-sm font-bold">المرجع</label><input type="text" id="journal-ref" class="border rounded-lg p-2 w-full" placeholder="مرجع"></div></div>' +
            '<div class="mb-4"><label class="block text-sm font-bold">الوصف</label><textarea id="journal-desc" rows="2" class="border rounded-lg p-2 w-full"></textarea></div>' +
            '<div><label class="block text-sm font-bold mb-2">سطور القيد</label><div id="journal-lines"></div><button type="button" onclick="RW_Finance._addJournalLine()" class="mt-2 text-indigo-600 font-bold"><i class="fa-solid fa-plus-circle ml-1"></i>إضافة سطر</button></div>' +
            '<div class="mt-4 p-3 bg-gray-50 rounded-lg flex justify-between"><span>مدين: <span id="j-debit">0.00</span></span><span>دائن: <span id="j-credit">0.00</span></span><span id="j-balance"></span></div>' +
            '<div class="mt-6 flex justify-end"><button type="button" onclick="RW_Finance._saveJournalEntry()" class="bg-indigo-600 text-white px-6 py-2 rounded-lg font-bold"><i class="fa-solid fa-check ml-1"></i>حفظ القيد</button></div>' +
            '</div>';
        _safeHtml(content, html);
        _addJournalLine(); _recalcJournalTotal();
    }

    function _journalAccountOptions() {
        return _cache.accountsFlat.map(function (a) { return '<option value="' + _esc(a.account_code) + '">' + _esc(a.account_name) + ' (' + _esc(a.account_code) + ')</option>'; }).join('');
    }

    function _addJournalLine() {
        var host = _byId('journal-lines'); if (!host) return;
        var cc = '<option value="">(بدون مركز)</option>' + _cache.costCenters.map(function (c) { return '<option value="' + _esc(c.id) + '">' + _esc(c.name) + ' (' + _esc(c.code) + ')</option>'; }).join('');
        var html = '<div class="journal-line grid grid-cols-12 gap-2 mb-2 bg-gray-50 p-2 rounded-lg">' +
            '<div class="col-span-3"><select class="border rounded p-1.5 w-full text-sm jl-account"><option value="">اختر الحساب</option>' + _journalAccountOptions() + '</select></div>' +
            '<div class="col-span-3"><select class="border rounded p-1.5 w-full text-sm jl-cost-center">' + cc + '</select></div>' +
            '<div class="col-span-2"><input type="number" step="0.01" min="0" class="border rounded p-1.5 w-full text-sm jl-debit" value="0" oninput="RW_Finance._recalcJournalTotal()"></div>' +
            '<div class="col-span-2"><input type="number" step="0.01" min="0" class="border rounded p-1.5 w-full text-sm jl-credit" value="0" oninput="RW_Finance._recalcJournalTotal()"></div>' +
            '<div class="col-span-2 flex justify-center items-center"><button type="button" onclick="RW_Finance._removeJournalLine(this)" class="text-red-500"><i class="fa-solid fa-circle-minus"></i></button></div></div>';
        host.insertAdjacentHTML('beforeend', html);
    }

    function _removeJournalLine(btn) { if (btn && btn.closest) btn.closest('.journal-line').remove(); _recalcJournalTotal(); }

    function _recalcJournalTotal() {
        var deb = 0, cred = 0;
        document.querySelectorAll('.jl-debit').forEach(function (el) { deb += Number(el.value || 0); });
        document.querySelectorAll('.jl-credit').forEach(function (el) { cred += Number(el.value || 0); });
        _safeText(_byId('j-debit'), _fmtNum(deb)); _safeText(_byId('j-credit'), _fmtNum(cred));
        var diff = Math.abs(deb - cred);
        _safeHtml(_byId('j-balance'), diff < 0.01 && deb > 0 ? '<span class="text-green-600 font-bold">✓ متوازن</span>' : '<span class="text-red-600 font-bold">⚠️ غير متوازن ' + _fmtNum(diff) + '</span>');
    }

    async function _saveJournalEntry() {
        var host = _byId('journal-lines');
        if (!host || host.dataset.journalSaving === '1') return;
        var lines = [], totalDebit = 0, totalCredit = 0;
        var rowEls = document.querySelectorAll('.journal-line');
        for (var i = 0; i < rowEls.length; i++) {
            var row = rowEls[i], accEl = row.querySelector('.jl-account'), dEl = row.querySelector('.jl-debit'), cEl = row.querySelector('.jl-credit'), ccEl = row.querySelector('.jl-cost-center');
            var code = String(accEl && accEl.value || '').trim(), debit = Number(dEl && dEl.value || 0), credit = Number(cEl && cEl.value || 0);
            if (!Number.isFinite(debit) || !Number.isFinite(credit) || debit < 0 || credit < 0) return _showToast('يوجد مبلغ غير صالح في السطر ' + (i + 1), 'error');
            if (debit > 0 && credit > 0) return _showToast('لا يجوز أن يحتوي السطر على مدين ودائن معًا', 'error');
            if (code && (debit || credit)) {
                var account = _accountByCode(code);
                if (!account) return _showToast('الحساب غير موجود في الشركة الحالية: ' + code, 'error');
                lines.push({ accountId: code, accountName: account.account_name, costCenterId: ccEl && ccEl.value ? ccEl.value : null, debit: debit, credit: credit });
                totalDebit += debit; totalCredit += credit;
            }
        }
        if (lines.length < 2) return _showToast('يجب إدخال سطرين على الأقل للقيد', 'warning');
        if (Math.abs(totalDebit - totalCredit) >= 0.01 || totalDebit <= 0) return _showToast('القيد غير متوازن', 'error');

        var op = _pendingOps.journal || (host.dataset.journalOperationId || _uuid());
        host.dataset.journalOperationId = op; host.dataset.journalSaving = '1'; _pendingOps.journal = op;
        _showLoader('جاري حفظ القيد...');
        try {
            var ses = await supabase.auth.getSession();
            var token = ses.data && ses.data.session ? ses.data.session.access_token : null;
            if (!token) throw new Error('انتهت الجلسة');
            var res = await fetch(RW_SUPABASE_URL + '/functions/v1/save-journal-entry', { method: 'POST', headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token }, body: JSON.stringify({ operation_id: op, date: _byId('journal-date').value || _today(), reference: _byId('journal-ref').value || '', description: _byId('journal-desc').value || '', entryType: 'Manual', lines: lines }) });
            var json = await res.json();
            if (!res.ok || !json || !json.success) throw new Error((json && json.error) || 'فشل حفظ القيد');
            _pendingOps.journal = null; delete host.dataset.journalOperationId; _showToast((json.duplicate ? 'القيد موجود بالفعل: ' : 'تم حفظ القيد ') + (json.entry_code || ''), 'success'); renderSubTab('journal');
        } catch (e) { _showError(e.message); }
        finally { host.dataset.journalSaving = '0'; _hideLoader(); }
    }

    // ==================== Cash vouchers ====================
    function _treasuryOptions(selectedId) {
        return _cache.treasury.map(function (t) { return '<option value="' + _esc(t.id) + '" ' + (t.id === selectedId ? 'selected' : '') + '>' + _esc(t.account_name) + ' (' + _esc(t.account_code) + ')</option>'; }).join('');
    }

    function _accountOptions(includeAll) {
        var items = includeAll ? _cache.accountsFlat : _cache.accountsFlat.filter(function (a) { return a.account_type !== 'asset' || a.account_code !== '124'; });
        return items.map(function (a) { return '<option value="' + _esc(a.id) + '">' + _esc(a.account_name) + ' (' + _esc(a.account_code) + ')</option>'; }).join('');
    }

    function _cashAccountId() {
        var a = _accountByCode('121');
        if (!a) throw new Error('CASH_ACCOUNT_121_NOT_CONFIGURED');
        return a.id;
    }

    function _getPendingOperation(type, host) {
        var op = _pendingOps[type] || (host && host.dataset.operationId) || _uuid();
        if (host) host.dataset.operationId = op;
        _pendingOps[type] = op;
        return op;
    }

    function _renderReceipts() {
        _renderCashList('Receipt', 'receipts', 'سندات القبض', 'green', '_newReceipt');
    }

    function _renderPayments() {
        _renderCashList('Payment', 'payments', 'سندات الصرف', 'red', '_newPayment');
    }

    function _renderCashList(type, tab, title, color, action) {
        var content = _byId('finance-content'); if (!content) return;
        var other = type === 'Receipt' ? 'سندات القبض' : 'سندات الصرف';
        content.innerHTML = '<div class="text-center py-8">جاري تحميل ' + other + '...</div>';
        var companyId = _companyId();
        supabase.from('cash_box').select('*').eq('company_id', companyId).eq('type', type).order('voucher_date', { ascending: false }).order('created_at', { ascending: false }).then(function (res) {
            _handleResult(res, 'فشل تحميل ' + other);
            var rows = res.data || [];
            var html = '<div class="bg-white rounded-2xl shadow-sm border p-4"><div class="flex justify-between items-center mb-4"><h2 class="text-xl font-bold">' + (type === 'Receipt' ? '<i class="fa-solid fa-arrow-down ml-2 text-green-600"></i>' : '<i class="fa-solid fa-arrow-up ml-2 text-red-600"></i>') + _esc(title) + '</h2><button type="button" onclick="RW_Finance.' + action + '()" class="bg-' + color + '-600 text-white px-4 py-2 rounded-xl"><i class="fa-solid fa-plus ml-1"></i>جديد</button></div>';
            if (!rows.length) html += '<div class="text-center py-8 text-gray-500">لا توجد سجلات</div>';
            else {
                html += '<div class="overflow-x-auto"><table class="w-full text-sm border-collapse"><thead><tr class="bg-gray-50"><th class="p-2 border">التاريخ</th><th class="p-2 border">المرجع</th><th class="p-2 border">المبلغ</th><th class="p-2 border">الخزينة</th><th class="p-2 border">الحالة</th></tr></thead><tbody>';
                for (var i = 0; i < rows.length; i++) {
                    var r = rows[i];
                    html += '<tr class="border-t"><td class="p-2">' + _esc(r.voucher_date) + '</td><td class="p-2">' + _esc(r.reference || r.voucher_code) + '</td><td class="p-2 font-bold">' + _fmtNum(r.amount) + '</td><td class="p-2">' + _esc(r.treasury_id) + '</td><td class="p-2">' + _esc(r.status || '') + '</td></tr>';
                }
                html += '</tbody></table></div>';
            }
            _safeHtml(content, html + '</div>');
        }).catch(function (e) { _safeHtml(content, '<div class="text-center py-8 text-red-500">' + _esc(e.message) + '</div>'); });
    }

    function _cashDialog(type) {
        var isReceipt = type === 'Receipt';
        var hostId = isReceipt ? 'rcpt-lines' : 'pmt-lines';
        var prefix = isReceipt ? 'rcpt' : 'pmt';
        var operation = _pendingOps[isReceipt ? 'receipt' : 'payment'];
        var treasuryDefault = _cache.treasury.length === 1 ? _cache.treasury[0].id : '';
        var cashAccount;
        try { cashAccount = _cashAccountId(); } catch (e) { cashAccount = ''; }

        var html = '<div class="bg-white rounded-2xl shadow-sm border p-4"><div class="flex justify-between items-center mb-4"><h2 class="text-xl font-bold">' + (isReceipt ? 'سند قبض جديد' : 'سند صرف جديد') + '</h2><button type="button" onclick="RW_Finance.renderSubTab(\'' + (isReceipt ? 'receipts' : 'payments') + '\')" class="text-gray-500"><i class="fa-solid fa-xmark text-xl"></i></button></div>' +
            '<div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4"><div><label class="block text-sm font-bold">التاريخ</label><input type="date" id="' + prefix + '-date" class="border rounded-lg p-2 w-full" value="' + _today() + '"></div>' +
            '<div><label class="block text-sm font-bold">الخزينة *</label><select id="' + prefix + '-treasury" class="border rounded-lg p-2 w-full">' + _treasuryOptions(treasuryDefault) + '</select></div>' +
            '<div><label class="block text-sm font-bold">الحساب المقابل *</label><select id="' + prefix + '-offset" class="border rounded-lg p-2 w-full"><option value="">اختر الحساب</option>' + _accountOptions(true) + '</select></div></div>' +
            '<div class="mb-4"><label class="block text-sm font-bold mb-2">تفاصيل السند (يمكن إدخال أكثر من بند؛ إجمالي البنود هو قيمة العملية)</label><div id="' + hostId + '"></div><button type="button" onclick="RW_Finance.' + (isReceipt ? '_addReceiptLine' : '_addPaymentLine') + '()" class="mt-2 text-' + (isReceipt ? 'green' : 'red') + '-600 font-bold"><i class="fa-solid fa-plus-circle ml-1"></i>إضافة بند</button></div>' +
            '<div class="p-3 bg-gray-50 rounded-lg mb-4">الإجمالي: <span id="' + prefix + '-total">0.00</span></div>' +
            '<div><label class="block text-sm font-bold">المرجع</label><input id="' + prefix + '-reference" class="border rounded-lg p-2 w-full" placeholder="مرجع اختياري"></div>' +
            '<div class="flex justify-end gap-3 mt-6"><button type="button" onclick="RW_Finance.renderSubTab(\'' + (isReceipt ? 'receipts' : 'payments') + '\')" class="px-4 py-2 border rounded-lg">إلغاء</button><button type="button" onclick="RW_Finance.' + (isReceipt ? '_saveReceipt' : '_savePayment') + '()" class="px-6 py-2 bg-' + (isReceipt ? 'green' : 'red') + '-600 text-white rounded-lg font-bold">حفظ</button></div>' +
            '<input type="hidden" id="' + prefix + '-cash-account" value="' + _esc(cashAccount) + '">' +
            '<input type="hidden" id="' + prefix + '-operation" value="' + _esc(operation || '') + '"></div>';
        _safeHtml(_byId('finance-content'), html);
        (isReceipt ? _addReceiptLine : _addPaymentLine)();
    }

    function _newReceipt() { _cashDialog('Receipt'); }
    function _newPayment() { _cashDialog('Payment'); }

    function _addReceiptLine() {
        var host = _byId('rcpt-lines'); if (!host) return;
        host.insertAdjacentHTML('beforeend', '<div class="rcpt-line grid grid-cols-12 gap-2 mb-2 bg-gray-50 p-2 rounded-lg"><div class="col-span-5"><input type="text" class="rcpt-line-account border rounded p-1.5 w-full text-sm" placeholder="اسم العميل / البيان"></div><div class="col-span-3"><input type="text" class="rcpt-line-desc border rounded p-1.5 w-full text-sm" placeholder="وصف"></div><div class="col-span-3"><input type="number" step="0.01" min="0" class="rcpt-line-amount border rounded p-1.5 w-full text-sm" oninput="RW_Finance._recalcReceiptTotal()"></div><div class="col-span-1 flex justify-center"><button type="button" onclick="RW_Finance._removeReceiptLine(this)" class="text-red-500"><i class="fa-solid fa-circle-minus"></i></button></div></div>');
    }

    function _removeReceiptLine(btn) { if (btn && btn.closest) btn.closest('.rcpt-line').remove(); _recalcReceiptTotal(); }
    function _recalcReceiptTotal() { var total = 0; document.querySelectorAll('.rcpt-line-amount').forEach(function (el) { total += Number(el.value || 0); }); _safeText(_byId('rcpt-total'), _fmtNum(total)); }

    function _addPaymentLine() {
        var host = _byId('pmt-lines'); if (!host) return;
        host.insertAdjacentHTML('beforeend', '<div class="pmt-line grid grid-cols-12 gap-2 mb-2 bg-gray-50 p-2 rounded-lg"><div class="col-span-5"><input type="text" class="pmt-line-account border rounded p-1.5 w-full text-sm" placeholder="اسم المستفيد / البيان"></div><div class="col-span-3"><input type="text" class="pmt-line-desc border rounded p-1.5 w-full text-sm" placeholder="وصف"></div><div class="col-span-3"><input type="number" step="0.01" min="0" class="pmt-line-amount border rounded p-1.5 w-full text-sm" oninput="RW_Finance._recalcPaymentTotal()"></div><div class="col-span-1 flex justify-center"><button type="button" onclick="RW_Finance._removePaymentLine(this)" class="text-red-500"><i class="fa-solid fa-circle-minus"></i></button></div></div>');
    }

    function _removePaymentLine(btn) { if (btn && btn.closest) btn.closest('.pmt-line').remove(); _recalcPaymentTotal(); }
    function _recalcPaymentTotal() { var total = 0; document.querySelectorAll('.pmt-line-amount').forEach(function (el) { total += Number(el.value || 0); }); _safeText(_byId('pmt-total'), _fmtNum(total)); }

    async function _saveCashVoucher(type) {
        var isReceipt = type === 'Receipt', prefix = isReceipt ? 'rcpt' : 'pmt', opKey = isReceipt ? 'receipt' : 'payment';
        var lines = [];
        document.querySelectorAll('.' + prefix + '-line').forEach(function (row) {
            var amount = Number(row.querySelector('.' + prefix + '-line-amount').value || 0);
            if (amount > 0) lines.push({ accountName: row.querySelector('.' + prefix + '-line-account').value || '', description: row.querySelector('.' + prefix + '-line-desc').value || '', amount: amount });
        });
        if (!lines.length) return _showToast('أضف بندًا واحدًا على الأقل', 'warning');
        var treasuryId = _byId(prefix + '-treasury').value;
        var offsetId = _byId(prefix + '-offset').value;
        var cashId = _byId(prefix + '-cash-account').value;
        if (!treasuryId) return _showToast('اختيار الخزينة مطلوب', 'warning');
        if (!cashId) return _showToast('حساب النقدية 121 غير مهيأ', 'error');
        if (!offsetId) return _showToast('اختر الحساب المقابل صراحةً', 'warning');
        var host = _byId(prefix + '-lines');
        var operationId = _getPendingOperation(opKey, host);
        var payload = {
            header: {
                operationId: operationId,
                date: _byId(prefix + '-date').value || _today(),
                reference: _byId(prefix + '-reference').value || null,
                notes: '',
                treasuryId: treasuryId,
                cashAccountId: cashId,
                offsetAccountId: offsetId,
                mainAccountName: lines.map(function (x) { return x.accountName; }).filter(Boolean).join('، ') || null
            },
            lines: lines
        };
        _showLoader(isReceipt ? 'جاري حفظ سند القبض...' : 'جاري حفظ سند الصرف...');
        try {
            var ses = await supabase.auth.getSession(), token = ses.data && ses.data.session ? ses.data.session.access_token : null;
            if (!token) throw new Error('انتهت الجلسة');
            var endpoint = isReceipt ? 'save-receipt-voucher' : 'save-payment-voucher';
            var res = await fetch(RW_SUPABASE_URL + '/functions/v1/' + endpoint, { method: 'POST', headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token }, body: JSON.stringify(payload) });
            var json = await res.json();
            if (!res.ok || !json || json.success === false) throw new Error((json && json.error) || 'فشل تنفيذ سند النقدية');
            _pendingOps[opKey] = null;
            _showToast(json.duplicate ? 'العملية موجودة بالفعل ولم تُكرر.' : 'تم الحفظ', 'success');
            renderSubTab(isReceipt ? 'receipts' : 'payments');
        } catch (e) { _showError(e.message); }
        finally { _hideLoader(); }
    }

    function _saveReceipt() { return _saveCashVoucher('Receipt'); }
    function _savePayment() { return _saveCashVoucher('Payment'); }

    // ==================== Transfers ====================
    function _renderTransfers() {
        var content = _byId('finance-content'); if (!content) return;
        content.innerHTML = '<div class="text-center py-8">جاري تحميل التحويلات...</div>';
        supabase.from('cash_box').select('*').eq('company_id', _companyId()).in('type', ['Transfer-Out', 'Transfer-In']).order('voucher_date', { ascending: false }).then(function (r) {
            _handleResult(r, 'فشل تحميل التحويلات');
            var merged = {};
            (r.data || []).forEach(function (t) {
                var key = t.reference || t.voucher_code || t.id;
                if (!merged[key]) merged[key] = { date: t.voucher_date, fromCash: '', toCash: '', amount: 0, ref: key };
                if (t.type === 'Transfer-Out') merged[key].fromCash = t.treasury_id;
                if (t.type === 'Transfer-In') merged[key].toCash = t.treasury_id;
                merged[key].amount = Math.max(merged[key].amount, Number(t.amount || 0));
            });
            var rows = Object.keys(merged).map(function (k) { return merged[k]; });
            var html = '<div class="bg-white rounded-2xl shadow-sm border p-4"><div class="flex justify-between items-center mb-4"><h2 class="text-xl font-bold"><i class="fa-solid fa-right-left ml-2 text-purple-600"></i>التحويلات</h2><button type="button" onclick="RW_Finance._newTransfer()" class="bg-purple-600 text-white px-4 py-2 rounded-xl">تحويل جديد</button></div>';
            if (!rows.length) html += '<div class="text-center py-8 text-gray-500">لا توجد تحويلات</div>';
            else {
                html += '<div class="overflow-x-auto"><table class="w-full text-sm border-collapse"><thead><tr class="bg-gray-50"><th class="p-2 border">التاريخ</th><th class="p-2 border">من</th><th class="p-2 border">إلى</th><th class="p-2 border">المبلغ</th><th class="p-2 border">المرجع</th></tr></thead><tbody>';
                rows.forEach(function (t) { html += '<tr class="border-t"><td class="p-2">' + _esc(t.date) + '</td><td class="p-2">' + _esc(t.fromCash) + '</td><td class="p-2">' + _esc(t.toCash) + '</td><td class="p-2 font-bold text-purple-600">' + _fmtNum(t.amount) + '</td><td class="p-2">' + _esc(t.ref) + '</td></tr>'; });
                html += '</tbody></table></div>';
            }
            _safeHtml(content, html + '</div>');
        }).catch(function (e) { _safeHtml(content, '<div class="text-center py-8 text-red-500">' + _esc(e.message) + '</div>'); });
    }

    function _newTransfer() {
        var treasuryOpts = _treasuryOptions(_cache.treasury.length ? _cache.treasury[0].id : ''), accountOpts = '<option value="">اختر الحساب</option>' + _accountOptions(true);
        var html = '<div class="bg-white rounded-2xl shadow-sm border p-4"><div class="flex justify-between items-center mb-4"><h2 class="text-xl font-bold">تحويل جديد</h2><button type="button" onclick="RW_Finance.renderSubTab(\'transfers\')" class="text-gray-500"><i class="fa-solid fa-xmark text-xl"></i></button></div>' +
            '<div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">' +
            '<div><label class="block text-sm font-bold">من خزينة *</label><select id="trf-from" class="border rounded-lg p-2 w-full">' + treasuryOpts + '</select></div>' +
            '<div><label class="block text-sm font-bold">إلى خزينة *</label><select id="trf-to" class="border rounded-lg p-2 w-full">' + treasuryOpts + '</select></div>' +
            '<div><label class="block text-sm font-bold">حساب المصدر *</label><select id="trf-source-account" class="border rounded-lg p-2 w-full">' + accountOpts + '</select></div>' +
            '<div><label class="block text-sm font-bold">حساب الوجهة *</label><select id="trf-target-account" class="border rounded-lg p-2 w-full">' + accountOpts + '</select></div></div>' +
            '<div class="grid grid-cols-1 md:grid-cols-2 gap-4"><div><label class="block text-sm font-bold">المبلغ *</label><input type="number" min="0.01" step="0.01" id="trf-amount" class="border rounded-lg p-2 w-full"></div><div><label class="block text-sm font-bold">المرجع</label><input id="trf-reference" class="border rounded-lg p-2 w-full"></div></div>' +
            '<div class="flex justify-end gap-3 mt-6"><button type="button" onclick="RW_Finance.renderSubTab(\'transfers\')" class="px-4 py-2 border rounded-lg">إلغاء</button><button type="button" onclick="RW_Finance._saveTransfer()" class="px-6 py-2 bg-purple-600 text-white rounded-lg font-bold">حفظ</button></div></div>';
        _safeHtml(_byId('finance-content'), html);
    }

    async function _saveTransfer() {
        var fromId = _byId('trf-from').value, toId = _byId('trf-to').value, sourceAccountId = _byId('trf-source-account').value, targetAccountId = _byId('trf-target-account').value, amount = Number(_byId('trf-amount').value || 0);
        if (!fromId || !toId || fromId === toId || !sourceAccountId || !targetAccountId || !(amount > 0)) return _showToast('بيانات التحويل غير صحيحة أو غير مكتملة', 'warning');
        var op = _pendingOps.transfer || _uuid(); _pendingOps.transfer = op; _showLoader('جاري تنفيذ التحويل...');
        try {
            var ses = await supabase.auth.getSession(), token = ses.data && ses.data.session ? ses.data.session.access_token : null;
            if (!token) throw new Error('انتهت الجلسة');
            var res = await fetch(RW_SUPABASE_URL + '/functions/v1/save-transfer-voucher', { method: 'POST', headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token }, body: JSON.stringify({ operationId: op, sourceTreasuryId: fromId, targetTreasuryId: toId, sourceAccountId: sourceAccountId, targetAccountId: targetAccountId, amount: amount, transferDate: _today(), reference: _byId('trf-reference').value || null, notes: '' }) });
            var json = await res.json();
            if (!res.ok || !json || json.success === false) throw new Error((json && json.error) || 'فشل تنفيذ التحويل');
            _pendingOps.transfer = null; _showToast(json.duplicate ? 'التحويل موجود بالفعل ولم يُكرر.' : 'تم التحويل', 'success'); renderSubTab('transfers');
        } catch (e) { _showError(e.message); }
        finally { _hideLoader(); }
    }

    // ==================== Reports ====================
    function _renderReports() {
        var content = _byId('finance-content'); if (!content) return;
        var html = '<div class="bg-white rounded-2xl shadow-sm border p-4"><h2 class="text-xl font-bold mb-4"><i class="fa-solid fa-chart-pie ml-2 text-teal-600"></i>التقارير المالية</h2>' +
            '<div class="grid grid-cols-1 md:grid-cols-3 gap-3 mb-4"><div><label class="block text-sm font-bold">من تاريخ</label><input id="rp-from" type="date" value="' + _today() + '" class="border rounded-lg p-2 w-full"></div><div><label class="block text-sm font-bold">إلى تاريخ</label><input id="rp-to" type="date" value="' + _today() + '" class="border rounded-lg p-2 w-full"></div></div>' +
            '<div class="flex flex-wrap gap-2 mb-4"><button type="button" onclick="RW_Finance._trialBalance()" class="bg-teal-600 text-white px-4 py-2 rounded-lg">ميزان المراجعة</button><button type="button" onclick="RW_Finance._profitLoss()" class="bg-emerald-600 text-white px-4 py-2 rounded-lg">قائمة الدخل</button><button type="button" onclick="RW_Finance._balanceSheet()" class="bg-indigo-600 text-white px-4 py-2 rounded-lg">الميزانية العمومية</button><button type="button" onclick="RW_Finance._costCenterProfitLoss()" class="bg-amber-600 text-white px-4 py-2 rounded-lg">أرباح/خسائر مراكز التكلفة</button></div>' +
            '<div id="report-output"></div></div>';
        _safeHtml(content, html);
    }

    async function _trialBalance() {
        var out = _byId('report-output'); if (!out) return;
        _safeHtml(out, '<div class="text-center py-8">جاري التحميل...</div>');
        try {
            var from = _byId('rp-from').value || _today(), to = _byId('rp-to').value || _today();
            var r = await supabase.rpc('get_trial_balance', { p_from_date: from, p_to_date: to }); _handleResult(r, 'فشل تحميل ميزان المراجعة');
            var rows = r.data || [], html = '<table class="w-full text-sm border"><thead><tr class="bg-gray-50"><th class="p-2">الكود</th><th class="p-2">الاسم</th><th class="p-2">مدين</th><th class="p-2">دائن</th><th class="p-2">الصافي</th></tr></thead><tbody>';
            rows.forEach(function (x) { html += '<tr class="border-t"><td class="p-2">' + _esc(x.account_id) + '</td><td class="p-2">' + _esc(x.account_name) + '</td><td class="p-2">' + _fmtNum(x.total_debit) + '</td><td class="p-2">' + _fmtNum(x.total_credit) + '</td><td class="p-2">' + _fmtNum(x.net_balance) + '</td></tr>'; });
            _safeHtml(out, html + '</tbody></table>');
        } catch (e) { _safeHtml(out, '<div class="text-center py-8 text-red-500">' + _esc(e.message) + '</div>'); }
    }

    async function _profitLoss() {
        var out = _byId('report-output'); if (!out) return;
        _safeHtml(out, '<div class="text-center py-8">جاري التحميل...</div>');
        try {
            var from = _byId('rp-from').value || _today(), to = _byId('rp-to').value || _today();
            var r = await supabase.rpc('get_profit_loss', { p_from_date: from, p_to_date: to }); _handleResult(r, 'فشل تحميل قائمة الدخل');
            var rows = r.data || [], revenue = 0, expenses = 0;
            rows.forEach(function (x) { if (x.account_type === 'revenue') revenue += Number(x.total_amount || 0); if (x.account_type === 'expense') expenses += Number(x.total_amount || 0); });
            var net = revenue - expenses;
            var html = '<div class="grid grid-cols-1 md:grid-cols-3 gap-3 mb-4"><div class="p-4 rounded-xl bg-green-50"><div class="text-sm text-gray-500">الإيرادات</div><div class="text-2xl font-black text-green-700">' + _fmtNum(revenue) + '</div></div><div class="p-4 rounded-xl bg-red-50"><div class="text-sm text-gray-500">المصروفات</div><div class="text-2xl font-black text-red-700">' + _fmtNum(expenses) + '</div></div><div class="p-4 rounded-xl bg-blue-50"><div class="text-sm text-gray-500">صافي النتيجة</div><div class="text-2xl font-black">' + _fmtNum(net) + '</div></div></div>' +
                '<table class="w-full text-sm border"><thead><tr class="bg-gray-50"><th class="p-2">النوع</th><th class="p-2">الحساب</th><th class="p-2">المبلغ</th></tr></thead><tbody>';
            rows.forEach(function (x) { html += '<tr class="border-t"><td class="p-2">' + _esc(x.account_type) + '</td><td class="p-2">' + _esc(x.account_name) + '</td><td class="p-2">' + _fmtNum(x.total_amount) + '</td></tr>'; });
            _safeHtml(out, html + '</tbody></table>');
        } catch (e) { _safeHtml(out, '<div class="text-center py-8 text-red-500">' + _esc(e.message) + '</div>'); }
    }

    async function _balanceSheet() {
        var out = _byId('report-output'); if (!out) return;
        _safeHtml(out, '<div class="text-center py-8">جاري التحميل...</div>');
        try {
            var r = await supabase.rpc('get_balance_sheet', { p_as_of: (_byId('rp-to') && _byId('rp-to').value) || _today() }); _handleResult(r, 'فشل تحميل الميزانية العمومية');
            var data = r.data || [], assets = data.filter(function (x) { return x.account_type === 'asset'; }), liabilities = data.filter(function (x) { return x.account_type === 'liability'; }), equity = data.filter(function (x) { return x.account_type === 'equity'; });
            function section(title, rows, cls) { var h = '<div class="' + cls + ' p-4 rounded-xl"><h4 class="font-black text-lg mb-3">' + title + '</h4><table class="w-full text-sm">'; rows.forEach(function (x) { h += '<tr class="border-b"><td class="py-2">' + _esc(x.account_name) + '</td><td class="py-2 text-left font-bold">' + _fmtNum(x.balance) + '</td></tr>'; }); return h + '</table></div>'; }
            _safeHtml(out, '<div class="grid grid-cols-1 md:grid-cols-2 gap-6">' + section('الأصول', assets, 'bg-blue-50') + section('الخصوم', liabilities, 'bg-red-50') + section('حقوق الملكية', equity, 'bg-emerald-50') + '</div>');
        } catch (e) { _safeHtml(out, '<div class="text-center py-8 text-red-500">' + _esc(e.message) + '</div>'); }
    }

    async function _costCenterProfitLoss() {
        var out = _byId('report-output'); if (!out) return;
        _safeHtml(out, '<div class="text-center py-8">جاري التحميل...</div>');
        try {
            var from = _byId('rp-from').value || _today(), to = _byId('rp-to').value || _today();
            var r = await supabase.rpc('get_pnl_by_cost_center', { p_from_date: from, p_to_date: to }); _handleResult(r, 'فشل تحميل تقرير مراكز التكلفة');
            var rows = r.data || [], html = '<table class="w-full text-sm border"><thead><tr class="bg-gray-50"><th class="p-2">المركز</th><th class="p-2">الإيرادات</th><th class="p-2">المصروفات</th><th class="p-2">الصافي</th></tr></thead><tbody>';
            rows.forEach(function (x) { html += '<tr class="border-t"><td class="p-2">' + _esc(x.cost_center_name) + '</td><td class="p-2">' + _fmtNum(x.revenue) + '</td><td class="p-2">' + _fmtNum(x.expenses) + '</td><td class="p-2 font-bold">' + _fmtNum(x.net_income) + '</td></tr>'; });
            _safeHtml(out, rows.length ? html + '</tbody></table>' : '<div class="text-center py-8 text-gray-500">لا توجد بيانات</div>');
        } catch (e) { _safeHtml(out, '<div class="text-center py-8 text-red-500">' + _esc(e.message) + '</div>'); }
    }

    // ==================== Budgets ====================
    function _renderBudgets() {
        var content = _byId('finance-content'); if (!content) return;
        var year = new Date().getFullYear(), month = new Date().getMonth() + 1;
        var years = ''; for (var y = year - 2; y <= year + 1; y++) years += '<option value="' + y + '" ' + (y === year ? 'selected' : '') + '>' + y + '</option>';
        var months = ['', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
        var mopts = ''; for (var m = 1; m <= 12; m++) mopts += '<option value="' + m + '" ' + (m === month ? 'selected' : '') + '>' + months[m] + '</option>';
        var cc = '<option value="">الكل</option>' + _cache.costCenters.map(function (c) { return '<option value="' + _esc(c.id) + '">' + _esc(c.name) + '</option>'; }).join('');
        var html = '<div class="bg-white rounded-2xl shadow-sm border p-4"><h2 class="text-xl font-bold mb-4">الموازنات التقديرية</h2><div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-4">' +
            '<div><label class="block text-sm font-bold">السنة</label><select id="budget-year" class="border rounded-lg p-2 w-full">' + years + '</select></div>' +
            '<div><label class="block text-sm font-bold">الشهر</label><select id="budget-month" class="border rounded-lg p-2 w-full">' + mopts + '</select></div>' +
            '<div><label class="block text-sm font-bold">مركز التكلفة</label><select id="budget-cc" class="border rounded-lg p-2 w-full">' + cc + '</select></div>' +
            '<div class="flex items-end"><button type="button" onclick="RW_Finance._loadBudgetsList()" class="bg-indigo-600 text-white px-4 py-2 rounded-lg font-bold w-full">عرض</button></div></div><div id="budgets-list"></div></div>';
        _safeHtml(content, html); _loadBudgetsList();
    }

    async function _loadBudgetsList() {
        var list = _byId('budgets-list'); if (!list) return;
        _safeHtml(list, '<div class="text-center py-8">جاري التحميل...</div>');
        try {
            var y = Number(_byId('budget-year').value), m = Number(_byId('budget-month').value), cc = _byId('budget-cc').value || null;
            var r = await supabase.rpc('get_budget_vs_actual', { p_year: y, p_month: m, p_cost_center_id: cc }); _handleResult(r, 'فشل تحميل الموازنة');
            var rows = r.data || [], html = '<table class="w-full text-sm border-collapse"><thead><tr class="bg-indigo-50"><th class="p-2 border">الحساب</th><th class="p-2 border">الموازنة</th><th class="p-2 border">الفعلي</th><th class="p-2 border">الانحراف</th><th class="p-2 border">%</th><th class="p-2 border">الحالة</th><th class="p-2 border">تعديل</th></tr></thead><tbody>';
            rows.forEach(function (row) {
                var status = row.status === 'within' ? '<span class="bg-green-100 text-green-700 px-2 py-1 rounded-full text-xs">ضمن</span>' : row.status === 'over' ? '<span class="bg-red-100 text-red-700 px-2 py-1 rounded-full text-xs">تجاوز</span>' : row.status === 'under' ? '<span class="bg-blue-100 text-blue-700 px-2 py-1 rounded-full text-xs">أقل</span>' : '<span class="bg-gray-100 text-gray-500 px-2 py-1 rounded-full text-xs">بدون</span>';
                html += '<tr class="border-t"><td class="p-2">' + _esc(row.account_name) + ' (' + _esc(row.account_code) + ')</td><td class="p-2">' + _fmtNum(row.budgeted_amount) + '</td><td class="p-2">' + _fmtNum(row.actual_amount) + '</td><td class="p-2">' + _fmtNum(row.variance) + '</td><td class="p-2">' + _fmtNum(row.variance_percent) + '%</td><td class="p-2">' + status + '</td><td class="p-2"><button type="button" onclick="RW_Finance._editBudget(\'' + _esc(row.account_id) + '\',\'' + _esc(row.account_name).replace(/'/g, '&#39;') + '\',' + y + ',' + m + ')" class="text-indigo-600"><i class="fa-solid fa-pen-to-square"></i></button></td></tr>';
            });
            _safeHtml(list, rows.length ? html + '</tbody></table>' : '<div class="text-center py-8 text-gray-500">لا توجد بيانات</div>');
        } catch (e) { _safeHtml(list, '<div class="text-center py-8 text-red-500">' + _esc(e.message) + '</div>'); }
    }

    function _editBudget(accountId, accountName, year, month) {
        var ccId = _byId('budget-cc') ? (_byId('budget-cc').value || null) : null;
        if (!_cache.accountMap[accountId]) return _showToast('الحساب غير تابع للشركة الحالية', 'error');
        Swal.fire({
            title: 'تعيين موازنة: ' + accountName,
            html: '<div class="text-right space-y-3"><p class="text-sm text-gray-500">' + _esc(month) + ' / ' + _esc(year) + '</p><label class="block text-sm font-bold">المبلغ المخطط</label><input type="number" id="budget-amount" min="0" step="0.01" class="swal2-input w-full" value="0"></div>',
            showCancelButton: true, confirmButtonText: 'حفظ', cancelButtonText: 'إلغاء',
            preConfirm: function () { var n = Number(document.getElementById('budget-amount').value || 0); if (!Number.isFinite(n) || n < 0) { Swal.showValidationMessage('المبلغ غير صالح'); return false; } return n; }
        }).then(function (r) {
            if (!r.isConfirmed) return;
            _showLoader('جاري حفظ الموازنة...');
            supabase.from('budgets').upsert({ account_id: accountId, cost_center_id: ccId, budget_year: year, budget_month: month, budgeted_amount: r.value, updated_at: new Date().toISOString() }, { onConflict: 'cost_center_id,account_id,budget_year,budget_month' }).then(function (res) {
                _handleResult(res, 'فشل حفظ الموازنة'); _hideLoader(); _showToast('تم الحفظ', 'success'); _loadBudgetsList();
            }).catch(function (e) { _hideLoader(); _showError(e.message); });
        });
    }

    return {
        render: render,
        renderSubTab: renderSubTab,
        _filterTreasury: _filterTreasury,
        _openTreasuryDialog: _openTreasuryDialog,
        _editTreasury: _editTreasury,
        _filterAccounts: _filterAccounts,
        _openAccountDialog: _openAccountDialog,
        _seedAccounts: _seedAccounts,
        _addJournalLine: _addJournalLine,
        _removeJournalLine: _removeJournalLine,
        _recalcJournalTotal: _recalcJournalTotal,
        _saveJournalEntry: _saveJournalEntry,
        _newReceipt: _newReceipt,
        _addReceiptLine: _addReceiptLine,
        _removeReceiptLine: _removeReceiptLine,
        _recalcReceiptTotal: _recalcReceiptTotal,
        _saveReceipt: _saveReceipt,
        _newPayment: _newPayment,
        _addPaymentLine: _addPaymentLine,
        _removePaymentLine: _removePaymentLine,
        _recalcPaymentTotal: _recalcPaymentTotal,
        _savePayment: _savePayment,
        _newTransfer: _newTransfer,
        _saveTransfer: _saveTransfer,
        _trialBalance: _trialBalance,
        _profitLoss: _profitLoss,
        _renderBudgets: _renderBudgets,
        _loadBudgetsList: _loadBudgetsList,
        _editBudget: _editBudget,
        _balanceSheet: _balanceSheet,
        _costCenterProfitLoss: _costCenterProfitLoss
    };
})();

window.RW_Finance = RW_Finance;
