# PROJECT SOURCE INVENTORY

## Primary application source
- `PWA/main.html`
- `PWA/core.js`
- `PWA/app.html`
- `PWA/index.html`
- `PWA/sw.js`
- `PWA/register-sw.js`
- `PWA/schema-validator.js`
- `PWA/warehouse/vouchers.html`
- `PWA/sales/van-sales.html`
- Warehouse: `counter.html`, `loader.html`, `manager.html`, `picker.html`, `receiver.html`, `returns.html`, `supervisor.html`, `unloader.html`
- Sales: `manager.html`, `order-taker.html`, `pos.html`, `supervisor.html`, `telesales.html`, `van-sales.html`
- Delivery: `driver.html`, `supervisor.html`
- Purchasing: `buyer.html`, `supervisor.html`
- Store: `index.html`, `track.html`

## Backend source
The original repository contains:
- `Edge_Functions/original/01_order_lifecycle`
- `02_picking`
- `03_loading`
- `04_runsheet`
- `05_delivery`
- `06_returns`
- `07_settlement`
- `08_inventory`
- `09_purchasing`
- `10_master_data`
- `11_accounting`
- `12_sales`
- `13_reporting`
- `14_infrastructure`
- `15_treasury`
- `16_ledger/legacy`

Current inventory source includes:
- `Edge_Functions/current/inventory/send-stock-voucher.ts`

## Database source/evidence
- `SQL_Evidence/schema/tables.csv`
- `SQL_Evidence/schema/Foreign Keys.csv`
- `SQL_Evidence/schema/Indexes.csv`
- `SQL_Evidence/schema/Primary Keys.csv`
- `SQL_Evidence/schema/Enum Types.csv`
- `SQL_Evidence/schema/Database Functions.csv`
- `SQL_Evidence/schema/استعلام RLS Policies.csv`
- `SQL_Evidence/diagnostics/*`

## Architecture and governance
- `Architecture/RAWAEA_ARCHITECTURE_CONSTITUTION.md`
- `Architecture/EXECUTION PROTOCOL.md`
- `Architecture/EXECUTION_GUARDRAILS.md`
- `Architecture/DOMAIN_EXECUTION_ORDER.md`
- `Architecture/INV-001 — INVENTORY REALITY MAP.md`
- `Architecture/الأذونات المخزنية اليدوية.md`

## Historical review corpus
- `Edge_Function_Reports/_HISTORICAL/Batch01.md` … `Batch15.md`
- `Edge_Function_Reports/_HISTORICAL/RAWAEA ERP HANDOVER.md`
- `Edge_Function_Reports/_HISTORICAL/van-sales report.md`
- `Edge_Function_Reports/_HISTORICAL/INV-001 — INVENTORY REALITY MAP.md`
- `Edge_Function_Reports/_HISTORICAL/INV-002 — INVENTORY SOURCE OF TRUTH.md`
- `Edge_Function_Reports/_HISTORICAL/RAWAEA ERP - Architecture Audit Register.csv`

## Current rescue corpus
- Hussein Phase 1 Production Contract.
- Morad Phase 1 Adversarial Review.
- Production diagnostics listed under `Evidence/Production/` in this repository.

## Preservation rule
The full original source remains immutable in the original repository until a deliberate source snapshot is copied into this repository. This inventory prevents loss of discoverability while avoiding accidental promotion of historical material to current truth.