# RAWAEA ERP — HR FORENSIC / SURGICAL CLOSURE
## 2026-09-18

> نطاق الجلسة: **HR فقط**.
> `main.html` لم يُعدّل.
> التقارير السابقة استُخدمت لفهم التاريخ فقط، بينما قرارات التنفيذ بُنيت على CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.

---

## 1. الهدف

إغلاق مسار HR الحالي من جهة:

- استرجاع الحالة الحقيقية بعد آخر جلسة.
- تحقيق جنائي في خطأ `Unexpected token ')'` وعدم تجاوز شاشة الدخول.
- منع استمرار تشغيل HR Legacy كتطبيق موازٍ.
- الحفاظ على Mother HR كـSource of Truth.
- إغلاق ثغرة actor identity في HR audit.
- منع DML المباشر على `employee_documents` من `anon/authenticated`.
- مطابقة HR مع النمط المعماري للأنظمة المنافسة دون نسخها حرفيًا.
- تحديث السجل المرجعي للجلسة التالية.

---

# 2. مصادر الحقيقة التي تم تثبيتها

## 2.1 System repository

Repository:
`papamohammed77-glitch/rawaie-erp-New`

HEAD قبل هذه الجلسة:
`96cbd83bf3e69600910ae655eb832a72e3d710c1`

Parent:
`2a10fd7c8ed6f756c61663ef0562c3887c40d76c`

هذه السلسلة هي المرجع المباشر لتاريخ إغلاق HR السابق.

## 2.2 Mother frontend repository

Repository:
`papamohammed77-glitch/erp-frontend`

HEAD النهائي بعد التنفيذ:
`9a0b72ef746f2f6f5c1b149edd2a490df39377c6`

Parent النهائي:
`75af385fd4f402c107423a37d0d2b769de152105`

Commit الأخير:
`hr: force republish with new SW build boundary`

## 2.3 Mother main.html protection

`companies/company-1/main.html` لم يُعدل في هذه الجلسة.

Blob الحالي:
`8ba8ef60c2875ea68ed85283ce772e023c0ef771`

الـforensic extract الحالي يثبت أن نهاية RW_HR canonical وليست النسخة القديمة التي كانت تحتوي على terminal IIFE إضافي.

---

# 3. استرجاع الحالة التاريخية

تمت قراءة:

- `MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`
- أحدث تقارير HR ذات الصلة في `doc/Draft/Reprots`.
- `HR_LOGIN_FORENSIC_CLOSURE_20260917.md`.
- `HR_LOGIN_RESPONSE_LAYER_SURGICAL_PATCH_20260917.diff`.
- `HR_LEGACY_ADAPTERS_20260917.sql`.
- `HR_MOTHER_SURGICAL_REPLACEMENT_20260917_FINAL.js`.
- `CURRENT_STATE.md`.

أهم نتيجة من الاسترجاع:

الحالة السابقة كانت تعتبر runtime/browser verification هي البوابة المفتوحة، لكن بعض نص الحالة القديمة كان قديمًا بالفعل مقارنة بـMother source الحالي. لذلك لم يتم إعادة تنفيذ الإصلاح القديم، بل تم مطابقة المصدر الحالي أولًا.

---

# 4. التحقيق الجنائي في خطأ الدخول

## 4.1 Console evidence

الرسالة:

```text
cdn.tailwindcss.com should not be used in production

main:25370 Uncaught SyntaxError: Unexpected token ')'
```

التحذير الخاص بـTailwind **ليس سبب توقف JavaScript**؛ هو warning مستقل.

## 4.2 Current source verification

التحقيق في Mother current source يثبت أن `main.html` الحالي لا يحتوي على الـterminal malformed IIFE الذي كان معروفًا من تاريخ RW_HR.

الـcurrent forensic extract يثبت نهاية RW_HR بالشكل canonical، مع إغلاق واحد فقط للـIIFE ثم export:

```text
23893: }());
23894: realtime();
23895: window.RW_HR={render:render,reload:render,openEmployee360:open360};
23896: window.RW_HR = RW_HR;
```

