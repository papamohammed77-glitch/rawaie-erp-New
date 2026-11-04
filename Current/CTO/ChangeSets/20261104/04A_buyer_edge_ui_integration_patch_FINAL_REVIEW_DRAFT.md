# RAWAEA ERP — Buyer Phase 1
# حزمة الربط النهائي بين Buyer ومدخل المشتريات المركزي

**الحالة:** مسودة فروق تنفيذية؛ لا تعدل المصدر التشغيلي  
**التطبيق:** `companies/company-1/purchasing/buyer.html`  
**Edge القائم:** `save-purchase-order` الإصدار الحي 22  
**المبدأ:** نفس الوظيفة المركزية ونفس JWT المستخدم؛ لا Edge Function جديدة.

---

## 1. العمليات المطلوب إضافتها إلى مدخل Edge الحالي

| العملية | RPC الهدف | طريقة الاستدعاء |
|---|---|---|
| إنشاء فاتورة PO | `purchase_create_po_invoice_atomic` | `profileClient.rpc` |
| تعديل فاتورة PO | `purchase_update_po_invoice_atomic` | `profileClient.rpc` |
| إنشاء Quick Market | `purchase_create_quick_market_invoice_atomic` | `profileClient.rpc` |
| تعديل Quick Market | `purchase_update_quick_market_invoice_atomic` | `profileClient.rpc` |
| إثبات المورد إلى Buyer | `buyer_goods_custody_register_handover_atomic` | `profileClient.rpc` |
| قراءة رصيد الحيازة | `buyer_goods_custody_get_balances_atomic` | `profileClient.rpc` |
| قراءة تقدم تسليم فاتورة | `buyer_goods_custody_get_invoice_handover_progress_atomic` | `profileClient.rpc` |
| حذف مسودة Quick Market | `purchase_delete_quick_market_draft_atomic` | `profileClient.rpc` |
| ترحيل فاتورة PO | `purchase_post_buyer_invoice_atomic` | `profileClient.rpc` |

### 1.1 حراسة الصلاحيات

في كتلة الصلاحيات قبل احتساب `operationId`، أضف:

```typescript
} else if ([
  "CREATE_QUICK_MARKET_INVOICE",
  "UPDATE_QUICK_MARKET_INVOICE",
  "REGISTER_GOODS_HANDOVER",
  "DELETE_QUICK_MARKET_DRAFT"
].includes(op)) {
  requireAny(["purchases"]);
} else if ([
  "CREATE_PO_INVOICE",
  "UPDATE_PO_INVOICE",
  "POST_INVOICE"
].includes(op)) {
  requireAll(["purchases", "finance"]);
} else if ([
  "GET_GOODS_CUSTODY",
  "GET_QUICK_MARKET_HANDOVER_PROGRESS"
].includes(op)) {
  requireAny(["purchases", "finance", "finance_manager"]);
```

يجب إدراج هذه الفروع في موضعها الصحيح داخل سلسلة `if / else if` الحالية دون حذف أي فرع أو تغيير صلاحيات العمليات القائمة.

### 1.2 توجيه الإنشاء والتعديل والترحيل

استبدل فروع الإنشاء/الترحيل الحالي بهذه الفروع، مع إبقاء `UPDATE_DRAFT_INVOICE` التاريخي كما هو للفواتير غير المصنفة القديمة:

```typescript
} else if (op === "CREATE_INVOICE" || op === "CREATE_PO_INVOICE") {
  if (!p.purchase_order_id) {
    throw new Error("فاتورة الشراء العادية تتطلب PO؛ استخدم Quick Market للمشتريات دون PO");
  }
  ({ data, error } = await profileClient.rpc("purchase_create_po_invoice_atomic", {
    p_company_id: companyId,
    p_supplier_id: p.supplier_id,
    p_purchase_order_id: p.purchase_order_id,
    p_branch_id: p.branch_id || null,
    p_due_date: p.due_date || null,
    p_supplier_invoice_no: p.supplier_invoice_no || null,
    p_notes: p.notes || null,
    p_items: p.items || [],
    p_operation_id: operationId
  }));
} else if (op === "UPDATE_PO_INVOICE") {
  ({ data, error } = await profileClient.rpc("purchase_update_po_invoice_atomic", {
    p_company_id: companyId,
    p_invoice_id: p.id,
    p_supplier_id: p.supplier_id,
    p_purchase_order_id: p.purchase_order_id,
    p_branch_id: p.branch_id || null,
    p_due_date: p.due_date || null,
    p_supplier_invoice_no: p.supplier_invoice_no || null,
    p_notes: p.notes || null,
    p_items: p.items || [],
    p_operation_id: operationId
  }));
} else if (op === "CREATE_QUICK_MARKET_INVOICE") {
  ({ data, error } = await profileClient.rpc("purchase_create_quick_market_invoice_atomic", {
    p_company_id: companyId,
    p_supplier_id: p.supplier_id,
    p_branch_id: p.branch_id,
    p_due_date: p.due_date || null,
    p_supplier_invoice_no: p.supplier_invoice_no || null,
    p_notes: p.notes || null,
    p_items: p.items || [],
    p_settlement_source: p.settlement_source,
    p_cash_custody_id: p.cash_custody_id || null,
    p_operation_id: operationId
  }));
} else if (op === "UPDATE_QUICK_MARKET_INVOICE") {
  ({ data, error } = await profileClient.rpc("purchase_update_quick_market_invoice_atomic", {
    p_company_id: companyId,
    p_invoice_id: p.invoice_id,
    p_supplier_id: p.supplier_id,
    p_branch_id: p.branch_id,
    p_due_date: p.due_date || null,
    p_supplier_invoice_no: p.supplier_invoice_no || null,
    p_notes: p.notes || null,
    p_items: p.items || [],
    p_settlement_source: p.settlement_source,
    p_cash_custody_id: p.cash_custody_id || null,
    p_operation_id: operationId
  }));
} else if (op === "POST_INVOICE") {
  ({ data, error } = await profileClient.rpc("purchase_post_buyer_invoice_atomic", {
    p_company_id: companyId,
    p_invoice_id: p.id,
    p_actor: user.email
  }));
```

### 1.3 إثبات الحيازة وقراءة الرصيد والتقدم

```typescript
} else if (op === "REGISTER_GOODS_HANDOVER") {
  ({ data, error } = await profileClient.rpc("buyer_goods_custody_register_handover_atomic", {
    p_company_id: companyId,
    p_invoice_id: p.invoice_id,
    p_vehicle_id: p.vehicle_id || null,
    p_items: p.items || [],
    p_evidence_path: p.evidence_path || null,
    p_notes: p.notes || null,
    p_operation_id: operationId
  }));
} else if (op === "GET_GOODS_CUSTODY") {
  ({ data, error } = await profileClient.rpc("buyer_goods_custody_get_balances_atomic", {
    p_company_id: companyId,
    p_custodian_user_id: p.custodian_user_id || null
  }));
} else if (op === "GET_QUICK_MARKET_HANDOVER_PROGRESS") {
  ({ data, error } = await profileClient.rpc("buyer_goods_custody_get_invoice_handover_progress_atomic", {
    p_company_id: companyId,
    p_invoice_id: p.invoice_id
  }));
} else if (op === "DELETE_QUICK_MARKET_DRAFT") {
  ({ data, error } = await profileClient.rpc("purchase_delete_quick_market_draft_atomic", {
    p_company_id: companyId,
    p_invoice_id: p.invoice_id,
    p_actor: user.email,
    p_reason: p.reason || null,
    p_operation_id: operationId
  }));
```

**لا تستخدم `sb.rpc` بخدمة Service Role لهذه العمليات.** جميع هذه الدوال تعتمد على `auth.uid()` وصلاحية المستخدم؛ يجب أن يصل JWT الأصلي عبر `profileClient`.

---

## 2. فروق واجهة Buyer المطلوبة

### 2.1 لوحة اليوم

استبدل زر «فاتورة شراء مسودة» بزرين واضحين:
- «إنشاء فاتورة PO» يستدعي `createPurchaseInvoice()`.
- «شراء سوق سريع» يستدعي `quickPurchase()`.

