# TASK-028 — RESPONSIBILITY MATRIX

| Responsibility | Historical / Production Legacy | Current Target | Decision |
|---|---|---|---|
| Picked -> Loading state | Edge wrapper + direct DB updates | `start_runsheet_loading` RPC | Moved to transactional DB capability |
| Physical Loading MAIN -> VAN | `complete-loading` direct stock mutation | `post_stock_movement(Loading)` | Replaced by central stock boundary |
| Loading reservation consumption | Legacy mixed stock logic | Central engine: `allocated_qty -= loaded_qty` | Replaced |
| Physical Unloading VAN -> MAIN | `unload-runsheet` direct stock mutation | `post_stock_movement(Unloading)` | Replaced by central stock boundary |
| Reopen physical reversal | Production v1 direct MAIN write | Central `Unloading` movement through Reopen RPC | Replaced |
| Reopen `qty_loaded` preservation | Production behavior preserved | Reopen leaves `order_details.qty_loaded` unchanged | Retained intentionally |
| Loading cancellation | Production v4 state rollback | `cancel_runsheet_loading` | Retained, state-only; no physical stock mutation |
| Inventory logging | Multiple writers | Central stock engine | Consolidated |
| Event idempotency | Random log code / state gate | deterministic event key + unique inventory_log index | Replaced |
| Backorder tracking | Loading-side ad hoc behavior | `fulfillment_backorders` ledger | Replaced / centralized |
| Runsheet detail aggregation | Trigger behavior | unique `(runsheet_id,item_code)` + UPSERT trigger | Hardened |
| COGS / journal posting | Not owned by Loading/Unloading | No accounting mutation in TASK-028 | Intentionally excluded |
| UI Loading calls | Existing PWA consumers | Existing request contracts preserved | Retained |
| Reopen / Cancel UI consumers | None found in Current PWA | No UI contract change required | No consumer to migrate |

## Acquisition / Comparison Evidence
- Production `reopen-loading` v1 was inspected and showed direct MAIN stock mutation and Loaded -> Loading state transition.
- Current wrappers were inspected and are RPC-only capability wrappers. fileciteturn409file0 fileciteturn408file0
- Current PWA was inspected for actual consumers: `start-loading`, `complete-loading`, and `unload-runsheet` are active consumers; request payloads remain compatible. fileciteturn422file0
- Historical/Original PWA contains the same Loading/Unloading consumer pattern; no Reopen/Cancel consumer was found. fileciteturn423file0

## Classification
TASK-028 is a Controlled Refactor because responsibility moved from distributed Edge Function stock mutation into a central PostgreSQL stock boundary. The UI request surface was preserved rather than rewritten.
