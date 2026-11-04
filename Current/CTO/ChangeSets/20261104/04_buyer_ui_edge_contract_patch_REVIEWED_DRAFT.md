# RAWAEA ERP — Buyer Phase 1
# فروق واجهة Buyer ومدخل Edge المركزي — مراجعة تنفيذية

**الحالة:** مسودة تغيير للمراجعة قبل التطبيق  
**الملف التشغيلي المستهدف الوحيد في هذه المرحلة:** `companies/company-1/purchasing/buyer.html`  
**مدخل Edge القائم:** `save-purchase-order` — الإصدار الحي 22  
**لا يُنشأ Edge Function جديد، ولا يتغير النظام الأم أو Core أو Receiver.**

---

## 1. نتيجة فحص المصدر الحالي

| موضع المصدر | الوضع الحالي | التغيير المطلوب |
|---|---|---|
| `renderToday` — بداية الطريقة عند السطر 370 | زر واحد ينشئ مسودة فاتورة عامة | فصل «فاتورة PO» عن «شراء سوق سريع» |
| `renderInvoices` — السطر 560 | يعرض سجل الشركة كاملًا لكل مستخدم | الافتراضي فواتير المستخدم الحالي؛ المالية المخولة فقط ترى الكل |
| `openInvoice` — السطر 612 | تعديل أي مسودة عبر النموذج العام | توجيه مسودة QUICK_MARKET إلى نموذج Quick Market الخاص |
| `deleteDraftInvoice` — السطر 630 | حذف عام | حذف Quick Market عبر وظيفة تتحقق من عدم وجود حدث حيازة أو استلام أو مصروف تابع |
| `renderVehicleBalance` — السطر 694 | رسالة ثابتة بأن الدفتر غير منشأ | عرض رصيد مشتق من دفتر الأحداث؛ المركبة لا تدخل في تعريف الرصيد |
| `createPurchaseInvoice` — السطر 833 | يسمح بفاتورة جديدة دون PO | فاتورة PO تتطلب PO؛ فاتورة بلا PO تمر عبر Quick Market فقط |
| `quickPurchase` — السطر 895 تقريبًا | مجرد alias لنموذج الفاتورة العامة | نموذج سوق سريع متميز |
| `renderQuickSearch` — السطر 897 | يعرض `items.cost_price` | حذف آخر تكلفة من نتائج البحث كليًا |

بصمة المصدر المعاد فحصه: `311f2673a90149df6f56d59a9a187a3379e6981c`.

## 2. شكل واجهة الشراء السريع المستهدف

يحتوي نموذج Quick Market على:
- مورد نشط من دليل الموردين المركزي فقط.
- فرع إلزامي.
- رقم فاتورة المورد وتاريخ الاستحقاق والملاحظات.
- بحث بالاسم والكود والباركود.
- كمية وسعر شراء فعلي يدوي لكل بند؛ لا يعرض ولا يمرر `cost_price`.
- خصم وضريبة ضمن الحدود المسموح بها في الوظيفة المركزية.
- مصدر التسوية: عهدة نقدية مؤكدة الاستلام أو ائتمان المورد.
- عند اختيار عهدة نقدية: اختيار عهدة مفتوحة تخص مسؤول المشتريات وتعرض المتاح بعد المصروفات والحجوزات القائمة.
- زر الحفظ ينشئ Draft فقط. لا يسجل استلام المورد ولا يغير المخزون أو رصيد المورد أو الخزينة.
- بعد الحفظ يظهر في تفاصيل الفاتورة إجراء مستقل «إثبات استلام البضاعة من المورد إلى عهدتي». هذا الإجراء لا يعمل إلا بعد تأكيد الاستلام الفعلي.

### 2.1 تعليمات تعديل الطريقة `quickPurchase`

استبدل alias الحالي:
```javascript
quickPurchase:function(){return this.createPurchaseInvoice();},
```

بطريقة منفصلة تعتمد على `Swal.fire` والبيانات المركزية الحالية:

```javascript
quickPurchase:async function(invoiceId){
    try{
        await this.loadSystemCurrency();
        var loaded=await Promise.all([
            this.data('suppliers'),this.data('items'),this.data('branches'),
            this.data('purchase_settings'),this.data('purchase_invoices'),
            this.data('purchase_invoice_details'),this.api('GET_CUSTODY',{})
        ]);
        var suppliers=loaded[0].filter(function(x){return x.is_active===true;});
        var items=loaded[1],branches=loaded[2],settings=loaded[3][0]||{},
            invoices=loaded[4],details=loaded[5],custodyData=loaded[6]||{},
            current=invoiceId?invoices.find(function(x){return x.id===invoiceId;}):null,
            self=this,selectedItem=null,lines=[];

        if(invoiceId&&(!current||current.purchase_source!=='QUICK_MARKET'||current.status!=='Draft'))
            throw new Error('مسودة Quick Market غير موجودة أو لم تعد قابلة للتعديل');

        var currentSupplier=current&&suppliers.find(function(x){return x.id===current.supplier_id;});
        if(current){
            lines=details.filter(function(x){return x.invoice_id===invoiceId;}).map(function(x){
                return {item_code:x.item_code,name:x.item_name,unit:x.unit,qty:Number(x.qty||0),
                    unit_price:Number(x.unit_price||0),discount_percent:Number(x.discount_percent||0),
                    tax_rate:Number(x.tax_rate||0)};
            });
        }

        var me=this.currentUser||{},custodies=(custodyData.custodies||[]).filter(function(c){
            return c.employee_id===me.id&&['Issued','UnderReview'].indexOf(c.status)!==-1&&!!c.acknowledged_at;
        });
        var advances=custodyData.advances||[],expenses=custodyData.expenses||[];
        var availableByCustody={};
        custodies.forEach(function(c){
            var acknowledged=advances.filter(function(a){return a.custody_id===c.id&&!!a.acknowledged_at;})
                .reduce(function(n,a){return n+Number(a.amount||0);},0);
            var committed=expenses.filter(function(e){return e.custody_id===c.id&&['Submitted','Approved'].indexOf(e.status)!==-1;})
                .reduce(function(n,e){return n+Number(e.amount||0);},0);
            var reserved=invoices.filter(function(i){
                return i.id!==(current&&current.id)&&i.cash_custody_id===c.id&&
                    i.purchase_source==='QUICK_MARKET'&&i.status==='Draft'&&i.settlement_status==='UNSETTLED';
            }).reduce(function(n,i){return n+Number(i.total_amount||0);},0);
            availableByCustody[c.id]=Math.max(0,acknowledged-committed-reserved);
        });
        custodies=custodies.filter(function(c){return availableByCustody[c.id]>0;});

        var defaultSettlement=current?current.settlement_source:(custodies.length?'EMPLOYEE_CUSTODY':'SUPPLIER_CREDIT');
        var defaultCustody=current&&current.cash_custody_id?current.cash_custody_id:(custodies[0]&&custodies[0].id||'');
        var html='<div dir="rtl" class="text-right space-y-4">'+
          '<div class="rounded-xl bg-purple-50 border border-purple-100 p-4"><b>شراء سوق سريع — دون أمر شراء</b>'+
          '<p class="text-xs text-slate-600 mt-1">فاتورة Draft، ثم إثبات مستقل لاستلام المورد إلى عهدتك. لا تدخل البضاعة مخزون الفرع من هذه الشاشة.</p></div>'+
          '<div class="grid grid-cols-1 md:grid-cols-2 gap-3">'+
          '<label class="text-xs font-bold">المورد المعتمد<select id="qmp-supplier" class="w-full border rounded-xl p-3 mt-1">'+
          '<option value="">اختر المورد</option>'+suppliers.map(function(x){
            return '<option value="'+buyerEsc(x.id)+'" '+(current&&current.supplier_id===x.id?'selected':'')+'>'+buyerEsc(x.name)+' · '+buyerEsc(x.supplier_code||'')+'</option>';
          }).join('')+'</select></label>'+
          '<label class="text-xs font-bold">فرع التوريد<select id="qmp-branch" class="w-full border rounded-xl p-3 mt-1"><option value="">اختر الفرع</option>'+
          branches.map(function(x){return '<option value="'+buyerEsc(x.id)+'" '+((current?current.branch_id===x.id:settings.default_branch_id===x.id)?'selected':'')+'>'+buyerEsc(x.name)+'</option>';}).join('')+
          '</select></label>'+
          '<label class="text-xs font-bold">رقم فاتورة المورد<input id="qmp-no" class="w-full border rounded-xl p-3 mt-1" value="'+buyerEsc(current&&current.supplier_invoice_no||'')+'"></label>'+
          '<label class="text-xs font-bold">تاريخ الاستحقاق<input id="qmp-due" type="date" class="w-full border rounded-xl p-3 mt-1" value="'+buyerEsc(current&&current.due_date||'')+'"></label>'+
          '<label class="text-xs font-bold">مصدر التسوية<select id="qmp-settlement" class="w-full border rounded-xl p-3 mt-1">'+
          '<option value="EMPLOYEE_CUSTODY" '+(defaultSettlement==='EMPLOYEE_CUSTODY'?'selected':'')+'>عهدتي النقدية</option>'+
          '<option value="SUPPLIER_CREDIT" '+(defaultSettlement==='SUPPLIER_CREDIT'?'selected':'')+'>ائتمان المورد</option></select></label>'+
          '<label id="qmp-custody-wrap" class="text-xs font-bold">العهدة النقدية<select id="qmp-custody" class="w-full border rounded-xl p-3 mt-1">'+
          '<option value="">اختر عهدة مؤكدة الاستلام</option>'+custodies.map(function(c){
            return '<option value="'+buyerEsc(c.id)+'" '+(defaultCustody===c.id?'selected':'')+'>'+buyerEsc(c.custody_code)+' · متاح '+buyerMoney(availableByCustody[c.id],c.currency)+'</option>';
          }).join('')+'</select></label></div>'+
          '<div class="rounded-xl border p-3"><div class="grid grid-cols-1 md:grid-cols-[1fr_110px_auto] gap-2 items-end">'+
          '<label class="text-xs font-bold">بحث صنف بالاسم أو الكود أو الباركود<input id="qmp-search" class="w-full border rounded-xl p-3 mt-1" placeholder="ابحث عن الصنف"></label>'+
          '<label class="text-xs font-bold">كمية<input id="qmp-qty" class="w-full border rounded-xl p-3 mt-1" type="number" min="0.001" step="0.001" value="1"></label>'+
          '<button id="qmp-add" type="button" class="px-4 py-3 rounded-xl bg-slate-800 text-white font-bold">إضافة الصنف</button></div>'+
          '<div id="qmp-results" class="max-h-48 overflow-auto"></div><div id="qmp-lines" class="mt-3"></div></div>'+
          '<label class="text-xs font-bold">ملاحظات<textarea id="qmp-notes" class="w-full border rounded-xl p-3 mt-1" rows="2">'+buyerEsc(current&&current.notes||'')+'</textarea></label>'+
          '<p class="text-[11px] text-slate-500">عملة الفاتورة: '+buyerEsc(this.currency)+'. السعر الفعلي يُدخل يدويًا. لن تستخدم آخر تكلفة الصنف كسعر افتراضي.</p></div>';

        function renderLines(){
            var host=RW_UI.byId('qmp-lines');if(!host)return;
            if(!lines.length){host.innerHTML='<p class="text-xs text-slate-400 py-3">أضف الأصناف أولًا.</p>';return;}
            var total=0,h='<div class="overflow-auto"><table class="w-full text-xs"><thead><tr><th class="p-2 text-right">الصنف</th><th>الكمية</th><th>السعر الفعلي</th><th>خصم %</th><th>ضريبة %</th><th>الإجمالي</th><th></th></tr></thead><tbody>';
            lines.forEach(function(x,i){
                var amount=Number(x.qty)*Number(x.unit_price)*(1-Number(x.discount_percent||0)/100)*(1+Number(x.tax_rate||0)/100);
                total+=amount;
                h+='<tr class="border-t"><td class="p-2"><b>'+buyerEsc(x.name)+'</b><small class="block text-slate-400">'+buyerEsc(x.item_code)+'</small></td>'+
                  '<td><input data-qmp="qty" data-i="'+i+'" type="number" min="0.001" step="0.001" value="'+x.qty+'" class="w-20 border rounded p-2"></td>'+
                  '<td><input data-qmp="unit_price" data-i="'+i+'" type="number" min="0.01" step="0.01" value="'+(x.unit_price==null?'':x.unit_price)+'" class="w-24 border rounded p-2"></td>'+
                  '<td><input data-qmp="discount_percent" data-i="'+i+'" type="number" min="0" max="100" step="0.01" value="'+x.discount_percent+'" class="w-16 border rounded p-2"></td>'+
                  '<td><input data-qmp="tax_rate" data-i="'+i+'" type="number" min="0" max="100" step="0.01" value="'+x.tax_rate+'" class="w-16 border rounded p-2"></td>'+
                  '<td class="font-bold">'+buyerMoney(amount,self.currency)+'</td>'+
                  '<td><button data-qmp-remove="'+i+'" type="button" class="text-red-600">حذف</button></td></tr>';
            });
            h+='</tbody></table><div class="text-left font-black p-2">الإجمالي: '+buyerMoney(total,self.currency)+'</div></div>';
            host.innerHTML=h;
            Array.from(host.querySelectorAll('[data-qmp]')).forEach(function(el){
                el.addEventListener('change',function(){
                    lines[Number(el.dataset.i)][el.dataset.qmp]=el.value===''?null:Number(el.value);renderLines();
                });
            });
            Array.from(host.querySelectorAll('[data-qmp-remove]')).forEach(function(el){
                el.addEventListener('click',function(){lines.splice(Number(el.dataset.qmpRemove),1);renderLines();});
            });
        }

        var modal=await Swal.fire({
            title:current?'تعديل مسودة Quick Market':'شراء سوق سريع جديد',
            html:html,width:1000,showCancelButton:true,confirmButtonText:'حفظ مسودة الفاتورة',
            cancelButtonText:'إلغاء',
            didOpen:function(){
                var search=RW_UI.byId('qmp-search'),results=RW_UI.byId('qmp-results');
                search.addEventListener('input',function(){
                    var q=this.value.trim().toLowerCase();
                    var found=items.filter(function(it){
                        return [it.name,it.item_code,it.barcode].join(' ').toLowerCase().indexOf(q)!==-1;
                    }).slice(0,15);
                    results.innerHTML=found.map(function(it,i){
                        return '<button type="button" data-qmp-item="'+i+'" class="block w-full text-right p-2 border-b"><b>'+
                            buyerEsc(it.name)+'</b><small class="block text-slate-400">'+buyerEsc(it.item_code)+' · '+buyerEsc(it.barcode||'')+'</small></button>';
                    }).join('');
                    Array.from(results.querySelectorAll('[data-qmp-item]')).forEach(function(btn){
                        btn.addEventListener('click',function(){
                            selectedItem=found[Number(btn.dataset.qmpItem)];
                            search.value=selectedItem.item_code+' — '+selectedItem.name;
                            results.innerHTML='';
                        });
                    });
                });
                RW_UI.byId('qmp-add').addEventListener('click',function(){
                    if(!selectedItem){Swal.showValidationMessage('اختر صنفًا من نتائج البحث');return;}
                    var qty=Number(RW_UI.byId('qmp-qty').value||0);
                    if(qty<=0){Swal.showValidationMessage('أدخل كمية موجبة');return;}
                    var old=lines.find(function(x){return x.item_code===selectedItem.item_code;});
                    if(old)old.qty=Number(old.qty)+qty;
                    else lines.push({item_code:selectedItem.item_code,name:selectedItem.name,unit:selectedItem.unit,
                        qty:qty,unit_price:null,discount_percent:0,tax_rate:0});
                    selectedItem=null;search.value='';RW_UI.byId('qmp-qty').value='1';renderLines();
                });
                RW_UI.byId('qmp-settlement').addEventListener('change',function(){
                    RW_UI.byId('qmp-custody-wrap').classList.toggle('hidden',this.value!=='EMPLOYEE_CUSTODY');
                });
                RW_UI.byId('qmp-custody-wrap').classList.toggle('hidden',RW_UI.byId('qmp-settlement').value!=='EMPLOYEE_CUSTODY');
                renderLines();
            },
            preConfirm:async function(){
                var supplierId=RW_UI.byId('qmp-supplier').value,branchId=RW_UI.byId('qmp-branch').value,
                    settlement=RW_UI.byId('qmp-settlement').value,custodyId=settlement==='EMPLOYEE_CUSTODY'?RW_UI.byId('qmp-custody').value:null;
                if(!supplierId||!branchId||!lines.length){Swal.showValidationMessage('اختر المورد والفرع وأضف بندًا واحدًا على الأقل');return false;}
                if(settlement==='EMPLOYEE_CUSTODY'&&!custodyId){Swal.showValidationMessage('اختر عهدة نقدية مؤكدة الاستلام أو غيّر مصدر التسوية إلى ائتمان المورد');return false;}
                for(var i=0;i<lines.length;i++){
                    if(!Number.isFinite(Number(lines[i].qty))||Number(lines[i].qty)<=0||
                       !Number.isFinite(Number(lines[i].unit_price))||Number(lines[i].unit_price)<=0){
                        Swal.showValidationMessage('يجب إدخال سعر فعلي أكبر من صفر وكمية موجبة لكل صنف');return false;
                    }
                }
                var payload={supplier_id:supplierId,branch_id:branchId,due_date:RW_UI.byId('qmp-due').value||null,
                    supplier_invoice_no:RW_UI.byId('qmp-no').value.trim()||null,
                    notes:RW_UI.byId('qmp-notes').value.trim()||null,
                    settlement_source:settlement,cash_custody_id:custodyId,
                    items:lines.map(function(x){return {item_code:x.item_code,qty:x.qty,unit_price:x.unit_price,
                        discount_percent:x.discount_percent,tax_rate:x.tax_rate};}),
                    operation_id:buyerOperationId()};
                if(invoiceId)payload.invoice_id=invoiceId;
                try{return await self.api(invoiceId?'UPDATE_QUICK_MARKET_INVOICE':'CREATE_QUICK_MARKET_INVOICE',payload);}
                catch(e){Swal.showValidationMessage(e.message);return false;}
            }
        });
        if(modal.isConfirmed){
            this.invalidate();RW_UI.toast('تم حفظ مسودة Quick Market دون أثر مخزني أو مالي','success');
            await this.renderInvoices();
        }
    }catch(e){this.notifyError(e);}
},
```

