# تقرير 382 — التحقيق الجنائي وإغلاق عقد عمود المندوب في الأذونات المخزنية
## RAWAEA ERP — DirectSale / DirectReturn — 2026-10-01

---

## 0. القرار التنفيذي

**النقطة المطلوبة:** إضافة عمود `المندوب` إلى جدول الأذونات المخزنية الخاص بـ `صرف سيارة بيع مباشر (DirectSale)` و`مرتجع/استلام سيارة بيع مباشر (DirectReturn)`، مع ربطه بالمندوب الفعلي المسؤول عن عهدة الحركة.

**مصدر هوية المندوب المعتمد:**

```text
stock_vouchers.custodian_user_id
        ↓
public.users.id
        ↓
public.users.name / email
```

ليس `driver_id`، وليس `vehicle.driver_id` إلا كـfallback داخل بعض عقود الربط الخلفية. الهوية التشغيلية المستقرة للإذن هي `custodian_user_id`.

**نتيجة التحقيق:**

1. عيب العرض في `Current/PWA/main.html` ثابت ومحدد: الجدول المضمّن لا يعرض `custodian_user_id` ولا اسم المندوب.
2. النسخة التشغيلية المركزية لا تُبنى على هذا الجدول المضمّن في المسار العادي؛ `main.html` يفوض `vouchers` إلى `./vouchers.html`. التقرير لا يخلط بين المسارين.
3. تم اكتشاف عيب Production حقيقي مستقل عن العرض كان مخفيًا في التقارير السابقة: استلام `DirectReturn` كان يحاول استخدام حركة `DirectReturn` بمصدر `NULL` بعد أن يكون إرسال المرتجع قد خفّض مخزون السيارة بالفعل. هذا يكسر الـtwo-stage contract.
4. تم إصلاح عيب Production في الـRPC المركزي الحالي فقط، بدون إنشاء Edge Function جديدة وبدون تعديل الـEdge wrappers.
5. لم يتم تعديل `main.html` في Git؛ أعطي أدناه تعديل جراحي محدد ينفذه مالك الملف.
6. تم إجراء اختبار E2E وظيفي داخل Production في معاملة تجريبية مع rollback قسري بعد جمع النتائج، وأثبت نجاح دورة DirectSale → DirectReturn SEND → DirectReturn RECEIVE → RECEIVE duplicate guard، مع حفظ المخزون والتأثير على عهدة المندوب وعدم إضافة قيود دفتر أستاذ عام.

---

## 1. حالة Git المعتمدة قبل التنفيذ

### System repository

```text
Repository: papamohammed77-glitch/rawaie-erp-New
Branch: main
HEAD: 8a175b78f09e382e7630efd09c6d97a7385e1876
Parent: b0cab4f2f63b957c449c537a445e755593712bdb
```

HEAD message:

```text
docs: update current state after Report381 cleanup and Van Sales audit
```

Parent message:

```text
docs: add SupplierReturn cleanup and Van Sales forensic execution report
```

### Current mother source

```text
Current/PWA/main.html
SHA: 27b777528665dcc985809648f006452c861ae36e
Lines: 5410
```

**هذا الملف لم يتغير في Git خلال هذه الجلسة.**

### Frontend repository

```text
Repository: papamohammed77-glitch/erp-frontend
HEAD: 503fb79da0878f97af46c8adad5bdedb0b3c283f
Parent: 1b89202949575eaebed4c5bf5512322129a114fb
Current vouchers.html blob: 85e709d0f41c189c6624a6160965d3b1a41960ba
```

آخر commit في هذا المستودع:

```text
Change user ID filter from 'id' to 'auth_id'
```

ولا يوجد دليل في النسخة الحالية على حاجة لإعادة تطبيق إصلاح `auth_id`.

---

## 2. مراجعة ملفات الحالة والتقارير السابقة

تمت مراجعة:

```text
MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md
CURRENT_STATE.md
Report358
Report359
Report360
Report361
Report362
Report380
Report381
```

تم التعامل مع هذه الملفات كـ**أدلة تاريخية فقط**، وليس كحالة Production حالية.

النقطة الأهم التي ظهر فيها اختلاف بين التاريخ والحالة الحالية هي أن تقارير DirectReturn السابقة أغلقت مسارًا بدا صحيحًا من مستوى المصدر التاريخي، لكن الاختبار على الـRPC الحالي أثبت أن عقد الاستلام الفعلي في Production ما زال يحتوي على عيب اتجاه حركة. لذلك تم اعتماد Production الحالية على التقارير السابقة، وليس العكس.

