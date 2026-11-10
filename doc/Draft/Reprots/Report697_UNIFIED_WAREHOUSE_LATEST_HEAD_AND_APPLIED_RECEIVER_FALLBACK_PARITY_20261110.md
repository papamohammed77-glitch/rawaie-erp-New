# Report697 — تثبيت HEAD 76a80d ومطابقة Migration fallback المنشورة

**Recorded:** 2026-11-10 (Africa/Cairo)  
**Previous checkpoints:** LVE-2026-11-10-696 / Report696  
**Disposition:** Source and migration registry reconciled; current Warehouse E2E run still in progress at verification time.

## 1. Current operational repository

- Repository: papamohammed77-glitch/erp-frontend, branch main.
- Current HEAD at verification: 76a80dfa1437f5a51a8f076f963c9328d8b1aa29, message test(warehouse): verify unified-role standard transfer receiver fallback, timestamp 2026-11-10T21:33:13Z.
- HEAD advanced two commits after 92fc447. The latest commit changes only .github/workflows/warehouse_hub_browser_e2e_20261110.yml; it adds a static contract check and a Playwright assertion for مخزن شامل as the designated standard-transfer receiver.
- warehouse.html remains blob 31c4f1ae903b389269a4b90afdf310784f77f194. picker.html remains blob a94e18f1c7b2de5dad912011bb32999611976b8e. The latest commits did not change these operational UI files.

## 2. Latest workflow state

- Latest Warehouse run 42906160386 is on HEAD 76a80d and was still in_progress at the time of this report.
- Job 130144570312 / standalone-warehouse had completed source-contract validation successfully and was starting the local source server; Playwright browser stage was pending.
- Do not call this latest run PASS until its final conclusion is read. The preceding run 42905190791 on 92fc447 completed PASS, but it did not include the newest full-role standard-transfer receiver UI assertion.
- Existing harness remains mocked Supabase/auth. Even a passing browser stage proves UI contract only, not actual production receipt execution.

## 3. Reconciled designated-receiver migrations

Two Git migrations and two matching live history entries exist:

| Purpose | Git file | SMART ERP migration history |
|---|---|---|
| Standard designated receiver baseline | 20261110222000_standard_transfer_requires_designated_branch_receiver.sql | Earlier applied version 20261110212138, name standard_transfer_requires_designated_branch_receiver_20261110 |
| Unified-role receiver fallback | 20261110213226_standard_transfer_unified_warehouse_receiver_fallback.sql | Applied version 20261110213226, name standard_transfer_unified_warehouse_receiver_fallback |

The enabled trigger is public.stock_vouchers.trg_transfer_responsibility_contract (BEFORE DELETE OR UPDATE).

### Live function comparison

Live pg_get_functiondef(public.enforce_transfer_responsibility_contract()) is 14,754 characters / 416 lines. The Git function block from 20261110213226_standard_transfer_unified_warehouse_receiver_fallback.sql is 14,755 characters / 421 migration-file lines. The function body is identical; the only normalized diff is the terminal semicolon after $function$ (pg_get_functiondef omits the final SQL statement terminator).

That applied/live definition includes receiver_candidates, eligible_voucher_role_receivers, and eligible_full_role_receivers. It prioritizes an eligible exact أذونات home-branch receiver; only if none exists does it fall back to eligible مخزن شامل candidates constrained by destination/home branch or single allowed branch. The selected receiver is deterministic by user id.

### Pending narrower migration risk

The additional Git file 20261110222000_standard_transfer_requires_designated_branch_receiver.sql is not present as an applied migration version in SMART ERP. Its function block is the earlier, narrower form: it counts and selects only exact-role أذونات users and does not retain the full-role fallback. Because its timestamp sorts after 20261110213226, applying all pending migrations from Git could overwrite the correct live function and remove the fallback.

**Required control:** retain the applied 20261110213226 source as the authoritative implementation; do not apply the pending 20261110222000 file as-is. Reconcile/retire the stale pending file in a separate source/governance change before any future migration push. No database migration was run in this audit.

## 4. Loading fixes now tracked

On the commits immediately before this checkpoint, current Git gained tracked Edge sources:
- cancel-loading/index.ts blob fec7145558f0393da7edb08785e3157949ce147e
- reopen-loading/index.ts blob 86bcd8982ad3d7abfd3665180331245c784216be

Both files use requireWarehouseRole and assertWarehouseMainBranch and enforce company-specific run sheet state plus loader_id assignment before invoking the existing SQL RPC. This resolves the previously noted wrapper inconsistency. Their business stock/RPC implementation was not altered in this audit.

## 5. Unified warehouse findings still open

- Embedded Picker remains at parity with standalone picker.html (26 shared methods; no method missing).
- cancel-picking v5 and reopen-picking v9 still require exact active role تحضير. Embedded Picker permits مخزن شامل and exposes these actions. Their service-role SQL RPCs enforce same company/auth identity, picker assignment, status and reservation semantics. The Edge role/branch guards need a reviewed surgical change.
- cancel-return v4 still denies مخزن شامل despite start/complete Returns accepting it. Preserve assigned handler, company, Returning status and return_end IS NULL guards when fixing the role/branch predicate.
- reopen-return v1 remains unsafe: raw stock_branches.qty decrement, no inventory_log movement, no reversal of posted sales-return journal/customer/POS/credit-note effects, no adequate company/idempotency/transaction guard. Keep it blocked pending a complete atomic reversal design.
- Legacy reopen-receiving v1 remains dormant in current receiver.html (which uses receive-purchase v18) but exposes a raw stock decrement without corresponding inventory_log/purchase AP reversal. Containment is still required before any client uses it.
- Parent navigation is already linked; there is no reason to rebuild the warehouse shell or alter the Picker bundle.

## 6. Execution boundaries

- Read-only Git/Supabase inspection only. No operational UI/Edge source patch, SQL, migration, ACL/RLS change, deployment, business-data mutation, user/role change, or test fixture was created.
- No Supabase branch or paid test environment was created.
- Cloudflare deployment of current HEAD 76a80d remains unverified; previous visible Production snapshot was behind the inspected HEAD.

## 7. Current acceptance

**CONFIRMED:** main HEAD 76a80d; warehouse and Picker blobs unchanged; receiver fallback migration 20261110213226 is applied and its live function matches the tracked source; later 10222000 file is not applied and is narrower; loading cancel/reopen guards are now tracked; previous Warehouse E2E run 42905190791 passed.

**PENDING:** final conclusion of Warehouse run 42906160386; Cloudflare parity; authenticated production E2E; Picker cancel/reopen full-role alignment; Returns cancel full-role alignment; fail-closed completed-return and legacy-receiving reopen; stale 10222000 migration retirement/reconciliation.

**Do not mark Warehouse fully released or Gold/Diamond until all blockers have closure evidence.**

Operational HEAD: 76a80dfa1437f5a51a8f076f963c9328d8b1aa29  
Warehouse blob: 31c4f1ae903b389269a4b90afdf310784f77f194  
Picker blob: a94e18f1c7b2de5dad912011bb32999611976b8e  
Latest run: 42906160386 (in_progress at report time)  
Applied fallback migration: 20261110213226