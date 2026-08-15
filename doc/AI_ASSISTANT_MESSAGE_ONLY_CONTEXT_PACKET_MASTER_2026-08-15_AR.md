# RAWAEA ERP — حزمة السياق الرئيسية لمساعد الرسائل الداخلية

**التاريخ:** 2026-08-15
**نوع الحزمة:** MASTER / MESSAGE-ONLY
**الغرض:** تهيئة مساعد ذكاء اصطناعي جديد يعمل حصريًا عبر الرسائل والملفات التي يرسلها المالك، دون وصول مباشر إلى GitHub أو Supabase أو PostgreSQL أو الويب.

---

# 0. مبدأ الحزمة

هذه الوثيقة هي **النسخة الموحّدة** من:

- `doc/AI_ASSISTANT_MESSAGE_ONLY_CONTEXT_PACKET_2026-08-15.md`
- `doc/AI_ASSISTANT_MESSAGE_ONLY_CONTEXT_PACKET_SUPPLEMENT_2026-08-15_AR.md`

وقد أضيف إليها ما ثبت من التجربة التنفيذية أثناء إنقاذ Inventory، خاصة مشكلات:

- الخلط بين Current وProduction.
- إعلان الإغلاق قبل اكتمال الأدلة.
- إضاعة الوقت في Blocks كان يمكن حلها بالبحث أو بوسيلة اختبار بديلة.
- اعتبار Stub/Inert مساويًا لـDeleted.
- عدم العثور على نسخة أصلية رغم وجودها في المستودع التاريخي.
- ظهور Defect حقيقي من الاستخدام الفعلي للتطبيق، مثل مشكلة `users_email_key` في `start-picking`.
- الحاجة إلى فصل artifact عن business Core state.
- ضرورة العمل بوحدات Closure صغيرة وعدم معالجة المشروع كله دفعة واحدة.

**مهم:** المساعد في Message-Only mode لا يملك وصولًا مباشرًا إلى النظام. لذلك لا يجوز له الادعاء بأنه تحقّق من Production أو نفّذ نشرًا أو Runtime Test ما لم يقدم المالك Evidence مباشرة تثبت ذلك.

---

# 1. هوية المشروع والرؤية

**المشروع:** RAWAEA ERP / الروائع ERP

**النطاق:** ERP/WMS/Distribution لنشاط FMCG وتوزيع البضائع.

**الرؤية:** بناء نظام مؤسسي قابل للتوسع والمقارنة مع الأنظمة الناضجة، دون إعادة اختراع المنطق المحاسبي أو المخزني الثابت من الصفر عندما توجد نماذج صناعية مستقرة.

الهدف ليس مجرد إصلاح أخطاء منفردة، بل تحويل النظام من نموذج **Distributed Business Logic** إلى بنية مركزية يمكن التحكم فيها لسنوات طويلة.

---

# 2. السلطة المعمارية

ترتيب القراءة الإلزامي قبل أي Closure Unit:

1. `CTO/00_MASTER_CONTEXT.md`
2. `CTO/01_SOURCE_AUTHORITY_MAP.md`
3. `Governance/RAWAEA_ARCHITECTURE_CONSTITUTION.md`
4. `Governance/EXECUTION_PROTOCOL.md`
5. `Architecture/EXECUTION_GUARDRAILS.md` إن كان موجودًا.
6. `Architecture/DOMAIN_EXECUTION_ORDER.md` إن كان موجودًا.
7. `Architecture/INV-001 — INVENTORY REALITY MAP.md` إن كان موجودًا.
8. `doc/CTO VISION REPORT.md`
9. `doc/CTO RECONSTRUCTION REPORT.md`
10. `doc/تقرير CTO الشامل.md`

هذه الملفات تعرّف:

- ONE CORE / ONE SOURCE OF TRUTH.
- حدود مسؤوليات Edge مقابل PostgreSQL Core.
- ترتيب الإصلاح.
- حدود التغيير المسموح.
- رؤية المالك طويلة المدى.

---

# 3. الخطة التنفيذية الكلية

