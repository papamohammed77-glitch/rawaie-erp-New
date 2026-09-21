
# Report284 — إغلاق تكامل الأذونات المخزنية مع مخزن سيارة البيع المباشر
التاريخ: 2026-09-21

## 1. نطاق الجلسة

النطاق الوحيد لهذه الجلسة هو:
- تبويب إدارة المخازن والمخزون → الأذونات المخزنية.
- التطبيق المستقل: companies/company-1/warehouse/vouchers.html.
- علاقته بالنظام الأم وبمسار Van Sales/المركبة والحسابات والمخزون.
- Production Supabase ذات الصلة.
- إغلاق الفجوات الحقيقية فقط، دون إعادة إصلاح ما ثبت إغلاقه.
- عدم لمس main.html أو vouchers.html أو van-sales.html مباشرة.

قاعدة الحقيقة الحاكمة:
CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.

التقارير التاريخية استُخدمت للاستدلال فقط، ثم أُعيد إثبات النقاط من المصدر الحي وProduction.

## 2. Governance وقراءة الحالة

تمت مراجعة:
1. MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS.
2. مجلد doc/Draft/Reprots وأحدث سلسلة تقارير الأذونات.
3. CURRENT_STATE.md.
4. آخر System commits والـparent.
5. آخر Mother commits والـparent.
6. المصدر الحالي لتطبيق vouchers.
7. المصدر الحالي لتطبيق van-sales.
8. الوثيقة التاريخية للأذونات المخزنية اليدوية.
9. النسخة التاريخية القديمة لتطبيق vouchers.
10. Production schema/RPC/constraints/permissions/runtime state.
11. آخر migrations المرتبطة بالأذونات والمخزون.

المبدأ التنفيذي المطبق:
UNDERSTAND → HISTORICAL CONTRACT → CURRENT SOURCE → CURRENT PRODUCTION → GAP → SURGICAL FIX → TEST → DEPLOY → PRODUCTION VERIFY → CLOSE.

## 3. Current Git

System repository:
papamohammed77-glitch/rawaie-erp-New

HEAD قبل التعديل:
fef27c2f4e50c9e1b5aae1c9ff153caf51ccbcf0

Parent:
d1c9f8de55b33a02d1ea6734b19db9d1c9fa2031

HEAD بعد تسجيل migration:
141c526186d5a3031666ea2986c24da038b25120

الـmigration المسجلة:
20260921100708_vouchers_mobile_branch_canonical_create_guard_20260921

Mother repository:
papamohammed77-glitch/erp-frontend

Mother latest:
7375e75d562b4743f435fd26db60402a5a23e293

Mother parent:
e0769499509ab3cd919d62b46e93529e13c992b7

Mother latest work relevant to this task:
- align Van Sales with canonical mobile branch and stock balance.
- remove unverified company state from Van Sales operation identity.

هذا العمل لم يُعاد فتحه ولم يُعدّل.

## 4. Current Source

تطبيق الأذونات المخزنية الحالي:
companies/company-1/warehouse/vouchers.html

Current blob:
5eea64c53a344f588c8035dc278d559d2be1b242

حالة الملف:
لم يتم تعديله بواسطة CTO في هذه الجلسة، التزامًا بتعليمات الملك.

تطبيق Van Sales الحالي:
companies/company-1/sales/van-sales.html

Current blob:
a914c3e268c8801533051a3f0901c0db5919ee64

حالة الملف:
لم يتم تعديله في هذه الجلسة.

Mother main.html:
لم يتم تعديله.

## 5. إعادة بناء الدور الوظيفي للأذونات

التطبيق ليس بديلًا عن عمليات Order/Runsheet.

دوره التشغيلي:
- Transfer: تحويل مستقل بين الفروع.
- DirectSale: صرف عهدة بيع مباشر من الفرع إلى المركبة.
- DirectReturn: إعادة عهدة/بضاعة المركبة إلى الفرع.
- SupplierReturn: إخراج بضاعة من الفرع للمورد.

Scrap وAdjustment موجودان في واجهة التطبيق، لكنهما مرتبطان بـAdjustment Engine ولا تم تحويلهما إلى Writer جديد داخل هذه الجلسة.

الأذونات إذن هي طبقة العمليات المخزنية المستقلة عن دورة الطلب/الرانشيت، مع التكامل مع:
- branch stock
- vehicle/mobile stock
- inventory log
- audit
- Van Sales
- accounting/future settlement surfaces.

