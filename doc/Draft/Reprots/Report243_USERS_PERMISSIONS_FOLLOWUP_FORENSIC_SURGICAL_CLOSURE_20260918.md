# RAWAEA ERP — تقرير 243
## RW_Users / المستخدمون والصلاحيات — متابعة جنائية وجراحة دقيقة
### التاريخ: 2026-09-18

> **نطاق هذه الوحدة:** تبويب المستخدمين والصلاحيات `RW_Users` فقط.  
> **main.html:** لم يُعدَّل بواسطة CTO.  
> **قاعدة الحقيقة:** CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.  
> التقارير السابقة استُخدمت كخرائط تاريخية فقط، ولم تُعامل كحالة حالية.

---

## 1. نقطة الاستئناف المثبتة

تمت إعادة بناء الحالة قبل أي تعديل من:

- `CURRENT_STATE.md`
- `MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`
- أحدث سجل تنفيذ Users/Permissions.
- آخر commits وparents في System repository.
- آخر commits وparents في Mother repository.
- الـblob الفعلي الحالي لـ`companies/company-1/main.html`.
- Production Supabase schema/data/RLS/functions.
- Production Edge Function deployments.
- المصادر التاريخية المرتبطة بـRW_Users.
- الوثائق الرسمية للمقارنة مع Odoo / Dynamics 365 / SAP Business One / Daftra / Manager.io.

### System Git — قبل إصلاحات هذه الوحدة

`papamohammed77-glitch/rawaie-erp-New`

- نقطة الحالة السابقة: `f3c15bac375dfca129e6814603867eed5b53117b`
- parent: `4cabe17b46491c25c957a2662e65e9c05fe3248a`

### Mother Git — آخر حقيقة قبل هذه الجلسة

`papamohammed77-glitch/erp-frontend`

- أحدث HEAD المرئي: `6f37b88b19e11d2885cfd9b51cc3992d81b5ac47`
- parent: `55271f8b65c6121085d209b090d2d67117ef9c3e`
- commit `55271f8b65c6121085d209b090d2d67117ef9c3e` هو آخر commit غيّر `companies/company-1/main.html`.
- parent لذلك commit: `033a5386930cee0d306a3a398a402066e596dfe`
- current `main.html` blob: `68ee9c23c876209364f405eed3d23a0c33f9d0ce`
- commit `6f37b8...` كان forensic extract لاحقًا ولم يغيّر `main.html`.

---

# 2. ما الذي ثبت أنه أُنجز بالفعل قبل هذه المتابعة

commit `55271f8b65c6121085d209b090d2d67117ef9c3e` نقل مجموعة الجراحات السابقة إلى Mother، ومنها:

1. Owner filter وفق wildcard semantics.
2. fail-closed عند فشل تحميل users.
3. fail-closed عند فشل تحميل roles.
4. إزالة fake role fallback.
5. البحث بالاسم والبريد والهاتف والدور.
6. إضافة صلاحية `stock_adjustment`.
7. حفظ custom permissions الإضافية مع صلاحيات الدور.
8. استرجاع حالة custom-permission toggle.
9. تغيير الإجراء من Delete إلى Deactivate.

**هذه العناصر لم تُكرر ولم تُعاد معالجتها.**

---

# 3. الاكتشافان الجديدان في CURRENT Mother Source

## DEFECT-01 — خطأ Parser داخل `RW_Users.openModal()`

### الملف

`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

### الموضع

global line ~5694 في الـblob الحالي:

`68ee9c23c876209364f405eed3d23a0c33f9d0ce`

### العنصر المعيب

ابحث عن النص الحرفي:

```javascript
'<div id="emp-panel-field" class="hidden">' +
    '<div class="mb-2 text-xs text-gray-500">' +
    'صلاحيات الدور تُطبق تلقائيًا. الاختيارات التالية هي الإضافات المباشرة لهذا المستخدم.' +
    '</div>'
    '<div class="space-y-4 p-4 bg-amber-50 rounded-xl border border-amber-200">' +
