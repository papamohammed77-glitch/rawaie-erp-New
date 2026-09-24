# تقرير 340 — الإغلاق الجنائي لتكامل الأذونات المخزنية مع ربط مندوب البيع المباشر بالمركبة — 2026-09-24

## 1. نطاق التنفيذ

تم إيقاف أي مسار سابق والبدء من آخر حالة مثبتة، مع اعتبار التقارير التاريخية أدلة استرشادية فقط.

تمت مراجعة:
- `doc/Draft/Reprots/MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`
- `CURRENT_STATE.md`
- أحدث تقارير Report337 / Report338 / Report339
- أحدث commits في مستودع النظام الأم، مع parent commits
- المصدر الحالي للـMother
- المصدر الحالي لتطبيق الأذونات المخزنية
- المصدر الحالي لتطبيق `van-sales`
- Production Supabase
- Production RPCs / Edge Functions
- Production data / audit / fleet assignments
- اختبار E2E داخل Production Transaction مع rollback.

## 2. الهوية الحالية المعتمدة

### System Git
- Repository: `papamohammed77-glitch/rawaie-erp-New`
- HEAD قبل إضافة هذا التقرير: `9ce3652fb144c75b98cb77d784d1a1d276d4464c`
- Parent: `223c53e35384efaba223999d2608d7c3f83b2eec`
- Commit 223c53: تحديث `setup-van-branch` لربط مندوب البيع المباشر بالمركبة من Master Assignment.
- Commit 9ce365: تنظيف Fixture تجريبي قديم من Production.

### Mother Git
- Repository: `papamohammed77-glitch/erp-frontend`
- أحدث HEAD الذي تم التحقق منه: `1c7f2596e7543a1ea4684d84171804b3e4d5a4d8`
- Parent: `cd67be47d1a36e42b3c5b8738d8ba1475f95ef86`
- `main.html` blob: `810e4f5440f5975f55099a124deb42b086a49183`
- `main.html` لم يتم تعديله.
- commit `cd67be47...` هو آخر تعديل فعلي على Mother قبل forensic bot، ويحتوي بالفعل على PATCH-339 الخاصة بـDirectSale Master binding.

### Standalone Vouchers
- File: `companies/company-1/warehouse/vouchers.html`
- Current blob: `287f9900efdf1ee595f6537e9d230ef06e347c06`
- لم يتم تعديل الملف تنفيذًا لشرط المالك.
- آخر commit فعلي للمصدر قبل هذه الجلسة: `53b254de274af504022d0acf13becc40378bd4aa`.
- الملف الحالي هو مصدر الخطأ.

### Standalone Van Sales
- File: `companies/company-1/sales/van-sales.html`
- Current blob: `8d61382a8e0025a0d079e71dd94f33d106d9088e`
- آخر commit: `36e521f78c8507e431bb9eb780269612c2d6cbf0`
- التطبيق يعتمد على `setup-van-branch` لاكتشاف المخزن المتنقل.

## 3. Production forensic findings

### 3.1 Master Assignment الحالي
Production تحتوي على Master assignment واحد Active/Primary:

- Assignment: `861ecd15-5ab6-4e53-8995-5d2d97570c3e`
- Direct Sales Rep: `vansales@rawaea.com`
- Rep ID: `111b0730-a977-4d11-bcd0-2427b178a9e5`
- Vehicle: `CHV-2025-01`
- Vehicle ID: `69b08188-60ee-43af-9644-e1626a85bfa0`
- Start: `2026-09-24 18:57:12.987021+00`
- Primary: true
- End: null.

### 3.2 المركبة الحقيقية
المركبة `CHV-2025-01`:
- Active = true
- mobile_stock_enabled = true
- mobile_branch_id = `2fffcf58-be04-4599-a289-8791362398ff`
- mobile branch code = `VAN-CHV-2025-01`
- `driver_id = NULL`

هذه النقطة تثبت أن استعمال `vehicles.driver_id` كمصدر علاقة لمندوب البيع المباشر أصبح غير صالح لهذا العقد.

### 3.3 السبب الجذري للخطأ في Vouchers

