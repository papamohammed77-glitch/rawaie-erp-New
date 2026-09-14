# تقرير 175 — SALES TARGETS E2E + LIVE CONTROL — 2026-09-14

## 0. نقطة البداية الحاكمة

**الهدف في هذه الجلسة كان E2E لملف النظام الأم الحالي:**

`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

وهذا الملف وحده هو Source of Truth للنظام الأم.

الحالة المعتمدة في هذه الجلسة لم تُبنَ من التقارير السابقة. تم الرجوع إلى:

`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

التقارير التاريخية استخدمت للاستدلال فقط.

---

## 1. التحقق من أحدث Git والـParent

### erp-frontend

HEAD الحالي المثبت من Git:

`3398d0952ea723d1de42b076ad93ae19c025bfa3`

رسالة commit:

`Fix forensic master source-of-truth path`

الـParent المباشر:

`8392edda5c766fa69c5faea768ca35e35b498b94`

رسالة الـParent:

`Add commission management functionality`

والـParent أثبت أن `forensic_main_assembly.yml` أضيف بهذه القاعدة:

```yaml
repository: papamohammed77-glitch/erp-frontend
path: companies/company-1/main.html
ref: main
mode: published_main_is_authoritative
fragment_mode: historical_reference_only
```

المعنى: `companies/company-1/main.html` هو الملف المنشور المرجعي، والأجزاء التاريخية ليست Source of Truth.

### rawaie-erp-New

HEAD الحالي المثبت:

`927296a29d39549e83ce88740f5ad4f4a6a0839c`

رسالة commit:

`Update CURRENT_STATE after Sales Targets Production closure`

والـParent المرجعي الأخير قبل تحديث الحالة:

`711ebb99db5207afd99e138fb0ebbf6ba470d774`

والـParent of Parent:

`faf18cae4b629e1b1f87fca7414a147f6befb541`

تم التعامل مع `CURRENT_STATE` على أنه لقطة حالة سابقة لا بديلًا عن الفحص المباشر.

---

## 2. حالة Source of Truth للنظام الأم

الملف الحالي:

`erp-frontend/companies/company-1/main.html`

Blob SHA المثبت:

`66c7c9bb2c8dba4a521647c680e2cb6605b28e0d`

الحجم المثبت:

`1,087,515 bytes`

### قيد تقني مثبت

البيئة الحالية لا تستطيع إرجاع محتوى هذا الملف الضخم كاملًا من GitHub Content API، كما أن raw download غير متاح من بيئة التنفيذ.

لذلك:

`FULL MAIN.HTML LINE-BY-LINE EOF READ = NOT PROVEN`

وبناءً عليه تم رفض اختراع أرقام أسطر أو anchors غير مثبتة.

**لم يتم تعديل `main.html` من خلال هذه الجلسة.**

---

## 3. الحالة الحالية لـSales Manager UI

الملف الحالي:

`erp-frontend/companies/company-1/sales/manager.html`

Blob SHA:

`60c6281d2a07e59d82391c225c701fc2cbb6fdff`

تمت قراءة الجزء الذي يحتوي على `renderTargets` من Current Source.

ثبت أن الشاشة الحالية لا تستخدم Sales Target Engine، بل تقوم بـ:

- قراءة قائمة المستخدمين.
- قراءة أوامر المبيعات مباشرة.
- تقسيم المبيعات حسب `created_by`.
- استخدام هدف ثابت hard-coded بقيمة `50000` ج.م لكل مستخدم.
- عرض نسبة من الهدف بشكل حسابي محلي فقط.

أي أن:

`Current Manager Targets UI != Sales Target Engine`

وهي لذلك **ليست E2E** مع الـProduction Target contract.

---

## 4. Sales Targets Production — الحالة المباشرة

### الجداول الموجودة بالفعل

Production يحتوي على:

- `sales_target_plans`
- `sales_target_assignments`
- `sales_target_runs`
- `sales_target_run_lines`

ولا توجد حاجة لإنشاء هذه الجداول مرة أخرى.

### القيود المثبتة

- `sales_target_plans.company_id -> companies.id`
- `sales_target_assignments.plan_id -> sales_target_plans.id`
- `sales_target_assignments.sales_rep_id -> users.id`
- `sales_target_assignments.branch_id -> branches.id`
- `sales_target_runs.plan_id -> sales_target_plans.id`
- `sales_target_run_lines.run_id -> sales_target_runs.id`
- `sales_target_run_lines.assignment_id -> sales_target_assignments.id`
- `(company_id, plan_code)` unique
- `(company_id, operation_id)` unique في `sales_target_runs`
- `(plan_id, sales_rep_id, branch_id)` unique في assignments
- `(run_id, assignment_id)` unique في run lines

