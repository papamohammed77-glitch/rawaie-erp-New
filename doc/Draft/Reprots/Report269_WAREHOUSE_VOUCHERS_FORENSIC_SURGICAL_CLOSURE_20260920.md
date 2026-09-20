# Report269 — التحقيق الجنائي والإغلاق الجراحي لتطبيق الأذونات المخزنية
## 2026-09-20

## 1) نطاق الجلسة

الملف الوحيد المطلوب تعديله بواسطة المالك:

`papamohammed77-glitch/erp-frontend/companies/company-1/warehouse/vouchers.html`

لم يتم تعديل `erp-frontend/companies/company-1/main.html`، ولم يتم تعديل `vouchers.html` مباشرة من هذا المنفذ.

أي تعديل Production لازم تم تطبيقه مباشرة في Supabase. لم يتم إنشاء Edge Function جديدة.

---

## 2) قاعدة الحقيقة التي حُسمت منها الجلسة

تمت إعادة التحقق من:

- System Git HEAD: `9fe3c816d962d456795ff3b971e5f22ea679ae9b`
- System parent: `d85e80ac1964500d25318efb29a1e2a6674f84f5`
- Mother current blob: `453565c39a50fdcf73eb03a97a1fc7d7ac10bb2f`
- Standalone vouchers blob: `545c96bb8e869ab0c38fe736df01605260f3bbae`
- Standalone build marker: `RAWAEA-VOUCHERS-CANONICAL-2026-08-28-R2`

الـMother الحالي يحتوي بالفعل على قائمة الأذونات ومسارات:
`transfer`, `direct-sale`, `direct-return`, `supplier-return`, `vouchers`.

الـMother نفسه يبقى مركز التحكم والرؤية، بينما `vouchers.html` هو Consumer مستقل للتنفيذ الميداني/التشغيلي.

---

## 3) الدور الوظيفي المثبت للتطبيق

العقد الحالي للتطبيق هو إدارة العمليات المخزنية المستقلة عن دورة Order/Runsheet:

```
Transfer
DirectSale
DirectReturn
SupplierReturn
```

بينما:

```
Picking
Loading
Delivery
Return
Unloading
```

تبقى عمليات fulfillment المرتبطة بدورة الأوردر/الرانشيت ولا ينبغي أن يعيد تطبيق الأذونات بناءها.

كما أن:

```
Scrap
Adjustment
```

موجودتان داخل مساحة العمل الحالية لكنهما تستخدمان `bulk-stock-adjustment` كـInventory Engine مستقل، وليستا `stock_vouchers`. لم يتم تغيير هذا السلوك لعدم وجود دليل يثبت أن Business Contract الحالي يريد تحويلهما إلى Voucher Documents.

---

## 4) النتيجة الجنائية لرحلة البيانات

المسار الصحيح الحالي:

```
Standalone vouchers.html
        ↓
Existing Edge capability
        ↓
create_manual_stock_voucher_atomic
        ↓
stock_vouchers + stock_voucher_details
        ↓
send / receive / complete / cancel RPCs
        ↓
post_stock_movement
        ↓
stock_branches
+
inventory_log
```

العقد المركزي للـPhysical Stock بقي دون تغيير:

```
PHYSICAL MOVEMENT
        ↓
post_stock_movement
        ↓
stock_branches + inventory_log
```

ولا يوجد Writer جديد.

---

## 5) الخطأ الحقيقي المكتشف

### ROOT CAUSE — Consumer Contract Drift

النسخة الحالية من `vouchers.html` عند الحفظ كانت تستدعي:

```
create-stock-voucher
```

وترسل:

```
type
reference
fromType
fromId
toType
toId
notes
items
```

لكنها لم ترسل:

```
rep_id
operation_id
```

في حين أن Production الحالية تحتوي بالفعل على الـcanonical 12-argument contract:

```
create_manual_stock_voucher_atomic(
  ...
  p_rep_id uuid,
  p_operation_id text
)
```

وEdge الحالي يدعم بالفعل:

```
body.rep_id / body.repId
body.operation_id / body.operationId
Idempotency-Key
```

