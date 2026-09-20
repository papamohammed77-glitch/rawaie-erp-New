# تقرير 266 — تحقيق جنائي وإغلاق جراحي لتبويب إدارة الأسطول والحركة
## RAWAEA ERP — Fleet Management / Capacity / Driver Contract / Runsheet Assignment
### التاريخ: 2026-09-20

## 1. نطاق الجلسة

النطاق محصور في:
- إدارة الأسطول والحركة Fleet Management.
- المركبات.
- السائقون.
- مستندات ورخص السائقين.
- التخطيط على أساس سعة المركبة.
- إسناد المركبة والسائق إلى الرانشيت.
- التكامل مع الرانشيت والتطبيقات التشغيلية دون إعادة بناء محركات العمليات الميدانية.
- Production Supabase + Current Git + Mother source + Deployment evidence.
- لم يتم تعديل Mother `main.html`.

لا تشمل الجلسة أي إصلاح مستقل في المخزون أو الحسابات أو المبيعات أو Picker إلا فيما يثبت أنه dependency مباشر لـFleet.

---

## 2. قاعدة التحقيق الحاكمة

تم اتباع التسلسل المعتمد:
UNDERSTAND
→ HISTORICAL CONTRACT
→ CURRENT GIT
→ CURRENT SOURCE
→ CURRENT PRODUCTION
→ CURRENT DATABASE
→ CURRENT DEPLOYMENT
→ ACTUAL GAP
→ SURGICAL FIX
→ TEST
→ PRODUCTION VERIFY
→ DOCUMENT
→ NEXT STATE

التقارير السابقة استُخدمت كأدلة تاريخية فقط، ولم تُعامل كـCurrent Truth.

المصدر الحاكم للمراجعة:
- `doc/Draft/Reprots/MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`
- `doc/Draft/Reprots/Report265...`
- `CURRENT_STATE.md`
- Current Git
- Production Supabase
- Current deployment evidence

---

## 3. Current Git / Parent قبل الإغلاق

آخر سلسلة قبل هذه الجلسة كانت:
- `0c394aad478a626d16b417666144637e2e83a897`
- Parent: `1c8f97929cb82ca42165c728521ed7bde8c4f9c2`

ثم نفذت هذه التغييرات في repository:
- `99e1977a8d87eed0baea13037975e21732b1d9f5`
- `a0f7737d3f37f4e51f243fc1022471841dc75fcf`
- `cd0859c52de3e6bbc72d6923db4143478d4fc8c8`
- `06878170a9025a203034364fde809b7172770044`
- `463a5821420a0831397d07c4929f75a52192fbd9`
- `0dbd47911b0ec75d788f1a355b45248cb9f23b77`

آخر commit للمهمة قبل التقرير:
`0dbd47911b0ec75d788f1a355b45248cb9f23b77`

---

## 4. Mother checkpoint

Current Mother:
- Repository: `papamohammed77-glitch/erp-frontend`
- HEAD: `ddcd9995240605dd9bcf31ab1abb1a774b887f84`
- Parent: `1823f9ab0e6f88c0118585c0b4f50a0b9b36bc38`
- main.html blob: `6074a4fc5f915701b23af5d7b6fca8a083c0a9dd`

حد الملكية:
- لم يتم تعديل `main.html`.
- التعديل الموجود في repository هو owner-ready surgical module فقط.

---

## 5. Production snapshot النهائي

Snapshot UTC:
`2026-09-20 07:23:32+00`

Current counts:
- companies = 1
- branches = 2
- items = 17
- vehicles = 0
- fleet_drivers = 0
- fleet_vehicle_assignments = 0
- vehicle_tracking = 0
- fleet_fuel_transactions = 0
- vehicle_maintenance = 0
- fleet_maintenance_plans = 0
- fleet_incidents = 0
- fleet_driver_performance_events = 0
- fleet_expenses = 0
- runsheets = 0
- run_sheet_details = 0