## 6. العقد التاريخي الذي تم الحفاظ عليه

الوثيقة التاريخية للأذونات أثبتت:
- voucher document مستقل.
- voucher_code هو هوية المستند.
- reference مرجع العملية.
- DirectSale = Branch → Vehicle.
- DirectReturn = Vehicle → Branch.
- سيارة المندوب مخزن متنقل، وليست هوية مندوب مستقلة.
- الصرف المباشر يمثل نقل عهدة مخزنية قبل البيع.
- المرتجع المباشر يمثل إعادة جزء/كل العهدة.
- العهدة يجب أن تُغلق أو تُترك كرصيد قائم للمركبة ليعاد تسويته لاحقًا.
- Physical Stock يجب أن يمر عبر المحرك المركزي.

هذه العقود لم تُستبدل.

## 7. Current Production architecture

Production تحتوي بالفعل على:
- post_stock_movement كـPhysical Stock writer مركزي.
- send_stock_voucher_atomic وcore.
- post_manual_stock_voucher_atomic.
- stock_voucher_operations مع UNIQUE(company_id, operation_id).
- vehicles.mobile_branch_id.
- vehicles.mobile_stock_enabled.
- branch row خاص بالمركبة.
- stock_branches unique(branch_id,item_id).
- inventory_log.
- audit_log وtrigger.

لا يوجد احتياج لإنشاء Edge Function جديدة.

## 8. التحقيق الجنائي

### Finding A — Frontend vehicle identity drift

العنصر:
loadRefs في vouchers.html

كان يجلب المركبات بدون:
mobile_branch_id
mobile_stock_enabled

النتيجة:
الواجهة كانت تعتمد لاحقًا على lookup تاريخي للفرع بواسطة:
VAN-vehicle_code

بينما Source of Truth الحالي في Production هو:
vehicles.mobile_branch_id

### Finding B — Frontend vehicleBranch drift

العنصر:
vehicleBranch:function(v)

كان يحل الفرع اعتمادًا على branch_code فقط.

هذا يترك الواجهة أسيرة للعقد التاريخي، بينما Production أصبح يملك mobile_branch_id صريحًا.

### Finding C — DirectSale / DirectReturn UI authorization side

العنصر:
pickArr:function(key)

كان يجمع authorization حول Mobile Branch في مواضع لا تمثل الجهة التشغيلية الصحيحة.

المطلوب:
- DirectSale: تصريح المستخدم على فرع المصدر، مع مطابقة المندوب للمركبة.
- DirectReturn: تصريح المستخدم على فرع الاستلام، بينما المركبة هي مصدر البضاعة.

### Finding D — Backend CREATE vehicle branch contract

Production كان يملك core حاليًا جيدًا في معظم دورة إنشاء الإذن، لكنه كان يربط صلاحية Vehicle context بإحدى صور branch identity القديمة.

تم تعديل core الحالي، لا إنشاء Core جديد.

الحارس الآن يقبل:
1. mobile_branch_id صالحًا داخل نفس الشركة.
2. fallback التاريخي VAN-vehicle_code للتوافق.

مع بقاء الحارس الموجود fn_vehicle_context_guard في موضعه، لأنه عقد Production قائم يفرض اتساق مخزن المركبة مع vehicle_code.

لم يتم تعطيل الحارس.

## 9. الإصلاح المنفذ مباشرة في Production

تم تطبيق migration:

20260921100708_vouchers_mobile_branch_canonical_create_guard_20260921

على:
create_manual_stock_voucher_atomic_core_12_20260828

بدون:
- Function جديدة.
- Edge Function جديدة.
- Writer جديد.
- تغيير Physical Movement contract.
- تغيير business status model.

التعديل:
- mobile_branch_id أصبح identity canonical مقبولًا.
- mobile_stock_enabled أصبح جزءًا من صحة Vehicle stock context.
- fallback VAN-vehicle_code بقي للتوافق.
- DirectSale وDirectReturn أصبحا يحترمان canonical mobile stock configuration.

## 10. عدد Edge Functions

عدد Edge Functions لم يزد في هذه الجلسة.

تم العمل عبر:
- RPC الحالية.
- core الحالية.
- migration داخل Production.

هذا يحافظ على حد الـgateway/Spend Cap.

## 11. بيانات الاختبار الدائمة

تم إنشاء بيانات واقعية ودائمة بناءً على master-data path الموجود.

### Vehicle

vehicle_code:
VEH-TEST-260921

