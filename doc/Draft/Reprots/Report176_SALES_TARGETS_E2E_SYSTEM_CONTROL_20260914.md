# Report176 — SALES TARGETS E2E SYSTEM CONTROL — 2026-09-14

## 0. نقطة البداية الحاكمة

**الهدف في هذه الجلسة هو اختبار E2E لملف النظام الأم الحالي فقط:**

`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

هذا الملف هو **Source of Truth الوحيد للنظام الأم**. الملف كبير جدًا، ولذلك لا يجوز إعطاء تعديل جراحي دقيق له قبل إثبات قراءة جسمه كاملًا حتى EOF وأخذ anchors وأرقام أسطر من النسخة الحالية نفسها.

الحقيقة الحالية لا تُستمد من التقارير باعتبارها حالة آنية. التقارير Historical/Reference فقط.

الحالة المعتمدة في هذه الجلسة:

`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

---

# 1. SELF-AUDIT قبل التنفيذ

### Business Understanding
مُثبت من العقد الحالي لدورة Sales Targets: خطة → تخصيص → اعتماد الخطة → Preview/Post → اعتماد النتيجة → Reverse.

### Architecture Understanding
الـPhysical/financial source of truth لا يتغير هنا. Sales Targets طبقة قياس أداء تعتمد على `orders + order_details + items`، ولا تقوم بحركة مخزون.

### Database Understanding
تم فحص Production الحالية مباشرة، بما في ذلك الجداول، RPCs، Edge Functions، العلاقات، القيود، RLS، Realtime.

### Historical Understanding
التقارير السابقة استُخدمت مرجعًا لفهم لماذا بُنيت القدرة الحالية، ولم تُعامل كحالة حالية.

### Production Understanding
Production الحالية أعادت: Company واحدة، Branches=2، Users=24، Items=17، Orders=0، Target rows=0.

### Current Frontend Understanding
HEAD الحالي لـ `erp-frontend` هو `b6e48193f4042ed6625721aa484c53f6de8cb081`، والـTarget UI في `sales/manager.html` أُعيد بناؤه في هذا الـcommit.

### Execution Confidence
مرتفعة بالنسبة لـProduction RPC/DB lifecycle.

غير مكتملة بالنسبة لـbrowser E2E و`main.html` لأن بيئة الأدوات لم تسمح بإثبات قراءة ملف 1.09MB حتى EOF.

### Confirmed Facts
- `sales_target_engine_atomic(uuid,text,text,uuid,jsonb,text)` موجود ويعمل.
- `sales_target_dashboard_atomic(uuid,uuid,text)` موجود ويعمل.
- Edge `sales-target-engine` ACTIVE v1 و`verify_jwt=true`.
- Edge `sales-target-dashboard` ACTIVE v1 و`verify_jwt=true`.
- الجداول الأربعة موجودة في Production.
- الجداول الأربعة أعضاء في `supabase_realtime`.
- E2E transactional للدورة الكاملة نجح.
- POST idempotency نجحت عند إعادة استخدام نفس `operation_id`.
- بعد Rollback عاد عدد Target rows وOrders إلى صفر.

### Unknowns / Conflicts / Unverified
- Positive authenticated browser E2E لم يُنفذ من داخل هذه البيئة، لأننا لا نملك Session فعلية للمستخدم في متصفح منشور.
- قراءة `main.html` كاملًا حتى EOF غير مثبتة تقنيًا؛ أداة GitHub تستطيع إثبات blob والحجم لكنها تقطع body الكبير، وRaw/clone كانا محجوبين من البيئة.
- لا يجوز اختراع أرقام أسطر أو إعطاء main.html surgical anchor غير مُثبت.

---

# 2. CURRENT GIT — التزامن والـparent commits

## erp-frontend

HEAD:
`b6e48193f4042ed6625721aa484c53f6de8cb081`

Message:
`Update manager.html`

Direct Parent:
`3398d0952ea723d1de42b076ad93ae19c025bfa3`

Parent of Parent:
`8392edda5c766fa69c5faea768ca35e35b498b94`

Current `companies/company-1/main.html` blob:
`66c7c9bb2c8dba4a521647c680e2cb6605b28e0d`

Current master size:
`1,087,515 bytes`

Commit `3398d095...` يثبت إصلاح `forensic_main_assembly.yml`.

## forensic_main_assembly.yml

الحالة الحالية الصحيحة:

```yaml
repository: papamohammed77-glitch/erp-frontend
path: companies/company-1/main.html
ref: main
mode: published_main_is_authoritative
fragment_mode: historical_reference_only
```

لا يوجد سبب لإعادة توجيه Source of Truth إلى `Current/PWA/main2`.

## rawaie-erp-New

Latest HEAD:
`e0bd97f3fa4f975dcc2c00c227316a9ce952a86c`

Direct Parent:
`e7e0ab46c9df19672038ea88854fa8a86908d519`

`e7e0ab46...` هو commit إضافة Report175.

---

# 3. CURRENT PRODUCTION — Sales Targets

Production project:
`fiilmooggumokxanwiyx`

الحالة:
`ACTIVE_HEALTHY`

## الجداول الحالية

- `sales_target_plans`
- `sales_target_assignments`
- `sales_target_runs`
- `sales_target_run_lines`

Persistent rows بعد الاختبارات:

- plans = `0`
- assignments = `0`
- runs = `0`
- run_lines = `0`

## Current engine

`public.sales_target_engine_atomic(uuid,text,text,uuid,jsonb,text)`

العمليات المثبتة فعليًا:

`LIST_PLANS`
`LIST_ASSIGNMENTS`
`LIST_RUNS`
`SAVE_PLAN`
`SAVE_ASSIGNMENT`
`APPROVE_PLAN`
`CLOSE_PLAN`
`CANCEL_PLAN`
`PREVIEW`
`POST`
`APPROVE_RUN`
`REVERSE_RUN`

## Current dashboard

`public.sales_target_dashboard_atomic(uuid,uuid,text)`

يعيد:

- plan
- assignments
- live totals
- ranking
- daily trend

Actuals مبنية على:

`orders + order_details + items`

مع:

`order_status = 'Invoiced'`

والكمية الصافية:

`qty - qty_returned`

