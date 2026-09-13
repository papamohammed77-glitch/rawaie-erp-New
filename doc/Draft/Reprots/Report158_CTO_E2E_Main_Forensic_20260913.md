# Report158 — CTO Forensic E2E للنظام الأم ومطابقة الحالة الحالية — 2026-09-13

## 0. الهدف الحاكم — يُقرأ بعناية
**الهدف في هذه الجلسة هو التعامل مع ملف النظام الأم المنشور الحالي `erp-frontend/companies/company-1/main.html` باعتباره Source of Truth، والتحقق منه جنائيًا مقابل CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE، ثم إصلاح ما يثبت أنه خلل حقيقي فقط.**

لا يُعامل أي تقرير سابق باعتباره حالة حالية. Report157 والملفات التاريخية استُخدمت لتحديد أماكن التحقيق فقط، ثم أُعيد إثبات الحالة من Git وProduction وDatabase.

Source of Truth الحالي للواجهة:
`https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/main.html`

`Current/PWA/main2/*` و`Original/PWA/main/*` وNew-main = historical/reference فقط.

---

## 1. CURRENT GIT — تم التحقق من HEAD والـParent

Repository:
`papamohammed77-glitch/erp-frontend`

### HEAD الحالي
`3573c92026557cb56a7782babe6f6cf690243072`

الرسالة:
`Update main.html`

الوقت:
`2026-09-13T09:58:01Z`

### DIRECT PARENT
`28f39b351bb44a4cd885ba784d505aadaeb13cf1`

الرسالة:
`Update main.html`

الـparent غيّر فقط timestamp الظاهر في أعلى `main.html` في المسار الذي تم التحقق منه.

### ماذا غيّر HEAD الحالي؟
الـHEAD الحالي أصلح عيب Transfer المعروف من الحالة السابقة:

قبل:
```javascript
.select('id, branch_code, name, branch_name')
```

بعد:
```javascript
.select('id, branch_code, name')
```

كما أزيل الاعتماد على `branches[i].branch_name` من label.

**الاستنتاج:** العيب الذي كان موثقًا في Report157 لم يعد موجودًا في CURRENT GIT. إعادة إصلاحه الآن كانت ستصبح إعادة إصلاح لشيء مغلق بالفعل.

---

## 2. CURRENT SOURCE — الملف المنشور تم قراءته كاملًا حتى EOF

الملف الحالي:
`companies/company-1/main.html`

تمت قراءته عبر GitHub على دفعات حتى نهاية الملف، وآخر سطر فعلي تم الوصول إليه هو EOF عند السطر `35521`.

تمت مراجعة وظائف النظام الأم التي ترتبط مباشرة بـ:
- الملاحة والتبويبات.
- الإدارة المالية.
- التقارير.
- الموارد البشرية.
- CRM.
- الأصناف والمخزون والجرد.
- الأذونات والتحويلات.
- دورة الأوردر والرانشيت.
- قراءة المخزون من الفروع.
- مسار الاستلام والشراء.

### نتيجة مراجعة Transfer الحالية
الدالة:
`async function _loadVoucherEntityOptions(type)`

الـTransfer block في CURRENT SOURCE يستخدم:
```javascript
.select('id, branch_code, name')
```

ولا توجد حاجة لأي تعديل إضافي على هذا الجزء.

### لا يوجد Direct Physical Stock Writer في main.html
البحث في CURRENT SOURCE لم يجد:
```javascript
.from('stock_branches').update(...)
```

الـ`stock_branches` في النظام الأم تُستخدم للقراءة وتجميع البيانات، بينما الحركة الفعلية مركزية في Production Core.

---

## 3. FORENSIC ASSEMBLY — لا تعديل مطلوب

تم فتح:
`rawaie-erp-New/forensic_main_assembly.yml`

والحالة الحالية مثبتة كالتالي:
```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
assembly_status: reference_only; published_main_is_authoritative
```

**النتيجة:** المسار وSource of Truth صحيحان بالفعل، ولذلك لم يتم إجراء تعديل غير ضروري عليه.

---

## 4. CURRENT PRODUCTION / DATABASE — الحالة الحالية

Project:
`fiilmooggumokxanwiyx`

أحدث migration قبل هذا التحقيق كان:
`20260913082923`

وتم تنفيذ migration أمني جديد خلال هذه الجلسة:
`20260913101126 — 20260913_main_cto_security_surface_hardening`

