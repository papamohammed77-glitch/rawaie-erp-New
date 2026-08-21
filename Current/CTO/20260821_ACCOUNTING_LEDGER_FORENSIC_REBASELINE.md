# RAWAEA ERP — ACCOUNTING / LEDGER FORENSIC RE-BASELINE
## Mandatory execution of the Autonomous CTO evaluation

**Date:** 2026-08-21  
**Fresh Production snapshot:** 2026-08-21 17:35:34.123549+00 (UTC) / 20:35 Cairo  
**Production project:** SMART ERP (`fiilmooggumokxanwiyx`)  
**Git main HEAD checked during this run:** `d77ca55d8006d35b29a36ae959bc349eada57aa5`  
**Project plan:** `doc/Draft/Hussin/الخطة العامة الكبرى لـ RAWAEA ERP`

---

## 1. EXECUTIVE DETERMINATION

The previous `01:19 UTC` baseline is now classified as **STALE**.

Fresh Production currently proves:

- `inventory_log = 3`
- `stock_vouchers = 0`
- `audit_log = 1775`
- `companies = 3`
- `users = 26`
- `branches = 5`
- `items = 50`

Production migration history confirms the later cleanup sequence:

- `20260821023255 production_data_cleanup_test_voucher_and_orphan_company_20260821_v3`
- `20260821023458 remove_orphan_e2e_inventory_logs_20260821`

Therefore the current CTO baseline is the post-cleanup state, not the earlier 62-log / 1-voucher snapshot.

**AUTONOMOUS CTO READY = NO.**

The reason is now better defined: Inventory is strong, but Accounting/Ledger centralization, evidence lineage, consumers, deployment, concurrency, and global zero-debt remain open. In addition, current Production exposes a concrete accounting integrity conflict described below.

---

# 2. TRUTH HIERARCHY USED

1. Current Production schema/runtime/data/RPC/grants/RLS/migrations.
2. Current Git `main`.
3. Current CTO evidence artifacts.
4. Historical/original sources and prior Git history.
5. Reports and prompts as historical evidence only.

Historical claims were not promoted to current truth unless re-proven.

---

# 3. CURRENT PRODUCTION STRUCTURAL BASELINE

Current Production structural counts:

- Public tables: **62**
- Public functions: **42**
- Public RLS policies: **102**
- Public triggers: **13**

The following sensitive tables have RLS enabled:

- `chart_of_accounts`
- `journal_entries`
- `journal_lines`
- `customer_ledger`
- `supplier_ledger`
- `driver_ledger`
- `treasury`
- `daily_settlements`
- `stock_branches`
- `inventory_log`
- `stock_vouchers`
- `erp_operation_registry`

Current tenant identity constraints include:

`public.users.auth_id → auth.users.id`

via FK `users_auth_id_fkey`, with `UNIQUE(auth_id)`, plus:

`public.users.company_id → companies.id`

via `users_company_id_fkey`.

---

# 4. INVENTORY RE-BASELINE — STILL CLOSED

The fresh sweep confirms the inventory conclusion from the previous forensic work:

### Physical movement

`post_stock_movement(10 args)` remains the canonical executable physical movement engine.

### Reservation

`reserve_stock` and `release_stock_reservation` remain separate reservation capabilities.

### Legacy residue

The old 9-argument `post_stock_movement` object still exists as a PostgreSQL catalog object but is not executable by the normal application roles; it is not an active parallel stock writer.

### Current stock state

The cleanup migration reduced Production `inventory_log` to 3 and `stock_vouchers` to 0.

**Inventory Core status: VERIFIED / REGRESSION FOUNDATION.**

No Inventory restart is justified.

---

# 5. ACCOUNTING WRITER FORENSICS — CURRENT PRODUCTION

A direct `pg_get_functiondef` sweep of the current 42 public functions found current journal/ledger writers in these functions:

| Function | Journal | Customer Ledger | Supplier Ledger | Driver Ledger |
|---|---:|---:|---:|---:|
| `complete_return_atomic` | YES | YES | NO | NO |
| `receive_purchase_atomic` | YES | NO | YES | NO |
| `save_sales_invoice_atomic` | YES | YES | NO | YES |

The same live sweep also identified current read/report functions such as:

- `get_account_balance_as_of`
- `get_account_monthly_balance`
- `get_balance_sheet`
- `get_balance_sheet_data`
- `get_cash_flow`
- `get_pnl_by_cost_center`
- `get_profit_loss`
- `get_trial_balance`

### Critical correction to the previous knowledge model

