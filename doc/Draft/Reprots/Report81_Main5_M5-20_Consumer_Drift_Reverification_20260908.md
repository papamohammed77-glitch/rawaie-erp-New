# RAWAEA ERP — Report81
## Main5 M5-20 Consumer Contract Drift — إعادة التحقيق والتحقق الجنائي

**التاريخ:** 2026-09-08  
**المستودع:** `papamohammed77-glitch/rawaie-erp-New`  
**الفرع:** `main`  
**Production:** `SMART ERP / fiilmooggumokxanwiyx`  
**الهدف:** `Current/PWA/main2/main5.md`

## 1. نقطة البداية الفعلية

لم تبدأ الجلسة من الصفر.
تمت مراجعة حالة المشروع المعلنة ثم إعادة إثباتها من Git وProduction والمصدر الحالي.

تمت مراجعة:

- `CURRENT_STATE.md`
- Report80
- Report79
- `MASTER - RAWAEA ERP FORENSIC CONTINUITY GOVERNANCE v2.md`
- `MASTER - RAWAEA ERP - UNIFIED CONTINUITY & MAIN1 EXECUTION.md`
- `MASTER - RAWAEA ERP.md`
- `Current/PWA/main2/main5.md`
- Production deployments ذات الصلة، وبالأخص `delete-order`
- Production database snapshot الحالي

المبدأ الحاكم الذي تم الالتزام به هو أن الحالة الحالية لا تثبت بالتقرير وحده؛ بل بإعادة التحقق من Git وProduction والـruntime/metadata حيثما ينطبق.

## 2. Current Git reconciliation

آخر HEAD في `main` عند بداية هذه المراجعة كان:

```text
a80d0709e94e5a04c642db2ffe4ad74b42fa2afa
```

وهو commit خاص بتحديث `CURRENT_STATE.md` بعد Report80، وليس تعديلًا على `main5.md`.

والـparent المباشر:

```text
bece3c2e58b0e5c3d75a5b490ed6ec8f1a91cd03
```

وهو commit Report80.

Blob الحالي المثبت لـ`main5.md` بقي:

```text
9f9926511c47f0295019daaf09ff4b5a1a2efc50
```

وبالتالي لا يوجد دليل على أن M5-20 عولج في المصدر منذ Report80.

## 3. إعادة قراءة main5

تمت قراءة `main5.md` عبر نطاقات متتابعة من بداية الملف حتى EOF، مع فحص النوافذ ذات الصلة بـ:

- `RW_Orders._renderTable`
- `_delete(code)`
- `RW_Orders._showDetails`
- `RW_Runsheets`
- M5-13 mutation routing

وتم الوصول إلى EOF فعليًا.
آخر بنية الملف ما زالت منتهية بإغلاق `RW_Runsheets` ثم:

```javascript
window.RW_Runsheets = RW_Runsheets;
```

لم يظهر أثناء هذه المراجعة direct writer إضافي ضمن نطاق M5-13 على:

```text
runsheets.update
runsheets.delete
run_sheet_details.delete
orders.update
```

وبالتالي M5-13 لم يُعاد فتحه.

## 4. Production reconciliation — قبل اعتماد أي نتيجة

تمت إعادة قراءة Production مباشرة عند:

```text
2026-09-08 02:49:23.779943+00
```

والحالة:

```text
companies = 1
users = 24
branches = 2
items = 17
orders = 0
runsheets = 0
order_details = 0
run_sheet_details = 0
stock_branches = 20
inventory_log = 3
```

هذه البيانات متوافقة مع snapshot السابق، ولم يظهر أي Order أو Runsheet تشغيلي جديد يمكن أن يبرر إعادة فتح M5-13 أو تنفيذ Browser E2E حقيقي.

## 5. Production delete-order contract

تمت إعادة التحقق من `delete-order` المنشورة حاليًا.
العقد التشغيلي الحالي يرفض الحذف عندما تكون حالة الأوردر:

```text
Invoiced
```

ويسمح بمسار الحذف للحالات:

```text
Draft
Confirmed
Pending
```

وعليه فالسماح لـ`Invoiced` في UI هو Consumer/Backend Contract Drift حقيقي، وليس خلافًا تجميليًا.

## 6. M5-20 — Root Cause المثبت

المشكلة موجودة في `main5.md` نفسها.
في جدول الأوردرات توجد إضافة تاريخية تسمح بـ`Invoiced` ضمن `canDelete`، كما يوجد Debug log.
وفي مودال التفاصيل يوجد شرط ثانٍ يسمح بـ`Invoiced`.

