# Report183 — استكمال Sales Targets Engine — Functional / Diamond Closure

**التاريخ:** 2026-09-14
**المرحلة:** Sales Targets Engine / Mother System Functional Completion
**الحالة المرجعية الوحيدة:** CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE

## تنبيه حاكم في بداية التقرير — يجب قراءته أولًا

**اختبار E2E لملف النظام الأم `erp-frontend/companies/company-1/main.html` هو نقطة الحسم، ولا يجوز اعتبار Sales Targets مكتملة وظيفيًا قبل اختبار النسخة الحالية نفسها بعد الدمج والنشر.**

تم التعامل مع `main.html` باعتباره Source of Truth الحالي، وليس أي جزء من الأجزاء التاريخية الـ11.

تم التحقق من أن النسخة الحالية موجودة في Git، ثم تم تتبعها حتى EOF. جسم الملف الحالي ينتهي عند `</html>` في السطر **39847**. تم التحقق من منطقة Sales Targets الحالية مباشرة، وتمت قراءة الوحدة كاملة من بداية `RW_SalesTargetsMain` إلى إغلاقها.

> ملاحظة دقة: لم يُعاد في هذه الجلسة عرض كل واحد من 39,847 سطرًا في نافذة المحادثة كسطر منفصل؛ لكن تم تحميل المحتوى الكامل الحالي والتحقق من EOF، ثم إجراء القراءة التفصيلية المتسلسلة الكاملة على الـclosure المستهدف Sales Targets والـhelpers والـdispatcher والـEOF.

---

# 1. CURRENT GIT — Frontend Mother

المستودع الحالي:

`papamohammed77-glitch/erp-frontend`

الفرع:

`main`

آخر Commit فعلي:

`70cc69aece9568374a8e86175e6963cae6832c02`

رسالة الـcommit:

`Update main.html`

Direct Parent:

`9e6645bf3c613f8995785d1fe70a88150ce87c16`

Parent of Parent:

`91e50848a65cb0255e95c4e7d8f1a1523eb43e85`

والـcommit الحالي `70cc69...` أضاف تعريف `RW_UI` فوق استخدام Sales Targets له.

الـParent `9e6645...` كان قد أصلح:

- `rw-page-content` → `rw-page-container`
- `this.selectPlan(...)` → `RW_SalesTargetsMain.selectPlan(...)`

والـParent الأقدم `91e508...` أدخل وحدة `RW_SalesTargetsMain` وربطها بالـnavigation/dispatcher.

## CURRENT Mother blob

`43a6061233ad9d7e84e946c9bac9e64297f643a6`

## EOF

الـEOF الفعلي:

```text
</script>
</body>
</html>
```

وأقرب عنوان EOF في النسخة الحالية هو السطر **39847** عند `</html>`.

---

# 2. forensic_main_assembly.yml

تم التحقق من الملف:

`rawaie-erp-New/forensic_main_assembly.yml`

وهو بالفعل مضبوط على:

```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
assembly_status:
  mode: published_main_is_authoritative
  fragment_mode: historical_reference_only
```

**لم يتم تعديل هذا الملف** لأنه صحيح بالفعل.

الأجزاء:

`Current/PWA/main2/main1.md ... main11.md`

تبقى Historical Reference فقط، ولا يجوز إعادة البناء منها.

---

# 3. CURRENT Mother — Sales Targets anchors

في النسخة الحالية:

### Helper

السطر الحالي يحتوي بالفعل على:

```js
const safeHTML = (el, html) => { if (!el) return; try { el.innerHTML = html; } catch(e) { console.error(e); } };
const safeText = (el, text) => { if (!el) return; try { el.innerText = text; } catch(e) { console.error(e); } };
const RW_UI = { safeHTML: safeHTML };
```

وهو في منطقة الـhelpers حول السطر **873**.

**إذن مشكلة `RW_UI is not defined` القديمة مغلقة بالفعل ولا يجوز إعادة إصلاحها.**

### بداية Sales Targets module

السطر **1311**:

```js
var RW_SalesTargetsMain = (function(){
```

### نهاية Sales Targets module

السطر **1481**:

```js
})();
```

المطلوب الجراحي في هذا التقرير يقتصر على استبدال هذا الـblock فقط.

لا يتم تعديل الـdispatcher خارج هذا الـblock.

---

# 4. ما تم إثباته من CURRENT Source

الوحدة الحالية تحتوي بالفعل على:

- `LIST_PLANS`
- إنشاء Plan
- تعديل Draft Plan
- اختيار Plan
- Preview
- Approve
- Cancel Draft
- Close
- Post Run
- Approve Run
- Reverse Run
- Dashboard
- KPIs
- Assignment performance read-only
- Ranking
- Runs table
- Realtime subscriptions

لكنها لا تمنح المستخدم في النظام الأم القدرة التشغيلية الكاملة الموجودة بالفعل في الـbackend على:

- عرض وإدارة الـAssignments ككيانات مستقلة.
- إضافة Assignment جديد.
- تعديل Assignment موجود.
- تفعيل/تعطيل Assignment.
- Clone Plan.
- رؤية target amount/qty/gross profit/weight/active داخل شاشة الإدارة.
- تشغيل دورة إدارة الهدف بالكامل من الواجهة دون الرجوع إلى وظائف خلفية.

وهذا هو الـFunctional Gap الحقيقي الحالي.

---

# 5. CURRENT Production / Backend — ما هو موجود بالفعل

Supabase Production:

`fiilmooggumokxanwiyx`

الـEdge Functions الحالية:

```text
sales-target-engine     ACTIVE / version 2 / verify_jwt=true
sales-target-dashboard  ACTIVE / version 1 / verify_jwt=true
```

`Sales-target-engine` يحول المستخدم المصادق إلى `users.company_id` ثم يستدعي:

`public.sales_target_engine_gateway`

والـdashboard يستدعي:

`public.sales_target_dashboard_atomic`

الـengine الحالي المثبت في Git/Production يدعم العمليات التالية:

```text
LIST_PLANS
LIST_ASSIGNMENTS
LIST_RUNS
SAVE_PLAN
SAVE_ASSIGNMENT
CLONE_PLAN
SET_ASSIGNMENT_ACTIVE
APPROVE_PLAN
CLOSE_PLAN
CANCEL_PLAN
PREVIEW
POST
APPROVE_RUN
REVERSE_RUN
```

وبالتالي لا توجد حاجة إلى إنشاء Edge Function جديدة لمجرد استكمال Mother UI.