vehicle_id:
5fe9d0b6-fc54-4cc6-9bff-ede0e8557dd8

license_plate:
س ن ر 6021

model:
Suzuki Carry 2024

driver:
vansales@rawaea.com

driver_id:
111b0730-a977-4d11-bcd0-2427b178a9e5

mobile_branch_id:
5372503d-f638-4e7f-808d-bda585825b2f

mobile_branch_code:
VAN-VEH-TEST-260921

vehicle_type:
VanSales

operation_mode:
Sales

ownership_type:
Owned

model_year:
2024

max_weight_kg:
800

max_volume_m3:
3.2

min_trip_value:
1000

fuel_type:
Petrol

mobile_stock_enabled:
true

هذه البيانات لم تُحذف، بناءً على تعليمات الملك.

### Demo DirectSale voucher

voucher_code:
IN-1

voucher_id:
17c21a99-225d-4219-8d31-12e9fb300f18

type:
DirectSale

reference:
DEMO-DIRECT-SALE-2026-09-21

operation_id:
DEMO-DS-260921-01

from:
BR-01

to:
VEH-TEST-260921

rep:
vansales@rawaea.com

created_by:
vouchers@rawaea.com

items:
1001 × 1
1003 × 1
1004 × 1

الحالة النهائية:
Draft

لا توجد له حركة physical stock حتى الآن.

## 12. Production baseline النهائي

Current production snapshot بعد الاختبار:

companies = 1
branches = 3
vehicles = 1
stock_vouchers = 1
stock_voucher_details = 3
stock_voucher_operations = 1
inventory_log = 3
audit_log = 2027

Demo voucher:
IN-1 = Draft

Demo voucher physical inventory logs:
0

MAIN / item 1001:
2.0000

Vehicle stock / item 1001:
0.0000

## 13. Production E2E

تم تنفيذ اختبار transactional حقيقي على Production ثم ROLLBACK.

### DirectSale

IN-1:
Draft → Sent

نتيجة:
success = true
movement_count = 3

تم التأكد أن الحركة:
- خصمت من MAIN.
- أضافت إلى مخزن المركبة.
- مرّت عبر post_stock_movement.

### DirectReturn

تم إنشاء DirectReturn مؤقت:
Vehicle → BR-01

ثم:
- SEND نجح.
- RECEIVE نجح.
- إعادة RECEIVE بنفس operation_id أعادت:
duplicate = true

### Result

قبل الاختبار:
MAIN item 1001 = 2
Vehicle item 1001 = 0

بعد سلسلة DirectSale + DirectReturn + Receive:
MAIN item 1001 = 2
Vehicle item 1001 = 0

ثم ROLLBACK.

النتيجة:
لا توجد آثار اختبار دائمة على Physical Stock.

## 14. خطأ اختبار كشفه التحقيق

عند محاولة إنشاء mobile branch مستقل بكود مختلف عن:
VAN-vehicle_code

تم إيقاف العملية بواسطة:
fn_vehicle_context_guard()

رسالة الخطأ:
vehicle mobile branch does not match company/vehicle code

القرار:
لم يتم تعطيل guard ولم تتم ترقيع Production حوله.

السبب:
هذا guard جزء من عقد Vehicle Master الحالي.
تم إبقاء هذا العقد.
وتم فقط جعل CREATE core يستفيد من mobile_branch_id دون إزالة شرط الاتساق القائم.

## 15. Competitive benchmark

### Odoo

Odoo 19 يدعم:
- Inventory adjustments.
- Barcode-based counting.
- assigned counting tasks.
- operation types.
- traceability.
- lot/serial handling.

المصادر:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/barcode/operations/adjustments.html
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/product_management/product_tracking/lots.html

### Microsoft Dynamics 365

Inventory Journals تميز:
- Movement
- Inventory adjustment
- Transfer
- Item arrival
- Counting
- Tag counting

وتتعامل التحويلات على مستوى from/to inventory dimensions، مع فصل النقل الفعلي عن transfer orders عند الحاجة.

المصادر:
https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/inventory-journals
https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/tasks/transfer-physical-inventory-within-warehouse

### SAP S/4HANA

Goods Movement يشمل:
- goods receipt
- goods issue
- stock transfer
- transfer posting
- توثيق الحركة

المصدر:
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/91b21005dded4984bcccf4a69ae1300c/742e46e570984d9aa74e468838f6e1ff.html

### Daftra

