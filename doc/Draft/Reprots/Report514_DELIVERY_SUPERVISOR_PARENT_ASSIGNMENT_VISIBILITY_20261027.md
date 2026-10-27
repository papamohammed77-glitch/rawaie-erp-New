# تقرير التنفيذ والتحقق — Report514
## إظهار تكليفات Delivery Supervisor داخل النظام الأم دون إنشاء نموذج لوجستي موازٍ

**التاريخ:** 2026-10-27  
**النتيجة:** PARTIALLY COMPLETED — السبب الجذري مؤكد، والرقعة الجراحية جاهزة للمالك، ولم يُدّعَ تطبيقها أو نشرها.  
**النطاق الحالي:** تدفق قراءة التكليفات من Delivery Supervisor إلى Parent ERP → إدارة التوصيل والشحن → مناديب التوصيل.  
**مرجع البداية:** Report507 وReport508؛ لم تُعد إصلاحات واجهة المشرف أو RPC الإسناد، لأن المصدر الحالي وProduction يثبتان أن الإسناد محفوظ أصلًا.

---

## A. الملخص التنفيذي

هذه الجولة لم تعد إلى إصلاح صفحة المشرف أو إعادة نشر عقد الإسناد المركزي؛ فهما موجودان بالفعل في المصدر الحالي وProduction. أُعيد فحص المصدرين والـRPCs والبيانات الحية، ثم نفذت قراءة عقدية مباشرة أثبتت أن:

1. واجهة المشرف الحالية تستخدم RPC الإسناد الذري وتكتب التكليف في **runsheets.deliverer_id** باستخدام **public.users.id**.
2. هناك تكليفان محفوظان في Production حاليًا: RS-1 وRS-2، وكلاهما Loaded وله deliverer_id.
3. تبويب Parent ERP المسمى «مناديب التوصيل» لا يقرأ علاقة runsheets.deliverer_id؛ بل يقرأ **public.delivery_agents** ويشتق عدد الرحلات من **public.delivery_route_plans**.
4. نتيجة استعلام Parent الحالي كانت **agents.rows = []** و **routes.rows = []**؛ كما أن عددي delivery_agents وdelivery_route_plans يساويان صفرًا في الشركة الحالية.

إذًا هذا ليس دليلًا على فشل حفظ تكليف المشرف. المشكلة هي فجوة العرض بين نموذج تكليف الرانشيت ونموذج سجل المندوب/خطة الرحلة في مركز اللوجستيات.

**قرار الإصلاح:** اختيار إصلاح Read Model في واجهة Parent لعرض تكليفات الرانشيت القائمة كقسم قراءة فقط داخل تبويب «مناديب التوصيل»، باستخدام RPC القراءة المركزية الموجودة **delivery_supervisor_assignment_query**. يبقى سجل **delivery_agents** الإداري وإسناد الخطط إلى **delivery_route_plans.delivery_agent_id** كما هما. هذا الخيار لا ينشئ Agent records افتراضية، ولا يخلق Route Plans دون بيانات تخطيط مكتملة، ولا يغير دورة الأعمال أو RPC الإسناد.

**لم أعدّل أي ملف HTML تشغيليًا، ولم أجرِ أي DDL/DML أو تغيير بيانات في Production.** القيود الحاكمة تجعل تعديل main.html من مسؤولية المالك عبر رقعة محددة؛ لذلك حالة الرقعة أدناه PROPOSED وليست APPLIED.

---

## B. مصادر الحقيقة التي أُعيد فحصها

### B1. المصدر التشغيلي

- المستودع: papamohammed77-glitch/erp-frontend
- الفرع: main
- الملف: companies/company-1/delivery/supervisor.html
- Blob SHA الحالي: 3e6db903cd7da411f9ed40a449f9ee5bece5f387
- الحجم المقروء: 307 أسطر تقريبًا.
- HEAD المشاهد: fb0499a03a357b9fc5f7a605302ffd845f8a5052.

