# RAWAEA ERP — INV-001 INVENTORY REALITY MAP

**Phase:** 3 — Immediate Domain Execution
**Domain:** Inventory
**Priority:** P0
**Status:** Historical execution specification / baseline

## Purpose

إنتاج خريطة الحقيقة الفعلية للمخزون في النظام الحالي، وليس تصميم Inventory جديدًا.

## Hard classification

كل معلومة يجب أن تكون:

`CONFIRMED` / `INFERRED` / `UNKNOWN` / `CONFLICT`

لا يجوز ملء الفراغ بالتخمين.

## Required map

1. Inventory entities
2. Inventory tables
3. Inventory quantities
4. Inventory locations
5. Inventory movements
6. Inventory writers
7. Inventory readers
8. Business events
9. State transitions
10. Sales relationship
11. Purchasing relationship
12. Returns relationship
13. Warehouse relationship
14. Van Sales relationship
15. Loading
16. Unloading
17. Runsheet
18. Counting
19. Adjustments
20. Accounting / COGS
21. Edge Functions
22. Application consumers
23. Source-of-truth matrix
24. Contradictions
25. Unknowns
26. Risks
27. Migration constraints
28. INV-002 entry gate

## Critical quantity rule

The project architecture references a six-quantity model. The meaning of each quantity must be proven from the current system; no name or meaning may be invented from memory.

## Inventory writers

Every Function, Trigger, RPC, direct SQL path, or application write that changes inventory state must be mapped with:

`Writer / Type / Tables / Columns / Operation / Caller / Business Event / Confidence`

## Inventory readers

Every Edge Function, PWA, report, RPC, view, dashboard, accounting function, ledger function, warehouse screen, sales screen, purchasing screen, delivery screen and related consumer must be mapped only when evidence proves the relationship.

## Van Sales

The real path must be proven rather than assumed:

`Warehouse → Loading → Van Inventory → Field Sale → Return → Unloading`

For each transition record Writer, Source, Destination, Quantity and Reference.

## Accounting

Determine whether Inventory directly posts accounting or whether Accounting consumes Inventory events. Do not invent the target model during reality mapping.

## Security

Map RLS, company isolation, branch isolation, roles, service-role access and privileged Edge Function writes. Do not rewrite security during this mapping sprint.

## Auditability

Determine whether inventory changes can be traced to WHO / WHEN / WHAT / WHY / REFERENCE / BEFORE / AFTER. Gaps are recorded; they are not automatically repaired here.

## Prohibited during INV-001

- Inventory rewrite
- Schema redesign
- Table deletion
- Function deletion
- RLS changes
- broad migration
- Business Rule changes
- Accounting redesign
- Sales redesign
- Van Sales redesign

## Exit gate

INV-001 is complete only when the Inventory entities, tables, quantities, locations, movements, writers, readers, Edge Functions, consumers, domain relationships, source-of-truth matrix, contradictions, unknowns, security boundaries and critical risks are mapped with evidence.

## INV-002 entry

Do not proceed until we can answer with evidence:

1. Where is the current inventory truth?
2. Who can change it?
3. Which events change it?
4. Which systems depend on it?