### Production RPC المركزي

`public.sales_target_engine_atomic(uuid,text,text,uuid,jsonb,text)`

الحالة: ACTIVE وProduction verified.

العمليات المثبتة:

- `LIST_PLANS`
- `LIST_ASSIGNMENTS`
- `LIST_RUNS`
- `SAVE_PLAN`
- `SAVE_ASSIGNMENT`
- `APPROVE_PLAN`
- `CLOSE_PLAN`
- `CANCEL_PLAN`
- `PREVIEW`
- `POST`
- `APPROVE_RUN`
- `REVERSE_RUN`

الـpermission semantics الحالية تحافظ على Owner wildcard:

`permissions = ["*"]`

ولا يوجد تحويل للـOwner إلى قائمة صلاحيات صريحة بديلة.

---

## 5. الإضافة الإنتاجية التي تم تنفيذها في هذه الجلسة

بدل إعادة بناء Engine موجود، تم بناء طبقة قراءة حية ومركزة لخدمة الواجهات.

### 5.1 DB integrity guard

تم إنشاء:

`public.sales_target_integrity_guard()`

ومساران:

`trg_sales_target_assignment_integrity`

`trg_sales_target_run_line_integrity`

الهدف:

- منع assignment بشركة مختلفة عن plan.
- منع sales_rep من Company مختلفة.
- منع branch من Company مختلفة.
- منع run-line من Company مختلفة عن run.
- منع run-line من Assignment تابع لـCompany أخرى.
- منع sales_rep/branch في run-line من عبور الـCompany boundary.

هذه حراسة Database-level وليست حراسة واجهة فقط.

### 5.2 Live Dashboard RPC

تم إنشاء:

`public.sales_target_dashboard_atomic(uuid,uuid,text)`

وهو يعيد:

- plan
- assignments
- live totals
- ranking
- daily trend

والـactuals مصدرها الحالي هو:

`orders + order_details + items`

بشرط:

`orders.order_status = 'Invoiced'`

مع صافي الكمية:

`qty - qty_returned`

ونفس الأساس المتوافق مع Sales Target Engine الموجود بالفعل.

### 5.3 Edge Function جديدة

تم نشر:

`sales-target-dashboard`

Version: `1`

`verify_jwt = true`

العقد:

```text
JWT
→ auth user
→ users.auth_id
→ company_id
→ sales_target_dashboard_atomic
```

ولا يثق المتصفح في `company_id` المرسل منه.

---

## 6. Realtime — نتيجة التحقيق الحالي

تم فحص publication مباشرة.

النتيجة الفعلية الحالية:

`supabase_realtime` يحتوي على الجداول الأربعة:

- `sales_target_assignments`
- `sales_target_plans`
- `sales_target_run_lines`
- `sales_target_runs`

تمت محاولة DDL لإضافتها، لكنها رُفضت لأن `sales_target_plans` already member of publication.

هذه المحاولة **لم تُحدث تغييرًا**.

ثم تم التحقق من `pg_publication_tables` وأثبت أن الجداول الأربعة موجودة بالفعل.

النتيجة:

`REALTIME = VERIFIED`

ولا يلزم migration إضافي لهذا الجزء.

---

## 7. اختبارات Production التي نُفذت

### الاختبار A — Dashboard contract

تم إنشاء Target Plan مؤقت داخل Transaction، وربطه بمندوب موجود فعليًا، ثم استدعاء:

`sales_target_dashboard_atomic`

تم التحقق من:

- `success=true`
- `assignments` = array
- `totals` = object
- `ranking` = array
- `trend` = array

ثم تم `ROLLBACK`.

النتيجة:

`DASHBOARD_E2E = PASS`

### الاختبار B — Foreign-company guard

تمت محاولة إنشاء assignment لمندوب من Company مختلفة.

الاختبار الأول لم يصل إلى Trigger لأن بيانات Company الأجنبية نفسها لم تكن موجودة في `companies` الحالية، فتم رفضها بالـFK.

تم بعد ذلك إثبات أن المستخدمين الحاليين كلهم في Company Production الوحيدة الموجودة، وبالتالي لم توجد حالة cross-company user صالحة لإعادة اختبارها دون اختلاق بيانات.

