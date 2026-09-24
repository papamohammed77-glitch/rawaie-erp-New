# تقرير التنفيذ الجنائي النهائي — تطبيق الأذونات المخزنية
## Closure: Transfer Receive + Draft Print + Current Voucher Integrity
**التاريخ:** 2026-09-24  
**النطاق:** `companies/company-1/warehouse/vouchers.html` + Production Supabase فقط  
**ممنوع التعديل:** `companies/company-1/main.html` وملف `vouchers.html` نفسه  
**مصدر الحقيقة:** CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE

---

## 1. نقطة الاستئناف المعتمدة

تم الاستئناف من:
- `CURRENT_STATE.md`
- MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS
- Report318 / Report319 كسياق تاريخي فقط
- أحدث Git وParent
- المصدر الحالي الحقيقي للـvoucher
- Production الحالية
- الـRPCs والـEdge الحالية

### الحالة الحالية قبل Owner Patch
- Mother frontend repository: `papamohammed77-glitch/erp-frontend`
- أحدث commit المثبت: `73e02aaf3a75fd06571475cbf2df26074e91f50d`
- هذا الـcommit عدّل forensic extract فقط، ولم يعدّل `vouchers.html`.
- Current `vouchers.html` SHA: `a0ab1bc7746be6f0f4342d87fdcc2657e87b8334`
- Current `vouchers.html` lines: 3905
- Current Production user:
  - `vouchers@rawaea.com`
  - role = مخزني
  - active_warehouse_role = أذونات
  - status = Active

---

## 2. ما ثبت تاريخيًا وما ثبت الآن

التقارير السابقة أثبتت أن:
- Physical Stock centralization مكتمل.
- Transfer backend lifecycle موجود ومركزي.
- Edit/Delete capabilities موجودة في Production.
- `printDraftVoucher` موجودة في المصدر الحالي.
- Browser E2E ظل مفتوحًا فقط لغياب جلسة Browser مصادق عليها.

لم تتم إعادة بناء أي من هذه الأجزاء.

الحالة الحالية أضافت ثلاث نقاط مصدرية مثبتة:
1. Draft print موجود لكنه غير مربوط بزر Draft.
2. `receive()` تحتوي خطأ scope حقيقي.
3. `pickSearch` فيها خطأ literal واحد: `split(/s+/)`.
4. Realtime الحالي يعيد giant branch filter.
5. `updateSource()` لا يعيد بناء realtime عند تغيير المصدر.
6. Draft actions الحالية لا توصل Edit/Delete/Print.

---

## 3. Production Contract — Transfer

العقد المثبت في Production:

`Draft → Send → Receive → Complete`

### Send
`send_stock_voucher_atomic`
- يثبت الإذن.
- يخصم من المصدر.
- ينشئ Physical OUT عبر `post_stock_movement`.

### Receive
`post_manual_stock_voucher_atomic`
- يتحقق من:
  - الشركة
  - الفرع
  - الصنف
  - الاتجاه
  - الكمية المتبقية
  - operation_id
- ينشئ Physical IN عبر `post_stock_movement`.
- يحدّث `received_qty`.

### Complete
`complete_manual_stock_voucher_atomic`
- ينقل الحالة إلى `Completed`.

لا يوجد Physical Stock writer مستقل في هذه الدورة.

---

## 4. Production E2E المنفذ فعليًا

تم استخدام الإذن الموجود فعليًا:
- Voucher: `IN-2`
- Type: Transfer
- Source: BR-01
- Target: BR-2
- Items: 1001 / 1003 / 1004 / 1005 / 1006
- كمية الاختبار: 1 لكل صنف

### القياس

Source قبل Send:
- 1001 = 11
- 1003 = 10
- 1004 = 11
- 1005 = 10
- 1006 = 12

بعد Send:
- 1001 = 10
- 1003 = 9
- 1004 = 10
- 1005 = 9
- 1006 = 11

بعد Receive:
- Target BR-2:
  - 1001 = 1
  - 1003 = 1
  - 1004 = 1
  - 1005 = 1
  - 1006 = 1

Replay بنفس operation_id:
- `duplicate = true`
- لا حركة ثانية.

Complete:
- status = `Completed`

### Conservation proof
- stock total before = 54
- stock total after = 54
- conservation = TRUE
- movement rows = 10
  - 5 OUT
  - 5 IN

### Cleanup proof
بعد Rollback:
- IN-2 = Draft
- inventory_log for IN-2 = 0
- لا توجد stock rows اختبارية جديدة في BR-2
- temporary QA function = 0

**النتيجة: Production Transfer core = CLOSED / VERIFIED**

---

## 5. Root Cause — Draft Print

### الموجود بالفعل
الدالة:
`printDraftVoucher:function(code)`

