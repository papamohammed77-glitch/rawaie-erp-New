# Report542 — إعادة مطابقة Production ومراجعة الإصلاح الجراحي لعرض تكليفات الرانشيت في «الرحلات والمسارات»

**وقت الفحص:** 2026-10-28 21:49–21:53 UTC (التاريخ المحلي بمصر 2026-10-29).  
**النطاق:** استئناف Report541، بيانات Production، RPC، مصدر Parent الحالي، تاريخ Git، والواجهة المنشورة المتاحة.  
**قرار التنفيذ:** السبب الجذري مؤكد، والإصلاح الجراحي محسوم وجاهز للمالك. لم أعدّل `companies/company-1/main.html` ولم أنشر Parent، التزامًا بالدستور التشغيلي الذي يجعل تعديل النظام الأم من مسؤولية المالك.

## 1. PRE-CHANGE SELF-AUDIT

- **Business Understanding — CONFIRMED:** تكليف مندوب التوصيل الفعلي محفوظ في `runsheets.deliverer_id`. خطة المسار كيان مستقل في `delivery_route_plans`، ومحطاتها في `delivery_route_stops`.
- **Architecture Understanding — CONFIRMED:** `agents` يعيد سجل `delivery_agents` في `rows` ويعيد تكليفات الرانشيت في `runsheet_assignments`. أما `routes` فيعيد خطط المسارات فقط.
- **Database Understanding — CONFIRMED:** الاستعلام الحي وجد RS-1 وRS-2 بحالة `Loaded` مع `deliverer_id` صالح ضمن الشركة نفسها. العدّ الحالي: `delivery_agents=0`, `delivery_route_plans=0`, `delivery_route_stops=0`.
- **Historical Understanding — CONFIRMED:** راجعت Report538 وReport540 ونسختَي Report541. إصلاح `agents()` السابق موجود بالفعل؛ لا ينبغي تكراره.
- **Production Understanding — CONFIRMED:** استعلام SQL مباشر في Supabase Production عند `2026-10-28 21:50:00Z`، واستدعاء مباشر للـRPC عند `21:50:21Z`، كلاهما للقراءة.
- **Current Understanding — CONFIRMED:** مصدر Parent في `papamohammed77-glitch/erp-frontend`, الفرع `main`; blob `companies/company-1/main.html` هو `0c1745081e8d17480433ed527d77cac9f5292021`. آخر تعديل فعلي معروف لهذا الملف هو commit `cb62612a174f5b1a8d5aa5a41a4c3e5747bb73fc`; HEAD المستودع `8843150bdde99d36d477d6bb344a24df61dd2942`.
- **Execution Confidence:** مرتفع لتشخيص فجوة المستهلك وصحة التعديل المقترح؛ غير مكتمل للواجهة المنشورة لأن الجلسة المتاحة غير مصادق عليها ولم يُنشر الإصلاح.

### جرد الأدلة

- **Historical Opened:** Report538، Report540، Report541 المؤرخ 2026-10-28، وReport541 المؤرخ 2026-10-29.
- **Original Opened:** راجعت تاريخ الإصلاح السابق عبر diff commit `cb62612...`؛ لم تكن هناك حاجة لإعادة كتابة أصل التطبيق.
- **Production Opened:** `public.delivery_logistics_query(uuid,text,jsonb,uuid,text)` وتعريفها الحي، وبيانات المستخدم/الرانشيتات/أعداد الجداول.
- **Current Opened:** مصدر `companies/company-1/main.html` عبر صفحة GitHub المتصلة؛ الحجم المعلن 33,153 سطرًا. تم استخراج دوال `routes()`, `planning()`, `agents()` والمساعد `q()` من المصدر المعروض.
- **Schema Checked:** أعمدة `runsheets`, `users`, `delivery_agents`, `delivery_route_plans`, `delivery_route_stops`.
- **Triggers Checked:** غير مطلوبة لهذا الإصلاح العرضي الذي لا يغيّر قاعدة البيانات؛ لم تُجرَ أي كتابة DB.
- **Dependencies Checked:** `q()` يرمي خطأ عند RPC error أو `success=false`; `esc()`, `date()`, `badge()`, `card()`, `shell()` مستخدمة بالفعل في نفس الوحدة.
- **Consumers Checked:** `routes()` و`agents()` و`planning()`، مع RPC الفعلي.
- **Published UI Checked:** تبويب Cloudflare المتصل كان مفتوحًا على «الرحلات والمسارات» لكنه يحتوي أيضًا عناصر نموذج الدخول؛ لذلك لا أعتبره جلسة E2E مصادقًا عليها أو فحصًا حديثًا بعد النشر.

