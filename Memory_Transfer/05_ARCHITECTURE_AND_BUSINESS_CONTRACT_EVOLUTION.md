# ARCHITECTURE AND BUSINESS CONTRACT EVOLUTION

## Target architecture
`PWA/UI → Edge Capability → PostgreSQL Domain Core/RPC → authoritative state → audit/accounting/ledger effects`

## Contract evolution
### Inventory
Historical distributed stock mutations were progressively converged into:
`Business operation → domain RPC → post_stock_movement → stock_branches + inventory_log`.
Current direct Production SQL verifies the central writer boundary.

### Reservation
`reserve_stock` and `release_stock_reservation` own allocation only. They are not physical movement engines.

### Voucher
Historical six-type vocabulary became a current four-lifecycle Voucher Core:
- Transfer
- DirectSale
- DirectReturn
- SupplierReturn

Scrap/Adjustment are Adjustment Engine operations, not invented voucher lifecycles.

### Vehicle
Vehicle and Representative are distinct identities. Current Production resolves Vehicle mobile stock context before physical movement.

### Item Identity
Current `items.item_code` is globally UNIQUE and `item_id` is the durable row identity. Do not invent company-scoped uniqueness where the live schema does not define it.

### Tenant Identity
Live contract:
`auth.users.id → public.users.auth_id → public.users.id → company_id → authorization scope`.
Current `start-picking` Production v33 and current Git use this contract.

### Fulfillment Authority
`order_details` is authoritative fulfillment detail; `run_sheet_details` is derived/aggregated state where the current contract requires it.

### Accounting
A central `post_journal_entry` core exists and `save-journal-entry` v8 uses it, but domain writers remain distributed. Therefore Accounting Core is deployed/strong but Writer Convergence is OPEN.

### Treasury
Treasury contains its own account identity conventions (e.g. historical `CASH-01`) while journal lines use COA UUIDs. No universal mapping is invented without proof.

## Governance transitions
The project repeatedly learned that:
- Historical UI completeness can be false.
- Git completeness can be false.
- Migration existence can be mistaken for deployment.
- Production deployment can be mistaken for browser runtime.
- Legacy objects can remain executable unless grants are explicitly controlled.
- A repair layer can introduce new defects.
- RLS can masquerade as missing data.
- Identity keys must be verified live.

## Surviving target architecture
Inventory and Voucher responsibilities are strongly separated. The remaining architectural debt is financial writer convergence, Consumer Matrix, Deployment Lineage, Fulfillment closure, Concurrency, and Global Zero-Debt outside Inventory.