1. `doc/خطة تنفيذية مرحلية - المرحلة الأولي المجزئة.md`
2. `CTO/MASTER-EXECUTION-LOG.md`
3. `CTO/02_EXECUTION_LOG.md`
4. `CTO/03_CURRENT_STATUS.md`
5. `CTO/05_TRUTH_RECONCILIATION.md`
6. `CTO/RESCUE-RECONCILIATION-2026-08-15.md`
7. `CTO/02_HISTORICAL_KNOWLEDGE_INDEX.md`
8. `CTO/04_PROJECT_SOURCE_INVENTORY.md`

**قاعدة:** الوثائق المؤرخة snapshots وليست Production truth أبدية. عند التعارض، Evidence الأحدث والأكثر مباشرة هو الأعلى.

---

# 4. هرم الحقيقة في Message-Only Mode

صنّف كل معلومة إلى:

1. **مؤكد من Evidence مباشر أرسله المالك.**
2. **مؤكد من ملف مصدر أرسله المالك.**
3. **Historical / Legacy evidence.**
4. **Current source.**
5. **Target / Design فقط.**
6. **استنتاج منطقي.**
7. **مجهول.**
8. **متعارض.**

ممنوع تحويل `Historical → Production` أو `Current → Production` أو `Staging → Production` أو `Report → Execution` بدون Evidence صريح.

---

# 5. أماكن النسخ الأصلية ومصادر الاسترجاع

إذا لم توجد Function في `rawaie-erp-New/Original` فهذا **ليس دليلًا على عدم وجودها**.

يجب البحث في:

### Historical repository
`papamohammed77-glitch/rawaie-erp-review/Edge_Functions/`

ويحتوي على:

- `Edge_Functions/original/`
- `Edge_Functions/current/`
- `Edge_Functions/archive/`

الرابط المرجعي:
`https://github.com/papamohammed77-glitch/rawaie-erp-review/tree/rescue/manual-vouchers-inventory-core/Edge_Functions`

### داخل rawaie-erp-New

- `Original/`
- `Current/`
- `supabase/migrations/`
- `SQL_Evidence/`
- `Edge_Function_Reports/_HISTORICAL/`
- Git history / commits التي يرسلها المالك.

**المساعد مسؤول عن طلب/العثور على المصدر الناقص، لا الانتظار بلا سبب.**

---

# 6. التاريخ والوثائق المرجعية

- `Edge_Function_Reports/_HISTORICAL/RAWAEA ERP HANDOVER.md`
- `Edge_Function_Reports/_HISTORICAL/INV-001 — INVENTORY REALITY MAP.md` إن كان موجودًا.
- `Edge_Function_Reports/_HISTORICAL/INV-002 — INVENTORY SOURCE OF TRUTH.md` إن كان موجودًا.
- `Edge_Function_Reports/_HISTORICAL/Batch01.md` … `Batch15.md`

هذه الملفات تشرح المسؤوليات التاريخية، الاعتماديات، أسباب الأخطاء، وسياق القرارات القديمة.

---

# 7. Database Evidence

الحد الأدنى:

- `SQL_Evidence/schema/tables.csv`
- `SQL_Evidence/schema/Foreign Keys.csv`
- `SQL_Evidence/schema/Indexes.csv`
- `SQL_Evidence/schema/Primary Keys.csv`
- `SQL_Evidence/schema/Enum Types.csv`
- `SQL_Evidence/schema/Database Functions.csv`
- `SQL_Evidence/schema/استعلام RLS Policies.csv`
- `SQL_Evidence/diagnostics/`
- migrations ذات الصلة.

**قاعدة:** migration غير منشورة ليست Production truth.

---

# 8. التطبيقات والمستهلكون

### Current
`Current/PWA/`

الأهم حسب المجال:

- `PWA/main.html`
- `PWA/core.js`
- `PWA/warehouse/picker.html`
- `PWA/warehouse/loader.html`
- `PWA/warehouse/receiver.html`
- `PWA/warehouse/unloader.html`
- `PWA/warehouse/returns.html`
- `PWA/warehouse/vouchers.html`
- `PWA/sales/van-sales.html`
- `PWA/sales/pos.html`
- `PWA/sales/telesales.html`
- `PWA/delivery/driver.html`

### Current Edge source
`Current/Edge_Functions/`

هذا هو المسار الرسمي للنسخ النهائية المعتمدة. لا تنشئ repositories جديدة أو نسخًا متكررة لنفس Function بلا قرار صريح.

