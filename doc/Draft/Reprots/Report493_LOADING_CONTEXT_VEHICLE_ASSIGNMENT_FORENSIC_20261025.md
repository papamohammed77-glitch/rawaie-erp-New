# تقرير التحقيق الجنائي — خطأ إنهاء التحميل `invalid Loading context`
**رقم الحدث:** LVE-2026-10-25-493  
**التاريخ:** 2026-10-25  
**المشروع:** SMART ERP / Supabase Production `fiilmooggumokxanwiyx`  
**النطاق:** `loader.html → complete-loading → complete_runsheet_loading → runsheets / vehicles / VAN branch`  
**الحالة:** ROOT CAUSE CONFIRMED / PRODUCTION GUARD DEPLOYED / INVALID SESSION RESTORED / FULL LOADING E2E STILL OPEN

## 1. PRE-CHANGE SELF-AUDIT

| المجال | الحكم | الدليل |
|---|---|---|
| فهم دورة التحميل | CONFIRMED | `start_runsheet_loading` يغيّر حالة الرانشيت إلى Loading؛ `complete_runsheet_loading` يشترط مركبة ويحوّل المخزون عبر `post_stock_movement`. |
| Production Edge | CONFIRMED | قراءة مباشرة من Supabase في هذه الجلسة. |
| Production SQL | CONFIRMED | تمت قراءة التعريفين الفعليين قبل التعديل وبعده. |
| المصدر التشغيلي | CONFIRMED جزئيًا | أعيد جلب Loader وPicker وCore مباشرة من `erp-frontend/main`. |
| Historical / Current State | CONFLICT RECONCILED | `CURRENT_STATE.md` كان يسجل Loader SHA `97b83d68...`; القراءة الحية الحالية أعادت SHA `6bc6ad2...`، واحتوت بالفعل على تغييرات تقرير 492 الخاصة بعرض تفاصيل الصنف. |
| Runtime | PARTIAL | سجل HTTP/PostgreSQL الفعلي يثبت الفشل. اختبارات SQL الآمنة تثبت guard الجديد، لكن لم يكتمل HTTP E2E لتحميل ناجح بمركبة معيّنة. |
| الثقة التنفيذية | مرتفعة في السبب الجذري ومنع تكراره؛ غير كافية لإعلان الإغلاق الكامل | بيانات الرانشيت الحالي لا تحدد المركبة المقصودة. |

### مصادر فُتحت مباشرة

- التوجيه التنفيذي: `doc/Draft/Reprots/writing-block.md`.
- `erp-frontend/companies/company-1/warehouse/loader.html` — Git blob SHA الحالي: `6bc6ad2ee93396faca20576241ad3318679171ef`.
- `erp-frontend/companies/company-1/warehouse/picker.html` — Git blob SHA: `d483bd15b36585b975b63c2ef641481a01d5d084`.
- `erp-frontend/companies/company-1/core.js` — Git blob SHA: `ff2f581d9900543c16f7cb026e13446520c0329d`.
- Production Edge `complete-loading` و`start-loading`.
- Production SQL: `start_runsheet_loading(uuid,text,text)`, `complete_runsheet_loading(uuid,uuid,jsonb,text)`, `manage_runsheet_atomic(uuid,text,text,text,uuid,uuid)`.
- Production schema: `runsheets`, `vehicles`, `branches`, `run_sheet_details`, `order_details`, `inventory_log`.
- Production Edge/PostgreSQL logs للفشل الفعلي.

## 2. LIVE PRODUCTION SNAPSHOT

### Edge Functions

| Function | Version | Status | verify_jwt | ezbr_sha256 |
|---|---:|---|---|---|
| `complete-loading` | 11 | ACTIVE | true | `c0ca692a29d14d64ec3729ae4bd12b9b84268e826ffc1c6993a48617b552b286` |
| `start-loading` | 5 | ACTIVE | true | `afcfe32707382c57a15ebb744dec61e95a4079abb9ee8d32f479f322091230c7` |

لم أعد نشر Edge Function؛ الخلل المثبت كان في عقد بدء التحميل داخل PostgreSQL، لا في مصادقة Edge. `ezbr_sha256` هو digest للنشر وليس Git SHA.

### دليل الخطأ الفعلي

Production logs في 2026-10-25 عند نحو 15:24 UTC سجّلت:

- HTTP `POST /functions/v1/complete-loading` → `400`.
- PostgreSQL: `invalid Loading context`.
- السياق: `complete_runsheet_loading(uuid,uuid,jsonb,text) line 31 at RAISE`.
- deployment id يشير إلى `complete-loading` version 11.

### شرط الإكمال المركزي

تعريف Production الفعلي لـ`complete_runsheet_loading` يرفض الرانشيت إذا لم يتحقق كل مما يلي:

- الرانشيت موجود وتابع للشركة المحددة.
- `status = 'Loading'`.
- `vehicle_id IS NOT NULL`.
- `loader_start IS NOT NULL`.
- `loading_cycle_id IS NOT NULL`.

