# تقرير 383 — التحقيق الجنائي والتعديل الجراحي لعمود مندوب صرف/مرتجع السيارة
## RAWAEA ERP — Current/PWA/main.html
**التاريخ:** 2026-10-01
**وحدة الإغلاق:** النظام الأم → الأذونات المخزنية → الجدول المضمّن → DirectSale / DirectReturn → إسقاط هوية المندوب

---

# 1. نقطة البداية المعتمدة

تم استرجاع الحالة من:
- MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP
- CURRENT_STATE.md حتى EOF
- آخر Current Git وParent
- Current/PWA/main.html
- Production Supabase
- Current Production migration الخاصة بـDirectReturn Receive
- مصدر تطبيق الأذونات الحالي في erp-frontend
- السجل التاريخي Report382 وReport381 كمصادر إرشاد لا كمصدر حالة

## Current Git

System HEAD عند بداية هذه الدورة:
`59fd766167bbdb3b9bd9af3d305da7b0eb52da64`

Parent:
`0be2f6f54e4748e231cc62a6a1943e93257f6a14`

والـdiff بين baseline Report382 والـHEAD الحالي أثبت أن تغييرات الحالة الأخيرة لم تلمس:
`Current/PWA/main.html`

## Current Mother Source

Path:
`Current/PWA/main.html`

Current blob:
`27b777528665dcc985809648f006452c861ae36e`

الحجم:
5410 سطرًا.

EOF verified.

---

# 2. الحقيقة الحالية للنظام الأم

النظام الأم ما زال يعرّف الأذونات المخزنية كتطبيق متخصص delegated application:

`vouchers → ./vouchers.html`

وتظهر هذه الحقيقة في:
- `window.MAIN_HTML_CURRENT_CONTRACT_LEDGER`
- `main1Delegation()`
- `RW_ParentRegistry.apps.vouchers`

إذن الجدول المضمّن داخل main.html ليس المصدر التشغيلي الأساسي لدورة الأذونات؛ هو read-model / compatibility view داخل النظام الأم.

هذا مهم لأن المطلوب الحالي عرض هوية المندوب فقط دون إعادة بناء دورة الأذونات.

---

# 3. السبب الجذري المثبت

## الملف

`Current/PWA/main.html`

## العنصر

`loadVouchers()`

الموضع:
حوالي السطر 2922–2925.

## الخلل

التحميل الحالي كان:

`stock_vouchers.select('*')`

ثم:

`_applyVouchers()`

فقط.

لا توجد طبقة إسقاط لحقـل:

`stock_vouchers.custodian_user_id`

إلى اسم مستخدم.

## العنصر الثاني

`_applyVouchers()`

الموضع:
حوالي السطر 2927–2931.

الجدول الحالي يحتوي:

- الرقم
- النوع
- التاريخ
- الحالة
- المرجع
- من
- إلى
- إجراءات

ولا يحتوي عمود المندوب.

والصف الحالي يطبع:
`v.to_id`
ثم ينتقل مباشرة إلى:
`acts`

وبالتالي فإن هوية المندوب الموجودة في:

`custodian_user_id`

موجودة في قاعدة البيانات، لكنها لا تظهر في هذا read-model.

---

# 4. مصدر هوية المندوب — Production

العقد الصحيح المثبت هو:

`stock_vouchers.custodian_user_id`

→

`public.users.id`

→

`public.users.name / email`

وقد ثبت من Production أن:

- `stock_vouchers.custodian_user_id` له Foreign Key مباشر إلى `public.users(id)`.
- علاقة Vehicle ↔ Direct Sales Rep التشغيلية الحديثة هي `fleet_vehicle_sales_rep_assignments`.
- `vehicles.driver_id` ليس مصدر الهوية الصحيح للمندوب في هذا السياق.
- DirectSale / DirectReturn يحفظان هوية المندوب في voucher custody context.

هذا الفصل صحيح معماريًا:

`Master Assignment`
=
من تربطه السيارة بالمندوب حاليًا.

بينما:

`custodian_user_id`
=
من كانت عليه العهدة في المستند نفسه.

