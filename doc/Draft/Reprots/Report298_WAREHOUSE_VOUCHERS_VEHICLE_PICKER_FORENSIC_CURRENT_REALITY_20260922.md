# تقرير 298 — التحقيق الجنائي النهائي لتبويب الأذونات المخزنية / Vehicle Picker / الحالة الحالية
## التاريخ
2026-09-22

## 1. نطاق الإغلاق
النطاق الوحيد في هذه الدورة:
- تبويب إدارة المخازن والمخزون → الأذونات المخزنية.
- الملف التشغيلي:
  `companies/company-1/warehouse/vouchers.html`
- التكامل الوظيفي مع:
  `companies/company-1/sales/van-sales.html`
- تكامل النظام الأم:
  `Current/PWA/main.html`
- المشكلة محل التحقيق:
  "في مودال إذن جديد لا تظهر المركبات / حقل المركبة غير مرتبط بجدول المركبات".
- منع صريح:
  - لا تعديل على `main.html`.
  - لا تعديل مباشر على `vouchers.html` في المستودع.
  - لا تعديل على `van-sales.html`.
  - لا إنشاء Edge Function جديدة.
  - لا إعادة إصلاح Closure مغلقة سابقًا.

---

## 2. ترتيب مصادر الحقيقة
تم تطبيق ترتيب الحوكمة كما هو معتمد:

CURRENT PRODUCTION
>
CURRENT DATABASE
>
CURRENT DEPLOYMENT EVIDENCE
>
CURRENT GIT
>
CURRENT SOURCE
>
VERIFIED RUNTIME
>
HISTORICAL CONTRACT
>
REPORTS
>
MEMORY

التقارير السابقة استُخدمت كدلائل بحث فقط، ولم تُعامل كحالة حالية.

---

## 3. CURRENT GIT — SYSTEM REPOSITORY

Repository:
`papamohammed77-glitch/rawaie-erp-New`

CURRENT HEAD:
`81278862de493a597ac74e2c975ff74bdbeb298b`

Immediate Parent:
`cc226abb50732cef510a70f412f08f1981ae2d82`

Commit:
`docs: align CURRENT_STATE with final report head`

نتيجة فحص الـcommit:
- التعديل في هذا الـcommit على `CURRENT_STATE.md` فقط.
- لا تعديل Runtime.
- لا تعديل Voucher Source.
- لا تعديل Production Contract.

وبالتالي لا يوجد Runtime change مخفي في آخر System commit.

---

## 4. CURRENT GIT — FRONTEND REPOSITORY

Repository:
`papamohammed77-glitch/erp-frontend`

CURRENT HEAD:
`745a615ccd0baff09ad2619b0316e46507a862e9`

Immediate Parent:
`29cd6e08056b50545db05a4bff220424127126c5`

Current:
`companies/company-1/warehouse/vouchers.html`

CURRENT FILE SHA:
`d02d3696d9ca1af8014fbb61c680c04c09c39b7e`

Current size:
- 92,667 characters
- 1,830 lines

آخر commit Runtime ذي الصلة هو:
`745a615...`

وهذا commit غيّر فقط موضع:
`s.routeHtml()`

ولم يغير:
- vehicle query
- vehicle filtering
- representative binding
- RPC contract
- Production schema.

---

## 5. CURRENT SOURCE — MAIN SYSTEM

`Current/PWA/main.html`

CURRENT SHA:
`27b777528665dcc985809648f006452c861ae36e`

الحكم المعماري المطبق في النظام الأم:
- `stock_vouchers` مملوكة تشغيليًا لتطبيق الأذونات.
- النظام الأم Control / Navigation / Monitoring Plane.
- المخزون في النظام الأم Read Model.
- لا يجوز نقل منطق Voucher operational إلى `main.html`.
- `vouchers.html` هو Operational Plane للأذونات المخزنية.
- `post_stock_movement` هو Physical Stock Engine.

هذا يؤكد أن الفصل الحالي مقصود معماريًا وليس جزيرة منفصلة.

