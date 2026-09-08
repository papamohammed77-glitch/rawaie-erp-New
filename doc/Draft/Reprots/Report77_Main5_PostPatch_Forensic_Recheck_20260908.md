# Report77 — إعادة المراجعة الجنائية الكاملة لـ main5 بعد تطبيق تعديلات Report76

التاريخ: 2026-09-08
الفرع: `main`
المستودع: `papamohammed77-glitch/rawaie-erp-New`
Production: `SMART ERP / fiilmooggumokxanwiyx`

## 1. نقطة الاستمرار

هذه الجلسة لم تبدأ من الصفر.
تم اتباع أمر الاستمرارية والحكم الوارد في:

- `doc/Draft/medhat/MASTER - RAWAEA ERP.md`
- `doc/Draft/Reprots/Report76_Main5_Forensic_Continuation_20260907.md`
- `CURRENT_STATE.md`

تمت إعادة قراءة MASTER حتى النهاية، وقراءة Report76، وقراءة CURRENT_STATE، ثم إعادة قراءة `Current/PWA/main2/main5.md` كاملًا حتى EOF عبر قراءة متسلسلة للنطاقات.

## 2. Current Git Reality

عند بداية التحقق كان `CURRENT_STATE.md` يسجل main5 بالـblob القديم:

```text
caffc0187b54444e96491dc6f00a238b2e870b32
```

بينما Git الحالي أثبت أن `main5.md` أصبح:

```text
PATH = Current/PWA/main2/main5.md
CURRENT BLOB = 34182a5a2380a0b4704503a964af07b92982b86f
```

وGit HEAD الحالي بعد تغييرات هذه الجلسة:

```text
cc6e302392d647ebde56a83dbdd7d02a049c0548
```

والـHEAD الحالي نتج عن إضافة ملف migration canonical خاص بتحديثات Realtime.

## 3. Historical Evidence Reconciliation

Report76 أثبت أن M5-01 إلى M5-12 وM5-14 كانت مطلوبة.
إعادة قراءة main5 الحالية أثبتت أن معظم هذه التعديلات أصبحت موجودة فعليًا في المصدر الحالي، ومنها:

```text
M5-01 = orders query company-scoped      PRESENT
M5-02 = order_details bounded by order IDs PRESENT
M5-03 = orders realtime company filter    PARTIALLY PRESENT (filter only)
M5-04 = _showDetails company-scoped      PRESENT
M5-05 = _printOrder settings company-scoped PRESENT
M5-06 = direct orders UPDATE before create-runsheet removed PRESENT
M5-07 = append target runsheet scoped      PRESENT
M5-08 = _loadRunsheetCodes scoped          PRESENT
M5-09 = _refreshData scoped/bounded        PRESENT
M5-10 = drivers/vehicles scoped            PRESENT
M5-11 = runsheets main list scoped          PRESENT
M5-12 = _details runsheet/orders scoped     PRESENT
M5-14 = currency driven from app_settings   PRESENT
```

## 4. Main5 Structural Recheck

قراءة `main5.md` وصلت إلى آخر السطر:

```text
window.RW_Runsheets = RW_Runsheets;
```

وإغلاقات الوحدات الرئيسية موجودة بنيويًا:

```text
RW_Orders = (function(){ ... })();
RW_Runsheets = (function(){ ... })();
```

لكن ظهرت أثناء إعادة القراءة الحالية مشكلتان Syntax واضحتان في `RW_Runsheets._details` لم تظهر في تقرير76 السابق.

### M5-17-A — Syntax Error

المقطع الحالي:

```javascript
ordersHtml += '<span class="inline-block bg-white rounded px-3 py-1 text-sm shadow-sm">' + orders[o].order_code + ' - ' + orders[o].customer_name + ' (' + _fmtNum(orders[o].total_amount) + ' ' ' + currency)</span>';
```

يوجد string literal متجاور بدون `+`، كما أن ترتيب الإغلاق غير صحيح.

### M5-17-B — Syntax Error

المقطع الحالي:

```javascript
itemsHtml += '<div class="mt-3 text-left font-bold text-lg">إجمالي الأصناف: ' + _fmtNum(grandTotal) + ' ' ' + currency</div>';
```

يوجد string literal متجاور بدون `+`، والإغلاق `</div>` خارج السلسلة.

هذان الخطآن كافيان لمنع parsing صحيح للملف المدمج إذا وصلا إلى runtime.

## 5. New Scope Findings Missed By Report76

### M5-15 — `_printOrder` order lookup still global

