# Report286 — Warehouse Stock Vouchers / Custodian Identity Forensic Closure — 2026-09-21

## 1. نطاق الجلسة

النطاق الوحيد:
- Warehouse Management → Inventory → Stock Vouchers.
- التكامل مع Van Sales / Vehicle Mobile Stock.
- Production Supabase.
- المصدر الحالي في `erp-frontend`.
- مقارنة العقد مع Odoo / Dynamics 365 / SAP / Daftra / Manager.io.
- تجهيز التعديل الجراحي في `companies/company-1/warehouse/vouchers.html`.

الممنوعات التي تم احترامها:
- لم يتم تعديل `main.html`.
- لم يتم تعديل `companies/company-1/warehouse/vouchers.html` بواسطة CTO.
- لم يتم تعديل `companies/company-1/sales/van-sales.html`.
- لم يتم إنشاء Edge Function جديدة.
- لم يتم إعادة تنفيذ migrations سبق إغلاقها.
- لم يتم إعادة فتح Physical Stock Core المغلق.

---

## 2. الحالة المرجعية التي تم التحقق منها

### System repository
Repository: `papamohammed77-glitch/rawaie-erp-New`

HEAD عند بداية التحقيق:
`163cc14038d6fb723f22b53925492087f82f7df2`

Parent:
`67e548a0269111009de237904739d1c40aed63dc`

آخر حالة مسجلة قبل هذا التقرير كانت Report285.

### Mother frontend repository
Repository: `papamohammed77-glitch/erp-frontend`

HEAD:
`c30e3a6c1f1233ed14acb77081392efab53b36dd`

Parent:
`7efa2dfe17ddd10cc410d3887cc9876d630aa319`

Current `vouchers.html` blob:
`e0601ac380b499178b9e5759d0850d43a0d914c2`

Current `van-sales.html` blob:
`a914c3e268c8801533051a3f0901c0db5919ee64`

### Important chronology correction

Report285 وصف عيبًا parser في `vouchers.html` وعيب تسجيل Service Worker.

آخر Mother commit `c30e3a6...` أصلح هذين العيبين بالفعل.

لذلك:
- لا يوجد إعادة إصلاح لهما.
- لا يوجد Parser rebuild جديد.
- لا يوجد Service Worker جديد.

---

## 3. إعادة بناء العقد التاريخي

ملف:
`rawaie-erp-review/Architecture/الأذونات المخزنية اليدوية.md`

تمت قراءته كاملًا حتى النهاية.

العقد التاريخي يثبت أن Manual Stock Vouchers مخصصة للعمليات التي لا تعتمد على Order / Runsheet، وتشمل:
- Transfer.
- DirectSale.
- DirectReturn.
- SupplierReturn.
- Scrap.
- Adjustment.

كما يثبت أن DirectSale هو تحميل عهدة مبيعات متنقلة قبل البيع، وليس بيعًا فعليًا للعميل.

والعقد التشغيلي الأهم:
البضاعة التي تخرج في DirectSale تدخل في عهدة مندوب البيع المباشر، بينما المركبة هي وعاء / mobile stock container.

هذا يطابق منطق التشغيل الميداني الحالي:
Warehouse → Custodian Representative + Vehicle Container → Van Sales → EOD Settlement.

---

## 4. التحقيق في المصدر الحالي

### Vouchers application

المصدر الحالي يحتوي بالفعل على Contract صحيح في شاشة الإنشاء:

`routeHtml()` عند السطر 888:
- DirectSale = Branch → Direct-Sales Representative → Vehicle.
- DirectReturn = Vehicle → Direct-Sales Representative → Branch.

والـ`submit()` عند السطر 1029 يتحقق من:
- وجود المندوب.
- وجود المركبة.
- `vehicle.driver_id === representative.id`.
- Company / branch scope.
- Mobile branch validity.

ويُرسل إلى الـEdge الحالي:
- `rep_id`.
- `operation_id`.
- from/to.
- items.

### المشكلة ليست في مسار الإنشاء الحالي

المشكلة في طبقة الوثيقة نفسها:

`stock_vouchers` لم يكن يحتوي على حقل ثابت لصاحب العهدة.

الـrep كان يدخل في:
- validation.
- operation fingerprint.
- API payload.

لكن لم يكن محفوظًا كجزء من رأس الإذن.

