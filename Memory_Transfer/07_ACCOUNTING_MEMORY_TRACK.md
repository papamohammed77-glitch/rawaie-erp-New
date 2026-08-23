# ACCOUNTING MEMORY TRACK

## Current Production evidence
Snapshot 2026-08-23: chart_of_accounts=87, journal_entries=2, journal_lines=0, customer_ledger=0, supplier_ledger=0, driver_ledger=0, treasury=1, daily_settlements=0.

## Architectural contract
Accounting consumes business/inventory events; it does not invent inventory truth. Ledger is derived from accounting, not a substitute for upstream correctness. fileciteturn205file0

## Readiness
The 2026-08-21 Autonomous CTO readiness registry classifies Accounting, Ledgers, and Treasury/Settlement as OPEN because posting contracts, writer ownership, event mapping, reconciliation, and balance semantics remain unproven ERP-wide. fileciteturn227file0

## Historical lesson
Older Loading implementations created COGS directly; the current Loading target intentionally separates physical custody movement from accounting recognition. Any future accounting change must reconcile the Owner/business contract and industry-standard accounting boundaries before implementation.

## Next evidence needed
- Discover every journal writer/adapter in current Production.
- Trace business event → journal authority → journal lines → ledger/treasury effects.
- Prove idempotency and audit behavior.
- Preserve original business responsibilities while centralizing posting.
