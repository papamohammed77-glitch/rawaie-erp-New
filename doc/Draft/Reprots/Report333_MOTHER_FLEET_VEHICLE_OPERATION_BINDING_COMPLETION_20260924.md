# Report333 — التحقيق الجنائي وإكمال ربط المركبة بالعملية
## RAWAEA ERP — Mother main.html / Fleet / Vehicle Details / Operation Binding
### 2026-09-24

---

## 1. نطاق الإغلاق

النطاق الوحيد:
النظام الأم → إدارة الأسطول والحركة → المركبات → تفاصيل المركبة → ربط المركبة بالعملية.

القدرات:
- RUNSHEET: رقم الرانشيت + السائق + مندوب التوصيل.
- BRANCH_TRANSFER: السائق + المركبة.
- DIRECT_SALE: مندوب البيع المباشر + المركبة.
- إظهار العمليات المرتبطة في تفاصيل المركبة.
- الحفاظ على المصدر الأصلي للعملية.
- عدم إنشاء dual-write أو Physical Stock Engine جديد.
- دعم retry/idempotency.
- الحفاظ على المخزون والمحاسبة والتقارير والتدقيق.

---

## 2. منهج التحقيق

تمت قراءة:
- MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS حتى EOF.
- CURRENT_STATE.md حتى EOF.
- Report332 حتى EOF.

تمت مطابقة:
CURRENT GIT
+
CURRENT SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT EVIDENCE.

التقارير استُخدمت كمؤشرات بحث فقط.

---

## 3. Git Current Reality

### System
Repository: papamohammed77-glitch/rawaie-erp-New

HEAD:
247feb5067c690e3ceca668c1b048ba56df3d856

Parent:
160ab6c41491e90bbd8f5cae690e0aee0c74c373

Relevant commits:
- d7b198a53c0e69d772a0b137c9810a5f31e2df5f
- 160ab6c41491e90bbd8f5cae690e0aee0c74c373
- 247feb5067c690e3ceca668c1b048ba56df3d856

### Mother
Repository: papamohammed77-glitch/erp-frontend

HEAD:
413b1eb8bfc633a0489b5e27b3c69874a2afa562

Parent:
4ef6973f2289f76d89aa9d9d52628171326793d8

File:
companies/company-1/main.html

Current blob:
274a884785ac1a38394a30735802dec5378fad0d

Current file:
32,075 lines / 1,741,281 chars.

Mother main.html was not modified by the assistant.

---

## 4. Historical Reconstruction

### Runsheet
Existing canonical fields:
- runsheets.vehicle_id
- runsheets.driver_id
- runsheets.deliverer_id

### Direct Sale
Existing canonical vehicle identity:
- stock_vouchers.to_type = Vehicle
- stock_vouchers.to_id = vehicle
- stock_vouchers.custodian_user_id = direct-sales representative

Do not add a second vehicle_id for DirectSale.

### Branch Transfer
The actual historical gap was persistent vehicle/driver identity on Transfer vouchers.
Production already contains:
- stock_vouchers.vehicle_id
- stock_vouchers.driver_id

### Control Plane
Existing:
- fleet_query
- fleet_command_atomic
- VEHICLE_OPERATION_BIND
- vehicle_detail
- vehicle_operation_candidates

No new Edge Function was required.

---

## 5. Root Cause Proven

The old mobile voucher trigger treated:

vehicle.driver_id

as:

Direct Sales Representative.

This contradicted the later operation-level contract:

stock_vouchers.custodian_user_id

where the custodian is the actual Direct Sales Rep.

Observed consequence:
DirectSale could fail with the mobile custody error when vehicle.driver_id was NULL.

The contradiction was historical:
- the custody guard tied the rep to vehicle.driver_id;
- the 2026-09-21 Direct Sales contract introduced explicit rep identity;
- the Fleet bind control plane also writes custodian_user_id.

Therefore the correct ownership model is:

Vehicle Driver = operational driver

DirectSale Custodian = operation-level Direct Sales Representative

They are independent identities.

---

## 6. Production Fix #1

Migration:
20260924125815_fix_directsale_custodian_operation_identity_20260924

Applied directly to Production.

Also stored in Git:
supabase/migrations/20260924125815_fix_directsale_custodian_operation_identity_20260924.sql

Changed:
enforce_stock_voucher_custodian()

