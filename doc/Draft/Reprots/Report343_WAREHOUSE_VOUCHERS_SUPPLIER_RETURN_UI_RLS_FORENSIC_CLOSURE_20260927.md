# Report343 — Warehouse Vouchers / SupplierReturn UI + RLS Forensic Closure
## تاريخ التنفيذ: 2026-09-27

---

# 1. نطاق الإغلاق

الوحدة المحسومة في هذه الجلسة فقط:

`companies/company-1/warehouse/vouchers.html`

والتكامل المرتبط بها مع:

- Production / Supabase
- Supplier Master
- Return Contract
- Purchase Order الاختياري
- Purchase Invoice الاختيارية
- Supplier Ledger
- General Ledger
- Tax Transactions
- Inventory / inventory_log
- النظام الأم Mother `main.html`
- التطبيق التنفيذي `van-sales.html`

## الملفات المحمية في هذه الجلسة

- `companies/company-1/main.html` — لم يُلمس.
- `companies/company-1/warehouse/vouchers.html` — لم يُعدَّل بواسطة المساعد.
- `companies/company-1/sales/van-sales.html` — لم يُعدَّل.
- لم تُنشأ Edge Function جديدة.

---

# 2. هرم الحقيقة الذي تم اعتماده

تمت إعادة بناء الحالة من:

1. CURRENT GIT
2. CURRENT SOURCE
3. CURRENT PRODUCTION
4. CURRENT DATABASE
5. CURRENT DEPLOYMENT EVIDENCE

والتقارير السابقة استُخدمت فقط كأدلة تاريخية.

## Current Governance

`MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS`

SHA:

`b03feec14a417ca9032d714774f2687b4542a373`

أهم عقد التحقيق:

- RAWAEA ERP منظومة واحدة وليست جزرًا منفصلة.
- أي إصلاح يجب أن يتتبع upstream/downstream/database/RPC/auth/state/audit/reporting/other PWAs.
- لا يوجد Half Fix.
- التعديل الجراحي يجب أن يقدم Complete Replacement Element.
- Production الذي يمكن تنفيذه مباشرة يجب تنفيذه، بينما ملفات Mother تبقى Owner-controlled.

---

# 3. آخر Git قبل Closure

## System repository

آخر نقطة موثقة قبل هذا الإغلاق:

- Current System HEAD: `97c6848eb477a2fd5d00162c3e3a0d08aac96d9e`
- Parent: موثق ضمن سلسلة SupplierReturn الحالية.
- أحدث تقرير: Report342.

## Mother repository

آخر مصدر مثبت:

- Mother HEAD: `4a322fa793027f8584d9f0d55638ef5a14aebc03`
- Parent: `fce3dfaa0503957791113a5ebf57d402a4a82764`
- `main.html` SHA: `810e4f5440f5975f55099a124deb42b086a49183`
- `vouchers.html` SHA: `6aca57d8baa8c78b616a281411f15438f34676bf`
- `van-sales.html` SHA: `8d61382a8e0025a0d079e71dd94f33d106d9088e`

هذا الـSHA هو baseline الذي يجب أن يُستخدم عند تطبيق Owner Patch.

---

# 4. النتيجة التاريخية التي لا يجوز إعادة فتحها

Mother commit `4a322...` يحتوي بالفعل على SR-01 / SR-02 / SR-03.

## ما تم إصلاحه سابقًا

### SR-01

`pickArr()` لم يعد يقيّد SupplierReturn على `supplierBranchMap` المبني من تاريخ PO.

### SR-02

`submit()` لم يعد يرفض SupplierReturn لأن المورد لم يسبق أن ظهر في PO للفرع.

### SR-03

تمت إعادة تسمية المسار إلى:

`المورد`

بدل:

`المورد المرتبط بالفرع`

## حكم التحقيق

لا تعاد هذه التعديلات.

ولا يعاد كتابة:

- `pickSearch()`
- Supplier picker engine
- `supplierBranchMap` نفسه

إلا إذا ظهرت أدلة متناقضة مستقبلًا.

---

# 5. تعريف دور SupplierReturn

المسار الصحيح في RAWAEA:

`Branch → Supplier`

وهو:

- حركة مخزنية مستقلة.
- ليست Order.
- ليست Runsheet.
- ليست Delivery.
- ليست Van Sales.
- ليست مشروطة بـ PO.
- ليست مشروطة بفاتورة شراء.

مسارا الشراء في النظام:

## المسار A — PO

`Purchase Order`
→ `Receiving`
→ `Stock`
→ `Inventory Log`
→ `Supplier Ledger`
→ `Accounting`

## المسار B — Direct Purchase

شراء مباشر من المورد/مندوب الشراء:

`Purchase Invoice / Direct Purchase`
→ `Stock`
→ `Inventory Log`
→ `Supplier Ledger`
→ `Accounting`

## SupplierReturn

`Warehouse Vouchers`
→ `SupplierReturn Contract`
→ `Send`
→ `Central Stock Movement`
→ `Supplier Ledger`
→ `GL`
→ `Tax`
→ `Audit`

هذا الاستقلال هو جزء من تصميم RAWAEA وليس خطأ يجب إزالته.

---

# 6. العيب الأول — Contract UI غير موجود في المصدر الحالي

## العنصر المعيب الأول

الملف:

`companies/company-1/warehouse/vouchers.html`

SHA:

`6aca57d8baa8c78b616a281411f15438f34676bf`

## الموضع

الدالة:

`routeHtml()`

السطر التقريبي الحالي:

**3492**

## العنصر المحدد للحذف الكامل

ابحث بالنص الحرفي:

~~~javascript
if(t==='SupplierReturn')return'<div class="grid grid-cols-1 sm:grid-cols-2 gap-2">'+p('wsFrom','الفرع المصدر')+p('wsTo','المورد')+'</div>';
~~~

احذف هذا السطر بالكامل.

## البديل الكامل

استبدله بالكامل بهذا:

~~~javascript
if(t==='SupplierReturn')
return(
    '<div class="grid grid-cols-1 sm:grid-cols-2 gap-2">'+
        p('wsFrom','الفرع المصدر')+
        p('wsTo','المورد')+
        '<div class="sm:col-span-2 mt-1">'+
            '<button type="button"'+
            ' onclick="App.openSupplierReturnContract()"'+
            ' class="w-full px-4 py-3 rounded-2xl bg-emerald-600 text-white text-xs font-black shadow-lg">'+
                '<i class="fa-solid fa-file-circle-check ml-2"></i>'+
                'عقد وتقييم مرتجع المورد'+
            '</button>'+
        '</div>'+
        '<div id="srContractState" class="sm:col-span-2 text-[10px] text-slate-500">'+
            'سيتم استكمال السبب والمرجع والفحص والتقييم قبل الإرسال.'+
        '</div>'+
    '</div>'
);
~~~