وبالتالي جدول الأذونات يجب أن يعرض `custodian_user_id` الموثق في المستند، لا أن يعيد اشتقاق اسم المندوب من `driver_id`.

---

# 5. Production الحالي

## Supabase

Project:
`SMART ERP`

Ref:
`fiilmooggumokxanwiyx`

Status:
ACTIVE_HEALTHY

PostgreSQL:
17.6.1.121

## DirectReturn Receive

المصدر الإنتاجي الحالي يثبت:

`DirectReturn SEND`
→
`InventoryDecrease`

من مخزون المركبة.

ثم:

`DirectReturn RECEIVE`
→
`InventoryIncrease`

إلى الفرع.

هذه الجراحة الحالية لا تغيّر هذا العقد ولا تلمسه.

Migration الحاكم:

`supabase/migrations/20261001090000_fix_directreturn_receive_stock_direction_contract.sql`

ومصدر Production الحالي يحتوي:

`WHEN 'DirectReturn' THEN 'InventoryIncrease'`

وبالتالي لا توجد حاجة إلى Production change جديد بسبب عمود المندوب.

---

# 6. لماذا لا نضيف Edge Function أو RPC

التعديل المطلوب:

- قراءة فقط.
- لا ينشئ مستندًا.
- لا يغير حالة voucher.
- لا يغير المخزون.
- لا يغير العهدة.
- لا يغير الحسابات.
- لا يغير Treasury.
- لا يغير workflow.

إضافة Edge/RPC ستكون بنية زائدة ومخالفة لقاعدة المشروع الحالية.

لا يوجد Production infrastructure change في هذه الوحدة.

---

# 7. العناصر المعيبة — بالحذف والاستبدال الحرفي

## PATCH 1 — تحميل هوية المندوب

### الملف

`Current/PWA/main.html`

### الدالة

`loadVouchers()`

### الموضع

حوالي السطر 2925.

### ابحث تحديدًا عن هذا العنصر كاملًا

```
var r=await supabase.from('stock_vouchers').select('*').eq('company_id',companyId()).order('voucher_date',{ascending:false}).order('created_at',{ascending:false});if(r.error)throw r.error;window._vouchersData=r.data||[];_applyVouchers();
```

### احذفه بالكامل واستبدله بهذا العنصر كاملًا

```
var voucherCompanyId=companyId();var r=await supabase.from('stock_vouchers').select('*').eq('company_id',voucherCompanyId).order('voucher_date',{ascending:false}).order('created_at',{ascending:false});if(r.error)throw r.error;var reps=await supabase.from('users').select('id,name,email').eq('company_id',voucherCompanyId).eq('status','Active').eq('role','مندوب بيع مباشر').order('name');if(reps.error)throw reps.error;window._vouchersRepMap=Object.create(null);(reps.data||[]).forEach(function(rep){window._vouchersRepMap[String(rep.id)]=rep.name||rep.email||'';});window._vouchersData=(r.data||[]).map(function(v){v._custodian_name=(v.custodian_user_id&&window._vouchersRepMap[String(v.custodian_user_id)])||'-';return v;});_applyVouchers();
```

### سبب الاختيار

الاستعلام مقيد بالشركة الحالية.

واستخراج المندوبين مقيد بالحالة والتصنيف الحاليين للمندوبين، وهو متسق مع RLS الحالي في Production الخاص بقراءة مندوبي البيع المباشر للمخازن.

---

# 8. PATCH 2 — إضافة عنوان العمود

### الدالة

`loadVouchers()`

### الموضع

حوالي السطر 2924.

### ابحث تحديدًا عن:

```
<th class="p-3">إلى</th><th class="p-3">إجراءات</th></tr></thead><tbody id="vouchers-tbody"><tr><td colspan="8" class="text-center py-8">جاري التحميل...</td></tr>
```

### احذف هذا العنصر واستبدله بالكامل بـ:

```
<th class="p-3">إلى</th><th class="p-3">المندوب</th><th class="p-3">إجراءات</th></tr></thead><tbody id="vouchers-tbody"><tr><td colspan="9" class="text-center py-8">جاري التحميل...</td></tr>
```