### 2.2 إجراء استلام المورد إلى عهدة المشتري

أضف الطريقة `registerQuickMarketHandover(invoiceId)` إلى كائن التطبيق:
- تقرأ الفاتورة وبنودها وأحداث `GET_GOODS_CUSTODY`.
- تحسب المتبقي من كمية كل بند بمجموع الأحداث السابقة من النوع `SUPPLIER_TO_BUYER_QUICK_MARKET`.
- تعرض الكميات المتبقية وتسمح بإثبات كمية جزئية.
- المركبة اختيارية؛ تمرر `vehicle_id: null` افتراضيًا إذا لم يختر المستخدم مركبة.
- ترسل `REGISTER_GOODS_HANDOVER` بمعرف عملية جديد.
- لا تستدعي `post_stock_movement` ولا تغير `stock_branches` ولا المورد ولا الخزينة.
- بعد النجاح تعيد تحميل تبويب رصيد البضاعة والفاتورة.

صيغة طلب الوظيفة:
```javascript
await this.api('REGISTER_GOODS_HANDOVER',{
  invoice_id:invoiceId,
  vehicle_id:null,
  items:[{item_code:'...',qty:2.5}],
  evidence_path:null,
  notes:'تسلم فعليًا من المورد',
  operation_id:buyerOperationId()
});
```

