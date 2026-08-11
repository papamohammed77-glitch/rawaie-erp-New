# RAWAEA ERP — CENTRAL CTO EXECUTION LOG

## Purpose
Mandatory chronological record of tasks, evidence, decisions, tests, gates, and unresolved conflicts.

## Control rule
No task is considered complete unless its evidence, decision, implementation status, test status, rollback status, and gate are recorded here or in a linked durable task report.

---

## TASK-004 — Production RPC Contract / Manual Voucher Send Path

**Status:** IN PROGRESS — NO GO

### Confirmed evidence captured
- `create_manual_stock_voucher_atomic(uuid,text,text,text,uuid,text,uuid,text,text,jsonb)` is `SECURITY DEFINER` and creates a `Draft` Manual Voucher.
- `complete_manual_stock_voucher_atomic(uuid,text,text)` is `SECURITY DEFINER` and transitions `Sent` → `Completed` for `DirectSale`/`SupplierReturn`, and `Received` → `Completed` for `Transfer`/`DirectReturn`.
- COMPLETE writes `completed_by` and `completed_at`.
- A real test fixture was created inside a transaction:
  - company `da4ef704-88ac-4120-aa0e-65b92b2aa2bc`
  - source `BR-01` / `151e5cd7-ac4a-4fc3-b703-d73a0dbb0dc6`
  - target `BR-2` / `a08568e5-40a7-4b15-85b4-ced8ebf9971d`
  - item `1004` / `ef864b14-ec62-4b9f-9932-17da041b6e42`
  - quantity `1`
  - generated voucher `IN-1`
  - voucher id `4062e2c6-f683-4a9c-bdc9-89705dbc7a7e`
- The captured Production RPC inventory paths include BOTH:
  - `send_stock_voucher_atomic(uuid,text,text)`
  - `post_manual_stock_voucher_atomic(uuid,text,text,text,jsonb)` with `SEND` / `RECEIVE` operations.
- Current status evidence states the current SEND Edge Function calls `send_stock_voucher_atomic`; therefore `post_manual_stock_voucher_atomic` cannot be assumed to be the sole current consumer.

### Newly discovered conflict
Two Production RPC implementations can perform the SEND business operation. Their existence alone does not establish which one is the authoritative Production consumer for Manual Vouchers.

### Gate decision
**STOP before STAGE-2 SEND execution.**

Reason: executing either RPC without establishing the actual consumer path would risk testing the wrong engine and could create misleading evidence about the real Production behavior.

### Required reconciliation
1. Identify all current consumers of `send_stock_voucher_atomic`.
2. Identify all current consumers of `post_manual_stock_voucher_atomic`.
3. Determine whether both are live, whether one is legacy, or whether they serve different workflows.
4. Compare their signatures, status transitions, stock mutations, inventory-log writes, and error/locking behavior.
5. Compare current Edge Function/UI call paths with the Production RPC evidence.
6. Only then select the RPC to test as the authoritative current Manual Voucher SEND path.

### Current test state
Transaction containing fixture `IN-1` remains intentionally uncommitted pending continuation/rollback of the controlled test.

### No production patch approved
None.