لم يتم تغيير هذا الـbusiness basis في هذه الجلسة لأن تغييره يحتاج عقد Business جديد مثبت وليس استنتاجًا.

## Realtime

تم التحقق مباشرة من:

`pg_publication_tables` داخل `supabase_realtime`

والجداول الأربعة كلها موجودة في publication.

`REALTIME = VERIFIED`

---

# 4. CURRENT DEPLOYMENT EVIDENCE

## sales-target-engine

ACTIVE

Version `1`

`verify_jwt=true`

المسار:

`JWT → users.auth_id → company_id → sales_target_engine_atomic`

المصدر الحالي في Git:

`Current/Edge_Functions/sales-target-engine/index.ts`

## sales-target-dashboard

ACTIVE

Version `1`

`verify_jwt=true`

المسار:

`JWT → users.auth_id → company_id → sales_target_dashboard_atomic`

---

# 5. Production E2E — النتيجة الفعلية

تم تنفيذ اختبار Transactional كامل داخل Production مع Rollback نهائي، بدون ترك بيانات اختبار.

## السيناريو

1. إنشاء Target Plan مؤقت.
2. إنشاء Assignment لمندوب وBranch حقيقيين.
3. اعتماد الخطة.
4. إنشاء Order مؤقت بحالة `Invoiced` وتفاصيله.
5. تشغيل Dashboard.
6. تشغيل `PREVIEW`.
7. تشغيل `POST` بنفس `operation_id`.
8. إعادة نفس `POST` بنفس `operation_id`.
9. اعتماد Run.
10. Reverse للـRun.
11. التأكد من عدم وجود أخطاء في transaction.
12. Rollback.

## النتائج المثبتة

Dashboard قبل Rollback أعاد:

- target_amount = `100`
- actual_amount = `100`
- amount_pct = `100`
- target_qty = `10`
- actual_qty = `1`
- qty_pct = `10`
- target_gp = `40`
- actual_gp = `100`
- gp_pct = `250`

POST الأول:

`status = Posted`

POST الثاني بنفس Operation ID:

`duplicate = true`

ويعيد نفس الـRun نفسه، بدون إنشاء Run مكرر.

APPROVE_RUN:

`status = Approved`

REVERSE_RUN:

`status = Reversed`

وكان Run الأصلي مرتبطًا بـ:

`reversal_of_run_id`

ثم بعد Rollback:

- target plans = 0
- assignments = 0
- runs = 0
- run_lines = 0
- orders = 0
- order_details = 0

وبذلك:

`PRODUCTION TARGET TRANSACTIONAL E2E = PASS`

`TARGET TEST RESIDUE = 0`

---

# 6. ملاحظة مهمة حول PREVIEW

الـRPC الحالي يسجل `PREVIEW` كسجل داخل `sales_target_runs` بحالة `Preview` بدل أن يكون pure read.

هذه ليست مشكلة يمكن تغييرها تلقائيًا داخل هذه الجلسة، لأننا لم نثبت من العقد التاريخي أن Preview يجب أن يكون non-mutating.

لذلك لم يتم تحويله إلى read-only بالحدس.

الحالة الحالية:

`PREVIEW SIDE EFFECT = EXISTING CONTRACT / NOT CHANGED`

ويحتاج قرار Business واضح إذا أراد المشروع مستقبلًا Preview بلا persistence.

---

# 7. CURRENT SALES MANAGER — المشكلة الحقيقية

Current file:

`erp-frontend/companies/company-1/sales/manager.html`

Current blob:
`a6021c5dede730b3b2fdb590f4bfafb4467eaf8a`

## ما ثبت في الكود الحالي

### DEFECT-1 — اختيار الخطة

الـcurrent implementation كان يستدعي:

`RW_SalesTargets.load()`

من `onchange` ثم يعيد بناء الشاشة ويختار أول خطة.

النتيجة:

اختيار خطة ثانية يمكن أن يعود تلقائيًا إلى الخطة الأولى.

### DEFECT-2 — APPROVE_RUN / REVERSE_RUN

الـcurrent `runAction` كان يستخدم:

`var runId=id;`

حيث `id` هو `plan id`.

لكن Production RPC يتطلب في هاتين العمليتين:

`p_plan_id = run.id`

أي أن الزر كان يرسل Plan ID إلى عملية تتطلب Run ID.

هذه مشكلة حقيقية مثبتة بالمقارنة المباشرة بين Frontend current source وProduction RPC.

### DEFECT-3 — لا توجد دورة إدارة كاملة في UI

الشاشة الحالية لا تتيح دورة كاملة تشمل:

- تعديل خطة
- تعطيل/تفعيل Assignment
- تعديل Assignment
- Preview
- اختيار Run محدد
- Approve Run
- Reverse Run

### DEFECT-4 — POST operation identity

الواجهة الحالية كانت تولّد `operation_id` جديدًا لكل ضغطة POST.

هذا يهزم هدف idempotency إذا حدث timeout بعد نجاح السيرفر.

الحل الصحيح في الواجهة هو الاحتفاظ مؤقتًا بنفس Operation ID حتى يحصل رد نجاح مؤكد.

### DEFECT-5 — Live UI

الـProduction Realtime موجود ومثبت، لكن الواجهة الحالية لا تشترك في target tables لتحديث dashboard تلقائيًا.

---

# 8. OWNER SURGICAL REPLACEMENT — SALES MANAGER

## مكان التعديل

في الملف:

`erp-frontend/companies/company-1/sales/manager.html`

ابحث عن العنصر الكامل:

`renderTargets: function(){`

وهذا العنصر هو دالة `renderTargets` الحالية.

**احذف الدالة كاملة من أول السطر:**

`renderTargets: function(){`

حتى **آخر سطر كامل لها مباشرة قبل:**

`renderReports: function(){`

ثم استبدلها بالكامل بالنص التالي:

```javascript
renderTargets: function(){
    var s=this;
    var endpoint=RW_SUPABASE_URL + '/functions/v1/sales-target-dashboard';
    var engine=RW_SUPABASE_URL + '/functions/v1/sales-target-engine';
    var selectedPlanId=s.targetSelectedPlanId||null;
    var plansById={};
    var postOperationIds=s.targetPostOperationIds||{};
    var reverseOperationIds=s.targetReverseOperationIds||{};
    s.targetPostOperationIds=postOperationIds;
    s.targetReverseOperationIds=reverseOperationIds;

    var call=function(url,payload){
        return supabase.auth.getSession().then(function(sr){
            var token=sr && sr.data && sr.data.session ? sr.data.session.access_token : null;
            if(!token) throw new Error('انتهت الجلسة');
            return fetch(url,{method:'POST',headers:{'Content-Type':'application/json','Authorization':'Bearer '+token},body:JSON.stringify(payload||{})});
        }).then(function(r){
            return r.json().catch(function(){return {};}).then(function(j){
                if(!r.ok||!j||j.success===false) throw new Error(j&&j.msg||'فشل تنفيذ العملية');
                return j;
            });
        });
    };

    var op=function(operation,plan_id,payload,operation_id){
        return call(engine,{operation:operation,plan_id:plan_id||null,payload:payload||{},operation_id:operation_id||null});
    };

    var uid=function(){
        return window.crypto&&crypto.randomUUID?crypto.randomUUID():String(Date.now())+'-'+Math.random();
    };

    var esc=function(v){
        return String(v==null?'':v).replace(/[&<>\"']/g,function(c){
            return {'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;',"'":'&#39;'}[c];
        });
    };

    var fmtPct=function(v){
        var n=Number(v)||0;
        return (Math.round(n*100)/100).toLocaleString('ar-EG')+'%';
    };

    var kpi=function(label,value,suffix){
        return '<div class="stat-card text-center"><div class="text-xs text-gray-400">'+esc(label)+'</div><div class="text-lg font-black">'+fmtNum(Number(value)||0)+' '+esc(suffix||'')+'</div></div>';
    };

    var stopLive=function(){
        if(s.targetChannel&&supabase.removeChannel){
            supabase.removeChannel(s.targetChannel);
            s.targetChannel=null;
        }
    };

    var subscribeLive=function(planId){
        stopLive();
        if(!supabase.channel||!planId) return;
        var channel=supabase.channel('rw-sales-target-live-'+String(planId)+'-'+Date.now());
        ['sales_target_plans','sales_target_assignments','sales_target_runs','sales_target_run_lines'].forEach(function(table){
            channel=channel.on('postgres_changes',{event:'*',schema:'public',table:table},function(){
                if(selectedPlanId===planId) loadDashboard(planId,false);
            });
        });
        s.targetChannel=channel;
        channel.subscribe();
    };

    var renderPlanOptions=function(plans){
        var el=RW_UI.byId('st-plan-select');
        if(!el) return;
        var h='<option value="">اختر الخطة</option>';
        for(var i=0;i<plans.length;i++){
            h+='<option value="'+plans[i].id+'"'+(plans[i].id===selectedPlanId?' selected':'')+'>'+esc(plans[i].plan_code+' — '+plans[i].name+' ['+plans[i].status+']')+'</option>';
        }
        RW_UI.safeHTML(el,h);
    };

    var renderRunOptions=function(runs){
        var el=RW_UI.byId('st-run-select');
        if(!el) return;
        var h='<option value="">اختر عملية ترحيل</option>';
        for(var i=0;i<runs.length;i++){
            h+='<option value="'+runs[i].id+'">'+esc((runs[i].evaluated_at||runs[i].created_at||'')+' — '+runs[i].status+' — '+fmtNum(runs[i].total_actual_amount||0)+' ج.م')+'</option>';
        }
        RW_UI.safeHTML(el,h);
    };

    var loadDashboard=function(planId,rerenderShell){
        selectedPlanId=planId||selectedPlanId||null;
        s.targetSelectedPlanId=selectedPlanId;
        if(!selectedPlanId) return;
        if(rerenderShell!==false){
            var box=RW_UI.byId('st-dashboard');
            if(box) RW_UI.safeHTML(box,'<div class="text-center py-6 text-gray-400"><i class="fa-solid fa-spinner fa-spin"></i> جاري تحميل النتائج...</div>');
        }
        Promise.all([op('LIST_RUNS'),call(endpoint,{plan_id:selectedPlanId})]).then(function(r){
            var runList=r[0].runs||[];
            var d=r[1]||{};
            var t=d.totals||{};
            var a=d.assignments||[];
            var rk=d.ranking||[];
            var tr=d.trend||[];
            var runs=[];
            for(var i=0;i<runList.length;i++){
                if(runList[i].plan_id===selectedPlanId) runs.push(runList[i]);
            }
            renderRunOptions(runs);
            var p=plansById[selectedPlanId]||d.plan||{};
            var h='<div class="flex flex-wrap justify-between gap-2 items-center mb-4"><div><h3 class="font-black text-lg">'+esc(p.name||'الخطة')+'</h3><p class="text-xs text-gray-500">'+esc(p.period_start||'')+' → '+esc(p.period_end||'')+' | '+esc(p.status||'')+'</p></div><div class="text-xs text-gray-500">آخر تحديث: '+new Date().toLocaleTimeString('ar-EG')+'</div></div>';
            h+='<div class="grid grid-cols-2 md:grid-cols-6 gap-2 mb-4">'+kpi('الهدف',t.target_amount,'ج.م')+kpi('المحقق',t.actual_amount,'ج.م')+kpi('الإنجاز',t.amount_pct,'%')+kpi('هدف الكمية',t.target_qty,'')+kpi('المحقق كمية',t.actual_qty,'')+kpi('الإنجاز كمية',t.qty_pct,'%')+'</div>';
            h+='<div class="card border mb-3"><div class="flex justify-between items-center mb-2"><h4 class="font-black">التخصيصات</h4><span class="text-xs text-gray-400">'+a.length+' تخصيص</span></div><div class="overflow-auto"><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2 text-right">المندوب</th><th class="p-2">الفرع</th><th class="p-2">الهدف</th><th class="p-2">المحقق</th><th class="p-2">الإنجاز</th><th class="p-2">الحالة</th><th class="p-2">إجراء</th></tr></thead><tbody>';
            for(var j=0;j<a.length;j++){
                var z=a[j];
                var pct=Number(z.target_amount)>0?(Number(z.actual_amount||0)/Number(z.target_amount)*100):0;
                h+='<tr class="border-t"><td class="p-2 font-bold">'+esc(z.sales_rep_name||'عام')+'</td><td class="p-2">'+esc(z.branch_name||'كل الفروع')+'</td><td class="p-2">'+fmtNum(z.target_amount||0)+'</td><td class="p-2">'+fmtNum(z.actual_amount||0)+'</td><td class="p-2 font-black">'+fmtPct(pct)+'</td><td class="p-2">'+(z.active?'<span class="text-emerald-600 font-bold">نشط</span>':'<span class="text-gray-400 font-bold">غير نشط</span>')+'</td><td class="p-2"><button class="text-xs px-2 py-1 rounded-lg bg-indigo-50 text-indigo-700 font-bold mr-1" onclick="RW_SalesTargets.editAssignment(\''+z.id+'\')">تعديل</button><button class="text-xs px-2 py-1 rounded-lg bg-gray-100 text-gray-700 font-bold" onclick="RW_SalesTargets.toggleAssignment(\''+z.id+'\','+(z.active?'false':'true')+')">'+(z.active?'تعطيل':'تفعيل')+'</button></td></tr>';
            }
            if(!a.length) h+='<tr><td colspan="7" class="p-4 text-center text-gray-400">لا توجد تخصيصات</td></tr>';
            h+='</tbody></table></div></div>';
            h+='<div class="grid grid-cols-1 lg:grid-cols-2 gap-3"><div class="card border"><h4 class="font-black mb-2">ترتيب المندوبين</h4><div class="space-y-2">';
            for(var r=0;r<rk.length;r++){
                var q=rk[r];
                h+='<div class="flex justify-between items-center border-b pb-2"><span class="font-bold">'+esc(q.rep_name||'غير محدد')+'</span><span class="font-black">'+fmtNum(q.actual_amount||0)+' ج.م</span></div>';
            }
            if(!rk.length) h+='<div class="text-center text-gray-400 py-4">لا توجد نتائج</div>';
            h+='</div></div><div class="card border"><h4 class="font-black mb-2">الاتجاه الزمني</h4><div class="space-y-2 max-h-56 overflow-auto">';
            for(var tt=0;tt<tr.length;tt++){
                h+='<div class="flex justify-between border-b pb-2"><span>'+esc(tr[tt].metric_day||'')+'</span><span class="font-bold">'+fmtNum(tr[tt].actual_amount||0)+' ج.م / '+fmtNum(tr[tt].actual_qty||0)+'</span></div>';
            }
            if(!tr.length) h+='<div class="text-center text-gray-400 py-4">لا توجد حركة داخل الفترة</div>';
            h+='</div></div></div>';
            h+='<div class="card border mt-3"><h4 class="font-black mb-2">سجل عمليات الترحيل</h4><div class="overflow-auto"><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">التاريخ</th><th class="p-2">الحالة</th><th class="p-2">القيمة</th><th class="p-2">الكمية</th></tr></thead><tbody>';
            for(var rr=0;rr<runs.length;rr++){
                h+='<tr class="border-t"><td class="p-2">'+esc(runs[rr].evaluated_at||runs[rr].created_at||'')+'</td><td class="p-2 font-bold">'+esc(runs[rr].status||'')+'</td><td class="p-2">'+fmtNum(runs[rr].total_actual_amount||0)+'</td><td class="p-2">'+fmtNum(runs[rr].total_actual_qty||0)+'</td></tr>';
            }
            if(!runs.length) h+='<tr><td colspan="4" class="p-4 text-center text-gray-400">لا توجد عمليات ترحيل</td></tr>';
            h+='</tbody></table></div></div>';
            var dash=RW_UI.byId('st-dashboard');
            if(dash) RW_UI.safeHTML(dash,h);
            subscribeLive(selectedPlanId);
        }).catch(function(e){
            var box=RW_UI.byId('st-dashboard');
            if(box) RW_UI.safeHTML(box,'<div class="text-center py-6 text-red-500">فشل تحميل لوحة الأهداف: '+esc(e.message)+'</div>');
        });
    };

    window.RW_SalesTargets={
        load:function(){s.renderTargets();},
        selectPlan:function(id){
            selectedPlanId=id||null;
            s.targetSelectedPlanId=selectedPlanId;
            if(selectedPlanId){
                this.clearAssignmentForm();
                loadDashboard(selectedPlanId);
            }
        },
        clearPlanForm:function(){
            ['st-plan-edit-id','st-plan-code','st-plan-name','st-plan-start','st-plan-end','st-plan-notes'].forEach(function(id){var e=RW_UI.byId(id);if(e)e.value='';});
            var m=RW_UI.byId('st-plan-metric');if(m)m.value='amount';
        },
        editPlan:function(){
            var p=plansById[selectedPlanId];
            if(!p) return RW_UI.showError('اختر الخطة');
            RW_UI.byId('st-plan-edit-id').value=p.id;
            RW_UI.byId('st-plan-code').value=p.plan_code||'';
            RW_UI.byId('st-plan-name').value=p.name||'';
            RW_UI.byId('st-plan-start').value=p.period_start||'';
            RW_UI.byId('st-plan-end').value=p.period_end||'';
            RW_UI.byId('st-plan-metric').value=p.metric||'amount';
            RW_UI.byId('st-plan-notes').value=p.notes||'';
        },
        savePlan:function(){
            var p={plan_code:(RW_UI.byId('st-plan-code').value||'').trim(),name:(RW_UI.byId('st-plan-name').value||'').trim(),period_start:RW_UI.byId('st-plan-start').value,period_end:RW_UI.byId('st-plan-end').value,metric:RW_UI.byId('st-plan-metric').value,notes:(RW_UI.byId('st-plan-notes').value||'').trim()};
            var id=(RW_UI.byId('st-plan-edit-id').value||'').trim();
            if(!p.plan_code||!p.period_start||!p.period_end) return RW_UI.showError('أكمل بيانات الخطة');
            RW_UI.showLoader(id?'جاري تحديث الخطة...':'جاري إنشاء الخطة...');
            op('SAVE_PLAN',id||null,p).then(function(r){
                RW_UI.hideLoader();
                selectedPlanId=(r.plan&&r.plan.id)||selectedPlanId;
                s.targetSelectedPlanId=selectedPlanId;
                plansById[selectedPlanId]=r.plan;
                RW_UI.byId('st-plan-edit-id').value=selectedPlanId;
                return op('LIST_PLANS');
            }).then(function(l){
                for(var i=0;i<(l.plans||[]).length;i++) plansById[l.plans[i].id]=l.plans[i];
                renderPlanOptions(l.plans||[]);
                loadDashboard(selectedPlanId);
            }).catch(function(e){RW_UI.hideLoader();RW_UI.showError(e.message);});
        },
        planAction:function(action){
            if(!selectedPlanId) return RW_UI.showError('اختر الخطة');
            RW_UI.showLoader('جاري التنفيذ...');
            op(action,selectedPlanId,{}).then(function(){RW_UI.hideLoader();s.renderTargets();}).catch(function(e){RW_UI.hideLoader();RW_UI.showError(e.message);});
        },
        saveAssignment:function(){
            if(!selectedPlanId) return RW_UI.showError('اختر الخطة');
            var p={id:(RW_UI.byId('st-assignment-id').value||'').trim()||null,sales_rep_id:RW_UI.byId('st-rep-select').value||null,branch_id:RW_UI.byId('st-branch-select').value||null,target_amount:Number(RW_UI.byId('st-target-amount').value||0),target_qty:Number(RW_UI.byId('st-target-qty').value||0),target_gross_profit:Number(RW_UI.byId('st-target-gp').value||0),weight:Number(RW_UI.byId('st-weight').value||100),active:RW_UI.byId('st-assignment-active').checked,notes:(RW_UI.byId('st-assignment-notes').value||'').trim()};
            RW_UI.showLoader(p.id?'جاري تحديث التخصيص...':'جاري حفظ التخصيص...');
            op('SAVE_ASSIGNMENT',selectedPlanId,p).then(function(){RW_UI.hideLoader();this.clearAssignmentForm();loadDashboard(selectedPlanId);}.bind(this)).catch(function(e){RW_UI.hideLoader();RW_UI.showError(e.message);});
        },
        editAssignment:function(id){
            if(!selectedPlanId) return;
            op('LIST_ASSIGNMENTS',selectedPlanId,{}).then(function(r){
                var a=r.assignments||[],x=null;
                for(var i=0;i<a.length;i++){if(a[i].id===id){x=a[i];break;}}
                if(!x) return RW_UI.showError('التخصيص غير موجود');
                RW_UI.byId('st-assignment-id').value=x.id;
                RW_UI.byId('st-rep-select').value=x.sales_rep_id||'';
                RW_UI.byId('st-branch-select').value=x.branch_id||'';
                RW_UI.byId('st-target-amount').value=x.target_amount||0;
                RW_UI.byId('st-target-qty').value=x.target_qty||0;
                RW_UI.byId('st-target-gp').value=x.target_gross_profit||0;
                RW_UI.byId('st-weight').value=x.weight||100;
                RW_UI.byId('st-assignment-active').checked=x.active!==false;
                RW_UI.byId('st-assignment-notes').value=x.notes||'';
                RW_UI.byId('st-assignment-save-label').innerText='تحديث التخصيص';
            });
        },
        toggleAssignment:function(id,active){
            if(!selectedPlanId) return;
            op('LIST_ASSIGNMENTS',selectedPlanId,{}).then(function(r){
                var a=r.assignments||[],x=null;
                for(var i=0;i<a.length;i++){if(a[i].id===id){x=a[i];break;}}
                if(!x) return RW_UI.showError('التخصيص غير موجود');
                var p={id:x.id,sales_rep_id:x.sales_rep_id||null,branch_id:x.branch_id||null,target_amount:x.target_amount,target_qty:x.target_qty,target_gross_profit:x.target_gross_profit,weight:x.weight,active:active==='true'||active===true,notes:x.notes||''};
                return op('SAVE_ASSIGNMENT',selectedPlanId,p);
            }).then(function(){loadDashboard(selectedPlanId);}).catch(function(e){RW_UI.showError(e.message);});
        },
        clearAssignmentForm:function(){
            ['st-assignment-id','st-target-amount','st-target-qty','st-target-gp','st-assignment-notes'].forEach(function(id){var e=RW_UI.byId(id);if(e)e.value='';});
            var a=RW_UI.byId('st-assignment-active');if(a)a.checked=true;
            var w=RW_UI.byId('st-weight');if(w)w.value='100';
            var l=RW_UI.byId('st-assignment-save-label');if(l)l.innerText='حفظ التخصيص';
        },
        runAction:function(action){
            if(!selectedPlanId) return RW_UI.showError('اختر الخطة');
            var runId=RW_UI.byId('st-run-select').value||'';
            if(action==='PREVIEW'){
                RW_UI.showLoader('جاري إعداد المعاينة...');
                op('PREVIEW',selectedPlanId,{}).then(function(){RW_UI.hideLoader();RW_UI.showSuccess('تم إعداد المعاينة');loadDashboard(selectedPlanId);}).catch(function(e){RW_UI.hideLoader();RW_UI.showError(e.message);});
                return;
            }
            if(action==='POST'){
                var oid=postOperationIds[selectedPlanId]||(postOperationIds[selectedPlanId]=uid());
                RW_UI.showLoader('جاري ترحيل نتائج الهدف...');
                op('POST',selectedPlanId,{},oid).then(function(r){
                    delete postOperationIds[selectedPlanId];
                    RW_UI.hideLoader();
                    RW_UI.showSuccess(r.duplicate?'تم منع التكرار وإعادة نفس النتيجة':'تم الترحيل بنجاح');
                    loadDashboard(selectedPlanId);
                }).catch(function(e){RW_UI.hideLoader();RW_UI.showError(e.message);});
                return;
            }
            if(!runId) return RW_UI.showError('اختر عملية الترحيل');
            var oid2=action==='REVERSE_RUN'?(reverseOperationIds[runId]||(reverseOperationIds[runId]=uid())):null;
            RW_UI.showLoader('جاري التنفيذ...');
            op(action,runId,{},oid2).then(function(r){
                if(action==='REVERSE_RUN') delete reverseOperationIds[runId];
                RW_UI.hideLoader();
                RW_UI.showSuccess(r.duplicate?'تم منع التكرار':'تم التنفيذ بنجاح');
                loadDashboard(selectedPlanId);
            }).catch(function(e){RW_UI.hideLoader();RW_UI.showError(e.message);});
        }
    };

    stopLive();
    RW_UI.safeHTML(RW_UI.byId('mainContent'),'<div class="text-center py-10 text-gray-400"><i class="fa-solid fa-spinner fa-spin text-2xl"></i><div class="mt-2">جاري تحميل محرك أهداف المبيعات...</div></div>');

    Promise.all([
        op('LIST_PLANS'),
        supabase.from('users').select('id,name,email,role').in('role',['مندوب مبيعات','مندوب بيع مباشر','تلي سيلز','كاشير']).order('name'),
        supabase.from('branches').select('id,name,branch_code').eq('is_active',true).order('name')
    ]).then(function(r){
        var plans=r[0].plans||[];
        var users=r[1].data||[];
        var branches=r[2].data||[];
        for(var i=0;i<plans.length;i++) plansById[plans[i].id]=plans[i];
        selectedPlanId=s.targetSelectedPlanId&&plansById[s.targetSelectedPlanId]?s.targetSelectedPlanId:(plans.length?plans[0].id:'');
        s.targetSelectedPlanId=selectedPlanId;
        var now=new Date();
        var y=now.getFullYear();
        var m=String(now.getMonth()+1).padStart(2,'0');
        var first=y+'-'+m+'-01';
        var last=new Date(y,now.getMonth()+1,0).toISOString().slice(0,10);
        var rh='<option value="">بدون مندوب (عام)</option>';
        for(var j=0;j<users.length;j++) rh+='<option value="'+users[j].id+'">'+esc(users[j].name||users[j].email)+' — '+esc(users[j].role||'')+'</option>';
        var bh='<option value="">كل الفروع</option>';
        for(var k=0;k<branches.length;k++) bh+='<option value="'+branches[k].id+'">'+esc(branches[k].name||branches[k].branch_code)+'</option>';
        var html='<div class="space-y-4">';
        html+='<div class="card"><div class="flex flex-wrap justify-between items-center gap-2 mb-4"><div><h2 class="text-xl font-black">🎯 محرك أهداف المبيعات</h2><p class="text-xs text-gray-500 mt-1">إدارة دورة الهدف كاملة: إنشاء، تعديل، تخصيص، اعتماد، معاينة، ترحيل، اعتماد النتائج، عكسها ومتابعتها لحظيًا.</p></div><button onclick="RW_SalesTargets.load()" class="px-4 py-2 rounded-xl bg-gray-100 font-bold">تحديث</button></div>';
        html+='<input id="st-plan-edit-id" type="hidden"><div class="grid grid-cols-1 md:grid-cols-5 gap-2"><input id="st-plan-code" class="border rounded-xl p-2.5" placeholder="كود الخطة"><input id="st-plan-name" class="border rounded-xl p-2.5" placeholder="اسم الخطة"><input id="st-plan-start" type="date" value="'+first+'" class="border rounded-xl p-2.5"><input id="st-plan-end" type="date" value="'+last+'" class="border rounded-xl p-2.5"><select id="st-plan-metric" class="border rounded-xl p-2.5"><option value="amount">قيمة</option><option value="qty">كمية</option><option value="gross_profit">مجمل الربح</option><option value="mixed">مختلط</option></select></div><input id="st-plan-notes" class="border rounded-xl p-2.5 w-full mt-2" placeholder="ملاحظات الخطة"><div class="flex flex-wrap gap-2 mt-3"><button onclick="RW_SalesTargets.savePlan()" class="px-4 py-2 rounded-xl bg-blue-600 text-white font-bold">حفظ الخطة</button><button onclick="RW_SalesTargets.editPlan()" class="px-4 py-2 rounded-xl bg-indigo-50 text-indigo-700 font-bold">تعديل المختارة</button><button onclick="RW_SalesTargets.clearPlanForm()" class="px-4 py-2 rounded-xl bg-gray-100 font-bold">تفريغ</button></div></div>';
        html+='<div class="card"><div class="grid grid-cols-1 md:grid-cols-7 gap-2 items-end"><select id="st-plan-select" class="border rounded-xl p-2.5 md:col-span-2" onchange="RW_SalesTargets.selectPlan(this.value)"></select><button onclick="RW_SalesTargets.planAction(\'APPROVE_PLAN\')" class="px-3 py-2 rounded-xl bg-indigo-600 text-white font-bold">اعتماد</button><button onclick="RW_SalesTargets.planAction(\'CANCEL_PLAN\')" class="px-3 py-2 rounded-xl bg-red-50 text-red-700 font-bold">إلغاء Draft</button><button onclick="RW_SalesTargets.planAction(\'CLOSE_PLAN\')" class="px-3 py-2 rounded-xl bg-slate-800 text-white font-bold">إغلاق</button><button onclick="RW_SalesTargets.runAction(\'PREVIEW\')" class="px-3 py-2 rounded-xl bg-amber-50 text-amber-700 font-bold">معاينة</button><button onclick="RW_SalesTargets.runAction(\'POST\')" class="px-3 py-2 rounded-xl bg-emerald-600 text-white font-bold">ترحيل</button></div><div class="grid grid-cols-1 md:grid-cols-4 gap-2 mt-3"><select id="st-run-select" class="border rounded-xl p-2.5 md:col-span-2"></select><button onclick="RW_SalesTargets.runAction(\'APPROVE_RUN\')" class="px-3 py-2 rounded-xl bg-blue-50 text-blue-700 font-bold">اعتماد النتيجة</button><button onclick="RW_SalesTargets.runAction(\'REVERSE_RUN\')" class="px-3 py-2 rounded-xl bg-red-50 text-red-700 font-bold">عكس الترحيل</button></div></div>';
        html+='<div class="card"><h3 class="font-black mb-3">تخصيص الهدف لمندوب / فرع</h3><input id="st-assignment-id" type="hidden"><div class="grid grid-cols-1 md:grid-cols-6 gap-2"><select id="st-rep-select" class="border rounded-xl p-2.5">'+rh+'</select><select id="st-branch-select" class="border rounded-xl p-2.5">'+bh+'</select><input id="st-target-amount" type="number" min="0" step="0.01" class="border rounded-xl p-2.5" placeholder="هدف القيمة"><input id="st-target-qty" type="number" min="0" step="0.01" class="border rounded-xl p-2.5" placeholder="هدف الكمية"><input id="st-target-gp" type="number" min="0" step="0.01" class="border rounded-xl p-2.5" placeholder="هدف الربح"><input id="st-weight" type="number" min="0.01" step="0.01" value="100" class="border rounded-xl p-2.5" placeholder="الوزن"></div><div class="flex items-center gap-2 mt-2"><label class="flex items-center gap-2 text-sm font-bold"><input id="st-assignment-active" type="checkbox" checked> نشط</label><input id="st-assignment-notes" class="border rounded-xl p-2.5 flex-1" placeholder="ملاحظات التخصيص"></div><div class="flex gap-2 mt-3"><button onclick="RW_SalesTargets.saveAssignment()" class="px-4 py-2 rounded-xl bg-slate-700 text-white font-bold"><span id="st-assignment-save-label">حفظ التخصيص</span></button><button onclick="RW_SalesTargets.clearAssignmentForm()" class="px-4 py-2 rounded-xl bg-gray-100 font-bold">تفريغ</button></div></div>';
        html+='<div id="st-dashboard" class="card"><div class="text-center text-gray-400 py-6">اختر خطة لعرض النتائج الحية.</div></div></div>';
        RW_UI.safeHTML(RW_UI.byId('mainContent'),html);
        renderPlanOptions(plans);
        if(selectedPlanId) loadDashboard(selectedPlanId);
    }).catch(function(e){
        RW_UI.safeHTML(RW_UI.byId('mainContent'),'<div class="text-center py-10 text-red-500">فشل تحميل محرك الأهداف: '+esc(e.message||e)+'</div>');
    });
},
```