Historical material referred to functions such as:

- `post_journal_entry`
- `save_journal_entry_atomic`
- `save_receipt_atomic`
- `save_expense_atomic`
- `save_opening_balance_atomic`

However, **they are not present among the current 42 public Production functions returned by PostgreSQL**.

This is a material **Historical/Current Contract Drift** finding.

It must not be “fixed” by inventing or deploying a new function merely because the historical plan names it. The first step is to reconstruct the current Accounting contract and provenance from Production + Git + migration history.

---

# 6. ACCOUNTING INTEGRITY FINDING — JOURNAL HEADER WITHOUT LINES

Fresh Production contains:

- `journal_entries = 2`
- `journal_lines = 0`

The two existing journal headers are:

1. `JE-VOID-1784927448473-476` — `VoidInvoice` — reference `VOID-ORD-1015`
2. `JE-VOID-1784927457858-428` — `VoidInvoice` — reference `VOID-ORD-1016`

Each of these two Journal Entries has:

`line_count = 0`

This is a concrete accounting integrity conflict because the Journal Header has no corresponding Journal Lines.

### Classification

**PROVEN DATA CONDITION**

Not yet proven:

- provenance of the rows
- whether they were intentionally archival/void markers
- whether lines were removed by a previous repair/cleanup
- whether downstream reports intentionally ignore them
- whether a corrective reversal exists elsewhere

### Mandatory safety status

**DO NOT DELETE OR SYNTHESIZE LINES YET.**

The project data-safety rule requires provenance, dependency impact, accounting/audit effect, rollback safety, and before/after evidence before historical data changes.

This is now an open **ACCOUNTING DATA-REPAIR CLOSURE UNIT**.

---

# 7. LEDGER CURRENT STATE

Current row counts:

| Ledger / Financial Store | Rows |
|---|---:|
| `customer_ledger` | 0 |
| `supplier_ledger` | 0 |
| `driver_ledger` | 0 |
| `treasury` | 1 |
| `daily_settlements` | 0 |
| `journal_entries` | 2 |
| `journal_lines` | 0 |

This means current Production has essentially no populated operational ledger history at this moment, except one Treasury master row and the two orphan-style Journal headers.

Therefore a Ledger architecture may exist structurally while runtime/data evidence of an active posted ledger is currently extremely sparse.

**Ledger Understanding = STRUCTURALLY VERIFIED / RUNTIME DATA PROOF INSUFFICIENT.**

---

# 8. CURRENT ACCOUNTING / LEDGER DOMAIN GRAPH

The current live pattern is not yet a single accounting core.

Current domain posting is distributed:

```text
Sales
  └─ save_sales_invoice_atomic
       ├─ post_stock_movement
       ├─ journal_entries / journal_lines
       ├─ customer_ledger
       └─ driver_ledger (specific Van credit case)

Purchase Receive
  └─ receive_purchase_atomic
       ├─ post_stock_movement
       ├─ journal_entries / journal_lines
       └─ supplier_ledger

Return
  └─ complete_return_atomic
       ├─ post_stock_movement
       ├─ journal_entries / journal_lines
       └─ customer_ledger
```

This proves domain accounting behavior, but not a central posting engine.

Hence:

**Accounting Core = OPEN**

**Ledger Core = OPEN**

---

# 9. ACCOUNTING WRITER MATRIX

| Event | Current writer | Physical effect | Journal | Ledger | Status |
|---|---|---|---|---|---|
| POS / Van Sale | `save_sales_invoice_atomic` | `post_stock_movement` | yes | customer + driver in specific credit path | VERIFIED CORE / centralization open |
| Purchase Receive | `receive_purchase_atomic` | `post_stock_movement` | yes | supplier | VERIFIED CORE / centralization open |
| Sales Return | `complete_return_atomic` | `post_stock_movement` for good goods | yes when accounts exist | customer | VERIFIED CORE / centralization open |
| Void Invoice | historical data exists as journal headers | unknown | header present | unknown | **DATA REPAIR OPEN** |
| Transfer | no current universal journal writer proven | physical movement | no universal posting proven | no | **OPEN** |
| Loading | physical movement | yes | no independent journal proven | no | **OPEN** |
| Unloading | physical movement | yes | no independent journal proven | no | **OPEN** |
| Adjustment | inventory adjustment engine | yes | accounting relevance not fully proven | ledger relevance not fully proven | **OPEN** |

No accounting design decision is being invented from names alone.

---

# 10. CONSUMER MATRIX — CURRENT STATUS

