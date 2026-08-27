# 2026-08-27 — Accountant PWA Financial Functions Forensic Review

## Evidence baseline

Production was re-read directly on 2026-08-27.

Verified current facts:
- chart_of_accounts: 17 rows
- treasury: 1 active row, CASH-01, balance 10,000.00
- stock_vouchers: 0
- inventory_log: 3
- erp_operation_registry: 0
- post_cash_receipt_atomic: active canonical core
- post_cash_payment_atomic: active canonical core
- save-receipt-voucher: v6 ACTIVE, JWT required
- save-payment-voucher: v4 ACTIVE, JWT required

Current Production financial core contract:
- company context comes from public.users.auth_id -> company_id
- cash account is resolved by company + account_code 121 + active
- treasury is resolved by company + active; current production has exactly one
- offset account must be selected explicitly by UUID
- operation_id is mandatory and is the idempotency identity
- Edge adapters call canonical cash cores; PWA must not write financial tables directly

## Rejected elements from previous proposals

1. `user_metadata.company_id` as company authority — rejected.
2. `MAIN` as treasury identity — rejected.
3. account name as account identity — rejected.
4. hard-coded account UUID — rejected.
5. unscoped `treasury` and `chart_of_accounts` queries before company resolution — rejected.
6. automatic default offset account such as 123/51 — rejected.
7. generating a fresh operation_id after a recoverable network failure — undesirable because it can create a second transaction.

## Canonical design decision

Modify only `App.newReceipt()` and `App.newPayment()`.

The functions must:
1. resolve authenticated user;
2. resolve authoritative company from public.users.auth_id;
3. load company-scoped active treasury and cash account;
4. require exactly one active treasury in the current contract;
5. present active company-scoped offset accounts for explicit selection;
6. generate/preserve one operation_id per pending UI transaction;
7. call the current Edge adapter payload shape `{ header, lines }`;
8. never directly mutate treasury/cash_box/journal tables.

## Current conclusion

The previous assistant proposals contained a correct architectural direction but mixed it with unscoped reads, semantic leftovers from the old contract, and weaker retry behavior. The canonical functions should therefore be rebuilt rather than pasted verbatim.
