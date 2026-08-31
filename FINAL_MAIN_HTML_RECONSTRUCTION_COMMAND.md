# RAWAEA ERP — FINAL MAIN.HTML RECONSTRUCTION COMMAND

## PURPOSE

هذه ليست خطة، وليست مراجعة تاريخية، وليست Prompt لاستكمال سلسلة سابقة.

**مهمتك الوحيدة:**

إعادة إنشاء:

`Current/PWA/main.html`

من الصفر، اعتمادًا على **الحقيقة الحالية المثبتة**، ثم إثبات أن الملف الجديد يحافظ على الوظائف والعقود المطلوبة، ومتوافق مع Production، ثم تحديث `CURRENT_STATE.md` وإعلان الإغلاق فقط بعد اكتمال بوابات الإثبات.

---

# 1. SINGLE ENTRY POINT — START HERE

ابدأ دائمًا بقراءة:

`/CURRENT_STATE.md`

ثم نفّذ فورًا:

`VERIFY CURRENT GIT HEAD`

`VERIFY CURRENT PRODUCTION SNAPSHOT`

`VERIFY CURRENT ACTIVE DEPLOYMENTS`

إذا اختلف الواقع عن `CURRENT_STATE.md`:

`STATE = STALE`

ثم حدّث `CURRENT_STATE.md` بالحقيقة الجديدة.

**لا تنفذ إعادة بناء قبل مزامنة الحالة.**

---

# 2. AUTHORITY RULE

لإثبات ما يوجد الآن، استخدم بهذا الترتيب:

1. Production Supabase الحالية.
2. PostgreSQL schema / functions / triggers / constraints / RLS / grants.
3. Active Edge Functions الحالية.
4. Git `main` الحالي.
5. Current PWA companions وCore/SW.
6. Current repository source files.
7. Git history فقط لحسم Contract محدد.
8. Original sources فقط لاستعادة وظيفة مثبت أنها لازمة.
9. Historical reports/prompts فقط لفهم السياق، وليس لإثبات Current Truth.

**لا يوجد مصدر اسمه “آخر تقرير” له سلطة تشغيلية.**

---

# 3. ABSOLUTE PROHIBITION: DO NOT REOPEN THE HISTORICAL LOOP

ممنوع:

- إعادة تنفيذ سلسلة main1 → main11.
- اعتبار `main.1..main.11` مكونات حالية لمجرد أن Prompt قديم ذكرها.
- إعادة قراءة عشرات التقارير بحثًا عن “الحل النهائي”.
- نسخ Original إلى Current ثم تعديل ما يبدو ناقصًا.
- إعادة بناء ما سبق إصلاحه لمجرد أنه تاريخيًا كان مختلفًا.
- استخدام نسب الإنجاز السابقة.
- استخدام أي عبارة `fixed / verified / closed / Gold / Diamond` قديمة كإثبات حالي.

القاعدة:

`HISTORICAL MATERIAL = EVIDENCE OF PAST`

`CURRENT_STATE + GIT + PRODUCTION = EVIDENCE OF NOW`

---

# 4. CLEAN-ROOM RECONSTRUCTION CONTRACT

لا تعدّل `Current/PWA/main.html` مباشرة في أول خطوة.

أولًا أنشئ **Candidate** خارج الملف النهائي.

الـCandidate يجب أن يُبنى من:

- Current `main.html` للميزات الموجودة حاليًا.
- Current PWA companions.
- Core / Service Worker / registration contracts.
- Production contracts.
- Current active API / RPC contracts.
- Original sources فقط عند إثبات Feature Contract مفقود.
- Validated changes الموجودة فعليًا في Git/Production.

ولا يجوز نقل كود إلا إذا عُرف:

`WHAT IT DOES`

`WHO CONSUMES IT`

`WHAT CONTRACT IT SERVES`

`WHETHER IT IS ACTIVE`

`WHETHER IT IS REQUIRED NOW`

---

# 5. THE ONLY REQUIRED LEDGER

أنشئ داخليًا سجلًا واحدًا:

`MAIN_HTML_CURRENT_CONTRACT_LEDGER`

ويجب أن يغطي على الأقل:

- HTML shell
- CSS/UI shell
- authentication
- session
- user identity
- company identity
- OWNER semantics
- permissions
- license state
- navigation
- data loading
- search
- cache
- offline
- sync
- realtime
- notifications
- PWA lifecycle
- CRUD
- ERP modules
- customers
- suppliers
- products/items
- sales/POS
- Van Sales
- telesales/order ticker إن كانت ما تزال Current
- purchasing
- receiving
- inventory
- stock vouchers
- picking
- loading
- delivery
- returns
- vehicles
- drivers
- accounting
- audit
- settings
- reports/export
- mobile behavior
- error handling

لكل عنصر:

`CURRENT EVIDENCE`

`REQUIRED NOW?`

`CONSUMERS`

`IMPLEMENTED IN CANDIDATE?`

`VERIFICATION METHOD`