إذن الخلل ليس نقصًا في Production Core، بل Consumer قديم لم يكتمل انتقاله إلى العقد الحالي.

### أثر الخلل

1. هوية العملية لا تنتقل صراحة من التطبيق إلى الـCore.
2. ربط مندوب البيع المباشر لا ينتقل صراحة إلى الـ12-arg contract.
3. لا يوجد correlation ثابت محلي يمكن إعادة استخدامه عند فقد استجابة CREATE بعد أن تكون العملية قد نفذت بنجاح.
4. لذلك كانت طبقة التكامل في التطبيق أقدم من طبقة Production canonical.

---

# 6) Production الإصلاح الذي طُبق

تم تحديث الـRPC المصادق القائم:

```
public.inventory_control(text,jsonb)
```

وإضافة capability:

```
VOUCHER_AUDIT
```

بدون إنشاء Edge Function جديدة.

الـCapability الجديدة تعيد:

```
voucher
details
audit
movements
```

وتستخدم Company context من:

```
auth.uid()
→ users.auth_id
→ users.company_id
```

ولا تفتح RLS على `audit_log`.

تم منح الوصول إلى:

```
authenticated
service_role
```

وتم الاحتفاظ بـPhysical Movement خارج هذه capability.

الـProduction migration canonical:

`supabase/migrations/20260920_inventory_control_voucher_audit_capability.sql`

Commit:

`d6d14f3deff6b8ea7cf03c650c6bb471eceed9b4`

---

# 7) لماذا لم نفتح audit_log مباشرة؟

Production الحالية تملك:

```
audit_log_select_owner
```

مع قراءة Owner مباشرة، بينما مستخدم تطبيق الأذونات يعتمد على سياق صلاحية الأذونات.

فتح RLS مباشرة كان سيكسر مبدأ فصل Capability عن Data Table.

لذلك الحل الصحيح:

```
Authorized Consumer
        ↓
inventory_control('VOUCHER_AUDIT')
        ↓
SECURITY DEFINER
        ↓
Company scoped voucher/audit/movement evidence
```

وهذا يغلق الفجوة دون توسيع صلاحية الجدول نفسه.

---

# 8) Production Verification

## 8.1 Full voucher lifecycle E2E

تم تشغيل Transactional E2E على Production باستخدام بيانات حقيقية موجودة بالفعل:

- الشركة: `00000000-0000-0000-0000-000000000001`
- المصدر: BR-01
- الوجهة: BR-2
- الصنف: 1001
- الكمية: 1
- المستخدم: owner@alrawae.com

المسار:

```
CREATE
→ SEND
→ RECEIVE
→ COMPLETE
```

النتيجة:

```
CREATE  = PASS
SEND    = PASS
RECEIVE = PASS
COMPLETE= PASS
```

التحقق الرقمي:

```
source: 2 → 1
target: 1 → 2
inventory_log rows = 2
operation rows = 1
```

ثم تم Rollback كامل.

بعد Rollback:

```
stock_vouchers = 0
stock_voucher_operations = 0
source qty = 2
target test row = absent
test inventory_log rows = 0
```

إذن Production لم تتلوث ببيانات الاختبار.

## 8.2 Audit capability

تم التحقق أن `VOUCHER_AUDIT`:

- يرفض Voucher غير الموجود.
- يطبق المصادقة.
- يعتمد على Company context الحالي.
- لا يحتاج Edge Function جديدة.

كما تم التحقق مباشرة أن Audit Trigger الحالي على `stock_vouchers` ينشئ سجلًا عند INSERT.

---

# 9) المنافسون — الفجوة الحقيقية التي يجب أن يعالجها Consumer

الدراسة الحالية لا تعني نسخ Odoo/Dynamics/SAP/Daftra/Manager.io.

### Odoo

Odoo يفرّق بين:
- stock moves
- receipts
- deliveries
- customer returns
- vendor returns
- scrap
- inventory adjustments

