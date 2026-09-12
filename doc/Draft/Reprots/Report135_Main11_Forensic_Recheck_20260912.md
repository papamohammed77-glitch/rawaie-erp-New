# تقرير 135 — إعادة الفحص الجنائي النهائي لـ Main11 بعد Owner Apply والمزامنة الحالية — 2026-09-12

## 0. الهدف الحاكم — يجب قراءته بعناية

**هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا يُتعامل معه كإضافات شكلية.**

وهذا متسق حرفيًا مع مبدأ الحوكمة: **الدراسة أولًا، ثم إعادة بناء العقد التاريخي، ثم تتبع السلوك الحالي، ثم تحديد الفجوة، ثم التعديل الجراحي، ثم الاختبار والتحقق.**

وتكرر هذه الدورة نفس الهدف دون أي تخفيف: **الوظائف الناقصة والواجهات الهيكلية لا تُعتبر مكتملة؛ المطلوب اكتمال وظيفي قابل للاستخدام والتحقق، لا مجرد وجود Screen أو Button.**

---

## 1. قاعدة الحكم المستخدمة

تم التعامل مع التقارير السابقة كمؤشرات فقط، وليس كمصدر حقيقة.

ترتيب الحكم:

`Production current > Database current > Deployment current > Current Git > Historical source > Reports > Memory > Assumption`

قواعد الإغلاق:

- `NO EVIDENCE = NO CLAIM`
- `NO EOF = NO FULL READ`
- `NO FUNCTIONAL TEST = NO FUNCTIONAL VERIFICATION`
- `NO PRODUCTION CHECK = NO PRODUCTION VERIFICATION`
- `NO DATA CHECK = NO DATA CLOSURE`
- لا Assembly قبل إغلاق Main11 حسب البوابات المعتمدة.

---

## 2. نقطة مهمة اكتُشفت فور إعادة الاسترجاع

Report134 كان يثبت Main11 على SHA قديم:

`2adfc787c3e5f0ca56abfcc85232e7a971773c3b`

لكن الفحص المباشر لـGit الحالي أثبت أن المصدر الحاكم تغيّر بالفعل بعد ذلك إلى:

`Current/PWA/main2/main11.md`

SHA الحالي:

`c4c954e9610c60182358a42665195d05cd3c3405`

الحجم الحالي:

`43413 bytes`

كما أن نهاية الملف أصبحت قبل السطر 530، والنطاق 530–540 فارغ، بينما السطر الختامي يحتوي `</script>`, `</body>`, `</html>`.

إذن Report134 لم يعد يعكس الحالة الحالية. تم اعتماد Git الحالي بدلًا منه.

---

## 3. المصادر التي تمت مراجعتها

تمت مراجعة:

- `MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`
- `Report133_Main10_Forensic_Recheck_R3_20260912.md`
- `Report134_Main11_Forensic_Recheck_20260912.md`
- `MAIN11_OWNER_SURGICAL_REPLACEMENTS_20260912.js`
- `MAIN11_OWNER_MICRO_FIX_20260912.js`
- `CURRENT_STATE.md`
- `Current/PWA/main2/main11.md`
- `Current/PWA/main2/main1.md` للتحقق من بداية طبقة التطبيق والـHTML/Script boundary
- `Current/PWA/main2/main1..main11` directory tree
- `Original/PWA/main/main11.md`
- `forensic_main_assembly.yml`
- Production Supabase schema، RPCs، RLS، audit trigger path، migrations، والـcurrent data counts.

لم يتم استخدام `Current/PWA/main` أو `Current/PWA/New-main` كمصدر للحالة الحالية.

---

# 4. Main11 — القراءة الحالية الكاملة

## 4.1 HR

المصدر الحالي يحتوي بالفعل على:

- `RW_HR` واحد فقط.
- قراءة الموظفين عبر `hr_list_employees()` بدل `users.*`.
- ملف تعويضات فعلي من `employee_profiles`.
- حضور وانصراف فعلي.
- طلبات إجازة فعلية.
- عرض مستندات الموظف من `employee_documents`.
- رفع إلى private `employee-documents` storage.
- Signed URL لفتح المستند.
- البحث والتحديث والحالات الفارغة والأخطاء.

الـmicro fix الخاص بالوقت مطبق فعلًا في المصدر الحالي:

```js
var toISO=function(id){var v=byId(id).value;return v?new Date(v).toISOString():null;};
```

ولم تعد نسخة `+03:00` القديمة موجودة.

---

## 4.2 CRM

المصدر الحالي يحتوي بالفعل على:

- `RW_CRM` واحد فقط.
- `customersData` كمصدر القراءة المحلي بعد التحميل.
- قراءة العملاء Company-scoped.
- بحث محلي على نفس المصدر المحمل.
- Event binding مباشر بدل inline `onclick`.
- سجل متابعات العميل.
- إنشاء المتابعة عبر `crm_save_customer_followup()`.
- عرض حالة الفشل بدل تحويل خطأ القراءة إلى قائمة فارغة.

