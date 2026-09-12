# Report128 — Main8 Forensic Recheck & Execution Record — 2026-09-12

## 0. الهدف الحاكم — يجب قراءته بعناية وتكراره

**هناك نقص شديد في كل التبويبات ، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا تتعامل معه كإضافات شكلية. وهذا متسق حرفيًا مع مبدأ الحوكمة: الدراسة أولًا، ثم إعادة بناء العقد التاريخي، ثم تتبع السلوك الحالي، ثم تحديد الفجوة، ثم التعديل الجراحي، ثم الاختبار والتحقق.**

الهدف هنا ليس إضافة أزرار أو واجهات ظاهرية. Main8 يجب أن يصبح جزءًا ماليًا وظيفيًا ومتكاملًا مع Production، مع الحفاظ على العقود التاريخية وعدم اختراع محركات موازية.

## 1. قاعدة التنفيذ

تم إيقاف أي مسار سابق غير متعلق بمهمة Main8.

المصادر المرجعية الحاكمة:

- `Current/PWA/main2/main8.md` كمصدر التحرير.
- `Original/PWA/main/main8.md` كمرجع تاريخي فقط.
- `CURRENT_STATE.md` كحالة جلسية، وليس كمصدر حقيقة بديل عن Production/Git.
- `forensic_main_assembly.yml` للتحقق من Source of Truth.

المسارات الموقوفة ولم تُستخدم كمصدر تحرير:

- `Current/PWA/main/*`
- `Current/PWA/New-main/*`

## 2. ما تم فحصه مباشرة

تمت إعادة قراءة وثائق الحوكمة والتوجيه، ثم إعادة فحص Report127، وقراءة `CURRENT_STATE.md` كاملًا، ثم فتح Main8 الحالي من المستودع وإعادة فتح مواضعه الجراحية الأساسية.

تم فتح `Original/PWA/main/main8.md` للمقارنة التاريخية.

تم التحقق من أن `forensic_main_assembly.yml` ما زال يستخدم:
`Current/PWA/main2/main1.md` … `main11.md`
مع `Original/PWA/main` كمرجع تاريخي فقط، وأن Assembly ما زال مؤجلًا. fileciteturn1308file0L1-L6

تم التحقق من وجود أجزاء Main1–Main11 تحت `Current/PWA/main2` من Directory Listing. fileciteturn1312file0L1-L10

## 3. Main8 Production/source evidence

Main8 الحالي بقي دون تعديل من المساعد. SHA المصدر قبل Owner Apply وما بعد هذه الجلسة:

`2131fbf3096d926b2486acb2ab58a4266ddd1bbc` fileciteturn1349file0L2-L6

هذا مهم: لم يتم الادعاء بأن Main8 النهائي مغلق، لأن ownership rule تمنع المساعد من تعديل Source Fragment.

## 4. إعادة اكتشاف المشاكل الفعلية في Main8

### MAIN8-N1 — الخزائن/البنوك

`_editTreasury(code)` كانت تسمح بإعادة كتابة `opening_balance` و`current_balance` أثناء تعديل الاسم/النوع، كما كانت تسمح بطلب الحذف دون فحص تاريخ `cash_box`.

الإصلاح المقترح في O1:

- تثبيت الأرصدة في واجهة التعديل.
- تحديث الاسم/النوع فقط.
- رفض الحذف عند وجود حركات نقدية أو رصيد غير صفري.

### MAIN8-N2 — دليل الحسابات

`_filterAccounts()` كانت تفحص الجذور فقط.

الإصلاح O2 يبحث recursively داخل الفروع ويحتفظ بمسار العقدة المطابقة.

### MAIN8-N3 — تعديل الحساب

`_openAccountDialog(editId)` كانت تجعل `account_code` readonly حتى عند الإضافة، وتسمح بتغيير `account_type` عند التعديل.

الإصلاح O3:

- الكود قابل للتحرير عند الإضافة.
- الكود والنوع ثابتان عند التعديل.
- اسم الحساب والأب فقط قابلان للتغيير.
- منع اختيار حساب تابع كأب للحساب الجاري لتفادي circular hierarchy.

### MAIN8-N4 — قائمة الدخل

Current Main8 كانت تعرض الإيرادات فقط.
Production `get-profit-loss` يعيد الإيرادات والمصروفات والإجماليات وصافي النتيجة.

الإصلاح O5 يعرض الجانبين والصافي.

### MAIN8-N5 — الميزانية العمومية

Current Main8 كانت تعرض الأصول والخصوم فقط.
Production `get_balance_sheet_data` تعيد أيضًا حقوق الملكية.

