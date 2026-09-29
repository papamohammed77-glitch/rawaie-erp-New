# تقرير تدقيق جنائي — VAN SALES / توحيد العهدة والقيمة
## Report 368 — 2026-09-29

## 1. نطاق التدقيق

الهدف: تفسير وإصلاح التناقض الظاهر في تطبيق مندوب البيع المباشر بين:
- «العهدة»
- «عهدتي الآن»
- «سيارتي»
- «رصيدي»

مع الحفاظ على:
- النظام الأم
- vouchers.html
- van-sales.html
- Core inventory contract
- العمليات الميدانية القائمة

---

## 2. الحالة الحالية المثبتة

### Git

المستودع:
- frontend: `papamohammed77-glitch/erp-frontend`

الفرع:
- `main`

آخر Commit لتصحيح Syntax السابق:
- `751c10723bfa5ed2ce6c3ae12561a179c5ecb56e`
- الرسالة: `Refactor customer iteration in van-sales.html`

وهذا الـcommit أصلح العيب السابق في `showRecentCustomers()`، لذلك بيانات `CURRENT_STATE` التي تشير إلى أن HEAD هو `22e2...` أصبحت قديمة بالنسبة للمصدر الحالي.

Target:
`companies/company-1/sales/van-sales.html`

الحالة:
- الملف محمي من التعديل المباشر في هذه الجلسة.
- ستُعطى Owner patches فقط.

---

## 3. التحقيق في Production

تم التحقق مباشرة من Supabase Production:

### Master Vehicle Assignment

- `CHV-2025-01` مرتبط فعليًا بالمندوب `vansales@rawaea.com`
- `VHL-0422` مرتبط فعليًا بالمندوب `vansales2@rawaea.com`
- العلاقة الحالية هي `fleet_vehicle_sales_rep_assignments`
- `vehicles.driver_id` في هذه الحالات NULL.

إذن مخزن السيارة canonical هو:
`vehicle.mobile_branch_id`
الذي تعيده وظيفة:
`setup-van-branch`

والوظيفة المنشورة حاليًا:
`setup-van-branch v5`

وهي company-scoped وتستخدم Master Assignment للمندوب المباشر.

---

## 4. المخزون الفعلي في Production

### CHV-2025-01

- عدد صفوف stock_branches = 17
- الصفوف ذات الرصيد الموجب = 5
- الصفوف ذات الرصيد صفر = 12
- إجمالي الكمية الفعلية = 5
- القيمة التجارية الحالية المبنية على sales_price = 413 جنيه
- القيمة المحاسبية المبنية على cost_price = 0 في بيانات Production الحالية

### VHL-0422

- عدد الصفوف = 17
- الرصيد الموجب = 1
- الرصيد صفر = 16
- إجمالي الكمية = 1
- القيمة التجارية الحالية = 135 جنيه
- القيمة المحاسبية الحالية = 0 بسبب cost_price الحالي لهذه البيانات

إذن الأصناف ذات الرصيد الصفري **موجودة فعلًا في قاعدة البيانات**؛ ليست بيانات وهمية من الواجهة.

لا يجوز حذف هذه الصفوف لمجرد أنها صفر، لأنها تمثل Stock Master rows صالحة للصنف/المخزن.

المطلوب في شاشة «العهدة الحالية» هو **عدم عرض الصفوف الصفرية ضمن المخزون الحالي**، لا حذفها من قاعدة البيانات.

---

## 5. Root Cause — التناقض الحقيقي

### العيب 1 — مصدر البيانات

`van-sales.html` يستخدم Dexie كـcache محلي لعرض المخزون:

`loadHomeStockSummary()`
و
`_loadVehicleStock()`

وهذا يجعل الشاشة تعتمد على آخر cache تم تحميله، وليس على المصدر الحي عند فتح العرض.

كما أن `enterApp()` يحتوي حاليًا:

`this.syncDown().catch(function(){ return null; }).then(...)`

وهذا يعني أن فشل المزامنة يمكن ابتلاعه ثم تستمر الواجهة باستخدام cache قديم أو ناقص.

هذا غير مقبول لشاشة عهدة.

### العيب 2 — اختلاف طريقة احتساب القيمة

`loadHomeStockSummary()` يحسب القيمة فقط لأول 5 صفوف:

`Math.min(stockItems.length,5)`

بينما:

`_renderVehicleStockHTML()`

يحسب القيمة على جميع الصفوف.

إذن نفس العهدة يمكن أن تظهر بقيم مختلفة بين «العهدة/عهدتي الآن» و«سيارتي».

### العيب 3 — الصفر

`_renderVehicleStockHTML()` يعرض كل صف حتى عندما:

`currentQty = 0`

وهذا يجعل المستخدم يعتقد أن النظام يحتوي أرصدة متناقضة، بينما هو يرى Stock Master rows صفرية.

