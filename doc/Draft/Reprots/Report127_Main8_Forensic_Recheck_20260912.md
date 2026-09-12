# تقرير Main8 — المراجعة الجنائية وإعادة الفحص

**التاريخ:** 2026-09-12  
**Source of Truth:** `Current/PWA/main2/main8.md`  
**Current SHA عند بداية الفحص:** `2131fbf3096d926b2486acb2ab58a4266ddd1bbc`  
**Assembly:** مؤجل حسب `forensic_main_assembly.yml`

## 0. الهدف الحاكم — إعادة التأكيد

> هناك نقص شديد في كل التبويبات ، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا تتعامل معه كإضافات شكلية.
>
> وهذا متسق حرفيًا مع مبدأ الحوكمة: الدراسة أولًا، ثم إعادة بناء العقد التاريخي، ثم تتبع السلوك الحالي، ثم تحديد الفجوة، ثم التعديل الجراحي، ثم الاختبار والتحقق.

هذا التقرير يطبق هذا المبدأ على Main8، ولا يعتبر أي نقص واجهة "تجميليًا" عندما يترتب عليه عقد تشغيل أو محاسبة أو بيانات ناقصة.

## 1. مصادر التحقيق

تم الرجوع إلى:

- `MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`.
- `CURRENT_STATE.md`.
- `Report126_Main7_Forensic_Recheck_20260912.md` كاملًا حتى نهايته.
- ملفات Owner Main7 الستة المسجلة في Report126، بما فيها Receiving / VoucherSave / Unloading / Inventory / Settlement / Picking.
- `forensic_main_assembly.yml`.
- `Current/PWA/main2/main8.md` كاملًا من البداية حتى EOF.
- `Original/PWA/main/main8.md` كمرجع تاريخي فقط.
- Production Supabase: schema، constraints، functions/RPCs، triggers، Edge Functions ذات الصلة، والتحقق التشغيلي حيث أمكن دون اختلاق جلسة مستخدم.

ملاحظة حوكمة: التقارير السابقة استُخدمت كدلائل، ثم تمت مطابقة النقاط الحساسة مع الكود وProduction الحالية.

## 2. نتيجة قراءة Main8

Main8 الحالي هو وحدة `RW_Finance` كاملة البنية، ويحتوي على:

- الخزائن والبنوك.
- دليل الحسابات.
- القيود اليومية.
- سندات القبض.
- سندات الصرف.
- التحويلات.
- التقارير المالية.
- الموازنات.

تم تتبع الملف حتى السطر الأخير `window.RW_Finance = RW_Finance;` ولم يظهر بعده محتوى فعلي في المصدر.

## 3. المطابقة التاريخية

النسخة التاريخية `Original/PWA/main/main8.md` تؤكد أن Main8 بدأ بوحدة مالية مباشرة مع Supabase، لكنها كانت أقل انضباطًا في Company scoping وإدارة الرصيد والحذف.

النسخة الحالية قطعت شوطًا كبيرًا نحو الشركة الحالية والعمليات الذرية، خصوصًا في القيود وسندات القبض والصرف والتحويلات، ولذلك لم تتم إعادة بناء الأجزاء السليمة.

القرار: **نحافظ على العقود المالية العاملة ونصلح فجوات Main8 المؤكدة فقط.**

## 4. الفجوات المثبتة في Main8

### MAIN8-N1 — تعديل الخزينة كان يعيد كتابة الرصيد الحالي

**الموضع:** `function _editTreasury(code) {` عند السطر 181.

النسخة الحالية ترسل `opening_balance` و`current_balance` من نافذة التعديل، والقيمة المستخدمة هي الرصيد الافتتاحي المدخل. هذا يسمح عمليًا بمحو الرصيد الجاري للخزينة عند مجرد تعديل الاسم أو النوع.

كما أن الحذف كان يتم دون فحص وجود حركة نقدية تاريخية.

**الحل:** استبدال الدالة كاملة. البديل يحفظ الرصيد الحالي والافتتاحي دون تعديل من نافذة البيانات الأساسية، ويمنع الحذف إذا كان هناك رصيد غير صفري أو تاريخ في `cash_box`.

### MAIN8-N2 — البحث في دليل الحسابات كان Root-only