سبب الصفر ليس فقدان وظيفة؛ Production الحالية لا تحتوي سجلات تشغيل Fleet فعلية. لذلك كل E2E التشغيلي تم داخل Transaction مؤقتة ثم ROLLBACK.

---

## 6. ما الذي كان موجودًا أصلًا

Production كانت تحتوي بالفعل على:
- `vehicles.max_weight_kg`
- `vehicles.max_volume_m3`
- `vehicles.ownership_type`
- `vehicles.expected_km_per_liter`
- `fleet_drivers.employment_type`
- `fleet_driver_documents` مع `license_class`, `document_number`, `issue_date`, `expiry_date`
- `fleet_vehicle_assignments`
- `runsheets.vehicle_id`
- `runsheets.driver_id`
- `fleet_command_atomic`
- `fleet_query`
- `manage_runsheet_atomic`

لذلك لم تتم إعادة بناء هذه المكونات.

---

## 7. الفجوات الفعلية التي أثبتها التحقيق

### 7.1 المركبة
السعة الوزنية كانت موجودة ولكن لا يوجد contract واضح لواجهة الإدخال بالطن، ولا يوجد تخزين فعلي لأبعاد صندوق المركبة.

الفجوة أغلقت بإضافة:
- `cargo_length_m`
- `cargo_width_m`
- `cargo_height_m`

مع اشتقاق:
`max_volume_m3 = length × width × height`

### 7.2 حالة المركبة
لم يكن هناك Contract موحد لاستخدام الحالة التشغيلية في قرار التخطيط.

أضيف:
- `operational_condition`
- القيم:
  - Excellent
  - Good
  - Fair
  - Poor

### 7.3 قدرة المسار
لم يكن هناك Contract واضح يميز المركبة محليًا/إقليميًا/بعيدًا.

أضيف:
- `route_capability`
- القيم:
  - LocalOnly
  - Regional
  - LongHaul
  - Any

### 7.4 الملكية
تم تثبيت:
- Owned
- RentedPerTrip
- RentedMonthly
- Other

### 7.5 السائق
كان `employment_type` محكومًا بقيد قديم لا يسمح بـPerTrip/Monthly.

Production constraint كانت تسمح فقط بمجموعة أقدم.
تم استبدالها بمجموعة متوافقة:
- Employee
- Contractor
- Outsourced
- RentalDriver
- PerTrip
- Monthly
- Other

### 7.6 الرخصة
الـschema كان يملك مستندات السائق، لكن Modal إنشاء السائق لم يكن يربط Contract الرخصة مع الإنشاء.

أصبح DRIVER_CREATE يقبل:
- Private
- ProfessionalFirst
- ProfessionalSecond
- ProfessionalThird

ويقوم بإنشاء DriverLicense document عند وجود بيانات الرخصة.

### 7.7 المشكلة المعمارية الأهم
السعة كانت موجودة كـMaster Data لكن لم تدخل في قرار إسناد الرانشيت.

`manage_runsheet_atomic` كان يقوم بدور الربط، وليس Planning Gate.

تم إنشاء Contract مركزي داخل:
`fleet_command_atomic`
بالأمر:
`RUNSHEET_ASSIGN`

هذا الأمر:
1. يتحقق من Tenant.
2. يتحقق من الرانشيت.
3. يتحقق من المركبة.
4. يتحقق من حالة المركبة.
5. يتحقق من السائق.
6. يحسب الوزن من `run_sheet_details × items.weight_kg`.
7. يحسب الحجم من `run_sheet_details × items.volume_m3`.
8. يمنع تجاوز الوزن.
9. يمنع تجاوز الحجم.
10. ثم يفوض عملية الربط الفعلية إلى `manage_runsheet_atomic`.

وبذلك لا يوجد Runsheet Engine جديد.

---

## 8. Item Master integrity

تم استخدام:
- `items.id`
- `items.item_code`
- `items.weight_kg`
- `items.volume_m3`