موجودة في Current Source ومبنية على:
- قراءة voucher من Production.
- قراءة details من Production.
- التحقق من `Draft`.
- فتح نافذة طباعة مستقلة.
- عدم تنفيذ أي حركة مخزنية.

إذن المشكلة ليست داخل print engine.

### السبب الحقيقي
داخل:
`App.cards(rows,scope)`

كتلة:
`if(act==='draft')`

لا تحتوي على:
`App.printDraftVoucher(...)`

### العلاج
استبدال **Draft action block فقط**.

الملف:
`companies/company-1/warehouse/vouchers.html`

الدالة:
`App.cards(rows,scope)`

السطر الحالي:
حوالي **730**

ابحث عن:
```javascript
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
```

احذفه تمامًا واستبدله:
```javascript
if(act==='draft'){
    a+=
        '<button onclick="event.stopPropagation();App.editVoucher(\''+
        s.esc(v.voucher_code)+
        '\')" class="bg-amber-500 text-white px-3 py-2 rounded-xl text-xs font-black">تعديل</button>';

    a+=
        '<button onclick="event.stopPropagation();App.deleteVoucher(\''+
        s.esc(v.voucher_code)+
        '\')" class="bg-rose-600 text-white px-3 py-2 rounded-xl text-xs font-black">حذف</button>';

    a+=
        '<button onclick="event.stopPropagation();App.printDraftVoucher(\''+
        s.esc(v.voucher_code)+
        '\')" class="bg-slate-700 text-white px-3 py-2 rounded-xl text-xs font-black">طباعة</button>';

    a+=
        '<button onclick="event.stopPropagation();App.send(\''+
        s.esc(v.voucher_code)+
        '\')" class="bg-indigo-600 text-white px-3 py-2 rounded-xl text-xs font-black">إرسال</button>';
}
```

---

## 6. Root Cause — Receive “V is not defined”

### المصدر الحقيقي
الدالة:
`receive:function(code)`

السطر:
**1928**

المشكلة ليست في RPC ولا في Production.

داخل أول callback يوجد:
```javascript
var v=r.data;
```

ثم في callback التالي يتم استخدام:
```v.id
```

لكن `v` محلي داخل callback الأول.

### العلاج الجراحي — لا تعاد كتابة الدالة

### PATCH RCV-01
ابحث داخل:
`receive:function(code)`

عن:
```javascript
receive:function(code){var s=this;
```

استبدله فقط:
```javascript
receive:function(code){var s=this,voucherId=null;
```

### PATCH RCV-02
ابحث داخل **نفس الدالة فقط** عن:
```javascript
var v=r.data;
```

استبدله:
```javascript
var v=r.data;voucherId=v.id;
```

### PATCH RCV-03
يوجد استخدامان فقط لـ:
```javascript
s.company+':'+v.id
```

داخل callback الثاني.

استبدل الاثنين فقط بـ:
```javascript
s.company+':'+voucherId
```

لا تغيّر:
- receivedItems
- operation_id
- preConfirm
- كمية الاستلام
- RPC
- حالة الإذن
- retry semantics

### نتيجة الإصلاح
`v` لم يعد مطلوبًا في callback الثاني.
الهوية تنتقل صراحة عبر:
`voucherId`

---

## 7. PATCH SCALE-01 — pickSearch

### السبب
Current Source contains:
```javascript
z.split(/s+/)
```

وهذا لا يطابق whitespace.

### الإجراء الجراحي
في:
`App.pickSearch(key,q)`

ابحث عن **النص الوحيد**:
```javascript
z.split(/s+/)
```

استبدله فقط:
```javascript
z.split(/\s+/)
```

لا تعدل بقية الدالة.

---

## 8. PATCH SCALE-02 — subscribeRealtime

### السبب
Current Source ما زال يبني:
```
branch_id=in.(...)
```

لكل الفروع.

هذا يعيد مشكلة الحجم التي ثبتت سابقًا في Production scale.

### الإجراء
الملف:
`vouchers.html`

الدالة:
`App.subscribeRealtime()`

السطر الحالي:
**149**

احذف الدالة كاملة واستبدلها:
```javascript
subscribeRealtime:function(){var s=this;if(!supabase||!supabase.channel)return;this.unsubscribeRealtime();var ch=supabase.channel('rw-vouchers-live-'+s.company).on('postgres_changes',{event:'*',schema:'public',table:'stock_vouchers',filter:'company_id=eq.'+s.company},function(){s.debouncedRefresh()}).on('postgres_changes',{event:'*',schema:'public',table:'stock_voucher_details'},function(){s.debouncedRefresh()});var source=s.sourceBranch();if(source&&source.id){ch.on('postgres_changes',{event:'*',schema:'public',table:'stock_branches',filter:'branch_id=eq.'+String(source.id)},function(){s.debouncedRefreshStock()})}ch.subscribe(function(status){s.updateConnection(status==='SUBSCRIBED');if(status==='SUBSCRIBED')s.markSync()});this.realtime=ch},
```

