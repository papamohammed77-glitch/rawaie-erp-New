# CTO EXECUTION COMMAND
# NEW-MAIN — MAIN1 FORENSIC COMPLETION & VERIFIED PARITY
## SINGLE-FILE / SINGLE-MODULE / NO-LOOP / NO-RESET

---

# 0. MISSION — هذه هي المهمة الوحيدة المسموح بتنفيذها

أنت تعمل الآن كـ:

**CTO + Principal Software Architect + Forensic Reconstruction Engineer + Production Verification Engineer**

ومهمتك الحالية الوحيدة هي:

> **التحقق الجنائي الكامل من أن `Current/PWA/New-main` يحتوي كل ما هو مطلوب فعليًا من `Current/PWA/main/main1.md` و`Original/PWA/main/main1.md`، ثم إكمال أي نقص أو إصلاح أي خطأ يخص نطاق MAIN1 فقط، مع الحفاظ على كل ما هو صحيح وموجود بالفعل في New-main، ثم التحقق من النتيجة وتسجيل كل الأحداث الفعلية في `CURRENT_STATE.md`.**

هذه ليست مهمة إعادة بناء المشروع.

هذه ليست مهمة إعادة إنشاء `main.html` من الصفر.

هذه ليست مهمة إعادة تنفيذ `main1 → main11`.

هذه ليست مهمة مراجعة عامة لـ`New-main`.

هذه ليست مهمة إصلاح كل ما في النظام.

هذه ليست مهمة إنتاج نسخة بديلة من الملف.

هذه هي:

> **MAIN1 COMPLETION UNIT**

وتنتهي فقط عندما يصبح Contract الخاص بـMAIN1 مثبتًا ومتكاملًا داخل `Current/PWA/New-main` وفق الأدلة الفعلية.

---

# 1. HARD STOP — أوقف كل المسارات التاريخية السابقة

لا تبدأ من الصفر.

لا تعيد فتح السلسلة القديمة.

لا تعيد تنفيذ:

`main1 → main2 → ... → main11`

ولا تعيد:

- إعادة تقسيم `main.html`.
- إعادة بناء Current/Main.
- إعادة بناء New-main بالكامل.
- إعادة تشغيل reconstruction التاريخي لمجرد أنه ذُكر في Prompt قديم.
- إعادة تطبيق إصلاحات سابقة دون إثبات أنها ناقصة حاليًا.
- إعادة إنشاء ملفات Candidate أو backups أو builders أو workflows أو evidence artifacts.
- إنشاء مجلدات جديدة بغرض التنظيم.
- إنشاء نسخة ثانية من `New-main`.
- إنشاء `New-main-v2`.
- إنشاء `main1-final`.
- إنشاء `main1-fixed`.
- إنشاء `candidate.html`.
- إنشاء أي ملف وسيط دائم داخل المستودع.

**المسموح بالتعديل الدائم في هذه المهمة:**

1. `Current/PWA/New-main`
2. `CURRENT_STATE.md`

ولا تنشئ أي ملف ثالث إلا إذا أثبتت ضرورة تقنية قاطعة، وفي هذه الحالة يجب التوقف قبل الإنشاء وتوثيق سبب الضرورة في `CURRENT_STATE.md`.

الأفضل والأصل:

> **لا تنشئ أي ملف جديد إطلاقًا.**

استخدم Git SHA / diff / runtime verification بدلًا من ملفات backup.

---

# 2. CRITICAL TARGET DEFINITION

النطاق المستهدف الآن هو:

```text
Current/PWA/New-main
```

لكن وحدة التحقق المطلوبة هي فقط:

```text
Current/PWA/main/main1.md
Original/PWA/main/main1.md
```

### مهم جدًا

`main1.md`:

- Logical Module
- Historical/Current Contract Source
- ليس بالضرورة byte range من `New-main`
- ليس مسموحًا إعادة تقطيعه من `New-main`
- ليس مسموحًا نسخ الملفين فوق New-main
- ليس مسموحًا افتراض أن ترتيب الأسطر أو الحجم أو byte offsets يمثل حدود الوحدة الحالية.

أنت تحقق **السلوك والعقود والوظائف**، وليس تطابقًا سطريًا أو byte-for-byte.

---

# 3. SOURCE OF TRUTH — لا تثق في التقارير

رتب سلطة الأدلة هكذا:

## Current Truth

1. Production runtime الفعلي
2. Production Supabase
3. PostgreSQL schema / functions / triggers / RLS / grants / constraints
4. Active Edge Functions
5. Current Git `main`
6. Current PWA/Core/SW files
7. Git history

## Historical Context

8. `Current/PWA/main/main1.md`
9. `Original/PWA/main/main1.md`
10. Historical prompts
11. Historical reports
12. Assistant memory

القاعدة المطلقة:

```text
Historical Source = proves historical intent/behavior
Current Source + Production = proves current reality
```

لا تسمح لأي تقرير تاريخي أن يثبت:

`CURRENT`

ولا:

`PASS`

ولا:

`FIXED`

ولا:

`CLOSED`

ولا:

`PRODUCTION`

بمجرد أنه قال ذلك.

---

# 4. BEFORE TOUCHING ANYTHING — BOOT & RECONCILIATION

ابدأ بالترتيب التالي ولا تتجاوزه:

### Step 1

اقرأ:

```text
CURRENT_STATE.md
```

حتى النهاية.

### Step 2

استخرج:

```text
LAST VERIFIED EVENT
```

ولا تستخدم:

```text
LAST REPORT
```

### Step 3

تحقق مباشرة من:

```text
Current Git HEAD
Current branch
Working tree status
Current/PWA/New-main existence
Current/PWA/main/main1.md existence
Original/PWA/main/main1.md existence
```

### Step 4

تحقق من Current Production state ذات الصلة.

### Step 5

تحقق أن `CURRENT_STATE.md` ما زال متزامنًا.

إذا كان:

```text
STATE != REALITY
```

فالحالة:

```text
STATE = STALE
```

قم بتسجيل ذلك أولًا، ثم حدّث `CURRENT_STATE.md` بالحقيقة.

**لا تبدأ تعديل New-main قبل مزامنة الحالة.**

---

# 5. HISTORICAL CONTEXT — اقرأه لفهم الهدف لا لاعتماد الواقع

قبل التنفيذ، قم بقراءة المواد التاريخية المرتبطة بالسلسلة السابقة بالقدر الذي يسمح لك باستخراج:

- الهدف الأصلي
- سبب إنشاء MAIN1
- ما كان يفترض أن تحتويه
- العقود التي كان من المفترض المحافظة عليها
- الأخطاء التي تم اكتشافها سابقًا
- الحلول التي ثبت نجاحها
- الحلول التي ثبت فشلها
- المحاولات التي يجب عدم تكرارها

ويجب إعطاء أولوية خاصة لـ:

```text
Current/CTO/RAWAEA_PROJECT_MEMORY_117-02.md
CURRENT_STATE.md
FINAL_MAIN_HTML_RECONSTRUCTION_COMMAND.md
doc/Draft/medhat/تقرير 116-03
```

ثم بقية المواد التاريخية عند الحاجة لحسم نية أو Contract.

لكن:

> **لا تستخدم أي ملف تاريخي لإثبات Current Truth دون إعادة التحقق.**

ولا تعيد تنفيذ مهمة تاريخية لمجرد أنها موجودة في الذاكرة.

---

# 6. DEFINE THE MAIN1 CONTRACT BEFORE EDITING

أنشئ ذهنيًا/داخليًا جدول تحقيق واحد:

# `MAIN1_FORENSIC_CONTRACT_MATRIX`

ولا تحفظه في ملف جديد.

لكل وظيفة/ميزة/سلوك مثبت في MAIN1 سجل:

| العنصر | Original Evidence | Current Evidence | New-main Status | Required Action | Verification |
|---|---|---|---|---|---|
| Function | ... | ... | ... | Preserve/Fix/Add/Retire | ... |
| UI | ... | ... | ... | ... | ... |
| State | ... | ... | ... | ... | ... |
| Auth | ... | ... | ... | ... | ... |
| Identity | ... | ... | ... | ... | ... |
| Tenant | ... | ... | ... | ... | ... |
| Permissions | ... | ... | ... | ... | ... |
| Owner | ... | ... | ... | ... | ... |
| License | ... | ... | ... | ... | ... |
| Navigation | ... | ... | ... | ... | ... |
| Data loading | ... | ... | ... | ... | ... |
| CRUD | ... | ... | ... | ... | ... |
| Events | ... | ... | ... | ... | ... |
| Error paths | ... | ... | ... | ... | ... |
| External contracts | ... | ... | ... | ... | ... |

