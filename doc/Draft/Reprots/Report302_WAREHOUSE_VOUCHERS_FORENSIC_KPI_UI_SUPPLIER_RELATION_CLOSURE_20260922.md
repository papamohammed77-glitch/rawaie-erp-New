# تقرير 302 — الأذونات المخزنية: التحقيق الجنائي الحالي وإكمال UX/KPI/SupplierReturn Closure
**التاريخ:** 2026-09-22  
**النطاق:** `erp-frontend/companies/company-1/warehouse/vouchers.html`  
**Production:** Supabase `fiilmooggumokxanwiyx`  
**القاعدة الحاكمة:** CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.

---

## 1. حالة الحقيقة قبل التنفيذ

### System repository
- HEAD عند بدء هذه الجولة: `3838fd33e98f689ec6d8e778ee539e6c89774c13`
- Parent: `8cc3b7538619bdf04585dfb60f44781234c3642e`
- آخر تسلسل وثائقي: Report301 ثم تصحيح مؤشر CURRENT_STATE.

### Frontend repository
- HEAD الحالي: `6715825ec05e62482a4e37335ab366f5512805cf`
- Parent: `745a615ccd0baff09ad2619b0316e46507a862e9`
- `vouchers.html` الحالي: `b23a7a8f605ff6151fd87b021de1e1d593672a57`
- `van-sales.html` الحالي: `8d61382a8e0025a0d079e71dd94f33d106d9088e`
- `main.html` الحالي: `8c3d6b05fd6a94a6b488f12b29da85ae888f70bc`

لم يتم تعديل `main.html` أو `vouchers.html` في هذا الإغلاق.

---

## 2. إعادة بناء دور التطبيق

تطبيق الأذونات المخزنية هو Operational Plane للحركات اليدوية غير المرتبطة بدورة Order/Runsheet:

- Transfer: `Branch → Branch`
- DirectSale: `Branch → Vehicle Mobile Stock`
- DirectReturn: `Vehicle Mobile Stock → Branch`
- SupplierReturn: `Branch → Supplier`

DirectSale هنا ليس فاتورة عميل. البيع الفعلي للعميل في Van Sales يمر عبر تطبيق البيع المباشر ثم `save_sales_invoice`/الحركة `VanSale`.

النظام الأم هو Control/Monitoring/Navigation Plane، ويعرض في مجموعة إدارة المخازن:
- مركز التحكم في المخزون.
- العمليات المخزنية.
- الأذونات المخزنية.
- الجرد.

الأذونات المخزنية في النظام الأم تفتح كتطبيق مستقل، ولا يوجد مبرر معماري لتحويلها إلى شاشة ضخمة داخل `main.html`.

---

## 3. Van Sales — النتيجة الجنائية

Current Van Sales يعتمد:
- `loadVanBranch()`
- `setup-van-branch`
- `vehicles.mobile_branch_id`
- `save-sales-invoice`
- `operation_id` محلي ثابت بحسب fingerprint.

السياق المثبت:
`vehicle.driver_id` هو Custodian/Representative identity للمخزن المتنقل.

Production Contract موجود بالفعل ولا يوجد Defect جديد مثبت في `van-sales.html`.

**القرار:** لا تعديل على `van-sales.html`.

---

## 4. Production — المورد وعلاقة الفرع

Production الحالية تحتوي موردًا نشطًا:
- Supplier: `SUPP-1001`
- ID: `87c5a847-8e05-492e-a15d-30e0a5cc93cc`
- Name: `ابراهيم الأبيض`

وكانت الحقيقة قبل بيانات QA:
- Purchase Orders مرتبطة بمورد/فرع: صفر.
- جدول `suppliers` لا يحتوي حاليًا علاقة branch master.
- لذلك لا يجوز للواجهة أن تخترع branch assignment للمورد.

عقد Production الصريح في `create_manual_stock_voucher_atomic` هو:

`purchase_orders.company_id + supplier_id + branch_id`

وبدونه يرفض Production إنشاء SupplierReturn.

هذا يعني أن عدم ظهور المورد في القائمة، عند انعدام العلاقة، ليس خطأ بحث حر يمكن علاجه بعرض كل الموردين.

---

## 5. السبب الحقيقي لمشكلة Supplier Search

Current `pickArr()` يحتوي:

`if(key==='wsTo'&&s.type==='SupplierReturn')`

ثم يبحث داخل:

`refs.supplierBranchMap[branchId]`

وإذا لم يوجد الربط يعيد:

`[]`

هذا Fail-Closed صحيح أمنيًا.

العيب UX كان أن الحقل يفسر النتيجة للمستخدم فقط كـ:
`لا توجد نتائج مرتبطة بالسياق المحدد`

ولا يشرح أن السبب هو **عدم وجود Supplier↔Branch relationship موثقة**.

### المعالجة الصحيحة

لا نفتح الموردين جميعًا.

نضيف فقط رسالة سياقية واضحة في `pickSearch()` عند:
- SupplierReturn
- wsTo
- القائمة المرتبطة فارغة.

وبذلك:
- يبقى Contract Fail-Closed.
- لا توجد بيانات متخيلة.
- يعرف المستخدم سبب الفراغ.
- عند وجود Purchase Order حقيقي للمورد والفرع يظهر المورد تلقائيًا.

---

## 6. QA Data — تم تنفيذها وتركها عمدًا

تم إنشاء بيانات Production تجريبية دائمة، ولم تُحذف:

### QA Purchase Order
- `QA-PO-SUPPLIER-LINK-20260922`
- Status: Draft
- Supplier: `SUPP-1001`
- Branch: `BR-01`
- Item: `1001`
- Qty Ordered: 1
- Qty Received: 0
- الغرض: إثبات علاقة Supplier↔Branch من خلال contract حقيقي، وليس عبر metadata مصطنع.

