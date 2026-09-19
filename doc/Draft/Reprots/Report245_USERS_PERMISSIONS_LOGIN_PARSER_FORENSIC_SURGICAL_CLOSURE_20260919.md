
# REPORT 245 — RW_Users LOGIN / PARSER FORENSIC SURGICAL CLOSURE
# RAWAEA ERP
# التاريخ: 2026-09-19
# النطاق: المستخدمون والصلاحيات فقط

## 1. الحالة المرجعية المعتمدة

تمت إعادة بناء الحالة من:
CURRENT GIT
+
CURRENT SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT EVIDENCE
+
CURRENT CI RUNTIME EVIDENCE

### Mother System
- أحدث Mother HEAD وقت هذا التقرير: 5da2121beef82840880276d254d8665468420332
- Parent: 904705d9efcadd8e3443f167ce8fa38cb17b0525
- آخر main.html commit قبل ذلك: 58368091b6b75b861cf2d2aa994ab7c52d7eedaa
- Parent لـ 583680: 3bc6f6674398931f21fae26b32562587d17b7ebd
- current main.html blob: 309bf5ea45a8f8a23b77ddf94c295c0c01dd8819

آخر commits في Mother بعد 2026-09-19:
1. 5da2121 — forensic: restore Mother browser E2E workflow
2. 904705d — forensic: persist current Mother HR extract
3. 5836809 — Update main.html
4. 3bc6f66 — forensic: trigger Mother browser E2E for RW_Users parser proof
5. 2bf3eaa — forensic: persist current Mother HR extract
6. 1412789 — Update main.html

## 2. أهم نتيجة جنائية

الخطأ الذي أرسله المستخدم:

    main:5730 Uncaught SyntaxError: Invalid or unexpected token

تم إثباته على Current Mother Source بواسطة GitHub Actions.

### Current source — السطر 5730

Current main.html يحتوي فعليًا على:

    '<button type="button" onclick="RW_Users._switchEmpTab(\\'basic\\')" id="tab-basic" ...>'

ونفس الخطأ موجود في:
- 5730 basic
- 5731 perms
- 5732 field
- 5733 assignments

تم إثبات عدد المواضع الأربعة في RW_Users.

### دليل Git القاطع

Commit:

    58368091b6b75b861cf2d2aa994ab7c52d7eedaa

غيّر النص من:

    onclick="RW_Users._switchEmpTab(\'basic\')"

إلى:

    onclick="RW_Users._switchEmpTab(\\'basic\\')"

وبنفس النمط لباقي التبويبات الأربعة.

أي أن الخطأ ليس تخمينًا في السطر.
إنه تغيير مثبت في Git أدخل double escaping غير صالح داخل JavaScript single-quoted string.

### دليل CI

Workflow:

    RAWAEA — Forensic Mother Assembly Guard

Run:
    35424752260

Job:
    105848653052

فشل في خطوة:

    Validate Mother inline JavaScript syntax

والرسالة الحرفية:

    /tmp/mother_scripts.js:5588
        '<button type="button" onclick="RW_Users._switchEmpTab(\\'basic\\')" ...>'
                                                                          ^^^^^^
    SyntaxError: Invalid or unexpected token

Workflow:

    RAWAEA CTO — published main.html full forensic gate

Run:
    35424752242

Job:
    105848653059

فشل في:

    Exact JavaScript syntax gate — original published source

والـline positioning أعاد نفس العنوان:

    /tmp/main-positioned.js:5730

بنفس Invalid or unexpected token عند basic.

### أثر الخطأ على شاشة الدخول

الملف يحتوي على:

    document.addEventListener('DOMContentLoaded', boot);

لكن JavaScript الكامل لا يصل إلى مرحلة التنفيذ أصلًا عندما يفشل Parser.
وبالتالي لا تُسجل boot handler بشكل قابل للتنفيذ، ولا يتم الانتقال الطبيعي من شاشة الدخول إلى النظام.

النتيجة:
خطأ 5730 هو Parser Gate Failure وليس خطأ صلاحيات أو Authentication Backend.

## 3. تحذير Tailwind

الرسالة:

    cdn.tailwindcss.com should not be used in production