### سجل الرانشيت المتأثر

قبل الإصلاح، كان `RS-1` في `Loading` مع `vehicle_id = NULL`، رغم وجود `loader_id` و`loader_start` و`loading_cycle_id`. وكانت كميات التحميل المسجلة صفرًا، ولم توجد حركة `Loading` في `inventory_log` لهذا الرانشيت. كان هذا سياقًا غير صالح أنشأه مسار البدء نفسه.

## 3. ROOT CAUSE

الدالة القديمة `start_runsheet_loading` كانت تتحقق من المستخدم ومن حالة `Picked` ثم تنشئ `loading_cycle_id` وتحوّل الحالة إلى `Loading` دون التحقق من:

1. وجود مركبة معيّنة للرانشيت.
2. أن المركبة تابعة للشركة نفسها ونشطة.
3. أن المركبة مفعّل لها مخزون متنقل.
4. أن `mobile_branch_id` يشير إلى فرع VAN نشط وصحيح للمركبة.
5. عدم وجود رانشيت آخر في `Loading` يستخدم المركبة نفسها.

وفي المقابل، `complete_runsheet_loading` يحتاج المركبة ليحدد فرع VAN، لذلك كان الفشل يظهر متأخرًا عند إنهاء التحميل بدلًا من منعه عند بدء الجلسة.

**الاستنتاج:** هذا خلل في عقد بدء التحميل، مع سجل تشغيلي سابق غير صالح؛ وليس خطأ Tailwind أو مجرد مشكلة عرض في Loader.

## 4. الإصلاح المنفذ

### Migration canonical

- المسار: `supabase/migrations/20261025_start_loading_vehicle_context_guard.sql`
- Commit إنشاء الملف: `f264203cf8c4688487b9aacdb154a8ff428ba28b`
- Commit تصحيح الملف: `e3a9fd20ec036a9b545f45e711c251cace5a9d25`
- Content SHA الحالي: `c70188cb0c28020145106c85032cb19235eb4c1b`
- Production migration registry: `20261025154530 / start_loading_vehicle_context_guard_20261025`
- تطبيق Migration: SUCCESS.

### الحماية الجديدة في `start_runsheet_loading`

قبل الانتقال إلى `Loading` تتحقق الدالة الآن من:

- وجود `vehicle_id`.
- وجود مركبة نشطة تابعة للشركة نفسها و`mobile_stock_enabled = true`.
- وجود `mobile_branch_id` صالح ونشط ومتطابق مع `VAN-<vehicle_code>`.
- عدم استخدام المركبة في رانشيت آخر حالته `Loading`.

إذا فشل شرط، تُرفض العملية قبل إنشاء دورة تحميل جديدة أو تغيير حالة الرانشيت، برسالة توضح المطلوب.

لم يتغير `complete-loading` ولم تُضعف شروط الحركة المخزنية. الصلاحيات بعد الاستبدال: `anon EXECUTE=false`, `authenticated EXECUTE=false`, `service_role EXECUTE=true`.

## 5. اختبار Production بعد الإصلاح

| الاختبار | النتيجة | الدليل |
|---|---|---|
| محاولة بدء `RS-2` بلا مركبة | PASS — رُفضت بالرسالة المحددة | كتلة SQL اختبارية التقطت رسالة `لا يمكن بدء التحميل قبل إسناد مركبة للرانشيت`؛ لم تتغير الحالة. |
| مسار بدء صالح بمركبة اختبار مؤقتة | PASS — الدالة وصلت إلى نتيجة النجاح المتوقعة داخل معاملة فرعية ثم تم rollback | استُخدمت مركبة موجودة وصالحة مؤقتًا في `RS-2`، ثم أُجبر rollback؛ لم يُحفظ إسناد أو تغيير حالة. |
| Baseline بعد اختبار المسار الصالح | PASS | `RS-2` بقي `Picked`, `vehicle_id=NULL`, `loader_id=NULL`; لا حركة مخزون. |
| استعادة سياق `RS-1` الفاسد | PASS جزئي | استدعاء `cancel_runsheet_loading` أعاده إلى `Picked`، ومسح `loader_id/loader_start/loader_end/loading_cycle_id`. |
| حركة مخزون ناتجة عن الاختبار | PASS | `inventory_log` لا يحتوي Loading movement لـ`RS-1`; الكمية المحمّلة المسجلة كانت صفرًا قبل الاستعادة وبعدها. |
| HTTP E2E لتحميل ناجح بمركبة مسندة | UNVERIFIED | لا توجد جلسة HTTP موثقة هنا لرانشيت معيّن بمركبة اختيرت بناءً على قرار تشغيلي صحيح. |
| Staging E2E | UNVERIFIED | مشروع Staging `hfzznsiprnwkpayskzhu` حالته INACTIVE عند الفحص. |

## 6. حالة واجهة Loader وPicker