ولم يتم اختراع أوزان أو أحجام مفقودة.

عند وجود بيانات ناقصة:
`fleet_query(vehicle_planning)`
يعرض:
`INCOMPLETE_DATA`

بدل إعطاء نسبة زائفة.

هذا متوافق مع نمط Dynamics الذي يحذر من نقص بيانات الوزن/الحجم عند التخطيط، ومع Odoo الذي لا يستطيع تقييم سعة المركبة دون وجود وزن وحجم للمنتج.

---

## 9. Planning Read Model

أضيف إلى:
`fleet_query`

View:
`vehicle_planning`

ويعيد:
- load weight
- load volume
- missing weight item count
- missing volume item count
- vehicle max weight
- vehicle max volume
- weight utilization %
- volume utilization %
- remaining weight
- remaining volume
- planning status
- condition warning
- route capability
- ownership
- dimensions
- fuel efficiency

Planning Status:
- READY
- INCOMPLETE_DATA
- BLOCKED

---

## 10. Driver License Guard

تمت إضافة حارس داخل:
`fleet_command_atomic → RUNSHEET_ASSIGN`

السلوك:
- رخصة منتهية = رفض الإسناد.
- رخصة غير مكتملة = تحذير.
- لا يتم تجاوز الحماية.
- لا يوجد استدعاء Edge جديد.

---

## 11. Production migrations التي تم تنفيذها

### Migration 1
`20260920071603_fleet_capacity_route_driver_contract_closure_20260920_v2`

أضاف:
- cargo dimensions
- operational condition
- route capability
- ownership constraints
- capacity validation
- Fleet command changes
- vehicle planning read model
- runsheet assignment gate
- manage_runsheet capacity protection

### Migration 2
`20260920071702_fleet_driver_employment_contract_options_20260920`

أصلح:
`fleet_drivers_employment_check`

ليدعم:
Employee / PerTrip / Monthly / Contractor / Outsourced / RentalDriver / Other

### Migration 3
`fleet_driver_license_assignment_guard_20260920`

أضاف:
- expired license hard stop
- incomplete license warning

---

## 12. Edge Functions

لم يتم إنشاء Edge Function جديدة.

لم يتم رفع Gateway load.

التنفيذ الجديد يستخدم:
- `fleet_command_atomic`
- `fleet_query`

وهذا يلتزم بقيد المشروع الحالي على عدد Edge Functions.

---

## 13. Frontend surgical module

الملف canonical:
`Current/PWA/owner-patches/RW_FleetManagement.js`

تم تحديث:
- `selectInput()`
- `openVehicleForm()`
- `openDriverForm()`
- `loadVehicles()`
- `loadTrips()`
- `openRunsheetAssignmentForm()`
- API export

ولا توجد كتابة مباشرة من Browser إلى Fleet tables.

---

## 14. التعديل الجراحي للمالك — main.html

لم يتم تعديل Mother.

### ابحث عن:
`// RW_Views – نظام التوجيه النهائي`

### ثم:
احذف كتلة Fleet IIFE/module الحالية الموجودة مباشرة قبل هذا marker.

### واستبدلها بالكامل بـ:
المحتوى الكامل الحالي للملف:

`Current/PWA/owner-patches/RW_FleetManagement.js`

لا تعدل:
- Fleet router
- permissions
- أي operational PWA
- inventory core
- post_stock_movement
- manage_runsheet_atomic signature
- أي كود غير متعلق بـFleet.

هذا يحافظ على الإصلاح السابق الخاص بـIIFE return contract، ويضيف عليه التطوير الجديد بدون إعادة البناء من الصفر.

---

## 15. تغييرات الواجهة المطلوبة فعليًا

### Vehicle Modal
يجب أن يظهر:
- السعة بالطن
- طول صندوق المركبة
- عرض صندوق المركبة
- ارتفاع صندوق المركبة
- حجم الصندوق المحسوب
- حالة وكفاءة المركبة
- قدرة المسار
- نوع الملكية
- الكفاءة كم/لتر
- البيانات الأساسية السابقة

