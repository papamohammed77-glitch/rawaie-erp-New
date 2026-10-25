# تقرير 498 — إعادة بناء الأمر التنفيذي وضبط انضباط التكامل Picker / Loader
**LAST VERIFIED EVENT:** `LVE-2026-10-25-498`  
**التاريخ:** 25 أكتوبر 2026  
**نوع العمل:** مراجعة حوكمة/مصادر + إعداد Prompt تنفيذي موحد + تحديث سجل الاستمرارية.  
**النطاق:** لا يتضمن تطبيق رقع HTML أو نشر Edge أو تغيير قاعدة البيانات.

## 1. SELF-AUDIT PRE

- **Business Understanding:** CONFIRMED ضمن دورة التحضير والتحميل وعرض الرانشيت والأصناف؛ مستند إلى المهمة المحددة في `writing-block.md` ومصادر Picker/Loader.
- **Architecture Understanding:** CONFIRMED في حدود الواجهة، Core، Edge، PostgreSQL، النظام الأم، وتوزيع مسؤوليات التنفيذ.
- **Database Understanding:** LIVE READ COMPLETED للعناصر والـRPCs والـtriggers والـACL المذكورة أدناه؛ لم يتم تنفيذ أي DDL/DML.
- **Historical Understanding:** CONFIRMED جزئيًا/موجّه؛ تمت قراءة `CURRENT_STATE.md` وسجل الأحداث الأحدث والتقرير 497، واستخدام التقارير 496 وما قبلها لتفسير التصحيحات. لم أدّعِ قراءة كل التقارير التاريخية غير ذات الصلة.
- **Production Understanding:** تم فحص Edge registry ومصدر الدوال الأربع ذات الصلة مباشرة، والاستعلام الحي عن PostgreSQL. هذا لا يثبت HTTP E2E أو HTML served identity.
- **Current Understanding:** أعيد جلب المصدر التشغيلي من `erp-frontend/main` وتطابقت البصمات مع سجل الحالة.
- **Execution Confidence:** مرتفع في ضبط النطاق وصحة سجل المصدر/Production المقروء؛ غير كافٍ لإعلان إغلاق تشغيلي للتطبيق لأن رقع المالك لم تُطبّق ولم يجرِ Browser/HTTP E2E.

### مصادر وقيود ما قبل التنفيذ
- `doc/Draft/Reprots/writing-block.md` — blob SHA `8929b54e04ef848e814a21f6ecdfb97bf8c7952d`; تمت قراءته عبر مقاطع متتابعة حتى قسم المهمة التنفيذية والخاتمة.
- `CURRENT_STATE.md` — blob SHA قبل التحديث `70a09d3d9e7644f264f7ac7f668576733518013c`; آخر حدث كان `LVE-2026-10-25-497`.
- `Report497_LOADER_PICKER_FULL_CORRECTED_OWNER_PATCH_20261025.md` — blob SHA `f602490973ad9cc617cc62980c24799fc2afe3e9`.
- Operational source repository: `papamohammed77-glitch/erp-frontend`, branch `main`.
- No operational HTML/Core/Main edits; no Production data/schema/ACL changes; no Edge deployment; no test fixture or harness created.

## 2. خلاصة القرار التنفيذي

تم إنشاء Prompt أوضح وأكثر صرامة:
`doc/Draft/Reprots/MASTER_CTO_EXECUTION_PROMPT_LOADER_PICKER_INTEGRATION_20261025.md`

وهو يحول الوثيقة التشغيلية الطويلة إلى عقد تنفيذ قابل للتطبيق دون إسقاط القيود المهمة. أبرز تحسين منهجي هو **الفصل الصريح بين مسار تكامل العرض والبيانات ومسار عيوب دورة التحميل**، مع عدم تجاهل عيوب Backend التي تؤثر فعليًا في سلامة المسار، وعدم خلطها تلقائيًا برقعة الواجهة أو ادعاء إصلاحها ضمنها.

هذا الحد مهم لأن المهمة الأصلية تحدد `picker.html` مرجعًا و`loader.html` هدفًا، وتمنع المساعد من تعديل ملفات HTML التشغيلية مباشرة. تقرير 497 وثّق أيضًا ديون دورة تحميل أوسع؛ لذلك يجب أن تبقى رقع المالك، وعيوب Production الخلفية، وإثباتات Runtime حالات منفصلة.