ويضاف زر الإجراء داخل `openInvoice` فقط عندما:
- `invoice.purchase_source === 'QUICK_MARKET'`
- `invoice.status === 'Draft'`
- المستخدم هو `invoice.purchaser_user_id`
- ما زالت هناك كمية غير مثبتة في دفتر الحيازة.

### 2.3 تحويل صفحة رصيد البضاعة

استبدل محتوى `renderVehicleBalance` الثابت بقراءة:
```javascript
var data=await this.api('GET_GOODS_CUSTODY',{});
var balances=Array.isArray(data.balances)?data.balances:[];
var events=Array.isArray(data.events)?data.events:[];
```

اعرض الرصيد حسب الصنف والفرع ومسؤول الحيازة، مع آخر الحركات والمستند المصدر. لا تستخدم `vehicles` أو `stock_branches` لإعادة حساب دفتر الحيازة. لا تجمع أرصدة عدة موظفين في بطاقة واحدة للمشتري الحالي.

### 2.4 قائمة «فواتيري»

في `renderInvoices`:
- عرّف `currentUserId` و`currentEmail`.
- الافتراضي: `purchaser_user_id === currentUserId`.
- للسجلات القديمة غير المصنفة فقط، استخدم `created_by` المطابق لبريد المستخدم كحل توافق رجعي.
- يسمح بعرض كل الفواتير فقط للمالك أو المالية المخولة، ولا يكون ذلك هو الوضع الافتراضي.
- أظهر عمود «مصدر الشراء» (PO / Quick Market / قديم غير مصنف) وعمود «مصدر التسوية».
- لا تعرض أي تكلفة معيارية من `items.cost_price`.