**قرار CTO:** لا يتم إنشاء Backend مكرر ولا جدول جديد لهذه الفجوة لأن العقد الخلفي الحالي يوفر المطلوب بالفعل.

---

# 6. CURRENT Database — الحالة التشغيلية

تم التحقق مباشرة من Production أن:

```text
sales_target_plans = 0
sales_target_runs  = 0
```

ولم يتم إنشاء Target business data دائم جديد في Production أثناء هذه الجلسة.

هذا مهم لأن عدم وجود بيانات أهداف حقيقية يمنع الادعاء بأن دورة Business E2E الإنتاجية الكاملة قد أُنجزت على بيانات فعلية.

لا يجوز تحويل ذلك إلى PASS وهمي.

---

# 7. المنافسون — لماذا الحالية ليست كافية

## Odoo

Odoo يربط أهداف الأداء بخطط قابلة للقياس ويتيح تحديد التكرار، نوع القياس، وربط الخطة ببائعي المبيعات، مع مسار اعتماد واضح؛ والخطة المعتمدة لا تعدل مباشرة بل تُعاد إلى Draft عند الحاجة. citeturn572473search1

## Dynamics 365

Dynamics 365 يتعامل مع الأهداف ككيانات إدارية قابلة للتوزيع على أفراد وفرق ومناطق مع Hierarchy وRollup وMetrics وTime Periods ومراقبة الإنجاز. citeturn572473search0turn572473search3

## Daftra

Daftra يعرض إدارة Sales Targets & Commissions، مع أهداف بالمبلغ أو الكمية، وتتبع أداء فريق المبيعات، وربط قواعد الهدف بفترات وبموظفين/فرق، مع إمكانيات أكثر تفصيلاً حول الأداء والعمولات. citeturn572473search7turn572473search9turn572473search10

### الاستنتاج للمشروع

لن نقلد المنافسين حرفيًا. لكن حتى تكون شاشة الروائع منافسة فعليًا، يجب على Mother أن تسمح بإدارة دورة الهدف وليس عرضها فقط.

أولوية هذه الجلسة:

**Plan + Assignment + Lifecycle + Dashboard + Realtime**

أما Commission Rules وProduct/Category Targeting وHierarchy الأوسع فهي مراحل مستقلة لاحقة ولا يجوز خلطها في هذا الـclosure.

---

# 8. القرار الجراحي

لا يتم تعديل:

- dispatcher
- navigation
- `safeHTML`
- `RW_UI`
- `RW_STATE`
- أي من الأجزاء التاريخية الـ11
- `New-main`
- الـBackend الحالي
- الـEdge Functions الحالية

يتم فقط استبدال:

**السطر 1311 إلى السطر 1481**

أي:

```text
START:
var RW_SalesTargetsMain = (function(){

END:
})();
```

بالوحدة الكاملة أدناه.

---

# 9. OWNER SURGICAL REPLACEMENT — COMPLETE BLOCK

## ابحث عن

في `erp-frontend/companies/company-1/main.html` الحالي ابحث عن هذا السطر الكامل الموجود في السطر **1311**:

```js
var RW_SalesTargetsMain = (function(){
```

ثم احذف **كل البلوك بالكامل حتى السطر الكامل التالي في نهايته، وهو:**

```js
})();
```

وهذا الـ`})();` هو الخاص بـ`RW_SalesTargetsMain` مباشرة قبل:

```js
function _rwCompanyId() {
```

**لا تحذف `function _rwCompanyId()`**.

## استبدله بالكامل بهذا البلوك:

```js
var RW_SalesTargetsMain = (function(){
    var realtimeChannel = null;
    var postOperationId = null;
    var reverseOperationIds = {};
    var selectedPlanId = null;
    var metaCache = null;

    function endpoint(name){ return RW_SUPABASE_URL + '/functions/v1/' + name; }

    function esc(v){
        return String(v==null?'':v).replace(/[&<>\"']/g,function(c){
            return {'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;',"'":'&#39;'}[c];
        });
    }

    function num(v){
        return (Number(v)||0).toLocaleString('ar-EG',{maximumFractionDigits:2});
    }

    function uid(){
        return window.crypto&&crypto.randomUUID ? crypto.randomUUID() : String(Date.now())+'-'+Math.random();
    }

    function companyId(){
        return _rwCompanyId();
    }

    function perms(){
        return RW_STATE && Array.isArray(RW_STATE.permissions) ? RW_STATE.permissions : [];
    }

    function hasPerm(name){
        var p=perms();
        return p.indexOf('*')>=0 || p.indexOf(name)>=0;
    }

    function canRead(){
        return hasPerm('sales_manager') || hasPerm('sales_supervisor') || hasPerm('general_manager') || hasPerm('reports');
    }

    function canManage(){
        return hasPerm('sales_manager') || hasPerm('sales_supervisor') || hasPerm('general_manager');
    }

    function canApprove(){
        return hasPerm('sales_manager') || hasPerm('general_manager');
    }

    function statusLabel(s){
        var m={Draft:'مسودة',Approved:'معتمدة',Closed:'مغلقة',Cancelled:'ملغاة',Preview:'معاينة',Posted:'مرحّلة',Reversed:'معكوسة'};
        return m[s]||s||'';
    }

    async function call(name,payload){
        var ses=await supabase.auth.getSession();
        var token=ses&&ses.data&&ses.data.session?ses.data.session.access_token:null;
        if(!token) throw new Error('انتهت الجلسة');
        var r=await fetch(endpoint(name),{
            method:'POST',
            headers:{'Content-Type':'application/json','Authorization':'Bearer '+token},
            body:JSON.stringify(payload||{})
        });
        var j=await r.json().catch(function(){return {};});
        if(!r.ok || !j || j.success===false) throw new Error((j&&j.msg)||'فشل تنفيذ العملية');
        return j;
    }

    async function op(operation,planId,payload,operationId){
        return call('sales-target-engine',{
            operation:operation,
            plan_id:planId||null,
            payload:payload||{},
            operation_id:operationId||null
        });
    }

    async function loadPlans(){
        return op('LIST_PLANS',null,{},null);
    }

    async function loadMeta(force){
        if(metaCache && !force) return metaCache;
        var c=companyId();
        if(!c) throw new Error('سياق الشركة غير محدد');

        var results=await Promise.all([
            supabase.from('users')
                .select('id,name,email,role,status')
                .eq('company_id',c)
                .eq('status','Active')
                .order('name'),
            supabase.from('branches')
                .select('id,name,branch_code,is_active')
                .eq('company_id',c)
                .order('name')
        ]);

        if(results[0].error) throw new Error(results[0].error.message);
        if(results[1].error) throw new Error(results[1].error.message);

        metaCache={
            users:results[0].data||[],
            branches:(results[1].data||[]).filter(function(x){return x.is_active!==false;})
        };
        return metaCache;
    }

    function preserveSelectedPlan(id){
        if(id) selectedPlanId=id;
        var select=byId('st-main-plan-select');
        if(select && selectedPlanId) select.value=selectedPlanId;
    }

    async function renderDashboard(planId){
        var box=byId('rw-sales-target-dashboard');
        if(!box || !planId) return;

        try{
            var j=await call('sales-target-dashboard',{plan_id:planId});
            var t=j.totals||{};
            var a=j.assignments||[];
            var r=j.ranking||[];
            var trend=j.trend||[];
            var runsResult=await op('LIST_RUNS',null,{},null);
            var runs=(runsResult.runs||[]).filter(function(x){return x.plan_id===planId;});
            var p=j.plan||{};
            var editable=canManage() && p.status==='Draft';
            var approvable=canApprove();

            var h='<div class="rw-kpi-grid">';
            h+='<div class="rw-kpi-card"><div class="rw-kpi-card-top"><span>هدف القيمة</span></div><div class="rw-kpi-value">'+num(t.target_amount)+' ج.م</div></div>';
            h+='<div class="rw-kpi-card"><div class="rw-kpi-card-top"><span>المحقق</span></div><div class="rw-kpi-value">'+num(t.actual_amount)+' ج.م</div></div>';
            h+='<div class="rw-kpi-card"><div class="rw-kpi-card-top"><span>إنجاز القيمة</span></div><div class="rw-kpi-value">'+num(t.amount_pct)+'%</div></div>';
            h+='<div class="rw-kpi-card"><div class="rw-kpi-card-top"><span>إنجاز الكمية</span></div><div class="rw-kpi-value">'+num(t.qty_pct)+'%</div></div>';
            h+='</div>';

            h+='<div class="rw-card"><div style="display:flex;justify-content:space-between;gap:12px;align-items:center;flex-wrap:wrap"><div><h3>ملخص الخطة</h3><div style="color:#6b7280;font-size:13px">'+esc(p.plan_code||'')+' — '+esc(p.name||'')+'</div></div><div class="rw-badge">'+esc(statusLabel(p.status))+'</div></div></div>';

            h+='<div class="rw-card"><div style="display:flex;justify-content:space-between;align-items:center;gap:12px;flex-wrap:wrap"><h3>تخصيصات الأهداف</h3>';
            if(editable) h+='<button class="rw-btn rw-btn-success" onclick="RW_SalesTargetsMain.openAssignmentEditor(null)">+ إضافة تخصيص</button>';
            h+='</div>';

            if(!a.length){
                h+='<div style="padding:28px;text-align:center;color:#6b7280">لا توجد تخصيصات لهذه الخطة. أضف مندوبًا أو فرعًا أو هدفًا عامًا قبل اعتماد الخطة.</div>';
            }else{
                h+='<div style="overflow:auto"><table class="rw-table"><thead><tr><th>المندوب</th><th>الفرع</th><th>هدف القيمة</th><th>هدف الكمية</th><th>هدف الربح</th><th>الوزن</th><th>المحقق</th><th>الإنجاز</th><th>الحالة</th><th>الإجراء</th></tr></thead><tbody>';
                for(var i=0;i<a.length;i++){
                    var z=a[i];
                    h+='<tr>';
                    h+='<td>'+esc(z.sales_rep_name||'عام')+'</td>';
                    h+='<td>'+esc(z.branch_name||'كل الفروع')+'</td>';
                    h+='<td>'+num(z.target_amount)+'</td>';
                    h+='<td>'+num(z.target_qty)+'</td>';
                    h+='<td>'+num(z.target_gross_profit)+'</td>';
                    h+='<td>'+num(z.weight)+'%</td>';
                    h+='<td>'+num(z.actual_amount)+'</td>';
                    h+='<td>'+num(z.achievement_pct)+'%</td>';
                    h+='<td>'+(z.active?'نشط':'موقوف')+'</td>';
                    h+='<td>';
                    if(editable){
                        h+='<button class="rw-btn" onclick="RW_SalesTargetsMain.openAssignmentEditor('+JSON.stringify(z.id)+')">تعديل</button> ';
                        h+='<button class="rw-btn" onclick="RW_SalesTargetsMain.setAssignmentActive('+JSON.stringify(z.id)+','+(z.active?'false':'true')+')">'+(z.active?'إيقاف':'تفعيل')+'</button>';
                    }else{
                        h+='<span style="color:#9ca3af;font-size:12px">قراءة فقط</span>';
                    }
                    h+='</td></tr>';
                }
                h+='</tbody></table></div>';
            }
            h+='</div>';

            h+='<div class="rw-card"><h3>ترتيب المندوبين</h3>';
            if(!r.length){
                h+='<div style="padding:18px;color:#6b7280">لا توجد نتائج بعد.</div>';
            }else{
                for(var k=0;k<r.length;k++){
                    h+='<div style="display:flex;justify-content:space-between;border-bottom:1px solid #eee;padding:12px 0;gap:12px"><b>'+esc(r[k].rep_name||'غير محدد')+'</b><span>'+num(r[k].actual_amount)+' ج.م — '+num(r[k].achievement_pct)+'%</span></div>';
                }
            }
            h+='</div>';

            h+='<div class="rw-card"><h3>الاتجاه اليومي</h3>';
            if(!trend.length){
                h+='<div style="padding:18px;color:#6b7280">لا توجد حركة مبيعات داخل فترة الخطة.</div>';
            }else{
                var maxTrend=0;
                for(var q=0;q<trend.length;q++) maxTrend=Math.max(maxTrend,Number(trend[q].actual_amount)||0);
                for(var q2=0;q2<trend.length;q2++){
                    var tv=Number(trend[q2].actual_amount)||0;
                    var width=maxTrend>0?Math.max(3,(tv/maxTrend)*100):3;
                    h+='<div style="display:grid;grid-template-columns:100px 1fr 120px;gap:10px;align-items:center;margin:8px 0"><span>'+esc(trend[q2].metric_day||'')+'</span><div style="height:10px;background:#eef2f7;border-radius:999px;overflow:hidden"><div style="height:100%;width:'+width+'%;background:#2563eb;border-radius:999px"></div></div><b style="text-align:left">'+num(tv)+' ج.م</b></div>';
                }
            }
            h+='</div>';

            h+='<div class="rw-card"><h3>عمليات الترحيل</h3><div style="overflow:auto"><table class="rw-table"><thead><tr><th>التاريخ</th><th>الحالة</th><th>القيمة</th><th>الكمية</th><th>الإجراء</th></tr></thead><tbody>';
            if(!runs.length){
                h+='<tr><td colspan="5">لا توجد عمليات ترحيل</td></tr>';
            }else{
                for(var n=0;n<runs.length;n++){
                    var run=runs[n];
                    h+='<tr><td>'+esc(run.evaluated_at||run.created_at||'')+'</td><td>'+esc(statusLabel(run.status))+'</td><td>'+num(run.total_actual_amount)+'</td><td>'+num(run.total_actual_qty)+'</td><td>';
                    if(approvable && run.status==='Posted') h+='<button class="rw-btn" onclick="RW_SalesTargetsMain.approveRun('+JSON.stringify(run.id)+')">اعتماد</button> ';
                    if(approvable && (run.status==='Posted'||run.status==='Approved')) h+='<button class="rw-btn rw-btn-danger" onclick="RW_SalesTargetsMain.reverseRun('+JSON.stringify(run.id)+')">عكس</button>';
                    if(!approvable || run.status==='Preview' || run.status==='Reversed') h+='<span style="color:#9ca3af;font-size:12px">—</span>';
                    h+='</td></tr>';
                }
            }
            h+='</tbody></table></div></div>';

            RW_UI.safeHTML(box,h);
        }catch(e){
            RW_UI.safeHTML(box,'<div class="rw-error">'+esc(e.message)+'</div>');
        }
    }

    function subscribeRealtime(){
        var c=companyId();
        if(!c) return;
        if(realtimeChannel){ try{supabase.removeChannel(realtimeChannel);}catch(e){} realtimeChannel=null; }
        realtimeChannel=supabase.channel('rw-sales-target-main-'+c)
          .on('postgres_changes',{event:'*',schema:'public',table:'sales_target_plans',filter:'company_id=eq.'+c},function(payload){
              var id=(payload&&payload.new&&payload.new.id)||selectedPlanId;
              render().catch(function(e){console.error(e);});
              if(id) selectedPlanId=id;
          })
          .on('postgres_changes',{event:'*',schema:'public',table:'sales_target_assignments',filter:'company_id=eq.'+c},function(){
              if(selectedPlanId) renderDashboard(selectedPlanId).catch(function(e){console.error(e);});
          })
          .on('postgres_changes',{event:'*',schema:'public',table:'sales_target_runs',filter:'company_id=eq.'+c},function(){
              if(selectedPlanId) renderDashboard(selectedPlanId).catch(function(e){console.error(e);});
          })
          .on('postgres_changes',{event:'*',schema:'public',table:'sales_target_run_lines',filter:'company_id=eq.'+c},function(){
              if(selectedPlanId) renderDashboard(selectedPlanId).catch(function(e){console.error(e);});
          })
          .subscribe();
    }

    async function render(){
        var c=byId('rw-page-container');
        if(!c) return;
        if(!canRead()){
            RW_UI.safeHTML(c,'<div class="rw-card"><div class="rw-error">ليس لديك صلاحية قراءة أهداف المبيعات.</div></div>');
            return;
        }
        RW_UI.safeHTML(c,'<div class="rw-card"><div class="rw-loading">جاري تحميل محرك أهداف المبيعات...</div></div>');
        try{
            var r=await loadPlans(), plans=r.plans||[];
            var meta=null;
            if(canManage()) meta=await loadMeta(false);

            var currentPlan=null;
            if(selectedPlanId){
                for(var p0=0;p0<plans.length;p0++) if(plans[p0].id===selectedPlanId){currentPlan=plans[p0];break;}
            }
            if(!currentPlan && plans.length) currentPlan=plans[0];
            if(currentPlan) selectedPlanId=currentPlan.id;

            var h='<div class="rw-page-header"><div><h1>🎯 أهداف المبيعات</h1><p>إدارة الخطة والتخصيص والاعتماد والترحيل والمتابعة من المحرك المركزي.</p></div><button class="rw-btn" onclick="RW_SalesTargetsMain.render()">تحديث</button></div>';

            h+='<div class="rw-card"><h3>إنشاء / تعديل خطة</h3><div class="rw-form-grid">';
            h+='<input id="st-main-plan-id" type="hidden" value="'+esc(currentPlan&&currentPlan.id||'')+'">';
            h+='<input id="st-main-plan-code" placeholder="كود الخطة" value="'+esc(currentPlan&&currentPlan.plan_code||'')+'" '+((currentPlan&&currentPlan.status!=='Draft')?'disabled':'')+'>';
            h+='<input id="st-main-plan-name" placeholder="اسم الخطة" value="'+esc(currentPlan&&currentPlan.name||'')+'" '+((currentPlan&&currentPlan.status!=='Draft')?'disabled':'')+'>';
            h+='<input id="st-main-plan-start" type="date" value="'+esc(currentPlan&&currentPlan.period_start||'')+'" '+((currentPlan&&currentPlan.status!=='Draft')?'disabled':'')+'>';
            h+='<input id="st-main-plan-end" type="date" value="'+esc(currentPlan&&currentPlan.period_end||'')+'" '+((currentPlan&&currentPlan.status!=='Draft')?'disabled':'')+'>';
            h+='<select id="st-main-plan-metric" '+((currentPlan&&currentPlan.status!=='Draft')?'disabled':'')+'><option value="amount">قيمة</option><option value="qty">كمية</option><option value="gross_profit">مجمل الربح</option><option value="mixed">مختلط</option></select>';
            h+='</div><textarea id="st-main-plan-notes" placeholder="ملاحظات الخطة" '+((currentPlan&&currentPlan.status!=='Draft')?'disabled':'')+'>'+esc(currentPlan&&currentPlan.notes||'')+'</textarea>';
            h+='<div class="rw-actions">';
            if(!currentPlan || currentPlan.status==='Draft') h+='<button class="rw-btn rw-btn-success" onclick="RW_SalesTargetsMain.savePlan()">حفظ الخطة</button>';
            if(currentPlan && (currentPlan.status==='Approved'||currentPlan.status==='Closed')) h+='<button class="rw-btn" onclick="RW_SalesTargetsMain.previewPlan()">معاينة جديدة</button>';
            if(!currentPlan) h+='<button class="rw-btn" onclick="RW_SalesTargetsMain.newPlan()">تفريغ</button>';
            h+='</div></div>';

            h+='<div class="rw-card"><div style="display:flex;justify-content:space-between;align-items:center;gap:12px;flex-wrap:wrap"><div><h3>الخطط</h3><p style="margin:4px 0;color:#6b7280">اختر الخطة لإدارة تفاصيلها وتخصيصاتها.</p></div>';
            if(canManage() && currentPlan && (currentPlan.status==='Approved'||currentPlan.status==='Closed'||currentPlan.status==='Cancelled')) h+='<button class="rw-btn" onclick="RW_SalesTargetsMain.clonePlan()">نسخ الخطة كنسخة جديدة</button>';
            h+='</div><select id="st-main-plan-select" onchange="RW_SalesTargetsMain.selectPlan(this.value)"><option value="">اختر الخطة</option>';
            for(var i=0;i<plans.length;i++) h+='<option value="'+esc(plans[i].id)+'">'+esc(plans[i].plan_code+' — '+plans[i].name+' ['+statusLabel(plans[i].status)+']')+'</option>';
            h+='</select><div class="rw-actions">';
            if(currentPlan && canManage() && currentPlan.status==='Draft') h+='<button class="rw-btn" onclick="RW_SalesTargetsMain.approvePlan()">اعتماد</button><button class="rw-btn rw-btn-danger" onclick="RW_SalesTargetsMain.cancelPlan()">إلغاء Draft</button>';
            if(currentPlan && canApprove() && currentPlan.status==='Approved') h+='<button class="rw-btn" onclick="RW_SalesTargetsMain.closePlan()">إغلاق الخطة</button>';
            if(currentPlan && canApprove() && (currentPlan.status==='Approved'||currentPlan.status==='Closed')) h+='<button class="rw-btn rw-btn-success" onclick="RW_SalesTargetsMain.postRun()">ترحيل النتائج</button>';
            h+='</div></div>';

            h+='<div id="rw-sales-target-dashboard"></div>';
            RW_UI.safeHTML(c,h);

            var metricEl=byId('st-main-plan-metric');
            if(metricEl && currentPlan) metricEl.value=currentPlan.metric||'amount';
            var planSelect=byId('st-main-plan-select');
            if(planSelect && selectedPlanId) planSelect.value=selectedPlanId;

            if(selectedPlanId) await renderDashboard(selectedPlanId);
            subscribeRealtime();
        }catch(e){
            RW_UI.safeHTML(c,'<div class="rw-error">'+esc(e.message)+'</div>');
        }
    }

    return {
        render:render,

        async newPlan(){
            selectedPlanId=null;
            var c=byId('rw-page-container');
            if(c) await render();
            var id=byId('st-main-plan-id'); if(id) id.value='';
            var code=byId('st-main-plan-code'); if(code) code.value='';
            var name=byId('st-main-plan-name'); if(name) name.value='';
            var start=byId('st-main-plan-start'); if(start) start.value='';
            var end=byId('st-main-plan-end'); if(end) end.value='';
            var metric=byId('st-main-plan-metric'); if(metric) metric.value='amount';
            var notes=byId('st-main-plan-notes'); if(notes) notes.value='';
        },

        async selectPlan(id){
            if(!id) return;
            selectedPlanId=id;
            var r=await loadPlans();
            var p=(r.plans||[]).find(function(x){return x.id===id;});
            if(!p) return;
            var idEl=byId('st-main-plan-id'); if(idEl) idEl.value=p.id||'';
            var code=byId('st-main-plan-code'); if(code) code.value=p.plan_code||'';
            var name=byId('st-main-plan-name'); if(name) name.value=p.name||'';
            var start=byId('st-main-plan-start'); if(start) start.value=p.period_start||'';
            var end=byId('st-main-plan-end'); if(end) end.value=p.period_end||'';
            var metric=byId('st-main-plan-metric'); if(metric) metric.value=p.metric||'amount';
            var notes=byId('st-main-plan-notes'); if(notes) notes.value=p.notes||'';
            await renderDashboard(id);
        },

        async savePlan(){
            try{
                if(!canManage()) throw new Error('ليس لديك صلاحية إدارة أهداف المبيعات');
                showLoader('جاري حفظ الخطة...');
                var planId=byId('st-main-plan-id').value||null;
                var j=await op('SAVE_PLAN',planId,{
                    plan_code:byId('st-main-plan-code').value.trim(),
                    name:byId('st-main-plan-name').value.trim(),
                    period_start:byId('st-main-plan-start').value,
                    period_end:byId('st-main-plan-end').value,
                    metric:byId('st-main-plan-metric').value,
                    notes:byId('st-main-plan-notes').value.trim()
                },null);
                if(j.plan&&j.plan.id) selectedPlanId=j.plan.id;
                showToast('تم حفظ الخطة','success');
                await render();
            }catch(e){showToast(e.message,'error');}finally{hideLoader();}
        },

        async previewPlan(){
            try{
                var id=selectedPlanId||byId('st-main-plan-select').value||byId('st-main-plan-id').value;
                if(!id) throw new Error('اختر خطة');
                showLoader('جاري المعاينة...');
                await op('PREVIEW',id,{},null);
                await renderDashboard(id);
                showToast('تمت معاينة الخطة','success');
            }catch(e){showToast(e.message,'error');}finally{hideLoader();}
        },

        async approvePlan(){
            try{
                if(!canManage()) throw new Error('ليس لديك صلاحية اعتماد الخطة');
                var id=selectedPlanId||byId('st-main-plan-select').value;
                if(!id) throw new Error('اختر خطة');
                showLoader('جاري اعتماد الخطة...');
                await op('APPROVE_PLAN',id,{},null);
                await render();
                showToast('تم اعتماد الخطة','success');
            }catch(e){showToast(e.message,'error');}finally{hideLoader();}
        },

        async cancelPlan(){
            try{
                if(!canManage()) throw new Error('ليس لديك صلاحية إلغاء الخطة');
                var id=selectedPlanId||byId('st-main-plan-select').value;
                if(!id) throw new Error('اختر خطة');
                showLoader('جاري إلغاء الخطة...');
                await op('CANCEL_PLAN',id,{},null);
                selectedPlanId=null;
                await render();
                showToast('تم إلغاء الخطة','success');
            }catch(e){showToast(e.message,'error');}finally{hideLoader();}
        },

        async closePlan(){
            try{
                if(!canApprove()) throw new Error('ليس لديك صلاحية إغلاق الخطة');
                var id=selectedPlanId||byId('st-main-plan-select').value;
                if(!id) throw new Error('اختر خطة');
                showLoader('جاري إغلاق الخطة...');
                await op('CLOSE_PLAN',id,{},null);
                await render();
                showToast('تم إغلاق الخطة','success');
            }catch(e){showToast(e.message,'error');}finally{hideLoader();}
        },

        async clonePlan(){
            try{
                if(!canManage()) throw new Error('ليس لديك صلاحية نسخ الخطة');
                var id=selectedPlanId||byId('st-main-plan-select').value;
                if(!id) throw new Error('اختر خطة');
                var r=await loadPlans();
                var p=(r.plans||[]).find(function(x){return x.id===id;});
                if(!p) throw new Error('الخطة غير موجودة');

                var defaultCode=(p.plan_code||'TARGET')+'-V'+(Number(p.version_no||1)+1);
                var result=await Swal.fire({
                    title:'نسخ الخطة',
                    html:'<div dir="rtl" style="text-align:right">'+
                        '<label style="display:block;margin-bottom:6px;font-weight:700">كود النسخة الجديدة</label>'+
                        '<input id="st-clone-code" class="swal2-input" value="'+esc(defaultCode)+'">'+
                        '<label style="display:block;margin:12px 0 6px;font-weight:700">اسم النسخة</label>'+
                        '<input id="st-clone-name" class="swal2-input" value="'+esc((p.name||'')+' — نسخة جديدة')+'">'+
                        '<label style="display:block;margin:12px 0 6px;font-weight:700">بداية الفترة</label>'+
                        '<input id="st-clone-start" type="date" class="swal2-input" value="'+esc(p.period_start||'')+'">'+
                        '<label style="display:block;margin:12px 0 6px;font-weight:700">نهاية الفترة</label>'+
                        '<input id="st-clone-end" type="date" class="swal2-input" value="'+esc(p.period_end||'')+'">'+
                        '</div>',
                    showCancelButton:true,
                    confirmButtonText:'إنشاء النسخة',
                    cancelButtonText:'إلغاء',
                    preConfirm:function(){
                        var code=(document.getElementById('st-clone-code').value||'').trim();
                        var name=(document.getElementById('st-clone-name').value||'').trim();
                        var start=document.getElementById('st-clone-start').value;
                        var end=document.getElementById('st-clone-end').value;
                        if(!code) return Swal.showValidationMessage('كود النسخة مطلوب');
                        if(!start||!end) return Swal.showValidationMessage('الفترة مطلوبة');
                        if(end<start) return Swal.showValidationMessage('نهاية الفترة لا يمكن أن تسبق البداية');
                        return {new_plan_code:code,name:name,period_start:start,period_end:end};
                    }
                });
                if(!result.isConfirmed) return;
                showLoader('جاري إنشاء نسخة الخطة...');
                var j=await op('CLONE_PLAN',id,result.value,null);
                selectedPlanId=j.plan&&j.plan.id?j.plan.id:null;
                await render();
                showToast('تم إنشاء نسخة جديدة مع نسخ التخصيصات','success');
            }catch(e){showToast(e.message,'error');}finally{hideLoader();}
        },

        async openAssignmentEditor(assignmentId){
            try{
                if(!canManage()) throw new Error('ليس لديك صلاحية إدارة تخصيصات الأهداف');
                var planId=selectedPlanId||byId('st-main-plan-select').value;
                if(!planId) throw new Error('اختر خطة Draft');
                var plans=await loadPlans();
                var plan=(plans.plans||[]).find(function(x){return x.id===planId;});
                if(!plan || plan.status!=='Draft') throw new Error('لا يمكن تعديل التخصيص إلا داخل خطة Draft');
                var dash=await call('sales-target-dashboard',{plan_id:planId});
                var assignments=dash.assignments||[];
                var existing=assignmentId?assignments.find(function(x){return x.id===assignmentId;}):null;
                var meta=await loadMeta(false);

                var usersHtml='<option value="">هدف عام</option>';
                for(var i=0;i<meta.users.length;i++){
                    var u=meta.users[i];
                    usersHtml+='<option value="'+esc(u.id)+'" '+(existing&&existing.sales_rep_id===u.id?'selected':'')+'>'+esc((u.name||u.email||'')+(u.role?' — '+u.role:''))+'</option>';
                }
                var branchesHtml='<option value="">كل الفروع</option>';
                for(var b=0;b<meta.branches.length;b++){
                    var br=meta.branches[b];
                    branchesHtml+='<option value="'+esc(br.id)+'" '+(existing&&existing.branch_id===br.id?'selected':'')+'>'+esc((br.branch_code||'')+' — '+(br.name||''))+'</option>';
                }

                var title=existing?'تعديل تخصيص الهدف':'إضافة تخصيص هدف';
                var result=await Swal.fire({
                    title:title,
                    width:'720px',
                    html:'<div dir="rtl" style="text-align:right">'+
                        '<div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">'+
                        '<div><label>المندوب</label><select id="st-as-rep" class="swal2-select" style="width:100%">'+usersHtml+'</select></div>'+
                        '<div><label>الفرع</label><select id="st-as-branch" class="swal2-select" style="width:100%">'+branchesHtml+'</select></div>'+
                        '<div><label>هدف القيمة</label><input id="st-as-amount" class="swal2-input" type="number" min="0" value="'+esc(existing&&existing.target_amount||0)+'"></div>'+
                        '<div><label>هدف الكمية</label><input id="st-as-qty" class="swal2-input" type="number" min="0" value="'+esc(existing&&existing.target_qty||0)+'"></div>'+
                        '<div><label>هدف مجمل الربح</label><input id="st-as-gp" class="swal2-input" type="number" min="0" value="'+esc(existing&&existing.target_gross_profit||0)+'"></div>'+
                        '<div><label>الوزن</label><input id="st-as-weight" class="swal2-input" type="number" min="0.01" value="'+esc(existing&&existing.weight||100)+'"></div>'+
                        '</div>'+\
                        '<label style="display:block;margin-top:12px">ملاحظات</label><textarea id="st-as-notes" class="swal2-textarea">'+esc(existing&&existing.notes||'')+'</textarea>'+\
                        '<label style="display:flex;align-items:center;gap:8px;margin-top:8px"><input id="st-as-active" type="checkbox" '+((!existing||existing.active)?'checked':'')+'> التخصيص نشط</label>'+\
                        '</div>',
                    showCancelButton:true,
                    confirmButtonText:'حفظ التخصيص',
                    cancelButtonText:'إلغاء',
                    preConfirm:function(){
                        var rep=document.getElementById('st-as-rep').value||'';
                        var branch=document.getElementById('st-as-branch').value||'';
                        var amount=Number(document.getElementById('st-as-amount').value||0);
                        var qty=Number(document.getElementById('st-as-qty').value||0);
                        var gp=Number(document.getElementById('st-as-gp').value||0);
                        var weight=Number(document.getElementById('st-as-weight').value||0);
                        if(!rep&&!branch&&amount<=0&&qty<=0&&gp<=0) return Swal.showValidationMessage('حدد مندوبًا أو فرعًا أو أدخل هدفًا موجبًا');
                        if(weight<=0) return Swal.showValidationMessage('الوزن يجب أن يكون أكبر من صفر');
                        return {
                            id:existing?existing.id:null,
                            sales_rep_id:rep||null,
                            branch_id:branch||null,
                            target_amount:amount,
                            target_qty:qty,
                            target_gross_profit:gp,
                            weight:weight,
                            active:document.getElementById('st-as-active').checked,
                            notes:(document.getElementById('st-as-notes').value||'').trim()
                        };
                    }
                });
                if(!result.isConfirmed) return;
                showLoader('جاري حفظ التخصيص...');
                await op('SAVE_ASSIGNMENT',planId,result.value,null);
                await renderDashboard(planId);
                showToast(existing?'تم تعديل التخصيص':'تم إضافة التخصيص','success');
            }catch(e){showToast(e.message,'error');}finally{hideLoader();}
        },

        async setAssignmentActive(assignmentId,active){
            try{
                if(!canManage()) throw new Error('ليس لديك صلاحية إدارة التخصيصات');
                var planId=selectedPlanId||byId('st-main-plan-select').value;
                if(!planId||!assignmentId) throw new Error('بيانات التخصيص غير مكتملة');
                showLoader(active?'جاري تفعيل التخصيص...':'جاري إيقاف التخصيص...');
                await op('SET_ASSIGNMENT_ACTIVE',planId,{assignment_id:assignmentId,active:active},null);
                await renderDashboard(planId);
                showToast(active?'تم تفعيل التخصيص':'تم إيقاف التخصيص','success');
            }catch(e){showToast(e.message,'error');}finally{hideLoader();}
        },

        async postRun(){
            try{
                if(!canApprove()) throw new Error('ليس لديك صلاحية ترحيل النتائج');
                var id=selectedPlanId||byId('st-main-plan-select').value;
                if(!id) throw new Error('اختر خطة');
                if(!postOperationId) postOperationId=uid();
                showLoader('جاري ترحيل النتائج...');
                var j=await op('POST',id,{},postOperationId);
                postOperationId=null;
                await renderDashboard(id);
                showToast(j.duplicate?'تم منع التكرار وإعادة نفس النتيجة':'تم الترحيل بنجاح','success');
            }catch(e){showToast(e.message,'error');}finally{hideLoader();}
        },

        async approveRun(runId){
            try{
                if(!canApprove()) throw new Error('ليس لديك صلاحية اعتماد العملية');
                showLoader('جاري اعتماد العملية...');
                await op('APPROVE_RUN',runId,{},null);
                if(selectedPlanId) await renderDashboard(selectedPlanId);
                showToast('تم اعتماد العملية','success');
            }catch(e){showToast(e.message,'error');}finally{hideLoader();}
        },

        async reverseRun(runId){
            try{
                if(!canApprove()) throw new Error('ليس لديك صلاحية عكس العملية');
                if(!reverseOperationIds[runId]) reverseOperationIds[runId]=uid();
                showLoader('جاري عكس العملية...');
                var j=await op('REVERSE_RUN',runId,{},reverseOperationIds[runId]);
                delete reverseOperationIds[runId];
                if(selectedPlanId) await renderDashboard(selectedPlanId);
                showToast(j.duplicate?'تم منع التكرار وإعادة نفس نتيجة العكس':'تم عكس العملية','success');
            }catch(e){showToast(e.message,'error');}finally{hideLoader();}
        }
    };
})();
```

