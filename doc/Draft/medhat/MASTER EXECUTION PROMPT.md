# MASTER EXECUTION PROMPT
# RAWAEA ERP — MAIN PWA / 11-PART GOLD–DIAMOND ZERO-DEBT RECONSTRUCTION
## P0 → P11 SERIALIZED FORENSIC REPAIR / INTEGRATION / PRODUCTION CLOSURE

---

# 0. MISSION CLASSIFICATION

هذه مهمة تنفيذية حرجة واستثنائية.

ليست مهمة تحليل.
ليست مهمة إعداد تقرير.
ليست مهمة كتابة اقتراحات.
ليست مهمة إعادة تنسيق.
وليست مهمة إصلاح شكلي.

المطلوب هو:

**إعادة بناء `Current/PWA/main.html` كملف واحد متكامل، من 11 أجزاء مادية، مع الحفاظ على جميع وظائفه وعقوده ومزاياه، وإغلاق الديون التقنية والفجوات والتعارضات، وتحقيق Gold / Diamond Production Closure.**

الملف المادي الحالي موزع على:

```text
Current/PWA/main/main.1.txt
Current/PWA/main/main.2.txt
Current/PWA/main/main.3.txt
Current/PWA/main/main.4.txt
Current/PWA/main/main.5.txt
Current/PWA/main/main.6.txt
Current/PWA/main/main.7.txt
Current/PWA/main/main.8.txt
Current/PWA/main/main.9.txt
Current/PWA/main/main.10.txt
Current/PWA/main/main.11.txt
```

هذه الأجزاء ليست تطبيقات مستقلة.

هي:

```text
ONE LOGICAL FILE
        =
main.1
+
main.2
+
...
+
main.11
```

وأي إصلاح في جزء منها يجب أن يُقاس دائمًا على الملف المنطقي الكامل.

---

# 1. AUTHORITY HIERARCHY

لا تعتمد على الذاكرة.

لا تعتمد على تقرير سابق.

لا تعتمد على مساعد سابق.

لا تعتمد على نسبة Completion سابقة.

لا تعتمد على عبارة:

- fixed
- repaired
- verified
- production-ready
- production deployed
- closed

إلا بعد إعادة إثباتها.

مصادر الحقيقة الفعلية تكون بترتيب التحقيق:

1. Production Supabase الحالية.
2. PostgreSQL functions / triggers / constraints / RLS / grants.
3. Edge Functions المنشورة فعليًا.
4. Git `main` الحالي.
5. جميع أجزاء `Current/PWA/main`.
6. `core.js`.
7. `sw.js`.
8. `register-sw.js`.
9. باقي PWA companions.
10. Git history.
11. Original / Historical sources.
12. Execution logs.
13. Reports / prompts / documentation.

الوثائق السابقة تساعد على فهم التاريخ والنية، لكنها لا تُعتبر حقيقة تشغيلية حالية دون مطابقة.

---

# 2. GOVERNING PRINCIPLE

طبّق دائمًا:

```text
UNDERSTAND
↓
RECONSTRUCT HISTORICAL CONTRACT
↓
RECONSTRUCT CURRENT REALITY
↓
TRACE DATA / AUTH / CONTROL FLOW
↓
TRACE CROSS-PART DEPENDENCIES
↓
COMPARE WITH TARGET ARCHITECTURE
↓
IDENTIFY ACTUAL GAP
↓
DESIGN SURGICAL FIX
↓
IMPLEMENT
↓
INTEGRATE
↓
TEST
↓
DEPLOY
↓
RUNTIME VERIFY
↓
DOCUMENT
↓
CLOSE
↓
NEXT PHASE
```

ممنوع:

```text
BUG FOUND
↓
GUESS
↓
PATCH
```

---

# 3. GOLDEN RULE — NEVER BREAK THE WHOLE TO FIX A PART

كل جزء من `main.html` يعتبر عضوًا في نظام واحد.

لا يجوز أن يتم:

- إصلاح جزء معزولًا.
- حذف وظيفة بدعوى أنها قديمة دون إثبات.
- نقل منطق إلى Core دون إثبات أن Core قادر على حمله.
- حذف dependency لأنه "غير مستخدم" قبل إثبات جميع consumers.
- تغيير selector أو ID أو global function دون فحص جميع references.
- تغيير storage key.
- تغيير event name.
- تغيير route.
- تغيير API contract.
- تغيير RPC contract.
- تغيير database field mapping.
- تغيير permission semantics.
- تغيير OWNER semantics.
- تغيير offline/sync behavior.

إلا بعد:

```text
CONSUMER DISCOVERY
+
HISTORICAL CONTRACT REVIEW
+
PRODUCTION CONTRACT REVIEW
+
CURRENT CONTRACT REVIEW
+
TARGET CONTRACT REVIEW
```

---

# 4. THE SINGLE LOGICAL FILE RULE

قبل أي تعديل:

قم بإعادة بناء الملف المنطقي:

```text
main.1
→
main.2
→
main.3
→
...
→
main.11
```

يجب إنشاء:

```text
MASTER FILE INTEGRITY MAP
```

يتضمن على الأقل:

```text
Part
Start boundary
End boundary
HTML structure
CSS ownership
DOM IDs
DOM classes
Global variables
Functions
Event listeners
API calls
RPC calls
Supabase calls
Storage keys
BroadcastChannel / events
Service Worker interactions
Cross-part references
Dependencies
External libraries
Potential duplicate symbols
Potential shadowing
```

لا تبدأ بإصلاح جزء قبل إثبات موقعه الوظيفي داخل الملف الكامل.

---

# 5. GLOBAL CONTRACT LOCK

أنشئ سجلًا منطقيًا يسمى:

```text
MAIN_HTML_CONTRACT_LEDGER
```

ولا تسمح لأي مرحلة بإسقاط Contract.

الـLedger يجب أن يحتوي على:

| Contract | Historical | Production | Current | Target | Status |
|---|---|---|---|---|---|
| Authentication | | | | | |
| Session | | | | | |
| Token lifecycle | | | | | |
| User identity | | | | | |
| Company identity | | | | | |
| OWNER semantics | | | | | |
| Permissions | | | | | |
| License | | | | | |
| Navigation | | | | | |
| Data loading | | | | | |
| Search | | | | | |
| Cache | | | | | |
| Offline | | | | | |
| Sync | | | | | |
| Realtime | | | | | |
| Notifications | | | | | |
| PWA lifecycle | | | | | |
| Forms | | | | | |
| Validation | | | | | |
| CRUD | | | | | |
| ERP modules | | | | | |
| Vehicles | | | | | |
| Drivers | | | | | |
| Inventory | | | | | |
| Stock vouchers | | | | | |
| Purchasing | | | | | |
| Receiving | | | | | |
| Returns | | | | | |
| Accounting | | | | | |
| Audit | | | | | |
| Settings | | | | | |
| Branding | | | | | |
| Licensing | | | | | |
| Reports | | | | | |
| Export | | | | | |
| Mobile behavior | | | | | |
| Error handling | | | | | |

قاعدة:

> لا يجوز أن ينتقل Contract من حالة إلى أخرى إلا مع إثبات أين أصبح.

---

# 6. GLOBAL DEPENDENCY MAP

أنشئ:

```text
MAIN_HTML_CROSS_PART_DEPENDENCY_MAP
```

لكل function / variable / DOM ID / listener / API wrapper / state object:

```text
OWNER PART
USED BY PARTS
CALLED BY
CALLS
READS
WRITES
SIDE EFFECTS
CONTRACT
```

يجب اكتشاف:

- duplicate functions
- duplicate variables
- duplicate event listeners
- duplicate initialization
- accidental overrides
- hidden globals
- circular dependencies
- order-dependent execution
- undefined references
- dead references
- stale references
- function signature drift

---

# 7. ABSOLUTE OWNER CONTRACT

لا تغير عقد OWNER.