لا توجد ضرورة لإعادة تنفيذ إصلاحات Report358–362 التي ثبت وجودها فعليًا في المصدر الحالي، ولا تم العبث بها.

---

## 3. موضع الخلل في النظام الأم

الموضع الحالي داخل:

```text
Current/PWA/main.html
```

الدالة:

```js
async function loadVouchers()
```

حوالي السطر 2921، ثم:

```js
function _applyVouchers()
```

حوالي السطر 2924–2928.

الجدول الحالي يحتوي:

```text
الرقم | النوع | التاريخ | الحالة | المرجع | من | إلى | إجراءات
```

ولا يحتوي على:

```text
المندوب
```

كما أن التحميل الحالي لا يجلب مستخدمي دور:

```text
مندوب بيع مباشر
```

ولا يبني lookup من:

```text
custodian_user_id → rep name
```

إذن العيب محدد وليس عيبًا في نموذج البيانات.

---

## 4. لماذا `custodian_user_id` هو الحقل الصحيح؟

التحقيق في Production أثبت أن مسار إنشاء الإذن يكتب:

```text
DirectSale   → stock_vouchers.custodian_user_id = p_rep_id
DirectReturn → stock_vouchers.custodian_user_id = p_rep_id
```

والـtrigger الحالي يفرض على DirectSale / DirectReturn وجود custodian صحيح، active، داخل الشركة، ودوره `مندوب بيع مباشر` مع صلاحية `van-sales`.

كما أن `send_stock_voucher_atomic` يستخدم `custodian_user_id` في DirectSale لحساب عهدة المندوب.

وفي DirectReturn تستخدم مرحلة RECEIVE نفس الحقل لإثبات المندوب وعمل قيد التخفيض في `driver_ledger`.

إذن:

```text
custodian_user_id = Business Contract Authority
```

أما:

```text
driver_id
```

فهو علاقة مركبة أخرى داخل المركبة، ولا يجوز استعمالها بدلًا من هوية صاحب العهدة في الإذن.

---

## 5. المسار المعماري الحالي ولماذا لا نعيد بناءه

`main.html` يعمل كنظام أم / Shell / Parent Control Plane.

لكن قائمة الأذونات حاليًا لديها تفويض صريح:

```text
vouchers → ./vouchers.html
```

والتعليق الموجود في النظام الأم يثبت أن:

```text
Physical stock movement remains in canonical Edge/RPC
```

إذن مسار العمل الصحيح هو:

```text
MAIN
  ↓
Permission / Tenant / Navigation control
  ↓
Vouchers app
  ↓
Existing capability wrappers
  ↓
Canonical RPCs
  ↓
post_stock_movement
  ↓
stock_branches + inventory_log
```

وبالتالي لا يجوز تحويل `main.html` إلى محرّك جديد للأذونات أو إعادة كتابة lifecycle الموجود.

التعديل المطلوب في `main.html` هو compatibility/read-model enhancement فقط للجدول المضمّن، وليس إنشاء دورة تشغيل جديدة.

---

## 6. العيب Production المكتشف أثناء E2E

### الحالة قبل الإصلاح

الدالة الحالية:

```text
post_manual_stock_voucher_atomic_core_20260828
```

في RECEIVE كانت تستخدم:

```sql
WHEN 'Transfer' THEN 'TransferIn'
WHEN 'DirectReturn' THEN 'DirectReturn'
```

لكن نفس الدالة كانت تجعل:

```text
src = NULL
```

في RECEIVE.

وفي الوقت نفسه، `post_stock_movement(..., 'DirectReturn', ...)` يتطلب مصدرًا لأن دلالة `DirectReturn` فيه هي نقل من مصدر إلى وجهة، ويبحث عن رصيد المصدر.

هذا يتعارض مع عقد DirectReturn الموجود في طبقتين:

### SEND

```text
Vehicle mobile branch
      ↓
InventoryDecrease
      ↓
vehicle stock - qty
```

### RECEIVE

```text
Vehicle return document
      ↓
Branch destination
      ↓
branch stock + qty
```

ولا يجوز أثناء RECEIVE إعادة خصم السيارة مرة أخرى.

