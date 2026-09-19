# RAWAEA ERP — RW_Users Add-User Failure
# التحقيق الجنائي + المقارنة التنافسية + التعديل الجراحي
## 2026-09-19

---

## 1. نطاق التنفيذ

النطاق محصور في:

**RW_Users — المستخدمين والصلاحيات**

العيب المستهدف:

`Uncaught ReferenceError: openModal is not defined`

الموضع الذي ظهر في Console:

`main:5333:55`

لم يتم تعديل `main.html` بواسطة CTO في هذه الجلسة. التعديل الوحيد المطلوب في `main.html` هو Owner surgical patch موضح حرفيًا في هذا التقرير.

لم يتم فتح أو تعديل دورة:

Order / Runsheet / Picking / Loading / Delivery / Return / Inventory

ولم يتم تغيير محرك الصلاحيات في Production دون دليل يثبت الحاجة.

---

## 2. مصدر الحقيقة الحالي

تم تجاوز التقارير السابقة باعتبارها Historical Evidence فقط، ثم إعادة المطابقة مع:

- Current System Git
- Current Mother Git
- Current Mother Source
- Current Production Database
- Current Production Edge Deployments
- Current runtime evidence
- Git parent/diff history

### System Repository

`papamohammed77-glitch/rawaie-erp-New`

Evidence baseline HEAD at investigation start:
`24e88b1909556c95c38cdfdd6d5aa1d94d033166`

Its parent:
`7cfc16aecd7ecdb6dde0774dd4ece7cf2cbbcea44`

Final System HEAD after this report, log and CURRENT_STATE commits:
`e7499fba1cfb119964abb00ef8939029a9909f0f`

Final System HEAD parent:
`1f8ed6228cedf5dedd368171686dc78dedbda22c`

The evidence baseline is the Production/source checkpoint used during the forensic investigation; subsequent System commits are documentation/state commits.

### Mother Repository

`papamohammed77-glitch/erp-frontend`

Current HEAD:
`b719017154beec8609a9f84f428fc64037672bce`

Parent:
`a24853414f3e2023a6e850c55ec652d660edcf9a`

Commit `b719017...` برسالة `forensic: persist current Mother HR extract` لا يغير `companies/company-1/main.html`؛ يغير فقط ملف forensic extract.

إذن آخر commit غيّر `main.html` فعليًا هو:
`a24853414f3e2023a6e850c55ec652d660edcf9a`

Parent:
`5da2121beef82840880276d254d8665468420332`

---

## 3. ماذا فعل آخر commit لـmain.html؟

Diff الخاص بـ`a248534...` أثبت أنه أصلح عيبين سابقين في RW_Users:

1. إزالة double escaping في أزرار Tabs.
2. إضافة `}` المفقودة قبل `return { ... }` لإغلاق `openUserPage`.

لم يغيّر هذا الـcommit handler الخاص بزر `btn-add-emp`.

وهنا بقي العيب الحالي.

---

## 4. Current Source — الدليل القاطع

Current Mother `main.html` blob:
`533d6afa77940228228e413a4df8dee2f0987592`

الحجم:
`1,511,535 bytes`

الـRW_Users module يبدأ عند line 5268 تقريبًا.

الـadd button handler الحالي عند lines 5331–5334:

```javascript
var addBtn = byId('btn-add-emp');
if (addBtn) {
    addBtn.addEventListener('click', function() { openModal(null); });
}
```

---

## 5. البحث الجنائي عن openModal

تم البحث داخل كامل وحدة RW_Users من بداية الوحدة حتى قبل بداية RW_Roles.

النتيجة:

**لا يوجد أي تعريف لـ `openModal` داخل RW_Users.**

في المقابل توجد دوال بنفس الاسم داخل IIFE مستقلة مثل RW_Customers وRW_Suppliers وRW_Branches وRW_Roles.

`RW_Roles` مثلًا يعرّف:

```javascript
function openModal(roleId) {
```

