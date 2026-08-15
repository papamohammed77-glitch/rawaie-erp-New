# RAWAEA ERP — خطة تهيئة مساعد CTO عبر الرسائل فقط

**التاريخ:** 2026-08-15
**الوضع:** مساعد جديد بلا وصول مباشر إلى GitHub / Supabase / PostgreSQL / Web.
**المسؤول عن الخطة:** CTO الحالي.
**المسؤول عن إنشاء المساعد وإرسال الملفات:** المالك.

---

# 1. الهدف

تهيئة مساعد جديد يفهم المشروع وخطة إنقاذ الـInventory كاملة، ويستطيع العمل كـCTO عبر الملفات التي يرسلها المالك فقط، دون أن يطلب إعادة شرح ما هو موجود في الحزمة.

الهدف ليس نقل كل تاريخ المشروع بالتساوي، بل نقل **ما يحتاجه لاتخاذ قرارات صحيحة وتنفيذ Closure Units صحيحة** بأقل عدد رسائل.

---

# 2. قاعدة الإرسال

يمكن إرسال **عدة ملفات في الرسالة الواحدة**.

القاعدة العملية:

- كل رسالة = مجموعة ملفات مرتبطة بموضوع واحد.
- لا تفصل كل ملف في رسالة مستقلة.
- ابدأ بالملفات الحاكمة، ثم الحالة الحالية، ثم Inventory rescue، ثم التاريخ، ثم الدالة التي ستعمل عليها.

المساعد الجديد لا يبدأ التنفيذ من الذاكرة العامة؛ يبدأ من **حزمة السياق + ترتيب القراءة**.

---

# 3. خريطة ذهنية مختصرة

```text
RAWAEA ERP
│
├── A. السلطة والرؤية
│   ├── Master Context
│   ├── Source Authority Map
│   ├── Architecture Constitution
│   └── Execution Protocol
│
├── B. الخطة التنفيذية والحالة
│   ├── Phase-1 Execution Plan
│   ├── Execution Log
│   ├── Current Status
│   └── Rescue Reconciliation 2026-08-15
│
├── C. Inventory Rescue Contract
│   ├── One Core / One Source of Truth
│   ├── post_stock_movement
│   ├── reserve_stock
│   ├── order_details authority
│   ├── run_sheet_details derived
│   └── Loading / Reopen / Reload / Unloading
│
├── D. التاريخ والمقارنة
│   ├── Historical Edge Functions
│   ├── Original Edge Functions
│   ├── Archive
│   └── Historical Reports / Handover
│
├── E. الأدلة الفنية
│   ├── Schema
│   ├── Functions
│   ├── Triggers
│   ├── RLS / Privileges
│   └── Diagnostics
│
├── F. التطبيقات والمستهلكون
│   ├── PWA/main.html
│   ├── picker.html
│   ├── loader.html
│   ├── receiver.html
│   ├── unloader.html
│   ├── vouchers.html
│   ├── van-sales.html
│   └── delivery / returns
│
└── G. Closure Queue
    ├── complete-picking
    ├── send-stock-voucher
    ├── receive-stock-voucher
    ├── receive-purchase
    ├── bulk-stock-adjustment
    ├── save-sales-invoice
    ├── complete-return
    ├── complete-order-delivery
    └── Global Physical Stock Writer Sweep
```

---

# 4. ترتيب الرسائل المقترح

## الرسالة 1 — الحزمة الرئيسية

أرسل:

- `AI_ASSISTANT_MESSAGE_ONLY_CONTEXT_PACKET_MASTER_2026-08-15_AR.md`
- `AI_ASSISTANT_MESSAGE_ONLY_CONTEXT_PACKET_GAPS_AND_SUPPLEMENT_2026-08-15_AR.md`

الهدف: إنشاء الهوية، القواعد، هرم الحقيقة، ومبدأ العمل.

## الرسالة 2 — السلطة المعمارية

أرسل:

- `CTO/00_MASTER_CONTEXT.md`
- `CTO/01_SOURCE_AUTHORITY_MAP.md`
- `Governance/RAWAEA_ARCHITECTURE_CONSTITUTION.md`
- `Governance/EXECUTION_PROTOCOL.md`
- `Architecture/DOMAIN_EXECUTION_ORDER.md` إن كان موجودًا

