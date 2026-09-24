# Report337 — التحقيق الجنائي وإغلاق فجوة صلاحيات ربط المركبة بالعملية
## التاريخ
2026-09-24

## 1. الحالة التي استُؤنفت منها

هذه الجولة بدأت من آخر نقطة مثبتة في سلسلة Report334 → Report335 → Report336، ولم تُعد تنفيذ أي إصلاح ثبت إغلاقه.

قاعدة الحقيقة المستخدمة:
CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE

### System Git
- Repository: `papamohammed77-glitch/rawaie-erp-New`
- HEAD عند بداية الجولة: `4f649f2a324716d46dc874324fa032c28873e781`
- Parent: `a806fa54090336324018cf7cb691788cab81d01b`

### Mother Git
- Repository: `papamohammed77-glitch/erp-frontend`
- Current HEAD: `7ca0aa1324fe1d925a752f559e990e92e29a384b`
- Parent: `854bc0d05389131782529e1b68801e4d651286c8`
- Current `companies/company-1/main.html` blob: `95cf0d8dfcb87f78962ae89038f141bcdb2c29a6`
- `854bc0...` كان آخر commit فعلي قبل `7ca0...`، وغيّر بنية/تنسيق Main دون تغيير عقد الربط.
- لم يتم إجراء أي كتابة من المساعد على Mother `main.html`.

### Production
Supabase project:
`fiilmooggumokxanwiyx`

الـFleet Control Plane الحالي:
- `fleet_query`
- `fleet_command_atomic`
- command: `VEHICLE_OPERATION_BIND`

لا توجد Edge Function جديدة لهذه القدرة.

---

## 2. ما ثبت تاريخيًا وأُعيد التحقق منه

### Report334
أغلق عناصر الواجهة التالية فعليًا:
- إظهار reference في بطاقات العمليات.
- Branch selector للتحويلات.
- document/reference synchronization.
- DirectSale document/reference display.
- انتظار modal completion.
- operation binding controls.

### Report335
أثبت أن:
- `vehicle_operation_candidates` موجود.
- DirectSale وTransfer وRunsheet projections موجودة.
- Vehicle Details يعرض العمليات.
- BIND لا ينفذ حركة مخزون.
- BIND لا ينفذ قيدًا محاسبيًا.
- replay idempotency موجود.

### Report336
أغلق:
- DirectSale vehicle.driver_id coupling.
- DirectSale custodian persistence.
- legacy manual voucher update overload.
- Physical stock writer discovery.

### نتيجة إعادة الفحص
لم يوجد دليل متناقض يبرر إعادة أي من هذه الإصلاحات.

---

## 3. الهدف المحدد لهذه الجولة

المشكلة الحالية التي تم التحقيق فيها:

> مستخدم التشغيل/المخزن يستطيع تنفيذ العملية الميدانية أو إنشاء/معالجة الإذن، لكن تبويب إدارة الأسطول والحركة وتفاصيل المركبة كان يحجب عنه قدرة ربط المركبة بالمستند/العملية.

المطلوب التشغيلي المعتمد:
- في مرحلة تأسيس النظام لا نربط كل عملية بالسائق الثابت للمركبة.
- يمكن للمخزن اختيار المركبة.
- يمكنه اختيار مندوب البيع المباشر.
- يمكنه اختيار مستند DirectSale موجود.
- رقم المستند والمرجع يظهران من المصدر نفسه.
- الربط يُستخدم لاحقًا في تقارير المركبات والسائقين ومندوبي التوصيل ومندوبي البيع وحركة المخزن.
- Binding نفسه لا يغيّر المخزون ولا الحسابات.
- التنفيذ الفعلي لاحقًا هو الذي يغيّر Physical Stock / custody / financial ledgers وفق عقد العملية.

---

## 4. التحقيق في Mother main.html

تمت قراءة المصدر الحالي مباشرة.

### العيب الأول — Navigation

الموضع:
حوالي السطر 1535–1537.

العنصر الحالي:

```javascript
{ view: 'fleet-management', label: 'لوحة إدارة الأسطول', perm: ['fleet.read','fleet.manage','general_manager','warehouse_manager','delivery_supervisor','finance_manager'] },
```

