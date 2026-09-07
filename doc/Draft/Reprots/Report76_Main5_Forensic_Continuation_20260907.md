# Report76 — الاستمرار الجنائي من main4 إلى main5

التاريخ: 2026-09-07
المستودع: `papamohammed77-glitch/rawaie-erp-New`
الفرع: `main`
Production: `SMART ERP / fiilmooggumokxanwiyx`

## 1. نقطة الاستمرار

تم استكمال العمل من الحالة المثبتة في CURRENT_STATE وReport75، وليس من الصفر.
تمت قراءة `MASTER - RAWAEA ERP.md` حتى النهاية، ومراجعة CURRENT_STATE وReport75، ثم إعادة التحقق من Git الحالي وProduction الحالية.

## 2. Current Git Reality

Git HEAD الحالي وقت التحقق:

```text
cbc30625ee1dea5dbc493e246f1e2cbc609f7e30
```

الـcommit الحالي يخص إصلاح `main4.md` ويحتوي كتلة M4-01 المصححة.

`main4.md` الحالي:

```text
PATH = Current/PWA/main2/main4.md
CURRENT BLOB = e89d29e4164c68784c109292f27d4d77df240557
```

وهذا أحدث من SHA/blob المذكورين في Report75/CURRENT_STATE السابقين.

## 3. Main4 Recheck

تمت إعادة قراءة أجزاء main4 الحالية التي تغطي RW_POS وRW_Roles وRW_TeleSales حتى الإغلاق.

النتيجة:

```text
M4-02 = موجود ومغلق مصدرًا
_saveOrder definitions = 1
legacy duplicate _saveOrder = غير موجود
M4-01 corrected try/catch = موجود
```

كتلة M4-01 الحالية تبدأ بـ `try {` بعد `var token = ...` وتنتهي بـ `} catch(e) { ... }` قبل `if (isEdit) {`.

الاستنتاج:

```text
MAIN4 SOURCE = CLOSED / STRUCTURALLY CORRECT ON CURRENT SOURCE
MAIN4 RUNTIME = NOT VERIFIED
11-PART INTEGRATION = NOT VERIFIED
```

لا يوجد تعديل جديد مطلوب للمستخدم على main4 في هذه الجلسة.

## 4. Production Reconciliation — 2026-09-07 10:12 UTC

تمت مطابقة Production مباشرة:

```text
companies      = 1
app_settings   = 1
users          = 24
roles          = 20
customers      = 3
suppliers      = 1
branches       = 2
items          = 17
orders         = 0
runsheets      = 0
stock_rows     = 20
inventory_logs = 3
```

RLS الحالي المثبت:

```text
orders = SELECT policy only; no authenticated UPDATE/DELETE policy
runsheets = SELECT/INSERT/UPDATE/DELETE policies with current-company checks
order_details = SELECT current-tenant policy
run_sheet_details = SELECT current-tenant policy
users = company-aware policies
vehicles = company-aware SELECT policy
app_settings = company-aware policies
```

## 5. Main5 Current Blob

```text
PATH = Current/PWA/main2/main5.md
CURRENT BLOB = caffc0187b54444e96491dc6f00a238b2e870b32
```

`main5.md` تمت مراجعته من بدايته وحتى EOF عبر القراءة المتسلسلة للنطاقات الحالية.

## 6. Main5 Findings

### M5-01 — Orders company scope missing

في `RW_Orders.render` يوجد:

```javascript
var ordRes = await supabase.from('orders').select('*, runsheets(runsheet_code)');
```

وهذا يجب أن يكون company-scoped.

### M5-02 — order_details query should follow loaded order IDs

الاستعلام الحالي:

```javascript
var detRes = await supabase.from('order_details').select('order_id, item_code');
```

لا يحتوي على `company_id` في الـschema، لذلك لا نضيف عمودًا غير موجود. يتم تقييده بمجموعة `ordersData[].id` الحالية.

### M5-03 — Realtime orders subscription unfiltered

القناة الحالية:

```javascript
.on('postgres_changes', { event: 'UPDATE', schema: 'public', table: 'orders' }, ...)
```

يجب إضافة `filter: 'company_id=eq.' + companyId`.

