# RAWAEA ERP — Global Inventory Core Integrity Sweep
**Date:** 2026-10-27  
**Execution mode:** Live Production inspection + targeted repair  
**Status:** INCOMPLETE — no 100% closure claim

## Executive self-audit
- Business understanding: strong for the inspected stock/voucher paths; not globally proven.
- Architecture understanding: `post_stock_movement` is the central physical movement contract in the inspected current cores.
- Production understanding: directly inspected live PostgreSQL definitions, grants, Edge Function deployments and migration registry during this run.
- Historical/current reconciliation: partial; full repository-wide consumer tracing and reproducible Git-to-deployment provenance are not closed.
- Execution confidence: high for the specific facts below; insufficient for global zero-debt.

## Confirmed live facts
1. Production has two `post_stock_movement` overloads:
   - 9 arguments: not executable by anon/authenticated/service_role at the time queried.
   - 10 arguments including `p_idempotency_key`: executable by service_role; this is the current central movement contract used by the inspected cores.
2. The following inspected cores call `post_stock_movement`: `post_manual_stock_voucher_atomic_core_20260828`, `send_stock_voucher_atomic_core_20260828`, `post_inventory_adjustment_atomic`, and the inspected loading/reopen paths.
3. Reservation functions `reserve_stock` and `release_stock_reservation` update `allocated_qty`; these are reservation paths, not physical stock movement engines.
4. `setup_van_stock` inserts missing `stock_branches` rows with qty=0 and allocated_qty=0. It is initialization, but its complete privilege/consumer contract still needs its own closure.
5. `items.item_code` has a global UNIQUE constraint in Production. This supports global item identity; company/branch authorization must still be enforced at the transaction boundary.
6. Live Edge inventory showed multiple active temporary E2E/harness functions returning 410 in logs. 410 proves inert response behavior, not deletion; registry removal is not established.
7. Live `receive_purchase` is ACTIVE v12, `verify_jwt=true`, and calls the five-argument `receive_purchase_atomic(uuid,text,text,jsonb,uuid)` with a deterministic/supplied operation identity.
8. Production also contains a four-argument `receive_purchase_atomic` compatibility overload that calls the five-argument function with a new random UUID. That compatibility path is not retry-idempotent if called directly; its caller inventory and deprecation/removal decision must be verified before changing it.
9. Production has `create_manual_stock_voucher_atomic` overloads (10 and 12 arguments), and the live `create-stock-voucher` Edge v12 supports both. Any change must preserve the 12-argument rep/operation contract and branch authorization.
10. Live schema confirms `stock_vouchers` uniqueness on (company_id,voucher_code), `stock_branches` uniqueness on (branch_id,item_id), and `items` uniqueness on item_code.

## Repairs performed in this run
- Applied Production migration `20260819014000_close_manual_voucher_create_tenant_and_item_identity` as recorded by Supabase migration registry. A transaction-scoped call to the 10-argument create RPC succeeded using a globally unique item whose item master company differs from the receiving company's metadata; the test transaction was rolled back.
- Applied Production migration entries related to receive-purchase compatibility/idempotency during the run. Subsequent live inspection confirmed the canonical five-argument RPC exists and is called by deployed `receive-purchase` v12. Because other later migrations and live definitions exist, the receive-purchase chain must be treated as reconciled only at the currently inspected endpoint, not as globally closed.
- Updated the GitHub file `Current/Edge_Functions/create-stock-voucher` during this run (commit returned: `f58a8ef6ead16a831d4261e1e25bb390fa5403dd`). A later live fetch returned a richer current file with create/update/delete and 10/12-argument RPC routing, indicating the repository artifact has since moved; the returned latest file must be used as the current source and this concurrent change must be reconciled before claiming parity.

## Outstanding items — must remain OPEN
- Complete full PostgreSQL physical-writer sweep, including dynamic SQL, triggers, table DML, and every overload.
- Confirm every writer candidate's exact body and classify it as central movement, reservation, initialization, orchestration, legacy, or unknown.
- Trace every PWA/HTML/JS consumer to Edge → RPC/Core → DB and record payload/response.
- Reconcile all current Edge versions, `verify_jwt`, deployed hashes, Git blob SHAs and commits at the same time.
- Investigate and close the 4-argument `receive_purchase_atomic` compatibility overload only after complete caller/dependency proof.
- Inspect/close `complete_return_atomic` and `complete_order_delivery_atomic` name drift against live PostgreSQL and actual current deployed consumers. The live Edge definitions inspected in this run call those RPC names; an earlier schema query returned no exact matching routines, so the name/overload state needs a fresh definitive reconciliation.
- Remove temporary harness registry objects only when deletion is actually performed and `NOT PRESENT` is confirmed.
- Run authenticated Production HTTP E2E for each closure unit, with normal/retry/duplicate/concurrent/failure cases and baseline restoration.

## Closure decision
**GLOBAL INVENTORY CORE INTEGRITY = INCOMPLETE.**  
Reason: the global writer/consumer/provenance/security/runtime sweep is not fully closed, and active temporary harnesses remain in the Production function registry. No 100% claim is made.

## Final self-audit
- What I proved: live central movement contract and grants for inspected functions; live global item-code uniqueness; live receive-purchase v12 identity contract; temporary harnesses remain registered; transactional create-RPC test succeeded and rolled back.
- What I did not prove: all physical writers outside the inspected set equal zero; complete consumer coverage; all Production functions have reproducible Git provenance; full authenticated HTTP E2E and concurrency closure for every writer.
- What I fixed: applied the recorded manual-voucher create migration and performed a rollback-safe transactional validation.
- What I initially missed: the repository and Production had newer manual-voucher contracts than the earlier file excerpt, including 12-argument create and update/delete behavior; this must be preserved.
- What could still be wrong: parallel changes, compatibility overloads, hidden/dynamic writers, RPC name drift, and runtime behavior not covered by the transactional SQL test.
- Final confidence: high for listed live facts, low-to-moderate for global completeness.
- Final closure status: INCOMPLETE — continue one Writer Closure Unit at a time.
