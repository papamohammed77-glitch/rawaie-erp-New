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
- P146: deployment-boundary repair committed to the published `erp-frontend` repository; legacy Manifest/SW URLs are now compatibility-routed to the canonical `company-1` assets. Runtime Auth closure remains open pending a fresh browser/runtime proof after deployment.

## DIRECT FORENSIC FINDINGS — 2026-09-02
### Source relationship
- `Current/PWA/New-main` remains the designated equivalent of `erp-frontend/companies/company-1/main.html`.
- Current `erp-frontend/companies/company-1/main.html` is Git blob `5bf6907747d807dfa9f10979f5a63685c8bae64e`, size 599007 bytes at the time of this verification.
- Latest published-repository commit before P146 was `022d0f1e0311328826c5ea11039f9ffc18f9def0` at 2026-09-01T20:53:06Z and fixed the HTML closing tag.
- P146 commit on the published repository is `e7a85c80904d57afaed58c782c358a85afb78b95`, created 2026-09-01T21:05:47Z.

### Supabase / Auth credential proof
- Production Supabase project: `fiilmooggumokxanwiyx`, status `ACTIVE_HEALTHY`, Postgres 17.6.1.
- Production exposes an active legacy `anon` key and an active modern publishable key.
- The exact legacy anon key embedded in `Current/PWA/New-main` matches the active Production legacy anon key.
- The exact legacy anon key embedded in `erp-frontend/companies/company-1/main.html` also matches the active Production legacy anon key.
- Therefore the current Git sources do NOT contain an invalid or disabled Supabase key.
- `RW_Auth.login` in `Current/PWA/New-main` calls `supabase.auth.signInWithPassword({email:username,password:password})`; no defect in that call was proven.

### Production runtime Auth evidence
- Supabase API logs show repeated `POST /auth/v1/token?grant_type=password` HTTP 401 responses from Chrome 151, including 2026-09-01T20:55:18.966Z and 20:55:18.968Z.
- Supabase Auth logs show a successful login event and successful token refresh from the same runtime hostname `https://erp-frontend.mh0537413487.workers.dev` at 2026-09-01T16:16:33Z, followed by a successful `/auth/v1/user` at 16:16:45Z.
- This proves the Supabase Auth service and the Production project are capable of authenticating this runtime successfully and that the observed 401 state is time-varying.
- The current runtime request's actual API key value cannot be read from the Supabase logs exposed here. Therefore it is NOT legitimate to claim the Worker is definitely sending a specific wrong key; the proven statement is only that the runtime is returning `Invalid API key` while the current Git key is valid in Production.

### Login source / deployment-lineage conclusion
- Because Current Git and published Git both carry the active Production anon key, changing the key line in `main.html` would be speculative and is explicitly rejected by the governance principle.
- The remaining proven boundary is the served Runtime/Deployment artifact: the browser receives an artifact that behaves differently from the verified current source, or an intermediate Worker layer modifies/serves another artifact/configuration.
- The direct Cloudflare Worker source/deployment configuration is not exposed through an available Cloudflare connector in this execution context. This is a declared UNVERIFIED boundary, not an invented explanation.

### Manifest defect — directly proven
- `companies/company-1/main.html` contains `<link rel="manifest" href="../manifest.json">`.
- The published repository contains the real manifest at `companies/company-1/manifest.json`.
- From `/companies/company-1/main.html`, `../manifest.json` resolves to `/companies/manifest.json`, which explains the browser `manifest.json 404` reported by the user.
- P146 adds an explicit rewrite from `/companies/manifest.json` to `/companies/company-1/manifest.json` in the published `_redirects` file.

### Service Worker compatibility defect — directly proven
- The historical runtime had requested `/companies/sw.js` because of the old relative registration path `../sw.js`.
- The canonical current target registration is `navigator.serviceWorker.register('./sw.js',{scope:'./'})` and the canonical published worker exists at `companies/company-1/sw.js`.
- P146 adds a compatibility rewrite from `/companies/sw.js` to `/companies/company-1/sw.js`, preventing an old cached/served artifact from failing solely because it still requests the historical URL.

## P144 / P146 PRODUCTION REPAIR RECORD
### P144 — New-main Service Worker repair
- `Current/PWA/New-main`: `../sw.js` → `./sw.js`, scope `../` → `./`.
- Evidence file: `Current/CTO/20260901_P144_RUNTIME_SURGICAL_REPAIR.json`.
- P144 explicitly recorded `production_runtime = PENDING_MANUAL_PUBLISH_AND_BROWSER_VERIFY`.

### P146 — published deployment boundary repair
- Repository: `papamohammed77-glitch/erp-frontend`.
- File changed: `_redirects` only.
- Commit: `e7a85c80904d57afaed58c782c358a85afb78b95`.
- Added:
  - `/companies/manifest.json /companies/company-1/manifest.json 200`
  - `/companies/sw.js /companies/company-1/sw.js 200`
- No Supabase credential change.
- No change to `main.html` login code.
- No change to Production Auth users.
- No change to protected `Current/PWA/main.html`.
- Purpose: close the URLs explicitly proven broken by runtime evidence while preserving the canonical current asset locations; the commit also provides a new deployment boundary for the Cloudflare-connected published repository.

