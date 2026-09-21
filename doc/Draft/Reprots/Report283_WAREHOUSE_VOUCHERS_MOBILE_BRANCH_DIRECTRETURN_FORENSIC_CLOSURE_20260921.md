# تقرير 283 — الإغلاق الجنائي لتكامل الأذونات المخزنية مع مخزن السيارة / DirectReturn

التاريخ: 2026-09-21
النطاق: `erp-frontend/companies/company-1/warehouse/vouchers.html` + Production Voucher RPCs + التكامل مع Van Sales
الحالة: **Production backend closure executed; owner-only frontend patch prepared; Browser E2E الحقيقي ما زال مشروطًا بوجود Vehicle تشغيلية في Production.**

---

## 1. قاعدة العمل الحاكمة

تم تنفيذ هذه الجلسة من آخر حالة مثبتة فقط، وفق التسلسل:

CURRENT GIT
→ CURRENT SOURCE
→ CURRENT PRODUCTION
→ HISTORICAL CONTRACT
→ CURRENT GAP
→ SURGICAL FIX
→ PRODUCTION VERIFICATION
→ SOURCE RECORD
→ CURRENT STATE

لم يتم:
- تعديل `main.html`
- تعديل `erp-frontend/companies/company-1/warehouse/vouchers.html`
- إنشاء Edge Function جديدة
- إعادة تنفيذ closures المغلقة سابقًا.

التقارير السابقة استُخدمت كمرجع تاريخي فقط، وتمت مطابقتها مع Production وCurrent Source.

---

## 2. GIT baseline الحالي

System repository:
`papamohammed77-glitch/rawaie-erp-New`

HEAD عند بداية الجلسة:
`5423e5d0031d996090832526fd3a23d6add0d867`

Parent المباشر:
`c6588b66f9a9fb22a1f23ea4302f65960d0a3ab2`

ثم:
`be90d75b8e4a19500bc080d200dab54a6b21e7a4`

ثم:
`740a1c37c31fe608f9fdf91fe813f5d0b7e9f512`

Mother repository:
`papamohammed77-glitch/erp-frontend`

Target vouchers file current blob بعد إعادة الفحص:
`5eea64c53a344f588c8035dc278d559d2be1b242`

Target van-sales file:
`companies/company-1/sales/van-sales.html`

Van Sales current source closure from previous session was **not reopened**.

---

## 3. CURRENT PRODUCTION snapshot

Supabase project:
`fiilmooggumokxanwiyx`

بعد جميع اختبارات هذه الجلسة:

- companies = 1
- branches = 2
- vehicles = 0
- stock_vouchers = 0
- stock_voucher_details = 0
- inventory_log = 3
- orders = 0

لا توجد سجلات اختبار دائمة جديدة في:
- stock_vouchers
- stock_voucher_details
- vehicles
- orders

السجل التاريخي الموجود في audit_log يثبت أن اختبارات سابقة تمت ثم حُذفت/أعيدت Production إلى baseline؛ لم يتم التعامل مع ذلك كسجل تشغيلي حالي.

---

## 4. Historical Business Contract للأذونات

ملف المرجع التاريخي:

`rawaie-erp-review/Architecture/الأذونات المخزنية اليدوية.md`

الأنواع التاريخية:

1. Transfer
2. DirectSale
3. DirectReturn
4. SupplierReturn
5. Scrap
6. Adjustment

العقد التشغيلي:

### DirectSale
فرع المخزن
→ مندوب البيع المباشر
→ Vehicle Mobile Stock

وهو **صرف عهدة** وليس Order.

### DirectReturn
Vehicle Mobile Stock
→ الفرع

وهو مرتجع ميداني مباشر مستقل عن Order/Runsheet.

### Voucher identity
العقد التاريخي يميز بين:
- `voucher_code`: كود/رقم الإذن الداخلي
- `reference`: المرجع اليدوي الخارجي

وبالتالي لا يوجد أساس صحيح لدمج الاثنين في هوية واحدة.

---

## 5. ما الذي يفعله التطبيق الحالي فعلًا

الملف:

`erp-frontend/companies/company-1/warehouse/vouchers.html`

المسار الحالي:

- يستقبل سياق الشركة من التطبيق
- يقرأ الفروع
- يقرأ المركبات
- يقرأ المندوبين
- يقرأ الموردين
- يعرض الأذونات اليدوية
- ينشئ الإذن عبر:
  `create-stock-voucher`
- يرسل عبر:
  `send-stock-voucher`
