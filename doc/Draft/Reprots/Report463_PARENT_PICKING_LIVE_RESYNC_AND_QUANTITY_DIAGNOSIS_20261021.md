# Report463 — مراجعة حية لتكامل جدول التحضير وكميات التحضير

التاريخ: 2026-10-21  
النطاق: `erp-frontend/companies/company-1/main.html`، قسم Picking فقط، مع تحقق Production من `runsheets` و`order_details` و`run_sheet_details` ومخزون الفرع الرئيسي.  
قاعدة التنفيذ: ملفات `main.html` و`warehouse/picker.html` يطبقها المالك؛ لم أعدّل أيًّا منهما. لم أجرِ تغييرات كتابة على Production أو بيانات الأعمال.

## PRE-CHANGE SELF-AUDIT

- Business Understanding: VERIFIED — هذه مراجعة لعرض بيانات دورة التحضير في النظام الأم، لا لإعادة بناء تطبيق Picker.
- Architecture Understanding: VERIFIED — `order_details.qty_picked` هو مصدر التحضير التفصيلي، و`run_sheet_details.qty_picked` إسقاط مشتق يُحدّثه `trg_sync_run_sheet_details`.
- Database Understanding: VERIFIED — تمت قراءة المخطط والبيانات الحية وتعريف دالة المزامنة.
- Historical Understanding: VERIFIED — تمت مراجعة CURRENT_STATE وتقارير 458–462 و461، مع تقديم الدليل الحي على التقارير التاريخية.
- Production Understanding: VERIFIED — استعلامات قراءة مباشرة وسجلات PostgreSQL من المشروع `fiilmooggumokxanwiyx`.
- Current Source Understanding: VERIFIED — قراءة blob الحالي لـ `main.html` SHA `bb10422217fc57a9a42c2bf65a55e9470a19537c`، 1,782,052 حرفًا / 33,000 سطرًا، مع فحص مواضع Picking 15282–15512. آخر commit للملف المرصود: `aafc769abd2a4d5539e6183990eaf6b9b989566b` بتاريخ 2026-10-21 15:12:22 UTC؛ رسالته تعديل تعليق HTML فقط.
- Execution Confidence: مرتفع لحقائق Git/DB والسبب المباشر لفشل إكمال RS-2؛ غير كافٍ لإثبات هوية HTML المخدوم أو إعادة إنتاج صفر RS-1 في المتصفح.

## الأدلة الحالية

### 1. أعمدة جدول التحضير

في المصدر الحالي، `loadPicking()` يعرض بالفعل الأعمدة:
- مسؤول التحضير
- وقت بداية التحضير
- وقت الانتهاء
- ملاحظات التحضير المجمعة
- مع بيانات الرانشيت والتاريخ والسائق والحالة والعرض

المصدر يجلب `picker_id`, `picker_start`, `picker_end`، ويستدعي `get_picking_display_users(uuid[])` لحل اسم المحضّر، ويجمع `order_details.reason_picking` حسب الرانشيت. لا تُعد تطبيق إصلاحات Report458/459 على نطاق واسع؛ هذه العناصر موجودة بالفعل في SHA الحالي.

### 2. تفاصيل الكمية المحضّرة

الدالة الحالية `_showPickingDetails(code)` في الأسطر 15471–15512:
- تتحقق من خطأ استعلام الرانشيت ومن عدم وجوده.
- تتحقق من خطأ استعلام `run_sheet_details`.
- تقرأ `item_code,item_name,unit,qty_ordered,qty_picked` من `run_sheet_details`.
- تعرض `qty_picked` من السجل المسترجع؛ اسم العمود والجدول صحيحان في المخطط الحالي.

لا يوجد في المصدر الذي فُحص خطأ مثبت يبرر استبدال دالة التفاصيل أو إعادة كتابة الجدول.

### 3. Production — لقطة مباشرة

وقت قراءة SQL: `2026-10-21 15:38:41 UTC`.

