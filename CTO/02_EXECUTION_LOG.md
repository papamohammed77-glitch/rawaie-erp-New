# RAWAEA ERP — CENTRAL CTO EXECUTION LOG

## Purpose
Mandatory chronological record of tasks, evidence, decisions, tests, gates, and unresolved conflicts.

## Control rule
No task is considered complete unless its evidence, decision, implementation status, test status, rollback status, and gate are recorded here or in a linked durable task report.

---

## TASK-004 — Production RPC Contract / Manual Voucher Send Path

**Status:** IN PROGRESS — STAGE 4 NEXT

### Confirmed evidence captured
- `create_manual_stock_voucher_atomic(uuid,text,text,text,uuid,text,uuid,text,text,jsonb)` is `SECURITY DEFINER` and creates a `Draft` Manual Voucher.
- `complete_manual_stock_voucher_atomic(uuid,text,text)` is `SECURITY DEFINER` and transitions `Sent` → `Completed` for `DirectSale`/`SupplierReturn`, and `Received` → `Completed` for `Transfer`/`DirectReturn`.
- COMPLETE writes `completed_by` and `completed_at`.
- Production inventory RPC evidence includes both `send_stock_voucher_atomic(uuid,text,text)` and `post_manual_stock_voucher_atomic(uuid,text,text,text,jsonb)` with `SEND` / `RECEIVE` operations.
- The earlier transactional fixture `IN-1` (`4062e2c6-f683-4a9c-bdc9-89705dbc7a7e`) was confirmed absent after its transaction ended.
- A persistent fixture was then created outside `BEGIN/ROLLBACK`:
  - company `da4ef704-88ac-4120-aa0e-65b92b2aa2bc`
  - source `BR-01` / `151e5cd7-ac4a-4fc3-b703-d73a0dbb0dc6`
  - target `BR-2` / `a08568e5-40a7-4b15-85b4-ced8ebf9971d`
  - item `1004` / `ef864b14-ec62-4b9f-9932-17da041b6e42`
  - quantity `1`
  - voucher `IN-1`
  - voucher id `a0974ec8-a5d0-4339-a5fb-7d2d0cee1d64`
  - reference `TEST-004-PERSISTENT`
  - notes `TEST-004 PERSISTENT FIXTURE`

### STAGE 1 — CREATE
**Result: PASS**
- `create_manual_stock_voucher_atomic(...)` returned `success=true`.
- Persistent voucher `IN-1` was created successfully.

### STAGE 2 — SEND
**Result: PASS**
- `IN-1` transitioned to `Sent`.
- `sent_date` populated.
- BR-01 item 1004 `qty`: `206 → 205`.
- `allocated_qty`: remained `0`.
- `available_qty`: became `205`.
- Exactly one `inventory_log` row was recorded for `IN-1`, `DirectSale`, quantity `1`, user `test-operator@rawaea.local`.

### STAGE 3 — COMPLETE
**Result: PASS**
- Full verification returned `STAGE 3 PASS`.
- COMPLETE did not create an additional inventory-log row; total remained `1`.
- The tested lifecycle reached the expected completed state under the stage verification.

### Current Gate
Proceed immediately to **STAGE 4** for the next verification required by TEST-004.

### No production patch approved
None.
