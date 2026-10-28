# Report541 — إعادة بناء سبب اختفاء تكليفات التوصيل من «الرحلات والمسارات» ومزامنة الحالة

**وقت الرصد الحي:** 2026-10-28 21:21:45Z إلى 21:22:57Z (UTC)؛ التاريخ المحلي في مصر 2026-10-29.  
**النطاق:** النظام الأم المنشور، Parent source، Production PostgreSQL/RPC، تكليفات RS-1 وRS-2، تبويبا «الرحلات والمسارات» و«مناديب التوصيل».  
**النتيجة:** ROOT CAUSE CONFIRMED — OWNER FILE CHANGE REQUIRED للمسار «الرحلات والمسارات». بوابة الواجهة المنشورة في تبويب «مناديب التوصيل» ما زالت UNVERIFIED لعدم توفر تفاعل متصفح/DOM حديث لهذا التبويب.

## 1. PRE-CHANGE SELF-AUDIT

- **Business Understanding — CONFIRMED:** الإسناد التشغيلي الفعلي محفوظ في **runsheets.deliverer_id**. خطة المسار كيان مختلف محفوظ في **delivery_route_plans** ويرتبط بالرانشيت عبر **runsheet_id**.
- **Architecture Understanding — CONFIRMED:** النظام الأم يحتوي مسارات منفصلة للخطط (routes)، والرانشيتات المرشحة للتخطيط (planning)، وسجل مناديب اللوجستيات والتكليفات الفعلية (agents).
- **Database Understanding — CONFIRMED:** في Production لا توجد صفوف في **delivery_route_plans** أو **delivery_route_stops** للشركة محل الفحص، بينما توجد رانشيتان مسندتان.
- **Historical Understanding — CONFIRMED:** Report538 وReport540 يوثّقان إصلاحًا سابقًا في **RW_DeliveryLogistics.agents()** يعرض **runsheet_assignments** في بطاقة منفصلة؛ لم أكرر ذلك الإصلاح.
- **Production Understanding — CONFIRMED:** استعلامات قراءة مباشرة بتاريخ 2026-10-28 21:20–21:22Z، واستدعاء مباشر للـRPC في Production.
- **Current Understanding — CONFIRMED:** ملف **companies/company-1/main.html** في **papamohammed77-glitch/erp-frontend** يحمل blob SHA **0c1745081e8d17480433ed527d77cac9f5292021**، ويتضمن الإصلاح السابق لبطاقة التكليفات في **agents()**.
- **Execution Confidence:** عالٍ في تشخيص عقد البيانات ومصدر الاختلاف؛ متوسط في سلوك الواجهة المنشورة؛ لا يوجد ادعاء بإغلاق E2E كامل.

### حقائق / فجوات

- **CONFIRMED:** **owner@alrawae.com** نشط، و**permissions=["*"]**، و**auth_id=0a6089e6-0c33-4cf9-9aa0-31fc42774b89**. يطابق هذا الـauth_user المسجل في طلبات RPC المنشورة بتاريخ 21:03Z.
- **CONFIRMED:** RS-1 وRS-2 موجودتان، حالتهما **Loaded**، ولكل منهما **deliverer_id** صالح ضمن الشركة نفسها.
- **CONFIRMED:** الاستدعاء المباشر لـ**delivery_logistics_query(...,'agents',...)** أعاد **success=true** و**runsheet_assignments** تحتوي RS-1 وRS-2، بينما **rows=[]** لأن سجل **delivery_agents** الإداري فارغ.
- **CONFIRMED:** استدعاء **routes** أعاد **rows=[]**، وعدد خطط المسار صفر.
- **CONFIRMED:** واجهة **routes()** في المصدر تستعلم من **q('routes',...)** وترسم صفوف **delivery_route_plans** فقط؛ لا تقرأ **runsheet_assignments**.
- **CONFIRMED:** **planning()** يستخدم نافذة تاريخ افتراضية من اليوم إلى سبعة أيام لاحقة؛ RS-1 وRS-2 بتاريخي 2026-10-10 و2026-10-12 خارج تلك النافذة.
- **UNVERIFIED:** هل بطاقة التكليفات تظهر حاليًا في الواجهة المنشورة عند فتح تبويب «مناديب التوصيل» تحديدًا.
- **UNVERIFIED:** هوية artifact الذي يقدمه Cloudflare ومطابقته الدقيقة لنسخة Git.
- **UNVERIFIED:** DOM/Console/Network body حديث لتبويب «مناديب التوصيل». لم تتوفر أداة تفاعل متصفح في هذه الجلسة؛ لا يُستنتج منها فشل RPC أو فشل العرض.

