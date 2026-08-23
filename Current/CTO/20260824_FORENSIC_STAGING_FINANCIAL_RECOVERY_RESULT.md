# RAWAEA ERP — 2026-08-24 FORENSIC STAGING FINANCIAL RECOVERY RESULT

## Authority

Production PostgreSQL > Current Git > Current evidence > Historical sources > reports.

## Target

Supabase project: `rawaea-staging`
Current staging company: `b4cc737e-6431-474e-af9e-92a427a44911` / TASK028 STAGING

## Proven result

### Treasury

The historical treasury was recovered from a verified row-level source and replayed under the current staging company.

- UUID: `0a9d9357-b5f3-4dfa-886f-7c73de4f274e`
- account_code: `CASH-01`
- account_name: `الخزينة الرئيسية`
- type: `Cash`
- opening_balance: `10000`
- current_balance: `10000`
- active: true
- historical created_at: `2026-05-16T00:08:06.123874+00`
- historical updated_at: `2026-05-16T00:08:06.123874+00`
- owner after replay: current staging company

A dedicated audit record was written because staging has no treasury audit trigger.
Audit record id: `646af97c-e3c4-48f4-b023-0b01c27b4d12`.

### Chart of Accounts

`chart_of_accounts` remains at 0 rows.

No exact row-level 87-account source was discovered in the directly searched current repositories.
The historical evidence proves the COUNT `87`, but not the 87 account rows themselves.
The published main.html/application seed is only a base seed and is not authoritative proof of the historical 87.

Therefore the 87-account replay is intentionally NOT executed.

## Schema drift discovered

The staging treasury table does not currently expose the uniqueness constraint `(company_id, account_code)` that some historical code/documentation assumed. An `ON CONFLICT` attempt was rejected by PostgreSQL because no matching unique/exclusion constraint exists.

The row was then safely restored using update-then-insert logic without altering the schema contract.

## Security findings in staging

Current security advisor reports that 65 public tables have RLS disabled.
It also reports SECURITY DEFINER financial functions callable by anon/authenticated, including:

- post_inventory_adjustment_atomic
- receive_purchase_atomic
- save_sales_invoice_atomic
- post_cash_receipt_atomic
- post_cash_payment_atomic
- post_customer_ledger_entry

Staging also has leaked-password protection disabled.

These are separate hardening gates and were NOT blindly fixed here because RLS without policy design would block legitimate access.

## Final forensic decision

Treasury Recovery = CLOSED for staging replay.
87 COA Recovery = OPEN — exact source missing.
Financial Writer Convergence = OPEN.
Staging Security Hardening = OPEN.

No fabricated financial master data was introduced.
