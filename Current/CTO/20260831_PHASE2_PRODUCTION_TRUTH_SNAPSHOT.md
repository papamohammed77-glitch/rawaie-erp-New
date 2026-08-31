# RAWAEA ERP — PHASE 2 PRODUCTION TRUTH SNAPSHOT

**Date:** 2026-08-31  
**Phase:** 2 — Production Now Snapshot  
**Status:** CLOSED  
**Production Project:** `fiilmooggumokxanwiyx` (`SMART ERP`)  
**Snapshot window (UTC):** `2026-08-31T08:42:02.596349Z` → `2026-08-31T08:43:01.892536Z`  
**Current Git head observed during Phase 2:** `484d92ed2fb940386f6ba450cfc08fd1fd91babf`

## Scope

This is a fresh read-only Production snapshot. No Production DDL, DML, Edge deployment, or business-data mutation was performed during Phase 2.

Because multiple independent read queries were required, the snapshot uses a clearly declared UTC window and records each sub-snapshot timestamp. No value from an older report is represented as the current Production value.

## PRODUCTION ENVIRONMENT

- Supabase project: `SMART ERP`
- Project ref: `fiilmooggumokxanwiyx`
- Status: `ACTIVE_HEALTHY`
- Region: `eu-west-1`
- PostgreSQL: 17
- Separate Supabase project observed: `rawaea-staging` / `hfzznsiprnwkpayskzhu`; not treated as Production.

## STRUCTURAL SNAPSHOT

At `2026-08-31T08:42:02.596349Z`:

| Metric | Current Production |
|---|---:|
| Public base tables | 66 |
| Public views | 0 |
| Public functions | 76 |
| Public user triggers | 20 |
| Public policies | 110 |
| Public indexes | 173 |
| Public constraints | 488 |
| Public role-table grant rows | 1582 |
| Applied migrations | 198 |
| Latest migration | `20260830082911` |

## BUSINESS DATA SNAPSHOT

At `2026-08-31T08:42:06.616214Z`:

| Entity | Rows |
|---|---:|
| companies | 1 |
| users | 24 |
| branches | 2 |
| items | 17 |
| customers | 3 |
| suppliers | 1 |
| vehicles | 0 |
| orders | 0 |
| order_details | 0 |
| runsheets | 0 |
| run_sheet_details | 0 |
| stock_branches | 20 |
| inventory_log | 3 |
| stock_vouchers | 0 |
| stock_voucher_details | 0 |
| purchase_orders | 0 |
| purchase_order_details | 0 |
| journal_entries | 2 |
| journal_lines | 0 |
| customer_ledger | 0 |
| supplier_ledger | 0 |
| driver_ledger | 0 |
| treasury | 1 |
| daily_settlements | 0 |
| audit_log | 1866 |

## CRITICAL DATABASE CONTRACT SURFACE

At `2026-08-31T08:42:11.208809Z`:

### Physical stock / reservation capabilities

- `post_stock_movement(...)` exists in **two overloads**; one overload includes `p_idempotency_key text`.
- `reserve_stock(...)` exists.
- `release_stock_reservation(...)` exists.
- `create_manual_stock_voucher_atomic(...)` exists in **two overloads**.
- `post_manual_stock_voucher_atomic(...)` exists.
- `send_stock_voucher_atomic(...)` exists.
- `receive_purchase_atomic(...)` exists.
- These functions return the observed production result types recorded by the database catalog; this phase does not infer business ownership beyond existence/signature.

### Public trigger surface observed

Relevant current triggers include audit triggers across operational/financial tables, `trg_sync_run_sheet_details` on `order_details`, and vehicle/branch context-guard triggers. Full trigger inventory remains a Phase 7/8 investigation artifact rather than a Phase 2 interpretation.

## SECURITY / RLS SNAPSHOT

At `2026-08-31T08:42:20.048089Z`:

- All 25 required business tables inspected in the Phase 2 query have RLS enabled.
- None of those tables has `FORCE ROW LEVEL SECURITY` enabled.
- Policy counts observed include: companies 1, users 4, branches 4, items 4, customers 4, suppliers 4, orders 3, stock_branches 1, inventory_log 1, stock_vouchers 1, journal_entries 1, journal_lines 1, customer_ledger 1, supplier_ledger 1, driver_ledger 1, treasury 4, audit_log 1.
- `users` exposes both `auth_id` and `company_id`.
- `stock_branches` exposes `branch_id`, `item_id`, `qty`, `allocated_qty`, `available_qty`, but no direct `company_id` column.
- `customer_ledger`, `supplier_ledger`, and `driver_ledger` do not expose direct `company_id` columns in their current schemas and require relational/scoping analysis in later phases.

