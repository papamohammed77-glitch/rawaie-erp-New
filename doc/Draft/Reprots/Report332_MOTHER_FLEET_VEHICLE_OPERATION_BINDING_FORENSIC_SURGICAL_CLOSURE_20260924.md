# Report332 — التحقيق الجنائي وإغلاق Control Plane لربط المركبة بالعملية
## RAWAEA ERP — Fleet / Vehicle Details / Vehicle Operation Binding
### التاريخ: 2026-09-24

---

## 1. نطاق المهمة

النطاق الوحيد لهذه الدورة:

**النظام الأم Mother → إدارة الأسطول والحركة → المركبات → تفاصيل المركبة**

المطلوب المثبت:

- زر **ربط المركبة بالعملية**.
- ربط المركبة برانشيت:
  - رقم الرانشيت.
  - السائق.
  - مندوب التوصيل.
- ربط المركبة بتحويل فرع:
  - السائق.
- ربط المركبة ببيع مباشر:
  - مندوب البيع المباشر.
- إظهار العمليات المرتبطة داخل تفاصيل المركبة.
- ربط العملية بمصادرها الأصلية وعدم إنشاء مصدر بيانات موازي.
- الحفاظ على Physical Stock وFulfillment وAccounting Contracts الحالية.
- تنفيذ Production مباشرة عند الحاجة.
- عدم تعديل `main.html` بواسطة المساعد.
- عدم إنشاء Edge Function جديدة.

قاعدة الحقيقة:

CURRENT GIT
+
CURRENT SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT EVIDENCE

---

# 2. الحكم التنفيذي

تم إغلاق الـProduction Control Plane المطلوب بنجاح.

تم بناء:

`VEHICLE_OPERATION_BIND`

داخل **الدالة الموجودة أصلًا**:

`public.fleet_command_atomic`

ولم يتم إنشاء Edge Function جديدة.

تم بناء Read Model إضافي داخل:

`public.fleet_query`

بدل إنشاء API جديد.

تم إضافة حقول مركبة للعملية فقط في:

`stock_vouchers.vehicle_id`
`stock_vouchers.driver_id`

لأن Branch Transfer لم يكن لديه هوية مركبة/سائق دائمة.

ولم تتم إضافة `vehicle_id` لبيع مباشر؛ لأن هذا العقد موجود بالفعل:

`stock_vouchers.to_type = 'Vehicle'`
`stock_vouchers.to_id = vehicle_id`

ولم تتم إضافة حقول جديدة للرانشيت؛ لأن العقد موجود أصلًا:

`runsheets.vehicle_id`
`runsheets.driver_id`
`runsheets.deliverer_id`

---

# 3. Current Mother Source — التحقيق الجنائي

Repository:

`papamohammed77-glitch/erp-frontend`

Current HEAD:

`53b254de274af504022d0acf13becc40378bd4aa`

Parent:

`80e42653a4a83874ab739b8a87e7ddc4f407e6e4`

Current `main.html` blob:

`274a884785ac1a38394a30735802dec5378fad0d`

Current file:

`companies/company-1/main.html`

Current line count:

`32075`

### النتيجة

الوحدة:

`RW_FleetManagement`

موجودة بالفعل.

`openVehicleDetail(id)` موجودة.

`openVehicleEdit(id)` موجودة بالفعل ومغلقة سابقًا.

لا توجد في Current Source:

- زر ربط المركبة بالعملية.
- `vehicle_operation_candidates` consumer.
- `VEHICLE_OPERATION_BIND` consumer في Mother.
- عرض منفصل للـTransfer/DirectSale داخل تفاصيل المركبة.

إذن العيب الحقيقي **Consumer/UI Capability Missing** وليس Vehicle Master CRUD.

---

# 4. لماذا لم نعيد فتح Fleet الحالي

ثبت من Current Source وProduction أن:

- `VEHICLE_UPDATE` موجود.
- projection الخاص بـ:
  - `expected_km_per_liter`
  - `operational_condition`
  - `route_capability`
  موجود بالفعل.
- `openVehicleEdit` موجود بالفعل.
- Mobile Vehicle Branch foundation موجود.
- Runsheet assignment يستخدم `manage_runsheet_atomic`.
- Direct Sale يستخدم Vehicle Target + Custodian.
- Physical Stock مركزي.

لذلك تم رفض إعادة بناء هذه الأجزاء.