وبالتالي فإن رقم الخطأ `25370` لا يطابق Source of Truth الحالي كدليل على defect جديد داخل `main.html`؛ بل يشير إلى artifact/runtime أقدم من النسخة الحالية.

## 4.3 Why the stale artifact could survive

الـMother Service Worker الحالي لا يخزن HTML، ويجعل navigation/API/runtime network-backed، ومع ذلك ظل لدينا احتمال أن الـartifact المنشور لم ينتقل إلى آخر SW build أو أن browser runtime كان ما يزال يمسك نسخة سابقة.

لذلك تم تنفيذ republish boundary جراحي في `sw.js` بدل لمس `main.html`.

---

# 5. HR ROUTING DEFECT — مثبت فعليًا

تم فتح `companies/company-1/app.html` الحالي ومقارنة redirect logic مع Mother HR.

قبل الإصلاح كان مستخدم HR يُرسل إلى:

```text
/companies/company-1/office/hr.html
```

وهذا الملف Legacy HR مستقل، وليس Mother HR.

المسار الجديد:

```text
HR permission
        ↓
/companies/company-1/main.html
        ↓
Mother HR (RW_HR)
```

الـLegacy `office/hr.html` كان يحتوي على:

- direct queries على users.
- صلاحيات legacy خاصة به.
- Attendance وSalary بحالة `قيد التطوير`.
- Dexie/cache path مستقل.

تركه كـruntime target كان يعني وجود **HR application engine موازي**، وهو مخالف لمبدأ النظام الأم كمصدر تحكم مركزي.

---

# 6. التعديلات الجراحية المنفذة في Mother

## 6.1 `companies/company-1/app.html`

Commit:
`400b16d8cfd6226b02955fe6a2fb76f386e56dde`

التغيير الوحيد الوظيفي:

```diff
- if (perms.indexOf('hr') !== -1) { window.location.replace(base + '/office/hr.html'); return; }
+ // HR — النظام الأم فقط؛ لا يتم توجيه مستخدم HR إلى التطبيق القديم.
+ if (perms.indexOf('hr') !== -1) { window.location.replace(base + '/main.html'); return; }
```

لم تتم إعادة بناء login shell أو تغيير منطق authentication نفسه.

## 6.2 `_redirects`

Commit:
`75af385fd4f402c107423a37d0d2b769de152105`

التغيير:

```diff
- /hr /companies/company-1/office/hr.html 200
+ /hr /companies/company-1/main.html 200
```

وبذلك تم إغلاق direct/bookmarked runtime entry إلى HR Legacy.

## 6.3 `companies/company-1/sw.js`

Commit النهائي:
`9a0b72ef746f2f6f5c1b149edd2a490df39377c6`

التغيير:

```diff
- RAWAEA_SW_P155_HR_TERMINAL_SYNTAX_HARDENING_20260917
+ RAWAEA_SW_P156_HR_REPUBLISH_20260918
```

الغرض ليس إصلاح business logic، بل إجبار deployment/runtime على نسخة SW جديدة، مع الحفاظ على القواعد الحالية:

- HTML غير مخزن.
- runtime غير مخزن.
- static cache versioned.
- old cache deleted on activation.
- controlled clients reloaded.
- known RW_HR response repair preserved.

---

# 7. Production HR database — findings

Supabase project:
`fiilmooggumokxanwiyx`

## 7.1 Current HR engines

تم التحقق من وجود واستخدام:

```text
hr_query
hr_command_atomic
hr_payroll_calculate_impl
hr_payroll_post_impl
hr_save_attendance
hr_set_leave_status
hr_upsert_employee_profile
hr_user_has_permission
```

## 7.2 Current HR data state

جميع HR domain tables الأساسية التي تم فحصها كانت بدون business rows وقت الـsnapshot.

لم يتم اختلاق أي بيانات موظفين لتصنيع نجاح الاختبارات.

هذه نقطة حاكمة: وجود schema/RPCs لا يعني اكتمال HR functional maturity.

---

# 8. Production security fix #1 — actor identity

## FINDING