لا تنتقل إلى التنفيذ قبل أن يصبح هذا النموذج واضحًا بالنسبة لك.

---

# 7. CLASSIFICATION RULE

كل عنصر من MAIN1 يجب تصنيفه واحدًا من:

```text
PRESERVE
RECONSTRUCT
FIX
REPLACE
RETIRE
UNKNOWN
```

### PRESERVE

موجود وصحيح.

لا تلمسه.

### RECONSTRUCT

مفقود، لكن Contract وجوده مثبت، ويمكن إعادة بنائه من الأدلة المباشرة.

### FIX

موجود لكنه خاطئ.

### REPLACE

نسخة New-main الحالية تخالف Contract مثبتًا وتحتاج إلى استبدال محدد.

### RETIRE

موجود تاريخيًا لكن ثبت أنه لم يعد Current أو أن Contract الحالي استبدله.

### UNKNOWN

لا توجد أدلة كافية.

والقاعدة:

```text
UNKNOWN != REMOVE
UNKNOWN != REBUILD
UNKNOWN != INVENT
```

---

# 8. THREE-WAY INVESTIGATION

لا تعتمد على مقارنة واحدة.

حقق في:

```text
ORIGINAL MAIN1
        ↓
CURRENT MAIN1
        ↓
NEW-MAIN
        ↓
CURRENT PRODUCTION / ACTIVE CONTRACTS
```

### السؤال الأول

ماذا كان MAIN1 يفعل تاريخيًا؟

### السؤال الثاني

ما الذي تم تعديله عبر النسخ الحالية؟

### السؤال الثالث

ما الذي يحتاجه New-main الآن؟

### السؤال الرابع

هل وظيفة MAIN1 ما زالت Current؟

### السؤال الخامس

إذا كانت Current:

هل هي:

```text
Present
Correct
Connected
Consumed
Runtime-compatible
Tenant-safe
Contract-compatible
```

---

# 9. DO NOT USE SURFACE-LEVEL PARITY

لا تقل:

```text
same HTML section
same function name
same button
same label
same variable
```

إذن parity achieved.

الـParity المطلوب:

```text
Behavioral Parity
Contract Parity
Integration Parity
Security Parity
Tenant Parity
Runtime Parity
```

مثال:

إذا كان Original يحتوي:

```text
function X()
```

وNew-main يحتوي شيئًا آخر يؤدي نفس الـContract:

فلا تقم بنسخ X لمجرد اختلاف الاسم.

العبرة:

```text
CONTRACT
```

لا:

```text
SOURCE SHAPE
```

---

# 10. MAIN1 MUST NOT BECOME A SECOND CORE

إذا وجدت أن MAIN1 تاريخيًا يحتوي منطقًا أصبحت ملكيته الآن لـ:

- Core
- Edge Function
- RPC
- Service Worker
- shared infrastructure
- authorization engine
- stock engine
- accounting engine
- synchronization engine

فلا تنسخ المنطق القديم إلى New-main.

يجب أن يكون:

```text
UI
 ↓
Current Owner
```

وليس:

```text
UI
 ↓
Duplicate Business Engine
```

---

# 11. INVENTORY / FINANCIAL HARD LOCK

إذا ظهر ضمن MAIN1 أي كود متعلق بالمخزون أو الحسابات:

لا تسمح بكتابة مباشرة من New-main إلى:

```text
stock_branches.qty
inventory_log
journal_entries
journal_lines
customer_ledger
supplier_ledger
driver_ledger
treasury
```

إلا إذا أثبتت مباشرة من Current Production Contract أن ذلك هو المسار الحالي والمالك الرسمي.

وبشكل خاص:

```text
Physical Stock Movement
        ↓
post_stock_movement
```

لا تنشئ writer بديلًا.

و:

```text
Reservation
        ↓
reserve_stock / release_stock_reservation
```

لا تخلط reservation مع movement.

---

# 12. TENANT / IDENTITY HARD LOCK

أي وظيفة ضمن MAIN1 تتعامل مع بيانات الشركة يجب أن تحافظ على:

```text
Authenticated user
        ↓
users.auth_id
        ↓
users.company_id
        ↓
company-scoped data
```

تحقق من:

- company_id
- auth_id
- user identity
- tenant filters
- RLS compatibility
- context propagation

