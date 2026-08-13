# BACKUP CTO 21 — HISTORICAL MEMORY COMPLETION DIRECTIVE

## Purpose

This directive completes the remaining historical/institutional memory of RAWAEA ERP after the CTO Reconstruction Report.

It is a memory-reconstruction task, not a Production implementation task.

NO PRODUCTION CHANGE.
NO APPLICATION CHANGE.
NO RPC CHANGE.
NO MIGRATION EXECUTION.

The goal is to make the successor CTO capable of reconstructing the project's original behavior, historical rationale, failed approaches, and feature intent without guessing.

---

# 1. ACTIVE AUTHORITY

Active repository:
`papamohammed77-glitch/rawaie-erp-New`

Historical repository:
`papamohammed77-glitch/rawaie-erp-review`

Production truth outranks both when current runtime evidence exists.

Do not confuse historical understanding with current deployment state.

---

# 2. MISSION

You must complete the remaining historical memory in four dimensions:

1. Original Application Behavior
2. Original Edge Function Behavior
3. Historical Architecture / Decisions
4. Historical Reports / Failure Evidence

The output is a reconciled external memory layer.

Do not merely summarize files.
Extract behavior, dependencies, contracts, side effects, assumptions, and reasons.

---

# 3. MANDATORY REPOSITORY NAVIGATION

## Phase A — Active repository first

Before historical research, confirm:

- `CTO/00_MASTER_CONTEXT.md`
- `CTO/01_SOURCE_AUTHORITY_MAP.md`
- `CTO/03_CURRENT_STATUS.md`
- `Governance/RAWAEA_ARCHITECTURE_CONSTITUTION.md`
- `Governance/EXECUTION_PROTOCOL.md`
- `CTO/TASKS/00_CTO_PROJECT_EXECUTION_LEDGER.md`
- latest closeouts
- all `CTO/BACKUP_CTO/*.md`

Do not use historical material to override these.

## Phase B — Historical repository

Open `rawaie-erp-review` systematically.

### B1 — Master documentation

Read and reconcile when present:

- `docs/00_REVIEW_START_HERE.md`
- `docs/01_PROJECT_OVERVIEW.md`
- `docs/06_SYSTEM_ARCHITECTURE.md`
- `docs/09_DATABASE_DOCUMENTATION.md`
- `docs/10_API_CATALOG.md`
- `docs/13_SECURITY_MODEL.md`
- `docs/17_ARCHITECTURAL_DECISIONS.md`
- `docs/18_MODULE_RESPONSIBILITY_MATRIX.md`
- `docs/19_KNOWN_ISSUES_AND_DEBT.md`
- `docs/24_FINAL_CTO_REPORT.md`

If a file is absent, record `NOT PRESENT` rather than inventing it.

### B2 — Architecture

Inspect the historical `Architecture/` tree.

Priority topics:

- architecture constitution
- execution protocol
- domain execution order
- stock model
- manual stock vouchers
- custody model
- returns
- loading/unloading
- delivery/runsheet
- accounting
- ledgers
- security
- offline/PWA behavior

### B3 — Original PWA

Inspect original applications, especially:

- `PWA/warehouse/vouchers.html`
- `PWA/warehouse/picker.html`
- `PWA/warehouse/returns.html`
- `PWA/sales/van-sales.html`

Also discover and inspect other connected PWA applications when their behavior is relevant.

For every important application extract:

- user roles
- screens
- functions
- controls
- validations
- search/dropdowns
- API calls
- RPC calls
- status transitions
- stock effects
- accounting/ledger effects
- permissions
- error handling
- loading/empty states
- notifications
- offline behavior
- feature dependencies

### B4 — Original Edge Functions

Inspect:
`Edge_Functions/original/`

The directory ordering is not authoritative.

Build the inventory by function identity and actual responsibility, not folder order.

Classify each function as:

- inventory
- purchasing
- sales
- returns
- loading
- delivery
- settlement
- accounting
- ledger
- authentication/security
- reporting
- utility

For each important function capture:

- trigger/consumer
- inputs
- outputs
- tables touched
- RPCs called
- stock mutations
- journal effects
- ledger effects
- audit effects
- authorization
- company isolation
- idempotency
- concurrency assumptions
- known defects
- known replacement/current function if identifiable

### B5 — Historical reports

Inspect:
`Edge_Function_Reports/_HISTORICAL/`

Recover:

- previous function reports
- forgotten functions
- duplicated responsibilities
- old architecture decisions
- known bugs
- business semantics discovered during previous work
- any function that was considered important but later moved/replaced

Do not treat report wording as Production truth. Treat it as historical evidence.

---

# 4. HISTORICAL FEATURE PARITY MEMORY

For each primary UI, create a historical feature inventory.

At minimum:

| Application | Function | Original Behavior | Current Equivalent | Production Evidence | Status |
|---|---|---|---|---|---|

Status values:

- PRESERVED
- REPLACED
- MISSING
- UNKNOWN
- CONFLICT
- HISTORICAL ONLY

Do not mark `PRESERVED` from visual similarity.
It requires behavioral parity.

