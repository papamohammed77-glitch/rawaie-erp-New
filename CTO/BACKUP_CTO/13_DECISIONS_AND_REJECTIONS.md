# BACKUP CTO 13 — DECISIONS / REJECTIONS / WHY

## Purpose
Preserve not only what was chosen, but what was deliberately rejected, because future regressions often happen when a new engineer rediscovers an old idea and treats it as new.

## Rejected / prohibited patterns
### 1. Treating design as Production
Rejected because implementation status must be proven from Production execution/evidence.

### 2. Guessing table/column names
Rejected after concrete Production errors such as nonexistent `received_by` and `is_active`.

### 3. Writing to generated columns
Rejected after `available_qty` was proven generated.

### 4. Creating duplicate vehicle infrastructure
Rejected because `public.vehicles` already existed.

### 5. Creating vehicle identity as `VAN-{email}`
Rejected. Vehicle and driver are separate entities.

### 6. Binding business identity permanently to a vehicle
Rejected because a representative can move vehicles.

### 7. Fixing Core defects in UI
Rejected. Inventory semantics belong in central Core/RPC.

### 8. Re-running the same failed test without isolating the cause
Rejected. Trace first; test second.

### 9. Considering a test transaction's successful function replacement permanent
Rejected. A later rollback can revert the replacement too.

### 10. Disabling RLS as a workaround
Rejected by architecture/security law.

### 11. Deleting original functions because a new implementation exists
Rejected until behavior parity, consumer redirection, validation and controlled deprecation are complete.

### 12. Treating historical repository as current truth
Rejected. `rawaie-erp-review` is historical/reference only after source migration.

## Strong architectural decisions
- One core / one source of truth.
- Inventory movement centralized.
- `allocated_qty` separated from movement quantity.
- Production evidence outranks migration intent.
- Original application is behavioral baseline for parity.
- Permanent fixes are committed separately from rollback-based test data.

## Why this file matters
A future CTO must not reinterpret a rejected pattern simply because the immediate code looks easier. The rejection often encodes a failure discovered through real Production work.