```

### سبب العيب

السلسلة النصية `'</div>'` لم يتبعها عامل concatenation `+`، وبالتالي ينكسر بناء تعبير `var html = ...` ويصبح الـJavaScript غير صالح.

### تعليمات المالك

**ابحث عن العنصر أعلاه واحذفه فقط.**

### البديل الكامل الجاهز

```javascript
'<div id="emp-panel-field" class="hidden">' +
    '<div class="mb-2 text-xs text-gray-500">' +
    'صلاحيات الدور تُطبق تلقائيًا. الاختيارات التالية هي الإضافات المباشرة لهذا المستخدم.' +
    '</div>' +
    '<div class="space-y-4 p-4 bg-amber-50 rounded-xl border border-amber-200">' +
    '<h4 class="font-black text-amber-700"><i class="fa-solid fa-truck-fast ml-2"></i>إعدادات الصلاحيات الميدانية</h4>' +
    '<div class="grid grid-cols-1 gap-4">' +
```

> **ملاحظة:** استُخدم نفس البناء الوظيفي الحالي؛ لا تُغيّر بقية modal.

---

## DEFECT-02 — سقوط صلاحية `items` من قائمة RW_Users

### الملف

نفس `main.html`.

### الموضع

global line ~5530.

### العنصر المعيب

ابحث عن هذا الجزء:

```javascript
{ key: 'dash', label: '🏢 لوحة التحكم' },
{ key: 'stock_adjustment', label: '🏢 تحديث الأرصدة (تسوية)' },
{ key: 'customers', label: '🏢 العملاء' },
```

### سبب العيب

commit `55271f8...` استبدل `items` بـ`stock_adjustment` بدل إضافة `stock_adjustment` إلى القائمة، فأصبحت صلاحية الأصناف والمخزون غير قابلة للاختيار من RW_Users رغم بقائها موجودة في RW_Roles وProduction.

### تعليمات المالك

**ابحث عن العناصر الثلاثة أعلاه واحذفها فقط.**

### البديل الكامل الجاهز

```javascript
{ key: 'dash', label: '🏢 لوحة التحكم' },
{ key: 'items', label: '🏢 الأصناف والمخزون' },
{ key: 'stock_adjustment', label: '🏢 تحديث الأرصدة (تسوية)' },
{ key: 'customers', label: '🏢 العملاء' },
```

---

# 4. Production Backend — ما تم إغلاقه مباشرة

## 4.1 save-role — Dynamic Role Propagation

### Production

- Edge Function: `save-role`
- version: **9**
- `verify_jwt=true`
- deployment SHA256:
  `cd4eb540120d165da4f32465ac9825152d7360a703f0e9d2e2cec497b6ee67be`

### التغيير

عند تحديث الدور:

`Role`

→ تحديد أعضاء الدور بـ`role_id` أو الدور النصي التاريخي

→ الاحتفاظ بالـdirect user permissions

→ إعادة تركيب effective permissions

→ تحديث `users.role_id`

→ تحديث `users.permissions`

→ مزامنة Auth metadata

→ Audit

→ rollback تعويضي عند فشل sync.

### الهدف

إغلاق الفجوة التي كانت تسمح بتغيير Role دون مزامنة المستخدمين النشطين مع صلاحيات الدور الجديدة.

### System Source

`Current/Edge_Functions/save-role`

تم مزامنته مع Production عبر:

`ecd9afcf462991cdfe107264df90bc51f96e096a`

---

## 4.2 save-employee — Canonical Role Identity + Explicit Password

### Production

- Edge Function: `save-employee`
- version: **10**
- `verify_jwt=true`
- deployment SHA256:
  `f1ff0999d1e5bef8423ebeaff580e35d16da505134a09087054725bb89480e75`

### التغيير

- منع fallback كلمة المرور `123456`.
- كلمة المرور مطلوبة عند إنشاء مستخدم جديد.
- الدور يجب أن يكون موجودًا داخل نفس الشركة.
- حفظ `role_id` canonical.
- الاحتفاظ بـrole permissions + direct permissions.
- rollback DB/Auth عند فشل العملية أو الـaudit.

### System Source

`Current/Edge_Functions/save-employee`

تمت مزامنته عبر:

`f660a937d16be05e470ec2e94cb3dba8584ffc8e`

---

## 4.3 bulk-stock-adjustment — Backend Permission Enforcement

### Production

- Edge Function: `bulk-stock-adjustment`
- version: **7**
- `verify_jwt=true`
- deployment SHA256:
  `18439000f1e138b56af0b33013729a9ccc469f9b4cf49e9c9bf1bb0c8d3e9a76`

### التغيير

قبل تنفيذ التسوية:

- actor يُستخرج من `users.auth_id`.
- company_id يُستخرج من actor.
- owner semantics = isOwner + `permissions:["*"]` + `owner_profile`.
- non-owner يحتاج `stock_adjustment`.
- branch company-scoped.
- item company-scoped.
- التنفيذ النهائي يستمر عبر `post_inventory_adjustment_atomic`.

### System Source

تم إنشاء المصدر canonical:

`Current/Edge_Functions/bulk-stock-adjustment`

عبر:

`08628e01d75fe50ddbde0617c669132322e1b290`

---

# 5. Production Final Snapshot

تمت إعادة القراءة بعد النشر:

- companies = **1**
- active_branches = **2**
- users = **24**
- active_users = **24**
- roles = **20**
- stock_branches = **20**
- inventory_log = **3**
- audit_log = **1993**
- users_without_role_id = **23**
- unused_roles = **4**

لم يتغير عدد سجلات الأعمال نتيجة هذه الجراحة.

---

# 6. Production User/Role Integrity

الحالة الفعلية:

- `owner@alrawae.com` هو Owner الوحيد حسب العقد المثبت.
- Owner semantics لم تتغير.
- 23 مستخدمًا ما زالوا بدون `role_id`.
- لا يوجد dangling role_id.
- لا يوجد cross-company role_id.
- المستخدمون التاريخيون المرتبطون بالدور النصي ما زالوا يطابقون صلاحيات أدوارهم.
- `mostafa@rawaea.com` ما زال:
  - role = `موظف`
  - role_id = NULL
  - لا يوجد Role مطابق بهذا الاسم
  - permissions = []
- **لم يتم اختراع Role أو تعيين Role لـMostafa بالتخمين.**
- لا يوجد Role في Production يحمل `stock_adjustment` حتى الآن.

---

# 7. لماذا لا تم إضافة stock_adjustment إلى Role الآن؟

لأن Production نفسها تثبت أن هذا key غير موجود في أي Role.

هذا يجعل إضافة الصلاحية إلى Role بعينه قرارًا تشغيليًا جديدًا، وليس إصلاحًا لخلل مثبت.

لذلك:

- أُضيفت `stock_adjustment` إلى RW_Users كصلاحية مباشرة قابلة للإسناد.
- فُرضت في backend.
- لم يتم منحها لأي Role Production بالتخمين.

---

# 8. Audit / Authorization

Production الحالي يحتوي:

`app_private.current_user_company_id()`

و

`app_private.current_user_has_permission(p_permission)`

وهو يطبق:

- Owner wildcard semantics.
- user permission.
- role permission.
- company context.

تم الحفاظ على هذا العقد ولم يتم استبداله بمحرك صلاحيات جديد.

---

# 9. المقارنة مع الأنظمة المنافسة

## Odoo

Odoo 19 يفصل بين:

- Users.
- Groups.
- Access Rights للـCRUD.
- Record Rules.
- Field-level Groups.
- Multi-company access.
- User devices / revoke devices.

المصادر الرسمية:

- Users: https://www.odoo.com/documentation/19.0/applications/general/users.html
- Security: https://www.odoo.com/documentation/19.0/developer/reference/backend/security.html
- Multi-company: https://www.odoo.com/documentation/19.0/applications/general/companies/multi_company.html

## Microsoft Dynamics 365 Business Central

يعتمد على:

- Users.
- Security Groups.
- Permission Sets.
- إمكانية ربط Permission Sets بمجموعة وإعادة استخدامها.
- Company-specific permission assignment.
- Security filters ضمن الطبقات المتقدمة.

المصادر الرسمية:

- Security Groups: https://learn.microsoft.com/en-us/dynamics365/business-central/ui-security-groups
- Permission Sets: https://learn.microsoft.com/en-us/dynamics365/business-central/application/base-application/page/system.security.accesscontrol.permission-sets
- Access overview: https://learn.microsoft.com/en-us/dynamics365/business-central/admin-access-overview

## SAP Business One

يوفر:

- Full Authorization.
- Read Only.
- No Authorization.
- مستويات تفصيلية داخل التطبيقات والتقارير.

المصدر الرسمي:

- Authorizations: https://help.sap.com/docs/SAP_BUSINESS_ONE/68a2e87fb29941b5bf959a184d9c6727/4506b99c7d720487e10000000a155369.html
- Reports authorizations: https://help.sap.com/docs/SAP_BUSINESS_ONE/2dc2e07e933b4dd5b93ab6405dcfb6af/a37030072b884cd395abde9c1539e55b.html

## Daftra

يوفر:

- Employee/User separation.
- Role-based permissions.
- Page/action restrictions.
- Accessible branches.
- Active/Inactive.
- Login as.
- granular task permissions.

المصادر الرسمية:

- Employee Permissions and Roles: https://docs.daftra.com/en/user_manual/employee-permissions-and-roles/
- Add User: https://docs.daftra.com/en/tutorial/adding-a-new-user/
- Accessible Branches: https://docs.daftra.com/en/faq/how-can-an-employee-be-restricted-from-accessing-certain-branches-on-the-system/
- Login as Employee: https://docs.daftra.com/en/tutorial/logging-in-as-an-employee/
- Branch Management: https://docs.daftra.com/en/tutorial/branches-management/

## Manager.io

يوفر:

- Restricted users.
- Business-level access.
- User Permissions.
- Tabs.
- Reports.
- Settings.
- Full access.
- Impersonation.
- Default No Access for restricted users.

المصدر الرسمي:

- Set user permissions: https://www2.manager.io/guides/33078
- Create users: https://www2.manager.io/guides/9162

---

# 10. الاستنتاج الوظيفي من المقارنة

## RAWAEA موجود بالفعل في:

- Users.
- Roles.
- company-scoping.
- active/inactive.
- expiry.
- branch restriction.
- direct user permissions.
- role permissions.
- Owner wildcard semantics.
- field-like operational controls.
- customer assignments.
- visit-day restrictions.
- device identity.
- audit_log.
- separated operational PWAs.

## الفجوات الحقيقية المتبقية — Capability Gaps وليست Bugs حالية

1. Generic CRUD matrix:
   - View
   - Create
   - Edit
   - Delete
   - Approve
   - Export
   - Execute

2. Generic Record Rules / row-level conditions.

3. Generic Field-level permission model.

4. User Permission Simulator / Login-as.

5. Device/session management UI.

6. Permission history / audit viewer داخل Mother.

7. Generic policy inheritance بدل الاعتماد الجزئي على role-name legacy compatibility.

### القرار

هذه **Closure Units مستقبلية مستقلة**.

لم يتم خلطها مع جراحة RW_Users الحالية، ولم يتم بناء framework ضخم داخل `main.html` لمجرد “مجاراة المنافسين”.

---

# 11. ما لم يتم تغييره عمدًا

- `companies/company-1/main.html` لم يُعدل بواسطة CTO.
- لا تعديل للنظام التشغيلي المنفصل.
- لا تعديل لمسار Picker / Loading / Delivery / Runsheet.
- لا تعديل لـInventory engines.
- لا تغيير لـOwner wildcard contract.
- لا تعيين Role لـ`mostafa@rawaea.com`.
- لا منح `stock_adjustment` إلى Role بالتخمين.
- لا حذف للـunused roles.
- لا backfill شامل لـ`role_id`.
- لا بناء generic security engine الآن.

---

# 12. Production / Source Alignment

## Canonical System changes

- `ecd9afcf462991cdfe107264df90bc51f96e096a`
- `f660a937d16be05e470ec2e94cb3dba8584ffc8e`
- `08628e01d75fe50ddbde0617c669132322e1b290`

### Current System chain

`f3c15...`
→ `ecd9af...`
→ `f660a9...`
→ `08628e...`

### Mother chain

`033a...`
→ `55271...` (main.html changed)
→ `6f37...` (forensic extract only)

---

# 13. Verification Boundary

## VERIFIED

- current source read from actual current blob.
- historical change read from Git commit diff.
- production database snapshot refreshed after changes.
- production Edge deployments confirmed.
- canonical source aligned with deployed Edge source for the three changed functions.
- role propagation backend implemented.
- canonical role_id assignment implemented.
- explicit password requirement implemented.
- stock_adjustment backend enforcement implemented.
- no Production business row count changed.
- no Owner semantic changed.

## NOT VERIFIED

### Live Browser E2E

لا توجد جلسة مستخدم Authenticated قابلة للحقن في هذه الأدوات تمكن من إجراء:

- login داخل Mother
- فتح RW_Users live
- فتح modal بعد إصلاح main.html
- create user
- edit user
- role propagation through UI
- disable user
- stock_adjustment UI interaction.

لذلك لا يجوز تحويل Production deployment PASS إلى Browser Production PASS.

---

# 14. Owner Surgical Changeset — المطلوب فقط في main.html

## Surgery A

**File:** `companies/company-1/main.html`

**Blob:** `68ee9c23c876209364f405eed3d23a0c33f9d0ce`

**Function:** `RW_Users.openModal`

**Approx global line:** 5694

**Action:** ابحث واحذف block DEFECT-01 أعلاه، واستبدله بالبديل الكامل أعلاه.

**Expected:** إصلاح parser فقط داخل modal.

---

## Surgery B

**File:** `companies/company-1/main.html`

**Blob:** `68ee9c23c876209364f405eed3d23a0c33f9d0ce`

**Function:** `RW_Users.openModal`

**Approx global line:** 5530

**Action:** ابحث واحذف block DEFECT-02 أعلاه، واستبدله بالبديل الكامل أعلاه.

**Expected:** استعادة `items` دون إزالة `stock_adjustment`.

---

# 15. Post-owner verification

بعد تطبيق الجراحتين حرفيًا:

1. Count DEFECT-01 old sequence = 0.
2. Count DEFECT-02 old sequence = 0.
3. Count replacement A = 1.
4. Count replacement B = 1.
5. Parse the full inline JavaScript with V8.
6. Parse `RW_Users.openModal`.
7. Open Mother → المستخدمون والصلاحيات.
8. Open Add User.
9. Open Edit User.
10. Verify tabs:
    - البيانات الأساسية
    - الصلاحيات
    - إعدادات الميدان
    - العملاء المسموحين
11. Verify role list.
12. Verify `items` and `stock_adjustment` appear.
13. Verify custom permissions.
14. Verify save employee.
15. Verify disable user.
16. Change a Role and verify propagation.
17. Re-read Production counts.
18. Re-read audit_log.

---

# 16. تعليمات جلسة لاحقة

ابدأ من هذه السلسلة ولا تعد إلى الإصلاحات المغلقة:

```
CURRENT_STATE
↓
Current System HEAD + parent
↓
Current Mother HEAD + parent
↓
current main.html blob
↓
Production Users/Roles snapshot
↓
deployed save-employee/save-role/delete-role/delete-employee
↓
verify owner contract
↓
verify owner surgical patch status
↓
browser E2E
```

بعد Browser E2E فقط:

- إمّا إغلاق RW_Users بالكامل.
- أو فتح Closure Unit جديدة من أول Gap مثبتة.

لا تعالج `mostafa` أو unused roles أو generic CRUD/record-rules إلا بــCurrent Evidence مستقل.

---

# 17. FINAL SELF-AUDIT

### What I Proved

- الحالة الحالية في Mother مختلفة عن checkpoint القديم، ولذلك لم أعتمد عليه.
- `55271f8...` هو commit الذي أدخل جراحات RW_Users السابقة.
- أحدث extract `6f37...` لم يغير main.html.
- ظهر خطأ parser جديد محدد داخل RW_Users.
- ظهر فقد حقيقي لصلاحية `items`.
- role propagation كان Gap حقيقيًا ولم يكن مغلقًا backend-wise.
- save-employee كان يقبل fallback password.
- stock_adjustment كان ظاهرًا في UI ولا يملك backend enforcement مستقلاً في Edge capability.
- Production changes تم نشرها.
- System source تم مزامنته مع Production.
- Production counts ظلت ثابتة.

### What I Did Not Prove

- Browser Production E2E.
- نجاح owner source cutover.
- runtime UI بعد الجراحتين.
- نجاح تغيير Role من الواجهة في Browser.

### What I Fixed

- Dynamic role propagation backend.
- canonical role_id on save employee.
- explicit password requirement.
- stock_adjustment backend enforcement.
- System source/deployment parity for these capabilities.

### What Remains Open

- Owner applies two exact main.html surgical replacements.
- Browser E2E for RW_Users.

### FINAL STATUS

```
RW_Users Production backend integrity = CLOSED
RW_Users Edge/source alignment        = CLOSED
main.html source surgery              = READY / OWNER ACTION
Browser E2E                            = OPEN
RW_Users FULL CLOSURE                 = OPEN
```

**لا يُعلن 100% CLOSED قبل تطبيق الجراحتين والتحقق الحي من Browser Production.**

---

## End of Report 243