### 2.5 فصل نموذج PO

في `createPurchaseInvoice`:
- لا يظهر خيار «بدون أمر شراء» عند إنشاء فاتورة جديدة.
- إذا كانت مسودة تاريخية قديمة بلا PO وتحتاج تعديلًا، تُحفظ إمكانية فتحها فقط من مسار التوافق المحدد؛ لا تستخدمها لإنشاء عملية جديدة.
- قبل الحفظ الجديد: `purchase_order_id` إلزامي.
- يرسل الحفظ `CREATE_INVOICE`، ويحوّل Edge إلى `purchase_create_po_invoice_atomic`.
- فاتورة Quick Market تنشأ حصريًا من `quickPurchase`.

### 2.6 البحث السريع القديم

في `renderQuickSearch` احذف متغير العملة ووسم «آخر تكلفة مرجعية» كاملًا. تعرض النتيجة الاسم والكود والباركود والوحدة فقط.

## 3. تعديلات مدخل Edge الحالي

**الوظيفة:** `save-purchase-order`  
**الإصدار الحالي:** 22  
**البصمة الحالية:** `a0885a8a636b0d57ef9ab54b476001be8e3dd1f4227b921f511b002f58642ffb`

لا يتم إنشاء وظيفة Edge جديدة. تضاف عمليات إلى دالة التوجيه الحالية.

