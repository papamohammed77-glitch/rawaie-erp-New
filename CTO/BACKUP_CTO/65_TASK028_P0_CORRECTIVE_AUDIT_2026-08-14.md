# TASK-028 — P0 Corrective Audit
Date: 2026-08-14

## STATUS
TASK-028 = INCOMPLETE

Production correction is deployed for the two confirmed P0 defects:
1. Backorder lifecycle after Reopen -> Full Reload.
2. Cycle-scoped Unloading idempotency.

The company-scoped `sync_run_sheet_details()` fix is also present in Production.

No 100% closeout claim is made.

## SELF-AUDIT

### Knowledge Confidence
- Business: 99/100
- Architecture: 98/100
- Database: 99/100
- Production: 98/100
- Historical: 96/100
- Current Code: 98/100

### Evidence Integrity
- Confirmed: Production definitions, deployed versions, migration application, Staging runtime proofs.
- Unknown: canonical byte-for-byte Edge source parity for all five deployed wrappers.
- Production Edge E2E: not proven; prior production smoke is classified as DB TRANSACTION SMOKE because RPCs were invoked directly inside a database transaction.

### Process Failure Recorded
The previous pre-release regression matrix did not contain the reusable-cycle case:
`Load -> Reopen -> Reload -> Reopen -> Reload -> Unload`.
This is recorded as a lifecycle test-design failure.

## CONFIRMED CHANGES

### P0-A — Persisted Loading Cycle Identity
Added `public.runsheets.loading_cycle_id` with:
- default `gen_random_uuid()`
- backfill for existing rows
- unique partial index `ux_runsheets_loading_cycle_id`

Lifecycle semantics:
- `start_runsheet_loading()` creates a new cycle ID.
- `complete_runsheet_loading()` uses the cycle ID for Loading idempotency.
- `complete_runsheet_reopen_loading()` reverses the prior cycle and creates a new cycle ID for the next Loading cycle.
- `complete_runsheet_unloading()` scopes its idempotency key to the current Loading cycle and item.
- `cancel_runsheet_loading()` clears the transient cycle identity.

### P0-B — Backorder Lifecycle
The `fulfillment_backorders` constraint now permits zero remaining quantity for terminal states.
`complete_runsheet_loading()` now reconciles existing backorder rows after each load cycle:
- `Pending` with `remaining_qty > 0`
- `Consumed` with `remaining_qty = 0`

This closes the previously open case where a Pending backorder survived a full reload.

### P1 — Multi-Tenant Trigger Lookup
`sync_run_sheet_details()` now resolves `item_id` using:
`company_id + item_code`
for both item lookup and aggregate source rows.

## TESTS

### Staging — Backorder Full Reload
Fixture:
- runsheet `T028-RS`
- item `T028-ITEM`
- order quantity 10
- picked 10

Flow:
`Partial Load -> Backorder -> Reopen -> Full Reload`

Observed proof:
- Runsheet status = `Loaded`
- Backorder status = `Consumed`
- Backorder remaining = `0`

### Staging — Multi-Cycle Identity
Observed multiple distinct Unloading keys for different Loading cycles, including distinct UUID cycle values.

### Staging — Idempotency Retry
Same `post_stock_movement()` event key invoked twice.
Observed:
- one matching inventory log row
- second invocation returned duplicate behavior
- no second physical event

### Production — Definition Verification
Production contains the corrected definitions for:
- `start_runsheet_loading`
- `complete_runsheet_loading`
- `complete_runsheet_reopen_loading`
- `complete_runsheet_unloading`
- `cancel_runsheet_loading`
- `sync_run_sheet_details`

Production contains migration:
`task028_cycle_backorder_integrity_fix`
version `20260814071956`.

## PRODUCTION PARITY

### Database / Migration parity
VERIFIED for the corrective migration:
Git branch contains:
`supabase/migrations/20260814_task028_cycle_backorder_integrity_fix.sql`

Production migration history contains:
`task028_cycle_backorder_integrity_fix`
version `20260814071956`.

### Edge wrapper parity
NOT VERIFIED byte-for-byte.
Production function versions are known, but this audit does not claim the Git wrapper source hash equals the deployed Edge package hash until a direct source/package comparison is completed.

## SECURITY CHECK
Current direct Production query reports:
- public tables: 61
- public tables with RLS disabled: 0

Therefore the previous report's `64 tables without RLS` statement is NOT CURRENT and must not be used as present Production truth.

## REMAINING DEFECTS / GATES

1. Production Edge E2E remains unproven because the available execution path did not provide a user JWT + HTTP invocation harness for these JWT-protected functions.
2. Byte-for-byte Current ↔ Production Edge source/package parity remains unverified.
3. PR #3 remains Draft; governance closeout is therefore incomplete.
4. Global Zero-Debt remains open for:
   - `send-stock-voucher`
   - `setup-van-branch`
   - `setup_van_stock`
   - `create-runsheet`
   - Manual Voucher CREATE/COMPLETE
   - remaining stock callers

## 100% STATUS
TASK-028 = INCOMPLETE

A 100% RELEASE-COMPLETE claim is intentionally withheld until:
- Production Edge E2E is proven.
- Canonical Git ↔ deployed Edge parity is proven.
- PR #3 governance is finalized.
- Application/consumer E2E is verified.

## NEXT ACTION
Complete the remaining Production Edge E2E/parity gates without changing the corrected business contract. Then run the Global Zero-Debt caller sweep.

## SELF-AUDIT FINAL

### What I proved
- Backorder Pending -> Consumed/0 after Reopen -> Full Reload on Staging.
- Loading Cycle identity is persisted and distinct across cycles.
- Unloading idempotency is cycle-scoped.
- Multi-tenant item resolution is company-scoped.
- Corrective migration is applied in Production.

### What I did not prove
- Full HTTP Edge E2E in Production.
- Byte-for-byte Edge package parity for all five deployed wrappers.

### What I assumed
None for the two P0 fixes.

### What could still be wrong
- A consumer could still rely on an unverified wrapper/deployed-source difference.
- Production business behavior could still diverge from direct DB smoke if the HTTP contract differs.

### What I would re-check for Production Release
- Edge HTTP invocation with real auth.
- Exact Current/deployed source package comparison.
- PR #3 final diff and deployment lineage.

### Self-Assessment
INITIAL CONFIDENCE: 96/100
FINAL CONFIDENCE: 99/100 for the audited P0 defects; release confidence remains lower until Edge E2E/parity gates close.
