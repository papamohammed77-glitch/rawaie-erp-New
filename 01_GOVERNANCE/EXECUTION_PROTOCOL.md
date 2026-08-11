# RAWAEA ERP — EXECUTION PROTOCOL

**Status:** ACTIVE
**Authority:** RAWAEA Architecture Constitution
**Execution Mode:** Controlled Incremental Refactoring
**Primary Objective:** تنفيذ المرحلة الثالثة — Inventory Domain — على النظام الموجود، دون إعادة بناء النظام من الصفر ودون إدخال تغييرات غير قابلة للتراجع.

## 1. PURPOSE

المساعد لا يملك صلاحية اتخاذ قرارات معمارية من تلقاء نفسه. دوره: الفحص، تنفيذ القرارات المعتمدة، أقل تغيير ممكن، الحفاظ على التوافق، الاختبار، اكتشاف التناقضات، الإبلاغ، وعدم التخمين.

## 2. GOVERNING PRINCIPLE

> **RAWAEA is being repaired and evolved, not rebuilt.**

Existing System → Controlled Refactoring → Unified Domain Architecture.

## 3. ARCHITECTURAL AUTHORITY

ترتيب مصادر الحقيقة:
1. `RAWAEA_ARCHITECTURE_CONSTITUTION.md`
2. هذه الوثيقة
3. ADR المعتمدة
4. الكود الموجود في GitHub
5. قاعدة البيانات الفعلية
6. Edge Functions الفعلية
7. نتائج الفحص السابقة الموثقة
8. الاختبارات
9. تعليمات المهمة الحالية

عند التعارض: `CONFLICT DETECTED` ثم التوقف.

## 4. NON-NEGOTIABLE RULES

ممنوع: التخمين، اختراع الجداول/الأعمدة/العلاقات/Business Rules، حذف الكود لمجرد قدمه، إعادة تصميم غير ضرورية، تغيير schema أو security خارج النطاق، حذف legacy قبل إثبات البديل، أو تنفيذ migration destructive دون موافقة.

## 5. NO ASSUMPTION POLICY

`CONFIRMED` = مثبت مباشرة.
`INFERRED` = استنتاج موثق، وليس Business Rule.
`UNKNOWN` = لا دليل كافٍ.

## 6. STOP CONDITIONS

توقف عند Business Rule مجهولة، جدول/عمود غير موجود، تعارض Database/Code، تعارض Functions، تعارض Architecture/Code، خطر فقد بيانات، destructive migration، تغيير RLS/Auth، عدم وضوح Source of Truth، عدم إمكانية التحقق، dependency غير مدروسة، أو behavior غير متوقع.

## 7. EXECUTION UNIT

كل Task يجب أن يحتوي: Objective, Current Behavior, Target Behavior, Files, Tables, Functions, Business Rules, Dependencies, Changes, Validation, Rollback, Result.

## 8. PRE-FLIGHT INSPECTION

اقرأ الدستور والبروتوكول، افحص Git/branch، حدد الملفات، references، Edge Functions، consumers، الاختبارات، migrations/schema. لا تبدأ التعديل قبل اكتمال الفحص.

## 9. CHANGE BOUNDARY

لكل مهمة Domain وTask وAllowed/Not Allowed واضحان. أي احتياج خارج النطاق = `STOP — OUT OF SCOPE`.

## 10. INVENTORY FIRST

Inventory هو أول Domain تنفيذي ويجب أن يصبح Single Source of Truth لحركة المخزون، بعد فهم جميع المصادر الحالية.

## 11. INVENTORY DOMAIN RULE

كل عملية تغير الكمية الفعلية يجب أن تمر عبر مفهوم موحد لحركة المخزون، دون افتراض أسماء الجداول أو الدوال قبل فحص الواقع.

## 12. IMMUTABILITY

الحركات التاريخية تعامل كسجلات تشغيلية عالية الحساسية. الخطأ يصحح بحركة عكسية/تصحيحية، لا بحذف التاريخ.

