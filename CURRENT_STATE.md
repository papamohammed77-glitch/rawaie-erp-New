# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- Operational truth: current Git, Production Supabase, deployed runtime evidence, and published artifact evidence.
- Historical reports are evidence only; never trust them over direct sources.
- `Current/PWA/New-main` is the authorized product target for `erp-frontend/companies/company-1/main.html`.
- `Current/PWA/main.html` remains protected and untouched.
- Historical reports are sacred and must never be deleted or overwritten.
- Git commit success is never treated as Production runtime proof.
- No 100% closure is declared without fresh Production/runtime evidence.

## HISTORICAL CONTINUITY
- P133: auth bootstrap repair; browser verification remained open.
- P134: deployment-lineage mismatch; runtime showed 401 and `/companies/sw.js` 404.
- P135: direct runtime source repair; target `New-main`; marker `RAWAEA_P135_TARGET`.
- P136: MAIN11 scope repair; shared client exported.
- P137: Service Worker finalized as P137 FINAL, cache namespace `rw-static-v3`.
- P138–P140: repeated reconciliation proved Git/Production runtime inconsistency; Cloudflare lineage remained unproven.
- P141–P143: reconstruction/assembly continued after state drift.
- P144: one-shot New-main Service Worker path repair; evidence preserved in `Current/CTO/20260901_P144_RUNTIME_SURGICAL_REPAIR.json`.
- P145: active Production Supabase key proved valid; 401 remained a served-runtime/deployment boundary issue.
- P146: published deployment boundary repaired with compatibility routes for historical Manifest/SW URLs.
- P150: permanent SW auto-update/cache contract implemented in source and published repository.
- P151: closed P150's remaining New-main coordinator gap by making the SW inject the shared update coordinator into controlled HTML; syntax failure was detected and corrected before final closure.

## DIRECT FORENSIC FINDINGS — 2026-09-02
### Auth/runtime
- Production Supabase `fiilmooggumokxanwiyx` is `ACTIVE_HEALTHY`.
- Current and published Git contain the active Production legacy anon key; credential replacement remains unjustified without new runtime evidence.
- `RW_Auth.login` uses `signInWithPassword`; no defect in that call was proven.
- Last proven runtime state before P150/P151 still had `401 Invalid API key`; the live Cloudflare artifact is not directly readable through an available connector here.

### P146 compatibility boundary
- Published `_redirects` continues to route:
  - `/companies/manifest.json -> /companies/company-1/manifest.json`
  - `/companies/sw.js -> /companies/company-1/sw.js`

## P150/P151 — PERMANENT AUTO-UPDATE CONTRACT
### Historical contract
`Original/PWA/register-sw.js` used:
- immediate registration;
- `registration.update()` every 60 seconds;
- update checks on `visibilitychange`;
- `controllerchange` handling.

`Original/PWA/sw.js` used:
- `skipWaiting()`;
- `clients.claim()`;
- Network Only for HTML/API;
- cache cleanup;
- `RW_SW_UPDATED` notification.

### Current gap proven
`Current/PWA/New-main` does not load `register-sw.js` directly. It registers `./sw.js` inline.

### P150
- Versioned SW cache namespace.
- Immediate activation.
- Automatic reload of in-scope windows after activation.
- Explicit no-cache/no-store deployment headers for app shell/SW identity in `erp-frontend/_headers`.

### P151 final design
`Current/PWA/sw.js` and published `companies/company-1/sw.js` now:
- use build marker `RAWAEA_SW_P151_AUTO_UPDATE_COORDINATOR`;
- use versioned cache `rw-static-RAWAEA_SW_P151_AUTO_UPDATE_COORDINATOR`;
- keep HTML/API/runtime code network-backed;
- activate immediately with `skipWaiting()`;
- claim clients with `clients.claim()`;
- automatically reload all in-scope windows on SW activation;
- inject `register-sw.js` into controlled HTML before `</head>` when the coordinator marker is absent.

The injected script path is derived from the SW registration scope, so nested pages resolve it against the application scope rather than their own directory.

The shared `register-sw.js` in Current and Published now performs:
- immediate `registration.update()`;
- 60-second polling;
- update on visibility;
- update on online;
- automatic reload on `controllerchange`.

The injection approach intentionally avoids destructive editing of the very large protected `New-main` file while still making the coordinator reachable from the actual main application after SW control is established.

