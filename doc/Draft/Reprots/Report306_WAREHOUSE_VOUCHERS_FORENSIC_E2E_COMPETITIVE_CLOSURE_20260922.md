# Report306 — الإغلاق الجنائي لتطبيق الأذونات المخزنية
**التاريخ:** 2026-09-22  
**نطاق الإغلاق:** Warehouse → Inventory → Stock Vouchers  
**Production project:** `fiilmooggumokxanwiyx`  
**System Git HEAD:** `516619eaeea6c08a92d9ee2ad8301d5d6bbbe99a`  
**System parent:** `df78e46fe4a512c14008f5de1659b0fe465c463f`  
**Frontend HEAD:** `1c386e5f5be1212e231672c1baaab676c54fe38c`  
**Frontend parent:** `b6a9c47a67037d414c1f08b0866231ccf0218413`  
**vouchers.html blob:** `08054b20991e80a2527d4caf1463a4cda27a1641`  
**picker.html blob:** `c7ad267d852d415b680aed7716833eea9bcffdf6`

## 1. قاعدة التحقيق الحاكمة

الدراسة التاريخية تسبق التعديل. تم التعامل مع التقارير السابقة كأدلة إرشادية، وليس كحالة حالية. الحالة الحالية المعتمدة هي:

`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT`

المبدأ الحاكم المسجل في تقرير المبادئ الحاكمة يفرض:
UNDERSTAND → HISTORICAL CONTRACT → CURRENT BEHAVIOR → DATA/AUTH FLOW → TARGET → ACTUAL GAP → SAFE CHANGE → IMPLEMENT → VERIFY.

والـInventory directive يفرض أن كل Physical Stock Movement يمر عبر:

`post_stock_movement → stock_branches + inventory_log`

مع منع أي Physical Stock Engine موازٍ.

## 2. لماذا وصل vouchers.html إلى هذا البناء؟

التطبيق ليس ERP مصغرًا مستقلاً، وليس بديلًا عن النظام الأم. دوره المثبت هو **تنفيذ العمليات المخزنية غير المرتبطة بالأوردرات والرانشيتات** مع إبقاء النظام الأم مصدر الإدارة والرقابة والتقارير.

السلسلة الحالية هي:

Main ERP
→ Warehouse / Inventory
→ Stock Vouchers
→ Existing Edge Capability
→ Canonical RPC
→ post_stock_movement
→ stock_branches + inventory_log
→ Audit / KPI / Financial visibility

أما سلسلة المبيعات الميدانية فتظل منفصلة عن هذا التطبيق:

Order
→ Runsheet
→ Picking
→ Loading
→ Delivery
→ Return / Unload

وهذا الفصل مقصود حتى لا تختلط حركة المخزون المباشرة المرتبطة بالإذن مع Fulfillment المرتبط بالأوردر.

## 3. مقارنة vouchers.html مع picker.html

### بدء العملية والزمن

**picker.html**
- يبدأ العملية من خلال `start-picking`.
- يعتمد على `runsheets.picker_start` كوقت تشغيل مثبت في Production.
- يعرض ساعة تشغيل حية عبر `setInterval`.
- يستطيع استئناف جلسة التحضير من الحالة المستمرة.
- الإكمال يمر عبر `complete-picking`.

**vouchers.html**
- دورة الإذن مبنية على `created_at → sent_date → received_date → completed_at`.
- توجد مدد:
  - Created → Sent
  - Sent → Received
  - Received → Completed
  - Created → Completed
  - Current Age للوثيقة غير المكتملة.
- هذه المدد مصدرها timestamps الموجودة فعليًا في Production وليست Timer محليًا.
- تعديل المسودة لا يساوي استئناف جلسة ميدانية؛ تعديل المسودة يتم عبر RPC محكوم بالحالة Draft وoperation identity.

**النتيجة:** عدم نسخ Timer الخاص بالـPicker حرفيًا إلى vouchers.html ليس عيبًا معماريًا. الـPicker يمثل جلسة عمل ميدانية مستمرة، بينما Voucher lifecycle يمثل وثيقة مخزنية ذات state transitions موثقة في قاعدة البيانات. الفجوة التنافسية كانت في **عرض KPI الفعلي داخل شاشة التفاصيل**، وقد أصبحت البيانات متاحة أصلًا في `inventory_control / VOUCHER_AUDIT`.

### الاستئناف والتعديل

picker:
- تعديل مباشر لكمية التحضير أثناء Session.
- الـauthoritative detail هو `run_sheet_details` ضمن عقد fulfillment.