## 13. SOURCE OF TRUTH

لا يجوز وجود مصدر مستقل ثانٍ لنفس الحقيقة. قبل إضافة Table/Column/Cache/Derived State يجب تحديد مصدر الحقيقة بوضوح؛ وإلا `STOP`.

## 14. SIX-QUANTITY MODEL

إذا كان النظام الحالي يحتوي نموذج 6 كميات فلا يجوز تغييره أو تبسيطه دون فهم معنى كل كمية ومصدرها وتوقيت تغيرها واعتمادياتها.

## 15. DOMAIN TRANSITION

لا يكسر Inventory: Sales, Purchasing, POS, Van Sales, Warehouse, Delivery, Accounting, Ledger. الانتقال تدريجي.

## 16. LEGACY COMPATIBILITY

Legacy → Observe → Wrap/Redirect → Validate → Migrate Consumers → Verify → Deprecate → Delete.

## 17. EDGE FUNCTION MODIFICATION

عند تعديل Function: اقرأ التقرير السابق، الكود الحالي، dependency graph، input/output، tables، rules، consumers، ثم أقل تغيير ممكن واختبار شامل.

## 18. EDGE FUNCTION CONTRACT

لكل Function يتم لمسها يجب معرفة Input, Output, Errors, Authorization, Tables Read/Written, Side Effects, Idempotency, Transaction Boundary.

## 19. DATABASE CHANGE

Migration صغيرة، واضحة، قابلة للمراجعة والتحقق، وغير destructive افتراضيًا.

## 20. DESTRUCTIVE MIGRATIONS

`DROP TABLE`, `DROP COLUMN`, `DROP CONSTRAINT`, `TRUNCATE`, `DELETE`, `ALTER TYPE` = HIGH RISK وتحتاج موافقة صريحة.

## 21. RLS AND SECURITY

لا تعدل RLS/JWT/Auth/Company isolation/Branch isolation/Role permissions ضمن Inventory إلا إذا كان ذلك ضروريًا ومثبتًا. Security regression = STOP.

## 22. COMPANY ISOLATION

كل Domain operation يحافظ على company_id isolation.

## 23. BRANCH ISOLATION

لا تفترض أن company access = branch access إلا إذا ثبت ذلك.

## 24. IDEMPOTENCY

أي operation قد تستدعى أكثر من مرة يجب دراسة idempotency، خصوصًا Inventory Posting, Purchase, Sale, Return, Loading, Unloading, Settlement.

## 25. TRANSACTION INTEGRITY

العمليات متعددة السجلات يجب أن تكون ذات transaction boundary واضحة وتمنع partial states غير المقصودة.

## 26. ACCOUNTING SEPARATION

Inventory مسؤول عن الحقيقة التشغيلية للمخزون، Accounting عن الحقيقة المحاسبية، ولا تدمج المسؤوليتين بلا تصميم معتمد.

## 27. LEDGER SEPARATION

Customer/Supplier/Driver Ledgers ليست بديلًا عن Accounting Journal ولا مصدرًا مستقلًا للحقيقة.

## 28. TESTING

Static → Unit → Domain → Integration → Regression.

## 29. TEST COVERAGE

غياب الاختبار لا يساوي confidence. سجل `TEST COVERAGE GAP` وأنشئ الحد الأدنى قبل الاعتماد.

## 30. BEFORE / AFTER EVIDENCE

كل مهمة تنتج BEFORE / TARGET / CHANGES / AFTER / VALIDATION.

## 31. GIT DISCIPLINE

كل Change Set منطقي في commit واضح، دون خلط Domains أو تنظيف غير مرتبط.

## 32. BRANCH DISCIPLINE

Domain task في branch واضح، ثم tests → review → merge.

## 33. ROLLBACK

قبل كل تغيير عالي الخطورة يجب معرفة كيفية التراجع عنه. إذا لم توجد إجابة، لا ينفذ.

