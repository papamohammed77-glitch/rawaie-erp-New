# RAWAEA ERP — حزمة تهيئة مساعد الرسائل الداخلية

**التاريخ:** 2026-08-15  
**الغرض:** تهيئة مساعد ذكاء اصطناعي جديد يعمل حصريًا عبر الملفات/الرسائل الداخلية، دون وصول مباشر إلى GitHub أو Supabase أو PostgreSQL أو الويب.

> **قاعدة مهمة:** هذه الحزمة تُعطي المساعد سياق المشروع والخطة والتنفيذ والحالة. لا يجوز له الادعاء بأنه تحقّق من Production مباشرةً؛ أي معلومة Production داخل الحزمة هي **لقطة Evidence مؤرخة** وليست حقيقة أبدية. عند تعارض لقطة قديمة مع لقطة أحدث، الأحدث هو المرجع.

---

# 1. ترتيب القراءة الإلزامي

## المستوى الأول — فهم المشروع والسلطة المعمارية

### 1. `CTO/00_MASTER_CONTEXT.md`
المرجع الأعلى لفهم المشروع، هرم الحقيقة، مبدأ **ONE CORE / ONE SOURCE OF TRUTH**، ونطاق الإنقاذ. urlفتح الملفhttps://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/CTO/00_MASTER_CONTEXT.md

### 2. `CTO/01_SOURCE_AUTHORITY_MAP.md`
خريطة مصادر الحقيقة: Production Evidence، RPC، Current، Historical، migrations، والمعمارية. urlفتح الملفhttps://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/CTO/01_SOURCE_AUTHORITY_MAP.md

### 3. `Governance/RAWAEA_ARCHITECTURE_CONSTITUTION.md`
القوانين المعمارية الحاكمة: Single Source of Truth، Core ownership، Inventory engine، عدم تكرار Business Logic. urlفتح الدستورhttps://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/Governance/RAWAEA_ARCHITECTURE_CONSTITUTION.md

### 4. `Governance/EXECUTION_PROTOCOL.md`
طريقة العمل الإلزامية: Inspect → Understand → Plan → Implement → Test → Verify → Review → Deploy. urlفتح البروتوكولhttps://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/Governance/EXECUTION_PROTOCOL.md

### 5. `doc/CTO VISION REPORT.md`
رؤية المالك/CTO والاتجاه طويل المدى. urlفتح التقريرhttps://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/CTO%20VISION%20REPORT.md

### 6. `doc/CTO RECONSTRUCTION REPORT.md`
إعادة بناء السياق والقرارات التاريخية. urlفتح التقريرhttps://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/CTO%20RECONSTRUCTION%20REPORT.md

### 7. `doc/تقرير CTO الشامل.md`
الصورة الشاملة للمشروع ومشكلة Distributed Business Logic وخطة الإنقاذ. urlفتح التقريرhttps://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/%D8%AA%D9%82%D8%B1%D9%8A%D8%B1%20CTO%20%D8%A7%D9%84%D8%B4%D8%A7%D9%85%D9%84.md

---

# 2. الخطة التنفيذية

### 8. `doc/خطة تنفيذية مرحلية - المرحلة الأولي المجزئة.md`
التفتيت المرحلي من Inventory Core إلى Vouchers ثم Loading/Unloading ثم Van Sales ثم Edge/Accounting/Final Proof. urlفتح الخطةhttps://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/%D8%AE%D8%B7%D8%A9%20%D8%AA%D9%86%D9%81%D9%8A%D8%B0%D9%8A%D8%A9%20-%20%D8%A7%D9%84%D9%85%D8%B1%D8%AD%D9%84%D8%A9%20%D8%A7%D9%84%D8%A3%D9%88%D9%84%D9%8A%20%D8%A7%D9%84%D9%85%D8%AC%D8%B2%D8%A6%D8%A9.md