إذا لم يمكن إثبات عنصر ما، لا تحذفه تلقائيًا. صنّفه:

`UNKNOWN`

ولا تستخدم `UNKNOWN → REMOVE`.

---

# 6. DO NOT INVENT MISSING FILES OR CONTRACTS

إذا لم تجد:

- ملفًا
- function
- RPC
- route
- event
- storage key
- API
- module

في Current:

ابحث في Current repository + Production + active consumers.

إن لم يثبت وجوده:

`MISSING / UNVERIFIED`

ولا تخترع بديلًا.

الاستثناء الوحيد: إذا كانت وظيفة مطلوبة بقوة من Contract مثبت ويمكن إعادة بنائها من الأدلة المباشرة، تُصنف:

`RECONSTRUCTABLE FROM EVIDENCE`

ويجب إثبات consumer قبل الإضافة.

---

# 7. MAIN.HTML MUST NOT BECOME A SECOND CORE

ممنوع وضع داخل `main.html` نسخة مستقلة من:

- Authentication engine
- token lifecycle
- permission engine
- cache engine
- sync engine
- realtime engine
- stock engine
- inventory_log writer
- stock adjustment engine
- shared state engine

إذا كان المنطق ملكًا لـCore أو Backend:

`CALL THE OWNER`

ولا:

`COPY THE OWNER`

---

# 8. INVENTORY CONTRACT LOCK

يجب أن يبقى:

`PHYSICAL STOCK MOVEMENT`

↓

`post_stock_movement`

↓

`stock_branches + inventory_log`

و:

`reserve_stock / release_stock_reservation`

هما Reservation capabilities فقط.

ممنوع أن يحتوي `main.html` على أي كتابة مباشرة إلى:

- `stock_branches.qty`
- `inventory_log`

وممنوع تنفيذ Physical Stock Movement خارج الـBackend owner contract.

---

# 9. TENANT / IDENTITY LOCK

يجب الحفاظ على:

`Authenticated user`

↓

`users.auth_id`

↓

`users.company_id`

↓

`company-scoped data`

وممنوع:

- company-unscoped operational lookup
- `app_settings LIMIT 1` عندما تحدد company identity
- global lookup لهوية تشغيلية غير مثبت أنها global

لا تغيّر هذا العقد من الواجهة.

---

# 10. OWNER SEMANTICS LOCK

لا تغيّر أو “تبسط” Owner behavior.

إذا كان Current Contract المثبت هو:

`isOwner = true`

+

`permissions = ["*"]`

+

`owner_profile`

+

`active license state`

فيجب الحفاظ على جميع semantics المرتبطة به.

لا تستبدل wildcard بقائمة صلاحيات صريحة لمجرد أنها تبدو مساوية.

---

# 11. SOURCE COMPOSITION RULE

رتّب بناء Candidate هكذا:

`CURRENT MAIN.HTML`

+

`CURRENT PWA / CORE CONTRACTS`

+

`PRODUCTION-VERIFIED BEHAVIOR`

+

`VALIDATED CHANGES`

+

`ORIGINAL ONLY FOR PROVEN MISSING CONTRACTS`

الهدف ليس جعل الملف “مثل Original”.

الهدف هو جعل الملف:

`CURRENT + COMPLETE + CONTRACT-PRESERVING + PRODUCTION-COMPATIBLE`

---

# 12. REWRITE RULE

اكتب Candidate جديدًا من الصفر.

لا تعتمد على patch chain طويل.

لا تحوّل الملف إلى تجميع عشوائي لقطع تاريخية.

أعد تنظيم البنية فقط بالقدر الذي لا يغير Contract.

أي إعادة تصميم داخلية يجب أن تكون:

`BEHAVIOR-PRESERVING`

ما لم يوجد Contract مثبت يوجب تغييرًا.

---

# 13. PARITY GATE — REQUIRED BEFORE REPLACEMENT

قبل استبدال `Current/PWA/main.html`، يجب إثبات:

### A. Structural parity

- valid HTML
- scripts/load order
- DOM roots
- required IDs
- required classes/selectors
- no duplicate critical IDs
- no duplicate global function definitions that cause shadowing
- no missing critical references

### B. Functional parity

كل Feature مثبت أنها Current يجب أن يكون لها:

`implemented`

و:

`consumer path verified`

و:

`error path verified`

### C. Contract parity

تحقق من:

- auth
- session
- company
- OWNER
- permissions
- license
- API/RPC contracts
- data field mappings
- storage keys
- events
- service-worker integration
- offline/sync behavior

### D. Change parity

كل تغيير مثبت بأنه ما زال مطلوبًا يجب أن يكون موجودًا في Candidate، أو يجب أن يوجد دليل مباشر يثبت أنه retired/replaced.

لا تسمح بـ:

`validated change disappears silently`

---

# 14. REPLACEMENT RULE

لا تستبدل `Current/PWA/main.html` إلا بعد نجاح كل بوابات Candidate السابقة.

عند الاستبدال:

1. احفظ hash للملف القديم.
2. اكتب الملف الجديد.
3. سجّل Git SHA الجديد.
4. حدّث `CURRENT_STATE.md` فورًا.
5. لا تنتقل لأي إصلاح آخر قبل التحقق من هذا الحدث.

---

# 15. PRODUCTION VERIFICATION — MANDATORY

بعد تحديث Git:

لا تعلن الإغلاق.

أثبت Production compatibility باستخدام الواقع الحالي.

يجب على الأقل التحقق من:

- login/session bootstrap
- company context
- navigation/root initialization
- core API connectivity
- representative read path
- representative write path
- inventory read path
- voucher/sales/purchase/return path حسب ما هو Current ومثبت
- error handling
- PWA/service-worker integration

لا يلزم تنفيذ عمليات مالية أو مخزنية دائمة لمجرد الاختبار.

استخدم:

`read-only verification`

أو:

`transactional test + rollback`

حيثما كان ذلك آمنًا.

لكن يجب أن يكون الاختبار على **Production runtime الفعلي أو Production contracts الفعلية**، وليس على Candidate فقط.

---

# 16. RUNTIME TRUTH RULE

يُمنع تحويل:

`static PASS`

إلى:

`Production PASS`

ويُمنع تحويل:

`staging PASS`

إلى:

`runtime PASS`

ويُمنع تحويل:

`Git commit exists`

إلى:

`feature works`

الإغلاق يتطلب الدليل المقابل لكل Claim.

---

# 17. LAST VERIFIED EVENT — MANDATORY AFTER EVERY REAL STEP

بعد كل تنفيذ حقيقي يغيّر Git أو Production أو Candidate/validated artifact:

`VERIFY`

↓

`UPDATE CURRENT_STATE.md`

↓

`NEXT ACTION`

سجّل في `CURRENT_STATE.md`:

- EVENT ID
- EVENT TYPE
- UTC TIMESTAMP
- SOURCE
- GIT SHA
- PRODUCTION STATE
- ACTION
- RESULT
- EVIDENCE
- IMPACT
- NEXT AUTHORIZED ACTION

**لا تستخدم LAST REPORT.**

---

# 18. FAILURE RULE

عند فشل أي Gate:

لا تواصل إلى المرحلة التالية.

ولا تدخل في تاريخ جديد.

ولا تعيد كتابة كل شيء عشوائيًا.

اعزل سبب الفشل:

`FAILURE`

→ `ROOT CAUSE`

→ `SURGICAL FIX`

→ `REVERIFY`

ثم فقط تابع.

---

# 19. CLOSURE GATE

لا يجوز كتابة:

`MAIN.HTML FINAL`

ولا:

`100% CLOSED`

إلا إذا أثبتت جميع الآتي:

`CURRENT_STATE synchronized`

+

`current Git verified`

+

`current Production verified`

+

`candidate built from evidence`

+

`structural parity PASS`

+

`functional parity PASS`

+

`contract parity PASS`

+

`validated change parity PASS`

+

`Production compatibility PASS`

+

`Production runtime smoke PASS`

+

`no unresolved critical unknown`

+

`CURRENT_STATE updated with final verified event`

---

# 20. FINAL OUTPUT — AFTER REAL EXECUTION ONLY

عند اكتمال المهمة، اترك في Git فقط ما يثبت النتيجة:

1. `Current/PWA/main.html` النهائي.
2. `CURRENT_STATE.md` محدّثًا إلى آخر Verified Event.
3. أي evidence/artifact ضروري لإعادة التحقق مستقبلًا.

لا تنشئ تقريرًا طويلًا ليكون بديلًا عن التنفيذ.

التقرير المختصر النهائي يجب أن يذكر فقط:

- Final Git SHA
- Final `main.html` identity/hash
- parity result
- Production runtime result
- remaining blockers (إن وجدت)
- LAST VERIFIED EVENT
- next authorized action

---

# 21. ABSOLUTE END CONDITION

إذا كان هناك أي عنصر من العناصر التالية غير مثبت:

`UNKNOWN`

`UNVERIFIED`

`PRODUCTION NOT VERIFIED`

`PARITY FAILED`

`CONTRACT CONFLICT`

`CURRENT_STATE STALE`

فالحالة:

`MAIN.HTML RECONSTRUCTION = OPEN`

وليس Closed.

وعند الإغلاق فقط:

`MAIN.HTML RECONSTRUCTION = 100% CLOSED`

ثم لا تفتح التاريخ من جديد، ولا تنتقل إلى مهمة أخرى إلا وفق `NEXT AUTHORIZED ACTION` داخل `CURRENT_STATE.md`.

---

# EXECUTION COMMAND

**Execute this command against the current repository and current Production. Do not merely describe the work.**

`START → CURRENT_STATE.md → RECONCILE → CLEAN-ROOM CANDIDATE → PARITY → REPLACE → VERIFY PRODUCTION RUNTIME → UPDATE CURRENT_STATE.md → CLOSE`