### الإصلاح الإنتاجي

تم تعديل الجزء الوحيد اللازم في Production إلى:

```sql
WHEN 'Transfer' THEN 'TransferIn'
WHEN 'DirectReturn' THEN 'InventoryIncrease'
```

وبذلك أصبح العقد:

```text
DirectReturn SEND
    = InventoryDecrease from vehicle

DirectReturn RECEIVE
    = InventoryIncrease into destination branch
```

وهذا يحافظ على:

```text
الشحنة المخصومة من السيارة لا تُخصم مرتين
والفرع لا يستلمها مرتين
```

### لماذا لم ننشئ Edge Function؟

لأن المشكلة في الـcanonical database movement contract نفسه، وليس في wrapper.

كما أن المشروع عند سقف Edge Functions، ولذلك تم الالتزام بالمسار الموجود:

```text
Existing Edge
   ↓
Existing authenticated RPC
   ↓
Existing stock writer
```

ولا توجد Edge Function إضافية.

---

## 7. Migration الكانوني الذي تم تسجيله

أضيف إلى المستودع:

```text
supabase/migrations/20261001090000_fix_directreturn_receive_stock_direction_contract.sql
```

Commit:

```text
6ae450aa42bc2d6cf4bcc30879e96365dbdde4c7
```

الـmigration محمي بشرط drift detection:

- يبحث عن النسخة الحالية من الدالة بالـsignature المحدد.
- يتحقق أن fragment المطلوب موجود مرة واحدة فقط.
- يوقف التنفيذ إذا تغيّر العقد بدل إجراء replace أعمى.
- ينفذ `CREATE OR REPLACE FUNCTION` فقط بعد تحقق uniqueness.
- يحتوي assertion نهائيًا يثبت وجود `InventoryIncrease` في فرع DirectReturn.

هذا يمنع عودة العيب بصمت في migration مستقبلي.

---

## 8. E2E Production Test — بيانات الاختبار

تم اختيار بيانات Production موجودة أصلًا، ولم يتم إنشاء master data جديدة:

### الشركة

```text
00000000-0000-0000-0000-000000000001
```

### الفرع الرئيسي

```text
BR-01
id = a38332b6-6cea-480a-ada1-6eb6ab0590db
```

### السيارة

```text
CHV-2025-01
id = 69b08188-60ee-43af-9644-e1626a85bfa0
mobile branch = 2fffcf58-be04-4599-a289-8791362398ff
```

### المندوب

```text
مندوب مبيعات بيع مباشر
id = 111b0730-a977-4d11-bcd0-2427b178a9e5
email = vansales@rawaea.com
```

المركبة مرتبطة بالمندوب عن طريق:

```text
fleet_vehicle_sales_rep_assignments
is_primary = true
end_at IS NULL
```

### الصنف

```text
1001
جو كيك 5ج
unit = حبة
sales_price = 50
```

الرصيد الابتدائي المثبت للفرع الرئيسي:

```text
qty = 8
allocated_qty = 0
available = 8
```

---

## 9. E2E Result

الاختبار جرى داخل anonymous PL/pgSQL block ثم تم إجباره على `RAISE EXCEPTION` بعد تجميع النتيجة، لكي يعود كل شيء إلى الحالة السابقة تلقائيًا.

### المرحلة A — إنشاء DirectSale

```text
status = Draft
custodian_user_id = 111b0730-a977-4d11-bcd0-2427b178a9e5
vehicle = CHV-2025-01
```

**PASS**

### المرحلة B — إرسال DirectSale

```text
status = Sent
movement_count = 1
custody_ledger = true
custody_value = 50
custodian_user_id = 111b0730-a977-4d11-bcd0-2427b178a9e5
```

المخزون أصبح:

```text
BR-01:            8 → 7
Vehicle mobile:   0 → 1
```

**PASS**

### المرحلة C — إنشاء DirectReturn

```text
status = Draft
custodian_user_id = 111b0730-a977-4d11-bcd0-2427b178a9e5
vehicle = CHV-2025-01
```

**PASS**

### المرحلة D — إرسال DirectReturn

```text
status = Sent
movement_count = 1
```

المخزون:

```text
BR-01:            7
Vehicle mobile:   1 → 0
```

**PASS**

### المرحلة E — استلام DirectReturn

بعد الإصلاح:

```text
status = Received
custody_ledger = true
custody_credit = 50
custodian_user_id = 111b0730-a977-4d11-bcd0-2427b178a9e5
```

المخزون:

```text
BR-01:            7 → 8
Vehicle mobile:   0
```

**PASS**

### المرحلة F — Duplicate Receive

تمت إعادة نفس عملية RECEIVE بنفس:

```text
operation_id = QA-REP-COL-DR-RECV-20261001
```

النتيجة:

```text
success   = true
duplicate = true
status    = Received
```

ولم تحدث حركة إضافية.

**PASS**

---

## 10. أثر الحركة على `inventory_log`

الاختبار أثبت وجود 3 حركات تشغيلية مترابطة داخل الـtransaction:

```text
1. DirectSale
   Branch → Mobile Vehicle Stock

2. DirectReturn SEND
   Mobile Vehicle Stock → InventoryDecrease

3. DirectReturn RECEIVE
   InventoryIncrease → Destination Branch
```

وهذا هو العقد الصحيح للـtwo-stage return في RAWAEA.

---

## 11. أثر العملية على عهدة المندوب

قبل الاختبار:

```text
driver_ledger rows = 0
balance = 0
```

بعد DirectSale SEND:

```text
Debit 50
```

بعد DirectReturn RECEIVE:

```text
Credit 50
```

النتيجة النهائية قبل rollback:

```text
rows_after = 2
balance_after = 0
```

أي أن دورة صرف 1 ثم مرتجع 1 أعادت عهدة المندوب إلى الصفر.

**PASS**

---

## 12. الأثر المحاسبي العام

تم قياس:

```text
journal_entries
journal_lines
```

قبل وبعد الاختبار.

النتيجة:

```text
journal_entries: 10 → 10
journal_lines:   16 → 16
```

أي أن DirectSale/DirectReturn الداخلي في هذا العقد لا ينشئ قيد دفتر أستاذ عام منفصلًا أثناء هذه الحركة.

هذا متسق مع مبدأ الحركة الداخلية للمخزون: تغيير موقع الملكية/الحيازة داخل المؤسسة لا يعني إنشاء إيراد أو تكلفة بيع تلقائيًا.

وقد ثبت ذلك أيضًا مقارنةً بالممارسات القياسية المنشورة:

- Odoo يفرّق بين الحركات الداخلية التي تغيّر الموقع ولا تغيّر ملكية المخزون، وبين الحركات الداخلة/الخارجة التي تؤثر في التقييم. https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/inventory_valuation/operations_valuation.html
- SAP يوضح أن النقل بين Storage Locations داخل نفس الموقع قد يتم دون إنشاء accounting document، بينما النقل بين valuation areas المختلفة قد ينشئ أثرًا محاسبيًا. https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/91b21005dded4984bcccf4a69ae1300c/a764bd534f22b44ce10000000a174cb4.html

**إذن عدم تغير journal هنا ليس نقصًا؛ بل هو نتيجة صحيحة لعقد الحركة الداخلية الحالية.**

الـ`driver_ledger` منفصل عن General Ledger وهو مسؤولية العهدة التشغيلية.

---

## 13. التحقق من سلامة Production بعد الاختبار

بسبب تنفيذ الاختبار داخل block مع rollback قسري:

```text
QA voucher rows = 0
QA inventory_log rows = 0
QA driver ledger rows = 0
```

والرصيد الفعلي للفرع رجع إلى:

```text
BR-01 item 1001
qty = 8
allocated_qty = 0
```

وبقيت فقط بنية Production الجديدة الخاصة بإصلاح الـRPC.

لم يتم حذف أو تعديل أي بيانات تشغيلية حقيقية.

---

## 14. تدقيق الجدول في main.html

### العيب

الـtable الحالي في `loadVouchers()` ليس ناقصًا في قاعدة البيانات؛ هو ناقص في read model فقط.

### الإصلاح الجراحي المطلوب

يتم تنفيذ **أربع substitutions فقط** داخل `loadVouchers()` و`_applyVouchers()`.

لا يتم استبدال أي دالة كاملة.

### PATCH 1 — تحميل قاموس المندوبين

ابحث عن **هذا السطر حرفيًا** داخل `async function loadVouchers()`:

```js
var r=await supabase.from('stock_vouchers').select('*').eq('company_id',companyId()).order('voucher_date',{ascending:false}).order('created_at',{ascending:false});if(r.error)throw r.error;window._vouchersData=r.data||[];_applyVouchers();
```