### 2.2 نموذج فاتورة PO

في `createPurchaseInvoice`:
- عند إنشاء مستند جديد، يلزم اختيار PO؛ لا تقبل قيمة فارغة.
- عند تعديل فاتورة جديدة موسومة `PURCHASE_ORDER` استدعِ `UPDATE_PO_INVOICE`.
- فاتورة تاريخية `LEGACY_UNCLASSIFIED` تبقى على مسار `UPDATE_DRAFT_INVOICE` القديم حتى لا نعيد تصنيف التاريخ من الواجهة.
- لا تسمح بتحويل فاتورة Quick Market إلى PO أو العكس من خلال التعديل.
- لا تعدّل دلالة الترحيل أو الاستلام في Buyer.

### 2.3 معرف العملية وإعادة المحاولة

في `quickPurchase`:
- أنشئ `var operationId=buyerOperationId();` مرة واحدة قبل فتح نافذة التأكيد.
- أعد استخدام `operationId` نفسه عند تكرار المحاولة داخل نافذة واحدة بعد فشل الشبكة أو ظهور رسالة تحقق.
- لا تنشئ معرفًا جديدًا داخل كل استدعاء `preConfirm`.
- عند بدء عملية جديدة من نافذة جديدة، أنشئ معرفًا جديدًا.
- لا تستخدم بصمة الأصناف وحدها كمفتاح idempotency؛ فقد تكون هناك مشتريات مستقلة متطابقة.

### 2.4 إثبات تسليم المورد إلى Buyer

أضف طريقة مستقلة داخل كائن التطبيق:

```javascript
registerQuickMarketHandover:async function(invoiceId){
    try{
        var progress=await this.api('GET_QUICK_MARKET_HANDOVER_PROGRESS',{invoice_id:invoiceId});
        var lines=Array.isArray(progress.lines)?progress.lines:[];
        if(!lines.length)throw new Error('لا توجد بنود قابلة لإثبات الحيازة');
        var available=lines.filter(function(x){return Number(x.remaining_qty)>0;});
        if(!available.length)throw new Error('تم إثبات كامل كميات الفاتورة في عهدة البضاعة');
        var operationId=buyerOperationId();
        var html='<div dir="rtl" class="text-right space-y-3"><p class="text-xs text-slate-600">أثبت الكميات التي تسلمتها فعليًا من المورد. لا يؤثر هذا الإجراء على مخزون الفرع أو حساب المورد.</p>';
        html+='<div class="space-y-2">'+available.map(function(x,i){
            return '<div class="grid grid-cols-12 gap-2 items-center border-b pb-2">'+
              '<div class="col-span-6"><b>'+buyerEsc(x.item_name)+'</b><small class="block text-slate-400">'+buyerEsc(x.item_code)+'</small>'+
              '<small class="block text-slate-500">المتبقي غير المثبت: '+buyerEsc(x.remaining_qty)+' '+buyerEsc(x.unit)+'</small></div>'+
              '<input data-handover="'+i+'" class="col-span-6 border rounded-lg p-2" type="number" min="0" max="'+Number(x.remaining_qty)+'" step="0.0001" value="0" data-item-code="'+buyerEsc(x.item_code)+'" data-max="'+Number(x.remaining_qty)+'">'+
              '</div>';
        }).join('')+'</div>'+
        '<label class="block text-xs font-bold">ملاحظات / رقم إيصال المورد<input id="bgh-notes" class="w-full border rounded-xl p-3 mt-1" placeholder="مرجع إثبات التسليم"></label>'+
        '<p class="text-[11px] text-slate-500">المركبة اختيارية؛ يمكن إتمام التسليم دون اختيار مركبة.</p></div>';
        var result=await Swal.fire({
            title:'إثبات استلام البضاعة من المورد',
            html:html,width:760,showCancelButton:true,
            confirmButtonText:'تسجيل الحيازة',cancelButtonText:'إلغاء',
            preConfirm:async function(){
                var items=[];
                Array.from(Swal.getHtmlContainer().querySelectorAll('[data-handover]')).forEach(function(el){
                    var qty=Number(el.value||0),max=Number(el.dataset.max||0);
                    if(!Number.isFinite(qty)||qty<0||qty>max){
                        throw new Error('الكمية المدخلة تتجاوز المتبقي للصنف '+el.dataset.itemCode);
                    }
                    if(qty>0)items.push({item_code:el.dataset.itemCode,qty:qty});
                });
                if(!items.length){
                    Swal.showValidationMessage('أدخل كمية موجبة لصنف واحد على الأقل');
                    return false;
                }
                try{
                    return await App.api('REGISTER_GOODS_HANDOVER',{
                        invoice_id:invoiceId,vehicle_id:null,items:items,
                        evidence_path:null,
                        notes:RW_UI.byId('bgh-notes').value.trim()||null,
                        operation_id:operationId
                    });
                }catch(e){
                    Swal.showValidationMessage(e.message);
                    return false;
                }
            }
        });
        if(result.isConfirmed){
            this.invalidate();
            RW_UI.toast('تم تسجيل حيازة البضاعة؛ لم يتغير مخزون الفرع أو حساب المورد','success');
            await this.renderVehicleBalance();
        }
    }catch(e){this.notifyError(e);}
},
```