### Driver Modal
يجب أن يظهر:
- نوع الرخصة
- رقم الرخصة
- تاريخ الإصدار
- تاريخ الانتهاء
- نوع التعاقد
- تاريخ بدء التعاقد
- البيانات الأساسية السابقة

---

## 16. Integration workflow

### Vehicle
Mother Fleet UI
→ `fleet_command_atomic`
→ `VEHICLE_CREATE / UPDATE`
→ `vehicles`

### Driver
Mother Fleet UI
→ `fleet_command_atomic`
→ `DRIVER_CREATE / UPDATE`
→ `fleet_drivers`
→ `fleet_driver_documents`

### Planning
Runsheet
→ `run_sheet_details`
→ `items.weight_kg / volume_m3`
→ `fleet_query(vehicle_planning)`
→ candidate vehicles

### Assignment
Fleet UI
→ `fleet_command_atomic(RUNSHEET_ASSIGN)`
→ weight/volume/license/tenant guards
→ `manage_runsheet_atomic`
→ `runsheets.vehicle_id + runsheets.driver_id`

### Physical operations
لا تغيير:
- Picking
- Reservation
- Loading
- Delivery
- Return
- Unloading
- Settlement

هذه لا تزال تحت operational spine الموجود مسبقًا.

---

## 17. E2E — Negative

اختبار مؤقت:
- Vehicle capacity = 1000 kg
- Runsheet load = 2000 kg

النتيجة:
`RUNSHEET_ASSIGN` رفض العملية:
`السعة الوزنية للمركبة غير كافية`

الـtransaction أُجهضت.

لا يوجد أثر دائم.

---

## 18. E2E — Positive

اختبار مؤقت:
- Vehicle = 5000 kg
- Cargo = 2 × 2 × 2 m
- Derived volume = 8 m³
- Ownership = RentedMonthly
- Condition = Excellent
- Route = LongHaul
- Driver employment = PerTrip
- License = ProfessionalFirst
- License expiry = 2030-01-01
- Runsheet item = ITM-1057
- quantity = 10

النتيجة:
- إنشاء المركبة = PASS
- حساب حجم الصندوق = PASS
- إنشاء السائق = PASS
- إنشاء DriverLicense = PASS
- Planning query = PASS
- RUNSHEET_ASSIGN = PASS
- runsheets.vehicle_id = correct vehicle
- runsheets.driver_id = existing operational driver user
- rollback = PASS

لا يوجد أثر دائم بعد الاختبار.

---

## 19. E2E integration finding

تم اختبار حالتين:
1. Fleet Driver بلا `user_id`:
   - يمكن حفظ ملف Fleet Driver.
   - لا يمكنه تلقائيًا أن يصبح `runsheets.driver_id` لأن الحقل التشغيلي هو user identity.
2. Fleet Driver مرتبط بـoperational user:
   - يمكن الإسناد الصحيح.
   - `runsheets.driver_id` أصبح هو user ID التشغيلي الصحيح.

هذه ليست مشكلة Capacity.
إنها حد هوية تكامل يجب الحفاظ عليه.

---

## 20. Competitive contract review

### Odoo
Odoo 19 يربط Fleet بالسعة ويستخدم Max Weight وMax Volume، ولا يستطيع Dispatch تقييم سعة المركبة إذا لم تتوفر أوزان وأحجام للمنتجات. هذا يطابق ما تم بناؤه هنا:
- vehicle capacity
- product weight/volume
- load capacity gate

Official:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/shipping_receiving/setup_configuration/dispatch.html
https://www.odoo.com/documentation/19.0/applications/hr/fleet/models.html

