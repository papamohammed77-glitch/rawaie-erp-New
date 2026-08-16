# MANDATORY CTO RESCUE EXECUTION DIRECTIVE

## قرار حاسم

تقرير `CTO_AUTONOMOUS_QUALIFICATION_AUDIT_2026-08-16` **ليس تصريحًا بإيقاف العمل**.

عبارة:

`NOT QUALIFIED — SUPERVISION REQUIRED`

لا تعني:

`STOP`

ولا تعني:

`BLOCKED`

بل تعني:

> **هناك Gates غير مغلقة يجب عليك إغلاقها بالتنفيذ الفعلي.**

أنت تعمل تحت إشراف المالك وCTO، لكنك **مُطالب بالتصرف التنفيذي الكامل** وليس إعداد قوائم نواقص ثم التوقف.

---

# 1. المرحلة الحالية

نحن داخل:

# `INVENTORY RESCUE — TASK-028 / ZERO-DEBT EXECUTION`

ولا تفتح Task جديدة لمجرد وجود نقص.

ولا تعيد الاستطلاع من الصفر.

المطلوب:

`DISCOVER → REPAIR → TEST → DEPLOY → VERIFY → CLOSE → NEXT`

---

# 2. الست فجوات التي اكتشفها Audit

هذه ليست Blockers توقف العمل؛ هذه **Work Items إلزامية**:

1. Fresh Production HTTP E2E + concurrency.
2. Inventory-wide PWA consumer tracing.
3. Git → Production artifact provenance.
4. Global writer proof خارج stored-function layer.
5. حذف الـACTIVE harnesses.
6. إغلاق بقية Inventory Closure Units، وفي مقدمتها `receive-stock-voucher`.

---

# 3. لا تتوقف عند اكتشاف المشكلة

عند وجود:

`DEFECT`

نفذ فورًا:

`ROOT CAUSE`
→ `SURGICAL FIX`
→ `TEST`
→ `DEPLOY`
→ `VERIFY`

ولا تكتب:

`BLOCKED`

إلا بعد استنفاد **كل** وسائل الحل المتاحة.

إذا كانت هناك خطوة تحتاج إجراءً يدويًا من المالك:

- حدد الإجراء المطلوب بدقة.
- اذكر لماذا.
- **واصل فورًا كل الأعمال التي لا تعتمد عليه.**

ممنوع جعل إجراء واحد يوقف الخطة كلها.

---

# 4. الأولوية الفورية

## Closure Unit 1 — `receive-stock-voucher`

Audit الحالي أثبت وجود:

- Current/Production drift.
- Core idempotency risk في repeated partial receive operations.

إذن:

### ابدأ بـ`receive-stock-voucher` الآن.

نفذ:

Historical
→ Original / Historical baseline
→ Current
→ Production
→ Core
→ Consumers
→ Surgical repair
→ Staging E2E
→ Production E2E
→ Close 100%

ولا تنتقل إلى الدالة التالية حتى تغلقها.

---

# 5. وبعدها

بالترتيب:

`send-stock-voucher`
→ `receive-purchase`
→ `bulk-stock-adjustment`
→ `save-sales-invoice`
→ `complete-return`
→ `complete-order-delivery`

ثم:

# GLOBAL INVENTORY WRITER SWEEP

ويشمل:

- PostgreSQL functions.
- Edge Functions.
- PWA/HTML/JS.
- dynamic SQL.
- RPC callers.
- application-side direct table writes.

**لا تستخدم غياب نتيجة GitHub search كدليل على غياب Writer.**
استخدم أدوات متعددة ومصادر مباشرة.

---

# 6. Consumer Trace

يجب بناء خريطة فعلية:

```text
PWA / HTML / JS
   ↓
Edge Function
   ↓
RPC / Core
   ↓
DB
```

لكل Inventory-related operation.

أي Consumer غير معروف:

`OPEN`

ثم يتم العثور عليه وإغلاقه.

