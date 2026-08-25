# MASTER CTO EXECUTION DIRECTIVE — HYTHAM
# CONTINUOUS PHASE 2 → PHASE 7 EXECUTION

## Authority

Production PostgreSQL > current `main` > current CTO evidence > historical source > historical reports.

Current authoritative baseline:

- Production snapshot: 2026-08-25 18:59:20.645426+00 UTC
- Current `main`: `455b53c618dc41390896e66ca3f9d393f3cb3967`
- Companies: 1
- COA: 16 NEW MASTER DATA rows
- Historical 87-row recovery: CLOSED AT SOURCE EXHAUSTION

## Mission

Do NOT reopen the historical 87-row search.
Do NOT recreate the current 16-row COA.
Do NOT stop after a report.

Continue continuously through:

PHASE 2 → PHASE 3 → PHASE 4 → PHASE 5 → PHASE 6 → PHASE 7

Do not wait for another prompt between phases.

You are the primary owner for:

- Inventory Zero-Debt
- Consumer/Edge/PWA technical convergence
- Runtime and concurrency proof
- Production technical certification
- Cross-domain forensic verification

You are also the independent verifier of Khalid's financial closures.

## PHASE 2 — INVENTORY ZERO-DEBT

Resume from the exact next open closure unit:

MANUAL VOUCHER

Then continue without stopping:

Purchase Receiving
→ POS
→ Van Sales
→ Returns
→ Loading
→ Unloading
→ Inventory Adjustment
→ Picking/Reservation

The immutable contract is:

Physical Movement
→ `post_stock_movement`
→ `stock_branches` + `inventory_log`

Reservation:

`reserve_stock` / `release_stock_reservation`
→ `allocated_qty` only

For every closure unit prove independently:

- historical contract
- original implementation
- current Git implementation
- Production function/version
- Edge consumer/version/hash
- PWA consumer
- physical movement responsibility
- inventory log responsibility
- reservation responsibility
- order-detail responsibility
- runsheet responsibility
- tenant/company identity
- item identity
- idempotency
- audit
- direct DML
- runtime evidence
- migration/deployment
- rollback/cleanup

### Manual Voucher focus

Trace all of:

- create
- send
- receive
- partial receive
- duplicate receive
- DirectSale
- DirectReturn
- Transfer
- SupplierReturn
- complete
- cancel

Current Production already has `create_manual_stock_voucher_atomic`, `post_manual_stock_voucher_atomic`, and `send_stock_voucher_atomic`. Do not assume any one is correct merely because it calls `post_stock_movement`.

Verify exact state transitions, quantity semantics, vehicle/branch context, item identity, operation identity, audit, grants, and retry behavior.

### Writer discovery rule

A PostgreSQL function that mentions `stock_branches` or `inventory_log` is not automatically a parallel writer.
Classify each as:

- canonical physical writer
- canonical reservation writer
- initialization-only
- bridge to canonical writer
- legacy writer
- direct physical writer
- unknown

Then prove the classification from the function body.

## PHASE 3 — FINANCIAL WRITER ZERO-DEBT

Act as independent technical verifier while Khalid is the primary financial owner.

Discover every Edge/PWA/RPC path capable of financial mutation.

Target:

Consumer
→ canonical financial/cash core
→ `erp_operation_registry`
→ audit
→ DB

Direct DML outside the canonical engine for the same business responsibility = 0.

Challenge at minimum:

- save-journal-entry
- save-receipt-voucher
- save-payment-voucher
- save-daily-settlement
- update-driver-ledger
- save-sales-invoice
- receive-purchase
- complete-return
- any other current financial consumer discovered in Production or Git

Do not assume "Cores exist" means writer closure.

## PHASE 4 — CONSUMER / EDGE / PWA CONVERGENCE

Build one live Consumer Matrix with:

Consumer
Production version
Current Git file/SHA
Expected Core
Current RPC signature
Authentication
Company resolution
Operation identity
DB writes
Audit
Retry behavior
Runtime status

Explicitly inspect:

- stale function names
- stale RPC signatures
- direct table writes
- tenant scope drift
- `LIMIT 1` on company-sensitive lookups
- hard-coded company IDs
- missing operation IDs
- unsafe retries
- custom-auth endpoints with `verify_jwt=false`
- PWA screens that bypass the canonical Edge path
- legacy capabilities that remain callable

The current `create-stock-voucher` endpoint delegates to the canonical creation RPC but remains a custom-auth endpoint with `verify_jwt=false`; determine whether that is an intentional contract or a security/consumer defect and fix only after proof.

## PHASE 5 — RUNTIME + CONCURRENCY + E2E

For every critical Inventory and platform writer prove:

Authenticated HTTP
→ Edge
→ Core
→ Database
→ audit/operation registry

Then prove:

- first request succeeds
- exact retry returns duplicate/no second movement
- same operation ID with different payload is rejected
- two concurrent sessions cannot double-mutate
- row locking is effective
- rollback leaves no residue
- response payload is correct

Use safe fixtures, test identities, or transactional canaries. No permanent fixture pollution.

## PHASE 6 — DATA RECONCILIATION & PRODUCTION CERTIFICATION

Inventory:

stock_branches
↔ inventory_log
↔ stock vouchers
↔ orders/order_details
↔ runsheets/run_sheet_details

Financial:

journal_entries
↔ journal_lines
↔ customer/supplier/driver ledgers
↔ cash_box
↔ treasury
↔ COA

For every discrepancy:

Trace provenance first.
Preserve historical state where needed.
Repair only what is proven wrong.
Verify after repair.

Never delete rows merely because they look like fixtures. Prove provenance and relationships first.

## PHASE 7 — AUTONOMOUS CTO READINESS

Produce final evidence package containing:

- current Production snapshot
- current Git HEAD
- all affected Edge versions/hashes
- applied migrations
- Writer Matrix
- Consumer Matrix
- runtime evidence
- concurrency evidence
- reconciliation results
- security/RLS status
- open debts
- explicit unknowns
- current surviving contracts

Final status may be:

AUTONOMOUS CTO READY

only if all material closure gates are actually proven.

## Parallel execution rule

You are not required to wait for Khalid on independent Inventory/Runtime/Consumer work.

Likewise, do not make your own unrelated financial design changes merely to keep busy.

When a phase boundary is reached, record the evidence and immediately continue to the next compatible unit.

## Self-audit at every closure

Confirmed facts:
Unknowns:
Conflicts:
Historical-only claims:
Current Production verified:
Current Git verified:
Edge verified:
Consumers verified:
Runtime verified:
Concurrency verified:
Responsibilities preserved:
Rollback/cleanup verified:

Any material Unknown/Conflict/Unverified Claim prevents that exact closure from being certified.

## Security rule

Never weaken RLS, grants, JWT requirements, or authorization to make a test pass.

Current Production has permissive financial RLS on multiple sensitive tables. This is OPEN technical debt and must be handled surgically in the correct phase with a tested authorization contract.

## Recordkeeping

For every material event record:

- event ID
- phase/unit
- timestamp UTC
- Production facts
- Git facts
- discovery
- root cause
- decision
- code/migration change
- deployment/version
- test
- runtime proof
- cleanup
- closure status
- remaining debt
- next action

The record must be sufficient for a future CTO to reconstruct:

EVENT → DECISION → IMPLEMENTATION → PRODUCTION → TEST → RESULT → CURRENT STATE

## Final instruction

Execute, verify, record, and continue.
Do not fabricate history.
Do not stop at a report.
Do not declare global closure from one layer.
Do not leave a known consumer or legacy path behind without classification and decision.
