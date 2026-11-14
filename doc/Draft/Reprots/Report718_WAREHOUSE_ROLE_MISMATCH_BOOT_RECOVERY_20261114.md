# Report718 — Warehouse Role Mismatch Boot Recovery
**Date:** 2026-11-14 (Africa/Cairo)  
**Status:** READY WITH LIMITATIONS  
**Operational HEAD:** `71fa933b3b78fa480f2d50ffb292d1a5bd4f8fa9`

## Executive result
The reported boot failure is an intentional authorization rejection, not a failed core.js load. The current session profile has active warehouse role `مرتجعات`; the unified hub requires `مخزن شامل`. SMART ERP contains a separate active unified-storekeeper account and a separate returns account. The repair preserves the server-verified role gate and adds a safe account-switch recovery path instead of widening access.

## Verified cause
- Console reports `[Warehouse] boot failed` with current role `مرتجعات`.
- `core.js` hydrates `active_warehouse_role` through `get_my_effective_profile`.
- `warehouse.html` verifies the server-side `get_warehouse_hub_snapshot` role and requires `مخزن شامل`; rejection is fail-closed by design.
- SMART ERP `fiilmooggumokxanwiyx`: one active `storekeeper@rawaea.com` profile has job role `أمين مخزن` and active role `مخزن شامل`; one active `returns@rawaea.com` profile has active role `مرتجعات`.
- No user-role assignment or permission widening was performed. The approved supervisor path remains `set_active_warehouse_role`.

## Source changes
Commit `3058c881fc5341dc370b4c6866d7e53824cf9280`:
- `companies/company-1/warehouse/warehouse.html`: displays current account identity and role on mismatch; reveals a controlled “تسجيل الخروج وتبديل الحساب” action only for role mismatch; logs out through `RW_Auth.doLogout`, clears local app state and password, and returns to the login-ready state. Successful boot hides the recovery action.
- `.github/workflows/warehouse_hub_browser_e2e_20261110.yml`: extends restricted-role E2E to assert fail-closed behavior, identity disclosure, account-switch visibility, sign-out, and no accidental app access.

Commit `71fa933b3b78fa480f2d50ffb292d1a5bd4f8fa9`:
- Adds the two already-applied SMART ERP migrations to Git source history:
  - `supabase/migrations/20261114130015_warehouse_return_handler_display_users_20261114.sql`
  - `supabase/migrations/20261114130048_warehouse_operation_actor_display_users_20261114.sql`
- These migrations extend company- and permission-scoped `get_picking_display_users` to return return-handler and loader IDs. They were already applied to SMART ERP before this source-sync commit; this commit does not reapply them.

## Test evidence
- Warehouse E2E Run [43600194412](https://github.com/papamohammed77-glitch/erp-frontend/actions/runs/43600194412): **SUCCESS** on `3058c881`. Job log confirms `WAREHOUSE_ACTIVE_ROLE_GATE_AND_SAFE_ACCOUNT_SWITCH=PASS`, all six native workspaces, seven voucher actions, image refresh/fallback, stock preflight, branch-scope guards, parent Picking/Loading/Unloading histories and actor attribution, and zero data writes in the Parent history fixtures.
- Mother Inventory Forensic E2E Run [43600326868](https://github.com/papamohammed77-glitch/erp-frontend/actions/runs/43600326868): **SUCCESS** on `71fa933b`.
- Forensic Mother Assembly Guard Run [43600326851](https://github.com/papamohammed77-glitch/erp-frontend/actions/runs/43600326851): **SUCCESS**.
- RAWAEA forensic current Mother extract Run [43600326876](https://github.com/papamohammed77-glitch/erp-frontend/actions/runs/43600326876): **SUCCESS**.
- CTO Helper Files Forensic Run [43600326824](https://github.com/papamohammed77-glitch/erp-frontend/actions/runs/43600326824): **SUCCESS**.
- CI uses local fixtures/mocks. It does not prove authenticated Cloudflare Production behavior.

## Production safety snapshot
Read-only SMART ERP snapshot remained:
- `inventory_counts=1`
- `inventory_count_details=35`
- `inventory_log=83`
- `erp_operation_registry=98`

No new QA rows, stock postings, cash movements, accounting journals, custody entries, or inventory operations were created in this event. The active 35-line count session was not used.

## Non-blocking Console warning
The Tailwind CDN warning is unrelated to the role rejection. It is a production build warning, not the cause of the boot failure. It was intentionally left out of this authentication repair to avoid an unrelated CSS/build-system change.

## Remaining verification
- Cloudflare deployed artifact for HEAD `71fa933b` is **UNVERIFIED** in this session.
- Authenticated browser runtime on the user's Production session is **UNVERIFIED**.
- The account intended for use must be the already-authorized unified-storekeeper account or be assigned through the approved warehouse-supervisor path. No user-role data was changed.

## Decision
**READY WITH LIMITATIONS** for source and CI. **Production runtime/deployment acceptance remains open.** No stock, treasury, accounting, custody, or inventory balances were changed.