## P151 EXECUTION RECORD
- Current SW final commit: `897e3336f3d68a948eba0b6f2aa5478526e42281`
- Published SW final commit: `13f4757bad0bcef2bd35e7d15e22e6c23d9e8498`
- Shared Current register coordinator commit: `ff033853b54af30dd1b26941f831471a71853fa8`
- Shared Published register coordinator commit: `5ed2a1d905fb9fdc479fad5d3ddf2a2f19ae8d3b`
- Published `_headers` commit: `49ad44762b36016151d90059c22dcb0e33d586e6`
- P151 audit report: `doc/Draft/Reprots/تقرير11.md` commit `63325869cf83ba62fb14db2d2492cbf907c64e95`.
- `CURRENT_STATE.md` was updated after P151.

## P151 ERROR / CORRECTION
- First P151 draft contained a missing closing parenthesis in the static-assets `event.respondWith(...)` branch.
- Local `node --check` caught the syntax error.
- The final Current SW was corrected and `node --check` returned `SW_SYNTAX_PASS`.
- The corrected source was then written to Git and mirrored to the published repository.

## IMPORTANT DEPLOYMENT BOUNDARY
- No GitHub Actions run exists for the P150/P151 commits through the available workflow lookup.
- The repository therefore provides no independent CI evidence that Cloudflare has already served P151.
- Direct Cloudflare Worker deployment/source inspection is unavailable in this execution context.
- Consequently `LIVE_CLOUDFLARE_ARTIFACT` and `LIVE_DEVICE_PROPAGATION` remain unverified.

## CURRENT STATUS FLAGS
```text
MASTER_GOVERNANCE_REVIEW         = VERIFIED
CURRENT_STATE_RECONCILED         = VERIFIED / UPDATED_P151
REPORT_HISTORY                   = PRESERVED
SUPABASE_PRODUCTION              = ACTIVE_HEALTHY
SUPABASE_ANON_KEY_IN_CURRENT     = VERIFIED_ACTIVE
SUPABASE_ANON_KEY_IN_PUBLISHED   = VERIFIED_ACTIVE
RW_AUTH_LOGIN_SOURCE             = VERIFIED_NO_DEFECT_PROVEN
BROWSER_LOGIN                    = OPEN / LAST_PROVEN_401
RUNTIME_WORKER_ARTIFACT           = UNKNOWN / DIRECTLY_UNREADABLE_HERE
CLOUDFLARE_DEPLOYMENT_STATE       = UNVERIFIED
MANIFEST_COMPAT_ROUTE             = COMMITTED_P146
LEGACY_SW_COMPAT_ROUTE            = COMMITTED_P146
P150_SOURCE                       = COMPLETE
P151_SOURCE                       = COMPLETE
P151_SYNTAX                       = VERIFIED_PASS
P151_UPDATE_COORDINATOR           = COMPLETE
P151_CDN_POLICY                   = PRESENT
P151_LIVE_PROPAGATION              = UNVERIFIED
PRODUCTION_RUNTIME_AFTER_P151     = NOT_YET_VERIFIED_BY_NEW_BROWSER_EVENT
GOLD                              = UNPROVEN
DIAMOND                           = UNPROVEN
CLOSED_100_PERCENT                = NO
```

## REQUIRED NEXT RUNTIME TEST
A fresh browser/network observation must prove:
1. live `sw.js` returns P151 build marker;
2. live `register-sw.js` returns the P151 coordinator;
3. `/companies/sw.js` is 200;
4. `/companies/manifest.json` is 200;
5. a new SW version automatically activates and existing app windows reload without manual cache clearing;
6. login and session restoration continue to work;
7. no new uncaught console error blocks the shell.

## INVENTORY CONTINUITY
The Global Inventory Core Integrity Sweep remains governed by:

`PHYSICAL STOCK MOVEMENT → post_stock_movement → stock_branches + inventory_log`

with `reserve_stock` limited to reservation responsibility.

Previous forensic work identified additional Writer/tenant closure issues; they remain open until each Writer is independently proven, fixed, deployed, and production-verified. No Inventory 100% claim has been made from reports alone.

## FINAL FORENSIC JUDGMENT
The permanent update architecture is now complete at the **source/Git level**:

```text
NEW SW DETECTED
   ↓
skipWaiting
   ↓
activate
   ↓
clients.claim
   ↓
automatic in-scope reload
   ↓
HTML served through SW
   ↓
register-sw.js injected
   ↓
immediate + periodic update checks
```

This removes the historical requirement for manual cache clearing and the old manual "Update now" interaction.

The only remaining gap is external to the source change itself: direct proof that the live Cloudflare Worker is now serving P151 and that real user devices have consumed the new deployment. Until that runtime fact is observed, `CLOSED_100_PERCENT` remains `NO`.
