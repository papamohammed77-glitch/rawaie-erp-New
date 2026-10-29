# Report559 — إعادة التحقق التشغيلي لمرشحات المرتجعات وحدود التغيير الجراحي

**Last Verified Event:** `LVE-2026-10-29-559`  
**التاريخ:** 2026-10-29  
**نقطة البداية:** `CURRENT_STATE.md` عند `LVE-2026-10-29-558`، ثم الدستور التشغيلي الدائم وReport545 وReport558 وReport557.  
**النطاق:** تطبيق المرتجعات `companies/company-1/warehouse/returns.html`، علاقته بالنظام الأم والتوصيل، بيانات Supabase Production، وحالة رقعة PR #8.  
**الحالة:** `ROOT CAUSE RECONFIRMED / PR #8 FILTER PATCH EXISTS BUT UNMERGED / SEARCH ASSIGNMENT PATCH STILL OWNER-ONLY / PRODUCTION READ-ONLY / EXACT RUNTIME ARTIFACT + AUTHENTICATED E2E UNVERIFIED / NOT CLOSED`

## 0. القرار التنفيذي

تم استرجاع الحالة الراهنة من `CURRENT_STATE.md` وقراءة الدستور التشغيلي وReport545 وReport558 وReport557، ثم إعادة جلب المصدر التشغيلي والفرع المقترح وPR #8، وقراءة Production مباشرة.

**السبب الجذري مؤكد في المصدر الحالي:** `returns.html` على `main` يستعلم عن جميع `runsheets` ذات `status='Delivered'` ويعرضها قبل تصفية الكمية المتبقية. كما أن حساب المتبقي لا يطرح `qty_returned`. لذلك يظهر رانشيت مكتمل التسليم ولا يملك أي كمية متبقية للمرتجع، وهو مخالف لدور التطبيق.

يوجد بالفعل إصلاح أساسي في Draft PR #8، لكنه لا يزال غير مدموج. لا يجوز وصفه بأنه إصلاح Production. كما أن مسار البحث داخل الرقعة لا يطبّق حاليًا قيد `return_handler_id` على حالات `Returning` مثلما تفعل القائمة الرئيسية؛ وسبق أن أُعدّ التصحيح الجراحي R8-S1-A/B كـOwner Patch. هذه المراجعة لم تكتب إلى أي ملف تشغيلي ولم تدمج أي PR.

## 1. الحوكمة وحدود الصلاحيات

- الدستور التشغيلي الدائم وReport545 هما المرجعان الملزمان لطريقة العمل، لا التقارير التاريخية وحدها.
- طبقات الحقيقة مستقلة: GitHub source، Supabase Production، Cloudflare build/deployment، والواجهة/سلوك المستخدم المصادق عليه.
- يمكن إثبات خطأ من المصدر دون الادعاء بأن كل نسخة منشورة تحمل الخطأ نفسه؛ كما أن نجاح نشر Preview لا يثبت إغلاق Production.
- النطاق الجراحي محصور في تطبيق المرتجعات. لا تعديل على `main.html` أو `driver.html` أو `core.js` أو schema/RLS/Edge Functions ما لم يظهر دليل جديد يثبت الحاجة.
- Owner-only HTML rule مستمرة؛ لا كتابة مباشرة إلى الملف التشغيلي ولا دمج PR في هذه الجولة.

## 2. أدلة المصدر الحي — GitHub

### 2.1 تطبيق المرتجعات على main

- Repo: `papamohammed77-glitch/erp-frontend`
- Branch: `main`
- File: `companies/company-1/warehouse/returns.html`
- Blob SHA: `36c20e03c94dc734e015610dec1e8208697df32a`
- النطاق الحالي في `App.loadRunsheets()`: استعلام `Returning` المسند للمستخدم، واستعلام `Delivered` عام، ثم تحميل تفاصيل مع `qty_loaded, qty_delivered` فقط، دون طرح `qty_returned`، ودون تصفية `available` بحسب المتبقي.
- البحث على `main` يستخدم الإسقاط المتداخل القديم `run_sheet_details(count)` ولا يحسب أهلية المتبقي قبل العرض.

### 2.2 رقعة PR #8

