# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- `CURRENT_STATE.md` is the single operational state entry point for this repository.
- `LAST VERIFIED EVENT` is the only recency authority; `LAST REPORT` has no operational authority.
- Historical reports/prompts, historical repositories and assistant memory are evidence/navigation only.
- Any mismatch between this file, Git, Production, deployments or runtime must be marked `STALE` and reconciled before new engineering decisions.
- Production changes require root-cause, dependency, contract, test, deployment and post-deployment verification before closure.
- Project memory is maintained in `Current/CTO/RAWAEA_PROJECT_MEMORY_117-02.md`.

## PROJECT
- Project: RAWAEA ERP
- Current repository: `papamohammed77-glitch/rawaie-erp-New`
- Historical repository: `papamohammed77-glitch/rawaie-erp-review`
- Active Git branch: `main`
- Production Supabase: `SMART ERP` / `fiilmooggumokxanwiyx`
- Staging Supabase: `rawaea-staging` / `hfzznsiprnwkpayskzhu`

## CURRENT REALITY RECONCILIATION — 2026-09-01
- The full `doc/Draft/medhat/MASTER — RAWAEA ERP.md` command was read end-to-end through section 60 and adopted as the governing execution model.
- `Current/PWA/main.html` remains protected and was not modified.
- The authorized reconstruction target is `Current/PWA/New-main`.
- Latest verified Git HEAD before this state update was `e8da572a5b42a407c4d5f8d7493b9e4fe134f663`.
- The most recent commit that actually modified `Current/PWA/New-main` remains `a4551e0fcfc55fd609f48109407c025b44e20641`; later commits changed workflow/tooling/prompts/documentation rather than the target.
- Therefore executor/parser/browser-gate changes are not evidence that the target artifact itself is complete.
- `Current/PWA/main/main1.md` and `Original/PWA/main/main1.md` remain logical contract sources and were not modified.
- New-main currently contains substantial MAIN1 shell/auth/navigation/permissions/notification/workflow/audit functionality, but the complete MAIN1 behavioral contract is not yet proven closed.

## CURRENT PRODUCTION — LAST DIRECTLY VERIFIED SNAPSHOT
- Production project: `fiilmooggumokxanwiyx` (`SMART ERP`)
- Status: `ACTIVE_HEALTHY`
- PostgreSQL: 17.6.x
- Verified continuity baseline: one company, 24 users, 2 branches, 17 items, 20 stock rows, 3 inventory-log rows, 0 orders, 0 runsheets, 2 journal headers, 0 journal lines, 0 customer/supplier/driver ledger rows, 0 daily settlements, 1 treasury.
- Authoritative identity path: authenticated user -> `public.users.auth_id` -> `public.users.company_id`.
- Physical-stock authority: `post_stock_movement`.
- Reservation authority: `reserve_stock` / `release_stock_reservation`.
- Journal authority for inspected posting paths: `post_journal_entry`.

## CURRENT OPEN SECURITY / RUNTIME FINDINGS
- Broad authenticated/anon policies remain on some order/fulfillment and settlement tables and require controlled consumer proof before remediation.
- Security Advisor findings remain open, including externally executable `SECURITY DEFINER` functions and disabled leaked-password protection.
- Full deployment-lineage parity for critical Edge Functions is not closed.
- No verified two-session Production concurrency proof is recorded for New-main.
- New-main browser/runtime parity is not certified.
- New-main Service Worker runtime is not certified.
- Main replacement is not authorized.

## MAIN1 FORENSIC / IMPLEMENTATION STATE
- MAIN1 forensic contract is verified in current project records.
- MAIN1 implementation in New-main remains `OPEN`.
- Required MAIN1 contracts include `RW_Audit_*`, `RW_Permissions_*`, `_clickNotif`, `_renderAndSave`, `_updateBadge`, `RW_Workflow`, identity/auth/navigation helpers, and associated audit/notification/workflow data contracts.
- Direct New-main inspection found these remaining contract concerns:
  - Owner calculation currently allows `owner_profile` existence to make `isOwner=true`; governing contract requires owner semantics to originate from authenticated metadata while preserving wildcard permissions.
  - New-main contains only a lightweight `RW_OwnerLicense` getter object; the full MAIN10 owner/license UI and save/change-email/change-password route was not found in the target artifact.
  - New-main notification implementation lacks the MAIN1 `_clickNotif`, `_renderAndSave`, `_updateBadge`, and `markRead` behavior including related-record navigation.
  - New-main audit rendering is simplified relative to the MAIN1 `RW_Audit_*` contract set.
  - Session reset/fail-closed behavior is not proven to the MAIN1 lifecycle contract.
  - Workflow rule loading is not explicitly company-scoped in the current New-main implementation; impact remains to be proven before any production security change.
- No New-main write was performed in this execution because the available GitHub write operation replaces the entire monolithic file and the full target bytes could not be safely reconstructed without risking unrelated content loss. This is a tooling safety limitation, not a closure claim.

## VERIFIED ARTIFACT / WORKFLOW LINEAGE
- `Current/PWA/New-main` is the sole authorized target.
- `a4551e0...` is the latest confirmed target-changing commit in this continuity chain.
- `6b339cc...` was an executor attempt, later reverted; it is not target proof.
- `9507d0...`, `02da996...`, `c2c316...` and related commits primarily changed execution tooling/gates and do not substitute for target implementation.
- No new workflow, executor, candidate, backup or parallel architecture was created by this execution.

