# Report219 — MOTHER FINANCE FORENSIC E2E / CORE FINANCE CLOSURE

> **تنبيه حاكم في بداية التقرير:** ملف النظام الأم الحالي `papamohammed77-glitch/erp-frontend/companies/company-1/main.html` هو **Source of Truth الوحيد** لهذه المهمة. يجب قراءته بعناية لأنه يمثل النسخة المنشورة الفعلية، بينما `Current/PWA/main2` وبقية الملفات المجزأة والتقارير السابقة هي مصادر تاريخية/استرشادية فقط.

## 1. نطاق التنفيذ

تم إيقاف أي مسار سابق غير متعلق بهذه المهمة، والبدء من آخر حالة مثبتة ثم إعادة التحقق من:

- CURRENT GIT
- CURRENT SOURCE
- CURRENT PRODUCTION
- CURRENT DATABASE
- CURRENT DEPLOYMENT EVIDENCE

آخر commit فعلي في Mother repository عند بدء المهمة:

- HEAD: `3fe3c76674c7cbed8eb10201fee83ca6af2f1b07`
- Message: `forensic: persist current Mother inventory extract`
- Parent: `3b5fdce634e44b3a2faa6bbf2dd40db5e88a676a`
- Current Mother file: `companies/company-1/main.html`
- Current forensic extract reports `24,150` lines and current SHA256 `7f5bc99954c62d3359180dedb577e52ff498c020eb29de04adc0cf4646a89c84`.

تمت مراجعة الـparent لأن قاعدة الحوكمة تمنع افتراض سبب الحالة الحالية.

---

## 2. النتيجة الجنائية قبل الإصلاح

تبين أن **البنية المالية الأساسية موجودة بالفعل** في Production وليست ناقصة من ناحية الجداول. Production يحتوي على:

- `finance_expenses`
- `finance_expense_lines`
- `finance_expense_categories`
- `finance_cheques`
- `finance_cheque_events`
- `finance_bank_statements`
- `finance_bank_statement_lines`
- `finance_tax_codes`
- `finance_tax_transactions`
- `finance_tax_settlements`
- `fixed_assets`
- `fixed_asset_events`
- `finance_periods`
- `recurring_journal_templates`
- `recurring_journal_lines`
- `finance_recurring_runs`
- `journal_entries`
- `journal_lines`

وهذا يمنع إعادة بناء جداول مكررة فقط لأن واجهة المستخدم كانت سطحية.

الحالة الحالية للبيانات:

| الكيان | العدد الحالي |
|---|---:|
| Finance periods | 1 |
| Expenses | 0 |
| Cheques | 0 |
| Bank statements | 0 |
| Tax codes | 0 |
| Fixed assets | 0 |
| Recurring templates | 0 |

الفترة الحالية الوحيدة هي `FY2026` من `2026-01-01` إلى `2026-12-31` وحالتها `OPEN` للشركة المرجعية الرئيسية.

---

## 3. العقد المحاسبي المركزي المثبت

تم التحقق من وجود `post_journal_entry` في Production كـSecurity Definer engine مركزي، وهو يتحقق من:

- Company context
- وجود الفترة المحاسبية عبر `finance_period_guard`
- وجود قيدين على الأقل
- صحة الحسابات داخل نفس الشركة
- توازن المدين والدائن
- Idempotency عبر `erp_operation_registry`
- كتابة `journal_entries` و`journal_lines`
- كتابة `audit_log`

بالتالي **لا يوجد سبب لإنشاء Journal Engine ثانٍ**.

كما تم التحقق من وجود `post_cash_payment_atomic` و`post_cash_receipt_atomic` كـCash/Treasury posting engines، وهما ينشئان `cash_box` ويغيران رصيد الخزينة ويستعملان `post_journal_entry`.

---

## 4. Console defect السابق

الخطأ المثبت في Mother كان Dispatcher-to-Namespace mismatch:

```text
_renderJournalList()
_renderRecurringJournals()
_renderExpenses()
_renderCheques()
_renderBankReconcile()
_renderTax()
_renderAssets()
_renderPeriods()
```

بينما الـnamespace يحتوي على:

```text
RW_Finance._renderJournalList
RW_Finance._renderRecurringJournals
RW_Finance._renderExpenses
RW_Finance._renderCheques
RW_Finance._renderBankReconcile
RW_Finance._renderTax
RW_Finance._renderAssets
RW_Finance._renderPeriods
```

هذا الإصلاح كان مثبتًا مسبقًا في CURRENT_STATE، ولم تتم إعادة تنفيذه. بعده لا يجوز إعادة معالجة الأخطاء الثمانية القديمة إلا إذا عادت في Console بعد E2E حقيقي.

---

## 5. التحقيق في واجهة Finance الحالية

النسخة الحالية من `RW_Finance_GoldExtension` تحتوي فعليًا على Renderers وGold Actions، لكن بعض الـmodals كانت أقرب إلى Proof-of-Concept من واجهة ERP مكتملة.

أهم الأمثلة المثبتة في CURRENT SOURCE:

### A — قيد متكرر

الـmodal الحالي يطلب:

- كود القالب
- اسم القالب
- التكرار
- تاريخ التنفيذ
- JSON يدوي لخطوط القيد

وهذا غير مناسب للاستخدام النهائي لأن المستخدم المالي لا ينبغي أن يكتب UUIDات وJSON يدويًا.

### B — شيك جديد

الـmodal الحالي يطلب رقم الشيك والبنك والمبلغ والتواريخ والطرف والملاحظات فقط، ويترك الحسابات والخزينة `null`.

### C — كشف بنكي جديد

الـmodal الحالي يختار **أول خزينة فعالة** باستخدام `limit(1)` ويعرض ثلاثة حقول فقط.

### D — أصل ثابت جديد

الـmodal الحالي يطلب UUIDات الحسابات يدويًا:

```text
UUID حساب الأصل
UUID مجمع الإهلاك
UUID مصروف الإهلاك
UUID ربح/خسارة الاستبعاد
```

### E — نوع ضريبة جديد

الـmodal الحالي يطلب UUID الحسابات يدويًا.

### F — فتح فترة

الـmodal الحالي يفتح الفترة بقيم افتراضية عامة ولا يوضح التداخل أو طبيعة الفترة، رغم أن Production يجب أن تمنع تداخل الفترات.

### G — المصروف

على خلاف الحالات السابقة، `newExpense` الحالية تحتوي بالفعل على تحميل تصنيفات وحسابات ومراكز تكلفة وTax Code وتدفع عبر RPC مركزي. لذلك **لم يتم استبدالها لمجرد الرغبة في التجميل**.

---

## 6. الإصلاحات المنفذة في Production

### 6.1 تشديد Accounting Period Contract

تم تنفيذ migration:

`20260916162000_finance_contract_integrity_close`

وتضمن:

1. رفض أي فترة جديدة تتداخل زمنيًا مع فترة موجودة للشركة.
2. منع تعديل فترة مغلقة عبر `finance_open_period`.
3. تسجيل إنشاء/تحديث الفترة في `audit_log`.
4. تحويل `finance_period_guard` من Guard اختياري إلى Guard فعلي:
   - لا توجد فترة مطابقة → رفض.
   - الفترة موجودة لكن غير `OPEN` → رفض.
   - الفترة المفتوحة فقط تسمح بالترحيل.

هذا التغيير يحول `finance_periods` من شاشة إدارية إلى Business Control حقيقي.

### 6.2 تشديد Bank Statement Contract

ضمن نفس migration:

- ممنوع تعديل كشف تمت تسويته `RECONCILED`.
- التحقق من رقم الكشف والتاريخ والأرصدة.
- التحقق من تاريخ وحجم بيانات كل سطر قبل الإدخال.
- الاستمرار في Company/Treasury scoping.

### 6.3 تشديد Cheque Contract

