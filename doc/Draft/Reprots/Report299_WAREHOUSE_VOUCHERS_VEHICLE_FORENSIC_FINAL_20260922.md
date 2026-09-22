# تقرير 299 — الأذونات المخزنية / حقل المركبة — التحقيق الجنائي والإغلاق

## 1. نطاق المهمة
الملفات والطبقات محل التحقيق:
- النظام الأم: `companies/company-1/main.html` — قراءة فقط، لم يتم تعديله.
- التطبيق المنفصل: `companies/company-1/warehouse/vouchers.html` — قراءة وتحقيق فقط، لم يتم تعديله في هذه الجلسة.
- التطبيق المنفصل: `companies/company-1/sales/van-sales.html` — قراءة فقط، لم يتم تعديله.
- Supabase Production: مشروع `fiilmooggumokxanwiyx`.
- Edge Functions/RPCs الحالية المرتبطة بدورة الأذونات.
- Service Worker / browser runtime evidence.
- السجل التاريخي المعماري للأذونات المخزنية اليدوية.
- مقارنة وظيفية مع Odoo وDynamics 365 وSAP S/4HANA وDaftra وManager.io.

القاعدة الحاكمة:
CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.
التقارير السابقة استُخدمت كأدلة تاريخية فقط، وليست مصدرًا للحالة الحالية.

---

## 2. Governance ومرجع الحالة
تمت قراءة MASTER CTO GOVERNANCE وCURRENT_STATE والتقارير الأخيرة الخاصة بالـVoucher/Vehicle/Picker، ثم تمت إعادة المطابقة مع الحالة الفعلية.

التسلسل الحاكم:
UNDERSTAND
→ HISTORICAL CONTRACT
→ CURRENT BEHAVIOR
→ DATA/AUTH/CONTROL FLOW
→ TARGET
→ ACTUAL GAP
→ SURGICAL CHANGE
→ TEST
→ PRODUCTION VERIFY
→ CLOSE

لا توجد هذه الجلسة إعادة إصلاح لأي Closure مثبت سابقًا.

---

## 3. CURRENT GIT

### System repository
Repository:
`papamohammed77-glitch/rawaie-erp-New`

Current HEAD:
`0559ae76896c605fa17cf05b49b6fd9e389ffbbf`

Parent:
`81278862de493a597ac74e2c975ff74bdbeb298b`

الـHEAD الحالي توثيقي؛ لا يحتوي تغييرًا تشغيليًا جديدًا في Voucher/Vehicle.

### Frontend repository
Repository:
`papamohammed77-glitch/erp-frontend`

Current HEAD:
`745a615ccd0baff09ad2619b0316e46507a862e9`

Parent:
`29cd6e08056b50545db05a4bff220424127126c5`

Current voucher blob:
`d02d3696d9ca1af8014fbb61c680c04c09c39b7e`

Current van-sales blob:
`8d61382a8e0025a0d079e71dd94f33d106d9088e`

Current common core:
`b3da51ee5a577e1aef346beb0ed4a866df7d563c`

Current Service Worker:
`6123fce8b99391d70e6937bde5c4fcbd3f2d8f48`

---

## 4. CURRENT PRODUCTION SNAPSHOT

Captured:
`2026-09-22 06:35:45.778287+00`

- companies = 1
- branches = 3
- items = 17
- vehicles = 1
- active_vehicles = 1
- stock_vouchers = 1
- stock_voucher_details = 3
- stock_voucher_operations = 1
- inventory_log = 6
- audit_log = 2034

Production vehicle:
- id = `5fe9d0b6-fc54-4cc6-9bff-ede0e8557dd8`
- vehicle_code = `VEH-TEST-260921`
- license_plate = `س ن ر 6021`
- model = `Suzuki Carry 2024`
- company_id = `00000000-0000-0000-0000-000000000001`
- status = `Active`
- driver_id = `111b0730-a977-4d11-bcd0-2427b178a9e5`
- mobile_stock_enabled = true
- mobile_branch_id = `5372503d-f638-4e7f-808d-bda585825b2f`
- mobile branch code = `VAN-VEH-TEST-260921`
- mobile branch active = true

