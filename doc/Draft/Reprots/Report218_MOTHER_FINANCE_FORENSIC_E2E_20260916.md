# Report218 — التحقيق الجنائي الحالي في الإدارة المالية بالنظام الأم

**التاريخ:** 2026-09-16
**المرحلة:** Mother Finance / E2E / Current-State Reconciliation

> **النقطة الحاكمة — اقرأها بعناية:** ملف `companies/company-1/main.html` في مستودع `papamohammed77-glitch/erp-frontend` هو **Source of Truth الفعلي لهذه المهمة**. لا يملك Report217 ولا `CURRENT_STATE.md` ولا أي fragment تاريخي حق تعريف الحالة الحالية إذا تعارض مع CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.
>
> **تكرار حاسم في الهدف:** اختبار E2E يجب أن يُبنى على `companies/company-1/main.html` الحالي نفسه، لا على `Current/PWA/main2` ولا على نسخة تاريخية ولا على تقرير سابق. أي Closure لاحق يبدأ من هذه الحقيقة المثبتة ولا يعيد إصلاح ما ثبت أنه موجود في CURRENT SOURCE.

## 1. نطاق المهمة

الهدف كان التحقيق الجنائي في أخطاء Console المرتبطة بتبويب الحسابات والإدارة المالية، وتحديد السبب الحقيقي من المصادر الحالية، ثم تنفيذ ما يدخل ضمن صلاحيات Production، وتقديم إصلاحات النظام الأم للمالك بصيغة جراحية دقيقة.

الأخطاء الأصلية المفحوصة:

```text
main:14542 Uncaught ReferenceError: _renderPeriods is not defined
main:14541 Uncaught ReferenceError: _renderAssets is not defined
main:14540 Uncaught ReferenceError: _renderTax is not defined
main:14539 Uncaught ReferenceError: _renderBankReconcile is not defined
main:14538 Uncaught ReferenceError: _renderCheques is not defined
main:14537 Uncaught ReferenceError: _renderExpenses is not defined
main:14536 Uncaught ReferenceError: _renderRecurringJournals is not defined
main:14535 Uncaught ReferenceError: _renderJournalList is not defined
```

تم أيضًا إعادة فحص Production security surface للدوال المالية لأن نجاح E2E الوظيفي لا يكفي إذا بقيت RPCs مكشوفة لـPUBLIC/anon.

---

## 2. مصادر التحقيق الحالية

### CURRENT GIT

المستودع:

`papamohammed77-glitch/erp-frontend`

أحدث HEAD مثبت:

`f1860e81f58def17090302a90b23289de37e93f1`

رسالته:

`forensic: persist current Mother inventory extract`

والـparent المباشر المثبت:

`17f0b4d504d62e312f9ba59cee6aee2cf54eb71a`

رسالة الـparent:

`Add new render functions to RW_Finance`

الـparent هو النقطة التاريخية المباشرة التي تهم هذا العطل لأنه أضاف صراحةً exports للـFinance renderers إلى namespace العامة.

كما أن HEAD الحالي نفسه لم يغيّر Mother main؛ بل حدّث forensic extract فقط.

### CURRENT SOURCE

الملف المعتمد:

`companies/company-1/main.html`

Current main blob SHA المثبت:

`f45a5a943629ea2b5891a4ef0c99049c493ab474`

والـforensic extract الحالي يثبت 24,150 سطرًا وحجم 1,360,026 بايت وSHA256:

`7b7d3968f7cdf7be69f5dd1c7d20ad61a698548b8aba341853a3f6593a491754`

### CURRENT PRODUCTION / DATABASE

Supabase Production project:

`fiilmooggumokxanwiyx`

تم فحص PostgreSQL function definitions وsignatures وEXECUTE privileges وruntime read probes مباشرة.

### CURRENT DEPLOYMENT EVIDENCE

تم فحص آخر Git chain ووجود الـGold Finance namespace في النسخة الحالية، ولم تُستخدم التقارير القديمة لتعريف الحالة الحالية.

---

## 3. النتيجة الجنائية الأساسية — السبب الحقيقي للـConsole

السبب الحالي ليس غياب Finance renderer، وليس غياب Gold Extension، وليس نقص RPC في PostgreSQL.

الوقائع المثبتة من CURRENT SOURCE:

1. `renderSubTab` داخل `RW_Finance` يستدعي في الموضع الحالي:

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

2. هذه الأسماء موجودة بالفعل كـfunctions داخل `RW_Finance_GoldExtension`، والـreturn object الحالي يعيدها بهذه الصورة:

```text
journalList
renderAssets
renderTax
renderPeriods
renderBankReconcile
renderRecurring
renderExpenses
renderCheques
```

3. الـparent commit `17f0b4d...` أضاف إلى `RW_Finance` public namespace:

```text
RW_Finance._renderJournalList = RW_Finance_GoldExtension.journalList;
RW_Finance._renderAssets = RW_Finance_GoldExtension.renderAssets;
RW_Finance._renderTax = RW_Finance_GoldExtension.renderTax;
RW_Finance._renderPeriods = RW_Finance_GoldExtension.renderPeriods;
RW_Finance._renderBankReconcile = RW_Finance_GoldExtension.renderBankReconcile;
RW_Finance._renderRecurringJournals = RW_Finance_GoldExtension.renderRecurring;
RW_Finance._renderExpenses = RW_Finance_GoldExtension.renderExpenses;
RW_Finance._renderCheques = RW_Finance_GoldExtension.renderCheques;
```

4. وهذه aliases موجودة أيضًا في CURRENT SOURCE الحالي، أي أن **Change B القديم الخاص بإضافة aliases لم يعد إصلاحًا مطلوبًا**.

إذن التناقض الحالي هو:

```text
CONSUMER / DISPATCHER
        ↓
local _renderJournalList / _renderAssets / ...
        ↓
غير معرفة داخل ذلك scope

بينما CURRENT SOURCE يحتوي فعليًا على:

RW_Finance._renderJournalList
RW_Finance._renderAssets
RW_Finance._renderTax
RW_Finance._renderPeriods
...
```

### الحكم

الـConsole regression الحالي هو **namespace binding mismatch بين dispatcher وpublic Finance namespace**.

المعالجة الصحيحة الحالية هي استخدام exports التي تم توفيرها بالفعل في الـparent/current source، وليس إزالة هذه exports ولا إعادة بناء Finance renderer.

هذا يختلف عن instruction القديمة في Report217 لأن Report217 كتب قبل وصول parent/current source الجديد الذي أضاف الـaliases.

---

## 4. أهمية parent commit

الـparent المباشر:

`17f0b4d504d62e312f9ba59cee6aee2cf54eb71a`

أضاف public bindings للـrender functions داخل `RW_Finance`.

هذا يجعل الـparent دليلًا سببيًا مباشرًا على المقصود المعماري للنسخة الحالية:

```text
Gold Extension renderer
        ↓
RW_Finance public alias
        ↓
Mother dispatcher
```

وبالتالي تعديل dispatcher الحالي إلى `RW_Finance._render...` ليس اختراعًا جديدًا؛ هو استكمال للربط الذي أُنشئ بالفعل في الـparent.

---

## 5. Current Source proof — Gold aliases الأخرى

لم يتم إعادة إضافة Gold action aliases لأن CURRENT SOURCE يحتويها بالفعل، ومنها:

```text
RW_Finance._goldAddAsset = RW_Finance_GoldExtension.goldAddAsset;
RW_Finance._goldDepreciate = RW_Finance_GoldExtension.goldDepreciate;
RW_Finance._goldDispose = RW_Finance_GoldExtension.goldDispose;
RW_Finance._goldTaxCode = RW_Finance_GoldExtension.goldTaxCode;
RW_Finance._goldTaxSettle = RW_Finance_GoldExtension.goldTaxSettle;
RW_Finance._goldOpenPeriod = RW_Finance_GoldExtension.goldOpenPeriod;
RW_Finance._goldChequeTransition = RW_Finance_GoldExtension.goldChequeTransition;
```

كما أن Gold Extension نفسها تعيد renderers/actions المطلوبة.

### قرار جراحي

لا يجوز تكرار Change B الخاص بهذه aliases ما دامت موجودة في CURRENT SOURCE.

هذا يمنع إعادة إصلاح ما تم إصلاحه بالفعل ويمنع duplicate bindings.

---

## 6. Current Production Finance DB review

تم فحص الدوال المالية الفعلية الموجودة في Production، ومن بينها:

```text
finance_journal_list
finance_list_recurring
finance_list_expenses
finance_list_cheques
finance_list_assets
finance_tax_report
finance_open_period
finance_close_period
finance_reopen_period
finance_open_bank_statement
finance_close_bank_statement
finance_save_expense
finance_save_cheque
finance_save_recurring
finance_save_tax_code
finance_tax_settle
finance_transition_cheque
save_fixed_asset
post_fixed_asset_depreciation
finance_dispose_asset
get_budget_vs_actual
```

كل الدوال الحساسة ذات الصلة موجودة فعليًا في Production.

