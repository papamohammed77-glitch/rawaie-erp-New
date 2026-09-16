# Report207 — التحقيق الجنائي واستكمال إدارة المخازن والمخزون

**التاريخ:** 2026-09-16  
**نوع المهمة:** GLOBAL INVENTORY / Mother System E2E / Functional Completion  
**مصدر الحقيقة:** CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE

> **النقطة الأهم:** الهدف في هذه الجلسة كان اختبار واستكمال **ملف النظام الأم المنشور** `erp-frontend/companies/company-1/main.html`، وليس الرجوع إلى أجزاء `Current/PWA/main2`. ملف النظام الأم هو Source of Truth الحالي، والتقارير السابقة استُخدمت كخلفية تاريخية فقط. أي حالة مستقبلية يجب أن تبدأ بإعادة مطابقة هذا الملف مع Git الحالي وProduction الحالية، لا بإعادة تنفيذ إصلاحات قديمة.

## 1. قاعدة العمل

التزمت بالتسلسل:

UNDERSTAND → RECONSTRUCT HISTORY FOR INTENT ONLY → TRACE CURRENT → TRACE DATA/AUTH/DEPLOYMENT → IDENTIFY GAP → SURGICAL FIX → TEST → PRODUCTION VERIFY.

لم يتم تعديل `companies/company-1/main.html` من جانبي. جميع تغييرات Mother المطلوبة ما زالت Owner-only.

## 2. CURRENT GIT — تم التحقق المباشر

المستودع الحالي:
`papamohammed77-glitch/erp-frontend`

الفرع:
`main`

HEAD الحالي الذي أعادته GitHub أثناء التحقيق:
`b673fa4c7b29d2ea6118aaf5c38a8bc2e1187af2`

رسالة HEAD:
`Expand mother inventory forensic source mapping`

الـparent المباشر:
`9d8fa07215d5e84f5672abb8b36c218de87559eb`

هذا الـHEAD لا يغيّر ملف النظام الأم؛ التغيير فيه خاص بأداة التحقيق E2E.

Commit سابق مباشر للـMother ضمن السلسلة:
`cff8399547277eb1db83fbd0ce809837471f2b64`
`Refactor purchase functions and realtime channel setup`

الـMother الحالي أعادت GitHub قراءة بصمة blob له:
`1e496d643d588bb2e92ea14cb8876cd9837b3e6b`

**ملاحظة حاكمة:** الـblob أعلاه هو بصمة القراءة الحالية للملف، وهو المرجع الذي يجب إعادة التحقق منه في كل جلسة لاحقة.

## 3. CURRENT MOTHER — ما ثبت فعليًا

`companies/company-1/main.html` موجود ويُخدم كملف النظام الأم.

نتيجة التدقيق الساكن:

- ملف HTML تم تحميله بنجاح.
- قائمة `إدارة المخازن والمخزون` موجودة في السطر **1145** في النسخة التي تم اختبارها.
- لا توجد عبارات `قيد التطوير` أو `جاري التطوير` أو `TODO` أو `FIXME` ضمن الفحص الساكن المستخدم.
- تبويبات إدارة المخازن التي تم إثبات وجودها في الـmenu:
  - الأصناف
  - المخازن والفروع
  - الاستلام
  - التحضير
  - التحميل
  - التوصيل
  - المرتجعات
  - التفريغ
  - تحويل مخزني
  - صرف سيارة بيع مباشر
  - استلام مرتجع سيارة
  - مرتجع لمورد
  - عرض الأذونات
  - جرد سيارة
  - جرد فرع
  - جرد عام

Dispatcher الحالي في الملف يوجّه هذه الشاشات إلى `RW_Warehouse`:

- `picking` → `RW_Warehouse.loadPicking()` — السطر 20953
- `loading` → `RW_Warehouse.loadLoading()` — السطر 20954
- `delivery` → `RW_Warehouse.loadDelivery()` — السطر 20955
- `return` → `RW_Warehouse.loadReturn()` — السطر 20956
- `unloading` → `RW_Warehouse.loadUnloading()` — السطر 20961
- `receiving` → `RW_Warehouse.loadReceiving()` — السطر 20962
- `vouchers` → `RW_Warehouse.loadVouchers()` — السطر 20963
- `transfer` → `RW_Warehouse.loadVoucherForm('Transfer')` — السطر 20964
- `direct-sale` → `RW_Warehouse.loadVoucherForm('DirectSale')` — السطر 20965
- `direct-return` → `RW_Warehouse.loadVoucherForm('DirectReturn')` — السطر 20966
- `supplier-return` → `RW_Warehouse.loadVoucherForm('SupplierReturn')` — السطر 20967
- `vehicle-count` → `RW_Warehouse.loadVehicleCount()` — السطر 20968
- `branch-count` → `RW_Warehouse.loadBranchCount()` — السطر 20969
- `general-count` → `RW_Warehouse.loadGeneralCount()` — السطر 20970
- `settlement` → `RW_Warehouse.loadSettlement()` — السطر 20971

هذا يثبت أن Mother UI لديه الهيكل التنفيذي الأساسي للمخزون، لكن لا يثبت وحده أن كل الوظائف التشغيلية الحديثة متصلة بالـProduction الجديدة.

## 4. Mother Browser E2E

تم إنشاء وتشغيل:
`.github/workflows/inventory_mother_forensic_e2e_20260916.yml`

Run:
`35058149973`

Job:
`104672563318`

النتيجة:
`success`

الاختبارات:

- Static Inventory Contract = PASS
- Source Map = PASS
- Playwright browser load = PASS
- Console errors = 0
- Page errors = 0
- Browser smoke = PASS

هذه نتيجة Browser Smoke وليست Full Authenticated Business E2E؛ لا يجوز تفسيرها على أنها إثبات نجاح كل عمليات المخزون داخل Production.

## 5. forensic_main_assembly.yml

تم إنشاء:
`.github/workflows/forensic_main_assembly.yml`

الغرض:
حماية المسار المعتمد ومنع انحراف Source of Truth بعيدًا عن:
`companies/company-1/main.html`

وذلك مع عدم حذف `Current/PWA/main2` لأن هذه الملفات تاريخية ومطلوبة للاسترشاد فقط.

## 6. مقارنة Daftra — إدارة المخزون فقط

تمت مراجعة وثائق Daftra الحالية المتعلقة بالمخزون والجرد وطلبات المخزون.

Daftra يوفّر، ضمن إدارة المخزون، مفاهيم تشغيلية تتجاوز مجرد عرض الرصيد، ومن أهمها:

1. **Stocktaking / الجرد:** إنشاء ورقة جرد، تحديد المستودع والتاريخ والملاحظات، المقارنة بين الرصيد الدفتري والعد الفعلي، ثم معالجة العجز والزيادة.
2. **Update All / Update Uncounted:** تحديث كمية النظام لكل البنود أو البنود غير المعدودة فقط قبل الإنهاء.
3. **Stock Requests / طلبات المخزون:** إنشاء طلب، اعتماد/رفض، ثم تحويل الطلب المعتمد إلى مستند/طلب مستودعي، بدل خلط الطلب بالحركة الفعلية.
4. **Tracking / serials / inventory reports:** الحفاظ على أثر قابل للتتبع، وتقارير قابلة للتصفية والتجميع والتصدير.

الاستنتاج التقني الذي ينطبق على RAWAEA ليس نسخ Daftra، بل استكمال Mother لتعرض وتتحكم في نفس طبقات المسؤولية الوظيفية مع الإبقاء على العمليات الميدانية الأصلية في RAWAEA.

## 7. ما تم تنفيذه مباشرة في Production

### 7.1 Inventory Read / Intelligence
تم إنشاء/تحديث:

`inventory_stock_snapshot(...)`

ويُرجع:
- physical quantity
- allocated quantity
- available quantity
- reorder point
- max quantity
- suggested replenishment
- cost
- stock value
- low stock flag

تم إنشاء/تحديث:

`inventory_replenishment_report(...)`

ويُرجع احتياج الاست replenishment حسب الفرع والصنف.

تم إنشاء/تحديث:

`inventory_movement_report(...)`

ويحوّل `inventory_log` إلى سجل حركات قابل للعرض مع أثر الحركة على الفرع وحساب before/after.

### 7.2 Low-stock semantics
تم منع اعتبار كل صنف ذي `reorder_point = 0` منخفض المخزون تلقائيًا.

القاعدة الآن:
`reorder_point > 0`
قبل إدخاله في low-stock/replenishment candidates.

وعند عدم وجود `max_qty` صالح أعلى من reorder point، تُستخدم كمية الوصول إلى reorder point كحد أدنى آمن بدل إخراج recommendation = 0 مضللة.

### 7.3 Inventory Count Engine
تم إنشاء/توسيع:

`inventory_count_engine(...)`

العمليات المدعومة:

`CREATE`
`GET`
`POPULATE`
`UPSERT_LINE`
`REFRESH`
`FINALIZE`
`CANCEL`

تمت إضافة بنية بيانات الجرد إلى `inventory_counts` و`inventory_count_details` مع:
- company identity
- branch identity
- item identity
- system quantity
- counted quantity
- variance
- adjusted flag
- operation identity
- timestamps

تم جعل `counted_qty` بلا default متعمد؛ السبب أن البنود غير المعدودة يجب ألا تُعتبر صفرًا.

تم دعم:
`REFRESH mode = ALL`
و
`REFRESH mode = UNCOUNTED`

والـFINALIZE يرفض وجود بند غير معدود.

### 7.4 Inventory Count physical adjustment
كل فرق فعلي في الجرد يتحرك عبر:

`post_stock_movement`

ولا يوجد Writer بديل للمخزون.

تم رفض استخدام `stock_discrepancies` لتسجيل فروق الجرد العام لأن هذا الجدول مرتبط بعقد Runsheet discrepancy وهو ليس سجل الجرد العام.

### 7.5 Stock Request Engine
تم إنشاء:

`inventory_stock_requests`
`inventory_stock_request_details`

وEngine:
`inventory_stock_request_engine(...)`

العمليات:

`CREATE`
`GET`
`APPROVE`
`REJECT`
`CONVERT`
`CANCEL`

والتحويل إلى إذن مخزني يستخدم:
`create_manual_stock_voucher_atomic(...)`

ولا ينفذ حركة فعلية عند مجرد إنشاء الطلب أو اعتماده.

هذه النقطة تحافظ على الفصل الصحيح بين:

REQUEST
→ APPROVAL
→ VOUCHER
→ PHYSICAL MOVEMENT

## 8. Edge infrastructure

كانت هناك محاولة لإنشاء Edge Function جديدة باسم `inventory-control`، لكن Production رفضتها بسبب الوصول إلى حد عدد Edge Functions في المشروع.

لم أستخدم هذا كسبب للتوقف.

تم إعادة استخدام Function قائمة:

`save-inventory-count`

وتحويلها إلى Gateway آمن يدعم:

`COUNT_*`
`REQUEST_*`
`SNAPSHOT`
`MOVEMENTS`
`REPLENISHMENT`

مع الحفاظ على backward-compatible legacy count contract.

تم تفعيل `verify_jwt=true` في هذا الـGateway.

## 9. Realtime

تمت إضافة جداول المخزون ذات الصلة إلى `supabase_realtime`:

- `inventory_log`
- `inventory_counts`
- `inventory_count_details`
- `stock_discrepancies`

والهدف أن تكون Mother والتطبيقات التنفيذية قادرة على الاستماع إلى تغييرات المخزون دون إنشاء Read Path خاص لكل شاشة.