- يستلم عبر:
  `receive-stock-voucher`
- يكمل/يلغي عبر الـRPCs الحالية
- يقرأ التدقيق والحركات عبر:
  `inventory_control / VOUCHER_AUDIT`

Physical Stock لا يُنفذ من JavaScript مباشرة؛ العقد الحالي يعتمد على:

`post_stock_movement`
→ `stock_branches`
+
`inventory_log`

وهذا هو الـcore المركزي المثبت.

---

## 6. التحقيق الجنائي — السبب الأول

### العيب

الدالة:

`loadRefs:function()`

في:
`companies/company-1/warehouse/vouchers.html`

السطر الحالي:
**27**

تقرأ المركبات هكذا:

`id,vehicle_code,license_plate,model,driver_id,status`

ولا تقرأ:

`mobile_branch_id`
`mobile_stock_enabled`

كما أن الفروع لا تحمل في الـfrontend:
`company_id`
`is_active`

### الأثر

Production انتقل إلى:
`vehicles.mobile_branch_id`

بينما الواجهة بقيت تقرأ البنية القديمة.

---

## 7. التحقيق الجنائي — السبب الثاني

العنصر:

`vehicleBranch:function(v)`

في السطر:
**504**

كان يعتمد حصريًا على:

`VAN-${vehicle_code}`

بينما العقد الحالي في Production هو:

`vehicles.mobile_branch_id`

مع fallback تاريخي إلى:
`VAN-vehicle_code`

إذن:
**Production canonical identity ≠ current frontend lookup**

وهذه هي فجوة التكامل الفعلية.

---

## 8. التحقيق الجنائي — السبب الثالث

العنصر:

`pickArr:function(key)`

في السطر:
**505**

في DirectSale كان يشترط:

`s.allowedBranch(s.user,vb)`

أي أن المستخدم المخزني يجب أن يمتلك صلاحية على **فرع مخزن السيارة نفسه**.

هذا لا يطابق العقد التشغيلي الحالي:

أمين مخزن الفرع
→ يصرف العهدة إلى السيارة.

صلاحية أمين المخزن يجب أن تُحسم على **فرع العملية المصدر** في DirectSale.

وفي DirectReturn:

أمين مخزن الفرع
← يستلم المرتجع من السيارة.

الحارس المركزي النهائي تم تصحيحه ليحسم صلاحية المستخدم على **فرع الاستلام** وليس على مخزن السيارة.

---

## 9. التحقيق الجنائي — السبب الرابع والأكثر خطورة

Production function:

`send_stock_voucher_atomic_core_20260828`

كان يحتوي حرفيًا على:

`WHERE mb.id=v.mobile_branch_id`

داخل:

`FROM public.vehicles v_vehicle`

الصحيح:

`WHERE mb.id=v_vehicle.mobile_branch_id`

هذا هو **الـruntime exception الحقيقي** الذي ظهر أثناء E2E.

هذا الخطأ ليس Business Rule.
ليس صلاحية.
ليس frontend.
إنه **متغير Alias خاطئ داخل SQL core**.

الخطأ المثبت كان:

`missing FROM-clause entry for table "v"`

في مسار Vehicle source.

---

## 10. Production fixes التي تم تنفيذها

### Migration 1

`20260921094116_vouchers_directreturn_send_authorization_branch_20260921`

تم تعديل الـwrapper:

`send_stock_voucher_atomic`

السلوك النهائي:

- DirectReturn + destination Branch:
  - authorization branch = destination Branch
- باقي العمليات:
  - authorization branch = source operational Branch

مع الحفاظ على:

- OWNER wildcard
- company scope
- branch scope
- existing core
- existing Edge Functions

### Migration 2

`20260921094210_vouchers_directreturn_vehicle_mobile_branch_core_fix_20260921`

تم إصلاح alias فقط:

`v.mobile_branch_id`
→
`v_vehicle.mobile_branch_id`

داخل Vehicle source resolution.

لم يتغير:
- movement model
- idempotency
- status transitions
- stock writer contract
- DirectReturn two-stage model

---

## 11. لماذا لم ننشئ Edge Function جديدة

Edge Functions الحالية تكفي:

- create-stock-voucher
- send-stock-voucher
- receive-stock-voucher

وهي تعمل فوق RPCs الحالية.

لذلك تم تجاوز حد gateway/spend-cap من خلال:
**تطوير الـRPC الموجود بدل إنشاء Edge جديدة.**

لا توجد حاجة لتوسيع عدد الـFunctions.

---