النتيجة:

`FOREIGN_COMPANY_CASE = BLOCKED_BY_CURRENT_FK/NO_SECOND_PRODUCTION_COMPANY`

وهذا ليس defect في Target code.

---

## 8. البيانات المؤقتة

كل Target E2E records التي تم إنشاؤها للاختبارات كانت داخل Transactions وجرى Rollback.

الحالة النهائية المثبتة:

- plans = `0`
- assignments = `0`
- runs = `0`
- run_lines = `0`

ولا يوجد test residue دائم من هذه الجلسة.

---

## 9. التعديل المطلوب من المالك — Sales Manager

**المالك هو المسؤول عن ملف `erp-frontend/companies/company-1/sales/manager.html`.**

العنصر المثبت:

```text
renderTargets: function(){
```

والحد النهائي للعُنصر الحالي هو:

```text
    },

    renderReports: function(){
```

أي أن المطلوب هو استبدال `renderTargets` الحالية كاملة، من بداية:

```text
renderTargets: function(){
```

حتى السطر السابق مباشرة لـ:

```text
renderReports: function(){
```

### البديل الجاهز

```javascript
renderTargets: function(){
    var s=this;
    var endpoint=RW_SUPABASE_URL + '/functions/v1/sales-target-dashboard';
    var engine=RW_SUPABASE_URL + '/functions/v1/sales-target-engine';
    var call=function(url,payload){
        return supabase.auth.getSession().then(function(sr){
            var token=sr && sr.data && sr.data.session ? sr.data.session.access_token : null;
            if(!token) throw new Error('انتهت الجلسة');
            return fetch(url,{method:'POST',headers:{'Content-Type':'application/json','Authorization':'Bearer '+token},body:JSON.stringify(payload||{})});
        }).then(function(r){return r.json().catch(function(){return {};}).then(function(j){if(!r.ok||!j||j.success===false)throw new Error(j&&j.msg||'فشل تنفيذ العملية');return j;});});
    };
    var op=function(operation,plan_id,payload,operation_id){return call(engine,{operation:operation,plan_id:plan_id||null,payload:payload||{},operation_id:operation_id||null});};
    var uid=function(){return window.crypto&&crypto.randomUUID?crypto.randomUUID():String(Date.now())+'-'+Math.random();};

    window.RW_SalesTargets={
        load:function(){s.renderTargets();},
        savePlan:function(){
            var p={plan_code:(RW_UI.byId('st-plan-code').value||'').trim(),name:(RW_UI.byId('st-plan-name').value||'').trim(),period_start:RW_UI.byId('st-plan-start').value,period_end:RW_UI.byId('st-plan-end').value,metric:RW_UI.byId('st-plan-metric').value,notes:(RW_UI.byId('st-plan-notes').value||'').trim()};
            if(!p.plan_code||!p.period_start||!p.period_end) return RW_UI.showError('أكمل بيانات الخطة');
            RW_UI.showLoader('جاري حفظ الخطة...');
            op('SAVE_PLAN',null,p).then(function(){RW_UI.hideLoader();s.renderTargets();}).catch(function(e){RW_UI.hideLoader();RW_UI.showError(e.message);});
        },
        saveAssignment:function(){
            var planId=RW_UI.byId('st-plan-select').value,rep=RW_UI.byId('st-rep-select').value,branch=RW_UI.byId('st-branch-select').value;
            var p={sales_rep_id:rep||null,branch_id:branch||null,target_amount:Number(RW_UI.byId('st-target-amount').value||0),target_qty:Number(RW_UI.byId('st-target-qty').value||0),target_gross_profit:Number(RW_UI.byId('st-target-gp').value||0),weight:Number(RW_UI.byId('st-weight').value||100),active:true,notes:(RW_UI.byId('st-assignment-notes').value||'').trim()};
            if(!planId) return RW_UI.showError('اختر الخطة');
            RW_UI.showLoader('جاري حفظ التخصيص...');
            op('SAVE_ASSIGNMENT',planId,p).then(function(){RW_UI.hideLoader();s.renderTargets();}).catch(function(e){RW_UI.hideLoader();RW_UI.showError(e.message);});
        },
        planAction:function(action){
            var id=RW_UI.byId('st-plan-select').value;
            if(!id) return RW_UI.showError('اختر الخطة');
            RW_UI.showLoader('جاري التنفيذ...');
            op(action,id,{}).then(function(){RW_UI.hideLoader();s.renderTargets();}).catch(function(e){RW_UI.hideLoader();RW_UI.showError(e.message);});
        },
        runAction:function(action){
            var id=RW_UI.byId('st-plan-select').value;
            if(!id) return RW_UI.showError('اختر الخطة');
            if(action==='POST'){
                var operationId=uid();
                RW_UI.showLoader('جاري ترحيل نتائج الهدف...');
                op('POST',id,{},operationId).then(function(r){RW_UI.hideLoader();RW_UI.showSuccess(r.duplicate?'تم منع التكرار وإعادة نفس النتيجة':'تم الترحيل بنجاح');s.renderTargets();}).catch(function(e){RW_UI.hideLoader();RW_UI.showError(e.message);});
            }else{
                var runId=id;
                RW_UI.showLoader('جاري التنفيذ...');
                op(action,runId,{},action==='REVERSE_RUN'?uid():null).then(function(){RW_UI.hideLoader();s.renderTargets();}).catch(function(e){RW_UI.hideLoader();RW_UI.showError(e.message);});
            }
        }
    };

    RW_UI.safeHTML(RW_UI.byId('mainContent'),'<div class="text-center py-10 text-gray-400"><i class="fa-solid fa-spinner fa-spin text-2xl"></i><div class="mt-2">جاري تحميل محرك أهداف المبيعات...</div></div>');
    Promise.all([
        op('LIST_PLANS'),
        supabase.from('users').select('id,name,email,role').in('role',['مندوب مبيعات','مندوب بيع مباشر','تلي سيلز','كاشير']).order('name'),
        supabase.from('branches').select('id,name,branch_code').eq('is_active',true).order('name')
    ]).then(function(r){
        var plans=(r[0].plans||[]),users=r[1].data||[],branches=r[2].data||[];
        var selected=plans.length?plans[0].id:'';
        var now=new Date(),y=now.getFullYear(),m=String(now.getMonth()+1).padStart(2,'0');
        var first=y+'-'+m+'-01',last=new Date(y,now.getMonth()+1,0).toISOString().slice(0,10);
        var ph='<option value="">اختر الخطة</option>';
        for(var i=0;i<plans.length;i++) ph+='<option value="'+plans[i].id+'"'+(plans[i].id===selected?' selected':'')+'>'+escapeHtml(plans[i].plan_code+' — '+plans[i].name+' ['+plans[i].status+']')+'</option>';
        var rh='<option value="">بدون مندوب (عام)</option>';
        for(var j=0;j<users.length;j++) rh+='<option value="'+users[j].id+'">'+escapeHtml(users[j].name||users[j].email)+' — '+escapeHtml(users[j].role||'')+'</option>';
        var bh='<option value="">كل الفروع</option>';
        for(var k=0;k<branches.length;k++) bh+='<option value="'+branches[k].id+'">'+escapeHtml(branches[k].name||branches[k].branch_code)+'</option>';
        var html='';
        html+='<div class="space-y-4">';
        html+='<div class="card"><div class="flex flex-wrap justify-between items-center gap-2 mb-4"><div><h2 class="text-xl font-black">🎯 محرك أهداف المبيعات</h2><p class="text-xs text-gray-500 mt-1">الخطة والتخصيص والاعتماد والترحيل والمتابعة اللحظية من نفس المحرك المركزي.</p></div><button onclick="RW_SalesTargets.load()" class="px-4 py-2 rounded-xl bg-gray-100 font-bold">تحديث</button></div>';
        html+='<div class="grid grid-cols-1 md:grid-cols-5 gap-2">';
        html+='<input id="st-plan-code" class="border rounded-xl p-2.5" placeholder="كود الخطة">';
        html+='<input id="st-plan-name" class="border rounded-xl p-2.5" placeholder="اسم الخطة">';
        html+='<input id="st-plan-start" type="date" value="'+first+'" class="border rounded-xl p-2.5">';
        html+='<input id="st-plan-end" type="date" value="'+last+'" class="border rounded-xl p-2.5">';
        html+='<select id="st-plan-metric" class="border rounded-xl p-2.5"><option value="amount">قيمة</option><option value="qty">كمية</option><option value="gross_profit">مجمل الربح</option><option value="mixed">مختلط</option></select>';
        html+='</div><input id="st-plan-notes" class="border rounded-xl p-2.5 w-full mt-2" placeholder="ملاحظات الخطة">';
        html+='<div class="flex flex-wrap gap-2 mt-3"><button onclick="RW_SalesTargets.savePlan()" class="px-4 py-2 rounded-xl bg-blue-600 text-white font-bold">إنشاء خطة</button></div></div>';
        html+='<div class="card"><div class="grid grid-cols-1 md:grid-cols-6 gap-2 items-end">';
        html+='<select id="st-plan-select" class="border rounded-xl p-2.5 md:col-span-2" onchange="RW_SalesTargets.load()">'+ph+'</select>';
        html+='<button onclick="RW_SalesTargets.planAction(\'APPROVE_PLAN\')" class="px-3 py-2 rounded-xl bg-indigo-600 text-white font-bold">اعتماد</button>';
        html+='<button onclick="RW_SalesTargets.planAction(\'CANCEL_PLAN\')" class="px-3 py-2 rounded-xl bg-red-50 text-red-700 font-bold">إلغاء Draft</button>';
        html+='<button onclick="RW_SalesTargets.planAction(\'CLOSE_PLAN\')" class="px-3 py-2 rounded-xl bg-slate-800 text-white font-bold">إغلاق</button>';
        html+='<button onclick="RW_SalesTargets.runAction(\'POST\')" class="px-3 py-2 rounded-xl bg-emerald-600 text-white font-bold">ترحيل النتائج</button>';
        html+='</div></div>';
        html+='<div class="card"><h3 class="font-black mb-3">إضافة تخصيص لمندوب / فرع</h3><div class="grid grid-cols-1 md:grid-cols-6 gap-2">';
        html+='<select id="st-rep-select" class="border rounded-xl p-2.5">'+rh+'</select>';
        html+='<select id="st-branch-select" class="border rounded-xl p-2.5">'+bh+'</select>';
        html+='<input id="st-target-amount" type="number" min="0" step="0.01" class="border rounded-xl p-2.5" placeholder="هدف القيمة">';
        html+='<input id="st-target-qty" type="number" min="0" step="0.01" class="border rounded-xl p-2.5" placeholder="هدف الكمية">';
        html+='<input id="st-target-gp" type="number" min="0" step="0.01" class="border rounded-xl p-2.5" placeholder="هدف الربح">';
        html+='<input id="st-weight" type="number" min="0.01" step="0.01" value="100" class="border rounded-xl p-2.5" placeholder="الوزن">';
        html+='</div><input id="st-assignment-notes" class="border rounded-xl p-2.5 w-full mt-2" placeholder="ملاحظات التخصيص">';
        html+='<div class="mt-3"><button onclick="RW_SalesTargets.saveAssignment()" class="px-4 py-2 rounded-xl bg-slate-700 text-white font-bold">حفظ التخصيص</button></div></div>';
        html+='<div id="st-dashboard" class="card"><div class="text-center text-gray-400 py-6">اختر خطة لعرض النتائج الحية.</div></div>';
        html+='</div>';
        RW_UI.safeHTML(RW_UI.byId('mainContent'),html);
        if(selected) loadSelected(selected); else return;
        function loadSelected(planId){
            op('LIST_RUNS').then(function(runR){
                return call(endpoint,{plan_id:planId}).then(function(d){
                    var t=d.totals||{},a=d.assignments||[],rk=d.ranking||[],tr=d.trend||[],runs=(runR.runs||[]).filter(function(x){return x.plan_id===planId;});
                    var h='<div class="flex flex-wrap justify-between gap-2 items-center mb-4"><div><h3 class="font-black text-lg">'+escapeHtml((d.plan&&d.plan.name)||'الخطة')+'</h3><p class="text-xs text-gray-500">'+escapeHtml((d.plan&&d.plan.period_start)||'')+' → '+escapeHtml((d.plan&&d.plan.period_end)||'')+' | '+escapeHtml((d.plan&&d.plan.status)||'')+'</p></div><div class="text-xs text-gray-500">آخر تحديث: '+new Date().toLocaleTimeString('ar-EG')+'</div></div>';
                    h+='<div class="grid grid-cols-2 md:grid-cols-6 gap-2 mb-4">'+kpi('الهدف',t.target_amount,'ج.م')+kpi('المحقق',t.actual_amount,'ج.م')+kpi('الإنجاز',t.amount_pct,'%')+kpi('هدف الكمية',t.target_qty,'')+kpi('المحقق كمية',t.actual_qty,'')+kpi('الإنجاز كمية',t.qty_pct,'%')+'</div>';
                    h+='<div class="grid grid-cols-1 lg:grid-cols-2 gap-3"><div class="card border"><h4 class="font-black mb-2">أداء التخصيصات</h4><div class="overflow-auto"><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2 text-right">المندوب</th><th class="p-2">الفرع</th><th class="p-2">الهدف</th><th class="p-2">المحقق</th><th class="p-2">%</th></tr></thead><tbody>';
                    for(var i=0;i<a.length;i++){var z=a[i],pct=z.target_amount>0?(Number(z.actual_amount)/Number(z.target_amount)*100):0;h+='<tr class="border-t"><td class="p-2 font-bold">'+escapeHtml(z.sales_rep_name||'عام')+'</td><td class="p-2">'+escapeHtml(z.branch_name||'كل الفروع')+'</td><td class="p-2">'+fmtNum(z.target_amount)+'</td><td class="p-2">'+fmtNum(z.actual_amount)+'</td><td class="p-2 font-black">'+fmtNum(pct)+'%</td></tr>';}
                    if(!a.length)h+='<tr><td colspan="5" class="p-4 text-center text-gray-400">لا توجد تخصيصات</td></tr>';
                    h+='</tbody></table></div></div><div class="card border"><h4 class="font-black mb-2">ترتيب المندوبين</h4><div class="space-y-2">';
                    for(var r=0;r<rk.length;r++){var q=rk[r];h+='<div class="flex justify-between items-center border-b pb-2"><span class="font-bold">'+escapeHtml(q.rep_name||'غير محدد')+'</span><span class="font-black">'+fmtNum(q.actual_amount)+' ج.م</span></div>';}
                    if(!rk.length)h+='<div class="text-center text-gray-400 py-4">لا توجد نتائج</div>';
                    h+='</div></div></div>';
                    h+='<div class="card border mt-3"><h4 class="font-black mb-2">عمليات الترحيل</h4><div class="overflow-auto"><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">التاريخ</th><th class="p-2">الحالة</th><th class="p-2">القيمة</th><th class="p-2">الكميات</th></tr></thead><tbody>';
                    for(var rr=0;rr<runs.length;rr++){h+='<tr class="border-t"><td class="p-2">'+escapeHtml(runs[rr].evaluated_at||runs[rr].created_at||'')+'</td><td class="p-2 font-bold">'+escapeHtml(runs[rr].status||'')+'</td><td class="p-2">'+fmtNum(runs[rr].total_actual_amount)+'</td><td class="p-2">'+fmtNum(runs[rr].total_actual_qty)+'</td></tr>';}
                    if(!runs.length)h+='<tr><td colspan="4" class="p-4 text-center text-gray-400">لا توجد عمليات ترحيل</td></tr>';
                    h+='</tbody></table></div></div>';
                    var box=RW_UI.byId('st-dashboard');if(box)RW_UI.safeHTML(box,h);
                    setTimeout(function(){if(tr.length){var cv=document.createElement('div');cv.className='mt-3 text-xs text-gray-500';cv.innerHTML='الاتجاه اليومي: '+tr.length+' يومًا مسجلًا';var b=RW_UI.byId('st-dashboard');if(b)b.appendChild(cv);}},50);
                });
            }).catch(function(e){var box=RW_UI.byId('st-dashboard');if(box)RW_UI.safeHTML(box,'<div class="text-center py-6 text-red-500">فشل تحميل لوحة الأهداف: '+escapeHtml(e.message)+'</div>');});
        }
        function kpi(label,value,suffix){return '<div class="stat-card text-center"><div class="text-xs text-gray-400">'+label+'</div><div class="text-lg font-black">'+fmtNum(Number(value)||0)+' '+suffix+'</div></div>';}
        function escapeHtml(v){return String(v==null?'':v).replace(/[&<>\"']/g,function(c){return {'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;',"'":'&#39;'}[c];});}
    }).catch(function(e){RW_UI.safeHTML(RW_UI.byId('mainContent'),'<div class="text-center py-10 text-red-500">فشل تحميل محرك الأهداف: '+String(e.message||e)+'</div>');});
},
```

