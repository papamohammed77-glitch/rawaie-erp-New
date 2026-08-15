# RAWAEA ERP — دليل تهيئة مساعد CTO بنظام الرسائل فقط

**التاريخ:** 2026-08-15
**الغرض:** تمكين المالك من إنشاء مساعد CTO جديد عبر الرسائل والملفات فقط، بدون وصول مباشر إلى GitHub أو Supabase أو PostgreSQL أو الويب.

> هذا الدليل هو **دليل التشغيل للمالك**. لا يحتاج المالك إلى فهم التفاصيل التقنية؛ ينفذ الترتيب ويرسل الملفات، والمساعد يتولى الفهم والتحليل والمتابعة.

---

# 1. ابدأ بماذا؟

أرسل للمساعد أولًا هذه الوثيقة:

`doc/AI_ASSISTANT_MESSAGE_ONLY_CONTEXT_PACKET_MASTER_2026-08-15_AR.md`

ثم أرسل:

`doc/AI_ASSISTANT_MESSAGE_ONLY_CONTEXT_PACKET_SUPPLEMENT_2026-08-15_AR.md`

ثم اطلب منه صراحة:

> اقرأ الحزمتين بالكامل، ولا تبدأ أي اقتراح أو تعديل. قدّم فقط تقرير فهم أولي يثبت أنك فهمت المشروع، مصادر الحقيقة، خطة الإنقاذ، وطريقة العمل.

---

# 2. بعد ذلك: أعطه السلطة المعمارية

أرسل بالترتيب:

1. `CTO/00_MASTER_CONTEXT.md`
2. `CTO/01_SOURCE_AUTHORITY_MAP.md`
3. `Governance/RAWAEA_ARCHITECTURE_CONSTITUTION.md`
4. `Governance/EXECUTION_PROTOCOL.md`
5. `Architecture/EXECUTION_GUARDRAILS.md` إن وُجد
6. `Architecture/DOMAIN_EXECUTION_ORDER.md` إن وُجد
7. `Architecture/INV-001 — INVENTORY REALITY MAP.md` إن وُجد

ثم قل له:

> لا تعد التنفيذ. ادمج هذه الوثائق مع الحزمة الرئيسية، وحدد أي تعارض أو نقص فقط.

---

# 3. أعطه الخطة التنفيذية والحالة الحالية

أرسل:

8. `doc/خطة تنفيذية مرحلية - المرحلة الأولي المجزئة.md`
9. `CTO/MASTER-EXECUTION-LOG.md`
10. `CTO/02_EXECUTION_LOG.md`
11. `CTO/03_CURRENT_STATUS.md`
12. `CTO/05_TRUTH_RECONCILIATION.md`
13. `CTO/RESCUE-RECONCILIATION-2026-08-15.md`
14. `CTO/02_HISTORICAL_KNOWLEDGE_INDEX.md`
15. `CTO/04_PROJECT_SOURCE_INVENTORY.md`

المطلوب منه هنا:

> كوّن Timeline واحدة للحالة الحالية، وافصل بوضوح بين ما هو Target، وما هو Current، وما ثبت أنه Production، وما هو مجرد تقرير تاريخي.

---

# 4. أعطه التاريخ والنسخ الأصلية

أرسل له:

16. `Edge_Function_Reports/_HISTORICAL/RAWAEA ERP HANDOVER.md`
17. `Edge_Function_Reports/_HISTORICAL/Batch01.md` إلى `Batch15.md` بحسب الحاجة
18. من المستودع التاريخي:
   `rawaie-erp-review/Edge_Functions/original/`
19. ثم:
   `rawaie-erp-review/Edge_Functions/current/`
20. ثم:
   `rawaie-erp-review/Edge_Functions/archive/`

**لا ترسل كل ملفات الدوال دفعة واحدة.**

أرسل للمساعد عند كل Closure Unit فقط الدالة المطلوبة + نسختها التاريخية المقابلة + أي Dependency مباشرة.

---

# 5. أعطه قاعدة البيانات كمرجع ثابت

أرسل:

21. `SQL_Evidence/schema/tables.csv`
22. `SQL_Evidence/schema/Foreign Keys.csv`
23. `SQL_Evidence/schema/Indexes.csv`
24. `SQL_Evidence/schema/Primary Keys.csv`
25. `SQL_Evidence/schema/Enum Types.csv`
26. `SQL_Evidence/schema/Database Functions.csv`
27. `SQL_Evidence/schema/استعلام RLS Policies.csv`
28. `SQL_Evidence/diagnostics/` عند الحاجة
29. migrations ذات الصلة فقط

ثم أكد له:

> لا تعتبر أي migration غير مثبتة النشر Production truth.

---

# 6. أعطه التطبيقات والمستهلكين

ابدأ بالملفات المرتبطة بالمرحلة الحالية فقط.

للمستودع الحالي:

30. `Current/PWA/main.html`
31. `Current/PWA/core.js`
32. `Current/PWA/warehouse/picker.html`
33. `Current/PWA/warehouse/loader.html`
34. `Current/PWA/warehouse/receiver.html`
35. `Current/PWA/warehouse/unloader.html`
36. `Current/PWA/warehouse/returns.html`
37. `Current/PWA/warehouse/vouchers.html`
38. `Current/PWA/sales/van-sales.html`
39. `Current/PWA/sales/pos.html`
40. `Current/PWA/sales/telesales.html`
41. `Current/PWA/delivery/driver.html`

لا تطلب منه تعديل هذه الملفات إلا بعد إثبات أن الخطأ في الـconsumer نفسه.

---

# 7. بعد اكتمال السياق: اجعله يبني خريطة ذهنية

اطلب منه إخراج خريطة ذهنية من هذا الشكل:

```text
RAWAEA ERP
│
├── VISION / GOVERNANCE
│   ├── CTO Context
│   ├── Architecture Constitution
│   └── Execution Protocol
│
├── EXECUTION PLAN
│   ├── Phase 1
│   ├── Closure Units
│   └── Current Status
│
├── SOURCE OF TRUTH
│   ├── Historical
│   ├── Original
│   ├── Current
│   ├── Production Evidence
│   └── Target
│
├── INVENTORY RESCUE
│   ├── post_stock_movement
│   ├── reserve_stock
│   ├── order_details
│   ├── run_sheet_details
│   └── Loading / Reopen / Unloading
│
├── APPLICATIONS
│   ├── Warehouse PWA
│   ├── Sales PWA
│   └── Delivery PWA
│
└── CLOSURE STATUS
    ├── 100% Closed
    ├── In Progress
    ├── Not Started
    └── Unknown / Conflict
```

---

# 8. بعد الخريطة: ابدأ Closure Units واحدة واحدة

القاعدة:

```text
PRE-CHANGE SELF-AUDIT
↓
READ SOURCES
↓
COMPARE ORIGINAL / HISTORICAL / CURRENT / PRODUCTION EVIDENCE
↓
LOSS / GAIN MATRIX
↓
TARGET CONTRACT
↓
SURGICAL CHANGE
↓
TEST
↓
PRODUCTION EVIDENCE
↓
FINAL SELF-AUDIT
↓
100% CLOSED
↓
NEXT UNIT
```

لا يبدأ الدالة التالية قبل إغلاق الحالية.

---

# 9. ترتيب Inventory Rescue الحالي

ابدأ حسب آخر حزمة معتمدة، مع إعادة التحقق عند وصول Evidence أحدث:

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
12. بقية Domains حسب `DOMAIN_EXECUTION_ORDER`

---

# 10. ما الذي يفعله المساعد وما الذي يفعله المالك؟

## المالك

- ينشئ المساعد.
- يرسل الملفات بالترتيب.
- يرسل Evidence من GitHub/Supabase عند طلبه.
- ينفذ أي إجراء لا يملك المساعد وسيلة مباشرة لتنفيذه.
- يؤكد الاختبارات الواقعية عندما تتم على النظام الأم.

## المساعد

- يقرأ ويفهم.
- يبحث داخل الملفات التي وصلته قبل أن يقول Missing.
- يحدد النقص.
- يصمم الحل.
- يوجه الجراحة التعديلية.
- يراجع كل Dependency قبل التعديل.
- يتحقق من عدم فقد أي مسؤولية.
- يطلب Evidence محددة فقط عندما تكون ضرورية.
- لا يدعي تنفيذًا لم يحدث.
- لا يعلن 100% قبل اكتمال الأدلة.

---

# 11. أهم قاعدة تمنع الحلقة المفرغة

عند اكتشاف مشكلة:

```text
لا تتوقف.
```

افعل:

```text
اكتشف السبب
→ ابحث في التاريخ والمصادر
→ افهم المعالجة السابقة
→ أصلح
→ اختبر
→ تحقق
→ أغلق
```

إذا كان المطلوب إجراءً بيد المالك فقط:

> حدد للمالك الإجراء في سطر واحد، ثم واصل كل ما يمكنك إنجازه.

---

# 12. ماذا أرسل له في كل مرة؟

قاعدة بسيطة جدًا:

### مرة واحدة
الحزمة الرئيسية + الحزمة المكملة + السلطة المعمارية + الخطة.

### لكل دالة
- Current function
- Historical/original function
- Production evidence
- Core dependencies
- Consumer
- آخر تقرير متعلق بها

### بعد الاختبار
- نتيجة الاختبار
- الحالة الفعلية
- أي Console / HTTP / SQL evidence

بهذا يصبح كل Closure Unit مستقلًا وواضحًا.

---

# 13. النتيجة المطلوبة من المالك

لا تحتاج إلى شرح المشروع للمساعد شفهيًا كل مرة.

يكفي:

**أرسل الحزمة → أرسل ملفات السلطة → أرسل ملفات الدالة الحالية → أرسل Evidence → دع المساعد يدير Closure Unit.**

ثم عندما يغلقها 100% انتقل إلى التالية.