المصدر الحالي يستخدم:
- delivery_supervisor_assignment_query لقراءة dashboard/team/runsheets.
- delivery_supervisor_assign_deliverer_atomic للإسناد وفكه.
- p_company_id وp_runsheet_code وp_deliverer_user_id وp_operation_id في عقد الإسناد.
- deliverer_id لهوية مندوب التوصيل، دون استخدامه بديلًا عن driver_id أو vehicle_id.

**القرار:** لا توجد مبررات لتكرار تعديل supervisor.html أو إعادة بناء عقد الإسناد. RETAINED.

### B2. المصدر الحالي للنظام الأم

- الملف: companies/company-1/main.html
- Blob SHA: b9bd5698c98c4b3d7e2bc388bacfbf4f43f2a919
- تم جلب Git blob الكامل وفحص مقاطع الوظائف المطلوبة؛ محتويات الملف كبيرة، لذلك لم أعتمد على fetch_file الذي أعاد محتوى فارغًا لهذا الملف.

في وحدة RW_DeliveryLogistics:
- agents() يستدعي delivery_logistics_query مع p_view = agents.
- قائمة المندوبين تتكون من صفوف public.delivery_agents فقط.
- active_routes مشتق من public.delivery_route_plans.
- routes() يقرأ delivery_route_plans ويعرض delivery_agent_name.
- assignAgent() يرسل delivery_agent_id إلى عقد ROUTE_AGENT_ASSIGN.
- يوجد فصل صريح بين سجل مندوب التوصيل الإداري وبيانات تشغيل المركبة/السائق.

**النتيجة:** Parent لم يملك في المسار الحالي قسمًا يعرض تكليفات runsheets.deliverer_id بصورة مستقلة عن ملف Delivery Agent وخطة Route Plan.

### B3. الوثائق السابقة ونقطة التوقف

- Report507_DELIVERY_SUPERVISOR_PARENT_INTEGRATION_ROOT_CAUSE_20261027.md — Blob SHA: aba96bb3406c80a007840cd2e2db376d872e2499.
- Report508_DELIVERY_SUPERVISOR_PARENT_INTEGRATION_STAGING_DRIFT_20261027.md — Blob SHA: 2ede468a20859f306a47b18314081a55ea43dd65.
- MASTER_CTO_EXECUTION_PROMPT_LOADER_PICKER_INTEGRATION_20261025.md — Blob SHA: abfa9d376c455ad7466b9404eed6f0a2c2166ede.
- writing-block.md — Blob SHA: 8929b54e04ef848e814a21f6ecdfb97bf8c7952d.
- CURRENT_STATE.md قبل هذا التقرير — Blob SHA: 85de3aae4a910db469a733ba86360ce1eb2351b6.

Report507 وReport508 سبق أن أثبتا انقسام نموذج القراءة، ودوّنا تعذر E2E وStaging drift. هذه الجولة **لم تكرر إصلاحات المشرف أو الميجريشن**؛ بل أعادت التحقق المباشر من Production واختارت البديل الأقل تغييرًا: عرض العلاقة الموجودة بدل اختراع ملفات أو خطط جديدة.

---

## C. دليل Production الحالي

**مشروع Supabase:** fiilmooggumokxanwiyx  
**إصدار PostgreSQL:** 17.6  
**وقت snapshot الذي أعادته قاعدة البيانات:** 2026-10-27T14:47:48.217349+00:00.

| الفحص | نتيجة القراءة الحالية |
|---|---|
| عدد الشركات | 1 |
| عدد الرانشيتات | 2 |
| الرانشيتات ذات deliverer_id | 2 |
| public.delivery_agents للشركة | 0 |
| public.delivery_route_plans للشركة | 0 |
| public.delivery_route_stops للشركة | 0 |
| الطلبات المرتبطة برانشيتات | 6 |

### C1. الرانشيتات المحفوظة

