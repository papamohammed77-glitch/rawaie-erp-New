# RAWAEA ERP — Report105
## إعادة الفحص الجنائي الحاكم لـ Main9 وربطها بـProduction الحالية — 2026-09-09

## 0. الهدف

تم تنفيذ إعادة الفحص من مصادر الحقيقة المباشرة، لا من التقارير السابقة وحدها، مع الالتزام بمبدأ:

`UNDERSTAND → RECONSTRUCT HISTORICAL CONTRACT → TRACE CURRENT BEHAVIOR → TRACE DATA/AUTH CONTROL FLOW → IDENTIFY ACTUAL GAP → SURGICAL FIX → TEST → PRODUCTION VERIFY`

نطاق هذه الجولة هو `Current/PWA/main2/main9.md` فقط، مع عدم تعديل المصدر الأم مباشرة لأن عقد المشروع يحدد Main9 كـOwner Source Operation.

---

## 1. المصادر التي تمت إعادة فتحها

- `doc/Draft/Reprots/Report104_Main9_Forensic_Recheck_20260909.md`
- `doc/Draft/Reprots/Report103_Main9_Forensic_Recheck_20260909.md`
- `doc/Draft/Reprots/Report102_Main9_Forensic_Recheck_20260909.md`
- `doc/Draft/Reprots/Report101_main9`
- `doc/Draft/medhat/MASTER - RAWAEA ERP.md`
- `doc/Draft/medhat/MASTER - RAWAEA ERP - UNIFIED CONTINUITY & MAIN1 EXECUTION.md`
- `doc/Draft/medhat/MASTER - RAWAEA ERP FORENSIC CONTINUITY GOVERNANCE v2.md`
- تقرير المبادئ الحاكمة
- `CURRENT_STATE.md`
- `.github/workflows/forensic_main_assembly.yml`
- `Current/PWA/main2/main9.md`
- `Original/PWA/main/main9.md` للتاريخ فقط
- قائمة `Current/PWA/main2/main1.md ... main11.md`
- PostgreSQL Production contracts الحالية

---

## 2. Current Git Truth

Git branch `main` الحالي هو:

`c994800ed90cc146207e45ab9ef16da3a5548b2f`

رسالة الـcommit:

`docs(cto): update current state after Report104 Main9 forensic recheck`

Main9 الحالي:

`Current/PWA/main2/main9.md`

SHA الحالي:

`a72b970709ce69192bd47824685e99962aaf9fd8`

تمت إعادة فتح الملف الحالي من Git، وما زالت النسخ القديمة من:

- `_loadDashboardData`
- `_loadDetailedReports`
- `_loadDropdowns`
- `_showCustomerLedgerDetail`
- `_showItemMovementDetail`
- `_showRunsheetDetail`
- `_showSettlementDetail`
- `_generateReport`

موجودة فعليًا.

`M9-01` موجود بالفعل ولا يجوز تكراره.

---

## 3. Owner Source Boundary

العقد الحاكم يحدد أن:

`Current/PWA/main2/main9.md`

هو **Owner Source**، وأن المساعد لا ينفذ الجراحة النصية عليه مباشرة.

لذلك لم يتم تعديل Main9 بواسطة هذه الجولة، ولم يتم اختلاق SHA جديد أو إعلان إغلاق وهمي.

المطلوب الفعلي بعد هذا التقرير هو Owner Source Surgery للحزم:

`M9-02..M9-09`

ثم إعادة قراءة Main9 من أول حرف إلى EOF والتحقق قبل أي Assembly.

---

## 4. Production Snapshot — Direct Reconciliation

تمت إعادة مزامنة Production مباشرة عند:

`2026-09-09 08:42:57.712837 UTC`

الأعداد الحالية:

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

---

## 5. Current Inventory Integrity — Direct

آخر تحقق مباشر:

`2026-09-09 08:44:38.440623 UTC`

النتائج:

- negative_stock = `0`
- invalid_reservation = `0`
- available_mismatch = `0`

النتيجة:

**لا توجد إشارة Production حالية تبرر إعادة فتح Inventory Core.**

العقد الحاكم ما زال:

`Physical Stock Movement → post_stock_movement → stock_branches + inventory_log`

و:

`reserve_stock / release_stock_reservation = Reservation-only`

---

## 6. Current PostgreSQL Contracts Revalidated

تمت إعادة التحقق من التعريفات الحالية للدوال التالية:

- `post_stock_movement`
- `receive_purchase_atomic`
- `complete_return_atomic`
- `complete_order_delivery_atomic`
- `get_trial_balance`
- `get_profit_loss`
- `get_balance_sheet_data`
- `get_cash_flow`
- `get_pnl_by_cost_center`
- `get_budget_vs_actual`

النقاط المهمة:

1. `items.item_code` = `UNIQUE` عالميًا.
2. `stock_branches` لا يحتوي `company_id`; Company scope يمر من `branch_id` إلى `branches.company_id`.
3. `post_stock_movement` يقبل `SalesReturn` و`DirectReturn` ولا يقبل `Return` منفردًا.
4. `receive_purchase_atomic` الحالي يستقبل `p_operation_id uuid` ويستخدم `receiving.operation_id` كهوية تشغيلية.
5. Finance reporting يجب أن يعتمد على RPCs السلطوية الموجودة بدل إعادة الحساب المحاسبي في Main9.

---

## 7. Assembly Path — Direct Verification

تم فتح `.github/workflows/forensic_main_assembly.yml` مباشرة.

المصدر الصحيح:

`Current/PWA/main2/**`

والناتج:

`Current/PWA/New-main`

`Original/PWA/main/*` تاريخ فقط.

لا توجد قرينة جديدة تبرر تغيير مسار Assembly.

---

## 8. Main9 Defect Matrix — Final Revalidated

### M9-01
`_companyId()` + `_nextDate(dateText)`

الحالة:

`CLOSED — DO NOT REPEAT`

### M9-02 — `_loadDashboardData`

العيب الحالي:

- الاعتماد الجزئي على `RW_STATE` كمصدر بيانات التقرير.
- عدم استخدام Item Master / Customer Production query مباشرة.
- العرض الحالي يحتوي معنى Forecast غير مثبت بالنظام الحالي.

التعديل المطلوب:

- Company-scoped queries.
- Branch-scoped stock.
- `available_qty` أو `qty - allocated_qty`.
- Production Item Master مباشر.
- Production Customers مباشر.
- عدم تسمية heuristic مبني على بيانات معدومة Demand Forecast/AI.

الحالة:

`OPEN`

### M9-03 — `_loadDropdowns`

التعديل المطلوب:

- reset لكل select قبل append.
- Company scope لكل كيان tenant-owned.
- Customer/Supplier/Treasury/Account/Driver = UUID identity.
- Item = `item_code` لأن Production يثبت uniqueness عالميًا.

الحالة:

`OPEN`

### M9-04 — `_showCustomerLedgerDetail`

التعديل المطلوب:

- استقبال `customerId`.
- تحقق Company + Customer UUID.
- ثم قراءة ledger.

الحالة:

`OPEN`

### M9-05 — `_showItemMovementDetail`

التعديل المطلوب:

- resolve `item_code -> items.id`.
- Company filter على `inventory_log`.
- Item identity filter.

الحالة:

`OPEN`

### M9-06 — `_showRunsheetDetail`

التعديل المطلوب:

- `(company_id, runsheet_code) -> rs.id`.
- `run_sheet_details.runsheet_id = rs.id`.
- `orders.company_id + orders.runsheet_id = rs.id`.

الحالة:

`OPEN`

### M9-07 — `_showSettlementDetail`

التعديل المطلوب:

- Company-scoped Settlement lookup.
- `runsheet_id` يعامل كـUUID relation.
- Resolve runsheet داخل الشركة للعرض فقط.

الحالة:

`OPEN`

### M9-08 — `_generateReport`

التعديل المطلوب يشمل الحزمة كلها:

- كل Sales queries Company + Date.
- `order_details` لا تقرأ global؛ تربط بـorders company-scoped.
- Stock عبر Branch IDs للشركة.
- Inventory Movement عبر Company + Item identity.
- Low Stock يعتمد على Available Stock وفق العقد.
- Purchases/Receiving Company-scoped.
- Finance عبر RPCs السلطوية الحالية.
- CRM Company-scoped.
- Returns من `inventory_log` بأنواع Production المثبتة: `SalesReturn` و`DirectReturn` فقط.
- HR Attendance/Salary = `CAPABILITY GATED` لعدم ثبوت مصدر Production سلطوي.
- Tax = `CAPABILITY GATED` وعدم اختلاق VAT.
- لا `LIMIT 1` في tenant-owned reporting lookups.
- لا نجاح وهمي لتقرير غير مدعوم.

الحالة:

`OPEN`

### M9-09 — `_loadDetailedReports`

التعديل المطلوب:

- Production Items مباشر مع `max_qty`.
- Production Customers Company-scoped.
- Orders Company + Date.
- `order_details` من Order IDs التي تم جلبها من الشركة.
- Stock من Branch IDs للشركة.
- توصيات الشراء تعتمد على `max_qty`.
- توصيات reorder threshold تبقى `policy-based` لا AI forecast.

الحالة:

`OPEN`

---

## 9. Critical Clarification — لماذا لا يتم تعديل Production الآن

التحقيق الحالي لا يثبت Defect جديد في Inventory Core.

