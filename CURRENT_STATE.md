# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- Operational truth: current Git, Production Supabase, deployed runtime evidence, and published artifact evidence.
- Historical reports are evidence only; do not trust them over direct sources.
- `Current/PWA/New-main` is the authorized product target for `erp-frontend/companies/company-1/main.html`.
- `Current/PWA/main.html` remains protected and untouched.
- Historical reports are sacred and must never be deleted or overwritten.
- Do not declare Gold, Diamond, or 100% closure from CI/workflow success alone.
- No manual Production publish is to be assumed from a Git commit.

## HISTORICAL CONTINUITY
- P133: auth bootstrap repair merged; browser verification remained open.
- P134: deployment-lineage mismatch established; runtime showed 401 and `/companies/sw.js` 404.
- P135: direct runtime source repair; target `New-main`; marker `RAWAEA_P135_TARGET`.
- P136: MAIN11 scope repair; exported `window.RW_SUPABASE_CLIENT`, MAIN11 uses shared client.
- P137: `sw.js` finalized as P137 FINAL, cache namespace `rw-static-v3`.
- P138–P140: repeated direct reconciliation established that Git source and Production runtime were inconsistent; Supabase and owner/license remained healthy; Cloudflare artifact lineage remained unproven.
- P141–P143: reconstruction/assembly work continued after the state file became stale. Current forensic work supersedes stage labels in old reports where direct source evidence differs.
- P144: one-shot New-main Service Worker repair executed and then retired; evidence preserved in `Current/CTO/20260901_P144_RUNTIME_SURGICAL_REPAIR.json`.
- P145: current runtime/login investigation established that the Supabase key present in both Current and published Git is active in Production; the remaining 401 is therefore a served-runtime/deployment-path problem until the actual Worker artifact is directly verified.
- P146: deployment-boundary repair committed to the published `erp-frontend` repository; legacy Manifest/SW URLs are compatibility-routed to canonical `company-1` assets. Runtime Auth closure remained open pending fresh runtime proof.
- P150: permanent Service Worker auto-update/cache contract implemented in Current and published repository; live Cloudflare propagation remains directly unverified.

## DIRECT FORENSIC FINDINGS — 2026-09-02
### Source relationship
- `Current/PWA/New-main` remains the designated equivalent of `erp-frontend/companies/company-1/main.html`.
- Current `erp-frontend/companies/company-1/main.html` was previously proven to contain the active Production Supabase anon key.
- P146 added compatibility routes for historical manifest and Service Worker paths.

### Supabase / Auth credential proof
- Production Supabase project: `fiilmooggumokxanwiyx`, status `ACTIVE_HEALTHY`, Postgres 17.6.1.
- The exact legacy anon key embedded in Current and published Git was previously matched directly to the active Production legacy anon key.
- `RW_Auth.login` in `Current/PWA/New-main` uses `supabase.auth.signInWithPassword({email:username,password:password})`; no defect in that call was proven.
- Current 401 runtime state remains open because the served Cloudflare artifact/config cannot be read directly through an available connector in this execution context.

### P146 deployment boundary
- Published repository: `papamohammed77-glitch/erp-frontend`.
- Compatibility routes remain:
  - `/companies/manifest.json -> /companies/company-1/manifest.json`
  - `/companies/sw.js -> /companies/company-1/sw.js`
- P146 remains a source/deployment-boundary repair, not proof of live Worker propagation.

## P150 — PERMANENT AUTO-UPDATE CONTRACT
### Historical evidence
- `Original/PWA/register-sw.js` used `registration.update()` every 60 seconds and on `visibilitychange`.
- `Original/PWA/sw.js` used `skipWaiting()`, `clients.claim()`, Network Only for HTML/API, cache cleanup, and `RW_SW_UPDATED` notification.

### Current defect proven
- `Current/PWA/New-main` does NOT load `register-sw.js`; it registers the Service Worker inline.
- The inline path did not contain the historical periodic update coordinator or a `controllerchange` reload handler.
- `Current/PWA/sw.js` used a fixed `rw-static-v3` cache namespace.

### P150 source changes
- `Current/PWA/sw.js` is now `RAWAEA_SW_P150_AUTO_UPDATE`.
- Static cache namespace is derived from the SW build: `rw-static-RAWAEA_SW_P150_AUTO_UPDATE`.
- Install calls `skipWaiting()`.
- Activate calls `clients.claim()` and automatically navigates all in-scope window clients to their current URL.
- HTML/navigation, Supabase/API, and runtime JS/MJS/TS remain Network Only.
- Old cache namespaces are deleted on activation.
- `Current/PWA/register-sw.js` now performs an immediate update check, 60-second polling, visibility-triggered update, online-triggered update, and automatic reload on `controllerchange`.

### Published changes
- `erp-frontend/companies/company-1/sw.js` now carries the P150 auto-update contract.
- `erp-frontend/companies/company-1/register-sw.js` now carries the P150 coordinator.
- `erp-frontend/_headers` was added to require revalidation/no-store for app shell, Service Worker, registration coordinator, and manifests.
- P146 `_redirects` compatibility routes remain in place.

### P150 Git commits
- Current SW: `0cf055e368fb2d1a3f821402c4fbf097cdad3123`
- Current register-sw: `ff033853b54af30dd1b26941f831471a71853fa8`
- Published SW: `a67d36f29481b032e000e43919440d24e66426e7`
- Published register-sw: `5ed2a1d905fb9fdc479fad5d3ddf2a2f19ae8d3b`
- Published `_headers`: `49ad44762b36016151d90059c22dcb0e33d586e6`
- P150 report: `doc/Draft/Reprots/تقرير10.md` commit `47e60a62c1a346dbfee4e8a34512457e714c5722`