### QA Vouchers

| Voucher | Type | Status | Reference |
|---|---|---|---|
| IN-5 | DirectSale | Draft | QA-VOUCHER-DS-KPI-20260922 |
| IN-6 | DirectReturn | Draft | QA-VOUCHER-DR-KPI-20260922 |
| IN-7 | SupplierReturn | Draft | QA-VOUCHER-SR-SUPPLIER-20260922 |

جميعها:
- Quantity = 1
- Item = 1001
- Movement count = 0
- Operation registry = موجود.
- Audit trigger = موجود.

تم التحقق أن Stock `1001` في `BR-01` بقي:
- qty = 2
- allocated = 0
- available = 2

ولا توجد حركة Physical Stock من بيانات QA.

---

## 7. Production KPI Contract — تم تنفيذه

لا توجد حاجة لإنشاء جدول جديد أو Edge Function جديدة.

تم تعديل `inventory_control(text,jsonb)` بشكل إضافي آمن، وتحديدًا `VOUCHER_AUDIT` فقط، لإرجاع:

`kpi`

ويتضمن:

- `start_at`
- `sent_at`
- `received_at`
- `completed_at`
- `end_at`
- `created_to_sent_seconds`
- `sent_to_received_seconds`
- `received_to_completed_seconds`
- `created_to_completed_seconds`
- `current_age_seconds`

### سبب القرار

كل هذه القيم مبنية على أعمدة موجودة فعلًا في Production:

- `created_at`
- `sent_date`
- `received_date`
- `completed_at`

لا يوجد:
- عمود تخميني.
- وقت مفترض.
- trigger جديد.
- Edge Function جديدة.

الإضافة Backward Compatible لأن المفاتيح القديمة في JSON response بقيت كما هي.

تمت إضافة migration canonical إلى Git:

`supabase/migrations/20260922104000_voucher_audit_kpi_contract_20260922.sql`

---

## 8. Production VOUCHER_AUDIT Verification

تم تنفيذ `VOUCHER_AUDIT` تحت سياق مستخدم الأذونات بعد إضافة KPI على `IN-7`.

النتيجة:
- success = true
- voucher = IN-7
- details = موجودة.
- operations = موجودة.
- audit = موجود.
- movements = [].
- kpi = موجود.

في حالة Draft الحالية:
- start_at موجود.
- current_age_seconds محسوب.
- الحقول المرحلية غير المتاحة حاليًا = null.

وهذا السلوك صحيح؛ لا يتم اختراع `sent_at` أو `completed_at`.

---

# 9. CURRENT SOURCE — مشكلة طي القائمة العليا

## ROOT CAUSE المثبت

Current `renderWorkspace()` يبني:

`workspace-head`

ثم:

`<div class="mt-3"> + s.routeHtml() + </div>`

ثم:

`<div id="wsTopPanel" ...>`

بينما `toggleTopPanel()` تتحكم فقط في:

`wsTopPanel`

إذن route selectors:
- Branch
- Representative
- Vehicle
- Supplier

لا تدخل ضمن منطقة الطي.

### لماذا وصل البناء إلى ذلك؟

التعديل التاريخي الخاص بمشكلة Smart Menu clipping نقل `routeHtml()` خارج `wsTopPanel` لأن `wsTopPanel` كان يستخدم `overflow:hidden`.

هذا الإصلاح التاريخي صحيح ولا يجب إرجاع `routeHtml()` إلى عنصر overflow-hidden.

الخطأ الحالي هو أن عملية الطي لم تُعد تصميمها بعد نقل route controls.

---

# 10. OWNER SURGICAL PATCH V-302-01 — CSS

## الملف

`companies/company-1/warehouse/vouchers.html`

## ابحث عن العنصر التالي حرفيًا

`.ws-top-panel{transition:max-height .24s ease,opacity .18s ease,transform .18s ease;overflow:hidden}.ws-top-panel.ws-top-collapsed{max-height:0!important;opacity:0;transform:translateY(-6px);pointer-events:none}`

## احذفه بالكامل واستبدله بالآتي

```css
.ws-top-panel{transition:max-height .24s ease,opacity .18s ease,transform .18s ease;overflow:hidden}
.ws-top-panel.ws-top-collapsed{max-height:0!important;opacity:0;transform:translateY(-6px);pointer-events:none}

.ws-route-panel{max-height:420px;transition:max-height .24s ease,opacity .18s ease,transform .18s ease;overflow:visible}
.ws-route-panel.ws-route-collapsed{max-height:0!important;opacity:0;transform:translateY(-6px);pointer-events:none;overflow:hidden}
```

لا تعدل CSS الخاص بـ `workspace-head`.

---

# 11. OWNER SURGICAL PATCH V-302-02 — toggleTopPanel

## الملف

`companies/company-1/warehouse/vouchers.html`

## ابحث عن الدالة كاملة

`toggleTopPanel:function(){`

وتنتهي عند:

`},`

قبل:

`choose:function(t)`

## احذف الدالة كاملة واستبدلها:

```javascript
toggleTopPanel:function(){
    var b=RW_UI.byId('wsTopToggle');
    var route=RW_UI.byId('wsRoutePanel');
    var meta=RW_UI.byId('wsTopPanel');

    if(!b || (!route && !meta)){
        return;
    }

    var collapsed=!(this.topPanelCollapsed===true);

    this.topPanelCollapsed=collapsed;

    if(route){
        route.classList.toggle(
            'ws-route-collapsed',
            collapsed
        );
    }

    if(meta){
        meta.classList.toggle(
            'ws-top-collapsed',
            collapsed
        );
    }

    b.setAttribute(
        'aria-expanded',
        collapsed ? 'false' : 'true'
    );

    b.innerHTML=
        '<i class="fa-solid fa-'+
        (collapsed?'chevron-down':'chevron-up')+
        ' ml-1"></i><span>'+
        (collapsed?'توسيع الخيارات':'طي الخيارات')+
        '</span>';
},
```

