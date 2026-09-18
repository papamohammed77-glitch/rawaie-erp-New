# RAWAEA ERP — تبويب التقارير الشاملة
# Forensic + Surgical Closure Report
## 2026-09-18

---

## 1. نطاق المهمة

هذه الجلسة محصورة في:

`RW_Reports_Comprehensive`

داخل:

`erp-frontend/companies/company-1/main.html`

ممنوع تعديل أي جزء خارج حدود الموديول المذكور، وممنوع تعديل `main.html` من خلال هذه الجلسة.

لا يوجد تغيير مطلوب أو منفذ على Sales / Inventory / Purchasing / Finance / CRM / Logistics / HR engines خارج احتياجات **قراءة التقارير**.

الهدف:

1. تثبيت الحالة الفعلية من Git + Source + Production + Database.
2. مطابقة الـ38 تقريرًا الموجودة فعليًا في الموديول مع Production.
3. مطابقة تجربة التقارير مع أنماط Odoo / Dynamics 365 Business Central / SAP Business One / Daftra / Manager.
4. فصل ما هو Contract مثبت عما هو مجرد واجهة أو وصف.
5. إصلاح التقارير التي ثبت فعليًا وجود فجوة فيها فقط.
6. إضافة دعم Production حقيقي لتقرير دوران المخزون.
7. إعطاء owner-managed source replacements محددة وقابلة للتطبيق.
8. تحديث حالة المشروع للجلسة التالية.

---

# 2. مصادر الحقيقة الحالية

## 2.1 System Repository

Repository:

`papamohammed77-glitch/rawaie-erp-New`

HEAD عند بداية هذه الجلسة:

`7cc32da0dfd4441bd3222cbe137faeb6ece294b5`

Parent:

`5e103748d65fb4c9c0988a6c89dbffb58708642d`

أحدث commit أنشأه هذا الإغلاق:

`f8117693e8b7c6f1d6a4aaffbb0f17765f4aa064`

Message:

`reports: canonicalize comprehensive inventory turnover report`

Parent لهذا الـcommit:

`7cc32da0dfd4441bd3222cbe137faeb6ece294b5`

---

## 2.2 Mother Repository

Repository:

`papamohammed77-glitch/erp-frontend`

Current Mother HEAD:

`fdfdb2bf03271e8eedad81ad8400c243b89c33a5`

Direct parent:

`d265bb72a64f4bbabf9c125a1b5bba5d17ffd799`

Current `main.html` blob:

`468da111b9da992331dba9162c6c6e6509b76004`

Current file size:

- 1,413,915 characters
- 25,837 lines

الـMother HEAD الأخير لم يغيّر `main.html`; التعديل كان forensic persistence.

---

## 2.3 Current State Governance

تمت مراجعة:

- `MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`
- `CURRENT_STATE.md`
- آخر تقارير `doc/Draft/Reprots`

الحوكمة الملزمة التي طبقتها هذه الجلسة:

```text
CURRENT GIT
+
CURRENT SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT EVIDENCE
```

هي مصدر الحقيقة.

التقارير التاريخية استخدمت للاسترداد فقط، وليس لإثبات الحالة الحالية.

---

# 3. Current Production Snapshot

Production project:

`fiilmooggumokxanwiyx`

وقت آخر فحص مباشر:

2026-09-18

Production الحالية تحتوي Company واحدة فقط:

| Company | ID |
|---|---|
| الروائع | `00000000-0000-0000-0000-000000000001` |

الحالة الحالية:

| العنصر | Production |
|---|---:|
| Active Branches | 2 |
| Active Items | 16 |
| Orders | 0 |
| Purchase Orders | 0 |
| Receiving | 0 |
| Runsheets | 0 |
| Journal Entries | 2 |
| Daily Settlements | 0 |
| Stock Rows | 20 |

الفروع النشطة الحالية:

- `BR-01` — الفرع الرئيسي — 17 stock rows
- `BR-2` — فرع إسكندرية — 3 stock rows

فحوص العزل:

- Cross-company stock rows = 0
- Cross-company inventory_log rows = 0
- Cross-company order_detail rows = 0

هذه هي Production الحالية، ولا يجوز حمل حالة الـ3 Companies القديمة من التقارير السابقة إلى أي تحليل لاحق.

---

# 4. Current Comprehensive Reports Source

الـmodule الحالي:

```
RW_Reports_Comprehensive
```

حدوده الحالية:

```
START  = line 19844
END    = line 23313
```

عدد التقارير المعرفة فعليًا:

**38 Report IDs**

## Sales — 7

1. `sales-summary`
2. `sales-by-customer`
3. `sales-by-item`
4. `sales-by-area`
5. `sales-order-status`
6. `sales-customer-ledger`
7. `sales-runsheet-performance`

## Inventory / Purchase — 7

8. `inventory-stock`
9. `inventory-movement`
10. `inventory-low-stock`
11. `inventory-dormant`
12. `purchase-by-supplier`
13. `purchase-order-status`
14. `purchase-receiving`

## Finance — 13

15. `finance-trial-balance`
16. `finance-profit-loss`
17. `finance-balance-sheet`
18. `finance-cash-flow`
19. `finance-general-ledger`
20. `finance-treasury`
21. `finance-customer-aging`
22. `finance-supplier-aging`
23. `finance-gl-activity`
24. `finance-period-readiness`
25. `finance-reconciliation`
26. `finance-exceptions`
27. `finance-tax`

## CRM — 4

28. `crm-customer-list`
29. `crm-customer-analysis`
30. `crm-customer-followups`
31. `crm-customer-by-area`

## Logistics — 4

32. `logistics-loading-unloading`
33. `logistics-returns`
34. `logistics-settlement`
35. `logistics-driver-performance`

## HR — 3

36. `hr-employee-list`
37. `hr-attendance`
38. `hr-salary`

---

# 5. Current Source Architecture Finding

التبويب حاليًا ليس Stub.

يوجد:

- section navigation
- 38 report definitions
- date/customer/supplier/item/account/treasury/driver/area parameters
- report rendering
- printing
- direct Production reads
- current Finance RPCs

لكن توجد فجوة معمارية في نقطة مهمة:

**واجهة التقارير أحدث من بعض عقود القراءة التي تستخدمها.**

ظهر ذلك في الحالات التالية:

1. Report يصف نفسه بأنه sales بينما يقرأ Draft/Confirmed/Pending.
2. Inventory Value يعرض قيمة باستخدام selling price.
3. Inventory movement يتجاوز الـProduction reporting contract الموجود ويقرأ `inventory_log` مباشرة.
4. Low Stock يكرر منطق reorder بقاعدة fallback = 5 بدل استخدام Production reporting engine.
5. Dormant report ليس Turnover Report فعلًا.
6. Finance GL يكرر قراءة journal tables بدل استخدام running-balance RPC الموجود.
7. Finance Tax يعرض Capability Gate قديمًا رغم وجود tax reporting contracts مثبتة في Production.
8. Treasury report لا يضع `company_id` ضمن read filter.
9. UX لا يوضح آخر وقت تنفيذ ومصدر التقرير.
10. لا يوجد CSV export رغم أن هذا أصبح نمطًا أساسيًا في الأنظمة المرجعية.

---

# 6. Historical Contract Protection

تم الرجوع إلى التقارير السابقة، وبخاصة:

- `Report160_CTO_E2E_Main_Sales_Gold_Diamond_Forensic_20260913.md`
- التقارير السابقة الخاصة Inventory
- التقارير السابقة الخاصة Finance
- التقارير الأخيرة الخاصة HR/CRM لاستخلاص Governance state فقط

القاعدة الناتجة:

لا نعيد فتح:

- save-sales-invoice
- complete-return
- Inventory Writers
- Runsheet lifecycle
- Picking / Loading / Delivery
- separate operational applications

فقط لأن تقريرًا جديدًا يريد القراءة منها.

تبويب التقارير الشاملة **قارئ/مجمّع** وليس Business Transaction Engine.

---

# 7. Competitor Benchmark — Current Official Evidence

## Odoo

Odoo 19 يوفّر:

- Balance Sheet
- Profit and Loss
- General Ledger
- Aged Receivable
- Aged Payable
- Cash Flow
- Tax Report
- Audit Trail
- Custom reports
- PDF/XLSX export
- Period comparison
- Graph and Pivot views
- Interactive dashboards
- Inventory Metrics
- stock value
- reserved stock
- negative stock
- slow-moving / stagnant analysis

المراجع الرسمية:

- https://www.odoo.com/documentation/19.0/applications/finance/accounting/reporting.html
- https://www.odoo.com/documentation/19.0/applications/essentials/reporting.html
- https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/reporting/dashboards.html
- https://www.odoo.com/documentation/19.0/applications/finance/accounting/get_started/inventory_valuation.html

---

## Microsoft Dynamics 365 Business Central

الـreporting الرسمي يشمل:

- Financial Reports
- Sales Reports
- Purchase Reports
- Inventory/Warehouse Reports
- Inventory Transaction Detail
- Inventory Availability
- Customer/Item Sales
- Opening quantity
- period movements
- closing quantity
- future supply/demand
- Excel / Word layouts
- analytical/export workflows

المراجع الرسمية:

- https://learn.microsoft.com/en-us/dynamics365/business-central/reports-available-reports
- https://learn.microsoft.com/en-us/dynamics365/business-central/reports/report-704
- https://learn.microsoft.com/en-us/dynamics365/business-central/reports/report-705
- https://learn.microsoft.com/en-us/dynamics365/business-central/reports/report-713
- https://learn.microsoft.com/en-us/dynamics365/business-central/finance-reports

---

## SAP Business One

الـreporting الرسمي يشمل:

- Sales Analysis حسب العملاء
- Sales Analysis حسب الأصناف
- Sales Analysis حسب Sales Employee
- Inventory Status Dashboard
- turnover-rate analysis
- insufficient inventory
- excessive inventory
- higher inventory / faster moving
- lower inventory / slower moving
- Sales and Purchase Report

المراجع الرسمية:

- https://help.sap.com/docs/SAP_BUSINESS_ONE
- SAP Business One — Sales Analysis Report
- SAP Business One — Inventory Status Dashboard
- SAP Business One — Sales and Purchase Report

---

## Daftra

Daftra يوفّر رسميًا:

- Inventory Detailed Transactions
- Inventory Transactions Summary
- Inventory Value
- Inventory Turnover
- warehouse filtering
- opening stock
- movement source
- inward/outward
- average cost
- stock value after transaction
- CSV
- Excel
- PDF
- stock alerts
- shortage/surplus
- stocktaking
- multi-warehouse movement analysis

المراجع:

- https://docs.daftra.com/en/tutorial/inventory-detailed-transactions-report/
- https://docs.daftra.com/en/tutorial/inventory-transactions-summary-report/
- https://docs.daftra.com/en/tutorial/inventory-value-report/
- https://docs.daftra.com/en/tutorial/inventory-turnover-report/
- https://www.daftra.com/en/inventory/

---

## Manager.io

Manager يوفّر رسميًا:

- Reports tab
- P&L
- comparative periods
- Balance Sheet
- Cash Flow
- customer/supplier aging
- inventory reports
- custom reports
- filters
- grouping
- sorting
- comparative columns
- real-time report regeneration
- copy/export workflow
- inventory quantity/value reports

المراجع:

- https://www2.manager.io/guides/7468
- https://www2.manager.io/guides/18075
- https://www2.manager.io/guides/8889
- https://www2.manager.io/guides/11111
- https://www2.manager.io/guides/11069

---

# 8. Competitive UX Target For RAWAEA

المطلوب ليس نسخ المنافسين.

الهدف المعياري لتبويب RAWAEA:

```
Live Production
+
Clear report source
+
As-of / period clarity
+
Operational filters
+
Opening / movement / closing
+
Decision metrics
+
Cost valuation
+
Drill-down
+
Export
+
Print
+
Company isolation
```

وعلى وجه الخصوص:

### Inventory

```
Current Qty
Available Qty
Allocated Qty
Opening Qty
Movement
Net Sales
Average Stock
Turnover
Days on Hand
Cost
Stock Value
Reorder Point
Recommended Order
```

وهذا يطابق الأنماط المؤسسية الموثقة في Odoo / Dynamics / SAP / Daftra / Manager، مع الإبقاء على دورة RAWAEA الميدانية الأصلية.

---

# 9. Production Reporting Contracts Confirmed

تم فحص Production مباشرة.

RPCs المؤكدة الآن:

### Inventory

`inventory_movement_report`

يُرجع:

- event
- date
- voucher
- item
- branch
- movement type
- qty
- effect qty
- before qty
- after qty
- user

### Inventory Replenishment

`inventory_replenishment_report`

يُرجع:

- available
- allocated
- reorder point
- max quantity
- deficit
- recommended order
- cost
- recommended order value

### Finance Tax

`finance_tax_report`

و:

`finance_tax_settlements_report`

كلاهما موجود فعليًا وtenant-scoped.

### Finance GL

`accountant_gl_account_activity`

ويُرجع running balance رسميًا.

### Finance readiness

`accountant_period_readiness`

### Finance reconciliation

`accountant_reconciliation_summary`

### Finance exception center

`accountant_exception_center`

### Standard financial statements

- `get_trial_balance`
- `get_profit_loss`
- `get_balance_sheet_data`
- `get_cash_flow`

لا يجوز إعادة إنشاء هذه العقود داخل Mother.

---

# 10. Production Change Executed

تم إنشاء ونشر contract جديد فقط لما ينقص فعليًا:

`public.comprehensive_inventory_turnover_report`

Migration canonical:

`supabase/migrations/20260918_comprehensive_inventory_turnover_report.sql`

تم تطبيقها في Production.

خصائص العقد:

- SECURITY DEFINER
- STABLE
- authenticated Company Context
- يرفض execution بدون authenticated company context
- يرفض company mismatch
- date validation
- optional item filter
- current stock
- available stock
- allocated stock
- opening quantity
- average stock
- net sales quantity
- movement count
- turnover ratio
- average daily sales
- days on hand
- cost price
- stock value at cost
- reorder point
- max quantity

### Current Production auth verification

تم تنفيذ الاختبار مرتين:

#### بدون auth context

النتيجة:

```
REJECTED
سياق الشركة المصادق عليه مطلوب
```

#### مع Auth Context حقيقي مرتبط بـusers.auth_id

النتيجة:

```
company_id = 00000000-0000-0000-0000-000000000001
success = true
days = 30
```

إذن contract لا يعمل باعتبار `p_company_id` وحده مصدر ثقة.

---

# 11. Current Production Data Reality For Inventory Turnover

الوضع الحالي في Production لا يحتوي Sales Transactions خلال نافذة الاختبار.

لذلك:

- `net_sales_qty = 0`
- `turnover_ratio = 0`
- `days_on_hand = NULL`

وهذا ليس Error.

هو نتيجة مباشرة لحقيقة أن:

`Orders = 0`

في Production الحالية.

وبالتالي لا يجوز تحويل هذه النتيجة إلى claim عن أداء المخزون التجاري.

---

# 12. Surgical Source Changes — OWNER ACTION

## IMPORTANT

**لا تعدّل `main.html` بالكامل.**

طبّق فقط العناصر التالية داخل:

`RW_Reports_Comprehensive`

---

# PATCH 01 — تحسين Report UX + Local Date + Export

## ابحث بالضبط عن:

`function _openReport(sectionKey, reportId) {`

داخل:

`RW_Reports_Comprehensive`

عند حدود تقارب:

`lines 20023–20079`

احذف الدالة كاملة حتى القوس المغلق الذي يسبق:

`async function _loadDropdowns(params)`

واستبدلها بالكامل بهذا البديل:

```javascript
function _openReport(sectionKey, reportId) {
    var section = _reportsStructure[sectionKey];
    if (!section) return;

    var report = null;

    for (var i = 0; i < section.reports.length; i++) {
        if (section.reports[i].id === reportId) {
            report = section.reports[i];
            break;
        }
    }

    if (!report) return;

    _currentSection = sectionKey;
    _currentReport = reportId;

    var container = byId('report-detail-container');
    if (!container) return;

    function localISODate(d) {
        var x = d || new Date();
        var y = x.getFullYear();
        var m = String(x.getMonth() + 1);
        var day = String(x.getDate());
        if (m.length < 2) m = '0' + m;
        if (day.length < 2) day = '0' + day;
        return y + '-' + m + '-' + day;
    }

    var today = localISODate(new Date());
    var firstDay = localISODate(
        new Date(new Date().getFullYear(), new Date().getMonth(), 1)
    );

    var html =
        '<div class="border-t pt-6 mt-6">' +
        '<div class="flex flex-wrap justify-between items-start gap-4 mb-6">' +
        '<div>' +
        '<div class="flex items-center gap-3 mb-1">' +
        '<i class="fa-solid fa-chart-column text-2xl ' + section.color + '"></i>' +
        '<h3 class="font-black text-lg text-gray-800">' + _esc(report.label) + '</h3>' +
        '</div>' +
        '<p class="text-sm text-gray-500">' + _esc(report.desc) + '</p>' +
        '</div>' +
        '<div class="text-xs text-gray-500 bg-gray-50 border rounded-xl px-3 py-2">' +
        '<div>المصدر: Production</div>' +
        '<div>يتم إنشاء التقرير لحظة الضغط على عرض التقرير</div>' +
        '</div>' +
        '</div>';

    var params = report.params || [];

    html += '<div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4" id="report-params">';

    if (params.indexOf('date') !== -1) {
        html +=
            '<div><label class="block text-xs font-bold text-gray-500 mb-1">من تاريخ</label>' +
            '<input type="date" id="rp-date-from" value="' + firstDay + '" ' +
            'class="w-full p-2.5 bg-gray-50 border rounded-lg text-sm"></div>';

        html +=
            '<div><label class="block text-xs font-bold text-gray-500 mb-1">إلى تاريخ</label>' +
            '<input type="date" id="rp-date-to" value="' + today + '" ' +
            'class="w-full p-2.5 bg-gray-50 border rounded-lg text-sm"></div>';
    }

    if (params.indexOf('customer') !== -1) {
        html +=
            '<div><label class="block text-xs font-bold text-gray-500 mb-1">العميل</label>' +
            '<select id="rp-customer" class="w-full p-2.5 bg-gray-50 border rounded-lg text-sm">' +
            '<option value="">جميع العملاء</option></select></div>';
    }

    if (params.indexOf('supplier') !== -1) {
        html +=
            '<div><label class="block text-xs font-bold text-gray-500 mb-1">المورد</label>' +
            '<select id="rp-supplier" class="w-full p-2.5 bg-gray-50 border rounded-lg text-sm">' +
            '<option value="">جميع الموردين</option></select></div>';
    }

    if (params.indexOf('item') !== -1) {
        html +=
            '<div><label class="block text-xs font-bold text-gray-500 mb-1">الصنف</label>' +
            '<select id="rp-item" class="w-full p-2.5 bg-gray-50 border rounded-lg text-sm">' +
            '<option value="">جميع الأصناف</option></select></div>';
    }

    if (params.indexOf('account') !== -1) {
        html +=
            '<div><label class="block text-xs font-bold text-gray-500 mb-1">الحساب</label>' +
            '<select id="rp-account" class="w-full p-2.5 bg-gray-50 border rounded-lg text-sm">' +
            '<option value="">اختر حساباً</option></select></div>';
    }

    if (params.indexOf('treasury') !== -1) {
        html +=
            '<div><label class="block text-xs font-bold text-gray-500 mb-1">الخزينة</label>' +
            '<select id="rp-treasury" class="w-full p-2.5 bg-gray-50 border rounded-lg text-sm">' +
            '<option value="">جميع الخزائن</option></select></div>';
    }

    if (params.indexOf('driver') !== -1) {
        html +=
            '<div><label class="block text-xs font-bold text-gray-500 mb-1">السائق</label>' +
            '<select id="rp-driver" class="w-full p-2.5 bg-gray-50 border rounded-lg text-sm">' +
            '<option value="">جميع السائقين</option></select></div>';
    }

    if (params.indexOf('area') !== -1) {
        html +=
            '<div><label class="block text-xs font-bold text-gray-500 mb-1">المنطقة</label>' +
            '<select id="rp-area" class="w-full p-2.5 bg-gray-50 border rounded-lg text-sm">' +
            '<option value="">جميع المناطق</option></select></div>';
    }

    html += '</div>';

    html +=
        '<div class="flex flex-wrap gap-2">' +
        '<button onclick="RW_Reports_Comprehensive._generateReport('' +
        sectionKey +
        '', '' +
        reportId +
        '')" ' +
        'class="bg-indigo-600 text-white px-6 py-2.5 rounded-xl font-bold shadow">' +
        '<i class="fa-solid fa-play ml-1"></i> عرض التقرير</button>' +

        '<button onclick="RW_Reports_Comprehensive._generateReport('' +
        sectionKey +
        '', '' +
        reportId +
        '')" ' +
        'class="bg-blue-50 text-blue-700 px-5 py-2.5 rounded-xl font-bold border border-blue-100">' +
        '<i class="fa-solid fa-rotate ml-1"></i> تحديث</button>' +

        '<button onclick="RW_Reports_Comprehensive._exportReportCsv()" ' +
        'class="bg-emerald-50 text-emerald-700 px-5 py-2.5 rounded-xl font-bold border border-emerald-100">' +
        '<i class="fa-solid fa-file-csv ml-1"></i> CSV</button>' +

        '<button onclick="RW_Reports_Comprehensive._printReport()" ' +
        'class="bg-gray-100 text-gray-600 px-5 py-2.5 rounded-xl font-bold">' +
        '<i class="fa-solid fa-print ml-1"></i> طباعة</button>' +

        '<button onclick="RW_Reports_Comprehensive._closeSection()" ' +
        'class="bg-gray-50 text-gray-600 px-5 py-2.5 rounded-xl font-bold border">' +
        '<i class="fa-solid fa-arrow-right ml-1"></i> رجوع</button>' +
        '</div>' +

        '<div id="report-result" class="mt-6 overflow-x-auto"></div>' +
        '</div>';

    safeHTML(container, html);

    _loadDropdowns(params);
}
```

---

# PATCH 02 — Export CSV + Print

## ابحث بالضبط عن:

`function _printReport() {`

في نهاية الموديول، قرب:

`lines 23302–23309`

احذف الدالة الحالية كاملة واستبدلها بـ:

```javascript
function _exportReportCsv() {
    var resultDiv = byId('report-result');
    if (!resultDiv) {
        _showToast('لا يوجد تقرير للتصدير', 'info');
        return;
    }

    var table = resultDiv.querySelector('table');
    if (!table) {
        _showToast('لا يوجد جدول قابل للتصدير', 'info');
        return;
    }

    var rows = table.querySelectorAll('tr');
    var csv = [];

    function csvCell(value) {
        var s = String(value == null ? '' : value)
            .replace(/?
|/g, ' ')
            .replace(/"/g, '""');
        return '"' + s + '"';
    }

    for (var i = 0; i < rows.length; i++) {
        var cells = rows[i].querySelectorAll('th,td');
        var line = [];

        for (var j = 0; j < cells.length; j++) {
            line.push(csvCell(cells[j].innerText || ''));
        }

        csv.push(line.join(','));
    }

    var blob = new Blob(
        ['﻿' + csv.join('
')],
        { type: 'text/csv;charset=utf-8;' }
    );

    var url = URL.createObjectURL(blob);
    var a = document.createElement('a');

    a.href = url;
    a.download =
        'rawaea-report-' +
        String(_currentReport || 'report') +
        '-' +
        new Date().toISOString().slice(0, 10) +
        '.csv';

    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
}

function _printReport() {
    var resultDiv = byId('report-result');

    if (!resultDiv || !resultDiv.innerHTML) {
        _showToast('لا يوجد تقرير للطباعة', 'info');
        return;
    }

    var printWindow = window.open('', '_blank');

    if (!printWindow) {
        _showToast('الرجاء السماح بالنوافذ المنبثقة', 'warning');
        return;
    }

    var html =
        '<!DOCTYPE html>' +
        '<html dir="rtl">' +
        '<head>' +
        '<meta charset="UTF-8">' +
        '<title>تقرير الروائع ERP</title>' +
        '<link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;700;900&display=swap" rel="stylesheet">' +
        '<style>' +
        'body{font-family:Cairo,sans-serif;padding:20px;color:#111827}' +
        'table{width:100%;border-collapse:collapse;margin-top:15px}' +
        'th,td{border:1px solid #ddd;padding:8px}' +
        'th{background:#f2f2f2;font-weight:800}' +
        '.text-center{text-align:center}' +
        '</style>' +
        '</head>' +
        '<body>' +
        resultDiv.innerHTML +
        '<script>window.onload=function(){window.print();};</script>' +
        '</body></html>';

    printWindow.document.open();
    printWindow.document.write(html);
    printWindow.document.close();
}
```

