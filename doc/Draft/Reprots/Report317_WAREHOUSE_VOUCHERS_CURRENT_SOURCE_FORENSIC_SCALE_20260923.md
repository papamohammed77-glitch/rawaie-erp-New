# Report317 — Vouchers Current-Source Forensic Repair & Scale Closure
## 2026-09-23
## Execution ID: VCH-CURRENT-SOURCE-SCALE-20260923

# 1. نقطة البداية والحالة المعتمدة

تم استرجاع الحالة من:
- MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS
- CURRENT_STATE.md
- EXECUTION_LOG_20260923_VOUCHERS_TRANSFER_SCOPE.md
- Report316
- Current Git
- Current Source
- Current Production
- Current deployed Edge Functions
- current runtime evidence

التقارير التاريخية استُخدمت كسياق فقط، ولم تعتبر حالة حالية.

# 2. Current Git

## System
HEAD:
820a4f314959a743d24ca9f497089b4b0a3058a7

Parent:
2f676b5a7d4af08fbeb978b3d1b8a59ea8acd969

Parent of parent:
165adb8304a5d39d8747a347211ae0939b189af1

## Frontend
HEAD:
5cf09bac46aa65fa1e94ba34dfbdc3760cd446e2

Parent:
2da3d6d9ae6b3e84ea0920998ecdefa94ed4d8e3

Parent of parent:
751f6175675ffe99023337e523501bd35e9553c6

Current vouchers.html blob:
fe0cbf6a6bbacc7086ea4fd8e9e78339e94820a8

Current van-sales.html blob:
8d61382a8e0025a0d079e71dd94f33d106d9088e

Current main.html blob:
8c3d6b05fd6a94a6b488f12b29da85ae888f70bc

لم يتم تعديل:
- main.html
- vouchers.html
- van-sales.html

# 3. Production snapshot

UTC:
2026-09-23 10:23:36.322334

| الكيان | Production |
|---|---:|
| Companies | 1 |
| Branches | 1,354 |
| Active Branches | 1,352 |
| Vehicles | 1,202 |
| Active Vehicles | 1,200 |
| Active Direct Sales Reps | 10,001 |
| Suppliers | 501 |
| Active Suppliers | 500 |
| Stock Vouchers | 42 |
| Inventory Log | 45 |
| Audit Log | 3,950 |
| Active Draft Vouchers | 0 |

# 4. العيب الحقيقي الأول — Stock Sync 400

العنصر:
App.prefetchStock

السطر:
151

Current code:
~~~
prefetchStock:function(silent){var s=this,bids=this.refs.branches.map(function(b){return b.id});if(!bids.length){this.stock={};return Promise.resolve()};if(!silent)RW_UI.showLoader('جاري مزامنة أرصدة المخزون...');return supabase.from('stock_branches').select('branch_id,item_id,qty,allocated_qty').in('branch_id',bids).limit(20000).then(function(r){if(r.error)throw r.error;s.stock={};(r.data||[]).forEach(function(x){s.stock[x.branch_id+':'+x.item_id]=Math.max(0,Number(x.qty||0)-Number(x.allocated_qty||0))});s.markSync();if(!silent)RW_UI.hideLoader();if(s.mode==='voucher')s.renderProducts();return r.data}).catch(function(e){if(!silent)RW_UI.hideLoader();console.error('[VOUCHERS] stock sync failed',e);throw e})},
~~~

Production:
- Active branches = 1,352
- UUID list = 50,023 chars
- full branch_id=in.(...) filter = 50,038 chars

هذا يطابق Console:
[VOUCHERS] stock sync failed / Bad Request

## Root Cause
تم توجيه Query إلى جميع الفروع بينما الشاشة تحتاج رصيد الفرع المصدر الحالي فقط.

العيب ليس في:
- stock_branches schema
- post_stock_movement
- inventory_log
- authorization

الحل:
sourceBranch → one branch_id → stock_branches

# 5. العيب الحقيقي الثاني — stale stock بعد تغيير المصدر

