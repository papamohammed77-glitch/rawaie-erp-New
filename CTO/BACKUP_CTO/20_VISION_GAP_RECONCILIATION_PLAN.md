# BACKUP CTO 20 — VISION GAP RECONCILIATION PLAN

## PURPOSE
This file converts the gaps identified by the successor CTO Vision Report into controlled evidence-driven work. It is not a declaration that any gap is already fixed.

## STATUS MODEL
OPEN = evidence or decision still missing.
READY = evidence exists and task can be planned.
PRODUCTION VERIFIED = implementation and runtime evidence completed.
CLOSED / GO = acceptance criteria fully met and durable record written.

## GAP-001 — COMPLETE RPC / SCHEMA RECONCILIATION
Question: Is the deployed COMPLETE RPC exactly aligned with the current Production `stock_vouchers` and `stock_voucher_details` schema and state machine?

Evidence required:
- exact Production table schema;
- exact deployed function signature and definition;
- all current callers;
- status transition behavior;
- completed_at/completed_by columns only if actually present;
- audit effects;
- inventory effect;
- duplicate execution behavior.

Acceptance:
No schema mismatch, no missing column reference, correct state transition, atomic behavior, and Production execution proof.

## GAP-002 — DIRECTRETURN RECONCILIATION
Question: Does current Production DirectReturn implement the owner contract `VAN -> MAIN` without losing custody responsibility or creating duplicate movement?

Evidence required:
- current Production movement RPC contract;
- current DirectReturn voucher creation path;
- current send/receive/complete consumers;
- inventory log effects;
- vehicle/representative references;
- original application behavior;
- current owner decision.

Acceptance:
Exact topology and responsibility model proven in Production.

## GAP-003 — CANCEL / AUDIT COMPLETENESS
Question: Does CANCEL preserve historical integrity and produce the intended audit trail without reversing a posted movement incorrectly?

Evidence required:
- deployed cancel RPC;
- voucher state constraints;
- audit/log tables and exact columns;
- before/after status evidence;
- posted-vs-draft boundary behavior;
- current caller(s).

Acceptance:
Draft cancellation works as intended, posted movements are protected, audit behavior is proven.

## GAP-004 — PARTIAL RECEIVE IDEMPOTENCY
Question: Can the same receive request be retried safely under concurrency without double movement?

Evidence required:
- exact deployed RECEIVE RPC;
- received_qty rules;
- request/reference/idempotency mechanism if present;
- row locks / constraints;
- concurrent test design;
- over-receive prevention;
- inventory log count under repeated request.

Acceptance:
Repeated/concurrent receive cannot duplicate inventory movement and cannot exceed original requested quantity.

## GAP-005 — UI FEATURE PARITY
Question: Does the candidate `vouchers.html` preserve all owner-valued behavior from the original and align with Gold references?

Evidence required:
- original `vouchers.html` full feature inventory;
- current candidate feature inventory;
- returns/picker Gold-reference comparison;
- permissions;
- lookups;
- search;
- validations;
- status transitions;
- error handling;
- offline behavior where applicable;
- RPC/API calls;
- visual interaction conventions.

Acceptance:
No unexplained feature loss and runtime behavior conforms to Production contracts.

## GAP-006 — VAN-SALES PARITY
Question: Does `van-sales.html` use VAN custody correctly and preserve all original sales/collection behavior?

Evidence required:
- original full function inventory;
- current source;
- exact backend calls;
- stock effects;
- customer financial effects;
- collection behavior;
- vehicle/driver selection;
- offline behavior.

Acceptance:
VanSale consumes VAN stock and preserves original business behavior.

## GAP-007 — CURRENT / CANDIDATE / DEPLOYED EDGE FUNCTION MAP
Create a three-state matrix:
Function | Original | Current Source | Candidate | Production Deployed | Consumer | Responsibility | Risk

Acceptance:
No critical function remains classified only by source presence.

## GAP-008 — PRODUCTION MAP BEYOND RESCUE SLICE
Build a current Production object map for remaining domains before touching sensitive domains.

Priority:
Loading / Unloading → Delivery / Returns → Accounting → Ledger → Settlement → Reporting.

Acceptance:
Every behavior-changing task has current object and consumer evidence before implementation.

## GAP-009 — STALE SNAPSHOT DETECTION
Any Production Evidence file older than the current checkpoint must be labeled as snapshot evidence, not timeless truth.

For current decisions:
- identify snapshot date;
- identify affected objects;
- refresh only the objects needed for the decision;
- preserve old snapshot for historical comparison.

## GAP-010 — BACKUP MEMORY RECONCILIATION
The successor CTO must compare all `CTO/BACKUP_CTO/*.md` against:
- current Master Context;
- current Task Ledger;
- latest Closeouts;
- current Production Evidence index.

Any discrepancy becomes a durable `CONFLICT` or `UNKNOWN` record. Do not silently edit away uncertainty.

## GAP CLOSURE RULE
No GAP is considered closed because its file exists. It closes only when its exact acceptance criteria are proven and recorded in the active task ledger.

## CONTROLLED EXECUTION RULE
Do not execute all gaps serially merely because they exist. At the start of each gap, identify dependencies, owner decisions, and whether fixing it is prerequisite to the next stage.

## CURRENT ORDER
1. Resolve governing NO GO reconciliation gate.
2. Complete evidence-driven gaps required for safe continuation.
3. Re-evaluate STAGE-28 readiness.
4. Only then proceed with Loading / Unloading Core.