نتيجة ذلك:
- المركبة كانت ظاهرة كموقع / وعاء.
- صاحب العهدة كان يُستنتج من `vehicle.driver_id`.
- الوثيقة التاريخية نفسها لا تحمل identity صريحة للمسؤول.

هذه فجوة Business Contract حقيقية وليست مشكلة شكلية.

---

## 5. Production evidence

الحالة الحالية قبل الإصلاح كانت تحتوي:

`stock_vouchers`:
- `IN-1`
- type = DirectSale
- status = Draft
- from = Branch
- to = Vehicle
- Vehicle = `VEH-TEST-260921`
- vehicle.driver_id = `111b0730-a977-4d11-bcd0-2427b178a9e5`
- driver = مندوب مبيعات بيع مباشر.

والـaudit create event كان يحفظ:
- to_type = Vehicle
- to_id = vehicle id

لكن دون custodian field.

هذا هو الإثبات المباشر لسبب الخطأ.

---

## 6. Production surgical fix — منفذ بالفعل

تم تطبيق migration:

`20260921_stock_voucher_custodian_identity_guard`

### ما تم تنفيذه

أضيف:

`stock_vouchers.custodian_user_id uuid`

مع:
- FK إلى `users.id`.
- ON DELETE RESTRICT.
- index:
  `idx_stock_vouchers_custodian_user_id`.

### Backfill

تمت مطابقة DirectSale / DirectReturn الموجودة من `vehicle.driver_id`.

النتيجة الحالية:
- IN-1 أصبح يحمل:
  `custodian_user_id = 111b0730-a977-4d11-bcd0-2427b178a9e5`.

### Guard

تم إنشاء:

`public.enforce_stock_voucher_custodian()`

وظيفتها:
1. DirectSale / DirectReturn فقط.
2. تثبيت أن endpoint المركبة صحيح.
3. جلب المركبة داخل Company scope.
4. التأكد من أن للمركبة مندوبًا مباشرًا.
5. اشتقاق custodian من vehicle.driver_id إذا لم يكن مدخلًا.
6. رفض أي custodian لا يطابق مندوب المركبة.
7. التأكد من أن custodian مستخدم Active وله role = مندوب بيع مباشر.
8. منع تغيير identity بعد الوصول إلى Sent / Received / Completed.

### Constraint

تمت إضافة:

`stock_vouchers_mobile_custodian_required_ck`

DirectSale / DirectReturn لا يمكن أن تكون بدون custodian.

### Audit

المسار التاريخي الحالي:
`trg_audit_stock_vouchers`
→ `fn_audit_trigger()`

وظل كما هو.

بالتالي إضافة custodian لا تقطع الـaudit trail؛ بل دخلت في `new_data` تلقائيًا.

---

## 7. E2E Production verification

اختبار Transactional كامل تم تنفيذه ثم Rollback.

### CREATE
تم إنشاء DirectSale مؤقت:
- Branch المصدر صحيح.
- Vehicle صحيح.
- Representative صحيح.
- operation_id ثابت.

النتائج:
- CREATE = PASS.
- custodian persisted = PASS.
- custodian = vehicle.driver_id = PASS.

### CREATE idempotency
إعادة نفس operation_id:

`duplicate = true`

= PASS.

### SEND
تم التنفيذ من خلال:

`send_stock_voucher_atomic`
→ `send_stock_voucher_atomic_core_20260828`
→ `post_stock_movement`

النتائج:
- SEND = PASS.
- Physical stock delta = `2.0000 → 1.0000`.
- inventory_log = row واحدة.

### SEND retry
إعادة SEND:

`duplicate = true`

ولم تتكرر الحركة.

### Audit
سجل CREATE في audit_log احتوى على:
`custodian_user_id = 111b0730-a977-4d11-bcd0-2427b178a9e5`

= PASS.

### Invalid custodian
محاولة إنشاء DirectSale بمستخدم ليس `مندوب بيع مباشر`:

رفضت Production الطلب بالرسالة:
`مندوب البيع المباشر غير صالح ضمن الشركة`

= PASS.

### Production data hygiene correction
خلال final snapshot ظهر سجل E2E تجريبي \\`IN-2\\` كان قد أُنشئ خارج Transaction في اختبار سابق.
تم التحقق من هويته من خلال:
- reference = \\`E2E-CUSTODIAN-0921\\`.
- type = DirectSale.
- status = Draft.
- عدم وجود inventory movement مرتبطة به.