ممنوع:

```text
global operational lookup
LIMIT 1 identity lookup
unscoped company data
cross-company fallback
```

إلا إذا أثبتت الأدلة المباشرة أن العنصر Global بطبيعته.

---

# 13. OWNER / PERMISSION CONTRACT

إذا كان MAIN1 يتعامل مع Owner أو permissions أو license:

لا تفترض أن role وحده يكفي.

تحقق من Current contract الفعلي.

إذا كان العقد:

```text
isOwner = true
permissions = ["*"]
owner_profile
active license
```

فاحفظ الـsemantics نفسها.

لا تحول:

```text
["*"]
```

إلى قائمة Permission صريحة لمجرد أنها تبدو مساوية.

ولا تجعل:

```text
role = مدير النظام
```

مرادفًا تلقائيًا لـ:

```text
isOwner = true
```

إلا إذا أثبت الكود الحالي ذلك.

---

# 14. ANALYZE NEW-MAIN WITHOUT DESTROYING VALID WORK

هذه قاعدة مركزية:

> **لا تتعامل مع New-main كملف فاسد لمجرد أنه Candidate.**

هو يحتوي عملًا حديثًا قد يكون صحيحًا.

قبل كل تعديل اسأل:

```text
What is here?
Why is it here?
What contract does it satisfy?
Is it already correct?
Will changing it regress another verified capability?
```

أي عنصر مثبت صحته:

```text
PRESERVE
```

ولا تعيد كتابته دون سبب.

---

# 15. MAIN1 SCOPE FENCE

أنت الآن تصلح فقط:

```text
MAIN1 CONTRACT
```

لذلك:

### مسموح

تعديل ما يلزم لكي:

- تكمل وظيفة MAIN1
- تصلح Bug في MAIN1
- تربط MAIN1 بعقد Current صحيح
- تمنع regression متعلقًا مباشرة بـMAIN1
- إصلاح dependency ضرورية مباشرة لـMAIN1

### غير مسموح

إطلاق إصلاحات مستقلة تخص:

```text
MAIN2
MAIN3
MAIN4
...
MAIN11
```

حتى لو لاحظتها.

سجلها فقط في:

```text
CURRENT_STATE.md
```

كـ:

```text
OBSERVED / OUT OF SCOPE
```

ولا تفتح جولة جديدة.

---

# 16. DO NOT FIX UNRELATED DEFECTS

إذا وجدت:

- Security issue
- RLS issue
- another PWA bug
- unrelated API bug
- unrelated workflow defect
- accounting anomaly
- legacy CI failure

لا تصلحه الآن إلا إذا كان:

```text
DIRECTLY BLOCKING MAIN1 VERIFICATION
```

وفي هذه الحالة:

```text
ROOT CAUSE
→ MINIMUM SAFE FIX
→ REVERIFY
```

ولا تحول المهمة إلى مشروع جديد.

---

# 17. SAFE EDITING RULE

قبل أول تعديل في:

```text
Current/PWA/New-main
```

سجّل:

```text
Git HEAD
File SHA
File size
Timestamp
```

ثم نفذ تعديلات صغيرة ومحددة.

بعد كل تعديل:

```text
diff
syntax
contract
dependency
runtime impact
```

لا تجمع عشرات الإصلاحات قبل الاختبار.

---

# 18. NO BLIND REWRITE

ممنوع:

```text
delete all
rewrite everything
```

وممنوع:

```text
copy Original
→ overwrite New-main
```

وممنوع:

```text
copy Current main1
→ paste into New-main
```

وممنوع:

```text
merge both blindly
```

أي إعادة كتابة كبيرة يجب أن تكون مبررة بوجود:

```text
PROVEN DEFECT
```

وليس:

```text
FILE LOOKS DIFFERENT
```

---

# 19. STATIC VALIDATION GATE

بعد كل إصلاح جوهري تحقق على الأقل من:

```text
HTML validity
JS syntax
No broken script blocks
No accidental premature </script>
No duplicate critical IDs
No duplicate global definitions causing shadowing
No undefined critical references
No malformed template/string boundaries
No broken event handlers
No missing required dependencies
```

وتذكر درس 116-03:

> لا تفترض أن وجود النص البرمجي في الملف يعني أن Browser سيقرأه بالطريقة التي تتوقعها.

يجب اختبار parsing الفعلي.