الإصلاح O6 يعرض الأصول والخصوم وحقوق الملكية ويحسب فرق التوازن.

### MAIN8-N6 — التدفقات النقدية

Production تحتوي `get_cash_flow` لكن Main8 لم يكن يعرضها.

الإصلاح O7 يضيف شاشة التدفقات النقدية المرتبطة مباشرة بـRPC الموجود.

### MAIN8-N7 — الموازنات

Current `_editBudget()` كانت تكتب مباشرة إلى `budgets` وتفرض `cost_center_id = null`.

الإصلاح O9 يستخدم `save_budget_atomic` وOperation Identity ويمرر مركز التكلفة الفعلي.

Current `_loadBudgetsList()` كانت تعرض نتائج مبنية على عقد Production لكنها لا تمرر مركز التكلفة إلى نافذة التعيين.

الإصلاح O8 يعيد تمريره.

## 5. اكتشاف مهم: Production أقوى من واجهة Main8 الحالية

تم العثور مباشرة في Production على قدرات محاسبية ورقابية قائمة بالفعل، ومصرح بها للمستخدمين المصادق عليهم، ولم تكن مكشوفة في Main8:

- `accountant_gl_account_activity`
- `accountant_period_readiness`
- `accountant_reconciliation_summary`
- `accountant_exception_center`
- `accountant_customer_aging`
- `accountant_supplier_aging`

هذه ليست وظائف مخترعة في التقرير؛ هي RPCs موجودة فعليًا في Production، مع authenticated EXECUTE grants، وجميعها تستخدم سياق الشركة من `app_private.current_user_company_id()` أو joins الشركة الصحيحة بحسب تعريف كل دالة.

لذلك تم إدخال O11–O16 إلى ملف البدائل كتكامل مباشر مع Backend القائم، وليس كـUI stub.

## 6. Production fixes المنفذة في هذه الجلسة

### 6.1 — Budget report aggregation

Migration:
`main8_budget_report_aggregate_fix`

الهدف:
منع تضاعف صف الحساب في التقرير عندما توجد أكثر من موازنة مرتبطة بمراكز تكلفة مختلفة.

### 6.2 — Budget Actual / Cost Center alignment

Migration:
`main8_budget_actual_cost_center_alignment`

الهدف:
عند اختيار مركز تكلفة، يجب أن يتغير الـActual بنفس سياق مركز التكلفة، لا أن يبقى إجمالي الحساب كله.

ثبت أولًا أن `journal_lines.cost_center_id` موجود في Production، ثم تم إصلاح RPC مع الحفاظ على نفس signature:

`get_budget_vs_actual(p_year, p_month, p_cost_center_id)`

وعند `p_cost_center_id = NULL` يظل التقرير جامعًا للحساب كله.

## 7. Production state بعد التنفيذ

لقطة Production في 2026-09-12:

- `budgets = 0`
- `journal_entries = 2`
- `active_treasury = 1`
- `active_accounts = 17`

لا توجد بيانات Budget قائمة في Production وقت اللقطة، ولذلك لا يمكن الادعاء بوجود نتيجة business sample فعلية بعد الإصلاح؛ ما تم التحقق منه هو العقد والـschema والتنفيذ نفسه.

## 8. ملف Owner Surgical Replacement

تمت إعادة إنشاء الملف الذي كان مفقودًا:

`doc/Draft/Reprots/MAIN8_OWNER_SURGICAL_REPLACEMENTS_20260912.js`

SHA الحالية:
`ec92a73e81169f5aa653b14e3185b8b2934c419d` fileciteturn1341file0L2-L6

الملف يحتوي على البدائل الكاملة، وليس snippets ناقصة.

## 9. تعليمات التطبيق على Main8 — محددة بالكامل

### O1 — `_editTreasury(code)`

**السطر الحالي:** 181.

ابحث عن:
`function _editTreasury(code) {`

احذف الدالة كاملة حتى آخر `}` الموجود مباشرة قبل التعليق:
`// ==================== دليل الحسابات ====================`

استبدلها بالقسم `O1` من:
`MAIN8_OWNER_SURGICAL_REPLACEMENTS_20260912.js`

### O2 — `_filterAccounts()`

**السطر الحالي:** قرابة 258.

ابحث عن:
`function _filterAccounts() {`

احذف الدالة كاملة حتى آخر `}` الموجود مباشرة قبل:
`function _openAccountDialog(editId) {`

استبدلها بالقسم `O2`.

### O3 — `_openAccountDialog(editId)`

**السطر الحالي:** قرابة 272.