---

# 12. OWNER SURGICAL PATCH V-302-03 — renderWorkspace

## الملف

`companies/company-1/warehouse/vouchers.html`

## ابحث عن

`renderWorkspace:function(){`

واحذف الدالة كاملة حتى نهاية:

`},`

الموجودة قبل:

`renderCats:function()`

## استبدلها كاملة بالآتي

```javascript
renderWorkspace:function(){
    var s=this,
        label=this.type==='Transfer'
            ?'تحويل داخلي'
            :this.type==='DirectSale'
                ?'صرف مباشر'
                :this.type==='DirectReturn'
                    ?'مرتجع مباشر'
                    :this.type==='SupplierReturn'
                        ?'مرتجع مورد'
                        :this.type==='Scrap'
                            ?'إتلاف / إعدام'
                            :'تسوية جرد',
        route=this.type==='Transfer'
            ?'فرع → فرع'
            :this.type==='DirectSale'
                ?'فرع → مركبة'
                :this.type==='DirectReturn'
                    ?'مركبة → فرع'
                    :this.type==='SupplierReturn'
                        ?'فرع → مورد'
                        :this.type==='Scrap'
                            ?'فرع → إتلاف'
                            :'فرع → تسوية',
        engine=this.mode==='engine',
        topCollapsed=this.topPanelCollapsed===true,

        routeClass=
            'ws-route-panel'+
            (topCollapsed?' ws-route-collapsed':''),

        metaClass=
            'ws-top-panel mt-3'+
            (topCollapsed?' ws-top-collapsed':''),

        h=
          '<div class="ws">'+
          '<div class="workspace-head p-3 sm:p-4 border-b border-slate-800">'+

            '<div class="flex items-center justify-between gap-2">'+

              '<div class="flex items-center gap-2">'+

                '<button type="button" onclick="App.back()" class="w-10 h-10 rounded-xl bg-white/10">'+
                  '<i class="fa-solid fa-arrow-right"></i>'+
                '</button>'+

                '<div>'+
                  '<b class="text-lg">'+s.esc(label)+'</b>'+
                  '<div class="text-[11px] text-slate-500">'+
                    s.esc(route)+
                    ' · إدارة دورة الإذن بالكامل'+
                  '</div>'+
                '</div>'+

              '</div>'+

              '<div class="flex items-center gap-2">'+

                '<button type="button"'+
                        ' id="wsTopToggle"'+
                        ' aria-expanded="'+
                        (topCollapsed?'false':'true')+
                        '"'+
                        ' onclick="App.toggleTopPanel()"'+
                        ' class="px-3 py-2 rounded-xl bg-slate-800 text-slate-200 text-[10px] font-black">'+
                  '<i class="fa-solid fa-'+
                  (topCollapsed?'chevron-down':'chevron-up')+
                  ' ml-1"></i>'+
                  '<span>'+
                  (topCollapsed?'توسيع الخيارات':'طي الخيارات')+
                  '</span>'+
                '</button>'+

                '<button type="button" onclick="App.clearCart()" class="text-xs text-slate-400">'+
                  'مسح السلة'+
                '</button>'+

              '</div>'+

            '</div>'+

            '<div id="wsRoutePanel" class="'+routeClass+' mt-3">'+
              s.routeHtml()+
            '</div>'+

            '<div id="wsTopPanel" class="'+metaClass+'">'+
              '<div class="grid grid-cols-1 sm:grid-cols-2 gap-2 mt-2">'+
                '<input id="wsRef" class="smart-input" placeholder="المرجع الإجباري">'+
                '<input id="wsNotes" class="smart-input" placeholder="'+
                  (engine?'السبب الإجباري':'ملاحظات (اختياري)')+
                '">'+
              '</div>'+
              (
                engine&&this.type==='Adjustment'
                  ?
                  '<select id="wsMode" class="smart-input mt-2">'+
                    '<option value="replace">تسوية إلى الرصيد الفعلي</option>'+
                    '<option value="add">زيادة</option>'+
                    '<option value="deduct">نقص</option>'+
                  '</select>'
                  :
                  ''
              )+
            '</div>'+

          '</div>'+

          '<div class="ws-grid">'+

            '<section class="catalog">'+

              '<div class="p-3 bg-slate-950 border-b border-slate-800">'+

                '<div class="flex items-center justify-between text-xs text-slate-500">'+
                  '<span>الكتالوج <b id="count"></b></span>'+
                  '<span id="stockHint">اختر المصدر لمعرفة المتاح</span>'+
                '</div>'+

                '<div class="relative mt-3">'+
                  '<input id="wsSearch" autocomplete="off"'+
                    ' oninput="App.search(this.value)"'+
                    ' onkeydown="App.searchKey(event)"'+
                    ' class="dark-input w-full rounded-2xl px-4 py-3.5 text-sm font-bold pr-12 pl-14"'+
                    ' placeholder="🔍 امسح الباركود أو ابحث باسم/كود الصنف... (F2)">'+
                  '<button id="wsScanBtn" type="button" onclick="App.openScanner()"'+
                    ' class="absolute left-2 top-1/2 -translate-y-1/2 w-10 h-10 rounded-xl bg-blue-600 text-white">'+
                    '<i class="fa-solid fa-camera"></i>'+
                  '</button>'+
                  '<i class="fa-solid fa-magnifying-glass absolute right-4 top-1/2 -translate-y-1/2 text-slate-500"></i>'+
                  '<div id="wsResults" class="hidden result-pop"></div>'+
                '</div>'+

                '<div id="wsCats" class="flex gap-2 overflow-x-auto mt-3"></div>'+

              '</div>'+

              '<div id="products" class="flex-1 min-h-0 overflow-y-auto p-3 grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-2"></div>'+

            '</section>'+

            '<aside class="cart">'+

              '<div class="p-3 border-b border-slate-700 bg-slate-900">'+
                '<div class="flex justify-between">'+
                  '<b>🛒 السلة</b>'+
                  '<span id="badge" class="bg-blue-600 px-2 py-1 rounded-full text-[10px]">0</span>'+
                '</div>'+
                '<div id="routeSummary" class="text-[11px] text-slate-500 mt-2"></div>'+
              '</div>'+

              '<div id="cartBox" class="flex-1 min-h-0 overflow-y-auto p-2 space-y-2"></div>'+

              '<div class="p-3 border-t border-slate-700 bg-slate-800">'+
                '<div class="flex justify-between text-xs text-slate-400">'+
                  '<span>عدد الأصناف</span>'+
                  '<b id="cartLines" class="text-white">0</b>'+
                '</div>'+
                '<div class="flex justify-between text-base font-black border-t border-slate-700 pt-2 mt-2">'+
                  '<span>إجمالي الكمية</span>'+
                  '<b id="cartQty" class="text-blue-400">0</b>'+
                '</div>'+
                '<button onclick="App.submit()" class="w-full bg-emerald-600 text-white py-3.5 rounded-2xl font-black mt-3">'+
                  '✓ '+
                  (engine?'تنفيذ الحركة':'حفظ المسودة')+
                '</button>'+
              '</div>'+

            '</aside>'+

          '</div>'+

          '<div class="mobile-bar bg-slate-950 border-t border-slate-700 p-2 gap-2">'+
            '<button onclick="App.openDrawer()" class="flex-1 bg-slate-800 text-white py-3 rounded-2xl font-black">'+
              '🛒 السلة <span id="mcount">0</span>'+
            '</button>'+
            '<button onclick="App.submit()" class="flex-1 bg-emerald-600 text-white py-3 rounded-2xl font-black">✓ حفظ</button>'+
          '</div>'+

          '<div id="drawer" class="mobile-drawer">'+
            '<div class="mobile-inner">'+
              '<div class="p-3 border-b border-slate-700 flex justify-between">'+
                '<b>🛒 السلة</b>'+
                '<button onclick="App.closeDrawer()" class="w-9 h-9 bg-slate-800 rounded-xl">✕</button>'+
              '</div>'+
              '<div id="drawerBox" class="flex-1 overflow-y-auto p-2 space-y-2"></div>'+
              '<div class="p-3 border-t border-slate-700">'+
                '<button onclick="App.closeDrawer();App.submit()" class="w-full bg-emerald-600 text-white py-3 rounded-2xl font-black">حفظ</button>'+
              '</div>'+
            '</div>'+
          '</div>'+

        '</div>';

    RW_UI.safeHTML(
        RW_UI.byId('mainContent'),
        h
    );

    this.renderCats();
    this.renderProducts();
    this.renderCart();
    this.summary();
},
```