ويعرض أثر الحركات والتقييم المخزني ضمن نفس المنظومة. كما يوفر Barcode workflows للتحويل والجرد.  
المصادر الرسمية:
- https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/inventory_valuation/operations_valuation.html
- https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/inventory_management/scrap_inventory.html
- https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/inventory_management/count_products.html
- https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/barcode/operations.html

### Dynamics 365

Dynamics يميز Inventory Journals مثل:
- Movement
- Inventory adjustment
- Transfer
- Item arrival
- Counting
- Tag counting

ويفصل الإنشاء والتحقق والنشر ومراجعة معاملات المخزون.

المصدر:
- https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/inventory-journals

### SAP

SAP Goods Movement يدعم:
- goods receipt
- goods issue
- stock transfer
- transfer posting

مع مستند حركة، وإمكانية التشغيل بدون مرجع مستند سابق أو مع مرجع، مع Idempotency في واجهات الخدمة.

المصادر:
- https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/1dad2180e6f34b75ac77afce5cb5eda1/6306cbb9a31611dc2b8d000f20fcb6a9.html
- https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/91b21005dded4984bcccf4a69ae1300c/742e46e570984d9aa74e468838f6e1ff.html

### Daftra / دفترة

Daftra/دفترة يظهر:
- تاريخ الحركة
- من/إلى
- الملاحظات
- المنتج
- السعر
- الكمية
- الرصيد قبل/بعد
- البحث في الأذونات
- الصلاحيات
- الاستيراد السريع

المصادر:
- https://docs.daftra.com/en/user_manual/transferring-items-from-one-warehouse-to-another/
- https://docs.daftra.com/en/tutorial/creating-a-manual-transfer-requisition/
- https://www.daftra.com/%D8%A3%D8%B0%D9%88%D9%86-%D9%85%D8%AE%D8%B2%D9%86%D9%8A%D8%A9/
- https://www.daftra.com/en/features/sub_feature/3

### Manager.io

Manager يفصل بين:
- Delivery Notes
- Inventory Transfers
- Inventory Write-offs

ويستخدم المستندات لتتبع الكمية أو تسوية الفقد/التالف.

المصادر:
- https://www2.manager.io/guides/36343
- https://www2.manager.io/guides/10709

---

# 10) لماذا لم نضف الرصيد Before/After التاريخي إلى تفاصيل الإذن الآن؟

لأن Production الحالية لا تقدم داخل Consumer-safe contract قيمة تاريخية before/after موثوقة لكل حركة.

إعادة حسابها من `inventory_log` داخل الواجهة ستكون افتراضًا خطرًا، خصوصًا مع:
- الحركات السابقة قبل إنشاء الحركة الحالية
- ترتيب الأحداث
- حركات متعددة لنفس الصنف
- تغييرات الإنتاج التاريخية

لذلك تم تنفيذ ما يثبت حاليًا:
- Current available stock في مساحة العمل
- Actual movement evidence بعد التنفيذ
- Audit evidence
- Voucher state
- item quantities and received quantities

وترك Before/After التاريخي كـBusiness Contract مستقل لا يُبنى بالتخمين.

---

# 11) التعديل الجراحي المطلوب من المالك

## الملف المطلوب تعديله

```
papamohammed77-glitch/erp-frontend
/companies/company-1/warehouse/vouchers.html
```

### لا تلمس:
```
companies/company-1/main.html
```

### ولا تلمس أي جزء آخر من vouchers.html غير العناصر المحددة أدناه.

---

# 12) SURGICAL PATCH #1 — newWorkspace

## ابحث عن العنصر المحدد:

```js
newWorkspace:function(){
```

واحذف الدالة كاملة، ثم استبدلها بالكامل:

```js
newWorkspace:function(){
    var s=this;
    this.cart=[];
    this.cat='الكل';
    this.createOpId=null;
    this.createFingerprint=null;
    try{
        if(s.company&&s.type){
            sessionStorage.removeItem('RW_VOUCHER_CREATE:'+s.company+':'+s.type);
        }
    }catch(e){}
    RW_UI.showLoader('جاري تجهيز مساحة العمل...');
    Promise.resolve()
        .then(function(){return s.prepare()})
        .then(function(){
            s.renderWorkspace();
            RW_UI.hideLoader();
        })
        .catch(function(e){
            RW_UI.hideLoader();
            RW_UI.showError(e.message||'تعذر تجهيز الكتالوج');
        });
},
```

