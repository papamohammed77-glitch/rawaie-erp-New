# 44 — TASK-027 IMPLEMENTATION REALITY MATRIX
## Date: 2026-08-14
## Mode: READ-ONLY AUDIT / NO PRODUCTION MUTATION

## Purpose
This matrix separates what TASK-027 proved at runtime from what is actually present in the current/deployed Production path.

The rule is:

> A Task is not globally `PRODUCTION IMPLEMENTED` because a design exists, a Current file exists, an RPC exists, or a test passed.

Each implementation layer is classified independently.

## Status vocabulary

- `CONFIRMED` = directly evidenced from the relevant source/system.
- `NOT VERIFIED` = not directly established in this audit.
- `CONFLICT` = evidence exists on both sides.
- `PARTIAL` = some components are proven, others are not.
- `HISTORICAL` = historical-only evidence.
- `TARGET` = intended design, not implementation fact.

## Matrix

| Component | Designed | Owner Approved | Original Baseline | Current Code | DB Object Exists | Deployed Source | Version | Runtime Tested | Production Verified | Reality Status |
|---|---|---|---|---|---|---|---:|---|---|---|
| `post_stock_movement` central engine | CONFIRMED | CONFIRMED | HISTORICAL comparison available | NOT VERIFIED in this audit | **CONFIRMED** | **NOT-VERIFIED AS EDGE; DB FUNCTION CONFIRMED** | N/A | **CONFIRMED by TASK-027 closeout** | **CONFIRMED DB object / partial behavior proof** | **PARTIAL** |
| DirectSale source -> target movement semantics | CONFIRMED | CONFIRMED | HISTORICAL source-only defect | NOT VERIFIED in this audit | **CONFIRMED through deployed DB function behavior** | Not applicable as a pure DB RPC | N/A | **CONFIRMED by TASK-027 runtime gate** | **CONFIRMED for direct RPC test; not globally verified through all callers** | **PARTIAL** |
| `setup_van_stock` generated-column correction | CONFIRMED | CONFIRMED | HISTORICAL write to generated `available_qty` | NOT VERIFIED in this audit | NOT VERIFIED as exact deployed object | NOT VERIFIED as current consumer | NOT VERIFIED | Historical/runtime evidence recorded in closeout | **NOT VERIFIED globally** | **NOT VERIFIED** |
| `setup-van-branch` canonical Vehicle-based identity | CONFIRMED target | CONFIRMED owner rule | Historical `VAN-{email}` behavior exists | NOT VERIFIED | Branch infrastructure exists | **CONFIRMED deployed v1** | **1** | Not separately tested in this audit | **CONFLICT** — deployed function still builds `VAN-{driver_email}` | **CONFLICT** |
| `send-stock-voucher` DirectSale caller path | CONFIRMED | CONFIRMED | Historical direct stock mutation | Current file reviewed previously; exact current/deployed parity not assumed | DB engine exists | **CONFIRMED deployed v6** | **6** | TASK-027 voucher E2E was documented | **CONFLICT** — deployed function directly mutates `stock_branches` and `inventory_log` instead of calling central engine | **CONFLICT / CRITICAL** |
| Manual Voucher CREATE | CONFIRMED | CONFIRMED | HISTORICAL | NOT VERIFIED in this audit | DB function/table support exists | **CONFIRMED `create-stock-voucher` v3** | **3** | TASK-027/earlier Gates documented | **PARTIAL** | **PARTIAL** |
| Manual Voucher COMPLETE | CONFIRMED | CONFIRMED | HISTORICAL | NOT VERIFIED in this audit | Table/object exists | **CONFIRMED `complete-stock-voucher` v3** | **3** | TASK-027/earlier Gates documented | **PARTIAL** | **PARTIAL** |
| Van branch stock baseline | CONFIRMED | CONFIRMED | HISTORICAL | NOT VERIFIED | **CONFIRMED** branch + stock rows | **CONFIRMED related infrastructure exists** | N/A | RS-1 snapshot observed VAN = 0 | **CONFIRMED snapshot only** | **PARTIAL** |
| DirectSale E2E test itself | CONFIRMED | CONFIRMED | Historical baseline | N/A | DB objects confirmed | Deployed caller parity not proven | N/A | **CONFIRMED** from TASK-027 closeout | **CONFIRMED as test evidence, not full system deployment proof** | **CONFIRMED TEST / PARTIAL SYSTEM** |

## Important production contradiction

The most important finding is the difference between:

### TASK-027 runtime proof

A direct runtime test demonstrated that the central stock engine could execute:

```text
MAIN - Qty
VAN  + Qty
inventory_log = one movement
```

and the voucher flow reached `Sent` then `Completed`.

### Current deployed consumer reality

Production `send-stock-voucher` version `6` is deployed and directly performs:

```text
stock_branches update
inventory_log insert
```

for `DirectSale`, rather than delegating the stock effect to `post_stock_movement`.

Therefore:

> `TASK-027 CLOSED / GO` remains valid as a runtime gate for the tested central-engine scenario, but it is **not sufficient evidence that every Production DirectSale caller has been migrated to the central engine**.

This is exactly why the Implementation Reality Matrix exists.

## Another production contradiction

`setup-van-branch` version `1` is deployed and still creates branches using:

```text
VAN-{driver_email}
```

while the current owner/business contract is:

```text
Vehicle != Representative
Vehicle identity is independent of Driver identity
Canonical branch example: VAN-VEH-92yrzb
```

This is a Production implementation conflict and must not be hidden by the TASK-027 headline.

## Final TASK-027 Reality Classification

```text
TASK-027 RUNTIME GATE              = CLOSED / GO
TASK-027 CENTRAL ENGINE PROOF      = CONFIRMED
TASK-027 GLOBAL DEPLOYMENT PARITY  = NOT VERIFIED
TASK-027 DEPLOYED-CALLER PARITY    = CONFLICT / PARTIAL
TASK-027 SYSTEM-WIDE GOLD          = NOT JUSTIFIED
```

## Governing rule going forward

Never use this shorthand:

`TASK CLOSED => all components Production implemented`

Use:

`Task gate status + component-level Implementation Reality Matrix`

instead.

## Safety audit

- Production mutations: NONE
- DDL: NONE
- Deployments: NONE
- Current code changes: NONE
- Original code changes: NONE