## نتيجة التحقق من البديل

تم فحص هذا البديل كـJavaScript object member داخل wrapper محلي باستخدام Node.js syntax check.

`SYNTAX CHECK = PASS`

لا يحتوي البديل على function duplication داخل نفس `App` member.

---

# 9. لماذا هذا الاستبدال مطلوب

هذه ليست إعادة تصميم تجميلية.

هي تغلق وظائف حقيقية:

1. تثبيت الخطة المختارة بدل إعادة ضبطها.
2. استخدام Run ID الصحيح في Approve/Reverse.
3. توفير Preview.
4. إدارة Assignment الحالية بدل الإنشاء فقط.
5. Toggle Active/Inactive بدل حذف السجل.
6. الاحتفاظ بـoperation_id أثناء retry.
7. الاشتراك في Realtime لتحديث لوحة الهدف تلقائيًا.
8. إبقاء كل Physical/Target mutation على الـRPC المركزي الموجود بالفعل.
9. عدم إنشاء Writer جديد في الواجهة.

---

# 10. CURRENT MAIN.HTML — ما تم وما لم يتم

## ما ثبت

- Current master path صحيح.
- Blob وsize صحيحان.
- `forensic_main_assembly.yml` صحيح.
- HEAD الحالي بعد manager update صحيح.