العنصر:
App.updateSource

السطر:
2743

Current:
~~~
updateSource:function(){this.summary();this.renderProducts()},
~~~

الخلل:
اختيار Branch أو Vehicle يغير مصدر المخزون، لكن current updateSource لا يعيد جلب الرصيد.

# 6. العيب الحقيقي الثالث — Realtime giant filter

العنصر:
App.subscribeRealtime

السطر:
149

Current behavior:
- يبني 1,352 branch IDs
- يضعها داخل branch_id=in.(...)

هذا يعيد إنشاء نفس مشكلة giant filter في Realtime.

الجراحة:
إزالة giant branch filter ثم فحص payload branch_id مقابل source branch.

# 7. العيب الحقيقي الرابع — Vehicle Search complexity

العنصر:
App.pickArr

السطر:
1811

Production:
- 1,352 Active Branches
- 1,200 Active Vehicles
- 10,001 Active Direct Reps

Current implementation كان يبحث عن:
- Mobile Branch داخل branches لكل vehicle
- Rep داخل reps لكل vehicle

وهذا يقارب:
O(V×B) + O(V×R)

الحل:
- cache branch index
- cache rep index
- الاحتفاظ بنفس Eligibility Contract

# 8. DirectSale Candidate Reality

Source = BR-01

Production proof:
- Active mobile valid vehicles = 1,200
- vehicles with active direct rep = 1,200
- current valid DirectSale candidates for BR-01 = 1
- active direct reps = 10,001

المرشح الواحد ليس UI data-loss defect.

الـbackend الحالي يشترط للمندوب:
- Active
- role = مندوب بيع مباشر
- van-sales permission
- allowed branch includes source branch

لذلك لا يجب فتح كل 1,200 مركبة في UI ثم رفض معظمها Backend.

هذا Business Contract منفصل عن Search Performance.

# 9. DirectReturn

Current Source يعيد لمسؤول الأذونات:
- Active vehicles
- mobile_stock_enabled != false
- valid mobile branch

Production:
1,200 mobile vehicles صالحة.

لا يوجد backend rewrite.

# 10. Transfer

Current Source:
- wsFrom Transfer = جميع Active Company Branches
- wsTo Transfer = جميع Active Company Branches

Production:
1,352 Active Branches.

Current allowedBranch يتضمن العقد المعتمد:
- role = مخزني
- activeWarehouseRole = أذونات
- same company

لا تعديل مطلوب في:
- allowedBranch
- pickSelect
- Transfer RPC

# 11. Van Sales Integration

الـworkflow المثبت:

Warehouse Vouchers
→ DirectSale
→ Vehicle Mobile Branch
→ van-sales
→ save-sales-invoice
→ save_sales_invoice_atomic
→ post_stock_movement

والعكس:

van-sales
→ DirectReturn
→ Warehouse Vouchers
→ Receive
→ Complete

لا Defect مثبت في van-sales.html يستوجب تغييره.

# 12. Production Backend

تمت إعادة مطابقة:
- create_manual_stock_voucher_atomic
- 12-arg overload
- post_manual_stock_voucher_atomic
- send_stock_voucher_atomic
- DirectReturn vehicle handling
- mobile_branch_id resolution
- post_stock_movement
- audit path

العقد:
Business Movement
→ post_stock_movement
→ stock_branches + inventory_log

لا توجد Edge Function جديدة مطلوبة.

# 13. Production E2E جديد

تم تشغيل Transfer داخل Transaction واحدة:

CREATE
→ SEND
→ RECEIVE
→ RECEIVE REPLAY
→ COMPLETE
→ FINAL CHECK
→ ROLLBACK

النتائج:
- CREATE PASS; IN-43
- SEND PASS; Sent
- RECEIVE PASS; Received
- RECEIVE REPLAY PASS; duplicate=true
- COMPLETE PASS; Completed
- movement_logs = 2
- allocated_qty = 0
- ROLLBACK

IN-43 لم يبق في Production.