ملاحظة مراجعة: `Swal.getHtmlContainer()` متاح في إصدار SweetAlert2 الحالي الذي تستخدمه الصفحة؛ يجب التحقق منه في اختبار المتصفح قبل اعتماد التغيير.

### 2.5 ربط التفاصيل

في `openInvoice(id)`:
- عند الفاتورة `QUICK_MARKET`، زر التعديل يستدعي `quickPurchase(id)`.
- عند `PURCHASE_ORDER` يستدعي `createPurchaseInvoice(id)`.
- عند `LEGACY_UNCLASSIFIED` يبقى المسار التاريخي الحالي.
- زر إثبات الحيازة يظهر فقط لمُنشئ الفاتورة عندما تكون Draft وغير ملغاة وتوجد كميات متبقية من استدعاء `GET_QUICK_MARKET_HANDOVER_PROGRESS`.
- لا تعرض زر ترحيل Quick Market من Buyer.
- لا تعرض زر حذف عام لـ Quick Market؛ استدعِ `DELETE_QUICK_MARKET_DRAFT` من طريقة الحذف بعد التأكد من نوع المصدر.

### 2.6 حذف المسودة

في `deleteDraftInvoice(id)`:
- اقرأ بيانات الفاتورة.
- إن كان `purchase_source==='QUICK_MARKET'`، استدعِ `DELETE_QUICK_MARKET_DRAFT`.
- إن كان `PURCHASE_ORDER`، استدعِ `DELETE_DRAFT_INVOICE` بعد التحقق من عدم وجود استلام أو مصروف.
- إن كان `LEGACY_UNCLASSIFIED`، احتفظ بالمسار التاريخي الحالي.
- لا تسمح بالحذف بعد أي حدث حيازة أو استلام أو مصروف أو مستند مرتجع.

### 2.7 إخفاء آخر تكلفة من البحث

في `renderQuickSearch` احذف بالكامل:
- متغير `currency` غير المستخدم.
- النص «آخر تكلفة مرجعية».
- أي عرض لقيمة `items.cost_price`.

تبقى نتيجة البحث: الاسم، كود الصنف، الباركود، الوحدة فقط. السعر الفعلي يُدخل يدويًا في نموذج الفاتورة.

### 2.8 «فواتيري»

- المستخدم يرى افتراضيًا الفواتير ذات `purchaser_user_id===currentUser.id`.
- للفواتير القديمة فقط التي لا تملك `purchaser_user_id`، استخدم مطابقة `created_by` مع بريد المستخدم.
- المالك/المالية المخولة يمكنها اختيار عرض الشركة بالكامل.
- لا تجعل عرض الشركة هو الوضع الافتراضي للمشتري.
- أظهر المصدر: PO / Quick Market / قديم غير مصنف.
- أظهر مصدر التسوية وحالة الاستلام وحالة التسوية من أعمدة المصدر، ولا تستنتجها من حالة النص وحدها.

