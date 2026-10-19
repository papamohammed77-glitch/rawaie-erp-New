# Report451 — Picker Fresh Production Resynchronization and Idempotent Completion Gap
**التاريخ:** 2026-10-19  
**وقت فحص Production:** `2026-10-19 18:16:17 UTC` لقاعدة البيانات؛ أُعيد جلب Edge objects ومصادر Git في دورة الفحص نفسها.  
**النطاق:** `erp-frontend/companies/company-1/warehouse/picker.html` وتكامل التحضير المباشر مع Edge/Core/Projection.  
**القيود المحترمة:** لم أعدّل `main.html` أو ملف التطبيق التشغيلي. لم أغيّر Schema/ACL/Edge في Production، ولم أُنشئ أو أعدّل أو أحذف أي بيانات أعمال.  
**الحالة:** `FRESH PRODUCTION RESYNC COMPLETE / EXISTING OWNER PATCHES STILL APPLICABLE / NEW RETRY-IDEMPOTENCY PATCH IDENTIFIED / NOT CLOSED`.

---

## 1. PRE-CHANGE SELF-AUDIT

- **Business Understanding:** 98/100 — دورة التحضير، الحجز، الإلغاء وإعادة الفتح مفهومة من المصدر الحي وعقد Core.
- **Architecture Understanding:** 98/100 — Picker → authenticated Edge → service_role → restricted Core RPC → `order_details` → trigger → `run_sheet_details` projection.
- **Database Understanding:** 99/100 — أُعيد فحص الأعمدة، RLS، grants، triggers، وتعريفات Core وACL في Production.
- **Historical Understanding:** 96/100 — قورنت النسخة التشغيلية الحالية بالـOriginal التاريخي، ورُوجعت تقارير 449 و450 وسجل الحالة وآخر commits المعروفة. الـOriginal مرجع تاريخي وليس مصدر التشغيل.
- **Production Understanding:** 99/100 — جُلبت الوظائف الأربع المنشورة مجددًا، وقورنت محتوياتها حرفيًا بملفات Current.
- **Current Understanding:** 100/100 لملف Picker الحالي الذي جرى جلبه كاملًا: 925 سطرًا، SHA `c7ad267d852d415b680aed7716833eea9bcffdf6`.
- **Execution Confidence:** 94/100 للتشخيص؛ لا يمكن رفع ثقة E2E دون اختبار مصادق عليه على Fixture معزول أو متصفح فعلي.

### Confirmed Facts

1. ملف التشغيل الحالي:
   - Repository: `papamohammed77-glitch/erp-frontend`
   - Path: `companies/company-1/warehouse/picker.html`
   - Blob SHA: `c7ad267d852d415b680aed7716833eea9bcffdf6`
   - الحجم: 49,238 حرفًا / 925 سطرًا.
   - لم يتغير عن SHA الموثق في Report449/450.
2. Original التاريخي:
   - `rawaie-erp-New/Original/PWA/warehouse/picker.html`
   - SHA: `7626ba320021a607854bf219f4bacd81fc3d1d92`
   - 623 سطرًا / 45,103 حرفًا. لا يُستبدل به المصدر التشغيلي الحالي.
3. أحدث commit مطابق لبحث Picker ما زال `703342f4fadb046388bcdeb826b4911167c96b67`؛ أضاف company scoping واستخدام `users.auth_id`. لا يُعاد هذا الإصلاح.
4. أحدث تقارير النطاق:
   - Report449: `f8056c80acd2231015c926a69565e1205fd3a29d`
   - Report450: `3a1a46f0a6abf941fee0f9809d141e2dc3bed3fa`
   - آخر تحديث معروف لـ`CURRENT_STATE.md` قبل هذا التقرير: commit `0f57e1a3fb381a74d7548546dec2dd5b76a61576`.
5. لم يظهر تغيير أحدث في ملف Picker نفسه. مصدر HTML التشغيلي ما زال غير معدل؛ لذلك تظل جراحات المالك في Report449/450 مطلوبة.

## 2. Fresh Production Snapshot