## 3. مطابقة المصدر التشغيلي المباشرة

| الأصل | SHA الحالي المقروء | الحجم |
|---|---|---:|
| `erp-frontend/companies/company-1/warehouse/loader.html` | `f478a78b9e5999cf44f7f65e06341b3036bfdcc9` | 811 سطرًا / 50,979 حرفًا |
| `erp-frontend/companies/company-1/warehouse/picker.html` | `d483bd15b36585b975b63c2ef641481a01d5d084` | 1,058 سطرًا / 55,069 حرفًا |
| `erp-frontend/companies/company-1/core.js` | `ff2f581d9900543c16f7cb026e13446520c0329d` | 773 سطرًا / 28,074 حرفًا |

القراءة المباشرة تؤكد:
- Loader يحتوي بالفعل `openRunsheet`، و`_showPreviewModal`، و`_showItemDetail`، و`_loaderImageHTML` وبديل الصورة، وعلاقة الصنف `items!run_sheet_details_item_id_fkey`، واختيار المركبة.
- Loader لا يحتوي في نسخته الحالية على `Dexie` أو `operation_id` أو `pauseLoading`. لذلك فإن رقع تقرير 497 لم تُطبّق في هذا المصدر الذي أُعيد جلبه.
- Picker يحتوي على تدفق التحضير الخاص به وDexie و`reopenPicking`؛ لا يعني ذلك نسخ وظائفه إلى Loader تلقائيًا.
- هذه بصمات Git للمصدر التشغيلي، وليست إثباتًا لهوية HTML التي تقدمها Cloudflare.

## 4. Production — فحص مباشر في هذه الجلسة

**وقت PostgreSQL المباشر:** `2026-10-25 19:05:49.977892+00`  
**الإصدار:** PostgreSQL 17.6  
**المشروع:** SMART ERP / `fiilmooggumokxanwiyx`

| Edge Function | Version | Status | verify_jwt | ezbr_sha256 |
|---|---:|---|---|---|
| `start-loading` | 6 | ACTIVE | true | `b0e1736ac7606c1c0b81dfdccd75cc90dbad955651961a24019b6e3c4a1988e1` |
| `complete-loading` | 11 | ACTIVE | true | `c0ca692a29d14d64ec3729ae4bd12b9b84268e826ffc1c6993a48617b552b286` |
| `cancel-loading` | 5 | ACTIVE | true | `65fdfe2066dac1779c1e82b27a958a13d71604808af8a33ca12779ac5b7c0c89` |
| `reopen-loading` | 2 | ACTIVE | true | `89cac4219673154832b294d74b810c98154b7a46464a893eb8f119439e358350` |

هذه بيانات Live Registry/source قرئت مباشرة. `ezbr_sha256` هو بصمة حزمة النشر، وليس Git SHA.

### حقائق Core وACL التي أُعيد التحقق منها
- `complete_runsheet_loading(uuid,uuid,jsonb,text)`: `SECURITY DEFINER`، ACL المعروض: `postgres` و`service_role` فقط.
- `complete_runsheet_reopen_loading(uuid,text,text,text)`: `SECURITY DEFINER`، ACL المعروض: `postgres` و`service_role` فقط.
- `cancel_runsheet_loading(uuid,text,text)`: `SECURITY DEFINER`، ACL المعروض: `postgres` و`service_role` فقط.
- `post_stock_movement` ذو 9 معاملات: ACL المعروض `postgres` فقط؛ والـoverload ذو 10 معاملات (يشمل idempotency key) يسمح لـ`postgres` و`service_role`. لا يُستنتج من هذا وحده أن Edge تستدعي overload بعينه؛ يلزم مطابقة نداء RPC الفعلي مع توقيعه.
- Trigger `trg_sync_run_sheet_details` ما زال مرتبطًا بـ`order_details` على INSERT/UPDATE/DELETE ويستدعي `sync_run_sheet_details()`.