### النتيجة

زر الطي الآن يسيطر على:
- Route Context.
- Reference/Notes/Adjustment mode.

مع الحفاظ على:
- `overflow:visible` عندما تكون route controls مفتوحة.
- Smart menus.
- Mobile layout.
- Cart.
- Existing submit actions.

---

# 13. OWNER SURGICAL PATCH V-302-04 — SupplierReturn Empty-State

## الملف

`companies/company-1/warehouse/vouchers.html`

## ابحث عن الدالة الحالية

`pickSearch:function(key,q)`

الموجودة بعد:

`pickShow:function(key){...}`

## احذف الدالة كاملة واستبدلها:

```javascript
pickSearch:function(key,q){
    var s=this,
        arr=this.pickArr(key)||[],
        z=this.norm(q),
        box=RW_UI.byId(key+'Menu');

    if(!box){
        return;
    }

    if(
        s.type==='SupplierReturn' &&
        key==='wsTo' &&
        !arr.length
    ){
        var bid=(RW_UI.byId('wsFrom')||{}).value||'';

        var sourceBranch=
            (s.refs.branches||[]).find(function(b){
                return b.id===bid;
            });

        var branchLabel=
            sourceBranch
                ?(
                    sourceBranch.name||
                    sourceBranch.branch_code||
                    'الفرع المحدد'
                )
                :'الفرع المحدد';

        box.innerHTML=
            '<div class="smart-empty p-3 leading-6">'+
                '<b class="block text-slate-200">لا يوجد موردون مرتبطون بهذا الفرع.</b>'+
                '<span class="block mt-1">لم تثبت قاعدة البيانات علاقة مورد ↔ فرع لـ '+
                s.esc(branchLabel)+
                '. تم حجب الموردين غير المرتبطين حفاظًا على صحة دورة مرتجع المورد.</span>'+
            '</div>';

        box.classList.remove('hidden');

        return;
    }

    var type=
        key==='wsRep'
            ?'rep'
            :(s.type==='DirectSale'&&key==='wsTo')
                ?'vehicle'
                :(s.type==='DirectReturn'&&key==='wsFrom')
                    ?'vehicle'
                    :(key==='wsTo'&&s.type==='SupplierReturn')
                        ?'supplier'
                        :'branch';

    var rows=
        arr
            .map(function(x){

                var a=
                    type==='rep'
                        ?(x.name||x.email||'')
                        :type==='vehicle'
                            ?(x.vehicle_code||x.license_plate||x.model||'')
                            :(x.name||x.supplier_code||x.branch_code||'');

                var b=
                    type==='rep'
                        ?(x.email||x.phone||'')
                        :type==='vehicle'
                            ?(x.license_plate||x.vehicle_code||'')
                            :(x.supplier_code||x.phone||x.branch_code||'');

                var na=s.norm(a);
                var nb=s.norm(b);

                var sc=
                    !z
                        ?1
                        :(na===z||nb===z
                            ?150
                            :(na.indexOf(z)===0||nb.indexOf(z)===0
                                ?115
                                :(na.indexOf(z)>=0||nb.indexOf(z)>=0
                                    ?70
                                    :0
                                )
                            )
                        );

                return {
                    x:x,
                    score:sc
                };

            })
            .filter(function(o){
                return o.score>0;
            })
            .sort(function(a,b){
                return b.score-a.score;
            })
            .slice(0,15);

    box.innerHTML=
        rows.length
            ?
            rows.map(function(o){

                var x=o.x;

                var label=
                    type==='rep'
                        ?(x.name||x.email)
                        :type==='vehicle'
                            ?(x.vehicle_code||x.license_plate||x.model)
                            :(x.name||x.supplier_code||x.branch_code);

                var code=
                    type==='rep'
                        ?(x.email||'')
                        :type==='vehicle'
                            ?(x.license_plate||x.vehicle_code||'')
                            :(x.supplier_code||x.branch_code||'');

                return(
                    '<div class="smart-row" onclick="App.pickSelect(''+
                        s.esc(key)+
                        '',''+
                        s.esc(x.id)+
                    '')">'+

                        '<div>'+
                            '<b class="text-xs text-white">'+
                                s.esc(label)+
                            '</b>'+
                            '<div class="smart-code">'+
                                s.esc(code)+
                            '</div>'+
                        '</div>'+

                        '<span class="text-[9px] text-emerald-400">اختيار</span>'+

                    '</div>'
                );

            }).join('')

            :
            '<div class="smart-empty">لا توجد نتائج مرتبطة بالسياق المحدد</div>';

    box.classList.remove('hidden');
},
```