---

# 7. العيب الثاني — refs ناقصة

## العنصر المعيب

داخل كائن:

`App.refs`

الموضع:

**السطر 27 تقريبًا**

ابحث عن:

~~~javascript
refs:{
    branches:[],
    vehicles:[],
    suppliers:[],
    reps:[],
    supplierBranchMap:{},
~~~

احذفه واستبدله بالكامل بـ:

~~~javascript
refs:{
    branches:[],
    vehicles:[],
    suppliers:[],
    reps:[],
    returnReasons:[],
    taxCodes:[],
    supplierBranchMap:{},
    directSalesAssignments:[],
    repVehicleMap:Object.create(null),
    vehicleRepMap:Object.create(null)
},
~~~

## تعديل حالة الجلسة

نفس كائن App يحتوي حاليًا تقريبًا على:

~~~javascript
realtime:null,lastSyncAt:null,scanLastCode:'',scanLastAt:0,
~~~

استبدل هذا العنصر فقط بـ:

~~~javascript
realtime:null,lastSyncAt:null,scanLastCode:'',scanLastAt:0,supplierReturnDraft:null,
~~~

الهدف: منع تسرب عقد مرتجع سابق إلى Workspace جديد.

---

# 8. العيب الثالث — loadRefs لا يحمل Return Reasons ولا Tax Codes

## الموضع

الدالة:

`loadRefs()`

الـanchor الحالي:

**حوالي السطر 132**

العنصر الحالي:

~~~javascript
        readAll(function(){
            return supabase
                .from('purchase_orders')
                .select('supplier_id,branch_id')
                .eq('company_id',s.company)
                .not('supplier_id','is',null)
                .order('created_at')
                .order('id');
        })
~~~

## احذفه بالكامل واستبدله بـ:

~~~javascript
        readAll(function(){
            return supabase
                .from('purchase_orders')
                .select('supplier_id,branch_id')
                .eq('company_id',s.company)
                .not('supplier_id','is',null)
                .order('created_at')
                .order('id');
        }),

        readAll(function(){
            return supabase
                .from('return_reasons')
                .select(
                    'id,company_id,reason_code,reason_name,reason_category,is_active'
                )
                .eq('company_id',s.company)
                .eq('is_active',true)
                .order(
                    'reason_code',
                    {ascending:true}
                );
        }),

        readAll(function(){
            return supabase
                .from('finance_tax_codes')
                .select(
                    'id,code,name,rate,purchase_account_id,is_active'
                )
                .eq('company_id',s.company)
                .eq('is_active',true)
                .order(
                    'code',
                    {ascending:true}
                );
        })
~~~

ثم ابحث عن العنصر:

~~~javascript
        s.refs.reps=r[3]||[];
        s.refs.supplierBranchMap={};
~~~

احذفه واستبدله بالكامل بـ:

~~~javascript
        s.refs.reps=r[3]||[];
        s.refs.returnReasons=r[5]||[];
        s.refs.taxCodes=r[6]||[];
        s.refs.supplierBranchMap={};
~~~

---

# 9. العيب الرابع — Contract helper غير موجود

## مكان الإدراج

بعد:

`routeHtml:function(){...}`

وقبل:

`renderWorkspace:function(){...`

أضف العناصر التالية كاملة.

## SR-07A — Fingerprint

~~~javascript
supplierReturnFingerprint:function(){
    return JSON.stringify(
        (this.cart||[])
            .map(function(x){
                return[
                    x.code,
                    Number(x.qty)||0
                ];
            })
            .sort(function(a,b){
                return String(a[0])
                    .localeCompare(String(b[0]));
            })
    );
},
~~~

## SR-07B — حفظ العقد

~~~javascript
saveSupplierReturnContract:function(code,callback){

    var s=this,
        d=s.supplierReturnDraft;

    function fail(message,error){

        var e=
            error instanceof Error
                ?error
                :new Error(
                    message||
                    'فشل حفظ عقد مرتجع المورد'
                );

        RW_UI.showError(
            e.message||
            'فشل حفظ عقد مرتجع المورد'
        );

        if(callback){
            callback(
                e,
                null
            );
        }
    }

    if(
        !d||
        !d.supplier_id||
        String(d.supplier_id)!==
        String(
            (RW_UI.byId('wsTo')||{}).value||''
        )
    ){
        fail(
            'بيانات عقد مرتجع المورد غير مكتملة.'
        );
        return;
    }

    var currentFingerprint=
        s.supplierReturnFingerprint();

    if(
        !d.items_fingerprint||
        String(d.items_fingerprint)!==
        String(currentFingerprint)
    ){
        fail(
            'تم تغيير أصناف المرتجع بعد حفظ العقد. أعد فتح عقد المرتجع لمراجعة التقييم.'
        );
        return;
    }

    var payload=
        JSON.parse(JSON.stringify(d));

    payload.items_fingerprint=
        currentFingerprint;

    var fp=
        JSON.stringify(payload);

    var key=
        'RW_SUPPLIER_RETURN_CONTRACT:'+
        s.company+':'+code;

    var op=null;

    try{
        var old=localStorage.getItem(key);

        if(old){
            var rec=JSON.parse(old);

            if(
                rec &&
                rec.fingerprint===fp &&
                rec.operation_id
            ){
                op=rec.operation_id;
            }
        }
    }catch(e){}

    if(!op){

        op=
            window.crypto &&
            crypto.randomUUID
                ?crypto.randomUUID()
                :'UI-SR-CONTRACT:'+
                 s.company+':'+
                 code+':'+
                 Date.now()+':'+
                 Math.random()
                    .toString(36)
                    .slice(2);

        try{
            localStorage.setItem(
                key,
                JSON.stringify({
                    operation_id:op,
                    fingerprint:fp,
                    created_at:
                        new Date().toISOString()
                })
            );
        }catch(e){}
    }

    RW_UI.showLoader(
        'جاري حفظ عقد مرتجع المورد...'
    );

    supabase
        .rpc(
            'save_supplier_return_contract',
            {
                p_company_id:s.company,
                p_voucher_code:code,
                p_contract:payload,
                p_operation_id:op
            }
        )
        .then(function(r){

            RW_UI.hideLoader();

            if(
                r.error ||
                !r.data ||
                r.data.success!==true
            ){
                fail(
                    (
                        r.error &&
                        r.error.message
                    )||
                    'فشل حفظ عقد مرتجع المورد',
                    r.error
                        ?new Error(r.error.message)
                        :null
                );
                return;
            }

            try{
                localStorage.removeItem(key);
            }catch(e){}

            if(callback){
                callback(
                    null,
                    r.data
                );
            }

        })
        .catch(function(e){

            RW_UI.hideLoader();

            fail(
                e.message||
                'فشل حفظ عقد مرتجع المورد',
                e
            );

        });
},
~~~

## SR-07C — Contract Modal

~~~javascript
openSupplierReturnContract:function(done){

    var s=this;

    if(s.type!=='SupplierReturn'){
        if(done)done();
        return;
    }

    var supplierId=
        (RW_UI.byId('wsTo')||{})
            .value||'';

    var supplier=
        (s.refs.suppliers||[])
        .find(function(x){
            return String(x.id)===
                String(supplierId);
        });

    if(!supplier){
        RW_UI.toast(
            'اختر المورد أولًا.',
            'warning'
        );
        return;
    }

    RW_UI.showLoader(
        'جاري تحميل مرجعيات المرتجع...'
    );

    var existingPromise=
        (
            s.mode==='edit' &&
            s.editVoucherCode
        )
        ?supabase
            .rpc(
                'get_supplier_return_contract',
                {
                    p_company_id:s.company,
                    p_voucher_code:
                        s.editVoucherCode
                }
            )
            .then(function(r){

                if(
                    r.error ||
                    !r.data ||
                    !r.data.success
                ){
                    return null;
                }

                var h=
                    r.data.voucher||{};

                return{
                    supplier_id:supplierId,
                    return_reason_id:
                        h.return_reason_id||'',
                    supplier_credit_note_ref:
                        h.supplier_credit_note_ref||'',
                    supplier_rma_ref:
                        h.supplier_rma_ref||'',
                    purchase_invoice_id:
                        h.purchase_invoice_id||'',
                    purchase_order_id:
                        h.purchase_order_id||'',
                    return_to_address:
                        h.return_to_address||
                        supplier.address||
                        '',
                    inspection_status:
                        h.inspection_status||
                        'not_required',
                    disposition:
                        h.disposition||
                        'return_to_supplier',
                    currency:
                        h.return_currency||
                        'SAR',
                    items_fingerprint:
                        s.supplierReturnFingerprint(),
                    lines:
                        r.data.lines||[]
                };

            })
            .catch(function(){
                return null;
            })
        :Promise.resolve(null);

    Promise.all([
        existingPromise,

        supabase
            .from('purchase_orders')
            .select(
                'id,po_code,po_date,total_amount,status'
            )
            .eq('company_id',s.company)
            .eq('supplier_id',supplierId)
            .neq('status','Cancelled')
            .order(
                'created_at',
                {ascending:false}
            )
            .limit(100),

        supabase
            .from('purchase_invoices')
            .select(
                'id,invoice_code,invoice_date,total_amount,status,purchase_order_id'
            )
            .eq('company_id',s.company)
            .eq('supplier_id',supplierId)
            .neq('status','Cancelled')
            .order(
                'created_at',
                {ascending:false}
            )
            .limit(100)
    ])
    .then(function(parts){

        var existing=parts[0]||null;

        var pos=
            (
                parts[1] &&
                parts[1].data
            )||
            [];

        var invoices=
            (
                parts[2] &&
                parts[2].data
            )||
            [];

        var sessionDraft=
            s.supplierReturnDraft &&
            String(
                s.supplierReturnDraft.supplier_id||''
            )===String(supplierId) &&
            String(
                s.supplierReturnDraft.items_fingerprint||''
            )===String(
                s.supplierReturnFingerprint()
            )
                ?s.supplierReturnDraft
                :null;

        var draft=
            existing||
            sessionDraft||
            {
                supplier_id:supplierId,
                return_reason_id:'',
                supplier_credit_note_ref:'',
                supplier_rma_ref:'',
                purchase_invoice_id:'',
                purchase_order_id:'',
                return_to_address:
                    supplier.address||
                    '',
                inspection_status:
                    'not_required',
                disposition:
                    'return_to_supplier',
                currency:'SAR',
                items_fingerprint:
                    s.supplierReturnFingerprint(),
                lines:[]
            };

        var html=
            '<div class="text-right space-y-4">'+

            '<div class="grid grid-cols-1 sm:grid-cols-2 gap-3">'+

                '<div>'+
                    '<label class="text-[10px] text-slate-400 block mb-1">سبب المرتجع *</label>'+
                    '<select id="srReason" class="smart-input w-full">'+
                        '<option value="">اختر السبب</option>'+
                        (s.refs.returnReasons||[])
                        .map(function(x){
                            return(
                                '<option value="'+
                                s.esc(x.id)+
                                '" '+
                                (
                                    String(x.id)===
                                    String(
                                        draft.return_reason_id||
                                        ''
                                    )
                                    ?'selected'
                                    :''
                                )+
                                '>'+
                                s.esc(
                                    x.reason_code+
                                    ' — '+
                                    x.reason_name
                                )+
                                '</option>'
                            );
                        })
                        .join('')+
                    '</select>'+
                '</div>'+

                '<div>'+
                    '<label class="text-[10px] text-slate-400 block mb-1">عنوان إرجاع المورد *</label>'+
                    '<input id="srReturnAddress" class="smart-input w-full" value="'+
                        s.esc(
                            draft.return_to_address||
                            supplier.address||
                            ''
                        )+
                    '" placeholder="عنوان استلام المرتجع لدى المورد">'+
                '</div>'+

                '<div>'+
                    '<label class="text-[10px] text-slate-400 block mb-1">Credit Note / Supplier Credit Note</label>'+
                    '<input id="srCreditNote" class="smart-input w-full" value="'+
                        s.esc(
                            draft.supplier_credit_note_ref||
                            ''
                        )+
                    '" placeholder="رقم إشعار المورد إن وجد">'+
                '</div>'+

                '<div>'+
                    '<label class="text-[10px] text-slate-400 block mb-1">RMA</label>'+
                    '<input id="srRma" class="smart-input w-full" value="'+
                        s.esc(
                            draft.supplier_rma_ref||
                            ''
                        )+
                    '" placeholder="رقم RMA إن وجد">'+
                '</div>'+

                '<div>'+
                    '<label class="text-[10px] text-slate-400 block mb-1">Purchase Order — اختياري</label>'+
                    '<select id="srPO" class="smart-input w-full">'+
                        '<option value="">بدون مرجع PO</option>'+
                        pos.map(function(x){
                            return(
                                '<option value="'+
                                s.esc(x.id)+
                                '" '+
                                (
                                    String(x.id)===
                                    String(
                                        draft.purchase_order_id||
                                        ''
                                    )
                                    ?'selected'
                                    :''
                                )+
                                '>'+
                                s.esc(
                                    x.po_code+
                                    ' · '+
                                    x.po_date
                                )+
                                '</option>'
                            );
                        }).join('')+
                    '</select>'+
                '</div>'+

                '<div>'+
                    '<label class="text-[10px] text-slate-400 block mb-1">Purchase Invoice — اختياري</label>'+
                    '<select id="srInvoice" class="smart-input w-full">'+
                        '<option value="">بدون مرجع فاتورة</option>'+
                        invoices.map(function(x){
                            return(
                                '<option value="'+
                                s.esc(x.id)+
                                '" '+
                                (
                                    String(x.id)===
                                    String(
                                        draft.purchase_invoice_id||
                                        ''
                                    )
                                    ?'selected'
                                    :''
                                )+
                                '>'+
                                s.esc(
                                    x.invoice_code+
                                    ' · '+
                                    x.invoice_date
                                )+
                                '</option>'
                            );
                        }).join('')+
                    '</select>'+
                '</div>'+

                '<div>'+
                    '<label class="text-[10px] text-slate-400 block mb-1">الفحص</label>'+
                    '<select id="srInspection" class="smart-input w-full">'+
                        '<option value="not_required">لا يتطلب فحص</option>'+
                        '<option value="pending">قيد الفحص</option>'+
                        '<option value="passed">اجتاز الفحص</option>'+
                        '<option value="failed">فشل الفحص</option>'+
                    '</select>'+
                '</div>'+

                '<div>'+
                    '<label class="text-[10px] text-slate-400 block mb-1">Disposition</label>'+
                    '<select id="srDisposition" class="smart-input w-full">'+
                        '<option value="return_to_supplier">إعادة للمورد</option>'+
                        '<option value="replacement_requested">استبدال مطلوب</option>'+
                        '<option value="credit_requested">ائتمان/خصم مستحق</option>'+
                        '<option value="rejected">مرفوض</option>'+
                    '</select>'+
                '</div>'+

            '</div>'+

            '<div class="border border-slate-800 rounded-2xl overflow-hidden">'+
                '<div class="px-3 py-2 bg-slate-900 text-[10px] font-black text-slate-300">'+
                    'تقييم بنود المرتجع — السعر والخصم والضريبة لكل صنف'+
                '</div>'+

                (s.cart||[]).map(function(x,i){

                    var old=
                        (draft.lines||[])
                        .find(function(z){
                            return String(z.item_code)===
                                String(x.code);
                        })||
                        {};

                    var price=
                        Number(
                            old.unit_price||
                            x.unitPrice||
                            0
                        )||
                        Number(
                            (
                                s.items.find(function(it){
                                    return String(it.item_code)===
                                        String(x.code);
                                })||
                                {}
                            ).cost_price||
                            0
                        )||
                        0;

                    return(
                        '<div class="p-3 border-b border-slate-800">'+
                        '<b class="text-xs text-white truncate block">'+
                            s.esc(x.name||x.code)+
                        '</b>'+
                        '<span class="text-[10px] text-slate-500">'+
                            s.esc(x.code)+
                            ' · Qty '+
                            f(x.qty)+
                        '</span>'+
                        '<div class="grid grid-cols-1 sm:grid-cols-3 gap-2 mt-2">'+

                            '<div>'+
                                '<label class="text-[9px] text-slate-500 block mb-1">سعر الوحدة</label>'+
                                '<input id="srPrice'+i+'" type="number" min="0" step="0.01" class="smart-input w-full" value="'+
                                    s.esc(price)+
                                '">'+
                            '</div>'+

                            '<div>'+
                                '<label class="text-[9px] text-slate-500 block mb-1">خصم %</label>'+
                                '<input id="srDisc'+i+'" type="number" min="0" max="100" step="0.01" class="smart-input w-full" value="'+
                                    s.esc(
                                        Number(
                                            old.discount_percent||0
                                        )
                                    )+
                                '">'+
                            '</div>'+

                            '<div>'+
                                '<label class="text-[9px] text-slate-500 block mb-1">Tax</label>'+
                                '<select id="srTax'+i+'" class="smart-input w-full">'+
                                    '<option value="">بدون ضريبة</option>'+
                                    (s.refs.taxCodes||[])
                                    .map(function(tc){
                                        return(
                                            '<option value="'+
                                            s.esc(tc.id)+
                                            '" '+
                                            (
                                                String(tc.id)===
                                                String(
                                                    old.tax_code_id||
                                                    ''
                                                )
                                                ?'selected'
                                                :''
                                            )+
                                            '>'+
                                            s.esc(
                                                tc.code+
                                                ' · '+
                                                tc.rate+
                                                '%'
                                            )+
                                            '</option>'
                                        );
                                    })
                                    .join('')+
                                '</select>'+
                            '</div>'+

                        '</div>'+
                        '</div>'
                    );
                }).join('')+

            '</div>'+
            '</div>';

        RW_UI.hideLoader();

        Swal.fire({
            title:'عقد مرتجع المورد',
            html:html,
            width:900,
            showCancelButton:true,
            confirmButtonText:'حفظ العقد',
            cancelButtonText:'إلغاء',
            reverseButtons:true,
            focusConfirm:false,
            didOpen:function(){

                var inspection=
                    RW_UI.byId('srInspection');

                var disposition=
                    RW_UI.byId('srDisposition');

                if(inspection)
                    inspection.value=
                        draft.inspection_status||
                        'not_required';

                if(disposition)
                    disposition.value=
                        draft.disposition||
                        'return_to_supplier';

            },
            preConfirm:function(){

                var reason=
                    (
                        RW_UI.byId(
                            'srReason'
                        )||
                        {}
                    ).value||
                    '';

                var address=
                    (
                        RW_UI.byId(
                            'srReturnAddress'
                        )||
                        {}
                    ).value.trim();

                if(!reason){
                    Swal.showValidationMessage(
                        'اختر سبب المرتجع.'
                    );
                    return false;
                }

                if(!address){
                    Swal.showValidationMessage(
                        'عنوان إرجاع المورد مطلوب.'
                    );
                    return false;
                }

                var lines=
                    (s.cart||[])
                    .map(function(x,i){

                        var price=
                            Number(
                                (
                                    RW_UI.byId(
                                        'srPrice'+i
                                    )||
                                    {}
                                ).value
                            )||0;

                        var disc=
                            Number(
                                (
                                    RW_UI.byId(
                                        'srDisc'+i
                                    )||
                                    {}
                                ).value
                            )||0;

                        var tax=
                            (
                                RW_UI.byId(
                                    'srTax'+i
                                )||
                                {}
                            ).value||
                            '';

                        if(price<=0){
                            Swal.showValidationMessage(
                                'سعر الصنف '+
                                x.code+
                                ' يجب أن يكون أكبر من صفر.'
                            );
                            throw new Error(
                                'invalid price'
                            );
                        }

                        if(disc<0 || disc>100){
                            Swal.showValidationMessage(
                                'خصم الصنف '+
                                x.code+
                                ' غير صالح.'
                            );
                            throw new Error(
                                'invalid discount'
                            );
                        }

                        return{
                            item_code:x.code,
                            unit_price:price,
                            discount_percent:disc,
                            tax_code_id:tax
                        };

                    });

                return{
                    supplier_id:supplierId,
                    return_reason_id:reason,
                    supplier_credit_note_ref:
                        (
                            RW_UI.byId(
                                'srCreditNote'
                            )||
                            {}
                        ).value.trim(),
                    supplier_rma_ref:
                        (
                            RW_UI.byId(
                                'srRma'
                            )||
                            {}
                        ).value.trim(),
                    purchase_invoice_id:
                        (
                            RW_UI.byId(
                                'srInvoice'
                            )||
                            {}
                        ).value||
                        null,
                    purchase_order_id:
                        (
                            RW_UI.byId(
                                'srPO'
                            )||
                            {}
                        ).value||
                        null,
                    return_to_address:address,
                    inspection_status:
                        (
                            RW_UI.byId(
                                'srInspection'
                            )||
                            {}
                        ).value||
                        'not_required',
                    disposition:
                        (
                            RW_UI.byId(
                                'srDisposition'
                            )||
                            {}
                        ).value||
                        'return_to_supplier',
                    currency:'SAR',
                    items_fingerprint:
                        s.supplierReturnFingerprint(),
                    lines:lines
                };
            }
        })
        .then(function(a){

            if(
                !a ||
                !a.isConfirmed
            ){
                return;
            }

            s.supplierReturnDraft=
                a.value;

            if(
                RW_UI.byId(
                    'srContractState'
                )
            ){
                RW_UI.safeText(
                    RW_UI.byId(
                        'srContractState'
                    ),
                    'تم حفظ بيانات عقد المرتجع في الجلسة.'
                );
            }

            if(done){
                done();
            }

        });

    })
    .catch(function(e){

        RW_UI.hideLoader();

        RW_UI.showError(
            e.message||
            'تعذر تحميل مرجعيات المرتجع'
        );

    });
},
~~~

---

# 10. العيب الخامس — SR-08 submit preflight غير موجود

## العنصر المعيب

داخل:

`submit()`

بعد بلوك SupplierReturn الحالي الذي يبدأ بـ:

~~~javascript
if(this.type==='SupplierReturn'){
    var sb=(this.refs.branches||[]).find(function(x){
~~~

والموضع الحالي:

**حوالي السطر 4070**

ضع هذا البلوك كاملًا بعد انتهاء التحقق الحالي للمورد:

~~~javascript
if(this.type==='SupplierReturn'){

    var currentSupplierId=
        (RW_UI.byId('wsTo')||{})
            .value||'';

    var currentFingerprint=
        this.supplierReturnFingerprint();

    if(
        !this.supplierReturnDraft||
        String(
            this.supplierReturnDraft.supplier_id||''
        )!==
        String(currentSupplierId)||
        String(
            this.supplierReturnDraft.items_fingerprint||''
        )!==
        String(currentFingerprint)
    ){

        this.openSupplierReturnContract(
            function(){
                App.submit();
            }
        );

        return;
    }
}
~~~

---

# 11. العيب السادس — Create callback يخرج قبل حفظ Contract

## الموضع

داخل:

`submit()`

مسار CREATE.

موضع `if(j&&j.success)` الحالي:

**حوالي السطر 4365**

## العنصر الحالي

ابحث عن:

~~~javascript
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
~~~

احذفه بالكامل.

## البديل الكامل المصحح

~~~javascript
            if(j&&j.success){

                try{
                    localStorage.removeItem(storageKey);
                }catch(e){}

                var createdCode=
                    j.voucher_code||
                    j.voucherId||
                    '';

                if(
                    s.type==='SupplierReturn' &&
                    createdCode
                ){

                    s.createOpId=null;
                    s.createFingerprint=null;

                    s.saveSupplierReturnContract(
                        createdCode,
                        function(err){

                            if(err){
                                s.mode='edit';
                                s.editVoucherCode=
                                    createdCode;
                                s.editOperationId=null;
                                s.editFingerprint=null;
                                return;
                            }

                            s.supplierReturnDraft=null;

                            RW_UI.toast(
                                'تم إنشاء وحفظ مرتجع المورد بنجاح',
                                'success'
                            );

                            s.back();

                        }
                    );

                    return;
                }

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
~~~

---

# 12. العيب السابع — Edit callback يمسح voucher code قبل حفظ Contract

## السبب

هذا خطأ حقيقي في صيغة Report342 السابقة.

العنصر السابق كان يمسح:

~~~javascript
s.editVoucherCode=null;
~~~

ثم يحاول اختبار:

~~~javascript
s.editVoucherCode
~~~

وبذلك يصبح شرط SupplierReturn غير صالح بعد التصفير.

## الموضع الحالي

داخل مسار UPDATE.

`if(j&&j.success)` في:

**حوالي السطر 4232**

## احذف العنصر الكامل التالي:

~~~javascript
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
~~~

## البديل الكامل

~~~javascript
                if(j&&j.success){

                    try{
                        localStorage.removeItem(
                            editStorageKey
                        );
                    }catch(e){}

                    if(
                        s.type==='SupplierReturn' &&
                        s.editVoucherCode
                    ){

                        var editedCode=
                            s.editVoucherCode;

                        s.saveSupplierReturnContract(
                            editedCode,
                            function(err){

                                if(err){
                                    s.mode='edit';
                                    return;
                                }

                                s.supplierReturnDraft=null;

                                RW_UI.toast(
                                    'تم تحديث عقد مرتجع المورد بنجاح',
                                    'success'
                                );

                                s.editVoucherCode=null;
                                s.editOperationId=null;
                                s.editFingerprint=null;

                                s.back();

                            }
                        );

                        return;
                    }

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
~~~

---

# 13. العيب الثامن — stale Contract State

تم اكتشافه أثناء forensic reconstruction وليس ضمن SR-01..SR-03.

## الموضع الأول

داخل:

`newWorkspace()`

**حوالي السطر 2384**

العنصر:

~~~javascript
    this.createOpId=null;
    this.createFingerprint=null;
~~~

استبدله بـ:

~~~javascript
    this.createOpId=null;
    this.createFingerprint=null;
    this.supplierReturnDraft=null;
~~~

## الموضع الثاني

داخل:

`editVoucher(code)`

**حوالي السطر 2075**

العنصر:

~~~javascript
            s.editOperationId=null;
            s.editFingerprint=null;

            s.type=v.type;
~~~

استبدله بـ:

~~~javascript
            s.editOperationId=null;
            s.editFingerprint=null;
            s.supplierReturnDraft=null;

            s.type=v.type;
~~~

## الموضع الثالث

داخل:

`back()`

**حوالي السطر 4396**

العنصر:

~~~javascript
    this.createOpId=null;
    this.createFingerprint=null;
~~~

استبدله بـ:

~~~javascript
    this.createOpId=null;
    this.createFingerprint=null;
    this.supplierReturnDraft=null;
~~~

---

# 14. ما لا يجب تعديله

لا تحذف أو تعيد كتابة:

- `pickSearch()`
- `pickShow()`
- `pickArr()`
- SR-01
- SR-02
- SR-03
- `post_stock_movement`
- `create_manual_stock_voucher_atomic`
- `send_stock_voucher_atomic`
- `complete_manual_stock_voucher_atomic_core_20260828`
- `main.html`
- `van-sales.html`

---

# 15. التحقيق الجنائي في Search / Supplier Dropdown

## ما كان يبدو ظاهريًا

- حقل المورد يظهر.
- `pickSearch()` يعمل.
- القائمة قد تكون فارغة.

## ما ثبت فعليًا

### مستخدم الاختبار

`vouchers@rawaea.com`

خصائصه:

- role = `مخزني`
- active_warehouse_role = `أذونات`
- permissions = `["warehouse"]`
- active = true
- company = company-1
- allowed_branch_ids = `"BR-01"`

والـhelper:

`app_private.current_user_has_permission('suppliers')`

أعاد:

`false`

## Policy الأصلية

كانت:

~~~sql
company_id = app_private.current_user_company_id()
AND app_private.current_user_has_permission('suppliers')
~~~

لذلك كان الموردون غير مرئيين للمستخدم رغم صحة `pickSearch()`.

محاكاة Session authenticated لهذا المستخدم أعادت:

- current company = company-1
- warehouse permission = true
- supplier permission = false
- supplier rows visible = **0**

هذا يثبت أن العيب في **RLS / Data Access** وليس في محرك Smart Search.

---

# 16. Production إصلاح Smart Supplier Directory

تم تطبيق Migration مباشرة في Production:

`harden_supplier_return_voucher_directory_and_rpc_acl_20260927`

وأُسجل مصدرها في:

`supabase/migrations/20260927165000_harden_supplier_return_voucher_directory_and_rpc_acl_20260927.sql`

## التغيير

Supplier Select أصبح يسمح بقراءة الموردين داخل نفس الشركة فقط إذا كان المستخدم:

- لديه صلاحية `suppliers`

أو:

- مستخدمًا نشطًا بدور Warehouse Role = `أذونات`

مع بقاء صلاحيات INSERT / UPDATE / DELETE للموردين دون توسيع.

## النتيجة بعد الإصلاح

مع نفس Session:

- supplier permission = false
- suppliers visible = **4**

هذا إثبات مباشر أن مشكلة القائمة المنسدلة أغلقت من طبقة Production دون منح المستخدم صلاحية إدارة الموردين.

---

# 17. Production Security Hardening

تم أيضًا إصلاح ACL الزائدة على Contract RPC.

## قبل

`assert_supplier_return_contract(uuid,uuid)`

كان لديه:

- PUBLIC EXECUTE = true
- ANON EXECUTE = true
- AUTHENTICATED EXECUTE = true

رغم أنه Guard داخلي.

## بعد

أصبح:

- PUBLIC = false
- ANON = false
- AUTHENTICATED = false

مع بقاء:

- `save_supplier_return_contract` للمستخدم authenticated فقط.
- `get_supplier_return_contract` للمستخدم authenticated فقط.

وهذا يطابق مبدأ:

`Browser → Authenticated RPC → Contract`

ولا يفتح Contract Guard كـpublic capability.

---

# 18. Production Return Reasons RLS

Policy القديمة كانت تسمح بقراءة Return Reasons لأي authenticated user دون company boundary واضح.

تم تضييقها إلى:

- الشركة الحالية
- أو reason عالمي `company_id IS NULL`

والـrole أصبح authenticated.

الهدف:

`No Cross-Tenant Reference Leakage`

---

# 19. لا توجد حاجة إلى Edge Function جديدة

تم التحقق من أن:

`create-stock-voucher`

الحالية هي بالفعل capability wrapper للمسار:

`Browser → Existing Edge → Canonical RPC`

وتدعم:

- create
- update draft
- delete draft

ولا يوجد سبب هندسي لإنشاء Edge Function جديدة.

تم الالتزام بحد المشروع في عدد الـFunctions / Spend Cap.

---

# 20. SupplierReturn Production Contract

Production كان قد أُغلق سابقًا في Report342، وتم التحقق من وجوده فعليًا.

العناصر الموجودة:

- Return Reason
- Supplier Credit Note Ref
- Supplier RMA Ref
- Optional PO
- Optional Purchase Invoice
- Return-to Address
- Inspection
- Disposition
- Unit Price
- Discount
- Tax
- Return totals
- Supplier Ledger
- GL
- Tax Transaction
- Purchase Document Links
- Idempotency

لا يوجد أي مبرر لإنشاء جدول أو Edge Function جديد في هذه الجلسة.

---

# 21. QA Data — دائم ولا يُحذف

تم إنشاء بيانات QA دائمة في Production.

## Supplier

`QA-SR-CLOSURE-20260927`

ID:

`8a4ec462-d9ef-43e3-943d-9c1369b2561e`

## Item

`QA-SR-ITEM-20260927`

ID:

`8a84e363-4c27-4b52-959f-311138df9972`

Cost:

`75.00`

## Voucher

`QA-SR-UI-CONTRACT-20260927-01`

ID:

`6c2cea2c-548b-48b3-aeb9-def4a80776e1`

Status:

`Completed`

---

# 22. QA Contract

تم حفظ Contract فعليًا باستخدام RPC authenticated.

القيم:

- Return Reason = SR001
- Supplier Credit Note = QA-UI-CN-20260927-01
- Supplier RMA = QA-UI-RMA-20260927-01
- PO = NULL
- Purchase Invoice = NULL
- Return-to Address = عنوان اختبار مرتجع المورد — 27 سبتمبر 2026
- Inspection = passed
- Disposition = credit_requested
- Unit Price = 75
- Discount = 10%
- Tax = VAT15-PURCHASE

الحساب:

- Gross = 75.00
- Discount = 7.50
- Taxable = 67.50
- VAT = 10.13
- Total = 77.63

---

# 23. QA Workflow Proof

تم تنفيذ:

`Draft`
→ `Contract Save`
→ `Send`
→ `Complete`

النتيجة:

`Completed`

---

# 24. QA Stock Proof

قبل:

`5.00`

بعد:

`4.00`

الفرق:

`-1.00`

inventory_log:

- movement_type = SupplierReturn
- qty = 1
- source_branch = BR-01
- reference = QA-SR-UI-CONTRACT-20260927-01
- idempotency key موجود.

---

# 25. QA Supplier Ledger Proof

سجل المورد:

- debit = 77.63
- credit = 0.00
- balance = -307.88

و:

`suppliers.accounts_payable = -307.88`

أي أن master payable تمت مزامنته مع ledger.

---

# 26. QA GL Proof

Journal:

`JE-SVR-QA-SR-UI-CONTRACT-20260927-01`

Status:

`Posted`

السطور:

| الحساب | مدين | دائن |
|---|---:|---:|
| الموردون (ذمم دائنة) | 77.63 | 0.00 |
| المخزون السلعي | 0.00 | 67.50 |
| ضريبة القيمة المضافة القابلة للاسترداد | 0.00 | 10.13 |

التحقق:

`Debit = 77.63`

`Credit = 77.63`

النتيجة:

**Balanced**

---

# 27. QA Tax Proof

Tax transaction:

- source_type = SupplierReturn
- taxable_amount = 67.50
- tax_amount = 10.13
- direction = OTHER
- journal_entry_id مرتبط
- source_reference = QA-SR-UI-CONTRACT-20260927-01

---

# 28. QA Idempotency Proof

Contract Save operation registry:

`QA-SR-UI-CONTRACT-OP-20260927-01`

Status:

`completed`

الاستجابة الأصلية:

- success = true
- duplicate = false
- voucher_id = QA voucher
- total = 77.63

لا توجد كتابة ثانية للعقد تحت نفس operation key.

البيانات محفوظة ولا تُحذف.

---

# 29. QA No-PO Path

اختبار QA الحالي تعمد أن يكون:

- PO = NULL
- Purchase Invoice = NULL

ومع ذلك:

- Contract Save = PASS
- Send = PASS
- Complete = PASS
- Stock = PASS
- Supplier Ledger = PASS
- AP = PASS
- GL = PASS
- Tax = PASS

وهذا يثبت أن عدم وجود PO/Invoice ليس dependency مخفيًا.

---

# 30. QA Authenticated Supplier Directory

بعد Production RLS fix:

Session:

`vouchers@rawaea.com`

أصبح:

`visible_suppliers = 4`

مع:

`supplier_permission = false`

هذا هو الاختبار الحاسم للقائمة المنسدلة.

---

# 31. Production Source / RPC Contract

## Existing write chain

`create-stock-voucher`

→ `create_manual_stock_voucher_atomic`

→ canonical stock core

وعند Send:

`send_stock_voucher_atomic`

→ `assert_supplier_return_contract`

→ `post_stock_movement`

→ supplier ledger / accounting / tax contract

تم الحفاظ على هذا المسار ولم تتم إضافة Writer موازي.

---

# 32. van-sales Integration Review

المصدر:

`companies/company-1/sales/van-sales.html`

SHA:

`8d61382a8e0025a0d079e71dd94f33d106d9088e`

المسار التنفيذي الحالي:

- `setup-van-branch`
- vehicle/mobile branch
- `syncDown()`
- `save-sales-invoice`
- `save-inventory-count`
- إعادة المزامنة إلى Production

لا يوجد SupplierReturn dependency.

وهذا صحيح معماريًا:

`Van Sales`

تتعامل مع:

- Vehicle Stock
- Customer Sales
- Customer Balance
- Inventory Count

بينما:

`Warehouse Vouchers / SupplierReturn`

تتعامل مع:

- Warehouse movement
- Supplier relationship
- Return contract
- Supplier accounting

والتكامل بينهما هو عبر:

`Central Stock / Inventory / Accounting`

وليس بتشابك مباشر بين صفحات الواجهة.

لذلك:

**لا تعديل على van-sales في هذه Closure.**

---

# 33. لماذا هذا البناء مناسب لـRAWAEA

التطبيقات الميدانية المنفصلة تحقق:

- سرعة تشغيل.
- أقل ازدحامًا على العامل الميداني.
- واجهة مخصصة للدور.
- استمرار التشغيل المحلي.
- تمييز واضح بين Warehouse / Sales / Delivery / Purchasing.

والنظام الأم يبقى:

`Control Plane`

بينما التطبيقات:

`Execution Plane`

أما Supabase/RPC/Core فهي:

`System Transaction Plane`

وهذا فصل صحي يجب الحفاظ عليه.

---

# 34. المقارنة مع الأنظمة المنافسة

المقارنة هنا ليست ترتيبًا للأفضل، بل استخراجًا للعقود الوظيفية ذات الصلة.

## Odoo

يوثق Odoo عمليات Return / Reverse Transfer، كما يربط valuation بحركة الإرجاع ويملك مسارات مالية للـVendor Credit.

مراجع:

- https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/purchase/manage_deals/manage.html
- https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/inventory_valuation/operations_valuation.html

## Microsoft Dynamics 365

يوثق Return PO للمورد، partial return، unplanned receipt، وCredit Note workflow مع الترحيل اللوجستي.

مرجع:

- https://learn.microsoft.com/en-us/dynamics365/supply-chain/procurement/tasks/create-purchase-return-order

## SAP S/4HANA

يوثق Return to Supplier كدورة تشمل Return Purchase Order، Return Delivery، Warehouse execution، وفي بعض المسارات inspection وreturn follow-up.

مراجع:

- https://help.sap.com/docs/SAP_S4HANA_CLOUD/87f9b54f9c4f4e75aff0061860a6589a/48fa152d678a4fe2858d014d7e8790f9.html
- https://help.sap.com/docs/s4hana-cloud-best-practices/return-to-supplier-bmk-br/create-returns-purchase-order
- https://help.sap.com/docs/sap_s4hana_cloud/74ffc024fd794eeca49dc8ffe7f9870d/1a81820e0ab948749bb54700d21ee44c.html

## Daftra

يوثق Purchase Debit Notes، ربطها أو عدم ربطها بفاتورة، إنشاء journal entry تلقائيًا، وPurchase Refund المرتبط بالفاتورة.

مراجع:

- https://docs.daftra.com/en/user_manual/issuing-credit-notes-and-refund-receipts-for-purchase-invoices/
- https://docs.daftra.com/en/user_manual/adding-purchase-invoice/
- https://docs.daftra.com/en/tutorial/purchase-invoice-net-position-report/

## Manager.io

يوثق Supplier Debit Notes المرتبطة بالمرتجع، المورد، Purchase Invoice الاختيارية، Reference، والمخزون والضرائب والذمم الدائنة.

مرجع:

- https://www2.manager.io/guides/7426

## نتيجة المقارنة

الـContract الحالي في RAWAEA أصبح يغطي:

- سبب المرتجع.
- المورد.
- PO الاختياري.
- Purchase Invoice الاختيارية.
- Credit Note / RMA.
- عنوان الإرجاع.
- Inspection.
- Disposition.
- valuation على مستوى السطر.
- Discount.
- Tax.
- Supplier Ledger.
- GL.
- Tax transaction.
- Stock.
- Audit.
- Idempotency.

الفجوة المتبقية بعد هذا الإغلاق ليست Contract schema، بل تنفيذ Owner UI + Browser E2E + published artifact verification.

---

# 35. لماذا لم تُنشأ جداول جديدة

Production الحالي يحتوي بالفعل على:

- Return Contract columns في stock_vouchers
- valuation columns في stock_voucher_details
- return_reasons
- finance_tax_codes
- finance_tax_transactions
- purchase_document_links
- supplier_ledger
- suppliers.accounts_payable

لذلك إنشاء جداول جديدة كان سيؤدي إلى duplicate truth.

قرار CTO:

**لا جدول جديد.**

---

# 36. لماذا لم تُنشأ Edge Function

المشروع في Spend/Gateway boundary لعدد Edge Functions.

والوظائف الحالية تغطي المسار.

قرار CTO:

**لا Edge Function جديدة.**

وتم الاعتماد على:

- existing authenticated RPC
- existing Edge wrappers
- existing canonical stock core

---

# 37. Root Cause النهائي

## Root Cause A — Frontend Contract Drift

Production Contract تم إغلاقه، لكن المصدر الحالي `vouchers.html` ظل على:

`SupplierReturn = branch + supplier فقط`

ولم يستهلك:

`save_supplier_return_contract`

وبذلك كان backend أكثر اكتمالًا من consumer.

## Root Cause B — Supplier Picker Data Access Drift

الـSmart Search لم يكن العيب.

الـdefect كان:

`suppliers_select_company`

تشترط صلاحية `suppliers`.

لكن مستخدم `مخزني / أذونات` يملك:

`["warehouse"]`

فكان:

`Supplier Rows = 0`

تم إصلاحه في Production.

## Root Cause C — Report342 SR-10 Ordering Defect

الـpatch المقترح سابقًا كان يمسح `editVoucherCode` ثم يختبره.

تم اكتشافه قبل التطبيق وإصلاحه هنا.

## Root Cause D — stale Contract State Risk

لم يكن `supplierReturnDraft` يُصفَّر في New/Edit/Back.

تم تضمين إصلاحه في Owner Patch.

---

# 38. حالة الملفات

| الأصل | الحالة |
|---|---|
| Production Contract | CLOSED |
| Production RLS | CLOSED |
| Supplier Dropdown Data Access | CLOSED |
| RPC ACL hardening | CLOSED |
| QA E2E DB/RPC | PASS |
| QA permanent data | RETAINED |
| vouchers.html source | OWNER PATCH READY |
| main.html | PROTECTED / UNTOUCHED |
| van-sales.html | PROTECTED / UNTOUCHED |
| Browser E2E | OPEN / UNVERIFIED |
| Published artifact | OPEN / UNVERIFIED |

---

# 39. الخطوات الوحيدة المتبقية على Owner

1. تطبيق SR-04 → SR-10 حرفيًا في `vouchers.html`.
2. Parse كامل للـembedded JavaScript.
3. Commit.
4. Publish.
5. Verify served artifact SHA.
6. Authenticated Browser E2E:
   - Supplier search
   - Supplier dropdown
   - Contract modal
   - Return Reason
   - PO optional
   - Invoice optional
   - Credit Note / RMA
   - Inspection
   - Disposition
   - line price / discount / tax
   - Save
   - Send
   - Complete
7. إعادة قراءة QA voucher في Production.
8. تأكيد stock / inventory_log / supplier ledger / AP / GL / tax.

لا يجب تحويل DB/RPC PASS إلى Browser PASS.

---

# 40. تعليمات البداية للمساعد التالي

لا يبدأ من Report343 فقط.

يبدأ بهذا الترتيب:

`CURRENT GIT`
→ `CURRENT SOURCE`
→ `CURRENT PRODUCTION`
→ `CURRENT DATABASE`
→ `CURRENT DEPLOYMENT`

ثم يتحقق من:

- System HEAD الجديد الناتج عن هذه الجلسة.
- Production migration:
  `20260927165000_harden_supplier_return_voucher_directory_and_rpc_acl_20260927.sql`
- Mother vouchers SHA.
- SR-04 → SR-10.
- QA voucher `QA-SR-UI-CONTRACT-20260927-01`.

ولا يعيد:

- SR-01
- SR-02
- SR-03
- DirectSale
- DirectReturn
- Fleet
- Contract Production schema

ولا يلمس:

- main.html

ولا ينشئ:

- Edge Function جديدة.

---

# 41. SELF AUDIT

## تم إثباته فعليًا

- Production SupplierReturn contract موجود.
- Supplier directory لم يعد فارغًا لمستخدم الأذونات.
- supplier permission غير مطلوب لقراءة دليل الموردين في هذا الدور، دون منح صلاحية إدارة المورد.
- Return Reasons أصبحت company-scoped.
- assert RPC لم يعد public/anon executable.
- save/get Contract أصبحا authenticated-only.
- QA SupplierReturn Completed.
- Stock movement صحيح.
- inventory_log صحيح.
- Supplier Ledger صحيح.
- suppliers.accounts_payable صحيح.
- Journal balanced.
- Tax transaction موجود.
- Idempotency registry موجود.
- لا PO / Invoice dependency في المسار التجريبي.
- لم تُنشأ Edge Function.
- لم يتغير main.html.
- لم يتغير vouchers.html بواسطة المساعد.
- لم يتغير van-sales.

## لم يُثبت بعد

- Authenticated Browser E2E.
- Published Artifact.
- Owner-applied SR-04 → SR-10.

---

# 42. الإغلاق

**Production / Database / Contract / Security / QA: CLOSED**

**Source UI: PATCH READY — OWNER APPLY**

**Browser / Deployment: OPEN**

ولا توجد في هذه المرحلة حاجة لإعادة بناء SupplierReturn أو إعادة فتح Production Contract.

