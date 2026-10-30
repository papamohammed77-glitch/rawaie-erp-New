# Report565 — مراجعة Returns Eligibility وProduction Business Effects
**تاريخ الفحص:** 2026-10-30 — 19:49 UTC / 21:49 Cairo  
**الحالة:** SOURCE PATCH PRESENT ON MAIN / BACKEND RETURN TRANSACTION CONFIRMED / CLOUDFLARE ARTIFACT UNVERIFIED / SECURITY ACL BLOCKER OPEN / NOT CLOSED

## 1) نقطة البداية والمرجعية

- بدأت من `CURRENT_STATE.md` في مستودع الحوكمة والتقارير `papamohammed77-glitch/rawaie-erp-New`؛ وكانت آخر نقطة مسجلة `LVE-2026-10-30-563`، وهدفها أهلية ظهور رانشيتات Delivered في تطبيق Returns المستقل.
- قرأت الدستور التشغيلي الدائم وReport563 قبل إعادة جلب الأدلة الحية.
- المستودع التشغيلي للكود هو `papamohammed77-glitch/erp-frontend`، بينما مستودع `rawaie-erp-New` هو مرجع CURRENT_STATE والتقارير والذاكرة. يوجد ملف CURRENT_STATE آخر داخل المستودع التشغيلي يحمل checkpoint مختلفًا خاصًا بحادثة Save Item؛ لم أخلط بينه وبين checkpoint الحوكمة.
- يوجد Report564 كـ Owner Change Set غير مرتبط بآخر CURRENT_STATE. قرأته كأثر تاريخي فقط؛ لا يُستخدم لإثبات الحالة الراهنة. Git الحالي أحدث منه ويحتوي على أجزاء التعديل التي كان يطلبها.

## 2) الملخص التنفيذي

**النتيجة الأساسية:** إصلاح أهلية Delivered لم يعد مجرد اقتراح. التعديلات المطلوبة موجودة الآن في `main` داخل `returns.html`، وتشمل القائمة الرئيسية والبحث والمعاينة وربط هوية مسؤول المرتجعات بـ UUID، إضافة إلى تحميل صورة الصنف من العلاقة الصحيحة. اجتاز JavaScript المضمن فحص التحليل النحوي.

لكن **لم يثبت أن Cloudflare Production يقدم هذه النسخة**. آخر commit نشر موثق في Report563 هو `9e3fe134`، بينما HEAD الحالي `5745f36` متقدم عليه بأربعة commits. كما تعذر جلب الـartifact المنشور أو headers أو إجراء Browser E2E في هذا التشغيل. لذلك لا أصف إصلاح الواجهة بأنه منشور أو Production Verified.

وفي Production حدثت عملية مرتجع حقيقية ناجحة للرانشيت RS-2 في 17:28–17:29 UTC؛ وقد ثبت أثرها في المخزون والإشعار الدائن والقيد المحاسبي. هذه تثبت مسار الأعمال الخلفي، لكنها لا تثبت أن فلتر القائمة الجديد كان هو نسخة الواجهة التي استخدمها المستخدم.

## 3) CONFIRMED

### A. GitHub / Source

- المستودع التشغيلي: `papamohammed77-glitch/erp-frontend`.
- الفرع: `main`.
- HEAD الحالي: `5745f36cd1e4e3707b84cead4d35aaf8a9882e75`.
- `companies/company-1/warehouse/returns.html`:
  - Blob: `16d02fff2d00759451879204abf218202898f9c0`
  - الحجم: 74,600 bytes
  - 1,309 سطرًا.
- `companies/company-1/app.html` Blob: `ec75f89c11620f6e8b8ef5996cf1a3289dcf20b4`.

التعديلات الموجودة بالفعل على Main:

1. Commit `671a4cf85d6fd59fb66f1f1c39941ab032053f89` أضاف `qty_returned` إلى استعلام تفاصيل الرانشيت، وحوّل أهلية المجموعة إلى:
   `max(0, qty_loaded - qty_delivered - qty_returned) > 0`
   ثم صفّى قائمة Delivered بحيث لا يظهر رانشيت بلا صنف واحد على الأقل ذي كمية مرتجعة متبقية.