- PR: [#8 — Draft: show only runsheets with outstanding returns](https://github.com/papamohammed77-glitch/erp-frontend/pull/8)
- الحالة المباشرة: `open=true`, `draft=true`, `merged=false`.
- Head branch: `fix/returns-only-pending-runsheets-20261029`
- Commit: `3ad370c83f8f3c7880d7ace9ac24eabb5833f9cf`
- Blob: `9cc013a419f6dac2c656471b72f0e629a622a5b6`
- الرقعة الأساسية تتخلص من `run_sheet_details(count)` في الاستعلامين الأساسيين، وتجلب `qty_returned`، وتحسب `max(0, qty_loaded - qty_delivered - qty_returned)`، وتخفي `Delivered` ما لم يتبقَّ أي صنف له كمية مرتجعة موجبة، وتحسّن أخطاء الاستعلام.
- الرقعة ما زالت Draft، وبالتالي لم تصل إلى `main` عبر merge.

### 2.3 فجوة البحث

في PR #8، الاستعلام يبحث في `Delivered` و`Returning` لكنه لا يطلب `return_handler_id`. ويستخدم المرشح:
```javascript
return rs.status !== 'Delivered' || pending[rs.id] === true;
```
ذلك يسمح بظهور أي حالة `Returning` في البحث مهما كان المستخدم المسند إليه، رغم أن القائمة الأساسية تقيد الحالات النشطة بـ`return_handler_id`. هذا اختلاف عقدي داخل التطبيق ويجب توحيده قبل الاعتماد.

التصحيح المحدد موجود في Report557 تحت R8-S1-A/B:
- A: إضافة `return_handler_id` إلى إسقاط بحث الرانشيت.
- B: جعل Promise استعلام التفاصيل معادًا إلى السلسلة الخارجية، مع فلترة أهلية البحث لتكون `Delivered` ذات متبقي موجب، أو `Returning` المسند إلى المستخدم الحالي، ومعالجة أخطاء البحث عبر المسار الخارجي.
- لا يعاد تطبيق التصحيح قبل إعادة التحقق من SHA وحدود النص الفريدة؛ الـBlob المرصود في هذه الجولة يطابق SHA المتوقع أعلاه.

## 3. بيانات Supabase Production — قراءة مستقلة

المشروع: `fiilmooggumokxanwiyx`.

استعلام قراءة مباشر إلى `public.runsheets` أكد وجود سجلين في العينة الحالية:

| الرانشيت | الحالة | عدد صفوف التفاصيل | إجمالي الكمية المتبقية للمرتجع |
|---|---|---:|---:|
| RS-1 | Delivered | 5 | 0 |
| RS-2 | Delivered | 7 | 5 |

الحساب المستخدم:
`sum(greatest(coalesce(qty_loaded,0)-coalesce(qty_delivered,0)-coalesce(qty_returned,0),0))`.

- لا توجد في العينة الحالية سجلات `Returning`.
- النتيجة التجارية المطلوبة من شرط الأهلية: إخفاء `RS-1` وإظهار `RS-2`.
- هذه قراءات فقط. لم يحدث DDL/DML أو استدعاء RPC كتابة أو تغيير RLS/ACL/Edge Function، ولم تُنشأ بيانات اختبار.
- نجاح SQL يؤكد قيم قاعدة البيانات فقط ولا يثبت ما يعرضه DOM أو أي Artifact منشور.

## 4. النشر وسلوك التشغيل

- تعليق Cloudflare bot في PR #8 بتاريخ 2026-10-29 سجّل نجاح Preview في مشروع `rawaea-erp` على commit `3ad370c` وعرض الرابطين:
  - `https://da5fcdde.rawaea-erp.pages.dev`
  - `https://fix-returns-only-pending-run.rawaea-erp.pages.dev`
- التعليق نفسه أظهر فشل بناء المشاريع `erp-frontend` و`rawaea-store` و`warehouse-supervisor`. لم تُقرأ سجلات تفاصيل الفشل هنا، فلا تُنسب أسبابه إلى كود المرتجعات.
- لقطة Cloudflare المتاحة في الجلسة السابقة عرضت Production لـ`rawaea-erp` على commit `416de1c`، لكن هذه ليست مطابقة بايتات للملف المنشور ولم تنفذ الرحلة المصادق عليها.
- محاولة القراءة المباشرة من Browser connector في الجلسة السابقة فشلت بسبب غياب originating browser context، لذا:
  - **CONFIRMED:** حالة Preview المسجلة في تعليق Cloudflare bot.
  - **UNVERIFIED:** تطابق الـArtifact الذي يقدمه نطاق Production بايتًا ببايت مع مصدر Git الحالي.
  - **UNVERIFIED:** رحلة E2E مصادق عليها تثبت القائمة والبحث وفتح التفاصيل.
  - **UNKNOWN:** الأسباب التفصيلية لفشل مشاريع Cloudflare الثلاثة حتى تُقرأ Logs فعلية.

## 5. التصنيف المنضبط للأدلة

### CONFIRMED
1. مصدر `returns.html` على `main` لا يصفي `Delivered` حسب المتبقي.
2. المصدر الأساسي يحسب المتبقي باستخدام `qty_loaded > qty_delivered` ولا يطرح `qty_returned`.
3. PR #8 يحتوي الإصلاح الرئيسي لكنه Draft/open/unmerged.
4. Production الحالي: `RS-1 pending=0`; `RS-2 pending=5`.
5. بحث PR #8 لا يوحد قيد `Returning` مع إسناد المستخدم؛ Patch R8-S1-A/B يعالج ذلك على مستوى المصدر المقترح.

### UNKNOWN
1. ما إذا كانت طلبات Supabase القديمة من Preview أو Production، عند عدم وجود Origin/Referer محددين.
2. الأسباب الجذرية لفشل بناء المشاريع الثلاثة الأخرى لأن سجل البناء التفصيلي لم يقرأ.
3. هوية بايتات HTML/JS المقدمة إلى كل جلسة مستخدم في Production.

### CONFLICT
1. الحالة الوظيفية المقصودة — ظهور رانشيتات لديها مرتجع فعلي فقط — لا تتفق مع تنفيذ `main` الحالي الذي يعرض كل `Delivered`.
2. داخل PR #8، القائمة الرئيسية تقيد `Returning` بالمستخدم، لكن البحث لا يفعل ذلك.

### UNVERIFIED
1. Artifact المنشور في Production بعد أي تحديث.
2. E2E في جلسة مستخدم مصادق عليها.
3. نجاح بوابة CI الحالية على Parent والتطبيقات المرتبطة بعد التعديلات الأخيرة.

## 6. مصفوفة التحقق

| الطبقة | الحالة | الدليل |
|---|---|---|
| GitHub Returns main | CONFIRMED defect | Blob `36c20e03...` وقراءة `loadRunsheets/onSearchInput` |
| GitHub PR #8 | CONFIRMED pending review | Blob `9cc013a4...`, commit `3ad370c`, Draft/unmerged |
| Supabase Production | CONFIRMED values | SQL read-only: RS-1=0, RS-2=5 |
| Cloudflare Preview | CONFIRMED bot status | تعليق PR #8 على commit `3ad370c` |
| Cloudflare failure causes | UNKNOWN | Logs التفصيلية لم تُقرأ |
| Production served artifact | UNVERIFIED | لا مقارنة byte-for-byte |
| Authenticated E2E | UNVERIFIED | لا DOM/Network/Console من جلسة مستقلة |

## 7. Mutation Ledger

- `returns.html` على `main`: لم يتغير.
- فرع PR #8: لم يتغير في هذه الجولة.
- `main.html`, `driver.html`, `core.js`: لم تتغير.
- Supabase Production: قراءات فقط؛ لا مخطط/صلاحيات/وظائف/بيانات أعمال تغيرت.
- Cloudflare: لم تتغير إعدادات أو عمليات نشر.
- لا بيانات اختبار أنشئت أو تركت في Production.

## 8. خطوة الاستئناف التالية

1. يعيد المالك جلب PR #8 ويتأكد من Blob SHA `9cc013a419f6dac2c656471b72f0e629a622a5b6` وحدود R8-S1-A/B الفريدة، ثم يطبق هاتين الرقعتين على الفرع فقط.
2. يعاد تشغيل فحص JavaScript المضمن بالكامل واختبار أهلية معزول: `RS-1` مخفي، `RS-2` ظاهر، و`Returning` لا يظهر إلا للمستخدم المسند إليه. لا يبدأ/يكتمل مرتجع أثناء اختبار العرض.
3. تُقرأ Logs الخاصة ببناء المشاريع الفاشلة وتُعالج فقط أسبابها المثبتة.
4. لا يُدمج PR ولا يُغلق العطل حتى تثبت هوية Artifact المنشور وتنجح رحلة E2E مصادق عليها تشمل القائمة والبحث وفتح تفاصيل الرانشيت.

**الخلاصة:** `ROOT CAUSE CONFIRMED / MAIN SOURCE DEFECT PRESENT / CORE PATCH IN DRAFT PR / SEARCH ASSIGNMENT PATCH OWNER-ONLY / NO PRODUCTION MUTATION / ARTIFACT + AUTHENTICATED E2E UNVERIFIED / NOT CLOSED`.