The critical consumer graph is not closed ERP-wide.

Known critical consumers include:

- POS / sales consumer → `save_sales_invoice_atomic`
- Purchase/receiving consumer → `receive_purchase_atomic`
- Return/POS return consumer → `complete_return_atomic`
- Voucher consumer → stock voucher RPCs
- Picker → reservation Core
- Loader → loading Core
- Unloader → unloading Core
- Delivery → `complete_order_delivery_atomic`

But the following remain unproven globally:

- every current PWA to exact deployed Edge version
- every Edge to exact Production RPC signature
- every Git consumer path vs deployed Edge artifact
- fallback/retry behavior for every critical consumer
- browser runtime parity

**Consumer Matrix = PARTIAL.**

---

# 11. SECURITY MATRIX — CURRENT PROOF

Current sensitive core RPCs are `SECURITY DEFINER` with `search_path=public`.

Examples verified directly:

- `post_stock_movement(10)`
- `receive_purchase_atomic`
- `complete_return_atomic`
- `save_sales_invoice_atomic`

`authenticated EXECUTE` is false for these sensitive RPCs; `service_role EXECUTE` is true where applicable.

All sensitive accounting/ledger tables checked are RLS-enabled.

However, table-level information_schema grants show non-zero mutation grants for the authenticated/service roles across the accounting/ledger table set. This means RLS and grants must be analyzed together; “RLS enabled” alone is not sufficient evidence of a closed write surface.

**Security Matrix = STRONG STRUCTURAL PROOF / GLOBAL AUTHORIZATION CLOSURE OPEN.**

---

# 12. DEPLOYMENT LINEAGE

Production migrations currently include the post-cleanup sequence through:

`20260821023458 remove_orphan_e2e_inventory_logs_20260821`

Git migration files exist for the major 19–21 August stream, but a complete:

`Git SHA → migration → deployed migration row → Edge/PWA artifact → runtime evidence`

matrix is not yet closed for the whole ERP.

Therefore:

**Deployment Lineage = PARTIAL.**

---

# 13. CONCURRENCY

Current core definitions demonstrate transactional patterns, row locking and idempotency in the sensitive Inventory/Fulfillment functions.

However, a complete independent-session concurrency matrix is not yet proven for:

- Accounting posting
- Ledger posting
- concurrent Sales
- concurrent Returns
- concurrent Purchase Receive
- concurrent Settlement

No sequential retry result is being counted as concurrency proof.

**Concurrency = PARTIAL.**

---

# 14. HYYTHAM CLAIM CORRECTIONS

The deleted Git artifact:

`doc/Draft/Hytham/RAWAEA_ERP_FORENSIC_KNOWLEDGE_REBASELINE_2026-08-21.md`

was recovered from its previous commit and compared with current Production.

Its key high-level conclusion is still valid:

> Production advanced significantly beyond the 15–20 August state, while Accounting/Ledger/Consumers/Deployment/Concurrency/ERP-wide regression remained open.

Its concrete `inventory_log = 3` and `stock_vouchers = 0` values are confirmed by the fresh Production query.

Therefore the deletion of the file does not invalidate its historical evidence.

However, claims in any deleted/recovered document are not current truth unless rechecked. Current Production remains authoritative.

---

# 15. KHALID CLAIM CORRECTIONS

No repository artifact or current indexed source accessible in this run was found under the name `Khalid` / `خالد`.

Therefore no Khalid claim will be invented or “corrected” from memory.

Status:

**UNKNOWN / SOURCE NOT FOUND**

The correct CTO behavior is to leave the claim unresolved until its source artifact is located, rather than fabricating a correction.

---

# 16. OPEN UNKNOWN REGISTER

1. Provenance and intended semantics of the two header-only Journal Entries.
2. Current replacement/absence lineage for historical `post_journal_entry` / `save_journal_entry_atomic` references.
3. Complete Accounting Consumer Matrix.
4. Complete Ledger Consumer Matrix.
5. Complete Git→Production deployment lineage.
6. Browser/runtime E2E of critical finance and warehouse paths.
7. Independent-session concurrency proof across all critical financial/fulfillment paths.
8. Full Security grant + RLS + SECURITY DEFINER authorization matrix across all critical financial operations.
9. Current authoritative model for Treasury movements vs `journal_entries`.
10. Current authoritative model for Daily Settlement → Driver Ledger → Treasury.
11. Full data-integrity reconciliation between Journal Headers, Journal Lines, Ledgers, Sales, Purchases, Returns, and Treasury.