في `vouchers.html` الحالي، DirectSale كان يستخدم:

`vehicle.driver_id === selectedRep.id`

في:
- `pickArr()`
- `pickSelect()`
- `submit()`

وبالتالي فإن المركبة المرتبطة رسميًا عبر:

`fleet_vehicle_sales_rep_assignments`

لا تظهر عند اختيار مندوب البيع المباشر، لأن العلاقة الجديدة مستقلة عن `vehicle.driver_id`.

### 3.4 السبب الجذري الثاني في Van Sales

Production `setup-van-branch` كان يفسر:

`driver_email → users.id → vehicles.driver_id`

بينما المركبة الحالية للمندوب:
- مرتبطة بالـMaster Assignment
- و`vehicles.driver_id = NULL`

لذلك كان `van-sales` معرضًا لفشل اكتشاف مخزن السيارة.

## 4. ما تم تنفيذه فعليًا في Production

### 4.1 بدون إنشاء Edge Function جديدة
تم تحديث نفس function الموجودة:

`setup-van-branch`

من النسخة 4 إلى النسخة 5.

Production:
- Slug: `setup-van-branch`
- Version: 5
- Status: ACTIVE
- verify_jwt = true
- Deployment SHA256: `71986370ae16e744332bc93f2b533dddf89433ef2cf1d34445da9c474e2c3f25`

### 4.2 السلوك الجديد

عند استدعاء `setup-van-branch`:

إذا كان `driver_email` يعود إلى مستخدم دوره `مندوب بيع مباشر`:
1. يتم البحث في `fleet_vehicle_sales_rep_assignments`
2. يثبت Active + Primary + end_at IS NULL
3. يتم استخراج `vehicle_id`
4. يتم تحميل المركبة من `vehicles` مع company scope
5. يستمر إنشاء/الربط مع `mobile_branch_id`
6. يستمر `setup_van_stock`
7. يعود `resolution_mode = direct_sales_rep_assignment`

أما غير مندوب البيع المباشر:
- يبقى fallback التاريخي القائم على `vehicle.driver_id`.

إذن تم فصل:
- Direct Sales Rep identity
- Driver identity

بدون كسر مسار السائقين التقليدي.

### 4.3 لم يتم تغيير
- `fleet_query`
- `fleet_command_atomic`
- `post_stock_movement`
- `create-stock-voucher`
- `create_manual_stock_voucher_atomic`
- `DirectReturn` semantics
- دورة المخزون المركزية.

## 5. Production CREATE / SEND E2E

تم تشغيل اختبار Transaction حقيقي على Production ثم Rollback.

### READ
استدعاء:

`fleet_query('direct_sales_rep_assignments')`

بهوية مستخدم الأذونات:
`vouchers@rawaea.com`

النتيجة:
- success = true
- Row موجود
- Rep = `vansales@rawaea.com`
- Vehicle = `CHV-2025-01`

وتم اختبار القراءة كذلك بهوية مندوب البيع المباشر نفسه.

### CREATE DirectSale
تم إنشاء إذن مؤقت داخل Transaction:

- type = DirectSale
- source = BR-01
- target vehicle = NULL
- rep_id = `111b0730...`
- operation_id = `QA-E2E-20260924-DS-001`

Production أعادت:

- success = true
- voucher = `IN-3`
- status = Draft
- `to_id = 69b08188...`
- `custodian_user_id = 111b0730...`

أي أن Production نفسها حلت المركبة من Rep Master بدون `to_id` في الطلب.

### SEND
قبل الإرسال:
- stock qty في BR-01 للصنف 1001 = 11

بعد SEND:
- stock qty في BR-01 = 10
- movement_count = 1
- custody_value = 1
- custody_ledger = true
- status = Sent
- to_id = `CHV-2025-01`

### REPLAY
إعادة نفس SEND أعادت:
- success = true
- duplicate = true
- movement_count = 1

وفي نهاية الاختبار تم تنفيذ:
`ROLLBACK`

ولم يترك الاختبار أي بيانات دائمة.

## 6. تنظيف Production

تم إثبات أن:

`FRD-2025-02 TEST`

