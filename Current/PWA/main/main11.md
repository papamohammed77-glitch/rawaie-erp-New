// ============================================================
// RAWAEA ERP — MAIN11
// HR / CRM / BOOT / GLOBAL COMPATIBILITY BOUNDARY
//
// Governance:
// - Fragment only; part of the single logical main.html.
// - No Physical Stock writer.
// - No Accounting / Ledger writer.
// - Tenant identity comes from RW_ShellContext.
// - DB field names must match Current Production schema.
// - Preserve public functions and cross-part contracts.
// ============================================================

(function () {
    'use strict';

    function _rwEsc(value) {
        return String(value == null ? '' : value).replace(/[&<>"']/g, function (m) {
            if (m === '&') return '&amp;';
            if (m === '<') return '&lt;';
            if (m === '>') return '&gt;';
            if (m === '"') return '&quot;';
            return '&#39;';
        });
    }

    function _rwCompanyId() {
        if (!window.RW_ShellContext || typeof window.RW_ShellContext.getCompanyId !== 'function') {
            throw new Error('TENANT_CONTEXT_UNAVAILABLE');
        }
        var companyId = window.RW_ShellContext.getCompanyId();
        if (!companyId) throw new Error('TENANT_CONTEXT_EMPTY');
        return companyId;
    }

    function _rwUserEmail() {
        try {
            var user = window.RW_STATE && window.RW_STATE.app && window.RW_STATE.app.currentUser;
            return user && user.email ? String(user.email) : '';
        } catch (e) {
            return '';
        }
    }

    function _rwToast(message, type) {
        try {
            if (typeof window.showToast === 'function') {
                window.showToast(message, type || 'info');
                return;
            }
        } catch (e) {}
        try { console.error(message); } catch (ignore) {}
    }

    function _rwShowLoader(message) {
        try {
            if (typeof window.showLoader === 'function') {
                window.showLoader(message || 'جاري التحميل...');
                return;
            }
        } catch (e) {}
    }

    function _rwHideLoader() {
        try {
            if (typeof window.hideLoader === 'function') window.hideLoader();
        } catch (e) {}
    }

    function _rwById(id) {
        try {
            if (typeof window.byId === 'function') return window.byId(id);
        } catch (e) {}
        return document.getElementById(id);
    }

    function _rwSafeHTML(element, html) {
        try {
            if (typeof window.safeHTML === 'function') {
                window.safeHTML(element, html);
                return;
            }
        } catch (e) {}
        if (element) {
            try { element.innerHTML = html; } catch (ignore) {}
        }
    }

    function _rwSafeText(element, text) {
        try {
            if (typeof window.safeText === 'function') {
                window.safeText(element, text);
                return;
            }
        } catch (e) {}
        if (element) {
            try { element.textContent = text == null ? '' : String(text); } catch (ignore) {}
        }
    }

    // ============================================================
    // RW_HR — الموارد البشرية
    // ============================================================

    var RW_HR = (function () {
        var hrData = [];
        var hrLoadSequence = 0;

        function _esc(value) {
            return _rwEsc(value);
        }

        function _fmtNum(value) {
            return Number(value || 0).toLocaleString('ar-EG');
        }

        function _isOwnerRecord(employee) {
            if (!employee) return false;

            try {
                var currentUser = window.RW_STATE &&
                    window.RW_STATE.app &&
                    window.RW_STATE.app.currentUser;

                if (currentUser &&
                    currentUser.isOwner === true &&
                    currentUser.id &&
                    employee.id === currentUser.id) {
                    return true;
                }
            } catch (e) {}

            var permissions = Array.isArray(employee.permissions) ? employee.permissions : [];
            var hasWildcard = permissions.indexOf('*') !== -1;
            var role = String(employee.role || '').trim().toLowerCase();

            return hasWildcard &&
                (role === 'owner' || role === 'مالك' || role === 'مدير النظام');
        }

        async function render() {
            var container = _rwById('rw-page-container');
            if (!container) return;

            var companyId;
            try {
                companyId = _rwCompanyId();
            } catch (e) {
                console.error('RW_HR tenant context', e);
                _rwToast('تعذر تحديد سياق الشركة الآمن', 'error');
                return;
            }

            var loadSequence = ++hrLoadSequence;
            _rwSafeText(_rwById('rw-header-title'), 'الموارد البشرية');
            _rwSafeText(_rwById('rw-header-subtitle'), 'إدارة ملفات الموظفين والرواتب والمستندات');
            _rwShowLoader('جاري تحميل بيانات الموظفين...');

            try {
                if (!window.supabase || typeof window.supabase.from !== 'function') {
                    throw new Error('SUPABASE_CLIENT_UNAVAILABLE');
                }

                // Current Production users schema has no is_owner column.
                // Owner detection is derived from the established permission/identity contract.
                var result = await window.supabase
                    .from('users')
                    .select('id,company_id,name,email,role,status,phone,expiry_date,salary,allowances,deductions,auth_id,permissions')
                    .eq('company_id', companyId)
                    .order('name', { ascending: true });

                if (result.error) throw result.error;
                if (loadSequence !== hrLoadSequence) return;
                hrData = result.data || [];
            } catch (e) {
                if (loadSequence !== hrLoadSequence) return;
                hrData = [];
                console.error('RW_HR.load', e);
                _rwToast('تعذر تحميل بيانات الموظفين', 'error');
            } finally {
                if (loadSequence === hrLoadSequence) _rwHideLoader();
            }

            if (loadSequence !== hrLoadSequence) return;

            var visibleEmployees = [];
            for (var i = 0; i < hrData.length; i++) {
                if (!_isOwnerRecord(hrData[i])) visibleEmployees.push(hrData[i]);
            }

            if (visibleEmployees.length === 0) {
                _rwSafeHTML(
                    container,
                    '<div class="text-center py-10 text-gray-500">لا يوجد موظفون ضمن الشركة الحالية.</div>'
                );
                return;
            }

            var html =
                '<div class="p-4">' +
                    '<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6" id="hr-cards-container">';

            for (var eIndex = 0; eIndex < visibleEmployees.length; eIndex++) {
                var emp = visibleEmployees[eIndex];
                var statusClass = emp.status === 'Active'
                    ? 'bg-green-100 text-green-700'
                    : 'bg-red-100 text-red-700';
                var statusText = emp.status === 'Active' ? 'نشط' : 'غير نشط';
                var initials = (emp.name || '؟').charAt(0);

                var avatarColor = 'bg-blue-500';
                if (emp.role === 'مدير') avatarColor = 'bg-indigo-500';
                else if (emp.role === 'محاسب') avatarColor = 'bg-emerald-500';
                else if (emp.role === 'مندوب' || emp.role === 'سائق') avatarColor = 'bg-amber-500';
                else if (emp.role === 'مخزني') avatarColor = 'bg-purple-500';

                html +=
                    '<div class="bg-white rounded-2xl shadow-sm border p-6 hover:shadow-md transition cursor-pointer" ' +
                        'data-hr-email="' + _esc(emp.email || '') + '" ' +
                        'onclick="RW_HR._openModal(this.dataset.hrEmail)">' +
                        '<div class="flex items-center gap-4 mb-4">' +
                            '<div class="w-16 h-16 ' + avatarColor + ' rounded-2xl flex items-center justify-center text-white text-2xl font-black">' +
                                _esc(initials) +
                            '</div>' +
                            '<div>' +
                                '<h3 class="font-black text-lg text-gray-800">' + _esc(emp.name) + '</h3>' +
                                '<p class="text-sm text-gray-500">' + _esc(emp.role) + '</p>' +
                            '</div>' +
                        '</div>' +
                        '<div class="space-y-2 text-sm">' +
                            '<div class="flex justify-between"><span class="text-gray-500">البريد:</span><span class="font-bold text-gray-700">' +
                                _esc(emp.email) +
                            '</span></div>' +
                            '<div class="flex justify-between"><span class="text-gray-500">الهاتف:</span><span class="font-bold text-gray-700">' +
                                _esc(emp.phone || '-') +
                            '</span></div>' +
                            '<div class="flex justify-between items-center"><span class="text-gray-500">الحالة:</span>' +
                                '<span class="px-2 py-0.5 rounded-full text-xs font-bold ' + statusClass + '">' +
                                    statusText +
                                '</span>' +
                            '</div>' +
                        '</div>' +
                    '</div>';
            }

            html += '</div></div>';
            _rwSafeHTML(container, html);
        }

        function _openModal(email) {
            var normalizedEmail = String(email || '').trim().toLowerCase();
            var employee = null;

            for (var i = 0; i < hrData.length; i++) {
                if (String(hrData[i].email || '').trim().toLowerCase() === normalizedEmail) {
                    employee = hrData[i];
                    break;
                }
            }

            if (!employee) {
                _rwToast('الموظف غير موجود', 'error');
                return;
            }

            var html = '<div class="text-right space-y-6">';

            html +=
                '<div class="bg-gray-50 p-4 rounded-xl">' +
                    '<h4 class="font-bold text-lg mb-3"><i class="fa-solid fa-user ml-2"></i>البيانات الأساسية</h4>' +
                    '<div class="grid grid-cols-2 gap-4">' +
                        '<div><label class="text-xs text-gray-500">الاسم الكامل</label><p class="font-bold">' + _esc(employee.name) + '</p></div>' +
                        '<div><label class="text-xs text-gray-500">البريد الإلكتروني</label><p class="font-bold">' + _esc(employee.email) + '</p></div>' +
                        '<div><label class="text-xs text-gray-500">رقم الهاتف</label><p class="font-bold">' + _esc(employee.phone || '-') + '</p></div>' +
                        '<div><label class="text-xs text-gray-500">الدور الوظيفي</label><p class="font-bold">' + _esc(employee.role) + '</p></div>' +
                        '<div><label class="text-xs text-gray-500">الحالة</label><p class="font-bold">' + _esc(employee.status) + '</p></div>' +
                        '<div><label class="text-xs text-gray-500">تاريخ انتهاء الصلاحية</label><p class="font-bold">' + _esc(employee.expiry_date || 'غير محدد') + '</p></div>' +
                    '</div>' +
                '</div>';

            html +=
                '<div class="bg-gray-50 p-4 rounded-xl">' +
                    '<h4 class="font-bold text-lg mb-3"><i class="fa-solid fa-money-bill-wave ml-2"></i>الراتب</h4>' +
                    '<div class="grid grid-cols-2 gap-4">' +
                        '<div><label class="text-xs text-gray-500">الراتب الأساسي</label><p class="font-bold text-emerald-600">' + _fmtNum(employee.salary) + ' EGP</p></div>' +
                        '<div><label class="text-xs text-gray-500">البدلات</label><p class="font-bold text-emerald-600">' + _fmtNum(employee.allowances) + ' EGP</p></div>' +
                        '<div><label class="text-xs text-gray-500">الخصومات</label><p class="font-bold text-red-600">' + _fmtNum(employee.deductions) + ' EGP</p></div>' +
                        '<div><label class="text-xs text-gray-500">الصافي</label><p class="font-bold text-blue-600">' +
                            _fmtNum(
                                (Number(employee.salary) || 0) +
                                (Number(employee.allowances) || 0) -
                                (Number(employee.deductions) || 0)
                            ) +
                            ' EGP</p></div>' +
                    '</div>' +
                '</div>';

            html +=
                '<div class="bg-gray-50 p-4 rounded-xl">' +
                    '<h4 class="font-bold text-lg mb-3"><i class="fa-solid fa-file-arrow-up ml-2"></i>المستندات</h4>' +
                    '<div class="flex flex-wrap gap-4">' +
                        '<div class="border-2 border-dashed rounded-xl p-6 text-center w-40">' +
                            '<i class="fa-solid fa-id-card text-3xl text-gray-400"></i>' +
                            '<p class="text-xs mt-2">صورة الهوية</p>' +
                            '<p class="text-xs text-gray-400">(قيد التطوير)</p>' +
                        '</div>' +
                        '<div class="border-2 border-dashed rounded-xl p-6 text-center w-40">' +
                            '<i class="fa-solid fa-file-contract text-3xl text-gray-400"></i>' +
                            '<p class="text-xs mt-2">عقد العمل</p>' +
                            '<p class="text-xs text-gray-400">(قيد التطوير)</p>' +
                        '</div>' +
                    '</div>' +
                '</div>' +
            '</div>';

            try {
                window.Swal.fire({
                    title: 'ملف الموظف: ' + _esc(employee.name),
                    html: html,
                    width: '800px',
                    showCloseButton: true,
                    showConfirmButton: false
                });
            } catch (e) {
                console.error('RW_HR._openModal', e);
            }
        }

        return {
            render: render,
            _openModal: _openModal
        };
    })();

    window.RW_HR = RW_HR;

    // ============================================================
    // RW_CRM — إدارة علاقات العملاء
    // ============================================================

    var RW_CRM = (function () {
        var crmRenderSequence = 0;

        function _esc(value) {
            return _rwEsc(value);
        }

        function _fmtNum(value) {
            return Number(value || 0).toLocaleString('ar-EG');
        }

        function _dateFormat(value) {
            return value ? new Date(value).toLocaleDateString('ar-EG') : '';
        }

        function _getCompanyId() {
            return _rwCompanyId();
        }

        async function _resolveCustomer(customerCode) {
            var companyId = _getCompanyId();
            var code = String(customerCode || '').trim();
            if (!code) throw new Error('CUSTOMER_CODE_REQUIRED');

            if (!window.supabase || typeof window.supabase.from !== 'function') {
                throw new Error('SUPABASE_CLIENT_UNAVAILABLE');
            }

            var result = await window.supabase
                .from('customers')
                .select('id,company_id,customer_code,name,phone,area,debt')
                .eq('company_id', companyId)
                .eq('customer_code', code)
                .maybeSingle();

            if (result.error) throw result.error;
            return result.data || null;
        }

        async function render() {
            var container = _rwById('rw-page-container');
            if (!container) return;

            try {
                _getCompanyId();
            } catch (e) {
                console.error('RW_CRM tenant context', e);
                _rwToast('تعذر تحديد سياق الشركة الآمن', 'error');
                return;
            }

            var renderSequence = ++crmRenderSequence;
            _rwSafeText(_rwById('rw-header-title'), 'إدارة علاقات العملاء (CRM)');
            _rwSafeText(_rwById('rw-header-subtitle'), 'سجل المتابعات والاتصالات بالعملاء');

            var customers = [];
            try {
                var stateCustomers = window.RW_STATE &&
                    window.RW_STATE.data &&
                    Array.isArray(window.RW_STATE.data.customers)
                    ? window.RW_STATE.data.customers
                    : [];

                if (stateCustomers.length) {
                    customers = stateCustomers.slice();
                } else if (window.RW_Data && typeof window.RW_Data.loadCustomers === 'function') {
                    customers = await window.RW_Data.loadCustomers();
                }

                if (renderSequence !== crmRenderSequence) return;
            } catch (e) {
                console.error('RW_CRM.render customers', e);
                customers = [];
            }

            _rwSafeHTML(
                container,
                '<div class="p-4">' +
                    '<div class="mb-4">' +
                        '<input type="text" id="crm-search" placeholder="🔍 بحث عن عميل..." class="w-full p-3 bg-white rounded-xl border" oninput="RW_CRM._filterCustomers()">' +
                    '</div>' +
                    '<div class="bg-white rounded-2xl shadow-sm border overflow-y-auto" style="max-height:65vh" id="crm-customers-list">' +
                        _buildCustomersTable(customers) +
                    '</div>' +
                '</div>'
            );
        }

        function _buildCustomersTable(customers) {
            if (!customers || !customers.length) {
                return '<div class="text-center py-10 text-gray-500">لا يوجد عملاء</div>';
            }

            var html =
                '<table class="w-full text-sm">' +
                    '<thead class="sticky top-0 bg-gray-50">' +
                        '<tr>' +
                            '<th class="p-3">العميل</th>' +
                            '<th class="p-3">الهاتف</th>' +
                            '<th class="p-3">المنطقة</th>' +
                            '<th class="p-3 text-center">الرصيد</th>' +
                            '<th class="p-3 text-center">متابعة</th>' +
                        '</tr>' +
                    '</thead>' +
                    '<tbody>';

            for (var i = 0; i < customers.length; i++) {
                var customer = customers[i];
                var code = String(customer.customer_code || '');

                html +=
                    '<tr class="border-b hover:bg-gray-50 cursor-pointer" ' +
                        'data-customer-code="' + _esc(code) + '" ' +
                        'data-customer-name="' + _esc(customer.name || '') + '" ' +
                        'onclick="RW_CRM._openFollowupModal(this.dataset.customerCode,this.dataset.customerName)">' +
                        '<td class="p-3">' +
                            '<div class="font-bold">' + _esc(customer.name) + '</div>' +
                            '<div class="text-xs text-gray-400">' + _esc(code) + '</div>' +
                        '</td>' +
                        '<td class="p-3">' + _esc(customer.phone || '-') + '</td>' +
                        '<td class="p-3">' + _esc(customer.area || '-') + '</td>' +
                        '<td class="p-3 text-center font-bold ' +
                            (Number(customer.debt) > 0 ? 'text-red-500' : 'text-green-600') +
                            '">' + _fmtNum(customer.debt) + ' EGP</td>' +
                        '<td class="p-3 text-center">' +
                            '<button type="button" class="bg-blue-100 text-blue-700 px-3 py-1 rounded-lg text-xs font-bold">' +
                                '<i class="fa-solid fa-plus ml-1"></i> متابعة' +
                            '</button>' +
                        '</td>' +
                    '</tr>';
            }

            return html + '</tbody></table>';
        }

        function _filterCustomers() {
            var search = _rwById('crm-search');
            var q = String(search && search.value ? search.value : '').trim().toLowerCase();
            var customers = [];

            try {
                customers = window.RW_STATE &&
                    window.RW_STATE.data &&
                    Array.isArray(window.RW_STATE.data.customers)
                    ? window.RW_STATE.data.customers
                    : [];
            } catch (e) {
                customers = [];
            }

            var filtered = q
                ? customers.filter(function (customer) {
                    return String(customer.name || '').toLowerCase().indexOf(q) !== -1 ||
                        String(customer.customer_code || '').toLowerCase().indexOf(q) !== -1 ||
                        String(customer.phone || '').indexOf(q) !== -1;
                })
                : customers;

            var list = _rwById('crm-customers-list');
            if (list) _rwSafeHTML(list, _buildCustomersTable(filtered));
        }

        async function _openFollowupModal(customerCode, customerName) {
            _rwShowLoader('جاري تحميل المتابعات...');

            try {
                var customer = await _resolveCustomer(customerCode);
                if (!customer) throw new Error('CUSTOMER_NOT_FOUND');

                // customer_followups has no company_id column in current Production.
                // Tenant isolation is enforced by the RLS policy through the resolved customer code.
                var followupsResult = await window.supabase
                    .from('customer_followups')
                    .select('*')
                    .eq('customer_id', customer.customer_code)
                    .order('followup_date', { ascending: false });

                if (followupsResult.error) throw followupsResult.error;

                var followups = followupsResult.data || [];
                var safeCustomerName = customer.name || customerName || '';

                var html =
                    '<div class="text-right">' +
                        '<div class="bg-blue-50 p-4 rounded-xl mb-4">' +
                            '<h3 class="font-bold text-lg">' + _esc(safeCustomerName) + '</h3>' +
                            '<p class="text-sm text-gray-500">كود: ' + _esc(customer.customer_code) + '</p>';

                if (customer.phone) {
                    var phoneDigits = String(customer.phone).replace(/\D/g, '');
                    html +=
                        '<div class="flex gap-2 mt-3">' +
                            '<a href="tel:' + _esc(customer.phone) + '" class="bg-green-500 text-white px-4 py-2 rounded-lg text-xs font-bold">' +
                                '<i class="fa-solid fa-phone ml-1"></i> اتصال' +
                            '</a>' +
                            '<a href="https://wa.me/' + _esc(phoneDigits) + '" target="_blank" rel="noopener noreferrer" class="bg-emerald-500 text-white px-4 py-2 rounded-lg text-xs font-bold">' +
                                '<i class="fa-brands fa-whatsapp ml-1"></i> واتساب' +
                            '</a>' +
                        '</div>';
                }

                html +=
                        '</div>' +
                        '<div class="bg-gray-50 p-4 rounded-xl mb-4">' +
                            '<h4 class="font-bold mb-3"><i class="fa-solid fa-plus-circle ml-1"></i> إضافة متابعة جديدة</h4>' +
                            '<div class="grid grid-cols-1 md:grid-cols-3 gap-3 mb-3">' +
                                '<div>' +
                                    '<label class="text-xs">التاريخ</label>' +
                                    '<input type="date" id="crm-followup-date" class="p-2 bg-white border rounded w-full text-sm" value="' +
                                        new Date().toISOString().slice(0, 10) +
                                    '">' +
                                '</div>' +
                                '<div>' +
                                    '<label class="text-xs">نوع الاتصال</label>' +
                                    '<select id="crm-followup-type" class="p-2 bg-white border rounded w-full text-sm">' +
                                        '<option>هاتف</option>' +
                                        '<option>واتساب</option>' +
                                        '<option>زيارة</option>' +
                                        '<option>بريد إلكتروني</option>' +
                                        '<option>أخرى</option>' +
                                    '</select>' +
                                '</div>' +
                                '<div>' +
                                    '<label class="text-xs">الحالة</label>' +
                                    '<select id="crm-followup-status" class="p-2 bg-white border rounded w-full text-sm">' +
                                        '<option>معلقة</option>' +
                                        '<option>مكتملة</option>' +
                                        '<option>ملغاة</option>' +
                                    '</select>' +
                                '</div>' +
                            '</div>' +
                            '<div>' +
                                '<label class="text-xs">ملاحظات</label>' +
                                '<textarea id="crm-followup-notes" class="p-2 bg-white border rounded w-full text-sm" rows="2" placeholder="تفاصيل المتابعة..."></textarea>' +
                            '</div>' +
                            '<div class="flex justify-end mt-3">' +
                                '<button type="button" id="btn-save-followup" class="bg-indigo-600 text-white px-6 py-2 rounded-lg font-bold text-sm">حفظ المتابعة</button>' +
                            '</div>' +
                        '</div>' +
                        '<div>' +
                            '<h4 class="font-bold mb-3"><i class="fa-solid fa-clock-rotate-left ml-1"></i> سجل المتابعات</h4>';

                if (followups.length) {
                    html += '<div class="max-h-48 overflow-y-auto space-y-2">';

                    for (var i = 0; i < followups.length; i++) {
                        var followup = followups[i];
                        var statusColor =
                            followup.status === 'مكتملة'
                                ? 'bg-green-100 text-green-700'
                                : followup.status === 'ملغاة'
                                    ? 'bg-red-100 text-red-700'
                                    : 'bg-yellow-100 text-yellow-700';

                        html +=
                            '<div class="bg-white border rounded-lg p-3">' +
                                '<div class="flex justify-between items-start mb-1">' +
                                    '<span class="font-bold text-sm">' + _esc(followup.followup_type) + '</span>' +
                                    '<span class="px-2 py-0.5 rounded-full text-xs font-bold ' + statusColor + '">' +
                                        _esc(followup.status || '-') +
                                    '</span>' +
                                '</div>' +
                                '<p class="text-xs text-gray-500 mb-1">' + _dateFormat(followup.followup_date) + '</p>' +
                                '<p class="text-sm">' + _esc(followup.notes || '-') + '</p>' +
                            '</div>';
                    }

                    html += '</div>';
                } else {
                    html += '<div class="text-center py-4 text-gray-400">لا توجد متابعات سابقة</div>';
                }

                html += '</div></div>';

                window.Swal.fire({
                    title: 'متابعة العميل: ' + _esc(safeCustomerName),
                    html: html,
                    width: '800px',
                    showCloseButton: true,
                    showConfirmButton: false,
                    didOpen: function () {
                        var saveButton = document.getElementById('btn-save-followup');
                        if (!saveButton) return;

                        saveButton.addEventListener('click', async function () {
                            var dateEl = document.getElementById('crm-followup-date');
                            var typeEl = document.getElementById('crm-followup-type');
                            var statusEl = document.getElementById('crm-followup-status');
                            var notesEl = document.getElementById('crm-followup-notes');

                            if (!dateEl || !typeEl || !statusEl || !notesEl) {
                                _rwToast('تعذر قراءة بيانات المتابعة', 'error');
                                return;
                            }

                            var payload = {
                                customer_id: customer.customer_code,
                                followup_date: dateEl.value,
                                followup_type: typeEl.value,
                                status: statusEl.value,
                                notes: String(notesEl.value || '').trim(),
                                created_by: _rwUserEmail()
                            };

                            if (!payload.followup_date) {
                                _rwToast('يرجى تحديد التاريخ', 'warning');
                                return;
                            }

                            if (!payload.customer_id) {
                                _rwToast('بيانات العميل غير صالحة', 'error');
                                return;
                            }

                            _rwShowLoader('جاري حفظ المتابعة...');

                            try {
                                var insertResult = await window.supabase
                                    .from('customer_followups')
                                    .insert(payload);

                                if (insertResult.error) throw insertResult.error;

                                _rwToast('تم حفظ المتابعة', 'success');
                                try { window.Swal.close(); } catch (ignore) {}

                                await _openFollowupModal(customer.customer_code, safeCustomerName);
                            } catch (e) {
                                console.error('RW_CRM.saveFollowup', e);
                                _rwToast('فشل حفظ المتابعة: ' + (e.message || 'خطأ غير معروف'), 'error');
                            } finally {
                                _rwHideLoader();
                            }
                        }, { once: true });
                    }
                });
            } catch (e) {
                console.error('RW_CRM._openFollowupModal', e);

                if (e.message === 'CUSTOMER_NOT_FOUND') {
                    _rwToast('العميل غير موجود ضمن الشركة الحالية', 'error');
                } else {
                    _rwToast('فشل تحميل المتابعات', 'error');
                }
            } finally {
                _rwHideLoader();
            }
        }

        return {
            render: render,
            _filterCustomers: _filterCustomers,
            _openFollowupModal: _openFollowupModal
        };
    })();

    window.RW_CRM = RW_CRM;

    // ============================================================
    // EVENTS & BOOT
    // ============================================================

    function bindEvents() {
        if (window.__RAWAEA_MAIN11_EVENTS_BOUND__) return;

        try {
            var loginForm = _rwById('rw-login-form');
            if (loginForm) {
                loginForm.addEventListener('submit', function (event) {
                    event.preventDefault();
                    if (window.RW_Auth && typeof window.RW_Auth.login === 'function') {
                        window.RW_Auth.login(
                            _rwById('rw-username') ? _rwById('rw-username').value : '',
                            _rwById('rw-password') ? _rwById('rw-password').value : ''
                        );
                    }
                });
            }

            var logoutButton = _rwById('rw-logout-btn');
            if (logoutButton) {
                logoutButton.addEventListener('click', function () {
                    if (window.RW_Auth && typeof window.RW_Auth.logout === 'function') {
                        window.RW_Auth.logout();
                    }
                });
            }

            var mobileButton = _rwById('rw-mobile-menu-btn');
            if (mobileButton) {
                mobileButton.addEventListener('click', function () {
                    var sidebar = _rwById('rw-sidebar');
                    if (sidebar) sidebar.classList.toggle('active');
                });
            }

            var collapseButton = _rwById('rw-collapse-btn');
            if (collapseButton) {
                collapseButton.addEventListener('click', function () {
                    if (window.RW_Navigation &&
                        typeof window.RW_Navigation.toggleSidebar === 'function') {
                        window.RW_Navigation.toggleSidebar();
                    }
                });
            }

            window.__RAWAEA_MAIN11_EVENTS_BOUND__ = true;
        } catch (e) {
            console.error('main11.bindEvents', e);
        }
    }

    async function boot() {
        if (window.__RAWAEA_MAIN11_BOOT_STARTED__) return;
        window.__RAWAEA_MAIN11_BOOT_STARTED__ = true;

        try {
            console.log('RAWAEA ERP BOOTING...');
            bindEvents();

            if (!window.supabase || !window.supabase.auth) {
                console.error('MAIN11_SUPABASE_UNAVAILABLE');
                return;
            }

            var sessionResult = await window.supabase.auth.getSession();

            if (sessionResult &&
                sessionResult.data &&
                sessionResult.data.session) {

                console.log('✅ Session restored');

                var authUser = sessionResult.data.session.user;
                var meta = authUser.user_metadata || {};

                window.RW_STATE.app.authenticated = true;
                window.RW_STATE.app.currentUser = {
                    name: meta.name || authUser.email,
                    email: authUser.email,
                    authId: authUser.id,
                    id: null,
                    companyId: null,
                    role: meta.role || 'مدير النظام',
                    isOwner: meta.isOwner === true || meta.isOwner === 'true'
                };

                // Owner wildcard semantics are governed by main1/ShellContext.
                // Do not invent or grant wildcard here to non-owners.
                window.RW_STATE.permissions = Array.isArray(meta.permissions)
                    ? meta.permissions.slice()
                    : [];

                window.RW_STATE.app.company = {
                    name: meta.companyName || 'الروائع ERP',
                    logo: meta.companyLogo || 'ر'
                };

                if (window.RW_Auth && typeof window.RW_Auth.enterSystem === 'function') {
                    try {
                        await window.RW_Auth.enterSystem();
                    } catch (e) {
                        console.error('ENTER_SYSTEM_FAILED', e);
                    }
                }
            }
        } catch (e) {
            console.error('MAIN11_BOOT_FAILED', e);
        } finally {
            if (window.RW_STATE && window.RW_STATE.app) {
                window.RW_STATE.app.initialized = true;
            }

            try {
                if (localStorage.getItem('rw_sidebar_collapsed') === '1' &&
                    window.RW_Navigation &&
                    typeof window.RW_Navigation.toggleSidebar === 'function') {
                    setTimeout(function () {
                        try { window.RW_Navigation.toggleSidebar(); } catch (ignore) {}
                    }, 300);
                }
            } catch (e) {}

            console.log('SYSTEM READY');
        }
    }

    if (!window.__RAWAEA_MAIN11_BOOT_BOUND__) {
        window.__RAWAEA_MAIN11_BOOT_BOUND__ = true;
        document.addEventListener('DOMContentLoaded', boot);
    }

    // ============================================================
    // Password reset compatibility
    // ============================================================

    window.resetPassword = function () {
        var emailElement = _rwById('rw-username');
        var email = emailElement ? String(emailElement.value || '').trim() : '';

        if (!email) {
            _rwToast('يرجى إدخال بريدك الإلكتروني أولاً في حقل اسم المستخدم', 'warning');
            return;
        }

        _rwShowLoader('جاري إرسال رابط إعادة التعيين...');

        window.supabase.auth.resetPasswordForEmail(email)
            .then(function (result) {
                _rwHideLoader();

                if (result.error) {
                    _rwToast('فشل الإرسال: ' + result.error.message, 'error');
                    return;
                }

                _rwToast(
                    'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني. راجع صندوق الوارد.',
                    'success'
                );
            })
            .catch(function () {
                _rwHideLoader();
                _rwToast('فشل الاتصال', 'error');
            });
    };

    // ============================================================
    // QR compatibility function — preserved in contract
    // ============================================================

    function generateQRInvoiceBase64(sellerName, vatNumber, invoiceDate, totalAmount, vatAmount) {
        var text =
            (sellerName || '') + '\n' +
            (vatNumber || '') + '\n' +
            (invoiceDate || '') + '\n' +
            (totalAmount || '') + '\n' +
            (vatAmount || '');

        var utf8Bytes = [];

        for (var i = 0; i < text.length; i++) {
            var charCode = text.charCodeAt(i);

            if (charCode < 0x80) {
                utf8Bytes.push(charCode);
            } else if (charCode < 0x800) {
                utf8Bytes.push(0xc0 | (charCode >> 6));
                utf8Bytes.push(0x80 | (charCode & 0x3f));
            } else if (charCode < 0xd800 || charCode >= 0xe000) {
                utf8Bytes.push(0xe0 | (charCode >> 12));
                utf8Bytes.push(0x80 | ((charCode >> 6) & 0x3f));
                utf8Bytes.push(0x80 | (charCode & 0x3f));
            } else {
                i++;
                charCode =
                    0x10000 +
                    (((charCode & 0x3ff) << 10) |
                    (text.charCodeAt(i) & 0x3ff));

                utf8Bytes.push(0xf0 | (charCode >> 18));
                utf8Bytes.push(0x80 | ((charCode >> 12) & 0x3f));
                utf8Bytes.push(0x80 | ((charCode >> 6) & 0x3f));
                utf8Bytes.push(0x80 | (charCode & 0x3f));
            }
        }

        var binary = '';
        for (var j = 0; j < utf8Bytes.length; j++) {
            binary += String.fromCharCode(utf8Bytes[j]);
        }

        return btoa(binary);
    }

    window.generateQRInvoiceBase64 = generateQRInvoiceBase64;

    // ============================================================
    // Existing user-table event compatibility
    // ============================================================

    if (!window.__RAWAEA_MAIN11_USER_TABLE_CLICK_BOUND__) {
        window.__RAWAEA_MAIN11_USER_TABLE_CLICK_BOUND__ = true;

        document.addEventListener('click', function (event) {
            var target = event.target;

            while (target && target !== document.body) {
                var email = target.getAttribute && target.getAttribute('data-email');

                if (email) {
                    var wrapper = _rwById('emp-table-wrapper');

                    if (wrapper && wrapper.contains(target) &&
                        window.RW_Users &&
                        typeof window.RW_Users._openModal === 'function') {
                        window.RW_Users._openModal(email);
                        return;
                    }
                }

                target = target.parentNode;
            }
        });
    }

    // Forensic / governance marker. This is metadata only; it owns no business logic.
    window.__RAWAEA_MAIN11_GOVERNED_CLOSED_V2__ = true;

})();
