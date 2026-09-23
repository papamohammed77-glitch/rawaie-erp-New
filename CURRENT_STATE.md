# RAWAEA ERP — CURRENT STATE
## Authoritative Forensic Checkpoint — 2026-09-23
## Current checkpoint: VCH-CURRENT-SOURCE-SCALE-20260923

Canonical report:
doc/Draft/Reprots/Report317_WAREHOUSE_VOUCHERS_CURRENT_SOURCE_FORENSIC_SCALE_20260923.md

Execution log:
doc/Draft/Reprots/EXECUTION_LOG_20260923_VOUCHERS_CURRENT_SOURCE_SCALE.md

### System Git
- Current checkpoint commit before this state update: 3266d529f9715a97d336b69868e210c2f003a9d6
- Prior system HEAD: 820a4f314959a743d24ca9f497089b4b0a3058a7
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
1. vouchers.html App.prefetchStock is the real cause of the reported stock sync 400:
   it sends all 1352 branch UUIDs in branch_id=in.(...), measured filter size 50038 chars.
2. vouchers.html App.updateSource does not reload stock after Source Branch / Vehicle changes.
3. vouchers.html App.subscribeRealtime builds the same all-branch giant filter for stock_branches.
4. vouchers.html App.pickArr performs repeated vehicle->branch and vehicle->rep scans; current scale makes this unnecessarily expensive.
5. Transfer scope is already correct: warehouse vouchers role can search/select all active same-company branches.
6. DirectReturn currently has 1200 valid mobile vehicle candidates for the warehouse vouchers operator.
7. DirectSale BR-01 currently has 1 eligible candidate under the existing backend rep/source-branch contract; do not weaken that contract in the UI.
8. Current smart search fields are present in Git; published behavior is not yet proven.

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
- GitHub Actions: no workflow runs/status checks associated with frontend HEAD 5cf09bac46aa65fa1e94ba34dfbdc3760cd446e2.
- Public Pages artifact could not be fetched from available network tools.
- Published artifact identity: OPEN / UNVERIFIED.
- Authenticated browser E2E: OPEN / UNVERIFIED.

### Console state
- Stock sync 400: ROOT CAUSE PROVEN; owner patch ready.
- SW auto-reload warning: infrastructure issue OPEN; not altered because published artifact cannot be verified and it is outside the protected voucher-only source patch.
- Tailwind CDN warning: non-blocking infrastructure debt in app.html; not altered in this cycle.

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
5. Confirm stock query is scoped to one source branch.
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
