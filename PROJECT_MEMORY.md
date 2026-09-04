# SMART ERP — Daily Project Memory

This file is the verified cross-system memory snapshot for the daily review.

## Sources
- GitHub: `papamohammed77-glitch/rawaie-erp-New` (default branch `main`)
- Supabase: `SMART ERP` (`fiilmooggumokxanwiyx`)

## Protected rules
- Do not store passwords, access tokens, service-role/secret keys, session secrets, or other credentials.
- PostgreSQL/Supabase production evidence outranks reports and self-attestation.
- Git chronology/source content does not prove deployment or browser runtime.
- `Current/PWA/New-main` is the canonical current application target; PWA consumers remain interface/orchestration surfaces, not business authorities.
- Preserve owner authorization semantics; do not replace owner wildcard permissions with guessed role enumerations.

## Historical context
### 2026-09-03 — initial and forensic continuity baseline
- Supabase connectivity verified.
- Prior reviews recorded the PWA/Core/Edge-Function/PostgreSQL separation, Supabase Auth + bearer JWT pattern, and owner/license continuity constraints.
- The production owner record was previously verified as active with wildcard permissions `["*"]`, linked owner profile, and active license; no production write was performed.
- Earlier continuity notes recorded security/performance advisories, stale recovery/test function surface, and lack of fresh full-browser Gold/Diamond proof.

## Verified review — 2026-09-04
### GitHub
- Latest observed `main` HEAD: `4b93e9178397028b6345c3a863d65e659a696331`, committed `2026-09-04T10:10:10Z`, message: `[CTO] Sync CURRENT_STATE with Report50 and corrected main ancestry`.
- Immediately preceding commits include Report50 forensic inventory/reconciliation (`391de3fb38cb63f5c9ea6a3e62a91a5a3727a1a6`) and the prior CURRENT_STATE sync (`8d64f747cdf06cd4197a379b7697b1855ecefeca`).
- `CURRENT_STATE.md` now explicitly corrects chronology: several 2026-09-03 commits touched `Current/PWA/New-main`, but their parent chains are alternate/independent; they are not proof that their intermediate artifacts are current `main` state.
- Current-state direct evidence identifies `Current/PWA/New-main` as a full HTML/CSS/JS PWA artifact with blob `22f4ee1a666141be62127159337beffb05e8b146` and size `575336` bytes. Current login source values include `rw-login-title = 58px` and `rw-login-logo = 88 × 88`; historical Original values are larger, but regression is not proven.
- Current source contract includes Supabase Auth restoration, derived `isOwner`/permissions, `RW_API` Edge Function calls using the authenticated session token, shared Dexie/local-storage runtime, and service-worker update/reload coordination. License route/source is confirmed; browser visibility, deployed revision, and cache state remain unknown.
- Current PWA consumer inventory is broad (sales/order, warehouse, driver/delivery, purchasing/finance/management, owner/general, store, vouchers) and is documented as consumers of the shared RAWAEA ERP boundary.
- Combined status query for the latest HEAD returned an empty status list. This is not evidence of passing CI; CI visibility remains unresolved.
- No verified new product-source mutation beyond the documented chronology correction was established in this review; no deployment proof was established.

### Supabase production
- Project `SMART ERP` is `ACTIVE_HEALTHY`, region `eu-west-1`, PostgreSQL `17.6.1.121`.
- Public business tables observed include companies, branches, users, roles/role_permissions, app_settings, items, customers, suppliers, orders/order_details, runsheets/run_sheet_details, stock and voucher tables, purchasing, accounting/treasury, audit/workflow/notification tables, vehicle/delivery/complaint/credit tables, and supporting registries. All observed public tables in the reviewed schema had RLS enabled.
- Schema confirms the owner/auth model fields (`users.auth_id`, `users.role_id`, `users.permissions`, `owner_profile.auth_user_id`, `owner_profile.license_status`) and the inventory invariant (`stock_branches.available_qty = qty - allocated_qty`).
- Edge Functions: a large active business surface is present for CRUD, orders/sales, runsheet/picking/loading/delivery/returns, stock vouchers, purchasing, accounting/reporting, audit, and supporting workflows. Observed business functions use `verify_jwt = true`.
- Separate historical/test/recovery-style functions remain active with `verify_jwt = false`, including canary, fixture, runtime-E2E, owner-recovery, and auth-verification names. This is a confirmed authorization/attack-surface risk until each function is classified as intentionally public, test-only, or obsolete.
- No schema migration or Edge Function deployment was performed by this review.

### Logs / advisories
- Prior and current review evidence includes successful `log-action` traffic (HTTP 200; OPTIONS 204) and repeated HTTP 410 calls to `owner-recovery-20260818`, proving that a retired/expired recovery path is still being called by some actor or test path.
- Security advisories observed `2026-09-04`: anonymous and authenticated roles can execute SECURITY DEFINER functions `public.create_item_with_opening_stock(...)` and `public.sync_company_main_branch_projection()`; Supabase Auth leaked-password protection is disabled.
- Performance advisories observed `2026-09-04`: many unindexed foreign keys across business tables; repeated RLS init-plan warnings where `auth.*()`/`current_setting()` are re-evaluated per row; multiple permissive policies on customer assignments, receiving, receiving details, and related surfaces; and multiple unused indexes. These are database-level findings, not proof of a current PWA regression.

## Reconciliation / material changes
- GitHub and Supabase remain architecturally consistent: PWA/UI → shared runtime → Edge Functions/RPC → PostgreSQL as system of record.
- No verified auth-flow redesign, RLS disablement, schema-breaking change, or production deployment was established in this review.
- The material change since the prior snapshot is documentation/continuity correction on GitHub, not a proven application or database deployment change.

## Open risks / next actions
1. Revoke or narrow `EXECUTE` on the two exposed SECURITY DEFINER RPCs unless public access is intentional.
2. Enable leaked-password protection in Supabase Auth.
3. Identify and remove/update the caller of repeated `owner-recovery-20260818` 410 requests.
4. Review every `verify_jwt = false` Edge Function and retire obsolete/test-only functions or add explicit custom authentication where required.
5. Restore meaningful CI status visibility for the current `main` HEAD; empty status is not pass.
6. Plan a controlled DB performance pass for FK indexes, RLS init-plan rewrites, duplicate permissive policies, and unused-index review.
7. Obtain fresh browser/runtime evidence before claiming deployed revision, cache correctness, login success, license-tab visibility, or whole-system Gold/Diamond closure.

## Confidence boundary
- Confirmed: repository/project identity, current `main` HEAD and continuity documents, current New-main source contract, Supabase health, reviewed schema/RLS posture, Edge Function inventory pattern and `verify_jwt` split, advisory categories, and known 410 recovery-call pattern.
- Not confirmed: full current PR/issue closure history, fresh end-to-end browser execution, exact current production login success for a real user, deployed revision/cached artifact identity, or whole-system acceptance closure.