العقد يجب إعادة إثباته من Production:

```text
OWNER
=
isOwner = true
+
permissions = ["*"]
+
owner_profile
+
active license state
```

ممنوع اعتبار:

```text
["*"]
```

مجرد fallback.

ممنوع تحويل wildcard إلى قائمة صلاحيات صريحة لمجرد أنها تبدو مكافئة.

يجب الحفاظ على:

- Owner guards
- License guards
- Permission inheritance
- Owner UI
- Owner-only actions
- License management
- Security semantics

---

# 8. TENANT / COMPANY CONTRACT

ممنوع:

```text
app_settings LIMIT 1
global lookup
unscoped users lookup
unscoped operational data
```

عندما تكون الهوية Company-scoped.

يجب دائمًا التحقق من:

```text
Authenticated User
↓
users.auth_id
↓
users.company_id
↓
Current company context
↓
Company-scoped reads
↓
Company-scoped writes
```

ولا يجوز أن تعتمد الواجهة وحدها على Company isolation.

---

# 9. CORE ARCHITECTURE CONTRACT

يجب ألا يحتوي `main.html` على Physical Stock Engine.

العقد:

```text
PHYSICAL STOCK MOVEMENT
↓
post_stock_movement
↓
stock_branches
+
inventory_log
```

والـReservation:

```text
reserve_stock
```

هو Reservation Engine فقط.

لا تضع:

- stock mutation
- inventory_log writer
- stock adjustment engine

مباشرة في الـPWA.

إذا وجدت legacy writer:

```text
TRACE
→
IDENTIFY
→
DETERMINE WHETHER ACTIVE / LEGACY / BRIDGE
→
REWIRE OR RETIRE SAFELY
```

---

# 10. DO NOT COPY CORE LOGIC INTO MAIN

راجع:

```text
core.js
sw.js
register-sw.js
```

ولا تنشئ نسخة ثانية من:

- Auth
- token refresh
- permissions
- cache
- sync
- search infrastructure
- shared state
- realtime
- API abstraction
- stock logic

داخل `main.html`

إذا كانت Core ناقصة:

```text
FIX CORE
```

بدل:

```text
DUPLICATE CORE INSIDE MAIN
```

---

# 11. EXECUTION MODEL

## P0 = FORENSIC INTEGRATION GATE

P0 لا تعدل Business Behavior.

مهمتها إثبات البيئة قبل أي إصلاح.

في P0:

1. اقرأ أجزاء `main.1` → `main.11` بالكامل.
2. أعد بناء الملف المنطقي.
3. راجع `main.html` الحالي.
4. راجع Original.
5. راجع `core.js`.
6. راجع `sw.js`.
7. راجع `register-sw.js`.
8. راجع PWA companions.
9. راجع Git history.
10. راجع Production.
11. راجع Edge Functions.
12. راجع PostgreSQL.
13. راجع RLS.
14. راجع triggers.
15. راجع grants.
16. راجع execution logs.
17. حدد أي تغييرات أحدث من Prompt 86/87/88.
18. حدد ما تم تنفيذه فعلًا وما لم ينفذ.

أنشئ:

```text
P0_BASELINE
P0_CONTRACT_LEDGER
P0_DEPENDENCY_MAP
P0_RISK_REGISTER
P0_FEATURE_INVENTORY
P0_PRODUCTION_SNAPSHOT
P0_GAPS_REGISTER
```

P0 ناجحة فقط عندما:

```text
UNKNOWN CRITICAL = 0
UNVERIFIED CRITICAL = 0
```

ولا يجوز بدء P1 قبل ذلك.

---

# 12. P1 → P11 EXECUTION MODEL

كل مرحلة P يجب أن تنفذ Lifecycle موحدًا:

```text
PHASE READ
↓
PART RECONSTRUCTION
↓
CROSS-PART IMPACT ANALYSIS
↓
HISTORICAL COMPARISON
↓
PRODUCTION COMPARISON
↓
TARGET COMPARISON
↓
ROOT CAUSE
↓
SURGICAL REPAIR
↓
LOCAL TEST
↓
WHOLE-FILE INTEGRATION TEST
↓
PRODUCTION ALIGNMENT
↓
RUNTIME VERIFICATION
↓
DOCUMENT
↓
CLOSE PHASE
```

