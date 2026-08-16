# CTO CLOSURE UNIT — receive-stock-voucher
## 2026-08-16 Execution Record

## PRE-CHANGE SELF-AUDIT

Business Understanding: 95/100
Architecture Understanding: 95/100
Database Understanding: 96/100
Historical Understanding: 93/100
Production Understanding: 95/100 for the verified Production Core/Edge objects
Current Understanding: 93/100
Execution Confidence: 88/100

### Confirmed Facts
- Production `receive-stock-voucher` is v5, ACTIVE, `verify_jwt=true`.
- Production `receive-stock-voucher` is a thin adapter to `post_manual_stock_voucher_atomic`.
- Production `post_manual_stock_voucher_atomic(uuid,text,text,text,jsonb)` was directly inspected.
- The existing Production idempotency key was `voucher + item + qty`.
- The Core unconditionally incremented `received_qty` after `post_stock_movement`, even when the movement layer could return `duplicate=true`.
- Therefore repeated same-quantity partial receive can duplicate `received_qty`, while legitimate repeated same-quantity partial receives can collide with the same idempotency identity.
- Current `receive-stock-voucher` in Git had direct `stock_branches` and `inventory_log` mutation and was already patched on the rescue branch to the thin Production adapter boundary.
- The Current PWA `main.html` currently calls the receive HTTP endpoint without an `operation_id` in the JSON request body.

### Unknowns / Open
- Current PWA `main.html` is a 693,899-byte single artifact, and the available GitHub write interface requires full-file replacement; a surgical edit to that file could not be safely applied from the available connector without reconstructing the entire artifact.
- Production HTTP E2E with a real JWT cannot be executed from the currently available Supabase connector because it exposes Edge metadata/source and SQL but not an authenticated HTTP invocation runner.

### Conflicts
- None in the Core definition used for this Closure Unit.

### Unverified Claims
- `receive-stock-voucher` is NOT 100% closed yet.

---

# DISCOVER

## Production

Live Production snapshot at verification time:

```text
Function: receive-stock-voucher
Version: 5
Status: ACTIVE
verify_jwt: true
Supabase artifact hash: 959cfaa337ab3f430fe8e6e2ecea870b66612c4b1ec5f36dd3acc28046a8de92
```

Production source is a thin wrapper that:

```text
HTTP
→ auth user
→ company context
→ voucher/item normalization
→ post_manual_stock_voucher_atomic
```

No direct `stock_branches` mutation exists in this deployed adapter.

## Current

PR #5 (`inventory-rescue-receive-20260815`) had already removed the historical distributed Edge mutations and aligned the Current Edge boundary to Production.

Head before this unit's repair work:
`d6a1dc6a7880e0b5d049002de836fc47df277ce1`

## Historical / Original

The previous Current/Original implementation directly:
- updated `stock_branches.qty`,
- inserted `inventory_log`,
- updated `stock_voucher_details.received_qty`,
- updated voucher status,
- and referenced a non-existent `received_by` field.

The Git PR evidence identified this as source drift.

## Core

Production `post_manual_stock_voucher_atomic` is `SECURITY DEFINER`, `search_path=public`, and internally calls `post_stock_movement`.

The Production Core defect was isolated to the receive idempotency layer.

---

# ROOT CAUSE

Original Production identity:

```text
ManualVoucher:RECEIVE:
company
:voucher
:item
:qty
```

The movement layer could correctly return `duplicate=true`, but the parent Core then incremented `received_qty` unconditionally.

Therefore:

```text
Retry same partial receive
→ Physical movement duplicate prevented
→ received_qty incremented again
```

At the same time:

```text
Legitimate later partial receive of same qty
→ same idempotency identity
→ false duplicate collision
```

A quantity-derived key cannot distinguish these two business cases.

---

# SURGICAL REPAIR

## Correct contract

A RECEIVE request requires a stable request-level:

```text
operation_id
```

The Core builds item-level movement identity as:

```text
ManualVoucher:RECEIVE:
company
:voucher
:operation_id
:item
```

The same operation ID is reused on transport/application retry.

A later legitimate partial receive must use a new operation ID.

## Edge change

Current rescue Edge was updated to:
- accept `operation_id` from body;
- alternatively accept `Idempotency-Key` HTTP header;
- reject RECEIVE without an operation ID;
- pass it into `post_manual_stock_voucher_atomic`.

Git commit:
`185e37358d12b25dc02891f1dfc45c970c284026`

## Core change

A corrective migration was added:

`supabase/migrations/20260816_receive_stock_voucher_operation_id.sql`

Git commit containing the corrective migration:
`50e40a5385349780d4a76b726152ec525e3b5b00`

The earlier quantity-derived attempt was explicitly superseded; it is NOT treated as a valid final fix.

---

# STAGING VERIFICATION

Staging project:
`hfzznsiprnwkpayskzhu`

The corrected Core was applied to Staging.

### Case 1 — Initial partial receive

Fixture:
- voucher: `QA-RCV-IDEMP`
- item: `T028-ITEM`
- target branch: `VAN TEST`
- requested: `1`
- operation_id: `OP-1`

Observed:

```text
stock qty: 8 → 9
received_qty: 0 → 1
status: Sent
```

### Case 2 — Retry same logical receive

Same:

```text
operation_id = OP-1
```

Observed:

```text
stock qty remained 9
received_qty remained 1
```