### Production data المهم للنظام الأم
الشركة المرجعية:
`00000000-0000-0000-0000-000000000001`

الفروع النشطة للصنف 1001:
- `BR-01` — `الفرع الرئيسي` — رصيد `2`
- `BR-2` — `فرع إسكندرية` — رصيد `1`

الصنف:
- `1001` — `جو كيك 5ج`

ولا توجد بيانات Vehicle نشطة يمكن استخدامها لاختبار DirectSale/DirectReturn حاليًا؛ لا يجوز اختراع بيانات Production فقط لإنجاح الاختبار.

---

## 5. INVENTORY CORE — الفحص الجنائي للـWriters

تم فحص functions التي تشير إلى `stock_branches` أو `inventory_log` في Production.

### Physical Stock Writer الحقيقي
الوحيد الذي يقوم بالتحديث الفيزيائي للرصيد هو:
`post_stock_movement`

وهو ينفذ العقد:
```text
PHYSICAL STOCK MOVEMENT
        ↓
post_stock_movement
        ↓
stock_branches
+
inventory_log
```

### وظائف لا تُعد Physical Stock Writers
`reserve_stock`
- Reservation Engine فقط.
- لا تمثل حركة مخزون فعلية.

`release_stock_reservation`
- Reservation release فقط.
- لا تمثل حركة مخزون فعلية.

`setup_van_stock`
- إنشاء صفوف stock أولية لفرع سيارة.
- لا تسجل Physical Movement ولا تنشئ Inventory Movement Event.

`create_vehicle_atomic`
- يهيئ صفوف stock الخاصة بالسيارة عند إنشاء الفرع/السيارة.
- ليس Physical Movement Writer.

### Functions الأخرى
`post_inventory_adjustment_atomic`
- لا يكتب المخزون مباشرة.
- يستدعي `post_stock_movement`.

`post_manual_stock_voucher_atomic_core_20260828`
- لا يكتب المخزون مباشرة.
- يستدعي `post_stock_movement`.

`send_stock_voucher_atomic_core_20260828`
- لا يكتب المخزون مباشرة.
- يستدعي `post_stock_movement`.

`complete_runsheet_picking`
- يستخدم Reservation Engine فقط، وهو السلوك الصحيح في عقد Picking.

`complete_runsheet_reopen_loading`
- يعيد المخزون من خلال `post_stock_movement`.

### نتيجة Zero-Debt Writer Discovery
```text
Physical Stock Writers outside post_stock_movement = 0
```

**حالة Inventory Core: CLOSED من ناحية Physical Writer centralization وفق Production evidence الحالية.**

---

## 6. TRANSFER E2E — Production Transactional Test

تم تنفيذ اختبار Transaction حقيقي في Production على المسار:

```text
BR-01
  ↓
BR-2
  ↓
item 1001
  ↓
create_manual_stock_voucher_atomic
  ↓
send_stock_voucher_atomic
  ↓
post_stock_movement
  ↓
stock_branches + inventory_log
```

### النتائج
- CREATE: `success`
- SEND: `success`
- final status: `Sent`
- `movement_count = 1`
- إعادة SEND لنفس الإذن أعادت:
  `duplicate = true`

تم إجراء الاختبار داخل Transaction وتم تنفيذ:
`ROLLBACK`

ثم تمت مراجعة Production بعد ذلك وأصبح:
- `stock_vouchers` للإذن الاختباري = `0`
- `inventory_log` للإذن الاختباري = `0`

**النتيجة:** لا توجد بيانات اختبارية دائمة.

هذا يثبت أن Transfer Backend Core نفسه يعمل وأن idempotency لمسار SEND تعمل فعليًا في Production.

---

## 7. SECURITY HARDENING — Production تم إصلاحها فعليًا

تم اكتشاف في مراجعة Security الحديثة عدد من SECURITY DEFINER functions المفتوحة بأكثر من المستوى المطلوب.

تم تنفيذ migration:
`20260913101126_main_cto_security_surface_hardening`

### ما تم إغلاقه
تم سحب EXECUTE من `anon/authenticated` عن:
- `employee_hr_touch_updated_at()`
- `sync_company_main_branch_projection()`
- `create_item_with_opening_stock(...)`
- `get_enterprise_decision_center(...)`
- `post_financial_entry_atomic(...)`

كما تم تثبيت Search Path صريح لـ:
`employee_document_storage_company_id(text)`

