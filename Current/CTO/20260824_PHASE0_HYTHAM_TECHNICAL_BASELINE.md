# RAWAEA ERP — PHASE 0 HYTHAM TECHNICAL PRODUCTION BASELINE

Date: 2026-08-24
Role: Hytham — Production Technical / Database / Runtime Inventory Owner
Repository: `papamohammed77-glitch/rawaie-erp-New`
Production: `SMART ERP` / `fiilmooggumokxanwiyx` 

## 1. Authority / restriction

This document is evidence-only and was produced under Phase 0.

Authority:
`Current Production Reality > Current main > Current Evidence > Historical Sources > Reports`

No functional refactor, DDL, DML, deployment, PWA/UI change, Financial Writer refactor, Inventory Core rewrite, data cleanup, or legacy deletion was performed during this Phase 0 run.

## 2. Fresh Production snapshot

Direct read-only PostgreSQL verification:

- UTC: `2026-08-24 16:06:44.657473`
- PostgreSQL: `17.6`
- Companies: `1`
- Users: `24`
- Branches: `2`
- Items: `17`
- Stock rows: `20`
- Inventory log: `3`
- Stock vouchers: `0`
- Treasury: `1`
- Chart of Accounts: `0`
- Journal entries: `2`
- Journal lines: `0`
- Customer ledger: `0`
- Supplier ledger: `0`
- Driver ledger: `0`
- Orders: `0`
- Purchase Orders: `0`
- Runsheets: `0`

The current operating topology is a single company. No deleted/legacy company was used as current truth.

## 3. Public PostgreSQL function inventory

Direct `pg_proc` inventory reports **48 public functions**.

The complete function inventory was read from Production `pg_proc` with signatures, SECURITY DEFINER state and definitions. Critical classifications are summarized here; the raw function definitions remain the Production evidence source.

| Function family | Critical role | Writer / side effect | Phase 0 status |
|---|---|---|---|
| `post_stock_movement` (10 args) | canonical physical stock | `stock_branches`, `inventory_log` | VERIFIED |
| `post_stock_movement` (9 args) | legacy overload | delegates to 10-arg core | LEGACY / STILL PRESENT |
| `reserve_stock` | reservation | `allocated_qty` | VERIFIED |
| `release_stock_reservation` | reservation release | `allocated_qty` | VERIFIED |
| `post_journal_entry` | accounting core | `journal_entries`, `journal_lines`, registry/audit | VERIFIED |
| `post_customer_ledger_entry` | customer ledger core | `customer_ledger` | VERIFIED |
| `post_supplier_ledger_entry` | supplier ledger core | `supplier_ledger` | VERIFIED |
| `post_driver_ledger_entry` | driver ledger core | `driver_ledger` | VERIFIED |
| `post_cash_receipt_atomic` | cash receipt core | `cash_box`, treasury, journal core | VERIFIED |
| `post_cash_payment_atomic` | cash payment core | `cash_box`, treasury, journal core | VERIFIED |
| `save_sales_invoice_atomic` | sales transaction | orders + stock core + financial cores | VERIFIED STRUCTURE |
| `receive_purchase_atomic` | purchase receiving | receiving + stock core + financial cores | VERIFIED STRUCTURE |
| `complete_return_atomic` | return transaction | return + stock core + financial cores | VERIFIED STRUCTURE |
| `complete_runsheet_picking` | picking/reservation | reservation + order/runsheet | VERIFIED; 2 overloads |
| `complete_runsheet_loading` | loading | stock core | VERIFIED |
| `complete_runsheet_unloading` | unloading | stock core | VERIFIED |
| `create_manual_stock_voucher_atomic` | voucher creation | voucher state/details | VERIFIED |
| `send_stock_voucher_atomic` | voucher send | stock core | VERIFIED |
| `post_manual_stock_voucher_atomic` | voucher bridge | stock core | LEGACY / BRIDGE |
| `receive_manual_stock_voucher_v2` | legacy receive | stock core | LEGACY / STILL PRESENT |
| `send_manual_stock_voucher_v2` | legacy send | stock core | LEGACY / STILL PRESENT |
| `setup_van_stock` | initialization | stock row initialization only | VERIFIED INITIALIZER |
| report functions (`get_trial_balance`, `get_profit_loss`, `get_balance_sheet`, `get_cash_flow`, etc.) | reporting | read-only | VERIFIED STRUCTURAL |
| trigger functions (`fn_audit_trigger`, `sync_run_sheet_details`, etc.) | trigger callbacks | dependent on trigger events | VERIFIED |

## 4. Critical EXECUTE grants

Direct Production privilege checks:

| Function | anon | authenticated | public | service_role |
|---|---:|---:|---:|---:|
| `post_journal_entry` | false | false | false | true |
| `post_customer_ledger_entry` | false | false | false | true |
| `post_supplier_ledger_entry` | false | false | false | true |
| `post_driver_ledger_entry` | false | false | false | true |
| `post_cash_receipt_atomic` | false | false | false | true |
| `post_cash_payment_atomic` | false | false | false | true |
| `post_stock_movement` 10-arg | false | false | false | true |
| `post_stock_movement` 9-arg | false | false | false | false |
| `reserve_stock` | false | false | false | true |
| `release_stock_reservation` | false | false | false | true |
| `save_sales_invoice_atomic` | false | false | false | true |
| `receive_purchase_atomic` | false | false | false | true |
| `complete_return_atomic` | false | false | false | true |

Runtime closure is **not** inferred from these grants.

## 5. Writer discovery

### Physical stock

Observed direct physical-state writers in the canonical Production set:

- `post_stock_movement` → `stock_branches` + `inventory_log`
- `reserve_stock` / `release_stock_reservation` → reservation (`allocated_qty`) only
- `setup_van_stock` → initialization of `stock_branches`

### Journal

Canonical writer:
`post_journal_entry`

Current compound functions observed delegating to the core:
- `save_sales_invoice_atomic`
- `receive_purchase_atomic`
- `complete_return_atomic`
- `post_cash_receipt_atomic`
- `post_cash_payment_atomic`

### Ledgers

Canonical writers:
- `post_customer_ledger_entry`
- `post_supplier_ledger_entry`
- `post_driver_ledger_entry`

### Treasury / cash

Canonical cash writers:
- `post_cash_receipt_atomic`
- `post_cash_payment_atomic`

Daily Settlement remains a separate runtime/write-path closure item.

## 6. RLS baseline

RLS is enabled on all required sensitive tables. Current policy counts:

- companies 1
- users 4
- branches 4
- items 4
- stock_branches 1
- inventory_log 1
- chart_of_accounts 4
- treasury 1
- journal_entries 1
- journal_lines 1
- customer_ledger 1
- supplier_ledger 1
- driver_ledger 3
- stock_vouchers 1
- stock_voucher_details 1

### Security DRIFT observed (no Phase 0 remediation)

Public-role `Allow all for all` / unconditional policies remain on:
- `customer_ledger`
- `journal_entries`
- `journal_lines`
- `supplier_ledger`
- `treasury`

`driver_ledger` also has public-role insert/update policies with permissive checks.

These are **DRIFT / OPEN SECURITY DEBT**. No policy was modified in Phase 0.

## 7. Trigger baseline

Relevant non-internal triggers:

| Table | Trigger | Event | Function | Status |
|---|---|---|---|---|
| branches | `trg_enforce_van_branch_company_context` | BEFORE INSERT/UPDATE | `enforce_van_branch_company_context` | VERIFIED |
| items | `trg_audit_items` | AFTER I/U/D | `fn_audit_trigger` | VERIFIED |
| journal_entries | `trg_audit_journal_entries` | AFTER I/U/D | `fn_audit_trigger` | VERIFIED |
| journal_lines | `trg_audit_journal_lines` | AFTER I/U/D | `fn_audit_trigger` | VERIFIED |
| stock_vouchers | `trg_audit_stock_vouchers` | AFTER I/U/D | `fn_audit_trigger` | VERIFIED |
| treasury | `trg_audit_treasury` | AFTER I/U/D | `fn_audit_trigger` | VERIFIED |

No trigger changes were made.

## 8. Applied migration baseline

Latest directly observed Production migration:
`20260824151259 — 20260824_canonical_financial_writer_cores`

Recent applied chain also includes:

- `20260824145903 — 20260824_restrict_financial_core_execute_privileges_v2`
- `20260824144609 — converge_return_financial_writers_20260824_v3`
- `20260824144450 — converge_purchase_receiving_finance_20260824`
- `20260824144437 — create_supplier_ledger_core_20260824`
- `20260824144329 — converge_pos_driver_ledger_20260824`
- `20260824144317 — create_driver_ledger_core_20260824`
- `20260823185253 — retire_nonactive_companies_20260823_forensic_cleanup_v2`
- `20260823175537 — pos_credit_zero_cogs_fix`
- `20260823175432 — pos_cash_treasury_lookup_fix_v2`
- `20260823175400 — pos_cash_treasury_lookup_fix`
- `20260823175324 — pos_financial_closure_core_v1`
- `20260823175139 — financial_reporting_tenant_scope_and_runtime_fix_20260823`
- `20260822182733 — fix_post_journal_entry_schema_drift_20260822`
- `20260822182713 — fix_atomic_cash_cores_registry_columns_20260822`
- `20260822182631 — create_atomic_cash_receipt_payment_cores_20260822_v2`
- `20260822032213 — accounting_core_post_journal_entry_and_report_join_20260822`

**Open:** full 1:1 reconciliation of all historical applied versions to all Git migration files.

## 9. Current Git baseline