وهذه هي النقاط الثلاث نفسها التي حددها Report80، وما زالت موجودة في المصدر الحالي.

لا توجد أدلة حالية تبرر تعديل Production `delete-order` للسماح بـ`Invoiced`.

القرار الصحيح في هذه اللحظة هو توحيد UI مع Production، وليس إضعاف الـbackend guard.

## 7. M5-20-A — التعديل الجراحي الأول

ابحث حرفيًا عن هذا السطر الكامل:

```javascript
var canDelete = (o.order_status === 'Draft' || o.order_status === 'Confirmed' || o.order_status === 'Invoiced') && !o.runsheet_id;
```

احذف **هذا السطر كاملًا حتى علامة `;` في نهايته**.

استبدله حرفيًا بـ:

```javascript
var canDelete = (o.order_status === 'Draft' || o.order_status === 'Confirmed' || o.order_status === 'Pending') && !o.runsheet_id;
```

لا تحذف السطر الذي بعده:

```javascript
if (canDelete) {
```

## 8. M5-20-B — التعديل الجراحي الثاني

ابحث حرفيًا عن هذا السطر الكامل:

```javascript
console.log('DEBUG_DELETE:', o.order_code, o.order_status, o.runsheet_id);
```

احذف **هذا السطر كاملًا حتى علامة `;` في نهايته**.

لا تستبدله بأي سطر آخر.

## 9. M5-20-C — التعديل الجراحي الثالث

في `RW_Orders._showDetails` ابحث حرفيًا عن **المقطع الكامل التالي**:

```javascript
var cannotDeleteStatuses = ['Returned', 'Partially Returned', 'Cancelled'];
var isDeletable = (order.order_status === 'Draft' || order.order_status === 'Pending' || order.order_status === 'Confirmed' || order.order_status === 'Invoiced');
var canDelete = isDeletable && !order.runsheet_id && cannotDeleteStatuses.indexOf(order.order_status) === -1;
```

احذف **الأسطر الثلاثة كاملة**.
آخر سطر في المقطع الذي يجب حذفه هو كاملًا:

```javascript
var canDelete = isDeletable && !order.runsheet_id && cannotDeleteStatuses.indexOf(order.order_status) === -1;
```

واستبدل الأسطر الثلاثة بمقطع مكوّن من السطرين التاليين حرفيًا:

```javascript
var isDeletable = (order.order_status === 'Draft' || order.order_status === 'Pending' || order.order_status === 'Confirmed');
var canDelete = isDeletable && !order.runsheet_id;
```

## 10. ما لا يجب تعديله

لا تعدل في `main5.md` أي موضع آخر في هذه الخطوة.
خصوصًا:

- لا تضف `Invoiced` مرة أخرى.
- لا تحذف `Pending`.
- لا تعدل `_delete(code)` في هذه الخطوة.
- لا تعدل M5-13.
- لا تعدل Realtime subscriptions الحالية.
- لا تضف `company_id` إلى `run_sheet_details` داخل هذه الوحدة.
- لا تغيّر صلاحيات `delete-order` في Production.

## 11. لماذا هذا الحل هو الصحيح

العقد الفعلي المثبت حاليًا هو:

```text
UI Delete eligibility
        ↓
delete-order
        ↓
Production contract
```

والـbackend هو صاحب الحماية النهائية.

التعديل المطلوب ليس ترقية صلاحية جديدة ولا اختراع مسار حذف لفاتورة منفذة، بل إزالة Consumer drift حتى لا تعرض الواجهة إجراءً تعرف Production مسبقًا أنه مرفوض.

القرار التاريخي الذي سمح بفكرة حذف `Invoiced` لإعادة الأوردر إلى ما قبل الإنشاء لم يعد متوافقًا مع عقد Production الحالي المثبت. لذلك لا يجوز استحضاره لتبرير إعادة إدخال `Invoiced` في واجهة المستخدم دون Contract جديد مثبت من النظام نفسه.

## 12. الاختبارات والتحقق

### ما تم إثباته

