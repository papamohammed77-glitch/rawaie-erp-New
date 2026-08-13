# CTO SOURCE MIGRATION NOTICE

## Effective rule
As of this record, `papamohammed77-glitch/rawaie-erp-New` is the **sole active CTO source repository** for the RAWAEA ERP recovery work.

## Historical repository
`papamohammed77-glitch/rawaie-erp-review`

This repository remains a historical/reference archive. It may be consulted for original code, historical reports, prior reviews, PR history and provenance, but it is no longer the authoritative location for active CTO task records.

## Why the migration was made
The active implementation/recovery work was being recorded across a review repository while the newer curated CTO baseline already existed in `rawaie-erp-New`. This creates unnecessary split-brain risk for future CTOs.

The new rule eliminates that ambiguity:

**Current CTO Truth → `rawaie-erp-New`**

Historical context may be retrieved from `rawaie-erp-review` only when explicitly required and must remain classified as historical unless reconciled with current Production evidence.

## Existing curated baseline retained
The curated baseline already present in this repository remains authoritative:
- `CTO/00_MASTER_CONTEXT.md`
- `CTO/01_SOURCE_AUTHORITY_MAP.md`
- `CTO/02_HISTORICAL_KNOWLEDGE_INDEX.md`
- `CTO/03_CURRENT_STATUS.md`
- `CTO/04_PROJECT_SOURCE_INVENTORY.md`
- `CTO/05_TRUTH_RECONCILIATION.md`
- `Inventory/Manual-Vouchers/01-CONTRACT.md`
- `Evidence/Production/`
- `Governance/RAWAEA_ARCHITECTURE_CONSTITUTION.md`
- `Governance/EXECUTION_PROTOCOL.md`

## New unified execution ledger
`CTO/TASKS/00_CTO_PROJECT_EXECUTION_LEDGER.md`

This ledger consolidates the execution status and the durable business/Production decisions reached through TASK-027.

## Next-CTO rule
Do not continue from the historical repository's task numbering, comments or old design proposals unless the corresponding fact is already represented/reconciled in this repository.

Start from the unified ledger and the current master context.
