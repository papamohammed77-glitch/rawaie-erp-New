# MASTER CTO EXECUTION DIRECTIVE — KHALID
# CONTINUOUS PHASE 2 → PHASE 7 EXECUTION

## Authority

Production PostgreSQL > current `main` > current CTO evidence > historical source > historical reports.

Current authoritative baseline for this directive:

- Production snapshot: 2026-08-25 18:59:20.645426+00 UTC
- Current `main`: `455b53c618dc41390896e66ca3f9d393f3cb3967`
- Company count: 1
- Current company: `00000000-0000-0000-0000-000000000001`
- Treasury count: 1
- COA count: 16
- Historical 87-row recovery: CLOSED AT SOURCE EXHAUSTION

## Mission

Do NOT reopen the historical 87-row search.
Do NOT recreate the 16-row COA already present in Production.
Do NOT stop after producing a report.

Your mission is to continue the ERP recovery/convergence continuously from the current state through:

PHASE 2
→ PHASE 3
→ PHASE 4
→ PHASE 5
→ PHASE 6
→ PHASE 7

You must move from one phase to the next as soon as its actual exit conditions are proven. Do not wait for a separate prompt.

You are the primary owner for:

- Financial architecture / writer convergence
- Financial consumer convergence
- Financial runtime proof
- Financial reconciliation
- Financial certification evidence

You are also a cross-reviewer for Inventory and must challenge Hytham's closure evidence using the same forensic standards.

## Non-negotiable execution discipline

Every unit follows:

UNDERSTAND
→ TRACE HISTORICAL CONTRACT
→ TRACE CURRENT PRODUCTION
→ TRACE CURRENT GIT
→ TRACE CONSUMER
→ IDENTIFY ACTUAL GAP
→ SURGICAL FIX
→ TEST
→ DEPLOY
→ PRODUCTION VERIFY
→ RECORD
→ CONTINUE

Never:

FOUND → REPORT → STOP

Never convert:

Migration PASS = Production PASS
Deployment PASS = Runtime PASS
Core exists = Writer closed

## PHASE 2 — INVENTORY ZERO-DEBT SUPPORT / CERTIFICATION

Do not rebuild `post_stock_movement`.

Your role:

1. Maintain an independent forensic review of Hytham's Inventory Writer Matrix.
2. Verify that each closure unit preserves business responsibilities.
3. Verify company/tenant identity and global-vs-company item identity against the live schema.
4. Verify idempotency and audit semantics.
5. Verify that direct physical mutation remains centralized.
6. Challenge any closure claim that lacks Production runtime evidence.

When Hytham closes Manual Voucher, Purchase, POS, Van Sales, Returns, Loading, Unloading, Adjustment, or Picking, review the evidence and either:

- ACCEPT with explicit scope, or
- REJECT with root cause and execute the required corrective action.

Do not modify Inventory merely for cosmetic consistency.

## PHASE 3 — FINANCIAL WRITER ZERO-DEBT

This is your primary phase.

Discover every Production and Edge consumer that can create:

- journal entries
- journal lines
- customer ledger
- supplier ledger
- driver ledger
- cash receipt
- cash payment
- daily settlement financial postings

Target contract:

Consumer
→ canonical Financial/Cash Core
→ erp_operation_registry
→ audit
→ database

Direct DML outside canonical Cores = 0 for the relevant responsibility.

Required closure matrix fields:

Writer | Production Version | Current Git | Consumer | Core | Direct DML | Idempotency | Tenant | Audit | HTTP | Runtime | Status

Investigate at minimum:

- save-journal-entry
- save-receipt-voucher
- save-payment-voucher
- save-daily-settlement
- update-driver-ledger
- save-sales-invoice
- receive-purchase
- complete-return
- complete-order-delivery where financial effects exist
- any other function discovered by global search

The current canonical Cores are already present. Do not replace them without evidence.

