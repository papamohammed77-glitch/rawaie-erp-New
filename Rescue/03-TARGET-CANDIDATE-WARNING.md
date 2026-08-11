# TARGET CANDIDATE WARNING

The following material from the rescue branch is NOT Production truth and must not be executed or described as deployed:

- `supabase/migrations/20260810_manual_voucher_core_v1_reconciled.sql`
- `supabase/migrations/20260810_manual_voucher_core_v1_FINAL.sql` (if present in the source branch)
- Any release migration that changes DirectSale/DirectReturn semantics.

## Reason
The reconciled migration was designed after review, but it references fields/semantics that were not all proven against the captured Production schema. In particular, one version references `received_by`, while the captured Production `stock_vouchers` schema does not prove that field.

Therefore:

Production Evidence ≠ Candidate Migration.

The candidate must first pass:

1. Full Production schema reconciliation.
2. Full deployed RPC reconciliation.
3. Audit contract reconciliation.
4. DirectSale/DirectReturn Target decision.
5. Idempotency design.
6. Static validation.
7. Controlled database test.
8. CTO GO.