هذا يمنع صلاحيات التشغيل الميداني مثل:
- warehouse
- warehouse_supervisor
- vouchers
- transfer
- direct-sale
- van-sales
- delivery

من الوصول إلى Fleet Management أصلاً.

### العيب الثاني — Fleet canRead

الموضع:
`RW_FleetManagement`
حوالي السطر 28840.

الحارس الحالي يستقبل Fleet readers التقليديين فقط، ولا يستوعب أدوار التشغيل المطلوبة في هذه المرحلة.

### العيب الثالث — زر الربط في Vehicle Detail

الموضع:
حوالي السطر 29082.

زر:
`ربط المركبة بالعملية`

موضوع داخل شرط:
`canManage()`

وهذا شرط إدارة Fleet Master Data، وليس شرط قدرة Operation Binding.

وبالتالي المستخدم الذي يجب أن يربط مستندًا تشغيليًا لا يرى الزر أصلًا.

### العيب الرابع — Guard داخل openVehicleOperationLinkForm

الموضع:
حوالي السطر 29185.

العنصر الحالي:

```javascript
if (!canManage()) throw new Error('ليس لديك صلاحية ربط العمليات بالمركبات');
```

هذا يعيد نفس الخلط بين:
Fleet Master Data Management
و
Operational Vehicle Binding.

### العيب الخامس — command()

الموضع:
حوالي السطر 28875.

العنصر الحالي يبدأ بـ:

```javascript
if (!canManage()) throw new Error('ليس لديك صلاحية تنفيذ عمليات Fleet');
```

وبالتالي حتى لو ظهر الزر وتم استدعاء الوظيفة، فإن مسار command() يمنع العملية قبل إرسالها إلى Control Plane.

---

## 5. التحقيق في Production

تم فحص:
- `fleet_query`
- `fleet_command_atomic`
- users
- roles
- permissions
- vehicles
- vehicle mobile branches
- stock
- audit trail
- operation registry.

### المستخدم التشغيلي المثبت

`warehouse.supervisor@rawaea.com`

- role = `مشرف مخازن`
- permissions تشمل:
  - warehouse_supervisor
  - vouchers
  - transfer
  - direct-sale
  - vehicle-count
  - reports

### مستخدم الأذونات

`vouchers@rawaea.com`

- role = `مخزني`
- permissions = [`warehouse`]
- active_warehouse_role = `أذونات`

### Direct Sales Representatives
- `vansales@rawaea.com`
- `van-sales2@rawaea.com`

### المركبات الحالية
- `CHV-2025-01`
- `FRD-2025-02 TEST`

والمركبتان النشطتان لهما Mobile Stock.

---

## 6. Root Cause

السبب الجذري لم يكن نقصًا في:
- Fleet Control Plane
- database relationship
- vehicle detail projection
- DirectSale identity
- stock movement engine
- document reference model.

السبب الحقيقي كان:

### Permission Model Drift

القدرة:
`VEHICLE_OPERATION_BIND`

تحتاج مستخدم تشغيل يستطيع:
1. قراءة candidate operations.
2. اختيار vehicle.
3. اختيار document.
4. اختيار operational representative.
5. تنفيذ binding.

لكن Mother وProduction كانا يعاملان هذه القدرة كأنها:
`Fleet Master Data Management`

وهذا غير صحيح معماريًا.

Fleet master management يخص:
- إنشاء/تعديل مركبة.
- Odometer.
- Fuel.
- Maintenance.
- Contracts.
- Documents.
- Incidents.
- Expenses.

بينما:
`VEHICLE_OPERATION_BIND`

يخص:
- إسناد عملية موجودة إلى مركبة.
- تثبيت العلاقة بين document وvehicle وoperator.
- بدون تنفيذ الحركة الفيزيائية نفسها.

هذا فصل مسؤوليات مطلوب، وليس توسيعًا عشوائيًا للصلاحيات.

---

## 7. العلاج Production الذي تم تنفيذه

تم استخدام الـRPCs الموجودة.

### Migration
`20260924164239_open_vehicle_operation_bind_for_operational_roles_20260924`

تم تعديل:
- `fleet_command_atomic`
- `fleet_query`

### Backend contract الجديد

الـspecial allowance ينطبق على:

```
VEHICLE_OPERATION_BIND
```

