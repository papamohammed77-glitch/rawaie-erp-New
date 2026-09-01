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
- The full execution order and stop conditions in `doc/Draft/medhat/برومبت + تقرير 122` were reread through the final execution section.
- `Current/PWA/main.html` remains protected and was not modified.
- The authorized reconstruction target is `Current/PWA/New-main`.
- `Current/PWA/main/main1.md` and `Original/PWA/main/main1.md` remain logical contract sources and were not modified.
- New-main contains the complete MAIN1→MAIN11 module chain plus a current navigation/owner/license/CRM closure patch.

## CURRENT PRODUCTION — DIRECTLY VERIFIED
- Production project: `fiilmooggumokxanwiyx` (`SMART ERP`)
- PostgreSQL: 17.6.x
- Direct owner identity test: owner auth identity -> public.users -> wildcard `['*']` -> owner_profile -> active license; verified.
- Direct permission-function test: Owner receives owner/random permission; non-owner receives assigned `delivery` permission and is denied `owner`; verified using PostgreSQL session JWT-sub simulation.
- Production physical-stock authority remains `post_stock_movement`; reservation authority remains `reserve_stock` / `release_stock_reservation`.
- No blind Production DDL/DML was introduced for the PWA work.

## CURRENT VERIFIED TARGET CHANGES
- `MAIN2` target commit: `ac6e55a...`
- `MAIN3` target commit: `7805951...`
- `MAIN4` target commit: `2c79811...`
- MAIN5→MAIN11 target commits are present in the current `New-main` history.
- Navigation/Owner/License/CRM/Users/Roles closure target commit: `31d4dc3afc4e59dfd9fc5ec90c4c982ee4d310dc`.
- The 31d commit changed only `Current/PWA/New-main` and tightened Owner semantics from owner_profile-only to authenticated metadata + wildcard + owner_profile, while adding the 122 navigation/dispatch contract. fileciteturn497file0L2-L2

## MAIN1 / 122 GAP STATUS
- Navigation parity: PATCHED in New-main according to Current main1 placement HR -> CRM -> Users -> Roles -> License(owner) -> Settings. fileciteturn498file0
- Owner semantic parity: PATCHED in New-main and verified in Production permission function.
- License route/entry: PATCHED in New-main; target contains RW_OwnerLicense and license owner guard.
- CRM route/entry: PATCHED in New-main; target contains RW_CRM and company-scoped CRM module.
- Users/Roles entries: PATCHED in New-main to explicit top-level entries matching the Current main1 tail placement.
- Notification contract: source proves Current/Original MAIN1 require `_clickNotif`, `_renderAndSave`, `_updateBadge`, and `markRead`; target currently requires final runtime verification of the newly added compatibility extension. fileciteturn527file1
- Audit contract: target has owner-only `RW_Audit_renderTab`, but full historical `RW_Audit_*` parity remains to be checked.
- Session fail-closed lifecycle: remains NOT VERIFIED.
- `workflow_rules` has no `company_id` column in Production; no invented tenant column was added. Workflow tenant scope remains an OPEN design/contract gap requiring provenance before any schema change.

## CURRENT RUNTIME / SECURITY OPEN ITEMS
- Browser authenticated E2E against real credentials remains NOT VERIFIED; one stale CI check uses a retired verifier endpoint and returned HTTP 410, which is unrelated to New-main. 
- New-main Service Worker runtime and deployment-lineage parity remain NOT VERIFIED.
- Full two-session Production concurrency proof remains NOT VERIFIED.
- Security Advisor findings remain OPEN unless independently remediated and verified.
- Broad RLS/role policy hardening remains subject to controlled consumer proof.
- Golden/Diamond certification remains NOT CERTIFIED until the full runtime and production gates pass.

## KNOWN FAILED ATTEMPTS AND THEIR ROOT CAUSES
- Early MAIN1 gate failed on inline-script detection; fixed by recognizing external `<script src>` tags and validating the single inline runtime.
- Historical MAIN2 compact integration produced broken escaping in `RW_Table`; replaced by authoritative MAIN2 source integration.
- MAIN5 reconstruction gate falsely rejected legitimate HTML-looking strings inside JavaScript; guard was narrowed.
- Initial Browser smoke treated extensionless `New-main` as a download under Python http.server; harness corrected by serving a temporary `.html` copy outside the repository.
- Notification closure runner initially failed because it assumed an exact `})();</script>` anchor; corrected to use the actual final `</script>` position.
- A separate legacy `Verify real Production sign-in` job failed because `auth-login-verification-20260818` is retired and returns HTTP 410; it is not evidence of a target defect.

## CONTINUITY RULES
- Reports are history, not truth.
- Commit message is not evidence without diff/runtime verification.
- Executor/workflow changes are not target completion.
- No duplicate stock/financial business engine is permitted in New-main.
- No Service Role key in PWA.
- No RLS disablement.
- No replacement of `Current/PWA/main.html` without full certification.

## LAST VERIFIED EVENT
- Event ID: `LVE-2026-09-01-003`
- Event Type: `MASTER_122_FORENSIC_TARGET_CLOSURE_PROGRESS`
- UTC: `2026-09-01T02:45:00Z` execution window
- Target: `Current/PWA/New-main`
- Latest target change: `31d4dc3afc4e59dfd9fc5ec90c4c982ee4d310dc`
- Production change: `app_private.current_user_has_permission(text)` strict owner semantics verified and retained.
- Actions: read Master and full 122 through final stop condition; verified full MAIN1→MAIN11 presence; reconciled Current main1 navigation; patched New-main navigation/Owner/License/CRM/Users/Roles; verified Production owner/permission semantics; initiated notification contract closure.
- Result: `122 CORE PARITY PATCHED / NOTIFICATION RUNTIME VERIFICATION PENDING / GOLD-DIAMOND NOT CERTIFIED`
- Next exact step: complete notification contract runtime verification, then audit/session checks, then final authenticated Production/browser/deployment gates.

## CURRENT CLOSURE STATUS
`CURRENT_STATE = SYNCHRONIZED`
`MASTER_CONTINUITY_COMMAND = ACTIVE`
`NEW_MAIN_MODULE_CHAIN = MAIN1..MAIN11_PRESENT`
`NAVIGATION_CONTRACT = PATCHED`
`OWNER_CONTRACT = PATCHED + PRODUCTION_VERIFIED`
`LICENSE_CONTRACT = PATCHED`
`CRM_CONTRACT = PATCHED`
`USERS_ROLES_CONTRACT = PATCHED`
`NOTIFICATION_CONTRACT = RUNTIME_VERIFICATION_PENDING`
`AUDIT_CONTRACT = OPEN`
`SESSION_FAIL_CLOSED = NOT_VERIFIED`
`WORKFLOW_TENANT_SCOPE = OPEN / PROVEN_SCHEMA_GAP`
`BROWSER_RUNTIME = OPEN`
`PRODUCTION_RUNTIME = PARTIAL`
`DEPLOYMENT_LINEAGE = OPEN`
`SECURITY = OPEN`
`CONCURRENCY = OPEN`
`MAIN_REPLACEMENT = NOT AUTHORIZED`
`GOLDEN_DIAMOND = NOT CERTIFIED`

<!-- TEMP NOTIFICATION TRIGGER -->