# Report82 — Main5 M5-20 Historical Contract Reconciliation

## 1. Current State

تمت إعادة فتح المهمة من الحالة الحالية، وليس من بداية المشروع.
تمت قراءة `CURRENT_STATE.md`، وReport80، وReport81، وملفات Master الثلاثة، ثم تمت قراءة `Current/PWA/main2/main5.md` من البداية حتى EOF.

**المصدر الحالي لـmain5 لم يتغير خلال هذه الجلسة.**

- Path: `Current/PWA/main2/main5.md`
- Current Blob: `9f9926511c47f0295019daaf09ff4b5a1a2efc50`
- EOF: `window.RW_Runsheets = RW_Runsheets;`

## 2. Last Verified Event

- UTC snapshot: `2026-09-08 03:10:41.530622+00`
- Production project: `fiilmooggumokxanwiyx`
- Production orders: `0`
- Production Invoiced orders: `0`
- Production POS-origin orders: `0`
- Production `delete_order` registry rows: `0`

## 3. Git Facts

آخر Source change لهذه الجلسة:

- `Current/Edge_Functions/delete-order` تم تحديثه ليصبح thin capability wrapper يستدعي `delete_order_atomic`.
- Commit: `a4c26d7c5e1a0ebfb0d394b04810126c497b18a4`

تمت إضافة canonical migration:

- `supabase/migrations/20260908_close_parent_pos_invoiced_order_deletion.sql`
- Commit: `9c2dab4cb7a5f04a36472ae92324f90f1c2380fe`

`main5.md` لم يُعدّل.

## 4. Historical Contract Used

تم الرجوع إلى:

`rawaie-erp-review/Edge_Functions/original/01_order_lifecycle/delete-order.ts`

وهو يثبت أن النظام التاريخي كان يسمح بحذف الأوردرات المنفذة بعد عكس آثار المخزون والحسابات ثم حذف الأوردر نفسه.

هذا السلوك التاريخي لا يتم نسخه حرفيًا؛ لأن التنفيذ الأصلي كان يحتوي على كتابات مباشرة للمخزون ومراجع ثابتة للشركة/الحسابات، وهو غير صالح ليكون Core اليوم.

الاستنتاج: **وجود `Invoiced` ضمن مسار الحذف ليس اختراعًا جديدًا، بل Capability تاريخية مثبتة يجب إعادة بناء ownership الخاص بها داخل المعمارية الحالية.**

## 5. Conflict Reconciliation

Report80/81 صنفا وجود `Invoiced` في main5 كـConsumer/Backend Drift، واقترحا حذف هذا الخيار من الواجهة وعدم تغييره في Production.

أعيد فتح هذا الاستنتاج بسبب دليل أقوى:

1. العقد التاريخي الأصلي يثبت capability حذف الأوردر المنفذ.
2. المستخدم أكد صراحة أن قرار السماح بحذف فاتورة POS `Invoiced` من النظام الأم كان قرارًا وظيفيًا مقصودًا، بهدف ألا تكون صلاحية تعديل فاتورة الكاشير لدى الكاشير نفسه.
3. current `main5` يحتوي بالفعل على هذه capability في موضعين.
4. Production كانت قد أغلقت هذه capability بالكامل في `delete-order v8`.

لذلك تم تصنيف المشكلة الحقيقية على أنها:

**Historical Functionality Lost / Current Backend Contract Drift**

وليس:

**UI Bug يجب إخفاءه.**

## 6. Root Cause

السبب الجذري كان وجود فصل بين:

- Historical Parent-System capability
- Current main5 consumer
- Current backend `delete-order`
- Current canonical engines

المشكلة ليست أن main5 يعرض `Invoiced` وحده، بل أن Production لم تعد تملك Backend capability آمنة تنفذ هذا السيناريو.

## 7. Production Change Implemented

تم إنشاء `public.delete_order_atomic(company_id, order_code, user_email)` كـSecurity Definer capability مركزية.

