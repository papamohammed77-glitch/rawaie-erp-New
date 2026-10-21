# Report462 — مزامنة التحضير مع Production: الأعمدة، الكمية المحضّرة، وحجز المخزون
**التاريخ:** 2026-10-21 UTC  
**النطاق:** جدول التحضير وتفاصيله في `erp-frontend/companies/company-1/main.html`، وفشل HTTP الفعلي من `complete-picking`.  
**حدود التنفيذ:** لم أعدّل `main.html` أو `picker.html` لأن المالك يطبق تغييرات ملفات الواجهة التشغيلية. راجعت Production مباشرة ولم أغيّر Core/Edge/ACL أو بيانات الأعمال لأن الرفض المسجل سببه عدم توفر المخزون، لا عيب مثبت في الحارس.

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** التحضير يسجل الكميات الملتقطة ويحجز المتاح؛ لا يخصم المخزون فعليًا. لا يجوز تجاوز الحجز لتمرير رانشيت متعارض.
- **Architecture Understanding:** `complete-picking v18` يستدعي `complete_runsheet_picking(..., p_operation_id)`; هذا يستدعي `reserve_stock`. `run_sheet_details` إسقاط مشتق من `order_details` عبر `trg_sync_run_sheet_details`. النظام الأم يعرض هذا الإسقاط في تفاصيل التحضير.
- **Database Understanding:** Production project `fiilmooggumokxanwiyx`; جداول `runsheets`, `orders`, `order_details`, `run_sheet_details`, `stock_branches` موجودة، وأعمدة هوية المحضّر وأوقات التحضير وملاحظات السطور موجودة.
- **Historical Understanding:** راجعت `CURRENT_STATE.md` حتى Report461 وتقارير Report458–461 ذات الصلة؛ استخدمتها كدلائل، ثم قارنت المصدر الحالي والـSQL والسجلات والبيانات مباشرة.
- **Production Understanding:** `complete-picking` ACTIVE v18، `verify_jwt=true`، deployment hash `14b4d650253e73abc7c7a1b1f25a8674849c11e32d21ae9928701f19705b0537`.
- **Current Understanding:** `main.html` blob SHA `bb10422217fc57a9a42c2bf65a55e9470a19537c`، 33,000 سطر. أحدث commit للمستودع في اللقطة كان `41beae7f5e54e22eeda66a44432e31fb5352a770`، وهو ملف استخراج جنائي؛ وأحدث commit سابق مباشر للملف الأم الظاهر هو `0aef3a7daa98c20b45dd69c626167a60be2e598a`.
- **Execution Confidence:** مرتفع في مصدر Git الذي تمت قراءته، وبيانات Production وسبب HTTP 400. Served HTML parity وBrowser E2E لم يثبتا.

## السجل الجنائي

- Current source: `erp-frontend/companies/company-1/main.html`, SHA أعلاه؛ تمت قراءة مواضع التحضير 15301–15512.
- Operational source: `erp-frontend/companies/company-1/warehouse/picker.html`, SHA `ffe18d4483ee074230e32b1c96f60507e5876a4b`; لم يُعدّل.
- Production SQL: تعريف `complete_runsheet_picking` و`reserve_stock` و`sync_run_sheet_details()`، triggers، وبيانات RS-1/RS-2.
- Production logs: `POST /functions/v1/complete-picking` أعاد 400 بتاريخ `2026-10-21 15:21:25 UTC`; سجل PostgreSQL يحدد `insufficient available stock for reservation` داخل `reserve_stock`.
- لم تُنشأ fixtures ولم تُحذف أو تُعدّل بيانات أعمال.

## 1. أعمدة جدول التحضير — موجودة بالفعل في Git

المصدر الحالي يحتوي الأعمدة المطلوبة:
- مسؤول التحضير، بداية التحضير، نهاية التحضير، وملاحظات التحضير: الأسطر 15306–15309.
- تحميل `picker_id,picker_start,picker_end`: 15326–15331.
- الاسم من `get_picking_display_users(uuid[])`: 15343–15358.
- تجميع `reason_picking` حسب الرانشيت، مع رقم الطلب واسم الصنف: 15375–15406.
- عرض الأعمدة: 15463–15467.

**القرار:** لا تكرر patches Report458/459؛ عناصرها موجودة في Git الحالي. عدم ظهورها في المتصفح لا يبرر إعادة تعديل المصدر ما لم تُطابق أولًا هوية الملف المخدوم مع SHA الحالي.

## 2. تفاصيل الكمية المحضّرة — بيانات Production لا تؤيد وجود صفر في RS-1

الدالة `_showPickingDetails(code)` تقرأ `run_sheet_details.qty_picked` وتعرضه عند الأسطر 15493–15510. Production trigger `trg_sync_run_sheet_details` يعمل على تغييرات `order_details`، و`sync_run_sheet_details()` يعيد بناء كميات الإسقاط من تفاصيل الطلبات.

النتائج الحية:
- `RS-1`: الحالة `Picked`; `sum(order_details.qty_picked)=13` و`sum(run_sheet_details.qty_picked)=13`. أمثلة: الصنف 1001 = 4، 1003 = 3، 1004 = 4، 1008 = 1.
- `RS-2`: الحالة `Picking`; الكمية المحضّرة في المصدرين = 0 لأنه لم يكتمل بعد.

