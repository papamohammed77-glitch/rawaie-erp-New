# Report144 — CTO First E2E للنظام الأم — Forensic Syntax Closure

**التاريخ:** 2026-09-12  
**نطاق الجلسة:** أول تجربة E2E لملف النظام الأم المنشور فقط.  
**قاعدة الحوكمة:** لا ثقة عمياء في التقارير؛ المصدر الفعلي هو الملف المنشور في Production repository، مع مراجعة التاريخ والسياق قبل أي قرار.

---

## 1. نقطة الحوكمة الحاسمة

الهدف هنا ليس إصلاح شاشة دخول بصورة منفصلة، ولا تعديل ملف تاريخي، ولا إعادة بناء `main.html` من الأجزاء القديمة.

الهدف هو:

```text
ERP Frontend Published Main
→ Parse كامل
→ Boot كامل
→ Login
→ Post-login bootstrap
→ ثم E2E الوظيفي
```

وتم اعتماد الملف التالي وحده كمصدر الحقيقة:

```text
erp-frontend/companies/company-1/main.html
```

أما:

```text
rawaie-erp-New/Current/PWA/main2/main1..main11.md
```

فهي مواد تاريخية/استرشادية فقط وليست Source of Truth.

---

## 2. المصادر التي تمت مراجعتها

تمت مراجعة:

1. `doc/Draft/Reprots/MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`
2. `doc/Draft/Reprots/Report143_CTO_Helper_Files_Integration_20260912.md`
3. `CURRENT_STATE.md`
4. الملف المنشور فعليًا:
   `erp-frontend/companies/company-1/main.html`
5. سجل Git الحديث للمستودع المنشور.
6. Workflow الخاص بالتحقق الجنائي:
   `.github/workflows/forensic_main_assembly.yml`
7. الحالة الفعلية لنتيجة GitHub Actions الخاصة بالملف المنشور.
8. أجزاء `Current/PWA/main2` كمصدر تاريخي فقط للمقارنة عند الحاجة.

لم يتم استخدام تقرير سابق باعتباره حقيقة نهائية دون مطابقة الملف المنشور فعليًا.

---

## 3. إثبات Source of Truth

الـWorkflow:

```text
.github/workflows/forensic_main_assembly.yml
```

يتعامل صراحة مع الرابط:

```text
https://raw.githubusercontent.com/papamohammed77-glitch/erp-frontend/main/companies/company-1/main.html
```

ويؤكد أن الأجزاء التاريخية و`New-main` ليست مصدر إعادة البناء.

**النتيجة:**

```text
ASSEMBLY SOURCE OF TRUTH = CORRECT
ASSEMBLY PATH = CORRECT
```

تم إجراء تعديل تشخيصي مؤقت على الـworkflow لاستخراج نافذة الخطأ، ثم تمت إعادته إلى صورته الحاكمة الأصلية بعد انتهاء التشخيص حتى لا يبقى أي أثر تنفيذي غير مطلوب.

---

## 4. الحالة الفعلية للملف المنشور

النسخة المنشورة الحالية من `main.html` تم التحقق منها مباشرة عبر الـraw source ونتيجة الـCI.

القياسات المثبتة في الـforensic run:

```text
BYTES = 933388
LINES = 17415
EOF = </script> + </body> + </html>
HTML OPEN/CLOSE = 1/1
HEAD OPEN/CLOSE = 1/1
BODY OPEN/CLOSE = 1/1
SCRIPT OPEN/CLOSE = 6/6
INCOMPLETE MARKERS = []
INLINE_JS_BLOCKS = 1
```

أي أن المشكلة ليست غياب `</html>` في النسخة الحالية؛ هذه النقطة كانت واردة في `CURRENT_STATE` القديم، لكنها لم تعد صحيحة بعد مطابقة الملف الفعلي الحالي.

---

## 5. إثبات الخطأ الحالي

نتيجة الـforensic syntax gate الحالية أعادت:

```text
/tmp/published-main-positioned.js:5261
        });
         ^
SyntaxError: Unexpected token ')'
```

وهذا يتطابق مع Console الذي قدمه المستخدم:

```text
main:5261 Uncaught SyntaxError: Unexpected token ')'
```

وبالتالي أصبح الخطأ **مثبتًا مستقلًا من Production source + GitHub Actions** وليس مجرد ملاحظة Browser.

---

## 6. الأثر على شاشة الدخول

تم التحقق من وجود تهيئة عميل Supabase في `main.html`، كما تم التحقق من وجود مسار:

```javascript
RW_SUPABASE_CLIENT.auth.signInWithPassword(...)
```

لكن وجود خطأ JavaScript parsing على مستوى الـinline script يمنع تنفيذ السكربت نفسه قبل الوصول إلى أي runtime logic.

وعليه:

```text
Syntax Parse Failure
        ↓
Inline JS لا يبدأ
        ↓
Login handler لا يعمل
        ↓
شاشة الدخول لا تتجاوز
```

إذن عدم تجاوز شاشة الدخول **عرض تابع مباشر لخطأ SyntaxError**، وليس دليلًا بحد ذاته على فساد Authentication أو Supabase credentials.

---

## 7. تحديد موضع الإصلاح الجراحي

الدالة المستهدفة هي:

```text
RW_Roles.openModal(roleId)
```

في الملف المنشور الحالي.

بداية الدالة:

```text
السطر 5088
```

ونهاية الكتلة الحالية:

```text
السطر 5262
```

والسطر الذي يرفضه parser هو:

```text
السطر 5261
```

ونصه الحالي حرفيًا:

```javascript
        });
```

ثم يأتي مباشرة:

```javascript
    }

    function _switchRoleTab(tabId) {
```

### لماذا لم يتم الاكتفاء بحذف السطر 5261؟

لأن نتيجة parser تثبت أن كتلة `openModal` المجمعة فقدت سلامة الإغلاق، لكنها لا تثبت من هذا الخط وحده أي قوس/إغلاق داخلي هو السبب الأصلي.

لذلك تم اعتماد إصلاح جراحي آمن على مستوى **الدالة الكاملة فقط**، وليس حذف قوس منفرد بالتخمين.

---

## 8. Owner ChangeSet — المطلوب تطبيقه على النظام الأم

### مكان التعديل

في:

```text
erp-frontend/companies/company-1/main.html
```

### ابحث عن بداية العنصر التالي حرفيًا

```javascript
    function openModal(roleId) {
```

وذلك في حدود السطر:

```text
5088
```

### احذف الكتلة كاملة

احذف `openModal(roleId)` الحالية كاملة، من هذا السطر:

```javascript
    function openModal(roleId) {
```

حتى السطر الذي يسبق مباشرة:

```javascript
    function _switchRoleTab(tabId) {
```

أي لا تترك أي جزء من الدالة الحالية.

### استبدلها كاملة بالنص التالي

