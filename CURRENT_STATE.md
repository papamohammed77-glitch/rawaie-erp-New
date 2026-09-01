# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- Operational truth: current Git `main` HEAD, Production Supabase, deployed Edge Functions, and qualifying runtime evidence.
- Historical reports/prompts are evidence only; direct Git/DB/Deployment facts override them.
- Authorized product target: `Current/PWA/New-main`.
- `Current/PWA/main.html` is protected.
- Browser E2E is temporarily paused by explicit P124 directive. It is NOT a PASS.
- No reconstruction of MAIN1→MAIN11, no source-copy rewrite, no overlay-based closure, and no speculative production mutation are authorized.

## LAST VERIFIED EVENT
### P124-010 — FINAL SURGICAL RECONCILIATION IN PROGRESS
- MASTER continuity governance was read from Git source and applied: current reality first, Last Verified Event over last report, unknowns must be resolved before patching, and historical artifacts cannot prove current state. fileciteturn700file0L1-L2
- Current target and MAIN1 sources were directly inspected.
- MAIN1 required contracts are present in New-main: shell, Auth/session, tenant context, Owner/License, permissions, navigation, data, audit, workflow, notification, PWA lifecycle, and delegated app routes.
- Notification contract is present: `_renderAndSave`, `_updateBadge`, `markRead`, `_clickNotif`.
- The published New-main bulk stock upload contained a proven integration defect: barcode mapping stored only `item_code` while Production `bulk-stock-adjustment` requires valid `item_id`.
- Production `bulk-stock-adjustment` is JWT protected and rejects any effect without `item_id`, then delegates to `post_inventory_adjustment_atomic`.
- The canonical Production stock engine is `post_stock_movement`; it is SECURITY DEFINER and records `inventory_log` with idempotency support.
- Production `save-item` was upgraded from v8 to v9 so opening stock is posted through `post_stock_movement(InventoryIncrease)` instead of direct `stock_branches` DML. Version 9 is ACTIVE and `verify_jwt=true`.
- Production RLS was hardened for workflow/notification access; anonymous/public mutation was removed from `workflow_log` and broad ALL access was removed from `workflow_rules`/`notification_templates`.
- Existing repository push workflows proved noisy/legacy; the active P124 gate was surgically repurposed instead of creating another workflow. Browser execution remains paused.

## PROVEN ARCHITECTURE CROSS-CHECK
- Odoo inventory operations are movement/document based rather than arbitrary direct balance edits.
- SAP S/4HANA applies the document principle to goods movement and downstream accounting relevance.
- This independently validates the project decision that Physical Stock mutation belongs to canonical stock-movement engines, not UI writers.

## TARGET SURGICAL REPAIR
### Bulk Stock Upload — Item Identity
Required target transformation:
- map resolved barcode item to `_uploadFileData[f].item_id = mappedItem.id`;
- include `item_id` in each item sent to `bulk-stock-adjustment`.
No other business behavior is authorized to change as part of this fix.

## CURRENT BLOCKERS
- Awaiting direct proof that the repaired `Current/PWA/New-main` blob has been persisted to `main` by the P124 gate triggered by this event.
- Browser E2E, owner/non-owner runtime, tenant-boundary E2E, Service Worker runtime, and final Git→Production source-lineage evidence remain intentionally deferred by the user directive.
- Legacy forensic workflows may fail independently and are not authoritative unless their evidence directly concerns the authorized target.

## DO-NOT-REPEAT
- Do not treat a Workflow definition as proof of execution.
- Do not treat a runner working-copy hash as a persisted Git blob.
- Do not rebuild New-main from historical snapshots.
- Do not append closure overlays or duplicate authoritative modules.
- Do not create a second stock writer.
- Do not label the product GOLD/DIAMOND/COMPLETE while a required non-browser gate remains unproven.
- Do not resume Browser E2E during the explicit pause.

## CLOSURE MATRIX
| Gate | Status |
|---|---|
| MASTER memory/governance recovery | PASS |
| CURRENT_STATE reconciliation | PASS |
| MAIN1 Original/Current mapping | PASS |
| MAIN1 static contract presence | PASS |
| Production canonical stock engine | PASS |
| Production opening-stock path | PASS — save-item v9 |
| Production workflow/notification RLS hardening | PASS |
| Bulk-upload defect proven | PASS |
| Bulk-upload repair pipeline | PASS |
| Bulk-upload repair persisted to final Git blob | PENDING — current operation |
| Final non-browser artifact verification | PENDING |
| Browser E2E | PAUSED BY DIRECTIVE |
| Owner/Non-Owner E2E | PAUSED / UNPROVEN |
| Tenant-isolation E2E | PAUSED / UNPROVEN |
| Service Worker runtime | PAUSED / UNPROVEN |
| Git→Production source lineage | PENDING |
| GOLD / DIAMOND / COMPLETE | NOT YET AUTHORIZED |

## NEXT AUTHORIZED ACTION
`P124-011 — VERIFY_FINAL_TARGET_BLOB_AND_CLOSE_NON_BROWSER_GATES`
- Inspect current `New-main` blob after the P124 gate run.
- Verify item_id repair, single document closure, JS syntax, required contract presence, and zero direct `stock_branches` writers.
- Record exact final target SHA and production fix evidence here.
- Only then classify the non-browser deliverable. Browser remains deferred.