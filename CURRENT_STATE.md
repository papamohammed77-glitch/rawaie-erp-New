# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- Operational truth: current Git main HEAD, Production Supabase, deployed Edge Functions, and runtime verification.
- Historical reports/prompts are evidence only.
- Authorized target: `Current/PWA/New-main`.
- `Current/PWA/main.html` is protected.
- Prompt 123/124 forbid reconstruction, overlay, new workflow, new file, or speculative production mutation.
- Every material operation is recorded here before closure.

## LAST VERIFIED EVENT
### P124-001 — FORENSIC_CONTINUATION_AND_PRODUCTION_HARDENING
- Prompt 124 (`doc/Draft/medhat/برومبت 124+ ملحق تقرير`) was read through its final `END COMMAND`; its execution rules now govern this continuation.
- `MASTER - RAWAEA ERP.md` was read through end-of-file; no later replacement of its governance model was found.
- `CURRENT_STATE.md` was reconciled against actual Git before use as an event ledger.
- Actual Git main HEAD at verification: `d4c2bf698d295b3a1a46c9caa74f65f0c6566dc6`.
- Latest commit that changed `Current/PWA/New-main`: `a5b7aa69f173da5002105023676b1eada0a87c42` (`[new-main-notification-persist] MAIN1 notification contract closure`, 2026-09-01 02:44:46 UTC).
- Exact current target blob SHA remains `d657d6e4bdd90a9b60f658a8bf28560e1b10f755`.
- Therefore `d657...` is the current file-content SHA, not the current branch HEAD; this distinction is now recorded explicitly.

## P124 FORENSIC FINDINGS
- MAIN1 contract mapping remains materially present in `Current/PWA/New-main`; no evidence-backed missing MAIN1 contract was established.
- Owner semantics are governed by authenticated Auth metadata `isOwner=true`, `users.permissions` containing `*`, and `owner_profile` presence; role-name alone is not accepted.
- MAIN1 notification contract exists: `_renderAndSave`, `_updateBadge`, `markRead`, `_clickNotif`.
- The notification contract remains subject to runtime verification; existence alone is not evidence of behavioral closure.
- Existing New-main layering/redefinitions remain a known architectural risk; no broad rewrite was performed because Prompt 124 forbids reconstruction and no specific runtime regression was independently proven from those duplicate layers.

## PRODUCTION FIXES EXECUTED
### P124-002 — WORKFLOW_NOTIFICATION_RLS_HARDENING
- Production RLS was reviewed for `workflow_rules`, `workflow_log`, and `notification_templates`.
- The effective policies now require authenticated access; no anonymous access path was accepted.
- No tenant column was invented for these legacy tables because the live schema does not contain `company_id` on them.

### P124-003 — MAIN1_DEPENDENCY_STOCK_AUTHORITY_HARDENING
- Direct Production inspection found `save-item` could bypass canonical stock authority by writing opening stock directly to `stock_branches`.
- This was a confirmed second physical-stock mutation path.
- `public.create_item_with_opening_stock(uuid,jsonb,uuid,numeric,text)` was implemented as a SECURITY DEFINER atomic owner path.
- The RPC validates company/category/branch context, creates the item, and routes opening balance through canonical `post_stock_movement('InventoryIncrease', ...)` with an idempotency key.
- Public EXECUTE was revoked; service-role execution is retained.
- `save-item` Production is now ACTIVE at version **12**, with `verify_jwt=true`, and calls the atomic RPC instead of directly mutating `stock_branches`.
- The live deployed source was re-read after deployment and contains no direct opening-balance `stock_branches` write in `save-item`.

## DATABASE / CORE VERIFICATION
- `post_stock_movement` exists as SECURITY DEFINER and enforces movement-type validation, branch-company validation, row locking, idempotency where supplied, `stock_branches` mutation, and `inventory_log` creation.
- `reserve_stock` and `post_journal_entry` exist as SECURITY DEFINER.
- MAIN1-sensitive tables inspected have RLS enabled, including `users`, `companies`, `customers`, `items`, `branches`, `orders`, `stock_branches`, `journal_entries`, `audit_log`, `owner_profile`, `notifications`, `workflow_rules`, and `workflow_log`.

## EDGE FUNCTION VERIFICATION
- `save-item`: version 12 ACTIVE, `verify_jwt=true`, SHA `ffc7e57e7fd57e60eaed861ebdd0f5187cc16347820007e900627fccf6486099`.
- `save-customer`: version 3 ACTIVE, `verify_jwt=true`, derives company context from authenticated `users` row.
- `log-action`: version 2 ACTIVE, `verify_jwt=true`.
- Core operational Edge Functions inspected are JWT protected.

## TEST EVIDENCE
- `create_item_with_opening_stock` was executed inside an explicit Production SQL transaction with synthetic test data and then rolled back.
- The RPC returned success and reported opening-balance posting.
- Post-rollback verification returned `test_items=0` and `test_logs=0`.
- This proves atomic rollback behavior and absence of test residue.

