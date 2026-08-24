# RAWAEA ERP — PHASE 0 EXECUTION DIRECTIVE

## REBASELINE & GOVERNANCE GATE

Date: 2026-08-24
Repository: `papamohammed77-glitch/rawaie-erp-New`
Production project: `fiilmooggumokxanwiyx`

### Authority

`Current Production Reality > Current main > Current Evidence > Historical Sources > Reports`

Reports from Khalid, Hytham, Prompt 53, Prompt 54, Prompt 55/56, and older memory packages are historical evidence only unless independently revalidated.

### Current directly verified Production snapshot

Verified at `2026-08-24 15:52:47 UTC`:

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
- Latest applied migration observed: `20260824151259`

Current main HEAD observed immediately before this directive:

`000f57bf533c04daff8c32985ba0b454951568bd`

Current deployed Edge inventory includes, among others:

- `save-sales-invoice` v15
- `receive-purchase` v12
- `complete-return` v24
- `complete-order-delivery` v13
- `save-journal-entry` v8
- `save-receipt-voucher` v5
- `save-payment-voucher` v3
- `save-daily-settlement` v3
- `update-driver-ledger` v1
- `create-stock-voucher` v8
- `send-stock-voucher` v19
- `receive-stock-voucher` v21
- `complete-stock-voucher` v4
- `cancel-stock-voucher` v4

Production currently contains both canonical Cores and legacy/bridge capabilities. Phase 0 must inventory them; it must not infer closure merely from their existence.

## Objective

Create ONE AUTHORITATIVE BASELINE that reconciles:

1. Production PostgreSQL
2. Production Edge Functions
3. Production RPC definitions
4. schema / constraints / triggers / RLS
5. current rows and operational counts
6. current Git `main`
7. current migration files and applied migrations
8. current branches and PR status
9. Current/CTO evidence records
10. Open Debt / Conflict / Drift

No functional refactor begins until the baseline exists.

## Phase 0 success criteria

Phase 0 is CLOSED only when:

- Production snapshot is timestamped.
- Complete Production function inventory is captured.
- Complete Production Edge inventory is captured with deployed versions/hashes.
- Applied migration inventory is captured and mapped against Git migrations.
- Git HEAD is captured.
- Relevant branches and PRs are captured, including merged/unmerged/draft/closed status.
- Production/Git drift candidates are enumerated.
- Current schema/trigger/RLS/security baseline is captured.
- Open Debt Register is normalized into one list with evidence and owner.
- No historical report is being used as current truth without a Production/Git citation.
- Khalid and Hytham independently produce their assigned inventories and reconcile any discrepancies.

## Non-negotiable restrictions

- NO business-logic redesign.
- NO COA creation or reconstruction.
- NO Treasury recreation.
- NO Inventory rewrite.
- NO PWA/UI rewrite.
- NO Financial Writer refactor.
- NO data cleanup merely because rows look historical.
- NO migration creation during Phase 0 unless a purely documentary migration inventory mechanism is strictly required; default is evidence-only.
- Every database probe must be read-only.
- Every experimental query must be non-mutating.
- Do not convert `UNKNOWN` into `0` or `CLOSED`.
- Do not infer Runtime closure from SQL definition inspection.

## Required final artifacts

### Master baseline
`Current/CTO/20260824_PHASE0_CURRENT_STATE_BASELINE.md`

### Khalid governance/evidence artifact
`Current/CTO/20260824_PHASE0_KHALID_GOVERNANCE_BASELINE.md`

### Hytham technical Production artifact
`Current/CTO/20260824_PHASE0_HYTHAM_TECHNICAL_BASELINE.md`

### Open-debt normalized register
`Current/CTO/20260824_PHASE0_OPEN_DEBT_REGISTER.md`

These are deliverables of Phase 0, not placeholders.

## Final reconciliation

Khalid and Hytham must compare their outputs line-by-line for:

- Production timestamp
- Company topology
- Core function set
- Edge versions
- migration state
- Git HEAD
- PR/branch state
- security privileges
- known drift
- open debt

Any conflict prevents Phase 0 closure until resolved against Production or Git.

## Exit state

`PHASE 0 = CLOSED`

only after the evidence package is internally consistent and independently reproducible.

Otherwise:

`PHASE 0 = OPEN`