وليس على كل أوامر Fleet.

الأدوار/الصلاحيات التشغيلية المسموح لها في هذه القدرة شملت:
- warehouse
- warehouse_supervisor
- warehouse_manager
- vouchers
- transfer
- direct-sale
- van-sales
- delivery
- delivery_supervisor
- vehicle-count

والأدوار التشغيلية:
- مشرف مخازن
- مخزني
- مندوب بيع مباشر
- مندوب توصيل
- مشرف توصيل

### ما لم يتغير

أوامر Fleet الأخرى مازالت تحت الحارس القديم:
- Fleet manage
- General manager
- Warehouse manager
- Owner/Wildcard

إذن لم يتم تحويل مستخدم الأذونات إلى Fleet administrator.

---

## 8. لماذا تم اختيار نفس RPC وليس Edge Function جديدة

المشروع بلغ حد عدد Edge Functions / Spend Cap.

لذلك:
- لا Edge Function جديدة.
- لا gateway جديد.
- لا capability wrapper جديد.
- لا duplication.

تم نقل نقطة السماح إلى الـControl Plane الموجود أصلًا.

---

## 9. E2E — Warehouse Supervisor

تم الاختبار داخل Transaction مع rollback.

### الخطوات
```
CREATE DirectSale Draft
→ fleet_query(vehicle_operation_candidates)
→ VEHICLE_OPERATION_BIND
→ replay بنفس operation_id
→ vehicle_detail
→ rollback
```

### النتيجة

- Fleet candidate read = PASS
- CREATE = PASS
- BIND = PASS
- replay = `duplicate=true`
- bound vehicle persisted = PASS
- Direct Sales Rep persisted = PASS
- vehicle_detail projection = PASS
- Binding stock mutation = NONE
- Binding accounting mutation = NONE
- rollback = PASS

---

## 10. E2E — Vouchers User

المستخدم:

`vouchers@rawaea.com`

تم الاختبار بنفس control plane.

النتيجة:
- fleet_query = PASS
- VEHICLE_OPERATION_BIND = PASS
- voucher/vehicle/rep persistence = PASS
- rollback = PASS

وهذا يثبت أن عامل الأذونات نفسه لم يعد محجوبًا عن قدرة الربط.

---

## 11. E2E — DirectSale Full Execution

تم تنفيذ:

```
DirectSale Draft
→ bind vehicle
→ bind direct sales rep
→ SEND
```

النتيجة:

- bind = PASS
- send = PASS
- source stock delta = -1
- vehicle mobile branch stock delta = +1
- rollback = PASS

هذا يتطابق مع عقد الحركة الحالي:

```
Physical Stock
→ post_stock_movement
→ stock_branches + inventory_log
```

ولا يوجد Writer موازٍ.

---

## 12. التأثير المحاسبي

الربط وحده:

- journal_entries = no delta
- journal_lines = no delta
- driver_ledger = no delta عند BIND نفسه

أما SEND في DirectSale فهو تحميل عهدة مبيعات، وليس Customer Sale.

في اختبار DirectSale الكامل:
- driver/custody ledger = +1
- G/L journal entries = 0
- G/L journal lines = 0

وهذا يحافظ على التمييز بين:
1. تحميل العهدة.
2. بيع العميل.
3. التسوية اللاحقة.

---

## 13. سلامة بيانات Production

أثناء هذه الجولة ظهر أثر قديم لعمليات QA:

`stock_voucher_operations`
كان يحتوي 10 سجلات:
- operation_id = QA-*
- voucher_id = NULL

وكانت هناك سجلات audit مرتبطة بـQA test vouchers.

بعد التحقق من هويتها ومصدرها:
- ليست معاملات تشغيلية.
- ليست vouchers حقيقية.
- ليست inventory movements.

تم تنظيفها في Production عبر migration مقيّدة.

### Migration
`20260924164848_cleanup_qa_orphan_operation_identities_and_audit_20260924`

الحذف كان محصورًا في:
- company_id المحدد.
- voucher_id IS NULL.
- operation_id LIKE QA-%.
- السجلات القديمة قبل يوم التنفيذ.
- QA stock-voucher audit rows.

تم إعادة تفعيل Guard بعد الحذف.

### النتيجة