## 12. E2E — Production RPC only

تم إنشاء بيانات مؤقتة داخل Transaction:

- Vehicle
- Mobile Branch
- Driver
- مصدر Stock

ثم:

### DirectSale

`Branch → Vehicle`

تم التحقق من:

- إنشاء الإذن
- إرسال الإذن
- خصم المصدر
- زيادة Mobile Stock
- كتابة Inventory Log

### DirectReturn

`Vehicle → Branch`

تم التحقق من:

- إنشاء الإذن
- إرسال الإذن
- حل Vehicle Mobile Branch
- خصم Mobile Stock
- RECEIVE إلى الفرع
- إعادة نفس RECEIVE operation_id

والنتيجة:

`duplicate = true`

في retry.

### Final assertions

- Main branch رجع إلى نفس الرصيد المتوقع بعد عكس الاختبار
- Vehicle branch رجع إلى صفر من أثر الاختبار
- Inventory log المؤقت لم يُترك
- Transaction تم عمل ROLLBACK لها كاملة

Production بعد الاختبار:

`stock_vouchers = 0`
`stock_voucher_details = 0`
`vehicles = 0`
`orders = 0`
`inventory_log = 3`

---

# 13. Surgical Owner Patch — vouchers.html فقط

## PATCH 1 — loadRefs

الملف:
`erp-frontend/companies/company-1/warehouse/vouchers.html`

ابحث تحديدًا عن:

`loadRefs:function(){var s=this;return Promise.all([supabase.from('branches').select('id,branch_code,name')...`

وهو عند:
**line 27**

احذفه كاملًا واستبدله بالدالة التالية:

~~~javascript
loadRefs:function(){
    var s=this;

    return Promise.all([
        supabase
            .from('branches')
            .select('id,branch_code,name,company_id,is_active')
            .eq('company_id',s.company)
            .eq('is_active',true)
            .order('name'),

        supabase
            .from('vehicles')
            .select('id,vehicle_code,license_plate,model,driver_id,status,mobile_branch_id,mobile_stock_enabled')
            .eq('company_id',s.company)
            .eq('status','Active')
            .order('vehicle_code'),

        supabase
            .from('suppliers')
            .select('id,supplier_code,name,phone,is_active')
            .eq('company_id',s.company)
            .eq('is_active',true)
            .order('name'),

        supabase
            .from('users')
            .select('id,name,email,phone,role,status,default_branch_id,allowed_branch_ids')
            .eq('company_id',s.company)
            .eq('status','Active')
            .eq('role','مندوب بيع مباشر')
            .order('name'),

        supabase
            .from('purchase_orders')
            .select('supplier_id,branch_id')
            .eq('company_id',s.company)
            .not('supplier_id','is',null)
    ])
    .then(function(r){

        for(var i=0;i<r.length;i++){
            if(r[i].error){
                throw r[i].error;
            }
        }

        s.refs.branches=r[0].data||[];
        s.refs.vehicles=r[1].data||[];
        s.refs.suppliers=r[2].data||[];
        s.refs.reps=r[3].data||[];

        s.refs.supplierBranchMap={};

        (r[4].data||[]).forEach(function(x){

            if(x.supplier_id&&x.branch_id){

                (s.refs.supplierBranchMap[x.branch_id]||
                    (s.refs.supplierBranchMap[x.branch_id]={})
                )[x.supplier_id]=1;
            }
        });

        return s.refs;
    });
},
~~~

---

# 14. PATCH 2 — vehicleBranch

الملف:
`erp-frontend/companies/company-1/warehouse/vouchers.html`

ابحث تحديدًا عن العنصر:

`vehicleBranch:function(v){if(!v)return null;var code='VAN-'+String(v.vehicle_code||'').trim().toUpperCase();return(this.refs.branches||[]).find(function(b){return String(b.branch_code||'').trim().toUpperCase()===code})||null},`

الموضع:
**line 504**

احذفه كاملًا واستبدله:

~~~javascript
vehicleBranch:function(v){
    if(!v){
        return null;
    }

    if(v.mobile_stock_enabled===false){
        return null;
    }

    if(v.mobile_branch_id){

        var direct=(this.refs.branches||[]).find(function(b){

            return (
                String(b.id)===String(v.mobile_branch_id) &&
                String(b.company_id||'')===String(this.company||'') &&
                b.is_active!==false
            );

        },this);

        if(direct){
            return direct;
        }
    }

    var code=
        'VAN-' +
        String(v.vehicle_code||'')
            .trim()
            .toUpperCase();

    return (this.refs.branches||[]).find(function(b){

        return (
            b.is_active!==false &&
            String(b.company_id||'')===String(this.company||'') &&
            String(b.branch_code||'')
                .trim()
                .toUpperCase()===code
        );

    },this)||null;
},
~~~

