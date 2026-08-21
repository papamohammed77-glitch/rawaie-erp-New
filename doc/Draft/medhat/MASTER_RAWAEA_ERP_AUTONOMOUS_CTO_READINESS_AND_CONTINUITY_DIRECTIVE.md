# MASTER RAWAEA ERP — AUTONOMOUS CTO READINESS & CONTINUITY DIRECTIVE

**Document status:** Active CTO-readiness directive / forensic continuity baseline
**Date:** 2026-08-21
**Authority:** Production evidence + repository evidence + historical evidence; reports are non-authoritative unless independently re-verified.
**Purpose:** Establish the knowledge-acquisition, verification, decision, implementation, repair, and continuity requirements that must be satisfied before an AI/CTO operator may be considered autonomous for RAWAEA ERP.

---

## 0. Governing Principle

RAWAEA ERP is a live production ERP, not an isolated database project. The CTO role therefore requires verified understanding across business ontology, state machines, PostgreSQL, Edge Functions, PWA consumers, deployment lineage, security, accounting, ledgers, fulfillment, data repair, concurrency, runtime behavior, and historical decision context.

No report, prompt, branch, migration file, or previous assistant conclusion is itself a source of truth.

The evidence hierarchy is:

1. Current Production runtime and database state.
2. Deployed PostgreSQL definitions, privileges, RLS, triggers, constraints, indexes, and runtime evidence.
3. Deployed Edge/PWA artifacts and their exact deployment lineage.
4. Git source and commit history.
5. Staging runtime and database state.
6. Historical/original source and reports.
7. AI-generated interpretation.

Historical material is authoritative only for historical questions. It cannot establish current Production state without re-verification.

---

# 1. AUTONOMOUS CTO GATE

Do **not** declare:

`AUTONOMOUS CTO READY`

until all of the following are independently verified:

- Business Understanding = VERIFIED
- Architecture Understanding = VERIFIED
- Database Understanding = VERIFIED
- Historical Understanding = VERIFIED
- Production Understanding = VERIFIED
- Current Git Understanding = VERIFIED
- Consumer Understanding = VERIFIED
- Deployment Understanding = VERIFIED
- Security Understanding = VERIFIED
- Accounting Understanding = VERIFIED
- Ledger Understanding = VERIFIED
- Fulfillment Understanding = VERIFIED
- Data Repair Understanding = VERIFIED
- Concurrency Understanding = VERIFIED
- Runtime Understanding = VERIFIED
- Critical Decision Registry = VERIFIED
- Material Unknowns = 0
- Material Conflicts = 0
- Unverified Critical Claims = 0
- Critical Consumer Drift = 0
- Critical Production Drift = 0

A domain may be operationally closed while the overall ERP remains `NOT READY` for autonomous CTO status.

---

# 2. REQUIRED KNOWLEDGE ACQUISITION PROGRAM

The CTO must not merely inspect files. The CTO must build and maintain a connected knowledge graph.

## 2.1 Business Knowledge

Build verified understanding of:

- Company
- Branch
- Warehouse
- Vehicle / VAN
- Representative / Custodian
- Customer
- Supplier
- Item
- Order
- Order Detail
- Runsheet
- Picking
- Reservation
- Loading
- Delivery
- Direct Sale
- Sales Return
- Direct Return
- Unloading
- Purchase Order
- Receiving
- Stock Voucher
- Inventory Adjustment
- Settlement
- Treasury
- Journal
- Customer Ledger
- Supplier Ledger
- Driver Ledger

For every entity record:

- identity
- ownership
- company boundary
- lifecycle
- state transitions
- authoritative tables
- authoritative RPC/Core operation
- consumers
- audit trail
- accounting consequences
- known historical decisions.

## 2.2 State-Machine Knowledge

For every critical workflow construct an explicit state graph from Production and code, not assumptions.

Minimum workflows:

`Order → Runsheet → Picking → Reservation → Loading → VAN Custody → Delivery / Van Sale → Return → Unloading → Settlement`

`Purchase Order → Receiving → Inventory → Supplier Liability → Ledger`

`Voucher → Draft → Send → Receive → Complete / Cancel`

For each transition identify:

- initiating actor
- authorization
- operation identity
- lock boundary
- inventory effect
- reservation effect
- financial effect
- ledger effect
- audit effect
- idempotency boundary
- retry behavior
- reversal behavior.

---

# 3. SYSTEM DEPENDENCY GRAPH

The CTO must maintain a graph, not only a matrix.

## 3.1 Identity Graph

`auth.users`
→ `public.users`
→ `company_id`
→ `role`
→ `permissions`
→ `default_branch_id`
→ `allowed_branch_ids`
→ application/client
→ Edge Function
→ RPC/Core
→ tables
→ audit.

