# تقرير التحقيق والتنفيذ — Report508
## تكامل مشرف التوصيل مع النظام الأم — مزامنة Production ومراجعة Staging

**التاريخ:** 2026-10-27  
**الحالة النهائية:** `PARTIALLY COMPLETED / ROOT CAUSE RECONFIRMED / REPAIR NOT DEPLOYED / STAGING DRIFT CONFIRMED`

## 1. SELF-AUDIT

- **Business Understanding — CONFIRMED:** الإسناد التشغيلي يجب أن يبقى على `runsheets.deliverer_id`، مع الفصل بين `driver_id` وهوية المركبة.
- **Architecture Understanding — CONFIRMED:** واجهة المشرف تستدعي RPC مستقلًا، بينما شاشة النظام الأم «مناديب التوصيل» تقرأ نموذج `delivery_agents`، وتقرأ المسارات من `delivery_route_plans`.
- **Historical Understanding — PARTIAL:** قُرئ `CURRENT_STATE.md` واستُخرج أحدث حدث LVE-2026-10-27-507، وقُرئ Report507 والوثيقة الحاكمة `writing-block.md`، كما قُرئ MASTER CTO prompt. لم تُستكمل مراجعة كل commit تاريخي لكل المستهلكين.
- **Production Understanding — CONFIRMED ضمن النطاق المفحوص:** أُعيد الاستعلام الحي عن تعريفات RPC والمخطط والبيانات الحالية.
- **Staging Understanding — CONFLICT/CONFIRMED DRIFT:** المخطط في Staging لا يطابق Production؛ الجداول الأساسية وقيود المفاتيح والـaudit trigger غير متوافقة مع migration اللوجستيات المرجعية.
- **Execution Confidence:** مرتفعة في تشخيص اختلاف عقد البيانات ووجود drift في Staging؛ غير كافية لإعلان إصلاح الإنتاج أو إغلاق E2E.

## 2. المصادر والمراجعات المنفذة

### GitHub — المصدر التشغيلي
- Repository: `papamohammed77-glitch/erp-frontend`, branch `main`.
- `companies/company-1/delivery/supervisor.html`
  - Blob SHA: `3e6db903cd7da411f9ed40a449f9ee5bece5f387`.
  - المصدر يستدعي `delivery_supervisor_assignment_query` و`delivery_supervisor_assign_deliverer_atomic`.
  - مسار الإسناد يرسل الشركة وكود الرانشيت و`p_deliverer_user_id` و`p_operation_id`؛ لا ينشئ ملف مندوب في `delivery_agents` ولا خطة في `delivery_route_plans`.
- `companies/company-1/main.html`
  - Blob SHA: `b9bd5698c98c4b3d7e2bc388bacfbf4f43f2a919`.
  - واجهة الملف الأم الضخم لم تُعدّل، التزامًا بالحوكمة. تمت مراجعة عقد Production الذي تستعمله شاشة إدارة التوصيل بدل الادعاء بقراءة كل أسطر الملف عبر أداة أعادت محتوى فارغًا.
- `rawaie-erp-New/doc/Draft/Reprots/MASTER_CTO_EXECUTION_PROMPT_LOADER_PICKER_INTEGRATION_20261025.md`
  - Blob SHA: `abfa9d376c455ad7466b9404eed6f0a2c2166ede`.
  - تمت قراءته على دفعات. يؤكد منع تعديل ملفات HTML التشغيلية مباشرة، ويطلب رقعًا جراحية للمالك عند الحاجة، وعدم تنفيذ DDL/DML إنتاجي للاختبار غير المعزول.
- `rawaie-erp-New/doc/Draft/Reprots/writing-block.md`
  - Blob SHA: `8929b54e04ef848e814a21f6ecdfb97bf8c7952d`.
- Report507:
  - Blob SHA: `aba96bb3406c80a007840cd2e2db376d872e2499`.
  - أكد السبب الجذري نفسه، لكن إعادة الفحص الحي أدناه هي الدليل الحالي.

## 3. Production — قراءة حية في هذه الدورة

Supabase Production project: `fiilmooggumokxanwiyx`.

### CONFIRMED — عقد الإسناد الحالي
الدالة `delivery_supervisor_assign_deliverer_atomic(uuid,text,uuid,text)`:
- تشترط `auth.uid()` وهوية مستخدم نشطة داخل الشركة.
- تتحقق من صلاحية المشرف/الإدارة.
- تتحقق من أن المندوب المستهدف مستخدم نشط داخل الشركة يحمل صلاحية `delivery`.
- تقفل الرانشيت وتسمح بالإسناد/فك الإسناد عندما تكون الحالة `Loaded`.
- تحدث `runsheets.deliverer_id` فقط، وتحافظ على `driver_id` و`vehicle_id`.
- تستخدم `erp_operation_registry` لمفتاح العملية ومنع إعادة استعماله بطلب مختلف.

