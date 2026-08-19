# RAWAEA ERP — PWA / INVENTORY FORENSIC CURRENT STATE
## 2026-08-19

### Basis
This checkpoint was rebuilt from current Git and current Production evidence. Prompts 6–11 and prior reports were treated as historical context, not as current truth.

### Production Snapshot
`2026-08-19 06:21:39 UTC`

### PWA Review
#### `Current/PWA/van-sales.html`
The previously reported `_createVanBranch()` defect is already fixed in current Git. Commit `b21f416ea54f9ff86832c35b6304fd1dd14a0fac` replaced direct `branches` INSERT using a hard-coded company with a call to the authenticated `setup-van-branch` capability. Production `setup-van-branch` is active with JWT verification and resolves company context from the authenticated user, validates the vehicle/driver, creates `VAN-{vehicle_code}`, and invokes `setup_van_stock`.

**No new PWA patch was required.**

#### `Current/PWA/picker.html`
The historical Prompt 11 finding that Picker did not yet send request identity is obsolete in the current source.

Current Picker behavior:
- creates/reuses a stable `operationId` using session state + `sessionStorage`;
- sends it as `Idempotency-Key`;
- sends the same value as `operation_id` in the JSON body;
- calls the `complete-picking` Edge Function.

Current Production `complete-picking` is version 16 and forwards `p_operation_id` to the canonical 5-parameter `complete_runsheet_picking` overload.

A transactional Production test using `RS-1` proved the same `operation_id` replay returns `duplicate=true` and writes no inventory log. The test was rolled back.

**No new PWA patch was required.**

### Legacy Picker API Closure
Production still exposed a legacy 4-argument `complete_runsheet_picking(uuid,text,text,jsonb)` overload that had no request-level operation identity. It was not the current PWA path, but it was an unnecessary callable bypass.

It is now retired in Production by revoking EXECUTE from `PUBLIC`, `anon`, `authenticated`, and `service_role`.

The canonical 5-parameter overload with `p_operation_id uuid` remains the only application-callable Picker completion contract.

Git migration recorded:
`supabase/migrations/20260819_revoke_legacy_complete_runsheet_picking_overload.sql`

### Inventory Writer Boundary
Current Production inspection found no direct `INSERT INTO public.inventory_log` or direct `UPDATE public.stock_branches` writer outside the approved engines. `post_stock_movement` remains the Physical Movement engine; `reserve_stock` remains Reservation-only.

`stock_branches` and `inventory_log` retain SELECT for read/reporting paths, while direct application write privileges are closed.

### Data Cleanup — Current Reality
The previously reported:
- 143 cross-company `stock_branches`
- 86 cross-company `inventory_log`

are now both **0** in current Production.

Current snapshot:
- stock rows = 23
- inventory log rows = 59
- cross-company stock = 0
- cross-company inventory log = 0
- negative stock = 0
- invalid allocated quantity = 0
- orphan stock branch = 0
- orphan stock item = 0
- orphan inventory-log item = 0
- orphan inventory-log company = 0

No further deletion is required for those two historical data classes.

### Important Remaining Data Observation
There are still 6 `order_details` rows whose Item Master `company_id` differs from the owning Order company. They belong to historical test-looking owner-company orders (`ORD-1007`..`ORD-1009`). They were **not deleted in this pass**, because the active schema treats Item Master identity as global (`items.item_code` is globally UNIQUE) and deleting detail rows from existing orders would be a destructive business-state mutation requiring a separate cleanup contract.

### Final Current Assessment
- `van-sales.html` `_createVanBranch()` defect: **already fixed; no patch needed**.
- Picker request-level idempotency: **implemented in current PWA + Edge + Production Core**.
- Legacy Picker bypass: **closed in Production and recorded in Git**.
- Physical Writers outside `post_stock_movement`: **0**.
- Cross-company stock/log residue: **0 / 0**.
- Physical stock integrity: **PASS**.
- Production snapshot synchronized: **YES** at 2026-08-19 06:21:39 UTC.

### Next Step
The Inventory Core is not reopened. Continue from the next remaining engineering area after Picker, using the same Production-first forensic procedure.

### Memory Anchor
Current canonical starting point:
- `Inventory/07-GLOBAL-INVENTORY-FORENSIC-CLOSURE-20260819.md`
- this file: `Inventory/08-PWA-INVENTORY-FORENSIC-CURRENT-20260819.md`
- legacy Picker closure migration: `20260819_revoke_legacy_complete_runsheet_picking_overload.sql`

Do not resurrect the old `_createVanBranch()` or “Picker has no operation_id” findings as current defects. Both were subsequently fixed in Git before this checkpoint.
