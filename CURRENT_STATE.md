# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- Operational truth: current Git main, Production Supabase, deployed Edge Functions, and independent runtime evidence.
- Historical reports/prompts are evidence only; they are not current truth.
- Authorized product target: `Current/PWA/New-main`.
- `Current/PWA/main.html` is protected and untouched.
- Historical reports are sacred: never delete or overwrite them.
- Gold/Diamond is never inferred from workflow success alone.
- No new source patch is authorized while a deployment-artifact mismatch remains unresolved.

## HISTORICAL CONTINUITY
### P131
- Specialized report navigation source repair completed in `Current/PWA/New-main`.
- Browser/Gold/Diamond closure was not proven.

### P132
- Memory/state reconciliation performed.
- Production Supabase baseline verified directly.
- Cloudflare deployment lineage remained unproven.

### P133 — AUTH BOOTSTRAP REPAIR
- PR #66 merged successfully.
- Product mutation: `573def3625d6f9c277c613c04ac8d5b513bf4310`.
- Merge: `5d5de8419cfd751220adb324fceb7a659d0d1941`.
- `Current/PWA/New-main` target blob after repair: `6c94560ef22ff6778fe0ecf91757afe500f4f1c63`.
- P133 corrected incorrect `window.supabase.auth` references.
- Browser verification remained open.

### P134 — DEPLOYMENT-LINEAGE FORENSICS
- Current source contained the active Supabase project configuration.
- Production Supabase was directly confirmed healthy.
- Runtime still produced `401 Invalid API key`.
- Runtime still requested `/companies/sw.js` and received `404`.
- Exact Cloudflare Pages artifact/commit/root remained unproven.
- Classification established: `DEPLOYMENT_ARTIFACT_MISMATCH / RUNTIME_LINEAGE_OPEN`.

### P135 — DIRECT RUNTIME SOURCE REPAIR
- Target: `Current/PWA/New-main`.
- Fixed the false MAIN11 Supabase availability guard.
- Added runtime marker `RAWAEA_P135_TARGET`.
- Source syntax passed.
- Browser closure remained pending.

### P136 — MAIN11 SCOPE REPAIR
- Root cause: MAIN11 is in a separate IIFE and cannot access the local `supabase` variable from MAIN1.
- Exported the existing client as `window.RW_SUPABASE_CLIENT`.
- MAIN11 now uses `var sb = window.RW_SUPABASE_CLIENT || null` and `sb.auth.getSession()`.
- Current target blob: `5a4cc333b24de8fe66b79329db97a997ffa8ec3b`.
- No credentials, DB, or Service Worker routing changed.

### P137 — SERVICE WORKER SOURCE FINALIZATION
- `Current/PWA/sw.js` updated to version `2.2 FINAL`.
- Build marker: `RAWAEA_SW_P137_FINAL`.
- Cache namespace: `rw-static-v3`.
- HTML/navigation, Supabase/API, and runtime code remain Network Only.
- Commit: `d36e7783e3934628bb63e7f2c5f3e95e0e5301ac`.
- Source syntax passed.
- `/companies/sw.js` runtime availability was intentionally NOT declared closed.

## P138 — DIRECT FORENSIC RECONCILIATION — 2026-09-01
### P138-01 — CURRENT GIT
- Current main history proves P136 target repair remains present.
- Current main HEAD at the start of P138 contained P137 source/report commits.
- Post-P136 commits did not revert `Current/PWA/New-main`; the later product source change was `Current/PWA/sw.js` only.
- P138 forensic report committed as `5fff8bfa73aa50970081441b1f448fe7d541c7f5`.

### P138-02 — RUNTIME CONFLICT
User/browser evidence currently shows:
- `RAWAEA_P135_TARGET New-main`
- `MAIN11_SUPABASE_UNAVAILABLE`
- `POST /auth/v1/token?grant_type=password → 401`
- `AuthApiError: Invalid API key`
- `/companies/sw.js → 404`

This runtime is inconsistent with the current Git target, which contains P136.

### P138-03 — DIRECT SUPABASE VERIFICATION
Production project: `fiilmooggumokxanwiyx`.
- Active legacy anon key exists.
- Active publishable key exists.
- Auth logs include successful login/refresh/user requests from a working runtime.
- Current browser/runtime also produces repeated 401 Auth requests.
- No P138 Supabase mutation was performed.

