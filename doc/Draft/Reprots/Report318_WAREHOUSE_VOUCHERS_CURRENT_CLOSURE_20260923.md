# تقرير 318 — إغلاق أزمة تطبيق الأذونات المخزنية: الحالة الحالية + العلاج الجراحي النهائي
## التاريخ
23 سبتمبر 2026

## الحالة المرجعية
هذا التقرير بُني من:
CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.

التقارير 314–317 استُخدمت للسياق التاريخي فقط، ثم تمت مطابقة كل نقطة مع الحالة الحالية. لا توجد إعادة لإصلاحات ثبت إغلاقها.

---

# 1) نقاط الحقيقة الحالية

## System repository
- Repository: papamohammed77-glitch/rawaie-erp-New
- HEAD: `ce6341dc31effb79bd8e065d2c91e3eec75363b9`
- Parent: `6a0b744a6630d3358d9f23cf787f417258e6b2fd`
- Message: `fix(vouchers): align draft update RPC auth and operation identity`
- هذا الـcommit يثبت أن capability الموجودة أصلًا `create-stock-voucher` تدعم CREATE / UPDATE-DRAFT / DELETE-DRAFT، ولا توجد حاجة لإنشاء Edge Function جديدة.

## Frontend repository
- Repository: papamohammed77-glitch/erp-frontend
- HEAD: `c2ac6d33cb5c20ba6539f61cabde1b33866ecb46`
- Parent: `5cf09bac46aa65fa1e94ba34dfbdc3760cd446e2`
- Current `companies/company-1/warehouse/vouchers.html` SHA: `1bbca38299ff093798badaaafda6a2b986583527`
- Current `companies/company-1/sales/van-sales.html` SHA: `8d61382a8e0025a0d079e71dd94f33d106d9088e`
- Current Mother ERP `main.html` SHA: `8c3d6b05fd6a94a6b488f12b29da85ae888f70bc`

## ممنوعات هذه الجلسة
لم يتم تعديل:
- `companies/company-1/main.html`
- `companies/company-1/sales/van-sales.html`
- `companies/company-1/warehouse/vouchers.html`

التعديلات التالية موجهة للمالك لتطبيقها يدويًا في `vouchers.html` فقط.

---

# 2) قراءة الحالة والتاريخ

Mother ERP هو سطح التحكم الأبوي: المستخدمون، الأدوار، الفروع، المركبات، المناديب، الموردون وبقية السياق الإداري.

Standalone Vouchers هو سطح التنفيذ التشغيلي للأذونات غير المرتبطة مباشرة بدورة Order/Runsheet:

Transfer
`Branch → Branch`

DirectSale
`Branch → Vehicle`

DirectReturn
`Vehicle → Branch`

SupplierReturn
`Branch → Supplier`

الدورة الميدانية المميزة للمنظومة تبقى:
Order → Picking → Loading → Delivery → Return

ولم يتم دمج هذه الدورة داخل Vouchers.

Van Sales يبقى:
Field Sales + Vehicle Custody + Mobile Inventory
ويستخدم capability الموجودة `save-sales-invoice`، ولم يظهر في التحقيق الحالي عيب يستوجب تعديل الملف.

---

# 3) الحقيقة الحالية في Production

لقطة Production:
`2026-09-23 12:08:24.850358+00`

- companies = 1
- branches = 1
- vehicles = 0
- suppliers = 0
- direct reps = 1
- warehouse users with active_warehouse_role=أذونات = 1
- stock_vouchers = 0
- stock_voucher_details = 0
- items = 16
- stock_branches = 16
- inventory_log = 6
- stock_voucher_operations technical tombstones = 10
- QA items = 0
- QA branches = 0
- QA vehicles = 0
- QA suppliers = 0

الفرع الفعلي المتبقي هو BR-01 فقط. لا توجد مركبات أو موردون حقيقيون حاليًا داخل Production؛ هذا ليس عطلًا في شاشة البحث، بل هو واقع البيانات بعد تنظيف الـfixtures. تسجيل الكيانات الجديدة يبقى من Mother ERP.

---

# 4) التنظيف المنفذ

تم حذف فقط ما ثبت أنه QA ولا توجد له معاملات تشغيلية:

### Items
- `ITM-1057`
- `ITM-1058`
- `ITM-1059`
- `ITM-1060`

### QA inventory log
تم حذف سجلات فتح الرصيد التجريبية الخاصة بـ1058–1060.

### Branch
- `BR-2` — تم إثبات عدم وجود Orders / Purchase Orders / Stock Vouchers / User assignments / Vehicle mobile assignments، وكانت بقاياه مخزونًا تجريبيًا فقط؛ تم حذفها.

### Vehicles / Suppliers / QA Users
لا يوجد الآن أي كيان QA متبقٍ وفق فحص:
QA / TEST / ITM- patterns في Users / Branches / Vehicles / Suppliers / Items.

## ما لم يُحذف
التاريخ التشغيلي الحقيقي في `inventory_log` بقي محفوظًا، بما فيه:
- VoidInvoice التاريخي.
- ForensicRepair المستخدم سابقًا لتصحيح اتجاهات مخزنية.

## Operation tombstones
يوجد 10 سجلات تقنية في `stock_voucher_operations` بلا `voucher_id`.

هذه ليست vouchers أو stock rows وهمية. الـProduction trigger:
`guard_stock_voucher_operation_delete_integrity()`
يمنع حذفها صراحة لأنها سجل هوية ومنع تكرار العمليات.

**لا يتم كسر هذا العقد لمجرد تقليل عداد الصفوف.**

---

# 5) الحقيقة الجنائية للمشكلة الحالية

## العيب الأول — Smart Search Tokenization

الملف الحالي يحتوي في:
`App.pickSearch(key,q)`

على:

```javascript
tokens=z
    ?z.split(/s+/)
```

الصحيح:

```javascript
tokens=z
    ?z.split(/\s+/)
```

### الإثبات
باستخدام نفس function الحالية في harness:

- `QA VCH` على مركبة: FAIL
- `BR 01` على فرع: FAIL

بعد إصلاح regex نفسه:

- `QA VCH`: PASS
- `BR 01`: PASS

بينما البحث المفرد:
- vehicle code: PASS
- Arabic license plate: PASS
- representative name: PASS
- supplier code: PASS

إذن المشكلة ليست Missing Search Engine.