## 10. Inventory Physical Writer audit

العقد المركزي المثبت في Production هو:

`PHYSICAL MOVEMENT`
→ `post_stock_movement`
→ `stock_branches`
+ `inventory_log`

تم فحص Production بحثًا عن Functions تعدل `stock_branches` أو تكتب `inventory_log` مباشرة.

لا يوجد Physical Writer مستقل صالح كبديل للـcentral engine ضمن النتائج الحالية.

الاستثناءات الوظيفية:

`reserve_stock`
و
`release_stock_reservation`

وهما Reservation Engine وليس Physical Movement Engine.

`setup_van_stock` / `create_vehicle_atomic`

هما setup/bootstrap functions وليسا حركة مخزنية.

## 11. مشاكل تم اكتشافها أثناء التنفيذ ومعالجتها

### المشكلة 1 — Fixture/Legacy stock data
الـProduction السابقة التي كانت التقارير تذكرها أظهرت cross-company stock rows عديدة.
التحقق الحالي في Production أوضح أن الشركة المرجعية الحالية واحدة، وبالتالي لا يجوز استخدام التقرير القديم أو الـfixtures السابقة كحالة حالية.

### المشكلة 2 — counted_qty default
تم اكتشاف أن default قد يحول البنود غير المعدودة إلى صفر.
تمت إزالته قبل اعتماد Finalize.

### المشكلة 3 — partial unique index
تم اكتشاف أن `ON CONFLICT` الخاص بسطر الجرد لن يكون صحيحًا مع partial unique index.
تم تحويل الهوية إلى UNIQUE صريح:
`count_id + branch_id + item_id`

### المشكلة 4 — إعادة الاختبار ببيانات تاريخية
اختبار Stock Request فشل أولًا لأن target branch مأخوذ من تقرير قديم ولم يكن صحيحًا في Production الحالية.
أعيد الاختبار بالفرع الموجود فعليًا فقط.

### المشكلة 5 — Edge Function capacity
إنشاء Function جديدة فشل بسبب حد Functions.
الحل النهائي كان Gateway داخل Function موجودة بدل تضخم البنية.

### المشكلة 6 — SQL diagnostic غير صالح
تم تنفيذ query تشخيصي احتوى على function غير موجودة (`public.pg_stat_file`).
الاستعلام فشل ولم يغير Production، ثم أعيد التنفيذ باستعلام صحيح.

## 12. اختبارات Production

### Inventory Snapshot
نجح على Company الحالية وActor نشط.

### Inventory Count E2E
تم اختبار:

CREATE
→ UPSERT_LINE
→ FINALIZE

وتم التحقق من:
- نجاح العملية
- delta صحيح في المخزون
- إنشاء inventory_log واحد
- عدم بقاء fixture بعد rollback

### Stock Request E2E
تم اختبار:

CREATE
→ APPROVE
→ CONVERT

وتم التحقق أن CONVERT لا يغير المخزون؛ الحركة الفعلية تظل داخل مسار الـvoucher المركزي.

### Production pollution guard
بعد الاختبارات transactional:

`inventory_counts = 0`
`inventory_count_details = 0`
`inventory_stock_requests = 0`
`inventory_stock_request_details = 0`

وبقيت بيانات `inventory_log` الحالية الموجودة أصلًا فقط.

## 13. ما لم يتم ادعاؤه

لم يتم الادعاء بإغلاق Gold/Diamond للـMother Inventory UI، لأن Mother HTML لم تُعدّل في هذه الجلسة حسب فصل المسؤوليات.

التشغيل الخلفي أصبح أقوى وأكثر اكتمالًا، لكن واجهة Mother الحالية لم تُوصل بعد إلى كل capabilities الجديدة:

- stock snapshot
- replenishment intelligence
- movement intelligence
- full count engine
- stock request workflow

