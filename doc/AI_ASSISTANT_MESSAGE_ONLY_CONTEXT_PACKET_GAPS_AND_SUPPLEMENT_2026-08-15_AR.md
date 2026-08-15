# RAWAEA ERP — ملحق فجوات حزمة السياق لمساعد CTO الرسائل الداخلية

**التاريخ:** 2026-08-15
**الغرض:** استكمال `AI_ASSISTANT_MESSAGE_ONLY_CONTEXT_PACKET_MASTER_2026-08-15_AR.md` دون تكراره.

---

# 1. لماذا هذا الملحق ضروري؟

الحزمة الرئيسية قوية في القواعد المعمارية والمنهجية، لكنها كانت تحتاج إلى ثلاث طبقات إضافية حتى يكون المساعد الجديد قادرًا على العمل بكفاءة عبر الرسائل فقط:

1. **خريطة إرسال مختصرة** تقلل عدد الرسائل.
2. **حالة تنفيذية حديثة** تمنع الخلط بين snapshots القديمة والحالة الأحدث.
3. **بروتوكول Evidence من المالك** عندما يحتاج المساعد إثباتًا من Production لأنه لا يملك وصولًا مباشرًا.

---

# 2. قاعدة الحالة الزمنية

الوثائق التاريخية لا تُساوى ببعضها.

عند إرسال عدة تقارير متعارضة للمساعد، استخدم القاعدة التالية:

`Latest direct Production evidence sent by owner`

ثم:

`Latest current source`

ثم:

`Latest approved reconciliation`

ثم:

`Architecture Constitution / ADRs`

ثم:

`Historical evidence`

ولا يجوز للمساعد دمج أرقام قديمة مع أرقام جديدة ثم إنتاج حالة وسطية من عنده.

---

# 3. الحالة التنفيذية التي يجب نقلها للمساعد الجديد

آخر Reconciliation تنفيذي مرسل في المشروع بتاريخ 2026-08-15 يقرر:

### `complete-picking`

**100% CLOSED / PRODUCTION RUNTIME VERIFIED** في آخر reconciliation.

العقد:

`Picking = Reservation`

ولا يجب تسجيل Physical Stock Movement عند Picking.

### `send-stock-voucher`

Production implementation على version 7، والـCurrent تم مواءمته مع Production Adapter في rescue branch، لكنه يحتاج review/verification قبل اعتبار Current source مغلقًا نهائيًا.

### الوحدات التالية

1. `receive-stock-voucher`
2. `receive-purchase`
3. `bulk-stock-adjustment`
4. `save-sales-invoice`
5. `complete-return`
6. `complete-order-delivery`
7. Global Physical Stock Writer Sweep

**لا يجوز اعتماد هذه القائمة كحقيقة Production إذا وصل للمساعد Evidence أحدث تنقضها.**

---

# 4. حادثة مهمة يجب أن يعرفها المساعد

حدث خطأ Production حقيقي عند تجربة `picker.html`:

`duplicate key value violates unique constraint "users_email_key"`

سبب الخطأ كان في `start-picking` وليس `picker.html`:

النسخة القديمة كانت تستخدم:

`app_settings.limit(1)` لتحديد الشركة، ثم تبحث في `users` بـ`email + company_id`، وإذا لم تجد المستخدم تحاول `INSERT`، فتفشل إذا كان البريد موجودًا أصلًا بسبب `users_email_key`.

تم لاحقًا إصلاح المسار إلى:

`auth.users.id → public.users.id → public.users.company_id → company-scoped runsheet`

وهذا مثال إلزامي للمساعد على الفرق بين:

`SOURCE ISSUE`
و
`CONSUMER ISSUE`

لا تعدّل التطبيق قبل إثبات أن العيب فيه.

---

# 5. قاعدة ملفات التطبيقات الذهبية/الماسية

بعض ملفات PWA تعتبر **Artifacts عالية الحساسية**.

مثل:

- `PWA/warehouse/picker.html`
- `PWA/warehouse/loader.html`
- `PWA/warehouse/receiver.html`
- `PWA/warehouse/unloader.html`
- `PWA/warehouse/returns.html`
- `PWA/warehouse/vouchers.html`
- `PWA/sales/van-sales.html`

القاعدة:

**لا تُعدّل هذه الملفات لمجرد ظهور خطأ API.**

نفذ:

`Consumer Contract Audit`
→ `Edge Contract Audit`
→ `Core Audit`