## 2. Live Production — النتائج المباشرة

### 2.1 بيانات الأعمال

عند `2026-10-28 21:50:00Z`:

| الكيان | النتيجة |
|---|---|
| RS-1 | `Loaded`, التاريخ `2026-10-10`, المندوب `driver@rawaea.com` |
| RS-2 | `Loaded`, التاريخ `2026-10-12`, المندوب `driver3@rawaea.com` |
| `delivery_agents` | 0 صفوف |
| `delivery_route_plans` | 0 صفوف |
| `delivery_route_stops` | 0 صفوف |

المستخدمان المسندان نشطان وضمن `company_id=00000000-0000-0000-0000-000000000001`. لا دليل يبرر إنشاء سجلات مناديب أو خطط/محطات اصطناعية.

### 2.2 استدعاء Production RPC المباشر

عند `2026-10-28 21:50:21Z`، باستخدام هوية مالك النظام الموجودة في Production:

- `agents`: `success=true`, `rows=[]`, و`runsheet_assignments=[RS-2, RS-1]`.
- `routes`: `success=true`, `rows=[]`.
- `planning` مع نطاق `2026-10-01` إلى `2026-10-31`: يعيد RS-1 وRS-2، وكل منهما `has_route_plan=false`.

هذا يؤكد أن بيانات التكليف موجودة وأن خلو `rows` في `agents` طبيعي مع خلو سجل `delivery_agents`. كما يؤكد أن «التكليف» ليس «خطة مسار».

### 2.3 عقد الهوية والأمان

تعريف Production للدالة `delivery_logistics_query(uuid,text,jsonb,uuid,text)` هو `SECURITY DEFINER` مع `search_path=public`. عند وجود `auth.uid()` تستخدم الدالة `public.users.auth_id=auth.uid()`، وعند غياب سياق Auth تستخدم `p_actor_user_id` مع الشركة والحالة. لا يوجد دليل في هذا التحقيق على عيب RPC/ACL/RLS، ولم تتغير صلاحيات أو بيانات.

## 3. Source + Git reconciliation

- **Repository:** `papamohammed77-glitch/erp-frontend`, branch `main`.
- **Current file:** `companies/company-1/main.html`.
- **Current blob SHA:** `0c1745081e8d17480433ed527d77cac9f5292021`.
- **Repository HEAD observed:** `8843150bdde99d36d477d6bb344a24df61dd2942`.
- **Last file-change commit:** `cb62612a174f5b1a8d5aa5a41a4c3e5747bb73fc`, which adds the runsheet-assignment card to `agents()`.
- **Exact current `routes()` location:** approximately line 30616; the existing final render line is at line 30633 in the current source content.

### ما كشفه المصدر

1. `q(view,payload)` يستدعي `delivery_logistics_query` ويحوّل أخطاء RPC أو `success=false` إلى exception.
2. `agents()` يقرأ `d.runsheet_assignments` ويعرض بطاقة مستقلة بالفعل.
3. `routes()` يقرأ `q('routes',...)` فقط ويعرض `d.rows` كخطط مسارات؛ لا يقرأ `runsheet_assignments`.
4. `planning()` يرسل نطاقًا افتراضيًا من اليوم إلى سبعة أيام لاحقة؛ لذا لا تظهر RS-1/RS-2 القديمتان في هذا العرض الافتراضي. هذا سلوك مستقل عن إصلاح بطاقة «الرحلات والمسارات».
5. لم يظهر في تاريخ الملف تغيير أحدث يضيف بطاقة التكليفات إلى `routes()`.

