# RAWAEA ERP — Warehouse Supervisor Team Scope Rerun Forensic Closure

Date: 2026-08-20

## Governing source basis

Re-read Prompts 11 through 22 directly from `doc/Draft/Hussin/` before modification. Those documents were treated as historical execution context only; Production and current Git were authoritative for the final decision.

## Direct source comparison

Compared:

- `Current/PWA/warehouse.supervisor`
- `Original/PWA/warehouse/supervisor.html`
- `Current/PWA/core.js`
- Production `public.users`
- Production `public.branches`
- Production `public.set_active_warehouse_role(uuid,text)`

## Proven Production facts

- Warehouse Supervisor: `warehouse.supervisor@rawaea.com`
- Company: `00000000-0000-0000-0000-000000000001`
- Supervisor scope: `BR-01`
- Active warehouse workers currently visible in this company: 5
- Current Production does not contain an active `role = 'أمين مخزن'`; the accepted backend contract nevertheless allows both `مخزني` and `أمين مخزن`.
- Approved active warehouse tasks remain exactly:
  - استلام
  - تحضير
  - تحميل
  - مرتجعات
  - تفريغ
  - أذونات
  - جرد
  - احتياطي

## Root cause / gap proved

The current Team tab was company-scoped but not branch-scoped. It selected `role = 'مخزني'` for the whole company and did not display the supervisor's effective branch scope.

The current Production RPC already enforced the correct branch boundary and task allow-list, so no new RPC, RLS weakening, Auth change, or new role was required.

## Surgical application change

Only `Current/PWA/warehouse.supervisor` was functionally modified.

Preserved:

- Login/Auth behavior
- `NO_SESSION` handling
- Warehouse Supervisor authorization gate
- Dashboard
- Live monitoring
- Existing tab structure
- Existing operational task contract
- Existing RPC-based role update path

Added/changed only in the Team scope:

- Resolve supervisor scope from `default_branch_id` plus `allowed_branch_ids`.
- Filter workers to active users whose role is `مخزني` or `أمين مخزن` and whose branch scope intersects the supervisor scope.
- Display effective branch scope in a dedicated Team header.
- Display worker primary job role separately from active operational task.
- Add worker/task search.
- Show assigned vs reserve/non-assigned counts.
- Keep task switching exclusively through `set_active_warehouse_role`.
- Improve error handling and refresh behavior after rejected changes.

## Production runtime verification

### Positive

Using the real supervisor Auth subject and JWT permission context in a transactional database test:

`set_active_warehouse_role(receiver, 'جرد')`

returned:

`success = true`

with branch scope:

`["BR-01"]`

Transaction was rolled back.

### Negative branch isolation

Inside a transaction the target worker's branch scope was temporarily changed to `BR-2` and the same real-supervisor call was attempted.

Production rejected the operation with:

`لا يمكن تعيين دور لعضو خارج فرع المشرف`

The transaction was rolled back.

Final verification confirms the target worker remains:

`allowed_branch_ids = BR-01`

`active_warehouse_role = استلام`

No persistent test contamination exists.

## Git state

Application blob after the surgical update:

`8f2a0937e86fb8a722ddb6ca77500ec32d68c0fe`

Application commit:

`8966d8b1ccc2388ee9a6a25688fcadd5b62d5d98`

A temporary patch workflow was used during execution but was removed from `main` immediately afterward through a Git tree/commit operation.

Final cleanup commit:

`9105dce48ab850029f207b082d3a37d3c9ac5087`

## Syntax / source verification

The final JavaScript payload extracted from `Current/PWA/warehouse.supervisor` passed `node --check`.

The final file was re-read from Git `main` and confirmed to retain blob SHA:

`8f2a0937e86fb8a722ddb6ca77500ec32d68c0fe`

The temporary workflow path is now absent from `main`.

## Closure

Historical context reviewed: **DONE**

Original UI compared: **DONE**

Current source reconciled: **DONE**

Production company/branch/role contract proven: **DONE**

Team branch scoping implemented: **DONE**

Task switching implemented: **DONE**

Backend branch enforcement verified: **DONE**

Positive runtime test: **PASS**

Negative cross-branch test: **PASS**

Persistent test contamination: **NONE**

Final interactive browser login with an actual password: not independently asserted here because the password is not available to the agent.
