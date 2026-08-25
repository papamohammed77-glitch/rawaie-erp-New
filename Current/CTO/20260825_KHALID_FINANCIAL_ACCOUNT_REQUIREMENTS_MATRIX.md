# RAWAEA ERP — PHASE 1B FINANCIAL ACCOUNT REQUIREMENTS MATRIX

Date: 2026-08-25
Owner: Khalid
Authority: Production PostgreSQL > Current main > Current CTO evidence > reachable historical sources > reports

## Scope

This matrix defines **NEW MASTER DATA** for the surviving Production company. It is not historical 87-row recovery.

Company:
`00000000-0000-0000-0000-000000000001`

Treasury:
`CASH-01 / الخزينة الرئيسية`

Current Production transaction paths inspected:
- `save_sales_invoice_atomic`
- `receive_purchase_atomic`
- `complete_return_atomic`
- `post_cash_receipt_atomic`
- `post_cash_payment_atomic`
- `post_journal_entry`

## Account matrix

| Code | Account | Type | Normal | Parent | Production evidence | Basis |
|---|---|---|---|---|---|---|
| 1 | الأصول | asset | debit | — | Required hierarchy for current asset accounts | New canonical top-level group |
| 11 | الأصول الثابتة | asset | debit | 1 | Standard ERP structure; no current writer directly selects it | New canonical subgroup; not historical recovery |
| 12 | الأصول المتداولة | asset | debit | 1 | Parent required for 121/123/124 currently used by writers | New canonical subgroup |
| 121 | النقدية (الخزينة الرئيسية) | asset | debit | 12 | `save_sales_invoice_atomic` explicitly selects `account_code='121'`; cash cores require a cash account UUID | Explicit current operational contract; not Treasury FK mapping |
| 123 | العملاء (ذمم مدينة) | asset | debit | 12 | `save_sales_invoice_atomic` explicitly selects `account_code='123'` for credit sales | Explicit current operational contract |
| 124 | المخزون السلعي | asset | debit | 12 | `save_sales_invoice_atomic`, `receive_purchase_atomic`, `complete_return_atomic` explicitly select `124` | Explicit current operational contract |
| 2 | الخصوم | liability | credit | — | Required hierarchy for current liability accounts | New canonical top-level group |
| 21 | الخصوم المتداولة | liability | credit | 2 | Parent required for 211/216 | New canonical subgroup |
| 211 | الموردون (ذمم دائنة) | liability | credit | 21 | `receive_purchase_atomic` explicitly selects `account_code='211'` | Explicit current operational contract |
| 216 | التزامات ضريبية | liability | credit | 21 | No current Production writer posts here | Reserved standard subgroup for future tax-enabled flows; explicitly marked non-current-writer |
| 3 | حقوق الملكية | equity | credit | — | Required coherent single-company financial master | New canonical top-level group |
| 31 | رأس المال | equity | credit | 3 | Required opening/equity representation for coherent company finance | New canonical account; no opening transaction created |
| 4 | الإيرادات | revenue | credit | — | Parent required for 41 | New canonical top-level group |
| 41 | إيرادات المبيعات | revenue | credit | 4 | `save_sales_invoice_atomic` explicitly selects `account_code='41'` | Explicit current operational contract |
| 5 | المصروفات وتكلفة المبيعات | expense | debit | — | Parent required for 51 | New canonical top-level group |
| 51 | تكلفة المبيعات | expense | debit | 5 | `save_sales_invoice_atomic` and `complete_return_atomic` explicitly select `account_code='51'` | Explicit current operational contract |

## Deliberate exclusions

Not inserted because current Production does not provide a direct writer/consumer requirement for them:
- bank accounts
- tax receivable
- tax expense
- sales discounts
- purchase/inventory clearing
- other operating expense subaccounts
- other income
- retained earnings
- fixed-asset leaf accounts

These may be designed in a later financial-master expansion after the corresponding business capabilities are evidenced.

## Historical separation

The previously documented 16 bootstrap concepts were **not copied as historical recovery**. Where a concept is reused here, it is explicitly classified as:

`NEW MASTER DATA — reused business concept, NOT historical recovery`

## Treasury ↔ COA contract

The current Production Cash/Sales contract is explicit:
- Treasury is passed by `treasury_id`.
- Cash GL account is passed separately as `cash_account_id`.
- Current POS writer selects GL cash account by `account_code='121'`.
- Production has no Treasury→COA foreign key and none was created by this phase.

Therefore `CASH-01 = 121` is **not** asserted as a database mapping. The proven contract is two explicit identities supplied to the cash core.
