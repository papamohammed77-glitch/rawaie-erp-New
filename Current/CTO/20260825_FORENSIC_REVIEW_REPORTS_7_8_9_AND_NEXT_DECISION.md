# RAWAEA ERP — FORENSIC REVIEW OF KHALID/HYTHAM REPORTS 7–9

Date: 2026-08-25
Authority: Production PostgreSQL > Current main > Current CTO Evidence > Reachable Historical Git > Reports

## 1. Scope

This record independently reviewed the reported work in:

- تقرير خالد 7 / 8 / 9
- تقرير هيثم 7 / 8 / 9
- تقرير + برومبت 58
- تقرير تقييم مرحلة + خطة
- Phase 0 / Phase 1 CTO artifacts

Reports were treated as historical claims only. Current state was rechecked directly in Production and live Git.

## 2. Current Production verified directly

Project: `fiilmooggumokxanwiyx`

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

Current production also contains 48 public PostgreSQL functions / overloads across 46 distinct names.

Current critical Edge versions verified directly include:

- save-sales-invoice v15
- receive-purchase v12
- complete-return v24
- complete-order-delivery v13
- save-journal-entry v8
- save-receipt-voucher v5
- save-payment-voucher v3
- save-daily-settlement v3
- update-driver-ledger v1
- create-stock-voucher v8
- send-stock-voucher v19
- receive-stock-voucher v21
- complete-stock-voucher v4
- cancel-stock-voucher v4

## 3. Current Git truth

Live `main` is now:

`db97d88a38535ad5ebe7d94ba23fabe4609070b7`

Latest commit:

`Add Khalid's Phase 1 COA recovery report`

Therefore all earlier HEAD values in Phase 0 reports are historical timestamps, not current truth.

## 4. Judgment — Khalid

### Correct and retained

- Direct Production baselines were appropriate.
- Single-company topology was correctly recognized.
- Treasury was not recreated.
- The historical 87 COA count was not converted into fabricated rows.
- Source exhaustion was correctly separated from exact row-level recovery.
- The reachable-source limitation was honestly stated.
- No Production COA mutation was performed.

### Current surviving status

`SOURCE EXHAUSTION = CLOSED` for the accessible/reachable evidence universe.
`EXACT 87 COA SOURCE = NOT FOUND`.
`EXACT 87 ROW RECOVERY = OPEN`.
`NO FABRICATION = TRUE`.

### Decision

Do not send Khalid into another identical search cycle. His next task is an owner-decision package unless genuinely new row-level evidence is supplied.

## 5. Judgment — Hytham

### Correct and retained

- Production schema/identity contract investigation was appropriate.
- UUID-based account identity was correctly separated from descriptive account names.
- Treasury↔COA was not inferred by naming convention.
- Staging parity was correctly treated as a real environment dependency.
- No security weakening was used to make staging pass.
- No Production COA/Treasury mutation was performed.
- SQL inspection was correctly distinguished from authenticated HTTP E2E and concurrency proof.

### Current surviving status

`PHASE 1 HYTHAM TECHNICAL CONTRACT = CLOSED` at the knowledge/contract level.
`PHASE 1 COA REPLAY = BLOCKED` by absent exact row-level source and staging structural parity.

## 6. Important corrections to stale reports

### Correction A — reports 8/9 are not current Production snapshots
Production has advanced beyond the 00:39–00:42 UTC snapshots.

### Correction B — receive_purchase has already advanced materially
Current Production signature is:

`receive_purchase_atomic(company_id, po_code, user_email, items, operation_id uuid)`

Current Edge v12 also supplies a deterministic/supplied operation identity.

The applied migration history proves subsequent receive-purchase idempotency/tenant hardening migrations are already in Production.

Therefore any earlier report describing receive-purchase operation identity as missing is historical drift, not a current defect.

### Correction C — manual voucher inventory writers have been further hardened after the reports
Applied migrations include manual voucher tenant/item identity closure and legacy receive-v2 closure. Current manual voucher posting delegates physical movement to `post_stock_movement`.

### Correction D — current physical-stock writer discovery
Direct PostgreSQL source scan currently finds only:

- `post_stock_movement` as Physical Stock / inventory-log writer;
- `reserve_stock` and `release_stock_reservation` as reservation paths.

The latter affect reservation state, not independent physical movement.

Therefore the current Production evidence supports the core contract:

`PHYSICAL MOVEMENT -> post_stock_movement -> stock_branches + inventory_log`

This does not by itself close runtime/E2E or all consumer lifecycle proof.

## 7. Phase 0 decision

`PHASE 0 = NOT CERTIFIED CLOSED`

Reason: migration↔Git lineage, deployed-source parity, complete writer classification, authenticated HTTP E2E, concurrency, and security debt remain open.

This does not invalidate the substantive work of Khalid or Hytham.

## 8. Phase 1 decision

`PHASE 1 COA RECOVERY = OPEN`

Reason: exact 87 row-level source remains absent.

`PHASE 1 HYTHAM TECHNICAL CONTRACT = CLOSED`

Reason: the current COA schema, account identity, parent contract, Treasury identity, and production safety boundary have been proven; replay cannot proceed without source rows and compatible staging.

Production COA mutation remains prohibited.

## 9. Next-step decision

### Khalid
Stop repeating the same evidence search. Produce an explicit owner-decision package:

1. evidence-exhaustion certificate;
2. exact missing historical fields/relations;
3. consequences of non-recovery;
4. two formally separated options:
   - new authoritative historical source;
   - NEW MASTER DATA creation project for the surviving company;
5. no Production mutation.

### Hytham
Open **PHASE 2 — INVENTORY ZERO-DEBT** as a controlled parallel technical track, because it does not depend on historical COA rows.

This is NOT a declaration that Phase 1 is closed globally. It is a dependency-aware parallelization approved to avoid idle time.

Phase 2 must operate Writer-by-Writer, beginning with global Physical Writer discovery and then:

post_stock_movement
→ Manual Voucher
→ Purchase
→ POS
→ Van Sales
→ Returns
→ Loading
→ Unloading
→ Adjustment
→ Picking / Reservation

For every unit: Historical / Production / Current Git / Consumer / Tenant / Item Identity / Idempotency / Runtime / Audit / Deploy / Production Verify / Closure.

## 10. Forbidden actions

- No fabricated COA rows.
- No Treasury recreation or inferred Treasury↔COA mapping.
- No Production COA mutation.
- No weakening of RLS/grants.
- No PWA changes merely because Core architecture exists.
- No `CLOSED` claim from SQL definition alone.
- No reuse of stale report snapshots as Current Truth.

## 11. Final self-audit

What was proved:
- Current Production baseline.
- Current Edge versions for critical consumers.
- Current main HEAD.
- Khalid's no-fabrication/source-exhaustion result.
- Hytham's technical contract result.
- Current Physical Stock writer boundary.
- Subsequent Production migration hardening.

What remains unproved:
- Exact historical 87 COA rows.
- Treasury↔COA historical business mapping.
- Full migration↔Git historical 1:1 lineage.
- Full deployed Edge hash↔Current source parity.
- Full writer classification.
- Authenticated HTTP E2E.
- Two-session concurrency.
- Financial RLS/table-grant closure.

Final status:
`PHASE 0 = NOT CERTIFIED CLOSED`
`PHASE 1 COA = OPEN`
`PHASE 1 HYTHAM TECHNICAL CONTRACT = CLOSED`
`PHASE 2 INVENTORY = AUTHORIZED AS PARALLEL CONTROLLED TRACK`
