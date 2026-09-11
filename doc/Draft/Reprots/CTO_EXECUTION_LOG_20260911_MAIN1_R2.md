# RAWAEA ERP — CTO EXECUTION LOG
## MAIN1 FORENSIC RE-CHECK — R2 — 2026-09-11

## 1. GOVERNANCE
- Governing document: `doc/Draft/Reprots/MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`.
- Governing SHA: `b03feec14a417ca9032d714774f2687b4542a373`.
- MASTER was read consecutively from start through the explicit END marker.
- No report was treated as current truth.
- `Original/PWA/main/main1.md` remains immutable historical reference.
- `Current/PWA/main2/main1.md` remains owner-editable source; no direct owner-source mutation was performed in this cycle.

## 2. FRESH PRODUCTION REALITY
Direct Production re-query at UTC `2026-09-11 06:36:41.858495` returned:
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

This supersedes the stale/contradictory values previously recorded in the older Main1 state package.

## 3. CURRENT MAIN1 SOURCE REALITY
- Path: `Current/PWA/main2/main1.md`
- Current SHA: `eda2319c13084e351a21061b74cebc235478a6e5`
- EOF verified by reads through the 1049 boundary and an empty read beyond it.
- Main1 is the Shell/Control Plane: DOM shell, Supabase client, canonical RW_STATE, auth bootstrap, permissions helper, workflow bootstrap, notification bootstrap/UI, audit UI, data bootstrap, navigation.
- View implementation remains a cross-file responsibility; Main1 does not duplicate `RW_Views`.

## 4. HISTORICAL/STALE RECORDS IDENTIFIED
The older documents below were based on a previous Main1 SHA and therefore cannot be used as current instructions without reconciliation:
- `doc/Draft/Reprots/OWNER_CHANGESETS_20260911_MAIN1.md`
- `doc/Draft/Reprots/CTO_EXECUTION_LOG_20260911_MAIN1.md`
- `CURRENT_STATE.md` Main1 checkpoint fields

The old R1 records described Finance/CRM/HR defects that are already corrected in the current Main1 source. They are preserved as historical evidence and must not be blindly re-applied.

## 5. VERIFIED CURRENT SOURCE — ALREADY CORRECT
The following are already present in the current Main1 and require no repeated surgery:
- Finance submenu action entries use `perm: ['finance','finance_manager']`.
- Settlement is not incorrectly assigned Finance permission.
- HR menu uses `perm: 'hr'`.
- CRM menu uses `perm: 'customers'`.
- `isAllowed(item)` supports permission arrays with OR semantics.
- `RW_Permissions_check` preserves Owner + wildcard semantics.

## 6. PROVEN MAIN1-E — AUDIT TABLE UNSAFE HTML SINK
Current `RW_Audit_renderTable(data)` concatenates DB-controlled audit fields into an HTML string and sends it through `innerHTML` via `safeHTML`.

Root cause:
- user_email, action, table_name, record_id and generated date text are inserted into HTML markup without contextual escaping.

Repair prepared:
- DOM construction + `textContent` for all DB-controlled values.
- Detail button remains event-driven and preserves behavior.

Exact full replacement is stored in:
`doc/Draft/Reprots/OWNER_CHANGESETS_20260911_MAIN1_R2.md`

Status:
`ROOT CAUSE PROVEN`
`SURGERY READY`
`OWNER MERGE PENDING`

## 7. PROVEN MAIN1-F — AUDIT DETAILS UNSAFE HTML SINK
Current `RW_Audit_showDetails(logId)` places JSON.stringify output and audit fields inside a SweetAlert HTML string.

Root cause:
- attacker-controlled or malformed audit data can become HTML at the sink.

Repair prepared:
- DOM construction with `textContent` for all dynamic values.
- old_data/new_data are rendered into `<pre>` as literal text.

Exact full replacement is stored in:
`doc/Draft/Reprots/OWNER_CHANGESETS_20260911_MAIN1_R2.md`

Status:
`ROOT CAUSE PROVEN`
`SURGERY READY`
`OWNER MERGE PENDING`

## 8. PROVEN MAIN1-G — NOTIFICATION UNSAFE HTML SINK
Current `RW_Notification.showPanel()` inserts notification title/body into a SweetAlert HTML string.