---

# 9. خريطة Inventory Rescue — العقد الثابتة

## 9.1 Physical Stock Movement

`post_stock_movement` هو **المحرك المركزي الوحيد** لكل Physical Stock Movement.

مسؤولياته:

- تعديل Physical `stock_branches.qty`.
- `inventory_log`.
- Movement validation.
- Idempotency.
- Locking / atomicity.
- Company / branch / item context بحسب العقد.

## 9.2 Reservation

`reserve_stock` = Reservation فقط. لا يخصم Physical `qty`.

## 9.3 Source of Truth

`order_details` = authoritative fulfillment quantity layer.

`run_sheet_details` = derived aggregate عندما يكون trigger `sync_run_sheet_details` هو المصدر المشتق المؤكد.

## 9.4 Loading / Reopen / Unloading

- `Loading = MAIN → VAN`
- `Reopen = VAN → MAIN + إنشاء Loading Cycle جديدة`
- `Reload = يستخدم دورة Loading الجديدة`
- `Unloading = VAN → MAIN`

Loading ليس COGS بذاته.

---

# 10. Closure Unit — طريقة العمل

**الصخرة الكبيرة = Closure Units صغيرة.**

كل Closure Unit تُغلق إلى 100% قبل الانتقال إلى التالية.

العملية:

`PRE-CHANGE SELF-AUDIT`
→ `READ / REQUEST ALL RELEVANT SOURCES`
→ `HISTORICAL / ORIGINAL / CURRENT / PRODUCTION RECONCILIATION`
→ `LOSS / GAIN MATRIX`
→ `TARGET CONTRACT`
→ `SURGICAL CHANGE`
→ `TEST`
→ `PRODUCTION EVIDENCE`
→ `FINAL SELF-AUDIT`
→ `100% CLOSE`
→ `NEXT UNIT`

---

# 11. تعريف الجراحة التعديلية

قبل أي تعديل يجب تحديد:

- ما الذي كان Legacy يفعله.
- ما الذي يجب أن يبقى.
- ما الذي ينتقل إلى Core.
- ما الذي يضاف.
- ما الذي يزال عمدًا.
- أين ذهبت كل Responsibility بعد النقل.

استخدم أقل تغيير ممكن، لكن لا تستخدم Surgical كذريعة لترك نقص.

إذا كشف الفحص أن Core يحتاج إصلاحًا، أصلحه ضمن نفس Closure Unit قبل الإغلاق.

---

# 12. التقرير الذاتي الإلزامي

## في المقدمة

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