تمت مطابقة `customer_followups.customer_id` في Production، وهو `text`، وبالتالي استخدام `customer_code` في Current CRM متوافق مع Schema الحالي وليس Defect.

---

# 5. العيب الذي بقي بعد Owner Apply

## M11-03 — اعتماد/رفض الإجازة كان ما زال يكتب من Browser مباشرة

المصدر الحالي، عند السطر 256 تقريبًا، يحتوي الدالة:

```text
async function _setLeaveStatus(id,status,emp) {
    var currentUser=(RW_STATE&&RW_STATE.app&&RW_STATE.app.currentUser)||{};
    var res=await supabase.from('employee_leave_requests').update({status:status,approved_by:currentUser.email||'',approved_at:new Date().toISOString()}).eq('id',id).eq('company_id',_companyId());
    if(res.error){showToast('فشل تحديث الإجازة: '+res.error.message,'error');return;}
    showToast(status==='approved'?'تم اعتماد الإجازة':'تم رفض الإجازة','success');
    _openModal(emp.id);
}
```

هذا ليس مجرد موضوع Style؛ لأن `approved_by` و`approved_at` كانا يأتيان من Client state.

Production كانت تستخدم بالفعل Session-derived actor في بقية HR RPCs، ولذلك تم إغلاق الفجوة بحدود Backend جديدة بدل تخفيف الحارس في RLS.

---

# 6. التصحيح المطلوب من المالك في Main11

## OWNER ACTION — M11-03

FILE:

`Current/PWA/main2/main11.md`

SOURCE SHA الحالي:

`c4c954e9610c60182358a42665195d05cd3c3405`

المكان:

`السطر 256 تقريبًا`

## احذف هذا العنصر كاملًا

ابحث حرفيًا عن:

```text
async function _setLeaveStatus(id,status,emp) {
```

احذف **الدالة كاملة** حتى القوس `}` الأخير الخاص بها، والذي يأتي مباشرة قبل:

```text
async function _uploadDocument(emp) {
```

لا تحذف سطر `async function _uploadDocument(emp) {`.

## استبدلها بالكامل بهذا العنصر

```js
    async function _setLeaveStatus(id,status,emp) {
        var res=await supabase.rpc('hr_set_leave_status',{
            p_leave_request_id:id,
            p_status:status,
            p_notes:null
        });
        if(res.error){showToast('فشل تحديث الإجازة: '+res.error.message,'error');return;}
        showToast(status==='approved'?'تم اعتماد الإجازة':'تم رفض الإجازة','success');
        _openModal(emp.id);
    }
```

هذا هو التعديل المطلوب من المالك في Main11 في هذه الدورة.

لا يوجد طلب لتعديل `hr_list_employees` في الملف؛ التصحيح المقابل تم تنفيذه في Production.

---

# 7. Production — التعديلات الفعلية التي نُفذت

## 7.1 HR Leave approval actor boundary

تم تنفيذ migration Production:

`20260912090311_main11_hr_leave_approval_actor_scope_20260912`

والـRPC:

`public.hr_set_leave_status(uuid,text,text)`

الخصائص:

- `SECURITY DEFINER`.
- Company Context من `app_private.current_user_company_id()`.
- Permission `hr`.
- قفل السجل `FOR UPDATE`.
- السماح فقط بالحالتين `approved` و`rejected`.
- السماح بالتغيير فقط من `pending`.
- `approved_by` من `users.auth_id = auth.uid()` وليس من Browser state.
- `approved_at = now()` داخل DB.

وتم أيضًا تقوية:

- `hr_save_attendance()` ليأخذ actor من Session Company Context ويحدث `updated_at`.
- `hr_upsert_employee_profile()` بنفس نمط actor derivation.

---

## 7.2 HR list semantics

تم تنفيذ migration Production:

`20260912090431_main11_hr_employee_list_include_inactive_20260912`

النسخة الفعلية في Production:

`20260912090431`

التغيير:

`hr_list_employees()` أصبح يعيد جميع موظفي الشركة، بينما تقوم الواجهة بحساب:

- إجمالي الموظفين.
- الموظفون النشطون.

وبذلك لم يعد مؤشر «إجمالي الموظفين» يستبعد الموظف غير النشط بصورة صامتة.

---

## 7.3 Production state بعد التعديلات

آخر migrations الفعلية:

```text
20260912090431  main11_hr_employee_list_include_inactive_20260912
20260912090311  main11_hr_leave_approval_actor_scope_20260912
20260912083643  main11_hr_crm_gold_capabilities_20260912
```

Production HR RPCs الحالية تتضمن:

```text
hr_list_employees
hr_set_leave_status
hr_save_attendance
hr_upsert_employee_profile
hr_create_leave_request
crm_save_customer_followup
```

الجداول الجديدة الحالية:

```text
employee_profiles
employee_attendance
employee_leave_requests
```

Production counts التي تم التحقق من المسار الحالي لم تُظهر بيانات إجازات قائمة تتطلب Repair؛ العدد الحالي لـ`employee_leave_requests` = `0`.

لم يتم حذف أو إعادة كتابة مستخدمين/عملاء/مستندات أو بيانات تشغيلية حقيقية بسبب عدم وجود Defect Data مثبت يبرر ذلك.

---

# 8. Security / Audit verification

تم التحقق من وجود RLS الحالية على:

- `employee_profiles`
- `employee_attendance`
- `employee_leave_requests`

والـpolicies تستخدم Company Context + HR permission.

تم التحقق من أن جداول HR الجديدة لها Audit Trigger باستخدام:

`fn_audit_trigger()`

كما أن المسار القائم للـStorage الخاص بمستندات الموظفين Private وCompany-scoped.

`audit_log` schema ومسار `fn_audit_trigger()` تم فحصهما مباشرة.

---

# 9. Assembly path

`forensic_main_assembly.yml` تم فحصه مباشرة، ويثبت:

```yaml
source_of_truth: Current/PWA/main2
historical_reference: Original/PWA/main
forbidden_sources:
  - Current/PWA/main
  - Current/PWA/New-main
assembly_status: deferred_until_all_fragments_are_owner_verified
```

لا يوجد Assembly في هذه الدورة.

---

# 10. Main2 reconciliation

تمت مطابقة directory الحالية مباشرة من Git، وجميع الأجزاء الـ11 موجودة تحت:

`Current/PWA/main2`

SHA الحالية:

```text
main1  f68d47c7574c34f678cfba2aafa5ad294aadbfe5
main2  65815e23b03e29c125957e6fe283cc1e253a7f7d
main3  eeb56daf8cd01b31b8a7e5f5ada4f1a09df30bfe
main4  e9f967859aeda729cd0811739a280ceec5266d7c
main5  800ad51c88a2e80d060480990836a3c975c7435a
main6  1dc500849a600e6436c1d319bdc93f3d270f6af9
main7  5839252a9807ae1758939dad754a4f3a4505c76f
main8  f67c0217a804d2cb2388ce48fb7f95176c075fb3
main9  b68e5d8f0f52258080950add12fd7fcecbf8c0d7
main10 a6d078d450f1a2182abff0eaf515b6861e66092b
main11 c4c954e9610c60182358a42665195d05cd3c3405
```

---

# 11. Syntax gate

تم إنشاء Gate دائم في Git:

`.github/workflows/_cto_forensic_main2_syntax_20260912.yml`

الغرض:

- تجميع `Current/PWA/main2/main1..main11.md` بنفس حدود النظام الفعلية.
- تنفيذ `node --check` على المصدر المجمع.
- تنفيذ Main11 structural gate.
- فحص:
  - RW_HR declaration count.
  - RW_CRM declaration count.
  - exported window objects.
  - micro-fix الحالي.
  - غياب `(قيد التطوير)` من Main11.

هذا لا يبدّل Source of Truth ولا يعد Assembly نشرًا.

نتيجة Node لم تُعلن هنا كـPASS قبل قراءة نتيجة الـworkflow بعد الـpush؛ قاعدة الحوكمة تمنع تحويل إنشاء الـGate إلى نجاح تنفيذي تلقائي.

---

# 12. لماذا لم يتم تعديل Main11 مباشرة

حسب فصل الصلاحيات المعتمد:

- Production DB/RPC/RLS = مسؤولية المساعد التنفيذية.
- `Current/PWA/main2/main1..main11.md` = مسؤولية المالك في التطبيق اليدوي.

لذلك تم إصلاح Production مباشرة، وتم تحويل التصحيح المتبقي في Main11 إلى Change Set محدد وكامل بدل الكتابة على المصدر من جهة المساعد.

---

# 13. ملفات Git الجديدة التي أضيفت

1. `doc/Draft/Reprots/MAIN11_OWNER_CORRECTION_R2_20260912.js`
2. `supabase/migrations/20260912090311_main11_hr_leave_approval_actor_scope_20260912.sql`
3. `supabase/migrations/20260912090431_main11_hr_employee_list_include_inactive_20260912.sql`
4. `.github/workflows/_cto_forensic_main2_syntax_20260912.yml`
5. `doc/Draft/Reprots/Report135_Main11_Forensic_Recheck_20260912.md`

لم يتم حذف أي تقرير سابق.

---

# 14. الأخطاء والتجارب

## ما نجح

