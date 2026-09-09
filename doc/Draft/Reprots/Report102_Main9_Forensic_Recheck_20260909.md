# RAWAEA ERP — Report102
# إعادة الفحص الجنائي الكامل لـ Main9 وربطها بواقع Production

## 0. المبدأ الحاكم — يجب تذكره طوال العمل

**هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا يجوز التعامل معه كإضافات شكلية.**

هذا متسق حرفيًا مع Governance Principle:

UNDERSTAND → RECONSTRUCT HISTORICAL CONTRACT → TRACE CURRENT BEHAVIOR → TRACE DATA/AUTH CONTROL FLOW → IDENTIFY ACTUAL GAP → SURGICAL FIX → TEST → PRODUCTION VERIFY.

---

## 1. نطاق هذه الجلسة

تمت إعادة فتح المصادر الحاكمة التالية قبل أي قرار:

1. تقرير المبادئ الحاكمة.
2. MASTER - RAWAEA ERP.md.
3. MASTER - RAWAEA ERP - UNIFIED CONTINUITY & MAIN1 EXECUTION.md.
4. MANDATORY CTO DIRECTIVE / GLOBAL INVENTORY ZERO-DEBT.
5. Report101_main9 كاملًا من البداية إلى النهاية، على دفعات متصلة حتى نهاية الملف.
6. CURRENT_STATE.md.
7. `.github/workflows/forensic_main_assembly.yml`.
8. `Current/PWA/main2/main9.md` من GitHub الفعلي الحالي.
9. Original/Current Edge Function sources المرتبطة بالمسارات ذات الصلة.
10. Production Supabase schema / functions / triggers / constraints / current data.

---

## 2. Source of Truth الذي تم إثباته

المصدر التحريري المعتمد للـPWA الأم هو:

`Current/PWA/main2/main1.md ... main11.md`

وليس:

`Current/PWA/main/*`

وليس:

`Current/PWA/New-main/*`

والـassembly workflow الحالي ما زال يشير إلى:

`Current/PWA/main2/**`

كنقطة المصدر، ويستخدم `Current/PWA/New-main` كناتج مولد.

**لا توجد حاجة لتغيير مسار assembly في هذه الجلسة؛ المسار المثبت حاليًا صحيح.**

---

## 3. أهم اكتشاف في الحالة الحالية: Git drift في Main9

`CURRENT_STATE.md` كان يسجل سابقًا Main9 blob مختلفًا، بينما GitHub الحالي أعاد:

`Current/PWA/main2/main9.md`

Current blob SHA observed:

`a72b970709ce69192bd47824685e99962aaf9fd8`

لذلك فإن أرقام الأسطر القديمة في Report100/Report101 لا يجوز استخدامها كمرجع وحيد.

**مرجع الجراحة الصحيح هو function heading + آخر سطر للمقطع + العلامة الفاصلة التالية، ثم رقم السطر الحالي التقريبي بعد إعادة فتح الملف.**

---

## 4. حالة Main9 بعد القراءة الحالية

Main9 الحالي يحتوي على:

- `RW_Reports` القديم.
- `RW_Reports_Comprehensive`.
- نسخة قديمة غير مكتملة من `_loadDetailedReports` داخل `RW_Reports`.
- `RW_Reports_Comprehensive._generateReport` بعدد كبير من القراءات غير المقيدة بالشركة.
- placeholders وظيفية يجب عدم إبقائها كأن التقارير مكتملة.
- بعض الدوال تم إصلاحها جزئيًا في نسخ تاريخية، ولكن النسخة الفعلية الحالية ما زالت تحتاج الجراحة الموثقة أدناه.

M9-01:

`function _companyId()`

و

`function _nextDate(dateText)`

موجودتان بالفعل.

**M9-01 = لا تعديل.**

---

# 5. حزمة جراحة Main9 — Owner Source Operations

> هذه التعديلات على `Current/PWA/main2/main9.md` ينفذها المالك يدويًا حسب بروتوكول المشروع. لا ينفذها المساعد مباشرة.
>
> المطلوب تنفيذ الحزمة كاملة بنفس الجلسة، ثم إعادة قراءة Main9 من أول حرف إلى آخر حرف، ثم syntax validation، ثم التكامل مع Main2. لا تستخدم أسلوب "افعل الباقي".

---

## M9-02 — `_loadDashboardData`

### ابحث حرفيًا عن بداية المقطع:

`async function _loadDashboardData(fromDate, toDate) {`

### الوضع الحالي التقريبي:
حوالي السطر 67 في النسخة الحالية.

### احذف:
الدالة كاملة من السطر الذي يبدأ بالنص أعلاه وحتى **آخر `}` يغلق الدالة مباشرة قبل**:

`    // ========== التقارير التفصيلية (Checkbox) ==========`

### استبدلها بالكامل:
بالبديل الكامل المسجل في Report101 تحت:

`M9-02 — _loadDashboardData`

### غرض البديل الإلزامي:
- Company context عبر `_companyId()`.
- Branch IDs من `branches.company_id`.
- Stock عبر فروع الشركة فقط.
- جمع `qty` / `allocated_qty` / `available_qty`.
- قراءة Items وفق عقد Item Master الحقيقي؛ لا تفترض `company_id` على أن item identity منفصلة عن العقد العالمي.
- Orders عبر `orders.company_id` والفترة.
- Customers عبر `customers.company_id`.
- عدم وجود global `LIMIT 1` في operational reads.

### لا تلمس:
`function _companyId()`
`function _nextDate()`

---

## M9-03 — `_loadDropdowns`

### ابحث حرفيًا:

`async function _loadDropdowns(params) {`

### الوضع الحالي التقريبي:
حوالي السطر 589، مع اعتماد الرقم النهائي على النسخة الحالية التي سيستخدمها المالك عند التحرير.

### احذف:
الدالة كاملة حتى **آخر `}` يغلق الدالة مباشرة قبل**:

`    // ==================== دوال التفاصيل (Drill-Down) ====================`

### استبدلها:
بالبديل الكامل المسجل في Report101 تحت `M9-03 — _loadDropdowns`.

### يلزم أن يتضمن البديل:
- `companyId = _companyId()`.
- Reset للـselect قبل append لمنع duplicate options.
- Customer / Supplier / Treasury / Account / Driver / Area كلها company-scoped.
- Item dropdown يستخدم `item_code` كـUI identity مع احترام أن `items.item_code` عليه `UNIQUE` عالمي في Production.
- لا global lookup لمسارات tenant-owned entities.

---

## M9-04 — `_showCustomerLedgerDetail`

### ابحث حرفيًا:

`async function _showCustomerLedgerDetail(customerCode, customerName) {`

### الخطأ المثبت:
الدالة الحالية تتعامل مع `customerCode` كما لو كان UUID للـledger ثم تستعلم مباشرة من `customer_ledger`، وتفتقد Company verification.

### احذف:
حتى **آخر `}` يغلق الدالة مباشرة قبل**:

`    async function _showItemMovementDetail(itemCode, itemName) {`

### استبدلها:
بالبديل الكامل في Report101 تحت `M9-04`.

### العقد النهائي:
- المتغير المستلم يجب أن يكون Customer UUID/identity الصحيح.
- تحقق أن العميل ينتمي إلى `companyId`.
- ثم اقرأ `customer_ledger` لهذا العميل.
- لا تسمح بفتح Ledger عبر cross-company identity.

---

## M9-05 — `_showItemMovementDetail`

### ابحث حرفيًا:

`async function _showItemMovementDetail(itemCode, itemName) {`

### احذف:
حتى **آخر `}` يغلق الدالة مباشرة قبل**:

`    async function _showRunsheetDetail(runsheetCode) {`

### استبدلها:
بالبديل الكامل في Report101 تحت `M9-05`.

### العقد النهائي:
- `_companyId()`.
- resolve Item identity من `items` بواسطة `item_code` لأن `item_code` globally unique في Production.
- تحقق هوية الـItem.
- اقرأ `inventory_log` مع Company filter ومع item identity الصحيحة.
- لا تعرض حركة Item تخص tenant آخر.

---

## M9-06 — `_showRunsheetDetail`

### ابحث حرفيًا:

`async function _showRunsheetDetail(runsheetCode) {`

### الخطأ المثبت:
النسخة الحالية تستخدم lookup غير company-scoped، كما أن ربط Orders تم في نسخة تاريخية بواسطة `runsheet_id = runsheetCode` بدل UUID الحقيقي.

### احذف:
حتى **آخر `}` يغلق الدالة مباشرة قبل**:

`    async function _showSettlementDetail(settlementCode) {`

### استبدلها:
بالبديل الكامل في Report101 تحت `M9-06`.

