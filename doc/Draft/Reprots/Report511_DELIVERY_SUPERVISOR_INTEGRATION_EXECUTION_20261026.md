# Report511 — التحقيق والتنفيذ الفعلي لتكامل مشرف التوصيل مع دورة الرانشيت

**التاريخ:** 2026-10-26  
**وقت آخر فحص Production:** 2026-10-26 17:01:21 UTC  
**الحالة:** PARTIAL — PRODUCTION RPC DEPLOYED + SQL READ/SECURITY CHECKS PASS / UI + DELIVERY EDGE CONTRACT NOT CLOSED  
**Production project:** SMART ERP / fiilmooggumokxanwiyx  
**المستودع التشغيلي:** papamohammed77-glitch/erp-frontend، الفرع main  
**مستودع العقود والتقارير:** papamohammed77-glitch/rawaie-erp-New، الفرع main

---

## 1. PRE-CHANGE SELF-AUDIT

| المجال | التقييم المدعوم | الحد الفعلي |
|---|---:|---|
| Business Understanding | 98/100 | ثبت الفصل بين سائق المركبة ومندوب التوصيل؛ إغلاق المحاسبة/التحصيل لكل دور ما زال مفتوحًا. |
| Architecture Understanding | 97/100 | Parent/Fleet يحتفظان بالمركبة وdriver_id؛ مشرف التوصيل مسؤول عن deliverer_id. |
| Database Understanding | 97/100 | تم فحص Production schema والـRLS والـRPCs مباشرة. |
| Historical Understanding | 93/100 | قرأت CURRENT_STATE وآخر تقارير 507–510 والبرومبت التشغيلي وملف Migration؛ لا أدعي إغلاق Git ancestry لكل Edge consumer. |
| Production Synchronization | 100/100 للقراءة والتنفيذ الذي تم | Migration طُبقت الآن على Production ثم أُعيد فحص الدوال والـACL والـread model مباشرة. |
| Consumer Trace | 75/100 | ثبتت أخطاء supervisor.html وdriver.html وخمس Edge contracts ذات صلة؛ لم تُغلق كل مستهلكات دورة التوصيل. |
| Runtime Verification | 55/100 | Production SQL read model ورفض الشركة الخطأ نجحا؛ لم يُنفذ HTTP E2E مصادق عليه أو Browser E2E. |
| Execution Confidence | 94/100 في عقد RPC فقط | لا تعني هذه الدرجة أن دورة التوصيل كاملة مغلقة. |

### Confirmed Facts
- Production يملك runsheets.driver_id وrunsheets.deliverer_id كحقلين منفصلين.
- Production يملك erp_operation_registry، ولا يلزم إنشاء جدول إسناد مكرر.
- Migration عقد قراءة المشرف والإسناد الذري موجودة في Git وتم تطبيقها على Production في هذه الجلسة.
- RPCs الجديدة SECURITY DEFINER، وEXECUTE غير ممنوح لـanon وممنوح لـauthenticated وservice_role.
- استدعاء read model تحت سياق Auth محاكى للمستخدم النشط ذي صلاحية delivery_supervisor أعاد dashboard والفريق والرانشيتات ضمن الشركة.
- RS-1 وRS-2 بقيا Loaded وdeliverer_id=NULL؛ لم أستخدمهما كـfixtures ولم أعدّل بيانات الأعمال.

### Unknown / Unverified
- لم يُثبت HTTP/PostgREST E2E باستخدام JWT حقيقي.
- لم يُثبت Browser E2E على HTML الذي يقدمه Cloudflare.
- لم يُنفذ اختبار جلستين متزامنتين على إسناد Production.
- لم تُوائم واجهة supervisor.html ولا driver.html بعد.
- لم تُصلح Edge Functions الحالية التي ما زالت تستخدم driver_id في دورة مندوب التوصيل.

### Conflict Resolved
كانت الحالة السابقة LVE-510 تقول إن Migration غير منشورة على Production. أعدت فحص Production في هذه الجلسة، ثم طبقت Migration بنجاح وتحققت من وجود الدالتين والـACL. لذلك الحالة الحالية تختلف عن Report510؛ لا يجوز استمرار استخدام الحالة القديمة بعد هذا الحدث.

---

## 2. نطاق المهمة وحل التعارض في التعليمات

ملف MASTER_CTO_EXECUTION_PROMPT_LOADER_PICKER_INTEGRATION_20261025.md يحتوي في وحدته المتغيرة مهمة Loader/Picker. لكن الرسالة التنفيذية الحالية حدّدت صراحة مهمة أحدث ومختلفة: اختبار تكامل مشرف التوصيل مع بقية النظام، مع فصل Driver عن Delivery Representative. اتُّبع نطاق الرسالة الحالية. لم أعدّل loader.html أو picker.html أو main.html.

---

## 3. مصادر الحقيقة التي أُعيد فتحها