## 2. الأدلة الحية

### 2.1 بيانات Production

استعلام Production عند **2026-10-28 21:19:36.748312+00** أعاد:

| Runsheet | الحالة | المندوب | Company |
|---|---|---|---|
| RS-1 | Loaded | driver@rawaea.com | 00000000-0000-0000-0000-000000000001 |
| RS-2 | Loaded | driver3@rawaea.com | 00000000-0000-0000-0000-000000000001 |

استعلام العدّ عند **2026-10-28 21:20:17.384086+00**:

- **delivery_agents = 0**
- **delivery_route_plans = 0**
- **delivery_route_stops = 0**
- الرانشيتات بحالات التوصيل المشمولة = **2**

هذه نتيجة متسقة: الإسناد موجود في سجل الرانشيت، لكن لا توجد خطة مسار مسجلة بعد. لم تُنشأ أي سجلات اصطناعية.

### 2.2 عقد RPC

التوقيع الحي: **delivery_logistics_query(uuid,text,jsonb,uuid,text)**.

- **SECURITY DEFINER**
- **search_path=public**
- عند وجود **auth.uid()**، تُحل هوية المستخدم من **public.users.auth_id=auth.uid()** مع الشركة والحالة.
- فرع **agents** يعيد سجل المندوبين في **rows** ويعيد تكليفات الرانشيت منفصلة في **runsheet_assignments**.
- فرع **routes** يعيد صفوف **delivery_route_plans** فقط.
- فرع **planning** يقرأ **runsheets** ضمن **run_date BETWEEN v_from AND v_to**.

لا يوجد دليل على خلل في RPC يبرر تغيير قاعدة البيانات أو ACL/RLS.

### 2.3 Parent source

المستودع: **papamohammed77-glitch/erp-frontend**، الفرع **main**.  
الملف: **companies/company-1/main.html**.  
Blob: **0c1745081e8d17480433ed527d77cac9f5292021**.  
Commit الإصلاح السابق: **cb62612a174f5b1a8d5aa5a41a4c3e5747bb73fc**.

- **q(view,payload)** يستدعي **delivery_logistics_query** مع **p_actor_user_id:null**؛ وهذا متوافق مع عقد Production عندما تكون جلسة Auth صالحة.
- **agents()** يقرأ **d.runsheet_assignments** ويعرض بطاقة مستقلة بعنوان «تعيينات الرانشيت من مشرف التوصيل».
- **routes()** يستدعي **q('routes',...)**، ثم يعرض **d.rows** في جدول خطط المسار. إذا كانت القائمة فارغة، يعرض «لا توجد خطط توصيل».
- لذلك لا يمكن أن تظهر RS-1 وRS-2 في جدول «الرحلات والمسارات» الحالي؛ فالـconsumer لا يطلب التكليفات أصلًا، وProduction لا يحتوي خطط مسار.

## 3. Root Cause

### السبب المثبت

هناك **فجوة عرض/تكامل بين عقدين مختلفين**، وليست فجوة بيانات أو هوية:

1. **تكليف الرانشيت بمندوب**: **runsheets.deliverer_id** — موجود في Production.
2. **خطة توصيل ومسار**: **delivery_route_plans** مع محطاتها في **delivery_route_stops** — لا توجد منها سجلات في Production.

واجهة «الرحلات والمسارات» تعرض العقد الثاني فقط. لذلك إسناد الرانشيت في تطبيق مشرف التوصيل لا يجعله يظهر في جدول الخطط ما لم تُنشأ خطة مسار عبر دورة التخطيط. هذا السلوك يفسّر الشاشة الحالية، لكنه لا يثبت أن غياب الخطط خطأ بيانات؛ لا ينبغي إنشاء خطة تلقائيًا أو اختراع إحداثيات/سرعات/محطات لمجرد ملء الجدول.

### ما لا يزال غير محسوم

