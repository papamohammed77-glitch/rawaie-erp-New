# RAWAEA ERP — Hytham Accounting Core Execution
## 2026-08-22

### Scope
Execution of Prompt 51 Track B only. Production target: SMART ERP (`fiilmooggumokxanwiyx`). No Inventory redesign. No PWA file modification performed.

### Production truth established
- PostgreSQL current time during execution: 2026-08-22 18:25:24 UTC.
- `journal_entries`: 2.
- `journal_lines`: 0.
- `treasury`: 1 row.
- `driver_ledger`: 0 rows.
- `customer_ledger`: 0 rows.
- `supplier_ledger`: 0 rows.
- `daily_settlements`: 0 rows.
- `post_journal_entry` existed in Production as SECURITY DEFINER with `search_path = public, pg_temp` and enforced balanced posting, company-scoped UUID account validation, and `erp_operation_registry` idempotency.

### Forensic findings
1. Production `journal_entries` does not contain `movement_id`, although the deployed `post_journal_entry` attempted to insert that column. This was a real schema/function drift and was reproduced by a transactional test.
2. Production `treasury.account_code = CASH-01` does not map by code to `chart_of_accounts.account_code` for the current treasury row. The current treasury row belongs to company `da4ef704-88ac-4120-aa0e-65b92b2aa2bc` and has no matching COA code. The active COA contains a cash account `121` with UUID `c0da972b-6dbc-4f7c-96b8-acd33c86c736`.
3. Therefore the new atomic cash cores intentionally require explicit `treasury_id`, `cash_account_id`, and `offset_account_id`. They do not infer identities from `CASH-01`, `41`, `5`, or other strings.
4. Driver ledger was not embedded in the new cash core because its accounting/operational ownership contract is not yet proven.

### Production changes executed
- `post_journal_entry` corrected to match current `journal_entries` schema; `p_movement_id` remains a compatibility parameter but is not written because the target column does not exist.
- Created `post_cash_receipt_atomic(...)`.
- Created `post_cash_payment_atomic(...)`.
- Both are `SECURITY DEFINER` with restricted `search_path` and `service_role` execution only.
- Both use `erp_operation_registry` for operation identity/idempotency.
- Both lock and validate the treasury and both COA UUIDs against the same company.
- Both create `cash_box` and post the journal through `post_journal_entry` in the same transaction.
- Payment prevents negative treasury balance.

### Test results
#### Receipt
A real transactional execution was run with production treasury/account UUIDs and operation id `11111111-1111-1111-1111-111111111111`, then rolled back.
Post-rollback state remained:
- journal_entries = 2
- journal_lines = 0
- treasury balance = 10000.00

#### Payment
A real transactional execution was run with production treasury/account UUIDs and operation id `22222222-2222-2222-2222-222222222222`, then rolled back.
Post-rollback state remained:
- journal_entries = 2
- journal_lines = 0
- treasury balance = 10000.00

### Writer convergence status
Legacy Edge Functions remain unchanged:
- `save-receipt-voucher` v5
- `save-payment-voucher` v3
- `save-daily-settlement` v3
- `update-driver-ledger` v1

No legacy writer was redirected in this unit because Treasury↔COA mapping and Consumer contract are still open. No PWA was modified.

### Closure classification
- Canonical journal boundary: ACTIVE / schema drift corrected.
- Atomic receipt core: IMPLEMENTED + transactional proof.
- Atomic payment core: IMPLEMENTED + transactional proof.
- Receipt/Payment Production consumer migration: OPEN.
- Driver ledger core: OPEN.
- Daily settlement core: OPEN.
- Writer convergence: OPEN.
- Financial concurrency: OPEN.
- Global Zero-Debt: OPEN.

### Evidence discipline
No production data was committed by the test cases. No PWA published file was modified. No account mapping was invented.