### مستودع التقرير/العقود
- CURRENT_STATE.md — قرأت LAST VERIFIED EVENT من LVE-510 وما قبله من LVE-509 و508 و507.
- Report510_DELIVERY_SUPERVISOR_EXECUTION_20261026.md — blob SHA: 9a3a591bd3150ee7aed1dff7c33cad04eb26f41a.
- Migration: supabase/migrations/20261026170000_delivery_supervisor_deliverer_assignment_contract.sql
- Migration blob SHA: dff7aada5534c16fdc6394085fc28c67dd4365cd.
- Commit الذي أضاف Migration بحسب سجل الحالة: 40fae5af069094210dce6e0f08a83d5fd442754c.

### المستودع التشغيلي
- companies/company-1/delivery/supervisor.html — blob SHA: 4108d2330e567c432f08197013b9c3cf6221a5c7، 229 سطرًا.
- companies/company-1/delivery/driver.html — blob SHA: 2df69860184f5a7c1b211ba059e1d6f57826c96b، 1,755 سطرًا.
- companies/company-1/core.js — blob SHA: ff2f581d9900543c16f7cb026e13446520c0329d، 773 سطرًا.

لم أكتب إلى ملفات HTML التشغيلية لأن سياسة المهمة تجعل تطبيق رقع هذه الملفات مسؤولية المالك. لم أغيّر main.html أو driver.html أو supervisor.html.

---

## 4. Live Production — ما تم فعليًا

### 4.1 Migration

تم تطبيق الملف canonical التالي على Production عبر مسار Supabase المعتمد:

~~~text
supabase/migrations/20261026170000_delivery_supervisor_deliverer_assignment_contract.sql
~~~

نتيجة أداة التطبيق: success=true. وأعاد سجل migrations النسخة الفعلية:

~~~text
version = 20261026170039
name = delivery_supervisor_deliverer_assignment_contract
~~~

الوقت المرصود بعد التطبيق: 2026-10-26 17:00:59.784089 UTC.

### 4.2 Live RPC inventory + ACL

| RPC | SECURITY DEFINER | anon EXECUTE | authenticated EXECUTE | service_role EXECUTE |
|---|---|---|---|---|
| delivery_supervisor_assignment_query(uuid,text) | true | false | true | true |
| delivery_supervisor_assign_deliverer_atomic(uuid,text,uuid,text) | true | false | true | true |

هذا يثبت نشر عقد القراءة والإسناد الذري وصلاحيات التنفيذ على مستوى PostgreSQL، ولا يثبت وحده نجاح HTTP/JWT أو واجهة المستخدم.

### 4.3 Live read-model test

نفذت قراءة Production تحت سياق Auth claim محاكى لمستخدم نشط لديه delivery_supervisor. النتيجة:

- dashboard: success=true، total_runsheets=2، loaded=2، delivering=0، delivered=0، returning=0، active_deliverers=4.
- team: أعاد أربعة مستخدمين نشطين مؤهلين للتوصيل.
- runsheets: أعاد RS-1 وRS-2 داخل الشركة المحددة، وكلاهما Loaded مع vehicle_id موجود وdriver_id=NULL وdeliverer_id=NULL.

**حد الاختبار:** هذا اختبار SQL تحت سياق Auth claim محاكى، وليس HTTP/PostgREST باستخدام JWT فعليًا.

### 4.4 Company isolation

نفذت اختبارًا سلبيًا باستعمال هوية المشرف نفسها مع company_id غير صحيحة. الدالة رفضت الطلب كما هو متوقع؛ لم تُرجع بيانات الشركة الأخرى.

### 4.5 Production RLS

الفحص المباشر أظهر RLS مفعّلًا على الجداول ذات الصلة التي فُحصت: runsheets وusers وerp_operation_registry وdelivery_agents. لم أغيّر RLS أو أضف سياسات واسعة.

### 4.6 Baseline

لم تُعدّل بيانات Production التشغيلية أو المخزون أو الحسابات. RS-1 وRS-2 لم يُستخدما كبيانات اختبار. لا يوجد ادعاء بأن Production assignment write أو HTTP E2E قد اجتاز الاختبار.

---

## 5. Driver مقابل Delivery Representative — العقد الصحيح

العقد الذي يجب أن يظل ثابتًا:

- Parent/Fleet يربط المركبة بالرانشيت ويحدد سائق المركبة في runsheets.vehicle_id وrunsheets.driver_id.
- Delivery Supervisor يحدد مندوب التوصيل في runsheets.deliverer_id.
- يجوز للشركة التي تجمع الوظيفتين إسناد نفس سجل الموظف إلى الحقلين إذا كان مخولًا بالدورين؛ لكن ذلك لا يبرر دمج الحقلين أو استعمال أحدهما بديلًا عن الآخر.
- إذا فصلت الشركة الوظيفتين، فلا يجوز أن يتحول إسناد مندوب التوصيل إلى تغيير driver_id، ولا يجوز أن يُمسح vehicle_id أو driver_id عند فك إسناد المندوب.
- عمليات التسليم والمرتجعات والتحصيل والمسؤولية عن البضاعة يجب أن تتبع هوية مندوب التوصيل وفق العقد الفعلي؛ بيانات السائق/المركبة والعداد تبقى منفصلة.

