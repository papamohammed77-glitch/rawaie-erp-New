# Production Evidence — Owner Login / Company Main Branch Compatibility

**Date:** 2026-09-02
**Production project:** `fiilmooggumokxanwiyx` (`SMART ERP`)
**Migration version:** `20260902023122`
**Migration name:** `compatibility_company_main_branch_projection_20260902`

## Observed Failure

The live application authenticated the owner successfully, then failed while reading:

`companies?id=eq.00000000-0000-0000-0000-000000000001&select=id,name,logo_url,main_branch_id,main_branch_code`

PostgreSQL returned:

`column companies.main_branch_id does not exist`

## Production Facts

- Supabase password authentication for `owner@alrawae.com` returned HTTP 200.
- The authenticated user row is active and belongs to company `00000000-0000-0000-0000-000000000001`.
- Owner authorization contract remains `permissions=["*"]` plus `owner_profile` and active license state.
- `app_settings.main_branch_id` is the authoritative main-branch source.
- The owner company's authoritative main branch is `a38332b6-6cea-480a-ada1-6eb6ab0590db` / `BR-01` / `الفرع الرئيسي`.
- Before this migration, `companies` did not expose `main_branch_id` or `main_branch_code`.

## Surgical Fix

A compatibility read projection was added to `companies`:

- `companies.main_branch_id`
- `companies.main_branch_code`

These columns are explicitly documented as projection-only. They do not become the business source of truth.

A trigger keeps the projection synchronized from `app_settings.main_branch_id` and the matching company-scoped branch code.

The migration also backfilled the projection from existing authoritative settings.

## Verification

Production verification after deployment showed:

- `companies.main_branch_id = app_settings.main_branch_id`
- `companies.main_branch_code = branches.branch_code`
- `projection_in_sync = true`

A transactional trigger test updated `app_settings.main_branch_id` to itself and confirmed the projection remained synchronized; the test transaction was rolled back.

## Runtime Boundary

The exact browser-side HTTP 200 for the retried `companies` request could not be observed directly from this execution environment. No new `42703` event was observed in the subsequent Production API/PostgreSQL log snapshot.

Therefore:

`DB_SCHEMA_FIX = VERIFIED`
`OWNER_CONTEXT = VERIFIED`
`PROJECTION_SYNC = VERIFIED`
`BROWSER_RETRY_HTTP_200 = NOT_DIRECTLY_OBSERVED_HERE`

## Architectural Rationale

Adding physical business ownership of the main branch to `companies` would create a competing source of truth. The implementation instead treats the new columns as an explicit compatibility boundary for the already-served frontend contract while preserving `app_settings.main_branch_id` as authoritative.