Direct-sales user:
- id = `111b0730-a977-4d11-bcd0-2427b178a9e5`
- email = `vansales@rawaea.com`
- role = `مندوب بيع مباشر`
- status = `Active`
- company_id = `00000000-0000-0000-0000-000000000001`
- allowed_branch_ids = `BR-01`
- permissions = [`van-sales`]

Voucher operator:
- email = `vouchers@rawaea.com`
- role = `مخزني`
- status = `Active`
- company_id = `00000000-0000-0000-0000-000000000001`
- allowed_branch_ids = `BR-01`
- permissions = [`warehouse`]

Production branches:
- BR-01 — الفرع الرئيسي
- BR-2 — فرع إسكندرية
- VAN-VEH-TEST-260921 — مخزن السيارة

---

## 5. ما تم إثباته في CURRENT SOURCE — vouchers.html

### 5.1 App.init
`App.init` يثبت سياق الشركة من جلسة Auth ثم يقرأ جدول `users` باستخدام `auth_id`:
- لا يوجد hard-coded company context.
- `s.company` تُضبط من سجل المستخدم الفعلي.
- بعد ذلك فقط يتم استدعاء `loadRefs()`.

### 5.2 loadRefs — السطر 28
`loadRefs:function()` يقرأ:
- branches
- vehicles
- suppliers
- direct-sales reps
- purchase order supplier/branch map

استعلام المركبات هو:
- جدول `vehicles`
- `company_id = s.company`
- `status = 'Active'`
- select:
  - id
  - vehicle_code
  - license_plate
  - model
  - driver_id
  - status
  - mobile_branch_id
  - mobile_stock_enabled

إذن:
لا توجد قائمة مركبات hard-coded.
لا توجد قراءة من branches بدل vehicles.
لا يوجد mock vehicle source.

### 5.3 vehicleBranch — السطر 820
الأولوية:
1. `vehicles.mobile_branch_id`
2. fallback تاريخي:
   `VAN-${vehicle_code}`

مع:
- نفس company
- branch active
- mobile stock enabled

### 5.4 pickArr — السطر 864
في DirectSale:
- المصدر = branch.
- الوجهة = vehicle.
- المركبة لا تدخل القائمة إلا إذا:
  - Active
  - لها mobile branch صالح
  - mobile stock enabled
  - لها rep صالح
  - المصدر branch صالح
  - المستخدم مسموح بالمصدر
  - rep مسموح بالمصدر
  - عند اختيار rep محدد: driver_id يطابقه

هذه ليست فجوة؛ هذا هو Company/Branch/Rep control contract.

### 5.5 pickSearch — السطر 991
نوع الحقل في DirectSale/To = vehicle.
البحث يتم على:
- vehicle_code
- license_plate
- model

### 5.6 pickSelect — السطر 992
عند اختيار المركبة:
- يتم وضع UUID في `wsTo`.
- يتم إظهار vehicle_code/license_plate/model.
- يتم اكتشاف driver من `vehicle.driver_id`.
- يتم ربط rep بالمركبة.
- يتم التحقق من source branch / rep contract.

### 5.7 routeHtml — السطر 1149
DirectSale يعرض:
- الفرع المصدر
- مندوب البيع المباشر
- المركبة — مرتبطة بالمندوب

الـSmart Menu معرف داخل نفس component IDs الصحيحة.

### 5.8 renderWorkspace — السطر ~1168
الإصلاح السابق الموجود بالفعل:
`<div class="mt-3">'+s.routeHtml()+'</div>`

موجود قبل:
`<div id="wsTopPanel" class="ws-top-panel ...">`

وليس داخله.

---

## 6. السبب الجذري للعطل الذي تم الإبلاغ عنه

### السبب التاريخي المثبت
كانت القائمة الخاصة بالمركبة تُبنى فعليًا، لكن:
`s.routeHtml()`
كانت داخل:
`wsTopPanel`

والـCSS الخاص به:
`overflow:hidden`

وبالتالي كانت Smart Menu تُنشأ، لكنها تُقص بصريًا داخل الحاوية.

إذن:
**العطل لم يكن Vehicle DB connection.**
**العطل لم يكن RLS.**
**العطل لم يكن Query.**
**العطل لم يكن Rep binding.**
**العطل كان UI clipping.**

