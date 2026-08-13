# 27 — DISTRIBUTED BUSINESS LOGIC RISK MAP

## Historical mutation map

| Actor/path | Historical mutation | Evidence class | Risk |
|---|---|---|---|
| `complete-picking` | allocation / inventory-related effects | Historical API + DB docs | High |
| `complete-loading` | physical stock + inventory log + journal | Historical API + workflow | Critical |
| `complete-order-delivery` | delivery quantities + revenue/customer ledger | Historical API + workflow | Critical |
| `complete-return` | stock return + liability + accounting/customer effects | Historical API + workflow | Critical |
| `receive-purchase` | inbound stock + receiving + accounting | Historical API + DB docs | Critical |
| `send-stock-voucher` | source stock deduction | Historical API | Critical |
| `receive-stock-voucher` | target stock addition | Historical API | Critical |
| `unload-runsheet` | stock restoration | Historical API + workflow | Critical |
| `save-inventory-count` / adjustments | stock correction | Historical API | Critical |
| receipt/payment/transfer vouchers | cash/treasury + journals | Historical API + security review | High |
| `save-daily-settlement` | driver liability + accounting | Historical API + workflow | High |
| `sync-run-sheet-details` | projection rebuild | Historical DB/API docs | High |

## Core architectural risk
Historically, business side effects were distributed across many Edge Functions and projections. This creates the possibility that two paths can mutate the same domain independently.

The current CTO architecture explicitly seeks centralized core engines, especially for stock movement, journal posting and ledger posting. This is a current target/current architecture rule, not a claim that every historical path has already disappeared from Production.

## Mutation classes

### Stock
- `stock_branches`
- `inventory_log`
- reservation/allocation
- voucher transfers
- run/unload flows

### Accounting
- `journal_entries`
- `journal_lines`
- cash/treasury

### Ledger
- customer ledger
- supplier ledger
- driver ledger/liability

### Projection
- `run_sheet_details`

### Audit
- `audit_log`

## Historical risk patterns
1. Same stock movement represented by multiple consumers.
2. Projection synchronization dependent on manual invocation.
3. Accounting effects embedded in operational functions.
4. Ledger effects embedded in operational functions.
5. UI-specific data access bypassing shared infrastructure.
6. Historical direct voucher mutation without the later central movement contract.

## Current reconciliation boundary
The presence of a historical mutation path does NOT mean the path is currently deployed. Every function requires Original / Current / Candidate / Deployed classification.

## No automatic conclusion
This document records architectural risk memory. It does not authorize refactoring and does not claim a defect exists in current Production unless separately evidenced.