لم يظهر أثناء فحص هذا العطل أي دليل يبرر إنشاء Finance table جديدة أو duplicate Finance engine.

---

## 7. Production security forensic finding إضافي

تم اكتشاف أن Production كانت تحتوي عددًا من `finance_*` functions مع EXECUTE متاح لـ`PUBLIC/anon` رغم أن التطبيق يستخدم authenticated sessions.

الدوال المكشوفة شملت قبل الإغلاق، ضمن مجموعة أوسع:

```text
finance_asset_register
finance_bank_match_candidates
finance_bank_reconciliation_summary
finance_current_period
finance_journal_detail
finance_journal_list
finance_list_recurring
finance_period_guard
finance_runtime_health
finance_tax_settlements_report
finance_validate_account_context
finance_validate_tax_accounts
finance_list_cheques
finance_list_expenses
```

### Production action المنفذ

تم تطبيق hardening في Production لإزالة EXECUTE من `PUBLIC, anon` عن كل `public.finance_%` functions مع إبقاء التنفيذ لـ:

```text
authenticated
service_role
```

كما أن `get_budget_vs_actual` كان قد أُغلق سابقًا لـPUBLIC/anon وتم التحقق من أن `authenticated` يملك EXECUTE.

### Production verification

بعد الإغلاق:

```text
Finance EXECUTE for PUBLIC/anon = 0 rows
```

واختبار مباشر للصلاحيات أثبت:

```text
anon_journal  = false
anon_expenses = false
anon_cheques  = false
auth_journal  = true
auth_budget   = true
```

هذا تغيير Production حقيقي وليس توصية نظرية.

---

## 8. Runtime DB probes

تم تشغيل probes مباشرة على Production للـFinance read functions التي يحتاجها CURRENT renderer.

النتائج:

```text
finance_journal_list    -> 2 rows
finance_list_recurring  -> 0 rows
finance_list_expenses   -> 0 rows
finance_list_cheques    -> 0 rows
finance_list_assets     -> 1 row
finance_tax_report      -> 0 rows
```

هذه النتائج تثبت أن طبقة PostgreSQL المطلوبة للـrenderers موجودة وتعمل، وبالتالي `ReferenceError` ليس سببه missing RPC.

لم يُنشأ أي سجل تجريبي دائم بواسطة هذه probes.

---

## 9. هل نحتاج جدولًا جديدًا؟

**لا.**

العطل الحالي يقع قبل الوصول إلى DB function call؛ وهو JavaScript namespace mismatch.

كما أن Production تحتوي بالفعل على البنية المالية المطلوبة لهذه النطاقات:

- دليل الحسابات
- القيود اليومية
- الخزائن والبنوك
- المصروفات
- الشيكات
- الأصول والإهلاك
- الضرائب
- الفترات المحاسبية
- المصروفات المتكررة
- bank reconciliation
- budget/reporting

إنشاء جداول بديلة الآن سيكون دينًا معماريًا جديدًا بلا سبب مثبت.

---

## 10. هل نحتاج Edge Function جديدة؟

**لا.**

الـFinance renderer الحالي يستخدم Supabase RPC مباشرة في الوظائف المالية، والـRPCs المطلوبة موجودة في Production.

إنشاء Edge wrapper جديد لهذا العطل سيضيف طبقة لا يحتاجها الـcurrent contract، وسيزيد نقاط الـdrift.

---

## 11. Surgical Change — Mother main.html فقط

**ممنوع على المساعد تعديل `erp-frontend/companies/company-1/main.html`.**

المالك هو الذي يطبق هذا التعديل على Source of Truth.

### CHANGE A — إصلاح dispatcher

**الموضع الحالي المثبت:** `main.html`، داخل `RW_Finance.renderSubTab`، عند Console lines `14535` إلى `14542` تقريبًا في النسخة التي ظهر منها الخطأ.

### ابحث عن العنصر التالي كاملًا:

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

**احذف هذا العنصر كاملًا، وينتهي تحديدًا بالسطر الأخير:**

```text
else if (tab === 'periods') _renderPeriods();
```

### واستبدله كاملًا بهذا العنصر:

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

**هذا هو التعديل الوحيد المطلوب لعلاج الـ8 ReferenceErrors الحالية من مصدرها المثبت.**

لا تحذف أي alias من نهاية Finance namespace.

لا تضف Gold aliases مرة أخرى لأنها موجودة بالفعل.

---

## 12. لا تطبق Change B القديم

Change B الموجود في Report217 كان إضافة aliases مثل:

```text
RW_Finance._goldAddAsset
RW_Finance._goldTaxCode
RW_Finance._goldOpenPeriod
```

