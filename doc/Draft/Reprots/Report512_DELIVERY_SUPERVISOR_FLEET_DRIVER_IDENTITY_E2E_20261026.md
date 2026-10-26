# Report512 — Delivery Supervisor / Fleet Driver Identity Integration: Fresh Production E2E and Closure Gap
**Date:** 2026-10-26  
**Live Production observation:** 2026-10-26 17:40:45.680660 UTC, PostgreSQL 17.6  
**Repositories:** `papamohammed77-glitch/rawaie-erp-New` (contracts/reports) and `papamohammed77-glitch/erp-frontend` (operational source, main)  
**Status:** `PARTIAL — RPC/SQL TRANSACTIONAL E2E PASS; FLEET DRIVER HAS NO LOGIN IDENTITY; UI/DELIVERY LIFECYCLE NOT CLOSED`

## 1. PRE-CHANGE SELF-AUDIT

| Area | Evidence-based assessment | Boundary |
|---|---|---|
| Business understanding | 98/100 | Driver vs delivery representative are distinct duties; money/product liability semantics still need full consumer/ledger reconciliation. |
| Architecture | 98/100 | Parent/Fleet owns vehicle + `runsheets.driver_id`; Delivery Supervisor owns `runsheets.deliverer_id`. |
| Production synchronization | 100/100 for the read snapshot and the rollback-only RPC test in this session | Does not mean all delivery consumers or live HTTP behavior are synchronized. |
| Database understanding | 98/100 | Existing Fleet driver master, users, runsheet identity columns, and operation registry were inspected live. |
| Consumer trace | 78/100 | Current supervisor/driver source and active Edge contracts inspected; no authenticated Browser/HTTP E2E. |
| Runtime verification | 70/100 for SQL transaction tests only | Real JWT/HTTP and served Cloudflare HTML not verified. |
| Execution confidence | 95/100 for the tested RPC contract; 65/100 for end-to-end workflow | Do not treat component success as system closure. |

**Confirmed:** Production RPCs exist and ACL is correct; a rollback-only Production transaction passed assign/retry/unassign assertions; the Fleet driver record exists but is not linked to a login user or a vehicle; current operational UI/Edge still contain the old `driver_id` consumer contract.

**Unknown / unverified:** authenticated HTTP/JWT, browser-served HTML parity, full lifecycle delivery/collection/return/ledger behavior, whether an actual browser session can use the latest UI, and whether the owner has applied Report511 source patches.

## 2. Latest state and sources re-opened

- Read `CURRENT_STATE.md`; latest prior event was `LVE-2026-10-26-511`. Its prior claim that the new assignment RPCs were deployed is freshly checked below rather than trusted as proof.
- Operational source repository `erp-frontend`, main:
  - `companies/company-1/delivery/supervisor.html`: blob `4108d2330e567c432f08197013b9c3cf6221a5c7` (229 lines).
  - `companies/company-1/delivery/driver.html`: blob `2df69860184f5a7c1b211ba059e1d6f57826c96b` (1,755 lines).
  - `companies/company-1/core.js`: blob `ff2f581d9900543c16f7cb026e13446520c0329d` (773 lines).
  - `companies/company-1/app.html`: blob `ec75f89c11620f6e8b8ef5996cf1a3289dcf20b4` (222 lines).
  - Latest repository commit observed: `40161bb3bef28cf6d8d2d6ba7938ee8807a63c23` (2026-10-26T13:16:45Z). The delivery source blob SHAs above still match.
- Canonical migration:
  `supabase/migrations/20261026170000_delivery_supervisor_deliverer_assignment_contract.sql`, blob `dff7aada5534c16fdc6394085fc28c67dd4365cd`.
- Prior implementation report: `doc/Draft/Reprots/Report511_DELIVERY_SUPERVISOR_INTEGRATION_EXECUTION_20261026.md`, retrieved at commit `abdbbeb3a5325d8740abb8863691d05cfd57f84c`, blob `518b21dbce2cef569df412a202eb4ffe12f2f1a7`.