---

## 6. CURRENT SOURCE — VAN SALES

File:
`companies/company-1/sales/van-sales.html`

CURRENT SHA:
`8d61382a8e0025a0d079e71dd94f33d106d9088e`

CURRENT line count:
2,297

النقاط التي تم التحقق منها:
- `loadVanBranch` يبدأ عند السطر 301.
- يستخدم `setup-van-branch`.
- `vanBranchId` يمثل Mobile Vehicle Stock.
- `vehicle_id` و`vehicle_code` و`driver_id` تحفظ ضمن سياق مخزن السيارة.
- البيع يستخدم `save-sales-invoice`.
- `source: 'van-sales'` موجود.
- `operation_id` محفوظ محليًا لإعادة المحاولة الآمنة.
- البيع الفعلي من المخزون المحمول يحدث بعد نقل العهدة إلى السيارة.

المسار المعماري:

Warehouse Branch
→ DirectSale Voucher
→ Vehicle Mobile Branch
→ Van Sales
→ Customer Sale
→ save-sales-invoice
→ Physical Stock Engine
→ Accounting / Ledger

لا يوجد Defect جديد مثبت في `van-sales.html` ضمن نطاق هذه الدورة، ولذلك لم يُلمس.

---

## 7. HISTORICAL CONTRACT — MANUAL VOUCHERS

تمت مراجعة الوثيقة التاريخية:

`rawaie-erp-review/Architecture/الأذونات المخزنية اليدوية.md`

SHA:
`9b2a2ca88eaa11a6a057812c7f0513ba57e0558f`

العقد التاريخي يثبت أن الأذونات المخزنية اليدوية تعالج الحركات التي ليست جزءًا من دورة:
- Order
- Runsheet
- Customer Delivery

القدرات:
- Transfer
- DirectSale
- DirectReturn
- SupplierReturn
- Scrap
- Adjustment

والتمييز الحاكم:

DirectSale Voucher
=
نقل عهدة مخزنية إلى مخزن السيارة

وليس:
Customer Sale Invoice

ثم:
Van Sales
=
بيع العميل الفعلي من المخزون المحمول.

DirectReturn:
Vehicle Mobile Stock
→ Branch

هذا العقد لم يتغير.

---

# 8. PRODUCTION — FRESH SNAPSHOT

Production Project:
`fiilmooggumokxanwiyx`

Fresh snapshot:
2026-09-22 06:17:20.921273+00

الحالة:
- companies = 1
- branches = 3
- items = 17
- vehicles = 1
- active vehicles = 1
- stock_vouchers = 1
- inventory_log = 6
- audit_log = 2034

هذه اللقطة أحدث من أرقام التقارير السابقة.

---

## 9. VEHICLE MASTER — CURRENT PRODUCTION FACT

المركبة الحالية:

vehicle_id:
`5fe9d0b6-fc54-4cc6-9bff-ede0e8557dd8`

vehicle_code:
`VEH-TEST-260921`

license:
`س ن ر 6021`

model:
`Suzuki Carry 2024`

company:
`00000000-0000-0000-0000-000000000001`

status:
`Active`

driver_id:
`111b0730-a977-4d11-bcd0-2427b178a9e5`

driver:
`vansales@rawaea.com`

driver role:
`مندوب بيع مباشر`

driver status:
`Active`

mobile_stock_enabled:
`true`

mobile_branch_id:
`5372503d-f638-4e7f-808d-bda585825b2f`

mobile branch:
`VAN-VEH-TEST-260921`

mobile branch active:
`true`

لا يوجد نقص في Vehicle Master.

---

## 10. VEHICLES RLS — FORENSIC PROOF

Production policy:

`vehicles_select_company`

SELECT for:
`authenticated`

Predicate:

`company_id = app_private.current_user_company_id()`

تم فحص:
`app_private.current_user_company_id()`

وتعريفها الحالي:

- تعتمد على `auth.uid()`.
- تربط `users.auth_id`.
- تعيد `users.company_id`.
- تستبعد المستخدم Inactive.

