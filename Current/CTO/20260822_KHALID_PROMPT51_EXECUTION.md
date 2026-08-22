# RAWAEA ERP — KHALID PROMPT 51 EXECUTION
## Production-first Closure / Consumer + Financial Security Track

**Date:** 2026-08-22  
**Role:** Khalid — Continuity / Architecture / Governance / Financial Security  
**Source directive:** `doc/Draft/medhat/برومبت 51`  
**Current Production:** SMART ERP (`fiilmooggumokxanwiyx`)  
**Current Git:** `main` at the execution time of this record

---

## 1. DIRECTIVE EXECUTED

Prompt 51 requires the next ERP phase to proceed as:

`ACCOUNTING → LEDGER → TREASURY → FINANCIAL SECURITY → CONSUMER MATRIX → DEPLOYMENT LINEAGE → CONCURRENCY → DATA RECONCILIATION → GLOBAL ZERO-DEBT`

For Khalid, the assigned execution units are:

- Accounting Contract Authority
- Treasury ↔ COA Contract
- Consumer Matrix
- Financial Security
- Deployment Lineage

Production is the runtime truth. Current Git is the change record. Historical reports are navigation/evidence only.

---

## 2. FRESH PRODUCTION SNAPSHOT

At `2026-08-22 03:18:43.915421+00` UTC:

| Metric | Current Production |
|---|---:|
| Companies | 3 |
| Users | 26 |
| Branches | 5 |
| Items | 50 |
| Stock rows | 26 |
| `inventory_log` | 3 |
| `stock_vouchers` | 0 |
| Orders | 0 |
| Runsheets | 0 |
| Purchase orders | 0 |
| `journal_entries` | 2 |
| `journal_lines` | 0 |
| `audit_log` | 1778 |
| `customer_ledger` | 0 |
| `supplier_ledger` | 0 |
| `driver_ledger` | 0 |

The Production migration head remains:

`20260821023458 remove_orphan_e2e_inventory_logs_20260821`

The earlier 62-log / 1-voucher snapshot is historical and is not Current Truth.

---

## 3. ACCOUNTING / FINANCIAL WRITER DISCOVERY

Direct Production inspection established active financial writers including:

- `save-receipt-voucher` v5
- `save-payment-voucher` v3
- `save-daily-settlement` v3
- `update-driver-ledger` v1
- `save-sales-invoice` v15
- `receive-purchase` v12
- `complete-return` v24

Current PostgreSQL domain cores also write financial state through:

- `save_sales_invoice_atomic`
- `receive_purchase_atomic`
- `complete_return_atomic`

Therefore financial posting is currently distributed and has not yet converged to one universal production writer boundary.

---

## 4. TREASURY ↔ COA CONTRACT FINDING

Production Treasury currently contains:

`account_code = CASH-01`

while `journal_lines.account_id` is a UUID FK to:

`chart_of_accounts(id)`

There is no proven Production row mapping the existing Treasury `CASH-01` value directly to a COA code.

The current company has a COA account:

`121 — النقدية (الخزينة الرئيسية)`

with its own UUID.

### Decision

No blind cast, string-to-UUID substitution, or invented universal mapping was made.

The Treasury→COA identity contract remains an explicit contract boundary / owner-gated item until proven from the actual accounting semantics.

---

## 5. FINANCIAL SECURITY — PRODUCTION FINDING

Production financial tables currently expose broad table grants and permissive RLS patterns. Examples include:

- `journal_entries`
- `journal_lines`
- `cash_box`
- `treasury`
- `customer_ledger`
- `supplier_ledger`
- `driver_ledger`
- `daily_settlements`
- `driver_liabilities`

The currently observed policy pattern includes `ALL` with unconditional `true` predicates on multiple tables.

This is a material financial write-surface exposure.

### Safety handling

Production was not tightened before Consumer coverage and Runtime replacement were proven.

A corresponding Staging capability boundary was tested first:

`REVOKE INSERT, UPDATE, DELETE, TRUNCATE`

from `anon` and `authenticated` on the sensitive financial tables.

Post-change verification confirmed application roles retained read-oriented privileges while `service_role` retained the DML needed by current domain execution.

