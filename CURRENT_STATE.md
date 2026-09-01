# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- Operational truth: current Git main HEAD, Production Supabase, deployed Edge Functions, and runtime verification.
- Historical reports/prompts are evidence only.
- Authorized target: `Current/PWA/New-main`.
- `Current/PWA/main.html` is protected.
- Prompt 123 forbids reconstruction, overlay, new workflow, new file, or speculative production mutation.

## LAST VERIFIED EVENT
### P123-007 — PRODUCTION_STOCK_AUTHORITY_AND_ATOMIC_ITEM_CREATION
- Static MAIN1 contract mapping remains complete; no evidence-backed missing MAIN1 contract was identified in `Current/PWA/New-main`.
- Production `save-item` v8 was found to write opening stock directly into `stock_branches`, creating a second physical-stock write path outside canonical `post_stock_movement`.
- Production `save-item` v9 first corrected that path to call `post_stock_movement(InventoryIncrease)` with an idempotency key; `verify_jwt=true` remained enabled.
- A deeper atomicity review identified that item creation and the subsequent stock call were still separate network/database operations. A PostgreSQL `SECURITY DEFINER` function `create_item_with_opening_stock(uuid,jsonb,uuid,numeric,text)` was therefore added. It creates the item and, when requested, posts `InventoryIncrease` through canonical `post_stock_movement` in one database transaction.
- Public EXECUTE on the new RPC was revoked; EXECUTE was granted only to `service_role`. Verification: `security_definer=true`, `public_exec=false`, `service_role_exec=true`.
- A first v10 Edge deployment was immediately identified as non-atomic because it created then deleted an item when opening stock was present. It was not accepted as final and was superseded without leaving the test item in production.
- `save-item` v11 is the accepted deployment. It validates Auth/tenant context, resolves the opening branch before mutation, then performs exactly one RPC call for creation. It has `verify_jwt=true` and no direct `stock_branches` write in the published creation path.
- Transaction rollback test executed in Production database context using a dedicated synthetic item name inside an explicit transaction. The RPC returned success and `opening_balance_posted=true`, then the transaction was rolled back. Follow-up verification found `0` test items and `0` test inventory logs, proving rollback semantics and absence of residual test data.
- Production Edge Function inventory confirms core functions are active; `save-item` is active at version 11, `save-customer` version 3, and `log-action` version 2, all with JWT verification enabled.
- Production `save-customer` derives `company_id` from authenticated user context and scopes writes by company; `log-action` is JWT-protected and records authenticated identity data.
- Production security hardening from P123-006 remains active: workflow/notification public `ALL` policies were removed and replaced with authenticated-only rules.
- No user/business production data was intentionally created or retained by the verification tests.

## RECONCILIATION HISTORY
### P123-001 — STATE_RECONCILIATION
- Recorded in commit `e9fd4f819a384b29063d3918723f512da10ed50e`.
### P123-002 — TARGET_FREEZE_AND_IDENTITY_VERIFICATION
- Frozen target: `d657d6e4bdd90a9b60f658a8bf28560e1b10f755`.
- Frozen Current MAIN1: `de3ea2f6c1c638447d1c34c8f6237e14d5ae3b59`.
- Frozen Original MAIN1: `14b12a471c20ad23a2c18f456dbc4d59783a0d1f`.
### P123-003 — MAIN1_ORIGINAL_ANALYSIS
- Original MAIN1 contract set extracted.
### P123-004 — MAIN1_CURRENT_ANALYSIS
- Current MAIN1 classified as hardened/adapted Original.
### P123-005 — NEW_MAIN_MAPPING_AND_GAP_CLASSIFICATION
- All required MAIN1 contracts found in target; no evidence-backed missing contract.
### P123-006 — EXECUTABLE_VERIFICATION_AND_PRODUCTION_RLS_HARDENING
- Production RLS hardening applied and verified.
### P123-007 — PRODUCTION_STOCK_AUTHORITY_AND_ATOMIC_ITEM_CREATION
- Production stock write path hardened and rollback-tested as recorded above.