---

# 10. ماذا يضيف الاستبدال فعليًا

هذا ليس تجميلًا بصريًا فقط.

بعد الاستبدال تصبح Mother UI متصلة بكل العقود الموجودة بالفعل في الـengine:

### Plan Management

- Create
- Draft Edit
- Approve
- Cancel
- Close
- Clone / Version

### Assignment Management

- Add
- Edit
- Activate
- Deactivate
- Representative scope
- Branch scope
- Global target
- Amount target
- Quantity target
- Gross profit target
- Weight
- Notes

### Performance

- Target value
- Actual value
- Target quantity
- Actual quantity
- Target GP
- Actual GP
- Achievement percentage
- Ranking
- Daily trend

### Operational lifecycle

- Preview
- Post
- Approve Run
- Reverse Run
- Idempotent POST retry
- Idempotent Reverse retry

### Security behavior

الواجهة نفسها تحترم:

```text
*
sales_manager
sales_supervisor
general_manager
reports
```

مع الحفاظ على semantics الخاصة بـOWNER / wildcard وعدم تحويل wildcard إلى قائمة صلاحيات صريحة.

### Realtime

الواجهة تستمع إلى:

```text
sales_target_plans
sales_target_assignments
sales_target_runs
sales_target_run_lines
```

مع إعادة تحميل/تحديث dashboard عند تغير البيانات.