وجود dispatcher قديم لهذه التبويبات يثبت نقطة دخول الشاشة، لكنه لا يثبت أن الشاشة تستخدم الـcapabilities الجديدة.

## 14. OWNER SURGICAL PATCH — المطلوب من المالك في Mother فقط

**لا تعد إلى `Current/PWA/main2` للتعديل.**

### PATCH-A — إدارة المخازن والمخزون
افتح:
`companies/company-1/main.html`

ابحث عن **السطر 1145** الذي يبدأ بالعنصر الكامل:
`{ icon: 'fa-warehouse', label: 'إدارة المخازن والمخزون'...`

لا تحذف القائمة الحالية كاملة.

المطلوب في الـMother التالي هو إنشاء/ربط واجهة إدارة مخزون حديثة داخل `RW_Warehouse` تستدعي Gateway `save-inventory-count` بعقود العمليات الجديدة.

**هذه المهمة تحتاج تحديد exact function block بعد فتح `RW_Warehouse` الحالي؛ لا تنفذ على الوصف وحده.**

لذلك لا يتم تقديم Replace block تخميني هنا؛ لأن الملف الحالي ضخم جدًا، والحوكمة تمنع اختراع مقطع استبدال قبل قراءة block الكامل من بدايته إلى نهايته.

### PATCH-B — Current dispatcher
مصدر التوجيه الحالي هو block dispatcher الذي يبدأ عند السطر **20515**، والـinventory entries فيه من السطور **20953–20971**.

لا تحذف هذه الـentries الآن؛ لأنها تمثل العقود الميدانية الأصلية.

المطلوب في الخطوة القادمة هو **استدعاء capabilities الجديدة من داخل `RW_Warehouse`** مع الإبقاء على:

Picker
Loader
Driver
Return
Unloader
Runsheet
Settlement

دون استبدالها بتطبيق Inventory عام.

## 15. القرار المعماري

RAWAEA لا يجب أن يقلد Daftra في استبدال العمليات الميدانية بتبويب عام.

التصميم المستهدف هو:

Mother System
↓
Inventory Control Plane
↓
Stock Snapshot / Replenishment / Movement Intelligence / Count Control / Request Control
↓
Existing Field Execution Apps
↓
post_stock_movement
↓
stock_branches + inventory_log

وهذا يحافظ على أكثر ما يميز RAWAEA: operational field execution مع مركز تحكم موحد.

## 16. FINAL SELF-AUDIT

### What I proved

- Source of Truth الحالي هو Mother HTML في `erp-frontend`.
- Mother لم يتم تعديلها في هذه الجلسة.
- Current Git HEAD أعيد التحقق منه.
- Parent commit أعيد التحقق منه.
- Mother browser smoke ناجح بلا Console/Page errors.
- Inventory menu والـdispatcher موجودان.
- Production schema يدعم الجرد والمخزون.
- Physical Stock Engine المركزي موجود.
- لا يوجد Physical Writer مستقل بديل صالح في Production الحالية.
- Inventory Read/Intelligence layer منشورة.
- Count Engine منشور.
- Stock Request Engine منشور.
- Existing Edge Gateway أعيد استخدامه بسبب Function limit.
- Realtime publications تمت إضافتها.
- Count E2E transactional نجح.
- Stock Request E2E transactional نجح بعد استخدام current branch evidence.
- لم تترك الاختبارات بيانات fixture جديدة.

### What I did not prove

- Full authenticated browser E2E لكل تبويب مخزون داخل Mother.
- Full network trace لكل endpoint مخزني من Mother.
- الربط النهائي في UI بين Mother والتقارير الجديدة.
- اكتمال Gold/Diamond للواجهة الأم حتى يتم هذا الربط ثم إعادة E2E حديث.
- Full comparison مع كل وظائف Daftra خارج الوظائف التي تتعلق مباشرة بإدارة المخزون والجرد وطلبات المخزون.

### What I initially missed

