# Report349 — إغلاق عقد الأذونات المخزنية: «معلقة / مكتملة» + مسؤولية التحويل + حماية الاستلام الجزئي
**التاريخ:** 2026-09-28  
**حالة التحقيق:** Production hardening منفذ + E2E DB PASS + حزمة Source جراحية جاهزة للمالك  
**النطاق:** `companies/company-1/warehouse/vouchers.html` فقط كهدف Source، دون تعديل مباشر عليه، ودون لمس `main.html`.

---

## 1. نقطة الاستئناف المثبتة

تم الاستئناف من آخر نقطة مثبتة في:

- `MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md` — قرئ كاملًا حتى النهاية.
- `CURRENT_STATE.md` — قرئ كاملًا حتى النهاية.
- `Report348_WAREHOUSE_VOUCHERS_TRANSFER_SOURCE_RESPONSIBILITY_FORENSIC_CLOSURE_20260928.md` — آخر تقرير تنفيذي سابق، واستُخدم كدليل تاريخي فقط.
- آخر Git في النظام الأم:
  - `99537edbd67adaf6381af781c68590436ff4c548` — Report348 checkpoint.
  - parent المقابل في سلسلة تقوية المصدر: `d813d1fd9bd8d2e478f3de6330f2abf63d9cd098`.
  - commit توثيق طبقة قاعدة البيانات: `ce55aa2716299037554fb891d354e2a90402451a`.
- آخر Source في `erp-frontend`:
  - `f07bdcc4abbbe899af569f8bfaccde04df279416`
  - parent: `cc35f3a9da6ababf4c8cd87b05ab93539cdae087`
  - `vouchers.html` الحالي: blob `9e3a9cbd0124639934cdf98abc9ec579f4b19f61`
  - عدد الأسطر الحالي: **6074**.

لم يتم إعادة إصلاح أي نقطة أُثبت إغلاقها في Report348.

---

# 2. هرم الحقيقة المستخدم في هذه الجلسة

أُعيد تطبيق قاعدة الحوكمة:

`CURRENT PRODUCTION > CURRENT DATABASE > CURRENT DEPLOYMENT > CURRENT GIT > CURRENT SOURCE > HISTORY > REPORTS > MEMORY`

التقارير لم تُعامل كحالة حالية. كل اكتشاف حرج في هذه الجلسة تم مطابقته مع Production أو Source الحالي.

---

# 3. التحقيق الجنائي — ما هو صحيح وما هو معيب

## 3.1 ما هو صحيح ومغلق بالفعل

العقد الحالي للتحويل بين الفروع في Production يثبت:

1. الإرسال يبدأ من فرع المصدر.
2. عند الانتقال `Draft → Sent` يتم اختيار مسؤول استلام وحيد للفرع الوجهة.
3. لا يمكن أن يكون مسؤول الاستلام هو نفس منفذ الإرسال.
4. `Sent → Received` لا يسمح به إلا `receiver_user_id` المثبت.
5. `Received → Completed` يحكمه العقد الحالي: منشئ الإذن أو الإدارة المخزنية.
6. `receiver_user_id` يصبح غير قابل للتغيير بعد تثبيته في دورة التنفيذ.
7. المخزون يتحرك عبر طبقة الحركة المركزية الموجودة، ولا توجد Edge Function جديدة مطلوبة.

Trigger Production الحالي:
`public.enforce_transfer_responsibility_contract()`

---

## 3.2 الخطأ الأمني الذي اكتُشف في هذه الجلسة

الخطأ لم يكن في الانتقال النهائي `Sent → Received` نفسه.

المشكلة كانت في أن الاستلام الجزئي الصحيح يترك الإذن في حالة:

`Sent`

بينما كان Trigger التحقق من هوية المستلم يُطبق فعليًا عند محاولة الوصول إلى `Received`.

وبالتالي كان هناك مسار محتمل:

**مستخدم مخزني آخر + active_warehouse_role = أذونات + Voucher Sent + RECEIVE جزئي**

→ الوصول إلى `post_manual_stock_voucher_atomic()`

→ تنفيذ `TransferIn`

→ تحديث `received_qty`

→ بقاء الإذن `Sent`

→ عدم المرور بعد إلى نقطة `Sent → Received` التي كان Trigger يحميها.

هذا كان **Business Contract Gap أمني حقيقي** وليس مشكلة UI.

---

# 4. الإصلاح Production الذي تم تنفيذه مباشرة

تم تعديل **الـRPC الموجود نفسه**:

`public.post_manual_stock_voucher_atomic(uuid,text,text,text,jsonb,text)`

Migration:

`20260928120431_harden_transfer_partial_receive_actor_20260928`

تمت إضافة حماية مباشرة قبل استدعاء الـcore:

```sql
if p_operation='RECEIVE' and v_voucher.type='Transfer' then
  if v_voucher.receiver_user_id is null
     or v_actor.id is distinct from v_voucher.receiver_user_id then
    raise exception 'لا يملك هذا المستخدم مسؤولية استلام تحويل الفرع';
  end if;
end if;
```

الهدف: **كل RECEIVE جزئي أو كلي لنقل فرعي يجب أن ينفذه نفس المستخدم المثبت كمسؤول استلام في الإذن.**

لم يتم إنشاء Edge Function جديدة.

الـEdge الحالية المرتبطة:
- `receive-stock-voucher` — ACTIVE — v22 — verify_jwt=true.
- `send-stock-voucher` — ACTIVE — v20 — verify_jwt=true.

الـEdge `receive-stock-voucher` تستخرج هوية Auth الحالية ثم تمرر البريد المرتبط بالمستخدم إلى الـRPC الموجود؛ لذلك أصبح الحارس الجديد في المركز التنفيذي الفعلي.

---

# 5. بيانات Production المستخدمة في الاختبار

الشركة:
`00000000-0000-0000-0000-000000000001`

فرع المصدر:
- BR-01
- `a38332b6-6cea-480a-ada1-6eb6ab0590db`

فرع الوجهة:
- BR-2
- `555ed6cd-5d12-4cac-8597-37e141ac4112`

مرسل الاختبار الموجود:
- `vouchers@rawaea.com`
- role = `مخزني`
- active_warehouse_role = `أذونات`
- default_branch = BR-01
- allowed_branch_ids = BR-01

مستلم الاختبار الموجود:
- `vouchers3@rawaea.com`
- role = `مخزني`
- active_warehouse_role = `أذونات`
- default_branch = BR-2
- allowed_branch_ids = BR-2

الصنف:
- code = 1001
- `جو كيك 5ج`

الرصيد قبل الاختبار:
- BR-01 = 8
- BR-2 = 3

---

# 6. E2E — النتيجة النهائية

تم إنشاء Fixture حقيقي داخل Transaction ثم تنفيذ كامل دورة التحويل ثم Rollback كامل، لذلك لم تُلوث Production بنتيجة الاختبار.

التسلسل:

### CREATE
نجح إنشاء Transfer حقيقي بواسطة `vouchers@rawaea.com`.

### SEND
نجح:
`Draft → Sent`

ونتجت حركة خروج واحدة من المصدر.

### UNAUTHORIZED RECEIVE
تمت محاولة استلام جزئي بواسطة **المرسل نفسه**:

`vouchers@rawaea.com`

والنتيجة:

**BLOCKED**

بالخطأ المقصود:

`لا يملك هذا المستخدم مسؤولية استلام تحويل الفرع`

### PARTIAL RECEIVE
المستلم الصحيح:

`vouchers3@rawaea.com`

استلم:
`0.5`

وبقي:

`status = Sent`

و:

`received_qty = 0.5`

### IDEMPOTENCY REPLAY
أعيد نفس `operation_id` ونفس payload.