| Runsheet | الحالة | deliverer_id | driver_id | vehicle_id |
|---|---|---|---|---|
| RS-1 | Loaded | 0912a68e… | NULL | موجود |
| RS-2 | Loaded | 5fc15ecf… | NULL | موجود |

تمت مطابقة كل deliverer_id مع public.users.id لمستخدم نشط يحمل صلاحية delivery. لا يظهر driver_id مسندًا في هذين الصفين، وهذا لا يمنع صحة تكليف مندوب التوصيل لأن السائق والمندوب حقلا مسؤولية منفصلان.

### C2. اختبار عقد القراءة المركزي الموجود

نفذت استدعاءين للقراءة فقط، دون إنشاء أو تعديل بيانات:

**1. delivery_logistics_query('agents')**  
النتيجة: success=true وrows فارغة.

**2. delivery_logistics_query('routes')**  
النتيجة: success=true وrows فارغة.

الاستدعاءان استخدما هوية مشرف موجودة وسياق الشركة الحالي ضمن اختبار SQL؛ هذا ليس اختبار HTTP/JWT أو Browser.

**3. delivery_supervisor_assignment_query تحت claim محاكى داخل Transaction ثم ROLLBACK**  
النتيجة:
- team: أربعة مستخدمين نشطين مؤهلين بصلاحية delivery.
- runsheets: RS-1 وRS-2، وكلاهما Loaded ويحمل deliverer_id.
- لم تُنفذ أي كتابة أعمال؛ وانتهت المعاملة بـROLLBACK.

هذا يثبت أن عقد قراءة التكليفات الحالي يرجع العلاقة التي تحتاج الشاشة لعرضها، وأنه يمكن إعادة استخدامه بدل إنشاء RPC أو جدول جديد. **لا يثبت ذلك نجاح المتصفح الحقيقي أو نشر HTML على Cloudflare.**

### C3. العلاقات المثبتة

- runsheets.deliverer_id → public.users.id.
- runsheets.driver_id → public.users.id.
- runsheets.vehicle_id → public.vehicles.id.
- delivery_route_plans.runsheet_id → public.runsheets.id.
- delivery_route_plans.delivery_agent_id → public.delivery_agents.id.
- delivery_agents.user_id موجود كحقل ربط اختياري بين سجل Delivery Agent وحساب المستخدم.

وجود الروابط لا يعني أن سجل Delivery Agent أو Route Plan يُنشأ تلقائيًا عند تكليف المشرف؛ Production يثبت أن ذلك لا يحدث في عقد الإسناد الحالي.

---

## D. السبب الجذري وتقييم البدائل

### السبب الجذري المؤكد

السبب هو اختلاف مصدر القراءة وليس عدم حفظ التكليف:

Supervisor → delivery_supervisor_assign_deliverer_atomic → runsheets.deliverer_id

بينما Parent → delivery_logistics_query('agents') → public.delivery_agents

ومركز المسارات → delivery_route_plans.delivery_agent_id → delivery_route_plans.runsheet_id.

لا توجد عملية مزامنة حالية بين عقد الإسناد المباشر وعقد سجل المندوب/خطة الرحلة، ولا توجد سجلات في delivery_agents أو delivery_route_plans في snapshot الحالي. لذلك تظهر شاشة Parent بحالة فارغة رغم وجود إسنادات صحيحة في runsheets.

### البدائل التي لم أعتمدها ولماذا

