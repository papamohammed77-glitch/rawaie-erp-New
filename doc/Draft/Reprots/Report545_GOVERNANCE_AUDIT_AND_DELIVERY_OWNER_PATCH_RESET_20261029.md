# Report545 — مراجعة حوكمة التقارير 400–500 وإعادة بناء Owner Change Set لتكامل التوصيل

**التاريخ:** 2026-10-29  
**النوع:** تقرير CTO لتنفيذ ما تسمح به الصلاحيات، وتصحيح مسار التنفيذ السابق، وتثبيت رقعة الواجهة للمالك.  
**المراجع:** Reports 400–500 في سجل التقارير، الدستور التشغيلي، writing-block.md، تكليف تنفيذي.md، التقارير 538/540/541/542/543/544، المصدر الحي وSupabase Production.  
**الحالة النهائية:** `PRODUCTION READ CONTRACT + COMPANY GUARDS + RUNSHEET DATE FILTER APPLIED AND VERIFIED / OWNER MAIN.HTML CHANGESET READY / NOT DEPLOYED / AUTHENTICATED E2E OPEN / NOT CLOSED`

## 0. القرار التنفيذي

نتيجة دراسة السلسلة ليست أن المساعد يجب أن يختار بين «لا تفعل شيئًا» و«افتح PR يحرر ملف التشغيل». الطريقة المثبتة في تقارير RAWAEA هي:

1. استعادة آخر حالة ثم إعادة التحقق من المصدر الحي، لا إعادة التشخيص من الصفر ولا تصديق التقرير الأقدم.
2. تحديد صلاحية كل طبقة: المساعد ينفذ تعديل Supabase الضروري المثبت داخل صلاحياته؛ المالك يطبق التعديل الجراحي على `companies/company-1/main.html` وفق دستور المهمة.
3. تجهيز Owner Change Set كامل، بمحددات أصلية واضحة وبدائل محدودة، مع فحص كامل لكتلة JavaScript الافتراضية، لا مجرد وصف نظري أو snippet مبتور.
4. اختبار التغيير الخلفي بعد تطبيقه فعليًا وتسجيل Migration Source في مستودع التشغيل.
5. فصل `APPLIED` عن `DEPLOYED` وعن `E2E VERIFIED`. لا يُعلن الإغلاق حتى يثبت سلوك الواجهة المنشورة المصادق عليها.

وفق هذه القاعدة، أغلقت PR #5 السابق بوصفه **SUPERSEDED / DO NOT MERGE**؛ لأنه أنشأ تغييرًا لملف النظام الأم في فرع مراجعة خلاف مسار المالك المُلزم في المهمة. لم يُدمج، ولم تُطبق migration المرفقة به. أبقيته سجلًا تاريخيًا، وانتقلت إلى المسار الصحيح: إصلاحات القراءة الخلفية التي أطبقها بنفسي عند ثبوت ضرورتها، وOwner Change Set دقيق لـ`main.html`.

## 1. دراسة نطاق التقارير 400–500

تم جرد ملفات التقارير المرقمة ضمن النطاق مباشرة من شجرة GitHub، وجلب محتواها لاستخراج العناوين وخطوط القرار والحالة؛ ثم قُرئت بعمق تقارير مرجعية تُظهر تصحيحات النطاق والـpatch lineage وطريقة العمل، من بينها Reports 400–409 و481–488 و492 و496–500، إلى جانب الحوكمة والتكليف التنفيذي وتقارير التوصيل الأحدث.

### 1.1 نتائج الجرد

- **114 ملف تقرير** يحمل رقمًا من 400 إلى 500.
- الرقمان **Report490 وReport491 غير موجودين** في مسار التقارير الذي جرى جرده.
- الأرقام المكررة داخل هذه النافذة: **403، 404، 407، 414، 421، 422، 423، 425، 458، 484، 485، 496**. يحمل Report422 وReport425 وReport496 ثلاثة ملفات مختلفة لكل رقم. لذلك الرقم وحده ليس هوية تقرير كافية؛ يجب استخدام اسم الملف الكامل والرابط ومحتواه.
- لا يجوز إعادة استخدام رقم تقرير جديد متعارض، أو افتراض أن التقرير الأعلى رقمًا يملك الحقيقة الأحدث دون مطابقة حالته مع Current Source وProduction.

### 1.2 ما تعلمته من خط التاريخ

| المرجع | الدرس المعتمد في هذا التنفيذ |
|---|---|
| Report400 | يمكن تنفيذ إصلاح Production وتسجيله، مع ترك الجراحة الأمامية للمالك؛ يجب فصل الحالتين. |
| Report401 ثم Report402 | لا تكرر Patch موجودًا بالفعل في Current Git. تقرير لاحق صحح checkpoint متأخرًا، ولم ينفذ جراحة زائدة. |
| Reports403–407 | نجاح RPC أو قراءة SQL لا يثبت أن المتصفح يعرض النتيجة؛ ولا يجوز الخلط بين مشكلة عرض ومشكلة عقد مالي/تشغيلي. |
| Report408 | تغييرات النظام الأم تُسلّم كـOwner Change Set عندما يمنع الدستور المساعد من تحريره مباشرة. |
| Report481 | تصحيح اتجاه المهمة قبل التعديل أهم من البناء على رقعة صحيحة لكنها تخص الملف أو المهمة الخطأ. |
| Report482 | المطلوب مقارنة الدورة الوظيفية كاملة مع الحفاظ على الوظائف المجاورة، وليس نقل جزء من واجهة مرجعية عشوائيًا. |
| Report486 | Resolve scope conflict أولًا؛ سجّل ما هو موجود، وما ينقص، وما لا يجوز تغييره، وماذا يملكه المساعد مقابل المالك. |
| Report488 | ترتيب الرقع ومحددات الاستبدال جزء من سلامة التصحيح؛ لا تجمع patches قديمة إذا كانت دوال المساعدة أو handlers لم توجد في ذلك الترتيب. |
| Reports497–499 | المصدر والـCore والـEdge والبيانات المنشورة أدلة منفصلة. وجود commit أو RPC لا يثبت Artifact منشورًا ولا Browser E2E. |
| Report500 | النظام الأم والتطبيقات التشغيلية وحدات منظومة واحدة؛ يجب تتبع مصدر البيانات ودورة العمل، لا التعامل مع كل شاشة كجزيرة مستقلة. |