### النتيجة
- vouchers company-scoped.
- stock_vouchers detail refresh.
- stock_branches يستمع فقط للمصدر الحالي.
- تغيير المصدر لا يسبب giant realtime filter.

---

## 9. PATCH SCALE-03 — updateSource

### السبب
Current Source يغيّر stock context لكنه لا يعيد بناء realtime channel.

### الإجراء
الملف:
`vouchers.html`

الدالة:
`App.updateSource()`

السطر الحالي:
**حوالي 3375**

احذف الدالة كاملة واستبدلها:
```javascript
updateSource:function(){var s=this,branch=this.sourceBranch(),branchId=branch&&branch.id?String(branch.id):'';clearTimeout(this._sourceStockTimer);var branchChanged=this._stockBranchId!==branchId;if(branchChanged){this._stockBranchId=branchId;this.stock={};if(this.company&&supabase)this.subscribeRealtime()}this.summary();this.renderProducts();if(!branchId)return;this._sourceStockTimer=setTimeout(function(){s.prefetchStock(true).catch(function(){});},80)},
```

### النتيجة
عند تغيير المصدر:
1. يتغير `_stockBranchId`.
2. يتم تصفير stock cache.
3. يعاد إنشاء realtime subscription.
4. يتم prefetch للمصدر الجديد.

---

## 10. PATCH UX-01 — choose

### السبب
اختيار نوع جديد لا يمسح هوية عمليات Edit/Create السابقة.

### الإجراء
الملف:
`vouchers.html`

الدالة:
`App.choose(t)`

السطر الحالي:
**298**

احذف الدالة كاملة واستبدلها:
```javascript
choose:function(t){
    this.editVoucherCode=null;
    this.editOperationId=null;
    this.editFingerprint=null;
    this.createOpId=null;
    this.createFingerprint=null;
    this.type=t;
    this.mode=(t==='Scrap'||t==='Adjustment')?'engine':'voucher';
    this.toggleMenu();
    this.newWorkspace();
}
```

---

## 11. PATCH UX-02 — Edit/Delete Draft

الـProduction capabilities موجودة بالفعل:
- `update_manual_stock_voucher_atomic`
- `delete_manual_stock_voucher_atomic`

لا Edge Function جديدة.

### المشكلة الحالية
Current UI لا يحتوي consumers لهاتين الـcapabilities.

### الإجراء
الملف:
`vouchers.html`

موضع الإدراج:
**مباشرة قبل**:
```javascript
prepare:function()
```