المصدر الحالي يحتوي بالفعل على بطاقة التكليفات في تبويب «مناديب التوصيل»، وRPC يعيد التكليفين. لم أتمكن من فتح ذلك التبويب داخل جلسة مصادق عليها حديثة وفحص DOM له؛ لذا لا أكرر إصلاح **agents()** ولا أغير RPC/ACL/RLS دون دليل جديد. إذا لم تظهر البطاقة في ذلك التبويب، فالخطوة التالية هي إثبات نسخة Cloudflare الفعلية أو التقاط استجابة/DOM للطلب؛ لا مشاركة أي كلمة مرور أو Cookie أو JWT أو Authorization header.

## 4. الإصلاح الجراحي المطلوب في النظام الأم

**وفق بروتوكول المشروع، لا أعدّل companies/company-1/main.html مباشرة؛ مالك النظام يطبق هذا التغيير.** التعديل المطلوب محدود إلى دالة **routes()** فقط، دون تغيير RPC أو البيانات أو دورة إنشاء الخطة.

### موضع التعديل

في **companies/company-1/main.html**، داخل **async function routes()** (حوالي السطر 30626 في blob الحالي)، ابحث عن السطر الأصلي:

~~~javascript
    set(shell(card('الرحلات والمسارات','خطة مقابل تنفيذ ومحصلة مالية',table)));
~~~

استبدل هذا السطر وحده بالمقطع التالي:

~~~javascript
    var assignmentData = null;
    var assignments = [];
    var assignmentLoadError = '';
    try {
      assignmentData = await q('agents',{search:'',status:'Active',limit:200,offset:0});
      assignments = Array.isArray(assignmentData.runsheet_assignments)
        ? assignmentData.runsheet_assignments : [];
    } catch (e) {
      assignmentLoadError = e && e.message ? e.message : 'تعذر تحميل التكليفات الفعلية';
    }
    var assignmentRows = assignments.map(function(a){
      var labels = {
        Loaded:'محملة',
        Delivering:'جاري التوصيل',
        Delivered:'تم التوصيل',
        Returning:'عائدة/مرتجعة'
      };
      var agentLink = a.delivery_agent_code
        ? esc(a.delivery_agent_code)
        : 'غير مرتبط بسجل مناديب اللوجستيات';
      return '<tr style="border-top:1px solid #eef2f7">' +
        '<td class="p-3"><b>'+esc(a.runsheet_code)+'</b></td>' +
        '<td class="p-3">'+date(a.run_date)+'</td>' +
        '<td class="p-3">'+esc(a.deliverer_name || ('مستخدم '+a.deliverer_user_id))+'</td>' +
        '<td class="p-3">'+badge(labels[a.status] || a.status,'info')+'</td>' +
        '<td class="p-3">'+agentLink+'</td></tr>';
    }).join('');
    var assignmentEmptyMessage = assignmentLoadError
      ? 'تعذر تحميل التكليفات: '+esc(assignmentLoadError)
      : 'لا توجد رانشيتات مسندة إلى مندوبي التوصيل في الحالات المعروضة.';
    var assignmentTable =
      '<div style="overflow:auto"><table class="w-full"><thead><tr>' +
      ['الرانشيت','التاريخ','مندوب التوصيل المسند فعليًا','الحالة','ربط سجل اللوجستيات']
        .map(function(h){return '<th class="p-3 text-right">'+h+'</th>';}).join('') +
      '</tr></thead><tbody>' +
      (assignmentRows ||
        '<tr><td colspan="5" class="text-center p-8 text-slate-400">' +
        assignmentEmptyMessage + '</td></tr>') +
      '</tbody></table></div>';
    set(shell(
      card(
        'التكليفات الفعلية من مشرف التوصيل',
        'التكليف التشغيلي محفوظ في runsheets.deliverer_id، ويُعرض مستقلًا عن خطة المسار.',
        assignmentTable
      ) +
      card('الرحلات والمسارات','خطة مقابل تنفيذ ومحصلة مالية',table)
    ));

### لماذا هذا الإصلاح هو الأنسب؟

- يقرأ التكليفات من RPC/العقد الموجود؛ لا ينشئ API أو Edge Function جديدة.
- يعرض التكليفات في «الرحلات والمسارات» دون تمثيلها خطأً كخطط توصيل.
- يحافظ على جدول الخطط الحالي وأزراره وعقد **route_detail**.
- لا ينشئ **delivery_route_plans** أو **delivery_route_stops** ولا يختلق بيانات تخطيط.
- لا يكرر تعديل بطاقة «مناديب التوصيل» الموجودة بالفعل.

