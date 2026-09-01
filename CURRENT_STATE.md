# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- Operational truth: current Git `main` HEAD, Production Supabase, deployed Edge Functions, and qualifying runtime evidence.
- Historical reports/prompts are evidence only; direct Git/DB/Deployment facts override them.
- Authorized product target: `Current/PWA/New-main`.
- `Current/PWA/main.html` is protected.
- Browser E2E is temporarily paused by explicit P124 directive. It is NOT a PASS.
- No reconstruction of MAIN1→MAIN11, no source-copy rewrite, no overlay-based closure, and no speculative production mutation are authorized.

## LAST VERIFIED EVENT
### P124-012 — SURGICAL PERSISTENCE RETRIGGER
- Direct reconciliation of the current P124 state completed from Git, Supabase Production, active Edge Functions, and the latest Hany execution report.
- Latest Hany report confirmed the historical blocker: the bulk-upload `item_id` repair had not yet been proven in the final `Current/PWA/New-main` Git blob at that time.
- Current Git `New-main` search/history still exposed the legacy upload mapping/payload form in the target lineage, so the existing P124 surgical persistence gate is the authorized mechanism to persist only the two-line repair.
- Production `bulk-stock-adjustment` requires canonical `item_id`; `post_stock_movement` remains the canonical Physical Stock engine.
- Production `save-item` is currently ACTIVE v12 and uses `create_item_with_opening_stock`; no direct opening-stock upsert is present in the current published function.
- Production Workflow/Notification public `ALL` access was removed previously; current policy model is restricted to authenticated use as required by the P124 contract.
- Browser E2E remains intentionally paused.

## ACTIVE P124 GATE
- Existing workflow: `.github/workflows/forensic-pwa-closure.yml`.
- The workflow is explicitly Browser-E2E-paused and triggered by `P124 surgical` commit messages.
- Its sole permitted product mutation is the canonical `item_id` repair inside `Current/PWA/New-main`.
- It validates document closure, one inline runtime script, Node syntax, required MAIN1 contracts, and absence of direct `stock_branches` DML.
- It must never modify `Current/PWA/main.html`.

## CURRENT BLOCKERS
- Awaiting/inspecting the action run produced by this trigger and direct inspection of the resulting New-main blob.
- Browser E2E, Owner/Non-Owner E2E, tenant-boundary E2E, Service Worker runtime verification, and final Git→Production source-lineage verification remain deferred/unproven by explicit user directive.
- Legacy workflows may still fail independently; they are not authoritative for P124 unless their evidence directly concerns the target artifact.

## DO-NOT-REPEAT
- Do not treat workflow existence as execution proof.
- Do not treat a runner working-copy SHA as a Git blob SHA.
- Do not introduce closure overlays or duplicate authoritative modules.
- Do not reconstruct MAIN1→MAIN11.
- Do not add a second physical-stock writer.
- Do not claim GOLD/DIAMOND/COMPLETE until the final non-browser gates are actually proven.
- Do not resume Browser E2E during this pause.

## CLOSURE MATRIX
| Gate | Status |
|---|---|
| Master continuity/governance | PASS |
| MAIN1 source mapping | PASS |
| MAIN1 static contract presence | PASS |
| Production canonical stock engine | PASS |
| Production bulk-adjustment contract | PASS |
| Production save-item opening-stock architecture | PASS — current v12 uses RPC |
| Workflow/Notification RLS hardening | PASS — public write access removed |
| P124 surgical persistence gate | TRIGGERED — awaiting result |
| Bulk-upload target repair persisted in final blob | PENDING |
| Final non-browser target verification | PENDING |
| Browser E2E | PAUSED BY DIRECTIVE |
| Owner/Non-Owner E2E | PAUSED / UNPROVEN |
| Tenant-isolation E2E | PAUSED / UNPROVEN |
| Service Worker runtime | PAUSED / UNPROVEN |
| Git→Production source lineage | PENDING |
| GOLD / DIAMOND / COMPLETE | NOT YET AUTHORIZED |

## NEXT AUTHORIZED ACTION
`P124-013 — VERIFY_SURGICAL_GATE_RESULT_AND_FINAL_NEW_MAIN_BLOB`
- Inspect the workflow result created by this trigger.
- Inspect the exact post-run `Current/PWA/New-main` Git blob.
- Confirm the two `item_id` changes are present and no other target mutation occurred.
- If the target blob is correct, run the non-browser static/architectural closure checks and update this ledger with exact evidence.