**الموضع:** `function _filterAccounts() {` الحالية تبدأ مباشرة بعد `_buildAccountTree()`، وحاليًا قرب السطر 258.

البحث الحالي لا يبحث recursively داخل الأبناء؛ فإذا طابق حساب فرعي يتم تجاهله إلا إذا كان من الجذور.

**الحل:** استبدال الدالة بدالة recursive تحفظ فرع الأب عند تطابق أحد الأبناء.

### MAIN8-N3 — إنشاء حساب جديد كان يعيد `account_code` فارغًا

**الموضع:** `function _openAccountDialog(editId) {` حاليًا قرب السطر 272.

عند الإضافة، حقل `acc-code` كان `readonly` وقيمته فارغة، ثم يتم تمرير القيمة نفسها إلى INSERT.

كذلك كان تعديل الحساب يسمح بتغيير `account_type` لحساب موجود، وهو تغيير قد يغير معنى الحساب في التقارير والـnormal balance.

**الحل:** استبدال الدالة كاملة. في الإضافة يصبح الكود قابلًا للإدخال، وفي التعديل يبقى الكود ونوع الحساب ثابتين، مع السماح بتعديل الاسم والأب فقط.

### MAIN8-N4 — تقرير الأرباح والخسائر كان ناقصًا وظيفيًا

**الموضع:** `function _profitLoss() {` داخل قسم التقارير.

Production Edge `get-profit-loss` يعيد الإيرادات والمصروفات وإجمالياتهما وصافي الربح، بينما Main8 كان يعرض الإيرادات فقط.

**الحل:** استبدال الدالة لعرض الإيرادات والمصروفات وصافي النتيجة والإجماليات.

### MAIN8-N5 — الميزانية العمومية كانت تعرض الأصول والخصوم فقط

Production `get_balance_sheet_data` يعيد `assets` و`liabilities` و`equity`، بينما Main8 كان يهمل حقوق الملكية.

**الحل:** استبدال `_balanceSheet()` لعرض الأقسام الثلاثة، إجمالياتها، واختبار التوازن `Assets = Liabilities + Equity`.

### MAIN8-N6 — Cash Flow موجود في Production وغير ظاهر في Main8

Production تحتوي `get_cash_flow(p_from_date,p_to_date)`، وهي شركة-scoped عبر `app_private.current_user_company_id()`.

لكن `_renderReports()` لا يقدم زرًا أو شاشة للتدفقات النقدية.

**الحل:** استبدال `_renderReports()` وإضافة `_cashFlow()` قبل `_balanceSheet()`.

تنبيه: العرض سيستخدم عقد Production الحالي كما هو؛ لا يتم الادعاء هنا بأنه إعادة تصميم كاملة لمحرك IAS 7 جديد دون عقد Production جديد.

### MAIN8-N7 — الموازنات تجاهلت مركز التكلفة المختار

`_editBudget()` كان يحفظ `cost_center_id: null` دائمًا مهما كان اختيار المستخدم في الشاشة.

**الحل:** الاستبدال الجديد يمرر مركز التكلفة الحقيقي ويستخدم `save_budget_atomic`.

### MAIN8-N8 — حفظ الميزانية كان Direct Upsert وليس Atomic/Idempotent

Production schema يحتوي على UNIQUE مركب، لكن `NULL` في PostgreSQL لا يمنع التكرار في UNIQUE العادي.

تم فحص Production الحالية ولم توجد duplicate rows في الموازنات غير المرتبطة بمركز تكلفة قبل الإصلاح.

**الحل Production:**

1. إضافة partial unique index:
   `budgets_null_cc_unique_idx(account_id,budget_year,budget_month) WHERE cost_center_id IS NULL`.
2. إضافة RPC ذري:
   `save_budget_atomic(...)`.
3. دعم Operation Identity عبر `erp_operation_registry`.
4. فحص Company context وAccount وCost Center.
5. Audit entry.

## 5. Production changes المنفذة فعليًا

### 5.1 — محرك القيود

تم تطبيق Migration:
`main8_validate_journal_cost_center`

النتيجة: `post_journal_entry` أصبح يرفض `cost_center_id` غير الموجود أو غير النشط، مع الحفاظ على كل عقود القيد السابقة.