---

# 9. PATCH 3 — تصحيح حالة القائمة الفارغة

### الدالة

`_applyVouchers()`

### الموضع

حوالي السطر 2930.

### ابحث تحديدًا عن:

```
if(!d.length){safeHTML(tb,'<tr><td colspan="8" class="text-center py-8">لا توجد أذونات</td></tr>');return;}
```

### احذفه بالكامل واستبدله بـ:

```
if(!d.length){safeHTML(tb,'<tr><td colspan="9" class="text-center py-8">لا توجد أذونات</td></tr>');return;}
```

---

# 10. PATCH 4 — عرض المندوب في الصف

### الدالة

`_applyVouchers()`

### الموضع

داخل:

`d.forEach(function(v){...})`

### ابحث تحديدًا عن هذا العنصر:

```
<td class="p-3">'+esc(v.to_id||'-')+'</td><td class="p-3 text-center">'+acts+'</td></tr>
```

### احذفه بالكامل واستبدله بهذا العنصر كاملًا:

```
<td class="p-3">'+esc(v.to_id||'-')+'</td><td class="p-3">'+esc(v._custodian_name||'-')+'</td><td class="p-3 text-center">'+acts+'</td></tr>
```

---

# 11. لماذا هذه أربع جراحات وليست إعادة كتابة للدالة

لا يتم استبدال:
- `loadVouchers()` كاملة.
- `_applyVouchers()` كاملة.
- `_viewVoucherDetails()`.
- `_saveAndSendVoucher()`.
- `_addVoucherItem()`.
- أي وظيفة أخرى.

التغيير محدود في:
1. مصدر read-model للمندوب.
2. header.
3. empty-state colspan.
4. row projection.

ولا يوجد أي تعديل على lifecycle.

---

# 12. التحقق الجراحي قبل الدمج

تم جلب Current Source الفعلي واختبار الاستبدالات على نسخة In-Memory فقط.

نتيجة عدد التطابقات:

| العنصر | العدد المتوقع | النتيجة |
|---|---:|---:|
| PATCH 1 anchor | 1 | PASS |
| PATCH 2 anchor | 1 | PASS |
| PATCH 3 anchor | 1 | PASS |
| PATCH 4 anchor | 1 | PASS |

كل عنصر ظهر مرة واحدة فقط.

لا يوجد خطر استبدال كتلة مكررة.

---

# 13. Syntax Gate

تم تطبيق الجراحات الأربع على نسخة In-Memory من:

`main.html`

ثم تم استخراج الـinline script وتشغيل:

`new Function(script)`

النتيجة:

**PASS**

عدد inline scripts:
1

Parse errors:
0

هذا الاختبار لا يعدل الملف الحقيقي.

---

# 14. Semantic Read-Model Test

تمت محاكاة الحالات الفعلية التالية باستخدام current Production user identity:

### DirectSale

`custodian_user_id`
=
`111b0730-a977-4d11-bcd0-2427b178a9e5`

النتيجة المتوقعة:
`مندوب مبيعات بيع مباشر`

النتيجة:
**PASS**

### DirectReturn

نفس الـcustodian.

النتيجة:
**PASS**

### Transfer

لا custodian.

النتيجة:
`-`

**PASS**

### SupplierReturn

لا custodian.

النتيجة:
`-`

**PASS**

وبالتالي لا يتم إظهار مندوب بشكل مصطنع في أنواع لا تخص صرف/مرتجع السيارة.

---

# 15. Production Schema Verification

تم التحقق أن:

`stock_vouchers.custodian_user_id`

يرتبط مباشرة بـ:

`users.id`

Foreign Key:
`stock_vouchers_custodian_user_fk`

وبذلك لا توجد حاجة إلى:
- جدول جديد.
- relation جديد.
- cache جديد.
- RPC جديد.
- Edge Function جديد.

المطلوب هو إسقاط هذا المفتاح في الـUI فقط.

---

# 16. Production Representative Verification

Production الحالي يحتوي على مندوبي البيع المباشر النشطين، ومن ضمنهم:

- `vansales@rawaea.com`
- `vansales2@rawaea.com`
- `van-sales2@rawaea.com`

والـMaster Assignment الحالي للمركبات محل التحقيق ما زال:
- CHV-2025-01 → vansales@rawaea.com
- VHL-0422 → vansales2@rawaea.com

ولا تعتمد الجراحة على `vehicles.driver_id`.

---

# 17. Workflow / DB / Accounting Impact

## قبل الجراحة

دورة المستند:

DirectSale / DirectReturn
→ stock_vouchers
→ custodian_user_id
→ stock/core workflow

## بعد الجراحة

نفس الدورة تمامًا.

الفرق الوحيد:

`custodian_user_id`

أصبح ظاهرًا في الجدول.

### لا يوجد:

- INSERT.
- UPDATE.
- DELETE.
- status transition.
- stock movement.
- treasury movement.
- ledger posting.

إذن:

**Accounting Impact = ZERO**

**Treasury Impact = ZERO**

**Stock Impact = ZERO**

**Workflow Impact = ZERO**

**Audit impact = ZERO**

**Data mutation = ZERO**

---

# 18. E2E والتحقق الإنتاجي

تمت مراجعة الـE2E الإنتاجي الحديث السابق في Report382 ومطابقته مع Production الحالي.

الاختبار الإنتاجي السابق القابل للـrollback أثبت:

DirectSale:
CREATE → SEND
→ Branch stock 8→7
→ Mobile stock 0→1
→ custody debit 50

DirectReturn:
CREATE → SEND
→ Mobile stock 1→0
→ Branch يبقى 7

DirectReturn:
RECEIVE
→ Branch 7→8
→ Mobile يبقى 0
→ custody credit 50

Duplicate RECEIVE بنفس operation_id:
→ duplicate=true
→ بلا movement إضافي.

كما أثبت الاختبار:
- Journal unchanged.
- Customer ledger unchanged.
- Supplier ledger unchanged.
- Treasury unchanged.
- Driver/custody ledger عاد إلى الصفر بعد debit/credit.
- Inventory logs بعد الـrollback لم تترك residue.

## Current evidence reconciliation

تمت إعادة مطابقة Production الحالي مع نفس الـRPC/Core المستخدم في ذلك الاختبار.

Current Production ما زال يحتوي:

`DirectReturn RECEIVE → InventoryIncrease`

ولا يوجد تغيير أحدث يبدل هذا العقد.

بالتالي لا توجد حاجة لإعادة تنفيذ حركة مالية/مخزنية إنتاجية فقط لإثبات read-only patch.

---

# 19. محاولة إنشاء Fixture إنتاجي جديد في هذه الدورة

تم إعداد Transactional E2E جديد كامل للتأكد من:
- DirectSale CREATE/SEND.
- DirectReturn CREATE/SEND.
- DirectReturn RECEIVE.
- duplicate receive.
- stock before/after.
- journal.
- customer ledger.
- supplier ledger.
- driver ledger.
- treasury.

لكن طبقة أمان تنفيذ SQL رفضت تشغيل طلب mutation المركب قبل التنفيذ.

لم يتم تجاوز هذا الحاجز.
لم يتم ترك أي fixture جزئي.
لم يتم ترك أي QA residue.

تم الاكتفاء بسلسلة الأدلة الإنتاجية القائمة والمطابَقة مع Current Production.

هذه النقطة لا تعتبر PASS جديدة كاختبار mutation في هذه الدورة؛ PASS الموثق هو الاختبار الإنتاجي السابق القابل للـrollback الذي ما زال عقده الإنتاجي الحالي مطابقًا.

---

# 20. E2E Browser

لا يوجد Browser-rendered E2E للـmain.html بعد الجراحة لأن:
- main.html لم يتم تعديلها في Git.
- لم يتم نشر نسخة جديدة.
- تشغيل workflow متاح للـGET/read لكن لا توجد أداة dispatch لهذا الـworkflow من هذه الجلسة.

لذلك:

**Browser E2E = OPEN**

ولا يتم تزوير الإغلاق.

---

# 21. لماذا لا يتم تعديل Production الآن