---

# 11. لماذا لم يتم تعديل Production في هذه الجلسة

لأن التحقيق الحالي أثبت أن Production تحتوي على البنية الخلفية المطلوبة بالفعل:

- Engine
- Gateway
- Dashboard
- Assignment lifecycle
- Versioned cloning
- Authorization
- Tenant checks
- Realtime publication

إنشاء جداول أو Edge Functions جديدة هنا سيكون **Debt جديدًا بلا دليل**.

تم اعتماد مبدأ:

```text
USE EXISTING CONTRACT
        ↓
COMPLETE MOTHER CONSUMER
        ↓
E2E VERIFY
```

بدل:

```text
ADD NEW BACKEND
        ↓
DUPLICATE BUSINESS LOGIC
```

---

# 12. أخطاء أو اكتشافات هذه الجلسة

## الخطأ/الاكتشاف الأول

التقارير السابقة كانت تعتبر وجود Plan + Dashboard كافيًا، بينما القراءة الحالية أثبتت أن الـAssignment lifecycle لم يكن exposed في Mother UI.

النتيجة:

`BACKEND EXISTS ≠ FUNCTIONAL MODULE COMPLETE`

## الاكتشاف الثاني

المشكلة القديمة `RW_UI is not defined` تم إغلاقها بالفعل في أحدث Commit `70cc...`، ولذلك تم رفض إعادة تطبيق نفس الإصلاح.

