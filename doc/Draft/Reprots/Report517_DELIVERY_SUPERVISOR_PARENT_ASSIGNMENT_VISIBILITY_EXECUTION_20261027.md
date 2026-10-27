# Report517 — تحقيق فجوة ظهور تكليفات مشرف التوصيل داخل النظام الأم
**التاريخ:** 2026-10-27  
**Production observation:** 2026-10-27 16:39:15.184259+00  
**النطاق الوحيد:** النظام الأم → إدارة التوصيل والشحن → مناديب التوصيل، وعرض تكليفات الرانشيت التي يحفظها تطبيق مشرف التوصيل.  
**الحالة:** `ROOT CAUSE CONFIRMED / OWNER PATCH PACKAGE PREPARED / NOT APPLIED / NOT DEPLOYED / E2E OPEN`

## 1. PRE-CHANGE SELF-AUDIT

- **Business Understanding:** CONFIRMED — تعيين مندوب إلى رانشيت عبر مشرف التوصيل ليس هو نفسه تسجيل كيان إداري في `delivery_agents` ولا إسناد مندوب إلى `delivery_route_plans`.
- **Architecture Understanding:** CONFIRMED — تطبيق المشرف يحفظ التكليف في `runsheets.deliverer_id` من خلال RPC قائم؛ Parent لديه read model مستقل لقائمة `delivery_agents` وخطط المسار.
- **Database Understanding:** CONFIRMED — تمت إعادة قراءة تعريف RPCs وProduction rows ذات الصلة. لم تُنفذ كتابة على البيانات.
- **Historical Understanding:** CONFIRMED — تمت مراجعة CURRENT_STATE وأحدث تقارير 514–516 والرقعة المقترحة سابقًا. استُخدمت هذه المواد لتوجيه إعادة الفحص، لا كبديل عن المصدر والـProduction.
- **Production Understanding:** CONFIRMED — تم استعلام مباشر جديد في Production الساعة 16:39:15.184259 UTC.
- **Current Understanding:** CONFIRMED — أُعيد جلب blob الحالي للنظام الأم وملف supervisor من المستودع التشغيلي.
- **Execution Confidence:** HIGH في تشخيص فجوة القراءة؛ PARTIAL في تنفيذ الإغلاق لأن HTML التشغيلي للنظام الأم خاضع لقاعدة أن يدمجه المالك، ولم يُنشر بعد.

### مصادر المصدر الحالي

- Operational repo: `papamohammed77-glitch/erp-frontend`, branch `main`.
- Parent: `companies/company-1/main.html`, blob SHA `b9bd5698c98c4b3d7e2bc388bacfbf4f43f2a919`, حجم النص المسترجع 1,787,034 حرفًا، 33,136 سطرًا حسب الفحص السابق.
- موضع `async function agents()`: السطر 30,668 في هذا الـblob.
- Supervisor: `companies/company-1/delivery/supervisor.html`, blob SHA `3e6db903cd7da411f9ed40a449f9ee5bece5f387`.
- Parent blob أُعيد جلبه مباشرة عبر Git blob، وليس الاعتماد على Contents API الذي أعاد محتوى فارغًا.
- وجود الدوال المساعدة `user()`, `perms()`, `companyId()`, `date()`, `badge()` وواجهة RPC `q()` مؤكد في مصدر Parent الحالي. تمت مطابقة شرط صلاحية البطاقة المقترحة مع شرط RPC الفعلي؛ لا يُستخدم اسم الدور وحده لتجاوز قائمة الصلاحيات التي يفرضها الخادم.

## 2. Production evidence — Fresh

استعلام القراءة الأخير أعاد:

| Runsheet | Status | Run date | Deliverer | driver_id | vehicle_id |
|---|---|---|---|---|---|
| RS-2 | Loaded | 2026-10-12 | driver3@rawaea.com | NULL | `7e58a39d-e1f4-435f-a6f7-fa625a234333` |
| RS-1 | Loaded | 2026-10-10 | driver@rawaea.com | NULL | `69b08188-60ee-43af-9644-e1626a85bfa0` |

- `company_id` للسجلين: `00000000-0000-0000-0000-000000000001`.
- عدد الرانشيتات المسندة في الاستعلام السابق بهذه الجولة: 2.
- لم تُستخدم RS-1 أو RS-2 كبيانات اختبار، ولم تتغير.
- `delivery_supervisor_assignment_query(uuid,text)` موجودة كـSECURITY DEFINER وتتحقق من `auth.uid()` ثم تربط المستخدم عبر `public.users.auth_id`، وتتحقق من الشركة والصلاحيات. عرض `team` يعيد `users.id/name/email` للمندوبين النشطين ذوي permission `delivery`; وعرض `runsheets` يعيد `runsheet_code/run_date/status/deliverer_id` للرانشيتات ذات الصلة.
- `delivery_logistics_query` ما زالت تقرأ `delivery_agents` في view=`agents` و`delivery_route_plans` في view=`routes`. لا يربط view=`agents` تكليفات `runsheets.deliverer_id`؛ وهذا يثبت سبب عدم ظهور التكليف في بطاقة المندوبين الحالية.
- لم يحدث DDL/DML أو تغيير RPC/ACL/RLS/Edge في هذه الجولة.