2. Commit `5745f36cd1e4e3707b84cead4d35aaf8a9882e75` استكمل المصدر الحالي:
   - البحث يجلب `qty_returned` ويطبق شرط الأهلية نفسه.
   - نتائج Returning محصورة في `return_handler_id === currentUser.id`.
   - المعاينة تستخدم المعادلة نفسها ولا تعرض أصنافًا مكتملة.
   - مقارنات `return_handler_id` تستخدم UUID الخاص بـ `users.id` دون fallback إلى البريد الإلكتروني.
   - تحميل الصور يستخدم `items!run_sheet_details_item_id_fkey(image_url)` ومساعد `returnItemImageHTML` بدل كاش الصور العام.
   - توجد معالجة أخطاء لاستعلامات القائمة والتفاصيل والصور.

3. فحص المصدر الحالي:
   - لا توجد استدعاءات متبقية لـ `RW_ImageCache.getImageHTML` في Returns.
   - مساعد الصور معرف مرة واحدة ويُستخدم في مواضع العرض.
   - تحليل JavaScript المضمن في `returns.html`: PASS.
   - تحليل JavaScript المضمن في `app.html`: PASS.
   - هذا فحص syntax فقط، وليس اختبار متصفح أو سلوكًا فعليًا.

4. مسار الدخول:
   - `app.html` يوجه `active_warehouse_role === 'مرتجعات'` إلى `/companies/company-1/warehouse/returns.html`.
   - شاشة `view: 'return'` داخل `main.html` هي شاشة داخلية أخرى، وليست تطبيق Returns المستقل.

5. العلاقات:
   - Production يحتوي FK باسم `run_sheet_details_item_id_fkey` إلى `items(id)`.
   - `items.image_url` موجود.
   - `runsheets.return_handler_id` من نوع UUID ويرتبط بـ `users(id)`.

6. PR #8:
   - ما زال Open / Draft / Unmerged.
   - Head: `3ad370c83f8f3c7880d7ace9ac24eabb5833f9cf`.
   - Base SHA القديم: `416de1c1d829c48b7c82442242a2a039e3d7e48c`.
   - ملف Returns في PR Blob `9cc013a419f6dac2c656471b72f0e629a622a5b6` لا يحتوي على search eligibility patch ولا image helper الموجودين الآن في Main.
   - مقارنة PR head بـ Main: PR ahead 25 / behind 2. لا تدمج هذا الفرع آليًا؛ Main يحتوي بالفعل على التعديلات الأحدث.
   - GitHub combined status للـcommitين 671a4cf و5745f36 أعاد statuses فارغة؛ لا يوجد CI PASS مثبت لهما.

### B. Production Database / Edge Functions

مشروع Production `SMART ERP`، ref `fiilmooggumokxanwiyx`.

العقود الحية ذات الصلة:

- `start-return`: ACTIVE، version 5، `verify_jwt=true`.
- `complete-return`: ACTIVE، version 27، `verify_jwt=true`.
- `cancel-return`: ACTIVE، version 4، `verify_jwt=true`.
- `complete_sales_return_credit_note_atomic`:
  - SECURITY DEFINER.
  - التنفيذ متاح لـ `service_role` فقط، وليس anon أو authenticated.
  - يستدعي `complete_return_atomic` ويطبق idempotency عبر operation key.
- `sync_run_sheet_details` trigger يعمل بعد تغييرات `order_details` ويعيد بناء projection في `run_sheet_details`.

التحقق من أهلية بدء المرتجع متطابق في التطبيق والخادم:
`max(0, qty_loaded - qty_delivered - qty_returned) > 0`.
كما يتحقق Edge Function من الشركة والمستخدم النشط وصلاحية warehouse والدور النشط «مرتجعات» وحالة Delivered وعدم وجود جلسة مرتجعات أخرى للمستخدم.

### C. Production Business Event — RS-2

رصدت عملية Production حقيقية بتاريخ 2026-10-30:

- `start-return` POST 200 عند 17:28:34.684 UTC، version 5.
- `complete-return` POST 200 عند 17:29:06.500 UTC، version 27.
- RS-2 انتقل من Returning إلى Returned.
- `return_start = 17:28:34.515+00`، و`return_end = 17:29:06.110504+00`.
- الكميات بعد الإكمال: loaded=6، delivered=1، returned=5، pending=0.
- أُنشئ Credit Note واحد: `CN-43b66b3845bf2adf9c83e6b784a83e42`، Posted، بقيمة 528.00.
- أُنشئ Journal Entry: `JE-7E5D28D7DE5346FE9ACE`، Posted، سطران؛ Debit=528.00 وCredit=528.00، والفرق صفر.
- `inventory_log` يحتوي خمسة حركات `SalesReturn`، كل منها كمية 1، بإجمالي خمس وحدات.
- سجل التدقيق يثبت تحديث خمسة أسطر في `order_details`، ثم تحديث حالة RS-2 إلى Returned.
- مطابقة projection بين `run_sheet_details` ومصدر `order_details`: 12 مجموعة، 0 mismatches، 0 one-sided groups.