### CONFIRMED — اختلاف نموذج القراءة
الدالة `delivery_logistics_query(uuid,text,jsonb,uuid,text)` في عرض `agents` تبني الصفوف من `public.delivery_agents` فقط. ويُحسب `active_routes` من `delivery_route_plans` ذات الحالات `Planned/InProgress`؛ أما إحصاءات التوقفات والتحصيل فتُشتق من الخطط والتوقفات/الإيصالات.

### CONFIRMED — لقطة البيانات
استعلام Production الحالي أعاد:
- رانشيتات لديها `deliverer_id`: **2** (`RS-1`, `RS-2`)، وكلاهما `Loaded`.
- `delivery_agents`: **0** صفوف.
- `delivery_route_plans`: **0** صفوف.
- `delivery_route_stops`: **0** صفوف.
- طلبات مرتبطة برانشيتات: **6**.

إذًا الإسناد محفوظ في نموذج الرانشيت، لكن النموذج الذي تقرؤه شاشة مناديب التوصيل لا يملك ملفات مندوبين أو خططًا لعرضها. هذا يثبت سبب عدم ظهور النموذج في الشاشة المستهدفة، ولا يثبت نجاح واجهة المتصفح أو نشرها.

## 4. Historical / Migration review

- Production migration history يحتوي على `20260920_delivery_logistics_control_plane_closure` و`delivery_supervisor_deliverer_assignment_contract` و`delivery_supervisor_complaints_query_20261027`.
- Staging لا يحتوي على migration اللوجستيات `20260920_delivery_logistics_control_plane_closure` ضمن سجل الهجرات المقروء.
- المصدر المرجعي `supabase/migrations/20260920_delivery_logistics_control_plane_closure.sql`، Blob SHA `e80ba658b31f7a16d45f729cb1fa1ac4b4886d2f`، يحتوي على نهايتي جسم دالة PL/pgSQL بلا فاصلة منقوطة بعد `$function$` (قبل تعريف الدالة التالية، وقبل أوامر `REVOKE`). أُصلح هذان الموضعان داخل حمولة إعادة التشغيل التجريبية فقط؛ لم يُعدّل الملف التاريخي في Git لأن تعديل migration قديم بعد تطبيقه على Production يخالف انضباط الهجرات غير القابلة للتغيير.
- بعد إصلاح هاتين النقطتين في حمولة Staging، فشل تطبيق الهجرة لأن `companies(id)` لا يملك قيدًا فريدًا مطابقًا في Staging. ثبت أن `companies` يحتوي صفًا واحدًا، بلا null أو duplicate في `id`.
- أُضيفت قيود Primary Key إلى `companies(id)`, `runsheets(id)`, و`orders(id)` في Staging فقط، بعد التحقق من عدم وجود قيم null أو تكرارات في مفاتيحها. هذه التعديلات باقية في Staging ويجب الاحتفاظ بها في سجل الحالة.
- بعد ذلك فشل replay لأن الدالة `public.fn_audit_trigger()` غير موجودة في Staging. فحص `audit_log` أكد أيضًا أن أعمدته في Staging لا تتضمن الحقول التي تكتبها نسخة Production من trigger (`actor_user_id`, `company_id`, `source_type`, `operation_id`). لم أضع trigger بديلًا شكليًا ولم أُعطّل التدقيق لإجبار الهجرة على النجاح.
- فشلتا إعادة تشغيل migration تم التراجع عنهما بواسطة المعاملة؛ تحقق لاحقًا أن عدد جداول اللوجستيات الموجودة في Staging ما زال صفرًا، وأن سجل migration الفاشل لم يُكتب. التغييرات الثلاثة المنفصلة لقيود المفاتيح فقط هي التي بقيت.

## 5. Root Cause

**CONFIRMED:** عدم التزامن بين نموذج الإسناد ونموذج عرض النظام الأم:
`Supervisor → runsheets.deliverer_id` لا يوفّر بذاته صفًا في `delivery_agents` أو خطة مرتبطة في `delivery_route_plans`. شاشة النظام الأم تقرأ نموذجًا مختلفًا.

**CONFIRMED:** Staging ليس حاليًا بيئة إثبات موثوقة لهذا المسار دون استعادة migration lineage ومخطط الـaudit المتوافقين. كما أن ملف migration المرجعي نفسه يحتوي على أخطاء terminator تمنع replay المباشر.

## 6. التغييرات المنفذة وما لم ينفذ

### تم تنفيذه
1. قراءة الحالة الحالية والتقرير الحاكم والمصدر التشغيلي.
2. إعادة قراءة Production RPC definitions والقيود والبيانات في هذه الدورة.
3. توثيق drift في Staging بدليل مباشر.
4. استعادة مفاتيح أساسية مفقودة في Staging فقط بعد إثبات سلامة قيم المفاتيح:
   - `companies_pkey`
   - `runsheets_pkey`
   - `orders_pkey`
5. محاولة replay للمخطط المرجعي على Staging؛ فشلت بأخطاء موثقة ولم تُسجل migration، ولم تُنشئ جداول اللوجستيات.