---

# 6) العيب الثاني — Realtime branch filter

النسخة الحالية تشترك في `stock_branches` بهذا النمط:

```javascript
filter:'branch_id=in.'+branchIds.join(',')
```

هذا يربط channel واحدًا بكل branch IDs التي تم تحميلها، وهو غير مناسب للتوسع الكبير، ويعيد نفس مشكلة قائمة IDs التي سبق إصلاحها في القراءة.

العلاج:
- stock_vouchers يبقى company scoped.
- stock_voucher_details يبقى live.
- stock_branches يصبح source-branch scoped فقط.
- عندما يتغير المصدر، يعاد بناء قناة realtime للمصدر الجديد.

لا يتم تعديل `prefetchStock`؛ هو بالفعل source-branch scoped في Current Source.

---

# 7) العيب الثالث — CRUD UI غير مكتمل رغم وجود Backend capability

Current Production + Current Git يثبتان وجود:
- UPDATE-DRAFT RPC
- DELETE-DRAFT RPC
- authenticated update path
- operation_id / idempotency

لكن Current UI في `cards()` يعطي المسودة:
- إرسال
- إلغاء

ولا يعطي:
- تعديل
- حذف

وهذا سبب فجوة وظيفية مباشرة.

العلاج الصحيح ليس إنشاء API جديد؛ بل توصيل الواجهة بالـcapability الموجودة.

---

# 8) العيب الرابع الذي يجب منعه أثناء إضافة Edit Mode

عند إدخال `mode='edit'` يجب ألا يبقى `editVoucherCode` عالقًا عند إنشاء إذن جديد.

لذلك يتم تصفير حالة التعديل في:
`App.choose()`
و
`App.back()`

حتى لا يحدث UPDATE غير مقصود لإذن قديم.

---

# 9) Backend proof — UPDATE / REPLAY / CONFLICT / DELETE

تم اختبار capability الحالية في Production باستخدام JWT claims لمستخدم الأذونات.

### CREATE
تم إنشاء Draft مؤقت:
- Type = Transfer
- Item = 1001
- operation_id = `QA-RESUME-CREATE-0923`

النتيجة:
PASS

### UPDATE
تم تعديل:
- destination branch
- quantity
- reference
- notes

النتيجة:
`duplicate=false`
PASS

### REPLAY
إعادة نفس:
`operation_id`
بنفس payload

النتيجة:
`duplicate=true`
PASS

### CONFLICT
إعادة نفس operation_id مع بيانات مختلفة

النتيجة:
`operation_id مستخدم مع بيانات مختلفة`
REJECTED / PASS

### DELETE
حذف الـDraft عبر:
`delete_manual_stock_voucher_atomic`

النتيجة:
`deleted=true`
PASS

هذا يثبت أن Backend capability ليست المشكلة.

---

# 10) Production auth proof

المسار الحالي:
`create-stock-voucher`
→ يتحقق من Authorization
→ يتحقق من `auth_id`
→ يستخرج `company_id`
→ UPDATE يستخدم RPC client محافظًا على JWT.

لا يوجد اعتماد جديد على `app_settings LIMIT 1` في هذا المسار.

لا توجد Edge Function جديدة.

---

# 11) العقد الذي يجب عدم المساس به

## Transfer
المخزني + `activeWarehouseRole='أذونات'` يستطيع التعامل مع جميع الفروع النشطة داخل نفس الشركة.

Current `App.allowedBranch()` وCurrent `pickArr()` يدعمان هذا العقد بالفعل.

**لا تعدل App.allowedBranch().**

**لا تعدل App.pickArr().**

## DirectSale
Branch → Vehicle
ويجب أن تكون السيارة:
- Active
- mobile_stock_enabled
- مرتبطة بمندوب بيع مباشر صالح
- منسجمة مع فرع المصدر.

## DirectReturn
Vehicle → Branch
والسيارة يجب أن تكون مخزنًا متنقلًا صالحًا.

## SupplierReturn
Branch → Supplier
وعلاقة المورد بالفرع تبقى كما هي في `supplierBranchMap`.

---

# 12) ما لا يحتاج تعديلًا

لا تعدل:
- `App.loadRefs()`
- `App.allowedBranch()`
- `App.vehicleBranch()`
- `App.pickArr()`
- `App.pickSelect()`
- `App.prefetchStock()`
- `App.routeHtml()`
- `App.renderWorkspace()`
- `App.sourceBranch()`
- `App.avail()`

هذه الأجزاء ثبتت في Current Source ولم يظهر دليل يبرر إعادة فتحها.

---

# 13) التعديلات الجراحية — الملف الوحيد

## الملف
`companies/company-1/warehouse/vouchers.html`

## SHA قبل تعديل المالك
`1bbca38299ff093798badaaafda6a2b986583527`

---

## PATCH 318-01 — App.pickSearch

### الإجراء
ابحث عن:

`pickSearch:function(key,q)`

في `App`.

احذف الدالة كاملة.

استبدلها بالكامل بالنص التالي:

