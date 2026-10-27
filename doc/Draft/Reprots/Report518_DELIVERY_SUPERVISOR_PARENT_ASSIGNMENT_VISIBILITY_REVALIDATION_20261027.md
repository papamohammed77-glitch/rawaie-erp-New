# Report518 — إعادة التحقق الجنائي لتكليفات مشرف التوصيل داخل النظام الأم

**التاريخ:** 2026-10-27  
**وقت لقطة Production الأخيرة:** 2026-10-27 16:54:45.121165 UTC  
**النطاق:** Delivery Supervisor → النظام الأم → إدارة التوصيل والشحن → مناديب التوصيل  
**النتيجة:** `PARTIALLY COMPLETED`  
**الحالة التنفيذية:** `ROOT CAUSE CONFIRMED / OWNER PATCH STILL REQUIRED / NOT APPLIED / NOT DEPLOYED / E2E OPEN`

## 1. PRE-CHANGE SELF-AUDIT

- **Business Understanding — CONFIRMED:** إسناد مندوب إلى رانشيت هو تكليف تشغيلي مستقل عن إنشاء سجل مندوب إداري في `delivery_agents`، ومستقل عن تعيين مندوب لخطة مسار في `delivery_route_plans`.
- **Architecture Understanding — CONFIRMED:** تطبيق المشرف يحفظ `runsheets.deliverer_id` من خلال RPC مركزي قائم. بطاقة النظام الأم الحالية تعرض كيان `delivery_agents` وتستمد مؤشرات الرحلات من `delivery_route_plans`.
- **Database Understanding — CONFIRMED:** أُعيد فحص الجداول والعلاقات وتعريفات RPC والصلاحيات وبيانات Production مباشرة.
- **Historical Understanding — CONFIRMED:** تمت قراءة `CURRENT_STATE.md` وأحدث سلسلة تقارير 514–517، مع استخدام التقارير لتحديد ما يجب إعادة التحقق منه لا كبديل عن الأدلة الحية.
- **Production Understanding — CONFIRMED:** لقطة SQL جديدة في 16:54:45 UTC، ومقارنة فعلية لنتائج read models داخل معاملة قراءة تنتهي بـROLLBACK.
- **Current Understanding — CONFIRMED:** أُعيد جلب `supervisor.html` وblob `main.html` من المستودع التشغيلي؛ لم يتغير SHA المرصود في هذه الجولة عن المرجع الذي بنيت عليه Report517.
- **Execution Confidence:** مرتفع في تشخيص اختلاف read models؛ غير مكتمل في إغلاق تجربة المستخدم لأن تعديل HTML التشغيلي يجب أن يدمجه المالك وفق قواعد الحوكمة.

## 2. التعليمات والقيود الحاكمة

قُرئ المستند المرجعي الكامل:

`rawaie-erp-New/doc/Draft/Reprots/MASTER_CTO_EXECUTION_PROMPT_LOADER_PICKER_INTEGRATION_20261025.md`

- Blob SHA: `abfa9d376c455ad7466b9404eed6f0a2c2166ede`
- عدد الأسطر: 371.
- يؤكد أن تقارير الماضي ليست دليل Runtime، وأن التعديل يجب أن يكون جراحيًا ومسنودًا بالدليل.
- يحظر تعديل `companies/company-1/main.html` وملفات التطبيقات التشغيلية مباشرةً؛ المالك يطبق تغييرات HTML التشغيلية.
- يمنع DDL/DML أو حركة أعمال إنتاجية بغرض الاختبار غير المعزول.

الوثيقة `doc/Draft/Reprots/writing-block.md` تحتوي في نهايتها على مهمة Loader/Picker أقدم مختلفة النطاق؛ لم أسمح لها بتحويل المهمة الحالية عن تكليف Delivery Supervisor الوارد في التوجيه الحالي. لم أستخدم أدوات التحكم التفاعلي بالمتصفح أو أطلب صلاحية للوصول إلى علامات التبويب.

## 3. مصادر المصدر الحالي