### Edge Functions — أعيد جلب كل وظيفة منشورة ومقارنتها بمصدر Current

| Edge Function | Production version | verify_jwt | Production `ezbr_sha256` | Current Git blob | Content parity |
|---|---:|---|---|---|---|
| `start-picking` | 35 | true | `fca0377fce2d02d52a17bdbbdd98cfe9cc449d052533df0a3b021be11c79914a` | `14188f5d60d70cc4ec214cd27145398979e06403` | EXACT |
| `complete-picking` | 18 | true | `14b4d650253e73abc7c7a1b1f25a8674849c11e32d21ae9928701f19705b0537` | `be06ac006adc146df46adc893e18105d95c0e9a3` | EXACT |
| `cancel-picking` | 5 | true | `218052d71120eeab9f83aff045a14e24173dd15f3dafdb4e91978e7dd7bbda01` | `69005b8c8b73baad5d54a9af9e155d45b621014f` | EXACT |
| `reopen-picking` | 9 | true | `ca69477e935cb78b7f9cebe13940e589c58adcf891ee16a26cc15354c735b3ae` | `fe7d6f77f1f34ba141f47d6af6e33ac5e8443ac2` | EXACT |

المطابقة أعلاه هي مقارنة محتوى `index.ts` حرفيًا بين Edge object الحي وملف Current المقابل؛ لا أساوي `ezbr_sha256` مع Git blob SHA.

### Database / Core / ACL

- `run_sheet_details` يحتوي `qty_picked` لكنه Projection مشتق؛ Trigger `trg_sync_run_sheet_details` يستدعي `sync_run_sheet_details()` عند INSERT/UPDATE/DELETE في `order_details`.
- `sync_run_sheet_details()` يعيد اشتقاق `qty_picked` و`qty_loaded` و`qty_delivered` وحقول الكميات الأخرى من `order_details`، ويحدّث Projection عبر upsert.
- Production grants لـ`authenticated` على `run_sheet_details` لا تتضمن UPDATE. سياسة RLS الحالية للجدول هي SELECT فقط. لا تمنح UPDATE للواجهة ولا تضف سياسة تسمح به.
- Core الصحيح هو `public.complete_runsheet_picking(p_company_id uuid, p_runsheet_code text, p_user_email text, p_items jsonb, p_operation_id uuid DEFAULT NULL)`. يثبت المصدر أنه:
  1. يتحقق من الشركة والرانشيت وحالة `Picking` وهوية المحضّر.
  2. يسجل/يتحقق من `operation_id` إذا قُدّم.
  3. يستدعي `reserve_stock` للكميات المحضّرة.
  4. يحدّث `order_details.qty_picked` وسبب النقص.
  5. يحول الحالة إلى `Picked`.
  6. لا ينشئ Physical Movement ولا `inventory_log` لحركة مادية أثناء التحضير.
- ACL: overload الخماسي قابل للتنفيذ من `service_role` فقط؛ `anon/authenticated` مرفوضان. Overload رباعي قديم موجود، لكنه لا يملك EXECUTE لـ`anon/authenticated/service_role`، ولم يظهر له مستدعٍ SQL مباشر في فحص `pg_proc.prosrc`. لم أحذفه لأن ذلك تغيير تدميري خارج الحاجة المثبتة لهذه الوحدة.
- سلسلة الثقة الحالية صحيحة: PWA لا تكتب إلى Core مباشرة؛ Edge يتحقق من JWT وهوية الشركة والصلاحية والدور النشط ثم يستدعي Core بـ`service_role`.

### Logs / Served Artifact

- استعلام Supabase unified logs أعاد خطأ Backend في هذه الدورة؛ لا أستنتج منه نجاحًا أو فشلًا تشغيليًا.
- محاولة جلب صفحة Cloudflare المنشورة عبر أداة الويب لم تنجح؛ لذلك **served HTML parity = UNVERIFIED**.
- لم أستخدم رانشيتًا حيًا كـFixture، ولم أغيّر بيانات Production.

## 3. دورة الحياة المثبتة