> **ملاحظة:** مسار الملف أعلاه قد يحتاج مطابقة الاسم الحالي في المستودع إذا كان قد تغير. استخدم نتيجة `CTO/02_HISTORICAL_KNOWLEDGE_INDEX.md` كفهرس إضافي.

### 9. `CTO/MASTER-EXECUTION-LOG.md`
السجل الرئيسي للتنفيذ والتقسيم والمبادئ التنفيذية. urlفتح السجلhttps://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/CTO/MASTER-EXECUTION-LOG.md

### 10. `CTO/02_EXECUTION_LOG.md`
السجل الزمني للتنفيذ الفعلي، والاختبارات، والقرارات، وProduction evidence. urlفتح السجلhttps://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/CTO/02_EXECUTION_LOG.md

### 11. `CTO/03_CURRENT_STATUS.md`
حالة الإنقاذ الحالية والمشاكل المتعارضة أو المفتوحة. urlفتح الملفhttps://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/CTO/03_CURRENT_STATUS.md

### 12. `CTO/05_TRUTH_RECONCILIATION.md`
سجل التناقضات بين التاريخ، الكود الحالي، Production، والتصميم المستهدف. urlفتح السجلhttps://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/CTO/05_TRUTH_RECONCILIATION.md

---

# 3. أحدث لقطة للحالة التنفيذية

### 13. `CTO/RESCUE-RECONCILIATION-2026-08-15.md`
**هذه أهم وثيقة للحالة الأخيرة المعروفة في المستودع.** تحتوي على Reality Matrix لـ`complete-picking` و`send-stock-voucher` وترتيب Zero-Debt. urlفتح الوثيقةhttps://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/CTO/RESCUE-RECONCILIATION-2026-08-15.md

لكن يجب على المساعد الجديد فهم أن هذه الوثيقة هي **لقطة مؤرخة**، وليست بديلًا عن Evidence أحدث يقدمه المالك.

### 14. `CTO/02_HISTORICAL_KNOWLEDGE_INDEX.md`
فهرس المعرفة التاريخية، ويجب الرجوع إليه لاكتشاف التقارير والوثائق والـEdge Functions القديمة. urlفتح الفهرسhttps://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/CTO/02_HISTORICAL_KNOWLEDGE_INDEX.md

---

# 4. التاريخ والنسخ الأصلية

### 15. `Edge_Function_Reports/_HISTORICAL/RAWAEA ERP HANDOVER.md`
التسليم الفني المؤسسي: فلسفة المشروع، جميع الـEdge Functions، قاعدة البيانات، المعمارية، Known Issues، والتصميم التاريخي. urlفتح التسليمhttps://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/Edge_Function_Reports/_HISTORICAL/RAWAEA%20ERP%20HANDOVER.md

### 16. المستودع التاريخي `rawaie-erp-review/Edge_Functions/`
هذا المصدر **إلزامي** لاسترجاع النسخ الأصلية عندما تكون غير موجودة في `rawaie-erp-New/Original`.

يحتوي على:

- `Edge_Functions/original/` — النسخ الأصلية التاريخية.
- `Edge_Functions/current/` — نسخ حالية/مرجعية في مستودع المراجعة التاريخي.
- `Edge_Functions/archive/` — الأرشيف.

urlفتح مجلد Edge_Functions التاريخيhttps://github.com/papamohammed77-glitch/rawaie-erp-review/tree/rescue/manual-vouchers-inventory-core/Edge_Functions

### 17. Batch Reports
`Edge_Function_Reports/_HISTORICAL/Batch01.md` … `Batch15.md`

استخدمها لمعرفة وظائف الدوال واعتمادياتها والمشاكل التي اكتشفت تاريخيًا.

### 18. `CTO/04_PROJECT_SOURCE_INVENTORY.md`
فهرس كل PWA، Edge Functions، SQL Evidence، Architecture، والمصادر التاريخية. urlفتح الفهرسhttps://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/CTO/04_PROJECT_SOURCE_INVENTORY.md

