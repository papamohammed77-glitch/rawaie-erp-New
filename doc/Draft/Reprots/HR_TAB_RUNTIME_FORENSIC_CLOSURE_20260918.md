# RAWAEA ERP — HR TAB RUNTIME FORENSIC SURGICAL CLOSURE
## 2026-09-18

نطاق الجلسة: تبويب HR فقط — سبب عدم استجابة التبويب ورسالة «حدث خطأ».

قاعدة التنفيذ: لا تعديل على companies/company-1/main.html من هذه الجلسة. تعديل ملف النظام الأم مُسلّم كـOwner Surgical Changeset دقيق جاهز للاستبدال. لا توجد Migration أو DDL أو إصلاح بيانات Production مطلوبة لهذه الحادثة.

---

## 1. Starting Truth — CURRENT GIT

### System repository
Repository:
papamohammed77-glitch/rawaie-erp-New

Current HEAD:
fee9cf2a1cfcd020d67093d4c0633edfa574ed70

Parent:
78da908d23be6ae64f544bf46abf9a5d0d6be3ea

Parent السابق:
79b16b22c5fe5b22fa0e9aa37d7026269394dbe0

### Mother repository
Repository:
papamohammed77-glitch/erp-frontend

Current HEAD:
b0d4475576f712057340821653d4a3a9d08e14e6

Parent:
29631c0e910b25b77fc5d4e2dda8efca8adfdb20

Current main.html forensic extract:
FILE_LINES=25412
FILE_BYTES=1462740
SHA256=b6f079ce423d1869c672ba265d2c473a5fc3853f8f2ea0cf1949e02c83e5d218

Current companies/company-1/main.html blob:
6dbca77b5e0fe569f3435fd39f965002dc7c0d2b

---

## 2. Production-first verification

تم فحص Production Supabase مباشرة قبل تحديد الإصلاح.

Supabase project:
fiilmooggumokxanwiyx

Core HR functions الموجودة فعليًا:
- hr_query
- hr_command_atomic
- hr_user_has_permission
- hr_payroll_calculate_impl
- hr_payroll_post_impl
- hr_list_employees
- hr_save_attendance
- hr_set_leave_status
- hr_upsert_employee_profile

hr_query وhr_command_atomic منشوران كـSECURITY DEFINER، والـHR command engine يتحقق من actor identity وcompany context وHR permission قبل عمليات الكتابة.

Production HR operational tables الحالية = 0 سجل في:
- employee_profiles
- employee_attendance
- employee_leave_requests
- employee_documents
- hr_departments
- hr_positions
- hr_contracts
- hr_attendance_events
- hr_work_entries
- hr_leave_types
- hr_leave_balances
- hr_requests
- hr_request_approvals
- hr_salary_advances
- hr_salary_components
- hr_payroll_periods
- hr_payroll_runs
- hr_payslips
- hr_payslip_lines
- hr_command_log

HR user الحقيقي في Production:
email      = hr@rawaea.com
auth_id    = 99eea49f-c27d-43e1-85b9-c97d4d85c55b
company_id = 00000000-0000-0000-0000-000000000001
role       = موظف الموارد البشرية
status     = Active

Production conclusion:
الحادثة الحالية ليست Missing HR Schema، وليست Missing RPC، وليست Tenant Data Failure.
لا يوجد تعديل Production Database مطلوب لإغلاقها.

---

## 3. Current-source reconstruction of the failure

Console failure:
TypeError: Cannot read properties of undefined (reading 'render')
    at Object.render (main:23741:36)
    at Object.navigate (main:1288:293)

Current Mother source:

RW_Views.render:
line 23741:
if (view === 'hr') { RW_HR.render(); return; }

هذا السطر ليس سبب الخطأ.

RW_HR opening:
line 23788:
var RW_HR = (function() {

HR render exists:
line 23902:
async function render(){ ... }

HR terminal الحالي:
23932: realtime();
23933: window.RW_HR={render:render,reload:render,openEmployee360:open360};
23934: }());
23935: window.RW_HR = RW_HR;

---

