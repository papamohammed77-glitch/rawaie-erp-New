# RAWAEA ERP — Vouchers Forensic Closure — 2026-08-28

## Authority
This closure was executed under the governing principles in:
- `doc/Draft/medhat/تقرير مبادئ حاكمة`
- `doc/Draft/medhat/برومبت استكمال مهام`
- `doc/Draft/medhat/برومبت 72`

Reports were treated as historical evidence only. Current Production Supabase and current Git were re-read before each material decision.

## Current Production Snapshot
Verified 2026-08-28 05:35 UTC:
- companies: 1
- branches: 2
- vehicles: 0
- suppliers: 1
- stock_vouchers: 0
- stock_voucher_operations: 0
- stock_branches: 20
- inventory_log: 3

Integrity snapshot:
- negative stock: 0
- over-allocated stock: 0
- duplicate `(branch_id,item_id)` stock keys: 0
- branch/item company mismatch: 0
- inventory_log/item company mismatch: 0
- order_detail/item company mismatch: 0
- runsheet/item company mismatch: 0

## Historical vs Current
The older vouchers forensic record described a previously populated vehicle and older voucher state. Current Production has no vehicles and no manual vouchers. The older assertions were therefore not reused as current truth.

## vouchers.html Current Contract
Current Git file: `Current/PWA/vouchers.html`

Verified responsibilities:
- warehouse voucher center
- Transfer Branch → Branch
- DirectSale Branch → Vehicle
- DirectReturn Vehicle → Branch
- SupplierReturn Branch → Supplier
- Scrap / Adjustment delegated to the Adjustment Engine
- smart searchable selectors for branches, reps, vehicles, suppliers
- smart item search by code/barcode/name/search label
- camera barcode scanning
- live stock refresh and realtime subscriptions
- voucher list/details/audit presentation
- partial RECEIVE operation identity retained in browser storage
- no client-side physical stock write
- no client-side inventory_log write

## Critical Corrections Applied
### 1. CREATE contract / DirectSale actor semantics
Production previously required DirectSale CREATE to be performed by a direct-sales rep. The actual current warehouse role is `مخزني / أذونات`, while the selected rep is `مندوب بيع مباشر`.

Production was corrected so the warehouse operator can create DirectSale while explicitly selecting the rep. The backend verifies:
- rep belongs to company
- rep is active
- rep role is `مندوب بيع مباشر`
- vehicle belongs to company
- vehicle is active
- vehicle.driver_id = selected rep
- vehicle VAN branch exists

The original ten-argument RPC signature was preserved as a compatibility wrapper.

### 2. CREATE idempotency
A permanent `stock_voucher_operations` registry was added with:
- company scope
- operation_id uniqueness per company
- request fingerprint
- linked voucher_id

This prevents accidental duplicate voucher creation after network retries.

### 3. Company authority
Adjustment, Complete, and Cancel capabilities now verify that the acting user's active `users.company_id` equals the supplied company context.

### 4. Realtime
`stock_vouchers`, `stock_voucher_details`, and `stock_branches` are members of `supabase_realtime` and use FULL replica identity.

### 5. Runtime compatibility
`Current/core.js` was added as a non-duplicating compatibility entry point because `vouchers.html` resolves `../core.js` while the canonical shared core remains `Current/PWA/core.js`.

### 6. Auditability
`stock_vouchers` is protected by `trg_audit_stock_vouchers` → `fn_audit_trigger()`. The audit path remains the system of record for voucher header INSERT/UPDATE/DELETE history.

## Physical Writer Closure
Global Production function discovery found only:
- `post_stock_movement` — Physical Stock Writer
- `reserve_stock` — Reservation Engine
- `release_stock_reservation` — Reservation Engine

No additional function was found that independently updates Physical Stock as a competing writer. `reserve_stock` and `release_stock_reservation` are explicitly non-movement operations.

## Production Transactional Proof
A temporary DirectSale fixture was created inside one transaction and rolled back.

Proved:
- warehouse operator `vouchers@rawaea.com` can create a DirectSale for selected rep `vansales@rawaea.com`
- CREATE returned success and the selected rep identity
- repeating the same operation_id returned `duplicate=true` and the same voucher
- SEND moved one unit from the source branch to the vehicle VAN branch
- source stock changed exactly `2 → 1`
- vehicle stock changed exactly `0 → 1`
- repeating SEND did not create a second movement
- rollback restored Production to its pre-test state

## Current Git Alignment
The current Git source of `create-stock-voucher` was aligned back to the deployed ten-argument compatibility contract after the Production DB gained the twelve-argument canonical implementation. This avoids claiming an Edge deployment that did not occur.

## Known Runtime Boundary
Production currently has **zero vehicles**. Therefore a persistent live DirectSale business transaction cannot be executed against real operational vehicle master data until a real vehicle is configured. This is a master-data condition, not a voucher code defect.

A transactional vehicle fixture was used only for verification and was fully rolled back.

## Industry Benchmark Notes
- Odoo 19 treats barcode scanning as part of inventory operation execution and supports internal-transfer/picking barcode flows.
- SAP EWM models warehouse execution as warehouse tasks with explicit confirmation and documented differences.
- Dynamics 365 Warehouse Management supports camera barcode scanning on mobile devices.

RAWAEA adopts these patterns selectively: execution identity, barcode-first interaction, explicit confirmation, auditable state transition, and a single physical-stock engine.

## Status
### PROVEN CLOSED
- Physical stock writer centralization
- Manual voucher CREATE server path
- DirectSale warehouse-operator semantics
- DirectSale rep/vehicle integrity checks
- CREATE idempotency registry
- SEND physical movement centralization
- company-context hardening for adjustment/complete/cancel
- realtime publication of voucher/stock tables
- current Production stock/inventory integrity checks = zero violations
- no persistent test pollution

### NOT CLAIMED CLOSED
- End-to-end browser-session runtime verification against live vehicle data, because Production currently has zero vehicles and no live browser session was available in this execution context.
- Full permanent live DirectSale business cycle against a real vehicle master record.

## Final Governance Position
The Database/Capability layer for the voucher workflow is closed to the extent proven by current Production and transactional evidence. A false `100% CLOSED` label is intentionally not written over the remaining browser/master-data runtime boundary.