## 3. Fresh Production state

### 3.1 RPC + ACL

Live PostgreSQL confirms:

| Function | SECURITY DEFINER | anon EXECUTE | authenticated EXECUTE | service_role EXECUTE |
|---|---:|---:|---:|---:|
| `delivery_supervisor_assignment_query(uuid,text)` | true | false | true | true |
| `delivery_supervisor_assign_deliverer_atomic(uuid,text,uuid,text)` | true | false | true | true |

The assignment contract checks an authenticated actor through `public.users.auth_id = auth.uid()`, company membership, active status, and a supervisor/owner/fleet-manage permission. The target must be an active same-company `public.users` record with `permissions @> ["delivery"]`. Assignment only updates `runsheets.deliverer_id`; it does not change `driver_id`, `vehicle_id`, or status. `erp_operation_registry` supplies operation idempotency.

### 3.2 Production transactional E2E with rollback

A temporary, uniquely named runsheet was inserted inside an explicit transaction, with an existing company vehicle and a separate active driver user assigned to the fixture. Under a simulated authenticated supervisor JWT claim, the test performed:

1. Assign an eligible delivery representative using the new RPC.
2. Retry the exact request with the same `operation_id`; assert the response marks `duplicate=true`.
3. Unassign using a distinct operation id.
4. Assert `deliverer_id IS NULL`, while `driver_id`, `vehicle_id`, and `status='Loaded'` remain unchanged.
5. Roll back the transaction.
6. Query the fixture code after rollback; result: `residual_fixture_rows = 0`.

**Result:** `PASS — SQL transactional test under simulated Auth claim; no persistent fixture.`  
**Not proven:** this is not a real JWT over PostgREST/Edge HTTP, not a browser test, and not a concurrency test using separate sessions.

### 3.3 Production Edge registry snapshot

Fresh `list_edge_functions` confirms these functions are ACTIVE with `verify_jwt=true`:

| Function | Version | `ezbr_sha256` | Confirmed contract gap |
|---|---:|---|---|
| `get-driver-dashboard` | 1 | `59f6bbd39fb8331109966c312fda3327077f17cceda8d9b4b1c9a1c6f652f58e` | Selects nonexistent `users.vehicle_id`; omits runsheet `id` but uses `activeRS.id`; filters by `driver_id`. |
| `start-delivery` | 7 | `7e87dd0a29d57d3d286c19e05aed70c8b40c7e74645fc73f593e6eee2610399e` | Filters the run by `driver_id`, not the assigned delivery representative; user lookup by email rather than `auth_id`. |
| `complete-delivery` | 4 | `9510e7ef441d3b1256f860c775094c43f5102381488580d99601b26c1b482753` | Does not verify the caller is the assigned `deliverer_id`. |
| `complete-order-delivery` | 14 | `15c67bde52401897fc0ccc4156670fd5cdc026152617401aabca232c1b046fb2` | Calls Core, but Core does not enforce assigned `deliverer_id` and `Delivering` status inside the transaction. |
| `force-unassign-runsheet` | 1 | `4fec814c60d3899ba12b1a6f7af07228a954cf56fe3ce0eb617abdeb8af514b9` | Insufficient company/permission scope; clears `driver_id` rather than `deliverer_id`. |

No Edge function was deployed in this pass. Deploying a partial Edge change while current `driver.html` still filters by `driver_id` would create a split contract and could strand existing users.

## 4. Critical new finding: the test Fleet driver is not a login user

Live Production contains this Fleet master record:

| Field | Live value |
|---|---|
| `fleet_drivers.id` | `17be00dc-a50b-4daf-94cd-c34687b68182` |
| `driver_code` | `D-01` |
| `full_name` | `سائق مركبة تجربة 1` |
| `email` | `driverer@rawaea.com` |
| `company_id` | `00000000-0000-0000-0000-000000000001` |
| `status` | `Active` |
| `fleet_drivers.user_id` | **NULL** |

