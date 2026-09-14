# تقرير 178 — Sales Targets — Current Forensic Closure + Owner Surgery

**التاريخ:** 14 سبتمبر 2026

## 0. النقطة الأهم — الهدف الحقيقي في هذه الدورة

الهدف لم يكن إثبات أن Backend الخاص بـSales Targets موجود فقط.

الهدف الحقيقي هو الوصول إلى **System-Level Sales Targets** بحيث يعمل محرك الأهداف من:

1. النظام الأم الحالي:
   `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`
2. تطبيق مدير المبيعات:
   `papamohammed77-glitch/erp-frontend/companies/company-1/sales/manager.html`
3. Production Supabase الحالية.
4. Realtime/Audit.
5. ثم Browser E2E كامل.

ملف `main.html` هو Source of Truth للنظام الأم.

لا يوجد في هذه الجلسة أي اعتماد على تقارير سابقة باعتبارها الحالة الحالية. التقارير استخدمت فقط كمرجع تاريخي ومؤشر بحث.

---

# 1. قاعدة الحقيقة التي تم تطبيقها

الحالة المعتمدة:

`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

ولإغلاق الـE2E النهائي يلزم أيضًا:

`CURRENT BROWSER / CONSOLE / NETWORK`

ولا يجوز تحويل Production PASS إلى Browser PASS.

---

# 2. CURRENT GIT — FRONTEND

## HEAD الحالي

Repository:
`papamohammed77-glitch/erp-frontend`

HEAD:
`b6e48193f4042ed6625721aa484c53f6de8cb081`

Message:
`Update manager.html`

هذا هو أحدث commit الذي تم إثباته مباشرة في هذه الجلسة، وهو تعديل على `sales/manager.html`.

## Direct Parent

`3398d0952ea723d1de42b076ad93ae19c025bfa3`

Message:
`Fix forensic master source-of-truth path`

وقد تم فتح الـparent نفسه مباشرة، وثبت أنه يضيف فقط:

```yaml
repository: papamohammed77-glitch/erp-frontend
path: companies/company-1/main.html
ref: main
mode: published_main_is_authoritative
fragment_mode: historical_reference_only
```

ولا يغيّر `main.html`.

## Current main.html blob

`66c7c9bb2c8dba4a521647c680e2cb6605b28e0d`

الحجم المثبت:
`1,087,515 bytes`

## forensic_main_assembly.yml

الحالة الحالية صحيحة ولا تحتاج تعديلًا إضافيًا:

```yaml
repository: papamohammed77-glitch/erp-frontend
path: companies/company-1/main.html
ref: main
mode: published_main_is_authoritative
fragment_mode: historical_reference_only
```

لا توجد أي مبررات لإعادة توجيه reconstruction إلى `Current/PWA/main2/*`.

---

# 3. CURRENT main.html — نتيجة التحقيق

تم فتح Blob الحالي مباشرة والتأكد من أنه يحتوي على النظام الأم الحالي.

لكن بسبب حجم الملف، GitHub connector لا يعيد الـbody كاملًا حتى EOF في جلسة الأدوات الحالية. تم أيضًا اختبار Raw/clone ولم يكن النقل المباشر متاحًا من runtime.

لذلك:

`FULL MAIN.HTML LINE-BY-LINE EOF READ = NOT PROVEN`

وبناءً على مبدأ الحوكمة:

`UNKNOWN / UNVERIFIED ≠ PATCH`

لم يتم اختلاق رقم سطر أو إعطاء رقم غير مثبت.

لكن تم البحث داخل الـbody الحالي القابل للفحص، وثبت أن `RW_Navigation.menuTree` الخاص بإدارة المبيعات يحتوي على:

`التلي سيلز → العملاء → المتجر الإلكتروني → نقطة البيع → أوردرات المبيعات → عروض الأسعار → قوائم الأسعار → العروض والخصومات → الرانشيتات → إدارة مرتجعات المبيعات`

ولا يوجد ضمن هذا المسار الحالي `sales-targets`.

كما تم البحث عن:

`renderTargets`

و:

`sales_target`

داخل الـmaster الحالي، ولم يثبت وجود Target module فعال داخل النظام الأم.

وبالتالي:

`MASTER SALES TARGET UI = OPEN`

وهذا يختلف جوهريًا عن وجود Target UI في `sales/manager.html`.

---

# 4. CURRENT sales/manager.html

HEAD الحالي يحتوي على Target UI متكامل جزئيًا.

في الـcommit الأخير تم استبدال Target view القديم الذي كان يحسب هدفًا ثابتًا `50000` من القراءة المباشرة للأوردرات، إلى واجهة متصلة بـ:

- `sales-target-engine`
- `sales-target-dashboard`

كما ظهر في الـcurrent source:

- `SAVE_PLAN`
- `SAVE_ASSIGNMENT`
- `APPROVE_PLAN`
- `CANCEL_PLAN`
- `CLOSE_PLAN`
- `POST`
- Dashboard summary
- assignment table
- ranking
- runs table

وهذا اتجاه صحيح معماريًا.

لكن عند المقارنة مع Production contract الحالي ظهرت العيوب التالية:

### DEFECT-1 — Plan selection state

الـselect الحالي يستدعي:

`RW_SalesTargets.load()`

من `onchange` ويعيد بناء الشاشة، مع احتمال فقدان اختيار المستخدم والعودة إلى أول خطة.

### DEFECT-2 — Run ID / Plan ID confusion

في `runAction` الحالي:

```javascript
var id=RW_UI.byId('st-plan-select').value;
```

ثم في الفرع غير `POST`:

```javascript
var runId=id;
```

أي أن `APPROVE_RUN` و`REVERSE_RUN` يمكن أن يرسلا **Plan ID** بدل **Run ID**.

وهذا غير صحيح لأن Production engine في هاتين العمليتين يعامل المعامل كـRun ID.

### DEFECT-3 — POST operation identity

الـPOST الحالي يولد:

```javascript
var operationId=uid();
```

لكل ضغطة.

هذا لا يحافظ على نفس الـoperation identity إذا حدث timeout بعد نجاح العملية وقبل وصول response.

الـcorrect pattern هو الاحتفاظ بنفس `operation_id` حتى يتم تأكيد نجاح العملية، ثم فقط تصفيره.

### DEFECT-4 — الإدارة ليست مكتملة

الـUI الحالي لا يقدم دورة إدارة كاملة ومرتبة لـ:

- Edit Plan
- Edit Assignment
- Enable/Disable Assignment
- Preview واضح
- اختيار Run مستقل
- Approve Run
- Reverse Run

### DEFECT-5 — Realtime

Production target tables موجودة بالفعل في `supabase_realtime`، لكن الـUI الحالي لا يفتح اشتراكًا عليها لتحديث Dashboard تلقائيًا.

### DEFECT-6 — `sales-target-dashboard` endpoint

المتغير `endpoint` موجود ويظهر أنه مخصص للـdashboard، لكن التصميم الحالي يحتاج إدارة state أفضل حتى يصبح اختيار الخطة والـdashboard والـruns متماسكًا ولا يعاد البناء بشكل يغير السياق.

---

# 5. CURRENT PRODUCTION — DATABASE

Production Supabase:

`fiilmooggumokxanwiyx`

الحالة:
`ACTIVE_HEALTHY`

## Target tables الحالية

- `sales_target_plans`
- `sales_target_assignments`
- `sales_target_runs`
- `sales_target_run_lines`

## العلاقات الحالية المثبتة

`plans.company_id → companies.id`

`assignments.plan_id → plans.id`

`assignments.sales_rep_id → users.id`

`assignments.branch_id → branches.id`

`runs.plan_id → plans.id`

`runs.reversal_of_run_id → runs.id`

`run_lines.run_id → runs.id`

`run_lines.assignment_id → assignments.id`

وجميعها تحمل `company_id` وتخضع لـRLS/Integrity Guards.

## القيود المهمة

`sales_target_plans(company_id, plan_code)` UNIQUE

`sales_target_assignments(plan_id, sales_rep_id, branch_id)` UNIQUE

`sales_target_runs(company_id, operation_id)` UNIQUE

`sales_target_run_lines(run_id, assignment_id)` UNIQUE

كما توجد CHECK constraints تمنع:

- فترة خطة غير صحيحة.
- target سالب.
- weight غير صالح.
- Metric غير معروف.

---

# 6. CURRENT PRODUCTION — ENGINE

المحرك الحالي:

`public.sales_target_engine_atomic(uuid,text,text,uuid,jsonb,text)`

والعمليات المثبتة:

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

محرك الحساب يعتمد على:

`orders + order_details + items`

مع:

`order_status = 'Invoiced'`

والكمية الصافية:

`qty - qty_returned`

ومجمل الربح:

`(unit_price - cost_price) × net_qty`

لم يتم تغيير هذه القاعدة لأنها Business Contract قائم وليست افتراضًا جديدًا.

---

# 7. CURRENT PRODUCTION — SECURITY GATEWAY

تم تنفيذ إصلاح حقيقي في Production بدل الاكتفاء بالمراجعة.

أُنشئت الدالة:

`public.sales_target_engine_gateway(uuid,text,text,uuid,jsonb,text)`

وهي Security Definer ومقفلة على:

`service_role`

وتفرض الفصل بين:

### Read

- `LIST_PLANS`
- `LIST_ASSIGNMENTS`
- `LIST_RUNS`
- `PREVIEW`

### Management

- `SAVE_PLAN`
- `SAVE_ASSIGNMENT`
- `CANCEL_PLAN`

### Approval

- `APPROVE_PLAN`
- `CLOSE_PLAN`
- `POST`
- `APPROVE_RUN`
- `REVERSE_RUN`

وتتحقق من:

`company_id + authenticated user email + active user + permissions`

ثم تمرر العملية إلى:

`sales_target_engine_atomic`

وهذا يحافظ على المحرك الأصلي ويضع ACL boundary أعلى منه بدل تعديل Business Logic بلا داعٍ.

---

# 8. CURRENT DEPLOYMENT — EDGE

تم تحديث `sales-target-engine` في Production إلى:

`ACTIVE v2`

مع:

`verify_jwt = true`

وأصبح المسار:

```text
JWT
↓
auth.getUser()
↓
users.auth_id
↓
company_id
↓
sales_target_engine_gateway
↓
sales_target_engine_atomic
```

وتم تحديث المصدر canonical في:

`Current/Edge_Functions/sales-target-engine/index.ts`

ليستدعي الـGateway بدل استدعاء الـCore مباشرة.

`sales-target-dashboard` بقي:

`ACTIVE v1`

`verify_jwt=true`

لأن مساره الحالي يفرض read permission داخل الـRPC نفسه ولم تظهر حاجة مثبتة لتغيير الـBusiness Contract.

---

# 9. CURRENT REALTIME

تم التحقق مباشرة أن الجداول الأربعة كلها أعضاء في publication:

`supabase_realtime`

وهي:

- `sales_target_plans`
- `sales_target_assignments`
- `sales_target_runs`
- `sales_target_run_lines`

إذن البنية التحتية للـRealtime موجودة بالفعل.

النقص الآن في **Frontend subscription**, لا في قاعدة البيانات.

---

# 10. PRODUCTION E2E — إعادة التحقق

تم تشغيل Transactional E2E على Production مع Rollback نهائي:

```text
SAVE_PLAN
→ SAVE_ASSIGNMENT
→ APPROVE_PLAN
→ PREVIEW
→ POST
→ same POST with same operation_id
→ APPROVE_RUN
→ REVERSE_RUN
→ ROLLBACK
```

النتيجة:

`SALES_TARGET_FULL_LIFECYCLE_E2E_PASS`

كما تم اختبار الـACL Gateway:

- Sales Manager يستطيع القراءة.
- Cashier لا يستطيع `SAVE_PLAN`.

النتيجة:

`SALES_TARGET_GATEWAY_ACL_E2E_PASS`

## بعد Rollback

Production الحالية تُظهر:

- plans = `0`
- assignments = `0`
- runs = `0`
- run_lines = `0`

وهذا يمنع أي test residue.

---

# 11. CURRENT PRODUCTION FINAL SNAPSHOT

**وقت snapshot:**

`2026-09-14 04:22:03.435613+00`

الحالة الخاصة بالهدف:

| العنصر | Production الحالية |
|---|---:|
| sales_target_plans | 0 |
| sales_target_assignments | 0 |
| sales_target_runs | 0 |
| sales_target_run_lines | 0 |
| audit_log | 1955 |

هذه هي الحالة التي يجب استخدامها عند قراءة هذا التقرير، وليس أي snapshot سابق.

---

# 12. CURRENT GIT CANONICAL UPDATE

تم تحديث المصدر canonical في repo `rawaie-erp-New`:

### Edge source

`Current/Edge_Functions/sales-target-engine/index.ts`

وأصبح يستدعي الـGateway.

### Migration source

أُنشئ:

`supabase/migrations/20260914071100_sales_target_secure_gateway_acl.sql`

ليجعل Production change reproducible من Git.

---

# 13. OWNER SURGERY — main.html

**لم يتم تعديل `main.html` من طرف المساعد.**

السبب ليس ترددًا؛ السبب هو عدم ثبوت قراءة الملف كاملًا حتى EOF من الأدوات المتاحة.

لكن تم تثبيت مواضع الجراحة بالـcurrent source search بما يكفي لتحديد العناصر الحالية، وستُنفذ الجراحة عند توفر الجسم الكامل للملف.

## تعديل 1 — Navigation

### ابحث عن العنصر الكامل التالي داخل:

`const RW_Navigation = {`

وفي:

`menuTree → إدارة المبيعات → submenu`

ابحث عن النص الكامل:

```javascript
{ icon: 'fa-chart-line', label: 'إدارة المبيعات', submenu: [{ view: 'telesales', label: 'التلي سيلز' }, { view: 'customers', label: 'العملاء' }, { view: 'online-store', label: 'المتجر الإلكتروني' }, { view: 'pos', label: 'نقطة البيع' }, { view: 'orders', label: 'أوردرات المبيعات' }, { view: 'quotes', label: 'عروض الأسعار' },{ view: 'price-lists', label: 'قوائم الأسعار' },{ view: 'promotions', label: 'العروض والخصومات' }, { view: 'runsheets', label: 'الرانشيتات' }, { view: 'sales-returns', label: 'إدارة مرتجعات المبيعات' }] },
```

استبدله بالعنصر الكامل التالي:

```javascript
{ icon: 'fa-chart-line', label: 'إدارة المبيعات', submenu: [{ view: 'telesales', label: 'التلي سيلز' }, { view: 'customers', label: 'العملاء' }, { view: 'online-store', label: 'المتجر الإلكتروني' }, { view: 'pos', label: 'نقطة البيع' }, { view: 'orders', label: 'أوردرات المبيعات' }, { view: 'quotes', label: 'عروض الأسعار' },{ view: 'price-lists', label: 'قوائم الأسعار' },{ view: 'promotions', label: 'العروض والخصومات' }, { view: 'sales-targets', label: 'أهداف المبيعات', perm: ['sales_manager','sales_supervisor','general_manager','reports'] }, { view: 'runsheets', label: 'الرانشيتات' }, { view: 'sales-returns', label: 'إدارة مرتجعات المبيعات' }] },
```

### مهم
لا تنشئ نسخة ثانية من `menuTree`.

---

# 14. OWNER SURGERY — Navigation dispatch

### ابحث عن السطر الكامل الحالي:

```javascript
if (view === 'sales-returns') { RW_SalesReturnsManagement.render(); return; }
```

ويظهر ضمن سلسلة dispatch الحالية بعد:

```javascript
if (view === 'return') { RW_Warehouse.loadReturn(); return; }
```

استبدل هذا الجزء فقط إلى:

```javascript
if (view === 'return') { RW_Warehouse.loadReturn(); return; }
if (view === 'sales-returns') { RW_SalesReturnsManagement.render(); return; }
if (view === 'sales-targets') { RW_SalesTargetsMain.render(); return; }
```

ولا تحذف `sales-returns`.

---

# 15. OWNER SURGERY — Main Target Controller

### ابحث عن السطر الكامل:

```javascript
function _rwCompanyId() {
```

### أضف فوقه مباشرة العنصر الكامل التالي:

```javascript
var RW_SalesTargetsMain = (function(){
    var realtimeChannel = null;
    var postOperationId = null;

    function endpoint(name){ return RW_SUPABASE_URL + '/functions/v1/' + name; }
    function esc(v){
        return String(v==null?'':v).replace(/[&<>\"']/g,function(c){
            return {'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;',"'":'&#39;'}[c];
        });
    }
    function num(v){ return (Number(v)||0).toLocaleString('ar-EG',{maximumFractionDigits:2}); }
    function uid(){ return window.crypto&&crypto.randomUUID ? crypto.randomUUID() : String(Date.now())+'-'+Math.random(); }

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

    async function renderDashboard(planId){
        var box=byId('rw-sales-target-dashboard');
        if(!box || !planId) return;
        try{
            var j=await call('sales-target-dashboard',{plan_id:planId});
            var t=j.totals||{}, a=j.assignments||[], r=j.ranking||[], runsResult=await op('LIST_RUNS',null,{},null);
            var runs=(runsResult.runs||[]).filter(function(x){return x.plan_id===planId;});
            var h='<div class="rw-kpi-grid">';
            h+='<div class="rw-kpi-card"><div class="rw-kpi-card-top"><span>هدف القيمة</span></div><div class="rw-kpi-value">'+num(t.target_amount)+' ج.م</div></div>';
            h+='<div class="rw-kpi-card"><div class="rw-kpi-card-top"><span>المحقق</span></div><div class="rw-kpi-value">'+num(t.actual_amount)+' ج.م</div></div>';
            h+='<div class="rw-kpi-card"><div class="rw-kpi-card-top"><span>إنجاز القيمة</span></div><div class="rw-kpi-value">'+num(t.amount_pct)+'%</div></div>';
            h+='<div class="rw-kpi-card"><div class="rw-kpi-card-top"><span>إنجاز الكمية</span></div><div class="rw-kpi-value">'+num(t.qty_pct)+'%</div></div>';
            h+='</div>';
            h+='<div class="rw-card"><h3>أداء التخصيصات</h3><div style="overflow:auto"><table class="rw-table"><thead><tr><th>المندوب</th><th>الفرع</th><th>هدف القيمة</th><th>المحقق</th><th>الإنجاز</th></tr></thead><tbody>';
            for(var i=0;i<a.length;i++){
                var z=a[i];
                h+='<tr><td>'+esc(z.sales_rep_name||'عام')+'</td><td>'+esc(z.branch_name||'كل الفروع')+'</td><td>'+num(z.target_amount)+'</td><td>'+num(z.actual_amount)+'</td><td>'+num(z.achievement_pct)+'%</td></tr>';
            }
            if(!a.length) h+='<tr><td colspan="5">لا توجد تخصيصات</td></tr>';
            h+='</tbody></table></div></div>';
            h+='<div class="rw-card"><h3>ترتيب المندوبين</h3>';
            for(var k=0;k<r.length;k++) h+='<div style="display:flex;justify-content:space-between;border-bottom:1px solid #eee;padding:10px 0"><b>'+esc(r[k].rep_name||'غير محدد')+'</b><span>'+num(r[k].actual_amount)+' ج.م</span></div>';
            if(!r.length) h+='<div>لا توجد نتائج</div>';
            h+='</div>';
            h+='<div class="rw-card"><h3>عمليات الترحيل</h3><div style="overflow:auto"><table class="rw-table"><thead><tr><th>التاريخ</th><th>الحالة</th><th>القيمة</th><th>الكمية</th><th>الإجراء</th></tr></thead><tbody>';
            for(var n=0;n<runs.length;n++){
                var run=runs[n];
                h+='<tr><td>'+esc(run.evaluated_at||run.created_at||'')+'</td><td>'+esc(run.status||'')+'</td><td>'+num(run.total_actual_amount)+'</td><td>'+num(run.total_actual_qty)+'</td><td>'+
                '<button class="rw-btn" onclick="RW_SalesTargetsMain.approveRun(\''+esc(run.id)+'\')">اعتماد</button> '+
                '<button class="rw-btn rw-btn-danger" onclick="RW_SalesTargetsMain.reverseRun(\''+esc(run.id)+'\')">عكس</button></td></tr>';
            }
            if(!runs.length) h+='<tr><td colspan="5">لا توجد عمليات ترحيل</td></tr>';
            h+='</tbody></table></div></div>';
            RW_UI.safeHTML(box,h);
        }catch(e){ RW_UI.safeHTML(box,'<div class="rw-error">'+esc(e.message)+'</div>'); }
    }

    async function render(){
        if(realtimeChannel){ try{supabase.removeChannel(realtimeChannel);}catch(e){} realtimeChannel=null; }
        var c=byId('rw-page-content');
        if(!c) return;
        RW_UI.safeHTML(c,'<div class="rw-card"><div class="rw-loading">جاري تحميل محرك أهداف المبيعات...</div></div>');
        try{
            var r=await loadPlans(), plans=r.plans||[];
            var h='<div class="rw-page-header"><div><h1>🎯 أهداف المبيعات</h1><p>إدارة الخطة والتخصيص والاعتماد والترحيل والمتابعة من المحرك المركزي.</p></div><button class="rw-btn" onclick="RW_SalesTargetsMain.render()">تحديث</button></div>';
            h+='<div class="rw-card"><h3>إنشاء / تعديل خطة</h3><div class="rw-form-grid">';
            h+='<input id="st-main-plan-id" type="hidden">';
            h+='<input id="st-main-plan-code" placeholder="كود الخطة">';
            h+='<input id="st-main-plan-name" placeholder="اسم الخطة">';
            h+='<input id="st-main-plan-start" type="date">';
            h+='<input id="st-main-plan-end" type="date">';
            h+='<select id="st-main-plan-metric"><option value="amount">قيمة</option><option value="qty">كمية</option><option value="gross_profit">مجمل الربح</option><option value="mixed">مختلط</option></select>';
            h+='</div><textarea id="st-main-plan-notes" placeholder="ملاحظات الخطة"></textarea>';
            h+='<div class="rw-actions"><button class="rw-btn" onclick="RW_SalesTargetsMain.savePlan()">حفظ الخطة</button><button class="rw-btn" onclick="RW_SalesTargetsMain.previewPlan()">معاينة</button></div></div>';
            h+='<div class="rw-card"><h3>الخطط</h3><select id="st-main-plan-select" onchange="RW_SalesTargetsMain.selectPlan(this.value)"><option value="">اختر الخطة</option>';
            for(var i=0;i<plans.length;i++) h+='<option value="'+esc(plans[i].id)+'">'+esc(plans[i].plan_code+' — '+plans[i].name+' ['+plans[i].status+']')+'</option>';
            h+='</select><div class="rw-actions"><button class="rw-btn" onclick="RW_SalesTargetsMain.approvePlan()">اعتماد</button><button class="rw-btn rw-btn-danger" onclick="RW_SalesTargetsMain.cancelPlan()">إلغاء Draft</button><button class="rw-btn" onclick="RW_SalesTargetsMain.closePlan()">إغلاق</button><button class="rw-btn rw-btn-success" onclick="RW_SalesTargetsMain.postRun()">ترحيل النتائج</button></div></div>';
            h+='<div id="rw-sales-target-dashboard"></div>';
            RW_UI.safeHTML(c,h);
            if(plans.length) await this.selectPlan(plans[0].id);
            var companyId=_rwCompanyId();
            if(companyId){
                realtimeChannel=supabase.channel('rw-sales-target-main-'+companyId)
                  .on('postgres_changes',{event:'*',schema:'public',table:'sales_target_plans',filter:'company_id=eq.'+companyId},function(){render();})
                  .on('postgres_changes',{event:'*',schema:'public',table:'sales_target_assignments',filter:'company_id=eq.'+companyId},function(){render();})
                  .on('postgres_changes',{event:'*',schema:'public',table:'sales_target_runs',filter:'company_id=eq.'+companyId},function(){var id=byId('st-main-plan-select');if(id&&id.value)renderDashboard(id.value);})
                  .on('postgres_changes',{event:'*',schema:'public',table:'sales_target_run_lines',filter:'company_id=eq.'+companyId},function(){var id=byId('st-main-plan-select');if(id&&id.value)renderDashboard(id.value);})
                  .subscribe();
            }
        }catch(e){ RW_UI.safeHTML(c,'<div class="rw-error">'+esc(e.message)+'</div>'); }
    }

    return {
        render:render,
        async selectPlan(id){
            if(!id) return;
            var r=await loadPlans(), p=(r.plans||[]).find(function(x){return x.id===id;});
            if(!p) return;
            byId('st-main-plan-id').value=p.id||'';
            byId('st-main-plan-code').value=p.plan_code||'';
            byId('st-main-plan-name').value=p.name||'';
            byId('st-main-plan-start').value=p.period_start||'';
            byId('st-main-plan-end').value=p.period_end||'';
            byId('st-main-plan-metric').value=p.metric||'amount';
            byId('st-main-plan-notes').value=p.notes||'';
            await renderDashboard(id);
        },
        async savePlan(){
            try{
                showLoader('جاري حفظ الخطة...');
                await op('SAVE_PLAN',byId('st-main-plan-id').value||null,{plan_code:byId('st-main-plan-code').value.trim(),name:byId('st-main-plan-name').value.trim(),period_start:byId('st-main-plan-start').value,period_end:byId('st-main-plan-end').value,metric:byId('st-main-plan-metric').value,notes:byId('st-main-plan-notes').value.trim()},null);
                showToast('تم حفظ الخطة','success');
                await render();
            }catch(e){showToast(e.message,'error');}finally{hideLoader();}
        },
        async previewPlan(){
            try{
                var id=byId('st-main-plan-select').value||byId('st-main-plan-id').value;
                if(!id) throw new Error('اختر خطة');
                showLoader('جاري المعاينة...');
                var j=await op('PREVIEW',id,{},null);
                showToast('تمت معاينة الخطة: '+(j.status||'Preview'),'success');
            }catch(e){showToast(e.message,'error');}finally{hideLoader();}
        },
        async approvePlan(){
            try{var id=byId('st-main-plan-select').value;if(!id)throw new Error('اختر خطة');showLoader('جاري اعتماد الخطة...');await op('APPROVE_PLAN',id,{},null);await render();showToast('تم اعتماد الخطة','success');}catch(e){showToast(e.message,'error');}finally{hideLoader();}
        },
        async cancelPlan(){
            try{var id=byId('st-main-plan-select').value;if(!id)throw new Error('اختر خطة');showLoader('جاري إلغاء الخطة...');await op('CANCEL_PLAN',id,{},null);await render();showToast('تم إلغاء الخطة','success');}catch(e){showToast(e.message,'error');}finally{hideLoader();}
        },
        async closePlan(){
            try{var id=byId('st-main-plan-select').value;if(!id)throw new Error('اختر خطة');showLoader('جاري إغلاق الخطة...');await op('CLOSE_PLAN',id,{},null);await render();showToast('تم إغلاق الخطة','success');}catch(e){showToast(e.message,'error');}finally{hideLoader();}
        },
        async postRun(){
            try{
                var id=byId('st-main-plan-select').value;if(!id)throw new Error('اختر خطة');
                if(!postOperationId) postOperationId=uid();
                showLoader('جاري ترحيل النتائج...');
                var j=await op('POST',id,{},postOperationId);
                postOperationId=null;
                await renderDashboard(id);
                showToast(j.duplicate?'تم منع التكرار وإعادة نفس النتيجة':'تم الترحيل بنجاح','success');
            }catch(e){showToast(e.message,'error');}finally{hideLoader();}
        },
        async approveRun(runId){
            try{showLoader('جاري اعتماد العملية...');await op('APPROVE_RUN',runId,{},null);var id=byId('st-main-plan-select');if(id)await renderDashboard(id.value);showToast('تم اعتماد العملية','success');}catch(e){showToast(e.message,'error');}finally{hideLoader();}
        },
        async reverseRun(runId){
            try{showLoader('جاري عكس العملية...');await op('REVERSE_RUN',runId,{},uid());var id=byId('st-main-plan-select');if(id)await renderDashboard(id.value);showToast('تم عكس العملية','success');}catch(e){showToast(e.message,'error');}finally{hideLoader();}
        }
    };
})();
```

### ملاحظات هذا الـcontroller

- لا يكتب إلى Production مباشرة.
- لا يغير `orders` أو `order_details`.
- يستخدم نفس `sales-target-engine` و`sales-target-dashboard`.
- يحافظ على company isolation عبر Edge/API.
- يحتفظ بـPOST operation identity.
- يميز Plan ID عن Run ID.
- يشغل Realtime subscriptions.
- يجعل النظام الأم يستخدم نفس الـTarget Engine المستخدم في Manager.

قبل إدخال هذا المقطع في النسخة النهائية يجب اختبار توافق أسماء helper functions المستخدمة في النسخة الحالية مثل:

`showLoader`
`hideLoader`
`showToast`
`rw-page-content`

وذلك من الملف الأم الحالي نفسه، وليس بالافتراض.

---

# 16. OWNER SURGERY — manager.html

الملف الحالي:

`companies/company-1/sales/manager.html`

### العنصر المطلوب

ابحث عن:

```javascript
renderTargets: function(){
```

والدالة كاملة، التي تبدأ بـ:

```javascript
renderTargets: function(){
    var s=this;
    var endpoint=RW_SUPABASE_URL + '/functions/v1/sales-target-dashboard';
```

وتنتهي مباشرة قبل:

```javascript
renderReports: function(){
```

### المطلوب

احذف دالة `renderTargets` الحالية كاملة من:

```javascript
renderTargets: function(){
```

حتى آخر `},` الذي يسبق مباشرة:

```javascript
renderReports: function(){
```

ثم استبدلها بالـ`renderTargets` الجديد المسجل في هذا التقرير كمرجع Owner Surgery، مع الإضافات الإلزامية التالية:

1. `postOperationId` يبقى ثابتًا حتى نجاح POST.
2. `APPROVE_RUN` و`REVERSE_RUN` يستخدمان Run ID الحقيقي.
3. اختيار الخطة لا يعيد تعيين الشاشة إلى أول خطة.
4. فتح Realtime channel على الجداول الأربعة.
5. عرض Preview.
6. عرض Run actions.
7. السماح بتعديل Assignment دون إنشاء duplicate row.
8. تعطيل Assignment بدل حذفه عند الحاجة التشغيلية.
9. عدم استخدام أي hard-coded target مثل `50000`.

**ممنوع ترك الدالة القديمة بجانب الجديدة. يجب أن توجد `renderTargets` واحدة فقط.**

---

# 17. ما لم يتم تغييره عمدًا

لم يتم تغيير:

- قاعدة حساب Actuals.
- `order_details` كمرجع fulfillment.
- `runsheet` behavior.
- أي Physical Stock writer.
- أي Inventory contract.
- أي Financial contract خارج Sales Targets.
- `main.html` نفسه.

السبب: لم تظهر حاجة مثبتة من Production تستوجب كسر هذه العقود.

---

# 18. الأخطاء التي ظهرت أثناء التنفيذ

### خطأ 1 — الاعتماد الأولي على Report173

السبب:
التقرير أصبح Historical ولم يعد يمثل Production الحالية.

الإجراء:
إعادة أخذ Production snapshot من قاعدة البيانات، ثم مراجعة current Git/current deployments مباشرة.

### خطأ 2 — محاولة استخدام Raw/clone لقراءة main.html

النتيجة:
الـruntime لا يملك DNS/النقل المطلوب.

الإجراء:
الاعتماد على GitHub blob/source search، وعدم اختراع EOF أو line numbers.

### خطأ 3 — Target backend كان مفتوحًا من ناحية ACL لبعض LIST operations

السبب:
`LIST_PLANS/LIST_ASSIGNMENTS/LIST_RUNS/PREVIEW` لم تكن مجمعة خلف capability gateway.

الإصلاح:
إنشاء `sales_target_engine_gateway` وربط Edge به.

### خطأ 4 — الخلط بين Plan ID وRun ID في Manager UI

السبب:
UI state كان يعتمد على selected plan ثم يمرره إلى run operations.

الإصلاح المطلوب:
Run operations يجب أن تستقبل Run ID من run table/select.

### خطأ 5 — Operation ID جديد عند كل POST

السبب:
توليد UUID عند click بدل الاحتفاظ به حتى response success.

الإصلاح المطلوب:
احتفاظ بـoperation identity حتى تأكيد العملية.

---

# 19. ما نجح وما لم ينجح

## نجح

- Production Target schema موجود.
- Production Target RPC موجود.
- Production Target Dashboard موجود.
- Production Realtime موجود.
- Production E2E transactional lifecycle نجح.
- POST retry idempotency نجحت.
- ACL gateway E2E نجحت.
- Production test residue = 0.
- canonical Git source للـEdge تم تحديثه.
- `forensic_main_assembly.yml` بالفعل يشير إلى Source of Truth الصحيح.

## لم يُغلق

- Browser E2E الحقيقي.
- Console verification في browser المنشور.
- Network verification في browser المنشور.
- تنفيذ Owner surgery على `main.html`.
- تنفيذ Owner surgery على `manager.html`.
- System-level closure النهائي.

---

# 20. FINAL CLOSURE MATRIX

| Layer | Status |
|---|---|
| Target DB Schema | CLOSED |
| Target Core RPC | CLOSED |
| Target Dashboard RPC | CLOSED |
| Target ACL Gateway | CLOSED |
| Target Edge | CLOSED |
| Target Realtime DB | CLOSED |
| Production Transactional E2E | CLOSED / PASS |
| POST Idempotency | CLOSED / PASS |
| Test Residue | CLOSED / 0 |
| Sales Manager UI | OPEN — OWNER |
| Master main.html UI | OPEN — OWNER |
| Browser E2E | OPEN |
| System-Level Sales Targets | OPEN |

**لا يجوز إعلان `100% CLOSED` الآن.**

---

# 21. ما تم إثباته وليس مجرد كلام

1. Production DB الحالية تحتوي Target Engine فعلي.
2. Target lifecycle يعمل Transactionally.
3. Reversal وApproval تعملان على Run حقيقي عند استدعاء RPC مباشرة.
4. POST duplicate protection تعمل.
5. Gateway ACL تعمل.
6. Target tables موجودة في Realtime.
7. لا توجد Target test rows متبقية بعد الاختبارات.
8. أحدث frontend HEAD وParent تم فتحهما مباشرة.
9. `forensic_main_assembly.yml` صحيح.
10. `main.html` الحالي هو Source of Truth المثبت، لكن قراءة EOF الكاملة غير مثبتة تقنيًا.

---

# 22. تعليمات البداية للمساعد التالي — اقرأ هذه أولًا

لا تبدأ من Report178.

ابدأ بهذا التسلسل حرفيًا:

```text
1. CURRENT PRODUCTION SNAPSHOT
   ↓
2. CURRENT FRONTEND HEAD
   ↓
3. DIRECT PARENT
   ↓
4. CURRENT main.html BLOB
   ↓
5. CURRENT manager.html
   ↓
6. CURRENT sales_target_* TABLES
   ↓
7. CURRENT RPC DEFINITIONS
   ↓
8. CURRENT EDGE DEPLOYMENTS
   ↓
9. CURRENT REALTIME PUBLICATION
   ↓
10. CURRENT RLS / ACL
   ↓
11. ONLY THEN historical reports as search pointers
```

بعد ذلك:

```text
READ CURRENT SOURCE
→ RECONSTRUCT CONTRACT
→ COMPARE PRODUCTION
→ IDENTIFY ACTUAL GAP
→ ONE SURGICAL CLOSURE UNIT
→ TEST
→ DEPLOY
→ PRODUCTION VERIFY
→ BROWSER VERIFY
→ REALTIME VERIFY
→ FINAL SNAPSHOT
→ REPORT
```

### لا تفعل

- لا تبدأ من Report173.
- لا تثق في CURRENT_STATE قديم إذا تعارض مع Production.
- لا تعيد إصلاح Gateway إذا لم يوجد Regression.
- لا تغيّر `sales_target_engine_atomic` لمجرد تحسين شكلي.
- لا تختلق line numbers لـ`main.html`.
- لا تعتبر Manager UI موجودًا = System-level closure.
- لا تعتبر Edge PASS = Browser PASS.
- لا تعتبر Realtime publication = Frontend Realtime subscription.

### البداية الفعلية للمهمة المتبقية

الأولوية 1:

`obtain CURRENT main.html full EOF body`

ثم:

`extract exact target navigation + dispatcher anchors`

ثم Owner surgery.

ثم Manager surgery.

ثم publish frontend.

ثم:

`authenticated browser E2E as Sales Manager`

ثم فحص:

`Console + Network + Realtime`

ثم Production snapshot جديد في نفس لحظة التقرير.

ولا تغلق النظام قبل أن تكون كل هذه الطبقات PASS.

---

# 23. Final Self-Audit

## What I Proved

- Current frontend HEAD and parent.
- Current main blob.
- Current Production target schema.
- Current RPCs.
- Current Edge versions.
- Current Realtime membership.
- Production E2E lifecycle.
- Gateway ACL E2E.
- Zero test residue.

## What I Did Not Prove

- Full line-by-line EOF read of 1.09MB `main.html`.
- Browser authenticated E2E.
- Browser Console clean.
- Browser Network clean.
- Frontend Realtime runtime reaction.

## What I Fixed

- Production Target Engine capability ACL boundary.
- Edge canonical source alignment to the new gateway.

## What I Initially Missed

- أن وجود Target tables وRPC لا يعني أن النظام الأم يحتوي Target UI.
- أن Manager UI الحالي يحتوي Target view لكنه ليس دورة إدارة كاملة.
- أن Run actions تحتاج Run ID مستقلًا.
- أن POST identity يجب أن يبقى ثابتًا حتى confirmation.

## What Could Still Be Wrong

- أي integration detail داخل `main.html` لا يمكن إثباته دون full body/EOF.
- أي Browser runtime defect لا يظهر من static source وحده.

## Final Confidence

`HIGH` للـProduction Target backend + ACL + transactional lifecycle.

`MEDIUM` للـManager integration حتى تنفيذ Owner surgery.

`LOW / NOT PROVEN` للـMaster browser E2E حتى قراءة `main.html` كاملة واختبار المتصفح.

## Final Closure Status

`SYSTEM-LEVEL SALES TARGETS = OPEN`

والسبب الوحيد الآن هو طبقة Frontend/Browser التي يجب إغلاقها من الـSource of Truth الحالي، وليس نقصًا في Production Target backend الذي تم إثباته وإغلاقه هنا.