---

## 11. AUTHENTICATED RLS SIMULATION

تمت محاكاة نفس سياق:

user:
`vouchers@rawaea.com`

auth_id:
`2e5262ec-8f7b-4d7e-824b-7ec5dcad62da`

وتحت:
`role = authenticated`

تم تنفيذ استعلام:

- current_user_company_id()
- auth.uid()
- vehicles
- company scope
- active status

النتيجة:
`visible_active_vehicle_count = 1`

هذا إثبات مباشر أن:
**الـauthenticated user نفسه يستطيع رؤية المركبة عبر RLS.**

إذن:
- المشكلة ليست Vehicle RLS.
- المشكلة ليست Company Context في جدول المركبات.
- المشكلة ليست انعدام المركبات.

---

# 12. CURRENT VOUCHERS SOURCE — VEHICLE QUERY

في:
`companies/company-1/warehouse/vouchers.html`

الدالة:
`loadRefs`

السطر:
28

الاستعلام الخاص بالمركبات عند السطر:
40

الاستعلام الحالي يطلب:

- id
- vehicle_code
- license_plate
- model
- driver_id
- status
- mobile_branch_id
- mobile_stock_enabled

ويطبق:
- `eq('company_id', s.company)`
- `eq('status', 'Active')`
- `order('vehicle_code')`

إذن التطبيق بالفعل:
**مرتبط مباشرة بجدول `vehicles`.**

ولا يوجد:
- array hardcoded
- vehicle mock
- static vehicle list
- query من branches بدل vehicles.

---

# 13. CURRENT SOURCE — VEHICLE BRANCH RESOLUTION

الدالة:
`vehicleBranch`

السطر:
820

العقد الحالي:

1. ترفض السيارة إذا `mobile_stock_enabled === false`.
2. تحاول أولًا:
   `vehicles.mobile_branch_id`
3. تتحقق أن المخزن:
   - نفس company
   - active
4. إذا لم يوجد:
   تستخدم fallback التاريخي:
   `VAN-{vehicle_code}`

هذا قرار صحيح لأنه:
- يحافظ على Canonical mobile_branch_id.
- يحافظ على التوافق التاريخي.
- لا يكسر Vehicle Stock.

---

# 14. CURRENT SOURCE — PICKER ARRAY

الدالة:
`pickArr`

السطر:
864

DirectSale:
`key === 'wsTo' && type === 'DirectSale'`

المركبة تمر فقط إذا:

- status = Active
- mobile branch صالح
- mobile_stock_enabled != false
- rep مرتبط بـ `driver_id`
- المصدر Branch موجود
- المستخدم مسموح له بالمصدر
- المندوب مسموح له بالمصدر
- إذا اختير Rep محدد:
  vehicle.driver_id == selectedRep

هذا يطابق العقد الوظيفي.

---

# 15. CURRENT SOURCE — PICKER SEARCH

الدالة:
`pickSearch`

تبحث في Vehicle fields:

- vehicle_code
- license_plate
- model

وتحوّل النتائج إلى Smart Menu.

وبالتالي:
**البحث ليس منفصلًا عن جدول المركبات.**

المشكلة المبلغ عنها ليست missing search function.

---

# 16. CURRENT SOURCE — VEHICLE SELECTION

الدالة:
`pickSelect`

السطر:
992

عند اختيار Vehicle في DirectSale:

- يحفظ:
  `wsTo.value = vehicle.id`
- يضع:
  `vehicle_code / license_plate / model`
  في الحقل المرئي.
- يستخرج:
  `vehicle.driver_id`
- يربطه بالمندوب.
- يتحقق من Branch context.
- يتحقق من Rep/Branch contract.

وعند Submit:

السطر:
1370

يُرسل:

- `toType = Vehicle`
- `toId = vehicle.id`
- `rep_id = rep`
- `operation_id`

إذن الـUUID الصحيح للمركبة ينتقل حتى الـBackend.

---

