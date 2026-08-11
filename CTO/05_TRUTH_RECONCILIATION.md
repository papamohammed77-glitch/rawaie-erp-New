# TRUTH RECONCILIATION LEDGER

| Topic | Historical claim | Latest evidence | CTO classification |
|---|---|---|---|
| Project table count | 51/52 in different docs | Current evidence snapshots are table-specific | HISTORICAL COUNT — do not use as current fact |
| `stock_vouchers.completed_by` | Some RPC/design material assumes it | Captured Production schema does not contain it | CONFLICT / PROVEN DEFECT |
| `inventory_log.branch_id` | Mentioned in some architecture/material | Captured actual contract does not contain it | HISTORICAL/DOCUMENTATION DRIFT |
| DirectSale | Historical/domain docs describe vehicle custody; current captured POST is OUT source only | Current Production behavior is OUT source only | CURRENT PRODUCTION FACT; TARGET UNRESOLVED |
| DirectReturn | Historical/domain docs describe vehicle → warehouse | Current captured RECEIVE is IN destination only | CURRENT PRODUCTION FACT; TARGET UNRESOLVED |
| Partial RECEIVE | Historical lifecycle allows partial receive | Captured current contract accumulates `received_qty` | CONFIRMED CURRENT BEHAVIOR |
| Partial RECEIVE idempotency | Not explicitly documented | No independent operation identity proven in captured schema/index evidence | UNPROVEN / BLOCKING |
| CANCEL | Lifecycle documented | Complete deployed definition not captured in persisted rescue evidence | UNKNOWN |
| Audit | General `audit_log` architecture documented | COMPLETE/CANCEL audit writes not proven | UNKNOWN |
| `send_stock_voucher_atomic` | Older atomic SEND path exists | Current `send-stock-voucher.ts` calls it | CURRENT IMPLEMENTATION FACT |
| `post_manual_stock_voucher_atomic` | Newer manual voucher core exists in rescue work | Not proven as sole current consumer | TARGET/CANDIDATE — not migration-complete |
| Reconciled migration | Designed as a fix | Explicitly not Production-executed | TARGET CANDIDATE ONLY |

## Rule
This ledger is the antidote to the previous failure mode: no document is allowed to silently overwrite another document's meaning. Every conflict remains visible until a CTO decision or new Production evidence closes it.