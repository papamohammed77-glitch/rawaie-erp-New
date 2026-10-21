# Report458 — التحقيق الجنائي لتكامل تبويب التحضير مع Production
**التاريخ:** 2026-10-21 UTC  
**النطاق:** جدول التحضير في `erp-frontend/companies/company-1/main.html`، تفاصيل الكميات، وسبب رفض `complete-picking` في Production.  
**سياسة التعديل:** لم أعدّل `main.html` أو `picker.html` لأنهما ضمن ملفات المالك التشغيلية. لم أجرِ تعديلًا على قاعدة البيانات أو Edge/RPC؛ الأدلة الحالية لا تبرر تجاوز حارس المخزون.

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** إنهاء التحضير يحجز الكمية الفعلية التي تم تحضيرها ولا ينفذ حركة مخزون فعلية؛ لا يجوز قبول كمية غير متاحة أو تجاوز الحجز القائم لرانشيت آخر.
- **Architecture Understanding:** تطبيق المحضّر يرسل `complete-picking` v18، الذي يستدعي `public.complete_runsheet_picking(uuid,text,text,jsonb,uuid)`. الدالة المركزية تستدعي `reserve_stock`. عرض تفاصيل التحضير في النظام الأم يقرأ `run_sheet_details`، وهي projection متزامنة من `order_details` عبر `trg_sync_run_sheet_details`.
- **Database Understanding:** Production project `fiilmooggumokxanwiyx`. الحقول الحالية تشمل `runsheets.picker_id/picker_start/picker_end`، و`order_details.qty_picked/reason_picking`، و`run_sheet_details.qty_picked`، و`stock_branches.qty/allocated_qty/available_qty`.
- **Historical Understanding:** راجعت `CURRENT_STATE.md` وآخر نقاط Picker حتى Report457 بوصفها أدلة تاريخية، ثم أعدت قراءة مصدر Git الحالي وتعريفات Production والسجلات الحية. لا أعتبر التقارير السابقة حالة حالية.
- **Production Understanding:** Edge `complete-picking` نشطة v18، `verify_jwt=true`، deployment hash `14b4d650253e73abc7c7a1b1f25a8674849c11e32d21ae9928701f19705b0537`.
- **Current Understanding:** `main.html` blob SHA `bb10422217fc57a9a42c2bf65a55e9470a19537c`, 33,000 سطرًا. أحدث commit ظاهر في تاريخ المستودع قبل سجل HTTP هو `0aef3a7daa98c20b45dd69c626167a60be2e598a` (Update main.html، 2026-10-21 15:09:32 UTC). أحدث commit بالمستودع كان إضافة استخراج جنائي، وليس تغييرًا تشغيليًا للتحضير.
- **Execution Confidence:** مرتفع لتشخيص حالة Git وProduction database/logs. مطابقة ملف HTML المخدوم عبر Cloudflare مع Git وBrowser E2E لم تثبت في هذه الجلسة.

## سجل القراءة والمصادر

- `erp-frontend/companies/company-1/main.html`: تمت قراءة blob الحالي واستخراج سياق `loadPicking`, `_applyPicking`, و`_showPickingDetails` (الأسطر 15301–15512).
- `erp-frontend/companies/company-1/warehouse/picker.html`: تم جلب المصدر الحالي؛ لم يتم تعديله.
- Production: تعريف `complete_runsheet_picking` و`reserve_stock`، triggers على `order_details`، وتعريف `sync_run_sheet_details()`.
- Production logs: طلب `POST /functions/v1/complete-picking` أعاد HTTP 400 في `2026-10-21 15:21:25 UTC`; سجل PostgreSQL يحدد السبب `insufficient available stock for reservation` داخل `reserve_stock`، أثناء `complete_runsheet_picking`.
- Production data: فُحصت حالتا `RS-1` و`RS-2` وعناصرهما ومخزون الفرع الرئيسي. الاستعلامات للقراءة فقط.

## النتيجة الأولى — أعمدة جدول التحضير

المطلوب (مسؤول التحضير، وقت البداية، وقت الانتهاء، ملاحظات التحضير) موجود بالفعل في مصدر Git الحالي:

- Header عند الأسطر 15306–15309.
- قراءة `picker_id,picker_start,picker_end` عند 15326–15331.
- تحويل `picker_id` إلى اسم عبر RPC `get_picking_display_users` عند 15343–15358.
- تجميع ملاحظات `reason_picking` من `order_details` حسب الرانشيت عند 15375–15406، مع فواصل عربية.
- عرض الأعمدة في الجدول عند 15463–15467.