---

## 6. Root Cause — العيوب التي ما زالت مثبتة

### A. supervisor.html — خلل Consumer contract
النسخة الحالية لا تستخدم RPCs الجديدة:
- renderDashboard يقرأ runsheets وusers مباشرة.
- renderTeam يربط الإحصاءات بـrunsheets.driver_id.
- openAssignModal يعرض Loaded مع driver_id=NULL، وليس deliverer_id=NULL.
- assignDriver يكتب runsheets.driver_id مباشرة.
- unassignDriver يمسح driver_id ويكتب status مباشرة.
- renderRunsheets يقرأ driver_id مباشرة.
- هذه القراءة/الكتابة تخالف RLS الحالية، وتخلط سائق المركبة بمندوب التوصيل.

### B. driver.html — خلل دورة المندوب
النسخة الحالية تجلب الرانشيتات بواسطة driver_id في checkForNewRunsheet، ومسار تحميل الرانشيت النشط، وبعض إحصاءات الرصيد. لذلك لا تتوافق مع إسناد supervisor الذي يكتب deliverer_id. لا يجوز إجراء استبدال شامل لكل ظهور لـdriver_id لأن بعض الحقول، مثل vehicle_tracking.driver_id، يجب أن تبقى هوية السائق الفعلية.

### C. Edge Functions المنشورة
تم فحص المصادر الحية مباشرة:

| Function | Production | verify_jwt | SHA الخاص بحزمة النشر | العيب المثبت |
|---|---:|---|---|---|
| get-driver-dashboard | v1 ACTIVE | true | 59f6bbd39fb8331109966c312fda3327077f17cceda8d9b4b1c9a1c6f652f58e | يستعلم عن users.vehicle_id غير الموجود؛ لا يضم activeRS.id في SELECT ثم يستخدمه؛ يعتمد driver_id. |
| start-delivery | v7 ACTIVE | true | 7e87dd0a29d57d3d286c19e05aed70c8b40c7e74645fc73f593e6eee2610399e | lookup بالبريد بدل auth_id، ويفحص driver_id بدل deliverer_id، وتحديث الحالة ليس عبر عقد ذري موحد. |
| complete-delivery | v4 ACTIVE | true | 9510e7ef441d3b1256f860c775094c43f5102381488580d99601b26c1b482753 | لا يتحقق من أن المنفذ هو deliverer_id المعيّن؛ يعتمد الشركة والحالة فقط. |
| complete-order-delivery | v14 ACTIVE | true | 15c67bde52401897fc0ccc4156670fd5cdc026152617401aabca232c1b046fb2 | Edge يستخدم auth_id لتحديد الشركة، لكن Core complete_order_delivery_atomic لا يفرض deliverer_id المعيّن وحالة Delivering داخل المعاملة. |
| force-unassign-runsheet | v1 ACTIVE | true | 4fec814c60d3899ba12b1a6f7af07228a954cf56fe3ce0eb617abdeb8af514b9 | lookup غير مقيد بالشركة، وفحص الصلاحيات غير كافٍ، ويمسح driver_id بدل deliverer_id. |

هذه نتائج مصدر Production الحالي؛ لا تعني أن كل هذه الوظائف تم إصلاحها أو إعادة نشرها. لم أنشر Edge Function جزئية قد تكسر واجهة ما زالت تستخدم driver_id.

---

## 7. هل نحتاج جداول جديدة؟

**لا.** الدليل الحي يثبت وجود:
- runsheets.deliverer_id
- runsheets.driver_id
- runsheets.vehicle_id
- erp_operation_registry

إنشاء جدول إسناد موازٍ سيخلق مصدر حقيقة إضافيًا ويضاعف احتمال drift. المطلوب هو توحيد consumers حول الحقول والعقود القائمة، وليس إضافة جدول آخر بلا حاجة مثبتة.

**نقطة مالية تحتاج مراجعة مستقلة قبل أي تغيير:** جداول driver_ledger وdriver_liabilities ما زالت تستخدم تسمية driver. يجب تتبع كل Writer وConsumer وتحديد هل السجل يمثل سائق المركبة أم مندوب التوصيل قبل تغيير هوية المسؤولية المالية؛ لا يجوز تبديل المعرّفات جماعيًا من الاسم وحده.

---

## 8. مصفوفة الاختبارات