## الاكتشاف الثالث

الـBackend الحالي بالفعل أكثر تقدمًا من Mother UI.

وبالتالي أفضل إصلاح هو إكمال Consumer الحالي، وليس إعادة بناء Engine.

---

# 13. ما لم يتم ادعاؤه

لم يتم الادعاء بأن:

```text
SAVE
→ ASSIGN
→ APPROVE
→ PREVIEW
→ POST
→ APPROVE_RUN
→ REVERSE_RUN
```

تمت تجربتها Business E2E على بيانات Target تشغيلية حقيقية في Production، لأن Production الحالية لا تحتوي على Target business data.

كما لم يتم إنشاء بيانات Target اصطناعية دائمة فقط للحصول على PASS شكلي.

---

# 14. اختبار E2E المطلوب بعد Owner Surgery

بعد تطبيق الاستبدال في Mother file ونشر `erp-frontend/main.html`، يكون الاختبار الإلزامي بالترتيب التالي:

```text
Login
↓
إدارة المبيعات
↓
أهداف المبيعات
↓
فتح التبويب
↓
Console = No ReferenceError
↓
Network = sales-target-engine 200
↓
Network = sales-target-dashboard 200
↓
Create Draft Plan
↓
Add Assignment
↓
Edit Assignment
↓
Disable Assignment
↓
Re-enable Assignment
↓
Approve Plan
↓
Clone Plan
↓
Open Clone
↓
Preview
↓
Post
↓
Retry Post with same operation_id
↓
duplicate=true
↓
Approve Run
↓
Reverse Run
↓
Realtime refresh
```