**Staging Financial Write Boundary = PASS.**

Production rollout remains gated by Consumer Matrix + runtime proof.

---

## 6. CURRENT/PWA CONSUMER RECONCILIATION

### `Current/PWA/van-sales.html`

The current source was inspected directly.

#### Sales consumer

`submitQuickSale()` calls:

`RW_API.call('save-sales-invoice', ...)`

and already supplies:

`operation_id: crypto.randomUUID()`

at request construction time.

This consumer is therefore aligned with the currently proven operation-identity pattern for sales retries.

#### Receipt consumer

`collectPayment()` calls:

`RW_API.call('save-receipt-voucher', payload, ...)`

with a header containing:

- date
- `cashBoxId: 'MAIN'`
- customer/account label
- notes
- `collectedByDriverEmail`

and does **not** currently provide a proven operation identity.

### PWA decision

No PWA change was made.

Reason: the replacement Receipt Core contract and account-selection semantics are not yet closed. Adding an `operation_id`, changing `cashBoxId`, or changing account identity now would be inventing the future Core contract rather than surgically aligning the consumer to an already-proven Production contract.

This is intentional non-modification, not a stalled task.

### Modified Current/PWA file

**None.**

The currently published `van-sales.html` remains untouched because no safe, evidence-backed surgical function replacement is yet established for the Receipt consumer.

---

## 7. JOURNAL DATA RECONCILIATION

Production currently has two Journal Headers and zero Journal Lines:

- `JE-VOID-1784927448473-476` → `VOID-ORD-1015`
- `JE-VOID-1784927457858-428` → `VOID-ORD-1016`

Audit evidence links each to a deleted POS order created on 2026-07-24.

Current classification:

**Historical Void markers with incomplete posted-journal representation.**

No deletion and no fabricated Journal Lines were performed.

The remaining contract question is whether RAWAEA wants these records to be:

1. non-posted administrative void markers;
2. balanced reversal journals;
3. or removed through a controlled historical cleanup policy.

That is not safe to choose by inference alone.

---

## 8. WHAT WAS EXECUTED VS WHAT WAS NOT

### Executed

- Fresh Production baseline.
- Production financial writer discovery.
- Treasury↔COA identity inspection.
- Current/PWA consumer inspection.
- Financial table grants and RLS inspection.
- Staging direct-write boundary test.
- Journal/Audit provenance reconciliation.
- Current Git consumer lineage inspection.

### Intentionally not executed in Production

- No blind modification to `save-receipt-voucher`.
- No blind modification to `save-payment-voucher`.
- No blind modification to `save-daily-settlement`.
- No direct Production security lockdown before Consumer coverage.
- No PWA payload change without a proven replacement Core contract.
- No invented Treasury→COA mapping.
- No synthetic Journal Lines.

These are prevented by the Prompt 51 rules, not by lack of information or capability.

---

## 9. CURRENT CLOSURE STATUS

`ACCOUNTING CONTRACT AUTHORITY = ACTIVE`

`TREASURY ↔ COA CONTRACT = OPEN / OWNER-GATED WHERE POLICY IS REQUIRED`

`CONSUMER MATRIX = PARTIAL BUT EXPANDING`

`FINANCIAL SECURITY = STAGING BOUNDARY PROVEN / PRODUCTION ROLLOUT OPEN`

`DEPLOYMENT LINEAGE = OPEN`

`ACCOUNTING CORE = PRODUCTION-DEPLOYED PARTIAL CAPABILITY`

`FINANCIAL CLOSURE = OPEN`

`AUTONOMOUS CTO READY = NO`

---

## 10. NEXT KHALID EXECUTION ORDER

```text
Treasury ↔ COA Contract Closure
        ↓
Receipt / Payment Consumer + Core Contract Closure
        ↓
Daily Settlement Consumer + Contract Closure
        ↓
Financial Security Production Rollout
        ↓
Full Consumer Matrix
        ↓
Deployment Lineage
        ↓
Runtime Verification
```

Inventory remains frozen as a regression foundation.

No Current/PWA file will be changed until a single target function is proven defective and its replacement contract is proven in Production.
