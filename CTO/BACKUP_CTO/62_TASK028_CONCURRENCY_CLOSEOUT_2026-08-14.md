# TASK-028 — TRUE TWO-SESSION CONCURRENCY CLOSEOUT

Date: 2026-08-14
Branch: `task-028-loading-unloading-refactor`
PR: `#3`
Environment: `rawaea-staging` (`hfzznsiprnwkpayskzhu`)

## Result

**TRUE TWO-SESSION CONCURRENCY = PASS**

The previous single-session limitation was removed by using the staging PostgreSQL scheduler (`pg_cron`) only as a controlled test harness. Two independent scheduled database workers invoked the actual `complete_runsheet_loading(...)` capability against the same Runsheet at the same scheduled instant.

## Evidence

### Run
- Worker A start: `2026-08-14 05:53:00.078114+00`
- Worker B start: `2026-08-14 05:53:00.078108+00`
- Start delta: approximately `6 microseconds`.

### Outcomes
- Worker A: `success=true`, `loaded_total=10`.
- Worker B: rejected with `invalid Loading context` after the winning transaction completed.
- Physical inventory log count for the Loading event: `1`.
- Final MAIN: `qty=0`, `allocated_qty=0`.
- Final VAN: `qty=10`.
- Final `order_details.qty_loaded=10`.
- Final Runsheet state: `Loaded`.

## Interpretation

This is a genuine two-worker database execution, not a sequential replay. The result proves that concurrent calls cannot produce two physical Loading effects for the same Runsheet lifecycle state.

The losing request is rejected by the transactional Runsheet lock/state boundary, while the winning request produces exactly one stock movement and one inventory event.

## Test Harness Cleanup

The concurrency probe used staging-only `pg_cron`, a staging-only helper function, and an isolated fixture. After evidence collection:

- both cron jobs were unscheduled;
- the helper functions were dropped;
- the probe table was removed;
- `pg_cron` was removed from staging;
- the synthetic Runsheet/order/item/vehicle/stock/log/backorder fixture was removed.

No Production test data was created or mutated by this concurrency experiment.

## Gate

`TASK-028 P0 concurrency gate = CLOSED`.

This record does not by itself grant `100% RELEASE-COMPLETE`; the remaining release gates are tracked separately.