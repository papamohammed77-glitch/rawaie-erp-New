# PRODUCTION CHANGE LEDGER

## Current snapshot
`2026-08-23 03:41:38.004558 UTC`

## Applied migration head
`20260822182733 fix_post_journal_entry_schema_drift_20260822`

## Evidence rule
A migration existing in Git is not deployment evidence. The rows in this ledger are marked by actual Production migration inventory and live deployed Edge metadata.

| Date/sequence | Change | Type | Object | Production evidence | Current status |
|---|---|---|---|---|---|
| 2026-08-14→17 | Central Inventory Core rewires | DDL/RPC | inventory writers | Applied migrations; current `post_stock_movement` exists | Surviving |
| 2026-08-16 | Legacy manual stock posting retirement line | DDL/RPC | manual voucher RPCs | Applied migrations | Legacy residue classified/execution-restricted |
| 2026-08-17 | Inventory rescue / global item master alignment | DATA/DDL | items/stock identity | Applied migrations | Current item identity is `item_id` + globally unique `item_code` |
| 2026-08-17 | Receive idempotency numeric fingerprint | RPC/logic | `receive_purchase_atomic` | Applied migrations | Superseded by later explicit operation identity lineage |
| 2026-08-19 | Inventory write boundary zero-debt | DDL/RPC | inventory writers | Applied `20260819050353` | Physical writer boundary verified |
| 2026-08-19 | Tenant-safe inventory/voucher boundary | DDL/RPC | voucher/read/write boundaries | Applied migrations | Surviving |
| 2026-08-19 | Purchase receive idempotency + tenant closure | RPC | `receive_purchase_atomic` | Applied migrations | Current Core active; consumer identity remains to be checked per operation |
| 2026-08-19 | Return/delivery operation centralization | RPC | returns/delivery | Applied `20260819010619` and later | Current |
| 2026-08-20 | Legacy manual voucher V2 disabled | DDL/grants | `send_manual_stock_voucher_v2`, `receive_manual_stock_voucher_v2` | Applied `20260819235822`; current grants checked historically | Execution-blocked legacy residue |
| 2026-08-20 | Warehouse team read scope | DDL/RPC | `get_warehouse_team` | Applied | Current |
| 2026-08-20 | Tenant-safe main CRUD | DDL/RPC | main CRUD capabilities | Applied `20260820035950` | Current in reviewed paths |
| 2026-08-20 | Target inbound stock row auto-init | RPC | `post_stock_movement` | Applied `20260820154957` | Current |
| 2026-08-20 | Voucher retry idempotency | RPC | send voucher | Applied `20260820155958` | Current |
| 2026-08-20 | Vehicle lifecycle contract | RPC | voucher Vehicle/mobile branch | Applied `20260820180154` | Current |
| 2026-08-20 | DirectSale target stock correction | RPC | `send_stock_voucher_atomic` / manual voucher | Applied `20260820183912` | Current |
| 2026-08-21 | Test voucher/orphan company cleanup | DATA | production fixture cleanup | Applied `20260821023255` | Historical cleanup reflected in current zero voucher rows |
| 2026-08-21 | Orphan inventory-log cleanup | DATA | `inventory_log` | Applied `20260821023458` | Current count is 3; provenance of remaining drift still tracked |
| 2026-08-22 | Central journal core/report join | RPC | `post_journal_entry` / reporting | Applied `20260822032213` | Current |
| 2026-08-22 | Atomic cash receipt/payment cores | RPC | receipt/payment cores | Applied `20260822182631`, `20260822182713` | Current but global financial convergence remains open |
| 2026-08-22 | Journal schema drift repair | RPC | `post_journal_entry` | Applied `20260822182733` | Current migration head |

## Live Edge deployment evidence — critical functions
- `save-sales-invoice` v15 ACTIVE
- `start-picking` v33 ACTIVE
- `complete-picking` v16 ACTIVE
- `complete-loading` v11 ACTIVE
- `complete-return` v24 ACTIVE
- `create-stock-voucher` v8 ACTIVE
- `send-stock-voucher` v19 ACTIVE
- `receive-stock-voucher` v21 ACTIVE
- `complete-stock-voucher` v4 ACTIVE
- `cancel-stock-voucher` v4 ACTIVE
- `receive-purchase` v12 ACTIVE
- `save-journal-entry` v8 ACTIVE
- `save-receipt-voucher` v5 ACTIVE
- `save-payment-voucher` v3 ACTIVE
- `save-daily-settlement` v3 ACTIVE
- `update-driver-ledger` v1 ACTIVE
- `complete-order-delivery` v13 ACTIVE

## Registry residue
Temporary/canary/harness functions remain registered ACTIVE, including several observed in runtime as HTTP 410. Exact deletion is not proven. They remain `GOVERNANCE OPEN`, not silently deleted.

## Required distinction
`Migration Applied` ≠ `Edge Deployed` ≠ `Browser Runtime Verified`.