| الاختبار | النتيجة | الدليل/الحد |
|---|---|---|
| تطبيق Migration على Production | PASS | Supabase apply_migration أعاد success=true. |
| ظهور RPCs في Production | PASS | pg_proc أعاد الدالتين بالتوقيع الصحيح. |
| ACL: منع anon | PASS | has_function_privilege=false للدالتين. |
| ACL: authenticated/service_role | PASS | EXECUTE=true للدالتين. |
| Read model: dashboard/team/runsheets | PASS — SQL only | نجاح تحت Auth claim محاكى؛ ليس HTTP JWT E2E. |
| رفض company_id غير صحيحة | PASS — SQL only | النداء رُفض ولم يُرجع بيانات الشركة الأخرى. |
| Assignment write على Production | NOT RUN | لا توجد fixture معزولة حالية؛ لم ألمس RS-1/RS-2. |
| Retry/duplicate/concurrency على Production | NOT RUN | لا ادعاء بنجاحها على Production. |
| Staging SQL contract tests | HISTORICAL PASS | Report510 وثّق اختبارًا سابقًا مع rollback؛ لم أعد اعتباره إثباتًا لـProduction HTTP. |
| Supervisor Browser E2E | NOT RUN | الواجهة لم تُوائم بعد. |
| Driver Browser/HTTP E2E | NOT RUN | UI/Edge ما زالت تستخدم driver_id. |
| Cloudflare served-HTML parity | UNVERIFIED | لم تُثبت مطابقة HTML المنشور مع blob الحالي. |
| Inventory/accounting baseline | PASS — NO MUTATION | لم أجرِ أي كتابة أعمال/مخزون/حسابات في هذه الجلسة. |

---

## 9. الرقع المصدرية الموجهة للمالك

**مهم:** هذه رقع مصدرية مقترحة للتطبيق بعد مراجعة SHA مباشرة قبل التطبيق. لم تُطبق في Git التشغيلي؛ لذلك الحالة PROPOSED وليست APPLIED.

### Patch A — supervisor.html / renderDashboard