هذا يتفق مع قاعدة:

**لا تعيد إصلاح ما ثبت إغلاقه.**

---

# 5. Root Cause

## 5.1 المشكلة المعمارية

النظام كان يملك ثلاث هويات تشغيلية منفصلة:

### Runsheet
المركبة موجودة في:

`runsheets.vehicle_id`

والسائق في:

`runsheets.driver_id`

ومندوب التوصيل في:

`runsheets.deliverer_id`

### Direct Sale
المركبة موجودة ضمن:

`stock_vouchers.to_type='Vehicle'`
+
`stock_vouchers.to_id`

والمندوب:

`stock_vouchers.custodian_user_id`

### Branch Transfer
لم يكن يحتوي هوية تشغيلية دائمة للمركبة أو السائق.

### النتيجة

شاشة المركبة كانت تعرف المركبة نفسها، لكنها لم تكن تملك Control Plane موحدًا يعرض:

- Runsheets
- Branch Transfers
- Direct Sales

ويربطها بالمركبة من نقطة واحدة.

هذا منع ظهور المركبة كمركز تشغيل موحد للرحلة والتكلفة والحيازة.

---

# 6. Root Cause الثاني — Driver Identity

الـRPC الحالي القديم كان يقبل أي User Active في ربط الرانشيت/التحويل.

هذا ليس كافيًا.

لذلك تم تشديد العقد بحيث تصبح هوية السائق:

Active
+
Same Company
+
Driver/Delivery identity

وتم اختبار رفض مستخدم `مندوب بيع مباشر` عند محاولة تمريره كسائق رانشيت.

Production:

PASS

الرسالة:

`السائق التشغيلي غير صالح أو ليس هوية سائق/توصيل`

---

# 7. Production Architecture After Fix

## العقد الجديد

### Runsheet

`Mother`

↓

`fleet_command_atomic`

↓

`VEHICLE_OPERATION_BIND`

↓

`manage_runsheet_atomic`

↓

`runsheets.vehicle_id`
+
`runsheets.driver_id`
+
`runsheets.deliverer_id`

---

### Branch Transfer

`Mother`

↓

`fleet_command_atomic`

↓

`VEHICLE_OPERATION_BIND`

↓

`stock_vouchers.vehicle_id`
+
`stock_vouchers.driver_id`

ثم عند التنفيذ:

`send_stock_voucher_atomic`

↓

`post_stock_movement`

↓

`stock_branches`
+
`inventory_log`

---

### Direct Sale

`Mother`

↓

`fleet_command_atomic`

↓

`stock_vouchers.to_type='Vehicle'`
+
`to_id=vehicle`
+
`custodian_user_id=direct_sales_rep`

ثم:

`send_stock_voucher_atomic`

↓

`post_stock_movement`

مع عقد عهدة المندوب الموجود بالفعل.

---

# 8. ما تم تنفيذه فعليًا في Production

## Migration 1

`20260924121815_add_vehicle_operation_binding_control_plane`

تم خلالها:

### Schema

إضافة:

`stock_vouchers.vehicle_id uuid`

`stock_vouchers.driver_id uuid`

### Foreign Keys

`stock_vouchers_vehicle_fk`

`stock_vouchers_driver_fk`

### Check

Transfer:

- كلاهما NULL
- أو كلاهما موجود

ولا يسمح بتركيب غير مكتمل.

### Indexes

`(company_id,vehicle_id,created_at)`

`(company_id,driver_id,created_at)`

### Trigger

`trg_stock_vouchers_transfer_vehicle_context`

وظيفته:

- Company isolation.
- Vehicle identity.
- Driver identity.
- منع ربط أنواع غير Transfer.
- منع تغيير هوية مركبة/سائق بعد التنفيذ.

---

# 9. Existing Fleet RPC — تم تمديده وليس استبداله

تم تمديد:

`fleet_command_atomic`

بدون Function جديدة.

Command الجديد:

`VEHICLE_OPERATION_BIND`

### RUNSHEET

Payload:

- operation_type
- vehicle_id
- runsheet_id
- driver_user_id
- delivery_rep_user_id

### BRANCH_TRANSFER

Payload:

- operation_type
- vehicle_id
- voucher_id
- driver_user_id

### DIRECT_SALE

Payload:

- operation_type
- vehicle_id
- voucher_id
- direct_sales_rep_id

---

# 10. Read Model الجديد

تم تمديد:

`fleet_query`

### vehicle_detail

أصبح يعرض:

- runsheets
- driver_name
- delivery_rep_name
- transfer_operations
- direct_sales

### vehicle_operation_candidates

تم إنشاؤه داخل نفس RPC.

يعيد:

- الرانشيتات المفتوحة/المؤكدة.
- التحويلات غير الملغاة.
- عمليات البيع المباشر غير الملغاة.
- السائقين.
- مندوبي التوصيل.
- مندوبي البيع المباشر.

وكل ذلك:

**Company Scoped**

---

# 11. لماذا لم نستخدم Edge Function جديدة

المشروع عند حد الوظائف/Spend Cap.

لذلك:

**No New Edge Function**

والحل أصبح:

Mother
→ authenticated Supabase RPC
→ existing Fleet control plane

وهذا يقلل:

- Gateway pressure
- Deployment surface
- Duplicate transport layer
- Consumer drift

---

# 12. Production E2E — RUNSHEET

تم تنفيذ اختبار Transactional حقيقي ثم Rollback.

### Vehicle

تم إنشاؤها مؤقتًا بواسطة:

`VEHICLE_CREATE`

### Runsheet

حالة:

`Open`

### Binding

تم:

`VEHICLE_OPERATION_BIND / RUNSHEET`

النتيجة:

PASS

### بعد الربط

تم إثبات:

`runsheets.vehicle_id = vehicle`

`runsheets.driver_id = delivery/driver user`

`runsheets.deliverer_id = delivery rep`

### Replay

نفس:

`operation_id`

النتيجة:

`duplicate=true`

PASS

### Query

`vehicle_detail`

أعاد:

`runsheets = 1`

PASS

### Rollback

PASS

لا يوجد أي QA residue.

---

# 13. Production E2E — BRANCH TRANSFER

تم إنشاء:

Draft Transfer

ثم:

### Bind

المركبة + السائق

PASS

### Binding side effect

قبل SEND:

Stock Delta = 0

أي أن الربط:

**لا يحرّك المخزون**

PASS

### Send

`send_stock_voucher_atomic`

PASS

### Receive

`post_manual_stock_voucher_atomic`

PASS

### Stock

Source:

`-1`

Target:

`+1`

PASS

### General Ledger

لم يتغير:

- Journal entries delta = 0
- Journal lines delta = 0
- Debit delta = 0
- Credit delta = 0

PASS

وهذا صحيح لأن Transfer ليس Revenue transaction.

### Audit

Voucher update audit موجود.

PASS

### Replay

نفس Operation ID:

`duplicate=true`

PASS

### Rollback

PASS

---

# 14. Production E2E — DIRECT SALE

تم تنفيذ:

Vehicle
+
Draft DirectSale
+
Direct Sales Rep

### Binding

PASS

### Replay

`duplicate=true`

PASS

### Send

PASS

الـProduction result أثبت:

`custody_value = 10`

`custody_ledger = true`

`movement_count = 1`

### Physical Stock

Source:

`-1`

Vehicle mobile branch:

`+1`

PASS

### General Ledger

لم يتم إنشاء قيد جديد بسبب ربط/إرسال اختبار العهدة.

PASS

### Driver / Rep Custody Ledger

تم تسجيل:

`+10`

في عهدة:

`van-sales2@rawaea.com`

PASS

### Query

`vehicle_detail.direct_sales = 1`

PASS

### Rollback

PASS

---

# 15. Production E2E — IMMUTABILITY

بعد تنفيذ Branch Transfer:

تمت محاولة إعادة ربطه بمركبة مختلفة.

النتيجة:

مرفوض.

الرسالة:

`تحويل الفرع المنفذ لا يمكن تغيير هوية مركبته/سائقه`

PASS

وهذا يمنع تشويه التاريخ التشغيلي بعد التنفيذ.

---

# 16. Production E2E — DRIVER GUARD

تمت محاولة استخدام:

`مندوب بيع مباشر`

كسائق رانشيت.

النتيجة:

مرفوض.

PASS

وبعد تعديل الحارس:

تم تنفيذ نفس السيناريو المشروع بسائق توصيل حقيقي.

PASS

Replay:

`duplicate=true`

PASS

---

# 17. Inventory Contract

لم يتم إنشاء Physical Stock Engine جديد.

العقد ما زال:

`PHYSICAL STOCK MOVEMENT`

↓