عند توفر بيانات حقيقية، يجب أيضًا التحقق من الأرقام نفسها وليس فقط HTTP 200.

---

# 15. PASS / FAIL Matrix

| الاختبار | الحالة الحالية |
|---|---|
| Current Git verified | PASS |
| Latest commit verified | PASS |
| Parent verified | PASS |
| Current mother source verified | PASS |
| EOF verified | PASS |
| RW_UI old root cause | CLOSED |
| Sales Targets dispatcher | PASS |
| Backend engine | VERIFIED |
| Backend assignment lifecycle | VERIFIED |
| Backend clone/versioning | VERIFIED |
| Dashboard Edge | VERIFIED |
| Realtime DB contract | VERIFIED |
| Mother Assignment UI | **OPEN → SURGICAL REPLACEMENT PREPARED** |
| Mother Clone UI | **OPEN → SURGICAL REPLACEMENT PREPARED** |
| Mother lifecycle UX | **OPEN → SURGICAL REPLACEMENT PREPARED** |
| Live Browser E2E | **OPEN** |
| Current Console after surgery | **OPEN** |
| Current Network after surgery | **OPEN** |
| Realtime browser runtime | **OPEN** |
| System-level Sales Targets | **OPEN** |

---

# 16. FINAL CTO CONCLUSION