## 4. ROOT CAUSE — CONFIRMED

هذه **فجوة Consumer في واجهة النظام الأم**، وليست فقدًا لبيانات الإسناد أو عيبًا مثبتًا في RPC:

- `runsheets.deliverer_id` يحتوي تكليف RS-1 وRS-2.
- RPC `agents` يعيدهما في `runsheet_assignments`.
- RPC `routes` يعيد `delivery_route_plans` فقط.
- `routes()` لا يستهلك `runsheet_assignments`، لذلك لا يمكن أن يعرض التكليفات في الشاشة الحالية.
- وجود صفر خطط مسار يجعل رسالة «لا توجد خطط توصيل» صحيحة بالنسبة إلى جدول الخطط، لكنها لا تعرض التكليفات الفعلية المنفصلة.

## 5. مراجعة الإصلاحات السابقة وحسم التعارض

قارنت نسختَي Report541:

- نسخة 2026-10-28 تفصل استدعاء `agents` عن بناء البطاقة، لكنها لا تتعامل صراحةً مع فشل الاستدعاء.
- نسخة 2026-10-29 تضيف `try/catch` ورسالة خطأ وتحافظ على جدول الخطط؛ هذا أفضل من ناحية تحمل فشل تحميل البطاقة.

**النسخة المعتمدة هنا:** الاحتفاظ بمعالجة الخطأ من النسخة الأحدث، مع إبقاء بطاقة «الرحلات والمسارات» الأصلية أولًا ثم إضافة بطاقة التكليفات بعدها؛ هذا يحافظ على ترتيب الواجهة الحالي قدر الإمكان.

### التعديل الجراحي الذي يطبقه المالك

في `companies/company-1/main.html`، داخل `async function routes()`، استبدل هذا السطر وحده (الموجود حاليًا قرب السطر 30633):

```javascript
set(shell(card('الرحلات والمسارات','خطة مقابل تنفيذ ومحصلة مالية',table)));
```

بالمقطع التالي:

```javascript
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
var assignmentRows = assignments.map(function(a) {
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
    .map(function(h) { return '<th class="p-3 text-right">'+h+'</th>'; }).join('') +
  '</tr></thead><tbody>' +
  (assignmentRows ||
    '<tr><td colspan="5" class="text-center p-8 text-slate-400">' +
    assignmentEmptyMessage + '</td></tr>') +
  '</tbody></table></div>';
set(shell(
  card('الرحلات والمسارات','خطة مقابل تنفيذ ومحصلة مالية',table) +
  card(
    'تكليفات الرانشيت من مشرف التوصيل',
    'التكليف الفعلي محفوظ في runsheets.deliverer_id؛ يُعرض مستقلًا عن خطط المسارات.',
    assignmentTable
  )
));
```

### لماذا هذا التعديل صحيح؟

- يعيد استخدام RPC قائمًا ولا ينشئ Edge Function أو RPC جديدًا.
- يحافظ على جدول الخطط وأزراره كما هما.
- يعرض التكليفات الفعلية منفصلة عن خطط المسار.
- يعالج فشل تحميل التكليفات دون إسقاط جدول الخطط.
- لا يغير بيانات Production أو الصلاحيات أو RLS/ACL أو سجلات التوصيل.
- لا يكرر إصلاح `agents()` الموجود بالفعل.

**حدود المسؤولية:** لم أعدل ملف النظام الأم ولم أنشره؛ الدستور التشغيلي ينص على أن المالك يطبق تعديلات النظام الأم. لا أصف التعديل بأنه مطبق أو منشور.

## 6. اختبارات القبول بعد تطبيق المالك

