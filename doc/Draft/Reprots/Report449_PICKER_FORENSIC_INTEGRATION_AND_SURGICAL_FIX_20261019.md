# Report449 — التحقيق الجنائي لتكامل تطبيق المحضّر مع دورة الرانشيت
**التاريخ:** 2026-10-19  
**النطاق:** `erp-frontend/companies/company-1/warehouse/picker.html` فقط من ناحية التطبيق التشغيلي؛ لا تعديل على `main.html` ولا على ملف التطبيق التشغيلي بواسطة المساعد.  
**بيئة الإنتاج:** Supabase project `fiilmooggumokxanwiyx`.  
**النتيجة:** `ROOT CAUSE VERIFIED / SURGICAL OWNER PATCH REQUIRED / NO PRODUCTION CHANGE REQUIRED / FULL HTTP E2E NOT RUN`.

---

## 1. PRE-CHANGE SELF-AUDIT

- **Business Understanding:** 95/100 — دورة التحضير تنقل الرانشيت من `Open/Confirmed` إلى `Picking` ثم `Picked`؛ الحجز يتم عبر Core عند إكمال التحضير، وليس بحركة مخزون مادية.
- **Architecture Understanding:** 96/100 — الواجهة تتصل بـEdge Functions المصادقة، والـEdge يستخدم `service_role` لاستدعاء Core؛ `run_sheet_details` جدول تلخيص مشتق من `order_details` وليس مصدر الحقيقة النهائي لكميات التحضير.
- **Database Understanding:** 97/100 — تم فحص تعريف `complete_runsheet_picking` و`sync_run_sheet_details`، وسياسات RLS ومنح الجدول والـTriggers ذات الصلة مباشرة في Production.
- **Historical Understanding:** 90/100 — قورنت النسخة الحالية بملف `rawaie-erp-review/PWA/warehouse/picker.html` وجرى فحص diff لأحدث commit المعروف الخاص بالملف. لم تُثبت قراءة نسخة Original منفصلة من `rawaie-erp-New` بسبب عدم نجاح مساراتها المتوقعة في الاسترجاع؛ لذلك لا أدعي اكتمال مقارنة كل طبقات Original/Archive في المستودع الجديد.
- **Production Understanding:** 98/100 — تمت قراءة Edge Functions المنشورة وتعريفات SQL وACL والسجلات المتاحة في نفس دورة الفحص.
- **Current Understanding:** 98/100 — الملف الحالي من GitHub قُرئ كاملًا: 925 سطرًا، blob SHA `c7ad267d852d415b680aed7716833eea9bcffdf6`.
- **Execution Confidence:** 94/100 — سبب العيب مثبت؛ لا أدعي E2E كاملًا لأن تنفيذ عمليات التحضير الفعلية على الرانشيتات الحية قد يغيّر حالة عمل حقيقية، ولم يتوفر Fixture معزول مثبت.

