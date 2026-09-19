# تقرير 248 — RW_Roles إدارة أدوار المستخدمين — تحقيق جنائي وإغلاق جراحي

**التاريخ:** 2026-09-19  
**النطاق الوحيد:** \`RW_Roles — إدارة أدوار المستخدمين\`  
**قاعدة التنفيذ:** لا تعديل لـ \`main.html\` بواسطة CTO؛ تعديلات Production اللازمة نُفذت مباشرة.

---

# 1. الحالة الحاكمة قبل التنفيذ

تمت إعادة بناء الحالة من المصادر الحالية، ولم يُعتمد على CURRENT_STATE أو التقارير السابقة كحالة حالية.

## Governance

تم فتح الملف كاملًا:

\`doc/Draft/Reprots/MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md\`

الحجم: **29,578 حرفًا / 2,606 سطرًا**.

القواعد المؤثرة:
- Reports = Historical Evidence فقط.
- Current Truth = Current Git + Current Source + Current Production + Current Database + Current Deployment Evidence.
- الدراسة تسبق التعديل.
- لا افتراض.
- لا إعادة إصلاح لما ثبت إغلاقه.
- لا إنشاء محرك صلاحيات ثانٍ.
- Owner Source Changes تبقى Owner-managed.
- Production Changes اللازمة ينفذها CTO مباشرة.
- لا يُعتبر وجود Screen أو Function أو Deployment إغلاقًا وظيفيًا.

## CURRENT_STATE

تم فتح \`CURRENT_STATE.md\` ومقارنة حالته مع Git الحالي. ثبت أن أعلى الحالة القديمة تخص RW_Users وليست RW_Roles، وأن أرقام Mother فيها أصبحت تاريخية.

---

# 2. Current Git — Mother

Repository:

\`papamohammed77-glitch/erp-frontend\`

## Current HEAD

\`e08652c3a6cb1d1768a04685cec437aa2d8b04c9\`

Parent:

\`3bc57c23fe334691514c633cad7d1599d776d54a\`

الـHEAD الحالي لا يغير \`main.html\`.

## آخر Commit غيّر main.html فعليًا

\`3bc57c23fe334691514c633cad7d1599d776d54a\`

Parent:

\`845c9f1bb0e879252c4450fc173acac960f82c51\`

هذا التغيير متعلق بإغلاق قوس RW_Users، وليس RW_Roles.

## Current main.html blob

\`ca40fd6c6f43797e096e338177280d22ac4fa436\`

**لم يتم تعديل \`main.html\` من CTO.**

---

# 3. آخر تاريخ مثبت لـ RW_Roles

الـcommit:

\`e2ab4cf203d7790859081133016ca3bdc56e92e9\`

Message:

\`Refactor role modal HTML and event handling\`

الـdiff أثبت إعادة تنظيم الـModal ولم يحوله إلى Page.

Current source ما زال يحتوي:

\`\`\`javascript
function openModal(roleId) {
\`\`\`

ويستخدم:

\`\`\`javascript
Swal.fire(...)
\`\`\`

والـAPI:

\`\`\`javascript
return { render: render, _openModal: openModal, _switchRoleTab: _switchRoleTab };
\`\`\`

إذن بقاء الـModal حقيقة Current Source.

---

# 4. Production — Current Role Reality

Supabase project:

\`fiilmooggumokxanwiyx\`

## Counts

- \`roles = 20\`
- \`system_roles = 3\`
- \`custom_roles = 17\`
- \`users = 24\`
- \`users_without_role_id = 1\`
- \`broken_role_refs = 0\`
- \`duplicate lower role names = 0\`

## User without role_id

\`\`\`
email: mostafa@rawaea.com
name: mostafa.ali
role: موظف
role_id: NULL
\`\`\`

ولا يوجد Production role باسم \`موظف\`.

**لم يتم إصلاحه آليًا** لأن اختيار Role آخر سيكون افتراضًا غير مثبت.

## Role usage

Production تثبت استخدامًا فعليًا للأدوار:
- مندوب توصيل = 4 مستخدمين نشطين.
- مخزني = 5 مستخدمين نشطين.
- أدوار أخرى مستخدمة أيضًا.

إذن Role Impact عنصر تشغيلي فعلي.

---

# 5. Production Schema / Security

## roles schema

- \`id uuid\`
- \`company_id uuid\`
- \`role_name varchar\`
- \`description text\`
- \`is_system boolean\`
- \`permissions jsonb\`
- \`created_at timestamptz\`
- \`updated_at timestamptz\`

## Constraints

\`\`\`
roles_company_id_role_name_key UNIQUE(company_id, role_name)
roles_company_id_fkey
roles_pkey
\`\`\`

## RLS

السياسات الحالية:
- \`roles_select_company_permission\`
- \`roles_insert_company_permission\`
- \`roles_update_company_permission\`
- \`roles_delete_company_permission\`

وتتحقق من:
\`app_private.current_user_company_id()\`
و:
\`app_private.current_user_has_permission('roles')\`

Tenant Boundary موجود.

---

# 6. Production Edge Contract

تم التحقق من:

- \`save-role v9 ACTIVE / verify_jwt=true\`
- \`delete-role v4 ACTIVE / verify_jwt=true\`
- \`seed-roles v4 ACTIVE / verify_jwt=true\`

## save-role

يحافظ على:
- JWT authentication.
- company من المستخدم المصادق عليه.
- roles permission guard.
- OWNER wildcard protection.
- role company scope.
- member role propagation.
- user permission synchronization.
- audit logging.
- حماية Rename للدور المرتبط بمستخدمين نشطين.

## delete-role

يحافظ على:
- JWT authentication.
- company scope.
- roles permission guard.
- منع حذف system role.
- منع حذف الدور المرتبط بمستخدمين نشطين.
- audit logging.

**قرار:** إعادة استخدام العقود الحالية وعدم إنشاء Backend Role Engine جديد.

---

# 7. Forensic Root Cause

السبب الجذري الحالي هو بقاء RW_Roles على **Legacy Role Editor Contract** داخل Modal بينما RW_Users أصبحت Page.

هذا ينتج:
- Role editor أقل نضجًا.
- عدم وجود Role 360.
- عدم وجود member impact.
- عدم وجود search/filter.
- عدم وجود responsive list.
- عدم وجود audit viewer داخل Profile.
- عدم وجود clone workflow.

هذه فجوة Capability حقيقية.

---

# 8. Competitive Benchmark

تمت مراجعة الأنماط الرسمية الحالية:

## Odoo
Groups / Access Rights، مع Read / Write / Create / Unlink وRecord Rules في طبقة الأمن.

## Dynamics 365 Business Central
Security Groups وPermission Sets وربط المستخدمين والصلاحيات مع الشركة.

## SAP
Business Roles + Business Catalogs + Restrictions، مع صفحات مستقلة لإدارة Business Roles وBusiness Users.

## Daftra
Employee Roles + Accessible Branches + Restricted Pages + Login-as.

## Manager.io
User Permissions بمستويات متعددة + Restricted User / Impersonate patterns.

## القرار الهندسي

تم أخذ ما يمكن إضافته الآن دون إنشاء Authorization Contract جديد:
- Page بدل Modal.
- Role Profile.
- Search / Filters.
- Permission grouping.
- Usage / Impact.
- Members.
- Audit history.
- Clone.
- Responsive UX.

ولم يتم اختراع:
- CRUD Matrix.
- Record Rules.
- Field-Level Permissions.
- Login-as / Simulator.
- Security Groups Engine جديد.

هذه Business Contracts مستقلة لاحقًا.

---

# 9. Production Infrastructure — تم التنفيذ

Migration:

\`role_management_audit_visibility_and_timestamp_20260919\`

## updated_at automation

Function:

\`public.touch_roles_updated_at()\`

Trigger:

\`trg_roles_updated_at\`

Production test منفصل أثبت تحديث \`updated_at\` عند UPDATE، ثم تم حذف سجل الاختبار.

## Audit visibility

تم إنشاء:

\`audit_log_select_role_managers\`

وتقيد رؤية Role audit بـ:
- table_name = roles.
- permission = roles.
- company_id من old_data/new_data يطابق company context.

## Performance

تم إنشاء:

\`idx_audit_log_roles_record_created\`

على:

\`audit_log(record_id, created_at DESC)\`

مع شرط \`table_name='roles'\`.

لا جدول جديد.

---

# 10. OWNER SURGICAL CHANGESET

> نفّذ هذه الجراحة فقط في Mother. لا تعدل \`main.html\` خارجها.

## SURGERY A — rolesData + usersData + helper

**File:** \`companies/company-1/main.html\`  
**Module:** \`RW_Roles\`

ابحث حرفيًا عن:

\`\`\`javascript
    var rolesData = [];
\`\`\`

احذفه واستبدله بـ:

\`\`\`javascript
    var rolesData = [];
    var usersData = [];

    function roleEsc(v) {
        return String(v == null ? '' : v)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }
\`\`\`

---

# SURGERY B — render()

داخل RW_Roles ابحث عن:

\`\`\`javascript
    async function render() {
\`\`\`

واحذف الدالة كاملة حتى بداية:

\`\`\`javascript
    function renderTable(data) {
\`\`\`

استبدلها بالكامل بـ:

\`\`\`javascript
    async function render() {
        var container = byId('rw-page-container');
        if (!container) return;

        var companyId = _rwCompanyId();
        if (!companyId) {
            safeText(byId('rw-header-title'), 'إدارة أدوار المستخدمين');
            safeText(byId('rw-header-subtitle'), 'تعذر تحديد سياق الشركة الحالية');
            safeHTML(container, '<div class="p-8 text-center bg-white rounded-3xl border border-rose-100 text-rose-700 font-black">سياق الشركة غير محدد.</div>');
            return;
        }

        safeText(byId('rw-header-title'), 'إدارة أدوار المستخدمين');
        safeText(byId('rw-header-subtitle'), 'إدارة مركزية للأدوار والصلاحيات وتأثيرها على المستخدمين');

        safeHTML(container,
            '<div id="rw-roles-page" class="max-w-[1700px] mx-auto p-4 md:p-6 space-y-5" dir="rtl">' +
                '<div class="bg-gradient-to-br from-slate-950 via-indigo-950 to-blue-900 rounded-[32px] p-6 md:p-8 text-white shadow-2xl"><div class="flex flex-col xl:flex-row xl:items-center xl:justify-between gap-6"><div><div class="text-xs md:text-sm text-indigo-200 font-black mb-2">RAWAEA ERP / SECURITY & ACCESS</div><h2 class="text-2xl md:text-4xl font-black">إدارة أدوار المستخدمين</h2><p class="text-sm md:text-base text-slate-200 mt-2 max-w-4xl leading-7">الدور هو ملف الصلاحيات القابل لإعادة الاستخدام. هذه الصفحة تدير نفس عقد الصلاحيات الحالي دون إنشاء محرك صلاحيات موازٍ.</p></div><div class="flex flex-wrap gap-2"><button type="button" id="btn-seed-roles" class="px-5 py-3 rounded-2xl bg-white/10 hover:bg-white/15 border border-white/15 font-black"><i class="fa-solid fa-seedling ml-2"></i>تهيئة الأدوار الافتراضية</button><button type="button" id="btn-add-role" class="px-5 py-3 rounded-2xl bg-white text-indigo-700 hover:bg-indigo-50 font-black shadow-lg"><i class="fa-solid fa-plus ml-2"></i>إضافة دور جديد</button></div></div></div>' +
                '<div class="grid grid-cols-2 xl:grid-cols-5 gap-4">' +
                    '<div class="bg-white rounded-3xl border border-slate-100 p-5 shadow-sm"><div class="text-xs font-black text-slate-500">إجمالي الأدوار</div><div id="roles-stat-total" class="mt-2 text-3xl font-black text-slate-900">—</div></div>' +
                    '<div class="bg-white rounded-3xl border border-slate-100 p-5 shadow-sm"><div class="text-xs font-black text-slate-500">أدوار النظام</div><div id="roles-stat-system" class="mt-2 text-3xl font-black text-blue-700">—</div></div>' +
                    '<div class="bg-white rounded-3xl border border-slate-100 p-5 shadow-sm"><div class="text-xs font-black text-slate-500">أدوار مخصصة</div><div id="roles-stat-custom" class="mt-2 text-3xl font-black text-indigo-700">—</div></div>' +
                    '<div class="bg-white rounded-3xl border border-slate-100 p-5 shadow-sm"><div class="text-xs font-black text-slate-500">مستخدمون بلا دور</div><div id="roles-stat-unassigned" class="mt-2 text-3xl font-black text-amber-700">—</div></div>' +
                    '<div class="bg-white rounded-3xl border border-slate-100 p-5 shadow-sm"><div class="text-xs font-black text-slate-500">أدوار غير مستخدمة</div><div id="roles-stat-unused" class="mt-2 text-3xl font-black text-rose-700">—</div></div>' +
                '</div>' +
                '<div id="roles-data-warning" class="hidden"></div>' +
                '<div class="bg-white rounded-3xl border border-slate-100 shadow-sm p-4 md:p-5"><div class="flex flex-col xl:flex-row xl:items-center gap-3"><div class="flex-1 relative"><i class="fas fa-search absolute right-4 top-1/2 -translate-y-1/2 text-slate-400"></i><input id="roles-search" type="search" class="w-full pr-11 pl-4 py-3 rounded-2xl border border-slate-200 bg-slate-50 focus:bg-white focus:outline-none focus:ring-2 focus:ring-indigo-200 font-bold" placeholder="ابحث باسم الدور أو الوصف..."></div><select id="roles-type-filter" class="px-4 py-3 rounded-2xl border border-slate-200 bg-slate-50 font-black"><option value="all">كل الأدوار</option><option value="system">أدوار النظام</option><option value="custom">الأدوار المخصصة</option><option value="unused">غير مستخدمة</option></select></div></div>' +
                '<div id="roles-table-wrapper"></div>' +
            '</div>'
        );

        var results = await Promise.all([
            supabase.from('roles').select('*').eq('company_id', companyId).order('created_at', { ascending: true }),
            supabase.from('users').select('id,name,email,status,role_id,role').eq('company_id', companyId).order('name', { ascending: true })
        ]);

        var rolesRes = results[0];
        var usersRes = results[1];

        if (rolesRes.error) {
            rolesData = [];
            usersData = [];
            safeHTML(byId('roles-table-wrapper'), '<div class="p-8 rounded-3xl bg-rose-50 border border-rose-100 text-rose-700 font-black">تعذر تحميل الأدوار: ' + roleEsc(rolesRes.error.message || 'خطأ غير معروف') + '</div>');
            return;
        }

        if (usersRes.error) {
            rolesData = [];
            usersData = [];
            safeHTML(byId('roles-table-wrapper'), '<div class="p-8 rounded-3xl bg-rose-50 border border-rose-100 text-rose-700 font-black">تعذر تحميل المستخدمين لحساب تأثير الدور: ' + roleEsc(usersRes.error.message || 'خطأ غير معروف') + '</div>');
            return;
        }

        rolesData = rolesRes.data || [];
        usersData = usersRes.data || [];
        renderTable(rolesData);

        var searchEl = byId('roles-search');
        var typeEl = byId('roles-type-filter');
        var rerender = function() { renderTable(rolesData); };
        if (searchEl) searchEl.addEventListener('input', rerender);
        if (typeEl) typeEl.addEventListener('change', rerender);

        var addBtn = byId('btn-add-role');
        if (addBtn) addBtn.addEventListener('click', function() { openRolePage(null); });

        var seedBtn = byId('btn-seed-roles');
        if (seedBtn) seedBtn.addEventListener('click', seedDefaultRoles);
    }
\`\`\`

---

# SURGERY C — renderTable()

ابحث داخل RW_Roles عن:

\`\`\`javascript
    function renderTable(data) {
\`\`\`

واحذفها كاملة حتى بداية \`openModal\` الحالية، واستبدلها بـ:

\`\`\`javascript
    function renderTable(data) {
        var w = byId('roles-table-wrapper');
        if (!w) return;

        var searchTerm = String((byId('roles-search') && byId('roles-search').value) || '').trim().toLowerCase();
        var typeFilter = String((byId('roles-type-filter') && byId('roles-type-filter').value) || 'all');
        var activeMemberCountByRole = {};
        var activeUsersWithoutRole = 0;

        for (var ui = 0; ui < usersData.length; ui++) {
            var usr = usersData[ui];
            if (usr.status !== 'Inactive' && !usr.role_id) activeUsersWithoutRole++;
            if (usr.status !== 'Inactive' && usr.role_id) {
                activeMemberCountByRole[usr.role_id] = (activeMemberCountByRole[usr.role_id] || 0) + 1;
            }
        }

        var systemCount = 0;
        var customCount = 0;
        var unusedCount = 0;

        for (var ri = 0; ri < data.length; ri++) {
            var rr = data[ri];
            var count = activeMemberCountByRole[rr.id] || 0;
            if (rr.is_system) systemCount++; else customCount++;
            if (count === 0) unusedCount++;
        }

        safeText(byId('roles-stat-total'), data.length);
        safeText(byId('roles-stat-system'), systemCount);
        safeText(byId('roles-stat-custom'), customCount);
        safeText(byId('roles-stat-unassigned'), activeUsersWithoutRole);
        safeText(byId('roles-stat-unused'), unusedCount);

        var warning = byId('roles-data-warning');
        if (warning) {
            if (activeUsersWithoutRole > 0) {
                warning.className = 'block p-4 rounded-3xl bg-amber-50 border border-amber-200 text-amber-900 text-sm font-bold';
                safeHTML(warning, '<div class="flex items-start gap-3"><div class="w-10 h-10 rounded-2xl bg-amber-100 flex items-center justify-center"><i class="fas fa-triangle-exclamation"></i></div><div><div class="font-black">يوجد ' + activeUsersWithoutRole + ' مستخدم نشط بلا role_id.</div><div class="mt-1 text-xs font-bold text-amber-800">لم يتم تعيينه تلقائيًا؛ لأن اسم الدور النصي الحالي لا يطابق دورًا Production قائمًا، وأي تعيين آلي سيكون افتراضًا غير مسموح به.</div></div></div>');
            } else {
                warning.className = 'hidden';
                safeHTML(warning, '');
            }
        }

        var filtered = [];
        for (var fi = 0; fi < data.length; fi++) {
            var r = data[fi];
            var memberCount = activeMemberCountByRole[r.id] || 0;
            var hay = (String(r.role_name || '') + ' ' + String(r.description || '')).toLowerCase();
            var searchMatch = !searchTerm || hay.indexOf(searchTerm) !== -1;
            var typeMatch = typeFilter === 'all' || (typeFilter === 'system' && r.is_system) || (typeFilter === 'custom' && !r.is_system) || (typeFilter === 'unused' && memberCount === 0);
            if (searchMatch && typeMatch) filtered.push(r);
        }

        if (!filtered.length) {
            safeHTML(w, '<div class="bg-white rounded-3xl border border-slate-100 p-12 text-center text-slate-500 font-black">لا توجد نتائج مطابقة للبحث الحالي.</div>');
            return;
        }

        var html = '<div class="bg-white rounded-3xl border border-slate-100 shadow-sm overflow-hidden"><div class="hidden xl:block overflow-x-auto"><table class="w-full text-sm"><thead class="bg-slate-50 border-b"><tr><th class="p-4 text-right font-black">الدور</th><th class="p-4 text-right font-black">الوصف</th><th class="p-4 text-center font-black">النوع</th><th class="p-4 text-center font-black">الصلاحيات</th><th class="p-4 text-center font-black">المستخدمون</th><th class="p-4 text-center font-black">الإجراء</th></tr></thead><tbody>';

        for (var i = 0; i < filtered.length; i++) {
            var role = filtered[i];
            var permissionCount = Array.isArray(role.permissions) ? role.permissions.length : 0;
            var members = activeMemberCountByRole[role.id] || 0;
            var typeBadge = role.is_system ? '<span class="inline-flex items-center gap-1 px-3 py-1.5 rounded-full bg-blue-50 text-blue-700 border border-blue-100 text-xs font-black"><i class="fas fa-shield-halved"></i>نظام</span>' : '<span class="inline-flex items-center gap-1 px-3 py-1.5 rounded-full bg-slate-50 text-slate-700 border border-slate-200 text-xs font-black"><i class="fas fa-user-shield"></i>مخصص</span>';
            html += '<tr class="hover:bg-slate-50/80 border-b last:border-0 transition-colors"><td class="p-4"><div class="font-black text-slate-900">' + roleEsc(role.role_name) + '</div><div class="text-xs text-slate-400 mt-1">آخر تحديث: ' + roleEsc(role.updated_at || role.created_at || 'غير متاح') + '</div></td><td class="p-4 text-slate-600 font-bold max-w-md">' + roleEsc(role.description || 'بدون وصف') + '</td><td class="p-4 text-center">' + typeBadge + '</td><td class="p-4 text-center"><span class="inline-flex items-center gap-2 font-black text-indigo-700"><i class="fas fa-key"></i>' + permissionCount + '</span></td><td class="p-4 text-center"><span class="font-black ' + (members > 0 ? 'text-emerald-700' : 'text-rose-600') + '">' + members + '</span></td><td class="p-4 text-center"><button type="button" data-role-open="' + roleEsc(role.id) + '" class="px-4 py-2.5 rounded-2xl bg-indigo-50 hover:bg-indigo-100 text-indigo-700 font-black"><i class="fas fa-arrow-left ml-2"></i>فتح الصفحة</button></td></tr>';
        }

        html += '</tbody></table></div><div class="xl:hidden divide-y">';

        for (var ci = 0; ci < filtered.length; ci++) {
            var cr = filtered[ci];
            var cp = Array.isArray(cr.permissions) ? cr.permissions.length : 0;
            var cm = activeMemberCountByRole[cr.id] || 0;
            html += '<button type="button" data-role-open="' + roleEsc(cr.id) + '" class="w-full text-right p-5 hover:bg-slate-50 transition-colors"><div class="flex items-start justify-between gap-4"><div class="min-w-0"><div class="font-black text-lg text-slate-900 truncate">' + roleEsc(cr.role_name) + '</div><div class="text-xs text-slate-500 mt-1 line-clamp-2">' + roleEsc(cr.description || 'بدون وصف') + '</div></div>' + (cr.is_system ? '<span class="shrink-0 px-3 py-1 rounded-full bg-blue-50 text-blue-700 text-xs font-black">نظام</span>' : '<span class="shrink-0 px-3 py-1 rounded-full bg-slate-50 text-slate-700 text-xs font-black">مخصص</span>') + '</div><div class="mt-4 flex items-center justify-between text-xs font-black text-slate-500"><span><i class="fas fa-key ml-1"></i>' + cp + ' صلاحية</span><span><i class="fas fa-users ml-1"></i>' + cm + ' مستخدم</span><span class="text-indigo-700">فتح <i class="fas fa-arrow-left mr-1"></i></span></div></button>';
        }

        html += '</div></div>';
        safeHTML(w, html);

        var openButtons = w.querySelectorAll('[data-role-open]');
        for (var bi = 0; bi < openButtons.length; bi++) {
            openButtons[bi].addEventListener('click', function() {
                openRolePage(this.getAttribute('data-role-open'));
            });
        }
    }
\`\`\`

---

# SURGERY D — openRolePage()

ابحث حرفيًا عن:

\`\`\`javascript
    function openModal(roleId) {
\`\`\`

واحذف الدالة كاملة حتى بداية:

\`\`\`javascript
    function _switchRoleTab(tabId) {
\`\`\`

واستبدلها بالدالة التالية:

\`\`\`javascript
    function openRolePage(roleId) {
        var container = byId('rw-page-container');
        if (!container) return;

        var role = null;
        if (roleId) {
            for (var i = 0; i < rolesData.length; i++) {
                if (String(rolesData[i].id) === String(roleId)) {
                    role = rolesData[i];
                    break;
                }
            }
            if (!role) {
                showToast('الدور المطلوب غير موجود في السياق الحالي', 'error');
                return;
            }
        }

        var isEdit = !!role;
        var currentPermissions = role && Array.isArray(role.permissions) ? role.permissions.slice() : [];
        var currentPermissionMap = {};
        for (var pm = 0; pm < currentPermissions.length; pm++) currentPermissionMap[String(currentPermissions[pm])] = true;

        var appPerms = [
            { key: 'pos', label: 'نقطة البيع (POS)', hint: 'بيع مباشر وفواتير POS' },
            { key: 'telesales', label: 'التلي سيلز', hint: 'الطلبات الهاتفية' },
            { key: 'orders', label: 'الأوردرات', hint: 'طلبات مندوبي المبيعات' },
            { key: 'van-sales', label: 'فان سيلز', hint: 'البيع المباشر بالسيارة' },
            { key: 'sales_supervisor', label: 'مشرف المبيعات', hint: 'إشراف تشغيل المبيعات' },
            { key: 'warehouse_supervisor', label: 'مشرف المخازن', hint: 'إشراف العمليات المخزنية' },
            { key: 'warehouse', label: 'عمال المخازن', hint: 'الاستلام والتحضير والتحميل وغيرها' },
            { key: 'delivery', label: 'مندوب التوصيل', hint: 'تنفيذ عمليات التسليم' },
            { key: 'delivery_supervisor', label: 'مشرف التوصيل', hint: 'إشراف دورة التوصيل' },
            { key: 'purchases', label: 'مسؤول المشتريات', hint: 'المشتريات' },
            { key: 'purchases_supervisor', label: 'مشرف المشتريات', hint: 'إشراف المشتريات' },
            { key: 'finance', label: 'المحاسب', hint: 'المالية' },
            { key: 'online-store', label: 'المتجر الإلكتروني', hint: 'تشغيل المتجر' },
            { key: 'sales_manager', label: 'مدير المبيعات', hint: 'إدارة المبيعات' },
            { key: 'warehouse_manager', label: 'مدير المخازن', hint: 'إدارة المخزون' },
            { key: 'finance_manager', label: 'المدير المالي', hint: 'الإدارة المالية' },
            { key: 'general_manager', label: 'المدير العام', hint: 'الإدارة العامة' },
            { key: 'hr', label: 'الموارد البشرية', hint: 'HR' }
        ];

        var erpPerms = [
            { key: 'dash', label: 'لوحة التحكم', hint: 'الواجهة الإدارية الرئيسية' },
            { key: 'items', label: 'الأصناف والمخزون', hint: 'دليل الأصناف ومتابعة المخزون' },
            { key: 'stock_adjustment', label: 'تحديث الأرصدة', hint: 'التسويات المخزنية' },
            { key: 'customers', label: 'العملاء', hint: 'دليل العملاء' },
            { key: 'suppliers', label: 'الموردين', hint: 'دليل الموردين' },
            { key: 'branches', label: 'الفروع والمخازن', hint: 'نطاق الفروع' },
            { key: 'runsheets', label: 'الرانشيتات', hint: 'فتح ومتابعة الرانشيت' },
            { key: 'receiving', label: 'سجل الاستلام', hint: 'عمليات الاستلام' },
            { key: 'picking', label: 'سجل التحضير', hint: 'عمليات التحضير' },
            { key: 'loading', label: 'سجل التحميل', hint: 'عمليات التحميل' },
            { key: 'return', label: 'سجل المرتجعات', hint: 'المرتجعات' },
            { key: 'unloading', label: 'سجل التفريغ', hint: 'عمليات التفريغ' },
            { key: 'vouchers', label: 'الأذونات المخزنية', hint: 'إدارة الأذونات' },
            { key: 'transfer', label: 'تحويل مخزني', hint: 'نقل المخزون' },
            { key: 'direct-sale', label: 'صرف سيارة بيع مباشر', hint: 'صرف بضاعة للبيع المباشر' },
            { key: 'direct-return', label: 'استلام مرتجع سيارة', hint: 'استلام مرتجعات السيارات' },
            { key: 'supplier-return', label: 'مرتجع لمورد', hint: 'مرتجعات الموردين' },
            { key: 'vehicle-count', label: 'جرد سيارة', hint: 'جرد المخزون بالسيارة' },
            { key: 'branch-count', label: 'جرد فرع', hint: 'جرد مخزون الفرع' },
            { key: 'general-count', label: 'جرد عام', hint: 'الجرد الشامل' },
            { key: 'reports', label: 'التقارير', hint: 'التقارير الإدارية' },
            { key: 'users', label: 'المستخدمين والصلاحيات', hint: 'إدارة المستخدمين' },
            { key: 'roles', label: 'إدارة الأدوار', hint: 'إدارة ملفات الصلاحيات' },
            { key: 'settings', label: 'إعدادات النظام', hint: 'الإعدادات العامة' },
            { key: 'settlement', label: 'إغلاق اليومية', hint: 'التسويات والإغلاق' }
        ];

        var members = [];
        if (role) {
            for (var mi = 0; mi < usersData.length; mi++) if (usersData[mi].role_id === role.id) members.push(usersData[mi]);
        }

        function permissionCard(item, group) {
            var checked = !!currentPermissionMap[item.key];
            return '<label class="role-page-perm-card flex items-start gap-3 p-4 rounded-2xl border ' + (checked ? 'border-indigo-200 bg-indigo-50/70' : 'border-slate-200 bg-white hover:bg-slate-50') + ' cursor-pointer transition-colors" data-role-perm-group="' + group + '" data-role-perm-search="' + roleEsc(item.key + ' ' + item.label + ' ' + item.hint) + '"><input type="checkbox" value="' + roleEsc(item.key) + '" class="role-page-perm mt-1 w-5 h-5 accent-indigo-600"' + (checked ? ' checked' : '') + '><span class="min-w-0 flex-1"><span class="block font-black text-sm text-slate-900">' + roleEsc(item.label) + '</span><span class="block text-[11px] text-slate-500 font-bold mt-1">' + roleEsc(item.hint) + '</span><span class="block text-[10px] text-slate-400 font-black mt-2">' + roleEsc(item.key) + '</span></span></label>';
        }

        var appHtml = '';
        for (var ai = 0; ai < appPerms.length; ai++) appHtml += permissionCard(appPerms[ai], 'apps');

        var erpHtml = '';
        for (var ei = 0; ei < erpPerms.length; ei++) erpHtml += permissionCard(erpPerms[ei], 'erp');

        var permissionCount = currentPermissions.filter(function(x) { return String(x).trim() && String(x).trim() !== '*'; }).length;
        var statusLabel = role && role.is_system ? 'دور نظامي' : 'دور مخصص';

        safeText(byId('rw-header-title'), isEdit ? 'تعديل الدور' : 'إضافة دور جديد');
        safeText(byId('rw-header-subtitle'), 'صفحة كاملة لإدارة هوية الدور وملف الصلاحيات وتأثيره على المستخدمين');

        var html =
            '<div id="rw-role-page" class="max-w-[1700px] mx-auto p-4 md:p-6 space-y-5" dir="rtl">' +
                '<div class="bg-gradient-to-br from-slate-950 via-indigo-950 to-blue-900 rounded-[32px] p-6 md:p-8 text-white shadow-2xl"><div class="flex flex-col xl:flex-row xl:items-start xl:justify-between gap-6"><div class="flex items-start gap-4 min-w-0"><button type="button" data-role-action="back" class="shrink-0 w-12 h-12 rounded-2xl bg-white/10 hover:bg-white/15 border border-white/15"><i class="fas fa-arrow-right"></i></button><div class="min-w-0"><div class="text-xs md:text-sm text-indigo-200 font-black mb-2">RAWAEA ERP / ROLE PROFILE</div><div class="flex flex-wrap items-center gap-2"><h2 class="text-2xl md:text-4xl font-black truncate">' + roleEsc(isEdit ? role.role_name : 'دور جديد') + '</h2><span class="px-3 py-1 rounded-full bg-white/10 border border-white/15 text-xs font-black">' + roleEsc(statusLabel) + '</span></div><p class="text-sm text-slate-200 mt-2">' + roleEsc(isEdit ? (role.description || 'بدون وصف') : 'أنشئ ملف صلاحيات قابلًا لإعادة الاستخدام للمستخدمين.') + '</p></div></div><div class="flex flex-wrap gap-2">' + (isEdit ? '<button type="button" data-role-action="clone" class="px-4 py-3 rounded-2xl bg-white/10 hover:bg-white/15 border border-white/15 font-black"><i class="fas fa-copy ml-2"></i>نسخ الدور</button>' : '') + '<button type="button" data-role-action="save" class="px-6 py-3 rounded-2xl bg-white text-indigo-700 hover:bg-indigo-50 font-black shadow-lg"><i class="fas fa-floppy-disk ml-2"></i>حفظ الدور</button></div></div></div>' +
                '<div class="grid grid-cols-2 xl:grid-cols-4 gap-4"><div class="bg-white rounded-3xl border border-slate-100 p-5 shadow-sm"><div class="text-xs text-slate-500 font-black">الصلاحيات الحالية</div><div class="mt-2 text-3xl font-black text-indigo-700">' + permissionCount + '</div></div><div class="bg-white rounded-3xl border border-slate-100 p-5 shadow-sm"><div class="text-xs text-slate-500 font-black">المستخدمون النشطون</div><div class="mt-2 text-3xl font-black text-emerald-700">' + members.filter(function(x){ return x.status !== 'Inactive'; }).length + '</div></div><div class="bg-white rounded-3xl border border-slate-100 p-5 shadow-sm"><div class="text-xs text-slate-500 font-black">التطبيقات</div><div class="mt-2 text-3xl font-black text-blue-700">' + appPerms.filter(function(x){ return !!currentPermissionMap[x.key]; }).length + '</div></div><div class="bg-white rounded-3xl border border-slate-100 p-5 shadow-sm"><div class="text-xs text-slate-500 font-black">النظام الأم</div><div class="mt-2 text-3xl font-black text-slate-800">' + erpPerms.filter(function(x){ return !!currentPermissionMap[x.key]; }).length + '</div></div></div>' +
                '<div class="sticky top-[96px] z-40 bg-white/95 backdrop-blur rounded-2xl border border-slate-100 shadow-sm p-2 overflow-x-auto"><div class="flex gap-2 min-w-max"><button type="button" data-role-tab="overview" class="px-5 py-3 rounded-xl font-black text-sm border-b-2 border-indigo-600 text-indigo-600">نظرة عامة</button><button type="button" data-role-tab="permissions" class="px-5 py-3 rounded-xl font-black text-sm text-slate-500">الصلاحيات</button><button type="button" data-role-tab="members" class="px-5 py-3 rounded-xl font-black text-sm text-slate-500">المستخدمون</button><button type="button" data-role-tab="audit" class="px-5 py-3 rounded-xl font-black text-sm text-slate-500">سجل التغييرات</button></div></div>' +
                '<section data-role-panel="overview" class="space-y-5"><div class="grid grid-cols-1 xl:grid-cols-[minmax(0,1.4fr)_minmax(360px,0.8fr)] gap-5"><div class="bg-white rounded-3xl border border-slate-100 shadow-sm overflow-hidden"><div class="px-6 py-5 bg-slate-50 border-b"><h3 class="font-black text-xl text-slate-900">هوية الدور</h3><p class="text-xs text-slate-500 mt-1">البيانات الأساسية التي تُحفظ في نفس Production contract الحالي.</p></div><div class="p-6 grid grid-cols-1 md:grid-cols-2 gap-5"><label class="block md:col-span-2"><span class="block text-xs font-black text-slate-600 mb-2">اسم الدور *</span><input id="role-name" value="' + roleEsc(role ? role.role_name : '') + '" class="w-full px-4 py-3 rounded-2xl border border-slate-200 bg-slate-50 focus:bg-white focus:outline-none focus:ring-2 focus:ring-indigo-200 font-bold"></label><label class="block md:col-span-2"><span class="block text-xs font-black text-slate-600 mb-2">الوصف</span><textarea id="role-desc" rows="4" class="w-full px-4 py-3 rounded-2xl border border-slate-200 bg-slate-50 focus:bg-white focus:outline-none focus:ring-2 focus:ring-indigo-200 font-bold">' + roleEsc(role ? (role.description || '') : '') + '</textarea></label></div></div><div class="space-y-5"><div class="bg-white rounded-3xl border border-slate-100 shadow-sm p-6"><div class="flex items-start gap-3"><div class="w-11 h-11 rounded-2xl bg-indigo-600 text-white flex items-center justify-center"><i class="fas fa-shield-halved"></i></div><div><h4 class="font-black text-lg text-slate-900">عقد الصلاحيات الحالي</h4><p class="text-sm text-slate-500 mt-2 leading-6">الدور يحفظ قائمة مفاتيح صلاحيات موجودة أصلًا في النظام. لا يتم هنا اختراع CRUD/Record Rules جديدة حتى لا ينفصل إعداد الدور عن الـruntime الحالي.</p></div></div></div><div class="bg-slate-950 rounded-3xl p-6 text-white"><div class="text-xs text-slate-400 font-black">مفتاح الحماية</div><div class="mt-2 font-black text-lg">company_id → roles → users.role_id</div><div class="mt-2 text-xs text-slate-400 leading-6">كل قراءة Production في هذه الصفحة Company-scoped، والحفظ والحذف يمران عبر Edge Functions الحالية.</div></div></div></div></section>' +
                '<section data-role-panel="permissions" class="hidden space-y-5"><div class="bg-white rounded-3xl border border-slate-100 shadow-sm p-5"><div class="flex flex-col xl:flex-row xl:items-center gap-3"><div class="flex-1 relative"><i class="fas fa-search absolute right-4 top-1/2 -translate-y-1/2 text-slate-400"></i><input id="role-permission-search" type="search" class="w-full pr-11 pl-4 py-3 rounded-2xl border border-slate-200 bg-slate-50 focus:bg-white focus:outline-none focus:ring-2 focus:ring-indigo-200 font-bold" placeholder="ابحث في اسم الصلاحية أو المفتاح أو الوصف..."></div><div class="flex flex-wrap gap-2"><button type="button" data-role-bulk="apps-on" class="px-4 py-3 rounded-2xl bg-indigo-50 text-indigo-700 font-black">تفعيل التطبيقات</button><button type="button" data-role-bulk="apps-off" class="px-4 py-3 rounded-2xl bg-slate-100 text-slate-700 font-black">مسح التطبيقات</button><button type="button" data-role-bulk="erp-on" class="px-4 py-3 rounded-2xl bg-blue-50 text-blue-700 font-black">تفعيل النظام الأم</button><button type="button" data-role-bulk="erp-off" class="px-4 py-3 rounded-2xl bg-slate-100 text-slate-700 font-black">مسح النظام الأم</button></div></div></div><div class="bg-white rounded-3xl border border-slate-100 shadow-sm overflow-hidden"><div class="px-6 py-5 bg-indigo-50 border-b border-indigo-100"><h3 class="font-black text-xl text-indigo-950">تطبيقات التشغيل</h3><p class="text-xs text-indigo-800/70 mt-1">المفاتيح التي تتحكم في التطبيقات التنفيذية المنفصلة.</p></div><div class="p-6 grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-3">' + appHtml + '</div></div><div class="bg-white rounded-3xl border border-slate-100 shadow-sm overflow-hidden"><div class="px-6 py-5 bg-slate-50 border-b"><h3 class="font-black text-xl text-slate-900">النظام الأم</h3><p class="text-xs text-slate-500 mt-1">المفاتيح التي تدير تبويبات وعمليات النظام المركزي.</p></div><div class="p-6 grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-3">' + erpHtml + '</div></div></section>' +
                '<section data-role-panel="members" class="hidden space-y-5"><div class="bg-white rounded-3xl border border-slate-100 shadow-sm overflow-hidden"><div class="px-6 py-5 bg-sky-50 border-b border-sky-100"><h3 class="font-black text-xl text-sky-950">المستخدمون المرتبطون بالدور</h3><p class="text-xs text-sky-800/70 mt-1">المرجع هو users.role_id. المستخدم الذي لا يملك role_id لا يتم ربطه تلقائيًا بأي دور.</p></div><div class="p-6">' + (members.length ? '<div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-3">' + members.map(function(member){ return '<div class="p-4 rounded-2xl border border-slate-200 bg-slate-50/60"><div class="flex items-start justify-between gap-3"><div><div class="font-black text-slate-900">' + roleEsc(member.name || member.email) + '</div><div class="text-xs text-slate-500 mt-1">' + roleEsc(member.email) + '</div></div><span class="px-2.5 py-1 rounded-full text-[10px] font-black ' + (member.status === 'Inactive' ? 'bg-slate-200 text-slate-600' : 'bg-emerald-50 text-emerald-700') + '">' + (member.status === 'Inactive' ? 'غير نشط' : 'نشط') + '</span></div><div class="mt-3 text-xs font-bold text-slate-500">الدور النصي: ' + roleEsc(member.role || '—') + '</div></div>'; }).join('') + '</div>' : '<div class="py-12 text-center text-slate-400 font-black">لا يوجد مستخدمون مرتبطون بهذا الدور حاليًا.</div>') + '</div></div></section>' +
                '<section data-role-panel="audit" class="hidden space-y-5"><div class="bg-white rounded-3xl border border-slate-100 shadow-sm overflow-hidden"><div class="px-6 py-5 bg-violet-50 border-b border-violet-100"><h3 class="font-black text-xl text-violet-950">سجل تغييرات الدور</h3><p class="text-xs text-violet-800/70 mt-1">السجل يقرأ فقط أحداث roles لهذا السجل دون كشف audit العام.</p></div><div id="role-audit-wrapper" class="p-6"><div class="text-center py-10 text-slate-400 font-black">جاري تحميل السجل...</div></div></div></section>' +
                '<div class="sticky bottom-0 z-40 bg-white/95 backdrop-blur border border-slate-100 rounded-3xl shadow-2xl p-4"><div class="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-3"><div class="text-xs text-slate-500 font-bold">' + (isEdit ? 'الدور الحالي: ' + roleEsc(role.role_name) : 'إنشاء دور جديد') + '</div><div class="flex flex-wrap gap-2"><button type="button" data-role-action="back" class="px-5 py-3 rounded-2xl bg-slate-100 hover:bg-slate-200 text-slate-700 font-black">العودة للأدوار</button>' + (isEdit && !role.is_system ? '<button type="button" data-role-action="delete" class="px-5 py-3 rounded-2xl bg-rose-600 hover:bg-rose-700 text-white font-black"><i class="fas fa-trash-alt ml-2"></i>حذف الدور</button>' : '') + '<button type="button" data-role-action="save" class="px-7 py-3 rounded-2xl bg-indigo-600 hover:bg-indigo-700 text-white font-black shadow-lg">حفظ الدور</button></div></div></div>' +
            '</div>';

        safeHTML(container, html);

        function switchTab(tabId) {
            var tabs = document.querySelectorAll('#rw-role-page [data-role-tab]');
            var panels = document.querySelectorAll('#rw-role-page [data-role-panel]');
            for (var ti = 0; ti < tabs.length; ti++) {
                var active = tabs[ti].getAttribute('data-role-tab') === tabId;
                tabs[ti].classList.toggle('border-indigo-600', active);
                tabs[ti].classList.toggle('text-indigo-600', active);
                tabs[ti].classList.toggle('text-slate-500', !active);
            }
            for (var pi = 0; pi < panels.length; pi++) panels[pi].classList.toggle('hidden', panels[pi].getAttribute('data-role-panel') !== tabId);
        }

        var pageRoot = byId('rw-role-page');
        if (pageRoot) {
            var tabs = pageRoot.querySelectorAll('[data-role-tab]');
            for (var ti = 0; ti < tabs.length; ti++) tabs[ti].addEventListener('click', function() { switchTab(this.getAttribute('data-role-tab')); });

            var permSearch = byId('role-permission-search');
            if (permSearch) permSearch.addEventListener('input', function() {
                var q = String(permSearch.value || '').trim().toLowerCase();
                var cards = pageRoot.querySelectorAll('.role-page-perm-card');
                for (var ci = 0; ci < cards.length; ci++) {
                    var hay = String(cards[ci].getAttribute('data-role-perm-search') || '').toLowerCase();
                    cards[ci].style.display = !q || hay.indexOf(q) !== -1 ? '' : 'none';
                }
            });

            var permInputs = pageRoot.querySelectorAll('.role-page-perm');
            for (var pi = 0; pi < permInputs.length; pi++) permInputs[pi].addEventListener('change', function() {
                var label = this.parentNode;
                if (!label) return;
                label.classList.toggle('border-indigo-200', this.checked);
                label.classList.toggle('bg-indigo-50/70', this.checked);
                label.classList.toggle('border-slate-200', !this.checked);
                label.classList.toggle('bg-white', !this.checked);
            });

            var bulkButtons = pageRoot.querySelectorAll('[data-role-bulk]');
            for (var bii = 0; bii < bulkButtons.length; bii++) bulkButtons[bii].addEventListener('click', function() {
                var action = this.getAttribute('data-role-bulk');
                var group = action.indexOf('apps') === 0 ? 'apps' : 'erp';
                var makeOn = action.indexOf('-on') !== -1;
                var all = pageRoot.querySelectorAll('.role-page-perm');
                for (var bi = 0; bi < all.length; bi++) if (all[bi].parentNode && all[bi].parentNode.getAttribute('data-role-perm-group') === group) {
                    all[bi].checked = makeOn;
                    all[bi].dispatchEvent(new Event('change'));
                }
            });

            var actions = pageRoot.querySelectorAll('[data-role-action]');
            for (var ac = 0; ac < actions.length; ac++) actions[ac].addEventListener('click', function() {
                var action = this.getAttribute('data-role-action');
                if (action === 'back') render();
                else if (action === 'save') saveRole(false);
                else if (action === 'clone') saveRole(true);
                else if (action === 'delete') deleteRole();
            });
        }

        function collectPermissions() {
            var selected = [];
            var checkboxes = document.querySelectorAll('#rw-role-page .role-page-perm:checked');
            for (var i = 0; i < checkboxes.length; i++) {
                var key = String(checkboxes[i].value || '').trim();
                if (key && selected.indexOf(key) === -1) selected.push(key);
            }
            return selected;
        }

        async function saveRole(cloneMode) {
            var nameEl = byId('role-name');
            var descEl = byId('role-desc');
            var name = nameEl ? String(nameEl.value || '').trim() : '';
            var description = descEl ? String(descEl.value || '').trim() : '';
            if (!name) { showToast('اسم الدور مطلوب', 'error'); return; }
            if (cloneMode) { name = name + ' - نسخة'; description = description || ('نسخة من الدور ' + (role ? role.role_name : '')); }

            var payload = { id: cloneMode ? null : (role ? role.id : null), role_name: name, description: description, permissions: collectPermissions(), is_system: cloneMode ? false : (role ? !!role.is_system : false) };
            showLoader(cloneMode ? 'جاري نسخ الدور...' : 'جاري حفظ الدور...');

            try {
                var sessionRes = await supabase.auth.getSession();
                var token = sessionRes && sessionRes.data && sessionRes.data.session ? sessionRes.data.session.access_token : null;
                if (!token) throw new Error('جلسة غير صالحة');
                var res = await fetch(RW_SUPABASE_URL + '/functions/v1/save-role', { method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + token }, body: JSON.stringify(payload) });
                var json = await res.json();
                if (!json || !json.success) throw new Error((json && (json.error || json.msg)) || 'فشل حفظ الدور');
                hideLoader();
                showToast(cloneMode ? 'تم نسخ الدور' : (isEdit ? 'تم تحديث الدور' : 'تم إنشاء الدور'), 'success');
                await render();
            } catch (e) {
                hideLoader();
                showToast(e.message || 'فشل الاتصال بـ save-role', 'error');
            }
        }

        async function deleteRole() {
            if (!role) return;
            var activeMembers = members.filter(function(x) { return x.status !== 'Inactive'; });
            if (activeMembers.length) { showToast('لا يمكن حذف دور مرتبط بمستخدمين نشطين؛ أعد تعيينهم أولًا', 'warning'); return; }

            var confirmResult = await Swal.fire({ title: 'حذف الدور', text: 'سيتم حذف الدور المخصص فقط بعد التحقق من عدم ارتباطه بمستخدمين.', icon: 'warning', showCancelButton: true, confirmButtonText: 'حذف الدور', cancelButtonText: 'إلغاء' });
            if (!confirmResult.isConfirmed) return;

            showLoader('جاري حذف الدور...');
            try {
                var sessionRes = await supabase.auth.getSession();
                var token = sessionRes && sessionRes.data && sessionRes.data.session ? sessionRes.data.session.access_token : null;
                if (!token) throw new Error('جلسة غير صالحة');
                var res = await fetch(RW_SUPABASE_URL + '/functions/v1/delete-role', { method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + token }, body: JSON.stringify({ roleId: role.id }) });
                var json = await res.json();
                if (!json || !json.success) throw new Error((json && (json.error || json.msg)) || 'فشل حذف الدور');
                hideLoader();
                showToast('تم حذف الدور', 'success');
                await render();
            } catch (e) {
                hideLoader();
                showToast(e.message || 'فشل الاتصال بـ delete-role', 'error');
            }
        }

        if (isEdit && role.id) {
            supabase.from('audit_log').select('action,user_email,old_data,new_data,created_at').eq('table_name', 'roles').eq('record_id', String(role.id)).order('created_at', { ascending: false }).limit(20).then(function(res) {
                var box = byId('role-audit-wrapper');
                if (!box) return;
                if (res.error) { safeHTML(box, '<div class="text-center py-8 text-rose-600 font-black">تعذر قراءة سجل التغييرات: ' + roleEsc(res.error.message || 'خطأ غير معروف') + '</div>'); return; }
                var rows = res.data || [];
                if (!rows.length) { safeHTML(box, '<div class="text-center py-10 text-slate-400 font-black">لا توجد أحداث مسجلة لهذا الدور حتى الآن.</div>'); return; }
                var out = '';
                for (var ai = 0; ai < rows.length; ai++) {
                    var row = rows[ai];
                    var oldPerms = row.old_data && Array.isArray(row.old_data.permissions) ? row.old_data.permissions.length : null;
                    var newPerms = row.new_data && Array.isArray(row.new_data.permissions) ? row.new_data.permissions.length : null;
                    var detail = row.action === 'delete' ? 'تم حذف الدور' : (row.action === 'create' ? 'تم إنشاء الدور' : (row.action === 'role_permissions_sync' ? 'تمت مزامنة صلاحيات مستخدم مرتبط' : 'تم تحديث ملف الدور'));
                    if (oldPerms !== null || newPerms !== null) detail += ' — الصلاحيات: ' + (oldPerms === null ? '—' : oldPerms) + ' → ' + (newPerms === null ? '—' : newPerms);
                    out += '<div class="p-4 rounded-2xl border border-slate-200 bg-slate-50/60 mb-3"><div class="flex flex-col md:flex-row md:items-center md:justify-between gap-2"><div><div class="font-black text-slate-900">' + roleEsc(detail) + '</div><div class="text-xs text-slate-500 mt-1">المنفذ: ' + roleEsc(row.user_email || 'system') + '</div></div><div class="text-xs font-black text-slate-400">' + roleEsc(row.created_at || '') + '</div></div></div>';
                }
                safeHTML(box, out);
            }).catch(function() {
                var box = byId('role-audit-wrapper');
                if (box) safeHTML(box, '<div class="text-center py-8 text-rose-600 font-black">تعذر تحميل سجل التغييرات.</div>');
            });
        } else {
            var auditBox = byId('role-audit-wrapper');
            if (auditBox) safeHTML(auditBox, '<div class="text-center py-10 text-slate-400 font-black">سجل التغييرات سيبدأ عند أول حفظ للدور.</div>');
        }
    }
\`\`\`

---

# SURGERY E — _switchRoleTab()

ابحث عن:

\`\`\`javascript
    function _switchRoleTab(tabId) {
\`\`\`

واحذفها واستبدلها بـ:

\`\`\`javascript
    function _switchRoleTab(tabId) {
        var root = byId('rw-role-page');
        if (!root) return;
        var tabs = root.querySelectorAll('[data-role-tab]');
        var panels = root.querySelectorAll('[data-role-panel]');
        for (var i = 0; i < tabs.length; i++) {
            var active = tabs[i].getAttribute('data-role-tab') === tabId;
            tabs[i].classList.toggle('border-indigo-600', active);
            tabs[i].classList.toggle('text-indigo-600', active);
            tabs[i].classList.toggle('text-slate-500', !active);
        }
        for (var p = 0; p < panels.length; p++) {
            panels[p].classList.toggle('hidden', panels[p].getAttribute('data-role-panel') !== tabId);
        }
    }
\`\`\`

---

# SURGERY F — Export compatibility

ابحث حرفيًا عن:

\`\`\`javascript
    return { render: render, _openModal: openModal, _switchRoleTab: _switchRoleTab };
\`\`\`

واحذفه واستبدله بـ:

\`\`\`javascript
    return {
        render: render,
        _openRolePage: openRolePage,
        _openModal: openRolePage,
        _switchRoleTab: _switchRoleTab
    };
\`\`\`

تم الإبقاء على \`_openModal\` كـAlias للـPage لتجنب كسر consumer تاريخي غير ظاهر في code search.

---

# 11. ما تم الحفاظ عليه

- \`roles.permissions\` contract.
- permission keys الحالية.
- \`save-role\`.
- \`delete-role\`.
- \`seed-roles\`.
- \`users.role_id\`.
- Company RLS.
- OWNER wildcard semantics.
- التطبيقات التشغيلية المنفصلة.
- inventory / runsheets / picking / loading / delivery / returns / accounting.
- دورة الأوردر والرانشيت.
- أي Physical Stock logic.

لا يوجد Role Engine ثانٍ.

---

# 12. النتيجة الوظيفية

بعد Owner integration يصبح RW_Roles:

## List
- KPI.
- Search.
- System / Custom / Unused filters.
- Permission count.
- Active member count.
- Unassigned-user warning.
- Responsive table/cards.
- Role Profile navigation.

## Profile
- Overview.
- General identity.
- Permissions.
- Permission search.
- Bulk enable/disable.
- Members / Impact.
- Audit history.
- Clone.
- Save.
- Delete.
- Responsive UX.

البنية:

\`\`\`
Role List
   ↓
Role Profile
   ├── Overview
   ├── Permissions
   ├── Members
   └── Audit
\`\`\`

---

# 13. Data Repair Decision

لم يتم تعديل:

\`mostafa@rawaea.com\`

لأن:

\`\`\`
role = موظف
role_id = NULL
\`\`\`

ولا يوجد Role Production مؤكد باسم \`موظف\`.

الحالة تظهر في الصفحة ولا يتم اختلاق تعيين.

---

# 14. Verification

## تم إثباته

- Current Mother HEAD = \`e08652c...\`
- Mother parent = \`3bc57c...\`
- آخر main.html-changing commit = \`3bc57c...\`
- Current main.html blob = \`ca40fd6...\`
- CTO main.html modification = 0.
- Production roles = 20.
- system roles = 3.
- custom roles = 17.
- users = 24.
- users without role_id = 1.
- broken role refs = 0.
- duplicate role names case-insensitive = 0.
- Role RLS company-scoped.
- save-role / delete-role / seed-roles deployed and authenticated.
- Role audit policy deployed.
- updated_at trigger deployed.
- Role audit performance index deployed.
- temporary role test cleaned completely.

## لم يثبت

- Live authenticated Browser E2E بعد Owner integration.
- Action-level CRUD authorization.
- Record Rules.
- Field-level permissions.
- Login-as / Simulator.
- Device/session management.

لا تُعلن هذه العناصر Closed في هذه الجلسة.

---

# 15. Closure Status

\`\`\`
RW_Roles forensic reconstruction       = CLOSED
RW_Roles Production infrastructure    = CLOSED
RW_Roles owner source patch            = READY
RW_Roles live browser runtime          = OPEN
RW_Roles 100% final closure            = OPEN UNTIL OWNER INTEGRATION + E2E
\`\`\`

---

# 16. جلسة الاستكمال التالية

لا تبدأ من الصفر.

ابدأ:

\`\`\`
CURRENT_STATE
↓
System HEAD + parent
↓
Mother HEAD + parent
↓
Current main.html blob
↓
Verify Owner surgeries A–F
↓
Source syntax gate
↓
Browser Production runtime
↓
Role List
↓
Search / Filter
↓
Role Profile
↓
Permissions
↓
Members
↓
Audit
↓
Clone
↓
Save
↓
Delete unused custom role
↓
Verify system role cannot delete
↓
Production reread
↓
Audit reread
↓
Close RW_Roles Browser Closure
↓
Open next independent Business Contract Unit
\`\`\`

لا تعيد RW_Users أو أي inventory/runsheet/delivery repair إلا عند Regression مثبت من Current Evidence.

---

# 17. Official benchmark sources

Odoo:
https://www.odoo.com/documentation/19.0/applications/general/users.html
https://www.odoo.com/documentation/19.0/developer/reference/backend/security.html

Dynamics 365 Business Central:
https://learn.microsoft.com/en-us/dynamics365/business-central/ui-security-groups
https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/security/data-security

SAP:
https://help.sap.com/docs/SAP_S4HANA_CLOUD/53e36b5493804bcdb3f6f14de8b487dd/b9fd81647cdf45f5ad462a50222c2caa.html
https://help.sap.com/docs/SAP_S4HANA_CLOUD/53e36b5493804bcdb3f6f14de8b487dd/f65e51a7203443efb58fe535c3d13e5f.html

Daftra:
https://docs.daftra.com/en/user_manual/employee-permissions-and-roles/
https://docs.daftra.com/en/tutorial/logging-in-as-an-employee/
https://docs.daftra.com/en/faq/how-can-an-employee-be-restricted-from-accessing-certain-branches-on-the-system/

Manager.io:
https://www2.manager.io/guides/33078
https://www2.manager.io/guides/9162

---

# END REPORT 248
