# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- Operational truth: current Git main HEAD, Production Supabase, deployed Edge Functions, and runtime verification.
- Historical reports/prompts are evidence only.
- Authorized target: `Current/PWA/New-main`.
- `Current/PWA/main.html` is protected.
- Prompt 123 forbids reconstruction, overlay, new workflow, new file, or speculative production mutation.

## LAST VERIFIED EVENT
### P123-006 — EXECUTABLE_VERIFICATION_AND_PRODUCTION_RLS_HARDENING
- Target static contract mapping remains complete: no evidence-backed MAIN1 contract is missing from `Current/PWA/New-main`.
- Independent source inspection confirmed target contains the required MAIN1 notification functions `_renderAndSave`, `_updateBadge`, `markRead`, `_clickNotif`, plus `RW_ShellContext`, `RW_OwnerLicense`, `RW_Views`, and the required MAIN1 view modules.
- Production Supabase verification confirmed the MAIN1-sensitive tables have RLS enabled: `users`, `companies`, `owner_profile`, `app_settings`, `workflow_rules`, `workflow_log`, `notification_templates`, `notifications`, `audit_log`, `items`, `customers`, `suppliers`, `branches`, `stock_branches`, `orders`, `journal_entries`, `customer_ledger`, `supplier_ledger`.
- Production core-function verification confirmed `post_stock_movement`, `reserve_stock`, and `post_journal_entry` exist as `SECURITY DEFINER` database functions.
- Production blocker discovered and remediated: `workflow_rules`, `workflow_log`, and `notification_templates` previously exposed an `ALL` policy for the `public` role. Migration `harden_main1_workflow_notification_rls` removed the public `ALL` policies and replaced them with authenticated-only access appropriate to the existing MAIN1 usage: authenticated SELECT on workflow rules/templates and authenticated INSERT on workflow log.
- Post-migration verification confirmed no `public ALL` policy remains on those three tables. The SELECT policies are evaluated with `auth.role() = 'authenticated'`; workflow-log insertion is restricted to the `authenticated` role.
- No production data was modified; this was policy-only hardening.
- Exact target artifact `Current/PWA/New-main` was not modified in P123-006, so the frozen artifact SHA remains the baseline `d657d6e4bdd90a9b60f658a8bf28560e1b10f755`.
- Runtime browser execution against the exact artifact could not be run in this environment because outbound network resolution is unavailable from the execution container. This is a tooling limitation, not an assertion of browser failure.
- Result: `PRODUCTION_SECURITY_GATE_PASS; STATIC_MAIN1_CONTRACT_GATE_PASS; BROWSER_GATE_EXTERNAL_REQUIRED`

## RECONCILIATION HISTORY
### P123-001 — STATE_RECONCILIATION
- Recorded in commit `e9fd4f819a384b29063d3918723f512da10ed50e`.

### P123-002 — TARGET_FREEZE_AND_IDENTITY_VERIFICATION
- Frozen target at start of reconciliation: `d657d6e4bdd90a9b60f658a8bf28560e1b10f755`.
- Frozen Current MAIN1: `de3ea2f6c1c638447d1c34c8f6237e14d5ae3b59`.
- Frozen Original MAIN1: `14b12a471c20ad23a2c18f456dbc4d59783a0d1f`.

### P123-003 — MAIN1_ORIGINAL_ANALYSIS
- Original MAIN1 full contract set extracted; no product mutation.

### P123-004 — MAIN1_CURRENT_ANALYSIS
- Current MAIN1 classified as a hardened/adapted variant of Original MAIN1.

### P123-005 — NEW_MAIN_MAPPING_AND_GAP_CLASSIFICATION
- All required MAIN1 contracts found in target; no missing contract identified.

### P123-006 — EXECUTABLE_VERIFICATION_AND_PRODUCTION_RLS_HARDENING
- Production RLS hardening applied and verified.

## TARGET FREEZE
- Baseline target SHA: `d657d6e4bdd90a9b60f658a8bf28560e1b10f755`
- The target remained unchanged through P123-006.
- Any future target SHA change must be recorded as a new surgical mutation and re-verified before closure.

## KNOWN BLOCKERS
- Browser/runtime execution against exact target artifact is still externally required because this environment cannot resolve outbound network addresses.
- Production behavioral evidence for authenticated login/navigation/notification interaction remains a separate gate from static and database verification.
- Therefore the state is not honestly marked GOLD/DIAMOND/COMPLETE yet.

## FAILED ATTEMPTS / DO-NOT-REPEAT
- Do not reconstruct MAIN1→MAIN11.
- Do not rebuild or rewrite New-main.
- Do not copy Original/Current MAIN1 into New-main.
- Do not add closure markers or metadata as a substitute for behavior.
- Do not modify forensic workflows to force green status.
- Do not modify Production without a proven MAIN1 blocker.
- Do not treat CI PASS, Browser PASS, and Production PASS as equivalent.
- Do not declare GOLD/DIAMOND while the exact browser gate is unverified.
- Do not start the next operation until this event is recorded here.

## NEXT AUTHORIZED ACTION
`P123-007 FINAL_BROWSER_RUNTIME_EVIDENCE`
- Execute browser smoke against the exact current `New-main` artifact.
- Verify no page errors, console errors, HTTP >=400 responses, and presence of shell/auth/owner/license/navigation contracts.
- Verify authenticated login -> tenant context -> dashboard -> notification surface with a real production session where authorized.
- Record exact run/evidence identifiers here.
- Only after all gates pass may the state be classified `CLOSED 100% / GOLD / DIAMOND / COMPLETE`.
