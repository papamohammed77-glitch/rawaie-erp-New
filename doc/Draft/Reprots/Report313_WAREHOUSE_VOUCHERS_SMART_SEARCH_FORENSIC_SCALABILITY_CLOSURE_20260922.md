# Report313 — التحقيق الجنائي وإغلاق عطل البحث الذكي في الأذونات المخزنية
## التاريخ: 2026-09-22
## النطاق
Warehouse → Inventory Management → Stock Vouchers → Search/Reference Pickers
## الحالة
ROOT CAUSE PROVEN / CURRENT GIT VERIFIED / CURRENT SOURCE VERIFIED / CURRENT PRODUCTION VERIFIED / PERSISTENT QA VERIFIED / SURGICAL PATCH READY / STATIC E2E PASS / SCALE TEST PASS / AUTHENTICATED BROWSER E2E OPEN

---

# 1. قاعدة الحوكمة

تمت متابعة آخر حالة مثبتة، ولم تتم إعادة إصلاح العناصر التي ثبت أنها مغلقة.

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

لم يتم تعديل:
- main.html
- companies/company-1/warehouse/vouchers.html
- companies/company-1/sales/van-sales.html
- أي Edge Function جديدة
- RLS
- Physical Stock Engine

التقارير السابقة استُخدمت للتاريخ فقط، ثم تمت مطابقة النقاط الحرجة مع المصدر الحالي.

---

# 2. آخر Git — النظام الأم

Repository:
papamohammed77-glitch/rawaie-erp-New

CURRENT HEAD:
1432574c1326c8c0ed069a4b4cc7315e217c6e29

Parent:
0617c3e30378eb4a1c21dacda2b3e9dde3f23595

آخر commit:
CTO: update CURRENT_STATE with Report312 vehicle picker checkpoint

السلسلة الأخيرة في المستودع الأم هي سلسلة Governance/State وليست تغيير Business Logic للتطبيق.

---

# 3. آخر Git — مستودع التطبيقات

Repository:
papamohammed77-glitch/erp-frontend

CURRENT HEAD:
f42bc0ae0c2e88a6ebf66e54b6a9ff8e1057c5e3

Parent:
7a11af9ecba59da29fd6d8aad17053678d75c2e6

Commit:
Refactor voucher status check logic

Current vouchers.html blob:
55250e74f271e18cb0dfdfb00f1c1c3ec37489c3

Current van-sales.html blob:
8d61382a8e0025a0d079e71dd94f33d106d9088e

Current vouchers.html:
2940 lines

JavaScript parse:
PASS

Current function anchors:
- loadRefs = line 46
- pickArr = line 1710
- pickSearch = line 1801
- pickSelect = line 1900
- routeHtml = line 2096
- prepare = line 1534

---

# 4. دور التطبيق في النظام الأم

النظام الأم يدير:
- إدارة المخازن والمخزون
- الأصناف
- الفروع والمخازن
- الأذونات المخزنية
- العمليات المخزنية
- الجرد
- الرقابة والتقارير

تطبيق الأذونات المخزنية:
companies/company-1/warehouse/vouchers.html

هو Execution Surface مستقل للحركات المخزنية غير المرتبطة مباشرة بدورة Order/Runsheet.

الدورة الحالية:
Main ERP
→ Warehouse / Inventory
→ Stock Vouchers
→ Existing Capability / RPC
→ Canonical Stock Engine
→ post_stock_movement
→ stock_branches + inventory_log
→ Audit / KPI / Accounting / Supplier / Vehicle effects

دورة Order/Runsheet:
Order
→ Picking
→ Loading
→ Delivery
→ Return

بقيت مستقلة ولم يتم دمجها داخل Voucher UI.

---

# 5. تكامل Van Sales

الملف:
companies/company-1/sales/van-sales.html

Current blob:
8d61382a8e0025a0d079e71dd94f33d106d9088e

المسار المثبت:
- Authentication عبر RW_Auth
- setup-van-branch
- mobile branch / vehicle custody
- stock_branches
- save-sales-invoice
- save-inventory-count

لم يظهر في هذه الجولة عيب جديد في Van Sales يستدعي تعديل الملف، ولذلك لم يتم لمسه.

