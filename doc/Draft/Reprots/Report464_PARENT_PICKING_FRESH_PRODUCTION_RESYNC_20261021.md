# Report464 — إعادة مزامنة Production لتبويب التحضير (Picking)
**التاريخ:** 2026-10-21 UTC  
**النطاق:** تكامل جدول وتفاصيل Picking في `erp-frontend/companies/company-1/main.html`، وتفسير رفض `complete-picking` في Production.  
**سياسة التعديل:** لم أعدّل `main.html` أو `warehouse/picker.html`؛ هذه الملفات يطبق المالك تغييراتها. لم أغيّر بيانات الأعمال أو مخطط Production أو RPC/Edge Function لأن الأدلة الحالية لا تثبت خللًا جديدًا يستوجب ذلك.

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** VERIFIED — يجب التمييز بين كمية تم تحضيرها وحفظها فعلًا وبين كمية لم يكتمل تحضيرها، مع احترام حجز المخزون.
- **Architecture Understanding:** VERIFIED — `order_details.qty_picked` هو المصدر التفصيلي؛ `run_sheet_details.qty_picked` إسقاط تجميعي يُحدّثه `trg_sync_run_sheet_details`. إكمال التحضير يمر عبر Edge `complete-picking` ثم RPC `complete_runsheet_picking` ويستدعي `reserve_stock`.
- **Database Understanding:** VERIFIED — تم فحص الأعمدة الفعلية، وتعريف Trigger المزامنة، وبيانات الرانشيتات الحية ومخزون الصنف 1008.
- **Historical Understanding:** VERIFIED — تمت مراجعة CURRENT_STATE وتقارير Report462/463 وcommits الأخيرة، مع إعطاء الأولوية لقراءة Production الجديدة.
- **Production Understanding:** VERIFIED — مشروع `fiilmooggumokxanwiyx` نشط؛ Edge `complete-picking` إصدار 18، ACTIVE، `verify_jwt=true`، SHA نشر `14b4d650253e73abc7c7a1b1f25a8674849c11e32d21ae9928701f19705b0537`.
- **Current Source Understanding:** VERIFIED WITH LIMITATION — SHA ملف `main.html` الحالي `bb10422217fc57a9a42c2bf65a55e9470a19537c`. تقارير التحقيق المباشر الأخيرة وثّقت مواضع Picking 15282–15512. أداة جلب الملف الكبير أعادت SHA دون محتوى كامل في هذه الدورة؛ لذلك لم أدّعِ إعادة قراءة الملف الكامل من جديد.
- **Execution Confidence:** مرتفع في حالة قاعدة البيانات وسبب رفض الحجز؛ غير مكتمل في إثبات ما عرضه متصفح المستخدم لأن استجابة Network وهوية HTML المخدوم لم تُقدّما.

## CURRENT PRODUCTION — قراءة مباشرة

وقت آخر استعلام SQL: `2026-10-21 15:52:37.687084+00 UTC`.

### حالة الرانشيتات

| الرانشيت | الحالة | أسطر التفاصيل | المطلوب | المحضّر | المحمّل |
|---|---|---:|---:|---:|---:|
| RS-1 | Picked | 11 | 14 | 13 | 0 |
| RS-2 | Picking | 9 | 9 | 0 | 0 |

بيانات RS-1 في `order_details` و`run_sheet_details` متوافقة وفق الفحص الحي السابق، ومجموع `qty_picked=13`. أما RS-2 فما زال في حالة Picking ومجموعه الحالي صفر؛ هذا لا يثبت أن تفاصيل RS-1 تظهر صفرًا.

### عقد المزامنة

Trigger `trg_sync_run_sheet_details` على `public.order_details` يعمل بعد INSERT/UPDATE/DELETE ويستدعي `sync_run_sheet_details()`. الدالة تجمع `sum(od.qty_picked)` وتحدث `run_sheet_details.qty_picked` حسب الرانشيت والصنف. لم يظهر في البيانات الحالية عدم تطابق يبرر إصلاح Trigger أو إعادة بناء الإسقاط.

### سبب رفض إكمال RS-2

Production logs تسجل رفضًا من `reserve_stock(uuid,uuid,uuid,numeric)` داخل `complete_runsheet_picking(uuid,text,text,jsonb,uuid)`، وEdge logs تؤكد HTTP 400 من `complete-picking` v18.

في الفرع الرئيسي `BR-01`، الصنف `1008` — «مصاصه 2ج»:
- `qty = 1`
- `allocated_qty = 1`
- `available_qty = 0`

الوحدة الوحيدة المتاحة محجوزة بالفعل ضمن RS-1، الذي يحتوي على كمية محضّرة 1 من هذا الصنف. لذلك فإن طلب حجز وحدة إضافية في RS-2 يجب أن يُرفض. هذا ليس خللًا ينبغي تجاوزه بتعديل `allocated_qty` أو تعطيل `reserve_stock`.

