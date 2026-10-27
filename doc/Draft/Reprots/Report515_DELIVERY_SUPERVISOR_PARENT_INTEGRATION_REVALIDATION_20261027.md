# Report515 — إعادة التحقق التنفيذي لتكليفات Delivery Supervisor داخل Parent ERP

**التاريخ:** 2026-10-27  
**وقت Production الأخير في هذه الجولة:** 2026-10-27 15:58:54.703680+00  
**النطاق:** ظهور تكليفات الرانشيت المسندة من Delivery Supervisor في Parent ERP → إدارة التوصيل والشحن → مناديب التوصيل.  
**الحالة الإجمالية:** `PARTIALLY COMPLETED` — السبب الجذري ما زال مثبتًا، وبيانات Production أعيدت مطابقتها، لكن رقعة Parent لم تُطبّق ولم يُنفذ Browser/HTTP E2E؛ لذلك لا يجوز إعلان `RESOLVED AND VERIFIED`.

## A. PRE-CHANGE SELF-AUDIT

| البعد | التقييم | أساس التقييم |
|---|---|---|
| Business Understanding | CONFIRMED / HIGH | فصل تكليف الرانشيت عن سجل Delivery Agent وخطة Route Plan مثبت في المصدر والعقود الحية |
| Architecture Understanding | CONFIRMED / HIGH | supervisor RPC → runsheets.deliverer_id؛ Parent Logistics agents → delivery_agents، routes → delivery_route_plans |
| Database Understanding | CONFIRMED / HIGH | تعريفات RPC الحية وعلاقات بيانات Production والعدادات تمت قراءتها مباشرة |
| Historical Understanding | CONFIRMED / HIGH | CURRENT_STATE وReport514 وmaster execution prompt قرئت؛ لم تُعامل التقارير كبديل عن القراءة الحية |
| Production Understanding | CONFIRMED / HIGH | قراءة SQL جديدة في Production عند 15:58:54 UTC |
| Current Understanding | CONFIRMED / HIGH | supervisor.html أعيد جلبه، SHA مطابق لـReport514 |
| Execution Confidence | MEDIUM | السبب الجذري مؤكد، لكن تطبيق HTML والنشر وBrowser E2E خارج ما تم إثباته في هذه الجولة |

**Confirmed Facts**
- `supervisor.html` الحالي يستدعي `delivery_supervisor_assignment_query` للقراءة و`delivery_supervisor_assign_deliverer_atomic` للإسناد وفكه.
- `delivery_supervisor_assign_deliverer_atomic(uuid,text,uuid,text)` و`delivery_supervisor_assignment_query(uuid,text)` موجودتان في Production، وتعملان كـSECURITY DEFINER؛ ACL الظاهر يمنح EXECUTE إلى authenticated وservice_role وليس anon.
- `runsheets.deliverer_id` يحمل هويات من `public.users.id`، منفصلة عن `driver_id` و`vehicle_id`.
- أحدث قراءة Production وجدت RS-1 وRS-2 في حالة Loaded، ولكل منهما deliverer_id صالح مرتبط بمستخدم؛ وعدادات `delivery_agents` و`delivery_route_plans` و`delivery_route_stops` تساوي صفرًا في قاعدة البيانات التي فُحصت.
- `CURRENT_STATE.md` يحدد Report514 بوصفه آخر حدث موثق قبل هذه الجولة، ويذكر صراحةً أن رقعة Parent مقترحة ولم تطبق.

**Unknown / Unverified**
- لا يوجد في هذه الجولة دليل على أن المالك طبّق رقعة Report514 بعد إنشائها.
- لم تُثبت مطابقة HTML الذي يقدمه Cloudflare مع Git الحالي.
- لم يُنفذ تسجيل دخول حقيقي ثم Browser/HTTP E2E من المشرف إلى Parent.
- لم تُختبر كل أدوار وصلاحيات Parent في المتصفح.

**Conflicts**
- لا تعارض حاليًا بين دليل البيانات الحية وسبب المشكلة الذي وثقه Report514: تكليفات موجودة في runsheets، بينما نموذج Parent الحالي يقرأ مصدرًا مختلفًا.
- لا يُستنتج من ذلك أن تكليف المشرف يجب أن ينشئ Delivery Agent أو Route Plan؛ لا يوجد عقد أعمال مثبت يفرض ذلك.