تم حذف \\`IN-2\\` وoperation registry المرتبط به مباشرةً من Production.

Final Production snapshot بعد التنظيف:
- stock_vouchers = 1.
- stock_voucher_details = 3.
- stock_voucher_operations = 1.
- inventory_log = 3.
- DirectSale/DirectReturn missing custodian = 0.

السجل المقصود كـdemo المستمر هو \\`IN-1\\` وليس \\`IN-2\\`.

---

## 8. Van Sales forensic result

ملف:
`companies/company-1/sales/van-sales.html`

Current blob:
`a914c3e268c8801533051a3f0901c0db5919ee64`

آخر الإغلاقات المثبتة ما زالت صحيحة:
- authenticated driver context.
- canonical mobile branch.
- mobile_branch_id.
- operation_id retry identity.
- Van Sale → existing `save-sales-invoice`.
- physical stock → `post_stock_movement`.

لم يثبت في هذه الجلسة Regression جديد يستدعي إعادة تعديل Van Sales.

### النتيجة

لا يتم لمس Van Sales في هذه closure.

الـintegration الصحيح أصبح:

Vouchers:
`Branch`
→ `Custodian Representative`
+
`Vehicle Container`

Van Sales:
`Custodian Representative`
→ يستخدم Mobile Branch المربوط بالمركبة
→ ينفذ المبيعات
→ settlement / reconciliation.

---

## 9. لماذا هذا الحل ليس ترقيعًا

الحل لا يعتمد على عرض الاسم في HTML فقط.

الحماية الآن ثلاثية:

1. UI:
المندوب والمركبة كلاهما محددان.

2. API/RPC:
`rep_id` موجود ومتحقق منه.

3. Database:
`custodian_user_id` أصبحت جزءًا من رأس المستند وتفرض عليها قيود FK + business trigger + immutability.

وبالتالي لا تعتمد المسؤولية القانونية أو الرقابية على:
`vehicle.driver_id`
كمعلومة مشتقة فقط.

---

## 10. مقارنة مع الأنظمة المنافسة

### Odoo

Odoo Inventory يبني الحركات على Source / Destination والـOperation Type، ويعالج internal transfers كحركات مادية منظمة. هذا ينسجم مع فصل مكان الحركة عن المسؤولية التشغيلية.

Official:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/inventory_management/use_locations.html

### Microsoft Dynamics 365

Inventory journals تتضمن:
- Movement.
- Inventory adjustment.
- Transfer.
- Counting.

والـTransfer يعتمد على from/to inventory dimensions، وليس على شاشة تجميلية فقط.

Official:
https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/inventory-journals

### SAP

SAP Goods Movement يميز:
- Goods Receipt.
- Goods Issue.
- Physical Stock Transfer.
- Transfer Posting.

والـGoods Movement موثق في Material/Stock Documents وتقارير الحركة.

Official:
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/91b21005dded4984bcccf4a69ae1300c/742e46e570984d9aa74e468838f6e1ff.html

### Daftra

Daftra يقدم مثالًا مباشرًا على فصل inventory responsibility عن مجرد موقع تخزين:
- يمكن إنشاء warehouse باسم الموظف.
- تخصيص المخزون لمسؤولية الموظف.
- متابعة detailed inventory transactions.
- تنفيذ stocktaking على مخزون الموظف.

Official:
https://docs.daftra.com/en/user_manual/how-to-assign-inventory-to-an-employee/

هذه النقطة هي الأقرب إلى Business Contract الخاص بروائع:
الموظف هو المسؤول عن العهدة، والمخزون له مكان/وعاء تشغيلي يمكن تتبعه.

### Manager.io

Inventory Transfers تعتمد على انتقال المخزون من Location إلى Location مع تسجيل source/destination والكمية.

Official:
https://www.manager.io/guides/inventory-transfers

---

## 11. التعديل الجراحي المطلوب من مالك الملف

### الملف الوحيد المطلوب تعديله يدويًا

`companies/company-1/warehouse/vouchers.html`

### PATCH A — filterList

ابحث حرفيًا عن:

`filterList:function(){`

عند السطر:
`155`

احذف الدالة كاملة حتى بداية:

`},cards:function(rows,scope){`

واستبدلها بالدالة التالية:

```javascript
filterList:function(){
    var s=this;

    var q=s.norm(
        (RW_UI.byId('listSearch')||{}).value||''
    );

    var type=
        (RW_UI.byId('listType')||{}).value||'';

    var from=
        (RW_UI.byId('listFrom')||{}).value||'';

    var to=
        (RW_UI.byId('listTo')||{}).value||'';

    if(from&&to&&from>to){
        RW_UI.toast(
            'الفترة الزمنية غير صحيحة',
            'warning'
        );
        return;
    }

    var labels={
        Transfer:'تحويل مخزني',
        DirectSale:'صرف سيارة بيع مباشر',
        DirectReturn:'استلام مرتجع سيارة',
        SupplierReturn:'مرتجع لمورد'
    };

    var statusLabels={
        Draft:'مسودة',
        Sent:'مُرسل',
        Received:'مُستلم',
        Completed:'مكتمل',
        Cancelled:'ملغى'
    };

    var rows=this.vouchers.filter(function(v){

        var fromText=s.loc(
            v.from_id,
            v.from_type
        );

        var toText=s.loc(
            v.to_id,
            v.to_type
        );

        var haystack=[
            v.voucher_code,
            v.reference,
            v.type,
            labels[v.type],
            v.status,
            statusLabels[v.status],
            fromText,
            toText,
            v.created_by,
            v.notes,
            (function(){
                if(!v.custodian_user_id) return '';
                var rep=(s.refs.reps||[]).find(function(r){
                    return r.id===v.custodian_user_id;
                });
                return rep ? (rep.name||rep.email||'') : '';
            })()
        ].map(function(x){
            return s.norm(x);
        });

        var textMatch=
            !q||
            haystack.some(function(x){
                return x.includes(q);
            });

        var typeMatch=
            !type||
            v.type===type;

        var date=
            String(v.voucher_date||'').slice(0,10);

        var fromMatch=
            !from||
            date>=from;

        var toMatch=
            !to||
            date<=to;

        return(
            textMatch&&
            typeMatch&&
            fromMatch&&
            toMatch
        );
    });

    RW_UI.safeText(
        RW_UI.byId('listCount'),
        String(rows.length)
    );

    var box=RW_UI.byId('listCards');

    if(!box){
        return;
    }

    RW_UI.safeHTML(
        box,
        this.cards(rows,this.tabName)
    );

```

### PATCH B — cards

ابحث حرفيًا عن:

`cards:function(rows,scope){`

عند السطر:
`265`

احذف الدالة كاملة حتى:

`},loc:function`

واستبدلها بالدالة التالية:

```javascript
},cards:function(rows,scope){

    var s=this;

    if(!rows.length){

        return (
            '<div class="card text-center py-14">'+
                '<div class="text-5xl mb-3">☕</div>'+
                '<b class="text-slate-400">لا توجد أذونات</b>'+
            '</div>'
        );
    }

    return rows.map(function(v){

        var c =
            v.status==='Draft'
                ?'bg-amber-100 text-amber-700'
                :v.status==='Sent'
                    ?'bg-blue-100 text-blue-700'
                    :v.status==='Received'
                        ?'bg-emerald-100 text-emerald-700'
                        :v.status==='Cancelled'
                            ?'bg-rose-100 text-rose-700'
                            :'bg-slate-100 text-slate-700';

        var l =
            v.status==='Draft'
                ?'مسودة'
                :v.status==='Sent'
                    ?'مُرسل'
                    :v.status==='Received'
                        ?'مُستلم'
                        :v.status==='Completed'
                            ?'مكتمل'
                            :'ملغى';

        var a='';

        if(scope==='pending'){

            var act=s.actionFor(v);

            if(act==='draft'){

                a+=
                    '<button onclick="event.stopPropagation();App.send(\''+
                    s.esc(v.voucher_code)+
                    '\')" class="bg-indigo-600 text-white px-3 py-2 rounded-xl text-xs font-black">إرسال</button>';

                a+=
                    '<button onclick="event.stopPropagation();App.cancel(\''+
                    s.esc(v.voucher_code)+
                    '\')" class="bg-rose-600 text-white px-3 py-2 rounded-xl text-xs font-black">إلغاء</button>';
            }

            if(act==='receive'){

                a+=
                    '<button onclick="event.stopPropagation();App.receive(\''+
                    s.esc(v.voucher_code)+
                    '\')" class="bg-emerald-600 text-white px-3 py-2 rounded-xl text-xs font-black">استلام</button>';
            }

            if(act==='complete'){

                a+=
                    '<button onclick="event.stopPropagation();App.complete(\''+
                    s.esc(v.voucher_code)+
                    '\')" class="bg-violet-600 text-white px-3 py-2 rounded-xl text-xs font-black">إكمال</button>';
            }
        }

        var fromText=s.loc(
            v.from_id,
            v.from_type
        );

        var toText=s.loc(
            v.to_id,
            v.to_type
        );

        var custodianText='—';

        if(
            (v.type==='DirectSale'||v.type==='DirectReturn') &&
            v.custodian_user_id
        ){
            var rep=(s.refs.reps||[]).find(function(r){
                return r.id===v.custodian_user_id;
            });

            if(rep){
                custodianText=rep.name||rep.email||'—';
            }
        }

        return (
            '<div class="card mb-3 cursor-pointer" onclick="App.details(\''+
                s.esc(v.voucher_code)+
            '\')">'+

                '<div class="flex flex-col gap-3">'+

                    '<div class="flex justify-between gap-3">'+

                        '<div class="flex-1 min-w-0">'+

                            '<div class="flex items-center gap-2 flex-wrap">'+
                                '<span class="text-[10px] text-slate-400 font-bold">رقم الإذن</span>'+
                                '<b class="text-base">'+
                                    s.esc(v.voucher_code)+
                                '</b>'+
                                '<span class="px-2 py-1 rounded-full text-[10px] font-bold '+c+'">'+
                                    l+
                                '</span>'+
                            '</div>'+

                            '<div class="grid grid-cols-1 sm:grid-cols-3 gap-2 mt-3">'+

                                '<div class="p-2.5 rounded-xl bg-slate-50">'+
                                    '<span class="block text-[9px] text-slate-400 font-bold">المرجع</span>'+
                                    '<b class="block text-xs mt-1">'+
                                        s.esc(v.reference||'—')+
                                    '</b>'+
                                '</div>'+

                                '<div class="p-2.5 rounded-xl bg-slate-50">'+
                                    '<span class="block text-[9px] text-slate-400 font-bold">التاريخ</span>'+
                                    '<b class="block text-xs mt-1">'+
                                        s.esc(v.voucher_date||'—')+
                                    '</b>'+
                                '</div>'+

                                '<div class="p-2.5 rounded-xl bg-slate-50">'+
                                    '<span class="block text-[9px] text-slate-400 font-bold">النوع</span>'+
                                    '<b class="block text-xs mt-1">'+
                                        s.esc(v.type||'—')+
                                    '</b>'+
                                '</div>'+

                            '</div>'+

                            '<div class="mt-2 text-[10px] text-slate-500">'+
                                s.esc(fromText)+
                                ' → '+
                                s.esc(toText)+
                            '</div>'+

                            (
                                (v.type==='DirectSale'||v.type==='DirectReturn')
                                ?
                                '<div class="mt-2 p-2.5 rounded-xl bg-amber-50 border border-amber-100">'+
                                    '<span class="block text-[9px] text-amber-600 font-bold">المستلم والمسؤول عن العهدة</span>'+
                                    '<b class="block text-xs mt-1 text-amber-900">'+
                                        s.esc(custodianText)+
                                    '</b>'+
                                '</div>'
                                :
                                ''
                            )+

                        '</div>'+

                        '<div class="flex gap-2 flex-wrap justify-end items-start">'+
                            a+
                        '</div>'+

                    '</div>'+

                '</div>'+

            '</div>'
        );

    }).join('');
},
loc:function(id,type){var a=type==='Branch'?this.refs.branches:type==='Vehicle'?this.refs.vehicles:this.refs.suppliers,x=(a||[]).find(function(z){return z.id===id});if(!x)return'غير معروف';return type==='Vehicle'?(x.vehicle_code||x.license_plate||x.model||'غير معروف'):type==='Supplier'?(x.name||x.supplier_code||'غير معروف'):(x.name||x.branch_code||'غير معروف')},

```

### PATCH C — details

ابحث حرفيًا عن:

`details:function(code){`

عند السطر:
`417`

احذف الدالة كاملة حتى بداية:

`},callAction:function`

واستبدلها بالدالة التالية:

```javascript
details:function(code){
    var s=this;

    RW_UI.showLoader();

    supabase
        .rpc(
            'inventory_control',
            {
                p_operation:'VOUCHER_AUDIT',
                p_payload:{
                    voucher_code:code
                }
            }
        )
        .then(function(r){

            RW_UI.hideLoader();

            if(r.error){
                throw new Error(
                    r.error.message||
                    'تعذر قراءة بيانات الإذن'
                );
            }

            var data=r.data||{};
            var v=data.voucher;

            var custodianText='—';
            var vehicleText='—';

            if(
                v &&
                (v.type==='DirectSale'||v.type==='DirectReturn')
            ){
                if(v.custodian_user_id){
                    var rep=(s.refs.reps||[]).find(function(r){
                        return r.id===v.custodian_user_id;
                    });

                    if(rep){
                        custodianText=rep.name||rep.email||'—';
                    }
                }

                vehicleText=
                    v.type==='DirectSale'
                        ?s.loc(v.to_id,'Vehicle')
                        :s.loc(v.from_id,'Vehicle');
            }

            if(!v){
                throw new Error('الإذن غير موجود');
            }

            var d=Array.isArray(data.details)
                ?data.details
                :[];

            var aud=Array.isArray(data.audit)
                ?data.audit
                :[];

            var movements=Array.isArray(data.movements)
                ?data.movements
                :[];

            var aH=aud.length
                ?aud.map(function(x){
                    var op=x.operation_id
                        ?'<br>Operation: '+s.esc(x.operation_id)
                        :'';

                    return(
                        '<div class="text-xs border-b py-2">'+
                        '<b>'+s.esc(x.action||'')+'</b>'+
                        ' · '+
                        s.esc(x.user_email||'system')+
                        '<span class="text-slate-400">'+
                        ' · '+
                        s.esc(x.created_at||'')+
                        '</span>'+
                        op+
                        '</div>'
                    );
                }).join('')
                :
                '<div class="text-xs text-slate-400">لا توجد سجلات تدقيق متاحة لهذه الوثيقة</div>';

            var movementH=movements.length
                ?movements.map(function(x){

                    var from=x.source_branch_id
                        ?s.loc(x.source_branch_id,'Branch')
                        :'—';

                    var to=x.target_branch_id
                        ?s.loc(x.target_branch_id,'Branch')
                        :'—';

                    return(
                        '<tr class="border-t">'+
                        '<td class="p-2 text-xs">'+
                        s.esc(x.item_name||x.item_code||'')+
                        '<div class="text-[10px] text-slate-400">'+
                        s.esc(x.item_code||'')+
                        '</div>'+
                        '</td>'+
                        '<td class="p-2 text-center text-xs">'+
                        s.esc(x.movement_type||'')+
                        '</td>'+
                        '<td class="p-2 text-center">'+
                        f(x.qty)+
                        '</td>'+
                        '<td class="p-2 text-xs">'+
                        s.esc(from)+
                        ' → '+
                        s.esc(to)+
                        '</td>'+
                        '<td class="p-2 text-xs">'+
                        s.esc(x.user_email||'system')+
                        '</td>'+
                        '</tr>'
                    );
                }).join('')
                :
                '<tr><td colspan="5" class="p-4 text-center text-slate-400">لا توجد حركة فعلية مسجلة لهذا الإذن حتى الآن</td></tr>';

            var h=
                '<div class="text-right">'+

                '<div class="grid grid-cols-2 gap-2 text-xs mb-3">'+
                '<div class="p-3 bg-slate-50 rounded-2xl">النوع<br><b>'+s.esc(v.type)+'</b></div>'+
                '<div class="p-3 bg-slate-50 rounded-2xl">الحالة<br><b>'+s.esc(v.status)+'</b></div>'+
                '<div class="p-3 bg-slate-50 rounded-2xl">المصدر<br><b>'+s.esc(s.loc(v.from_id,v.from_type))+'</b></div>'+
                '<div class="p-3 bg-slate-50 rounded-2xl">الوجهة<br><b>'+s.esc(s.loc(v.to_id,v.to_type))+'</b></div>'+
                ((v.type==='DirectSale'||v.type==='DirectReturn')
                    ?
                    '<div class="p-3 bg-amber-50 border border-amber-100 rounded-2xl">المستلم والمسؤول عن العهدة<br><b>'+s.esc(custodianText)+'</b></div>'+
                    '<div class="p-3 bg-slate-50 rounded-2xl">المركبة / وعاء النقل<br><b>'+s.esc(vehicleText)+'</b></div>'
                    :
                    '')+
                '<div class="p-3 bg-slate-50 rounded-2xl">أنشأ بواسطة<br><b>'+s.esc(v.created_by||'—')+'</b></div>'+
                '<div class="p-3 bg-slate-50 rounded-2xl">أكمل بواسطة<br><b>'+s.esc(v.completed_by||'—')+'</b></div>'+
                '</div>'+

                '<div class="mb-3 text-xs text-slate-500">'+
                'المرجع: '+s.esc(v.reference||'—')+
                '<br>المصدر: '+s.esc(v.source||'—')+
                '<br>تاريخ الإنشاء: '+s.esc(v.created_at||'—')+
                '<br>الإرسال: '+s.esc(v.sent_date||'—')+
                '<br>الاستلام: '+s.esc(v.received_date||'—')+
                '<br>الإكمال: '+s.esc(v.completed_at||'—')+
                '<br>ملاحظات: '+s.esc(v.notes||'—')+
                '</div>'+

                '<div class="border rounded-2xl overflow-auto">'+
                '<table class="w-full text-sm">'+
                '<thead class="bg-slate-100">'+
                '<tr>'+
                '<th class="p-3">الصنف</th>'+
                '<th class="p-3">الكمية</th>'+
                '<th class="p-3">المستلم</th>'+
                '<th class="p-3">المتبقي</th>'+
                '</tr>'+
                '</thead>'+
                '<tbody>'+
                d.map(function(x){
                    return(
                        '<tr class="border-t">'+
                        '<td class="p-3">'+
                        s.esc(x.item_name||x.item_code)+
                        '</td>'+
                        '<td class="p-3 text-center">'+
                        f(x.qty)+
                        '</td>'+
                        '<td class="p-3 text-center">'+
                        f(x.received_qty)+
                        '</td>'+
                        '<td class="p-3 text-center">'+
                        f(Math.max(
                            0,
                            Number(x.qty||0)-
                            Number(x.received_qty||0)
                        ))+
                        '</td>'+
                        '</tr>'
                    );
                }).join('')+
                '</tbody>'+
                '</table>'+
                '</div>'+

                '<div class="mt-4 border rounded-2xl overflow-auto">'+
                '<div class="p-3 bg-slate-100 font-black text-sm">الحركات الفعلية المرتبطة</div>'+
                '<table class="w-full text-sm">'+
                '<thead class="bg-slate-50">'+
                '<tr>'+
                '<th class="p-2">الصنف</th>'+
                '<th class="p-2">نوع الحركة</th>'+
                '<th class="p-2">الكمية</th>'+
                '<th class="p-2">المسار</th>'+
                '<th class="p-2">المنفذ</th>'+
                '</tr>'+
                '</thead>'+
                '<tbody>'+
                movementH+
                '</tbody>'+
                '</table>'+
                '</div>'+

                '<details class="mt-4">'+
                '<summary class="cursor-pointer font-black text-sm">سجل التدقيق</summary>'+
                '<div class="mt-2">'+aH+'</div>'+
                '</details>'+

                '</div>';

            Swal.fire({
                title:'تفاصيل الإذن '+s.esc(code),
                html:h,
                width:940,
                showConfirmButton:false,
                showCloseButton:true,
                customClass:{
                    popup:'!rounded-3xl'
                }
            });
        })
        .catch(function(e){
            RW_UI.hideLoader();
            RW_UI.showError(
                e.message||
                'تعذر تحميل تفاصيل الإذن'
            );
        });
},
callAction:function(name,code,successText){
    var s=this;
    var busyKey=name+':'+code;

    if(this.busy[busyKey])return;

    this.busy[busyKey]=true;

    RW_UI.showLoader();

    RW_API.call(
        name,
        {voucher_code:code},
        function(j){
```