### ملاحظة تنفيذية مهمة

هذا الاستبدال مخصص للـ`manager.html` فقط.

لم يتم وضع أرقام أسطر مصطنعة لأن الـCurrent Source الذي أعادته أداة GitHub في هذه البيئة يحوي أجزاء من الملف في أسطر منطقية ضخمة، وبالتالي رقم السطر المادي غير مثبت بشكل موثوق.

العنصر النصي نفسه مثبت بالكامل من Current Source، وبداية ونهاية الاستبدال محددتان أعلاه.

---

## 10. النظام الأم `main.html`

لم يتم تنفيذ أي تعديل مباشر على `main.html` لأن:

1. المالك قرر أن هذا الملف تحت مسؤوليته.
2. Source API الحالي لا يعيد محتواه الكامل بسبب الحجم.
3. لا يجوز اختراع anchor أو رقم سطر.

لذلك لم تتم كتابة “تعليمة جراحية” غير مثبتة.

### ما ثبت وظيفيًا

الـProduction أصبح يملك:

`Engine CRUD + Approval + Posting + Reverse + Live Dashboard + DB Integrity Guard + Edge JWT`

وبالتالي عندما يصبح Current `main.html` قابلًا للقراءة كاملة يجب ربط تبويب الأهداف مباشرة بهذا العقد، وليس إعادة بناء Target backend.

