# Morad — Phase 1 Adversarial Review

**Source:** `rawaie-erp-review` / `rescue/manual-vouchers-inventory-core`
**Classification:** CURRENT RESCUE REVIEW — not Production truth.

## Confirmed risks
1. COMPLETE RPC/schema mismatch around `completed_by`.
2. Partial RECEIVE has a static idempotency gap: status `Sent` remains valid after a partial receive, and no independent operation identity is proven.
3. DirectSale custody can be caller-supplied when endpoint values are supplied; strict authenticated-VAN custody is therefore not proven.
4. DirectReturn has the symmetrical custody concern.
5. CANCEL definition was not fully proven in persisted evidence.
6. Production schema and audit contract were not fully closed.

## Required review behavior
Every finding must be:
Evidence → Why → Impact → Practical correction.
A reviewer must not merely say BLOCKED when a safe corrective proposal can be made.

## CTO gate
NO GO until target semantics and evidence gaps are reconciled.
