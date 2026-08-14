# TASK-028 PRE-CHANGE RESPONSIBILITY MATRIX

## Scope
`complete-loading`, `unload-runsheet`, `start-loading`, `cancel-loading`, `reopen-loading`, and the Loading/Unloading Core boundary.

## Evidence Authorities
- Original: `rawaie-erp-review` historical source.
- Current Before Patch: `rawaie-erp-New/main`.
- Production: deployed Supabase Edge Function definitions and read-only schema evidence.
- Target: Principal CTO-approved TASK-028 contract.

| Responsibility | Original | Production | Current Before | Current After | Target | Status |
|---|---|---|---|---|---|---|
| Authenticate request | Yes | Yes | Yes | Yes | Required | PRESERVED |
| Validate Runsheet state | Loading required | Loading required | Loading required | Loading required | Loading required | PRESERVED |
| Resolve MAIN branch | app_settings | app_settings | app_settings | app_settings | company-scoped | PRESERVED / HARDENED |
| Resolve vehicle/VAN branch | Not central | Production legacy path | Legacy/current capability | Core RPC | canonical Vehicle branch | MOVED |
| Direct stock mutation | Yes | Yes | Yes | No | Core only | MOVED |
| Inventory log write | Yes | Yes | Yes | No | Core only | MOVED |
| COGS journal creation | Yes | Yes | Yes | No | No COGS at Loading/Unloading | INTENTIONALLY REMOVED |
| `order_details.qty_loaded` | Yes | Yes | Yes | Core only | authoritative fulfillment quantity | PRESERVED / CENTRALIZED |
| `run_sheet_details.qty_loaded` | Yes | Direct/trigger mix | Legacy direct-write path | Trigger-derived | derived aggregate | REPLACED |
| Legacy `remaining_qty` write | Yes | Yes / legacy attempt | Yes / incompatible | No | not part of current schema | OBSOLETE |
| Backorder child Order creation | Yes | Yes | Yes | No | durable Backorder ledger | REPLACED |
| Backorder ledger | No | No | No | Yes | durable fulfillment ledger | ADDED |
| Runsheet `Loading -> Loaded` | Yes | Yes | Yes | Core RPC | required | PRESERVED |
| Runsheet `Loaded -> Picked` | Yes | Yes | Yes | Core RPC | required | PRESERVED |
| Orders set Loaded/Pending | Yes | Yes | Yes | Core RPC | required | PRESERVED |
| Stock allocation release on Loading | Yes | Yes | Yes | Core | consume picked reservation | PRESERVED / CORRECTED |
| Stock allocation restoration on Unloading | Not symmetric | Not symmetric | Not symmetric | Core | exact inverse | CORRECTED |
| Event-level idempotency | State/retry only | Random log code + state gate | Random log code + state gate | Deterministic key + unique index | required | P0 CORRECTION |
| Failure rollback | None as one operation | sequential calls | sequential calls | PostgreSQL function transaction | atomic | REPLACED |
| `start-loading` lifecycle gate | Production v3 | Yes | Current source not present in active branch | Not modified | remains lifecycle entry point | VERIFIED / NO CHANGE |
| `cancel-loading` | clears loaded quantities/state, no stock reversal | v4 | not modified | not modified | remains non-stock cancel | VERIFIED / NO CHANGE |
| `reopen-loading` | lifecycle helper | production source reviewed | not modified | not modified | must remain compatible | REVIEW REQUIRED |

## Controlled Refactor Classification

The reduction of `complete-loading` and `unload-runsheet` is a **CONTROLLED REFACTOR**, not a one-line surgical patch, because responsibilities are deliberately moved from distributed Edge code into transactional PostgreSQL Core RPCs.

## Removal Safety

No responsibility is considered deleted merely because it disappeared from the Edge Function. Each removed block is classified above as `MOVED`, `REPLACED`, `INTENTIONALLY REMOVED`, or `OBSOLETE`.

## Protected Assets

- `Original/` untouched.
- Production database untouched.
- Production Edge Functions not deployed from this branch.

## Open Review Item

`reopen-loading` deployed source must be opened and compared before final Runtime acceptance. No production claim is made for that comparison until direct deployed evidence is recorded.