New contract:
- DirectSale / DirectReturn require Vehicle endpoint.
- Vehicle must belong to the same company.
- custodian_user_id is mandatory.
- custodian must be active.
- same company.
- role = مندوب بيع مباشر.
- permission = van-sales.
- executed mobile voucher identity is immutable.

No change to Physical Stock semantics.

---

## 7. Production Fix #2

Migration:
20260924130417_align_fleet_direct_sales_rep_permission_20260924_v3

Applied directly to Production.

Canonical Git file:
supabase/migrations/20260924130417_align_fleet_direct_sales_rep_permission_20260924_v3.sql

It aligns:
- fleet_query candidates
- fleet_command_atomic bind validation
- mobile voucher custody validation

Final Direct Sales Rep condition:
active + same company + role مندوب بيع مباشر + van-sales permission.

---

## 8. Current Production Data Integrity

Current checks:

DirectSale / DirectReturn:
- missing custodian = 0
- invalid custodian = 0

Branch Transfer:
- missing vehicle = 0
- missing driver = 0
- invalid vehicle = 0
- invalid driver = 0

Active same-company Direct Sales Reps with van-sales permission:
2

No E2E test residue:
- E2E vouchers = 0
- E2E runsheets = 0
- E2E inventory logs = 0

---

## 9. E2E — RUNSHEET

Temporary transaction:
Create Runsheet → Bind Vehicle + Driver + Delivery Rep → Replay same Operation ID → Vehicle Detail.

Result:
PASS

Verified:
- persistence correct.
- replay duplicate=true.
- stock unchanged.
- GL unchanged.
- vehicle detail read model correct.

Rollback completed.

---

## 10. E2E — BRANCH TRANSFER

Temporary transaction:
Create Transfer Voucher → Bind Vehicle + Driver → Replay → SEND → RECEIVE → COMPLETE → Vehicle Detail.

Result:
PASS

Verified:
- bind persisted.
- bind replay duplicate=true.
- send succeeded.
- receive succeeded.
- receive replay duplicate=true.
- complete succeeded.
- source stock = -1.
- target stock = +1.
- journal entries delta = 0.
- journal lines delta = 0.
- vehicle_detail.transfer_operations correct.

Rollback completed.

---

## 11. E2E — DIRECT SALE

Temporary transaction:
Create DirectSale Voucher → Direct Sales Rep custody → Bind Vehicle + Rep → Replay → SEND → Vehicle Detail.

Result:
PASS

Verified:
- vehicle identity correct.
- operation-level rep identity correct.
- replay duplicate=true.
- SEND succeeded.
- source stock = -1.
- mobile stock = +1.
- driver ledger custody = +10 for one unit priced at 10.
- journal entries delta = 0.
- journal lines delta = 0.
- customer ledger delta = 0.
- supplier ledger delta = 0.
- treasury delta = 0.
- cash box delta = 0.
- direct_sales read model correct.

Rollback completed.

---

## 12. Negative DirectSale E2E

After execution, an attempted rebind to a different Direct Sales Rep was rejected.

Result:
PASS

Guard:
البيع المباشر المنفذ مرتبط بالفعل بمركبة/مندوب مختلف

Executed operation identity is immutable.

Rollback completed.

---

## 13. Authenticated Query Path

Browser-auth simulation used:
request.jwt.claims.sub = owner auth_id.

fleet_query(..., p_actor_user_id = NULL)

Result:
PASS

The RPC correctly resolved auth.uid() and returned direct_sales_reps projection.

Therefore the Mother UI does NOT need to add currentUser.id for this query.

Do not create a separate frontend workaround.

---

## 14. Physical Stock Integrity

Production discovery shows only:

post_stock_movement

as the Physical Quantity mutation engine.

reserve_stock / release_stock_reservation remain reservation operations.

The legacy 9-argument post_stock_movement overload delegates to the canonical engine and is not a second Physical Stock engine.

Contract remains:

PHYSICAL STOCK MOVEMENT
→ post_stock_movement
→ stock_branches + inventory_log

---

# 15. Mother UI — Actual Remaining Gap

Current Mother main.html contains:
- no vehicle-operation binding button.
- no operation-link modal.
- no operation cards for transfer/direct sale.
- command helper generates a fresh operation id internally.

Production Control Plane already exists.

Therefore the remaining gap is Consumer/UI completion only.

---

# 16. PATCH-333-01 — Command Operation Identity

File:
companies/company-1/main.html