### 5.2 — محرك الموازنات

تم تطبيق Migration:
`main8_budget_atomic_integrity`

النتيجة:

- منع duplicate budget بدون cost center مستقبلًا.
- حفظ ذري عبر `save_budget_atomic`.
- idempotency عبر `erp_operation_registry` عند تمرير Operation Identity.
- فحص Company context.
- فحص Account وCost Center.
- audit record.

## 6. Production schema verification

تمت مطابقة الجداول:

- `treasury`
- `chart_of_accounts`
- `cost_centers`
- `journal_entries`
- `journal_lines`
- `cash_box`
- `budgets`

وثبت من schema:

- `treasury` company-scoped ومفتاحه الفريد `(company_id,account_code)`.
- `chart_of_accounts` company-scoped ومفتاحه الفريد `(company_id,account_code)`.
- `budgets` لا تحتوي `company_id`، والعزل يأتي من account/cost-center context الحالي.
- `cost_centers` عالمية في schema الحالية ولا يوجد `company_id` فيها؛ لم يتم اختراع Company column أو filter غير موجود.
- `cash_box` و`journal_entries` يحتويان `company_id`.

## 7. Production financial RPC verification

ثبت وجود:

- `post_journal_entry`
- `post_cash_receipt_atomic`
- `post_cash_payment_atomic`
- `post_treasury_transfer_atomic`
- `get_trial_balance`
- `get_profit_loss`
- `get_balance_sheet_data`
- `get_cash_flow`
- `get_pnl_by_cost_center`
- `get_budget_vs_actual`
- `save_budget_atomic` بعد هذا الإصلاح

وتبين أن محركات التقارير الرئيسية تستعمل `app_private.current_user_company_id()` أو Company-scoped data joins.

## 8. Audit verification

ثبت وجود `trg_audit_treasury` و`trg_audit_cash_box` و`trg_audit_journal_entries` و`trg_audit_journal_lines`.

كما ثبت أن `fn_audit_trigger()` يكتب إلى `audit_log` ويأخذ actor من JWT عندما يكون متاحًا، مع fallback إلى `system`.

## 9. Edge Functions verification

المسارات المالية الحالية المهمة تمت مطابقتها مع Production:

- `save-journal-entry` → `post_journal_entry`.
- `save-receipt-voucher` → `post_cash_receipt_atomic`.
- `save-payment-voucher` → `post_cash_payment_atomic`.
- `save-transfer-voucher` → `post_treasury_transfer_atomic`.
- `get-trial-balance` → `get_trial_balance`.
- `get-profit-loss` → `get_profit_loss`.

كل المسارات الأربعة للكتابة المالية تستخدم JWT وتستخرج `company_id` من `users.auth_id` بدل `app_settings LIMIT 1`.

## 10. ما لم يتم تغييره عمدًا

لم يتم تعديل:

- `_saveJournalEntry()`.
- `_saveReceipt()`.
- `_savePayment()`.
- `_saveTransfer()`.
- `_loadAllData()`.
- `Original/PWA/main`.
- `Current/PWA/New-main`.
- `Current/PWA/main`.
- `forensic_main_assembly.yml`.

السبب: المسارات المذكورة تعمل بعقود Production حالية أو تحتاج عقدًا جديدًا قبل إعادة تصميمها؛ تعديلها الآن بلا دليل كان سيخالف الحوكمة.

## 11. Owner Surgical Change Set — Main8

### O1 — `_editTreasury(code)`

**FILE:** `Current/PWA/main2/main8.md`

**CURRENT START:** السطر 181.

**ابحث عن:**
`function _editTreasury(code) {`

**احذف الدالة كاملة حتى آخر `}` قبل:**
`// ==================== دليل الحسابات ====================`

**استبدلها بالكامل بـ:**
`MAIN8_OWNER_SURGICAL_REPLACEMENTS_20260912.js` — القسم O1.

### O2 — `_filterAccounts()`

**CURRENT START:** السطر 258 تقريبًا.

**ابحث عن:**
`function _filterAccounts() {`

**احذف الدالة كاملة حتى آخر `}` قبل:**
`function _openAccountDialog(editId) {`

**استبدلها بالكامل بـ:** القسم O2 من ملف البدائل.

