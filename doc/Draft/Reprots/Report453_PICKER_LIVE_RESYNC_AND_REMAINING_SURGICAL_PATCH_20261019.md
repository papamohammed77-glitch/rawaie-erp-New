# Report453 — إعادة مزامنة Picker مع Production والمصدر الحالي وتحديد الجراحة المتبقية

**التاريخ:** 2026-10-19  
**النطاق الوحيد:** `erp-frontend/companies/company-1/warehouse/picker.html` وعقد Picker مع Production Core/Edge.  
**القيود:** لم أعدّل `main.html` أو ملف Picker التشغيلي. لم أغيّر Schema أو ACL أو Edge Functions أو بيانات الأعمال في Production.  
**الحالة:** `CURRENT SOURCE RESYNCED / PATCHES 449 READ-GUARDS + PROJECTION-WRITE REMOVAL ALREADY PRESENT / TWO CONSUMER PATCHES REMAIN / NOT CLOSED`.

---

## 1. PRE-CHANGE SELF-AUDIT

- **Business Understanding:** 98/100 — التحضير يسجل الكمية الفعلية ويُنشئ Reservation؛ لا يمثل حركة مخزون مادية.
- **Architecture Understanding:** 99/100 — Picker → JWT-authenticated Edge → service_role → restricted Core RPC → `order_details` → trigger → derived `run_sheet_details`.
- **Database Understanding:** 99/100 — تمت قراءة تعريفات Core والـtrigger وسياسات RLS ونتائج grants ذات الصلة مباشرة.
- **Historical Understanding:** 96/100 — تمت مراجعة Reports 449–452 وCURRENT_STATE كمؤشرات، ومقارنة التغييرات الموثقة بالـsource الحالي والـcommit الجديد. Original يظل baseline تاريخيًا وليس مصدر تشغيل.
- **Production Understanding:** 99/100 — أعيد جلب وظائف Production الأربع وSQL وحالة الرانشيتات في هذه الدورة.
- **Current Understanding:** 100/100 للملف الذي جرى جلبه كاملًا: 966 سطرًا، 51,413 حرفًا، blob SHA `3f3fab73c30dd2861e43747e6cc774d86739244b`.
- **Execution Confidence:** 96/100 للتشخيص؛ لم يُنفذ Browser/HTTP E2E مصادق عليه، ولم يثبت تطابق HTML المخدوم مع Git.

### Confirmed Facts

1. **المصدر الحالي تغيّر بعد Report452.** الملف:
   - Repo: `papamohammed77-glitch/erp-frontend`
   - Path: `companies/company-1/warehouse/picker.html`
   - Current blob SHA: `3f3fab73c30dd2861e43747e6cc774d86739244b`
   - الحجم: 51,413 حرفًا / 966 سطرًا.