## 4. ROOT CAUSE — PROVEN

RW_HR مكتوب كـIIFE assignment:

var RW_HR = (function() {
    ...
}());

لكن داخل الـIIFE لا يوجد return يعيد الـHR public object.

إذن نتيجة الـIIFE هي:

RW_HR === undefined

ثم ينفذ السطر:

window.RW_HR = RW_HR;

فتصبح:

window.RW_HR === undefined

وعندما تنفذ RW_Views:

RW_HR.render()

ينتج حرفيًا:

Cannot read properties of undefined (reading 'render')

إذن العطل الحالي هو Module Export Contract Failure وليس Parser Failure.

---

## 5. Runtime proof

تمت إعادة إنتاج نفس النمط في JavaScript:

الحالة الحالية:

var RW_HR=(function(){
  window.RW_HR={render:function(){}};
}());

النتيجة:
RW_HR = undefined

الحالة الصحيحة:

var FIXED=(function(){
  return {render:function(){}};
}());

النتيجة:
typeof FIXED.render = function

Root cause مثبت بالتنفيذ وليس بالتخمين.

---

## 6. Historical Git reconstruction

### Commit 15325117153959536d8035b603ef9cfd64fc736d
Title:
Refactor RW_HR assignment in main.html

Parent:
eea3a62903d1533607f753d14c727145838c40e7

هذا الـcommit حذف إغلاق RW_HR IIFE من هذا الموضع:

window.RW_HR={render:render,reload:render,openEmployee360:open360};
}());

وأبقى:
window.RW_HR = RW_HR;

### Commit 48139d0b711496712d3c43572eef0e0e4ee5934c
Title:
Fix script closure in main.html

هذا أضاف الإغلاق النهائي للـscript الخارجي:
})();

لكنه لم يعالج قيمة RW_HR المرجعة.

### Commit 1f3e89e8761e34e3982746ae93ab0260e4d4b1a4
Title:
Refactor modal function for improved clarity

أعاد:
}());

إلى حدود HR، لكنه أبقى الـIIFE بلا return.

الخلاصة التاريخية:
الـparser history والـmodule-export history تشابكا في إصلاحات متعاقبة، ولذلك لا يجوز إعادة كتابة HR أو تعديل RW_Views.

---

## 7. Why the fix is exactly one surgical source change

لا يوجد evidence يسمح بتعديل:
- RW_Views
- RW_Navigation
- hr_query
- hr_command_atomic
- HR routing
- _redirects
- SW
- middleware
- legacy HR adapters
- أي دورة مخزون أو رانشيت أو توصيل

الـcurrent source يثبت أن المشكلة محصورة في public return contract الخاص بـRW_HR.

---

# 8. OWNER SURGICAL CHANGESET

FILE:
companies/company-1/main.html

CURRENT BLOB:
6dbca77b5e0fe569f3435fd39f965002dc7c0d2b

OBJECT:
RW_HR

OPENING:
line 23788

function:
var RW_HR = (function() {

EXACT CURRENT ELEMENT:
ابحث حرفيًا عن هذا البلوك عند lines 23932–23935:

  realtime();
  window.RW_HR={render:render,reload:render,openEmployee360:open360};
}());
window.RW_HR = RW_HR;

ACTION:
احذف هذا البلوك كاملًا.

REPLACE WITH THIS COMPLETE BLOCK فقط:

  realtime();
  return {
    render: render,
    reload: render,
    openEmployee360: open360
  };
}());
window.RW_HR = RW_HR;

لا تضف window.RW_HR داخل الـIIFE.
لا تغير RW_Views.render.
لا تغير render().
لا تغير realtime().
لا تغير أي function أخرى في RW_HR.

---

## 9. Why this replacement preserves the existing contract

القيمة المرجعة من RW_HR ستصبح:

{
  render: render,
  reload: render,
  openEmployee360: open360
}

وبالتالي:
RW_HR.render صالح.
RW_HR.reload صالح.
RW_HR.openEmployee360 صالح.

ويظل:
window.RW_HR = RW_HR;

هو public export الوحيد.