أدرج الكتلة التالية كاملة:
```javascript
editVoucher:function(code){
    var s=this;

    RW_UI.showLoader(
        'جاري فتح المسودة...'
    );

    supabase
        .from('stock_vouchers')
        .select('*,stock_voucher_details(*)')
        .eq('company_id',s.company)
        .eq('voucher_code',code)
        .maybeSingle()
        .then(function(r){

            if(r.error){
                throw r.error;
            }

            if(!r.data){
                throw new Error(
                    'الإذن غير موجود'
                );
            }

            var v=r.data;

            if(v.status!=='Draft'){
                throw new Error(
                    'لا يمكن تعديل إذن بعد إرساله'
                );
            }

            s.mode='edit';
            s.editVoucherCode=v.voucher_code;
            s.editOperationId=null;
            s.editFingerprint=null;

            s.type=v.type;
            s.topPanelCollapsed=false;
            s.cat='الكل';

            s.cart=
                (v.stock_voucher_details||[])
                .map(function(x){
                    return{
                        id:x.item_id,
                        code:x.item_code,
                        name:x.item_name||x.item_code,
                        unit:x.unit||'حبة',
                        qty:Number(x.qty)||0,
                        unitPrice:Number(
                            x.unit_price||0
                        )||0,
                        notes:x.notes||''
                    };
                })
                .filter(function(x){
                    return(
                        x.id &&
                        x.code &&
                        x.qty>0
                    );
                });

            return s.prepare()
                .then(function(){
                    s.renderWorkspace();

                    var from=
                        RW_UI.byId('wsFrom');

                    var fromSearch=
                        RW_UI.byId('wsFromSearch');

                    var to=
                        RW_UI.byId('wsTo');

                    var toSearch=
                        RW_UI.byId('wsToSearch');

                    var rep=
                        RW_UI.byId('wsRep');

                    var repSearch=
                        RW_UI.byId('wsRepSearch');

                    if(from){
                        from.value=
                            v.from_id||'';
                    }

                    if(to){
                        to.value=
                            v.to_id||'';
                    }

                    if(rep){
                        rep.value=
                            v.custodian_user_id||'';
                    }

                    if(s.type==='DirectReturn'){

                        var vv=
                            (s.refs.vehicles||[])
                            .find(function(x){
                                return x.id===v.from_id;
                            });

                        var rr=
                            vv&&
                            (s.refs.reps||[])
                            .find(function(x){
                                return x.id===vv.driver_id;
                            });

                        if(fromSearch){
                            fromSearch.value=
                                vv
                                    ?(
                                        vv.vehicle_code||
                                        vv.license_plate||
                                        vv.model||
                                        ''
                                    )
                                    :'';
                        }

                        if(rep){
                            rep.value=
                                rr
                                    ?rr.id
                                    :'';
                        }

                        if(repSearch){
                            repSearch.value=
                                rr
                                    ?(
                                        rr.name||
                                        rr.email||
                                        ''
                                    )
                                    :'';
                            repSearch.setAttribute(
                                'readonly',
                                'readonly'
                            );
                        }

                    }else if(
                        s.type==='DirectSale'
                    ){

                        var bb=
                            (s.refs.branches||[])
                            .find(function(x){
                                return x.id===v.from_id;
                            });

                        var rv=
                            (s.refs.vehicles||[])
                            .find(function(x){
                                return x.id===v.to_id;
                            });

                        var rp=
                            (s.refs.reps||[])
                            .find(function(x){
                                return x.id===v.custodian_user_id;
                            });

                        if(fromSearch){
                            fromSearch.value=
                                bb
                                    ?(
                                        bb.name||
                                        bb.branch_code||
                                        ''
                                    )
                                    :'';
                        }

                        if(toSearch){
                            toSearch.value=
                                rv
                                    ?(
                                        rv.vehicle_code||
                                        rv.license_plate||
                                        rv.model||
                                        ''
                                    )
                                    :'';
                        }

                        if(repSearch){
                            repSearch.value=
                                rp
                                    ?(
                                        rp.name||
                                        rp.email||
                                        ''
                                    )
                                    :'';
                            repSearch.removeAttribute(
                                'readonly'
                            );
                        }

                    }else{

                        if(fromSearch){
                            fromSearch.value=
                                s.loc(
                                    v.from_id,
                                    v.from_type
                                );
                        }

                        if(toSearch){
                            toSearch.value=
                                s.loc(
                                    v.to_id,
                                    v.to_type
                                );
                        }

                        if(repSearch){
                            repSearch.value=
                                '';
                            repSearch.removeAttribute(
                                'readonly'
                            );
                        }
                    }

                    var ref=
                        RW_UI.byId('wsRef');

                    var notes=
                        RW_UI.byId('wsNotes');

                    if(ref){
                        ref.value=
                            v.reference||'';
                    }

                    if(notes){
                        notes.value=
                            v.notes||'';
                    }

                    s.renderCart();
                    s.summary();
                    s.updateSource();
                });
        })
        .then(function(){
            RW_UI.hideLoader();
        })
        .catch(function(e){
            RW_UI.hideLoader();
            RW_UI.showError(
                e.message||
                'تعذر فتح المسودة للتعديل'
            );
        });
},
deleteVoucher:function(code){
    var s=this;

    Swal.fire({
        title:'حذف المسودة نهائيًا؟',
        text:'سيتم حذف الإذن المسودة وتفاصيله نهائيًا دون إنشاء سجل إلغاء.',
        icon:'warning',
        showCancelButton:true,
        confirmButtonText:'حذف نهائي',
        cancelButtonText:'رجوع',
        confirmButtonColor:'#dc2626',
        reverseButtons:true
    }).then(function(a){

        if(!a.isConfirmed){
            return;
        }

        RW_UI.showLoader(
            'جاري حذف المسودة...'
        );

        RW_API.call(
            'create-stock-voucher',
            {
                action:'delete',
                voucher_code:code
            },
            function(j){

                RW_UI.hideLoader();

                if(j&&j.success){

                    RW_UI.toast(
                        'تم حذف المسودة نهائيًا',
                        'success'
                    );

                    s.loadList(s.tabName);
                    return;
                }

                RW_UI.showError(
                    (j&&j.msg)||
                    'فشل حذف المسودة'
                );
            }
        );
    });
}
```

لا تحذف `prepare`.

---

## 12. PATCH UX-03 — submit

### السبب
Current `submit()` لا يحتوي مسار:
`mode === 'edit'`

والـbackend update capability موجودة بالفعل.

### الإجراء
الملف:
`vouchers.html`

الدالة:
`App.submit()`

السطر الحالي:
**حوالي 3445**