CURRENT SOURCE الحالي يحتويها بالفعل.

لذلك:

```text
DO NOT RE-ADD
DO NOT DUPLICATE
DO NOT REWRITE
```

أي تكرار لها حاليًا سيكون تعديلًا غير ضروري.

---

## 13. Modal state — ما لم يُغلق بعد

تم فحص المودالات المالية الحالية.

ما زال هناك UX debt غير مرتبط بخطأ Console الحالي، أهمه أن بعض النوافذ تعرض UUIDs للحسابات يدويًا، مثل:

- `goldAddAsset`
- `goldDispose`
- `goldTaxCode`

لكن هذه النقطة **ليست جزءًا من إصلاح ReferenceError**، ولم تُعدّل في هذه الجلسة لأن المطلوب هو عدم تغيير behavior قائم دون دليل E2E جديد.

الخطوة الصحيحة التالية بعد إغلاق Console هي E2E لهذه المودالات من current source، ثم استبدال UUID inputs بقوائم حسابات company-scoped إذا أثبت E2E أن هذا هو الـnext functional gap.

---

## 14. أخطاء/محاولات التحقيق

لم تحدث أي عملية Production غير مقصودة على بيانات الأعمال.

كانت هناك أثناء جمع الأدلة محاولات وصول إلى مسارات غير موجودة/ملفات كبيرة لا يعيدها GitHub Contents API بسبب الحجم، وتم تجاوز ذلك باستخدام:

- Git commit metadata
- blob evidence
- forensic extract
- resource search
- Supabase direct PostgreSQL evidence

هذه القيود لم تغيّر أي قرار مبني على حقيقة غير مثبتة.

لم يتم تعديل Mother main من المساعد.

---

## 15. Verification Matrix

| الفحص | النتيجة |
|---|---|
| قراءة Governance principle | PASS |
| قراءة completion directive | PASS |
| قراءة Report217 كمرجع استرشادي | PASS |
| فحص أحدث HEAD | PASS |
| فحص parent commit | PASS |
| تحديد Current Mother source | PASS |
| فحص current main blob | PASS |
| إثبات وجود Gold renderer exports | PASS |
| إثبات وجود current `_render*` aliases | PASS |
| تحديد mismatch داخل dispatcher | PASS |
| فحص Finance RPC existence | PASS |
| فحص Finance RPC runtime probes | PASS |
| فحص execute privileges | PASS |
| إزالة PUBLIC/anon Finance EXECUTE | PASS / PRODUCTION |
| فحص عدم الحاجة إلى table جديدة | PASS |
| فحص عدم الحاجة إلى Edge Function جديدة | PASS |
| تعديل Mother main بواسطة المساعد | NO — حسب الصلاحيات |
| Browser E2E بعد التعديل الحالي | PENDING OWNER ACTION |

---

## 16. حالة الإغلاق الحالية

### CLOSED

1. **Production Finance anonymous execute surface:** CLOSED / PRODUCTION VERIFIED.
2. **`get_budget_vs_actual` execute permission:** CLOSED / PRODUCTION VERIFIED.
3. **Root cause of 8 ReferenceErrors:** PROVEN.
4. **Gold aliases diagnosis:** PROVEN; aliases already present in current source.
5. **Finance DB renderer dependencies:** PROVEN present and callable.
6. **Source of Truth path in `forensic_main_assembly.yml`:** VERIFIED.

### NOT YET CLOSED

1. تطبيق CHANGE A على Mother main بواسطة المالك.
2. Reload للملف المنشور بعد الدمج.
3. الضغط الفعلي على تبويبات Finance الثمانية.
4. تسجيل أول Console error جديد فقط إن ظهر.
5. التحقق من أن كل زر ينقلك إلى renderer المطلوب دون ReferenceError.
6. فتح modals الرئيسية ومراجعة UX/business completion بعد اختفاء Console root error.

لا يجوز إعلان `MOTHER FINANCE E2E = 100% CLOSED` قبل تنفيذ browser E2E الفعلي بعد دمج CHANGE A.

---

## 17. التعليمات التنفيذية للمالك الآن

نفذ على `companies/company-1/main.html` فقط:

```text
ابحث عن المقطع الكامل ذو 8 أسطر `_render...` في RW_Finance.renderSubTab.
احذفه كاملًا حتى السطر المنتهي بـ `_renderPeriods();`.
استبدله كاملًا بالمقطع ذي 8 أسطر `RW_Finance._render...` المذكور في CHANGE A.
```

لا تعدّل نهاية Finance alias block.

لا تعدّل `Current/PWA/main2`.

لا تعدّل `New-main`.