Root cause:
- notification content is database-controlled but is not safely rendered as text.

Repair prepared:
- DOM construction + `textContent` for title/body/reference values.
- click behavior retained with addEventListener.

Exact full replacement is stored in:
`doc/Draft/Reprots/OWNER_CHANGESETS_20260911_MAIN1_R2.md`

Status:
`ROOT CAUSE PROVEN`
`SURGERY READY`
`OWNER MERGE PENDING`

## 9. PROVEN MAIN1-WF — WORKFLOW FALSE SUCCESS
Current `RW_Workflow.evaluate(tableName, event, recordId, recordData)`:
- selects active rules;
- builds action records with status `pending`;
- writes workflow_log with overall status `success`;
- executes no action;
- swallows persistence errors.

Production contract discovered directly:
- active rule `UpdateStockAndJournalOnPOReceive`: `update_inventory`, `create_journal_entry`.
- active rule `CreateJournalOnOrderDeliver`: `create_journal_entry`.
- active rule `CreateStockVoucherOnOrderConfirm`: `create_stock_voucher`.
- `workflow_log` currently contains zero rows.

Root cause:
`evaluate()` is a false-success stub, not an executor.

Critical governance decision:
A replacement implementation is NOT invented yet because the actual executor/parameter/authorization/transaction contract for those action types has not been proven from current Main2–Main11 and Production executors.

This is not a blocker. It is an active evidence task.

Next exact evidence task:
- Search Current Main2–Main11 for exact action types:
  `update_inventory`, `create_journal_entry`, `create_stock_voucher`.
- Search Production RPCs and Edge Functions for their real executors/dispatchers.
- Prove parameter contract, transaction boundary, auth/tenant scope, retry/idempotency, failure behavior.
- Then perform a surgical full-function replacement of `evaluate()`.

Status:
`ROOT CAUSE PROVEN`
`EXECUTOR CONTRACT OPEN`
`NO SAFE CODE INVENTION`
`ACTIVE INVESTIGATION`

## 10. PRODUCTION DATA REPAIR
No Main1 data mutation was performed in this R2 forensic cycle.

Reason:
- no current Main1 data corruption was proven that could safely be repaired without affecting business records;
- workflow_log is empty;
- Production counts were refreshed directly before judgment.

## 11. CURRENT CLOSURE STATUS
- MASTER CTO reading: `FULLY CLOSED`
- Current Main1 reading: `FULLY CLOSED`
- Fresh Production synchronization: `CLOSED FOR THIS CYCLE`
- Historical cross-check: `DONE AT STRUCTURAL BOUNDARIES; ORIGINAL LEFT IMMUTABLE`
- Finance/CRM/HR old R1 findings: `STALE / ALREADY REFLECTED IN CURRENT SOURCE`
- Audit table XSS: `PROVEN / OWNER SURGERY READY`
- Audit details XSS: `PROVEN / OWNER SURGERY READY`
- Notification XSS: `PROVEN / OWNER SURGERY READY`
- Workflow false-success: `PROVEN / EXECUTOR DISCOVERY OPEN`
- Main1 owner-source functional closure: `OPEN`
- Main1 Gold/Diamond closure: `OPEN`
- Global Gold/Diamond: `OPEN`

## 12. OWNER CHANGESET
Active owner instructions:
`doc/Draft/Reprots/OWNER_CHANGESETS_20260911_MAIN1_R2.md`

Creation commit:
`47dfb50f996190afc562047221f5ef40c03edb78`

## 13. FALSE-CLOSURE GUARD
No claim is made that Main1 is Fully Closed.
The current source has not been modified by the assistant because owner-source delivery is explicitly assigned to the owner.
Production was not changed in this Main1 R2 cycle because no proven Main1 Production mutation was required.

## 14. NEXT EXACT RESUMPTION POINT
`MAIN1-WF`

Exact source element:
`RW_Workflow.evaluate(tableName, event, recordId, recordData)`

Exact evidence search:
`update_inventory`
`create_journal_entry`
`create_stock_voucher`

Required result:
prove the real action executor contract from Current/PWA/main2–main11 + Production RPC/Edge before writing the replacement.