كان Fixture/QA قديمًا، لأن:
- اسمه صريح TEST
- لا يوجد له vouchers
- لا يوجد له runsheets
- لا توجد assignments
- لا توجد fuel/maintenance/incidents/contracts
- لا توجد أوامر أو عمليات مالية مرتبطة
- كان لديه فقط stock fixture rows وvehicle status history وaudit records مرتبطة بإنشائه.

تم حذف:
- المركبة التجريبية
- المخزن/الفرع المتنقل التجريبي
- stock fixture rows الخاصة به
- vehicle status history الخاصة به
- audit records الخاصة بإنشائه.

Production بعد التنظيف:
- vehicles = 1
- branches = 3
- test vehicle = 0
- test branch = 0
- test audit references = 0
- test stock rows = 0.

## 7. ملاحظة مهمة عن Vouchers.html

لم يتم تعديل:
`erp-frontend/companies/company-1/warehouse/vouchers.html`

لأن هذا الملف owner-controlled حسب التعليمات.

لذلك:

### Production Core
CLOSED

### Van Sales backend integration
CLOSED

### Vouchers source integration
PATCH READY — OWNER APPLY REQUIRED

### Authenticated Browser E2E
UNVERIFIED

ولا يجوز تحويل Browser E2E إلى PASS دون متصفح مصادق فعليًا.

# 8. التعديل الجراحي المطلوب في Vouchers.html

## PATCH V-01 — App.refs

ابحث بالضبط عن:

`refs:{branches:[],vehicles:[],suppliers:[],reps:[],supplierBranchMap:{}}`

وحددها داخل الكائن `var App={...}`.

احذف السطر واستبدله بالكامل بـ:

```javascript
refs:{
    branches:[],
    vehicles:[],
    suppliers:[],
    reps:[],
    supplierBranchMap:{},
    directSalesAssignments:[],
    repVehicleMap:Object.create(null),
    vehicleRepMap:Object.create(null)
},
```

---

## PATCH V-02 — loadRefs()

ابحث بالضبط عن:

`loadRefs:function(){`

واحذف الدالة كاملة حتى `},` التي تسبق:

`updateConnection:function(live)`

واستبدلها بالكامل:

```javascript
loadRefs:function(){
    var s=this,
        pageSize=500;

    function readAll(makeQuery){
        var rows=[],
            offset=0;

        function readPage(){
            return makeQuery()
                .range(offset,offset+pageSize-1)
                .then(function(r){
                    if(r.error){
                        throw r.error;
                    }

                    var page=r.data||[];

                    rows=rows.concat(page);

                    if(page.length<pageSize){
                        return rows;
                    }

                    offset+=pageSize;

                    return readPage();
                });
        }

        return readPage();
    }

    return Promise.all([
        readAll(function(){
            return supabase
                .from('branches')
                .select('id,branch_code,name,company_id,is_active')
                .eq('company_id',s.company)
                .eq('is_active',true)
                .order('name')
                .order('id');
        }),

        readAll(function(){
            return supabase
                .from('vehicles')
                .select('id,vehicle_code,license_plate,model,driver_id,status,mobile_branch_id,mobile_stock_enabled')
                .eq('company_id',s.company)
                .eq('status','Active')
                .order('vehicle_code')
                .order('id');
        }),

        readAll(function(){
            return supabase
                .from('suppliers')
                .select('id,supplier_code,name,phone,is_active')
                .eq('company_id',s.company)
                .eq('is_active',true)
                .order('name')
                .order('id');
        }),

        readAll(function(){
            return supabase
                .from('users')
                .select('id,name,email,phone,role,status,default_branch_id,allowed_branch_ids')
                .eq('company_id',s.company)
                .eq('status','Active')
                .eq('role','مندوب بيع مباشر')
                .order('name')
                .order('id');
        }),

        readAll(function(){
            return supabase
                .from('purchase_orders')
                .select('supplier_id,branch_id')
                .eq('company_id',s.company)
                .not('supplier_id','is',null)
                .order('created_at')
                .order('id');
        })
    ]).then(function(r){

        s.refs.branches=r[0]||[];
        s.refs.vehicles=r[1]||[];
        s.refs.suppliers=r[2]||[];
        s.refs.reps=r[3]||[];
        s.refs.supplierBranchMap={};

        (r[4]||[]).forEach(function(x){
            if(x.supplier_id&&x.branch_id){
                (s.refs.supplierBranchMap[x.branch_id]||
                    (s.refs.supplierBranchMap[x.branch_id]={})
                )[x.supplier_id]=1;
            }
        });

        return supabase.rpc(
            'fleet_query',
            {
                p_company_id:s.company,
                p_view:'direct_sales_rep_assignments',
                p_payload:{},
                p_actor_user_id:null
            }
        );
    }).then(function(fr){

        if(fr.error){
            throw fr.error;
        }

        var rows=
            fr.data &&
            Array.isArray(fr.data.rows)
                ?fr.data.rows
                :[];

        s.refs.directSalesAssignments=rows;
        s.refs.repVehicleMap=
            Object.create(null);
        s.refs.vehicleRepMap=
            Object.create(null);

        rows.forEach(function(a){

            var repId=
                String(
                    a.direct_sales_rep_id||''
                ).trim();

            var vehicleId=
                String(
                    a.vehicle_id||''
                ).trim();

            if(!repId||!vehicleId){
                return;
            }

            var vehicle=
                (s.refs.vehicles||[])
                    .find(function(v){
                        return String(v.id)===vehicleId;
                    });

            if(!vehicle){
                return;
            }

            if(
                s.refs.repVehicleMap[repId] &&
                String(
                    s.refs.repVehicleMap[repId]
                )!==vehicleId
            ){
                throw new Error(
                    'يوجد أكثر من مركبة أساسية لمندوب البيع المباشر: '+
                    repId
                );
            }

            if(
                s.refs.vehicleRepMap[vehicleId] &&
                String(
                    s.refs.vehicleRepMap[vehicleId]
                )!==repId
            ){
                throw new Error(
                    'يوجد أكثر من مندوب أساسي للمركبة: '+
                    vehicleId
                );
            }

            s.refs.repVehicleMap[repId]=vehicleId;
            s.refs.vehicleRepMap[vehicleId]=repId;
        });

        return s.refs;
    });
},
```

---

## PATCH V-03 — helper جديد

ابحث بالضبط عن نهاية:

`vehicleBranch:function(v){`

واحرص أن يكون الإدراج مباشرة قبل:

`pickArr:function(key){`

أضف هذه الدالة كاملة:

```javascript
syncDirectSaleVehicleWithRep:function(repId){

    var s=this;

    if(s.type!=='DirectSale'){
        return true;
    }

    var rep=
        (s.refs.reps||[])
            .find(function(r){
                return String(r.id)===
                    String(repId||'');
            });

    var sourceBranch=
        (s.refs.branches||[])
            .find(function(b){
                return String(b.id)===
                    String(
                        (RW_UI.byId('wsFrom')||{})
                            .value||
                        ''
                    );
            });

    var vehicleId=
        s.refs.repVehicleMap[
            String(repId||'')
        ]||
        '';

    var vehicle=
        (s.refs.vehicles||[])
            .find(function(v){
                return String(v.id)===
                    String(vehicleId);
            });

    if(
        !rep||
        !sourceBranch||
        !s.allowedBranch(rep,sourceBranch)||
        !vehicle||
        !s.vehicleBranch(vehicle)
    ){

        RW_UI.byId('wsTo').value='';
        RW_UI.byId('wsToSearch').value='';
        RW_UI.byId('wsToSearch')
            .removeAttribute('readonly');

        return false;
    }

    RW_UI.byId('wsTo').value=
        vehicle.id;

    RW_UI.byId('wsToSearch').value=
        vehicle.vehicle_code||
        vehicle.license_plate||
        vehicle.model||
        '';

    RW_UI.byId('wsToSearch')
        .setAttribute(
            'readonly',
            'readonly'
        );

    return true;
},
```

---

## PATCH V-04 — DirectSale reps

داخل:

`pickArr:function(key){`

ابحث بالضبط عن:

`if(key==='wsRep'){`

