
# Report342 — إغلاق Business Contract لمسار SupplierReturn في الأذونات المخزنية

**التاريخ:** 2026-09-27  
**النطاق:** companies/company-1/warehouse/vouchers.html من جهة Owner Surgical Patch فقط، مع تنفيذ Production/Supabase مباشرة.  
**القيود:** main.html لم يُلمس. vouchers.html لم يُعدّل بواسطة المساعد. van-sales.html لم يُلمس. لا Edge Function جديدة.

---

## 1. نقطة البداية المثبتة

### System Git
- Repository: papamohammed77-glitch/rawaie-erp-New
- آخر حالة موثقة قبل التنفيذ: f9eb8b14f13cd6bc8ad4fa1fa11c9c98f48ebde4
- تلك الحالة أشارت إلى استمرار فجوات Business Contract بعد إغلاق عيب SupplierReturn الأساسي.

### Mother Git
- Repository: papamohammed77-glitch/erp-frontend
- HEAD الفعلي الذي تمت مراجعته: 4a322fa793027f8584d9f0d55638ef5a14aebc03
- Parent: fce3dfaa0503957791113a5ebf57d402a4a82764
- vouchers.html SHA: 6aca57d8baa8c78b616a281411f15438f34676bf
- main.html SHA: 810e4f5440f5975f55099a124deb42b086a49183
- van-sales.html SHA: 8d61382a8e0025a0d079e71dd94f33d106d9088e

Commit 4a322... سبق أن أغلق SR-01/SR-02/SR-03:
- إزالة اعتماد SupplierReturn على supplierBranchMap.
- إزالة PO gate من submit.
- تسمية الوجهة بالمورد.

هذه النقاط لم تُعاد ولم تُعدل.

---

## 2. دور التطبيق والعقد المعماري

vouchers.html تطبيق الأذونات المخزنية التشغيلية المستقلة، وليس تطبيق Orders/Runsheets.

SupplierReturn هو:
Branch → Supplier

السلسلة الوظيفية:

SupplierReturn Draft
→ Send
→ Physical Stock Movement
→ Complete
→ Supplier Ledger
→ GL
→ Audit

وجود PO أو Purchase Invoice هو سياق مرجعي اختياري، وليس شرطًا لإنشاء المرتجع.

مسارا الشراء في RAWAEA يظلان منفصلين:

### Purchase workflow
PO → Receiving → Stock → Supplier Ledger → Accounting

### Direct Purchase workflow
شراء مباشر/فاتورة صغيرة → Stock/Accounting

SupplierReturn يمكنه الإشارة إلى أي من المسارين دون تحويل نفسه إلى PO-bound transaction.

---

## 3. van-sales والتكامل

van-sales.html:
- يجهز Mobile Branch عبر setup-van-branch.
- يسجل المبيعات عبر save-sales-invoice.
- يتعامل مع مخزون المركبة والجرد.
- لا ينشئ SupplierReturn.

لا يوجد نقص مثبت في van-sales يستلزم تعديلًا في هذه Closure.

التكامل الصحيح يتم عبر البنية المركزية:
stock_branches + inventory_log + ERP accounting.

---

## 4. سبب عطل المورد والبحث الذكي

تم إثبات أن Search Engine ليس سبب العطل.

العيب كان Candidate Source داخل pickArr:
SupplierReturn → supplierBranchMap → purchase_orders → no PO → empty candidate list.

Commit 4a322... أزال هذا القيد بالفعل.

النتيجة الحالية:
- اسم المورد قابل للبحث.
- كود المورد قابل للبحث.
- الهاتف قابل للبحث.
- dropdown يعرض الموردين النشطين.

لا يُعاد كتابة pickSearch.

---

# 5. Production Closure المنفذ

تم تنفيذ migration Production:

close_supplier_return_contract_accounting_20260927

وتم حفظ النسخة الدائمة في System Git:

supabase/migrations/20260927152000_close_supplier_return_contract_accounting.sql

Git commit:
d5a124803a9cc17560b4022844cb04eb3e3d1312