`hr_command_atomic` كان يسمح بإرسال `p_actor_email` مختلف عن هوية `p_actor_user_id`، ما يعني أن سجل HR command كان يمكن نظريًا أن يحتوي على actor_email مزيف.

## SURGICAL FIX

تم إنشاء trigger production:

```text
hr_command_log_enforce_actor_identity()
```

ويقوم قبل INSERT/UPDATE بـ:

1. التحقق من actor_user_id داخل نفس company.
2. رفض actor identity غير الصالح.
3. اشتقاق `actor_email` من users record نفسه.
4. تجاهل email المزود من caller كمرجع للحقيقة.

Migration:

```text
hr_command_log_actor_identity_guard_20260918
```

## PRODUCTION TEST

تم تنفيذ اختبار transactional على مستخدم HR الحقيقي مع إرسال:

```text
spoof@example.invalid
```

وكانت النتيجة في `hr_command_log`:

```text
actor_user_id = 67552c18-144e-453f-b0e8-5b7730b929d6
actor_email   = hr@rawaea.com
```

أي أن الـCore أعاد بناء actor identity من المصدر الحقيقي بدل قبول spoofed input.

---

# 9. Production security fix #2 — employee documents DML boundary

## FINDING

جدول:

```text
public.employee_documents
```

كان لديه DML privilege مباشر للـpublic application roles، رغم أن HR document contract الحالي يسجل metadata من خلال HR command layer.

## FIX

تم تنفيذ:

```sql
REVOKE INSERT, UPDATE, DELETE, TRUNCATE
ON TABLE public.employee_documents
FROM anon, authenticated;
```

Migration:

```text
hr_employee_documents_table_dml_boundary_20260918
```

هذا لا يلغي HR document capability؛ بل يمنع bypass مباشر للـtable ويُبقي operation تحت HR command boundary.

---

# 10. Tenant / authorization evidence

تم اختبار HR user الحقيقي:

```text
email      = hr@rawaea.com
auth_id    = 99eea49f-c27d-43e1-85b9-c97d4d85c55b
company_id = 00000000-0000-0000-0000-000000000001
permission = hr
```

واختبار:

```text
auth.uid()
auth.role()
app_private.current_user_company_id()
hr_user_has_permission(...,'hr')
hr_query('self',...)
hr_query('dashboard',...)
hr_query('employees',...)
```

أثبت أن HR Core يعمل داخل authenticated company context الصحيح.

صلاحية OWNER wildcard لم يتم لمسها.

---

# 11. مقارنة HR مع الأنظمة المنافسة

تمت مراجعة النمط الحالي في التوثيق الرسمي:

## Odoo

Odoo يربط Employee master data بالعقود والـAttendances وTime Off وPayroll/Work Entries، والعقد جزء من سلسلة الحساب وليس مجرد شاشة بيانات. كما يدير حالات العقود والمستندات. 

## Microsoft Dynamics 365 Human Resources

Time & Attendance يعتمد على calculation/approval groups وabsence setup، وتوجد طبقة واضحة لحساب واعتماد الوقت بدل اعتبار attendance مجرد CRUD.

## SAP SuccessFactors

Time Management يتعامل مع Time Sheets وClock In/Out وTime Off والـapproval والـalerts، مع تكامل مع time recording systems.

## Daftra

HRM يجمع Employee Records + Org Structure + Contracts + Attendance + Leave + Requests/Loans + dynamic salary components + Payroll، ويضيف ESS وقيود الموقع/الشبكة والبصمة في بعض السيناريوهات.

## Manager.io

Manager يملك Employee/Payroll capabilities مرتبطة بالـaccounting، لكنه benchmark أضيق من Odoo/Dynamics/SAP في عمق HR workflow.

### مصادر التحقق

- Odoo Employees / Payroll / Contracts:
  - https://www.odoo.com/documentation/18.0/applications/hr/employees.html
  - https://www.odoo.com/documentation/18.0/applications/hr/payroll.html
  - https://www.odoo.com/documentation/19.0/applications/hr/payroll/contracts.html