كل Production responsibility الضرورية لهذه النقطة موجودة بالفعل:

- custodian_user_id
- users FK
- DirectSale custody
- DirectReturn custody
- Master Assignment
- central stock movement
- DirectReturn Receive correction
- idempotency

أي تعديل جديد في Production الآن سيكون إعادة بناء لما هو مثبت بالفعل.

---

# 22. التكامل مع النظام الأم والتطبيقات المنفصلة

## النظام الأم

يملك:
- company context
- permission context
- application delegation
- stock voucher navigation/read-model

## vouchers.html

يملك:
- Create
- Edit
- Send
- Receive
- DirectSale
- DirectReturn
- SupplierReturn
- Transfer
- stock-voucher workflow

## Van Sales

يمتلك:
- mobile stock
- direct sales
- customer collection
- inventory count
- settlement

ولا يتم نقل أي مسؤولية من هذه التطبيقات.

الجراحة الحالية تجعل النظام الأم قادرًا على رؤية:

`Voucher → Custodian Rep`

دون تكرار workflow التنفيذي.

---

# 23. الدراسة التاريخية لعقد العمليات

## DirectSale

الغاية:
إخراج بضائع من فرع إلى مخزن مركبة/مندوب كعهدة متنقلة.

الهوية التشغيلية الحديثة:

`Master Assignment`

والهوية التاريخية للمستند:

`custodian_user_id`

## DirectReturn

الغاية:
إرجاع البضاعة من مخزون المركبة إلى الفرع.

وليس:
- Sales Return.
- Order Return.
- Runsheet Return.

أي محاولة اشتقاق المندوب من `driver_id` كانت ستربط العملية بهوية السائق بدل صاحب العهدة.

الجراحة الحالية لا تقع في هذا الخطأ.

---

# 24. Benchmark تنافسي

الدراسة الحديثة للأنظمة المنافسة تؤكد اتجاهًا واحدًا:

## Odoo

Moves History يسجل:
- Date
- Reference
- Product
- Lot/Serial
- From
- To

وهو read-model مخصص لتتبع الحركة ومراجعة الفروق.

المصدر:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/reporting/moves_history.html

## Microsoft Dynamics 365

Transfer journal يستخدم From/To dimensions، وتوجد رؤية مستقلة لـinventory transactions، مع فصل واضح بين التشغيل والتتبع.

المصدر:
https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/tasks/transfer-physical-inventory-within-warehouse

كما تدعم Dynamics transaction views المخصصة للمخزن.

## SAP

Two-Step Transfer:
- إزالة من المصدر.
- المخزون ينتقل إلى حالة transfer.
- الاستلام يضيفه إلى المخزون المتاح في الوجهة.

وفي النقل بين storage locations داخل نفس plant لا يلزم عادةً Accounting Document لحركة المادة نفسها.

المصادر:
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/91b21005dded4984bcccf4a69ae1300c/ad64bd534f22b44ce10000000a174cb4.html
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/9905622a5c1f49ba84e9076fc83a9c2c/a764bd534f106b44ce10000000a174cb4.html

## Daftra

يوثق:
- From Warehouse
- To Warehouse
- Notes
- Quantity
- Available Before
- Available After

كما يدعم ربط مسؤولية المخزون بالموظف وتقارير حركة الموظف/مخزنه.

المصادر:
https://docs.daftra.com/en/tutorial/transferring-stock/
https://docs.daftra.com/en/user_manual/how-to-assign-inventory-to-an-employee/
https://docs.daftra.com/en/tutorial/inventory-detailed-transactions-report/

## الاستنتاج المناسب لـRAWAEA

عمود المندوب هو تحسين Auditability حقيقي وليس زينة UI.

لكن لا يتم إدخال:
- Stock Before/After
- Barcode
- Attachments
- Approval metadata
- Reason analytics
- SLA
- advanced exception queue

في هذه الجراحة لأنها نقاط Business Capability مستقلة.

---

# 25. الفجوات التنافسية التي تم رصدها ولم تُلمس

تظل كـBacklog مستقل:

1. Stock Before / Stock After
2. Barcode-first stock operation
3. Attachments / evidence
4. Reason analytics
5. Exception queue
6. Rich audit timeline
7. Transit visibility
8. Lot/Serial/Expiry عند تفعيل tracking
9. Approval visualization

لا يجوز خلطها مع مشكلة عمود المندوب.

---

# 26. Owner Change Set

## المطلوب من المالك

ملف واحد:

`Current/PWA/main.html`

أربع استبدالات فقط:

- PATCH 1
- PATCH 2
- PATCH 3
- PATCH 4

## لا يتم تعديل:

- vouchers.html
- van-sales.html
- أي Edge Function
- أي RPC
- أي table
- أي RLS
- أي workflow

---

# 27. التحقق بعد دمج المالك

بعد تطبيق الجراحات:

### Gate 1
Syntax PASS

### Gate 2
Load Voucher List

### Gate 3
DirectSale row:
المندوب يظهر من `custodian_user_id`

### Gate 4
DirectReturn row:
المندوب يظهر من `custodian_user_id`

### Gate 5
Transfer / SupplierReturn:
المندوب = `-`

### Gate 6
Empty state:
colspan = 9

### Gate 7
Refresh:
mapping يبقى صحيحًا.

### Gate 8
Browser E2E:
لا يوجد تغيير في Create/Send/Receive.

### Gate 9
Production read verification:
company scope
+
FK identity
+
custodian name

---

# 28. SELF-AUDIT

## What I Proved
- Current Git baseline.
- Current mother source.
- Current Production DirectReturn Receive contract.
- Current stock voucher → users FK.
- Current representative identities.
- Main delegation contract.
- Exact four current defective UI elements.
- Unique replacement anchors.
- Patched-source syntax.
- Semantic representative mapping.
- Zero accounting/stock/workflow mutation from the patch.

## What I Did Not Prove
- Browser-rendered main.html after owner merge/publish.
- Fresh production mutation E2E in this cycle بسبب execution safety gate.

## What I Did Not Change
- main.html
- vouchers.html
- van-sales.html
- RPC
- Edge Functions
- Tables
- RLS
- Stock/Accounting workflow

## Initial failure during execution
Transactional mutation E2E المركب رفضته طبقة أمان التنفيذ.
لم تتم إعادة المحاولة ولم يترك أثرًا.

## Current Closure

`ROOT CAUSE = PROVEN`

`PRODUCTION CONTRACT = VERIFIED`

`OWNER SURGICAL PATCH = READY`

`STATIC SYNTAX = PASS`

`SEMANTIC MAPPING = PASS`

`BROWSER E2E = OPEN`

`DEPLOYMENT VERIFICATION = OPEN`

---

# 29. نقطة الاستكمال الدقيقة للجلسة التالية

1. افتح:
`Current/PWA/main.html`

2. ابحث عن:
`var r=await supabase.from('stock_vouchers').select('*').eq('company_id',companyId()).order('voucher_date',{ascending:false}).order('created_at',{ascending:false});if(r.error)throw r.error;window._vouchersData=r.data||[];_applyVouchers();`

3. احذف العنصر كاملًا.
4. ضع PATCH 1 كاملًا.
5. نفذ PATCH 2 وPATCH 3 وPATCH 4 فقط.
6. شغّل Syntax Gate.
7. سجّل Commit جديد.
8. انشر main.html.
9. شغّل Browser E2E.
10. اختبر DirectSale وDirectReturn.
11. تحقق أن Transfer/SupplierReturn يعرضان `-`.
12. تحقق من refresh وempty state.
13. فقط بعد ذلك أغلق UI projection closure.

---

# 30. الحكم النهائي

هذه الوحدة ليست Backend defect.

وليست Stock defect.

وليست Accounting defect.

وليست Vehicle Assignment defect.

هي:

**Mother UI Read-Model Projection Gap**

والإصلاح الجراحي الصحيح هو:

**إسقاط custodian_user_id إلى اسم المندوب + إضافة العمود + تصحيح colspan فقط.**

لا حاجة إلى أي إعادة بناء أو Function أو RPC أو Table.

---

# END — REPORT 383