## TARGET FREEZE
- Baseline target SHA: `d657d6e4bdd90a9b60f658a8bf28560e1b10f755`.
- `Current/PWA/New-main` was not modified by P123-006 or P123-007; its exact frozen artifact SHA therefore remains unchanged.
- Any future target SHA change must be treated as a new surgical mutation and re-verified.

## VERIFIED PRODUCTION FACTS
- Critical MAIN1-sensitive tables have RLS enabled.
- `post_stock_movement`, `reserve_stock`, and `post_journal_entry` exist as `SECURITY DEFINER` functions.
- `post_stock_movement` supports `InventoryIncrease` and idempotency.
- `create_item_with_opening_stock` is `SECURITY DEFINER` and inaccessible to `public`.
- Active workflow rules: 3. Active notification templates: 4. Existing workflow log rows: 0. Existing notification rows: 0. Existing audit log rows: 1866 at verification time.

## ROOT-CAUSE STUDY — WHY PRIOR EXECUTION LOOPED
1. Stale `CURRENT_STATE.md` allowed assistants to start from an obsolete snapshot.
2. Scope drift turned a MAIN1 reconciliation into reconstruction/cross-cutting work.
3. Overlay contracts and labels were sometimes mistaken for behavioral parity.
4. Forensic workflows/validators were modified enough to become variables in the investigation.
5. Git commit success, CI success, browser success, and production success were not kept as independent evidence classes.
6. The original forensic protocol lacked a hard requirement that every claim carry a current artifact/evidence identity.
7. The project has multiple historical layers and duplicate module definitions, making “last definition wins” behavior easy to confuse with intentional architecture.
8. A previously overlooked production dependency demonstrated that static parity alone is insufficient: `save-item` could bypass the canonical stock engine even though MAIN1 contract names were present.

## ENGINEERING RESPONSE
- Deterministic state reconciliation is mandatory before each new mutation.
- MAIN1 scope is preserved: only direct blockers are changed.
- Physical stock authority is centralized through `post_stock_movement`.
- Opening stock is now transactionally coupled to item creation.
- Security is enforced at database policy and Edge Function layers, not UI labels alone.
- Browser/runtime evidence remains an independent gate.

## FAILED ATTEMPTS / DO-NOT-REPEAT
- Do not reconstruct MAIN1→MAIN11.
- Do not rebuild or rewrite New-main.
- Do not copy Original/Current MAIN1 into New-main.
- Do not add closure markers as a substitute for behavior.
- Do not modify forensic workflows merely to force green.
- Do not deploy a multi-step item+stock mutation where a single transaction is required.
- Do not equate CI PASS with Browser PASS or Production PASS.
- Do not declare GOLD/DIAMOND/COMPLETE while exact browser runtime evidence is absent.

## CLOSURE STATUS
- `STATIC_MAIN1_CONTRACT`: PASS
- `PRODUCTION_SECURITY`: PASS
- `PRODUCTION_STOCK_AUTHORITY`: PASS
- `ATOMIC_ITEM_OPENING_STOCK`: PASS
- `ROLLBACK_TEST`: PASS
- `EDGE_DEPLOYMENT_VERIFICATION`: PASS
- `EXACT_BROWSER_RUNTIME`: NOT EXECUTED in this environment because outbound network resolution is unavailable.
- `PRODUCTION_AUTHENTICATED_BROWSER_E2E`: NOT EXECUTED here because no authorized browser session/credentialed browser runner is exposed.
- Honest classification: `TECHNICAL_CLOSURE_PENDING_BROWSER_EVIDENCE`.

## NEXT AUTHORIZED ACTION
`P123-008_EXTERNAL_BROWSER_RUNTIME_GATE`
- Execute the exact frozen `Current/PWA/New-main` artifact in an authorized browser runner.
- Verify login/session, tenant resolution, dashboard, navigation, license route, notification badge/click/read behavior, owner-only audit/license behavior, console errors, network >=400 responses, and page/runtime exceptions.
- Record the exact run ID and artifact SHA here.
- Only then, if every gate passes, mark `CLOSED 100% / GOLD / DIAMOND / COMPLETE`.