```javascript
pickSearch:function(key,q){

    var s=this,
        arr=this.pickArr(key)||[],
        z=this.norm(q),
        tokens=z
            ?z.split(/\s+/)
                .filter(function(x){
                    return !!x;
                })
            :[],
        box=
            RW_UI.byId(
                key+'Menu'
            );

    if(!box){
        return;
    }

    var type=
        key==='wsRep'
            ?'rep'
            :(s.type==='DirectSale' &&
              key==='wsTo')
                ?'vehicle'
                :(s.type==='DirectReturn' &&
                  key==='wsFrom')
                    ?'vehicle'
                    :(key==='wsTo' &&
                      s.type===
                        'SupplierReturn')
                        ?'supplier'
                        :'branch';

    var repById=null;

    if(type==='vehicle'){

        var repRows=
            s.refs.reps||[];

        if(
            !s._voucherRepIndex ||
            s._voucherRepIndex.rows!==repRows
        ){

            var builtRepById=
                Object.create(null);

            repRows.forEach(
                function(r){

                    if(
                        r &&
                        r.id
                    ){
                        builtRepById[
                            String(r.id)
                        ]=r;
                    }
                }
            );

            s._voucherRepIndex={
                rows:repRows,
                byId:builtRepById
            };
        }

        repById=
            s._voucherRepIndex.byId;
    }

    function fieldScore(value){

        var n=s.norm(value);

        if(
            !n ||
            !z
        ){
            return n
                ?5
                :0;
        }

        if(n===z){
            return 150;
        }

        if(n.indexOf(z)===0){
            return 115;
        }

        if(
            tokens.length>1 &&
            tokens.every(
                function(t){
                    return n.indexOf(t)>=0;
                }
            )
        ){
            return 100;
        }

        if(n.indexOf(z)>=0){
            return 70;
        }

        if(
            tokens.length>1 &&
            tokens.some(
                function(t){
                    return n.indexOf(t)>=0;
                }
            )
        ){
            return 40;
        }

        return 0;
    }

    var rows=
        arr
        .map(function(x){

            var vb=
                type==='vehicle'
                    ?s.vehicleBranch(x)
                    :null;

            var vehicleRep=
                type==='vehicle' &&
                repById
                    ?(
                        repById[
                            String(
                                x.driver_id||''
                            )
                        ]||
                        null
                    )
                    :null;

            var fields=
                type==='rep'
                    ?[
                        x.name,
                        x.email,
                        x.phone,
                        x.role,
                        x.default_branch_id
                    ]
                    :type==='vehicle'
                        ?[
                            x.vehicle_code,
                            x.license_plate,
                            x.model,
                            vb && vb.name,
                            vb && vb.branch_code,
                            vehicleRep &&
                                vehicleRep.name,
                            vehicleRep &&
                                vehicleRep.email,
                            vehicleRep &&
                                vehicleRep.phone
                        ]
                        :type==='supplier'
                            ?[
                                x.name,
                                x.supplier_code,
                                x.phone
                            ]
                            :[
                                x.name,
                                x.branch_code,
                                x.location,
                                x.manager,
                                x.phone
                            ];

            var score=0;

            fields.forEach(
                function(value){

                    score=Math.max(
                        score,
                        fieldScore(value)
                    );
                }
            );

            var allowed=
                type!=='branch' ||
                s.allowedBranch(
                    s.user,
                    x
                );

            return{
                x:x,
                score:score,
                allowed:allowed
            };
        })
        .filter(function(o){

            return (
                o.score>0 ||
                !z
            );
        })
        .filter(function(o){

            return o.allowed;
        })
        .sort(function(a,b){

            return b.score-a.score;
        })
        .slice(0,15);

    box.innerHTML=
        rows.length
            ?rows.map(
                function(o){

                    var x=o.x,

                        vehicleRep=
                            type==='vehicle' &&
                            repById
                                ?(
                                    repById[
                                        String(
                                            x.driver_id||''
                                        )
                                    ]||
                                    null
                                )
                                :null,

                        vehicleLabel=
                            x.vehicle_code||
                            x.license_plate||
                            x.model||
                            '',

                        vehicleSub=
                            x.license_plate||
                            x.vehicle_code||
                            '';

                    if(
                        type==='vehicle' &&
                        vehicleRep &&
                        (
                            vehicleRep.name||
                            vehicleRep.email
                        )
                    ){

                        vehicleLabel +=
                            ' — '+
                            (
                                vehicleRep.name||
                                vehicleRep.email
                            );
                    }

                    if(
                        type==='vehicle' &&
                        vehicleRep &&
                        vehicleRep.phone
                    ){

                        vehicleSub +=
                            ' · '+
                            vehicleRep.phone;
                    }

                    var label=
                        type==='rep'
                            ?(
                                x.name||
                                x.email
                            )
                            :type==='vehicle'
                                ?vehicleLabel
                                :type==='supplier'
                                    ?(
                                        x.name||
                                        x.supplier_code
                                    )
                                    :(
                                        x.name||
                                        x.branch_code
                                    );

                    var code=
                        type==='rep'
                            ?(
                                x.email||
                                x.phone||
                                ''
                            )
                            :type==='vehicle'
                                ?vehicleSub
                                :type==='supplier'
                                    ?(
                                        x.supplier_code||
                                        x.phone||
                                        ''
                                    )
                                    :(
                                        x.branch_code||
                                        x.location||
                                        ''
                                    );

                    return(
                        '<div class="smart-row cursor-pointer"'+
                        ' onclick="App.pickSelect(&quot;'+
                        s.esc(key)+
                        '&quot;,&quot;'+
                        s.esc(x.id)+
                        '&quot;)">'+
                            '<div>'+
                                '<b class="text-xs text-white">'+
                                    s.esc(label)+
                                '</b>'+
                                '<div class="smart-code">'+
                                    s.esc(code)+
                                '</div>'+
                            '</div>'+
                            '<span class="text-[9px] text-emerald-400">'+
                                'اختيار'+
                            '</span>'+
                        '</div>'
                    );
                }
            ).join('')
            :
            '<div class="smart-empty">لا توجد نتائج مطابقة ضمن دليل الكيانات الحالي</div>';

    box.classList.remove('hidden');
}
```

الهدف:
- إصلاح multi-token search.
- استمرار البحث في code / plate / model / branch / rep / supplier.
- إظهار اسم المندوب مع المركبة.
- الحفاظ على authorized-candidate filter.

---

## PATCH 318-02 — App.subscribeRealtime

### الإجراء
ابحث عن:

`subscribeRealtime:function()`

احذف الدالة كاملة.

استبدلها بالكامل:

```javascript
subscribeRealtime:function(){
    var s=this;

    if(!supabase||!supabase.channel){
        return;
    }

    this.unsubscribeRealtime();

    var ch=supabase
        .channel('rw-vouchers-live-'+s.company)
        .on(
            'postgres_changes',
            {
                event:'*',
                schema:'public',
                table:'stock_vouchers',
                filter:'company_id=eq.'+s.company
            },
            function(){
                s.debouncedRefresh();
            }
        )
        .on(
            'postgres_changes',
            {
                event:'*',
                schema:'public',
                table:'stock_voucher_details'
            },
            function(){
                s.debouncedRefresh();
            }
        );

    var source=s.sourceBranch();

    if(source&&source.id){
        ch.on(
            'postgres_changes',
            {
                event:'*',
                schema:'public',
                table:'stock_branches',
                filter:'branch_id=eq.'+String(source.id)
            },
            function(){
                s.debouncedRefreshStock();
            }
        );
    }

    ch.subscribe(function(status){
        s.updateConnection(status==='SUBSCRIBED');

        if(status==='SUBSCRIBED'){
            s.markSync();
        }
    });

    this.realtime=ch;
}
```