---

# 5. ملفات قواعد البيانات والأدلة

### 19. `SQL_Evidence/`
أهم ما يجب تضمينه للمساعد:

- `SQL_Evidence/schema/tables.csv`
- `Foreign Keys.csv`
- `Indexes.csv`
- `Primary Keys.csv`
- `Enum Types.csv`
- `Database Functions.csv`
- `استعلام RLS Policies.csv`
- مجلد `SQL_Evidence/diagnostics/`

### 20. `Inventory/`
كل العقود والتحليلات الخاصة بالـInventory Rescue.

### 21. `supabase/`
المigrations والمصدر البرمجي لقاعدة البيانات، مع قاعدة صارمة: **migration غير المنشورة ليست Production truth**.

---

# 6. تطبيقات النظام ومستهلكو الـEdge Functions

### 22. `Current/PWA/`
المصدر الحالي للتطبيقات.

الأهم للمخازن:

- `PWA/warehouse/picker.html`
- `PWA/warehouse/loader.html`
- `PWA/warehouse/receiver.html`
- `PWA/warehouse/unloader.html`
- `PWA/warehouse/returns.html`
- `PWA/warehouse/counter.html`
- `PWA/warehouse/manager.html`
- `PWA/warehouse/supervisor.html`

وللمبيعات:

- `PWA/sales/van-sales.html`
- `PWA/sales/pos.html`
- `PWA/sales/telesales.html`
- `PWA/sales/order-taker.html`

وللتسليم:

- `PWA/delivery/driver.html`
- `PWA/delivery/supervisor.html`

### 23. `Current/Edge_Functions/`
هذا هو المصدر الرسمي للنسخ النهائية المعتمدة التي يجب أن تكون موجودة في Current.

لا يُسمح بتشعب المستودعات أو إنشاء نسخ غير منضبطة لنفس الدالة.

---

# 7. اللائحة الحالية لأهم دوال الإنقاذ

هذه **لقطة Production مباشرة حديثة** يجب استخدامها كمرجع زمني، لا كبديل عن أدلة أحدث.

| Edge Function | Production Version | آخر وضع معروف |
|---|---:|---|
| `start-picking` | 14 | إصلاح user/company context منشور؛ خطأ `users_email_key` عولج؛ يلزم إغلاق Cleanup/Governance إذا بقيت harnesses |
| `complete-picking` | 13 | منشورة ومختبرة؛ وحدة الإغلاق كانت قيد المراجعة النهائية |
| `start-loading` | 4 | منشورة ضمن مسار Loading rescue |
| `complete-loading` | 10 | Thin Wrapper منشورة؛ Core مركزي؛ لا تُعتبر Current وProduction متطابقتين دون مطابقة SHA/المحتوى |
| `reopen-loading` | 2 | منشورة؛ دورة Loading الجديدة ومعالجة Reopen/Reload جزء من rescue |
| `unload-runsheet` | 5 | منشورة؛ عكس Loading عبر Core |
| `send-stock-voucher` | 7 | منشورة على Central Stock Engine؛ Current-source alignment وRelease evidence بحاجة متابعة |
| `receive-stock-voucher` | 5 | منشورة؛ Closure Unit لاحقة |
| `receive-purchase` | 9 | منشورة؛ Closure Unit لاحقة |
| `bulk-stock-adjustment` | 5 | منشورة؛ Closure Unit لاحقة |
| `save-sales-invoice` | 13 | منشورة؛ إصلاح VanSale double-deduction جزء من rescue |
| `complete-return` | 23 | منشورة؛ Central movement routing جزء من rescue |
| `complete-order-delivery` | 11 | منشورة؛ إصلاح VAN physical deduction جزء من rescue |
| `create-runsheet` | 22 | موجودة في Production؛ تعتمد عليها دورة Runsheet/Picking |

### Core Inventory

