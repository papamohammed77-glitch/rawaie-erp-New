# MASTER MEMORY TRANSFER DIRECTIVE — RAWAEA ERP

## 0. PURPOSE

هذه الوثيقة هي **بروتوكول نقل الذاكرة الكامل** لـ RAWAEA ERP إلى CTO جديد توقفت ذاكرته قبل Prompt 11.

الهدف ليس تلخيص المشروع، وليس إعطاء CTO القادم مجموعة روابط ثم مطالبته بإعادة التحقيق من الصفر.

الهدف هو بناء **Knowledge Transfer Package** يجعل CTO القادم يدخل المحطة الحالية وهو يحمل:

- التسلسل التاريخي الكامل من Prompt 11 حتى آخر محطة موثقة؛
- كل التحولات المعمارية المهمة؛
- كل ما تغير في Production؛
- كل ما تغير في Git؛
- كل ما تغير في Edge Functions / RPCs / Schema / UI؛
- كل القرارات التي اتخذت ولماذا؛
- كل التصحيحات التي ألغت أو عدلت استنتاجات أقدم؛
- كل الفجوات المفتوحة والمخاطر؛
- الفرق بين Historical Truth وCurrent Production Truth؛
- والخريطة التشغيلية التي تسمح له بالاستكمال دون إعادة قراءة عشرات الملفات.

هذه الوثيقة ليست تقريرًا عن إنجاز المهمة. إنها **مواصفة إنشاء الذاكرة المنقولة نفسها**.

---

# 1. ROLE

أنت تعمل كـ:

**CTO Knowledge Reconstruction Engineer / Forensic Historian / Production Continuity Architect**

مهمتك بناء حزمة ذاكرة قابلة للتسليم إلى CTO آخر.

لا يجوز لك اختراع معلومة لإنهاء جدول.
لا يجوز لك تحويل تقرير قديم إلى حقيقة حالية.
لا يجوز لك حذف حدث لأن نتيجته أصبحت قديمة.
لا يجوز لك دمج حدثين مختلفين لمجرد أنهما يعالجان نفس الوحدة.
لا يجوز لك إسقاط الإصلاحات الصغيرة أو تصحيحات الـConsumer أو تعديلات الـProduction لأنها تبدو ثانوية.

---

# 2. CONTINUITY PRINCIPLE

الـCTO الجديد يجب أن يقرأ الحزمة ويستطيع الإجابة دون العودة إلى السلسلة الأصلية عن:

1. كيف بدأ الوضع عند Prompt 11؟
2. ماذا اكتشف كل Prompt لاحق؟
3. ماذا تغير بسبب كل اكتشاف؟
4. ما الذي تغير في Git؟
5. ما الذي تغير في Production؟
6. ما الذي تم نشره؟
7. ما الذي تم تصحيحه لاحقًا؟
8. ما الذي أصبح Legacy؟
9. ما الذي ظل Open؟
10. ما الذي كان صحيحًا تاريخيًا ولم يعد صحيحًا حاليًا؟
11. ما هو الوضع الحالي المثبت؟
12. ما الخطوة التالية الصحيحة؟

---

# 3. SOURCE AUTHORITY — NON-NEGOTIABLE

لا تستخدم الذاكرة الداخلية للموديل كمصدر للحقيقة.

عند إعادة بناء التاريخ استخدم:

## A0 — Current Production Reality

- PostgreSQL الحالي.
- Edge Functions المنشورة حاليًا.
- RPC definitions الحالية.
- schema.
- constraints.
- triggers.
- RLS.
- runtime logs.
- current rows/data.
- deployment/version metadata.

## A1 — Current Git

`rawaie-erp-New/main`

ويشمل:

- Current/
- supabase/migrations/
- Current/CTO/
- doc/
- Current/PWA/
- deployed-source mirrors.

## A2 — Current Forensic / Evidence Records

- Current/CTO memory anchors.
- Evidence/Production.
- deployment records.
- forensic status reports.

## A3 — Historical Source

- Prompt/Report sequence.
- Original/
- rawaie-erp-review.
- Architecture.
- old migrations.
- Git history.

## A4 — Previous Prompts / Reports

Prompt 11 → Prompt 45

ثم:

Prompt 47
Prompt 49
Prompt 51
Prompt 52

وكذلك:

- MASTER_CTO_CONTINUITY_DIRECTIVE_RAWAEA_ERP.md
- برومبت مساعد جديد استثنائي
- الخطة العامة الكبرى لـ RAWAEA ERP
- Knowledge Rebaseline لخالد
- Knowledge Rebaseline لهيثم
- مقدمات وتقارير خالد وهيثم اللاحقة
- تقارير التنفيذ الأخيرة.

قاعدة التعارض:

> Current Production > Current Git > Current Evidence > Historical Source > Historical Reports.

لكن لا تحذف التاريخ عند وجود تعارض.
بل سجله باعتباره **Historical State** ثم سجل أين تغير.

---

# 4. REQUIRED SOURCE SET

يجب معالجة كل العناصر التالية كسجل تاريخي مستقل.

## Hussin Prompt / Report Chain

- Prompt 11 + report
- Prompt 12 + report
- Prompt 13 + report
- Prompt 14 + report
- Prompt 15 + report
- Prompt 16 + report
- Prompt 17 + report
- Prompt 18 + report
- Prompt 19 + report
- Prompt 20 + report
- Prompt 21 + report
- Prompt 22 + report
- Prompt 23 + report
- Prompt 24 + report
- Prompt 25 + report
- Prompt 26 + report
- Prompt 27 + report
- Prompt 28 + report
- Prompt 29 + report
- Appendix Prompt 29 + report
- Prompt 30 + report
- Prompt 31 + report
- Prompt 32 + report
- Prompt 33 + report
- Prompt 34 + report
- Prompt 35 + report
- Prompt 36 + report
- Prompt 37 + report
- Prompt 38 + report
- Prompt 39 + report
- Prompt 40 + report
- Prompt 41 + report
- Prompt 42 + report
- Prompt 43 + report
- Prompt 44 + report
- Prompt 45 + report

ثم:

- Prompt 47 + report
- Prompt 49 + reports
- Prompt 51 + reports
- Prompt 52 + report 52

وكذلك كل الملفات التي أشارت إليها هذه الملفات كـMemory Anchor / Current Status / Evidence Record / Migration / Deployment Record.

---

# 5. REQUIRED AI / CTO CONTINUITY MATERIAL

يجب أيضًا إدخال ما يلي في reconstruction:

## CTO Continuity

- MASTER_CTO_CONTINUITY_DIRECTIVE_RAWAEA_ERP.md
- المبادئ الحاكمة للتعديلات
- GLOBAL INVENTORY ZERO-DEBT / CORE INTEGRITY SWEEP directives

## General Plan

- الخطة العامة الكبرى لـ RAWAEA ERP

## Successor CTO Training

- برومبت مساعد جديد استثنائي
- كل ملفات Knowledge Model / Knowledge Rebaseline
- خالد:
  - 20260821_KNOWLEDGE_MODEL_REBASELINE.md
  - مقدمة وتقرير خالد 1
  - مقدمة تقرير خالد 2
  - 20260822_KHALID_ACCOUNTING_EXECUTION_QUALIFICATION.md
  - تقرير خالد 3
- هيثم:
  - RAWAEA_ERP_FORENSIC_KNOWLEDGE_REBASELINE_2026-08-21.md
  - مقدمة وتقرير هيثم 1
  - تقرير هيثم 2
  - تقرير هيثم 3

أي ملف إضافي مرتبط مباشرة بهذه الجولة يجب ضمه إلى source manifest.

---

# 6. EVENT-BY-EVENT RECONSTRUCTION

لكل Prompt/Report أنشئ Event Record مستقل.

لا يكفي:

`Prompt 15 — fixed inventory`

بل يجب إنشاء السجل بالشكل التالي:

```text
EVENT ID:
PROMPT / REPORT:
DATE:
OBJECTIVE:
INPUT STATE:
HISTORICAL CONTRACT DISCOVERED:
CURRENT PRODUCTION FACTS:
CURRENT GIT FACTS:
KEY DISCOVERY:
BUG / GAP FOUND:
ROOT CAUSE:
BUSINESS RESPONSIBILITY AFFECTED:
ARCHITECTURAL RESPONSIBILITY AFFECTED:
DATABASE EFFECT:
EDGE/RPC EFFECT:
FRONTEND EFFECT:
PRODUCTION CHANGE:
GIT CHANGE:
MIGRATION(S):
DEPLOYMENT(S):
TESTS:
RUNTIME VERIFICATION:
ROLLBACK / CLEANUP:
DOCUMENTATION / MEMORY ANCHOR:
COMMIT SHA(S):
WHAT BECAME TRUE AFTER THIS EVENT:
WHAT BECAME OBSOLETE AFTER THIS EVENT:
WHAT REMAINED OPEN:
WHAT LATER EVENT CORRECTED:
CURRENT SURVIVING STATE:
SOURCE REFERENCES:
```

