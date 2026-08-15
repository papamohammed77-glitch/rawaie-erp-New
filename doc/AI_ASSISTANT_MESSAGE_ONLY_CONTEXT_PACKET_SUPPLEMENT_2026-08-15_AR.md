# RAWAEA ERP — الحزمة العربية المكملة لتهيئة مساعد الرسائل الداخلية

**التاريخ:** 2026-08-15  
**الغرض:** استكمال حزمة `AI_ASSISTANT_MESSAGE_ONLY_CONTEXT_PACKET_2026-08-15.md` لمساعد ذكاء اصطناعي جديد يعمل حصريًا من خلال الرسائل والملفات التي يرسلها المالك، **دون وصول مباشر إلى GitHub أو Supabase أو PostgreSQL أو الويب**.

> هذه الوثيقة **لا تستبدل** الحزمة الأصلية؛ إنها تكملها وتسد الفجوات التي قد تجعل مساعدًا جديدًا يكرر أخطاء منهجية أو تنفيذية سابقة.

---

# 1. أهم ما كان ناقصًا في الحزمة الأصلية

الحزمة الأصلية كانت قوية في عرض السياق العام، لكنها كانت تحتاج إلى طبقة تنفيذية إضافية توضح للمساعد الجديد، بدون أي استعلام خارجي:

1. **الحالة التنفيذية الأخيرة لكل Closure Unit**، وليس فقط قائمة الدوال.
2. الفرق بين:
   - Historical
   - Original
   - Current
   - Production
   - Target
   - Production Runtime Verified
3. أن بعض التقارير القديمة أصبحت **Stale** ولا يجوز استخدامها كحقيقة حالية.
4. العيوب التي تم اكتشافها **بعد** تقارير سابقة، وخاصة عيب `start-picking` الذي ظهر عمليًا من النظام.
5. أين وصل **Inventory Rescue** على مستوى Core المركزي، وما الذي بقي مفتوحًا.
6. أن `complete-loading` و`complete-picking` أصبحا Edge adapters بينما الـBusiness Core انتقل إلى PostgreSQL.
7. أن وجود إصلاح في `Current` لا يعني أنه منشور في Production، والعكس صحيح.
8. أن بعض الإصلاحات المنشورة ما زال لها **Source-of-Truth alignment** أو Governance cleanup مفتوح.
9. أن المساعد الجديد يعمل في بيئة **Message-Only**؛ لذلك لا يجوز له الادعاء بأنه نفذ نشرًا أو اختبارًا لمجرد وجوده في الوثائق.
10. ضرورة وجود **Self-Audit في مقدمة التقرير ونهايته**.

---

# 2. قاعدة الحقيقة الخاصة بالمساعد الجديد

بما أن المساعد لا يملك وصولًا مباشرًا إلى النظام، يجب أن يصنف كل معلومة في رده إلى واحدة من الحالات التالية:

- **مؤكد من ملف/لقطة Evidence أرسلها المالك.**
- **مذكور في تقرير تاريخي.**
- **Target/Design فقط.**
- **استنتاج منطقي.**
- **مجهول.**
- **متعارض بين مصدرين.**

ولا يجوز أبدًا تحويل:

`Historical → Confirmed Production`

أو:

`Current → Production`

أو:

`Staging → Production`

أو:

`Report → Execution Evidence`

بدون دليل صريح.

---

# 3. هرم الحقيقة الإلزامي

عند العمل من الرسائل فقط، الترتيب:

1. **أحدث Production Evidence يرسله المالك.**
2. تعريفات PostgreSQL/RPC المنشورة التي يرسلها المالك.
3. تعريفات Edge Functions المنشورة التي يرسلها المالك.
4. Current source الذي يرسله المالك.
5. Application source الذي يرسله المالك.
6. Architecture Constitution / ADRs.
7. Historical reports.
8. Unreleased migrations.

عند التعارض: **لا تختَر من نفسك**؛ سجل التعارض واطلب/انتظر أحدث Evidence.

---

# 4. ترتيب القراءة المكمل الإلزامي

يجب أن يطلب المساعد من المالك توفير هذه الملفات/المحتويات بالترتيب إذا لم تكن ضمن الرسالة:

## المستوى A — السلطة المعمارية

1. `CTO/00_MASTER_CONTEXT.md`
2. `CTO/01_SOURCE_AUTHORITY_MAP.md`
3. `Governance/RAWAEA_ARCHITECTURE_CONSTITUTION.md`
4. `Governance/EXECUTION_PROTOCOL.md`
5. `Architecture/EXECUTION_GUARDRAILS.md`
6. `Architecture/DOMAIN_EXECUTION_ORDER.md`
7. `Architecture/INV-001 — INVENTORY REALITY MAP.md`

