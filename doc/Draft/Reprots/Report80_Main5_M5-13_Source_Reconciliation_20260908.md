# RAWAEA ERP — Report80
## Main5 M5-13 Source Reconciliation + M5-20 Consumer Contract Drift

**التاريخ:** 2026-09-08
**المستودع:** `papamohammed77-glitch/rawaie-erp-New`
**الفرع:** `main`
**Production:** `SMART ERP / fiilmooggumokxanwiyx`
**الهدف:** `Current/PWA/main2/main5.md`

## 1. نقطة البداية والتحقق

تمت قراءة `CURRENT_STATE.md` بالكامل، وReport79 بالكامل، وملفات الاستمرارية الثلاثة:

- `MASTER - RAWAEA ERP FORENSIC CONTINUITY GOVERNANCE v2.md`
- `MASTER - RAWAEA ERP - UNIFIED CONTINUITY & MAIN1 EXECUTION.md`
- `MASTER - RAWAEA ERP.md`

كما تمت مراجعة سجل Git الأخير، ثم قراءة `main5.md` من البداية حتى EOF والتحقق من الإصدار المنشور في `main`.

## 2. Last Verified Event

آخر حدث Git مباشر قبل هذه المراجعة:

`bf87eac7b1623058402db1495114dd4523ebe92d`

الرسالة:

`Refactor runsheet management with async/await`

الـcommit يثبت أن M5-13-A/B/C طُبقت بالفعل داخل `main5.md`.

Blob الحالي لـ`main5.md`:

`9f9926511c47f0295019daaf09ff4b5a1a2efc50`

## 3. M5-13 — نتيجة إعادة التحقق

تمت مطابقة المصدر الحالي مع الهدف السابق.

### UPDATE

`preConfirm` أصبح يستدعي:

`/functions/v1/manage-runsheet`

مع العملية:

`UPDATE`

### DELETE

`_deleteRunsheet(code)` أصبح يستدعي:

`/functions/v1/manage-runsheet`

مع العملية:

`DELETE`

### CANCEL

`_cancelRunsheet(code)` أصبح يستدعي:

`/functions/v1/manage-runsheet`

مع العملية:

`CANCEL`

### Direct-write scan

لم يعد موجودًا في `main5.md` أي استخدام مباشر لـ:

- `supabase.from('runsheets').update(...)`
- `supabase.from('runsheets').delete(...)`
- `supabase.from('orders').update(...)` لمسار M5-13
- `supabase.from('run_sheet_details').delete(...)` لمسار M5-13

إذن M5-13 source handoff تم تطبيقه فعليًا.

## 4. Production reconciliation

Production الحالية:

- Supabase project = `fiilmooggumokxanwiyx`
- Project status = `ACTIVE_HEALTHY`
- PostgreSQL = `17.6.1.121`
- `manage_runsheet` Edge = `ACTIVE v1`
- `verify_jwt = true`
- `manage_runsheet_atomic` = `SECURITY DEFINER`
- EXECUTE = `postgres + service_role` فقط
- `anon/authenticated` = لا EXECUTE

والدالة الحالية `manage_runsheet_atomic` تقبل فقط:

`UPDATE / CANCEL / DELETE`

مع company scope وrow locking وحراس حالة التنفيذ.

## 5. Production data snapshot

تم قياس Production مباشرة قبل إغلاق هذه المراجعة:

```text
companies=1
users=24
branches=2
items=17
orders=0
runsheets=0
order_details=0
run_sheet_details=0
stock_branches=20
inventory_log=3
```

لا توجد بيانات Runsheet/Order حالية تسمح باختبار Browser E2E حقيقي دون إنشاء بيانات اختبار. لذلك لا يتم الادعاء بوجود Browser E2E في هذه الجلسة.

## 6. Realtime contract

تم التحقق من سياسات القراءة الحالية لـ:

- `orders`
- `order_details`
- `runsheets`
- `run_sheet_details`

وتبيّن أن `order_details` و`run_sheet_details` محميتان بسياسات SELECT مرتبطة بالـtenant عبر الأب المرتبط بها.

لذلك عدم وجود `company_id` مباشر في قناة Realtime لهاتين الجدولين لا يثبت وجود Tenant Data Leak بحد ذاته، ولم يتم اختراع Patch لهذا الجزء.

## 7. Defect مكتشف أثناء full-file recheck — M5-20

أثناء مقارنة `main5.md` مع Production اكتُشف Drift حقيقي بين UI Consumer وBackend Contract.

في `main5.md` يوجد شرط يسمح بإظهار زر حذف للأوردر عندما تكون الحالة:

`Invoiced`

بينما Production `delete-order v8` يرفض الحذف صراحة في هذه الحالة، ويقبل فقط:

`Draft / Confirmed / Pending`

ويتعامل مع الفاتورة المنفذة عبر مسار عكسي رسمي.

هذا ليس اختلافًا تجميليًا؛ إنه Consumer Contract Drift.

### Root Cause

تمت إضافة `Invoiced` إلى قائمة الحالات القابلة للحذف في واجهة `main5` دون أن يكون ذلك متوافقًا مع عقد `delete-order` الحالي في Production.

### Production action