واستبدل هذا الجزء كاملًا حتى `}` الخاصة بالـblock بـ:

```javascript
if(key==='wsRep'){

    return (
        s.refs.reps||[]
    )
    .filter(function(r){

        if(!b){
            return false;
        }

        if(
            s.type==='DirectSale' &&
            !s.refs.repVehicleMap[
                String(r.id)
            ]
        ){
            return false;
        }

        return (
            s.allowedBranch(
                s.user,
                b
            ) &&
            s.allowedBranch(
                r,
                b
            )
        );
    });
}
```

---

## PATCH V-05 — DirectSale vehicle candidates

داخل `pickArr:function(key)` ابحث بالضبط عن:

`if(
        key==='wsTo' &&
        s.type==='DirectSale'
    ){`

احذف الـblock كاملًا حتى قبل:

`if(
        key==='wsTo' &&
        s.type==='DirectReturn'
    ){`

واستبدله:

```javascript
if(
    key==='wsTo' &&
    s.type==='DirectSale'
){

    var rid=
        (RW_UI.byId('wsRep')||{})
            .value||
        '';

    var mappedVehicleId=
        rid
            ?s.refs.repVehicleMap[
                String(rid)
            ]||''
            :'';

    return (
        s.refs.vehicles||[]
    )
    .filter(function(v){

        var vb=
            s.vehicleBranch(v);

        var repId=
            s.refs.vehicleRepMap[
                String(v.id)
            ]||
            '';

        var rep=
            (s.refs.reps||[])
                .find(function(r){
                    return String(r.id)===
                        String(repId);
                });

        return (
            v.status==='Active' &&
            v.mobile_stock_enabled!==false &&
            !!vb &&
            !!b &&
            s.allowedBranch(
                s.user,
                b
            ) &&
            !!rep &&
            s.allowedBranch(
                rep,
                b
            ) &&
            (
                !rid ||
                String(v.id)===
                    String(mappedVehicleId)
            )
        );
    });
}
```

---

## PATCH V-06 — pickSelect(): wsTo DirectSale

داخل `pickSelect:function(key,id){`

ابحث بالضبط عن:

`else if(
        key==='wsTo' &&
        s.type==='DirectSale'
    ){`

استبدل الـblock كاملًا:

```javascript
}else if(
    key==='wsTo' &&
    s.type==='DirectSale'
){

    var vehicleRepId=
        s.refs.vehicleRepMap[
            String(x.id)
        ]||
        '';

    var vehicleRep=
        (s.refs.reps||[])
            .find(function(rp){
                return String(rp.id)===
                    String(vehicleRepId);
            });

    var sourceBranch=
        (s.refs.branches||[])
            .find(function(bb){
                return String(bb.id)===
                    String(
                        (RW_UI.byId('wsFrom')||{})
                            .value||
                        ''
                    );
            });

    if(
        !vehicleRep ||
        !sourceBranch ||
        !s.allowedBranch(
            vehicleRep,
            sourceBranch
        )
    ){

        RW_UI.toast(
            'المركبة غير مربوطة بمندوب بيع مباشر صالح لهذا الفرع',
            'error'
        );

        RW_UI.byId(key).value='';
        RW_UI.byId(key+'Search').value='';

        return;
    }

    RW_UI.byId('wsRep').value=
        vehicleRep.id;

    RW_UI.byId('wsRepSearch').value=
        vehicleRep.name||
        vehicleRep.email||
        '';

    RW_UI.byId('wsRepSearch')
        .setAttribute(
            'readonly',
            'readonly'
        );

    s.syncDirectSaleVehicleWithRep(
        vehicleRep.id
    );

```

---

## PATCH V-07 — pickSelect(): اختيار مندوب DirectSale

ابحث بالضبط عن:

`if(key==='wsRep'){
        RW_UI.byId(key+'Search').value=
            x.name||x.email;
`

استبدل هذا الـbranch كاملًا بـ:

```javascript
if(key==='wsRep'){

    RW_UI.byId(key+'Search').value=
        x.name||
        x.email||
        '';

    if(
        s.type==='DirectSale'
    ){

        var synced=
            s.syncDirectSaleVehicleWithRep(
                x.id
            );

        if(!synced){
            RW_UI.byId('wsRep').value='';
            RW_UI.byId('wsRepSearch').value='';

            RW_UI.toast(
                'لا توجد مركبة نشطة معينة لهذا المندوب في إدارة الأسطول',
                'error'
            );

            return;
        }
    }

```

---

## PATCH V-08 — تغيير الفرع في DirectSale

داخل `pickSelect:function(key,id){` ابحث بالضبط عن:

`if(
        key==='wsFrom' &&
        s.type==='DirectSale'
    ){`

استبدل الـblock كاملًا:

```javascript
if(
    key==='wsFrom' &&
    s.type==='DirectSale'
){

    var selectedRepId=
        (RW_UI.byId('wsRep')||{})
            .value||
        '';

    var selectedRep=
        (s.refs.reps||[])
            .find(function(rp){
                return String(rp.id)===
                    String(selectedRepId);
            });

    var keepRep=
        !!selectedRep &&
        s.allowedBranch(
            selectedRep,
            x
        );

    if(!keepRep){

        RW_UI.byId('wsRep').value='';
        RW_UI.byId('wsRepSearch').value='';

        RW_UI.byId('wsTo').value='';
        RW_UI.byId('wsToSearch').value='';
        RW_UI.byId('wsToSearch')
            .removeAttribute('readonly');

    }else{

        s.syncDirectSaleVehicleWithRep(
            selectedRep.id
        );
    }

    RW_UI.byId('wsRepSearch')
        .removeAttribute('readonly');
}
```

---

## PATCH V-09 — submit(): عدم إجبار DirectSale على to_id القديم

داخل `submit:function(){` ابحث بالضبط عن:

`if(!to){
        RW_UI.toast('الوجهة مطلوبة','warning');
        return;
    }`

استبدله:

```javascript
if(
    !to &&
    this.type!=='DirectSale'
){
    RW_UI.toast(
        'الوجهة مطلوبة',
        'warning'
    );
    return;
}
```

ثم ابحث مباشرة بعده عن:

`if(this.type==='DirectSale'){`

واحذف هذا الـblock كاملًا حتى قبل:

`if(this.type==='DirectReturn'){`

واستبدله:

```javascript
if(this.type==='DirectSale'){

    var r=
        (this.refs.reps||[])
            .find(function(x){
                return String(x.id)===
                    String(rep);
            });

    var b=
        (this.refs.branches||[])
            .find(function(x){
                return String(x.id)===
                    String(fr);
            });

    var mappedVehicleId=
        this.refs.repVehicleMap[
            String(rep)
        ]||
        '';

    if(
        !r ||
        !b ||
        !this.allowedBranch(r,b) ||
        !mappedVehicleId
    ){
        RW_UI.toast(
            'مندوب البيع المباشر يجب أن تكون له مركبة نشطة معينة من إدارة الأسطول',
            'error'
        );
        return;
    }

    /*
     * Master Assignment is authoritative.
     * Any stale/manual vehicle value is reconciled
     * to the current assigned vehicle before submit.
     */
    to=mappedVehicleId;

    var v=
        (this.refs.vehicles||[])
            .find(function(x){
                return String(x.id)===
                    String(to);
            });

    if(
        !v ||
        !this.vehicleBranch(v)
    ){
        RW_UI.toast(
            'المركبة المعينة للمندوب لا تملك مخزنًا متنقلًا صالحًا',
            'error'
        );
        return;
    }

    var toField=
        RW_UI.byId('wsTo');

    if(toField){
        toField.value=to;
    }

    var toSearch=
        RW_UI.byId('wsToSearch');

    if(toSearch){

        toSearch.value=
            v.vehicle_code||
            v.license_plate||
            v.model||
            '';

        toSearch.setAttribute(
            'readonly',
            'readonly'
        );
    }
}
```

ولا يتم تعديل:
- `ft`
- `tt`
- `normalizedItems`
- `operation_id`
- `reference`
- `create-stock-voucher` call.

## 9. السلوك بعد تنفيذ PATCH V-01 إلى V-09

