# CURRENT AUTHORITATIVE CHECKPOINT — 2026-09-24 — Report335 FINAL
## Mother Fleet Vehicle Operation Link — Current Source + Production E2E Reconciliation

> This checkpoint supersedes older Fleet/Mother checkpoints below. Older entries remain historical evidence.

## Current System Truth
- System repository: `papamohammed77-glitch/rawaie-erp-New`
- System HEAD: `443627198998b2dbf15eb9e5e57cb113fd83cbf3`
- System parent: `2b9cee366fb7e6574a853956a74d1e9a9d05321a`

## Current Mother Truth
- Mother repository: `papamohammed77-glitch/erp-frontend`
- Mother HEAD: `111a6876ddf38394989896f64767170b77c3231e`
- Mother parent: `26d4d4d347be477b69482e75627154aa6565d5ac`
- Current `companies/company-1/main.html` blob: `3d1ac970c0e81d0a581045ce79b140708ccfa3af`
- `26d4...` is the last commit that actually modified Mother `main.html`.
- `111a...` is forensic-extract only.
- Assistant direct write to Mother `main.html`: **NO**.

## Report334 Reconciliation
Report334 PATCH-334-01 and PATCH-334-02 are already applied in current Mother source by Owner commit `26d4...`.
Do not reapply either patch.
Do not reopen Report334 without contradictory primary evidence.

## Production Truth
- Supabase project: `fiilmooggumokxanwiyx`
- Fleet command: `fleet_command_atomic`
- Fleet query: `fleet_query`
- Canonical command: `VEHICLE_OPERATION_BIND`
- Candidate view: `vehicle_operation_candidates`
- Latest relevant migration: `20260924145700_extend_fleet_vehicle_operation_candidates_document_branch_context`
- No new Edge Function created.

## Current Production E2E
Inside isolated transaction then rollback:
- RUNSHEET bind: PASS.
- RUNSHEET replay with same operation_id: duplicate=true PASS.
- BRANCH_TRANSFER bind: PASS.
- BRANCH_TRANSFER replay: duplicate=true PASS.
- DIRECT_SALE bind: PASS.
- DIRECT_SALE replay: duplicate=true PASS.
- vehicle_detail saw all three linked operation types: PASS.
- branch/document/reference candidate context: PASS.
- binding stock delta: 0.
- allocated_qty delta: 0.
- inventory_log delta: 0.
- journal entry delta: 0.
- journal line delta: 0.
- QA business residue after rollback: 0.
- QA fleet registry after rollback: 0.

## Current Production Snapshot
- companies: 1
- branches: 4
- vehicles: 2
- fleet_drivers: 0
- runsheets: 0
- stock_vouchers: 2
- inventory_log: 25
- journal_entries: 10
- journal_lines: 16
- audit_log: 2180
- QA fleet registry: 0
- QA vouchers: 0
- QA runsheets: 0

## Closure
- Production Fleet control plane: CLOSED / VERIFIED.
- Candidate read model: CLOSED / VERIFIED.
- Branch filtering: CLOSED / VERIFIED.
- Document/reference context: CLOSED / VERIFIED.
- RUNSHEET binding: CLOSED / E2E.
- BRANCH_TRANSFER binding: CLOSED / E2E.
- DIRECT_SALE binding: CLOSED / E2E.
- Idempotency/replay: CLOSED / E2E.
- Vehicle detail reporting: CLOSED / E2E.
- Physical Stock isolation: CLOSED.
- Accounting isolation: CLOSED.
- QA cleanup: CLOSED.
- Mother Report334 source implementation: CLOSED / OWNER-APPLIED.
- Public served artifact identity: OPEN / UNVERIFIED.
- Authenticated Browser Console/Network E2E: OPEN / UNVERIFIED.

## Hard Rule
Do not call Source PASS or DB PASS a Browser PASS.
The next CTO must start from CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.

## Exact Next Resumption
1. Verify System HEAD and Mother HEAD again.
2. Do not reapply Report334 patches.
3. Do not create a new Edge Function for this capability.
4. If Browser access becomes available, verify the served Mother artifact and authenticated Browser E2E for RUNSHEET / BRANCH_TRANSFER / DIRECT_SALE.
5. Capture Console + Network.
6. Re-snapshot Production at the same reporting moment.
7. Only reopen a closed Fleet boundary when contradictory primary evidence exists.

## Report335
`doc/Draft/Reprots/Report335_MOTHER_FLEET_VEHICLE_OPERATION_LINK_CURRENT_RECONCILIATION_E2E_20260924.md`

---

# CURRENT AUTHORITATIVE CHECKPOINT — 2026-09-24 — Report334 FINAL
## Mother Fleet Vehicle Operation Link — Branch + Document/Reference Context

> This checkpoint supersedes all older CURRENT_STATE sections below. Older sections remain historical evidence.

## Current Verified Git
### System
- HEAD: `3c2bf3f040c5861f24b0f299502f94515c06c52a`
- Parent: `2b9cee366fb7e6574a853956a74d1e9a9d05321a`
- Report334 final commit: `3c2bf3f040c5861f24b0f299502f94515c06c52a`

### Mother
- Repository: `papamohammed77-glitch/erp-frontend`
- HEAD: `b1820141d49dbe9b82e339cd7ccb05781f39d81a`
- Parent: `7915275b87c74f1b249a1da7b3732a16511aae38`
- Current main.html blob: `c521d84fd96143b435e432e135e2d8a967acf60e`
- Mother main.html was not modified by assistant.

## Current Production
- Migration: `20260924145700_extend_fleet_vehicle_operation_candidates_document_branch_context`
- `fleet_query.vehicle_operation_candidates` now supports optional company-scoped active branch filtering and returns branch/document/reference context.
- No new Edge Function was created.
- Existing Fleet command/query control plane unchanged except read-model extension.

## Current UI Defect / Surgical Resolution
The remaining Mother gap is exclusively Consumer UX:
- Branch Transfer needs branch selector + document/reference presentation.
- Direct Sale needs automatic document/reference presentation.
- Linked operation cards need reference visible.
- RUNSHEET remains unchanged.
- Identity separation remains unchanged.

Owner-only Mother patches:
- PATCH-334-01: replace only `function operationBlock(title, rows, type)`.
- PATCH-334-02: replace only `async function openVehicleOperationLinkForm()` up to `async function openVehicleEdit(id){`.
Exact replacements are stored in:
`doc/Draft/Reprots/Report334_MOTHER_FLEET_VEHICLE_OPERATION_LINK_BRANCH_DOCUMENT_FORENSIC_CLOSURE_20260924.md`

## E2E Verification
Production binding test ran inside a single transaction and was rolled back:
- candidate read model returned branch list, transfer documents and direct-sale document context.
- selected branch filter returned only matching transfer source/destination rows.
- invalid branch was rejected.
- Branch Transfer bind PASS; replay duplicate=true.
- Direct Sale bind PASS; replay duplicate=true.
- binding caused no persistent stock, allocated stock, journal, journal-line, or driver-ledger mutation.
- QA vouchers/registry/audit residue = 0 after rollback.

Production snapshot:
- active companies 1
- branches 4
- vehicles 2
- runsheets 0
- stock vouchers 2
- inventory log 25
- journal entries 10
- journal lines 16
- driver ledger 4
- QA fleet vouchers 0
- QA fleet registry 0

## Closure Status
- Production Fleet operation binding control plane: CLOSED.
- Branch/document candidate read model: CLOSED.
- Physical stock centralization: CLOSED.
- Mother surgical patches: READY FOR OWNER.
- Mother source/served browser closure: OPEN until owner applies and publishes the two patches.

## Mandatory Next Session
1. Verify System HEAD and Mother HEAD.
2. Do not reopen closed Production contracts unless contradictory primary evidence exists.
3. Apply only PATCH-334-01 and PATCH-334-02 to Mother main.html.
4. Parse the complete main.html.
5. Commit and publish Mother.
6. Verify served artifact identity.
7. Run authenticated browser E2E for RUNSHEET, BRANCH_TRANSFER, DIRECT_SALE.
8. Capture Console/Network.
9. Verify vehicle_detail, candidate read model, audit, stock and accounting.
10. Replay using the same Operation ID.
11. Snapshot Production at the same reporting moment.
12. Update CURRENT_STATE.
13. Do not create a new Edge Function for this capability.

## Report
`doc/Draft/Reprots/Report334_MOTHER_FLEET_VEHICLE_OPERATION_LINK_BRANCH_DOCUMENT_FORENSIC_CLOSURE_20260924.md`

## Continuity Rule
Start from:
CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.

Never infer current state from older reports alone.
Do not redo closed repairs.
Do not create a second Physical Stock engine.
Do not create a new Edge Function for this capability.

---

# CURRENT CHECKPOINT — 2026-09-24 — Mother Fleet Vehicle Operation Binding

## Scope
Closure unit: Mother `main.html` → `RW_FleetManagement` → Vehicle Details → Vehicle Operation Binding.

## Primary Truth
- System repository: `papamohammed77-glitch/rawaie-erp-New`
- System documentation/migration HEAD immediately before this state update: `c4062382237438f82f443140a91e772598b0a080`
- Mother repository: `papamohammed77-glitch/erp-frontend`
- Mother HEAD: `53b254de274af504022d0acf13becc40378bd4aa`
- Mother parent: `80e42653a4a83874ab739b8a87e7ddc4f407e6e4`
- Mother `companies/company-1/main.html` blob: `274a884785ac1a38394a30735802dec5378fad0d`
- Mother `main.html` lines: 32,075
- Assistant direct write to Mother `main.html`: NO

## Historical reconciliation
- Fleet Vehicle Master/Edit was already closed in earlier checkpoints and was not reopened.
- Runsheet vehicle/driver/delivery-rep identity already existed.
- Direct Sale vehicle identity already existed as `stock_vouchers.to_type='Vehicle'` + `to_id`; Direct Sale was NOT given a duplicate `vehicle_id`.
- Branch Transfer lacked persistent vehicle/driver identity and was the actual schema gap.

## Production implementation
No new Edge Function was created.

Existing `fleet_command_atomic` was extended with:
`VEHICLE_OPERATION_BIND`

Operations:
- RUNSHEET → `runsheets.vehicle_id`, `runsheets.driver_id`, `runsheets.deliverer_id`
- BRANCH_TRANSFER → `stock_vouchers.vehicle_id`, `stock_vouchers.driver_id`
- DIRECT_SALE → existing `stock_vouchers.to_type/to_id/custodian_user_id`

Existing `fleet_query` was extended with:
- vehicle_detail.runsheets enrichment
- vehicle_detail.transfer_operations
- vehicle_detail.direct_sales
- `vehicle_operation_candidates`

Production migrations:
- `20260924121815_add_vehicle_operation_binding_control_plane`
- `20260924123114_harden_vehicle_operation_driver_identity_20260924`
- `20260924123200_harden_vehicle_operation_driver_identity_20260924_v2`

