# RAWAEA ERP — خريطة التنفيذ وسد فجوات حزمة مساعد الرسائل الداخلية

**التاريخ:** 2026-08-15
**النوع:** EXECUTION MAP / CONTEXT GAP SUPPLEMENT
**المرجع الأساسي:** `doc/AI_ASSISTANT_MESSAGE_ONLY_CONTEXT_PACKET_MASTER_2026-08-15_AR.md`

> هذه الوثيقة تضيف طبقة عملية لمساعدة المساعد الجديد على العمل من الملفات والرسائل فقط. لا تستبدل الحزمة الرئيسية.

---

# 1. لماذا نحتاج هذه الوثيقة؟

الحزمة الرئيسية والمكملة توفران سياقًا قويًا، لكن المساعد الجديد يحتاج أيضًا إلى **طريقة استخدام السياق** حتى لا:

- يقرأ كل شيء دفعة واحدة ويضيع الأولويات.
- يخلط بين الوثيقة والتشغيل الفعلي.
- يخلط بين Current وProduction.
- يبدأ تعديلًا قبل معرفة وظيفة الدالة واعتمادياتها.
- يتوقف عند نقص ملف بينما توجد نسخة تاريخية في مصدر آخر.
- يقفز بين Closure Units ويترك دينًا خلفه.

القاعدة هنا:

> **السياق الكامل يُقرأ مرة، أما ملفات التنفيذ فتُسلّم على وحدات صغيرة.**

---

# 2. الخريطة الذهنية المختصرة

```text
                 RAWAEA ERP
                      │
        ┌─────────────┴─────────────┐
        │                           │
   رؤية المالك                 نظام التنفيذ
        │                           │
  Governance / ADRs          Closure Units
        │                           │
        └─────────────┬─────────────┘
                      │
                Inventory Rescue
                      │
        ┌─────────────┼─────────────┐
        │             │             │
   Physical Move   Reservation   Fulfillment
        │             │             │
post_stock_...   reserve_stock   order_details
        │                           │
stock_branches               run_sheet_details
inventory_log                      │
                              triggers
                      
                      │
             Edge Functions / PWA
                      │
                Production Evidence
```

---

# 3. تسلسل الملفات الذي يفهمه المساعد

## المرحلة 1 — تكوين الصورة العامة

1. `doc/AI_ASSISTANT_MESSAGE_ONLY_CONTEXT_PACKET_MASTER_2026-08-15_AR.md`
2. `doc/AI_ASSISTANT_MESSAGE_ONLY_CONTEXT_PACKET_SUPPLEMENT_2026-08-15_AR.md`
3. `CTO/00_MASTER_CONTEXT.md`
4. `CTO/01_SOURCE_AUTHORITY_MAP.md`
5. `Governance/RAWAEA_ARCHITECTURE_CONSTITUTION.md`
6. `Governance/EXECUTION_PROTOCOL.md`

**النتيجة المطلوبة:** المساعد يعرف ما المشروع، وما سلطات الحقيقة، وما الممنوع.

## المرحلة 2 — فهم الخطة

7. `doc/خطة تنفيذية مرحلية - المرحلة الأولي المجزئة.md`
8. `CTO/MASTER-EXECUTION-LOG.md`
9. `CTO/02_EXECUTION_LOG.md`
10. `CTO/03_CURRENT_STATUS.md`
11. `CTO/05_TRUTH_RECONCILIATION.md`
12. `CTO/RESCUE-RECONCILIATION-2026-08-15.md`
13. `CTO/02_HISTORICAL_KNOWLEDGE_INDEX.md`
14. `CTO/04_PROJECT_SOURCE_INVENTORY.md`

**النتيجة المطلوبة:** يعرف من أين بدأنا وإلى أين وصلنا وما الذي لم يُغلق.

## المرحلة 3 — التاريخ والنسخ

