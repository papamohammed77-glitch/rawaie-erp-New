# RAWAEA ERP — KHALID ACCOUNTING EXECUTION QUALIFICATION
## Autonomous CTO-in-Training / Closure Unit 01

**Date:** 2026-08-22  
**Role:** Khalid — Continuity / Architecture / Autonomous CTO-in-Training  
**Rule:** Production first. Current Git second. Historical material is navigation/evidence only.  
**Current Production:** SMART ERP (`fiilmooggumokxanwiyx`)  
**Fresh Production time:** `2026-08-22 03:18:43.915421+00` UTC  
**Current Git main:** `d004e6ef1b2b32ee0d9668b4dda7a90d0f022ef5`  
**Primary mission:** ACCOUNTING CORE FORENSIC CLOSURE

---

# 1. EXECUTIVE STATUS

`AUTONOMOUS CTO READY = NO`

This qualification has moved from Knowledge Model into executable Closure work.

The first Closure Unit is not closed yet because the live evidence exposes multiple independent financial writers, unsafe direct table write capability, deployed Edge/Git drift, and unresolved financial contract semantics.

However, the unit is **actively executing**. No work was stopped because of missing information; unresolved items were split into:

- fixable without Owner Decision;
- requiring contract reconstruction;
- requiring runtime/consumer evidence;
- requiring explicit Owner Decision.

The current project is treated as a system under construction. The goal is not merely to reproduce the old behavior; it is to build a materially stronger ERP by reusing proven patterns from mature systems while preserving RAWAEA business contracts.

---

# 2. FRESH PRODUCTION RE-BASELINE

At `2026-08-22 03:18:43.915421+00` UTC:

| Metric | Current |
|---|---:|
| Companies | 3 |
| Users | 26 |
| Branches | 5 |
| Items | 50 |
| Stock rows | 26 |
| Inventory log | 3 |
| Stock vouchers | 0 |
| Orders | 0 |
| Runsheets | 0 |
| Purchase orders | 0 |
| Journal entries | 2 |
| Journal lines | 0 |
| Audit log | 1778 |
| Customer ledger | 0 |
| Supplier ledger | 0 |
| Driver ledger | 0 |

Production migration head remains:

`20260821023458 remove_orphan_e2e_inventory_logs_20260821`

Therefore the earlier `inventory_log=62 / stock_vouchers=1` baseline is stale.

Inventory is a regression foundation, not the active rescue target.

---

# 3. CURRENT GIT REALITY

`main` has advanced to:

`d004e6ef1b2b32ee0d9668b4dda7a90d0f022ef5`

The current head adds the Prompt 48 execution record. The repository is therefore moving faster than the older Accounting/Ledger baseline records.

Recent PR history also proves that the project already applies a disciplined Production-first rescue pattern: for example, receive-purchase had a dedicated consumer closure with stable `operation_id`, and send-stock-voucher had a Production-first target-branch correction. These are useful execution patterns, not Current Truth by themselves.

---

# 4. ACCOUNTING GLOBAL WRITER DISCOVERY — LIVE PRODUCTION

Current Production Edge functions include active financial capabilities:

- `save-journal-entry` v6
- `save-receipt-voucher` v5
- `save-payment-voucher` v3
- `save-daily-settlement` v3
- `update-driver-ledger` v1
- `save-sales-invoice` v15
- `receive-purchase` v12
- `complete-return` v24
- financial reporting functions such as `get-trial-balance`, `get-profit-loss`, `get-balance-sheet`, `get-cash-flow`, and `get-pnl-by-cost-center`.

Current PostgreSQL `pg_get_functiondef` evidence directly proves that these domain cores can write journals/ledgers:

- `save_sales_invoice_atomic`
- `receive_purchase_atomic`
- `complete_return_atomic`

There is no current Production function matching a central `post_journal_entry` contract that is proven as the universal financial posting boundary.

---

# 5. CRITICAL FINDING A — DIRECT FINANCIAL EDGE WRITERS

## `save-receipt-voucher` v5

The deployed Production source directly writes:

- `cash_box`
- `journal_entries`
- `journal_lines`
- `treasury`
- optionally `driver_ledger`

It also hard-codes:

`company_id = 00000000-0000-0000-0000-000000000001`

Authentication is performed, but company context is not derived from the authenticated user's `public.users.company_id`.

## `save-payment-voucher` v3

The deployed Production source directly writes:

- `cash_box`
- `journal_entries`
- `journal_lines`
- `treasury`

and uses the same hard-coded company ID pattern.

## `save-daily-settlement` v3

The deployed Production source directly writes:

- `daily_settlements`
- `journal_entries`
- `journal_lines`

and updates `driver_liabilities`.

It also hard-codes the company ID and performs multiple dependent writes as separate API operations instead of one database transaction.

## `update-driver-ledger` v1

The deployed Production source is a direct `driver_ledger.insert(...)` API. It does not call a central Ledger Core.

### Classification

