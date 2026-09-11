# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-11 — MASTER CTO EXECUTION OS / MAIN1 R2

### GOVERNING TARGET — NON-NEGOTIABLE
الهدف هو استكمال المشروع وظيفيًا وتشغيليًا وفق Gold/Diamond، وليس مجرد إكمال UI. الدراسة تسبق التعديل. لا يُعامل التقرير أو الذاكرة كمصدر للحالة الحالية. كل Closure Unit يجب أن تمر من الواقع الحالي إلى الإثبات ثم الإصلاح ثم الاختبار ثم Production Verification ثم التوثيق.

الحلقة الحاكمة:

RECOVER → REFRESH → RECONSTRUCT → VERIFY → INVESTIGATE → IDENTIFY → REPAIR → COMPLETE → INTEGRATE → TEST → DEPLOY → VERIFY PRODUCTION → REPAIR DATA → DOCUMENT → UPDATE CURRENT_STATE → UPDATE EXECUTION LOG → UPDATE CLOSURE MATRIX → DEFINE NEXT EXACT CHECKPOINT → CONTINUE.

### SOURCE-OF-TRUTH GOVERNANCE
- Current verified Production/Runtime reality outranks historical reports.
- Production Database is execution truth; Git is reproducible canonical source, not a substitute for Production.
- Historical reports are forensic evidence only.
- Unknown must create evidence work, not guessing.
- One Closure Unit at a time.
- Parent editable source = `Current/PWA/main2/main1.md ... main11.md` and remains owner-merge domain.
- `Original/PWA/main/*` = immutable historical reference.
- `Current/PWA/New-main` = generated assembly target only.
- Main1 owns the shell/control plane; view implementation remains cross-file in the other Main fragments.
- Physical Stock contract = `post_stock_movement -> stock_branches + inventory_log`.
- `reserve_stock` / `release_stock_reservation` = reservation engine only.
- Current governing execution OS = `doc/Draft/Reprots/MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`.

## CURRENT GIT TRUTH — FRESH R2
- Main1 current SHA: `eda2319c13084e351a21061b74cebc235478a6e5`.
- Main1 original SHA: `14b12a471c20ad23a2c18f456dbc4d59783a0d1f`.
- Active Main1 owner changeset: `doc/Draft/Reprots/OWNER_CHANGESETS_20260911_MAIN1_R2.md`.
- Active Main1 execution log: `doc/Draft/Reprots/CTO_EXECUTION_LOG_20260911_MAIN1_R2.md`.
- R2 owner changeset creation commit: `47dfb50f996190afc562047221f5ef40c03edb78`.
- R2 execution log creation commit: `e48e20721e9957f9a28b510babc467bc06720709`.
- Earlier R1 Main1 documents remain historical/stale and must not be blindly reapplied.

## FRESH PRODUCTION SNAPSHOT — 2026-09-11 R2
Verified directly at UTC `2026-09-11 06:36:41.858495`:
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

Additional verified Production facts:
- `workflow_rules` contains 3 active rules.
- `workflow_log` contains 0 rows.
- `items.item_code` has a UNIQUE constraint in the current schema.
- `users.auth_id` has a UNIQUE constraint.
- `audit_log` currently has no company_id column.

## MASTER READING GATE
The complete MASTER CTO Governance document was read in consecutive chunks from start through its explicit END marker.
MASTER SHA: `b03feec14a417ca9032d714774f2687b4542a373`.

## MAIN1 READING GATE
Current Main1 was read in chunked ranges through EOF, with reads beyond the terminal boundary returning empty content.
Current Main1 SHA: `eda2319c13084e351a21061b74cebc235478a6e5`.

Main1 role proven:
- HTML shell / login / main shell.
- Supabase client bootstrap.
- `RW_STATE` canonical frontend state.
- Generic table pagination.
- Audit submission/UI.
- Permission evaluation.
- Workflow bootstrap.
- Notification bootstrap/UI.
- Authentication bootstrap.
- Base data bootstrap.
- Navigation tree and routing handoff.

Main1 intentionally does not define `RW_Views`; this remains a cross-file responsibility and should not be duplicated into Main1.

## HISTORICAL RECORD RECONCILIATION
The previous Main1 state package and R1 owner changeset were discovered to be stale because they referenced Main1 SHA `4d1b...`, old EOF information, and Finance/CRM/HR defects that are already corrected in the current Main1 source.

Therefore:
- R1 is preserved as historical evidence.
- R2 is the active source of owner surgery.
- No R1 surgery should be re-applied to the current file.

## VERIFIED CURRENT — ALREADY CORRECT
The following are present in the current Main1 and require no duplicate surgery:

### Finance authorization
Seven Finance actions already contain:
`perm: ['finance', 'finance_manager']`
for treasury, accounts, journal, receipts, payments, transfers, reports.
`settlement` remains separate and has no Finance permission.

### HR capability
Main1 already contains:
`{ view: 'hr', icon: 'fa-id-card', label: 'الموارد البشرية', perm: 'hr' }`

### CRM capability
Main1 already contains:
`{ view: 'crm', icon: 'fa-handshake', label: 'إدارة علاقات العملاء (CRM)', perm: 'customers' }`

### Array-aware permission evaluator
`isAllowed(item)` already supports `perm` arrays with OR semantics, single string permission, and view fallback.

### Owner semantics
`RW_Permissions_check` preserves the historical Owner + wildcard semantics and is not changed.