**القرار:** لا تُعد تطبيق أي patch لهذه الأعمدة؛ التعديل موجود بالفعل في Git. لم يُثبت أن نسخة Cloudflare المنشورة تطابق هذا الـblob. إذا كانت الأعمدة غير ظاهرة في المتصفح، فالخطوة الصحيحة هي مقارنة الـserved artifact/cache بالـSHA الحالي، لا إعادة تعديل المصدر نفسه.

## النتيجة الثانية — الكمية المحضّرة تظهر صفرًا في تفاصيل الرانشيت

- `_showPickingDetails(code)` يقرأ `run_sheet_details.qty_picked` عند 15493–15497 ويعرض القيمة عند 15508–15510.
- Production trigger `trg_sync_run_sheet_details` يعمل بعد INSERT/UPDATE/DELETE على `order_details`.
- `sync_run_sheet_details()` يعيد بناء `run_sheet_details.qty_picked` من `sum(order_details.qty_picked)`؛ لذلك لا يوجد دليل على فجوة مزامنة في العقد الحالي.
- مقارنة Production المباشرة أثبتت أن `RS-1` بحالة `Picked` يعرض كميات مطابقة بين `run_sheet_details` و`order_details` (مثل item 1001 = 4، و1003 = 3، و1004 = 4، و1008 = 1).
- `RS-2` بحالة `Picking` لم يُنهَ بعد؛ القيم الحالية فيه صفر في المصدرين معًا، وهذا صحيح قبل نجاح إنهاء التحضير.

**القرار:** لم يثبت عيب في SQL projection أو في كود تفاصيل Git الحالي. إذا كان المتصفح يعرض صفرًا لـ`RS-1` رغم بيانات Production أعلاه، فهذا يشير إلى عدم تطابق artifact المخدوم/جلسة متصفح أو اختلاف وقت القراءة، ويجب إثباته من نفس الرانشيت ونفس وقت الاختبار قبل أي تعديل آخر. لا أغيّر `main.html` اعتمادًا على وصف لا يطابق البيانات الحية.

## النتيجة الثالثة — سبب HTTP 400 عند إنهاء `RS-2`

السجل الحي يثبت أن الفشل ليس خطأ CORS ولا تحذير Tailwind ولا مشكلة في Edge deployment. السبب هو شرط الحجز الصحيح في `reserve_stock`:

`available = qty - allocated_qty`; يرفض الحجز إذا كانت الكمية المتاحة أقل من الكمية المطلوبة.

| الصنف | المطلوب في RS-2 | رصيد فعلي | محجوز مسبقًا | متاح | النتيجة |
|---|---:|---:|---:|---:|---|
| 1001 — جو كيك 5ج | 1 | 6 | 4 | 2 | متاح |
| 1003 — شيبس تايجر طعوم 10ج | 1 | 5 | 3 | 2 | متاح |
| 1004 — شيبس تايجر طعوم 5ج | 2 | 9 | 4 | 5 | متاح |
| 1005 — سماش سادة 5ج | 2 | 10 | 1 | 9 | متاح |
| 1006 — جاجور سناكس طعوم 10ج | 1 | 11 | 0 | 11 | متاح |
| 1007 — تايجر شيبس 15ج | 1 | 2 | 0 | 2 | متاح |
| **1008 — مصاصة 2ج** | **1** | **1** | **1** | **0** | **الحجز مرفوض بحق** |

الرصيد الوحيد المتاح من الصنف 1008 محجوز بالفعل لرانشيت `RS-1`. لذلك فإن محاولة حجز وحدة أخرى في `RS-2` يجب أن تفشل. تعطيل الحارس أو تعديل `allocated_qty` يدويًا سيؤدي إلى حجز زائد ومخالفة عقد المخزون المركزي.

**الإجراء التشغيلي الصحيح:** في `RS-2` اجعل كمية الصنف 1008 المحضّرة صفرًا وسجّل سبب النقص، ثم أعد محاولة إنهاء التحضير. إذا كان الصنف موجودًا فعليًا إضافيًا، فليُسجّل استلام/زيادة مخزون صحيحة عبر مسار المخزون المعتمد أولًا؛ لا تُجرِ تعديلًا مباشرًا على الرصيد أو الحجز.