# 17. CURRENT SOURCE — ROUTE / CLIPPING FIX

الدالة:
`routeHtml`

السطر:
1149

موضع routeHtml الحالي:
السطر 1168

الحالة الحالية:

`s.routeHtml()`

موجود **خارج**:

`wsTopPanel`

وليس داخله.

والـCSS الحالي يحتوي:

`.ws-top-panel { overflow:hidden; }`

إذن:
Smart Menu الخاص بالمركبة لم يعد داخل clipping container.

هذا هو الإصلاح الجراحي السابق الحقيقي.

---

# 18. ROOT CAUSE — THE ACTUAL HISTORICAL DEFECT

العطل الذي كان يجعل المستخدم يرى أن المركبات "لا تظهر" لم يكن:

- نقص جدول vehicles.
- نقص Vehicle rows.
- نقص company_id.
- نقص RLS.
- نقص RPC.
- نقص rep.
- نقص mobile branch.
- نقص mobile stock.
- ضعف query.

السبب الفعلي كان:

`s.routeHtml()`

كان داخل:

`.ws-top-panel`

والـpanel:
- قابل للطي.
- `overflow:hidden`.

الـSmart Menu كان يُنشأ فعليًا،
لكن حدوده المرئية كانت تُقص بواسطة الأب.

لذلك:
البرنامج كان يجد المركبة،
لكن المستخدم قد لا يرى القائمة فعليًا.

---

# 19. CURRENT FIX STATUS

المشكلة السابقة تم إصلاحها بالفعل في CURRENT SOURCE عبر commit:

`745a615ccd0baff09ad2619b0316e46507a862e9`

التغيير:
نقل:

`s.routeHtml()`

خارج:

`wsTopPanel`

دون تعديل:
- vehicle query
- picker logic
- submit
- backend
- RPC
- database.

هذه النقطة:
**لا يجوز إعادة إصلاحها.**

---

# 20. FORENSIC RECONSTRUCTION OF THE REPORTED FAILURE

لدينا الآن سلسلة أدلة كاملة:

PRODUCTION:
Vehicle موجودة
↓
Vehicle Active
↓
Mobile Stock enabled
↓
Mobile Branch valid
↓
Rep valid
↓
RLS authenticated visibility = 1

CURRENT SOURCE:
vehicles query موجود
↓
vehicleBranch موجود
↓
pickArr موجود
↓
pickSearch موجود
↓
pickSelect موجود
↓
submit يرسل vehicle.id

CURRENT UI STRUCTURE:
routeHtml خارج clipping panel

وبالتالي:
**لا توجد حاليًا فجوة منطقية في Source + DB تفسر عدم ظهور المركبة.**

---

# 21. CURRENT PICKARR RECONSTRUCTION AGAINST PRODUCTION DATA

تمت مطابقة كل شروط DirectSale على المركبة الإنتاجية الحالية:

- active_ok = true
- mobile_stock_ok = true
- mobile_branch_ok = true
- rep_ok = true
- source_branch_ok = true
- rep_branch_ok = true
- user_branch_ok = true

النتيجة:

`pickarr_directsale_vehicle_would_pass = true`

هذه نتيجة حسابية مبنية على بيانات Production الحالية.

إذن:
**المركبة يجب أن تدخل قائمة Vehicle في DirectSale عندما يكون المصدر BR-01 محددًا.**

---

# 22. CURRENT EDGE FUNCTIONS

تم فحص الـEdge Functions الحالية ذات الصلة.

## setup-van-branch
Version:
4

verify_jwt:
true

## create-stock-voucher
Version:
10

verify_jwt:
true

## send-stock-voucher
Version:
20

verify_jwt:
true

## receive-stock-voucher
Version:
22

verify_jwt:
true

لا توجد حاجة إلى Edge Function جديدة.

---

# 23. CURRENT CREATE-STOCK-VOUCHER CONTRACT

الـEdge الحالي:

`create-stock-voucher`

لا يكتب Vehicle data بنفسه.