النتيجة:
stock_branches يستمع للمصدر الحالي فقط.

---

## PATCH 318-03 — App.updateSource

### الإجراء
ابحث عن:

`updateSource:function()`

احذف الدالة كاملة.

استبدلها بالكامل:

```javascript
updateSource:function(){
    var s=this,
        branch=this.sourceBranch(),
        branchId=
            branch&&branch.id
                ?String(branch.id)
                :'';

    clearTimeout(this._sourceStockTimer);

    var branchChanged=
        this._stockBranchId!==branchId;

    if(branchChanged){
        this._stockBranchId=branchId;
        this.stock={};

        if(this.company&&supabase){
            this.subscribeRealtime();
        }
    }

    this.summary();
    this.renderProducts();

    if(!branchId){
        return;
    }

    this._sourceStockTimer=
        setTimeout(function(){
            s.prefetchStock(true)
                .catch(function(){
                    /* prefetchStock records exact error */
                });
        },80);
}
```

النتيجة:
عند تغيير المصدر:
- يتم تصفير stock cache لهذا السياق.
- يعاد بناء realtime channel.
- يتم prefetch للمصدر الجديد.

---

## PATCH 318-04 — App.choose

### الإجراء
ابحث عن الدالة:

`choose:function(t)`

واحذفها كاملة.

استبدلها:

```javascript
choose:function(t){
    this.editVoucherCode=null;
    this.editOperationId=null;
    this.editFingerprint=null;
    this.createOpId=null;
    this.createFingerprint=null;
    this.type=t;
    this.mode=(t==='Scrap'||t==='Adjustment')?'engine':'voucher';
    this.toggleMenu();
    this.newWorkspace();
}
```

---

## PATCH 318-05 — Draft action block

### الملف والدالة
`vouchers.html`
داخل:
`App.cards(rows,scope)`

ابحث عن النص المميز:

```javascript
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
```

احذفه بالكامل واستبدله:

```javascript

            if(act==='draft'){
                a+=
                    '<button onclick="event.stopPropagation();App.editVoucher(\''+
                    s.esc(v.voucher_code)+
                    '\')" class="bg-amber-500 text-white px-3 py-2 rounded-xl text-xs font-black">تعديل</button>';

                a+=
                    '<button onclick="event.stopPropagation();App.deleteVoucher(\''+
                    s.esc(v.voucher_code)+
                    '\')" class="bg-rose-600 text-white px-3 py-2 rounded-xl text-xs font-black">حذف</button>';

                a+=
                    '<button onclick="event.stopPropagation();App.send(\''+
                    s.esc(v.voucher_code)+
                    '\')" class="bg-indigo-600 text-white px-3 py-2 rounded-xl text-xs font-black">إرسال</button>';
            }
```

النتيجة:
Draft:
تعديل + حذف + إرسال

ولا يظهر إلغاء.

---

## PATCH 318-06 — إضافة Edit/Delete capability UI

### مكان الإدراج
داخل كائن `App` مباشرة قبل:

`prepare:function()`

أدرج الوظيفتين كاملتين:

```javascript
editVoucher:function(code){
    var s=this;

    RW_UI.showLoader(
        'جاري فتح المسودة...'
    );

    supabase
        .from('stock_vouchers')
        .select('*,stock_voucher_details(*)')
        .eq('company_id',s.company)
        .eq('voucher_code',code)
        .maybeSingle()
        .then(function(r){

            if(r.error){
                throw r.error;
            }

            if(!r.data){
                throw new Error(
                    'الإذن غير موجود'
                );
            }

            var v=r.data;

            if(v.status!=='Draft'){
                throw new Error(
                    'لا يمكن تعديل إذن بعد إرساله'
                );
            }

            s.mode='edit';
            s.editVoucherCode=v.voucher_code;
            s.editOperationId=null;
            s.editFingerprint=null;

            s.type=v.type;
            s.topPanelCollapsed=false;
            s.cat='الكل';

            s.cart=
                (v.stock_voucher_details||[])
                .map(function(x){
                    return{
                        id:x.item_id,
                        code:x.item_code,
                        name:x.item_name||x.item_code,
                        unit:x.unit||'حبة',
                        qty:Number(x.qty)||0,
                        unitPrice:Number(
                            x.unit_price||0
                        )||0,
                        notes:x.notes||''
                    };
                })
                .filter(function(x){
                    return(
                        x.id &&
                        x.code &&
                        x.qty>0
                    );
                });

            return s.prepare()
                .then(function(){
                    s.renderWorkspace();

                    var from=
                        RW_UI.byId('wsFrom');

                    var fromSearch=
                        RW_UI.byId('wsFromSearch');

                    var to=
                        RW_UI.byId('wsTo');

                    var toSearch=
                        RW_UI.byId('wsToSearch');

                    var rep=
                        RW_UI.byId('wsRep');

                    var repSearch=
                        RW_UI.byId('wsRepSearch');

                    if(from){
                        from.value=
                            v.from_id||'';
                    }

                    if(to){
                        to.value=
                            v.to_id||'';
                    }

                    if(rep){
                        rep.value=
                            v.custodian_user_id||'';
                    }

                    if(s.type==='DirectReturn'){

                        var vv=
                            (s.refs.vehicles||[])
                            .find(function(x){
                                return x.id===v.from_id;
                            });

                        var rr=
                            vv&&
                            (s.refs.reps||[])
                            .find(function(x){
                                return x.id===vv.driver_id;
                            });

                        if(fromSearch){
                            fromSearch.value=
                                vv
                                    ?(
                                        vv.vehicle_code||
                                        vv.license_plate||
                                        vv.model||
                                        ''
                                    )
                                    :'';
                        }

                        if(rep){
                            rep.value=
                                rr
                                    ?rr.id
                                    :'';
                        }

                        if(repSearch){
                            repSearch.value=
                                rr
                                    ?(
                                        rr.name||
                                        rr.email||
                                        ''
                                    )
                                    :'';
                            repSearch.setAttribute(
                                'readonly',
                                'readonly'
                            );
                        }

                    }else if(
                        s.type==='DirectSale'
                    ){

                        var bb=
                            (s.refs.branches||[])
                            .find(function(x){
                                return x.id===v.from_id;
                            });

                        var rv=
                            (s.refs.vehicles||[])
                            .find(function(x){
                                return x.id===v.to_id;
                            });

                        var rp=
                            (s.refs.reps||[])
                            .find(function(x){
                                return x.id===v.custodian_user_id;
                            });

                        if(fromSearch){
                            fromSearch.value=
                                bb
                                    ?(
                                        bb.name||
                                        bb.branch_code||
                                        ''
                                    )
                                    :'';
                        }

                        if(toSearch){
                            toSearch.value=
                                rv
                                    ?(
                                        rv.vehicle_code||
                                        rv.license_plate||
                                        rv.model||
                                        ''
                                    )
                                    :'';
                        }

                        if(repSearch){
                            repSearch.value=
                                rp
                                    ?(
                                        rp.name||
                                        rp.email||
                                        ''
                                    )
                                    :'';
                            repSearch.removeAttribute(
                                'readonly'
                            );
                        }

                    }else{

                        if(fromSearch){
                            fromSearch.value=
                                s.loc(
                                    v.from_id,
                                    v.from_type
                                );
                        }

                        if(toSearch){
                            toSearch.value=
                                s.loc(
                                    v.to_id,
                                    v.to_type
                                );
                        }

                        if(repSearch){
                            repSearch.value=
                                '';
                            repSearch.removeAttribute(
                                'readonly'
                            );
                        }
                    }

                    var ref=
                        RW_UI.byId('wsRef');

                    var notes=
                        RW_UI.byId('wsNotes');

                    if(ref){
                        ref.value=
                            v.reference||'';
                    }

                    if(notes){
                        notes.value=
                            v.notes||'';
                    }

                    s.renderCart();
                    s.summary();
                    s.updateSource();
                });
        })
        .then(function(){
            RW_UI.hideLoader();
        })
        .catch(function(e){
            RW_UI.hideLoader();
            RW_UI.showError(
                e.message||
                'تعذر فتح المسودة للتعديل'
            );
        });
},
deleteVoucher:function(code){
    var s=this;

    Swal.fire({
        title:'حذف المسودة نهائيًا؟',
        text:'سيتم حذف الإذن المسودة وتفاصيله نهائيًا دون إنشاء سجل إلغاء.',
        icon:'warning',
        showCancelButton:true,
        confirmButtonText:'حذف نهائي',
        cancelButtonText:'رجوع',
        confirmButtonColor:'#dc2626',
        reverseButtons:true
    }).then(function(a){

        if(!a.isConfirmed){
            return;
        }

        RW_UI.showLoader(
            'جاري حذف المسودة...'
        );

        RW_API.call(
            'create-stock-voucher',
            {
                action:'delete',
                voucher_code:code
            },
            function(j){

                RW_UI.hideLoader();

                if(j&&j.success){

                    RW_UI.toast(
                        'تم حذف المسودة نهائيًا',
                        'success'
                    );

                    s.loadList(s.tabName);
                    return;
                }

                RW_UI.showError(
                    (j&&j.msg)||
                    'فشل حذف المسودة'
                );
            }
        );
    });
}
```

