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
A controlled Production HTTP harness was deployed as `complete-picking-runtime-e2e-20260818` v1. It was designed to create a temporary Auth user, create a public picker fixture, call the live `complete-picking` endpoint with a real Auth access token, verify Picked/reservation/run_sheet_details/no-Picking-log, retry the HTTP call, release reservation, and prove exact baseline restoration.

A temporary GitHub workflow was added to execute the harness against Production. The available GitHub connector returned no workflow run or status for the triggering commits, so there is no verifiable HTTP gate result available from the execution infrastructure. No success claim is made.

The temporary workflow was removed from `main`. The temporary HTTP harness was retired to HTTP 410. Production contains zero residual P4 test users, Auth users, runsheets, or orders by the P4 test prefixes.

## Closure status
COMPLETE-PICKING Core / Static / Data Integrity: PASS.
Production HTTP E2E: NOT PROVEN in this cycle.

Therefore `complete-picking` is **NOT 100% CLOSED** under Prompt 4 because the required live HTTP gate has no verifiable execution result. No percentage is reported and no historical HTTP result is promoted to current truth.

## Next permitted Closure Unit
`complete-picking` remains the active closure unit until a legitimate Production HTTP runtime result is captured. Per Prompt 4 Zero-Debt Rule, `send-stock-voucher` and later units must not be promoted to 100% closure as a substitute.