### Microsoft Dynamics 365
Dynamics 365 Transportation Management يستخدم Load Templates بأبعاد وMax Weight وMax Volume، ويعرض utilization ويمنع تجاوز الحدود حسب إعدادات التحميل. كما أن Load Planning يستخدم load-building strategies. هذا يدعم الاتجاه المعماري الذي تم اعتماده في Fleet.

Official:
https://learn.microsoft.com/en-us/dynamics365/supply-chain/transportation/include-container-weight-volume-on-load
https://learn.microsoft.com/en-us/dynamics365/supply-chain/transportation/tasks/load-template
https://learn.microsoft.com/en-us/dynamics365/supply-chain/transportation/tasks/load-building-workbench

### SAP Transportation Management
SAP يعرّف Vehicle Resource ككائن يربط المركبة بالسعة والتوافر، ويدعم Weight/Volume وأبعاد متعددة وAvailability وPhysical Properties. كما يربط التخطيط بالـresource capacity.

Official:
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/e3dc5400c1cc41d1bc0ae0e7fd9aa5a2/bad5555bf8d042069b1ed7927e6e59e7.html

### Daftra
المراجعات التاريخية السابقة للمشروع سجلت وجود نموذج إدارة نقل/رحلات يتابع المركبة والرحلة والمصروف والصيانة والنتيجة المالية.

### Manager.io
النظام يقدم Fixed Asset handling للمركبات والإهلاك، وهو مستوى تكاملي لم يتم خلطه مع Fleet التشغيل في هذه الجلسة.

---

## 21. ما لم يتم بناؤه عمدًا

هذه النقاط لم تُخترع:
- Telematics / GPS ingestion
- scheduled notifications
- Fixed Asset vehicle lifecycle
- Maintenance Plan → Work Order lifecycle
- Work Order → spare parts → stock movement
- true On-Time Delivery KPI
- route engine حقيقي
- multi-stop optimization
- compartment planning
- time-slot vehicle availability
- real-time GPS utilization

سبب عدم بنائها:
لا يوجد Contract Production مثبت لهذه الأشياء ضمن Fleet الحالي، وبناؤها الآن سيكون تخمينًا وتوسعًا خارج Closure Unit.

---

## 22. نقطة البيانات المفتوحة

الـ17 Item الموجودة في Production لا تكفي بيانات الوزن/الحجم لجميع الأصناف.

القاعدة الجديدة لا تملأ هذه القيم تلقائيًا.

بدلًا من ذلك:
- item data ناقص = INCOMPLETE_DATA
- لا يتم تحويل النقص إلى نسبة نجاح زائفة
- لا يتم اختلاق أوزان أو أحجام

العمل التالي الصحيح هو Item Master data-quality closure عندما تصل هذه الوحدة حسب roadmap، وليس داخل Fleet blind repair.

---

## 23. حالة Browser

### Closed
- Production schema = CLOSED
- Vehicle data contract = CLOSED
- Driver employment contract = CLOSED
- Driver license storage = CLOSED
- Capacity planning backend = CLOSED
- Capacity assignment gate = CLOSED
- Tenant validation = CLOSED
- No new Edge Function = CLOSED
- Git canonical module = CLOSED
- Surgical patch documentation = CLOSED

### Open
- Mother owner cutover
- Browser Production E2E
- visual confirmation of modals
- dashboard → vehicles → vehicle detail → drivers → alerts → trips → costs → performance in live browser

لا يجوز اعتبار Browser PASS قبل تطبيق module على Mother وتشغيل الاختبار الفعلي.

---

## 24. Root cause النهائي

المشكلة لم تكن "حقول ناقصة فقط".

السبب الحقيقي كان طبقيًا:

1. بعض Master Data موجودة في DB ولكن غير ممثلة في UI.
2. بعض الحقول المطلوبة لم يكن لها schema contract.
3. Driver employment constraint كان أقدم من الـbusiness requirement.
4. Vehicle capacity كانت Master Data بدون Planning Gate.
5. Fleet لم يكن جزءًا حقيقيًا من قرار Runsheet assignment.
6. Driver Fleet identity وoperational User identity كان يمكن أن ينفصلا.
7. لذلك كانت الوظيفة موجودة شكليًا لكن Business Contract غير مكتمل.

