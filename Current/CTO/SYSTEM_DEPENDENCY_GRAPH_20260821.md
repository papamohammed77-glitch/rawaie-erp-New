# RAWAEA ERP — SYSTEM DEPENDENCY GRAPH
## Evidence-based baseline — 2026-08-21

This graph records the relationships currently proven or partially proven. An incomplete edge must remain labeled as such.

## 1. Identity / Security
```text
Auth Session
  ↓
auth.users.id
  ↓
public.users.auth_id
  ↓
public.users.id
  ↓
public.users.company_id
  ↓
Role / Permission
  ↓
Application Gate / Edge Auth
  ↓
Domain RPC
  ↓
Target company-scoped rows
```

Known: Production RLS on core tables uses company context helpers on reviewed policies. Exact role/permission semantics remain incomplete ERP-wide.

## 2. Inventory / Voucher
```text
Voucher / Purchase / Sales / Loading / Unloading / Return
  ↓
Domain Edge/API
  ↓
Domain RPC
  ↓
post_stock_movement(10)
  ↓
stock_branches.qty
  +
 inventory_log
```

Reservation path:
```text
Picking
  ↓
reserve_stock
  ↓
stock_branches.allocated_qty
  ↓
release_stock_reservation (on valid release/reopen/cancel paths)
```

## 3. Fulfillment
```text
orders
  ↓
order_details [authoritative fulfillment detail]
  ↓
runsheets
  ↓
Picking
  ↓
Reservation
  ↓
Loading MAIN→VAN
  ↓
Delivery / Van Sales / Return
  ↓
Unloading VAN→MAIN where applicable
```

Current Production contains dedicated RPCs for runsheet creation, picking, loading, delivery, return and unloading. The complete cross-domain state/consumer graph is still OPEN.

## 4. Accounting
```text
Business Event
  ↓
Journal Authority (OPEN)
  ↓
journal_entries
  ↓
journal_lines
  ↓
Financial balances / reports
```

Current Production contains chart_of_accounts (87 rows), journal_entries (2 rows), journal_lines (0 rows). No current public PostgreSQL function was discovered in the direct writer sweep that inserts/updates the journal tables. Ownership therefore remains OPEN and must be traced through Edge/application consumers before any redesign.

## 5. Ledgers / Treasury / Settlement
```text
Financial / Operational Event
  ├──> customer_ledger
  ├──> supplier_ledger
  ├──> driver_ledger
  ├──> treasury
  └──> daily_settlements
```

Current row counts are 0 for customer/supplier/driver ledgers and daily_settlements, and 1 for treasury. A complete writer/ownership/reconciliation graph is OPEN.

## 6. Audit
```text
Mutating Table
  ↓
Audit Trigger / Audit Function
  ↓
audit_log
```

Reviewed current Production triggers include audit paths for orders, order_details and stock_vouchers. Full audit coverage across all critical domains remains OPEN.

## 7. Deployment / Continuity
```text
Current Git Commit
  ↓
Source Artifact
  ↓
Deployment Artifact
  ↓
Edge/PWA Runtime
  ↓
Production DB/RPC
  ↓
Runtime Evidence / Logs
```

Production versions are known for current Edge inventory. Complete commit→artifact→deploy→runtime lineage for every critical component remains OPEN.

## 8. Required next graph expansions
1. Accounting event graph.
2. Ledger/Treasury/Settlement event graph.
3. Complete order→fulfillment state machine graph.
4. Critical Consumer map.
5. Full authorization graph.
6. Deployment lineage graph.
7. Data provenance/repair graph.
8. Concurrency-sensitive edges.