النتيجة:

`duplicate = true`

ولم تتكرر حركة مخزنية.

### REMAINDER
المستلم الصحيح استلم:

`0.5`

فأصبح:

`received_qty = 1`

وانتقل الإذن إلى:

`Received`

### COMPLETE
المُرسل الأصلي:

`vouchers@rawaea.com`

نفذ الإكمال النهائي، وفق العقد الحالي.

النتيجة:

`Completed`

### المخزون

`source_delta = -1`

`target_delta = +1`

### الحركات

`movement_count = 3`

وهذه صحيحة:

1. TransferOut
2. TransferIn للجزء الأول
3. TransferIn للجزء الثاني

### E2E RESULT

**PASS**

---

# 7. تنظيف بيانات الاختبار القديمة

تم فحص بيانات الأذونات اليدوية قبل التنظيف.

تم حذف فقط المسودات القديمة الواضحة كـQA والتي لا تحمل أي أثر حركة:

- `IN-6`
- `IN-7`

بعد التنظيف:

- Manual Completed = 5
- Manual Draft = 0

تم **عدم حذف** الأذونات المكتملة القديمة ذات الأثر المالي/المخزني، لأن حذفها مباشرةً سيكسر سلامة التاريخ المحاسبي والمخزني ولا يوجد في هذا التحقيق دليل يبرر عكسها اعتباطيًا.

Fixture هذا التحقيق نفسه:
- لم يترك Voucher.
- لم يترك inventory movement.
- لم يترك test operation residue.

---

# 8. Current Source — المشكلة الحالية في vouchers.html

الـblob الحالي لم يتغير أثناء هذه الجلسة:

`9e3a9cbd0124639934cdf98abc9ec579f4b19f61`

والسبب أن تعليمات الجلسة تمنع تعديل `vouchers.html` مباشرة من جهتي.

كما تم احترام:

**لا تعديل في `main.html`.**

---

# 9. العيوب Source التي ما زالت مفتوحة

## T-09 — allowedBranch

### العنصر المعيب

الملف:

`companies/company-1/warehouse/vouchers.html`

الدالة:

`allowedBranch:function(u,b)`

الموضع الحالي يبدأ تقريبًا عند line 2999.

### الخطأ

ابحث عن بداية الدالة:

```javascript
allowedBranch:function(u,b){
```

واحذف **الدالة كاملة** حتى الفاصل:

```javascript
},
```

قبل `pickArr`.

### البديل الكامل

```javascript
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
```

### سبب التعديل

إزالة bypass الخاص بـ`Transfer` الذي كان يجعل مخزني/أذونات يرى كل فروع الشركة.

---

# 10. T-10 — pickArr

### العنصر المعيب

الدالة:

`pickArr:function(key)`

موضعها الحالي يبدأ تقريبًا line 3245.

### الخطأ

داخل:

```javascript
if(
    s.type==='Transfer'
){
    return allBranches;
}
```

يُسمح للمرسل باختيار كل فروع الشركة كمصدر.

### الإجراء

ابحث عن **الدالة كاملة**:

```javascript
pickArr:function(key){
```

واستبدلها كاملة بالآتي:

```javascript
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
            return userBranches;
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
```

### العقد الناتج

- المصدر Transfer = فروع المستخدم فقط.
- الوجهة Transfer = كل فروع الشركة المسموح بها من حيث company، لأن الوجهة ليست ملكية المرسل.
- Production هو الذي يحدد عند الإرسال أن المرسل مصرح له بالمصدر.
- Production هو الذي يربط مسؤول استلام الوجهة.

---

# 11. T-11 — pickSelect

### العنصر المعيب

الدالة:

`pickSelect:function(key,id)`

موضعها الحالي يبدأ تقريبًا line 3814.

### الخطأ

الشرط الحالي يفرض `allowedBranch` على وجهة Transfer:

```javascript
(key==='wsTo'&&(
    s.type==='Transfer' ||
    s.type==='DirectReturn'
))
```

وهذا قد يمنع اختيار فرع الوجهة المختلف عن فرع المرسل.

### الإجراء

ابحث عن **الدالة كاملة**:

```javascript
pickSelect:function(key,id){
```

واستبدلها بالنسخة الحالية نفسها مع تعديل عقد branchSelection فقط إلى:

```javascript
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
```

**ملاحظة جراحية:** لا تُعدّل أي جزء آخر من `pickSelect`.

---

# 12. T-12 — actionFor

### العنصر المعيب

الدالة:

`actionFor:function(v)`

موضعها الحالي تقريبًا line 434.

### الخطأ

الدالة الحالية توسع بعض الأفعال لتصبح عامة أكثر من اللازم في DirectSale / DirectReturn / SupplierReturn.

خصوصًا:

- Draft يمكن أن يظهر فعله لغير المنشئ.
- DirectReturn Sent قد يظهر `receive` لأي مستخدم.
- الإكمال يحتاج ربطه بالمنشئ أو الإدارة المخزنية.

### الإجراء

ابحث عن:

```javascript
actionFor:function(v){
```

واحذف الدالة كاملة ثم استبدلها:

```javascript
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
            return(
                exactReceiver||
                privileged
            )?'receive':'';
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
```

---

# 13. T-13 — cards

### العنصر المعيب

الدالة:

`cards:function(rows,scope)`

موضعها الحالي تقريبًا line 795.

### الخطأ

هي حاليًا تبني **Cards** وتضع أزرار التحكم داخل صف البطاقة خارج مودال الإذن.

وهذا يخالف العقد الجديد:

**قائمة = جدول عرض فقط**

**التحكم = داخل مودال الإذن فقط**

### الإجراء

ابحث عن:

```javascript
cards:function(rows,scope){
```

واحذف **الدالة كاملة** حتى:

```javascript
},
```

التي تسبق `loc:function`.

### البديل الكامل

```javascript
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
```

**لا توجد أزرار Edit/Delete/Send/Receive/Complete خارج المودال بعد هذا الاستبدال.**

---

# 14. T-14 — تفاصيل الإذن: نقل كل التحكم إلى داخل المودال

### العنصر المعيب

داخل:

`details:function(code)`

الموضع الحالي تقريبًا line 1653.

ابحث تحديدًا عن:

```javascript
var transferReceiver=
    v.type==='Transfer' &&
    v.status==='Sent' &&
    s.user&&
    s.user.id&&
    v.receiver_user_id&&
    String(s.user.id)===String(v.receiver_user_id);

var topActions=
```

واحذف هذا العنصر كاملًا حتى نهاية بناء `topActions`.

### البديل الكامل

```javascript
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
```

ثم يبقى:

```javascript
showCloseButton:!transferReceiver
```

كما هو.

---

# 15. T-15 — Receive Modal: حفظ / استلام كلي / طباعة / خروج بدون حفظ

هذه النقطة غير مكتملة في Source الحالي رغم أن منطق الكميات الجزئية نفسه صحيح.

## الجزء الأول: مودال الاستلام الكلي

داخل `receive:function(code,full)` ابحث تحديدًا عن:

```javascript
return Swal.fire({
    title:'استلام كلي',
```

واستبدل **كتلة Swal.fire الكاملة** إلى نهاية `preConfirm`:

```javascript
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
```

## الجزء الثاني: مودال الاستلام التفصيلي

ابحث تحديدًا عن:

```javascript
return Swal.fire({
    title:'استلام '+s.esc(v.type),
```

واستبدل **كتلة Swal.fire الكاملة** حتى نهاية `preConfirm` بهذا:

```javascript
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
```

### النتيجة

داخل مودال الاستلام نفسه:

- **حفظ الاستلام**
- **استلام كلي** من المودال الرئيسي
- **طباعة**
- **خروج بدون حفظ**

