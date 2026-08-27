# RAWAEA ERP — Accountant Control Center Forensic Execution

**Date:** 2026-08-28
**Authority:** Current Production Supabase + Current Git main
**Method:** forensic revalidation; historical reports treated as evidence only

## 1. Governing rule

No historical report, assistant statement, memory artifact, or prior percentage was accepted as Production truth. Current Production and current Git were re-read and reconciled before each material decision.

The governing modification sequence remains:

UNDERSTAND → HISTORICAL CONTRACT → CURRENT BEHAVIOR → DATA/AUTH FLOW → TARGET GAP → SURGICAL CHANGE → VERIFY

## 2. Current Production baseline

The current Production database snapshot used for this execution reports:

- PostgreSQL 17.6
- Companies: 1
- Users: 24
- Branches: 2
- Items: 17
- Stock rows: 20
- Inventory log rows: 3
- Stock vouchers: 0
- Treasury rows: 1
- Chart of Accounts: 17
- Journal entries: 2
- Journal lines: 0
- Customer ledger rows: 0
- Supplier ledger rows: 0
- Driver ledger rows: 0
- Orders: 0
- Purchase orders: 0
- Runsheets: 0
- Audit log rows: 1856
- erp_operation_registry rows: 0 at the baseline query

## 3. Historical assistant assessment

### Khalid

The historical 87-account recovery stop was methodologically correct. Source exhaustion was correctly distinguished from successful recovery of 87 authoritative rows. The later creation of 16/17 current COA accounts was treated as New Financial Master Data, not as historical reconstruction.

His financial convergence work was valuable, but the reports were not treated as proof of current closure because subsequent Production changes existed.

### Hytham

The core architectural finding remains correct: `post_stock_movement` is the Physical Stock writer contract; `reserve_stock` and `release_stock_reservation` are reservation engines, not physical movement engines. Current Production confirms the financial writer Cores also exist.

However, prior claims of global closure were broader than the evidence because browser E2E, runtime/concurrency and persistent period-close contract were not proven.

## 4. Historical bad journal data

Two historical `VoidInvoice` journal headers existed:

- `JE-VOID-1784927448473-476` / `VOID-ORD-1015`
- `JE-VOID-1784927457858-428` / `VOID-ORD-1016`

Both were `Posted` with zero current journal lines. Audit history proves that two temporary lines were created and deleted within seconds, preserving the historical audit trail.

### Executed fix

The headers were **not deleted** and historical audit records were not rewritten.

They were moved from `Posted` to `Cancelled` because they represent invalid zero-line void headers and must not remain posted.

Migration:

`20260828_quarantine_zero_line_void_invoice_headers`

Production verification:

`Posted zero-line journal headers = 0`

## 5. Reconciliation defect discovered and fixed

The prior `accountant_reconciliation_summary` incorrectly reported:

`CASH_VS_GL = OK, difference = 10000`

because it compared Treasury current balance directly with GL movement while Treasury opening balance was 10000.

### Executed fix

The reconciliation now compares:

`Treasury current - Treasury opening`

against:

`posted GL movement on account 121`

and explicitly treats zero-line posted journals as journal integrity exceptions.

Migration:

`20260828_fix_accountant_reconciliation_cash_baseline_and_gl_scope`

Production authenticated verification now returns:

- CASH_VS_GL = OK / 0.00
- AR_VS_GL = OK / 0
- AP_VS_GL = OK / 0
- JOURNAL_BALANCE = OK / 0

The G/L account activity read model was also hardened with an explicit current-company account ownership guard.

## 6. Accountant PWA regression correction

The current PWA was not accepted as equivalent to the historical richer accountant consumer merely because it contained the same tab labels.

A real regression was found:

`cashVoucher()` created a new Operation ID for every attempt and did not persist failed operations.

That undermined the idempotency contract already implemented in the financial Cores.

### Executed PWA repair

`Current/PWA/accountant.html` was surgically restored as a full Accountant Control Center consumer without introducing financial writers into the browser.

The PWA now includes:

- authenticated Company context from `users.auth_id`
- OWNER / wildcard / finance permission semantics
- multi-treasury context
- current COA account resolution
- Dashboard
- Receipts
- Payments
- Journals
- Trial Balance
- P&L
- Balance Sheet
- Cash Flow
- P&L by Cost Center
- Operational Runsheet and Order views
- Customer and Supplier Aging
- Inventory control read model
- G/L and account activity
- Reconciliation
- Period Readiness
- Exception Center
- Audit Feed
- date filtering
- CSV export

Cash operations now persist the complete request in `sessionStorage` under a company/type key and retry with the **same Operation ID**, preserving the canonical idempotency contract.

No financial DML was added to the PWA.

## 7. Financial report execution surface

Production inspection found that the following report functions were executable by `anon` even though the Accountant Control Center is authenticated:

- `get_trial_balance`
- `get_profit_loss`
- `get_balance_sheet`
- `get_cash_flow`
- `get_pnl_by_cost_center`