No second physical movement was applied.

### Case 3 — Legitimate later partial receive

New:

```text
operation_id = OP-2
qty = 1
```

Observed:

```text
stock qty: 9 → 10
received_qty: 1 → 2
status: Received
inventory logs: 2
```

This proves the critical semantic distinction:

```text
same operation_id
→ retry / duplicate

new operation_id
→ legitimate new partial receive
```

### Baseline restoration

All temporary fixture records were removed.

Final Staging verification:

```text
QA vouchers = 0
QA inventory logs = 0
VAN TEST / T028-ITEM qty = 8
VAN TEST / T028-ITEM allocated_qty = 0
```

Baseline was restored.

---

# CONSUMER RECONCILIATION

The Current PWA `Current/PWA/main.html` currently performs:

```text
POST /functions/v1/receive-stock-voucher
Authorization: Bearer <session token>
body = {
  voucher_code,
  receivedItems
}
```

The live consumer currently does NOT send `operation_id`.

Therefore the new Core contract cannot safely be deployed to Production until the consumer is surgically updated to create one stable operation ID before the request and reuse it for retries.

The correct client behavior is:

```text
User confirms RECEIVE
        ↓
create operation_id once
        ↓
POST Edge with operation_id
        ↓
retry using SAME operation_id
```

A second legitimate partial receive creates a new operation ID.

This is a real Consumer Contract Drift, not a theoretical concern.

---

# GLOBAL WRITER EVIDENCE RELEVANT TO THIS UNIT

Live Production PostgreSQL inspection classified:

```text
post_stock_movement
    = Central Physical Movement Engine

reserve_stock / release_stock_reservation
    = Reservation Engine

post_manual_stock_voucher_atomic
    = Orchestrator

post_inventory_adjustment_atomic
    = Orchestrator

setup_van_stock
    = Initialization

complete_runsheet_reopen_loading
    = Orchestrator
```

The direct physical writer remains `post_stock_movement` in the inspected Production Core path.

No direct Production trigger writer was found on `stock_branches` / `inventory_log` in the relevant trigger inspection.

---

# ACTUAL CHANGES

1. Added corrective Core migration on rescue branch.
2. Updated rescue `receive-stock-voucher` Edge adapter to carry request-level operation identity.
3. Applied corrected Core to Staging.
4. Executed real Core partial/retry/new-partial tests in Staging.
5. Restored Staging baseline and removed all test fixtures/logs.
6. Did NOT deploy the incompatible new Edge/Core contract to Production because the Current PWA consumer is not yet sending `operation_id`.

This is intentional Production safety, not a stop condition.

---

# WHY PRODUCTION DEPLOYMENT IS NOT SAFE YET

Deploying the new Core while the current Production Edge still calls the 5-argument contract would produce:

```text
RECEIVE
→ operation_id missing
→ Core rejection
```

Deploying the new Edge without updating the PWA would produce the same incompatibility.

Therefore the remaining dependency is precisely:

```text
Current Production Consumer
→ operation_id contract
```

The dependency is isolated and repairable.

---

# FINAL SELF-AUDIT

## What I Proved

- The original receive defect is real and occurs at Core idempotency boundaries.
- The first candidate fix (`received_before + qty`) was insufficient; it was tested and rejected rather than falsely promoted.
- Request-level operation identity correctly separates retry from a legitimate same-quantity partial receive.
- The corrected Core works in Staging.
- Same operation ID does not double-increment physical stock or `received_qty`.
- New operation ID permits a legitimate subsequent partial receive.
- Staging baseline was restored.
- Current/Production Edge boundary is already Core-oriented.

## What I Did Not Prove

- Real Production HTTP E2E for the new contract.
- Production runtime after deployment of the new contract.
- Full Current PWA consumer modification, because the 693,899-byte single-file artifact requires full-file write access for a surgical change and the available GitHub write interface did not expose patch-level file editing.

## What I Fixed

- Core receive idempotency design.
- Current rescue Edge contract.

## What I Initially Missed

- `received_before + qty` does not uniquely identify a transport retry. A retry occurs after the first transaction committed, so `received_before` changes. Only a stable operation identity can distinguish retry from a new legitimate partial receive.

## What Could Still Be Wrong

- A second untraced consumer could still call the 5-argument receive contract.
- Production may contain a separate consumer not represented by the inspected Current PWA.
- Full HTTP E2E must still be executed after the consumer contract is updated.

## Final Confidence

**Core fix confidence: HIGH**

**Closure confidence: NOT YET 100%**

## Final Closure Status

# INCOMPLETE — CONSUMER CONTRACT DEPENDENCY REMAINS

Do NOT move to the next Closure Unit yet.

---

# NEXT EXECUTABLE ACTIONS — SAME CLOSURE UNIT

1. Apply the surgical `operation_id` change to the Current PWA consumer.
2. Deploy the corrected Edge adapter to Staging.
3. Run HTTP E2E with a real JWT:
   - normal
   - retry same operation ID
   - duplicate
   - legitimate second partial with new operation ID
   - invalid/over-receive
   - failure/rollback
4. Verify Production artifact/source provenance.
5. Deploy Edge + Core to Production.
6. Repeat Production HTTP E2E.
7. Verify baseline restoration.
8. Verify no stale/parallel writer remains for the receive path.
9. Only then mark:

`receive-stock-voucher = 100% CLOSED`