---

# P1 — MAIN.1 FOUNDATION / DOCUMENT / SHELL

النطاق الأساسي:

- HTML document foundation
- head
- external libraries
- CSS foundation
- login shell
- global layout
- sidebar shell
- header shell
- page container
- root-level globals

أصلح فقط ما يثبت أنه خطأ.

تحقق من:

- duplicate imports
- incompatible libraries
- CSS conflicts
- broken IDs
- inaccessible DOM roots
- structural imbalance
- mobile regressions
- script order problems
- CSP/security implications إن وجدت
- global namespace pollution

### P1 mandatory output

```text
P1_FUNCTIONAL_BASELINE
P1_DOM_CONTRACT
P1_GLOBAL_SYMBOL_MAP
P1_EXTERNAL_DEPENDENCY_MAP
P1_TEST_RESULT
```

ثم:

```text
P1 = CLOSED
```

فقط إذا لم يتأثر P2→P11.

---

# P2 — AUTH / SESSION / IDENTITY

افحص:

- login
- logout
- session restore
- token lifecycle
- expired session
- refresh
- user retrieval
- company retrieval
- role
- permissions
- OWNER
- bootstrap
- auth failure
- fail-closed behavior
- unauthorized behavior

خصوصًا:

```text
forceEnterFallback()
```

يجب ألا يؤدي إلى fail-open.

القاعدة:

```text
AUTH FAILURE
→
SAFE FAILURE
```

وليس:

```text
AUTH FAILURE
→
ENTER APPLICATION
```

اختبر:

1. valid session
2. expired session
3. invalid token
4. missing user
5. missing company
6. inactive user
7. OWNER
8. non-owner
9. permission wildcard
10. ordinary permissions

---

# P3 — BOOTSTRAP / COMPANY CONTEXT / BRANDING / SETTINGS

أعد ربط الوظائف التي ثبت فقدانها.

راجع:

```text
app_settings
```

والحقول المثبتة في Production.

يجب أن يعمل:

- company name
- company logo
- company phone
- store name
- store logo
- store primary color
- store secondary color
- payment method
- currency
- delivery fee
- minimum invoice amount
- tax rate
- main branch
- license state

مع Company-scoping صحيح.

ممنوع اختراع defaults تناقض Production.

---

# P4 — NAVIGATION / SPA / VIEW LIFECYCLE

افحص:

- module switching
- active navigation
- view initialization
- cleanup
- event listeners
- deep links
- browser refresh
- history
- back/forward
- mobile navigation
- route consistency
- repeated view initialization

ابحث عن:

```text
duplicate initialization
listener leaks
stale DOM references
```

كل module يجب أن يمتلك lifecycle واضحًا.

---

# P5 — DATA LOADING / API / CACHE / SEARCH

راجع:

- initial loading
- lazy loading
- pagination
- cache
- stale cache
- refresh
- error states
- empty states
- search
- smart search
- filtering
- sorting

ابحث عن:

- N+1 queries
- global queries
- unscoped queries
- stale cache after mutation
- cache poisoning
- duplicate loading
- race conditions

لا تكسر Search أو Cache أثناء تحسين الأداء.

---

# P6 — ERP MASTER DATA / CRUD

راجع جميع عمليات:

- Items
- Customers
- Suppliers
- Vehicles
- Drivers
- Branches
- Users
- Categories
- Settings

لكل module:

```text
READ
CREATE
UPDATE
DELETE / DEACTIVATE
VALIDATE
AUTH
TENANT
CACHE
ERROR
AUDIT
```

خاصة:

```text
create_vehicle_atomic
save-settings
```

يجب ألا تعاد كتابة صلاحيات الـbackend داخل الـfrontend.

---

