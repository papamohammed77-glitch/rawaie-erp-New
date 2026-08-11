# SOURCE AUTHORITY MAP

## Rule
This map separates **current confirmed evidence** from **historical/reference material** and **unreleased target candidates**.

| Layer | Source | Status | Use |
|---|---|---|---|
| Production Evidence | `SQL_Evidence/diagnostics/` from rescue branch | CONFIRMED for captured facts | Primary schema/state evidence |
| Deployed RPC evidence | `SQL_Evidence/diagnostics/2) All manual-voucher RPC definitions.csv` | CONFIRMED for captured definitions | Compare RPC vs schema |
| RPC privileges | `SQL_Evidence/diagnostics/3) RPC privileges.csv` | CONFIRMED for captured execution context | Security review |
| Inventory log contract | `SQL_Evidence/diagnostics/5) Inventory-log actual contract.csv` | CONFIRMED | Do not invent columns |
| Company/branch evidence | diagnostics 6 and 7 | CONFIRMED | Context isolation |
| Stock snapshot | diagnostics 8 | CONFIRMED snapshot only | Not a timeless balance |
| Actual indexes | `SQL_Evidence/diagnostics/الفهارس الفعلية.csv` | CONFIRMED | Constraint/idempotency analysis |
| Current UI | `PWA/warehouse/vouchers.html`, `PWA/sales/van-sales.html` | CURRENT SOURCE | Consumer behavior; not Production proof |
| Current Inventory Edge | `Edge_Functions/current/inventory/` | CURRENT SOURCE | Current service behavior |
| Original Edge Functions | `Edge_Functions/original/` | HISTORICAL | Preserve and compare; never assume Target |
| Architecture Constitution | `Architecture/RAWAEA_ARCHITECTURE_CONSTITUTION.md` | ACTIVE ARCHITECTURE | Governing architectural laws |
| Execution Protocol | `Architecture/EXECUTION PROTOCOL.md` | ACTIVE PROCESS | Change-control rules |
| Domain Execution Order | `Architecture/DOMAIN_EXECUTION_ORDER.md` | ACTIVE PROCESS | Inventory-first order |
| Old docs 00-24 | `docs/` | HISTORICAL BASELINE | Project knowledge; reconcile claims |
| Handover | `Edge_Function_Reports/_HISTORICAL/RAWAEA ERP HANDOVER.md` | HISTORICAL HANDOVER | Broad institutional knowledge |
| Unreleased migrations | `supabase/migrations/20260810_*` on rescue branch | TARGET CANDIDATE / NOT PRODUCTION | Review only; never call deployed |
| Hussein Phase-1 report | `Architecture/CTO/ASSISTANTS/HUSSEIN/OUTBOX/PHASE-1-PRODUCTION-CONTRACT.md` | CURRENT RESCUE ANALYSIS | Strong reconciliation baseline |
| Morad adversarial review | `Architecture/CTO/ASSISTANTS/MORAD/OUTBOX/PHASE-1-ADVERSARIAL-REVIEW.md` | CURRENT RESCUE REVIEW | Challenge/defect detection |

## Important stale-document warning
Older documents contain claims such as exact table counts, completeness percentages and architectural confidence scores. These must not override newer Production Evidence. Example: historical documentation describes a broader `stock_vouchers`/audit model than the captured Production schema. The rescue Evidence is therefore the controlling source for current Inventory implementation decisions.