لا توجد حاجة لتعديل Production لهذا العيب؛ الـBackend Guard صحيح بالفعل.

التصحيح المطلوب في المصدر هو إيقاف إظهار Delete لـ`Invoiced`.

## 8. التعليمات الجراحية المطلوبة للمستخدم

### M5-20-A — قائمة حذف الأوردر في الجدول

ابحث حرفيًا عن السطر:

```javascript
var canDelete = (o.order_status === 'Draft' || o.order_status === 'Confirmed' || o.order_status === 'Invoiced') && !o.runsheet_id;
```

احذف السطر كاملًا، وينتهي عند:

```text
;
```

واستبدله حرفيًا بـ:

```javascript
var canDelete = (o.order_status === 'Draft' || o.order_status === 'Confirmed' || o.order_status === 'Pending') && !o.runsheet_id;
```

### M5-20-B — إزالة Debug Console غير الضروري

ابحث حرفيًا عن السطر:

```javascript
console.log('DEBUG_DELETE:', o.order_code, o.order_status, o.runsheet_id);
```

احذف هذا السطر كاملًا.

### M5-20-C — زر الحذف داخل مودال تفاصيل الأوردر

ابحث حرفيًا عن هذا المقطع الكامل:

```javascript
var cannotDeleteStatuses = ['Returned', 'Partially Returned', 'Cancelled'];
var isDeletable = (order.order_status === 'Draft' || order.order_status === 'Pending' || order.order_status === 'Confirmed' || order.order_status === 'Invoiced');
var canDelete = isDeletable && !order.runsheet_id && cannotDeleteStatuses.indexOf(order.order_status) === -1;
```

احذف المقطع كاملًا حتى نهاية السطر:

```javascript
var canDelete = isDeletable && !order.runsheet_id && cannotDeleteStatuses.indexOf(order.order_status) === -1;
```

ثم استبدله حرفيًا بـ:

```javascript
var isDeletable = (order.order_status === 'Draft' || order.order_status === 'Pending' || order.order_status === 'Confirmed');
var canDelete = isDeletable && !order.runsheet_id;
```

## 9. لماذا لا توجد تعديلات أخرى مطلوبة على main5 الآن

- M5-13 source routing موجود فعليًا.
- `manage-runsheet` هو الـauthoritative mutation owner.
- RLS الحالية تمنع قراءة `order_details` و`run_sheet_details` خارج tenant في المسارات الحالية.
- `run_sheet_details` لا يحتوي `company_id` مباشرًا، ولذلك لا يمكن اختراع Realtime filter غير مدعوم بالschema.
- لم يظهر أثناء قراءة EOF أي direct writer إضافي ضمن نطاق M5-13.

## 10. ما لم يتم إثباته

- Browser E2E كامل لـM5-13 غير منفذ في هذه الجلسة لأن Production الحالية لا تحتوي Orders/Runsheets.
- لم يتم تعديل `main5.md` بواسطة المساعد، تنفيذًا لبروتوكول أن المستخدم هو من ينفذ تعديلات الأجزاء الـ11.
- لا يمكن اعتبار M5-20 مغلقًا حتى يُطبّق المستخدم التعديلات الثلاثة ثم يُعاد فحص `main5.md` كاملًا.

## 11. ما تم إصلاحه وما لم يتم إصلاحه

### تم إثباته

- M5-13-A/B/C موجودة في المصدر الحالي.
- Production capability موجودة ومنشورة.
- Production tenant guard موجود.
- Production backend لا يسمح بحذف Invoiced.
- بيانات Production الحالية متطابقة مع snapshot السابق لهذه الوحدة.

### المطلوب من المصدر

M5-20-A/B/C فقط.

## 12. Final Self-Audit

### What I Proved

- قرأت Master root حتى EOF.
- قرأت Master unified حتى EOF.
- قرأت `main5.md` حتى EOF.
- راجعت Git history المباشر.
- راجعت Production deployment الحالي لـ`manage-runsheet`.
- راجعت Production `delete-order`.
- راجعت RLS الخاصة بالـorder/runsheet detail tables.
- أثبتت أن M5-13 تم تطبيقه فعليًا في Source.
- أثبتت وجود M5-20 Contract Drift.

### What I Initially Missed

Report79 كان صحيحًا في M5-13، لكن full-file reconciliation الحالي كشف أن إضافة `Invoiced` في Delete UI لا تتوافق مع `delete-order v8` الحالي.

### What Could Still Be Wrong

يظل هناك احتمال وجود Browser-only behavior لا يظهر في Source/DB بسبب عدم وجود بيانات تشغيلية حقيقية حاليًا، ولذلك لا يتم ادعاء Browser E2E.

### Final Closure Status

```text
M5-13 BACKEND = CLOSED
M5-13 SOURCE = VERIFIED / APPLIED
M5-20 UI CONTRACT DRIFT = OPEN / EXACT SOURCE PATCH PROVIDED
MAIN5 FINAL RELEASE GATE = OPEN
```

الخطوة المسموح بها بعد M5-20 هي إعادة قراءة `main5.md` من line 1 إلى EOF، ثم syntax/structure/direct-write/consumer scan، ثم Production reconciliation جديد.