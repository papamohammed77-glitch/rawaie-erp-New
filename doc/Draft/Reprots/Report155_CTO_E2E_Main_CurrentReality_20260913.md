# Report155 — CTO E2E للنظام الأم — Current Reality / Items / Warehouse / Detailed Reports

**التاريخ:** 2026-09-13  
**الغرض:** تحديث الحالة الفعلية بعد إعادة التحقيق من CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE، وعدم إعادة إصلاح ما ثبت أنه صحيح بالفعل.  

# 0. الهدف الحاكم — نقطة يجب قراءتها بعناية

**الهدف هو اختبار E2E لملف النظام الأم الحالي:**

`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

وهو Source of Truth الحالي للواجهة المنشورة. ملفات `Current/PWA/main2/*` و`Original/PWA/main/*` والتقارير السابقة بقيت استرشادية/تاريخية فقط.

الهدف النهائي ليس مجرد وجود شاشات، بل اكتمالها وظيفيًا بما يحافظ على دورة حياة المخزون والأوردر والرانشيت والتطبيقات المنفصلة، ويصل بالنظام إلى مستوى Gold/Diamond دون ترقيع أو كسر عقود سابقة مثبتة.

# 1. إعادة بناء Current Git

تمت مراجعة الفرع `main` في `erp-frontend`، ثم مراجعة HEAD وparent المباشر وعدم الاعتماد على CURRENT_STATE القديم.

```text
CURRENT HEAD
5bdb2863570085edd19265465937aea3c674b52c

DIRECT PARENT
02166a9f8e94ac0b2cc15257eb0aec8e039848bd

CURRENT main.html BLOB
2485901f759b88995ac80e1060883554b1177bbe
```

رسالة HEAD الحالية: `Update main.html`، وتم إنشاؤه في 2026-09-13 07:59:49Z.

الـparent المباشر كان `Update comment timestamp in main.html`، وكان قد أدخل regression نحوية؛ HEAD الحالي أصلح تلك النقاط بالفعل.

## النتيجة الحاكمة

Report154 أصبح STALE في جزئية Syntax/Login التي كان يعالجها. لا يجوز إعادة تطبيق replacement الخاص به.

المصدر الحالي يثبت الآن داخل `_renderTable()`:

```javascript
rowHtml += '<td ...>'
```

ويعيد قوس الإغلاق:

```javascript
    }
    function _sort(field) {
```

كما أن escaping في المواضع الحرجة أصبح بالصورة الصحيحة داخل المصدر الحالي.

# 2. forensic_main_assembly.yml

تم فتح الملف مباشرة.

الحالة الحالية صحيحة ولا تحتاج تعديلًا:

```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
assembly_status: reference_only; published_main_is_authoritative
```

القرار: **لا تعديل.**

# 3. Items — النتيجة الفعلية الحالية

تمت مراجعة المصدر المنشور مباشرة داخل منطقة `RW_Items`، ولم يظهر في الحالة الحالية فقد للوظائف التي ذُكرت سابقًا كفقد محتمل.

المثبت في المصدر الحالي:

- قائمة الأصناف والبحث بالاسم/الكود/الباركود.
- فلترة التصنيف والحالة.
- الفرز.
- أعمدة إجمالي المخزون ومخزون الفروع.
- حركة الصنف.
- مصفوفة الأرصدة حسب الفروع.
- فلترة المصفوفة.
- تصدير Excel.
- رفع/تحديث الأرصدة من CSV/XLS/XLSX.
- إدارة التصنيفات.
- إضافة/تعديل/حذف الصنف.
- تبويبات نموذج الصنف.
- الرصيد الافتتاحي.
- الحقول التسويقية والصورة.

## القرار

لا توجد حاليًا إصابة Frontend مثبتة في هذه الوظائف تستوجب تعديلًا في `main.html`. إعادة تعديلها ستكون إعادة إصلاح لما أصبح صحيحًا بالفعل.

# 4. Categories — السبب الحقيقي لفقد التصنيفات

تم فحص Production قبل أي تعديل.

في Company:

```text
00000000-0000-0000-0000-000000000001
```

كان عدد الأصناف 17، وكان جدول `categories` لا يمثل كل القيم المستخدمة في `items.category`، مع وجود `category_id = NULL` للأصناف.

تم إثبات أن كود الواجهة الحالي يستعلم عن التصنيفات بطريقة Company-scoped، وبالتالي لم يكن نقص العرض ناتجًا عن query ناقص في الواجهة.

## الإصلاح الفعلي في Production

تم تنفيذ إصلاح بيانات محكوم داخل Production:

1. إنشاء التصنيفات الرئيسية المفقودة المطابقة لقيم البيانات الفعلية.
2. ربط `items.category_id` بالـmaster عبر تطابق `company_id + category_name`.
3. بعد اكتشاف سجل متبقٍ، تم تحديده مباشرة:

```text
item_code = ITM-1057
name      = صنف تجريبي2
category  = تكنولوجيا
```

ثم تم إنشاء `تكنولوجيا` وربط الصنف بها.

## التحقق النهائي

```text
categories(company 1) = 5
items(company 1) = 17
items with unresolved non-null category and null category_id = 0
```

إذن مشكلة «مودال التصنيفات لا تظهر كل التصنيفات» ومشكلة قائمة التصنيف في الصنف الجديد أصبحت **Data Integrity issue مغلقة من ناحية Production data**، دون تعديل واجهة غير ضروري.

تم تسجيل الإصلاح في `audit_log` باستخدام `action='update'` بعد رفض المحاولة الأولى بقيمة action غير مسموح بها من الـCHECK constraint.

# 5. Branch Stock Matrix / Excel / Update Balances

المصدر الحالي يثبت وجود:

```text
Branch stock matrix
Branch filter
Excel export
CSV/XLS/XLSX upload
Bulk stock adjustment
Refresh بعد نجاح العملية
```

كما أن حركة الصنف الحالية تعتمد على:

```text
inventory_log
+ company_id
+ item_id
+ optional branch filter
+ physical movement type
+ user/reference
```

ولا يوجد دليل حالي يبرر إرجاع renderer قديم يعتمد على `stock_vouchers` بدل هذا المسار.

## القرار

لا تعديل Frontend مطلوب لهذه النقاط في الحالة الحالية.

# 6. التحويلات المخزنية — التحقيق الحالي

تم فتح المسار الحالي `RW_Warehouse.loadVoucherForm(type)` مباشرة.

### الفروع

الاستعلام الحالي Company-scoped:

```javascript
supabase.from('branches')
  .select('id, branch_code, name, branch_name')
  .eq('company_id', companyId)
  .eq('is_active', true)
```

Production تثبت وجود:

```text
Active branches in company 1 = 2
```

لذلك عدم ظهور قائمة الفروع لا يثبت حاليًا كعيب Backend أو query.

### المندوبون والسيارات

المصدر الحالي يحدد المندوبين ثم يستعلم عن السيارات النشطة المرتبطة بهم.

Production تثبت:

```text
Active direct-sales reps = 1
Active vehicles = 0
Active vehicles attached to direct-sales reps = 0
```

إذن عدم ظهور السيارات **بيانات صحيحة بالنسبة للحالة الحالية**: لا توجد سيارة Active فعلية يمكن للواجهة عرضها.

لا يجوز اختلاق سيارة في Production فقط لإسكات الشاشة.

### create-stock-voucher

الـEdge Function الحالي Production version 10، ويدعم:

```text
company context from auth user
operation_id / Idempotency-Key
rep_id
company-scoped branches
company-scoped identity
RPC create_manual_stock_voucher_atomic
```

وليس هناك دليل حالي يستدعي إعادة بناء واجهة التحويل من الصفر.

## القرار

لا تعديل Frontend لهذه النقطة في الوقت الحالي.

# 7. Manual Voucher / Physical Stock Contract

تمت مطابقة Production الحالية للدوال ذات الصلة.

العقد المركزي المثبت:

```text
PHYSICAL STOCK MOVEMENT
        ↓
post_stock_movement
        ↓
stock_branches + inventory_log
```

`post_manual_stock_voucher_atomic` يستخدم `post_stock_movement` ولا ينشئ محرك Physical Stock ثانٍ.

كما أن `post_inventory_adjustment_atomic` وعمليات المبيعات الحالية التي تمت مراجعتها تنتهي إلى `post_stock_movement`.

بالتالي لا يوجد مبرر لإعادة بناء محرك حركة مخزون موازٍ.

# 8. RECEIVE PURCHASE — Production closure

تمت مراجعة الحالة الحية وليس النسخة التاريخية.

Production الحالية تحتوي على:

```text
receive_purchase_atomic(
  p_company_id,
  p_po_code,
  p_user_email,
  p_items,
  p_operation_id uuid
)
```

والـschema يحتوي:

```text
receiving.operation_id UNIQUE
```

تم تثبيت عملية الاستلام على `operation_id` صريح، بحيث تصبح هوية العملية مستقلة عن `qty_received` الحالي، ويتم فحص duplicate قبل السماح بحركة جديدة.

الـEdge Function `receive-purchase` الحالي Production version 12 يرسل `p_operation_id` ويقبل:

```text
body.operation_id
أو
Idempotency-Key
```

والـfrontend الحالي `main.html` **يرسل بالفعل**:

```javascript
var receiveOperationId = (crypto && crypto.randomUUID) ? crypto.randomUUID() : ...;
```

ثم:

```text
Idempotency-Key = receiveOperationId
operation_id    = receiveOperationId
```

لذلك لا يوجد حاليًا سبب لطلب تعديل هذا الجزء من `main.html`؛ الاقتراح السابق بإضافته أصبح STALE وتم رفض إعادة تطبيقه.

لا يوجد Purchase Order فعلي حالي في Production يسمح باختبار استلام إيجابي دائم دون إنشاء بيانات تشغيلية جديدة، لذلك لم يتم تلويث Production باختبار دائم.

# 9. Detailed Reports — التحقيق في Cannot read properties of undefined (reading 'length')

تم فتح `RW_Reports_Comprehensive._generateReport()` والمناطق التابعة له مباشرة.

في المسارات التي تمت مراجعتها، توجد حواجز صريحة مثل:

```javascript
data = r.data || [];
```

و:

```javascript
Array.isArray(balance17)
```

و:

```javascript
(receivingRes14.data || [])
```

وغيرها من أنماط حماية المصفوفات قبل `.length` و`.map`.

وبذلك لم يتم العثور في المصدر الحالي المفحوص على عنصر محدد يمكن إثباته كسبب وحيد لرسالة:

```text
Cannot read properties of undefined (reading 'length')
```

دون تنفيذ Browser E2E أو الحصول على stack trace حالي يحدد الفرع الذي ينفذ أثناء الخطأ.

## القرار الحاكم

لم يتم اختراع replacement للواجهة في هذه النقطة.

هذا ليس «توقفًا عن الحل»، بل رفض لملء فجوة الأدلة بتخمين. الـclosure الصحيح يحتاج:

```text
CURRENT browser stack trace
→ exact reportId
→ exact failing expression
→ reproduction
→ surgical fix
```

# 10. Production changes executed in this session

تم تنفيذ/تثبيت ما ثبتت ضرورته فقط:

### A. Category data repair

```text
Production data repair = DONE
```

مع audit record.

### B. receive_purchase_atomic contract

```text
Production migration = APPLIED
operation_id explicit
idempotency identity decoupled from mutable qty_received
```

### C. لم يتم تعديل أي Physical Stock writer بطريقة منفصلة

لأن المركزية الحالية مثبتة بالفعل.

# 11. Errors / failed attempts

### Category audit logging

المحاولة الأولى استخدمت `action='data_repair'`، ورفضها Production لأن `audit_log.action` يقبل مجموعة actions محددة. تم إعادة العملية بـ`action='update'` ونجحت.

### Purchase receive synthetic test

المحاولة التجريبية الأولى لم تكن دليلًا كافيًا على idempotent retry؛ تم رفض اعتبارها PASS، ثم تم إعادة تصميم العملية اعتمادًا على `operation_id` صريح موجود أصلًا في عقد receiving.

هذه المحاولة الفاشلة **لم تُعتبر Runtime PASS ولم تُستخدم كحقيقة تشغيلية**.

# 12. Security / advisory evidence

Supabase security advisors الحالية تُظهر تحذيرات مستقلة عن هذا closure، منها SECURITY DEFINER functions قابلة للتنفيذ من `anon` أو `authenticated` في بعض الوظائف، بالإضافة إلى `auth_leaked_password_protection` غير مفعّل.

هذه النتائج مهمة أمنيًا لكنها ليست سببًا مثبتًا لمشكلات Items/Transfers/Reports المذكورة هنا، ولذلك لم يتم توسيع نطاق هذا closure إليها دون evidence specific.

# 13. What was deliberately NOT modified

```text
erp-frontend/companies/company-1/main.html
Current/PWA/main2/*
Original/PWA/main/*
forensic_main_assembly.yml
```

لم يتم تعديل `main.html` لأن هذا الملف Owner-only حسب قاعدة المهمة.

لم يتم إعادة تطبيق Report154 أو Report153 لأن الحالة الحالية في Git تقدمت وتحتوي الإصلاحات اللازمة التي لا يجوز تكرارها.

# 14. Owner surgical modifications — الحالة النهائية

**لا يوجد حاليًا replacement إضافي مثبت وضروري لـ`main.html` في النقاط الأربع المذكورة: Categories / Matrix+Excel+Update / Transfers / Receive Purchase.**

بالنسبة لـDetailed Reports:

```text
No exact owner replacement yet.
```

السبب: لا يوجد في source الحالي المفحوص expression محدد تم إثباته كسبب للـ`undefined.length`.

لا توجد تعليمات من نوع «ابحث عن شيء يشبه...»؛ لأن ذلك يخالف منهجية التحديد الدقيق ويعيد الخطأ إلى التخمين.

# 15. E2E status

لا تتوفر في هذه البيئة أداة Browser Automation حقيقية لتنفيذ:

```text
fresh incognito
→ login
→ click tabs
→ open modals
→ inspect console
→ reproduce report error
```

لذلك:

```text
Browser E2E PASS = NOT CLAIMED
```

وهذا لا يساوي فشل النظام؛ بل يعني أن المرحلة الحالية هي forensic/static/runtime evidence دون browser execution.

# 16. FINAL CTO VERDICT

```text
CURRENT GIT = VERIFIED
CURRENT HEAD = 5bdb2863570085edd19265465937aea3c674b52c
CURRENT PARENT = 02166a9f8e94ac0b2cc15257eb0aec8e039848bd
CURRENT MAIN SOURCE = VERIFIED
FORENSIC ASSEMBLY = VERIFIED
ITEMS FEATURE LOSS = NOT PROVEN IN CURRENT SOURCE
ITEMS RENDERER REGRESSION = ALREADY FIXED IN CURRENT HEAD
ITEMS CATEGORY DATA GAP = FIXED IN PRODUCTION
CATEGORY MASTER COVERAGE = 5 categories / 17 items / 0 unresolved category links
BRANCH MATRIX = PRESENT
EXCEL IMPORT/EXPORT = PRESENT
WAREHOUSE TRANSFER UI QUERY = PRESENT + COMPANY SCOPED
ACTIVE BRANCHES = 2
ACTIVE DIRECT SALES REPS = 1
ACTIVE VEHICLES = 0
PHYSICAL STOCK CENTRALIZATION = VERIFIED
RECEIVE PURCHASE OPERATION ID = FIXED/DEPLOYED IN PRODUCTION
DETAILED REPORT undefined.length ROOT CAUSE = NOT YET PROVEN
BROWSER E2E = NOT CLAIMED
GOLD/DIAMOND = OPEN
```

# 17. What was initially missed / corrected in reasoning

1. The previous state of `CURRENT_STATE.md` was stale and still described HEAD `02166a9`; the live source had already advanced to `5bdb286` and fixed the syntax gate.
2. The proposed frontend receive-operation fix had already been implemented in the current `main.html`; repeating it would have been a regression in process, even if the code change itself was reasonable historically.
3. The missing Categories problem was caused by Production master-data incompleteness, not by an incomplete frontend query.
4. The missing cars problem is currently explained by Production containing zero active vehicles; creating UI code to hide that fact would be wrong.

# 18. NEXT CTO / ASSISTANT — mandatory start sequence

ابدأ من هذه الخطوات ولا تتجاوزها:

```text
1. اقرأ HEAD الحقيقي من Git.
2. افتح parent المباشر.
3. افحص diff بين HEAD وparent.
4. افتح CURRENT main.html من ref=main.
5. لا تستخدم Report154/153 كحالة حالية؛ استخدمهما لفهم التاريخ فقط.
6. افحص CURRENT Production في نفس لحظة التقرير.
7. افحص CURRENT Database/schema/RPCs/triggers/permissions.
8. افحص CURRENT deployment evidence للـEdge Functions.
9. عند أي defect: حدّد exact function + exact expression + exact runtime evidence.
10. قبل التعديل، أثبت هل هو Regression أم Capability جديدة.
11. إن كان Owner-only frontend: أعطِ المالك block كاملًا ببداية ونهاية واضحتين ورقم السطر الحالي، ولا تلمس الملف بنفسك.
12. إن كان Production defect مثبتًا: أصلحه مباشرة في Production.
13. اختبر الإصلاح على المسار الفعلي، ولا تعتبر synthetic/no-op test دليلًا على browser PASS.
14. أعد مزامنة Production قبل كل نسبة أو تقرير جديد.
15. لا تعيد إصلاح ما ثبت أنه موجود بالفعل في CURRENT HEAD/Production.
16. أي Unknown أو Conflict أو Unverified Claim مؤثر يمنع 100% Closure.
17. لا تنتقل للـclosure التالي قبل إغلاق الحالي 100%، أو توثيق سبب إبقائه OPEN بالدليل.
18. في E2E للنظام الأم: استخدم دائمًا المصدر المنشور `companies/company-1/main.html` كـSource of Truth، ولا تعود إلى fragments القديمة إلا لفهم تاريخ contract.
19. قبل إعلان Gold/Diamond: تحقق من UI completeness + workflow completeness + runtime + browser E2E + data integrity + authorization.
```

# 19. Closure status

```text
CURRENT TRUTH RECONSTRUCTION = COMPLETE
CATEGORY DATA REPAIR = COMPLETE
RECEIVE PURCHASE OPERATION ID = COMPLETE
ITEMS NAMED ISSUES = CURRENTLY NOT REQUIRING FRONTEND PATCH
TRANSFER DATA AVAILABILITY = EXPLAINED FROM CURRENT PRODUCTION
DETAILED REPORTS ROOT CAUSE = OPEN / REPRODUCTION REQUIRED
BROWSER E2E = OPEN
FULL SYSTEM GOLD/DIAMOND = OPEN
```