1. في «الرحلات والمسارات»، يجب أن يبقى جدول الخطط الحالي كما هو.
2. يجب أن تظهر بطاقة مستقلة «تكليفات الرانشيت من مشرف التوصيل» وبها RS-1 وRS-2، والمندوب، والحالة «محملة».
3. إذا فشل استدعاء `agents`، يجب أن يظهر تنبيه داخل البطاقة وتبقى بطاقة الخطط مرئية.
4. في «مناديب التوصيل»، يجب أن تبقى بطاقة التكليفات الموجودة بالفعل سليمة.
5. أعد تحميل التبويبين وتحقق من عدم تكرار الصفوف؛ التغيير للعرض فقط.
6. افحص Network لرد RPC وDOM وConsole في جلسة مصادق عليها فعليًا.
7. تحقق بعد النشر من أن الصفحة المنشورة تقدم النسخة التي تتضمن تعديل المالك. لا تُعدّل RPC أو بيانات Production لإجبار ظهور البطاقة.

### نتائج الاختبارات التي نُفذت الآن

| الاختبار | النتيجة |
|---|---|
| Production SQL للرانشيتات والعدادات | PASS — قراءة فقط |
| Production RPC `agents` | PASS — RS-1 وRS-2 في `runsheet_assignments` |
| Production RPC `routes` | PASS — `rows=[]` مع صفر خطط |
| Production RPC `planning` بنطاق أكتوبر | PASS — RS-1 وRS-2 موجودتان و`has_route_plan=false` |
| مراجعة مصدر `routes()` و`agents()` و`q()` | PASS — فجوة المستهلك مثبتة |
| Static/Browser E2E بعد التعديل | NOT RUN — التعديل لم يُطبق |
| Authenticated published UI Network/DOM/Console | UNVERIFIED — التبويب المتاح يعرض عناصر تسجيل الدخول |
| Cloudflare served-artifact provenance | UNVERIFIED |
| Production deployment بعد الإصلاح | NOT RUN — لم يحدث نشر |

## 7. Mutation ledger

- Production database/data/schema/RPC/ACL/RLS: **لم تتغير**.
- Parent source `main.html`: **لم يتغير**.
- Cloudflare deployment: **لم يتغير**.
- `delivery_agents`, route plans/stops, runsheets, inventory, accounting: **لم تتغير**.
- Test fixtures/harnesses: **لم تُنشأ**.
- التغيير في هذه الدورة: تقرير توثيقي فقط، مع تحديث نقطة الاستئناف في `CURRENT_STATE.md`.

## SELF-AUDIT FINAL

- **What I Proved:** الحالة الحية للرانشيتين والعدادات؛ استجابة RPC؛ تعريف الدالة وعقد الهوية؛ مصدر `routes()` الحالي؛ وجود إصلاح `agents()`؛ السبب الدقيق لعدم عرض التكليفات في «الرحلات والمسارات».
- **What I Did Not Prove:** ظهور البطاقة بعد التعديل في DOM منشور مصادق عليه؛ هوية artifact الذي يقدمه Cloudflare؛ نجاح E2E بعد نشر المالك.
- **What I Fixed:** حسمت التباين بين نسختَي patch واخترت مقطعًا واحدًا يجمع معالجة الخطأ مع الحفاظ على ترتيب الواجهة الحالي؛ أعددت التغيير النهائي للمالك.
- **What I Initially Missed:** يجب عدم الخلط بين وجود تكليف في `runsheets` وبين وجود خطة في `delivery_route_plans`; كما أن التقرير السابق لا يثبت وحده أن النشر أو جلسة المصادقة حديثان.
- **What Could Still Be Wrong:** قد تبقى مشكلة نشر أو مصادقة أو runtime بعد تطبيق المقطع؛ لا يمكن حسمها قبل نشر المالك واختبار الجلسة المصادق عليها.
- **Final Confidence:** مرتفع في التشخيص وصحة التعديل المقترح؛ غير مكتمل في Runtime المنشور.
- **Final Closure Status:** `ROOT CAUSE CONFIRMED — OWNER PATCH PREPARED — PRODUCTION UI E2E OPEN — NOT CLOSED`.
- **Next exact action:** يطبق المالك الاستبدال المحدد في `companies/company-1/main.html` ثم ينشره؛ بعدها تُعاد مطابقة الـartifact وتُختبر البطاقتان من جلسة مصادق عليها قبل الإغلاق.