---

## 11. ما الذي لم يتم الادعاء بإغلاقه

لم يُعتبر ما يلي مغلقًا:

`MASTER UI`

`BROWSER E2E`

`SYSTEM-LEVEL SALES TARGETS`

لأن تشغيل المتصفح الفعلي على نسخة المستخدم المنشورة وجلسة JWT لم يكن متاحًا من بيئة التنفيذ.

أي تقرير يقول إن Browser E2E = PASS دون هذا الاختبار لا يُقبل كدليل.

---

## 12. أخطاء/محاولات فاشلة في هذه الجلسة

### محاولة 1 — إنشاء Live Dashboard migration

فشلت بسبب alias SQL غير صالح (`day`).

لم تُطبق migration.

### محاولة 2 — إعادة نشر SQL بعد تصحيح alias

تمت بنجاح.

### محاولة 3 — تفعيل Realtime بإضافة الجداول

فشلت برسالة PostgreSQL تفيد أن `sales_target_plans` عضو بالفعل في `supabase_realtime`.

بعدها تم التحقق عبر `pg_publication_tables` وثبت أن الجداول الأربعة أعضاء بالفعل.

إذًا هذه ليست migration ناقصة.

### محاولة E2E عبر Company غير موجودة

رفضتها FK قبل الوصول إلى Target trigger.