لم تُنشأ Edge Function جديدة.

---

# 6. DB Contract

## stock_vouchers

تمت إضافة:

- return_reason_id
- supplier_credit_note_ref
- supplier_rma_ref
- purchase_invoice_id
- purchase_order_id
- return_to_address
- inspection_status
- disposition
- return_currency
- return_subtotal
- return_discount_amount
- return_tax_amount
- return_total_amount

مع Foreign Keys وChecks.

## stock_voucher_details

تمت إضافة:

- gross_amount
- discount_percent
- discount_amount
- taxable_amount
- tax_code_id
- tax_rate
- tax_amount
- net_amount
- line_total

ومنع القيم غير المنطقية.

---

# 7. Return Reasons

تم إدخال Master Data للشركة:

- SR001 — تالف / جودة غير مطابقة
- SR002 — صنف أو كمية غير مطابقة
- SR003 — منتهي أو قريب انتهاء الصلاحية
- SR004 — فائض / شراء غير مطلوب
- SR005 — رفض المورد / اتفاق تجاري

---

# 8. Tax Contract

تم إنشاء:

- COA 126 — ضريبة القيمة المضافة القابلة للاسترداد
- VAT15-PURCHASE
- Rate = 15%

وتم ربط Tax Code بحساب الضريبة.

---

# 9. Supplier Payable Contract

كان هناك drift مثبت بين:
- suppliers.accounts_payable
- supplier_ledger.balance

تم إغلاقه بواسطة Trigger مركزي:
trg_sync_supplier_accounts_payable

بعد التنفيذ:

payable_balance_mismatches = 0

من أصل 4 موردي الشركة الذين تم فحصهم.

أمثلة:
- SUPP-1001 = 3970 / Ledger = 3970
- QA-SR-20260927 = -150 / Ledger = -150
- QA-SR-CLOSURE-20260927 = -230.25 / Ledger = -230.25

---

# 10. RPC بدل Edge Function جديدة

تم استخدام RPC مصادق عليه بدل إنشاء Function جديدة.

## save_supplier_return_contract

يغلق:
- authentication
- company isolation
- wildcard/permission
- supplier
- return reason
- optional PO
- optional Purchase Invoice
- PO/Invoice consistency
- return-to address
- inspection
- disposition
- line price
- discount
- tax
- document links
- audit
- idempotency

## get_supplier_return_contract

يعيد العقد كاملًا.

## assert_supplier_return_contract

حاجز نهائي قبل Send/Complete.

---

# 11. Accounting Contract

مثال مثبت:

Gross = 150
Discount = 15
Taxable = 135
VAT = 20.25
Total = 155.25

القيد:

| الحساب | مدين | دائن |
|---|---:|---:|
| الموردون | 155.25 | 0 |
| المخزون | 0 | 135.00 |
| ضريبة القيمة المضافة القابلة للاسترداد | 0 | 20.25 |

النتيجة:
Debit = Credit = 155.25

SupplierReturn يخفض:
- المخزون بصافي القيمة.
- أصل ضريبة المشتريات بقيمة الضريبة.
- التزام المورد بإجمالي المرتجع.

---

# 12. Credit Note / RMA

تمت إضافة:
- supplier_credit_note_ref
- supplier_rma_ref

وهذه المراجع تحفظ المستند الخارجي للمورد.

لم يتم إنشاء مستند مالي موازٍ من النوع Credit Note داخل نظام الشراء لأن RAWAEA لديه أصلًا مسار Purchase Returns مستقل.

الأثر المالي للمرتجع يتم مباشرة عبر:
Supplier Ledger + GL.

هذا يمنع ازدواجية الحقيقة المحاسبية.

---

# 13. QA Fixture — لا حذف

## Supplier
QA-SR-CLOSURE-20260927

ID:
8a4ec462-d9ef-43e3-943d-9c1369b2561e

Address:
شارع الاختبار 27 - مخزن المورد

## Item
QA-SR-ITEM-20260927

Cost:
75

## PO
QA-SR-PO-20260927