```javascript
    function openModal(roleId) {
        var role = roleId ? rolesData.find(function(r) { return r.id == roleId; }) : null;
        var isEdit = !!role;
        var title = isEdit ? 'تعديل دور' : 'إضافة دور جديد';

        var appPerms = [
            { key: 'pos', label: 'نقطة البيع (POS)' },
            { key: 'telesales', label: 'التلي سيلز' },
            { key: 'orders', label: 'الأوردرات (مندوب المبيعات)' },
            { key: 'van-sales', label: 'فان سيلز' },
            { key: 'sales_supervisor', label: 'مشرف المبيعات' },
            { key: 'warehouse_supervisor', label: 'مشرف المخازن' },
            { key: 'warehouse', label: 'عمال المخازن (استلام/تحضير/تحميل...)' },
            { key: 'delivery', label: 'مندوب التوصيل' },
            { key: 'delivery_supervisor', label: 'مشرف التوصيل' },
            { key: 'purchases', label: 'مسؤول المشتريات' },
            { key: 'purchases_supervisor', label: 'مشرف المشتريات' },
            { key: 'finance', label: 'المحاسب' },
            { key: 'online-store', label: 'المتجر الإلكتروني' },
            { key: 'sales_manager', label: 'مدير المبيعات' },
            { key: 'warehouse_manager', label: 'مدير المخازن' },
            { key: 'finance_manager', label: 'المدير المالي' },
            { key: 'general_manager', label: 'المدير العام' },
            { key: 'hr', label: 'الموارد البشرية' }
        ];

        var erpPerms = [
            { key: 'dash', label: 'لوحة التحكم' },
            { key: 'items', label: 'الأصناف والمخزون' },
            { key: 'stock_adjustment', label: 'تحديث الأرصدة (تسوية)' },
            { key: 'customers', label: 'العملاء' },
            { key: 'suppliers', label: 'الموردين' },
            { key: 'branches', label: 'الفروع والمخازن' },
            { key: 'runsheets', label: 'الرانشيتات' },
            { key: 'receiving', label: 'سجل الاستلام' },
            { key: 'picking', label: 'سجل التحضير' },
            { key: 'loading', label: 'سجل التحميل' },
            { key: 'return', label: 'سجل المرتجعات' },
            { key: 'unloading', label: 'سجل التفريغ' },
            { key: 'vouchers', label: 'الأذونات المخزنية' },
            { key: 'transfer', label: 'تحويل مخزني' },
            { key: 'direct-sale', label: 'صرف سيارة بيع مباشر' },
            { key: 'direct-return', label: 'استلام مرتجع سيارة' },
            { key: 'supplier-return', label: 'مرتجع لمورد' },
            { key: 'vehicle-count', label: 'جرد سيارة' },
            { key: 'branch-count', label: 'جرد فرع' },
            { key: 'general-count', label: 'جرد عام' },
            { key: 'reports', label: 'التقارير' },
            { key: 'users', label: 'المستخدمين والصلاحيات' },
            { key: 'roles', label: 'إدارة الأدوار' },
            { key: 'settings', label: 'إعدادات النظام' },
            { key: 'settlement', label: 'إغلاق اليومية' }
        ];

        function buildCheckboxes(list) {
            var h = '<div class="grid grid-cols-2 md:grid-cols-3 gap-2 mt-2">';
            for (var i = 0; i < list.length; i++) {
                var p = list[i];
                var checked = '';
                if (role && role.permissions && role.permissions.indexOf(p.key) !== -1) {
                    checked = ' checked';
                }
                h += '<label class="flex items-center gap-2 text-sm cursor-pointer hover:bg-gray-50 p-1 rounded">';
                h += '<input type="checkbox" value="' + p.key + '"' + checked + ' class="role-perm-checkbox">';
                h += ' ' + p.label;
                h += '</label>';
            }
            h += '</div>';
            return h;
        }

        var appHTML = buildCheckboxes(appPerms);
        var erpHTML = buildCheckboxes(erpPerms);

        var html =
            '<div class="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50" dir="rtl">' +
            '<div class="bg-white rounded-2xl shadow-2xl w-full max-w-2xl overflow-hidden">' +
            '<div class="bg-indigo-600 px-6 py-4 flex justify-between text-white">' +
            '<h3 class="text-xl font-bold"><i class="fas fa-user-shield ml-2"></i>' + title + '</h3>' +
            '<button type="button" onclick="Swal.close()"><i class="fas fa-xmark text-xl"></i></button>' +
            '</div>' +
            '<form class="p-6 space-y-6" style="max-height:70vh;overflow-y:auto" onsubmit="return false;">' +
            '<input type="hidden" id="role-id-hidden" value="' + (role ? (role.id || '') : '') + '">' +
            '<div class="flex flex-col"><label class="text-sm font-bold">اسم الدور *</label><input id="role-name" value="' + (role ? (role.role_name || '') : '') + '" class="p-2.5 bg-gray-50 border rounded-lg"></div>' +
            '<div class="flex flex-col"><label class="text-sm font-bold">الوصف</label><input id="role-desc" value="' + (role ? (role.description || '') : '') + '" class="p-2.5 bg-gray-50 border rounded-lg"></div>' +
            '<div>' +
            '<div class="flex border-b mb-4">' +
            '<button type="button" onclick="RW_Roles._switchRoleTab(\'apps\')" class="px-4 py-2 font-bold text-sm border-b-2 border-blue-600 text-blue-600" id="role-tab-apps">📱 صلاحيات التطبيقات</button>' +
            '<button type="button" onclick="RW_Roles._switchRoleTab(\'erp\')" class="px-4 py-2 font-bold text-sm text-gray-500" id="role-tab-erp">🏢 صلاحيات النظام الأم</button>' +
            '</div>' +
            '<div id="role-panel-apps">' + appHTML + '</div>' +
            '<div id="role-panel-erp" class="hidden">' + erpHTML + '</div>' +
            '</div>' +
            '<div class="flex justify-end gap-3 pt-4 border-t">' +
            (isEdit && !role.is_system ? '<button type="button" id="btn-delete-role" class="px-5 py-2.5 bg-red-600 text-white rounded-xl font-bold mr-auto"><i class="fas fa-trash-alt ml-1"></i> حذف الدور</button>' : '') +
            (isEdit && role.is_system ? '<span class="px-4 py-2.5 bg-slate-100 text-slate-500 rounded-xl font-bold mr-auto"><i class="fas fa-lock ml-1"></i> دور نظامي</span>' : '') +
            '<button type="button" class="px-5 py-2.5 border rounded-xl font-bold" onclick="Swal.close()">إلغاء</button>' +
            '<button type="button" id="btn-save-role" class="px-6 py-2.5 bg-indigo-600 text-white rounded-xl font-bold">حفظ</button>' +
            '</div></form></div></div>';

        Swal.fire({
            html: html,
            width: '700px',
            showConfirmButton: false,
            showCancelButton: false,
            customClass: { popup: '!bg-transparent !shadow-none !p-0' },
            didOpen: function() {
                var saveBtn = byId('btn-save-role');
                if (saveBtn) {
                    saveBtn.addEventListener('click', async function() {
                        var nameEl = byId('role-name');
                        var descEl = byId('role-desc');
                        var name = nameEl ? nameEl.value.trim() : '';
                        if (!name) {
                            showToast('اسم الدور مطلوب', 'error');
                            return;
                        }

                        var selectedPerms = [];
                        var checkboxes = document.querySelectorAll('.role-perm-checkbox:checked');
                        for (var i = 0; i < checkboxes.length; i++) {
                            selectedPerms.push(checkboxes[i].value);
                        }

                        var payload = {
                            id: role ? role.id : null,
                            role_name: name,
                            description: descEl ? descEl.value.trim() : '',
                            permissions: selectedPerms,
                            is_system: role ? (role.is_system || false) : false
                        };

                        showLoader('جاري الحفظ...');
                        var sessionRes = await supabase.auth.getSession();
                        var token = sessionRes.data.session ? sessionRes.data.session.access_token : null;
                        if (!token) {
                            hideLoader();
                            showToast('جلسة غير صالحة', 'error');
                            return;
                        }

                        try {
                            var res = await fetch(RW_SUPABASE_URL + '/functions/v1/save-role', {
                                method: 'POST',
                                headers: {
                                    'Content-Type': 'application/json',
                                    Authorization: 'Bearer ' + token
                                },
                                body: JSON.stringify(payload)
                            });
                            var json = await res.json();
                            hideLoader();

                            if (json.success) {
                                showToast(isEdit ? 'تم التعديل' : 'تمت الإضافة', 'success');
                                Swal.close();

                                var refreshedRoles = await supabase.from('roles')
                                    .select('*')
                                    .eq('company_id', _rwCompanyId())
                                    .order('created_at', { ascending: true });

                                if (refreshedRoles.error) {
                                    showToast('تم الحفظ لكن تعذر تحديث قائمة الأدوار', 'warning');
                                    return;
                                }

                                rolesData = refreshedRoles.data || [];
                                renderTable(rolesData);
                            } else {
                                showToast(json.error || 'فشل الحفظ', 'error');
                            }
                        } catch (e) {
                            hideLoader();
                            showToast('فشل الاتصال بـ Edge Function', 'error');
                        }
                    });
                }

                if (!isEdit) return;
                var deleteBtn = byId('btn-delete-role');
                if (!deleteBtn) return;

                deleteBtn.addEventListener('click', async function() {
                    var confirmResult = await Swal.fire({
                        title: 'تأكيد الحذف',
                        text: 'حذف هذا الدور؟',
                        icon: 'warning',
                        showCancelButton: true,
                        confirmButtonText: 'حذف',
                        cancelButtonText: 'إلغاء'
                    });

                    if (!confirmResult.isConfirmed) return;
                    showLoader('جاري الحذف...');

                    var sessionRes = await supabase.auth.getSession();
                    var token = sessionRes.data.session ? sessionRes.data.session.access_token : null;
                    if (!token) {
                        hideLoader();
                        showToast('جلسة غير صالحة', 'error');
                        return;
                    }

                    try {
                        var res = await fetch(RW_SUPABASE_URL + '/functions/v1/delete-role', {
                            method: 'POST',
                            headers: {
                                'Content-Type': 'application/json',
                                Authorization: 'Bearer ' + token
                            },
                            body: JSON.stringify({ roleId: role.id })
                        });

                        var json = await res.json();
                        hideLoader();

                        if (json.success) {
                            showToast('تم الحذف', 'success');
                            Swal.close();

                            var dRes = await supabase.from('roles')
                                .select('*')
                                .eq('company_id', _rwCompanyId())
                                .order('created_at', { ascending: true });

                            rolesData = dRes.data || [];
                            renderTable(rolesData);
                        } else {
                            showToast(json.error || 'فشل الحذف', 'error');
                        }
                    } catch (e) {
                        hideLoader();
                        showToast('فشل الاتصال بـ Edge Function', 'error');
                    }
                });
            }
        });
    }