## PHASE 4 — CONSUMER / EDGE / PWA CONVERGENCE

Build and continuously update one Consumer Matrix across:

- PWA/main.html
- vouchers.html
- other PWA screens
- Edge Functions
- RPC signatures
- deployed versions
- current Git source

For each consumer prove:

input contract
→ authentication
→ company identity
→ operation identity
→ Edge
→ RPC/Core
→ DB
→ response handling

Explicitly detect:

- stale RPC names
- stale signatures
- direct table writes
- wrong tenant context
- `LIMIT 1` on company-sensitive lookups
- missing operation IDs
- retry-unsafe calls
- `verify_jwt=false` capabilities without a justified custom authentication contract
- PWA code still implementing retired business logic

Do not patch UI merely to hide backend defects.

## PHASE 5 — RUNTIME + CONCURRENCY + E2E

For every critical financial operation establish:

Browser/PWA
→ authenticated HTTP
→ Edge
→ Core
→ DB
→ audit/operation registry

Then prove:

1. first request succeeds;
2. exact retry returns duplicate/idempotent result;
3. two simultaneous requests do not double-post;
4. no lost update occurs;
5. transaction rollback leaves no partial business state;
6. response contract is correct.

Use safe transaction fixtures where possible. Production test data must not be left behind.

## PHASE 6 — DATA RECONCILIATION & PRODUCTION CERTIFICATION

Reconcile at minimum:

Financial:

journal_entries ↔ journal_lines
journal ↔ customer/supplier/driver ledgers
cash_box ↔ treasury
Treasury ↔ current COA operational contract

Inventory:

stock_branches ↔ inventory_log ↔ business documents

Fulfillment:

orders ↔ order_details ↔ runsheets ↔ run_sheet_details

Do not assume run_sheet_details is authoritative. Prove the current fulfillment contract from Production and Git before changing any source-of-truth relationship.

Every discrepancy requires:

PROVEN ROOT CAUSE
→ DATA PRESERVATION DECISION
→ SAFE REPAIR
→ RECONCILIATION QUERY
→ POST-REPAIR VERIFICATION

No destructive cleanup based on counts alone.

## PHASE 7 — AUTONOMOUS CTO READINESS

Build a final readiness package proving:

- current Production snapshot
- current main HEAD
- current Edge versions/hashes
- applied migrations
- canonical Core inventory
- Writer Matrix
- Consumer Matrix
- Runtime/E2E evidence
- concurrency evidence
- data reconciliation
- security/RLS state
- open debt
- known unknowns
- historical/current distinction
- exact next action for any remaining non-blocking debt

Only then may the system be described as:

AUTONOMOUS CTO READY

## Continuous execution rule

Do not stop between phases to ask for a new prompt.

When a phase's exit conditions are proven:

1. write its closure record;
2. update Open Debt;
3. create/verify Git record;
4. verify Production;
5. immediately begin the next phase.

If one area is blocked by an external dependency, continue every other independent closure unit. Do not turn one blocker into a project-wide stop.

## Self-audit required at every phase

Before declaring any closure:

Confirmed facts:
Unknowns:
Conflicts:
Unverified claims:
Production verified:
Current Git verified:
Consumers verified:
Runtime verified:
Responsibilities preserved:
Rollback/cleanup verified:

Any material Unknown/Conflict/Unverified Claim prevents that exact closure from being certified.

## Recordkeeping

For every material action create/update:

- event record
- decision record
- migration record if applicable
- deployment record if applicable
- runtime evidence
- current status

Include commit SHA and Production timestamp.

The record must be sufficient for a future CTO to reconstruct:

EVENT → DECISION → CODE → PRODUCTION → TEST → RESULT → CURRENT STATE

## Final instruction

Execute, verify, record, and continue.
Do not manufacture history.
Do not create duplicate master data.
Do not weaken security to make tests pass.
Do not declare global closure from partial closure.
Do not stop at a report.
