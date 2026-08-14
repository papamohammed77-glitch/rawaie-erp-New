# TASK-028 — COMPLETION SWEEP STATUS
Date: 2026-08-14
Branch: `task-028-loading-unloading-refactor`
PR: `#3`

## STATUS
`INCOMPLETE — NO PRODUCTION GO`

This is a Release Closeout record, not a readiness percentage.

## CONFIRMED
- Original repository remains untouched.
- Production Supabase remains untouched.
- PR #3 remains the only active TASK-028 changeset and remains Draft.
- Current now contains `start-loading`, `complete-loading`, `reopen-loading`, `cancel-loading`, and `unload-runsheet` capability wrappers.
- `start_runsheet_loading` and `cancel_runsheet_loading` transactional state capabilities were added to staging.
- Staging contains the central Loading/Unloading Core, deterministic event keys, Reopen capability, Backorder ledger, and trigger boundary.
- `run_sheet_details` concurrency integrity was hardened with unique `(runsheet_id,item_code)` plus trigger upsert semantics.

## STAGING EXECUTION EVIDENCE
Fixture: isolated company `T028`, runsheet `T028-RS`, item `T028-ITEM`.

- Full Loading 10: PASS — MAIN 100→90, allocation 10→0, VAN 0→10, state Loaded.
- Reopen 10: PASS — MAIN 90→100, allocation 0→10, VAN 10→0, state Loading, `qty_loaded=10` preserved.
- Exact Reopen retry: PASS — returned `duplicate=true`, no second physical effect.
- Reopen → partial Reload 6: PASS — MAIN 100→94, allocation 10→4, VAN 0→6, `qty_loaded=6`, Backorder 4.
- Unloading inverse: PASS — MAIN 94→100, allocation 4→10, VAN 6→0, `qty_loaded=0`, Backorder Cancelled.
- Repeated Unloading: previously verified in staging runtime record; no second reversal.
- Loaded > Picked: PASS — rejected with no stock mutation.
- Missing VAN stock row: PASS — rejected before physical mutation; fixture restored afterward.
- Failure rollback: PASS — invalid Loading request left state/stock/fulfillment at baseline.
- Generated availability: PASS — `available_qty` reflects `qty - allocated_qty` and is not directly written.
- Accounting boundary: PASS — Loading/Reopen/Unloading create no COGS/journal entries.
- Trigger consistency: PASS — `order_details.qty_loaded` is reflected in `run_sheet_details`.
- Backorder lifecycle: PASS — partial remainder Pending, reversed load Cancelled.
- Start/Cancel lifecycle: PASS — Picked→Loading→Picked with no physical stock mutation.

## NEW INTEGRATION CORRECTION
The staging trigger audit exposed that `run_sheet_details` had no uniqueness constraint and the prior count-then-insert trigger was vulnerable to concurrent duplicate creation. Current/staging were corrected with:
- unique `(runsheet_id,item_code)` index;
- trigger UPSERT semantics.

This correction must be included in the final deployable migration set.

## REMAINING BLOCKERS
1. True two-session database concurrency is still `NOT VERIFIED`; the active execution surface provides one SQL session. Therefore no concurrency PASS is claimed.
2. Current PR still contains multiple TASK-028 migration files. Before Production Review, the migration set must be consolidated/declared as one coherent deployable set with no obsolete competing definitions.
3. Production deployment has not occurred.
4. Production verification has not occurred.
5. Application consumer integration has not yet been proven against the final Current Edge contracts.

## GATE
`Static = PASS WITH OPEN RELEASE BLOCKERS`
`Staging Runtime = PASS FOR EXECUTED MATRIX EXCEPT CONCURRENCY`
`Integration = INCOMPLETE`
`Production Deploy = NOT EXECUTED`
`Production Verify = NOT EXECUTED`
`Closeout = INCOMPLETE`

No 100% completion claim is authorized.