```
Picker
  ├─ start-picking → authenticated Edge → company/role checks → runsheet Picking
  ├─ edit quantities → draft محلي داخل جلسة الواجهة (بعد تطبيق Report450 يصبح محفوظًا محليًا عبر Dexie)
  ├─ complete-picking → authenticated Edge → complete_runsheet_picking
  │   ├─ reserve_stock
  │   ├─ order_details.qty_picked + reason_picking
  │   ├─ sync_run_sheet_details trigger
  │   └─ runsheet Picked
  ├─ cancel-picking → cancel_runsheet_picking
  └─ reopen-picking → reopen_runsheet_picking
```

لا يجوز كتابة `run_sheet_details` مباشرة من Picker، ولا كتابة `order_details` مباشرة من PWA، ولا اعتبار التحضير حركة مخزون مادية.

## 4. LOSS / GAIN / RESPONSIBILITY MATRIX

| المسؤولية | التصنيف | الدليل / القرار |
|---|---|---|
| Company scoping و`users.auth_id` | RETAINED | SHA الحالي وcommit 703342 |
| Authorization على Edge Functions الأربع | HARDENED / PRODUCTION VERIFIED | النسخ الحية تطابق Current حرفيًا |
| كتابة `run_sheet_details.qty_picked` من UI | INVALID / REMOVE | لا UPDATE grant أو policy للمستخدم المصادق؛ Projection مشتق |
| استعادة مسودة التحضير بعد refresh | MISSING IN CURRENT HTML | Dexie store معرّف لكن غير مستخدم للحفظ/الاستعادة؛ Report450 يعالج ذلك |
| عرض أخطاء القراءة كأنها قائمة فارغة | MISSING ERROR HANDLING | Report449 patches B/C |
| Idempotent retry لإنهاء التحضير من PWA | MISSING CONSUMER CONTRACT | Core/Edge يقبلان `operation_id`، لكن PWA الحالي لا يرسله |
| Current ↔ Production Edge parity | VERIFIED | مطابقة حرفية لأربع وظائف |
| HTML Git ↔ Cloudflare served parity | UNVERIFIED | أداة الوصول للصفحة فشلت |
| Authenticated HTTP E2E / browser E2E | UNVERIFIED | لم يتوفر Fixture معزول ولا جلسة متصفح مصادق عليها في هذه الدورة |

## 5. Owner Change Set — لا تعدّل ملف التشغيل أو main.html من المساعد

### أولًا: طبّق Report449 وReport450 دون تكرار أو توسيع

المصدر المستهدف لا يزال SHA `c7ad267d852d415b680aed7716833eea9bcffdf6`.

- Report449 PATCH A: احذف الكتابة المباشرة إلى `run_sheet_details`.
- Report449 PATCH B/C: أضف حراس أخطاء القراءة في `renderPendingTab()` و`openRunsheet()`.
- Report450 PATCH B/C: احفظ واستعد مسودة الجهاز في Dexie، مع التحقق من `runsheet_id` و`picker_start`.
- Report450 PATCH A: بعد إزالة السطر غير الصحيح، لا تضف كتابة بديلة إلى قاعدة البيانات.
- لا تلمس `main.html`، ولا تغيّر ACL أو Trigger أو Core لهذا العيب.

المراجع الكاملة والتحديدات الحرفية:
- [Report449](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report449_PICKER_FORENSIC_INTEGRATION_AND_SURGICAL_FIX_20261019.md)
- [Report450](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report450_PICKER_SERVER_AUTHORIZATION_AND_DRAFT_PERSISTENCE_20261019.md)

### ثانيًا: PATCH E — تمرير operation_id ثابت لإنهاء التحضير

هذا نقص جديد مثبت من تتبع المستهلك حتى Core: Edge `complete-picking` يقرأ `body.operation_id` أو `Idempotency-Key` ويمرره إلى Core؛ أما Picker الحالي فيرسل `runsheet_code` و`items` فقط. نتيجة ذلك أن إعادة الطلب بعد ضياع الاستجابة لا تستفيد من idempotency registry، وإن كانت حماية حالة الرانشيت تمنع إتمامه مرتين.