### بعد الإصلاح
اختفى تحذير:
`function_search_path_mutable`

واختفت التحذيرات الخاصة بالـfunctions التي تم سحب صلاحياتها.

المتبقي حاليًا هو:
- Auth Leaked Password Protection = Disabled.
- 8 SECURITY DEFINER functions للمستخدمين المسجلين، وهي functions مقيدة بسياق المستخدم/الشركة أو تحتاج مراجعة مستقلة لاحقة، وليس من الصحيح تعطيلها دفعة واحدة دون دراسة Consumer contracts.

### القرار
**تم إغلاق العيب الأمني الذي ثبت أنه خارج العقد الحالي. ولم يتم تعطيل وظائف HR/CRM/Finance الحالية التي يتطلبها النظام الأم لمجرد أن الـlint يصنفها SECURITY DEFINER.**

---

## 8. RETAINED PRODUCTION DATA — لا توجد عملية تنظيف عمياء

ظهرت في Production سابقًا مؤشرات cross-company في `stock_branches` و`inventory_log`.

إعادة التدقيق أثبت أن Schema الحالي يجعل `items.item_code` UNIQUE على مستوى قاعدة البيانات، وأن `post_stock_movement` يعتمد على `item_id` ويقوم بفرض شركة الفرع المصدر/الهدف، بينما Item Master نفسه له عقد عالمي.

لذلك لا يجوز تحويل وجود item metadata لشركة أخرى إلى خطأ تلقائيًا ثم حذف الأرصدة دون إثبات أصلها.

تم اتخاذ القرار التالي:
- لا حذف.
- لا إعادة كتابة quantities.
- لا تغيير Company IDs.
- لا تنظيف تخميني.

تبقى المسألة **Data Forensics / Fixture Hygiene** مفتوحة إلى أن يوجد دليل تاريخي قاطع يثبت أنها بيانات اختبار يجب إزالتها.

---

## 9. CURRENT MAIN FUNCTIONALITY — ما هو موجود فعليًا

CURRENT MAIN يحتوي على وحدات فعلية وليست مجرد عناوين فقط في:

### المخزون والتشغيل
- الأصناف.
- الفروع والمخازن.
- الاستلام.
- التحضير.
- التحميل.
- التوصيل.
- المرتجعات.
- التفريغ.
- الأذونات المخزنية.
- تحويل مخزني.
- صرف مباشر.
- مرتجع مباشر.
- مرتجع مورد.
- الجرد.
- التسويات اليومية.

### المبيعات
- POS.
- Telesales.
- Order Taker.
- Van Sales.
- Online Store.
- Orders.
- Runsheets.

### المالية
- الخزائن والبنوك.
- دليل الحسابات.
- قيود اليومية.
- سندات القبض.
- سندات الصرف.
- التحويلات.
- التقارير المالية.

### التقارير
- Dashboard.
- Detailed Reports.
- Comprehensive Reports.

### الموارد البشرية
- Employee list.
- Attendance.
- Leave requests.
- Employee profiles / compensation.
- Employee documents.

### CRM
- Customer management.
- Follow-up.
- Assignment-related functionality.

**إذن: وصف هذه الوحدات بأنها “هيكل فقط” لم يعد صحيحًا بالكامل. بعضها أصبح functional فعليًا، لكن هذا لا يساوي اكتمال Gold/Diamond.**

---

## 10. GAP ANALYSIS — مقارنة حالية مع دفترة

تمت مراجعة القدرات الحالية المعلنة لدفترة بتاريخ هذا التحقيق.

دفترة يعلن ضمن منظومته الحالية قدرات تشمل، بالإضافة إلى الأساسيات:

### المبيعات
- الفواتير وعروض الأسعار.
- نقاط البيع.
- العروض.
- الأقساط.
- أهداف المبيعات والعمولات.
- التأمينات.
- الفاتورة الإلكترونية.

### العملاء / CRM
- متابعة العملاء.
- المواعيد.
- نقاط الولاء.
- العضويات والاشتراكات.
- النقاط والأرصدة.
- التأمينات.

### المخزون
- المنتجات.
- المشتريات.
- الموردين.
- دورة المشتريات.
- الأذون المخزنية.
- الجرد.
- قوائم الأسعار.
- التصنيع.
- تتبع المنتجات.

### الحسابات
- المصروفات.
- دليل الحسابات.
- مراكز التكلفة.
- دورة الشيكات.
- الأصول الثابتة.
- الضرائب.
- التقارير المالية.

