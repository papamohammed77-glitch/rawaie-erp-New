# RAWAEA ERP — Accountant Forensic Review & Closure

**Event ID:** 20260827-ACCOUNTANT-FINANCIAL-WORKBENCH-01
**Date:** 2026-08-27
**Scope:** Current/PWA/accountant.html + supporting financial-read security + current Production financial Core verification

## Source Authority

1. Current Production Supabase
2. Current `main` Git
3. Current CTO / evidence records
4. Historical reports and assistant reports only as historical evidence

The governing modification principle remains: understand historical/current contract, trace current behavior and dependencies, identify the actual gap, then make a minimal safe change and verify against Production.

## Current Production facts verified directly

- 3 company rows currently exist.
- The surviving RAWAEA operating company used by the current accountant workflow is `00000000-0000-0000-0000-000000000001`.
- Current Treasury: one active treasury, `CASH-01`, current balance 10,000.
- Current COA for that company: 17 active accounts.
- COA `121` is currently `النقدية (الخزينة الرئيسية)` and is the verified cash-account mapping used by the current cash Core.
- `post_journal_entry`, `post_cash_receipt_atomic`, and `post_cash_payment_atomic` exist as SECURITY DEFINER functions.
- Cash receipt/payment Cores validate company, treasury, account UUIDs, amount, and operation UUID; they route journal creation through `post_journal_entry` and use `erp_operation_registry` for idempotency.
- Reporting functions currently include trial balance, profit & loss, balance sheet, cash flow, and cost-center P&L.

## Historical assistant work — accepted vs rejected

### Accepted
- Moving receipt/payment posting behind canonical cash Cores.
- Using `public.users.auth_id` as the company-context bridge.
- Passing Treasury/COA UUIDs rather than names or `MAIN`.
- Persisting operation identity for retry safety.
- Keeping financial DML out of the PWA.
- Retaining historical reports as historical evidence rather than Current Truth.

### Rejected / corrected
- `MAIN`/cash-box symbolic identity as an accounting account identity.
- Account names as account IDs.
- Unscoped company lookups.
- Hard-coded historical company IDs in execution paths.
- Treating the existence of a Core as proof that all consumers are converged.
- Treating historical Production snapshots as current.

## Accountant.html forensic result

The previous file had already incorporated the core UUID contract for receipts/payments, but remained too narrow for a production accountant workstation. It contained only KPI, receipt, payment, and journal placeholder views, and its dashboard relied on operational tables without enough financial-control context.

The current file was replaced with a Financial Workbench that provides:

- secure company-scoped session/context initialization;
- treasury and cash-account context loaded before financial operations;
- receipt/payment creation through existing Edge adapters and canonical cash Cores;
- persisted operation identity for retry safety;
- receipt and payment history with date/reference filtering UI;
- posted journal browsing and journal-line drill-down;
- Reporting Core access for Trial Balance, P&L, Balance Sheet and Cost Center P&L;
- cash movement reporting;
- CSV export;
- customer/supplier balance views with an explicit warning that operational balances are not a substitute for G/L reconciliation;
- a financial control panel showing operation-registry health and posted-journal counts.

The change was committed to `main` as commit:

`76f9a926039ec9918cac17f3a9f7f2f3c96a61fe`

## Security repair executed in Production

The following insecure public `ALL` policies were found directly in Production and removed:

- `cash_box` — `Allow all for all`
- `treasury` — `Allow all for all`
- `journal_entries` — `Allow all for all`
- `journal_lines` — `Allow all for all`

They were replaced with authenticated company-scoped SELECT policies. `journal_lines` is scoped through its parent journal entry's company. `erp_operation_registry` now has a company-scoped authenticated SELECT policy.

No authenticated INSERT/UPDATE/DELETE policy was introduced for these financial posting tables; financial writes remain owned by the server-side Core/service path.

Migration name:

`harden_financial_read_policies_20260827`

## Production runtime verification

A transactional self-test was executed directly against the Production financial Cores:

### Receipt
- First post: success, balanced 2-line journal.
- Same operation UUID retried: returned `duplicate=true` and the same journal/cash-box identifiers.
- Transaction rolled back.

### Payment
- First post: success, balanced 2-line journal.
- Same operation UUID retried: returned `duplicate=true` and the same journal/cash-box identifiers.
- Transaction rolled back.

Final residue check:

- self-test cash rows = 0
- self-test journal rows = 0
- self-test operation-registry rows = 0

Therefore the verification produced no Production test residue.

## Competitor-derived design decisions

The current accountant design adopts principles visible in mature ERP products without copying their implementation:

- Financial statements beyond a KPI page.
- General-ledger drill-down.
- Trial-balance controls and reconciliation orientation.
- Period filtering.
- Auditability and traceability.
- Separation between transactional posting engines and reporting consumers.
- Explicit distinction between operational subledger balances and G/L truth.
- Exportable reporting.

These principles are consistent with Odoo's financial reporting model and Microsoft Business Central's finance/audit/reporting model.

## Closure status

### Accountant PWA
**SOURCE IMPLEMENTED:** YES
**GIT COMMITTED:** YES
**PRODUCTION PWA HOST DEPLOYMENT VERIFIED:** NOT YET

### Financial Core
**RECEIPT CORE VERIFIED:** YES
**PAYMENT CORE VERIFIED:** YES
**IDEMPOTENCY VERIFIED:** YES
**NO TEST RESIDUE:** YES

### Financial read security
**PUBLIC ALL POLICIES REMOVED:** YES
**COMPANY-SCOPED READ POLICIES VERIFIED:** YES

## Important remaining debt

This event does NOT certify the entire ERP financial or inventory system as globally closed. Independent open work remains around:

- historical 87-COA recovery decisions;
- global financial writer convergence;
- purchase/POS/return consumer convergence;
- runtime authenticated HTTP/browser E2E;
- true concurrency testing;
- Production/Git byte-level lineage for every deployed Edge/Core;
- current return and delivery Edge drift requiring separate Writer Closure Units;
- Leaked Password Protection, which remains an Auth security advisor warning.

## Final statement

The current `accountant.html` is no longer a legacy four-tab placeholder. It is a substantially upgraded production-oriented Financial Workbench over the canonical financial cores. It is **not** certified as a globally complete accountant/financial suite until the remaining backend consumer, runtime, reconciliation, and security gates are independently closed.