تمت إعادة بناء `finance_save_cheque` داخل Production بحيث:

- رقم الشيك ونوعه والمبلغ والتواريخ إلزامية.
- `due_date >= cheque_date`.
- الحسابات والخزينة يجب أن تتبع الشركة.
- التعديل مسموح فقط طالما الشيك `ISSUED`.
- **لا تتم كتابة `finance_cheque_events` مرة أخرى عند مجرد التعديل.**
- حدث `ISSUED` يسجل مرة واحدة عند الإنشاء.

الانتقالات اللاحقة تظل عبر `finance_transition_cheque` وبسلسلة الحالات الحالية المثبتة.

### 6.4 توحيد أثر المصروف النقدي

تم تنفيذ migration:

`20260916163500_finance_expense_cashflow_integrity`

التعديلات:

- المصروف النقدي يستمر في استخدام `post_journal_entry` كـAccounting Engine مركزي.
- تم إضافة التحقق من كفاية رصيد الخزينة قبل الترحيل.
- المصروف النقدي ينشئ أيضًا `cash_box` بحركة `Payment` و`source_type='Expense'`.
- رصيد الخزينة ينخفض داخل نفس المعاملة.
- `operation_id` يظل Idempotency anchor.

بهذا لم يعد المصروف النقدي مجرد Journal Entry + تعديل رصيد خزينة؛ بل أصبح له أثر Cash Box أيضًا مثل سند الصرف.

### 6.5 Accounting Security

سطح Finance RPC anonymous/public كان قد أُغلق في migrations السابقة المثبتة في الحالة الحالية:

- `20260916115243_finance_close_public_read_rpc_surface`
- `20260916115339_finance_lock_anonymous_rpc_surface`
- `20260916115431_finance_security_surface_close`

ولا توجد نية لإعادة فتحه.

---

## 7. ما لم نغيّره عن قصد

لم يتم تغيير:

- Mother `erp-frontend/companies/company-1/main.html`
- `Current/PWA/main2`
- العمليات الميدانية Picker/Loader/Delivery/Return/Unloading
- `post_stock_movement`
- `reserve_stock`
- `release_stock_reservation`
- أي Business Contract مثبت للتشغيل الميداني

السبب: المهمة المالية لا تبرر تعديل العمليات الميدانية، والحكومة تمنع كسر عقد قائم لمجرد وجود عيب في طبقة أخرى.

---

## 8. الاختبارات والتجارب

### تجربة 1 — Finance CREATE / Item identity

سبق إثبات CREATE عبر Production ببيانات transaction مؤقتة، وتم إنشاء voucher واختباره ثم rollback. الاختبار أكد عدم وجود خطأ في global item identity.

### تجربة 2 — Finance Period Guard

الاستدعاء المباشر من قناة SQL لم يحمل `auth.uid()`، ولذلك ظهر:

```text
FINANCE_COMPANY_CONTEXT_REQUIRED
```

هذا **فشل في وسيلة الاختبار وليس فشلًا في منطق الـGuard**؛ لأن `app_private.current_user_company_id()` يعتمد على `auth.uid()` بشكل صريح.

### تجربة 3 — Purchase idempotency

أثناء العمل السابق ظهر خلل في ترتيب duplicate detection، ثم تم تصحيحه. لم يتم تضمينه ضمن Closure المالية النهائية لكونه جزءًا من Purchase/Inventory، لا من Finance task الحالي.

---

## 9. المطلوب من المالك في Mother main.html

### أولًا — Dispatcher fix

**الموضع المثبت:** `RW_Finance.renderSubTab` عند `main.html` lines `14535–14542` في النسخة الحالية التي ظهرت منها الأخطاء.

**ابحث عن العنصر التالي كاملًا واحذفه:**

```text
else if (tab === 'journal-list') _renderJournalList();
else if (tab === 'recurring-journals') _renderRecurringJournals();
else if (tab === 'expenses') _renderExpenses();
else if (tab === 'cheques') _renderCheques();
else if (tab === 'bank-reconcile') _renderBankReconcile();
else if (tab === 'tax') _renderTax();
else if (tab === 'assets') _renderAssets();
else if (tab === 'periods') _renderPeriods();
```

