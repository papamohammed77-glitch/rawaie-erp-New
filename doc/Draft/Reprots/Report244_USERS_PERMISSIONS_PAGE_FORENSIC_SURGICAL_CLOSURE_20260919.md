# RAWAEA ERP — تقرير 244
## المستخدمون والصلاحيات — جراحة تحويل محرر المستخدم من Modal إلى Page
### التاريخ: 2026-09-19

## 1. نطاق الإغلاق

النطاق الوحيد في هذه الجلسة هو RW_Users / المستخدمون والصلاحيات.

لم يتم تعديل main.html في المستودع الأم بواسطة منفذ هذه الجلسة. تم إعداد Owner Surgical Change Set جاهز للاستبدال، مع تحديث السجلات في مستودع النظام فقط.

لا توجد Migration أو Edge Function جديدة مطلوبة لهذه الجراحة؛ Production الحالية توفر عقد الحفظ والحذف والصلاحيات والتعيينات اللازمة.

## 2. مصادر الحقيقة الحالية

Mother repository:
- HEAD: 189a2e082569144842bf793e9b3a439363078fdc
- Parent: 991b0290ce88c271540cc822d9849128fb1e2dd9
- Parent of parent: 6f37b88b19e11d2885cfd9b51cc3992d81b5ac47
- Current main.html blob: 60d61ad247b4172b79ded234b806d6b77c153e1b
- Current forensic extract: 26,367 lines.

System repository at session start:
- HEAD: bb0369f00e11f2b099762d9947e6b3e993fed095
- Parent: da03ad5e204bebe0cb584c2949a7b290d0c96deb

## 3. Production snapshot

- companies = 1
- users = 24
- active users = 24
- roles = 20
- active branches = 2
- audit_log = 1993
- users_without_role_id = 23
- dangling_role_id = 0
- cross_company_role_id = 0
- role_text_mismatch = 0

تمت مطابقة هذه الأرقام مع Production الحالية، ولم يتم عمل bulk backfill للـrole_id، لأن عدم وجود role_id في 23 سجلًا ليس دليلًا كافيًا على أن هذه البيانات يجب تغييرها.

حساب المالك الحالي:
- role = مدير النظام
- role_id صحيح
- permissions = ["*"]

لم يتم تغيير semantics الخاصة بالمالك.

## 4. Production security/deployment

تم التحقق من RLS الحالية على users وroles وcustomer_assignments، وهي Company-scoped.

تم التحقق من الـEdge deployments الحالية:

- save-employee v10 ACTIVE — f1ff0999d1e5bef8423ebeaff580e35d16da505134a09087054725bb89480e75
- save-role v9 ACTIVE — cd4eb540120d165da4f32465ac9825152d7360a703f0e9d2e2cec497b6ee67be
- delete-employee v4 ACTIVE — 7a2657afff27449026f8bef474e5c9c5f0f001345a1e205efda871f2db6206ae
- delete-role v4 ACTIVE — e9a3837b1df7d93f4447a88bf4f14846f7e6fdf04714699b89fa21adc8d8bd3

لا يوجد تعديل Production مطلوب لهذه الوحدة.

## 5. التحقيق الجنائي في المصدر الحالي

الملف:
companies/company-1/main.html

الوحدة:
RW_Users

الدالة الحالية:
function openModal(email)

