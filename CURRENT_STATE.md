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

## DIRECT FORENSIC FINDINGS — 2026-09-01
### Source relationship
- `Current/PWA/New-main` is the designated equivalent of `erp-frontend/companies/company-1/main.html`.
- Direct Git review showed the target lineage was not lost between those two repositories; prior target content was present in both.
- Published/support files reviewed include `schema-validator.js`, `sw.js`, `register-sw.js`, `core.js`, and `app.html`; no evidence supports inventing a replacement root file or changing the application architecture.

### Supabase / Auth
- Production Supabase project: `fiilmooggumokxanwiyx`.
- Active anon and publishable keys exist.
- Auth logs contain successful login/refresh activity from another runtime.
- Direct owner verification: `public.users.permissions=["*"]`, Auth `isOwner=true`, Auth `permissions=["*"]`, owner profile linked, license status `active`.
- Therefore owner wildcard/license is NOT the current blocker and Role Permissions must not be expanded to compensate.

### Service Worker
- The legacy `New-main` registration used `../sw.js`.
- With `/companies/company-1/main.html`, this resolves to `/companies/sw.js`.
- Browser evidence showed exactly that URL returning 404.
- `Current/PWA/sw.js` exists in Git, but Git existence does not prove that the URL exists in the published artifact.
- Reconstruction logic has been changed to canonical registration: `navigator.serviceWorker.register('./sw.js',{scope:'./'})`.
- Production closure is NOT proven until the user manually publishes the updated target/support file set and the URL is tested directly.

### Reconstruction / build failure
The P143 reconstruction pipeline did not initially produce a valid `New-main`.

Confirmed failure chain:
1. Early reconstruction produced `JS_SYNTAX_FAIL: Unexpected end of input`.
2. Phase isolation proved the FIRST broken fragment was `main1.md`.
3. The immediate source defect was a forensic HTML sentinel such as `<!-- RAWAEA_P1_FORENSIC_CLOSED:v18 -->` being concatenated inside the single application JavaScript block.
4. Reconstruction was amended to strip trailing `RAWAEA_*` sentinels and to run phase-by-phase Node syntax checks from `main1` through `main11`.
5. A second defect was found in the reconstruction workflow: it previously validated/persisted `Current/PWA/main.html` instead of the authorized target `Current/PWA/New-main`. The workflow has been corrected to build, validate, browser-smoke, and persist `New-main` itself.
6. Temporary forensic workflow files were created for isolation and then removed. Historical reports were not removed.

## CURRENT ARTIFACT STATUS
- `Current/PWA/New-main` currently remains the previously stored target blob `5a4cc333b24de8fe66b79329db97a997ffa8ec3b` at the time of last direct fetch; a newly reconstructed target has NOT yet been proven written to that path.
- Therefore the user's current Production Console (`P135`, `/companies/sw.js` 404, Auth 401) MUST still be treated as a served-runtime symptom until a new target is manually published and re-tested.
- The reconstruction tool and canonical forensic workflow have been updated, but CI execution after the final tool changes is not treated as successful without a direct completed run artifact.

## CURRENT STATUS FLAGS
```text
CURRENT_SOURCE_P136        = VERIFIED
CURRENT_SW_P137            = VERIFIED
SUPABASE_PRODUCTION        = HEALTHY
OWNER_WILDCARD             = VERIFIED
OWNER_isOwner              = VERIFIED
OWNER_LICENSE              = ACTIVE
NEW_MAIN_TARGET            = STALE / RECONSTRUCTION NOT YET PROVEN WRITTEN
BROWSER_LOGIN              = OPEN / 401
MAIN11_UNAVAILABLE         = OPEN IN SERVED RUNTIME
COMPANIES_SW               = OPEN / 404
CLOUDFLARE_ARTIFACT_ID     = UNKNOWN
DEPLOYMENT_ROOT_MAPPING    = UNKNOWN
GOLD                       = UNPROVEN
DIAMOND                    = UNPROVEN
CLOSED_100_PERCENT         = NO
```

## P143 REPAIR RECORD
### Code / workflow changes made
- `tools/run_final_main_reconstruction_20260831.py`
  - strips trailing forensic `RAWAEA_*` HTML sentinels from fragments
  - phase-by-phase JavaScript syntax isolation
  - canonical Service Worker registration repair
  - runtime Supabase key declaration normalization
- `.github/workflows/forensic_main_assembly.yml`
  - target changed from `Current/PWA/main.html` to `Current/PWA/New-main`
  - structural gates and Browser Smoke now exercise the actual target artifact
  - persist step saves `Current/PWA/New-main`

### Deliberately NOT changed
- Supabase schema / Auth users / owner profile
- Role permissions
- `Current/PWA/main.html`
- historical reports
- Cloudflare deployment by assumption
- fabricated `/companies/sw.js`

## MANUAL DEPLOYMENT CONTRACT
The only confirmed direct product target is:

`Current/PWA/New-main` → `erp-frontend/companies/company-1/main.html`

Do not copy any other file unless its current Git content is shown to differ from the published source and the difference is recorded.

Before manual publish:
- keep the currently published `main.html` as a rollback backup
- copy only the files explicitly listed as changed by the next verified artifact comparison

After manual publish, perform a clean-session test:
1. `RAWAEA ERP BOOTING...`
2. no `MAIN11_SUPABASE_UNAVAILABLE`
3. login succeeds
4. session restoration succeeds
5. tenant/company context resolves
6. owner license tab appears when owner is logged in
7. `/companies/sw.js` returns HTTP 200
8. Service Worker scope is correct
9. no new uncaught console error blocks the application shell

## NEXT AUTHORIZED ACTIONS
1. Execute the corrected reconstruction pipeline and obtain direct proof that `Current/PWA/New-main` was rewritten.
2. Record the resulting target SHA and compare it to `erp-frontend/companies/company-1/main.html`.
3. Compare support files by exact content/SHA and produce the manual deployment list.
4. User manually publishes the exact list with rollback backups.
5. Re-test Production runtime from a clean browser session.
6. Only after runtime closure revisit Gold/Diamond.

## REPORTS
- Historical reports remain preserved.
- `doc/Draft/Reprots/تقرير7.md` remains preserved as the P140 historical execution report.
- `doc/Draft/Reprots/تقرير8.md` is the current P143 forensic reconstruction/runtime diagnosis report.

## FINAL FORENSIC JUDGMENT
The evidence does NOT support “lost file relationship” as the root cause.

The immediate root problem is:

`STALE SERVED ARTIFACT + BROKEN RECONSTRUCTION PIPELINE`

with two independently proven runtime/build contributors:

- legacy Service Worker relative path (`../sw.js`) → `/companies/sw.js` 404
- reconstruction contamination from HTML forensic sentinels inside JavaScript → `Unexpected end of input`

The Supabase 401 remains an OPEN runtime symptom, not a proven credential defect.

Production is not closed until the corrected artifact is actually published and the browser proves the complete login/bootstrap path.