بعد الحفظ والرفع أعد فتح الصفحة واضغط التبويبات المالية، ثم اعمل Console capture لأول خطأ جديد فقط.

---

## 18. تعليمات للمساعد القادم — طريقة بدء التحقيق وتسلسله

**هذه التعليمات يجب أن تُقرأ قبل أي تعديل لاحق:**

1. ابدأ دائمًا من `CURRENT GIT` وليس من Report218 أو CURRENT_STATE.
2. احصل على أحدث commit الحقيقي في `erp-frontend`.
3. افتح الـparent المباشر لهذا commit، ثم افحص diff الخاص بالمنطقة محل المشكلة.
4. افتح current `companies/company-1/main.html` نفسه؛ لا تستخدم fragment تاريخي لتحديد الحالة.
5. إذا كان الملف كبيرًا، استخدم blob + forensic extract + targeted source search بدل الادعاء أنك قرأت نسخة غير متاحة.
6. trace أي Console error بهذا التسلسل:

```text
Browser consumer
→ dispatcher / onclick
→ local function or public namespace
→ return object / export
→ RPC
→ Production function
→ DB schema / privilege
```

7. عند `ReferenceError` افحص أولًا scope + declaration + return object + public alias. لا تنشئ function جديدة قبل إثبات عدم وجود الموجودة.
8. عند `is not a function` افحص function declaration + return object + namespace binding قبل أي DB change.
9. عند `403` افحص `routine_privileges` و`has_function_privilege` قبل لمس business logic.
10. عند وجود alias بالفعل في CURRENT SOURCE، لا تعِد إصلاحه.
11. عند وجود RPC فعلي في Production، لا تنشئ Edge Function بديلة إلا إذا ثبت أن الـconsumer يحتاج contract مختلفًا.
12. لا تنشئ table جديدة إلا إذا ثبت أن الـbusiness capability غير موجودة في current schema.
13. التزم بالقاعدة:

```text
UNDERSTAND
→ CURRENT SOURCE
→ CURRENT PRODUCTION
→ CURRENT DB
→ CURRENT DEPLOYMENT
→ IDENTIFY GAP
→ ONE SURGICAL CHANGE
→ VERIFY
→ CLOSE
→ NEXT OPEN GAP
```

14. لا تعلن أي percentage أو Closure قبل مطابقة Production في نفس لحظة التقرير.
15. عند تعديل Mother main: أعطِ المالك العنصر الكامل للحذف، وحدد آخر سطر فيه، ثم البديل الكامل.
16. عند تعديل Production: نفذ التغيير بنفسك، ثم verify privileges/signature/runtime مباشرة.
17. لا تعُد إلى `Current/PWA/main2` إلا للاستدلال التاريخي، وليس كمصدر تحديث.
18. إذا ظهر عطل جديد بعد CHANGE A، لا تعُد إلى الأخطاء الثمانية القديمة إلا بدليل regression جديد.

---

## 19. Final Self-Audit

### What was proved

- Current HEAD والـparent الحقيقيان تم فحصهما.
- Current Mother main هو Source of Truth.
- الـparent أضاف الـFinance renderer aliases التي يعتمد عليها الحل الحالي.
- الـdispatcher الحالي ما زال يستدعي local `_render...`، وهذه هي علة الـReferenceErrors.
- Gold action aliases موجودة بالفعل، لذلك لا حاجة لتكرارها.
- Finance RPC dependencies موجودة في Production وتعمل.
- Finance anonymous execute surface تم إغلاقه في Production.

### What was not proved

- Browser E2E بعد تنفيذ CHANGE A من المالك.
- UX completion النهائي لكل modal مالي.

### What was fixed

- Production security surface للدوال المالية.
- `get_budget_vs_actual` permission remained verified.

### What was deliberately not changed

- Mother `main.html`.
- Finance business functions.
- Finance tables.
- Gold action aliases الموجودة بالفعل.
- العمليات المخزنية والتطبيقات التنفيذية المنفصلة.

### Final closure

```text
CURRENT FINANCE ROOT CAUSE = PROVEN
PRODUCTION SECURITY CLOSURE = CLOSED
MOTHER SOURCE SURGICAL PATCH = READY FOR OWNER
BROWSER E2E = PENDING OWNER MERGE
FULL FINANCE E2E = NOT YET CLOSED
```

**القاعدة التالية:** بمجرد تنفيذ CHANGE A وإعادة الاختبار، نبدأ من أول Console error جديد فعلي فقط، ولا نعيد هذه النقطة من الصفر ما لم يظهر regression مثبت في CURRENT SOURCE/CURRENT RUNTIME.