- QA operations = 0
- QA vouchers = 0
- QA inventory logs = 0
- QA registry = 0
- QA stock-voucher audit residue = 0

---

## 14. ملاحظة Governance مهمة

أثناء التحقق ظهرت في Production migrations:
`20260924164831_cleanup_orphaned_qa_stock_voucher_operation_artifacts_20260924`

لكن لم يوجد لها ملف مطابق في Git الحالي.

لم يتم اختراع محتواها أو إعادة بنائها من الظن.

تم فقط:
- توثيق الفجوة.
- الاحتفاظ بالمحتوى المؤكد من migration التي نفذناها نحن.
- عدم الادعاء بأن محتوى migration الأقدم معروف إذا لم يكن مستخرجًا من Source/Git.

هذه النقطة يجب أن تبقى في قائمة Governance Reconciliation إلى أن تُستخرج من المصدر الرسمي إن كان لها أثر مهم.

---

## 15. Static Verification للـMother Surgical Patch

تم أخذ نسخة كاملة من:
`companies/company-1/main.html`

وتم بناء Patch في الذاكرة فقط.

لم يتم commit أو write إلى Mother.

### التحقق

- original lines = 32,296
- patched in-memory lines = 32,333
- inline script blocks = 6
- JavaScript parse errors = 0
- `canBindVehicleOperation()` = 1
- special command case = 1
- link guards converted = 2
- no assistant write to Mother = TRUE

---

## 16. Mother Surgical Patch — المطلوب من المالك فقط

### PATCH-337-01 — Navigation

ابحث حرفيًا عن هذا السطر في:
`companies/company-1/main.html`

```javascript
{ view: 'fleet-management', label: 'لوحة إدارة الأسطول', perm: ['fleet.read','fleet.manage','general_manager','warehouse_manager','delivery_supervisor','finance_manager'] },
```

احذفه واستبدله بهذا السطر:

```javascript
{ view: 'fleet-management', label: 'لوحة إدارة الأسطول', perm: ['fleet.read','fleet.manage','general_manager','warehouse_manager','delivery_supervisor','finance_manager','warehouse','warehouse_supervisor','warehouse_manager','vouchers','transfer','direct-sale','van-sales','delivery','vehicle-count'] },
```

---

### PATCH-337-02 — إضافة capability helper

ابحث حرفيًا عن:

```javascript
function canRead() {
```

وقبلها مباشرة أضف هذا العنصر كاملًا:

```javascript
  function canBindVehicleOperation() {
    var u = currentUser();
    if (!u) return false;
    if (u.isOwner === true) return true;
    var p = Array.isArray(RW_STATE.permissions) ? RW_STATE.permissions : [];
    return p.indexOf('*') !== -1 ||
      p.indexOf('fleet.manage') !== -1 ||
      p.indexOf('fleet.read') !== -1 ||
      p.indexOf('warehouse') !== -1 ||
      p.indexOf('warehouse_supervisor') !== -1 ||
      p.indexOf('warehouse_manager') !== -1 ||
      p.indexOf('vouchers') !== -1 ||
      p.indexOf('transfer') !== -1 ||
      p.indexOf('direct-sale') !== -1 ||
      p.indexOf('van-sales') !== -1 ||
      p.indexOf('delivery') !== -1 ||
      p.indexOf('delivery_supervisor') !== -1 ||
      p.indexOf('vehicle-count') !== -1 ||
      u.role === 'مدير عام' ||
      u.role === 'مدير مخازن' ||
      u.role === 'مشرف مخازن' ||
      u.role === 'مخزني' ||
      u.role === 'مندوب بيع مباشر' ||
      u.role === 'مندوب توصيل' ||
      u.role === 'مشرف توصيل';
  }
```

---

### PATCH-337-03 — داخل canRead فقط

ابحث عن هذه المجموعة داخل:
`function canRead()`

```javascript
return p.indexOf('*') !== -1 ||
      p.indexOf('fleet.manage') !== -1 ||
      p.indexOf('fleet.read') !== -1 ||
      p.indexOf('reports') !== -1 ||
```

استبدلها بهذه المجموعة:

```javascript
return p.indexOf('*') !== -1 ||
      p.indexOf('fleet.manage') !== -1 ||
      p.indexOf('fleet.read') !== -1 ||
      p.indexOf('warehouse') !== -1 ||
      p.indexOf('warehouse_supervisor') !== -1 ||
      p.indexOf('warehouse_manager') !== -1 ||
      p.indexOf('vouchers') !== -1 ||
      p.indexOf('transfer') !== -1 ||
      p.indexOf('direct-sale') !== -1 ||
      p.indexOf('van-sales') !== -1 ||
      p.indexOf('delivery') !== -1 ||
      p.indexOf('delivery_supervisor') !== -1 ||
      p.indexOf('vehicle-count') !== -1 ||
      p.indexOf('reports') !== -1 ||
```

لا تغير باقي `canRead()`.

---

### PATCH-337-04 — command()

ابحث عن:

```javascript
async function command(commandName, payload, operationId) {
    if (!canManage()) throw new Error('ليس لديك صلاحية تنفيذ عمليات Fleet');
```

احذف السطر الثاني فقط واستبدله بهذه الثلاثة أسطر:

```javascript
    if (commandName === 'VEHICLE_OPERATION_BIND') {
      if (!canBindVehicleOperation()) throw new Error('ليس لديك صلاحية ربط العمليات بالمركبات');
    } else if (!canManage()) throw new Error('ليس لديك صلاحية تنفيذ عمليات Fleet');
```

لا تعدل باقي `command()`.

---

### PATCH-337-05 — زر الربط داخل Vehicle Detail

الموضع الحالي:
حوالي السطر 29082 داخل:
`async function openVehicleDetail(id)`

ابحث عن الجزء الذي يبدأ حرفيًا:

```javascript
(canManage()? '<button onclick="RW_FleetManagement.openOdometerForm()"
```

وينتهي بنفس العنصر عند:

```javascript
...RW_FleetManagement.openVehicleOperationLinkForm()...</button>' : '')+
```

استبدل هذا العنصر فقط بهذا العنصر:

```javascript
      (canManage()? '<button onclick="RW_FleetManagement.openOdometerForm()" class="px-3 py-2 rounded-xl bg-slate-100 font-bold">عداد</button><button onclick="RW_FleetManagement.openFuelForm()" class="px-3 py-2 rounded-xl bg-slate-100 font-bold">وقود</button><button onclick="RW_FleetManagement.openMaintenanceForm()" class="px-3 py-2 rounded-xl bg-slate-100 font-bold">صيانة</button><button onclick="RW_FleetManagement.openContractForm()" class="px-3 py-2 rounded-xl bg-slate-100 font-bold">عقد</button><button onclick="RW_FleetManagement.openVehicleDocumentForm()" class="px-3 py-2 rounded-xl bg-slate-100 font-bold">مستند</button><button onclick="RW_FleetManagement.openIncidentForm()" class="px-3 py-2 rounded-xl bg-slate-100 font-bold">حادث</button><button onclick="RW_FleetManagement.openExpenseForm()" class="px-3 py-2 rounded-xl bg-slate-100 font-bold">مصروف</button>' : '')+(canBindVehicleOperation()? '<button onclick="RW_FleetManagement.openVehicleOperationLinkForm()" class="px-3 py-2 rounded-xl bg-indigo-600 text-white font-bold">ربط المركبة بالعملية</button>' : '')+
```

النتيجة:
- Fleet Master Data buttons تبقى تحت `canManage()`.
- زر ربط العملية يصبح قدرة مستقلة.

---

### PATCH-337-06 — openVehicleOperationLinkForm()

ابحث عن:

```javascript
if (!canManage()) throw new Error('ليس لديك صلاحية ربط العمليات بالمركبات');
```

داخل:
`async function openVehicleOperationLinkForm()`

احذفه واستبدله بهذا السطر:

```javascript
    if (!canBindVehicleOperation()) throw new Error('ليس لديك صلاحية ربط العمليات بالمركبات');
```

لا تعدل أي جزء آخر من الدالة.

---

## 17. ما لا يجب تعديله في main.html

لا تعدل:
- `operationBlock()`
- `openVehicleOperationLinkForm()` body
- `fleet_query` consumer contract
- `VEHICLE_OPERATION_BIND` payload
- `voucher_id`
- `direct_sales_rep_id`
- `operation_id`
- `vehicle_detail` projection
- RUNSHEET logic
- DirectSale identity logic
- stock logic.