### 2.9 رصيد عهدة البضاعة

استبدل الصفحة الثابتة في `renderVehicleBalance` باستدعاء:
```javascript
var result=await this.api('GET_GOODS_CUSTODY',{});
var balances=Array.isArray(result.balances)?result.balances:[];
var events=Array.isArray(result.events)?result.events:[];
```
واعرض:
- الرصيد حسب الصنف والفرع.
- إجمالي الحيازة الحالية.
- آخر الأحداث، والفاتورة ورقم المورد، والكمية.
- لا تعرض المركبة باعتبارها شرطًا أو مفتاح الرصيد.
- لا تجمع مخزون الموظف مع `stock_branches` أو مخزون سيارات التوصيل.

### 2.10 المتاح من العهدة النقدية

تُخصم فواتير Quick Market المسودة المرتبطة بالعهدة من «المتاح» في:
- `renderToday`.
- `renderCustody`.
- نافذة `quickPurchase`.

الصيغة المفاهيمية:
`المتاح = النقد المؤكد الاستلام - المصروفات Submitted/Approved - حجوزات فواتير Quick Market Draft غير المسواة`.

في `renderToday` و`renderCustody` يجب حساب الحجوزات من `purchase_invoices` التي تحقق جميع الشروط:
```javascript
purchase_source === 'QUICK_MARKET'
settlement_source === 'EMPLOYEE_CUSTODY'
cash_custody_id === custody.id
status === 'Draft'
settlement_status === 'UNSETTLED'
```
ثم طرح مجموع `total_amount` من رصيد النقد المؤكد بعد استبعاد الفاتورة الحالية عند تعديلها. لا تخصم فواتير المورد الآجلة أو الفواتير التاريخية غير المصنفة. يجب استخدام نفس العملة فقط، ويظل فحص SQL هو مصدر الحسم عند الحفظ؛ العرض الأمامي للتنبيه فقط.

لا تُخصم فاتورة PO الآجلة من عهدة نقدية لمجرد أنها موجودة. ولا يُسمح للحسابات أن تجمع عملات مختلفة.

---

## 3. حدود المرحلة الأولى

- لا تعديل في `receiver.html` أو `main.html` أو `core.js`.
- لا استلام مخزني من Buyer.
- لا زيادة `stock_branches` أو كتابة `inventory_log` من Quick Market.
- لا دائن مورد أو قيد عام عند إنشاء الفاتورة أو تسلم البضاعة لدى Buyer.
- لا مسار Quick Market في مراجعة مصروف العهدة إلى أن يتوافر استلام Receiver مرتبط بالفاتورة وبنودها.
- لا SupplierReturn في هذه الحزمة.
- لا تصنيف أو تحويل للفواتير التاريخية.
- لا اختبار بإنشاء بيانات دائمة في Production.

## 4. قائمة التحقق قبل إدخال هذه الفروق إلى المصدر التشغيلي

1. Migration / RPC / Edge / Buyer تُراجع معًا كحزمة واحدة.
2. لا توجد أسماء عمليات مكررة أو متداخلة مع `CREATE_INVOICE` و`UPDATE_DRAFT_INVOICE` القديمتين.
3. جميع RPCs التي تستخدم `auth.uid()` تستقبل JWT الأصلي.
4. لا تُمنح صلاحيات DML مباشرة على دفتر الأحداث.
5. تعمل إعادة المحاولة بنفس `operation_id` دون تكرار، ويرفض المفتاح بمحتوى مختلف.
6. السعر الفعلي مطلوب، و`cost_price` غير ظاهر.
7. لا أثر للمخزون أو المورد أو الخزينة قبل Receiver.
8. «المتاح» يخصم الحجوزات النقدية ولا يسمح بتجاوز العهدة.
9. فواتير PO الجديدة موسومة، والفواتير القديمة غير المصنفة لا يُعاد تصنيفها آليًا.
10. بعد التطبيق: قراءة مصدر GitHub، ثم نشر Cloudflare، ثم اختبار مصادق عليه، ثم مطابقة قاعدة البيانات والأثر التجاري.