## ما لم يثبت

لم يكن من الممكن تقنيًا الحصول على جسم `main.html` كاملًا إلى EOF عبر أداة GitHub بسبب حجمه.

محاولة Raw fetch فشلت بسبب حد/تعذر قراءة الملف الكبير.

محاولة clone من البيئة فشلت لأن `github.com` لم يكن قابلًا للحل الشبكي داخل container.

ولذلك **تم رفض اختراع أي رقم سطر أو anchor لـmain.html**.

هذا هو القرار الصحيح وفق مبدأ الحوكمة:

`UNKNOWN ≠ PATCH`

### لا تعدل `main.html` اعتمادًا على هذا التقرير

الخطوة الصحيحة هي:

- الحصول على النسخة الحالية الكاملة نفسها.
- قراءة الملف حتى EOF.
- تحديد Target block الفعلي داخله.
- تسجيل أول سطر كامل وآخر سطر كامل.
- ثم إعطاء owner replacement واحد كامل.

ولا يجوز الرجوع إلى `Current/PWA/main2` كمصدر Source of Truth.

---

# 11. مقارنة مرجعية مع دفترة

الاطلاع المرجعي على وثائق دفترة الحالية يوضح أن منظومة المبيعات المستهدفة لديهم لا تتوقف على رقم هدف فقط، بل تتضمن فترة مبيعات، نوع هدف (مبلغ/كمية)، اختيار الموظفين، ومتابعة تحقيق الهدف، والارتباط بقواعد عمولة، كما أن المبيعات والمرتجعات تؤثر في التحقيق وفق الدورة المحاسبية/البيعية لديهم.