### 3.1 حراسة الصلاحيات

في كتلة الصلاحيات قبل احتساب `operationId`:

```typescript
} else if ([
  "CREATE_QUICK_MARKET_INVOICE",
  "UPDATE_QUICK_MARKET_INVOICE",
  "REGISTER_GOODS_HANDOVER",
  "DELETE_QUICK_MARKET_DRAFT"
].includes(op)) {
  requireAny(["purchases"]);
} else if (op === "GET_GOODS_CUSTODY") {
  requireAny(["purchases", "finance", "finance_manager"]);
}
```

### 3.2 إنشاء فاتورة PO

يستبدل استدعاء `CREATE_INVOICE` الحالي باستدعاء الوظيفة المركزية الجديدة مع JWT المستخدم:

```typescript
} else if (op === "CREATE_INVOICE") {
  if (!p.purchase_order_id) throw new Error("فاتورة الشراء العادية تتطلب أمر شراء PO؛ استخدم Quick Market للمشتريات بلا PO");
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
```

### 3.3 إضافة توجيه عمليات Quick Market والحيازة

```typescript
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
} else if (op === "DELETE_QUICK_MARKET_DRAFT") {
  ({ data, error } = await profileClient.rpc("purchase_delete_quick_market_draft_atomic", {
    p_company_id: companyId,
    p_invoice_id: p.invoice_id,
    p_actor: user.email,
    p_reason: p.reason || null,
    p_operation_id: operationId
  }));
```

كل العمليات التي تعتمد على `auth.uid()` تستعمل `profileClient` الذي يحمل JWT الحقيقي للمستخدم. لا تحولها إلى `sb.rpc` بخدمة Service Role.

### 3.4 الحفاظ على المسارات القائمة

- `CREATE_PO` يبقى عبر `purchase_create_po_atomic`.
- `POST_INVOICE` يبقى خاضعًا لفحص الاستلام المركزي؛ لا تضاف له صلاحية ترحيل Quick Market بلا Receiver.
- `RECEIVE_PO` يبقى كما هو في هذه المرحلة، ولا نعدل Receiver أو `receive_purchase_atomic`.
- وظائف العهدة النقدية الحالية لا تستبدل؛ يضاف فرع Quick Market في مرحلة الاستلام اللاحقة فقط بعد إنشاء روابط استلام فاتورة السوق.
- لا يتغير CORS أو JWT أو طريقة استعادة الملف الشخصي أو وظيفة `GET_DATA` إلا بالقدر اللازم أعلاه.

