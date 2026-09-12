/*
 * RAWAEA ERP — Main8 Owner Surgical Replacement Package
 * Date: 2026-09-12
 * Source of Truth: Current/PWA/main2/main8.md
 * Current source SHA before owner apply:
 *   2131fbf3096d926b2486acb2ab58a4266ddd1bbc
 *
 * IMPORTANT:
 * - This file is the owner-side change package. Do NOT paste this whole file into main8.md.
 * - Apply each named section only to its exact function/anchor in Main8.
 * - Assistant does NOT edit Current/PWA/main2/main8.md.
 * - Production changes are documented separately in the Main8 execution report.
 *
 * Governing Gold/Diamond target:
 * هناك نقص شديد في كل التبويبات ، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات،
 * بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها.
 * هذا جزء من هدف Gold/Diamond للمشروع، ولا تتعامل معه كإضافات شكلية.
 * وهذا متسق حرفيًا مع مبدأ الحوكمة: الدراسة أولًا، ثم إعادة بناء العقد التاريخي، ثم تتبع السلوك الحالي،
 * ثم تحديد الفجوة، ثم التعديل الجراحي، ثم الاختبار والتحقق.
 */

/* ============================================================
   O1 — _editTreasury(code)
   MAIN8 CURRENT START: line 181
   DELETE THE FULL CURRENT FUNCTION UNTIL THE LAST } IMMEDIATELY
   BEFORE THE COMMENT:
   // ==================== دليل الحسابات ====================
   ============================================================ */
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

/* ============================================================
   O2 — _filterAccounts()
   CURRENT START: line 258 تقريبًا
   DELETE UNTIL THE LAST } IMMEDIATELY BEFORE:
   function _openAccountDialog(editId) {
   ============================================================ */
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

/* ============================================================
   O3 — _openAccountDialog(editId)
   CURRENT START: line 272 تقريبًا
   DELETE UNTIL THE LAST } IMMEDIATELY BEFORE:
   async function _seedAccounts() {
   ============================================================ */
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

/* ============================================================
   O4 — _renderReports()
   CURRENT START: line 1022
   DELETE UNTIL THE LAST } IMMEDIATELY BEFORE:
   function _trialBalance() {
   ============================================================ */
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

/* ============================================================
   O5 — _profitLoss()
   CURRENT START: line 1051
   DELETE UNTIL THE LAST } IMMEDIATELY BEFORE:
   function _renderBudgets() {
   ============================================================ */
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

/* ============================================================
   O6 — _balanceSheet()
   CURRENT START: line 1128
   DELETE UNTIL THE LAST } IMMEDIATELY BEFORE:
   function _costCenterProfitLoss() {
   ============================================================ */
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

/* ============================================================
   O7 — ADD _cashFlow()
   INSERT DIRECTLY ABOVE:
   function _balanceSheet() {
   ============================================================ */