الهدف الوحيد:
- بدء كل وثيقة جديدة بهوية عملية جديدة.
- عدم حمل عملية قديمة إلى نموذج جديد.

---

# 13) SURGICAL PATCH #2 — submit

## ابحث عن:

```js
submit:function(){
```

واحذف الدالة الحالية كاملة، ثم استبدلها بالكامل:

```js
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

    var ft=this.type==='DirectReturn'
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
        var cached=sessionStorage.getItem(storageKey);

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
            sessionStorage.setItem(
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
                    sessionStorage.removeItem(storageKey);
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
},
```

### ما تم الحفاظ عليه

لم يتم تغيير:
- validations الخاصة بالفرع.
- validations الخاصة بالمندوب.
- validations الخاصة بالمركبة.
- supplier/branch relation.
- Scrap/Adjustment engine.
- stock availability.
- barcode workflow.
- cart behavior.

التغيير فقط:
- Operation Identity.
- rep_id.
- item metadata.
- safe retry.

---

# 14) SURGICAL PATCH #3 — renderList

## ابحث عن:

```js
renderList:function(scope){
```

واحذف الدالة كاملة واستبدلها:

```js
renderList:function(scope){
    var s=this;

    var typeOptions=[
        '<option value="">كل الأنواع</option>',
        '<option value="Transfer">تحويل مخزني</option>',
        '<option value="DirectSale">صرف سيارة بيع مباشر</option>',
        '<option value="DirectReturn">استلام مرتجع سيارة</option>',
        '<option value="SupplierReturn">مرتجع لمورد</option>'
    ].join('');

    var h=
        '<div class="h-full overflow-y-auto p-4 overscroll-contain">'+
        '<div class="max-w-[1150px] mx-auto">'+

        '<div class="flex justify-between items-center mb-4">'+
        '<div>'+
        '<b class="text-lg">'+
        (scope==='pending'
            ?'📄 الأذونات المعلقة'
            :'✅ الأذونات المكتملة')+
        '</b>'+
        '<p class="text-xs text-slate-400 mt-1">'+
        '<span id="listCount">'+this.vouchers.length+'</span>'+
        ' سجل · <span id="syncAt">آخر مزامنة: —</span>'+
        '</p>'+
        '</div>'+
        '<button onclick="App.toggleMenu()" class="gold-chip px-4 py-2.5 rounded-2xl font-black text-sm">'+
        '+ نوع جديد</button>'+
        '</div>'+

        '<div class="card mb-4">'+
        '<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-2">'+
        '<input id="listSearch" oninput="App.filterList()" placeholder="🔍 رقم الإذن أو المرجع أو النوع" class="w-full p-3 bg-white rounded-2xl border-2 border-slate-100 outline-none font-semibold text-sm">'+
        '<select id="listType" onchange="App.filterList()" class="w-full p-3 bg-white rounded-2xl border-2 border-slate-100 outline-none font-semibold text-sm">'+
        typeOptions+
        '</select>'+
        '<input id="listFrom" type="date" onchange="App.filterList()" class="w-full p-3 bg-white rounded-2xl border-2 border-slate-100 outline-none font-semibold text-sm">'+
        '<input id="listTo" type="date" onchange="App.filterList()" class="w-full p-3 bg-white rounded-2xl border-2 border-slate-100 outline-none font-semibold text-sm">'+
        '<button type="button" onclick="App.loadList(App.tabName)" class="w-full p-3 bg-slate-800 text-white rounded-2xl font-black text-sm">'+
        '↻ تحديث من Production'+
        '</button>'+
        '</div>'+
        '</div>'+

        '<div id="listCards">'+
        this.cards(this.vouchers,scope)+
        '</div>'+

        '</div></div>';

    RW_UI.safeHTML(RW_UI.byId('mainContent'),h);
    this.markSync();
},
```

---