| المصدر | SHA / النتيجة | ما يثبته |
|---|---|---|
| `erp-frontend/companies/company-1/delivery/supervisor.html` | blob `3e6db903cd7da411f9ed40a449f9ee5bece5f387` | الواجهة تستدعي `delivery_supervisor_assignment_query` للقراءة و`delivery_supervisor_assign_deliverer_atomic` للكتابة |
| `erp-frontend/companies/company-1/main.html` | blob `b9bd5698c98c4b3d7e2bc388bacfbf4f43f2a919`؛ 1,787,034 حرفًا و33,136 سطرًا عند جلب Git blob | `async function agents()` تبدأ عند السطر 30,668، وبطاقة المندوبين تقرأ `q('agents',...)` |
| `erp-frontend/companies/company-1/core.js` | blob `ff2f581d9900543c16f7cb026e13446520c0329d` | هوية التطبيق والصلاحيات العامة؛ لا يلزم تعديله لإصلاح فجوة العرض المثبتة |
| `CURRENT_STATE.md` قبل هذا التقرير | blob `87cceb5302d92003dffe858f1df9a20e7dd1867e` | أحدث حدث سابق LVE-2026-10-27-517؛ حزمة المالك موجودة لكن لم تطبق |

## 4. السبب الجذري المثبت

**CONFIRMED — اختلاف عقد القراءة (Read-model mismatch)، وليس فشل حفظ الإسناد.**

1. واجهة المشرف تحفظ مندوب التوصيل في `public.runsheets.deliverer_id`.
2. RPC `delivery_supervisor_assignment_query(uuid,text)` يعيد فريق التوصيل من `public.users`، ويعيد الرانشيتات من `public.runsheets` متضمنة `deliverer_id`.
3. النظام الأم في `agents()` يستدعي `delivery_logistics_query` بالعرض `agents`، والذي يقرأ `public.delivery_agents` ويعرض حقول المندوب الإداري ومؤشرات الخطط.
4. عرض `routes` يعتمد على `public.delivery_route_plans`، بما في ذلك `delivery_agent_id`.
5. لا يوجد في بطاقة `agents()` الحالية جزء يعرض تكليفات `runsheets.deliverer_id`.

لذلك لا يجوز إنشاء سجل `delivery_agents` أو خطة `delivery_route_plans` تلقائيًا فقط لإظهار تكليف المشرف؛ ذلك سيخلط كيانين وعقدين مختلفين.

## 5. أدلة Production المباشرة

### 5.1 لقطة البيانات

استعلام Production للقراءة فقط عند 2026-10-27 16:54:45.121165 UTC:

| القياس | النتيجة |
|---|---:|
| إجمالي الرانشيتات | 2 |
| رانشيتات لديها `deliverer_id` | 2 |
| سجلات `delivery_agents` | 0 |
| سجلات `delivery_route_plans` | 0 |
| سجلات `delivery_route_stops` | 0 |

الصفوف الموجودة:

| الرانشيت | الحالة | مندوب التوصيل | `driver_id` | `vehicle_id` |
|---|---|---|---|---|
| RS-2 | Loaded | `driver3@rawaea.com` | NULL | موجود |
| RS-1 | Loaded | `driver@rawaea.com` | NULL | موجود |

لم تتغير هذه الصفوف في هذه الجولة، ولم تُستخدم كبيانات اختبار.

### 5.2 مقارنة read models

نُفذت مقارنة قراءة في معاملة SQL مع claims محاكاة لمستخدم المشرف المعروف، ثم انتهت المعاملة بـ`ROLLBACK`. هذه مقارنة عقد قاعدة بيانات وليست HTTP/JWT E2E.

- `delivery_supervisor_assignment_query(...,'team')`: أعادت 4 مندوبي توصيل نشطين.
- `delivery_supervisor_assignment_query(...,'runsheets')`: أعادت RS-1 وRS-2 مع `deliverer_id` الصحيح.
- `delivery_logistics_query(...,'agents',...)`: أعادت `rows=[]`.
- `delivery_logistics_query(...,'routes',...)`: أعادت `rows=[]`.

هذا الاختلاف يحدد موضع فقدان الظهور في read model الخاص بالنظام الأم.

### 5.3 RPC والأمان

- الدالتان موجودتان في Production:
  - `delivery_supervisor_assignment_query(uuid,text)`
  - `delivery_supervisor_assign_deliverer_atomic(uuid,text,uuid,text)`
- كلتاهما `SECURITY DEFINER` مع `search_path = public, pg_temp`.
- ACL الحالي يمنح `EXECUTE` إلى `authenticated` و`service_role`، وليس `anon` أو `PUBLIC`.
- عقد القراءة يربط المستخدم المصادق عليه عبر `public.users.auth_id = auth.uid()`، ويتحقق من الشركة والحالة والصلاحيات.
- عقد الإسناد يتحقق من أهلية مندوب التوصيل ونطاق الشركة، ويقيد تحديث الرانشيت بالحالة `Loaded`، ويستخدم `erp_operation_registry` للـidempotency.