These are not theoretical architecture smells.

They are **ACTIVE PRODUCTION FINANCIAL WRITERS**.

---

# 6. CRITICAL FINDING B — FINANCE TABLE WRITE SURFACE

Current Production `information_schema.role_table_grants` shows `anon`, `authenticated`, and `service_role` all have broad DML privileges on:

- `journal_entries`
- `journal_lines`
- `cash_box`
- `treasury`
- `customer_ledger`
- `supplier_ledger`
- `driver_ledger`
- `daily_settlements`
- `driver_liabilities`

Current RLS policies include permissive patterns such as:

`Allow all for all`

with:

`qual = true`

and:

`with_check = true`

on multiple financial tables.

### Classification

**CRITICAL FINANCIAL SECURITY EXPOSURE**

RLS being enabled is not sufficient evidence of safety when the active policy is effectively unconditional.

---

# 7. SAFE STAGING EXECUTION ALREADY PERFORMED

To test the financial write-boundary correction without risking Production, the following was applied to `rawaea-staging`:

```sql
REVOKE INSERT, UPDATE, DELETE, TRUNCATE
ON TABLE
  public.journal_entries,
  public.journal_lines,
  public.cash_box,
  public.treasury,
  public.customer_ledger,
  public.supplier_ledger,
  public.driver_ledger,
  public.daily_settlements,
  public.driver_liabilities
FROM anon, authenticated;
```

Migration name:

`staging_financial_direct_write_boundary_20260822`

### Post-migration verification

For all affected tables:

- `anon` retained SELECT/REFERENCES/TRIGGER only.
- `authenticated` retained SELECT/REFERENCES/TRIGGER only.
- `service_role` retained the DML capabilities required by current Edge/domain code.

This establishes a stronger capability boundary in Staging without changing Production yet.

**Staging Security Boundary Test = PASS**

Production deployment remains gated by the consumer matrix and runtime verification, not by lack of investigative progress.

---

# 8. CRITICAL FINDING C — TREASURY / CHART-OF-ACCOUNTS CONTRACT DRIFT

Production currently has:

`treasury.account_code = CASH-01`

but the `journal_lines.account_id` column is UUID and references `chart_of_accounts(id)`.

There is currently no `chart_of_accounts.account_code = CASH-01` row for the existing Production treasury.

The main company has a Chart of Accounts account:

- `121` = `النقدية (الخزينة الرئيسية)`

with a UUID distinct from the treasury UUID.

### Consequence

`CASH-01` cannot be blindly used as a Journal Line `account_id`.

The Financial Edge code currently accepts/falls back to code-like strings while the database contract expects UUID account identities.

This is a **PROVEN CURRENT CONTRACT DRIFT**.

It is not safe to fix by casting text to UUID or by guessing a universal treasury→COA mapping.

---

# 9. CURRENT JOURNAL DATA INTEGRITY

Current Production has exactly two Journal Headers and zero Journal Lines.

Both are `VoidInvoice` entries:

- `JE-VOID-1784927448473-476` → `VOID-ORD-1015`
- `JE-VOID-1784927457858-428` → `VOID-ORD-1016`

The referenced orders were created on 2026-07-24 and later deleted; `audit_log` proves the original order creation and deletion events.

Therefore the current evidence strongly supports that the two Journal Headers are **void markers created during invoice deletion cleanup**, not random orphan rows.

However:

- they are still `Posted`;
- they have zero lines;
- the accounting effect is therefore zero.

### Current classification

**PROVEN HISTORICAL VOID MARKERS / ACCOUNTING REPRESENTATION INCOMPLETE**

The correct correction is NOT to fabricate journal lines from the deleted invoice.

The correct next closure question is whether RAWAEA wants voided/deleted sales represented as:

1. no journal at all;
2. a fully balanced reversal journal;
3. a non-posted administrative void marker that is excluded from posted-ledger reports.

This is an Owner/Accounting contract decision, and the system can continue progressing independently around it.

---

# 10. INDUSTRY BENCHMARK — WHAT CAN BE BORROWED SAFELY

The current Production evidence does not require inventing financial architecture from scratch.

### SAP

SAP's Journal Entry model is document + multiple line items, including organizational context and posting date. SAP also treats reversal as a first-class operation with explicit reversal reason/reference and creates corresponding reversal documents rather than silently mutating the original posted document. citeturn364058search0turn364058search3turn364058search6

### Microsoft Dynamics 365

Dynamics 365 supports reversing posted journals as a reversal transaction and documents explicit handling for reversing customer/vendor ledger entries. Inventory posting can combine physical and financial posting for some transaction types while transfer orders can separate physical and financial updates. citeturn364058search1turn364058search4turn364058search8

### Odoo

Odoo's current accounting documentation ties inventory valuation to General Ledger entries and explicitly supports closing/valuation entries and accruals when the timing of physical and financial recognition differs. citeturn364058search12

### RAWAEA consequence

The stable pattern worth adopting is:

```text
Business Event
    ↓
Authoritative Financial Event
    ↓
Balanced Journal Document
    ↓
Journal Lines
    ↓
Ledger / Treasury projections
    ↓
Audit / Reversal linkage
```

and, for reversal:

```text
Original Posted Event
    ↓
Explicit Reversal Event
    ↓
Inverse Journal
    ↓
Reference to Original
```

This is an industry-derived pattern, not a replacement for RAWAEA's own Owner Decisions.

---

# 11. WHAT CAN BE IMPLEMENTED WITHOUT OWNER DECISION

The following are now independent and actionable:

### A. Tenant context

Every financial writer must derive company context from authenticated identity instead of a hard-coded company UUID.

### B. Direct-write capability boundary

Finance tables should not be directly writable by `anon`/`authenticated` when the intended path is Edge/Core.

The Staging boundary test is already successful.

### C. UUID account identity

Journal Lines must receive actual `chart_of_accounts.id` UUIDs. Account codes are lookup keys, not Journal Line foreign-key values.

### D. Transaction boundary

Receipt, Payment, and Settlement need a transactional database boundary before being considered production-grade financial operations.

### E. Idempotency

Receipt, Payment, Settlement and Driver Ledger operations need explicit operation identity, because generating a new timestamp/random reference on each retry is not a deterministic retry contract.

---

# 12. OWNER DECISIONS THAT MUST NOT BE FABRICATED

1. Treasury→Chart of Accounts identity/mapping policy.
2. VoidInvoice accounting semantics.
3. Payment/Receipt account selection semantics.
4. Daily Settlement accounting recognition rule.
5. Driver Ledger ownership vs settlement ownership.
6. Posting date vs document date policy.
7. Reversal policy for financial events.

Non-dependent work continues regardless.

---

# 13. CLOSURE UNIT STATUS

## ACCOUNTING CORE FORENSIC CLOSURE

**Status: OPEN — ACTIVE EXECUTION**

### Completed in this unit

- Fresh Production re-baseline on 2026-08-22.
- Global identification of the major financial Edge surface.
- Direct inspection of Production financial Edge source for receipt/payment/settlement/driver-ledger.
- Direct identification of hard-coded company context.
- Direct identification of Finance table grants and permissive RLS.
- Direct inspection of Journal Header/Line integrity.
- Direct reconciliation of the two VoidInvoice entries with their original deleted orders through `audit_log`.
- Direct discovery of Treasury/COA identity drift.
- Staging financial direct-write boundary applied and verified.
- Industry benchmark comparison completed for journal/reversal/inventory-accounting patterns.

### Not yet closed

- Canonical Accounting Event Contract.
- Canonical Treasury contract.
- Ledger engines.
- Exact consumer map for financial Edge functions.
- Production security rollout after consumer verification.
- Production replacement/deployment of direct financial writers.
- True runtime E2E for financial flows.
- True independent-session concurrency proof.

### Readiness

`AUTONOMOUS CTO READY = NO`

This is an execution gate, not an indication of lack of project understanding.

---

# 14. NEXT EXECUTION ORDER

The remaining work is now narrowed to the smallest safe chain:

```text
ACCOUNTING EVENT CONTRACT
        ↓
TREASURY ↔ COA CONTRACT
        ↓
ATOMIC RECEIPT / PAYMENT / SETTLEMENT CORE
        ↓
LEDGER CORE
        ↓
FINANCIAL SECURITY PRODUCTION ROLLOUT
        ↓
CONSUMER MATRIX
        ↓
DEPLOYMENT LINEAGE
        ↓
RUNTIME E2E
        ↓
CONCURRENCY
        ↓
DATA RECONCILIATION
        ↓
GLOBAL ZERO-DEBT
```

Inventory remains frozen as a regression foundation unless Production changes or contradictory evidence appears.

---

# 15. SELF-AUDIT

## Proved directly

- Current Production state at 2026-08-22 03:18 UTC.
- Current migration head.
- Active Production Financial Edge functions and versions.
- Direct financial writers.
- Hard-coded company contexts.
- Broad finance-table DML grants.
- Permissive finance RLS policies.
- Treasury/COA identity mismatch.
- Two header-only VoidInvoice journal records.
- Their source orders and deletion history.
- Staging write-boundary correction and verification.

## Proved from industry sources

- Journal document/line-item model and explicit reversal.
- Reversal as a new accounting document rather than mutation.
- Financial/inventory posting relationship patterns.

## Not claimed

- A central Accounting Core does not yet exist in current Production.
- A central Ledger Core does not yet exist in current Production.
- The exact Treasury→COA policy is not assumed.
- The VoidInvoice accounting policy is not assumed.
- Browser/runtime E2E is not claimed without actual runtime evidence.
- Concurrency is not claimed from sequential retries.

**FINAL:** `AUTONOMOUS CTO NOT READY — ACCOUNTING CLOSURE IN PROGRESS`