يدعم:
- detailed inventory transactions
- timestamp
- movement type
- warehouse
- opening balance
- print/export
- stocktaking
- serial/lot/expiry

المصادر:
https://docs.daftra.com/en/tutorial/inventory-detailed-transactions-report/
https://docs.daftra.com/en/tutorial/importing-a-stocktaking-sheet/
https://docs.daftra.com/en/user_manual/how-to-perform-inventory-stocktaking-of-tracked-products/

### Manager.io

لم يُستخدم كمصدر عقد تقني في هذه الجلسة لعدم توفر توثيق رسمي حي بالدرجة نفسها.

## 16. ما الذي يملكه RAWAEA بالفعل

التطبيق الحالي ليس نسخة سطحية من النموذج التاريخي القديم.

الموجود حاليًا يشمل:
- live refresh
- realtime subscriptions
- company scoping
- branch scoping
- vehicle references
- representative references
- supplier mapping
- stock preview
- before/after movement visibility
- audit visibility
- operation identity
- DirectSale / DirectReturn workflow
- explicit voucher/reference separation
- full voucher detail view
- action orchestration

هذه العناصر كانت جزءًا من أعمال الجلسات السابقة، ولم تتم إعادة بنائها.

## 17. Competitive gaps التي لم يتم اختراعها

الأنظمة المنافسة تحتوي قدرات إضافية مثل:
- lot
- serial
- expiry
- barcode count
- richer stocktaking
- print/export
- richer approval layers
- transfer in-transit
- richer tracking dimensions.

لم يتم اختراع schema أو business contract جديد لها في هذه الجلسة.

السبب:
هذه Domain Contracts وليست UI additions.
إدخالها يتطلب:
- schema
- lifecycle
- valuation
- traceability
- reporting
- audit
- movement semantics.

لذلك تم إبقاؤها Future Contract بدل إنشاء دين جديد.

## 18. التعديل الجراحي المطلوب في vouchers.html

الملف:
companies/company-1/warehouse/vouchers.html

الملف لم يتم تعديله بواسطة CTO.

### PATCH 1 — loadRefs

