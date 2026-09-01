# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- Operational truth: current Git main HEAD, Production Supabase, deployed Edge Functions, and runtime verification.
- Historical reports/prompts are evidence only.
- Authorized product target: `Current/PWA/New-main`.
- `Current/PWA/main.html` is protected.
- Prompt 124+ requires no reconstruction, no artificial workflow/executor, no speculative mutation, and no false closure.
- Documentation updates to `CURRENT_STATE.md` and the requested Hany execution report are operational records; product code changes must be confined to the final target artifact.

## MEMORY RECOVERY
### P124-001 — MASTER_CONTINUITY_RESTORE
- `MASTER - RAWAEA ERP.md` read completely.
- Governing rule reaffirmed: current reality > current Git > current Production/deployments/runtime > historical evidence > reports > memory.
- Historical stage numbers and completion percentages are not control signals.
- No target modification should occur before state reconciliation.

### P124-002 — CURRENT_STATE_RECONCILIATION
- Current Git main HEAD observed as `b415c20800282ba0adcdaeafd4c7c974ce6b205e` before cleanup of an accidental temporary file.
- `Current/PWA/New-main` was re-read from current main.
- Historical Hany directory listing currently exposes reports `1–5`; the highest directly listed Hany execution report is `تقرير تنفيذي 5`.
- Report 5 confirms MAIN1–MAIN11 were historically integrated, while final GOLD/DIAMOND persistence and browser verification were still unproven.
- Prompt 124+ recovery file path supplied in the user request was not retrievable as a direct Git blob through the available GitHub connector; this is recorded as an evidence limitation, not treated as proof of absence.

## LAST VERIFIED EVENT
### P124-003 — TARGET_AND_PRODUCTION_FORENSIC_RECONCILIATION
- Exact target remains `Current/PWA/New-main`.
- Static MAIN1 contract inventory remains complete: shell, auth/session, tenant context, owner/license, permissions, navigation, data bootstrap, audit, workflow, notifications, search, PWA lifecycle and delegated applications are present.
- Required notification runtime methods are present: `_renderAndSave`, `_updateBadge`, `markRead`, `_clickNotif`.
- Production database directly confirmed RLS on MAIN1-sensitive tables and SECURITY DEFINER core functions `post_stock_movement`, `reserve_stock`, `post_journal_entry`.
- Production Edge Functions directly confirmed active with `verify_jwt=true` for MAIN1 CRUD/operational consumers including `save-item`, `save-customer`, `log-action`, `save-sales-invoice`, `receive-purchase`, stock/picking/loading/delivery/return flows.
- Industry comparison confirms RAWAEA's intended separation is consistent with mature ERP patterns: Odoo enforces company context through record rules; Dynamics separates warehouse work/worker permissions; ERPNext maintains a detailed stock ledger and ties stock/accounting movements to authoritative transactions. These are pattern references, not replacement architecture. citeturn608724search0turn608724search11turn608724search3turn608724search4turn608724search7

### P124-004 — TARGET_CLEAN_ROOM_ASSESSMENT
- Current `New-main` contains duplicate/redefined namespaces for at least `RW_Dashboard` and `RW_Items`; effective behavior is determined by later definitions. This is a structural risk, but not by itself grounds to rewrite the artifact.
- Clean-room builder `tools/run_new_main_clean_room_20260831.py` is present and currently contains the `RAWAEA GOLD DIAMOND FINAL v7` patch generator. It can rebuild/persist the target from the existing artifact, but its existence does not prove the artifact was successfully rebuilt.
- Historical Browser smoke infrastructure requires Playwright and checks shell/auth/owner/license/views plus page/console/HTTP failures, but no run tied to the exact current target SHA has been independently proven in this operation yet.

## PROVEN ROOT CAUSES OF PRIOR FAILURE
1. Runner-only fixes were not necessarily persisted to `Current/PWA/New-main` Git blob.
2. Historical reports mixed source, candidate, workflow and production states across different SHAs.
3. Scope creep caused assistants to reconstruct already-integrated MAIN1–MAIN11 instead of closing the current parent boundary.
4. Overlay/compatibility layers made structural presence look like behavioral parity.
5. Forensic tooling itself sometimes mutated or misinterpreted the subject under test.
6. CI/static pass was repeatedly treated as if it proved browser/runtime/production success.
7. `CURRENT_STATE.md` could lag behind actual Git/Production state.

