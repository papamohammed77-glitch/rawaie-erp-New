# RAWAEA ERP — MASTER FORENSIC CONTINUITY GOVERNANCE v2
## Successor CTO / Production Truth / Main1→Main11 / No-Assumption Execution

## 0. PURPOSE
هذا الأمر التنفيذي يجمع القواعد الحاكمة السابقة الخاصة بالاستمرارية، التحقيق الجنائي، مراجعة Main1، النظام الأم، Production، Git، التقارير، والبيانات في بروتوكول واحد.

المهمة ليست البدء من الصفر.
المهمة هي استعادة آخر **LAST VERIFIED EVENT** ثم متابعة التنفيذ من النقطة المثبتة فقط.

---

## 1. SOURCE OF TRUTH

لا توجد ذاكرة أو نسبة إنجاز أو تقرير تاريخي أعلى من الواقع الحالي.

ترتيب الإثبات:

1. Production Runtime / Browser evidence
2. Production Database
3. PostgreSQL functions / triggers / RLS / grants / constraints
4. Active Edge Functions / deployments
5. Current Git HEAD and current source files
6. Verified artifacts
7. Historical contracts / original source
8. Historical reports
9. Historical prompts
10. Memory
11. Assumptions

`CURRENT_STATE.md` هو **continuity checkpoint** وليس حقيقة مطلقة. إذا تعارض مع Git أو Production أو deployment أو runtime، يجب عمل reconciliation.

---

## 2. HARD STOP — BEFORE ANY CHANGE

قبل أي تعديل:

```text
READ
→ VERIFY
→ RECONCILE
→ UNDERSTAND
→ PATCH
→ TEST
→ DEPLOY
→ VERIFY PRODUCTION
→ DOCUMENT
→ UPDATE CURRENT_STATE
```

ممنوع قبل اكتمال هذا التسلسل:

- إعادة تطبيق Patch تاريخي.
- حذف Legacy.
- إعادة بناء ملف كامل.
- تحويل Unknown إلى Bug.
- تحويل Report إلى Production truth.
- استخدام نسبة مئوية بدلاً من Closure evidence.

---

## 3. CONTINUITY RECOVERY PROTOCOL

ابدأ دائمًا بهذا الترتيب:

```text
CURRENT_STATE.md
↓
LAST VERIFIED EVENT
↓
LATEST COMMITS
↓
LATEST REPORTS
↓
CURRENT SOURCE
↓
ACTIVE DEPLOYMENTS
↓
PRODUCTION DATABASE
↓
RUNTIME EVIDENCE
↓
RECONCILIATION
```

اقرأ الملفات من البداية للنهاية عند اتخاذ قرار متعلق بها. لا تعتمد على أول أو آخر أسطر فقط.

يجب تسجيل:

```text
EVENT ID
UTC TIMESTAMP
GIT SHA
PRODUCTION SNAPSHOT
SOURCE PATH
DEPLOYMENT VERSION
RUNTIME RESULT
ACTION
RESULT
OPEN BLOCKERS
NEXT AUTHORIZED ACTION
```

---

## 4. HISTORICAL CONTRACT RULE

التاريخ لا يستخدم لإثبات Current Truth، لكنه إلزامي لفهم:

- لماذا يوجد السلوك.
- ما العقد التاريخي.
- ما الذي كان مقصودًا.
- ما الذي كان compatibility layer.
- ما الذي استُبدل عمدًا.
- ما الذي فشل في محاولات سابقة.

قاعدة حاكمة:

```text
OLD != WRONG
OLD != CURRENT
CURRENT != TARGET
UNKNOWN != BUG
UNKNOWN != REMOVE
```

---

## 5. ONE CLOSURE UNIT AT A TIME

كل Closure Unit يجب أن تمر بهذا التسلسل:

```text
RESPONSIBILITY
→ CONSUMER
→ HISTORICAL CONTRACT
→ CURRENT SOURCE
→ PRODUCTION
→ DEPLOYMENT
→ RUNTIME
→ GAP
→ ROOT CAUSE
→ SURGICAL CHANGE
→ TEST
→ DEPLOY
→ PRODUCTION VERIFY
→ DOCUMENT
→ CLOSE
```

لا تجمع Defects غير مرتبطة في Patch واحد لمجرد السرعة.

---

## 6. NO FALSE CLOSURE

لا تعتبر أي بند Closed 100% بسبب:

- وجود commit.
- نجاح migration.
- نجاح unit test فقط.
- نجاح staging فقط.
- نجاح static inspection فقط.
- نجاح endpoint response واحد لا يثبت runtime integration.

