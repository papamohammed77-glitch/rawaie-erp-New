# RAWAEA ERP — Hytham Prompt 53 POS Financial Closure
## 2026-08-23

### Scope
Prompt 53 — Hytham execution track only.

Production target: SMART ERP (`fiilmooggumokxanwiyx`).
Published PWA scope: `Current/PWA/pos.html` was reviewed but was **not modified** because its current consumer contract already carries `operation_id` through `save-sales-invoice` v15 to `save_sales_invoice_atomic`.

Out of scope: `accountant.html`, `finance-manager.html`, `vouchers.html`, Inventory Core redesign.

### Source hierarchy applied
1. Current SMART ERP Production runtime and definitions.
2. Current Git under `Current/`.
3. Prompt 53 and historical reports as historical/contract evidence only.

### Prompt 53 conclusions confirmed from Production

`save-sales-invoice` Production v15 authenticates the caller, derives/accepts `operation_id`, and calls `save_sales_invoice_atomic`.

Before this closure, `save_sales_invoice_atomic`:
- centralized physical stock through `post_stock_movement`;
- but directly inserted `journal_entries` and `journal_lines`;
- directly inserted `customer_ledger`;
- directly inserted `driver_ledger` for Van Credit;
- did not use the Atomic Cash Core for cash POS.

### Production changes executed

#### 1. Customer Ledger Core
Created `public.post_customer_ledger_entry(...)` as `SECURITY DEFINER` with:
- company validation through the customer row;
- operation identity via `erp_operation_registry`;
- customer row locking for serialized balance calculation;
- non-negative / one-sided debit-credit validation;
- authoritative balance derivation;
- audit record;
- duplicate protection.

#### 2. POS writer convergence
Replaced the Production definition of `save_sales_invoice_atomic` so that:
- physical stock still goes only through `post_stock_movement`;
- journal posting goes through `post_journal_entry`;
- cash POS goes through `post_cash_receipt_atomic`;
- credit POS journal uses AR + Revenue, and COGS/Inventory only when COGS is positive;
- customer credit balance goes through `post_customer_ledger_entry`;
- no direct writes remain to `journal_entries`, `journal_lines`, or `customer_ledger` inside the POS writer;
- parent `operation_id` protects the invoice as a whole;
- child COGS/customer operations are generated inside the same transaction;
- cash Treasury mapping is deliberately strict: exactly one active treasury must exist for the company. No implicit `CASH-01 -> COA` mapping was invented.

#### 3. Current Edge source synchronized
`Current/Edge_Functions/save-sales-invoice` was updated on the review branch to match verified Production v15, including operation identity and Idempotency-Key handling.

### Surgical PWA status

`Current/PWA/pos.html`: **NOT MODIFIED**.

Reason: the current Consumer already provides the required transaction identity path and does not need a blind UI rewrite for this closure unit.

### Tests executed in SMART ERP Production

#### Cash POS transactional test
A real `save_sales_invoice_atomic` cash sale was executed inside a transaction with a real company, branch, item, treasury and production accounts.
Observed inside the transaction:
- stock decreased by the sale quantity;
- cash receipt path increased Treasury by the sale amount;
- accounting write was created through the central journal core.

The transaction was then rolled back.
Post-rollback verification:
- orders = 0 for the test operation;
- operation registry = 0 for the test operation;
- journal entries = 0 for the test order;
- inventory logs = 0 for the test operation;
- Treasury balance returned to `10000.00`.

#### Duplicate / retry test
Same `operation_id` was submitted twice inside one transaction.
Observed:
- only one order existed;
- only one journal entry was created for the tested cash sale;
- the second call followed the duplicate path;
- the transaction was rolled back afterward.

#### Credit POS transactional test
A real credit POS sale was executed using a real production customer/account set.
The initial version exposed a zero-COGS line defect; the central accounting core correctly rejected it.
The function was corrected so zero-cost products generate only the AR/Revenue lines, while positive COGS generates the additional COGS/Inventory pair.
The corrected credit sale then passed transactionally and was rolled back.
Post-rollback verification:
- no order remained;
- no operation registry records remained;
- no test customer-ledger record remained;
- no POS cash-box record remained.

### Direct writer verification
Current Production `save_sales_invoice_atomic` now contains:
- no direct `journal_entries` insert;
- no direct `journal_lines` insert;
- no direct `customer_ledger` insert;
- a central `post_journal_entry` call;
- a central `post_cash_receipt_atomic` call for cash sales;
- a central `post_customer_ledger_entry` call for credit customers.

### Remaining OPEN items

1. **Driver Ledger Convergence — OPEN**
   Van Credit still has a direct `driver_ledger` insert. The Production `driver_ledger` schema has no `company_id`, and its ownership/multi-tenant contract has not been proven sufficiently to invent a new core or rewrite this writer safely.

2. **Treasury multi-register mapping — OPEN**
   Current POS has no published treasury selector/explicit treasury UUID contract. Production currently has one active treasury for the exercised company, so the closure uses a strict `exactly one active treasury` requirement rather than guessing a `MAIN` mapping. Multiple-treasury operation needs a proven business contract before expansion.

3. **Concurrency proof — OPEN**
   The transactional and retry tests passed, but a genuine two-session concurrent HTTP/runtime proof has not yet been completed in this unit. Therefore POS Financial Closure cannot be labeled CLOSED.

4. **Production HTTP end-to-end proof — OPEN**
   The core transaction was verified directly in Production SQL transaction scope. Full authenticated PWA -> Edge v15 -> RPC runtime proof is still required before declaring final runtime closure.

### Final Closure Status

**POS FINANCIAL CLOSURE = OPEN / PARTIAL CLOSURE**

The major distributed Accounting writer path has been converged into central cores without modifying `Current/PWA/pos.html`.

The unit is intentionally not marked CLOSED while Driver Ledger, multi-treasury contract, concurrency, and full authenticated HTTP runtime proof remain open.

### Review Branch

`heytham/prompt53-pos-financial-closure`

### Main branch impact

No merge to `main` was performed from this execution branch.