Additional guards:
- Transfer vehicle/driver must be same-company.
- Transfer vehicle/driver must be supplied together.
- Executed Transfer vehicle/driver identity is immutable.
- Runsheet/Transfer driver must be an active driver/delivery identity.
- Non-Transfer vouchers cannot carry the new Transfer-specific vehicle/driver fields.

## Inventory / Accounting Contract
Physical Stock remains:
`post_stock_movement` → `stock_branches` + `inventory_log`

Binding itself does not move stock.

E2E Transfer:
- Bind: stock delta 0
- Send: source -1
- Receive: target +1
- GL journal delta 0
- replay with same operation_id: duplicate=true
- rollback clean

E2E Direct Sale:
- Bind: PASS
- replay: duplicate=true
- Send: source -1, vehicle mobile branch +1
- existing direct-sales custody ledger: +10 test value
- GL delta from binding/send test: 0
- vehicle_detail.direct_sales: 1
- rollback clean

E2E Runsheet:
- Bind: PASS
- vehicle/driver/delivery-rep persisted
- replay: duplicate=true
- vehicle_detail.runsheets: 1
- rollback clean

Negative E2E:
- invalid direct-sales user as Runsheet driver: rejected
- executed Transfer rebind to another vehicle: rejected

## Production cleanup
Fresh QA residue:
- QA vehicles = 0
- QA vouchers = 0
- QA runsheets = 0
- QA inventory logs = 0
- QA operation registry = 0
- QA binding audit residue = 0

Current Production snapshot:
- companies = 1
- branches = 4
- items = 16
- stock_rows = 53
- stock_vouchers = 2
- inventory_log_rows = 25
- journal_entries = 10
- journal_lines = 16
- driver_ledger_rows = 4

## Mother main.html surgical patch — OWNER ACTION
Do NOT replace the whole file or whole function.

### PATCH-332-01
In `RW_FleetManagement.command`:
Find exactly:
```js
async function command(commandName, payload) {
```
Replace only with:
```js
async function command(commandName, payload, operationId) {
```

Find exactly:
```js
      p_operation_id: op(commandName),
```
Replace only with:
```js
      p_operation_id: operationId || op(commandName),
```

### PATCH-332-02
In `RW_FleetManagement.openVehicleDetail(id)`, append this button to the existing management button chain:
```html
<button onclick="RW_FleetManagement.openVehicleOperationLinkForm()" class="px-3 py-2 rounded-xl bg-indigo-600 text-white font-bold">ربط المركبة بالعملية</button>
```

### PATCH-332-03
Find exactly:
```js
       listBlock('الرحلات',d.runsheets,'runsheet_code','run_date')+
```
Replace only with:
```js
       operationBlock('الرحلات',d.runsheets,'RUNSHEET')+operationBlock('تحويلات الفروع',d.transfer_operations,'BRANCH_TRANSFER')+operationBlock('البيع المباشر',d.direct_sales,'DIRECT_SALE')+
```

### PATCH-332-04
Immediately before:
```js
function listBlock(title, rows, key, subkey) {
```
insert the complete `operationBlock` function from Report332.

### PATCH-332-05
Immediately before:
```js
async function openVehicleEdit(id){
```
insert the complete `toggleVehicleOperationLinkPanels` and `openVehicleOperationLinkForm` functions from Report332.

The modal uses existing `fleet_query('vehicle_operation_candidates')` and existing authenticated `fleet_command_atomic`.

### PATCH-332-06
In the `RW_FleetManagement` API object immediately after:
```js
openVehicleEdit: openVehicleEdit,
```
insert:
```js
    openVehicleOperationLinkForm: openVehicleOperationLinkForm,
    toggleVehicleOperationLinkPanels: toggleVehicleOperationLinkPanels,
```

## Static verification
- Current target anchors are unique:
  - command function = 1
  - openVehicleDetail = 1
  - openVehicleEdit = 1
  - API openVehicleEdit = 1
- Current UI binding strings = 0 before owner patch.
- Full surgical JavaScript patch parse = PASS.
- Mother source unchanged by assistant.

## Closure Status
- Production binding control plane: CLOSED / VERIFIED
- Runsheet binding: CLOSED / VERIFIED
- Transfer binding: CLOSED / VERIFIED
- Direct Sale binding: CLOSED / VERIFIED
- Driver identity guard: CLOSED / VERIFIED
- Transfer immutability: CLOSED / VERIFIED
- Read model: CLOSED / VERIFIED
- Inventory integrity: CLOSED / VERIFIED
- Accounting side-effect integrity: CLOSED / VERIFIED
- Mother source patch: READY / OWNER ACTION
- Served Mother artifact: OPEN / UNVERIFIED
- Authenticated Browser E2E after owner patch: OPEN / UNVERIFIED

## Required next session sequence
1. Re-verify current Mother HEAD/blob; reports are historical, not current truth.
2. Apply only PATCH-332-01 through PATCH-332-06.
3. Parse the complete `main.html`.
4. Commit and publish Mother.
5. Verify served artifact identity.
6. Run authenticated Browser E2E:
   - Vehicle Details → Runsheet bind
   - Vehicle Details → Branch Transfer bind
   - Vehicle Details → Direct Sale bind
7. Verify Network / Console / DB.
8. Replay each operation with the same operation_id.
9. Snapshot Production at the same moment as the final report.
10. Update this state again.
11. Do not reopen any closed component without contradictory primary evidence.

## Reference report
`doc/Draft/Reprots/Report332_MOTHER_FLEET_VEHICLE_OPERATION_BINDING_FORENSIC_SURGICAL_CLOSURE_20260924.md`

# CURRENT AUTHORITATIVE CHECKPOINT — 2026-09-24 — Report331 Voucher Draft Update Closure

## CURRENT TRUTH
This checkpoint is based on direct verification of CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE. Historical reports are context only.

### System repository
- Current verified write sequence before this state update:
  - 1674614e50e4790ffb6d06bed4e2b09394a1d972 — fix canonical UPDATE duplicate guard.
  - 86e87aeb8cc4d5fcab3b3b19b238c47f441fbbe1 — add DB uniqueness invariant.
  - bf43432089ba2b512c237e22550a6fa31b3fd5a6 — Report331.
  - f03da20bf133f51872517f6d8416f689633bf9b6 — execution log.
- Verify CURRENT HEAD again in the next session; do not rely on these hashes alone.

### Mother frontend
- Current HEAD verified: 53b254de274af504022d0acf13becc40378bd4aa
- Parent: 80e42653a4a83874ab739b8a87e7ddc4f407e6e4
- vouchers.html current SHA: 287f9900efdf1ee595f6537e9d230ef06e347c06
- vouchers.html = 4395 lines
- full inline JavaScript parse = PASS
- vouchers.html was NOT modified in Report331.
- main.html was NOT modified.

### Incident closed
The reported 400 error during Draft Transfer Edit:
POST /functions/v1/create-stock-voucher
→ action=update
→ update_manual_stock_voucher_atomic
→ "لا يجوز تكرار الصنف داخل نفس الإذن"

Root cause was proven in the Production RPC:
jsonb_to_recordset(p_items) AS x(itemCode text)
PostgreSQL normalizes the unquoted identifier to itemcode while the payload uses camelCase itemCode, causing the duplicate guard to group multiple rows as NULL and reject valid multi-item edits.

### Production fix
Migration 20260924113537:
fix_manual_voucher_update_itemcode_duplicate_guard

The duplicate guard now reads:
jsonb_array_elements(p_items) AS z(value)
GROUP BY btrim(z.value->>'itemCode')

### Database invariant
Migration 20260924113616:
add_stock_voucher_detail_unique_item_guard

Constraint:
stock_voucher_details_voucher_item_key
UNIQUE (voucher_id,item_id)

Duplicate detail keys verified after change = 0.

### Positive / negative verification
Positive UPDATE:
- real Production user vouchers@rawaea.com
- items 1001,1003,1004,1005,1006
- result = success
- detail rows = 5
- distinct items = 5
- transaction rolled back.

Negative UPDATE:
- temporary voucher inside transaction
- duplicate item 1001 + 1001
- result = rejected with "لا يجوز تكرار الصنف داخل نفس الإذن"
- transaction rolled back.

### Production QA cleanup
QA vouchers IN-1 and IN-2 were proven to be recent test vouchers with no Order/Runsheet references.
IN-1 had five TransferOut movements.
Those movements were reversed through post_stock_movement / InventoryIncrease.
The test vouchers and related logs were removed using the official voucher lifecycle/delete path.
A permitted audit_log delete record documents the repair.

Final cleanup:
- voucher residue for IN-1/IN-2 = 0
- QA inventory_log residue = 0
- linked operation residue = 0

### Final Production snapshot
- companies = 1
- branches = 4
- items = 16
- stock_vouchers = 0
- stock_voucher_details = 0
- stock_voucher_operations = 13
- inventory_log = 11
- stock_branches = 48
- audit_log = 2171
- duplicate voucher/item keys = 0

BR-01 repaired stock:
- 1001 = 12
- 1003 = 11
- 1004 = 12
- 1005 = 11
- 1006 = 13

### Edge / architecture
- create-stock-voucher Version 12 ACTIVE.
- No new Edge Function created.
- UPDATE continues through the existing capability wrapper and canonical UPDATE RPC.
- Physical Stock remains centralized through post_stock_movement.
- No change to orders, runsheets, picking, loading, unloading, delivery, returns, purchase, or reservation engines.

### Frontend surgical decision
For this incident:
NO CHANGE is required in:
companies/company-1/warehouse/vouchers.html

Do not delete, replace, or add a frontend block for the duplicate error.
Do not modify main.html.

The existing frontend payload already sends itemCode correctly. The defect was server-side.

### Documentation
- Report331:
  doc/Draft/Reprots/Report331_WAREHOUSE_VOUCHERS_DRAFT_UPDATE_DUPLICATE_GUARD_FORENSIC_CLOSURE_20260924.md
  commit: bf43432089ba2b512c237e22550a6fa31b3fd5a6
- Execution log:
  doc/Draft/Reprots/EXECUTION_LOG_20260924_VOUCHERS_DRAFT_UPDATE_DUPLICATE_GUARD.md
  commit: f03da20bf133f51872517f6d8416f689633bf9b6

### Closure status
- Production duplicate guard = CLOSED / VERIFIED
- DB uniqueness invariant = CLOSED / VERIFIED
- QA data repair = CLOSED / VERIFIED
- Physical Stock centralization = CLOSED / VERIFIED
- Current voucher source syntax = CLOSED / VERIFIED
- Current Edge integration = CLOSED / VERIFIED
- Frontend surgical patch for this incident = NONE REQUIRED
- main.html = UNTOUCHED
- Authenticated Browser E2E = OPEN / UNVERIFIED
- Served artifact identity = OPEN / UNVERIFIED

