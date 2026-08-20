# RAWAEA ERP — Warehouse Supervisor Team Read-Scope Forensic Fix

Date: 2026-08-20

## Incident

`Current/PWA/warehouse.supervisor` showed an empty `فريقي` table although Production contained active warehouse workers in the supervisor's branch scope.

## Evidence

Production contained 5 active `مخزني` users in company `00000000-0000-0000-0000-000000000001`, all scoped to `BR-01`:

- `vouchers@rawaea.com` — أذونات
- `receiver@rawaea.com` — استلام
- `picker@rawaea.com` — تحضير
- `loader@rawaea.com` — تحميل
- `returns@rawaea.com` — مرتجعات

The warehouse supervisor is `warehouse.supervisor@rawaea.com`, with `warehouse_supervisor` permission and scope `BR-01`.

The `public.users` SELECT policy permits a user to read company rows only when the user has permission `users`; otherwise the policy permits only the user's own row through `auth_id = auth.uid()`.

The previous `loadStaff()` implementation queried `public.users` directly for all company members. Because the supervisor does not have the `users` permission, the query returned no team rows under RLS.

The existing team-table renderer was already present in the file, including the requested columns, per-worker task dropdown, individual Save button, search, pending/saved state, and mobile layout. The failure was therefore a data-access contract defect, not a missing UI implementation.

## Production Fix

Created:

`public.get_warehouse_team()`

Properties:

- `SECURITY DEFINER`
- company-scoped
- authenticated supervisor authorization
- derives supervisor scope from `default_branch_id` / `allowed_branch_ids`
- returns only active warehouse workers (`مخزني` / `أمين مخزن`) with overlapping branch scope
- returns scope metadata and member list
- does not widen `public.users` RLS

Grants:

- `authenticated`: EXECUTE
- `service_role`: EXECUTE
- revoked from `PUBLIC` and `anon`

Migration:

`20260820_warehouse_supervisor_team_read_scope`

## Application Fix

Only `Current/PWA/warehouse.supervisor` was modified in the application.

`loadStaff()` now calls:

```js
supabase.rpc('get_warehouse_team')
```

and hydrates:

- `companyId`
- supervisor branch scope
- branch rows
- `staffList`

The existing table and role-save workflow were preserved. Role writes continue through `set_active_warehouse_role()`.

Git commit:

`5c6c0612f6cc7473c38853c26d6e4f7bb6d1b249`

Final blob:

`38efd5eccf83a5540a1fa29689b93beaa75c7adf`

## Runtime Verification

Using the real supervisor Auth identity in a transaction, `get_warehouse_team()` returned:

- scope: `BR-01`
- member count: `5`
- all five expected warehouse workers

The transaction was rolled back after verification.

`set_active_warehouse_role()` was also positively verified in a rollback transaction for `receiver@rawaea.com -> جرد`.

## Important Distinction

This closes the **source and Production read-path defect** that caused the empty table. It does not, by itself, prove that an external hosting layer has already served the new Git `main` commit to the browser.

Therefore:

- Source/Git: CLOSED
- Production RPC: DEPLOYED + VERIFIED
- Browser/hosting runtime: requires the hosting layer to serve commit `5c6c0612...`

No RLS broadening, password change, Auth mutation, or direct `users` update was introduced.