## CURRENT BUSINESS / ARCHITECTURAL CONTRACTS
- Sales channels converge into order/runsheet/fulfillment lifecycle.
- Physical stock authority: `post_stock_movement`.
- Reservation authority: `reserve_stock` / `release_stock_reservation`.
- Journal authority for inspected accounting paths: `post_journal_entry`.
- Dedicated customer/supplier/driver ledger writers exist.
- Specialized PWAs remain responsible for POS, Telesales, Van Sales, Purchasing/Receiving, Picking, Loading, Delivery, Returns and Stock Vouchers.
- New-main must delegate domain ownership to existing Core/Edge/RPC paths rather than recreate business engines.

## HISTORICAL SOURCE STATUS
- Historical `rawaie-erp-review/main` is architecture/contract/forensics evidence, not current Production truth.
- Historical CTO/Inventory memory tracks preserve prior closures and failure knowledge.
- Inventory writer closure was scoped to the physical-stock writer boundary, not ERP-wide closure.
- Historical reports require current re-verification before closure claims.

## MEMORY 117-02
- `Current/CTO/RAWAEA_PROJECT_MEMORY_117-02.md` remains the persistent governed memory ledger.
- It incorporates the Master command, current Production baseline, historical reconciliation, consumer examples and current MAIN1 target-gap findings.
- It does not claim exhaustive consumer/deployment closure or Production readiness.

## KNOWN INCIDENT / ANTIPATTERN MEMORY
- Report != current truth.
- Historical PASS != current PASS.
- CI PASS/Migration PASS != Production PASS.
- Git source != deployed code unless lineage is proven.
- Executor fix != target implementation.
- Commit existence != runtime deployment.
- Active function/workflow != production consumer.
- Do not create duplicate physical-stock writers.
- Do not repair anomalies without provenance and audit/downstream analysis.
- Do not use `LIMIT 1` to conceal tenant ambiguity.
- Do not byte-slice logical PWA modules.
- Do not replace Main before parity/runtime certification.
- Do not use a schema/advisor warning alone as authorization for Production mutation.

## FORBIDDEN ACTIONS — ACTIVE
- No blind Production DDL/DML.
- No Production business-logic patch solely to satisfy CI.
- No direct Physical Stock writer outside canonical engines.
- No direct financial mutation from New-main.
- No deletion of unknown legacy artifacts.
- No credential/token use merely because exposed in historical workflow source.
- No replacement of `Current/PWA/main.html` without complete evidence.
- No artificial workflow/executor/parallel architecture.

## LAST VERIFIED EVENT
- Event ID: `LVE-2026-09-01-002`
- Event Type: `MASTER_CONTINUITY_MAIN1_TARGET_RECONCILIATION_FINAL`
- UTC: `2026-09-01T00:15:00Z` execution window
- Source: full MASTER command sections 0-60 + direct GitHub commit history/diff comparison + direct New-main/main1/main10 inspection + current Production evidence already verified in this chain
- Git SHA: `e8da572a5b42a407c4d5f8d7493b9e4fe134f663`
- Production State: `ACTIVE_HEALTHY`
- Action: completed the required continuity sequence, reconciled current HEAD against the last New-main target change, inspected the target and MAIN1/MAIN10 contracts, confirmed remaining target gaps, and refused unsafe whole-file replacement without complete target bytes.
- Result: `CURRENT_STATE SYNCHRONIZED / MAIN1 OPEN / TARGET WRITE SAFETY BLOCKER RECORDED`
- Evidence: `a4551e0...` is the latest New-main modification; current target source at HEAD was inspected; MAIN1 notification/audit/owner/license contracts were cross-checked.
- Impact: no legacy Main change and no Production mutation; false MAIN1 closure was prevented.
- Next Authorized Action: obtain/use a safe full-file target-write path, apply only the proven MAIN1 gaps in `Current/PWA/New-main`, then run static validation, browser/runtime verification, and authenticated Production compatibility checks before closure.

## CURRENT CLOSURE STATUS
`CURRENT_STATE = SYNCHRONIZED`
`MASTER_CONTINUITY_COMMAND = ACTIVE`
`MEMORY_GOVERNANCE_117_02 = ACTIVE`
`PRODUCTION_HEALTH = ACTIVE_HEALTHY`
`MAIN1_FORENSIC_CONTRACT = VERIFIED`
`NEW_MAIN_MAIN1_PARITY = OPEN`
`NEW_MAIN_BROWSER_RUNTIME = OPEN`
`NEW_MAIN_PRODUCTION_RUNTIME = OPEN`
`MAIN1_TARGET_WRITE = EXTERNAL_TOOLING_SAFETY_LIMITATION`
`DEPLOYMENT_LINEAGE = PARTIAL / OPEN`
`SECURITY = OPEN`
`CONCURRENCY = OPEN`
`MAIN_REPLACEMENT = NOT AUTHORIZED`
`GOLDEN_DIAMOND = NOT CERTIFIED`

<!-- TEMP CLOSURE TRIGGER: final verification run -->
<!-- TEMP CLOSURE TRIGGER 2 -->