### Draft / Confirmed / Pending
يبقى الحذف المباشر مدعومًا كما كان العقد الحالي.

### Invoiced
تم قصره على:

- `orders.source = 'pos'`
- الأوردر غير مربوط بـRunsheet
- الحالة `Invoiced`
- المستخدم لديه صلاحية فعالة واحدة على الأقل من:
  - `*`
  - `general_manager`
  - `sales_manager`
  - `sales_supervisor`

هذه المفاتيح لم تُختر بالتخمين؛ تم التحقق منها من `users.permissions` و`roles.permissions` و`role_permissions` في Production الحالية.

### Cashier
Production الحالية تثبت أن حساب الكاشير يحمل `permissions = ["pos"]` ولا يملك أيًا من صلاحيات الحذف المنفذ أعلاه.

## 8. Business Reversal Flow

عند حذف `Invoiced` يتم قبل حذف الأوردر:

1. عكس كل Physical Stock movement عبر `post_stock_movement`.
2. عكس القيد الأصلي عبر `post_journal_entry`.
3. عكس Customer Ledger عند وجود قيد عميل متعلق بالفاتورة.
4. عكس Driver Ledger عند وجود قيد سائق متعلق بالفاتورة.
5. حفظ العملية في `erp_operation_registry` لدعم retry/idempotency.
6. تسجيل audit event.
7. حذف `order_details` ثم `orders`.

لا توجد كتابة مباشرة إلى `stock_branches.qty` داخل capability الجديدة.

## 9. Inventory Ownership

العقد الحالي بقي:

`Physical Stock -> post_stock_movement -> stock_branches + inventory_log`

و`delete_order_atomic` يستدعي `post_stock_movement` فقط ولا ينشئ Physical Stock Engine موازيًا.

تمت مراجعة grants:

- `delete_order_atomic`: `service_role` فقط.
- `authenticated`: لا يملك EXECUTE المباشر.
- `anon`: لا يملك EXECUTE.

## 10. Edge Deployment

تم نشر `delete-order`:

- Version: `9`
- Status: `ACTIVE`
- `verify_jwt = true`
- Deployment id: `cd9b6859-725b-4286-8a7d-e7d503da0280`
- Deployment timestamp: `2026-09-08 03:12:17.477000+00`

والـEdge أصبح wrapper رفيعًا:

`JWT -> users.auth_id -> users.company_id -> delete_order_atomic`

## 11. Runtime Verification

تمت إعادة قراءة تعريف Production بعد النشر والتحقق من:

- وجود `delete_order_atomic`.
- `SECURITY DEFINER = true`.
- `service_role EXECUTE = true`.
- `authenticated EXECUTE = false`.
- `anon EXECUTE = false`.
- `delete-order` Deployment v9 ACTIVE.

### ما لم يمكن إثباته
Production الحالية لا تحتوي أي `Invoiced POS order`.
وبالتالي لا توجد حالة تشغيلية حقيقية يمكن حذفها لاختبار reversal كامل دون إنشاء Test Data.

تمت محاولة بناء fixture transactional آمنة، لكن أدوات التنفيذ رفضت إدخال/حذف Test Data مباشرة في Production ضمن هذا السياق. لم يتم التحايل على هذا الحاجز بإدخال بيانات دائمة.

لذلك:

- Authorization / Deployment / DB Contract = مثبتة.
- Full live reversal on an actual Invoiced order = غير مثبتة بعد.
- Browser E2E = غير مثبتة.

وهذا يمنع إعلان Full Closure.

## 12. Test Attempts / Failures

### Failure A
محاولة اختبار Transaction بدأت بصيغة PL/pgSQL غير صحيحة (`DECLARE` خارج block).

النتيجة: لم يحدث أي Production mutation.

### Failure B
Fixture test حاول إدخال `order_details.line_amount` يدويًا.

Production أثبتت أن `line_amount` Generated Column.