`post_stock_movement`

↓

`stock_branches`

+

`inventory_log`

Binding نفسه لا يغيّر:

- qty
- allocated_qty
- available_qty
- inventory_log

إلا عندما تدخل العملية الفعلية دورة التنفيذ.

وهذا تم إثباته في Transfer E2E.

---

# 18. Accounting Contract

لا يوجد Journal بسبب مجرد Binding.

هذا مقصود.

### Transfer

- Stock movement فقط.
- لا Revenue.
- لا AR.
- لا AP.
- لا GL journal.

### Direct Sale

الربط يغير:

- Vehicle identity
- Custodian identity

ثم SEND ينفذ عقد العهدة الحالي.

أما القيود المحاسبية الكاملة لفاتورة البيع فتظل ضمن:

`save_sales_invoice_atomic`

ولم نخلط هذا العقد مع Fleet Binding.

---

# 19. لماذا هذا التصميم أفضل من إنشاء جدول Vehicle Operations جديد الآن

لم يتم إنشاء جدول مستقل لأن Current Schema لديه بالفعل مصادر أصلية متخصصة:

Runsheet:
`runsheets`

Transfer:
`stock_vouchers`

Direct Sale:
`stock_vouchers`

إنشاء جدول جديد الآن كان سيؤدي إلى:

- Dual Write
- Synchronization debt
- احتمال divergence
- مصدر حقيقة ثانٍ

بينما:

`fleet_query`

يعمل كـRead Model موحد بدون امتلاك البيانات من جديد.

وهذا يحقق الهدف دون صناعة دين معماري جديد.

---

# 20. Competitive Review

تمت مراجعة النمط العام في الأنظمة المنافسة.

### Odoo

يتيح:

- Vehicle
- Driver
- Contracts
- Services
- Odometer
- Cost Analysis
- تكاليف على مستوى المركبة/السائق.

المراجع:

https://www.odoo.com/documentation/19.0/applications/hr/fleet/new_vehicle.html

https://www.odoo.com/documentation/19.0/applications/hr/fleet/service.html

https://www.odoo.com/documentation/19.0/applications/hr/fleet/odometers.html

https://www.odoo.com/documentation/19.0/th/applications/hr/fleet/cost_analysis.html

### Microsoft Dynamics 365

يضيف مفهوم:

- Resource
- Route
- Load
- Capacity
- Scheduling

https://learn.microsoft.com/en-us/dynamics365/supply-chain/transportation/transportation-management-overview

https://learn.microsoft.com/en-us/dynamics365/supply-chain/transportation/plan-freight-transportation-routes-multiple-stops

### SAP S/4HANA Transportation Management

يبني Vehicle Resource حول:

- Capacity
- Availability
- Driver resource
- Qualifications
- Compartments
- Downtime

https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/e3dc5400c1cc41d1bc0ae0e7fd9aa5a2/bad5555bf8d042069b1ed7927e6e59e7.html

### Daftra

يقدم Transportation/Tracking بشكل عالي المستوى.

https://www.daftra.com/en/transportation/

### Manager.io

ليس Fleet platform، لكنه مرجع جيد في ربط المستندات والآثار المالية.

https://www2.manager.io/guides/7189

---

# 21. Competitive Gaps — تم تسجيلها ولم نُدخلها بدون Contract

تم تحديد نقاط قابلة للتطوير مستقبلًا:

- Trip Start / End
- Odometer Start / End
- Route / Territory
- Capacity utilization
- Weight/Volume at execution
- Vehicle availability windows
- Cost center / trip cost allocation
- Fuel-to-trip relation
- Maintenance-to-trip relation
- Attachments / POD
- Operational exceptions
- Scheduled route planning

هذه **Backlog Contracts مستقلة**.

لم يتم إدخالها داخل هذه Closure حتى لا نحول إصلاح الربط إلى إعادة تصميم Fleet كاملة.

---

# 22. Mother Main — الجراحة المطلوبة فقط

## PATCH-332-01 — command operation identity

الملف:

`companies/company-1/main.html`

المكان:

`RW_FleetManagement.command`

ابحث عن هذا السطر **بالضبط**:

```js
async function command(commandName, payload) {
```

احذفه واستبدله فقط بـ:

```js
async function command(commandName, payload, operationId) {
```

ثم ابحث عن هذا السطر **بالضبط** داخل نفس الدالة:

```js
      p_operation_id: op(commandName),
```

