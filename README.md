# RAWAEA ERP — CTO Recovery Baseline

**Repository:** `papamohammed77-glitch/rawaie-erp-New`

**Baseline branch:** `recovery/cto-curated-baseline`

## Purpose

This repository is a clean, curated execution baseline extracted from the two RAWAEA ERP repositories:

- `papamohammed77-glitch/rawaie-erp-review`
- `papamohammed77-glitch/rawaie-erp-New`

It is intentionally **not** a blind copy.

Only material verified from the latest accessible rescue branch, persisted Production Evidence, or current implementation was admitted to the operational baseline.

## Authority order

1. `01_GOVERNANCE/RAWAEA_ARCHITECTURE_CONSTITUTION.md`
2. `01_GOVERNANCE/EXECUTION_PROTOCOL.md`
3. `01_GOVERNANCE/EXECUTION_GUARDRAILS.md`
4. `01_GOVERNANCE/DOMAIN_EXECUTION_ORDER.md`
5. `02_STATUS/INVENTORY_VOUCHERS_VANSALES_EXECUTION_STATUS.md`
6. `04_EVIDENCE/*` — Production evidence is authoritative for current Production state
7. `05_VOUCHERS/CURRENT/*` — current Git implementation evidence
8. `06_LEGACY/ORIGINAL/*` — historical behavior only; never treated as Target automatically
9. `07_ASSISTANTS/*` — analysis/review records; not architecture authority

## Critical rule

**No guessing. No invented schema. No invented Business Rules. No Production change without an approved Target contract and validation plan.**

## Current state

The Inventory / Manual Voucher work remains **BLOCKED / NOT GO** at the last recorded gate.

The confirmed critical issue is a Production RPC / Schema mismatch involving `stock_vouchers.completed_by`. Additional unresolved contracts include Partial RECEIVE idempotency, DirectSale/DirectReturn custody semantics, and complete end-to-end Van Sales evidence.

## Important exclusions

Known mixed, speculative, stale, or unreleased material was deliberately excluded from the authoritative folders. The source repository remains the historical archive.

See `00_CTO/01_SOURCE_AND_AUTHORITY.md` for the exact admission/exclusion policy.