### Important implementation boundary
- `Current/PWA/New-main` still contains its own inline Service Worker registration. Because the file is very large/protected and the available Git connector only supports full-file replacement, it was intentionally NOT rewritten destructively in this sweep.
- P150 therefore makes the Service Worker lifecycle itself auto-reloading, and separately upgrades the shared `register-sw.js` coordinator for pages that explicitly load it.
- Continuous periodic detection for the New-main inline registration is NOT directly proven until the live app is serving a coordinator path that performs those checks. Normal browser Service Worker update checks still apply on registration/navigation.

## CURRENT STATUS FLAGS
```text
MASTER_GOVERNANCE_REVIEW         = VERIFIED
CURRENT_STATE_RECONCILED         = VERIFIED / UPDATED_P150
REPORT_HISTORY                   = PRESERVED
SUPABASE_PRODUCTION              = ACTIVE_HEALTHY
SUPABASE_ANON_KEY_IN_CURRENT     = VERIFIED_ACTIVE
SUPABASE_ANON_KEY_IN_PUBLISHED   = VERIFIED_ACTIVE
RW_AUTH_LOGIN_SOURCE             = VERIFIED_NO_DEFECT_PROVEN
BROWSER_LOGIN                    = OPEN / 401_INVALID_API_KEY (last proven runtime evidence)
RUNTIME_WORKER_ARTIFACT           = UNKNOWN / DIRECTLY_UNREADABLE_HERE
CLOUDFLARE_DEPLOYMENT_STATE       = UNVERIFIED
MANIFEST_404_CAUSE                = VERIFIED / PATH_MISMATCH
MANIFEST_COMPAT_ROUTE             = COMMITTED_P146
LEGACY_SW_404_CAUSE              = VERIFIED / HISTORICAL_PATH
SW_COMPAT_ROUTE                   = COMMITTED_P146
P150_SOURCE                       = COMPLETE
P150_PUBLISHED_REPO               = COMPLETE
P150_CACHE_CONTRACT               = COMPLETE
P150_AUTO_RELOAD_LOGIC            = COMPLETE
P150_LIVE_PROPAGATION              = UNVERIFIED
PRODUCTION_RUNTIME_AFTER_P150     = NOT_YET_VERIFIED_BY_NEW_BROWSER_EVENT
GOLD                              = UNPROVEN
DIAMOND                           = UNPROVEN
CLOSED_100_PERCENT                = NO
```

## CURRENT MANUAL / DEPLOYMENT CONTRACT
- Canonical product source: `rawaie-erp-New/Current/PWA/New-main`.
- Published product path: `erp-frontend/companies/company-1/main.html`.
- Published support assets include `companies/company-1/manifest.json`, `companies/company-1/sw.js`, and `companies/company-1/register-sw.js`.
- `erp-frontend/_headers` defines revalidation policy for application shell/SW identity.
- `erp-frontend/_redirects` preserves P146 compatibility routes for historical client paths.
- No Production publish is to be inferred merely from a Git commit.

## REQUIRED RUNTIME CLOSURE TEST
A fresh browser/runtime observation after P150 must show:
1. P150 SW build is served.
2. `/companies/company-1/sw.js` is 200 and returns P150 build marker.
3. `/companies/sw.js` is 200 through compatibility route.
4. `/companies/manifest.json` is 200 through compatibility route.
5. New login attempt no longer returns the previously observed `Invalid API key` unless the served artifact still differs from Git.
6. A new SW build activates without manual cache clearing.
7. Existing in-scope app windows reload automatically when a new SW activates.
8. Session restoration remains intact after automatic reload.
9. No new uncaught console error blocks the application shell.

## NEXT AUTHORIZED ACTION
- Verify the live `erp-frontend.mh0537413487.workers.dev` runtime after P150 is actually serving.
- Compare live `sw.js`, live `register-sw.js`, and live `main.html` against the Git P150 source byte-for-byte where accessible.
- If `Invalid API key` persists, obtain actual served HTML/Worker configuration and compare the runtime Supabase URL/key with the verified Production key before changing credentials.
- Do not reopen Supabase Auth configuration, Owner permissions, or `RW_Auth.login` without new direct evidence.
- After live P150 propagation is proven, resume Inventory Writer Closure Units one writer at a time.

## REPORTS
- Historical reports remain preserved and sacred.
- `doc/Draft/Reprots/تقرير7.md`, `تقرير8.md`, and `تقرير9.md` remain preserved.
- `doc/Draft/Reprots/تقرير10.md` is the P150 permanent auto-update/cache closure report.

## FINAL FORENSIC JUDGMENT
The project now has a permanent **source-level** auto-update contract:

`NEW SW BUILD → skipWaiting → clients.claim → automatic reload`

plus explicit cache revalidation rules and compatibility routes at the published boundary.

This is materially stronger than the historical manual Banner path.

However:

`GIT SOURCE = COMPLETE`
`LIVE CLOUDFLARE PROPAGATION = UNVERIFIED`

Therefore:

`CLOSED_100_PERCENT = NO`

until a fresh runtime/browser observation proves that the live Worker is serving P150 and the automatic update cycle is occurring in the real user environment.