الحالات المسموح بها:

```text
SOURCE CLOSED
DEPLOYMENT CLOSED
DATABASE CLOSED
RUNTIME CLOSED
PRODUCTION VERIFIED
FULLY CLOSED
```

وإذا لم تتوافر كل الأدلة المطلوبة، يبقى البند مفتوحًا.

---

## 7. MAIN1 CONTRACT

`Current/PWA/main2/main1.md` ليس تلقائيًا Login-only.
يجب تحديده كجزء من parent application وفق المصدر الحالي.

المراجعة الإلزامية:

```text
UI
AUTH
SESSION RESTORE
STATE
COMPANY IDENTITY
TENANT CONTEXT
OWNER SEMANTICS
PERMISSIONS
LICENSE ASSUMPTIONS
NAVIGATION
DATA BOOTSTRAP
AUDIT
ERROR HANDLING
SCRIPT BOUNDARIES
DEPENDENCIES ON MAIN2+
```

لكل عنصر:

```text
PRESERVE / RECONSTRUCT / FIX / REPLACE / RETIRE / UNKNOWN
```

---

## 8. MAIN1 PATCH INTEGRITY

إذا كان آخر Git يثبت Patch سابقًا فلا تعِد تنفيذه إلا عند وجود Regression أو contradiction مباشر.

الحالة المرجعية الحالية المعروفة:

```text
ed4e91ec595234ba7ede3f08558c660c1b100d3e
```

وقد ثبت تاريخيًا أنه طبق Patch 1–4 على Main1:

1. `RW_STATE.app.company.id`
2. user/company bootstrap
3. company-scoped `app_settings`
4. company-scoped bootstrap reads

لا تعُد إلى هذه الإصلاحات دون دليل جديد.

---

## 9. SYSTEM SETTINGS / BRANDING CONTRACT

الهوية التشغيلية للشركة ليست قيمة ثابتة داخل HTML.

المصدر السلطوي:

```text
Authenticated User
→ users.company_id
→ app_settings(company_id)
→ branding / company configuration
```

يشمل ذلك بحسب الـschema الحالي، عند وجود الحقول:

```text
company_name
company_logo
company_description
delivery_fee
tax_rate
min_invoice_amount
VAT / registration fields
main_branch_id
```

يجب الحفاظ على `app_settings` كمصدر إعدادات النظام.

القيم الثابتة داخل الواجهة قد تكون Presentation Fallback فقط، ولا يجوز أن تتحول إلى Source of Truth.

إذا كانت Company موجودة في `users/companies` بلا `app_settings`، فهذا **DATA / CONFIGURATION GAP** ويجب تشخيصه منفصلًا. لا يجوز وضع اسم شركة ثابت مكان السجل المفقود ثم اعتبار ذلك إصلاحًا.

---

## 10. TENANT / IDENTITY CONTRACT

العقد:

```text
Authenticated User
→ users.auth_id
→ users.company_id
→ Current Company Context
→ Company-scoped operational data
```

ممنوع استخدام:

```text
LIMIT 1
GLOBAL LOOKUP
UNSCOPED OPERATIONAL LOOKUP
```

عندما تكون الهوية Company-bound.

لكن لا تفرض Company scope على مفتاح يثبته الـSchema كـGlobal.

مثال:

```text
items.item_code UNIQUE globally
```

إذًا Item identity يمكن أن يكون:

```text
item_id / globally-unique item_code
```

مع Company validation على العمليات التي يجب أن تكون tenant-bound.

---

## 11. OWNER CONTRACT

إذا كان العقد التاريخي:

```text
isOwner = true
permissions = ["*"]
owner_profile
active license
```

فلا تستبدل wildcard بقائمة صريحة لمجرد أن القائمتين تبدوان متساويتين.

---

## 12. INVENTORY IMMUTABLE CONTRACT

```text
PHYSICAL STOCK MOVEMENT
→ post_stock_movement
→ stock_branches
+ inventory_log
```

Reservation:

```text
reserve_stock
release_stock_reservation
```

هما Reservation capabilities فقط.

لا يجوز لأي PWA/HTML/RPC/Edge/legacy bridge أن يكتب Physical Stock مباشرة.

---

## 13. DATA REPAIR CONTRACT

أي anomaly يمر عبر:

```text
DETECT
→ IDENTIFY SOURCE
→ HISTORICAL CHECK
→ BUSINESS IMPACT
→ DOWNSTREAM IMPACT
→ DECIDE
→ SURGICAL REPAIR
→ AUDIT
→ VERIFY
```

ممنوع:

```text
LOOKS WRONG
→ DELETE
```