ليست سبب فشل Parser.
هي Warning منفصلة.

لا يوجد في هذا التحقيق ما يبرر لمسها داخل RW_Users.
لا تغيير لها في هذه الجراحة.

## 4. خطأ ثانٍ مؤكد لا يجوز تركه بعد إصلاح الأول

في Current Mother Source توجد نهاية openUserPage بهذا الشكل:

    6087:}
    6088:
    6089:container.scrollTop = 0;
    6090:
    6091:    return {

الـ} في 6087 يغلق كتلة if (isEdit).
ولا توجد } ثانية تغلق:

    function openUserPage(email)

قبل:

    return {

وقد أثبت الـCI على parent السابق أن Parser ينتقل بعدها إلى نهاية IIFE ويصل إلى:

    })();

مع:

    SyntaxError: Unexpected token ')'

لذلك إصلاح double escaping وحده سيكون نصف إصلاح فقط؛ سيكشف الخطأ الثاني مباشرة.

## 5. ما تم التحقق من عدم الحاجة إلى تعديله

### RW_Users renderTable
Current source يحتوي بالفعل على role search:

    var roleMatch = (e.role || '').toLowerCase().indexOf(q) !== -1;

ولا يتم تغيير هذا.

### RW_Users return object
Current source يحتوي بالفعل على:

    _openModal: openUserPage,

ولا يتم تغيير هذا.

### openUserPage
Current source يحتوي بالفعل على openUserPage(email).
لا إعادة استبدال الدالة كاملة.
الجراحة الحالية أصغر وأكثر أمانًا.

هذا يمنع إعادة تطبيق إصلاحات Report 244 التي ثبت أنها موجودة بالفعل.

## 6. OWNER SURGICAL CHANGESET — لا تلمس main.html من CTO

### SURGERY A — إصلاح الـdouble escaping

الملف:
    companies/company-1/main.html

الدالة:
    function openUserPage(email)

المواضع:
    5730–5733

ابحث حرفيًا عن:

    '<button type="button" onclick="RW_Users._switchEmpTab(\\'basic\\')" id="tab-basic" class="px-5 py-3 rounded-xl font-black text-sm border-b-2 border-blue-600 text-blue-600">البيانات الأساسية</button>' +

    '<button type="button" onclick="RW_Users._switchEmpTab(\\'perms\\')" id="tab-perms" class="px-5 py-3 rounded-xl font-black text-sm text-slate-500">الصلاحيات</button>' +

    '<button type="button" onclick="RW_Users._switchEmpTab(\\'field\\')" id="tab-field" class="px-5 py-3 rounded-xl font-black text-sm text-slate-500">إعدادات الميدان</button>' +

    (isEdit ? '<button type="button" onclick="RW_Users._switchEmpTab(\\'assignments\\')" id="tab-assignments" class="px-5 py-3 rounded-xl font-black text-sm text-slate-500">العملاء المسموحون</button>' : '') +

احذف هذه الأسطر الأربعة واستبدلها بالكامل بـ:

    '<button type="button" onclick="RW_Users._switchEmpTab(\'basic\')" id="tab-basic" class="px-5 py-3 rounded-xl font-black text-sm border-b-2 border-blue-600 text-blue-600">البيانات الأساسية</button>' +

    '<button type="button" onclick="RW_Users._switchEmpTab(\'perms\')" id="tab-perms" class="px-5 py-3 rounded-xl font-black text-sm text-slate-500">الصلاحيات</button>' +

    '<button type="button" onclick="RW_Users._switchEmpTab(\'field\')" id="tab-field" class="px-5 py-3 rounded-xl font-black text-sm text-slate-500">إعدادات الميدان</button>' +

    (isEdit ? '<button type="button" onclick="RW_Users._switchEmpTab(\'assignments\')" id="tab-assignments" class="px-5 py-3 rounded-xl font-black text-sm text-slate-500">العملاء المسموحون</button>' : '') +

قاعدة التحقق النصي:
- Current = backslash backslash + single quote.
- Target = single backslash + single quote.
- لا تغيّر أسماء التبويبات أو HTML أو IDs.

### SURGERY B — إغلاق openUserPage() فعليًا

