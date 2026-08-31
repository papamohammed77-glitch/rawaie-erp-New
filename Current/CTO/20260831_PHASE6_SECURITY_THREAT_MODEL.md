# RAWAEA ERP — PHASE 6 SECURITY / TENANT ISOLATION ASSESSMENT

**Date:** 2026-08-31  
**Phase:** 6 — Security & Authorization Forensics  
**Status:** CLOSED  
**Production mutation:** None.

## POSITIVE CONTROLS PROVEN

1. Critical business tables inspected in Phase 2 have RLS enabled.
2. `app_private.current_user_company_id()` is a `SECURITY DEFINER`, `STABLE` function that resolves `company_id` from `users.auth_id = auth.uid()` and excludes inactive users.
3. `app_private.current_user_has_permission()` is a `SECURITY DEFINER`, `STABLE` function using `users.auth_id = auth.uid()` and role/user permissions.
4. Critical writer RPCs such as `post_stock_movement`, `reserve_stock`, `release_stock_reservation`, `receive_purchase_atomic`, and voucher atomic functions expose `EXECUTE` to `service_role` in the inspected privilege snapshot rather than to anon/authenticated roles.
5. Several direct table policies correctly use `app_private.current_user_company_id()` to enforce tenant isolation.

## P0 SECURITY FINDINGS

### S-001 — Orders are not tenant-isolated for authenticated direct table access

Current Production policy `allow_all_orders` is `FOR ALL` and applies to `public`, with `USING (auth.role() = 'authenticated')` and `WITH CHECK (auth.role() = 'authenticated')`.

Current table grants also give `authenticated` and `anon` broad table privileges on `orders`.

The policy checks only authentication state; it does not bind rows to `company_id` or to a company-scoped business permission. Therefore an authenticated user is not structurally constrained by this RLS policy to their tenant when accessing `orders` directly.

Current business data has zero orders, so there is no evidence of an already-exposed cross-tenant order row in the current dataset. The structural authorization defect remains P0 because it becomes exploitable as soon as more than one tenant has business data.

### S-002 — Order details are not tenant-isolated for authenticated direct table access

Current Production policy `allow_all_order_details` similarly allows `ALL` for `public` whenever `auth.role() = 'authenticated'`.

`order_details` has broad authenticated and anon table grants. The policy does not enforce the parent order's company context.

Because `order_details` is a child table of `orders`, tenant isolation must be derived through the order relationship or through another authoritative company predicate. Authentication alone is insufficient.

### S-003 — Run-sheet details are not tenant-isolated for authenticated direct table access

Current Production policy `allow_all_run_sheet_details` allows `ALL` when authenticated, without a company predicate on the row or parent runsheet.

`run_sheet_details` has broad authenticated and anon table grants. This permits structurally broad direct access to a child fulfillment table unless application code prevents direct table access everywhere.

The system cannot rely on application routing as the sole protection because the database is itself exposing an RLS policy that does not enforce tenant isolation for these records.

### S-004 — Daily settlements are globally readable through RLS policy

Current Production policy `Allow all for all` on `daily_settlements` is `FOR ALL`, `USING true`, and `WITH CHECK true`.

Current table grants observed for anon/authenticated are `SELECT`; service role has mutation privileges. Therefore the immediately proven impact is broad read visibility, not arbitrary client-side mutation under the current grants.

`daily_settlements` contains operational/financial settlement information and should be company-scoped at the RLS layer.

## SUPPORTING SECURITY OBSERVATIONS

### CORS

Several current Edge Function wrappers, including `save-sales-invoice` and `complete-loading`, use `Access-Control-Allow-Origin: *`. Server-side authentication is still performed, so this alone is not proof of unauthorized access. It is a hardening concern and must be reviewed against the intended production origin policy.

### Authentication linkage anomaly

The current Production snapshot contains one `public.users` row with `auth_id IS NULL`. This may be an intentionally pre-provisioned/inactive account, but until provenance is established it cannot be considered compliant with an auth-linked tenant model for an active user.

### Historical security drift

The July security model recorded missing RLS on multiple finance tables as a P0 gap. Current Production shows RLS enabled on those inspected tables, proving that part of the security model was materially improved. The current P0 findings are a different class of flaw: policies exist but are too broad in some key child/business tables. fileciteturn41file0L2-L2

### Retired endpoint activity

Production Edge logs show repeated calls to historical/test-style endpoints returning 410. This is an attack-surface / dependency-hygiene concern, but consumer attribution is required before deletion or routing changes.

## SECURITY VERDICT

`NOT READY FOR PRODUCTION ENGINEERING`

The current system has meaningful defense-in-depth controls, but the tenant-isolation layer is not uniformly enforced. The presence of broad authenticated RLS policies on core order/fulfillment tables is sufficient to block any final production-readiness certification at this stage.

## REQUIRED SECURITY REMEDIATION DESIGN (NOT EXECUTED HERE)

The following are design requirements for later implementation, not changes executed in Phase 6:

1. Replace broad authenticated `ALL` policies on `orders`, `order_details`, and `run_sheet_details` with explicit operation-specific policies using authoritative company context and, where necessary, parent-record joins.
2. Constrain `daily_settlements` SELECT to the current user's company and appropriate role/permission.
3. Determine whether direct table grants to anon/authenticated are still required for each affected table; prefer least-privilege access and canonical Edge/RPC writers for mutation.
4. Prove all specialized child tables have tenant enforcement through either direct `company_id` or a secure parent relation.
5. Re-test cross-tenant SELECT/INSERT/UPDATE/DELETE behavior with two-tenant fixtures in a non-production validation environment before any Production policy change.
6. Perform a complete policy/function privilege review rather than patching only these four tables.

## EXIT GATE

`PHASE 6 CLOSED`

Security and authorization behavior has been inspected at the RLS policy, tenant-context function, and table-grant levels. P0 security findings are recorded. No Production security policy or data was modified.