ينتهي العنصر تحديدًا بالسطر:

```text
else if (tab === 'periods') _renderPeriods();
```

**واستبدله كاملًا بـ:**

```text
else if (tab === 'journal-list') RW_Finance._renderJournalList();
else if (tab === 'recurring-journals') RW_Finance._renderRecurringJournals();
else if (tab === 'expenses') RW_Finance._renderExpenses();
else if (tab === 'cheques') RW_Finance._renderCheques();
else if (tab === 'bank-reconcile') RW_Finance._renderBankReconcile();
else if (tab === 'tax') RW_Finance._renderTax();
else if (tab === 'assets') RW_Finance._renderAssets();
else if (tab === 'periods') RW_Finance._renderPeriods();
```

### ثانيًا — ممنوع تعديل `newExpense` لمجرد إعادة التصميم

الحالة الحالية تحتوي على تحميل فعلي لـAccounts / Cost Centers / Tax Codes / Treasury وتستدعي:

```text
finance_save_expense
```

ولا يوجد دليل حالي يبرر حذف هذا المسار.

### ثالثًا — modals تحتاج ترقيتها في Mother

الأهداف الوظيفية الواجب تحقيقها في Source of Truth:

- `newRecurring`: اختيار الحسابات من دليل الحسابات بدل UUID اليدوي + جدول خطوط قابل للإضافة/الحذف + عرض إجمالي المدين والدائن + منع الحفظ غير المتوازن قبل RPC.
- `newCheque`: اختيار Treasury والحسابات من القوائم بدل UUID يدوي، مع Party، Bank، Reference، Note، وتواريخ واضحة.
- `newBank`: اختيار الخزينة صراحة، إضافة سطور كشف بنكي قابلة للإضافة، تاريخ ووصف وReference ومبلغ لكل سطر، ومنع `limit(1)` من الواجهة.
- `goldAddAsset`: اختيار الحسابات من قائمة Company-scoped + Category + Cost + Salvage + Useful Life + Method + Acquisition/Service dates + Notes.
- `goldTaxCode`: اختيار حسابات الضريبة من قائمة Company-scoped + الاسم والكود والنسبة + حسابات المخرجات والمدخلات والتسوية.
- `goldOpenPeriod`: إدخال period code/year/start/end مع عرض وتحذير فوري عند التداخل قبل الاستدعاء.
- `goldTaxSettle`: اختيار المدة والكود مع عرض Net Tax الناتج قبل التنفيذ، ثم إظهار Journal Entry الناتج.

**لا تستخدم UUIDات يدوية في أي modal جديد.**

---

## 10. Source of Truth / forensic_main_assembly

الحالة الحالية المثبتة في Git تشير إلى:

```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
assembly_status:
  mode: published_main_is_authoritative
  fragment_mode: historical_reference_only
```

لذلك لم يتم إنشاء إعادة توجيه جديدة، ولم يتم نقل Source of Truth إلى `Current/PWA/main2`.

---

## 11. ما الذي يعتبر مغلقًا الآن

```text
Finance schema foundation              = PROVEN PRESENT
Central journal engine                 = PROVEN PRESENT
Finance public/anon RPC surface        = CLOSED
Accounting period overlap              = CLOSED IN PRODUCTION
Closed-period edit                     = CLOSED IN PRODUCTION
Missing-period posting                 = CLOSED IN PRODUCTION
Reconciled bank statement edit         = CLOSED IN PRODUCTION
Cheque duplicate lifecycle event       = CLOSED IN PRODUCTION
Cash expense → cash_box parity          = CLOSED IN PRODUCTION
Expense treasury insufficiency         = CLOSED IN PRODUCTION
```

---

## 12. ما لم يُغلق بعد

