# CTO — Next Gate

## Current Gate

`BLOCKED / NO GO`

## Do not repeat

Do not re-run the already confirmed company/branch/schema/index diagnostics unless new evidence or code changes invalidate them.

## Next execution gate

### GATE-INV-001 — Contract Closure

Before any Production patch:

1. Freeze the final Manual Voucher Target semantics.
2. Decide the authoritative completion/cancellation audit contract.
3. Prove whether Partial RECEIVE requires a persistent operation identity/idempotency key.
4. Prove DirectSale and DirectReturn custody ownership at the authoritative boundary.
5. Prove the complete deployed `post_manual_stock_voucher_atomic` definition.
6. Reconcile current vs original vs unreleased migration behavior.
7. Reconcile Van Sales end-to-end before touching `van-sales.html`.

## Then

`One coherent patch → self-cleaning lifecycle tests → regression → Production verification → Release Gate`

No schema change is allowed merely to make a failing test pass.
