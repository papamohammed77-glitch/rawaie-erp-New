# RAWAEA ERP — KHALID PROMPT 51 DIRECT EXECUTION CLOSURE
## Production-first / Consumer / Treasury / Security / Deployment Track

**Role:** Khalid  
**Production:** SMART ERP (`fiilmooggumokxanwiyx`)  
**Git:** `main` at execution record time  
**Source directive:** `doc/Draft/medhat/برومبت 51`

## 1. EXECUTION SCOPE

Prompt 51 assigns Khalid:

- Accounting Contract Authority
- Treasury ↔ COA Contract
- Consumer Matrix
- Financial Security
- Deployment Lineage

The global order remains:

`ACCOUNTING → LEDGER → TREASURY → FINANCIAL SECURITY → CONSUMER MATRIX → DEPLOYMENT LINEAGE → CONCURRENCY → DATA RECONCILIATION → GLOBAL ZERO-DEBT`

Inventory is preserved as a regression foundation and was not redesigned in this closure unit.

## 2. CURRENT GIT REALITY

Current `main` at the time of execution:

`e5961aa19d516361ae44d04a9d145ab9cc6e8617`

This commit records Hytham's Production accounting-core execution closure. It confirms the current Production core path includes:

- `post_journal_entry`
- `post_cash_receipt_atomic`
- `post_cash_payment_atomic`

and that legacy financial writer convergence remains open.

## 3. PRODUCTION ACCOUNTING CORE — DIRECT VERIFICATION

The current Production PostgreSQL definition of `post_journal_entry` is `SECURITY DEFINER` with a restricted search path and validates:

- company identity
- operation identity
- entry date/type/creator
- minimum two journal lines
- UUID account identity
- account/company ownership
- non-negative amounts
- one-side-per-line debit/credit rule
- non-zero debit and credit totals
- balanced journal rule
- idempotency through `erp_operation_registry`
- audit record creation

The current Production schema also confirms:

`journal_lines.account_id → chart_of_accounts.id`

and the journal entry is company-scoped.

## 4. TREASURY ↔ COA CONTRACT — CLOSED FOR CURRENT PRODUCTION IDENTITY

Current Production contains exactly one Treasury row for the active company:

- Treasury code: `CASH-01`
- Treasury name: `الخزينة الرئيسية`
- Treasury UUID: `0a9d9357-b5f3-4dfa-886f-7c73de4f274e`
- Company: `da4ef704-88ac-4120-aa0e-65b92b2aa2bc`

The same company has the active COA account:

- COA code: `121`
- COA name: `النقدية (الخزينة الرئيسية)`
- COA UUID: `c0da972b-6dbc-4f7c-96b8-acd33c86c736`

The identity is therefore proven by the Production records' UUIDs, company scope, and account names. The codes are different and MUST NOT be treated as interchangeable.

### Canonical current mapping

```text
Treasury CASH-01
    ↓ exact Production identity
COA 121 — النقدية (الخزينة الرئيسية)
```

This is a mapping of the current Production master data only. It is not a new universal rule for future companies.

## 5. CURRENT FINANCIAL WRITERS — DIRECT DATABASE SWEEP

Production PostgreSQL currently contains financial writers/capabilities including:

- `post_cash_receipt_atomic`
- `post_cash_payment_atomic`
- `save_sales_invoice_atomic`
- `receive_purchase_atomic`
- `complete_return_atomic`
- `post_journal_entry`

The current definitions show that several domain functions still contain direct `journal_entries`, `journal_lines`, `customer_ledger`, `supplier_ledger`, or `driver_ledger` writes.

Therefore:

`Accounting Core = deployed capability`

but:

`Financial Writer Convergence = OPEN`

No claim of universal single-writer closure is made.

## 6. CURRENT/PWA CONSUMER MATRIX — PROVEN ITEMS

### `accountant.html`

Current Git SHA:

`a0469e81cded644fafada4df24e5628111357e74`

Tabs:

- KPI
- سندات قبض
- سندات صرف
- قيود

The published source directly calls:

- `save-receipt-voucher`
- `save-payment-voucher`

The current PWA receipt/payment payload is not the same as the new atomic-core contract. It still supplies values such as:

- `cashBoxId: 'MAIN'`
- `mainAccountName` derived from the user-entered reference
- `lines[].accountName`
- amount/date/notes