### Exact next resumption
1. Verify CURRENT System HEAD and parent.
2. Verify CURRENT Mother HEAD and vouchers.html SHA.
3. Verify live create-stock-voucher Version 12 and UPDATE RPC.
4. Verify the fixed duplicate guard text in Production.
5. Verify stock_voucher_details_voucher_item_key.
6. Do not reopen Report331 fix without contradictory current evidence.
7. Do not modify vouchers.html or main.html for this incident.
8. When authenticated browser execution is available, run:
   login → Warehouse → Vouchers → Draft Transfer → Edit → Save unique 5 items → Console/Network → DB verification → same operation retry.
9. Capture fresh Production snapshot at the same reporting moment.
10. Only then close Browser/served-artifact surfaces.

### Governing rule
Never convert historical report statements, source static PASS, or RPC E2E PASS into Browser PASS. Re-prove CURRENT truth before every new closure.

---

# RAWAEA ERP — CURRENT AUTHORITATIVE CHECKPOINT
## 2026-09-24 — Report330 Warehouse Vouchers JavaScript Syntax Forensic Closure

> Truth hierarchy remains:
> CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.
> Historical reports are contextual only and must be re-verified.

### System Git at checkpoint creation
- Previous verified HEAD: `197d2ab643caf358f2c0f67ee1386ba3bbc803a0`
- Previous parent: `32269bde2966201f98834899199592caf0877dd6`
- Report330 commit: `626528c73591be8cd4e34a73b3c15fb68b32b255`

### Mother Frontend Current Truth
- Repository: `papamohammed77-glitch/erp-frontend`
- Current HEAD: `80e42653a4a83874ab739b8a87e7ddc4f407e6e4`
- Parent: `3978a108de384ee6f11efff952aea791b59bf09d`
- `companies/company-1/warehouse/vouchers.html` SHA: `95b342be269dbc9c6e49fb46230431838a352f86`
- Latest frontend commit changed only the HTML comment timestamp.
- No assistant write was made to `vouchers.html`.
- No assistant write was made to `main.html`.

### Current Voucher Source Defect
The Current voucher source contains four missing commas in the `App` object literal introduced by frontend commit `4ef6973f2289f76d89aa9d9d52628171326793d8`.

Exact defects:
1. `choose:function(t)` before `actionFor:function(v)` — approximately line 307.
2. `deleteVoucher:function(code)` before `prepare:function()` — approximately line 2265.
3. Main submit method before `openDrawer:function()` — approximately line 4201.
4. `back:function()` before `account:function()` — approximately line 4216.

Before correction:
- Full inline JavaScript parse = FAIL
- `SyntaxError: Unexpected identifier 'actionFor'`

In-memory correction of only these four delimiters:
- Full inline JavaScript parse = PASS
- inline scripts parsed = 1
- bad `split(/s+/)` = 0
- giant realtime branch filter = 0

### Exact Owner Patch
File:
`companies/company-1/warehouse/vouchers.html`

Apply ONLY the four delimiter edits documented completely in:
`doc/Draft/Reprots/Report330_WAREHOUSE_VOUCHERS_SYNTAX_FORENSIC_SURGICAL_CLOSURE_20260924.md`

Do not replace any complete function.
Do not reapply Report329.

### Production Status
No Production change was required for this incident.

Current Production voucher capabilities verified:
- `create_manual_stock_voucher_atomic`
- `update_manual_stock_voucher_atomic`
- `delete_manual_stock_voucher_atomic`
- `send_stock_voucher_atomic`
- `post_manual_stock_voucher_atomic`
- `complete_manual_stock_voucher_atomic`
- `post_stock_movement`

No new Edge Function was created.

Current `receive-stock-voucher`:
- Version 22
- ACTIVE
- verify_jwt = true

Current `create-stock-voucher`:
- Version 12
- ACTIVE
- verify_jwt = false because the function implements custom authentication with `supabase.auth.getUser`.

### Production E2E
Fresh transactional test against real `IN-2`:
- Draft → Send → Receive all five lines → Receive replay → Complete
- Complete guard correctly rejected an intentionally incomplete partial receive test.
- Full transfer flow executed successfully.
- Replay with same operation_id did not create duplicate physical movement.
- Full transaction rolled back.

After rollback:
- `IN-2` status = Draft
- `received_qty` = 0
- `inventory_log` rows for `IN-2` = 0
- source stock total = 54
- target stock total = 0
- no QA residue

### Integration
`main.html` was not modified and does not require modification for this defect.

The login-screen symptom was caused by the voucher script failing to parse before `App.init()` could execute.

The Tailwind CDN warning is non-blocking and was not the root cause.

### Closure Status
- Production Voucher Core = CLOSED / VERIFIED
- Physical Stock Centralization = CLOSED / VERIFIED
- Transfer E2E = PASS
- Receive Idempotency = PASS
- Current Source Root Cause = PROVEN
- Static Syntax Repair = PROVEN IN-MEMORY
- Owner Patch = READY
- main.html = UNTOUCHED
- Production Change = NOT REQUIRED
- Authenticated Browser E2E = OPEN
- Served Artifact Verification = OPEN
- Overall Voucher Frontend Closure = PENDING OWNER PATCH + PUBLISH + BROWSER E2E

### Exact Next Resumption Point
1. Re-verify System HEAD and Mother HEAD.
2. Re-read Report330 only for this closure.
3. Apply only VCH-SYNTAX-01 through VCH-SYNTAX-04.
4. Parse the complete `vouchers.html`.
5. Publish owner frontend.
6. Verify the served artifact identity.
7. Run authenticated browser E2E.
8. Capture Console + Network evidence.
9. Run a fresh Production snapshot immediately after browser E2E.
10. Do not reopen Report329 closed items or Production voucher core unless new contradictory current evidence appears.

---

# RAWAEA ERP — CURRENT STATE
## Latest Authoritative Forensic Checkpoint — 2026-09-24
## Active Closure Unit: Mother ERP → Suppliers → مسؤول المشتريات → Smart Search

> Current truth:
> CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.
> Historical reports remain contextual and must be re-verified.

### System Git
- Current HEAD: `85ad9d2b1a195e5b8845a6550beec5fd85fdfc41`
- Parent: `9f9b3fd27aa9d4a57cf3453aea7833ab42b9b900`
- Production migration file: `supabase/migrations/20260924_supplier_purchase_rep_search_hardening.sql`
- Migration commit: `85ad9d2b1a195e5b8845a6550beec5fd85fdfc41`

### Mother Frontend Current Truth
- Repository: `papamohammed77-glitch/erp-frontend`
- Current HEAD: `897d40c47b27544fb8a5515a7f7dcce528c4563e`
- Parent: `3520240a57f2124bbcf96c3007f67a9c36890fcb`
- Current `companies/company-1/main.html` blob: `f4e707060a3f0ff68b993bf57616e4e861ac54e6`
- Current `main.html` line count: 32068
- Assistant direct write to `main.html`: NO

### Previous Supplier UI Fix — Already Applied
- Owner commit: `3520240a57f2124bbcf96c3007f67a9c36890fcb`
- Scope: Supplier Code Preview only.
- Do not reopen or reapply.

### Current Supplier Purchase Representative Defect
Function:
`RW_Suppliers.openModal(code)`

Current exact defective element:
`<div class="flex flex-col"><label>مسؤول المشتريات</label><input id="supp-rep" value="${s?.purchase_rep||''}" class="p-2.5 bg-gray-50 border rounded-lg"></div>`

Current source position:
- line 6935

The field is a plain text input with no smart search.

### Production Contract
- Existing field: `suppliers.purchase_rep varchar`
- No `purchase_rep_id`
- No new column/table created.
- Current Role Master spelling is exactly: `مسئول مشتريات`
- Current active purchaser count in company = 1.
- Current purchaser:
  - name = `مندوب مشتريات 1`
  - email = `buyer1@rawaea.com`
  - status = Active
  - permissions = [`purchases`, `suppliers`]

### Production Smart Search RPC
`public.get_supplier_purchase_reps(text)`

Security:
- SECURITY DEFINER
- auth.uid required
- suppliers permission required
- company derived from authenticated user
- Active users only
- Role Master = `مسئول مشتريات`
- anonymous EXECUTE revoked
- authenticated EXECUTE granted
- search supports multiple words across name/email/phone/employee_id
- max 25 results

Previous RPC:
`public.supplier_purchase_rep_search(text)`
was retired by migration:
`20260924083623_remove_duplicate_supplier_rep_search_rpc`

Current Production function inventory contains only the new `get_supplier_purchase_reps(text)` search RPC.

### Production Supplier Save Hardening
Existing:
`public.save_supplier_atomic(...)`

Current behavior:
- authenticated/company/permission validation preserved
- purchase_rep on CREATE/UPDATE must resolve to an Active purchaser in the same company
- matching by canonical purchaser name or email
- stored purchase_rep is canonical `users.name`
- invalid purchaser rejected
- accounts_payable remains financial-source-of-truth and is not rewritten by supplier master

Existing Edge:
`save-supplier`
- Version 5
- ACTIVE
- verify_jwt = true
- no new Edge Function created

### Production Search Verification
Authenticated purchaser context:
- blank search → exact current purchaser returned
- `buyer1` → exact current purchaser returned
- Arabic multi-token search → exact current purchaser returned

Unauthorized direct-sales user:
- `get_supplier_purchase_reps` rejected with:
  `لا تملك صلاحية الوصول إلى مندوبي المشتريات`

### Supplier Save Verification
- valid purchaser email → CREATE PASS
- valid purchaser name → CREATE PASS
- invalid purchaser value → rejected
- QA transactions fully rolled back

### Purchase / Stock / Accounting E2E
Transient transaction:
Supplier
→ Purchase Invoice
→ POST
→ post_stock_movement
→ stock_branches + inventory_log
→ Journal
→ Supplier Ledger
→ POST replay

Measured:
- stock item 1001 BR-01: 2 → 3
- inventory_log: 6 → 7
- supplier_ledger: 0 → 1
- journal_entries: 8 → 9
- journal_lines: 12 → 14
- replay: duplicate=true

After ROLLBACK:
- suppliers = 2
- purchase_invoices = 0
- inventory_log = 6
- supplier_ledger = 0
- journal_entries = 8
- BR-01 item 1001 stock = 2

No QA residue.

### Static Owner Surgical Patch
Target:
`RW_Suppliers.openModal(code)`

Current source line:
`6935`

Replace ONLY the exact defective element above with the complete replacement in:
`doc/Draft/Reprots/Report326_MOTHER_SUPPLIER_PURCHASE_REP_SMART_SEARCH_FORENSIC_SURGICAL_CLOSURE_20260924.md`

Static verification against current blob:
- target occurrence = 1
- replacement occurrence = 1
- JavaScript parse = PASS
- main.html repository write = NO

### Browser E2E
**OPEN / UNVERIFIED**

No authenticated browser runtime was available in this session.

Do not convert:
- DB/RPC E2E
- source static parse
- Production integration E2E

into authenticated Browser E2E PASS.

