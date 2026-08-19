# RAWAEA ERP — Warehouse Supervisor Team Tab Forensic Closure

Date: 2026-08-20

## Source Reconciliation

Investigated directly from GitHub and Production, including Prompt/Report 11 through 23, the historical `Original/PWA/warehouse/supervisor.html`, current `Current/PWA/warehouse.supervisor`, `Current/PWA/core.js` references, and the deployed `set_active_warehouse_role` RPC.

The historical/current contract is:

- base employee role remains `مخزني` / `أمين مخزن`;
- `active_warehouse_role` is the operational assignment;
- allowed operational assignments are `استلام`, `تحضير`, `تحميل`, `مرتجعات`, `تفريغ`, `أذونات`, `جرد`, `احتياطي`;
- visibility is company-scoped and restricted to workers whose branch scope overlaps the supervisor scope;
- assignment must be enforced by the Production RPC, not by direct browser writes to `users`.

## Implemented Change

`Current/PWA/warehouse.supervisor` was modified surgically in the Team tab only.

The previous immediate-save card UI was replaced by a searchable team table with:

1. worker identity;
2. base job role;
3. worker branch scope;
4. current operational task;
5. per-worker task dropdown;
6. unsaved-change indicator;
7. independent Save button per worker.

The save action remains routed through:

`set_active_warehouse_role(p_user_id, p_role)`

No direct `users.update(...)` was introduced.

All existing Login/Auth, Dashboard, Live Monitoring, branch scope logic, worker filtering, and existing RPC security boundaries were preserved.

## Production Verification

Verified directly that:

- `warehouse.supervisor@rawaea.com` is active, role `مشرف مخازن`, company `00000000-0000-0000-0000-000000000001`, branch scope `BR-01`.
- `receiver@rawaea.com` is active, role `مخزني`, same company, branch scope `BR-01`, current task `استلام`.
- `set_active_warehouse_role` remains SECURITY DEFINER with company, warehouse-role, closed-task-list, and branch-overlap enforcement.
- A positive Production RPC test was executed inside a transaction using the supervisor JWT subject and `receiver` target, assigning `جرد`; the transaction was rolled back and the final Production state remained `استلام`.

## Git State

File update commit: `804d5c82d0ae32bf56003b73de1803a106fd2ba3`

Final removal of temporary execution workflow: `8cdad66c46e188280fe588aca1d3d22246da1f40`

The temporary workflow was removed immediately after the file write so no execution artifact remains in the repository.

## Closure

Warehouse Supervisor — Team scope: VERIFIED

Warehouse Supervisor — Individual operational assignment: VERIFIED

Table + per-worker dropdown + per-worker Save: IMPLEMENTED

Direct browser write to `users`: NONE

Production mutation test contamination: NONE

Existing supervisor application functions preserved: YES