نفّذ PATCH E **بعد** جراحات Report449/450، ثم أعد جلب الملف وحساب أرقام الأسطر من جديد.

#### E1 — إنشاء مفتاح واحد ثابت لجلسة إكمال الطلب

- **الملف:** `companies/company-1/warehouse/picker.html`
- **الدالة:** `App.completePicking()`
- **المحدد:** ابحث عن السطر:
  ```js
  var self = this; if(!this.session) return; if(!navigator.onLine){ toast('أنت غير متصل', 'warning'); return; }
  ```
- **استبدله كاملًا بـ:**
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

#### E2 — احفظ المفتاح قبل HTTP، ثم أرسله في الجسم والـheader

- **الدالة:** `App.completePicking()`
- **المحدد الأول:** ابحث عن:
  ```js
  supabase.auth.getSession().then(function(sessionRes){
  ```
- **استبدله بـ:**
  ```js
  db.session.put(self.session).then(function(){
      return supabase.auth.getSession();
  }).then(function(sessionRes){
  ```
  هذا يضمن حفظ `operation_id` في Dexie قبل إرسال الطلب. إذا فشل حفظ المسودة، لا تُرسل العملية إلى الخادم دون مفتاح محفوظ.

- **المحدد الثاني:** داخل استدعاء `fetch(.../functions/v1/complete-picking)`، أضف header:
  ```js
  'Idempotency-Key': operationId
  ```
  إلى كائن `headers` الموجود، مع الإبقاء على `Content-Type` و`Authorization`.

- **المحدد الثالث:** استبدل الجسم:
  ```js
  body: JSON.stringify({ runsheet_code: self.session.runsheet_code, items: items })
  ```
  بـ:
  ```js
  body: JSON.stringify({
      runsheet_code: self.session.runsheet_code,
      items: items,
      operation_id: operationId
  })
  ```

#### E3 — لا تعِد استخدام مفتاح مرتبط بحمولة مختلفة

- **الدالة:** `App.editPickedItem(index)`
- **المحدد:** ابحث عن السطرين:
  ```js
  self.session.items[index].qty_picked = r.value.qty;
  self.session.items[index].notes = r.value.notes;
  ```
- **استبدلهما بـ:**
  ```js
  if (self.session.items[index].qty_picked !== r.value.qty ||
      self.session.items[index].notes !== r.value.notes) {
      self.session.operation_id = null;
  }
  self.session.items[index].qty_picked = r.value.qty;
  self.session.items[index].notes = r.value.notes;
  ```
  أبقِ حفظ Dexie الخاص بـReport450 مباشرة بعد هذين السطرين. أي تغيير في الكمية أو الملاحظات يحرر المفتاح السابق؛ أما إعادة الطلب بنفس الحمولة فتبقى على المفتاح نفسه.

#### E4 — استعادة operation_id مع المسودة

- **الدالة:** `App.openRunsheet(code)`
- **المحدد:** داخل كتلة `if(sameSession){` في Patch B الخاص بـReport450، أضف في بداية الكتلة:
  ```js
  if (typeof savedSession.operation_id === 'string' &&
      /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(savedSession.operation_id)) {
      self.session.operation_id = savedSession.operation_id;
  }
  ```
  هذا يحافظ على نفس المفتاح بعد refresh في نفس دورة التحضير. لا تستعده إذا اختلف `runsheet_id` أو `picker_start`.

### الأثر المتوقع من PATCH E

- تكرار نفس طلب الإكمال بعد timeout/ضياع الاستجابة يعيد النتيجة المسجلة من Core بدل الاعتماد على حالة `Picked` فقط.
- اختلاف الحمولة لا يعاد إرساله بالمفتاح نفسه.
- لا Edge Function جديدة، ولا تغيير Schema/ACL، ولا كتابة مباشرة إلى أي جدول.
- لم يُنفذ هذا التعديل على الملف؛ المالك يطبقه وفق تقسيم المسؤوليات.

## 6. الاختبارات المطلوبة بعد تطبيق المالك