ابحث عن:
`function _openAccountDialog(editId) {`

احذف الدالة كاملة حتى آخر `}` الموجود مباشرة قبل:
`async function _seedAccounts() {`

استبدلها بالقسم `O3`.

### O4 — `_renderReports()`

**السطر الحالي:** 1022.

ابحث عن:
`function _renderReports() {`

احذف الدالة كاملة حتى آخر `}` الموجود مباشرة قبل:
`function _trialBalance() {`

استبدلها بالقسم `O4`.

### O5 — `_profitLoss()`

**السطر الحالي:** 1051.

ابحث عن:
`function _profitLoss() {`

احذف الدالة كاملة حتى آخر `}` الموجود مباشرة قبل:
`function _renderBudgets() {`

استبدلها بالقسم `O5`.

### O6 — `_balanceSheet()`

**السطر الحالي:** 1128.

ابحث عن:
`function _balanceSheet() {`

احذف الدالة كاملة حتى آخر `}` الموجود مباشرة قبل:
`function _costCenterProfitLoss() {`

استبدلها بالقسم `O6`.

### O7 — `_cashFlow()`

ابحث عن السطر:
`function _balanceSheet() {`

أضف **فوقه مباشرة** الدالة الكاملة الموجودة في القسم `O7`.

### O8 — `_loadBudgetsList()`

**السطر الحالي:** 1093.

ابحث عن:
`function _loadBudgetsList() {`

احذف الدالة كاملة حتى آخر `}` الموجود مباشرة قبل:
`function _editBudget(accountId, accountName, year, month) {`

استبدلها بالقسم `O8`.

### O9 — `_editBudget(accountId, accountName, year, month)`

**السطر الحالي:** 1113.

ابحث عن:
`function _editBudget(accountId, accountName, year, month) {`

احذف الدالة كاملة حتى آخر `}` الموجود مباشرة قبل:
`function _balanceSheet() {`

استبدلها بالقسم `O9`.

### O11–O16 — القدرات المالية Production-backed

أضف الدوال الكاملة:

`_accountActivity()`
`_periodReadiness()`
`_reconciliationSummary()`
`_exceptionCenter()`
`_customerAging()`
`_supplierAging()`

في موضع واحد قبل `return {` في نهاية `RW_Finance`.

استخدم الأقسام المناظرة في ملف البدائل.

### O10 — Export

في `return { ... }` استبدل السطر الذي يحتوي على:
`_balanceSheet: _balanceSheet, _costCenterProfitLoss: _costCenterProfitLoss`

ليصدر أيضًا:
`_cashFlow`, `_accountActivity`, `_periodReadiness`, `_reconciliationSummary`, `_exceptionCenter`, `_customerAging`, `_supplierAging`.

لا تغير بقية الـreturn.

## 10. ما لم يتم تغييره عمدًا

لم يتم تعديل:

- `Current/PWA/main2/main8.md`
- `Current/PWA/core.js`
- `Current/PWA/sw.js`
- `Current/PWA/register-sw.js`
- `Current/PWA/manifest.json`
- `Original/PWA/main/*`
- `Current/PWA/main/*`
- `Current/PWA/New-main/*`
- `forensic_main_assembly.yml`

السبب: لا توجد ضرورة حالية لتغييرها في Main8 closure، والملفات المساعدة لن تدخل التعديل إلا بعد assembly النهائي كما تنص الخطة.

## 11. التجارب والفشل والنتائج

### نجح

- التحقق المباشر من Main8 الحالي وSHA.
- إعادة التحقق من Production financial RPCs.
- إثبات وجود `journal_lines.cost_center_id`.
- إثبات وجود authenticated grants للدوال الرقابية المالية المتقدمة.
- تنفيذ Migration 1 بنجاح.
- تنفيذ Migration 2 بنجاح.
- إعادة إنشاء ملف البدائل المفقود في Git.
- تحديث `CURRENT_STATE.md`.
- تأكيد بقاء `forensic_main_assembly.yml` على Source of Truth الصحيح.

### فشل / لم يتحول إلى PASS زائف

- لم يتم تنفيذ Owner Apply على `main8.md` لأن ذلك من اختصاص المالك.
- لم يتم تسجيل Browser E2E النهائي.
- لم يتم تسجيل authenticated runtime E2E النهائي بعد Owner Apply.
- لم يتم تسجيل `node --check` كنجاح نهائي على Main8 نفسه؛ السبب أن Source Fragment لم يتغير بعد.
- لم يتم اختلاق sample business data في Production لتجميل التقرير؛ `budgets=0` وقت لقطة Production.