احذف الدالة كاملة واستبدلها بالنص التالي:
```javascript
submit:function(){
    var s=this;

    if(!this.cart.length){
        RW_UI.toast('أضف صنفاً واحداً على الأقل','warning');
        return;
    }

    var ref=(RW_UI.byId('wsRef')||{}).value.trim();
    var notes=(RW_UI.byId('wsNotes')||{}).value.trim();
    var fr=(RW_UI.byId('wsFrom')||{}).value||'';
    var to=(RW_UI.byId('wsTo')||{}).value||'';
    var rep=(RW_UI.byId('wsRep')||{}).value||'';

    if(!ref){
        RW_UI.toast('المرجع إجباري','warning');
        return;
    }

    if(!fr){
        RW_UI.toast('المصدر مطلوب','warning');
        return;
    }

    if(this.mode==='engine'){
        if(!notes){
            RW_UI.toast('السبب إجباري','warning');
            return;
        }

        var mode=this.type==='Scrap'
            ?'deduct'
            :((RW_UI.byId('wsMode')||{}).value||'replace');

        RW_UI.showLoader('جاري تنفيذ الحركة...');

        RW_API.call(
            'bulk-stock-adjustment',
            {
                branch_id:fr,
                adjustment_type:mode,
                voucher_code:ref,
                reason:notes,
                items:this.cart.map(function(x){
                    return{
                        item_id:x.id,
                        item_code:x.code,
                        qty:x.qty
                    };
                })
            },
            function(j){
                RW_UI.hideLoader();

                if(j&&j.success){
                    RW_UI.toast(
                        j.duplicate
                            ?'تم التعرف على العملية السابقة'
                            :'تم تنفيذ الحركة',
                        'success'
                    );
                    s.back();
                }else{
                    RW_UI.showError(
                        (j&&j.msg)||'فشل تنفيذ الحركة'
                    );
                }
            }
        );

        return;
    }

    if(!to){
        RW_UI.toast('الوجهة مطلوبة','warning');
        return;
    }

    if(this.type==='DirectSale'){
        var r=(this.refs.reps||[]).find(function(x){
            return x.id===rep;
        });
        var v=(this.refs.vehicles||[]).find(function(x){
            return x.id===to;
        });
        var b=(this.refs.branches||[]).find(function(x){
            return x.id===fr;
        });

        if(
            !r||
            !v||
            v.driver_id!==r.id||
            !b||
            !s.allowedBranch(r,b)||
            !s.vehicleBranch(v)
        ){
            RW_UI.toast(
                'الفرع والمندوب والمركبة غير متسقين',
                'error'
            );
            return;
        }
    }

    if(this.type==='DirectReturn'){
        var vv=(this.refs.vehicles||[]).find(function(x){
            return x.id===fr;
        });
        var bb=(this.refs.branches||[]).find(function(x){
            return x.id===to;
        });
        var rr=vv&&(this.refs.reps||[]).find(function(x){
            return x.id===vv.driver_id;
        });

        if(
            !vv||
            !bb||
            !rr||
            !s.allowedBranch(rr,bb)||
            !s.vehicleBranch(vv)
        ){
            RW_UI.toast(
                'المركبة والمندوب وفرع المرتجع غير متسقين',
                'error'
            );
            return;
        }
    }

    if(this.type==='SupplierReturn'){
        var sb=(this.refs.branches||[]).find(function(x){
            return x.id===fr;
        });
        var sp=(this.refs.suppliers||[]).find(function(x){
            return x.id===to;
        });
        var map=(s.refs.supplierBranchMap||{})[fr];

        if(
            !sb||
            !sp||
            !map||
            !map[sp.id]
        ){
            RW_UI.toast(
                'لا يوجد ربط موثق بين المورد والفرع',
                'error'
            );
            return;
        }
    }

    if(this.mode==='edit'){

        var editFt=
            this.type==='DirectReturn'
                ?'Vehicle'
                :'Branch';

        var editTt=
            this.type==='DirectSale'
                ?'Vehicle'
                :this.type==='SupplierReturn'
                    ?'Supplier'
                    :'Branch';

        var editItems=
            this.cart
                .map(function(x){
                    return{
                        itemCode:x.code,
                        itemName:x.name||x.code,
                        unit:x.unit||'حبة',
                        qty:Number(x.qty)||0,
                        unitPrice:Number(
                            x.unitPrice||
                            x.unit_price||
                            0
                        )||0,
                        notes:x.notes||''
                    };
                })
                .sort(function(a,b){
                    return String(
                        a.itemCode
                    ).localeCompare(
                        String(b.itemCode)
                    );
                });

        var editFingerprint=
            JSON.stringify({
                voucher_code:this.editVoucherCode,
                type:this.type,
                reference:ref,
                from_id:fr,
                to_id:to,
                rep_id:rep||null,
                notes:notes,
                items:editItems
            });

        var editStorageKey=
            'RW_VOUCHER_UPDATE:'+
            s.company+':'+
            this.editVoucherCode;

        var editOperationId=null;

        try{
            var cachedEdit=
                localStorage.getItem(
                    editStorageKey
                );

            if(cachedEdit){
                var previousEdit=
                    JSON.parse(cachedEdit);

                if(
                    previousEdit &&
                    previousEdit.fingerprint===
                        editFingerprint &&
                    previousEdit.operation_id
                ){
                    editOperationId=
                        previousEdit.operation_id;
                }
            }
        }catch(e){}

        if(!editOperationId){

            editOperationId=
                window.crypto &&
                crypto.randomUUID
                    ?crypto.randomUUID()
                    :'UI-UPDATE:'+
                     s.company+':'+
                     this.editVoucherCode+':'+
                     Date.now()+':'+
                     Math.random()
                        .toString(36)
                        .slice(2);

            try{
                localStorage.setItem(
                    editStorageKey,
                    JSON.stringify({
                        operation_id:
                            editOperationId,
                        fingerprint:
                            editFingerprint,
                        created_at:
                            new Date().toISOString()
                    })
                );
            }catch(e){}
        }

        s.editOperationId=
            editOperationId;

        s.editFingerprint=
            editFingerprint;

        RW_UI.showLoader(
            'جاري حفظ تعديل المسودة...'
        );

        RW_API.call(
            'create-stock-voucher',
            {
                action:'update',
                voucher_code:
                    this.editVoucherCode,
                operation_id:
                    editOperationId,
                type:this.type,
                reference:ref,
                fromType:editFt,
                fromId:fr,
                toType:editTt,
                toId:to,
                rep_id:rep||null,
                notes:notes,
                items:editItems
            },
            function(j){

                RW_UI.hideLoader();

                if(j&&j.success){

                    try{
                        localStorage.removeItem(
                            editStorageKey
                        );
                    }catch(e){}

                    s.editVoucherCode=null;
                    s.editOperationId=null;
                    s.editFingerprint=null;

                    RW_UI.toast(
                        j.duplicate
                            ?'تم التعرف على تعديل المسودة السابق'
                            :'تم تحديث المسودة بنجاح',
                        'success'
                    );

                    s.back();
                    return;
                }

                RW_UI.showError(
                    (j&&j.msg)||
                    'فشل تحديث المسودة — تم الاحتفاظ بهوية العملية لإعادة المحاولة بأمان'
                );
            }
        );

        return;
    }

    var ft=this.type==='DirectReturn'
        ?'Vehicle'
        :'Branch';

    var tt=this.type==='DirectSale'
        ?'Vehicle'
        :this.type==='SupplierReturn'
            ?'Supplier'
            :'Branch';

    var normalizedItems=this.cart
        .map(function(x){
            return{
                itemCode:x.code,
                itemName:x.name||x.code,
                unit:x.unit||'حبة',
                qty:Number(x.qty)||0,
                unitPrice:Number(x.unitPrice||x.unit_price||0)||0,
                notes:x.notes||''
            };
        })
        .sort(function(a,b){
            return String(a.itemCode).localeCompare(
                String(b.itemCode)
            );
        });

    var fingerprint=JSON.stringify({
        type:this.type,
        reference:ref,
        from_id:fr,
        to_id:to,
        rep_id:rep||null,
        notes:notes,
        items:normalizedItems
    });

    var storageKey='RW_VOUCHER_CREATE:'+s.company+':'+s.type;
    var operationId=null;

    try{
        var cached=localStorage.getItem(storageKey);

        if(cached){
            var previous=JSON.parse(cached);

            if(
                previous &&
                previous.fingerprint===fingerprint &&
                previous.operation_id
            ){
                operationId=previous.operation_id;
            }
        }
    }catch(e){}

    if(!operationId){
        operationId=
            window.crypto &&
            crypto.randomUUID
            ?crypto.randomUUID()
            :'UI-CREATE:'+s.company+':'+
             this.type+':'+
             Date.now()+':'+
             Math.random().toString(36).slice(2);

        try{
            localStorage.setItem(
                storageKey,
                JSON.stringify({
                    operation_id:operationId,
                    fingerprint:fingerprint,
                    created_at:new Date().toISOString()
                })
            );
        }catch(e){}
    }

    s.createOpId=operationId;
    s.createFingerprint=fingerprint;

    RW_UI.showLoader('جاري حفظ المسودة...');

    RW_API.call(
        'create-stock-voucher',
        {
            type:this.type,
            reference:ref,
            fromType:ft,
            fromId:fr,
            toType:tt,
            toId:to,
            rep_id:rep||null,
            operation_id:operationId,
            notes:notes,
            items:normalizedItems
        },
        function(j){
            RW_UI.hideLoader();

            if(j&&j.success){
                try{
                    localStorage.removeItem(storageKey);
                }catch(e){}

                s.createOpId=null;
                s.createFingerprint=null;

                RW_UI.toast(
                    j.duplicate
                        ?'تم استرجاع نتيجة عملية الحفظ السابقة'
                        :'تم إنشاء '+(
                            j.voucher_code||
                            j.voucherId||
                            'الإذن'
                        ),
                    'success'
                );

                s.back();
                return;
            }

            RW_UI.showError(
                (j&&j.msg)||
                'فشل إنشاء الإذن — تم الاحتفاظ بهوية العملية لإعادة المحاولة بأمان'
            );
        }
    );
}
```

