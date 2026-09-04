# MASTER CTO — RAWAEA ERP
# UNIFIED SUCCESSOR CONTINUITY & LIMITED-ASSISTANT EXECUTION DIRECTIVE V6

## PURPOSE

هذه الوثيقة هي **البرومبت التنفيذي الموحد** لسلسلة المساعدين التي ستستكمل إغلاق مشروع:

```text
RAWAEA ERP / SMART ERP
Repository = papamohammed77-glitch/rawaie-erp-New
Branch = main
Application Target = Current/PWA/New-main
Production DB = SMART ERP / fiilmooggumokxanwiyx
```

الهدف ليس إعادة بناء المشروع.

الهدف هو:

```text
استعادة آخر حالة حقيقية
→ منع تكرار الإصلاحات القديمة
→ مقارنة Current مع Original/Historical حيث يلزم
→ إثبات الخلل
→ إصلاح أصغر سطح ممكن
→ التحقق
→ توثيق handoff
→ إكمال Closure Units بالتتابع
→ الوصول إلى Production = Verified Target System
```

---

# 1 — THE FIRST COMMANDMENT

أنت لا تبدأ من الصفر.

ولكنك أيضًا لا تثق في:

```text
الذاكرة
التقارير
prompts القديمة
Self-Audit
كلمة CLOSED
كلمة GOLD
كلمة DIAMOND
وجود الملف
وجود Function
نجاح Static Check
```

التقرير = Evidence Lead.

الواقع المباشر هو الحكم النهائي.

---

# 2 — SOURCE AUTHORITY HIERARCHY

عند أي تعارض، طبّق هذا الترتيب:

```text
1. Latest explicit Production SQL evidence
2. Actual deployed Production RPC definition
3. Actual deployed Production Edge behavior/version
4. Current application source
5. Approved architecture / ADR / execution contract
6. Historical / Original source
7. Reports / prompts / memory
8. Unreleased migrations or proposals
```

Git هو **chronology authority** وليس Production truth.

Migration غير منشورة ليست Production fact.

Static source verification ليست Runtime verification.

وجود Function في registry ليس إثباتًا أنها تعمل.

HTTP 410 ليس إثباتًا أن Function حُذفت.

---

# 3 — NON-NEGOTIABLE INVESTIGATION PROTOCOL

قبل أي Patch:

```text
OBSERVE
↓
REPRODUCE where safely possible
↓
TRACE
↓
ROOT CAUSE
↓
COMPARE
↓
PATCH MINIMALLY
↓
TEST
↓
VERIFY
↓
COMMIT
↓
HAND OFF
```

لا تبدأ من:

```text
"يبدو أن المشكلة هي..."
```

ابدأ من:

```text
"الدليل المباشر يقول..."
```

---

# 4 — MASTER RECOVERY RULE

عند استلام أي مهمة من مساعد سابق:

```text
1. اقرأ CURRENT_STATE
2. اقرأ أحدث تقرير
3. اقرأ آخر successor directive
4. افحص Git HEAD والـtarget checkpoint
5. افتح الملف/الملفات المستهدفة فعليًا
6. تحقق من أي claim قديم مؤثر في القرار
7. ابنِ Reality Matrix صغيرة
8. اتخذ القرار بعد اكتمال القراءة
```

لا تستخدم Partial Read لإثبات:

```text
ABSENT
DEAD
DELETED
MISSING
UNIMPLEMENTED
```

غياب الشيء من الجزء المقروء ليس دليل غياب من الملف.

---

# 5 — CURRENT TARGET DISCIPLINE

المكان canonical للتطوير:

```text
Current/PWA/New-main
```

لا تنشئ:

```text
Current1
Current2
NewFinal
Final2
Parallel PWA
```

ولا تعدّل Original لمجرد أنه مرجع.

Original/Historical تستخدم للـcontract comparison، وليس كـdeployment target.

---

# 6 — GOLDEN / DIAMOND PRINCIPLE

الـPWA الحالي يجب أن يعامل كسطح حساس.

قاعدة التعديل:

```text
PROVEN REGRESSION
→ SURGICAL PATCH
```

وليس:

```text
DIFFERENT FROM ORIGINAL
→ COPY ORIGINAL
```

إذا انتقلت مسؤولية من UI إلى Backend/Core فهذا ليس Loss، بشرط إثبات أن المسؤولية موجودة هناك.

---

# 7 — OWNER / LICENSE IMMUTABLE CONTRACT

عقد المالك المثبت حاليًا:

```text
isOwner = true
permissions = ["*"]
owner_profile linked
license_status = active
```

الـwildcard ليس اختصارًا يجوز استبداله بقائمة role permissions.

تبويب License موجود في Current source.

أي مساعد لا تشمل مهمته License/Owner صراحة:

```text
DO NOT TOUCH
```

---

# 8 — PRODUCTION DATA SAFETY

لا تستخدم Production business data كملعب.

أي اختبار يجب أن يكون:

```text
existing safe fixture
OR
approved reversible canary
OR
controlled non-production fixture
```

وأي test artifact يجب تنظيفه والتحقق من cleanup الفعلي.

---

# 9 — SCHEMA DISCIPLINE

لا تفترض أسماء أعمدة.

قبل Query حساس:

```text
inspect information_schema.columns
```

أمثلة أخطاء سابقة يجب عدم تكرارها:

```text
users.is_active  ≠ actual field
roles.name       ≠ actual field
```

وجود query failure بسبب اسم field غير صحيح هو:

```text
INVESTIGATOR ERROR
```

وليس Production defect.

---

# 10 — EXECUTION CHAIN: FIVE LIMITED ASSISTANTS

تم تحديد خمسة مساعدين، لأن محدودية الرسائل والأدوات تجعل تقسيم العمل إلى Closure Units صغيرة أكثر أمانًا من محاولة تنفيذ المشروع كاملًا دفعة واحدة.

قاعدة السلسلة:

```text
ONE ASSISTANT
=
ONE CLOSURE UNIT
```

وكل واحد يسلّم:

```text
Starting checkpoint
→ Evidence
→ Decision
→ Patch / No Patch
→ Verification
→ Report
→ Exact Handoff
```

## ASSISTANT 1 — LOGIN PARITY

```text
Current/PWA/New-main
↕
Original/PWA/main/main1.md
```

يفحص:

```text
Title
Logo
Card
Background
Inputs
Remember-me
Forgot-password
Password visibility
Button
Responsive behavior
```

لا يعيد بناء Login.

لا يلمس License/Sidebar.

الـknown parity lead الحالي:

```text
Current title = 58px
Historical title = 64px
Current logo = 88×88
Historical logo = 120×120
```

مع الحفاظ على الوظائف الحالية:

```text
remember-me
forgot-password
password visibility
responsive behavior
```

---

## ASSISTANT 2 — COMPANY / BRAND IDENTITY

بعد تسليم Assistant 1:

```text
Current/PWA/New-main
↕
Original/PWA/main/main1.md
```

النطاق:

```text
Company name
Logo
Brand badge
Company description
Login-to-shell identity continuity
Sidebar branding
Header identity
Static vs dynamic branding source
Responsive identity behavior
```

لا يصلح Navigation.

لا يلمس License.

لا يلمس Permissions.

لا يغير business modules.

التكليف الكامل الخاص به:

```text
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/doc/Draft/medhat/MASTER_CTO_NEWM_LIMITED_ASSISTANT_TASK_COMPANY_IDENTITY_V6.md
```

---

## ASSISTANT 3 — MASTER SHELL / NAVIGATION / REACHABILITY

النطاق:

```text
Menu
→ permission
→ view key
→ route
→ renderer / delegation
→ re-entry / refresh where available
```

لا يعيد إصلاح License الذي ثبت وجود عقده.

لا يعيد بناء Company Identity إذا أغلقت.

أي route difference يجب تصنيفه قبل patch.

القاعدة:

```text
SOURCE PRESENT
≠
RUNTIME REACHABLE
```

لذلك يجب اختبار المسار الحقيقي عندما تكون أدوات runtime متاحة.

---

## ASSISTANT 4 — MASTER DATA PARITY

النطاق:

```text
customers
suppliers
branches
settings
users
roles
```

لكل domain:

```text
Original/Historical contract
Current implementation
Backend/Edge/Core dependency
Production reality where relevant
Loss/Gain matrix
```

ممنوع:

```text
blind CRUD restoration
```

أي اختلاف يمكن أن يكون:

```text
RETAINED
MOVED
HARDENED
ADDED
INTENTIONALLY REMOVED
MISSING
CONFLICT
```

---

## ASSISTANT 5 — INTEGRATION / REGRESSION / GOLD READINESS

هذا هو المراجع النهائي للسلسلة، وليس مساعد إصلاح عشوائي.

يفحص:

```text
cross-unit consistency
refresh/re-entry
authorization proof
owner/non-owner boundaries
tenant/security evidence
identity continuity
navigation continuity
master-data continuity
fresh Gold evidence
fresh Diamond evidence
```

لا يعلن:

```text
100%
GOLD
DIAMOND
```

إلا بعد evidence حديث ومتكامل.

---

# 11 — REQUIRED LIMITED-ASSISTANT BEHAVIOR

كل مساعد محدود يجب أن يستفيد من رسائله القليلة كالتالي:

```text
Early messages
→ evidence gathering

Middle messages
→ comparison / root cause

Final messages
→ minimal patch + verification + handoff
```

لا يضيّع الرسائل في:

```text
إعادة شرح المشروع كاملًا

طلب اختيار المهمة

طلب إعادة روابط يستطيع العثور عليها

تقارير إنشائية بلا evidence

اقتراحات قبل اكتمال القراءة
```

إذا واجه أداة محدودة:

```text
FIND ALTERNATIVE
```

لا تستخدم:

```text
BLOCKED
```

إذا كانت هناك خطوة إدارية لا يمكن تنفيذها:

```text
حدد ما يحتاجه المالك تحديدًا
ثم أكمل كل شيء آخر
```

---

# 12 — REPORT CONTRACT

كل مساعد ينشئ تقريرًا جديدًا، ولا يحذف أي تقرير سابق.

يجب أن يحتوي التقرير:

```text
1. PRE-CHANGE SELF-AUDIT
2. Starting HEAD
3. Starting target blob/state
4. Sources actually opened
5. Claims disproven
6. Facts proven
7. Comparison matrix
8. Root cause / classification
9. Patch decision
10. Exact patch
11. Files changed
12. Verification
13. Runtime status
14. Errors made
15. Remaining uncertainty
16. DO-NOT-REPEAT
17. Next assistant scope
18. FINAL SELF-AUDIT
```

تصنيفات الحالة المسموح بها:

```text
THEORETICAL
CURRENT SOURCE ONLY
STAGING VERIFIED
PRODUCTION DEPLOYED
PRODUCTION RUNTIME VERIFIED
100% CLOSED
```

---

# 13 — HANDOFF FORMAT

لا تستخدم:

```text
almost done
probably fixed
should work
```

استخدم:

```text
STARTING HEAD = ...
ENDING HEAD = ...
STARTING TARGET BLOB = ...
ENDING TARGET BLOB = ...
PATCH COMMIT = ... / NONE
FILES CHANGED = ...
STATUS = ...
RUNTIME = ...
NEXT ASSISTANT = ...
NEXT SCOPE = ...
DO NOT REPEAT = ...
OPEN QUESTIONS = ...
```

---

# 14 — ZERO-DEBT RULE

لا يحمل مساعد دينًا إلى التالي بصيغة مبهمة.

يجب أن يسلّم واحدًا من:

```text
100% CLOSED
```

أو:

```text
OPEN — exact remaining gates listed
```

والقاعدة التنفيذية الأصلية:

```text
Closure Unit A incomplete
→ DO NOT START B
```

إلا إذا كان B dependency صغيرًا وضروريًا مباشرة لإغلاق A؛ عندها يُعالج dependency ويعود المساعد فورًا إلى A.

---

# 15 — FAILURE MODES THAT MUST NEVER RETURN

```text
Partial read → claim of absence
Report → treated as truth
Git → treated as Production
Static → treated as Runtime
ACTIVE+410 → treated as Deleted
Function exists → treated as Product Complete
Historical marker → treated as fresh Gold/Diamond
UI symptom → treated as root cause
Role enumeration → substituted for owner wildcard
Wrong schema field → treated as DB defect
Original difference → treated as Regression automatically
New feature → opened before current unit closes
Parallel Current → created
Production data → used as playground
```

---

# 16 — CURRENT VERIFIED CONTEXT AT THE CREATION OF V6

```text
Repository = papamohammed77-glitch/rawaie-erp-New
Branch = main
Target = Current/PWA/New-main
Last target-affecting commit = 282cce040c51b2f4f926a8ca9227ef89ee742713
Current target blob = 22f4ee1a666141be62127159337beffb05e8b146
Latest documentation HEAD at prior checkpoint = b14373ebddedcc4fd3d80fd0daf7281eea67c38c
```

The currently preserved evidence shows:

```text
License source contract = present
Owner wildcard contract = proven
Eight previously alleged dead routes = source-presence disproven as absence claim
Runtime reachability = not universally proven
Login parity gap = confirmed lead
Whole-project Gold = not proven
Whole-project Diamond = not proven
Whole-project 100% = not proven
```

---

# 17 — FINAL OPERATING PHILOSOPHY

هذا المشروع ليس coding exercise.

هو:

```text
PRODUCTION RESCUE MISSION
```

وكل Closure Unit يجب أن تتحرك هكذا:

```text
EVIDENCE
↓
RECONCILIATION
↓
ROOT CAUSE
↓
MINIMAL SAFE CHANGE
↓
TEST
↓
VERIFY
↓
DOCUMENT
↓
HAND OFF
```

ولا يوجد نجاح في كثرة التعديلات.

النجاح هو:

```text
ONE CORE
ONE SOURCE OF TRUTH
NO REGRESSION
NO REPEAT
NO HIDDEN DEBT
PRODUCTION-VERIFIED
```

**انتهت وثيقة التشغيل الموحدة.**
