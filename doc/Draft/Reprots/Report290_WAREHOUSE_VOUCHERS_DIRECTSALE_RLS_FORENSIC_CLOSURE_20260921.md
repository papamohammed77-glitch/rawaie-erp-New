# تقرير 290 — إغلاق عطل DirectSale في تطبيق الأذونات المخزنية
## تحقيق جنائي + إصلاح Production + تثبيت الحالة — 2026-09-21

---

## 1. نطاق المهمة

النطاق المغلق في هذه الجلسة:

- إدارة المخازن والمخزون → الأذونات المخزنية.
- تطبيق:
  `companies/company-1/warehouse/vouchers.html`
- تكامل DirectSale مع:
  - الفرع المصدر.
  - مندوب البيع المباشر.
  - المركبة.
  - المخزن المتنقل للمركبة.
  - محرك المخزون المركزي.
- مطابقة التطبيق مع:
  - النظام الأم `companies/company-1/main.html`.
  - تطبيق `companies/company-1/sales/van-sales.html`.
  - Production Supabase.
  - السجل التاريخي للأذونات المخزنية.

خارج النطاق:

- تعديل `main.html`.
- تعديل `vouchers.html` في هذه الجلسة.
- تعديل `van-sales.html`.
- إنشاء Edge Function جديدة.
- إعادة تنفيذ V-03/V-04 اللذين ثبت وجودهما بالفعل في المصدر الحالي.

---

## 2. قاعدة الحقيقة المستخدمة

اعتمد التحقيق فقط على:

CURRENT GIT
+
CURRENT SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT EVIDENCE

التقارير السابقة استُخدمت كسياق تاريخي فقط.

---

## 3. Git الحالي

### النظام الأم / المصدر الحاكم

المستودع:

`papamohammed77-glitch/rawaie-erp-New`

المصدر البرمجي المرجعي:

- Source baseline HEAD:
  `8117e919834ccd5fef0003f850508f286e41b3a7`
- parent:
  `9ca6bf1bba8c807aeb5c16c612a1d1bed76d356d`

ثم ظهرت commits توثيقية فقط، من بينها:

- `51ebbd1d8a7e9be1e8310418f7dbbec7c12d3e52`
- message:
  `state: clarify source baseline and documentation-only HEAD drift`

### Mother Frontend

المستودع:

`papamohammed77-glitch/erp-frontend`

الحالة الحالية:

- HEAD:
  `f59bce9bac6b4d76fda2b16e6889f5d8b1e2466d`
- parent:
  `bab20ca64b359045bbaae7a47b7eee6e4b538a1b`

target:

`companies/company-1/warehouse/vouchers.html`

Current blob:

`570a4a952b7645e5ef7674e80d5238b65f8cd9eb`

Van Sales current blob:

`8d61382a8e0025a0d079e71dd94f33d106d9088e`

---

## 4. الحقيقة الحالية لتطبيق vouchers

تم فتح المصدر الحالي والتأكد من وجود عناصر الإصلاح السابقة.

### V-03 — موجود بالفعل

العنصر:

`pickArr:function(key){`

ويحتوي حاليًا على:

- تحميل مندوبين البيع المباشر من `refs.reps`.
- فلترة المندوب وفق الفرع المصدر.
- إتاحة المركبات في DirectSale بناءً على:
  - المركبة Active.
  - `mobile_stock_enabled`.
  - وجود مندوب مرتبط.
  - صحة مخزن المركبة.
  - صلاحية الفرع.
  - صلاحية المندوب.
  - تطبيق مرشح المندوب إذا اختير.

### V-04 — موجود بالفعل

العنصر:

`pickSelect:function(key,id){`

وعند اختيار مركبة DirectSale ينفذ:

`vehicle.driver_id -> wsRep`

ويضع مندوب البيع المباشر في الحقل المناسب ويجعله readonly بعد الاختيار.

### النتيجة

لا يوجد patch جديد مشروع داخل `vouchers.html`.

**ممنوع إعادة تطبيق V-03/V-04.**

إعادة تعديلهما ستكرر إصلاحًا قائمًا وتخالف قاعدة عدم إصلاح ما تم إصلاحه بالفعل.

---

## 5. التحقيق في العطل المبلغ عنه

العطل الظاهري:

- DirectSale لا يستجيب.
- قائمة مندوب البيع المباشر تبدو فارغة.
- قائمة المركبات تبدو غير مستجيبة.
- لا يمكن الوصول عمليًا إلى حفظ الإذن.

### التحقيق في المصدر