---

# 14. OWNER SURGICAL PATCH V-302-05 — KPI summary في قائمة الأذونات

## الملف

`companies/company-1/warehouse/vouchers.html`

## ابحث عن

`renderList:function(scope){`

## احذف الدالة كاملة حتى نهاية الدالة قبل:

`filterList:function()`

## استبدلها بالكامل:

```javascript
renderList:function(scope){
    var s=this;

    var typeOptions=[
        '<option value="">كل الأنواع</option>',
        '<option value="Transfer">تحويل مخزني</option>',
        '<option value="DirectSale">صرف سيارة بيع مباشر</option>',
        '<option value="DirectReturn">استلام مرتجع سيارة</option>',
        '<option value="SupplierReturn">مرتجع لمورد</option>'
    ].join('');

    function secondsBetween(a,b){
        var x=Date.parse(a||'');
        var y=Date.parse(b||'');

        if(!Number.isFinite(x)||!Number.isFinite(y)||y<x){
            return null;
        }

        return Math.round((y-x)/1000);
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
            parts=[];

        if(d) parts.push(d+'ي');
        if(h||d) parts.push(h+'س');
        parts.push(m+'د');

        return parts.join(' ');
    }

    var total=this.vouchers.length;

    var draft=this.vouchers.filter(function(v){
        return v.status==='Draft';
    }).length;

    var active=this.vouchers.filter(function(v){
        return v.status==='Sent'||v.status==='Received';
    }).length;

    var completedRows=
        this.vouchers
            .map(function(v){
                return secondsBetween(
                    v.created_at,
                    v.completed_at
                );
            })
            .filter(function(x){
                return x!==null;
            });

    var avgCompleted=
        completedRows.length
            ?
            durationText(
                Math.round(
                    completedRows.reduce(
                        function(a,b){return a+b;},
                        0
                    )/completedRows.length
                )
            )
            :
            '—';

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

        '<div class="grid grid-cols-2 lg:grid-cols-4 gap-2 mb-4">'+

        '<div class="card p-3">'+
            '<span class="block text-[9px] text-slate-400 font-bold">إجمالي السجلات المحملة</span>'+
            '<b class="block text-lg mt-1">'+
                total+
            '</b>'+
        '</div>'+

        '<div class="card p-3">'+
            '<span class="block text-[9px] text-amber-600 font-bold">مسودات</span>'+
            '<b class="block text-lg mt-1 text-amber-700">'+
                draft+
            '</b>'+
        '</div>'+

        '<div class="card p-3">'+
            '<span class="block text-[9px] text-blue-600 font-bold">قيد الدورة</span>'+
            '<b class="block text-lg mt-1 text-blue-700">'+
                active+
            '</b>'+
        '</div>'+

        '<div class="card p-3">'+
            '<span class="block text-[9px] text-emerald-600 font-bold">متوسط زمن الإغلاق</span>'+
            '<b class="block text-sm mt-2 text-emerald-700">'+
                durationText(
                    completedRows.length
                        ?
                        Math.round(
                            completedRows.reduce(
                                function(a,b){return a+b;},
                                0
                            )/completedRows.length
                        )
                        :
                        null
                )+
            '</b>'+
        '</div>'+

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
        '↻ تحديث  '+
        '</button>'+
        '</div>'+
        '</div>'+

        '<div class="text-[10px] text-slate-500 mb-2">'+
            (completedRows.length
                ?
                'متوسط الزمن المبني فقط على الأذونات التي تحتوي created_at + completed_at.'
                :
                'سيظهر متوسط زمن الإغلاق بعد توفر أذونات مكتملة تحمل created_at + completed_at.'
            )+
        '</div>'+

        '<div id="listCards">'+
        this.cards(this.vouchers,scope)+
        '</div>'+

        '</div></div>';

    RW_UI.safeHTML(
        RW_UI.byId('mainContent'),
        h
    );

    this.markSync();
},
```