تمت إزالة تكرار `var ft` الموجود في صياغة التقرير التاريخي قبل اعتماد الـchangeset.

---

## 13. PATCH UX-04 — back

### السبب
الرجوع من Edit لا يمسح operation identity.

### الإجراء
الملف:
`vouchers.html`

الدالة:
`App.back()`

السطر الحالي:
**3729**

احذف الدالة كاملة واستبدلها:
```javascript
back:function(){
    this.mode=null;
    this.cart=[];
    this.editVoucherCode=null;
    this.editOperationId=null;
    this.editFingerprint=null;
    this.createOpId=null;
    this.createFingerprint=null;
    this.tab(this.tabName);
    var l=RW_UI.byId('typeLabel');
    if(l){
        l.textContent='إذن جديد';
    }
}
```

---

## 14. ما لم يتم تعديله

### Frontend
لم تتم الكتابة إلى:
- `companies/company-1/warehouse/vouchers.html`
- `companies/company-1/main.html`
- `companies/company-1/sales/van-sales.html`

### Production
لم يتم إنشاء:
- Edge Function جديدة.
- جدول جديد.
- RLS جديد.

ولم يتم تغيير:
- Physical Stock engine.
- Reservation engine.
- Order fulfillment.
- Runsheet logic.
- Picker.
- Mother ERP.