لكن هذا داخل:

```javascript
var RW_Roles = (function() {
    ...
})();
```

بينما المستخدمون داخل:

```javascript
var RW_Users = (function() {
    ...
})();
```

لذلك `RW_Roles.openModal` لا تدخل lexical scope لوحدة RW_Users.

---

## 6. نقطة الإثبات الأقوى

داخل RW_Users نفسها توجد الدالة الصحيحة:

```javascript
function openUserPage(email) {
```

وتُعاد من الـmodule:

```javascript
return {
    render: render,
    _openModal: openUserPage,
```

وفي أسفل Mother يوجد document click handler الصحيح:

```javascript
RW_Users._openModal(email);
```

إذن مسار Edit قائم بالفعل ولا يحتاج تغييرًا.

---

## 7. Root Cause النهائي

### الخطأ الحقيقي

**Old handler residue / stale symbol reference**

مسار Add User القديم بقي:

`openModal(null)`

بعد أن أصبح محرر المستخدم الحالي:

`openUserPage(email)`

بالتالي المسار الفعلي قبل الإصلاح:

```text
btn-add-emp
   ↓
RW_Users.render()
   ↓
click handler
   ↓
openModal(null)   ← UNDEFINED
```

والمسار الصحيح:

```text
btn-add-emp
   ↓
RW_Users.render()
   ↓
click handler
   ↓
openUserPage(null)
   ↓
RW_Users user editor
```

هذا يفسر Console error بالكامل.

---

## 8. لماذا لم يكن Parser Repair السابق هو الحل؟

لأن Parser Repair أغلق double escaping وmissing brace فقط.

Console يثبت أن النظام يصل إلى:

- Supabase Client initialized
- Session restored
- Bootstrap loaded
- System Ready

ثم يفشل عند click فقط.

إذن defect الحالي Runtime binding وليس parser/bootstrap failure.

---

## 9. Current Production — تحقق مستقل

Production الحالية أعيدت قراءتها مباشرة:

- users = **24**
- active_users = **24**
- roles = **20**
- wildcard_users = **1**
- users_without_role_id = **23**
- dangling_role_id = **0**
- active_customer_assignments = **0**

`users` تحتوي على company_id, email, name, role, permissions, status, phone, default_branch_id, allowed_branch_ids, expiry_date, role_id, auth_id, allow_all_customers, restrict_to_visit_day, device_id, active_warehouse_role.

`roles` تحتوي على company_id, role_name, permissions, is_system.

`owner_profile` موجود ويُستخدم للحفاظ على عقد Owner.

---

## 10. Production RLS وEdge

Production RLS الحالية تثبت company scoping للمستخدمين والأدوار وتعيينات العملاء.

Production Edge الحالية:

- save-employee version **10**, verify_jwt=true
- save-role version **9**, verify_jwt=true
- delete-employee version **4**, verify_jwt=true
- delete-role version **4**, verify_jwt=true

هذه القدرة الخلفية ليست سبب `openModal` ولا تحتاج Migration أو Edge patch في هذه الجراحة.

---

## 11. Current Users/Permissions Contract

RW_Users الحالية تحتوي بالفعل على:

- users listing
- company-scoped users
- company-scoped roles
- branch loading
- status
- expiry
- role + role_id
- role permissions
- direct permissions
- customer assignments
- visit-day control
- allowed branches
- warehouse role
- Owner handling
- disable user
- audit-backed backend operations

لذلك لا يوجد مبرر لإعادة بناء Users module من الصفر.

---

## 12. المقارنة التنافسية

### Odoo 19

Odoo يربط المستخدمين بالمجموعات، ثم يدعم Access Rights للـCRUD، وRecord Rules، وField-level restrictions، وMulti-company، وأجهزة المستخدم وإلغاء جلسات الأجهزة.

المصادر الرسمية:

https://www.odoo.com/documentation/19.0/applications/general/users.html
https://www.odoo.com/documentation/19.0/developer/reference/backend/security.html
https://www.odoo.com/documentation/19.0/applications/general/companies/multi_company.html

### Dynamics 365 Business Central

يعتمد على Users وSecurity Groups وPermission Sets، مع إمكانية ربط صلاحيات بمجموعات وإسناد Permission Sets على مستوى شركة.

https://learn.microsoft.com/en-us/dynamics365/business-central/ui-security-groups
https://learn.microsoft.com/en-us/dynamics365/business-central/application/base-application/page/system.security.accesscontrol.permission-sets

### SAP S/4HANA Cloud

يعتمد على Business Roles وBusiness Catalogs وRestrictions، مع Read وWrite وValue Help ونطاقات تنظيمية.

https://help.sap.com/docs/SAP_S4HANA_CLOUD/53e36b5493804bcdb3f6f14de8b487dd/c926d691d7144f7dba16f8e12ad81d28.html

### Daftra

يوفر Users/Employees وRoles وAccessible Branches وRestricted Pages وActive/Inactive وLogin as.

https://docs.daftra.com/en/user_manual/employee-permissions-and-roles/
https://docs.daftra.com/en/tutorial/adding-a-new-user/
https://docs.daftra.com/en/faq/how-can-an-employee-be-restricted-from-accessing-certain-branches-on-the-system/
https://docs.daftra.com/en/tutorial/logging-in-as-an-employee/

### Manager.io

يوفر Restricted Users وUser Permissions بمستويات View وView/Create وView/Create/Update وView/Create/Update/Delete.

https://www2.manager.io/guides/33078

---

## 13. Capability Gaps الحقيقية

هذه gaps تنافسية/وظيفية منفصلة عن Bug الحالي، ولا يجوز خلطها مع الجراحة الحالية:

1. Generic CRUD matrix: View / Create / Update / Delete / Approve / Export / Execute.
2. Generic row-level record rules.
3. Generic field-level permissions.
4. Permission simulator / Login-as.
5. Device/session management UI.
6. Audit history viewer داخل user profile.
7. Policy inheritance abstraction أكثر عمومية من legacy role-name compatibility.

هذه Closure Units مستقلة؛ لم يتم اختراع Schema جديد لها داخل هذه الجراحة لأن ذلك سيكون توسعًا غير مثبت على سبب العطل.

---

## 14. التعديل الجراحي المطلوب — OWNER ONLY

### Surgery U-01