لم يتم إنشاء Company جديدة بغرض الاختبار.

---

## 13. GLOBAL CLOSURE MATRIX — الوضع الحالي بعد الجلسة

| العنصر | Git | Production | Runtime | الحالة |
|---|---|---|---|---|
| Target tables | PROVEN | PROVEN | N/A | CLOSED |
| Target engine RPC | PROVEN | PROVEN | Transaction E2E PASS | CLOSED |
| Idempotent POST | PROVEN | PROVEN | POST retry PASS سابقًا | CLOSED |
| Audit target triggers | PROVEN | PROVEN | trigger present | CLOSED |
| DB Company integrity | PROVEN | PROVEN | Guard installed | CLOSED |
| Live dashboard RPC | CREATED | DEPLOYED | Transaction E2E PASS | CLOSED |
| Live dashboard Edge | CREATED | ACTIVE v1 | JWT contract | CLOSED |
| Realtime | PROVEN | ALREADY MEMBER | publication verified | CLOSED |
| Manager Target UI | CURRENT SOURCE READ | N/A | hardcoded 50k | OPEN → OWNER SURGERY |
| Mother main.html | CURRENT BLOB PROVEN | N/A | full EOF unavailable | OPEN → OWNER |
| Browser E2E | N/A | N/A | not executable here | OPEN |
| System Target closure | Partial | Partial | blocked by master/browser | OPEN |

