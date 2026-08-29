# RAWAEA ERP — MAIN PWA Forensic Execution Log

## Event
- Event ID: MAIN-PWA-20260829-001
- Timestamp: 2026-08-29T13:00:00+03:00
- Scope: Current/PWA/main.html forensic execution
- Directive: MANDATORY CTO DIRECTIVE — Prompt 86

## Pre-execution baseline
- main.html SHA: 34b1bd23f99ac08a797625ab2fd359b21bf140b4
- Production project: fiilmooggumokx
- Production latest migration verified: 20260828235117
- Current PWA companion files inspected: core.js, sw.js, register-sw.js
- Historical source inspected: Original/PWA/main.html

## Directly proven findings
1. `main.html` is the Parent ERP Shell and contains authentication, bootstrap, navigation, master data, sales, procurement, warehouse, finance, HR, CRM, audit and routing behavior. A wholesale rewrite was rejected.
2. Tenant context was not explicitly resolved from the authenticated `users` row before shell bootstrap.
3. `app_settings` was read with global `LIMIT 1` semantics in the parent shell.
4. The frontend used `meta.permissions || ['*']`, which can incorrectly grant wildcard permissions when metadata is absent. Production evidence shows wildcard is an OWNER semantic, not a safe generic fallback.
5. Multiple tenant-owned reads in the shell were not explicitly company-scoped. Production RLS is permissive for some operational tables, so the client must not rely on RLS alone.
6. The shell had a fail-open `forceEnterFallback()` path capable of opening the application after bootstrap failure.
7. Production has a canonical Vehicle Master contract: `vehicles` + `create_vehicle_atomic(...)`, with company validation and optional Mobile/Van branch initialization.
8. Direct client-side Physical Stock mutation was not accepted; Physical Stock remains a backend engine responsibility.

## New critical task: System Identity / Settings / Owner continuity
- Production `app_settings` was re-read directly. Current schema contains `company_name`, `company_logo`, `company_phone`, `store_name`, `store_logo`, `store_primary_color`, `store_secondary_color`, `payment_method`, `currency`, `delivery_fee`, `min_invoice_amount`, `tax_rate`, `main_branch_id`, and license state fields.
- Production owner row `owner@alrawae.com` was re-read directly. Current DB permissions are `[*]`, status `Active`; auth metadata retains `isOwner=true` and `permissions=["*"]`.
- Existing `RW_OwnerLicense` and owner-only navigation were found in Current; the task is restoration/continuity, not replacement.
- A critical backend drift was discovered: the deployed `save-settings` capability previously referenced non-existent `app_settings` columns (`vat_number`, `registered_name`, `business_address`) and lacked a real Owner gate for license mutations.

## Changes actually deployed
### Production
- `save-settings` Edge Function deployed as version 13, ACTIVE, JWT required.
- New backend contract authenticates through `auth_id`, resolves `users.company_id`, requires Active user, whitelists only current `app_settings` fields, validates `main_branch_id` against the same company, and allows license-field mutations only when both Auth metadata and DB permissions confirm OWNER wildcard semantics.

### Git executor
- `tools/p0_main_shell_repair_v2.py` updated in commit `59d6e1f1f9d786f26b2f21fb728b6404ff6e7099`.
- Executor now also restores app-settings-backed identity/branding bridge, adds OwnerContract protection, restores currency state, and converts bootstrap fallback to fail-closed.
- A second critical workflow trigger commit `4cba1498408596a5fb638e30d39b7d3eeecd08b2` was added, but its run created no jobs; it therefore was NOT treated as execution success.

## Production data findings
- Owner identity/permissions currently remain intact; no owner permissions or license state were altered.
- No production data repair was performed from assumption.

## Current limitation still under execution
- `Current/PWA/main.html` remains at the pre-executor SHA `34b1bd23f99ac08a797625ab2fd359b21bf140b4` at the time of this log update because the GitHub Actions executor has not yet executed its job.
- Therefore the main.html source transformation is NOT yet claimed as deployed or closed.
- Browser-authenticated E2E of the UI is not claimed until an actual browser runtime is available.

## Governance
No percentage completion is used. Closure is accepted only after Git + Production + runtime + regression evidence reconcile.