## STATIC / TARGET VERIFICATION
- Target contains MAIN1 shell, authentication/session surface, tenant context, owner/license surface, permissions, navigation, data bootstrap, audit, workflow, notification, search, PWA lifecycle, and delegated specialized-app routes.
- Target contains required MAIN1 global contracts including `RW_ShellContext`, `RW_OwnerLicense`, `RW_Views`, `RW_Dashboard`, `RW_Items`, `RW_POS`, `RW_Orders`, `RW_Runsheets`, `RW_Purchases`, `RW_Warehouse`, `RW_Finance`, `RW_Reports`, `RW_HR`, and `RW_CRM`.
- Existing clean-room workflow definition contains explicit Node syntax, DOM/contract, browser smoke, legacy-file protection, and checksum gates.
- No prior Browser PASS tied to exact target SHA `d657...` was established from the accessible repository evidence.
- Git commit combined-status lookup for `a5b7aa69...` returned no status checks.

## EXECUTION BLOCKER
### P124-004 — AUTHENTICATED_BROWSER_RUNTIME_GATE
- Exact owner/non-owner browser execution remains **PENDING**.
- The execution environment available in this session does not expose a reliable authenticated browser runner/session for the repository artifact.
- Local container network resolution cannot reach the raw GitHub artifact endpoint, so local browser replay cannot be treated as valid evidence.
- No installable browser-automation plugin was available in the connected plugin catalog.
- Existing repository workflow evidence available through the connector did not yield a Browser PASS tied to `d657...`.
- Per Prompt 124, this gate cannot be replaced by static markers, commit messages, self-attestation, CI assumptions, or historical reports.

## ROOT-CAUSE / RECOVERY CONCLUSION
- The repeated failure mode was primarily governance/evidence drift, not absence of the MAIN1 surface.
- Confirmed causes: stale event ledger, scope drift, overlay/self-attestation, duplicate JavaScript layering, mutable forensic tooling, and conflation of Git/CI/browser/Production evidence.
- A real Production dependency defect was also discovered: direct opening-stock mutation in `save-item`; it has now been removed from the live path and centralized through the atomic stock owner.
- The remaining blocker is proof, not a speculative implementation request.

## CLOSURE MATRIX
| Gate | Status | Evidence |
|---|---|---|
| Prompt 124 read to END COMMAND | PASS | `turn753file0` |
| MASTER - RAWAEA ERP read to EOF | PASS | Repository file returned empty content after line 2600 (`turn758file0`) |
| Git current state | PASS | main HEAD `d4c2bf698d295b3a1a46c9caa74f65f0c6566dc6` |
| Latest New-main commit | PASS | `a5b7aa69f173da5002105023676b1eada0a87c42` |
| Latest New-main file SHA | PASS | `d657d6e4bdd90a9b60f658a8bf28560e1b10f755` |
| MAIN1 source contract | PASS | Current + Original MAIN1 inspection |
| New-main MAIN1 mapping | PASS | Forensic contract review |
| Production RLS | PASS | Direct schema/policy inspection |
| Stock authority | PASS | canonical `post_stock_movement` |
| Atomic opening stock | PASS | rollback-tested `create_item_with_opening_stock` |
| save-item production hardening | PASS | v12 ACTIVE, JWT protected |
| Exact static artifact syntax | NOT INDEPENDENTLY CERTIFIED | Existing workflow defines gate, but no qualifying PASS was found for exact SHA |
| Exact browser runtime | **PENDING** | authenticated browser runner unavailable |
| Owner authenticated E2E | **PENDING** | no qualifying browser evidence |
| Non-owner authorization E2E | **PENDING** | no qualifying browser evidence |
| Tenant isolation E2E | **PENDING** | no qualifying authenticated browser evidence |
| Service Worker runtime | **PENDING** | no qualifying browser evidence |

## CURRENT CLASSIFICATION
`FORENSICALLY RECONCILED; PRODUCTION HARDENED; MAIN1 STATIC CONTRACT MAPPED; AUTHENTICATED BROWSER RUNTIME GATE PENDING`

## ABSOLUTE CLOSURE RULE
Do **not** mark `CLOSED 100% / GOLD / DIAMOND / COMPLETE` until Prompt 124's independent authenticated browser requirements are satisfied on the latest actual `Current/PWA/New-main` artifact and recorded here. A false 100% is explicitly prohibited.

## NEXT AUTHORIZED ACTION
`P124-005_AUTHENTICATED_BROWSER_RUNTIME_EXECUTION`
- Execute the exact current target artifact in a real browser with authorized Owner and non-Owner identities.
- Verify login, Auth bootstrap, tenant context, dashboard, navigation hierarchy, Owner/License gating, notifications, audit, logout/fail-closed, and network/console health.
- Add no overlays, no reconstruction, no new workflows, and no new permanent evidence files.
- If a qualifying browser runner becomes available, record run identity, artifact SHA, browser URL, console/network results, and authorization/tenant outcomes here.
- Only then may final classification become `CLOSED 100% / GOLD / DIAMOND / COMPLETE`.