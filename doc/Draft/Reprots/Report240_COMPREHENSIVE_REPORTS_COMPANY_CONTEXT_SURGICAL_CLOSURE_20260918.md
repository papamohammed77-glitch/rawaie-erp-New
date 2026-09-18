# RAWAEA ERP — تبويب التقارير الشاملة
# تقرير التحقيق الجنائي والإصلاح الجراحي — الجلسة الحالية
## 2026-09-18

---

## 1. نطاق التنفيذ

نطاق هذه الجلسة محصور في:

`RW_Reports_Comprehensive`

داخل مصدر النظام الأم:

`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

**حماية صريحة:** لم يتم تعديل `main.html` بواسطة CTO.

الهدف التنفيذي:

1. إعادة بناء الحالة الحالية من المصادر الفعلية.
2. التحقق من Production الحالية قبل تقرير أي نتيجة.
3. تتبع سبب الخطأ:
   `RW_Reports_Comprehensive._loadDropdowns ReferenceError: _companyId is not defined`
4. مراجعة العقد التاريخي والمعماري وعدم إعادة إصلاح ما تم إغلاقه.
5. التحقق من Production reporting contracts الحالية.
6. مقارنة بنمط التقارير في Odoo وMicrosoft Dynamics 365 Business Central وSAP Business One وDaftra وManager.io.
7. تحديد **إصلاح جراحي واحد واضح** لمصدر النظام الأم.
8. تنفيذ أي تغيير Production لازم فقط إذا ثبتت ضرورته.
9. تحديث سجل الحالة للجلسة التالية.

---

# 2. قاعدة الحقيقة المستخدمة

لم تُعامل التقارير التاريخية كـCurrent State.

ترتيب الحقيقة المستخدم:

```
CURRENT GIT
+
CURRENT SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT EVIDENCE
+
CURRENT RUNTIME EVIDENCE
```

التقارير السابقة استُخدمت لاسترجاع السياق التاريخي والعقود فقط.

---

# 3. Governance / Master CTO

تمت قراءة ملف:

`doc/Draft/Reprots/MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`

حتى نهايته.

أهم القواعد المنطبقة على هذه الجلسة:

- الدراسة تسبق التعديل.
- لا يوجد اعتماد على الافتراض أو التخمين.
- Production مصدر حقيقة أولي.
- CURRENT_STATE سجل تنفيذي حي وليس ملخصًا تاريخيًا.
- لا يُعلن Closure من تقرير نظري.
- التعديل الجراحي يجب أن يحدد الملف والدالة والموقع والبديل الكامل.
- لا يجوز إعادة بناء `main.html` كاملًا.
- مسؤولية مالك النظام الأم هي تطبيق تغييرات `main.html`.
- Production SQL/DDL الذي يثبت ضرورته يُنفذ مباشرة.
- كل Closure يجب أن يوضح ما ثبت، وما لم يثبت، وما بقي مفتوحًا.
- لا تُترك Responsibility بلا مالك بعد الإصلاح.

---

# 4. آخر حالة في Git — التحقق الجنائي

## 4.1 System Repository

Repository:

`papamohammed77-glitch/rawaie-erp-New`

Current main HEAD المثبت:

`0f91627c13487232dc854fb87e5c08f95b42a6fb`

Direct parent:

`06ba639fdf3f8f4eaf0a5c12adaa160f08d97338`

الـHEAD الحالي هو State Checkpoint حديث، وليس النسخة القديمة التي كانت بعض التقارير السابقة تشير إليها.

## 4.2 Mother Repository

Repository:

`papamohammed77-glitch/erp-frontend`

Current main HEAD المثبت:

`50ad72f343dec2aaa45499dd24b73d3b6c270140`

Direct parent:

`83722ec6d914c2a58672dfa7e87066fd0a1206bd`

Current `main.html` blob:

`9c51deb8ec3bb0391e8781553e302af53707f776`

الحجم الحالي:

- 25,904 سطرًا تقريبًا.
- 1,413,332 حرفًا تقريبًا.

الـparent `83722...` يحتوي بالفعل على آخر الإصلاحات السابقة الخاصة بتبويب التقارير الشاملة، ومنها:

- إصلاح بناء أزرار `_generateReport()`.
- إصلاح `_exportReportCsv()`.
- معالجة `<\/script>` داخل `_printReport()`.
- تحديث وصف Tax.

ولذلك **لم تتم إعادة هذه الإصلاحات** في هذه الجلسة.

---

# 5. القراءة الحالية للنظام الأم

تم فتح الـblob الحالي نفسه، وليس الاعتماد على التقرير السابق.

حدود الموديول الحالي:

`RW_Reports_Comprehensive`

يبدأ عند:

`main.html line 19845`

وينتهي تقريبًا عند:

`main.html line 23380`

ويحتوي على:

- Sales: 7
- Inventory/Purchase: 7
- Finance: 13
- CRM: 4
- Logistics: 4
- HR: 3

الإجمالي:

**38 Report IDs**

---

# 6. Production أولًا — الحالة الحالية

Production Supabase:

`fiilmooggumokxanwiyx`

Snapshot فعلي وقت التحقيق:

`2026-09-18T07:48:24Z`

الحالة:

| العنصر | Production الحالية |
|---|---:|
| Companies | 1 |
| Active Branches | 2 |
| Active Items | 16 |
| Orders | 0 |
| Purchase Orders | 0 |
| Receiving | 0 |
| Runsheets | 0 |
| Journal Entries | 2 |
| Daily Settlements | 0 |
| Stock Rows | 20 |
| Inventory Log Rows | 3 |

Company الحالية:

`00000000-0000-0000-0000-000000000001`

Cross-company stock/item mismatch:

**0**

Cross-company inventory_log/item mismatch:

**0**

النتيجة:

**لا توجد مشكلة Production Database تخص خطأ تبويب التقارير الشاملة الحالي.**

---

# 7. Production Reporting Contracts

تمت إعادة فحص Production PostgreSQL الحالية، والعقود التالية موجودة فعليًا:

### Inventory

- `inventory_movement_report(uuid,text,date,date,uuid,uuid,text,text,integer,integer)`
- `inventory_replenishment_report(uuid,text,uuid,integer,integer)`
- `comprehensive_inventory_turnover_report(uuid,date,date,uuid)`

### Finance / Accounting

- `finance_tax_report(uuid,date,date)`
- `finance_tax_settlements_report(uuid,date,date)`
- `accountant_customer_aging(date)`
- `accountant_supplier_aging(date)`
- `accountant_gl_account_activity(uuid,date,date)`
- `accountant_period_readiness(date,date)`
- `accountant_reconciliation_summary(date)`
- `accountant_exception_center(date)`
- `get_trial_balance(date,date)`
- `get_profit_loss(date,date)`
- `get_balance_sheet_data(date)`
- `get_cash_flow(date,date)`

هذه العقود تطابق الاستخدام الحالي في الموديول بالنسبة للتقارير التي تعتمد عليها.

---

# 8. التقرير المطلوب إصلاحه — Root Cause

الـConsole الحالي:

```
RW_Reports_Comprehensive._loadDropdowns ReferenceError:
_companyId is not defined
```

الموقع الحالي المثبت:

```
main.html:20183
var companyId = _companyId();
```

ومصدر الاستدعاء:

```
_openReport()
    ↓
