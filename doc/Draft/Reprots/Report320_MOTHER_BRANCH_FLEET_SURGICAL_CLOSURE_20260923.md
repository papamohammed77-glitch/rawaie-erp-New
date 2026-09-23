# تقرير 320 — إغلاق جراحي لعطل المخازن/الفروع وإكمال Fleet UI
## RAWAEA ERP — Production First / Current Source / Surgical Mother Patch
**التاريخ:** 2026-09-23
**النطاق:** النظام الأم `erp-frontend/companies/company-1/main.html` + Production capabilities المرتبطة به.
**قاعدة العمل:** لا إعادة بناء، لا إعادة إصلاح لما ثبت إغلاقه، لا تغيير لمحرك العمليات المخزنية، ولا إنشاء Edge Function جديدة.

---

## 1. الحالة المرجعية التي بُني عليها هذا الإغلاق

### Mother Frontend
- Repository: `papamohammed77-glitch/erp-frontend`
- Current Mother HEAD: `6d505d30dcad981932b3f3562ea9bb37901fecb4`
- Parent: `c2ac6d33cb5c20ba6539f61cabde1b33866ecb46`
- Current `companies/company-1/main.html` blob: `8c3d6b05fd6a94a6b488f12b29da85ae888f70bc`
- أحدث commit على Mother يضيف `printDraftVoucher` إلى `vouchers.html` فقط؛ لا يوجد دليل على تغيير `main.html` في هذا الـHEAD.
- `main.html` لم يُكتب إليه من هذه الجلسة.

### System Git
بعد مزامنة مصادر Production الجديدة:
- HEAD: `eacedf557210a89b4d5a08d79d2e5c4ec76d7c93`
- Parent: `51e67154d9f1fd65f6317ad22b9cdc47b2aff07e`

### Production
- Project: `fiilmooggumokxanwiyx`
- active companies = 1
- active branches = 3
- vehicles = 2
- mobile-stock vehicles = 2
- branches ذات `VAN-` prefix = 2
- `inventory_log` = 6
- `audit_log` = 2147
- QA vehicles = 0
- QA branches = 0
- QA fleet operation records = 0

---

## 2. القراءة التاريخية والحوكمة

تمت مراجعة:
- `MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS`
- `CURRENT_STATE.md`
- Report319
- تقارير Fleet السابقة 264/265/266
- Owner patch السابق لـFleet
- Current Mother source
- Current Production functions / schema / data
- آخر Mother commits وparent
- Production deployment state