الموضع الحالي:
يبدأ تقريبًا عند السطر 5457 وينتهي قبل return { الخاص بوحدة RW_Users.

العيوب المثبتة:

1. المحرر الحالي Modal وليس صفحة كاملة.
2. الفصل بين البيانات الأساسية والصلاحيات والإعدادات الميدانية والتعيينات ضعيف بصريًا.
3. الصلاحيات الموروثة من الدور والإضافات المباشرة لا تظهر كطبقتين واضحتين.
4. تغيير الدور لا يعيد بناء preview للصلاحيات داخل الواجهة.
5. توجد Heading مكررة داخل قسم إعدادات الميدان في النسخة الحالية.
6. هناك Search defect: filterTable يدعم الدور، بينما إعادة filtering داخل renderTable لا تضيف role إلى الشرط.
7. لا توجد User 360 page تجمع الهوية والنطاق والصلاحيات والتعيينات في مساحة واحدة.

## 6. التحقق التاريخي

التقرير 243 والتقارير السابقة استُخدمت لتحديد ما تم إغلاقه وما لا يجب تكراره.

تمت مطابقة أحدث Mother commits بدل الاعتماد على snapshot قديم.

Commit 991b0290 هو آخر commit سبق HEAD الحالي 189a2e08 مباشرة، وهو commit متعلق بإعادة هيكلة permissions داخل main.html.

وبالتالي فإن أي Owner edit يجب أن يُطبق على blob الحالي 60d61ad، وليس على النسخ الأقدم التي استُخدمت في تقارير 242 و243.

## 7. مقارنة المنافسين — ما الذي يثبت فائدته لهذه الجراحة

Odoo 19:
- user profile page.
- roles/groups.
- access rights.
- explicit permissions.
- inherited groups.
- record rules وCRUD على مستوى النماذج في الطبقة التقنية.

المصادر الرسمية:
https://www.odoo.com/documentation/19.0/applications/general/users/access_rights.html
https://www.odoo.com/documentation/19.0/developer/reference/backend/security.html

Dynamics 365 Business Central:
- Security Groups.
- Permission Sets.
- assignment إلى users/groups.
- company-specific permission assignment.

المصادر الرسمية:
https://learn.microsoft.com/en-us/dynamics365/business-central/ui-security-groups
https://learn.microsoft.com/en-us/dynamics365/business-central/application/system/table/system.security.accesscontrol.access-control

SAP Business One:
- Full Authorization.
- Read Only.
- No Authorization.
- child-level authorization.

المصدر الرسمي:
https://help.sap.com/docs/SAP_BUSINESS_ONE/2dc2e07e933b4dd5b93ab6405dcfb6af/3abee2ab057d456a8b5395073c63da18.html

Daftra:
- Employee/Role permissions.
- Accessible Branches.
- Restricted Pages.
- Login as Employee.

المصادر الرسمية:
https://docs.daftra.com/en/user_manual/employee-permissions-and-roles/
https://docs.daftra.com/en/faq/how-can-an-employee-be-restricted-from-accessing-certain-branches-on-the-system/
https://docs.daftra.com/en/tutorial/logging-in-as-an-employee/

Manager.io:
- User Permissions منفصلة في Settings.
- تحديد ما يستطيع restricted user رؤيته وفعله.

المصدر الرسمي:
https://www2.manager.io/guides/33078

القرار الهندسي:
نستخدم من هذه الأنماط ما يمكن إضافته داخل RW_Users الآن دون اختراع Authorization Engine جديد:
- صفحة User Profile بدل Modal.
- فصل inherited permissions عن direct permissions.
- إبراز branch scope.
- search داخل permissions.
- preview فعّال عند تغيير الدور.
- الحفاظ على عقد backend الحالي.

لا يتم الآن اختراع:
- CRUD matrix.
- record rules.
- field-level authorization.
- login-as/simulator.
- Security Groups مستقلة.
لأن هذه Business Contracts جديدة وليست إصلاح UI.

## 8. OWNER SURGICAL CHANGE SET — الجراحة الأولى

الملف:
companies/company-1/main.html

الدالة:
renderTable(data)

الموضع:
حوالي السطر 5367.

ابحث عن العنصر التالي حرفيًا:

    if ((emp.name||'').toLowerCase().indexOf(searchTerm) !== -1 || (emp.email||'').toLowerCase().indexOf(searchTerm) !== -1 || (emp.phone||'').toLowerCase().indexOf(searchTerm) !== -1) {

احذفه واستبدله بـ:

    if (
        (emp.name || '').toLowerCase().indexOf(searchTerm) !== -1 ||
        (emp.email || '').toLowerCase().indexOf(searchTerm) !== -1 ||
        (emp.phone || '').toLowerCase().indexOf(searchTerm) !== -1 ||
        (emp.role || '').toLowerCase().indexOf(searchTerm) !== -1
    ) {

لا تعدل بقية renderTable.

## 9. OWNER SURGICAL CHANGE SET — الجراحة الثانية

الملف:
companies/company-1/main.html

الوحدة:
RW_Users

العنصر الحالي:
function openModal(email) {

الموضع:
حوالي السطر 5457.

احذف الدالة كاملة، من بداية:

    function openModal(email) {

حتى آخر قوس لها، مباشرة قبل:

    return {

ثم استبدلها بالكامل بالدالة التالية:

    function openUserPage(email) {
    var container = byId('rw-page-container');
    if (!container) return;

    var emp = null;
    if (email) {
        for (var i = 0; i < employeesData.length; i++) {
            if (employeesData[i].email === email) {
                emp = employeesData[i];
                break;
            }
        }
    }

    var isEdit = !!emp;
    var title = isEdit ? 'تعديل بيانات المستخدم' : 'إضافة مستخدم جديد';

    function escPage(v) {
        return String(v == null ? '' : v)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    function normalizeList(value) {
        if (Array.isArray(value)) return value.slice();
        if (typeof value === 'string' && value.trim()) {
            try {
                var parsed = JSON.parse(value);
                if (Array.isArray(parsed)) return parsed;
            } catch (e) {}
            return value.split(',');
        }
        return [];
    }

    function contains(list, value) {
        return list.indexOf(value) !== -1;
    }

    var currentRole = null;
    if (emp && emp.role) {
        for (var ri = 0; ri < rolesList.length; ri++) {
            if (rolesList[ri].role_name === emp.role) {
                currentRole = rolesList[ri];
                break;
            }
        }
    }

    var currentRolePermissions = currentRole ? normalizeList(currentRole.permissions) : [];
    var existingPermissions = emp ? normalizeList(emp.permissions) : [];
    var knownPermissions = {};
    var permLabels = [
        { key: 'pos', label: 'نقطة البيع (POS)', group: 'apps' },
        { key: 'telesales', label: 'التلي سيلز', group: 'apps' },
        { key: 'orders', label: 'الأوردرات (مندوب المبيعات)', group: 'apps' },
        { key: 'van-sales', label: 'فان سيلز', group: 'apps' },
        { key: 'sales_supervisor', label: 'مشرف المبيعات', group: 'apps' },
        { key: 'warehouse_supervisor', label: 'مشرف المخازن', group: 'apps' },
        { key: 'warehouse', label: 'عمال المخازن', group: 'apps' },
        { key: 'delivery', label: 'مندوب التوصيل', group: 'apps' },
        { key: 'delivery_supervisor', label: 'مشرف التوصيل', group: 'apps' },
        { key: 'purchases', label: 'مسؤول المشتريات', group: 'apps' },
        { key: 'purchases_supervisor', label: 'مشرف المشتريات', group: 'apps' },
        { key: 'finance', label: 'المحاسب', group: 'apps' },
        { key: 'online-store', label: 'المتجر الإلكتروني', group: 'apps' },
        { key: 'sales_manager', label: 'مدير المبيعات', group: 'apps' },
        { key: 'warehouse_manager', label: 'مدير المخازن', group: 'apps' },
        { key: 'finance_manager', label: 'المدير المالي', group: 'apps' },
        { key: 'general_manager', label: 'المدير العام', group: 'apps' },
        { key: 'hr', label: 'الموارد البشرية', group: 'apps' },

        { key: 'dash', label: 'لوحة التحكم', group: 'erp' },
        { key: 'items', label: 'الأصناف والمخزون', group: 'erp' },
        { key: 'stock_adjustment', label: 'تحديث الأرصدة (تسوية)', group: 'erp' },
        { key: 'customers', label: 'العملاء', group: 'erp' },
        { key: 'suppliers', label: 'الموردين', group: 'erp' },
        { key: 'branches', label: 'الفروع والمخازن', group: 'erp' },
        { key: 'runsheets', label: 'الرانشيتات', group: 'erp' },
        { key: 'receiving', label: 'سجل الاستلام', group: 'erp' },
        { key: 'picking', label: 'سجل التحضير', group: 'erp' },
        { key: 'loading', label: 'سجل التحميل', group: 'erp' },
        { key: 'return', label: 'سجل المرتجعات', group: 'erp' },
        { key: 'unloading', label: 'سجل التفريغ', group: 'erp' },
        { key: 'vouchers', label: 'الأذونات المخزنية', group: 'erp' },
        { key: 'transfer', label: 'تحويل مخزني', group: 'erp' },
        { key: 'direct-sale', label: 'صرف سيارة بيع مباشر', group: 'erp' },
        { key: 'direct-return', label: 'استلام مرتجع سيارة', group: 'erp' },
        { key: 'supplier-return', label: 'مرتجع لمورد', group: 'erp' },
        { key: 'vehicle-count', label: 'جرد سيارة', group: 'erp' },
        { key: 'branch-count', label: 'جرد فرع', group: 'erp' },
        { key: 'general-count', label: 'جرد عام', group: 'erp' },
        { key: 'reports', label: 'التقارير', group: 'erp' },
        { key: 'users', label: 'المستخدمين والصلاحيات', group: 'erp' },
        { key: 'roles', label: 'إدارة الأدوار', group: 'erp' },
        { key: 'settings', label: 'إعدادات النظام', group: 'erp' },
        { key: 'settlement', label: 'إغلاق اليومية', group: 'erp' }
    ];

    for (var kp = 0; kp < permLabels.length; kp++) {
        knownPermissions[permLabels[kp].key] = true;
    }

    var directPermissions = [];
    for (var ep = 0; ep < existingPermissions.length; ep++) {
        var pKey = String(existingPermissions[ep]).trim();
        if (!pKey || pKey === '*') continue;
        if (!contains(currentRolePermissions, pKey)) {
            directPermissions.push(pKey);
        }
    }

    var unknownDirectPermissions = [];
    for (var udp = 0; udp < directPermissions.length; udp++) {
        if (!knownPermissions[directPermissions[udp]]) {
            unknownDirectPermissions.push(directPermissions[udp]);
        }
    }

    var roleOptions = '<option value="">اختر دوراً</option>';
    for (var r = 0; r < rolesList.length; r++) {
        var selectedRole = (emp && emp.role === rolesList[r].role_name) ? ' selected' : '';
        roleOptions += '<option value="' + escPage(rolesList[r].role_name) + '"' + selectedRole + '>' +
            escPage(rolesList[r].role_name) + '</option>';
    }
    if (!rolesList.length) {
        roleOptions = '<option value="">لا توجد أدوار متاحة</option>';
    }

    var branchOptions = '';
    var allowedBranches = emp ? normalizeList(emp.allowed_branch_ids) : [];
    if (allowedBranches.length === 1 && String(allowedBranches[0]).trim() === '*') {
        allowedBranches = ['*'];
    }

    var normalizedAllowedBranches = allowedBranches.map(function(x) {
        return String(x).trim();
    });

    for (var b = 0; b < branchesList.length; b++) {
        var br = branchesList[b];
        var code = br.branch_code || br.id || '';
        var name = br.name || br.branch_name || '';
        var branchSelected = '';
        if (contains(normalizedAllowedBranches, String(code).trim())) {
            branchSelected = ' selected';
        }
        branchOptions += '<option value="' + escPage(code) + '"' + branchSelected + '>' +
            escPage(name) + ' (' + escPage(code) + ')</option>';
    }

    function permissionBox(p) {
        var inherited = contains(currentRolePermissions, p.key);
        var direct = contains(directPermissions, p.key);
        var labelText = inherited && direct
            ? 'موروثة من الدور + مباشرة'
            : (inherited ? 'موروثة من الدور' : (direct ? 'مباشرة' : 'غير مفعلة'));
        var checked = inherited || direct;
        var editable = !inherited || direct;

        return '<label class="emp-perm-card flex items-start gap-3 p-3 rounded-2xl border ' +
            (inherited ? 'border-emerald-100 bg-emerald-50/60' : 'border-slate-200 bg-white hover:bg-slate-50') +
            ' cursor-pointer" data-perm-key="' + escPage(p.key) + '" data-perm-search="' +
            escPage(p.key + ' ' + p.label) + '">' +
            '<input type="checkbox" value="' + escPage(p.key) + '"' +
            (checked ? ' checked' : '') +
            (editable ? '' : ' disabled') +
            ' class="mt-1 w-4 h-4' + (editable ? ' emp-custom-perm' : '') + '" aria-label="' +
            escPage(p.label) + '">' +
            '<span class="min-w-0 flex-1">' +
            '<span class="block font-black text-sm text-slate-800">' + escPage(p.label) + '</span>' +
            '<span class="emp-perm-status block text-[11px] ' +
            (inherited ? 'text-emerald-700' : 'text-slate-500') +
            ' font-bold mt-1">' + labelText + '</span>' +
            '</span></label>';
    }

    var appsHTML = '';
    var erpHTML = '';
    for (var pi = 0; pi < permLabels.length; pi++) {
        if (permLabels[pi].group === 'apps') {
            appsHTML += permissionBox(permLabels[pi]);
        } else {
            erpHTML += permissionBox(permLabels[pi]);
        }
    }

    for (var up = 0; up < unknownDirectPermissions.length; up++) {
        appsHTML += '<label class="emp-perm-card flex items-start gap-3 p-3 rounded-2xl border border-amber-200 bg-amber-50 cursor-pointer" data-perm-key="' +
            escPage(unknownDirectPermissions[up]) + '" data-perm-search="' +
            escPage(unknownDirectPermissions[up] + ' صلاحية محفوظة') + '">' +
            '<input type="checkbox" value="' + escPage(unknownDirectPermissions[up]) + '" checked class="mt-1 w-4 h-4 emp-custom-perm" aria-label="' +
            escPage(unknownDirectPermissions[up]) + '">' +
            '<span class="min-w-0 flex-1">' +
            '<span class="block font-black text-sm text-amber-900">' + escPage(unknownDirectPermissions[up]) + '</span>' +
            '<span class="block text-[11px] text-amber-700 font-bold mt-1">صلاحية مباشرة محفوظة خارج الكتالوج الحالي — ستظل محفوظة ما لم تُلغَ يدويًا.</span>' +
            '</span></label>';
    }

    var roleCount = currentRolePermissions.filter(function(x) {
        return String(x).trim() && String(x).trim() !== '*';
    }).length;

    var directCount = directPermissions.length;
    var effectiveMap = {};
    for (var ec = 0; ec < currentRolePermissions.length; ec++) {
        var ek = String(currentRolePermissions[ec]).trim();
        if (ek && ek !== '*') effectiveMap[ek] = true;
    }
    for (var dc = 0; dc < directPermissions.length; dc++) {
        effectiveMap[directPermissions[dc]] = true;
    }
    var effectiveCount = Object.keys(effectiveMap).length;

    var empName = emp ? (emp.name || '') : '';
    var empEmail = emp ? (emp.email || '') : '';
    var empPhone = emp ? (emp.phone || '') : '';
    var empExpiry = emp ? (emp.expiry_date || '') : '';
    var allowAllCusts = emp ? !!emp.allow_all_customers : false;
    var restrictVisit = emp ? emp.restrict_to_visit_day !== false : true;
    var deviceIdVal = emp ? (emp.device_id || '') : '';
    var activeStatus = !emp || emp.status === 'Active';

    safeText(byId('rw-header-title'), title);
    safeText(
        byId('rw-header-subtitle'),
        isEdit
            ? 'إدارة كاملة لبيانات المستخدم وصلاحياته ونطاق وصوله من صفحة واحدة'
            : 'إنشاء مستخدم جديد مع الدور والصلاحيات ونطاق الوصول'
    );

    var html =
        '<div id="rw-user-page" class="max-w-[1600px] mx-auto p-4 md:p-6 space-y-5">' +

        '<div class="bg-gradient-to-br from-slate-900 via-indigo-900 to-blue-800 rounded-[32px] p-6 md:p-8 text-white shadow-xl">' +
            '<div class="flex flex-col xl:flex-row xl:items-center xl:justify-between gap-5">' +
                '<div class="flex items-start gap-4">' +
                    '<div class="w-16 h-16 md:w-20 md:h-20 rounded-3xl bg-white/10 border border-white/15 flex items-center justify-center text-3xl md:text-4xl font-black">' +
                        escPage((empName || 'م')[0]) +
                    '</div>' +
                    '<div class="min-w-0">' +
                        '<div class="text-xs md:text-sm text-indigo-200 font-black mb-1">RAWAEA ERP / المستخدمون والصلاحيات</div>' +
                        '<h2 class="text-2xl md:text-3xl font-black truncate">' + escPage(title) + '</h2>' +
                        '<p class="text-sm text-slate-200 mt-2">' +
                            escPage(emp ? ((emp.name || emp.email || '')) : 'إنشاء حساب جديد') +
                            (empEmail ? ' — ' + escPage(empEmail) : '') +
                        '</p>' +
                    '</div>' +
                '</div>' +
                '<div class="flex flex-wrap gap-2">' +
                    '<button type="button" id="btn-user-page-back" class="px-5 py-3 rounded-2xl bg-white/10 hover:bg-white/15 border border-white/15 font-black"><i class="fas fa-arrow-right ml-2"></i>العودة للمستخدمين</button>' +
                    (isEdit ? '<span class="px-5 py-3 rounded-2xl bg-white/10 border border-white/15 font-black">' + (activeStatus ? 'نشط' : 'غير نشط') + '</span>' : '') +
                '</div>' +
            '</div>' +
        '</div>' +

        '<div class="grid grid-cols-2 xl:grid-cols-4 gap-4">' +
            '<div class="bg-white rounded-2xl border border-slate-100 p-5 shadow-sm"><div class="text-xs text-slate-500 font-bold">الدور</div><div class="mt-2 font-black text-lg text-slate-800 truncate">' + escPage(emp && emp.role ? emp.role : 'غير محدد') + '</div></div>' +
            '<div class="bg-white rounded-2xl border border-slate-100 p-5 shadow-sm"><div class="text-xs text-slate-500 font-bold">صلاحيات الدور</div><div id="emp-role-perm-count" class="mt-2 font-black text-2xl text-emerald-700">' + roleCount + '</div></div>' +
            '<div class="bg-white rounded-2xl border border-slate-100 p-5 shadow-sm"><div class="text-xs text-slate-500 font-bold">إضافات مباشرة</div><div class="mt-2 font-black text-2xl text-indigo-700">' + directCount + '</div></div>' +
            '<div class="bg-white rounded-2xl border border-slate-100 p-5 shadow-sm"><div class="text-xs text-slate-500 font-bold">الإجمالي الفعّال</div><div id="emp-effective-count" class="mt-2 font-black text-2xl text-slate-800">' + effectiveCount + '</div></div>' +
        '</div>' +

        '<div class="sticky top-[96px] z-40 bg-white/95 backdrop-blur rounded-2xl border border-slate-100 shadow-sm p-2 overflow-x-auto">' +
            '<div class="flex gap-2 min-w-max">' +
                '<button type="button" onclick="RW_Users._switchEmpTab(\\'basic\\')" id="tab-basic" class="px-5 py-3 rounded-xl font-black text-sm border-b-2 border-blue-600 text-blue-600">البيانات الأساسية</button>' +
                '<button type="button" onclick="RW_Users._switchEmpTab(\\'perms\\')" id="tab-perms" class="px-5 py-3 rounded-xl font-black text-sm text-slate-500">الصلاحيات</button>' +
                '<button type="button" onclick="RW_Users._switchEmpTab(\\'field\\')" id="tab-field" class="px-5 py-3 rounded-xl font-black text-sm text-slate-500">إعدادات الميدان</button>' +
                (isEdit ? '<button type="button" onclick="RW_Users._switchEmpTab(\\'assignments\\')" id="tab-assignments" class="px-5 py-3 rounded-xl font-black text-sm text-slate-500">العملاء المسموحون</button>' : '') +
            '</div>' +
        '</div>' +

        '<section id="emp-panel-basic" class="space-y-5">' +
            '<div class="bg-white rounded-3xl border border-slate-100 shadow-sm overflow-hidden">' +
                '<div class="px-6 py-5 bg-slate-50 border-b"><h3 class="font-black text-xl text-slate-800">بيانات الحساب والهوية</h3><p class="text-xs text-slate-500 mt-1">البيانات التي تحدد الحساب ونطاقه الأساسي.</p></div>' +
                '<div class="p-6 grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4">' +
                    '<label class="block xl:col-span-2"><span class="block text-xs font-black text-slate-600 mb-2">الاسم الكامل *</span><input id="emp-name" value="' + escPage(empName) + '" class="w-full px-4 py-3 rounded-2xl border border-slate-200 bg-slate-50 focus:bg-white focus:outline-none focus:ring-2 focus:ring-indigo-200"></label>' +
                    '<label class="block xl:col-span-2"><span class="block text-xs font-black text-slate-600 mb-2">البريد الإلكتروني *</span><input id="emp-email" value="' + escPage(empEmail) + '" type="email" autocomplete="username" class="w-full px-4 py-3 rounded-2xl border border-slate-200 bg-slate-50 focus:bg-white focus:outline-none focus:ring-2 focus:ring-indigo-200"></label>' +
                    '<label class="block"><span class="block text-xs font-black text-slate-600 mb-2">رقم الهاتف</span><input id="emp-phone" value="' + escPage(empPhone) + '" inputmode="tel" class="w-full px-4 py-3 rounded-2xl border border-slate-200 bg-slate-50 focus:bg-white focus:outline-none focus:ring-2 focus:ring-indigo-200"></label>' +
                    '<label class="block"><span class="block text-xs font-black text-slate-600 mb-2">كلمة المرور</span><input id="emp-password" type="password" autocomplete="new-password" placeholder="' + escPage(isEdit ? 'اتركها فارغة للإبقاء على الحالية' : 'مطلوبة عند الإنشاء') + '" class="w-full px-4 py-3 rounded-2xl border border-slate-200 bg-slate-50 focus:bg-white focus:outline-none focus:ring-2 focus:ring-indigo-200"></label>' +
                    '<label class="block"><span class="block text-xs font-black text-slate-600 mb-2">الدور الوظيفي *</span><select id="emp-role" class="w-full px-4 py-3 rounded-2xl border border-slate-200 bg-slate-50 focus:bg-white focus:outline-none focus:ring-2 focus:ring-indigo-200">' + roleOptions + '</select></label>' +
                    '<label class="block"><span class="block text-xs font-black text-slate-600 mb-2">الحالة</span><select id="emp-status" class="w-full px-4 py-3 rounded-2xl border border-slate-200 bg-slate-50"><option value="Active"' + (activeStatus ? ' selected' : '') + '>نشط</option><option value="Inactive"' + (!activeStatus ? ' selected' : '') + '>غير نشط</option></select></label>' +
                    '<label class="block"><span class="block text-xs font-black text-slate-600 mb-2">تاريخ انتهاء الصلاحية</span><input id="emp-expiry" type="date" value="' + escPage(empExpiry) + '" class="w-full px-4 py-3 rounded-2xl border border-slate-200 bg-slate-50"></label>' +
                    '<div class="md:col-span-2 xl:col-span-4"><label class="block"><span class="block text-xs font-black text-slate-600 mb-2">الفروع المسموحة</span><select id="emp-branches" multiple class="w-full px-4 py-3 rounded-2xl border border-slate-200 bg-slate-50 min-h-[140px]">' + branchOptions + '</select><span class="block text-xs text-slate-500 mt-2">اتركه بدون اختيار للسماح بكل فروع الشركة.</span></label></div>' +
                '</div>' +
            '</div>' +
            '<div class="bg-blue-50/70 rounded-3xl border border-blue-100 p-6">' +
                '<div class="flex items-start gap-3"><div class="w-11 h-11 rounded-2xl bg-blue-600 text-white flex items-center justify-center"><i class="fas fa-layer-group"></i></div><div><h4 class="font-black text-blue-900">كيف تُبنى الصلاحية؟</h4><p class="text-sm text-blue-800/80 mt-1">الدور يحدد مجموعة الصلاحيات الموروثة، ويمكن إضافة صلاحيات مباشرة لهذا المستخدم. تغيير الدور يعيد تركيب الصلاحيات الفعالة وفق العقد الحالي.</p></div></div>' +
            '</div>' +
        '</section>' +

        '<section id="emp-panel-perms" class="hidden space-y-5">' +
            '<div class="bg-white rounded-3xl border border-slate-100 shadow-sm overflow-hidden">' +
                '<div class="px-6 py-5 bg-slate-50 border-b flex flex-col lg:flex-row lg:items-center lg:justify-between gap-3">' +
                    '<div><h3 class="font-black text-xl text-slate-800">الصلاحيات</h3><p class="text-xs text-slate-500 mt-1">الموروثة من الدور تظهر للقراءة فقط، والإضافات المباشرة قابلة للتعديل.</p></div>' +
                    '<input id="emp-permission-search" type="search" placeholder="بحث باسم الصلاحية أو المفتاح..." class="w-full lg:w-80 px-4 py-3 rounded-2xl border border-slate-200 bg-white">' +
                '</div>' +
                '<div class="p-6 space-y-6">' +
                    '<div class="flex flex-wrap gap-2 text-xs font-black">' +
                        '<span class="px-3 py-2 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-100">موروثة من الدور</span>' +
                        '<span class="px-3 py-2 rounded-full bg-white text-slate-600 border border-slate-200">مباشرة للمستخدم</span>' +
                        '<span class="px-3 py-2 rounded-full bg-amber-50 text-amber-800 border border-amber-200">محفوظة خارج الكتالوج</span>' +
                    '</div>' +
                    '<div>' +
                        '<div class="flex items-center justify-between mb-3"><h4 class="font-black text-lg">تطبيقات التشغيل</h4><span class="text-xs font-black text-slate-400">' + permLabels.filter(function(x){return x.group==='apps';}).length + ' صلاحية</span></div>' +
                        '<div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-3">' + appsHTML + '</div>' +
                    '</div>' +
                    '<div>' +
                        '<div class="flex items-center justify-between mb-3"><h4 class="font-black text-lg">النظام الأم</h4><span class="text-xs font-black text-slate-400">' + permLabels.filter(function(x){return x.group==='erp';}).length + ' صلاحية</span></div>' +
                        '<div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-3">' + erpHTML + '</div>' +
                    '</div>' +
                '</div>' +
            '</div>' +
        '</section>' +

        '<section id="emp-panel-field" class="hidden space-y-5">' +
            '<div class="bg-white rounded-3xl border border-slate-100 shadow-sm overflow-hidden">' +
                '<div class="px-6 py-5 bg-amber-50 border-b border-amber-100"><h3 class="font-black text-xl text-amber-900">إعدادات الميدان</h3><p class="text-xs text-amber-800/70 mt-1">قواعد نطاق الوصول الميداني والجهاز المرتبط بالمستخدم.</p></div>' +
                '<div class="p-6 grid grid-cols-1 xl:grid-cols-2 gap-5">' +
                    '<label class="flex items-start gap-4 p-5 rounded-3xl border border-slate-200 bg-slate-50/70 cursor-pointer"><input type="checkbox" id="emp-allow-all-customers"' + (allowAllCusts ? ' checked' : '') + ' class="mt-1 w-5 h-5"><span><span class="block font-black text-base">السماح برؤية جميع العملاء</span><span class="block text-sm text-slate-500 mt-1">يتجاوز قيود التعيين ويتيح للمندوب رؤية جميع العملاء المسموح بهم ضمن الشركة.</span></span></label>' +
                    '<label class="flex items-start gap-4 p-5 rounded-3xl border border-slate-200 bg-slate-50/70 cursor-pointer"><input type="checkbox" id="emp-restrict-visit-day"' + (restrictVisit ? ' checked' : '') + ' class="mt-1 w-5 h-5"><span><span class="block font-black text-base">تقييد العملاء بيوم الزيارة</span><span class="block text-sm text-slate-500 mt-1">عند التفعيل يُراعى يوم زيارة العميل في الوصول الميداني.</span></span></label>' +
                    '<label class="block xl:col-span-2"><span class="block text-xs font-black text-slate-600 mb-2">معرف الجهاز</span><input id="emp-device-id" value="' + escPage(deviceIdVal) + '" class="w-full px-4 py-3 rounded-2xl border border-slate-200 bg-slate-50"><span class="block text-xs text-slate-500 mt-2">يبقى متاحًا للإدارة للمراقبة والربط، ويُملأ تلقائيًا عند استخدام التطبيق عندما يكون ذلك مدعومًا.</span></label>' +
                '</div>' +
            '</div>' +
        '</section>' +

        (isEdit ?
        '<section id="emp-panel-assignments" class="hidden space-y-5">' +
            '<div class="bg-white rounded-3xl border border-slate-100 shadow-sm overflow-hidden">' +
                '<div class="px-6 py-5 bg-sky-50 border-b border-sky-100"><h3 class="font-black text-xl text-sky-900">العملاء المسموحون</h3><p class="text-xs text-sky-800/70 mt-1">تعيينات مستقلة عن صلاحيات التطبيقات، وتخضع لنفس Company Scope في Production.</p></div>' +
                '<div class="p-6 space-y-5">' +
                    '<input type="text" id="assignment-search" oninput="RW_Users._searchAssignmentCustomers(this.value)" placeholder="ابحث بالاسم أو كود العميل..." class="w-full px-4 py-3 rounded-2xl border border-slate-200 bg-slate-50">' +
                    '<div id="assignment-results" class="min-h-[120px] max-h-72 overflow-y-auto rounded-2xl border bg-slate-50 p-3"><div class="text-center text-slate-400 text-sm py-8">ابدأ بالبحث عن عميل</div></div>' +
                    '<div><h4 class="font-black text-base text-slate-800 mb-3">التعيينات الحالية</h4><div id="assigned-customers-list" class="min-h-[120px] max-h-72 overflow-y-auto rounded-2xl border bg-white p-3"><div class="text-center text-slate-400 text-sm py-8">جاري التحميل...</div></div></div>' +
                    '<div class="p-4 rounded-2xl bg-slate-50 border border-slate-100 text-xs text-slate-500">عند تفعيل «السماح برؤية جميع العملاء» يتم تجاهل قائمة التعيينات عند العرض التشغيلي.</div>' +
                '</div>' +
            '</div>' +
        '</section>' : '') +

        '<div class="sticky bottom-0 z-40 bg-white/95 backdrop-blur border border-slate-100 rounded-3xl shadow-2xl p-4">' +
            '<div class="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-3">' +
                '<div class="text-xs text-slate-500 font-bold">المستخدم • ' + escPage(empEmail || 'حساب جديد') + '</div>' +
                '<div class="flex flex-wrap gap-2">' +
                    (isEdit ? '<button type="button" id="btn-delete-emp" class="px-5 py-3 bg-rose-600 hover:bg-rose-700 text-white rounded-2xl font-black"><i class="fas fa-user-slash ml-2"></i>تعطيل المستخدم</button>' : '') +
                    '<button type="button" id="btn-user-page-cancel" class="px-5 py-3 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-2xl font-black">إلغاء</button>' +
                    '<button type="button" id="btn-save-emp" class="px-7 py-3 bg-indigo-600 hover:bg-indigo-700 text-white rounded-2xl font-black shadow-lg">حفظ المستخدم</button>' +
                '</div>' +
            '</div>' +
        '</div>' +
        '</div>';

    safeHTML(container, html);

    var backBtn = byId('btn-user-page-back');
    if (backBtn) {
        backBtn.onclick = function() {
            render();
        };
    }

    var cancelBtn = byId('btn-user-page-cancel');
    if (cancelBtn) {
        cancelBtn.onclick = function() {
            render();
        };
    }

    var permissionSearch = byId('emp-permission-search');
    if (permissionSearch) {
        permissionSearch.addEventListener('input', function() {
            var q = String(permissionSearch.value || '').trim().toLowerCase();
            var cards = document.querySelectorAll('#emp-panel-perms .emp-perm-card');
            for (var ci = 0; ci < cards.length; ci++) {
                var hay = String(cards[ci].getAttribute('data-perm-search') || '').toLowerCase();
                cards[ci].style.display = !q || hay.indexOf(q) !== -1 ? '' : 'none';
            }
        });
    }

    function syncRolePermissionPreview() {
        var roleEl = byId('emp-role');
        if (!roleEl) return;

        var selectedRole = null;
        for (var sri = 0; sri < rolesList.length; sri++) {
            if (rolesList[sri].role_name === roleEl.value) {
                selectedRole = rolesList[sri];
                break;
            }
        }

        var selectedRolePermissions = selectedRole ? normalizeList(selectedRole.permissions) : [];
        var cards = document.querySelectorAll('#emp-panel-perms .emp-perm-card');

        for (var sci = 0; sci < cards.length; sci++) {
            var card = cards[sci];
            var key = String(card.getAttribute('data-perm-key') || '');
            var input = card.querySelector('input');
            var status = card.querySelector('.emp-perm-status');
            if (!input) continue;

            var inherited = contains(selectedRolePermissions, key);
            var direct = contains(directPermissions, key);
            var effective = inherited || direct;

            input.checked = effective;
            input.classList.toggle('emp-custom-perm', !inherited || direct);
            input.disabled = inherited && !direct;

            card.classList.toggle('border-emerald-100', inherited);
            card.classList.toggle('bg-emerald-50/60', inherited);
            card.classList.toggle('border-slate-200', !inherited);
            card.classList.toggle('bg-white', !inherited);

            if (status) {
                status.textContent = inherited && direct
                    ? 'موروثة من الدور + مباشرة'
                    : (inherited ? 'موروثة من الدور' : (direct ? 'مباشرة' : 'غير مفعلة'));
                status.classList.toggle('text-emerald-700', inherited);
                status.classList.toggle('text-slate-500', !inherited);
            }
        }

        var map = {};
        for (var rpi = 0; rpi < selectedRolePermissions.length; rpi++) {
            var rk = String(selectedRolePermissions[rpi]).trim();
            if (rk && rk !== '*') map[rk] = true;
        }
        for (var dpi = 0; dpi < directPermissions.length; dpi++) {
            var dk = String(directPermissions[dpi]).trim();
            if (dk && dk !== '*') map[dk] = true;
        }

        var roleCountEl = byId('emp-role-perm-count');
        var effectiveCountEl = byId('emp-effective-count');

        if (roleCountEl) {
            roleCountEl.textContent = selectedRolePermissions.filter(function(x) {
                return String(x).trim() && String(x).trim() !== '*';
            }).length;
        }

        if (effectiveCountEl) {
            effectiveCountEl.textContent = Object.keys(map).length;
        }
    }

    var roleSelect = byId('emp-role');
    if (roleSelect) {
        roleSelect.addEventListener('change', syncRolePermissionPreview);
    }

    var saveBtn = byId('btn-save-emp');
    if (saveBtn) {
        saveBtn.addEventListener('click', async function() {
            if (saveBtn.disabled) return;

            var sel = byId('emp-branches');
            var selectedBranches = [];
            if (sel) {
                for (var s = 0; s < sel.options.length; s++) {
                    if (sel.options[s].selected) selectedBranches.push(sel.options[s].value);
                }
            }

            var nameInput = byId('emp-name');
            var emailInput = byId('emp-email');
            var name = nameInput ? nameInput.value.trim() : '';
            var emailVal = emailInput ? emailInput.value.trim() : '';
            if (!name || !emailVal) {
                showToast('الاسم والبريد مطلوبان', 'error');
                return;
            }

            var passInput = byId('emp-password');
            var passValue = (passInput && passInput.value) ? passInput.value : '';
            if (!isEdit && !passValue) {
                showToast('يجب تعيين كلمة مرور عند إنشاء مستخدم جديد', 'error');
                return;
            }

            var customPerms = [];
            var checkboxes = document.querySelectorAll('.emp-custom-perm:checked');
            for (var cp = 0; cp < checkboxes.length; cp++) {
                var value = String(checkboxes[cp].value || '').trim();
                if (value && customPerms.indexOf(value) === -1) customPerms.push(value);
            }

            var payload = {
                name: name,
                email: emailVal,
                phone: byId('emp-phone') ? byId('emp-phone').value.trim() : '',
                password: passValue || null,
                role: byId('emp-role') ? byId('emp-role').value : '',
                status: byId('emp-status') ? byId('emp-status').value : 'Active',
                expiry_date: byId('emp-expiry') ? byId('emp-expiry').value : '',
                allowed_branch_ids: selectedBranches,
                permissions: customPerms,
                allow_all_customers: byId('emp-allow-all-customers') ? byId('emp-allow-all-customers').checked : false,
                restrict_to_visit_day: byId('emp-restrict-visit-day') ? byId('emp-restrict-visit-day').checked : true,
                device_id: byId('emp-device-id') ? byId('emp-device-id').value.trim() : ''
            };

            saveBtn.disabled = true;
            saveBtn.classList.add('opacity-60', 'cursor-not-allowed');
            showLoader('جاري حفظ المستخدم...');

            try {
                var sessionRes = await supabase.auth.getSession();
                var token = sessionRes && sessionRes.data && sessionRes.data.session
                    ? sessionRes.data.session.access_token
                    : null;

                if (!token) throw new Error('جلسة غير صالحة');

                var res = await fetch(
                    RW_SUPABASE_URL + '/functions/v1/save-employee',
                    {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            Authorization: 'Bearer ' + token
                        },
                        body: JSON.stringify({
                            employee: payload,
                            isEdit: isEdit,
                            originalEmail: emp ? emp.email : ''
                        })
                    }
                );

                var json = await res.json();
                if (!json || !json.success) {
                    throw new Error((json && (json.error || json.msg)) || 'فشل حفظ المستخدم');
                }

                hideLoader();
                showToast(isEdit ? 'تم تحديث المستخدم بنجاح' : 'تم إنشاء المستخدم بنجاح', 'success');
                await render();
            } catch (e) {
                hideLoader();
                saveBtn.disabled = false;
                saveBtn.classList.remove('opacity-60', 'cursor-not-allowed');
                showToast(e.message || 'فشل الاتصال بـ Edge Function', 'error');
            }
        });
    }

    if (isEdit) {
        var deleteBtn = byId('btn-delete-emp');
        if (deleteBtn) {
            deleteBtn.addEventListener('click', async function() {
                var confirmResult = await Swal.fire({
                    title: 'تأكيد تعطيل المستخدم',
                    text: 'سيتم تعطيل المستخدم ومنع دخوله مع الاحتفاظ بسجله التاريخي. هل تريد المتابعة؟',
                    icon: 'warning',
                    showCancelButton: true,
                    confirmButtonText: 'تعطيل المستخدم',
                    cancelButtonText: 'إلغاء'
                });

                if (!confirmResult.isConfirmed) return;

                deleteBtn.disabled = true;
                deleteBtn.classList.add('opacity-60', 'cursor-not-allowed');
                showLoader('جاري تعطيل المستخدم...');

                try {
                    var sessionRes = await supabase.auth.getSession();
                    var token = sessionRes && sessionRes.data && sessionRes.data.session
                        ? sessionRes.data.session.access_token
                        : null;

                    if (!token) throw new Error('جلسة غير صالحة');

                    var res = await fetch(
                        RW_SUPABASE_URL + '/functions/v1/delete-employee',
                        {
                            method: 'POST',
                            headers: {
                                'Content-Type': 'application/json',
                                Authorization: 'Bearer ' + token
                            },
                            body: JSON.stringify({ email: emp.email })
                        }
                    );

                    var json = await res.json();
                    if (!json || !json.success) {
                        throw new Error((json && (json.error || json.msg)) || 'فشل تعطيل المستخدم');
                    }

                    hideLoader();
                    showToast('تم تعطيل المستخدم', 'success');
                    await render();
                } catch (e) {
                    hideLoader();
                    deleteBtn.disabled = false;
                    deleteBtn.classList.remove('opacity-60', 'cursor-not-allowed');
                    showToast(e.message || 'فشل الاتصال بـ Edge Function', 'error');
                }
            });
        }

        window._currentEmpEmail = emp.email;
        window._assignmentCustomers = [];
        window._assignedCustomerIds = [];

        supabase.from('customer_assignments')
            .select('customer_id, customers!inner(customer_code, name, area, phone)')
            .eq('user_id', emp.id)
            .eq('is_active', true)
            .then(function(res) {
                if (res && res.error) throw res.error;
                window._assignedCustomerIds = (res.data || []).map(function(a) { return a.customer_id; });
                _renderAssignedCustomersList(res.data || []);
            })
            .catch(function(e) {
                console.error('فشل تحميل تعيينات العملاء:', e);
                var list = byId('assigned-customers-list');
                if (list) safeHTML(list, '<div class="text-center text-rose-600 text-sm py-8">تعذر تحميل التعيينات الحالية</div>');
            });
    }

    container.scrollTop = 0;
}

هذه الجراحة تستبدل Modal بمحرر User 360 كامل داخل rw-page-container.

## 10. OWNER SURGICAL CHANGE SET — الجراحة الثالثة

في نفس RW_Users ابحث عن:

    _openModal: openModal,

احذف هذا السطر واستبدله بـ:

    _openModal: openUserPage,

لا تحذف _switchEmpTab.

لا تعدل الـglobal click handler الموجود في نهاية main.html؛ فهو يستدعي _openModal، وبعد الجراحة سيقود إلى الصفحة الجديدة.

## 11. وظائف الصفحة الجديدة

الصفحة الجديدة تحتوي على:

### البيانات الأساسية
- الاسم.
- البريد.
- الهاتف.
- كلمة المرور.
- الدور.
- الحالة.
- تاريخ الانتهاء.
- الفروع المسموحة.

### الصلاحيات
قسم تطبيقات التشغيل وقسم النظام الأم.

تظهر الصلاحيات الموروثة من الدور كقراءة فقط.

تظهر الإضافات المباشرة قابلة للتعديل.

توجد Permission Search.

يُعاد بناء preview للصلاحيات عند تغيير الدور.

### إعدادات الميدان
- السماح بجميع العملاء.
- تقييد بيوم الزيارة.
- Device ID.

### العملاء المسموحون
الحفاظ على customer_assignments الحالية مع نفس Company Scope.

### Actions
- العودة للمستخدمين.
- إلغاء.
- حفظ.
- تعطيل المستخدم.

يتم منع double-submit أثناء الحفظ والتعطيل.

## 12. نقطة حرجة في الحفاظ على البيانات

save-employee الحالي لا يخزن direct permissions وحدها؛ بل يبني permissions من:

role.permissions + requestedPermissions

لذلك الصفحة تحسب direct permissions الحالية على أنها permissions الحالية ناقص صلاحيات الدور الحالي، وهو نفس العقد الذي يجب الحفاظ عليه.

كما أن replacement يعرض أي permission محفوظة مباشرة ولا توجد في catalog الحالي على أنها صلاحية محفوظة خارج الكتالوج، ولا يسقطها بصمت عند الحفظ.

لا يتم تحويل OWNER wildcard إلى قائمة صريحة.

## 13. لماذا لم يتم تغيير Production

لم يظهر في التحقيق أي نقص Production ضروري لإتمام page editor.

الـbackend الحالي يدعم:
- role resolution.
- permission merge.
- branch normalization/validation.
- user update/create.
- auth synchronization.
- deactivate.
- audit.

إضافة backend الآن ستخلق تغييرًا غير لازم في Business Contract.

الحالة الصحيحة:
PRODUCTION VERIFIED — NO CHANGE REQUIRED.

## 14. ما تم إصلاحه دون تكرار إصلاحات سابقة

- الاعتماد على current Mother blob 60d61ad بدل snapshots قديمة.
- إزالة duplicate field heading ضمن replacement.
- فصل inherited/direct permissions بصريًا.
- role-change preview.
- حفظ unknown direct permissions.
- تحويل editor إلى page.
- إصلاح role search داخل renderTable.
- الحفاظ على applications الحالية.
- الحفاظ على ERP permissions الحالية، بما فيها items وstock_adjustment.
- الحفاظ على customer assignments.
- الحفاظ على Edge API contracts.
- الحفاظ على OWNER semantics.

## 15. التحقق الفني الحالي

JavaScript syntax:
PASS.

Production database verification:
PASS.

Production RLS verification:
PASS.

Edge deployment verification:
PASS.

Mother current source verification:
PASS.

Browser E2E:
NOT RUN.

لا يتم تسجيل Browser E2E كنجاح قبل تنفيذ page فعليًا على Production في المتصفح.

## 16. Business Contract gaps التي يجب عدم تزوير إغلاقها

ما يزال خارج نطاق هذه الجراحة:

1. CRUD per object/action.
2. Record rules.
3. Field-level security.
4. Login-as / Permission Simulator.
5. Device/session security center الكامل.
6. Security Groups متعددة العضوية.
7. SAP-style Full/Read Only/None matrix.

هذه نقاط تصميم/بنية مستقلة، وليست مجرد نقص في modal.

## 17. تعريف Done لهذه الوحدة

بعد تطبيق Owner Surgery:

- فتح RW_Users يعرض القائمة.
- الضغط على المستخدم يفتح Page وليس Modal.
- إضافة مستخدم تفتح نفس Page في create mode.
- البحث يعمل بالاسم والبريد والهاتف والدور.
- الدور يغيّر inherited preview فورًا.
- direct permissions تبقى قابلة للتعديل.
- branch scope محفوظ.
- customer assignments محفوظة.
- save يمر عبر save-employee.
- deactivate يمر عبر delete-employee.
- owner لا يتحول إلى permissions صريحة.
- الصفحة تعود للقائمة بعد الحفظ/التعطيل.
- لا يتم تعديل أي Operational App أو Stock Engine.

## 18. حالة الإغلاق

Current status:
OWNER SURGICAL CHANGE SET READY

Production:
VERIFIED — NO CHANGE REQUIRED

Mother main.html:
NOT MODIFIED BY CTO

Runtime:
NOT BROWSER VERIFIED

Final status:
NOT 100% CLOSED until owner applies the 3 surgical edits and Browser E2E passes.

## 19. تعليمات بداية الجلسة التالية

لا تبدأ من التقارير القديمة.

ابدأ بالترتيب:

CURRENT_STATE.md

ثم current System HEAD

ثم current Mother HEAD

ثم current main.html blob

ثم ابحث عن RW_Users

ثم تحقق أن openUserPage موجودة بدل openModal

ثم تحقق من _openModal: openUserPage

ثم تحقق من renderTable role search

ثم Production users/roles/RLS

ثم save-employee v10

ثم delete-employee v4

ثم Browser E2E.

بعد إثبات ذلك فقط أغلق RW_Users Page Surgery.

أي مساعد لاحق ممنوع أن يعيد تنفيذ backend closures التي ثبتت هنا.

## End of Report 244