---

# 17. OPEN DECISIONS

No business-contract redesign is authorized from this report alone.

Potential Owner Decisions that may become necessary after forensic reconstruction:

- whether Journal Header rows without lines are legitimate void markers or corrupt data
- whether Accounting will converge on one central journal-posting engine
- exact ownership between Journal Core, Ledger Core, Treasury and Daily Settlement
- whether any historical financial workflow is intentionally read-only/archival

All non-dependent investigation should continue without waiting for these decisions.

---

# 18. GLOBAL ZERO-DEBT STATUS

Current Zero-Debt sweep is **NOT CLOSED**.

Open categories:

- direct journal writer plurality
- direct ledger writer plurality / absence of central engine proof
- legacy accounting references not present in current Production
- consumer/deployment drift
- temporary/historical harness lineage
- global concurrency proof
- accounting data integrity
- current runtime browser proof

Inventory physical writers are not the blocker here; the blocker has moved to ERP-wide transactional and accounting truth.

---

# 19. READINESS GATE

| Domain | Status |
|---|---|
| Business Understanding | STRONG |
| Architecture | STRONG |
| Database | STRONG |
| Historical | STRONG |
| Production | STRONG / FRESH |
| Git | STRONG |
| Inventory Core | VERIFIED |
| Voucher Domain | VERIFIED CORE |
| Fulfillment | PARTIAL |
| Identity/Tenant | STRONG CORE / GLOBAL OPEN |
| Security | STRONG STRUCTURAL / OPEN GLOBAL |
| Accounting | **OPEN** |
| Ledger | **OPEN** |
| Consumers | **PARTIAL** |
| Deployment | **PARTIAL** |
| Concurrency | **PARTIAL** |
| Data Repair | **OPEN — JOURNAL HEADER/LINES CONFLICT** |
| Zero-Debt | **OPEN** |

### Gate

`AUTONOMOUS CTO READY = NO`

Critical blockers include:

- current accounting integrity conflict
- absence of proven central journal engine in current Production
- incomplete ledger proof
- incomplete consumer/deployment lineage
- incomplete concurrency proof
- unresolved global zero-debt

---

# 20. SELF-AUDIT

### What was proven
- current Production freshness
- cleanup migrations through `20260821023458`
- current Inventory core centralization
- current sensitive core SECURITY DEFINER/search_path state
- current RLS state
- actual current public function inventory
- current journal/ledger row state
- two Journal Headers with zero Journal Lines

### What was corrected
- previous baseline is stale
- historical `post_journal_entry` style references are not present in current Production
- Hytham baseline was recovered as historical evidence, not blindly trusted

### What remains unproven
- financial data provenance for orphan-style journal headers
- full central accounting architecture
- full ledger architecture
- complete runtime/browser E2E
- complete consumer/deployment matrix
- true concurrency proof

### What could still be wrong
- accounting writers may exist in deployed Edge Functions without a matching current DB function writer
- some grants may be permissive but protected by RLS; effective path requires policy-level evaluation
- historical finance records may have additional legacy semantics not represented in current empty/near-empty ledgers

### Current drift
The largest current drift is **historical accounting references vs current Production function catalog**.

### Closure state
**ERP-WIDE KNOWLEDGE CLOSURE = NOT COMPLETE**

**ACCOUNTING/LEDGER FORENSIC CLOSURE UNIT = OPEN**

---

# 21. IMMEDIATE EXECUTION ORDER

The mandated continuation order is:

1. Preserve this fresh baseline.
2. Forensic-trace the two header-only Journal Entries to their historical creation path.
3. Reconstruct every current and historical Accounting writer from Production and Git.
4. Reconstruct every current and historical Ledger writer.
5. Build the exact Accounting Event → Journal → Ledger graph for Sales, Purchase, Return, Expense, Receipt, Opening Balance, Transfer, Adjustment and Settlement where such contracts are actually proven.
6. Reconcile exact Edge/PWA consumers and deployment lineage for each finance writer.
7. Only then decide whether a central Accounting Core is required by evidence, rather than by architecture preference.
8. Run counter-forensics against the resulting accounting/ledger model.

No production data mutation is authorized by this document alone.

---

# FINAL CTO STATUS

> **AUTONOMOUS CTO NOT READY.**
>
> Inventory is a regression foundation, not the next discovery target.
>
> The next critical forensic boundary is **Accounting → Ledger → Consumers → Security → Deployment → Concurrency**, beginning with the proven current Journal Header/Journal Line integrity conflict.