### العقد النهائي:
- Resolve `runsheets` عبر `(company_id, runsheet_code)`.
- استخدم `rs.id` كـUUID للعلاقات.
- اقرأ `run_sheet_details` عبر `runsheet_id = rs.id`.
- اقرأ `orders` عبر `runsheet_id = rs.id` + `orders.company_id`.

---

## M9-07 — `_showSettlementDetail`

### ابحث حرفيًا:

`async function _showSettlementDetail(settlementCode) {`

### احذف:
حتى **آخر `}` يغلق الدالة مباشرة قبل**:

`    // ==================== توليد التقرير (مع Drill-Down) ====================`

### استبدلها:
بالبديل الكامل في Report101 تحت `M9-07`.

### العقد النهائي:
- Settlement lookup عبر `company_id`.
- `runsheet_id` يعامل كـUUID relation وليس كـrunsheet code.
- resolve runsheet للعرض الآمن فقط.

---

# M9-08 — `_generateReport`

## هذه ليست مجرد Company Filter Patch

هذه أهم جراحة وظيفية في Main9.

### ابحث حرفيًا:

`async function _generateReport(sectionKey, reportId) {`

### احذف:
الدالة كاملة حتى **آخر `}` يغلقها مباشرة قبل**:

`    function _printReport() {`

### استبدلها بالكامل:
بالبديل الكامل في Report101 تحت `M9-08 — _generateReport`.

### يجب أن يغلق البديل كل الفجوات التالية، لا بعضها فقط:

### SALES
- Sales Summary → Company + Date.
- Sales By Customer → Company + UUID Customer identity.
- Sales By Item → لا قراءة global لـ`order_details`؛ استخدم `orders!inner` أو relation يثبت company.
- Sales By Area → Company + Date.
- Order Status → Company + Date.
- Customer Ledger → تحقق Customer داخل company.
- Runsheet performance → Company + Date.

### INVENTORY
- Stock Report → branch IDs من Company ثم stock rows عبرها.
- Inventory Movement → Company + Item identity.
- Low Stock → available stock الحقيقي وليس physical فقط إذا كان العقد المعتمد يتطلب المتاح.
- Dormant → Orders داخل Company + Stock داخل Branches Company.

### PURCHASES
- Supplier Report → Company + Date.
- PO Status → Company + Date.
- Receiving → `receiving.company_id` ثم `receiving_details.operation_id`.

### FINANCE
استخدم Finance RPCs الحقيقية في Production:

- `get_trial_balance`
- `get_profit_loss`
- `get_balance_sheet_data`
- `get_cash_flow`

ولا تعرض:

`العرض الكامل قيد التطوير`

عندما تكون القدرة نفسها متاحة عبر RPC حقيقي.

أما Tax فلا تخترع VAT data؛ استخدم capability-gated behavior إذا لم يثبت مصدر ضريبي سلطوي.

### CRM
- Customer List → Company.
- Customer Analysis → Orders Company + non-cancelled.
- Followups → `customer_followups.company_id`.
- By Area → Customers Company.

### LOGISTICS
- Loading/Unloading → Stock vouchers Company.
- Returns → المصدر السلطوي `inventory_log`، وليس افتراض Return Voucher إذا لم يثبت ذلك في Production.
- Settlement → Company.
- Driver Performance → Runsheets Company.

### HR
- Employee List → Users Company.
- Attendance / Salary → capability gated طالما أن مصدر Production السلطوي غير مثبت.

### ممنوع
- global `LIMIT 1` في operational lookup.
- قراءة `RW_STATE.data` كـSource of Truth عندما تكون Production query هي العقد السلطوي للتقرير.
- إظهار نجاح وهمي لتقرير غير مدعوم.

---

# M9-09 — `_loadDetailedReports`

### ابحث حرفيًا عن:

`async function _loadDetailedReports(fromDate, toDate, types) {`

### ملاحظة مهمة جدًا
في النسخة الحالية توجد نسخة قديمة من هذه الدالة داخل `RW_Reports` بعد `renderDetailedReports()`، وهي مختلفة جذريًا عن الـreplacement الذي ظهر في Report101.

### احذف:
الدالة كاملة حتى **آخر `}` يغلقها مباشرة قبل**:

`    return {`

ثم لا تحذف `return` نفسه.

### استبدلها:
بالبديل الكامل المسجل في Report101 تحت:

`M9-09 — _loadDetailedReports`