async function _cashFlow() {
    var out = byId('report-output');
    if (!out) return;
    safeHTML(out, '<div class="text-center py-8"><i class="fa-solid fa-spinner fa-spin"></i> جاري تحميل التدفقات النقدية...</div>');

    var fromDate = byId('rp-from') ? byId('rp-from').value : '';
    var toDate = byId('rp-to') ? byId('rp-to').value : '';
    if (!fromDate || !toDate) {
        safeHTML(out, '<div class="text-center py-8 text-red-500">حدد نطاق التاريخ أولًا.</div>');
        return;
    }

    try {
        var res = await supabase.rpc('get_cash_flow', {
            p_from_date: fromDate,
            p_to_date: toDate
        });
        if (res.error) throw res.error;
        var rows = res.data || [];
        var grouped = {};
        var grand = 0;

        for (var i = 0; i < rows.length; i++) {
            var r = rows[i];
            var category = r.category || 'operating_outflow';
            if (!grouped[category]) grouped[category] = { rows: [], total: 0 };
            var amount = Number(r.amount || 0);
            grouped[category].rows.push(r);
            grouped[category].total += amount;
            grand += amount;
        }

        var labels = {
            operating_inflow: 'تدفقات تشغيلية داخلة',
            operating_outflow: 'تدفقات تشغيلية خارجة',
            investing: 'تدفقات استثمارية',
            financing: 'تدفقات تمويلية'
        };

        var html = '<div class="bg-white border rounded-xl p-5"><h3 class="font-black text-2xl mb-4 text-center">قائمة التدفقات النقدية</h3>';
        html += '<div class="text-center text-sm text-gray-500 mb-5">من ' + _esc(fromDate) + ' إلى ' + _esc(toDate) + '</div>';

        var order = ['operating_inflow', 'operating_outflow', 'investing', 'financing'];
        for (var c = 0; c < order.length; c++) {
            var key = order[c];
            if (!grouped[key]) continue;
            html += '<div class="mb-5"><div class="flex justify-between font-black mb-2"><span>' + labels[key] + '</span><span>' + _fmtNum(grouped[key].total) + '</span></div>';
            html += '<table class="w-full text-sm border"><thead><tr class="bg-gray-50"><th class="p-2 text-right">الحساب</th><th class="p-2 text-left">المبلغ</th></tr></thead><tbody>';
            for (var x = 0; x < grouped[key].rows.length; x++) {
                html += '<tr class="border-t"><td class="p-2">' + _esc(grouped[key].rows[x].account_name) + ' (' + _esc(grouped[key].rows[x].account_id) + ')</td><td class="p-2 text-left font-bold">' + _fmtNum(grouped[key].rows[x].amount) + '</td></tr>';
            }
            html += '</tbody></table></div>';
        }

        html += '<div class="mt-4 p-4 rounded-xl bg-cyan-50 border font-black flex justify-between"><span>صافي التدفقات حسب عقد Production</span><span>' + _fmtNum(grand) + '</span></div></div>';
        safeHTML(out, html);
    } catch (e) {
        safeHTML(out, '<div class="text-center py-8 text-red-500">' + _esc(e.message || 'فشل تحميل التدفقات النقدية') + '</div>');
    }
}

/* ============================================================
   O8 — _loadBudgetsList()
   CURRENT START: line 1093
   DELETE UNTIL THE LAST } IMMEDIATELY BEFORE:
   function _editBudget(accountId, accountName, year, month) {
   ============================================================ */
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

/* ============================================================
   O9 — _editBudget(accountId, accountName, year, month, costCenterId)
   CURRENT START: line 1113
   DELETE UNTIL THE LAST } IMMEDIATELY BEFORE:
   function _balanceSheet() {
   ============================================================ */
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

/* ============================================================
   O11 — _accountActivity()
   INSERT anywhere before the final return object; recommended
   immediately after _cashFlow().
   ============================================================ */
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

/* ============================================================
   O12 — _periodReadiness()
   ============================================================ */
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

/* ============================================================
   O13 — _reconciliationSummary()
   ============================================================ */
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

/* ============================================================
   O14 — _exceptionCenter()
   ============================================================ */
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

/* ============================================================
   O15 — _customerAging()
   ============================================================ */
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

/* ============================================================
   O16 — _supplierAging()
   ============================================================ */
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

/* ============================================================
   O10 — FINAL RETURN OBJECT CHANGE
   CURRENT LINE: final return object near EOF.
   FIND EXACT CURRENT TEXT:
   _balanceSheet: _balanceSheet, _costCenterProfitLoss: _costCenterProfitLoss

   REPLACE WITH:
   ============================================================ */
/*
_balanceSheet: _balanceSheet,
_cashFlow: _cashFlow,
_accountActivity: _accountActivity,
_periodReadiness: _periodReadiness,
_reconciliationSummary: _reconciliationSummary,
_exceptionCenter: _exceptionCenter,
_customerAging: _customerAging,
_supplierAging: _supplierAging,
_costCenterProfitLoss: _costCenterProfitLoss
*/

/* ============================================================
   OWNER APPLICATION ORDER
   1. O1
   2. O2
   3. O3
   4. O4
   5. O5
   6. O8
   7. O9
   8. O7 insertion immediately above _balanceSheet
   9. O6
  10. O11..O16 insert before final return object
  11. O10 return export line

   Do not modify other Main8 functions unless a fresh forensic gate proves
   a new defect after these replacements. Do not edit main1..main11 by
   broad search/replace or by deleting partial lines.
   ============================================================ */