**الملف:** companies/company-1/delivery/supervisor.html  
**SHA المتوقع:** 4108d2330e567c432f08197013b9c3cf6221a5c7  
**محدد البحث:** renderDashboard: function(){

استبدل الدالة كاملةً من بداية renderDashboard حتى الفاصلة التي تلي إغلاقها، بالآتي:

~~~javascript
renderDashboard: function(){
    var self=this;
    var companyId=this.currentUser&&this.currentUser.company_id;
    RW_UI.safeHTML(RW_UI.byId('mainContent'),'<div class="p-4"><div class="skeleton h-32 w-full mb-4"></div><div class="skeleton h-48 w-full"></div></div>');
    if(!companyId){RW_UI.showError('تعذر تحديد الشركة للمستخدم');return;}
    Promise.all([
        supabase.rpc('delivery_supervisor_assignment_query',{p_company_id:companyId,p_view:'dashboard'}),
        supabase.rpc('delivery_supervisor_assignment_query',{p_company_id:companyId,p_view:'team'})
    ]).then(function(results){
        if(results[0].error)throw results[0].error;
        if(results[1].error)throw results[1].error;
        var d=results[0].data||{},team=(results[1].data&&results[1].data.rows)||[];
        var totalRS=Number(d.total_runsheets)||0,totalValue=0;
        var deliveredCount=Number(d.delivered)||0;
        var deliveringCount=Number(d.delivering)||0;
        var loadedCount=Number(d.loaded)||0;
        var html='<div class="p-4"><h2 class="text-lg font-black text-slate-800 mb-4">📊 مؤشرات الأداء – الشهر الحالي</h2>';
        html+='<div class="grid grid-cols-2 gap-3 mb-4"><div class="stat-card card"><p class="text-xs text-teal-400">إجمالي الرحلات</p><p class="text-2xl font-black text-teal-600">'+totalRS+'</p></div><div class="stat-card card"><p class="text-xs text-blue-400">الرحلات الجارية/المحملة</p><p class="text-2xl font-black text-blue-600">'+(loadedCount+deliveringCount)+'</p></div><div class="stat-card card"><p class="text-xs text-green-400">تم التوصيل</p><p class="text-2xl font-black text-green-600">'+deliveredCount+'</p></div><div class="stat-card card"><p class="text-xs text-amber-400">مناديب نشطون</p><p class="text-2xl font-black text-amber-600">'+(Number(d.active_deliverers)||team.length)+'</p></div></div>';
        html+='<div class="card mb-4"><h3 class="font-bold text-slate-700 mb-3">نسبة الإنجاز</h3><div class="w-full h-48 relative"><canvas id="kpiChart"></canvas></div></div>';
        html+='<div class="text-center text-sm text-slate-500">👥 عدد مناديب التوصيل النشطين: <strong>'+(Number(d.active_deliverers)||team.length)+'</strong></div></div>';
        RW_UI.safeHTML(RW_UI.byId('mainContent'),html);
        setTimeout(function(){var ctx=RW_UI.byId('kpiChart');if(ctx){if(self.chartInstance)self.chartInstance.destroy();self.chartInstance=new Chart(ctx,{type:'doughnut',data:{labels:['تم التوصيل','لم يكتمل'],datasets:[{data:[deliveredCount,Math.max(0,totalRS-deliveredCount)],backgroundColor:['#10b981','#f59e0b'],borderWidth:0}]},options:{responsive:true,maintainAspectRatio:false,plugins:{legend:{position:'bottom',labels:{usePointStyle:true,padding:20}}}}});}},200);
    }).catch(function(err){RW_UI.showError('تعذر تحميل مؤشرات مشرف التوصيل: '+(err.message||'خطأ غير معروف'));});
},
~~~

**ملاحظة حسابية:** RPC dashboard لا يعيد قيمة إجمالية للرحلات، لذلك لا تعرض الدالة قيمة مالية مختلقة. إذا احتاجت KPI القيمة المالية، يضاف حقل read-model محكوم إلى RPC بعد إثبات العقد المطلوب، لا قراءة مباشرة من الواجهة.

### Patch B — supervisor.html / renderTeam

**محدد البحث:** renderTeam: function(){

استبدل الدالة الحالية كاملةً بدالة تقرأ الفريق والرانشيتات عبر RPC وتحسب الإحصاءات باستخدام deliverer_id. لا تستخدم driver_id كمفتاح إحصاء لمندوب التوصيل.

~~~javascript
renderTeam: function(){
    var self=this,companyId=this.currentUser&&this.currentUser.company_id;
    RW_UI.safeHTML(RW_UI.byId('mainContent'),'<div class="p-4"><div class="skeleton h-16 w-full mb-4"></div><div class="skeleton h-24 w-full mb-3"></div></div>');
    if(!companyId){RW_UI.showError('تعذر تحديد الشركة للمستخدم');return;}
    Promise.all([
        supabase.rpc('delivery_supervisor_assignment_query',{p_company_id:companyId,p_view:'team'}),
        supabase.rpc('delivery_supervisor_assignment_query',{p_company_id:companyId,p_view:'runsheets'})
    ]).then(function(results){
        if(results[0].error)throw results[0].error;
        if(results[1].error)throw results[1].error;
        var deliverers=(results[0].data&&results[0].data.rows)||[];
        var runsheets=(results[1].data&&results[1].data.rows)||[];
        var stats={};
        for(var i=0;i<runsheets.length;i++){
            var rs=runsheets[i],id=rs.deliverer_id||'';
            if(!id)continue;
            if(!stats[id])stats[id]={count:0,total:0,delivered:0};
            stats[id].count++;
            stats[id].total+=Number(rs.total_amount)||0;
            if(rs.status==='Delivered')stats[id].delivered++;
        }
        self.driversList=deliverers;
        var html='<div class="p-4"><h2 class="text-lg font-black text-slate-800 mb-4">👥 مناديب التوصيل</h2>';
        if(!deliverers.length){html+='<div class="text-center py-16"><div class="text-6xl mb-4">👥</div><p class="text-slate-400 font-bold">لا يوجد مناديب توصيل نشطون.</p></div>';}
        else{
            for(var j=0;j<deliverers.length;j++){
                var person=deliverers[j],st=stats[person.id]||{count:0,total:0,delivered:0};
                var rate=st.count>0?Math.round((st.delivered/st.count)*100):0;
                html+='<div class="card mb-3"><div class="flex justify-between mb-2"><span class="font-bold">'+(person.name||person.email)+'</span><span class="px-2 py-0.5 bg-teal-100 text-teal-700 rounded-full text-xs font-bold">مندوب توصيل</span></div>';
                html+='<div class="grid grid-cols-3 gap-2 text-center"><div><p class="text-xs text-gray-400">رحلات مسندة</p><p class="font-black">'+st.count+'</p></div><div><p class="text-xs text-gray-400">القيمة</p><p class="font-black text-teal-600">'+fmtNum(st.total)+'</p></div><div><p class="text-xs text-gray-400">توصيل</p><p class="font-black text-green-600">'+rate+'%</p></div></div>';
                html+='<div class="w-full h-1.5 bg-gray-100 rounded-full mt-2"><div class="h-full bg-teal-500 rounded-full" style="width:'+rate+'%"></div></div>';
                html+='<div class="mt-2 flex gap-2"><button onclick="App.openAssignModal(\''+person.id+'\',\''+(person.name||person.email||'').replace(/'/g,"\\'")+'\')" class="text-xs bg-teal-100 text-teal-700 px-3 py-1 rounded-full font-bold">تخصيص رانشيت</button></div></div>';
            }
        }
        html+='</div>';RW_UI.safeHTML(RW_UI.byId('mainContent'),html);
    }).catch(function(err){RW_UI.showError('تعذر تحميل فريق التوصيل: '+(err.message||'خطأ غير معروف'));});
},
~~~

### Patch C — supervisor.html / openAssignModal + assignDriver + unassignDriver

تستبدل هذه الدوال الثلاث فقط. يستخدم الإسناد والفك RPC ذريًا ويكتب deliverer_id فقط. operation_id يبقى ثابتًا عند إعادة المحاولة الفاشلة عبر localStorage.

~~~javascript
openAssignModal: function(delivererUserId,delivererName){
    var self=this,companyId=this.currentUser&&this.currentUser.company_id;
    if(!companyId){RW_UI.showError('تعذر تحديد الشركة للمستخدم');return;}
    supabase.rpc('delivery_supervisor_assignment_query',{p_company_id:companyId,p_view:'runsheets'}).then(function(res){
        if(res.error)throw res.error;
        var rows=(res.data&&res.data.rows)||[];
        var loaded=rows.filter(function(r){return r.status==='Loaded'&&!r.deliverer_id;});
        if(!loaded.length){Swal.fire({title:'لا توجد رانشيتات',text:'لا توجد رانشيتات محملة غير مسندة لمندوب توصيل.',icon:'info',customClass:{popup:'!rounded-3xl'}});return;}
        var options='';
        for(var i=0;i<loaded.length;i++){options+='<option value="'+loaded[i].runsheet_code+'">'+loaded[i].runsheet_code+' - '+loaded[i].run_date+' ('+fmtNum(loaded[i].total_amount)+' ج.م)</option>';}
        Swal.fire({title:'تخصيص رانشيت لـ '+delivererName,html:'<select id="swal-rs-select" class="swal2-input w-full text-right rounded-xl">'+options+'</select>',showCancelButton:true,confirmButtonText:'تخصيص',cancelButtonText:'إلغاء',customClass:{popup:'!rounded-3xl',confirmButton:'!rounded-xl !bg-teal-600 !px-8',cancelButton:'!rounded-xl'},preConfirm:function(){return document.getElementById('swal-rs-select').value;}}).then(function(result){if(result.isConfirmed&&result.value)self.assignDriver(result.value,delivererUserId);});
    }).catch(function(err){RW_UI.showError('تعذر تحميل الرانشيتات: '+(err.message||'خطأ غير معروف'));});
},

assignDriver: function(runsheetCode,delivererUserId){
    var self=this,companyId=this.currentUser&&this.currentUser.company_id;
    if(!companyId||!delivererUserId){RW_UI.toast('بيانات الشركة أو مندوب التوصيل غير مكتملة','error');return;}
    var key='rw_delivery_assign_op:'+companyId+':'+runsheetCode+':'+delivererUserId,opId=localStorage.getItem(key);
    if(!opId){opId=(window.crypto&&crypto.randomUUID)?crypto.randomUUID():'assign-'+Date.now()+'-'+Math.random().toString(16).slice(2);localStorage.setItem(key,opId);}
    Swal.showLoading();
    supabase.rpc('delivery_supervisor_assign_deliverer_atomic',{p_company_id:companyId,p_runsheet_code:runsheetCode,p_deliverer_user_id:delivererUserId,p_operation_id:opId}).then(function(res){
        Swal.close();
        if(res.error)throw res.error;
        localStorage.removeItem(key);
        RW_UI.toast('تم إسناد مندوب التوصيل بنجاح','success');
        self.renderTeam();self.renderRunsheets();
    }).catch(function(err){Swal.close();RW_UI.toast('تعذر إسناد المندوب: '+(err.message||'خطأ غير معروف')+' — أعد المحاولة دون إنشاء عملية جديدة','error');});
},

unassignDriver: function(runsheetCode){
    var self=this,companyId=this.currentUser&&this.currentUser.company_id;
    if(!companyId){RW_UI.toast('تعذر تحديد الشركة للمستخدم','error');return;}
    Swal.fire({title:'تأكيد فك إسناد المندوب',text:'سيُفك إسناد مندوب التوصيل فقط. لن تتغير المركبة أو هوية السائق أو حالة الرانشيت.',icon:'warning',showCancelButton:true,confirmButtonText:'فك الإسناد',cancelButtonText:'إلغاء',customClass:{popup:'!rounded-3xl'}}).then(function(result){
        if(!result.isConfirmed)return;
        var key='rw_delivery_unassign_op:'+companyId+':'+runsheetCode,opId=localStorage.getItem(key);
        if(!opId){opId=(window.crypto&&crypto.randomUUID)?crypto.randomUUID():'unassign-'+Date.now()+'-'+Math.random().toString(16).slice(2);localStorage.setItem(key,opId);}
        Swal.showLoading();
        supabase.rpc('delivery_supervisor_assign_deliverer_atomic',{p_company_id:companyId,p_runsheet_code:runsheetCode,p_deliverer_user_id:null,p_operation_id:opId}).then(function(res){
            Swal.close();
            if(res.error)throw res.error;
            localStorage.removeItem(key);
            RW_UI.toast('تم فك إسناد مندوب التوصيل','success');
            self.renderRunsheets();self.renderTeam();
        }).catch(function(err){Swal.close();RW_UI.toast('تعذر فك الإسناد: '+(err.message||'خطأ غير معروف'),'error');});
    });
},
~~~

**تنبيه:** لا تطبق هذه الرقع قبل إصلاح force-unassign-runsheet ودورة driver.html الموضحة أدناه؛ وإلا سيبقى المسار Loaded متوافقًا بينما يظل مسار Delivering غير متوافق.

### Patch D — supervisor.html / renderRunsheets

**محدد البحث:** renderRunsheets: function(){

استبدل قراءة الجدول المباشرة بنداء RPC، مع الاحتفاظ بترتيب العرض الحالي. يلزم بعد ذلك تعديل renderRunsheetList لعرض اسم المندوب من قائمة الفريق، وعدم عرض driver_id بوصفه مندوب التوصيل.

~~~javascript
renderRunsheets: function(){
    var self=this,companyId=this.currentUser&&this.currentUser.company_id;
    RW_UI.safeHTML(RW_UI.byId('mainContent'),'<div class="p-4"><div class="skeleton h-16 w-full mb-4"></div><div class="skeleton h-32 w-full mb-3"></div></div>');
    if(!companyId){RW_UI.showError('تعذر تحديد الشركة للمستخدم');return;}
    Promise.all([
        supabase.rpc('delivery_supervisor_assignment_query',{p_company_id:companyId,p_view:'runsheets'}),
        supabase.rpc('delivery_supervisor_assignment_query',{p_company_id:companyId,p_view:'team'})
    ]).then(function(results){
        if(results[0].error)throw results[0].error;
        if(results[1].error)throw results[1].error;
        var rows=(results[0].data&&results[0].data.rows)||[];
        var team=(results[1].data&&results[1].data.rows)||[],names={};
        for(var i=0;i<team.length;i++)names[team[i].id]=team[i].name||team[i].email;
        self.loadedRunsheets=rows.map(function(r){r.deliverer_name=r.deliverer_id?(names[r.deliverer_id]||'مندوب مسند'):'';return r;});
        self.renderRunsheetList();
    }).catch(function(err){RW_UI.showError('تعذر تحميل الرانشيتات: '+(err.message||'خطأ غير معروف'));});
},
~~~

### Patch E — force-unassign-runsheet وdriver.html

لا أقدم تعديلًا شكليًا أو تبديلًا شاملًا لـdriver_id إلى deliverer_id. يجب أولًا تثبيت Core command ذري لفك إسناد مندوب أثناء Delivering، ثم تعديل Edge الحالي force-unassign-runsheet ليستخدمه مع company scope وصلاحية المشرف، مع الحفاظ على driver_id وvehicle_id والكميات المسلّمة. بعدها تُوائم start-delivery وcomplete-delivery وget-driver-dashboard وcancel-delivery مع deliverer_id، وتُراجع driver.html سطرًا بسطر لتمييز حقول مسؤولية مندوب التوصيل من حقول السائق/المركبة والعداد. لا تُنشر هذه Edge changes قبل تطبيق واجهة متوافقة، لأن النشر الجزئي قد يمنع المستخدمين الحاليين من استرجاع رانشيتاتهم.

---

## 10. Mutation ledger

### ما تغيّر
- Production: تم تطبيق Migration الموجودة في Git، فظهرت الدالتان الجديدتان مع ACL المطلوب.
- Production migration registry: سجل التنفيذ الفعلي version 20261026170039/name delivery_supervisor_deliverer_assignment_contract.
- التقرير والحالة المستمرة سيُحدّثان بعد هذا التنفيذ.

### ما لم يتغير
- لم تتغير أي بيانات تشغيلية في runsheets أو orders أو المخزون أو المحاسبة.
- لم تتغير driver_id أو deliverer_id أو vehicle_id في RS-1 وRS-2.
- لم تتغير أي Edge Function منشورة.
- لم تتغير supervisor.html أو driver.html أو core.js أو main.html.
- لم تُنشأ جداول جديدة.
- لم يُنفذ HTTP E2E أو Browser E2E.

---

## 11. Outstanding Debt Register

| البند | الحالة | الإجراء المحدد |
|---|---|---|
| Production supervisor RPC contract | VERIFIED at SQL level | اختبار PostgREST/JWT فعلي بعد تطبيق الواجهة. |
| Company-scoped read model | VERIFIED at SQL level | إعادة اختبار HTTP مع مشرف مصادق عليه وشركة أخرى مرفوضة. |
| Loaded assignment / unassignment | DEPLOYED, SQL path only | اختبار كتابة ذري على fixture معزول؛ لا تستخدم RS-1/RS-2. |
| Supervisor direct table access | CURRENT ONLY / OPEN | تطبيق الرقع A–D على SHA المذكور بواسطة المالك. |
| Delivering emergency unassignment | PRODUCTION DEFECT / OPEN | Core atomic contract + repair existing force-unassign-runsheet. |
| Driver vs deliverer in delivery lifecycle | DRIFT / OPEN | مواءمة Edge + driver.html مع الحقل الصحيح، دون تبديل حقول vehicle tracking. |
| Core order delivery guard | OPEN | فرض company + deliverer identity + Delivering status داخل complete_order_delivery_atomic. |
| Driver ledger/liability ownership | UNKNOWN | Consumer/writer trace قبل أي تغيير schema أو نقل مسؤولية مالية. |
| Concurrent assignment | NOT RUN | اختبار جلستين مستقلتين على fixture معزول. |
| Production HTTP E2E | NOT RUN | يحتاج جلسة مستخدم مشرف/مندوب حقيقية وتطبيق المصدر المتوافق. |
| Cloudflare served HTML parity | UNVERIFIED | جلب النسخة المنشورة ومقارنتها بعد تطبيق المالك للرقع. |
| 100% Closure | NOT CLOSED | لا يجوز إعلانه قبل إغلاق البنود المؤثرة أعلاه. |

---

## 12. SELF-AUDIT FINAL

### What I Proved
- فصل الهوية في Production schema موجود فعلًا: driver_id وdeliverer_id.
- Migration العقد المركزي موجودة في المستودع، وطُبقت على Production.
- RPCs الجديدة موجودة، SECURITY DEFINER، وanon لا يملك EXECUTE.
- read model نجح في SQL تحت Auth claim محاكى، ورفض company_id غير صحيحة.
- baseline الخاص بـRS-1 وRS-2 لم يتغير.

### What I Did Not Prove
- HTTP/PostgREST JWT E2E.
- Browser E2E أو Cloudflare served-HTML parity.
- نجاح إسناد كتابة فعلي في Production على fixture.
- توافق جميع Edge consumers ودورة التحصيل والمرتجعات والدفتر المالي مع فصل الدورين.
- Git-to-deployed provenance الكامل لكل Edge Function.

### What I Fixed
- نشرت عقد قراءة المشرف وإسناد مندوب التوصيل في Production، مع ACL مقيد.
- لم أنشئ جداول مكررة.

### What I Initially Missed
- وجود RPC آمن وحده لا يكفي: supervisor.html ما زال يكتب driver_id مباشرة، والـDriver Edge lifecycle ما زال يستهلك driver_id. يجب تنسيق تحديث المصدر قبل نشر تغييرات Edge.

### What Could Still Be Wrong
- أي consumer غير مكتشف لـdriver_id في تطبيقات التوصيل أو ledger.
- سلوك HTTP/JWT الفعلي بعد تطبيق المصدر.
- تطابق HTML الذي يقدمه Cloudflare مع Git.
- أن تكون صلاحيات بعض مناديب التوصيل معتمدة على role-derived permission بدل وجود literal delivery في permissions.

**Final Confidence:** 94% لعقد RPC وقراءة Production على مستوى SQL؛ أقل من ذلك لتكامل النظام كاملًا.  
**Final Closure Status:** PARTIAL — NOT CLOSED.  
**الخطوة التالية المحددة:** تطبيق الرقع A–D بعد إعادة فحص SHA، ثم تنفيذ Core/Edge repair لدورة Delivering وdriver.html بصورة متزامنة، وبعدها HTTP E2E مصادق عليه مع retry/concurrency/wrong-company وباسلاين نظيف. لا تعاد دراسة الفصل بين driver وdeliverer من الصفر ما لم يظهر دليل جديد.


### Patch D2 — supervisor.html / renderRunsheetList: إظهار مندوب التوصيل دون الخلط مع السائق

**محدد البحث الفريد:** السطر الذي يبدأ بـ  
`html+='<p class="text-xs text-slate-400">'` داخل حلقة `renderRunsheetList` ويعرض `rs.run_date` و`rs.total_amount`.

**استبدل هذا السطر وحده**:

~~~javascript
html+='<p class="text-xs text-slate-400">'+rs.run_date+' | '+fmtNum(rs.total_amount)+' ج.م</p>';
~~~

**بالنص التالي**:

~~~javascript
html+='<p class="text-xs text-slate-400">'+rs.run_date+' | '+fmtNum(rs.total_amount)+' ج.م</p>';
html+='<p class="text-xs '+(rs.deliverer_id?'text-teal-700':'text-amber-600')+' mt-1">مندوب التوصيل: '+(rs.deliverer_name||'غير مسند')+'</p>';
~~~

هذا التعديل يعرض اسم مندوب التوصيل الذي أُثرِي به كل سجل في Patch D. لا يعرض driver_id على أنه مندوب، ولا يغيّر الحالة أو أي بيانات تشغيلية.