## 4. مصفوفة الأثر بعد التعديل

| العملية | سجل الفاتورة | دفتر حيازة Buyer | مخزون الفرع | المورد / الأستاذ العام | الخزينة |
|---|---|---|---|---|---|
| إنشاء PO | PO / دون أثر | لا أثر | لا أثر | لا أثر | لا أثر |
| إنشاء Quick Market | Draft / QUICK_MARKET | لا أثر | لا أثر | لا أثر | لا أثر |
| إثبات المورد ← Buyer | لا يرحّل الفاتورة | زيادة الكمية المستلمة فعليًا | لا أثر | لا أثر | لا أثر |
| تعديل مسودة Quick Market قبل الحيازة | تعديل مسودة | لا أثر | لا أثر | لا أثر | لا أثر |
| محاولة حذف Quick Market بعد إثبات الحيازة | رفض | يبقى الحدث الأصلي | لا أثر | لا أثر | لا أثر |
| استلام المخزن | غير منفذ في المرحلة الأولى | سيخصم المقبول في مرحلة Receiver | لا أثر الآن | لا أثر الآن | لا أثر الآن |

## 5. اختبارات واجهة وEdge الإلزامية

1. المورد غير النشط أو المورد من شركة أخرى يُرفض.
2. فرع غير صالح يُرفض.
3. العملة تُقرأ من `app_settings` ولا يقبل RPC قيمة يرسلها المتصفح.
4. إنشاء فاتورة Quick Market لا يقبل PO ولا ينشئ حركة مخزون أو AP أو GL.
5. سعر كل صنف مطلوب يدويًا؛ لا تُقرأ `cost_price` ولا تعرض.
6. لا تُقبل قيمة عهدة نقدية بدون عهدة مفتوحة تخص نفس المستخدم ومؤكدة الاستلام.
7. مجموع المصروفات المعتمدة والمعلقة وحجوزات فواتير Quick Market لا يتجاوز النقدية المؤكدة.
8. إثبات التسليم للمشتري يتطلب فاتورة Quick Market للمستخدم نفسه ورقم فاتورة مورد وفرع.
9. الكمية المسلمة لا تتجاوز كمية الفاتورة بعد جمع أحداث التسليم السابقة.
10. المركبة فارغة وتنجح العملية؛ وجود مركبة لا يغير مفتاح الرصيد.
11. نفس `operation_id` ونفس المحتوى يعيد النتيجة السابقة؛ المفتاح نفسه بمحتوى مختلف يرفض.
12. محاولة تعديل أو حذف الفاتورة بعد وجود حدث حيازة ترفض.
13. مستخدم آخر لا يرى سجل الحيازة الشخصي، والمالية المخولة فقط تستطيع العرض الشامل.
14. فواتير المستخدم الحالي فقط تظهر افتراضيًا في «فواتيري».

## 6. نقاط لا يدخلها هذا التعديل

- واجهة Receiver واستلام PO وفاتورة Quick Market: المرحلة الثانية.
- زيادة مخزون الفرع عند القبول: المرحلة الثانية، داخل معاملة الاستلام المخزني المركزية.
- تسوية مصروف Quick Market وربطها بإذن Receiver: المرحلة الثانية؛ لا يُقبل مستند تسوية بلا مستند استلام فعلي مرتبط بالفاتورة وبنودها.
- SupplierReturn، تفويض المشتري، إيصال المورد والقبول الجزئي: المرحلة الثالثة.
- المستحق المالي للموظف عندما تتجاوز مصروفاته العهدة النقدية: يظل بندًا مفتوحًا حتى تضاف وظيفة حسابية صحيحة لحساب دائن الموظفين. حساب الدليل الحالي لا يحتوي هذا الحساب؛ لا نستخدم حساب 127 كخصم أو دائن بديل ولا ندعي الدفع دون سند.
- لا يجري حذف فواتير الاختبار أو عكسها في هذا التعديل.

---

**الخلاصة:** هذه الفروق تبقي Buyer متصلًا بوظائف النظام المركزية، وتجعل Quick Market عملية مستقلة، وتفصل حيازة الموظف عن مخزون الفرع وعن العهدة النقدية. لا يُنشر ملف Buyer منفردًا قبل نشر SQL والمدخل المركزي في الحزمة نفسها.