لا توجد capability مفقودة بعد الإصلاح.

---

## 10. Current HR Mother architecture

HR الحالي في النظام الأم يتكون من:

dashboard
employees
organization
contracts
attendance
leaves
requests
advances
payroll
documents

Read path:
hr_query

Write path:
hr_command_atomic

Actor:
users + auth identity

Authorization:
hr_user_has_permission

Audit:
hr_command_log + actor identity guard

Documents:
employee_documents + Storage

Realtime:
HR table subscription عبر realtime()

هذه البنية لا تحتاج إعادة بناء لهذا العطل.

---

## 11. Historical operational boundary

هذه الجلسة لم تغيّر:
- Order lifecycle
- Runsheet lifecycle
- Picking
- Loading
- Delivery
- Returns
- Inventory count
- Stock movement
- أي Accounting flow خارج HR

ذلك لأن السبب الجذري لا يمر بأي من هذه المسارات، ولا توجد إشارة من Production أو Current Source تربط الخطأ بها.

---

# 12. Competitive benchmark — HR ONLY

## Odoo 19

Odoo يربط Employee master ببيانات الموظف والعقود والهيكل التنظيمي، ويربط العقود بالتعويض وساعات العمل ومصدر Work Entries، بينما Time Off يشمل requests/balances/allocations/approvals/reports.

مصادر:
https://www.odoo.com/documentation/19.0/applications/hr/employees.html
https://www.odoo.com/documentation/19.0/applications/hr/payroll/contracts.html
https://www.odoo.com/documentation/19.0/applications/hr/payroll/salaries.html
https://www.odoo.com/documentation/19.0/applications/hr/payroll/pay_runs.html
https://www.odoo.com/documentation/19.0/applications/hr/time_off.html

## Microsoft Dynamics 365 Human Resources

النمط الموثق يتضمن:
- Time & Attendance calculation groups
- Approval groups
- Absence setup/codes
- validation rules
- leave plans
- accrual/balances

مصادر:
https://learn.microsoft.com/en-us/dynamics365/human-resources/hr-set-up-time-and-attendance-information
https://learn.microsoft.com/en-us/dynamics365/human-resources/hr-leave-and-absence-plans
https://learn.microsoft.com/en-us/dynamics365/human-resources/hr-register-time

## SAP SuccessFactors

النمط الموثق يتضمن:
- Clock In / Clock Out
- time events
- Time Sheet
- approval lifecycle
- time recording profiles
- Time Off administration
- Admin Alerts

مصادر:
https://help.sap.com/docs/successfactors-employee-central/operating-time-management-in-sap-successfactors/9b874bb10627450fad5c2ceff72c107f.html
https://help.sap.com/docs/successfactors-employee-central/implementing-time-management-in-sap-successfactors/assigning-time-recording-profiles-to-employees

## Daftra

الـHRM المعلن رسميًا يجمع:
- employee records
- attendance
- leave
- contracts
- request approvals
- advances/loans
- salary components
- payroll
- ESS mobile

مصدر:
https://www.daftra.com/en/hrm/

## Manager.io

النمط الحالي:
- Employees
- Payslips
- earnings/deductions
- payroll liabilities
- payment settlement كعملية منفصلة

مصادر:
https://www2.manager.io/guides/9751
https://www2.manager.io/guides/9752
https://www2.manager.io/guides/9768

Competitive conclusion:
الـHR domain الموجود في RAWAEA يغطي الهيكل الأساسي المتوافق مع النمط العالمي:
Employee → Organization → Contract → Attendance → Leave → Request → Advance → Payroll → Documents.

المزايا المستقبلية المتقدمة تبقى Closure Units مستقلة ولا تدخل في إصلاح هذا العطل.

---

# 13. Verification after Owner surgery

## Exact source verification

Search:
window.RW_HR={render:render,reload:render,openEmployee360:open360};
}());
window.RW_HR = RW_HR;

Expected:
0 matches

Search:
return {
    render: render,
    reload: render,
    openEmployee360: open360
  };
}());
window.RW_HR = RW_HR;