الإصلاح نقل Fleet من:
Master Data screen
إلى:
Master Data + Planning Control + Assignment Guard

دون خلق operational engine موازي.

---

## 25. Self-Audit

### What I Proved
- Production schema الحالي.
- الحقول التي كانت موجودة فعلًا.
- الحقول التي كانت ناقصة.
- القيد التاريخي الذي منع PerTrip/Monthly.
- آلية Fleet command/query الحالية.
- الوزن والحجم يمكن حسابهما من run_sheet_details + item master.
- capacity gate يعمل.
- ownership/condition/route fields تعمل.
- license document ينشأ مع Driver create.
- driver contract يعمل.
- runsheet assignment يكتب إلى existing operational spine.
- لا يوجد Edge Function جديد.

### What I Did Not Prove
- browser visual E2E بعد owner cutover.
- live user interaction داخل Mother.
- GPS/telematics.
- real route optimization.
- fixed asset accounting lifecycle.
- maintenance work order integration.

### What I Fixed
- Vehicle cargo dimensions.
- Vehicle condition.
- Vehicle route capability.
- Ownership contract.
- Driver employment contract.
- License capture.
- Capacity planning.
- Assignment gate.
- Driver license expiry gate.
- Fleet owner surgical source.
- Migration evidence in Git.

### What I Initially Missed
- The historical employment constraint.
- Fleet Driver → operational User identity boundary.
- The fact that route capability metadata alone is not a full route-class contract.

### What Could Still Be Wrong
- Item master weight/volume completeness.
- Owner insertion into Mother may be incomplete or misplaced.
- Browser assembly could expose another Mother-level conflict not visible in source-only verification.

### Final Confidence
Backend / schema / RPC closure: HIGH and E2E verified.
Mother browser runtime: NOT CLOSED until owner cutover.

---

## 26. Session-next instructions

ابدأ دائمًا بهذا الترتيب:

1. Verify System HEAD + parent.
2. Verify Mother HEAD + parent + main.html blob.
3. Verify current `RW_FleetManagement.js`.
4. Verify Production Fleet schema and current counts.
5. Verify fleet_command_atomic and fleet_query signatures.
6. Confirm no new Edge Function was created.
7. Verify owner applied the complete Fleet module before `// RW_Views – نظام التوجيه النهائي`.
8. Run JS parse + Mother assembly guard.
9. Open Fleet in Production browser.
10. Execute:
   - dashboard
   - vehicles
   - vehicle detail
   - driver
   - driver detail
   - alerts
   - trips
   - costs
   - performance
11. Create/read test data only if an approved test tenant exists; otherwise use read-only browser smoke.
12. Verify no direct browser DML against Fleet tables.
13. Re-snapshot Production.
14. Only then open the next Fleet Business Contract.

Do not:
- rebuild Fleet.
- recreate fleet_command_atomic.
- recreate fleet_query.
- create another Edge Function.
- reopen the IIFE defect.
- modify main.html outside the exact owner surgery.
- invent missing item weights/volumes.
- start a new Fleet feature before Browser closure.

---

## 27. Final closure status

FLEET BUSINESS CONTRACT — CAPACITY / VEHICLE MASTER / DRIVER CONTRACT
= PRODUCTION CLOSED

FLEET RUNSHEET CAPACITY GATE
= PRODUCTION CLOSED

FLEET DRIVER LICENSE GUARD
= PRODUCTION CLOSED

FLEET UI SOURCE
= CANONICAL / OWNER READY

MOTHER BROWSER E2E
= OPEN

GLOBAL FLEET COMPLETION
= PARTIALLY CLOSED BY DESIGN
until Mother browser cutover is verified.

# END REPORT 266