### Documentation
- Final report:
  `doc/Draft/Reprots/Report326_MOTHER_SUPPLIER_PURCHASE_REP_SMART_SEARCH_FORENSIC_SURGICAL_CLOSURE_20260924.md`
  commit: `21f63c4cbf594405a9af670871139a51fdc9f4ba`
- Execution log:
  `doc/Draft/Reprots/EXECUTION_LOG_20260924_SUPPLIER_PURCHASE_REP_SMART_SEARCH.md`
  commit: `414a18010cbb14a5136e45d4d54b2f16d1df627b`

### Exact Next Resumption Point
1. Re-verify System HEAD `85ad9d2b1a195e5b8845a6550beec5fd85fdfc41`.
2. Re-verify Mother HEAD `897d40c47b27544fb8a5515a7f7dcce528c4563e`.
3. Re-verify main.html blob `f4e707060a3f0ff68b993bf57616e4e861ac54e6`.
4. Do not reopen Report325 Supplier Save repair.
5. Do not reopen Supplier Code Preview repair.
6. In `RW_Suppliers.openModal(code)`, replace ONLY the exact line-6935 `supp-rep` element using Report326.
7. Parse full main.html.
8. Owner commits/publishes frontend.
9. Verify served artifact identity.
10. Fresh authenticated login.
11. Mother → الموردين → إضافة مورد جديد.
12. Search for `مندوب مشتريات 1` or `buyer1`.
13. Select result.
14. Save supplier.
15. Verify Network/Console, row refresh, and purchase_rep persistence.
16. Edit supplier and verify financial balance is unchanged by Master Data.
17. Verify supplier audit.
18. Run fresh Production snapshot at report time.
19. Update CURRENT_STATE again.
20. Do not reopen this closure without contradictory current evidence.

### Closure Status
- Production Smart Search Capability = CLOSED / VERIFIED
- Production Supplier Save validation = CLOSED / VERIFIED
- Purchase/Stock/Accounting integration = E2E VERIFIED
- Mother exact source target = VERIFIED / READY
- main.html owner patch = PENDING OWNER
- Published artifact = OPEN / UNVERIFIED
- Authenticated Browser E2E = OPEN / UNVERIFIED
- Overall Supplier Purchase Representative Smart Search = PARTIALLY CLOSED

---

# LATEST AUTHORITATIVE CHECKPOINT — 2026-09-24 07:05 UTC

## Current Truth
CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE only.

### Latest System Git
- Current checkpoint before this update: `89058fcdb80e311694607a8a24e653b2fc5570ca`
- Parent: `1b4744eb345c652dec9745b141e704be69c0d04e`
- New forensic report: `doc/Draft/Reprots/Report324_MOTHER_PURCHASE_INVOICE_OWNER_PATCH_FORENSIC_CLOSURE_20260924.md`
- Report commit: `b0b2503a3f714d6c42c492b0a1ec4761fa8658be`

### Current Mother Frontend
- Repository: `papamohammed77-glitch/erp-frontend`
- HEAD: `ae6049f9672031da7113b2b1296e7f3fee14eeee`
- Parent: `1799a7107460410840efbd76a1145e624f0b2a34`
- `companies/company-1/main.html` blob: `e1766d81a59a5e18d654f0366846701c36922edf`
- Owner applied Report323 to Mother source.
- No assistant write to `main.html`.

### Mother Purchase Current Source Forensics
`RW_PurchaseGold.createInvoice()` now contains:
- supplier smart search
- item smart search
- PO→supplier synchronization
- supplier invoice number field
- invoice notes field
- selected-item logic

Current source defect proven:
- obsolete legacy handler tail remains at lines 13543–13550.
- full inline script compilation fails with `SyntaxError: Unexpected token 'catch'`.

Missing source payload proven:
- `preConfirm` contains `supplier_invoice_no`
- `notes: byId('pg-i-notes').value.trim(),` is missing.

After exact owner surgical corrections:
- PATCH-324-01 removes only the obsolete tail.
- PATCH-324-02 adds only the missing notes line.
- in-memory full inline-script compilation = PASS.

### Current Production Purchase
- `save-purchase-order`: Version 7, ACTIVE, verify_jwt=true.
- Production source matches canonical Current source.
- CREATE_INVOICE → `purchase_create_invoice_atomic_v2`.
- No new Edge Function required.
- `purchase_create_invoice_atomic_v2` persists `supplier_invoice_no` and `notes`.
- `purchase_post_invoice_atomic` posts inventory through `post_stock_movement`, then Journal + Supplier Ledger.

### Fresh Production E2E (transactional / rollback)
- CREATE = PASS.
- CREATE same `operation_id` = `duplicate=true`, same invoice = PASS.
- POST = PASS.
- POST replay = `duplicate=true` = PASS.
- Stock delta = +2.
- Inventory movements for invoice = 1.
- Supplier Ledger rows = 1, credit = 110.
- Journal entries = 1, lines = 2, debit = 110, credit = 110.
- Invoice detail `received_qty=2`.
- Invoice persisted fields in transaction: supplier invoice reference + notes = PASS.
- Transaction rolled back; no permanent QA purchase data remains.

### Current Production Database Snapshot
- companies = 1
- active_branches = 4
- active_suppliers = 0
- active_items = 16
- purchase_orders = 0
- purchase_invoices = 0
- purchase_invoice_details = 0
- supplier_ledger rows = 0
- purchase journal rows = 0
- inventory_log rows = 6

### Competitive Contract Check
Current official references confirm mature purchase invoice workflows include Supplier, Reference, Due Date/Payment Terms, PO relation, item/qty/price/tax/discount, posting, AP impact, inventory/accounting integration and invoice verification/matching. Current RAWAEA backend already contains the required relational and posting foundation for the present closure; advanced 3-way matching/tolerance/workflow remain separate Business Contract closures.

### Closure Status
- Production Purchase Core = CLOSED / VERIFIED
- Supplier Smart Search Backend = CLOSED / VERIFIED
- Item Smart Search Backend = CLOSED / VERIFIED
- Supplier Invoice Reference Backend = CLOSED / VERIFIED
- Notes Backend = CLOSED / VERIFIED
- Mother main.html = FOUND DEFECT / OWNER PATCH READY
- Full Mother syntax = OPEN until owner applies PATCH-324-01
- Notes payload = OPEN until owner applies PATCH-324-02
- Authenticated Browser E2E = OPEN

### Exact Next Resumption Point
1. Read Report324.
2. Verify Mother HEAD `ae6049f...` and blob `e1766d...`.
3. Search `RW_PurchaseGold.createInvoice()`.
4. Delete exact lines 13543–13550 from PATCH-324-01 only.
5. Add the exact `notes` line from PATCH-324-02.
6. Parse full `main.html`.
7. Commit/publish frontend.
8. Verify served artifact identity.
9. Fresh authenticated browser E2E.
10. Verify Purchase CREATE → POST → stock → inventory_log → supplier_ledger → journal → realtime.
11. Replay CREATE and POST.
12. Capture fresh Production snapshot.
13. Update CURRENT_STATE.
14. Do not reopen closed Purchase backend contracts unless contradictory current evidence appears.

### Anti-Regression
Do not reapply Report323. Do not replace `createInvoice()` wholesale. Do not create a new Edge Function for this closure.

---

# LATEST AUTHORITATIVE CHECKPOINT — 2026-09-23 18:30 UTC

## Current Truth
CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE only.
Historical reports are contextual evidence only.

## Latest System Git
- Report323 commit: `1b4744eb345c652dec9745b141e704be69c0d04e`
- Purchase invoice canonical migration commit: `69934930fe1ecb5c3e9f0edf68db27d316aa78da`
- Current source sync commit for `Current/Edge_Functions/save-purchase-order`: `6050c4fff806142f81504affbbf87207090ce281`

## Current Mother Frontend
- Repository: `papamohammed77-glitch/erp-frontend`
- Current HEAD: `8a12be7d7faf3294131e7b51de810d6e040a8faf`
- Direct parent: `2a8ce1d41e0af948bbec99ef947a3aaa492b13a5`
- Current `companies/company-1/main.html` blob: `71aec095f7c20a92b8f19b4cbc3e7bc237941ef1`
- No assistant write to `main.html`.

### Mother Purchase Target
Current `RW_PurchaseGold.createInvoice()`:
- invoice modal at approximately lines 13032–13282
- supplier field is a plain `select`
- item code is exact text input + exact lookup
- `supplier_invoice_no` is collected then deleted before API call

### Owner Patch
Canonical surgical owner patch is Report323:
`doc/Draft/Reprots/Report323_MOTHER_PURCHASE_INVOICE_SMART_SEARCH_FORENSIC_SURGICAL_CLOSURE_20260923.md`

Apply only:
- PATCH-323-00
- PATCH-323-01
- PATCH-323-02
- PATCH-323-03
- PATCH-323-04
- PATCH-323-05
- PATCH-323-06
- PATCH-323-07

Do not replace the whole `main.html`.
Do not modify already-closed purchase backend contracts.

## Current Production Purchase
- `save-purchase-order`: Version 7, ACTIVE, verify_jwt=true.
- CREATE_INVOICE now calls `purchase_create_invoice_atomic_v2`.
- `purchase_create_invoice_atomic_v2` persists `supplier_invoice_no` and `notes` by calling the existing `purchase_create_invoice_atomic` and updating the newly created Draft invoice atomically.
- No new Edge Function was created.

## Production Database Snapshot
At current verification:
- active suppliers = 0
- active items = 16
- active branches = 4
- purchase_orders = 0
- purchase_invoices = 0
- purchase_invoice_details = 0
- supplier_ledger rows = 0
- Purchase journal entries = 0
- inventory_log rows = 6
- purchase_settings rows = 0

No permanent QA purchase entities remain.

## Production E2E — Purchase Invoice
### Core
CREATE → POST → Physical Stock → inventory_log → Supplier Ledger → Journal Entry → invoice detail received_qty → ROLLBACK = PASS

### Idempotency
CREATE same operation_id → duplicate=true = PASS
POST same invoice twice → duplicate=true = PASS
Physical movement count remained 1.
Supplier ledger count remained 1.

### v2 Reference Extension
CREATE with supplier_invoice_no → persisted = PASS
Replay same operation_id → duplicate=true = PASS
POST → stock delta = PASS
inventory_log = PASS
supplier_ledger = PASS
journal entry = PASS
ROLLBACK = PASS

## Smart Search Verification
Transactional SQL predicates for:
- supplier name/code/phone/search_label
- item code/name/barcode/search_label

= PASS

No QA suppliers remained after ROLLBACK.

## Production / Git Alignment
- Production `save-purchase-order` Version 7 source was copied into canonical `rawaie-erp-New/Current/Edge_Functions/save-purchase-order`.
- Canonical migration file:
  `supabase/migrations/20260923_purchase_invoice_reference_extension.sql`

## Browser State
OPEN:
- owner patch application
- full main.html parse after patch
- frontend commit/publish
- served artifact identity
- authenticated Browser E2E
- fresh Network/Console evidence

Do not convert DB/RPC E2E into Browser E2E.

