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
- Final report content SHA: `c448f89dd01f42ceefb7f092ff41f43b18ea2643`.
- Latest documentation commit/HEAD قبل تحديث هذه الحالة: `8f07ed9644efd94f60ea9d1d78ac198b71def3de`.
- أحدث source commit لـMain1 قبل تحديث هذه الحالة: `ecc5a33c55520cb0d9233d7934ed0423fe3a9ef7`.

## ASSEMBLY SOURCE GOVERNANCE
- Assembly target remains `Current/PWA/main2/main1..main11.md`.
- `forensic_main_assembly.yml` لم يتم إثبات وجوده في المواقع التي تم فحصها ولم يتم اختراعه.
- Assembly remains deferred until the 11 fragments are functionally complete and reviewed.

## FRESH PRODUCTION SNAPSHOT — MAIN2 RECHECK
تم التحقق مباشرة من Production في UTC `2026-09-11 20:16:24.49657`.
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
`const byId = id => document.getElementById('id');`
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

## MAIN2 RECHECK — 2026-09-11
### Current source
- Source: `Current/PWA/main2/main2.md`.
- Current blob SHA: `baee3cc02ae5701e6fbcbad12e57e2930afc4ae4`.
- Last Main2 source commit remains `625e7a8df17042f8701dc288f98eae381bdc3e82`.
- Current Git HEAD after Main1 updates and Main2 report: `8f07ed9644efd94f60ea9d1d78ac198b71def3de`.
- `Original/PWA/main/main2.md` was reviewed as historical reference only.
- Main2 was not modified by the assistant.

### R118/R119 reconciliation
The five historical Company Context defects and the Dashboard P&L defect recorded in Report118/R119 are already fixed in the current Main2 source and must not be reapplied.

### Main2 proven contract facts
- `RW_Dashboard.loadAll()` is company-scoped and uses Production `get_profit_loss` for P&L.
- `_loadMovementReport()` uses the same physical movement type set currently accepted by Production `post_stock_movement`.
- Main2 bulk adjustment already uses an operation ID/fingerprint and refreshes data after success.
- Item opening balance is routed through `create_item_with_opening_stock`, which in Production posts `InventoryIncrease` through `post_stock_movement`.
- No `(قيد التطوير)` string was found in the current Main2 source during the targeted review.
- No safe evidence justified rewriting the Matrix branch-filter semantics, so it was intentionally not changed.

### MAIN2-D1 — OPEN OWNER ACTION
Current `renderTopItemsChart(details)` declares the UI text:
`أفضل 10 أصناف (اضغط للتفاصيل)`

but its click handler only runs:
`RW_Navigation.navigate('items');`

and does not open/filter the selected item. This is a proven UI/scope mismatch, not a guessed Business Rule.

Exact owner action is documented in:
`doc/Draft/Reprots/Report121_Main2_Forensic_Recheck_20260911.md`

Exact current location:
`Current/PWA/main2/main2.md` lines `352–387`.

Owner must replace the complete `function renderTopItemsChart(details) { ... }` block only; do not modify the surrounding Dashboard functions.

### Production fixes executed from Main2 dependency closure
Production functions/endpoints updated directly:
- `save-item` → version 13: company context and item-management permission enforcement; opening stock remains canonical.
- `delete-item` → version 4: company-scoped deletion and item permission enforcement.
- `save-category` → version 4: company-scoped create/update/delete/replacement and permission enforcement.

`bulk-stock-adjustment` was already version 6 with user-derived company context; no duplicate repair was applied.

### Syntax / Runtime status
- GitHub workflow `.github/workflows/validate-main2-fragments.yml` exists and is configured to run `node --check` over Main1–Main11.
- No workflow run associated with the current Main2 blob was available to prove a full-file parser PASS.
- Main2 Full Syntax = `NOT PROVEN`.
- Main2 Browser Runtime = `NOT PROVEN`.
- Assembly = `DEFERRED`.

### Main2 closure
- Main2 source reconciliation: `CLOSED FOR THIS RECHECK`.
- Historical stale fixes: `DO NOT REAPPLY`.
- Main2-D1: `OPEN — OWNER ACTION`.
- Main2 Production dependency repairs: `DEPLOYED`.
- Main2 Gold/Diamond: `OPEN`.

## MAIN2–MAIN11 STATUS
The canonical fragment set remains:
`Current/PWA/main2/main1.md ... main11.md`.
Their Git objects are present. Full parser/E2E functional closure for all eleven has not yet been proven in this checkpoint.