### شروط البديل الإلزامية:
- Company context عبر `_companyId()`.
- Customers Company-scoped.
- Branch IDs Company-scoped.
- Stock عبر Branch IDs التابعة للشركة.
- Orders Company-scoped + date.
- `order_details` لا يقرأ global؛ يربط عبر `orders` IDs الناتجة من Company-scoped orders، أو relation equivalent.
- inventory recommendations تعتمد على stock الحقيقي.
- لا global Item/Customer/Order reads في تقرير tenant-aware.
- لا placeholders مقنعة في النتائج.

---

## 6. تحذير من خطأ تكرار الإصلاح

لا تستخدم أرقام الأسطر القديمة من Report101 حرفيًا.

لا تستخدم:

`Current/PWA/main/main9.md`

ولا:

`Current/PWA/New-main`

ولا النسخة الأصلية كـSource of Truth.

استخدم:

`Current/PWA/main2/main9.md`

Current SHA:

`a72b970709ce69192bd47824685e99962aaf9fd8`

والتحديد يكون بـ:

**START EXACT HEADING + DELETE FULL FUNCTION + LAST CLOSING LINE BEFORE NEXT EXACT MARKER.**

---

# 7. Production — ما تم إثباته مباشرة

## Current production snapshot
آخر direct snapshotات في هذه الجلسة كانت خلال:

`2026-09-09 05:46 – 05:48 UTC`

والواقع الحالي الأساسي:

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

## Stock integrity

Production current:

- negative stock = 0
- over allocated = 0
- available_qty mismatch = 0
- bad source company in inventory_log = 0
- bad target company in inventory_log = 0
- bad item identity in inventory_log = 0
- bad stock voucher branch/company context = 0

## Writer discovery

فحص PostgreSQL المباشر أثبت:

### Authoritative Physical Writer
`post_stock_movement`

هو الكاتب المركزي لـ:

`stock_branches`
+
`inventory_log`

### Reservation-only writers
`reserve_stock`
`release_stock_reservation`

وهما يعدلان `allocated_qty` فقط، ولا ينفذان Physical Movement مستقلًا.

### Bootstrap-only stock row creation
`create_vehicle_atomic`
`setup_van_stock`

الكتابة هنا تهيئة صفوف مخزون جديدة بكميات صفر، وليست حركة مخزنية.

### Inventory Log
فحص `pg_proc.prosrc` أثبت أن الكتابة المباشرة إلى `inventory_log` خارج القراءة محصورة عمليًا في:

`post_stock_movement`

وبالتالي:

**Physical Writers outside post_stock_movement = 0**

وفق تعريف Physical Movement، مع إبقاء Reservation/Bootstrap كـspecialized non-movement writers.

---

# 8. Production repairs التي تم تطبيقها/تثبيتها في هذه الدورة

- تم تثبيت/إعادة فرض Company-aware checks في Manual Voucher capability wrappers.
- تم التأكد أن Manual Voucher lifecycle يمر إلى Core مع `post_stock_movement`.
- تم التأكد أن `create_manual_stock_voucher_atomic` الحالي له overloads واضحة، بما فيها النسخة الحديثة التي تدعم `p_rep_id` و`p_operation_id`.
- تم التحقق أن `receive_purchase_atomic` الحالي يستقبل `p_operation_id uuid`.
- تم التحقق أن `complete_return_atomic` و`complete_order_delivery_atomic` موجودان في Production ويستخدمان operation registry و`post_stock_movement`.
- تم التحقق من audit trigger على `stock_vouchers` إلى `fn_audit_trigger()`.
- تم التحقق أن `items.item_code` عليه UNIQUE عالمي.
- تم التحقق أن `stock_branches` لا يحتوي `company_id` مباشرًا وأن Company scope يمر عبر `branches.company_id`.

Migration applied in this cycle:

`inventory_core_zero_debt_governed_fixes_20260909`

---

# 9. Production runtime drift الذي تم كشفه

Git Current كان يحتوي نسخًا أحدث من بعض Edge Functions مقارنة بالنسخ المنشورة التي ظهرت من Production metadata.

تم إثبات ذلك خصوصًا في:

- `receive-purchase`
- `complete-return`
- `complete-order-delivery`

كما أن Current Git version من `create-stock-voucher` يستخدم الـRPC canonical.

**في هذه الجلسة تم توثيق الـdrift ولكن لم أعتبر Edge deployment PASS ما لم أستلم إثبات deployment runtime جديد.**

