# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-11 — MAIN1 FORENSIC RE-CHECK R5

### GOVERNING TARGET — NON-NEGOTIABLE
هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع ولا يُتعامل معه كإضافات شكلية.

الحوكمة الحاكمة: الدراسة أولًا → إعادة بناء العقد التاريخي → تتبع السلوك الحالي → تتبع البيانات والصلاحيات والتدفق → تحديد الفجوة الفعلية → التعديل الجراحي → الاختبار → التحقق من Production → التوثيق.

## SOURCE-OF-TRUTH GOVERNANCE
- Production الحالية هي حقيقة التنفيذ.
- Git هو المصدر القانوني القابل لإعادة الإنتاج، وليس بديلًا عن Production.
- التقارير التاريخية أدلة جنائية وليست حقيقة حالية.
- Source of Truth التحريري للملف الأم: `Current/PWA/main2/main1.md ... main11.md`.
- `Original/PWA/main/*` مرجع تاريخي immutable.
- `Current/PWA/New-main` مرحلة تاريخية فقط، وليس مصدر مراجعة حالي.
- Main1 مسؤول عن Shell/Control Plane، والواجهات الوظيفية موزعة على Main2–Main11.
- لا Assembly قبل اكتمال ومراجعة الأجزاء الـ11.

## CURRENT GIT TRUTH — FRESH R5
- Main1 current SHA: `8275750c05c353dec9ed825ca4aff7a4f6d05fab`.
- Main1 source: `Current/PWA/main2/main1.md`.
- لم يتم تعديل Main1 بواسطة المساعد.
- Owner surgical changeset R5: `doc/Draft/Reprots/OWNER_CHANGESETS_20260911_MAIN1_R5.md`.
- Owner changeset SHA: `f8c33c3e39dd4464c4e39f1b4b02ca03699369b2`.
- Final session report: `doc/Draft/Reprots/MAIN1_FORENSIC_RECHECK_20260911_R5.md`.
- Final session report commit: `5de4c4d1a8852750c4fb968fc1b21b5654ef8152`.
- Git HEAD after documentation commits: `5de4c4d1a8852750c4fb968fc1b21b5654ef8152`.

## ASSEMBLY SOURCE GOVERNANCE
- Assembly target remains `Current/PWA/main2/main1..main11.md`.
- `forensic_main_assembly.yml` has not been proven to exist in the previously checked locations and has not been invented.
- Assembly remains deferred until the 11 fragments are functionally complete and reviewed.

## FRESH PRODUCTION SNAPSHOT — 2026-09-11 R5
تم التحقق مباشرة من Production في UTC `2026-09-11 09:39:47.550805`.
- companies = 1
- branches = 2
- users = 24
- items = 17
- customers = 3
- orders = 0
- purchase_orders = 0
- stock_branches = 20
- inventory_log = 3
- audit_log = 1869
- active workflow_rules = 3
- workflow_log = 0

لم يتم تنفيذ business-data mutation في جلسة R5؛ التحقق الحالي كان read-only بالنسبة لـProduction.

## MAIN1 FORENSIC R5

### Already correct — DO NOT REAPPLY
- Finance actions use `perm: ['finance', 'finance_manager']`.
- HR uses `perm: 'hr'`.
- CRM uses `perm: 'customers'`.
- `isAllowed(item)` supports permission arrays with OR semantics.
- Owner + wildcard semantics remain preserved.
- Audit table/detail dynamic data are already rendered through DOM/textContent.
- `RW_Data` basic loads are company-scoped.

### MAIN1-N1 — OPEN OWNER SURGERY
Exact inline caller:
`onclick="window.togglePasswordVisibility('rw-password', this)"`

The current source contains the caller but no proven definition of `window.togglePasswordVisibility`.

Owner replacement is defined completely in R5: add `window.togglePasswordVisibility = function(inputId, button) { ... };` immediately before:
`const byId = id => document.getElementById(id);`

### MAIN1-N2 — OPEN OWNER SURGERY
Inside `RW_Notification`, exact function:
`function showPanel() {`

Current defect: constructed DOM listeners are attached, then lost because SweetAlert receives `root.outerHTML`.

Owner replacement in R5 changes the call to:
`html: root`
while preserving textContent and the listeners.

### MAIN1-N3 — OPEN OWNER SURGERY
Current login element:
`<a href="#" class="rw-forgot">نسيت كلمة المرور؟</a>`

Owner replacement in R5 changes it to an actionable button and adds the complete `resetPasswordForEmail()` handler immediately before:
`window.RW_Navigation = RW_Navigation;`

### MAIN1-N4 — OPEN DISCOVERY, NO SURGERY
Quick Search exists in Main1 as:
`<input type="text" class="rw-header-search-input" placeholder="بحث سريع...">`

No Main1-local Search contract sufficient for a safe implementation was proven. No handler was invented to avoid duplicate routing/search architecture.

### MAIN1-WF — OPEN
Exact function:
`function evaluate(tableName, event, recordId, recordData) {}`

Current proven false-success behavior remains:
- rule matching;
- actions represented as `pending`;
- no executor call;
- `workflow_log.status = 'success'` despite no action execution;
- errors in logging swallowed.

Production active rules remain:
1. `UpdateStockAndJournalOnPOReceive` → `update_inventory`, `create_journal_entry`.
2. `CreateJournalOnOrderDeliver` → `create_journal_entry`.
3. `CreateStockVoucherOnOrderConfirm` → `create_stock_voucher`.

No safe Executor/Dispatcher contract was proven from Production + current sources, so no replacement was invented.

## OWNER CHANGESET R5 — EXACT ACTIONS
Execute only these Main1 changes manually in `Current/PWA/main2/main1.md`:

1. `MAIN1-N1`
Find exactly:
`const byId = id => document.getElementById(id);`
Insert the complete `window.togglePasswordVisibility` block immediately above it.

2. `MAIN1-N2`
Inside `var RW_Notification = (function() {` find exactly:
`function showPanel() {`
Delete only that complete function through the line immediately before:
`function markAllRead() {`
Replace with the full function in R5.

3. `MAIN1-N3`
Find exactly:
`<a href="#" class="rw-forgot">نسيت كلمة المرور؟</a>`
Replace with the exact button in R5.
Then find exactly:
`window.RW_Navigation = RW_Navigation;`
Insert the complete forgot-password IIFE immediately above it.

Do not modify:
- `RW_Audit_renderTable()`.
- `RW_Audit_showDetails()`.
- Finance permissions.
- HR permission.
- CRM permission.
- `isAllowed()`.
- `function evaluate(tableName, event, recordId, recordData) {}`.
- `Original/PWA/main/main1.md`.

## MAIN2–MAIN11 STATUS
The canonical fragment set currently remains:
`Current/PWA/main2/main1.md ... main11.md`.
Their Git objects are present. Full parser/E2E functional closure for all eleven has not yet been proven in this checkpoint.

Known cross-fragment findings remain:
- Main7 has State Contract ambiguity around `RW_STATE.app.companyId` vs `RW_STATE.app.company.id`; do not normalize without runtime proof.
- Main8 Finance UI exists, but UI existence is not capability closure.
- Main9 reporting has explicit capability gates; do not call gated functionality complete without authoritative Production sources.
- Main11 has proven `(قيد التطوير)` content in HR documents.

## PRODUCTION / DATABASE GOVERNANCE
- No R5 mutation was made to Main1 business data in Production.
- Production was refreshed before final judgment.
- No claim of Production Functional Closure was made from Git alone.
- `workflow_rules` and `workflow_log` are currently separate global tables without `company_id`; no tenant column was invented.
- `notifications` and `notification_templates` likewise have no `company_id` in the current schema; no schema mutation was introduced for Main1.

## SYNTAX / VERIFICATION
- Main1 content and EOF boundary were directly verified against current Git.
- Full browser/parser execution remains NOT PROVEN in this checkpoint.
- Main2–Main11 parser/E2E remains NOT PROVEN.
- Therefore `Syntax 100% PASS` and `Functional 100% PASS` are not claimed.

## CLOSURE STATUS
- Governance reread: `CLOSED FOR R5`
- Main1 forensic reread: `CLOSED FOR R5`
- Fresh Production synchronization: `CLOSED FOR THIS CHECKPOINT`
- Main1 N1 password visibility: `OPEN — OWNER ACTION`
- Main1 N2 notification interaction: `OPEN — OWNER ACTION`
- Main1 N3 forgot password: `OPEN — OWNER ACTION`
- Main1 N4 quick search: `OPEN — CONTRACT DISCOVERY`
- Main1-WF: `OPEN — EXECUTOR CONTRACT DISCOVERY`
- Main1 functional closure: `OPEN`
- Main1 Gold/Diamond: `OPEN`
- Global functional completion: `OPEN`
- Global Gold/Diamond: `OPEN`
- Assembly: `DEFERRED`

## FINAL SELF-AUDIT
### What was proven
- Governing Gold/Diamond target reconfirmed.
- Main1 current path and SHA proven.
- Main1 EOF proven.
- Fresh Production snapshot proven at `2026-09-11 09:39:47.550805 UTC`.
- E/F/G were already present and were not duplicated.
- N1/N2/N3 defects are directly evidenced in current Main1.
- R5 Owner Change Set is committed and contains complete replacements.
- Workflow false-success remains proven and intentionally unpatched pending executor contract evidence.

### What was not proven
- Main1 owner surgery has not yet been applied to the fragment.
- Full browser/parser PASS.
- Full Main2–Main11 functional completion.
- Search contract.
- Workflow executor/dispatcher contract.
- Final assembly.
- Production E2E across all capabilities.
- Global Gold/Diamond.

## NEXT EXACT RESUMPTION POINT
`MAIN1 OWNER MERGE VERIFICATION`

Then:
`MAIN1-WF — EXECUTOR CONTRACT DISCOVERY`

Do not return to:
- `Current/PWA/New-main` as a development source.
- `Current/PWA/main/*` as a development source.

## REQUIRED QUESTIONS
### هل تحقق الهدف الأصلي: استكمال ملفات النظام الأم وظيفيًا بالكامل؟
لا. لا توجد أدلة تسمح بالإعلان عن اكتمال النظام الأم بالكامل في هذا checkpoint.

### هل مازالت هناك أي تبويب أو وظيفة ناقصة أو هيكلية فقط أو `(قيد التطوير)`؟
نعم. Main1 لديه N1/N2/N3 قبل owner merge، Workflow executor مفتوح، Search contract مفتوح، وMain11 لديه `(قيد التطوير)` مثبت، كما أن functional completeness لـMain2–Main11 لم تثبت بالكامل.

### متى يكتمل؟
لا يوجد تاريخ يمكن إثباته دون تخمين. الإغلاق مشروط بإكمال owner surgeries، إغلاق Executor contract، إكمال كل capabilities end-to-end، parser/browser PASS، Assembly صحيح من `Current/PWA/main2`, ثم Production E2E verification.

## GOVERNANCE RULE
لا قيمة لأي نسبة أو تقرير قبل مطابقة Production الحالية في نفس لحظة التقرير. لا تعديل يبنى على الظن أو التخمين. وجود واجهة أو Commit أو Staging PASS لا يساوي Functional Production Closure.