بل:
- يحقق المستخدم.
- يحدد company من users.auth_id.
- يمرر:
  - from
  - to
  - rep_id
  - operation_id
  إلى RPC canonical.

وهذا صحيح معماريًا.

---

# 24. CURRENT DATABASE RPC CONTRACT

Production تحتوي على:

`create_manual_stock_voucher_atomic`

والـcanonical 12-argument signature الحالية تشمل:

- p_company_id
- p_type
- p_reference
- p_from_type
- p_from_id
- p_to_type
- p_to_id
- p_notes
- p_created_by
- p_items
- p_rep_id
- p_operation_id

الـ12-arg path:
- يتحقق من منشئ الإذن.
- يتحقق من الشركة.
- يتحقق من المندوب.
- يتحقق من role = مندوب بيع مباشر.
- يتحقق من صلاحية van-sales.
- ثم يمرر الحركة إلى Core.

لا يوجد احتياج إلى RPC جديد لإظهار المركبات في الواجهة الحالية.

---

# 25. PRODUCTION TRANSACTIONAL SAFETY TEST

تم تنفيذ Transaction حقيقية على Production تشمل:
- إنشاء DirectSale.
- محاولة الإرسال.
- التحقق من عدم وجود أثر دائم بعد Rollback.

بعد Rollback:

`vouchers_after_rollback = 0`

`logs_after_rollback = 0`

إذن:
- لا Test Residue.
- لا تلويث للبيانات.

ملاحظة الحوكمة:
الـconnector أعاد نتيجة الاستعلام النهائي بعد Rollback فقط؛ لذلك لا يتم استخدام هذه الجولة وحدها لإدعاء نجاح intermediate CREATE/SEND، وإنما لإثبات سلامة rollback وعدم ترك أثر.

---

# 26. CURRENT PERSISTENT DEMO DATA — CORRECTION

البيانات الحالية Production لا تطابق بعض الأرقام القديمة في CURRENT_STATE السابق.

الحالة الفعلية الآن:

Persistent demo voucher:
`IN-1`

type:
`DirectSale`

status:
`Cancelled`

from:
`BR-01`

to:
`VEH-TEST-260921`

reference:
`DEMO-DIRECT-SALE-2026-09-21`

هذا السجل لم يتم حذفه.

لا توجد حركة Physical حالية مرتبطة به.

لا يوجد سبب لإعادة تغييره أو حذفه ضمن نطاق هذه المهمة.

---

# 27. CURRENT SOURCE — SEARCH / CATEGORIES

تم أيضًا التحقق أن Product Search أصبحت مستقلة عن top panel:

- `wsSearch`
- `wsResults`
- `wsScanBtn`
- `wsCats`

وهذا تم بالفعل في parent runtime change قبل commit `745a615...`.

لا يوجد إصلاح جديد هنا.

---

# 28. COMPETITOR BENCHMARK — VERIFIED CURRENT OFFICIAL SOURCES

## Odoo 19
Odoo يدعم:
- Inventory Adjustments.
- Barcode inventory counting.
- تعيين عمليات العد للمستخدمين.
- اختيار Product وQuantity وLocation.
- +1 / -1.
- تاريخ حركة المخزون.

مصدر:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/barcode/operations/adjustments.html

## Microsoft Dynamics 365
Inventory journals تشمل:
- Movement
- Inventory adjustment
- Transfer
- Item arrival
- Counting
- Tag counting

والـTransfer يعتمد على From / To Inventory Dimensions.

مصدر:
https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/inventory-journals

## SAP S/4HANA
Goods Movement يغطي:
- Goods Receipt
- Goods Issue
- Physical Stock Transfer
- Transfer Posting
- Material Document / history

مصدر:
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/91b21005dded4984bcccf4a69ae1300c/742e46e570984d9aa74e468838f6e1ff.html

## Daftra
يوفر:
- From Warehouse
- To Warehouse
- Quantity
- Available Before
- Available After
- Notes
- Detailed movement history
- Product/Warehouse/Type filtering
- Print / Export