الملف:
    companies/company-1/main.html

الدالة:
    function openUserPage(email)

ابحث حرفيًا عن هذا المقطع:

    });
}

container.scrollTop = 0;

return {

احذفه بالكامل واستبدله بـ:

    });

    container.scrollTop = 0;
}

return {

ملاحظة:
الـ} الأولى في المقطع الحالي تغلق if (isEdit).
الـ} الجديدة بعد container.scrollTop = 0 تغلق function openUserPage نفسها.

لا تحذف return object.
لا تغيّر:
    _openModal: openUserPage,

## 7. Production Verification

تمت مطابقة Production مباشرة قبل إغلاق هذا التقرير.

### Users
- users = 24
- active_users = 24
- wildcard users = 1

### Roles
- roles = 20
- system roles = 3

### OWNER
- role = مدير النظام
- role_id صحيح
- permissions = ["*"]
- wildcard semantics محفوظة

### RLS
تم التحقق من سياسات:
- users_select_company
- users_insert_permission
- users_update_permission
- users_delete_permission
- roles_select_company_permission
- roles_insert_company_permission
- roles_update_company_permission
- roles_delete_company_permission
- customer_assignments_manage
- customer_assignments_select_scoped

### Edge Functions
الحالة الحالية Production:
- save-employee v10 ACTIVE
- save-role v9 ACTIVE
- delete-employee v4 ACTIVE
- delete-role v4 ACTIVE

الخلاصة:
لا يوجد سبب Production Database أو Edge Function يبرر تعديلًا بسبب Parser الخطأ الحالي.

## 8. Production Change Decision

PRODUCTION DATABASE:
    NO CHANGE REQUIRED

PRODUCTION RPC:
    NO CHANGE REQUIRED

PRODUCTION EDGE:
    NO CHANGE REQUIRED

سبب القرار:
الخلل مثبت في source JavaScript Parser داخل Mother main.html، وليس في Backend contract.

## 9. Competitor Comparison — Users & Permissions only

### Odoo
يوفر:
- Users + Access Rights
- Groups
- CRUD access rights
- Record Rules
- Field-level security
- User devices / revoke
- Multi-company access + default company

المصادر الرسمية:
https://www.odoo.com/documentation/19.0/applications/general/users.html
https://www.odoo.com/documentation/19.0/developer/reference/backend/security.html

RAWAEA الحالي:
- Roles موجودة
- Direct permissions موجودة
- Branch scope موجود
- Device ID موجود في data model
- Owner wildcard موجود
- لا يوجد حاليًا عقد موحد لـ record rules
- لا يوجد field-level authorization مستقل
- لا توجد security device center/revoke contract مكتملة داخل Users UI

### Microsoft Dynamics / Business Central
يوفر:
- Security Groups
- Permission Sets
- تجميع الصلاحيات عبر مجموعات
- إمكانية تخصيص Permission Set لشركة محددة

المصدر:
https://learn.microsoft.com/en-us/dynamics365/business-central/ui-security-groups

RAWAEA الحالي:
- Role موجود
- Permission set فعلي موجود داخل role permissions
- لكن لا يوجد Security Group composition متعدد المستخدمين
- ولا يوجد Permission Set hierarchy/assignment model منفصل عن role

### SAP S/4HANA
يوفر:
- Business Roles
- Business Catalogs
- Restrictions
- Read / Write / Value Help authorization
- Restriction fields وقيم/ranges

المصدر:
https://help.sap.com/docs/SAP_S4HANA_CLOUD/53e36b5493804bcdb3f6f14de8b487dd/c926d691d7144f7dba16f8e12ad81d28.html

RAWAEA الحالي:
- Role + permissions
- Company/branch scope
- لا توجد Restricted-field/value-range authorization contract

### Daftra
يوفر:
- Employee Roles
- Permissions per role
- Accessible Branches
- Restricted Pages
- Login as employee

المصادر الرسمية:
https://docs.daftra.com/en/user_manual/employee-permissions-and-roles/
https://docs.daftra.com/en/tutorial/logging-in-as-an-employee/
https://docs.daftra.com/en/faq/how-can-an-employee-be-restricted-from-accessing-certain-branches-on-the-system/