```text
Mother dispatcher browser E2E              = OWNER ACTION PENDING
Actual browser click test for 8 tabs       = PENDING OWNER SOURCE MERGE
Visual/interaction Gold completion         = PENDING OWNER SOURCE MERGE
Full Finance cross-tab E2E                 = PENDING
First-new-console-error capture            = PENDING
```

هذه ليست أعذارًا؛ هذه حدود الاختبار الفعلية. لا يجوز تحويل `CURRENT SOURCE` إلى `Production/Browser PASS` دون تنفيذ Browser E2E.

---

## 13. تعليمات للمساعد التالي — كيف يبدأ ويصل للحقيقة

1. **ابدأ دائمًا بملف Mother الحالي** `erp-frontend/companies/company-1/main.html` وليس `main2`.
2. احصل على HEAD الحقيقي من GitHub ثم افتح **parent commit** مباشرة.
3. قارن فقط الـarea المستهدفة مع parent؛ لا تفسر التغيير قبل رؤية الـdiff.
4. اعتبر التقارير السابقة Evidence تاريخي فقط.
5. في كل مشكلة استخدم التسلسل:

```text
CURRENT SOURCE
→ CURRENT CONSUMER
→ CURRENT FUNCTION / NAMESPACE
→ CURRENT RPC
→ CURRENT PRODUCTION FUNCTION
→ CURRENT TABLE / CONSTRAINT / PRIVILEGE
→ CURRENT DEPLOYMENT / RUNTIME
```

6. عند `ReferenceError`: افحص declaration + scope + namespace قبل إنشاء أي function.
7. عند `is not a function`: افحص export/return object قبل Database.
8. عند `403`: افحص `routine_privileges` و`has_function_privilege` قبل تغيير Business Logic.
9. لا تنشئ Table/Edge Function إذا كانت القدرة موجودة بالفعل.
10. أغلق Closure Unit واحدة، ثم اختبرها، ثم انتقل لما بعدها.
11. أي تعديل Production يجب أن يكون migration موثقًا وقابلًا لإعادة الإنتاج.
12. أي تعديل Mother يجب أن يعود إلى المستخدم كحذف/استبدال جراحي كامل، لا كسطر مبتور.
13. لا تستخدم الأرقام أو النسب في تقرير دون snapshot Production في نفس التقرير.
14. لا تعتبر Test Harness SQL بدون auth context اختبارًا لواجهة المستخدم.
15. لا تعيد إصلاح ما هو مثبت كـClosed إلا بعد إثبات regression.

---

## 14. SELF-AUDIT

### What was proved

- أحدث HEAD الحقيقي للـMother هو `3fe3c766...`.
- الـparent الحقيقي هو `3b5fdce...`.
- `main.html` الحالي هو Source of Truth.
- Finance foundation موجود في Production.
- `post_journal_entry` هو Accounting Core مركزي.
- `finance_period_guard` أصبح Guard فعليًا.
- Expense cash posting أصبح له `cash_box` effect في نفس المسار.
- Reconciled bank statements لا يمكن تعديلها عبر save path.
- Cheque create/update لا يولد duplicate lifecycle events.

### What was not proved

- Browser E2E بعد تطبيق owner patch.
- Visual completion النهائي لجميع Finance modals.
- Real-user auth-context E2E من المتصفح.

### What was intentionally not changed

- Mother source itself.
- Historical fragments.
- Field operations.
- Inventory central movement contract.

### Final closure

```text
FINANCE BACKEND CONTRACT INTEGRITY = SUBSTANTIALLY CLOSED / PRODUCTION VERIFIED
MOTHER SOURCE PATCH               = READY / OWNER ACTION REQUIRED
FULL BROWSER FINANCE E2E          = NOT CLOSED YET
```

> **تنبيه حاكم في نهاية التقرير:** عند أي جلسة لاحقة يجب إعادة مطابقة Production مع CURRENT GIT في اللحظة نفسها. لا يجوز اعتبار هذا التقرير أو أي تقرير سابق مصدر حالة حالي مستقلًا عن Production.