ولا يوجد أي تأثير على المخزون عند الخروج بدون حفظ.

---

# 16. الشكل الوظيفي النهائي المطلوب

## «معلقة»

الجدول يعرض بالترتيب:

| الترتيب | النوع |
|---|---|
| 1 | تحويل فرع — إرسال |
| 2 | تحويل فرع — استلام |
| 3 | صرف مندوب |
| 4 | مرتجع مباشر |
| 5 | مرتجع مورد |

كل صف:

**Click → Voucher Modal**

ولا توجد أزرار تشغيل خارج المودال.

---

# 17. Transfer — مسؤولية الفرع المرسل

### Draft

العمليات المتاحة فقط للمنشئ أو الإدارة المخزنية:

- تعديل
- حذف
- إرسال
- طباعة

### Sent

لا يظهر زر الاستلام إلا:

`currentUser.id = receiver_user_id`

### Received

الإكمال:

- منشئ الإذن
- أو الإدارة المخزنية وفق Production contract

### ممنوع

- المرسل يستلم لنفسه.
- مستلم آخر يشارك في نفس الإذن.
- تغيير `receiver_user_id` بعد تثبيته.
- استلام جزئي بواسطة مستخدم غير المسؤول.
- تنفيذ RECEIVE مباشرةً خارج المسؤول المثبت.

---

# 18. الاستلام الجزئي — العقد النهائي

إذا كان:

`qty = 10`

وتم استلام:

`4`

فالحالة تبقى:

`Sent`

و:

`received_qty = 4`

و:

`remaining = 6`

وعند استلام الـ6:

`received_qty = 10`

فتنتقل الحالة إلى:

`Received`

وبعد ذلك يتم الإكمال وفق مسؤول الإكمال الحالي.

هذا السلوك ينسجم مع النمط المثبت في picker ومع مبدأ الكمية الفعلية وليس الكمية النظرية.

---

# 19. التكامل المركزي

النظام ليس مجموعة جزر.

التدفق المستهدف:

`vouchers.html`
→ Auth user
→ existing Edge
→ existing RPC
→ central stock movement
→ inventory_log
→ stock_voucher_details.received_qty
→ stock_vouchers.status
→ responsibility trigger
→ audit / operation identity
→ reporting / stock context

ولا يتم إنشاء مخزن حركة محلي داخل التطبيق.

---

# 20. علاقة picker / van-sales

## picker

الاستفادة الأساسية التي تم تثبيتها من المصدر التاريخي والحالي:

- التعامل مع الكمية الفعلية.
- التفريق بين المطلوب والمنفذ.
- الحفاظ على دورة تنفيذ ميدانية منفصلة عن شاشة النظام الأم.

## van-sales

التطبيق مستقل تشغيليًا، لكنه يشارك نفس:

- الشركة.
- الفروع.
- المستخدم.
- المركبة.
- العهدة.
- أذونات DirectSale / DirectReturn.
- المخزون المركزي.

لا يجوز تحويل `vouchers.html` إلى بديل عن التطبيق الميداني، ولا تحويل `van-sales.html` إلى مخزن مستقل خارج القلب المركزي.

---

# 21. مقارنة تنافسية موثقة

## Odoo

توثيق Odoo يثبت دعم معالجة الكميات الفعلية على السطور، والاستلام الجزئي، وإمكانية إنشاء Backorder عند بقاء جزء من الكمية. وهذا يضع الاستلام الجزئي في فئة Business Workflow أساسية لا ميزة تجميلية.  
المصدر:  
https://www.odoo.com/documentation/13.0/applications/inventory_and_mrp/purchase/purchases/rfq/reception.html  
https://www.odoo.com/documentation/17.0/applications/inventory_and_mrp/inventory/shipping_receiving/picking_methods/batch.html

## Dynamics 365

