# TASK-007 — Custody Matrix

## Status
**COMPLETE / GO TO TASK-008**

## Objective
Freeze the custody model at the highest evidence level currently available, explicitly separating:

1. Production physical-stock custody represented by `stock_branches` / branch identities.
2. Operational custody semantics described by the historical Manual Voucher and Van Sales documents.
3. Current Production RPC representation where it differs from historical/target custody semantics.

## Evidence Authority
- Production Data Contract: `CTO/TASKS/TASK-002-INVENTORY-DATA-CONTRACT.md`.
- Production Voucher Contract: `CTO/TASKS/TASK-003-VOUCHER-DATA-CONTRACT.md`.
- Production lifecycle/RPC evidence used in TASK-004/TASK-005.
- Historical Manual Voucher architecture: `Architecture/الأذونات المخزنية اليدوية.md`.
- Historical Van Sales model: `Edge_Function_Reports/_HISTORICAL/van-sales report.md`.
- Current source authority rules: `CTO/01_SOURCE_AUTHORITY_MAP.md`.

## Core Custody Rule
`stock_branches` is the captured Production representation of physical stock custody at branch/item level. The Production schema also contains generic Voucher custody metadata through `from_type/from_id` and `to_type/to_id`, while the captured Production Voucher contract currently validates the supported Create types against Branch/Supplier combinations.

Therefore:

- **Physical inventory custody proven in Production:** branch-based through `stock_branches`.
- **Operational/person/vehicle custody:** only proven where explicitly represented by current Production data/logic; historical vehicle/driver custody must not be promoted to current Production truth without target reconciliation.

## Custody Matrix

| Movement | Current Production custody representation | Operational custody meaning from reference material | Status |
|---|---|---|---|
| Transfer | Branch A → Branch B | Stock responsibility moves from source branch to destination branch after SEND/RECEIVE lifecycle | **PROVEN** |
| DirectSale | Source is Branch; current CREATE RPC requires `to_type='Branch'` and `to_id` to be a company branch | Historical architecture defines this as issuing stock to a Van Sales driver/vehicle as temporary custody, outside Runsheet | **CURRENT SCHEMA PROVEN / OPERATIONAL CUSTODY UNRESOLVED** |
| DirectReturn | Current Voucher RPC path is Branch-typed for source/target and RECEIVE adds stock to voucher target branch | Historical architecture defines return as vehicle/driver custody → branch | **CURRENT SCHEMA PROVEN / OPERATIONAL CUSTODY UNRESOLVED** |
| SupplierReturn | Branch → Supplier in current CREATE/POST contract | Operational responsibility leaves branch and is returned to supplier | **PROVEN** |
| Scrap | Historical document describes warehouse/scrap custody → disposal/no destination | Current Production CREATE RPC does not accept `Scrap` | **HISTORICAL ONLY / NOT CURRENT PRODUCTION CONTRACT** |
| Adjustment | Historical document describes inventory reconciliation rather than transfer between custodial parties | Current Production CREATE RPC does not accept `Adjustment` | **HISTORICAL ONLY / NOT CURRENT PRODUCTION CONTRACT** |

## Van Sales Custody
The historical Van Sales report explicitly models the vehicle as temporary inventory custody. It describes stock being transferred from the main warehouse to a vehicle/driver custody represented logically as a temporary branch such as `VAN-<driver_email>`, with `stock_branches` used to track that custody. It also states that the independent Van Sales application was not yet a fully independent unit and that some portions of this model were incomplete/not implemented. This remains historical/reference evidence, not current Production truth. fileciteturn211file0

## Runsheet vs Van Custody
The Van Sales reference explicitly distinguishes Van Sales from Runsheet operations: the Van Sales representative leaves with unsold stock as custody, sells directly, collects cash/credit, and returns for settlement; Runsheet is an order-delivery path for pre-confirmed orders. fileciteturn211file0

## Current Production DirectSale / DirectReturn Boundary
The captured Production CREATE RPC currently accepts these types:
- `Transfer`
- `DirectSale`
- `DirectReturn`
- `SupplierReturn`

For `DirectSale` and `DirectReturn`, the current RPC validation requires Branch source and Branch target. This is current Production evidence and therefore outranks the historical document for current implementation decisions. The historical document's vehicle/driver custody semantics remain an unresolved Target/Custody question, not a fact to be silently rewritten into the current Production model. fileciteturn222file0

## Custody vs Physical Stock
Custody is not equivalent to a stock mutation itself.

- `stock_branches.qty` remains the physical balance source of truth.
- `allocated_qty` remains reservation and is not a custodial transfer.
- `inventory_log` records movement history but does not become a separate custody ledger.
- Voucher `from_type/from_id` and `to_type/to_id` describe movement parties within the Voucher contract; they do not by themselves prove a non-branch physical stock store.

## Important Unresolved Target Decisions
1. Whether `DirectSale` in the Target design must represent Branch → Van/Driver custody directly, or whether the Van/Driver is represented through a dedicated branch identity.
2. Whether `DirectReturn` in the Target design must represent Van/Driver custody → Branch and how that custody is encoded.
3. Whether vehicle custody is always represented as a Branch-level stock location in the final Target Design.

These are deliberately left unresolved because the available current Production and historical sources do not establish a single reconciled Target representation. No assumption is made.

## Gate Decision
**TASK-007 CLOSED / GO.**

The custody matrix is complete at the evidence boundary: current Production custody is frozen, historical Van/Driver custody is preserved as reference semantics, and the DirectSale/DirectReturn target representation is explicitly isolated as a Target Decision rather than silently treated as current truth.

## Next Task
**TASK-008 — Movement Types Contract**