---

## 15. Production infrastructure

الـbackend الحالي كافٍ لإغلاق المطلوب.

المستخدم شدد على عدم إنشاء Edge جديدة بسبب حد الوظائف/spend cap؛ تم الالتزام بذلك.

الـReceive الحالي يستمر عبر:
`receive-stock-voucher`
→ `post_manual_stock_voucher_atomic`
→ `post_stock_movement`

والـSend عبر:
`send-stock-voucher / send_stock_voucher_atomic`

ولا يوجد مسار جديد.

---

## 16. العلاقات والتكامل

### Mother ERP
Mother هو مصدر:
- Company
- Branch
- Vehicle
- Representative
- Supplier
- Users/Roles
- Permissions

Vouchers لا ينشئ نسخة مستقلة من هذه البيانات.

### Voucher App
وظيفته:
**Warehouse operations not coupled to Orders/Runsheets**

يشمل:
- Transfer
- Direct Sale
- Direct Return
- Supplier Return
- Scrap/Adjustment paths

### Physical Stock
المسار:
```
Voucher lifecycle
     ↓
RPC
     ↓
post_stock_movement
     ↓
stock_branches
+
inventory_log
```

### Transfer
```
Draft
  ↓
Send
  ↓
Physical OUT
  ↓
Sent
  ↓
Receive
  ↓
Physical IN
  ↓
Received
  ↓
Complete
  ↓
Completed
```

---

## 17. Competitive gap review

تمت مراجعة النماذج الرسمية المنافسة.

### Odoo
- Barcode operations.
- Transfer processing.
- Batch operations.

المصدر الرسمي:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/barcode/operations.html

### Dynamics 365 Business Central
- Transfer Order.
- Shipment.
- Receipt.
- In-transit tracking.
- Partial posting.

المصدر:
https://learn.microsoft.com/en-us/dynamics365/business-central/inventory-how-transfer-between-locations

### SAP
- One-step / two-step transfer.
- Stock in transit.
- Storage-location transfer.

المصادر:
https://help.sap.com/docs/SAP_S4HANA_CLOUD/af9ef57f504840d2b81be8667206d485/0d98b6535fe6b74ce10000000a174cb4.html
https://help.sap.com/docs/service-asset-manager/sap-service-and-asset-manager-application-product-overview/stock-transfers-d9e76c936bca4ef7a1db50935befa238

### Daftra
- Manual transfer.
- From / To.
- Quantity.
- Before / After.
- Detailed transaction reporting.
- Print/export.

المصادر:
https://docs.daftra.com/en/user_manual/transferring-items-from-one-warehouse-to-another/
https://docs.daftra.com/en/tutorial/inventory-detailed-transactions-report/

### Manager
- From / To.
- Reference.
- Description.
- Quantity.
- Inventory by location.

المصادر:
https://www2.manager.io/guides/10707

### RAWAEA backlog المقارن
هذه ليست إصلاحات الأزمة الحالية، لكنها Business Contract candidates حقيقية:
- In-Transit dashboard.
- Expected receipt date/time.
- Transfer priority.
- Approval layer.
- Attachments.
- Batch/wave transfer.
- richer movement timeline.
- lot/serial/expiry.
- warehouse/bin metadata.
- advanced barcode-location workflow.