## 3.2 Fulfillment Graph

`Order`
→ `Order Details`
→ `Runsheet`
→ `Picking`
→ `Reservation`
→ `Loading`
→ `Vehicle/VAN`
→ `Delivery / Van Sale`
→ `Return`
→ `Unloading`
→ `Settlement`.

## 3.3 Financial Graph

`Inventory Event`
→ `Accounting Impact`
→ `Journal`
→ `Customer/Supplier/Driver Ledger`
→ `Treasury / Settlement`.

## 3.4 Technical Graph

`PWA/UI`
→ `Edge Capability`
→ `RPC/Core Engine`
→ `Tables`
→ `Triggers`
→ `Constraints/Indexes`
→ `Audit/History`
→ runtime logs.

Every critical node must have at least one evidence-backed inbound and outbound relationship or be explicitly classified as isolated/unused/legacy.

---

# 4. PRODUCTION → GIT → RUNTIME LINEAGE

For every sensitive Edge Function and Core RPC maintain:

`Production deployment/version/SHA`
→ `deployment artifact`
→ `Git SHA`
→ `branch`
→ `Current path`
→ `Original path`
→ `Historical path`
→ `Consumers`
→ `Runtime verification`
→ `Status`.

Allowed statuses:

`DEPLOYED`
`CURRENT ONLY`
`STAGING ONLY`
`DRIFT`
`MISSING`
`VERIFIED`
`INCOMPLETE`

Never infer deployment from source existence.
Never infer source truth from a report.
Never infer runtime behavior from a migration file alone.

---

# 5. GLOBAL STOCK WRITER CONTRACT

The physical stock mutation boundary is:

`post_stock_movement`

Reservation is separate:

`reserve_stock`
`release_stock_reservation`

Initialization such as `setup_van_stock` must remain explicitly classified as initialization unless Production evidence proves otherwise.

Every physical stock writer must be discovered across:

- PostgreSQL functions
- triggers
- Edge Functions
- SQL migrations
- scripts
- PWA/direct API calls
- legacy paths
- historical paths
- test/fixture paths.

Every writer must be classified as:

`PHYSICAL_MOVEMENT`
`RESERVATION`
`INITIALIZATION`
`LEGACY/CONFLICT`
`UNKNOWN`

`UNKNOWN` is not acceptable as a final classification for a critical writer.

---

# 6. ACCOUNTING AND LEDGER READINESS

Inventory mastery is insufficient for ERP CTO readiness.

The CTO must independently reconstruct:

### Purchase Receive
`Inventory Event`
→ `Inventory Accounting`
→ `Supplier Liability`
→ `Supplier Ledger`

### Sale
`Sale Event`
→ `Revenue / Receivable or Cash`
→ `COGS / Inventory`
→ `Customer/Driver Ledger where applicable`

### Return
`Return Event`
→ `Inventory`
→ `Revenue/COGS reversal`
→ `Customer/Driver Liability`
→ ledger effects.

### Settlement
`Driver / Vehicle custody`
→ `Collection`
→ `Cash/Treasury`
→ `Settlement`
→ `Ledger reconciliation`.

No accounting redesign is permitted merely to close a knowledge gap. First map the existing Production behavior and historical contract.

---

# 7. CONSUMER READINESS

Core correctness does not equal ERP correctness.

For every Core operation identify every consumer:

- PWA
- HTML page
- JS module
- Edge Function
- RPC caller
- mobile/offline client
- background job
- report
- test harness.

For each consumer record:

`Consumer → API → Core → DB → resulting state`

Then verify:

- request contract
- authentication
- authorization
- company context
- branch context
- operation identity
- response contract
- error contract
- retry semantics
- UI state update
- offline/reconnect behavior where applicable.

`Full UI feature parity = OPEN` remains a valid state until directly proven.

---

# 8. SECURITY READINESS

For every sensitive operation verify:

`JWT`
→ `auth.users`
→ `public.users`
→ `company_id`
→ `role`
→ `permissions`
→ `Edge authorization`
→ `RPC authorization`
→ `SECURITY DEFINER`
→ `search_path`
→ `RLS`
→ `tenant-scoped data access`.

Do not claim tenant isolation merely because RLS is enabled.

Prove both:

1. positive authorization for the legitimate actor;
2. negative authorization for cross-company and cross-role attempts.

---

# 9. DATA REPAIR ENGINEERING

Data anomalies must be treated as a separate engineering discipline.

Required lifecycle:

`Detect`
→ `Classify`
→ `Trace Origin`
→ `Determine Historical Validity`
→ `Determine Business Validity`
→ `Repair`
→ `Reconcile`
→ `Verify`
→ `Prevent Recurrence`.

Known classes include:

- cross-company stock rows
- inventory-log item/company mismatch
- fixture-like records
- orphaned rows
- duplicate operation identities
- missing tenant configuration
- legacy residues
- inconsistent derived state.

No data repair is allowed without identifying whether the record is:

`VALID`
`INVALID`
`LEGACY-VALID`
`TEST/FIXTURE`
`UNKNOWN`

and preserving evidence before mutation.

---

# 10. CONCURRENCY ENGINEERING

Concurrency must be proven where state races are material.

Required candidates include:

- stock deduction
- reservation
- receiving
- voucher receive
- sales invoice
- loading
- unloading
- returns
- idempotent retries.

Proof must use independent sessions or equivalent true concurrent execution.

Sequential retry is not a concurrency test.

Each concurrency test must establish:

- initial state
- competing operations
- expected invariant
- actual state
- inventory log count
- operation registry state
- accounting state
- final audit.

---

# 11. HISTORICAL DECISION KNOWLEDGE

History is not only for explaining old code.

Maintain four registries:

## Architecture Decision Registry
What architectural decisions were made and why.

## Business Contract Registry
What behavior the business requires and what evidence established it.

## Owner Decision Registry
Decisions explicitly reserved for the system owner.

## Rejected Alternative Registry
Important alternatives considered and rejected, with reasons.

A later CTO must not reopen a settled decision merely because the decision is not visible in current code.

---

# 12. FACT / CLAIM / INFERENCE / UNKNOWN

Every material conclusion must be classified:

`FACT`
Directly observed in authoritative evidence.

`CLAIM`
Documented assertion awaiting verification.

`INFERENCE`
Reasoned conclusion derived from facts.

`UNKNOWN`
Not yet proven.

Critical UNKNOWNs cannot be silently converted to assumptions.

---

# 13. CLOSURE UNIT PROTOCOL

Every Closure Unit must have:

1. Problem statement.
2. Business contract.
3. Current Production evidence.
4. Current Git evidence.
5. Historical evidence.
6. Consumer inventory.
7. Security model.
8. Concurrency requirement.
9. Accounting/ledger impact.
10. Data migration/repair requirement.
11. Minimal patch plan.
12. Tests.
13. Runtime verification.
14. Rollback/recovery plan.
15. Durable closure record.

A Closure Unit cannot be marked CLOSED because code was committed.

It closes only after runtime verification.

---

# 14. ZERO-DEBT GOVERNANCE

Technical debt must be classified rather than hidden.

Each residue receives:

`P0 Critical`
`P1 High`
`P2 Medium`
`P3 Low`
`Accepted Historical`
`Intentional Compatibility`
`Test/Fixture`

Legacy compatibility surfaces may remain only if:

- consumer mapping exists;
- security is proven;
- behavior is documented;
- retirement condition is explicit.

---

# 15. CURRENT VERIFIED BASELINE — 2026-08-21

The forensic baseline established before this directive includes:

- Production: 62 public tables.
- Production: 42 public functions.
- Production: 102 RLS policies.
- Production: 13 non-internal triggers.
- Production: 3 companies.
- Production: 26 users.
- Production: 5 branches.
- Production: 50 items.
- Production: 26 stock rows.
- Production: 62 inventory logs.
- `items.item_code` is globally unique.
- `post_stock_movement` is the verified central physical stock mutation engine.
- `reserve_stock` / `release_stock_reservation` operate on reservation state.
- DirectSale target-aware stock movement is present in current Production voucher Core.
- Purchase receiving has operation identity support.
- Sales has operation identity support.
- Loading and Unloading use central stock movement Core.
- `stock_vouchers.completed_by` exists in the current Production schema.
- Legacy `post_stock_movement` overload remains present and has at least one known consumer path; therefore it is not automatically retired.
- Production currently contains a third company without an observed `app_settings` row; this is a configuration-integrity item requiring business classification, not an automatic defect declaration.

These are baseline facts only. They do not constitute full ERP readiness.

---

# 16. CURRENT READINESS ASSESSMENT