_loadDropdowns()
    ↓
_companyId()
```

لكن داخل IIFE الخاصة بـ`RW_Reports_Comprehensive` **لا توجد دالة `_companyId()` أصلًا**.

الفحص البرنامجي لدوال الموديول أثبت أن الدوال المحلية الموجودة تشمل:

- `_fmtNum`
- `_esc`
- `_showLoader`
- `_hideLoader`
- `_showToast`
- `render`
- `_openSection`
- `_closeSection`
- `_openReport`
- `_loadDropdowns`
- `_generateReport`
- `_exportReportCsv`
- `_printReport`
- ودوال الـvalidation والـdrill-down

ولا تشمل:

`_companyId`

---

# 9. لماذا ظهر الخطأ الآن؟

يوجد `_companyId()` في أجزاء أخرى من `main.html`، لكنه **دالة محلية داخل IIFE أخرى**.

وجودها هناك لا يجعلها متاحة داخل:

`RW_Reports_Comprehensive`

إذن محاولة إصلاح التقارير باستدعاء helper مالي آخر ستكون خطأ معماريًا.

---

# 10. عقد الهوية الصحيح في Mother الحالي

Boot الحالي المثبت في نفس `main.html` يقوم بتكوين:

عند line 25810 تقريبًا:

```javascript
RW_STATE.app.company = {
    id: profileRes.data.company_id,
    name: meta.companyName || 'الروائع ERP',
    logo: meta.companyLogo || 'ر'
};
```

والـCurrent Boot يقرأ:

```
users.company_id
```

ويربطه بالـSession عبر:

`auth_id`

إذن مصدر Company Identity المثبت في Current Source هو:

```
RW_STATE.app.company.id
```

وليس:

```
RW_STATE.app.companyId
```

وليس:

```
RW_STATE.user.companyId
```

والفحص الحالي أثبت عدم وجود Assignment عام لـ:

`RW_STATE.app.companyId`

داخل المصدر الحالي.

لذلك لا يجوز بناء إصلاح على هذا الحقل غير الموجود.

---

# 11. العيب الحقيقي

العيب ليس:

- RPC مفقود.
- Production schema مكسورة.
- Permission database.
- Inventory engine.
- Order engine.
- Runsheet engine.
- Supplier/Customer data.
- Company data.

العيب هو:

**Reports module يستدعي helper غير موجود داخل نطاقه، بينما Company Identity موجودة في Current Session تحت `RW_STATE.app.company.id`.**

---

# 12. أثر العيب

الاستدعاء المتأثر في `_loadDropdowns` هو:

`main.html:20183`

لكن نفس الخطأ سيظهر لاحقًا أيضًا داخل الموديول عند الاستدعاءات التالية:

- `main.html:20377`
- `main.html:20456`
- `main.html:20541`
- `main.html:20662`
- `main.html:20796`

أي أن إصلاح سطر `20183` وحده سيكون **نصف حل**.

الحل الصحيح هو إصلاح مصدر Company Context داخل الموديول مرة واحدة.

---

# 13. لماذا لا نعدل _loadDropdowns نفسها؟

لأن:

`_loadDropdowns()`

مبنية بالفعل على contract صحيح:

```
companyId
    ↓