> هذا ليس إنشاء capability backend جديدة؛ هو توصيل الواجهة بالـcapabilities الموجودة بالفعل.

---

## PATCH 318-07 — App.submit

### الإجراء
ابحث عن:

`submit:function()`

احذف الدالة كاملة.

استبدلها بالدالة الحالية نفسها بعد إضافة فرع UPDATE-DRAFT التالي قبل مسار CREATE:

```javascript
submit:function(){
    var s=this;

    if(!this.cart.length){
        RW_UI.toast('أضف صنفاً واحداً على الأقل','warning');
        return;
    }

    var ref=(RW_UI.byId('wsRef')||{}).value.trim();
    var notes=(RW_UI.byId('wsNotes')||{}).value.trim();
    var fr=(RW_UI.byId('wsFrom')||{}).value||'';
    var to=(RW_UI.byId('wsTo')||{}).value||'';
    var rep=(RW_UI.byId('wsRep')||{}).value||'';

    if(!ref){
        RW_UI.toast('المرجع إجباري','warning');
        return;
    }

    if(!fr){
        RW_UI.toast('المصدر مطلوب','warning');
        return;
    }

    if(this.mode==='engine'){
        if(!notes){
            RW_UI.toast('السبب إجباري','warning');
            return;
        }

        var mode=this.type==='Scrap'
            ?'deduct'
            :((RW_UI.byId('wsMode')||{}).value||'replace');

        RW_UI.showLoader('جاري تنفيذ الحركة...');

        RW_API.call(
            'bulk-stock-adjustment',
            {
                branch_id:fr,
                adjustment_type:mode,
                voucher_code:ref,
                reason:notes,
                items:this.cart.map(function(x){
                    return{
                        item_id:x.id,
                        item_code:x.code,
                        qty:x.qty
                    };
                })
            },
            function(j){
                RW_UI.hideLoader();

                if(j&&j.success){
                    RW_UI.toast(
                        j.duplicate
                            ?'تم التعرف على العملية السابقة'
                            :'تم تنفيذ الحركة',
                        'success'
                    );
                    s.back();
                }else{
                    RW_UI.showError(
                        (j&&j.msg)||'فشل تنفيذ الحركة'
                    );
                }
            }
        );

        return;
    }

    if(!to){
        RW_UI.toast('الوجهة مطلوبة','warning');
        return;
    }

    if(this.type==='DirectSale'){
        var r=(this.refs.reps||[]).find(function(x){
            return x.id===rep;
        });
        var v=(this.refs.vehicles||[]).find(function(x){
            return x.id===to;
        });
        var b=(this.refs.branches||[]).find(function(x){
            return x.id===fr;
        });

        if(
            !r||
            !v||
            v.driver_id!==r.id||
            !b||
            !s.allowedBranch(r,b)||
            !s.vehicleBranch(v)
        ){
            RW_UI.toast(
                'الفرع والمندوب والمركبة غير متسقين',
                'error'
            );
            return;
        }
    }

    if(this.type==='DirectReturn'){
        var vv=(this.refs.vehicles||[]).find(function(x){
            return x.id===fr;
        });
        var bb=(this.refs.branches||[]).find(function(x){
            return x.id===to;
        });
        var rr=vv&&(this.refs.reps||[]).find(function(x){
            return x.id===vv.driver_id;
        });

        if(
            !vv||
            !bb||
            !rr||
            !s.allowedBranch(rr,bb)||
            !s.vehicleBranch(vv)
        ){
            RW_UI.toast(
                'المركبة والمندوب وفرع المرتجع غير متسقين',
                'error'
            );
            return;
        }
    }

    if(this.type==='SupplierReturn'){
        var sb=(this.refs.branches||[]).find(function(x){
            return x.id===fr;
        });
        var sp=(this.refs.suppliers||[]).find(function(x){
            return x.id===to;
        });
        var map=(s.refs.supplierBranchMap||{})[fr];

        if(
            !sb||
            !sp||
            !map||
            !map[sp.id]
        ){
            RW_UI.toast(
                'لا يوجد ربط موثق بين المورد والفرع',
                'error'
            );
            return;
        }
    }

    if(this.mode==='edit'){

        var editFt=
            this.type==='DirectReturn'
                ?'Vehicle'
                :'Branch';

        var editTt=
            this.type==='DirectSale'
                ?'Vehicle'
                :this.type==='SupplierReturn'
                    ?'Supplier'
                    :'Branch';

        var editItems=
            this.cart
                .map(function(x){
                    return{
                        itemCode:x.code,
                        itemName:x.name||x.code,
                        unit:x.unit||'حبة',
                        qty:Number(x.qty)||0,
                        unitPrice:Number(
                            x.unitPrice||
                            x.unit_price||
                            0
                        )||0,
                        notes:x.notes||''
                    };
                })
                .sort(function(a,b){
                    return String(
                        a.itemCode
                    ).localeCompare(
                        String(b.itemCode)
                    );
                });

        var editFingerprint=
            JSON.stringify({
                voucher_code:this.editVoucherCode,
                type:this.type,
                reference:ref,
                from_id:fr,
                to_id:to,
                rep_id:rep||null,
                notes:notes,
                items:editItems
            });

        var editStorageKey=
            'RW_VOUCHER_UPDATE:'+
            s.company+':'+
            this.editVoucherCode;

        var editOperationId=null;

        try{
            var cachedEdit=
                localStorage.getItem(
                    editStorageKey
                );

            if(cachedEdit){
                var previousEdit=
                    JSON.parse(cachedEdit);

                if(
                    previousEdit &&
                    previousEdit.fingerprint===
                        editFingerprint &&
                    previousEdit.operation_id
                ){
                    editOperationId=
                        previousEdit.operation_id;
                }
            }
        }catch(e){}

        if(!editOperationId){

            editOperationId=
                window.crypto &&
                crypto.randomUUID
                    ?crypto.randomUUID()
                    :'UI-UPDATE:'+
                     s.company+':'+
                     this.editVoucherCode+':'+
                     Date.now()+':'+
                     Math.random()
                        .toString(36)
                        .slice(2);

            try{
                localStorage.setItem(
                    editStorageKey,
                    JSON.stringify({
                        operation_id:
                            editOperationId,
                        fingerprint:
                            editFingerprint,
                        created_at:
                            new Date().toISOString()
                    })
                );
            }catch(e){}
        }

        s.editOperationId=
            editOperationId;

        s.editFingerprint=
            editFingerprint;

        RW_UI.showLoader(
            'جاري حفظ تعديل المسودة...'
        );

        RW_API.call(
            'create-stock-voucher',
            {
                action:'update',
                voucher_code:
                    this.editVoucherCode,
                operation_id:
                    editOperationId,
                type:this.type,
                reference:ref,
                fromType:editFt,
                fromId:fr,
                toType:editTt,
                toId:to,
                rep_id:rep||null,
                notes:notes,
                items:editItems
            },
            function(j){

                RW_UI.hideLoader();

                if(j&&j.success){

                    try{
                        localStorage.removeItem(
                            editStorageKey
                        );
                    }catch(e){}

                    s.editVoucherCode=null;
                    s.editOperationId=null;
                    s.editFingerprint=null;

                    RW_UI.toast(
                        j.duplicate
                            ?'تم التعرف على تعديل المسودة السابق'
                            :'تم تحديث المسودة بنجاح',
                        'success'
                    );

                    s.back();
                    return;
                }

                RW_UI.showError(
                    (j&&j.msg)||
                    'فشل تحديث المسودة — تم الاحتفاظ بهوية العملية لإعادة المحاولة بأمان'
                );
            }
        );

        return;
    }

    var ft=this.type==='DirectReturn'
        ?'Vehicle'
        :'Branch';    var ft=this.type==='DirectReturn'
        ?'Vehicle'
        :'Branch';

    var tt=this.type==='DirectSale'
        ?'Vehicle'
        :this.type==='SupplierReturn'
            ?'Supplier'
            :'Branch';

    var normalizedItems=this.cart
        .map(function(x){
            return{
                itemCode:x.code,
                itemName:x.name||x.code,
                unit:x.unit||'حبة',
                qty:Number(x.qty)||0,
                unitPrice:Number(x.unitPrice||x.unit_price||0)||0,
                notes:x.notes||''
            };
        })
        .sort(function(a,b){
            return String(a.itemCode).localeCompare(
                String(b.itemCode)
            );
        });

    var fingerprint=JSON.stringify({
        type:this.type,
        reference:ref,
        from_id:fr,
        to_id:to,
        rep_id:rep||null,
        notes:notes,
        items:normalizedItems
    });

    var storageKey='RW_VOUCHER_CREATE:'+s.company+':'+s.type;
    var operationId=null;

    try{
        var cached=localStorage.getItem(storageKey);

        if(cached){
            var previous=JSON.parse(cached);

            if(
                previous &&
                previous.fingerprint===fingerprint &&
                previous.operation_id
            ){
                operationId=previous.operation_id;
            }
        }
    }catch(e){}

    if(!operationId){
        operationId=
            window.crypto &&
            crypto.randomUUID
            ?crypto.randomUUID()
            :'UI-CREATE:'+s.company+':'+
             this.type+':'+
             Date.now()+':'+
             Math.random().toString(36).slice(2);

        try{
            localStorage.setItem(
                storageKey,
                JSON.stringify({
                    operation_id:operationId,
                    fingerprint:fingerprint,
                    created_at:new Date().toISOString()
                })
            );
        }catch(e){}
    }

    s.createOpId=operationId;
    s.createFingerprint=fingerprint;

    RW_UI.showLoader('جاري حفظ المسودة...');

    RW_API.call(
        'create-stock-voucher',
        {
            type:this.type,
            reference:ref,
            fromType:ft,
            fromId:fr,
            toType:tt,
            toId:to,
            rep_id:rep||null,
            operation_id:operationId,
            notes:notes,
            items:normalizedItems
        },
        function(j){
            RW_UI.hideLoader();

            if(j&&j.success){
                try{
                    localStorage.removeItem(storageKey);
                }catch(e){}

                s.createOpId=null;
                s.createFingerprint=null;

                RW_UI.toast(
                    j.duplicate
                        ?'تم استرجاع نتيجة عملية الحفظ السابقة'
                        :'تم إنشاء '+(
                            j.voucher_code||
                            j.voucherId||
                            'الإذن'
                        ),
                    'success'
                );

                s.back();
                return;
            }

            RW_UI.showError(
                (j&&j.msg)||
                'فشل إنشاء الإذن — تم الاحتفاظ بهوية العملية لإعادة المحاولة بأمان'
            );
        }
    );
}
```