### عيوب Backend ما زالت مفتوحة وفق المصدر الحي
- `cancel-loading v5` و`reopen-loading v2` يقرآن الشركة عبر `app_settings.limit(1)` بدل اشتقاقها من المستخدم المصادق عليه وربطه بـ`public.users.auth_id`. هذا عيب سياق شركة مثبت في المصدر المنشور.
- `complete-loading v11` يرفض العناصر ذات `loaded_qty <= 0`.
- عقد Core `complete_runsheet_loading` يشترط حالة `Loading` وبيانات دورة التحميل؛ ويحتاج ترتيب فحص idempotency مقابل حالة الرانشيت إلى اختبار مباشر بعد نجاح commit وفقد الاستجابة. لم يُجرَ اختبار HTTP retry/concurrency في هذه المهمة، لذلك لا يُسجل كإصلاح أو Runtime PASS.
- لا توجد في هذه المهمة أي محاولة لإصلاح هذه العيوب الخلفية؛ لأنها تتطلب وحدة تنفيذ واختبارات مستقلة، ولا يجوز الادعاء بأنها عولجت بإعداد Prompt.

## 5. أين أخطأ المنهج السابق وكيف يعالج الـPrompt الجديد ذلك؟

1. **الاعتماد على التقارير بدل إعادة الجلب:** الآن يُلزم Prompt بقراءة CURRENT_STATE ثم إعادة جلب الملفات وProduction في جلسة العمل.
2. **الخلط بين المرجع والهدف:** يثبت `picker.html` مرجعًا و`loader.html` هدفًا، مع منع تعديل الاثنين مباشرة ضمن هذا التفويض.
3. **توسيع نطاق المهمة بصمت:** يميز Prompt بين تكامل العرض وديون دورة التحميل، ويطلب إثبات علاقة الدين بالنطاق قبل ضمه إلى الإصلاح.
4. **إعادة بناء وظائف موجودة:** ينص على الاحتفاظ بمعاينة Loader وتفاصيل الأصناف والصورة الكبيرة واختيار المركبة؛ لا تُنسخ Picker wholesale.
5. **خلط الهوية:** يلزم التحقق الحي من `auth.users.id` و`public.users.auth_id` و`public.users.id` وعدم الخلط بين Auth ID ومعرّف المستخدم التطبيقي.
6. **الخلط بين مصدر Git والنشر:** يميز blob SHA عن `ezbr_sha256`، ويشترط فحص HTML الذي يقدمه Cloudflare عند ادعاء نشر الواجهة.
7. **اعتبار الرقعة تقريرًا أو إغلاقًا:** يفصل `PROPOSED/APPLIED/DEPLOYED/VERIFIED/CLOSED`، ويمنع إغلاق المهمة قبل تطبيق المالك واختبارها.
8. **التوقف عند نقص واحد:** يلزم استمرار التحقيق والعمل الآمن المستقل مع تسجيل الإجراء الدقيق المطلوب، دون تجاوز حدود التعديل أو الادعاء بإتمام غير مثبت.

## 6. حالة المهمة الفعلية

| البند | الحالة |
|---|---|
| قراءة الوثيقة التشغيلية وتحليل تعليماتها | CONFIRMED |
| قراءة CURRENT_STATE وآخر حدث موثق | CONFIRMED |
| قراءة تقرير 497 وتصحيحاته | CONFIRMED |
| إعادة جلب Loader/Picker/Core من المصدر التشغيلي | CONFIRMED |
| إعادة قراءة Edge registry/source | CONFIRMED |
| قراءة PostgreSQL timestamp / ACL / triggers | CONFIRMED |
| إنشاء Prompt تنفيذي موحد | CREATED IN GIT |
| تعديل Loader/Picker/Main/Core | NOT DONE — محظور في نطاق المهمة |
| إصلاح Edge security context | NOT DONE — عيب مفتوح منفصل |
| إصلاح/إثبات retry-after-commit | NOT DONE — لم يجرِ اختبار E2E |
| Cloudflare served HTML identity | UNVERIFIED |
| Browser/HTTP E2E مصادق | NOT RUN |
| Baseline restoration | NOT APPLICABLE؛ لم تُنشأ fixtures |
| إغلاق تطبيق التحميل 100% | NOT CLOSED |