ابحث تحديدًا عن:

    loadRefs:function(){var s=this;return Promise.all([supabase.from('branches').select('id,branch_code,name')...

الموضع:
line 27

احذف الدالة كاملة واستبدلها:

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

### PATCH 2 — vehicleBranch

ابحث تحديدًا عن:

    vehicleBranch:function(v){if(!v)return null;var code='VAN-'+String(v.vehicle_code||'').trim().toUpperCase();return(this.refs.branches||[]).find(function(b){return String(b.branch_code||'').trim().toUpperCase()===code})||null},

الموضع:
line 504

احذف الدالة كاملة واستبدلها:

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

### PATCH 3 — pickArr

ابحث تحديدًا عن العنصر الذي يبدأ بـ:

    pickArr:function(key){var s=this,bid=(RW_UI.byId('wsFrom')||{}).value||''

الموضع:
line 505

احذف الدالة كاملة واستبدلها:

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

### PATCH 4 — فصل رقم الإذن عن المرجع

ابحث تحديدًا عن:

    cards:function(rows,scope){var s=this;if(!rows.length)return...

الموضع:
line 199

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

## 19. لا تعدل هذه العناصر

لا تعدل:
- main.html.
- van-sales.html.
- callAction.
- send.
- cancel.
- complete.
- receive.
- summary.
- existing CREATE operation identity.
- existing RECEIVE operation identity.
- before/after stock.
- list/filter.
- audit/details.
- Service Worker.

الهدف هو إكمال الـUI contract فقط.

## 20. ما تم عدم لمسه عمدًا

لم يتم:
- إعادة بناء voucher workflow.
- إعادة كتابة post_stock_movement.
- إنشاء Physical Stock writer جديد.
- تعطيل fn_vehicle_context_guard.
- تغيير status model.
- تغيير stock valuation.
- تعديل Driver Ledger contract.
- تعديل Van Sales contract.
- إضافة Edge Function.

## 21. علاقة DirectSale بالمندوب والسيارة

الـProduction contract الحالي يثبت:
- المندوب هو مستخدم فعلي.
- السيارة كيان مستقل.
- الربط التشغيلي بينهما عبر vehicle.driver_id.
- السيارة تصبح mobile stock عبر mobile_branch_id + mobile_stock_enabled.
- الصرف يذهب إلى المخزن المتنقل.
- البيع اليومي بعد ذلك هو VanSale.
- المرتجع المباشر يعود من المخزن المتنقل إلى الفرع.

لم يتم تحويل السيارة إلى هوية مندوب.

## 22. الحسابات والعهدة

Production الحالية لا تجعل CREATE DirectSale يُنشئ قيدًا محاسبيًا بحد ذاته.

هذا متسق مع العقد التاريخي الذي يميز:
- نقل العهدة قبل البيع
- عن البيع الفعلي.

الرقابة المالية على العهدة مرتبطة بالعمليات اللاحقة settlement/driver liability/Van Sales.

لم يتم اختراع قيد مالي جديد داخل vouchers.

## 23. Closure matrix

| العنصر | Production | Current Source | حالة الإغلاق |
|---|---|---|---|
| Physical stock centralization | مثبت | مثبت | CLOSED |
| Manual CREATE contract | مثبت | Edge موجود | CLOSED |
| Operation registry | مثبت | موجود | CLOSED |
| DirectSale vehicle relation | مثبت | owner patch مطلوب | OWNER PATCH |
| DirectReturn vehicle relation | مثبت | owner patch مطلوب | OWNER PATCH |
| mobile_branch_id lookup | مثبت | owner patch مطلوب | OWNER PATCH |
| warehouse branch authorization | مثبت | owner patch مطلوب | OWNER PATCH |
| voucher serial/reference distinction | مثبت | owner patch مطلوب | OWNER PATCH |
| Audit/movement detail | مثبت | مثبت | CLOSED |
| RECEIVE retry idempotency | مثبت | مثبت | CLOSED |
| New Edge Function | 0 | 0 | CLOSED |
| main.html | untouched | untouched | CLOSED |
| van-sales.html | untouched | untouched | CLOSED |
| Browser E2E | backend contract PASS | UI patch not applied | OPEN |

## 24. SELF-AUDIT

### What was proved
- Current System GIT was reread.
- System HEAD and parent were checked.
- Mother latest commits and parent were checked.
- Target vouchers source was reread.
- Van Sales current source was reread.
- Historical voucher architecture was reread.
- Current Production schema was checked.
- Current vehicle contract was checked.
- Current manual voucher CREATE contract was checked.
- Current send/receive core was checked.
- Physical movement centralization was checked.
- Real Production E2E passed transactionally.
- DirectReturn RECEIVE retry returned duplicate=true.
- Production data was re-snapshotted.
- No E2E test residue remained.
- Persistent demo vehicle and voucher remain intentionally.

### What was not proved
- Browser visual E2E after the owner applies PATCH 1–4.
- Full Mother launch path after owner changes vouchers.html.
- Full UI acceptance from login through DirectSale/DirectReturn in a real browser.

### Why this remains open
The owner explicitly prohibited CTO from modifying vouchers.html.

Therefore no claim of browser-level 100% closure is made.

## 25. بداية الجلسة التالية

1. اقرأ هذا التقرير أولًا.
2. اقرأ CURRENT_STATE.md.
3. افحص System HEAD.
4. افحص target vouchers blob.
5. تحقق هل PATCH 1–4 تم تطبيقها.
6. لا تعيد أي Production migration مغلقة.
7. لا تعدل main.html.
8. لا تعدل van-sales.html إذا لم يظهر دليل جديد.
9. نفذ browser/static validation على vouchers.
10. نفذ E2E:
    - login
    - branch context
    - DirectSale
    - Send
    - vehicle stock increase
    - DirectReturn
    - Receive
    - retry duplicate
    - final stock reconciliation
11. بعد ذلك افحص Production مرة أخرى في نفس لحظة التقرير.
12. إذا نجح كل ذلك فقط سجّل:
    BROWSER E2E = CLOSED
    GLOBAL VOUCHERS INTEGRATION = CLOSED

## 26. Source of Truth

لا تستخدم هذا التقرير كبديل عن الواقع.

ابدأ دائمًا من:
CURRENT GIT
+
CURRENT SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT EVIDENCE

والتقارير السابقة مجرد trail لفهم لماذا وصل النظام إلى حالته الحالية.

## 27. Owner execution instruction

الملف الوحيد المطلوب تعديله يدويًا:
companies/company-1/warehouse/vouchers.html

نفّذ فقط:
PATCH 1
PATCH 2
PATCH 3
PATCH 4

وبنفس ترتيبها.

لا تُضف Function جديدة.
لا تضف Edge Function جديدة.
لا تعيد كتابة الملف كاملًا.
لا تعدل main.html.