المهمة لم تكن Backend missing.

المهمة كانت:

**Mother UI غير مكتملة وظيفيًا رغم أن Backend Engine متقدم بالفعل.**

لذلك تم إعداد إصلاح جراحي واحد في Consumer نفسه بدل إضافة دين جديد.

الحالة الصحيحة الآن:

```text
SALES TARGET BACKEND                 = VERIFIED
SALES TARGET DATABASE CONTRACT       = VERIFIED
SALES TARGET EDGE                    = VERIFIED
SALES TARGET TENANT/AUTHORIZATION    = VERIFIED
SALES TARGET VERSIONING              = VERIFIED
MOTHER RW_UI ROOT CAUSE              = CLOSED
MOTHER SALES TARGET CORE UI          = PRESENT
MOTHER ASSIGNMENT MANAGEMENT         = REQUIRES OWNER SURGERY
MOTHER CLONE MANAGEMENT              = REQUIRES OWNER SURGERY
MOTHER FULL FUNCTIONAL UX             = REQUIRES OWNER SURGERY
LIVE BROWSER E2E                      = OPEN
```

**لا يجوز رفع الحالة إلى 100% CLOSED قبل نشر Owner Surgery ثم مشاهدة Browser E2E فعليًا.**

---

# 17. تعليمات للمساعد التالي — يجب قراءتها قبل أي إجراء

ابدأ دائمًا بهذا التسلسل:

```text
1. CURRENT PRODUCTION snapshot
2. CURRENT GIT HEAD
3. DIRECT PARENT
4. CURRENT Mother blob
5. EOF
6. Current source anchors
7. Current Production DB routines
8. Current Edge deployments
9. Current browser evidence
10. Only then compare historical reports
11. Treat reports as context, never as current state
12. Do not rebuild from the 11 historical fragments
13. Do not repeat a fix already proven present in HEAD
14. Inspect the exact current Consumer before changing Backend
15. Close one functional gap at a time
16. Verify the real user journey
17. Reconcile Production immediately before final closure
```

وعند العودة إلى Sales Targets تحديدًا:

```text
Read current main.html
↓
Find RW_SalesTargetsMain
↓
Confirm current anchors
↓
Confirm latest commit/parent
↓
Confirm backend operations
↓
Confirm current Production row state
↓
Confirm Owner Surgery was actually applied
↓
Browser E2E
↓
Console
↓
Network
↓
Realtime
↓
Production reconciliation
↓
Only then close
```

ولا يجوز أن يبدأ المساعد بإصلاح:

- `RW_UI`
- `rw-page-container`
- `selectPlan`
- dispatcher

مرة أخرى، لأن هذه النقاط ثبت وجودها في CURRENT HEAD.

كما لا يجوز إنشاء Engine بديل أو جدول بديل لمجرد اكتمال شكلي.

---

# 18. Next exact closure unit

بعد Owner Surgery:

**MOTHER SALES TARGETS LIVE E2E CLOSURE**

والأولوية الأولى:

```text
فتح التبويب
→ إنشاء Draft Plan
→ Assignment CRUD
→ Approve
→ Clone
→ Preview
→ Post + duplicate retry
→ Approve Run
→ Reverse
→ Realtime
→ Console clean
→ Network clean
→ Production reconcile
```

بعدها فقط يتم الانتقال إلى Functional Completion للـCRM/Finance/HR/Reports.