## 7. Mutation Ledger

- **GitHub:** إنشاء `MASTER_CTO_EXECUTION_PROMPT_LOADER_PICKER_INTEGRATION_20261025.md` فقط في هذه المرحلة؛ سيُسجل commit في سجل الاستمرارية بعد نجاح حفظ التقرير.
- **Supabase:** قراءات فقط؛ لا DDL، لا DML، لا ACL changes، لا Edge deployment.
- **المصدر التشغيلي:** لم يُعدّل Loader أو Picker أو Core أو Main.
- **بيانات الأعمال:** لا تغيير في الرانشيتات أو المخزون أو `inventory_log`.
- **Fixtures/Harnesses:** لم يُنشأ أو يُحذف شيء.

## 8. SELF-AUDIT FINAL

### What I Proved
- أعيد جلب المصدر التشغيلي الحالي وتطابقت بصمات Loader/Picker/Core مع سجل الحالة الأحدث.
- رقع Report497 غير مطبقة في Loader الحالي؛ غياب `Dexie` و`operation_id` و`pauseLoading` مثبت في النص الحالي.
- Production ما زال يعرض الإصدارات الأربع المسجلة أعلاه، وكلها `ACTIVE` و`verify_jwt=true`.
- عيوب تحديد الشركة في cancel/reopen موجودة في المصدر المنشور الحالي.
- Core ACL والـtrigger المعنيين قُرئا مباشرة.

### What I Did Not Prove
- لم أثبت هوية HTML الذي تقدمه Cloudflare.
- لم أشغّل Browser/HTTP E2E أو concurrency.
- لم أطبّق رقع المالك أو أصلح Edge/Core.
- لم أثبت baseline runtime بعد أي إصلاح؛ لم يحدث أي إصلاح في هذه الدورة.

### What I Fixed
- أصلحت فجوة الحوكمة/الصياغة بإنتاج Prompt تنفيذي يوضح النطاق، وترتيب مصادر الحقيقة، والحدود، والإثباتات، والتقارير، والتسليم.
- لم أعدّل كود التشغيل.

### What I Initially Missed
- أهم فرق يجب الحفاظ عليه هو أن المهمة الأصلية تتعلق بتكامل العرض والبيانات بين Picker وLoader، بينما Report497 يضم أيضًا ديون دورة تحميل وخلفية. لا يجوز دمج هذين المسارين في حكم واحد دون إثبات علاقة الاعتماد.

### What Could Still Be Wrong
- قد تختلف نسخة Cloudflare عن Git.
- قد تكون هناك تغييرات أحدث في Production بعد وقت القراءة المسجل.
- لم يُختبر سلوك retry الحقيقي ولا عزل الشركة عبر HTTP.
- يظل Prompt نفسه وثيقة إرشادية؛ لا يثبت تطبيق الرقع أو إغلاق عيوب النظام.

**Final Confidence:** مرتفع في دقة لقطة المصدر/Production وقت القراءة وفي تصحيح صياغة النطاق؛ محدود فيما يخص Runtime لأن E2E لم يُنفذ.  
**Final Closure Status:** `PROMPT CREATED / SOURCE AND PRODUCTION RECONCILED FOR THIS REVIEW / OPERATIONAL DEFECTS OPEN / NOT 100% CLOSED`.

## 9. أول إجراء للمساعد التالي

1. اقرأ هذا التقرير و`CURRENT_STATE.md` ثم أعد جلب Loader وProduction قبل أي إجراء.
2. لا تعِد كتابة معاينة الرانشيت وتفاصيل الأصناف والصورة؛ هذه موجودة في Loader.
3. تحقق من أن Loader لا يزال على SHA `f478a78b9e5999cf44f7f65e06341b3036bfdcc9` قبل أن يطبق المالك رقع Report497؛ إذا تغير، أعد مطابقة كل محدد بحث.
4. اتبع Prompt الجديد لفصل رقع Loader الموجهة للمالك عن إصلاح Edge/Core الأمني والإيديمبوتنسي.
5. لا تعلن إغلاقًا تشغيليًا قبل تطبيق المالك، فحص HTML المنشور، واختبارات مصادقة/Runtime ذات صلة.