---

# PATCH 03 — Public API

## ابحث بالضبط عن:

```javascript
return {
    render: render,
    _openSection: _openSection,
    _closeSection: _closeSection,
    _openReport: _openReport,
    _generateReport: _generateReport,
    _printReport: _printReport,
    _showCustomerLedgerDetail: _showCustomerLedgerDetail,
    _showItemMovementDetail: _showItemMovementDetail,
    _showRunsheetDetail: _showRunsheetDetail,
    _showSettlementDetail: _showSettlementDetail
};
```

واستبدله كاملًا بـ:

```javascript
return {
    render: render,
    _openSection: _openSection,
    _closeSection: _closeSection,
    _openReport: _openReport,
    _generateReport: _generateReport,
    _exportReportCsv: _exportReportCsv,
    _printReport: _printReport,
    _showCustomerLedgerDetail: _showCustomerLedgerDetail,
    _showItemMovementDetail: _showItemMovementDetail,
    _showRunsheetDetail: _showRunsheetDetail,
    _showSettlementDetail: _showSettlementDetail
};
```

---

# PATCH 04 — Sales Summary

## ابحث عن البلوك الذي يبدأ حرفيًا بـ:

`if (reportId === 'sales-summary') {`

قرب line 20828.

احذف هذا البلوك كاملًا حتى القوس الذي يسبقه:

`else if (reportId === 'sales-by-customer')`

واستبدله بـ:

```javascript
if (reportId === 'sales-summary') {

    if (customer) {
        await _validateCustomer(customer);
    }

    var q1 = supabase
        .from('orders')
        .select('total_amount')
        .eq('company_id', companyId)
        .in('order_status', ['Invoiced', 'Delivered'])
        .gte('order_date', fromDate)
        .lte('order_date', toDate);

    if (customer) {
        q1 = q1.eq('customer_id', customer);
    }

    var r1 = await q1;

    if (r1.error) throw r1.error;

    data = r1.data || [];

    var totalSales = 0;

    for (var i1 = 0; i1 < data.length; i1++) {
        totalSales += Number(data[i1].total_amount) || 0;
    }

    var avgOrder =
        data.length > 0
            ? totalSales / data.length
            : 0;

    html =
        '<h4 class="font-bold mb-3">ملخص المبيعات</h4>' +
        '<div class="grid grid-cols-1 md:grid-cols-3 gap-4">' +

        '<div class="bg-blue-50 p-4 rounded-xl text-center">' +
        '<p class="text-xs text-gray-500">عدد الفواتير المحققة</p>' +
        '<p class="text-2xl font-black">' +
        data.length +
        '</p></div>' +

        '<div class="bg-green-50 p-4 rounded-xl text-center">' +
        '<p class="text-xs text-gray-500">إجمالي المبيعات</p>' +
        '<p class="text-2xl font-black">' +
        _fmtNum(totalSales) +
        ' EGP</p></div>' +

        '<div class="bg-amber-50 p-4 rounded-xl text-center">' +
        '<p class="text-xs text-gray-500">متوسط الفاتورة</p>' +
        '<p class="text-2xl font-black">' +
        _fmtNum(avgOrder) +
        ' EGP</p></div>' +

        '</div>';
}
```

---

# PATCH 05 — Sales By Customer

## ابحث عن:

`else if (reportId === 'sales-by-customer') {`

قرب line 20887.

استبدل البلوك كاملًا حتى:

`else if (reportId === 'sales-by-item')`

بالآتي:

```javascript
else if (reportId === 'sales-by-customer') {

    if (customer) {
        await _validateCustomer(customer);
    }

    var q2 = supabase
        .from('orders')
        .select('customer_id, customer_name, total_amount')
        .eq('company_id', companyId)
        .in('order_status', ['Invoiced', 'Delivered'])
        .gte('order_date', fromDate)
        .lte('order_date', toDate);

    if (customer) {
        q2 = q2.eq('customer_id', customer);
    }

    var r2 = await q2;

    if (r2.error) throw r2.error;

    data = r2.data || [];

    var customerMap = {};

    for (var i2 = 0; i2 < data.length; i2++) {

        var cid2 = data[i2].customer_id || 'غير محدد';

        if (!customerMap[cid2]) {
            customerMap[cid2] = {
                name: data[i2].customer_name || cid2,
                total: 0,
                count: 0
            };
        }

        customerMap[cid2].total +=
            Number(data[i2].total_amount) || 0;

        customerMap[cid2].count += 1;
    }

    var customerArr =
        Object.keys(customerMap)
            .map(function(key) {
                return {
                    id: key,
                    name: customerMap[key].name,
                    total: customerMap[key].total,
                    count: customerMap[key].count
                };
            })
            .sort(function(a, b) {
                return b.total - a.total;
            });

    var grandCustomerTotal =
        customerArr.reduce(function(sum, row) {
            return sum + row.total;
        }, 0);

    var customerRows = [];

    for (var c2 = 0; c2 < customerArr.length; c2++) {

        var pct2 =
            grandCustomerTotal > 0
                ? (customerArr[c2].total / grandCustomerTotal) * 100
                : 0;

        customerRows.push(
            '<tr class="border-t">' +
            '<td class="p-2">' + _esc(customerArr[c2].id) + '</td>' +
            '<td class="p-2 font-semibold">' + _esc(customerArr[c2].name) + '</td>' +
            '<td class="p-2 text-center">' + customerArr[c2].count + '</td>' +
            '<td class="p-2 text-center font-bold">' + _fmtNum(customerArr[c2].total) + ' EGP</td>' +
            '<td class="p-2 text-center">' + pct2.toFixed(1) + '%</td>' +
            '</tr>'
        );
    }

    html =
        '<h4 class="font-bold mb-3">المبيعات حسب العميل</h4>' +
        _table(
            [
                'كود العميل',
                'اسم العميل',
                'عدد الفواتير',
                'إجمالي المبيعات',
                'النسبة'
            ],
            customerRows
        );
}
```

---

# PATCH 06 — Sales By Item

## ابحث عن:

`else if (reportId === 'sales-by-item') {`

قرب line 20998.

احذف البلوك كاملًا حتى:

`else if (reportId === 'sales-by-area')`

ثم استبدله:

```javascript
else if (reportId === 'sales-by-item') {

    var ordersRes3 = await supabase
        .from('orders')
        .select('id')
        .eq('company_id', companyId)
        .in('order_status', ['Invoiced', 'Delivered'])
        .gte('order_date', fromDate)
        .lte('order_date', toDate);

    if (ordersRes3.error) throw ordersRes3.error;

    var orderIds3 =
        (ordersRes3.data || [])
            .map(function(o) { return o.id; })
            .filter(Boolean);

    if (!orderIds3.length) {

        html =
            '<h4 class="font-bold mb-3">المبيعات حسب الصنف</h4>' +
            '<div class="text-center py-4 text-gray-500">لا توجد بيانات</div>';

    } else {

        var detailsRes3 =
            await supabase
                .from('order_details')
                .select(
                    'item_id, item_code, item_name, qty, qty_delivered, qty_returned, unit_price'
                )
                .in('order_id', orderIds3);

        if (detailsRes3.error) throw detailsRes3.error;

        data = detailsRes3.data || [];

        var itemMap3 = {};

        for (var d3 = 0; d3 < data.length; d3++) {

            var key3 =
                data[d3].item_id ||
                data[d3].item_code;

            if (!key3) continue;

            if (!itemMap3[key3]) {
                itemMap3[key3] = {
                    code: data[d3].item_code || '',
                    name: data[d3].item_name || data[d3].item_code || '',
                    qty: 0,
                    total: 0
                };
            }

            var sourceOrderQty =
                Number(data[d3].qty_delivered) > 0
                    ? Number(data[d3].qty_delivered)
                    : Number(data[d3].qty) || 0;

            var returnedQty =
                Number(data[d3].qty_returned) || 0;

            var netQty =
                Math.max(0, sourceOrderQty - returnedQty);

            itemMap3[key3].qty += netQty;

            itemMap3[key3].total +=
                netQty *
                (Number(data[d3].unit_price) || 0);
        }

        var itemArr3 =
            Object.keys(itemMap3)
                .map(function(key) {
                    return itemMap3[key];
                })
                .sort(function(a, b) {
                    return b.total - a.total;
                });

        var itemRows3 = [];

        for (var ir3 = 0; ir3 < itemArr3.length; ir3++) {

            itemRows3.push(
                '<tr class="border-t">' +
                '<td class="p-2">' + _esc(itemArr3[ir3].code) + '</td>' +
                '<td class="p-2 font-semibold">' + _esc(itemArr3[ir3].name) + '</td>' +
                '<td class="p-2 text-center">' + itemArr3[ir3].qty + '</td>' +
                '<td class="p-2 text-center font-bold">' + _fmtNum(itemArr3[ir3].total) + ' EGP</td>' +
                '</tr>'
            );
        }

        html =
            '<h4 class="font-bold mb-3">المبيعات حسب الصنف</h4>' +
            _table(
                [
                    'كود الصنف',
                    'اسم الصنف',
                    'الكمية الصافية المباعة',
                    'إجمالي المبيعات'
                ],
                itemRows3
            );
    }
}
```

---

# PATCH 07 — Sales By Area

## ابحث عن:

`else if (reportId === 'sales-by-area') {`

قرب line 21117.

استبدله كاملًا:

```javascript
else if (reportId === 'sales-by-area') {

    var r4 = await supabase
        .from('orders')
        .select('area, total_amount')
        .eq('company_id', companyId)
        .in('order_status', ['Invoiced', 'Delivered'])
        .gte('order_date', fromDate)
        .lte('order_date', toDate);

    if (r4.error) throw r4.error;

    data = r4.data || [];

    var areaMap4 = {};

    for (var a4 = 0; a4 < data.length; a4++) {

        var areaKey4 =
            data[a4].area || 'غير محدد';

        areaMap4[areaKey4] =
            (areaMap4[areaKey4] || 0) +
            (Number(data[a4].total_amount) || 0);
    }

    var areaRows4 = [];

    Object.keys(areaMap4)
        .sort()
        .forEach(function(key) {

            areaRows4.push(
                '<tr class="border-t">' +
                '<td class="p-2 font-semibold">' + _esc(key) + '</td>' +
                '<td class="p-2 text-center font-bold">' + _fmtNum(areaMap4[key]) + ' EGP</td>' +
                '</tr>'
            );
        });

    html =
        '<h4 class="font-bold mb-3">المبيعات حسب المنطقة</h4>' +
        _table(
            ['المنطقة', 'إجمالي المبيعات'],
            areaRows4
        );
}
```

---

# PATCH 08 — Inventory Stock Valuation

## ابحث عن:

`else if (reportId === 'inventory-stock') {`

قرب line 21358.

لا تحذف Business logic كله.

استبدل داخل هذا البلوك:

```javascript
var value8 =
    st8.qty *
    (Number(items8[i8].sales_price) || 0);
```

بـ:

```javascript
var cost8 =
    Number(items8[i8].cost_price) || 0;

var value8 =
    st8.qty * cost8;
```

ثم ابحث داخل نفس البلوك عن رؤوس الجدول:

```javascript
'سعر البيع',
'قيمة المخزون'
```

واستبدلهما:

```javascript
'سعر التكلفة',
'قيمة المخزون بالتكلفة'
```

وفي صف العرض استبدل:

```javascript
_fmtNum(items8[i8].sales_price)
```

بـ:

```javascript
_fmtNum(cost8)
```

**السبب:** inventory valuation يجب أن يمثل cost basis وليس retail selling value. هذا يتفق مع Odoo inventory valuation وDaftra Inventory Value وManager Inventory Value patterns.

---

# PATCH 09 — Inventory Movement

## ابحث عن البلوك:

`else if (reportId === 'inventory-movement') {`

قرب line 21499.

احذفه كاملًا واستبدله بـ:

```javascript
else if (reportId === 'inventory-movement') {

    if (!itemCode) {
        safeHTML(
            resultDiv,
            '<div class="text-center py-4 text-gray-500">' +
            'يرجى اختيار صنف' +
            '</div>'
        );
        return;
    }

    var item9 =
        await _validateItem(itemCode);

    var currentUserEmail9 =
        RW_STATE &&
        RW_STATE.app &&
        RW_STATE.app.currentUser
            ? RW_STATE.app.currentUser.email
            : null;

    var movementReport9 =
        await supabase.rpc(
            'inventory_movement_report',
            {
                p_company_id: companyId,
                p_user_email: currentUserEmail9,
                p_from_date: fromDate,
                p_to_date: toDate,
                p_branch_id: null,
                p_item_id: item9.id,
                p_movement_type: null,
                p_query: null,
                p_limit: 500,
                p_offset: 0
            }
        );

    if (movementReport9.error) {
        throw movementReport9.error;
    }

    var payload9 =
        movementReport9.data || {};

    data =
        Array.isArray(payload9.rows)
            ? payload9.rows
            : [];

    var rows9 = [];

    for (var m9 = 0; m9 < data.length; m9++) {

        rows9.push(
            '<tr class="border-t">' +
            '<td class="p-2">' + _esc(data[m9].movement_date) + '</td>' +
            '<td class="p-2">' + _esc(data[m9].branch_name || '') + '</td>' +
            '<td class="p-2">' + _esc(data[m9].movement_type || '') + '</td>' +
            '<td class="p-2">' + _esc(data[m9].reference || data[m9].voucher_id || '') + '</td>' +
            '<td class="p-2 text-center">' + _fmtNum(data[m9].before_qty) + '</td>' +
            '<td class="p-2 text-center">' + _fmtNum(data[m9].effect_qty) + '</td>' +
            '<td class="p-2 text-center font-bold">' + _fmtNum(data[m9].after_qty) + '</td>' +
            '<td class="p-2">' + _esc(data[m9].user_email || '') + '</td>' +
            '</tr>'
        );
    }

    html =
        '<h4 class="font-bold mb-3">الحركة التفصيلية للصنف: ' +
        _esc(item9.name || item9.item_code) +
        '</h4>' +
        '<div class="mb-3 text-xs text-gray-500">' +
        'المصدر: Production inventory_movement_report' +
        '</div>' +
        _table(
            [
                'التاريخ',
                'الفرع',
                'نوع الحركة',
                'المرجع',
                'قبل الحركة',
                'التأثير',
                'بعد الحركة',
                'المستخدم'
            ],
            rows9
        );
}
```

---

# PATCH 10 — Low Stock

## ابحث عن:

`else if (reportId === 'inventory-low-stock') {`

قرب line 21581.

احذف البلوك كاملًا واستبدله بـ:

```javascript
else if (reportId === 'inventory-low-stock') {

    var currentUserEmail10 =
        RW_STATE &&
        RW_STATE.app &&
        RW_STATE.app.currentUser
            ? RW_STATE.app.currentUser.email
            : null;

    var lowStockReport10 =
        await supabase.rpc(
            'inventory_replenishment_report',
            {
                p_company_id: companyId,
                p_user_email: currentUserEmail10,
                p_branch_id: null,
                p_limit: 500,
                p_offset: 0
            }
        );

    if (lowStockReport10.error) {
        throw lowStockReport10.error;
    }

    var lowPayload10 =
        lowStockReport10.data || {};

    var lowRows10 =
        Array.isArray(lowPayload10.rows)
            ? lowPayload10.rows
            : [];

    html =
        '<h4 class="font-bold mb-3">الأصناف الأقل من حد الطلب</h4>' +
        '<div class="mb-3 text-xs text-gray-500">' +
        'المصدر: Production inventory_replenishment_report' +
        '</div>' +
        _table(
            [
                'الفرع',
                'كود الصنف',
                'الصنف',
                'المتاح',
                'المحجوز',
                'حد الطلب',
                'العجز',
                'الكمية المقترحة',
                'قيمة الطلب المقترحة'
            ],
            lowRows10.map(function(it) {

                return (
                    '<tr class="border-t">' +
                    '<td class="p-2">' + _esc(it.branch_name || '') + '</td>' +
                    '<td class="p-2">' + _esc(it.item_code || '') + '</td>' +
                    '<td class="p-2 font-semibold">' + _esc(it.item_name || '') + '</td>' +
                    '<td class="p-2 text-center font-bold">' + _fmtNum(it.available_qty) + '</td>' +
                    '<td class="p-2 text-center">' + _fmtNum(it.allocated_qty) + '</td>' +
                    '<td class="p-2 text-center">' + _fmtNum(it.reorder_point) + '</td>' +
                    '<td class="p-2 text-center font-bold text-red-600">' + _fmtNum(it.deficit_qty) + '</td>' +
                    '<td class="p-2 text-center font-bold text-blue-700">' + _fmtNum(it.recommended_order_qty) + '</td>' +
                    '<td class="p-2 text-center">' + _fmtNum(it.recommended_order_value) + ' EGP</td>' +
                    '</tr>'
                );
            })
        );
}
```

هنا تم حذف fallback الافتراضي:

```
Number(reorder_point) || 5
```

ولا يسمح التقرير باختراع رقم حد طلب غير موجود.

---

# PATCH 11 — Inventory Dormant / Turnover

## ابحث عن:

`else if (reportId === 'inventory-dormant') {`

قرب line 21710.

احذف البلوك كاملًا واستبدله بـ:

```javascript
else if (reportId === 'inventory-dormant') {

    var turnoverReport11 =
        await supabase.rpc(
            'comprehensive_inventory_turnover_report',
            {
                p_company_id: companyId,
                p_from_date: fromDate,
                p_to_date: toDate,
                p_item_id: itemCode
                    ? (await _validateItem(itemCode)).id
                    : null
            }
        );

    if (turnoverReport11.error) {
        throw turnoverReport11.error;
    }

    var turnoverPayload11 =
        turnoverReport11.data || {};

    var turnoverRows11 =
        Array.isArray(turnoverPayload11.rows)
            ? turnoverPayload11.rows
            : [];

    html =
        '<h4 class="font-bold mb-3">تحليل دوران المخزون</h4>' +
        '<div class="mb-3 text-xs text-gray-500">' +
        'المصدر: Production comprehensive_inventory_turnover_report' +
        '</div>' +
        _table(
            [
                'كود الصنف',
                'الصنف',
                'الافتتاحي',
                'الحالي',
                'المتاح',
                'المحجوز',
                'صافي المبيعات',
                'متوسط المخزون',
                'معدل الدوران',
                'متوسط البيع اليومي',
                'أيام التغطية',
                'التكلفة',
                'قيمة المخزون بالتكلفة'
            ],
            turnoverRows11.map(function(it) {

                return (
                    '<tr class="border-t">' +
                    '<td class="p-2">' + _esc(it.item_code || '') + '</td>' +
                    '<td class="p-2 font-semibold">' + _esc(it.item_name || '') + '</td>' +
                    '<td class="p-2 text-center">' + _fmtNum(it.opening_qty) + '</td>' +
                    '<td class="p-2 text-center">' + _fmtNum(it.current_qty) + '</td>' +
                    '<td class="p-2 text-center font-bold">' + _fmtNum(it.available_qty) + '</td>' +
                    '<td class="p-2 text-center">' + _fmtNum(it.allocated_qty) + '</td>' +
                    '<td class="p-2 text-center">' + _fmtNum(it.net_sales_qty) + '</td>' +
                    '<td class="p-2 text-center">' + _fmtNum(it.average_qty) + '</td>' +
                    '<td class="p-2 text-center font-bold">' + _fmtNum(it.turnover_ratio) + '</td>' +
                    '<td class="p-2 text-center">' + _fmtNum(it.avg_daily_sales) + '</td>' +
                    '<td class="p-2 text-center">' +
                    (
                        it.days_on_hand == null
                            ? '—'
                            : _fmtNum(it.days_on_hand)
                    ) +
                    '</td>' +
                    '<td class="p-2 text-center">' + _fmtNum(it.cost_price) + '</td>' +
                    '<td class="p-2 text-center font-bold">' + _fmtNum(it.stock_value_at_cost) + ' EGP</td>' +
                    '</tr>'
                );
            })
        );
}
```

هذه أول مرة يصبح التقرير الحالي المسمى Dormant مرتبطًا فعلًا بحساب Turnover/Days on Hand بدل مجرد:

```
sold at least once / not sold
```

---

# PATCH 12 — Finance General Ledger

## ابحث عن:

`else if (reportId === 'finance-general-ledger') {`

قرب line 22422.

احذف البلوك كاملًا واستبدله بـ:

```javascript
else if (reportId === 'finance-general-ledger') {

    if (!account) {

        safeHTML(
            resultDiv,
            '<div class="text-center py-4 text-gray-500">' +
            'يرجى اختيار حساب' +
            '</div>'
        );

        return;
    }

    var account12 =
        await _validateAccount(account);

    var glReport12 =
        await supabase.rpc(
            'accountant_gl_account_activity',
            {
                p_account_id: account12.id,
                p_from_date: fromDate,
                p_to_date: toDate
            }
        );

    if (glReport12.error) {
        throw glReport12.error;
    }

    data =
        Array.isArray(glReport12.data)
            ? glReport12.data
            : [];

    var rows12 = [];

    for (var g12 = 0; g12 < data.length; g12++) {

        rows12.push(
            '<tr class="border-t">' +
            '<td class="p-2">' + _esc(data[g12].entry_date) + '</td>' +
            '<td class="p-2">' + _esc(data[g12].entry_code || '') + '</td>' +
            '<td class="p-2">' + _esc(data[g12].reference || '') + '</td>' +
            '<td class="p-2">' + _esc(data[g12].description || '') + '</td>' +
            '<td class="p-2 text-center">' + _fmtNum(data[g12].debit) + '</td>' +
            '<td class="p-2 text-center">' + _fmtNum(data[g12].credit) + '</td>' +
            '<td class="p-2 text-center font-bold">' + _fmtNum(data[g12].running_balance) + '</td>' +
            '</tr>'
        );
    }

    html =
        '<h4 class="font-bold mb-3">دفتر الأستاذ العام — ' +
        _esc(account12.account_name || account12.account_code) +
        '</h4>' +
        _table(
            [
                'التاريخ',
                'رقم القيد',
                'المرجع',
                'البيان',
                'مدين',
                'دائن',
                'الرصيد الجاري'
            ],
            rows12
        );
}
```

---

# PATCH 13 — Treasury Company Scope

## ابحث داخل:

`else if (reportId === 'finance-treasury') {`

قرب line 22537.

ابحث عن:

```var r20 =
    await supabase
        .from('cash_box')
        .select('*')
        .eq(
            'treasury_id',
            treasury
        )
```

احذفه واستبدله بـ:

```javascript
var r20 =
    await supabase
        .from('cash_box')
        .select('*')
        .eq('company_id', companyId)
        .eq('treasury_id', treasury)
        .order(
            'voucher_date',
            { ascending: false }
        );
```

لا تغير باقي المنطق.

---

# PATCH 14 — Finance Tax Capability Gate

## ابحث عن:

`else if (reportId === 'finance-tax') {`

قرب line 22665.

احذف البلوك الحالي كاملًا:

```javascript
else if (reportId === 'finance-tax') {
    html = '<div class="text-center py-4 text-amber-700 bg-amber-50 border border-amber-200 rounded-xl">Capability Gate: مصدر Production سلطوي للضريبة غير مثبت، لذلك لم يتم اختلاق التقرير.</div>';
}
```

واستبدله بـ:

```javascript
else if (reportId === 'finance-tax') {

    var taxReport14 =
        await supabase.rpc(
            'finance_tax_report',
            {
                p_company_id: companyId,
                p_from: fromDate,
                p_to: toDate
            }
        );

    if (taxReport14.error) {
        throw taxReport14.error;
    }

    var taxRows14 =
        Array.isArray(taxReport14.data)
            ? taxReport14.data
            : [];

    var taxSettlementReport14 =
        await supabase.rpc(
            'finance_tax_settlements_report',
            {
                p_company_id: companyId,
                p_from: fromDate,
                p_to: toDate
            }
        );

    if (taxSettlementReport14.error) {
        throw taxSettlementReport14.error;
    }

    var taxSettlementRows14 =
        Array.isArray(taxSettlementReport14.data)
            ? taxSettlementReport14.data
            : [];

    html =
        '<h4 class="font-bold mb-3">تقرير الضرائب</h4>' +
        '<div class="mb-6">' +
        _table(
            [
                'الكود',
                'الضريبة',
                'النسبة',
                'ضريبة المدخلات',
                'ضريبة المخرجات',
                'ضرائب أخرى',
                'صافي الضريبة'
            ],
            taxRows14.map(function(row) {
                return (
                    '<tr class="border-t">' +
                    '<td class="p-2">' + _esc(row.code) + '</td>' +
                    '<td class="p-2 font-semibold">' + _esc(row.name) + '</td>' +
                    '<td class="p-2 text-center">' + _fmtNum(row.rate) + '%</td>' +
                    '<td class="p-2 text-center">' + _fmtNum(row.input_tax) + '</td>' +
                    '<td class="p-2 text-center">' + _fmtNum(row.output_tax) + '</td>' +
                    '<td class="p-2 text-center">' + _fmtNum(row.other_tax) + '</td>' +
                    '<td class="p-2 text-center font-bold">' + _fmtNum(row.net_tax) + '</td>' +
                    '</tr>'
                );
            })
        ) +
        '</div>' +

        '<h4 class="font-bold mb-3">تسويات الضرائب</h4>' +
        _table(
            [
                'رقم التسوية',
                'من',
                'إلى',
                'المخرجات',
                'المدخلات',
                'الصافي',
                'الحالة'
            ],
            taxSettlementRows14.map(function(row) {
                return (
                    '<tr class="border-t">' +
                    '<td class="p-2 font-semibold">' + _esc(row.settlement_code) + '</td>' +
                    '<td class="p-2">' + _esc(row.from_date) + '</td>' +
                    '<td class="p-2">' + _esc(row.to_date) + '</td>' +
                    '<td class="p-2 text-center">' + _fmtNum(row.output_tax) + '</td>' +
                    '<td class="p-2 text-center">' + _fmtNum(row.input_tax) + '</td>' +
                    '<td class="p-2 text-center font-bold">' + _fmtNum(row.net_tax) + '</td>' +
                    '<td class="p-2 text-center">' + _esc(row.status || '') + '</td>' +
                    '</tr>'
                );
            })
        );
}
```

---

# PATCH 15 — Report Freshness Metadata

## ابحث عن السطر الحالي داخل:

`_generateReport`

الذي يبدأ:

```javascript
safeHTML(resultDiv, html);
```

في نهاية الـtry، قبل:

```catch (e)
```

استبدله بـ:

```javascript
safeHTML(
    resultDiv,
    html +
    '<div class="mt-4 pt-3 border-t text-xs text-gray-400 flex flex-wrap justify-between gap-2">' +
    '<span>المصدر: Production</span>' +
    '<span>آخر تنفيذ: ' +
    _esc(
        new Date().toLocaleString('ar-EG')
    ) +
    '</span>' +
    '</div>'
);
```

---

# PATCH 16 — Local Date Instead Of UTC Date In Report UI

داخل `_openReport` الجديد تم علاج ذلك بالفعل.

لا تعدّل أي date code آخر في النظام.

---

# 13. Reports Deliberately NOT Modified

هذه ليست أخطاء مثبتة، لذلك لم يتم تغييرها:

## sales-order-status

هو تقرير lifecycle وليس sales revenue report.

يجب أن يعرض حالات:

- Draft
- Confirmed
- Pending
- Invoiced
- Delivered
- Returned
- Cancelled

ولا يجب تحويله إلى Sales Revenue report.

## sales-runsheet-performance

هذا report تشغيلي مميز لـRAWAEA.

لا يتم تبسيطه أو إعادة بنائه وفق نماذج ERP المكتبية.

## sales-customer-ledger

يُبقي على ledger contract الحالي.

## Purchase reports

لم يتم اختراع Purchase Analytics فوق جداول غير مثبتة.

## CRM

لم يتم تحويل customer analysis إلى segmentation اصطناعي؛ لا توجد contract definitions حالية تثبت معاني "New / Stopped" بما يكفي لإضافة معيار زمني تخميني.

## Logistics

تم الإبقاء على:

- loading/unloading
- returns
- settlement
- driver performance

لأنها مرتبطة بدورة RAWAEA التشغيلية.

## HR attendance / salary

تبقى Capability Gated.

الـProduction current HR contract لا يثبت مصدرًا تشغيليًا صالحًا للتقريرين.

---

# 14. Why Inventory Turnover Was A Real Gap

النص الحالي:

```
تحليل دوران المخزون (الأصناف الراكدة)
```

لكن الحساب الفعلي كان:

```
stock > 0
AND
item was not seen in orders
```

هذا ليس Turnover.

العقد الجديد يحوّله إلى:

```
Opening Stock
+
Closing Stock
+
Average Stock
+
Net Sales
+
Turnover Ratio
+
Daily Sales
+
Days on Hand
+
Cost
+
Stock Value
```

ولا يقرر أن الصنف "راكد" إلا عندما تتوفر البيانات اللازمة لهذا التحليل.

هذه النقطة متسقة مع SAP Inventory Status وOdoo Warehouse Metrics وDaftra Inventory Turnover وDaftra Detailed Stock Reports وDynamics Inventory Transaction/Availability patterns.

---

# 15. Why Low Stock Was Rewired

المنطق القديم:

```
reorder_point null
→ 5
```

هذا تخمين غير مقبول.

الـProduction engine الحالي:

`inventory_replenishment_report`

هو المصدر الذي يملك:

- available
- allocated
- reorder point
- max quantity
- deficit
- recommended order
- cost
- recommended order value

لذلك Mother يجب أن تعرض Production result بدل إعادة حساب المعنى.

---

# 16. Why Inventory Movement Was Rewired

الـcurrent Source كان:

```
select inventory_log
```

لكن Production لديها:

`inventory_movement_report`

وهذا contract يضيف:

- before_qty
- effect_qty
- after_qty
- branch
- validation
- company context
- user context
- pagination

وبالتالي القراءة المباشرة القديمة كانت أقل نضجًا من الـProduction contract.

---

# 17. Why Finance GL Was Rewired

الـcurrent source كان يجمع:

- journal_entries
- journal_lines

ويعرض debit/credit فقط.

لكن Production لديه بالفعل:

`accountant_gl_account_activity`

ويحسب:

- opening balance
- transaction rows
- running balance
- account guard
- company guard

إعادة استخدامه أقوى وأكثر اتساقًا.

---

# 18. Why Finance Tax Was Rewired

الـcurrent UI كان يعرض:

```
Capability Gate
```

رغم أن Production أثبت مباشرة وجود:

`finance_tax_report`

و:

`finance_tax_settlements_report`

وكلاهما يتحقق من current user company context.

إذن الـGate أصبحت historical residue وليس Production reality.

---

# 19. Current Production Probes

تم تنفيذ probe authenticated على:

- `inventory_movement_report` → success, current rows = 0
- `inventory_replenishment_report` → success, rows returned
- `finance_tax_report` → success, empty data because no current tax transactions
- `finance_tax_settlements_report` → success, empty data because no settlements
- `comprehensive_inventory_turnover_report` → success under real auth context

الـempty arrays هنا تعكس Production data state، وليس غياب العقد.

---

# 20. Important Data Observation

Current Production:

```
Orders = 0
Purchase Orders = 0
Receiving = 0
Runsheets = 0
Settlements = 0
Journal Entries = 2
```

لذلك:

- لا يجوز صناعة KPI مبيعات وهمي.
- لا يجوز إعلان sales trend.
- لا يجوز إعلان inventory turnover performance.
- لا يجوز اختبار customer sales ranking بنتائج مصطنعة.

ما يمكن إثباته الآن هو:

**Contract correctness + tenant isolation + report source correctness.**

وليس business performance.

---

