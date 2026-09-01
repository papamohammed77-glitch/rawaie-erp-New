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

---

## P139 — DIRECT RUNTIME / CURRENT-SOURCE RECONCILIATION — 2026-09-01
### P139-01 — MASTER / STATE / REPORT RECOVERY
- `doc/Draft/medhat/MASTER - RAWAEA ERP.md` was opened from the repository and its current-truth/continuity/governance command was followed: read current state first, reconcile against current Git/Production/runtime, do not patch unknowns.
- `CURRENT_STATE.md` was read directly before mutation.
- `doc/Draft/Reprots/تقرير1` through `تقرير5.md` were reviewed as the historical sequence; no historical report was deleted or overwritten.
- P139 report created as `doc/Draft/Reprots/تقرير6.md` in commit `48cfcc012cf1d4e13ba9b0cf70ab6df2bf7ad878`.

### P139-02 — CURRENT TARGET DIRECT PROOF
- Current `Current/PWA/New-main` was read directly from Git/Raw.
- P136 is physically present in the current target:
  - `window.RW_SUPABASE_CLIENT=supabase`
  - `window.__RAWAEA_P136_SCOPE_REPAIR__='shared-client'`
  - `var sb = window.RW_SUPABASE_CLIENT || null`
  - `sb.auth.getSession()`
- Current target still contains the P135 continuity marker; that marker alone does not identify the runtime as P135.
- Therefore the previous P136 source repair was not lost or silently reverted.

### P139-03 — GIT HISTORY RECONCILIATION
- Direct Git comparison of P136 commit `65b2ef057cba3f2f507495a37f124f6d9225ac39` to current HEAD `1ba72e0b915d907a32bac5794ed548c9b81755ba` shows no subsequent modification to `Current/PWA/New-main`.
- Later product modification in this lineage was `Current/PWA/sw.js` for P137.
- Current source therefore remains P136-correct.

### P139-04 — RUNTIME CONFLICT REMAINS
User runtime evidence continues to show:
- `RAWAEA_P135_TARGET New-main`
- `MAIN11_SUPABASE_UNAVAILABLE`
- `POST /auth/v1/token?grant_type=password → 401`
- `AuthApiError: Invalid API key`
- `/companies/sw.js → 404`

This cannot be reconciled with the current source because the current source contains the P136 marker and shared-client guard.

### P139-05 — SERVICE WORKER / HEADERS DIRECT REVIEW
- `Current/PWA/sw.js` remains the P137 final source.
- `Current/PWA/_headers` contains `no-cache/no-store/must-revalidate` rules for `/sw.js`, nested `sw.js`, `/manifest.json`, root HTML, and nested HTML.
- These rules are only effective if `_headers` is included in the actual Cloudflare Pages output root; that root is still unproven.

### P139-06 — DIRECT EXTERNAL ACCESS LIMITS
- A direct repository clone from the execution container failed at DNS resolution (`Could not resolve host: github.com`); this was treated as an environment limitation, not repository evidence.
- Direct public fetch of `https://rawaea-erp.pages.dev/companies/sw.js` through the available web channel returned `Cache miss`; no false HTTP-200 claim was made.
- No Cloudflare Pages deployment-management connector or installable Cloudflare plugin was available in this session.

### P139-07 — SUPABASE / OWNER / LICENSE RECONFIRMATION
- Production Supabase remains healthy by direct connector evidence.
- Active legacy anon key and publishable key exist.
- Owner contract remains verified: `public.users.permissions=["*"]`, Auth `isOwner=true`, Auth `permissions=["*"]`, linked active owner profile, `license_status=active`.
- No P139 Supabase mutation was performed.

### P139-08 — SURGICAL DECISION
- No new JavaScript patch is authorized.
- No new Supabase credential change is authorized.
- No new `sw.js` content patch is authorized.
- No duplicate `/companies/sw.js` file is to be added by guesswork.
- The only valid surgical action remaining is to publish the exact current P136/P137 artifacts through the legitimate Cloudflare Pages path and prove the resulting URL-to-artifact mapping.

### P139-09 — CURRENT STATUS
```text
CURRENT_SOURCE_P136        = VERIFIED
CURRENT_SW_P137            = VERIFIED
SUPABASE_PRODUCTION        = HEALTHY
OWNER_WILDCARD             = VERIFIED
OWNER_LICENSE              = ACTIVE
BROWSER_LOGIN              = OPEN / 401
MAIN11_UNAVAILABLE         = OPEN IN SERVED RUNTIME
COMPANIES_SW               = OPEN / 404
CLOUDFLARE_ARTIFACT_ID     = UNKNOWN
DEPLOYMENT_ROOT_MAPPING    = UNKNOWN
GOLD                       = UNPROVEN
DIAMOND                    = UNPROVEN
CLOSED_100_PERCENT         = NO
```

### P139-10 — NEXT AUTHORIZED EXECUTION
1. Publish the exact `Current/PWA/New-main` artifact containing P136.
2. Publish the exact `Current/PWA/sw.js` containing `RAWAEA_SW_P137_FINAL`.
3. Verify the actual output root maps to `/companies/company-1/main.html` and `/companies/sw.js`.
4. Open a clean browser session and require the P136 marker, absence of `MAIN11_SUPABASE_UNAVAILABLE`, successful login/session restoration, owner/license tab visibility, and Service Worker HTTP 200.
5. Only then close deployment/auth gates and resume Gold/Diamond evaluation.