## Competitive Contract Findings
Reference patterns verified from Odoo / Dynamics 365 / SAP:
- supplier/vendor lookup
- invoice reference from supplier
- PO source relationship
- item line lookup
- quantities, prices, discounts/taxes
- invoice verification/matching
- posting creates financial effects
- supplier payable/ledger impact
- receipt/inventory relationship

RAWAEA already contains the required backend relational model and posting engine. The remaining Mother gap is UX/search execution and fresh browser proof, not new purchase infrastructure.

## Exact Next Resumption Point
1. Re-read Report323.
2. Verify Mother HEAD `8a12be7...` and main blob `71aec095...`.
3. Apply only PATCH-323-00..07 to `companies/company-1/main.html`.
4. Full script parse.
5. Commit/publish.
6. Verify served artifact identity.
7. Fresh login.
8. Purchase Cycle → Purchase Invoices.
9. Supplier smart search.
10. Item smart search.
11. Create invoice.
12. Check supplier invoice reference persistence.
13. Post invoice.
14. Verify Network + Console.
15. Verify DB rows and stock/accounting effects.
16. Verify Realtime refresh.
17. Capture fresh Production snapshot.
18. Update CURRENT_STATE again.
19. Do not reopen closed purchase backend work without contradictory current evidence.

---

# LATEST AUTHORITATIVE CHECKPOINT — 2026-09-23 18:45 UTC

## Current Truth
CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE only.
Historical reports are contextual and must be re-verified.