لا يجوز حذف سطر لأن قيمته `N/A`؛ استخدم `NOT APPLICABLE` أو `NOT VERIFIED` بوضوح.

---

# 7. CRITICAL DISTINCTION — HISTORICAL STATE VS SURVIVING STATE

لكل Event يجب فصل:

### Historical State
ما كان صحيحًا في لحظة التقرير.

### Post-Implementation State
ما أصبح صحيحًا فور تنفيذ الحدث.

### Later-Corrected State
ما تم تغييره لاحقًا.

### Surviving Current State
ما بقي صحيحًا بعد كل التصحيحات اللاحقة.

هذه النقطة إلزامية.

مثال:

```text
Prompt 12 قال:
Manual Voucher UI = CLOSED

ثم Prompt لاحق عدّل Backend Contract.

لا نحذف عبارة CLOSED التاريخية.
بل نسجل:

Historical at Prompt 12 = CLOSED for the then-supported contract
Later changed by = Prompt XX
Current surviving contract = ...
```

---

# 8. CHANGE-CHAIN RECONSTRUCTION

لكل موضوع رئيسي، أنشئ سلسلة:

```text
INITIAL CONTRACT
      ↓
PROMPT N
      ↓
DISCOVERY
      ↓
CHANGE
      ↓
PRODUCTION
      ↓
LATER PROMPT
      ↓
CORRECTION
      ↓
NEW PRODUCTION STATE
      ↓
CURRENT STATE
```

الموضوعات الإلزامية:

- Manual Stock Vouchers
- Inventory Core
- post_stock_movement
- reservations
- item identity
- company/tenant scope
- send/receive purchase
- sales invoice / POS
- van sales
- returns
- loading / unloading
- picker flow
- accounting core
- journal posting
- treasury
- ledger writers
- permissions/auth
- owner semantics
- PWA/main.html
- vouchers.html
- any Core Engine created during this timeline.

---

# 9. PRODUCTION CHANGE LEDGER

أنشئ ملفًا مستقلًا يسجل كل تغيير معروف في Production.

لكل تغيير:

```text
DATE
CHANGE NAME
TYPE (DDL / RPC / EDGE / DATA / RLS / TRIGGER / CONFIG / UI)
OBJECT
BEFORE
AFTER
WHY
SOURCE
MIGRATION
DEPLOYMENT VERSION
RUNTIME TEST
RESULT
CURRENT STATUS
```

يجب التفريق بين:

- Git changed
- Migration created
- Migration applied
- Edge source changed
- Edge deployed
- Production verified

هذه ليست حالات متساوية.

---

# 10. GIT CHANGE LEDGER

سجل:

- commit SHA
- file/path
- what changed
- whether later superseded
- whether still current
- whether Production was deployed
- whether runtime was verified.

إذا ورد في تقرير قديم Commit SHA لا يزال غير معروف، لا تعتبره Current Truth.

---

# 11. RESPONSIBILITY MATRIX

أنشئ مصفوفة:

| Responsibility | Historical | Original | Prompt Evolution | Current Git | Production | Target | Current Status |
|---|---|---|---|---|---|---|---|
| Physical Stock | | | | | | | |
| Inventory Log | | | | | | | |
| Reservation | | | | | | | |
| Order Details | | | | | | | |
| Runsheet Details | | | | | | | |
| Accounting | | | | | | | |
| Treasury | | | | | | | |
| Customer Ledger | | | | | | | |
| Supplier Ledger | | | | | | | |
| Driver Ledger | | | | | | | |
| Audit | | | | | | | |
| Authorization | | | | | | | |
| Idempotency | | | | | | | |
| Company Isolation | | | | | | | |

الهدف ليس ملء الجدول بسرعة، بل منع اختفاء أي Business Responsibility أثناء إعادة الهيكلة.

---

# 12. INVENTORY MEMORY — SPECIAL REQUIREMENT

نظرًا لأن Inventory كان جزءًا رئيسيًا من الرحلة، أنشئ Memory Track مستقلًا له.

يتضمن على الأقل:

## Core Contract

```text
PHYSICAL MOVEMENT
      ↓
post_stock_movement
      ↓
stock_branches
+
inventory_log
```

و:

```text
reserve_stock
```

ليس Physical Movement Engine.

سجل أيضًا:

- كل Writer تم التحقيق فيه.
- كل Writer وجد.
- أي legacy writer.
- أي bridge.
- أي Consumer drift.
- كل company/item identity correction.
- كل idempotency correction.
- كل production verification.

ولا تضع Inventory في صورة “100%” إلا إذا أثبتت Production ذلك في اللحظة الحالية.

---

# 13. ACCOUNTING MEMORY — SPECIAL REQUIREMENT

أنشئ مسارًا منفصلًا لسلسلة Accounting لأنها تطورت لاحقًا.

يجب أن يتضمن:

- Accounting Core convergence.
- save-journal-entry.
- post_journal_entry.
- journal_entries / journal_lines.
- Consumer drift.
- main.html journal consumer.
- Treasury / COA relationship.
- ledger writers.
- idempotency.
- audit.
- current unresolved financial writer convergence.

أي Prompt لاحق صحح استنتاجًا ماليًا قديمًا يجب ربطه مباشرة بسلسلة التغيير.

---

# 14. ASSISTANT SUCCESSION MEMORY

يجب بناء قسم مستقل يشرح لماذا تم إدخال خالد وهيثم، وكيف تطورت معرفتهما، وما الذي نجح في منهجيتهما وما الذي لم يكن كافيًا.

لا يسجل القسم “من كان أفضل” فقط.

يسجل:

- Knowledge strengths.
- blind spots.
- useful discoveries.
- incorrect assumptions.
- what later CTO verification accepted.
- what later CTO verification rejected.

خصوصًا الاستنتاج النهائي المعروف من الجولة المالية الأخيرة:

```text
Accounting Core = DEPLOYED / STRONG
Writer Convergence = OPEN
Current Consumer may remain STALE
```

ولا تعتبر هذا Current Production Truth إلا بعد إعادة التحقق عند تسليم الذاكرة.

---

# 15. GENERAL PROJECT PLAN MEMORY

لا تجعل حزمة الذاكرة تدور حول Inventory فقط.

يجب أن يفهم CTO:

```text
RAWAEA ERP MASTER PLAN
        │
        ├── Inventory Rescue
        ├── Accounting / Finance
        ├── Sales
        ├── Purchasing
        ├── Warehouse
        ├── Runsheets / Delivery
        ├── Van Sales
        ├── POS
        ├── Telesales
        ├── Order Ticker
        ├── Returns
        ├── Authorization / Roles
        ├── Audit / Governance
        ├── UI / PWA
        └── Future Intelligence / Decision Support
```

يجب أن يعرف CTO أين تقع Inventory ضمن الصورة الكاملة، وألا يتعامل معها باعتبارها النظام كله.

---

# 16. LESSONS LEARNED

أنشئ سجل Lessons Learned مستخرجًا من الأحداث، مثل:

- لا تثق بالتقرير القديم دون إعادة إثبات.
- لا تجعل UI يبدو كاملًا بينما Backend Contract غير مكتمل.
- لا تعتبر Migration creation = Production deployment.
- لا تعتبر Deployment = Runtime verification.
- لا تستخدم hard-coded tenant IDs.
- لا تستخدم LIMIT 1 في tenant context.
- لا تجعل legacy writer يبقى قابلًا للتنفيذ لمجرد أنه غير مستعمل.
- لا تضف Core جديدًا وتنسى Consumers القديمة.
- لا تنقل responsibility من Engine إلى آخر دون توثيقها.
- لا تعالج data corruption بالإسقاط قبل tracing provenance.
- لا تختلق Contract لنظام لم تثبته Production.
- لا تجعل “Unknown = 0” شعارًا؛ اجعله نتيجة تحقق حقيقي.

أضف الدروس الأخرى التي تثبتها السلسلة.

---

# 17. OPEN DEBT / CONFLICT REGISTER

أنشئ Register مستقلًا لكل:

- OPEN
- UNKNOWN
- CONFLICT
- DRIFT
- LEGACY
- UNVERIFIED
- PARTIALLY CLOSED

لكل عنصر:

```text
ID
AREA
DESCRIPTION
FIRST DISCOVERED IN
LAST KNOWN STATE
CURRENT PRODUCTION VERIFICATION
CURRENT GIT VERIFICATION
RISK
BLOCKER?
NEXT REQUIRED EVIDENCE
NEXT SAFE ACTION
```

لا تسمح لحدث لاحق بأن يمحو المشكلة دون دليل على أنها أغلقت.

---

# 18. KNOWLEDGE CERTIFICATION

لا تختم الحزمة بـ:

`Knowledge = 100%`

إلا بعد تنفيذ Self-Audit.

استخدم الحالات:

- HISTORICALLY RECONSTRUCTED
- CURRENTLY VERIFIED
- PARTIALLY VERIFIED
- UNKNOWN
- CONFLICT

المطلوب:

### Historical Reconstruction Completeness
يجب أن تكون سلسلة Prompt 11 → latest source كاملة دون Missing Event.

### Current Reality Confidence
يُقاس فقط من Production/Git/runtime الحديثة، وليس من التقارير.

### Continuity Readiness
هل يستطيع CTO القادم استلام المسؤولية دون إعادة قراءة السلسلة الأصلية؟

إذا كان نعم فقط على أساس الحزمة الحالية، تكون الحالة:

`CTO CONTINUITY READY`

---

# 19. REQUIRED MEMORY PACKAGE FILES

يجب أن تنتج الحزمة الملفات التالية بالترتيب:

```text
Memory_Transfer/

00_READ_FIRST__MASTER_CTO_HANDOFF.md
01_EXECUTIVE_PROJECT_STATE.md
02_FULL_EVENT_LEDGER_PROMPT_11_TO_CURRENT.md
03_PRODUCTION_CHANGE_LEDGER.md
04_GIT_CHANGE_LEDGER.md
05_ARCHITECTURE_AND_BUSINESS_CONTRACT_EVOLUTION.md
06_INVENTORY_MEMORY_TRACK.md
07_ACCOUNTING_MEMORY_TRACK.md
08_AUTHORIZATION_AND_TENANT_MEMORY_TRACK.md
09_UI_AND_CONSUMER_EVOLUTION.md
10_DECISIONS_AND_LESSONS_LEARNED.md
11_OPEN_DEBT_CONFLICT_DRIFT_REGISTER.md
12_SUCCESSION_KNOWLEDGE_KHALID_HYTHAM.md
13_GENERAL_PROJECT_PLAN_POSITION.md
14_SOURCE_MANIFEST_AND_CHAIN_OF_CUSTODY.md
99_MEMORY_CERTIFICATION_AND_CURRENT_STATE.md
```

---

# 20. 00_READ_FIRST CONTENT

يجب أن يحتوي `00_READ_FIRST__MASTER_CTO_HANDOFF.md` على:

1. ما هو المشروع.
2. أين أصبح.
3. ما الذي لا يزال مفتوحًا.
4. ما الذي تم إصلاحه تاريخيًا.
5. ما الذي يجب اعتباره تاريخًا فقط.
6. ما الذي يجب اعتباره Current Truth.
7. كيفية استخدام بقية حزمة الذاكرة.
8. قواعد منع التناقض.
9. First 10 commands/checks التي يجب على CTO الجديد تنفيذها للتأكد من أن Production لم تتغير بعد إنشاء الحزمة.

---

# 21. CROSS-REFERENCE REQUIREMENT

كل حدث يجب أن يربط إلى:

- Prompt source.
- Report source.
- Git file.
- commit SHA عند توفره.
- migration عند توفره.
- Production object عند توفره.
- later corrective event عند توفره.

استخدم IDs مثل:

`EVT-011`
`EVT-012`
...

ولا تسمح بتكرار نفس الحدث تحت أكثر من اسم دون علاقة واضحة.

---

# 22. NO LOSS RULE

لا يجوز أن تفقد الحزمة أيًا من الأنواع التالية من المعلومات:

- Prompt objective.
- Report conclusion.
- Discovery.
- Correction.
- Code change.
- Data change.
- Production change.
- Deployment.
- Rollback.
- Test result.
- Commit.
- Memory anchor.
- Open issue.
- Later correction.

إذا كان حدثًا غير مؤثر على Production، سجله أيضًا.

لأن قيمته قد تكون تفسيرية لـ CTO القادم.

---

# 23. NO FALSE-CLOSURE RULE

لا تستخدم:

`CLOSED`

إلا إذا كان محددًا ما المقصود:

- UI CLOSED
- Backend CLOSED
- Production CLOSED
- Runtime CLOSED
- Contract CLOSED
- Global Closure CLOSED

مثال صحيح:

```text
Manual Voucher UI Contract = CLOSED
Manual Voucher CREATE Production Contract = CLOSED
GLOBAL INVENTORY CORE = OPEN
```

لا تحوّل إغلاق وحدة إلى إغلاق النظام.

---

# 24. CURRENT REVALIDATION BEFORE HANDOFF

