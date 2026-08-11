# RAWAEA EXECUTION GUARDRAILS

**Status:** ACTIVE
**Purpose:** حماية النظام أثناء التنفيذ.

## Non-negotiable

المساعد يملك: الفحص، التحليل، التنفيذ، الاختبار، التحقق، التوثيق، والتصعيد.

لا يملك: اختراع Business Rules، تغيير Source of Truth، إعادة تصميم Domain، إنشاء نظام بديل، حذف نظام قائم، تغيير Security Model، تعطيل RLS، أو تنفيذ Migration خطرة دون خطة Rollback.

## No Guessing

ممنوع التخمين أو الافتراض أو اختراع أسماء جداول/أعمدة/علاقات/Business Rules أو افتراض أن Function/Table/Trigger غير مستخدمة.

إذا لم توجد المعلومة: `UNKNOWN`.

## No Destruction

لا DROP/TRUNCATE/DELETE واسع النطاق/تغيير نوع خطير/حذف Functions أو Triggers أو Policies أو تعديل Production جماعيًا دون سبب موثق، Recovery/Backup مناسب، Rollback، Verification وموافقة صريحة عند الحاجة.

## No Big Bang

كل تغيير:

Inspect → Understand → Plan → Implement → Test → Verify → Commit.

## Minimal Change

Minimal Change > Compatible Change > Reversible Change > Large Refactor.

## Existing System First

الهدف إصلاح النظام الموجود وفق المعمارية، وليس بناء ERP جديد بجانبه.

## Single Source of Truth

قبل إضافة Table/Column/Cache/Derived State/Balance/Quantity يجب تحديد مصدر الحقيقة. إذا لم يكن واضحًا: STOP.

## Inventory Invariants

يجب الحفاظ على عدم السالبية حيث يسمح Business Policy، صحة الشركة/الفرع/الصنف، اتجاه الحركة، المصدر/الوجهة، قابلية التتبع، ومنع Duplicate Posting وفق القواعد المثبتة.

## Edge Functions

قبل تعديل أي Function: حدد caller، reads، writes، Business Rules، side effects، dependencies، consumers، وسبب التعديل. لا تحذف Legacy لمجرد أنها تبدو قديمة.

## Database First

تحقق من Tables, Columns, PK, FK, UNIQUE, CHECK, Indexes, Triggers, Views, Functions, RLS, Policies قبل أي تغيير.

## RLS

RLS جزء من Security Boundary. لا تعطله كحل لمشكلة Function/Query. أي تغيير في Auth/RLS/Company isolation/Branch isolation = STOP ما لم يكن ضروريًا ومثبتًا.

## Testing

اختبر Schema + Business Logic + Security + Data Integrity + Integration + Regression. نجاح الكود وحده ليس Completion.

## Before / After

سجل Current behavior, Current schema, dependencies, tests قبل التغيير، ثم New behavior, schema, dependencies, tests بعده.

## Stop Conditions

Business Rule مجهولة، تعارض مصادر، فقد بيانات محتمل، تغيير Security/Source of Truth/Architecture، dependency مجهولة، أو Test Failure غير مفسر = BLOCKED.

## Escalation

```text
BLOCKED
Domain:
Task:
Observed:
Expected:
Unknown:
Risk:
Proposed Options:
Required Decision:
```

## No Repeated Work

استخدم Evidence الموجود. لا تعيد الاستعلام إلا إذا تغيرت الحقيقة أو ظهرت inconsistency أو أصبحت الأدلة غير صالحة.

## No Scope Creep

المشاكل الجانبية تسجل FOLLOW-UP ولا تُنفذ أثناء المهمة الحالية.

## Completion

المهمة مكتملة فقط عند:

Code Changed + Tests Passed + Data Integrity Verified + Security Verified + Dependencies Checked + No Unresolved Regression + Commit + Result Report.

## Final rule

**أقل تغيير صحيح، بأقل مخاطرة، أعلى قابلية للتحقق والتراجع، دون انحراف عن معمارية RAWAEA.**
