# تقرير 501 — إصلاح إعادة تحميل الرانشيت بعد إعادة الفتح
**LAST VERIFIED EVENT:** `LVE-2026-10-25-501`  
**التاريخ:** 25 أكتوبر 2026  
**النطاق:** خطأ `complete-loading` «كمية التحميل تتجاوز الكمية المحجوزة» عند إعادة تحميل رانشيت سبق تحميله وإعادة فتحه.  
**الحالة:** CORE FIX DEPLOYED / CURRENT REOPENED RUNSHEET RESERVATION RESTORED / ROLLBACK-ONLY CORE RUNTIME TEST PASS / UI HTTP E2E NOT RUN.

---

## 1. SELF-AUDIT قبل التنفيذ

| البند | التقييم | الدليل/الحد |
|---|---|---|
| فهم المشكلة التشغيلية | CONFIRMED | رسالة HTTP 400 التي أبلغ عنها المالك، مع تعريف Core الحي |
| Production Edge identity | CONFIRMED | Supabase live registry + get_edge_function |
| Production Core diagnosis | CONFIRMED | `pg_get_functiondef` للدوال الثلاث: `complete_runsheet_loading`, `complete_runsheet_reopen_loading`, `post_stock_movement` |
| حالة بيانات الرانشيت المتأثر | CONFIRMED | استعلامات Production للرانشيت RS-1، حركات Unloading، الأرصدة والحجوزات |
| Historical/current source history | PARTIAL | قرأت CURRENT_STATE checkpoint الأحدث والتقارير ذات الصلة 500 و499 و497 والحوكمة/مهمة التنفيذ ذات الصلة؛ لم أجر جردًا تاريخيًا لكل migrations غير المرتبطة |
| صحة الحل المعماري | CONFIRMED | إعادة الحجز عبر `reserve_stock` بعد عكس الحركة المركزية، في نفس معاملة إعادة الفتح |
| HTTP UI E2E | NOT RUN | لا أُكمل عملية تحميل إنتاجية حقيقية كاختبار؛ ذلك سيُثبت حركة مخزون نهائية لا اختبارًا معزولًا |
| إعلان الإغلاق 100% | NOT CLAIMED | لم يُختبر زر Loader من جلسة مستخدم عبر HTTP بعد الإصلاح |

**Unknowns قبل التنفيذ:** هل يوجد إصلاح لاحق غير موثق للدالة؟ حُسم بفحص تعريف Production الحي. هل كان الرصيد المحجوز يُعاد بعد Unloading؟ حُسم من التعريف الحي وبيانات RS-1.  
**Conflicts:** لا يوجد تعارض في تعريف Core بعد تطبيق migration؛ لم تُثبت مطابقة Cloudflare HTML مع Git.  
**Unverified:** Browser/HTTP E2E من جلسة المستخدم، والنشر الفعلي لآخر Loader HTML على Cloudflare.

## 2. الحالة الحية قبل الإصلاح

### 2.1 Edge
- Function: `complete-loading`
- Production status: `ACTIVE`
- Version: `v11`
- `verify_jwt=true`
- `ezbr_sha256=c0ca692a29d14d64ec3729ae4bd12b9b84268e826ffc1c6993a48617b552b286`
- وظيفة Edge تقرأ المستخدم من `public.users` بواسطة `auth_id = auth.users.id`، ثم تستدعي RPC `complete_runsheet_loading`.
- لم أغيّر Edge Function أو إعدادات JWT.

### 2.2 السبب الجذري المثبت
في تعريف Production السابق لـ`complete_runsheet_reopen_loading`:
1. كان يعكس حركة التحميل عبر `post_stock_movement(..., 'Unloading', ...)`.
2. كان ينقل الرصيد الفعلي من مخزن المركبة إلى المخزن الرئيسي.
3. كان يغيّر حالة الرانشيت إلى `Loading` ويولّد `loading_cycle_id` جديدًا.
4. **لم يكن يعيد حجز الكمية التي أُعيدت إلى المخزن الرئيسي.**