**ملاحظة:** المتغير `avgCompleted` في الكتلة أعلاه ليس مطلوبًا للعرض المباشر ويمكن حذفه لتقليل الحجم؛ لا يوجد اعتماد خارجي عليه. الأفضل عند تطبيق الدالة حذفه إن أراد المالك تقليل churn.

---

# 15. OWNER SURGICAL PATCH V-302-06 — KPI داخل بطاقة الإذن

## الملف

`companies/company-1/warehouse/vouchers.html`

## ابحث عن

`cards:function(rows,scope){`

## احذف الدالة كاملة حتى قبل:

`loc:function(id,type)`

## استبدلها:

```javascript
cards:function(rows,scope){
    var s=this;

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

        var m=Math.floor(n/60);

        var out=[];

        if(d) out.push(d+'ي');
        if(h||d) out.push(h+'س');
        out.push(m+'د');

        return out.join(' ');
    }

    function dateText(v){
        if(!v){
            return '—';
        }

        var t=parseTs(v);

        if(t===null){
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

    if(!rows.length){
        return(
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
                    '<button onclick="event.stopPropagation();App.send(''+
                    s.esc(v.voucher_code)+
                    '')" class="bg-indigo-600 text-white px-3 py-2 rounded-xl text-xs font-black">إرسال</button>';

                a+=
                    '<button onclick="event.stopPropagation();App.cancel(''+
                    s.esc(v.voucher_code)+
                    '')" class="bg-rose-600 text-white px-3 py-2 rounded-xl text-xs font-black">إلغاء</button>';

            }

            if(act==='receive'){

                a+=
                    '<button onclick="event.stopPropagation();App.receive(''+
                    s.esc(v.voucher_code)+
                    '')" class="bg-emerald-600 text-white px-3 py-2 rounded-xl text-xs font-black">استلام</button>';

            }

            if(act==='complete'){

                a+=
                    '<button onclick="event.stopPropagation();App.complete(''+
                    s.esc(v.voucher_code)+
                    '')" class="bg-violet-600 text-white px-3 py-2 rounded-xl text-xs font-black">إكمال</button>';

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
                custodianText=
                    rep.name||
                    rep.email||
                    '—';
            }
        }

        var endTs=
            v.completed_at||
            v.received_date||
            null;

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

        var lifecycleEnd=
            endTs||
            (
                v.status==='Completed'||v.status==='Cancelled'
                    ?null
                    :new Date().toISOString()
            );

        var lifecycleText=
            endTs
                ?
                durationText(
                    duration(
                        v.created_at,
                        lifecycleEnd
                    )
                )
                :
                durationText(
                    duration(
                        v.created_at,
                        lifecycleEnd
                    )
                );

        return(
            '<div class="card mb-3 cursor-pointer" onclick="App.details(''+
                s.esc(v.voucher_code)+
            '">'+

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

                            '<div class="grid grid-cols-2 lg:grid-cols-4 gap-2 mt-2">'+

                                '<div class="p-2.5 rounded-xl bg-indigo-50 border border-indigo-100">'+
                                    '<span class="block text-[9px] text-indigo-500 font-bold">بداية الإذن</span>'+
                                    '<b class="block text-[10px] mt-1 text-indigo-900">'+
                                        s.esc(dateText(v.created_at))+
                                    '</b>'+
                                '</div>'+

                                '<div class="p-2.5 rounded-xl bg-blue-50 border border-blue-100">'+
                                    '<span class="block text-[9px] text-blue-500 font-bold">بداية التنفيذ</span>'+
                                    '<b class="block text-[10px] mt-1 text-blue-900">'+
                                        s.esc(dateText(v.sent_date))+
                                    '</b>'+
                                '</div>'+

                                '<div class="p-2.5 rounded-xl bg-emerald-50 border border-emerald-100">'+
                                    '<span class="block text-[9px] text-emerald-500 font-bold">النهاية المثبتة</span>'+
                                    '<b class="block text-[10px] mt-1 text-emerald-900">'+
                                        s.esc(dateText(endTs))+
                                    '</b>'+
                                '</div>'+

                                '<div class="p-2.5 rounded-xl bg-violet-50 border border-violet-100">'+
                                    '<span class="block text-[9px] text-violet-500 font-bold">'+
                                        (endTs?'مدة الدورة':'العمر الحالي')+
                                    '</span>'+
                                    '<b class="block text-[10px] mt-1 text-violet-900">'+
                                        s.esc(lifecycleText)+
                                    '</b>'+
                                '</div>'+

                            '</div>'+

                            '<div class="grid grid-cols-1 sm:grid-cols-3 gap-2 mt-2">'+

                                '<div class="text-[9px] text-slate-500 bg-slate-50 rounded-xl px-2.5 py-2">'+
                                    'منشأ → إرسال: <b>'+
                                    s.esc(durationText(createdToSent))+
                                    '</b>'+
                                '</div>'+

                                '<div class="text-[9px] text-slate-500 bg-slate-50 rounded-xl px-2.5 py-2">'+
                                    'إرسال → استلام: <b>'+
                                    s.esc(durationText(sentToReceived))+
                                    '</b>'+
                                '</div>'+

                                '<div class="text-[9px] text-slate-500 bg-slate-50 rounded-xl px-2.5 py-2">'+
                                    'استلام → إكمال: <b>'+
                                    s.esc(durationText(receivedToCompleted))+
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
```

### KPI semantics