- الاسترجاع من Current Git بدل الاعتماد على Report134.
- إثبات Owner Apply الفعلي على Main11.
- إثبات تطبيق micro fix فعليًا في Main11.
- إثبات CRM company-scoped read/write model.
- إثبات HR new tables/RPCs/RLS/Audit.
- إضافة actor-safe leave approval RPC.
- تصحيح HR total employee semantics في Production.
- تثبيت مسار syntax gate دائم للمصدر الصحيح.

## ما فشل أو بقي غير مكتمل

- لا يمكن إعلان Browser E2E حي من غير جلسة Browser/Auth حقيقية متاحة في أدوات الجلسة.
- `node --check` على live Git blob لم يُنفذ محليًا بسبب عدم توفر artifact محلي موثوق من GitHub داخل بيئة التنفيذ؛ لذلك أُنشئ Gate دائم ويجب أخذ نتيجته من GitHub Actions.
- لم يتم تنفيذ Assembly.
- لم يتم إعلان Global Gold/Diamond.
- Payroll-to-GL ما زال بلا Contract محاسبي Production مثبت، ولذلك لم يتم اختراع حسابات رواتب.

---

# 15. ما تم إصلاحه مقابل ما لم يُصلح

## Fixed

- HR safe employee read.
- HR compensation source.
- HR attendance capability.
- HR leave request capability.
- HR document usage.
- CRM followup canonical write.
- Leave approval actor boundary in Production.
- HR employee count semantics in Production.
- Permanent syntax gate for `Current/PWA/main2`.

## Not fixed by design

- Payroll accounting integration.
- Assembly.
- Final integrated Browser/E2E closure.
- Global Gold/Diamond closure.

السبب في العناصر الأخيرة ليس نقصًا في الرغبة في التنفيذ، بل وجود شروط Evidence/Contract لازمة قبل الادعاء بالإغلاق.

---

# 16. Final Self-Audit

## What I Proved

- الوثائق الحاكمة قُرئت، وتم الرجوع للمصدر الحالي مباشرة.
- Report134 كان stale بالنسبة لـMain11 الحالي، وتم تجاوز الاعتماد عليه.
- Main11 الحالي هو `c4c954e9610c60182358a42665195d05cd3c3405`.
- Main11 الحالي مقروء حتى EOF الحالي.
- micro fix موجود.
- HR/CRM replacement الحالي موجود في المصدر.
- العيب المتبقي في `_setLeaveStatus` محدد بدقة.
- RPC `hr_set_leave_status` منشور في Production ومتحقق من Security Definer وتوقيعه.
- `hr_list_employees` في Production تم تصحيح Semantics الخاصة بالإجمالي.
- Main2 tree الحالية تحتوي 11 fragment.
- `forensic_main_assembly.yml` يشير للمسار الصحيح.
- لا Assembly تم.

## What I Did Not Prove

- Browser E2E حي للمستخدم الحقيقي.
- Node syntax PASS للـlive assembled blob داخل هذه الجلسة نفسها قبل نتيجة Actions.
- اكتمال جميع وحدات Gold/Diamond خارج نطاق Main11.
- Payroll accounting contract.

## What Remains

المالك فقط يطبق M11-03 في `Current/PWA/main2/main11.md`.

بعد ذلك:

```text
re-read Main11 1→EOF
→ recompute SHA
→ GitHub syntax gate
→ HR/CRM runtime
→ Production snapshot at report time
→ data/audit/RLS verification
→ Main11 Closure Gate
→ only then consider Assembly
```

---

# 17. الحالة النهائية لهذه الدورة

```text
GOVERNANCE REVIEW = PASS
CURRENT GIT RECONCILIATION = PASS
MAIN11 FULL SOURCE RECHECK = PASS
MAIN11 CURRENT EOF = VERIFIED
MAIN11 MICRO FIX = PRESENT
MAIN11 HR/CRM OWNER APPLY = PRESENT
M11-03 LEAVE APPROVAL ACTOR FIX = PRODUCTION READY / OWNER SOURCE PATCH PENDING
PRODUCTION HR/CRM FOUNDATION = DEPLOYED
PRODUCTION HR ACTOR RPC = DEPLOYED
PRODUCTION HR LIST SEMANTICS = CORRECTED
PRODUCTION RLS = VERIFIED
PRODUCTION AUDIT = VERIFIED
MAIN2 TREE = VERIFIED
ASSEMBLY PATH = VERIFIED
PERMANENT MAIN2 SYNTAX GATE = ADDED
ASSEMBLY = DEFERRED
PAYROLL GL CONTRACT = OPEN
GLOBAL GOLD/DIAMOND = OPEN
MAIN11 FULLY CLOSED = NO — OWNER PATCH + EXECUTABLE/RUNTIME GATES REMAIN
```

# END OF REPORT135
