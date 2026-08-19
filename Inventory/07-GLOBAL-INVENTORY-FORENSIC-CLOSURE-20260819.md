# RAWAEA ERP — GLOBAL INVENTORY FORENSIC CLOSURE
## 2026-08-19

### Scope
This checkpoint was rebuilt from direct GitHub and Production evidence. Previous CTO reports were treated as historical evidence only.

### Sources Re-reviewed
- `doc/Draft/medhat/برومبت 6`
- `doc/Draft/medhat/تقرير تنفيذ برومبت 6`
- `doc/Draft/medhat/برومبت 7 ملحق بتقريره`
- `doc/Draft/medhat/برومبت 8 وتقرير تنفيذه`
- `doc/Draft/medhat/برومبت 9 وتقرير تنفيذه`
- `doc/Draft/Hussin/تقييم برومبت 9 وتقرير تنفيذه`
- `Inventory/05-GLOBAL-INVENTORY-ZERO-DEBT-RESULT-20260819.md`
- `Inventory/06-GLOBAL-INVENTORY-ZERO-DEBT-POST-MERGE-20260819.md`

### Historical Discrepancy Resolved
Hussin's finding that `complete_runsheet_picking` directly wrote `inventory_log` was valid for the historical Production state he reviewed.

Current Production was re-inspected directly. The deployed `complete_runsheet_picking` now:
- uses `reserve_stock` for Picking reservation;
- updates `order_details` fulfillment quantities;
- does not insert into `inventory_log`;
- explicitly returns `inventory_log_written=false`.

Therefore that historical gap was already repaired before this forensic pass. No duplicate repair was applied.

### Current Production Snapshot
Snapshot: `2026-08-19 05:07:21.99545+00`

- Direct `inventory_log` writers outside `post_stock_movement`: **0**
- Direct `stock_branches.qty` writers outside the Core/Reservation engines: **0**
- Inventory/stock triggers: **0**
- Negative physical stock rows: **0**
- Invalid `allocated_qty`: **0**
- Orphan stock branch rows: **0**
- Orphan stock item rows: **0**
- Orphan inventory-log item rows: **0**
- Orphan inventory-log company rows: **0**

### Additional Production Gap Found and Closed — Direct Write Boundary
Production still granted direct `INSERT/UPDATE/DELETE/TRUNCATE/REFERENCES/TRIGGER` privileges on `stock_branches` and `inventory_log` to `anon`, `authenticated`, and `service_role`.

`pg_stat_statements` confirmed historical direct writes through `service_role`, proving that the capability was real and not merely theoretical.

The boundary was closed in Production:
- direct writes revoked from `anon`, `authenticated`, `service_role`;
- `SELECT` retained for reporting/read paths;
- trusted `SECURITY DEFINER` inventory engines remain able to mutate stock.

### Additional Production Gap Found and Closed — Operation Registry Boundary
The security advisor identified `public.erp_operation_registry` as publicly exposed with RLS disabled. Its purpose is internal operation/idempotency coordination used by return and delivery cores.

The Production boundary was closed:
- RLS enabled on `erp_operation_registry`;
- all direct privileges revoked from `anon`, `authenticated`, and `service_role`;
- Core `SECURITY DEFINER` functions retain internal access.

A post-change runtime test confirmed Sales → POS Return still executes correctly after the registry lockdown.

### Additional Production Defect Found and Closed — POS Return Null Runsheet Guard
`complete_return_atomic` contained a POS-return guard that could evaluate `v_runsheet.id` when `p_runsheet_code` was NULL. This caused a runtime `record "v_runsheet" is not assigned yet` failure on the POS Return path.

The current Production definition was preserved and only the defective guard was replaced with a nested guard that evaluates `v_runsheet` only when a runsheet is actually present.

### Runtime Verification Performed
All tests were executed against Production and transactional tests were rolled back unless explicitly documenting cleanup.

1. **Core stock engine**
   - movement posted through `post_stock_movement`;
   - idempotent replay detected as duplicate;
   - transactional verification PASS.

2. **Purchase Receiving**
   - explicit `operation_id` accepted;
   - first receive posted one physical movement;
   - replay returned `duplicate=true`;
   - no second receipt/movement;
   - transactional verification PASS.

3. **Sales → POS Return**
   - sales invoice posted through `save_sales_invoice_atomic`;
   - replay returned duplicate;
   - POS return posted through `complete_return_atomic`;
   - replay returned duplicate;
   - net physical stock returned to the exact starting quantity;
   - transactional verification PASS after the POS guard fix and registry lockdown.

4. **Write-boundary security**
   - direct `service_role` write to `inventory_log`: BLOCKED;
   - direct `authenticated` update to `stock_branches`: BLOCKED;
   - direct `authenticated` registry access: BLOCKED;
   - Core `SECURITY DEFINER` mutation remains functional.

### Company / Item Identity
The current schema still defines `items.item_code` as globally UNIQUE. Therefore existing rows where a branch company differs from the Item Master `company_id` are not automatically treated as corruption.

Current counts:
- cross-company `stock_branches`: 143
- cross-company `inventory_log`: 86
- cross-company `order_details`: 6

These were intentionally **not deleted or rewritten** because the current Item Master contract is global and the current foreign-key/identity model supports such references. No data mutation was performed on these rows without proof that they were invalid.

### Final Status
- Physical Writers outside `post_stock_movement`: **0**
- Direct stock/log write capability for application roles: **CLOSED**
- Operation registry public access: **CLOSED**
- Physical stock integrity checks: **PASS**
- Core idempotency checks: **PASS**
- Critical Sales/Return runtime verification: **PASS**
- Purchase receiving runtime verification: **PASS**

## GLOBAL INVENTORY CORE INTEGRITY = 100% CLOSED

### Remaining Program Step
The Inventory rescue phase is complete. The next planned engineering phase is **Picker**, under the same forensic / Production-first governance.

### Canonical Git Changes From This Pass
- `supabase/migrations/20260819_inventory_write_boundary_zero_debt.sql`
- `supabase/migrations/20260819_fix_complete_return_pos_null_runsheet_guard.sql`
- `supabase/migrations/20260819_lock_erp_operation_registry_internal.sql`
- this checkpoint: `Inventory/07-GLOBAL-INVENTORY-FORENSIC-CLOSURE-20260819.md`

### Next-Session Memory Anchor
Do not reopen old Hussin findings as if they are still Production facts. The Picking direct `inventory_log` writer is already removed in current Production.

The real closures completed in this forensic pass were:
1. application write-boundary lockdown for `stock_branches` / `inventory_log`;
2. internal-only lockdown for `erp_operation_registry`;
3. POS Return null-runsheet runtime guard in `complete_return_atomic`.

Next work starts from **Picker**, not from Global Inventory Writer Discovery.
