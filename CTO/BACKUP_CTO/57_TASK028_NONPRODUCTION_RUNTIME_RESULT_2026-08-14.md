# 57 — TASK-028 NON-PRODUCTION RUNTIME RESULT

## STATUS
`RUNTIME VERIFIED — PARTIAL MATRIX PASS`

## ENVIRONMENT
`rawaea-staging` Supabase project: `hfzznsiprnwkpayskzhu`.
Production project `SMART ERP` was not modified.

## PASSING TESTS
| Test | Result | Evidence |
|---|---|---|
| Full Loading 10 | PASS | MAIN 100→90, allocated 10→0, VAN 0→10, Runsheet Loaded |
| Reopen Loading | PASS | MAIN 90→100, allocated 0→10, VAN 10→0, Runsheet Loading, `qty_loaded=10` preserved |
| Reopen Retry | PASS | second same `operation_id` produced no second reversal; one event log |
| Reopen→Reload Partial 6 | PASS | MAIN 100→94, allocated 10→4, VAN 0→6, `qty_loaded=6`, backorder 4 |
| Unloading inverse | PASS | MAIN 94→100, allocated 4→10, VAN 6→0, Runsheet Picked, `qty_loaded=0` |
| Repeated Unloading | PASS | rejected by Loaded-state gate; no additional stock/log effect |
| Insufficient MAIN | PASS | rejected; MAIN remained 100 / allocated 10 |
| Loaded > Picked | PASS | rejected; no stock/order mutation |
| Missing VAN | PASS | rejected; MAIN remained unchanged |
| Failure rollback | PASS | multi-item Loading failure rolled back earlier stock/order/log effects; baseline restored |
| Generated availability | PASS | `available_qty` is generated `qty - allocated_qty` |
| Accounting boundary | PASS | zero journal entries created by Loading/Reopen/Unloading |
| Trigger consistency | PASS | `order_details.qty_loaded` update was reflected in `run_sheet_details.qty_loaded` by `sync_run_sheet_details()` |
| Backorder lifecycle | PASS | partial reload created Pending remainder 4; Unloading cancelled it |

## IMPORTANT LIMITATION
True two-session concurrent execution was **not executed** in this gate because the available database execution interface provides a single execution session. Therefore `CONCURRENT REOPEN/LOADING = NOT VERIFIED`, not PASS.

## OBSERVED STAGING PARITY ISSUE
The staging database initially lacked UUID defaults on `run_sheet_details.id` and `inventory_log.id`, despite the Production schema using generated UUID identifiers. Both were corrected only in staging so the test environment could faithfully execute the Current target.

## PRODUCTION GATE
No Production deployment or Production mutation occurred.