احذفه واستبدله فقط بـ:

```js
      p_operation_id: operationId || op(commandName),
```

لا تحذف الدالة كاملة.

---

# 23. PATCH-332-02 — زر ربط المركبة بالعملية

في:

`RW_FleetManagement.openVehicleDetail(id)`

ابحث عن السطر الحالي الذي يبدأ:

```js
(canManage()? '<button onclick="RW_FleetManagement.openOdometerForm()"
```

وفي **نهاية سلسلة أزرار الإدارة داخل نفس السطر**، قبل:

```js
' : '')
```

أضف:

```html
<button onclick="RW_FleetManagement.openVehicleOperationLinkForm()" class="px-3 py-2 rounded-xl bg-indigo-600 text-white font-bold">ربط المركبة بالعملية</button>
```

فتصبح نهاية السلسلة:

```js
<button onclick="RW_FleetManagement.openExpenseForm()" class="px-3 py-2 rounded-xl bg-slate-100 font-bold">مصروف</button><button onclick="RW_FleetManagement.openVehicleOperationLinkForm()" class="px-3 py-2 rounded-xl bg-indigo-600 text-white font-bold">ربط المركبة بالعملية</button>
```

---

# 24. PATCH-332-03 — عرض العمليات داخل تفاصيل المركبة

في:

`RW_FleetManagement.openVehicleDetail(id)`

ابحث عن هذا السطر **بالضبط**:

```js
       listBlock('الرحلات',d.runsheets,'runsheet_code','run_date')+
```

احذفه واستبدله فقط بـ:

```js
       operationBlock('الرحلات',d.runsheets,'RUNSHEET')+operationBlock('تحويلات الفروع',d.transfer_operations,'BRANCH_TRANSFER')+operationBlock('البيع المباشر',d.direct_sales,'DIRECT_SALE')+
```

---

# 25. PATCH-332-04 — دالة عرض العمليات

في:

`RW_FleetManagement`

ابحث عن العلامة **بالضبط**:

```js
function listBlock(title, rows, key, subkey) {
```

أضف **مباشرة قبلها** الدالة التالية كاملة:

```js
  function operationBlock(title, rows, type) {
    var list = Array.isArray(rows) ? rows : [];
    var h = '<div class="rw-card" style="padding:16px"><div style="font-weight:900;color:#0f172a;margin-bottom:12px">' + esc(title) + '</div>';
    if (!list.length) {
      return h + '<div style="font-size:12px;color:#94a3b8;font-weight:700">لا توجد عمليات مرتبطة</div></div>';
    }
    for (var i=0;i<Math.min(list.length,8);i++) {
      var x=list[i]||{};
      var label = type==='RUNSHEET' ? (x.runsheet_code||'—') : (x.voucher_code||'—');
      var meta = '';
      if(type==='RUNSHEET') {
        meta = 'السائق: ' + (x.driver_name||'—') + ' · مندوب التوصيل: ' + (x.delivery_rep_name||'—') + ' · ' + (x.status||'—');
      } else if(type==='BRANCH_TRANSFER') {
        meta = 'السائق: ' + (x.driver_name||'—') + ' · ' + (x.from_branch_name||'—') + ' ← ' + (x.to_branch_name||'—') + ' · ' + (x.status||'—');
      } else {
        meta = 'مندوب البيع المباشر: ' + (x.direct_sales_rep_name||'—') + ' · ' + (x.status||'—');
      }
      h += '<div style="border:1px solid #e5e7eb;border-radius:16px;padding:11px 12px;margin-top:8px;background:#f8fafc">' +
           '<div style="display:flex;justify-content:space-between;gap:8px;align-items:flex-start">' +
             '<div style="font-weight:900;color:#111827">' + esc(label) + '</div>' +
             '<div style="font-size:11px;color:#64748b;font-weight:800">' + esc(date(x.operation_date||x.run_date)) + '</div>' +
           '</div>' +
           '<div style="font-size:11px;color:#64748b;font-weight:700;margin-top:6px;line-height:1.8">' + esc(meta) + '</div>' +
         '</div>';
    }
    return h + '</div>';
  }

```

---

# 26. PATCH-332-05 — Toggle + Modal ربط العملية

ابحث عن:

```js
async function openVehicleEdit(id){
```

أضف **مباشرة قبله**:

```js
  function toggleVehicleOperationLinkPanels() {
    var type = val('fvo-type');
    var panels = {
      RUNSHEET: 'fvo-rs-panel',
      BRANCH_TRANSFER: 'fvo-tr-panel',
      DIRECT_SALE: 'fvo-ds-panel'
    };
    Object.keys(panels).forEach(function(k){
      var el = byId(panels[k]);
      if (el) el.style.display = k === type ? 'block' : 'none';
    });
  }

  async function openVehicleOperationLinkForm() {
    var id = state.selectedVehicleId;
    if (!id) throw new Error('المركبة غير محددة');
    if (!canManage()) throw new Error('ليس لديك صلاحية ربط العمليات بالمركبات');

    var d = await query('vehicle_operation_candidates',{vehicle_id:id});
    var rs = Array.isArray(d.runsheets) ? d.runsheets : [];
    var tr = Array.isArray(d.transfers) ? d.transfers : [];
    var ds = Array.isArray(d.direct_sales) ? d.direct_sales : [];
    var drivers = Array.isArray(d.drivers) ? d.drivers : [];
    var deliveryReps = Array.isArray(d.delivery_reps) ? d.delivery_reps : [];
    var directReps = Array.isArray(d.direct_sales_reps) ? d.direct_sales_reps : [];
    var vehicle = d.vehicle || {};
    var bindOperationId = op('VEHICLE_OPERATION_BIND');

    var rsOptions = rs.map(function(x){
      return [x.id, (x.runsheet_code||'—') + ' · ' + (x.status||'—') + ' · سائق: ' + (x.driver_name||'—') + ' · توصيل: ' + (x.delivery_rep_name||'—')];
    });
    var trOptions = tr.map(function(x){
      return [x.id, (x.voucher_code||'—') + ' · ' + (x.status||'—') + ' · ' + (x.current_vehicle_code ? 'مركبة حالية: '+x.current_vehicle_code : 'غير مربوطة') + ' · سائق: ' + (x.driver_name||'—')];
    });
    var dsOptions = ds.map(function(x){
      return [x.id, (x.voucher_code||'—') + ' · ' + (x.status||'—') + ' · مندوب: ' + (x.direct_sales_rep_name||'—') + (x.current_vehicle_code ? ' · مركبة: '+x.current_vehicle_code : '')];
    });
    var driverOptions = drivers.map(function(x){ return [x.id,(x.name||x.email||'—')+' · '+(x.role||'')]; });
    var deliveryOptions = deliveryReps.map(function(x){ return [x.id,(x.name||x.email||'—')+' · '+(x.role||'')]; });
    var directOptions = directReps.map(function(x){ return [x.id,(x.name||x.email||'—')+' · '+(x.role||'')]; });

    var html =
      '<div style="text-align:right">' +
        '<div style="padding:12px 14px;border-radius:16px;background:#eff6ff;color:#1e3a8a;font-size:12px;font-weight:800;margin-bottom:12px">المركبة: ' + esc(vehicle.vehicle_code||vehicle.license_plate||id) + ' — الربط يحدّث مصدر العملية نفسه ولا ينشئ سجلًا موازيًا.</div>' +
        '<div><label class="font-bold text-sm text-slate-700">نوع العملية</label><select id="fvo-type" class="rw-input" style="height:46px;padding-right:14px;margin-top:6px" onchange="RW_FleetManagement.toggleVehicleOperationLinkPanels()"><option value="RUNSHEET">رانشيت</option><option value="BRANCH_TRANSFER">تحويل فرع</option><option value="DIRECT_SALE">بيع مباشر</option></select></div>' +
        '<div id="fvo-rs-panel" style="display:block;margin-top:12px">' +
          selectInput('fvo-rs','الرانشيت','',rsOptions) +
          selectInput('fvo-rs-driver','السائق','',driverOptions) +
          selectInput('fvo-rs-delivery','مندوب التوصيل','',deliveryOptions) +
        '</div>' +
        '<div id="fvo-tr-panel" style="display:none;margin-top:12px">' +
          selectInput('fvo-tr','تحويل الفرع','',trOptions) +
          selectInput('fvo-tr-driver','السائق','',driverOptions) +
        '</div>' +
        '<div id="fvo-ds-panel" style="display:none;margin-top:12px">' +
          selectInput('fvo-ds','البيع المباشر','',dsOptions) +
          selectInput('fvo-ds-rep','مندوب البيع المباشر','',directOptions) +
        '</div>' +
        '<div style="margin-top:12px;font-size:11px;color:#64748b;font-weight:700;line-height:1.9">الرانشيت يكتب vehicle_id/driver_id/deliverer_id في الرانشيت. تحويل الفرع يكتب vehicle_id/driver_id في الإذن. البيع المباشر يحافظ على to_type=Vehicle/to_id مع custodian_user_id الحالي.</div>' +
      '</div>';

    await modal('ربط المركبة بالعملية', html, async function() {
      var type = val('fvo-type');
      var payload = { operation_type:type, vehicle_id:id };

      if (type==='RUNSHEET') {
        payload.runsheet_id = val('fvo-rs');
        payload.driver_user_id = val('fvo-rs-driver');
        payload.delivery_rep_user_id = val('fvo-rs-delivery');
        if (!payload.runsheet_id) throw new Error('اختر الرانشيت');
        if (!payload.driver_user_id) throw new Error('اختر السائق');
        if (!payload.delivery_rep_user_id) throw new Error('اختر مندوب التوصيل');
      } else if (type==='BRANCH_TRANSFER') {
        payload.voucher_id = val('fvo-tr');
        payload.driver_user_id = val('fvo-tr-driver');
        if (!payload.voucher_id) throw new Error('اختر تحويل الفرع');
        if (!payload.driver_user_id) throw new Error('اختر السائق');
      } else if (type==='DIRECT_SALE') {
        payload.voucher_id = val('fvo-ds');
        payload.direct_sales_rep_id = val('fvo-ds-rep');
        if (!payload.voucher_id) throw new Error('اختر البيع المباشر');
        if (!payload.direct_sales_rep_id) throw new Error('اختر مندوب البيع المباشر');
      } else {
        throw new Error('نوع العملية غير مدعوم');
      }

      return await command('VEHICLE_OPERATION_BIND',payload,bindOperationId);
    },'ربط المركبة');

    await openVehicleDetail(id);
    showToast('تم ربط المركبة بالعملية بنجاح','success');
  }

```

