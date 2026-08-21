# RAWAEA ERP — AUTONOMOUS CTO CONTROL REGISTERS
## Snapshot: 2026-08-21

## 1. Evidence Ledger
| Evidence | Source | Date | Classification | Current Use |
|---|---|---|---|---|
| Physical stock writer = `post_stock_movement(10)` only | Production PostgreSQL | 2026-08-21 | PROVEN FACT | Current architecture |
| Legacy 9-arg stock RPC non-executable by app roles | Production grants | 2026-08-21 | PROVEN FACT | Compatibility residue |
| Manual Voucher V2 execution disabled | Production grants + migration ledger | 2026-08-21 | PROVEN FACT | Current voucher boundary |
| DirectSale target is vehicle stock branch | Production `post_manual_stock_voucher_atomic` / `send_stock_voucher_atomic` | 2026-08-21 | PROVEN FACT | Current contract |
| Inbound target stock row may be initialized in central movement engine | Production `post_stock_movement(10)` | 2026-08-21 | PROVEN FACT | Current inventory contract |
| `items.item_code` globally UNIQUE | Production constraint | 2026-08-21 | PROVEN FACT | Item identity |
| Journal tables exist but journal_lines/customer/supplier/driver ledgers currently have zero rows | Production data snapshot | 2026-08-21 | PROVEN FACT | Accounting/Ledger readiness baseline |
| No public PostgreSQL function currently discovered as direct writer to journal/ledger tables | Production pg_proc writer sweep | 2026-08-21 | PROVEN FACT | Requires Edge/app writer sweep |
| Cross-company metadata checks = 0; companies without app_settings = 0 | Production data checks | 2026-08-21 | PROVEN FACT | Current data-integrity baseline |

## 2. Architecture Decision Registry
| Decision | Current State | Basis | Status |
|---|---|---|---|
| One physical stock engine | `post_stock_movement(10)` | Production writer sweep | CLOSED |
| Reservation separate from physical movement | `reserve_stock` / `release_stock_reservation` | Production definitions | CLOSED |
| Item identity uses globally unique `item_code` plus authoritative `item_id` reference | Production constraint/schema | Production | CLOSED |
| Domain operations should converge on Core RPCs | Current architecture + Production behavior | Production/Governance | ACTIVE |
| ERP-wide accounting/ledger centralization | Not yet proven as implemented | Grand Plan | OPEN TARGET |

## 3. Business Contract Registry
| Contract | Current Evidence | Status |
|---|---|---|
| Picking reserves stock, not physical movement | Production picking RPC | VERIFIED |
| Loading moves MAIN→VAN through Core | Production Core/RPC chain | VERIFIED CORE |
| Unloading moves VAN→MAIN through Core | Production Core/RPC chain | VERIFIED CORE |
| DirectSale sends stock to vehicle branch context | Production Voucher Core | VERIFIED CORE |
| Partial Receive accumulates `received_qty` | Production Voucher Core | VERIFIED CORE |
| Voucher UI full parity with original behavior | Not yet runtime proven | OPEN |
| Accounting effect per inventory event | Not fully proven | OPEN |
| Ledger effect per business event | Not fully proven | OPEN |

## 4. Owner Decision Registry
No unresolved Owner Decision has been required to close the current inventory facts. Business questions that truly cannot be resolved from evidence must be recorded here before implementation depends on them.

## 5. Rejected Alternative Registry
| Alternative | Reason rejected | Evidence |
|---|---|---|
| Keep parallel direct physical stock writers | Violates central stock authority | Production writer sweep |
| Treat reservation as physical movement | `allocated_qty` is separate state | Production reservation functions |
| Treat Git-only migration as Production proof | Production ledger is authoritative | CTO governance |
| Declare ERP-wide autonomy after Inventory closure | Evaluation identified material Accounting/Ledger/Fulfillment/Consumer gaps | Autonomous Readiness assessment |

## 6. Unknown Register
| Unknown | Materiality | Next Evidence |
|---|---|---|
| Complete Accounting posting contract | HIGH | Edge/app writer sweep + historical contract reconciliation |
| Complete Ledger writer ownership | HIGH | Edge/app sweep + runtime/data evidence |
| Full order→fulfillment state graph | HIGH | Current PWA + Edge + RPC + data flow |
| Full Consumer graph for critical RPCs | HIGH | Current PWA/Edge mapping + runtime |
| Full deployment lineage per critical component | HIGH | Git commit → deployment → runtime evidence |
| Independent-session concurrency proof where required | HIGH | Real parallel-session tests |
| Full Voucher UI feature parity | HIGH | Original vs Current static matrix + browser E2E |

## 7. Conflict Register
| Earlier Claim | Current Evidence | Corrected State |
|---|---|---|
| 19-Aug historical baseline showed cross-company metadata rows | 2026-08-21 Production checks now return 0 for stock_branches, inventory_log, order_details | Historical fact only; current anomaly count = 0 |
| 19-Aug reports treated some Voucher/DirectSale behavior as unresolved | 20-Aug/21-Aug Production migrations and RPCs now implement DirectSale vehicle target and retry hardening | Superseded by current Production |
| Older master context stated some Manual Voucher schema/contract defects | Current 2026-08-21 Production rebaseline must supersede those statements where later migrations repaired them | Older statements retained only as historical evidence |

## 8. Trap Register — Re-proven
- Git state is not Production state.
- Historical reports age out.
- Legacy RPC object existence does not imply application reachability.
- `verify_jwt` metadata alone does not prove authorization.
- Reservation state must not be conflated with physical stock.
- Production test data must not be treated as business truth without classification.
- A zero-row ledger is not proof that a ledger architecture is complete.
- Absence of a direct PostgreSQL writer does not prove the absence of an Edge/application writer.