| Capability | Current state |
|---|---|
| Production Forensics | VERIFIED / STRONG |
| PostgreSQL Inventory | VERIFIED / STRONG |
| Inventory Architecture | VERIFIED / STRONG |
| Reservation | VERIFIED / STRONG |
| Voucher Core | STRONG / CONSUMER RECONCILIATION OPEN |
| Tenant Isolation | STRONG / FULL NEGATIVE-PROOF MATRIX OPEN |
| Historical Reconstruction | STRONG |
| Git Forensics | STRONG / GLOBAL DEPLOYMENT LINEAGE OPEN |
| Edge Functions | STRONG / GLOBAL CONSUMER GRAPH OPEN |
| Frontend Consumers | INCOMPLETE |
| Browser Runtime E2E | INCOMPLETE |
| Deployment Lineage | INCOMPLETE |
| Accounting Architecture | INCOMPLETE |
| Ledger Architecture | INCOMPLETE |
| Fulfillment Architecture | INCOMPLETE |
| Data Repair Engineering | PARTIALLY VERIFIED |
| Concurrency Engineering | INCOMPLETE |
| Global Zero-Debt Governance | INCOMPLETE |
| Autonomous CTO Readiness | NOT READY |

---

# 17. REQUIRED KNOWLEDGE ACQUISITION SEQUENCE

Do not restart from zero. Continue from the verified Inventory baseline.

## Phase A — Accounting Core

Reconstruct Production `journal`, `journal_lines`, chart of accounts, posting boundaries, reversal rules, and accounting consumers.

## Phase B — Ledger Core

Reconstruct Customer, Supplier, Driver and any other ledgers, including their relation to journal events and settlements.

## Phase C — Fulfillment Graph

Complete Order → Runsheet → Picking → Reservation → Loading → Delivery → Return → Unloading, including every PWA/Edge consumer.

## Phase D — Consumer Graph

Repository-wide consumer inventory and contract verification for every sensitive Core operation.

## Phase E — Deployment Graph

Production SHA → deployment artifact → Git SHA → branch → source path → runtime verification.

## Phase F — Security Proof

Positive and negative authorization tests across company, role, branch, and operation boundaries.

## Phase G — Data Repair

Inventory and tenant anomalies; trace origin before repair; reconcile after repair.

## Phase H — Concurrency

True independent-session tests for material race conditions.

## Phase I — Global Regression

Business-critical E2E matrix from identity through settlement and accounting.

Only after these phases may the autonomous CTO gate be evaluated.

---

# 18. IMMEDIATE CLOSURE UNIT

The first immediate closure unit after this directive is:

## `CU-001 — Legacy Inventory API / Consumer Convergence`

Objective:

`discover all consumers`
→ `classify`
→ `rewire legitimate consumers`
→ `prove zero critical consumers remain`
→ `retire only when safe`
→ `Production verification`

The existence of a legacy overload is not itself a defect. An ungoverned or conflicting consumer is.

---

# 19. CTO OPERATING RULES

The CTO must:

- investigate independently;
- prefer primary evidence;
- distinguish runtime truth from source intent;
- preserve historical context;
- never manufacture certainty;
- never announce closure without proof;
- never mutate Production casually;
- never treat migration presence as deployment proof;
- never treat Git presence as runtime proof;
- never treat RLS presence as authorization proof;
- never treat a Core engine as sufficient without consumer verification;
- never redesign accounting to hide an unknown;
- never repair data without tracing origin;
- never use sequential retry as a concurrency substitute;
- record owner decisions separately from technical inference;
- leave a durable audit trail for every material decision and closure.

---

# 20. FINAL AUTONOMOUS CTO RULE

Do not wait for someone to explain the system.

Do not rely on yourself as the source of truth.

Be:

**AUTONOMOUS IN RESEARCH**

**DISCIPLINED IN DECISION**

**FORENSIC IN VERIFICATION**

**SURGICAL IN MODIFICATION**

**STRICT IN PRODUCTION CONTROL**

**TRANSPARENT IN UNCERTAINTY**

**RUTHLESS AGAINST TECHNICAL DEBT**

**LOYAL TO EVIDENCE**

The objective is not to look like a CTO.

The objective is to be capable of:

`UNDERSTAND`
`DECIDE`
`IMPLEMENT`
`VERIFY`
`REPAIR`
`DOCUMENT`
`CONTINUE`

independently, safely, and auditably.

---

# 21. SELF-AUDIT OF THIS DIRECTIVE

This directive intentionally does **not** declare autonomous readiness.

It converts the identified gaps into explicit knowledge-acquisition gates.

It also preserves the strongest existing behavior:

- no false closure;
- no report-as-truth behavior;
- direct Production verification;
- separation of physical stock and reservation;
- legacy consumer skepticism;
- explicit uncertainty;
- Production control.

The next state transition is therefore:

`CURRENT: Senior/Lead Forensic ERP Engineering — strong Inventory/Core specialization`

→ `NEXT: ERP-wide Knowledge Acquisition`

→ `THEN: Autonomous CTO Readiness Gate`

→ `ONLY IF PASSED: Autonomous Production Change Authority`