- `post_stock_movement` = Central Physical Stock Movement Engine.
- `reserve_stock` = Reservation Engine، وليس Physical Movement.
- `setup_van_stock` = Initialization فقط إذا أثبت الدليل ذلك.
- `order_details` = authoritative fulfillment quantity layer في مسارات rescue التي تم إثباتها.
- `run_sheet_details` = derived aggregate عندما يكون trigger `sync_run_sheet_details` هو المصدر المشتق المؤكد.

---

# 8. خطة الإنقاذ — ما تم تثبيته وما يزال يحتاج الإغلاق

## مكتمل/مثبت فعليًا بدرجة عالية

### Inventory Core
`post_stock_movement` موجود في Production ويُستخدم في مسارات الحركة التي تم إصلاحها.

### Picking/Loading rescue
تم نشر وإثبات مسارات فعلية لـ:

`start-picking → complete-picking → start-loading → complete-loading → reopen-loading → reload → unload-runsheet`

مع Production HTTP evidence لبعض المسارات وسجلات runtime محفوظة.

### Centralization
تم توجيه عدد من مسارات المخزون الرئيسية إلى `post_stock_movement` بدل الكتابة المباشرة، ومنها:

- SEND Voucher
- RECEIVE Voucher
- Purchase Receiving
- Inventory Adjustment
- Sales / VanSale
- Returns
- Delivery / VanSale

لكن **Global Inventory Rescue = لم تُغلق 100% بعد**.

## Queue الحالية للـZero-Debt

1. `complete-picking` — آخر إغلاق موثق.
2. `send-stock-voucher` — patch/review/verification حسب آخر snapshot.
3. `receive-stock-voucher`.
4. `receive-purchase`.
5. `bulk-stock-adjustment`.
6. `save-sales-invoice`.
7. `complete-return`.
8. `complete-order-delivery`.
9. **Global Physical Stock Writer Sweep**.
10. بعد تثبيت Inventory: Accounting → Ledger → بقية Domains.

> إذا وصلت للمساعد Evidence أحدث من هذه اللائحة، **Evidence الأحدث تتفوق عليها فورًا**.

---

# 9. تناقضات الحالة التي يجب ألا يخفيها المساعد الجديد

هناك مستندات `main` تحمل حالة أقدم من الواقع الأخير. مثال مباشر: `CTO/PLAN-STATUS-CURRENT.md` ما زال يعرض نقطة تنفيذ أقدم في الخطة.

لذلك:

**لا تستخدم ملف خطة قديم وحده لتحديد ما تم تنفيذه.**

يجب ترتيب الحقيقة هكذا:

1. أحدث Production Evidence مقدّم للرسائل الداخلية.
2. أحدث deployed Edge snapshot مقدّم للرسائل الداخلية.
3. أحدث deployed RPC/schema snapshot.
4. Latest Current source.
5. أحدث Closure Report.
6. `CTO/RESCUE-RECONCILIATION-2026-08-15.md`.
7. بقية الوثائق.

إذا ظهر تعارض، سجله صراحة ولا تحله بالتخمين.

---

# 10. منهج العمل للمساعد الجديد

لكل Closure Unit واحدة فقط:

`PRE-CHANGE SELF-AUDIT`
→ `READ ALL RELEVANT SOURCES`
→ `HISTORICAL / ORIGINAL / CURRENT / PRODUCTION RECONCILIATION`
→ `LOSS / GAIN MATRIX`
→ `TARGET CONTRACT`
→ `SURGICAL PATCH`
→ `TEST`
→ `ACTUAL PRODUCTION VERIFICATION`
→ `FINAL SELF-AUDIT`
→ `100% CLOSE`
→ `NEXT UNIT`

ممنوع:

- اعتبار التقرير دليلًا على التنفيذ.
- اعتبار Staging = Production.
- إعلان 100% مع Unknown أو Unverified.
- التوقف عند عائق قبل استنفاد الحلول المتاحة.
- نقل النقص إلى Task لاحقة.
- إنشاء repository أو source-of-truth جديد دون قرار.
- تعديل UI/Golden application قبل إثبات أن المشكلة فيه.
- حذف Original لأنه قديم.
- استخدام migration غير منشورة كدليل Production.