مصادر:
https://docs.daftra.com/en/tutorial/transferring-stock/
https://docs.daftra.com/en/tutorial/inventory-detailed-transactions-report/
https://docs.daftra.com/en/tutorial/detailed-stock-transactions-for-each-product-report/

## Manager.io
يوثق:
- Inventory Transfers
- Date
- Reference
- Description
- Item
- Qty
- From
- To
- movement between inventory locations
- Inventory Quantity by Location

مصادر:
https://www2.manager.io/guides/10707
https://www2.manager.io/guides/11130

---

# 29. COMPETITIVE COVERAGE CURRENTLY PRESENT IN RAWAEA

تطبيق الأذونات الحالي يحتوي بالفعل على عناصر مهمة تنافسية:

- From / To.
- Branch / Vehicle / Supplier dimensions.
- Vehicle mobile stock.
- Rep binding.
- Product search.
- Barcode scan.
- Quantity controls.
- Stock availability.
- Expected-after view.
- Draft / Sent / Received / Completed / Cancelled lifecycle.
- Audit detail.
- Physical movement detail.
- Operation identity.
- Permission-aware branch selection.
- Separate field applications.
- Central Physical Stock Engine.

هذه ليست مجرد UI shells؛ معظمها مربوط فعليًا بالـdatabase / RPC / Production.

---

# 30. REAL COMPETITIVE GAPS — CLASSIFIED, NOT INVENTED

الفجوات التي ظهرت من المقارنة ولكن تحتاج Business Contract مستقل:

1. Date field قابلة للتحرير للمستند.
2. Lot / Serial / Expiry traceability.
3. Formal document approvals.
4. Attachments / evidence for sensitive vouchers.
5. Rich discrepancy reason taxonomy.
6. Richer movement filters and reporting.
7. In-transit stock model.
8. Inventory count assignment/session contract.
9. Before/After stock snapshots as first-class reporting fields.

هذه لم تُنفذ في هذه الدورة لأن إدخالها داخل Voucher UI الآن سيخلق:
- Business Contract جديد.
- Schema consequences.
- Reporting consequences.
- Accounting consequences.
- Cross-module effects.

ولذلك لم يتم اختلاقها.

---

# 31. NO PRODUCTION PATCH REQUIRED IN THIS CYCLE

بعد المقارنة بين:

CURRENT PRODUCTION
+
CURRENT SOURCE
+
RLS
+
RPC
+
EDGE
+
HISTORICAL CONTRACT

لم يظهر Defect Production حالي يستدعي DDL أو data repair.

تم رفض إنشاء:
- RPC جديد للمركبات.
- Edge Function جديد.
- جدول Vehicle جديد.
- علاقة جديدة.
- migration تجميلي.
- query workaround.

السبب:
البنية الحالية موجودة بالفعل وصحيحة.

---

# 32. OWNER SURGICAL CHANGESET

## الحالة

**لا يوجد Owner Change Set جديد في `vouchers.html`.**

السبب:
الـsource الحالي هو أصلًا نسخة ما بعد الإصلاح:

`745a615...`

والـblob الحالي:
`d02d3696...`

أي أن إعادة إعطاء نفس patch سيكون:
- تكرارًا للإصلاح.
- Regression risk.
- مخالفًا لقاعدة عدم إعادة إصلاح المغلق.

### OWNER ACTION