ID:
967e9cfa-01c7-42ac-90c7-dad16b3b4de3

Status:
Draft

## Purchase Invoice
QA-SR-INV-20260927

ID:
2f6208c9-32e9-41a2-9014-56826f8b5e84

Status:
Draft

---

# 14. E2E Test IN-4

Voucher:
IN-4

ID:
9a849d3a-399c-447a-8696-597438050d70

Contract:
- Qty 2
- Unit price 75
- Gross 150
- Discount 15
- Taxable 135
- VAT 20.25
- Total 155.25
- Return reason SR001
- Inspection passed
- Disposition credit_requested
- Credit Note QA-CN-20260927-01
- RMA QA-RMA-20260927-01
- PO = QA-SR-PO-20260927
- Invoice = QA-SR-INV-20260927

Workflow:
Draft → Sent → Completed

ثبت:
- stock movement
- inventory_log
- supplier ledger
- accounts_payable
- journal
- tax transaction
- purchase_document_links

---

# 15. IN-4 Stock Proof

قبل = 8

بعد = 6

inventory_log:
- reference = IN-4
- movement_type = SupplierReturn
- qty = 2
- source branch = BR-01
- idempotency key موجود.

---

# 16. IN-4 Accounting Proof

Journal:
JE-SVR-IN-4

ID:
782d8f87-d112-4cde-9fc9-28c39cc80124

Lines:
- Supplier Payable debit 155.25
- Inventory credit 135
- VAT asset credit 20.25

Balanced.

Tax transaction:
- source_type = SupplierReturn
- taxable = 135
- tax = 20.25
- direction = OTHER
- journal_entry_id مربوط.
- source_reference = IN-4

---

# 17. IN-4 Document Traceability

تم إنشاء:

stock_voucher → purchase_invoice

و:

stock_voucher → purchase_order

كـTyped Document Links.

---

# 18. IN-4 Idempotency

إعادة save بنفس operation_id:

QA-SR-CONTRACT-OP-20260927

أعادت:
duplicate = true

دون إنشاء Contract ثانٍ.

---

# 19. E2E Test IN-5 — Direct Purchase

الغرض: إثبات أن PO وPurchase Invoice مراجع اختيارية وليستا شرطًا مخفيًا.

Voucher:
IN-5

Contract:
- Qty 1
- Gross 75
- Discount 0
- Tax 0
- Total 75
- PO = NULL
- Invoice = NULL
- Return Reason = SR001

Workflow:
Draft → Sent → Completed

Accounting:
- Supplier debit 75
- Inventory credit 75
- Balanced

النتيجة:
Direct Purchase path يعمل بدون PO أو Invoice reference.

---

# 20. Negative Test IN-6

تم إنشاء IN-6 عمدًا بدون Return Reason.

محاولة Send أعادت:

سبب المرتجع مطلوب و/أو غير صالح

وظلت الحالة:

Draft

ولم تحدث حركة مخزنية.

هذا يثبت أن Contract Guard يسبق Physical Stock Movement.

---

# 21. المنافسون — ما تم أخذه كمرجع

Odoo يوثق Returns/Reverse Transfers وCredit Notes، وتظهر وثائقه أن المرتجع والجانب المالي مرتبطان ولكن لا يُختزلان في كمية فقط.

Dynamics 365 يتعامل مع Return-to-Vendor / Return Purchase Order كعملية لها دورة مستقلة وربط بالمستندات.

SAP S/4HANA يوثق Return to Supplier مع:
- Return Purchase Order
- Return Delivery
- WMS execution
- inspection/return follow-up
- return-to-address وreplacement-oriented handling.

Daftra يدعم Purchase Returns / Debit Notes والتعامل مع الضرائب والخصومات والمراجع.

Manager يدعم Supplier Debit Notes وربطها بالمورد وعمليات Accounts Payable.

