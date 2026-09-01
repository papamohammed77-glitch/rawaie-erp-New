# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- Operational truth: current Git main HEAD, Production Supabase, deployed Edge Functions, and runtime verification.
- Historical reports/prompts are evidence only.
- Authorized target: `Current/PWA/New-main`.
- `Current/PWA/main.html` is protected.
- Prompt 123 forbids reconstruction, overlay, new workflow, new file, or speculative production mutation.

## LAST VERIFIED EVENT
### P123-005 — NEW_MAIN_MAPPING_AND_GAP_CLASSIFICATION
- Frozen target inspected directly: `Current/PWA/New-main`.
- Target contains the MAIN1 shell, authentication/session surface, tenant context, owner/license surface, permissions, navigation, data bootstrap, audit, workflow, notifications, search, PWA lifecycle, and delegated specialized-app routes.
- Target contains the notification runtime contract required by MAIN1: `_renderAndSave`, `_updateBadge`, `markRead`, `_clickNotif`.
- Target contains `RW_ShellContext`, `RW_OwnerLicense`, `RW_Views`, `RW_Dashboard`, `RW_Items`, `RW_POS`, `RW_Orders`, `RW_Runsheets`, `RW_Purchases`, `RW_Warehouse`, `RW_Finance`, `RW_Reports`, `RW_HR`, and `RW_CRM`.
- Owner identity is not inferred from `owner_profile` alone: target requires Auth metadata owner flag + wildcard permission + owner profile presence.
- Tenant identity is established from authenticated Auth user -> `users.company_id`; shell remains hidden when tenant context cannot be established.
- Main business reads observed in the target use `company_id`/resolved branch scope where applicable; specialized stock/accounting writes remain delegated to core/Edge Functions.
- `RW_Workflow` behavior matches Current MAIN1 at the contract level; no additional tenant-scope rewrite was introduced because Current MAIN1 itself reads active workflow rules without a `company_id` filter and therefore this is not a proven parity gap for Prompt 123.
- MAIN1 contract classification: `EXACT` or `HARDENED/ADAPTED` for all required contracts; no evidence-backed `MISSING` contract remains.
- No source replacement, reconstruction, overlay file, new workflow, or Production mutation performed.
- Result: `NEW_MAIN_MAIN1_MAPPING_COMPLETE_NO_MISSING_CONTRACTS_IDENTIFIED`

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

## TARGET FREEZE
- Baseline target SHA: `d657d6e4bdd90a9b60f658a8bf28560e1b10f755`
- The target remained unchanged throughout P123-003, P123-004, and P123-005.
- Any future target SHA change must be recorded as a new surgical mutation and re-verified before closure.

## KNOWN BLOCKERS
- MAIN1 static contract mapping: resolved.
- Remaining closure requirement: independent execution evidence (JavaScript syntax + browser smoke + production/runtime evidence) on the exact final target artifact.
- No claim of Production/GOLD/DIAMOND closure is valid until the evidence gates above are independently satisfied.

## FAILED ATTEMPTS / DO-NOT-REPEAT
- Do not reconstruct MAIN1→MAIN11.
- Do not rebuild or rewrite New-main.
- Do not copy Original/Current MAIN1 into New-main.
- Do not add closure markers or metadata as a substitute for behavior.
- Do not modify forensic workflows to force green status.
- Do not modify Production without a proven MAIN1 blocker.
- Do not treat CI PASS, Browser PASS, and Production PASS as equivalent.
- Do not start the next operation until this event is recorded here.

## NEXT AUTHORIZED ACTION
`P123-006 EXECUTABLE_VERIFICATION_AND_CLOSURE`
- Verify exact target syntax/DOM/contract invariants.
- Run independent browser smoke against the exact target artifact where tooling permits.
- Capture runtime/Production evidence where access permits.
- Update this file after the operation with exact evidence identifiers and final classification.