**المعالجة التشغيلية الصحيحة:** في جلسة RS-2، سجّل الكمية المحضّرة الفعلية للصنف 1008 بصفر مع ملاحظة نقص مناسبة، ثم أعد محاولة إنهاء التحضير. إذا كان هناك مخزون إضافي موجود ماديًا بالفعل، فاستلمه عبر مسار حركة المخزون المركزي المعتمد قبل إعادة المحاولة. لا تُدخل كمية أو حركة مخزون افتراضية.

## مراجعة طلب المالك

1. **مسؤول التحضير ووقت البداية والنهاية والملاحظات:** التقارير الأخيرة التي فحصت المصدر الحالي تؤكد وجود هذه الأعمدة، وحل اسم المحضّر عبر `get_picking_display_users(uuid[])`، وتجميع `reason_picking`. لا تُعد تطبيق إصلاحات Report458/459.
2. **الكمية المحضّرة عند فتح رانشيت مكتمل:** المصدر الموثق يقرأ `run_sheet_details.qty_picked`، وProduction تثبت أن RS-1 لديه 13. لا يوجد دليل حالي يثبت أن الاستعلام يعيد صفرًا لرانشيت RS-1.
3. **HTTP 400 عند إنهاء RS-2:** السبب الجذري مثبت: المتاح للصنف 1008 يساوي صفرًا بسبب الحجز السابق. لا يلزم تعديل SQL/Edge لإزالة هذا الرفض الصحيح.
4. **لماذا لا أقدّم استبدالًا برمجيًا الآن؟** لأن ذلك سيكون تغييرًا مبنيًا على افتراض. إذا استمر ظهور صفر لـRS-1 في المتصفح، يجب تسجيل استجابة Network الفعلية لطلب `run_sheet_details` مع الرانشيت المطلوب، والوقت، وهوية HTML المخدوم؛ ثم مطابقة الاستجابة مع استعلام Production في نفس اللحظة. لا يُستبدل كود صحيح لمجرد أن المتصفح أظهر قيمة متعارضة مرة واحدة.

## التغييرات والاختبارات

- Source changes: NONE.
- Production schema/RPC/Edge changes: NONE.
- Production business data changes: NONE.
- Static verification: تم الاعتماد على مواضع المصدر الموثقة في تقرير التحقيق الأحدث، مع تسجيل قيد أن جلب الملف الكبير أعاد metadata/SHA فقط في هذه الدورة.
- Database verification: PASS — RS-1 picked total 13؛ RS-2 picked total 0 وهو ما يزال Picking؛ Trigger المزامنة يجمع الكميات من المصدر التفصيلي.
- HTTP E2E: FAIL متوقع لإكمال RS-2 عندما يتضمن الصنف 1008 بكمية موجبة؛ سجل Production يثبت سبب الرفض.
- Served HTML parity / browser E2E: UNVERIFIED.
- Test residue: لم تُنشأ fixtures ولم تُجرَ تغييرات كتابة؛ لا يوجد أثر اختباري أنشأته هذه الدورة.

## SELF-AUDIT FINAL

- **What I Proved:** حالة Production الحالية للرانشيتين؛ كمية RS-1 المحضّرة 13؛ RS-2 لا يزال Picking ومجموعه صفر؛ Trigger الإسقاط؛ نسخة Edge الحالية؛ سبب HTTP 400 ومخزون الصنف 1008.
- **What I Did Not Prove:** أن HTML المخدوم يطابق SHA الحالي؛ أو أن متصفح المستخدم يعرض صفرًا لـRS-1 في نفس وقت الاستعلام؛ أو Browser E2E.
- **What I Fixed:** لم أجرِ تغييرًا لأن لا يوجد عيب جديد مثبت يبرره. حدّدت المعالجة التشغيلية الصحيحة لرفض RS-2.
- **What I Initially Missed:** يجب الفصل بين صفر RS-2 قبل الإكمال وبين ادعاء صفر RS-1 بعد اكتماله؛ البيانات الحية تثبت الأولى ولا تثبت الثانية.
- **What Could Still Be Wrong:** قد تكون الواجهة المخدومة مختلفة عن Git، أو قد يكون طلب المتصفح قرأ بيانات/رانشيتًا مختلفًا. لا يمكن حسم ذلك دون Network response وserved artifact identity.
- **Final Confidence:** مرتفع في سبب رفض الحجز واتساق بيانات Production التي تم فحصها؛ متوسط في تفسير شكوى العرض غير المعاد إنتاجها.
- **Final Closure Status:** `PRODUCTION CORE + CURRENT DATA VERIFIED / NO NEW CODE CHANGE JUSTIFIED / SERVED HTML + BROWSER E2E UNVERIFIED`.
- **Next exact step:** (1) عالج نقص الصنف 1008 في RS-2 حسب الواقع المادي ثم أعد الإكمال. (2) إذا بقي RS-1 يعرض صفرًا، التقط Network response لطلب `run_sheet_details` وهوية HTML المخدوم قبل أي تعديل. (3) لا تُعدّل `main.html` أو `picker.html` إلا بعد إثبات موضع الخلل الدقيق.