2. أحدث commit عُثر عليه للملف: [b903c403c8bebf7f98307d22f9c7ca286c72382e](https://github.com/papamohammed77-glitch/erp-frontend/commit/b903c403c8bebf7f98307d22f9c7ca286c72382e)، برسالة `Improve error handling and session management in picker`. الـdiff يضيف guards لأخطاء قراءة قائمة الرانشيت، والرانشيت، والتفاصيل؛ ويضيف استعادة/حفظ جلسة عند فتح الرانشيت؛ ويحذف الكتابة المباشرة السابقة إلى `run_sheet_details`.
3. نتيجة فحص المصدر الحالي آليًا:
   - `direct_projection_updates = 0`
   - `renderPendingTab` error guard = موجود
   - `openRunsheet` runsheet error guard = موجود
   - `openRunsheet` details error guard = موجود
   - `db.session.get` = 1
   - `db.session.put` = 1
   - `operation_id / Idempotency-Key` = 0
4. لذلك فإن Report449 PATCH A–C (حذف projection update وحراس أخطاء القراءة) موجودة بالفعل في المصدر الحالي؛ **لا تعِد تطبيقها**. جزء استعادة الجلسة من Report450 موجود جزئيًا، لكنه لا يحفظ كل تعديل بعد تغيير الكمية/الملاحظات.
5. العيب المتبقي في `App.editPickedItem(index)` عند السطر الحالي 683: الكمية والملاحظات تتغيران في الذاكرة ثم يتم `renderActiveSession()` بلا `db.session.put(self.session)`. لذلك لا تُحفظ التغييرات الأخيرة محليًا بعد كل تعديل.
6. العيب المتبقي في `App.completePicking()` عند السطر الحالي 698 وما بعده: PWA يرسل `runsheet_code` و`items` فقط، ولا يرسل `operation_id` أو `Idempotency-Key`. Edge Production `complete-picking v18` يقبل كليهما ويمرر المفتاح إلى Core الخماسي المعاملات، لكن المستهلك الحالي لا يستفيد من عقد إعادة المحاولة.
7. Production Edge أُعيد جلبه ومقارنته حرفيًا بملفات `rawaie-erp-New/Current/Edge_Functions/`:
   
   | Function | Production version | verify_jwt | Production ezbr_sha256 | Current Git blob | تطابق المحتوى |
   |---|---:|---|---|---|---|
   | `start-picking` | 35 | true | `fca0377fce2d02d52a17bdbbdd98cfe9cc449d052533df0a3b021be11c79914a` | `14188f5d60d70cc4ec214cd27145398979e06403` | EXACT |
   | `complete-picking` | 18 | true | `14b4d650253e73abc7c7a1b1f25a8674849c11e32d21ae9928701f19705b0537` | `be06ac006adc146df46adc893e18105d95c0e9a3` | EXACT |
   | `cancel-picking` | 5 | true | `218052d71120eeab9f83aff045a14e24173dd15f3dafdb4e91978e7dd7bbda01` | `69005b8c8b73baad5d54a9af9e155d45b621014f` | EXACT |
   | `reopen-picking` | 9 | true | `ca69477e935cb78b7f9cebe13940e589c58adcf891ee16a26cc15354c735b3ae` | `fe7d6f77f1f34ba141f47d6af6e33ac5e8443ac2` | EXACT |

   تمت مقارنة محتوى `index.ts` نفسه حرفيًا. Git blob SHA وProduction `ezbr_sha256` معرفان مختلفان، ولم تتم مساواتهما.
8. SQL Production في هذه الدورة أكد:
   - `complete_runsheet_picking(uuid,text,text,jsonb,uuid)` هو overload الخماسي الذي تستدعيه Edge؛ `service_role` فقط يملك EXECUTE.
   - `run_sheet_details` محمي بـRLS؛ `authenticated` لديه SELECT ولا يملك UPDATE.
   - `trg_sync_run_sheet_details` يعمل بعد INSERT/UPDATE/DELETE على `order_details`، و`sync_run_sheet_details()` يعيد اشتقاق الإسقاط من مصدر التفاصيل الأساسي.
   - `reserve_stock` هو الحجز؛ لا توجد حاجة إلى كتابة مخزون مادي أو إضافة ACL لهذه المهمة.
9. فحص Production الأخير عند `2026-10-19 19:59:21.177102+00 UTC` أعاد: `runsheets=2`, `run_sheet_details=12`, `stock_branches=57`. الرانشيتان الحاليتان `RS-1` و`RS-2` حالتهما `Open`، والكميات المحضرة صفر. لم أستخدمهما كـfixtures ولم أغيّر بيانات أعمال.
10. استعلام السجلات الموحد لم يعطِ دليلًا صالحًا في هذه الدورة؛ لا أدعي HTTP E2E أو نجاحًا/فشلًا مستندًا إلى logs. كما أن تطابق Cloudflare served HTML مع Git ما زال `UNVERIFIED`.

### Unknowns / Conflicts / Unverified Claims

- `UNVERIFIED`: HTML الذي يقدمه Cloudflare مطابق بايتًا ببايت لملف Git.
- `UNVERIFIED`: تنفيذ E2E مصادق عليه لإكمال/إلغاء/إعادة فتح التحضير.
- `UNVERIFIED`: استعادة المسودة بعد تطبيق الحفظ لكل تعديل، لأن المستهلك لم يُعدّل بعد.
- لم يظهر تضارب جديد يبرر تغيير Production schema/ACL/Edge. إضافة صلاحية UPDATE إلى `run_sheet_details` ستكون مخالفة للعقد وليست إصلاحًا.

---

## 2. مراجعة التغييرات السابقة: ما يُمرر وما لا يُعاد

| التغيير/المسؤولية | الحكم الحالي | الإجراء |
|---|---|---|
| Company scope في قراءات Picker | صحيح وموجود | RETAIN |
| ربط هوية التطبيق عبر `users.auth_id` | صحيح وموجود | RETAIN |
| معالجة أخطاء `renderPendingTab/openRunsheet` | موجودة في آخر commit | RETAIN؛ لا تكرر |
| حذف UPDATE المباشر إلى `run_sheet_details` | موجود في آخر commit | RETAIN؛ لا تستبدله بكتابة مباشرة أخرى |
| حفظ/استعادة Dexie عند فتح الجلسة | موجود جزئيًا | استكمال حفظ كل تعديل |
| تمرير `operation_id` في الإكمال | غير موجود في المصدر الحالي | إضافة Patch جراحي |
| Production Edge auth + JWT | صحيح؛ النسخ الحية تطابق Current | لا تعديل |
| Production schema / RLS / grants | متوافق مع العقد | لا تعديل |
| اختبار HTTP/browser + served artifact parity | غير مثبت | يبقى مفتوحًا حتى اختبار فعلي |

---

## 3. التعديل الجراحي المتبقي — ينفذه المالك في Picker فقط

**لا تعدّل `main.html` ولا تستبدل ملف Picker بالكامل.** قبل التطبيق أعد جلب الملف وتأكد أن SHA ما زال `3f3fab73c30dd2861e43747e6cc774d86739244b`. إذا تغيّر، أعد مطابقة النصوص المستهدفة.

### PATCH 453-A — حفظ الكمية والملاحظات بعد كل تعديل

- **الملف:** `companies/company-1/warehouse/picker.html`
- **الدالة:** `App.editPickedItem(index)`
- **موضع السطر الحالي:** 683–686.
- **محدد البحث الحرفي:** ابحث عن هذه الأسطر الثلاثة:
  
  ```js
  self.session.items[index].qty_picked = r.value.qty;
  self.session.items[index].notes = r.value.notes;
  self.renderActiveSession();
  ```

- **استبدل الأسطر الثلاثة فقط بهذه الكتلة:**
  
  ```js
  if (self.session.items[index].qty_picked !== r.value.qty ||
      self.session.items[index].notes !== r.value.notes) {
      self.session.operation_id = null;
  }
  self.session.items[index].qty_picked = r.value.qty;
  self.session.items[index].notes = r.value.notes;
  db.session.put(self.session).catch(function(err){
      console.error('Picker draft persistence error:', err);
      toast('تعذر حفظ مسودة التحضير على هذا الجهاز', 'error');
  });
  self.renderActiveSession();
  ```

- **الأثر:** يحفظ التغييرات محليًا باستخدام مخزن Dexie الموجود؛ لا ينشئ جدولًا أو خدمة جديدة. عند تغيير الحمولة يُلغى مفتاح العملية السابق لمنع إعادة استخدامه لطلب مختلف. لا توجد كتابة إلى قاعدة Production من هذا المقطع.

### PATCH 453-B — مفتاح ثابت لإعادة محاولة إكمال التحضير

#### B1 — تجهيز operation_id مرة واحدة لكل حمولة

- **الدالة:** `App.completePicking()`
- **محدد البحث:** أول سطر داخل الدالة:
  
  ```js
  var self = this; if(!this.session) return; if(!navigator.onLine){ toast('أنت غير متصل', 'warning'); return; }
  ```

- **استبدله بالنص التالي:**
  
  ```js
  var self = this; if(!this.session) return; if(!navigator.onLine){ toast('أنت غير متصل', 'warning'); return; }
  if (!this.session.operation_id) {
      if (!window.crypto || typeof window.crypto.randomUUID !== 'function') {
          toast('المتصفح لا يدعم إنشاء مفتاح العملية. حدّث المتصفح ثم أعد المحاولة.', 'error');
          return;
      }
      this.session.operation_id = window.crypto.randomUUID();
  }
  var operationId = this.session.operation_id;
  ```

#### B2 — حفظ المفتاح قبل إرسال الطلب

- **محدد البحث:** داخل `.then(function(result){` في تأكيد إنهاء التحضير، ابحث عن:
  
  ```js
  supabase.auth.getSession().then(function(sessionRes){
  ```

- **استبدل هذا السطر فقط بالنص التالي:**
  
  ```js
  db.session.put(self.session).then(function(){
      return supabase.auth.getSession();
  }).then(function(sessionRes){
  ```

- إذا فشل حفظ المسودة فلن يرسل المتصفح طلب الإكمال دون حفظ المفتاح محليًا.

#### B3 — إرسال المفتاح في HTTP headers

- **داخل** `fetch(SUPABASE_URL + '/functions/v1/complete-picking', ...)`، استبدل قيمة `headers` الحالية:
  
  ```js
  headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token }
  ```

- **بالنص التالي:**
  
  ```js
  headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ' + token,
      'Idempotency-Key': operationId
  }
  ```

#### B4 — إرسال operation_id في جسم الطلب

- **محدد البحث الحرفي:**
  
  ```js
  body: JSON.stringify({ runsheet_code: self.session.runsheet_code, items: items })
  ```

- **استبدله بـ:**
  
  ```js
  body: JSON.stringify({
      runsheet_code: self.session.runsheet_code,
      items: items,
      operation_id: operationId
  })
  ```

- **عقد إعادة المحاولة:** إذا ضاعت الاستجابة بعد تنفيذ العملية، يعاد إرسال نفس الحمولة بالمفتاح نفسه. إذا تغيرت الكمية أو الملاحظات، PATCH 453-A يمسح المفتاح السابق ويولد الإكمال التالي مفتاحًا جديدًا. لا يُولد مفتاح جديد لمجرد إعادة المحاولة.

---

## 4. الاختبارات المطلوبة بعد التطبيق

1. إعادة جلب Picker بعد التطبيق، وحفظ SHA الجديد، ومراجعة diff للتأكد من أن التعديل اقتصر على موضعي الجراحة.
2. استخراج JavaScript وتشغيل syntax check كامل.
3. تحقق ساكن: لا يوجد `from('run_sheet_details').update`؛ حراس القراءة الثلاثة موجودة؛ `db.session.put/get` موجودان؛ `operation_id` و`Idempotency-Key` موجودان.
4. تعديل صنفين ثم Refresh قبل الإكمال: الكميات والملاحظات تستعاد فقط عندما يطابق `runsheet_id` و`picker_start` دورة التحضير الحالية.
5. إكمال طبيعي والتحقق من حالة `Picked`، وتحديث `order_details.qty_picked`، ومزامنة `run_sheet_details` بواسطة Trigger، وصحة `allocated_qty`.
6. إعادة إرسال الطلب نفسه بنفس المفتاح: يجب أن يعيد Core النتيجة المسجلة دون حجز ثانٍ.
7. تغيير الكمية/الملاحظات بعد فشل محاولة غير مكتملة: يجب أن يتغير المفتاح قبل الحمولة الجديدة.
8. اختبار cancel ثم reopen على Fixture معزول فقط؛ لا تستخدم `RS-1` أو `RS-2` الحيين.
9. تحقق من Company isolation ومن رفض مستخدم لا يملك warehouse permission أو دور تحضير صحيح.
10. إثبات Cloudflare served HTML parity، ثم فحص baseline وعدم وجود test residue.

**لا يُنشأ fixture في Production الآن** لأن الرانشيتات الظاهرة هي بيانات أعمال فعلية ولا توجد بيئة Staging مستقلة مثبتة في هذه الدورة. لا يوجد تغيير Production مبرر قبل تطبيق مستهلك HTML واختباره.

---

## 5. SELF-AUDIT FINAL

- **What I Proved:** SHA الحالي وحجم Picker؛ commit الجديد وdiff؛ أن الحراس وحذف direct projection write موجودة؛ أن حفظ Dexie بعد التعديل وoperation_id ما زالا غائبين؛ أن Edge Production الأربع تطابق Current source حرفيًا؛ أن Core/RLS/trigger يدعمون العقد المركزي.
- **What I Did Not Prove:** served HTML parity، browser/HTTP E2E مصادق عليه، أو نجاح حفظ المسودة بعد التعديل قبل تطبيق PATCH 453-A.
- **What I Fixed:** لم أعدّل ملفات التشغيل أو Production. صححت الحالة التدقيقية وحددت بدقة أن أجزاء من Report449/450 أصبحت منفذة بالفعل في commit `b903c403c8bebf7f98307d22f9c7ca286c72382e`؛ المتبقي هو Patch 453-A و453-B فقط.
- **What I Initially Missed:** تقرير 452 كان مبنيًا على SHA أقدم `c7ad267d852d415b680aed7716833eea9bcffdf6`. آخر commit غيّر الملف، لذا إعادة تطبيق كل حزمة 449–452 كما هي ستكرر تغييرات وتستهدف سياقًا قديمًا.
- **What Could Still Be Wrong:** HTML المخدوم قد لا يساوي Git الحالي؛ لا توجد E2E مصادق عليها؛ لا يمكن إعلان إغلاق lifecycle قبل اختبار معزول.
- **Final Confidence:** 0.99 في تحديد الحالة الحالية والفجوتين المتبقيتين؛ 0.65 في الإغلاق التشغيلي إلى حين اختبار المستهلك المنشور.
- **Final Closure Status:** `CURRENT SOURCE RESYNCED / PRODUCTION EDGE-CORE VERIFIED / TWO OWNER PATCHES REQUIRED / SERVED PARITY + HTTP E2E OPEN / NOT CLOSED`.
- **Next exact step:** المالك يطبق PATCH 453-A و453-B فقط على SHA الحالي، ثم يعاد جلب المصدر ومراجعته وتشغيل الاختبارات قبل إعلان الإغلاق.
