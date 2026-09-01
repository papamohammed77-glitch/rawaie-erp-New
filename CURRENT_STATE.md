# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- Operational truth: current Git main HEAD, Production Supabase, deployed Edge Functions, and qualifying runtime evidence.
- Historical reports and prior assistant conclusions are leads only.
- Authorized target: `Current/PWA/New-main`.
- `Current/PWA/main.html` is protected.
- Prompt 124 governs this continuation: no reconstruction, no overlay, no speculative production mutation, and no closure without direct evidence.

## LAST VERIFIED EVENT
### P124-008 — TARGET-ONLY RUNTIME VERIFIER / FINAL FORENSIC STATE
- Current `main` HEAD directly verified as `6635544af89978b977d90573f18f95aad48b6d59`.
- Current target `Current/PWA/New-main` directly inspected at that HEAD. Its MAIN1 shell, authentication/session, tenant context, owner/license, permissions, navigation, data, audit, workflow, notification, PWA lifecycle and delegated application surfaces are present.
- Required notification functions `_renderAndSave`, `_updateBadge`, `markRead`, `_clickNotif` are present.
- No evidence-backed missing MAIN1 contract was identified by direct static reconciliation.
- The old mutating reconstruction workflow was replaced with a read-only exact-target runtime verifier; it no longer rewrites `New-main`, injects closure overlays, or changes production state.

## PRODUCTION VERIFIED
- PostgreSQL contains `post_stock_movement`, `reserve_stock`, and `post_journal_entry` as SECURITY DEFINER functions.
- Major operational tables are RLS-enabled.
- `save-customer` is ACTIVE with `verify_jwt=true` and derives `company_id` from authenticated identity.
- `log-action` is ACTIVE with `verify_jwt=true`.
- `save-item` is ACTIVE with JWT verification and uses the atomic opening-stock owner `create_item_with_opening_stock`, which routes opening stock through `post_stock_movement('InventoryIncrease', ...)` with idempotency.
- Workflow/notification RLS was hardened to remove broad anonymous/public access while preserving authenticated runtime behavior.

## RUNTIME VERIFICATION FINDINGS
- A prior verifier run failed on a verifier-only defect (`DOCUMENT_TAIL_INVALID`); this was not evidence of an application failure.
- The verifier was corrected to inspect multiple inline scripts and proper document closure without altering the target.
- The repository now contains a read-only Playwright verifier that checks the exact checked-out `New-main` artifact, JavaScript syntax, critical DOM, route surface, notification contract, owner-denial behavior at the navigation layer, and legacy `main.html` integrity.
- However, no qualifying current GitHub Actions Run tied to the present HEAD has been obtained through the available Actions interface, and no authenticated Owner/Non-Owner browser session is available in this execution context.
- Therefore authenticated E2E, tenant-boundary E2E, runtime Service Worker success, and final production/browser correlation remain **unproven evidence gates**. They are not application defects by themselves and must not be relabeled as PASS.

## IMPORTANT LINEAGE FACT
- Production `save-item` is presently at the hardened atomic implementation path, but the exact deployed source lineage back to the canonical Git Edge Function source file has not been independently proven in this execution context.
- No surrogate source file has been invented.

## CLOSURE MATRIX
| Gate | Status |
|---|---|
| Prompt 124 memory/governance recovery | PASS |
| Current-state reconciliation | PASS |
| Latest main HEAD identity | PASS |
| MAIN1 Original/Current mapping | PASS |
| MAIN1 → New-main static mapping | PASS |
| Main1 tenant/owner/notification contract presence | PASS |
| Canonical stock authority | PASS |
| Atomic opening-stock owner | PASS |
| Production RLS hardening | PASS |
| Read-only exact-target verifier | PASS |
| Exact current-artifact JavaScript/browser execution result | PENDING — no qualifying current run available |
| Authenticated Owner E2E | PENDING |
| Authenticated Non-Owner E2E | PENDING |
| Tenant isolation E2E | PENDING |
| License route/render E2E | PENDING |
| Notification behavioral E2E | PENDING |
| Audit/logout/fail-closed E2E | PENDING |
| Service Worker runtime | PENDING |
| Git→Production save-item source lineage | PENDING |
| GOLD / DIAMOND / COMPLETE | NOT AUTHORIZED |

## DO-NOT-REPEAT
- Do not reconstruct MAIN1→MAIN11.
- Do not rewrite `New-main` from Historical/Original snapshots.
- Do not inject markers/overlays to simulate closure.
- Do not mutate Production to manufacture test evidence.
- Do not treat a static verifier, CI configuration, Git commit, or Supabase function hash as authenticated browser PASS.
- Do not claim `Closed 100%` while any required runtime gate remains unproven.

## NEXT AUTHORIZED ACTION
`P124-009 — QUALIFIED_AUTHENTICATED_E2E_AND_LINEAGE`
- Run the existing read-only verifier against the exact current `main` target and capture the real job/log evidence.
- Reuse an authorized authenticated browser path with real Owner and Non-Owner test identities; do not simulate those identities by mutating `RW_STATE`.
- Verify tenant boundary, license, notifications, audit/logout/fail-closed, network/console and Service Worker behavior.
- Reconcile the deployed `save-item` source with the canonical Git source.
- Only then promote the state to `CLOSED 100% / GOLD / DIAMOND / COMPLETE`.