customers.company_id
suppliers.company_id
items.company_id
treasury.company_id
chart_of_accounts.company_id
users.company_id
customers.area + company_id
```

الخلل هو فقط في كيفية الحصول على:

`companyId`

لذلك تعديل استعلامات dropdowns سيكون تغييرًا زائدًا وغير جراحي.

---

# 14. لماذا لا نعدل _generateReport نفسها؟

`_generateReport()` تستخدم نفس Company Context.

الخلل نفسه سيتكرر إذا تم إصلاح dropdowns وحدها.

لذلك يجب إنشاء helper محلي canonical داخل:

`RW_Reports_Comprehensive`

ويستفيد منه الطرفان:

- `_loadDropdowns()`
- `_generateReport()`
- جميع الـdrill-down functions التي تستدعي `_companyId()`

وبذلك تنتقل Responsibility إلى نقطة واحدة.

---

# 15. Historical Contract Protection

تمت مراجعة Report238 وReport239 والسياق التاريخي لتبويب التقارير.

كما تم فحص المصدر الحالي بعد آخر Parent commit.

النتيجة المهمة:

**الإصلاح المطلوب لا يغيّر أي Business Logic للتقارير.**

لا يغيّر:

- طريقة احتساب المبيعات.
- دورة حياة Order.
- Runsheet lifecycle.
- Picking.
- Loading.
- Delivery.
- Returns.
- Settlements.
- Physical Stock.
- Inventory Movement Engine.
- Inventory Turnover Engine.
- Accounting posting.
- Customer Ledger.
- Supplier Ledger.

التغيير هو فقط:

**إتاحة Company Context الصحيح للموديول الذي كان يستدعي helper غير موجود.**

---

# 16. فحص رحلة البيانات في التقارير

## Sales

مصادر التقارير الحالية:

- `orders`
- `order_details`
- `runsheets`

والشركة مربوطة بالفعل في Parent queries.

## Inventory

المصدر الحالي:

- `stock_branches`
- Production inventory reporting RPCs

وهذا يحافظ على العقد المركزي للمخزون.

## Purchasing

المصادر:

- `purchase_orders`
- `receiving`
- `receiving_details`

## Finance

المصادر الحالية تمر عبر Production accounting/reporting contracts.

## CRM

المصدر:

- `customers`
- `customer_followups`
- `orders`

## Logistics

المصادر:

- `stock_vouchers`
- `inventory_log`
- `daily_settlements`
- `runsheets`
- `orders`
- `order_details`

## HR

الموديول الحالي يحتفظ بـCapability Gates للحضور والرواتب حيث لا يوجد في الأدلة الحالية Report Contract سلطوي مكافئ مثبت.

هذه ليست مشكلة runtime الحالية، ولا ينبغي تحويلها إلى patch مستقل دون evidence جديد.

---

# 17. لا يوجد Production Migration لهذه المشكلة

النتيجة:

```
Production DB change = 0
Schema change = 0
RPC change = 0
Data repair = 0
```

السبب:

Production reporting contracts موجودة بالفعل.

العطل Source Runtime Context فقط.

تنفيذ Migration في Production لن يعالج `ReferenceError`.

---

# 18. Surgical Patch — REQUIRED OWNER ACTION

## العنصر الوحيد المطلوب في main.html

ابحث داخل:

`var RW_Reports_Comprehensive = (function() {`

عن هذا البلوك **حرفيًا**:

```javascript
    function _showToast(m, t) { try { if (typeof showToast === 'function') showToast(m, t || 'success'); } catch(e) { alert(m); } }

    var _container = null;
```

### احذف البلوك أعلاه بالكامل.

ثم استبدله بالكامل بهذا البلوك:

```javascript
    function _showToast(m, t) { try { if (typeof showToast === 'function') showToast(m, t || 'success'); } catch(e) { alert(m); } }

    function _companyId() {
        if (
            typeof RW_STATE !== 'undefined' &&
            RW_STATE &&
            RW_STATE.app &&
            RW_STATE.app.company &&
            RW_STATE.app.company.id
        ) {
            return RW_STATE.app.company.id;
        }

        throw new Error('سياق الشركة غير محدد');
    }

    var _container = null;
```

**هذا هو التعديل الجراحي الوحيد المطلوب في `main.html` لهذه الجلسة.**

لا تحذف أي `_companyId()` من الدوال اللاحقة.

لا تستبدل أي:

`var companyId = _companyId();`

داخل الدوال.

لا تعدل الـboot.

لا تعدل الـfinance IIFE.

لا تعدل `RW_STATE`.

لا تعرّف `RW_STATE.app.companyId` كحل بديل.

---

# 19. لماذا هذا هو الإصلاح الصحيح؟

لأن الـCurrent Source يثبت:

```
Authenticated User
    ↓
users.auth_id
    ↓
users.company_id
    ↓
RW_STATE.app.company.id
    ↓
RW_Reports_Comprehensive._companyId()
    ↓
company-scoped report reads
```

وهذا يعيد بناء التدفق الحالي بدل اختراع Contract جديد.

---

# 20. Validation — Source

Current Source parser:

**PASS**

Full current inline script V8 parse:

**PASS**

Current `RW_Reports_Comprehensive` module parse:

**PASS**

تجربة helper المعزولة:

### سياق صالح

Input:

```
RW_STATE.app.company.id = "COMPANY-TEST"
```

Result:

```
"COMPANY-TEST"
```

### سياق غير موجود

Result:

```
Error: سياق الشركة غير محدد
```

إذن الـhelper:

- يعيد Company ID الصحيح.
- يرفض missing context.
- لا يعتمد على global variable غير مثبت.

---

# 21. ما الذي تم إثباته بالفعل؟

1. `_companyId` مفقودة داخل `RW_Reports_Comprehensive`.
2. `_loadDropdowns` تستدعيها عند line 20183.
3. `_generateReport` تستدعي نفس العقد.
4. Company identity الحالية موجودة في `RW_STATE.app.company.id`.
5. Production database سليمة من ناحية Company isolation الحالية.
6. Reporting RPC contracts موجودة في Production.
7. الإصلاح المطلوب محصور في helper محلي واحد.
8. لا توجد حاجة إلى Production migration لهذا الخطأ.
9. الإصلاح لا يمس أي Business Engine.
10. الإصلاح قابل للتحقق آليًا دون تغيير بيانات الأعمال.

---

# 22. ما الذي لم يُثبت بعد؟

لم يتم إعلان Browser Production PASS، لأن Owner لم يطبق بعد التعديل الجراحي على `main.html`.

المتبقي بعد Owner Cutover:

```
OWNER CUTOVER
↓
CURRENT MOTHER BLOB RECHECK
↓
V8 PARSE
↓
OPEN COMPREHENSIVE REPORTS
↓
CLICK FIRST REPORT
↓
VERIFY DROPDOWNS
↓
GENERATE REPORT
↓
CSV
↓
PRINT
↓
BACK
↓
38 REPORT SMOKE
↓
CURRENT PRODUCTION RE-SNAPSHOT
```

---

# 23. Benchmark — Odoo

وفق الوثائق الرسمية الحالية:

- تقرير Stock يعرض On Hand وFree to Use وIncoming وOutgoing وUnit Cost وTotal Value.
- يمكن تضييق النتائج حسب Warehouse وCategory.
- يوجد History وReplenishment.
- تقارير Finance تشمل Balance Sheet وP&L وGeneral Ledger وAged Receivable/Payable وCash Flow وTax.
- يوجد Drill-down وتصدير PDF/XLSX ومقارنة الفترات.

المصادر:

- https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/reporting/stock.html
- https://www.odoo.com/documentation/19.0/applications/finance/accounting/reporting.html

---

# 24. Benchmark — Microsoft Dynamics 365 Business Central

الوثائق الرسمية الحالية تثبت:

- Inventory Transaction Detail يعرض Opening Quantity وحركات الزيادة والنقصان وClosing Quantity.
- Inventory Availability يجمع On Hand مع Supply وDemand.
- يوجد Ad-hoc Analysis داخل النظام.
- يوجد Financial Reporting مبني على تعريفات Rows/Columns.
- يدعم التحليل والفلاتر وطرق العرض المحفوظة.

المصادر:

- https://learn.microsoft.com/en-us/dynamics365/business-central/reports/report-704
- https://learn.microsoft.com/en-us/dynamics365/business-central/reports/report-705
- https://learn.microsoft.com/en-us/dynamics365/business-central/analysis-mode
- https://learn.microsoft.com/en-us/dynamics365/business-central/finance-reports

---

# 25. Benchmark — SAP Business One

الوثائق الرسمية الحالية تثبت وجود:

- Inventory Status.
- Inventory in Warehouse.
- Inventory Audit Report.
- Inventory Valuation.
- General Ledger مع Selection Criteria متعددة.
- إمكان حفظ مجموعات Selection Criteria للاستخدام المتكرر.

المصادر:

- https://help.sap.com/
- SAP Business One 10.0 Help Portal — Inventory Module Authorizations
- SAP Business One 10.0 Help Portal — General Ledger

---

# 26. Benchmark — Daftra

التوثيق الرسمي الحالي لتقرير Inventory Turnover يثبت:

- Product.
- Warehouse.
- Date.
- Category.
- Brand.
- Group By.
- Cost of Sales.
- Beginning Avg. Inventory.
- Ending Avg. Inventory.
- Avg. Inventory.
- Turnover Ratio.
- Avg. Days to Sell Inventory.

المصدر:

- https://docs.daftra.com/en/tutorial/inventory-turnover-report/

---

# 27. Benchmark — Manager.io

التوثيق الرسمي الحالي يثبت:

- Custom Reports.
- Filters.
- Ordering.
- Grouping.
- Aliases.
- Saved/custom report definitions.
- نسخ/Clone للتقارير.
- Copy to clipboard.

المصدر:

- https://www2.manager.io/guides/18075

---

# 28. نتيجة Benchmark على RAWAEA

الموديول الحالي ليس Skeleton.

هو يحتوي بالفعل على:

- 38 report IDs.
- Filters للـDate.
- Customer.
- Supplier.
- Item.
- Account.
- Treasury.
- Driver.
- Area.
- Production RPC reporting.
- Drill-down.
- CSV.
- Print.
- Freshness metadata.
- Capability Gates.
- Inventory-specific reports.
- Field Logistics reports.

الـgap الحالي الذي ظهر في هذه الجلسة **ليس نقصًا في عدد التقارير**.

الـgap الحالي:

**Session/Tenant Context Resolver داخل الموديول.**

أما تحسينات مقارنة المنافسين مثل:

- Generic warehouse filter.
- Branch/location filter في مزيد من التقارير.
- Saved report views.
- Period comparison.
- richer analytical pivoting.

فهذه تحسينات مستقبلية، وليست مبررًا لتوسيع هذا الإصلاح أو خلطها به.

---

# 29. حماية العمليات الميدانية

تم الحفاظ صراحة على:

```
Order
↓
Runsheet
↓
Picking
↓
Loading
↓
Delivery
↓
Return
↓
Settlement
```

وكذلك:

```
Physical Stock
↓
Central Production Inventory Contracts
```

لا يوجد أي patch في هذه الجلسة يكتب إلى:

- `stock_branches`
- `inventory_log`
- `order_details`
- `run_sheet_details`
- `runsheets`
- `orders`
- `daily_settlements`

التقرير يظل طبقة قراءة وتحليل.

---

# 30. Execution Record

### Assistant-side execution

- Governance read: PASS
- Current State read: PASS
- Current System HEAD/parent: VERIFIED
- Current Mother HEAD/parent: VERIFIED
- Current main.html blob: VERIFIED
- Production snapshot: VERIFIED
- Production reporting contracts: VERIFIED
- Current module inspection: VERIFIED
- Root cause: PROVEN
- Full inline V8 parse: PASS
- Surgical helper test: PASS
- Production change for this defect: NONE

### Owner-side execution

```
main.html surgical cutover = PENDING
Browser E2E = PENDING
38-report smoke = PENDING
```

---

# 31. Final Surgical Instruction للمساعد/المالك التالي

لا تبدأ من Report239 على أنه Current State.

ابدأ بهذا الترتيب:

1. تحقق من System HEAD وParent.
2. تحقق من Mother HEAD وParent.
3. تحقق من `main.html` blob الحالي.
4. ابحث داخل `RW_Reports_Comprehensive` عن:
   `function _showToast(m, t)`
5. طبّق **استبدال البلوك المحدد في Section 18 فقط**.
6. لا تعدل أي helper خارج `RW_Reports_Comprehensive`.
7. لا تنشئ `RW_STATE.app.companyId`.
8. شغّل V8 parse.
9. افتح تبويب التقارير الشاملة.
10. اضغط أول تقرير يحتوي Date.
11. تحقق من اختفاء:
   `ReferenceError: _companyId is not defined`
12. تحقق من تحميل dropdowns.
13. نفذ Generate.
14. تحقق من CSV وPrint.
15. Smoke-test الـ38 Report IDs.
16. أعد Production snapshot.
17. لا تعلن Closure قبل Browser PASS + Production re-snapshot.

---

# 32. FINAL SELF-AUDIT

## What I Proved

- Current Mother source was inspected مباشرة.
- Current Git and parent were revalidated.
- Current Production database was revalidated.
- Exact runtime root cause is missing `_companyId` inside Reports IIFE.
- Current canonical Company Identity is `RW_STATE.app.company.id`.
- Production reporting contracts exist.
- No Production migration is required.
- The fix is one surgical helper block.

## What I Did Not Prove

- Browser Production PASS after Owner Cutover.
- All 38 reports were clicked in a live browser in this session.

## What I Initially Rejected

- إصلاح Production SQL.
- إضافة `companyId` إلى schema.
- تعديل boot.
- تعديل finance helper.
- تعديل كل call-site منفصل.
- إعادة بناء تبويب التقارير من الصفر.
- إعادة فتح Inventory/Order/Runsheet engines.

## What Could Still Be Wrong

بعد تطبيق helper فقط، قد يظهر خطأ runtime جديد مختلف داخل تقرير بعينه؛ عندها يُتعامل معه كدليل جديد مستقل، ولا يُخلط مع هذا العيب.

## Closure Status

```
CURRENT PRODUCTION = VERIFIED
CURRENT SOURCE = VERIFIED
ROOT CAUSE = PROVEN
SURGICAL PATCH = COMPLETE / OWNER READY
PRODUCTION PATCH = NOT REQUIRED
BROWSER PASS = PENDING OWNER CUTOVER
38 REPORT SMOKE = PENDING
FULL TAB CLOSURE = PENDING BROWSER VERIFICATION
```

---

# END OF REPORT