### O3 — `_openAccountDialog(editId)`

**CURRENT START:** السطر 272 تقريبًا.

**ابحث عن:**
`function _openAccountDialog(editId) {`

**احذف الدالة كاملة حتى آخر `}` قبل:**
`async function _seedAccounts() {`

**استبدلها بالكامل بـ:** القسم O3.

### O4 — `_renderReports()`

ابحث عن:
`function _renderReports() {`

**احذف الدالة كاملة حتى آخر `}` قبل:**
`function _trialBalance() {`

**استبدلها بالكامل بـ:** القسم O4.

### O5 — `_profitLoss()`

ابحث عن:
`function _profitLoss() {`

**احذف الدالة كاملة حتى آخر `}` قبل:**
`function _renderBudgets() {`

**استبدلها بالكامل بـ:** القسم O5.

### O6 — `_balanceSheet()`

ابحث عن:
`function _balanceSheet() {`

**احذف الدالة كاملة حتى آخر `}` قبل:**
`function _costCenterProfitLoss() {`

**استبدلها بالكامل بـ:** القسم O6.

### O7 — إضافة `_cashFlow()`

ابحث عن السطر:
`function _balanceSheet() {`

**أضف فوقه مباشرة الدالة الكاملة:**
`async function _cashFlow() { ... }`
الموجودة في القسم O7 من ملف البدائل.

لا تحذف `_balanceSheet()` في هذه الخطوة؛ O6 يتم بعد ذلك كاستبدال مستقل.

### O8 — `_loadBudgetsList()`

ابحث عن:
`function _loadBudgetsList() {`

**احذف الدالة كاملة حتى آخر `}` قبل:**
`function _editBudget(accountId, accountName, year, month) {`

**استبدلها بالكامل بـ:** القسم O8.

### O9 — `_editBudget(...)`

ابحث عن:
`function _editBudget(accountId, accountName, year, month) {`

**احذف الدالة كاملة حتى آخر `}` قبل:**
`function _balanceSheet() {`

**استبدلها بالكامل بـ:** القسم O9.

### O10 — Export `_cashFlow`

في نهاية `return { ... }` ابحث عن السطر الحالي:
`_balanceSheet: _balanceSheet, _costCenterProfitLoss: _costCenterProfitLoss`

**استبدله بهذا السطر فقط:**
`_balanceSheet: _balanceSheet, _cashFlow: _cashFlow, _costCenterProfitLoss: _costCenterProfitLoss`

لا تغيّر بقية `return`.

## 12. ملف البدائل الكامل

تم إنشاء ملف واحد يحتوي جميع البدائل الكاملة:

`doc/Draft/Reprots/MAIN8_OWNER_SURGICAL_REPLACEMENTS_20260912.js`

مر على `node --check` بنجاح:

`SYNTAX_OK`

ولا يتم تطبيق أي جزء منه على `main8.md` من طرف المساعد؛ التنفيذ في Source Fragment من اختصاص المالك وفق قاعدة المشروع.

## 13. Tests / Experiments

### نجح

- Production schema verification.
- Production RPC/function verification.
- Production trigger verification.
- فحص وجود duplicate budgets في `NULL cost_center_id` قبل إنشاء partial unique index: لا توجد duplicates.
- Syntax check لملف البدائل: PASS.
- Production DDL migrations: PASS.

### لم يُحوّل إلى PASS زائف

لم يتم تسجيل Browser E2E على Main8 النهائي، لأن Main8 source fragment لم يتم تعديله بعد. وبالتالي:

`MAIN8 FINAL BROWSER E2E = PENDING`

كما لم يتم تسجيل Production runtime success من Edge Functions باستخدام session user حقيقية لمجرد أن الـRPC definitions تبدو صحيحة؛ هذا يحتاج authenticated execution بعد Owner Apply.

## 14. Gold/Diamond assessment

Main8 الآن لديه عقد Production أفضل، وتقارير أساسية أكمل، وحماية بيانات أفضل.

لكنه **ليس Gold/Diamond مغلقًا بعد**.

الأسباب التي لا يجوز إخفاؤها:

- ما زال الجزء الحالي يحتاج Owner Apply ثم إعادة قراءة كامل المصدر.
- ما زالت هناك قدرات مالية تنافسية متقدمة غير مثبتة في هذا fragment أو في Production contract، مثل General Ledger / Account Statement / Period Closing / Bank Reconciliation / VAT workflow / richer analytical dimensions.
- لا يجوز اختراع هذه الوحدات من داخل Main8 دون reconstruction تاريخي وProduction contract جديد.

هذا ليس نقصًا متروكًا؛ بل **Backlog حوكمي صريح** للدورات القادمة.

## 15. Self-Audit

### ما تم إثباته

- Main8 الحالي هو `Current/PWA/main2/main8.md`.
- SHA البداية: `2131fbf3096d926b2486acb2ab58a4266ddd1bbc`.
- تمت قراءة المصدر حتى EOF.
- النسخة التاريخية `Original/PWA/main/main8.md` تمت مراجعتها.
- Production schema المالي تمت مطابقته.
- Production financial RPCs تمت مطابقتها.
- Audit triggers المالية تمت مطابقتها.
- Main8 لديه gaps وظيفية حقيقية وليست شكلية فقط.
- تم تنفيذ إصلاحين Production فعليين: Journal Cost Center validation وBudget Atomic Integrity.
- تم إعداد Owner Surgical Replacement كامل لـMain8.
- ملف البدائل اجتاز syntax validation.

### ما لم يُثبت بعد

- Owner Apply على `main8.md`.
- Syntax النهائي لـ`main8.md` بعد Owner Apply.
- Browser E2E النهائي.
- التكامل النهائي Main8 مع Main1–Main11 بعد assembly.
- Production authenticated runtime verification لمسارات Main8 بعد Owner Apply.
- Gold/Diamond closure النهائي للنظام المالي بالكامل.

### أخطر ما كان يمكن أن يكون خطأً ولم يتم افتراضه

- لم يتم تغيير global `cost_centers` إلى company-scoped لأن schema الحالي لا يثبت ذلك.
- لم يتم اعتبار كل `LIMIT 1` خطأً آليًا؛ تمت مطابقة السياق ووظيفة كل query.
- لم يتم إعادة كتابة محركات القيود/القبض/الصرف/التحويل العاملة بلا gap مثبت.

## 16. Closure Status

```text
MAIN8 FULL SOURCE READ = PASS
MAIN8 HISTORICAL REVIEW = PASS
MAIN8 PRODUCTION SCHEMA TRACE = PASS
MAIN8 FINANCIAL RPC TRACE = PASS
MAIN8 AUDIT TRACE = PASS
MAIN8 OWNER REPLACEMENT SYNTAX = PASS
MAIN8 PRODUCTION INTEGRITY FIXES = DEPLOYED
MAIN8 OWNER SOURCE APPLY = PENDING
MAIN8 FINAL SOURCE SYNTAX = PENDING
MAIN8 BROWSER E2E = PENDING
MAIN8 INTEGRATION WITH MAIN1..MAIN11 = PENDING
MAIN8 GOLD/DIAMOND = NOT CLOSED
ASSEMBLY = DEFERRED
```

## 17. الخطة الدقيقة للجلسة التالية

1. تطبيق O1→O10 على `Current/PWA/main2/main8.md` فقط.
2. قراءة Main8 الجديد من أول حرف حتى EOF.
3. تشغيل `node --check` على Main8 النهائي.
4. فحص duplicate declarations وdelimiter balance.
5. فحص Main8 مع Main7/Main9 interfaces.
6. تشغيل Browser/Auth E2E على Finance.
7. تشغيل retry tests للعمليات المالية ذات Operation Identity.
8. إعادة مزامنة Production في نفس لحظة التقرير.
9. عند نجاح كل Gates فقط، اعتماد Main8 والانتقال للجزء التالي.
10. لا Assembly قبل إغلاق Main1..Main11 وفق نفس الـGates.

## 18. ملاحظة تنفيذية للمالك

هذا التقرير لا يطلب منك البحث عن نهاية غامضة للدوال.
كل عملية حذف محددة بآخر دالة/تعليق قبلها، والبدائل موجودة كاملة في ملف واحد.

**لا تعدل `Current/PWA/main8.md` إلا بتطبيق العناصر المحددة أعلاه.**