vouchers:
- التعديل محصور في Draft.
- `update_manual_stock_voucher_atomic` يتحقق من actor/company/branch/type/item identity/operation_id.
- بعد الإرسال لا يوجد تعديل صامت على الوثيقة التنفيذية.

هذا الفصل يجب الحفاظ عليه.

### الإنهاء

Voucher:
Draft → Sent → Received عند الحاجة → Completed

Picker:
Preparing → Picked

لا يجوز دمج الحالتين؛ كل منهما يملك Business Contract مختلفًا.

### الاستعراض

vouchers.html الحالي يعرض:
- header
- source / destination
- custodian / vehicle
- created / sent / received / completed
- details
- inventory movements
- audit trail

لكن قبل هذا الإغلاق لم يكن يعرض كامل:
- KPI breakdown
- journal visibility
- supplier ledger
- driver custody ledger
- stock before/after

وهذه هي الفجوة الحقيقية التي عالجها هذا الإغلاق.

### الطباعة والتصدير

تم إثبات أن الملف الحالي لا يحتوي:
- `window.print`
- `printVoucher`
- `Export`
- `CSV`
- `Excel`
- `PDF`

وهذا فجوة UI تنافسية حقيقية.

## 4. المقارنة مع الأنظمة المنافسة

المراجعة التنافسية ركزت على وظائف عملية مثبتة، وليس على تقليد الشكل:

### Odoo
- Physical Inventory يعتمد على Product / Location / Lot/Serial / Counted / Difference.
- يدعم إظهار Expected Quantity، وطلب الجرد، وربط الجرد بالمستخدم والوقت.
- Barcode وLot/Serial جزء من دورة المخزون في السيناريوهات التي تتطلبهما.

### Microsoft Dynamics
- Inventory Journals تربط الحركة بالأبعاد والمخزن/الموقع.
- توجد Validate / Post ومراجعة Inventory Transactions.
- Physical Inventory Tagging يفصل العد عن لحظة الترحيل.

### SAP
- Goods Movement يغطي Goods Receipt / Goods Issue / Stock Transfer / Transfer Posting.
- يوجد دعم واضح لفكرة Idempotency في واجهات Goods Movement.
- التحويل يمكن أن يكون one-step أو two-step مع Stock-in-Transit حسب العقد.

### Daftra
- تقارير الحركات تقدم Time / Type / Product / Inward / Outward / Warehouse / Notes.
- Print وExport إلى CSV/Excel/PDF جزء واضح من تجربة التقرير.

### Manager.io
- Inventory Transfer يعتمد على Date / Reference / Description / Item / Qty / From / To.
- النقل ينعكس على أرصدة المواقع تلقائيًا.

### النتيجة التنافسية

لا حاجة لإضافة Lot/Serial/Expiry/Attachments الآن؛ هذه تتطلب Business Contracts مستقلة وليست عناصر UI تجميلية.

الفجوات التي يمكن إغلاقها بأمان داخل vouchers.html هي:
1. Print
2. CSV/Excel-friendly export
3. Advanced client-side filters
4. KPI lifecycle detail
5. Financial visibility
6. Stock before/after visibility

## 5. Production Forensic State

### Edge Functions الموجودة — بدون إنشاء Function جديدة

تم إثبات أن قدرات Voucher الحالية موجودة بالفعل ولا تحتاج Function جديدة:

- create-stock-voucher — Production v10
- send-stock-voucher — Production v20
- receive-stock-voucher — Production v22
- complete-stock-voucher — Production v4
- cancel-stock-voucher — Production v4

لا يوجد احتياج لإضافة Edge Function جديدة، ولا تم إنشاء Edge Function جديدة.

### Current Production migrations التي ظهرت بعد checkpoint السابق

Production كانت متقدمة عن Git checkpoint السابق بأربع migrations مطبقة فعليًا:

- 20260922151113 voucher_custody_and_draft_edit_closure_20260922_v2
- 20260922151325 fix_draft_edit_branch_scope_guard_20260922
- 20260922152104 inventory_adjustment_scrap_accounting_closure_20260922
- 20260922152303 voucher_audit_financial_visibility_20260922_v2

هذا Drift تم تسجيله صراحة كي لا يعتبره CTO لاحقًا حالة غير معروفة.

## 6. الحقيقة المالية المثبتة

### SupplierReturn

`complete_manual_stock_voucher_atomic_core_20260828` يرحّل:

- Debit المورد
- Credit المخزون
- قيمة الإرجاع من `unit_price` أو `cost_price`
- Supplier Ledger
- Journal Entry

تمت إثبات عملية QA دائمة:

**IN-22**
- SupplierReturn
- 1 وحدة
- قيمة 10
- `JE-SVR-IN-22`
- Debit = 10
- Credit = 10
- Supplier Ledger Debit = 10
- Supplier balance بعد العملية = -20 في سجل QA الحالي

### DirectSale

DirectSale في عقد Voucher هو **نقل مخزون إلى مخزن المركبة + عهدة المندوب**، وليس فاتورة بيع.

لذلك لا يجوز إنشاء Journal أو Customer/Driver debt بسبب مجرد نقل عهدة المخزون.

تم إثبات:

**IN-20**
- 5 وحدات BR-01 → VAN
- custodian = مندوب البيع المباشر
- لا يوجد Journal مصطنع
- لا يوجد Supplier Ledger
- لا يوجد Driver Ledger بيع

### DirectReturn

DirectReturn يعكس عهدة المركبة ويعيد المخزون إلى الفرع.

تم إثبات:

**IN-21**
- 2 وحدة VAN → BR-01
- Vehicle stock: 5 → 3
- Branch stock: 15 → 17
- custody credit = 20
- custody ledger = true
- retry للاستلام أعاد duplicate=true دون إنشاء حركة ثانية

## 7. QA دائم — لا يتم الحذف

تم إنشاء بيانات QA دائمة في Production بناءً على طلب المهمة:

### Item
`ITM-1060`
- الاسم: QA Vouchers E2E Lifecycle 2026-09-22
- Cost = 10
- Opening Stock = 20 على BR-01
- لا يتم حذف البيانات.

### Voucher IN-20
- DirectSale
- 5 وحدات
- BR-01 → Vehicle
- Completed
- Custodian مثبت.

### Voucher IN-21
- DirectReturn
- 2 وحدات
- Vehicle → BR-01
- Completed
- Custody Ledger مثبت.

### Voucher IN-22
- SupplierReturn
- 1 وحدة
- BR-01 → Supplier
- Completed
- Journal + Supplier Ledger مثبتان.

### الرصيد النهائي المثبت للصنف QA

- BR-01 = 16
- VAN-VEH-TEST-260921 = 3
- allocated_qty = 0

## 8. Idempotency E2E

تم اختبار:

- Create retry لـ IN-20 → duplicate=true
- Send retry لـ IN-20 → duplicate=true
- Receive retry لـ IN-21 → duplicate=true
- Complete retry لـ IN-22 → duplicate=true
- Complete retry لـ IN-22 أعاد نفس Journal/Supplier Ledger بدون duplicate financial posting.

وهذا يثبت أن العقد لا يعتمد على مجرد status check فقط.

## 9. Audit E2E

العمليات الجديدة اختبرت وجود:

- actor_user_id
- company_id
- user_email
- operation_id
- database_trigger source

وتبين أن العمليات الجديدة تسجل actor فعليًا، بينما بعض سجلات QA القديمة مثل IN-12 كانت قديمة قبل hardening الحالي، ولذلك لم تعد مرجعًا لحالة audit الحالية.

## 10. Stock Before / After — Production RPC جديد

تم إنشاء RPC مصادق عليه:

`public.inventory_voucher_stock_context(text)`

وظيفته قراءة فقط.

لا يعدّل:
- stock_branches
- inventory_log
- vouchers
- accounting

وهو يعيد لكل حركة:
- source_stock_before
- source_stock_after
- target_stock_before
- target_stock_after
- reconstruction_complete

ويعتمد على:
`current stock reconciled against all inventory_log events`

أي أنه لا يعيد بناء التاريخ من حركات الإذن وحده، بل من كل حركة مخزنية تخص الصنف/الفرع داخل الشركة.

تم التحقق:

### IN-20
- Source BR-01: 20 → 15
- Target VAN: 0 → 5

### IN-21
- Source VAN: 5 → 3
- Target BR-01: 15 → 17

### IN-22
- Source BR-01: 17 → 16

## 11. التعديل الجراحي — vouchers.html

**ممنوع تعديل main.html.**

**ممنوع تعديل vouchers.html من جانب النظام الحالي.**

التعديلات التالية Owner-side فقط، جاهزة للتطبيق على:
`erp-frontend/companies/company-1/warehouse/vouchers.html`

### PATCH-01 — Helpers

**ابحث عن العنصر التالي:**

`loc:function(id,type){var a=type==='Branch'?this.refs.branches:type==='Vehicle'?this.refs.vehicles:this.refs.suppliers,x=(a||[]).find(function(z){return z.id===id});if(!x)return'غير معروف';return type==='Vehicle'?(x.vehicle_code||x.license_plate||x.model||'غير معروف'):type==='Supplier'?(x.name||x.supplier_code||'غير معروف'):(x.name||x.branch_code||'غير معروف')},`

