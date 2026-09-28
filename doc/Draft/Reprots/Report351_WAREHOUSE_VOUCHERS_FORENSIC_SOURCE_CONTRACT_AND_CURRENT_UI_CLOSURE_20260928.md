# تقرير 351 — التحقيق الجنائي للحالة الحالية لتبويب الأذونات المخزنية

التاريخ: 2026-09-28

الحالة: Production source-binding hardening مطبق ومثبت. Owner Source Patch T-09 إلى T-15 جاهز. Browser E2E يظل مفتوحًا حتى تطبيق المصدر والنشر والاختبار.

## 1. نقطة البداية والحقيقة الحالية

تم الرجوع إلى:
- MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — تمت القراءة حتى EOF.
- CURRENT_STATE.md — تمت مراجعة أحدث checkpoint.
- Report350 — تمت المراجعة حتى النهاية.
- Current Git والـparent.
- Current vouchers.html والملفات التشغيلية picker.html وvan-sales.html.
- Production RPC/Trigger/Edge/RLS والبيانات التجريبية.

System HEAD عند البداية:
ec5e81528f3b37f942405b74db5ff6c01b6fdd67

System parent:
c95560c52e599421e5165baff01a578118b291ea

Frontend HEAD:
f07bdcc4abbbe899af569f8bfaccde04df279416

Frontend parent:
cc35f3a9da6ababf4c8cd87b05ab93539cdae087

vouchers.html blob:
9e3a9cbd0124639934cdf98abc9ec579f4b19f61
6074 سطرًا.

main.html blob:
810e4f5440f5975f55099a124deb42b086a49183

## 2. السبب الجذري الحالي

### 2.1 مصدر Transfer

Source كان يسمح في pickArr بمصدر Transfer أوسع من عقد المسؤولية الجديد.
المطلوب للمخزني أذونات غير privileged هو:
from_id = default_branch_id.

### 2.2 Action authority

actionFor القديمة لا تطابق Production في Transfer/Sent:
Receive يجب أن يظهر للمستلم المثبت فقط، وليس لأي privileged user.

### 2.3 قوائم Pending وCompleted

cards القديمة تعرض أفعال التنفيذ في القائمة.
العقد المطلوب:
القائمة = جدول قراءة وتنقل.
المودال = تنفيذ.

### 2.4 Top actions

details الحالية لا تربط topActions بكل حالات Draft/Receive/Complete كما ينبغي.

### 2.5 Receive UX

محرك partial/full موجود بالفعل ولا يُعاد بناؤه.
النقص هو زر الطباعة والخروج بدون حفظ داخل مودال الاستلام.

## 3. الدور المعماري

main.html هو Control Plane للنظام الأم:
المستخدمون، الأدوار، الفروع، الصلاحيات، الوظائف الأبوية، والمسؤوليات العليا.

vouchers.html هو Execution PWA للأذونات المخزنية اليدوية غير المرتبطة بالأوردرات والرانشيتات.

Transfer lifecycle:
Draft → Sent → Received → Completed

عند Send:
المصدر يخصم.

عند Receive:
يضاف فقط ما استلمه المستلم فعليًا.

الاستلام الجزئي يستند إلى نمط picker.html للكميات المنفذة لكل بند.

van-sales.html يبقى مسؤولًا عن البيع الفعلي من مخزن المركبة؛ لا يتم نقل Transfer إليه.

## 4. Production الذي تم تنفيذه في هذه الدورة

تم تعديل Production مباشرة دون إنشاء Edge Function جديدة.

Migration DB:
version 20260928132432

name:
20260928170000_bind_transfer_source_to_keeper_home_branch_20260928

العقد الجديد:
- مخزني + active_warehouse_role = أذونات + غير privileged: from_id يساوي default_branch_id.
- القيد يسري عند CREATE ويستمر في Draft وعند Send.
- وجهة Transfer مفتوحة لجميع الفروع النشطة داخل الشركة.
- receiver binding السابق لم يتغير.

تم تسجيل المصدر في Git:
supabase/migrations/20260928132432_20260928170000_bind_transfer_source_to_keeper_home_branch_20260928.sql

## 5. البيانات والاختبار

المستخدم المرسل:
vouchers@rawaea.com
فرعه BR-01.

المستلم:
vouchers3@rawaea.com
فرعه BR-2.

اختبار سلبي:
المستخدم المرسل حاول إنشاء Transfer من BR-2.
النتيجة:
فرع مصدر التحويل يجب أن يطابق الفرع الأساسي لمسؤول المخزن
BLOCK PASS.

