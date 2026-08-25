# RAWAEA ERP — TREASURY ↔ COA CONTRACT

Date: 2026-08-25
Owner: Khalid

## Proven in Production

1. The surviving company is `00000000-0000-0000-0000-000000000001`.
2. The active Treasury row is `CASH-01 / الخزينة الرئيسية`.
3. The active GL cash account created for current transaction compatibility is `account_code='121'` / `النقدية (الخزينة الرئيسية)`.
4. `save_sales_invoice_atomic` explicitly selects the GL cash account by `account_code='121'`.
5. `post_cash_receipt_atomic` and `post_cash_payment_atomic` accept **two separate identities**:
   - `p_treasury_id`
   - `p_cash_account_id`
6. The current `treasury` table has no direct FK to `chart_of_accounts`.

## Contract interpretation

The proven operational contract is therefore:

`Treasury identity` + `GL cash-account identity`

passed independently to the Cash Core.

There is **no proven database relation** requiring `CASH-01` to own or equal account `121`.

## Explicit non-claims

- No `CASH-01 → 121` FK was created.
- No Treasury row was changed.
- No Treasury balance was changed.
- No historical mapping was claimed.
- No UI patch was added to compensate for the missing relationship.

## Current status

`TREASURY ↔ COA OPERATIONAL CONTRACT = PROVEN FOR CURRENT CASH/POS CORE`

`TREASURY ↔ COA DATABASE FK = NOT REQUIRED / NOT PRESENT`

Future explicit configuration may be introduced only if a new business requirement proves it necessary.