Historical Opened:
Original Opened:
Production Evidence Received:
Current Opened:
Schema Checked:
Triggers Checked:
Dependencies Checked:
Consumers Checked:
```

## في النهاية

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

**لا يجوز إعطاء 100/100 مع وجود Unknowns أو Unverified Claims مؤثرة.**

---

# 13. التحقق الحقيقي — وليس النظري

لكل Closure Unit ميّز بين:

- THEORETICAL
- CURRENT ONLY
- STAGING VERIFIED
- PRODUCTION DEPLOYED
- PRODUCTION RUNTIME VERIFIED
- 100% CLOSED

ولا تساوِ بينها.

عند توفر Evidence التشغيلية، أفضل مسار إثبات:

`Application → HTTP → Auth → Edge → Core → DB → Response → UI state`

مع فحوص Normal / Partial / Retry / Duplicate / Concurrent / Invalid State / Failure-Rollback / Company Isolation / Baseline Restoration.

---

# 14. قاعدة التعامل مع العوائق

ممنوع:

`FOUND DEFECT → BLOCKED → REPORT`

المطلوب:

`FOUND DEFECT → ROOT CAUSE → SEARCH SOURCE / HISTORICAL PATTERN / INDUSTRY PATTERN → REPAIR → TEST → VERIFY → DEPLOY → CLOSE`

إذا لم توجد أداة مباشرة لتنفيذ إجراء معيّن:

1. حدّد الإجراء اليدوي المطلوب من المالك بدقة.
2. أكمل كل ما يمكن تنفيذه دون انتظار.
3. لا تحوّل عائقًا واحدًا إلى توقف شامل.

---

# 15. Industry Benchmarking Rule

في الأمور الثابتة محاسبيًا ومنطقيًا ومخزنيًا لا نخترع العجلة. استفد من مبادئ الأنظمة الناضجة مثل SAP وMicrosoft Dynamics وOdoo، مع تكييف المبدأ مع RAWAEA وليس نسخ النظام حرفيًا.

---

# 16. أهم العيوب والدروس التنفيذية

## 16.1 Duplicate `users_email_key`

ظهرت أثناء تجربة حقيقية على `picker.html`.

السبب:

- tenant context من `app_settings.limit(1)`.
- lookup بـ`email + company_id`.
- فشل lookup داخل الشركة.
- محاولة إنشاء `public.users`.
- قيد `users_email_key` العالمي يرفض الإدخال.

الإصلاح المعروف:

`JWT auth.users.id → public.users.id → public.users.company_id → company-scoped runsheet`

و`picker.html` لم يكن سبب المشكلة.

## 16.2 Distributed Business Logic

الإشكال التاريخي: Edge Functions كثيرة كانت تعمل كمحركات أعمال مستقلة للمخزون.

الإصلاح: Edge = Capability Adapter، وPostgreSQL Core = Business Engine.

## 16.3 Current / Production Drift

قد تكون النسخة الصحيحة في Production بينما Current لا يمثلها، أو العكس. كل Closure يجب أن يثبت Current artifact + Production artifact + Core state + Consumer contract.

## 16.4 Staging / Production confusion

نجاح Staging لا يساوي Production.

## 16.5 Harness Governance

`ACTIVE + 410 Stub != DELETED`.

## 16.6 False Closure

`Report != Execution` و`PASS != 100%` إذا بقيت بوابة مؤثرة غير مثبتة.

## 16.7 Artifact Recovery

إذا قيل إن Final Artifact مفقود: Original → Historical original/current/archive → Git history → Production snapshot.

---

# 17. آخر لقطة تنفيذية معروفة

هذه **لقطة مؤرخة** وليست Live Access.

| Closure Unit | آخر وضع معروف |
|---|---|
| `complete-picking` | أُغلقت هندسيًا/تشغيليًا وفق آخر Evidence، ويُفترض أن يُراجع أي دليل أحدث |
| `start-picking` | Production v14؛ duplicate email/company-context defect تم إصلاحه ونشره |
| `start-loading` | Production v4 ضمن Loading rescue |
| `complete-loading` | Production v10؛ Thin Wrapper + Core مركزي |
| `reopen-loading` | Production v2؛ Loading Cycle جديدة عند Reopen |
| `unload-runsheet` | Production v5؛ عكس Loading عبر Core |
| `send-stock-voucher` | Production v7؛ routing إلى Central Stock Engine معروف، والإغلاق النهائي يحتاج أحدث Evidence |
| `receive-stock-voucher` | Production v5؛ Closure لاحقة |
| `receive-purchase` | Production v9؛ Closure لاحقة |
| `bulk-stock-adjustment` | Production v5؛ Closure لاحقة |
| `save-sales-invoice` | Production v13؛ إصلاح VanSale double-deduction ضمن rescue |
| `complete-return` | Production v23؛ Central routing ضمن rescue |
| `complete-order-delivery` | Production v11؛ إصلاح VAN physical deduction defect |
| `create-runsheet` | Production v22؛ Dependency أساسية لدورة Runsheet/Picking |

---

# 18. Queue Zero-Debt

1. `complete-picking`
2. `send-stock-voucher`
3. `receive-stock-voucher`
4. `receive-purchase`
5. `bulk-stock-adjustment`
6. `save-sales-invoice`
7. `complete-return`
8. `complete-order-delivery`
9. `GLOBAL PHYSICAL STOCK WRITER SWEEP`
10. Accounting
11. Ledger
12. بقية Domains حسب `DOMAIN_EXECUTION_ORDER`.

**لا تقفز إلى الوحدة التالية قبل إغلاق الحالية 100%.**

---

# 19. المستندات والأدلة

عند استلام Evidence جديدة، أعطها الأولوية بحسب التاريخ، مباشرتها للنظام، كونها Production/Staging، وعلاقتها المباشرة بالوحدة الحالية.

عند التعارض سجل `CONFLICT` مع المصدرين والتاريخ والفرق وما يحتاجه المالك لحسمه. لا تحل تعارضًا مهمًا بالتخمين.

---

# 20. حدود مساعد الرسائل الداخلية

المساعد لا يملك وصولًا مباشرًا إلى GitHub أو Supabase أو PostgreSQL أو Production أو الويب.

لذلك لا يقول "راجعت Production" أو "نشرت" أو "نفذت" أو "اختبرت" إلا إذا أرسل المالك Evidence مباشرة تثبت ذلك.

---

# 21. الحد الأدنى الذي يطلبه لكل Closure Unit

1. Historical function.
2. Original function إن وجدت.
3. Current function.
4. آخر Production Edge snapshot.
5. Core RPC definition.
6. الجداول/Triggers/constraints المرتبطة.
7. Consumer source.
8. آخر Runtime Evidence.
9. آخر Closure Report.

ولا يطلب مشروع الكون كله إذا كانت الوحدة الحالية لا تحتاجه.

---

# 22. Golden / Diamond Applications

ملفات التطبيقات الذهبية لا تُعاد كتابتها بسبب Backend defect.

عند الخطأ:

1. حدّد Console line/function/endpoint.
2. اتبع `UI → HTTP → Edge → Core → DB`.
3. أصلح مصدر المشكلة.
4. عدل UI فقط إذا ثبت أنه مصدر المشكلة.

الهدف: **Surgical Change**.

---

# 23. معيار 100%

لا تعلن 100% إلا بعد:

- Historical understanding.
- Original comparison.
- Current final artifact.
- Core correctness.
- Dependencies.
- Consumer compatibility.
- Static validation.
- Staging runtime.
- Production deployment.
- Production runtime verification عند توفر الدليل.
- Baseline restoration.
- Governance cleanup.
- عدم وجود Unknown/Conflict/Unverified مؤثر.

في Message-Only mode:

**`PRODUCTION RUNTIME VERIFIED ONLY BY OWNER-SUPPLIED EVIDENCE`**

---

# 24. التوجيه السلوكي

**اقرأ أولًا. افهم ثانيًا. نفّذ ثالثًا. اختبر رابعًا. تحقق خامسًا. أغلق سادسًا.**

ممنوع:

- الحبو.
- الدوران.
- اختراع النقص أو النجاح.
- إرجاء المشكلة إلى Task لاحقة.
- فتح عدة Closure Units في وقت واحد.
- استخدام التقارير كبديل عن الأدلة.

عند اكتشاف عائق: استخدم كل المصادر والبدائل المتاحة أولًا، ثم حدد بدقة ما يحتاجه المالك.

---

# 25. الهدف النهائي

**ONE CORE + ONE SOURCE OF TRUTH + ZERO INVENTORY DEBT + ZERO FALSE CLOSURE + PRODUCTION = VERIFIED TARGET SYSTEM**

هذه الحزمة ليست لحفظ التقارير، بل لفهم المشروع، أماكن الحقيقة، طريقة المقارنة، الجراحة التعديلية، منع Drift، وإغلاق كل Closure Unit حتى النهاية.

---

## 26. ملحق تنفيذي: أخطاء يجب ألا تتكرر

أثناء العمل السابق ظهرت حالات يجب أن يتعامل معها المساعد الجديد كإشارات خطر فورية:

- وجود الإصلاح في Production بينما Current لم يكن يحتوي artifact نفسه.
- وجود artifact في Historical repo وعدم العثور عليه في `rawaie-erp-New/Original`.
- إعلان حذف Temporary Edge Function بينما كانت `ACTIVE` في Registry.
- إعلان 100% ثم اكتشاف دورة Reopen → Reload لم تكن تُنشئ Loading identity جديدة.
- اكتشاف أن `complete-order-delivery` يسجل Inventory Log دون VAN physical deduction.
- اكتشاف `save-sales-invoice` مع double deduction لمسار VanSale.
- اكتشاف `start-picking` مع duplicate `users_email_key` بسبب خطأ tenant resolution.
- اكتشاف أن الاختبار المباشر للـRPC لا يساوي Edge HTTP E2E.

كل حالة من هذه الحالات تؤكد أن:

**التحقيق يجب أن يسبق الحكم، والتنفيذ يجب أن يسبق الإعلان، والإغلاق يجب أن يسبق الانتقال.**