### الإصلاح الجراحي السابق
Commit:
`745a615ccd0baff09ad2619b0316e46507a862e9`

التغيير الوحيد:
- إخراج `s.routeHtml()` من `wsTopPanel`.
- الإبقاء على كل IDs والدوال والـRPC contract كما هي.

هذا الإصلاح موجود الآن في CURRENT SOURCE.

---

## 7. تعليمات التعديل الجراحي لمالك الملف

### الملف
`companies/company-1/warehouse/vouchers.html`

### الحالة الحالية
SHA:
`d02d3696d9ca1af8014fbb61c680c04c09c39b7e`

### القرار
**لا تطبق أي تعديل جديد على الملف إذا كان عندك هذا الـSHA أو أي نسخة تحتوي الإصلاح أدناه.**

### patch التاريخي المغلق — للمطابقة فقط

ابحث داخل:
`renderWorkspace:function()`

عن العنصر القديم المحدد حرفيًا:
`'<div>'+s.routeHtml()+'</div>'+`

واحذفه.

البديل الكامل الذي أُدخل بالفعل:
`'<div class="mt-3">'+s.routeHtml()+'</div>'+`

ويجب أن يكون مباشرة قبل:
`'<div id="wsTopPanel" class="ws-top-panel mt-3'+(topCollapsed?' ws-top-collapsed':'')+'">'+`

### تحذير
هذا Patch مغلق بالفعل.
إعادة تطبيقه على CURRENT SOURCE = إعادة إصلاح غير مطلوب + Regression Risk.

---

## 8. CURRENT DATABASE / RPC

Production الحالية تحتوي على overloads من:
`create_manual_stock_voucher_atomic`

لكن DirectSale الحالي يستخدم بشكل صريح الـ12-argument signature:
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

والـ12-arg wrapper:
- يتحقق من المستخدم داخل الشركة.
- يتحقق من DirectSales Rep.
- يتحقق من role.
- يتحقق من van-sales.
- يحل Vehicle بالـUUID داخل نفس company.
- يتحقق من active + mobile stock.
- يتحقق من driver_id = rep.
- يتحقق من mobile branch.
- يسجل operation identity.
- يمرر الإدخال إلى core canonical.

لا توجد حاجة إلى Vehicle RPC جديدة.

---

## 9. CURRENT EDGE FUNCTIONS

الحالة Production:
- setup-van-branch = v4
- create-stock-voucher = v10
- send-stock-voucher = v20
- receive-stock-voucher = v22
- complete-stock-voucher = v4
- cancel-stock-voucher = v4

كل هذه الحالية:
- ACTIVE
- verify_jwt = true

قرار:
**لم يتم إنشاء Edge Function جديدة.**

سبب القرار:
القدرة المطلوبة موجودة بالفعل في Current Edge + RPC.

---

## 10. Van Sales Integration

تمت مراجعة:
`companies/company-1/sales/van-sales.html`

الدور الحالي:
- السيارة = Mobile Stock Location.
- `loadVanBranch` يحل mobile branch.
- vehicle_id / vehicle_code / driver_id محفوظة في سياق التطبيق.
- المبيعات الفعلية تستخدم `save-sales-invoice`.
- source = `van-sales`.
- العملية تحمل operation identity لإعادة المحاولة.
- البيع الفعلي يخصم من مخزون السيارة، وليس من المخزن الرئيسي.

التكامل:
DirectSale Voucher
→ Branch Stock ↓
→ Vehicle Mobile Stock ↑
→ Van Sales
→ Customer Sale
→ Vehicle Mobile Stock ↓
→ Daily Settlement

هذا يطابق فلسفة المستند التاريخية:
DirectSale = تحميل عهدة مبيعات متنقلة، وليس Customer Sale.

لا يوجد Defect Production مثبت في Van Sales يستدعي تعديل الملف.

---

## 11. لماذا الأذونات موجودة كتطبيق مستقل؟

السجل المعماري التاريخي:
`rawaie-erp-review/Architecture/الأذونات المخزنية اليدوية.md`

العقد:
الأذونات اليدوية تغطي الحركات التي لا تبدأ من Order/Runsheet:
- Transfer
- DirectSale
- DirectReturn
- SupplierReturn
- Scrap
- Adjustment

