# RAWAEA ERP — CTO Curated Recovery Repository

This repository is the curated CTO knowledge baseline for the RAWAEA ERP recovery effort.

## Start here
1. `CTO/00_MASTER_CONTEXT.md`
2. `CTO/01_SOURCE_AUTHORITY_MAP.md`
3. `Governance/RAWAEA_ARCHITECTURE_CONSTITUTION.md`
4. `Governance/EXECUTION_PROTOCOL.md`
5. `CTO/03_CURRENT_STATUS.md`
6. `Inventory/Manual-Vouchers/01-CONTRACT.md`
7. `Evidence/Production/`
8. `Rescue/`

## Critical rule
Production Evidence is not interchangeable with historical documentation or unreleased migrations.

Every implementation decision must follow:

**Evidence → Reconciliation → Target Decision → Minimal Patch → Tests → Review → CTO GO → Post-Deploy Verification**

## Source repositories
- Review/source repository: https://github.com/papamohammed77-glitch/rawaie-erp-review
- This curated repository: https://github.com/papamohammed77-glitch/rawaie-erp-New/tree/cto/curated-baseline-v1

## Current status
**NO GO — Inventory / Manual Vouchers / Van Sales reconciliation remains open.**

No Production SQL has been executed by this curated baseline.

<!-- CTO-P163-TRIGGER-2026-09-03 -->