## المستوى B — خط الإنقاذ التنفيذي

8. `doc/خطة تنفيذية مرحلية - المرحلة الأولي المجزئة.md`
9. `CTO/MASTER-EXECUTION-LOG.md`
10. `CTO/02_EXECUTION_LOG.md`
11. `CTO/03_CURRENT_STATUS.md`
12. `CTO/05_TRUTH_RECONCILIATION.md`
13. `CTO/RESCUE-RECONCILIATION-2026-08-15.md`
14. `CTO/02_HISTORICAL_KNOWLEDGE_INDEX.md`
15. `CTO/04_PROJECT_SOURCE_INVENTORY.md`

## المستوى C — التاريخ والنسخ الأصلية

16. `Edge_Function_Reports/_HISTORICAL/RAWAEA ERP HANDOVER.md`
17. `Edge_Function_Reports/_HISTORICAL/Batch01.md` … `Batch15.md`
18. `rawaie-erp-review/Edge_Functions/original/`
19. `rawaie-erp-review/Edge_Functions/current/`
20. `rawaie-erp-review/Edge_Functions/archive/`

> **مهم:** إذا لم توجد الدالة في `rawaie-erp-New/Original` فهذا لا يعني أنها غير موجودة؛ يجب البحث في المستودع التاريخي `rawaie-erp-review/Edge_Functions/original/` وفي تاريخ الـGit الذي يرسله المالك.

## المستوى D — Database Evidence

21. `SQL_Evidence/schema/tables.csv`
22. `SQL_Evidence/schema/Foreign Keys.csv`
23. `SQL_Evidence/schema/Indexes.csv`
24. `SQL_Evidence/schema/Primary Keys.csv`
25. `SQL_Evidence/schema/Enum Types.csv`
26. `SQL_Evidence/schema/Database Functions.csv`
27. `SQL_Evidence/schema/استعلام RLS Policies.csv`
28. `SQL_Evidence/diagnostics/`

## المستوى E — التطبيق والمستهلكون

29. `PWA/main.html`
30. `PWA/core.js`
31. `PWA/warehouse/picker.html`
32. `PWA/warehouse/loader.html`
33. `PWA/warehouse/receiver.html`
34. `PWA/warehouse/unloader.html`
35. `PWA/warehouse/returns.html`
36. `PWA/warehouse/vouchers.html`
37. `PWA/sales/van-sales.html`
38. `PWA/sales/pos.html`
39. `PWA/sales/telesales.html`
40. `PWA/delivery/driver.html`

## المستوى F — مصدر التطوير

41. `Current/Edge_Functions/`
42. `Current/PWA/`
43. `supabase/migrations/`

---

# 5. أحدث صورة تنفيذية معروفة في الحزمة

هذه ليست Live Access؛ إنها **آخر Evidence موثقة داخل المستودع** ويجب اعتبارها لقطة مؤرخة.

## `complete-picking`

**الحالة المسجلة:** `100% CLOSED — PRODUCTION RUNTIME VERIFIED`

الطبقات:

`complete-picking`
→ `complete_runsheet_picking`
→ `reserve_stock`
→ `order_details`
→ trigger `sync_run_sheet_details`
→ `runsheet = Picked`

العقد:

- Picking = Reservation.
- Physical `qty` لا يتغير.
- `allocated_qty` يزيد.
- لا يوجد Picking movement في `inventory_log`.
- `run_sheet_details` مشتق وليس مصدر الحقيقة.

**تنبيه:** عند وصول Evidence أحدث من المالك، قد تتغير هذه الحالة.

## `start-picking`

**آخر وضع معروف:** Production **v14 ACTIVE**، وتم إصلاح عيب حقيقي ظهر للمستخدم أثناء تجربة التطبيق:

`users_email_key` duplicate

السبب:

- كانت الشركة تستخرج من `app_settings.limit(1)`.
- البحث عن المستخدم كان `email + company_id`.
- عند فشل البحث داخل الشركة كان يحاول إنشاء `public.users`.
- قيد `users_email_key` العالمي كان يرفض الإدخال.

الحل المنشور:

`JWT auth.users.id`
→ `public.users.id`
→ `public.users.company_id`
→ `company-scoped runsheet`

مع إزالة إنشاء المستخدم التلقائي من Start Picking.

**مهم:** `picker.html` لم يُعدل لهذا الإصلاح؛ consumer contract بقي:

`POST /functions/v1/start-picking`

```json
{"runsheet_code":"..."}
```

## `complete-loading`

**آخر وضع معروف:** Production **v10 ACTIVE**.

`complete-loading` Edge أصبحت Thin Wrapper.

الـBusiness Logic المقصودة:

`complete_runsheet_loading`
→ `post_stock_movement`
→ `stock_branches + inventory_log`