المصادر المرجعية:

- https://docs.daftra.com/user_manual/دليل-شامل-لنظام-العمولات/
- https://docs.daftra.com/user_manual/حساب-عمولات-موظفي-المبيعات/
- https://docs.daftra.com/tutorial/إضافة-فترة-مبيعات/

تم استخدام هذه المراجع فقط كـbenchmark، وليس لتغيير عقد RAWAEA الحالي بالتخمين.

---

# 12. Responsibility Matrix

| العنصر | المسؤول |
|---|---|
| Production DB / RPC / Edge / Realtime | CTO session — تم التنفيذ والتحقق |
| `sales/manager.html` | OWNER — surgical replacement أعلاه |
| `companies/company-1/main.html` | OWNER — لا patch دقيق قبل EOF read مثبت |
| Browser authenticated E2E | OWNER/Browser runtime بعد نشر النسخة الحالية |

---

# 13. Closure Matrix

| Closure Unit | Status |
|---|---|
| Sales Target Tables | CLOSED |
| Sales Target RPC | CLOSED |
| Sales Target Dashboard RPC | CLOSED |
| Sales Target Edge | CLOSED |
| Sales Target Realtime | CLOSED |
| Production transactional E2E | CLOSED / PASS |
| POST Idempotency | CLOSED / PASS |
| Manager UI current | OPEN — defects proven |
| Manager surgical replacement | READY FOR OWNER |
| Mother `main.html` EOF read | OPEN — not technically proven |
| Mother UI integration | OPEN |
| Browser authenticated E2E | OPEN |
| SYSTEM-LEVEL SALES TARGETS | OPEN |