### الموارد البشرية
- الهيكل التنظيمي.
- العقود.
- الحضور والانصراف.
- الرواتب.
- الطلبات.
- السلف.

### التشغيل
- أوامر الشغل.
- إدارة المشاريع.
- دورة العمل Workflow.
- الحجوزات.
- تتبع الوقت.
- الإيجارات والوحدات.
- التصنيع.

مصادر المراجعة:
- https://www.daftra.com/features/all_features
- https://www.daftra.com/
- https://www.daftra.com/en/features/all_features/
- https://www.daftra.com/features/sub_feature/11
- https://www.daftra.com/%D8%AF%D9%88%D8%B1%D8%A9-%D8%A7%D9%84%D8%B4%D9%8A%D9%83%D8%A7%D8%AA/
- https://www.daftra.com/%D8%A5%D8%AF%D8%A7%D8%B1%D8%A9-%D8%A7%D9%84%D8%A3%D8%B5%D9%88%D9%84/

### فجوات CURRENT MAIN المثبتة بالبحث النصي
لم نجد في CURRENT `main.html` واجهات أو functions واضحة لتشغيل:
- الشيكات.
- الأقساط.
- نقاط الولاء.
- أوامر الشغل.
- الأصول الثابتة.
- إدارة المصروفات كوحدة تشغيلية مستقلة.
- إدارة مراكز التكلفة كوحدة مستقلة للمستخدم.

كما أن CURRENT MAIN لا يعرض هذه البنود كقائمة مستقلة في الـnavigation.

### مقابل Production Database
Production تحتوي فعليًا على جداول لبعض هذه المجالات:
- `cheques` — 12 column.
- `installments` — 11 columns.
- `installment_details` — 8 columns.
- `loyalty_points` — 8 columns.
- `work_orders` — 13 columns.
- `workflows` — 7 columns.
- `workflow_rules` — 8 columns.
- `cost_centers` — 6 columns.
- `coupons` — 16 columns.

لكن البحث عن RPCs مباشرة لهذه الأسماء أعاد فقط routine واضحًا هو:
`get_pnl_by_cost_center(...)`

ولم يثبت وجود CRUD/transaction RPC canonical جاهز للأقساط/الشيكات/الولاء/أوامر الشغل بالقدر الذي يسمح ببناء واجهات آمنة الآن دون تخمين.

**الاستنتاج:** هناك Backend/Data Foundation لبعض هذه المجالات، لكن CURRENT MAIN لا يمثلها كقدرات تشغيلية كاملة، وProduction لا تثبت وجود Core Transactional Contracts جاهزة لكل مجال. لذلك بناء واجهات كاملة الآن من الصفر سيكون تخمينًا ومخالفة لمبدأ الحوكمة.

---

## 11. E2E حقيقة Browser مقابل E2E Backend

### تم إثباته
- CURRENT GIT = VERIFIED.
- HEAD + DIRECT PARENT = VERIFIED.
- CURRENT SOURCE = VERIFIED.
- CURRENT DB schema = VERIFIED.
- CURRENT DB data = VERIFIED.
- CURRENT Edge deployments = VERIFIED.
- Inventory Physical Writer centralization = VERIFIED.
- Transfer backend transaction = VERIFIED.
- SEND idempotency = VERIFIED.
- Security hardening migration = DEPLOYED + VERIFIED.

### لم يتم ادعاؤه
- Browser click-by-click E2E لا يمكن اعتباره PASS في هذه البيئة لأن لا توجد قناة Browser Automation هنا.
- لا يوجد دليل runtime من متصفح فعلي في نفس اللحظة بعد آخر نشر للمالك.

**القاعدة: لم يتم تحويل Backend PASS إلى Browser PASS.**

---

## 12. OWNER ACTION — لا يوجد إصلاح Transfer جديد مطلوب

Current HEAD أثبت أن العيب:
```javascript
.select('id, branch_code, name, branch_name')
```

تم إصلاحه بالفعل في CURRENT SOURCE.

لذلك:

**لا تحذف شيئًا من Transfer block الآن، ولا تعيد استبداله.**

هذا الجزء CLOSED في CURRENT GIT.

إذا ظهر الخطأ نفسه في المتصفح بعد هذا الـHEAD، فسيكون السؤال الوحيد وقتها هو:
**هل الصفحة التي تخدمها منصة النشر هي نفس commit `3573c92026557cb56a7782babe6f6cf690243072`؟**