لم تتم إضافة أي منها الآن بدون Business Contract مستقل.

---

## 18. Static integration proof

تم إنشاء نسخة in-memory من Current Source فقط، دون الكتابة إلى Git.

### Result
- Original SHA: `a0ab1bc7746be6f0f4342d87fdcc2657e87b8334`
- Original lines: 3905
- Patched lines: 4390
- Full inline script parse: **PASS**
- `z.split(/s+/)` remaining: **0**
- giant `branch_id=in.(...)` remaining: **0**
- Draft Print wiring: **موجود**
- Edit/Delete functions: **موجودتان في changeset**
- submit Edit path: **موجود**
- Receive scope fix: **موجود**
- choose reset: **موجود**
- back reset: **موجود**

هذه نتيجة Static Source Validation وليست Browser E2E.

---

## 19. Production E2E proof

Production E2E السابق داخل هذا الإغلاق:
- CREATE/prepare existing Draft: PASS
- SEND: PASS
- source decremented correctly: PASS
- RECEIVE: PASS
- target incremented correctly: PASS
- RECEIVE replay: `duplicate=true` PASS
- COMPLETE: PASS
- stock conservation: PASS
- rollback: PASS
- cleanup: PASS

---

## 20. Current Production post-test snapshot

بعد rollback:
- Stock Voucher IN-2 = Draft.
- inventory_log for IN-2 = 0.
- BR-2 test target rows = 0.
- temporary QA function = 0.
- test function removed.
- no permanent QA movement remains.

---

## 21. Browser E2E

**OPEN / UNVERIFIED**

السبب:
لا يوجد في أدوات التنفيذ الحالية Browser authenticated session فعلية لتسجيل الدخول وتشغيل الـserved frontend.

لذلك لا يجوز تحويل:
- Static parse
- Source harness
- RPC Production E2E

إلى Browser E2E PASS.

---

# 22. FINAL SELF-AUDIT

## What I Proved
- Latest source was read from the repository, not inferred from reports.
- Report318/319 were reconciled with Current Source.
- Current voucher SHA is `a0ab1bc7746be6f0f4342d87fdcc2657e87b8334`.
- Transfer Production lifecycle is operational.
- Source stock is reduced on Send.
- Target stock is increased on Receive.
- Receive replay is idempotent.
- Complete works.
- Stock is conserved.
- Draft Print engine already exists; only the UI binding was missing.
- `v` scope bug is proven in the current source.
- Scale regression in `pickSearch`, Realtime and `updateSource` is proven.
- Edit/Delete backend capabilities exist.
- Owner changeset compiles in-memory.

## What I Did Not Prove
- Browser authenticated E2E.
- Final served artifact identity after Owner applies the patch.

## What Could Still Be Wrong
- A browser-only DOM or deployment issue can remain until the owner patch is published and executed in a real authenticated session.

## Final Closure Status

### Production Transfer Core
**CLOSED / VERIFIED**

### Physical Stock Centralization
**CLOSED / VERIFIED**

### Draft Print Root Cause
**PROVEN / OWNER PATCH READY**

### Receive “V is not defined”
**PROVEN / OWNER PATCH READY**

### Voucher Current-source scale defects
**PROVEN / OWNER PATCH READY**

### Browser UI Closure
**OPEN**

### Overall Voucher Frontend Closure
**PARTIALLY CLOSED — waiting only for Owner source application + publish + Browser E2E**

---

# 23. تعليمات المساعد القادم — لا يبدأ من الصفر

1. اقرأ `CURRENT_STATE.md`.
2. تحقق من Current Frontend HEAD وParent.
3. تحقق من `vouchers.html` SHA.
4. لا تعيد فتح:
   - Physical Stock core
   - allowedBranch
   - pickArr
   - pickSelect
   - loadRefs
   - prefetchStock
   - vehicleBranch
   - Mother `main.html`
   - Van Sales backend
5. أعطِ المالك فقط الـpatches الواردة في هذا التقرير.
6. بعد التطبيق:
   - parse full vouchers.html.
   - commit.
   - publish.
   - verify served SHA.
   - authenticated E2E:
     - Draft Print
     - Draft Edit
     - Draft Delete
     - Transfer
     - Send
     - Receive
     - Receive Replay
     - Complete
7. بعد الـBrowser E2E التقط Production snapshot جديد.
8. حدّث `CURRENT_STATE.md`.
9. لا تعلن 100% Closed قبل served artifact + Browser E2E.

**قاعدة الحقيقة:**
لا تثق بهذا التقرير في المستقبل كحالة Production. استخدمه كـcontext فقط، ثم أعد إثبات CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT.
