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
