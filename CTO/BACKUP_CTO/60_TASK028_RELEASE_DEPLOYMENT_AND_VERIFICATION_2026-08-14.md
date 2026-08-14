# TASK-028 — RELEASE DEPLOYMENT & VERIFICATION
Date: 2026-08-14

## STATUS
RELEASE DEPLOYED / CLOSEOUT NOT YET 100%

## CHANGESET
Repository: papamohammed77-glitch/rawaie-erp-New
Branch: task-028-loading-unloading-refactor
PR: #3
Original: unchanged
Production mutation: controlled migration + five Edge Function deployments

## IMPLEMENTATION CHANGES
- Central `post_stock_movement` now owns Loading/Unloading physical stock mutation.
- Loading consumes `allocated_qty` reservation and physical `qty`.
- Unloading/Reopen reverses VAN -> MAIN and restores MAIN allocation.
- Loading/Unloading require persisted event-level idempotency keys.
- `inventory_log(company_id,idempotency_key)` has a unique partial index.
- `fulfillment_backorders` is durable and deduplicated by `(order_detail_id,runsheet_id)`.
- `sync_run_sheet_details` uses unique `(runsheet_id,item_code)` plus UPSERT and fixed search_path.
- Loading lifecycle RPCs are SECURITY DEFINER with `search_path=public` and executable only by `service_role`.
- `available_qty` remains PostgreSQL-generated as `qty - allocated_qty`.

## STAGING EVIDENCE
Existing report 57 recorded PASS for:
Full Loading; Reopen; Reopen Retry; Reopen -> Partial Reload; Unloading inverse; repeated Unloading rejection; insufficient MAIN; Loaded > Picked; missing VAN; rollback; generated availability; accounting boundary; trigger consistency; backorder lifecycle.

Additional direct staging execution after migration consolidation reproduced the complete lifecycle and returned:
- main_qty_restored = true
- main_alloc_restored = true
- van_empty = true
- state_restored = true
- reopen_one_log = true

Additional direct tests:
- event idempotency: one physical effect + one inventory log
- reservation rejection: insufficient reservation leaves MAIN unchanged
- cancellation: Loading -> Picked with no physical stock effect
- backorder lifecycle: partial load creates remainder and Unloading cancels it

## PRODUCTION DEPLOYMENT
Production project: SMART ERP (`fiilmooggumokxanwiyx`)

Migration applied as `task_028_final_release`.
Production Edge Functions deployed:
- start-loading v4
- complete-loading v10
- reopen-loading v2
- cancel-loading v5
- unload-runsheet v5

All deployed functions require JWT.

## PRODUCTION VERIFICATION
Verified directly against Production after deployment:
- `stock_branches.available_qty` remains generated as `(qty - allocated_qty)`.
- `fulfillment_backorders` exists.
- `inventory_log.idempotency_key` exists.
- relevant RPCs are SECURITY DEFINER with `search_path=public`.
- relevant RPCs are executable by `service_role` and not by `anon` or `authenticated`.
- `run_sheet_details` has no duplicate `(runsheet_id,item_code)` groups.
- Production currently has zero `Loaded` runsheets, so no active Loaded run was exposed to the migration during deployment.

## APPLICATION CONSUMER AUDIT
Current/PWA/main.html was searched against the final Edge contracts.
Confirmed consumers:
- `start-loading` request: `{runsheet_code}`
- `complete-loading` request: `{runsheet_code, items}`
- `unload-runsheet` request: `{runsheet_code}`
No `reopen-loading`, `cancel-loading`, or `fulfillment_backorders` consumer was found in the Current PWA; therefore no existing UI request contract was silently broken by those backend capabilities.

## REMAINING RELEASE GATE
TRUE TWO-SESSION CONCURRENCY EXECUTION was not possible through the available single-session SQL execution interface and therefore remains NOT VERIFIED. This is not being relabeled PASS.

Production functional mutation smoke-test was deliberately not executed against live business data; production verification is deployment/schema/read-only invariant verification only.

## CONCLUSION
TASK-028 has been corrected, staged, integrated at the DB/core level, deployed to Production, and production-verified at the deployment/schema/invariant level. It is NOT labeled 100% RELEASE-COMPLETE until the concurrency evidence gate is independently executed with two concurrent database sessions and a controlled Production functional smoke verification is authorized/executed.