المراجع:
https://www.odoo.com/documentation/17.0/applications/inventory_and_mrp/repairs/repair_orders.html
https://learn.microsoft.com/en-us/dynamics365/supply-chain/sales-marketing/cancel-return-order
https://help.sap.com/docs/SAP_S4HANA_CLOUD_BEST_PRACTICES/3f32d6cfdc6103e29a68fd71ff6c3633/a1d94bf6ba794569be331c07563b9953.html
https://help.sap.com/docs/SAP_S4HANA_CLOUD/a376cd9ea00d476b96f18dea1247e6a5/aad8417242c84d70a64b2742fe818c90.html
https://docs.daftra.com/en/user_manual/adding-purchase-invoice/
https://www2.manager.io/guides/7426

---

# 22. الفجوات التي أُغلقت في هذه Closure

CLOSED:

- Return Reason
- Supplier Credit Note reference
- Supplier RMA reference
- Optional Purchase Invoice reference
- Optional PO reference
- Return-to Address
- Inspection status
- Disposition
- Tax valuation
- Discount valuation
- Line valuation
- Supplier Ledger effect
- GL effect
- Inventory effect
- Tax transaction
- Document links
- Audit
- Idempotency
- Payable synchronization

---

# 23. ما لم يُنشأ عمدًا

لم يتم إنشاء:
- Edge Function جديدة
- SupplierReturn parallel service
- Credit Note duplicate accounting object
- PO dependency
- Order/Runsheet dependency
- Van Sales dependency

---

# 24. OWNER SURGICAL PATCH — SOURCE ONLY

## الملف الوحيد

companies/company-1/warehouse/vouchers.html

---

## SR-04 — App refs

ابحث عن كائن refs الذي يحتوي supplierBranchMap.

أضف:

~~~javascript
returnReasons:[],
taxCodes:[],
~~~

لا تحذف supplierBranchMap.

---

## SR-05 — loadRefs

داخل loadRefs ابحث بالضبط عن قراءة:

~~~javascript
.from('purchase_orders')
~~~

بعدها أضف:

~~~javascript
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
}),
~~~

ثم بجوار إسناد refs.reps:

~~~javascript
s.refs.returnReasons=r[5]||[];
s.refs.taxCodes=r[6]||[];
~~~

---

# 25. SR-06 — routeHtml SupplierReturn only

ابحث عن الفرع:

~~~javascript
if(t==='SupplierReturn')return
~~~

استبدل قيمة SupplierReturn فقط بـ:

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

لا تغيّر فروع الأنواع الأخرى.

---

# 26. SR-07 — Contract helper methods

مكان الإدراج:
مباشرة بعد routeHtml.

أضف:

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

saveSupplierReturnContract:function(code,callback){

    var s=this,
        d=s.supplierReturnDraft;

    if(
        !d||
        !d.supplier_id||
        String(d.supplier_id)!==
        String(
            (RW_UI.byId('wsTo')||{}).value||''
        )
    ){
        RW_UI.showError(
            'بيانات عقد مرتجع المورد غير مكتملة.'
        );
        return;
    }

    var payload=
        JSON.parse(JSON.stringify(d));

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
                RW_UI.showError(
                    (
                        r.error &&
                        r.error.message
                    )||
                    'فشل حفظ عقد مرتجع المورد'
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

            RW_UI.showError(
                e.message||
                'فشل حفظ عقد مرتجع المورد'
            );

        });
},

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

        var draft=
            existing||
            s.supplierReturnDraft||
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
                    '<label class="text-[10px] text-slate-400 block mb-1">عنوان إعادة التوريد *</label>'+
                    '<input id="srReturnAddress" class="smart-input w-full" value="'+
                        s.esc(
                            draft.return_to_address||
                            supplier.address||
                            ''
                        )+
                    '" placeholder="عنوان تسليم المرتجع للمورد">'+
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
                        'عنوان إعادة التوريد مطلوب.'
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

# 27. SR-08 — submit preflight

داخل submit، بعد التحقق الحالي لـSupplierReturn، أضف قبل create/update:

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

# 28. SR-09 — create callback

في success callback لـcreate-stock-voucher:

لا تنفذ s.back مباشرة في SupplierReturn.

بعد إنشاء voucher بنجاح استخدم:

~~~javascript
var createdCode=
    j.voucher_code||
    j.code||
    '';

if(
    s.type==='SupplierReturn' &&
    createdCode
){

    s.saveSupplierReturnContract(
        createdCode,
        function(err){

            if(err){
                s.mode='edit';
                s.editVoucherCode=
                    createdCode;
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

s.back();
return;
~~~

---

# 29. SR-10 — edit callback

في success callback لمسار update:

~~~javascript
if(
    s.type==='SupplierReturn' &&
    s.editVoucherCode
){

    s.saveSupplierReturnContract(
        s.editVoucherCode,
        function(err){

            if(err){
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

s.back();
return;
~~~

---

# 30. ملاحظات على Owner Patch

لا تعدل:
- pickSearch
- send
- receive
- post_stock_movement
- Edge Functions
- main.html
- van-sales

التعديل يقتصر على Contract UI + authenticated RPC call.

---

# 31. سبب اختيار Modal Contract

لأنها:
- لا تغير Layout الأساسي للأذونات.
- لا تعيد بناء renderCart.
- تسمح بالتقييم line-by-line.
- تسمح بالـPO/Invoice الاختياري.
- تبقي SupplierReturn مستقلًا.
- تسمح بتوسعة fields مستقبلًا.
- تترك physical workflow كما هو.

---

# 32. مصفوفة الإغلاق

| البند | الحالة |
|---|---|
| SupplierReturn مستقل عن PO | PASS |
| Supplier Search | PASS في current source |
| Return Reason | PASS |
| Credit Note ref | PASS |
| RMA ref | PASS |
| Optional PO | PASS |
| Optional Invoice | PASS |
| Return-to Address | PASS |
| Inspection | PASS |
| Disposition | PASS |
| Line Price | PASS |
| Line Discount | PASS |
| Line Tax | PASS |
| Inventory Movement | PASS |
| Inventory Log | PASS |
| Supplier Ledger | PASS |
| Supplier AP master sync | PASS |
| Journal | PASS |
| Tax Transaction | PASS |
| Document Links | PASS |
| Idempotency | PASS |
| Negative Guard | PASS |
| Persistent QA | PASS |
| New Edge | NO |
| main.html touched | NO |
| vouchers source touched by assistant | NO |
| van-sales touched | NO |
| Owner UI patch | READY |
| Browser E2E | OPEN |
| Published artifact | OPEN |

---

# 33. الحالة التي يبدأ منها المساعد التالي

مصادر الحقيقة:

CURRENT GIT
+
CURRENT SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT EVIDENCE

لا تبدأ من تقرير قديم باعتباره حالة حالية.

ابدأ تحديدًا من:
- System HEAD بعد هذا Documentation Closure
- Mother HEAD 4a322...
- vouchers SHA 6aca...
- main SHA 810e...
- van-sales SHA 8d613...
- Production migration close_supplier_return_contract_accounting_20260927
- QA IN-4
- QA IN-5
- QA IN-6

ثم تحقق من Owner Patch SR-04 → SR-10.

بعدها:
Full parse
→ Published artifact
→ Authenticated Browser E2E
→ Production verification

لا تعيد SR-01/SR-02/SR-03.
لا تعيد DirectSale.
لا تعيد DirectReturn.
لا تعيد Fleet.
لا تنشئ Edge Function جديدة.
لا تلمس main.html.

---

# 34. Self Audit

### ما تم إثباته
- Production Contract مكتمل.
- Direct purchase return يعمل.
- PO/Invoice referenced return يعمل.
- Accounting balanced.
- Stock effect صحيح.
- Supplier payable synchronized.
- Idempotency تعمل.
- Guards تعمل.
- QA دائم.

### ما لم يتم إثباته
- Browser E2E بعد Owner Patch.
- Published artifact بعد Owner Patch.

### تعريف الإغلاق
وجود DB columns أو RPC ليس Closure.

Closure الحقيقي:

Source
→ Browser
→ Authenticated RPC
→ DB
→ Stock
→ Ledger
→ GL
→ Audit
→ Production verification

## END — Report342