### لم ينفذ — ولا أدعي خلاف ذلك
- لم يُعدّل ملف HTML التشغيلي أو `main.html`.
- لم تُعدّل RPC في Production.
- لم يُنشأ أي `delivery_agents` أو `delivery_route_plans` في Production.
- لم تُنفذ عملية إسناد HTTP مصادق عليها من المتصفح.
- لم يُثبت Cloudflare served-artifact parity.
- لم يُعلن الإغلاق أو نشر إصلاح.

## 7. قرار الإصلاح

الإصلاح الدائم يجب أن يحسم عقد التكامل دون إنشاء مصدر حقيقة موازٍ. المسار المرشح هو توسيع عقد الإسناد الذري ليستفيد من آليات اللوجستيات القائمة لإنشاء/مطابقة ملف المندوب وخطة `Draft` وربطها بالرانشيت عند انطباق شروطها، مع idempotency، وعزل الشركة، وفك الربط عند unassign، وعدم تغيير السائق أو المركبة أو حالة الرانشيت. لكن لا يجوز نشر هذا التغيير قبل أن تُستعاد بيئة Staging القابلة لإعادة تشغيل الهجرات، ثم اختبار السيناريو كاملًا. لا يجوز تحويل فشل Staging إلى مبرر لتجربة غير معزولة في Production.

## 8. Execution Gates

| Gate | الحالة | السبب |
|---|---|---|
| 0 — Directive and Scope Lock | PASS | قرئت الوثائق المرجعية وحدود المهمة |
| 1 — Current-State and Source Verification | PASS | المصدر الحالي وProduction contracts والبيانات أعيد فحصها |
| 2 — Reproduce and Localize Failure | PARTIAL | سبب عدم تطابق نموذج القراءة مثبت؛ HTTP/browser reproduction لم يُنفذ |
| 3 — Root-Cause Confirmation and Change Design | PASS (diagnosis only) | السبب واضح؛ التنفيذ النهائي ما زال يحتاج اختبارًا |
| 4 — Pre-Change Safety Review | PASS for read-only investigation; FAIL for release readiness | Staging drift يمنع اختبارًا مطابقًا |
| 5 — Controlled Implementation | BLOCKED | لا يوجد تعديل وظيفي؛ لا توجد بيئة Staging سليمة للتحقق |
| 6 — Contract/Auth/Data Integrity | PARTIAL | عقد RPC ومخطط Production فُحصا؛ لا يوجد E2E إيجابي |
| 7 — End-to-End Acceptance | BLOCKED | لم يُنفذ browser/HTTP E2E |
| 8 — Deployment and Runtime | BLOCKED | لا يوجد نشر إصلاح ولا إثبات artifact منشور |
| 9 — Final Audit and Closure | PARTIAL | تقرير موثق، لكن الإصلاح والإغلاق غير مكتملين |

## 9. SELF-AUDIT FINAL

**What I Proved**
- الإسناد في Production محفوظ في `runsheets.deliverer_id`.
- نموذج النظام الأم للمناديب يعتمد `delivery_agents` وخطط الرحلات.
- يوجد حاليًا صفر صفوف في هذين النموذجين مقابل رانشيتين مسندتين.
- Staging يفتقد جداول اللوجستيات ومخطط audit المتوافق.
- ملف migration المرجعي يتضمن فاصلتين منقوطتين مفقودتين بعد أجسام دوال PL/pgSQL.

**What I Did Not Prove**
- أن إصلاحًا جديدًا يعمل عبر واجهة المشرف والمتصفح.
- أن شاشة النظام الأم تعرض الإسناد بعد إصلاح فعلي.
- أن HTML المنشور يطابق Git.
- أن Production أصبح مصححًا.

**What I Fixed**
- أصلحت مفاتيح PK المفقودة في Staging فقط، بعد التحقق من تفردها وعدم null.
- لم أنفذ تغييرًا وظيفيًا في Production لأن Staging لم يصل إلى حالة يمكن الاعتماد عليها للاختبار.

**What I Initially Missed**
- أن migration اللوجستيات المرجعي غير قابل لإعادة التشغيل كما هو بسبب terminators مفقودة.
- أن Staging يفتقد PKs أساسية و`fn_audit_trigger()` وحقول audit التي تتوقعها نسخة Production.

**What Could Still Be Wrong**
- قد توجد فروق إضافية بين Staging وProduction غير المكتشفة بعد.
- لم يُختبر مسار الواجهة عبر HTTP/JWT/Browser.
- يلزم مراجعة consumers أخرى لعقد Delivery Logistics قبل نشر أي تغيير في RPC مشتركة.

**Final Confidence:** مرتفع في التشخيص؛ منخفض في أي ادعاء عن إصلاح وظيفي لم يُنفذ.  
**Final Closure Status:** `PARTIALLY COMPLETED — NOT CLOSED`.  
**Remaining:** إصلاح migration lineage وStaging audit schema، ثم تنفيذ واختبار عقد التكامل، ثم Production deploy وE2E والتحقق من العرض الفعلي.