1. JavaScript syntax validation للملف كاملًا بعد التعديلات، ثم إعادة جلب SHA.
2. فتح التطبيق من Cloudflare مع cache bypass ومقارنة محتوى الصفحة المخدوم بالمصدر.
3. مستخدم مخزن مصادق عليه وصالح: فتح قائمة الرانشيتات وقراءة الأخطاء دون عرض قائمة فارغة كنجاح.
4. بدء التحضير وتعديل صنفين؛ refresh قبل الإكمال؛ التحقق من استعادة الكميات والملاحظات على الجهاز نفسه فقط.
5. التأكد من أن Network لا يحتوي PATCH/UPDATE إلى `run_sheet_details`.
6. إكمال التحضير: تحقق من `order_details.qty_picked`، و`runsheets.status='Picked'`، والحجز، وProjection بعد Trigger، وعدم وجود Physical Movement.
7. إعادة إرسال **نفس** `operation_id` والحمولة بعد محاكاة ضياع الاستجابة: يجب أن يرجع Core نتيجة مكررة ناجحة دون إعادة الحجز.
8. تغيير الكمية بعد إلغاء نافذة التأكيد: يجب إنشاء `operation_id` جديد عند محاولة الإكمال التالية.
9. اختبر cancel/reopen على Fixture معزول فقط، مع التحقق من تحرير/إعادة الحجز مرة واحدة.
10. اختبر رفض مستخدم غير مصرح به ورفض مستخدم من شركة أخرى.
11. افحص Logs وProduction counts بعد الاختبار وتأكد من عدم وجود Test residue.
12. لا تعتبر HTTP E2E أو browser E2E مغلقًا حتى تتوفر أدلة تشغيل فعلية.

## 7. Production / Governance

- لم تُجرَ أي تغييرات Production في هذه الدورة؛ الأدلة الحالية لا تبرر تعديل Schema/ACL/Core.
- لا تمنح `authenticated` صلاحية UPDATE على `run_sheet_details`.
- لا تحذف overload القديم غير القابل للتنفيذ دون Closure Unit مستقلة تثبت كامل اعتمادات التاريخ والـcallers؛ لا يوجد Caller SQL مباشر مثبت له حاليًا.
- لم يُثبت served HTML parity ولا HTTP/browser E2E؛ لا تدّعِ الإغلاق.
- لا تُنشئ بيانات اختبار في Production على رانشيتات فعلية. استخدم Fixture معزولًا فقط عند إثبات عزله وإمكانية استعادة baseline.

## SELF-AUDIT FINAL

- **What I Proved:** المصدر الحالي وSHA؛ Original التاريخي؛ Production versions/JWT flags؛ المطابقة الحرفية بين Current وProduction لأربع Edge Functions؛ RLS/grants على projection؛ trigger ومحتوى Core؛ غياب `operation_id` من طلب PWA الحالي.
- **What I Did Not Prove:** Cloudflare served-byte parity، authenticated HTTP E2E، browser E2E، أو نجاح PATCH E بعد تطبيقه.
- **What I Fixed:** لم أغيّر الملف التشغيلي أو `main.html`؛ لم تكن هناك حاجة إلى تعديل Production لهذا العيب. وثّقت PATCH E الإضافي فوق جراحات Report449/450.
- **What I Initially Missed:** لم يكن ربط PWA بـCore idempotency مكتملًا؛ Core يدعم `operation_id` لكن المستهلك لا يرسله.
- **What Could Still Be Wrong:** تنفيذ المالك قد يختلف عن محددات هذا التقرير؛ يجب إعادة جلب SHA قبل التطبيق وبعده. قد يظل النشر المخدوم مختلفًا عن Git حتى إثبات parity.
- **Final Confidence:** 99/100 في نتائج الفحص الساكن وProduction SQL/Edge parity؛ لا تُستخدم هذه الدرجة كبديل عن E2E.
- **Final Closure Status:** `PRODUCTION CORE/EDGE VERIFIED / OWNER PATCHES 449–451 REQUIRED / SERVED PARITY + HTTP E2E OPEN / NOT CLOSED`.
