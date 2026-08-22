# RAWAEA ERP — Khalid Financial PWA Consumer Review
## Production-first review following Prompt 51

Date: 2026-08-22

## Scope
Reviewed the current `Current/PWA` published applications relevant to the Accounting/Ledger closure scope, with direct comparison to current Production Edge contracts.

Primary reviewed consumers:
- `Current/PWA/accountant.html`
- `Current/PWA/finance-manager.html`
- `Current/PWA/driver.html`

## Proven consumer mapping

### accountant.html
This is the direct financial writer consumer reviewed.

Tabs:
- dashboard
- receipts
- payments
- journal

Direct write capabilities:
- `newReceipt()` → `save-receipt-voucher`
- `newPayment()` → `save-payment-voucher`

The current PWA request shape is:
- `date`
- `cashBoxId: 'MAIN'`
- `mainAccountName: <reference text>`
- `notes`
- `lines: [{ accountName: <reference text>, description, amount }]`

Production `save-receipt-voucher` currently expects `{ header, lines }`, then reads `header.cashBoxId`, `header.mainAccountName`, `header.mainAccountId`, `header.collectedByDriverEmail`.

Therefore the current consumer and deployed Edge contract are not shape-aligned.

A second independent mismatch is that the PWA uses `cashBoxId: 'MAIN'`, while the current Production treasury master is identified by `account_code = CASH-01` and journal line `account_id` is a UUID FK to `chart_of_accounts.id`.

The current UI also uses the entered reference text as `mainAccountName` and `accountName`, which is not a proven accounting account identity.

### finance-manager.html
Read/report consumer only in the reviewed source.

It reads:
- orders
- purchase_orders
- treasury

It does not directly invoke `save-receipt-voucher`, `save-payment-voucher`, or financial write RPCs in the reviewed code.

No surgical change is justified for this file under the current Closure Unit.

### driver.html
The current source contains broader operational behavior and includes a fallback user provisioning path with a hard-coded company UUID. This is a separate tenant/security finding and was not changed because it is not the proven target of the current Accounting Writer Closure Unit.

## Surgical-change decision

No Current/PWA file was modified in this closure step.

Reason: fixing `accountant.html` by merely reshaping the payload or replacing `MAIN` with `CASH-01` would leave unresolved accounting identity semantics (`chart_of_accounts.id` UUID, debit/credit account ownership, Treasury→COA mapping, receipt/payment semantics) and would therefore be a partial/unsafe fix.

The correct next dependency is the Treasury ↔ COA Contract and the canonical Receipt/Payment Core contract. After that contract is proven, `accountant.html` can receive a surgical replacement of only `newReceipt()` and `newPayment()` using the confirmed Production contract.

## Status

Consumer Discovery: VERIFIED for the reviewed files.

Consumer Contract Drift: PROVEN in `accountant.html`.

PWA Surgical Fix: NOT APPLIED — contract dependency remains open.

Production financial writer convergence: OPEN.

No Production data or PWA deployment was changed in this review step.