النتيجة: تم تصحيح منهج الاختبار، وليس تعديل الـSchema.

### Failure C
محاولة DML مباشرة لإنشاء fixture كاملة تم حظرها من طبقة الأمان.

النتيجة: لم نلوث Production.

هذه الإخفاقات ليست Runtime Failures في النظام؛ هي Test-Harness Failures.

## 13. Data Repair

لم يتم تنفيذ أي حذف أو تنظيف لبيانات Production في هذه الوحدة.

السبب: Production الحالية تحتوي أصلًا على `0` Orders و`0` Invoiced POS orders، وبالتالي لا توجد بيانات تشغيلية متضررة تحتاج إلى إصلاح ضمن هذا العقد.

## 14. Main5 Source Instructions — DO NOT APPLY Report81 Blindly

لا تنفذ تعليمات Report81 القديمة التي تحذف `Invoiced` من UI.

نفذ بدلًا منها التعديل الجراحي التالي فقط.

### M5-20-A — RW_Orders._renderTable

**ابحث عن هذا المقطع كاملًا، وانتهاؤه هو السطر الأخير الذي يبدأ بـ `var canDelete =` وينتهي بـ `!o.runsheet_id;`:**

```js
// ✅ تعديل: إضافة Invoiced للحالات التي يمكن حذفها (طالما لا يوجد runsheet_id)
console.log('DEBUG_DELETE:', o.order_code, o.order_status, o.runsheet_id);
var canDelete = (o.order_status === 'Draft' || o.order_status === 'Confirmed' || o.order_status === 'Invoiced') && !o.runsheet_id;
```

**احذف المقطع الثلاثي كاملًا، ثم استبدله بالكامل بهذا المقطع:**

```js
var currentUser = (typeof RW_STATE !== 'undefined' && RW_STATE.app) ? RW_STATE.app.currentUser : null;
var permissions = (currentUser && Array.isArray(currentUser.permissions)) ? currentUser.permissions : [];
var canDeleteInvoiced = !!(currentUser && (currentUser.isOwner === true || permissions.indexOf('*') !== -1 || permissions.indexOf('general_manager') !== -1 || permissions.indexOf('sales_manager') !== -1 || permissions.indexOf('sales_supervisor') !== -1));
var canDelete = (o.order_status === 'Draft' || o.order_status === 'Confirmed' || o.order_status === 'Pending' || (o.order_status === 'Invoiced' && canDeleteInvoiced)) && !o.runsheet_id;
```

### M5-20-B — إزالة Debug

**ابحث عن هذا السطر كاملًا، وهو ينتهي بـ `);`:**

```js
console.log('DEBUG_DELETE:', o.order_code, o.order_status, o.runsheet_id);
```

**احذف السطر كاملًا ولا تترك أي جزء منه.**

### M5-20-C — RW_Orders._showDetails

**ابحث عن هذا المقطع كاملًا، وانتهاؤه هو السطر الأخير الذي يبدأ بـ `var canDelete =` وينتهي بـ `cannotDeleteStatuses.indexOf(order.order_status) === -1;`:**

```js
// ✅ زر حذف الأوردر – يظهر لـ Draft، Pending، Confirmed غير المرتبطة برانشيت
// ✅ تعديل: إضافة Invoiced واستبعاد Returned/Partially Returned
var cannotDeleteStatuses = ['Returned', 'Partially Returned', 'Cancelled'];
var isDeletable = (order.order_status === 'Draft' || order.order_status === 'Pending' || order.order_status === 'Confirmed' || order.order_status === 'Invoiced');
var canDelete = isDeletable && !order.runsheet_id && cannotDeleteStatuses.indexOf(order.order_status) === -1;
```

**احذف المقطع الخماسي كاملًا، ثم استبدله بالكامل بهذا المقطع:**