Expected:
1 match

## JavaScript validation

Run:
node --check

أو نفس V8 new Function() validation المستخدم في تقارير parser.

Expected:
PASS

## Runtime validation

login
→ Session restored
→ Mother shell
→ HR
→ RW_Views.render('hr')
→ RW_HR.render()
→ HR dashboard

Expected:
- لا توجد «حدث خطأ»
- لا يوجد Cannot read properties of undefined
- لا يوجد RW_HR undefined

## Read-only HR smoke

dashboard
employees
organization
contracts
attendance
leaves
requests
advances
payroll
documents

Expected:
الانتقال بين التبويبات العشرة بدون module failure.

---

# 14. Production decision

Production DB:
VERIFIED

Production HR core:
VERIFIED

Production structural change:
NONE REQUIRED

Production data repair:
NONE REQUIRED

Middleware hotfix:
NOT APPLIED

Service Worker hotfix:
NOT APPLIED

سبب عدم تطبيق Hotfix:
الـcanonical source نفسه يحتوي العيب، وresponse-layer workaround سيحوّل المشكلة إلى drift إضافي بين source وserved runtime. المطلوب إصلاح public module contract نفسه.

---

# 15. FINAL SELF-AUDIT

## What I Proved

- Current System HEAD verified.
- Current System parent verified.
- Current Mother HEAD verified.
- Current Mother parent verified.
- Current main.html blob verified.
- Current RW_HR source boundary verified.
- RW_HR.render exists.
- RW_Views.render is correct.
- RW_HR IIFE has no module-level return.
- RW_HR therefore resolves to undefined.
- This exactly matches the current TypeError.
- Historical Git sequence explains how the broken export arose.
- Production HR schema/functions exist.
- Current Production HR operational tables contain no business fixtures.
- No Production database change is required.
- No inventory/runsheet/delivery logic needs to be touched.
- Main.html was not modified.
- One exact surgical Owner patch is sufficient for this root cause.

## What I Did Not Prove

- Live Cloudflare served artifact after Owner applies the patch.
- Authenticated browser E2E after Owner deploys the patch.
- Full transactional HR E2E with populated HR business data.

## Closure status

CURRENT SOURCE ROOT CAUSE        = PROVEN
PRODUCTION HR CORE               = VERIFIED
OWNER SURGICAL PATCH             = READY
MAIN.HTML MODIFIED BY CTO        = 0
PRODUCTION DB CHANGE             = 0
LIVE BROWSER AFTER PATCH         = OPEN
FULL HR E2E                      = OPEN

---

# 16. NEXT SESSION — START FROM THIS EXACT POINT

1. Verify System HEAD:
fee9cf2a1cfcd020d67093d4c0633edfa574ed70

2. Verify Mother HEAD:
b0d4475576f712057340821653d4a3a9d08e14e6

3. Verify Owner applied the exact lines 23932–23935 surgery above.

4. Do not revisit the old parser incident unless a fresh current-source parse proves new drift.

5. Verify:
typeof RW_HR
typeof RW_HR.render
typeof RW_HR.reload
typeof RW_HR.openEmployee360

6. Run live HR navigation.

7. Run read-only smoke for all ten HR tabs.

8. Only after runtime closure open the next HR Closure Unit.

9. Do not reopen inventory/runsheet/delivery/picking/accounting unless new direct evidence from HR integration requires it.

---

# 17. GOVERNANCE CARRIED FORWARD

Reports are historical evidence only.

Current truth hierarchy:
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT EVIDENCE
+
CURRENT GIT
+
CURRENT SOURCE

No prior report may override current-source evidence.

Never repeat a closed fix without new evidence.

Never modify main.html from an old report if current source proves a different root cause.

Never create a second HR runtime engine.

Never convert Git/DB PASS into browser Production PASS.

Preserve OWNER semantics:
isOwner + permissions:["*"] + owner_profile + license state.

Any future HR capability must close:
Business Contract
→ Source
→ DB
→ Authorization
→ Runtime
→ Error path
→ Retry
→ Audit
→ Production verification
→ Current State