هذه أدلة مباشرة على نجاح عملية المرتجع الخلفية وآثارها. لم ينفذ هذا الفحص العملية ولم يغير أي بيانات.

### D. Current Production Eligibility Snapshot

الحالة الحية عند الفحص:

| Runsheet | Status | Detail rows | Loaded | Delivered | Returned | Pending return |
|---|---|---:|---:|---:|---:|---:|
| RS-1 | Delivered | 5 | 13 | 13 | 0 | 0 |
| RS-2 | Returned | 7 | 6 | 1 | 5 | 0 |

- Returning count = 0.
- لا يوجد حاليًا أي Delivered له كمية مرتجعة متبقية في العينة الكاملة المسترجعة.
- بناءً على المصدر والبيانات الحالية، المتوقع أن تكون قائمة Delivered المؤهلة فارغة. هذا استنتاج من المصدر والبيانات، وليس اختبار UI فعليًا.

### E. New Workflow Contract Finding

- `run_sheet_details` للـauthenticated لديه SELECT، لكن `has_table_privilege(authenticated, run_sheet_details, UPDATE)=false`، ولا توجد UPDATE policy للمستخدمين.
- `saveReturnItem()` في الواجهة يكتب إلى Dexie `localChanges` ثم يحاول تحديث `run_sheet_details` مباشرة، ويتجاهل نتيجة الطلب.
- Edge Function `cancel-return` يوضح أن مسودات الأصناف device-local حتى ينفذ `complete-return`، وأن `run_sheet_details` projection مشتق ولا يجب تصفيره مباشرة.
- `cancelReturn()` لا يحذف سجلات `localChanges`، بينما `_loadLocalChanges()` يعيد تحميلها عند فتح جلسة لاحقة، و`completeReturn()` يحذفها عند نجاح الإكمال.

**المؤكد:** المسودة المحلية تبقى بعد الإلغاء ويمكن أن يعاد تحميلها في جلسة لاحقة.  
**غير المحسوم:** هل هذا سلوك مقصود للاستئناف أم يجب أن يعني الإلغاء التخلص من المسودة؟ لا تغيّر هذا المسار قبل قرار مالك واضح؛ لأنه قد يؤثر في كميات المرتجع التي تُرسل لاحقًا.

### F. Production Security / ACL — Blocker قائم

الفحص المباشر أكد:

1. سياسة `categories` باسم `Allow all for all`:
   - roles = `{public}`
   - command = `ALL`
   - `qual=true` و`with_check=true`.
   - anon لديه table privileges للقراءة والإدخال والتحديث والحذف.

2. `stock_discrepancies`:
   - سياسة SELECT للـpublic بشرط true.
   - سياسة INSERT للـpublic مع `with_check=true`.
   - anon لديه SELECT وINSERT فعليان وفق `has_table_privilege`.

3. `has_table_privilege` أكد TRUNCATE للـanon والـauthenticated على الأقل في:
   `items, categories, branches, runsheets, users, stock_discrepancies, return_reasons`.
   كما ظهر TRUNCATE للـauthenticated على `run_sheet_details` و`order_details`.

RLS enabled لا يحمي من TRUNCATE. لم أجرّب أي عملية destructive ولم أغير grants أو policies. هذه ثغرة صلاحيات Production عالية الأولوية وتحتاج مراجعة مستهلكين وخطة rollback قبل أي DDL أو ACL mutation.

## 4) UNKNOWN

- هل Cloudflare Production يقدم الآن commit 5745f36 أم لا.
- ما هي headers الفعلية لـ`returns.html` و`core.js` في الخادم، وهل توجد cache headers مؤثرة.
- هل واجهة المستخدم تعرض القائمة والبحث والمعاينة والصور كما يتوقع المصدر الحالي.
- هل الاحتفاظ بمسودات Dexie بعد cancel مقصود أم خلل.
- نتيجة طلب UPDATE المباشر داخل `saveReturnItem` لم تُلتقط من Runtime؛ المنع مؤكد من عقد Production، لكن الاستجابة الفعلية غير مختبرة.