- Microsoft Dynamics 365 Human Resources:
  - https://learn.microsoft.com/en-us/dynamics365/human-resources/hr-set-up-time-and-attendance-information
  - https://learn.microsoft.com/en-us/dynamics365/human-resources/hr-update-time-and-attendance-information
- SAP SuccessFactors:
  - https://help.sap.com/docs/SAP_SUCCESSFACTORS_EMPLOYEE_CENTRAL/b84252bad1a94ee4a2977c5f91c64b3f/0f2eb16d58d84b8ab30edbbbc47cf5aa.html
  - https://www.sap.com/products/hcm/employee-time-tracking-software/features.html
  - https://help.sap.com/docs/successfactors-employee-central/operating-time-management-in-sap-successfactors/9b874bb10627450fad5c2ceff72c107f.html
- Daftra:
  - https://www.daftra.com/en/hrm/
  - https://www.daftra.com/en/payroll/
  - https://docs.daftra.com/en/user_manual/employee-attendance-logs/
  - https://www.daftra.com/en/attendance-leave-management/
- Manager.io:
  - https://www2.manager.io/manager.pdf

---

# 12. Benchmark Gap Matrix — RAWAEA HR

| Capability | RAWAEA current evidence | Competitive pattern | Current conclusion |
|---|---|---|---|
| Employee master | HR profiles + employees query/commands | Odoo/Dynamics/SAP/Daftra core | Present |
| Organization | departments/positions/assignments domain | Strong in Odoo/Daftra/SAP | Present in schema; runtime depth needs E2E proof |
| Contracts | HR contracts/components | Explicit contract lifecycle in Odoo/SAP/Daftra | Present as domain; E2E not yet closed |
| Attendance | attendance/events/work entries domain | attendance calculation + work entry concepts | Backend present; operational E2E open |
| Leave | leave requests/balances/types | balances + policy + approvals | Backend present; operational E2E open |
| Requests | request/approval domain | workflow approvals | Present as domain; full workflow open |
| Advances | salary advances | loans/advances linked to payroll | Present as domain |
| Payroll | payroll periods/runs/payslips/components | contract + attendance + rules → payslip | Strong domain basis; calculation E2E open |
| Documents | employee_documents + Storage | integrated employee documents | Present; direct DML now closed |
| Audit | hr_command_log | governance/audit trails | Actor identity now protected |
| ESS | Not independently proven | Daftra/SAP patterns | Open |
| Fingerprint/clock integration | Not independently proven | Daftra/SAP patterns | Open |
| Geofence/IP/photo attendance | Not part of proven current contract | Daftra pattern | Open / optional |
| Advanced payroll formulas | Not independently proven in runtime | Daftra/Odoo patterns | Open |
| Alerts | Not independently proven | SAP/Daftra patterns | Open |

الاستنتاج الحاكم: **لا نضيف هذه المزايا لمجرد منافسة الشكل**. كل capability مستقبلية يجب أن تمر Closure Unit منفصلة تثبت Business Contract + DB + permissions + runtime + accounting impact.

---

# 13. Final closure matrix

| Item | Evidence | Status |
|---|---|---|
| HR historical reconstruction | Governance + latest reports + Git | CLOSED |
| Current Mother source inspected | Git current source | CLOSED |
| main.html modified | verified unchanged | CLOSED = 0 changes |
| HR login route to Legacy | app.html current source | FIXED |
| Direct `/hr` legacy route | `_redirects` current source | FIXED |
| HR stale SW version | SW source | FIXED |
| HR actor spoof risk | Production test | FIXED |
| employee_documents direct DML | Production grant boundary | FIXED |
| HR authenticated context | Production JWT simulation | VERIFIED |
| HR core query path | Production | VERIFIED |
| HR core command path | Production | VERIFIED |
| HR business test data | none | CLEAN |
| Mother Git latest HEAD | `9a0b72...` | VERIFIED |
| Live Cloudflare/deployed artifact | no independently retrieved deployed URL in this session | OPEN |
| Authenticated browser E2E | not independently executed against live URL | OPEN |
| Full HR functional E2E | open by design until real HR data/test harness exists | OPEN |

