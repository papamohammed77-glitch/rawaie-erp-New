# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- Operational truth: current Git main HEAD, Production Supabase, deployed Edge Functions, and runtime verification.
- Historical reports/prompts are evidence only.
- Authorized target: `Current/PWA/New-main`.
- `Current/PWA/main.html` is protected.
- Prompt 123 forbids reconstruction, overlay, new workflow, new file, or speculative production mutation.

## LAST VERIFIED EVENT
### P123-004 — MAIN1_CURRENT_ANALYSIS
- Source: `Current/PWA/main/main1.md`
- Current MAIN1 blob SHA: `de3ea2f6c1c638447d1c34c8f6237e14d5ae3b59`
- Complete blob read completed before target modification.
- Confirmed intentional hardening relative to Original MAIN1:
  - `RW_ShellContext` resolves authenticated Supabase identity to the active `users` row and establishes `company_id`/user identity before system entry.
  - Bootstrap reads for `app_settings`, items, customers, branches, and suppliers are company-scoped where applicable.
  - Owner permission state is not accepted from an arbitrary wildcard profile alone; `currentUser.isOwner` drives absolute-owner behavior.
  - `enterSystem()` resolves tenant context before displaying the main application shell.
  - tenant-resolution failure is fail-closed: main shell remains hidden and login remains visible.
- Confirmed retained MAIN1 cross-cutting contracts:
  - `RW_Table`
  - `RW_Audit_log`
  - `RW_Permissions_check` / `RW_Permissions_applyUI`
  - `RW_Workflow`
  - `RW_Notification`
  - `RW_Audit_renderTab` and audit pagination/detail behavior
  - `RW_Auth` login/logout lifecycle
  - `RW_Data` bootstrap data loaders
  - `RW_Navigation` menu tree/filter/router/action dispatch
- Notification contract confirmed present in Current MAIN1: `_renderAndSave`, `_updateBadge`, `markRead`, `_clickNotif`; Original contains the same core functions. fileciteturn630file1L19-L32
- Classification: `CURRENT_MAIN1 = HARDENED_VARIANT_OF_ORIGINAL`, not a replacement architecture.
- No New-main mutation performed in this operation.
- Result: `CURRENT_MAIN1_CONTRACTS_EXTRACTED_AND_HARDENING_CLASSIFIED`

## RECONCILIATION HISTORY
### P123-001 — STATE_RECONCILIATION
- Recorded in commit `e9fd4f819a384b29063d3918723f512da10ed50e`.

### P123-002 — TARGET_FREEZE_AND_IDENTITY_VERIFICATION
- Frozen target: `d657d6e4bdd90a9b60f658a8bf28560e1b10f755`.
- Frozen Current MAIN1: `de3ea2f6c1c638447d1c34c8f6237e14d5ae3b59`.
- Frozen Original MAIN1: `14b12a471c20ad23a2c18f456dbc4d59783a0d1f`.

### P123-003 — MAIN1_ORIGINAL_ANALYSIS
- Original MAIN1: full contract set extracted; no product mutation.

## TARGET FREEZE
- Frozen target SHA: `d657d6e4bdd90a9b60f658a8bf28560e1b10f755`
- Unexpected target SHA change => STOP + forensic investigation.

## KNOWN BLOCKERS
- New-main complete mapping not yet completed.
- Gap classification not yet completed.
- Functional/browser/production closure not yet re-established.

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
`P123-005 NEW_MAIN_MAPPING_AND_GAP_CLASSIFICATION`
- Re-read frozen New-main.
- Map every MAIN1 contract to the target implementation.
- Classify each contract: `EXACT`, `HARDENED/ADAPTED`, `MISSING`, `INTENTIONALLY_REMOVED`, or `BLOCKED`.
- Only evidence-backed `MISSING/BLOCKED` behavior can enter the surgical-fix queue.
