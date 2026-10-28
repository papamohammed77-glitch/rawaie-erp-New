# Report531 — التحقيق التشغيلي لتكليفات مشرف التوصيل في النظام الأم
**التاريخ:** 2026-10-28  
**النطاق:** supervisor PWA → Production RPC → runsheets/users → parent UI render → Cloudflare tab  
**الحالة:** `DATABASE + RPC + SOURCE CONFIRMED / AUTHENTICATED UI E2E UNVERIFIED / NO NEW PATCH JUSTIFIED`

## 1. PRE-CHANGE SELF-AUDIT
- **Business Understanding — CONFIRMED:** تكليف الرانشيت محفوظ في `public.runsheets.deliverer_id`. هذا التكليف مستقل عن سجل `public.delivery_agents`، ولا يشترط وجود سجل لوجستيات كي يظهر.
- **Architecture Understanding — CONFIRMED:** صفحة مشرف التوصيل تقرأ من `delivery_supervisor_assignment_query`، والنظام الأم يقرأ من `delivery_logistics_query(p_view='agents')`. العقد يعيد `rows` لسجل مناديب اللوجستيات و`runsheet_assignments` للتكليفات الفعلية كحقلين منفصلين.
- **Database Understanding — CONFIRMED:** قاعدة Production هي `fiilmooggumokxanwiyx`، ووقت القراءة الحية `2026-10-28 20:10:51.634776+00`.
- **Historical Understanding — CONFIRMED:** تمت مراجعة `CURRENT_STATE.md` وReport530؛ Report530 استُخدم كدليل بحث لا كبديل عن التحقق الحي.
- **Production Understanding — CONFIRMED:** تعريف `public.delivery_logistics_query(uuid,text,jsonb,uuid,text)` يحتوي فرع `agents` الذي يبني `runsheet_assignments` من `runsheets.deliverer_id` ويضم `public.users` على الشركة نفسها.
- **Current Source — CONFIRMED:** `papamohammed77-glitch/erp-frontend`, `main`, `companies/company-1/main.html`, blob SHA `0c1745081e8d17480433ed527d77cac9f5292021`. مصدر Git يتضمن بالفعل `async function agents()`، ويقرأ `d.runsheet_assignments` ثم يبني جدول «تعيينات الرانشيت من مشرف التوصيل».
- **Execution Confidence:** مرتفع لقاعدة البيانات وعقد RPC ومسار الرسم في Git؛ غير كافٍ لإثبات عرض الواجهة بعد تسجيل الدخول لأن التبويب المتصل غير مصادق عليه ولا يمكن تنفيذ التفاعل من أداة القراءة الحالية.

## 2. Fresh Production evidence
استعلام حي مباشر إلى `delivery_logistics_query(..., 'agents', ...)` باستخدام هوية مالك النظام النشطة أعاد:
- `success=true`
- `rows=[]` لسجل `delivery_agents` (صفر مناديب لوجستيات مسجلين).
- `runsheet_assignments` يحتوي عنصرين:
  - `RS-2` — `Loaded` — مندوب توصيل 3 — `driver3@rawaea.com`.
  - `RS-1` — `Loaded` — مندوب توصيل — `driver@rawaea.com`.
- `delivery_agent_code=null` للتكليفين، وهو يعبّر عن عدم وجود ربط بسجل `delivery_agents` ولا يلغي التكليف الفعلي.
- لم تُعدّل بيانات الرانشيتات أو المخزون أو الحجوزات أو القيود المحاسبية.

## 3. Consumer / rendering trace
| الطبقة | الدليل | النتيجة |
|---|---|---|
| Production DB | `runsheets.deliverer_id` joins `users.id` داخل الشركة نفسها؛ RS-1 وRS-2 موجودان | CONFIRMED |
| Production RPC | `delivery_logistics_query` يعيد `runsheet_assignments` في فرع `agents` | CONFIRMED |
| RPC caller في parent source | `q(view,payload)` يستدعي `supabase.rpc('delivery_logistics_query', {p_company_id,p_view,p_payload,...})` | CONFIRMED |
| Consumer | `agents()` ينفذ `q('agents',...)` ويقرأ `d.runsheet_assignments` | CONFIRMED |
| Table render | `assignmentRows` تُحوّل التكليفات إلى صفوف ثم تُعرض داخل `assignmentTable` في بطاقة «تعيينات الرانشيت من مشرف التوصيل» | CONFIRMED |
| Cloudflare commit lineage | Report530 وثّق أن commit النشر المرصود `8843150bdde99d36d477d6bb344a24df61dd2942` يتضمن commit إصلاح المصدر `cb62612a174f5b1a8d5aa5a41a4c3e5747bb73fc` في أسلافه | CONFIRMED بحسب دليل Report530؛ لم يُجرَ تحقق جديد من لوحة النشر في هذه الدورة |
| Authenticated browser render | التبويب المتصل يعرض شاشة تسجيل الدخول فوق DOM للصفحة الأم؛ لم تُنفّذ عملية تسجيل دخول/تحديث/فتح تبويب تفاعلية | UNVERIFIED |