### اختبارات قبول بعد تطبيق المالك

1. افتح «الرحلات والمسارات»: يجب أن تظهر بطاقة التكليفات، وبها RS-1 وRS-2 والمندوب والحالة.
2. يجب أن يظل جدول الخطط يعرض «لا توجد خطط توصيل» ما دام عدد الخطط صفرًا؛ لا تعتبر هذا فشلًا إذا كانت بطاقة التكليفات ظاهرة.
3. افتح «مناديب التوصيل»: يجب أن تظهر بطاقة التكليفات الموجودة أصلًا وبها RS-1 وRS-2.
4. اضغط «تحديث» وأعد تحميل الصفحة؛ يجب أن تبقى النتيجة نفسها.
5. تحقق من Network بأن طلب **agents** يعيد **runsheet_assignments**، ومن DOM بأن البطاقة والصفين ظهرا.
6. تحقق من Console وعدم وجود أخطاء JavaScript.
7. تحقق من أن عدد **delivery_route_plans** و**delivery_route_stops** بقي صفرًا؛ هذا الإصلاح لا ينشئ خططًا.
8. بعد نشر المالك، أعد فحص artifact المنشور قبل إعلان الإغلاق. لا يُدّعى Git/Production parity بلا دليل مباشر.

## 5. Mutation Ledger

- **Production data/schema/RPC/ACL/RLS:** قراءة فقط؛ لم تتغير.
- **Runsheets/assignments:** لم تتغير.
- **Inventory/accounting:** لم تتغير.
- **Parent operational source:** لم يُعدّل احترامًا لقاعدة أن مالك النظام يطبق تغييرات النظام الأم.
- **Historical repair cb62612...:** محفوظ؛ لم يُكرر.
- **Test fixtures/harnesses:** لم تُنشأ.
- **Governance:** هذا التقرير هو توثيق الحالة الجديدة، ويجب ربطه بأول حدث موثق في **CURRENT_STATE.md**.

## 6. Remaining / Closure

- **السبب الجذري لمسار «الرحلات والمسارات»:** CONFIRMED.
- **الإصلاح الجراحي:** جاهز للتطبيق في ملف النظام الأم، لكنه لم يُطبّق بعد؛ يتطلب إجراء المالك.
- **تبويب «مناديب التوصيل» في Runtime المنشور:** UNVERIFIED؛ المصدر وRPC صحيحان، لكن DOM حديث للتبويب لم يُفحص.
- **Cloudflare artifact provenance:** UNVERIFIED.
- **Production E2E بعد الإصلاح:** NOT RUN لأن تعديل النظام الأم لم يُنشر بعد.
- **Final Closure Status:** ROOT CAUSE CONFIRMED — OWNER FILE CHANGE REQUIRED / E2E NOT CLOSED.

## SELF-AUDIT FINAL

- **What I Proved:** استمرار بيانات RS-1 وRS-2؛ هوية المالك وصلاحياته؛ استجابة RPC الحية؛ الفصل بين **runsheets.deliverer_id** و**delivery_route_plans**؛ أن **routes()** لا يقرأ التكليفات وأن **agents()** يحتوي إصلاحًا سابقًا.
- **What I Did Not Prove:** ظهور بطاقة التكليفات في تبويب «مناديب التوصيل» على Cloudflare الآن؛ تطابق artifact المنشور مع blob الحالي؛ نجاح E2E بعد تعديل النظام الأم.
- **What I Fixed:** لا تعديل تشغيلي تخميني؛ جهزت تعديلًا جراحيًا مثبت السبب لمسار «الرحلات والمسارات».
- **What I Initially Missed:** وجود فرق وظيفي بين إسناد الرانشيت وإنشاء خطة توصيل، وأن تبويب التخطيط لديه نافذة تاريخية تستبعد الرانشيتين حاليًا.
- **What Could Still Be Wrong:** قد توجد فجوة نشر/عرض في تبويب «مناديب التوصيل» رغم سلامة المصدر والـRPC؛ تحتاج فحصًا بعد مصادقة حديثة.
- **Final Confidence:** مرتفع في سبب غياب التكليفات من جدول الخطط؛ متوسط في حالة الواجهة المنشورة الكاملة.
- **Final Closure Status:** ROOT CAUSE CONFIRMED — OWNER FILE CHANGE REQUIRED.
