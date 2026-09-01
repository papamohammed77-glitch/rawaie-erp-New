# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- Operational truth: current Git `main` HEAD, Production Supabase, deployed Edge Functions, and qualifying runtime evidence.
- Historical reports/prompts are evidence only; direct Git/DB/Deployment facts override them.
- Authorized product target: `Current/PWA/New-main`.
- `Current/PWA/main.html` is protected.
- Browser E2E is PAUSED by explicit user directive and is not a PASS or FAIL in this round.
- Field/production trial is deferred until the target artifact is fully reconciled.
- No reconstruction of MAIN1→MAIN11, no source-copy rewrite, no overlay-based closure, and no speculative production mutation are authorized.

## LAST VERIFIED EVENT
### P124-014 — OFFICIAL SURGICAL GATE RETRIGGER
- Direct source/Production review identified the unresolved target defect: bulk stock upload must propagate canonical `item_id` from the resolved item row into the bulk adjustment payload.
- Historical persistence attempts were proven to stop before product mutation because of executor syntax failure and validator false-positive behavior; they are retained as forensic failure causes only.
- The current official `forensic-pwa-closure.yml` is the authorized persistence path and explicitly does not run Browser E2E in this round.
- Production confirms `post_stock_movement` as the canonical Physical Stock writer and the bulk-adjustment contract as item-identity based.
- Production CRUD/Audit functions are JWT-protected and derive tenant context from authenticated `users.company_id`.

## EXECUTION STATUS
`P124-014` has been retriggered. The authoritative next fact is the Git blob of `Current/PWA/New-main`, not a runner working copy.

## ACCEPTANCE CRITERIA
1. `mappedItem.id` is retained as `_uploadFileData[f].item_id`.
2. Bulk adjustment payload sends canonical `item_id` and retains `item_code` for compatibility.
3. No direct `stock_branches` DML exists in New-main.
4. MAIN1 required contracts remain present.
5. JavaScript syntax and document closure pass.
6. `Current/PWA/main.html` checksum remains unchanged.
7. Browser E2E remains paused.

## CURRENT BLOCKERS
- Final target blob SHA and exact surgical diff are pending direct verification after the retrigger.
- Browser/field/runtime gates remain intentionally deferred.

## DO-NOT-REPEAT
- Do not equate trigger with persistence.
- Do not equate runner SHA with Git blob SHA.
- Do not reconstruct MAIN1→MAIN11.
- Do not introduce a second Physical Stock writer.
- Do not claim GOLD/DIAMOND/COMPLETE without exact evidence.

## CLOSURE MATRIX
| Gate | Status |
|---|---|
| Master continuity/governance | PASS |
| MAIN1 mapping | PASS |
| Production stock engine | PASS |
| Production JWT/RLS baseline | PASS |
| Bulk upload target repair | PENDING |
| Final New-main syntax | PENDING |
| Final document closure | PENDING |
| Legacy main.html integrity | PENDING |
| Browser E2E | PAUSED BY DIRECTIVE |
| Field trial | DEFERRED |
| GOLD / DIAMOND / COMPLETE | NOT YET AUTHORIZED |

## NEXT AUTHORIZED ACTION
`P124-015 — DIRECT_GIT_BLOB_VERIFICATION`