1. **إعادة تعديل supervisor.html:** مرفوض؛ المصدر الحالي يستخدم RPC مركزيًا بالفعل، والإسنادات موجودة في Production.
2. **إنشاء delivery_agents تلقائيًا لكل مستخدم delivery:** لم أعتمده؛ يتطلب توليد agent_code وemployment_type وبيانات سجل المندوب دون عقد معتمد يحدد القيم، وقد يخلق بيانات رئيسية تخمينية.
3. **إنشاء delivery_route_plans تلقائيًا عند الإسناد:** لم أعتمده؛ الخطة لها lifecycle خاص ومدخلات تخطيط ومحطات وحالة، ولا يجوز إنشاء خطة تشغيلية لمجرد إظهار التكليف.
4. **إنشاء جدول ربط جديد أو Edge Function جديدة:** غير مطلوب؛ المخطط الحالي وRPCs الموجودة تكفي لإظهار العلاقة.
5. **إجراء DDL/DML في Production أو ترقيع Staging المتباعد:** غير مبرر لهذه المعالجة؛ اختيار قراءة مركزية موجودة يتجنب الاعتماد على Staging الذي أثبت Report508 أنه غير متطابق مع Production.

### القرار المختار

إضافة بطاقة قراءة فقط بعنوان «تكليفات الرانشيت الحالية» داخل تبويب Parent «مناديب التوصيل»، تقرأ team وrunsheets عبر delivery_supervisor_assignment_query الموجود، وتربط كل runsheet بـdeliverer_id ثم تعرض اسم المستخدم/الرانشيت/التاريخ/الحالة. تظل بطاقة delivery_agents الحالية كما هي. لا يتم تغيير ROUTE_AGENT_ASSIGN أو إنشاء Plan أو Agent.

هذه معالجة عرض مستدامة للعرض المطلوب، وتحافظ على عقود المسؤولية الحالية. لا تعني أن تكليف المشرف صار تعيين Route Plan؛ يبقى ذلك Workflow مستقلًا حتى يصدر قرار أعمال صريح بدمجه.

---

## E. الرقعة الجراحية الموجهة للمالك — PROPOSED

**لا تطبق هذا التعديل بواسطة هذه الجولة؛ HTML التشغيلية محكومة بتطبيق المالك.** يجب إعادة جلب SHA ومطابقة النص الأصلي قبل التطبيق.

### Patch 1 — إضافة helper قراءة التكليفات