الموجود حاليًا:

```javascript
supabase.from('orders').select('*').eq('order_code', code).maybeSingle()
```

رغم أن `_showDetails` أصبح company-scoped، يظل مسار الطباعة غير scoped.

### M5-16 — `_createRS` new runsheet lookup still global

الموجود حاليًا:

```javascript
var newRsRes = await supabase.from('runsheets').select('id').eq('runsheet_code', json.rsId).maybeSingle();
```

إنشاء الرانشيت نفسه يذهب إلى capability صحيحة (`create-runsheet`)، لكن lookup اللاحق يجب أن يبقى ضمن Company Context نفسه.

## 6. Realtime Forensic Verification

الهدف التشغيلي للمشروع هو أن تظهر عمليات إنشاء/تعديل الأوردرات والرانشيتات دون refresh، وأن تكون العملة وغيرها من إعدادات `app_settings` قابلة للتغيير مركزيًا.

Production قبل الإصلاح كانت تحتوي Realtime publication على:

```text
orders فقط
```

أما الآن، بعد التطبيق المباشر والتحقق:

```text
app_settings
order_details
orders
run_sheet_details
runsheets
```

كلها ضمن `supabase_realtime`.

كما تم جعل `REPLICA IDENTITY FULL` للجداول الخمسة.

Production migration versions:

```text
20260908010304 = enable_realtime_orders_runsheets_fulfillment
20260908010601 = add_app_settings_realtime_currency_contract
```

وهذا يحقق أساسًا صحيحًا لالتقاط INSERT / UPDATE / DELETE والفلترة حسب الشركة عند استخدام Realtime.

## 7. Production Integration Finding — append-to-runsheet

أثناء التحقق من مالك عملية «ضم الأوردر إلى رانشيت» تم فحص Edge Function المنشورة.

تم اكتشاف defect حقيقي في النسخة السابقة:

```text
order_details ... eq('company_id', c)
```

لكن `order_details` لا تحتوي على `company_id` في Production schema.

تم إصلاح Production مباشرة، وإعادة نشر:

```text
append-to-runsheet
VERSION = 7
STATUS = ACTIVE
```

والـsource canonical في Git تم تحديثه أيضًا.

الإصلاح حافظ على Company scoping الصحيح لأن الأوردرات نفسها تم تحميلها أولًا ضمن company context، ثم تم استخدام `order_id` الناتج لتقييد `order_details`.

## 8. create-runsheet Ownership Verification

Production `create-runsheet` الحالية:

```text
VERSION = 26
VERIFY JWT = true
```

وتستخدم:

```text
create_runsheet_atomic
```

ولا يوجد ما يبرر إعادة تنفيذ إنشاء الرانشيت داخل frontend.

إذًا إزالة الـdirect DB update من main5 قبل استدعاء `create-runsheet` صحيحة، بينما mutation المحلي داخل `ordersData` بعد النجاح ليس DB writer، ولذلك لا يعتبر Parallel DB Writer.

## 9. Production Current Snapshot

تمت مطابقة Production مباشرة بتاريخ:

```text
2026-09-08 01:02:35 UTC
```

والأرقام الحالية:

```text
companies      = 1
app_settings   = 1
users          = 24
branches       = 2
items          = 17
orders         = 0
runsheets      = 0
stock_rows     = 20
inventory_logs = 3
```

Current currency:

```text
SAR
```

وبسبب عدم وجود orders/runsheets حاليًا، لا يمكن تنفيذ E2E browser transaction حقيقي على إنشاء/ضم رانشيت دون اختلاق بيانات تشغيلية دائمة.

## 10. What Was Actually Executed In Production

1. إضافة `runsheets`, `order_details`, `run_sheet_details` إلى `supabase_realtime`.
2. إضافة `app_settings` إلى `supabase_realtime`.
3. جعل `orders`, `runsheets`, `order_details`, `run_sheet_details`, `app_settings` = `REPLICA IDENTITY FULL`.
4. إصلاح Edge Function `append-to-runsheet` وإعادة نشرها كالإصدار 7.
5. توثيق تغييرات Production في Git عبر migrations canonical.

## 11. What Was NOT Modified

بسبب قاعدة هذه المرحلة:

```text
Assistant may modify Production directly.
User modifies the 11 mother-file fragments.
```

لم يتم تعديل:

```text
Current/PWA/main2/main5.md
```

مباشرة بواسطة المساعد.

## 12. Exact Surgical Instructions Still Required On main5