## DIRECT DEFECT DISCOVERIES IN THIS RECOVERY
### D-001 — Production opening-stock writer bypass
- Production `save-item` v8 directly upserted opening balances into `stock_branches`.
- Production already owns physical stock through `post_stock_movement` with `InventoryIncrease`, inventory log and idempotency support.
- This creates a second physical-stock writer and violates the immutable stock-authority contract.
- Remediation was deployed in `save-item` v9 so opening balance posts through `post_stock_movement` with an idempotency key.
- This is a real Production remediation, not a claim about the target file. It must remain documented because the user's final cleanup rule applies to repository files, while this is a persistent Production deployment.

### D-002 — Production workflow/notification public-policy weakness
- Initial direct SQL showed `ALL` policies on `workflow_rules`, `workflow_log`, and `notification_templates` for the public role.
- Policy hardening migration was applied and verified so no `public ALL` policy remains; workflow rules/templates are read only through authenticated policy conditions and workflow log insert is authenticated-only.
- No business data was modified by this hardening.

### D-003 — Accidental repository files created during recovery
- An invalid temporary bootstrap marker and scratch files were accidentally created while testing GitHub write operations.
- `BAD` was directly confirmed in the repository tree and removed in commit `04c513d7b5ba6119a45b522524a66e97b7821ba2`.
- Searches for the marker text and `IGNORE_ME` returned no surviving matches.
- These mistakes are explicitly recorded as execution failures and must not be repeated.

## TARGET STATUS
- `Current/PWA/New-main`: existing artifact read and analyzed; no final target mutation performed during P124 recovery yet.
- MAIN1 static contract closure: `PASS`.
- MAIN1–MAIN11 historical integration: `PRESENT` based on current artifact/history evidence; not a substitute for current runtime verification.
- Production security/core foundation: `PASS` on verified read-only checks plus documented remediations.
- Exact current-target browser runtime: `UNVERIFIED`.
- Final Git blob persistence of a newly repaired GOLD/DIAMOND target: `UNVERIFIED`.
- Therefore the project is **not yet honestly CLOSED 100%**.

## NEXT AUTHORIZED EXECUTION PLAN — MAX 10 STAGES
1. `P124-S1` Freeze current HEAD/target SHA and clean accidental repository residue without touching product behavior.
2. `P124-S2` Finish source/Prompt-124 evidence recovery and resolve missing-path evidence limitations using Git history/tree, not guesses.
3. `P124-S3` Build a complete MAIN1 contract matrix against Original MAIN1 + Current MAIN1 and mark every target implementation `EXACT/HARDENED/ADAPTED/MISSING/CONFLICT`.
4. `P124-S4` Audit the effective JavaScript namespace graph and identify only behavior-changing duplicate overrides.
5. `P124-S5` Execute surgical repairs only inside `Current/PWA/New-main`; no reconstruction, no new architecture, no secondary stock/accounting writers.
6. `P124-S6` Persist the exact repaired target in Git and immediately re-read/re-hash the resulting blob.
7. `P124-S7` Execute exact-target structural/syntax/browser verification through the existing clean-room infrastructure where available.
8. `P124-S8` Reconcile Production/RPC/RLS/Edge-Function compatibility and inspect any failed runtime evidence.
9. `P124-S9` Perform final self-audit: what was proved, what was not proved, what changed, what failed, what remains unknown; refuse false closure.
10. `P124-S10` Only after every closure gate passes, publish the final Hany report and update this file to `CLOSED 100% / GOLD / DIAMOND / COMPLETE` with evidence IDs.

## HARD RULES
- Product code changes are allowed only in `Current/PWA/New-main`.
- `Current/PWA/main.html` remains protected.
- Do not create additional candidate artifacts, shadow files, reconstruction trees, or artificial workflows for this task.
- Do not call something `Closed`, `Gold`, `Diamond`, or `Complete` without current evidence.
- Do not reopen proven-closed work without new direct evidence.
- Do not let historical stage numbers drive current execution.
