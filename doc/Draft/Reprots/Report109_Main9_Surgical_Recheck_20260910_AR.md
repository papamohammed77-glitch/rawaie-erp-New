# تقرير 109 — إعادة الفحص الجراحي لـ Main9
## 2026-09-10

### الحالة المرجعية
- المستودع: `papamohammed77-glitch/rawaie-erp-New`
- الملف: `Current/PWA/main2/main9.md`
- SHA الحالي المقروء من Git: `a2e9c927e9e5051a0707a5492844279e66ce69f4`
- Main2 الحالي: `_rwCompanyId()` يعتمد على `RW_STATE.app.company.id`.
- عقد Item Master الحالي: `items.item_code` عليه `UNIQUE` عالمي.

### نتيجة إعادة الفحص

#### 1) `_companyId()`
الحالة: **صحيح حاليًا — لا تعدّل**.

النسخة الحالية بالفعل تحاول بالترتيب:
1. `RW_STATE.app.company.id`
2. `RW_STATE.app.companyId`
3. `RW_STATE.user.companyId`
4. خطأ صريح عند غياب السياق.

إذن لا توجد جراحة مطلوبة هنا.

#### 2) `_appendOptions()`
الحالة: **صحيح حاليًا — لا تعدّل**.

النسخة الحالية تحفظ placeholder الفارغ، تمسح الخيارات السابقة، ثم تضيف نتائج Production الحالية. وهذا يحقق شرط إعادة الفتح idempotently الوارد في تقرير المراجعة.

#### 3) `_generateReport()`
الحالة: **DEFECTIVE — SURGICAL REPLACEMENT REQUIRED**.

الخلل المثبت في النسخة الحالية هو أن الدالة تحتوي قراءات غير مربوطة بسياق الشركة، أو تعتمد على `RW_STATE.data.*` كمصدر تقرير، أو تستخدم `order_details` مباشرة دون تقييدها من خلال Order IDs التابعة للشركة الحالية.

القراءات المعيبة المثبتة:
- `orders` بدون `company_id` في عدة تقارير مبيعات.
- `order_details` مباشرة حسب التاريخ في `sales-by-item`.
- `customer_ledger` باستخدام UUID مقدم دون إثبات العميل داخل الشركة.
- `runsheets` بدون `company_id` في تقارير الأداء.
- `stock_branches` بدون تقييد فروع مملوكة للشركة.
- `inventory_log` بواسطة `item_code` فقط.
- `RW_STATE.data.items` و`RW_STATE.data.customers` كمصدر تقرير.
- `purchase_orders` دون `company_id`.
- `receiving_details` مباشرة رغم أن هوية الشركة موجودة في `receiving.operation_id`.
- `journal_lines` دون حصر `journal_entries` بالشركة.
- `cash_box` دون التحقق المستقل من ملكية `treasury` داخل الشركة.
- `daily_settlements` و`users` و`runsheets` دون Company Scope.
- المرتجعات تعتمد على `stock_vouchers.type = 'Return'` رغم أن دلالات الحركة الحالية هي `SalesReturn` / `DirectReturn`.

### الجراحة المعتمدة
**حذف الدالة الحالية `_generateReport(sectionKey, reportId)` بالكامل واستبدالها بالنسخة الكاملة الموجودة في ملف الجراحة المسجل مع هذا التقرير.**

لا تُحذف أو تُعاد كتابة:
- `_companyId()`
- `_appendOptions()`
- `_loadDashboardData()`
- `_loadDetailedReports()`
- دوال Drill-Down الصحيحة
- `RW_Reports`
- أي wrapper أو assignment خارج حدود الدالة المستهدفة.

### عقد البديل
البديل الكامل يضمن:
- Company Context من `_companyId()`.
- منع `RW_STATE.data.*` كمصدر تقرير عند وجود Production source.
- Company scope لكل الكيانات tenant-owned.
- Branch ownership عند قراءة `stock_branches`.
- `company_id + item_id` عند قراءة `inventory_log`.
- تقييد `order_details` من خلال Order IDs للشركة الحالية.
- استخدام `SalesReturn` و`DirectReturn` للمرتجعات.
- استخدام Finance RPCs الحالية مباشرة:
  - `get_trial_balance`
  - `get_profit_loss`
  - `get_balance_sheet_data`
  - `get_cash_flow`
- إبقاء التقارير غير المتاحة Capability-Gated بدل اختلاق بيانات.
- الحفاظ على واجهة التقارير الحالية والـDrill-Downs الأساسية.

### التحقق
- `node --check` للبديل الجراحي الكامل: **PASS**.
- إعادة قراءة Main9 الحالي حتى نهاية الملف: **تمت** عبر قراءة المقاطع المتسلسلة حتى `window.RW_Reports_Comprehensive = RW_Reports_Comprehensive;`.
- Full Main9 syntax بعد الجراحة: **NOT PROVEN YET**.
- Main2 integration بعد الجراحة: **NOT PROVEN YET**.
- Assembly: **NOT STARTED**.
- New-main syntax/runtime: **NOT PROVEN**.

### الحالة النهائية
`MAIN9 SURGERY = READY`
`CURRENT MAIN9 BEFORE SURGERY = DEFECTIVE IN _generateReport ONLY`
`_companyId = CLOSED`
`_appendOptions = CLOSED`
`MAIN9 FULL SYNTAX = OPEN`
`MAIN2 MATCH = OPEN`
`ASSEMBLY = NOT STARTED`