---

# 14. Important negative findings

لم يتم اعتماد أي من التالي باعتباره سببًا للـparser failure الحالي:

- Tailwind production warning.
- إعادة بناء `main.html`.
- إعادة كتابة RW_HR بالكامل.
- إنشاء موظفين وهميين.
- تغيير OWNER wildcard semantics.

هذه كلها كانت ستنتج تعديلًا غير ضروري أو غير مثبت.

---

# 15. FINAL SELF-AUDIT

## What I Proved

- Mother current source لا يحتاج تعديل `main.html` لهذه closure.
- HR permission كان يفتح Legacy HR كتطبيق runtime مستقل.
- تم نقل HR runtime إلى Mother system.
- direct `/hr` route تم نقله أيضًا.
- تم إجبار Service Worker على republish boundary جديد.
- actor identity في HR audit أصبحت derived من user/company identity.
- `employee_documents` لم تعد قابلة لـdirect DML من anon/authenticated.
- HR RPC/query context يعمل للمستخدم HR الحقيقي.
- لم يتم اختلاق business data.

## What I Did Not Prove

- الوصول إلى deployed production URL في Cloudflare بشكل مستقل.
- authenticated browser E2E من المتصفح الحقيقي بعد آخر Git commit.
- اكتمال كل HR business flows end-to-end.
- device/ESS/geofence integrations.

## What I Initially Had To Reject

- اعتبار warning Tailwind سببًا للـparser failure.
- اعتبار تقارير 17 سبتمبر الحالة الحالية دون مطابقة source.
- إبقاء `office/hr.html` كruntime بدافع التوافق.

## Final closure status

```text
HR ARCHITECTURAL ROUTING            = CLOSED
HR AUDIT ACTOR INTEGRITY            = CLOSED
HR DOCUMENT DML BOUNDARY            = CLOSED
HR MOTHER SOURCE ALIGNMENT          = CLOSED
MAIN.HTML CHANGE COUNT              = 0
LIVE DEPLOYMENT VERIFICATION        = OPEN
AUTHENTICATED BROWSER E2E            = OPEN
FULL HR FUNCTIONAL CLOSURE           = OPEN
```

لا يجوز في الجلسة التالية تحويل Git/DB PASS إلى Production browser PASS.

---

# 16. تعليمات إلزامية للمساعد التالي

ابدأ بهذا التسلسل فقط:

```text
CURRENT_STATE
  ↓
CURRENT SYSTEM GIT HEAD + PARENT
  ↓
CURRENT MOTHER GIT HEAD + PARENT
  ↓
CURRENT main.html hash (verify unchanged)
  ↓
CURRENT HR app.html / _redirects / sw.js
  ↓
CURRENT SUPABASE HR migrations + grants + RPCs
  ↓
OBTAIN LIVE DEPLOYED URL
  ↓
FETCH LIVE APP
  ↓
BROWSER E2E
  ↓
AUTHENTICATED HR E2E
  ↓
ONLY THEN OPEN NEXT HR FUNCTIONAL CLOSURE
```

ممنوع إعادة تنفيذ أي migration من هذا التقرير، وممنوع إعادة إصلاح parser القديم دون دليل جديد من الـLIVE artifact.

إذا ظهر defect جديد، افتح Closure Unit واحدة فقط ولا تخلطها مع غيرها.

---

# 17. Production migrations executed in this session

```text
hr_employee_documents_table_dml_boundary_20260918
hr_command_log_actor_identity_guard_20260918
```

ولا توجد migrations HR أخرى أُنشئت هنا.

---

# 18. Git changes executed in Mother

```text
400b16d8cfd6226b02955fe6a2fb76f386e56dde
  hr: route HR login to Mother HR instead of legacy route

75af385fd4f402c107423a37d0d2b769de152105
  hr: retire legacy HR runtime route and republish boundary

9a0b72ef746f2f6f5c1b149edd2a490df39377c6
  hr: force republish with new SW build boundary
```

هذه التغييرات خارج `main.html` فقط.