لا تقول:

`CONSUMER TRACE INCOMPLETE`

وتتوقف.

---

# 7. Provenance

لكل Production Edge Function ذات صلة:

- Current file path.
- Current Git blob SHA.
- Commit SHA.
- Production version.
- Production `ezbr_sha256`.
- Evidence linking deployed artifact إلى المصدر.

**لا تساوي `ezbr_sha256` مع Git commit SHA دون إثبات.**

إذا كانت provenance غير قابلة للإعادة:

أنشئ سلسلة provenance قابلة للتدقيق في Git.

---

# 8. Harnesses

`ACTIVE + 410` **ليس Deleted**.

يجب:

1. حصر كل temporary harness.
2. إثبات وظيفته.
3. حذف Registry object فعليًا عندما تكون الأداة/الصلاحية تسمح.
4. إعادة `list_edge_functions`.
5. إثبات `NOT PRESENT`.

إن احتاج الحذف إجراءً يدويًا من المالك، **اطلبه فورًا** ولا توقف بقية العمل.

---

# 9. Production E2E

نستخدم:

**البيانات التجريبية الموجودة أصلًا** أو Fixture معزولًا ومؤقتًا.

لا تحتاج إلى اختراع عالم جديد.

المطلوب:

```text
Real Application / HTTP
→ Auth
→ Edge
→ Core
→ DB
→ Response
```

وعند الحاجة:

- Normal.
- Retry.
- Duplicate.
- Concurrent.
- Failure.
- Rollback.
- Baseline restoration.

---

# 10. Inventory Contract

العقد الثابت:

```text
Physical Movement
→ post_stock_movement

Reservation
→ reserve_stock / release_stock_reservation

available_qty
= qty - allocated_qty
```

أي Function تتجاوز هذا العقد:

**يجب إصلاحها أو تصنيفها Initialization/Read-only/Reservation بعد إثبات ذلك.**

---

# 11. لا تختلق حلًا، ولا تختلق عذرًا

ممنوع:

- ادعاء 100%.
- ادعاء Deleted بدون حذف.
- ادعاء Production Verification من Staging.
- ادعاء provenance بلا دليل.
- إخفاء defect داخل Self-Audit.
- التوقف لأن أداة واحدة ناقصة.
- انتظار المالك لإحضار ملف يستطيع CTO العثور عليه.

---

# 12. Self-Audit

## بداية كل Closure Unit

يجب تقديم:

```text
Business Understanding
Architecture Understanding
Database Understanding
Historical Understanding
Production Understanding
Current Understanding
Execution Confidence

Confirmed Facts
Unknowns
Conflicts
Unverified Claims
```

لكن الدرجات **لا قيمة لها وحدها**.

كل درجة يجب أن تستند إلى أدلة.

## نهاية كل Closure Unit

يجب تقديم:

```text
What I Proved
What I Did Not Prove
What I Fixed
What I Initially Missed
What Could Still Be Wrong
Final Confidence
Final Closure Status
```

---

# 13. معيار 100%

لا تكتب:

`100% CLOSED`

إلا عندما تكون:

- Current artifact final.
- Original/Historical comparison complete.
- Core complete.
- Dependencies complete.
- Consumers complete.
- Static complete.
- Staging complete.
- Production E2E complete.
- Concurrency complete.
- Baseline restored.
- Provenance complete.
- Governance complete.

---

# 14. نقطة الانطلاق الآن

**ابدأ فورًا بـ`receive-stock-voucher`.**

ولا تقدم تقرير تأهيل جديدًا.

لا أريد:

`QUALIFIED / NOT QUALIFIED`

أريد:

# `EXECUTED / VERIFIED / CLOSED`

ثم انتقل للدالة التالية فقط بعد إغلاق الحالية.

**الهدف النهائي:**

# `ZERO-DEBT INVENTORY RESCUE — PRODUCTION VERIFIED`