# P7 — SALES / POS / VAN SALES / TELESALES / ORDERS

راجع:

- POS
- Van Sales
- Telesales
- Orders
- invoice creation
- customer selection
- pricing
- discounts
- payment
- order status
- invoice status
- sales rep
- branch
- stock interaction

احفظ Contract:

```text
POSSale
VanSale
```

والـBusiness distinctions بينها.

لا تغير behavior فقط لكونه يبدو غير مثالي.

أي تغيير يجب أن يثبت:

```text
Historical Contract
+
Production Contract
+
Target Contract
```

---

# P8 — WAREHOUSE / RUNSHEETS / PICKING / LOADING / DELIVERY

راجع:

- runsheets
- picking
- loading
- delivery
- returns preparation
- order fulfillment
- quantities
- statuses
- driver
- vehicle
- warehouse flow
- reservation

القواعد:

```text
order_details
=
authoritative fulfillment detail
```

و:

```text
run_sheet_details
=
derived aggregate
```

ممنوع Dual Write غير مبرر.

راجع race conditions.

راجع state transitions.

---

# P9 — STOCK VOUCHERS / INVENTORY / RETURNS / RECEIVING

هذه مرحلة حرجة.

تحقق من:

```text
CREATE
→
SEND
→
RECEIVE
→
COMPLETE
→
CANCEL
```

راجع الأنواع.

راجع:

- Purchase
- Transfer
- Sale
- Return
- Adjustment
- Receiving

وتأكد أن:

```text
main.html
```

لا ينفذ Physical Stock مباشرة.

أي stock mutation يجب أن يمر عبر:

```text
post_stock_movement
```

كما يجب احترام:

```text
reserve_stock
```

كـReservation only.

راجع partial receive / idempotency / retry / duplicate submission.

---

# P10 — ACCOUNTING / LEDGERS / AUDIT / LICENSE

راجع:

- journal interactions
- customer ledger
- supplier ledger
- driver ledger
- daily settlement
- treasury
- audit
- license
- owner license management

المبدأ:

الواجهة لا تنشئ accounting truth من تلقاء نفسها إذا كان الـbackend هو مصدر الحقيقة.

تحقق من:

```text
Owner
+
License
+
Authorization
+
Audit
```

ولا تسمح بإسقاط أي Feature تاريخي.

---

# P11 — PWA FINAL INTEGRATION / OFFLINE / SYNC / REALTIME / GOLD-DIAMOND CLOSURE

هذه ليست مجرد المرحلة الأخيرة.

هذه **Whole System Closure Gate**.

راجع:

- service worker
- cache strategy
- cache invalidation
- offline behavior
- queue
- sync retry
- duplicate sync
- conflict resolution
- realtime
- notifications
- app lifecycle
- reload
- reconnect
- stale tab
- multiple tabs
- mobile
- desktop
- browser refresh
- hard refresh
- session restoration

ثم أعد بناء:

```text
main.html
=
main.1
+
...
+
main.11
```

مرة أخرى من الصفر.

---

# 13. THE REASSEMBLY GATE

بعد P11 لا تقرأ الأجزاء كمستندات منفصلة.

أعد تجميعها إلى ملف واحد.

ثم نفذ:

```text
SYNTAX CHECK
STRUCTURAL CHECK
DOM CHECK
SYMBOL CHECK
REFERENCE CHECK
EVENT CHECK
API CHECK
RPC CHECK
AUTH CHECK
TENANT CHECK
PERMISSION CHECK
OWNER CHECK
LICENSE CHECK
PWA CHECK
SERVICE WORKER CHECK
OFFLINE CHECK
SYNC CHECK
REALTIME CHECK
ERP FUNCTION CHECK
```

ثم:

```text
WHOLE-FILE REGRESSION
```

---

# 14. NO FUNCTION LOSS PROTOCOL

قبل أي تعديل:

أنشئ:

```text
FEATURE BASELINE
```

لكل feature:

```text
Feature
Historical existence
Current existence
Original behavior
Current behavior
Target behavior
Required preservation
```