# 15) SURGICAL PATCH #4 — filterList

## ابحث عن:

```js
filterList:function(){
```

واحذف الدالة كاملة واستبدلها:

```js
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

    var rows=this.vouchers.filter(function(v){

        var textMatch=
            !q||
            s.norm(v.voucher_code).includes(q)||
            s.norm(v.reference).includes(q)||
            s.norm(v.type).includes(q);

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
            textMatch &&
            typeMatch &&
            fromMatch &&
            toMatch
        );
    });

    var count=RW_UI.byId('listCount');

    if(count){
        count.textContent=rows.length;
    }

    RW_UI.safeHTML(
        RW_UI.byId('listCards'),
        this.cards(rows,this.tabName)
    );
},
```

هذه الجراحة تعطي التطبيق مستوى البحث/التصفية الذي تثبته شاشات الأذونات الحديثة في الأنظمة المنافسة، بدون تغيير الـData Model.

---

# 16) SURGICAL PATCH #5 — details

## ابحث عن:

```js
details:function(code){
```

واحذف الدالة الحالية كاملة واستبدلها:

```js
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
```

---

# 17) SURGICAL PATCH #6 — callAction

## ابحث عن:

```js
callAction:function(name,code,successText){
```

واحذف الدالة الحالية كاملة واستبدلها:

```js
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

            RW_UI.hideLoader();

            delete s.busy[busyKey];

            if(j&&j.success){

                RW_UI.toast(
                    j.duplicate
                        ?'تم التعرف على العملية السابقة'
                        :successText,
                    'success'
                );

                s.markSync();

                s.loadList(s.tabName);

                s.prefetchStock(true);

            }else{

                RW_UI.showError(
                    (j&&j.msg)||
                    'فشل التنفيذ'
                );
            }
        }
    );
},
```

الفرق الجراحي الوحيد هنا:
عدم إسقاط المستخدم قسرًا إلى `pending` بعد تنفيذ الإجراء.

---

# 18) وظائف لم تُلمس عمدًا

لم يتم تعديل:

- `loadList`
- `receive`
- `prepare`
- `handleScan`
- `renderProducts`
- `pickArr`
- `pickSelect`
- `routeHtml`
- `allowedBranch`
- `vehicleBranch`
- `Scrap / Adjustment`
- Realtime subscription

لأن التحقيق لم يثبت وجود خلل يستوجب إعادة بنائها.

---

# 19) Contract Matrix

| المسؤولية | Current | Target after surgery | النتيجة |
|---|---|---|---|
| Voucher creation | Edge → RPC | Edge → 12-arg canonical RPC | مكتمل |
| Operation identity | غير صريح من Consumer | operation_id ثابت لكل retry | مكتمل |
| DirectSale rep identity | validation فقط | validation + rep_id | مكتمل |
| Physical movement | post_stock_movement | post_stock_movement | محفوظ |
| Inventory log | Core | Core | محفوظ |
| Audit UI | direct audit_log SELECT | inventory_control(VOUCHER_AUDIT) | مكتمل |
| Tenant context | company on app + RLS | auth.uid → users.company_id → RPC | مكتمل |
| Search | text only | text + type + date range | مكتمل بالجراحة |
| Current stock | prefetchStock | prefetchStock | محفوظ |
| Barcode | current | current | محفوظ |
| Receive idempotency | localStorage + operation_id | current unchanged | محفوظ |
| Scrap/Adjustment | separate engine | separate engine | لم يتغير |
| Mother control | existing RW_Warehouse | unchanged | محفوظ |

---

# 20) Production status

### Production Infrastructure
- `inventory_control` modified and deployed.
- `VOUCHER_AUDIT` capability added.
- No new Edge Function.
- No RLS relaxation.
- No new Physical Writer.
- Existing physical stock contract preserved.

### Production data
- `stock_vouchers = 0`
- `stock_voucher_operations = 0`
- Test residue = 0.

---

# 21) Browser E2E Status

```
BACKEND PRODUCTION E2E = PASS
BROWSER E2E             = OPEN
```

الـBrowser gate لا يمكن تحويله إلى PASS من خلال SQL فقط.

