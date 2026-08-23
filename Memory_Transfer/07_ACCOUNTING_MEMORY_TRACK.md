# ACCOUNTING MEMORY TRACK

## CURRENT SNAPSHOT
2026-08-23 03:41:38.004558 UTC

## CURRENT PRODUCTION FACTS
- `save-journal-entry` Edge v8 ACTIVE.
- `post_journal_entry` Core is deployed.
- `save_sales_invoice_atomic`, `receive_purchase_atomic`, `complete_return_atomic` and other domain operations create financial effects.
- Receipt/payment/daily-settlement/driver-ledger capabilities are also deployed.
- `journal_entries` = 2; `journal_lines` = 0 at this snapshot.

## HISTORICAL TRANSITION
The system evolved from distributed journal writes toward a stronger centralized journal core. Prompt 51/52 then identified the remaining problem as Consumer/Writer convergence rather than absence of an Accounting Core.

## CURRENT JOURNAL CONTRACT
Current `save-journal-entry` v8 → authenticated user → company context → account code → COA UUID → `post_journal_entry` → journal state + operation registry + authoritative audit.

The current core validates minimum lines, account identity/company ownership, non-negative amounts, single-sided line values, balanced totals and idempotency.

## CURRENT CONSUMER GAP
`Current/PWA/main.html::_saveJournalEntry()` was historically found stale. Report 52 prepared a surgical replacement aligned to the current DOM (`journal-ref`, `journal-desc`, `jl-cost-center`) and Production v8. That replacement was reviewed but the published `main.html` was deliberately not altered in that surgical review.

Therefore:
**Production Journal Core = STRONG / CURRENT**
**Manual Journal Consumer = NOT YET PROVEN ALIGNED**

## FINANCIAL WRITERS DISCOVERED
- save-sales-invoice
- receive-purchase
- complete-return
- save-receipt-voucher
- save-payment-voucher
- save-daily-settlement
- update-driver-ledger
- save-expense / opening-balance / related domain functions recorded in the rebaseline

## OPEN
- Universal journal posting authority.
- Full financial writer matrix.
- Ledger authority/reconciliation.
- Treasury↔COA mapping.
- Production financial security rollout.
- Consumer retry/operation identity proof.
- Runtime/concurrency proof.

## NO FALSE CLOSURE
Accounting is not “UNKNOWN”; it is **PARTIALLY VERIFIED / CENTRALIZATION OPEN**.