# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- Operational truth: current Git `main` HEAD, Production Supabase, deployed Edge Functions, and qualifying runtime evidence.
- Historical reports/prompts are evidence only; direct Git/DB/Deployment facts override them.
- Authorized product target: `Current/PWA/New-main`.
- `Current/PWA/main.html` is protected and must remain byte-identical during target operations.
- Browser E2E is temporarily PAUSED by explicit user directive. It is neither PASS nor FAIL in this round.
- Field/production trial is deferred until the target artifact is fully reconciled.
- No reconstruction of MAIN1→MAIN11, no source-copy rewrite, no overlay-based closure, and no speculative production mutation are authorized.

## LAST VERIFIED EVENT
### P124-013 — CLEAN-ROOM TRIGGER AND FINAL-ARTIFACT RECOVERY
- The latest Hany report was read directly; it correctly identified the unresolved blocker: the bulk-upload `item_id` repair had not been proven in the final `Current/PWA/New-main` Git blob.
- Direct Production inspection confirmed `bulk-stock-adjustment` expects canonical item identity and that `post_stock_movement` is the canonical Physical Stock engine.
- Direct Production inspection confirmed the main CRUD/Audit Edge Functions are JWT-protected and derive tenant context from authenticated `users.company_id`.
- Direct Production inspection confirmed the canonical stock RPC family (`post_stock_movement`, `reserve_stock`, `post_journal_entry`) is present and `SECURITY DEFINER`.
- Direct Production inspection confirmed sensitive tables have RLS enabled. Previous public `ALL` policies on workflow/notification infrastructure were hardened; authenticated operational access remains.
- The critical product defect remains localized to `Current/PWA/New-main` bulk stock upload identity propagation: barcode/item lookup must retain `mappedItem.id` as `item_id`, and the bulk adjustment payload must send `item_id` as canonical identity while retaining `item_code` for compatibility/display.
- Previous persistence attempts failed before product mutation because the clean-room executor had an `IndentationError`, then its validator produced a false `INLINE_SCRIPT_COUNT_INVALID` because it counted literal `<script>` strings inside JavaScript. These are now understood failure modes and the validator logic was corrected to locate the actual body inline script.
- The official P124 gate is the controlled persistence path. Browser E2E remains paused and is not used as a closure condition in this round.

## ACTIVE EXECUTION
`P124-014 — VERIFY_OFFICIAL_SURGICAL_GATE_AND_TARGET_BLOB`

Expected official gate behavior:
1. Read current `Current/PWA/New-main`.
2. Apply only the two canonical `item_id` propagation changes when absent.
3. Reject any direct `stock_branches` writer inside New-main.
4. Validate document closure and JavaScript syntax.
5. Preserve `Current/PWA/main.html` checksum.
6. Commit/push only `Current/PWA/New-main` when a real target delta exists.
7. Do not run Browser E2E.

## TARGET ACCEPTANCE CRITERIA
- `Current/PWA/New-main` contains the exact `item_id` mapping and payload repair.
- The final Git blob differs from the pre-repair blob only by the intended surgical product change(s).
- Main1 required contracts remain present.
- No direct `stock_branches` DML appears in New-main.
- JavaScript syntax gate passes.
- HTML/body closure gate passes.
- `Current/PWA/main.html` checksum is unchanged.
- Production canonical stock architecture remains authoritative.

## CURRENT BLOCKERS
- Final post-trigger target blob SHA still needs direct verification.
- Final non-browser closure matrix remains pending until that blob is verified.
- Browser E2E, Owner/Non-Owner E2E, tenant-boundary E2E, Service Worker runtime verification, field trial, and Git→Production source-lineage verification remain intentionally deferred/unproven.

## DO-NOT-REPEAT
- Do not treat a workflow trigger as a successful target mutation.
- Do not treat a runner working-copy SHA as the Git blob SHA.
- Do not treat CI/static output as Browser/Production proof.
- Do not reconstruct or regenerate New-main from MAIN1→MAIN11.
- Do not introduce a second Physical Stock writer.
- Do not add closure overlays or marker objects as evidence of behavior.
- Do not resume Browser E2E during this pause.
- Do not claim GOLD/DIAMOND/COMPLETE until the stated acceptance criteria are actually evidenced.

## CLOSURE MATRIX
| Gate | Status |
|---|---|
| Master continuity/governance | PASS |
| MAIN1 source mapping | PASS |
| MAIN1 static contract presence | PASS |
| Production canonical stock engine | PASS |
| Production bulk-adjustment identity contract | PASS |
| Production save-item opening-stock architecture | PASS — current deployed version uses RPC path |
| Workflow/Notification RLS hardening | PASS |
| Bulk-upload target repair in final blob | PENDING — this execution targets it |
| Final target JS syntax | PENDING |
| Final target document closure | PENDING |
| No direct stock writer in target | PENDING |
| Legacy `main.html` integrity | PENDING |
| Browser E2E | PAUSED BY DIRECTIVE |
| Owner/Non-Owner E2E | PAUSED / UNPROVEN |
| Tenant-isolation E2E | PAUSED / UNPROVEN |
| Service Worker runtime | PAUSED / UNPROVEN |
| Field trial | DEFERRED |
| Git→Production source lineage | PENDING |
| GOLD / DIAMOND / COMPLETE | NOT YET AUTHORIZED |

## NEXT AUTHORIZED ACTION
`P124-015 — DIRECTLY_VERIFY_FINAL_NEW_MAIN_BLOB`
- Verify the exact post-gate `Current/PWA/New-main` blob.
- Record the exact Git SHA and the exact surgical diff.
- If correct, mark the non-browser product gates closed and produce Hany's final forensic report.
- Keep Browser E2E and field trial deferred until explicit reactivation.