## B. مصادر الحقيقة التي فُحصت

1. **المستودع التشغيلي:** `papamohammed77-glitch/erp-frontend`, branch `main`.
2. **الملف التشغيلي:** `companies/company-1/delivery/supervisor.html`, blob SHA `3e6db903cd7da411f9ed40a449f9ee5bece5f387`. أعيد جلب الملف كاملًا؛ الاستدعاءات المركزية المشار إليها أعلاه موجودة.
3. **ملف Parent:** `companies/company-1/main.html`, blob SHA `b9bd5698c98c4b3d7e2bc388bacfbf4f43f2a919`. محاولة القراءة عبر Contents API مع تحديد النطاق أعادت محتوى فارغًا؛ لم أختلق مقتطفًا أو رقم سطر جديدًا. يعتمد التشخيص الحالي على المراجعة السابقة الموثقة في Report514، ويجب إعادة جلب blob/مقاطع Parent القابلة للفحص قبل تطبيق الرقعة.
4. **الحالة الحالية:** `CURRENT_STATE.md`؛ آخر حدث قبل هذه الجولة هو LVE-2026-10-27-514.
5. **التقرير السابق:** `doc/Draft/Reprots/Report514_DELIVERY_SUPERVISOR_PARENT_ASSIGNMENT_VISIBILITY_20261027.md`, blob SHA `28f81f58d6821c79fe835053c5702ad27abb3d8a`.
6. **الدستور التشغيلي:** `doc/Draft/Reprots/MASTER_CTO_EXECUTION_PROMPT_LOADER_PICKER_INTEGRATION_20261025.md`, blob SHA `abfa9d376c455ad7466b9404eed6f0a2c2166ede`; قُرئ محتواه المتاح كاملًا. كما قُرئ `doc/Draft/Reprots/writing-block.md`، blob SHA `8929b54e04ef848e814a21f6ecdfb97bf8c7952d`.
7. **Production:** Supabase project `fiilmooggumokxanwiyx`. قُرئت تعريفات RPC وACL مباشرة، ونُفذت استعلامات قراءة فقط للرانشيتات والعدادات. لم يحدث أي DDL أو DML.

## C. Production snapshot — قراءة جديدة

**وقت قاعدة البيانات:** `2026-10-27 15:58:54.70368+00`.

| Runsheet | Status | Deliverer | Email | driver_id | vehicle_id |
|---|---|---|---|---|---|
| RS-1 | Loaded | مندوب توصيل | driver@rawaea.com | NULL | `69b08188-60ee-43af-9644-e1626a85bfa0` |
| RS-2 | Loaded | مندوب توصيل 3 | driver3@rawaea.com | NULL | `7e58a39d-e1f4-435f-a6f7-fa625a234333` |

Company ID observed: `00000000-0000-0000-0000-000000000001`.

| Relation | Current count |
|---|---:|
| `public.delivery_agents` | 0 |
| `public.delivery_route_plans` | 0 |
| `public.delivery_route_stops` | 0 |

هذه قراءة Production مباشرة؛ لا تعني اختبار HTTP أو متصفح، ولا تثبت ما يعرضه Cloudflare. لم تُعدّل RS-1 أو RS-2.

## D. السبب الجذري — CONFIRMED

المساران الحاليان يمثلان نموذجين مختلفين:

```
Delivery Supervisor
  → delivery_supervisor_assign_deliverer_atomic
  → runsheets.deliverer_id (public.users.id)

Parent ERP / Delivery Logistics
  → delivery_logistics_query('agents')
  → public.delivery_agents

Parent ERP / Routes
  → delivery_logistics_query('routes')
  → public.delivery_route_plans
```

لذلك وجود `deliverer_id` في الرانشيت لا يجعل السجل يظهر تلقائيًا في قائمة `delivery_agents`. والبيانات الحية تؤكد أن نموذج سجل المندوب وخطط المسار فارغ حاليًا. هذا **Read-model/display integration gap** وليس دليلًا على أن حفظ الإسناد فشل.

### قرار المعالجة الآمن

