# تقرير 352 — التحقيق الجنائي في HEAD الحالي وإعداد الإغلاق الجراحي لتطبيق الأذونات المخزنية

**التاريخ:** 28 سبتمبر 2026  
**النطاق:** RAWAEA ERP — `companies/company-1/warehouse/vouchers.html`  
**الحالة التنفيذية:** إصلاح المصدر جرى التحقق منه في rehearsal، لكن تطبيقه على الملف نفسه متروك للمستخدم تنفيذًا للتوجيه بعدم تعديل الملف مباشرة من هذه الجلسة.

---

## 1. نقطة الاستئناف

تم الاستئناف من آخر حالة مثبتة، ثم تمت مطابقة الحالة مع Current Git وCurrent Source وCurrent Production وCurrent Database وأدلة النشر المتاحة.

### Current Git

| المصدر | القيمة |
|---|---|
| System HEAD | `6e73a63254f44b1fe796ba5fdcc2ceb8582cbc1e` |
| System parent | `71befda98e7425877280ba40bb5eef411ee3aad2` |
| Frontend HEAD | `f5c9b877d973d42c2c3f4f2671a94924cf37f0d1` |
| Frontend parent | `f07bdcc4abbbe899af569f8bfaccde04df279416` |
| Target blob | `90426dea29a20fbd292f3de9731b521bdae9c5e2` |

تمت مراجعة حتى النهاية:
- `MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`
- `Report350_WAREHOUSE_VOUCHERS_FORENSIC_CLOSURE_20260928.md`
- `Report351_WAREHOUSE_VOUCHERS_FORENSIC_SOURCE_CONTRACT_AND_CURRENT_UI_CLOSURE_20260928.md`
- `CURRENT_STATE.md`

التقارير تاريخ مرجعي فقط، والحكم الحالي من المصادر الحالية.

---

## 2. السبب الجذري المثبت

آخر Frontend commit حذف/أعاد تركيب أجزاء في `vouchers.html` بصورة غير متماسكة.

### T13 — سبب Console الحالي

عند line **1286** يوجد:

`function durationText(sec){...}`

خارج موضعه الصحيح، بعد إغلاق تنفيذ `cards()`، مع وجود تنفيذ ثانٍ قديم لـ`cards()`.

هذا هو السبب المباشر لـ:

`Unexpected identifier 'durationText'`

### T14 — Runtime بعد إزالة T13

داخل `details()`:
- `topActions` يُغلق.
- HTML التفاصيل يأتي كسلسلة مستقلة.
- لاحقًا يتم تمرير `html:h`.

لكن `var h=` اختفى.

إذن بعد إصلاح syntax ستظهر:

`ReferenceError: h is not defined`

### T15 — Syntax ثانوي يظهر بعد T13

في `receive(code,full)`:
`if(full===true){`

لا يتم إغلاق الشرط بعد `Swal.fire(...)`.

ولهذا يظهر بعد T13:

`Unexpected token ')'`

### T16 — Regression مرتبط بتكامل المركبات

الـHEAD حذف:

`vehicleBranch:function(v){...}`

مع بقاء **9 استدعاءات** للدالة داخل الملف.

والتنفيذ الصحيح موجود بالفعل في parent commit `f07bdcc4abbbe899af569f8bfaccde04df279416`.

---

# 3. ما هو صحيح بالفعل ولا يعاد إصلاحه

لا تعاد:
- T-09
- T-10
- T-11
- exact receiver binding
- source responsibility
- supplier return contract
- Owner wildcard
- RPC/Edge contracts القائمة
- فصل `vouchers.html` عن `van-sales.html`

هذه النقاط مثبتة في Current Source/Production.

---

# 4. الدور المعماري

## النظام الأم

`main.html` هو المصدر الأب والسلطة المركزية لإدارة:
المستخدمين، الأدوار، الوظائف، الفروع، المخازن، المركبات، المناديب، الموردين، ونطاق المسؤولية.

**لم يتم لمس `main.html`.**

## vouchers.html

التطبيق التنفيذي للحركات اليدوية غير المرتبطة مباشرة بدورة Order/Runsheet:

- Transfer — فرع → فرع
- DirectSale — فرع → مركبة
- DirectReturn — مركبة → فرع
- SupplierReturn — فرع → مورد

## van-sales.html

التطبيق الميداني للبيع النهائي:

`Vehicle Stock → Customer Sale`

