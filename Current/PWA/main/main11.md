// ============================================================
// RW_HR – الموارد البشرية (HR) - الوحدة المتقدمة
// ============================================================
var RW_HR = (function() {
    var hrData = [];

    function _esc(s) { return String(s || '').replace(/[&<>"']/g, function(m) { return m === '&' ? '&amp;' : m === '<' ? '&lt;' : m === '>' ? '&gt;' : m === '"' ? '&quot;' : '&#39;'; }); }
    function _fmtNum(n) { return Number(n || 0).toLocaleString(); }

    async function render() {
        var container = byId('rw-page-container');
        if (!container) return;

        var companyId = null;
        try {
            if (!window.RW_ShellContext || typeof RW_ShellContext.getCompanyId !== 'function') throw new Error('TENANT_CONTEXT_UNAVAILABLE');
            companyId = RW_ShellContext.getCompanyId();
            if (!companyId) throw new Error('TENANT_CONTEXT_EMPTY');
        } catch (e) {
            console.error('RW_HR tenant context', e);
            showToast('تعذر تحديد سياق الشركة الآمن', 'error');
            return;
        }

        safeText(byId('rw-header-title'), 'الموارد البشرية');
        safeText(byId('rw-header-subtitle'), 'إدارة ملفات الموظفين والرواتب والمستندات');
        showLoader('جاري تحميل بيانات الموظفين...');

        try {
            var res = await supabase
                .from('users')
                .select('id,company_id,name,email,role,status,phone,expiry_date,salary,allowances,deductions,auth_id,is_owner')
                .eq('company_id', companyId)
                .order('name', { ascending: true });
            if (res.error) throw res.error;
            hrData = res.data || [];
        } catch (e) {
            hrData = [];
            console.error('RW_HR.load', e);
            showToast('تعذر تحميل بيانات الموظفين', 'error');
        } finally {
            hideLoader();
        }

        if (hrData.length === 0) {
            safeHTML(container, '<div class="text-center py-10 text-gray-500">لا يوجد موظفون ضمن الشركة الحالية.</div>');
            return;
        }

        var html = '<div class="p-4"><div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6" id="hr-cards-container">';
        for (var i = 0; i < hrData.length; i++) {
            var emp = hrData[i];
            if (emp.is_owner === true || emp.role === 'مالك' || emp.role === 'Owner') continue;
            var statusClass = emp.status === 'Active' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700';
            var statusText = emp.status === 'Active' ? 'نشط' : 'غير نشط';
            var initials = (emp.name || '؟').charAt(0);
            var avatarColor = 'bg-blue-500';
            if (emp.role === 'مدير') avatarColor = 'bg-indigo-500';
            else if (emp.role === 'محاسب') avatarColor = 'bg-emerald-500';
            else if (emp.role === 'مندوب' || emp.role === 'سائق') avatarColor = 'bg-amber-500';
            else if (emp.role === 'مخزني') avatarColor = 'bg-purple-500';
            html += '<div class="bg-white rounded-2xl shadow-sm border p-6 hover:shadow-md transition cursor-pointer" onclick="RW_HR._openModal(\'' + _esc(emp.email) + '\')">';
            html += '<div class="flex items-center gap-4 mb-4"><div class="w-16 h-16 ' + avatarColor + ' rounded-2xl flex items-center justify-center text-white text-2xl font-black">' + _esc(initials) + '</div><div><h3 class="font-black text-lg text-gray-800">' + _esc(emp.name) + '</h3><p class="text-sm text-gray-500">' + _esc(emp.role) + '</p></div></div>';
            html += '<div class="space-y-2 text-sm"><div class="flex justify-between"><span class="text-gray-500">البريد:</span><span class="font-bold text-gray-700">' + _esc(emp.email) + '</span></div><div class="flex justify-between"><span class="text-gray-500">الهاتف:</span><span class="font-bold text-gray-700">' + _esc(emp.phone || '-') + '</span></div><div class="flex justify-between items-center"><span class="text-gray-500">الحالة:</span><span class="px-2 py-0.5 rounded-full text-xs font-bold ' + statusClass + '">' + statusText + '</span></div></div></div>';
        }
        html += '</div></div>';
        safeHTML(container, html);
    }

    function _openModal(email) {
        var emp = null;
        for (var i = 0; i < hrData.length; i++) {
            if (hrData[i].email === email) { emp = hrData[i]; break; }
        }
        if (!emp) { showToast('الموظف غير موجود', 'error'); return; }
        var html = '<div class="text-right space-y-6">';
        html += '<div class="bg-gray-50 p-4 rounded-xl"><h4 class="font-bold text-lg mb-3"><i class="fa-solid fa-user ml-2"></i>البيانات الأساسية</h4><div class="grid grid-cols-2 gap-4">';
        html += '<div><label class="text-xs text-gray-500">الاسم الكامل</label><p class="font-bold">' + _esc(emp.name) + '</p></div><div><label class="text-xs text-gray-500">البريد الإلكتروني</label><p class="font-bold">' + _esc(emp.email) + '</p></div><div><label class="text-xs text-gray-500">رقم الهاتف</label><p class="font-bold">' + _esc(emp.phone || '-') + '</p></div><div><label class="text-xs text-gray-500">الدور الوظيفي</label><p class="font-bold">' + _esc(emp.role) + '</p></div><div><label class="text-xs text-gray-500">الحالة</label><p class="font-bold">' + _esc(emp.status) + '</p></div><div><label class="text-xs text-gray-500">تاريخ انتهاء الصلاحية</label><p class="font-bold">' + _esc(emp.expiry_date || 'غير محدد') + '</p></div>';
        html += '</div></div><div class="bg-gray-50 p-4 rounded-xl"><h4 class="font-bold text-lg mb-3"><i class="fa-solid fa-money-bill-wave ml-2"></i>الراتب</h4><div class="grid grid-cols-2 gap-4">';
        html += '<div><label class="text-xs text-gray-500">الراتب الأساسي</label><p class="font-bold text-emerald-600">' + _fmtNum(emp.salary) + ' EGP</p></div><div><label class="text-xs text-gray-500">البدلات</label><p class="font-bold text-emerald-600">' + _fmtNum(emp.allowances) + ' EGP</p></div><div><label class="text-xs text-gray-500">الخصومات</label><p class="font-bold text-red-600">' + _fmtNum(emp.deductions) + ' EGP</p></div><div><label class="text-xs text-gray-500">الصافي</label><p class="font-bold text-blue-600">' + _fmtNum((Number(emp.salary) || 0) + (Number(emp.allowances) || 0) - (Number(emp.deductions) || 0)) + ' EGP</p></div>';
        html += '</div></div><div class="bg-gray-50 p-4 rounded-xl"><h4 class="font-bold text-lg mb-3"><i class="fa-solid fa-file-arrow-up ml-2"></i>المستندات</h4><div class="flex flex-wrap gap-4"><div class="border-2 border-dashed rounded-xl p-6 text-center w-40"><i class="fa-solid fa-id-card text-3xl text-gray-400"></i><p class="text-xs mt-2">صورة الهوية</p><p class="text-xs text-gray-400">(قيد التطوير)</p></div><div class="border-2 border-dashed rounded-xl p-6 text-center w-40"><i class="fa-solid fa-file-contract text-3xl text-gray-400"></i><p class="text-xs mt-2">عقد العمل</p><p class="text-xs text-gray-400">(قيد التطوير)</p></div></div></div></div>';
        Swal.fire({ title: 'ملف الموظف: ' + _esc(emp.name), html: html, width: '800px', showCloseButton: true, showConfirmButton: false });
    }
    return { render: render, _openModal: _openModal };
})();
window.RW_HR = RW_HR;

// ============================================================
// RW_CRM – إدارة علاقات العملاء (CRM)
// ============================================================
var RW_CRM = (function() {
    function _esc(s) { return String(s || '').replace(/[&<>"']/g, function(m) { return m === '&' ? '&amp;' : m === '<' ? '&lt;' : m === '>' ? '&gt;' : m === '"' ? '&quot;' : '&#39;'; }); }
    function _fmtNum(n) { return Number(n || 0).toLocaleString(); }
    function _dateFormat(d) { return d ? new Date(d).toLocaleDateString('ar-EG') : ''; }

    function _getCompanyId() {
        if (!window.RW_ShellContext || typeof RW_ShellContext.getCompanyId !== 'function') throw new Error('TENANT_CONTEXT_UNAVAILABLE');
        var companyId = RW_ShellContext.getCompanyId();
        if (!companyId) throw new Error('TENANT_CONTEXT_EMPTY');
        return companyId;
    }

    async function _resolveCustomer(customerCode) {
        var companyId = _getCompanyId();
        var res = await supabase.from('customers').select('id,company_id,customer_code,name,phone,area,debt').eq('company_id', companyId).eq('customer_code', customerCode).maybeSingle();
        if (res.error) throw res.error;
        return res.data || null;
    }

    async function render() {
        var container = byId('rw-page-container');
        if (!container) return;
        try { _getCompanyId(); } catch (e) { showToast('تعذر تحديد سياق الشركة الآمن', 'error'); return; }
        safeText(byId('rw-header-title'), 'إدارة علاقات العملاء (CRM)');
        safeText(byId('rw-header-subtitle'), 'سجل المتابعات والاتصالات بالعملاء');
        var customers = RW_STATE.data.customers || [];
        if (!customers.length) {
            try { customers = await RW_Data.loadCustomers(); } catch (e) { customers = []; }
        }
        safeHTML(container, '<div class="p-4"><div class="mb-4"><input type="text" id="crm-search" placeholder="🔍 بحث عن عميل..." class="w-full p-3 bg-white rounded-xl border" oninput="RW_CRM._filterCustomers()"></div><div class="bg-white rounded-2xl shadow-sm border overflow-y-auto" style="max-height:65vh" id="crm-customers-list">' + _buildCustomersTable(customers) + '</div></div>');
    }

    function _buildCustomersTable(customers) {
        if (!customers || !customers.length) return '<div class="text-center py-10 text-gray-500">لا يوجد عملاء</div>';
        var html = '<table class="w-full text-sm"><thead class="sticky top-0 bg-gray-50"><tr><th class="p-3">العميل</th><th class="p-3">الهاتف</th><th class="p-3">المنطقة</th><th class="p-3 text-center">الرصيد</th><th class="p-3 text-center">متابعة</th></tr></thead><tbody>';
        for (var i = 0; i < customers.length; i++) {
            var c = customers[i];
            var code = _esc(c.customer_code || '');
            var name = _esc(c.name || '');
            html += '<tr class="border-b hover:bg-gray-50 cursor-pointer" onclick="RW_CRM._openFollowupModal(\'' + code.replace(/\\/g,'\\\\').replace(/'/g,"\\'") + '\',\'' + name.replace(/\\/g,'\\\\').replace(/'/g,"\\'") + '\')">';
            html += '<td class="p-3"><div class="font-bold">' + name + '</div><div class="text-xs text-gray-400">' + code + '</div></td><td class="p-3">' + _esc(c.phone || '-') + '</td><td class="p-3">' + _esc(c.area || '-') + '</td><td class="p-3 text-center font-bold ' + (Number(c.debt) > 0 ? 'text-red-500' : 'text-green-600') + '">' + _fmtNum(c.debt) + ' EGP</td><td class="p-3 text-center"><button class="bg-blue-100 text-blue-700 px-3 py-1 rounded-lg text-xs font-bold"><i class="fa-solid fa-plus ml-1"></i> متابعة</button></td></tr>';
        }
        return html + '</tbody></table>';
    }

    function _filterCustomers() {
        var q = (byId('crm-search') ? byId('crm-search').value : '').toLowerCase();
        var customers = RW_STATE.data.customers || [];
        var filtered = q ? customers.filter(function(c) { return (c.name || '').toLowerCase().indexOf(q) !== -1 || (c.customer_code || '').toLowerCase().indexOf(q) !== -1 || String(c.phone || '').indexOf(q) !== -1; }) : customers;
        var list = byId('crm-customers-list');
        if (list) safeHTML(list, _buildCustomersTable(filtered));
    }

    async function _openFollowupModal(customerCode, customerName) {
        showLoader('جاري تحميل المتابعات...');
        try {
            var customer = await _resolveCustomer(customerCode);
            if (!customer) throw new Error('CUSTOMER_NOT_FOUND');
            var res = await supabase.from('customer_followups').select('*').eq('customer_id', customer.customer_code).order('followup_date', { ascending: false });
            if (res.error) throw res.error;
            var followups = res.data || [];
            var html = '<div class="text-right"><div class="bg-blue-50 p-4 rounded-xl mb-4"><h3 class="font-bold text-lg">' + _esc(customer.name || customerName) + '</h3><p class="text-sm text-gray-500">كود: ' + _esc(customer.customer_code) + '</p>';
            if (customer.phone) html += '<div class="flex gap-2 mt-3"><a href="tel:' + _esc(customer.phone) + '" class="bg-green-500 text-white px-4 py-2 rounded-lg text-xs font-bold"><i class="fa-solid fa-phone ml-1"></i> اتصال</a><a href="https://wa.me/' + _esc(String(customer.phone).replace(/\D/g,'')) + '" target="_blank" rel="noopener noreferrer" class="bg-emerald-500 text-white px-4 py-2 rounded-lg text-xs font-bold"><i class="fa-brands fa-whatsapp ml-1"></i> واتساب</a></div>';
            html += '</div><div class="bg-gray-50 p-4 rounded-xl mb-4"><h4 class="font-bold mb-3"><i class="fa-solid fa-plus-circle ml-1"></i> إضافة متابعة جديدة</h4><div class="grid grid-cols-1 md:grid-cols-3 gap-3 mb-3"><div><label class="text-xs">التاريخ</label><input type="date" id="crm-followup-date" class="p-2 bg-white border rounded w-full text-sm" value="' + new Date().toISOString().slice(0,10) + '"></div><div><label class="text-xs">نوع الاتصال</label><select id="crm-followup-type" class="p-2 bg-white border rounded w-full text-sm"><option>هاتف</option><option>واتساب</option><option>زيارة</option><option>بريد إلكتروني</option><option>أخرى</option></select></div><div><label class="text-xs">الحالة</label><select id="crm-followup-status" class="p-2 bg-white border rounded w-full text-sm"><option>معلقة</option><option>مكتملة</option><option>ملغاة</option></select></div></div><div><label class="text-xs">ملاحظات</label><textarea id="crm-followup-notes" class="p-2 bg-white border rounded w-full text-sm" rows="2" placeholder="تفاصيل المتابعة..."></textarea></div><div class="flex justify-end mt-3"><button id="btn-save-followup" class="bg-indigo-600 text-white px-6 py-2 rounded-lg font-bold text-sm">حفظ المتابعة</button></div></div><div><h4 class="font-bold mb-3"><i class="fa-solid fa-clock-rotate-left ml-1"></i> سجل المتابعات</h4>';
            if (followups.length) { html += '<div class="max-h-48 overflow-y-auto space-y-2">'; for (var f = 0; f < followups.length; f++) { var fw = followups[f]; var statusColor = fw.status === 'مكتملة' ? 'bg-green-100 text-green-700' : fw.status === 'ملغاة' ? 'bg-red-100 text-red-700' : 'bg-yellow-100 text-yellow-700'; html += '<div class="bg-white border rounded-lg p-3"><div class="flex justify-between items-start mb-1"><span class="font-bold text-sm">' + _esc(fw.followup_type) + '</span><span class="px-2 py-0.5 rounded-full text-xs font-bold ' + statusColor + '">' + _esc(fw.status) + '</span></div><p class="text-xs text-gray-500 mb-1">' + _dateFormat(fw.followup_date) + '</p><p class="text-sm">' + _esc(fw.notes || '-') + '</p></div>'; } html += '</div>'; } else html += '<div class="text-center py-4 text-gray-400">لا توجد متابعات سابقة</div>';
            html += '</div></div>';
            Swal.fire({ title: 'متابعة العميل: ' + _esc(customer.name || customerName), html: html, width: '800px', showCloseButton: true, showConfirmButton: false, didOpen: function() { var saveBtn = document.getElementById('btn-save-followup'); if (!saveBtn) return; saveBtn.addEventListener('click', async function() {
                var dateEl = document.getElementById('crm-followup-date'), typeEl = document.getElementById('crm-followup-type'), statusEl = document.getElementById('crm-followup-status'), notesEl = document.getElementById('crm-followup-notes');
                if (!dateEl || !typeEl || !statusEl || !notesEl) return;
                var payload = { customer_id: customer.customer_code, followup_date: dateEl.value, followup_type: typeEl.value, status: statusEl.value, notes: notesEl.value.trim(), created_by: RW_STATE.app.currentUser ? RW_STATE.app.currentUser.email : '' };
                if (!payload.followup_date) { showToast('يرجى تحديد التاريخ', 'warning'); return; }
                showLoader('جاري حفظ المتابعة...');
                try { var insertRes = await supabase.from('customer_followups').insert(payload); if (insertRes.error) throw insertRes.error; showToast('تم حفظ المتابعة', 'success'); Swal.close(); await _openFollowupModal(customer.customer_code, customer.name || customerName); } catch (e) { console.error('RW_CRM.saveFollowup', e); showToast('فشل حفظ المتابعة: ' + (e.message || 'خطأ غير معروف'), 'error'); } finally { hideLoader(); }
            }); } });
        } catch (e) { console.error('RW_CRM._openFollowupModal', e); showToast(e.message === 'CUSTOMER_NOT_FOUND' ? 'العميل غير موجود ضمن الشركة الحالية' : 'فشل تحميل المتابعات', 'error'); } finally { hideLoader(); }
    }
    return { render: render, _filterCustomers: _filterCustomers, _openFollowupModal: _openFollowupModal };
})();
window.RW_CRM = RW_CRM;

// ============================================================
// EVENTS & BOOT
// ============================================================
function bindEvents() {
    try {
        var loginForm = byId('rw-login-form');
        if (loginForm) loginForm.addEventListener('submit', function(e) { e.preventDefault(); RW_Auth.login(byId('rw-username').value, byId('rw-password').value); });
        var logoutBtn = byId('rw-logout-btn');
        if (logoutBtn) logoutBtn.addEventListener('click', function() { RW_Auth.logout(); });
        var mobileBtn = byId('rw-mobile-menu-btn');
        if (mobileBtn) mobileBtn.addEventListener('click', function() { var sidebar = byId('rw-sidebar'); if (sidebar) sidebar.classList.toggle('active'); });
        var collapseBtn = byId('rw-collapse-btn');
        if (collapseBtn) collapseBtn.addEventListener('click', function() { RW_Navigation.toggleSidebar(); });
    } catch (e) { console.error('bindEvents', e); }
}

function boot() {
    try {
        console.log('RAWAEA ERP BOOTING...');
        bindEvents();
        supabase.auth.getSession().then(function(res) {
            if (res.data && res.data.session) {
                console.log('✅ Session restored');
                var user = res.data.session.user;
                var meta = user.user_metadata || {};
                RW_STATE.app.authenticated = true;
                RW_STATE.app.currentUser = {
                    name: meta.name || user.email,
                    email: user.email,
                    authId: user.id,
                    id: null,
                    companyId: null,
                    role: meta.role || 'مدير النظام',
                    isOwner: meta.isOwner === true || meta.isOwner === 'true'
                };
                RW_STATE.permissions = Array.isArray(meta.permissions) ? meta.permissions.slice() : [];
                RW_STATE.app.company = { name: meta.companyName || 'الروائع ERP', logo: meta.companyLogo || 'ر' };
                RW_Auth.enterSystem().catch(function(e) { console.error('ENTER_SYSTEM_FAILED', e); });
            }
        }).catch(function(e) { console.error('SESSION_RESTORE_FAILED', e); });
        RW_STATE.app.initialized = true;
        try { if (localStorage.getItem('rw_sidebar_collapsed') === '1') setTimeout(function() { RW_Navigation.toggleSidebar(); }, 300); } catch (e) {}
        console.log('SYSTEM READY');
    } catch (e) {
        console.error(e);
        document.body.innerHTML = '<div style="min-height:100vh;display:flex;align-items:center;justify-content:center;flex-direction:column;font-family:Cairo;"><h1>RAWAEA ERP</h1><p>BOOT ERROR</p></div>';
    }
}
document.addEventListener('DOMContentLoaded', boot);

window.resetPassword = function() {
    var emailEl = byId('rw-username');
    var email = emailEl ? emailEl.value.trim() : '';
    if (!email) { showToast('يرجى إدخال بريدك الإلكتروني أولاً في حقل اسم المستخدم', 'warning'); return; }
    showLoader('جاري إرسال رابط إعادة التعيين...');
    supabase.auth.resetPasswordForEmail(email).then(function(res) { hideLoader(); if (res.error) showToast('فشل الإرسال: ' + res.error.message, 'error'); else showToast('تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني. راجع صندوق الوارد.', 'success'); }).catch(function(e) { hideLoader(); showToast('فشل الاتصال', 'error'); });
};

function generateQRInvoiceBase64(sellerName, vatNumber, invoiceDate, totalAmount, vatAmount) {
    var text = (sellerName || '') + '\n' + (vatNumber || '') + '\n' + (invoiceDate || '') + '\n' + (totalAmount || '') + '\n' + (vatAmount || '');
    var utf8Bytes = [];
    for (var i = 0; i < text.length; i++) {
        var charCode = text.charCodeAt(i);
        if (charCode < 0x80) utf8Bytes.push(charCode);
        else if (charCode < 0x800) { utf8Bytes.push(0xc0 | (charCode >> 6)); utf8Bytes.push(0x80 | (charCode & 0x3f)); }
        else if (charCode < 0xd800 || charCode >= 0xe000) { utf8Bytes.push(0xe0 | (charCode >> 12)); utf8Bytes.push(0x80 | ((charCode >> 6) & 0x3f)); utf8Bytes.push(0x80 | (charCode & 0x3f)); }
        else { i++; charCode = 0x10000 + (((charCode & 0x3ff) << 10) | (text.charCodeAt(i) & 0x3ff)); utf8Bytes.push(0xf0 | (charCode >> 18)); utf8Bytes.push(0x80 | ((charCode >> 12) & 0x3f)); utf8Bytes.push(0x80 | ((charCode >> 6) & 0x3f)); utf8Bytes.push(0x80 | (charCode & 0x3f)); }
    }
    var binary = '';
    for (var j = 0; j < utf8Bytes.length; j++) binary += String.fromCharCode(utf8Bytes[j]);
    return btoa(binary);
}

document.addEventListener('click', function(e) {
    var target = e.target;
    while (target && target !== document.body) {
        var email = target.getAttribute && target.getAttribute('data-email');
        if (email) {
            var wrapper = byId('emp-table-wrapper');
            if (wrapper && wrapper.contains(target)) { RW_Users._openModal(email); return; }
        }
        target = target.parentNode;
    }
});
})();
</script>
</body>
</html>