بعد أن يطبق المالك الاستبدالات الستة في `vouchers.html`، يجب أن يكون اختبار المتصفح التالي:

```
Login
→ Open permissions app
→ CREATE Transfer
→ CREATE same request twice after simulated response loss
→ expect one Voucher
→ SEND
→ RECEIVE partial
→ RECEIVE same operation retry
→ expect duplicate/no extra movement
→ RECEIVE remainder
→ COMPLETE
→ open details
→ verify movements
→ verify audit
→ verify list filters
→ verify realtime refresh
```

ولا يجوز تسجيل Browser PASS قبل تحقق فعلي من ذلك.

---

# 22) Open Contracts — لا تُعاد بناؤها

1. Before/After historical movement state داخل Consumer-safe Voucher details.
2. Bulk import/paste from spreadsheet داخل Voucher form.
3. Approval layer للـManual Vouchers قبل SEND.
4. Attachments / documents.
5. Lot/serial/expiry context.
6. Formal in-transit state beyond current two-step Transfer implementation.
7. Full document print/export contract.

هذه نقاط Business Contract مستقلة ولا تُعتبر Bugs في الجراحة الحالية.

---

# 23) التعليمات للمساعد التالي

## ابدأ هكذا

1. اقرأ هذا التقرير بالكامل.
2. اقرأ `CURRENT_STATE.md`.
3. أعد التحقق من:
   - System HEAD + parent
   - Mother HEAD + parent
   - `vouchers.html` SHA
   - Production `inventory_control`
4. لا تثق بهذا التقرير كحالة حالية؛ استخدمه كبوصلة فقط.
5. افتح `vouchers.html` الحالي مباشرة.
6. تحقق أن الاستبدالات الستة ما زالت مطابقة.
7. نفذ Browser E2E قبل أي تغيير جديد.
8. إذا نجح Browser E2E، أغلق Voucher Consumer Closure.
9. بعدها فقط افتح Business Contract التالي من قائمة Open Contracts.
10. لا تعيد بناء:
   - Inventory Core
   - post_stock_movement
   - receive idempotency
   - Mother navigation
   - field Operations
   - Scrap/Adjustment engine

## قاعدة منع الانحراف

لا تُصلح شيئًا لأنه يبدو غريبًا.

اسأل دائمًا:

```
CURRENT SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT
+
HISTORICAL CONTRACT
```

ثم:

```
ACTUAL GAP
→ SURGICAL FIX
→ TEST
→ PRODUCTION VERIFY
→ CLOSE
```

---

# 24) FINAL SELF-AUDIT

### What I Proved
- Current Mother routing contains the voucher module.
- Current standalone vouchers file is a separate Consumer.
- Production has canonical 12-arg manual voucher creation.
- Production Edge create capability already supports rep_id and operation_id.
- Full CREATE→SEND→RECEIVE→COMPLETE Production E2E passed and rolled back.
- Physical movement remained centralized.
- `VOUCHER_AUDIT` capability deployed.
- No new Edge Function was required.
- No permanent test residue exists.

### What I Did Not Prove
- Browser E2E of the patched standalone file.
- User-interface rendering after owner applies patches.
- Historical before/after quantities inside voucher details.

### What I Fixed
- Production authenticated voucher audit capability.
- Consumer contract drift identified and surgical replacement prepared.
- Operation identity propagation.
- rep_id propagation.
- list filtering parity.
- unified movement/audit detail retrieval.
- current-tab preservation after actions.

### What Could Still Be Wrong
- A future commit could replace these current functions.
- Browser integration could reveal an unrelated UI binding issue.
- Business approval/attachments/serial/lot contracts remain open.

### Final Closure Status

```
PRODUCTION CORE FOR VOUCHERS       = VERIFIED
PHYSICAL STOCK CENTRALIZATION      = PRESERVED
CONSUMER SURGERY                    = READY FOR OWNER
BROWSER E2E                         = OPEN
GLOBAL VOUCHER CLOSURE              = NOT CLOSED UNTIL BROWSER E2E
```

## END REPORT