- **المستودع/الفرع:** papamohammed77-glitch/erp-frontend / main.
- **الملف:** companies/company-1/main.html.
- **Blob SHA الذي فُحص:** b9bd5698c98c4b3d7e2bc388bacfbf4f43f2a919.
- **الموضع الحالي:** قبل الدالة async function agents()، عند السطر التقريبي 30668.
- **محدد بحث فريد:** async function agents(){ ضمن IIFE RW_DeliveryLogistics.
- **الإضافة المقترحة:** helper جديد باسم assignedRunsheetsCard. لا تستبدل agents() بالكامل ولا تغيّر q('agents') أو منطق route plan.

~~~javascript
  async function assignedRunsheetsCard(){
    var actor=user()||{},p=perms();
    var allowed=p.indexOf('*')!==-1 ||
      p.indexOf('delivery_supervisor')!==-1 ||
      p.indexOf('fleet.read')!==-1 ||
      p.indexOf('fleet.manage')!==-1 ||
      ['مدير عام','مدير مخازن','مدير مالي'].indexOf(actor.role)!==-1;
    if(!allowed){
      return card('تكليفات الرانشيت الحالية','عرض مستقل عن سجل Delivery Agent وخطة Route Plan',
        '<div style="padding:14px;border-radius:12px;background:#fffbeb;color:#92400e;font-weight:800">لا تتوفر صلاحية قراءة تكليفات الرانشيت في هذا السياق.</div>');
    }
    var company=companyId();
    if(!company)throw new Error('سياق الشركة غير محدد');
    var results=await Promise.all([
      supabase.rpc('delivery_supervisor_assignment_query',{p_company_id:company,p_view:'team'}),
      supabase.rpc('delivery_supervisor_assignment_query',{p_company_id:company,p_view:'runsheets'})
    ]);
    if(results[0].error)throw new Error(results[0].error.message);
    if(results[1].error)throw new Error(results[1].error.message);
    if(!results[0].data||results[0].data.success===false)throw new Error('فشل قراءة فريق التوصيل');
    if(!results[1].data||results[1].data.success===false)throw new Error('فشل قراءة تكليفات الرانشيت');
    var team=(results[0].data.rows)||[],all=(results[1].data.rows)||[];
    var people=Object.create(null);
    team.forEach(function(x){people[String(x.id)]=x;});
    var assigned=all.filter(function(x){return !!x.deliverer_id;});
    var rows=assigned.map(function(r){
      var person=people[String(r.deliverer_id)]||{};
      var status=String(r.status||'—');
      var kind=status==='Loaded'?'info':status==='Delivering'?'warn':status==='Delivered'?'ok':'muted';
      return '<tr style="border-top:1px solid #eef2f7">'+
        '<td class="p-3"><b>'+esc(person.name||person.email||'هوية غير ظاهرة في قائمة الفريق')+'</b></td>'+
        '<td class="p-3">'+esc(r.runsheet_code||'—')+'</td>'+
        '<td class="p-3">'+esc(date(r.run_date))+'</td>'+
        '<td class="p-3">'+badge(status,kind)+'</td></tr>';
    }).join('');
    var body='<div style="overflow:auto"><table class="w-full"><thead><tr>'+
      ['مندوب التوصيل','الرانشيت','التاريخ','الحالة'].map(function(h){return '<th class="p-3 text-right">'+h+'</th>';}).join('')+
      '</tr></thead><tbody>'+
      (rows||'<tr><td colspan="4" class="text-center p-8 text-slate-400">لا توجد رانشيتات مسندة إلى مندوبي التوصيل ضمن حالات المتابعة الحالية.</td></tr>')+
      '</tbody></table></div>';
    return card('تكليفات الرانشيت الحالية',
      'قراءة فقط من runsheets.deliverer_id عبر RPC مركزي مقيّد بالشركة؛ لا ينشئ Route Plan أو Delivery Agent',
      body);
  }
~~~

### Patch 2 — عرض البطاقة دون تغيير سجل Delivery Agent

- **المحدد الحالي:** داخل agents()، السطر الذي يبدأ بـ:
  set(shell(card('مناديب التوصيل','هوية مستقلة عن سائق المركبة',...
- **التغيير المحدود:** احتفظ بمحتوى بطاقة مناديب التوصيل الحالي بالكامل، وسمّ الناتج agentsCard بدل استدعاء set مباشرة. بعد إغلاق card الحالية، أضف:

~~~javascript
    var assignmentCard='';
    try{
      assignmentCard=await assignedRunsheetsCard();
    }catch(e){
      assignmentCard=card('تكليفات الرانشيت الحالية','تعذر تحميل بيانات الإسناد من المصدر المركزي',
        '<div style="padding:14px;border-radius:12px;background:#fef2f2;color:#991b1b;font-weight:800">'+esc(e.message||'تعذر تحميل تكليفات الرانشيت')+'</div>');
    }
    set(shell(agentsCard+assignmentCard));
~~~

- **الإبقاء على:** مدخل البحث وقائمة delivery_agents الحالية، وحقول agent_code/full_name/user_id، وآلية إسناد delivery_route_plans عبر ROUTE_AGENT_ASSIGN.
- **عدم فعل:** لا تستبدل IDs الخاصة بـdelivery_agents بـpublic.users.id. لا تُغير p_view='agents' أو طريقة اختيار المندوب للخطة. لا تكتب على runsheets أو delivery_agents. لا تعرض UUIDs الخام في الواجهة.

**مهم قبل التطبيق:** النص الحالي داخل agents() يجب أن يُطابق حرفيًا بعد إعادة الجلب لأن الموضع أعلاه يصف نقطة الإدراج وليس إذنًا باستبدال الدالة كاملة. لا تدّعِ أن الرقعة مطبقة أو مفحوصة نحويًا حتى يطبقها المالك وتُفحص الصفحة كاملة.

---

## F. مصفوفة المسؤوليات Loss/Gain

| المسؤولية | الحالة | الدليل/القرار |
|---|---|---|
| حفظ تكليف مندوب على الرانشيت | RETAINED | RPC الحالي يكتب runsheets.deliverer_id |
| هوية مندوب التوصيل | RETAINED | public.users.id مع صلاحية delivery |
| السائق التشغيلي | RETAINED | runsheets.driver_id مستقل |
| المركبة | RETAINED | runsheets.vehicle_id مستقل |
| سجل Delivery Agent الإداري | RETAINED | delivery_agents له دورة مستقلة وحقول خاصة |
| خطة المسار | RETAINED | delivery_route_plans له lifecycle منفصل |
| عرض التكليف في Parent | MISSING | agents() لا يقرأ deliverer_id أو عقد runsheets |
| إظهار التكليف بقراءة فقط | PROPOSED | الرقعة المقترحة تستدعي RPC قراءة موجودًا |
| جدول أو RPC جديد | INTENTIONALLY NOT ADDED | غير مطلوب لمعالجة العرض |
| مزامنة إنشاء Route Plan مع تكليف المشرف | UNKNOWN / OUT OF SCOPE | لم يُثبت أن عملية إسناد المشرف مطالبة بإنشاء خطة توصيل |

---

## G. نتائج الاختبارات والبوابات

### اختبارات منفذة

| الاختبار | النتيجة | دليل وحدود الاستنتاج |
|---|---|---|
| استرجاع supervisor.html الحالي | PASS | Blob SHA 3e6db903cd7da411f9ed40a449f9ee5bece5f387 |
| فحص main.html current source | PASS | Git blob b9bd5698c98c4b3d7e2bc388bacfbf4f43f2a919؛ 33,136 سطرًا |
| قراءة Production schema/relations | PASS | الـFKs والحقول المذكورة في القسم C |
| Parent agents query | PASS — returns empty | delivery_logistics_query('agents') أعاد rows=[] في Production |
| Parent routes query | PASS — returns empty | delivery_logistics_query('routes') أعاد rows=[] في Production |
| Supervisor query تحت Auth claim محاكى | PASS — SQL only | team=4، runsheets=RS-1 وRS-2؛ تم ROLLBACK |
| HTTP/JWT من الواجهة | NOT RUN | لا توجد جلسة HTTP مصادق عليها في هذه الجولة |
| Browser E2E بعد تطبيق رقعة Parent | NOT RUN | الرقعة لم تُطبق |
| Cloudflare served HTML parity | UNVERIFIED | لم تتوفر قرينة مباشرة على الـHTML المنشور |
| اختبار صلاحيات كل أدوار Parent | NOT RUN | لم تُجرَ جلسات Browser مستقلة |
| Cleanup لبيانات الاختبار | NOT APPLICABLE | لم تُنشأ أي بيانات اختبار |
| Regression لباقي Route Plan/Collections | NOT RUN | لا تعديل مطبق حتى الآن |

### Execution Gates

| Gate | الحالة | السبب |
|---|---|---|
| 0 — Directive and Scope Lock | PASS | قرئت المهمة الجديدة والحوكمة العامة؛ جرى حصر النطاق في إظهار تكليفات المشرف |
| 1 — Current-State and Source Verification | PASS | أُعيد فحص supervisor.html وmain.html وProduction وReport507/508 |
| 2 — Reproduce and Localize | PASS على مستوى البيانات/العقد؛ PARTIAL على مستوى Browser | ثبت أن المخزن يحفظ التكليف بينما Parent query يقرأ نموذجًا فارغًا؛ Browser reproduction غير منفذ |
| 3 — Root-Cause Confirmation and Design | PASS | فجوة Read Model مؤكدة؛ اختير العرض المباشر بدل إنشاء Agent/Route Plan تلقائي |
| 4 — Pre-Change Safety Review | PASS للفحص فقط | لا DDL/DML أو تعديل مصدر؛ رقعة Parent تقرأ فقط |
| 5 — Controlled Implementation | BLOCKED / PROPOSED | الحوكمة تمنع تطبيق HTML التشغيلية مباشرة؛ الرقعة تنتظر تطبيق المالك |
| 6 — Contract/Auth/Data Integrity | PARTIAL | القراءة تستخدم RPC الحالي المقيّد بالشركة؛ لم يُختبر Browser/HTTP أو كل الأدوار |
| 7 — End-to-End Functional Acceptance | BLOCKED | لم تُطبق الرقعة ولم يُنفذ E2E |
| 8 — Deployment/Runtime | BLOCKED | لا دليل Cloudflare served-artifact أو نشر رقعة |
| 9 — Final Audit/Closure | PARTIAL | تقرير الأدلة والرقعة جاهزان، لكن التغيير التشغيلي والـE2E مفتوحان |

---

## H. سجل التغييرات (Mutation Ledger)

- Production DDL/DML: لا تغيير.
- Production data: لا تغيير.
- Supabase RPC/ACL/RLS/Edge: لا تغيير.
- supervisor.html: لا تغيير.
- main.html: لا تغيير.
- Staging schema/migrations: لا تغيير في هذه الجولة.
- Git operational source: لا تغيير.
- Report514: توثيق وPatch proposal فقط.
- CURRENT_STATE.md: تحديث هذا الحدث في مقدمة السجل دون حذف التاريخ السابق.

---

## I. المخاطر المفتوحة والإجراء الدقيق لإغلاقها

1. **تطبيق الرقعة:** على المالك إعادة جلب main.html SHA الحالي ثم تطبيق الإضافة الموضعية فقط.
2. **Static parse:** بعد تطبيق الرقعة، تحليل كل JavaScript داخل الصفحة كاملة، وليس المقطع الجديد فقط.
3. **اختبار Parent بصلاحيات مختلفة:** على الأقل مستخدم delivery_supervisor، وfleet.read أو fleet.manage. تحقق من أن عدم سماح RPC لا يخفي قائمة agents الأصلية أو ينتج نجاحًا زائفًا.
4. **اختبار عرض:** بعد تسجيل الدخول للنظام الأم، فتح «إدارة التوصيل والشحن → مناديب التوصيل». يجب أن تظهر RS-1 وRS-2 باسمَي مندوبيهما، التاريخ والحالة، فيما تظل قائمة سجل delivery_agents مستقلة.
5. **اختبار فصل المسؤوليات:** يجب أن يبقى إسناد Route Plan من خلال delivery_agents.id، ولا يجوز أن تستخدم القائمة user.id كـdelivery_agent_id.
6. **اختبار Regression:** تحقق من route assignment وroute detail وcollections وperformance؛ يجب أن تظل النماذج الحالية مستقلة.
7. **Deployment:** بعد تطبيق المصدر والنشر، قارن Cloudflare-served HTML بالمصدر/الالتزام المقصود.
8. **E2E:** نفذ HTTP/Browser مصادقًا عليه عبر تدفق المشرف بعد التطبيق ثم تحقق من البيانات المعروضة في Parent. لا تستخدم RS-1 أو RS-2 كبيانات اختبار أو تعدّلها خلال التحقق.
9. **Staging:** إن تقرر اختبار Staging، لا تعِد تشغيل migration اللوجستيات المعطوبة قبل إصلاح lineage/schema/audit وفق تقرير مستقل. هذه الرقعة لا تحتاج إلى migration جديدة لتجربة عرض read-model.

---

## J. القرار النهائي

- هل الإسناد موجود في قاعدة البيانات؟ **CONFIRMED** — RS-1 وRS-2 يحملان deliverer_id.
- هل Parent agents query يعرض هذه العلاقة حاليًا؟ **CONFIRMED NO** — يعتمد على delivery_agents ويعيد rows فارغة.
- هل ثبت السبب الجذري؟ **CONFIRMED** — اختلاف Read Model عن مصدر إسناد الرانشيت.
- هل تم تعديل الكود التشغيلي؟ **NO** — الرقعة PROPOSED بسبب حظر تعديل main.html مباشرة.
- هل تم نشر إصلاح؟ **NO / UNVERIFIED**.
- هل نجح Browser/HTTP E2E؟ **NOT RUN**.
- هل الإغلاق الكامل مثبت؟ **لا**.

**النتيجة الإجمالية:** PARTIALLY COMPLETED — ROOT CAUSE CONFIRMED / READ-MODEL PATCH PROPOSED / NO PRODUCTION MUTATION / PARENT E2E OPEN / NOT CLOSED.

**لا تعِد إصلاح supervisor.html أو RPC الإسناد.** الخطوة التالية هي تطبيق الرقعة الجراحية في Parent ثم اختبارها في الجلسة المصادق عليها، والتحقق من HTML المنشور.

---

## ملحق تنفيذي — Patch 2 بصيغة استبدال حرفي محدود

هذا الملحق يضبط موضع تعديل agents() بدقة حتى لا يضطر المالك لاستنتاج الأقواس أو إعادة كتابة الدالة. يجب أولًا التأكد من أن Blob SHA لا يزال b9bd5698c98c4b3d7e2bc388bacfbf4f43f2a919.

**محدد البحث:** العبارة الحالية داخل agents():

~~~javascript
    set(shell(card('مناديب التوصيل','هوية مستقلة عن سائق المركبة',input('dl-agent-search','بحث','','text','style="max-width:340px;margin-bottom:12px"')+
      '<div style="overflow:auto"><table class="w-full"><thead><tr>'+['الكود','الاسم','الهاتف','نوع التعاقد','ربط التطبيق','الرحلات النشطة','التوصيلات','التحصيل'].map(function(h){return '<th class="p-3 text-right">'+h+'</th>';}).join('')+'</tr></thead><tbody>'+
        rows||'<tr><td colspan="8" class="text-center p-8 text-slate-400">لا يوجد مناديب مسجلون</td></tr>')+'</tbody></table></div>')));
~~~

**الاستبدال المحدود المقترح لهذا المقطع فقط:**

~~~javascript
    var agentsCard=card('مناديب التوصيل','هوية مستقلة عن سائق المركبة',input('dl-agent-search','بحث','','text','style="max-width:340px;margin-bottom:12px"')+
      '<div style="overflow:auto"><table class="w-full"><thead><tr>'+['الكود','الاسم','الهاتف','نوع التعاقد','ربط التطبيق','الرحلات النشطة','التوصيلات','التحصيل'].map(function(h){return '<th class="p-3 text-right">'+h+'</th>';}).join('')+'</tr></thead><tbody>'+
        rows||'<tr><td colspan="8" class="text-center p-8 text-slate-400">لا يوجد مناديب مسجلون</td></tr>')+'</tbody></table></div>');
    var assignmentCard='';
    try{
      assignmentCard=await assignedRunsheetsCard();
    }catch(e){
      assignmentCard=card('تكليفات الرانشيت الحالية','تعذر تحميل بيانات الإسناد من المصدر المركزي',
        '<div style="padding:14px;border-radius:12px;background:#fef2f2;color:#991b1b;font-weight:800">'+esc(e.message||'تعذر تحميل تكليفات الرانشيت')+'</div>');
    }
    set(shell(agentsCard+assignmentCard));
~~~

لا تستبدل سطر البحث الذي يلي المقطع؛ يجب أن يبقى:

~~~javascript
    var s=E('dl-agent-search'); if(s)s.oninput=function(){S.search=this.value;setTimeout(function(){agents().catch(function(e){toast(e.message,'error');})},180)};
~~~

هذه الرقعة مكوّنة من helper جديد + تغيير اسم ناتج البطاقة الحالية + إضافة البطاقة الثانية. لا تستبدل agents() كاملة، ولا تغيّر أي دالة أخرى. حالة هذه الرقعة ما زالت PROPOSED.