بعد كل Phase:

```text
FEATURE DIFF
```

لا يجوز:

```text
Before = 100 features
After = 96 features
```

ثم الادعاء بالنجاح.

أي feature اختفت يجب أن تكون:

```text
REMOVED BY VALIDATED CONTRACT
```

وإلا تعتبر:

```text
REGRESSION
```

---

# 15. NO CONTRACT LOSS PROTOCOL

كل Contract يتم تصنيفه:

```text
PRESERVE
MIGRATE
DEPRECATE
RETIRE
REPLACE
```

ولا يجوز:

```text
UNKNOWN
```

لـCritical Contract.

---

# 16. NO TECHNICAL DEBT PROTOCOL

أي defect يتم اكتشافه يجب أن يدخل:

```text
FINDING
→
ROOT CAUSE
→
HISTORICAL CHECK
→
PRODUCTION CHECK
→
TARGET CHECK
→
FIX
→
TEST
→
DEPLOY
→
VERIFY
→
CLOSE
```

ممنوع:

```text
TODO
FIX LATER
KNOWN ISSUE
TEMPORARY HACK
WORKAROUND
```

في نهاية المهمة، إلا إذا كان هناك مبرر معماري موثق وصريح.

---

# 17. NO GAPS PROTOCOL

قبل إغلاق أي Phase:

أجب:

```text
What remains unknown?
What remains unverified?
What remains duplicated?
What remains legacy?
What remains outside Core?
What remains outside Tenant scope?
What remains outside OWNER semantics?
What remains untested?
What remains un-deployed?
What remains unverified in Production?
```

أي Critical gap:

```text
PHASE NOT CLOSED
```

---

# 18. CURRENT / PRODUCTION CONTINUOUS SYNC RULE

قبل كل:

- report
- comparison
- percentage
- closure statement
- next phase

نفذ:

```text
CURRENT GIT SNAPSHOT
+
CURRENT PRODUCTION SNAPSHOT
+
CURRENT EDGE DEPLOYMENT SNAPSHOT
```

في نفس السياق الزمني قدر الإمكان.

لا تستخدم نسبة قديمة.

ولا تقل:

```text
90%
```

إلا إذا كانت مبنية على Baseline معلومة وقابلة لإعادة الإنتاج.

---

# 19. PRODUCTION EXECUTION STANDARD

كل تغيير يجب أن يسجل حالته واحدة فقط من:

```text
THEORETICAL
CURRENT-ONLY
GIT-COMMITTED
STAGING-VERIFIED
PRODUCTION-DEPLOYED
PRODUCTION-RUNTIME-VERIFIED
100%-CLOSED
```

لا يجوز تحويل:

```text
GIT COMMITTED
```

إلى:

```text
PRODUCTION DEPLOYED
```

ولا:

```text
STAGING VERIFIED
```

إلى:

```text
PRODUCTION VERIFIED
```

---

# 20. EXECUTION LOGGING

لكل P:

أنشئ سجلًا:

```text
P0_EXECUTION_LOG
P1_EXECUTION_LOG
P2_EXECUTION_LOG
...
P11_EXECUTION_LOG
```

ويجب أن يذكر:

```text
Phase
Part
Start State
Evidence Used
Findings
Root Causes
Changes
Files Changed
Functions Changed
Contracts Preserved
Contracts Changed
Tests
Production Deployment
Production Runtime Verification
Remaining Unknowns
Remaining Risks
Closure Decision
```

---

# 21. CROSS-PHASE HANDOFF CONTRACT

لا تبدأ P(n+1) إلا بعد وجود:

```text
P(n)_CLOSED
```

ويجب أن تحتوي على:

```text
No unresolved critical defect
No unresolved critical contract
No unresolved critical dependency
No unverified production claim
No lost feature
No lost responsibility
```

لكن:

إذا اكتشفت P(n+1) أن P(n) كانت خاطئة:

لا تحافظ على خطأ تاريخي لمجرد أن المرحلة أُغلقت.

افعل:

```text
REOPEN P(n)
FIX
REVERIFY
RE-CLOSE
```

---

# 22. SAFE REPAIR STRATEGY

ممنوع wholesale rewrite لملف كامل فقط لأنه كبير.

القاعدة:

```text
SURGICAL CHANGE
```

إلا إذا ثبت أن بنية كاملة يجب إعادة بنائها.

وفي هذه الحالة يجب أولًا إنشاء:

```text
BEFORE SNAPSHOT
RESPONSIBILITY MAP
FEATURE MAP
CONTRACT MAP
DEPENDENCY MAP
ROLLBACK POINT
```

ثم التنفيذ.

---

# 23. GOLD / DIAMOND QUALITY GATE

Gold ليست:

```text
Looks good
```

Diamond ليست:

```text
No visible bug
```

بل:

## GOLD

```text
Feature complete
Contract preserved
Architecture aligned
Production deployed
```

## DIAMOND

```text
Feature complete
+
Contract complete
+
Tenant safe
+
Owner safe
+
PWA safe
+
Offline safe
+
Sync safe
+
Realtime aware
+
Core aligned
+
No parallel business engine
+
No known critical gap
+
Production runtime verified
+
Documentation complete
+
Current/Production aligned
```

---

# 24. FINAL FORENSIC AUDIT

أنشئ:

```text
FINAL_MAIN_HTML_FORENSIC_AUDIT
```

ويتضمن:

## What was proved

## What was fixed

## What was preserved

## What was migrated

## What was retired

## What was discovered late

## What was initially wrong

## What changed after Prompt 86

## What changed after Prompt 87

## What changed after Prompt 88

## What changed directly in Production

## What changed only in Git

## What was runtime verified

## What was not runtime verified

## Remaining Unknowns

## Remaining Conflicts

## Remaining Risks

## Remaining Technical Debt

## Remaining Feature Debt

## Remaining Contract Debt

---

# 25. FINAL GLOBAL MATRIX

أنشئ:

```text
MAIN_HTML_GLOBAL_MATRIX
```

| Phase | Part | Scope | Features Preserved | Contracts Preserved | Fixes | Production | Runtime Verified | Status |
|---|---|---|---|---|---|---|---|---|
| P0 | Baseline | | | | | | | |
| P1 | main.1 | | | | | | | |
| P2 | main.2 | | | | | | | |
| P3 | main.3 | | | | | | | |
| P4 | main.4 | | | | | | | |
| P5 | main.5 | | | | | | | |
| P6 | main.6 | | | | | | | |
| P7 | main.7 | | | | | | | |
| P8 | main.8 | | | | | | | |
| P9 | main.9 | | | | | | | |
| P10 | main.10 | | | | | | | |
| P11 | main.11 | | | | | | | |

---

# 26. FINAL ZERO-DEBT GATE

لا تعتبر المهمة مكتملة إلا إذا أثبتت:

```text
ALL 11 PARTS READ
+
WHOLE FILE RECONSTRUCTED
+
ALL CROSS-PART DEPENDENCIES CHECKED
+
ALL CRITICAL FEATURES PRESERVED
+
ALL CRITICAL CONTRACTS PRESERVED
+
ALL CRITICAL DEFECTS FIXED
+
TENANT INTEGRITY
+
OWNER INTEGRITY
+
LICENSE INTEGRITY
+
AUTH INTEGRITY
+
PWA INTEGRITY
+
OFFLINE INTEGRITY
+
SYNC INTEGRITY
+
REALTIME INTEGRITY
+
CORE ALIGNMENT
+
NO PARALLEL PHYSICAL STOCK ENGINE
+
NO CRITICAL GAPS
+
NO CRITICAL UNKNOWN
+
NO CRITICAL UNVERIFIED CLAIM
+
CURRENT/GIT ALIGNED
+
PRODUCTION ALIGNED
+
PRODUCTION RUNTIME VERIFIED
```

ثم:

```text
GLOBAL MAIN PWA CORE INTEGRITY = 100% CLOSED
```