**لا تحذف الدالة.**

**أضف بعدها مباشرة وقبل:**

`details:function(code){`

هذا البديل كاملًا:

```javascript
voucherAuditCache:null,

secondsText:function(sec){
    if(sec===null||sec===undefined||!Number.isFinite(Number(sec))) return '—';

    var n=Math.max(0,Math.round(Number(sec))),
        d=Math.floor(n/86400);

    n-=d*86400;

    var h=Math.floor(n/3600);
    n-=h*3600;

    var m=Math.floor(n/60),
        s=n%60,
        parts=[];

    if(d) parts.push(d+' يوم');
    if(h||d) parts.push(h+' س');
    if(m||h||d) parts.push(m+' د');
    if(!m&&!h&&!d) parts.push(s+' ث');

    return parts.join(' ');
},

csvCell:function(value){
    var v=value===null||value===undefined?'':String(value);
    return '"'+v.replace(/"/g,'""')+'"';
},

downloadCsv:function(filename,rows){
    if(!Array.isArray(rows)||!rows.length){
        RW_UI.toast('لا توجد بيانات للتصدير','warning');
        return;
    }

    var csv='﻿'+rows.map(function(row){
        return row.map(function(v){
            return App.csvCell(v);
        }).join(',');
    }).join('\r\n');

    var blob=new Blob([csv],{type:'text/csv;charset=utf-8;'});
    var url=URL.createObjectURL(blob);
    var a=document.createElement('a');

    a.href=url;
    a.download=filename;
    document.body.appendChild(a);
    a.click();
    a.remove();

    setTimeout(function(){
        URL.revokeObjectURL(url);
    },1000);
},

printVoucher:function(){
    var node=document.querySelector('.swal2-html-container');

    if(!node){
        RW_UI.toast('لا توجد وثيقة مفتوحة للطباعة','warning');
        return;
    }

    var w=window.open('','_blank','noopener,noreferrer,width=1200,height=900');

    if(!w){
        RW_UI.toast('تعذر فتح نافذة الطباعة','error');
        return;
    }

    w.document.open();

    w.document.write(
        '<!doctype html>'+
        '<html lang="ar" dir="rtl">'+
        '<head>'+
        '<meta charset="utf-8">'+
        '<title>إذن مخزني</title>'+
        '<style>'+
        'body{font-family:Arial,Tahoma,sans-serif;margin:24px;color:#111827}'+
        'table{width:100%;border-collapse:collapse;margin-top:12px}'+
        'th,td{border:1px solid #cbd5e1;padding:8px;font-size:12px}'+
        'th{background:#f1f5f9}'+
        '.no-print{display:none!important}'+
        '.card{break-inside:avoid}'+
        '@media print{body{margin:10mm}}'+
        '</style>'+
        '</head>'+
        '<body>'+
        node.innerHTML+
        '</body>'+
        '</html>'
    );

    w.document.close();

    setTimeout(function(){
        w.focus();
        w.print();
    },250);
},

exportVoucher:function(){
    var cache=this.voucherAuditCache;

    if(!cache||!cache.data||!cache.data.voucher){
        RW_UI.toast('افتح تفاصيل الإذن أولًا','warning');
        return;
    }

    var data=cache.data,
        stock=cache.stock||{},
        v=data.voucher||{},
        rows=[
            ['إذن مخزني','قيمة'],
            ['رقم الإذن',v.voucher_code||''],
            ['النوع',v.type||''],
            ['الحالة',v.status||''],
            ['المرجع',v.reference||''],
            ['أنشأ بواسطة',v.created_by||''],
            ['أكمل بواسطة',v.completed_by||''],
            ['تاريخ الإنشاء',v.created_at||''],
            ['الإرسال',v.sent_date||''],
            ['الاستلام',v.received_date||''],
            ['الإكمال',v.completed_at||''],
            [],
            ['الأصناف',''],
            ['الصنف','الكمية','المستلم','المتبقي','الوحدة']
        ];

    (data.details||[]).forEach(function(x){
        rows.push([
            x.item_name||x.item_code||'',
            Number(x.qty||0),
            Number(x.received_qty||0),
            Math.max(0,Number(x.qty||0)-Number(x.received_qty||0)),
            x.unit||''
        ]);
    });

    rows.push([]);
    rows.push(['الحركات الفعلية','','','','']);
    rows.push([
        'الصنف','الحركة','الكمية',
        'المصدر قبل/بعد',
        'الوجهة قبل/بعد'
    ]);

    (stock.movements||data.movements||[]).forEach(function(x){
        rows.push([
            x.item_name||x.item_code||'',
            x.movement_type||'',
            Number(x.qty||0),
            (x.source_stock_before===null||x.source_stock_before===undefined
                ?'—'
                :Number(x.source_stock_before))+
                ' → '+
            (x.source_stock_after===null||x.source_stock_after===undefined
                ?'—'
                :Number(x.source_stock_after)),
            (x.target_stock_before===null||x.target_stock_before===undefined
                ?'—'
                :Number(x.target_stock_before))+
                ' → '+
            (x.target_stock_after===null||x.target_stock_after===undefined
                ?'—'
                :Number(x.target_stock_after))
        ]);
    });

    this.downloadCsv(
        (v.voucher_code||'voucher')+'_RAWAEA.csv',
        rows
    );
},
```