**القرار:** لا يوجد دليل على فجوة SQL projection حاليًا. إذا كانت شاشة المتصفح تعرض صفرًا عند فتح RS-1، فالمطلوب قبل أي تعديل إضافي هو التقاط Network response لنفس طلب `run_sheet_details` وتحديد SHA/نسخة HTML المخدومة. لا تدّعِ أن المشكلة أُغلقت في المتصفح قبل ذلك.

## 3. سبب HTTP 400 — رفض مخزون صحيح وليس عيبًا يجب تجاوزه

في `RS-2`، الصنف `1008 — مصاصة 2ج` مطلوب بكمية 1، بينما `stock_branches.qty=1` و`allocated_qty=1`، وبالتالي `available_qty=0`. الكمية المتاحة محجوزة بالفعل للرانشيت `RS-1`. `reserve_stock` يرفض الحجز إذا كان `qty - allocated_qty < p_qty`. هذا هو السبب المباشر المسجل في Production.

بقية أصناف RS-2 وقت الفحص كان لديها متاح يكفي الكميات المطلوبة؛ التعارض المحدد هو الصنف 1008.

**الإجراء التشغيلي الصحيح:**
1. في `RS-2` اجعل كمية الصنف 1008 المحضّرة = 0، وسجّل ملاحظة واضحة عن عدم توفر كمية متاحة.
2. أعد محاولة إنهاء التحضير باستخدام مسار المحضّر المعتاد.
3. إذا كان هناك مخزون فعلي إضافي غير مسجل، أدخله من خلال حركة مخزنية صحيحة أولًا، ثم أعد المحاولة.
4. لا تُعدّل `allocated_qty` يدويًا ولا تُرخِ حارس `reserve_stock`؛ ذلك سيؤدي إلى حجز زائد ويتعارض مع قلب المخزون المركزي.

## LOSS / GAIN / RESPONSIBILITY MATRIX

| العنصر | الحالة | الدليل |
|---|---|---|
| أعمدة مسؤول/بداية/نهاية/ملاحظات التحضير | RETAINED / PRESENT | موجودة في مصدر Git الحالي |
| تجميع الملاحظات | PRESENT | `reason_picking` مجمّع لكل رانشيت |
| كمية RS-1 المحضّرة | VERIFIED | 13 في `order_details` و`run_sheet_details` |
| كمية RS-2 قبل الإنهاء | VERIFIED | صفر في المصدرين، والحالة Picking |
| حارس المخزون عند الإنهاء | CORRECT | available=0 للصنف 1008 |
| تعديل SQL/Edge/ACL | NOT WARRANTED | لا عيب Core مثبت في رفض الحجز |
| تطابق HTML المخدوم مع Git | UNVERIFIED | لم تتوفر هوية artifact المخدوم |
| Browser E2E | UNVERIFIED | لم ينفذ اختبار متصفح حي في هذه الدورة |

## التغييرات والاختبارات

- تعديل `main.html` / `picker.html`: لا شيء؛ ملفات المالك.
- Production schema/RPC/Edge/ACL/data: لا شيء.
- قراءة مصدر Git: PASS للمواضع المحددة.
- SQL cross-check للإسقاط: PASS — RS-1 totals متطابقة؛ RS-2 صفر قبل الإنهاء.
- HTTP: FAIL لطلب RS-2 بسبب المتاح صفرًا للصنف 1008؛ السبب الجذري مثبت في سجل PostgreSQL.
- Baseline/residue: لا fixtures أو تغييرات بيانات دائمة.
- Served-artifact parity وBrowser E2E: UNVERIFIED.

## SELF-AUDIT FINAL

- **What I Proved:** الأعمدة المطلوبة موجودة في Git؛ الاسم يُقرأ عبر RPC محدد؛ الملاحظات مجمعة؛ RS-1 لديه 13 وحدة محضّرة في المصدرين؛ RS-2 لم يكتمل بعد؛ HTTP 400 ناتج عن عدم توفر الصنف 1008 بعد حجزه لرانشيت RS-1.
- **What I Did Not Prove:** أن HTML المخدوم يطابق Git؛ أو أن المتصفح الذي عرض صفرًا كان يعرض RS-1 في نفس وقت فحص قاعدة البيانات.
- **What I Fixed:** لم أجرِ تغييرًا غير مبرر؛ لا يوجد عيب مثبت يبرر تغيير Core أو تخفيف الحجز.
- **What I Initially Missed:** ملاحظة الصفر المبلغ عنها وفشل الحجز في RS-2 مشكلتان منفصلتان؛ الثانية مثبتة كرفض مخزون صحيح، بينما الأولى لا تتكرر في بيانات RS-1 الحالية.
- **What Could Still Be Wrong:** قد تكون نسخة HTML المنشورة قديمة، أو قد تكون لقطة المتصفح تخص RS-2 قبل اكتماله. لا يمكن حسم ذلك دون Network/served-artifact evidence.
- **Final Confidence:** مرتفع في تشخيص Production للـHTTP 400 واتساق كميات RS-1؛ متوسط في تشخيص تجربة المتصفح غير المتاحة.
- **Final Closure Status:** `GIT + PRODUCTION DATA/CORE VERIFIED / NO CODE CHANGE JUSTIFIED / SERVED HTML + BROWSER E2E OPEN`.
- **Next exact steps:** تحقق من الكمية المحضرة في RS-1 عبر Network response إذا بقي الصفر ظاهرًا؛ قارن served HTML مع SHA الحالي؛ وفي RS-2 اجعل الصنف 1008 صفرًا مع سبب النقص أو أدخل المخزون الصحيح من مساره المركزي قبل إعادة المحاولة.