DirectSale:
- Branch → Vehicle
- لا يوجد Order عميل عند الإنشاء.
- لاحقًا Van Sales تستخدم عهدة السيارة في البيع.

DirectReturn:
- Vehicle → Branch
- يستخدم لتفريغ المتبقي/المرتجع من عهدة السيارة.

Transfer:
- Branch → Branch
- نقل أصل تشغيلي داخلي بلا Customer Order.

إذن التطبيق ليس جزيرة منفصلة وظيفيًا؛ هو Transaction Document Layer فوق نفس Physical Stock Core.

---

## 12. التكامل مع النظام الأم

النظام الأم مسؤول عن:
- فتح الوحدة.
- الصلاحيات.
- التحكم في التنقل.
- إدارة الإدارات والتطبيقات المنفصلة.

التطبيق المستقل مسؤول عن:
- تنفيذ Transaction Voucher.
- Product/Stock selection.
- Branch/Vehicle/Rep/Supplier context.
- lifecycle state.
- dispatch إلى Edge/RPC.

العقد المعماري:
Mother = Control Plane
Standalone Apps = Execution Surfaces
Supabase Core = Transaction/Truth Layer

لا يلزم إدخال منطق المركبات داخل main.html.

---

## 13. مقارنة تنافسية

### Odoo
Odoo يدعم:
- physical inventory
- barcode counting
- assigning counts to users
- scheduled counts
- optional visibility of expected quantity
- product/location/quantity handling

المراجع:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/barcode/operations/adjustments.html
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/inventory_management/count_products.html

### Dynamics 365
يوفر Inventory Journals تشمل:
- Movement
- Inventory Adjustment
- Transfer
- Counting
- Tag Counting

ويسمح بالتحديث الفيزيائي والمالي مع posting وفق journal contract.

المراجع:
https://learn.microsoft.com/en-us/dynamics365/finance/general-ledger/inventory-posting
https://learn.microsoft.com/en-us/dynamics365/business-central/inventory-how-count-adjust-reclassify

### SAP S/4HANA
Goods Movement يغطي:
- Goods Receipt
- Goods Issue
- Physical Stock Transfer
- Transfer Posting
- material history/reporting

المرجع:
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/91b21005dded4984bcccf4a69ae1300c/742e46e570984d9aa74e468838f6e1ff.html

### Daftra
التحويلات المخزنية تشمل:
- Date
- From Warehouse
- To Warehouse
- Notes
- Quantity
- Available Before
- Available After

والتقارير تعرض:
- Time
- Type
- Product
- Inward/Outward
- Warehouse
- Notes
مع filtering/export في التقارير التفصيلية.

المراجع:
https://docs.daftra.com/en/tutorial/transferring-stock/
https://docs.daftra.com/en/tutorial/inventory-detailed-transactions-report/
https://docs.daftra.com/en/user_manual/transferring-items-from-one-warehouse-to-another/

### Manager.io
Inventory Transfers تدعم:
- Date
- Reference
- Description
- Item
- Qty
- From
- To

وInventory Locations تفصل المخزون حسب الموقع.

المراجع:
https://www2.manager.io/guides/10707
https://www2.manager.io/guides/10677

---

## 14. الفجوات التنافسية الحقيقية — لا تُدمج داخل هذا الإصلاح

ظهرت في المقارنة، لكنها Business Contracts مستقلة:
1. editable voucher date/time
2. lot / serial / expiry traceability
3. formal approvals
4. evidence/attachments
5. richer discrepancy taxonomy
6. in-transit stock
7. assigned counting sessions
8. before/after inventory snapshots كحقول reporting أولية
9. richer document/movement reporting

هذه لم تُحقن داخل Voucher الحالي لأن ذلك سيخلق:
- Schema consequences
- Accounting consequences
- Reporting consequences
- Lifecycle consequences
- Cross-module contracts

---

## 15. E2E — Frontend Automated Evidence

Workflow:
`.github/workflows/warehouse_vouchers_browser_e2e_20260920.yml`

آخر run على HEAD الحالي:
`35691952367`

النتيجة:
**FAIL في Browser Smoke**