# 21. What Was Fixed In Production

## Production FIX #1

تم إنشاء:

`comprehensive_inventory_turnover_report`

Status:

```
PRODUCTION DEPLOYED
PRODUCTION AUTH VERIFIED
PRODUCTION ROLLBACK NOT APPLICABLE — READ-ONLY
```

## No Production changes were made to:

- orders
- order_details
- stock_branches
- inventory_log
- stock_vouchers
- journal_entries
- customers
- suppliers
- runsheets
- operational engines

---

# 22. What Was NOT Changed

```
main.html = NOT CHANGED
Mother runtime = NOT deployed by this session
Browser authenticated E2E = not available
Operational workflows = untouched
Inventory writer closures = untouched
Sales transaction writers = untouched
HR Production core = untouched
CRM Production core = untouched
```

---

# 23. Required Verification After Owner Applies Source Surgery

بعد تطبيق الـ16 patches:

## Gate 1 — JavaScript syntax

شغّل syntax validation على **الـassembled Mother file**.

الهدف:

```
SyntaxError = 0
```

## Gate 2 — Load

فتح:

`RW_Reports_Comprehensive`

يجب أن يعرض:

```
6 sections
38 reports
```

## Gate 3 — Sales

اختبر:

- sales-summary
- sales-by-customer
- sales-by-item
- sales-by-area
- sales-order-status
- sales-runsheet-performance

## Gate 4 — Inventory

اختبر:

- inventory-stock
- inventory-movement
- inventory-low-stock
- inventory-dormant

وتأكد أن Inventory value يظهر **cost value** وليس sales value.

## Gate 5 — Finance

اختبر:

- trial balance
- P&L
- balance sheet
- cash flow
- GL
- treasury
- customer aging
- supplier aging
- GL activity
- period readiness
- reconciliation
- exceptions
- tax

## Gate 6 — Export

اختبر:

```
CSV
Print
```

## Gate 7 — Company isolation

يجب ألا يعرض أي report بيانات شركة أخرى.

## Gate 8 — Last updated

يظهر:

```
المصدر: Production
آخر تنفيذ: ...
```

## Gate 9 — Production reread

بعد أي Browser action:

أعد قراءة Production.

لا يجوز:

```
Browser PASS
→
Production assumed PASS
```

---

# 24. Final Responsibility Matrix

| Report capability | Current Source | Production Contract | Surgical action |
|---|---|---|---|
| Sales summary | direct orders | order lifecycle | filter realized statuses |
| Sales by customer | direct orders | order lifecycle | filter realized statuses |
| Sales by item | direct order_details | order fulfillment fields | net sold quantity |
| Sales by area | direct orders | order lifecycle | filter realized statuses |
| Inventory stock | selling-price valuation | cost_price exists | cost valuation |
| Inventory movement | direct inventory_log | inventory_movement_report | rewire |
| Low stock | local fallback logic | inventory_replenishment_report | rewire |
| Dormant | simplistic no-sale test | new turnover contract | rewire |
| General ledger | direct journal query | accountant_gl_account_activity | rewire |
| Treasury | direct cash_box | company-scoped table | add company filter |
| Tax | stale Capability Gate | finance_tax_report + settlement | rewire |
| Other reports | existing contracts | existing | leave untouched |

---

# 25. Zero-Debt Position

التبويب الآن بعد هذا الإغلاق لا يزال ليس Browser-closed لأن owner-managed Mother cutover لم يحدث داخل هذه الجلسة.

لكن حدود الـProduction reporting contract التي كانت ناقصة أصبحت:

```
Production Backend:
CLOSED for added Inventory Turnover capability

Existing Production reporting RPCs:
VERIFIED

Source surgery:
READY

Main.html:
UNTOUCHED BY THIS SESSION

Browser E2E:
OPEN

Overall Comprehensive Reports:
OPEN UNTIL OWNER SOURCE CUTOVER + RUNTIME E2E
```

لا يتم استخدام كلمة:

```
100% CLOSED
```

قبل Browser gate.

---

# 26. Session Continuity — Start Here Next Time

ابدأ دائمًا من:

## Step 1

اقرأ:

`CURRENT_STATE.md`

## Step 2

اقرأ هذا التقرير:

`Report238_COMPREHENSIVE_REPORTS_FORENSIC_SURGICAL_CLOSURE_20260918.md`

## Step 3

تحقق من:

System HEAD:

`f8117693e8b7c6f1d6a4aaffbb0f17765f4aa064`

Mother HEAD:

`fdfdb2bf03271e8eedad81ad8400c243b89c33a5`

Mother main blob:

`468da111b9da992331dba9162c6c6e6509b76004`

## Step 4

لا تعتمد على old CURRENT_STATE hashes إذا اختلفت عن Git الحالي.

## Step 5

افتح:

`RW_Reports_Comprehensive`

ولا تعدّل أي report ثبت أنه سليم.

## Step 6

تحقق من Production:

`fiilmooggumokxanwiyx`

## Step 7

بعد owner cutover:

```
Syntax
→
Mother load
→
Report smoke tests
→
Export
→
Production reread
→
Browser E2E
→
Final state update
```

---

# 27. Governance Notes For Future CTO

1. Report data is not truth merely because a report exists.
2. A label is not a contract.
3. A table query is not automatically the authoritative reporting source.
4. A capability gate must be re-verified against current Production before remaining active.
5. No fallback business constants without a proven contract.
6. No report may silently use selling price as stock valuation.
7. No report may claim performance when Production has no supporting transactions.
8. No cross-company lookup.
9. No operational writer may be re-opened from a reporting concern alone.
10. RAWAEA's field workflow remains an original business capability and must not be simplified into generic ERP reporting.

---

# 28. Final Self-Audit

## What I Proved

- Current Production has one company.
- Current Mother source is `468da111b9da992331dba9162c6c6e6509b76004`.
- Comprehensive module contains 38 reports.
- Production contains specialized inventory reporting contracts.
- Production contains specialized tax reporting contracts.
- Production contains specialized GL activity reporting.
- New inventory turnover contract is deployed.
- New inventory turnover contract rejects missing authenticated company context.
- New inventory turnover contract works under authenticated company context.
- Current Production has no business order activity for the test window.
- Existing report definitions were not all blindly rewritten.
- Main.html was not modified by this task.

## What I Did Not Prove

- Authenticated browser click-by-click E2E after owner source cutover.
- Actual production UI rendering after source surgery.
- Export/Print runtime after owner cutover.
- Performance under large real transaction volumes.
- Tax business output because current Production tax transaction data is empty.
- Sales analytics because current Production order data is empty.

## What I Fixed

- Production Inventory Turnover contract.
- Production auth guard for that contract.
- Canonical Git migration for that contract.
- Exact Mother surgical source replacements for the proven reporting gaps.

## What I Initially Found But Did Not Change

- CRM segmentation semantics.
- Runsheet workflow.
- Delivery logic.
- Inventory movement engines.
- Sales transaction engines.
- HR contracts.

## What Could Still Be Wrong

Only after owner cutover:

- consumer wiring
- syntax assembly
- browser runtime
- actual role-based access visibility

These require browser/source execution evidence.

## Final Status

```
GLOBAL COMPREHENSIVE REPORTS FORENSIC = COMPLETE
PRODUCTION REPORTING CONTRACT VERIFICATION = COMPLETE
PRODUCTION TURNOVER CONTRACT = DEPLOYED
SURGICAL MOTHER REPLACEMENTS = READY
MAIN.HTML = UNTOUCHED
BROWSER E2E = OPEN
OVERALL TAB = OPEN UNTIL CUTOVER + E2E
```

---

# 29. Canonical Production Migration

File:

`supabase/migrations/20260918_comprehensive_inventory_turnover_report.sql`

Commit:

`f8117693e8b7c6f1d6a4aaffbb0f17765f4aa064`

---

# 30. End Of Closure Report

القاعدة للجلسة التالية:

```
DO NOT REOPEN CLOSED ENGINES

VERIFY CURRENT GIT
VERIFY CURRENT SOURCE
VERIFY CURRENT PRODUCTION
VERIFY CURRENT DATABASE
VERIFY CURRENT DEPLOYMENT

THEN CONTINUE FROM THE OPEN GATE ONLY
```