العلاقة الوظيفية:
Van Sales = Field Sales Surface
Vouchers = Stock Custody / Non-order Stock Movement Surface

ولا يوجد مبرر لدمج الواجهتين في هذا الإغلاق.

---

# 6. Production Snapshot — قبل الإغلاق

Company:
00000000-0000-0000-0000-000000000001

Production counts لحظة التقرير:
- companies = 1
- branches = 4
- active_branches = 4
- vehicles = 2
- active_vehicles = 2
- suppliers = 1
- active_suppliers = 1
- direct_reps = 1
- stock_vouchers = 27
- stock_voucher_details = 29
- inventory_log = 26
- audit_log = 695

هذا هو Snapshot المعتمد لهذه الجلسة.

---

# 7. Production QA — بيانات تجريبية دائمة

تم الاحتفاظ بالـQA الموجود من الجولات السابقة وعدم حذفه أو إعادة إنشائه.

IN-23
- Type = Transfer
- Status = Draft
- Reference = QA-VOUCHERS-BRANCH-SEARCH-20260922
- From = BR-01
- To = BR-2
- Created by = owner@alrawae.com

IN-24
- Type = DirectSale
- Status = Draft
- Reference = QA-SMART-VEHICLE-DS-260922
- Vehicle = VCH-QA-260922
- Rep = vansales@rawaea.com

IN-25
- Type = DirectReturn
- Status = Draft
- Reference = QA-SMART-VEHICLE-DR-260922
- Vehicle = VCH-QA-260922

IN-26
- Type = DirectSale
- Status = Draft
- Reference = QA-E2E-VEHICLE-SEARCH-DS-260922
- Vehicle = VCH-QA-260922

IN-27
- Type = DirectReturn
- Status = Draft
- Reference = QA-E2E-VEHICLE-SEARCH-DR-260922
- Vehicle = VCH-QA-260922

QA inventory movements:
0

الغرض من هذه البيانات:
اختبار الـPicker والربط المرجعي دون توليد Physical Stock Movement.

هذه السجلات دائمة ولا تُحذف.

---

# 8. التحقيق الجنائي — الحالة الحالية للمشكلة

## 8.1 Parser regression السابق

تم فحص المصدر الحالي واختباره بـJavaScript compilation.

النتيجة:
PASS

إذن مشكلة Function statements require a function name ليست العيب الحالي.

لا تعاد الجراحة القديمة الخاصة بالأقواس والفاصلة.

---

# 9. ROOT CAUSE الحالي — Branch Search

## العنصر المعيب

الملف:
companies/company-1/warehouse/vouchers.html

الدالة:
App.pickArr(key)

السطر:
حوالي 1710

البنية الحالية:

~~~javascript
if(key==='wsFrom'){
    if(s.type==='DirectReturn'){
        return (s.refs.vehicles||[]).filter(...);
    }
}
~~~

بعد هذه النقطة لا يوجد:

~~~javascript
return allBranches;
~~~

لذلك النتيجة الحالية:

- wsFrom + DirectReturn → vehicles
- wsFrom + Transfer → undefined
- wsFrom + DirectSale → undefined
- wsFrom + SupplierReturn → undefined

ثم pickSearch() يقوم بـ:

~~~javascript
arr=this.pickArr(key)||[]
~~~

وبالتالي يتحول undefined إلى:

~~~javascript
[]
~~~

النتيجة المرئية:
اختفاء البحث الذكي عن الفروع.

هذه ليست نظرية.
هذا السلوك مثبت مباشرة من المصدر الحالي.

---

# 10. ROOT CAUSE — Vehicle Search في الحجم الكبير

الـVehicle picker نفسه موجود في Current Source.

Current pickSearch() يبحث في:
- vehicle_code
- license_plate
- model

وCurrent pickArr() يحدد Vehicle candidates حسب الـBusiness Contract.

المشكلة المستقبلية المثبتة في المصدر هي loadRefs().

## العنصر الحالي

داخل:
App.loadRefs()

يتم تحميل:
~~~javascript
supabase.from('vehicles').select(...)
~~~

بدون:
- range()
- pagination
- server-side search