---

## 14. أهم استنتاج هندسي

لا يوجد مبرر لإعادة إنشاء Sales Target database أو إعادة كتابة Engine الموجود.

العمل الحقيقي المتبقي في هذه المرحلة هو:

```text
CURRENT MASTER UI
        ↓
SALES TARGET ENGINE
        ↓
LIVE DASHBOARD EDGE
        ↓
PRODUCTION DATABASE
        ↓
REALTIME
        ↓
BROWSER E2E
```

الـManager UI الحالي كان يمثل تقرير مبيعات محليًا، وليس Target Management.

البديل المرفق ينقله إلى Target Management فعلي.

أما `main.html` فلا يجوز تعديلها حتى تصبح قابلة للقراءة الكاملة من Current Source أو تُقدم نسخة Current كاملة قابلة للفحص.

---

# FINAL SELF-AUDIT

## What I Proved

- Current frontend HEAD وParent تم التحقق منهما.
- `forensic_main_assembly.yml` يحدد `erp-frontend/companies/company-1/main.html` كمصدر الحقيقة.
- Sales Target tables موجودة في Production.
- Sales Target engine موجود ويعمل.
- Live Dashboard RPC أُنشئ ونُشر بنجاح.
- DB integrity guards أُنشئت ونُشرت.
- Edge dashboard نُشر مع JWT.
- Live Dashboard transaction test نجح.
- Realtime publication للجداول الأربعة موجود بالفعل.
- Manager current target screen الحالية تستخدم target hard-coded `50000` ولا تستخدم المحرك.