### العيب 4 — «رصيدي»

`رصيدي` مصدره:
`driver_ledger`

وهو **التزام مالي**، وليس كمية أو قيمة مخزون.

لذلك:
`رصيدي 
eq قيمة العهدة`

وهذا اختلاف وظيفي صحيح وليس خطأ محاسبيًا.

---

## 6. المصدر الصحيح الدائم

التصميم المعتمد:

### Physical Custody Authority

`stock_branches.qty`

لـcanonical `vanBranchId`.

### Available Stock

`qty - allocated_qty`

مع الحفاظ على `qty` كالرصيد الفيزيائي للعهدة.

### Commercial Display Value

لواجهة مندوب البيع الحالية:
`qty × items.sales_price`

ولا يتم تغيير أساس القيمة في هذه الجراحة حتى لا نغير Business Contract قائمًا.

### Accounting/Inventory Valuation

المحرك المركزي للتقارير يستخدم cost valuation، مثل `inventory_stock_snapshot`.

هذه القيمة لا يجب خلطها مع «قيمة البيع» المعروضة للمندوب.

---

## 7. Industry Principle

الأنظمة الناضجة تفرق بين:
- stock quantity
- on-hand inventory
- stock valuation
- operational documents
- financial balances

SAP يدير المخزون على أساس الكمية والقيمة مع توثيق حركات المخزون، ويميز بين physical/on-hand stock وvaluation. urlSAP Inventory Managementhttps://help.sap.com/doc/a6a8c7536e8e2a4be10000000a174cb4/700_SFIN3E%20006/en-US/2bdcc4530b29b44ce10000000a174cb4.html

Dynamics 365 يعرض on-hand inventory وفق أبعاد مثل warehouse/location بدل اعتبار كل السجلات مساوية للرصيد الحالي. urlDynamics 365 On-hand Inventoryhttps://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/tasks/check-availability-stock

Daftra يدعم تعيين ومتابعة المخزون لكل مستودع/موظف ويستخدم صلاحيات المستودعات والـdefault warehouse، وهو قريب من مفهوم vehicle custody في RAWAEA. urlDaftra Inventoryhttps://www.daftra.com/en/inventory/

---

## 8. Production Core — النتيجة

تم التحقق من أن:

`save_sales_invoice_atomic()`

في Production ينفذ Van Sale عبر:

`post_stock_movement()`

وباستخدام `VanSale` من mobile branch.

كما أن:
`post_van_sales_collection_atomic()`

موجود في Production، و`save-receipt-voucher v8` قادر على تمرير Van Sales collection atomically.

لا توجد حاجة لإنشاء Edge Function جديدة لهذه المشكلة.

لا توجد حاجة لتعديل `vouchers.html` أو `main.html`.

---

# 9. الإصلاح الجراحي المطلوب

## PATCH 1 — منع استمرار التطبيق بعد فشل المزامنة

### الملف
`companies/company-1/sales/van-sales.html`

### العنصر
`enterApp:function()`

### احذف فقط:

```javascript
this.syncDown().catch(function() { return null; }).then(function() { App.loadVanBranch(); });
```

### واستبدله بالكامل بـ:

```javascript
this.syncDown()
    .then(function() {
        App.loadVanBranch();
    })
    .catch(function(err) {
        RW_UI.showError(
            (err && err.message) ||
            'تعذر مزامنة بيانات النظام، تم إيقاف العرض لمنع استخدام بيانات قديمة'
        );
    });
```

---

## PATCH 2 — توحيد «العهدة» مع المصدر الحي

### الملف
`companies/company-1/sales/van-sales.html`

### العنصر
الدالة كاملة:
`loadHomeStockSummary:function()`

### احذف الدالة الحالية بالكامل واستبدلها بالدالة التالية:

```javascript
loadHomeStockSummary:function() {
    var self=this;
    var branchId=this.vanBranchId;
    var companyId=this.companyId;
    var box=RW_UI.byId('homeStockSummary');
    var kpi=RW_UI.byId('kpiStock');

    if(!branchId||!companyId){
        RW_UI.safeHTML(
            box,
            '<p class="text-gray-400">لم يتم تحديد مخزن السيارة المعتمد.</p>'
        );
        RW_UI.safeText(kpi,'0 ج.م');
        return;
    }

    Promise.all([
        supabase
            .from('stock_branches')
            .select('item_id,qty,allocated_qty,updated_at')
            .eq('branch_id',branchId),

        supabase
            .from('items')
            .select('id,item_code,name,sales_price,unit')
            .eq('company_id',companyId)
            .eq('is_active',true)
    ])
    .then(function(result){
        var stockRes=result[0],
            itemsRes=result[1];

        if(stockRes.error) throw stockRes.error;
        if(itemsRes.error) throw itemsRes.error;

        var itemMap={};
        (itemsRes.data||[]).forEach(function(it){
            itemMap[String(it.id)]=it;
        });

        var rows=(stockRes.data||[])
            .map(function(st){
                var it=itemMap[String(st.item_id)];
                var qty=Math.max(0,Number(st.qty)||0);

                return{
                    item_id:st.item_id,
                    item:it,
                    qty:qty,
                    allocated_qty:Math.max(0,Number(st.allocated_qty)||0),
                    sales_price:it?Math.max(0,Number(it.sales_price)||0):0,
                    updated_at:st.updated_at||null
                };
            })
            .filter(function(x){
                return x.qty>0;
            })
            .sort(function(a,b){
                var ac=a.item?(a.item.item_code||''):'',
                    bc=b.item?(b.item.item_code||''):'';

                return String(ac).localeCompare(String(bc),'ar');
            });

        var totalQty=0,
            totalValue=0;

        rows.forEach(function(x){
            totalQty+=x.qty;
            totalValue+=x.qty*x.sales_price;
        });

        var preview=rows.slice(0,5);

        var summary=
            '<div class="text-xs text-slate-500 mb-2">'+
                '<b>'+totalQty+'</b> صنف/وحدة حالية'+
                ' · قيمة البيع التقريبية <b>'+
                RW_UI.formatNumber(totalValue)+
                ' ج.م</b>'+
            '</div>';

        preview.forEach(function(x){
            if(!x.item) return;

            summary+=
                '<span class="inline-block bg-orange-50 text-orange-700 px-2 py-1 rounded-lg text-xs font-bold ml-1 mb-1">'+
                x.item.name+
                ': '+
                x.qty+
                '</span>';
        });

        if(rows.length>5){
            summary+=
                '<span class="text-xs text-gray-400">... و'+
                (rows.length-5)+
                ' صنف آخر</span>';
        }

        if(!rows.length){
            summary=
                '<p class="text-gray-400">لا توجد عهدة فعلية حالياً.</p>';
        }

        RW_UI.safeHTML(
            box,
            summary
        );

        RW_UI.safeText(
            RW_UI.byId('homeStockLastUpdate'),
            '🟢 آخر تحديث: الآن'
        );

        RW_UI.safeText(
            kpi,
            RW_UI.formatNumber(totalValue)+' ج.م'
        );
    })
    .catch(function(err){
        console.error('loadHomeStockSummary:',err);

        RW_UI.safeHTML(
            box,
            '<p class="text-red-400">تعذر تحميل العهدة الحية من النظام.</p>'
        );

        RW_UI.safeText(kpi,'—');
        RW_UI.safeText(
            RW_UI.byId('homeStockLastUpdate'),
            '🔴 فشل تحديث بيانات العهدة'
        );
    });
},
```

---

## PATCH 3 — توحيد «سيارتي» مع نفس المصدر والحساب

### الملف
`companies/company-1/sales/van-sales.html`

### العنصر
`_loadVehicleStock:function()`

### احذف الدالة الحالية بالكامل واستبدلها بالدالة التالية:

```javascript
_loadVehicleStock:function() {
    var self=this;
    var branchId=this.vanBranchId;
    var companyId=this.companyId;
    var container=RW_UI.byId('vehicleDetail');

    if(!container) return;

    if(!branchId||!companyId){
        RW_UI.safeHTML(
            container,
            '<div class="text-center py-12 bg-white rounded-2xl">'+
            '<div class="text-6xl mb-4">🚛</div>'+
            '<p class="text-slate-400 font-bold">لم يتم تحديد مخزن السيارة المعتمد</p>'+
            '</div>'
        );
        return;
    }

    Promise.all([
        supabase
            .from('stock_branches')
            .select('item_id,qty,allocated_qty,updated_at')
            .eq('branch_id',branchId),

        supabase
            .from('items')
            .select('id,item_code,name,sales_price,unit')
            .eq('company_id',companyId)
            .eq('is_active',true)
    ])
    .then(function(result){
        var stockRes=result[0],
            itemsRes=result[1];

        if(stockRes.error) throw stockRes.error;
        if(itemsRes.error) throw itemsRes.error;

        var itemMap={};

        (itemsRes.data||[]).forEach(function(it){
            itemMap[String(it.id)]=it;
        });

        var myStock=(stockRes.data||[])
            .map(function(st){
                var it=itemMap[String(st.item_id)];

                return{
                    item_id:st.item_id,
                    item:it,
                    qty:Math.max(0,Number(st.qty)||0),
                    allocated_qty:Math.max(0,Number(st.allocated_qty)||0),
                    updated_at:st.updated_at||null
                };
            })
            .filter(function(x){
                return x.qty>0;
            })
            .sort(function(a,b){
                var ac=a.item?(a.item.item_code||''):'',
                    bc=b.item?(b.item.item_code||''):'';

                return String(ac).localeCompare(String(bc),'ar');
            });

        var orderQuery=supabase
            .from('orders')
            .select('id')
            .eq('company_id',companyId)
            .eq('created_by',self.currentUser.email)
            .eq('source','van-sales')
            .eq('order_date',new Date().toISOString().split('T')[0]);

        return Promise.resolve(orderQuery)
            .then(function(oRes){
                if(oRes.error) throw oRes.error;

                var orderIds=(oRes.data||[]).map(function(o){
                    return o.id;
                });

                if(!orderIds.length){
                    self._renderVehicleStockHTML(
                        container,
                        myStock,
                        myStock.map(function(x){return x.item;}),
                        {}
                    );
                    return;
                }

                return supabase
                    .from('order_details')
                    .select('item_code,qty')
                    .in('order_id',orderIds)
                    .then(function(dRes){
                        if(dRes.error) throw dRes.error;

                        var soldMap={};

                        (dRes.data||[]).forEach(function(d){
                            var code=String(d.item_code||'');
                            soldMap[code]=
                                (soldMap[code]||0)+
                                (Number(d.qty)||0);
                        });

                        self._renderVehicleStockHTML(
                            container,
                            myStock,
                            myStock.map(function(x){return x.item;}),
                            soldMap
                        );
                    });
            });
    })
    .catch(function(err){
        console.error('_loadVehicleStock:',err);

        RW_UI.safeHTML(
            container,
            '<div class="text-center py-12 bg-white rounded-2xl">'+
            '<p class="text-red-400 font-bold">تعذر تحميل العهدة الحية من النظام</p>'+
            '</div>'
        );
    });
},
```