## Loss / Gain / Responsibility Matrix

| المسؤولية | الحالة | الدليل / الإجراء |
|---|---|---|
| أعمدة مسؤول التحضير والبداية والنهاية | RETAINED / PRESENT | موجودة في المصدر الحالي |
| تجميع ملاحظات التحضير | RETAINED / PRESENT | `reason_picking` مجمّع حسب الرانشيت |
| تفاصيل الكمية المحضّرة | PRESENT / DATA CONSISTENT | `run_sheet_details` متزامن مع `order_details`؛ RS-1 صحيح |
| حجز المخزون قبل إنهاء التحضير | CORRECT GUARD | رفض RS-2 للصنف 1008 بسبب available=0 |
| إصلاح Production SQL/Edge | NOT REQUIRED BY CURRENT EVIDENCE | لا تغيير نُفّذ |
| مطابقة HTML المخدوم مع Git | UNVERIFIED | يلزم تحقق من Cloudflare/browser |
| Browser E2E بعد التحقق | OPEN | لم يُنفذ في هذه الجلسة |

## التغييرات والاختبارات

- **Source changes:** NONE — لم أعدّل ملفات HTML التي يملك المالك تطبيق تعديلاتها.
- **Production schema/RPC/Edge/data changes:** NONE.
- **Static validation:** قرأت مواضع المصدر المحددة وتحققت من مسار القراءة/العرض.
- **Database verification:** PASS للاتساق بين `order_details` و`run_sheet_details` في الرانشيتات الحالية.
- **HTTP evidence:** FAIL متوقع لـ`RS-2` عند محاولة حجز الصنف 1008؛ السبب مثبت في PostgreSQL logs.
- **Baseline / residue:** لم تُنشأ fixtures ولم تُعدّل بيانات الأعمال؛ لم يلزم تنظيف.
- **Production served artifact parity:** UNVERIFIED.
- **Browser E2E:** UNVERIFIED.

## SELF-AUDIT FINAL

- **What I Proved:** الأعمدة المطلوبة موجودة في Git الحالي؛ مصدر الاسم هو RPC مخصص؛ الملاحظات تُجمع من تفاصيل الطلب؛ تفاصيل RS-1 تعكس الكميات المحضرة الحقيقية؛ RS-2 لم يُنهَ بعد؛ سبب HTTP 400 هو انعدام المتاح للصنف 1008 بسبب حجزه لرانشيت RS-1.
- **What I Did Not Prove:** أن HTML المخدوم حاليًا يطابق Git؛ أن حالة الصفر التي شاهدها المستخدم كانت في RS-1 وفي نفس لحظة الاستعلام؛ نجاح Browser E2E بعد إعادة التحميل/النشر.
- **What I Fixed:** لا تغيير برمجي/Production؛ لا يوجد Defect مثبت يبرر تعديلًا في هذه الدورة.
- **What I Initially Missed:** يجب فصل عطل العرض المبلغ عنه عن فشل حجز مخزون مثبت في سجل Production؛ فهما ليسا نفس المشكلة.
- **What Could Still Be Wrong:** قد تكون نسخة الواجهة المخدومة قديمة أو أن المستخدم فتح RS-2 قبل اكتماله؛ لا أستطيع تأكيد أي منهما دون served-artifact/browser evidence.
- **Final Confidence:** مرتفع في سبب HTTP 400 وفي حالة بيانات Production المقروءة؛ متوسط في سبب ملاحظة الواجهة بسبب عدم توفر إثبات النسخة المخدومة.
- **Final Closure Status:** `CURRENT GIT + PRODUCTION DATA/CORE VERIFIED / NO CODE CHANGE JUSTIFIED / SERVED ARTIFACT + BROWSER E2E OPEN`.
- **Next exact steps:** (1) لا تُعدّل أعمدة التحضير الموجودة في Git؛ قارن النسخة المنشورة بـSHA `bb10422217fc57a9a42c2bf65a55e9470a19537c`. (2) في RS-2 سجّل الصنف 1008 بكمية محضرة صفر وسبب النقص أو عالج المخزون عبر حركة صحيحة إن كان هناك رصيد فعلي غير مسجل. (3) أعد اختبار إنهاء التحضير وتأكد من عدم وجود حجز مزدوج. (4) إذا ظل RS-1 يعرض صفرًا، اجمع لقطة Network/response لنفس طلب تفاصيل الرانشيت قبل تعديل المصدر.
