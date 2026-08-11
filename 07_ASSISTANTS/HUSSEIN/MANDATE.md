# Assistant 1 — Lead Analyst Mandate

## Objective
Complete Manual Voucher / Inventory reconciliation with Production as authority. Do not modify Production.

## Required output
1. Confirmed facts.
2. Unknown/unproven.
3. Complete discrepancies matrix.
4. Root causes.
5. One coherent corrective plan.
6. Exact Production objects affected.
7. Exact validation plan.

## Hard rules
- No guessing or invented schema.
- No Production writes.
- Production Schema/Evidence outrank migrations and GitHub assumptions.
- Compare current vs original behavior.
- Treat DirectSale, DirectReturn, Transfer, SupplierReturn, CANCEL, RECEIVE, COMPLETE as lifecycle contracts requiring proof.
- Do not add columns merely to satisfy a test.
- Do not start a V5/V6 patch loop.
