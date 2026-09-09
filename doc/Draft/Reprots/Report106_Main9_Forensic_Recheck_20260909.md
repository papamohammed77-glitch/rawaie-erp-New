# RAWAEA ERP — Report106
## إعادة الفحص الجنائي النهائي لحزمة جراحة Main9 — 2026-09-09

## 0. المبدأ الحاكم

تم تنفيذ هذه الجولة وفق التسلسل:

`UNDERSTAND → RECONSTRUCT HISTORICAL CONTRACT → TRACE CURRENT BEHAVIOR → TRACE DATA/AUTH CONTROL FLOW → IDENTIFY ACTUAL GAP → SURGICAL FIX PACKAGE → VERIFY → DOCUMENT`

ولا تم التعامل مع أي تقرير تاريخي باعتباره Current Truth.

الهدف الوظيفي ما زال Gold/Diamond: استكمال التبويب وظيفيًا وليس شكليًا، مع الحفاظ على العقود التاريخية الصحيحة وعدم اختلاق بيانات أو Capabilities غير مثبتة.

---

## 1. Current Truth Reconciliation

تمت إعادة فتح:

- `CURRENT_STATE.md`
- `Report104_Main9_Forensic_Recheck_20260909.md`
- `Report105_Main9_Forensic_Recheck_20260909.md`
- `MASTER - RAWAEA ERP.md`
- `MASTER - RAWAEA ERP - UNIFIED CONTINUITY & MAIN1 EXECUTION.md`
- `MASTER - RAWAEA ERP FORENSIC CONTINUITY GOVERNANCE v2.md`
- `Report101_main9`
- `Current/PWA/main2/main9.md`
- `.github/workflows/forensic_main_assembly.yml`
- Production PostgreSQL contracts الحالية

الحالة الحاكمة الحالية هي Report105/CURRENT_STATE وليس Report104، لأنهما أحدث زمنيًا.

---

## 2. Git Verification

Current `main` HEAD عند نقطة هذا التحقق:

`57f10d6756a99ae6cd5efe178b9fd601097c8cd9`

Main9:

`Current/PWA/main2/main9.md`

SHA:

`a72b970709ce69192bd47824685e99962aaf9fd8`

الملف لم يُعدّل مباشرة في هذه الجولة، احترامًا لـOwner Source Surgery boundary.

تم التأكد من وجود جميع أجزاء Main2 من `main1.md` إلى `main11.md`، وأن Workflow الحالي يستخدم:

`Current/PWA/main2/**`

كمصدر تحرير و`Current/PWA/New-main` كناتج Assembly.

---

## 3. Main9 Direct Forensic Result

تمت قراءة Main9 الحالي من Git blob مباشرة والتحقق من تسلسله وبنيته حتى النهاية.

تم إثبات وجود الإصدارات القديمة من:

- `_loadDashboardData`
- `_loadDetailedReports`
- `_loadDropdowns`
- `_showCustomerLedgerDetail`
- `_showItemMovementDetail`
- `_showRunsheetDetail`
- `_showSettlementDetail`
- `_generateReport`

كما تم إثبات أن:

- `M9-01` موجود ومغلق فعليًا.
- لا يوجد مبرر لإعادة تطبيق `M9-01`.
- الملف ينتهي عند إغلاق `RW_Reports_Comprehensive` ثم `window.RW_Reports_Comprehensive = ...` دون tail إضافي بعده.
- لا يوجد دليل من المصدر الحالي يبرر إعادة هيكلة حدود `<script>` داخل Main9 باعتباره fragment منفصلًا.

---

## 4. Production Snapshot — Same Report Window

تمت مزامنة Production مباشرة عند:

`2026-09-09 08:56:26.637806 UTC`

العدادات:

- companies = 1
- branches = 2
- users = 24
- items = 17
- customers = 3
- suppliers = 1
- treasury = 1
- chart_of_accounts = 17
- orders = 0
- runsheets = 0
- purchase_orders = 0
- stock_vouchers = 0
- stock_branches = 20
- inventory_log = 3
- receiving = 0
- receiving_details = 0
- journal_entries = 2

الشركة الحالية المثبتة مباشرة:

`00000000-0000-0000-0000-000000000001` / `الروائع`

تم أيضًا التحقق مباشرة من Inventory invariants:

- negative_stock = `0`
- invalid_reservation = `0`
- available_mismatch = `0`

لا يوجد دليل Production جديد يبرر إعادة فتح Inventory Core.

---

## 5. Production Contracts Revalidated

تم إثبات:

- `items.item_code` = Global UNIQUE.
- `stock_branches` لا يحتوي `company_id`; tenant scope عبر `branch_id -> branches.company_id`.
- `customer_followups.company_id` موجود.
- `daily_settlements.company_id` موجود.
- `cash_box.company_id` موجود.
- `journal_entries.company_id` موجود.
- `users.company_id` موجود.
- `runsheets.company_id` موجود.
- Finance RPCs السلطوية موجودة: `get_trial_balance`, `get_profit_loss`, `get_balance_sheet_data`, `get_cash_flow`, `get_pnl_by_cost_center`, `get_budget_vs_actual`.
- Returns reporting must use `SalesReturn` / `DirectReturn`; plain `Return` غير مدعوم في `post_stock_movement`.
- HR Attendance/Salary لا يوجد لهما مصدر Production سلطوي مثبت ضمن الجولة الحالية، لذا يجب Capability Gate وعدم الإيهام باكتمالهما.

---

## 6. Main9 Final Defect Matrix

### M9-01
Closed. لا يعاد فتحه.

### M9-02
مفتوح. السبب: `RW_STATE` مستخدم كfallback لمصدر التقرير، stock لا يعتمد Available Stock، ويوجد معنى Forecast غير مثبت.

الإجراء المطلوب: Production Item/Customer query مباشر، Company-scoped orders، Branch-scoped stock، Available Stock، وإزالة معنى Forecast غير المدعوم.

### M9-03
مفتوح. السبب: dropdowns لا تقوم بreset قبل append في النسخة الحالية.

الإجراء المطلوب: reset لكل select، Company scope للـtenant entities، UUID identity للكيانات ذات UUID، و`item_code` للصنف لأنه Global UNIQUE.

### M9-04
مفتوح. السبب: `customer_ledger.customer_id` يُستخدم بدون validation يثبت أن العميل يتبع الشركة الحالية.

### M9-05
مفتوح. السبب: `inventory_log` يُقرأ بـ`item_code` فقط دون Company/Item identity validation.

### M9-06
مفتوح. السبب: runsheet lookup وorders linkage غير Company-scoped، و`orders.runsheet_id` يُعامل خطأً كـrunsheet code بدل UUID.

### M9-07
مفتوح. السبب: settlement lookup غير Company-scoped و`runsheet_id` يعرض كرمز دون resolve مضبوط.

### M9-08
مفتوح. السبب: مجموعة التقارير الشاملة تحتوي Global reads وRW_STATE reads وplain `Return` وplaceholders، وبعض Finance reads لا تربط بسلطوية Production مباشرة.

### M9-09
مفتوح. السبب: التقرير التفصيلي يستخدم RW_STATE، لا يستخدم `max_qty`، ولا يربط order_details بأوردرات الشركة.

---

## 7. Surgical Package Decision

أُعيد اعتماد Owner Source Surgery للحزم M9-02..M9-09 دفعة واحدة، مع منع إعادة M9-01.

حدود الحذف يجب أن تعتمد على:

`START EXACT HEADING + FULL FUNCTION + NEXT EXACT MARKER`

ولا تعتمد على رقم السطر وحده.

أرقام البداية الحالية:

- M9-02 `_loadDashboardData` = 67
- M9-09 `_loadDetailedReports` = 260
- M9-03 `_loadDropdowns` = 654
- M9-04 `_showCustomerLedgerDetail` = 811
- M9-05 `_showItemMovementDetail` = 828
- M9-06 `_showRunsheetDetail` = 845
- M9-07 `_showSettlementDetail` = 875
- M9-08 `_generateReport` = 893

هذه الأرقام مرجعية للمصدر الحالي قبل Owner Surgery فقط، ويجب الاعتماد في الحذف على الحدود النصية الكاملة.

---

## 8. Important Correction to Earlier Packages

لا يجوز نسخ Report101 حرفيًا.

التصحيحات الإلزامية التي أصبحت جزءًا من الحزمة النهائية:

1. لا `RW_STATE.data.items` كمصدر تقرير عند توفر Production Item Master.
2. لا `RW_STATE.data.customers` كمصدر تقرير عند توفر Production Customers.
3. لا plain `Return`.
4. لا Forecast/AI semantics من reorder/average-order heuristic.
5. `max_qty` يجب أن يدخل في M9-09 لأنه مستخدم في منطق التوصية.
6. كل tenant-owned lookup يجب أن يحمل Company scope.
7. `stock_branches` scope عبر Company branches.
8. `order_details` لا تقرأ global؛ تبنى من Order IDs التي جُلبت من الشركة نفسها.
9. Finance reporting يستخدم RPCs السلطوية الحالية.
10. HR Attendance/Salary وTax تبقى Capability-Gated عندما لا يوجد مصدر سلطوي مثبت.

---

## 9. Syntax / Integration Status

تم فحص المصدر الحالي من Git حتى EOF والتحقق من إغلاق الوحدات والدوال الرئيسية.

لكن:

`POST-SURGERY SYNTAX = NOT PROVEN`

لأن Owner Source Surgery لم يُنفذ بعد.

ويظل التسلسل الصحيح بعد تنفيذ الجراحة:

`Owner Main9 Surgery`
→ `Read Main9 to EOF`
→ `Syntax validation`
→ `Main2 integration match`
→ `Governed Assembly`
→ `node --check`
→ `Browser/PWA smoke`
→ `Production UI smoke`

ولا يجوز تجاوز أي Gate.

---

## 10. What Was Not Done

- لم يتم تعديل `Current/PWA/main2/main9.md` مباشرة.
- لم يتم تشغيل Assembly.
- لم يتم إعلان Main9 Closed.
- لم يتم إعلان Gold/Diamond.
- لم يتم إعادة فتح Inventory Core.

هذه ليست نواقص تنفيذية؛ إنها التزامات Owner Source boundary وNo-False-Closure.

---

## 11. FINAL SELF-AUDIT

### What I Proved
- Report105/CURRENT_STATE أحدث من Report104 وتم التعامل معه كـCurrent checkpoint.
- Current Main9 SHA ما زال `a72b970...`.
- M9-01 مغلق.
- M9-02..M9-09 ما زالت تحتوي النسخ القديمة فعليًا.
- Production الحالية شركة واحدة بالأعداد المثبتة أعلاه.
- Inventory invariants نظيفة.
- Finance RPC capabilities موجودة.
- Item identity global UNIQUE.
- Assembly source path صحيح.

### What I Did Not Prove
- Owner execution of M9-02..M9-09.
- Post-surgery Main9 syntax.
- Main2 assembly output.
- Browser/PWA runtime after surgery.
- Full Production UI report smoke.
- Gold/Diamond parent closure.

### Final Status

`M9-01 = SOURCE CLOSED`
`M9-02..M9-09 = OWNER SOURCE SURGERY REQUIRED`
`MAIN9 = OPEN`
`MAIN2 ASSEMBLY = BLOCKED`
`PRODUCTION INVENTORY CORE = VERIFIED / NO REOPEN JUSTIFIED`
`GOLD/DIAMOND = NOT CLOSED`