`loadRefs:function(){`

يقرأ:

- branches
- vehicles
- suppliers
- users حيث:
  `role = 'مندوب بيع مباشر'`
- purchase_orders

الـSQL المنطقي في الواجهة صحيح.

المشكلة لم تكن في Search Engine.

المشكلة لم تكن في `pickSearch`.

المشكلة لم تكن في `pickSelect`.

---

## 6. Root Cause — Production RLS

### سياسة المستخدمين الحالية قبل الإصلاح

السياسة:

`users_select_company`

كانت تسمح للمستخدم برؤية:

1. صفه الشخصي فقط عبر:
   `auth_id = auth.uid()`

أو:

2. مستخدمي شركته إذا كانت لديه صلاحية:
   `users`

مستخدم الأذونات الحالي:

`vouchers@rawaea.com`

خصائصه المؤكدة في Production:

- role = `مخزني`
- active_warehouse_role = `أذونات`
- permissions = [`warehouse`]

ولا يملك permission:

`users`

### الاختبار الجنائي

تم تشغيل نفس الاستعلام الذي تحتاجه `loadRefs` تحت:

`authenticated`

وبهوية:

`vouchers@rawaea.com`

قبل إصلاح Production:

`direct_reps = 0`

مع أن Production تحتوي فعليًا على:

`vansales@rawaea.com`

بدور:

`مندوب بيع مباشر`

---

## 7. لماذا ظهر العطل في المركبات أيضًا؟

هذا هو التسلسل الفعلي:

`loadRefs()`
↓
`users`
↓
RLS
↓
0 Direct Sales Reps
↓
`refs.reps = []`
↓
`pickArr('wsRep') = []`

ثم في DirectSale:

`pickArr('wsTo')`

يتحقق من وجود المندوب المرتبط بالمركبة:

`!!rep`

ولأن:

`refs.reps = []`

فإن:

`vehicle candidates = 0`

إذًا:

### محرك البحث كان موجودًا.

### مصادر البيانات كانت موجودة.

### لكن Candidate Provider كان يسلّم قائمة فارغة بسبب RLS.

وهذا يفسر كامل السلوك الظاهري.

---

## 8. Root Cause Classification

التصنيف:

**PRODUCTION AUTHORIZATION / DATA-VISIBILITY CONTRACT MISMATCH**

وليس:

- JavaScript syntax failure.
- Search algorithm failure.
- Modal renderer failure.
- Service Worker cache failure.
- Edge Function missing.
- main.html routing defect.

---

## 9. الإصلاح الجراحي في Production

تم تطبيق migration مباشرة على Production:

`allow_warehouse_direct_rep_lookup_for_vouchers`

نسخة Git canonical موجودة في:

`supabase/migrations/20260921165026_allow_warehouse_direct_rep_lookup_for_vouchers.sql`

### الإصلاح

```sql
BEGIN;

DROP POLICY IF EXISTS users_select_direct_reps_warehouse
ON public.users;

CREATE POLICY users_select_direct_reps_warehouse
ON public.users
FOR SELECT
TO authenticated
USING (
  company_id = app_private.current_user_company_id()
  AND status = 'Active'
  AND role = 'مندوب بيع مباشر'
  AND app_private.current_user_has_permission('warehouse')
);

COMMIT;
```

---

## 10. لماذا هذا الإصلاح هو الصحيح؟

لم يتم:

- توسيع صلاحية `users` لمستخدم الأذونات.
- فتح جميع مستخدمي الشركة.
- تعطيل RLS.
- استخدام service role من Browser.
- تمرير بيانات مندوبين من Edge جديد.
- نسخ بيانات المندوبين إلى جدول آخر.

بل تم فتح أقل نطاق تشغيلي مطلوب فقط:

**Warehouse user → Active Direct Sales Reps → same company**

وبالتالي:

- لا يكتسب المستخدم صلاحية إدارة المستخدمين.
- لا يرى بقية المستخدمين بلا داع.
- يبقى Company Isolation فعالًا.
- تستمر إدارة المصدر في Production Core.

---

## 11. Production Verification بعد الإصلاح

نفس الاختبار تحت `authenticated` أعاد:

- branches = 3
- vehicles = 1
- direct_reps = 1
- purchase_orders = 0
- stock_rows = 37
- items = 16

والـDirect Sales Rep الحالي المثبت:

`vansales@rawaea.com`

والـVehicle الحالي:

- vehicle_code = `VEH-TEST-260921`
- license = `س ن ر 6021`
- driver_id =
  `111b0730-a977-4d11-bcd0-2427b178a9e5`