هذه العناصر ثبتت صحتها في الجولة الحالية والتاريخ السابق.

---

## 18. تدفق العمل بعد PATCH-337

### بداية العملية
مندوب البيع المباشر أو الإدارة يحدد:
- السيارة.
- مندوب البيع.

### إعداد المخزن
المخزن يفتح:
إدارة الأسطول والحركة
→ المركبات
→ تفاصيل المركبة
→ ربط المركبة بالعملية

ثم:
- يختار DirectSale document.
- رقم المستند يقرأ من المستند نفسه.
- Reference يقرأ من المستند نفسه.
- Direct Sales Rep يختار من `direct_sales_reps`.

### Binding
```
Mother
→ fleet_command_atomic
→ VEHICLE_OPERATION_BIND
→ stock_vouchers.to_id
→ stock_vouchers.custodian_user_id
```

### التنفيذ لاحقًا
```
SEND
→ send_stock_voucher_atomic
→ send_stock_voucher_atomic_core_20260828
→ post_stock_movement
→ stock_branches
→ inventory_log
→ driver/custody ledger
```

وهكذا لا تصبح كل شاشة جزيرة منفصلة.

---

## 19. التأثير على التقارير

عند اعتماد:
- vehicle = voucher.to_id
- Direct Sales Rep = voucher.custodian_user_id
- document/reference = voucher fields
- physical movement = inventory_log

يمكن للتقارير أن تربط العملية على مستوى:
- المركبة.
- مندوب البيع.
- المخزن.
- المستند.
- المرجع.
- حركة المخزون.
- العهدة.
- التسوية.

وهذا هو الربط الصحيح للمراقبة، دون Dual Write للمخزون.

---

## 20. مقارنة تنافسية

### Odoo
Odoo Fleet يوفر بيانات المركبة، العقود، الخدمة، السائقين، العدادات والصيانة. كما أن سجلات الخدمة ترتبط بالمركبة والسائق والتكلفة والعداد.  
مصادر رسمية:
- https://www.odoo.com/documentation/19.0/applications/hr/fleet/new_vehicle.html
- https://www.odoo.com/documentation/19.0/applications/hr/fleet/service.html
- https://www.odoo.com/documentation/19.0/applications/hr/fleet/odometer.html

### Microsoft Dynamics
Transportation Management يربط النقل الوارد والصادر، التخطيط، الأساطيل الداخلية والخارجية، الأحمال، المسارات، والتكاليف؛ كما يدعم تخطيط المسارات متعددة التوقفات والأحمال المبنية على الوزن والحجم.  
المصادر الرسمية:
- https://learn.microsoft.com/en-us/dynamics365/supply-chain/transportation/transportation-management-overview
- https://learn.microsoft.com/en-us/dynamics365/supply-chain/transportation/plan-freight-transportation-routes-multiple-stops

### SAP
SAP Transportation Management يعامل Vehicle وDrivers وTransportation Units كـResources مرتبطة بالقدرة والتوافر والتخطيط والتنفيذ.  
المصادر الرسمية:
- https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/e3dc5400c1cc41d1bc0ae0e7fd9aa5a2/bad5555bf8d042069b1ed7927e6e59e7.html
- https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/e3dc5400c1cc41d1bc0ae0e7fd9aa5a2/aa0deb63fb22457fa41c36a156f69157.html

### Daftra
Daftra يركز في النقل على ملف الرحلة، الإيرادات والمصروفات، ميزانية السيارة، الصيانة ورسوم الخدمة وصافي الربح، مع إدارة أصول المركبات والاستهلاك.  
المصدر الرسمي:
- https://www.daftra.com/en/transportation/

### Manager.io
Manager يدعم Reference مستقلًا للمعاملات، ويستخدم Inventory Locations، Transfers، Goods Receipts، Delivery Notes، ومراجع داخل المستندات. كما يتيح custom fields على المستندات والمعاملات.  
المصادر الرسمية:
- https://www2.manager.io/guides/18764
- https://www2.manager.io/guides/10707
- https://www2.manager.io/guides/8941

### الاستفادة لـRAWAEA
الفجوة القادمة ليست في زر الربط نفسه.

