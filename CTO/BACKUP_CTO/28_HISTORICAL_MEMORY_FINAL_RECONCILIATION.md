# 28 — HISTORICAL MEMORY FINAL RECONCILIATION

## Scope
Reconciles historical repository evidence with active CTO memory. No Production change.

## Sources inspected
### Active repository
- `CTO/00_MASTER_CONTEXT.md`
- `CTO/01_SOURCE_AUTHORITY_MAP.md`
- `CTO/03_CURRENT_STATUS.md`
- `Governance/RAWAEA_ARCHITECTURE_CONSTITUTION.md`
- `Governance/EXECUTION_PROTOCOL.md`
- `CTO/TASKS/00_CTO_PROJECT_EXECUTION_LEDGER.md`
- current closeout and Backup CTO memory
- `CTO/BACKUP_CTO/21_HISTORICAL_MEMORY_COMPLETION_DIRECTIVE.md`

### Historical repository
- `docs/00_REVIEW_START_HERE.md`
- `docs/01_PROJECT_OVERVIEW.md`
- `docs/06_SYSTEM_ARCHITECTURE.md`
- `docs/09_DATABASE_DOCUMENTATION.md`
- `docs/10_API_CATALOG.md`
- `docs/11_BUSINESS_WORKFLOWS.md`
- `docs/13_SECURITY_MODEL.md`
- `docs/17_ARCHITECTURAL_DECISIONS.md`
- `docs/18_MODULE_RESPONSIBILITY_MATRIX.md`
- `docs/19_KNOWN_ISSUES_AND_DEBT.md`
- `docs/24_FINAL_CTO_REPORT.md`
- primary original PWA files: vouchers, picker, returns, van-sales
- historical Edge Function tree and inventory/voucher directory
- historical Edge Function report batches, including Batch 01

## Reconciled knowledge

### Project identity
Historical and current records agree that RAWAEA ERP is a distribution/FMCG ERP centered on field execution, runsheets, inventory, delivery, returns and settlement.

### Six-quantity model
Historical source confirms the six quantity model in `order_details`. Current architecture preserves the conceptual importance but Production truth must be checked per current implementation.

### Source-of-truth model
Historical documentation says `order_details` is primary and `run_sheet_details` is a projection. Current architecture retains the source/projection distinction.

### Vehicle / Driver
Historical schema uses separate vehicle and driver fields. Current owner memory makes the separation explicit and treats the vehicle as mobile stock container and representative as custodian.

### DirectSale / VanSale / DirectReturn
- DirectSale: current owner contract = MAIN → VAN.
- VanSale: current owner contract = VAN → CUSTOMER.
- DirectReturn: recorded as VAN → MAIN, but current reconciliation still contains a custody conflict; therefore status remains `CONFLICT`.

### Manual vouchers
Historical source confirms Draft/Sent/Receive/Complete/Cancel style workflow and dedicated voucher UI. Current runtime gates have independently proven selected SEND/RECEIVE/COMPLETE behavior, but complete historical-to-current parity is not yet established.

### Edge Functions
Historical architecture relied heavily on Edge Functions for domain execution. Current architecture is moving responsibility toward central business engines/RPCs. Historical presence is not deployment proof.

### Security
Historical review identified RLS gaps, invoke/supabase.sql issues, cache issues and other defects. These are historical findings. Current state must be determined from current evidence.

## Explicit conflicts

### C-001 — DirectReturn
Historical behavior and current owner contract are not sufficient to close the current custody reconciliation. Status: `CONFLICT`.

### C-002 — Historical voucher mutation vs current centralized movement
Historical functions could directly mutate stock. Current architecture requires centralized stock movement. Status: `HISTORICAL → CURRENT RECONCILIATION REQUIRED`.

### C-003 — Historical UI vs current VanSale implementation
The original Van Sales UI establishes mobile sales behavior, but not the final deployed stock topology. Status: `UNKNOWN/CONFLICT` pending behavioral parity evidence.

### C-004 — Historical financial side effects
Historical documentation claims accounting/ledger effects in several operational functions. Current deployed definitions must be checked before treating those claims as current.

## Unresolved questions
1. Exact current Production equivalence of every original PWA feature.
2. Exact Original→Current→Deployed mapping for every historical Edge Function.
3. Full audit/idempotency semantics for all voucher paths.
4. Complete current Production object map outside the current rescue slice.
5. Whether every historical architecture decision remains active after subsequent CTO work.

## Safe handling
Every unresolved item is explicitly classified `UNKNOWN` or `CONFLICT`. No historical statement is promoted to Production truth without evidence.

## Conclusion
Historical memory is materially richer than the previous CTO reconstruction, and the principal historical behavior, architecture, failure and semantic categories are now represented in durable active-repository records. However, completeness is not 100% because full function-by-function and feature-by-feature deployed parity has not been proven.