احذفه فقط واستبدله بهذا السطر:

```js
var voucherCompanyId=companyId();var r=await supabase.from('stock_vouchers').select('*').eq('company_id',voucherCompanyId).order('voucher_date',{ascending:false}).order('created_at',{ascending:false});if(r.error)throw r.error;var reps=await supabase.from('users').select('id,name,email').eq('company_id',voucherCompanyId).eq('status','Active').eq('role','مندوب بيع مباشر').order('name');if(reps.error)throw reps.error;window._vouchersRepMap=Object.create(null);(reps.data||[]).forEach(function(rep){window._vouchersRepMap[String(rep.id)]=rep.name||rep.email||'';});window._vouchersData=(r.data||[]).map(function(v){v._custodian_name=(v.custodian_user_id&&window._vouchersRepMap[String(v.custodian_user_id)])||'-';return v;});_applyVouchers();
```

### PATCH 2 — رأس الجدول

ابحث داخل `safeHTML(c,...)` في `loadVouchers()` عن الجزء الذي يبدأ بـ:

```html
<tr><th class="p-3">الرقم</th><th class="p-3">النوع</th><th class="p-3">التاريخ</th><th class="p-3">الحالة</th><th class="p-3">المرجع</th><th class="p-3">من</th><th class="p-3">إلى</th><th class="p-3">إجراءات</th></tr></thead><tbody id="vouchers-tbody"><tr><td colspan="8" class="text-center py-8">جاري التحميل...</td></tr>
```

احذفه فقط واستبدله بـ:

```html
<tr><th class="p-3">الرقم</th><th class="p-3">النوع</th><th class="p-3">التاريخ</th><th class="p-3">الحالة</th><th class="p-3">المرجع</th><th class="p-3">من</th><th class="p-3">إلى</th><th class="p-3">المندوب</th><th class="p-3">إجراءات</th></tr></thead><tbody id="vouchers-tbody"><tr><td colspan="9" class="text-center py-8">جاري التحميل...</td></tr>
```

### PATCH 3 — empty state

داخل `function _applyVouchers()` ابحث حرفيًا عن:

```js
if(!d.length){safeHTML(tb,'<tr><td colspan="8" class="text-center py-8">لا توجد أذونات</td></tr>');return;}
```

استبدله بـ:

```js
if(!d.length){safeHTML(tb,'<tr><td colspan="9" class="text-center py-8">لا توجد أذونات</td></tr>');return;}
```

### PATCH 4 — عمود المندوب في الصف

داخل `function _applyVouchers()` ابحث حرفيًا عن نهاية الصف:

```js
'<td class="p-3">'+esc(v.to_id||'-')+'</td><td class="p-3 text-center">'+acts+'</td></tr>'
```

استبدلها بـ:

```js
'<td class="p-3">'+esc(v.to_id||'-')+'</td><td class="p-3">'+esc(v._custodian_name||'-')+'</td><td class="p-3 text-center">'+acts+'</td></tr>'
```

### لا تعدّل أي شيء آخر في main.html

```text
لا حذف للدالة loadVouchers كاملة
لا حذف للدالة _applyVouchers كاملة
لا تعديل save/send/receive workflow
لا تعديل vouchers.html
لا تعديل navigation delegation
لا تعديل permission authority
```

---

## 15. لماذا لا نعدل `inventory_voucher_report` لهذا الإصلاح؟

لأن الجدول المضمّن الحالي في `main.html` لا يستخدم RPC التقرير؛ بل يستدعي:

```js
supabase.from('stock_vouchers').select('*')
```

كما أن Report362 الخاص بـ`inventory_voucher_report` تم التحقق من إصلاحه بالفعل عبر `GROUP BY v.type` و`GROUP BY v.status`.

إعادة تعديل RPC هنا ستكون تغييرًا خارج موضع الحاجة، ولذلك **لم يتم ذلك**.

---

## 16. التوافق مع النظام التشغيلي المنفصل

الـ`vouchers.html` الحالي في `erp-frontend` لا يعرض قائمة جدول كلاسيكية؛ الواجهة الحالية تعتمد على cards وتحتوي بالفعل على:

```text
custodian_user_id
rep lookup
vehicleRepMap
repVehicleMap
```

كما أن `filterList` يستخدم بيانات المندوب في البحث.

