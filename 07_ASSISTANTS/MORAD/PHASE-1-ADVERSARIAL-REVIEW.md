# RAWAEA ERP — MORAD PHASE 1 ADVERSARIAL REVIEW

**Branch reviewed:** `rescue/manual-vouchers-inventory-core`
**Mode:** Evidence-first / Read-only
**Authority:** CTO

## Confirmed findings

### F-001 — COMPLETE RPC / Production Schema mismatch
Production schema lacks `stock_vouchers.completed_by`; the COMPLETE path attempts to write it. This is a real Schema/RPC contract defect.

### F-002 — Partial RECEIVE idempotency is not demonstrably proven
Current RECEIVE supports partial receipt and can remain in `Sent`. Captured evidence shows no request/event idempotency identity or unique movement identity tied to a RECEIVE attempt. Therefore replay protection is not proven.

### F-003 — DirectSale custody endpoint can be caller-supplied
CREATE defaults to the authenticated user's VAN branch only when `toId` is absent. A supplied `toId` is retained. If strict vehicle custody is the Target, server-side enforcement is weaker than required.

### F-004 — DirectReturn has the symmetrical endpoint issue
CREATE defaults `fromId` to the user's VAN only when omitted. A supplied `fromId` is retained. Strict custody enforcement is therefore not proven.

### F-005 — Voucher type scope discrepancy
Architecture materials list `Transfer, DirectSale, DirectReturn, SupplierReturn, Scrap, Adjustment`; current shared lifecycle rules support only the first four. This requires an explicit Target decision.

## Accepted Hussein findings

- `completed_by` mismatch is real.
- Current Edge Functions delegate inventory mutation to the atomic RPC boundary.
- DirectSale Target conflict requires reconciliation.
- No patch before reconciliation.

## Corrected / rejected overstatement

The statement that DirectSale automatically converts its destination to the user's VAN is too broad: this occurs only when the caller omits `toId`.

## Missing / required evidence

- Complete deployed definition of `post_manual_stock_voucher_atomic`.
- Complete deployed definitions of COMPLETE and CANCEL RPCs.
- Manual Voucher RPC privilege matrix.
- Complete Van Sales application/functions/evidence for MAIN → VAN → VanSale → Return → Unload.

## Additional discrepancy

Architecture documentation describes `inventory_log.branch_id`, while captured Production schema evidence does not contain that column. This is a proven documentation/contract mismatch, not automatically a database defect.

## RLS

Broad RLS policies are observed, but this review does not classify RLS alone as a confirmed security defect. The complete authentication → Edge authorization → RPC exposure → SECURITY DEFINER path must be evaluated.

## Test risks

1. Mandatory partial RECEIVE replay test.
2. DirectSale endpoint custody tests with omitted, correct, and wrong destination.
3. Symmetric DirectReturn custody tests.
4. Tests must use controlled/generated identifiers and clean themselves.

## CTO GATE

`BLOCKED`

The patch must not be cleared until the above risks and evidence gaps are reconciled.