```js
// ✅ حذف Invoiced من النظام الأم متاح فقط للمستخدم المصرح له تاريخيًا.
var currentUser = (typeof RW_STATE !== 'undefined' && RW_STATE.app) ? RW_STATE.app.currentUser : null;
var permissions = (currentUser && Array.isArray(currentUser.permissions)) ? currentUser.permissions : [];
var canDeleteInvoiced = !!(currentUser && (currentUser.isOwner === true || permissions.indexOf('*') !== -1 || permissions.indexOf('general_manager') !== -1 || permissions.indexOf('sales_manager') !== -1 || permissions.indexOf('sales_supervisor') !== -1));
var isDeletable = (order.order_status === 'Draft' || order.order_status === 'Pending' || order.order_status === 'Confirmed' || (order.order_status === 'Invoiced' && canDeleteInvoiced));
var canDelete = isDeletable && !order.runsheet_id;
```

**لا تعدل أي مكان آخر في `main5.md` في هذه الوحدة.**

## 15. What Must Happen After Manual Source Application

بعد أن يطبق المستخدم التعديلات الثلاثة:

1. اقرأ `main5.md` من أول سطر إلى EOF.
2. تحقق من عدم وجود `DEBUG_DELETE`.
3. تحقق من بقاء `Invoiced` في المسارين ولكن بشرط الصلاحية.
4. تحقق من الأقواس والـquotes وإغلاق الـfunctions.
5. تحقق من عدم وجود direct stock writes في main5.
6. تحقق من Consumer path إلى `/functions/v1/delete-order`.
7. أعد Production snapshot.
8. أعد فحص deployment v9.
9. عند توفر فاتورة Invoiced POS حقيقية، نفذ runtime verification كامل للحذف والعكس.

## 16. Alternatives Rejected

تم رفض:

- حذف `Invoiced` من الواجهة بالكامل.
- إعادة استخدام الـOriginal مباشرة.
- الكتابة المباشرة إلى `stock_branches` من Edge.
- فتح EXECUTE للـauthenticated على `delete_order_atomic`.
- إعطاء الكاشير صلاحية الحذف المنفذ.
- إنشاء permission key جديد غير موجود في العقد الحالي لمجرد حل الشاشة.

## 17. What Was Proven

- التاريخ يثبت أن حذف `Invoiced` ليس Capability مخترعة الآن.
- Current main5 كان يحافظ على هذه القدرة.
- Production القديمة كانت قد أسقطت القدرة من backend.
- تم بناء capability Production جديدة متوافقة مع المعمارية الحالية.
- Physical Stock reversal يمر عبر `post_stock_movement`.
- Accounting reversal يمر عبر `post_journal_entry`.
- Customer/Driver ledger reversal يمر عبر الـledger engines الحالية.
- Backend authorization مفصول عن UI ومغلق افتراضيًا أمام authenticated/anon.
- Edge v9 منشور Active.
- main5 لم يتغير.

## 18. What Was Not Proven

- Live successful deletion of an actual Invoiced POS order in current Production.
- Full browser E2E.
- Full realtime UI reaction after a live Invoiced deletion.

## 19. Final Status

```text
Historical Contract = RECONCILED
Production Core Capability = IMPLEMENTED
Production DB = VERIFIED
Production Edge = DEPLOYED
Git Edge Source = ALIGNED
Git Canonical Migration = RECORDED
main5 Source = OPEN / USER PATCH REQUIRED
Runtime Full Invoiced Deletion = OPEN
Browser E2E = OPEN
MAIN5 FINAL RELEASE = OPEN
```

## 20. Next Authorized Action

المستخدم يطبق فقط M5-20-A/B/C أعلاه على `Current/PWA/main2/main5.md`.

بعد ذلك تتم إعادة القراءة من SOF إلى EOF وإجراء reconciliation جديد مع Production.

لا يجوز إعادة تطبيق Report81 بعد هذا التقرير؛ هذا التقرير هو أحدث reconciliation لأنه أعاد فتح العقد التاريخي من المصدر الأصلي وربطه بProduction الحالية.