Live checks found no matching `public.users` row and no matching `auth.users` identity for `driverer@rawaea.com`. The inspected current `vehicles` records have `fleet_driver_id=NULL`; therefore the test Fleet driver is also not assigned to either currently listed vehicle.

This explains why the record does not appear in the existing User Management list: it is a Fleet/HR master row, not an authenticated application user. This is not fixed correctly by inserting a fake `public.users` row or by adding a duplicate table. `public.users.password_hash` is not an Auth credential, and a login needs an `auth.users` identity linked through `public.users.auth_id`.

### Existing schema is sufficient; do not create duplicate tables

- `fleet_drivers.user_id → public.users.id` already exists.
- `vehicles.fleet_driver_id → fleet_drivers.id` already exists.
- `vehicles.driver_id → public.users.id` exists.
- `runsheets.driver_id → public.users.id` and `runsheets.deliverer_id → public.users.id` exist.
- `delivery_agents` is a separate delivery-agent master table and is currently empty in the inspected Production snapshot.
- `erp_operation_registry` already exists for idempotent operations.

**Conclusion:** no new table is justified by the live schema. The missing piece is identity provisioning/linking and consumer alignment, not storage capacity.

### Role/app-router mismatch

Live `public.roles` contains:
- `سائق مركبة` with `permissions=[]`.
- `مندوب توصيل` with `permissions=["delivery"]`.
- `مشرف توصيل` with `permissions=["delivery_supervisor","customers","runsheets"]`.

Current `app.html` routes to `delivery/driver.html` only when `permissions` contains `delivery`, and routes to `delivery/supervisor.html` only when it contains `delivery_supervisor`. There is no verified separate `vehicle_driver` route/permission in the current router. Consequently, merely creating a `public.users` row under the existing `سائق مركبة` role would not establish working app access. Giving the driver `delivery` just to make the tile appear would wrongly grant the delivery-representative workflow and defeat the owner’s separation requirement.

**Required design:** preserve separate Fleet driver and application-user identities; provision the Auth + `public.users` account through the existing authorized user-creation flow; link `fleet_drivers.user_id` to the resulting `public.users.id`; assign vehicle via `vehicles.fleet_driver_id`; assign runsheet vehicle/driver through Parent/Fleet (`vehicle_id` + `driver_id`); assign the delivery representative separately through `deliverer_id`. A combined-role employee may hold both distinct permissions, but the fields and responsibilities must remain separate.

The authorized `save-employee` Edge function (Production v10, ACTIVE, `verify_jwt=true`, `ezbr_sha256=f1ff0999d1e5bef8423ebeaff580e35d16da505134a09087054725bb89480e75`) creates Auth + `public.users` accounts, but its current source does not link a matching `fleet_drivers` row. The fleet creation flow itself does not provision a login identity. No automatic account was created because there is no approved password/invitation flow in the current Fleet creation contract and no Auth identity exists to link.

## 5. Source / consumer reconciliation

### Delivery Supervisor current source

The current `supervisor.html` still:
- reads `runsheets` and `users` directly;
- derives team assignment statistics from `driver_id`;
- lists unassigned runsheets using `driver_id IS NULL`;
- writes `runsheets.driver_id` during delivery-representative assignment;
- clears `driver_id` during unassignment.

That conflicts with live Production RLS and the newly deployed `delivery_supervisor_assign_deliverer_atomic` contract.

### Driver PWA current source

The current `driver.html` still queries runsheets through `driver_id`, and some delivery/collection paths record the acting identity as `driver_id`. A global replace is unsafe: `vehicle_tracking.driver_id` and fleet vehicle driver assignments must continue to mean the vehicle driver. The app needs explicit role-aware behavior and must not assume every driver is also the delivery representative.

### Parent/Fleet

The Parent/Fleet contract owns vehicle and driver assignment. The Delivery Supervisor contract owns only the representative assignment. Do not change `main.html` in this task’s governed source-edit mode; source patches must be owner-applied after the exact current blob SHA is rechecked. Report511 contains the surgical supervisor patches; this report adds the Fleet-driver identity finding and the necessary account-linking contract.

