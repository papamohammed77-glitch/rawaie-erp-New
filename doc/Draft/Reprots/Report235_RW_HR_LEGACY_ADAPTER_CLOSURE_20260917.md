# RAWAEA ERP — تقرير إغلاق Legacy Writers داخل RW_HR
## 2026-09-17 — ملحق تنفيذي حاكم بعد Report234

## 1. الغرض

هذا التقرير مكمل لتقرير `Report234_RW_HR_FORENSIC_REEXECUTION_FULL_20260917.md` ولا يعيد التحقيقات التي ثبتت فيه.

الغرض الوحيد هو توثيق آخر Closure تم فعليًا بعد إعادة تشغيل المهمة: تحويل وظائف HR التاريخية التي ما زالت Mother تستدعيها إلى Compatibility Adapters فوق `hr_command_atomic`، بحيث لا تبقى Writer Engines مستقلة.

## 2. Production change

تم تطبيق migration:

```text
20260917
hr_legacy_compatibility_adapters
```

وظائف التوافق:

```text
hr_upsert_employee_profile
hr_save_attendance
hr_create_leave_request
hr_set_leave_status
```

لم تعد تنفذ `INSERT/UPDATE` مباشرة على HR business tables.

## 3. Canonical routing

```text
hr_upsert_employee_profile
→ hr_command_atomic('employee.profile.upsert', payload, operation_id, actor_id, actor_email)

hr_save_attendance
→ hr_command_atomic('attendance.day.upsert', payload, operation_id, actor_id, actor_email)

hr_create_leave_request
→ hr_command_atomic('leave.request.create', payload, operation_id, actor_id, actor_email)

hr_set_leave_status('approved')
→ hr_command_atomic('leave.request.approve', payload, operation_id, actor_id, actor_email)

hr_set_leave_status('rejected')
→ hr_command_atomic('leave.request.reject', payload, operation_id, actor_id, actor_email)
```

كل Adapter يستخرج actor/company من الجلسة الحالية، ويولّد operation identity حتمية من payload، ثم يفوض المسؤولية كاملة للـCore.

## 4. Runtime verification

في transaction واحدة وبـJWT context لمستخدم HR موجود فعليًا في Production:

```text
hr_upsert_employee_profile = PASS
hr_save_attendance          = PASS
hr_create_leave_request     = PASS
hr_set_leave_status         = PASS
```

أُنشئت سجلات اختبارية مؤقتة فقط داخل نفس transaction، ثم تم `ROLLBACK`.

التحقق بعد rollback:

```text
employee_profiles        = 0
employee_attendance      = 0
employee_leave_requests  = 0
hr_command_log           = 0
```

## 5. Writer discovery closure

تم البحث في تعريفات PostgreSQL عن وظائف HR أخرى تحتوي mutation مباشرة على `hr_*` أو `employee_*` tables.

النتيجة المتبقية:

```text
hr_payroll_calculate_impl
hr_payroll_post_impl
```

هذه ليست Client Writers مستقلة؛ كلاهما `service_role` فقط ولا يملك `authenticated` أو `anon` execute، وكلاهما مستدعى من `hr_command_atomic` ضمن Payroll Core.

إذن بنية الكتابة أصبحت:

```text
Mother/legacy adapter
        ↓
hr_command_atomic
        ↓
Payroll implementation helpers (service-only where required)
        ↓
HR business tables
```

ولا يوجد Client HR Writer Engine مستقل مثبت في Production خارج هذا المسار.

## 6. Security state

تم التحقق أن Direct HR table DML grants للمستخدمين `anon/authenticated` تساوي:

```text
0
```

والـlegacy mutation RPCs نفسها:

```text
anon execute = false
```

بينما `authenticated` يحتفظ بالوصول إليها فقط لأن Mother الحالية ما زالت Consumer لها، مع تحولها إلى Delegates فقط.

## 7. Closure interpretation

إغلاق الـlegacy Writer هنا لا يعني حذف API surface القديم.

المعيار المعماري هو:

```text
Legacy API compatibility may remain.
Legacy business writer may not remain.
```

وبذلك يكون الـlegacy surface مجرد Transport/Compatibility Layer حتى يتم تركيب replacement في Mother وإثبات أن الـconsumer القديم لم يعد مستخدمًا.

## 8. What remains open

لا يزال مطلوبًا تنفيذ Mother cutover:

```text
Current Mother RW_HR
→ exact surgical replacement
→ browser syntax validation
→ real authenticated browser E2E
```

وبعد إثبات ذلك فقط يُتخذ قرار إزالة Compatibility Adapters نهائيًا.

## 9. Final status

```text
HR Core writers                     = centralized
Legacy independent HR writers      = closed
Compatibility adapters             = active / delegate-only
Direct client HR DML              = 0
Mother surgical replacement        = ready
Mother main.html                  = untouched
Browser E2E                        = open
Overall RW_HR                      = not closed
```

## 10. Next-session rule

لا تبدأ HR من جديد.

ابدأ من:

```text
CURRENT GIT
CURRENT MOTHER SOURCE
CURRENT PRODUCTION
CURRENT DATABASE
CURRENT DEPLOYMENT
```

ثم نفّذ cutover الجراحي للـRW_HR وحده، وبعده Browser E2E، ثم أعد قراءة Production قبل إعلان الإغلاق.

## 11. Canonical adapter artifact

`doc/Draft/Reprots/HR_LEGACY_ADAPTERS_20260917.sql`

## 12. Main full report

`doc/Draft/Reprots/Report234_RW_HR_FORENSIC_REEXECUTION_FULL_20260917.md`