**File:** `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

**Current blob:** `533d6afa77940228228e413a4df8dee2f0987592`

**Module:** `RW_Users`

**Function:** `async function render()`

**Lines:** 5331–5334

### ابحث حرفيًا عن:

```javascript
var addBtn = byId('btn-add-emp');
if (addBtn) {
    addBtn.addEventListener('click', function() { openModal(null); });
}
```

### احذف البلوك كاملًا واستبدله بـ:

```javascript
var addBtn = byId('btn-add-emp');
if (addBtn) {
    addBtn.addEventListener('click', function() {
        openUserPage(null);
    });
}
```

### لا تعدل

- openUserPage(email)
- return mapping `_openModal: openUserPage`
- document click handler
- RW_Roles
- save-employee
- save-role
- RLS
- DB schema

---

## 15. لماذا هذا البديل هو الصحيح؟

`openUserPage` موجودة داخل نفس lexical scope لـRW_Users، وFunction Declaration hoisting يجعلها متاحة وقت click.

`null` تدخل Create Mode لأن داخل الدالة:

```javascript
var isEdit = !!emp;
```

وبالتالي:

`email = null → emp = null → isEdit = false → إضافة مستخدم جديد`

---

## 16. ممنوع الالتفاف

لا تستبدل `openModal` بــ:

- window.openModal
- RW_Roles._openModal
- global function جديدة باسم openModal

ولا تُنشئ alias عامًا يخفي المشكلة.

العقد الصحيح هو:

**RW_Users → openUserPage**

---

## 17. Regression Guard

بعد Owner patch يجب أن تصبح نتائج البحث داخل RW_Users:

```text
openModal(null) = 0
openUserPage(null) = 1
function openUserPage(email) = 1
```

ويظل:

`RW_Users._openModal(email)`

هو مسار Edit.

---

## 18. Verification Gate

بعد تطبيق U-01:

1. افتح Mother.
2. سجل الدخول.
3. افتح المستخدمين والصلاحيات.
4. اضغط إضافة مستخدم.
5. تحقق من فتح إضافة مستخدم جديد.
6. افتح تبويب البيانات الأساسية.
7. افتح تبويب الصلاحيات.
8. افتح تبويب إعدادات الميدان.
9. في مستخدم موجود اختبر العملاء المسموحين.
10. ارجع للقائمة وافتح مستخدمًا موجودًا.
11. تحقق من عدم وجود ReferenceError أو PageError.
12. اختبر save user.
13. أعد قراءة Production.
14. تحقق من audit.

---

## 19. GitHub Actions الحالية

آخر Mother browser E2E run على `a248534...`:

`35425989459`

النتيجة: **failure**

لكن الـjob فشل في خطوة:

`Assert canonical payroll syntax in Mother source`

قبل Playwright browser stage.

إذن هذا الـfailure ليس دليلًا على فشل RW_Users.

وفي المقابل run:

`35425989464`

لـ`RAWAEA CTO — published main.html full forensic gate` على نفس `a248...` كان **success**.

---

## 20. Production Action

**لم يتم تعديل Production في هذه الجراحة.**

السبب:

الخطأ يحدث قبل أي call إلى save-employee أو save-role أو Supabase users write.

لا توجد بنية Production ناقصة مطلوبة لإصلاحه.

---

## 21. SELF-AUDIT

### What I Proved

- Current Mother HEAD مختلف عن checkpoint القديم.
- b719 لا يغير main.html.
- a248 هو آخر commit غيّر main.html.
- current main.html blob = 533d6afa...
- لا يوجد openModal داخل RW_Users.
- line 5333 يستدعي openModal(null).
- openUserPage موجودة داخل RW_Users.
- `_openModal` مربوط بـopenUserPage.
- sibling openModal لا تدخل lexical scope.
- Production Users/Roles/Auth backend موجود.
- لا توجد Production migration مطلوبة.

### What I Did Not Prove

- Live Browser interaction بعد Owner patch لم تُنفذ.
- save/edit Browser Production بعد Owner patch لم تُنفذ.
- competitor feature parity ليست 100%، بل توجد capability gaps مستقلة.

### What I Fixed

- تم تحديد السبب الجذري بدليل source مباشر.
- تم تحديد surgical replacement الوحيد اللازم.
- تم رفض الحلول الالتفافية.
- تم تحديث سجل التنفيذ والحالة.

### Final Closure

```text
RW_Users backend integrity        = VERIFIED
RW_Users current source           = VERIFIED
openModal root cause              = PROVEN
Owner surgical patch              = READY
Browser Production verification   = OPEN
RW_Users final closure             = OPEN
```

---

## 22. إرشادات الجلسة التالية

ابدأ من:

```text
CURRENT_STATE
↓
Mother HEAD + parent
↓
current main.html blob
↓
Surgery U-01 status
↓
Browser E2E
↓
Production user create/edit verification
↓
Audit verification
```

لا تعيد parser repair أو أي جراحة أُغلقت تاريخيًا إلا إذا أثبت Current Evidence regression جديدًا.

بعد نجاح U-01 فقط افتح أقرب Capability Gap مستقل.

---

## 23. قاعدة حاكمة

لا تستخدم `openModal` كحل عام داخل RW_Users.

عقد RW_Users الحالي:

```text
RW_Users
    |
    +-- render()
    |
    +-- openUserPage(email)
    |
    +-- _openModal = openUserPage
    |
    +-- save-employee
```

## End of Report