إذن المطلوب في `main.html` هو سد فجوة العرض في الـlegacy/embedded compatibility surface، وليس إعادة بناء التطبيق التشغيلي.

---

## 17. Benchmark مختصر مع الأنظمة المنافسة

### Odoo

تقارير Moves History تعرض التاريخ والمرجع والمنتج والمصدر والوجهة، ويوفر Dashboard تجميع التحويلات حسب المسؤول ونوع العملية. https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/reporting/moves_history.html

### Dynamics 365

Microsoft يفرض في عمليات النقل أبعاد From/To ويعالج أعمال المخزن تحت مستخدم/عامل warehouse، مع تتبع الحركة في inventory transactions. https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/tasks/transfer-physical-inventory-within-warehouse

كما يعرض Mobile warehouse flows باعتبار worker جزءًا من العملية. https://learn.microsoft.com/en-us/dynamics365/supply-chain/warehousing/configure-mobile-devices-warehouse

### SAP

SAP يميّز بين النقل أحادي الخطوة والنقل على مرحلتين، وفي الـtwo-step procedure يتم أولًا الخصم من موقع الإصدار ثم إدخال المخزون في الموقع المستلم. هذا قريب جدًا من منطق DirectReturn الميداني الحالي بعد تصحيح receive direction. https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/91b21005dded4984bcccf4a69ae1300c/ad64bd534f22b44ce10000000a174cb4.html

### Manager.io

Inventory Transfers تعرض Date / Reference / Item / Qty / From / To وتعدل كميات المواقع تلقائيًا. https://www2.manager.io/guides/10707

### دفترة

دليل دفترة الحالي يثبت وجود تحكم مستقل في المخازن، وصلاحيات إنشاء/تعديل/عرض الأذون المخزنية، إضافة إلى صلاحيات مستوى المستودعات والخزائن والحسابات، كما يذكر تتبع الحركات والتقارير، وهو يؤكد أهمية ربط الحركة بالمستخدم/النطاق وليس مجرد وجود زر. https://docs.daftra.com/tutorial/%D8%B6%D8%A8%D8%B7-%D9%88%D8%AA%D9%87%D9%8A%D8%A6%D8%A9-%D8%A5%D8%AF%D8%A7%D8%B1%D8%A9-%D8%A7%D9%84%D9%85%D9%88%D8%B8%D9%81%D9%8A%D9%86/

**الخلاصة benchmark:** الحقل المقترح ليس تجميليًا؛ هو read-model projection لفاعل العملية، ويعطي المحقق والمراقب نقطة ربط مباشرة بين الحركة والمندوب والعهدة.

---

## 18. حقول إضافية ذات قيمة حقيقية للتطوير اللاحق

لا تُضاف الآن إلى main.html لأنها خارج المطلوب الجراحي، لكن النظام الأم أو التقرير المركزي يمكن أن يضيف لاحقًا:

```text
المندوب
vehicle
branch source
branch destination
created_by
sent_by
received_by
status transition timestamps
custody value
operation_id
reference
exception/reversal status
```

والأولوية الرقابية الأعلى بعد إغلاق عمود المندوب:

```text
مندوب
   ↓
سيارة
   ↓
فرع المصدر
   ↓
فرع الاستلام
   ↓
الحركة
   ↓
عهدة المندوب
   ↓
inventory_log
   ↓
الرانشيت/الفواتير عند وجود الربط
```

---

## 19. اختبار المصدر للـpatch الجراحي

تم إنشاء نسخة patch مستقلة بدون تعديل المصدر الحقيقي، وتم اختبار الأجزاء الجديدة بـNode:

```text
PATCH_JS_SYNTAX = PASS
REP_MAPPING     = PASS
```

واختبار mapping أثبت:

```text
DirectSale  + custodian_user_id → اسم المندوب
DirectReturn + custodian_user_id → اسم المندوب
Voucher بدون custodian → '-'
```

كما تم التأكد أن الـpatch لا يغيّر أي writer مخزني أو Edge call.

---

## 20. Browser E2E status

يوجد Workflow خاص بـ`warehouse_vouchers` داخل مستودع `erp-frontend` يستخدم Playwright/Chromium ويغطي:

```text
syntax
core path
service worker path
login UI
console/page errors
```

لكن لا تتوفر في جلسة التنفيذ الحالية أداة dispatch للـGitHub Actions تسمح بتشغيل Workflow جديد يدويًا من هنا.