- `main5.md` لم يتغير منذ Report80.
- M5-13 ما زال routed إلى `manage-runsheet`.
- `main5.md` وصل فعليًا إلى EOF.
- نقطة M5-20-A ما زالت تحتوي `Invoiced`.
- Debug line الخاصة بـM5-20-B ما زالت موجودة.
- نقطة M5-20-C ما زالت تحتوي `Invoiced`.
- Production `delete-order` ما زال يحمي من حذف `Invoiced`.
- Production snapshot الحالي لا يحتوي Orders/Runsheets تشغيلية.

### ما لم يتم إثباته بعد

- نجاح syntax/structure بعد تطبيق M5-20 لأن التعديل لم يُجرَ بعد في المصدر.
- Browser E2E حقيقي بعد التعديل؛ لا توجد بيانات تشغيلية في Production تسمح به دون إنشاء بيانات اختبار.
- إغلاق M5-20 نفسه؛ ما زال يحتاج تطبيق التعديلات الثلاثة ثم إعادة فحص المصدر كاملًا.

## 13. الأخطاء / الإخفاقات التي يجب حفظها

لا يوجد فشل Production جديد في هذه الوحدة.

لكن تم تثبيت failure mode مهم من ناحية الاستمرارية:

```text
Report80 identifies M5-20
→ source remains unchanged
→ current reconciliation must rediscover the same defect
```

الدرس:

لا تعتبر "Exact patch provided" مساويًا لـ"Source applied".

كما لا تعتبر وجود تعديل تاريخي يفسر `Invoiced` مساويًا لعقد Production الحالي.

ولا يجوز إعادة استخدام عبارة CLOSED قبل تحقق المصدر والـProduction والـruntime المناسب.

## 14. ما تم تغييره فعليًا في هذه الجلسة

```text
Current/PWA/main2/main5.md = NOT MODIFIED
Production delete-order = NOT MODIFIED
Production database data = NOT MODIFIED
```

تمت إضافة هذا التقرير فقط.
وسيتم تحديث `CURRENT_STATE.md` بعد تسجيل التقرير.

## 15. Final Self-Audit

### What I Proved

- تم استرجاع الحالة من `CURRENT_STATE.md` ثم إعادة مطابقتها مع Git.
- تمت مراجعة Report80 وReport79.
- تمت قراءة ملفات الاستمرارية الثلاثة المطلوبة.
- تمت مراجعة `main5.md` حتى EOF.
- تمت إعادة إثبات بقاء M5-13 مغلقًا في المصدر.
- تمت إعادة إثبات M5-20 كمشكلة Consumer/Backend حقيقية.
- تمت إعادة قياس Production مباشرة.
- تم التحقق من عدم الحاجة إلى تعديل Production لهذه الوحدة.
- تم تحديد التعديلات الثلاثة المطلوبة حرفيًا دون غموض.

### What I Did Not Prove

- لم يتم تطبيق M5-20 في المصدر لأن البروتوكول ينص على أن المستخدم ينفذ تعديلات الأجزاء الـ11.
- لم يتم تنفيذ Browser E2E بسبب عدم وجود Orders/Runsheets في Production.
- لم يتم إعلان MAIN5 مغلقًا.

### What Could Still Be Wrong

بعد تطبيق M5-20 قد يظهر defect مستقل عند إعادة قراءة الملف الكامل. لذلك إعادة القراءة الكاملة والـsyntax/structure/consumer scan ليست اختيارية؛ هي بوابة الإغلاق التالية.

## 16. Final Closure Status

```text
M5-13 BACKEND = CLOSED
M5-13 SOURCE = VERIFIED / APPLIED
M5-20-A = OPEN / EXACT SOURCE PATCH
M5-20-B = OPEN / EXACT SOURCE PATCH
M5-20-C = OPEN / EXACT SOURCE PATCH
MAIN5 SOURCE = OPEN
MAIN5 RUNTIME = OPEN
MAIN5 FINAL RELEASE GATE = OPEN
```

## 17. NEXT AUTHORIZED ACTION

المسار المصرح التالي فقط:

```text
USER APPLIES M5-20-A
↓
USER APPLIES M5-20-B
↓
USER APPLIES M5-20-C
↓
READ main5 FROM LINE 1 → EOF AGAIN
↓
SYNTAX / STRUCTURE SCAN
↓
DIRECT-WRITE SCAN
↓
CONSUMER / BACKEND CONTRACT SCAN
↓
FRESH PRODUCTION RECONCILIATION
↓
IF CLEAN → CLOSE M5-20
ELSE → OPEN THE NEXT PROVEN DEFECT
```

لا توجد خطوة أخرى معتمدة على `main5` قبل هذه البوابة.