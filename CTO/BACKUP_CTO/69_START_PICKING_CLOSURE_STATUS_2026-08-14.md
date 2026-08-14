# START-PICKING CLOSURE STATUS — 2026-08-14

## SELF-AUDIT

Business Understanding: 99/100  
Architecture Understanding: 98/100  
Database Understanding: 98/100  
Historical Understanding: 95/100  
Production Understanding: 99/100  
Current Understanding: 99/100  
Execution Confidence: 97/100

## STATUS

`INCOMPLETE — TEMPORARY HARNESS REGISTRY CLEANUP ONLY`

## SOURCE EVIDENCE

- Historical: `rawaie-erp-review/Edge_Functions/original/02_picking/start-picking.ts`
- Historical SHA: `ba03d87e2db3ca68a08e3a0ca170200fcf9ab700`
- Active Original: no `start-picking` file exists under `rawaie-erp-New/Original/Edge Functions`; Historical + Production were used to recover the Current baseline. No Original file was modified.
- Current: `Current/Edge_Functions/start-picking`
- Current content SHA: `a3cfee6b80d059c1a3dd1cf6f5b989706267ee92`
- Git change commit: `b3994f31a1347c190e2240d7896de7f72faa4bf1`
- Production version: `v13`
- Production package SHA: `db59f78f6045ff3ed29fc518e04adcab6bb72e2e63171fa36b4bfc6076b4de5a`

## RESPONSIBILITY MATRIX

| Responsibility | Historical | Production Before | Current | Production v13 | Target |
|---|---|---|---|---|---|
| JWT/Auth | YES | YES | YES | YES | RETAIN |
| Company context | hard-coded/absent | drifted | company-scoped | company-scoped | RETAIN |
| Picker identity | public.users by email | same | company-scoped public.users | company-scoped | RETAIN |
| Open/Confirmed guard | YES | YES | YES | YES | RETAIN |
| Picking state mutation | YES | YES | conditional + row-count gate | same | RETAIN |
| Concurrency rejection | NOT SAFE | NOT SAFE | FIXED | FIXED | REQUIRED |
| Physical stock mutation | NO | NO | NO | NO | NONE |
| inventory_log | NO | NO | NO | NO | NONE |

## FINDINGS AND FIXES

### P0 — concurrency success-with-zero-row risk
Fixed by conditional update + `.select(...)` + exact `updatedRows.length === 1` check.

### P1 — company isolation drift
Fixed by scoping public user and runsheet lookups to `app_settings.company_id` / `company_id`.

### P1 — Production/Current provisioning drift
Production v12 contained a canary-specific `password_hash` sentinel. Current and Production v13 are now aligned on the required NOT NULL field with a non-recoverable random hash filler when a public user must be created.

## TEST RESULTS

### Staging HTTP E2E
- Open -> Picking: PASS
- Confirmed -> Picking: PASS
- Invalid state: PASS
- Retry: PASS
- Concurrent pair: one HTTP 200 / one HTTP 400: PASS
- Missing runsheet: PASS
- Company isolation with second company: PASS
- picker_id and picker_start persisted: PASS
- Baseline restoration: PASS
- Auth/public test cleanup: PASS

### Production HTTP Canary
- Open -> Picking: PASS
- Confirmed -> Picking: PASS
- Invalid state: PASS
- Retry: PASS
- Concurrent pair: one HTTP 200 / one HTTP 400: PASS
- Missing runsheet: PASS
- Production baseline restored: PASS
- Auth/public temporary user cleanup: PASS

## CONSUMER

`Current/PWA/main.html` invokes:
`POST /functions/v1/start-picking`
with:
`Authorization: Bearer <session access token>`
and payload:
`{ runsheet_code: rsCode }`.
Success is handled through `startJson.success`; failure through `startJson.msg`.

## TEMPORARY TEST ARTIFACTS

GitHub workflow and trigger marker were deleted from the active branch.

Two temporary Supabase Edge Functions remain registered but are now inert HTTP 410 handlers:

- `start-picking-closure-harness` — Staging — ACTIVE registry, inert 410
- `start-picking-production-harness` — Production — ACTIVE registry, inert 410

The active registry status is the only remaining closeout defect.

## FINAL GATE

All `start-picking` business/function gates are PASS.

Formal `100% RELEASE-COMPLETE` is withheld until the two temporary Edge Function artifacts are deleted from Supabase registry and verified absent by `list_edge_functions`.

## SELF-AUDIT FINAL

### What I Proved
The corrected `start-picking` passed staging and production HTTP tests, including retry, concurrency, company isolation, state validation, picker identity, and baseline restoration.

### What I Did Not Prove
Deletion of the temporary Supabase harness artifacts is not yet evidenced because the connected Supabase action surface has no Delete Edge Function operation.

### What I Fixed
Company context and concurrency row-count validation; Production v13 deployed from Current source.

### What I Initially Missed
The original Production v12 path could return success without proving a row was actually transitioned under concurrent access.

### What Could Still Be Wrong
Only the governance status of the temporary test artifacts remains open for this Closure Unit.

### Final Confidence
97/100 until registry cleanup is verified.