---

# 20. MAIN1 FUNCTIONAL GATE

لكل Function/Capability ضمن MAIN1:

تحقق من:

```text
UI entry
↓
event/call
↓
state
↓
API/Edge/RPC
↓
database/read model
↓
response
↓
UI rendering
↓
error handling
```

لا تعتبر:

```text
function exists
```

دليلًا على:

```text
function works
```

---

# 21. CURRENT PRODUCTION VERIFICATION

لا تحتاج إلى تنفيذ عمليات مالية أو مخزنية دائمة فقط لإثبات MAIN1.

استخدم:

```text
read-only verification
```

متى أمكن.

أو:

```text
transactional test + rollback
```

عند الضرورة.

الاختبار يجب أن يثبت فقط العقود التي يعتمد عليها MAIN1.

---

# 22. BROWSER / RUNTIME VERIFICATION

إذا كان MAIN1 يتطلب browser runtime:

يجب اختبار:

```text
Load
Parse
Initialize
Auth
Session
Context
Navigation
MAIN1 entry points
Representative actions
Error path
Logout
Reload
```

لا تساوِ:

```text
CI PASS
```

مع:

```text
Browser PASS
```

ولا:

```text
static PASS
```

مع:

```text
Production PASS
```

---

# 23. EXTERNAL RESEARCH RULE

يمكنك البحث على الإنترنت في:

- SAP
- Oracle
- Odoo
- Microsoft Dynamics
- Salesforce
- NetSuite
- أنظمة ERP/WMS/POS الحديثة
- ممارسات architecture المعروفة

لكن فقط لأغراض:

```text
Pattern discovery
Architecture validation
UX comparison
Industry best practice
```

ولا تستخدم المنافسين كـSource of Truth للمشروع.

لا تضف وظيفة جديدة إلى MAIN1 لأن:

```text
competitor has it
```

إلا إذا أثبتت أن المشروع نفسه يحتاجها ضمن Contract.

---

# 24. CREATIVE ENGINEERING RULE

استخدم خبرتك الإبداعية فقط بعد معرفة:

```text
Current Contract
Historical Intent
Current Architecture
Dependency Ownership
Production Reality
```

الإبداع هنا يعني:

```text
أفضل تنفيذ لنفس العقد
```

وليس:

```text
إضافة أفكار جديدة بلا طلب
```

---

# 25. FAILURE CONTROL — ممنوع الدوران

عند أي فشل:

لا تبدأ تجربة عشوائية جديدة.

سجل داخليًا:

```text
FAILURE
ROOT CAUSE
EVIDENCE
HYPOTHESIS
ACTION
RESULT
```

ثم:

```text
FAILURE
→ ROOT CAUSE
→ SURGICAL FIX
→ REVERIFY
```

إذا فشل الحل:

لا تعيده بصيغة مختلفة عشر مرات.

اسأل:

```text
Why did it fail?
Was the assumption wrong?
Was the dependency wrong?
Was the target wrong?
Was the test wrong?
Was the environment wrong?
```

---

# 26. FAILURE MEMORY — لا تكرر ما ثبت فشله

اعتبر الدروس التالية محظورة التكرار:

### ممنوع 1

اعتبار التقارير التاريخية Current Truth.

### ممنوع 2

اعتبار Git commit دليلًا على Production runtime.

### ممنوع 3

اعتبار CI PASS دليلًا على Browser/Production PASS.

### ممنوع 4

إعادة تقطيع `main.html` إلى `main1..main11`.

### ممنوع 5

الكتابة فوق logical modules من workflow forensic.

### ممنوع 6

اعتبار اختلاف timestamp فرقًا وظيفيًا.

### ممنوع 7

فحص logical modules كأنها HTML monolith واحد.

### ممنوع 8

نسخ Original إلى Current دون Contract analysis.

### ممنوع 9

إصلاح Production لمجرد إسكات CI.

### ممنوع 10

إعادة فتح إصلاح تم إثباته دون evidence على regression.

### ممنوع 11

حذف عنصر غير مفهوم لأنه:

```text
UNKNOWN
```

### ممنوع 12

اختراع Builders / Candidates / workflows / evidence files.

---

# 27. CHANGE DECISION MATRIX

قبل أي تعديل يجب أن تكون النتيجة:

```text
KEEP
```

أو:

```text
MODIFY
```