ولا تستخدم أي صياغة بديلة إذا لم تتحقق الشروط.

---

# 27. BEHAVIOR ON FAILURE

لا تتوقف عند:

```text
Blocked
```

إلا إذا كان هناك حظر حقيقي غير قابل للتجاوز من الصلاحيات أو البنية التحتية.

عند اكتشاف Defect:

```text
FOUND
↓
INVESTIGATE
↓
ROOT CAUSE
↓
HISTORICAL VALIDATION
↓
PRODUCTION VALIDATION
↓
TARGET VALIDATION
↓
SURGICAL FIX
↓
TEST
↓
DEPLOY
↓
VERIFY
↓
CLOSE
```

إذا كان العائق نتيجة نقص في أداة أو مسار:

ابحث عن وسيلة تنفيذ بديلة آمنة.

ممنوع اختراع نجاح غير موجود.

ممنوع الادعاء بأن إجراءً تم دون دليل.

---

# 28. MANDATORY SELF-AUDIT BEFORE EVERY PHASE

```text
PHASE SELF-AUDIT

Current Part Read Completely: YES/NO
Whole-file context checked: YES/NO
Historical context checked: YES/NO
Production checked: YES/NO
Edge Functions checked: YES/NO
PostgreSQL checked: YES/NO
Dependencies checked: YES/NO
Consumers checked: YES/NO
Feature baseline checked: YES/NO
Contract ledger checked: YES/NO
Tenant checked: YES/NO
OWNER checked: YES/NO
Potential regressions checked: YES/NO
Production verification available: YES/NO

UNKNOWN:
CONFLICT:
UNVERIFIED CLAIM:
NEW DEBT:
NEW GAP:
```

أي Critical `YES/NO` غير مثبت:

```text
DO NOT CLOSE
```

---

# 29. FINAL COMMAND

ابدأ من:

```text
P0
```

ثم:

```text
P1
P2
P3
P4
P5
P6
P7
P8
P9
P10
P11
```

بالترتيب.

لا تتخطَّ Phase.

لا تعكس الترتيب.

لا تجمع إصلاحات غير مترابطة دفعة واحدة.

لكن إذا كشف الإصلاح أن Phase سابقة تحتوي خطأ:

```text
REOPEN
→
FIX
→
VERIFY
→
CLOSE
→
CONTINUE
```

يجب الحفاظ على وحدة الملف:

```text
main.1 + main.2 + ... + main.11
```

حتى النهاية.

الهدف النهائي ليس:

```text
11 repaired text files
```

بل:

```text
ONE GOLD–DIAMOND MAIN.HTML
```

واحد:

```text
ONE APPLICATION SHELL
ONE STATE MODEL
ONE AUTH MODEL
ONE TENANT MODEL
ONE PERMISSION MODEL
ONE OWNER MODEL
ONE DATA MODEL
ONE PWA MODEL
ONE CORE ARCHITECTURE
ONE BUSINESS CONTRACT
ONE PRODUCTION REALITY
```

وعند النهاية فقط:

```text
FINAL WHOLE-FILE REASSEMBLY
→
FINAL FORENSIC AUDIT
→
FINAL PRODUCTION SYNC
→
FINAL RUNTIME VERIFICATION
→
ZERO-DEBT CLOSURE
```

ثم أعلن فقط النتيجة التي تثبتها الأدلة.

**لا تتوقف بين P0 وP11 لمجرد كتابة تقرير.**
انتقل تلقائيًا إلى المرحلة التالية بعد إغلاق السابقة فعليًا.
ولا تعتبر أي مرحلة مغلقة إلا بعد تحققها.
ولا تترك وراءك:

- Technical Debt
- Contract Debt
- Feature Debt
- Dependency Gap
- Tenant Gap
- Security Gap
- Production Drift
- Current Drift
- Documentation Gap

إلا إذا كان غير Critical ومُثبتًا صراحةً في السجل النهائي.

**المطلوب تنفيذ كامل، وليس وصف التنفيذ.**