---

# 27. PATCH-332-06 — API Exposure

في:

`RW_FleetManagement`

ابحث عن:

```js
openVehicleEdit: openVehicleEdit,
```

أضف تحته مباشرة:

```js
    openVehicleOperationLinkForm: openVehicleOperationLinkForm,
    toggleVehicleOperationLinkPanels: toggleVehicleOperationLinkPanels,
```

لا تعدل باقي الـAPI.

---

# 28. Static Patch Validation

Current source قبل Owner patch:

- `command(commandName,payload)` = 1 occurrence.
- `openVehicleDetail(id)` = 1 occurrence.
- `openVehicleEdit(id)` = 1 occurrence.
- `openVehicleEdit: openVehicleEdit` = 1 occurrence.
- `VEHICLE_OPERATION_BIND` UI = 0.
- `vehicle_operation_candidates` UI = 0.

تم اختبار Syntax للنص الجراحي الكامل داخل JavaScript parser:

**PASS**

ولم يتم كتابة `main.html` من المساعد.

---

# 29. Production E2E — Accounting / Stock Truth

## Binding

لا يؤثر على:

- stock_branches
- inventory_log
- journal_entries
- journal_lines

## Transfer SEND/RECEIVE

تم إثبات:

`BR-01 -1`

`BR-2 +1`

والـGL:

`0`

## Direct Sale SEND

تم إثبات:

`Source Branch -1`

`Vehicle Mobile Branch +1`

وعهدة مندوب البيع:

`+10`

أما قيود البيع المحاسبية الكاملة فتظل في Sales Invoice Core.

---

# 30. Production Data Cleanup

بعد كل E2E:

- QA vehicles = 0
- QA vouchers = 0
- QA runsheets = 0
- QA inventory logs = 0
- QA operation registry = 0
- QA binding-related audit residue = 0

لا يوجد QA Business Entity دائم.

---

# 31. Current Production Snapshot

المثبت أثناء الإغلاق:

- companies = 1
- branches = 4
- items = 16
- stock_rows = 53
- stock_vouchers = 2
- inventory_log = 25
- journal_entries = 10
- journal_lines = 16
- driver_ledger_rows = 4

المستندان الدائمان الموجودان:

- IN-1
- IN-2

تم تركهما دون تعديل لأن Current Evidence لم تثبت أن ربطهما بالمركبة يجب أن يكون تلقائيًا.

