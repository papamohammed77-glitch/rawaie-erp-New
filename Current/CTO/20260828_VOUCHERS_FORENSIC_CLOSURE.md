# RAWAEA ERP — Vouchers Forensic Closure — 2026-08-28

## Authority
This closure was executed under the governing principles in:
- `doc/Draft/medhat/تقرير مبادئ حاكمة`
- `doc/Draft/medhat/برومبت استكمال مهام`
- `doc/Draft/medhat/برومبت 72`
- `Current/CTO/20260828_VOUCHERS_CORE_SINGLE_SOURCE_GOVERNANCE.md`

Reports were treated as historical evidence only. Current Production Supabase and current Git were re-read before each material decision.

## Current Production Snapshot
Verified 2026-08-28 05:58 UTC:
- companies: 1
- branches: 2
- vehicles: 0
- suppliers: 1
- stock_vouchers: 0
- stock_voucher_operations: 0
- stock_branches: 20
- inventory_log: 3

## Historical vs Current
The older vouchers forensic record described previously populated vehicles and older voucher state. Current Production has no vehicles and no manual vouchers. Those older assertions were not reused as current truth.

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

## Critical Corrections Previously Proven
### 1. CREATE contract / DirectSale actor semantics
Production requires the warehouse operator to create DirectSale while explicitly selecting the direct-sales rep. The backend validates rep/company/activity, vehicle/company/activity, vehicle.driver_id = selected rep, and VAN branch integrity. The compatibility ten-argument RPC signature remains available while the canonical contract is twelve arguments.

### 2. CREATE idempotency
Production contains the `stock_voucher_operations` registry for company-scoped operation identity and request fingerprinting.

### 3. Company authority
Adjustment, Complete, and Cancel capabilities include company-context validation.

### 4. Realtime
Production verification previously confirmed the voucher/stock tables participate in realtime publication with full replica identity.

### 5. Auditability
`stock_vouchers` remains protected by `trg_audit_stock_vouchers` → `fn_audit_trigger()` for INSERT/UPDATE/DELETE history.

## Physical Writer Closure
Direct Production discovery establishes the central contract:
- `post_stock_movement` is the Physical Stock Writer.
- `reserve_stock` and `release_stock_reservation` are Reservation Engines and are not Physical Stock Writers.
- Voucher SEND/RECEIVE paths delegate physical posting to `post_stock_movement`.

A separate historical `complete-return` Edge Function remains a global inventory debt item because its current deployment is outside this voucher closure unit and was not silently reclassified as closed here.

## Canonical Shared PWA Source Closure
The shared PWA runtime source is now singular:
- canonical shared core: `Current/PWA/core.js`
- canonical service worker bootstrap: `Current/PWA/register-sw.js`
- canonical service worker: `Current/PWA/sw.js`
- `Current/core.js` does not exist on current `main`

All current PWA pages were path-normalized so the shared runtime resolves locally within `Current/PWA`. The central `register-sw.js` was also corrected from `../sw.js` to `sw.js` because the actual deployed worker resides beside it.

The temporary one-shot GitHub workflow used to perform the bulk path normalization self-deleted after successful execution. Final canonicalization commit:
`fd7a597198027e061b79039634af0091682aff3f`.

A subsequent correction to `Current/PWA/register-sw.js` was committed as:
`b38cfd917217fe73a53f05b1542d75c014eea1eb`.

## Verification Status
### PROVEN
- Current `Current/PWA/core.js` exists and is the canonical shared core.
- `Current/core.js` is absent from current `main`.
- `Current/PWA/register-sw.js` exists and registers `sw.js` locally.
- `Current/PWA/sw.js` exists.
- `Current/PWA/vouchers.html` loads `core.js` locally rather than `../core.js`.
- The one-shot path-normalization workflow completed successfully and then removed itself.
- The source canonicalization is committed to `main`.

### NOT CLAIMED PROVEN
- Browser-session end-to-end verification of the final static asset path in a live browser instance was not available in this execution context.
- A live DirectSale business transaction against a real vehicle cannot be performed because current Production has zero vehicles.
- Global inventory core is not declared 100% closed while the known `complete-return` direct-writer deployment remains outside this voucher unit.

## Governance Correction
Any previous statement that `Current/core.js` should remain as a compatibility entry point is obsolete and must not be used as a future implementation pattern. A duplicate shared core outside `Current/PWA` is explicitly prohibited.

## Final Position
The vouchers frontend/shared-runtime source location is now canonicalized to `Current/PWA`. The voucher database/capability closure remains subject to the explicit runtime boundaries above; no false 100% Production/browser closure is claimed where direct evidence is unavailable.