# 14. البيانات التجريبية

Production النهائية:
Active Draft Vouchers = 0

المستندات ذات الأثر المخزني لا تُحذف عشوائيًا بسبب guard_stock_voucher_delete_integrity().

تم الحفاظ على التدقيق التاريخي، مع عدم وجود Active Draft QA يعيق التشغيل.

# 15. مشاكل Console الأخرى

## sw.js
Current:
activateAndReloadClients() ينفذ client.navigate(client.url).

Current redirect:
 /app → /companies/company-1/app.html

لكن published artifact لم يكن متاحًا للتحقق عبر أدوات الشبكة الحالية.

Status:
INFRASTRUCTURE OPEN

لم يتم تعديل sw.js في هذه الدورة.

## Tailwind
التحذير صادر من app.html، وليس من vouchers.html.

Status:
NON-BLOCKING INFRASTRUCTURE DEBT

لم يتم تعديل main.html أو app.html.

# 16. OWNER CHANGESET

الملف الوحيد المطلوب تعديله يدويًا:
companies/company-1/warehouse/vouchers.html

Current SHA:
fe0cbf6a6bbacc7086ea4fd8e9e78339e94820a8

## PATCH-317-01
### العنصر
App.prefetchStock
### السطر
151

احذف الدالة كاملة واستبدلها:

~~~
prefetchStock:function(silent){
    var s=this,
        branch=this.sourceBranch(),
        branchId=
            branch&&branch.id
                ?String(branch.id)
                :'';

    if(!branchId){
        this.stock={};

        if(!silent){
            RW_UI.hideLoader();
        }

        if(this.mode==='voucher'){
            this.renderProducts();
        }

        return Promise.resolve([]);
    }

    this._stockBranchId=branchId;

    if(!silent){
        RW_UI.showLoader(
            'جاري مزامنة أرصدة المخزون...'
        );
    }

    return supabase
        .from('stock_branches')
        .select(
            'branch_id,item_id,qty,allocated_qty'
        )
        .eq('branch_id',branchId)
        .limit(20000)
        .then(function(r){

            if(r.error){
                throw r.error;
            }

            s.stock={};

            (r.data||[]).forEach(function(x){

                s.stock[
                    x.branch_id+
                    ':'+
                    x.item_id
                ]=
                    Math.max(
                        0,
                        Number(x.qty||0)-
                        Number(x.allocated_qty||0)
                    );
            });

            s._stockBranchId=branchId;
            s.markSync();

            if(!silent){
                RW_UI.hideLoader();
            }

            if(s.mode==='voucher'){
                s.renderProducts();
            }

            return r.data||[];
        })
        .catch(function(e){

            if(!silent){
                RW_UI.hideLoader();
            }

            console.error(
                '[VOUCHERS] stock sync failed',
                e
            );

            if(silent){
                return [];
            }

            throw e;
        });
},
~~~

## PATCH-317-02
### العنصر
App.updateSource
### السطر
2743

احذف الدالة الحالية:

~~~
updateSource:function(){this.summary();this.renderProducts()},
~~~

واستبدل:

~~~
updateSource:function(){
    var s=this,
        branch=this.sourceBranch(),
        branchId=
            branch&&branch.id
                ?String(branch.id)
                :'';

    clearTimeout(this._sourceStockTimer);

    if(
        this._stockBranchId!==
        branchId
    ){
        this._stockBranchId=
            branchId;

        this.stock={};
    }

    this.summary();
    this.renderProducts();

    if(!branchId){
        return;
    }

    this._sourceStockTimer=
        setTimeout(function(){

            s.prefetchStock(true)
                .catch(function(){
                    /* prefetchStock records exact error */
                });

        },80);
},
~~~

## PATCH-317-03
### العنصر
App.debouncedRefreshStock
### السطر
150

احذف:

~~~
debouncedRefreshStock:function(){var s=this;clearTimeout(this._stockTimer);this._stockTimer=setTimeout(function(){s.prefetchStock(true)},180)},
~~~