اختبار إيجابي:
BR-01 → BR-2 نجح إنشاء المسودة.
Voucher:
IN-6

ثم حُذفت المسودة بواسطة delete_manual_stock_voucher_atomic.
QA-SOURCE-BIND residue = 0.

الحالة الحالية للأذونات اليدوية:
Draft = 0
Sent = 0
Received = 0
Completed = 5

لم تُحذف QA SupplierReturn مكتملة ذات أثر مخزني حقيقي.

## 6. مقارنة تنافسية

Odoo:
Detailed Operations تسجل الكميات المنفذة لكل منتج في التحويلات الداخلية.
https://www.odoo.com/documentation/18.0/applications/inventory_and_mrp/barcode/operations/transfers_scratch.html

Dynamics 365:
Transfer Order Receiving جزء من Warehouse Management.
https://learn.microsoft.com/en-us/dynamics365/supply-chain/warehousing/configure-transfer-order-receiving-process

SAP:
يفصل Goods Issue وGoods Receipt ويدعم Stock in Transit.
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/91b21005dded4984bcccf4a69ae1300c/9e64bd534f22b44ce10000000a174cb4.html

Manager:
Inventory Transfers بين المواقع.
https://www2.manager.io/guides/10707

Daftra:
Manual Transfer بين المستودعات مع المصدر والوجهة والكمية.
https://docs.daftra.com/en/user_manual/transferring-items-from-one-warehouse-to-another/

فجوات مستقبلية حقيقية، لا تدخل في هذه الجراحة:
- Stock in Transit reporting.
- ETA/SLA.
- Discrepancy reason codes.
- Barcode receiving.
- Backorder / remaining transfer.
- Receipt attachments.
- Transit reconciliation dashboard.

## 7. Owner Surgical Changeset — vouchers.html فقط

Current SHA:
9e3a9cbd0124639934cdf98abc9ec579f4b19f61

لا تلمس main.html.

### T-09 — allowedBranch