### PATCH M5-17-A

ابحث عن **السطر الكامل التالي**:

```javascript
ordersHtml += '<span class="inline-block bg-white rounded px-3 py-1 text-sm shadow-sm">' + orders[o].order_code + ' - ' + orders[o].customer_name + ' (' + _fmtNum(orders[o].total_amount) + ' ' ' + currency)</span>';
```

**احذفه كاملًا واستبدله بهذا السطر الكامل:**

```javascript
ordersHtml += '<span class="inline-block bg-white rounded px-3 py-1 text-sm shadow-sm">' + orders[o].order_code + ' - ' + orders[o].customer_name + ' (' + _fmtNum(orders[o].total_amount) + ' ' + currency + ')</span>';
```

### PATCH M5-17-B

ابحث عن **السطر الكامل التالي**:

```javascript
itemsHtml += '<div class="mt-3 text-left font-bold text-lg">إجمالي الأصناف: ' + _fmtNum(grandTotal) + ' ' ' + currency</div>';
```

**احذفه كاملًا واستبدله بهذا السطر الكامل:**

```javascript
itemsHtml += '<div class="mt-3 text-left font-bold text-lg">إجمالي الأصناف: ' + _fmtNum(grandTotal) + ' ' + currency + '</div>';
```

### PATCH M5-15

ابحث عن **السطر الكامل التالي** داخل `_printOrder`:

```javascript
supabase.from('orders').select('*').eq('order_code', code).maybeSingle()
```

**استبدله بالسطر الكامل:**

```javascript
supabase.from('orders').select('*').eq('company_id', _rwCompanyId()).eq('order_code', code).maybeSingle()
```

### PATCH M5-16

ابحث عن **السطر الكامل التالي** داخل `_createRS`:

```javascript
var newRsRes = await supabase.from('runsheets').select('id').eq('runsheet_code', json.rsId).maybeSingle();
```

**استبدله بالسطر الكامل:**

```javascript
var newRsRes = await supabase.from('runsheets').select('id').eq('company_id', _rwCompanyId()).eq('runsheet_code', json.rsId).maybeSingle();
```

### PATCH M5-18 — Orders Realtime

في `RW_Orders.render` ابحث عن **المقطع الكامل الذي يبدأ حرفيًا بـ**:

```javascript
var channel = supabase
    .channel('orders-realtime')
```

وينتهي بـ:

```javascript
    .subscribe();
```

**احذف المقطع كاملًا، من `var channel = supabase` حتى `.subscribe();`، واستبدله بالكامل بهذا المقطع:**

```javascript
if (window._rwOrdersRealtimeChannel) {
    supabase.removeChannel(window._rwOrdersRealtimeChannel);
    window._rwOrdersRealtimeChannel = null;
}
window._rwOrdersRealtimeChannel = supabase
    .channel('orders-realtime-' + companyId)
    .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'orders',
        filter: 'company_id=eq.' + companyId
    }, function() {
        if (RW_STATE.app.currentView === 'orders') {
            _refreshData().catch(function(e) { console.error('Orders realtime refresh failed:', e); });
        }
    })
    .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'order_details'
    }, function() {
        if (RW_STATE.app.currentView === 'orders') {
            _refreshData().catch(function(e) { console.error('Order details realtime refresh failed:', e); });
        }
    })
    .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'app_settings',
        filter: 'company_id=eq.' + companyId
    }, async function() {
        try {
            var currencyRes = await supabase.from('app_settings')
                .select('currency')
                .eq('company_id', companyId)
                .order('created_at', { ascending: true })
                .limit(1)
                .maybeSingle();
            if (currencyRes.data) {
                currency = currencyRes.data.currency || 'SAR';
                _applyFilters();
            }
        } catch(e) {
            console.error('Currency realtime refresh failed:', e);
        }
    })
    .subscribe();
```

### PATCH M5-19 — Runsheets Realtime

داخل `RW_Runsheets`، داخل `async function render()`، ابحث عن **السطر الكامل الموجود مباشرة بعد**:

```javascript
safeHTML(c, html);
```

وهو:

```javascript
_apply();
```

**أضف فوق هذا السطر مباشرة** المقطع التالي، أي يصبح `_apply();` موجودًا بعد المقطع كما هو دون حذفه:

```javascript
if (window._rwRunsheetsRealtimeChannel) {
    supabase.removeChannel(window._rwRunsheetsRealtimeChannel);
    window._rwRunsheetsRealtimeChannel = null;
}
var runsheetsCompanyId = _rwCompanyId();
window._rwRunsheetsRealtimeChannel = supabase
    .channel('runsheets-realtime-' + runsheetsCompanyId)
    .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'runsheets',
        filter: 'company_id=eq.' + runsheetsCompanyId
    }, function() {
        if (RW_STATE.app.currentView === 'runsheets') {
            render();
        }
    })
    .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'run_sheet_details'
    }, function() {
        if (RW_STATE.app.currentView === 'runsheets') {
            render();
        }
    })
    .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'order_details'
    }, function() {
        if (RW_STATE.app.currentView === 'runsheets') {
            render();
        }
    })
    .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'orders',
        filter: 'company_id=eq.' + runsheetsCompanyId
    }, function() {
        if (RW_STATE.app.currentView === 'runsheets') {
            render();
        }
    })
    .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'app_settings',
        filter: 'company_id=eq.' + runsheetsCompanyId
    }, function() {
        if (RW_STATE.app.currentView === 'runsheets') {
            render();
        }
    })
    .subscribe();
```

ثم اترك السطر الموجود أصلًا:

```javascript
_apply();
```

دون تغيير.

## 13. M5-13 Remains Open

`_deleteRunsheet` و`_cancelRunsheet` ما زالا يحتويان عمليات DB مباشرة من الواجهة.
لم يتم اختراع Backend جديد لهذه العمليات.

هذا ليس نقصًا في التحقيق؛ بل التزام صريح بقاعدة:

```text
UNKNOWN / UNPROVEN CONTRACT ≠ INVENT A NEW OWNER
```

الإغلاق يحتاج إعادة بناء عقد الحذف/الإلغاء من التاريخ + Business Contract + Production capability.

## 14. Final Evidence Assessment

### PROVEN

```text
MASTER read to EOF
CURRENT_STATE reconciled enough to detect stale main5 SHA
Report76 reconciled against current source
main5 read completely to EOF
M5-01..12 and M5-14 mostly present in current source
Production current counts verified
Production currency = SAR verified
Realtime publication now covers required tables
Replica identity FULL now enabled for required tables
append-to-runsheet defect identified and fixed in Production v7
append-to-runsheet Git source aligned
create-runsheet Production owner verified
```

### NOT PROVEN

```text
main5 source closure = OPEN until user performs M5-15..M5-19
main5 browser runtime = NOT VERIFIED
11-part integration = NOT VERIFIED
full PWA runtime = NOT VERIFIED
real Realtime browser E2E = NOT VERIFIED because current Production has zero orders/runsheets
_deleteRunsheet business contract = OPEN
_cancelRunsheet business contract = OPEN
```

## 15. Final Status

```text
MAIN5 SOURCE = OPEN — USER SURGICAL PATCH REQUIRED
MAIN5 SYNTAX = BLOCKED BY M5-17-A / M5-17-B UNTIL CORRECTED
MAIN5 TENANT SCOPE = OPEN M5-15 / M5-16
MAIN5 REALTIME = PRODUCTION FOUNDATION CLOSED; SOURCE SUBSCRIPTION OPEN M5-18 / M5-19
APPEND-TO-RUNSHEET PRODUCTION = FIXED / DEPLOYED v7
PRODUCTION REALTIME FOUNDATION = CLOSED
M5-13 DELETE/CANCEL CONTRACT = OPEN
11-PART INTEGRATION = OPEN
BROWSER RUNTIME = OPEN
PROJECT = OPEN
```

## 16. Last Verified Event

```text
EVENT TYPE = MAIN5 POST-PATCH FORENSIC RECHECK + PRODUCTION REALTIME INTEGRATION
UTC = 2026-09-08 01:02:35+00
GIT HEAD = cc6e302392d647ebde56a83dbdd7d02a049c0548
MAIN5 BLOB = 34182a5a2380a0b4704503a964af07b92982b86f
PRODUCTION SNAPSHOT = companies=1, users=24, branches=2, items=17, orders=0, runsheets=0, stock_rows=20, inventory_logs=3
PRODUCTION CHANGES = Realtime publication + REPLICA IDENTITY FULL; append-to-runsheet v7
RESULT = Current main5 recheck found 4 additional source issues; production prerequisites for live order/runsheet/settings synchronization are now in place
EVIDENCE = current Git source + direct Production SQL + active Edge Function deployment
NEXT AUTHORIZED ACTION = User applies exact M5-15..M5-19 blocks to main5, commits, then main5 is re-read from first line to EOF and integration/runtime verification continues
```
