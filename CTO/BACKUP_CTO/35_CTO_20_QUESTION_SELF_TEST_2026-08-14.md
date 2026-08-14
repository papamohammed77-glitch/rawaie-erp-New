# 35 — CTO 20-QUESTION SELF-TEST — 2026-08-14

## Purpose
This document records the explicit 20-question self-test required by `30_FINAL_CTO_ASSIMILATION_AND_ACTIVE_EXECUTION_DIRECTIVE.md`. It supplements `34_CTO_GUARDIAN_TEST_RESULT_2026-08-14.md` and does not replace any historical readiness snapshot.

## Result
**20 / 20 — PASS**

All answers are grounded in the current CTO repository evidence hierarchy. Schema/deployment claims are not promoted from historical material to Production truth.

---

### 1. Why is `DirectSale` different from Loading?
`DirectSale` is the manual custody movement `MAIN -> VAN/mobile custody`, without requiring a Sales Order. Loading is the physical loading step of an already prepared Runsheet. They are separate workflows; conflating them can create duplicate stock deduction.

**Classification:** OWNER-DECISION / CURRENT CONTRACT.

**Evidence:** `30_FINAL_CTO_ASSIMILATION_AND_ACTIVE_EXECUTION_DIRECTIVE.md`, `31_STAGE28_OPERATIONAL_MEMORY.md`, `028-TASK-028-LOADING-UNLOADING-CORE-STATUS.md`.

### 2. Why is Unloading different from Customer Return?
Unloading is a Runsheet-level emergency reversal of a fully Loaded Runsheet back to `Picked` and restores warehouse state. Customer Return is order-granular and belongs to the delivery cycle. They have different triggers, quantities, and ownership semantics.

**Classification:** OWNER-DECISION / CURRENT CONTRACT.

**Evidence:** `31_STAGE28_OPERATIONAL_MEMORY.md`.

### 3. Who owns Van custody: vehicle or representative?
The representative/driver is the custody and accountability holder. The vehicle is the physical operating unit/mobile stock container. They are separate identities and a representative may change vehicles.

**Classification:** OWNER-DECISION.

**Evidence:** `30_FINAL_CTO_ASSIMILATION_AND_ACTIVE_EXECUTION_DIRECTIVE.md`, `31_STAGE28_OPERATIONAL_MEMORY.md`.

### 4. Why must `runsheets.driver_id` store `users.id`?
The Production FK contract is `runsheets.driver_id -> users.id`. The Current UI therefore uses the user's UUID as the dropdown value rather than email. Email is not the relational FK identity.

**Classification:** CONFIRMED.

**Evidence:** `028-TASK-028-LOADING-UNLOADING-CORE-STATUS.md`.

### 5. What is the official Runsheet numbering rule?
Find the highest existing `runsheet_code` within the active company and create the next number as previous + 1. If none exists in that company, start at `RS-1`.

**Classification:** OWNER-DECISION / CURRENT CONTRACT.

**Evidence:** `30_FINAL_CTO_ASSIMILATION_AND_ACTIVE_EXECUTION_DIRECTIVE.md`.

### 6. Why is `app_settings.runsheet_serial` not the current numbering source?
Because the owner-confirmed contract explicitly uses the previous company-scoped Runsheet number + 1. `app_settings.runsheet_serial` must not replace that contract unless the owner explicitly changes the decision.

**Classification:** OWNER-DECISION.

**Evidence:** `30_FINAL_CTO_ASSIMILATION_AND_ACTIVE_EXECUTION_DIRECTIVE.md`, `33_CTO_FINAL_READINESS_ADDENDUM_2026-08-14.md`.

### 7. Which table is the primary operational quantity record historically?
Historically, `order_details` is the primary order-line quantity source. It preserves the original requested quantity for an order line. This is a historical semantic claim and is not being asserted as a current Production schema fact without current schema evidence.

**Classification:** HISTORICAL.

**Evidence:** historical architecture memory preserved in `24_HISTORICAL_ARCHITECTURE_DECISION_CATALOG.md` and the historical repository.

### 8. What is the role of `run_sheet_details`?
It is the Runsheet-side operational detail/projection layer used for Runsheet execution quantities and outcomes. It does not retroactively replace the historical order-line source represented by `order_details`.

**Classification:** HISTORICAL / CURRENT STAGE-28 CONTEXT.

**Evidence:** `31_STAGE28_OPERATIONAL_MEMORY.md`, `028-TASK-028-LOADING-UNLOADING-CORE-STATUS.md`.

**Safety note:** Exact current Production columns must be re-proven before schema-level implementation.

### 9. Which quantity represents physical Loading?
`qty_loaded` represents the quantity physically loaded. It is distinct from `qty_picked`.

**Classification:** OWNER-DECISION / CURRENT CONTRACT.

**Evidence:** `31_STAGE28_OPERATIONAL_MEMORY.md`.

### 10. Which state must a Runsheet have before emergency Unloading?
`Loaded`.

**Classification:** OWNER-DECISION / CURRENT CONTRACT.

**Evidence:** `31_STAGE28_OPERATIONAL_MEMORY.md`.

### 11. What state follows complete emergency Unloading?
`Picked`.