## Current System Git
- Latest report commit before this CURRENT_STATE update: \`10b997bab19f943d0d75b01ce31eb5653a87318f\`
- Parent: \`69e4b647b929efdd2834cf26273af01e7ee0fe45\`
- New report: \`doc/Draft/Reprots/Report322_MOTHER_BRANCH_SAVE_SESSION_FORENSIC_SURGICAL_CLOSURE_20260923.md\`

## Current Mother Frontend Truth
- Repository: \`papamohammed77-glitch/erp-frontend\`
- HEAD: \`6fdcebc551d8eef9a9fd3a8fe8c200d0d4ce90c2\`
- Parent: \`5c4fd658e6046d93ca80db18fb15f2521cc9e4b1\`
- Current \`companies/company-1/main.html\` blob: \`7e9e49895bddd1369ac6ead8c00cfcbc172d3603\`
- No assistant write to \`main.html\`.

## Branch Save — Current Forensic Status
### Historical defect
The observed 400s on 2026-09-23 13:09–13:24 UTC were all on \`save-branch\` Version 4.
That version's auth/schema defect is closed.

### Current Production
\`save-branch\`:
- Version 5
- ACTIVE
- verify_jwt=true
- deployment id: \`b289cefd-6875-4c2b-8970-395f223a14cb\`
- deployment evidence: 2026-09-23 14:23:35 UTC

Current Production user evidence:
- auth_id = \`0a6089e6-0c33-4cf9-9aa0-31fc42774b89\`
- company_id = \`00000000-0000-0000-0000-000000000001\`
- status = Active
- permissions = [\`*\`]

Current \`public.users\` schema has no \`is_owner\`.

### Current source defect
\`RW_Branches.openModal(code)\` save handler at lines 7083–7092 only calls:
\`supabase.auth.getSession()\`
and sends the cached token directly.

The current source does not:
- inspect token expiry;
- refresh before save when expiry is near;
- retry once after an auth rejection.

This is classified as:
CURRENT SOURCE AUTH-FRESHNESS DEFECT.

The exact latest user click cannot be independently proven as a Version 5 runtime failure because no matching Version 5 POST 400 is present in the available runtime snapshot.

## Owner Surgical Patch
Target:
\`papamohammed77-glitch/erp-frontend/companies/company-1/main.html\`

Current SHA:
\`7e9e49895bddd1369ac6ead8c00cfcbc172d3603\`

Target:
\`RW_Branches.openModal(code)\` → save handler lines 7083–7092.

Exact replacement is documented completely in:
\`doc/Draft/Reprots/Report322_MOTHER_BRANCH_SAVE_SESSION_FORENSIC_SURGICAL_CLOSURE_20260923.md\`

Do not modify the whole function.
Do not reopen Report320/321 fixes.

## Production / Database
No Production change was required in this cycle.

Transactional test:
\`QA-BR-923\`
CREATE → UPDATE → DELETE → ROLLBACK = PASS

Post-test:
- QA rows = 0
- branches = 3

Current snapshot:
- companies = 1
- branches = 3
- active_branches = 3
- vehicles = 2
- auth-linked users = 25

## Current main.html Syntax
Full current inline script parse:
PASS

Current syntax closures already present:
- Customer openModal line 6772
- Supplier openModal line 6917
- Branch openModal line 7055

## Competitive Study
No Branch schema expansion was implemented.
Future Branch Master 2.0 candidates remain uncommitted:
- branch type
- region/GPS
- operating hours/contact email
- barcode
- capacity
- warehouse capability
- replenishment policy
- receiving/picking profile
- financial dimension/cost center
- transfer policy
- operational calendar

Official comparative sources are recorded in Report322.

## Browser / Published Artifact
OPEN:
- owner-side main.html patch
- frontend commit/publish
- served artifact identity
- authenticated Browser E2E

Do not convert static parse or transactional DB tests into Browser E2E.

## Exact Next Resumption Point
1. Read Report322.
2. Verify frontend HEAD and main.html SHA above.
3. Apply only the exact Owner patch in Report322 Section 9.
4. Parse full main.html.
5. Commit/publish frontend.
6. Verify served artifact identity.
7. Login with a fresh session.
8. Mother → المخازن والفروع → إضافة فرع → حفظ.
9. Verify POST save-branch success and branch list refresh.
10. Test Edit and Inactive status.
11. Inspect fresh save-branch runtime logs.
12. Update this file again from the new verified checkpoint.
13. Do not re-run already closed historical fixes without new contradictory evidence.

---

# LATEST AUTHORITATIVE CHECKPOINT — 2026-09-23 14:26 UTC

## Current Truth
CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE only.
Historical reports remain contextual unless re-verified.

## Latest System Git
- HEAD: `eacedf557210a89b4d5a08d79d2e5c4ec76d7c93`
- Parent: `51e67154d9f1fd65f6317ad22b9cdc47b2aff07e`
- Report: `doc/Draft/Reprots/Report320_MOTHER_BRANCH_FLEET_SURGICAL_CLOSURE_20260923.md`
- Canonical current Production source:
  - `Current/Edge_Functions/save-branch`
  - `Current/Edge_Functions/delete-branch`

## Mother Frontend — Current Source
- Repository: `papamohammed77-glitch/erp-frontend`
- HEAD: `6d505d30dcad981932b3f3562ea9bb37901fecb4`
- Parent: `c2ac6d33cb5c20ba6539f61cabde1b33866ecb46`
- main.html SHA: `8c3d6b05fd6a94a6b488f12b29da85ae888f70bc`
- No assistant write to `companies/company-1/main.html`.

## Fresh Production Snapshot
- active companies = 1
- active branches = 3
- active vehicles = 2
- mobile-stock vehicles = 2
- VAN-prefixed branches = 2
- inventory_log = 6
- audit_log = 2147
- QA vehicles = 0
- QA branches = 0
- QA Fleet operations = 0

## Branch Save Defect — CLOSED
Proven root cause:
- Production `save-branch` queried non-existent `public.users.is_owner`.
- `public.users` has `auth_id`, `company_id`, `permissions`, `status`, etc., but no `is_owner`.
- This caused the observed `سياق الشركة غير صالح` 400.

Production:
- `save-branch` v5 deployed.
- `delete-branch` v4 deployed for the same invalid-column defect.
- company/auth scoping preserved.
- numeric BR code generation fixed to max actual numeric BR code; VAN codes excluded.
- no new Edge Function created.

## Branch Code
Current business branch: `BR-01`.
Current mobile contexts: 2 `VAN-` branches.
Numeric generator test: BR-01 + BR-9 + BR-10 + VAN-* → `BR-11`.

## Fleet
- `fleet_command_atomic` contains `VEHICLE_UPDATE`.
- Production transaction E2E passed for model, plate, weight, dimensions, volume recomputation, condition, route, efficiency, ownership; transaction rolled back.
- Current Mother already renders `expected_km_per_liter`, `operational_condition`, `route_capability`; do not reopen these closed cells.
- Current Mother missing only the edit consumer/onclick/export required by Report320.
- Vehicle mobile branch remains a context/container, not a second Branch Master or inventory engine; custody remains with the operational representative/driver according to the existing DirectSale contract.

## Owner Surgical Patch — Report320
Target: `erp-frontend/companies/company-1/main.html`
- PATCH-320-BR-01..03: numeric code preview + mobile vehicle semantic badge.
- PATCH-320-FL-01..03: edit onclick + `openVehicleEdit(id)` + API export.
- Do not replace main.html.
- Do not replace the Fleet module.
- Do not modify already-correct efficiency/condition/route table cells.

## Browser E2E
OPEN.
Required final gate: owner patch → full Mother JS parse → publish → served artifact SHA verification → authenticated Branch/Fleet E2E → fresh Production snapshot.

## Exact Next Resumption Point
1. Read Report320.
2. Verify Mother HEAD `6d505d30dcad981932b3f3562ea9bb37901fecb4` and main blob `8c3d6b05fd6a94a6b488f12b29da85ae888f70bc`.
3. Apply only PATCH-320-BR-01..03 and PATCH-320-FL-01..03.
4. Parse, publish, verify served artifact.
5. Run authenticated E2E.
6. Capture fresh Production snapshot.
7. Update CURRENT_STATE.

---

# LATEST AUTHORITATIVE CHECKPOINT — 2026-09-23 13:50 UTC

## Current Truth
CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.
Historical reports remain contextual only.

## Latest System Git
- HEAD: 011ee6dbeeee1c55304d9eebafd2c819feaef1a8
- Parent: fd64fd443acd238fdf80f395adb7c325e84a7d15
- Final report: doc/Draft/Reprots/Report319_WAREHOUSE_VOUCHERS_CURRENT_PRODUCTION_EXECUTION_20260923.md
- Production migration commit: fd64fd443acd238fdf80f395adb7c325e84a7d15

## Frontend Current Source
- HEAD: c2ac6d33cb5c20ba6539f61cabde1b33866ecb46
- Parent: 5cf09bac46aa65fa1e94ba34dfbdc3760cd446e2
- vouchers.html SHA: 1bbca38299ff093798badaaafda6a2b986583527
- main.html SHA: 8c3d6b05fd6a94a6b488f12b29da85ae888f70bc
- van-sales.html SHA: 8d61382a8e0025a0d079e71dd94f33d106d9088e

## Protected Source Files
No assistant write:
- main.html
- vouchers.html
- van-sales.html

## Production Snapshot — authoritative for this checkpoint
Captured: 2026-09-23 13:50:39.591176+00
- companies = 1
- branches = 3
- active_branches = 3
- vehicles = 2
- active_vehicles = 2
- direct reps = 2
- voucher users = 1
- items = 16
- stock_branches = 48
- inventory_log = 6
- audit_log = 2141
- stock_vouchers = 0
- drafts = 0
- explicit TEST vehicles = 1

## Production Changes Executed
1. fleet_query vehicle projection fixed in Production to expose:
   - expected_km_per_liter
   - operational_condition
   - route_capability
2. Reproducible migration committed:
   supabase/migrations/20260923_fleet_query_vehicle_operational_fields_projection_fix.sql
3. Current Draft IN-1 was proven test data (N-Test-01), had zero Physical Movement, and was deleted through the existing Draft delete capability.
4. No new Edge Function created.
5. No frontend source file written.

## Production E2E
Transient DirectSale E2E in one transaction:
- CREATE = PASS
- SEND = PASS
- COMPLETE = PASS
- stock delta = PASS
- custodian = direct-sales representative
- movement logs = 1
- rollback = PASS

The vehicle->representative link was temporary inside the transaction only.

## Current DirectSale Reality
Current Production vehicles are active/mobile-stock-enabled but have driver_id = NULL.
Therefore the existing DirectSale picker correctly has no eligible vehicle until a valid direct-sales representative is assigned to a vehicle.
Do not weaken this contract.

## Current Voucher Owner Patch Status
Report318 PATCH-01 through PATCH-08 are still pending in owner-owned vouchers.html.
New delta in Report319:
- PATCH 319-01 App.printDraftVoucher
- Draft action must add Print and retain Edit/Delete/Send after PATCH-05.

Static syntax of PATCH 319-01 = PASS.

## Current Mother ERP Gaps
- New Branch UI still presents textual "جديد"; Production save-branch already generates next numeric BR-n.
- Historical save-branch 400 root cause is NOT proven for a specific browser session; do not weaken auth_id/company validation.
- Fleet backend has VEHICLE_UPDATE, but current main.html lacks the Edit/Onclick UI action.
- Fleet operational fields now come from Production fleet_query.
- Branch/Vehicle semantic model remains Vehicle = mobile context/container; representative is custody actor for DirectSale.

## Browser / Served Artifact
OPEN:
- authenticated Browser E2E
- served artifact identity after owner frontend publish

Do not convert RPC or source-harness PASS into Browser E2E PASS.
Do not claim GLOBAL INVENTORY CORE INTEGRITY = 100% CLOSED.

## Next Exact Resumption Point
1. Read Report319.
2. Re-read CURRENT_STATE latest block and verify current Git/Frontend SHA.
3. Do not reopen closed backend contracts.
4. Owner applies Report318 PATCH-01..08 to vouchers.html.
5. Owner applies Report319 PATCH-319-01 only for Draft Print.
6. Static parse.
7. Commit frontend.
8. Publish.
9. Verify served artifact SHA against Git.
10. Authenticated E2E: Transfer, DirectSale, DirectReturn, SupplierReturn, Draft Print/Edit/Delete, Send, Receive, Complete.
11. Capture a fresh Production snapshot.
12. Update CURRENT_STATE.
13. Only then evaluate full closure.

---

# CURRENT EXECUTION CHECKPOINT — 2026-09-23

## Source of Truth
CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE only.
Reports are historical guidance and must not be treated as current state without re-verification.

## Latest Git
System repo:
- HEAD before this checkpoint: `ce6341dc31effb79bd8e065d2c91e3eec75363b9`
- Parent: `6a0b744a6630d3358d9f23cf787f417258e6b2fd`
- Latest documentation commit created in this session: `db47da584a16a76baa5b20c51216941da8acadfd`
- Report: `doc/Draft/Reprots/Report318_WAREHOUSE_VOUCHERS_CURRENT_CLOSURE_20260923.md`

Frontend repo:
- HEAD: `c2ac6d33cb5c20ba6539f61cabde1b33866ecb46`
- Parent: `5cf09bac46aa65fa1e94ba34dfbdc3760cd446e2`
- Current vouchers.html SHA: `1bbca38299ff093798badaaafda6a2b986583527`
- Mother main.html SHA: `8c3d6b05fd6a94a6b488f12b29da85ae888f70bc`
- van-sales.html SHA: `8d61382a8e0025a0d079e71dd94f33d106d9088e`

## Forbidden Source Changes
No assistant write was made to:
- `companies/company-1/main.html`
- `companies/company-1/warehouse/vouchers.html`
- `companies/company-1/sales/van-sales.html`

The owner must manually apply Report318 surgical patches to vouchers.html only.

## Current Production Snapshot
Captured: 2026-09-23 12:08:24+00
- companies = 1
- branches = 1
- vehicles = 0
- suppliers = 0
- direct reps = 1
- warehouse users with active_warehouse_role=أذونات = 1
- stock_vouchers = 0
- stock_voucher_details = 0
- items = 16
- stock_branches = 16
- inventory_log = 6
- QA items = 0
- QA branches = 0
- QA vehicles = 0
- QA suppliers = 0
- stock_voucher_operations technical tombstones = 10

Current business branch:
- BR-01 only.
Vehicles and suppliers are currently empty by design after QA cleanup; new real entities must originate from Mother ERP.

## Data Cleanup Completed
Deleted after proving no operational references:
- BR-2 test branch
- ITM-1057
- ITM-1058
- ITM-1059
- ITM-1060
- their QA stock rows
- three QA opening-balance inventory_log records

Historical operational inventory logs were preserved.

Technical operation tombstones were preserved because the Production integrity trigger forbids deleting operation identities.

## Backend Capability Verified in Production
Existing endpoint only; no new Edge Function created.
- create-stock-voucher
- update_manual_stock_voucher_atomic
- delete_manual_stock_voucher_atomic
- send_stock_voucher_atomic
- post_manual_stock_voucher_atomic
- post_stock_movement

Production RPC E2E verified:
CREATE → UPDATE → REPLAY → CONFLICT rejection → DELETE

## Current Verified Source Defects
1. `App.pickSearch(key,q)` contains `z.split(/s+/)`; must be `z.split(/\s+/)`.
2. `App.subscribeRealtime()` uses a large `branch_id=in(...)` stock_branches filter; should be source-branch scoped.
3. Draft cards expose Cancel but not Edit/Delete.
4. Edit mode requires explicit state reset in `choose` / `back`.
5. Edit UI and submit path are absent even though backend UPDATE/DELETE capabilities already exist.

## Already-Closed Source Areas
Do NOT reopen without new evidence:
- `App.loadRefs()` pagination/company scope
- `App.allowedBranch()`
- `App.vehicleBranch()`
- `App.pickArr()`
- `App.pickSelect()`
- `App.prefetchStock()`
- `App.routeHtml()`
- `App.renderWorkspace()`
- Mother ERP main.html
- Van Sales integration

Transfer contract:
warehouse user + activeWarehouseRole=أذونات + same company → all active company branches.
Backend remains final authorization guard.

## Report318 Owner Patch Set
Apply ONLY the eight surgical patch groups documented in Report318:
- App.pickSearch
- App.subscribeRealtime
- App.updateSource
- App.choose
- Draft action block inside App.cards
- App.editVoucher + App.deleteVoucher
- App.submit
- App.back

Temporary in-memory composition of the current HTML with all Report318 patches compiled successfully.

## Test Evidence
Exact Current Source harness:
- Before patch: multi-token vehicle query `QA VCH` failed.
- Before patch: multi-token branch query `BR 01` failed.
- After patch: both passed.
- Arabic vehicle plate search passed before/after.
- Representative search passed before/after.
- Supplier search passed before/after.

Temporary QA vehicle/supplier/branches were created for search testing and then deleted.
No QA business entities remain.

## Browser E2E Status
OPEN.
Reason: no authenticated browser session/tool was available to verify the served frontend interactively.
Do not convert RPC/source-harness PASS into Browser E2E PASS.
Do not claim 100% closure until:
- owner patches are applied,
- frontend is committed/published,
- served artifact is verified against Git,
- authenticated Browser E2E passes.

## Next Exact Resumption Point
Read Report318 first.
Then read the current vouchers.html SHA above.
Apply only Report318 surgical owner patches.
Do not touch main.html or van-sales.html.
Then perform static parse → publish → served artifact verification → authenticated E2E → fresh Production snapshot → update CURRENT_STATE again.

---

# RAWAEA ERP — CURRENT STATE
## Authoritative Forensic Checkpoint — 2026-09-23
## Current checkpoint: VCH-CURRENT-SOURCE-SCALE-20260923

Canonical report:
doc/Draft/Reprots/Report317_WAREHOUSE_VOUCHERS_CURRENT_SOURCE_FORENSIC_SCALE_20260923.md

Execution log:
doc/Draft/Reprots/EXECUTION_LOG_20260923_VOUCHERS_CURRENT_SOURCE_SCALE.md

### System Git
- Current state commit: 365e5919c6fac6fc4304c7640c4a66941f1b1293
- Parent of current state commit: 3266d529f9715a97d336b69868e210c2f003a9d6
- Prior system HEAD before Report317: 820a4f314959a743d24ca9f497089b4b0a3058a7
- Prior parent: 2f676b5a7d4af08fbeb978b3d1b8a59ea8acd969
- Report317 commit: 257ee8c3ec4dfada2102f62c90f5f8eb3f6da847
- Execution log commit: 3266d529f9715a97d336b69868e210c2f003a9d6

### Frontend Git
- Current HEAD: 5cf09bac46aa65fa1e94ba34dfbdc3760cd446e2
- Parent: 2da3d6d9ae6b3e84ea0920998ecdefa94ed4d8e3
- Parent of parent: 751f6175675ffe99023337e523501bd35e9553c6
- Current vouchers.html blob: fe0cbf6a6bbacc7086ea4fd8e9e78339e94820a8
- Current van-sales.html blob: 8d61382a8e0025a0d079e71dd94f33d106d9088e
- Current main.html blob: 8c3d6b05fd6a94a6b488f12b29da85ae888f70bc

### Files explicitly protected in this cycle
- main.html — untouched
- vouchers.html — untouched by assistant
- van-sales.html — untouched

### Production snapshot
UTC: 2026-09-23 10:23:36.322334
- companies=1
- branches=1354
- active_branches=1352
- vehicles=1202
- active_vehicles=1200
- direct_sales_reps=10001
- suppliers_total=501
- suppliers_active=500
- stock_vouchers=42
- inventory_log=45
- audit_log=3950
- active_drafts=0

### Current forensic findings
1. App.prefetchStock sends all 1352 branch UUIDs in branch_id=in.(...), measured filter size 50038 chars; this is the proven cause of the reported stock sync 400.
2. App.updateSource does not refresh stock after Source Branch / Vehicle changes.
3. App.subscribeRealtime repeats the all-branch giant filter for stock_branches.
4. App.pickArr performs repeated vehicle->branch and vehicle->rep scans at current scale.
5. Transfer scope is already correct: warehouse vouchers role can search/select all active same-company branches.
6. DirectReturn has 1200 valid mobile vehicle candidates for the warehouse vouchers operator.
7. DirectSale BR-01 has 1 eligible candidate under the existing backend rep/source-branch contract; do not weaken that contract in the UI.
8. Smart-search fields are present in current Git; published behavior is not yet proven.

### Closed and must not be repeated
- Physical stock central engine
- post_stock_movement routing
- reserve/release reservation contract
- Transfer backend authorization
- allowedBranch Transfer exception
- pickSelect vehicle->rep binding
- loadRefs pagination contract
- van-sales central invoice integration
- DirectReturn backend capability
- old QA draft cleanup
- prior Transfer E2E
- prior backend DirectSale/DirectReturn/SupplierReturn E2E

### Production E2E in this cycle
Transient IN-43:
- CREATE PASS
- SEND PASS
- RECEIVE PASS
- RECEIVE replay with same operation_id: duplicate=true PASS
- COMPLETE PASS
- movement_logs=2
- allocated_qty=0
- ROLLBACK PASS
No IN-43 residue remains.

### Data cleanup
Active Draft Vouchers = 0.
Movement-bearing historical QA records are preserved because the delete guard protects stock-document history; no Integrity Guard bypass was used.

### Owner change package
Target:
companies/company-1/warehouse/vouchers.html

Current SHA:
fe0cbf6a6bbacc7086ea4fd8e9e78339e94820a8

Apply only the exact replacements in Report317:
- PATCH-317-01 App.prefetchStock
- PATCH-317-02 App.updateSource
- PATCH-317-03 App.debouncedRefreshStock
- PATCH-317-04 App.vehicleBranch
- PATCH-317-05 App.pickArr
- PATCH-317-06 App.pickSearch

Do not modify:
- main.html
- van-sales.html
- allowedBranch()
- pickSelect()
- loadRefs()
- norm()
- routeHtml()
- submit()
- prepare()

### Deployment state
- GitHub Actions: no workflow runs/status checks associated with frontend HEAD.
- Public Pages artifact could not be fetched from available network tools.
- Published artifact identity: OPEN / UNVERIFIED.
- Authenticated browser E2E: OPEN / UNVERIFIED.

### Console state
- Stock sync 400: ROOT CAUSE PROVEN; owner patch ready.
- SW auto-reload warning: infrastructure issue OPEN.
- Tailwind CDN warning: non-blocking infrastructure debt in app.html.

### Closure status
- Production backend voucher lifecycle: CLOSED / VERIFIED
- Physical Stock Core: CLOSED
- Transfer authorization: CLOSED
- QA cleanup: CLOSED
- Current frontend root cause: PROVEN
- Owner source patch: READY
- Published artifact: OPEN
- Browser E2E: OPEN
- Overall Vouchers target: PARTIALLY CLOSED

### Next exact resumption point
1. Verify frontend HEAD 5cf09bac46aa65fa1e94ba34dfbdc3760cd446e2.
2. Verify vouchers.html blob fe0cbf6a6bbacc7086ea4fd8e9e78339e94820a8.
3. Apply PATCH-317-01 through PATCH-317-06 only.
4. Parse vouchers.html.
5. Confirm stock query is source-branch scoped.
6. Confirm no giant all-branch Realtime filter.
7. Confirm vehicle search resolves branch and rep identity through cached indexes.
8. Publish.
9. Verify served artifact identity.
10. Run authenticated E2E Transfer / DirectSale / DirectReturn / SupplierReturn.
11. Verify Draft => zero Physical Stock movement.
12. Verify receive replay => zero second movement.
13. Capture fresh Production snapshot.
14. Update CURRENT_STATE.
15. Close only what is proven.

### Continuity rule
Current truth is:
CURRENT GIT
+
CURRENT SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT EVIDENCE

Reports are historical/contextual evidence only.


## Final 2026-09-23 reconciliation after Report318
- Latest system documentation HEAD: `cee3ed04c8520210c9c6a0e8b97e5fd8a67bbd2a`
- Report318 final content commit: `cee3ed04c8520210c9c6a0e8b97e5fd8a67bbd2a`
- Global Writer Discovery classified all current PostgreSQL/Edge candidates.
- Physical Movement Writers outside `post_stock_movement`: **0**.
- `reserve_stock` / `release_stock_reservation`: reservation-only, mutate `allocated_qty`, not physical movement.
- `create_vehicle_atomic` / `setup_van_stock`: mobile-stock initialization only; create zero-quantity stock rows, no movement log.
- Current Edge wrappers `complete-return`, `complete-order-delivery`, `receive-purchase`, `save-sales-invoice` are RPC wrappers; no direct stock table writes in Current Git.
- Production currently has no QA business entities; technical operation tombstones remain by design.
- Browser authenticated E2E remains OPEN until Owner applies Report318 to frontend, publishes, verifies served artifact, and runs login-based E2E.


## Current 2026-09-24 — Supplier Purchase Representative Smart Search Closure

### Source truth
- Mother frontend repository: `papamohammed77-glitch/erp-frontend`.
- Current frontend HEAD: `897d40c47b27544fb8a5515a7f7dcce528c4563e`.
- Parent: `3520240a57f2124bbcf96c3007f67a9c36890fcb`.
- Current `main.html` blob: `f4e707060a3f0ff68b993bf57616e4e861ac54e6`.
- Current `main.html` lines: 32068.
- Commit `3520240…` changed only supplier-code preview in `RW_Suppliers.openModal()`; commit `897d40…` changed only forensic extract documentation.
- This session did NOT modify `main.html`.

### Problem closure
- Target: `RW_Suppliers.openModal(code)` → `#supp-rep` at current line 6934.
- Root cause: plain text input with no smart lookup/search.
- Direct browser lookup of `users` is not a valid solution because current RLS exposes company-wide users only to users with `users` permission.
- Canonical Production lookup already exists: `public.get_supplier_purchase_reps(text)`.
- The canonical lookup is authenticated, company-scoped, active-user scoped, and role-scoped to `مسئول مشتريات`; it searches name/email/phone/employee id.