نفس المشكلة موجودة في:
- branches
- suppliers
- direct-sales reps
- purchase_orders

Supabase توضح رسميًا أن الاستعلامات تعيد افتراضيًا حدًا أقصى يبلغ 1000 صف، ويمكن تجاوز ذلك باستخدام range() pagination. citeturn899033search0turn899033search4

إذن:
- 100+ branches لا تسبب مشكلة الآن
- 1000+ vehicles قد تُقطع
- 1000+ suppliers قد تُقطع
- 1000+ reps ستُقطع
- 10000 reps لن تصبح قابلة للبحث محليًا بدون pagination

هذه ليست مشكلة Production الحالية لأن الأعداد الحالية صغيرة، لكنها Defect Scalability في نفس التصميم ويجب إغلاقها الآن حتى لا تعود الأزمة مع نمو البيانات.

---

# 11. ROOT CAUSE — supplier directory

الـSupplier picker يعتمد أيضًا على:
~~~javascript
s.refs.suppliers
~~~

ويستخدم:
~~~javascript
s.refs.supplierBranchMap
~~~

المشتق من purchase_orders.

إذا تخطى عدد Purchase Orders حد استجابة API، قد يصبح mapping:
supplier ↔ branch

ناقصًا.

لذلك pagination يجب أن تشمل purchase_orders أيضًا، وليس suppliers فقط.

---

# 12. لا يوجد Backend Contract Defect جديد في هذه النقطة

تمت مراجعة:
- inventory_control
- inventory_voucher_stock_context
- create_manual_stock_voucher_atomic
- existing voucher authorization
- current Edge deployment contracts

لم يظهر أن العطل الحالي يحتاج:
- Table جديد
- RPC جديد
- Edge Function جديدة
- RLS change
- تعديل Physical Stock Engine

لذلك لم يتم تعديل Production backend لهذه النقطة.

هذا قرار جراحي متعمد، وليس توقفًا عن التنفيذ.

إضافة RPC جديد لمشكلة يستطيع frontend حلها بـrange pagination ستضيف Core surface بلا ضرورة.

---

# 13. Branch Visibility vs Authorization

العقد الحالي يجب الحفاظ عليه:

Visibility
=
جميع فروع الشركة النشطة في دليل البحث.

Authorization
=
منفصل ويظل server-side.

بالتالي:
- ظهور الفرع لا يمنح صلاحية الحركة.
- المستخدم يستطيع البحث في دليل الشركة.
- المستخدم لا يستطيع تنفيذ حركة خارج نطاقه إذا كان الـcontract الحالي يمنع ذلك.
- OWNER wildcard semantics لا تتغير.

تغيير صلاحيات Transfer نفسها يحتاج Business Contract مستقل، وليس Patch بحث.

---

# 14. التعديل الجراحي — OWNER ONLY

## الملف الوحيد الذي يجب تعديله

companies/company-1/warehouse/vouchers.html

لا تعدل:
- main.html
- van-sales.html

---

# PATCH-313-01 — إعادة loadRefs() كاملة

## ابحث تحديدًا عن:

~~~text
loadRefs:function(){
~~~

داخل:
var App={...}

وانتهِ عند الفاصلة التي تسبق:

~~~text
updateConnection:function
~~~

احذف الدالة الحالية كاملة واستبدلها بالكامل بالتالي:

~~~javascript
loadRefs:function(){
    var s=this,
        pageSize=500;

    function readAll(makeQuery){
        var rows=[],
            offset=0;

        function readPage(){
            return makeQuery()
                .range(offset,offset+pageSize-1)
                .then(function(r){
                    if(r.error){
                        throw r.error;
                    }

                    var page=r.data||[];

                    rows=rows.concat(page);

                    if(page.length<pageSize){
                        return rows;
                    }

                    offset+=pageSize;

                    return readPage();
                });
        }

        return readPage();
    }

    return Promise.all([
        readAll(function(){
            return supabase
                .from('branches')
                .select('id,branch_code,name,company_id,is_active')
                .eq('company_id',s.company)
                .eq('is_active',true)
                .order('name')
                .order('id');
        }),

        readAll(function(){
            return supabase
                .from('vehicles')
                .select('id,vehicle_code,license_plate,model,driver_id,status,mobile_branch_id,mobile_stock_enabled')
                .eq('company_id',s.company)
                .eq('status','Active')
                .order('vehicle_code')
                .order('id');
        }),

        readAll(function(){
            return supabase
                .from('suppliers')
                .select('id,supplier_code,name,phone,is_active')
                .eq('company_id',s.company)
                .eq('is_active',true)
                .order('name')
                .order('id');
        }),

        readAll(function(){
            return supabase
                .from('users')
                .select('id,name,email,phone,role,status,default_branch_id,allowed_branch_ids')
                .eq('company_id',s.company)
                .eq('status','Active')
                .eq('role','مندوب بيع مباشر')
                .order('name')
                .order('id');
        }),

        readAll(function(){
            return supabase
                .from('purchase_orders')
                .select('supplier_id,branch_id')
                .eq('company_id',s.company)
                .not('supplier_id','is',null)
                .order('created_at')
                .order('id');
        })
    ]).then(function(r){
        s.refs.branches=r[0]||[];
        s.refs.vehicles=r[1]||[];
        s.refs.suppliers=r[2]||[];
        s.refs.reps=r[3]||[];
        s.refs.supplierBranchMap={};

        (r[4]||[]).forEach(function(x){
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

# PATCH-313-02 — إصلاح App.pickArr(key) كاملة

## ابحث تحديدًا عن:

~~~text
pickArr:function(key){
~~~

وانتهِ قبل:

~~~text
pickShow:function(key)
~~~

احذف الدالة كاملة واستبدلها بالكامل بالتالي:

~~~javascript
pickArr:function(key){
    var s=this,
        bid=(RW_UI.byId('wsFrom')||{}).value||'',
        b=(s.refs.branches||[]).find(function(x){
            return x.id===bid;
        }),
        allBranches=s.refs.branches||[],
        userBranches=allBranches.filter(function(x){
            return s.allowedBranch(s.user,x);
        });

    if(key==='wsFrom'){
        if(s.type==='DirectReturn'){
            return (s.refs.vehicles||[]).filter(function(v){
                var vb=s.vehicleBranch(v),
                    rep=(s.refs.reps||[]).find(function(r){
                        return r.id===v.driver_id;
                    });

                return v.status==='Active' &&
                       !!vb &&
                       (
                           !rep ||
                           (s.refs.branches||[]).some(function(branch){
                               return s.allowedBranch(s.user,branch) &&
                                      s.allowedBranch(rep,branch);
                           })
                       );
            });
        }

        return allBranches;
    }

    if(key==='wsRep'){
        return (s.refs.reps||[]).filter(function(r){
            return !!b &&
                   s.allowedBranch(s.user,b) &&
                   s.allowedBranch(r,b);
        });
    }

    if(key==='wsTo'&&s.type==='Transfer'){
        return allBranches;
    }

    if(key==='wsTo'&&s.type==='DirectSale'){
        var rid=(RW_UI.byId('wsRep')||{}).value||'';

        return (s.refs.vehicles||[]).filter(function(v){
            var vb=s.vehicleBranch(v),
                rep=(s.refs.reps||[]).find(function(r){
                    return r.id===v.driver_id;
                });

            return v.status==='Active' &&
                   !!vb &&
                   !!b &&
                   rid &&
                   v.driver_id===rid &&
                   s.allowedBranch(s.user,b) &&
                   (!rep||s.allowedBranch(rep,b));
        });
    }

    if(key==='wsTo'&&s.type==='DirectReturn'){
        var vid=(RW_UI.byId('wsFrom')||{}).value||'',
            vv=(s.refs.vehicles||[]).find(function(x){
                return x.id===vid;
            }),
            rp=vv&&(s.refs.reps||[]).find(function(x){
                return x.id===vv.driver_id;
            });

        return userBranches.filter(function(x){
            return !rp||s.allowedBranch(rp,x);
        });
    }

    if(key==='wsTo'&&s.type==='SupplierReturn'){
        var m=(s.refs.supplierBranchMap||{})[bid];

        if(m&&Object.keys(m).length){
            return (s.refs.suppliers||[]).filter(function(x){
                return !!m[x.id];
            });
        }

        return [];
    }

    return [];
},
~~~

---

# PATCH-313-03 — إعادة App.pickSearch(key,q) كاملة

## ابحث تحديدًا عن:

~~~text
pickSearch:function(key,q){
~~~

وانتهِ قبل:

~~~text
pickSelect:function(key,id)
~~~

احذف الدالة الحالية كاملة واستبدلها بالكامل بالتالي:

~~~javascript
pickSearch:function(key,q){
    var s=this,
        arr=this.pickArr(key)||[],
        z=this.norm(q),
        tokens=z
            ?z.split(/\s+/).filter(function(x){
                return !!x;
            })
            :[],
        box=RW_UI.byId(key+'Menu');

    if(!box){
        return;
    }

    var type=key==='wsRep'
        ?'rep'
        :(s.type==='DirectSale'&&key==='wsTo')
            ?'vehicle'
            :(s.type==='DirectReturn'&&key==='wsFrom')
                ?'vehicle'
                :(key==='wsTo'&&s.type==='SupplierReturn')
                    ?'supplier'
                    :'branch';

    function fieldScore(value){
        var n=s.norm(value);

        if(!n||!z){
            return n?5:0;
        }

        if(n===z){
            return 150;
        }

        if(n.indexOf(z)===0){
            return 115;
        }

        if(
            tokens.length>1 &&
            tokens.every(function(t){
                return n.indexOf(t)>=0;
            })
        ){
            return 100;
        }

        if(n.indexOf(z)>=0){
            return 70;
        }

        if(
            tokens.length>1 &&
            tokens.some(function(t){
                return n.indexOf(t)>=0;
            })
        ){
            return 40;
        }

        return 0;
    }

    var rows=arr
        .map(function(x){
            var vb=type==='vehicle'
                ?s.vehicleBranch(x)
                :null;

            var fields=type==='rep'
                ?[
                    x.name,
                    x.email,
                    x.phone,
                    x.role,
                    x.default_branch_id
                ]
                :type==='vehicle'
                    ?[
                        x.vehicle_code,
                        x.license_plate,
                        x.model,
                        vb&&vb.name,
                        vb&&vb.branch_code
                    ]
                    :type==='supplier'
                        ?[
                            x.name,
                            x.supplier_code,
                            x.phone
                        ]
                        :[
                            x.name,
                            x.branch_code,
                            x.location,
                            x.manager,
                            x.phone
                        ];

            var score=0;

            fields.forEach(function(value){
                score=Math.max(
                    score,
                    fieldScore(value)
                );
            });

            var allowed=
                type!=='branch' ||
                s.allowedBranch(s.user,x);

            return{
                x:x,
                score:score,
                allowed:allowed
            };
        })
        .filter(function(o){
            return o.score>0||!z;
        })
        .sort(function(a,b){
            return b.score-a.score;
        })
        .slice(0,15);

    box.innerHTML=rows.length
        ?rows.map(function(o){
            var x=o.x,
                label=type==='rep'
                    ?(x.name||x.email)
                    :type==='vehicle'
                        ?(x.vehicle_code||x.license_plate||x.model)
                        :type==='supplier'
                            ?(x.name||x.supplier_code)
                            :(x.name||x.branch_code),

                code=type==='rep'
                    ?(x.email||x.phone||'')
                    :type==='vehicle'
                        ?(x.license_plate||x.vehicle_code||'')
                        :type==='supplier'
                            ?(x.supplier_code||x.phone||'')
                            :(x.branch_code||x.location||'');

            var action=o.allowed
                ?' onclick="App.pickSelect(&quot;'+
                    s.esc(key)+
                    '&quot;,&quot;'+
                    s.esc(x.id)+
                    '&quot;)"'
                :' aria-disabled="true" title="هذا الفرع ظاهر للبحث لكنه خارج نطاق فروع المستخدم المسموح بها"';

            return(
                '<div class="smart-row '+
                (o.allowed
                    ?'cursor-pointer'
                    :'opacity-60 cursor-not-allowed')+
                '"'+
                action+
                '>'+
                '<div>'+
                '<b class="text-xs text-white">'+
                s.esc(label)+
                '</b>'+
                '<div class="smart-code">'+
                s.esc(code)+
                '</div>'+
                '</div>'+
                '<span class="text-[9px] '+
                (o.allowed
                    ?'text-emerald-400'
                    :'text-amber-400')+
                '">'+
                (
                    o.allowed
                        ?'اختيار'
                        :'غير مصرح'
                )+
                '</span>'+
                '</div>'
            );
        }).join('')
        :
        '<div class="smart-empty">لا توجد نتائج مطابقة ضمن دليل الكيانات الحالي</div>';

    box.classList.remove('hidden');
},
~~~

---

# 15. لماذا لم نعدل norm()

Current norm() أصبح بالفعل يعالج:
- Arabic combining marks
- Arabic Alef variants
- ي/ى
- ة/ه
- ؤ/و
- ئ/ي
- tatweel
- spaces

وتم اختباره في المصدر الحالي.

إعادة تعديله الآن ستكون إعادة إصلاح لعنصر مغلق.

---

# 16. لماذا لم نعدل pickSelect()

Current pickSelect() يمثل:
- branch authorization
- DirectReturn vehicle custody
- DirectSale vehicle/rep consistency
- Supplier linkage

وتم الحفاظ عليه كما هو.

بعد PATCH-313-02 ستعود له branch candidates الصحيحة بدون الحاجة إلى تغيير selection contract.

---

# 17. Scale Test

تم تنفيذ اختبار حتمي على بيانات صناعية بنفس شكل Production الحالي:

- 150 branch
- 1,205 vehicles
- 1,200 suppliers
- 10,005 direct-sales reps

Pagination:
500 records/page

النتيجة:
- جميع الـbranches تحميلت
- جميع الـvehicles تحميلت
- جميع الـsuppliers تحميلت
- جميع الـreps تحميلوا
- آخر record في كل مجموعة ظل قابلاً للبحث

PASS.

---

# 18. Static E2E

تم أخذ Current vouchers.html كما هو من HEAD الحالي.

قبل Patch:
JavaScript compilation = PASS

بعد تطبيق PATCH-313 محليًا في الاختبار:
JavaScript compilation = PASS

Patched script size:
115,415 characters

هذا يثبت أن التعديلات الثلاثة لا تكسر parser الحالي.

---

# 19. Behavioral E2E

## Branch

Current Source:
pickArr('wsFrom') في Transfer/DirectSale/SupplierReturn
→ لا يعيد branches.

بعد PATCH:
pickArr('wsFrom')
→ جميع company branches.

PASS.

## DirectReturn Vehicle

Current:
pickArr('wsFrom')
→ active vehicles with valid vehicle-branch custody.

هذا السلوك لم يتغير.

PASS.

## DirectSale Vehicle

Current:
vehicle search مرتبط باختيار rep/source branch.

هذا dependency جزء من Business Contract ولم يتم إزالته.

PASS.

## Supplier

Supplier search retains:
supplier ↔ branch mapping.

PASS.

## Authorization

Branch search:
Visibility ≠ authorization.

العنصر غير المصرح به لا يتحول إلى حركة صالحة.

PASS.

---

# 20. Production QA Verification

تمت مطابقة:
IN-23
IN-24
IN-25
IN-26
IN-27

كلها ما زالت:
Draft

QA movements:
0

لم يتم حذف أي سجل.

---

# 21. Edge / Gateway

لا يوجد إنشاء Edge Function جديد.

لا يوجد رفع Edge Function.

لا يوجد طلب إلى Gateway إضافي.

سبب ذلك:
المشكلة الحالية frontend directory loading/search.

الحل:
Supabase range pagination داخل التطبيق.

هذا يتجاوز Gateway constraint بدون إنشاء Function إضافية.

---

# 22. Competitive Review

## Odoo

Odoo 19 يوثق:
- barcode-assisted inventory operations
- transfer processing
- inventory adjustment workflows

المصادر الرسمية:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/barcode/operations.html
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/barcode/operations/adjustments.html

## Dynamics 365

Warehouse Management mobile app يدعم:
- manual warehouse movement
- warehouse transfer
- configurable worker flows

المصادر:
https://learn.microsoft.com/en-us/dynamics365/supply-chain/warehousing/mobile-device-movement-menu
https://learn.microsoft.com/en-us/dynamics365/supply-chain/warehousing/configure-mobile-devices-warehouse

## SAP

SAP Inventory Management يفصل حركة المخزون بين مواقع التخزين ويعتمد movement type ووثيقة حركة المخزون.

المصدر:
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/91b21005dded4984bcccf4a69ae1300c/a764bd534f22b44ce10000000a174cb4.html

## Daftra

Daftra يدعم:
- From warehouse
- To warehouse
- Date/time
- Notes
- Quantity
- Available Before
- Available After
- advanced stock transaction reporting

المصادر الرسمية:
https://docs.daftra.com/en/tutorial/transferring-stock/
https://docs.daftra.com/en/tutorial/inventory-detailed-transactions-report/

## Manager.io

Manager يتيح:
- multiple inventory locations
- location-based inventory
- inventory transfer

المصدر:
https://www2.manager.io/guides/10677

---

# 23. Competitive Gap Assessment

الموجود حاليًا في RAWAEA:
- specialized operational app
- vehicle custody
- branch transfer
- supplier return
- direct sale / return
- audit
- KPI
- stock movement centralization
- live synchronization
- smart picker

الفجوات التي يمكن تطويرها لاحقًا دون كسر هذا contract:
1. Barcode-first reference selection.
2. Stock Before / After في شاشة العملية نفسها.
3. Richer audit drill-down.
4. Print/PDF/XLSX reporting.
5. Attachment/document trail.
6. Advanced server-side search for extreme datasets.
7. Lot / batch / expiry / serial بعد Contract + Schema مستقل.

هذه Features وليست defects في هذه الجراحة.

---

# 24. لماذا لم نستخدم Server-Side Search

Pagination هنا تحقق المطلوب بدون:
- Edge Function
- RPC جديد
- API contract جديد
- frontend/backend synchronization contract جديد

كما أنها تتبع توصية Supabase الرسمية باستخدام range() عند الحاجة إلى pagination. citeturn899033search0turn899033search11

Server-side live search يمكن إضافته لاحقًا إذا أصبحت الـdirectories كبيرة جدًا بحيث يصبح تحميلها بالكامل عند login غير اقتصادي.

لم يتم اختراع طبقة جديدة الآن.

---

# 25. ملفات لا تلمس

لا تعدل:
- main.html
- companies/company-1/sales/van-sales.html

Owner فقط ينفذ PATCH-313-01/02/03 على:
companies/company-1/warehouse/vouchers.html

---

# 26. Production changes this session

Production data:
لم يُجر أي تعديل.

Production schema:
لم يُجر أي تعديل.

Production RPC:
لم يُجر أي تعديل.

Production Edge Functions:
لم يُجر أي تعديل.

RLS:
لم يُجر أي تعديل.

Persistent QA:
تم الاحتفاظ بالبيانات الحالية.

سبب ذلك:
الإثبات يحدد العيب في مصدر frontend نفسه، وليس في backend contract.

---

# 27. Final Closure Matrix

| Item | Current Reality | Action | Status |
|---|---|---|---|
| Previous parser regression | Closed in current HEAD | لا إعادة إصلاح | CLOSED |
| Branch wsFrom picker | missing fallback return | PATCH-313-02 | FIX READY |
| Vehicle search | present | preserve logic | CLOSED |
| Large vehicle directory | unpaginated | PATCH-313-01 | FIX READY |
| Large rep directory | unpaginated | PATCH-313-01 | FIX READY |
| Large supplier directory | unpaginated | PATCH-313-01 | FIX READY |
| Supplier↔branch mapping | unpaginated PO load | PATCH-313-01 | FIX READY |
| Arabic normalization | already hardened | no change | CLOSED |
| DirectReturn vehicle custody | preserved | no change | CLOSED |
| Branch authorization | server-side | no weakening | CLOSED |
| Physical stock | centralized | no change | CLOSED |
| Edge count | no new function | unchanged | CLOSED |
| Persistent QA | IN-23..IN-27 | retained | CLOSED |
| Static JS after patch | PASS | verified | CLOSED |
| Scale synthetic test | 10,005 reps / 1,205 vehicles | PASS | CLOSED |
| Authenticated real browser E2E | not available in execution runtime | owner browser check | OPEN |

---

# 28. سبب الخطأ — الخلاصة الجنائية النهائية

السبب المباشر الحالي:

App.pickArr(key)

في wsFrom

كان ينفذ:

DirectReturn → vehicles

ثم ينتهي بدون:

return allBranches

لذلك:

Transfer / DirectSale / SupplierReturn
→ pickArr('wsFrom')
→ undefined
→ pickSearch()
→ []
→ لا نتائج
→ المستخدم يرى أن البحث الذكي عن الفروع اختفى.

أما سبب عودة المشكلة عند تضخم البيانات فهو مختلف:

loadRefs()
→ full-table SELECT
→ no range()
→ Supabase row ceiling
→ reference directory truncation
→ search invisibility للأجزاء التي تجاوزت الحد.

إذن الأزمة لها سببان متراكبان، وتم فصل كل سبب عن الآخر بدل ترقيع العرض.

---

# 29. ما تم إثباته

- Current frontend HEAD هو f42bc0...
- Parent هو 7a11af...
- vouchers.html current blob هو 55250...
- source current JavaScript صالح نحويًا.
- previous parser regression مغلق.
- current branch picker defect موجود في pickArr.
- current vehicle picker logic موجود وصحيح ولم يُعاد بناؤه.
- current normalization hardened بالفعل.
- current Production counts صغيرة، لذلك truncation ليست سببًا حاليًا مثبتًا في Production؛ لكنها Defect Scalability مثبت من الكود.
- pagination 500 نجحت على بيانات صناعية حتى 10,005 reps.
- persistent QA data موجودة ولم تُحذف.
- لا Backend migration جديدة مطلوبة.
- لا Edge Function جديدة مطلوبة.

---

# 30. ما لم يُثبت بعد

Authenticated real-browser E2E بعد تطبيق Owner Patch.

لا يجوز تحويل:
Static PASS
إلى:
Browser PASS.

كذلك لم يتم اختبار 10,000+ production entities فعلية لأن Production الحالية لا تحتوي هذه الأعداد، وتم استبدال ذلك باختبار صناعي deterministic.

---

# 31. إرشادات المساعد القادم

1. اقرأ هذا التقرير ثم CURRENT_STATE.
2. طابق erp-frontend/main مع vouchers.html الحالي قبل لمس أي شيء.
3. لا تعد إلى parser fix؛ هو مغلق.
4. طبّق PATCH-313-01 ثم PATCH-313-02 ثم PATCH-313-03 فقط.
5. شغّل JavaScript parse مباشرة بعد الاستبدال.
6. افتح Transfer واختبر wsFrom.
7. اختبر DirectReturn لاكتشاف عدم تضرر vehicle path.
8. اختبر DirectSale بعد اختيار rep.
9. اختبر SupplierReturn بعد اختيار source branch.
10. اختبر Arabic branch search باسم جزئي.
11. اختبر vehicle code + plate + model.
12. بعد التطبيق يجب تسجيل Frontend SHA جديد.
13. نفذ Browser E2E مصادق.
14. خذ Production snapshot جديدًا في نفس لحظة تقرير الإغلاق.
15. لا تعتبر المهمة 100% CLOSED قبل Browser E2E.
16. لا تغير authorization contract أثناء إصلاح search.
17. أي تغيير في Transfer all-company-destination rights يحتاج Business Contract مستقلًا ومراجعة الـRPCs، وليس تغييرًا داخل picker.

---

# 32. الحالة المطلوبة بعد Owner Patch

TARGET:

Current Source
+
PATCH-313
+
Fresh Frontend SHA
+
Browser E2E
+
Fresh Production Snapshot

ثم:

WAREHOUSE VOUCHERS SMART REFERENCE SEARCH
=
100% CLOSED

إلى حين تنفيذ ذلك:
PATCH READY / BROWSER E2E OPEN

---