ابحث عن:
~~~
allowedBranch:function(u,b){
~~~
احذف الدالة كاملة واستبدل:

~~~javascript
allowedBranch:function(u,b){
    if(!u||!b)return false;

    if(String(u.default_branch_id||'')===String(b.id)){
        return true;
    }

    var a=u.allowed_branch_ids;

    if(a===null||typeof a==='undefined'){
        return true;
    }

    if(Array.isArray(a)){
        a=a.map(String);
    }else if(typeof a==='string'&&a.trim()){
        var raw=a.trim(),
            parsed=null;

        try{
            parsed=JSON.parse(raw);
        }catch(e){
            parsed=null;
        }

        if(Array.isArray(parsed)){
            a=parsed.map(String);
        }else if(typeof parsed==='string'){
            a=[parsed.trim()];
        }else{
            a=raw
                .split(/[,|]/)
                .map(function(x){
                    return x
                        .trim()
                        .replace(/^"|"$/g,'');
                })
                .filter(Boolean);
        }
    }else{
        return false;
    }

    a=a.map(function(x){
        return String(x)
            .trim()
            .replace(/^"|"$/g,'');
    });

    if(a.indexOf('*')>=0){
        return true;
    }

    return (
        a.indexOf(String(b.id))>=0 ||
        a.indexOf(String(b.branch_code||''))>=0
    );
},
~~~

### T-10 — pickArr

ابحث عن:
~~~
pickArr:function(key){
~~~
احذف الدالة كاملة حتى قبل:
~~~
pickShow:function(key)
~~~
واستبدل:

~~~javascript
pickArr:function(key){

    var s=this,

        allBranches=
            (s.refs.branches||[])
            .filter(function(x){

                return (
                    String(
                        x.company_id||''
                    )===
                    String(
                        s.company||''
                    ) &&
                    x.is_active!==false
                );
            }),

        userBranches=
            allBranches.filter(
                function(x){
                    return s.allowedBranch(
                        s.user,
                        x
                    );
                }
            ),

        bid=
            (RW_UI.byId('wsFrom')||{})
            .value||
            '',

        b=
            allBranches.find(
                function(x){
                    return (
                        String(x.id)===
                        String(bid)
                    );
                }
            );

    if(key==='wsFrom'){

        if(
            s.type==='DirectReturn'
        ){

            if(
                s.user &&
                s.user.role===
                    'مندوب بيع مباشر'
            ){

                return (
                    s.refs.vehicles||[]
                )
                .filter(function(v){

                    return (
                        v.status==='Active' &&
                        v.mobile_stock_enabled!==false &&
                        v.driver_id===
                            s.user.id &&
                        !!s.vehicleBranch(v)
                    );
                });
            }

            return (
                s.refs.vehicles||[]
            )
            .filter(function(v){

                return (
                    v.status==='Active' &&
                    v.mobile_stock_enabled!==false &&
                    !!s.vehicleBranch(v)
                );
            });
        }

        if(
        s.type==='Transfer'
    ){
        var transferPermissions=
            s.user&&s.user.permissions;

        var transferPermissionList=[];

        if(Array.isArray(transferPermissions)){
            transferPermissionList=
                transferPermissions.map(String);
        }else if(
            typeof transferPermissions==='string' &&
            transferPermissions.trim()
        ){
            var transferRaw=
                transferPermissions.trim(),
                transferParsed=null;

            try{
                transferParsed=
                    JSON.parse(transferRaw);
            }catch(e){
                transferParsed=null;
            }

            if(Array.isArray(transferParsed)){
                transferPermissionList=
                    transferParsed.map(String);
            }else if(
                typeof transferParsed==='string'
            ){
                transferPermissionList=[
                    transferParsed.trim()
                ];
            }else{
                transferPermissionList=
                    transferRaw
                        .split(/[,|]/)
                        .map(function(x){
                            return x.trim();
                        })
                        .filter(Boolean);
            }
        }

        var transferPrivileged=
            transferPermissionList.indexOf('*')>=0 ||
            [
                'مدير النظام',
                'مدير عام'
            ].indexOf(
                String(
                    (s.user||{}).role||''
                )
            )>=0;

        if(transferPrivileged){
            return allBranches;
        }

        if(
            s.user &&
            s.user.default_branch_id
        ){
            return allBranches.filter(
                function(x){
                    return (
                        String(x.id)===
                        String(
                            s.user.default_branch_id
                        )
                    );
                }
            );
        }

        return [];
    }

        return userBranches;
    }

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

    if(
        key==='wsTo' &&
        s.type==='Transfer'
    ){
        return allBranches;
    }

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

    if(
        key==='wsTo' &&
        s.type==='DirectReturn'
    ){
        return userBranches;
    }

    if(
        key==='wsTo' &&
        s.type==='SupplierReturn'
    ){

        return (
            s.refs.suppliers||[]
        )
        .filter(function(x){

            return (
                x &&
                x.is_active!==false
            );
        });
    }

    return [];
},
~~~

العقد: المخزني أذونات غير privileged يرى فرعه الأساسي فقط كمصدر. privileged/wildcard يحتفظان بالسلطة العليا. الوجهة تظل جميع الفروع النشطة.

### T-11 — pickSelect

ابحث عن:
~~~
pickSelect:function(key,id){
~~~
احذف الدالة كاملة واستبدل:

~~~javascript
pickSelect:function(key,id){
    var s=this,
        arr=this.pickArr(key)||[],
        x=arr.find(function(z){
            return z.id===id;
        });

    if(!x){
        return;
    }

    var branchSelection=
        (key==='wsFrom'&&s.type!=='DirectReturn') ||
        (key==='wsTo'&&s.type==='DirectReturn');

    if(branchSelection){
        var selectedBranch=
            (s.refs.branches||[]).find(function(branch){
                return branch.id===id;
            });

        if(
            !selectedBranch ||
            !s.allowedBranch(s.user,selectedBranch)
        ){
            RW_UI.toast(
                'هذا الفرع ظاهر للبحث، لكنه خارج نطاق فروع المستخدم المسموح بها',
                'error'
            );
            return;
        }
    }

    if(key==='wsFrom'&&s.type==='DirectReturn'){
        var vb=s.vehicleBranch(x);

        if(!vb){
            RW_UI.toast(
                'المركبة لا تملك مخزنًا متنقلًا صالحًا',
                'error'
            );
            return;
        }

        RW_UI.byId('wsFrom').value=x.id;
        RW_UI.byId('wsFromSearch').value=
            x.vehicle_code||x.license_plate;

        RW_UI.byId('wsFromMenu').classList.add('hidden');

        var r=
            s.refs.reps.find(function(rp){
                return rp.id===x.driver_id;
            });

        RW_UI.byId('wsRep').value=r?r.id:'';
        RW_UI.byId('wsRepSearch').value=
            r?(r.name||r.email):'';

        if(r){
            RW_UI.byId('wsRepSearch').setAttribute(
                'readonly',
                'readonly'
            );
        }else{
            RW_UI.byId('wsRepSearch').removeAttribute(
                'readonly'
            );
        }

        s.summary();
        s.renderProducts();

        return;
    }

    RW_UI.byId(key).value=x.id;

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

    }else if(
        key==='wsTo' &&
        s.type==='SupplierReturn'
    ){
        RW_UI.byId(key+'Search').value=
            x.name||
            x.supplier_code||
            '';

    }else{
        RW_UI.byId(key+'Search').value=
            x.name||
            x.vehicle_code||
            x.supplier_code||
            x.branch_code||
            '';
    }

    RW_UI.byId(key+'Menu').classList.add('hidden');

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

    if(
        key==='wsRep' &&
        s.type==='DirectSale'
    ){
        RW_UI.byId('wsTo').value='';
        RW_UI.byId('wsToSearch').value='';
        RW_UI.byId('wsRepSearch').removeAttribute(
            'readonly'
        );
    }

    s.updateSource();
},
~~~

التحقق بنطاق المصدر لا يطبّق على وجهة Transfer.

### T-12 — actionFor

ابحث عن:
~~~
actionFor:function(v){
~~~
احذف الدالة كاملة واستبدل:

~~~javascript
actionFor:function(v){
    var s=this;

    if(!v||!s.user){
        return '';
    }

    var user=s.user;

    var email=
        String(user.email||'')
            .trim()
            .toLowerCase();

    var creator=
        email &&
        String(v.created_by||'')
            .trim()
            .toLowerCase()===email;

    var permissions=user.permissions;

    if(typeof permissions==='string'){
        try{
            permissions=JSON.parse(permissions);
        }catch(e){
            permissions=
                permissions
                    .split(/[,|]/)
                    .map(function(x){
                        return x.trim();
                    })
                    .filter(Boolean);
        }
    }

    permissions=
        Array.isArray(permissions)
            ?permissions.map(String)
            :[];

    var wildcard=
        permissions.indexOf('*')>=0;

    var privileged=
        wildcard||
        [
            'مدير النظام',
            'مدير عام',
            'مدير مخازن',
            'مشرف مخازن'
        ].indexOf(String(user.role||''))>=0;

    var warehouseVoucherRole=
        String(
            user.activeWarehouseRole||
            user.active_warehouse_role||
            ''
        )==='أذونات';

    function branchInScope(branchId){

        if(!branchId){
            return false;
        }

        if(privileged){
            return true;
        }

        if(
            String(user.default_branch_id||'')===
            String(branchId)
        ){
            return true;
        }

        var branch=
            (s.refs.branches||[])
                .find(function(b){
                    return String(b.id)===
                        String(branchId);
                });

        if(!branch){
            return false;
        }

        var a=user.allowed_branch_ids;

        if(a===null||typeof a==='undefined'){
            return true;
        }

        if(Array.isArray(a)){
            a=a.map(String);
        }else if(typeof a==='string'&&a.trim()){

            var raw=a.trim(),
                parsed=null;

            try{
                parsed=JSON.parse(raw);
            }catch(e){
                parsed=null;
            }

            if(Array.isArray(parsed)){
                a=parsed.map(String);
            }else if(typeof parsed==='string'){
                a=[parsed.trim()];
            }else{
                a=raw
                    .split(/[,|]/)
                    .map(function(x){
                        return x
                            .trim()
                            .replace(/^"|"$/g,'');
                    })
                    .filter(Boolean);
            }

        }else{
            return false;
        }

        a=a.map(function(x){
            return String(x)
                .trim()
                .replace(/^"|"$/g,'');
        });

        return(
            a.indexOf('*')>=0||
            a.indexOf(String(branch.id))>=0||
            a.indexOf(String(branch.branch_code||''))>=0
        );
    }

    var exactReceiver=
        user.id&&
        v.receiver_user_id&&
        String(user.id)===
        String(v.receiver_user_id);

    if(v.type==='Transfer'){

        if(v.status==='Draft'){
            return(
                creator||
                privileged
            )?'draft':'';
        }

        if(v.status==='Sent'){
            /*
             * Production contract is receiver-bound for every RECEIVE,
             * including partial RECEIVE while the voucher remains Sent.
             */
            return exactReceiver
                ?'receive'
                :'';
        }

        if(v.status==='Received'){
            return(
                creator||
                privileged
            )?'complete':'';
        }

        return '';
    }

    if(v.status==='Draft'){
        return(
            creator||
            privileged
        )?'draft':'';
    }

    if(v.status==='Sent'){

        if(v.type==='DirectReturn'){
            return(
                privileged||
                (
                    warehouseVoucherRole&&
                    branchInScope(v.to_id)
                )
            )?'receive':'';
        }

        if(
            v.type==='DirectSale'||
            v.type==='SupplierReturn'
        ){
            return(
                creator||
                privileged
            )?'complete':'';
        }
    }

    if(v.status==='Received'){
        return(
            creator||
            privileged
        )?'complete':'';
    }

    return '';
},
~~~

قاعدة Transfer/Sent:
exact receiver_user_id فقط.

### T-13 — cards

ابحث عن:
~~~
cards:function(rows,scope){
~~~
احذف الدالة كاملة واستبدل:

~~~javascript
cards:function(rows,scope){
    var s=this;

    function dateText(v){
        if(!v){
            return '—';
        }

        var t=Date.parse(v);

        if(!Number.isFinite(t)){
            return String(v);
        }

        try{
            return new Date(t).toLocaleString(
                'ar-EG',
                {
                    year:'numeric',
                    month:'2-digit',
                    day:'2-digit',
                    hour:'2-digit',
                    minute:'2-digit'
                }
            );
        }catch(e){
            return String(v);
        }
    }

    function parseTs(v){
        var t=Date.parse(v||'');
        return Number.isFinite(t)?t:null;
    }

    function duration(from,to){
        var a=parseTs(from),
            b=parseTs(to);

        if(a===null||b===null||b<a){
            return null;
        }

        return Math.round((b-a)/1000);
    }

    function durationText(sec){
        if(sec===null||sec===undefined){
            return '—';
        }

        var n=Math.max(0,Number(sec)||0),
            d=Math.floor(n/86400);

        n-=d*86400;

        var h=Math.floor(n/3600);

        n-=h*3600;

        var m=Math.floor(n/60),
            out=[];

        if(d)out.push(d+'ي');
        if(h||d)out.push(h+'س');
        out.push(m+'د');

        return out.join(' ');
    }

    function typeLabel(v){

        if(v.type==='Transfer'){

            if(scope==='pending'&&v.status==='Draft'){
                return 'تحويل فرع — إرسال';
            }

            if(scope==='pending'&&v.status==='Sent'){
                return 'تحويل فرع — استلام';
            }

            if(scope==='pending'&&v.status==='Received'){
                return 'تحويل فرع — بانتظار الإكمال';
            }

            return 'تحويل فرع';
        }

        if(v.type==='DirectSale'){
            return 'صرف مندوب';
        }

        if(v.type==='DirectReturn'){
            return 'مرتجع مباشر';
        }

        if(v.type==='SupplierReturn'){
            return 'مرتجع مورد';
        }

        return v.type||'إذن مخزني';
    }

    function statusLabel(v){

        if(v.status==='Draft'){
            return 'مسودة';
        }

        if(v.status==='Sent'){
            return 'مُرسل';
        }

        if(v.status==='Received'){
            return 'مُستلم';
        }

        if(v.status==='Completed'){
            return 'مكتمل';
        }

        if(v.status==='Cancelled'){
            return 'ملغى';
        }

        return v.status||'—';
    }

    function statusClass(v){

        if(v.status==='Draft'){
            return 'bg-amber-100 text-amber-700';
        }

        if(v.status==='Sent'){
            return 'bg-blue-100 text-blue-700';
        }

        if(v.status==='Received'){
            return 'bg-emerald-100 text-emerald-700';
        }

        if(v.status==='Cancelled'){
            return 'bg-rose-100 text-rose-700';
        }

        return 'bg-slate-100 text-slate-700';
    }

    function rank(v){

        if(v.type==='Transfer'){

            if(scope==='pending'){
                if(v.status==='Draft')return 10;
                if(v.status==='Sent')return 20;
                if(v.status==='Received')return 25;
            }

            return 10;
        }

        if(v.type==='DirectSale'){
            return 30;
        }

        if(v.type==='DirectReturn'){
            return 40;
        }

        if(v.type==='SupplierReturn'){
            return 50;
        }

        return 90;
    }

    if(!rows.length){
        return(
            '<div class="card text-center py-14">'+
                '<div class="text-5xl mb-3">☕</div>'+
                '<b class="text-slate-400">لا توجد أذونات</b>'+
            '</div>'
        );
    }

    var ordered=
        rows
            .slice()
            .sort(function(a,b){

                var ra=rank(a),
                    rb=rank(b);

                if(ra!==rb){
                    return ra-rb;
                }

                var ta=parseTs(a.created_at)||0,
                    tb=parseTs(b.created_at)||0;

                return tb-ta;
            });

    var body=
        ordered.map(function(v){

            var codeJs=
                JSON.stringify(
                    String(v.voucher_code||'')
                );

            var fromText=
                s.loc(
                    v.from_id,
                    v.from_type
                );

            var toText=
                s.loc(
                    v.to_id,
                    v.to_type
                );

            var createdToSent=
                duration(
                    v.created_at,
                    v.sent_date
                );

            var sentToReceived=
                duration(
                    v.sent_date,
                    v.received_date
                );

            var receivedToCompleted=
                duration(
                    v.received_date,
                    v.completed_at
                );

            return(
                '<tr '+
                    'role="button" tabindex="0" '+
                    'class="border-t hover:bg-slate-50 cursor-pointer transition-colors">'+
                    '<td class="p-3 align-top" '+
                        'onclick="App.details('+s.esc(codeJs)+')" '+
                        'onkeydown="if(event.key===\\\'Enter\\\' || event.key===\\\' \\\'){App.details('+s.esc(codeJs)+')}">'+
                        '<b class="block text-sm">'+
                            s.esc(v.voucher_code||'—')+
                        '</b>'+
                        '<span class="text-[10px] text-slate-400">'+
                            'فتح التفاصيل ←'+
                        '</span>'+
                    '</td>'+
                    '<td class="p-3 align-top" onclick="App.details('+s.esc(codeJs)+')">'+
                        '<span class="block text-xs font-black">'+
                            s.esc(typeLabel(v))+
                        '</span>'+
                        '<span class="inline-block mt-1 px-2 py-1 rounded-full text-[10px] font-bold '+statusClass(v)+'">'+
                            s.esc(statusLabel(v))+
                        '</span>'+
                    '</td>'+
                    '<td class="p-3 align-top text-xs" onclick="App.details('+s.esc(codeJs)+')">'+
                        '<b>'+s.esc(fromText)+'</b>'+
                        '<span class="block text-slate-400 my-1">↓</span>'+
                        '<b>'+s.esc(toText)+'</b>'+
                    '</td>'+
                    '<td class="p-3 align-top text-xs" onclick="App.details('+s.esc(codeJs)+')">'+
                        '<b>'+s.esc(v.reference||'—')+'</b>'+
                        '<span class="block mt-1 text-slate-400">'+
                            s.esc(dateText(v.voucher_date||v.created_at))+
                        '</span>'+
                    '</td>'+
                    '<td class="p-3 align-top text-xs" onclick="App.details('+s.esc(codeJs)+')">'+
                        '<div>إنشاء → إرسال: <b>'+s.esc(durationText(createdToSent))+'</b></div>'+
                        '<div class="mt-1">إرسال → استلام: <b>'+s.esc(durationText(sentToReceived))+'</b></div>'+
                        '<div class="mt-1">استلام → إكمال: <b>'+s.esc(durationText(receivedToCompleted))+'</b></div>'+
                    '</td>'+
                    '<td class="p-3 align-top text-center" onclick="App.details('+s.esc(codeJs)+')">'+
                        '<span class="text-lg">›</span>'+
                    '</td>'+
                '</tr>'
            );

        }).join('');

    return(
        '<div class="card overflow-hidden">'+
        '<div class="px-3 py-3 border-b bg-slate-50 text-xs font-black flex justify-between gap-3 flex-wrap">'+
            '<span>'+
                (scope==='pending'
                    ?'الأذونات المعلقة'
                    :'الأذونات المكتملة')+
            '</span>'+
            '<span class="text-slate-400">اضغط على أي سطر لفتح مودال الإذن</span>'+
        '</div>'+
        '<div class="overflow-x-auto">'+
        '<table class="w-full text-right">'+
            '<thead class="bg-white">'+
                '<tr>'+
                    '<th class="p-3 text-[10px] text-slate-500 whitespace-nowrap">الإذن</th>'+
                    '<th class="p-3 text-[10px] text-slate-500 whitespace-nowrap">النوع / الحالة</th>'+
                    '<th class="p-3 text-[10px] text-slate-500 whitespace-nowrap">من / إلى</th>'+
                    '<th class="p-3 text-[10px] text-slate-500 whitespace-nowrap">المرجع / التاريخ</th>'+
                    '<th class="p-3 text-[10px] text-slate-500 whitespace-nowrap">دورة الحياة</th>'+
                    '<th class="p-3 text-[10px] text-slate-500 whitespace-nowrap">فتح</th>'+
                '</tr>'+
            '</thead>'+
            '<tbody>'+
                body+
            '</tbody>'+
        '</table>'+
        '</div>'+
        '</div>'
    );
},
~~~

النتيجة:
Pending وCompleted في جدول.
كل سطر Click يفتح التفاصيل.
لا أزرار تنفيذ خارج Modal.
الترتيب:
Transfer Send
Transfer Receive
DirectSale
DirectReturn
SupplierReturn

### T-14 — details

داخل details:function(code) ابحث عن:
~~~
var transferReceiver=
~~~
ثم كتلة var topActions التابعة لها حتى نهايتها.
احذف الكتلة كاملة واستبدل:

~~~javascript
var transferReceiver=
    v.type==='Transfer' &&
    v.status==='Sent' &&
    s.user&&
    s.user.id&&
    v.receiver_user_id&&
    String(s.user.id)===String(v.receiver_user_id);

var act=s.actionFor(v);

var codeJs=
    JSON.stringify(
        String(v.voucher_code||'')
    );

var topActions=
    '<div class="flex flex-wrap justify-end gap-2 mb-3 no-print">';

if(act==='draft'){

    topActions+=
        '<button type="button" onclick="App.editVoucher('+codeJs+')" class="px-3 py-2 rounded-xl bg-amber-500 text-white text-xs font-black">تعديل</button>'+
        '<button type="button" onclick="App.deleteVoucher('+codeJs+')" class="px-3 py-2 rounded-xl bg-rose-600 text-white text-xs font-black">حذف</button>'+
        '<button type="button" onclick="App.send('+codeJs+')" class="px-3 py-2 rounded-xl bg-indigo-600 text-white text-xs font-black">إرسال</button>'+
        '<button type="button" onclick="App.printDraftVoucher('+codeJs+')" class="px-3 py-2 rounded-xl bg-slate-800 text-white text-xs font-black">🖨 طباعة</button>';

}else if(act==='receive'){

    if(v.type==='Transfer'){

        topActions+=
            '<button type="button" onclick="App.receive('+codeJs+',true)" class="px-3 py-2 rounded-xl bg-emerald-600 text-white text-xs font-black">استلام كلي</button>'+
            '<button type="button" onclick="App.receive('+codeJs+',false)" class="px-3 py-2 rounded-xl bg-teal-600 text-white text-xs font-black">استلام تفصيلي</button>';

    }else{

        topActions+=
            '<button type="button" onclick="App.receive('+codeJs+',false)" class="px-3 py-2 rounded-xl bg-emerald-600 text-white text-xs font-black">استلام</button>';

    }

    topActions+=
        '<button type="button" onclick="App.printVoucher()" class="px-3 py-2 rounded-xl bg-slate-800 text-white text-xs font-black">🖨 طباعة</button>'+
        '<button type="button" onclick="App.exitVoucherDetails()" class="px-3 py-2 rounded-xl bg-slate-500 text-white text-xs font-black">خروج بدون حفظ</button>';

}else if(act==='complete'){

    topActions+=
        '<button type="button" onclick="App.complete('+codeJs+')" class="px-3 py-2 rounded-xl bg-violet-600 text-white text-xs font-black">إكمال</button>'+
        '<button type="button" onclick="App.printVoucher()" class="px-3 py-2 rounded-xl bg-slate-800 text-white text-xs font-black">🖨 طباعة</button>'+
        '<button type="button" onclick="App.exitVoucherDetails()" class="px-3 py-2 rounded-xl bg-slate-500 text-white text-xs font-black">خروج</button>';

}else{

    topActions+=
        '<button type="button" onclick="App.printVoucher()" class="px-3 py-2 rounded-xl bg-slate-800 text-white text-xs font-black">🖨 طباعة</button>'+
        '<button type="button" onclick="App.exportVoucher()" class="px-3 py-2 rounded-xl bg-emerald-600 text-white text-xs font-black">⇩ تصدير CSV</button>';

}

topActions+=
    '</div>';
~~~

اترك:
~~~
showCloseButton:!transferReceiver
~~~
كما هي.

### T-15 — receive

داخل receive:function(code,full):
الكتلة الأولى التي تبدأ بـ title:'استلام كلي' تستبدل بـ:

~~~javascript
return Swal.fire({
    title:'استلام كلي',
    html:fh,
    showDenyButton:true,
    denyButtonText:'🖨 طباعة',
    showCancelButton:true,
    confirmButtonText:
        'حفظ الاستلام الكلي',
    cancelButtonText:
        'خروج بدون حفظ',
    allowOutsideClick:false,
    preDeny:function(){

        Swal.close();

        setTimeout(function(){
            s.details(code);

            setTimeout(function(){
                s.printVoucher();
            },400);

        },80);

        return false;
    },
    preConfirm:function(){
        return [];
    }
});
~~~

والكتلة الثانية التي تبدأ بـ title:'استلام '+s.esc(v.type) تستبدل بـ:

~~~javascript
return Swal.fire({
    title:'استلام '+s.esc(v.type),
    html:h,
    showDenyButton:true,
    denyButtonText:'🖨 طباعة',
    showCancelButton:true,
    confirmButtonText:
        'حفظ الاستلام',
    cancelButtonText:
        'خروج بدون حفظ',
    allowOutsideClick:false,
    preDeny:function(){

        Swal.close();

        setTimeout(function(){
            s.details(code);

            setTimeout(function(){
                s.printVoucher();
            },400);

        },80);

        return false;
    },
    preConfirm:function(){

        var out=[];

        d.forEach(function(x,i){

            var el=
                RW_UI.byId(
                    'rq'+i
                );

            if(!el){
                return;
            }

            var q=
                Number(el.value||0);

            var m=
                Number(el.max||0);

            if(q<0||q>m){
                throw new Error(
                    'كمية غير صالحة'
                );
            }

            if(q){
                out.push({
                    itemId:x.item_id,
                    itemCode:x.item_code,
                    receivedQty:q
                });
            }

        });

        if(!out.length){

            Swal.showValidationMessage(
                'أدخل كمية استلام'
            );

            return false;
        }

        return out;
    }
});
~~~

## 8. السيناريو التشغيلي النهائي

### المرسل

مخزني أذونات:
- المصدر = فرعه الأساسي.
- الوجهة = أي فرع نشط.
- Draft: Edit / Delete / Send / Print داخل Modal.
- لا Receive.

### المستقبل

- Sent Transfer يظهر له Receive فقط إذا كان receiver_user_id هو هويته.
- Partial Receive أو Receive All.
- Print.
- Exit without Save.
- لا يمكن تغيير receiver بعد Send.

### الجدول

معلقة:
Transfer Send → Transfer Receive → DirectSale → DirectReturn → SupplierReturn.

مكتملة:
نفس نمط العرض، مع الحالة المكتملة.

## 9. E2E والـClosure Gate

بعد Owner Apply:
Full Source Parse
→ Deploy
→ Authenticated Browser E2E
→ Served Artifact Verification
→ Production stock/audit verification.

يجب إثبات:
- sender Receive blocked.
- non-receiver Receive blocked.
- receiver immutable.
- partial receive صحيح.
- full remaining receive صحيح.
- duplicate replay idempotent.
- خروج بدون حفظ بلا mutation.

Browser Run 53 السابق:
INLINE_SCRIPT_NOT_FOUND

هذا فشل Harness وليس إثباتًا لفشل Business Workflow.

## 10. المبادئ الحاكمة الجديدة

1. UI visibility ليست Authorization.
2. Transfer RECEIVE = exact receiver_user_id.
3. Transfer Source لمخزني أذونات = default_branch_id.
4. Source scope وDestination scope مفهومان مختلفان.
5. Lists للتصفح؛ Modals للتنفيذ.
6. استخدم RPC/Edge الموجودة قبل إنشاء Edge جديدة.
7. لا تحذف سجلًا مرحلًا ذا أثر بدون Reverse رسمي.
8. E2E التخريبي يجب أن يكون zero-residue.
9. Current Git + Source + Production + DB + Deployment Evidence تتقدم على التقارير.
10. لا تعِد فتح عقد أُغلقت دون دليل حالي متناقض.

## 11. Self Audit

| البند | النتيجة |
|---|---|
| MASTER CTO EOF | PASS |
| Report350 EOF | PASS |
| Current State checkpoint | PASS |
| Current source SHA | PASS |
| Last HEAD + parent | PASS |
| Production DB/Trigger/RPC | PASS |
| Wrong source block | PASS |
| Valid source create | PASS |
| New QA residue | 0 |
| New Edge Function | NONE |
| main.html touched | NO |
| vouchers.html touched | NO |
| Production source-binding | CLOSED |
| Owner T-09→T-15 | OPEN |
| Browser E2E | OPEN |

## 12. تعليمات الاستكمال

ابدأ من CURRENT_STATE.
ثم Current Git والـparent.
ثم Current vouchers blob.
ثم تحقق من Production.
ثم اختبر هل T-09 إلى T-15 مطبقة بالفعل.

إذا لم تُطبق، طبّقها على vouchers.html فقط وفق هذا التقرير.

بعد ذلك:
Full Parse → Deploy → Browser E2E → Production Verification → UI Closure.

لا تعد:
- receiver binding
- partial receive backend
- DirectReturn backend guard
- Production source binding
- إنشاء Edge جديدة
- main.html

**حالة النهاية: Production source-binding CLOSED؛ Owner Source T-09→T-15 OPEN؛ Browser E2E OPEN.**