Current `main` HEAD at the end of this baseline window:
`c88159ed486819afe76dcf19614c204dcae242ae`

Commit message:
`docs(cto): complete Khalid Phase 0 governance baseline`

Critical Current sources checked:
- `Current/Edge_Functions/save-sales-invoice` — exists; current source synchronized to verified Production v15.
- `Current/Edge_Functions/receive-purchase` — exists.
- `Current/Edge_Functions/complete-return` — exists.
- `Current/Edge_Functions/save-journal-entry` — now exists in Current and represents the verified Production v8 contract.

## 10. Edge deployment baseline

Direct Production Edge inventory was queried from the SMART ERP deployment registry.

Critical deployed versions:

| Edge | Version | verify_jwt | Status |
|---|---:|---|---|
| save-sales-invoice | 15 | true | VERIFIED |
| receive-purchase | 12 | true | VERIFIED |
| complete-return | 24 | true | VERIFIED |
| complete-order-delivery | 13 | true | VERIFIED |
| save-journal-entry | 8 | true | VERIFIED |
| save-receipt-voucher | 5 | true | VERIFIED |
| save-payment-voucher | 3 | true | VERIFIED |
| save-transfer-voucher | 3 | true | VERIFIED |
| save-daily-settlement | 3 | true | VERIFIED |
| update-driver-ledger | 1 | true | VERIFIED |
| create-stock-voucher | 8 | false | DEPLOYED / auth must be proven from source |
| send-stock-voucher | 19 | false | DEPLOYED / auth must be proven from source |
| receive-stock-voucher | 21 | false | DEPLOYED / auth must be proven from source |
| complete-stock-voucher | 4 | true | VERIFIED |
| cancel-stock-voucher | 4 | true | VERIFIED |

The complete deployed inventory was queried directly. A complete per-edge byte/hash ↔ Current source map is still OPEN.

## 11. Critical technical path matrix

| Path | Production Core | Edge | Current source | Phase 0 status |
|---|---|---|---|---|
| Manual Voucher | voucher cores + stock core | create/send/receive/complete/cancel | present | VERIFIED STRUCTURE + LEGACY |
| Purchase Receiving | `receive_purchase_atomic` | v12 | present | VERIFIED STRUCTURE |
| POS / Sales | `save_sales_invoice_atomic` + financial/stock cores | v15 | present | VERIFIED STRUCTURE |
| Returns | `complete_return_atomic` | v24 | present | VERIFIED STRUCTURE |
| Loading | `complete_runsheet_loading` | v11 | present | VERIFIED STRUCTURE |
| Unloading | `complete_runsheet_unloading` | v6 | present | VERIFIED STRUCTURE |
| Picking / Reservation | picking overloads + reservation cores | v16 | present | VERIFIED; overload remains |
| Receipts | `post_cash_receipt_atomic` | v5 | consumer exists | RUNTIME UNVERIFIED |
| Payments | `post_cash_payment_atomic` | v3 | consumer exists | RUNTIME UNVERIFIED |
| Daily Settlement | settlement runtime path | v3 | lineage incomplete | UNVERIFIED |

## 12. Branch / PR baseline

Current Hytham branches still present:
- `heytham/prompt51-journal-v8-surgical-review`
- `heytham/prompt53-pos-financial-closure`
- `heytham/20260824-financial-writer-convergence`

PR #24 is **closed / not merged / historical** and is not current main authority.
PR #23 and earlier Hytham review PRs remain historical evidence only.

## 13. Open Drift / Debt discovered by Hytham

1. Financial RLS policies contain broad public-role `ALL/true` exposure on multiple financial tables.
2. Driver ledger table policies remain permissive even though core EXECUTE is restricted.
3. Legacy 9-arg `post_stock_movement` remains defined; it has no examined-role EXECUTE grant. Reachability/consumer closure is still open.
4. Legacy voucher bridge functions remain present and require consumer mapping before retirement.
5. Full applied-migration ↔ Git migration reconciliation is incomplete.
6. Full deployed Edge hash ↔ Current source parity is incomplete.
7. SQL definition inspection does not prove authenticated HTTP runtime closure.
8. SQL definition inspection does not prove two-session concurrency.
9. COA remains zero; no reconstruction was attempted.
10. Current operational transaction tables are empty; absence of rows must not be interpreted as business-flow closure.

## 14. Hytham Phase 0 completion state

`HYTHAM PHASE 0 TECHNICAL BASELINE = OPEN`

Reason: required technical inventory is substantially captured, but the assignment's completion condition still requires:

- complete 1:1 applied migration ↔ Git migration reconciliation;
- complete deployed Edge version/hash ↔ Current Git mapping;
- full 48-function writer classification with direct Git/source references;
- line-by-line reconciliation with Khalid's Phase 0 artifact;
- normalized open-debt handoff.

No functional changes were made during this Phase 0 run.