### M5-04 — `_showDetails` order lookup unscoped

الاستعلام الحالي:

```javascript
supabase.from('orders').select('*').eq('order_code', code).maybeSingle()
```

يجب إضافة `.eq('company_id', _rwCompanyId())`.

### M5-05 — `_printOrder` uses global app_settings LIMIT 1

الاستعلام الحالي:

```javascript
supabase.from('app_settings').select('*').limit(1).single();
```

هذا مخالف لعقد Tenant Context ويجب جعله company-scoped.

### M5-06 — `_createRS` contains an unauthorized/redundant direct order update

المقطع الحالي:

```javascript
await supabase
    .from('orders')
    .update({ runsheet_id: null, order_status: 'Confirmed' })
    .in('order_code', selected);
```

Production تثبت أن `orders` لا تملك للمستخدم المصادق سياسة UPDATE؛ وبالتالي هذا المسار ليس owner صحيحًا، ويجب حذفه بالكامل. إنشاء وربط الرانشيت يجب أن يبقى عبر capability `create-runsheet`.

### M5-07 — `_appendRS` runsheet lookup unscoped

الاستعلام الحالي:

```javascript
supabase.from('runsheets').select('runsheet_code, status').in('status', ['Open', 'Confirmed']);
```

يجب إضافة company scope.

وكذلك lookup الهدف الحالي:

```javascript
supabase.from('runsheets').select('id').eq('runsheet_code', v.value).maybeSingle();
```

يجب إضافة company scope.

### M5-08 — `_loadRunsheetCodes` unscoped

الاستعلام الحالي:

```javascript
supabase.from('runsheets').select('id, runsheet_code')
```

يجب إضافة company scope.

### M5-09 — `_refreshData` orders/runsheets relation unscoped

الاستعلام الحالي:

```javascript
var ordRes = await supabase.from('orders').select('*, runsheets(runsheet_code)');
```

يجب إضافة company scope.

`order_details` بعد ذلك يجب تقييده بـorder IDs المحملة حاليًا بدل جلب تفاصيل عامة.

### M5-10 — Runsheets helper queries are unscoped

الموجود:

```javascript
supabase.from('users').select('email, name').in('role', ['driver','سائق','مندوب']);
supabase.from('vehicles').select('id, license_plate, model');
```

يجب إضافة `.eq('company_id', _rwCompanyId())` لكليهما.

### M5-11 — Runsheets main list unscoped

الموجود:

```javascript
supabase.from('runsheets').select('*').order('run_date', { ascending: false });
```

يجب إضافة company scope.

### M5-12 — `_details` runsheet/orders lookups unscoped

يجب إضافة Company Scope إلى:

```javascript
supabase.from('runsheets').select('*').eq('runsheet_code', code).maybeSingle()
```

و:

```javascript
supabase.from('orders').select('order_code, customer_name, total_amount').eq('runsheet_id', rs.id)
```

وترك `run_sheet_details` مع `runsheet_id` بعد إثبات Tenant عبر الأب `runsheets`.

### M5-13 — Runsheet deletion path is not an authorized atomic owner

`_deleteRunsheet` ينفذ ثلاث عمليات منفصلة من الـFrontend:

```javascript
await supabase.from('orders').update(...)
await supabase.from('run_sheet_details').delete().eq('runsheet_id', rsId)
await supabase.from('runsheets').delete().eq('id', rsId)
```

ولا توجد Production capability حالية باسم `delete-runsheet` أو RPC مماثل ثبت أنها owner لهذا العقد.

لذلك **لا يتم اختراع Backend جديد داخل هذه الوحدة**. يظل هذا `OPEN CONTRACT` حتى يُعاد بناء contract الحذف من المصدر التاريخي/الـbusiness owner.

## 7. Syntax / Structure Assessment

لا يوجد في القراءة الحالية عيب تركيب واضح يوازي M4-01 داخل main5.
أهم إغلاقات الدوال الظاهرة صحيحة:

```text
RW_Orders = function scope closes with })();
RW_Runsheets = function scope closes with })();
async _details = try/catch properly closed
preConfirm callback closed
_deleteRunsheet callback closed
_cancelRunsheet callback closed
_printManifest closed
```

