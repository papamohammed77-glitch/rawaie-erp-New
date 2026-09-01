# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- Operational truth: current Git main HEAD, Production Supabase, deployed Edge Functions, and runtime verification.
- Historical reports/prompts are evidence only.
- Authorized target: `Current/PWA/New-main`.
- `Current/PWA/main.html` is protected.
- Prompt 123 forbids reconstruction, overlay, new workflow, new file, or speculative production mutation.
- Every material operation is recorded here before closure.

## LAST VERIFIED EVENT
### P123-008 — FINAL_FORENSIC_GATE_REVIEW
- Full Prompt 123/appendix execution path was followed through state reconciliation, target freeze, Original MAIN1 analysis, Current MAIN1 analysis, New-main mapping, surgical Production hardening, and independent database verification.
- The report's core root causes were confirmed in practice: stale state, scope drift, overlay-vs-behavior confusion, mutable forensic infrastructure, and conflation of CI/Git/browser/Production evidence. fileciteturn673file0L2
- A previously hidden direct dependency was discovered during forensic inspection: Production `save-item` could bypass the canonical stock engine through direct `stock_branches` upsert. This was corrected and then made transactionally atomic via `create_item_with_opening_stock` + `post_stock_movement`.
- External architecture research independently supports the adopted security model: Odoo treats multi-company access as record rules based on `company_id`/`company_ids`; Salesforce uses layered object/record sharing with restrictive defaults and explicit expansion of access. citeturn905106search12turn905106search0turn905106search3

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
- Production workflow/notification RLS hardened; target unchanged.
### P123-007 — PRODUCTION_STOCK_AUTHORITY_AND_ATOMIC_ITEM_CREATION
- `save-item` v11 is active; opening stock creation is routed through one atomic PostgreSQL transaction using `create_item_with_opening_stock` and canonical `post_stock_movement`.
- Rollback verification left `0` synthetic test items and `0` synthetic inventory logs.
### P123-008 — FINAL_FORENSIC_GATE_REVIEW
- Production and static gates re-verified; exact Browser gate remains externally required.

## TARGET FREEZE
- Exact target SHA remains `d657d6e4bdd90a9b60f658a8bf28560e1b10f755`.
- `Current/PWA/New-main` was not modified by P123-006 through P123-008.
- The Production fixes are dependencies of the frozen target, not a reconstruction of it.

## PRODUCTION VERIFIED
- RLS enabled on all MAIN1-sensitive tables inspected.
- `post_stock_movement` (including idempotency-capable overload), `reserve_stock`, and `post_journal_entry` exist as `SECURITY DEFINER` functions.
- `create_item_with_opening_stock(uuid,jsonb,uuid,numeric,text)` exists as `SECURITY DEFINER`; `public` EXECUTE is false and `service_role` EXECUTE is true.
- `save-item` is ACTIVE at version 11 with `verify_jwt=true`.
- `save-customer` is ACTIVE at version 3 with `verify_jwt=true` and derives `company_id` from authenticated context.
- `log-action` is ACTIVE at version 2 with `verify_jwt=true`.
- Workflow rules/templates/log public `ALL` exposure was removed; authenticated-only policies are now in place.
- Active workflow rules: 3. Active notification templates: 4. Workflow log rows: 0. Notification rows: 0. Audit rows: 1866 at verification time.

## TEST EVIDENCE
- Atomic item creation + opening stock was executed inside an explicit SQL transaction and rolled back.
- The RPC returned `success=true` and `opening_balance_posted=true` during the transaction.
- Post-rollback verification returned `test_items=0` and `test_logs=0`.
- The v10 Edge Function experiment was rejected immediately because its delete/re-create fallback was non-atomic; v11 superseded it.

## ROOT-CAUSE / RECOVERY CONCLUSION
- The project did not fail because MAIN1 was fundamentally absent.
- The main execution failure was a governance/evidence failure combined with layered implementation history.
- Static MAIN1 parity was substantially present before this pass.
- The meaningful engineering gap uncovered during deeper review was not MAIN1 UI absence but an unsafe stock mutation path in a MAIN1 dependency; it is now corrected at the Production Edge/DB layer.
- The remaining independent gate is Browser/Runtime execution on the exact frozen artifact.

## BROWSER GATE
- No browser PASS is claimed.
- Local container network resolution is unavailable, preventing execution against the deployed web artifact from this environment.
- Repository workflow evidence found no prior Browser PASS tied to frozen target SHA `d657d6e4bdd90a9b60f658a8bf28560e1b10f755`.
- The existing clean-room browser script's license-navigation assertion may itself require an authenticated test state; this is a test-harness concern that must be validated independently rather than changed merely to force green.
- No credentialed browser session is exposed to this execution context.

## CLOSURE MATRIX
| Gate | Status | Evidence |
|---|---|---|
| Prompt 123 full read | PASS | Repository report read to end |
| State reconciliation | PASS | P123-001..008 ledger |
| Target identity/freeze | PASS | target SHA `d657d6e…` |
| MAIN1 Original analysis | PASS | P123-003 |
| MAIN1 Current analysis | PASS | P123-004 |
| New-main mapping | PASS | P123-005 |
| Production security | PASS | RLS + JWT verification |
| Stock authority | PASS | canonical `post_stock_movement` |
| Atomic opening stock | PASS | rollback-tested RPC |
| Edge deployment | PASS | save-item v11 active |
| Exact browser runtime | **PENDING** | external authenticated browser runner required |
| Production authenticated E2E | **PENDING** | credentialed browser execution required |

## CURRENT CLASSIFICATION
`TECHNICALLY_RECONCILED; PRODUCTION_HARDENED; STATIC_MAIN1_CLOSED; BROWSER_RUNTIME_GATE_PENDING`

## ABSOLUTE CLOSURE RULE
Do NOT mark `CLOSED 100% / GOLD / DIAMOND / COMPLETE` until an independent authenticated browser run proves the exact frozen artifact behavior and records its run ID here. A false 100% is explicitly prohibited.

## NEXT AUTHORIZED ACTION
`P123-009_AUTHENTICATED_BROWSER_RUNTIME_EXECUTION`
- Run the exact `Current/PWA/New-main` SHA in a real browser with authorized test identity.
- Verify login -> authoritative tenant context -> dashboard -> navigation -> license/owner gating -> notifications -> audit -> logout/fail-closed behavior.
- Collect console errors, uncaught exceptions, HTTP >=400 responses, and evidence of successful/failed gates.
- Record run ID, browser URL, artifact SHA, and result in this file.
- Only a clean run permits final `CLOSED 100% / GOLD / DIAMOND / COMPLETE` classification.