### 5.4 سجل التشغيل

تظهر سجلات Supabase طلبات HTTP ناجحة `200` إلى `/rest/v1/rpc/delivery_supervisor_assignment_query` من الواجهة المستضافة على `rawaea-erp.pages.dev`، كما تظهر طلبات ناجحة إلى دالة الإسناد. هذا دليل على أن مسار RPC استُخدم فعليًا، لكنه **ليس** دليلًا على أن بطاقة النظام الأم عرضت التكليف بصريًا.

## 6. LOSS / GAIN / RESPONSIBILITY MATRIX

| المسؤولية | التصنيف | الدليل / القرار |
|---|---|---|
| حفظ تكليف المشرف | RETAINED | `runsheets.deliverer_id` محفوظ وRPC الإسناد موجود |
| قراءة فريق التوصيل التشغيلي | RETAINED | `delivery_supervisor_assignment_query` يعيد المستخدمين المؤهلين |
| قائمة المندوبين الإداريين | RETAINED | `delivery_agents` لها عقد مستقل يجب الحفاظ عليه |
| خطط المسارات والمحطات والتحصيل | RETAINED | `delivery_route_plans` و`delivery_route_stops` تبقى مستقلة |
| عرض تكليفات الرانشيت في بطاقة النظام الأم | MISSING | لا يوجد في `agents()` الحالية عرض لـ`runsheets.deliverer_id` |
| إنشاء Agent/Route Plan تلقائيًا عند تكليف المشرف | INTENTIONALLY NOT ADDED | يخلط العقود ويصنع سجلات أعمال لم يطلبها المسار |
| تعديل supervisor/Core/RPC/ACL/RLS | RETAINED / NO CHANGE | لم يثبت عيب في مسار الحفظ أو الحاجة لتغييره |

## 7. التغيير الجراحي المقترح للمالك

الحزمة التفصيلية ذات النص البديل الكامل ومحددات الاستبدال موجودة بالفعل في:

[`Report517_DELIVERY_SUPERVISOR_PARENT_ASSIGNMENT_VISIBILITY_EXECUTION_20261027.md`](Report517_DELIVERY_SUPERVISOR_PARENT_ASSIGNMENT_VISIBILITY_EXECUTION_20261027.md)

