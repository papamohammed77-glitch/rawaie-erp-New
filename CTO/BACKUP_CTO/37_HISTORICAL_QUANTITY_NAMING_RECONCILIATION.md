# 37 — HISTORICAL QUANTITY NAMING RECONCILIATION

## Purpose
Record the historical/current terminology difference discovered during CTO execution qualification without changing code or schema.

## Evidence
Historical architecture catalog `CTO/BACKUP_CTO/24_HISTORICAL_ARCHITECTURE_DECISION_CATALOG.md` states that historical `order_details` carried six quantities including `qty_ordered`.

Current Stage-28 operational memory and current source discussions use `qty` for the original requested quantity.

## Reconciliation

| Concept | Historical name | Current rescue/current terminology | Classification |
|---|---|---|---|
| Original requested quantity | `qty_ordered` | `qty` | HISTORICAL vs CURRENT terminology |
| Picked quantity | `qty_picked` | `qty_picked` | CONSISTENT |
| Loaded quantity | `qty_loaded` | `qty_loaded` | CONSISTENT |
| Delivered quantity | `qty_delivered` | `qty_delivered` | CONSISTENT |
| Refused quantity | `qty_refused` | `qty_refused` | CONSISTENT |
| Returned quantity | `qty_returned` | `qty_returned` | CONSISTENT |

## Interpretation
The available evidence supports treating `qty_ordered` and current `qty` as a likely semantic continuity of the original requested quantity, but this equivalence is not promoted to a current Production schema fact without direct schema evidence.

## Required handling
- Do not rename columns because of this report.
- Do not add `qty_ordered` to Current or Production by assumption.
- When Stage-28 or any future schema-sensitive task requires the original-requested quantity, re-prove the exact Production column name first.
- Keep the terminology difference visible in historical/current reconciliation records.

## Status
`DOCUMENTED — NO CODE CHANGE — NO PRODUCTION CHANGE`