### Production execution
- No new Edge Function created.
- `save-supplier` remains ACTIVE version 5 with `verify_jwt=true`.
- `save_supplier_atomic` remains the authoritative Supplier Master writer.
- Temporary candidate RPC `supplier_purchase_rep_search(text)` was applied during forensic validation and then fully removed; final Production count = 0.
- Canonical `get_supplier_purchase_reps(text)` remains = 1.
- Migration history for the temporary candidate was recorded in Git so Production remains reconstructable.

### Production verification
- Authenticated lookup as `buyer1@rawaea.com`: PASS; result = `مندوب مشتريات 1` / `buyer1@rawaea.com` / `مسئول مشتريات`.
- Unauthorized lookup as `vansales@rawaea.com`: PASS — rejected by permission guard.
- Supplier create with `purchase_rep`: PASS.
- Supplier update with blank `purchase_rep`: PASS; persisted as NULL.
- Stock/log/ledger/journal counts unchanged during rollback E2E.
- Final snapshot: active suppliers 2; QA supplier residue 0; inventory_log 6; stock_branches 48; supplier_ledger 0; journal_entries 8.

### Surgical Main.html patch
- Owner action only: replace the single existing `#supp-rep` div inside `RW_Suppliers.openModal()`.
- Do not change `_handleSave()`, supplier save Edge/RPC, purchase workflow, inventory, accounting, or other fields.
- The replacement uses the existing `get_supplier_purchase_reps` RPC, debounce 250ms, native datalist, and preserves optional/blank semantics.
- Static validation against current blob: target occurrences 1; inline script parse PASS; onfocus handler parse PASS; oninput handler parse PASS.

### Competitive contract review
- Odoo 19: vendor pricelists connect supplier/product with price, minimum quantity and lead time.
- Business Central: Vendor master includes Purchaser Code, Currency, Payment Terms, Posting Group, Shipping/Location and Blocking concepts.
- SAP S/4HANA: supplier data is split across central, company-code and purchasing-organization layers, including purchasing group, order currency, payment terms, lead time and purchasing block.
- Manager.io: supplier master includes credit limit, currency, address, email, division, control account and starting balance.
- These are backlog candidates only; no new Supplier Master fields were added in this closure without a proven RAWAEA Business Contract.

### Closure status
- Supplier Purchase Rep backend/data contract: CLOSED / VERIFIED.
- Main.html surgical patch: READY FOR OWNER APPLY.
- Browser authenticated UI E2E after owner patch: OPEN / UNVERIFIED.
- Served artifact identity after owner publish: OPEN / UNVERIFIED.

### Next exact resumption point
1. In current `erp-frontend/main.html` blob `f4e707060a3f0ff68b993bf57616e4e861ac54e6`, find the exact line/element for `#supp-rep` inside `RW_Suppliers.openModal()` (current line 6934).
2. Replace only that element with the exact patch in Report326.
3. Parse the complete `main.html`.
4. Commit owner patch.
5. Publish the current frontend artifact.
6. Run authenticated Browser E2E for Add/Edit Supplier → Responsible Buyer search/select/blank.
7. Verify served artifact identity.
8. Capture a fresh Production snapshot.
9. Close the UI contract only after those runtime checks pass.

### Report
- Report326: `doc/Draft/Reprots/Report326_MOTHER_SUPPLIER_PURCHASE_REP_FORENSIC_SURGICAL_CLOSURE_20260924.md`.
- Report commit: `82c72e258aab52dd8ed84d9cd70d8962663381da`.


---

# LATEST AUTHORITATIVE CHECKPOINT — 2026-09-24 — Supplier Purchase Representative Inline Scope Fix

## Current truth verified from primary sources
- Frontend repository: `papamohammed77-glitch/erp-frontend`
- Current Frontend HEAD: `47ff966a23e89b19666485ac239455ec9a06a79d`
- Parent: `3bd5ab664608e7a7632ce978d7b50c3181508516`
- Current `companies/company-1/main.html` blob: `2b14edfaaa2dc1c64af386a187b795aca9e239a9`
- Current source line count: 32,075
- Assistant direct write to `main.html`: NO

## Historical change reconciled
Commit `3bd5ab...` introduced the Responsible Buyer smart-search UI.
The later `47ff966...` commit changed only the forensic extract.
Therefore Report326's older main.html blob is stale and must not be used as current source.

## Defect
Target:
`RW_Suppliers.openModal(code)` → `#supp-rep`

Current target line: **6938**

The target occurs exactly once.

## Root cause
The page defines:
`var supabase = RW_SUPABASE_CLIENT`
inside the page's private IIFE, while explicitly exposing:
`window.RW_SUPABASE_CLIENT = client`.

The Responsible Buyer search is embedded in an inline HTML event handler. That handler cannot close over the IIFE-local `supabase` variable, so `supabase` resolves to the global Supabase SDK namespace.

That global namespace does not expose the client instance `rpc()` method.

Observed Console error:
`Uncaught TypeError: supabase.rpc is not a function`

## Correct surgical fix
Replace only the existing `#supp-rep` element inside `RW_Suppliers.openModal(code)`.