واستبدل:

~~~
debouncedRefreshStock:function(){
    var s=this;

    clearTimeout(
        this._stockTimer
    );

    this._stockTimer=
        setTimeout(function(){

            s.prefetchStock(true)
                .catch(function(){
                    /* silent refresh */
                });

        },180);
},
~~~

## PATCH-317-04
### العنصر
App.vehicleBranch
### السطر
1767

احذف الدالة الحالية كاملة من:
vehicleBranch:function(v){

حتى ما قبل:
pickArr:function(key){

واستبدل:

~~~
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

## PATCH-317-05
### العنصر
App.pickArr
### السطر
1811

احذف الدالة الحالية كاملة من:
pickArr:function(key){

حتى ما قبل:
pickShow:function(key){

واستبدل:

~~~
pickArr:function(key){

    var s=this,

        allBranches=
            (s.refs.branches||[])
            .filter(function(x){

                return (
                    String(
                        x.company_id||''
                    )===
                    String(
                        s.company||''
                    ) &&
                    x.is_active!==false
                );
            }),

        userBranches=
            allBranches.filter(
                function(x){
                    return s.allowedBranch(
                        s.user,
                        x
                    );
                }
            ),

        bid=
            (RW_UI.byId('wsFrom')||{})
            .value||
            '',

        b=
            allBranches.find(
                function(x){
                    return (
                        String(x.id)===
                        String(bid)
                    );
                }
            );

    if(key==='wsFrom'){

        if(
            s.type==='DirectReturn'
        ){

            if(
                s.user &&
                s.user.role===
                    'مندوب بيع مباشر'
            ){

                return (
                    s.refs.vehicles||[]
                )
                .filter(function(v){

                    return (
                        v.status==='Active' &&
                        v.mobile_stock_enabled!==false &&
                        v.driver_id===
                            s.user.id &&
                        !!s.vehicleBranch(v)
                    );
                });
            }

            return (
                s.refs.vehicles||[]
            )
            .filter(function(v){

                return (
                    v.status==='Active' &&
                    v.mobile_stock_enabled!==false &&
                    !!s.vehicleBranch(v)
                );
            });
        }

        if(
            s.type==='Transfer'
        ){
            return allBranches;
        }

        return userBranches;
    }

    if(key==='wsRep'){

        return (
            s.refs.reps||[]
        )
        .filter(function(r){

            if(!b){
                return false;
            }

            return (
                s.allowedBranch(
                    s.user,
                    b
                ) &&
                s.allowedBranch(
                    r,
                    b
                )
            );
        });
    }

    if(
        key==='wsTo' &&
        s.type==='Transfer'
    ){
        return allBranches;
    }

    if(
        key==='wsTo' &&
        s.type==='DirectSale'
    ){

        var rid=
            (RW_UI.byId('wsRep')||{})
            .value||
            '';

        var repRows=
            s.refs.reps||[];

        if(
            !s._voucherRepIndex ||
            s._voucherRepIndex.rows!==repRows
        ){

            var repById=
                Object.create(null);

            repRows.forEach(
                function(r){

                    if(
                        r &&
                        r.id
                    ){
                        repById[
                            String(r.id)
                        ]=r;
                    }
                }
            );

            s._voucherRepIndex={
                rows:repRows,
                byId:repById
            };
        }

        var repIndex=
            s._voucherRepIndex.byId;

        return (
            s.refs.vehicles||[]
        )
        .filter(function(v){

            var vb=
                s.vehicleBranch(v);

            var rep=
                repIndex[
                    String(
                        v.driver_id||''
                    )
                ]||
                null;

            return (
                v.status==='Active' &&
                v.mobile_stock_enabled!==false &&
                !!vb &&
                !!b &&
                s.allowedBranch(
                    s.user,
                    b
                ) &&
                !!rep &&
                s.allowedBranch(
                    rep,
                    b
                ) &&
                (
                    !rid ||
                    String(
                        v.driver_id
                    )===String(rid)
                )
            );
        });
    }

    if(
        key==='wsTo' &&
        s.type==='DirectReturn'
    ){
        return userBranches;
    }

    if(
        key==='wsTo' &&
        s.type==='SupplierReturn'
    ){

        var m=
            (
                s.refs
                    .supplierBranchMap||
                {}
            )[bid];

        if(
            m &&
            Object.keys(m).length
        ){

            return (
                s.refs.suppliers||[]
            )
            .filter(function(x){

                return !!m[x.id];
            });
        }

        return [];
    }

    return [];
},
~~~

## PATCH-317-06
### العنصر
App.pickSearch
### السطر
1970

احذف الدالة الحالية كاملة من:
pickSearch:function(key,q){

حتى ما قبل:
pickSelect:function(key,id){

واستبدل:

~~~
pickSearch:function(key,q){

    var s=this,
        arr=this.pickArr(key)||[],
        z=this.norm(q),
        tokens=z
            ?z.split(/s+/)
                .filter(function(x){
                    return !!x;
                })
            :[],
        box=
            RW_UI.byId(
                key+'Menu'
            );

    if(!box){
        return;
    }

    var type=
        key==='wsRep'
            ?'rep'
            :(s.type==='DirectSale' &&
              key==='wsTo')
                ?'vehicle'
                :(s.type==='DirectReturn' &&
                  key==='wsFrom')
                    ?'vehicle'
                    :(key==='wsTo' &&
                      s.type===
                        'SupplierReturn')
                        ?'supplier'
                        :'branch';

    var repById=null;

    if(type==='vehicle'){

        var repRows=
            s.refs.reps||[];

        if(
            !s._voucherRepIndex ||
            s._voucherRepIndex.rows!==repRows
        ){

            var builtRepById=
                Object.create(null);

            repRows.forEach(
                function(r){

                    if(
                        r &&
                        r.id
                    ){
                        builtRepById[
                            String(r.id)
                        ]=r;
                    }
                }
            );

            s._voucherRepIndex={
                rows:repRows,
                byId:builtRepById
            };
        }

        repById=
            s._voucherRepIndex.byId;
    }

    function fieldScore(value){

        var n=s.norm(value);

        if(
            !n ||
            !z
        ){
            return n
                ?5
                :0;
        }

        if(n===z){
            return 150;
        }

        if(n.indexOf(z)===0){
            return 115;
        }

        if(
            tokens.length>1 &&
            tokens.every(
                function(t){
                    return n.indexOf(t)>=0;
                }
            )
        ){
            return 100;
        }

        if(n.indexOf(z)>=0){
            return 70;
        }

        if(
            tokens.length>1 &&
            tokens.some(
                function(t){
                    return n.indexOf(t)>=0;
                }
            )
        ){
            return 40;
        }

        return 0;
    }

    var rows=
        arr
        .map(function(x){

            var vb=
                type==='vehicle'
                    ?s.vehicleBranch(x)
                    :null;

            var vehicleRep=
                type==='vehicle' &&
                repById
                    ?(
                        repById[
                            String(
                                x.driver_id||''
                            )
                        ]||
                        null
                    )
                    :null;

            var fields=
                type==='rep'
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
                            vb && vb.name,
                            vb && vb.branch_code,
                            vehicleRep &&
                                vehicleRep.name,
                            vehicleRep &&
                                vehicleRep.email,
                            vehicleRep &&
                                vehicleRep.phone
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

            fields.forEach(
                function(value){

                    score=Math.max(
                        score,
                        fieldScore(value)
                    );
                }
            );

            var allowed=
                type!=='branch' ||
                s.allowedBranch(
                    s.user,
                    x
                );

            return{
                x:x,
                score:score,
                allowed:allowed
            };
        })
        .filter(function(o){

            return (
                o.score>0 ||
                !z
            );
        })
        .filter(function(o){

            return o.allowed;
        })
        .sort(function(a,b){

            return b.score-a.score;
        })
        .slice(0,15);

    box.innerHTML=
        rows.length
            ?rows.map(
                function(o){

                    var x=o.x,

                        vehicleRep=
                            type==='vehicle' &&
                            repById
                                ?(
                                    repById[
                                        String(
                                            x.driver_id||''
                                        )
                                    ]||
                                    null
                                )
                                :null,

                        vehicleLabel=
                            x.vehicle_code||
                            x.license_plate||
                            x.model||
                            '',

                        vehicleSub=
                            x.license_plate||
                            x.vehicle_code||
                            '';

                    if(
                        type==='vehicle' &&
                        vehicleRep &&
                        (
                            vehicleRep.name||
                            vehicleRep.email
                        )
                    ){

                        vehicleLabel +=
                            ' — '+
                            (
                                vehicleRep.name||
                                vehicleRep.email
                            );
                    }

                    if(
                        type==='vehicle' &&
                        vehicleRep &&
                        vehicleRep.phone
                    ){

                        vehicleSub +=
                            ' · '+
                            vehicleRep.phone;
                    }

                    var label=
                        type==='rep'
                            ?(
                                x.name||
                                x.email
                            )
                            :type==='vehicle'
                                ?vehicleLabel
                                :type==='supplier'
                                    ?(
                                        x.name||
                                        x.supplier_code
                                    )
                                    :(
                                        x.name||
                                        x.branch_code
                                    );

                    var code=
                        type==='rep'
                            ?(
                                x.email||
                                x.phone||
                                ''
                            )
                            :type==='vehicle'
                                ?vehicleSub
                                :type==='supplier'
                                    ?(
                                        x.supplier_code||
                                        x.phone||
                                        ''
                                    )
                                    :(
                                        x.branch_code||
                                        x.location||
                                        ''
                                    );

                    return(
                        '<div class="smart-row cursor-pointer"'+
                        ' onclick="App.pickSelect(&quot;'+
                        s.esc(key)+
                        '&quot;,&quot;'+
                        s.esc(x.id)+
                        '&quot;)">'+
                            '<div>'+
                                '<b class="text-xs text-white">'+
                                    s.esc(label)+
                                '</b>'+
                                '<div class="smart-code">'+
                                    s.esc(code)+
                                '</div>'+
                            '</div>'+
                            '<span class="text-[9px] text-emerald-400">'+
                                'اختيار'+
                            '</span>'+
                        '</div>'
                    );
                }
            ).join('')
            :
            '<div class="smart-empty">لا توجد نتائج مطابقة ضمن دليل الكيانات الحالي</div>';

    box.classList.remove('hidden');
},
~~~

# 17. لماذا لم يتم تعديل

لا تعديل:
- main.html
- van-sales.html
- loadRefs
- norm
- allowedBranch
- pickSelect
- routeHtml
- submit
- prepare

لأن هذه الأجزاء لم يظهر فيها defect جديد يستوجب الجراحة.

# 18. Production changes in this continuation

لا يوجد Production schema change مطلوب للجراحة الحالية.

تم تنفيذ والتحقق من E2E فقط داخل Transaction مع Rollback.

لا:
- Edge Function جديدة
- Table جديدة
- RPC جديدة
- RLS جديدة
- Physical Stock engine جديد

# 19. Competitive review

## Odoo
Barcode operations وTransfers وBatch Transfers.
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/barcode/operations.html

## Dynamics 365
Transfer Orders وShip/Receive وQuantity in transit وTransfer Routes وBatch posting.
https://learn.microsoft.com/en-us/dynamics365/business-central/inventory-how-transfer-between-locations
https://learn.microsoft.com/en-us/dynamics365/business-central/inventory-how-setup-locations

## SAP
one-step/two-step transfer وstock transport orders وstock in transit.
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/9905622a5c1f49ba84e9076fc83a9c2c/c864bd534f22b44ce10000000a174cb4.html
https://help.sap.com/docs/SAP_S_S4HANA_SUPPLYCHAIN_INTEGRATION_ADDON_FOR_SAP_INTEGRATED_BUSINESS_PLANNING/ce74cb613bb44bc1925126c84b191ad9/1e89de55a5fea544e10000000a44147b.html

## Daftra
manual transfer وbefore/after stock وnotes وattachments وتقارير الحركة التفصيلية.
https://docs.daftra.com/en/user_manual/transferring-items-from-one-warehouse-to-another/
https://docs.daftra.com/en/tutorial/transferring-stock/
https://docs.daftra.com/en/tutorial/inventory-detailed-transactions-report/

## Manager.io
Inventory Transfers مع date/reference/description/item/qty/from/to وتعديل الكميات تلقائيًا.
https://www2.manager.io/guides/10707

## RAWAEA
الموجود بالفعل:
- Branch → Branch Transfer
- Vehicle/mobile custody
- DirectSale
- DirectReturn
- barcode/item search
- before/after stock visibility
- audit trail
- central stock movement
- separate operational applications

المساحات المستقبلية:
- ETA
- transit aging
- attachments/proof
- batch transfer
- saved filters
- deeper transfer analytics

لا تعتبر هذه عيوبًا حالية.

# 20. Deployment Evidence

GitHub Actions:
لا توجد workflow runs مرتبطة بالـFrontend HEAD الحالي.

Combined status:
لا توجد status checks.

الوصول العام إلى Pages تعذر من أدوات الشبكة الحالية.

لذلك:
Published Artifact = OPEN / UNVERIFIED
Authenticated Browser E2E = OPEN / UNVERIFIED

ولا يجوز تحويلهما إلى PASS بالتخمين.

# 21. SELF-AUDIT

## Confirmed Facts
- giant stock filter = 50,038 chars
- Active Branches = 1,352
- Active Vehicles = 1,200
- Active Direct Reps = 10,001
- Active Suppliers = 500
- Transfer branch scope = all active same-company branches
- DirectReturn valid vehicles = 1,200
- DirectSale BR-01 current eligible candidate count = 1
- backend E2E PASS
- retry RECEIVE duplicate=true
- no test data remains from IN-43
- active voucher drafts = 0
- current vouchers source has stock sync defect
- current source has stale source-stock defect
- current realtime has giant branch filter
- current vehicle candidate resolution has avoidable nested lookups

## Unknown
- exact served Pages artifact
- authenticated browser runtime after owner patch

## Conflicts
Historical reports contain older frontend SHAs.
Current frontend HEAD is 5cf09bac46aa65fa1e94ba34dfbdc3760cd446e2.

# 22. FINAL STATUS

Production backend voucher lifecycle:
CLOSED / VERIFIED

Physical Stock Core:
CLOSED

Transfer authorization:
CLOSED

QA cleanup:
CLOSED

Current Source forensic diagnosis:
PROVEN

Owner Source Patch:
READY

Published Artifact:
OPEN

Browser Authenticated E2E:
OPEN

Overall Voucher Unit:
PARTIALLY CLOSED

لا تستخدم:
100% CLOSED
ZERO-DEBT
GOLD
DIAMOND

قبل نشر الـOwner Patch وتشغيل browser E2E والتحقق من الـserved artifact.

# 23. NEXT EXACT RESUMPTION POINT

1. Verify Frontend HEAD:
   5cf09bac46aa65fa1e94ba34dfbdc3760cd446e2
2. Verify vouchers blob:
   fe0cbf6a6bbacc7086ea4fd8e9e78339e94820a8
3. Apply PATCH-317-01 through PATCH-317-06 only.
4. Parse vouchers.html.
5. Confirm no giant stock IN(...) filter.
6. Confirm stock request is source-branch scoped.
7. Confirm realtime has no all-branch giant filter.
8. Confirm vehicle search can use vehicle + rep identity.
9. Publish.
10. Verify served artifact identity.
11. Run authenticated E2E.
12. Capture fresh Production snapshot.
13. Update CURRENT_STATE.
14. Close only proven surfaces.

# END