## 12. تقييم Gold/Diamond

Main8 الحالي **ليس Gold/Diamond مغلقًا**.

تمت إزالة الفجوات من ناحية الدراسة والتشخيص، وتم تنفيذ Production fixes حقيقية، وتم تجهيز البدائل الكاملة، بل وتمت إضافة تكاملات مع capabilities موجودة أصلًا في Production.

لكن الإغلاق النهائي يتطلب Owner Apply ثم إعادة الفحص:

`OWNER APPLY`
→ `FULL EOF READ`
→ `NODE --CHECK`
→ `DUPLICATE DECLARATION CHECK`
→ `CONSOLE CHECK`
→ `MAIN7/MAIN8/MAIN9 CONTRACT CHECK`
→ `AUTHENTICATED E2E`
→ `PRODUCTION RUNTIME VERIFY`
→ `FINAL PRODUCTION SYNC`

لا يتم الانتقال إلى Assembly قبل ذلك.

## 13. Self-Audit

### What I Proved

- Main8 Source of Truth الحالي صحيح.
- Main8 SHA لم يتغير لأن المساعد لم يحرر Source Fragment.
- Report127 لم يكن كافيًا كحقيقة؛ تمت مطابقة الوقائع مع GitHub وProduction.
- `forensic_main_assembly.yml` صحيح.
- Production financial contracts المطلوبة موجودة.
- Production budget report logic احتاج بالفعل إلى إصلاحين إضافيين وتم تنفيذهما.
- ملف البدائل المفقود تم إنشاؤه.
- Owner instructions أصبحت محددة بالأسماء والحدود النهائية للدوال.

### What I Did Not Prove

- لم أثبت نجاح Main8 النهائي بعد Owner Apply.
- لم أثبت Browser E2E النهائي.
- لم أثبت integration مع Main1–Main11 بعد assembly.
- لم أثبت runtime behavior من session user حقيقية بعد تغييرات المصدر، لأن المصدر لم يُطبّق بعد.
- لم أثبت أن كل جزء من Main1–Main11 أُعيدت قراءته كاملًا إلى EOF في هذه الجلسة؛ الذي تم إثباته هو directory-level Source-of-Truth inventory وSHA mapping، ولذلك لا يوجد ادعاء بإغلاق التكامل الكامل.

### What I Fixed

- Production `get_budget_vs_actual` aggregation.
- Production cost-center alignment.
- Missing Main8 replacement package.
- CURRENT_STATE drift in fragment hashes/checkpoint.

### What I Initially Missed During Early Analysis

تم اكتشاف أن قوة Production المالية الحالية أكبر من واجهة Main8، وأن المشكلة ليست فقط في الإصلاحات السبع المعروفة؛ توجد capabilities جاهزة يمكن ربطها مباشرة بدل بناء backend جديد.

### What Could Still Be Wrong

- أي خطأ تنفيذي في تطبيق المالك للبدائل.
- أي contract drift مع Main7/Main9 بعد التعديل النهائي.
- أي UI/DOM dependency غير مكشوفة في النص الحالي حتى الاختبار النهائي.
- أي مشكلة صلاحيات browser-level غير ظاهرة من RPC grants وحدها.

## 14. Final Status

```text
MAIN8 FULL SOURCE READ = PASS
MAIN8 HISTORICAL REVIEW = PASS
MAIN8 PRODUCTION CONTRACT TRACE = PASS
MAIN8 PRODUCTION BUDGET FIXES = DEPLOYED
MAIN8 OWNER REPLACEMENT FILE = CREATED
MAIN8 OWNER SOURCE APPLY = PENDING
MAIN8 FINAL EXECUTABLE SYNTAX = PENDING
MAIN8 AUTHENTICATED BROWSER E2E = PENDING
MAIN8 PRODUCTION RUNTIME VERIFY = PENDING
MAIN1..MAIN11 FINAL INTEGRATION = PENDING
MAIN8 GOLD/DIAMOND = NOT CLOSED
ASSEMBLY = DEFERRED
```

## 15. الحكم التنفيذي

لا يوجد مبرر لإعادة Main8 إلى نقطة الصفر.

المرحلة الصحيحة الآن هي تطبيق **ملف البدائل الجراحي المحدد** على `Current/PWA/main2/main8.md` فقط، ثم إعادة الفحص الكامل. هذا هو المسار الوحيد الذي يحافظ على الملكية الصحيحة للـSource Fragment ويمنع تكرار الأخطاء التي حدثت عندما كانت تعليمات الحذف غير محددة أو عندما استُخدمت بدائل ناقصة.
