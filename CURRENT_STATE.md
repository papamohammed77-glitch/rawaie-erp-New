# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- Operational truth: current Git `main` HEAD, Production Supabase, deployed Edge Functions, and qualifying runtime evidence.
- Historical reports/prompts are evidence only; direct Git/DB/Deployment facts override them.
- Authorized product target: `Current/PWA/New-main`.
- `Current/PWA/main.html` is protected.
- Browser E2E is temporarily paused by explicit P124 directive. It is NOT a PASS.
- No reconstruction of MAIN1→MAIN11, no source-copy rewrite, no overlay-based closure, and no speculative production mutation are authorized.

## LAST VERIFIED EVENT
### P124-011 — ACTIVE TARGET GATE TRIGGERED
- P124 continuity/governance and direct-source reconciliation completed.
- MAIN1 Original/Current contract mapping to New-main is complete; no evidence-backed missing MAIN1 contract remains.
- Production `bulk-stock-adjustment` requires canonical `item_id` and delegates atomically to `post_inventory_adjustment_atomic`.
- The exact published New-main defect is the missing `item_id` in bulk-upload mapping/payload.
- Production `save-item` is currently ACTIVE version 12 and uses the database RPC `create_item_with_opening_stock` for new items/opening stock; no direct opening-stock upsert is present in the current published function.
- Canonical `post_stock_movement` remains present as SECURITY DEFINER and is the established physical-stock authority for movement transactions.
- Browser E2E remains intentionally paused.

## ACTIVE P124 GATE
- Existing active push workflow was converted from legacy Overlay/Browser behavior to a P124 surgical target-only gate.
- It is intentionally restricted to commit messages containing `P124 surgical persist`.
- Its only product mutation is the two-line bulk-upload item identity repair in `Current/PWA/New-main`.
- It validates document closure, single inline runtime script, Node syntax, MAIN1 contract markers, and absence of direct `stock_branches` DML.
- It must never mutate `Current/PWA/main.html`.

## CURRENT BLOCKERS
- Awaiting the action run produced by this trigger and direct inspection of the resulting New-main blob.
- Browser E2E, Owner/Non-Owner E2E, tenant-boundary E2E, Service Worker runtime verification, and final Git→Production lineage remain deferred/unproven by explicit user directive.
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
| Active P124 surgical gate | TRIGGERED |
| Bulk-upload target repair persisted | PENDING |
| Final non-browser target verification | PENDING |
| Browser E2E | PAUSED BY DIRECTIVE |
| Owner/Non-Owner E2E | PAUSED / UNPROVEN |
| Tenant-isolation E2E | PAUSED / UNPROVEN |
| Service Worker runtime | PAUSED / UNPROVEN |
| Git→Production source lineage | PENDING |
| GOLD / DIAMOND / COMPLETE | NOT YET AUTHORIZED |

## NEXT AUTHORIZED ACTION
`P124-012 — READ ACTIVE GATE RESULT AND VERIFY EXACT TARGET BLOB`
- Read the workflow run for commit `P124 surgical persist: trigger active target gate`.
- Inspect `Current/PWA/New-main` after the run.
- Confirm the two item_id changes exist and are the only target mutation.
- Record exact target SHA and gate evidence here.