### DirectSale — المسار الطبيعي
1. المستخدم يختار الفرع.
2. تظهر فقط مندوبي البيع المباشر الذين لديهم Master Vehicle.
3. عند اختيار المندوب:
   - تستخرج Vouchers المركبة من `fleet_query`.
   - يتم ملء المركبة تلقائيًا.
   - يتم قفل حقل المركبة لأن مصدر الحقيقة هو Master Fleet.
4. إذا تغير الفرع:
   - يعاد فحص branch authorization.
   - يعاد مزامنة المركبة.
5. عند الحفظ:
   - يعتمد التطبيق على Master Assignment.
   - لا يعود `vehicle.driver_id` شرطًا.
6. إذا حدث stale UI value:
   - يتم تصحيحه إلى المركبة المعينة قبل الطلب.
7. Production Core يحافظ على آخر دفاع:
   - company scope
   - rep identity
   - vehicle resolution
   - stock movement centralization.

## 10. لماذا هذا هو الحل المعماري الصحيح

أصبح لدينا الفصل التالي:

Direct Sales Rep
→ fleet_vehicle_sales_rep_assignments
→ Vehicle
→ mobile_branch_id
→ Vouchers DirectSale
→ create_manual_stock_voucher_atomic
→ send_stock_voucher_atomic
→ post_stock_movement
→ stock_branches + inventory_log

بينما:

Driver
→ vehicle.driver_id

لذلك لا يعاد استخدام Driver field لتحديد Direct Sales Rep.

## 11. Van Sales التكامل

`van-sales.html` لا يحتاج تعديلًا في هذه النقطة.

التغيير تم في `setup-van-branch` لأنه هو capability gateway المستخدم فعليًا من التطبيق.

المسار أصبح:

`van-sales.html`
→ `setup-van-branch`
→ if Direct Sales Rep
→ `fleet_vehicle_sales_rep_assignments`
→ Vehicle
→ canonical mobile branch
→ `setup_van_stock`.

هذا يحافظ على تطبيقات التشغيل المنفصلة ويمنع ازدواج منطق Fleet داخل كل تطبيق.

## 12. مقارنة تنافسية مختصرة

### Odoo
Odoo يميز Fleet vehicle/driver ويعرض Vehicle/Driver/Service/Odometer كبيانات مترابطة، وليس باعتبار السائق بديلًا عن كل هوية تشغيلية. كما يدير خدمات المركبات وسجلاتها وتقارير الـodometer. المصدر الرسمي:
https://www.odoo.com/documentation/19.0/applications/hr/fleet/new_vehicle.html
https://www.odoo.com/documentation/19.0/applications/hr/fleet/service.html
https://www.odoo.com/documentation/19.0/applications/hr/fleet/odometers.html

### Dynamics 365
Transportation Management يبني عمليات النقل على planning, inbound, outbound, load building, route guides, scheduled routes. هذا يدعم فكرة أن المركبة والرحلة والحمولة والجهة التشغيلية كيانات مستقلة مرتبطة، وليس مجرد Driver field واحد.
https://learn.microsoft.com/en-us/dynamics365/supply-chain/transportation/transportation-management-overview
https://learn.microsoft.com/en-us/dynamics365/supply-chain/transportation/plan-freight-transportation-routes-multiple-stops

### SAP TM
SAP TM يتعامل مع Vehicle Resources وDrivers كموارد مستقلة، ويضع Capacity/Availability في نموذج المورد. هذا متسق مباشرة مع فصل RAWAEA بين Fleet master وDirect Sales Rep identity.
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/e3dc5400c1cc41d1bc0ae0e7fd9aa5a2/aa0deb63fb22457fa41c36a156f69157.html
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/e3dc5400c1cc41d1bc0ae0e7fd9aa5a2/bad5555bf8d042069b1ed7927e6e59e7.html

### Daftra
Daftra يطرح النقل كقدرة تشغيلية مستقلة مع تتبع الأسطول والجدولة الرقمية، كما يعلن عن تطبيقات تعمل بصورة مستقلة أو متزامنة. هذا يتوافق مع معمارية RAWAEA متعددة التطبيقات مع Mother Control Plane.
https://www.daftra.com/en/transportation/
https://www.daftra.com/features/all_features