ثم لا تُجرى إلا **Surgical Patch** إذا أثبتت الأدلة أن المشكلة في التطبيق نفسه.

---

# 6. بروتوكول Evidence من المالك

لأن المساعد الجديد لا يملك وصولًا مباشرًا:

عند الحاجة إلى Production، يطلب المساعد من المالك **شيئًا واحدًا أو مجموعة صغيرة محددة**.

أمثلة:

### لفحص Edge Function

- نسخة الملف المنشور.
- Version.
- SHA إن توفر.

### لفحص Core

- `pg_get_functiondef(...)`
- signatures.
- privileges.

### لفحص Schema

- تعريف الجدول.
- constraints.
- indexes.
- triggers.

### لفحص Runtime

- Console log.
- Edge log.
- قبل/بعد من الجداول الأساسية.

**لا يطلب المساعد إعادة كل ملفات المشروع إذا كان يحتاج ملفًا واحدًا فقط.**

---

# 7. حزمة الرسالة الذكية

لخفض عدد الرسائل، يمكن للمالك إرسال في الرسالة الواحدة:

### Closure Unit واحدة

- Original Function.
- Current Function.
- Production Function snapshot.
- Core RPC definition.
- Relevant schema/trigger evidence.
- Consumer file.
- آخر تقرير مرتبط بها.

هذه هي **أفضل حزمة رسالة واحدة** للمراجعة والتنفيذ.

---

# 8. ما الذي لا يجب أن يفعله المساعد الجديد

ممنوع:

- إعادة الاستكشاف الكامل بعد كل رسالة.
- إعادة طلب ملفات سبق إرسالها.
- فتح Task جديدة قبل إغلاق الحالية.
- اعتبار غياب `Original` في مكان واحد دليلًا على عدم وجوده.
- اعتبار migration = Production.
- اعتبار `ACTIVE` = صحيح.
- اعتبار `HTTP 200` = سلامة المخزون.
- اعتبار `Staging PASS` = Production PASS.
- اعتبار التقرير Evidence.
- إنشاء نسخ متكررة للدالة في عدة أماكن بلا سبب.
- ترك artifact النهائي خارج `Current`.

---

# 9. اختبار ذاتي إجباري للمساعد

قبل كل Closure Unit يجب أن يسأل نفسه:

### هل أعرف؟

- الوظيفة؟
- العقد؟
- كل المسؤوليات القديمة؟
- كل المسؤوليات الجديدة؟
- مصدر الحقيقة؟
- Core؟
- Consumer؟
- Production Evidence المطلوبة؟

إذا كانت الإجابة لا:

**يحدد ما ينقصه تحديدًا، ثم يطلبه، ولا يبدأ التخمين.**

وبعد التنفيذ:

### هل أنجزت؟

- المصدر؟
- Current artifact؟
- Core؟
- الاختبارات؟
- Production verification؟
- cleanup؟
- report؟

أي `NO` مؤثر = `INCOMPLETE`.

---

# 10. لاختصار التنفيذ

لا نحتاج نقل كل ملفات النظام إلى المساعد الجديد دفعة واحدة.

الهدف هو:

**Context Core أولًا → Closure Unit الحالية ثانيًا → الوحدة التالية لاحقًا.**

بهذا نحافظ على رصيد الرسائل ونمنع غرق المساعد في التاريخ غير الضروري.

---

# 11. معيار النجاح للمساعد الجديد

المساعد الناجح يجب أن يعمل بهذا الشكل:

`Read the packet`
→ `Understand authority`
→ `Understand rescue architecture`
→ `Accept one closure unit`
→ `Ask only for missing evidence`
→ `Compare`
→ `Repair`
→ `Verify`
→ `Close 100%`
→ `Next closure unit`

وليس:

`Read report`
→ `repeat report`
→ `discover blocker`
→ `stop`
→ `new report`

---

# 12. مبدأ الخلاصة

**المساعد ليس مطلوبًا منه أن يعرف كل تاريخ المشروع بنفس الدرجة.**

المطلوب أن يعرف:

- من أين يأخذ الحقيقة.
- كيف يحدد نطاق Closure Unit.
- كيف يقارن النسخ.
- كيف ينقل المسؤولية دون فقدها.
- كيف يثبت Production.
- كيف لا يخدع نفسه ولا المالك.
- وكيف يخلص الصخرة قطعةً قطعةً حتى لا يبقى دين.