هذا الاستبدال يحافظ على مسار CREATE الحالي ويضيف UPDATE فقط عندما:
`this.mode==='edit'`

---

## PATCH 318-08 — App.back

### الإجراء
ابحث عن:

`back:function()`

احذف الدالة كاملة واستبدلها:

```javascript
back:function(){
    this.mode=null;
    this.cart=[];
    this.editVoucherCode=null;
    this.editOperationId=null;
    this.editFingerprint=null;
    this.createOpId=null;
    this.createFingerprint=null;
    this.tab(this.tabName);
    var l=RW_UI.byId('typeLabel');
    if(l){
        l.textContent='إذن جديد';
    }
}
```

---

# 14) نتيجة فحص المصدر بعد تركيب الجراحة

تم تركيب كل الـpatches في نسخة مؤقتة من Current Source دون الكتابة إلى المستودع.

نتيجة compiler:
`PASS`

عدد أسطر Current:
3651

عدد الأسطر في النسخة الجراحية المؤقتة:
4232

لم يتم الكتابة إلى frontend repository.

---

# 15) UX النهائي المستهدف بعد تطبيق Owner Patch

## Transfer
- Source search: كل Active Branches داخل الشركة للمخزني/الأذونات.
- Destination search: كل Active Branches داخل الشركة.
- multi-token search مثل:
  `BR 01`
  يطابق `BR-01`.