ويعتمد على المسار الحالي `save-sales-invoice` مع `operation_id`.

لذلك:
**DirectSale ليس فاتورة عميل.**
هو تسليم مخزون عهدة إلى المركبة.

---

# 5. Production / Supabase

تم التحقق من المسار الموجود:

- `create-stock-voucher`
- `send-stock-voucher`
- `receive-stock-voucher`
- `complete-stock-voucher`

والـRPCs الحالية:
- `create_manual_stock_voucher_atomic`
- `post_manual_stock_voucher_atomic`
- `send_stock_voucher_atomic`
- `complete_manual_stock_voucher_atomic`
- `delete_manual_stock_voucher_atomic`
- `enforce_transfer_responsibility_contract`
- `inventory_voucher_stock_context`

**لم يثبت أي نقص Production يستدعي إنشاء Edge Function جديدة.**

---

# 6. اختبار Production

تم إنشاء ثم حذف مسودة عبر الـRPC الحالي لكل نوع:

| العملية | النتيجة |
|---|---|
| Transfer | PASS |
| DirectSale | PASS |
| DirectReturn | PASS |
| SupplierReturn | PASS |

وبعد التنظيف:

- temporary voucher rows = 0
- inventory_log residue = 0
- Manual vouchers = 5
- Completed = 5
- Draft = 0
- Sent = 0
- Received = 0

لا توجد بيانات QA عابرة متبقية من الاختبار الجديد.

---

# 7. التقييم التنافسي المختصر

الهيكل الحالي أقوى من مجرد نموذج حركة بسيط لأنه يملك دورة تشغيلية مستقلة، مسؤول استلام، lifecycle، audit، stock context، ومخزن سيارة canonical.

الفجوات اللاحقة التي يمكن تطويرها دون تغيير هذا الهيكل:
- Transit/In-transit KPI صريح.
- Planned ship/receive وlead time.
- Bin/location hierarchy.
- Lot/serial/expiry/package.
- Batch/import.
- تقارير move history وwarehouse metrics أعمق.
- PDF/barcode operation documents.
- Evidence attachments للعقد.

هذه **Backlog لاحق** وليست إصلاح HEAD الحالي.

مراجع:
- Odoo: https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/inventory_valuation/operations_valuation.html
- Odoo Barcode: https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/barcode/operations.html
- Odoo Move History: https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/reporting/moves_history.html
- Odoo Dashboards: https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/reporting/dashboards.html
- Dynamics: https://learn.microsoft.com/en-us/dynamics365/supply-chain/warehousing/transfer-orders-warehouse
- Dynamics Receiving: https://learn.microsoft.com/en-us/dynamics365/supply-chain/warehousing/configure-transfer-order-receiving-process
- Daftra: https://docs.daftra.com/en/user_manual/transferring-items-from-one-warehouse-to-another/
- Manager.io: https://www2.manager.io/guides/10707
- SAP Help: https://help.sap.com/

---

# 8. التعديل الجراحي T13

### الملف المطلوب تعديله
`companies/company-1/warehouse/vouchers.html`

### ابحث تحديدًا عن
`cards:function(rows,scope){`

البداية الحالية: **line 968**

### احذف كاملًا
من `cards:function(rows,scope){` حتى **قبل**:

`loc:function(id,type){`

### استبدل العنصر كاملًا بهذا

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
},,
~~~

هذا هو تنفيذ `cards()` الحالي الصحيح فقط، ويزيل في نفس الوقت الـorphan `durationText()` والنسخة القديمة المكررة.

---

# 9. التعديل الجراحي T14

### داخل
`details:function(code){`

### ابحث تحديدًا عن
~~~javascript
topActions+=
    '</div>';
~~~

البداية الحالية: **line 2438**

### احذف
من هذه العبارة حتى **قبل**:

~~~javascript
Swal.fire({
    title:'تفاصيل الإذن '+s.esc(code),
~~~

### استبدل الكتلة كاملة بهذا

~~~javascript
topActions+=
    '</div>';

var h=
    topActions+
            '<div class="grid grid-cols-2 gap-2 text-xs mb-3">'+
            '<div class="p-3 bg-slate-50 rounded-2xl">النوع<br><b>'+s.esc(v.type)+'</b></div>'+
            '<div class="p-3 bg-slate-50 rounded-2xl">الحالة<br><b>'+s.esc(v.status)+'</b></div>'+
            '<div class="p-3 bg-slate-50 rounded-2xl">المصدر<br><b>'+s.esc(s.loc(v.from_id,v.from_type))+'</b></div>'+
            '<div class="p-3 bg-slate-50 rounded-2xl">الوجهة<br><b>'+s.esc(s.loc(v.to_id,v.to_type))+'</b></div>'+
            (
                v.type==='DirectSale'||v.type==='DirectReturn'
                    ?
                    '<div class="p-3 bg-amber-50 border border-amber-100 rounded-2xl">العهدة<br><b>'+s.esc(custodianText)+'</b></div>'+
                    '<div class="p-3 bg-slate-50 rounded-2xl">المركبة<br><b>'+s.esc(vehicleText)+'</b></div>'
                    :
                    ''
            )+
            '<div class="p-3 bg-slate-50 rounded-2xl">أنشأ بواسطة<br><b>'+s.esc(v.created_by||'—')+'</b></div>'+
            '<div class="p-3 bg-slate-50 rounded-2xl">أكمل بواسطة<br><b>'+s.esc(v.completed_by||'—')+'</b></div>'+
            '</div>'+

            '<div class="grid grid-cols-2 md:grid-cols-4 gap-2 mb-3">'+
            '<div class="p-3 rounded-2xl bg-indigo-50 border border-indigo-100 text-xs">إنشاء → إرسال<br><b>'+s.secondsText(kpi.created_to_sent_seconds)+'</b></div>'+
            '<div class="p-3 rounded-2xl bg-blue-50 border border-blue-100 text-xs">إرسال → استلام<br><b>'+s.secondsText(kpi.sent_to_received_seconds)+'</b></div>'+
            '<div class="p-3 rounded-2xl bg-emerald-50 border border-emerald-100 text-xs">استلام → إكمال<br><b>'+s.secondsText(kpi.received_to_completed_seconds)+'</b></div>'+
            '<div class="p-3 rounded-2xl bg-violet-50 border border-violet-100 text-xs">'+
            (kpi.current_age_seconds!==null&&kpi.current_age_seconds!==undefined
                ?'العمر الحالي'
                :'كامل الدورة')+
            '<br><b>'+s.secondsText(
                kpi.current_age_seconds!==null&&kpi.current_age_seconds!==undefined
                    ?kpi.current_age_seconds
                    :kpi.created_to_completed_seconds
            )+'</b></div>'+
            '</div>'+

            '<div class="mb-3 text-xs text-slate-500">'+
            'المرجع: '+s.esc(v.reference||'—')+
            '<br>الإنشاء: '+s.esc(v.created_at||'—')+
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
                    '<td class="p-3">'+s.esc(x.item_name||x.item_code)+'</td>'+
                    '<td class="p-3 text-center">'+f(x.qty)+'</td>'+
                    '<td class="p-3 text-center">'+f(x.received_qty)+'</td>'+
                    '<td class="p-3 text-center">'+
                    f(Math.max(0,Number(x.qty||0)-Number(x.received_qty||0)))+
                    '</td>'+
                    '</tr>'
                );
            }).join('')+
            '</tbody>'+
            '</table>'+
            '</div>'+

            '<div class="mt-4 border rounded-2xl overflow-auto">'+
            '<div class="p-3 bg-slate-100 font-black text-sm">الحركات الفعلية + الرصيد قبل/بعد</div>'+
            '<table class="w-full text-sm">'+
            '<thead class="bg-slate-50">'+
            '<tr>'+
            '<th class="p-2">الصنف</th>'+
            '<th class="p-2">الحركة</th>'+
            '<th class="p-2">الكمية</th>'+
            '<th class="p-2">المصدر قبل/بعد</th>'+
            '<th class="p-2">الوجهة قبل/بعد</th>'+
            '<th class="p-2">المنفذ</th>'+
            '</tr>'+
            '</thead>'+
            '<tbody>'+
            movementH+
            '</tbody>'+
            '</table>'+
            '</div>'+

            '<div class="mt-4 border rounded-2xl p-3 bg-slate-50">'+
            '<div class="font-black text-sm mb-2">الأثر المالي والمحاسبي</div>'+
            journalH+
            '<div class="mt-3">'+
            financialRows(financial.driver_ledger||[],'دفتر المندوب / العهدة')+
            '</div>'+
            '<div class="mt-3">'+
            financialRows(financial.supplier_ledger||[],'دفتر المورد')+
            '</div>'+
            '</div>'+

            '<details class="mt-4">'+
            '<summary class="cursor-pointer font-black text-sm">سجل التدقيق</summary>'+
            '<div class="mt-2">'+auditH+'</div>'+
            '</details>'+

            '<div class="mt-3 text-[10px] text-slate-400">'+
            'Stock context: '+
            s.esc(stock.basis||'current_stock_reconciled_against_all_inventory_log_events')+
            '</div>'+

            '</div>';