### لماذا هذه التعديلات الثلاثة فقط؟

لأن:
- routeHtml صحيح.
- submit صحيح.
- create operation identity موجود.
- rep_id موجود في payload.
- backend Production أصبح يحفظ custodian.
- inventory_control يرجع `to_jsonb(voucher)`، ولذلك سيصل الحقل تلقائيًا.

المطلوب فقط جعل الوثيقة المرئية:
- توضح صاحب العهدة.
- تفصل بينه وبين المركبة.
- تسمح بالبحث عنه.
- تعرضه في التفاصيل والمراقبة.

---

## 12. ما لم يتم تغييره

- `main.html`: 0.
- `vouchers.html`: 0 كتابة من CTO.
- `van-sales.html`: 0.
- Physical Stock Core: 0 إعادة بناء.
- New Edge Functions: 0.
- Closed inventory migrations: 0 إعادة تنفيذ.

---

## 13. الحالة الحالية النهائية

### Production
- Custodian column = DEPLOYED.
- Custodian FK = DEPLOYED.
- Custodian trigger = DEPLOYED.
- Existing DirectSale backfill = VERIFIED.
- Physical stock remains centralized.
- CREATE E2E = PASS.
- CREATE retry = PASS.
- SEND E2E = PASS.
- SEND retry = PASS.
- Audit preservation = PASS.
- Invalid custodian rejection = PASS.
- Final persistent test pollution = 0 after explicit IN-2 cleanup.