Loading = `MAIN → VAN`.

Reopen = عكس Loading ثم دورة Loading جديدة.

Unloading = `VAN → MAIN`.

والـLoading ليس COGS بذاته.

## `send-stock-voucher`

**Production:** v7 معروف كـthin adapter مرتبط بـ`send_stock_voucher_atomic` ثم `post_stock_movement`.

**Current:** تم تسجيل patch لمحاذاة Current مع الـProduction adapter في rescue branch، لكن هذا لا يعني تلقائيًا أنه merged إلى `main` أو أنه Production deployment جديد.

هذه نقطة يجب عدم خلطها.

---

# 6. ما الذي تم تحقيقه فعليًا على مستوى Inventory Rescue

## أ. Central Physical Stock Boundary

المبدأ التنفيذي:

`post_stock_movement`

هو **Central Physical Stock Movement Engine**.

المسؤوليات التي يجب أن تبقى فيه:

- تعديل Physical `qty`.
- Inventory log.
- Movement validation.
- Idempotency.
- Locking/atomicity.
- Company/branch/item context بحسب العقد.

## ب. Reservation Boundary

`reserve_stock` منفصل عن Physical Movement.

Picking لا يعني خصم Physical `qty`.

## ج. Source of Truth

`order_details` = authoritative fulfillment quantity layer.

`run_sheet_details` = derived aggregate عبر trigger.

## د. Loading / Unloading

تم بناء Core لدعم:

- Loading MAIN → VAN.
- Reopen Loading = VAN → MAIN ثم Cycle جديدة.
- Reload باستخدام Cycle identity الجديدة.
- Unloading VAN → MAIN.
- event-level idempotency.
- rollback.
- backorder reconciliation.

## هـ. Manual Voucher Centralization

الأعمال المعالجة في rescue stream تضمنت إعادة توجيه المسارات الرئيسية إلى الـCentral Stock Engine، بما فيها SEND وبعض مسارات RECEIVE/Purchase/Adjustment/Sales/Return/Delivery بحسب آخر Evidence.

**لكن Global Inventory Release ليس بالضرورة مغلقًا 100% بمجرد وجود هذه الدوال في Production؛ يجب الاعتماد على آخر Reality Matrix يرسله المالك.**

---

# 7. قائمة Zero-Debt الحالية

آخر ترتيب موثق:

1. `complete-picking` — مغلق بحسب آخر reconciliation موثق.
2. `send-stock-voucher` — patched / review + verification.
3. `receive-stock-voucher`.
4. `receive-purchase`.
5. `bulk-stock-adjustment`.
6. `save-sales-invoice`.
7. `complete-return`.
8. `complete-order-delivery`.
9. `GLOBAL PHYSICAL STOCK WRITER SWEEP`.
10. بعد إغلاق Inventory فقط: Accounting.
11. ثم Ledger.
12. ثم بقية Domains حسب `DOMAIN_EXECUTION_ORDER`.

**المساعد الجديد ممنوع من القفز إلى الوحدة التالية قبل إغلاق الوحدة الحالية 100%، إلا إذا أصدر المالك أمرًا صريحًا بغير ذلك.**

---

# 8. أخطر عيوب/دروس تنفيذية يجب معرفتها من البداية

## العيب 1 — Duplicate users email

هذه كانت مشكلة حقيقية ظهرت من النظام نفسه.

القاعدة الجديدة:

لا تنشئ `public.users` داخل Start Picking لمجرد أن lookup داخل الشركة فشل.

## العيب 2 — Distributed Business Logic

كان كل Edge Function تقريبًا يتصرف كمحرك أعمال مستقل للمخزون.

الخطة الحالية:

Edge = Capability Adapter.

PostgreSQL Core = Business Engine.

## العيب 3 — Source-of-Truth Drift

تم اكتشاف أن نسخة Production قد تكون صحيحة بينما `Current` لا تمثلها، أو العكس.

لذلك كل closure يجب أن يثبت:

Current artifact + Production artifact + Core state + Consumer contract.

## العيب 4 — Staging/Production confusion

Staging success لا يعني Production success.

## العيب 5 — Harness Governance

`ACTIVE + 410 Stub != DELETED`.

وجود temporary test Edge Functions في registry يجب أن يظهر صراحة كـGovernance debt حتى يتم حذفها أو اعتماد إجراء موثق من المالك.

## العيب 6 — false closure

لا:

`Report = Execution`

ولا:

`PASS = 100%`

إذا بقي أي بوابة غير مثبتة.

---

# 9. بروتوكول رسالة-فقط للمساعد الجديد

المساعد الجديد **لا يملك GitHub/Supabase/ويب**. لذلك:

### لا يقول:

- "راجعت Production".
- "نفذت Migration".
- "نشرت Function".
- "اختبرت Runtime".

إلا إذا أرسل له المالك **Evidence نصية/ملفية مباشرة** تثبت ذلك.

### عند نقص مصدر

يطلب من المالك:

- الملف.
- تعريف RPC.
- تعريف Edge Function المنشورة.
- نتيجة SQL.
- log.
- screenshot.
- commit SHA.

ويحدد بالضبط **أي Evidence ناقصة ولماذا**.

### عند وجود تعارض

يكتب:

`CONFLICT`

ثم يحدد المصدرين ويبيّن أيهما أحدث.

---

# 10. Self-Audit الإلزامي

## في مقدمة كل تقرير

```text
SELF-AUDIT
Business Understanding:
Architecture Understanding:
Database Understanding:
Historical Understanding:
Production Understanding:
Current Understanding:
Execution Confidence:

Confirmed Facts:
Unknowns:
Conflicts:
Unverified Claims:
```

ثم:

```text
Historical Opened:
Original Opened:
Production Evidence Received:
Current Opened:
Schema Checked:
Triggers Checked:
Dependencies Checked:
Consumers Checked:
```

## في نهاية كل تقرير

```text
SELF-AUDIT FINAL
What I Proved
What I Did Not Prove
What I Fixed
What I Initially Missed
What Could Still Be Wrong
Final Confidence
Final Closure Status
```

ويجب ألا تتجاوز درجة الثقة ما تسمح به الأدلة.

---

# 11. كيف يعمل المساعد الجديد عمليًا

عند استلام Closure Unit جديدة:

1. يقرأ هذه الحزمة.
2. يقرأ الحزمة الأصلية.
3. يحدد المطلوب بالضبط.
4. يطلب فقط الملفات الضرورية للوحدة الحالية، لا مشروع الكون كله.
5. يعقد Pre-Change Self-Audit.
6. يقارن Original/Historical/Current/Production evidence المرسلة.
7. يحدد الوظائف التي ستبقى/تنقل/تضاف/تحذف عمدًا.
8. يقدم Target Contract للجراحة.
9. بعد موافقة المالك ينفذ/يدير التعديل عبر ما يمكن من بيئة الرسائل.
10. يختبر الأدلة التي يمكنه اختبارها من الملفات المرسلة.
11. يعطي Final Closure Report.
12. لا يفتح الوحدة التالية قبل إغلاق الحالية 100%.

---

# 12. تعريف 100% لمساعد الرسائل الداخلية

في Message-Only mode، لا يمكن للمساعد أن يثبت Deployment/Production Runtime بنفسه بدون Evidence من المالك.

لذلك توجد حالتان مختلفتان:

### 100% هندسي من حيث الملفات والتحليل

ممكن إذا كانت جميع المصادر والنسخ والـConsumers والـCore evidence متوفرة.

### 100% Production Runtime

لا يكتبها المساعد إلا بعد أن يقدم المالك Evidence تشغيلية مباشرة.

هذا التفريق أساسي حتى لا نكرر مشكلة التقارير البراقة التي سبقت.

---

# 13. ملف الإنذار السلوكي

يجب قراءة ملف:

`Architecture/سجل التحذيرات الرئيسي – نظام الإنذار المبكر للمساعدين المستقبليين.md`

(أو مساره الحالي إذا تغير) قبل بدء أي Closure Unit.

الهدف: منع تكرار السلوكيات السابقة مثل:

- التوقف غير الضروري.
- الادعاءات غير المثبتة.
- الخلط بين Current وProduction.
- تجاهل المصادر التاريخية المتاحة.
- فتح مهام كثيرة دفعة واحدة.
- اعتبار Governance gap سببًا لتجميد بقية التنفيذ الممكن.

---

# 14. الخلاصة التنفيذية التي يجب أن يعرفها المساعد الجديد

هذا المشروع **ليس مشروع إعادة كتابة ERP من الصفر**.

إنه مشروع:

`Reality Reconciliation`
→ `Inventory Core Rescue`
→ `Controlled Surgical Refactor`
→ `Production Verification`
→ `Zero-Debt Closure`
→ ثم بقية Domains.

الهدف المعماري:

# ONE CORE
# ONE SOURCE OF TRUTH
# SURGICAL CHANGE
# ZERO DEBT
# NO FALSE CLOSURE

والقاعدة التنفيذية النهائية:

> **قطعة واحدة تُفهم بالكامل، تُصلح بالكامل، تُثبت بالكامل، ثم ننتقل للقطعة التالية.**

**لا نطارد عشر مشاكل في وقت واحد، ولا نترك مشكلة مفتوحة بحجة الانشغال بمشكلة أخرى.**