### Executed fix

Anonymous execution was revoked. Execution remains available to `authenticated` and `service_role`.

Migration:

`20260828_harden_accountant_report_execute_surface`

Current verification shows `anon_exec = false` and `auth_exec = true` for these reports.

## 8. Financial Core surface

Current Production verification shows the following canonical writers are SECURITY DEFINER and service-role executable only:

- `post_journal_entry`
- `post_cash_receipt_atomic`
- `post_cash_payment_atomic`
- `post_customer_ledger_entry`
- `post_supplier_ledger_entry`
- `post_driver_ledger_entry`
- `post_driver_liability_entry`
- `post_daily_settlement_atomic`
- `post_treasury_transfer_atomic`
- `post_inventory_adjustment_atomic`
- `post_manual_stock_voucher_atomic`
- `post_stock_movement`

All direct user execution was not granted for these Financial/Stock Core writers.

`erp_operation_registry` has the unique identity contract:

`(company_id, operation_type, operation_key)`

## 9. Physical Stock zero-debt result

Current Production function scan found no direct Physical Stock writer outside the intended core.

The only functions whose definitions contain `stock_branches` writes are the intended:

- `post_stock_movement`
- `reserve_stock`
- `release_stock_reservation`

The latter two are reservation-only by contract.

The current Physical Stock contract therefore remains:

Physical Movement → `post_stock_movement` → `stock_branches` + `inventory_log`

## 10. Period close

Production has no persisted `period`, `fiscal period`, `close`, or `lock` table or write RPC.

The only verified capability is:

`accountant_period_readiness`

This is a readiness model, not a persistent accounting-period close contract.

No new period-close contract was invented during this execution because doing so would create a new architectural contract without a historical source or explicit design decision.

Current readiness output is:

- UNBALANCED_JOURNALS = PASS / 0
- FAILED_OPERATIONS = PASS / 0
- PENDING_DRIVER_LIABILITIES = PASS / 0
- STOCK_INVARIANTS = PASS / 0
- PERSISTENT_PERIOD_CLOSE = REVIEW / contract absent

## 11. Current Accountant Control Center status

### Closed with direct evidence

- Historical zero-line `VoidInvoice` headers quarantined without audit destruction
- Zero-line Posted journal exception removed from current state
- Treasury-vs-GL reconciliation logic corrected
- AR/AP reconciliation read models verified at zero difference in current company context
- Journal balance integrity verified
- Accountant read-model access is authenticated-only
- Accountant PWA consumer restored and aligned to canonical financial cores
- PWA receipt/payment idempotency persistence restored
- G/L account activity company guard hardened
- Financial core anonymous execution surface closed
- Physical Stock direct-writer scan = no unauthorized Physical Movement writer found

### Not honestly certifiable as 100% closed yet

1. **Browser Runtime / HTTP E2E** — a real authenticated user session was not available for destructive-free browser execution, so no claim of browser runtime certification is made.
2. **Persistent Period Close Contract** — no existing Production contract exists; creating one is a new architecture decision, not a forensic repair.
3. **Global Consumer/Edge closure** — some Edge wrappers have historically used unsafe `app_settings LIMIT 1` company resolution and require continued closure where they remain active. These should not be falsely marked complete without per-function Production verification.
4. **Full financial concurrency certification** — SQL Core idempotency is present, but two-user/browser concurrency has not been honestly certified from an authenticated UI session.

## 12. Anti-regression rule

The following must remain prohibited:

- account name as financial identity
- user_metadata as Company source of truth
- hard-coded financial UUIDs
- guessed default account codes for new business behavior
- direct browser financial DML
- direct Physical Stock mutation outside the stock core
- treating readiness as period close
- treating staging/SQL-only PASS as browser runtime PASS
- deleting historical audit evidence to make reports look clean

## 13. Canonical Git migrations added by this execution

- `supabase/migrations/20260828_quarantine_zero_line_void_invoice_headers.sql`
- `supabase/migrations/20260828_fix_accountant_reconciliation_cash_baseline_and_gl_scope.sql`
- `supabase/migrations/20260828_accountant_forensic_cleanup.sql`
- `supabase/migrations/20260828_harden_accountant_report_execute_surface.sql`

## 14. Final forensic verdict

The previous Accountant work was **not worthless and was not wholly wrong**. The principal architecture was largely correct, but several closure claims exceeded the evidence.

This execution corrected proven defects and restored the Accountant PWA to a substantial production-ready consumer of the canonical financial Cores without introducing new distributed writers.

However, the honest final certification is:

`ACCOUNTANT CONTROL CENTER CORE INTEGRITY = CLOSED`

`ACCOUNTANT CONTROL CENTER PRODUCTION CERTIFICATION = NOT 100% CERTIFIED`

because Browser E2E, two-session concurrency and a persistent period-close contract remain unproven/undefined.

No percentage above the evidence-backed boundary is authorized.
