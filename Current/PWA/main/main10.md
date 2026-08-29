var RW_OwnerLicense = (function() {
    'use strict';

    function render() {
        var container = byId('rw-page-container');
        if (!container) return;
        safeText(byId('rw-header-title'), 'إدارة الترخيص');
        safeText(byId('rw-header-subtitle'), 'التحكم في حالة الشركة وبيانات المالك');
        safeHTML(container, '<div class="p-4 max-w-2xl mx-auto space-y-6" id="license-main-container"><div class="text-center py-10 text-gray-400"><i class="fa-solid fa-spinner fa-spin text-2xl"></i> جاري تحميل بيانات الترخيص...</div></div>');
        _loadLicenseData();
    }

    function _loadLicenseData() {
        supabase.from('app_settings').select('*').limit(1).single().then(function(res) {
            var s = res.data || {};
            _buildFullForm({ 
                licenseStatus: s.status || 'trial', 
                trialEndDate: s.trial_end_date || '', 
                subscriptionEndDate: s.subscription_end_date || '',
                ownerEmail: s.owner_email || ''
            });
        }).catch(function() {
            _buildFullForm({ licenseStatus: 'trial', trialEndDate: '', subscriptionEndDate: '', ownerEmail: '' });
        });
    }

    // ============================================================
// دالة togglePasswordVisibility المساعدة (توضع خارج أي دالة داخل RW_OwnerLicense)
// ============================================================
window.togglePasswordVisibility = function(inputId, btn) {
    var input = document.getElementById(inputId);
    if (!input) return;
    if (input.type === 'password') {
        input.type = 'text';
        btn.innerHTML = '<i class="fa-solid fa-eye-slash"></i>';
    } else {
        input.type = 'password';
        btn.innerHTML = '<i class="fa-solid fa-eye"></i>';
    }
}

// ============================================================
// دالة _buildFullForm المُعدَّلة
// ============================================================
function _buildFullForm(licenseInfo) {
    var container = byId('license-main-container');
    if (!container) return;

    // جلب البريد الإلكتروني الحالي
    var currentEmail = '';
    supabase.auth.getUser().then(function(userRes) {
        if (userRes.data && userRes.data.user) {
            currentEmail = userRes.data.user.email || '';
            var emailField = byId('owner-new-email');
            if (emailField) emailField.value = currentEmail;
        }
    });

    var html = '';
    // قسم الترخيص
    html += '<div class="bg-white rounded-2xl shadow-sm border p-6">';
    html += '<h3 class="text-lg font-black text-indigo-600 border-b pb-2 mb-4"><i class="fa-solid fa-shield-haltered ml-2"></i> إعدادات الترخيص</h3>';
    html += '<div class="space-y-4">';
    html += '<div class="flex flex-col"><label class="text-sm font-bold text-gray-700">حالة الشركة</label><select id="license-status" class="p-2.5 bg-gray-50 border rounded-lg">';
    html += '<option value="trial"' + (licenseInfo.licenseStatus === 'trial' ? ' selected' : '') + '>فترة تجربة</option>';
    html += '<option value="active"' + (licenseInfo.licenseStatus === 'active' ? ' selected' : '') + '>نشطة</option>';
    html += '<option value="suspended"' + (licenseInfo.licenseStatus === 'suspended' ? ' selected' : '') + '>موقوفة</option>';
    html += '<option value="cancelled"' + (licenseInfo.licenseStatus === 'cancelled' ? ' selected' : '') + '>ملغاة</option>';
    html += '</select></div>';
    html += '<div class="grid grid-cols-2 gap-4">';
    html += '<div><label class="text-sm font-bold">تاريخ انتهاء التجربة</label><input id="license-trial-end" type="date" value="' + (licenseInfo.trialEndDate || '') + '" class="p-2.5 bg-gray-50 border rounded-lg w-full"></div>';
    html += '<div><label class="text-sm font-bold">تاريخ انتهاء الاشتراك</label><input id="license-sub-end" type="date" value="' + (licenseInfo.subscriptionEndDate || '') + '" class="p-2.5 bg-gray-50 border rounded-lg w-full"></div>';
    html += '</div>';
    html += '<div class="flex justify-end pt-2"><button type="button" id="btn-save-license-only" class="px-6 py-2.5 bg-indigo-600 text-white rounded-xl font-bold shadow-md">حفظ إعدادات الترخيص</button></div>';
    html += '</div></div>';

    // قسم تغيير البريد الإلكتروني
    html += '<div class="bg-white rounded-2xl shadow-sm border p-6 mt-6">';
    html += '<h3 class="text-lg font-black text-blue-600 border-b pb-2 mb-4"><i class="fa-solid fa-envelope ml-2"></i> تغيير البريد الإلكتروني</h3>';
    html += '<div class="space-y-4">';
    html += '<div><label class="text-sm font-bold">البريد الإلكتروني الحالي</label><input id="owner-current-email" class="p-2.5 bg-gray-100 border rounded-lg w-full" readonly value="' + currentEmail + '"></div>';
    html += '<div><label class="text-sm font-bold">البريد الإلكتروني الجديد</label><input id="owner-new-email" type="email" class="p-2.5 bg-gray-50 border rounded-lg w-full" placeholder="أدخل البريد الإلكتروني الجديد"></div>';
    html += '<div class="flex justify-end pt-2"><button type="button" id="btn-change-email" class="px-6 py-2.5 bg-blue-600 text-white rounded-xl font-bold shadow-md">تغيير البريد الإلكتروني</button></div>';
    html += '</div></div>';

    // قسم تغيير كلمة المرور
    html += '<div class="bg-white rounded-2xl shadow-sm border p-6 mt-6">';
    html += '<h3 class="text-lg font-black text-red-600 border-b pb-2 mb-4"><i class="fa-solid fa-key ml-2"></i> تغيير كلمة المرور</h3>';
    html += '<div class="space-y-4">';
    html += '<div><label class="text-sm font-bold">كلمة المرور الجديدة</label>';
    html += '<div class="relative">';
    html += '<input id="owner-new-password" type="password" class="p-2.5 bg-gray-50 border rounded-lg w-full pl-12" placeholder="أدخل كلمة المرور الجديدة">';
    html += '<button type="button" onclick="window.togglePasswordVisibility(\'owner-new-password\', this)" class="absolute left-2 top-2.5 text-gray-500 hover:text-gray-700 p-1"><i class="fa-solid fa-eye"></i></button>';
    html += '</div></div>';
    html += '<div><label class="text-sm font-bold">تأكيد كلمة المرور الجديدة</label>';
    html += '<div class="relative">';
    html += '<input id="owner-confirm-password" type="password" class="p-2.5 bg-gray-50 border rounded-lg w-full pl-12" placeholder="أعد إدخال كلمة المرور الجديدة">';
    html += '<button type="button" onclick="window.togglePasswordVisibility(\'owner-confirm-password\', this)" class="absolute left-2 top-2.5 text-gray-500 hover:text-gray-700 p-1"><i class="fa-solid fa-eye"></i></button>';
    html += '</div></div>';
    html += '<div class="flex justify-end pt-2"><button type="button" id="btn-change-password" class="px-6 py-2.5 bg-red-600 text-white rounded-xl font-bold shadow-md">تغيير كلمة المرور</button></div>';
    html += '</div></div>';

    safeHTML(container, html);
    _bindSaveButtons();
}

function _bindSaveButtons() {
    // زر حفظ إعدادات الترخيص
    var btnLicense = byId('btn-save-license-only');
    if (btnLicense) {
        btnLicense.addEventListener('click', function() {
            var payload = {
                status: byId('license-status').value,
                trial_end_date: byId('license-trial-end').value || null,
                subscription_end_date: byId('license-sub-end').value || null
            };
            _saveSettings(payload, 'إعدادات الترخيص');
        });
    }

    // زر تغيير البريد الإلكتروني
    var btnEmail = byId('btn-change-email');
    if (btnEmail) {
        btnEmail.addEventListener('click', function() {
            var newEmail = byId('owner-new-email').value.trim();
            if (!newEmail) { showToast('أدخل البريد الإلكتروني الجديد', 'error'); return; }
            showLoader('جاري تغيير البريد الإلكتروني...');
            supabase.auth.updateUser({ email: newEmail }).then(function(res) {
                hideLoader();
                if (res.error) { showToast(res.error.message, 'error'); return; }
                showToast('تم تغيير البريد الإلكتروني بنجاح. تم إرسال رابط تأكيد إلى بريدك الجديد.', 'success');
                byId('owner-new-email').value = '';
                // تحديث البريد الحالي المعروض
                supabase.auth.getUser().then(function(userRes) {
                    if (userRes.data && userRes.data.user) {
                        byId('owner-current-email').value = userRes.data.user.email || '';
                    }
                });
            }).catch(function(e) {
                hideLoader();
                showToast('فشل الاتصال', 'error');
            });
        });
    }

    // زر تغيير كلمة المرور
    var btnPassword = byId('btn-change-password');
    if (btnPassword) {
        btnPassword.addEventListener('click', function() {
            var newPass = byId('owner-new-password').value;
            if (!newPass) { showToast('أدخل كلمة المرور الجديدة', 'error'); return; }
            showLoader('جاري تغيير كلمة المرور...');
            supabase.auth.updateUser({ password: newPass }).then(function(res) {
                hideLoader();
                if (res.error) { showToast(res.error.message, 'error'); return; }
                showToast('تم تغيير كلمة المرور بنجاح', 'success');
                byId('owner-new-password').value = '';
            }).catch(function(e) {
                hideLoader();
                showToast('فشل الاتصال', 'error');
            });
        });
    }
}

function _saveSettings(payload, label) {
    showLoader('جاري حفظ ' + (label || 'الإعدادات') + '...');
    
    supabase.auth.getSession().then(function(sessionRes) {
        var headers = { 'Content-Type': 'application/json' };
        if (sessionRes && sessionRes.data && sessionRes.data.session) {
            headers['Authorization'] = 'Bearer ' + sessionRes.data.session.access_token;
        }
        
        return fetch(RW_SUPABASE_URL + '/functions/v1/save-settings', {
            method: 'POST',
            headers: headers,
            body: JSON.stringify(payload)
        });
    }).then(function(res) {
        if (!res.ok) {
            return res.json().then(function(err) { throw new Error(err.error || 'خطأ في الخادم'); });
        }
        return res.json();
    }).then(function(json) {
        hideLoader();
        if (json.success) {
            showToast('تم حفظ ' + (label || 'الإعدادات') + ' بنجاح', 'success');
        } else {
            showToast(json.error || 'فشل حفظ ' + (label || 'الإعدادات'), 'error');
        }
    }).catch(function(e) {
        hideLoader();
        showToast('فشل الاتصال: ' + (e.message || 'خطأ غير معروف'), 'error');
        console.error(e);
    });
}

    return { render: render };
})();
window.RW_OwnerLicense = RW_OwnerLicense;
// ============================================================
// RW_Views – نظام التوجيه النهائي
// ============================================================
var RW_Views = {
    render: function(view) {
        var c = byId('rw-page-container');
        if (!c) return;

        // التحقق من الصلاحية
        var permissionMap = {
            'dashboard': 'dash',
            'items': 'items',
            'telesales': 'orders',
            'customers': 'customers',
            'suppliers': 'suppliers',
            'branches': 'branches',
            'pos': 'pos',
            'purchase-pos': 'purchases',
            'purchases': 'purchases',
            'orders': 'orders',
            'runsheets': 'runsheets',
            'online-store': 'online-store',
            'users': 'users',
            'roles': 'roles',
            'license': 'license',
            'settings': 'settings',
            'settlement': 'settlement',
            'receiving': 'receiving',
            'picking': 'picking',
            'loading': 'loading',
            'delivery': 'delivery',
            'return': 'return',
            'unloading': 'unloading',
            'vouchers': 'vouchers',
            'transfer': 'transfer',
            'direct-sale': 'direct-sale',
            'direct-return': 'direct-return',
            'supplier-return': 'supplier-return',
            'vehicle-count': 'vehicle-count',
            'branch-count': 'branch-count',
            'general-count': 'general-count',
            'reports-dashboard': 'reports',
            'reports-detailed': 'reports',
            'reports-comprehensive': 'reports',
            'audit-log': 'owner',
            'hr': 'users',
            'crm': 'customers'
        };

        var permKey = permissionMap[view];
        if (permKey === 'owner') {
            var isOwner = (RW_STATE.app.currentUser && RW_STATE.app.currentUser.isOwner === true);
            if (!isOwner) {
                safeHTML(c, '<div class="rw-card" style="text-align:center;padding:60px 20px"><div style="font-size:64px;margin-bottom:20px">🔒</div><h2>غير مصرح</h2><p>هذا التبويب مخصص للمالك فقط</p></div>');
                return;
            }
        } else if (permKey) {
            if (!RW_Permissions_check(permKey)) {
                safeHTML(c, '<div class="rw-card" style="text-align:center;padding:60px 20px"><div style="font-size:64px;margin-bottom:20px">🔒</div><h2>غير مصرح</h2><p>ليس لديك صلاحية الوصول إلى هذا التبويب</p></div>');
                return;
            }
        }

        var titles = {
            'dashboard':'لوحة التحكم','items':'الأصناف','customers':'العملاء','suppliers':'الموردين',
            'telesales':'التلي سيلز',
            'branches':'المخازن والفروع','pos':'نقطة البيع','purchase-pos':'نقطة شراء','purchases':'أوردرات الشراء',
            'orders':'أوردرات المبيعات','runsheets':'الرانشيتات','online-store':'المتجر الإلكتروني',
            'users':'المستخدمين والصلاحيات','roles':'إدارة أدوار المستخدمين','license':'إدارة الترخيص',
            'settings':'إعدادات النظام','settlement':'إغلاق اليومية','receiving':'الاستلام',
            'picking':'التحضير','loading':'التحميل','delivery':'التوصيل','return':'المرتجعات',
            'unloading':'التفريغ','vouchers':'الأذونات المخزنية','transfer':'تحويل مخزني',
            'direct-sale':'صرف سيارة بيع مباشر','direct-return':'استلام مرتجع سيارة',
            'supplier-return':'مرتجع لمورد','vehicle-count':'جرد سيارة','branch-count':'جرد فرع',
            'general-count':'جرد عام','reports-dashboard':'لوحة القيادة','reports-detailed':'التقارير التفصيلية',
            'audit-log':'سجل التدقيق'
        };
        safeText(byId('rw-header-title'), titles[view] || view);

        // استدعاء التبويب المناسب
        if (view === 'dashboard') { RW_Dashboard.render(); return; }
        if (view === 'items') { RW_Items.render(); return; }
        if (view === 'customers') { RW_Customers.render(); return; }
        if (view === 'suppliers') { RW_Suppliers.render(); return; }
        if (view === 'branches') { RW_Branches.render(); return; }
        if (view === 'settings') { RW_Settings.render(); return; }
        if (view === 'hr') { RW_HR.render(); return; }
        if (view === 'crm') { RW_CRM.render(); return; }
        if (view === 'users') { RW_Users.render(); return; }
        if (view === 'roles') { RW_Roles.render(); return; }
        if (view === 'license') { RW_OwnerLicense.render(); return; }
        if (view === 'telesales') { RW_TeleSales.render(); return; }
        if (view === 'pos') { RW_POS.render(); return; }
        if (view === 'orders') { RW_Orders.render(); return; }
        if (view === 'runsheets') { RW_Runsheets.render(); return; }
        if (view === 'online-store') { RW_OnlineStore.render(); return; }
        if (view === 'purchases') { RW_Purchases.renderOrders(); return; }
        if (view === 'purchase-pos') { RW_Purchases.renderPOS(); return; }
        if (view === 'picking') { RW_Warehouse.loadPicking(); return; }
        if (view === 'loading') { RW_Warehouse.loadLoading(); return; }
        if (view === 'delivery') { RW_Warehouse.loadDelivery(); return; }
        if (view === 'return') { RW_Warehouse.loadReturn(); return; }
        if (view === 'unloading') { RW_Warehouse.loadUnloading(); return; }
        if (view === 'receiving') { RW_Warehouse.loadReceiving(); return; }
        if (view === 'vouchers') { RW_Warehouse.loadVouchers(); return; }
        if (view === 'transfer') { RW_Warehouse.loadVoucherForm('Transfer'); return; }
        if (view === 'direct-sale') { RW_Warehouse.loadVoucherForm('DirectSale'); return; }
        if (view === 'direct-return') { RW_Warehouse.loadVoucherForm('DirectReturn'); return; }
        if (view === 'supplier-return') { RW_Warehouse.loadVoucherForm('SupplierReturn'); return; }
        if (view === 'vehicle-count') { RW_Warehouse.loadVehicleCount(); return; }
        if (view === 'branch-count') { RW_Warehouse.loadBranchCount(); return; }
        if (view === 'general-count') { RW_Warehouse.loadGeneralCount(); return; }
        if (view === 'settlement') { RW_Warehouse.loadSettlement(); return; }
        if (view === 'finance') { RW_Finance.render(); return; }
        if (view === 'reports-dashboard') { RW_Reports.renderDashboard(); return; }
        if (view === 'reports-detailed') { RW_Reports.renderDetailedReports(); return; }
        if (view === 'reports-comprehensive') { RW_Reports_Comprehensive.render(); return; }
        if (view === 'audit-log') { RW_Audit_renderTab(); return; }

        safeHTML(c, '<div class="rw-card" style="text-align:center;padding:60px 20px"><div style="font-size:64px;margin-bottom:20px">🚧</div><h2>' + (titles[view] || view) + '</h2><p style="color:#6b7280">قيد التطوير</p></div>');
    }
};
window.RW_Views = RW_Views;
