// ============================================================
// RW_Finance – الحسابات والمالية (وحدة كاملة - Supabase مباشر)
// ============================================================
var RW_Finance = (function() {
    function _showLoader(m) { try { if (typeof showLoader === 'function') showLoader(m || 'جاري التحميل...'); } catch(e) { console.error(e); } }
    function _hideLoader() { try { if (typeof hideLoader === 'function') hideLoader(); } catch(e) { console.error(e); } }
    function _showToast(m, t) { try { if (typeof showToast === 'function') showToast(m, t || 'success'); } catch(e) { alert(m); } }
    function _fmtNum(n) { return parseFloat(n || 0).toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ','); }
    function _esc(s) { return String(s == null ? '' : s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;'); }

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
    var _cache = { loaded: false, accountsTree: [], accountsFlat: [], treasury: [] };

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
    function _refreshCache() { _cache.loaded = false; }

    function render() { renderSubTab('treasury'); }

    function renderSubTab(subTab) {
        var tab = subTab || 'treasury';
        _loadAllData(function() {
            var container = byId('rw-page-container');
            if (!container) return;
            safeText(byId('rw-header-title'), 'الحسابات والمالية');
            var tabs = [
                { id: 'treasury', label: 'الخزائن والبنوك' }, { id: 'accounts', label: 'دليل الحسابات' },
                { id: 'journal', label: 'قيود يومية' }, { id: 'receipts', label: 'سندات القبض' },
                { id: 'payments', label: 'سندات الصرف' }, { id: 'transfers', label: 'التحويلات' },
                { id: 'reports', label: 'التقارير المالية' }, { id: 'budgets', label: 'الموازنات' }
            ];
            var html = '<div class="p-4"><div class="flex flex-wrap gap-2 border-b pb-3 mb-4">';
            for (var i = 0; i < tabs.length; i++) {
                var activeClass = (tab === tabs[i].id) ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200';
                html += '<button onclick="RW_Finance.renderSubTab(\'' + tabs[i].id + '\')" class="px-4 py-2 rounded-xl font-bold text-sm transition ' + activeClass + '">' + tabs[i].label + '</button>';
            }
            html += '</div><div id="finance-content"></div></div>';
            safeHTML(container, html);
            if (tab === 'treasury') _renderTreasury();
            else if (tab === 'accounts') _renderAccounts();
            else if (tab === 'journal') _renderJournal();
            else if (tab === 'receipts') _renderReceipts();
            else if (tab === 'payments') _renderPayments();
            else if (tab === 'transfers') _renderTransfers();
            else if (tab === 'reports') _renderReports();
            else if (tab === 'budgets') _renderBudgets();
        });
    }

    // ==================== الخزائن والبنوك ====================
    function _renderTreasury() {
        var content = byId('finance-content'); if (!content) return;
        var data = _cache.treasury;
        var html = '<div class="bg-white rounded-2xl shadow-sm border p-4"><div class="flex justify-between items-center mb-4"><h2 class="text-xl font-bold"><i class="fa-solid fa-vault ml-2 text-blue-600"></i>الخزائن والبنوك</h2><button onclick="RW_Finance._openTreasuryDialog()" class="bg-blue-600 text-white px-4 py-2 rounded-xl font-bold"><i class="fa-solid fa-plus ml-1"></i> إضافة</button></div><div class="mb-3"><input type="text" id="tr-search" placeholder="بحث..." class="w-full md:w-80 border rounded-lg px-3 py-2 text-sm" oninput="RW_Finance._filterTreasury()"></div><div id="tr-list" class="overflow-x-auto">' + _buildTreasuryTable(data) + '</div></div>';
        safeHTML(content, html);
    }
    function _buildTreasuryTable(data) {
        if (!data.length) return '<div class="text-center py-8 text-gray-500">لا توجد خزائن</div>';
        var html = '<table class="w-full text-sm border-collapse"><thead><tr class="bg-gray-50"><th class="p-2 border">الكود</th><th class="p-2 border">الاسم</th><th class="p-2 border">النوع</th><th class="p-2 border">الرصيد</th></tr></thead><tbody>';
        for (var i = 0; i < data.length; i++) {
            var t = data[i];
            html += '<tr class="border-t hover:bg-gray-50 cursor-pointer" onclick="RW_Finance._editTreasury(\'' + _esc(t.account_code) + '\')"><td class="p-2">' + _esc(t.account_code) + '</td><td class="p-2 font-bold">' + _esc(t.account_name) + '</td><td class="p-2">' + (t.type === 'Cash' ? 'خزينة' : 'بنك') + '</td><td class="p-2 font-bold text-blue-600">' + _fmtNum(t.current_balance) + '</td></tr>';
        }
        html += '</tbody></table>'; return html;
    }
    function _filterTreasury() {
        var q = (byId('tr-search') ? byId('tr-search').value : '').toLowerCase();
        var filtered = _cache.treasury.filter(function(t) { return (t.account_name||'').toLowerCase().indexOf(q) !== -1 || (t.account_code||'').toLowerCase().indexOf(q) !== -1; });
        var list = byId('tr-list'); if (list) safeHTML(list, _buildTreasuryTable(filtered));
    }
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
function _editTreasury(code) {
    var item = null;
    for (var i = 0; i < _cache.treasury.length; i++) {
        if (_cache.treasury[i].account_code === code) {
            item = _cache.treasury[i];
            break;
        }
    }
    if (!item) {
        _showToast('الخزينة غير موجودة', 'error');
        return;
    }

    var companyId;
    try {
        companyId = _companyId();
    } catch (e) {
        _showToast(e.message || 'سياق الشركة غير محدد', 'error');
        return;
    }

    Swal.fire({
        title: 'تعديل ' + item.account_name,
        html: '<div class="text-right">' +
            '<div class="mb-4"><label class="block text-sm font-bold">الاسم</label>' +
            '<input id="tr-name" class="swal2-input" value="' + _esc(item.account_name) + '"></div>' +
            '<div class="mb-4"><label class="block text-sm font-bold">النوع</label>' +
            '<select id="tr-type" class="swal2-input">' +
            '<option value="Cash"' + (item.type === 'Cash' ? ' selected' : '') + '>خزينة</option>' +
            '<option value="Bank"' + (item.type === 'Bank' ? ' selected' : '') + '>بنك</option>' +
            '</select></div>' +
            '<div class="mb-2"><label class="block text-sm font-bold">الرصيد الافتتاحي</label>' +
            '<input class="swal2-input" value="' + _fmtNum(item.opening_balance) + '" disabled></div>' +
            '<div class="mb-2"><label class="block text-sm font-bold">الرصيد الحالي</label>' +
            '<input class="swal2-input" value="' + _fmtNum(item.current_balance) + '" disabled></div>' +
            '<div class="text-xs text-gray-500 mt-2">الأرصدة لا تُعدل من شاشة البيانات الأساسية.</div>' +
            '</div>',
        showCancelButton: true,
        confirmButtonText: 'حفظ',
        cancelButtonText: 'إلغاء',
        showDenyButton: true,
        denyButtonText: 'حذف',
        denyButtonColor: '#ef4444',
        preConfirm: function() {
            var nameEl = document.getElementById('tr-name');
            var typeEl = document.getElementById('tr-type');
            var name = nameEl ? nameEl.value.trim() : '';
            if (!name) {
                Swal.showValidationMessage('اسم الخزينة مطلوب');
                return false;
            }
            return {
                account_name: name,
                type: typeEl ? typeEl.value : item.type,
                updated_at: new Date().toISOString()
            };
        }
    }).then(function(result) {
        if (result.isConfirmed) {
            _showLoader('جاري حفظ التعديل...');
            supabase.from('treasury')
                .update(result.value)
                .eq('id', item.id)
                .eq('company_id', companyId)
                .then(function(res) {
                    if (res.error) throw res.error;
                    _refreshCache();
                    renderSubTab('treasury');
                    _showToast('تم تعديل بيانات الخزينة دون المساس بالأرصدة', 'success');
                })
                .catch(function(e) {
                    _showToast(e.message || 'فشل الحفظ', 'error');
                })
                .finally(_hideLoader);
        } else if (result.isDenied) {
            _showLoader('جاري التحقق قبل الحذف...');
            Promise.all([
                supabase.from('cash_box').select('id', { count: 'exact', head: true })
                    .eq('company_id', companyId)
                    .eq('treasury_id', item.id),
                Promise.resolve({ count: Number(item.current_balance || 0) !== 0 ? 1 : 0 })
            ]).then(function(checks) {
                var cashHistoryCount = Number(checks[0].count || 0);
                var nonZeroBalance = Number(checks[1].count || 0) > 0;
                _hideLoader();
                if (cashHistoryCount > 0 || nonZeroBalance) {
                    _showToast('لا يمكن حذف خزينة لها حركات نقدية أو رصيد غير صفري.', 'warning');
                    return;
                }
                return Swal.fire({
                    title: 'تأكيد الحذف',
                    text: 'حذف ' + item.account_name + '؟',
                    icon: 'warning',
                    showCancelButton: true,
                    confirmButtonColor: '#ef4444',
                    confirmButtonText: 'حذف',
                    cancelButtonText: 'إلغاء'
                });
            }).then(function(confirmResult) {
                if (!confirmResult || !confirmResult.isConfirmed) return;
                _showLoader('جاري الحذف...');
                return supabase.from('treasury')
                    .delete()
                    .eq('id', item.id)
                    .eq('company_id', companyId)
                    .then(function(res) {
                        if (res.error) throw res.error;
                        _refreshCache();
                        renderSubTab('treasury');
                        _showToast('تم الحذف', 'success');
                    })
                    .catch(function(e) {
                        _showToast(e.message || 'فشل الحذف', 'error');
                    })
                    .finally(_hideLoader);
            }).catch(function(e) {
                _hideLoader();
                _showToast(e.message || 'تعذر التحقق من الحذف', 'error');
            });
        }
    });
}

    // ==================== دليل الحسابات ====================
    function _renderAccounts() {
        var content = byId('finance-content'); if (!content) return;
        var html = '<div class="bg-white rounded-2xl shadow-sm border p-4"><div class="flex justify-between items-center mb-4"><h2 class="text-xl font-bold"><i class="fa-solid fa-sitemap ml-2 text-indigo-600"></i>دليل الحسابات</h2><div><button onclick="RW_Finance._seedAccounts()" class="bg-amber-500 text-white px-3 py-2 rounded-lg ml-2"><i class="fa-solid fa-seedling ml-1"></i> تهيئة</button><button onclick="RW_Finance._openAccountDialog()" class="bg-indigo-600 text-white px-4 py-2 rounded-lg"><i class="fa-solid fa-plus ml-1"></i> حساب جديد</button></div></div><div class="mb-3"><input type="text" id="acc-search" placeholder="بحث..." class="w-full md:w-80 border rounded-lg px-3 py-2 text-sm" oninput="RW_Finance._filterAccounts()"></div><div id="acc-tree" class="overflow-auto">' + _buildAccountTree(_cache.accountsTree, 0) + '</div></div>';
        safeHTML(content, html);
    }
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
function _filterAccounts() {
    var q = (byId('acc-search') ? byId('acc-search').value : '').trim().toLowerCase();
    var tree = byId('acc-tree');
    if (!tree) return;

    if (!q) {
        safeHTML(tree, _buildAccountTree(_cache.accountsTree, 0));
        return;
    }

    function filterNode(node) {
        if (!node) return null;
        var ownMatch = String(node.name || '').toLowerCase().indexOf(q) !== -1 ||
            String(node.id || '').toLowerCase().indexOf(q) !== -1;
        var matchingChildren = [];
        var children = node.children || [];

        for (var i = 0; i < children.length; i++) {
            var filteredChild = filterNode(children[i]);
            if (filteredChild) matchingChildren.push(filteredChild);
        }

        if (!ownMatch && !matchingChildren.length) return null;

        var copy = {
            id: node.id,
            uuid: node.uuid,
            name: node.name,
            type: node.type,
            parent: node.parent,
            children: ownMatch ? children.slice(0) : matchingChildren
        };
        return copy;
    }

    var filteredRoots = [];
    for (var r = 0; r < _cache.accountsTree.length; r++) {
        var result = filterNode(_cache.accountsTree[r]);
        if (result) filteredRoots.push(result);
    }

    safeHTML(
        tree,
        _buildAccountTree(
            filteredRoots.length ? filteredRoots : [],
            0
        )
    );
}
function _openAccountDialog(editId) {
    var item = null;
    if (editId) {
        for (var i = 0; i < _cache.accountsFlat.length; i++) {
            if (_cache.accountsFlat[i].account_code === editId) {
                item = _cache.accountsFlat[i];
                break;
            }
        }
    }

    var isEdit = !!item;
    var companyId = _companyId();
    var types = [
        'asset:أصول',
        'liability:خصوم',
        'equity:حقوق ملكية',
        'revenue:إيرادات',
        'expense:مصروفات'
    ];

    function findAccountById(id) {
        for (var n = 0; n < _cache.accountsFlat.length; n++) {
            if (_cache.accountsFlat[n].id === id) return _cache.accountsFlat[n];
        }
        return null;
    }

    function hasAncestor(candidateId, targetId) {
        var currentId = candidateId;
        var seen = {};
        while (currentId) {
            if (seen[currentId]) return false;
            seen[currentId] = true;
            if (currentId === targetId) return true;
            var row = findAccountById(currentId);
            if (!row) return false;
            currentId = row.parent_account_id || null;
        }
        return false;
    }

    var typeOptions = types.map(function(t) {
        var pair = t.split(':');
        return '<option value="' + pair[0] + '"' +
            (isEdit && item.account_type === pair[0] ? ' selected' : '') + '>' +
            pair[1] + '</option>';
    }).join('');

    var parentOptions = _cache.accountsFlat.filter(function(a) {
        if (!isEdit) return true;
        if (a.id === item.id) return false;
        if (hasAncestor(a.id, item.id)) return false;
        return true;
    }).map(function(a) {
        return '<option value="' + _esc(a.id) + '"' +
            (isEdit && item.parent_account_id === a.id ? ' selected' : '') + '>' +
            _esc(a.account_name) + ' (' + _esc(a.account_code) + ')</option>';
    }).join('');

    Swal.fire({
        title: isEdit ? 'تعديل حساب' : 'إضافة حساب جديد',
        html: '<div class="text-right">' +
            '<div class="mb-3"><label class="block text-sm font-bold">كود الحساب *</label>' +
            '<input id="acc-code" class="swal2-input" value="' +
            (isEdit ? _esc(item.account_code) : '') + '" ' +
            (isEdit ? 'readonly' : '') + '></div>' +
            '<div class="mb-3"><label class="block text-sm font-bold">اسم الحساب *</label>' +
            '<input id="acc-name" class="swal2-input" value="' +
            (isEdit ? _esc(item.account_name) : '') + '"></div>' +
            '<div class="mb-3"><label class="block text-sm font-bold">النوع</label>' +
            '<select id="acc-type" class="swal2-input" ' + (isEdit ? 'disabled' : '') + '>' +
            typeOptions + '</select></div>' +
            '<div class="mb-3"><label class="block text-sm font-bold">الحساب الأب</label>' +
            '<select id="acc-parent" class="swal2-input"><option value="">لا يوجد</option>' +
            parentOptions + '</select></div>' +
            '</div>',
        showCancelButton: true,
        confirmButtonText: isEdit ? 'حفظ' : 'إضافة',
        cancelButtonText: 'إلغاء',
        showDenyButton: isEdit,
        denyButtonText: 'حذف',
        denyButtonColor: '#ef4444',
        preConfirm: function() {
            var codeEl = document.getElementById('acc-code');
            var nameEl = document.getElementById('acc-name');
            var typeEl = document.getElementById('acc-type');
            var parentEl = document.getElementById('acc-parent');
            var code = codeEl ? codeEl.value.trim() : '';
            var name = nameEl ? nameEl.value.trim() : '';
            var accountType = typeEl ? typeEl.value : '';
            var parentId = parentEl && parentEl.value ? parentEl.value : null;

            if (!isEdit && !code) {
                Swal.showValidationMessage('كود الحساب مطلوب عند الإضافة');
                return false;
            }
            if (!name) {
                Swal.showValidationMessage('اسم الحساب مطلوب');
                return false;
            }
            if (!isEdit && parentId && hasAncestor(parentId, null)) {
                Swal.showValidationMessage('الحساب الأب غير صالح');
                return false;
            }

            return {
                account_code: code,
                account_name: name,
                account_type: accountType,
                parent_account_id: parentId
            };
        }
    }).then(function(result) {
        if (result.isConfirmed) {
            _showLoader('جاري حفظ الحساب...');
            var payload = result.value;
            var promise;

            if (isEdit) {
                promise = supabase.from('chart_of_accounts')
                    .update({
                        account_name: payload.account_name,
                        parent_account_id: payload.parent_account_id,
                        updated_at: new Date().toISOString()
                    })
                    .eq('id', item.id)
                    .eq('company_id', companyId);
            } else {
                var normalBalance = ['liability', 'equity', 'revenue'].indexOf(payload.account_type) !== -1 ? 'credit' : 'debit';
                promise = supabase.from('chart_of_accounts').insert({
                    company_id: companyId,
                    account_code: payload.account_code,
                    account_name: payload.account_name,
                    account_type: payload.account_type,
                    parent_account_id: payload.parent_account_id,
                    normal_balance: normalBalance,
                    is_active: true
                });
            }

            promise.then(function(res) {
                if (res.error) throw res.error;
                _refreshCache();
                renderSubTab('accounts');
                _showToast('تم حفظ الحساب', 'success');
            }).catch(function(e) {
                _showToast(e.message || 'فشل حفظ الحساب', 'error');
            }).finally(_hideLoader);
        } else if (result.isDenied) {
            Swal.fire({
                title: 'تأكيد الحذف',
                text: 'حذف ' + item.account_name + '؟',
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#ef4444',
                confirmButtonText: 'حذف',
                cancelButtonText: 'إلغاء'
            }).then(function(dr) {
                if (!dr.isConfirmed) return;
                _showLoader('جاري الحذف...');
                supabase.from('chart_of_accounts')
                    .delete()
                    .eq('id', item.id)
                    .eq('company_id', companyId)
                    .then(function(res) {
                        if (res.error) throw res.error;
                        _refreshCache();
                        renderSubTab('accounts');
                        _showToast('تم الحذف', 'success');
                    }).catch(function(e) {
                        _showToast(e.message || 'فشل الحذف', 'error');
                    }).finally(_hideLoader);
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

    // ==================== القيود اليومية ====================
    function _renderJournal() {
        var content = byId('finance-content'); if (!content) return;
        var today = new Date().toISOString().slice(0,10);
        var html = '<div class="bg-white rounded-2xl shadow-sm border p-4"><h2 class="text-xl font-bold mb-4"><i class="fa-solid fa-book ml-2 text-indigo-600"></i>قيد يومي يدوي</h2><div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4"><div><label class="block text-sm font-bold">التاريخ</label><input type="date" id="journal-date" value="' + today + '" class="border rounded-lg p-2 w-full"></div><div><label class="block text-sm font-bold">المرجع</label><input type="text" id="journal-ref" class="border rounded-lg p-2 w-full" placeholder="مرجع"></div></div><div class="mb-4"><label class="block text-sm font-bold">الوصف</label><textarea id="journal-desc" rows="2" class="border rounded-lg p-2 w-full"></textarea></div><div><label class="block text-sm font-bold mb-2">سطور القيد</label><div id="journal-lines"></div><button onclick="RW_Finance._addJournalLine()" class="mt-2 text-indigo-600 font-bold"><i class="fa-solid fa-plus-circle ml-1"></i> إضافة سطر</button></div><div class="mt-4 p-3 bg-gray-50 rounded-lg flex justify-between"><span>مدين: <span id="j-debit">0.00</span></span><span>دائن: <span id="j-credit">0.00</span></span><span id="j-balance"></span></div><div class="mt-6 flex justify-end"><button onclick="RW_Finance._saveJournalEntry()" class="bg-indigo-600 text-white px-6 py-2 rounded-lg font-bold"><i class="fa-solid fa-check ml-1"></i> حفظ القيد</button></div></div>';
        safeHTML(content, html);
        _addJournalLine();
        _recalcJournalTotal();
    }
    function _addJournalLine() {
        var opts = '';
        for (var i = 0; i < _cache.accountsFlat.length; i++) {
            var a = _cache.accountsFlat[i];
            opts += '<option value="' + _esc(a.account_code) + '">' + _esc(a.account_name) + ' (' + _esc(a.account_code) + ')</option>';
        }
        var ccOpts = '<option value="">(بدون مركز)</option>';
        if (_cache.costCenters && _cache.costCenters.length) {
            for (var c = 0; c < _cache.costCenters.length; c++) {
                ccOpts += '<option value="' + _esc(_cache.costCenters[c].id) + '">' + _esc(_cache.costCenters[c].name) + '</option>';
            }
        }
        var html = '<div class="journal-line grid grid-cols-12 gap-2 mb-2 bg-gray-50 p-2 rounded-lg">' +
            '<div class="col-span-3"><select class="border rounded p-1.5 w-full text-sm jl-account"><option value="">اختر الحساب</option>' + opts + '</select></div>' +
            '<div class="col-span-3"><select class="border rounded p-1.5 w-full text-sm jl-cost-center">' + ccOpts + '</select></div>' +
            '<div class="col-span-2"><input type="number" step="0.01" min="0" class="border rounded p-1.5 w-full text-sm jl-debit" value="0" oninput="RW_Finance._recalcJournalTotal()"></div>' +
            '<div class="col-span-2"><input type="number" step="0.01" min="0" class="border rounded p-1.5 w-full text-sm jl-credit" value="0" oninput="RW_Finance._recalcJournalTotal()"></div>' +
            '<div class="col-span-2 flex justify-center items-center"><button onclick="RW_Finance._removeJournalLine(this)" class="text-red-500"><i class="fa-solid fa-circle-minus"></i></button></div>' +
            '</div>';
        byId('journal-lines').insertAdjacentHTML('beforeend', html);
    }
    function _removeJournalLine(btn) { btn.closest('.journal-line').remove(); _recalcJournalTotal(); }
    function _recalcJournalTotal() {
        var deb = 0, cred = 0;
        document.querySelectorAll('.jl-debit').forEach(function(el) { deb += parseFloat(el.value) || 0; });
        document.querySelectorAll('.jl-credit').forEach(function(el) { cred += parseFloat(el.value) || 0; });
        safeText(byId('j-debit'), _fmtNum(deb)); safeText(byId('j-credit'), _fmtNum(cred));
        var diff = Math.abs(deb - cred);
        safeHTML(byId('j-balance'), diff < 0.01 ? '<span class="text-green-600 font-bold">✓ متوازن</span>' : '<span class="text-red-600 font-bold">⚠️ غير متوازن ' + _fmtNum(diff) + '</span>');
    }
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
            _showToast(
                'يوجد مبلغ غير صالح في السطر ' + (i + 1),
                'error'
            );
            return;
        }

        if (deb < 0 || cred < 0) {
            _showToast(
                'لا يجوز إدخال مبالغ سالبة في السطر ' + (i + 1),
                'error'
            );
            return;
        }

        if (deb > 0 && cred > 0) {
            _showToast(
                'لا يجوز أن يحتوي السطر ' + (i + 1) +
                ' على مدين ودائن معًا',
                'error'
            );
            return;
        }

        if (acc && (deb || cred)) {
            var selected =
                accEl &&
                accEl.selectedOptions &&
                accEl.selectedOptions[0];

            var ccEl = l.querySelector('.jl-cost-center');

            lines.push({
                accountId: acc,
                accountName: selected ? selected.textContent : '',
                costCenterId:
                    ccEl && ccEl.value
                        ? ccEl.value
                        : null,
                debit: deb,
                credit: cred
            });

            totalDebit += deb;
            totalCredit += cred;
        }
    }

    if (lines.length < 2) {
        _showToast(
            'يجب إدخال سطرين على الأقل للقيد',
            'warning'
        );
        return;
    }

    if (
        Math.abs(totalDebit - totalCredit) >= 0.01 ||
        totalDebit <= 0 ||
        totalCredit <= 0
    ) {
        _showToast(
            'القيد غير متوازن: المدين ' +
            _fmtNum(totalDebit) +
            ' / الدائن ' +
            _fmtNum(totalCredit),
            'error'
        );
        return;
    }

    var operationId =
        (host && host.dataset.journalOperationId) || '';

    if (!operationId) {
        if (
            window.crypto &&
            typeof window.crypto.randomUUID === 'function'
        ) {
            operationId = window.crypto.randomUUID();
        } else if (
            window.crypto &&
            typeof window.crypto.getRandomValues === 'function'
        ) {
            var bytes = new Uint8Array(16);
            window.crypto.getRandomValues(bytes);

            bytes[6] =
                (bytes[6] & 0x0f) | 0x40;

            bytes[8] =
                (bytes[8] & 0x3f) | 0x80;

            operationId = '';

            for (var b = 0; b < bytes.length; b++) {
                if (
                    b === 4 ||
                    b === 6 ||
                    b === 8 ||
                    b === 10
                ) {
                    operationId += '-';
                }

                operationId +=
                    bytes[b]
                        .toString(16)
                        .padStart(2, '0');
            }
        } else {
            function hex4() {
                return Math.floor(
                    (1 + Math.random()) * 0x10000
                )
                .toString(16)
                .substring(1);
            }

            operationId =
                hex4() +
                hex4() +
                '-' +
                hex4() +
                '-4' +
                hex4().substring(1) +
                '-' +
                (
                    8 +
                    Math.floor(Math.random() * 4)
                ).toString(16) +
                hex4().substring(1) +
                '-' +
                hex4() +
                hex4() +
                hex4();
        }

        if (host) {
            host.dataset.journalOperationId =
                operationId;
        }
    }

    if (host) {
        host.dataset.journalSaving = '1';
    }

    var payload = {
        operation_id: operationId,

        date:
            byId('journal-date')
                ? (
                    byId('journal-date').value ||
                    new Date()
                        .toISOString()
                        .slice(0, 10)
                )
                : new Date()
                    .toISOString()
                    .slice(0, 10),

        reference:
            byId('journal-ref')
                ? (
                    byId('journal-ref').value || ''
                )
                : '',

        description:
            byId('journal-desc')
                ? (
                    byId('journal-desc').value || ''
                )
                : '',

        entryType: 'Manual',

        lines: lines
    };

    var saveUrl =
        RW_SUPABASE_URL +
        '/functions/v1/save-journal-entry';

    if (
        typeof supabase === 'undefined' ||
        !supabase ||
        !supabase.auth
    ) {
        if (host) {
            host.dataset.journalSaving = '0';
        }

        _showToast(
            'جلسة Supabase غير متاحة',
            'error'
        );

        return;
    }

    _showLoader();

    supabase.auth.getSession()

        .then(function(ses) {
            var token =
                ses &&
                ses.data &&
                ses.data.session
                    ? ses.data.session.access_token
                    : null;

            if (!token) {
                throw new Error(
                    'انتهت الجلسة'
                );
            }

            return fetch(saveUrl, {
                method: 'POST',

                headers: {
                    'Content-Type':
                        'application/json',

                    'Authorization':
                        'Bearer ' + token
                },

                body:
                    JSON.stringify(payload)
            });
        })

        .then(function(res) {
            return res.json().then(function(json) {

                if (
                    !res.ok ||
                    !json ||
                    !json.success
                ) {
                    throw new Error(
                        (
                            json &&
                            json.error
                        ) ||
                        'فشل حفظ القيد'
                    );
                }

                return json;
            });
        })

        .then(function(json) {
            _hideLoader();

            if (host) {
                host.dataset.journalSaving = '0';
                delete host.dataset.journalOperationId;
            }

            _showToast(
                (
                    json.duplicate
                        ? 'القيد موجود بالفعل: '
                        : 'تم حفظ القيد '
                ) +
                (
                    json.entry_code ||
                    json.entryCode ||
                    ''
                ),
                'success'
            );

            renderSubTab('journal');
        })

        .catch(function(e) {
            _hideLoader();

            if (host) {
                host.dataset.journalSaving = '0';
            }

            _showToast(
                e && e.message
                    ? e.message
                    : 'فشل الحفظ',
                'error'
            );

            console.error(
                'Journal save error:',
                e
            );
        });
}
    // ==================== سندات القبض والصرف والتحويلات ====================
    function _renderReceipts() {
        var content = byId('finance-content'); if (!content) return;
        content.innerHTML = '<div class="text-center py-8">جاري تحميل سندات القبض...</div>';
                supabase.from('cash_box').select('*').eq('company_id', _companyId()).eq('type', 'Receipt').order('voucher_date', { ascending: false }).then(function(r) {
            if (r.error) throw r.error;
            var data = r.data || [];
            var html = '<div class="bg-white rounded-2xl shadow-sm border p-4"><div class="flex justify-between items-center mb-4"><h2 class="text-xl font-bold"><i class="fa-solid fa-arrow-down ml-2 text-green-600"></i>سندات القبض</h2><button onclick="RW_Finance._newReceipt()" class="bg-green-600 text-white px-4 py-2 rounded-xl"><i class="fa-solid fa-plus ml-1"></i> سند قبض جديد</button></div><div id="receipts-list">' + _buildReceiptsTable(data) + '</div></div>';
            safeHTML(content, html);
        });
    }
    function _buildReceiptsTable(data) {
        if (!data.length) return '<div class="text-center py-8 text-gray-500">لا توجد سندات قبض</div>';
        var html = '<table class="w-full text-sm border-collapse"><thead><tr class="bg-gray-50"><th class="p-2 border">التاريخ</th><th class="p-2 border">الخزينة</th><th class="p-2 border">المبلغ</th><th class="p-2 border">المرجع</th></tr></thead><tbody>';
        for (var i = 0; i < data.length; i++) { var r = data[i]; html += '<tr class="border-t"><td class="p-2">' + _esc(r.voucher_date) + '</td><td class="p-2">' + _esc(r.treasury_id) + '</td><td class="p-2 font-bold text-green-600">' + _fmtNum(r.amount) + '</td><td class="p-2">' + _esc(r.reference) + '</td></tr>'; }
        html += '</tbody></table>'; return html;
    }
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
    function _addReceiptLine() {
        var html = '<div class="rcpt-line grid grid-cols-12 gap-2 mb-2 bg-gray-50 p-2 rounded-lg"><div class="col-span-5"><input type="text" class="rcpt-line-account border rounded p-1.5 w-full text-sm" placeholder="اسم العميل"></div><div class="col-span-3"><input type="text" class="rcpt-line-desc border rounded p-1.5 w-full text-sm" placeholder="وصف"></div><div class="col-span-3"><input type="number" step="0.01" min="0" class="rcpt-line-amount border rounded p-1.5 w-full text-sm" oninput="RW_Finance._recalcReceiptTotal()"></div><div class="col-span-1 flex justify-center"><button onclick="RW_Finance._removeReceiptLine(this)" class="text-red-500"><i class="fa-solid fa-circle-minus"></i></button></div></div>';
        byId('rcpt-lines').insertAdjacentHTML('beforeend', html);
    }
    function _removeReceiptLine(btn) { btn.closest('.rcpt-line').remove(); _recalcReceiptTotal(); }
    function _recalcReceiptTotal() { var total = 0; document.querySelectorAll('.rcpt-line-amount').forEach(function(el) { total += parseFloat(el.value) || 0; }); safeText(byId('rcpt-total'), _fmtNum(total)); }
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

    function _renderPayments() {
        var content = byId('finance-content'); if (!content) return;
        content.innerHTML = '<div class="text-center py-8">جاري تحميل سندات الصرف...</div>';
                supabase.from('cash_box').select('*').eq('company_id', _companyId()).eq('type', 'Payment').order('voucher_date', { ascending: false }).then(function(r) {
            if (r.error) throw r.error;
            var data = r.data || [];
            var html = '<div class="bg-white rounded-2xl shadow-sm border p-4"><div class="flex justify-between items-center mb-4"><h2 class="text-xl font-bold"><i class="fa-solid fa-arrow-up ml-2 text-red-600"></i>سندات الصرف</h2><button onclick="RW_Finance._newPayment()" class="bg-red-600 text-white px-4 py-2 rounded-xl"><i class="fa-solid fa-plus ml-1"></i> سند صرف جديد</button></div><div id="payments-list">' + _buildReceiptsTable(data) + '</div></div>';
            safeHTML(content, html);
        });
    }
    function _newPayment() {
        var content = byId('finance-content'); if (!content) return;
        var treasuryOptions = _cache.treasury.map(function(t) {
            return '<option value="' + _esc(t.id) + '">' + _esc(t.account_name) + ' (' + _esc(t.account_code) + ')</option>';
        }).join('');
        var accountOptions = _cache.accountsFlat.map(function(a) {
            return '<option value="' + _esc(a.id) + '">' + _esc(a.account_name) + ' (' + _esc(a.account_code) + ')</option>';
        }).join('');
        var html = '<div class="bg-white rounded-2xl shadow-sm border p-4"><div class="flex justify-between items-center mb-4"><h2 class="text-xl font-bold"><i class="fa-solid fa-arrow-up ml-2 text-red-600"></i>سند صرف جديد</h2><button onclick="RW_Finance.renderSubTab(\'payments\')" class="text-gray-500 hover:text-gray-700"><i class="fa-solid fa-xmark text-xl"></i></button></div><div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4"><div><label class="block text-sm font-bold">التاريخ</label><input type="date" id="pmt-date" class="border rounded-lg p-2 w-full" value="' + new Date().toISOString().slice(0,10) + '"></div><div><label class="block text-sm font-bold">الخزينة</label><select id="pmt-cashbox" class="border rounded-lg p-2 w-full"><option value="">اختر الخزينة</option>' + treasuryOptions + '</select></div><div><label class="block text-sm font-bold">الحساب الرئيسي</label><select id="pmt-main-account" class="border rounded-lg p-2 w-full"><option value="">اختر الحساب</option>' + accountOptions + '</select></div></div><div class="mb-4"><h4 class="font-bold mb-2">بنود السند</h4><div id="pmt-lines"></div><button type="button" onclick="RW_Finance._addPaymentLine()" class="mt-2 text-red-600 font-bold"><i class="fa-solid fa-plus-circle ml-1"></i> إضافة بند</button></div><div class="p-3 bg-gray-50 rounded-lg flex justify-between mb-4"><span>الإجمالي: <span id="pmt-total">0.00</span></span></div><div class="flex justify-end gap-3"><button type="button" onclick="RW_Finance.renderSubTab(\'payments\')" class="px-4 py-2 border rounded-lg">إلغاء</button><button type="button" onclick="RW_Finance._savePayment()" class="px-6 py-2 bg-red-600 text-white rounded-lg font-bold"><i class="fa-solid fa-check ml-1"></i> حفظ</button></div></div>';
        safeHTML(content, html);
        _addPaymentLine();
    }
    function _addPaymentLine() {
        var html = '<div class="pmt-line grid grid-cols-12 gap-2 mb-2 bg-gray-50 p-2 rounded-lg"><div class="col-span-5"><input type="text" class="pmt-line-account border rounded p-1.5 w-full text-sm" placeholder="اسم المستفيد"></div><div class="col-span-3"><input type="text" class="pmt-line-desc border rounded p-1.5 w-full text-sm" placeholder="وصف"></div><div class="col-span-3"><input type="number" step="0.01" min="0" class="pmt-line-amount border rounded p-1.5 w-full text-sm" oninput="RW_Finance._recalcPaymentTotal()"></div><div class="col-span-1 flex justify-center"><button onclick="RW_Finance._removePaymentLine(this)" class="text-red-500"><i class="fa-solid fa-circle-minus"></i></button></div></div>';
        byId('pmt-lines').insertAdjacentHTML('beforeend', html);
    }
    function _removePaymentLine(btn) { btn.closest('.pmt-line').remove(); _recalcPaymentTotal(); }
    function _recalcPaymentTotal() { var total = 0; document.querySelectorAll('.pmt-line-amount').forEach(function(el) { total += parseFloat(el.value) || 0; }); safeText(byId('pmt-total'), _fmtNum(total)); }
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

    function _renderTransfers() {
        var content = byId('finance-content'); if (!content) return;
        content.innerHTML = '<div class="text-center py-8">جاري تحميل التحويلات...</div>';
        supabase.from('cash_box').select('*').eq('company_id', _companyId()).in('type', ['Transfer-Out', 'Transfer-In']).order('voucher_date', { ascending: false }).then(function(r) {
            if (r.error) throw r.error;
            var data = r.data || [], merged = {};
            for (var i = 0; i < data.length; i++) { var t = data[i]; if (!merged[t.reference]) merged[t.reference] = { date: t.voucher_date, fromCash: '', toCash: '', amount: 0, ref: t.reference }; if (t.type === 'Transfer-Out') merged[t.reference].fromCash = t.treasury_id; else merged[t.reference].toCash = t.treasury_id; merged[t.reference].amount = Math.max(merged[t.reference].amount, t.amount||0); }
            var transfers = Object.values(merged);
            var html = '<div class="bg-white rounded-2xl shadow-sm border p-4"><div class="flex justify-between items-center mb-4"><h2 class="text-xl font-bold"><i class="fa-solid fa-right-left ml-2 text-purple-600"></i>التحويلات</h2><button onclick="RW_Finance._newTransfer()" class="bg-purple-600 text-white px-4 py-2 rounded-xl"><i class="fa-solid fa-plus ml-1"></i> تحويل جديد</button></div><div id="transfers-list">' + _buildTransfersTable(transfers) + '</div></div>';
            safeHTML(content, html);
        });
    }
    function _buildTransfersTable(data) {
        if (!data.length) return '<div class="text-center py-8 text-gray-500">لا توجد تحويلات</div>';
        var html = '<table class="w-full text-sm border-collapse"><thead><tr class="bg-gray-50"><th class="p-2 border">التاريخ</th><th class="p-2 border">من</th><th class="p-2 border">إلى</th><th class="p-2 border">المبلغ</th></tr></thead><tbody>';
        for (var i = 0; i < data.length; i++) { var t = data[i]; html += '<tr class="border-t"><td class="p-2">' + _esc(t.date) + '</td><td class="p-2">' + _esc(t.fromCash) + '</td><td class="p-2">' + _esc(t.toCash) + '</td><td class="p-2 font-bold text-purple-600">' + _fmtNum(t.amount) + '</td></tr>'; }
        html += '</tbody></table>'; return html;
    }
    function _newTransfer() {
        var content = byId('finance-content'); if (!content) return;
        var treasuryOptions = _cache.treasury.map(function(t) {
            return '<option value="' + _esc(t.id) + '">' + _esc(t.account_name) + ' (' + _esc(t.account_code) + ')</option>';
        }).join('');
        var accountOptions = _cache.accountsFlat.map(function(a) {
            return '<option value="' + _esc(a.id) + '">' + _esc(a.account_name) + ' (' + _esc(a.account_code) + ')</option>';
        }).join('');
        var html = '<div class="bg-white rounded-2xl shadow-sm border p-4"><div class="flex justify-between items-center mb-4"><h2 class="text-xl font-bold"><i class="fa-solid fa-right-left ml-2 text-purple-600"></i>تحويل جديد</h2><button type="button" onclick="RW_Finance.renderSubTab(\'transfers\')" class="text-gray-500 hover:text-gray-700"><i class="fa-solid fa-xmark text-xl"></i></button></div><div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4"><div><label class="block text-sm font-bold">من خزينة</label><select id="trf-from" class="border rounded-lg p-2 w-full"><option value="">اختر الخزينة</option>' + treasuryOptions + '</select></div><div><label class="block text-sm font-bold">إلى خزينة</label><select id="trf-to" class="border rounded-lg p-2 w-full"><option value="">اختر الخزينة</option>' + treasuryOptions + '</select></div><div><label class="block text-sm font-bold">حساب المصدر</label><select id="trf-source-account" class="border rounded-lg p-2 w-full"><option value="">اختر الحساب</option>' + accountOptions + '</select></div><div><label class="block text-sm font-bold">حساب الوجهة</label><select id="trf-target-account" class="border rounded-lg p-2 w-full"><option value="">اختر الحساب</option>' + accountOptions + '</select></div></div><div class="mb-4"><label class="block text-sm font-bold">المبلغ</label><input type="number" min="0.01" step="0.01" id="trf-amount" class="border rounded-lg p-2 w-full"></div><div class="flex justify-end gap-3"><button type="button" onclick="RW_Finance.renderSubTab(\'transfers\')" class="px-4 py-2 border rounded-lg">إلغاء</button><button type="button" onclick="RW_Finance._saveTransfer()" class="px-6 py-2 bg-purple-600 text-white rounded-lg font-bold"><i class="fa-solid fa-check ml-1"></i> حفظ</button></div></div>';
        safeHTML(content, html);
    }
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

    // ==================== التقارير المالية ====================
function _renderReports() {
    var content = byId('finance-content');
    if (!content) return;

    var today = new Date().toISOString().slice(0, 10);
    var accountOptions = '<option value="">اختر الحساب لعرض الأستاذ العام</option>' +
        _cache.accountsFlat.map(function(a) {
            return '<option value="' + _esc(a.id) + '">' +
                _esc(a.account_name) + ' (' + _esc(a.account_code) + ')</option>';
        }).join('');

    var html = '<div class="bg-white rounded-2xl shadow-sm border p-4">' +
        '<h2 class="text-xl font-bold mb-4"><i class="fa-solid fa-chart-pie ml-2 text-teal-600"></i>مركز التقارير والتحكم المالي</h2>' +
        '<div class="grid grid-cols-1 md:grid-cols-3 gap-3 mb-4">' +
        '<div><label class="block text-sm font-bold">من تاريخ</label><input id="rp-from" type="date" value="' + today + '" class="border rounded-lg p-2 w-full"></div>' +
        '<div><label class="block text-sm font-bold">إلى تاريخ</label><input id="rp-to" type="date" value="' + today + '" class="border rounded-lg p-2 w-full"></div>' +
        '<div><label class="block text-sm font-bold">الحساب</label><select id="rp-account" class="border rounded-lg p-2 w-full">' + accountOptions + '</select></div>' +
        '</div>' +
        '<div class="flex flex-wrap gap-2 mb-3">' +
        '<button onclick="RW_Finance._trialBalance()" class="bg-teal-600 text-white px-4 py-2 rounded-lg">ميزان المراجعة</button>' +
        '<button onclick="RW_Finance._profitLoss()" class="bg-emerald-600 text-white px-4 py-2 rounded-lg">قائمة الدخل</button>' +
        '<button onclick="RW_Finance._balanceSheet()" class="bg-indigo-600 text-white px-4 py-2 rounded-lg">الميزانية العمومية</button>' +
        '<button onclick="RW_Finance._cashFlow()" class="bg-cyan-600 text-white px-4 py-2 rounded-lg">التدفقات النقدية</button>' +
        '<button onclick="RW_Finance._costCenterProfitLoss()" class="bg-amber-600 text-white px-4 py-2 rounded-lg">أرباح/خسائر المراكز</button>' +
        '<button onclick="RW_Finance._accountActivity()" class="bg-slate-700 text-white px-4 py-2 rounded-lg">الأستاذ العام</button>' +
        '<button onclick="RW_Finance._customerAging()" class="bg-violet-600 text-white px-4 py-2 rounded-lg">أعمار العملاء</button>' +
        '<button onclick="RW_Finance._supplierAging()" class="bg-fuchsia-600 text-white px-4 py-2 rounded-lg">أعمار الموردين</button>' +
        '<button onclick="RW_Finance._reconciliationSummary()" class="bg-sky-700 text-white px-4 py-2 rounded-lg">المطابقات</button>' +
        '<button onclick="RW_Finance._exceptionCenter()" class="bg-rose-700 text-white px-4 py-2 rounded-lg">مركز الاستثناءات</button>' +
        '<button onclick="RW_Finance._periodReadiness()" class="bg-stone-700 text-white px-4 py-2 rounded-lg">جاهزية الفترة</button>' +
        '</div>' +
        '<div class="text-xs text-gray-500 mb-4">التقارير المتقدمة أدناه تستخدم عقود Production الحالية ولا تنشئ محرك بيانات موازيًا.</div>' +
        '<div id="report-output"></div></div>';

    safeHTML(content, html);
}
    function _trialBalance() {
        var out = byId('report-output'); if (!out) return;
        out.innerHTML = '<div class="text-center py-8"><i class="fa-solid fa-spinner fa-spin"></i> جاري التحميل...</div>';
        supabase.auth.getSession().then(function(ses) {
            return fetch(RW_SUPABASE_URL + '/functions/v1/get-trial-balance', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + ses.data.session.access_token },
                body: JSON.stringify({ fromDate: byId('rp-from').value, toDate: byId('rp-to').value })
            }).then(function(res) { return res.json(); });
        }).then(function(json) {
            if (json.success) {
                var html = '<table class="w-full text-sm border"><thead><tr class="bg-gray-50"><th class="p-2">الكود</th><th class="p-2">الاسم</th><th class="p-2">مدين</th><th class="p-2">دائن</th></tr></thead><tbody>';
                for (var i = 0; i < json.data.length; i++) { var r = json.data[i]; html += '<tr><td class="p-2">' + r.accountId + '</td><td class="p-2">' + r.accountName + '</td><td class="p-2">' + _fmtNum(r.totalDebit) + '</td><td class="p-2">' + _fmtNum(r.totalCredit) + '</td></tr>'; }
                html += '</tbody></table>';
                safeHTML(out, html);
            } else {
                safeHTML(out, '<div class="text-center py-8 text-red-500">فشل التحميل</div>');
            }
        }).catch(function() { safeHTML(out, '<div class="text-center py-8 text-red-500">فشل التحميل</div>'); });
    }

function _profitLoss() {
    var out = byId('report-output');
    if (!out) return;
    safeHTML(out, '<div class="text-center py-8"><i class="fa-solid fa-spinner fa-spin"></i> جاري تحميل قائمة الدخل...</div>');

    supabase.auth.getSession().then(function(ses) {
        var token = ses && ses.data && ses.data.session ? ses.data.session.access_token : null;
        if (!token) throw new Error('انتهت الجلسة');
        return fetch(RW_SUPABASE_URL + '/functions/v1/get-profit-loss', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token },
            body: JSON.stringify({
                fromDate: byId('rp-from').value,
                toDate: byId('rp-to').value
            })
        });
    }).then(function(res) {
        return res.json().then(function(json) {
            if (!res.ok || !json || !json.success) throw new Error((json && json.msg) || 'فشل تحميل قائمة الدخل');
            return json;
        });
    }).then(function(json) {
        var data = json.data || {};
        var revenue = data.revenueAccounts || [];
        var expenses = data.expenseAccounts || [];
        var totalRevenue = Number(data.totalRevenue || 0);
        var totalExpense = Number(data.totalExpense || 0);
        var netProfit = Number(data.netProfit || (totalRevenue - totalExpense));

        var html = '<div class="grid grid-cols-1 md:grid-cols-3 gap-3 mb-5">' +
            '<div class="bg-green-50 border rounded-xl p-4"><div class="text-sm text-gray-500">إجمالي الإيرادات</div><div class="text-2xl font-black text-green-700">' + _fmtNum(totalRevenue) + '</div></div>' +
            '<div class="bg-red-50 border rounded-xl p-4"><div class="text-sm text-gray-500">إجمالي المصروفات</div><div class="text-2xl font-black text-red-700">' + _fmtNum(totalExpense) + '</div></div>' +
            '<div class="bg-blue-50 border rounded-xl p-4"><div class="text-sm text-gray-500">صافي النتيجة</div><div class="text-2xl font-black ' + (netProfit >= 0 ? 'text-blue-700' : 'text-red-700') + '">' + _fmtNum(netProfit) + '</div></div>' +
            '</div>';

        html += '<div class="grid grid-cols-1 md:grid-cols-2 gap-5">';
        html += '<div class="border rounded-xl p-4"><h3 class="font-black text-lg mb-3">الإيرادات</h3><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2 text-right">الحساب</th><th class="p-2 text-left">المبلغ</th></tr></thead><tbody>';
        for (var i = 0; i < revenue.length; i++) {
            html += '<tr class="border-t"><td class="p-2">' + _esc(revenue[i].accountName) + '</td><td class="p-2 text-left font-bold">' + _fmtNum(revenue[i].total) + '</td></tr>';
        }
        html += '</tbody><tfoot><tr class="border-t font-black"><td class="p-2">الإجمالي</td><td class="p-2 text-left">' + _fmtNum(totalRevenue) + '</td></tr></tfoot></table></div>';

        html += '<div class="border rounded-xl p-4"><h3 class="font-black text-lg mb-3">المصروفات</h3><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2 text-right">الحساب</th><th class="p-2 text-left">المبلغ</th></tr></thead><tbody>';
        for (var j = 0; j < expenses.length; j++) {
            html += '<tr class="border-t"><td class="p-2">' + _esc(expenses[j].accountName) + '</td><td class="p-2 text-left font-bold">' + _fmtNum(expenses[j].total) + '</td></tr>';
        }
        html += '</tbody><tfoot><tr class="border-t font-black"><td class="p-2">الإجمالي</td><td class="p-2 text-left">' + _fmtNum(totalExpense) + '</td></tr></tfoot></table></div></div>';

        safeHTML(out, html);
    }).catch(function(e) {
        safeHTML(out, '<div class="text-center py-8 text-red-500">' + _esc(e.message || 'فشل تحميل قائمة الدخل') + '</div>');
    });
}
    function _renderBudgets() {
        var content = byId('finance-content'); if (!content) return;
        var today = new Date();
        var currentYear = today.getFullYear();
        var currentMonth = today.getMonth() + 1;
        var monthNames = ['', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
        var html = '<div class="bg-white rounded-2xl shadow-sm border p-4"><h2 class="text-xl font-bold mb-4"><i class="fa-solid fa-chart-pie ml-2 text-indigo-600"></i>الموازنات التقديرية</h2>';
        html += '<div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-4">';
        html += '<div><label class="block text-sm font-bold">السنة</label><select id="budget-year" class="border rounded-lg p-2 w-full">';
        for (var y = currentYear - 2; y <= currentYear + 1; y++) html += '<option value="' + y + '"' + (y === currentYear ? ' selected' : '') + '>' + y + '</option>';
        html += '</select></div>';
        html += '<div><label class="block text-sm font-bold">الشهر</label><select id="budget-month" class="border rounded-lg p-2 w-full">';
        for (var m = 1; m <= 12; m++) html += '<option value="' + m + '"' + (m === currentMonth ? ' selected' : '') + '>' + monthNames[m] + '</option>';
        html += '</select></div>';
        html += '<div><label class="block text-sm font-bold">مركز التكلفة</label><select id="budget-cc" class="border rounded-lg p-2 w-full"><option value="">الكل</option>';
        if (_cache.costCenters) for (var c = 0; c < _cache.costCenters.length; c++) html += '<option value="' + _esc(_cache.costCenters[c].id) + '">' + _esc(_cache.costCenters[c].name) + '</option>';
        html += '</select></div>';
        html += '<div class="flex items-end"><button onclick="RW_Finance._loadBudgetsList()" class="bg-indigo-600 text-white px-4 py-2 rounded-lg font-bold w-full"><i class="fa-solid fa-search ml-1"></i> عرض</button></div>';
        html += '</div><div id="budgets-list" class="overflow-x-auto"></div></div>';
        safeHTML(content, html);
    }

function _loadBudgetsList() {
    var listDiv = byId('budgets-list');
    if (!listDiv) return;
    safeHTML(listDiv, '<div class="text-center py-8"><i class="fa-solid fa-spinner fa-spin"></i> جاري التحميل...</div>');

    var year = parseInt(byId('budget-year').value, 10);
    var month = parseInt(byId('budget-month').value, 10);
    var ccId = byId('budget-cc').value || null;

    supabase.rpc('get_budget_vs_actual', {
        p_year: year,
        p_month: month,
        p_cost_center_id: ccId
    }).then(function(res) {
        if (res.error) throw res.error;
        var data = res.data || [];
        if (!data.length) {
            safeHTML(listDiv, '<div class="text-center py-8 text-gray-500">لا توجد بيانات</div>');
            return;
        }

        var html = '<table class="w-full text-sm border-collapse"><thead><tr class="bg-indigo-50">' +
            '<th class="p-2 border">الحساب</th><th class="p-2 border text-center">الموازنة</th>' +
            '<th class="p-2 border text-center">الفعلي</th><th class="p-2 border text-center">الانحراف</th>' +
            '<th class="p-2 border text-center">%</th><th class="p-2 border text-center">الحالة</th>' +
            '<th class="p-2 border text-center">تعيين</th></tr></thead><tbody>';

        for (var i = 0; i < data.length; i++) {
            var row = data[i];
            var statusBadge = row.status === 'within' ? '<span class="bg-green-100 text-green-700 px-2 py-1 rounded-full text-xs">ضمن</span>' :
                row.status === 'over' ? '<span class="bg-red-100 text-red-700 px-2 py-1 rounded-full text-xs">تجاوز</span>' :
                row.status === 'under' ? '<span class="bg-blue-100 text-blue-700 px-2 py-1 rounded-full text-xs">أقل</span>' :
                '<span class="bg-gray-100 text-gray-500 px-2 py-1 rounded-full text-xs">بدون</span>';
            var accountName = _esc(row.account_name);
            var safeAccountName = accountName.replace(/\\/g, '\\\\').replace(/'/g, "\\'");
            html += '<tr class="border-t hover:bg-gray-50">' +
                '<td class="p-2">' + accountName + '</td>' +
                '<td class="p-2 text-center">' + _fmtNum(row.budgeted_amount) + '</td>' +
                '<td class="p-2 text-center">' + _fmtNum(row.actual_amount) + '</td>' +
                '<td class="p-2 text-center">' + _fmtNum(row.variance) + '</td>' +
                '<td class="p-2 text-center">' + Number(row.variance_percent || 0).toFixed(2) + '%</td>' +
                '<td class="p-2 text-center">' + statusBadge + '</td>' +
                '<td class="p-2 text-center"><button onclick="RW_Finance._editBudget(\'' +
                _esc(row.account_id) + '\',\'' + safeAccountName + '\',' + year + ',' + month + ',\'' +
                (ccId || '') + '\')" class="text-indigo-600" title="تعيين الموازنة"><i class="fa-solid fa-pen-to-square"></i></button></td>' +
                '</tr>';
        }
        html += '</tbody></table>';
        safeHTML(listDiv, html);
    }).catch(function(e) {
        safeHTML(listDiv, '<div class="text-center py-8 text-red-500">' + _esc(e.message || 'فشل تحميل الموازنات') + '</div>');
    });
}
function _editBudget(accountId, accountName, year, month, costCenterId) {
    var ccId = costCenterId || null;
    var ccOptions = '<option value="">بدون مركز تكلفة</option>' +
        (_cache.costCenters || []).map(function(cc) {
            return '<option value="' + _esc(cc.id) + '"' + (ccId === cc.id ? ' selected' : '') + '>' +
                _esc(cc.name || cc.code || cc.id) + '</option>';
        }).join('');

    Swal.fire({
        title: 'تعيين موازنة: ' + accountName,
        html: '<div class="text-right">' +
            '<p class="text-sm text-gray-500 mb-4">' + month + ' / ' + year + '</p>' +
            '<label class="block text-sm font-bold mb-2">مركز التكلفة</label>' +
            '<select id="swal-budget-cc" class="swal2-input w-full">' + ccOptions + '</select>' +
            '<label class="block text-sm font-bold mb-2">المبلغ المخطط</label>' +
            '<input type="number" id="swal-budget-amount" step="0.01" min="0" class="swal2-input w-full" placeholder="0.00">' +
            '</div>',
        showCancelButton: true,
        confirmButtonText: 'حفظ',
        cancelButtonText: 'إلغاء',
        preConfirm: function() {
            var amount = parseFloat(document.getElementById('swal-budget-amount').value);
            var selectedCC = document.getElementById('swal-budget-cc').value || null;
            if (!Number.isFinite(amount) || amount < 0) {
                Swal.showValidationMessage('أدخل مبلغًا صحيحًا أكبر أو يساوي صفرًا');
                return false;
            }
            return {
                amount: amount,
                costCenterId: selectedCC
            };
        }
    }).then(function(result) {
        if (!result.isConfirmed) return;

        var amount = result.value.amount;
        var selectedCC = result.value.costCenterId;
        var host = byId('finance-content');
        var operationId = host && host.dataset.budgetOperationId;
        if (!operationId) {
            operationId = (window.crypto && crypto.randomUUID) ? crypto.randomUUID() : String(Date.now()) + '-' + Math.random();
            if (host) host.dataset.budgetOperationId = operationId;
        }

        _showLoader('جاري حفظ الموازنة...');
        supabase.rpc('save_budget_atomic', {
            p_account_id: accountId,
            p_budget_year: year,
            p_budget_month: month,
            p_budgeted_amount: amount,
            p_cost_center_id: selectedCC,
            p_notes: null,
            p_operation_id: operationId
        }).then(function(res) {
            if (res.error) throw res.error;
            var duplicate = res.data && res.data.duplicate === true;
            if (host) delete host.dataset.budgetOperationId;
            _showToast(duplicate ? 'الموازنة موجودة بالفعل ولم تُكرر.' : 'تم حفظ الموازنة', 'success');
            _loadBudgetsList();
        }).catch(function(e) {
            _showToast(e.message || 'فشل حفظ الموازنة', 'error');
        }).finally(_hideLoader);
    });
}
function _balanceSheet() {
    var out = byId('report-output');
    if (!out) return;
    safeHTML(out, '<div class="text-center py-8"><i class="fa-solid fa-spinner fa-spin"></i> جاري تحميل الميزانية...</div>');

    var asOfDate = byId('rp-to') ? byId('rp-to').value : new Date().toISOString().slice(0, 10);
    supabase.rpc('get_balance_sheet_data', { p_as_of: asOfDate }).then(function(res) {
        if (res.error) throw res.error;
        var d = res.data || {};
        var assets = d.assets || [];
        var liabilities = d.liabilities || [];
        var equity = d.equity || [];
        var totalAssets = 0;
        var totalLiabilities = 0;
        var totalEquity = 0;

        var html = '<div class="bg-white p-5 rounded-xl border">';
        html += '<h3 class="font-black text-2xl mb-5 text-center">الميزانية العمومية حتى ' + _esc(asOfDate) + '</h3>';
        html += '<div class="grid grid-cols-1 md:grid-cols-3 gap-4">';

        function section(title, rows, cls) {
            var total = 0;
            var block = '<div class="' + cls + ' p-4 rounded-xl border"><h4 class="font-black text-lg mb-3">' + title + '</h4><table class="w-full text-sm">';
            for (var i = 0; i < rows.length; i++) {
                var amount = Number(rows[i].balance || 0);
                total += amount;
                block += '<tr class="border-b"><td class="py-2">' + _esc(rows[i].account_name) + '</td><td class="py-2 text-left font-bold">' + _fmtNum(amount) + '</td></tr>';
            }
            block += '<tr class="font-black"><td class="py-2">الإجمالي</td><td class="py-2 text-left">' + _fmtNum(total) + '</td></tr></table></div>';
            return { html: block, total: total };
        }

        var a = section('الأصول', assets, 'bg-blue-50');
        var l = section('الخصوم', liabilities, 'bg-red-50');
        var e = section('حقوق الملكية', equity, 'bg-emerald-50');
        totalAssets = a.total;
        totalLiabilities = l.total;
        totalEquity = e.total;
        html += a.html + l.html + e.html + '</div>';

        var rhs = totalLiabilities + totalEquity;
        var difference = totalAssets - rhs;
        html += '<div class="mt-5 p-4 rounded-xl border ' + (Math.abs(difference) < 0.005 ? 'bg-green-50' : 'bg-red-50') + '">' +
            '<div class="flex flex-wrap justify-between gap-3 font-black">' +
            '<span>الأصول: ' + _fmtNum(totalAssets) + '</span>' +
            '<span>الخصوم + حقوق الملكية: ' + _fmtNum(rhs) + '</span>' +
            '<span>فرق التوازن: ' + _fmtNum(difference) + '</span>' +
            '</div>' +
            '<div class="mt-2 text-sm">' + (Math.abs(difference) < 0.005 ? 'الميزانية متوازنة.' : 'يوجد فرق يحتاج مراجعة.') + '</div>' +
            '</div></div>';

        safeHTML(out, html);
    }).catch(function(e) {
        safeHTML(out, '<div class="text-center py-8 text-red-500">' + _esc(e.message || 'فشل تحميل الميزانية') + '</div>');
    });
}

    function _costCenterProfitLoss() {
        var out = byId('report-output'); if (!out) return;
        safeHTML(out, '<div class="text-center py-8"><i class="fa-solid fa-spinner fa-spin"></i> جاري التحميل...</div>');
        var fromDate = byId('rp-from') ? byId('rp-from').value : '';
        var toDate = byId('rp-to') ? byId('rp-to').value : '';
        supabase.rpc('get_pnl_by_cost_center', { p_date_from: fromDate, p_date_to: toDate }).then(function(res) {
            var data = res.data || [];
            if (!data.length) { safeHTML(out, '<div class="text-center py-8 text-gray-500">لا توجد بيانات</div>'); return; }
            var html = '<h4 class="font-bold mb-3">أرباح/خسائر حسب مركز التكلفة</h4><table class="w-full text-sm border"><thead><tr class="bg-gray-50"><th class="p-2">المركز</th><th class="p-2 text-center">الإيرادات</th><th class="p-2 text-center">المصروفات</th><th class="p-2 text-center">الصافي</th></tr></thead><tbody>';
            for (var i = 0; i < data.length; i++) {
                var net = data[i].net_income || 0;
                var netClass = net >= 0 ? 'text-green-600' : 'text-red-600';
                html += '<tr class="border-t"><td class="p-2">' + _esc(data[i].cost_center_name) + '</td><td class="p-2 text-center">' + _fmtNum(data[i].revenue) + '</td><td class="p-2 text-center">' + _fmtNum(data[i].expenses) + '</td><td class="p-2 text-center font-bold ' + netClass + '">' + _fmtNum(net) + '</td></tr>';
            }
            html += '</tbody></table>';
            safeHTML(out, html);
        }).catch(function(e) { safeHTML(out, '<div class="text-center py-8 text-red-500">فشل التحميل</div>'); });
    }

function _accountActivity() {
    var out = byId('report-output');
    if (!out) return;
    var accountId = byId('rp-account') ? byId('rp-account').value : '';
    if (!accountId) {
        safeHTML(out, '<div class="text-center py-8 text-amber-600">اختر حسابًا أولًا لعرض الأستاذ العام.</div>');
        return;
    }
    safeHTML(out, '<div class="text-center py-8"><i class="fa-solid fa-spinner fa-spin"></i> جاري تحميل الأستاذ العام...</div>');

    supabase.rpc('accountant_gl_account_activity', {
        p_account_id: accountId,
        p_from_date: byId('rp-from').value,
        p_to_date: byId('rp-to').value
    }).then(function(res) {
        if (res.error) throw res.error;
        var rows = res.data || [];
        var account = null;
        for (var i = 0; i < _cache.accountsFlat.length; i++) {
            if (_cache.accountsFlat[i].id === accountId) { account = _cache.accountsFlat[i]; break; }
        }
        var html = '<div class="bg-white border rounded-xl p-4"><h3 class="font-black text-xl mb-4">الأستاذ العام: ' +
            _esc(account ? account.account_name : accountId) + '</h3>';
        if (!rows.length) {
            html += '<div class="text-center py-8 text-gray-500">لا توجد حركة في الفترة المحددة.</div></div>';
            safeHTML(out, html);
            return;
        }
        html += '<div class="overflow-x-auto"><table class="w-full text-sm border"><thead><tr class="bg-gray-50">' +
            '<th class="p-2">التاريخ</th><th class="p-2">القيد</th><th class="p-2">المرجع</th>' +
            '<th class="p-2">الوصف</th><th class="p-2">مدين</th><th class="p-2">دائن</th><th class="p-2">الرصيد الجاري</th>' +
            '</tr></thead><tbody>';
        for (var r = 0; r < rows.length; r++) {
            html += '<tr class="border-t"><td class="p-2">' + _esc(rows[r].entry_date) + '</td>' +
                '<td class="p-2">' + _esc(rows[r].entry_code) + '</td>' +
                '<td class="p-2">' + _esc(rows[r].reference) + '</td>' +
                '<td class="p-2">' + _esc(rows[r].description) + '</td>' +
                '<td class="p-2 text-left">' + _fmtNum(rows[r].debit) + '</td>' +
                '<td class="p-2 text-left">' + _fmtNum(rows[r].credit) + '</td>' +
                '<td class="p-2 text-left font-bold">' + _fmtNum(rows[r].running_balance) + '</td></tr>';
        }
        html += '</tbody></table></div></div>';
        safeHTML(out, html);
    }).catch(function(e) {
        safeHTML(out, '<div class="text-center py-8 text-red-500">' + _esc(e.message || 'فشل تحميل الأستاذ العام') + '</div>');
    });
}

function _periodReadiness() {
    var out = byId('report-output');
    if (!out) return;
    safeHTML(out, '<div class="text-center py-8">جاري فحص جاهزية الفترة...</div>');
    supabase.rpc('accountant_period_readiness', {
        p_from_date: byId('rp-from').value,
        p_to_date: byId('rp-to').value
    }).then(function(res) {
        if (res.error) throw res.error;
        var rows = res.data || [];
        var html = '<div class="bg-white border rounded-xl p-4"><h3 class="font-black text-xl mb-4">جاهزية الفترة</h3>' +
            '<table class="w-full text-sm border"><thead><tr class="bg-gray-50"><th class="p-2">البوابة</th><th class="p-2">الحالة</th><th class="p-2">المؤشر</th><th class="p-2">التفصيل</th></tr></thead><tbody>';
        for (var i = 0; i < rows.length; i++) {
            var cls = rows[i].status === 'PASS' ? 'text-green-700' : rows[i].status === 'FAIL' ? 'text-red-700' : 'text-amber-700';
            html += '<tr class="border-t"><td class="p-2 font-bold">' + _esc(rows[i].gate_code) + '</td>' +
                '<td class="p-2 font-black ' + cls + '">' + _esc(rows[i].status) + '</td>' +
                '<td class="p-2">' + _fmtNum(rows[i].metric) + '</td>' +
                '<td class="p-2">' + _esc(rows[i].detail) + '</td></tr>';
        }
        html += '</tbody></table></div>';
        safeHTML(out, html);
    }).catch(function(e) {
        safeHTML(out, '<div class="text-center py-8 text-red-500">' + _esc(e.message || 'فشل فحص الجاهزية') + '</div>');
    });
}

function _reconciliationSummary() {
    var out = byId('report-output');
    if (!out) return;
    safeHTML(out, '<div class="text-center py-8">جاري تنفيذ المطابقات...</div>');
    supabase.rpc('accountant_reconciliation_summary', {
        p_as_of_date: byId('rp-to').value
    }).then(function(res) {
        if (res.error) throw res.error;
        var rows = res.data || [];
        var html = '<div class="bg-white border rounded-xl p-4"><h3 class="font-black text-xl mb-4">مركز المطابقات</h3>' +
            '<table class="w-full text-sm border"><thead><tr class="bg-gray-50"><th class="p-2">الاختبار</th><th class="p-2">الحالة</th><th class="p-2">الفرق</th><th class="p-2">التفصيل</th></tr></thead><tbody>';
        for (var i = 0; i < rows.length; i++) {
            var cls = rows[i].status === 'OK' ? 'text-green-700' : 'text-red-700';
            html += '<tr class="border-t"><td class="p-2 font-bold">' + _esc(rows[i].check_code) + '</td>' +
                '<td class="p-2 font-black ' + cls + '">' + _esc(rows[i].status) + '</td>' +
                '<td class="p-2 text-left">' + _fmtNum(rows[i].difference) + '</td>' +
                '<td class="p-2">' + _esc(rows[i].detail) + '</td></tr>';
        }
        html += '</tbody></table></div>';
        safeHTML(out, html);
    }).catch(function(e) {
        safeHTML(out, '<div class="text-center py-8 text-red-500">' + _esc(e.message || 'فشل المطابقة') + '</div>');
    });
}

function _exceptionCenter() {
    var out = byId('report-output');
    if (!out) return;
    safeHTML(out, '<div class="text-center py-8">جاري تحميل مركز الاستثناءات...</div>');
    supabase.rpc('accountant_exception_center', {
        p_as_of_date: byId('rp-to').value
    }).then(function(res) {
        if (res.error) throw res.error;
        var rows = res.data || [];
        var html = '<div class="bg-white border rounded-xl p-4"><h3 class="font-black text-xl mb-4">مركز الاستثناءات</h3>';
        if (!rows.length) {
            html += '<div class="text-center py-8 text-green-700 font-bold">لا توجد استثناءات مكتشفة.</div></div>';
            safeHTML(out, html);
            return;
        }
        html += '<div class="overflow-x-auto"><table class="w-full text-sm border"><thead><tr class="bg-gray-50"><th class="p-2">النوع</th><th class="p-2">الخطورة</th><th class="p-2">المفتاح</th><th class="p-2">الوصف</th><th class="p-2">القيمة</th><th class="p-2">وقت الاكتشاف</th></tr></thead><tbody>';
        for (var i = 0; i < rows.length; i++) {
            var sev = rows[i].severity === 'HIGH' ? 'text-red-700' : rows[i].severity === 'MEDIUM' ? 'text-amber-700' : 'text-slate-700';
            html += '<tr class="border-t"><td class="p-2">' + _esc(rows[i].exception_type) + '</td>' +
                '<td class="p-2 font-black ' + sev + '">' + _esc(rows[i].severity) + '</td>' +
                '<td class="p-2">' + _esc(rows[i].record_key) + '</td>' +
                '<td class="p-2">' + _esc(rows[i].description) + '</td>' +
                '<td class="p-2 text-left">' + _fmtNum(rows[i].amount) + '</td>' +
                '<td class="p-2">' + _esc(rows[i].detected_at) + '</td></tr>';
        }
        html += '</tbody></table></div></div>';
        safeHTML(out, html);
    }).catch(function(e) {
        safeHTML(out, '<div class="text-center py-8 text-red-500">' + _esc(e.message || 'فشل تحميل الاستثناءات') + '</div>');
    });
}
function _customerAging() {
    var out = byId('report-output');
    if (!out) return;
    safeHTML(out, '<div class="text-center py-8">جاري تحميل أعمار العملاء...</div>');
    supabase.rpc('accountant_customer_aging', {
        p_as_of_date: byId('rp-to').value
    }).then(function(res) {
        if (res.error) throw res.error;
        var rows = res.data || [];
        var html = '<div class="bg-white border rounded-xl p-4"><h3 class="font-black text-xl mb-4">أعمار أرصدة العملاء</h3><div class="overflow-x-auto"><table class="w-full text-sm border"><thead><tr class="bg-gray-50"><th class="p-2">العميل</th><th class="p-2">الحالي</th><th class="p-2">1-30</th><th class="p-2">31-60</th><th class="p-2">61-90</th><th class="p-2">أكثر من 90</th><th class="p-2">الصافي</th></tr></thead><tbody>';
        for (var i = 0; i < rows.length; i++) {
            html += '<tr class="border-t"><td class="p-2">' + _esc(rows[i].customer_name) + ' (' + _esc(rows[i].customer_code) + ')</td>' +
                '<td class="p-2 text-left">' + _fmtNum(rows[i].current_amount) + '</td>' +
                '<td class="p-2 text-left">' + _fmtNum(rows[i].days_1_30) + '</td>' +
                '<td class="p-2 text-left">' + _fmtNum(rows[i].days_31_60) + '</td>' +
                '<td class="p-2 text-left">' + _fmtNum(rows[i].days_61_90) + '</td>' +
                '<td class="p-2 text-left">' + _fmtNum(rows[i].over_90) + '</td>' +
                '<td class="p-2 text-left font-bold">' + _fmtNum(rows[i].net_balance) + '</td></tr>';
        }
        html += '</tbody></table></div></div>';
        safeHTML(out, html);
    }).catch(function(e) {
        safeHTML(out, '<div class="text-center py-8 text-red-500">' + _esc(e.message || 'فشل أعمار العملاء') + '</div>');
    });
}
function _supplierAging() {
    var out = byId('report-output');
    if (!out) return;
    safeHTML(out, '<div class="text-center py-8">جاري تحميل أعمار الموردين...</div>');
    supabase.rpc('accountant_supplier_aging', {
        p_as_of_date: byId('rp-to').value
    }).then(function(res) {
        if (res.error) throw res.error;
        var rows = res.data || [];
        var html = '<div class="bg-white border rounded-xl p-4"><h3 class="font-black text-xl mb-4">أعمار أرصدة الموردين</h3><div class="overflow-x-auto"><table class="w-full text-sm border"><thead><tr class="bg-gray-50"><th class="p-2">المورد</th><th class="p-2">الحالي</th><th class="p-2">1-30</th><th class="p-2">31-60</th><th class="p-2">61-90</th><th class="p-2">أكثر من 90</th><th class="p-2">الصافي</th></tr></thead><tbody>';
        for (var i = 0; i < rows.length; i++) {
            html += '<tr class="border-t"><td class="p-2">' + _esc(rows[i].supplier_name) + ' (' + _esc(rows[i].supplier_code) + ')</td>' +
                '<td class="p-2 text-left">' + _fmtNum(rows[i].current_amount) + '</td>' +
                '<td class="p-2 text-left">' + _fmtNum(rows[i].days_1_30) + '</td>' +
                '<td class="p-2 text-left">' + _fmtNum(rows[i].days_31_60) + '</td>' +
                '<td class="p-2 text-left">' + _fmtNum(rows[i].days_61_90) + '</td>' +
                '<td class="p-2 text-left">' + _fmtNum(rows[i].over_90) + '</td>' +
                '<td class="p-2 text-left font-bold">' + _fmtNum(rows[i].net_balance) + '</td></tr>';
        }
        html += '</tbody></table></div></div>';
        safeHTML(out, html);
    }).catch(function(e) {
        safeHTML(out, '<div class="text-center py-8 text-red-500">' + _esc(e.message || 'فشل أعمار الموردين') + '</div>');
    });
}

    return {
        render: render, renderSubTab: renderSubTab,
        _filterTreasury: _filterTreasury, _openTreasuryDialog: _openTreasuryDialog, _editTreasury: _editTreasury,
        _filterAccounts: _filterAccounts, _openAccountDialog: _openAccountDialog, _seedAccounts: _seedAccounts,
        _addJournalLine: _addJournalLine, _removeJournalLine: _removeJournalLine, _recalcJournalTotal: _recalcJournalTotal, _saveJournalEntry: _saveJournalEntry,
        _newReceipt: _newReceipt, _addReceiptLine: _addReceiptLine, _removeReceiptLine: _removeReceiptLine, _recalcReceiptTotal: _recalcReceiptTotal, _saveReceipt: _saveReceipt,
        _newPayment: _newPayment, _addPaymentLine: _addPaymentLine, _removePaymentLine: _removePaymentLine, _recalcPaymentTotal: _recalcPaymentTotal, _savePayment: _savePayment,
        _newTransfer: _newTransfer, _saveTransfer: _saveTransfer,
        _trialBalance: _trialBalance, _profitLoss: _profitLoss,
        _renderBudgets: _renderBudgets, _loadBudgetsList: _loadBudgetsList, _editBudget: _editBudget,
        _balanceSheet: _balanceSheet,
_cashFlow: _cashFlow,
_accountActivity: _accountActivity,
_periodReadiness: _periodReadiness,
_reconciliationSummary: _reconciliationSummary,
_exceptionCenter: _exceptionCenter,
_customerAging: _customerAging,
_supplierAging: _supplierAging,
_costCenterProfitLoss: _costCenterProfitLoss
    };
})();
window.RW_Finance = RW_Finance;
