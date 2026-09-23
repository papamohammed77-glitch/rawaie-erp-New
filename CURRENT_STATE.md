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