### Confirmed Facts
1. آخر مصدر حالي قرأناه: `erp-frontend/companies/company-1/warehouse/picker.html`, SHA `c7ad267d852d415b680aed7716833eea9bcffdf6`, 925 سطرًا.
2. أحدث commit عُثر عليه ببحث `picker`: [703342f4fadb046388bcdeb826b4911167c96b67](https://github.com/papamohammed77-glitch/erp-frontend/commit/703342f4fadb046388bcdeb826b4911167c96b67)، بتاريخ 2026-08-17، ورسالة `Update picker.html`. الـdiff يوضح إضافة سياق الشركة واستخدام `users.auth_id` بدل البحث بالبريد الإلكتروني؛ هذا تغيير صحيح ومتوافق مع عزل الشركة، ولا يُعاد.
3. Production Edge الحالي:
   - `start-picking`: v34، `verify_jwt=true`, `ezbr_sha256=706840bfe745f2e12b4584ff99dc9d7d6c08a5ef5f35f5afb0a57a684aaa1adf`.
   - `complete-picking`: v17، `verify_jwt=true`, `ezbr_sha256=eb631b8f3ed33b51847bad5cdf7868eaeada70221cf001ea2bd4c53bc768f1df`.
   - `cancel-picking`: v4، `verify_jwt=true`, `ezbr_sha256=e8013e0e06dd38503e3bc9c44a62c8b689212b145a9bbb44f45f48d99cdc5c66`.
   - `reopen-picking`: v8، `verify_jwt=true`, `ezbr_sha256=b095383e169f2c2736a7c71d7505fc10fc9893d428a948199d7ffc420ecfa9e9`.
4. Core `complete_runsheet_picking(..., p_operation_id uuid DEFAULT NULL)` يحدّث `order_details.qty_picked`، ويستدعي `reserve_stock`، ويحدّث حالة الرانشيت إلى `Picked`. لا يكتب حركة مخزون مادية ولا يستدعي `post_stock_movement`، وهذا صحيح لدورة التحضير.
5. Trigger `trg_sync_run_sheet_details` يعمل على INSERT/UPDATE/DELETE في `order_details`. ودالة `sync_run_sheet_details()` تعيد اشتقاق `run_sheet_details.qty_picked` و`qty_loaded` وغيرها من `order_details`. هذا يثبت أن `run_sheet_details` Projection مشتق؛ لا ينبغي أن تكتب الواجهة فيه مباشرة.
6. Production RLS على `run_sheet_details` يحتوي سياسة SELECT فقط للمستخدمين المصادق عليهم، و`information_schema.role_table_grants` لا يعرض UPDATE لـ`authenticated`. لذلك استدعاء الواجهة في السطر 643:
   ```js
   supabase.from('run_sheet_details').update({ qty_picked: r.value.qty }).eq('runsheet_id', self.session.runsheet_id || null).eq('item_code', it.item_code).then(function(){});
   ```
   ليس مسار حفظ صالحًا في Production؛ إنه يتجاهل نتيجة الخطأ ويستهدف جدولًا مشتقًا ومحميًا. السجل الحي الذي تمت مراجعته يثبت GET ناجحًا لقراءة `run_sheet_details` في 2026-10-19 17:14:26 UTC، ولا يثبت نجاح PATCH. لا أدعي وجود PATCH فاشل مسجل؛ عدم صلاحية UPDATE مثبتة من ACL/RLS.
7. سجل Production يثبت استخدام التطبيق لقراءة تفاصيل الرانشيت من `run_sheet_details`، والـLoader يقرأ هذه projection، بينما Core التحميل يعتمد على `order_details.qty_picked` ويُنفّذ الحركة من خلال `post_stock_movement`. بذلك تبقى حدود المصدر المركزي محفوظة.
8. في `renderPendingTab()`، نتيجة `Promise.all([p1,p2])` لا تتحقق من `results[0].error` و`results[1].error` قبل تحويل `data || []`. قد تتحول أخطاء القراءة إلى قائمة فارغة تبدو كأنها «لا توجد مهام». وفي `openRunsheet()` لا يتم فحص `rsRes.error` قبل التعامل مع `rsRes.data`، ولا `detRes.error` قبل تحويل التفاصيل إلى قائمة. هذه فجوات معالجة أخطاء مؤكدة من المصدر الحالي، لكنها ليست سببًا مثبتًا لتعطل Production الآن.
9. Production snapshot المقروء أظهر وجود رانشيتين بحالة `Open`، ولم يُنفذ تغيير عليهما أو إنشاء/حذف بيانات تجريبية.
10. لم تُجرَ تغييرات على Production أو SQL أو ACL أو Edge Functions في هذه الدورة؛ لا يوجد تغيير خلفي مبرر لأن العيب الأساسي في Consumer HTML، ومنح UPDATE للواجهة سيخالف عقد Core/Projection.

### Unknowns / Unverified
- لم يُثبت تطابق نسخة HTML التي يخدمها Cloudflare حرفيًا مع blob SHA الحالي؛ سجل المتصفح يثبت أن صفحة من `rawaea-erp.pages.dev` قرأت `run_sheet_details`، لا تطابق كل البايتات.
- لم يُنفذ HTTP E2E للتحضير/الإلغاء/إعادة الفتح على Production لأن ذلك يتطلب تغيير حالة رانشيت حي، ولا يوجد Fixture معزول مثبت في هذه الدورة.
- لا أُعلن إغلاقًا كاملًا لتجربة المتصفح أو parity النشر.

---

## 2. دورة الحياة والعقد المركزي

```
Picker UI
  ├─ start-picking  → مصادقة المستخدم + تحديد الشركة + انتقال Open/Confirmed → Picking
  ├─ edit quantities → حالة مؤقتة في جلسة الواجهة
  ├─ complete-picking → complete_runsheet_picking
  │                      ├─ تحقق الشركة والرانشيت والمستخدم
  │                      ├─ reserve_stock
  │                      ├─ تحديث order_details.qty_picked
  │                      ├─ trigger sync_run_sheet_details
  │                      └─ status = Picked
  ├─ cancel-picking → cancel_runsheet_picking + تحرير الحجز/إعادة الحالة حسب العقد
  └─ reopen-picking → reopen_runsheet_picking + إعادة دورة التحضير حسب العقد
```

- **Physical Movement:** لا يحدث عند التحضير؛ لا ينبغي أن ينشئ Picker حركة عبر `post_stock_movement`.
- **Reservation:** يتم عبر `reserve_stock` في Core عند إكمال التحضير.
- **Projection:** `run_sheet_details` يعاد بناؤه من `order_details` عبر Trigger؛ لا يكتب إليه Picker مباشرة.
- **Company isolation:** المصدر الحالي يقيّد قراءة الرانشيتات بـ`company_id` ويحل المستخدم بواسطة `auth_id`; هذه التعديلات محفوظة.
- **Consumer mapping:** `picker.html → start-picking/complete-picking/cancel-picking/reopen-picking → Core RPCs → order_details/runsheets → sync_run_sheet_details → loader/report reads`.

---

## 3. LOSS / GAIN / RESPONSIBILITY MATRIX

| المسؤولية | الحالة | الدليل |
|---|---|---|
| تحديد المستخدم عبر `auth_id` وسياق الشركة | RETAINED / HARDENED | المصدر الحالي وcommit 703342 |
| بدء التحضير | RETAINED | Edge `start-picking` v34 |
| إنهاء التحضير والحجز | RETAINED / CENTRALIZED | `complete-picking` v17 + Core |
| تحديث projection بعد Core | RETAINED / CENTRALIZED | Trigger `trg_sync_run_sheet_details` |
| كتابة `run_sheet_details.qty_picked` مباشرة من الواجهة | LEGACY / INVALID UNDER CURRENT ACL | السطر 643 + ACL/RLS |
| التعامل مع أخطاء قراءات قائمة الرانشيت | MISSING | تجاهل `error` في `renderPendingTab` و`openRunsheet` |
| مطابقة HTML المنشور مع Git | UNVERIFIED | لا يوجد artifact hash موثوق في هذه الدورة |
| HTTP E2E على Production | NOT RUN | لا توجد fixture معزولة؛ حماية الرانشيتات الحية مقدمة |

---

## 4. التعديل الجراحي المطلوب من المالك

**لا تعدّل الملف كله. لا تعدّل `main.html`. لا تغيّر SQL/ACL.**

### PATCH A — إزالة الكتابة المباشرة غير المصرح بها إلى Projection

- **الملف:** `erp-frontend/companies/company-1/warehouse/picker.html`
- **Blob SHA الحالي:** `c7ad267d852d415b680aed7716833eea9bcffdf6`
- **الدالة:** `App.editPickedItem(index)`
- **الموضع:** السطر 643 في النسخة الحالية.
- **محدد البحث — ابحث عن هذا النص حرفيًا واحذفه فقط:**
  ```js
  supabase.from('run_sheet_details').update({ qty_picked: r.value.qty }).eq('runsheet_id', self.session.runsheet_id || null).eq('item_code', it.item_code).then(function(){});
  ```
- **النص البديل:** لا تضف أي كتابة بديلة إلى قاعدة البيانات. احذف السطر وحده؛ تبقى تحديثات `self.session.items[index]` في الذاكرة، والحفظ الرسمي عند `complete-picking` الذي يكتب إلى `order_details` عبر Core. لا تستبدله بتحديث مباشر إلى `order_details` أو RPC آخر.
- **الأثر:** إزالة طلب UPDATE مرفوض ومُهمل الخطأ، ومنع تجاوز Projection/ACL. لا يغيّر هذا وحده سلوك الحفظ النهائي، لكنه لا يضيف استمرارية محلية أثناء جلسة التحضير؛ استعادة جلسة غير مكتملة بعد إعادة تحميل الصفحة تظل غير مثبتة وتحتاج تصميمًا منفصلًا قبل الادعاء بأنها مدعومة.

### PATCH B — عدم عرض أخطاء القراءة على أنها «لا توجد مهام»

هذا إصلاح Consumer مستقل صغير، يظل داخل الملف نفسه.

- **الدالة:** `App.renderPendingTab()`
- **محدد البحث:** داخل `.then(function(results){` ابحث عن الكتلة التالية واحذفها فقط:
  ```js
  var myRunsheets = results[0].data || [];
  var openRunsheets = results[1].data || [];

  self.allRunsheets = myRunsheets.concat(openRunsheets);
  self.renderRunsheetLists(myRunsheets, openRunsheets);
  ```
- **البديل الكامل:**
  ```js
  if (results[0].error || results[1].error) {
      console.error('Picker runsheets load error:', {
          mine: results[0].error || null,
          available: results[1].error || null
      });
      safeHTML(
          byId('mainContent'),
          '<div class="text-center py-20 text-red-400">تعذر تحميل الرانشيتات. حدّث الصفحة أو راجع صلاحياتك واتصالك.</div>'
      );
      return;
  }

  var myRunsheets = results[0].data || [];
  var openRunsheets = results[1].data || [];

  self.allRunsheets = myRunsheets.concat(openRunsheets);
  self.renderRunsheetLists(myRunsheets, openRunsheets);
  ```
- **الأثر:** التفريق بين «لا توجد مهام» و«فشل قراءة البيانات». لا يغيّر استعلامات الشركة أو حالات الرانشيت.

### PATCH C — معالجة خطأ قراءة الرانشيت وتفاصيله

- **الدالة:** `App.openRunsheet(code)`
- **الموضع الأول:** داخل `.then(function(rsRes){`، قبل `if(!rsRes.data)`.
- **أضف هذا الحارس فقط:**
  ```js
  if (rsRes.error) {
      console.error('Picker runsheet read error:', rsRes.error);
      toast('تعذر قراءة الرانشيت. تحقق من الاتصال والصلاحيات.', 'error');
      self.renderPendingTab();
      return;
  }
  ```
- **الموضع الثاني:** داخل `.then(function(detRes){`، قبل `var items = detRes.data || [];`.
- **أضف هذا الحارس فقط:**
  ```js
  if (detRes.error) {
      console.error('Picker runsheet details read error:', detRes.error);
      toast('تعذر تحميل أصناف الرانشيت.', 'error');
      self.renderPendingTab();
      return;
  }
  ```
- **الأثر:** منع تحويل أخطاء قاعدة البيانات إلى «الرانشيت غير موجود» أو شاشة تفاصيل فارغة.

---

## 5. الاختبار المطلوب بعد تطبيق المالك للتعديلات

1. JavaScript syntax validation للملف كاملًا دون إعادة تنسيقه.
2. تسجيل دخول مستخدم مخزن فعلي مصادق عليه، والتحقق من الشركة والدور.
3. فتح قائمة التحضير مع نتائج فعلية، ثم محاكاة خطأ قراءة في Staging للتأكد من ظهور رسالة الخطأ لا قائمة فارغة.
4. فتح رانشيت `Open/Confirmed`؛ بدء التحضير؛ تعديل كمية؛ التأكد من عدم إرسال PATCH إلى `run_sheet_details`; إكمال التحضير؛ التحقق من أن `complete-picking` يستدعي Core وأن `order_details.qty_picked` وProjection `run_sheet_details.qty_picked` متطابقان بعد Trigger.
5. اختبار الكميات الجزئية/الصفرية وسبب النقص؛ التحقق من `available_qty = qty - allocated_qty` ومن عدم وجود حركة مخزون مادية في مرحلة التحضير.
6. اختبار الإلغاء وإعادة الفتح على Fixture معزول فقط؛ التحقق من الحجز وحالة الرانشيت وعدم تكرار تحرير الحجز.
7. اختبار مستخدم من شركة أخرى والتأكد من عدم رؤية/فتح الرانشيت.
8. فحص Network: لا يوجد UPDATE من المتصفح إلى `run_sheet_details`، والكتابة التشغيلية تأتي من Edge→service_role→Core.
9. التحقق من نسخة Cloudflare المنشورة مقابل المصدر بعد تطبيق المالك.

**لم تُنفّذ اختبارات الحالة التي تغيّر بيانات Production في هذه الدورة. لا تنشئ اختبارًا على رانشيت حقيقي قيد العمل.**

---

## 6. Production / Governance

- لا Migration مطلوبة.
- لا تعديل ACL مطلوب؛ عدم وجود UPDATE لـ`authenticated` هو حد أمني صحيح.
- لا Edge Function جديدة؛ الحد الحالي للـFunctions لا يبرر إضافة واحدة.
- لم يُغيّر Production ولم تُنشأ/تُحذف بيانات تجريبية.
- لا تُعلن `100% CLOSED` قبل تطبيق المالك للتغييرات، وفحص المصدر المخدوم، وتشغيل E2E معزول مثبت.

---

## 7. SELF-AUDIT FINAL

- **What I Proved:** مصدر Picker الحالي، خطأ الكتابة المباشرة إلى projection، ACL/RLS، Core reservation، Trigger إعادة اشتقاق projection، وإصدارات Edge المنشورة.
- **What I Did Not Prove:** تطابق bytes بين Cloudflare وGit، ونجاح HTTP E2E حقيقي على fixture معزول، واستعادة جلسة التحضير بعد إعادة تحميل الصفحة.
- **What I Fixed:** لم أعدّل ملف التشغيل أو Production لأن الملك هو منفذ تغييرات HTML ولأن تغيير ACL سيكون غير صحيح؛ جهزت ثلاث جراحات محددة.
- **What I Initially Missed:** الكتابة المباشرة القديمة بقيت في UI رغم أن الكتابة النهائية أصبحت مركزية عبر Core، كما أن PostgREST يعيد أخطاء داخل نتيجة Promise ولا يلزم أن يرفض الـPromise.
- **What Could Still Be Wrong:** قد توجد فروق بين الملف المخدوم والمصدر؛ لا يُستنتج من Git وحده أن التعديلات نُشرت.
- **Final Confidence:** 94/100 في تشخيص عيب الواجهة، و78/100 في الإغلاق التشغيلي لعدم تنفيذ HTTP E2E.
- **Final Closure Status:** `SURGICAL PATCHES READY / OWNER APPLICATION REQUIRED / PRODUCTION UNCHANGED / NOT CLOSED`.