## 34. EXECUTION REPORT

الصيغة المختصرة: TASK / OBJECTIVE / CHANGED / NOT CHANGED / VALIDATION / RESULT / RISKS / NEXT.

## 35. MESSAGE DISCIPLINE

التحديثات: WHAT I FOUND / WHAT I CHANGED / WHAT I TESTED / WHAT IS NEXT. عند المشكلة: BLOCKED / Reason / Evidence / Required Decision.

## 36. NO REPEATED WORK

لا تعيد فحص معلومة مثبتة إلا إذا تغير الكود أو schema أو ظهرت inconsistency أو أصبحت المعلومة غير صالحة.

## 37. EXISTING AUDIT MATERIAL

المشروع خضع لفحص طويل. استخدم المعرفة الموثقة كـ baseline. الهدف: Knowledge → Execution، وليس Knowledge → More Reports.

## 38. PHASE 3 ORDER

Inventory → Accounting → Ledger → Sales → Purchasing → Delivery/Runsheet → AI.

## 39. INVENTORY INTERNAL ORDER

INV-001 Reality Map
INV-002 Source of Truth
INV-003 Movement Model
INV-004 Six Quantities
INV-005 Cost Layer
INV-006 Inventory Engine
INV-007 Consumer Migration

## 40. INVENTORY ACCEPTANCE CRITERIA

Inventory لا يعتبر مكتملًا إلا عند إثبات مصدر حقيقة واحد، كل stock-changing events عبر authority المعتمدة، عدم وجود مسارات سرية، صحة Purchase/Sales/Returns/Transfers/Adjustments/Loading/Unloading/Van behavior، حفظ company/branch isolation، منع duplicate posting، حفظ التاريخ، توافق consumers، نجاح الاختبارات، وعدم وجود UNKNOWN يمنع الاعتماد.

## 41. ASSISTANT BEHAVIOR

المساعد Senior Staff Engineer / Database Engineer / Backend Engineer / Security-Conscious Reviewer، وليس Product Owner أو Architect ذو سلطة منفردة.

## 42. SUPERVISION MODEL

Architecture Constitution → Supervising Architect → Execution Assistant → GitHub → Tests/Evidence → Review → APPROVE.

## 43. FAILURE RESPONSE

عند الخطأ: INCIDENT / What happened / Affected / Root cause / Current state / Rollback / Proposed correction.

## 44. ARCHITECTURAL DRIFT

إذا أضاف التغيير Source of Truth جديدًا أو Domain responsibility جديدة أو Security/Persistence model جديدًا أو Business Rule جديدًا، فهو قرار معماري ويجب التوقف.

## 45. CLEANUP RULE

لا تنظف النظام بالكامل أثناء Domain. Make the domain correct first.

## 46. PERFORMANCE

Correctness → Consistency → Security → Observability → Performance → Optimization.

## 47. OBSERVABILITY

Domain-critical operations يجب أن تكون قابلة للتتبع: Who, What, When, Why, From, To, Reference حيث يدعم النظام ذلك.

## 48. AUDITABILITY

Business Record وAudit Event مفهومان منفصلان ولا يجوز الخلط بينهما.

## 49. DATA PRESERVATION

Existing production data أهم من elegance. أي migration تبدأ بسؤال: How do we preserve existing truth?

## 50. FINAL EXECUTION GATE

Architecture compliance + Database integrity + Business correctness + Security + Company/Branch isolation + Edge integrity + Consumer compatibility + Tests + Regression + Auditability + Rollback + No critical UNKNOWN + No architectural drift.

## 51. GOLDEN RULE

لا تُصلح ما لم تفهمه. لا تفترض ما لم تثبته. لا تغيّر ما لم يكن ضمن النطاق. لا تحذف ما لم تثبت أن البديل يغطيه. لا تعتبر التغيير ناجحًا حتى تثبته بالاختبار والدليل.