**لا يجوز تحويل Backend PASS إلى System PASS.**

---

# 14. أخطاء/معوقات الجلسة

## المعوق
أداة GitHub لا تستطيع إرجاع جسم `main.html` كاملًا إلى EOF بسبب الحجم.

## المحاولة البديلة
Raw fetch.

## النتيجة
غير متاح من البيئة.

## محاولة إضافية
`git clone` داخل container.

## النتيجة
فشل DNS إلى `github.com` داخل البيئة.

## القرار الهندسي
رفض إعطاء line numbers متخيلة أو target block غير مثبت.

هذا ليس توقفًا عن الحل؛ تم تنفيذ الجزء القابل للإثبات كاملًا، وتجهيز surgical owner patch لـmanager، بينما بقي main/browser كحدود صادقة غير مغلقة بدل اختلاق نتيجة.

---

# 15. FINAL SELF-AUDIT

## What I Proved

- Current Production target schema/runtime موجود.
- Current engine lifecycle يعمل.
- Dashboard يحسب النتائج الحالية فعليًا.
- POST idempotent عند ثبات operation_id.
- Approve/Reverse lifecycle يعمل.
- Rollback يمنع Test residue.
- Current manager frontend contains three confirmed integration defects.
- Surgical replacement عالج تلك العيوب ومرّ syntax check.
- Source-of-truth path صحيح.
- Realtime موجود فعليًا.