RAWAEA الحالي:
- Roles
- Branch scope
- Permissions
- لا توجد Restricted Pages contract مستقلة
- لا يوجد Login-as / Permission Simulator contract

### Manager.io
يوفر مستويات:
- No access
- View
- View/Create
- View/Create/Update
- View/Create/Update/Delete
- Full access

المصدر الرسمي:
https://www2.manager.io/guides/33078

RAWAEA الحالي:
- Permission keys الحالية feature/module oriented
- لا يوجد حتى الآن CRUD level مستقل لكل resource

## 10. Business Contract Gaps — لا تُخفى ولا تُعتبر مغلقة

هذه ليست Parser bug fixes.
هي عقود Business/Security مستقلة ويجب أن تبقى Open بعد هذه الجراحة:

1. Effective Permissions Engine متعدد الأدوار/المجموعات.
2. Permission levels: View/Create/Update/Delete.
3. Record-level restrictions.
4. Field-level authorization.
5. Security Groups / Permission Sets مستقلة عن role.
6. Login-as / Permission Simulator.
7. Restricted Pages / action-level deny overlays.
8. User Security Center للأجهزة والجلسات وإمكانية revoke.
9. Multi-company access/default company إذا تم تفعيل هذا العقد مستقبلًا.

لا يتم اختراع أي منها داخل هذه الجراحة.
لا يتم إنشاء جداول أو RPCs لها إلا بعد فتح Closure Unit مستقلة بعقد واضح.

## 11. Historical Contract Preservation

تم الحفاظ على:
- OWNER = isOwner + permissions:["*"] semantics.
- Role-based permissions.
- Direct permissions.
- Branch scope.
- Customer assignments.
- Separate operational PWAs.
- Existing field/mileage/warehouse/route operational flow.
- Backend save/delete user/role contracts.

لا توجد في هذه الجراحة أي إعادة هندسة لدورة المخزون أو الأوردر أو الرانشيت.

## 12. Forensic Trigger Cleanup

تم استخدام تعديل مؤقت على:
    .github/workflows/browser_e2e_mother_20260915.yml

فقط لتحفيز GitHub Actions على Current Mother Source.

تمت استعادة الملف إلى حالته الأصلية.

Restore commit:
    5da2121beef82840880276d254d8665468420332

ولا يوجد تعديل مقصود متبقٍ على main.html من CTO.

## 13. Final Closure Status

CURRENT PARSER STATE:
    BROKEN — proven

ROOT CAUSE A:
    double escaping introduced in 5836809

ROOT CAUSE B:
    missing openUserPage() closing brace

PRODUCTION BACKEND:
    VERIFIED — no change required

ALREADY FIXED USER-PAGE CONTRACTS:
    preserved

OWNER CHANGESET:
    READY — 2 exact replacements

BROWSER E2E:
    NOT YET PASSING because Mother parser gate fails before browser step

Therefore:

    RW_Users LOGIN/PARSER CLOSURE = NOT CLOSED YET

The correct next action is the two surgical replacements above, followed by a fresh Mother HEAD/source check and the existing CI syntax gate.

## 14. NEXT EXACT RESUMPTION POINT

ابدأ من:

    Mother HEAD 5da2121beef82840880276d254d8665468420332

ثم:

    1. تحقق أن main.html blob ما زال 309bf5ea45a8f8a23b77ddf94c295c0c01dd8819.
    2. طبّق SURGERY A فقط.
    3. طبّق SURGERY B فقط.
    4. لا تغيّر renderTable.
    5. لا تغيّر _openModal.
    6. شغّل:
       RAWAEA — Forensic Mother Assembly Guard
    7. إذا مر syntax:
       شغّل Browser E2E.
    8. إذا مر Browser E2E:
       افتح Users & Permissions فعليًا.
    9. تحقق من:
       create user
       edit user
       role change
       direct permission display
       field settings
       customer assignments
       branch scope
       deactivate user
       OWNER guard
    10. بعد ذلك فقط افتح Closure Unit التالية لعقود المنافسين المفتوحة.

لا تعيد Report 244.
هذا التقرير هو تصحيح جنائي للمرحلة التالية بعده.

# END REPORT 245