لا تعدّل `vouchers.html) مرة أخرى بسبب مشكلة المركبات.

لا تعدّل:
- loadRefs
- vehicleBranch
- pickArr
- pickSearch
- pickSelect
- routeHtml
- renderWorkspace
- submit

لهذا العطل.

---

# 33. السبب الحقيقي إذا كانت المشكلة ما زالت تظهر للمستخدم

بعد استنفاد الأدلة المتاحة:

- Production vehicles = صحيحة.
- RLS visibility = صحيحة.
- Current source = صحيح.
- pickArr predicate = يمر.
- route clipping fix = موجود.
- current Edge contracts = صحيحة.

لذلك لا يمكن دعم ادعاء أن هناك Defect حالي داخل:
- Vehicle table
- RLS
- vouchers source
- RPC

إذا استمر ظهور المشكلة في المتصفح، فطبقة العطل المتبقية هي:

**Published Browser Runtime / Deployment Artifact**

وليس Source أو Production Database.

هذه النقطة لم يتم تحويلها إلى "Closed" لأن أداة الجلسة لا توفر تحققًا مباشرًا من Cloudflare Pages artifact المنشور الحالي.

---

# 34. DEPLOYMENT EVIDENCE CURRENTLY AVAILABLE

`_headers` الحالي:
SHA:
`44f65fb3bb36923f8cc7b9060ec7bd13cdbafbee`

يضع:
- no-cache
- no-store
- must-revalidate
لصفحات HTML الرئيسية.

`register-sw.js`
SHA:
`9a8f8b14be0cfb92e82077c36b36fab9b452c8ec`

يقوم:
- registration.update()
- periodic update
- focus/online update.

`sw.js`
SHA:
`6123fce8b99391d70e6937bde5c4fcbd3f2d8f48`

والتعليق والعقد الحاليان يثبتان:
- HTML/navigation = network-backed
- API/runtime = network-backed
- static assets فقط هي التي تستخدم cache.

إذن Service Worker cache ليس مبرهنًا عليه كسبب.

لكن:
**Published Cloudflare artifact نفسه لم يتم فتحه مباشرة.**

---

# 35. CLOSURE CLASSIFICATION

## CLOSED / VERIFIED
- Vehicle master exists.
- Vehicle company context.
- Vehicle active status.
- Vehicle mobile branch.
- Vehicle mobile stock enabled.
- Vehicle driver.
- Rep identity.
- Vehicle RLS visibility.
- Vehicle query in vouchers source.
- VehicleBranch resolution.
- DirectSale vehicle filtering.
- Vehicle selection.
- Vehicle UUID submission.
- Historical vehicle clipping root cause.
- Clipping source fix.
- Mother delegation.
- Van Sales mobile stock integration.
- Existing Edge Functions.
- Existing canonical voucher RPC.
- Transaction rollback safety.

## NOT CLOSED
- Published Cloudflare browser runtime identity.
- Authenticated live browser E2E against published artifact.

لا يجوز تحويل النقطتين الأخيرتين إلى CLOSED.

---

# 36. PRE-SWEEP SELF-AUDIT

### Business Understanding
Confirmed.

### Architecture Understanding
Confirmed.

### Database Understanding
Confirmed.

### Historical Understanding
Confirmed.

### Production Understanding
Confirmed.

### Current Source Understanding
Confirmed.

### Consumer Understanding
Confirmed for Voucher ↔ Van Sales ↔ Mother.

### Dependency Understanding
Confirmed for Vehicle → Mobile Branch → Voucher → Van Sales.

### Execution Confidence
High for source/database/backend.

---

## Confirmed Facts
- Production has one Active Vehicle.
- The vehicle is visible under simulated authenticated RLS.
- Current source directly queries vehicles.
- Current picker predicate passes the vehicle.
- Current source already contains clipping fix.
- Current Edge versions are active and JWT protected.
- No Production schema patch is required.
- No new Edge Function is required.
- No data repair is justified by current evidence.

## Unknowns
- Published Cloudflare artifact exact SHA.
- Live authenticated browser runtime after publication.

## Conflicts
- Older CURRENT_STATE sections contain older system/front-end SHAs.
- Current Git overrides those older values.
- Persistent demo voucher status is currently Cancelled, not Draft as some older checkpoint text stated.

## Unverified Claims
- Browser UI after the latest publication.

---

# 37. FINAL SELF-AUDIT

### What was proved
- The reported "vehicles are not connected" condition is false for CURRENT SOURCE.
- The Vehicle table is wired directly.
- The authenticated user can see Vehicle under current RLS.
- The production vehicle passes all current DirectSale picker conditions.
- The current source contains the correct clipping repair.
- DirectSale/backend contracts remain connected to the vehicle UUID.
- Van Sales consumes the canonical mobile branch.
- No new Production infrastructure is required.

### What was not proved
- Live browser publication equality with current frontend HEAD.

### What was not changed
- main.html: untouched.
- vouchers.html: untouched.
- van-sales.html: untouched.
- Production schema: untouched.
- Production data: untouched.
- Edge Functions: no new function.
- Existing Edge versions were only inspected.

### What was initially believed but disproved
"المركبات لا تظهر لأن التطبيق غير مرتبط بجدول المركبات."

هذا غير صحيح في CURRENT STATE.

The current implementation is already directly connected.

### What remains possible
إذا استمرت المشكلة في المتصفح:
- Deployment artifact mismatch.
- Published runtime not at current HEAD.
- Browser opened against an older deployment.
- Authenticated session context not matching the tested user.

هذه الاحتمالات لم يتم اختيار واحد منها كحقيقة نهائية لأن deployed runtime لم يُفحص مباشرة.

---

# 38. CURRENT NEXT EXACT TASK

ابدأ الجلسة القادمة بهذا التسلسل فقط:

1. اقرأ آخر ذيل من `CURRENT_STATE.md`.
2. تحقق من System HEAD:
   `81278862de493a597ac74e2c975ff74bdbeb298b`
3. تحقق من Frontend HEAD:
   `745a615ccd0baff09ad2619b0316e46507a862e9`
4. تحقق من vouchers blob:
   `d02d3696d9ca1af8014fbb61c680c04c09c39b7e`
5. لا تعيد أي Voucher Source patch.
6. افتح/تحقق من Published Cloudflare artifact.
7. نفذ Browser E2E authenticated:
   - DirectSale
   - Branch BR-01
   - Vehicle VEH-TEST-260921
   - Rep vansales@rawaea.com
8. اثبت ظهور Vehicle Menu في المتصفح نفسه.
9. ثم نفذ:
   DirectSale → Send
10. ثم:
   DirectReturn → Send → Receive
11. Retry Receive بنفس operation_id.
12. طابق inventory_log + audit_log + stock.
13. أعد Fresh Production snapshot في نفس لحظة التقرير.
14. فقط بعدها احسم Browser E2E Closure.

---

# 39. ENGINEERING INSTRUCTION TO THE NEXT CTO

لا تبدأ من جديد.

لا تبحث عن Vehicle relationship جديدة.

لا تضف Edge Function جديدة.

لا تنشئ RPC vehicle picker بلا سبب.

لا تعيد:
- loadRefs fix
- vehicleBranch fix
- pickArr fix
- clipping fix
- DirectSale backend fix.

ابدأ من:

CURRENT FRONTEND:
`745a615...`

CURRENT VOUCHERS BLOB:
`d02d3696...`

CURRENT PRODUCTION:
Vehicle `VEH-TEST-260921`

ثم افحص فقط:
**Published Runtime == Current Source ?**

إذا:
YES
→ Browser E2E

إذا:
NO
→ Deployment Drift Closure

ولا تعكس نتيجة Production إلى Source أو العكس من غير دليل.

---

# 40. FINAL RESULT

**Voucher Vehicle Data / Database Contract = PROVEN**

**Vehicle ↔ Rep Contract = PROVEN**

**Vehicle ↔ Mobile Branch Contract = PROVEN**

**Vehicle Picker Current Source = PROVEN**

**Historical Clipping Root Cause = PROVEN**

**Historical Clipping Fix = PRESENT**

**Mother Integration = PROVEN**

**Van Sales Integration = PROVEN**

**Production Vehicle RLS Visibility = PROVEN**

**Production schema repair needed = NO**

**New Edge Function needed = NO**

**New voucher source patch needed = NO**

**Published Browser Runtime = OPEN**

**Full Voucher Browser Closure = OPEN ONLY AT DEPLOYMENT/RUNTIME GATE**

---

# END OF REPORT 298