أو:

```text
ADD
```

أو:

```text
RETIRE
```

ومع كل قرار يجب أن تعرف:

```text
Evidence
Reason
Affected Contract
Risk
Verification
```

إذا لم تعرف ذلك:

```text
DO NOT MODIFY
```

---

# 28. FINAL MAIN1 PARITY GATE

لا تعتبر MAIN1 مكتملًا إلا إذا نجحت كل هذه البوابات:

## Gate A — Source Understanding

```text
Original MAIN1 understood
Current MAIN1 understood
Historical intent understood
```

## Gate B — New-main Mapping

لكل MAIN1 contract:

```text
Mapped
Implemented
Or proven Retired
```

ولا يوجد:

```text
silent omission
```

## Gate C — Functional

```text
entry works
logic works
dependency works
response works
error path works
```

## Gate D — Security

```text
auth correct
identity correct
tenant correct
permission semantics correct
owner semantics correct
```

## Gate E — Architecture

```text
No duplicate core
No duplicate writer
No direct forbidden mutation
Correct owner delegation
```

## Gate F — Runtime

```text
Browser parse
Initialization
Representative runtime behavior
```

## Gate G — Production Compatibility

```text
Current Production contracts compatible
```

---

# 29. NO FALSE CLOSURE

ممنوع كتابة:

```text
DONE
FINAL
COMPLETE
CLOSED
100%
GOLD
DIAMOND
PRODUCTION READY
```

إلا إذا كان الدليل يطابق العبارة.

إذا بقي عنصر:

```text
UNKNOWN
UNVERIFIED
BLOCKED
```

في نطاق MAIN1 نفسه:

فلا تغلق المهمة.

---

# 30. CURRENT_STATE UPDATE — AFTER EVERY REAL EVENT

بعد كل تغيير حقيقي:

```text
VERIFY
↓
UPDATE CURRENT_STATE.md
↓
NEXT AUTHORIZED ACTION
```

ويجب تسجيل:

```text
EVENT ID
EVENT TYPE
UTC TIMESTAMP
SOURCE
GIT SHA
TARGET
ACTION
RESULT
EVIDENCE
IMPACT
NEXT AUTHORIZED ACTION
```

---

# 31. EVENT MEMORY — أهم مخرج بعد الكود

في نهاية المهمة، يجب أن يسجل `CURRENT_STATE.md` تسلسل الأحداث الحقيقي:

```text
START
→ RECONCILIATION
→ MAIN1 CONTRACT DISCOVERY
→ GAP DISCOVERY
→ FIX 1
→ VERIFICATION 1
→ FIX 2
→ VERIFICATION 2
→ BLOCKER
→ ROOT CAUSE
→ FAILED ATTEMPT
→ WHY FAILED
→ SUCCESSFUL FIX
→ FINAL VERIFICATION
```

لا تكتب ملخصًا إنشائيًا.

سجل الأحداث القابلة لإعادة البناء.

---

# 32. FAILURE MEMORY — REQUIRED

إذا فشلت محاولة، يجب أن تسجل:

```text
What was attempted?
Why was it attempted?
What exact evidence supported it?
What failed?
Exact failure symptom?
Root cause?
What was learned?
What must not be repeated?
What finally worked?
```

الهدف:

> المساعد التالي يجب أن يستطيع قراءة `CURRENT_STATE.md` ومعرفة أين وصلنا ولماذا، دون إعادة التجارب الفاشلة.

---

# 33. SUCCESS MEMORY — REQUIRED

في حالة نجاح أي إصلاح، لا تكتب فقط:

```text
fixed
```

بل سجل:

```text
Problem
Root Cause
Fix
Affected Contract
Verification
Production Impact
Regression Status
```

---

# 34. OUT-OF-SCOPE FINDINGS

إذا وجدت مشاكل خارج MAIN1:

لا تصلحها الآن.

ضعها في `CURRENT_STATE.md` تحت:

```text
OBSERVED OUT OF SCOPE
```

مع:

```text
Finding
Evidence
Risk
Recommended Future Scope
```

ولا تعطيها أولوية جديدة إلا إذا أصبحت blocker مباشرًا لـMAIN1.

---

# 35. STOP CONDITIONS

توقف عن التعديل فورًا إذا:

### Condition A

تحتاج إلى إنشاء ملف جديد فقط لإكمال المهمة.

### Condition B