- **بداية الإذن** = `created_at`
- **بداية التنفيذ** = `sent_date`
- **النهاية المثبتة** = `completed_at` ثم `received_date` فقط.
- **العمر الحالي** = `now - created_at` للأذونات غير المكتملة.
- لا يتم اعتبار `sent_date` نهاية دورة إلا إذا لم يوجد أي انتقال لاحق؛ ولذلك في البطاقة سيظهر العمر الحالي حتى يوجد `received_date/completed_at`.

---

# 16. ما لم يُعدل عمدًا

لا تعدل:

- `main.html`
- `van-sales.html`
- `loadRefs()`
- `pickArr()` الخاص بالـvehicle
- `pickSelect()` الحالي
- `routeHtml()`
- `submit()`
- `prepare()`
- `handleScan()`
- `details()` المعتمدة بعد Report301
- أي Edge Function جديدة.

الـVehicle / mobile_branch / DirectSale / DirectReturn closures السابقة بقيت كما هي.

---

# 17. لماذا لا نضيف حقولًا تنافسية الآن؟

المقارنة الحديثة مع الأنظمة المنافسة تثبت أهمية:

- تاريخ/وقت المستند.
- From/To.
- الكمية.
- Available Before/After في بعض واجهات الحركة.
- سجل حركة تفصيلي.
- Inventory adjustment/counting.
- Mobile/barcode execution.
- Two-step transfers عند الحاجة إلى stock-in-transit.
- Audit/timeline.

Odoo يدعم Inventory Adjustments وBarcode counting وتعيين مهام الجرد للمستخدمين.  
Dynamics يستخدم Journals للعد والتسوية والتحويل.  
SAP يميز صراحة بين one-step وtwo-step stock transfer، ويستخدم stock-in-transfer عند الحاجة للمراقبة أثناء النقل.  
Daftra يعرض تاريخ ووقت حركة النقل وFrom/To والكمية وAvailable Before/After، كما يوفر تقارير تفصيلية لكل حركة ومصدرها.  
Manager.io يعتمد Date/Reference/Description/Item/Qty/From/To في تحويلات المخزون.

المزايا التالية لا تُضاف في هذه الجلسة لأنها Business Contracts غير مثبتة في RAWAEA الحالي:

- Lot/Serial/Expiry.
- Attachments/evidence.
- Approval workflow مستقل.
- In-transit stock ledger مستقل.
- Supplier branch master جديد.
- Item before/after تاريخي من دون historical valuation contract.

هذه ليست فجوات UI فقط؛ لكل منها أثر Database/Accounting/Authorization يجب فتح Closure Unit مستقل لها إذا تقررت.

---

# 18. التحقق الوظيفي الحالي

## DirectSale
Production موجود بها:
- Branch BR-01.
- Vehicle `VEH-TEST-260921`.
- Mobile branch.
- Direct Sales Representative.
- Item 1001.

DirectSale Production CREATE/SEND سبق إثباته Transactionally في Reports 299/300/301.

## DirectReturn
Production contract:
- Vehicle → Branch.
- SEND يخرج من مخزن السيارة.
- RECEIVE يضيف إلى الفرع.

تم إثبات الدورة Transactionally مع rollback في السجلات السابقة.

## SupplierReturn
قبل QA:
- لا علاقة Supplier↔Branch.
- النتيجة الصحيحة = 0 supplier candidates.

بعد QA:
- `QA-PO-SUPPLIER-LINK-20260922`
- العلاقة أصبحت مثبتة حقيقيًا عن طريق Purchase Order.
- `IN-7` SupplierReturn Draft تم إنشاؤه بنجاح عبر Production RPC.
- هذا يثبت أن server contract وUI source contract متسقان.

---

# 19. E2E — حدود الإثبات

### Production / DB
تم إثبات:
- QA CREATE.
- Operation registry.
- Audit.
- No movement for QA drafts.
- Supplier↔Branch relation.
- VOUCHER_AUDIT KPI response.
- Stock baseline preserved.

### Browser
لم يتم اعتبار Browser E2E = PASS.

السبب:
لم يتم نشر Owner Patch الجديد في `erp-frontend` خلال هذه الجولة، وبالتالي لا توجد مساواة مثبتة بين:
CURRENT SOURCE
و
PUBLISHED ARTIFACT.

---

# 20. سبب الأزمة النهائي

الأزمة ليست خطأ واحدًا.

### السبب الأول
تم إصلاح clipping historically بنقل route controls خارج `wsTopPanel`، لكن toggle لم يُعاد ربطه بالمنطقة الجديدة.

### السبب الثاني
SupplierReturn كان مصممًا Fail-Closed، بينما المستخدم يرى النتيجة كأن البحث أو dropdown معطل.

### السبب الثالث
قاعدة البيانات تحتوي lifecycle timestamps بالفعل، لكن UI لم يحوّلها إلى KPI تشغيلي قابل للقراءة.

### السبب الرابع الذي تمت معالجته في Production
`inventory_control('VOUCHER_AUDIT')` لم يكن يعيد KPI contract موحدًا، فأضيفت طبقة KPI مشتقة دون تغيير الschema.

---

# 21. Gateway / Edge Decision

لا توجد Edge Function جديدة.

القرار:
- استخدام RPC الحالي.
- `inventory_control` هو canonical control/report gateway.
- `post_stock_movement` يبقى Physical Stock Engine.
- التطبيق المنفصل يستمر باستخدام الوظائف الحالية.

هذا يتجاوز سقف عدد Edge Functions دون فتح مسار HTTP جديد.

---

# 22. Production Change Log في هذه الجلسة

### Applied
`voucher_audit_kpi_contract_20260922`

### Canonical Git migration
`20260922104000_voucher_audit_kpi_contract_20260922.sql`