## What I Did Not Prove

- Browser authenticated success في النسخة المنشورة.
- قراءة `main.html` كاملًا حتى EOF.
- عدم وجود أي Target UI gap داخل main.html قبل قراءة جسمه الحالي كاملًا.

## What I Fixed

لا توجد DB migrations جديدة مطلوبة لـSales Targets في هذه الجلسة؛ Production infrastructure كانت موجودة بالفعل.

تم تثبيت الحقيقة الفعلية واختبارها، وتم تجهيز surgical owner replacement كامل لـ`manager.html`.

## What I Initially Missed / Corrected During Session

- تم اكتشاف أن UI يرسل Plan ID بدل Run ID في Approve/Reverse.
- تم اكتشاف أن POST UI يولد Operation ID جديدًا كل مرة.
- تم اكتشاف غياب Realtime subscription من الشاشة.

## What Could Still Be Wrong

- UI/main E2E حتى يتم تطبيق replacement ونشره.
- Target scope المتقدم على مستوى Product/Category/Team والربط التفصيلي بالعمولات ليس جزءًا مثبتًا من العقد الحالي؛ لا يجوز إدخاله أثناء هذه closure دون قرار Business مستقل.

## Final Confidence

`PRODUCTION BACKEND = HIGH`

`MANAGER SURGERY = HIGH — owner application pending`

`MAIN/BROWSER = NOT PROVEN`

## Final Closure Status

`SYSTEM-LEVEL SALES TARGETS = OPEN`

---

# 16. SELF-DIRECTED START ORDER — تعليمات للمساعد التالي

ابدأ ولا تثق بأي تقرير سابق إلا كمرجع تاريخي.

### الخطوة 1
التقط Snapshot جديد من Production في نفس لحظة العمل.

### الخطوة 2
اقرأ أحدث `erp-frontend` HEAD وDirect Parent وParent of Parent، ثم تحقق من:

- `companies/company-1/main.html` blob
- `forensic_main_assembly.yml`
- `sales/manager.html` blob

### الخطوة 3
أعد فحص Production مباشرة:

- target tables
- constraints
- triggers
- RLS
- realtime
- target RPC definitions
- Edge versions
- current target row counts

### الخطوة 4
لا تعيد إصلاح Target backend إلا إذا ظهرت Regression مباشرة من Production.

### الخطوة 5
احصل على جسم `companies/company-1/main.html` الحالي كاملًا إلى EOF.

إذا كانت الأداة لا تستطيع، أصلح طريقة الوصول نفسها قبل إعطاء أي line number.

### الخطوة 6
لا تستخدم `Current/PWA/main2` كمصدر Truth؛ استخدمه تاريخيًا فقط.

### الخطوة 7
طبّق owner replacement الموجود في هذا التقرير على `sales/manager.html` حرفيًا، ثم انشر النسخة الحالية.

### الخطوة 8
نفذ browser E2E حقيقي بحساب المستخدم:

`Create Plan → Edit Plan → Assignment → Approve Plan → Preview → Post → Retry → Approve Run → Reverse Run`

### الخطوة 9
راقب Console وNetwork، ولا تعتبر نجاح UI بدون رد RPC صحيح نجاحًا.

### الخطوة 10
اختبر Realtime فعليًا:

غيّر Target/Assignment من Session، وشاهد تحديث dashboard في Session ثانية أو في شاشة متصلة.

### الخطوة 11
اختبر Auth/Tenant isolation على مستوى المستخدم وليس UI فقط.

### الخطوة 12
بعد browser E2E، ارجع فورًا إلى Production snapshot جديد.

### الخطوة 13
أعد حساب كل نسب التقرير من Production الحالية في نفس لحظة التقرير.

### الخطوة 14
حدّث `CURRENT_STATE.md` ثم أضف تقريرًا جديدًا ولا تحذف أي تقرير.

### الخطوة 15
فقط عند اكتمال:

`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT + CURRENT BROWSER`

يُسمح بكتابة:

`SYSTEM-LEVEL SALES TARGETS = CLOSED`

---

# 17. القاعدة النهائية

لا توجد قيمة لعبارة:

`95% complete`

أو:

`Backend ready`

إذا كان `main.html` أو browser E2E غير مثبت.

الحالة الصحيحة الآن:

```text
PRODUCTION TARGET ENGINE
        =
VERIFIED

MANAGER UI
        =
SURGICAL FIX READY

MOTHER UI
        =
OWNER OPEN

BROWSER E2E
        =
OPEN

SYSTEM CLOSURE
        =
OPEN
```

وهذا هو السجل التنفيذي الصحيح القابل للاستمرار من جلسة لاحقة دون إعادة إصلاح ما ثبت أنه سليم.