## 5) CONFLICT / RECONCILIATION

- آخر Cloudflare deployment source commit موثق في Report563 هو `9e3fe1342abfc845a24014a3eec6fbe8abef5348`. ملف Returns عنده Blob `c284f88ba0c7d4c0373b66f826f8a3c8c11599b7` ولا يحتوي على فلتر pending eligibility.
- Main الحالي `5745f36` متقدم بأربعة commits عن ذلك deployment checkpoint. لذلك لا يجوز مساواة Main بالنسخة المنشورة.
- Report564 يقول إن بعض Owner patches لم تكن مطبقة؛ هذا الوصف أصبح تاريخيًا وتجاوزه Git الحالي.
- PR #8 ما زال Draft/Unmerged، بينما Main يحتوي الآن على commits لاحقة. لا تستخدم PR head كبديل عن Main ولا تدمجه دون إعادة مراجعة كاملة.
- Memory ledger كان متوقفًا عند LVE-560، وCURRENT_STATE عند LVE-563؛ تم تحديثهما بهذا الحدث.

## 6) UNVERIFIED

- Cloudflare artifact identity وserved bytes.
- Browser authenticated E2E لقائمة Delivered والبحث والمعاينة والصور.
- اختبار سلوك cancel ثم فتح جلسة جديدة على الجهاز نفسه.
- CI/Playwright PASS للـcommits الحالية.

حاولت فتح عنوان Pages المنشور مباشرة، لكن أداة الويب لم تستطع الوصول إليه، كما لم يتوفر Browser context أو Cloudflare dashboard/API في هذا التشغيل. سجلات Edge للمرتجع لا تحتوي Referer/Origin usable، لذلك لا تربط عملية RS-2 بـcommit معين.

## 7) مصفوفة التحقق

| الطبقة | النتيجة |
|---|---|
| GitHub / Source | CONFIRMED — patch موجود على Main |
| Supabase Production schema/RLS/Edge | CONFIRMED — العقود والوظائف والسياسات قُرئت مباشرة |
| Deployed artifact | UNVERIFIED — آخر commit موثق أقدم من Main |
| Runtime / E2E | PARTIAL — Edge POSTs نجحت؛ UI E2E غير منفذ |
| Business-data effects | CONFIRMED — RS-2، 5 وحدات مخزون، Credit Note، Journal متوازن، projection متطابق |

## 8) ما تم فعليًا في هذه المراجعة

- قراءة CURRENT_STATE والدستور وReport563.
- إعادة جلب Main والملفات الحالية والـPR والـcommits.
- إعادة جلب Production schema/RLS/grants/FKs/triggers/Edge Functions والمigrations ذات الصلة.
- استعلامات SQL للقراءة فقط ومراجعة Edge logs وسجلات التدقيق والمخزون والحسابات.
- تحليل JavaScript المضمن في Returns وapp.html.
- إنشاء هذا التقرير وتحديث CURRENT_STATE وذاكرة المشروع.

**لم يتم:** تعديل operational HTML، أو تعديل PR، أو نشر Cloudflare، أو DDL/RLS/grants، أو تعديل Edge Function/RPC، أو إنشاء بيانات اختبار، أو تعديل المخزون والحسابات.

## 9) الخطوة التالية ذات الأولوية

الحصول على دليل Cloudflare Production الحالي: commit/build lineage ثم served `returns.html` و`core.js` وheaders، ومطابقتها مع Main `5745f36`. بعد ذلك فقط ينفذ اختبار Browser مصادق عليه لقائمة Returns والبحث والمعاينة. لا تدمج PR #8؛ Main يحتوي بالفعل على التعديلات الأحدث.

يظل ACL blocker عالي الخطورة مفتوحًا ويجب ألا يُنسى عند تقرير أي توسع Production.

**Final Status:** RETURNS SOURCE PATCH CONFIRMED ON MAIN / PRODUCTION RETURN BACKEND CONFIRMED / DEPLOYMENT + UI E2E UNVERIFIED / LOCAL CANCEL-DRAFT SEMANTICS OPEN / CRITICAL ACL BLOCKER OPEN / NOT PRODUCTION READY / NOT CLOSED.