### Persistent QA
- `QA-PO-SUPPLIER-LINK-20260922`
- `IN-5`
- `IN-6`
- `IN-7`

### Not deleted
جميع QA أعلاه مقصود الاحتفاظ بها لجلسات التحقق التالية.

---

# 23. FINAL CLOSURE MATRIX

| Contract / Function | Production | Current Source | Decision |
|---|---:|---:|---|
| Physical Stock centralization | Proven | Preserved | CLOSED |
| DirectSale | Proven | Preserved | CLOSED |
| DirectReturn | Proven | Preserved | CLOSED |
| Vehicle/mobile branch | Proven | Preserved | CLOSED |
| Van Sales integration | Proven | Preserved | CLOSED |
| SupplierReturn server guard | Proven | Preserved | CLOSED |
| SupplierReturn relationship data | QA relation created | Fail-closed preserved | CLOSED FOR CONTRACT |
| Supplier empty-state UX | N/A | Owner patch | OWNER PATCH |
| Top-panel full collapse | N/A | Owner patch | OWNER PATCH |
| Voucher lifecycle KPI | KPI contract live | Owner UI patch | PRODUCTION CLOSED / UI OPEN |
| main.html | untouched | untouched | CLOSED |
| New Edge Function | none | none | CLOSED |
| Browser authenticated E2E | not proven | not deployed | OPEN |

---

# 24. PRE-SWEEP SELF-AUDIT

### Confirmed Facts
- Current system HEAD and parent verified.
- Current frontend HEAD and parent verified.
- Current vouchers blob verified.
- Current main blob verified.
- Current Van Sales blob verified.
- Current Production Supplier verified.
- Current Production Branch verified.
- Current Production Vehicle and Rep verified.
- Current SupplierReturn server guard verified.
- Current Purchase Order relation was absent before QA.
- QA Purchase Order created and retained.
- DirectSale QA created.
- DirectReturn QA created.
- SupplierReturn QA created.
- No Physical Stock movement generated by QA.
- KPI contract deployed in Production.
- VOUCHER_AUDIT returned KPI successfully.
- No new Edge Function created.

### Unknowns
- Published browser artifact after owner source patch.
- Authenticated Browser E2E after that deployment.

### Conflicts resolved
- Old report values were superseded by current Production.
- Historical clipping fix is preserved and not re-applied.
- Historical vehicle picker repair is preserved and not re-applied.

### Unverified Claims
لا توجد دعوى Production غير مثبتة ضمن هذه الجولة بخلاف Browser runtime.

---

# 25. FINAL SELF-AUDIT

## What was proved
1. Current Git.
2. Current parent.
3. Current Source.
4. Current Production.
5. Current database contract.
6. Current Van Sales integration.
7. Current SupplierReturn contract.
8. Actual SupplierReturn relation behavior.
9. Production KPI capability.
10. No Physical Stock mutation from QA data.

## What was fixed
### Production
- Added canonical Voucher lifecycle KPI response to `inventory_control('VOUCHER_AUDIT')`.
- Kept all existing response fields.
- No new Edge Function.
- No new table.
- No new column.

### Data
- Added persistent QA PO.
- Added persistent QA DirectSale/DirectReturn/SupplierReturn drafts.

### Owner source patch prepared
- Full top panel collapse.
- SupplierReturn relationship-aware empty state.
- KPI summary.
- KPI lifecycle data in voucher cards.

## What was intentionally not fixed
- Closed Vehicle Picker patches.
- Closed clipping source patch.
- Closed DirectSale/DirectReturn backend paths.
- Van Sales.
- main.html.

## What could still be wrong
Only:
- owner source application;
- frontend deployment;
- authenticated browser runtime.

---

# 26. تعليمات الاستكمال للمساعد التالي

ابدأ بالترتيب التالي:

1. اقرأ CURRENT_STATE.
2. تحقق من System HEAD وFrontend HEAD.
3. تحقق من `vouchers.html` blob قبل أي edit.
4. تحقق من Production counts وQA:
   - QA-PO-SUPPLIER-LINK-20260922
   - IN-5
   - IN-6
   - IN-7
5. لا تعيد Vehicle Picker.
6. لا تعيد clipping repair التاريخي.
7. طبّق فقط:
   - V-302-01
   - V-302-02
   - V-302-03
   - V-302-04
   - V-302-05
   - V-302-06
8. شغّل static parse.
9. انشر frontend.
10. نفذ Browser E2E:
    - Login
    - Warehouse
    - Stock Vouchers
    - New Voucher
    - DirectSale
    - collapse/expand
    - supplier search
    - DirectReturn
    - SupplierReturn
    - save draft
11. بعد E2E خذ Production snapshot جديد في نفس لحظة التقرير.
12. لا تعتبر Browser closure قبل إثبات artifact identity.
13. لا تنشئ Edge Function جديدة.

---

# 27. المصادر التنافسية الرسمية

Odoo:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/barcode/operations/adjustments.html

Dynamics 365:
https://learn.microsoft.com/en-us/dynamics365/business-central/inventory-how-count-adjust-reclassify
https://learn.microsoft.com/en-us/dynamics365/finance/general-ledger/inventory-posting

SAP:
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/91b21005dded4984bcccf4a69ae1300c/9e64bd534f22b44ce10000000a174cb4.html
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/91b21005dded4984bcccf4a69ae1300c/bf64bd534f22bd534a424de10000000a174cb4.html

Daftra:
https://docs.daftra.com/en/tutorial/transferring-stock/
https://docs.daftra.com/en/tutorial/inventory-detailed-transactions-report/

Manager.io:
https://www2.manager.io/guides/10707

---

# END OF REPORT 302