## What I Did Not Prove

- Browser E2E للنسخة المنشورة.
- قراءة `main.html` كاملًا حتى EOF.
- نجاح التعديل الجراحي في `main.html` لأنه لم يتم تنفيذه.
- نجاح تجربة cross-company مستخدم صالح من Company ثانية، لأن Production الحالية لا تحتوي Company ثانية.

## What I Fixed

- Live dashboard production contract.
- DB-level Target tenant integrity guards.
- Edge endpoint للوصول الحي إلى Dashboard.
- Git canonical migration/source files لهذه الإضافة.

## What I Initially Missed

- Realtime كان موجودًا بالفعل؛ الاستعلام الأول لم يُظهره بسبب طريقة الربط المستخدمة، وتم تصحيحه عبر `pg_publication_tables`.
- واجهة `manager.html` لا تستخدم الـTarget Engine أصلًا رغم وجود backend كامل.

## What Could Still Be Wrong

- قد توجد داخل `main.html` نقاط تكامل Target لم تظهر بسبب عدم إمكانية قراءة الملف الكامل من البيئة الحالية.
- قد يظهر في المتصفح Console defect بعد دمج جراحة Manager/Master لم يمكن تشغيلها هنا.

## Final Confidence

`PRODUCTION TARGET BACKEND = HIGH`

`LIVE DASHBOARD = HIGH`

`REALTIME = HIGH`

`MANAGER UI CURRENT = PROVEN DEFECT / OWNER PATCH PREPARED`

`MASTER UI = UNPROVEN`

`BROWSER E2E = OPEN`

## Final Closure Status

`SALES TARGETS SYSTEM = OPEN`

السبب الوحيد بعد تنفيذ Production work هو أن Master UI وBrowser E2E لم يغلقا بعد.

---

# تعليمات بدء المهمة للمساعد التالي — إلزامية

لا تبدأ من هذا التقرير كحالة Production.

ابدأ دائمًا بالترتيب:

```text
1. CURRENT FRONTEND HEAD
2. CURRENT DIRECT PARENT
3. CURRENT MASTER BLOB
4. FULL CURRENT MASTER SOURCE TO EOF
5. CURRENT SUPABASE TABLES
6. CURRENT RPC DEFINITIONS
7. CURRENT EDGE DEPLOYMENTS
8. CURRENT RLS
9. CURRENT TRIGGERS
10. CURRENT REALTIME PUBLICATION
11. CURRENT PRODUCTION DATA
12. CURRENT BROWSER / CONSOLE EVIDENCE
```

ثم:

```text
HISTORICAL CONTRACT
        ↓
CURRENT BEHAVIOR
        ↓
ACTUAL GAP
        ↓
MINIMAL SURGICAL FIX
        ↓
PRODUCTION CHANGE
        ↓
TEST
        ↓
DEPLOY
        ↓
PRODUCTION VERIFY
        ↓
OWNER MASTER SURGERY
        ↓
BROWSER E2E
        ↓
REALTIME VERIFY
        ↓
AUDIT VERIFY
        ↓
CURRENT STATE UPDATE
        ↓
CLOSE
```

ولا تعيد إصلاح شيء ثبت إغلاقه في Current Production إلا إذا أثبتت لقطة جديدة Regression.

ولا تستخدم أرقام أسطر من تقرير قديم.

ولا تعتبر `backend PASS` مساويًا لـ`system PASS`.

ولا تُعلن 100% closure قبل Browser E2E على النسخة المنشورة الحالية.
