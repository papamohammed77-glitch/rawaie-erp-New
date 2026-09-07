# SMART ERP — Daily Project Memory

This file is the verified cross-system memory snapshot for the daily review.

## Sources
- GitHub: `papamohammed77-glitch/rawaie-erp-New` (default branch `main`)
- Supabase: `SMART ERP` (`fiilmooggumokxanwiyx`)

## Protected rules
- Do not store passwords, access tokens, service-role/secret keys, session secrets, or other credentials.
- PostgreSQL/Supabase production evidence outranks reports and self-attestation.
- Git chronology/source content does not prove deployment or browser runtime.
- Preserve owner authorization semantics; do not replace owner wildcard permissions with guessed role enumerations.
- `Current/PWA/New-main` remains the canonical application target; PWA consumers remain interfaces/orchestration surfaces, not business authorities.
- `UNKNOWN != BUG`; do not claim closure without current evidence.

## Verified continuity — 2026-09-07 automation refresh
### GitHub
- Latest observed main commit: `4be6fecef4bb4cc4fa5aebdc76e1f5d5568699cd` (`Update CURRENT_STATE after Report76 main5 forensic continuation`, 2026-09-07T10:15:16Z).
- Current `CURRENT_STATE.md` checkpoint identifies `c7aee872815564b910d7258d5918e550e66dc9da` as the forensic checkpoint and `Current/PWA/main2/main5.md` as the active target for the next surgical patch set.
- `Current/PWA/New-main` remains present and structurally rich, but this refresh did not modify application code, workflows, Supabase schema, Edge Functions, policies, secrets, or production data.
- Fresh browser/runtime parity and commit-specific product CI PASS remain unconfirmed in the current source set.

### Current closure units
- Main4 source is recorded as structurally closed after the corrected M4-01 block; runtime, 11-part integration, and full PWA runtime remain open.
- Main5 source is open with exact surgical changes M5-01..M5-12 and M5-14 identified for company scoping, authorized write boundaries, and currency binding; M5-13 delete-runsheet remains an open contract and must not be invented.
- No new evidence authorizes reopening Main2 or changing `Current/PWA/New-main` in this refresh.

### Supabase health and schema
- Project `SMART ERP` (`fiilmooggumokxanwiyx`) is `ACTIVE_HEALTHY`, region `eu-west-1`, PostgreSQL `17.6.1.121`, release channel `ga`.
- Latest migration is `20260905080418` `inventory_log_branch_attribution_contract`.
- Production schema directly confirms tenant-linked companies/branches/users/settings, centralized inventory movement with `source_branch_id` and `target_branch_id`, order/runsheet relationships, accounting tables, audit log, and RLS enabled across inspected public tables.
- Current inspected row counts include: companies=1, branches=2, users=24, roles=20, customers=3, suppliers=1, items=17, orders=0, runsheets=0, stock_branches=20, inventory_log=3, journal_entries=2, audit_log=1868.

### Edge Functions and authorization
- Core business Edge Functions observed are ACTIVE and JWT-protected (`verify_jwt=true`) across master data, sales, runsheets, picking/loading/delivery/returns, stock vouchers, purchasing, accounting, reporting, and vehicle operations.
- Historical test/canary/fixture/gate/recovery functions remain ACTIVE with `verify_jwt=false`, including picking harness/E2E, owner recovery, auth verification, receive-purchase runtime E2E, and sales canary functions. This is a confirmed attack-surface/lifecycle risk; no retirement or hardening was applied in this refresh.

### Fresh security advisories — observed 2026-09-07T10:22:31Z
- `public.create_item_with_opening_stock(...)` is executable by both `anon` and `authenticated` as `SECURITY DEFINER`.
- `public.sync_company_main_branch_projection()` is executable by both `anon` and `authenticated` as `SECURITY DEFINER`.
- Supabase Auth leaked-password protection is disabled.
- No security remediation was applied in this refresh.

### Fresh performance advisories — observed 2026-09-07T10:22:37Z
- Unindexed foreign keys remain across inventory, orders, runsheets, purchasing, accounting, vehicle, workflow, and related tables, including both `inventory_log` branch foreign keys.
- RLS init-plan warnings remain across multiple operational, notification, owner, receiving, financial, and workflow tables.
- Multiple permissive-policy warnings remain on `customer_assignments`, `fulfillment_backorders`, `receiving`, and `receiving_details`.
- Unused-index findings remain across items, vehicles, orders, finance, workflow, coupons, installments, and related tables.
- No performance DDL changes were applied in this refresh.

## Cross-system reconciliation
- GitHub and Supabase remain directionally aligned around a centralized core, tenant-aware operations, explicit branch attribution, and JWT-protected business APIs.
- The primary unresolved risks are: open Main5 source patch set, unverified deployment/runtime parity, active `verify_jwt=false` historical surface, public EXECUTE on two `SECURITY DEFINER` functions, RLS policy/performance debt, and unresolved delete-runsheet business ownership.
- Production business-data writes in this refresh: `0`.
- Secrets, passwords, keys, tokens, or credential material stored/disclosed: `0`.

## Confidence boundary
```text
REPOSITORY/PROJECT IDENTITY = CONFIRMED
LATEST OBSERVED MAIN COMMIT = CONFIRMED
SUPABASE HEALTH = CONFIRMED
LATEST MIGRATION = CONFIRMED
SCHEMA / RELATIONSHIPS / RLS = CONFIRMED (inspected scope)
CORE JWT-PROTECTED FUNCTIONS = CONFIRMED
ACTIVE verify_jwt=false TEST/RECOVERY SURFACE = CONFIRMED
SECURITY ADVISORIES = CONFIRMED (fresh)
PERFORMANCE ADVISORIES = CONFIRMED (fresh)
MAIN4 SOURCE STATUS = CONFIRMED CLOSED / RUNTIME OPEN
MAIN5 SOURCE STATUS = CONFIRMED OPEN / PATCH SET SPECIFIED
DEPLOYED REVISION = UNKNOWN
SERVICE WORKER/CACHE = UNKNOWN
FRESH BROWSER E2E = UNKNOWN
GOLD/DIAMOND/100% CLOSURE = NOT PROVEN
```

## Classification
### CONFIRMED
- Facts listed in the sections above that were returned directly by GitHub or Supabase in this refresh.

### HISTORICAL
- Prior reports, prior CI failures, prior closure labels, and prior workflow claims not re-proven against the current source/runtime.

### INFERRED
- GitHub source and Supabase schema are directionally compatible, but this does not prove deployed runtime parity.
- Main5 company-scope and currency issues are the next evidence-backed source corrections; no deletion capability should be invented.

### TARGET-CANDIDATE
- Next authorized code target: `Current/PWA/main2/main5.md` for the exact M5-01..M5-12 and M5-14 surgical edits documented in Report76.
- `Current/PWA/New-main` remains protected and should change only on new direct defect evidence.

## Open risks / next evidence
1. Apply and verify the exact Main5 patch set M5-01..M5-12 and M5-14.
2. Re-read the resulting Main5 source from first line to EOF and rerun structural/syntax checks.
3. Reconcile Main5 against current Production RLS and Edge Function ownership.
4. Obtain fresh browser/runtime proof against the exact current Git HEAD.
5. Reconcile deployed artifact and Service Worker/cache lineage.
6. Retire or harden obsolete `verify_jwt=false` functions only after dependency proof.
7. Revoke or narrow public EXECUTE on the two exposed SECURITY DEFINER functions.
8. Enable leaked-password protection.
9. Prioritize FK indexes and RLS policy rewrites.
10. Preserve historical evidence as historical unless re-confirmed directly.