---

# 11. حزمة الملفات التي يجب إعطاؤها للمساعد الجديد

**الترتيب العملي المقترح:**

1. `CTO/00_MASTER_CONTEXT.md`
2. `CTO/01_SOURCE_AUTHORITY_MAP.md`
3. `Governance/RAWAEA_ARCHITECTURE_CONSTITUTION.md`
4. `Governance/EXECUTION_PROTOCOL.md`
5. `doc/CTO VISION REPORT.md`
6. `doc/CTO RECONSTRUCTION REPORT.md`
7. `doc/تقرير CTO الشامل.md`
8. `doc/خطة تنفيذية مرحلية - المرحلة الأولي المجزئة.md`
9. `CTO/MASTER-EXECUTION-LOG.md`
10. `CTO/02_EXECUTION_LOG.md`
11. `CTO/03_CURRENT_STATUS.md`
12. `CTO/05_TRUTH_RECONCILIATION.md`
13. `CTO/RESCUE-RECONCILIATION-2026-08-15.md`
14. `CTO/02_HISTORICAL_KNOWLEDGE_INDEX.md`
15. `CTO/04_PROJECT_SOURCE_INVENTORY.md`
16. `Edge_Function_Reports/_HISTORICAL/RAWAEA ERP HANDOVER.md`
17. `Edge_Function_Reports/_HISTORICAL/Batch01.md` … `Batch15.md`
18. `Edge_Function_Reports/_HISTORICAL/INV-001 — INVENTORY REALITY MAP.md`
19. `Edge_Function_Reports/_HISTORICAL/INV-002 — INVENTORY SOURCE OF TRUTH.md`
20. `SQL_Evidence/schema/*`
21. `SQL_Evidence/diagnostics/*`
22. `Inventory/*`
23. `supabase/migrations/*` ذات الصلة بالمرحلة الحالية
24. **Historical Edge Functions** للدالة محل الإغلاق من `rawaie-erp-review/Edge_Functions/original/`
25. **Current Edge Function** نفسها من `Current/Edge_Functions/`
26. **Current PWA consumer** للدالة نفسها
27. **آخر Production Edge snapshot** (source/version/hash)
28. **آخر Production RPC/schema/trigger snapshot** للدالة نفسها
29. أي تقرير Closure سابق للدالة نفسها

---

# 12. مبدأ استخدام هذه الحزمة

المساعد الجديد **لا يحتاج إلى معرفة كل ملفات المشروع دفعة واحدة**.

ابدأ بحزمة القراءة أعلاه، ثم في كل Closure Unit أرسل له فقط الملفات الخاصة بالدالة ومستهلكها وCore الخاص بها، مع آخر Production snapshots المرتبطة بها.

بهذا نحقق:

**فهم شامل للمشروع + عمل قطعة قطعة + عدم ضياع المعرفة + عدم خلط النظري بالمنفذ + عدم نقل الدين إلى الأمام.**

---

# 13. تنبيه مهم حول لقطات Production

تم تضمين أرقام الإصدارات الحالية المعروفة وقت إعداد هذه الحزمة من فحوص Production المباشرة السابقة.

لكن المساعد الجديد لا يملك Supabase، لذلك يجب تحديث هذا القسم برسالة داخلية جديدة عند حدوث نشر لاحق.

لا يجوز له تحويل هذا الملف إلى بديل دائم عن Production Evidence.

---

# 14. قاعدة النهاية

**نحن لا نريد مساعدًا يحفظ التقارير. نريد مساعدًا يفهم المشروع، يعرف أين توجد الحقيقة، ويعمل على Closure Unit واحدة حتى 100% دون تخمين أو كذب أو تدوير أو نقل نقص إلى الأمام.**