Known cross-fragment findings remain:
- Main7 has State Contract ambiguity around `RW_STATE.app.companyId` vs `RW_STATE.app.company.id`; do not normalize without runtime proof.
- Main8 Finance UI exists, but UI existence is not capability closure.
- Main9 reporting has explicit capability gates; do not call gated functionality complete without authoritative Production sources.
- Main11 has proven `(قيد التطوير)` content in HR documents.

## PRODUCTION / DATABASE GOVERNANCE
- Production was refreshed before final Main2 judgment.
- No R5 business-data mutation was made as part of Main1.
- Main2 dependency repairs were limited to capability/security code and did not alter business data.
- `workflow_rules` and `workflow_log` are currently global tables without `company_id`; no tenant column was invented.
- `notifications` and `notification_templates` likewise have no `company_id` in the current schema; no schema mutation was introduced for Main1.

## SYNTAX / VERIFICATION
- Main1 content and EOF boundary were directly verified against current Git.
- Main2 full source content and EOF boundary were retrieved from the current Main2 blob.
- Main2–Main11 parser/E2E remains NOT PROVEN.
- Therefore `Syntax 100% PASS` and `Functional 100% PASS` are not claimed.

## CLOSURE STATUS
- Governance reread: `CLOSED FOR R5`
- Main1 forensic reread: `CLOSED FOR R5`
- Fresh Production synchronization: `CLOSED FOR MAIN2 RECHECK`
- Main1 N1 password visibility: `OPEN — OWNER ACTION`
- Main1 N2 notification interaction: `OPEN — OWNER ACTION`
- Main1 N3 forgot password: `OPEN — OWNER ACTION`
- Main1 N4 quick search: `OPEN — CONTRACT DISCOVERY`
- Main1-WF: `OPEN — EXECUTOR CONTRACT DISCOVERY`
- Main1 functional closure: `OPEN`
- Main2-D1: `OPEN — OWNER ACTION`
- Main2 full syntax/runtime: `OPEN — NOT PROVEN`
- Main2 Gold/Diamond: `OPEN`
- Global functional completion: `OPEN`
- Global Gold/Diamond: `OPEN`
- Assembly: `DEFERRED`

## FINAL SELF-AUDIT
### What was proven
- Governing Gold/Diamond target reconfirmed.
- Main2 current source and SHA proven.
- Main2 historical R118/R119 defects were reconciled against the current source and were not reapplied.
- Fresh Production snapshot was measured at `2026-09-11 20:16:24.49657 UTC`.
- Production dependency repairs were deployed for save-item, delete-item, and save-category.
- `post_stock_movement` remains the Production Physical Stock engine.
- Main2 contains one currently proven Owner source defect: Top Items detail navigation.
- Report121 was committed to the canonical report sequence.

### What was not proven
- Main2 owner surgery has not yet been applied to the fragment.
- Full Main2 parser PASS.
- Browser/PWA runtime PASS.
- Full Main2–Main11 functionality and assembly readiness.
- Workflow executor/dispatcher contract.
- Quick Search contract.
- Final assembly.
- Production E2E across all capabilities.
- Global Gold/Diamond.

## NEXT EXACT RESUMPTION POINT
`MAIN2 OWNER SURGERY VERIFICATION — MAIN2-D1`

After owner applies MAIN2-D1:
`READ MAIN2 TO EOF → SYNTAX → RECHECK GIT → RECHECK PRODUCTION → CLOSE MAIN2`

Then proceed to Main3.

Do not return to:
- `Current/PWA/New-main` as a development source.
- `Current/PWA/main/*` as a development source.

## REQUIRED QUESTIONS
### هل تحقق الهدف الأصلي: استكمال ملفات النظام الأم وظيفيًا بالكامل؟
لا. لا توجد أدلة تسمح بالإعلان عن اكتمال النظام الأم بالكامل في هذا checkpoint.

### هل مازالت هناك أي تبويب أو وظيفة ناقصة أو هيكلية فقط أو `(قيد التطوير)`؟
نعم. Main2 لديه MAIN2-D1 قبل Owner merge، كما أن parser/browser/assembly وfunctional closure للـ11 fragments لم تثبت بالكامل، وMain11 لديه `(قيد التطوير)` مثبت تاريخيًا في الوثيقة الحالية.

### متى يكتمل؟
لا يوجد تاريخ يمكن إثباته دون تخمين. الإغلاق مشروط بإكمال owner surgeries، إغلاق Executor contract وSearch contract، إكمال كل capabilities end-to-end، parser/browser PASS، Assembly صحيح من `Current/PWA/main2`, ثم Production E2E verification.

## GOVERNANCE RULE
لا قيمة لأي نسبة أو تقرير قبل مطابقة Production الحالية في نفس لحظة التقرير. لا تعديل يبنى على الظن أو التخمين. وجود واجهة أو Commit أو Staging PASS لا يساوي Functional Production Closure.