القاعدة الحاكمة بقيت كما هي:
`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

والتقارير السابقة استخدمت كسياق تاريخي فقط، ثم أعيد إثبات كل ما يؤثر على هذه الجلسة من Production وCurrent Source.

---

## 3. التحقيق الجنائي — عطل إضافة الفرع

### الدليل من Mother
الموضع الحالي:
`RW_Branches`
السطر المرجعي الحالي: **7052**

النص الحالي:
```js
<div class="flex flex-col"><label>كود الفرع</label><input id="branch-code" value="${b?.branch_code||'جديد'}" readonly class="p-2.5 bg-gray-100 border rounded-lg"></div>
```

### الدليل من Production
`save-branch` كان يستعلم:
```
id,company_id,status,is_owner,permissions
```

لكن فحص Schema Production أثبت أن `public.users` لا يحتوي عمود:
`is_owner`

Schema الفعلي يحتوي:
- id
- company_id
- email
- name
- password_hash
- role
- permissions
- status
- ...
- auth_id
- ...

ولا يوجد `is_owner`.

### Root Cause المثبت
الـEdge Function كانت تنفذ SELECT على عمود غير موجود.
لذلك `userError` يصبح موجودًا، ثم ينتهي التنفيذ بالرسالة:
**سياق الشركة غير صالح**

وهذا يفسر الـHTTP 400 المسجل في Console دون افتراض وجود خلل في company_id نفسه.

### Production Fix المنفذ
تم تحديث `save-branch` من version 4 إلى **version 5**:
- حذف `is_owner` من SELECT.
- الحفاظ على `auth_id` → `users` → `company_id`.
- الحفاظ على صلاحيات `*` أو `branches`.
- الحفاظ على company-scoped update.
- تغيير توليد الكود من ترتيب نصي إلى حساب أعلى رقم فعلي `BR-N`.
- الاستمرار في جعل Production هو المصدر النهائي للكود.

وتم تحديث `delete-branch` إلى **version 4** لنفس إزالة الاعتماد على `is_owner` من actor lookup؛ لمنع إعادة ظهور نفس العطل داخل إدارة الفروع.

لا توجد Edge Function جديدة.

---

## 4. عقد كود الفرع

Production الحالية:
- Branch code uniqueness = `UNIQUE(company_id, branch_code)`
- فرع الأعمال الفعلي الحالي: `BR-01`
- مخازن المركبات المتنقلة الحالية تستخدم `VAN-...` ولا تدخل في عداد `BR-N`

الـgenerator الحالي في `save-branch`:
- يفحص جميع `branch_code` الخاصة بالشركة.
- يأخذ فقط `BR-(digits)`.
- يتجاهل `VAN-` وأي أكواد أخرى.
- يحدد `maxNumber`.
- الكود التالي = `BR-(maxNumber+1)`.

اختبار الخوارزمية على مجموعة اختبارية:
- BR-01
- BR-9
- BR-10
- VAN-CHV-2025-01

النتيجة:
- max = 10
- next = BR-11

وهذا يغلق عيب الترتيب النصي `BR-9` مقابل `BR-10`.

---

## 5. التعديل الجراحي المطلوب في Mother — Branch Code

### PATCH-320-BR-01
**الملف:** `erp-frontend/companies/company-1/main.html`

ابحث عن:
```js
function openModal(code) {
```

أضف مباشرة قبله:

```js
function nextBranchCodePreview() {
    let maxNumber = 0;
    data.forEach(x => {
        const code = String(x.branch_code || '').trim();
        if (code.toUpperCase().indexOf('BR-') !== 0) return;
        const n = parseInt(code.slice(3), 10);
        if (Number.isFinite(n)) maxNumber = Math.max(maxNumber, n);
    });
    return 'BR-' + (maxNumber + 1);
}
```

### PATCH-320-BR-02
في نفس `RW_Branches.openModal` ابحث عن النص الكامل:

```js
<div class="flex flex-col"><label>كود الفرع</label><input id="branch-code" value="${b?.branch_code||'جديد'}" readonly class="p-2.5 bg-gray-100 border rounded-lg"></div>
```

استبدله فقط بـ:

```js
<div class="flex flex-col"><label>كود الفرع</label><input id="branch-code" value="${b?.branch_code||nextBranchCodePreview()}" readonly class="p-2.5 bg-gray-100 border rounded-lg"></div>
```

مهم:
- في وضع التعديل يبقى الكود الحالي.
- في الإضافة يظهر Preview مثل `BR-2`.
- Production يعيد حساب الكود عند الحفظ، لذلك الـPreview ليس مصدر الحقيقة ولا توجد مخاطرة من فتح المودال فترة طويلة أو تنفيذ حفظ متزامن.

---

## 6. إدماج المركبات في تقرير الفروع دون كسر العقد

### العقد المثبت
`setup-van-branch` الحالي ينشئ:
`VAN-<vehicle_code>`

وProduction الحالية تحتوي بالفعل على:
- 3 branches active
- 2 منها mobile vehicle branches
- 2 active mobile-stock vehicles

إذن لا حاجة لإضافة Branch Engine جديد ولا جدول جديد.

### الدلالة الصحيحة
المركبة:
**Mobile Stock Context / Container**

وليست:
**Branch Master حقيقي**

ولا تصبح هي صاحب الحيازة القانونية/التشغيلية النهائية للبضاعة.

في DirectSale:
- موقع المخزون المتنقل = mobile branch المرتبط بالمركبة.
- Custody actor = المندوب/السائق التشغيلي وفق العقد التشغيلي.
- انتقال الحيازة النهائي = إلى العميل عند البيع، وليس إلى المركبة أو أي وعاء نقل.

### PATCH-320-BR-03
في السطر الحالي **7037** داخل `RW_Branches.renderTable`، ابحث فقط عن:

```js
<td class="p-3 font-semibold">${b.name||''}</td>
```

واستبدله بـ:

```js
<td class="p-3 font-semibold">${b.name||''}${/^VAN-/i.test(String(b.branch_code||'')) ? '<div style="margin-top:4px;display:inline-block;padding:3px 8px;border-radius:999px;background:#eff6ff;color:#2563eb;font-size:11px;font-weight:800">🚚 مركبة متنقلة • وعاء مخزون • الحيازة التشغيلية على المندوب</div>' : ''}</td>
```

لا تغير:
- company filtering
- row onclick
- edit/delete behavior
- branch data loader

هذا مجرد **عرض دلالي** لكي لا يقرأ مراقب النظام سجل السيارة على أنه فرع ثابت.

---

## 7. Fleet: ما تم إثباته قبل أي تعديل

Current Mother عند:
`RW_FleetManagement.loadVehicles`

السطران **28494–28495** يحتويان بالفعل على:
- `expected_km_per_liter`
- `operational_condition`
- `route_capability`

وهذه البيانات أصبحت موجودة فعليًا في Production `fleet_query` بعد migration:
`20260923_fleet_query_vehicle_operational_fields_projection_fix.sql`

لذلك:
**لا تعدل خلايا عرض الكفاءة والحالة/المسار.**
الجزء ثبت أنه أصلح بالفعل، وإعادة بنائه الآن ستكون تكرارًا غير مبرر.

---

## 8. Root Cause — Fleet Edit

Current Mother:
- backend: `fleet_command_atomic` يحتوي `VEHICLE_UPDATE`
- Production E2E ثبت نجاحه.
- UI الحالي يعرض المركبات، لكن الزر الحالي/onclick للصف يفتح `openVehicleDetail` فقط.
- لا توجد `openVehicleEdit` في الـAPI.

إذن النقص الحقيقي:
**Consumer/UI capability missing**
وليس backend contract missing.

---

## 9. Production E2E — VEHICLE_UPDATE

تم تنفيذ اختبار داخل Transaction ثم Rollback كامل.

### CREATE
- VEHICLE_CREATE = PASS

### UPDATE
تم تعديل:
- model
- license_plate
- max_weight_kg
- cargo_length_m
- cargo_width_m
- cargo_height_m
- max_volume_m3
- operational_condition
- route_capability
- expected_km_per_liter
- ownership_type

### النتيجة المثبتة
```
max_volume_m3 = 5.2800
max_weight_kg = 6000
ownership_type = RentedMonthly
route_capability = Regional
expected_km_per_liter = 12
operational_condition = Excellent
```

### Rollback
PASS

وبعد الإغلاق:
- QA vehicles = 0
- QA branches = 0
- QA fleet operations = 0

---

## 10. التعديل الجراحي المطلوب في Mother — Fleet Edit

### PATCH-320-FL-01
**الملف:** `erp-frontend/companies/company-1/main.html`

في `RW_FleetManagement.loadVehicles`، السطر الحالي **28492**:

ابحث عن:

```js
'<td class="p-3"><strong>'+esc(v.vehicle_code)+'</strong><div class="text-xs text-slate-400">'+esc(v.model||'')+'</div></td><td class="p-3">'+esc(v.license_plate)+'</td>'+
```

واستبدله فقط بـ:

```js
'<td class="p-3"><strong>'+esc(v.vehicle_code)+'</strong><div class="text-xs text-slate-400">'+esc(v.model||'')+'</div><button type="button" title="تعديل المركبة" onclick="event.stopPropagation();RW_FleetManagement.openVehicleEdit(\''+v.id+'\')" class="mt-2 px-2 py-1 rounded-lg bg-indigo-50 text-indigo-700 text-xs font-bold"><i class="fa-solid fa-pen"></i> تعديل</button></td><td class="p-3">'+esc(v.license_plate)+'</td>'+
```

يحافظ هذا على:
- row onclick الحالي = فتح التفاصيل.
- زر التعديل = يمنع bubbling ثم يفتح Edit.
- لا يوجد تغيير في جدول البيانات نفسه.

---

## 11. PATCH-320-FL-02 — إضافة دالة واحدة فقط

في `RW_FleetManagement` ابحث عن العلامة الدقيقة:

```js
async function openVehicleForm(){
```

أضف **مباشرة قبلها** الدالة التالية كاملة:

```js
async function openVehicleEdit(id){
  if(!id) return;
  if(!canManage()) throw new Error('ليس لديك صلاحية تعديل المركبات');
  state.selectedVehicleId=id;
  var d=await query('vehicle_detail',{vehicle_id:id});
  var v=d.vehicle||{};
  if(!v.id) throw new Error('المركبة غير موجودة');
  await modal('تعديل المركبة',
    '<div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;text-align:right">'+
    input('fve-model','الموديل',v.model||'')+input('fve-plate','رقم اللوحة',v.license_plate||'')+
    input('fve-type','نوع المركبة',v.vehicle_type||'Delivery')+input('fve-mode','نمط التشغيل',v.operation_mode||'Mixed')+
    selectInput('fve-owner','الملكية',v.ownership_type||'Owned',[['Owned','مملوكة للشركة'],['RentedPerTrip','مستأجرة بالنقلة'],['RentedMonthly','مستأجرة بالشهر'],['Other','أخرى']])+input('fve-weight-ton','السعة الوزنية (طن)',Number(v.max_weight_kg||0)/1000,'number')+
    input('fve-l','طول صندوق المركبة (م)',v.cargo_length_m||'','number')+input('fve-w','عرض صندوق المركبة (م)',v.cargo_width_m||'','number')+input('fve-h','ارتفاع صندوق المركبة (م)',v.cargo_height_m||'','number')+
    selectInput('fve-condition','الحالة التشغيلية',v.operational_condition||'Good',[['Excellent','ممتازة'],['Good','جيدة'],['Fair','متوسطة'],['Poor','ضعيفة']])+selectInput('fve-route','قدرة المسار',v.route_capability||'Any',[['LocalOnly','محلية / قريبة فقط'],['Regional','إقليمية / متوسطة'],['LongHaul','بعيدة / مسافات طويلة'],['Any','مناسبة لكل المسارات']])+
    input('fve-eff','الكفاءة المتوقعة (كم/لتر)',v.expected_km_per_liter||'','number')+input('fve-year','سنة الصنع',v.model_year||'','number')+input('fve-vin','VIN / Chassis',v.vin||'')+input('fve-fuel','نوع الوقود',v.fuel_type||'Diesel')+
    input('fve-registration','تاريخ التسجيل',v.registration_date||'','date')+input('fve-commission','تاريخ بدء التشغيل',v.commission_date||'','date')+input('fve-retirement','تاريخ الإحالة',v.retirement_date||'','date')+input('fve-engine','رقم المحرك',v.engine_number||'')+input('fve-color','اللون',v.color||'')+input('fve-tank','سعة خزان الوقود (لتر)',v.fuel_tank_capacity_l||'','number')+
    '<div style="grid-column:1/3;display:grid;gap:10px"><textarea id="fve-notes" class="rw-input" style="height:80px;padding:10px" placeholder="ملاحظات">'+esc(v.notes||'')+'</textarea><label style="display:flex;align-items:center;gap:8px;font-weight:800"><input id="fve-refrigerated" type="checkbox" '+(v.refrigerated?'checked':'')+'> مبردة</label><label style="display:flex;align-items:center;gap:8px;font-weight:800"><input id="fve-mobile" type="checkbox" '+(v.mobile_stock_enabled!==false?'checked':'')+'> تفعيل مخزون المركبة</label></div>'+
    '</div>',
    async function(){
      var tons=Number(val('fve-weight-ton')),l=Number(val('fve-l')),w=Number(val('fve-w')),h=Number(val('fve-h'));
      if(!val('fve-model')||!val('fve-plate')) throw new Error('الموديل ورقم اللوحة مطلوبان');
      if(!(tons>0)) throw new Error('السعة الوزنية يجب أن تكون أكبر من صفر');
      if(!(l>0&&w>0&&h>0)) throw new Error('أبعاد صندوق المركبة الثلاثة مطلوبة');
      var eff=val('fve-eff'),year=val('fve-year'),tank=val('fve-tank');
      await command('VEHICLE_UPDATE',{
        vehicle_id:id,
        model:val('fve-model'),
        license_plate:val('fve-plate'),
        vehicle_type:val('fve-type')||'Delivery',
        operation_mode:val('fve-mode')||'Mixed',
        ownership_type:val('fve-owner')||'Owned',
        max_weight_kg:tons*1000,
        max_volume_m3:l*w*h,
        cargo_length_m:l,
        cargo_width_m:w,
        cargo_height_m:h,
        operational_condition:val('fve-condition')||'Good',
        route_capability:val('fve-route')||'Any',
        expected_km_per_liter:eff||null,
        model_year:year||null,
        vin:val('fve-vin')||null,
        fuel_type:val('fve-fuel')||null,
        refrigerated:byId('fve-refrigerated').checked,
        mobile_stock_enabled:byId('fve-mobile').checked,
        registration_date:val('fve-registration')||null,
        commission_date:val('fve-commission')||null,
        retirement_date:val('fve-retirement')||null,
        engine_number:val('fve-engine')||null,
        color:val('fve-color')||null,
        fuel_tank_capacity_l:tank||null,
        notes:val('fve-notes')||null
      });
      await openVehicleDetail(id);
      showToast('تم تعديل المركبة بنجاح','success');
    },'حفظ التعديل');
}
```

هذه الدالة لا تعيد إنشاء Fleet.
هي مجرد Consumer للـcontract الموجود:
`VEHICLE_UPDATE`.

---

## 12. PATCH-320-FL-03 — تصدير الدالة

في `var api = {` ابحث عن السطر الدقيق:

```js
openVehicleDetail: openVehicleDetail,
```

أضف تحته مباشرة:

```js
openVehicleEdit: openVehicleEdit,
```

ولا تعدل بقية الـAPI.

---

## 13. ما لم يتم تعديله عمدًا

لم يتم تغيير:
- Fleet query
- fleet_command_atomic
- `post_stock_movement`
- setup_van_stock
- mobile branch contract
- DirectSale contract
- DirectReturn
- runsheet engine
- picking
- loading
- delivery
- returns
- settlement
- reservation
- voucher lifecycle

السبب:
هذه نقاط ثبت إغلاقها تاريخيًا وحاليًا، ولا يوجد evidence جديد يبرر إعادة فتحها.

---

## 14. Production source synchronization

تم إضافة المصدر الحالي الفعلي لـProduction Edge capabilities التي لم يكن لها current source canonical واضح:

- `Current/Edge_Functions/save-branch`
- `Current/Edge_Functions/delete-branch`

وهما الآن متزامنان مع Production:
- save-branch v5
- delete-branch v4

هذه ليست Edge Functions جديدة؛ هي source canonical لنفس capabilities المنشورة.

---

## 15. E2E / Verification Matrix

| الاختبار | النتيجة |
|---|---|
| Root cause `is_owner` absence | PROVEN |
| save-branch v5 deployed | PASS |
| delete-branch v4 deployed | PASS |
| Numeric Branch generator | PASS |
| Ignore VAN codes in BR counter | PASS |
| Vehicle detail query current fields | PASS |
| `VEHICLE_UPDATE` Production transaction | PASS |
| max volume recomputation | PASS |
| Operational condition | PASS |
| Route capability | PASS |
| Expected km/l | PASS |
| Ownership update | PASS |
| QA cleanup | PASS |
| QA vehicles remaining | 0 |
| QA branches remaining | 0 |
| QA fleet operations remaining | 0 |
| New Edge Functions | 0 |
| Mother main.html assistant write | 0 |
| Authenticated Browser E2E | OPEN — owner must apply Mother patch |
| Served artifact verification | OPEN |

---

## 16. لماذا لم أعتبر المهمة 100% Browser Closed

Production root causes والـbackend contracts تم تنفيذها والتحقق منها.

لكن:
- `main.html` ملف محمي وملكية تعديله للمستخدم.
- لا يوجد authenticated browser session من هذه الجلسة.
- لذلك لا يجوز تحويل Production/RPC PASS إلى Browser PASS.

إغلاق المتصفح النهائي يتطلب:
1. تطبيق PATCH-320-BR-01..03.
2. تطبيق PATCH-320-FL-01..03.
3. JS parse كامل لـMother.
4. Publish.
5. مطابقة served artifact مع Git.
6. اختبار:
   - إضافة فرع → Preview BR-N → حفظ → ظهور الفرع.
   - فتح مركبة → تعديل.
   - تغير الكفاءة.
   - تغير الحالة التشغيلية.
   - تغير المسار.
   - بقاء صف المركبة ظاهرًا في تقرير الفروع كـmobile context.
   - بقاء صف الفرع الثابت مميزًا عن mobile vehicle.
7. Capture Production snapshot جديد.

---

## 17. Self-Audit

### ما تم إثباته
- سبب `سياق الشركة غير صالح` في save-branch = SELECT لعمود `is_owner` غير الموجود.
- save-branch Production v5 أصبح company-scoped ويولد `BR-N` رقميًا.
- delete-branch لا يحمل نفس العيب.
- Fleet backend update capability موجودة وليست مفقودة.
- جدول Fleet الحالي يعرض fields التشغيلية بالفعل؛ لا حاجة لتعديلها.
- Fleet UI ينقصه Consumer واحد فعلي: `openVehicleEdit`.
- Vehicle mobile branch موجود في Production كـVAN-prefixed branch context.
- Production الحالية لا تحتوي QA vehicle/branch remnants.
- لا يوجد Edge Function جديد.

### ما لم يتم إثباته
- authenticated Browser E2E من المستخدم الفعلي.
- Served Mother artifact بعد تطبيق patch.

### ما تم إصلاحه
- save-branch actor lookup
- numeric branch code generation
- delete-branch actor lookup
- canonical Git source for both existing Edge functions
- Owner Patch exact anchors for Branch/Fleet UI

### ما لم تتم إعادة إصلاحه
- Fleet query projection
- Fleet command gateway
- mobile stock contract
- operational PWAs
- inventory movement engine

---

## 18. تعليمات الاستئناف للجلسة القادمة

ابدأ من هذه السلسلة بالترتيب:

1. تحقق من Mother HEAD:
`6d505d30dcad981932b3f3562ea9bb37901fecb4`

2. تحقق من main blob:
`8c3d6b05fd6a94a6b488f12b29da85ae888f70bc`

3. لا تعيد قراءة Fleet history من أجل إعادة البناء؛ استخدمها فقط لفهم العقد.

4. طابق أولًا:
CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE.

5. افتح فقط:
- `RW_Branches.openModal`
- `RW_Branches.renderTable`
- `RW_FleetManagement.loadVehicles`
- `RW_FleetManagement.openVehicleForm`
- `var api`

6. طبق PATCH-320-BR-01..03.

7. طبق PATCH-320-FL-01..03.

8. لا تعدل خلايا:
`expected_km_per_liter`
`operational_condition`
`route_capability`
لأنها مغلقة من Production.

9. لا تنشئ Edge Function جديدة.

10. إذا ظهر خطأ جديد:
FOUND → ROOT CAUSE → HISTORY → CURRENT PRODUCTION → SURGICAL FIX → TEST → DEPLOY → VERIFY → CLOSE.

11. لا تعتبر المهمة Browser Closed حتى يتم:
Owner Patch → Parse → Publish → Served SHA → Authenticated E2E → Fresh Production Snapshot.

---

## 19. النتيجة

**Production Branch Context Fix = CLOSED**

**Production Branch Code Generator = CLOSED**

**Fleet VEHICLE_UPDATE backend = CLOSED**

**Fleet operational-field projection = CLOSED**

**Mother Branch UI patch = READY FOR OWNER**

**Mother Fleet Edit UI patch = READY FOR OWNER**

**Mobile Vehicle/Branch semantic presentation = READY FOR OWNER**

**Authenticated Browser E2E = OPEN**

**Overall task = FUNCTIONALLY IMPLEMENTED, BROWSER VERIFICATION PENDING**