لذلك لا يُعلن هذا التقرير Browser E2E rendered PASS كدليل مستقل.

الـE2E الذي تم إغلاقه فعليًا هنا هو:

```text
Production DB contract E2E
+ transactional rollback
+ stock movement
+ voucher lifecycle
+ custody ledger
+ idempotency
+ general journal invariance
+ source syntax/mapping validation
```

أما إثبات الـbrowser-rendered deployment فيبقى Owner-side verification بعد تنفيذ الـpatch الجراحي في `main.html` ونشر النسخة.

---

## 21. ما لم يتم تغييره عمدًا

لمنع regression، لم يتم لمس:

```text
RW_Permissions_check
owner wildcard contract
license management
main navigation delegation
vouchers.html
inventory_voucher_report
stock_branches schema
stock_vouchers schema
vehicle assignment schema
send-stock-voucher
receive-stock-voucher
create-stock-voucher
post_stock_movement
DirectSale creation contract
DirectReturn assignment contract
```

إلا أن `post_manual_stock_voucher_atomic_core_20260828` عُدّل فقط في fragment الاتجاه المشار إليه في هذا التقرير لأن الاختبار أثبت أن العيب ما زال موجودًا في Production الحالية.

---

## 22. تعليمات جلسة التنفيذ التالية — لا تبدأ من الصفر

ابدأ بهذا الترتيب فقط:

```text
1. اقرأ CURRENT_STATE.md من آخر append.
2. أثبت CURRENT GIT HEAD والـparent.
3. أثبت SHA الحالي لـ Current/PWA/main.html.
4. افحص Production RPC post_manual_stock_voucher_atomic_core_20260828.
5. أثبت وجود DirectReturn → InventoryIncrease في RECEIVE.
6. لا تعيد إصلاحه إذا ثبت وجوده.
7. راجع Report382 كمرجع تاريخي، ثم ارجع إلى CURRENT SOURCE / PRODUCTION.
8. في main.html نفذ الأربع substitutions الجراحية المحددة فقط.
9. شغّل source syntax + mapping test.
10. بعد النشر نفذ browser-rendered E2E من Workflow المخصص.
11. تحقق من عمود المندوب في DirectSale وDirectReturn.
12. تحقق أن Transfer/SupplierReturn يظهران '-'.
13. تحقق أن refresh لا يفقد lookup.
14. تحقق أن عدم وجود مندوب لا يكسر القائمة.
15. لا تعدل writer أو workflow نتيجة لنجاح العرض.
```

### قاعدة استمرارية

```text
CURRENT GIT
    > historical report
CURRENT SOURCE
    > historical report
CURRENT PRODUCTION
    > assumption
CURRENT DATABASE
    > expectation
CURRENT DEPLOYMENT EVIDENCE
    > theoretical browser claim
```

أي جلسة لاحقة لا تعيد اختبار أو إصلاح العيوب المغلقة أعلاه إلا إذا ظهر دليل جديد في المصدر/Production/Deployment يناقض الإغلاق.

---

# SELF AUDIT

### هل تم تعديل main.html؟

```text
لا.
```

المصدر بقي على SHA:

```text
27b777528665dcc985809648f006452c861ae36e
```

### هل تم إنشاء Edge Function جديدة؟

```text
لا.
```

### هل تم تجاوز سقف Edge Functions؟

```text
نعم، تم العمل عبر الـRPC الحالي.
```

### هل تم اختبار المخزون فعليًا؟

```text
نعم — transactional E2E داخل Production مع rollback.
```

### هل تم اختبار عهدة المندوب؟

```text
نعم — Debit 50 ثم Credit 50 ثم balance = 0.
```

### هل تم اختبار دفتر الأستاذ العام؟

```text
نعم — entries 10→10 وlines 16→16.
```

### هل تم اختبار idempotency؟

```text
نعم — duplicate RECEIVE returned duplicate=true without extra movement.
```

### هل بقيت بيانات الاختبار في Production؟

```text
لا — rollback ثم post-check = 0 QA rows.
```

### هل تم الادعاء بوجود Browser E2E بعد النشر؟

```text
لا.
```

### هل يمكن أن يعود عيب DirectReturn RECEIVE؟

تم تسجيل migration canonical لمنع عودته بصمت، مع drift guard.

---

# END OF REPORT 382