تحتاج إلى تعديل `Current/PWA/main.html`.

### Condition C

تحتاج إلى تعديل `main2..main11` لإكمال MAIN1 دون إثبات dependency مباشرة.

### Condition D

لا يوجد Evidence كافٍ.

### Condition E

التغيير قد يؤثر على Production Contract غير مفهوم.

في هذه الحالات لا تخمن.

حقق أولًا.

---

# 36. FINAL REPORT FORMAT

في النهاية لا تقدم تقريرًا إنشائيًا طويلًا.

يجب أن يتضمن:

## 1. Mission

```text
MAIN1 COMPLETION
```

## 2. Starting State

Git SHA + New-main state.

## 3. Verified Contracts

ما ثبت أنه موجود.

## 4. Missing / Defective Contracts

ما تم اكتشافه.

## 5. Changes Actually Applied

فقط التغييرات الحقيقية.

## 6. Failed Attempts

كل محاولة فشلت ولماذا.

## 7. Successful Resolution

الحل الذي نجح والدليل.

## 8. Verification

```text
Static
Functional
Browser
Production
```

بحسب ما تم اختباره فعليًا.

## 9. Remaining MAIN1 Blockers

إن وجدت.

## 10. Out-of-Scope Findings

إن وجدت.

## 11. Last Verified Event

مع Event ID الجديد.

## 12. Final State

واحدة فقط:

```text
MAIN1 = VERIFIED COMPLETE
```

أو:

```text
MAIN1 = PARTIALLY COMPLETE / BLOCKED
```

ولا تستخدم صيغة أقوى من الأدلة.

---

# 37. ABSOLUTE CLOSURE CONDITION

لن تعتبر المهمة مكتملة حتى تستطيع الإجابة بالأدلة المباشرة عن الأسئلة التالية:

### A

هل تمت مراجعة:

```text
Original/PWA/main/main1.md
Current/PWA/main/main1.md
Current/PWA/New-main
```

بهدف MAIN1 فقط؟

### B

هل كل وظيفة Current من MAIN1 موجودة في New-main أو ثبت أنها retired؟

### C

هل كل اختلاف معروف مبرر؟

### D

هل لا يوجد Contract تم إسقاطه بصمت؟

### E

هل أي business logic تم نقله إلى المالك الصحيح بدل نسخه؟

### F

هل Auth / Tenant / Owner / Permissions / License semantics محفوظة؟

### G

هل تم اختبار المسارات الفعلية؟

### H

هل كل الادعاءات المهمة لها Evidence؟

### I

هل تم تسجيل كل الأحداث والفشل والنجاح؟

### J

هل يستطيع CTO آخر متابعة المهمة دون إعادة ما تم؟

إذا كانت الإجابة عن أي سؤال:

```text
NO
```

فلا تعلن الإغلاق.

---

# 38. FINAL COMMAND

ابدأ الآن من:

```text
CURRENT_STATE.md
```

ثم:

```text
LAST VERIFIED EVENT
→ Git HEAD
→ Production Truth
→ Historical Context
→ Original MAIN1
→ Current MAIN1
→ New-main
→ MAIN1 Contract Matrix
→ Gap Analysis
→ Surgical Completion
→ Static Verification
→ Runtime Verification
→ Production Compatibility Verification
→ CURRENT_STATE update
→ Final MAIN1 closure decision
```

### وتذكر:

```text
DO NOT START OVER.
DO NOT REBUILD THE PROJECT.
DO NOT REOPEN MAIN1:MAIN11 HISTORY.
DO NOT TOUCH CURRENT/PWA/main.html.
DO NOT RE-SLICE MAIN.HTML.
DO NOT TRUST REPORTS.
DO NOT TRUST MEMORY.
DO NOT INVENT FILES.
DO NOT INVENT CONTRACTS.
DO NOT REPEAT FAILED ATTEMPTS.
DO NOT FIX OUT-OF-SCOPE PROBLEMS.
DO NOT DECLARE PASS WITHOUT EVIDENCE.
```

والهدف النهائي:

> **اجعل `Current/PWA/New-main` مكتملًا ومتوافقًا مع Contract الخاص بـMAIN1، وليس نسخة من MAIN1 التاريخي، ثم أثبت ذلك من الأدلة الحالية وسجّل الحقيقة الجديدة في `CURRENT_STATE.md`.**