تظل صالحة ما دام SHA الحالي لـ`main.html` هو `b9bd5698c98c4b3d7e2bc388bacfbf4f43f2a919). تتكون من:

1. إضافة `assignedRunsheetsCard()` داخل نطاق `RW_DeliveryLogistics` قبل `agents()`.
2. استبدال تركيب بطاقة `agents()` فقط ليعرض بطاقة قائمة المندوبين الحالية وبطاقة قراءة مستقلة لتكليفات الرانشيت.
3. الإبقاء على معالج البحث `dl-agent-search` دون تغيير.
4. استخدام RPC القراءة الموجود، دون إنشاء RPC أو جدول أو Edge Function جديد.
5. مطابقة شرط عرض البطاقة لصلاحيات RPC: `*` أو `delivery_supervisor` أو `fleet.read` أو `fleet.manage`.

**لم تُطبق الرقعة**؛ حوكمة المشروع تمنع المساعد من تعديل `main.html` مباشرة. لم أغير `supervisor.html` لأن عيب الحفظ غير مثبت، ولم أغير قاعدة البيانات لأن العقد الحالي كافٍ لقراءة التكليفات.

## 8. نتائج بوابات التنفيذ

| البوابة | الحالة | الدليل / السبب |
|---|---|---|
| Gate 0 — النطاق والتعليمات | PASS | تمت قراءة التوجيه الحالي والمستند المرجعي الكامل؛ النطاق محصور في ظهور تكليفات المشرف |
| Gate 1 — الحالة الحالية | PASS | SHA وموضع `agents()` ومصدر supervisor وعقود Production جرى التحقق منها |
| Gate 2 — إعادة الإنتاج/تحديد الفشل | PASS جزئيًا | مقارنة SQL تثبت أن بيانات التكليف موجودة لكن Parent agents/routes فارغة؛ العرض البصري لم يُختبر |
| Gate 3 — السبب والتصميم | PASS | السبب اختلاف read models؛ الإصلاح المقترح read-only داخل بطاقة النظام الأم |
| Gate 4 — سلامة ما قبل التعديل | PASS | تم فحص SHA الحالي والمخطط والقيود وACL؛ لا حاجة إلى DDL/DML |
| Gate 5 — التنفيذ الجراحي | NOT APPLIED | لم يُعدل HTML التشغيلي امتثالًا لسياسة أن المالك يطبق التغيير |
| Gate 6 — العقد والأمان | PASS على مستوى المصدر وSQL | تحقق الشركة والهوية والصلاحية؛ لا يثبت وحده اختبار HTTP مستقلًا لكل حالات الرفض |
| Gate 7 — E2E والانحدار | NOT RUN / UNVERIFIED | لم تُنفذ تجربة واجهة مصادقة كاملة، ولم يُختبر العرض المرئي بعد الدمج |
| Gate 8 — النشر وRuntime | UNVERIFIED | لم يُنشر تعديل Parent، ولم تُطابق نسخة Cloudflare بعد التعديل |
| Gate 9 — التدقيق والإغلاق | PARTIAL | التقرير وسجل الاستمرارية هما التغييران الوحيدان في هذه الجولة |

## 9. Mutation ledger

- `companies/company-1/main.html`: لا تغيير.
- `companies/company-1/delivery/supervisor.html`: لا تغيير.
- Core / Edge / RPC / DDL / DML / ACL / RLS: لا تغيير.
- بيانات الأعمال: لا تغيير.
- RS-1 وRS-2: لم تُستخدم كـfixtures ولم تتغير.
- اختبارات المتصفح والـCloudflare parity: لم تُنفذ.
- التغيير المنجز في هذه الجولة: إعادة تحقق مباشرة وتوثيق؛ حزمة التعديل الجراحي للمالك ما زالت في Report517.

## 10. ما تبقى لإغلاق المهمة

1. على المالك تطبيق رقعة Report517 فقط بعد التأكد من أن SHA لـ`main.html` لم يتغير.
2. فحص JavaScript للصفحة كاملة بعد الدمج.
3. تسجيل دخول Parent بمستخدم مصرح له، والتأكد من ظهور RS-1 وRS-2 والمندوب والتاريخ والحالة.
4. اختبار مستخدم غير مخول، مع بقاء رفض الخادم هو المرجع الأمني.
5. التأكد من بقاء قائمة `delivery_agents` والبحث ومسار `ROUTE_AGENT_ASSIGN` وخطط المسارات والتحصيل والأداء دون تغيير.
6. نشر الصفحة ثم فحص HTML الذي يقدمه Cloudflare ومطابقته للمصدر المقصود.
7. تنفيذ E2E مصادق عبر تطبيق المشرف ثم النظام الأم. لا تستخدم RS-1 أو RS-2 كبيانات اختبار.

## 11. SELF-AUDIT FINAL

- **What I Proved:** التكليف محفوظ في Production؛ read model الخاص بالمشرف يعيده؛ Parent agents/routes لا يعرضانه لأنهما يقرآن كيانين مختلفين؛ الـRPCs الحالية محمية من anon.
- **What I Did Not Prove:** ظهور البطاقة بصريًا بعد الدمج، اختبار متصفح/HTTP E2E جديد، نشر Cloudflare، أو تطابق النسخة المنشورة.
- **What I Fixed:** لم أغير الكود التشغيلي؛ أعدت التحقق من السبب، وحافظت على الرقعة الجراحية الموثقة بدل إنشاء مسار بيانات مكرر.
- **What I Initially Missed:** لا ينبغي تفسير «عدم الظهور» على أنه فشل حفظ. نقطة الفقد هي تركيب بطاقة Parent، لا جدول التكليفات.
- **What Could Still Be Wrong:** احتمال اختلاف صلاحيات جلسة Parent الفعلية أو اختلاف النسخة التي تقدمها Cloudflare؛ لا يحسم ذلك إلا اختبار ما بعد الدمج.
- **Final Confidence:** HIGH في السبب الجذري؛ MEDIUM في سلامة الرقعة حتى تنفيذ الاختبارات؛ runtime غير متحقق.
- **Final Closure Status:** `PARTIAL — ROOT CAUSE CONFIRMED / OWNER PATCH REQUIRED / NOT APPLIED / NOT DEPLOYED / E2E OPEN`.