## 6. Loss / Gain / Responsibility Matrix

| Responsibility | Current evidence | Correct owner/target | Status |
|---|---|---|---|
| Fleet employee master | `fleet_drivers` record exists | Fleet/HR | RETAINED |
| Auth login identity for D-01 | No `auth.users` match | Authorized user-provisioning flow | MISSING |
| Link Fleet driver to app user | `fleet_drivers.user_id=NULL` | Existing FK to `public.users.id` | MISSING |
| Vehicle ↔ Fleet driver | inspected `vehicles.fleet_driver_id=NULL` | Parent/Fleet | NOT ASSIGNED |
| Runsheet vehicle | `runsheets.vehicle_id` | Parent/Fleet | RETAINED |
| Runsheet vehicle driver | `runsheets.driver_id` | Parent/Fleet | RETAINED |
| Runsheet delivery representative | `runsheets.deliverer_id` | Delivery Supervisor RPC | RPC deployed; UI consumer not migrated |
| Supervisor read model | two company-scoped RPCs deployed | PostgreSQL | VERIFIED at SQL level |
| Delivery execution authorization | Edge/Core still use old driver contract | Edge/Core | OPEN |
| Driver-only app routing | role has empty permissions; router lacks proven separate route | Core/app router + app contract | OPEN |
| Collection/product liability attribution | existing driver-ledger naming; role semantics not fully traced | Delivery/Finance contracts | OPEN |

## 7. Industry design check

The stable design pattern is to maintain driver master data separately from vehicle resources and freight/run assignments, then validate availability/qualification and assign the driver at the appropriate transportation order or stage. SAP Transportation Management documents driver master data, default drivers on vehicle resources, and driver assignment at freight-order or transportation-stage level. This supports the RAWAEA separation of driver, vehicle, and delivery representative rather than collapsing their IDs into one field.