لا يتم تحويل Git Current إلى Production PASS تلقائيًا.

---

# 10. أخطاء/تجارب الجلسة

### تجربة 1
تم اختبار مسار Manual Voucher داخل Transaction مؤقتة.

النتيجة: نجاح إنشاء capability عبر الـRPC بدون استمرار بيانات الاختبار بعد rollback.

### تجربة 2
ظهر أثناء اختبار Purchase Receive أن retry قد يمر إلى quantity validation قبل duplicate detection في نسخة مبكرة.

تم تحليل ذلك بدل تجاوز الحارس، وثبت أن Operation Identity يجب أن تكون ثابتة وصريحة.

### النتيجة النهائية
Production الحالية تعكس النسخة المنقحة من `receive_purchase_atomic` التي تستخدم `p_operation_id` و`receiving.operation_id` كهوية تشغيل.

### تجربة 3
تم تنفيذ checks مباشرة على:

- stock invariants
- inventory_log identity
- branch/company integrity
- voucher branch/company integrity
- failed operations
- processing operations

والنتائج الحالية لا تظهر failed/processing core operations ولا stock invariant failure.

---

# 11. لماذا لم أعتبر Main9 مغلقًا

لأن:

1. `Current/PWA/main2/main9.md` لم يتم تعديله من قبل المساعد، وفق Owner-edit protocol.
2. Main9 الحالي ما زال يحتوي على legacy report code ونسخة `_loadDetailedReports` القديمة.
3. M9-08 وM9-09 يتجاوزان مجرد tenant filter إلى functional completeness.
4. لم يتم تنفيذ Full Main2 Assembly بعد.
5. لم يتم تنفيذ Node syntax gate للـassembled parent.
6. لم يتم تنفيذ Browser/PWA smoke بعد الدمج.
7. Edge runtime drift اكتُشف ويحتاج deployment evidence قبل تحويله إلى PASS.

لذلك:

`MAIN9 SOURCE = OPEN`
`MAIN2 ASSEMBLY = BLOCKED`
`PARENT GOLD/DIAMOND = NOT CLOSED`

---

# 12. FINAL SELF-AUDIT

## What I Proved

- Governance sources reopened.
- Report101 read end-to-end in slices to EOF.
- Current Main9 physically reopened from GitHub.
- Current Main9 SHA differs from older CURRENT_STATE checkpoint and this drift was not ignored.
- Main9 contains real functional gaps, not only formatting gaps.
- Production current company count is 1.
- Current stock invariants pass.
- Current inventory_log identity and branch/company integrity pass.
- PostgreSQL writer discovery found no independent Physical Movement Writer outside `post_stock_movement`.
- Reservation and bootstrap writers are not Physical Movement engines.
- Complete Return / Delivery / Purchase RPCs exist in current Production.
- Audit trigger path exists.
- Main2 is still the only editable parent source.

## What I Did Not Prove

- Final Main9 source after Owner surgery.
- Full Main2 assembly after surgery.
- Browser runtime after assembly.
- Full production UI E2E for every report.
- Gold/Diamond closure.
- Production Edge deployment pass for the Git-current versions identified as newer than deployed metadata.

## What I Fixed

- Production DB governance guards related to Manual Voucher wrappers.
- Verified canonical inventory writer contract.
- Verified stock invariants and current data identity.

## What I Initially Missed / Corrected During This Session

- Current Git Main9 SHA drift versus CURRENT_STATE.
- A test ordering issue around receive duplicate detection.
- Schema fact that `stock_branches` has no `company_id` column.
- Need to classify bootstrap stock row creation separately from Physical Movement.

## What Could Still Be Wrong

- Owner could apply a replacement block incompletely.
- A legacy duplicate function may remain in Main9 after manual surgery.
- Assembly could surface cross-fragment symbol collisions.
- Edge runtime may remain older than Current Git until deployment is independently verified.

## Final Confidence

**High for the facts directly verified in Production and Git.**

**Not high enough to claim Main9 / Parent / Gold-Diamond closure.**

## Final Closure Status

`GLOBAL INVENTORY CORE INTEGRITY — DB WRITER CONTRACT = CLOSED`

`MAIN9 = OPEN / OWNER SURGERY REQUIRED`

`MAIN2 ASSEMBLY = BLOCKED`

`PARENT GOLD/DIAMOND = NOT CLOSED`