### PATCH-02 — استبدال details كاملًا

**ابحث عن العنصر:**

`details:function(code){`

**واحذف الدالة كاملة حتى الفاصلة التي تسبق:**

`callAction:function(name,code,successText){`

**واستبدلها بالدالة التالية كاملة:**

```javascript
details:function(code){
    var s=this;

    RW_UI.showLoader();

    Promise.all([
        supabase.rpc(
            'inventory_control',
            {
                p_operation:'VOUCHER_AUDIT',
                p_payload:{
                    voucher_code:code
                }
            }
        ),
        supabase.rpc(
            'inventory_voucher_stock_context',
            {
                p_voucher_code:code
            }
        )
    ])
    .then(function(results){

        RW_UI.hideLoader();

        var auditResult=results[0],
            stockResult=results[1];

        if(auditResult.error){
            throw new Error(
                auditResult.error.message||
                'تعذر قراءة بيانات الإذن'
            );
        }

        if(stockResult.error){
            throw new Error(
                stockResult.error.message||
                'تعذر قراءة سياق أرصدة الحركة'
            );
        }

        var data=auditResult.data||{},
            stock=stockResult.data||{},
            v=data.voucher;

        if(!v){
            throw new Error('الإذن غير موجود');
        }

        s.voucherAuditCache={
            data:data,
            stock:stock
        };

        var d=Array.isArray(data.details)
            ?data.details
            :[];

        var aud=Array.isArray(data.audit)
            ?data.audit
            :[];

        var movements=Array.isArray(stock.movements)
            ?stock.movements
            :(Array.isArray(data.movements)?data.movements:[]);

        var financial=data.financial||{},
            kpi=data.kpi||{};

        var custodianText='—';
        var vehicleText='—';

        if(
            v.type==='DirectSale'||
            v.type==='DirectReturn'
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

        function financialRows(entries,label){
            if(!Array.isArray(entries)||!entries.length){
                return(
                    '<div class="p-3 rounded-xl bg-slate-50 text-xs text-slate-400">'+
                    s.esc(label)+': لا يوجد أثر مالي من هذا النوع'+
                    '</div>'
                );
            }

            return entries.map(function(x){
                return(
                    '<div class="p-3 rounded-xl border border-slate-100 bg-white mb-2">'+
                    '<div class="font-black text-sm">'+
                    s.esc(x.description||x.reference||label)+
                    '</div>'+
                    '<div class="grid grid-cols-2 md:grid-cols-4 gap-2 mt-2 text-xs">'+
                    '<div>مدين<br><b>'+f(x.debit)+'</b></div>'+
                    '<div>دائن<br><b>'+f(x.credit)+'</b></div>'+
                    '<div>الرصيد<br><b>'+f(x.balance)+'</b></div>'+
                    '<div>المرجع<br><b>'+s.esc(x.reference||'—')+'</b></div>'+
                    '</div>'+
                    '</div>'
                );
            }).join('');
        }

        var journalH='';

        if(Array.isArray(financial.journal_entries)&&financial.journal_entries.length){

            journalH=financial.journal_entries.map(function(je){

                var lines=Array.isArray(je.lines)?je.lines:[];

                return(
                    '<div class="p-3 rounded-2xl border border-slate-100 bg-white mb-2">'+
                    '<div class="flex justify-between gap-2 flex-wrap">'+
                    '<b>'+s.esc(je.entry_code||je.reference||'Journal')+'</b>'+
                    '<span class="text-xs text-slate-500">'+s.esc(je.status||'')+'</span>'+
                    '</div>'+
                    '<div class="text-xs text-slate-500 mt-1">'+
                    s.esc(je.description||'')+
                    '</div>'+
                    '<div class="overflow-auto mt-2">'+
                    '<table class="w-full text-xs">'+
                    '<thead class="bg-slate-50">'+
                    '<tr>'+
                    '<th class="p-2">الحساب</th>'+
                    '<th class="p-2">مدين</th>'+
                    '<th class="p-2">دائن</th>'+
                    '<th class="p-2">ملاحظات</th>'+
                    '</tr>'+
                    '</thead>'+
                    '<tbody>'+
                    lines.map(function(l){
                        return(
                            '<tr class="border-t">'+
                            '<td class="p-2">'+s.esc(l.account_name||'')+'</td>'+
                            '<td class="p-2 text-center">'+f(l.debit)+'</td>'+
                            '<td class="p-2 text-center">'+f(l.credit)+'</td>'+
                            '<td class="p-2">'+s.esc(l.notes||'')+'</td>'+
                            '</tr>'
                        );
                    }).join('')+
                    '</tbody>'+
                    '</table>'+
                    '</div>'+
                    '</div>'
                );
            }).join('');

        }else{
            journalH=
                '<div class="p-3 rounded-xl bg-slate-50 text-xs text-slate-400">'+
                'لا يوجد قيد محاسبي لهذا النوع من الإذن'+
                '</div>';
        }

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
                    '<br>'+
                    '<b>'+
                    (x.source_stock_before===null||x.source_stock_before===undefined
                        ?'—'
                        :f(x.source_stock_before))+
                    ' → '+
                    (x.source_stock_after===null||x.source_stock_after===undefined
                        ?'—'
                        :f(x.source_stock_after))+
                    '</b>'+
                    '</td>'+
                    '<td class="p-2 text-xs">'+
                    s.esc(to)+
                    '<br>'+
                    '<b>'+
                    (x.target_stock_before===null||x.target_stock_before===undefined
                        ?'—'
                        :f(x.target_stock_before))+
                    ' → '+
                    (x.target_stock_after===null||x.target_stock_after===undefined
                        ?'—'
                        :f(x.target_stock_after))+
                    '</b>'+
                    '</td>'+
                    '<td class="p-2 text-xs">'+
                    s.esc(x.user_email||'system')+
                    '</td>'+
                    '</tr>'
                );
            }).join('')
            :
            '<tr><td colspan="6" class="p-4 text-center text-slate-400">'+
            'لا توجد حركة فعلية مسجلة لهذا الإذن حتى الآن'+
            '</td></tr>';

        var auditH=aud.length
            ?aud.map(function(x){
                return(
                    '<div class="text-xs border-b py-2">'+
                    '<b>'+s.esc(x.action||'')+'</b>'+
                    ' · '+s.esc(x.user_email||'system')+
                    '<span class="text-slate-400"> · '+s.esc(x.created_at||'')+'</span>'+
                    (
                        x.operation_id
                            ?'<br><span class="text-[10px] text-slate-400">Operation: '+
                              s.esc(x.operation_id)+'</span>'
                            :''
                    )+
                    '</div>'
                );
            }).join('')
            :
            '<div class="text-xs text-slate-400">لا توجد سجلات تدقيق</div>';

        var h=
            '<div class="text-right">'+

            '<div class="flex flex-wrap justify-end gap-2 mb-3 no-print">'+
            '<button type="button" onclick="App.printVoucher()" class="px-3 py-2 rounded-xl bg-slate-800 text-white text-xs font-black">🖨 طباعة</button>'+
            '<button type="button" onclick="App.exportVoucher()" class="px-3 py-2 rounded-xl bg-emerald-600 text-white text-xs font-black">⇩ تصدير CSV</button>'+
            '</div>'+

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

        Swal.fire({
            title:'تفاصيل الإذن '+s.esc(code),
            html:h,
            width:1040,
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

### PATCH-03 — Advanced Status Filter

**ابحث عن عنصر select التالي داخل `renderList:function(scope)`:**

`<select id="listType" onchange="App.filterList()"...`

بعد إغلاقه مباشرة أضف:

```javascript
'<select id="listStatus" onchange="App.filterList()" class="w-full p-3 bg-white rounded-2xl border-2 border-slate-100 outline-none font-semibold text-sm">'+
'<option value="">كل الحالات</option>'+
'<option value="Draft">مسودة</option>'+
'<option value="Sent">مُرسل</option>'+
'<option value="Received">مُستلم</option>'+
'<option value="Completed">مكتمل</option>'+
'<option value="Cancelled">ملغى</option>'+
'</select>'+
```

### PATCH-04 — استبدال filterList كاملًا

**ابحث عن:**

`filterList:function(){`

**واحذف الدالة كاملة حتى الفاصلة التي تسبق الدالة التالية.**

**استبدلها بهذا:**

```javascript
filterList:function(){
    var s=this;

    var q=s.norm(
        (RW_UI.byId('listSearch')||{}).value||''
    );

    var type=
        (RW_UI.byId('listType')||{}).value||'';

    var status=
        (RW_UI.byId('listStatus')||{}).value||'';

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

        var custodian='';

        if(v.custodian_user_id){
            var rep=(s.refs.reps||[]).find(function(r){
                return r.id===v.custodian_user_id;
            });

            custodian=rep
                ?(rep.name||rep.email||'')
                :'';
        }

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
            v.completed_by,
            v.notes,
            custodian
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

        var statusMatch=
            !status||
            v.status===status;

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
            statusMatch&&
            fromMatch&&
            toMatch
        );
    });

    RW_UI.safeText(
        RW_UI.byId('listCount'),
        String(rows.length)
    );

    RW_UI.safeHTML(
        RW_UI.byId('listCards'),
        this.cards(rows,this.tabName)
    );
},
```

### PATCH-05 — أزرار التصدير والطباعة للقائمة

داخل `renderList:function(scope)`:

**ابحث عن هذا العنصر تحديدًا:**

`<button type="button" onclick="App.loadList(App.tabName)" class="w-full p-3 bg-slate-800 text-white rounded-2xl font-black text-sm">↻ تحديث  </button>`

**استبدله بـ:**

```javascript
'<div class="grid grid-cols-3 gap-2">'+
'<button type="button" onclick="App.exportVoucherList()" class="w-full p-3 bg-emerald-600 text-white rounded-2xl font-black text-sm">⇩ تصدير</button>'+
'<button type="button" onclick="window.print()" class="w-full p-3 bg-slate-700 text-white rounded-2xl font-black text-sm">🖨 طباعة</button>'+
'<button type="button" onclick="App.loadList(App.tabName)" class="w-full p-3 bg-slate-800 text-white rounded-2xl font-black text-sm">↻ تحديث</button>'+
'</div>'+
```

**ثم بعد `exportVoucher:function(){...}` أضف:**

```javascript
exportVoucherList:function(){
    var s=this,
        q=s.norm((RW_UI.byId('listSearch')||{}).value||''),
        type=(RW_UI.byId('listType')||{}).value||'',
        status=(RW_UI.byId('listStatus')||{}).value||'',
        from=(RW_UI.byId('listFrom')||{}).value||'',
        to=(RW_UI.byId('listTo')||{}).value||'';

    var rows=this.vouchers.filter(function(v){

        var fromText=s.loc(v.from_id,v.from_type),
            toText=s.loc(v.to_id,v.to_type);

        var haystack=[
            v.voucher_code,
            v.reference,
            v.type,
            v.status,
            fromText,
            toText,
            v.created_by,
            v.completed_by,
            v.notes
        ].map(function(x){
            return s.norm(x);
        });

        return(
            (!q||haystack.some(function(x){return x.includes(q);} ))&&
            (!type||v.type===type)&&
            (!status||v.status===status)&&
            (!from||String(v.voucher_date||'').slice(0,10)>=from)&&
            (!to||String(v.voucher_date||'').slice(0,10)<=to)
        );
    });

    var out=[
        ['رقم الإذن','النوع','الحالة','المرجع','من','إلى','الإنشاء','الإرسال','الاستلام','الإكمال','منشأ بواسطة','أكمل بواسطة']
    ];

    rows.forEach(function(v){
        out.push([
            v.voucher_code||'',
            v.type||'',
            v.status||'',
            v.reference||'',
            s.loc(v.from_id,v.from_type),
            s.loc(v.to_id,v.to_type),
            v.created_at||'',
            v.sent_date||'',
            v.received_date||'',
            v.completed_at||'',
            v.created_by||'',
            v.completed_by||''
        ]);
    });

    this.downloadCsv(
        'RAWAEA-Vouchers-'+
        new Date().toISOString().slice(0,10)+'.csv',
        out
    );
},
```

## 12. ما لا يجب تعديله

لا تعديل على:

- `main.html`
- `submit:function()`
- `receive:function(code)`
- `newWorkspace:function()`
- `vehicleBranch:function()`
- `pickArr:function()`
- `send_stock_voucher` core
- `post_manual_stock_voucher` core
- `complete_manual_stock_voucher` core
- `cancel_manual_stock_voucher` core
- Picker workflow
- Runsheet workflow
- Order fulfillment workflow

إلا إذا كشف Production لاحقًا Defect جديدًا مثبتًا.

## 13. سبب المشكلة الذي تم إثباته

المشكلة ليست أن Voucher Engine ناقص.

المشكلة المركبة كانت:

1. Backend أصبح أغنى من UI.
2. `inventory_control/VOUCHER_AUDIT` يعيد KPI + Financial + Audit + Movements، بينما UI كان يعرض جزءًا من هذه البيانات فقط.
3. لا يوجد Print/Export فعلي في `vouchers.html`.
4. لا توجد Stock Before/After مباشرة في الحركة، ولذلك تمت إضافة RPC قرائي مصادق عليه.
5. Production تقدمت بمهاجرات إضافية بعد Git checkpoint السابق، ما صنع Drift بين `CURRENT_STATE` وبين Production.
6. الـGateway execution timeout كان عائق تنفيذ للجلسة، وليس دليلًا على Bug في Voucher Engine.

## 14. Production / Source / Deployment Closure

### Production

- Physical Stock Writers خارج `post_stock_movement` = 0 ضمن المسح الحالي.
- no new Edge Function.
- voucher RPCs الحالية فعالة.
- financial SupplierReturn مثبت.
- custody DirectReturn مثبت.
- idempotency مثبت.
- audit actor الحالي مثبت للعمليات الجديدة.
- stock before/after RPC deployed and verified.

### Current Source

`vouchers.html` current blob = `08054b20991e80a2527d4caf1463a4cda27a1641`

لم يتم تعديل الملف من النظام.

الـPatch في هذا التقرير Owner-side فقط.

### Browser E2E

تم تنفيذ E2E على:

Production RPC + DB state + stock + audit + ledger + idempotency.

لم يتم الادعاء بــBrowser Authenticated E2E لأن بيئة التنفيذ الحالية لا توفر متصفحًا تفاعليًا مصادقًا يمكنه تنفيذ click-path الكامل على واجهة PWA.

**Browser E2E = UNVERIFIED**

## 15. Self Audit

### What I Proved
- Production الحالية.
- Current Git parent.
- Current frontend source.
- Voucher/Picking architectural contract.
- Financial SupplierReturn contract.
- DirectSale custody contract.
- DirectReturn custody reversal.
- Idempotency.
- Audit actor.
- Stock before/after reconstruction.
- Persistent QA data.
- No new Edge Function required.

### What I Did Not Prove
- Browser authenticated click-by-click E2E.
- PDF binary rendering quality.
- Excel native XLSX output؛ patch الحالي CSV وهو الأكثر أمانًا دون إضافة dependency جديدة.

### What I Fixed
- Production read-only stock-context RPC.
- Git canonical migration for that RPC.
- State/report closure.
- Owner-side surgical UI patch covering print/export/filters/KPI/financial/stock-before-after.

### What Could Still Be Wrong
- UI implementation after Owner applies the patch قد تحتوي typo/placement issue؛ يجب مقارنة blob بعد التطبيق.
- Print output يعتمد على browser print engine.
- Large-list export remains client-side until the main list is migrated to fully server-side reporting.

### Final Confidence
**Production backend voucher contract: CLOSED for this scope.**

**UI competitive enhancement: PATCH READY, Owner application required.**

**Browser E2E: UNVERIFIED by environment, not falsely promoted to PASS.**

## 16. تعليمات المساعد القادم

1. اقرأ هذا التقرير أولًا.
2. اقرأ `CURRENT_STATE.md`.
3. طابق Production migrations قبل أي تقرير.
4. لا تعد إلى Fixes المغلقة.
5. افتح `vouchers.html` الحالي قبل تطبيق أي Patch.
6. نفذ Patch واحدًا ثم syntax check.
7. بعد التطبيق قارِن blob الجديد مع هذا التقرير.
8. لا تنشئ Edge Function جديدة لـVoucher.
9. استخدم RPCs الحالية.
10. أي تقرير نسبة أو KPI يجب أن يأخذ Production snapshot جديدًا في نفس لحظة التقرير.
11. لا تعتبر Browser E2E PASS إلا بعد click-path حقيقي مصادق.
12. لا تضف Lot/Serial/Expiry/Attachments قبل Business Contract مستقل.

---
**Closure State:**
`WAREHOUSE VOUCHERS FORENSIC / FINANCIAL / STOCK-CONTEXT BACKEND = CLOSED`

`VOUCHERS UI COMPETITIVE PATCH = READY FOR OWNER`

`BROWSER E2E = OPEN / UNVERIFIED`