- أن `counted_qty` default يجعل POPULATE خطيرًا.
- أن `ON CONFLICT` لا يطابق partial unique index.
- أن اعتماد operation fingerprint فقط غير كافٍ لهوية retry في Purchase Receiving دون client operation identity ثابت.

### What could still be wrong

- توجد capabilities Production جديدة تحتاج Consumer integration داخل Mother.
- `receive-purchase` الحالي يحتاج client operation identity ثابتة من Mother قبل الادعاء بإغلاق retry/idempotency الكامل.
- Functions التشغيلية المرتبطة بالمرتجعات والتسليم يجب مواصلة مراجعتها ضمن Writer Closure Units منفصلة.

## 17. NEXT SESSION — إرشادات إلزامية للمساعد التالي

1. لا تبدأ من التقارير.
2. ابدأ بـ`CURRENT_STATE.md` ثم CURRENT Git HEAD ثم direct parent.
3. افتح `companies/company-1/main.html` نفسه، ولا تستخدم `Current/PWA/main2` كمصدر للحالة.
4. أعد أخذ blob SHA للـMother قبل أي تحليل.
5. خذ Production snapshot جديد في نفس وقت التقرير.
6. لا تعتبر أي report ratio أو PASS قديم صالحًا بعد تغير HEAD/Production.
7. ابدأ من آخر نقطة مثبتة: Inventory backend capabilities أصبحت موجودة، فلا تعيد إنشائها.
8. الوحدة المفتوحة الآن هي Mother Consumer Integration لهذه capabilities، وليس إعادة بناء backend.
9. افتح `RW_Warehouse` كاملًا قبل طلب أي surgical patch.
10. اربط كل شاشة داخل Mother بالـAPI الموجود دون كسر العمليات الميدانية الحالية.
11. أي physical mutation يجب أن يظل عبر `post_stock_movement`.
12. أي reservation يجب أن يظل عبر Reservation Engine فقط.
13. بعد كل owner patch: Git refresh → browser → console → network → Production DB → realtime.
14. لا تعتبر Browser Smoke = Authenticated E2E.
15. لا تعتبر Staging/temporary transaction = Production success دائم.
16. لا تنشئ Edge Function جديدة قبل فحص capacity؛ استخدم capability الموجودة إذا كانت مناسبة.
17. لا تنشئ جدولًا إذا كان موجودًا بالفعل.
18. إذا تعارض التقرير مع Production الحالية، Production هي المرجع.
19. قبل أي إصلاح جديد اسأل: هل هذه النقطة سبق إغلاقها؟ وهل الدليل الحالي أعاد فتحها؟
20. لا تعلن Gold/Diamond إلا بعد Mother UI + Backend + Network + DB + Realtime evidence كاملة.

## 18. الحالة النهائية لهذه الجلسة

```text
CURRENT GIT                         VERIFIED
CURRENT MOTHER SOURCE               VERIFIED / UNMODIFIED BY ASSISTANT
CURRENT PRODUCTION                  VERIFIED
CURRENT DATABASE                    VERIFIED
CURRENT DEPLOYMENTS                 VERIFIED
MOTHER STATIC E2E                    PASS
MOTHER BROWSER SMOKE                 PASS
INVENTORY READ ENGINE                DEPLOYED + VERIFIED
INVENTORY COUNT ENGINE               DEPLOYED + VERIFIED
STOCK REQUEST ENGINE                 DEPLOYED + VERIFIED
INVENTORY REALTIME                   DEPLOYED
PHYSICAL WRITERS OUTSIDE CORE       0 discovered
NEW PRODUCTION FIXTURES              0
FULL AUTHENTICATED MOTHER E2E        OPEN
MOTHER → NEW INVENTORY CAPABILITIES  OPEN
GOLD/DIAMOND INVENTORY UI            OPEN
NEXT CLOSURE UNIT                    MOTHER CONSUMER INTEGRATION
```
