# RAWAEA ERP — 2026-08-25 FORENSIC PHASE 0 RECONCILIATION

## 1. Authority

Current Production Reality > Current Git main > Current Evidence > Historical Sources > Reports.

This record supersedes no historical report. Historical reports remain immutable historical evidence. This document records the surviving current state and the decision made after independent reconciliation.

## 2. Current Production snapshot

Captured directly from Production project `fiilmooggumokxanwiyx` at `2026-08-24 21:41:19.526822+00` (equivalent to 2026-08-25 local Cairo date window):

- PostgreSQL 17.6
- Companies: 1
- Users: 24
- Branches: 2
- Items: 17
- Stock rows: 20
- Inventory log: 3
- Stock vouchers: 0
- Treasury: 1
- Chart of Accounts: 0
- Journal entries: 2
- Journal lines: 0
- Customer ledger: 0
- Supplier ledger: 0
- Driver ledger: 0
- Orders: 0
- Purchase Orders: 0
- Runsheets: 0
- Audit log: 1855
- Applied migration head: `20260824151259`
- Public PostgreSQL function overloads: 48
- Distinct public function names: 46

## 3. Current Git

Current `main` HEAD was independently read from GitHub at:

`ff50bb2dc9416db313fa008ab60d9392b4a9da6e`

Latest commit message in the live `main` ref:

`إضافة تقرير هيثم الفعلي للتنفيذ`

This proves that the Phase 0 baseline documents contain historical HEAD snapshots (`000f57...`, `4a1ad...`, `c881...`) and must not be treated as one single HEAD. They are historical observations from different instants, not a single current baseline.

## 4. Validation of Khalid / Hytham Phase 0 work

### Khalid

Substantively correct:

- Production snapshot was directly queried.
- Single-company topology was correctly retained.
- Treasury was not recreated.
- Exact 87 COA recovery was not fabricated.
- Source exhaustion was correctly separated from exact 87-row recovery.
- Financial Core privilege hardening was correctly classified from Production.
- Broad financial RLS policies were correctly preserved as OPEN debt rather than patched during Phase 0.
- PR #24 was correctly treated as closed/unmerged historical evidence.

### Hytham

Substantively correct:

- 48 public function overloads are confirmed by current `pg_proc`.
- Core financial and inventory functions exist in Production.
- Security EXECUTE hardening is confirmed for canonical financial cores.
- Legacy stock/voucher capabilities remain present and must be handled through consumer mapping rather than assumption.
- SQL definition inspection was correctly distinguished from HTTP E2E and concurrency proof.
- Broad financial RLS remains a real open security debt.

## 5. Findings that prevent a false Phase 0 CLOSED declaration

1. The three Phase 0 documents contain different `main` HEADs because they were recorded at different times. The current live HEAD is now `ff50bb2...`.
2. Hytham explicitly left full applied-migration ↔ Git migration reconciliation OPEN.
3. Hytham explicitly left full deployed Edge hash/version ↔ Current source mapping OPEN.
4. Hytham explicitly left full line-by-line reconciliation with Khalid OPEN.
5. The current Production Edge inventory includes a substantial operational/canary/harness footprint. Presence alone does not establish consumer status.
6. Financial RLS still contains unconditional public-role `ALL USING true` policies on sensitive tables including `cash_box`, `customer_ledger`, `daily_settlements`, `journal_entries`, `journal_lines`, `supplier_ledger`, and `treasury`.
7. Production `save_sales_invoice_atomic`, `receive_purchase_atomic`, and `complete_return_atomic` are now structurally converged on canonical stock/journal/ledger/cash cores, but live transaction runtime remains unproven because the corresponding operational tables are empty.

## 6. Decision

`PHASE 0 = NOT CERTIFIED CLOSED`

Reason: the gate's own exit criteria require evidence reconciliation work that is explicitly still open. This is a governance hold, not a failure of the two assistants' substantive work.

## 7. Phase 1 authorization

Phase 1 may begin as a **controlled Financial Master Data recovery track** because it does not require a rewrite of Inventory, POS, UI, or Financial Writer architecture.

However:

- No Production COA insertion is authorized by this record.
- Staging is the only place for replay/validation.
- Production remains read-only for the COA recovery mission until exact source evidence is established and a separate production restoration decision is approved.
- Treasury `CASH-01` is not to be recreated.
- No Treasury↔COA mapping may be invented.
- Exact 87-row recovery remains OPEN until row-level evidence exists.

## 8. Phase 1 role split

Khalid = forensic source-recovery owner for exact historical COA row evidence and the resulting master-data dataset.

Hytham = technical contract / staging validation / schema-integrity counterpart. Hytham must validate that any source-backed COA dataset can be replayed safely against the current schema and that Treasury↔COA relations are evidence-backed; he must not invent accounts or duplicate Khalid's source-search work.

## 9. Required next prompts

- `Current/CTO/20260825_PHASE1_KHALID_C0A_RECOVERY_PROMPT.md`
- `Current/CTO/20260825_PHASE1_HYTHAM_MASTER_DATA_CONTRACT_PROMPT.md`

## 10. Closure rule

The Phase 1 prompts do not authorize Production mutation. They authorize investigation, staging replay, evidence generation, and owner-decision preparation.

Any claim of `COA RECOVERY = CLOSED` requires:

exact 87 source-backed rows + verified ownership remap + verified parent relations + schema/constraint validation + staging runtime validation.

No report may override this gate.
