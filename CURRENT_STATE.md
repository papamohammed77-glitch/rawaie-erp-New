# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- Operational truth: current Git main HEAD, Production Supabase, deployed Edge Functions, and runtime verification.
- Historical reports/prompts are evidence only.
- Authorized target: `Current/PWA/New-main`.
- `Current/PWA/main.html` is protected.
- No reconstruction, overlay, new workflow, or new file is authorized by Prompt 123.

## LAST VERIFIED EVENT
### P123-003 — MAIN1_ORIGINAL_ANALYSIS
- Source: `Original/PWA/main/main1.md`
- Original MAIN1 blob SHA: `14b12a471c20ad23a2c18f456dbc4d59783a0d1f`
- Read mode: complete blob read before any target mutation.
- Historical contracts established:
  - Authentication/session bootstrap and login/logout event binding.
  - User/role/permission evaluation and Owner semantics.
  - Tenant-sensitive application state and global shell initialization.
  - Notification runtime contract: `RW_Notification`, `_renderAndSave`, `markRead`, `_updateBadge`, `_clickNotif` and notification reference navigation behavior.
  - Audit contract and audit-detail access behavior.
  - Workflow/rules evaluation contract.
  - Navigation/router and page dispatch contracts.
  - Shared data/bootstrap helpers and global UI lifecycle.
  - Safe rendering/event helpers used by the parent shell.
- Classification rule: the existence of a function name in a derived implementation is not sufficient; parity requires executable behavior and compatible cross-module contracts.
- Result: `ORIGINAL_MAIN1_CONTRACTS_EXTRACTED`
- Product mutation: none.
- Evidence: full direct Git blob read plus targeted direct Git searches confirming notification contracts in Original MAIN1. The same notification contracts are also present in Current MAIN1. fileciteturn630file2L35-L48

## RECONCILIATION HISTORY
### P123-001 — STATE_RECONCILIATION
- Recorded in commit `e9fd4f819a384b29063d3918723f512da10ed50e`.
- `CURRENT_STATE` was stale relative to Git and was synchronized before target work.

### P123-002 — TARGET_FREEZE_AND_IDENTITY_VERIFICATION
- Target SHA verified unchanged at `d657d6e4bdd90a9b60f658a8bf28560e1b10f755`.
- Current MAIN1 SHA `de3ea2f6c1c638447d1c34c8f6237e14d5ae3b59`.
- Original MAIN1 SHA `14b12a471c20ad23a2c18f456dbc4d59783a0d1f`.

## TARGET FREEZE
- Frozen target SHA: `d657d6e4bdd90a9b60f658a8bf28560e1b10f755`
- Rule: any unexpected New-main SHA change requires STOP + forensic investigation.

## KNOWN BLOCKERS
- Current MAIN1 analysis not yet completed.
- New-main mapping not yet completed.
- Evidence-bound gap classification not yet completed.
- Functional/browser/production closure remains unverified.

## FAILED ATTEMPTS / DO-NOT-REPEAT
- Do not reconstruct MAIN1→MAIN11.
- Do not rebuild or rewrite New-main.
- Do not copy Original/Current MAIN1 into New-main.
- Do not add closure markers, wrapper contracts, or metadata as a substitute for behavior.
- Do not modify forensic workflows to force green status.
- Do not modify Production unless MAIN1 is directly blocked and the minimum safe fix is proven.
- Do not treat CI PASS, Browser PASS, or Production PASS as interchangeable.
- Do not start the next operation until the previous event is reflected here.

## NEXT AUTHORIZED ACTION
`P123-004 MAIN1_CURRENT_ANALYSIS`
- Read Current/PWA/main/main1.md completely.
- Identify intentional hardening versus behavior regressions.
- Compare current MAIN1 contracts against the Original contract set above.
- Do not modify New-main during this analysis.