كما أن Main9 هو طبقة Reporting/Presentation، ولا يملك مبررًا لإعادة بناء محرك المخزون أو تغيير RPCs التي ثبتت سلطويتها في Production.

أي إعادة فتح لـInventory الآن ستكون مخالفة مباشرة لقاعدة:

`DO NOT REOPEN CLOSED WORK WITHOUT NEW EVIDENCE`

---

## 10. التجارب والتحقق

### Experiment A — Current Git Recheck

تمت إعادة فتح Main9 الحالي مباشرة.

النتيجة:

`OLD IMPLEMENTATIONS STILL PRESENT`

### Experiment B — Production Snapshot

تمت إعادة مزامنة العدادات الحالية مباشرة.

النتيجة:

`Production counts remain consistent with the last checkpoint.`

### Experiment C — Inventory Invariants

تم فحص:

- Negative Stock.
- Invalid Reservation.
- Available Quantity mismatch.

النتيجة:

`0 / 0 / 0`

### Experiment D — PostgreSQL Contract Revalidation

تمت إعادة فحص movement types وFinance RPCs وoperation-id contract.

النتيجة:

`Contracts confirmed.`

### Experiment E — Assembly Workflow

تم فتح workflow الحالي مباشرة.

النتيجة:

`Canonical path is still correct.`

---

## 11. ما تم إثباته

- Report104 ليس Current Truth بحد ذاته وتمت مطابقته مع Git/Production.
- Current Main9 SHA ما زال `a72b970…`.
- Main9 لم يخضع للجراحة المصدرية بعد.
- M9-01 مغلق فعلًا ولا يجب تكراره.
- M9-02..M9-09 ما زالت مفتوحة.
- Production الحالية شركة واحدة.
- Inventory invariants سليمة.
- لا يوجد دليل جديد على Physical Stock Writer خارج `post_stock_movement`.
- `items.item_code` عالمي Unique.
- Assembly source path صحيح.
- Finance capabilities المطلوبة موجودة بالفعل.

---

## 12. ما لم يتم إثباته بعد

- تنفيذ Owner Source Surgery فعليًا في Main9.
- Main9 post-surgery syntax.
- Main2 full integration بعد الجراحة.
- Generated `New-main` validity.
- Browser/PWA smoke بعد Assembly.
- Production UI report smoke.
- Gold/Diamond parent closure.

---

## 13. Authorized Next Step — Direct Owner Action

يجب تنفيذ الجراحة على:

`Current/PWA/main2/main9.md`

فقط.

استخدم حدود:

`START EXACT HEADING + FULL FUNCTION + NEXT EXACT MARKER`

ولا تستخدم أرقام الأسطر وحدها.

بعد الحفظ والرفع إلى Git:

1. Read Main9 من أول حرف إلى EOF.
2. Verify كل M9-02..M9-09 مرة واحدة فقط.
3. Verify M9-01 لم يتكرر.
4. Verify old implementations اختفت.
5. Run syntax gate.
6. Match Main2 fragments.
7. Run governed assembly.
8. Run `node --check` على الناتج.
9. Run Browser/PWA smoke.
10. ثم Production UI smoke للتقارير.

---

## 14. FINAL SELF-AUDIT

### What I Proved

- Current Git HEAD = `c994800ed90cc146207e45ab9ef16da3a5548b2f`.
- Current Main9 SHA = `a72b970709ce69192bd47824685e99962aaf9fd8`.
- Production snapshot refreshed at `2026-09-09 08:42:57.712837 UTC`.
- Inventory invariants refreshed at `2026-09-09 08:44:38.440623 UTC`.
- Main9 still contains the old implementations.
- Inventory Core remains healthy according to current invariant checks.
- Assembly path is correct.

### What I Did Not Prove

- Main9 surgery execution.
- Post-surgery syntax.
- Parent Assembly.
- Browser/PWA runtime.
- Gold/Diamond closure.

### What Was Corrected in This Recheck

- Report104 was not treated as infallible.
- Current production timestamp was refreshed.
- Current Git HEAD was refreshed.
- Inventory invariants were refreshed.
- `Return` as a movement type was rejected because Production does not support it.
- Recommendation semantics were kept policy-based rather than AI/demand forecasting.
- No unnecessary Inventory rewrite was introduced.

### FINAL STATUS

`M9-01 = SOURCE CLOSED`

`M9-02..M9-09 = OPEN / OWNER SOURCE SURGERY REQUIRED`

`MAIN9 SOURCE = OPEN`

`MAIN2 ASSEMBLY = BLOCKED`

`PRODUCTION INVENTORY CORE = VERIFIED / NO NEW REPAIR JUSTIFIED`

`PARENT GOLD/DIAMOND = NOT CLOSED`
