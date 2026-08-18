# RAWAEA ERP — Prompt 4 Current Reality + Complete Picking Closure

Date: 2026-08-18
Execution basis: Production-first reconciliation

## Evaluation source
- Prompt 3 evaluation: `doc/Draft/Hussin/تقييم تقرير برومبت 3`
- Prompt 4 directive: `doc/Draft/Hussin/برومبت 4`

## Current Production Reality observed in this cycle
- start-picking: v33
- complete-picking: v15
- send-stock-voucher: v19
- receive-stock-voucher: v21
- complete-loading: v11
- complete-return: v23
- unload-runsheet: v6
- save-sales-invoice: v14
- bulk-stock-adjustment: v5
- setup-van-branch: v3

Production timestamp observed from PostgreSQL: 2026-08-18 17:04:55+00.

## Source reconciliation — complete-picking
Current: `Current/Edge_Functions/complete-picking`, SHA `10d759008a3a829789d882736efece5a158f2b1f`.
Original: `Original/Edge Functions/complete-picking.ts`, SHA `c981efef28e9c3e65a0729400f648bbff857a21c`.

Current Edge adapter is thin: authentication -> public user/company resolution -> `complete_runsheet_picking` RPC. It does not directly update stock or inventory_log.

Original implementation directly wrote a Picking inventory_log row, mutated runsheet state from the Edge layer, and called reservation behavior outside a single transactional DB boundary. That responsibility has moved into the current transactional Core.

## Current Core contract verified in Production
`complete_runsheet_picking(uuid,text,text,jsonb)` is SECURITY DEFINER and:
- validates company, picker, main branch, runsheet state, and picker ownership
- locks the runsheet row
- aggregates incoming item codes
- validates authoritative item identity
- validates picked quantity against ordered quantity
- calls `reserve_stock` only
- distributes `qty_picked` into order_details
- relies on the DB trigger `sync_run_sheet_details` for derived run_sheet_details aggregation
- transitions runsheet to Picked
- does not call `post_stock_movement`
- returns `inventory_log_written=false`

Production trigger `trg_sync_run_sheet_details` maintains run_sheet_details from authoritative order_details.

## Production data integrity checks
- negative stock qty: 0
- negative allocated qty: 0
- allocated_qty > qty: 0
- authoritative runsheet+item aggregation mismatch between order_details and run_sheet_details: 0
- current main-branch reservation coverage for picked quantities: 0 mismatches
- current inventory_log Picking movement rows: 0
- current picked runsheets: 1

The initial reservation query was corrected after the branch code assumption was disproved; the real configured main branch is `app_settings.main_branch_id` with branch_code `BR-01`.

## Parallel writer sweep
Production contains three functions matching direct stock table writes:
- `post_stock_movement`
- `reserve_stock`
- `release_stock_reservation`

These are the canonical central movement/reservation engines, not independent legacy writers. No additional parallel physical stock engine was identified in this sweep.

## HTTP E2E gate
A controlled Production HTTP harness was deployed as:
`complete-picking-runtime-e2e-20260818` v1.

The harness:
1. creates a temporary Auth user through Supabase Admin
2. creates a temporary public picker identity
3. creates a temporary runsheet/order/detail fixture
4. obtains a real Auth access token
5. calls the live `complete-picking` endpoint over HTTP
6. verifies Picked state, qty_picked, run_sheet_details, reservation increase, and absence of Picking inventory_log
7. retries the same HTTP request and requires rejection without a second side effect
8. releases the reservation
9. verifies exact stock baseline restoration
10. deletes all temporary Auth/public/fixture objects

A temporary GitHub workflow was added to execute this harness against Production. The workflow is intentionally temporary and must be removed after the gate result is recorded.

## Closure rule
No 100% Closure is recorded here until the Production HTTP gate itself returns success and baseline restoration is independently verified from the gate output.