### Manager.io
Manager يفصل Inventory Location عن المستند نفسه، ويتيح Reference وItem وQty وFrom/To، ويتيح Custom Fields على Goods Receipts وInventory Transfers وInventory Write-offs وغيرها. هذا يؤكد أهمية أن يبقى المستند المخزني قويًا من حيث الهوية والسجل والتتبع، مع بقاء التنفيذ في engine واحد.
https://www2.manager.io/guides/10677
https://www2.manager.io/guides/10707
https://www2.manager.io/guides/8941

## 13. Competitive backlog الذي لم يتم خلطه بهذه الوحدة

هذه عناصر حقيقية ويمكن فتحها كوحدات Closure مستقلة بعد تثبيت Vouchers:
- صلاحية/إتاحة المركبة
- Capacity / utilization
- route/run linking
- vehicle cost per trip / cost per km
- fuel economics
- maintenance impact
- evidence / attachments
- transaction timeline
- approval/audit workflow
- operational exceptions
- unified vehicle/rep/warehouse 360 reporting.

لم تتم إضافتها داخل هذه الوحدة حتى لا نخلط Business Contracts جديدة مع إصلاح الربط الحالي.

## 14. Self-Audit

### Confirmed Facts
- Master assignment موجود في Production.
- Current vehicle driver_id = NULL.
- Fleet query يعيد Rep→Vehicle.
- Vouchers الحالي يستخدم driver_id.
- Van Sales الحالي يستخدم setup-van-branch.
- setup-van-branch كان يعتمد driver_id.
- Production Core يستطيع CREATE DirectSale بدون to_id.
- Production Core يحل vehicle من rep_id.
- SEND يمر في post_stock_movement.
- Replay idempotent.
- QA fixture القديم تم حذفه.
- لا توجد DirectSale drafts حالية.
- لا توجد Test Vehicle/Test Branch حالية.

### Unknowns
- Browser E2E في المتصفح الفعلي.

### Unverified Claims
- لا يوجد ادعاء Browser PASS.

### What was fixed
- setup-van-branch production resolution.
- production QA residue.
- source-level Vouchers integration patch specification.

### What was NOT modified
- Mother main.html.
- Standalone Vouchers source.
- post_stock_movement.
- Fleet Control Plane.

## 15. FINAL CLOSURE

### Production backend
CLOSED

### Fleet Master → Van Sales
CLOSED at Production capability level

### Fleet Master → Vouchers source
PATCH READY / OWNER APPLY REQUIRED

### Database QA hygiene
CLOSED

### Browser E2E
OPEN / UNVERIFIED

# 16. تعليمات الجلسة القادمة

ابدأ بهذه السلسلة فقط:

1. CURRENT_STATE.md
2. System HEAD + parent
3. Mother HEAD + parent
4. Vouchers blob
5. Production deployment
6. Production Fleet assignment
7. افتح PATCH V-01 إلى V-09.
8. لا تعيد أي إصلاح من Report337/338/339.
9. لا تعدل main.html.
10. لا تنشئ Edge Function جديدة.
11. بعد تطبيق Vouchers patch فقط:
   - اقرأ الملف كاملًا.
   - تحقق من `fleet_query` call.
   - تحقق من `repVehicleMap`.
   - تحقق من عدم وجود DirectSale runtime يعتمد `vehicle.driver_id`.
   - تحقق من عدم المساس بـDirectReturn.
   - نفذ Browser E2E.
   - قارن Network → fleet_query → create-stock-voucher → create_manual_stock_voucher_atomic.
   - تحقق أن Draft لا يحرك stock.
   - SEND يحرك stock مرة واحدة.
   - Replay = duplicate.
12. بعدها فقط افتح Closure Unit التالية.

## GOVERNANCE RULE

التقرير تاريخي بعد حفظه.

الحالة الحقيقية للجلسة التالية =

CURRENT GIT
+
CURRENT SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT EVIDENCE

ولا يوجد أي اعتماد على هذا التقرير بدل إعادة التحقق من هذه المصادر.