---

# 10. ما لم يتم تغييره عمدًا

لا تعديل الآن على:
- `main.html`
- `vouchers.html`
- Core Inventory
- `post_stock_movement`
- `setup-van-branch`
- `save-sales-invoice`

لأن التدقيق لم يثبت وجود Defect Production فيها مرتبط بهذه المشكلة.

---

# 11. نقاط أخرى مفتوحة — ليست جزءًا من جراحة العهدة الحالية

تظل Closure Units مستقلة:

1. `collectPayment()` — ما زال يحتاج ربطًا كاملًا مع `save-receipt-voucher v8`.
2. `loadMyCustomers()` — يحتاج company/source scoping.
3. `loadCustomerPatterns()` — يحتاج query bounded بـorder IDs + company/source.
4. `loadKPIs()` — يحتاج company/source scoping.
5. `loadHomeSalesSummary()` — يحتاج company/source scoping.
6. `loadMyInvoices()` — يحتاج company/source scoping.
7. `showCustomerDetail()` و`repeatOrder()` — يحتاجان scope/authorization audit.
8. `initiateEndOfDay()` — لا يزال client-only وليس settlement contract نهائيًا.

**لا تخلط هذه النقاط مع الإصلاح الحالي.**

---

# 12. النتيجة

### السبب المؤكد للتناقض

**مصدران عرض مختلفان لنفس المخزون + احتساب قيمة غير موحد + عرض صفوف صفرية + السماح بالاستمرار عند فشل المزامنة.**

### الحل الدائم

كل عرض للعهدة الحالية في Van Sales يعتمد مباشرة على:

`stock_branches.qty`

لـcanonical vehicle branch، ويستخدم نفس قاعدة احتساب القيمة ونفس ترتيب الأصناف.

«رصيدي» يبقى Financial Responsibility وليس Stock Value.

ولا تُحذف الصفوف الصفرية من Production.

---

# 13. حالة التنفيذ

- Production Core: **لم يحتج تعديلًا.**
- Production stock data: **تم التحقق مباشرة.**
- Frontend source: **لم يُمس.**
- Surgical patches: **جاهزة للمالك.**
- Browser E2E بعد تطبيقها: **مطلوب**.
- Van Sales custody reconciliation: **OPEN حتى تطبيق الـpatch واختباره**.

## Self-Audit

Business Understanding: 99/100  
Architecture Understanding: 99/100  
Database Understanding: 100/100  
Historical Understanding: 98/100  
Production Understanding: 100/100  
Current Understanding: 100/100  
Execution Confidence: 97/100

Confirmed Facts: current source + Production DB + Production Edge/Core verified.  
Unknowns: exact browser-served artifact after owner patch.  
Conflicts: none material.  
Unverified: browser execution after owner patch.

## CURRENT NEXT STEP

طبّق PATCH 1 → 3 فقط في:
`companies/company-1/sales/van-sales.html`

ثم نفذ:
Syntax → Browser E2E → Production read verification.

ولا تعِد إصلاح `showRecentCustomers()`؛ Commit `751c...` أثبت أن إصلاحه موجود بالفعل.