## 3. السبب الجذري

**CONFIRMED — Read-model mismatch، لا فشل حفظ الإسناد.**

تطبيق مشرف التوصيل يحفظ التكليف في `runsheets.deliverer_id`. أما بطاقة Parent الحالية `agents()` فتعرض فقط `delivery_agents` مع مؤشرات مشتقة من `delivery_route_plans`. لذلك وجود تكليف محفوظ لا ينشئ تلقائيًا سجل Delivery Agent ولا Route Plan، ولا يظهر في بطاقة Parent الحالية.

الحل الآمن ضمن النطاق: إضافة بطاقة مستقلة **للقراءة فقط** بعنوان «تكليفات الرانشيت الحالية» بجانب قائمة Delivery Agent القائمة، باستخدام RPC القراءة الموجودة `delivery_supervisor_assignment_query`. لا تُنشئ Agent أو Route Plan تلقائيًا، ولا تغيّر مفاتيح/علاقات هوية المندوب والسائق والمركبة.

## 4. Owner ChangeSet — تعديل موضعي فقط

**الملف:** `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`  
**Blob SHA الذي تمت مطابقته:** `b9bd5698c98c4b3d7e2bc388bacfbf4f43f2a919`  
**الدالة:** `async function agents()`، يبدأ موضعها عند السطر 30,668 في هذا الـblob.  
**المالك هو من يدمج تعديل HTML التشغيلي.** لا تدّعِ أن الرقعة مطبقة قبل حفظها والتحقق منها.

### 4.1 أضف الدالة المساعدة التالية داخل نفس نطاق IIFE الخاص بـ`RW_DeliveryLogistics`، قبل `async function agents()`

```javascript
  async function assignedRunsheetsCard(){
    var p=perms();
    var allowed=p.indexOf('*')!==-1 ||
      p.indexOf('delivery_supervisor')!==-1 ||
      p.indexOf('fleet.read')!==-1 ||
      p.indexOf('fleet.manage')!==-1;
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
```

### 4.2 استبدل المقطع المحدد داخل `agents()` فقط

**ابحث عن بداية المقطع** `set(shell(card('مناديب التوصيل','هوية مستقلة عن سائق المركبة'`، داخل `async function agents()` الحالية.

**احذف المقطع الحالي بالكامل التالي فقط:**

```javascript
    set(shell(card('مناديب التوصيل','هوية مستقلة عن سائق المركبة',input('dl-agent-search','بحث','','text','style="max-width:340px;margin-bottom:12px"')+
      '<div style="overflow:auto"><table class="w-full"><thead><tr>'+['الكود','الاسم','الهاتف','نوع التعاقد','ربط التطبيق','الرحلات النشطة','التوصيلات','التحصيل'].map(function(h){return '<th class="p-3 text-right">'+h+'</th>';}).join('')+'</tr></thead><tbody>'+(
        rows||'<tr><td colspan="8" class="text-center p-8 text-slate-400">لا يوجد مناديب مسجلون</td></tr>')+'</tbody></table></div>')));
```

**واستبدله بهذا المقطع كاملًا:**

```javascript
    var agentsCard=card('مناديب التوصيل','هوية مستقلة عن سائق المركبة',input('dl-agent-search','بحث','','text','style="max-width:340px;margin-bottom:12px"')+
      '<div style="overflow:auto"><table class="w-full"><thead><tr>'+['الكود','الاسم','الهاتف','نوع التعاقد','ربط التطبيق','الرحلات النشطة','التوصيلات','التحصيل'].map(function(h){return '<th class="p-3 text-right">'+h+'</th>';}).join('')+'</tr></thead><tbody>'+(
        rows||'<tr><td colspan="8" class="text-center p-8 text-slate-400">لا يوجد مناديب مسجلون</td></tr>')+'</tbody></table></div>');
    var assignmentCard='';
    try{
      assignmentCard=await assignedRunsheetsCard();
    }catch(e){
      assignmentCard=card('تكليفات الرانشيت الحالية','تعذر تحميل بيانات الإسناد من المصدر المركزي',
        '<div style="padding:14px;border-radius:12px;background:#fef2f2;color:#991b1b;font-weight:800">'+esc(e.message||'تعذر تحميل تكليفات الرانشيت')+'</div>');
    }
    set(shell(agentsCard+assignmentCard));
```