~~~

هذا لا يغيّر محتوى التفاصيل. فقط يعيد ربط جميع سلاسل HTML بالمتغير `h`.

---

# 10. التعديل الجراحي T15

### الدالة
`receive:function(code,full){`

البداية: **line 2652**

### احذف الدالة كاملة
حتى قبل:

`editVoucher:function(code){`

### استبدلها بالدالة التالية كاملة

~~~javascript
receive:function(code,full){
    var s=this,
        voucherId=null;

    if(this.busy['receive:'+code]){
        return;
    }

    RW_UI.showLoader();

    supabase
        .from('stock_vouchers')
        .select('*,stock_voucher_details(*)')
        .eq('company_id',s.company)
        .eq('voucher_code',code)
        .maybeSingle()
        .then(function(r){

            RW_UI.hideLoader();

            if(r.error||!r.data){
                throw new Error(
                    'الإذن غير موجود'
                );
            }

            var v=r.data;

            voucherId=v.id;

            if(
                v.type!=='Transfer'&&
                v.type!=='DirectReturn'
            ){
                throw new Error(
                    'هذا النوع ينتقل إلى الإكمال مباشرة بعد الإرسال'
                );
            }

            var d=v.stock_voucher_details||[];

            var remaining=
                d
                    .map(function(x){
                        return{
                            item:x,
                            qty:Math.max(
                                0,
                                Number(x.qty||0)-
                                Number(x.received_qty||0)
                            )
                        };
                    })
                    .filter(function(x){
                        return x.qty>0;
                    });

            if(full===true){

                if(!remaining.length){
                    throw new Error(
                        'لا توجد كميات متبقية للاستلام'
                    );
                }

                var fh=
                    '<div class="text-right space-y-2">'+
                    '<div class="p-3 rounded-2xl bg-emerald-50 border border-emerald-100 font-black">'+
                    'سيتم استلام جميع الكميات المتبقية لهذا الإذن.'+
                    '</div>';

                remaining.forEach(function(rm){

                    fh+=
                        '<div class="flex justify-between gap-3 p-3 border rounded-2xl bg-slate-50">'+
                        '<span class="font-bold">'+
                        s.esc(
                            rm.item.item_name||
                            rm.item.item_code
                        )+
                        '</span>'+
                        '<b>'+
                        f(rm.qty)+
                        '</b>'+
                        '</div>';

                });

                fh+='</div>';

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

            }

            var h=
                '<div class="text-right space-y-2">';

            d.forEach(function(x,i){

                var rem=
                    Math.max(
                        0,
                        Number(x.qty||0)-
                        Number(x.received_qty||0)
                    );

                if(rem>0){

                    h+=
                        '<div class="p-3 border rounded-2xl bg-slate-50 flex gap-3 items-center">'+
                        '<div class="flex-1">'+
                        '<b>'+
                        s.esc(
                            x.item_name||
                            x.item_code
                        )+
                        '</b>'+
                        '<div class="text-xs text-slate-400">'+
                        'المتبقي: '+
                        f(rem)+
                        '</div>'+
                        '</div>'+
                        '<input id="rq'+i+
                        '" data-item-id="'+
                        x.item_id+
                        '" data-item-code="'+
                        s.esc(x.item_code)+
                        '" max="'+
                        rem+
                        '" min="0" value="'+
                        rem+
                        '" type="number" step="any" '+
                        'class="w-24 p-2 border rounded-xl text-center">'+
                        '</div>';

                }

            });

            h+='</div>';

            return Swal.fire({
                title:'استلام '+s.esc(v.type),
                html:h,
                showCancelButton:true,
                confirmButtonText:'تنفيذ الاستلام',
                cancelButtonText:'إلغاء',
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

        })
        .then(function(a){

            if(!a||!a.isConfirmed){
                return;
            }

            var isFull=
                full===true;

            var receivedItems=
                isFull
                    ?[]
                    :(a.value||[]);

            var vfp=
                isFull
                    ?'FULL_REMAINDER'
                    :
                    JSON.stringify(
                        receivedItems
                            .map(function(x){
                                return[
                                    x.itemId,
                                    Number(
                                        x.receivedQty
                                    )
                                ];
                            })
                            .sort(function(x,y){
                                return String(x[0])
                                    .localeCompare(
                                        String(y[0])
                                    );
                            })
                    );

            var store=
                'RW_VOUCHER_RECEIVE:'+
                s.company+
                ':'+
                voucherId;

            var op=null;

            if(isFull){

                op=
                    'UI-RECEIVE-REMAINDER:'+
                    s.company+
                    ':'+
                    voucherId;

            }else{

                try{

                    var old=
                        localStorage.getItem(
                            store
                        );

                    if(old){

                        var rec=
                            JSON.parse(old);

                        if(
                            rec&&
                            rec.fingerprint===vfp&&
                            rec.operation_id
                        ){
                            op=rec.operation_id;
                        }

                    }

                }catch(e){}

                if(!op){

                    op=
                        (
                            window.crypto&&
                            crypto.randomUUID
                        )
                            ?crypto.randomUUID()
                            :
                            'UI-RECEIVE:'+
                            s.company+
                            ':'+
                            voucherId+
                            ':'+
                            Date.now()+
                            ':'+
                            Math.random()
                                .toString(36)
                                .slice(2);

                }

                try{

                    localStorage.setItem(
                        store,
                        JSON.stringify({
                            operation_id:op,
                            fingerprint:vfp,
                            created_at:
                                new Date()
                                    .toISOString()
                        })
                    );

                }catch(e){}

            }

            s.busy['receive:'+code]=true;

            RW_UI.showLoader(
                'جاري تسجيل الاستلام...'
            );

            RW_API.call(
                'receive-stock-voucher',
                {
                    voucher_code:code,
                    receivedItems:
                        receivedItems,
                    operation_id:op
                },
                function(j){

                    RW_UI.hideLoader();

                    delete s.busy[
                        'receive:'+code
                    ];

                    if(j&&j.success){

                        if(!isFull){
                            try{
                                localStorage.removeItem(
                                    store
                                );
                            }catch(e){}
                        }

                        RW_UI.toast(
                            j.duplicate
                                ?'تم التعرف على العملية المكررة'
                                :'تم الاستلام بنجاح',
                            'success'
                        );

                        s.loadList(
                            'pending'
                        );

                        s.prefetchStock(
                            true
                        );

                    }else{

                        RW_UI.showError(
                            (j&&j.msg)||
                            'فشل الاستلام — تم الاحتفاظ بهوية العملية لإعادة المحاولة بأمان'
                        );

                    }

                }
            );

        })
        .catch(function(e){

            RW_UI.hideLoader();

            delete s.busy[
                'receive:'+code
            ];

            RW_UI.showError(
                e.message||
                'فشل فتح الاستلام'
            );

        });
},

~~~

الإصلاح البنيوي المحدد:
إغلاق `if(full===true)` بعد Modal الاستلام الكلي.

لا يتم تغيير:
- RPC
- operation_id
- partial receive
- full receive
- localStorage idempotency

---

# 11. التعديل الجراحي T16

### الملف
`companies/company-1/warehouse/vouchers.html`

### لا تبحث عن
`vehicleBranch:function(v){`

لأنها محذوفة حاليًا من HEAD.

### ابحث تحديدًا عن
`syncDirectSaleVehicleWithRep:function(repId){`

البداية الحالية: **line 3579**

### أضف مباشرة قبله

~~~javascript
vehicleBranch:function(v){

    if(
        !v ||
        v.mobile_stock_enabled===false
    ){
        return null;
    }

    var branches=
        this.refs &&
        this.refs.branches
            ?this.refs.branches
            :[];

    if(
        !this._voucherBranchIndex ||
        this._voucherBranchIndex.rows!==branches
    ){

        var byId=
            Object.create(null);

        var byCode=
            Object.create(null);

        branches.forEach(
            function(b){

                if(
                    !b ||
                    b.is_active===false ||
                    String(
                        b.company_id||''
                    )!==String(
                        this.company||''
                    )
                ){
                    return;
                }

                byId[
                    String(b.id)
                ]=b;

                var code=
                    String(
                        b.branch_code||''
                    )
                    .trim()
                    .toUpperCase();

                if(code){
                    byCode[code]=b;
                }

            },
            this
        );

        this._voucherBranchIndex={
            rows:branches,
            byId:byId,
            byCode:byCode
        };
    }

    var index=
        this._voucherBranchIndex;

    if(v.mobile_branch_id){

        var direct=
            index.byId[
                String(
                    v.mobile_branch_id
                )
            ];

        if(
            direct &&
            String(
                direct.company_id||''
            )===String(
                this.company||''
            ) &&
            direct.is_active!==false
        ){
            return direct;
        }
    }

    var fallbackCode=
        'VAN-'+
        String(
            v.vehicle_code||''
        )
        .trim()
        .toUpperCase();

    return (
        index.byCode[fallbackCode]||
        null
    );
},


~~~

هذه الدالة مستعادة حرفيًا من parent commit، وليست إعادة بناء جديدة.

---

# 12. لماذا لا توجد تعديلات Supabase أخرى

لأن العطل الحالي موجود في parser/assembly داخل frontend.

Production أثبت:
- CRUD draft يعمل عبر RPC.
- الأنواع الأربعة مقبولة.
- cleanup يعمل.
- المسؤوليات والقيود الأساسية موجودة.

إنشاء Function جديدة لن يحل هذا العطل وسيزيد ضغط الـFunction/Spend Cap بدون مبرر.

---

# 13. Source-level validation

تم تنفيذ rehearsal للتعديلات الأربعة على Current Source في الذاكرة:

### Parsing
**6 / 6 embedded scripts = PASS**

### Functional smoke
**10 / 10 = PASS**

شمل:
1. Owner wildcard.
2. exact transfer receiver.
3. رفض receiver غير الصحيح.
4. warehouse manager completion.
5. DirectReturn authorization.
6. SupplierReturn completion.
7. vehicleBranch resolution.
8. Transfer source home-branch restriction.
9. وجود route surfaces للأنواع الأربعة.
10. cards render بدون تسريب أزرار التنفيذ.

هذه ليست Browser E2E.

---

# 14. Browser / Deployment closure

لا توجد حاليًا أدلة Browser E2E حديثة كافية لإعلان إغلاق الـHEAD.

الخط الصحيح التالي:

`T13 → T14 → T15 → T16 → Browser Parse → Browser E2E → Production evidence → Closure`

---

# 15. Tailwind warning

التحذير:

`cdn.tailwindcss.com should not be used in production`

ليس سبب الانهيار الحالي.

هو hardening مستقل يحتاج build/CSS pipeline، لذلك لا يدخل في الإصلاح الجراحي الحالي.

---

# 16. Self Audit

| البند | الحالة |
|---|---|
| Master Governance | مقروء |
| Report350 | مقروء |
| Report351 | مقروء |
| CURRENT_STATE | مقروء |
| Current Git | تم |
| Parent commit | تم |
| Current source | تم |
| Production DB | تم |
| Production transient QA | PASS |
| QA cleanup | PASS |
| New Edge Function | لا |
| main.html | لم يُلمس |
| vouchers.html | لم يُلمس مباشرة |
| van-sales.html | لم يُلمس |
| T09/T10/T11 | لم تُعاد |
| Surgical rehearsal | PASS |
| Browser E2E | غير مثبت بعد |

---

# 17. إرشادات الجلسة التالية

ابدأ من هذا التقرير و`CURRENT_STATE.md`.

نفذ فقط:

**T13 → T14 → T15 → T16**

ثم:

**Syntax → Browser E2E → Production evidence**

لا تبدأ من الصفر.

لا تعيد إصلاح ما ثبت إغلاقه.

لا تنشئ Edge Function جديدة.

لا تلمس `main.html`.

لا تلمس `van-sales.html`.

لا تغيّر عقود Transfer/Receiver/Supplier Return المثبتة إلا إذا ظهر دليل جديد من Current Production يناقضها.

---

## الحكم التنفيذي

**المشكلة الحالية = Regression في Frontend HEAD، وليست فجوة Backend.**

**الـProduction contract الحالي صالح ومختبر.**

**الأربعة Patches في هذا التقرير كافية لإعادة الملف إلى حالة متماسكة نحويًا ووظيفيًا على مستوى المصدر.**

**الإغلاق النهائي يبقى مشروطًا بتطبيق المستخدم للـPatch ثم Browser E2E ثم دليل النشر.**
