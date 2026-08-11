# CTO — Source & Authority Register

## Objective

This repository is a curated recovery baseline, not a blind mirror.

## Source repositories

### Source A — primary review repository
`papamohammed77-glitch/rawaie-erp-review`

### Source B — target repository
`papamohammed77-glitch/rawaie-erp-New`

## Source branch used for the latest rescue evidence
`rescue/manual-vouchers-inventory-core`

## Admission rule

A file is admitted to an operational folder only when its content is one of:

1. Active architectural authority.
2. Current execution protocol / guardrail.
3. Latest recorded execution status.
4. Persisted Production Evidence obtained from the rescue investigation.
5. Current implementation code from the rescue branch.
6. Historical/original code required for regression comparison.
7. Assistant analysis that records a material finding and is clearly labeled as analysis, not authority.

## Explicit exclusions

The following are NOT admitted as authoritative operational evidence:

- `SQL_Evidence/diagnostics/رد حول التعريفات.md` because it contains an older unverified schema description before the later actual-index evidence.
- Unreleased migrations are not placed in the operational SQL folder. They remain reference-only because they contain Target alternatives that were explicitly marked `NOT EXECUTED IN PRODUCTION`.
- Draft assistant replies are not treated as facts when later Production Evidence supersedes them.
- Any document whose statements conflict with the latest persisted Production Evidence is excluded from the authoritative evidence set.

## Current Production facts admitted

- `stock_vouchers` does NOT contain `completed_by`.
- Deployed `complete_manual_stock_voucher_atomic` attempts to write `completed_by`.
- Deployed Manual Voucher POST is `SECURITY DEFINER`.
- Current Manual Voucher lifecycle types in current shared rules are Transfer, DirectSale, DirectReturn, SupplierReturn.
- Current SEND performs OUT movement for supported outbound types.
- Current RECEIVE performs IN movement and supports partial receipt.
- Production `inventory_log` has no `branch_id` column in the captured schema evidence.
- Branch/company consistency was verified for BR-01 and BR-2.
- Main branch is BR-01 for the captured company context.
- Captured stock availability: BR-01 has 8624 available total; BR-2 has 0.
- Actual index evidence for `stock_voucher_details` shows the primary key only.

## Evidence status vocabulary

- `PROVEN` — directly evidenced.
- `STATIC` — proven from code/schema but not empirically exercised.
- `UNKNOWN` — insufficient evidence.
- `CONFLICT` — sources disagree.
- `TARGET DECISION REQUIRED` — multiple valid interpretations exist and architecture/business intent must decide.

## Golden rule

No excluded material may be silently reintroduced as if it were Production truth.