الاحتفاظ بعقد الإسناد الحالي، وإضافة قسم قراءة فقط في Parent لعرض تكليفات الرانشيت باستخدام RPC القراءة الموجود `delivery_supervisor_assignment_query`، مع إبقاء قائمة `delivery_agents` وعقد إسناد `delivery_route_plans.delivery_agent_id` مستقلين. لا تُنشأ سجلات Delivery Agent أو Route Plan اصطناعية لمجرد إظهار التكليف.

## E. Loss / Gain / Responsibility Matrix

| الوظيفة | الحالة | الدليل / القرار |
|---|---|---|
| حفظ تكليف المندوب في runsheet | RETAINED | RPC الحي يحدّث `runsheets.deliverer_id` |
| هوية المندوب | RETAINED | FK إلى `public.users.id`؛ مستخدم منفصل عن السائق والمركبة |
| سجل Delivery Agent الإداري | RETAINED | مصدر Parent الحالي مستقل؛ لا تُنشأ سجلات تلقائيًا |
| Route Plan ومحطاته | RETAINED | lifecycle منفصل؛ لا تُنشأ خطة من مجرد الإسناد |
| عرض تكليفات الرانشيت في Parent | MISSING | لا يقرأ العرض الحالي علاقة `runsheets.deliverer_id` وفق مراجعة Parent الموثقة في Report514 |
| عرض تكليفات محفوظة عبر RPC موجود | PROPOSED | رقعة Report514؛ لم يثبت تطبيقها |
| RPC/Edge/table جديدة | INTENTIONALLY NOT ADDED | لا حاجة مثبتة إليها |
| إنشاء Route Plan تلقائيًا عند إسناد المشرف | UNKNOWN / NOT AUTHORIZED BY CURRENT CONTRACT | لا دليل يثبت أن هذا هو السلوك المقصود |

## F. بوابات التنفيذ والاختبار

| Gate | الحالة | النتيجة |
|---|---|---|
| 0 — Directive and Scope Lock | PASS | المهمة محصورة في تكامل عرض تكليفات Delivery Supervisor داخل Parent |
| 1 — Current-State and Source Verification | PASS WITH LIMITATION | supervisor + Production + CURRENT_STATE + Report514 أعيد فحصها؛ مقاطع Parent لم تُسترجع بنجاح في هذه الجولة |
| 2 — Reproduce and Localize | PASS AT DATA/CONTRACT LEVEL; BROWSER NOT RUN | البيانات موجودة في runsheets ومصدر Parent منفصل؛ لم تُجر تجربة متصفح |
| 3 — Root-Cause Confirmation and Design | PASS | السبب مدعوم بالبيانات والعقود؛ اختيار Read Model أقل تغييرًا |
| 4 — Pre-Change Safety Review | PASS FOR READ-ONLY INVESTIGATION | لم يُنفذ تغيير تشغيلي |
| 5 — Controlled Implementation | BLOCKED BY EXPLICIT SOURCE-EDIT GOVERNANCE | HTML التشغيلي يُعدّله المالك؛ الرقعة ليست APPLIED |
| 6 — Contract/Auth/Data Integrity | PARTIAL | تعريفات RPC وACL وبيانات الرانشيت فُحصت؛ لم تُختبر جلسات HTTP/JWT أو جميع الأدوار |
| 7 — End-to-End Functional Acceptance | BLOCKED / NOT RUN | يلزم تطبيق الرقعة واختبار الواجهتين |
| 8 — Deployment and Runtime | BLOCKED / UNVERIFIED | لا دليل على نشر الرقعة أو HTML المستضاف |
| 9 — Final Evidence Audit and Closure | PARTIAL | تقرير وتحديث الاستمرارية هما المخرجان المنفذان؛ التكامل التشغيلي لم يُغلق |

### Acceptance matrix

| الشرط | الحالة |
|---|---|
| Root cause established | CONFIRMED |
| Corrective code applied | NO — PROPOSED ONLY |
| Assignment persisted | CONFIRMED — RS-1 / RS-2 |
| Survives reload | UNVERIFIED |
| Parent displays correct assignment | UNVERIFIED / NOT RUN |
| Authorization preserved in real HTTP session | UNVERIFIED |
| Regression checks | NOT RUN |
| Deployment verified | UNVERIFIED |
| Test cleanup | NOT APPLICABLE — no fixtures created |
| Report reflects evidence | PASS |