## 4. Root cause decision
**لا يوجد عيب حالي مثبت في بيانات Production أو RPC أو كود render في Git.** المسار موجود بالفعل ويعيد Production التكليفين. لذلك لا أغيّر SQL أو البيانات أو `main.html` بالتخمين، ولا أكرر إصلاح commit `cb62612`.

الجزء الوحيد المفتوح هو إثبات واجهة مصادق عليها بعد تحميل النسخة الحالية. التبويب المتصل حاليًا غير مصادق عليه، والموصل المتاح للمتصفح هنا للقراءة فقط؛ لذا لم أستطع تنفيذ Ctrl+Shift+R أو تسجيل الدخول أو فتح مركز التوصيل نيابة عن المستخدم. هذا قيد تفاعل محدد، وليس Block على التحقيق أو دليلًا على فشل Production.

## 5. القرار الجراحي
**لا يوجد تعديل جراحي جديد مبرر حاليًا.** العنصر الصحيح الموجود بالفعل:
- الملف: `erp-frontend/companies/company-1/main.html`
- الدالة: `async function agents()`
- محدد البحث: `var assignments=Array.isArray(d.runsheet_assignments)?d.runsheet_assignments:[];`
- ثم `var assignmentRows=assignments.map(...)` و`assignmentTable` و`card('تعيينات الرانشيت من مشرف التوصيل',...)`.

لا تستبدل هذا العنصر؛ فهو موجود ويستهلك عقد Production الصحيح. تعديل آخر دون إثبات عطل render قد يكرر الإصلاح أو يسبب regression. لا تعديل على `main.html` أو ملف المشرف أو Production.

## 6. الإجراء التشغيلي الوحيد لإغلاق إثبات الواجهة
على المالك في التبويب المنشور:
1. نفّذ تحديثًا قسريًا للصفحة `Ctrl+Shift+R`.
2. سجّل الدخول بالطريقة المعتادة.
3. افتح `مركز التوصيل واللوجستيات → مناديب التوصيل`.
4. تحقق من ظهور جدول «تعيينات الرانشيت من مشرف التوصيل» وفيه RS-1 وRS-2.
5. إن غاب الجدول، التقط استجابة Network لطلب `delivery_logistics_query` مع `p_view=agents` وبيانات `runsheet_assignments`، مع حجب Cookies وAuthorization وأي أسرار.

النتائج المحتملة محددة مسبقًا:
- RPC response فيه RS-1 وRS-2 والجدول ظاهر: وثّق DOM/صورة وأغلق مشكلة العرض.
- RPC response فيهما والجدول غير ظاهر: عندها فقط تُجهّز جراحة جديدة في مسار render بعد استخراج النص الحالي كاملًا ورقم السطر.
- RPC response لا يحتويهما: افحص معاملات الطلب ونسخة RPC المخدومة قبل أي تعديل SQL.

## 7. Mutation ledger
- لا تغييرات في Production DB/RPC/ACL/RLS/Edge Functions.
- لا تغييرات في `main.html` أو `supervisor.html`.
- لا بيانات تجريبية أُنشئت؛ البيانات الحقيقية الموجودة RS-1 وRS-2 تكفي لاختبار عقد القراءة ولا حاجة لتعريض Production لصفوف اختبار.
- لا بيانات صحيحة حُذفت أو عُدّلت.
- تم تحديث هذا التقرير ومرجع الحالة فقط.

## 8. SELF-AUDIT FINAL
- **What I Proved:** تكليفان حقيقيان في Production؛ RPC يعيد التكليفين؛ كود parent الحالي يحتوي consumer وtable render؛ عدم وجود `delivery_agents` لا يعني فقد التكليف.
- **What I Did Not Prove:** عرض الجدول بعد تسجيل دخول حقيقي في المتصفح؛ تطابق HTML المخدوم بايتًا ببايت مع Git.
- **What I Fixed:** لم أجرِ إصلاحًا تشغيليًا جديدًا لأن العيب لم يثبت في طبقات DB/RPC/Git.
- **What I Initially Missed:** `rows=[]` لا يساوي غياب التكليفات؛ التكليفات موجودة في `runsheet_assignments` المنفصل.
- **What Could Still Be Wrong:** قد يوجد خلل DOM/runtime خاص بالجلسة بعد المصادقة لم يظهر في قراءة التبويب غير المصادق عليه.
- **Final Confidence:** مرتفع في DB/RPC/source؛ متوسط في نشر الواجهة؛ غير مكتمل في authenticated UI E2E.
- **Final Closure Status:** `BACKEND + SOURCE CONTRACT VERIFIED / AUTHENTICATED UI E2E OPEN / NOT CLOSED`.