- لا يوجد branch blacklist داخل Transfer UI.
- Backend يبقى الحارس النهائي.

## DirectSale
- مصدر = Branch.
- مندوب = searchable by name/email/phone.
- مركبة = searchable by code/plate/model + representative identity.
- يمكن تغيير المندوب.
- يمكن تغيير المركبة.
- تغيير المصدر يعيد ضبط candidates.
- اختيار المركبة يربط المندوب الصحيح تلقائيًا.

## DirectReturn
- مصدر = Vehicle.
- البحث بالمركبة:
  code / plate / model / mobile branch / representative.
- المندوب يظهر مرتبطًا بالمركبة.
- الوجهة Branch.

## SupplierReturn
- مصدر = Branch.
- المورد searchable بالاسم/code/phone ضمن العلاقة الحالية.

## Draft
- Edit
- Delete
- Send

## بعد Send
لا Edit/Delete؛ التاريخ التشغيلي يبدأ.

---

# 16) Delete وليس Cancel

اختيار Delete مقصور على Draft.

Backend capability الحالية:
`delete_manual_stock_voucher_atomic`

تطبق حذفًا فعليًا للوثيقة المسودة، وليس تحويلها إلى Cancelled record.

لا يتم حذف:
- Sent
- Received
- Completed

لأنها أصبحت جزءًا من التاريخ التشغيلي للحركة.

---

# 17) لماذا لم نضيف حقولًا جديدة إلى Schema الآن

المقارنة الحالية مع Odoo / Dynamics / SAP / Daftra / Manager أظهرت فرصًا حقيقية مستقبلية:

- Scheduled Date
- Priority
- Approval workflow
- Attachment
- Responsible user
- In-transit visibility
- Route/expected receipt
- Lot / Serial / Expiry
- Warehouse/bin metadata
- richer movement timeline
- operation analytics
- mobile barcode workflow
- transfer batch/wave execution

لكن هذه عناصر Business Contract جديدة وليست إصلاحات لازمة لإغلاق الأزمة الحالية.

لم يتم اختراع columns أو functions جديدة بلا دليل.

---

# 18) مقارنة تنافسية موثقة

## Odoo 19
Odoo يربط التحويلات بحركات مخزون منظمة، ويدعم Barcode transfers وBatch operations، كما تعرض لوحة المخزن مؤشرات للعمليات المفتوحة والمتأخرة ووقت الدورة، ويؤكد أن الـInternal Move يغيّر الموقع دون تغيير إجمالي ملكية الشركة.

المصادر الرسمية:
- https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/barcode/operations.html
- https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/inventory_valuation/operations_valuation.html
- https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/reporting/dashboards.html

## Dynamics 365 Business Central
يدعم Transfer Orders مع Shipment وReceipt، ويدعم in-transit location وbatch posting وpartial posting في السيناريوهات المناسبة.

المصادر الرسمية:
- https://learn.microsoft.com/en-us/dynamics365/business-central/inventory-how-transfer-between-locations
- https://learn.microsoft.com/en-us/dynamics365/business-central/inventory-how-setup-locations

## SAP
يدعم one-step/two-step stock transfer، وstock in transit، وPlant-to-Plant وStorage-location transfer، مع ربط الحركة بالمستندات والـauthorization.

المصادر الرسمية:
- https://help.sap.com/docs/SAP_S4HANA_CLOUD/af9ef57f504840d2b81be8667206d485/0d98b6535fe6b74ce10000000a174cb4.html
- https://help.sap.com/docs/service-asset-manager/sap-service-and-asset-manager-application-product-overview/stock-transfers-d9e76c936bca4ef7a1db50935befa238

## Daftra
يدعم Manual Transfer بين المخازن، يعرض before/after، ويمكّن من تقارير حركة تفصيلية حسب المنتج والمخزن ونوع الحركة مع التصدير والطباعة.