- `RS-1`: الحالة `Picked`؛ `picker_start` و`picker_end` موجودان؛ مجموع `qty_picked` هو **13** في `run_sheet_details` ومطابق لـ `order_details`.
- `RS-2`: الحالة `Picking`؛ `picker_end` فارغ؛ مجموع `qty_picked` هو **0** في المصدرين. هذا متوقع قبل إكمال التحضير، وليس دليلًا على أن تفاصيل RS-1 تعود بصفر.
- Trigger `trg_sync_run_sheet_details` يعمل بعد INSERT/UPDATE/DELETE على `order_details`، ويعيد تجميع الكميات إلى `run_sheet_details`. تعريفه الحالي يجمع `sum(od.qty_picked)` ويحدّث الصف المشتق.
- لا توجد بيانات تجريبية جديدة أُنشئت في هذه الدورة.

### 4. سبب رفض HTTP لإكمال RS-2

سجلات PostgreSQL الحالية تحتوي على `insufficient available stock for reservation` عند استدعاء `complete_runsheet_picking(uuid,text,text,jsonb,uuid)` من خلال `complete-picking`.

الدليل الحي:
- الصنف `1008` — `مصاصه 2ج`: كمية الفرع الرئيسية 1، والكمية المحجوزة 1، والمتاح 0.
- `RS-1` لديه لهذا الصنف كمية محضرة 1 وحجز 1.
- `RS-2` يطلب وحدة إضافية من الصنف نفسه، لكن المتاح صفر.

إذن رفض الحجز صحيح وفق عقد المخزون؛ لا تتجاوز `reserve_stock` ولا تعدّل `allocated_qty` يدويًا. إذا كان الصنف غير متاح فعليًا، سجّل الكمية المحضّرة صفرًا مع ملاحظة نقص مناسبة. إذا كان هناك مخزون فعلي إضافي، أدخله عبر مسار حركة المخزون المركزي المعتمد ثم أعد المحاولة.

## التعديل الجراحي المطلوب

**لا يوجد تعديل جديد مبرر حاليًا في `main.html` أو Production** على الأدلة الحالية:
- الأعمدة المطلوبة موجودة.
- معالجة أخطاء استعلام التفاصيل موجودة.
- RS-1 يعيد كمية محضرة صحيحة = 13 من Production.
- RS-2 صفر لأنه لم يُنهَ بعد.
- HTTP 400 الحالي سببه نقص المتاح للصنف 1008، وليس خطأ واجهة مثبتًا.

إذا ظل RS-1 يعرض صفرًا بعد إعادة تحميل قوية، فالإجراء التالي المحدد هو التقاط Network response الفعلي لطلب `run_sheet_details`، وتسجيل URL/هوية HTML المخدوم، ثم مقارنة استجابة المتصفح بالاستعلام الحي. لا تُجرِ أي تعديل Core أو UI إضافيًا قبل هذا الدليل.

## SELF-AUDIT FINAL

- What I Proved: الأعمدة موجودة في Git الحالي؛ الاستعلام التفصيلي يقرأ العمود الصحيح؛ RS-1 = 13 في المصدر والـprojection؛ RS-2 = 0 قبل الإكمال؛ سبب HTTP 400 هو حجز صحيح مرفوض بسبب available=0 للصنف 1008.
- What I Did Not Prove: تطابق HTML المخدوم مع SHA الحالي، أو إعادة إنتاج مشكلة الصفر في متصفح المستخدم.
- What I Fixed: لا تغيير؛ لا يوجد Defect جديد مثبت يستدعي تعديلًا.
- What I Initially Missed: صفر RS-2 وظهور صفر مزعوم لـRS-1 حالتان مختلفتان؛ السجلات الحالية تثبت الأولى ولا تثبت الثانية.
- What Could Still Be Wrong: قد تكون النسخة المخدومة قديمة، أو قد تكون استجابة Network التي شاهدها المستخدم مختلفة عن لقطة Production الحالية.
- Final Confidence: مرتفع لبيانات Production وسبب رفض RS-2؛ متوسط لمشكلة المتصفح غير المعاد إنتاجها.
- Final Closure Status: `CURRENT SOURCE + PRODUCTION DATA/CORE VERIFIED / NO NEW SURGICAL CHANGE JUSTIFIED / SERVED HTML + BROWSER E2E UNVERIFIED`.
- تعليمات الاستئناف: ابدأ بقراءة هذا التقرير ثم أعد قراءة CURRENT_STATE وSHA الحالي لـmain.html. لا تكرر إصلاحات Report458/459/461. إذا بقي الصفر في RS-1، اجمع Network response وهوية HTML المخدوم أولًا. لا تُخفف عقد المخزون لعلاج خطأ UI.