## الرسالة 3 — الخطة والحالة

أرسل:

- `doc/خطة تنفيذية مرحلية - المرحلة الأولي المجزئة.md`
- `CTO/MASTER-EXECUTION-LOG.md`
- `CTO/02_EXECUTION_LOG.md`
- `CTO/03_CURRENT_STATUS.md`
- `CTO/RESCUE-RECONCILIATION-2026-08-15.md`

## الرسالة 4 — Inventory Evidence

أرسل:

- ملفات `SQL_Evidence/schema/` الأساسية
- `SQL_Evidence/diagnostics/`
- migrations المرتبطة بالـInventory التي تعتبرها الحزمة الحالية مرجعية

## الرسالة 5 — التاريخ

أرسل:

- `Edge_Function_Reports/_HISTORICAL/RAWAEA ERP HANDOVER.md`
- `Edge_Function_Reports/_HISTORICAL/INV-001 ...` إن وجد
- `Edge_Function_Reports/_HISTORICAL/INV-002 ...` إن وجد
- `Batch01.md` إلى `Batch15.md` على دفعات داخل نفس الرسالة عند الإمكان

## الرسالة 6 — التطبيقات

أرسل معًا:

- `PWA/main.html`
- `PWA/core.js`
- ملفات تطبيقات المجال الذي ستعمل عليه Closure Unit

## الرسالة 7 — Closure Unit الحالية

أرسل **كل ملفات الدالة الحالية + النسخة الأصلية + Core + Consumer + تقريرها النهائي السابق** في رسالة واحدة.

ابدأ بالوحدة التي يحددها آخر Rescue Reconciliation مؤكّد.

---

# 5. ما الذي يجب أن يعرفه المساعد قبل أول تنفيذ

يجب أن يثبت أنه فهم:

1. لماذا Inventory تأتي أولًا.
2. ما الفرق بين Physical Movement وReservation.
3. لماذا `post_stock_movement` هو Physical Stock Engine المركزي.
4. لماذا `reserve_stock` ليس Physical Movement.
5. لماذا `order_details` authoritative و`run_sheet_details` derived.
6. لماذا Loading ليس COGS بذاته.
7. لماذا لا نعيد كتابة التطبيقات الذهبية إلا بجراحة مثبتة.
8. لماذا Current ليس Production.
9. لماذا Historical ليس Target تلقائيًا.
10. لماذا تقرير المساعد ليس Evidence.
11. لماذا كل Closure Unit يجب أن تصل 100% قبل التالية.
12. لماذا نستخدم Industry Benchmark بدل اختراع منطق محاسبي/مخزني ثابت.

---

# 6. بروتوكول التشغيل للمساعد الجديد

في كل Closure Unit:

`SELF-AUDIT PRE`
→ فهم الوظيفة
→ جمع المصادر
→ مقارنة Historical / Original / Current / Production Evidence المرسلة
→ Loss / Gain Matrix
→ Target Contract
→ Surgical Patch
→ Test
→ Production Evidence من المالك
→ SELF-AUDIT FINAL
→ 100% Close
→ التالي

المساعد لا يعلن Production facts من تلقاء نفسه لأنه لا يملك وصولًا مباشرًا.

عندما يحتاج Evidence من Production، يطلب **الاستعلام/لقطة/الملف المحدد فقط**، وليس إعادة شرح المشروع.

---

# 7. المخرجات الإلزامية القصيرة

قبل التنفيذ:

- فهم الدالة.
- مصادرها.
- المخاطر.
- خطة الجراحة.
- ما يحتاجه من ملفات إضافية إن وجد.

بعد التنفيذ:

- ماذا تغير.
- أين تغير.
- ما الذي حُفظ.
- ما الذي نُقل إلى Core.
- الاختبارات.
- Evidence المطلوبة من المالك.
- الحالة الحقيقية: `CURRENT / STAGING / PRODUCTION / CLOSED`.

---

# 8. القاعدة الذهبية

**المساعد لا يحمل ديونًا إلى الأمام.**

إذا ظهرت مشكلة داخل Closure Unit، فتعالج داخلها قبل الانتقال، مع الحفاظ على النطاق وعدم تحويل الإصلاح إلى إعادة تصميم للكون كله.
