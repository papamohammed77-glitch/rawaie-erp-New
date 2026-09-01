# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- Operational truth comes from current Git, Production Supabase, deployed Edge Functions and runtime tests.
- Historical reports/prompts/assistant memory are evidence only.
- Authorized Golden target: `Current/PWA/New-main`.
- `Current/PWA/main.html` remains protected and untouched.

## VERIFIED TARGET
- `Current/PWA/New-main` contains the MAIN1→MAIN11 published module chain.
- Verified target commits in this continuity chain include MAIN2 `ac6e55a`, MAIN3 `7805951`, MAIN4 `2c79811`, and subsequent MAIN5→MAIN11 target commits.
- Latest verified target contract patch: `31d4dc3afc4e59dfd9fc5ec90c4c982ee4d310dc`.
- That patch changed only `Current/PWA/New-main`, restoring Navigation/Owner/License/CRM/Users/Roles parity and tightening Owner semantics.

## PRODUCTION
- Project: `fiilmooggumokxanwiyx` / `SMART ERP`.
- PostgreSQL 17.6.x.
- Owner identity directly verified: authenticated owner metadata + `public.users.permissions=['*']` + `owner_profile` + active license.
- `app_private.current_user_has_permission(text)` was updated to require those Owner semantics while preserving explicit user/role permissions.
- PostgreSQL JWT-sub simulation verified: Owner -> owner/random = true; non-owner delivery = true; non-owner owner = false.

## 122 FINDINGS
- Navigation: PATCHED to Current MAIN1 order/placement including HR, CRM, Users, Roles, License(owner), Settings.
- License: PATCHED in target; `RW_OwnerLicense` retained and owner route protected.
- CRM: PATCHED in target; final `RW_CRM` routed from navigation.
- Users/Roles: PATCHED in target navigation.
- Notification: OPEN. Current/Original MAIN1 require `_clickNotif`, `_renderAndSave`, `_updateBadge`, `markRead`; target did not contain them during direct search. A target injection was attempted but the runner failed before persistence due an incorrect script-close anchor.
- Audit: OPEN; target has owner-only audit renderer but full historical contract parity is not certified.
- Session fail-closed: NOT VERIFIED.
- Workflow tenant scope: OPEN; `workflow_rules` has no `company_id`, so no speculative schema change was made.

## TESTS
- Static target validation: PASS after navigation/owner/license/CRM patch.
- Production owner/permission semantics: PASS under PostgreSQL JWT-sub simulation.
- Browser navigation test: NOT VERIFIED; one prior run failed because extensionless `New-main` was served as a download. Harness was corrected afterward.
- Authenticated Production E2E: NOT VERIFIED. A separate legacy verifier endpoint is retired and returned HTTP 410; this is unrelated to New-main.
- Notification runtime contract: NOT VERIFIED because the target injection did not persist.
- Service Worker/deployment lineage: NOT VERIFIED.
- Two-session Production concurrency: NOT VERIFIED.

## FAILED ATTEMPTS / ROOT CAUSES
- MAIN1 syntax failure: malformed escaping in earlier target patch -> corrected in target lineage.
- MAIN2 compact merge: broken escaping -> replaced with authoritative MAIN2 source, target commit `ac6e55a`.
- MAIN5 wrapper guard: legitimate HTML-looking JS strings falsely rejected -> guard narrowed.
- Browser harness: extensionless target treated as download -> harness corrected to serve temporary `.html` outside repository.
- Notification runner: exact `})();</script>` anchor did not exist -> runner corrected to final `</script>` anchor, but the subsequent target write is still unpersisted.

## SAFETY
- No duplicate stock/financial writer was introduced.
- No Service Role key was introduced into PWA.
- RLS was not disabled.
- No replacement of `Current/PWA/main.html`.
- No new Golden/final target file was created.

## LAST VERIFIED EVENT
- Event ID: `LVE-2026-09-01-005`
- Event Type: `MASTER_122_FORENSIC_EXECUTION_RECONCILIATION`
- Target: `Current/PWA/New-main`
- Target commit: `31d4dc3afc4e59dfd9fc5ec90c4c982ee4d310dc`
- Production permission contract: corrected and directly tested.
- Result: `122 CORE NAV+OWNER+LICENSE+CRM+USERS+ROLES PATCHED / NOTIFICATION+AUDIT+SESSION+WORKFLOW+RUNTIME OPEN`
- Next exact step: persist notification contract, run clean browser E2E, then close audit/session/workflow scope and deployment/runtime gates.

## CLOSURE
`MAIN1_TO_MAIN11 = PRESENT`
`NAVIGATION = PATCHED`
`OWNER = PATCHED + PRODUCTION_VERIFIED`
`LICENSE = PATCHED`
`CRM = PATCHED`
`USERS_ROLES = PATCHED`
`NOTIFICATION = OPEN`
`AUDIT = OPEN`
`SESSION = NOT VERIFIED`
`WORKFLOW_SCOPE = OPEN`
`BROWSER = NOT VERIFIED`
`PRODUCTION_E2E = NOT VERIFIED`
`DEPLOYMENT_LINEAGE = OPEN`
`SECURITY = OPEN`
`CONCURRENCY = NOT VERIFIED`
`GOLDEN_DIAMOND = NOT CERTIFIED`