Function:
async function command(commandName, payload) {

Find exactly:

`js
async function command(commandName, payload) {
`

Replace only with:

`js
async function command(commandName, payload, operationId) {
`

Then, inside the same function, find exactly:

`js
p_operation_id: op(commandName),
`

Replace only with:

`js
p_operation_id: operationId || op(commandName),
`

Do not replace the function body.

---

# 17. PATCH-333-02 — Button

Inside:
async function openVehicleDetail(id)

Find exactly:

`html
<button onclick="RW_FleetManagement.openExpenseForm()" class="px-3 py-2 rounded-xl bg-slate-100 font-bold">مصروف</button>
`

Replace only with:

`html
<button onclick="RW_FleetManagement.openExpenseForm()" class="px-3 py-2 rounded-xl bg-slate-100 font-bold">مصروف</button><button onclick="RW_FleetManagement.openVehicleOperationLinkForm()" class="px-3 py-2 rounded-xl bg-indigo-600 text-white font-bold">ربط المركبة بالعملية</button>
`

Do not replace openVehicleDetail.

---

# 18. PATCH-333-03 — Operation Read Model

Inside:
openVehicleDetail(id)

Find exactly:

`js
listBlock('الرحلات',d.runsheets,'runsheet_code','run_date')+
`

Delete that line only.

Replace with:

`js
operationBlock('الرحلات',d.runsheets,'RUNSHEET')+operationBlock('تحويلات الفروع',d.transfer_operations,'BRANCH_TRANSFER')+operationBlock('البيع المباشر',d.direct_sales,'DIRECT_SALE')+
`

---

# 19. PATCH-333-04 — Operation Renderer

Immediately before:

`js
function listBlock(title, rows, labelKey, dateKey) {
`

Insert:

`js
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
`

---

# 20. PATCH-333-05 — Vehicle Operation Binding Modal

Immediately before:

`js
async function openVehicleEdit(id){
`

Insert both functions below in full:

`js
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

    var rsOptions = [['','اختر الرانشيت']].concat(rs.map(function(x){
      return [x.id, (x.runsheet_code||'—') + ' · ' + (x.status||'—') + ' · سائق: ' + (x.driver_name||'—') + ' · توصيل: ' + (x.delivery_rep_name||'—')];
    }));
    var trOptions = [['','اختر تحويل الفرع']].concat(tr.map(function(x){
      return [x.id, (x.voucher_code||'—') + ' · ' + (x.status||'—') + ' · ' + (x.current_vehicle_code ? 'مركبة حالية: '+x.current_vehicle_code : 'غير مربوطة') + ' · سائق: ' + (x.driver_name||'—')];
    }));
    var dsOptions = [['','اختر البيع المباشر']].concat(ds.map(function(x){
      return [x.id, (x.voucher_code||'—') + ' · ' + (x.status||'—') + ' · مندوب: ' + (x.direct_sales_rep_name||'—') + (x.current_vehicle_code ? ' · مركبة: '+x.current_vehicle_code : '')];
    }));
    var driverOptions = [['','اختر السائق']].concat(drivers.map(function(x){ return [x.id,(x.name||x.email||'—')+' · '+(x.role||'')]; }));
    var deliveryOptions = [['','اختر مندوب التوصيل']].concat(deliveryReps.map(function(x){ return [x.id,(x.name||x.email||'—')+' · '+(x.role||'')]; }));
    var directOptions = [['','اختر مندوب البيع المباشر']].concat(directReps.map(function(x){ return [x.id,(x.name||x.email||'—')+' · '+(x.role||'')]; }));

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
`

---

# 21. PATCH-333-06 — API Exposure

Inside RW_FleetManagement API object.

Immediately after exactly:

`js
openVehicleEdit: openVehicleEdit,
`

insert:

`js
    openVehicleOperationLinkForm: openVehicleOperationLinkForm,
    toggleVehicleOperationLinkPanels: toggleVehicleOperationLinkPanels,
`

Do not replace the API object.

---

# 22. Static Verification

An in-memory patched copy of the current main.html was built without writing the source.

Before:
- command signature anchor = 1.
- operation id line = 1.
- openVehicleDetail = 1.
- old runsheet renderer = 1.
- listBlock = 1.
- openVehicleEdit = 1.
- API anchor = 1.

After:
- command(operationId) = 1.
- operationId forwarding = 1.
- operationBlock = 1.
- openVehicleOperationLinkForm = 1.
- API exposure = 1.

Full inline JavaScript compilation:
PASS

Scripts parsed:
6

The actual Mother main.html remains untouched.

---

# 23. Competitor Functional Benchmark

هذه المقارنة ليست ترتيبًا أو تقييم فائز.

### Odoo
Odoo Fleet يربط المركبة بالسائق، ويدير service history والتكلفة والمرحلة.
https://www.odoo.com/documentation/19.0/applications/hr/fleet/service.html

الاستفادة لـRAWAEA:
- Service history.
- Driver context.
- Vendor.
- Cost.
- Stage.

### SAP Transportation Management
SAP يعرّف vehicle resource مع capacity/availability ويربط drivers بالـfreight orders، ويقدم cost analysis وفق عدة أبعاد، ومنها actual/planned costs.
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/e3dc5400c1cc41d1bc0ae0e7fd9aa5a2/bad5555bf8d042069b1ed7927e6e59e7.html
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/e3dc5400c1cc41d1bc0ae0e7fd9aa5a2/a0fcb406eb9c473098c76ca23e88a1e5.html

الاستفادة:
- Operation capacity.
- Planned vs actual cost.
- Route/source/destination.
- Vehicle utilization.

### Daftra
Daftra يربط ملف الرحلة بالإيرادات والمصروفات والرسوم وصيانة المركبة وصافي الربح، ويقدم Mileage Tracking.
https://www.daftra.com/en/transportation/
https://docs.daftra.com/en/user_manual/mileage-tracking/

الاستفادة:
- Trip Cost.
- Mileage Cost.
- Vehicle profitability.

### Dynamics 365 Field Service
Dynamics يحسب travel charges ويربطها بالـwork order / booking.
https://learn.microsoft.com/en-us/dynamics365/field-service/travel-charges

الاستفادة:
- Cost per operational event.
- Travel cost allocation.

### Manager.io
Manager يربط Inventory Items بالبيع والشراء وحركات المخزون والربحية.
https://www2.manager.io/guides/7551

الاستفادة:
- single item identity.
- stock/accounting consistency.

هذه ليست تغييرات Patch-333؛ هي Backlog موثق فقط.

---

# 24. Future Fleet Capability Backlog

بعد تثبيت Binding يمكن إضافة capabilities مستقلة:
- عداد بداية/نهاية لكل عملية.
- Distance per operation.
- Fuel cost allocation.
- Maintenance allocation.
- Toll / parking / route expenses.
- Planned vs actual trip cost.
- Weight / volume capacity utilization.
- Cost per kilometer.
- Cost per delivered order.
- Cost per runsheet.
- Cost per branch transfer.
- Direct-sales vehicle profitability.

لا تُدمج هذه العناصر داخل Patch-333.

---

# 25. Final Self-Audit

## What was proved
- Root cause proved.
- Production custody contradiction fixed.
- Fleet candidate/bind permission aligned.
- Runsheet E2E PASS.
- Branch Transfer E2E PASS.
- Direct Sale E2E PASS.
- Accounting verification PASS.
- No duplicate E2E.
- Current data integrity PASS.
- Authenticated query path PASS.
- Physical Stock remains centralized.
- Mother patch parses in-memory.

## What was not proved
- Real browser UI E2E after owner publication.
- Served artifact after owner commit.
- Browser Console/Network evidence.

## Current Closure
Production Control Plane:
FULLY CLOSED

Mother main.html Consumer:
OWNER PATCH READY

Overall Mother Vehicle Operation Binding:
PENDING OWNER PATCH + PUBLISH + BROWSER E2E

---

# 26. Exact Next Start

1. Verify current System HEAD.
2. Verify current Mother HEAD and main.html blob.
3. Apply only PATCH-333-01..06.
4. Parse full main.html.
5. Commit.
6. Publish.
7. Verify served artifact.
8. Run authenticated browser E2E:
   إدارة الأسطول والحركة → المركبات → تفاصيل المركبة → ربط المركبة بالعملية.
9. Test RUNSHEET / TRANSFER / DIRECT SALE.
10. Capture Console + Network.
11. Verify DB and vehicle_detail.
12. Replay with same Operation ID.
13. Verify no duplicate physical movement.
14. Take fresh Production snapshot in same reporting moment.
15. Update CURRENT_STATE.md.

Do not reopen:
- Fleet Vehicle Master.
- fleet_command_atomic architecture.
- fleet_query architecture.
- Physical Stock centralization.
- previously closed voucher/inventory closures.

# END OF REPORT333