لكن:
**VOUCHERS_SOURCE_GATES = PASS**

سبب الفشل المثبت:
`page.title: Execution context was destroyed, most likely because of a navigation`

التحقيق أثبت أن:
`companies/company-1/sw.js`
في `activate` يقوم:
- clients.claim()
- matchAll()
- client.navigate(client.url)

وهذا يمكنه إعادة تحميل نافذة Playwright أثناء الاختبار.

إذن فشل Browser Smoke الحالي:
**ليس إثباتًا أن Vehicle Picker مكسور.**
إنه فشل Browser Harness بسبب navigation من Service Worker.

لا يجوز تعديل `vouchers.html` لعلاج هذا الاختبار.

---

## 16. Production Functional E2E — DirectSale

تم تنفيذ Transaction على Production باستخدام البيانات الحقيقية:
- company = current company
- source = BR-01
- vehicle = VEH-TEST-260921
- rep = vansales@rawaea.com
- item = 1001
- qty = 1

### CREATE
النتيجة:
- voucher_code = IN-2
- type = DirectSale
- status = Draft
- to_id = Vehicle UUID الحقيقي
- operation_id = `FORENSIC-SEND-2026-09-22`

### SEND
النتيجة:
- status = Sent
- movement_type = DirectSale
- qty = 1
- voucher_id = IN-2
- item_id = 1001

هذا يثبت أن:
Voucher Create
→ Vehicle UUID
→ Rep Contract
→ Send
→ post_stock_movement
→ inventory_log

كلها متصلة فعليًا.

### Rollback verification
بعد rollback:
- vouchers matching test reference = 0
- operations matching test operation_id = 0
- logs matching test reference = 0

ولا يوجد Production residue.

---

## 17. Production Candidate Test للـVehicle Picker

تمت مطابقة predicate الحالي مباشرة مع Production:
النتيجة:
`matching_vehicle_picker_candidates = 1`

أي أن المركبة الحالية تمر بكل شروط DirectSale Picker عندما يكون:
`wsFrom = BR-01`

---

## 18. نقطة مهمة في UX وليست Defect

الـDirectSale picker الحالي يتطلب أن يكون:
`wsFrom`
محددًا أولًا.

عند عدم وجود مصدر branch:
- `b` = null
- شرط:
  `!!b`
  يمنع إظهار المركبات.

هذا **سلوك مقصود ضمن Branch/Vehicle contract الحالي** وليس نقصًا مثبتًا.

لا أوصي بإظهار مركبات من كل الفروع قبل اختيار المصدر، لأن ذلك يضعف:
- Branch isolation
- Rep binding
- Vehicle responsibility
- operational clarity

ولا يوجد دليل تاريخي يثبت أن التصميم المقصود كان العكس.

---

## 19. Production Data State بعد كل اختبارات الجلسة

Fresh snapshot:
`2026-09-22 06:35:45.778287+00`

ما زال:
- companies = 1
- branches = 3
- items = 17
- vehicles = 1
- active vehicles = 1
- stock_vouchers = 1
- stock_voucher_details = 3
- stock_voucher_operations = 1
- inventory_log = 6
- audit_log = 2034

Persistent voucher:
- IN-1
- DirectSale
- Cancelled
- BR-01 → VEH-TEST-260921
- reference = DEMO-DIRECT-SALE-2026-09-21

لم يتم تعديل هذا السجل في هذه الجلسة.

---

## 20. ما تم فعله فعليًا في Production هذه الجلسة

لا يوجد DDL جديد مطلوب بسبب Vehicle Picker.
لا يوجد Data Repair مطلوب.
لا يوجد Edge Function جديد.
لا يوجد Vehicle RPC جديد.
لا يوجد تعديل في main.html.
لا يوجد تعديل في vouchers.html.
لا يوجد تعديل في van-sales.html.

تم فقط تنفيذ:
- قراءة Production.
- تحقق RLS/Company/Vehicle/Rep.
- تحقق current RPC/Edge.
- Transactional DirectSale CREATE/SEND.
- Rollback.
- post-rollback residue verification.

---

## 21. قرار الإغلاق