## G. ما تم تغييره في هذه الجولة

- تم إنشاء هذا التقرير الجديد.
- تم تحديث `CURRENT_STATE.md` بإضافة الحدث الأحدث مع الإبقاء على كل السجل السابق.
- لم يتغير `supervisor.html` أو `main.html`.
- لم تتغير أي RPC أو Edge Function أو ACL أو RLS.
- لم يحدث DDL/DML أو تعديل في بيانات الأعمال.
- لم تُنشأ fixtures ولم تُعدّل RS-1 أو RS-2.

## H. الخطوة التنفيذية التالية الدقيقة

1. أعد جلب `companies/company-1/main.html` من المستودع التشغيلي بطريقة تُظهر النص الفعلي داخل IIFE `RW_DeliveryLogistics`؛ لا تعتمد على SHA قديم وحده، لأن Contents API أعادت محتوى فارغًا لهذه القراءة.
2. طابق موضع `async function agents()` ومقطع `set(shell(card('مناديب التوصيل'...)));` حرفيًا مع ملحق Report514. إذا تغيّر النص أو SHA، أعد بناء الرقعة على المصدر الحالي بدل تطبيقها آليًا.
3. يطبّق المالك رقعة Report514 فقط: helper قراءة تكليفات + تركيب البطاقة الجديدة مع إبقاء بطاقة `delivery_agents` وسلوك ROUTE_AGENT_ASSIGN كما هما. لا تعديل على `supervisor.html` ولا إنشاء RPC أو جدول جديد.
4. شغّل static parse على JavaScript في صفحة Parent كاملة بعد التطبيق.
5. اختبر جلسة Parent مصادقًا عليها بصلاحية مناسبة، ثم افتح «إدارة التوصيل والشحن → مناديب التوصيل» وتحقق من ظهور RS-1 وRS-2 تحت المندوبين الصحيحين.
6. تحقق من بقاء سجل Delivery Agent وإسناد Route Plan مستقلين، ومن سلوك صلاحيات غير المصرح لهم، ومن عدم تغيير البيانات أو الصلاحيات.
7. تحقق من HTML المنشور على Cloudflare ومن HTTP/Browser E2E. بعد ذلك فقط حدّث الحالة إلى APPLIED/DEPLOYED/VERIFIED بحسب الدليل.

## I. SELF-AUDIT FINAL

- **What I Proved:** تكليفات RS-1 وRS-2 موجودة في Production؛ المندوبون مرتبطون بـ`runsheets.deliverer_id`; الجداول التي يقرأها Parent حاليًا (`delivery_agents`, `delivery_route_plans`, `delivery_route_stops`) فارغة؛ RPCs الحالية موجودة وعقودها وصلاحياتها قُرئت.
- **What I Did Not Prove:** تطبيق رقعة Parent، عرضها في متصفح حقيقي، parity مع Cloudflare، أو إتمام HTTP/JWT E2E.
- **What I Fixed:** لم أغيّر كودًا تشغيليًا لأن الحوكمة الحالية تحصر تطبيق HTML في المالك؛ وثّقت الحالة الحية وأبقيت الرقعة في نطاقها الصحيح.
- **What I Initially Missed:** لم تكن هناك فجوة حفظ مثبتة؛ المشكلة في اختلاف نموذج القراءة بين تكليف الرانشيت وسجل Delivery Agent/Route Plan.
- **What Could Still Be Wrong:** قد يكون مصدر Parent أو deployment قد تغير بعد Report514؛ يجب جلب مقاطع Parent الحالية قبل تطبيق الرقعة. كما أن صلاحيات عرض القسم تحتاج اختبارًا واقعيًا.
- **Final Confidence:** HIGH في السبب الجذري على مستوى البيانات والعقد؛ LOW/MEDIUM في سلوك UI المنشور حتى تنفيذ E2E.
- **Final Closure Status:** `PARTIAL — ROOT CAUSE CONFIRMED / PRODUCTION DATA RECONFIRMED / PARENT PATCH NOT APPLIED / E2E NOT RUN / NOT CLOSED`.

**لا تعلن الإغلاق الكامل. لا تعِد إصلاح RPC أو صفحة المشرف دون عيب جديد مثبت.**