The Production atomic cores instead require explicit UUID identities and operation identity.

### Decision

`accountant.html` is a proven financial Consumer but **not safe for surgical conversion yet** because the current UI does not establish the required offset-account UUID contract. Replacing the function without that contract would invent accounting policy.

**No PWA modification performed.**

### `vouchers.html`

Current Git SHA:

`2434b44d520a9a62b90e1735353343a6ad02ca72`

It is an inventory-voucher workspace for:

- Transfer
- DirectSale
- DirectReturn
- SupplierReturn
- Scrap
- Adjustment

It is not a receipt/payment Consumer. No unrelated finance modification was made.

## 7. FINANCIAL SECURITY — CURRENT PRODUCTION STATE

Production `information_schema.role_table_grants` currently shows broad DML privileges for both `anon` and `authenticated` on sensitive financial tables including:

- `cash_box`
- `customer_ledger`
- `supplier_ledger`
- `driver_ledger`
- `driver_liabilities`
- `daily_settlements`
- `journal_entries`
- `journal_lines`
- `treasury`

This means the direct-table write surface is still broader than the target architecture.

### Safety decision

Production DML was **not revoked in this closure unit** because the financial consumers and legacy writers have not yet fully converged. Revoking now could break active runtime paths before their replacement contracts are live.

The staged capability-boundary pattern remains the safety reference. Production rollout is a subsequent closure unit after Consumer Matrix and runtime proof.

## 8. DEPLOYMENT LINEAGE

Current Git provides exact source SHAs for the PWA consumers and exact current PostgreSQL function definitions.

The available repository evidence also shows recent Production-first accounting execution recorded at Git commit:

`e5961aa19d516361ae44d04a9d145ab9cc6e8617`

A complete Edge Function deployed-version/SHA registry is **not exposed by the available Production SQL surface** and therefore cannot be fabricated from Git filenames or historical reports.

Status:

`Deployment Lineage = PARTIAL / OPEN`

The remaining requirement is direct deployed Edge artifact/version evidence for each writer.

## 9. CURRENT ACCOUNTING DATA STATE

Direct Production inspection currently shows:

- `journal_entries = 2`
- `journal_lines = 0`
- `customer_ledger = 0`
- `supplier_ledger = 0`
- `driver_ledger = 0`
- `daily_settlements = 0`
- one Treasury row for the current active company

The two Journal Headers are known Void markers tied by audit evidence to deleted POS orders. No synthetic journal lines were created.

The treatment of these historical Void headers remains a business-policy decision unless a stronger Production contract proves the intended semantic.

## 10. NO CURRENT/PWA FILE WAS MODIFIED

This is deliberate and compliant with the surgical-change rule.

No safe target function has yet met all of the following simultaneously:

`PROVEN DEFECT + PROVEN REPLACEMENT CONTRACT + PRODUCTION-BACKED ACCOUNT IDENTITY + SAFE RUNTIME PATH`

Therefore:

**Modified `Current/PWA` files: NONE.**

No file was cosmetically changed, broadly refactored, or rewritten from assumptions.

## 11. CLOSURE STATUS

| Gate | Status |
|---|---|
| Accounting Contract Authority | ACTIVE |
| Treasury ↔ COA current-identity mapping | **CLOSED FOR CURRENT PRODUCTION COMPANY** |
| Receipt Consumer Contract | OPEN |
| Payment Consumer Contract | OPEN |
| Financial Security Staging Pattern | PROVEN |
| Financial Security Production Rollout | OPEN |
| Consumer Matrix | PARTIAL / ACTIVE |
| Deployment Lineage | PARTIAL / OPEN |
| Financial Writer Convergence | OPEN |
| Financial Concurrency | OPEN |
| Data Reconciliation | OPEN |
| Global Zero-Debt | OPEN |
| Autonomous CTO Ready | NO |

## 12. NEXT KHALID CLOSURE UNITS

```text
Receipt / Payment Consumer Contract
        ↓
Daily Settlement Consumer Contract
        ↓
Full Financial Consumer Matrix
        ↓
Production Financial Write Boundary
        ↓
Deployment Lineage Completion
        ↓
Runtime Verification
        ↓
Concurrency Evidence
```

The Inventory rescue remains frozen as a regression foundation while this financial closure proceeds.