- mobile_branch_id =
  `5372503d-f638-4e7f-808d-bda585825b2f`
- mobile_stock_enabled = true
- status = Active

---

## 12. DirectSale backend E2E

تم تنفيذ E2E transactionally على Production باستخدام:

- Company الصحيح.
- BR-01.
- Direct Sales Rep الصحيح.
- Vehicle الصحيح.
- Item 1001.
- `vouchers@rawaea.com`.

الخطوات:

`create_manual_stock_voucher_atomic`
↓
DirectSale
↓
Branch -> Vehicle
↓
`send_stock_voucher_atomic`
↓
`post_stock_movement`

النتيجة داخل Transaction:

- Main item 1001:
  `2 -> 1`
- Mobile stock item 1001:
  `0 -> 1`

ثم:

`ROLLBACK`

وعادت Production إلى baseline.

---

## 13. إثبات المركزية

Physical Stock ما زال:

`Business Capability`
↓
`RPC / Core`
↓
`post_stock_movement`
↓
`stock_branches`
+
`inventory_log`

لم يتم إنشاء Physical Stock Writer جديد.

لم يتم إنشاء Edge Function جديدة.

---

## 14. Edge Functions الحالية

المسار الحالي يستخدم Edge Functions موجودة:

- create-stock-voucher
- send-stock-voucher
- receive-stock-voucher
- complete-stock-voucher
- cancel-stock-voucher

والـCreate الحالي Production هو:

- version = 10
- verify_jwt = true

والـSend الحالي:

- version = 20
- verify_jwt = true

لا توجد حاجة إلى Function جديدة لإغلاق هذه المشكلة.

---

## 15. العلاقة مع النظام الأم

المسار المنشور:

`/vouchers`
→
`/companies/company-1/warehouse/vouchers.html`

ولا يوجد دليل حالي يثبت حاجة `main.html` إلى تعديل لهذا العطل.

**main.html = UNTOUCHED**

كما أن:

`_redirects`

يثبت route:

`/vouchers -> companies/company-1/warehouse/vouchers.html`

---

## 16. العلاقة مع Van Sales

الملف:

`companies/company-1/sales/van-sales.html`

الحالة الحالية محفوظة ولم تُفتح له Closure جديدة.

العقود الحالية المهمة:

`vehicle.driver_id`
→
Direct Sales Representative

و:

`vehicle.mobile_branch_id`
→
Mobile Stock Branch

والـVan Sales يحتفظ بتدفقه الميداني المنفصل.

لم يتم كسر:

- مخزن السيارة.
- التشغيل الميداني.
- الفواتير.
- الـmobile branch.
- الـoperation identity الموجود في المصدر الحالي.

---

## 17. لماذا الأذونات منفصلة عن Orders / Runsheets؟

الملف التاريخي:

`rawaie-erp-review/Architecture/الأذونات المخزنية اليدوية.md`

يثبت أن Manual Stock Vouchers تم إنشاءها لتغطية حركات لا تبدأ من:

- Order
- Runsheet

ومنها:

- Transfer
- DirectSale
- DirectReturn
- SupplierReturn
- Scrap
- Adjustment

### DirectSale بالتحديد

معناها التشغيلي:

**تحميل عهدة مبيعات متنقلة قبل البيع.**

أي:

`Branch`
→
`Vehicle / Mobile Stock`

وليس:

`Order`
→
`Runsheet`

وبالتالي فإن التطبيق الحالي منفصل وظيفيًا عن دورة الأوردر/الرانشيت مع تكامل كامل معها على مستوى الحقيقة المخزنية.

---

## 18. لماذا هذا البناء المعماري مناسب لـ RAWAEA؟

تم تأكيد ثلاث طبقات:

### Mother

- navigation
- supervision
- control
- reporting
- permissions

### Independent Apps

- receiver
- picker
- loader
- returns
- vouchers
- van sales
- delivery

### Database Core

- Source of Truth
- business enforcement
- stock engine
- audit
- idempotency

هذا يحقق الهدف الذي بُنيت له التطبيقات المنفصلة:

**واجهة تشغيل ميداني صغيرة ومركزة، مع حقيقة تشغيلية موحدة داخل Production Core.**

---

## 19. Benchmark — Odoo

Odoo يوثق:

- inventory adjustments
- barcode operations
- expected quantity
- manual counting
- assignment
- finalization

مصدر:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/barcode/operations/adjustments.html

RAWAEA يملك بالفعل:

- تطبيقًا مستقلاً.
- barcode/search.
- warehouse context.
- vehicle context.
- central stock engine.
- lifecycle.

لا يوجد سبب لإعادة بناء ما هو موجود.

---

## 20. Benchmark — Dynamics 365

مفهوم Inventory Journals في Dynamics يميز بين:

- movement
- adjustment
- transfer
- arrival
- counting

المبدأ المفيد لـ RAWAEA:

**الفصل بين نوع الحركة وسياق المصدر/الوجهة.**

هذا متحقق في:

`stock_vouchers.type`

و:

`from_type/from_id`

و:

`to_type/to_id`

---

## 21. Benchmark — SAP

SAP يوثق transfer posting والحالات one-step/two-step.

الاستنتاج المعماري المفيد:

**Issue وReceipt يمكن أن يكونا مرحلتين منفصلتين عندما تكون الرؤية التشغيلية للعهدة أو النقل مهمة.**

وهذا ينسجم مع DirectReturn/Transfer الحاليين ولا يبرر تغيير العقد الحالي.

---

## 22. Benchmark — Daftra

من عناصر تدفق التحويل المخزني المنشورة:

- التاريخ.
- المصدر.
- الوجهة.
- المنتج.
- الكمية.
- الكمية المتاحة قبل.
- الكمية المتاحة بعد.
- التفاصيل والتاريخ.

RAWAEA يحتوي بالفعل في شاشة السلة على:

- Available Before
- Available After

وبالتالي هذه الجزئية ليست نقصًا حاليًا في شاشة التنفيذ.

---

## 23. Benchmark — Manager.io

Manager يربط Inventory Transfer بـ:

- Date
- Reference
- Description
- Item
- Qty
- From
- To

وهذا متحقق بنيويًا في RAWAEA.

---

## 24. Capabilities تنافسية يمكن إضافتها مستقبلاً

هذه ليست bugs حالية، ولم تدخل في هذا الإصلاح حتى لا تتحول مهمة الإصلاح إلى expansion:

1. مرفقات وإثباتات المستند.
2. Approval workflow للأذونات الحساسة.
3. Timeline أقوى للمستند.
4. Exception / discrepancy analytics.
5. Lot / serial / expiry عند اعتمادها في Business Model.
6. in-transit visibility أكثر تقدمًا إذا اعتمد المشروع ذلك رسميًا.
7. keyboard-first execution أوسع للمستخدمين الكثيفين.

هذه عناصر roadmap، وليست أسبابًا لإعادة فتح DirectSale الحالي.

---

## 25. Data Integrity / Production الحالي

Production الحالي عند إعداد التقرير:

- companies = 1
- branches = 3
- vehicles = 1
- stock_vouchers = 1
- stock_voucher_details = 3
- stock_voucher_operations = 1
- inventory_log = 6
- audit_log = 2034
- orders = 0
- runsheets = 0

المستند الحالي:

- voucher = IN-1
- type = DirectSale
- status = Cancelled
- reference = DEMO-DIRECT-SALE-2026-09-21

### تصحيح مهم للحالة التاريخية

السجلات السابقة كانت تشير إلى أن IN-1 ما زال Draft.

الحقيقة الحالية من Production هي:

**IN-1 = Cancelled**

هذه هي الحالة التي يجب أن يعتمد عليها أي CTO لاحق.

---

## 26. Production integrity

تم التأكد من وجود:

- audit trigger على stock_vouchers.
- custodian trigger.
- delete integrity guard.
- central movement engine.
- operation registry.

ولا يوجد parallel Physical Stock Engine مطلوب لإغلاق هذه النقطة.

---

## 27. Surgical Source Decision

الملف المطلوب الذي طلب owner تطبيق أي تعديل فيه:

`companies/company-1/warehouse/vouchers.html`

### القرار الحالي

**لا يوجد تعديل جراحي جديد.**

لا تحذف:

`pickArr:function(key){`

ولا:

`pickSelect:function(key,id){`

ولا:

`loadRefs:function(){`

ولا:

`pickSearch:function`

لأن الإصلاحات المطلوبة فيها موجودة بالفعل في Current Source.

العطل الحالي كان خارج هذه الدوال:

**Production RLS policy**

---

## 28. لماذا لم نعدل vouchers.html؟

لأن تعديل المصدر مرة ثانية سيؤدي إلى:

- duplicate repair.
- regression risk.
- drift عن Current Source.
- مخالفة مبدأ no-repair-of-repaired-code.

القاعدة المطبقة:

**CURRENT SOURCE صحيح + CURRENT PRODUCTION غير متوافق = أصلح Production contract، لا تعيد كتابة الواجهة.**

---

## 29. Browser E2E

لم يتم تسجيل Browser E2E authenticated حقيقي بعد إصلاح RLS داخل هذه البيئة.

المتوفر في GitHub:

`.github/workflows/warehouse_vouchers_browser_e2e_20260920.yml`

وهو يتحقق من:

- تحميل الصفحة.
- core.js.
- sw.js.
- وجود عناصر login.
- غياب console/page errors في smoke boot.

لكنه لا يثبت وحده:

- login authenticated.
- DirectSale search.
- rep selection.
- vehicle selection.
- create voucher browser click path.

ولا يوجد workflow-dispatch capability متاح في أداة التنفيذ الحالية يمكن من خلاله تشغيل هذا السيناريو يدويًا دون تعديل الملفات المحمية.

لذلك:

**BROWSER E2E = OPEN / NOT CLAIMED**

---

## 30. SELF-AUDIT

### What I Proved

- Current system source baseline.
- Current system documentation drift.
- Current frontend HEAD and parent.
- Current vouchers blob.
- Current van-sales blob.
- Current Production structure.
- Current active rep.
- Current active vehicle.
- Current mobile branch.
- Exact RLS policy behavior.
- Zero visible reps قبل الإصلاح.
- One visible rep بعد الإصلاح.
- سبب اختفاء المركبات.
- Current V-03/V-04 already present.
- DirectSale Create/Send Production transaction.
- Main stock decrement.
- Mobile stock increment.
- Central writer path.
- rollback restoration.
- current Edge versions.
- no new Edge Function.
- main.html untouched.
- current IN-1 status.

### What I Did Not Prove

- authenticated browser click-through after this Production policy change.
- real-device rendering.
- browser offline retry for this exact modal.

لا تم تحويل أي Unknown إلى PASS.

---

## 31. FINAL CLOSURE MATRIX

| العنصر | الحالة |
|---|---|
| DirectSale root cause | CLOSED |
| RLS mismatch | CLOSED |
| Direct rep visibility | CLOSED |
| Vehicle candidate visibility | CLOSED |
| V-03 | ALREADY CLOSED |
| V-04 | ALREADY CLOSED |
| Create DirectSale backend | PRODUCTION VERIFIED |
| Send DirectSale backend | PRODUCTION VERIFIED |
| Physical stock centralization | CLOSED |
| Mobile branch contract | CLOSED |
| Main HTML | UNTOUCHED |
| Vouchers source | VERIFIED / NO NEW PATCH |
| Van Sales | PRESERVED |
| New Edge Function | NOT CREATED |
| Production migration source | RECORDED IN GIT |
| Current State | UPDATED |
| Browser authenticated E2E | OPEN |

---

## 32. التعليمات للجلسة التالية

ابدأ بهذا الترتيب فقط:

1. تحقق من Production snapshot أولاً.
2. تحقق من migration:
   `allow_warehouse_direct_rep_lookup_for_vouchers`
3. تحقق من:
   - `vouchers@rawaea.com`
   - Active Direct Sales Rep
   - Active Vehicle
   - mobile_branch_id
4. تحقق من Current vouchers blob:
   `570a4a952b7645e5ef7674e80d5238b65f8cd9eb`
5. لا تعيد V-03/V-04.
6. لا تلمس `main.html`.
7. لا تعدل `van-sales.html` بلا دليل جديد.
8. شغّل Browser E2E حقيقي عند توفر runner.
9. لا تحول Browser E2E إلى PASS إلا بدليل تنفيذ فعلي.
10. إذا ظهرت مشكلة جديدة، افتح Closure Unit جديدة منفصلة.

---

# FINAL STATUS

**DIRECTSALE RLS ROOT CAUSE = CLOSED**

**DIRECTSALE PRODUCTION CONTRACT = CLOSED**

**DIRECTSALE CREATE/SEND E2E = PRODUCTION VERIFIED**

**CURRENT VOUCHERS SOURCE = ALREADY CORRECT**

**V-03/V-04 = DO NOT REAPPLY**

**MAIN.HTML = UNTOUCHED**

**VAN SALES = PRESERVED**

**NO NEW EDGE FUNCTION = CREATED**

**PRODUCTION MIGRATION = RECORDED**

**CURRENT_STATE = UPDATED**

**BROWSER E2E = OPEN / NOT CLAIMED**

---

# END OF REPORT 290