توثيق Microsoft يميز بوضوح بين Shipment وReceipt في Transfer Order، ويحتفظ بأحداث/حركات مخزنية مستقلة مرتبطة بمرحلة الشحن والاستلام.  
المصدر:  
https://learn.microsoft.com/en-us/dynamics365/finance/general-ledger/inventory-posting  
https://learn.microsoft.com/en-us/dynamics365/supply-chain/warehousing/transfer-orders-warehouse

## Manager.io

يوثق Manager أن Inventory Transfer يسجل انتقال الأصناف بين المواقع مع Date / Reference / Item / Qty / From / To، ويؤكد أن الرصيد حسب الموقع ينتج من صافي الحركات.  
المصدر:  
https://www2.manager.io/guides/10707

## Daftra

المصادر المفتوحة التي تم الوصول إليها خلال التحقيق تؤكد تركيز إدارة المخزون على الرؤية المحدثة للكميات والحركة بين الفروع/المخازن والتنبيه بحدود المخزون، لكن لم يُبنَ هذا التقرير على ادعاءات تفصيلية غير موثقة عن واجهة Transfer الخاصة بها.  
المصدر:  
https://www.daftra.com/blog/

## SAP

لم يُستخدم ادعاء تفصيلي عن SAP في هذا التقرير دون مصدر رسمي مطابق للنقطة، حفاظًا على قاعدة عدم الافتراض.

---

# 22. ما ينقص RAWAEA مقارنةً بالنضج التنافسي — Backlog وليس ضمن Closure الحالي

هذه النقاط **لا يجوز اعتبارها جزءًا مغلقًا**:

1. حالة In-Transit صريحة ككيان تشغيلي يمكن مراقبته.
2. ETA / SLA للانتقال بين الفروع.
3. سبب فرق الاستلام Discrepancy Reason.
4. Backorder / Remaining transfer document عند الحاجة.
5. Attachments / Proof of delivery أو إثبات الاستلام.
6. Barcode-assisted receiving.
7. Lot / Batch / Serial حين تكون طبيعة الصنف تستلزم ذلك.
8. Branch reconciliation dashboard للتحويلات المفتوحة والمعلقة والمتأخرة.
9. تقرير تحويلات: Sent / In-Transit / Partial / Received / Completed / Exception.
10. Approval workflow اختياري للتحويلات الحساسة.

هذه Backlog حقيقية وليست مطلوبة كسبب لتعطيل الإغلاق الحالي.

---

# 23. لماذا لم نغيّر بنية النظام

لم يتم تحويل العملية إلى شاشة مركزية واحدة.

السبب:

- الفصل بين التطبيق الأم والتطبيقات الميدانية مقصد معماري أصيل في RAWAEA.
- المرسل يعيش داخل سياق الفرع المصدر.
- المستلم يعيش داخل سياق الفرع الوجهة.
- الـUI ينفذ.
- الـRPC يحكم.
- Trigger يحرس العقد.
- inventory_log يسجل الأثر.
- النظام الأم يراقب ويملك السلطة العليا.

هذا يحافظ على الميزة الميدانية التي بُني عليها المشروع على مدى أشهر.

---

# 24. Deployment / Browser E2E

Production DB/RPC:

**متحقق فعليًا.**

E2E المعاملي:

**PASS.**

Browser E2E المنشور السابق:

**OPEN**

سبب الفتح ليس فشلًا في عقد Transfer الذي اختُبر، وإنما فشل Harness السابق:

`INLINE_SCRIPT_NOT_FOUND`

لذلك لا يجوز إعلان Browser E2E مغلقًا قبل تصحيح الـharness أو إجراء browser test فعلي على النسخة المنشورة بعد تطبيق Source patch.

---

# 25. مبادئ حاكمة جديدة

## P-01 — مسؤولية العملية تُربط بالهوية وليس بالدور فقط

الـrole يحدد القدرة العامة.

لكن العملية التنفيذية الحرجة تحتاج أيضًا:

`specific responsible user`

## P-02 — Partial receive له نفس مستوى الحماية للـFull receive

لا يكفي حماية الانتقال النهائي للحالة.

يجب حماية **كل mutation**.

## P-03 — Sender ≠ Receiver

في Transfer:

`sender_user_id ≠ receiver_user_id`

عمليًا هو:

`actor.id ≠ receiver_user_id`

## P-04 — UI لا يمنح السلطة

الواجهة تخفي/تظهر الزر المناسب، لكن Production هو الحارس النهائي.

## P-05 — Destination ≠ Source scope

مرسل التحويل يملك نطاق مصدره.

ولا يجوز استخدام نطاق المصدر لمنع اختيار الوجهة.

## P-06 — Table is navigation; Modal is control surface

القائمة للاستعراض.

المودال هو مساحة التحكم في الإذن.

## P-07 — No new Edge Functions when an existing central capability exists

المعالجة تتم بإعادة استخدام الموجود وتحديث الـRPC المركزي عند الحاجة.

## P-08 — No closure without downstream proof

كل إغلاق يجب أن يثبت:

UI → API/RPC → DB → audit → stock → downstream.

---

# 26. تعليمات البداية للجلسة التالية

ابدأ من:

1. Current Production بعد Migration:
   `harden_transfer_partial_receive_actor_20260928`
2. Current Source:
   `vouchers.html` SHA:
   `9e3a9cbd0124639934cdf98abc9ec579f4b19f61`
3. تحقق أن المالك طبّق:
   - T-09
   - T-10
   - T-11
   - T-12
   - T-13
   - T-14
   - T-15
4. لا تعد إصلاح Production guard الذي ثبت نجاحه.
5. تحقق Browser E2E على النسخة المنشورة.
6. اختبر Transfer حقيقيًا:
   - sender BR-01
   - receiver BR-2
   - partial
   - replay
   - remainder
   - complete
7. بعد إغلاق Browser E2E انتقل إلى أول Business Contract Gap حقيقي غير مغلق، وليس إعادة ترتيب UI سبق إغلاقه.

---

# 27. Self Audit

### Source reading
- Master Governance: PASS
- CURRENT_STATE: PASS
- Report348: PASS
- vouchers.html current: PASS
- picker historical/current inspection: PASS
- van-sales inspection: PASS

### Production
- Existing trigger verified: PASS
- Existing RPC verified: PASS
- Existing Edge receive verified: PASS
- Production hardening applied: PASS

### Security
- Partial unauthorized receive: BLOCKED
- Bound receiver partial receive: PASS
- Sender self-receive: BLOCKED
- Receiver binding preserved: PASS
- Idempotent replay: PASS

### Stock
- Source delta: -1
- Destination delta: +1
- Movement count: 3
- Test residue: 0

### Cleanup
- Legacy QA drafts IN-6 / IN-7: REMOVED
- Legacy completed QA with financial/stock effects: PRESERVED pending controlled reversal evidence

### UX contract
- Current Source table: NOT YET APPLIED
- Current Source buttons-inside-modal: NOT YET APPLIED
- Surgical replacements: READY

### Main
- `main.html`: NOT TOUCHED

---

# 28. Closure statement

تم **إغلاق طبقة Production الأمنية الحرجة للاستلام الجزئي**.

تم **إثبات دورة Transfer في قاعدة البيانات End-to-End**.

لم يتم إعلان إغلاق UI لأن Source patch لم يُطبّق بعد، احترامًا لقيد عدم التعديل المباشر على `vouchers.html`.

النقطة التالية الوحيدة اللازمة لإغلاق الهدف الحالي هي:

**تطبيق حزمة Source الجراحية T-09 → T-15 على `companies/company-1/warehouse/vouchers.html` ثم Browser E2E على النسخة المنشورة.**

بعدها فقط يُعاد تقييم الإغلاق النهائي للتبويب.