القراءة الحية للمصدر أظهرت أن Loader الحالي يحتوي بالفعل على علاقة الصنف لقراءة `description/image_url/name/unit`، ونطاق الشركة وملكية جلسة التحميل؛ لذلك لم أعد تطبيق رقعة Report492 على نسخة أقدم ولم أعدل `loader.html` أو `picker.html` أو `core.js` أو `main.html`.

`startLoading(code)` يستدعي `start-loading` باستخدام `runsheet_code` فقط؛ ولا يختار مركبة بنفسه. التصميم الحالي يضع إسناد المركبة ضمن إدارة الرانشيت قبل التحميل، و`manage_runsheet_atomic` يسمح بتعديل `vehicle_id` في حالتي `Open/Confirmed` فقط. لذلك يجب أن تكون المركبة مسندة قبل انتقال الرانشيت إلى مراحل التنفيذ.

يوجد حاليًا رانشيتان في بيانات الاختبار بحالة `Picked` وبدون مركبة. لم أُسنِد مركبة عشوائيًا: يوجد أكثر من مرشح صالح ولا توجد قرينة تربط أيًا منها بالرانشيت المتأثر. اختيار مركبة خاطئة يغيّر سياق المخزون المتنقل وقد يوجّه الحركة إلى VAN غير صحيحة.

## 7. ما بقي مفتوحًا

1. **إسناد مركبة صحيحة للرانشيت المتأثر:** غير محسوم لأن البيانات لا تحدد المركبة المقصودة. لا يجوز اختيار مركبة بالتخمين.
2. **مسار استعادة الرانشيت الذي وصل بالفعل إلى `Picked` بلا مركبة:** عقد `manage_runsheet_atomic` الحالي لا يسمح بتغيير المركبة في حالة `Picked`. يجب استخدام دورة تشغيل معتمدة لإعادته إلى مرحلة يمكن فيها إسناد المركبة أو اعتماد إجراء آمن يسمح بالإسناد قبل التحميل دون لمس الحجز/الكميات.
3. **HTTP E2E كامل:** بعد إسناد المركبة الصحيحة، يلزم اختبار start → complete عبر HTTP حقيقي والتحقق من حركة واحدة صحيحة في `post_stock_movement` ثم baseline restoration لبيانات الاختبار.
4. **التطبيق التشغيلي المنشور:** Git blob SHA لا يثبت وحده أن Cloudflare يخدم هذه البصمة. لم أغيّر HTML أو أدّعِ نشره.

## 8. قرار الإغلاق

- إصلاح السبب الجذري لمنع إنشاء سياق Loading بلا مركبة: **IMPLEMENTED + PRODUCTION VERIFIED**.
- تنظيف سياق `RS-1` الفاسد: **RESTORED TO PICKED; vehicle assignment still open**.
- `complete-loading` end-to-end في Production: **NOT CLOSED** إلى حين إسناد المركبة الصحيحة وإجراء اختبار HTTP كامل.
- لا أُعلن `100% CLOSED`؛ لأن اختيار المركبة الصحيحة وHTTP E2E لم يُثبتا.

## 9. SELF-AUDIT FINAL

**What I Proved**
- سبب رسالة `invalid Loading context` من سجل PostgreSQL المباشر.
- `start_runsheet_loading` كان يسمح ببدء التحميل دون مركبة.
- Migration الحماية نُشرت في Production، وحالة تسجيلها وبصمة الدالة الجديدة تم التحقق منهما.
- الرفض المبكر للرانشيت بلا مركبة يعمل، ومسار صالح اختُبر داخل rollback دون ترك أثر.
- `RS-1` استُعيد إلى `Picked` دون حركة مخزون أو حذف كميات التحضير.

**What I Did Not Prove**
- أن مركبة بعينها هي المركبة الصحيحة لـ`RS-1` أو `RS-2`.
- نجاح HTTP E2E كامل لتحميل صحيح في Production.
- هوية HTML التي يقدمها Cloudflare مقارنةً ببصمة Git.

**What I Fixed**
- أضفت guard مركزيًا قبل انتقال الرانشيت إلى `Loading`.
- أزلت حالة `Loading` غير الصالحة في `RS-1` باستخدام دالة الإلغاء المعتمدة، مع الحفاظ على حالة التحضير والحجز.

**What I Initially Missed**
- كان الخلل يبدأ قبل `complete-loading`: مسار البدء لم يفرض شرط المركبة الذي يحتاجه مسار الإكمال.

**What Could Still Be Wrong**
- قد تبقى فجوة في تجربة المستخدم إذا لم يتمكن المشغل من معرفة أن المركبة يجب أن تُسند قبل التحميل، أو إذا لم توجد واجهة عملية لاستعادة رانشيت `Picked` غير المسند.
- قد توجد اختلافات نشر HTML غير مثبتة بين Git وCloudflare.

**Final Confidence:** مرتفعة في إصلاح الحماية والسبب الجذري؛ متوسطة في إغلاق دورة التشغيل كاملةً.  
**Final Closure Status:** `PARTIAL — ROOT CAUSE FIXED / PRODUCTION GUARD VERIFIED / FULL HTTP E2E OPEN`.
