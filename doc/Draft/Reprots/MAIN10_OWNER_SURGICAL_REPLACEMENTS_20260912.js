/*
 * RAWAEA ERP — MAIN10 OWNER SURGICAL REPLACEMENTS
 * Date: 2026-09-12
 * Source of Truth: Current/PWA/main2/main10.md
 *
 * IMPORTANT:
 * - Do NOT edit Current/PWA/main10 in this package.
 * - Owner applies the replacements manually to the exact source fragment.
 * - Production changes: none required for Main10 findings in this cycle.
 */

const MAIN10_OWNER_SURGICAL_REPLACEMENTS_20260912 = {
  source: 'Current/PWA/main2/main10.md',
  source_sha_before_apply: '169025a6836c7fdc7281ea86523b975a84d889f1',
  replacements: [
    {
      id: 'M10-O1',
      title: 'إزالة القيم الافتراضية المضللة عند غياب Company Context',
      location: 'داخل _loadLicenseData() — الكتلة التي تبدأ بـ if (!companyId) {',
      action: 'احذف الكتلة الحالية كاملة واستبدلها بالكتلة التالية:',
      replacement: `if (!companyId) {
    safeHTML(byId('license-main-container'), '<div class="rw-card" style="text-align:center;padding:40px 20px"><div style="font-size:48px;margin-bottom:16px">⚠️</div><h3>تعذر تحديد سياق الشركة</h3><p style="color:#6b7280;margin-top:8px">لا يمكن تحميل بيانات الترخيص دون Company Context صالح.</p></div>');
    return;
}`
    },
    {
      id: 'M10-O2',
      title: 'استبدال _buildFullForm بالكامل',
      location: 'Current/PWA/main2/main10.md — السطور 102–163، الدالة function _buildFullForm(licenseInfo)',
      action: 'احذف الدالة كاملة من السطر الذي يبدأ بـ function _buildFullForm(licenseInfo) { حتى القوس } الذي يسبق function _bindSaveButtons() مباشرة، واستبدلها كاملة بالتالي:',
      replacement: `function _buildFullForm(licenseInfo) {
    var container = byId('license-main-container');
    if (!container) return;

    var currentEmail = String((licenseInfo && licenseInfo.ownerEmail) || '').trim();

    var html = '';

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

    html += '<div class="bg-white rounded-2xl shadow-sm border p-6 mt-6">';
    html += '<h3 class="text-lg font-black text-blue-600 border-b pb-2 mb-4"><i class="fa-solid fa-envelope ml-2"></i> تغيير البريد الإلكتروني</h3>';
    html += '<div class="space-y-4">';
    html += '<div><label class="text-sm font-bold">البريد الإلكتروني الحالي</label><input id="owner-current-email" class="p-2.5 bg-gray-100 border rounded-lg w-full" readonly value="' + currentEmail + '"></div>';
    html += '<div><label class="text-sm font-bold">البريد الإلكتروني الجديد</label><input id="owner-new-email" type="email" class="p-2.5 bg-gray-50 border rounded-lg w-full" placeholder="أدخل البريد الإلكتروني الجديد"></div>';
    html += '<div class="flex justify-end pt-2"><button type="button" id="btn-change-email" class="px-6 py-2.5 bg-blue-600 text-white rounded-xl font-bold shadow-md">تغيير البريد الإلكتروني</button></div>';
    html += '</div></div>';

    html += '<div class="bg-white rounded-2xl shadow-sm border p-6 mt-6">';
    html += '<h3 class="text-lg font-black text-red-600 border-b pb-2 mb-4"><i class="fa-solid fa-key ml-2"></i> تغيير كلمة المرور</h3>';
    html += '<div class="space-y-4">';
    html += '<div><label class="text-sm font-bold">كلمة المرور الجديدة</label>';
    html += '<div class="relative">';
    html += '<input id="owner-new-password" type="password" class="p-2.5 bg-gray-50 border rounded-lg w-full pl-12" placeholder="أدخل كلمة المرور الجديدة">';
    html += '<button type="button" onclick="window.togglePasswordVisibility(\\'owner-new-password\\', this)" class="absolute left-2 top-2.5 text-gray-500 hover:text-gray-700 p-1"><i class="fa-solid fa-eye"></i></button>';
    html += '</div></div>';
    html += '<div><label class="text-sm font-bold">تأكيد كلمة المرور الجديدة</label>';
    html += '<div class="relative">';
    html += '<input id="owner-confirm-password" type="password" class="p-2.5 bg-gray-50 border rounded-lg w-full pl-12" placeholder="أعد إدخال كلمة المرور الجديدة">';
    html += '<button type="button" onclick="window.togglePasswordVisibility(\\'owner-confirm-password\\', this)" class="absolute left-2 top-2.5 text-gray-500 hover:text-gray-700 p-1"><i class="fa-solid fa-eye"></i></button>';
    html += '</div></div>';
    html += '<div class="flex justify-end pt-2"><button type="button" id="btn-change-password" class="px-6 py-2.5 bg-red-600 text-white rounded-xl font-bold shadow-md">تغيير كلمة المرور</button></div>';
    html += '</div></div>';

    safeHTML(container, html);

    supabase.auth.getUser().then(function(userRes) {
        if (userRes.data && userRes.data.user) {
            var authenticatedEmail = userRes.data.user.email || currentEmail;
            var currentEmailField = byId('owner-current-email');
            if (currentEmailField) currentEmailField.value = authenticatedEmail;
        }
    }).catch(function(error) {
        console.error('RW_OwnerLicense._buildFullForm.getUser', error);
    });

    _bindSaveButtons();
}`
    },
    {
      id: 'M10-O3',
      title: 'استبدال _bindSaveButtons بالكامل',
      location: 'Current/PWA/main2/main10.md — الدالة function _bindSaveButtons() التي تبدأ بعد _buildFullForm مباشرة',
      action: 'احذف الدالة كاملة حتى القوس } الذي يسبق function _saveSettings(payload, label) مباشرة، واستبدلها كاملة بالتالي:',
      replacement: `function _bindSaveButtons() {
    var btnLicense = byId('btn-save-license-only');
    if (btnLicense) {
        btnLicense.addEventListener('click', function() {
            var statusField = byId('license-status');
            var trialEndField = byId('license-trial-end');
            var subEndField = byId('license-sub-end');
            if (!statusField || !trialEndField || !subEndField) return;

            var payload = {
                status: statusField.value,
                trial_end_date: trialEndField.value || null,
                subscription_end_date: subEndField.value || null
            };
            _saveSettings(payload, 'إعدادات الترخيص');
        });
    }

    var btnEmail = byId('btn-change-email');
    if (btnEmail) {
        btnEmail.addEventListener('click', function() {
            var emailField = byId('owner-new-email');
            if (!emailField) return;

            var newEmail = emailField.value.trim();
            if (!newEmail) {
                showToast('أدخل البريد الإلكتروني الجديد', 'error');
                return;
            }

            var emailPattern = /^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$/;
            if (!emailPattern.test(newEmail)) {
                showToast('أدخل بريدًا إلكترونيًا صالحًا', 'error');
                return;
            }

            showLoader('جاري تغيير البريد الإلكتروني...');
            supabase.auth.updateUser({ email: newEmail }).then(function(res) {
                hideLoader();
                if (res.error) {
                    showToast(res.error.message, 'error');
                    return;
                }
                showToast('تم إرسال رابط التأكيد إلى البريد الإلكتروني الجديد', 'success');
                emailField.value = '';
            }).catch(function(e) {
                hideLoader();
                showToast('فشل الاتصال', 'error');
                console.error('RW_OwnerLicense.changeEmail', e);
            });
        });
    }

    var btnPassword = byId('btn-change-password');
    if (btnPassword) {
        btnPassword.addEventListener('click', function() {
            var passwordField = byId('owner-new-password');
            var confirmField = byId('owner-confirm-password');
            if (!passwordField || !confirmField) return;

            var newPass = passwordField.value;
            var confirmPass = confirmField.value;

            if (!newPass) {
                showToast('أدخل كلمة المرور الجديدة', 'error');
                return;
            }

            if (!confirmPass) {
                showToast('أدخل تأكيد كلمة المرور الجديدة', 'error');
                return;
            }

            if (newPass !== confirmPass) {
                showToast('كلمة المرور وتأكيدها غير متطابقين', 'error');
                return;
            }

            showLoader('جاري تغيير كلمة المرور...');
            supabase.auth.updateUser({ password: newPass }).then(function(res) {
                hideLoader();
                if (res.error) {
                    showToast(res.error.message, 'error');
                    return;
                }
                showToast('تم تغيير كلمة المرور بنجاح', 'success');
                passwordField.value = '';
                confirmField.value = '';
            }).catch(function(e) {
                hideLoader();
                showToast('فشل الاتصال', 'error');
                console.error('RW_OwnerLicense.changePassword', e);
            });
        });
    }
}`
    },
    {
      id: 'M10-O4',
      title: 'استبدال RW_Views بالكامل',
      location: 'Current/PWA/main2/main10.md — السطور 262–400، من var RW_Views = { حتى window.RW_Views = RW_Views;',
      action: 'احذف RW_Views بالكامل حتى آخر سطر window.RW_Views = RW_Views; واستبدله كاملًا بالتالي:',
      replacement: `var RW_Views = {
    render: function(view) {
        var c = byId('rw-page-container');
        if (!c) return;

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
            'finance': 'finance',
            'reports-dashboard': 'reports',
            'reports-detailed': 'reports',
            'reports-comprehensive': 'reports',
            'audit-log': 'owner',
            'hr': 'hr',
            'crm': 'customers'
        };

        var permKey = permissionMap[view];

        if (permKey === 'owner') {
            var currentUser = (typeof RW_STATE !== 'undefined' && RW_STATE && RW_STATE.app && RW_STATE.app.currentUser)
                ? RW_STATE.app.currentUser
                : null;
            var isOwner = currentUser && currentUser.isOwner === true;
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
            'dashboard':'لوحة التحكم',
            'items':'الأصناف',
            'customers':'العملاء',
            'suppliers':'الموردين',
            'telesales':'التلي سيلز',
            'branches':'المخازن والفروع',
            'pos':'نقطة البيع',
            'purchase-pos':'نقطة شراء',
            'purchases':'أوردرات الشراء',
            'orders':'أوردرات المبيعات',
            'runsheets':'الرانشيتات',
            'online-store':'المتجر الإلكتروني',
            'users':'المستخدمين والصلاحيات',
            'roles':'إدارة أدوار المستخدمين',
            'license':'إدارة الترخيص',
            'settings':'إعدادات النظام',
            'settlement':'إغلاق اليومية',
            'receiving':'الاستلام',
            'picking':'التحضير',
            'loading':'التحميل',
            'delivery':'التوصيل',
            'return':'المرتجعات',
            'unloading':'التفريغ',
            'vouchers':'الأذونات المخزنية',
            'transfer':'تحويل مخزني',
            'direct-sale':'صرف سيارة بيع مباشر',
            'direct-return':'استلام مرتجع سيارة',
            'supplier-return':'مرتجع لمورد',
            'vehicle-count':'جرد سيارة',
            'branch-count':'جرد فرع',
            'general-count':'جرد عام',
            'finance':'الإدارة المالية',
            'reports-dashboard':'لوحة القيادة',
            'reports-detailed':'التقارير التفصيلية',
            'reports-comprehensive':'التقارير الشاملة',
            'audit-log':'سجل التدقيق',
            'hr':'الموارد البشرية',
            'crm':'إدارة علاقات العملاء'
        };
        safeText(byId('rw-header-title'), titles[view] || view);

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

        safeHTML(c, '<div class="rw-card" style="text-align:center;padding:60px 20px"><div style="font-size:64px;margin-bottom:20px">⚠️</div><h2>' + (titles[view] || view) + '</h2><p style="color:#6b7280">التبويب غير معروف</p></div>');
    }
};
window.RW_Views = RW_Views;`
    }
  ]
};

/*
 * Owner execution checklist:
 * 1) M10-O1: exact if (!companyId) block in _loadLicenseData.
 * 2) M10-O2: replace full _buildFullForm only.
 * 3) M10-O3: replace full _bindSaveButtons only.
 * 4) M10-O4: replace full RW_Views only.
 * 5) Do not edit function _saveSettings unless new evidence appears.
 * 6) Do not edit other Main fragments.
 */