تفاصيل مرجعية: [Report402](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report402_POS_CURRENT_SOURCE_PRODUCTION_RECONCILIATION_20261010.md)، [Report481](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report481_LOADER_RUNSHEET_CLICK_DETAILS_SCOPE_CORRECTION_20261023.md)، [Report486](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report486_LOADER_TARGET_SCOPE_CORRECTION_AND_PATCH_CONSOLIDATION_20261024.md)، [Report488](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report488_LOADER_DAILY_REVALIDATION_PATCH_ORDER_CORRECTION_20261024.md)، [Report497](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report497_LOADER_PICKER_FULL_CORRECTED_OWNER_PATCH_20261025.md)، [Report500](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report500_RAWAEA_ERP_MIND_MAP_20261025.md).

## 2. تصحيح مسار التنفيذ السابق

### 2.1 ما الذي كان خطأ؟

أُنشئ PR #5 سابقًا ويحتوي تغييرات على `companies/company-1/main.html` في فرع مستقل. رغم أنه لم يُدمج، فإن إنشاء مثل هذا التغيير كان خروجًا عن نموذج التنفيذ المنصوص عليه للملفات التشغيلية المحمية: تجهيز Owner Change Set ليس تصريحًا بنقل الملف التشغيلي إلى مسار تحرير المساعد.

### 2.2 الإجراء التصحيحي

- PR #5 أُغلق، غير مدموج، بعنوان **SUPERSEDED — owner-only delivery assignment correction (do not merge)**.
- لم يُطبق bundle الـRPC الموجود داخل PR #5.
- المصدر الحالي للنظام الأم لم يتغير. فرع `main` تحرك فقط بإضافة ملفات Migration مصدرية مساعدة لـSupabase.
- لم تُنشأ خطط توصيل أو سجلات مندوبين أو تكليفات أو بيانات اختبار في Production.
- الرقعة التي تلي هذا القسم هي النسخة المرجعية الوحيدة المقترحة للمالك في هذه الجولة؛ لا تُنسخ الرقعة القديمة من PR #5.