لكن Source Syntax correctness لا يساوي Runtime/E2E closure.

## 8. Exact Surgical Patch — Main5

### PATCH M5-01

ابحث عن السطر كاملًا:

```javascript
var ordRes = await supabase.from('orders').select('*, runsheets(runsheet_code)');
```

استبدله بالسطر:

```javascript
var companyId = _rwCompanyId();
if (!companyId) { hideLoader(); showToast('سياق الشركة غير محدد', 'error'); return; }
var ordRes = await supabase.from('orders').select('*, runsheets(runsheet_code)').eq('company_id', companyId);
```

### PATCH M5-02

ابحث عن:

```javascript
var detRes = await supabase.from('order_details').select('order_id, item_code');
```

استبدله بـ:

```javascript
var orderIds = ordersData.map(function(o) { return o.id; }).filter(Boolean);
var detRes = orderIds.length
    ? await supabase.from('order_details').select('order_id, item_code').in('order_id', orderIds)
    : { data: [] };
```

### PATCH M5-03

ابحث عن المقطع الكامل الذي يبدأ بـ:

```javascript
var channel = supabase
    .channel('orders-realtime')
```

وينتهي مباشرة عند:

```javascript
    .subscribe();
```

استبدل فقط تعريف `.on(...)` بالمقطع:

```javascript
    .on('postgres_changes', {
        event: 'UPDATE',
        schema: 'public',
        table: 'orders',
        filter: 'company_id=eq.' + companyId
    }, function(payload) {
```

واترك callback وبقية السلسلة كما هي.

### PATCH M5-04

ابحث عن السطر:

```javascript
supabase.from('orders').select('*').eq('order_code', code).maybeSingle()
```

واستبدله بـ:

```javascript
supabase.from('orders').select('*').eq('company_id', _rwCompanyId()).eq('order_code', code).maybeSingle()
```

### PATCH M5-05

ابحث عن السطر كاملًا:

```javascript
return supabase.from('app_settings').select('*').limit(1).single();
```

استبدله بـ:

```javascript
return supabase.from('app_settings').select('*').eq('company_id', _rwCompanyId()).order('created_at', { ascending: true }).limit(1).single();
```

### PATCH M5-06

ابحث عن المقطع الكامل الذي يبدأ بـ:

```javascript
await supabase
    .from('orders')
    .update({ runsheet_id: null, order_status: 'Confirmed' })
    .in('order_code', selected);
```

وينتهي عند السطر:

```text
.in('order_code', selected);
```

**احذفه كاملًا ولا تضف بديلًا.**

### PATCH M5-07

ابحث عن السطر:

```javascript
var rsRes = await supabase.from('runsheets').select('runsheet_code, status').in('status', ['Open', 'Confirmed']);
```

استبدله بـ:

```javascript
var rsRes = await supabase.from('runsheets').select('runsheet_code, status').eq('company_id', _rwCompanyId()).in('status', ['Open', 'Confirmed']);
```

ثم ابحث عن:

```javascript
var targetRsRes = await supabase.from('runsheets').select('id').eq('runsheet_code', v.value).maybeSingle();
```

واستبدله بـ:

```javascript
var targetRsRes = await supabase.from('runsheets').select('id').eq('company_id', _rwCompanyId()).eq('runsheet_code', v.value).maybeSingle();
```

### PATCH M5-08

ابحث عن السطر:

```javascript
return supabase.from('runsheets').select('id, runsheet_code').then(function(res) {
```

واستبدله بـ:

```javascript
return supabase.from('runsheets').select('id, runsheet_code').eq('company_id', _rwCompanyId()).then(function(res) {
```

### PATCH M5-09

ابحث عن السطر:

```javascript
var ordRes = await supabase.from('orders').select('*, runsheets(runsheet_code)');
```

داخل `_refreshData` تحديدًا، واستبدله بـ:

```javascript
var ordRes = await supabase.from('orders').select('*, runsheets(runsheet_code)').eq('company_id', _rwCompanyId());
```

ثم استبدل:

```javascript
var detRes = await supabase.from('order_details').select('order_id, item_code');
```

بـ:

```javascript
var orderIds = ordersData.map(function(o) { return o.id; }).filter(Boolean);
var detRes = orderIds.length
    ? await supabase.from('order_details').select('order_id, item_code').in('order_id', orderIds)
    : { data: [] };
```

### PATCH M5-10

ابحث عن:

```javascript
var dRes = await supabase.from('users').select('email, name').in('role', ['driver','سائق','مندوب']);
```

استبدله بـ:

```javascript
var dRes = await supabase.from('users').select('email, name').eq('company_id', _rwCompanyId()).in('role', ['driver','سائق','مندوب']);
```

وابحث عن:

```javascript
var vRes = await supabase.from('vehicles').select('id, license_plate, model');
```

استبدله بـ:

```javascript
var vRes = await supabase.from('vehicles').select('id, license_plate, model').eq('company_id', _rwCompanyId());
```

### PATCH M5-11

ابحث عن:

```javascript
var res = await supabase.from('runsheets').select('*').order('run_date', { ascending: false });
```

استبدله بـ:

```javascript
var res = await supabase.from('runsheets').select('*').eq('company_id', _rwCompanyId()).order('run_date', { ascending: false });
```

### PATCH M5-12

ابحث عن:

```javascript
var rsRes = await supabase.from('runsheets').select('*').eq('runsheet_code', code).maybeSingle();
```

استبدله بـ:

```javascript
var rsRes = await supabase.from('runsheets').select('*').eq('company_id', _rwCompanyId()).eq('runsheet_code', code).maybeSingle();
```

ثم ابحث عن:

```javascript
var ordersRes = await supabase.from('orders').select('order_code, customer_name, total_amount').eq('runsheet_id', rs.id);
```

واستبدله بـ:

```javascript
var ordersRes = await supabase.from('orders').select('order_code, customer_name, total_amount').eq('company_id', _rwCompanyId()).eq('runsheet_id', rs.id);
```

## 9. Production Status

لا توجد حاجة إلى تعديل Production بسبب PATCH M5-01..M5-12 نفسها؛ هذه تعديلات مصدر Frontend.

Production RLS الحالي يؤكد أن إزالة الـdirect order update في `_createRS` مطلوبة.

لا يتم إنشاء `delete-runsheet` capability في هذه الجلسة لأن owner/business contract غير مثبت.

## 10. Final Self-Audit

### ما تم إثباته

- MASTER governance read to EOF.
- CURRENT_STATE was reconciled against current Git/Production.
- Report75 was treated as historical evidence, not current truth.
- main4 current source contains corrected M4-01 and M4-02 remains intact.
- Current Git HEAD is `cbc30625...`.
- Current main4 blob is `e89d29e...`.
- Current main5 blob is `caffc018...`.
- Production was rechecked at `2026-09-07 10:12:16 UTC`.
- Production currently has no orders or runsheets.
- Orders have SELECT-only authenticated RLS; runsheets have company-aware write policies.
- Main5 has the listed company-scope defects and an unauthorized/redundant direct order update.
- No Production delete-runsheet owner was found.

### ما لم يتم إثباته

```text
main4 browser runtime
main5 browser runtime
11-part final assembly
Full PWA runtime
Production runtime of final assembled main
E2E create/append/delete runsheet behavior
Atomic delete-runsheet business contract
```

### ما تم تعديله في هذه الجلسة

```text
MAIN4 = no source modification by assistant
MAIN5 = no source modification by assistant
Production = no new main5-specific migration/deployment
Documentation = Report76
```

## 11. NEXT AUTHORIZED ACTION

```text
USER:
  Apply PATCH M5-01 → M5-12 exactly to Current/PWA/main2/main5.md.

THEN:
  commit main5.md

THEN:
  provide new main5 commit SHA + blob SHA

THEN:
  re-read main5 from first line to EOF
  perform structural/source recheck
  reconcile Production again
  continue to the next main2 part only after M5 source closure
```

## 12. Closure Status

```text
MAIN4 SOURCE = CLOSED
MAIN4 RUNTIME = OPEN
MAIN5 SOURCE = OPEN / USER PATCH REQUIRED
MAIN5 RUNTIME = OPEN
11-PART INTEGRATION = OPEN
PROJECT = OPEN
```