## PROVEN MAIN1-E — AUDIT TABLE STORED-XSS
Exact element:
`function RW_Audit_renderTable(data) {`

Defect:
DB-controlled audit fields are concatenated into HTML and passed to `safeHTML()` / `innerHTML`.

Required repair:
DOM construction + `textContent` for all dynamic data.

Full replacement is in:
`doc/Draft/Reprots/OWNER_CHANGESETS_20260911_MAIN1_R2.md`

Status:
`ROOT CAUSE PROVEN / SURGERY READY / OWNER MERGE PENDING`

## PROVEN MAIN1-F — AUDIT DETAILS STORED-XSS
Exact element:
`function RW_Audit_showDetails(logId) {`

Defect:
Audit metadata and JSON output are concatenated into HTML passed to SweetAlert.

Required repair:
DOM construction + `textContent`; old/new JSON rendered in `<pre>` as literal text.

Status:
`ROOT CAUSE PROVEN / SURGERY READY / OWNER MERGE PENDING`

## PROVEN MAIN1-G — NOTIFICATION STORED-XSS
Exact element:
`function showPanel() {` inside `RW_Notification`.

Defect:
Database-controlled notification title/body are inserted directly into SweetAlert HTML.

Required repair:
DOM construction + `textContent`, preserving click and mark-read behavior.

Status:
`ROOT CAUSE PROVEN / SURGERY READY / OWNER MERGE PENDING`

## PROVEN MAIN1-WF — WORKFLOW FALSE SUCCESS
Exact element:
`function evaluate(tableName, event, recordId, recordData) {`
inside `RW_Workflow`.

Defect proven:
- Actions are represented with `pending` states.
- No Action is executed.
- Overall `workflow_log.status` is written as `success`.
- Persistence errors are swallowed.

Current Production workflow contract proven to exist:
1. `UpdateStockAndJournalOnPOReceive` -> `update_inventory`, `create_journal_entry`.
2. `CreateJournalOnOrderDeliver` -> `create_journal_entry`.
3. `CreateStockVoucherOnOrderConfirm` -> `create_stock_voucher`.

`workflow_log` is currently empty, so no historic false-success rows require data repair.

### Required next evidence
Before replacing `evaluate()` the actual Executor/Dispatcher contract must be proven from current Main2–Main11 + Production RPC/Edge:
- executor location;
- payload/parameter contract;
- authorization/tenant rules;
- transaction boundary;
- retry/idempotency;
- failure contract;
- downstream responsibilities.

No replacement was invented because doing so would violate the no-guessing rule.

Status:
`ROOT CAUSE PROVEN / EXECUTOR DISCOVERY OPEN / NOT A BLOCKER`

## DATA REPAIR STATUS
No Main1-related business data was mutated during R2 forensic review.

Reason:
No safe data correction was proven. Current workflow_log is empty; current Production base counts are stable; no destructive cleanup is justified from appearance alone.

## OWNER CHANGESET
Active file:
`doc/Draft/Reprots/OWNER_CHANGESETS_20260911_MAIN1_R2.md`

The owner source itself remains untouched.

## CURRENT MAIN1 CLOSURE
- Master governance reading: `CLOSED`
- Current Main1 full reading: `CLOSED`
- Fresh Production synchronization gate: `CLOSED FOR THIS CYCLE`
- Historical reconciliation against stale R1: `CLOSED`
- Finance/CRM/HR stale findings: `SUPERSEDED / ALREADY PRESENT IN CURRENT SOURCE`
- Audit table: `OPEN — SURGERY READY`
- Audit details: `OPEN — SURGERY READY`
- Notifications: `OPEN — SURGERY READY`
- Workflow: `OPEN — EXECUTOR CONTRACT DISCOVERY`
- Main1 forensic review: `CLOSED AS FORENSIC REVIEW ONLY`
- Main1 functional closure: `OPEN`
- Global Gold/Diamond: `OPEN`

## FINAL SELF-AUDIT
### What was proven
- Master was fully read to EOF.
- Current Main1 was read to EOF.
- Fresh Production was queried immediately before final judgment.
- Previous state records were shown to be stale relative to current Main1 SHA and EOF boundary.
- Finance/CRM/HR fixes already exist in the current Main1 source.
- Audit table/details and Notification panel contain unsafe HTML sinks.
- Workflow evaluator is a false-success stub.
- No workflow history exists to repair.

### What was not proven
- Actual Workflow Executor/Dispatcher contract.
- Main2–Main11 functional completeness.
- Final New-main assembly.
- Browser/PWA end-to-end runtime.
- Main1 post-merge production smoke verification.

### What was not changed
- `Current/PWA/main2/main1.md` — owner merge domain.
- `Original/PWA/main/main1.md` — immutable.
- No Main1 Production business data was modified.

## NEXT EXACT RESUMPTION POINT
Closure Unit: `MAIN1-WF`

Exact source function:
`Current/PWA/main2/main1.md :: function evaluate(tableName, event, recordId, recordData) {`

Exact evidence search terms:
`update_inventory`
`create_journal_entry`
`create_stock_voucher`

Then close owner surgical repairs E/F/G and perform full Main1 re-read + runtime verification before assigning `MAIN1 = FULLY CLOSED`.

## STATUS
`MAIN1 FORENSIC REVIEW = CLOSED`
`MAIN1 FUNCTIONAL = OPEN`
`GLOBAL GOLD/DIAMOND = OPEN`