### Source
- Current vouchers source = VERIFIED.
- Current Van Sales source = VERIFIED.
- Main source not touched.
- Previous parser/SW regressions already fixed in Mother HEAD and not repeated.

### UI
UI semantic patch = READY.
UI patch application = OWNER ACTION.
Browser E2E = OPEN until owner applies patches and the deployed frontend actually loads this exact Mother revision.

---

## 14. SELF-AUDIT

### What I Proved
- أصل الخطأ في DirectSale كان غياب persisted custodian identity داخل voucher header.
- Production كان يعتمد عمليًا على vehicle.driver_id كهوية مشتقة.
- current vouchers UI كان قد قطع شوطًا صحيحًا بالفعل في اختيار rep + vehicle.
- Van Sales لا يحتاج إعادة إصلاح حاليًا.
- Production now enforces custodian integrity.
- physical stock is still centralized.
- retries remain idempotent.

### What I Did Not Prove
- Browser execution على build المنشور بعد تطبيق Owner patches لم يتم إثباته هنا لأن `vouchers.html` لم يُكتب إليه من CTO حسب النطاق.
- لا يتم إعلان UI 100% closed قبل Browser E2E.

### What I Fixed
- Production data contract for DirectSale/DirectReturn custody.
- Existing current DirectSale backfill.
- database enforcement.

### What I Initially Missed
- لم يكن الخلل الحقيقي في اختيار المركبة وحدها؛ كان في عدم تخزين صاحب العهدة داخل document identity نفسه.

### What Could Still Be Wrong
- Owner could apply patch to a different revision than `c30e3a6...`.
- Deployed static site may not yet point to current Mother HEAD.
- Browser E2E therefore remains the last external closure gate.

### Final Closure Status

`PRODUCTION CUSTODIAN CONTRACT = CLOSED`

`PHYSICAL STOCK CENTRALIZATION = CLOSED`

`VAN SALES BACKEND CONTRACT = CLOSED`

`VOUCHERS UI CUSTODIAN DISPLAY = READY / OWNER PATCH REQUIRED`

`BROWSER E2E = OPEN`

`GLOBAL INVENTORY ZERO-DEBT = NOT YET DECLARED 100%`

---

## 15. تعليمات البداية للمساعد التالي

1. Verify current System HEAD + parent.
2. Verify current Mother HEAD.
3. Fetch current `vouchers.html` blob.
4. Verify PATCH A/B/C are applied exactly once.
5. Do not touch `main.html`.
6. Do not rerun `20260921_stock_voucher_custodian_identity_guard`.
7. Re-read current Production custodian counts.
8. Run browser parser.
9. Run Browser E2E for:
   - login.
   - DirectSale workspace.
   - branch.
   - rep.
   - vehicle.
   - saved voucher list showing custodian.
   - details showing custodian + vehicle.
10. Re-snapshot Production immediately before final closure report.
11. Only then decide whether the Vouchers closure is 100%.



---

## 16. Final Production Snapshot — correction-verified

Verified after cleanup:
`stock_vouchers=1`
`stock_voucher_details=3`
`stock_voucher_operations=1`
`inventory_log=3`
`missing_custodian=0`
`IN-2=0`

`IN-1` remains the single intentional demo DirectSale record and carries the verified custodian identity.

The final state reported here supersedes any earlier count in this report that reflected the temporary `IN-2` test record.