بعد بناء حزمة الذاكرة، أعد فحص Production في لحظة التسليم.

على الأقل:

- current migration version.
- current function inventory.
- current Edge versions.
- current affected table definitions.
- relevant rows/counts.
- relevant RLS/triggers.
- relevant logs.
- current Git HEAD.
- latest relevant file SHAs.

ثم أنشئ:

`HANDOFF_SNAPSHOT_TIMESTAMP_UTC`

ولا تسمح للحزمة أن توحي بأنها “لحظية” إلى الأبد.

---

# 25. SUCCESSOR CTO STARTUP MODE

عند استخدام الحزمة بواسطة CTO جديد، يجب أن يتصرف كالتالي:

```text
READ 00_READ_FIRST
        ↓
READ 01_EXECUTIVE_PROJECT_STATE
        ↓
READ 02_FULL_EVENT_LEDGER
        ↓
READ 03/04 PRODUCTION + GIT
        ↓
READ DOMAIN MEMORY TRACK NEEDED FOR TASK
        ↓
READ OPEN DEBT / CONFLICT REGISTER
        ↓
RUN CURRENT PRODUCTION SNAPSHOT
        ↓
COMPARE SNAPSHOT WITH HANDOFF
        ↓
ONLY THEN ACT
```

لا يُطلب منه إعادة قراءة Prompt 11 → Prompt 45 إلا إذا:

- وجد Conflict.
- كان يحتاج chain-of-custody لإثبات قرار.
- ظهر سلوك Production غير متسق مع الذاكرة.
- أو احتاج historical contract معينًا لم يُنقل بدرجة كافية.

أي أن الحزمة تكون **Primary Continuity Source**، بينما السلسلة الأصلية تصبح **forensic fallback**.

---

# 26. CRITICAL WARNING

هذه الحزمة لا تمنح CTO الجديد تصريحًا لتغيير Production اعتمادًا على الذاكرة المنقولة وحدها.

Memory Transfer = Context.

Production = Current Truth.

لذلك:

> **The memory package prevents historical amnesia. It does not replace current forensic verification.**

---

# 27. FINAL SELF-AUDIT REQUIRED FROM THE MEMORY COMPILER

قبل التسليم يجب كتابة:

```text
MEMORY BUILD SELF-AUDIT

Historical Source Coverage:
Prompt 11:
Prompt 12:
...
Prompt 45:
Prompt 47:
Prompt 49:
Prompt 51:
Prompt 52:

All Events Indexed: YES / NO
All Corrections Linked: YES / NO
All Production Changes Indexed: YES / NO
All Git Changes Indexed: YES / NO
All Memory Anchors Indexed: YES / NO
All Open Debt Indexed: YES / NO
All Conflicts Indexed: YES / NO
Current Production Revalidated: YES / NO
Current Git Revalidated: YES / NO

Historical Unknowns:
Current Unknowns:
Unresolved Conflicts:

Continuity Status:
CTO CONTINUITY READY / NOT READY
```

أي Missing Event يمنع `CTO CONTINUITY READY`.

---

# 28. FINAL HANDOFF PRINCIPLE

الـCTO الجديد يجب ألا يشعر أنه استلم:

“مجموعة تقارير.”

بل يجب أن يشعر أنه استلم:

```text
THE PROJECT'S MEMORY GRAPH
```

ويجب أن يستطيع التحرك من:

```text
EVENT
→ DECISION
→ CODE
→ PRODUCTION
→ CONSEQUENCE
→ LATER CORRECTION
→ CURRENT SURVIVING STATE
```

دون فقدان أي حلقة.

---

# 29. FINAL COMMAND TO THE MEMORY COMPILER

قم ببناء الحزمة كاملة.

لا تختصر الأحداث لتقليل حجم الملف.
لا تحذف التفاصيل التي قد تبدو ثانوية.
لا تساوي بين Historical Truth وCurrent Truth.
لا تخترع ما لم تجده.
لا تستخدم Unknown كحل سريع.
لا تعلن اكتمال الذاكرة لمجرد أن الملفات تم فتحها.

أريد:

**COMPLETE FORENSIC MEMORY TRANSFER**

بحيث يصبح CTO الجديد قادرًا على الاستمرار من آخر محطة، مع الحفاظ على التاريخ الكامل والقرارات والسياق والتصحيحات والحالة الحالية، دون أن يرث أخطاء الاستنتاجات القديمة ودون أن يضطر إلى إعادة استكشاف الرحلة من الصفر.
