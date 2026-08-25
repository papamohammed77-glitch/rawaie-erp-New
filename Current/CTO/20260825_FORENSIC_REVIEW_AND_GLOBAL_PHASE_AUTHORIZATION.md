# RAWAEA ERP — FORENSIC REVIEW & GLOBAL PHASE AUTHORIZATION

## Snapshot authority

Production PostgreSQL: 17.6
Production snapshot UTC: 2026-08-25 18:59:20.645426+00
Current main HEAD at review: `455b53c618dc41390896e66ca3f9d393f3cb3967`

Production counts at the authoritative snapshot:

- Companies: 1
- Users: 24
- Branches: 2
- Items: 17
- Stock rows: 20
- Inventory log: 3
- Stock vouchers: 0
- Treasury: 1
- Chart of Accounts: 16
- Journal entries: 2
- Journal lines: 0
- Customer ledger: 0
- Supplier ledger: 0
- Driver ledger: 0
- Orders: 0
- Purchase orders: 0
- Runsheets: 0

## Source hierarchy applied

1. Current Production
2. Current `main`
3. Current CTO/evidence records
4. Historical source artifacts
5. Historical reports

Historical reports remain evidence of historical state only.

## Forensic findings

### Historical 87-row COA

The historical 87-row dataset was not recovered. The previous exhaustive recovery effort correctly stopped at Source Exhaustion. No historical recovery claim may be made for the current 16-row COA.

### New Financial Master Data

Production currently contains 16 COA rows introduced by:

- `20260825013814_khalid_new_financial_master_data_v1`
- `20260825013838_khalid_new_financial_master_data_parent_links_v1`

The current rows are NEW MASTER DATA, not historical recovery.

Observed required production-facing codes include 121, 123, 124, 211, 41, and 51 plus their hierarchy.

### Inventory core

The immutable contract remains:

`Physical Movement -> post_stock_movement -> stock_branches + inventory_log`

`reserve_stock` and `release_stock_reservation` are reservation-only engines.

Production function inspection shows current physical writers/bridges either call `post_stock_movement` or perform reservation/initialization only. This establishes the core boundary, but does NOT certify consumer/runtime closure.

### Important remaining inventory findings

- `post_manual_stock_voucher_atomic` is still an active bridge and must be closed as a full consumer/edge/runtime unit.
- `send_stock_voucher_atomic` and purchase/return/loading/unloading paths must be verified end-to-end.
- `create-stock-voucher` now delegates to `create_manual_stock_voucher_atomic`, but its deployed endpoint remains `verify_jwt=false` with custom bearer validation; this belongs to consumer/security convergence and must be formally verified.
- `complete_runsheet_picking` uses reservation only and reports `inventory_log_written=false`; this is correct for reservation semantics but its identity/idempotency/runtime contract still requires closure.
- Loading/unloading paths call the canonical stock engine.

### Financial core

Current Production contains canonical:

- `post_journal_entry`
- `post_customer_ledger_entry`
- `post_supplier_ledger_entry`
- `post_driver_ledger_entry`
- `post_cash_receipt_atomic`
- `post_cash_payment_atomic`

Current inspected financial writers call these cores rather than independently inserting journal/ledger rows.

However, Financial Writer Zero-Debt is NOT certified because consumer coverage, authenticated HTTP E2E, concurrency, settlement, runtime evidence, lineage, and RLS remain open.

### Security / RLS

Current Production still has permissive `Allow all for all` policies on sensitive tables including:

- `cash_box`
- `customer_ledger`
- `daily_settlements`
- `journal_entries`
- `journal_lines`
- `supplier_ledger`
- `treasury`

`driver_ledger` also retains permissive public policies. These are real security debt and must be handled in the appropriate later phase without weakening protections to make tests pass.

### Current lineage

Historical reports cited older main HEADs. Current main is now `455b53c618dc41390896e66ca3f9d393f3cb3967` and therefore all old HEAD values are historical snapshots.

The current migration head includes the two Khalid COA migrations and the canonical financial writer core migration.

## Assessment of Khalid and Hytham

### Khalid

Correct on historical COA recovery discipline. No evidence of fabrication. Correctly stopped the historical search at source exhaustion.

Phase 1B execution is also currently supported by Production: the 16-row NEW Financial Master Data set exists and its migration lineage is present.

Required correction to old reports: do not recreate another COA and do not reopen the 87-row search unless a genuinely new authoritative source appears.

### Hytham

Correct on the architectural direction and Inventory core boundary. Global Writer Discovery is substantively verified at the PostgreSQL physical-mutation layer.

Required correction to old reports: "Physical Writers outside post_stock_movement = 0" is NOT equivalent to global Phase 2 closure. Consumer, Edge, PWA, grants, runtime, idempotency, tenant, item identity, audit, and legacy retirement still require proof.

## Execution decision

The project is authorized to proceed continuously through all remaining phases.

The project must NOT wait for the historical 87 rows.

The current 16-row NEW COA remains the production master data baseline. New accounts may be added only when current transaction requirements prove they are required; duplicates or replacement COA structures are forbidden without evidence.

### Phase sequence

- PHASE 2 — INVENTORY ZERO-DEBT: continue from the next open closure unit, starting with Manual Voucher.
- PHASE 3 — FINANCIAL WRITER ZERO-DEBT: begin after Phase 2 global physical-writer gate is certified, while independent financial investigation may proceed in parallel where no dependency exists.
- PHASE 4 — CONSUMER / EDGE / PWA CONVERGENCE
- PHASE 5 — RUNTIME + CONCURRENCY + E2E
- PHASE 6 — DATA RECONCILIATION & PRODUCTION CERTIFICATION
- PHASE 7 — AUTONOMOUS CTO READINESS

No phase may be declared globally closed based on report wording alone. Every closure requires current Production evidence, current Git evidence, deployment/version evidence, runtime evidence where applicable, and a recorded self-audit.

## No-loop rule

Historical-source searches are now closed unless a new authoritative artifact appears.
No repeated search/report/prompt cycle is permitted for the same evidence universe.

## Required final certification language

Use only the following states:

- VERIFIED
- PARTIALLY VERIFIED
- OPEN
- BLOCKED BY DEPENDENCY
- CLOSED AT SOURCE EXHAUSTION
- PRODUCTION VERIFIED
- RUNTIME VERIFIED
- NOT PROVEN

Do not use "100%" or "CLOSED" without naming the exact closure scope.

## Event recording

This file is the forensic transition record for the continuous execution directive. The two execution prompts below are the operational descendants of this decision and must be followed as living directives, not as report-writing exercises.