---

# 32. Closure Matrix

| النقطة | الحالة |
|---|---|
| Vehicle operation command | CLOSED / VERIFIED |
| Runsheet vehicle binding | CLOSED / VERIFIED |
| Runsheet driver binding | CLOSED / VERIFIED |
| Runsheet delivery rep binding | CLOSED / VERIFIED |
| Transfer vehicle identity | CLOSED / VERIFIED |
| Transfer driver identity | CLOSED / VERIFIED |
| Direct Sale vehicle binding | CLOSED / VERIFIED |
| Direct Sale rep identity | CLOSED / VERIFIED |
| Transfer stock integrity | CLOSED / VERIFIED |
| Direct Sale stock integrity | CLOSED / VERIFIED |
| General Ledger unintended mutation | CLOSED / VERIFIED |
| Driver custody effect | CLOSED / VERIFIED |
| Tenant isolation | CLOSED / VERIFIED |
| Executed Transfer immutability | CLOSED / VERIFIED |
| Read model vehicle_detail | CLOSED / VERIFIED |
| Read model operation candidates | CLOSED / VERIFIED |
| New Edge Function | 0 |
| Mother main.html | UNCHANGED |
| Mother surgical patch | READY / OWNER ACTION |
| Authenticated Browser E2E | OPEN / UNVERIFIED |
| Served artifact identity | OPEN / UNVERIFIED |

---

# 33. What Was Not Changed

لم يتم إعادة بناء:

- Vehicle Master
- Vehicle Edit
- Fleet Query base
- Runsheet Engine
- manage_runsheet_atomic
- Picking
- Loading
- Delivery
- Return
- Purchase
- Reservation
- post_stock_movement
- Direct Sale accounting
- existing Edge Functions

السبب:

لا توجد Current Evidence تبرر إعادة فتحها.

---

# 34. Self-Audit

## What I Proved

- Current Mother HEAD.
- Current Mother blob.
- Exact Fleet source.
- Exact missing UI consumer.
- Existing Runsheet identity contract.
- Existing DirectSale vehicle contract.
- Missing Transfer vehicle/driver persistence.
- Production control-plane implementation.
- Driver role guard.
- Company isolation.
- Transfer immutability.
- Runsheet binding.
- Direct Sale binding.
- Replay/idempotency.
- Stock movement effects.
- GL effects.
- Driver custody effect.
- Read model.
- QA cleanup.
- No new Edge Function.

## What I Did Not Prove

- Authenticated Browser E2E.
- Served production Mother artifact after Owner patch.

ولا يجوز تصنيفهما PASS قبل إثباتهما.

## What Could Still Be Wrong

السطح الوحيد المفتوح فعليًا بعد هذه الدورة هو:

**Mother UI publish/runtime**

وليس الـProduction Control Plane.

---

# 35. Exact Next Session Instructions

ابدأ بهذا الترتيب ولا تعُد إلى التقارير القديمة كحالة حالية:

1. تحقق من Mother HEAD.
2. تحقق من `main.html` blob.
3. طبق PATCH-332-01 إلى PATCH-332-06 فقط.
4. Parse كامل `main.html`.
5. Commit.
6. Publish.
7. Verify Served Artifact.
8. افتح Mother.
9. ادخل:
   إدارة الأسطول والحركة
   → المركبات
   → تفاصيل المركبة
   → ربط المركبة بالعملية.
10. اختبر:
   - Runsheet.
   - Transfer.
   - Direct Sale.
11. تحقق من Console.
12. تحقق من Network.
13. تحقق من DB.
14. أعد نفس العملية بنفس Operation ID.
15. تحقق من عدم وجود حركة مزدوجة.
16. خذ Production Snapshot في نفس لحظة التقرير.
17. حدّث `CURRENT_STATE.md`.
18. لا تعيد فتح هذه Closure بدون contradictory evidence.

---

# 36. Governing Rule

لا تحكم على نجاح هذا التغيير من وجود الزر.

النجاح الكامل هو:

UI
→ authenticated RPC
→ correct source record
→ correct actor
→ correct operation identity
→ correct workflow transition
→ correct stock effect
→ correct accounting effect
→ correct audit
→ correct vehicle read model
→ no duplicate
→ no tenant leak
→ no parallel data source

وعند تحقق هذه السلسلة فقط:

**VEHICLE OPERATION BINDING = CLOSED**