الإضافات التنافسية المستقبلية المنطقية:
- trip cost ledger.
- cost/km.
- fuel cost per trip.
- maintenance cost allocation.
- vehicle capacity utilization.
- planned vs actual route.
- driver/rep productivity.
- vehicle availability calendar.
- asset lifecycle/depreciation.
- route profitability.
- unified vehicle + operation + document 360 view.

هذه ليست ضمن Closure الحالي ولا يجب إدخالها داخله.

---

## 21. Self Audit

### ما تم إثباته
- Current Mother source.
- Current Mother HEAD/parent/blob.
- Current System HEAD/parent.
- Current Production fleet RPCs.
- Actual operational users and permissions.
- Actual vehicles/mobile branches.
- Root cause of access loss.
- Existing Control Plane integrity.
- Production authorization fix.
- Warehouse Supervisor E2E.
- Vouchers actor E2E.
- DirectSale BIND/REPLAY/SEND E2E.
- Stock delta.
- Accounting delta.
- custody ledger behavior.
- vehicle_detail projection.
- QA residue cleanup.
- main.html in-memory patch syntax.

### ما لم يُثبت
- authenticated Browser E2E على الـpublished Mother artifact.

### Unknowns
- المحتوى الأصلي الدقيق لـProduction migration `20260924164831...` غير مستخرج من Git؛ لم يتم تخمينه.

### Conflicts
- كانت هناك فجوة بين Mother Fleet permissions وOperational permissions.
- تم إغلاقها في Production Control Plane.
- Mother consumer patch ما زال يحتاج تطبيق المالك.

### Unverified Claims
لا توجد مطالبة Browser PASS.

---

## 22. Final Closure Status

### Production Control Plane
`VEHICLE_OPERATION_BIND Authorization = CLOSED`

### Production E2E
`Warehouse Supervisor = PASS`
`Vouchers Actor = PASS`
`DirectSale Bind/Replay/Send = PASS`

### Physical Stock
`Centralized through post_stock_movement = VERIFIED`

### Accounting
`Binding = No GL movement`
`DirectSale SEND = custody ledger only at this stage`

### Data Hygiene
`QA residue = 0`

### Mother main.html
`SOURCE PATCH = READY FOR OWNER`
`ASSISTANT WRITE = NO`

### Browser
`AUTHENTICATED PUBLISHED E2E = OPEN / UNVERIFIED`

---

## 23. تعليمات الاستمرارية للمساعد القادم

ابدأ بهذا الترتيب ولا تبدأ من تقرير قديم:

1. اقرأ آخر `CURRENT_STATE.md`.
2. اطبع Current System HEAD + parent.
3. اطبع Current Mother HEAD + parent + main.html blob.
4. اطبع Current Production migrations.
5. اعمل checksum/identity للمصدر الحالي.
6. لا تعيد Report334.
7. لا تعيد DirectSale driver decoupling.
8. لا تعيد custodian persistence.
9. لا تنشئ Edge Function لهذه القدرة.
10. لا تغير Physical Stock contract.
11. طبّق فقط PATCH-337 على Mother إذا لم يكن قد طبق بالفعل.
12. بعد Owner update:
   - اعمل parse كامل لـmain.html.
   - اعمل authenticated Browser E2E.
   - تحقق Network → fleet_query.
   - تحقق Network → fleet_command_atomic.
   - تحقق أن BIND لا يضيف inventory movement.
   - نفّذ DirectSale SEND في QA transaction.
   - تحقق reports.
13. بعد Browser PASS فقط أغلق Browser closure.
14. أي تقرير جديد يجب أن يذكر:
   - ما تم إثباته.
   - ما لم يتم إثباته.
   - ما تم تغييره.
   - ما الذي لم يتغير.
   - Primary source identities.

---

## 24. أهم قاعدة للمواصلة

لا تسأل:
"هل توجد وظيفة ربط المركبة؟"

السؤال الصحيح:
"هل يستطيع المستخدم التشغيلي المقصود تنفيذ دورة الربط كاملة من Mother إلى Control Plane إلى projection إلى التقرير، مع بقاء Physical Stock والمحاسبة في محركاتهما المركزية؟"

هذه هي وحدة القياس الصحيحة لإغلاق هذه القدرة.