[PR #5 المغلق للتوثيق فقط — لا تدمجه](https://github.com/papamohammed77-glitch/erp-frontend/pull/5).

## 3. هوية Current Source والبيانات الحية

### 3.1 المصدر

- مستودع التشغيل: `papamohammed77-glitch/erp-frontend`.
- أحدث HEAD بعد حفظ ملفات Migration المصدرية: `7ce460f68de85f50a176341cc6a5e8fc58167045`.
- ملف Parent المستهدف: `companies/company-1/main.html`.
- SHA الحالي لملف Parent عند التحقق: `1f60ecc6eefba3a669a5aa01512da269453c9ed5`.
- لم يتغير Blob الخاص بـ`main.html` عبر commits حفظ ملفات Migration؛ يظل Owner Change Set بحاجة إلى إعادة تحقق SHA قبل تطبيقه.

### 3.2 Production — حقائق مؤكدة بالقراءة المباشرة

- الشركة: `00000000-0000-0000-0000-000000000001`.
- الرانشيتان `RS-1` بتاريخ 2026-10-10 و`RS-2` بتاريخ 2026-10-12 حالتهما `Loaded`، ولكل منهما `runsheets.deliverer_id` صالح.
- `delivery_logistics_query(...,'agents',...)` يعيد التكليفين في `runsheet_assignments`، ويعيد أربعة حسابات نشطة غير مرتبطة بسجل `delivery_agents` في `unregistered_delivery_users`.
- المستخدمون الأربعة بدور `مندوب توصيل` هم: مندوب توصيل، مندوب توصيل 2، مندوب توصيل 3، مندوب توصيل 4. لا يوجد لأي منهم سجل مطابق في `delivery_agents`.
- أعداد `delivery_agents` و`delivery_route_plans` و`delivery_route_stops` للشركة ما زالت صفرًا.
- `delivery_logistics_query(...,'routes',...)` يعيد `success=true, rows=[]` لأن خطة المسار كيان مستقل لا توجد له سجلات حاليًا.
- لم يُنشأ صف تجريبي في أي من هذه الجداول، ولا يوجد Probe record باقٍ.

### 3.3 تفسير علاقة الكيانات

- `users`: حساب الدخول والدور والصلاحيات.
- `delivery_agents`: السجل التشغيلي/التعاقدي للمندوب؛ كود المندوب ونوع التعاقد والبيانات التشغيلية.
- `runsheets.deliverer_id`: التكليف الفعلي الذي سجله المشرف على الرانشيت.
- `delivery_route_plans`: خطة مسار مستقلة قد تُنشأ بعد التكليف.
- `delivery_route_stops`: المحطات التي تنتمي إلى خطة المسار.

لا ينبغي إنشاء سجل مندوب أو خطة مسار تلقائيًا لمجرد عرض البيانات. المطلوب أن يعرض النظام حقيقة الحساب والتكليف وخطة المسار كلًّا في مكانه، مع ربطها بصريًا، وإجراء التسجيل الصريح عندما يحدد المسؤول كود المندوب المعتمد.

## 4. تغييرات Supabase التي نُفذت بالفعل

هذه تغييرات على الوظائف الموجودة، وليست وظائف أو جداول جديدة. لم تُغيَّر صلاحيات التنفيذ أو RLS/ACL؛ تم التحقق بعدها من أن `authenticated EXECUTE=true` و`anon EXECUTE=false` بقيتا على الدوال ذات الصلة.

### 4.1 إضافة القراءة الصريحة للحسابات غير المرتبطة

**Migration:** `delivery_agents_unregistered_users_read_contract_20261029`.

أُضيف إلى استجابة `agents` حقل `unregistered_delivery_users` يُرجع الحسابات النشطة بدور `مندوب توصيل` التي لا يوجد لها سجل في `delivery_agents`، مع نطاق الشركة وبحث/ترقيم صفحات من Payload الحالي. الحقول المعادة: user_id، name، email، phone، status. لم يُنشأ سجل مستخدم أو مندوب.

[مصدر Migration في مستودع التشغيل](https://github.com/papamohammed77-glitch/erp-frontend/blob/main/supabase/migrations/20261029_delivery_agents_unregistered_users_read_contract.sql).

### 4.2 حماية ربط المستخدم في أمر المندوب الموجود

**Migration:** `delivery_agent_user_link_company_guard_20261029`.

أضيف حارس داخل `delivery_logistics_command_atomic` في أمري `AGENT_CREATE` و`AGENT_UPDATE`: إذا أُرسل user_id، فيجب أن يكون مستخدمًا نشطًا تابعًا للشركة نفسها. بذلك لا يعتمد أمان الربط على `readonly` في الواجهة وحده. الأمر والـRPC موجودان أصلًا؛ لم تُنشأ دالة جديدة.

تم تمرير اختبار رفض لمعرّف مستخدم غير موجود داخل كتلة اختبار معزولة. أعادت قراءة لاحقة صفر صفوف لأي `PROBE` في `delivery_agents` وصفر عمليات اختبار في `erp_operation_registry`.

[مصدر Migration في مستودع التشغيل](https://github.com/papamohammed77-glitch/erp-frontend/blob/main/supabase/migrations/20261029_delivery_agent_user_link_company_guard.sql).

### 4.3 توحيد نافذة تاريخ المسار مع تاريخ الرانشيت

**Migration:** `delivery_routes_use_runsheet_date_window_20261029`.

الدالة الحالية كانت تصفي `routes` حسب تاريخ إنشاء خطة المسار `p.created_at`، بينما واجهة العرض والتكليفات تستعمل تاريخ الرانشيت `r.run_date`. استبدلت هذا الشرط وحده ليعكس نافذة التاريخ التشغيلية نفسها، مع بقاء شكل الاستجابة ونطاق الشركة وبقية فروع الدالة كما كانت.

[مصدر Migration في مستودع التشغيل](https://github.com/papamohammed77-glitch/erp-frontend/blob/main/supabase/migrations/20261029_delivery_routes_use_runsheet_date_window.sql).

### 4.4 التحقق بعد التطبيق

| الفحص | النتيجة الفعلية |
|---|---|
| قراءة `agents` RPC بعد التحديث | `success=true`; التكليفان RS-1 وRS-2 ما زالا موجودين؛ أربع حسابات غير مرتبطة معادة في الحقل الجديد |
| قراءة `routes` RPC | `success=true, rows=[]` بما يتسق مع عدم وجود خطط مسار حاليًا |
| دوال القراءة والكتابة | `SECURITY DEFINER` بقي موجودًا، وصلاحيات التنفيذ لم تتسع |
| حارس user_id | الفحص الساكن يثبت إدراجه في الإنشاء والتحديث؛ اختبار رفض معزول مرّ، ولا توجد Probe rows باقية |
| بيانات الأعمال | `delivery_agents=0`, `delivery_route_plans=0`, `delivery_route_stops=0`; لا بيانات تشغيلية جديدة |
| الواجهة المنشورة | لم يتم اختبارها بعد التعديل؛ لا ادعاء نشر أو E2E |

المحاولة الأولى لتطبيق read-contract migration أُوقفت من أداة Supabase بسبب `COMMIT` صريح داخل غلاف التطبيق. تحققت من أن الدالة لم تتغير، وأن migration لم تُسجل في ذلك الوقت، ثم أعدت المحاولة دون BEGIN/COMMIT صريح. لا أثر لهذه المحاولة الفاشلة في Production.

## 5. Owner Surgical Change Set — النظام الأم فقط

**لا تكتب هذه الكتل إلى ملف التشغيل من جانب المساعد.** المالك يطبقها بعد إعادة جلب `main.html` والتحقق أن SHA لا يزال `1f60ecc6eefba3a669a5aa01512da269453c9ed5`. إذا تغير SHA أو تغيّر نص محدد البحث، أعد التحديد على المصدر الجديد ولا تلصق الرقعة القديمة.

### 5.1 Patch A — استبدال الدالة routes() كاملة فقط

**موضع البداية الأصلي:** `async function routes(){`  
**موضع النهاية:** قبل `async function openRoute(id){` مباشرة.

الهدف: استخدام الـcontracts الموجودين `routes` و`agents.runsheet_assignments` في جدول واحد. لا تعدل RPC لهذا العرض، ولا تنشئ خططًا أو محطات تلقائيًا. يحفظ الصف على الرانشيت نوعه `assignment` ولا يسمح بفتحه كمعرّف خطة. إذا كانت الخطة ملغاة وكان التكليف الحالي لا يزال قائمًا، يظهر سجل الخطة الملغاة والسجل الحالي في صفين متميزين.

~~~javascript
  async function routes(){
    var fromDate=new Date(Date.now()-86400000*30).toISOString().slice(0,10);
    var toDate=new Date(Date.now()+86400000*14).toISOString().slice(0,10);
    var d=await q('routes',{from_date:fromDate,to_date:toDate,limit:200,offset:0});
    S.cache.routes=d.rows||[];

    var assignmentData=null,assignments=[],assignmentLoadError='';
    try{
      assignmentData=await q('agents',{search:'',status:'',limit:500,offset:0});
      assignments=Array.isArray(assignmentData.runsheet_assignments)?assignmentData.runsheet_assignments:[];
    }catch(e){
      assignmentLoadError=e&&e.message?e.message:'تعذر تحميل التكليفات الفعلية';
    }
    assignments=assignments.filter(function(a){
      return a.run_date&&a.run_date>=fromDate&&a.run_date<=toDate;
    });

    var agentIndex=Object.create(null);
    (assignmentData&&Array.isArray(assignmentData.rows)?assignmentData.rows:[]).forEach(function(a){
      if(a&&a.id)agentIndex[String(a.id)]=a;
    });
    var rows=S.cache.routes.map(function(x){
      var row=Object.assign({},x);
      row.record_type='route_plan';
      row.assignment=row.status==='Cancelled'?null:
        assignments.find(function(a){return a.runsheet_code===row.runsheet_code;})||null;
      return row;
    });
    var activePlanByRunsheet=Object.create(null);
    rows.forEach(function(x){
      if(x.runsheet_code&&x.status!=='Cancelled')activePlanByRunsheet[x.runsheet_code]=true;
    });
    assignments.forEach(function(a){
      if(activePlanByRunsheet[a.runsheet_code])return;
      rows.push({
        id:a.runsheet_id,
        plan_code:null,
        status:a.status,
        runsheet_status:a.status,
        runsheet_code:a.runsheet_code,
        run_date:a.run_date,
        vehicle_id:a.vehicle_id||null,
        driver_id:a.driver_id||null,
        vehicle_code:null,
        delivery_agent_id:null,
        delivery_agent_name:null,
        stop_count:null,
        planned_total_km:null,
        planned_duration_minutes:null,
        collected_amount:null,
        created_at:null,
        record_type:'assignment',
        assignment:a
      });
    });
    rows.sort(function(a,b){
      var ad=String(a.run_date||''),bd=String(b.run_date||'');
      if(ad!==bd)return bd.localeCompare(ad);
      return String(b.created_at||'').localeCompare(String(a.created_at||''));
    });

    var statusLabels={
      Draft:'مسودة',Planned:'مخططة',InProgress:'جارية',Completed:'مكتملة',Cancelled:'ملغاة',
      Loaded:'محملة',Delivering:'جاري التوصيل',Delivered:'تم التوصيل',Returning:'عائدة/مرتجعة'
    };
    var bodyRows=rows.map(function(x){
      var isAssignment=x.record_type==='assignment';
      var a=x.assignment||null;
      var runStatus=a?a.status:(x.runsheet_status||'');
      var planStatus=x.status||'';
      var shownStatus=isAssignment?runStatus:planStatus;
      var statusTone=shownStatus==='Completed'||shownStatus==='Delivered'?'ok':
        (shownStatus==='Cancelled'?'bad':
        (shownStatus==='Loaded'||shownStatus==='Delivering'||shownStatus==='Returning'||shownStatus==='InProgress'?'warn':'info'));
      var statusCell=isAssignment
        ?badge(statusLabels[shownStatus]||shownStatus,statusTone)+'<div style="margin-top:4px">'+badge('تكليف فعلي — بلا خطة مسار','warn')+'</div>'
        :badge(statusLabels[planStatus]||planStatus,statusTone);
      if(!isAssignment&&a){
        statusCell+='<div style="font-size:11px;color:#64748b;margin-top:4px">حالة الرانشيت: '+esc(statusLabels[runStatus]||runStatus)+'</div>';
        if(planStatus!==runStatus){
          statusCell+='<div style="font-size:11px;margin-top:4px">'+badge('حالة الخطة والرانشيت مختلفة','warn')+'</div>';
        }
      }

      var planAgent=x.delivery_agent_name||'';
      var planAgentRow=x.delivery_agent_id?agentIndex[String(x.delivery_agent_id)]:null;
      var planAgentUserId=planAgentRow&&planAgentRow.user_id?String(planAgentRow.user_id):'';
      var assignedName=a&&a.deliverer_name?a.deliverer_name:'';
      var assignedUserId=a&&a.deliverer_user_id?String(a.deliverer_user_id):'';
      var agentCell='';
      if(isAssignment){
        agentCell='<div><b>'+esc(assignedName||('مستخدم '+(a.deliverer_user_id||'')))+'</b></div>';
        agentCell+='<div style="font-size:11px;margin-top:4px">'+badge(a.delivery_agent_code?'مرتبط بسجل لوجستي':'حساب غير مرتبط بسجل لوجستي',a.delivery_agent_code?'ok':'warn')+'</div>';
      }else if(planAgent&&assignedName){
        if(planAgentUserId&&assignedUserId&&planAgentUserId===assignedUserId){
          agentCell='<div><b>'+esc(planAgent)+'</b></div><div style="font-size:11px;margin-top:4px">'+badge('إسناد الخطة والرانشيت متطابق','ok')+'</div>';
        }else{
          agentCell='<div><b>مندوب الخطة:</b> '+esc(planAgent)+'</div><div style="margin-top:4px"><b>تكليف الرانشيت:</b> '+esc(assignedName)+'</div>';
          agentCell+='<div style="margin-top:4px">'+badge(planAgentUserId&&assignedUserId?'تعارض مصدر الإسناد':'تعذر إثبات تطابق الهوية',planAgentUserId&&assignedUserId?'bad':'warn')+'</div>';
        }
      }else if(planAgent){
        agentCell='<div><b>'+esc(planAgent)+'</b></div><div style="font-size:11px;margin-top:4px">'+badge(a?'لا توجد هوية مشتركة مثبتة':'مندوب خطة المسار',a?'warn':'info')+'</div>';
      }else if(assignedName){
        agentCell='<div><b>'+esc(assignedName)+'</b></div><div style="font-size:11px;margin-top:4px">'+badge(a&&a.delivery_agent_code?'تكليف مرتبط بسجل لوجستي':'تكليف الرانشيت غير مرتبط بسجل لوجستي',a&&a.delivery_agent_code?'ok':'warn')+'</div>';
      }else{
        agentCell=badge('غير مسند','warn');
      }

      var firstCell=isAssignment
        ?'<b>'+esc(x.runsheet_code)+'</b><div style="font-size:11px;color:#b45309;margin-top:4px">تكليف محفوظ على الرانشيت</div>'
        :'<b>'+esc(x.plan_code||'خطة توصيل')+'</b><div style="font-size:11px;color:#94a3b8">'+esc(x.runsheet_code)+'</div>'+
          (x.status==='Cancelled'&&assignments.some(function(z){return z.runsheet_code===x.runsheet_code;})?'<div style="font-size:11px;margin-top:4px">'+badge('خطة ملغاة؛ التكليف الحالي معروض في صف مستقل','warn')+'</div>':'');
      var vehicleCell=x.vehicle_code?esc(x.vehicle_code):(x.vehicle_id?badge('مركبة مرتبطة','info'):'—');
      var stopsCell=isAssignment?badge('لا توجد محطات بخطة مسار','warn'):(x.stop_count==null?'—':esc(x.stop_count));
      var distanceCell=isAssignment?badge('لم تُحدد بعد','warn'):
        (x.planned_total_km==null?'—':money(x.planned_total_km)+' كم'+
         '<div style="font-size:11px;color:#94a3b8">'+(x.planned_duration_minutes==null?'—':money(x.planned_duration_minutes)+' د')+'</div>');
      var collectedCell=isAssignment?'—':(x.collected_amount==null?'—':money(x.collected_amount)+' EGP');
      var actions=isAssignment
        ?(canManage()&&shownStatus==='Loaded'
          ?btn('إنشاء خطة مسار','plan-new:'+esc(x.runsheet_code),'px-3 py-2 rounded-xl bg-indigo-600 text-white font-bold')
          :badge('لا توجد خطة مسار','warn'))
        :('<div style="display:flex;gap:6px;flex-wrap:wrap">'+
          btn('فتح','route-open:'+esc(x.id),'px-3 py-2 rounded-xl bg-slate-100 text-slate-700 font-bold')+
          (canManage()&&x.status!=='Cancelled'?btn('تحسين','route-opt:'+esc(x.id),'px-3 py-2 rounded-xl bg-indigo-600 text-white font-bold'):'')+
          '</div>');
      return '<tr style="border-top:1px solid #eef2f7"><td class="p-3">'+firstCell+'</td>'+
        '<td class="p-3">'+statusCell+'</td><td class="p-3">'+agentCell+'</td>'+
        '<td class="p-3">'+vehicleCell+'</td><td class="p-3">'+stopsCell+'</td>'+
        '<td class="p-3">'+distanceCell+'</td><td class="p-3">'+collectedCell+'</td>'+
        '<td class="p-3">'+actions+'</td></tr>';
    }).join('');
    var table='<div style="overflow:auto"><table class="w-full"><thead><tr>'+
      ['الخطة / الرانشيت','الحالة التشغيلية','مصدر الإسناد والمندوب','المركبة','المحطات','المسافة / الزمن المخطط','التحصيل','إدارة'].map(function(h){return '<th class="p-3 text-right">'+h+'</th>';}).join('')+
      '</tr></thead><tbody>'+
      (bodyRows||'<tr><td colspan="8" class="text-center p-8 text-slate-400">لا توجد خطط أو تكليفات توصيل في الفترة المعروضة</td></tr>')+
      '</tbody></table></div>';
    var note='<div style="padding:10px 12px;border-radius:14px;background:#f8fafc;border:1px solid #eef2f7;color:#475569;font-size:12px;font-weight:700;margin-bottom:12px">'+
      'يعرض الجدول خطط المسارات والتكليفات الفعلية معًا. لا تُنشأ خطة أو محطة تلقائيًا. إذا اختلف مندوب الخطة عن مستخدم الرانشيت يظهر المصدران والتنبيه بدل إخفاء الاختلاف.'+
      '</div>';
    if(assignmentLoadError)note+='<div style="padding:10px 12px;border-radius:12px;background:#fff7ed;color:#9a3412;margin-bottom:12px">تعذر تحميل تكليفات الرانشيت؛ صفوف خطط المسار معروضة من المصدر الحالي، لكن لا يمكن تأكيد تكليفاتها: '+esc(assignmentLoadError)+'</div>';
    set(shell(card('الرحلات والمسارات','عرض موحد للتكليف الفعلي وخطة التوصيل والتنفيذ والتحصيل',note+table)));
  }
~~~

### 5.2 Patch B — استبدال الدالة agents() كاملة فقط

**موضع البداية الأصلي:** `async function agents(){`  
**موضع النهاية:** قبل `async function openAgentForm` مباشرة.

الهدف: توحيد السجل التشغيلي والحسابات التي تحتاج إلى استكماله في جدول «مناديب التوصيل المسجلون»، مع الحفاظ على بطاقة تعيينات الرانشيت وسلوك البحث القديم. لا تُعرض أرقام نشاط مختلقة للحساب الذي لا يملك سجلًا لوجستيًا؛ تبقى المقاييس `—`.

~~~javascript
  async function agents(){
    var d=await q('agents',{search:S.search,status:'Active',limit:200,offset:0});
    S.cache.agents=d.rows||[];
    var assignments=Array.isArray(d.runsheet_assignments)?d.runsheet_assignments:[];
    var userLinkContractAvailable=Array.isArray(d.unregistered_delivery_users);
    var unregisteredUsers=userLinkContractAvailable?d.unregistered_delivery_users:[];
    S.cache.unregisteredDeliveryUsers=unregisteredUsers;
    var registeredRows=S.cache.agents.map(function(a){
      return '<tr style="border-top:1px solid #eef2f7"><td class="p-3"><b>'+esc(a.agent_code||'—')+'</b></td>'+
        '<td class="p-3">'+esc(a.full_name||'—')+'</td><td class="p-3">'+esc(a.phone||'—')+'</td>'+
        '<td class="p-3">'+esc(a.email||'—')+'</td><td class="p-3">'+esc(a.employment_type||'—')+'</td>'+
        '<td class="p-3">'+esc(a.active_routes==null?'—':a.active_routes)+'</td>'+
        '<td class="p-3">'+(a.stops_delivered==null?'—':esc(a.stops_delivered))+' / '+(a.stops_total==null?'—':esc(a.stops_total))+'</td>'+
        '<td class="p-3">'+(a.collected_amount==null?'—':money(a.collected_amount)+' EGP')+'</td>'+
        '<td class="p-3">'+badge(a.user_id?'سجل لوجستي مرتبط بحساب':'سجل لوجستي مستقل',a.user_id?'ok':'warn')+'</td></tr>';
    }).join('');
    var unregisteredRows=unregisteredUsers.map(function(u){
      return '<tr style="border-top:1px solid #eef2f7"><td class="p-3"><b>—</b><div style="font-size:11px;color:#64748b;margin-top:3px">حساب فقط</div></td>'+
        '<td class="p-3">'+esc(u.name||'—')+'</td><td class="p-3">'+esc(u.phone||'—')+'</td>'+
        '<td class="p-3">'+esc(u.email||'—')+'</td><td class="p-3">'+badge('حساب مستخدم بلا سجل لوجستي','warn')+'</td>'+
        '<td class="p-3">—</td><td class="p-3">—</td><td class="p-3">—</td><td class="p-3">'+
        (canManage()?btn('استكمال التسجيل','agent-register-user:'+esc(u.user_id),'px-3 py-2 rounded-xl bg-indigo-600 text-white font-bold'):'—')+
        '</td></tr>';
    }).join('');
    var unregisteredEmpty=userLinkContractAvailable
      ?'لا توجد حسابات نشطة بدور مندوب توصيل تنتظر استكمال التسجيل.'
      :'عقد بيانات التوصيل لم يعِد قائمة الحسابات غير المرتبطة؛ لا يمكن اعتبار القائمة خالية حتى يُراجع عقد RPC المنشور.';
    var rows=registeredRows+unregisteredRows;
    var agentsTable='<div style="overflow:auto"><table class="w-full"><thead><tr>'+
      ['الكود / الحساب','المندوب / المستخدم','الهاتف','البريد الإلكتروني','نوع السجل','الرحلات النشطة','التوصيلات','التحصيل','إجراء'].map(function(h){return '<th class="p-3 text-right">'+h+'</th>';}).join('')+
      '</tr></thead><tbody>'+(rows||'<tr><td colspan="9" class="text-center p-8 text-slate-400">'+esc(unregisteredEmpty)+'</td></tr>')+
      '</tbody></table></div>';
    var assignmentRows=assignments.map(function(a){
      var statusLabels={Loaded:'محملة',Delivering:'جاري التوصيل',Delivered:'تم التوصيل',Returning:'عائدة/مرتجعة'};
      var agentLink=a.delivery_agent_code?esc(a.delivery_agent_code):'غير مرتبط بسجل مناديب اللوجستيات';
      return '<tr style="border-top:1px solid #eef2f7"><td class="p-3"><b>'+esc(a.runsheet_code)+'</b></td>'+
        '<td class="p-3">'+date(a.run_date)+'</td><td class="p-3">'+esc(a.deliverer_name||('مستخدم '+a.deliverer_user_id))+'</td>'+
        '<td class="p-3">'+badge(statusLabels[a.status]||a.status,'info')+'</td><td class="p-3">'+agentLink+'</td></tr>';
    }).join('');
    var assignmentTable='<div style="overflow:auto"><table class="w-full"><thead><tr>'+
      ['الرانشيت','التاريخ','مندوب التوصيل المسند فعليًا','حالة الرانشيت','ربط سجل اللوجستيات'].map(function(h){return '<th class="p-3 text-right">'+h+'</th>';}).join('')+
      '</tr></thead><tbody>'+(assignmentRows||'<tr><td colspan="5" class="text-center p-8 text-slate-400">لا توجد رانشيتات مسندة إلى مندوبي التوصيل في الحالات المعروضة.</td></tr>')+
      '</tbody></table></div>';
    set(shell(
      card('مناديب التوصيل المسجلون','سجل المندوبين التشغيلي، مع إظهار حسابات التوصيل التي تحتاج إلى استكمال ربطها بسجل لوجستي.',input('dl-agent-search','بحث',S.search||'','text','style="max-width:340px;margin-bottom:12px"')+agentsTable)+
      card('تعيينات الرانشيت من مشرف التوصيل','التكليف الفعلي محفوظ في runsheets.deliverer_id ويظل ظاهرًا مستقلًا عن سجل المندوب اللوجستي.',assignmentTable)
    ));
    var search=E('dl-agent-search');
    if(search)search.oninput=function(){S.search=this.value;setTimeout(function(){agents().catch(function(e){toast(e.message,'error');})},180)};
  }
~~~

### 5.3 Patch C — استبدال openAgentForm() كاملة فقط

**موضع البداية الأصلي:** `async function openAgentForm(){`  
**موضع النهاية:** قبل `async function collections(){` مباشرة.

الهدف: إبقاء نموذج تسجيل المندوب الحالي، مع دعم اختيار حساب موجود وتعبئة بياناته وقفل user_id في الواجهة. يظل كود المندوب المعتمد مطلوبًا من المسؤول. الخادم يتحقق أيضًا من أن المستخدم المرتبط نشط ويتبع الشركة نفسها.

~~~javascript
  async function openAgentForm(existingUser){
    var selectedUser=existingUser||null;
    await modal(selectedUser?'استكمال التسجيل التشغيلي لحساب موجود':'تسجيل مندوب توصيل',
      input('da-code','كود المندوب المعتمد','')+
      input('da-name','الاسم الكامل',selectedUser?selectedUser.name:'')+
      input('da-phone','الهاتف',selectedUser?selectedUser.phone:'')+
      input('da-email','البريد الإلكتروني',selectedUser?selectedUser.email:'')+
      select('da-emp','نوع التعاقد','Employee',[['Employee','موظف'],['Contractor','متعاقد'],['Outsourced','شركة خارجية'],['PerTrip','بالنقلة'],['Monthly','بالشهر'],['Other','أخرى']])+
      select('da-status','الحالة','Active',[['Active','نشط'],['Inactive','غير نشط'],['Suspended','موقوف']])+
      input('da-user',selectedUser?'حساب المستخدم المرتبط':'User UUID — اختياري',selectedUser?selectedUser.user_id:'','text',selectedUser?'readonly':'placeholder="اربط حسابًا موجودًا فقط"')+
      input('da-branch','الفرع الافتراضي UUID — اختياري','','text'),
      async function(){
        if(!val('da-code')||!val('da-name'))throw new Error('كود واسم مندوب التوصيل مطلوبان');
        if(selectedUser&&val('da-user')!==selectedUser.user_id)throw new Error('تعذر مطابقة هوية المستخدم المختار');
        await c('AGENT_CREATE',{
          agent_code:val('da-code'),full_name:val('da-name'),phone:val('da-phone')||null,email:val('da-email')||null,
          employment_type:val('da-emp'),status:val('da-status'),user_id:val('da-user')||null,default_branch_id:val('da-branch')||null
        },'agent-create:'+val('da-code'));
        Swal.close();S.tab='agents';S.search='';await refresh();toast('تم تسجيل المندوب وربطه بحساب المستخدم المحدد','success');
      });
  }
~~~

### 5.4 Patch D — إدراج handler واحد داخل handle(action)

في الدالة الموجودة `async function handle(action){`، ابحث عن:

~~~javascript
      if(k==='agent-new'){return openAgentForm();}
      if(k==='plan-new'){return openPlanCreate(id);}
~~~

استبدل هذا المقطع الصغير بالآتي؛ لا تستبدل `handle()` كاملة:

~~~javascript
      if(k==='agent-new'){return openAgentForm();}
      if(k==='agent-register-user'){
        var selected=(S.cache.unregisteredDeliveryUsers||[]).find(function(u){return u.user_id===id;});
        if(!selected){
          var fresh=await q('agents',{search:'',status:'Active',limit:200,offset:0});
          S.cache.unregisteredDeliveryUsers=Array.isArray(fresh.unregistered_delivery_users)?fresh.unregistered_delivery_users:[];
          selected=S.cache.unregisteredDeliveryUsers.find(function(u){return u.user_id===id;});
        }
        if(!selected)throw new Error('حساب التوصيل لم يعد ضمن قائمة الحسابات غير المرتبطة؛ حدّث الشاشة');
        return openAgentForm(selected);
      }
      if(k==='plan-new'){return openPlanCreate(id);}
~~~

### 5.5 ما يجب أن يبقى دون تغيير

- لا تعديل في أي دالة أو ملف آخر، ولا إعادة كتابة `main.html` كاملة.
- لا تغيير في `AGENT_CREATE` payload غير استخدام user_id للحساب المختار، ولا تغيير في أي عقد مخزون/محاسبة.
- لا تُنشأ خطة مسار أو محطات من أجل إظهار الرانشيت.
- لا تُخفَ حالة تعارض مندوب الخطة مع مستخدم الرانشيت؛ يعرض الجدول المصدرين إذا لم يمكن إثبات التطابق.
- يبقى زر إنشاء الخطة على صف تكليف `Loaded` فقط ويستدعي مسار إنشاء الخطة الحالي. لا يفتح صف التكليف تفاصيل خطة لأنه ليس خطة.
- يبقى البحث القديم في جدول مناديب التوصيل حاضرًا؛ فُحص ذلك صراحة لأن فقده سيكون تراجعًا وظيفيًا.

## 6. نتائج الفحص الساكن والتشغيلي

أُعيد بناء Owner Change Set في الذاكرة بالاستناد إلى SHA الحالي، دون الكتابة إلى ملف التشغيل، ثم فُحصت الدوال المعدلة ووحدة `RW_DeliveryLogistics` كاملة عبر JavaScript parser.

| الاختبار | النتيجة |
|---|---|
| صياغة routes() البديلة | `PASS` |
| صياغة agents() البديلة | `PASS` |
| صياغة openAgentForm() البديلة | `PASS` |
| صياغة handler المضاف | `PASS` |
| صياغة وحدة RW_DeliveryLogistics الكاملة بعد تركيب التعديلات افتراضيًا | `PASS` |
| عدد تعريفات الدوال المستهدفة بعد التركيب | واحد لكل دالة |
| جدول واحد للخطط والتكليفات | invariant `PASS` |
| منع عدّ صف تكليف كأنه خطة مسار | invariant `PASS` |
| وضوح تعارض هوية المندوب | invariant `PASS` |
| الاحتفاظ بحقل البحث ومعالج البحث | invariant `PASS` |
| ثبات main.html الأصلي أثناء إعداد الرقعة | SHA لم يتغير |

هذه فحوص Static على Patch افتراضي قبل تطبيق المالك. لا تعني أن ملف HTML المنشور قد تغير أو أن سلوك المتصفح بعد النشر قد ثبت.

## 7. الاختبارات الإلزامية بعد تطبيق المالك ونشره

1. التحقق من حفظ الملف كاملًا وفحص JavaScript للملف كله، لا للمقاطع فقط.
2. فتح «إدارة التوصيل والشحن → الرحلات والمسارات» في جلسة مصادق عليها، وتأكيد أن RS-1 وRS-2 يظهران كصفَي تكليف فعلي بلا خطة، دون صفوف زائدة أو فتح غير صحيح للتفاصيل.
3. فتح «مناديب التوصيل»، وتأكيد أن الحسابات الأربعة تظهر في الجدول مع حالة «حساب مستخدم بلا سجل لوجستي»، وأن البحث يرشح المسجل وغير المسجل، وأن بطاقة تكليفات الرانشيت القديمة ما زالت تعمل.
4. اختيار أحد الحسابات الأربعة وفتح التسجيل، وتأكيد أن الاسم/البريد/الهاتف معبأة وأن user_id مقفل. لا تحفظ سجلًا حقيقيًا حتى يحدد المالك كود المندوب المعتمد ونوع التعاقد الصحيح.
5. اختبار رفض user_id غير نشط/من شركة أخرى عبر الحارس الخلفي، ثم التأكد من عدم حدوث أي إدخال.
6. تصوير Response من Network بعد تنقيته من الأسرار، وDOM/Console في الجلسة نفسها. يجب إثبات أن Cloudflare يقدم ملفًا مطابقًا للـcommit المعتمد.
7. التأكد من أن عدد الخطط والمحطات لم يتغير بمجرد فتح الواجهة، وأنه لا يوجد أثر في المخزون/الحسابات/سجل الحركة.
8. تحديث تقرير جديد فقط بعد ظهور النتائج الفعلية؛ لا تغير الحالة إلى `CLOSED` لمجرد أن patch أصبح موجودًا في Git.

## 8. Mutation Ledger

- **Supabase Production:** ثلاث تغييرات صغيرة على دالتين موجودتين: حقل قراءة للحسابات غير المرتبطة، وحارس نطاق شركة على user_id في AGENT_CREATE/AGENT_UPDATE، وتصحيح فلتر تاريخ routes ليستخدم تاريخ الرانشيت. جميعها موثقة في ملفات Migration source.
- **بيانات الأعمال:** لم تتغير؛ لم تُنشأ سجلات مناديب أو خطط مسارات أو محطات أو تكليفات أو مستخدمين.
- **المخزون/المحاسبة:** لم يحدث أي تغيير.
- **ACL/RLS/Edge Functions/جداول جديدة:** لم تتغير، ولم تُنشأ وظائف جديدة.
- **ملف النظام الأم:** لم يعدّله المساعد؛ SHA الحالي ما زال `1f60ecc6eefba3a669a5aa01512da269453c9ed5`.
- **PR #5:** مغلق وغير مدموج، لا تستخدمه؛ كان مسار تنفيذ خاطئًا للملف التشغيلي.
- **نشر Cloudflare:** لم يتم نشر تغيير HTML في هذه الجولة ولم يثبت Artifact منشور.
- **E2E المصادق عليه:** لم يتم.

## 9. SELF-AUDIT FINAL

**What I Proved**
- تمت دراسة نافذة التقارير 400–500 وجرد 114 ملفًا؛ تم تحديد الأرقام المتعارضة والمفقودة والمرجعيات التي تصحح الـpatch lineage.
- Current Git يملك بالفعل بطاقة تكليفات في `routes()` منفصلة عن جدول الخطط، بينما المطلوب التشغيلي هو جدول موحد.
- Production RPC يعيد التكليفين الحقيقيين والحسابات الأربعة غير المرتبطة.
- عقد القراءة الخلفي، الحارس على هوية المستخدم، وفلتر تاريخ الرانشيت طُبقت في الدوال القائمة وتم التحقق من تعريفاتها ونتائج الاستدعاء.
- تم تجهيز Owner Change Set كامل وفحص وحدة التوصيل كاملة ساكنًا.

**What I Did Not Prove**
- تطبيق المالك لتغييرات HTML.
- تطابق الـartifact الذي يقدمه Cloudflare مع SHA.
- استجابة Network/DOM/Console بعد المصادقة.
- أن النتيجة المنشورة تعرض RS-1/RS-2 كما هو مقصود.

**What I Initially Missed and Corrected**
- إعداد PR لتعديل `main.html` تجاوز حد الملكية؛ أغلقته دون دمج.
- بطاقة تكليفات منفصلة لا تحقق مطلب الجدول نفسه؛ رقعة routes() الجديدة تدمج المصادر دون خلط أنواع السجلات.
- مصدر حساب المستخدم يجب أن يبقى ظاهرًا حتى لو لم يكتمل سجل المندوب التشغيلي، لكن الاستكمال لا يجوز أن يكون تلقائيًا أو برمز مخترع.
- توحيد نافذة التاريخ ضروري حتى لا يُخلط تاريخ إنشاء خطة المسار بتاريخ الرانشيت التشغيلي.

**Final Status:** `PRODUCTION READ CONTRACT + COMPANY GUARDS + RUNSHEET DATE WINDOW APPLIED AND VERIFIED / OWNER MAIN.HTML CHANGESET READY / NOT DEPLOYED / AUTHENTICATED E2E OPEN / NOT CLOSED`.

**Next exact action:** المالك يطبق Patches A–D فقط على `main.html` بعد إعادة التحقق من SHA، ثم ينشر وفق سير العمل المعتمد ويثبت الاختبارات في القسم 7. لا تُعَد جراحة Production لهذا السبب مرة أخرى ما لم يظهر دليل جديد من المصدر أو الـRuntime.