والـFixture/test data لا تُحذف قبل إثبات هويتها وتأثيرها.

---

## 14. PRODUCTION TEST SAFETY

الأولوية:

```text
READ-ONLY
```

أو:

```text
BEGIN
→ CREATE TEMP TEST STATE
→ EXERCISE REAL FUNCTION
→ ASSERT
→ ROLLBACK
```

لا تلوث Production ببيانات اختبار دائمة عندما يمكن عزلها داخل transaction.

---

## 15. FAILURE MEMORY

عند أي فشل يجب تسجيل:

```text
WHAT FAILED
WHY
ROOT CAUSE
WHICH SOURCE WAS WRONG/STALE
WHAT WAS TRIED
WHAT SUCCEEDED
WHAT FAILED
WHAT MUST NOT BE REPEATED
NEW SAFE APPROACH
```

أمثلة محمية:

- stale CURRENT_STATE.
- commit mistaken for deployment proof.
- source mistaken for runtime proof.
- New-main browser failure attributed incorrectly to Main1.
- historical Main1 analysis mistaken for current Main1.
- whole-file rewrite used instead of surgical patch.

---

## 16. MAIN1 → MAIN11 AS ONE PARENT

تعامل مع `main1...main11` كـlogical parent modules إلا إذا أثبت المصدر أنها مستقلة.

لا تحوّل الملفات إلى byte slices.

تحقق من:

```text
GLOBALS
FUNCTION OWNERSHIP
MODULE DEPENDENCIES
LOAD ORDER
EXPORTS
SCRIPT CONTINUITY
DOM CONTRACT
SHARED STATE
AUTH CONTEXT
```

لا تضف أو تحذف script boundary لمجرد الشكل.

---

## 17. GOLD / DIAMOND PARENT VISION

الهدف المعماري:

```text
Integrated Parent Application
+
Historical UI identity
+
Current parent shell
+
Dynamic company configuration
+
Tenant-safe data flow
+
Preserved Owner semantics
+
Correct Core / Edge / RPC ownership
+
No duplicate business engines
+
No fake completion
+
Runtime-verifiable assembly
```

لكن Gold/Diamond لا يُعلن إلا بعد:

```text
SOURCE
+
DATABASE
+
DEPLOYMENT
+
RUNTIME
+
PRODUCTION
+
AUDITABILITY
```

---

## 18. REPORTS ARE INDEXES, NOT TRUTH

التقارير تساعد على معرفة:

```text
where to investigate
what was attempted
what others believed
```

لكن لا تثبت Current Truth وحدها.

عند تعارض تقريرين:

```text
do not choose by recency alone

re-open the underlying evidence
```

---

## 19. CURRENT_STATE UPDATE CONTRACT

بعد كل تنفيذ حقيقي:

```text
ACTION
→ VERIFY
→ WRITE IMMUTABLE REPORT
→ UPDATE CURRENT_STATE
→ RECONCILE HEAD
→ RECORD LAST VERIFIED EVENT
```

`CURRENT_STATE` يجب أن يحتوي دائمًا على:

```text
Current Git HEAD
Latest Verified Event
Production Snapshot
Main1 Status
Open Runtime Gates
Open Data/Configuration Gaps
Next Authorized Action
Last Report Path
```

---

## 20. FINAL SELF-AUDIT

قبل إعلان أي إغلاق:

```text
BUSINESS UNDERSTANDING = ?
ARCHITECTURE UNDERSTANDING = ?
DATABASE UNDERSTANDING = ?
HISTORICAL UNDERSTANDING = ?
PRODUCTION UNDERSTANDING = ?
CURRENT SOURCE UNDERSTANDING = ?
DEPLOYMENT UNDERSTANDING = ?
RUNTIME UNDERSTANDING = ?

CONFIRMED FACTS = []
UNKNOWNS = []
CONFLICTS = []
UNVERIFIED CLAIMS = []

WHAT I PROVED = []
WHAT I DID NOT PROVE = []
WHAT I FIXED = []
WHAT I INITIALLY MISSED = []
WHAT COULD STILL BE WRONG = []
```

أي Unknown أو Conflict مؤثر يمنع Full Closure.

---

## 21. FINAL RULE

لا تقل:

```text
Main1 = 100% Closed
```

إلا عندما تكون الأدلة الفعلية متسقة بين:

```text
CURRENT SOURCE
+
DEPLOYMENT
+
PRODUCTION
+
RUNTIME
+
DATA / CONFIGURATION
```

وبعدها فقط يصبح الانتقال إلى Main2 عملًا مصرحًا به.