**لا تحذف ولا تستبدل** سطر البحث التالي؛ يجب أن يظل كما هو:

```javascript
    var s=E('dl-agent-search'); if(s)s.oninput=function(){S.search=this.value;setTimeout(function(){agents().catch(function(e){toast(e.message,'error');})},180)};
```

### 4.3 أثر الرقعة وحدودها

- تحفظ بطاقة `delivery_agents` الحالية ومدخل البحث وسلوكها دون تغيير business contract.
- تضيف بطاقة مستقلة تقرأ التكليفات من RPC موجود، ولا تكتب إلى قاعدة البيانات.
- لا تنشئ `delivery_agents` أو `delivery_route_plans`، ولا تربط `users.id` مكان `delivery_agents.id`.
- لا تغير `supervisor.html` أو RPCs أو ACL/RLS.
- هذه الرقعة **لم تُطبق بعد**؛ إنها حزمة تغيير للمالك، وليست دليل نشر أو نجاح.

## 5. الاختبارات المطلوبة بعد الدمج

1. فحص JavaScript للصفحة كاملة (وليس المقطع وحده) والتأكد من عدم وجود syntax error.
2. تسجيل دخول Parent بحساب لديه `delivery_supervisor` أو `fleet.read`، وفتح «إدارة التوصيل والشحن → مناديب التوصيل».
3. التأكد من ظهور RS-1 باسم `driver@rawaea.com` وRS-2 باسم `driver3@rawaea.com`، مع الحالة والتاريخ.
4. التأكد أن قائمة Delivery Agent الإدارية ما زالت مستقلة ولا تختفي أو تتغير.
5. اختبار مستخدم غير مخول: لا تظهر بيانات التكليف له؛ ويجب أن يظل قرار الرفض من RPC في الخادم هو المرجع الأمني.
6. اختبار بحث القائمة القديمة، إسناد Route Plan، تفاصيل الرحلة، التحصيل، الأداء، والتحديث/إعادة المحاولة.
7. التحقق من الـHTML الذي يقدمه Cloudflare بعد النشر ومطابقته للمصدر المقصود.
8. تنفيذ E2E مصادق عبر واجهة المشرف ثم Parent؛ لا تستخدم RS-1/RS-2 كـfixtures ولا تعدل بياناتهما.

## 6. Mutation ledger

- Production SQL: قراءة فقط.
- Database/DDL/DML/RPC/ACL/RLS/Edge: لا تغيير.
- `supervisor.html`: لا تغيير.
- `main.html`: لم يعدله المساعد؛ تم إعداد Owner ChangeSet محدد مطابقًا للـblob الحالي.
- Test fixtures/business data: لا تغيير.
- Documentation: هذا التقرير + تحديث CURRENT_STATE فقط.

## 7. SELF-AUDIT FINAL

- **What I Proved:** التكليف محفوظ في Production في `runsheets.deliverer_id`; RS-1 وRS-2 مرتبطان بمندوبيهما؛ RPC القراءة المركزية موجودة ومقيدة بالشركة والمستخدم؛ Parent agents view الحالي يقرأ `delivery_agents` لا تكليفات `runsheets`.
- **What I Did Not Prove:** ظهور البطاقة بعد الدمج، اختبار متصفح/HTTP مصادق، نشر Cloudflare، أو نجاح E2E.
- **What I Fixed:** لم أغير الكود التشغيلي أو بيانات الأعمال؛ أعددت تغييرًا جراحيًا كاملًا مطابقًا للمصدر الحالي، وحددت ما يجب أن يدمجه المالك.
- **What I Initially Missed:** المشكلة في اختلاف read model وليست فشل حفظ الإسناد. كذلك يجب أن يطابق فحص الواجهة شرط ACL/RPC حرفيًا؛ تم تصحيح الرقعة قبل اعتمادها كي لا تعتبر أسماء الأدوار وحدها تصريحًا غير موجود في عقد RPC.
- **What Could Still Be Wrong:** قد تظهر فجوة صلاحيات/تهيئة في بيئة Parent فعلية؛ يجب اختبارها بعد الدمج. لا يُعد فحص SQL وحده اختبار HTTP/JWT.
- **Final Confidence:** HIGH لتشخيص السبب؛ MEDIUM لسلامة تصميم الرقعة؛ NOT VERIFIED runtime.
- **Final Closure Status:** `PARTIAL — ROOT CAUSE CONFIRMED / OWNER PATCH PREPARED / NOT APPLIED / NOT DEPLOYED / E2E OPEN`.