**Classification:** OWNER-DECISION / CURRENT CONTRACT.

**Evidence:** `31_STAGE28_OPERATIONAL_MEMORY.md`, `028-TASK-028-LOADING-UNLOADING-CORE-STATUS.md`.

### 12. Why is historical `complete-loading` unsafe to copy blindly?
The historical implementation directly mutated MAIN stock, `inventory_log`, Runsheet/order quantities, and accounting. The historical Unloading implementation directly restored stock and reset quantities. Copying either blindly risks duplicate stock mutation, accounting duplication, and conflict with the current central inventory/custody architecture.

**Classification:** CONFIRMED HISTORICAL FINDING + ACTIVE ARCHITECTURAL RULE.

**Evidence:** `028-TASK-028-LOADING-UNLOADING-CORE-STATUS.md`, `Governance/RAWAEA_ARCHITECTURE_CONSTITUTION.md`.

### 13. What does `stock_branches.allocated_qty` represent?
Reserved/allocated quantity. It is not a physical stock movement. Physical quantity is represented by `stock_branches.qty`.

**Classification:** CONFIRMED CURRENT INVENTORY MODEL.

**Evidence:** `CTO/00_MASTER_CONTEXT.md` and current Inventory rescue memory.

### 14. Why can `available_qty` not be written directly?
Because it is generated/derived from underlying stock state. A previous failure demonstrated that attempting to write the generated value violates the database contract. The underlying physical/reserved quantities must be changed instead.

**Classification:** CONFIRMED FAILURE MEMORY / SCHEMA RULE.

**Evidence:** `CTO/00_MASTER_CONTEXT.md`, `25_HISTORICAL_FAILURE_FORENSICS.md`.

### 15. What is the authority hierarchy when Original, Current, and Production disagree?
Production evidence/deployed runtime is highest, followed by active CTO/Governance/Architecture records, Current source, Historical source/reports, and finally general model knowledge. Conflicts are explicitly labeled; they are not silently reconciled.

**Classification:** CONFIRMED GOVERNANCE.

**Evidence:** `CTO/00_MASTER_CONTEXT.md`, `CTO/01_SOURCE_AUTHORITY_MAP.md`, `30_FINAL_CTO_ASSIMILATION_AND_ACTIVE_EXECUTION_DIRECTIVE.md`.

### 16. What does Original vs Current mean in this repository?
`Original/` is the immutable forensic baseline. `Current/` is the single development/candidate workspace. Only Current may be surgically modified.

**Classification:** CONFIRMED GOVERNANCE.

**Evidence:** `30_FINAL_CTO_ASSIMILATION_AND_ACTIVE_EXECUTION_DIRECTIVE.md`.

### 17. What does a historical report prove?
It proves historical context or behavior at the time it was produced. It does not prove current Production deployment or runtime behavior. Current Production evidence must override stale historical claims.

**Classification:** CONFIRMED GOVERNANCE.

**Evidence:** `CTO/01_SOURCE_AUTHORITY_MAP.md`, `Governance/RAWAEA_ARCHITECTURE_CONSTITUTION.md`.

### 18. What must be tested before a Function becomes Gold?
The exact contract/schema must be proven; source must be reviewed; targeted runtime behavior must pass; boundary/error cases and concurrency/idempotency must be tested where applicable; inventory/accounting/audit effects must be verified; and durable evidence must support the acceptance gate. Source presence alone is never deployment proof.

**Classification:** CONFIRMED EXECUTION RULE.

**Evidence:** `Governance/EXECUTION_PROTOCOL.md`, `30_FINAL_CTO_ASSIMILATION_AND_ACTIVE_EXECUTION_DIRECTIVE.md`, `31_STAGE28_OPERATIONAL_MEMORY.md`.

### 19. What does rollback teach from previous work?
A permanent RPC/function fix can be erased if it is performed in the same transaction as disposable test work and that transaction is rolled back. Permanent implementation must therefore be separated from disposable test data, followed by post-rollback verification.

**Classification:** CONFIRMED FAILURE MEMORY.

**Evidence:** `25_HISTORICAL_FAILURE_FORENSICS.md` and the established failure-memory records.

### 20. What is the correct response to an unknown schema column?
Stop and inspect authoritative schema/deployed evidence. Do not invent the column, guess a name, or build a workaround around an unproven schema. Classify it `UNKNOWN` until evidence resolves it; if sources disagree, classify `CONFLICT`.

**Classification:** CONFIRMED GOVERNANCE.

**Evidence:** `Governance/EXECUTION_PROTOCOL.md`, `CTO/00_MASTER_CONTEXT.md`, `CTO/01_SOURCE_AUTHORITY_MAP.md`.

---

# FINAL RESULT

**20/20 — PASS**

All mandatory answers are understood.

This does not close the remaining Production/domain gaps and does not grant autonomous Production authority.

The current Stage-28 gate remains:

**EVIDENCE / CONTRACT RECONCILIATION**

No `complete-loading` or `unload-runsheet` patch should begin until the exact Production schema/constraints and clean `RS-1` fixture state required by `028-TASK-028-LOADING-UNLOADING-CORE-STATUS.md` are captured and reconciled.

**Self-certification:** `CTO READY — WITH DOCUMENTED GAPS`.