---

# 15. PATCH 3 — pickArr

الملف نفسه.

ابحث تحديدًا عن:

`pickArr:function(key){var s=this,bid=(RW_UI.byId('wsFrom')||{}).value||''...`

الموضع:
**line 505**

احذف الدالة كاملة واستبدل:

~~~javascript
pickArr:function(key){

    var s=this;

    var bid=(RW_UI.byId('wsFrom')||{}).value||'';

    var b=(s.refs.branches||[]).find(function(x){
        return x.id===bid;
    });

    var userBranches=
        (s.refs.branches||[]).filter(function(x){
            return s.allowedBranch(s.user,x);
        });

    if(key==='wsFrom'){

        if(s.type==='DirectReturn'){

            return (s.refs.vehicles||[]).filter(function(v){

                var vb=s.vehicleBranch(v);

                var rep=
                    (s.refs.reps||[]).find(function(r){
                        return r.id===v.driver_id;
                    });

                return (
                    v.status==='Active' &&
                    !!vb &&
                    v.mobile_stock_enabled!==false &&
                    !!rep
                );
            });
        }

        return userBranches;
    }

    if(key==='wsRep'){

        return (s.refs.reps||[]).filter(function(r){

            return (
                !!b &&
                s.allowedBranch(s.user,b) &&
                s.allowedBranch(r,b)
            );
        });
    }

    if(key==='wsTo'&&s.type==='Transfer'){
        return userBranches;
    }

    if(key==='wsTo'&&s.type==='DirectSale'){

        var rid=(RW_UI.byId('wsRep')||{}).value||'';

        return (s.refs.vehicles||[]).filter(function(v){

            var vb=s.vehicleBranch(v);

            var rep=
                (s.refs.reps||[]).find(function(r){
                    return r.id===v.driver_id;
                });

            return (
                v.status==='Active' &&
                rid &&
                v.driver_id===rid &&
                !!vb &&
                v.mobile_stock_enabled!==false &&
                !!b &&
                s.allowedBranch(s.user,b) &&
                (!rep||s.allowedBranch(rep,b))
            );
        });
    }

    if(key==='wsTo'&&s.type==='DirectReturn'){

        var vid=(RW_UI.byId('wsFrom')||{}).value||'';

        var vv=
            (s.refs.vehicles||[]).find(function(x){
                return x.id===vid;
            });

        var rp=
            vv &&
            (s.refs.reps||[]).find(function(x){
                return x.id===vv.driver_id;
            });

        return userBranches.filter(function(x){

            return (
                !!x &&
                (!rp||s.allowedBranch(rp,x))
            );
        });
    }

    if(key==='wsTo'&&s.type==='SupplierReturn'){

        var m=(s.refs.supplierBranchMap||{})[bid];

        if(m&&Object.keys(m).length){

            return (s.refs.suppliers||[]).filter(function(x){
                return !!m[x.id];
            });
        }

        return s.refs.suppliers||[];
    }

    return userBranches;
},
~~~

### السبب

تمت إزالة صلاحية المستخدم على Mobile Branch من:
- DirectSale target vehicle
- DirectReturn source vehicle

مع الإبقاء على:
- company identity
- vehicle active
- mobile stock enabled
- driver/representative identity
- user branch authorization في فرع العملية.

الـbackend يبقى الحارس النهائي.

---

# 16. PATCH 4 — البعد التشغيلي/الشكل: فصل رقم الإذن عن المرجع

الملف نفسه.

ابحث تحديدًا عن:

`cards:function(rows,scope){var s=this;if(!rows.length)return...`

الموضع:
**line 199**

احذف الدالة كاملة واستبدلها:

~~~javascript
cards:function(rows,scope){

    var s=this;

    if(!rows.length){

        return (
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
                    '<button onclick="event.stopPropagation();App.send(\''+
                    s.esc(v.voucher_code)+
                    '\')" class="bg-indigo-600 text-white px-3 py-2 rounded-xl text-xs font-black">إرسال</button>';

                a+=
                    '<button onclick="event.stopPropagation();App.cancel(\''+
                    s.esc(v.voucher_code)+
                    '\')" class="bg-rose-600 text-white px-3 py-2 rounded-xl text-xs font-black">إلغاء</button>';
            }

            if(act==='receive'){

                a+=
                    '<button onclick="event.stopPropagation();App.receive(\''+
                    s.esc(v.voucher_code)+
                    '\')" class="bg-emerald-600 text-white px-3 py-2 rounded-xl text-xs font-black">استلام</button>';
            }

            if(act==='complete'){

                a+=
                    '<button onclick="event.stopPropagation();App.complete(\''+
                    s.esc(v.voucher_code)+
                    '\')" class="bg-violet-600 text-white px-3 py-2 rounded-xl text-xs font-black">إكمال</button>';
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

        return (
            '<div class="card mb-3 cursor-pointer" onclick="App.details(\''+
                s.esc(v.voucher_code)+
            '\')">'+

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

                            '<div class="mt-2 text-[10px] text-slate-500">'+
                                s.esc(fromText)+
                                ' → '+
                                s.esc(toText)+
                            '</div>'+

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
~~~

---

# 17. ما لم يتم تعديله عمدًا

لا تعدل أيًا من العناصر التالية:

- `callAction`
- `send`
- `cancel`
- `complete`
- `receive`
- `summary`
- CREATE operation identity
- RECEIVE operation identity
- before/after stock
- list/filter
- audit/details
- `main.html`
- `van-sales.html`
- Service Worker

---

# 18. رقم الإذن vs المرجع

Current Production/Data Contract يملك بالفعل:

`voucher_code`

كهوية الإذن الداخلية.

و:

`reference`

كمرجع العملية.

لا توجد حاجة لإنشاء عمود Serial جديد لهذه النقطة.

الـUI يحتاج فقط إبراز الفصل بصريًا.

---

# 19. Competitive benchmark

### Odoo

Odoo 19 يميز بوضوح بين:
- document operations
- lots
- serial numbers
- traceability
- location/movement history

ويتيح تتبع serial/lot عبر دورة المخزون ومراقبة الحركات والموقع.  
المصدر:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/product_management/product_tracking/serial_numbers.html

### Microsoft Dynamics 365

Dynamics Inventory Journals يميز أنواعًا مستقلة مثل:
- Movement
- Inventory adjustment
- Transfer
- Item arrival
- Counting
- Tag counting

وتحويل المخزون ينتج issue من المصدر وreceipt للوجهة عند post.  
المصدر:
https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/inventory-journals

### Daftra

Daftra يميز:
- warehouse
- stocktaking number
- date
- notes
- physical count
- system count
- shortage/overage
- adjustment

كما يدعم Serial / Lot / Expiry للمنتجات المتتبعة.  
المصادر:
https://docs.daftra.com/en/tutorial/adding-a-stocktaking-sheet/
https://docs.daftra.com/en/user_manual/how-to-perform-inventory-stocktaking-of-tracked-products/
https://docs.daftra.com/en/tutorial/tracking-products-by-serial-number/

### SAP

SAP S/4HANA يعتمد Goods Movement/Inventory Movement semantics للـgoods issue/goods receipt/stock transfer، مع التمييز بين الوثيقة والعملية المادية.

### Manager.io

لم يُستخدم كمصدر عقد في هذه الجلسة لعدم توفر توثيق رسمي كافٍ بنفس مستوى المصادر السابقة.

---

# 20. ما الذي ينقص RAWAEA تنافسيًا — ولماذا لم نبنه عشوائيًا الآن

تم إثبات أن عناصر المنافسة التالية حقيقية في الأنظمة العالمية:

- Lot Tracking
- Serial Number Tracking
- Expiry Tracking
- Stocktaking number
- Physical vs System count
- Shortage / Overage
- Traceability
- Inventory Movement history
- document operation identity

لكن:
**لم يتم إنشاء أي schema أو business contract جديد لهذه المزايا في هذه الجلسة.**

السبب:
هذه ليست امتدادات UI بسيطة.
إنها Domain Contract مستقل يتطلب:
- schema
- movement semantics
- valuation behavior
- stock availability
- traceability
- return rules
- reporting
- audit

لذلك تم إبقاؤها Future Business Contract بدل اختراع بنية تؤدي إلى debt جديد.

---

# 21. Final Closure Matrix

| العنصر | الحالة |
|---|---|
| Physical stock centralization | CLOSED |
| Voucher CREATE | CLOSED |
| Voucher SEND | CLOSED |
| Voucher RECEIVE | CLOSED |
| Voucher COMPLETE | CLOSED |
| Voucher CANCEL | CLOSED |
| DirectSale → Vehicle Stock | CLOSED |
| DirectReturn two-stage model | CLOSED |
| DirectReturn authorization branch | CLOSED |
| Vehicle mobile branch SQL alias | CLOSED |
| Voucher document/ref separation | OWNER READY |
| vouchers loadRefs mobile branch | OWNER READY |
| vouchers vehicleBranch mobile identity | OWNER READY |
| DirectSale vehicle UI authorization | OWNER READY |
| DirectReturn vehicle UI authorization | OWNER READY |
| Main.html | NOT MODIFIED |
| Van-sales | NOT MODIFIED IN THIS CLOSURE |
| New Edge Function | 0 |
| Production E2E RPC path | PASS |
| Production persistent residue after E2E | NONE |
| Browser E2E against real vehicle | OPEN — vehicles=0 |
| Lot/Serial/Expiry | FUTURE BUSINESS CONTRACT |

---

# 22. SELF-AUDIT

## What was proved

- Current GIT and parent chain were reread.
- Current vouchers source blob was reread.
- Current Production database was reread.
- Historical manual-voucher contract was reread.
- DirectSale and DirectReturn responsibilities were traced.
- Current mobile vehicle identity was traced.
- Production runtime error was reproduced.
- Exact runtime root cause was isolated.
- Production SQL was repaired in the existing functions.
- DirectReturn authorization was repaired in the existing wrapper.
- DirectSale + DirectReturn + Receive E2E passed transactionally.
- RECEIVE retry returned duplicate semantics.
- Production was re-read after testing.
- No permanent test voucher/vehicle/order was left.

## What was not proved

- Full browser E2E using a persistent operational vehicle.
- Browser visual verification after owner applies PATCH 1–4.
- Full live Mother synchronization after owner edit.
- Lot/Serial/Expiry contract.

## What was initially missed

The backend was already mobile-branch aware in most of the current path, but:
1. one SQL alias remained wrong;
2. one authorization guard used the wrong side of DirectReturn;
3. the frontend still read legacy vehicle-branch identity.

These were revealed only by executing the real Production-shaped flow, not by static inspection alone.

---

# 23. Exact Root Cause — final

الخطأ الذي كان يمنع المسار:

**ليس نقص Edge Function.**

وليس:
- نقص جدول
- نقص voucher_code
- نقص reference
- نقص physical writer

السبب الحرفي في Production كان:

`send_stock_voucher_atomic_core_20260828`

وفي Vehicle source resolution:

الخطأ:
`v.mobile_branch_id`

الصحيح:
`v_vehicle.mobile_branch_id`

وبالتوازي كان هناك خطأ Authorization Contract:

DirectReturn
كان يُقاس على:
**Vehicle Stock Branch**

بينما يجب أن يُقاس على:
**Receiving Operational Branch**

أما في الواجهة فكان هناك contract drift ثالث:

Production:
`vehicles.mobile_branch_id`

Frontend:
`VAN-vehicle_code`

تم إغلاق الأسباب الثلاثة في Backend/Production.
الـfrontend ما زال يحتاج فقط تطبيق الـowner patches الأربع أعلاه.

---

# 24. تعليمات البداية للمساعد التالي

لا تبدأ من الصفر.

ابدأ بهذا الترتيب:

1. اقرأ آخر section في `CURRENT_STATE.md`.
2. افحص System HEAD وParent.
3. افحص Mother current blob.
4. افحص target vouchers blob.
5. تحقق هل PATCH 1–4 مطبقة.
6. لا تعيد إصلاح أي Closure مغلق.
7. اقرأ Production في نفس لحظة التقييم.
8. تحقق أن:
   - `send_stock_voucher_atomic`
   - `send_stock_voucher_atomic_core_20260828`
   يحتويان على الإصلاحين أعلاه.
9. لا تنشئ Edge Function جديدة.
10. بعد owner patch فقط:
    - parser/static validation
    - browser E2E
    - DirectSale
    - DirectReturn
    - Receive retry
    - Production resnapshot
11. لا تعتبر المهمة 100% CLOSED قبل توافق:
    CURRENT GIT
    +
    CURRENT SOURCE
    +
    CURRENT PRODUCTION
    +
    CURRENT DEPLOYMENT
    +
    BROWSER E2E

---

## 25. Source of Truth

الحالة الحالية المعتمدة:

CURRENT GIT
+
CURRENT SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT EVIDENCE

التقارير التاريخية لا تُستخدم كبديل عن هذه المصادر.