ولا يجوز تعديل الكود مرة أخرى قبل مطابقة الـserved asset مع هذا الـcommit.

---

## 13. CURRENT SECURITY / PERFORMANCE RESIDUE

Security current:
- Auth Leaked Password Protection = Disabled.

Performance advisors الحالية:
- 64 unindexed foreign keys.
- 37 auth RLS initplan warnings.
- 31 unused indexes.
- 6 multiple permissive policy warnings.
- 1 duplicate index على `orders`.

هذه البنود لا يجوز تنظيفها دفعة واحدة في هذه المرحلة؛ يلزم تحويلها إلى Closure Units مستقلة وربط كل واحدة بمستهلك حقيقي وQuery Plan وConsumer evidence.

---

## 14. WHAT WAS ACTUALLY CHANGED IN THIS SESSION

### Production
تم تنفيذ migration واحدة:
`20260913101126_main_cto_security_surface_hardening`

Purpose:
- تقليص سطح EXECUTE على functions غير المطلوبة للـbrowser.
- تثبيت Search Path لـ`employee_document_storage_company_id`.

### Production data
- لا توجد تغييرات دائمة على business data.
- اختبارات Transfer تم تنفيذها داخل Transaction ثم Rollback.

### erp-frontend main.html
- **لم يتم تعديله آليًا**.
- CURRENT HEAD كان قد استبق هذا التحقيق وأغلق بالفعل Transfer `branch_name` defect.

### forensic_main_assembly.yml
- لا تغيير لأنه صحيح بالفعل.

### rawaie-erp-New/current historical fragments
- لا تغيير.

---

## 15. أخطاء التحقيق والتصحيحات

### خطأ/إرباك سابق من الحالة القديمة
Report157 وCURRENT_STATE السابقان كانا يشيران إلى HEAD قديم:
`5bdb286...`

أما CURRENT GIT الآن:
`3573c920...`

### النتيجة
كان من الممكن بسهولة إعادة تطبيق Transfer patch وإحداث دوامة “إصلاح ما تم إصلاحه”.
تم منع ذلك بالمطابقة المباشرة للـHEAD والـparent والـdiff.

---

## 16. FINAL SELF-AUDIT

### What I Proved
- قرأت Governance Master والـexecution prompt والـReport157 وCURRENT_STATE كمواد استرشادية.
- رفضت التقارير كـSource of Truth.
- طابقت HEAD الحالي مع DIRECT PARENT.
- قرأت CURRENT main.html حتى EOF.
- تحققت من Source of Truth وforensic assembly.
- تحققت من current Production DB.
- نفذت Production transactional transfer E2E.
- تحققت من duplicate SEND idempotency.
- أثبتت أن Physical Writers خارج `post_stock_movement` = 0 بعد classification.
- نفذت Security hardening حقيقيًا في Production.
- أعادت Security advisor review بعد التغيير.
- قارنت فجوات CURRENT MAIN مع القدرات المعلنة حاليًا في دفترة.

### What I Did Not Prove
- Browser click-by-click PASS.
- اكتمال Gold/Diamond لجميع المجالات المالية/HR/CRM/Operations.
- أن كل الجداول الحديثة لها transactional core صالح لبناء UI الآن.
- أن cross-company stock rows الموجودة في Production يجب حذفها؛ لا يوجد دليل قاطع كافٍ لذلك.

### What I Fixed
- Production security surface الذي ثبت أنه غير مطلوب للمستخدمين.
- Search path mutable function.

### What I Initially Missed During This Session
- CURRENT Git أصبح أحدث من Report157، وبالتالي Transfer defect موثق في التقرير القديم مغلق بالفعل في source الحالي.

### What Could Still Be Wrong
- served browser asset may not yet match latest Git HEAD.
- بعض الـadvanced DB tables لم تتحول بعد إلى Business Transactional APIs قابلة للاستخدام من main.
- Auth leaked-password protection ما زال غير مفعل.

### Final Confidence
- Inventory Core centralization: **HIGH / PRODUCTION VERIFIED**
- Transfer backend: **HIGH / PRODUCTION TRANSACTION VERIFIED**
- Transfer frontend current-source state: **HIGH / GIT VERIFIED**
- Browser runtime: **NOT VERIFIED**
- Global Gold/Diamond: **NOT CLOSED**

