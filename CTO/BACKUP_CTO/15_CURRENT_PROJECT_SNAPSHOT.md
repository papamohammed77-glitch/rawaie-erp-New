# BACKUP CTO 15 — CURRENT PROJECT SNAPSHOT

## Snapshot date
2026-08-13

## Active repository
`papamohammed77-glitch/rawaie-erp-New`

## Historical/reference repository
`papamohammed77-glitch/rawaie-erp-review`

## Current active CTO baseline
`CTO/00_MASTER_CONTEXT.md`
`CTO/01_SOURCE_AUTHORITY_MAP.md`
`Governance/RAWAEA_ARCHITECTURE_CONSTITUTION.md`
`Governance/EXECUTION_PROTOCOL.md`
`CTO/TASKS/00_CTO_PROJECT_EXECUTION_LEDGER.md`

## Current task state
TASK-001 through TASK-027: CLOSED / GO per durable task ledger.

Current next phase:
`STAGE-28 — Loading / Unloading Core`

## Confirmed vehicle custody baseline
Company:
`da4ef704-88ac-4120-aa0e-65b92b2aa2bc`

MAIN:
`151e5cd7-ac4a-4fc3-b703-d73a0dbb0dc6`

Vehicle:
`VEH-92yrzb`
ID `70e5d809-0505-4e60-b317-feff6e799127`

VAN branch:
`VAN-VEH-92yrzb`
ID `dbdef0b7-0909-4f71-a367-30c61d021286`

Representative:
`van-sales@rawaea.com`
ID `a86726d9-d687-4113-a9e2-5f90f4bdb4fa`

## Current central inventory principles
- DirectSale is MAIN → VAN.
- VanSale is VAN → customer.
- DirectReturn is VAN → MAIN.
- SupplierReturn is branch → supplier.
- Inventory movement must go through central engine where defined.
- `allocated_qty` is reservation, not movement.
- `available_qty` is generated/derived where proven.

## Current permanent backend corrections
- `setup_van_stock`: generated-column correction.
- `post_stock_movement`: DirectSale two-sided movement.
- `send_manual_stock_voucher_v2`: target branch comes from voucher.to_id.

## Current validated E2E
`TASK-027 — VOUCHER E2E PASS`

## Important implementation status distinction
The current repository may contain both deployed/current and target/unreleased code. The CTO must always verify deployment state from Production evidence before calling any repository migration deployed.

## Immediate continuation rule
Do not reopen TASK-001..027 unless new Production evidence contradicts the recorded status.
Start by reading the latest STAGE-28 task specification, then inspect current Loading/Unloading Production objects, then compare original implementations before changing anything.