### CLOSED
- Vehicle table exists and is populated.
- Vehicle company scope.
- Vehicle Active state.
- Mobile Stock.
- Mobile Branch.
- Driver ↔ Direct Sales Rep.
- Vehicle search fields.
- Vehicle picker predicate.
- Vehicle UUID selection.
- Voucher → Vehicle integration.
- Voucher → Van Sales integration.
- DirectSale Production CREATE.
- DirectSale Production SEND.
- Physical stock centralization.
- Historical clipping defect.
- Historical clipping surgical fix.
- No production residue after QA transactions.

### OPEN
- Published Cloudflare artifact identity.
- Authenticated browser E2E against the actually published artifact.

لا يجوز تحويل هاتين النقطتين إلى CLOSED دون deployment evidence مباشر.

---

# 22. السبب النهائي للعطل

## السبب الذي أصلح فعليًا
**UI clipping داخل `wsTopPanel` بسبب `overflow:hidden` بينما `s.routeHtml()` كان داخله.**

## الحالة الحالية
الإصلاح موجود بالفعل في:
Frontend HEAD `745a615ccd0baff09ad2619b0316e46507a862e9`

Current voucher SHA:
`d02d3696d9ca1af8014fbb61c680c04c09c39b7e`

## إذا كانت المركبات ما زالت لا تظهر في المتصفح بعد نشر HEAD الحالي
لا تعيد تعديل:
- `loadRefs`
- `vehicleBranch`
- `pickArr`
- `pickSearch`
- `pickSelect`
- `routeHtml`

ابدأ مباشرة من:
**Published Runtime / Deployment Artifact Verification**

ولا تصنّف السبب على أنه database/vehicle query defect بدون دليل.

---

# 23. SELF-AUDIT

### Confirmed Facts
- CURRENT GIT verified.
- Parent commits verified.
- CURRENT vouchers source verified.
- CURRENT van-sales source verified.
- Production vehicle verified.
- Production rep verified.
- Production branch verified.
- Vehicle picker candidate = 1.
- Current DirectSale RPC verified.
- Current Edge verified.
- Production CREATE/SEND transactional test passed.
- Rollback residue = 0.
- Historical clipping fix exists.

### Unknowns
- Published Cloudflare artifact SHA.

### Conflicts
- Older reports contain older HEAD/parent values.
- They are superseded by CURRENT GIT.
- Some older narrative text describes IN-1 as Draft; current Production proves it is Cancelled.

### Unverified Claims
- Live browser against published Cloudflare artifact.

### What was not changed
- main.html
- vouchers.html
- van-sales.html
- Vehicle schema
- Vehicle rows
- no new Edge Function

### Final Closure Status
**VOUCHER VEHICLE / DATABASE / RPC / VAN SALES CONTRACT = CLOSED**

**HISTORICAL UI ROOT CAUSE = CLOSED**

**SOURCE PATCH = ALREADY PRESENT — DO NOT REAPPLY**

**PRODUCTION FUNCTIONAL DIRECTSALE = CLOSED**

**PUBLISHED BROWSER RUNTIME = OPEN / DEPLOYMENT EVIDENCE REQUIRED**

---

# 24. إرشاد المساعد التالي

1. اقرأ هذا التقرير ثم CURRENT_STATE، ولا تعتمد على أرقام أقدم منه.
2. تحقق من:
   - System HEAD `0559ae76896c605fa17cf05b49b6fd9e389ffbbf`
   - Frontend HEAD `745a615ccd0baff09ad2619b0316e46507a862e9`
   - Voucher SHA `d02d3696d9ca1af8014fbb61c680c04c09c39b7e`
3. لا تعيد Voucher Vehicle Patch.
4. لا تعدل main.html.
5. لا تعدل van-sales.html.
6. افتح Published Cloudflare Artifact فعلًا.
7. طابق artifact مع current frontend HEAD.
8. نفذ browser authenticated E2E على:
   BR-01 → VEH-TEST-260921 → vansales@rawaea.com.
9. إذا اختلف artifact عن HEAD:
   أغلق Deployment Drift فقط.
10. إذا تطابق:
   انتقل إلى Browser Runtime investigation.
11. لا تدخل أي Business Contract جديد داخل Voucher قبل مراجعة مستقلة.

---

# نهاية تقرير 299