- SAP Help: [Use of Drivers in Freight Order Management](https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/e3dc5400c1cc41d1bc0ae0e7fd9aa5a2/f494ff5544367b43e10000000a4450e5.html)
- SAP Help: [Driver — SAP Transportation Management](https://help.sap.com/docs/SAP_TRANSPORTATION_MANAGEMENT/54cf405c9d9e4c96bf091967ea29d6a7/1b10a0f487a84b8abc77f13d3cca353f.html)

No verifiable public source establishing Almarai’s internal driver/delivery-representative system configuration was found in this investigation. No claim about Almarai’s proprietary workflow is made.

## 8. Test matrix

| Test | Result | Evidence / limit |
|---|---|---|
| Live Production PostgreSQL version/time | PASS | 17.6; 2026-10-26 17:40:45.680660 UTC |
| RPC presence and ACL | PASS | Live `pg_proc` + `has_function_privilege` |
| Assign deliverer through RPC | PASS — SQL rollback test | Simulated Auth claim, temporary fixture |
| Same-operation retry | PASS — SQL rollback test | `duplicate=true` asserted |
| Unassign deliverer | PASS — SQL rollback test | RPC success asserted |
| Preserve driver/vehicle/status | PASS — SQL rollback test | driver_id, vehicle_id, Loaded status unchanged |
| Test fixture cleanup | PASS | `residual_fixture_rows=0` after rollback |
| Wrong-company SQL check | HISTORICAL PASS, not re-run in this specific transaction | Report511 records rejection; this report does not relabel it as HTTP |
| Authenticated HTTP/PostgREST E2E | NOT RUN | No real supervisor JWT/session supplied to the runner |
| Concurrent separate-session assignment | NOT RUN | Not tested |
| Supervisor browser E2E / Cloudflare served HTML | UNVERIFIED | Source blob known; served HTML not proven |
| Driver PWA E2E | NOT RUN | Old `driver_id` consumer contract remains |
| Full delivery + returns + collection + ledger lifecycle | NOT CLOSED | Core/Edge responsibility and financial attribution remain open |
| New table creation | NOT NEEDED | Existing tables/FKs already cover the entities |
| Production business baseline | PRESERVED | Fixture transaction rolled back; no persistent runsheet/user/stock/accounting change |

## 9. Mutation ledger

**Production changes in this execution:**
- No persistent DDL/DML changes.
- One rollback-only test transaction created and removed its temporary runsheet and operation-registry rows.
- Verified the residual fixture query returned zero rows.
- No Edge function redeployed.
- No operational HTML/Core file changed.
- No user/Auth account created.
- No new table created.
- No stock, allocation, inventory log, order, collection, accounting, or ledger records intentionally changed.

**Pre-existing Production migration:** the canonical delivery-supervisor assignment migration was applied before this execution, as documented in LVE-511; it was re-verified live during this execution.

## 10. Exact remaining Closure Unit

1. Owner rechecks current blob SHAs, then applies Report511’s `supervisor.html` patches to use the RPCs and `deliverer_id`; no direct runsheet/user writes.
2. Define the separate `vehicle_driver` permission/app route and role-aware driver workflow. Do not grant `delivery` solely to make a driver login visible.
3. Extend the authorized account provisioning/linking flow so a Fleet driver can be linked by `company_id + verified identity` to the resulting `public.users.id`; set `fleet_drivers.user_id`. Do not create a fake user row without an Auth identity. Confirm whether the user-management screen should show unlinked Fleet employees separately as “no login account” or only show authenticated users.
4. Reconcile `get-driver-dashboard`, `start-delivery`, `complete-delivery`, `complete-order-delivery`, `force-unassign-runsheet`, and Core delivery RPCs with `deliverer_id` for delivery duties and `driver_id` for vehicle duties. Do not deploy a partial backend change that breaks the current PWA.
5. Reconcile collection receipts, driver liabilities/ledger attribution, returns, and company isolation.
6. Run staging tests, real authenticated HTTP/JWT E2E, retry/duplicate, wrong company, wrong deliverer, concurrency, browser E2E against the served Cloudflare artifact, then verify zero fixture residue and baseline restoration.

## 11. SELF-AUDIT FINAL

**What I proved**
- Live Production RPCs and ACL are correct for the new assignment contract.
- Assign → duplicate retry → unassign works in a Production SQL transaction under a simulated authenticated claim; the fixture was rolled back.
- Driver/vehicle/status fields remained untouched by the delivery-representative assignment.
- The Fleet test record `D-01` is not a login user and is not linked to a vehicle.
- Existing schema is sufficient; duplicate tables are unnecessary.
- Current app routing and delivery consumers do not yet honor the separation end-to-end.

**What I did not prove**
- Real JWT/HTTP or browser E2E.
- That Cloudflare serves the current source blobs.
- That the test Fleet driver can log in; current evidence says it cannot because there is no Auth user.
- Full delivery/returns/collection/ledger lifecycle correctness.
- Production concurrency behavior.

**What I fixed**
- No persistent code/DB repair was made in this pass because current consumers are inconsistent and a partial Edge deployment would risk breaking delivery. The Production transactional test was rolled back with zero residue. The earlier canonical assignment RPC remains deployed.

**What I initially missed**
- The newly created Fleet driver record `D-01` had not been linked to `public.users` or `auth.users`; the current vehicle records also have `fleet_driver_id=NULL`.
- The existing `سائق مركبة` role has no permissions, while `app.html` routes to the current driver PWA only for `delivery`, which is a representative permission.

**What could still be wrong**
- There may be other consumers or ledger writers not captured by the current targeted trace.
- The served Cloudflare artifact may differ from Git.
- The exact business policy for a combined-role user still needs to be represented as two permissions/assignments, not one overloaded field.

**Final confidence:** 95/100 for the SQL RPC behavior tested; 65/100 for whole-system delivery integration.  
**Final closure status:** `PARTIAL — NOT 100% CLOSED`. The immediate next unit is role-aware Fleet driver account provisioning/linking plus owner-applied supervisor UI patch, followed by coordinated Edge/Core and real HTTP E2E.