---

# 5. HISTORICAL BUSINESS SEMANTICS

Specifically search the historical repositories for terms and concepts involving:

- DirectSale
- DirectReturn
- DirectIssue
- VanSale
- VAN
- Vehicle
- Driver
- Representative
- Custody
- Loading
- Unloading
- Runsheet
- Return
- SupplierReturn
- Partial Receive
- Settlement
- Customer Collection
- Driver Ledger
- Vehicle Account
- Customer Debt

For every occurrence determine whether it is:

CONFIRMED OWNER DECISION
HISTORICAL BEHAVIOR
TARGET DESIGN
INFERRED
CONFLICT
UNKNOWN

Do not collapse different meanings just because names are similar.

---

# 6. DECISION FORENSICS

For every major historical architecture decision, answer:

1. What was the original decision?
2. What problem was it solving?
3. What alternative was rejected?
4. Why was it rejected?
5. Did Production ever implement it?
6. Was it later changed?
7. What downstream behavior depended on it?
8. What regression would occur if it were changed casually?

This is institutional memory, not documentation summarization.

---

# 7. FAILURE FORENSICS

Search historical records for incidents involving:

- stock duplication
- double deduction
- wrong branch
- wrong warehouse
- wrong driver
- wrong vehicle
- wrong voucher status
- missing inventory log
- journal duplication
- ledger inconsistency
- RLS failures
- permissions failures
- AppSheet/Google Sheets limitations
- performance issues
- race conditions
- offline synchronization
- image paths
- deprecated functions
- abandoned migrations

For each incident build:

Incident → Root Cause → Detection → Fix → Residual Risk → Lesson

Do not reintroduce a rejected pattern because the original incident was old.

---

# 8. DISTRIBUTED BUSINESS LOGIC FORENSICS

A major historical architectural concern is distributed business logic.

Identify every historical function/application that could directly mutate:

- stock
- inventory_log
- journal_entries
- ledgers
- custody
- settlement

Map:

`WHO MUTATES WHAT`

Then compare against current Core/RPC architecture.

Any duplication becomes an explicit architectural risk.

---

# 9. MEMORY OUTPUT FILES

Write/update these durable records in `rawaie-erp-New/CTO/BACKUP_CTO/` when the historical extraction is complete:

### `22_HISTORICAL_UI_BEHAVIOR_CATALOG.md`
Original PWA behavior and parity inventory.

### `23_HISTORICAL_EDGE_FUNCTION_CATALOG.md`
Original Edge Function responsibility map.

### `24_HISTORICAL_ARCHITECTURE_DECISION_CATALOG.md`
Historical decisions, alternatives and reasons.

### `25_HISTORICAL_FAILURE_FORENSICS.md`
Historical incidents and lessons.

### `26_BUSINESS_SEMANTICS_FORENSICS.md`
All historical business meanings and conflicts.

### `27_DISTRIBUTED_LOGIC_RISK_MAP.md`
Historical mutation paths and architectural risk map.

### `28_HISTORICAL_MEMORY_FINAL_RECONCILIATION.md`
Final reconciliation against current CTO memory and Production evidence.

### `29_CTO_MEMORY_COMPLETENESS_STATUS.md`
Final readiness statement.

---

# 10. COMPLETENESS TEST

Do not declare this work complete until the final reconciliation can answer:

- What did the original vouchers application actually do?
- What did the original van-sales application actually do?
- Which original Edge Functions altered stock?
- Which altered accounting?
- Which altered ledgers?
- Which features must be preserved?
- Which historical behaviors were intentionally rejected?
- Which historical behaviors remain unresolved?
- Which current Production behaviors differ from historical behavior?
- Which conflicts require owner decisions?

Every unanswered question must be marked UNKNOWN or CONFLICT.

---

# 11. PROHIBITED BEHAVIOR

During this memory task:

- Do not modify Production.
- Do not modify application code.
- Do not create test records.
- Do not interpret historical code as deployed truth.
- Do not silently reconcile conflicts.
- Do not delete historical files.
- Do not rewrite history.
- Do not fabricate missing files.
- Do not use general model knowledge to fill a missing historical fact without labeling it INFERRED.

---

# 12. FINAL OUTPUT

Produce a final:

`HISTORICAL MEMORY COMPLETION REPORT`

with:

1. Files inspected
2. Historical modules recovered
3. Original UI behavior recovered
4. Original Edge behavior recovered
5. Business semantics recovered
6. Historical decisions recovered
7. Historical failures recovered
8. Distributed-logic findings
9. Conflicts with current system
10. Unknowns remaining
11. Records written to `rawaie-erp-New`
12. CTO memory completeness percentage
13. Remaining risks

The percentage must be evidence-based.
Do not say 100% merely because the task was performed.

Only say:

`CTO MEMORY COMPLETE — 100%`

if every critical knowledge category has either:

- authoritative evidence,
- explicit owner decision,
- or explicit documented UNKNOWN/CONFLICT with a safe handling rule.

The goal is not to claim omniscience.
The goal is to make future execution safe even when historical knowledge is incomplete.