### P138-04 — OWNER / LICENSE FORENSICS
Direct SQL verification confirmed:
- Owner user is Active.
- `public.users.permissions = ["*"]`.
- Wildcard evaluation is true.
- Auth metadata `isOwner = true`.
- Auth metadata `permissions = ["*"]`.
- `owner_profile.auth_user_id` matches Auth user.
- `owner_profile.license_status = active`.

Therefore the owner wildcard/license contract is intact and is NOT the current blocker.

### P138-05 — SERVICE WORKER PATH FORENSICS
- `Current/PWA/New-main` uses relative registration `../sw.js`.
- `manifest.json` defines `start_url=/companies/company-1/app.html` and `scope=/companies/company-1/`.
- This resolves the Service Worker request to `/companies/sw.js`.
- Git contains `Current/PWA/sw.js` P137 FINAL, but runtime returns 404 for the required URL.
- Therefore `Git file exists ≠ deployed URL exists`.

### P138-06 — ROOT CAUSE
Current classification:

`DEPLOYMENT_ARTIFACT_MISMATCH / RUNTIME_LINEAGE_OPEN`

Evidence strongly supports that `rawaea-erp.pages.dev` is serving a stale/different artifact and/or has a deployment root/path mismatch.

This is the only explanation currently reconciling all three direct observations:
1. Git target = P136.
2. Browser runtime = P135 behavior/marker.
3. Runtime Service Worker URL = 404 while P137 source exists in Git.

The exact Cloudflare deployed commit, artifact identity, output/root directory, and path mapping remain UNPROVEN.

### P138-07 — NON-ACTION
- No new `New-main` patch.
- No new `sw.js` patch.
- No Supabase DB/Auth/schema mutation.
- No Cloudflare deployment was fabricated.
- No historical report was deleted or overwritten.

## CURRENT SURVIVING STATE
- `Current/PWA/New-main`: P136 source repair PRESENT.
- `Current/PWA/sw.js`: P137 FINAL source PRESENT.
- `Current/PWA/main.html`: PROTECTED / untouched.
- Supabase: ACTIVE / healthy by direct connector evidence.
- Owner wildcard: VERIFIED.
- Owner `isOwner`: VERIFIED.
- Owner license: ACTIVE.
- Browser authentication: OPEN / `401 Invalid API key`.
- `MAIN11_SUPABASE_UNAVAILABLE`: OPEN in served runtime.
- `/companies/sw.js`: OPEN / 404.
- Cloudflare Pages artifact identity: OPEN.
- Deployment root/output mapping: OPEN.
- Gold: UNPROVEN.
- Diamond: UNPROVEN.
- Closed 100%: NO.

## REPORTS
- `doc/Draft/Reprots/تقرير1` preserved.
- `doc/Draft/Reprots/تقرير2.md` preserved.
- `doc/Draft/Reprots/تقرير3.md` preserved.
- `doc/Draft/Reprots/تقرير4.md` preserved.
- `doc/Draft/Reprots/تقرير5.md` = P138 forensic deployment mismatch report, commit `5fff8bfa73aa50970081441b1f448fe7d541c7f5`.
- Hany reports remain preserved through `تقرير تنفيذي 15.md`.

## NEXT AUTHORIZED ACTIONS
1. Obtain the legitimate Cloudflare Pages deployment record for `rawaea-erp.pages.dev`: deployment ID, deployed commit, build configuration, output/root directory, and artifact identity.
2. Compare the served `/companies/company-1/main.html` against the current Git P136 target, including the P136 shared-client marker and Supabase client construction.
3. Fetch `/companies/sw.js` directly and require HTTP 200 plus `RAWAEA_SW_P137_FINAL`.
4. If the artifact is stale, redeploy the exact current authorized PWA target through the existing legitimate Cloudflare path. Do not change credentials or application logic again.
5. After deployment, perform a fresh browser session test: boot, shared client availability, login, session restoration, tenant resolution, dashboard, owner/license tab, and Service Worker registration/scope.
6. Only after independent runtime closure re-test specialized reports and evaluate Gold/Diamond.
7. Continue appending forensic state/report evidence; do not delete historical evidence.
