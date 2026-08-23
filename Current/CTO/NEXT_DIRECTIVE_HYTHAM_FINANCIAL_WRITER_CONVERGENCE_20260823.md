# MASTER CTO NEXT DIRECTIVE — HYTHAM
## Closure Unit: WRITE-SIDE FINANCIAL CONVERGENCE + RUNTIME PROOF

Production: SMART ERP (`fiilmooggumokxanwiyx`)
Repository: `rawaie-erp-New`

### 0. Scope boundary

You own the transactional/write side only.

Do NOT modify company membership.
Do NOT decide COA ownership.
Do NOT restore Treasury.
Do NOT create financial master data.
Do NOT modify `accountant.html`.
Do NOT redesign `finance-manager.html`.
Do NOT modify `pos.html` unless a new Production-proven Consumer defect is demonstrated.

### 1. Current Production truth

Re-baseline directly from Production before any change.

Current live Cores include:

- `post_stock_movement`
- `post_journal_entry`
- `post_cash_receipt_atomic`
- `post_cash_payment_atomic`
- `post_customer_ledger_entry`

Current live tenant topology is one company, but the financial master data currently contains:

- `chart_of_accounts = 0`
- `treasury = 0`
- `cash_box = 0`

Therefore do not perform a permanent financial transaction test that depends on fabricated master data.

### 2. Current direct-write evidence

Production PostgreSQL currently proves these residual writers:

1. `receive_purchase_atomic`
   - direct `journal_entries`
   - direct `journal_lines`
   - direct `supplier_ledger`

2. `complete_return_atomic`
   - direct `journal_entries`
   - direct `journal_lines`
   - direct `customer_ledger`

3. `save_sales_invoice_atomic`
   - direct `driver_ledger` for Van Credit

Legacy Edge consumers also remain direct writers, including `save-receipt-voucher`, `save-payment-voucher`, and `save-daily-settlement`.

### 3. Phase order

Do not bulk-refactor all writers.

Execute one Closure Unit at a time:

FOUND
→ HISTORICAL CONTRACT
→ PRODUCTION TRACE
→ CONSUMER TRACE
→ CORE CONTRACT
→ SURGICAL CHANGE
→ TEST
→ DEPLOY
→ RUNTIME VERIFY
→ CLOSE

Then move to the next writer.

### 4. First task — Driver Ledger contract

Before creating any Core:

- inspect the live `driver_ledger` schema;
- prove whether driver ownership is per company or global;
- inspect all consumers and readers;
- inspect historical reports/migrations for the intended semantics;
- identify whether a `company_id` is required;
- identify the exact balance semantics and debit/credit direction;
- identify operation identity semantics.

Do not create `post_driver_ledger_entry` until the contract is proven.

### 5. Second task — Git/Production lineage

PR #23 is Draft/Open/Unmerged.

Prove exactly:

- Production Edge version;
- Current Git version;
- branch SHA;
- deployed function hash/version;
- whether Current source is behind Production;
- what must be synchronized into `main` without changing behavior.

A Production PASS is not a Git PASS.

### 6. Third task — authenticated HTTP E2E

Once the master-data identity is resolved by Khalid and real COA/Treasury exists:

prove:

PWA
→ Edge
→ RPC
→ Core
→ DB
→ audit

using authenticated requests.

No direct SQL-only closure for this step.

### 7. Fourth task — independent-session concurrency

Use two genuinely independent authenticated sessions.

Prove:

- one logical operation cannot post twice;
- row locks serialize conflicting effects;
- duplicate operation identity is safe;
- no lost update exists;
- no double ledger posting exists;
- no double treasury mutation exists.

### 8. Fifth task — financial writer convergence

After the company/master-data contract is proven, migrate one writer at a time.

Suggested order:

A. `save-sales-invoice` residual Driver Ledger write
B. `save-receipt-voucher`
C. `save-payment-voucher`
D. `receive_purchase_atomic`
E. `complete_return_atomic`
F. `save-daily-settlement`
G. `update-driver-ledger`

For each writer create a responsibility matrix:

Historical | Production | Current | Target

Stock mutation
Inventory log
Accounting
Ledger
Treasury
Order quantities
Runsheet state
Backorder
Idempotency
Company isolation
Audit

No responsibility may disappear.

### 9. Account identity rules

Never use:

`MAIN`
`CASH-01`
`41`
`51`

as a substitute for a UUID account identity unless the current schema/contract explicitly proves that mapping.

Every journal line must resolve to the canonical `chart_of_accounts.id` for the correct company.

### 10. Production safety

No synthetic financial data.
No hidden fallback Treasury.
No hardcoded company IDs in transactional authorization paths.
No partial migration that leaves the old writer live and the new writer live in parallel.

Experiments must be reversible and auditable.

### 11. Deliverable

For every closure unit produce:

- Producer
- Consumer
- Historical contract
- Production definition
- Current Git source
- Core contract
- Surgical diff
- Tests
- Runtime evidence
- Rollback evidence
- Residual writers
- Final status

Do not claim `FINANCIAL WRITE SIDE = CLOSED` while any direct financial writer remains outside its authoritative Core.