### Final Closure Status
```text
INVENTORY PHYSICAL WRITER ZERO-DEBT = CLOSED
TRANSFER BACKEND E2E = CLOSED
TRANSFER CURRENT SOURCE DEFECT = CLOSED IN GIT
SECURITY SURFACE FIX = DEPLOYED AND VERIFIED
BROWSER E2E = OPEN
ADVANCED ERP FUNCTIONAL COMPLETENESS = OPEN
GLOBAL GOLD/Diamond = OPEN
```

---

# 17. FINAL DIRECTIVE TO THE NEXT CTO / ASSISTANT

**لا تبدأ من التقرير. ابدأ من الواقع.**

هذا هو التسلسل الإلزامي:

```text
1) CURRENT GIT HEAD
   ↓
2) DIRECT PARENT
   ↓
3) PARENT OF PARENT عند وجود diff مؤثر
   ↓
4) CURRENT SOURCE OF TRUTH
   ↓
5) احسب/ثبت Current file SHA وEOF
   ↓
6) CURRENT PRODUCTION DATABASE SCHEMA
   ↓
7) CURRENT PRODUCTION DATA
   ↓
8) CURRENT EDGE DEPLOYMENTS + VERSION + SOURCE
   ↓
9) CURRENT RUNTIME / LOG EVIDENCE
   ↓
10) أعد إنتاج الخطأ الحقيقي
   ↓
11) حدد العنصر الدقيق: function / line / query / RPC / table / policy
   ↓
12) ارجع للتاريخ فقط لفهم CONTRACT ولماذا وصل الكود لهذه الصورة
   ↓
13) قارن CURRENT مقابل TARGET
   ↓
14) أثبت ACTUAL GAP
   ↓
15) Closure Unit واحدة فقط
   ↓
16) Surgical Fix
   ↓
17) أعد قراءة CURRENT SOURCE بعد التعديل
   ↓
18) Production Verification
   ↓
19) Runtime Verification
   ↓
20) Data Verification
   ↓
21) Audit / Security Verification
   ↓
22) Report + CURRENT_STATE
   ↓
23) انتقل للوحدة التالية فقط بعد إغلاق السابقة
```

### قواعد لا يجوز كسرها

- لا تثق بتقرير قديم كحالة حالية.
- لا تثق بذاكرة المساعد.
- لا تستخدم `main2` كـSource of Truth.
- لا تعيد إصلاح ما أثبته CURRENT GIT أنه مغلق.
- لا تنشئ بيانات Production وهمية لعمل E2E أخضر.
- لا تعدل Production إذا كانت Production نفسها قد أثبتت سلامة الـcore.
- لا تعالج عدة Writers في دفعة واحدة.
- لا تعتبر وجود جدول Backend دليلًا على اكتمال الـBusiness Capability.
- لا تعتبر وجود Menu item أو Modal دليلًا على Functionality.
- لا تبنِ Transaction Core من تخمين إذا لم يوجد Contract مثبت.
- لا تحوّل Backend verification إلى Browser PASS.
- أي نسبة اكتمال يجب أن ترتبط بلحظة Production محددة.
- كل Closure يجب أن يسجل: Historical / Production / Current / Target / Consumer / Data / Auth / Audit / Runtime.
- عند ظهور مشكلة، المسار الوحيد:

```text
FOUND
→ ROOT CAUSE
→ HISTORICAL CONTRACT
→ CURRENT PRODUCTION
→ TARGET CONTRACT
→ SURGICAL FIX
→ TEST
→ DEPLOY
→ VERIFY
→ CLOSE
```

### أول نقطة بدء في الجلسة التالية

إذا لم يكن هناك خطأ Browser جديد مثبت، فلا تعد إلى Transfer.

ابدأ بأول Gap فعلي غير مغلق في CURRENT MAIN، ثم قم بمطابقة:

```text
CURRENT MAIN
+
CURRENT DATABASE
+
CURRENT RPC / EDGE
+
CURRENT AUDIT
+
CURRENT PERMISSIONS
+
CURRENT DOWNSTREAM IMPACT
```

ثم حدد هل توجد قدرة Business حقيقية جاهزة للعرض، أم مجرد Database Foundation. إذا كانت مجرد Foundation فلا تخترع لها UI قبل بناء/إثبات Transaction Contract.

**الحقيقة أولًا. العقد ثانيًا. الفجوة المثبتة ثالثًا. الإصلاح الجراحي رابعًا. التحقق خامسًا. الإغلاق أخيرًا.**
