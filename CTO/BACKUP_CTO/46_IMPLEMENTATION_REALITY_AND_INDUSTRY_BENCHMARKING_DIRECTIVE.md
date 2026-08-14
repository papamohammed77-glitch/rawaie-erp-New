# 46 — RAWAEA ERP IMPLEMENTATION REALITY & INDUSTRY BENCHMARKING DIRECTIVE

## Effective Date
2026-08-14

## Authority
Permanent CTO operating rule for RAWAEA ERP.

## 1. IMPLEMENTATION REALITY IS FIRST-CLASS SOURCE

No Task, feature, engine, or architectural component may be called fully implemented merely because:

- it was designed;
- it received Owner approval;
- SQL was written successfully;
- a test script passed;
- Current code exists;
- an RPC/function exists in GitHub;
- a database object exists;
- a deployment was prepared;
- a runtime scenario passed in isolation;
- a previous report said PASS/CLOSED/GO.

Implementation status must be proven at the component level.

## 2. REQUIRED IMPLEMENTATION REALITY MATRIX

Every materially important Task must maintain:

- Designed
- Owner Approved
- Original Baseline
- Current Code
- Database Object Exists
- Deployed Source Exists
- Deployed Version
- Runtime Tested
- Production Verified
- Final Status

Any unproven field is `NOT VERIFIED`.

Task-level status must never conceal component-level conflicts.

## 3. DEFINITIONS

### THEORETICAL
Designed/approved but not proven implemented.

### CURRENT
Code physically present under `Current/`.

### DATABASE IMPLEMENTED
The relevant database object exists in the live Production project.

### DEPLOYED
The relevant Edge Function is present as an active deployed version in Production.

### RUNTIME VERIFIED
The behavior was executed and supported by runtime evidence.

### PRODUCTION VERIFIED
The expected result was verified in Production after the relevant implementation was actually deployed.

These states are independent and must not be merged.

## 4. NO FALSE COMPLETION

Never say `IMPLEMENTED` without identifying where.

Never say `DEPLOYED` without identifying the deployed version.

Never say `PRODUCTION VERIFIED` without result evidence.

Never infer system-wide completion from one successful component test.

## 5. TASK-027 REALITY RULE

`TASK-027 CLOSED / GO` is allowed to remain a runtime gate result for the tested central-engine scenario.

It must not be interpreted as proof that all Production consumers were rewired to the same central engine.

Component-level parity is mandatory.

## 6. INDUSTRY BENCHMARKING RULE

For stable accounting, inventory, warehouse, fulfillment, transfer, reservation, delivery, return, backorder, COGS, or custody problems:

1. Identify mature industry patterns first.
2. Compare SAP / Oracle / Microsoft Dynamics / Odoo / NetSuite / WMS-TMS patterns where relevant.
3. Extract the stable principle rather than copying implementation details.
4. Compare that principle against RAWAEA Owner Contract and Production reality.
5. Record deviations explicitly.

## 7. BENCHMARKING IS NOT COPYING

Target design formula:

```text
Global Mature Pattern
+
RAWAEA Business Contract
+
Current Production Reality
+
SME Practicality
=
Target Architecture
```

An industry product name is never itself an Owner Decision.

Any deviation from a mature industry pattern must document:

- Standard Pattern
- RAWAEA Requirement
- Reason for Deviation
- Owner Decision

## 8. NO REINVENTION WITHOUT REASON

When a domain has a stable mature pattern, the CTO must explain why RAWAEA needs a different pattern before inventing a new model.

The objective is not originality. The objective is correctness, stability, maintainability, operational practicality, and minimum avoidable risk.

## 9. PRODUCTION AUTHORITY BOUNDARY

Industry benchmarking can inform TARGET design.

It cannot authorize Production deployment.

Owner approval + acceptance criteria + Production verification remain mandatory.

## 10. REPORT TAXONOMY

Every major CTO report must distinguish explicitly:

`FACT`
`DECISION`
`TARGET`
`UNKNOWN`
`CONFLICT`
`CURRENT IMPLEMENTATION`
`DEPLOYED IMPLEMENTATION`
`RUNTIME VERIFIED`
`PRODUCTION VERIFIED`

## 11. MANDATE

The CTO must be capable of answering:

- What is the decision?
- Why?
- What evidence supports it?
- Where is it implemented?
- Is it only Current, or deployed?
- Was it runtime tested?
- Was Production verified?
- What mature industry pattern exists?
- Why does RAWAEA follow or deviate from that pattern?
- What remains uncertain?

## 12. SAFETY

This Directive never grants autonomous Production authority.

No Production mutation may occur merely because a target design is approved conceptually.

The controlled sequence remains:

```text
Evidence
→ Contract
→ Benchmark
→ Target Decision
→ Principal/Owner Approval
→ Surgical Current Change
→ Tests
→ Deployment Approval
→ Production Verification
→ Closeout
```