في المقابل، `post_stock_movement` يطبّق عقدًا صحيحًا: عند `Loading` يشترط `stock_branches.allocated_qty >= qty`، ثم يخصم الكمية من `qty` ومن `allocated_qty`. لذلك كانت إعادة الفتح تعيد `qty` دون إعادة `allocated_qty`، فتفشل دورة التحميل التالية رغم عدم تغيير الكميات في الواجهة.

هذه ليست مشكلة تنسيق أو رسالة UI، ولا يجوز تجاوزها بتخفيف فحص الحجز أو بكتابة مباشرة من Loader.

### 2.3 دليل بيانات Production قبل الإصلاح
- `RS-1` كان في الحالة `Loading` بدورة جديدة `2c4d113a-dd02-430d-ad3b-b9b4e05bc737`.
- رُصدت خمس حركات `Unloading` لعملية إعادة الفتح `0af40f83-7aac-473c-936a-4cf9f2e71f71)، مجموعها **13 وحدة**.
- لم توجد حركات `Loading` في الدورة الجديدة قبل الإصلاح.
- الأرصدة الفعلية للمخزن الرئيسي كانت قد عادت، بينما بقي الحجز عند القيم السابقة لا عند القيم اللازمة لإعادة تحميل نفس الكميات.

| كود الصنف | `qty` قبل إصلاح الحجز | `allocated_qty` قبل | كمية إعادة الحجز المطلوبة |
|---|---:|---:|---:|
| 1001 | 6 | 1 | 4 |
| 1003 | 5 | 1 | 3 |
| 1004 | 9 | 1 | 4 |
| 1005 | 10 | 1 | 1 |
| 1008 | 1 | 0 | 1 |
| **الإجمالي** | — | — | **13** |

## 3. الإصلاح المنفذ

### 3.1 Canonical migration
أُضيفت migration إلى المستودع المرجعي:

`supabase/migrations/20261025195614_reopen_loading_restore_reservation_20261025.sql`

- Blob SHA: `e4a0f38e01f083b394050372b0f9e7c519a051e8`
- Git commit الذي أضاف المسار canonical: `4820dbf43c92fd85a48487a74a11d4f4229813b7`
- أزيل ملف migration المؤقت ذو timestamp غير المطابق حتى لا يبقى مصدران لنفس الإصلاح؛ commit الحذف: `07e5cd3c95c146f1aeaaa7c37a550ce342d6e5c3`.
- Migration registry في Production سجّل: `20261025195614 / reopen_loading_restore_reservation_20261025`.

### 3.2 التغيير الدقيق
داخل `complete_runsheet_reopen_loading`، وبعد عكس الحركة المادية لكل صنف بواسطة `post_stock_movement(..., 'Unloading', ...)`، تنفّذ الدالة الآن:

```sql
PERFORM public.reserve_stock(
  p_company_id,
  m,
  d.item_id,
  d.qty_loaded
);
```

وتجمع التفاصيل حسب `item_id` لمنع تكرار المعالجة إذا ظهر الصنف في أكثر من تفصيل.

**لماذا الكمية هي `qty_loaded`؟** لأن التحميل السابق استهلك الحجز بمقدار الكمية المحمّلة الفعلية. إعادة الفتح تعكس هذه الكمية فقط؛ إعادة حجز `qty_picked` بالكامل قد تحجز ما لم يُستهلك أصلًا، فتؤدي إلى حجز مزدوج.

تجري الحركة العكسية وإعادة الحجز وانتقال الحالة داخل معاملة واحدة. إذا فشلت إعادة الحجز، تُلغى حركة Unloading المقابلة تلقائيًا بسبب فشل المعاملة؛ لا يُترك نصف إصلاح.

### 3.3 الأمان والعقد
- بقي `post_stock_movement` محرك الحركة المادية المركزي.
- بقي `reserve_stock` محرك الحجز فقط.
- لم تتغير دالة `complete-loading` المنشورة أو عقد HTTP الخاص بها.
- بعد التعديل: `complete_runsheet_reopen_loading` ما زالت `SECURITY DEFINER`، و`anon/authenticated EXECUTE=false`، و`service_role EXECUTE=true`، وتم التحقق من ذلك مباشرة من Production.
- لا يُخفَّف فحص `allocated_qty` في محرك الحركة.

## 4. إصلاح حالة RS-1 المفتوحة بالفعل

تغيير تعريف الدالة يصلح عمليات إعادة الفتح اللاحقة، لكنه وحده لا يصلح الحجز الذي فُقد بالفعل في دورة `RS-1` المفتوحة قبل التغيير. لذلك نُفذ تصحيح بيانات محدود ومشروط بعد إثبات الحالة الحية.

### حواجز التصحيح
لم يُنفّذ التصحيح إلا بعد التحقق من جميع الشروط التالية:
- نفس الشركة والرانشيت ومعرّف الدورة الحالي المحدد.
- الحالة `Loading`.
- وجود خمس حركات إعادة فتح محددة بالـ`operation_id` نفسه ومجموعها 13.
- عدم وجود حركة `Loading` في الدورة الجديدة.
- مطابقة الأرصدة والحجوزات السابقة لقيم baseline المحددة أعلاه.
- مطابقة `run_sheet_details.qty_loaded` للكميات المراد استعادة حجزها.

استخدم التصحيح `reserve_stock` فقط لكل صنف. لم يُعد حركة مادية، ولم يُدخل `inventory_log` جديدًا، ولم يغيّر `qty` أو حالة الرانشيت أو دورة التحميل. لو لم تطابق أي قيمة الحواجز، لكان التصحيح قد توقف بخطأ بدل تعديل بيانات مختلفة.

## 5. نتائج التحقق بعد الإصلاح

### 5.1 الأرصدة والحجوزات
| كود الصنف | `qty` بعد | `allocated_qty` بعد | `available_qty` بعد |
|---|---:|---:|---:|
| 1001 | 6 | 5 | 1 |
| 1003 | 5 | 4 | 1 |
| 1004 | 9 | 5 | 4 |
| 1005 | 10 | 2 | 8 |
| 1008 | 1 | 1 | 0 |

- إجمالي الحجز المستعاد: **13 وحدة**.
- `qty` بقي دون تغيير في تصحيح الحجز.
- لم تُضف حركات مخزون جديدة أثناء تصحيح الحجز.
- حالة `RS-1` بقيت `Loading` في نفس `loading_cycle_id`.
- لم تُنفذ عملية تحميل فعلية ضمن هذا التحقق.

### 5.2 Core runtime — اختبار مع rollback
نُفذ استدعاء فعلي لـ`complete_runsheet_loading` على سياق RS-1 الحالي داخل كتلة فرعية تُجبر rollback بعد أن تعيد الدالة استجابة نجاح. هذا الاختبار لا يترك آثارًا تشغيلية.

بعد الاختبار، تحققت مباشرة من:
- حركات `Loading` للدورة الحالية = **0**.
- سجل `complete_runsheet_loading` لهذه الدورة = **0**.
- حالة الرانشيت = `Loading`.
- الأرصدة والحجوزات بقيت مطابقة لقيم ما بعد التصحيح أعلاه.

**النتيجة: PASS لاختبار Core داخل معاملة تُلغى بالكامل.** هذا يثبت أن مسار Core استطاع قبول الكميات والحجوزات الحالية دون تثبيت حركة أعمال، لكنه **ليس** HTTP E2E ولا اختبارًا من المتصفح.

### 5.3 ACL / migration
- تعريف Production النهائي للدالة قُرئ مباشرة بعد migration.
- `anon EXECUTE=false`.
- `authenticated EXECUTE=false`.
- `service_role EXECUTE=true`.
- migration registry يحتوي النسخة `20261025195614`.

## 6. ما لم يتم اختباره
- لم يُنفذ HTTP E2E من واجهة Loader بجلسة مستخدم حقيقية؛ لأن ذلك سيعتمد على استكمال تحميل فعلي ويثبت حركة مخزون في Production، وليس اختبارًا معزولًا.
- لم أعد نشر `complete-loading`؛ لم يتغير كود Edge ولم تكن هناك حاجة لإعادة نشره لهذا الإصلاح.
- لم أغيّر `loader.html` أو `picker.html`؛ السياسة التنفيذية الحالية تجعل المالك يطبق تعديلات HTML، كما أن سبب الخطأ كان في Core لا في الواجهة.
- لم أتحقق من النسخة التي يقدمها Cloudflare حاليًا؛ Git لا يثبت النسخة المنشورة.
- لا أدعي إغلاق عيوب التفويض الأخرى التي وُثقت تاريخيًا في مسار `reopen-loading` Edge؛ لم يكن هذا الإصلاح تغييرًا أمنيًا لذلك الـEdge.

## 7. Mutation ledger
1. **APPLIED / DEPLOYED:** تحديث `public.complete_runsheet_reopen_loading` في Production عبر migration `20261025195614`.
2. **APPLIED:** استعادة حجز 13 وحدة للرانشيت المفتوح RS-1 باستخدام `reserve_stock` بعد فحص preconditions.
3. **VERIFIED:** قراءة تعريف الدالة وACL وحالة migration من Production بعد التطبيق.
4. **VERIFIED:** اختبار Core transactional مع rollback، ثم التحقق من عدم وجود حركات أو registry rows دائمة للدورة الحالية.
5. **NOT CHANGED:** Edge `complete-loading` v11، وLoader/Pick­er HTML، و`post_stock_movement`، والبيانات الفعلية `qty`، وحالة الرانشيت.
6. لا توجد بيانات Harness أو Canary أنشأها هذا الإجراء.

## 8. الإجراء التالي الدقيق
1. على المالك إعادة فتح Loader وتحديث الجلسة إن لزم، ثم فتح `RS-1` في قائمة `قيد التحميل` والتحقق من أن الكميات المعروضة تطابق المحضّر.
2. تنفيذ الإنهاء من واجهة Loader مرة واحدة فقط بعد التأكد من صحة الكميات. هذه ستكون عملية أعمال حقيقية، وليست اختبار rollback؛ يجب أن تسجل حركات `Loading` للدورة الحالية وتحوّل الحالة إلى `Loaded`.
3. بعد التنفيذ، تحقق من استجابة HTTP و`runsheets.status` و`inventory_log` وأرصدة MAIN/VAN. لا تضغط الإنهاء بالتزامن ولا تكرر الإجراء بعد نجاحه.
4. اختبر إعادة فتح ثانية فقط بعد نجاح الإكمال الأول ومراجعة الأرصدة، للتأكد من أن الحجز يُستعاد تلقائيًا في الدورة الجديدة.

## 9. SELF-AUDIT FINAL

**What I Proved**
- السبب الجذري هو عكس الحركة المادية عند إعادة الفتح دون إعادة الحجز المستهلك.
- Production Core أُصلح وأُثبت تعريفه وACL بعد التطبيق.
- حالة RS-1 المفتوحة أُعيد حجز الكميات الخمس بإجمالي 13 وحدة.
- Core loading يقبل الحالة المصححة داخل اختبار rollback دون آثار دائمة.

**What I Did Not Prove**
- نجاح طلب HTTP من Loader بعد الإصلاح.
- تطابق HTML المنشور في Cloudflare مع آخر Commit في Git.
- إغلاق مشكلات التفويض المنفصلة في Edge `reopen-loading`.

**What I Fixed**
- إضافة `reserve_stock` بعد كل حركة Unloading في Core reopen.
- استعادة الحجز المستهلك للدورة المفتوحة الحالية دون تغيير الرصيد الفعلي.

**What I Initially Missed**
- يجب أن تتضمن إعادة فتح دورة التحميل استعادة الحجز الذي استهلكه التحميل السابق، لا عكس `qty` فقط. هذا حُسم بفحص تعريف Production والأرصدة الحية قبل التعديل.

**What Could Still Be Wrong**
- قد تفشل واجهة HTTP بسبب مشكلة مستقلة في جلسة المستخدم أو نشر HTML أو بيانات أخرى؛ لم يُنفذ هذا المسار بعد.
- توجد مسائل تاريخية في تفويض Edge `reopen-loading` لم تُغلق بهذا الإصلاح.

**Final Confidence:** مرتفع في السبب الجذري وإصلاح Core وحالة الحجز؛ متوسط في جاهزية المسار الكامل حتى واجهة المستخدم إلى أن يتم HTTP E2E.  
**Final Closure Status:** `CORE FIX DEPLOYED + CURRENT RESERVATION REPAIRED + CORE ROLLBACK TEST PASS / UI HTTP E2E OPEN / NOT 100% CLOSED`.