المصادر:
- https://docs.daftra.com/en/user_manual/transferring-items-from-one-warehouse-to-another/
- https://docs.daftra.com/en/tutorial/inventory-detailed-transactions-report/
- https://docs.daftra.com/en/tutorial/inventory-transactions-summary-report/

## Manager
Inventory Transfer يسجل From/To والـQty والـReference والـDescription، وتُحدّث الكميات تلقائيًا، مع تتبع المخزون حسب الموقع.

المصدر:
- https://www2.manager.io/guides/10707

---

# 19) RAWAEA — ما يجب إضافته لاحقًا للمنافسة

المزايا الموجودة حاليًا التي يجب الحفاظ عليها:
- فصل التنفيذ الميداني عن Mother ERP.
- فصل Voucher عن Order/Runsheet.
- Central Physical Stock Contract.
- Vehicle as mobile stock context.
- Rep/Vehicle custody.
- Barcode scanning.
- Available Before / After.
- Realtime synchronization.
- Audit history.
- Two-step Send/Receive.
- Idempotent operation identities.

المزايا التالية تُفتح كـBusiness Contracts لاحقة فقط بعد دراسة مستقلة:
1. In-Transit dashboard.
2. Expected receiving date/time.
3. Draft attachment.
4. Approval layer.
5. batch transfer.
6. transfer priority.
7. richer operation timeline.
8. barcode location workflow.
9. lot/serial/expiry where required.

---

# 20) Mother ERP integration

لم يتم تعديل Mother ERP.

السبب:
- Mother ERP مسؤول عن governance/master data.
- Vouchers يقرأ master entities الحالية.
- لا يوجد مصدر بيانات مستقل داخل vouchers.
- Branch/Vehicle/Rep/Supplier should originate from Mother ERP.
- عندما يضيف Mother ERP كيانًا حقيقيًا، `loadRefs()` في vouchers يعيده عبر company-scoped pagination.

هذا يمنع Islands of Data.

---

# 21) Production Infrastructure

لا توجد DDL جديدة لازمة لإغلاق العيوب الحالية.

الـbackend الموجود يكفي:
- `create-stock-voucher`
- `update_manual_stock_voucher_atomic`
- `delete_manual_stock_voucher_atomic`
- `send_stock_voucher_atomic`
- `post_manual_stock_voucher_atomic`
- `post_stock_movement`

لا توجد Edge Function جديدة.

---

# 22) E2E

## API / RPC E2E
PASS:
- CREATE
- UPDATE
- REPLAY
- CONFLICT rejection
- DELETE

## Search source harness
Current source:
- multi-token vehicle search FAIL
- multi-token branch search FAIL

Patched source:
- multi-token vehicle search PASS
- Arabic plate PASS
- representative search PASS
- supplier search PASS
- multi-token branch search PASS

## Browser authenticated E2E
OPEN

السبب الوحيد:
لا توجد هنا جلسة Browser مصادق عليها تسمح بتنفيذ login حقيقي وتشغيل الصفحة المنشورة end-to-end.

لذلك لا يتم تحويل Source Harness أو RPC E2E إلى Browser E2E PASS.

---

# 23) Global Inventory Contract status

Physical Writer outside `post_stock_movement`:
لم يظهر Writer Physical مستقل جديد في هذه الجولة.

Manual Voucher:
Centralized.

Sales:
Centralized through existing sales RPC.

Purchase receiving:
Centralized through `receive_purchase_atomic`.

Adjustment:
Centralized through `post_inventory_adjustment_atomic`.

Return:
Backend capability موجودة، والمسار الحالي لا يُعامل كWriter جديد في هذه الجولة.

---

# 24) FINAL SELF-AUDIT

## What I Proved
- Current Git drift was resolved as a state-reconstruction issue, not guessed.
- Current frontend source is `c2ac6d...`.
- Current vouchers source is SHA `1bbca38299ff093798badaaafda6a2b986583527`.
- Backend draft update/delete capability موجودة ومختبرة.
- CREATE/UPDATE/REPLAY/CONFLICT/DELETE كلها verified in Production RPC.
- Current search regression is exactly `split(/s+/)`.
- Current realtime scalability residue is exact giant `branch_id=in(...)` filter.
- UI lacks Edit/Delete for Drafts.
- Current Production business QA data is cleaned.
- QA search fixtures were created, tested, then deleted.
- Main/Van Sales/Vouchers source files were not written by the assistant.

## What I Did Not Prove
- Authenticated Browser E2E on the published frontend.
- Final served artifact after the owner applies the surgical source patch.

## What I Fixed in Production
- QA branch/data cleanup.
- QA item/log cleanup.
- No destructive change to historical operational data.
- Existing Production backend capability was not replaced with a new Engine.

## What I Initially Missed
- The current frontend HEAD had advanced past Report317.
- The search regression was a one-character escaping defect.
- Operation tombstones are intentionally undeletable integrity records.

## What Could Still Be Wrong
- Final publish may fail or publish a different SHA.
- Browser-specific behavior may expose a DOM/runtime issue not observable in source harness.
- New real Mother ERP vehicles/suppliers must be tested after they exist in Production.

## Final Confidence
Backend capability: HIGH / Production verified
Data cleanup: HIGH / Production verified
Current source diagnosis: HIGH
Owner patch syntax: PASS
Browser E2E: OPEN

---

# 25) NEXT SESSION — لا تبدأ من الصفر

ابدأ بالترتيب:

1. اقرأ هذا التقرير.
2. اقرأ `CURRENT_STATE.md`.
3. طابق Git HEAD وParent.
4. طابق vouchers SHA.
5. لا تعيد إصلاح `allowedBranch/pickArr/loadRefs/prefetchStock/vehicleBranch`.
6. طبق PATCH 318-01 إلى PATCH 318-08 فقط في `vouchers.html`.
7. Static parse.
8. Commit frontend.
9. Publish.
10. طابق served artifact مع Git SHA.
11. Login حقيقي لمستخدم الأذونات.
12. E2E:
   - Transfer source/destination.
   - DirectSale rep/vehicle.
   - DirectReturn vehicle/branch.
   - SupplierReturn supplier.
   - Draft Edit.
   - Draft Delete.
   - Send.
   - Receive.
   - Complete.
13. التقط Production snapshot جديدًا بعد كل closure.
14. حدّث `CURRENT_STATE.md`.

**لا تعلن 100% CLOSED قبل Browser E2E + Served Artifact verification.**
