# TASK-002 — INVENTORY DATA CONTRACT

## Objective
Freeze the factual Production contract for `stock_branches`, `inventory_log`, `allocated_qty`, and their constraints/indexes/relations before any implementation change.

## Evidence Reviewed
- `SQL_Evidence/diagnostics/1-Exact table columns + defaults + generated expressions.csv`
- `SQL_Evidence/diagnostics/2-Primary keys  unique constraints  check constraints  FKs.csv`
- `SQL_Evidence/diagnostics/3-Index definitions — exact Production definitions.csv`
- `SQL_Evidence/diagnostics/4-Foreign-key dependencies in both directions.csv`
- `SQL_Evidence/diagnostics/5-Triggers on the InventoryVoucher tables.csv`
- `SQL_Evidence/diagnostics/6-RLS status + policies.csv`
- `SQL_Evidence/diagnostics/7-Views  rules  dependencies referencing Inventory Core.md`
- `SQL_Evidence/diagnostics/8-FunctionsRPCs whose stored source references Inventory Core.csv`
- `SQL_Evidence/diagnostics/10-Table row estimates — context only, NOT balances.csv`
- Prior Inventory/Voucher contracts and CTO truth-reconciliation documents.

## 1. `stock_branches`

### Production columns
`id, branch_id, item_id, qty, allocated_qty, available_qty, updated_at`. fileciteturn273file0

### Confirmed semantics
- `qty` = current physical stock balance for a branch/item row.
- `allocated_qty` = reserved/allocated quantity; it is not itself an inventory movement.
- `available_qty` is a **generated column** with the exact Production expression:
  `qty - allocated_qty`. fileciteturn273file0

### Production constraints
- Primary key: `stock_branches_pkey (id)`.
- Unique key: `(branch_id, item_id)`.
- `branch_id` FK → `branches(id)` with `ON DELETE CASCADE`.
- `item_id` FK → `items(id)` with `ON DELETE CASCADE`.
- `id`, `branch_id`, `item_id`, `qty`, `allocated_qty` are NOT NULL. fileciteturn274file0turn276file0

### Production indexes
- PK unique index on `id`.
- Unique index on `(branch_id, item_id)`.
- `idx_stock_branches_branch` on `branch_id`.
- `idx_stock_branches_item` on `item_id`. fileciteturn275file0

## 2. `inventory_log`

### Production columns
`id, company_id, log_code, movement_date, voucher_id, item_id, item_code, item_name, movement_type, qty, reference, user_email, created_at`. There is **no `branch_id` column** in the captured Production schema. fileciteturn273file0

### Confirmed semantics
`inventory_log` is the historical record of inventory movements. It is **not** the authoritative current balance.

### Production constraints
- Primary key: `inventory_log_pkey (id)`.
- `company_id` FK → `companies(id)` with `ON DELETE CASCADE`.
- `item_id` FK → `items(id)` with `ON DELETE RESTRICT`.
- Required NOT NULL columns include `id`, `company_id`, `log_code`, `movement_date`, `movement_type`, `qty`. fileciteturn274file0turn276file0

### Production indexes
- PK unique index on `id`.
- `idx_inventory_log_item` on `item_id`. fileciteturn275file0

### Important limitation
No Production CHECK/ENUM constraint restricting `movement_type` values was captured in this evidence. Therefore the allowed movement-type vocabulary remains an application/RPC contract question and is **not declared as a database-enforced fact**.

## 3. `allocated_qty`

`allocated_qty` is a column of `stock_branches` and represents reserved stock.

Therefore:

`allocated_qty ≠ inventory movement`

The current availability relationship is database-enforced through the generated `available_qty` expression:

`available_qty = qty - allocated_qty`. fileciteturn273file0

The stock movement engine must therefore not treat allocation as an automatic physical movement.

## 4. Source of Truth Matrix

| Value / Fact | Source of Truth | Status |
|---|---|---|
| Current physical stock by branch/item | `stock_branches.qty` | **PROVEN** |
| Reserved stock | `stock_branches.allocated_qty` | **PROVEN** |
| Available stock | generated `stock_branches.available_qty = qty - allocated_qty` | **PROVEN** |
| Historical inventory movement | `inventory_log` | **PROVEN** |
| Item identity | `items.id` referenced by `stock_branches.item_id` / `inventory_log.item_id` | **PROVEN** |
| Branch identity | `branches.id` referenced by `stock_branches.branch_id` | **PROVEN** |
| Branch/item uniqueness | `stock_branches(branch_id,item_id)` | **PROVEN** |
| Inventory movement classification | `inventory_log.movement_type` | **PROVEN column; DB allowed-values constraint NOT PROVEN** |

## 5. Related Voucher Contract Relevant to Inventory

The same Production evidence establishes:

- `stock_vouchers.company_id` → `companies.id` CASCADE.
- `stock_vouchers.from_branch_id` → `branches.id` SET NULL.
- `stock_vouchers.to_branch_id` → `branches.id` SET NULL.
- `stock_vouchers(company_id,voucher_code)` UNIQUE.
- `stock_voucher_details.voucher_id` → `stock_vouchers.id` CASCADE.
- `stock_voucher_details.item_id` → `items.id` RESTRICT. fileciteturn274file0turn276file0

These relationships are now sufficient for the Inventory Data Contract; Voucher lifecycle semantics remain TASK-003.

## 6. Triggers / RLS / Dependencies

### Trigger evidence
Production has an audit trigger on `stock_vouchers` for INSERT/UPDATE/DELETE calling `fn_audit_trigger()`. fileciteturn277file0

### RLS evidence
Policies exist on `inventory_log`, `stock_branches`, `stock_vouchers`, and `stock_voucher_details`; the captured policy set includes broad `Allow all for all` policies, plus additional `stock_branches` policies. fileciteturn278file0

The exact RLS enable/force flags were not present in the exported policy result itself; this does not block TASK-002 because RLS policy behavior is governed separately in the Security task.

### Dependency evidence
The captured dependency query returned no view/materialized-view dependencies for the Inventory Core tables. fileciteturn279file0

Stored Production functions/RPCs referencing the Inventory Core tables were captured in `8-FunctionsRPCs whose stored source references Inventory Core.csv`; these are inputs to TASK-004, not a reason to reopen the data contract. fileciteturn270file0

## 7. Row Counts

The evidence reports approximate statistics only:
- `inventory_log`: 137 estimated rows.
- `stock_branches`: 99 estimated rows.
- `stock_voucher_details`: 0 estimated rows.
- `stock_vouchers`: 0 estimated rows. fileciteturn280file0

These are **context only**, not authoritative inventory balances.

## 8. Safety Classification

**NO PATCH AUTHORIZED BY TASK-002.**

This task establishes the data contract only. It does not authorize schema changes, RPC replacement or application changes.

## Gate

**TASK-002 STATUS: COMPLETE / GO**

The previously blocking Production dependency closure has been sufficiently established for the requested Inventory Data Contract.

Residual items are deliberately assigned to later Tasks:
- movement-type enforcement → TASK-008
- Voucher lifecycle → TASK-003 / TASK-005
- RPC behavior → TASK-004
- concurrency/idempotency → TASK-010 / TASK-011
- RLS/security hardening → TASK-049

## Next Action
Proceed to **TASK-003 — Voucher Data Contract**.