15. `Edge_Function_Reports/_HISTORICAL/`
16. `rawaie-erp-review/Edge_Functions/original/`
17. `rawaie-erp-review/Edge_Functions/current/`
18. `rawaie-erp-review/Edge_Functions/archive/`
19. `rawaie-erp-New/Original/`
20. `rawaie-erp-New/Current/`

**النتيجة المطلوبة:** يعرف أين يجد النسخة الأصلية حتى لو لم توجد في `rawaie-erp-New/Original`.

## المرحلة 4 — قاعدة البيانات

21. `SQL_Evidence/schema/`
22. `SQL_Evidence/diagnostics/`
23. `supabase/migrations/`

**النتيجة المطلوبة:** يفهم الجداول والقيود والـRPCs والـtriggers قبل لمس أي Edge Function.

## المرحلة 5 — التطبيق

24. `Current/PWA/main.html`
25. `Current/PWA/core.js`
26. الـconsumer الخاص بالـClosure Unit الحالية فقط.

**النتيجة المطلوبة:** يعرف contract الحقيقي من التطبيق إلى Edge.

---

# 4. Evidence Packet لكل Closure Unit

لا ترسل للمساعد عشرات الملفات عشوائيًا. أنشئ حزمة صغيرة لكل دالة:

```text
[01] Current Edge Function
[02] Historical/Original Edge Function
[03] Production deployed source أو تعريف الإصدار
[04] Core RPC definition
[05] Direct dependencies
[06] Consumer file
[07] آخر تقرير/Decision متعلق بالدالة
[08] Runtime / Console / HTTP evidence إن وُجد
```

وإذا كانت الدالة تعتمد على دالة أخرى مباشرة، أضف Dependency Packet لها فقط.

---

# 5. جدول تصنيف كل شيء

يجب أن يضع المساعد حالة كل عنصر في واحدة فقط من الحالات التالية:

| الحالة | معناها |
|---|---|
| `DESIGN` | قرار مستهدف لم يُثبت تنفيذُه |
| `CURRENT` | موجود في Current فقط |
| `STAGING VERIFIED` | اختبر في Staging |
| `PRODUCTION DEPLOYED` | منشور في Production |
| `PRODUCTION VERIFIED` | نفذ فعليًا في Production بأدلة |
| `100% CLOSED` | كل بوابات الوحدة مغلقة |
| `UNKNOWN` | لا يوجد دليل كافٍ |
| `CONFLICT` | الأدلة متعارضة |

---

# 6. بروتوكول المقارنة قبل التعديل

قبل تغيير أي Function:

```text
Historical / Original
        ↓
وظائفها ومسؤولياتها
        ↓
Production الحالية
        ↓
Current الحالية
        ↓
Core / DB
        ↓
Consumer
        ↓
Target Contract
```

ثم يُنتج:

### LOSS
ما اختفى؟

### GAIN
ما أضيف؟

### MOVE
ما انتقل إلى Core؟

### HARDEN
ما أصبح أكثر أمانًا؟

### INTENTIONAL REMOVE
ما أزيل عمدًا ولماذا؟

### MISSING
ما لم نجد له بديلًا؟

---

# 7. القاعدة المحاسبية والمخزنية

عندما يكون القرار ثابتًا في الصناعة، لا يُخترع من الصفر.

يُراجع المساعد:

- SAP
- Microsoft Dynamics
- Odoo
- المعايير المحاسبية والمخزنية المناسبة

ثم يربط المبدأ بعقد RAWAEA.

لكن **Industry Benchmark لا يثبت Production implementation**.

---

# 8. قاعدة التعامل مع الملفات الذهبية

الملفات التطبيقية الحساسة مثل:

- `picker.html`
- `loader.html`
- `receiver.html`
- `unloader.html`
- `van-sales.html`
- `main.html`

تعامل كـ**Golden/Diamond Artifacts**.

لا يعاد تصميمها لمجرد وجود مشكلة خلفية.

يجب أولًا إثبات:

`Consumer Contract صحيح`

ثم إصلاح Backend/Edge/Core.

إذا ظهر أن الـfrontend نفسه هو مصدر المشكلة:

**Surgical Patch محدد، لا Rewrite.**

---

# 9. قاعدة Current Source of Truth

لا تنشئ نسخًا جديدة للدالة في مستودعات أو مجلدات متعددة.

المكان الرسمي للنسخة النهائية هو:

`rawaie-erp-New/Current/Edge_Functions/`

والنسخة النهائية لملف التطبيق في:

`rawaie-erp-New/Current/PWA/`

Production deployment يجب أن يعود إلى artifact يمكن تعقبه إلى Current + Commit.

---

# 10. ترتيب العمل عندما يكون هناك عائق

إذا قال المساعد:

> لا أملك الملف.

يُنفذ:

```text
Search Current
→ Search Original
→ Search Historical
→ Search Archive
→ Search Git history
→ Ask owner only if still missing
```

إذا قال:

> لا أستطيع تنفيذ اختبار HTTP.

يُنفذ:

```text
External runner
→ staging fixture
→ existing test runsheet
→ reversible production canary (only when explicitly authorized)
```

ثم يطلب من المالك فقط الإجراء الذي يحتاج موافقته أو تنفيذه.

---

# 11. Definition of Done

Closure Unit ليست مكتملة عندما:

- الكود "يبدو صحيحًا".
- أو الاختبار النظري نجح.
- أو Production deployment تم.

بل عندما يثبت:

```text
Source
+ Core
+ Dependencies
+ Consumers
+ Tests
+ Deployment
+ Runtime Evidence
+ Baseline Restoration
+ Governance
= 100% CLOSED
```

---

# 12. ماذا يجب أن يطلب المساعد من المالك؟

عندما يحتاج Evidence من Production، لا يطلب "كل شيء".

يطلب فقط:

1. نسخة Function المنشورة.
2. تعريف Core RPC.
3. نتيجة الاختبار/Console.
4. لقطة حالة DB الضرورية.
5. أي إجراء يدوي محدد لا يستطيع تنفيذه.

ثم يعود مباشرة إلى التنفيذ.

---

# 13. حالة المشروع عند تهيئة المساعد الجديد

استخدم الحزمة الرئيسية كأساس للسياق، ثم **اعتبر حالة الـInventory Rescue لقطة مؤرخة وليست حقيقة حية**.

المعلومة التي يجب أن تبقى ثابتة هي:

> **الهدف المعماري:** ONE CORE / ONE SOURCE OF TRUTH، والمحرك المركزي `post_stock_movement` لكل Physical Stock Movement، مع Reservation منفصل.

أما نسب الإنجاز، إصدارات Production، والـClosure Units المغلقة، فيجب تحديثها فقط من آخر Evidence يرسله المالك.

---

# 14. أمر التهيئة النهائي

أرسل للمساعد بعد الحزمة:

> أنت CTO للروائع ERP في وضع Message-Only.
>
> لا تملك وصولًا مباشرًا إلى GitHub أو Supabase أو الويب.
>
> لا تدّعي أي تنفيذ لا يثبت في الملفات أو الأدلة التي أرسلها المالك.
>
> اقرأ الحزم المرجعية بالترتيب.
>
> ابنِ خريطة ذهنية واحدة للمشروع.
>
> ثم اعمل Closure Units واحدة واحدة.
>
> قبل كل وحدة: Self-Audit + فهم الدالة + مقارنة المصادر.
>
> أثناء الوحدة: Surgical Refactor + اختبار + تحقق.
>
> عند أي نقص: ابحث في كل المصادر قبل طلب المساعدة.
>
> لا تتوقف عند Block يمكن حله.
>
> بعد كل وحدة: Final Self-Audit + حالة مغلقة أو مفتوحة بصدق.
>
> لا تنتقل إلى الوحدة التالية قبل 100% Closed.

# END