## REPORT / EXPERIMENT HISTORY FOR CURRENT LOGIN INCIDENT
### What was verified
1. `MASTER - RAWAEA ERP.md` and the governance sequence were reviewed before modification.
2. `CURRENT_STATE.md` and reports 1–8 were reviewed as historical evidence, not as truth above direct sources.
3. Current `rawaie-erp-New` and published `erp-frontend` sources were inspected.
4. Supabase active keys were queried directly.
5. Supabase Auth/API logs were queried directly.
6. The live Worker hostname was identified from Production Auth logs.
7. `RW_Auth.login` was inspected and no code defect was proven.
8. Manifest and Service Worker URL resolution were traced against the actual published directory tree.
9. P146 was applied to the published repository.

### Rejected/failed approaches
- Replacing the Supabase key in `main.html` was rejected because the embedded key was directly proven active in Production; doing so would have been an unverified change.
- Treating the browser's `401 Invalid API key` as proof of a bad Git credential was rejected because the same credential exists and is active, and the same Worker hostname previously authenticated successfully.
- Treating the P135 console marker alone as proof of a stale file was rejected because that marker was not independently proven to be absent from the current target.
- Direct Cloudflare deployment/runtime inspection could not be completed because no Cloudflare connector is available in this execution context. This remains a hard verification boundary.

## CURRENT STATUS FLAGS
```text
MASTER_GOVERNANCE_REVIEW         = VERIFIED
CURRENT_STATE_RECONCILED         = VERIFIED / UPDATED_P146
REPORT_HISTORY                   = PRESERVED
SUPABASE_PRODUCTION              = ACTIVE_HEALTHY
SUPABASE_ANON_KEY_IN_CURRENT     = VERIFIED_ACTIVE
SUPABASE_ANON_KEY_IN_PUBLISHED   = VERIFIED_ACTIVE
RW_AUTH_LOGIN_SOURCE             = VERIFIED_NO_DEFECT_PROVEN
BROWSER_LOGIN                    = OPEN / 401_INVALID_API_KEY
RUNTIME_WORKER_ARTIFACT           = UNKNOWN / DIRECTLY_UNREADABLE_HERE
CLOUDFLARE_DEPLOYMENT_STATE       = UNVERIFIED
MANIFEST_404_CAUSE                = VERIFIED / PATH_MISMATCH
MANIFEST_COMPAT_ROUTE             = COMMITTED_P146
LEGACY_SW_404_CAUSE              = VERIFIED / HISTORICAL_PATH
SW_COMPAT_ROUTE                   = COMMITTED_P146
PRODUCTION_RUNTIME_AFTER_P146     = NOT_YET_VERIFIED_BY_NEW_BROWSER_EVENT
GOLD                              = UNPROVEN
DIAMOND                           = UNPROVEN
CLOSED_100_PERCENT                = NO
```

## CURRENT MANUAL / DEPLOYMENT CONTRACT
- Canonical product source: `rawaie-erp-New/Current/PWA/New-main`.
- Published product path: `erp-frontend/companies/company-1/main.html`.
- Published support assets include `companies/company-1/manifest.json` and `companies/company-1/sw.js`.
- P146 intentionally adds compatibility rewrites at the published boundary instead of duplicating canonical assets.
- No Production publish is to be inferred merely from the Git commit.

## REQUIRED RUNTIME CLOSURE TEST
After P146 is actually serving from the live Worker, the clean-session browser proof must show:
1. `RAWAEA ERP BOOTING...`
2. no `MAIN11_SUPABASE_UNAVAILABLE`
3. no `Invalid API key`
4. login succeeds
5. session restoration succeeds
6. tenant/company context resolves
7. owner/license guard behaves according to the historical contract
8. `/companies/manifest.json` no longer returns 404
9. `/companies/sw.js` no longer returns 404
10. canonical Service Worker scope is correct
11. no new uncaught console error blocks the application shell

## NEXT AUTHORIZED ACTION
- Verify the live `erp-frontend.mh0537413487.workers.dev` runtime after the P146 published-repository commit. This must be a fresh browser/network observation, not an inference from GitHub.
- If `Invalid API key` persists, obtain the actual served HTML/Worker configuration or deployment artifact and compare the runtime Supabase URL/key byte-for-byte with the verified Production key before changing any credential or login code.
- Do not reopen Supabase Auth configuration, Owner permissions, or `RW_Auth.login` without new direct evidence.

## REPORTS
- Historical reports remain preserved and sacred.
- `doc/Draft/Reprots/تقرير7.md` remains preserved as the P140 historical execution report.
- `doc/Draft/Reprots/تقرير8.md` remains preserved as the P143 forensic reconstruction/runtime diagnosis report.
- `doc/Draft/Reprots/تقرير9.md` is the P146 forensic login/deployment investigation and surgical repair report.

## FINAL FORENSIC JUDGMENT — CURRENT INCIDENT
The browser's `Invalid API key` is NOT proven to be caused by the Supabase key stored in current Git, because that exact key is active in Production and exists in both Current and published Git.

The strongest proven root boundary is:

`LIVE RUNTIME / DEPLOYMENT ARTIFACT MISMATCH`

with two independently proven URL defects at the published boundary:

- `../manifest.json` from `companies/company-1/main.html` → `/companies/manifest.json` 404
- historical `../sw.js` from the older runtime → `/companies/sw.js` 404

P146 closes both URL defects at the deployment boundary without modifying authentication behavior.

However, because the live Cloudflare Worker artifact itself is not directly readable from the available connectors, `Invalid API key` remains OPEN and `CLOSED_100_PERCENT = NO` until a fresh runtime observation proves the browser is now consuming the verified artifact and completing login successfully.