The only behavioral correction is:
`supabase.rpc('get_supplier_purchase_reps', ...)`
→
`window.RW_SUPABASE_CLIENT.rpc('get_supplier_purchase_reps', ...)`

Full replacement is documented in:
`doc/Draft/Reprots/Report327_MOTHER_SUPPLIER_PURCHASE_REP_INLINE_SCOPE_FORENSIC_CLOSURE_20260924.md`

## Production verification
Canonical Production lookup remains:
`public.get_supplier_purchase_reps(text)`

Verified properties:
- SECURITY DEFINER
- authenticated EXECUTE = true
- anon EXECUTE = false
- auth.uid required
- company derived from authenticated user
- suppliers permission required
- active users
- role `مسئول مشتريات`
- search name/email/phone/employee_id
- max 25

`save-supplier` remains Version 5 ACTIVE with verify_jwt=true.
`save_supplier_atomic` remains the Supplier Master writer.
No Production schema, table, Edge Function, inventory or accounting change was required for this UI defect.

## Current Production baseline
- suppliers = 2
- inventory_log = 6
- stock_branches = 48
- supplier_ledger = 0
- journal_entries = 8

No QA residue.

## Static verification
Against current blob:
- `id="supp-rep"` occurrences = 1
- old local RPC reference in target block = 1
- corrected global client RPC reference in in-memory patch = 1
- corrected onfocus handler parse = PASS
- no change to `_handleSave()`
- no change to purchase/inventory/accounting workflow

## Closure status
- Root cause = PROVEN
- Production backend/data contract = CLOSED / VERIFIED
- Main source surgical patch = READY / OWNER ACTION
- Served artifact identity = OPEN
- Authenticated Browser E2E after Owner publish = OPEN
- Overall Supplier Purchase Representative UI = PARTIALLY CLOSED

## Exact next resumption
1. Apply only Report327's `#supp-rep` replacement.
2. Full `main.html` parse.
3. Owner commit/publish.
4. Verify served artifact identity.
5. Run authenticated Browser E2E Add/Edit Supplier → Responsible Buyer search/select/blank.
6. Verify Console and Network.
7. Capture fresh Production snapshot.
8. Update this state again.


---

# CURRENT CHECKPOINT — 2026-09-24 — Report328 Purchase Invoice URL Forensic Closure

## Current Mother Truth
- Frontend repository: `papamohammed77-glitch/erp-frontend`
- Current HEAD: `0010f719a33bfcda3f2922eca66c6be55d5582a9`
- Parent: `b5043e626bf9eddea87644c36d024291cccff55f`
- Current Mother blob: `4eb18a27285550e81a6b1564fdb9df4708363cfa`
- File: `companies/company-1/main.html`
- Current file size: 1,741,278 bytes / 32,075 lines

## Purchase Invoice Incident
Root cause is PROVEN in current source:
`RW_PurchaseGold.api(operation, payload, operationId)` line 12040 references undefined `SUPABASE_URL` instead of existing `RW_SUPABASE_URL`.
The failure is thrown before HTTP dispatch; current `createInvoice()` catch displays the error and closes the loader. No Console error is expected from the current code because the exception is caught without console logging.

## Production Truth
- Supabase project: `fiilmooggumokxanwiyx`
- Existing Edge Function: `save-purchase-order` Version 7, `verify_jwt=true`
- CREATE_INVOICE → `purchase_create_invoice_atomic_v2`
- POST_INVOICE → `purchase_post_invoice_atomic`
- No new Edge Function created.
- No additional Production migration required for this specific incident.

## Production Snapshot at Closure Investigation
- companies = 1
- suppliers = 2
- purchase_orders = 0
- purchase_invoices = 0
- purchase_returns = 0
- purchase_payments = 0
- inventory_log = 6
- stock_branches = 48
- supplier_ledger = 0
- journal_entries = 8
- journal_lines = 12

## E2E Transactional Proof
Completed isolated Production transaction using real supplier/branch/item identities and rolled back at the end.
- CREATE invoice: PASS
- CREATE replay same operation_id: duplicate=true PASS
- POST invoice: PASS
- Stock delta: +1 PASS
- Inventory log delta: +1 PASS
- Journal entry delta: +1 PASS
- Journal lines delta: +2 PASS
- Journal debit/credit: 10.00 / 10.00 PASS
- Supplier ledger delta: +1 PASS
- Supplier credit: 10.00 PASS
- POST replay: duplicate=true PASS
- QA residue after rollback: 0

## Owner Surgical Patch — NO DIRECT MAIN.HTML WRITE
File:`companies/company-1/main.html`
Function:`RW_PurchaseGold.api(operation, payload, operationId)`
Line:12040
Find exactly:
```js
      SUPABASE_URL + '/functions/v1/save-purchase-order',
```
Replace only with:
```js
      RW_SUPABASE_URL + '/functions/v1/save-purchase-order',
```
Do not replace the whole function and do not modify closed Purchase logic.

## Static Verification
- Current full inline script compilation: PASS
- In-memory one-line correction compilation: PASS
- Current full source is not modified by the assistant.

## Closure Status
- Root cause: PROVEN
- Production backend: VERIFIED
- Production data: CLEAN
- Purchase accounting E2E: PASS
- Stock E2E: PASS
- Idempotency: PASS
- Mother surgical patch: READY / OWNER ACTION
- Served artifact: OPEN until Owner publish
- Authenticated Browser E2E: OPEN until Owner publish
- Purchase Invoice Closure: PENDING ONE-LINE OWNER PATCH

## Non-Reopened Historical Work
Report323/Report324 work already present in Current Source was not repeated.

## Next Resumption
1. Verify Owner applied Report328 one-line patch only.
2. Fetch new current Mother blob.
3. Parse full main.html.
4. Verify `RW_PurchaseGold.api()` URL expression.
5. Verify served artifact identity.
6. Run authenticated Browser E2E Purchase Invoice.
7. Capture Console + Network + HTTP.
8. Immediately snapshot Production after Browser E2E.
9. Close this Closure Unit only after those current proofs.

Reference report: `doc/Draft/Reprots/Report328_MOTHER_PURCHASE_INVOICE_SUPABASE_URL_FORENSIC_CLOSURE_20260924.md`


---

# CURRENT CHECKPOINT — 2026-09-24 — Report329 Warehouse Vouchers Receive/Print Forensic Closure

## Current Truth
- System repository: `papamohammed77-glitch/rawaie-erp-New`
- Current system HEAD: `32269bde2966201f98834899199592caf0877dd6`
- System HEAD parent: `61636eebe86173a0a9ed1858a34fef263cc6d89d`
- Latest system commit created this closure report only.
- Mother frontend repository: `papamohammed77-glitch/erp-frontend`
- Current Mother HEAD: `73e02aaf3a75fd06571475cbf2df26074e91f50d`
- Mother HEAD parent: `غير مسترد`
- Mother latest commit is forensic-extract only; it did not modify vouchers.html.
- Current vouchers file SHA: `a0ab1bc7746be6f0f4342d87fdcc2657e87b8334`
- Current vouchers lines: 3905

## Current Production
- Supabase project: `fiilmooggumokxanwiyx`
- Active voucher user: `vouchers@rawaea.com`
- role = مخزني
- active_warehouse_role = أذونات
- status = Active
- Current branches: BR-01, VAN-CHV-2025-01, VAN-FRD-2025-02 TEST, BR-2
- Current permanent stock vouchers after QA rollback:
  - `IN-2` = Draft
  - one existing Sent voucher remains
- `inventory_log` for IN-2 = 0
- BR-2 target rows created by QA = 0

## Production Transfer E2E — VERIFIED
Using real Production identities inside an isolated rollback:
- Draft → Sent → Received → Completed = PASS
- Send reduced source by 1 for each of 5 tested items.
- Receive increased target by 1 for each of the same 5 items.
- Receive replay with same operation_id returned duplicate=true.
- Physical movement rows = 10 (5 OUT + 5 IN).
- Stock total before = 54.
- Stock total after = 54.
- Conservation = PASS.
- QA rollback = PASS.
- No QA residue remained.

## Proven Current-Source Defects
1. Draft print engine exists as `printDraftVoucher(code)`; the actual defect is missing Draft-action binding.
2. `receive(code)` references `v.id` from a different Promise callback scope.
3. `pickSearch(key,q)` contains `z.split(/s+/)`.
4. `subscribeRealtime()` contains an all-branch `branch_id=in.(...)` filter.
5. `updateSource()` does not rebuild realtime when source changes.
6. Draft card actions do not expose Edit/Delete/Print.

## Owner Surgical Patch Status
No assistant write was made to:
- `companies/company-1/warehouse/vouchers.html`
- `companies/company-1/main.html`

Owner patch is documented in:
`doc/Draft/Reprots/Report329_WAREHOUSE_VOUCHERS_RECEIVE_PRINT_FORENSIC_CLOSURE_20260924.md`

Static in-memory validation of the complete Owner changeset:
- Parse = PASS
- bad `z.split(/s+/)` = 0
- giant realtime branch filter = 0
- Draft Print binding = present
- Edit/Delete consumers = present
- submit edit path = present
- receive scope fix = present
- choose/back operation reset = present

## Production Backend
No new Edge Function was created.
No new persistent test schema was left behind.
Existing capabilities remain the execution path:
- `send_stock_voucher_atomic`
- `post_manual_stock_voucher_atomic`
- `complete_manual_stock_voucher_atomic`
- `post_stock_movement`
- existing `receive-stock-voucher` Edge Function

## Closure Classification
- Transfer Production Core: CLOSED / VERIFIED
- Physical Stock Centralization: CLOSED / VERIFIED
- Draft Print root cause: PROVEN / OWNER PATCH READY
- Receive `v is not defined`: PROVEN / OWNER PATCH READY
- Voucher scale/source defects: PROVEN / OWNER PATCH READY
- Browser authenticated E2E: OPEN
- Served artifact verification after Owner patch: OPEN
- Overall Voucher Frontend Closure: PENDING OWNER PATCH + PUBLISH + BROWSER E2E

## Next Session — Start Here
1. Read this checkpoint and Report329.
2. Verify current frontend HEAD and voucher SHA again; do not trust the stored hashes blindly.
3. Do not reopen closed `loadRefs`, `allowedBranch`, `vehicleBranch`, `pickArr`, `pickSelect`, `prefetchStock`, Mother main, Van Sales, or Physical Stock centralization.
4. Apply only the documented surgical Owner patches to `vouchers.html`.
5. Parse the full file.
6. Publish and verify the served artifact identity.
7. Run authenticated Browser E2E for Draft Print and the complete Transfer lifecycle.
8. Capture a fresh Production snapshot immediately after Browser E2E.
9. Update this file again.
10. Never convert Source/Production RPC PASS into Browser PASS without browser evidence.

## Non-Negotiable Governance
Future reports are context only. Re-prove:
CURRENT GIT
+
CURRENT SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT EVIDENCE
before any new closure.