## CRITICAL GRANTS SNAPSHOT

At `2026-08-31T08:42:29.889445Z`:

- Critical writer RPCs observed in the catalog have `EXECUTE` granted to `service_role`; no `authenticated` or `anon` `EXECUTE` grant was returned for those writer RPCs.
- Critical financial/stock tables expose SELECT grants to authenticated/anon in several cases, while broad mutation privileges are held by `service_role`.
- This is a current privilege fact, not a security verdict; policy semantics and actual call paths remain later-phase work.

## INTEGRITY RECONCILIATION SNAPSHOT

At `2026-08-31T08:43:01.892536Z`:

### Clean checks

- Duplicate `(company_id,item_code)` groups: 0
- Negative stock rows: 0
- `available_qty != qty - allocated_qty`: 0
- Cross-company stock rows by branch/item company comparison: 0
- Inventory-log item/company mismatches: 0
- Orphan order details: 0
- Order-detail item/company mismatches: 0
- Orders pointing to a non-matching company runsheet: 0
- Orphan run-sheet details: 0
- Orphan voucher details: 0
- Voucher-detail item/company mismatches: 0
- Orphan purchase-order details: 0
- Purchase-detail item/company mismatches: 0
- Journal lines without headers: 0
- Customer-ledger orphan references: 0
- Supplier-ledger orphan references: 0
- Duplicate non-null user `auth_id`: 0

### Current anomalies requiring later provenance analysis

- `users.auth_id IS NULL`: **1 row**. This is an observed data condition, not classified as a defect in Phase 2.
- `journal_entries` without any `journal_lines`: **2 rows**. This is an observed accounting condition, not repaired or numerically synthesized in Phase 2.

No data repair was attempted because the Master CTO Protocol explicitly requires provenance, impact analysis, repair design, rollback and audit before Production data changes.

## RUNTIME SNAPSHOT

### Edge Function runtime

Direct current deployment inventory contains the active canonical business functions and numerous historical/test/canary functions. Current deployed versions and SHA-256 artifacts are observable directly from Supabase.

### Live runtime evidence

The Edge Function logs show repeated HTTP **410** calls to historical/test-style functions, including:

- `auth-login-verification-20260818`
- `complete-picking-picker-http-gate-20260818`
- `owner-recovery-20260818`

The most recent observed calls are around `2026-08-31T08:42:11Z`.

This proves those endpoints are being requested and returning 410. It does **not** yet prove that they are active production consumers or that the product's primary workflow is broken; consumer attribution is deferred to the System Graph / Deployment Lineage phases.

### API / Auth logs

The direct Supabase API and Auth log queries for the current window returned no rows in the connector response.

### PostgreSQL logs

The recent PostgreSQL log feed contains several ERROR records associated with investigation/query activity, including invalid column/function/aggregate references. These are recorded as runtime evidence only and are not treated as application defects without consumer/provenance correlation.

## FRESHNESS / DRIFT WARNING

`CURRENT_STATE.md` and prior baseline artifacts contain earlier Git/Production timestamps and must not supersede this fresh snapshot. During Phase 2, the current Git head advanced again to `484d92ed2fb940386f6ba450cfc08fd1fd91babf`; therefore the repository is demonstrably moving while this investigation is occurring.

## PRODUCTION TRUTH STATUS

### Proven now

- Current Production environment identified as `SMART ERP` / `fiilmooggumokxanwiyx`.
- Fresh structural inventory captured.
- Fresh business-row counts captured.
- Critical RPC/function signatures observed.
- RLS and policy counts captured.
- Critical grants captured.
- Fresh relational integrity checks captured.
- Current runtime observations captured.

### Not proven yet

- Historical intent of every current behavior.
- Complete active-consumer graph.
- Complete Git-to-Production deployment lineage.
- Full physical-stock writer matrix.
- Full accounting/ledger writer matrix.
- Full tenant/authorization behavior across every critical lookup.
- Browser/service-worker/runtime certification of New-main.

## EXIT GATE

`PHASE 2 CLOSED`

The required Fresh Production Snapshot has been completed and recorded with timestamps and evidence boundaries. No percentage-based readiness claim is made. No Production mutation occurred in this phase.
