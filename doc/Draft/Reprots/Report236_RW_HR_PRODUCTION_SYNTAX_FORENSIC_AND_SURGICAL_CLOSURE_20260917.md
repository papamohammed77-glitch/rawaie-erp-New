# RAWAEA ERP — RW_HR Production Syntax Forensic & Surgical Closure
## 2026-09-17

## 1. Scope

هذه الجلسة أوقفت أي أعمال أخرى وركزت حصراً على عطل RW_HR الذي يمنع تجاوز شاشة الدخول.

العطل المرصود:

```text
(index):64 cdn.tailwindcss.com should not be used in production.
main:23839:1925 Uncaught SyntaxError: Unexpected token ')'
```

التحذير الخاص بـTailwind ليس سبب توقف التطبيق؛ هو تحذير Production hygiene.

الخطأ الحاجب للتنفيذ هو `SyntaxError` داخل JavaScript في `main.html`.

---

## 2. Current Git re-verification

تمت إعادة التحقق من آخر تسلسل Git في مستودع النظام.

آخر HEAD المثبت أثناء التحقيق:

```text
9b97ef495986e1d92a0448985fbb376f1b936a6f
ci(hr): enforce syntax-safe Mother HR surgical artifact
```

Parent:

```text
fab59e3300e91a280f1466c3ccbd7a751d45464f
```

والـCI commit أضاف Workflow يقوم بتطبيع token محدد في الـsurgical artifact ثم يشغّل:

```text
node --check doc/Draft/Reprots/HR_MOTHER_SURGICAL_REPLACEMENT_20260917_FINAL.js
```

هذا يثبت وجود Guard آلي للـartifact، لكنه لا يثبت أن `main.html` في Mother/Production قد تم استبداله بالـartifact.

---

## 3. Current Mother source

المصدر الفعلي هو:

```text
papamohammed77-glitch/erp-frontend
companies/company-1/main.html
```

HEAD المرجعي الذي تم فحصه:

```text
269d3fb7776005ae6c2d9431cf784bde4b434e92
```

Parent:

```text
2b8ef7a26716470020bb786566210c0c41a434dd
```

تم الوصول إلى محتوى `main.html` عبر GitHub Contents API، وتأكد وجود:

```html
<script src="https://cdn.tailwindcss.com"></script>
```

وهو مصدر التحذير المذكور في Console.

الـMother `main.html` لم يتم تعديله خلال هذا التحقيق.

---

## 4. Root-cause determination

الـConsole يحدد موضعاً داخل `payrollTab`:

```javascript
async function payrollTab(cn){
  ...
  return tr([
    esc(x.employee_name),
    esc(x.period_code),
    money(x.gross),
    money(x.deductions),
    money(x.net),
    esc(x.status||'-')
  ]))
  ...
}
```

النسخة التي سببت العطل تحتوي إغلاقاً زائداً في نهاية سلسلة `map/table`:

```text
esc(x.status||'-')]))));
```

بينما الإغلاق الصحيح لهذا التركيب هو:

```text
esc(x.status||'-')])));
```

أي أن السبب المباشر هو:

```text
EXTRA CLOSING PARENTHESIS
→ JavaScript parser failure
→ script block fails to parse
→ initialization code after/beside the script is not safely executable
→ login/runtime flow is blocked
```

هذا ليس خطأ في Supabase HR Core ولا في `hr_query` ولا في `hr_command_atomic`.

---

## 5. Why the login is affected by a payroll syntax error

`main.html` يجمع Runtime النظام الأم وRW_HR داخل JavaScript كبير واحد.

لذلك وجود SyntaxError في `payrollTab` لا يعني أن payroll وحده يتعطل.

الـbrowser يقوم بعملية parsing للـscript قبل التنفيذ.

إذا فشل parsing:

```text
SyntaxError
→ script does not execute
→ bootstrap/login handlers may never be registered
→ application remains on login screen
```

ولهذا فالعطل الظاهر في Login هو أثر Runtime عام، وليس دليلاً على أن authentication نفسها هي Root Cause.

---

## 6. Surgical solution

المبدأ المعتمد:

```text
DO NOT TOUCH main.html OUTSIDE RW_HR
DO NOT REWRITE THE APPLICATION
DO NOT CHANGE HR CORE
DO NOT CREATE A SECOND HR ENGINE
```

الإصلاح الجراحي الجاهز موجود في:

```text
doc/Draft/Reprots/HR_MOTHER_SURGICAL_REPLACEMENT_20260917_FINAL.js
```

وهو replacement كامل لوحدة `RW_HR` فقط.

كما أضيف Guard آلي:

```text
.github/workflows/hr_surgical_artifact_normalizer.yml
```

ويقوم الـGuard بتصحيح token المعروف فقط إذا ظهر مرة واحدة، ثم يرفض الحالة إذا ظهر أكثر من occurrence، وبعد ذلك يشغّل `node --check`.

هذا يحول الخطأ من خطأ بشري متكرر إلى failure قابل للكشف آلياً قبل قبول الـartifact.

---

## 7. Production / deployment status

حتى نهاية هذا التحقيق لا يوجد دليل كافٍ يسمح بإعلان:

```text
Mother main.html cutover = PASS
Production served artifact = PASS
Authenticated browser login = PASS
RW_HR browser E2E = PASS
```

لذلك لم يتم إعلان Closure زائف.

الحالة الصحيحة:

```text
Root cause                         = IDENTIFIED
Surgical correction                = READY
Artifact syntax guard              = PRESENT
Mother main.html modification       = NOT PERFORMED
Production cutover                  = OPEN
Browser verification                = OPEN
Overall RW_HR                       = OPEN
```

---

## 8. HR benchmark conclusions

المقارنة الوظيفية الحديثة لا تستخدم لترتيب المنتجات، بل لتحديد العقد التي يجب ألا يفقدها RAWAEA.

Odoo يربط ملف الموظف بالمعلومات الشخصية والوظيفية والعقود والأقسام والمهارات والإجازات والمستندات والتكاملات، ويقدم onboarding/offboarding وorg chart وself-service عبر منظومة HR. citeturn0search3turn0search5turn0search15

Dynamics 365 Human Resources يغطي personnel management، organizational hierarchies، leave/absence، benefits، compensation، performance، learning، workflows وemployee/manager self-service. citeturn0search0turn0search1turn0search16turn0search23

SAP SuccessFactors Employee Central يعتمد people/organization/job/pay data مركزياً مع history وeffective-dated objects وworkflows، بينما Time Management يغطي time recording وabsence وbalances وmanager approvals، وEmployee Central Payroll يغطي دورة payroll حتى posting للمالية. citeturn0search7turn2search3turn2search5turn2search9

Daftra يربط employee records وorganizational structure وcontracts وattendance وleave وpayroll وrequests، ويعرض pay runs وpayslips وapproval/payment roles والربط المحاسبي. citeturn2search1turn2search7turn2search14turn2search18

### Implication for RAWAEA

Core الحالي يغطي جزءاً قوياً من:

```text
Employee data
Organization
Assignments
Contracts
Schedules
Attendance
Leaves
Requests / approvals
Advances
Payroll foundation
Documents
Accounting map
```

لكن الـproduction-grade completion لا يساوي مجرد وجود هذه الجداول أو التبويبات. يجب أن يظل العقد المستهدف:

```text
Central employee identity
→ effective-dated employment history
→ organization / position / branch
→ attendance / leave
→ requests / approvals
→ compensation / payroll
→ documents
→ accounting
→ self-service / manager workflows
→ audit / security
```

وهذا يتفق مع اتجاهات Odoo/Dynamics/SAP/Daftra المذكورة أعلاه دون نسخ تصميم أي منتج.

---

## 9. Required next closure gate

الخطوة التالية الوحيدة المرتبطة بهذا incident:

```text
1. Use the corrected surgical RW_HR artifact.
2. Replace ONLY RW_HR in Mother main.html.
3. Run full-file JavaScript syntax validation on the assembled main.html.
4. Deploy the resulting Mother artifact.
5. Verify served artifact identity.
6. Open authenticated browser session.
7. Verify login.
8. Open HR tab.
9. Verify all HR sub-tabs.
10. Verify payroll tab specifically.
11. Re-check console for SyntaxError.
12. Re-check Production DB after browser actions.
```

Only after these gates pass may RW_HR move from `OPEN` to `CLOSED`.

---

## 10. Session continuation instructions

المساعد التالي لا يبدأ من الصفر.

يبدأ من:

```text
CURRENT GIT
CURRENT MOTHER SOURCE
CURRENT PRODUCTION
CURRENT DATABASE
CURRENT DEPLOYMENT EVIDENCE
```

والحقيقة الجديدة التي يجب عدم إعادة التحقيق فيها دون سبب هي:

```text
The blocking parser error is an extra closing parenthesis in payrollTab's final payslip table expression.
```

أما ما لم يُثبت فهو:

```text
Whether the corrected surgical artifact has actually been cut into Mother main.html.
Whether Production is serving the corrected artifact.
Whether authenticated browser E2E passes after cutover.
```

**No false closure.**
