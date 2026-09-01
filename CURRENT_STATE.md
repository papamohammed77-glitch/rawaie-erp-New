# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- Operational truth: current Git `main` HEAD, Production Supabase, deployed Edge Functions, and qualifying runtime evidence.
- Historical reports/prompts are evidence only and must not override direct source/DB facts.
- Authorized product target: `Current/PWA/New-main`.
- `Current/PWA/main.html` is protected.
- Browser E2E is **temporarily paused by explicit P124 directive**. It is not a PASS and must not be represented as one.
- No reconstruction of MAIN1→MAIN11, no source-copy rewrite, no overlay-based closure, and no speculative production mutation are authorized.

## LAST VERIFIED EVENT
### P124-009 — SURGICAL TARGET AUDIT / NO-BROWSER MODE
- Directly re-read the P124 memory-recovery pack, CURRENT_STATE, and Hany 7 before acting.
- Confirmed the prior operational chain and rejected report-only conclusions where direct evidence differed.
- `Current/PWA/New-main` contains the MAIN1 shell/runtime contracts, tenant context, owner/license surface, permissions, navigation, data, audit, workflow, notification, PWA lifecycle, and delegated specialized applications.
- Critical notification functions are present: `_renderAndSave`, `_updateBadge`, `markRead`, `_clickNotif`.
- Current/Original MAIN1 both contain the same core notification contract and workflow bootstrap surface.
- `New-main` contains multiple historical namespace redefinitions/compatibility layers; this is a maintainability and determinism risk, but no destructive rewrite was performed in this pass because a full behavioral replacement is not justified without runtime proof.

## VERIFIED PRODUCTION ARCHITECTURE
- PostgreSQL contains `post_stock_movement`, `reserve_stock`, and `post_journal_entry` as `SECURITY DEFINER` functions.
- `post_stock_movement` is the canonical stock-changing engine: validates movement type/quantity, enforces company ownership of source/target branches, locks stock rows, mutates `stock_branches`, records `inventory_log`, and supports idempotency keys.
- Major operational tables are RLS-enabled.
- Workflow/notification policies were hardened to remove broad anonymous/public mutation access while preserving authenticated reads where required.
- Relevant production Edge Functions are JWT-protected (`verify_jwt=true`).
- `save-customer` derives `company_id` from authenticated Auth identity.
- `log-action` derives the audit user from the authenticated token and writes audit data through the server-side client.
- Production `save-item` uses the hardened atomic opening-stock path described in prior verified state.

## PROVEN CODE GAP IDENTIFIED AND REPAIRED IN PIPELINE
### Bulk Stock Adjustment Contract Drift
- The New-main bulk-upload UI previously mapped barcode → `item_code` but omitted `item_id` from the upload record sent to `bulk-stock-adjustment`.
- Production `bulk-stock-adjustment` requires a valid `item_id`/resolved item identity.
- The authoritative surgical verifier was extended to map `mappedItem.id` into `_uploadFileData[f].item_id` and include `item_id` in the final payload.
- Runner evidence proved the surgical transformation executes successfully in a clean runner and generated target SHA `612c7cb3323b0be6a767781388cd746ac27af8c06ffe31203650393f2b5e470d` in the runner working copy.
- The same target mutation has **not yet been independently proven persisted to `main`**; do not mark the product artifact closed on this item until its Git blob reflects the repaired payload.

## VERIFIER FORENSIC FIXES
- The original structural gate incorrectly treated `</script>` strings embedded inside generated JavaScript HTML as document terminators.
- The verifier was changed to locate the single actual inline script using the first inline `<script>` and the final `</script>` boundary, then validate the surrounding document markup.
- The verifier now explicitly forbids direct `stock_branches` writers inside New-main.
- Browser E2E is intentionally absent from the surgical verification pipeline for this P124 pass.

## EXTERNAL / HISTORICAL ARCHITECTURE CROSS-CHECK
- Odoo's inventory model is document/movement oriented: inventory adjustments are represented as stock movements rather than arbitrary direct balance edits.
- SAP S/4HANA likewise follows a document principle for stock-changing transactions, with material documents and accounting documents where financially relevant.
- This validates the project's canonical `post_stock_movement` direction and the decision to eliminate secondary physical-stock writers.

## KNOWN CURRENT BLOCKERS
- The exact repaired `New-main` blob containing the bulk-upload `item_id` correction is not yet directly proven on `main`.
- The current Actions interface exposes reliable PR-triggered runs, but push-run visibility is limited; therefore a GitHub Actions run is not assumed merely because a push-triggered workflow exists.
- Authenticated Owner/Non-Owner browser execution, tenant-boundary E2E, Service Worker runtime, and final Git→Production lineage remain unproven because Browser E2E is paused by directive.
- Some legacy reconstruction/forensic workflows continue to exist and may fail independently; they are not authoritative for this target unless their evidence directly concerns `Current/PWA/New-main`.

## DO-NOT-REPEAT
- Do not treat CI workflow definition as proof of application execution.
- Do not treat a runner working-copy SHA as a persisted Git artifact SHA.
- Do not reconstruct MAIN1→MAIN11.
- Do not rewrite New-main from historical snapshots.
- Do not use markers/labels/metadata as substitutes for behavioral closure.
- Do not introduce a second stock writer.
- Do not claim `Closed 100% / GOLD / DIAMOND / COMPLETE` while the repaired target persistence or any required evidence gate is still unproven.
- Do not resume Browser E2E during this temporary P124 pause.

## CLOSURE MATRIX
| Gate | Status |
|---|---|
| Memory/governance recovery | PASS |
| CURRENT_STATE reconciliation | PASS |
| MAIN1 Original/Current mapping | PASS |
| MAIN1 → New-main static contract presence | PASS |
| Canonical stock authority in Production | PASS |
| Atomic opening-stock architecture in Production | PASS |
| Production RLS hardening | PASS |
| Bulk-upload item identity drift identified | PASS — gap proven |
| Bulk-upload surgical repair generated by verifier | PASS — runner evidence |
| Bulk-upload repair persisted to `main` target blob | PENDING |
| Verifier parser corrected | PASS |
| Browser E2E | PAUSED BY DIRECTIVE |
| Authenticated Owner E2E | PAUSED / UNPROVEN |
| Authenticated Non-Owner E2E | PAUSED / UNPROVEN |
| Tenant-isolation E2E | PAUSED / UNPROVEN |
| Service Worker runtime | PAUSED / UNPROVEN |
| Git→Production source lineage | PENDING |
| GOLD / DIAMOND / COMPLETE | NOT AUTHORIZED |

## NEXT AUTHORIZED ACTION
`P124-010 — VERIFY_TARGET_PERSISTENCE_AND_SURGICAL_COMPLETION`
- Directly inspect `Current/PWA/New-main` on current `main`.
- Confirm whether the bulk-upload `item_id` repair is present in the Git blob.
- If absent, persist only that surgical change; then re-run the non-browser static verifier.
- Verify no direct stock writer exists in the final target.
- Reconcile the final target SHA with this file before any closure label.
- Browser E2E remains paused until explicitly re-authorized.
