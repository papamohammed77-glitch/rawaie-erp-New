# RAWAEA ERP — CENTRAL CTO EXECUTION LOG

## Purpose
Mandatory chronological record of tasks, evidence, decisions, tests, gates, and unresolved conflicts.

## Control rule
No task is considered complete unless its evidence, decision, implementation status, test status, rollback status, and gate are recorded here or in a linked durable task report.

---

## CTO WORKING METHOD — CURRENT OPERATING STANDARD

### Execution rhythm
**One Stage = one coherent execution unit → one comprehensive verification → one decision → next Stage.**

Do not subdivide a Stage into artificial sub-stages merely to make an already-small task look smaller. Break a Stage only when real safety, evidence, concurrency, or dependency isolation requires it.

### Working principles
- No guessing.
- No repeating evidence already proven and still valid.
- Query the full evidence needed for the stage in one comprehensive pass whenever practical.
- Execute the stage as one coherent operation wherever safe.
- Verify the complete stage result in one comprehensive pass.
- Once proven, close the Stage and move forward immediately.
- Do not reopen closed work unless newer authoritative evidence contradicts it.
- Do not turn simple work into a documentation or analysis loop.
- Decompose only genuine complexity; never decompose for its own sake.
- Optimize for measurable progress toward implementation, validation, and release.

### Constitutional principles carried forward
1. Do not diagnose critical findings in isolation; reconcile architecture, security, authorization, source-of-truth, workflow, Production schema evidence, equivalent functions/apps, and historical warnings.
2. Broad RLS is an observed fact, not proof of a defect by itself.
3. Authentication is not authorization; business-operation authorization and database integrity are separate controls.
4. Target-required business operations must be atomic.
5. One business fact must have one authoritative source of truth and one authoritative movement history.
6. Inventory mutations converge on one central controlled business engine; adapters are not competing business engines.
7. Applications are operational event sources, not autonomous business systems or databases.
8. Preserve the current V1 one-company/multi-branch architecture unless an explicit Target decision changes it.
9. Repair the smallest coherent boundary; do not reopen unrelated domains.
10. No critical code change before Target reconciliation against Original, Current, schema evidence, equivalent functions, and Architecture.
11. Evidence classification remains explicit: PROVEN / STATIC ONLY / KNOWN-REVIEW / UNKNOWN / TARGET DECISION REQUIRED.
12. Documentation must support decisions and safe execution, never replace measurable progress.
13. Production Schema + Persisted Evidence + Actual Deployed Definitions outrank assumptions, names, migrations, and historical code.
14. Important Production read-only evidence is persisted so the same diagnostic is not repeatedly requested.
15. Lifecycle responsibility is explicit: state, physical stock, history, audit, and administrative closure must not be duplicated across stages.
16. Treat the validation database as production infrastructure; use controlled test data and avoid unnecessary contamination.
17. Protect the business first, simplify operational work second, and never achieve one by sacrificing the other.
18. A task is not considered Production-implemented merely because a report, migration, or candidate file exists in GitHub; executable changes require actual target-system execution and direct verification.
19. Contract/evidence tasks are closed from authoritative Production evidence; implementation/test tasks are closed only from actual execution evidence.
20. Every execution stage must be verified against the actual target system; repository artifacts alone never establish Production implementation.

---

## TASK-004 — Production RPC Contract / Manual Voucher Send Path
**Status: COMPLETE — GO TO TASK-005**

### Confirmed evidence captured
- `create_manual_stock_voucher_atomic(uuid,text,text,text,uuid,text,uuid,text,text,jsonb)` is `SECURITY DEFINER` and creates a `Draft` Manual Voucher.
- `complete_manual_stock_voucher_atomic(uuid,text,text)` is `SECURITY DEFINER` and transitions `Sent` → `Completed` for `DirectSale`/`SupplierReturn`, and `Received` → `Completed` for `Transfer`/`DirectReturn`.
- COMPLETE writes `completed_by` and `completed_at`.
- Production inventory RPC evidence includes both `send_stock_voucher_atomic(uuid,text,text)` and `post_manual_stock_voucher_atomic(uuid,text,text,text,jsonb)` with `SEND` / `RECEIVE` operations.
- The earlier transactional fixture `IN-1` (`4062e2c6-f683-4a9c-bdc9-89705dbc7a7e`) was confirmed absent after its transaction ended.
- A persistent fixture was created outside `BEGIN/ROLLBACK`:
  - company `da4ef704-88ac-4120-aa0e-65b92b2aa2bc`
  - source `BR-01` / `151e5cd7-ac4a-4fc3-b703-d73a0dbb0dc6`
  - target `BR-2` / `a08568e5-40a7-4b15-85b4-ced8ebf9971d`
  - item `1004` / `ef864b14-ec62-4b9f-9932-17da041b6e42`
  - quantity `1`
  - voucher `IN-1`
  - voucher id `a0974ec8-a5d0-4339-a5fb-7d2d0cee1d64`
  - reference `TEST-004-PERSISTENT`
  - notes `TEST-004 PERSISTENT FIXTURE`

### TEST-004 results

#### STAGE 1 — CREATE
**PASS**
- RPC returned `success=true`.
- Voucher `IN-1` was created and persisted in `Draft` state.

#### STAGE 2 — SEND
**PASS**
- `IN-1` transitioned `Draft → Sent`.
- `sent_date` populated.
- BR-01 / item 1004: `qty 206 → 205`.
- `allocated_qty` remained `0`.
- `available_qty` became `205`.
- Exactly one `inventory_log` row was produced: `DirectSale`, quantity `1`, user `test-operator@rawaea.local`.

#### STAGE 3 — COMPLETE
**PASS**
- COMPLETE moved the voucher to the required completed state for `DirectSale`.
- `completed_at` and `completed_by` were populated.
- COMPLETE produced no additional inventory movement; the voucher retained exactly one inventory-log row.

#### STAGE 4 — FINAL VERIFICATION
**PASS**
- Voucher `IN-1`: `Completed`.
- `completed_by = test-operator@rawaea.local`.
- `completed_at = 2026-08-12 16:47:45.437064+00`.
- BR-01 / item 1004: `qty=205`, `allocated_qty=0`, `available_qty=205`.
- Detail: item `1004`, `qty=1`, `received_qty=0`.
- Inventory history: one `DirectSale` movement, quantity `1`.
- Final summary: `STAGE 4 PASS`.

### TASK-004 closure decision
**TEST-004 PASS. TASK-004 CLOSED / GO.**

### Persistent fixture
Retained intentionally for subsequent controlled tests:
- voucher `IN-1`
- voucher_id `a0974ec8-a5d0-4339-a5fb-7d2d0cee1d64`

No automatic cleanup was performed.

### Production patch status
**None approved or applied by TASK-004.**

---

## TASK-005 — Voucher State Machine
**Status: COMPLETE — GO TO TASK-006**

Production definitions reviewed for CREATE / SEND / POST / COMPLETE / CANCEL.

Confirmed lifecycle:
```text
CREATE → Draft
Draft → Cancelled (Draft-only)
Draft → Sent (SEND)
Transfer / DirectReturn: Sent → partial Sent / full Received → Completed
DirectSale / SupplierReturn: Sent → Completed
```
COMPLETE is administrative closure and does not mutate stock. CANCEL is Draft-only and does not mutate stock.

---

## TASK-006 — Inventory Movement Matrix
**Status: COMPLETE — GO TO TASK-007**

The movement matrix was frozen from Production evidence plus explicitly classified historical evidence. `stock_branches.qty` is physical state, `allocated_qty` is reservation, `available_qty = qty - allocated_qty`, and `inventory_log` is movement history. Manual Voucher SEND/RECEIVE are the proven stock mutation points for the closed voucher paths; COMPLETE/CANCEL are administrative lifecycle actions.

---

## TASK-007 — Custody Matrix
**Status: COMPLETE — GO.**

Closed by commit `65dbb10a4af9a1da357a9f7a55a24cf668f0bc35` from reconciled evidence.

---

## TASK-008 — Movement Types Contract
**Status: COMPLETE — GO.**

Closed by commit `8b8c9d9d838b9eb9e50d115d3f199505c38a2108`.

---

## TASK-009 — Partial Receive Contract
**Status: COMPLETE — GO.**

Closed by commit `d6681a2f9aade9052548655b7b067811c9367373`.

---

## TASK-010 — Idempotency Contract
**Status: COMPLETE — FINDING / GO TO TASK-011.**

A transactional Production test executed:
`SEND 2 → RECEIVE 1 → repeat the same RECEIVE 1`.

### Result
**TASK-010 — NON-IDEMPOTENT PARTIAL RECEIVE PROVEN.**

The repeated partial RECEIVE was accepted as a second movement rather than being rejected/deduplicated by an independent operation identity. The transaction was rolled back. No idempotency patch was applied by TASK-010.

### Gate
**TASK-010 CLOSED.**

---

## TASK-011 — Concurrency Contract
**Status: COMPLETE — GO TO TASK-012.**

### Production Evidence
Production RPC definitions were captured from `pg_proc` for:
- `complete_manual_stock_voucher_atomic`
- `post_manual_stock_voucher_atomic`
- `send_stock_voucher_atomic`

The captured evidence proves:
- `FOR UPDATE` row locking on the voucher path.
- `FOR UPDATE` row locking on stock rows in the atomic inventory path.
- Conditional/CAS-style stock updates using the previously-read `qty` and `allocated_qty` values.
- Voucher state transitions also use conditional current-state predicates.
- The production atomic path orders effects consistently before stock locking.

### Evidence classification
**PROVEN from actual deployed Production RPC definitions.**

### Gate
**TASK-011 CLOSED.**
Closed by commit `1a700dc1bfb264b282b0fee712801adf71a92a22`.

---

## TASK-012 — Atomic Transaction Contract
**Status: COMPLETE — GO TO TASK-013.**

### Production Test
A single transactional Production test was executed using only the previously-proven company/branches/item and the verified Production RPC path. The test performed:

`CREATE → SEND 2 → RECEIVE 1 → intentionally invalid RECEIVE 2 → full verification → ROLLBACK`.

The invalid RECEIVE attempted to exceed the remaining quantity. The transaction correctly rejected the invalid operation, and the comprehensive post-failure verification matched the expected pre-failure state. The complete test then rolled back.

### Result
**TASK-012 — ATOMIC TRANSACTION CONTRACT PASS.**

### Production impact
- No Schema change.
- No RPC change.
- No application change.
- No permanent test fixture created by TASK-012.
- Test data was rolled back.

### Closure classification
**Production execution VERIFIED. TASK-012 CLOSED / GO.**

### Gate
**Next: TASK-013 — Stock Engine Design.**

---

## TASK-013 — Stock Engine Design
**Status: COMPLETE — GO TO TASK-014.**

### Target Design Authority
The approved/active target design baseline is:
`TARGET — RAWAEA CENTRAL INVENTORY & STOCK MOVEMENT DESIGN`.
It explicitly establishes a single central Inventory Business Core represented by `post_stock_movement` as the authoritative physical stock posting boundary.

### Design contract confirmed
- Inventory movement is a domain operation and is not UI-owned.
- Applications express business intent; they do not implement independent stock mutation rules.
- `stock_branches.qty` is the physical stock truth.
- `stock_branches.allocated_qty` is reservation state and is separate from physical movement.
- `available_qty` is derived availability.
- `inventory_log` is the authoritative posted-movement history.
- Manual Voucher header and detail truth are `stock_vouchers` and `stock_voucher_details`.
- The central movement engine owns movement validation, availability checks, physical quantity mutations, movement logging, movement semantics, locking, and atomicity.
- Reservation is a separate operation and must not be folded into physical movement posting.
- Accounting remains a separate domain engine; this design does not invent Journal/Chart mappings.
- Runsheet remains a separate domain and does not own Manual Voucher semantics.
- `DirectSale` is custody loading to vehicle/representative, not the customer sale; `VanSale` consumes that custody; `DirectReturn` returns custody to warehouse.
- Each physical movement has one authoritative posting path and must generate exactly its corresponding inventory history record.
- `Complete` is administrative closure and must not cause a second physical stock mutation.

### Target movement boundary
The design freezes the central physical posting interface as the `post_stock_movement` boundary. It deliberately leaves `allocated_qty`, Accounting details, detailed Runsheet behavior, and unresolved Loading/Unloading semantics outside the engine contract where separate contracts are required.

### Implementation gate checked
The target design explicitly requires, before implementation: mapping all stock-writing Edge Functions, separating `qty` from `allocated_qty` writers, mapping `inventory_log` writers, mapping Voucher lifecycle functions, proving DirectSale/DirectReturn end-to-end, proving VanSale custody consumption separately, separating Runsheet ownership, mapping accounting effects, and verifying Atomicity/Concurrency. TASK-011 and TASK-012 now provide the Production evidence for the last two prerequisite contracts.

### Production / implementation status
**No production implementation was performed by TASK-013.** This Task is a design contract. No Schema, RPC, Edge Function, or PWA was modified by the task itself.

### Decision
**TASK-013 CLOSED / GO TO TASK-014.**
The Target Inventory Engine boundary is now fixed before coding. Any later implementation must conform to this design and must be separately verified in the actual target system.

---

## TASK-014 — Stock Engine Implementation
**Status: IN_PROGRESS — PRODUCTION EXECUTION REQUIRED.**

### Implementation artifact
Created:
`supabase/migrations/20260812_task014_post_stock_movement.sql`

Commit:
`170df08da029bf84c6fdf7a6743404e67bb0452c0`

### Implementation boundary
The artifact creates a new Production RPC with exact signature:
`public.post_stock_movement(uuid,text,uuid,uuid,uuid,numeric,text,text,text)`

The implementation is deliberately independent of the existing Voucher RPC consumers. It does **not** replace or modify `send_stock_voucher_atomic` or `post_manual_stock_voucher_atomic` and it does not alter schema.

### Production schema basis used
Persisted Production evidence confirms:
- `stock_branches(branch_id,item_id)` unique key.
- `stock_branches.qty` physical quantity.
- `stock_branches.allocated_qty` reservation quantity.
- generated `available_qty = qty - allocated_qty`.
- `inventory_log` fields used by the engine: `company_id`, `log_code`, `movement_date`, `voucher_id`, `item_id`, `item_code`, `item_name`, `movement_type`, `qty`, `reference`, `user_email`.

### Supported movement types in TASK-014
The implementation currently supports only movement semantics already unambiguous in the Target design:
- `PurchaseIn`
- `TransferOut`
- `TransferIn`
- `POSSale`
- `VanSale`
- `SalesReturn`
- `PurchaseReturn`
- `InventoryIncrease`
- `InventoryDecrease`

`Loading`, `Unloading`, and `Adjustment` are intentionally rejected until their separate event semantics are closed by their designated contracts. This is a safety boundary, not an inferred implementation.

### Engine invariants implemented
- Positive quantity only.
- Closed movement vocabulary.
- Company-context validation for branches and item.
- Required source/target branch validation by movement type.
- Source availability uses `qty - allocated_qty`.
- `allocated_qty` is never mutated.
- Stock row is locked with `FOR UPDATE`.
- Stock write uses conditional/CAS predicates.
- Exactly one corresponding `inventory_log` row is written per successful engine call.
- Stock mutation and inventory log are in the same database transaction boundary.
- `SECURITY DEFINER` with `search_path = public`.

### Current status
**NOT YET PRODUCTION-EXECUTED.**
Repository artifact exists; Production implementation is not considered complete until the SQL migration is actually executed against the target database and the embedded transactional verification returns successfully.

### Next required action
Execute the migration against the actual target database using the exact artifact, then return the final verification result. No Edge Function consumer is to be rewired until TASK-014 Production verification is PASS.


---

## 2026-11-03 — Buyer LVE-602: Return ACL / Procurement Flow Forensic Reconciliation

**Starting checkpoint:** LVE-2026-11-03-601.  
**Operational Git:** `erp-frontend/main` HEAD `743c9b170bf2314a9e4d64fd4d8104f2cc1aee8c`, parent `2ce93c6d80ec4c38353bdf88880d06ae9e0abdde`.  
**Buyer blob:** `aee14e6a4edbccd5fb95dff24f21daf1c6d21fcc`.

### Confirmed evidence
- Revalidated P0 invoice-table writer boundary (migration 20261103155029), PO receiving authorization (20261103155444 / Edge v13), and employee-acknowledgement cash posting (20261103160902). These are already applied; do not repeat.
- Active existing gateways: save-purchase-order v22 and receive-purchase v13; no new Edge Function created.
- Production still grants client DML on purchase_returns and purchase_return_details to anon/authenticated, with ALL RLS policies scoped to current company. Current company-1 source scan of 34 HTML/JS files found no direct DML consumer in that tree; external integrations remain unknown.
- purchase_post_return_atomic currently posts SupplierReturn stock-out and supplier AP debit without an explicit supplier acceptance event.
- Buyer issueCustody modal/toast wording at lines 870/880 asserts immediate cash/GL posting despite current acknowledgement-gated RPC behavior.
- quickPurchase remains an alias to createPurchaseInvoice; Receiver remains PO-only; no distinct Buyer vehicle-goods custody ledger is present.
- Buyer current tabs and existing PO/delivery/fleet contracts preserved.

### Verification boundary
No Buyer/Receiver/main source change, Production DDL/RLS/ACL/grant/RPC/data mutation, Edge deployment, Cloudflare deployment, fixture creation or authenticated Browser E2E was performed. Cloudflare artifact parity and runtime behavior remain UNVERIFIED. Production snapshot counts and full evidence are in Report602.

### Owner change gates
- P0-D: narrow return-table client access to authenticated company-scoped SELECT and central service-role writers; exact proposed SQL, rollback, preflight, and acceptance criteria are in Report602. Not applied pending explicit approval of that exact changeset and external-consumer review.
- P1: Quick Market Purchase, purchasing vehicle goods custody, supplier return acceptance, and custody expense types remain design/open items.
- Owner-facing surgical Buyer text/acknowledgement correction is prepared in Report602; not committed to operational source.

**Arabic report:** `doc/Draft/Reprots/Report602_BUYER_CURRENT_SOURCE_PRODUCTION_FORENSIC_AND_CHANGESET_20261103.md` (commit `25b991849fb2d7c9fea28cff0e68962dcf34a50d`; blob `af43e480f35c72fbc5093a6607c36b4ea16747eb`).  
**Current state:** LVE-602 at top of `CURRENT_STATE.md`; state commit `bc6dd6a42311a599123314adf1a3d6a4772f5f99`; blob `18964899b45250a3bf92bec32d730b6457c1e199`.

**STATUS:** P0 controls already present / return-table DML exposure confirmed / remediation awaiting exact owner approval / market purchase and vehicle custody open / Cloudflare-runtime E2E unverified / not closed.

---

## 2026-11-03 — Buyer LVE-603: Cumulative Return Integrity & Supplier Acceptance Forensic Review

**Starting checkpoint:** LVE-2026-11-03-602.  
**Operational Git:** erp-frontend/main HEAD 743c9b170bf2314a9e4d64fd4d8104f2cc1aee8c; parent 2ce93c6d80ec4c38353bdf88880d06ae9e0abdde.  
**Buyer blob:** aee14e6a4edbccd5fb95dff24f21daf1c6d21fcc.  
**Report:** doc/Draft/Reprots/Report603_BUYER_RETURN_INTEGRITY_DEPLOYMENT_RECHECK_AND_CHANGE_GATE_20261103.md.  
**Report commit:** 7e9fe3e7be50e61d6e71145a6b2bffbdd63b3254.

### Confirmed findings

- Rechecked live Production return table columns, constraints, triggers, grants, RLS policies and RPC definitions.
- purchase_create_return_atomic checks each new detail quantity against the original received_qty but does not subtract quantities already returned in earlier return documents. Separate operation_id values can therefore create new return quantities beyond the original received quantity.
- purchase_post_return_atomic posts SupplierReturn stock movement, debits supplier AP (211), credits inventory (124), inserts supplier_ledger debit and marks Posted. It has no supplier acceptance/partial acceptance event.
- No returned_qty/accepted_qty columns or cumulative return trigger exist in the current return schema. Header triggers only record status history/update timestamp.
- purchase_returns and purchase_return_details have current authenticated direct DML privileges and ALL policies scoped only by current company, not role. Central Edge authorization can therefore be bypassed by a direct same-company authenticated table write.
- Production counts show purchase_returns=0, purchase_return_details=0, custody rows=0. No current over-return rows are evidenced.
- Buyer quickPurchase remains an alias to createPurchaseInvoice; Receiver remains PO-only; the Buyer vehicle panel explicitly says the purchasing goods custody ledger is not enabled.
- Cash custody Production posting waits for the assigned employee acknowledgement; Buyer issueCustody text/toast lines 870/880 still imply immediate posting. Exact owner patch is in Report603 §10.

### Verification boundary / work not performed

No source HTML edit, Production DDL/RLS/ACL/RPC/data mutation, Edge deployment, Cloudflare deployment, fixture creation, or authenticated Browser E2E was performed. Cloudflare snapshot displayed Production commit 7a14d51, which predates the current operational HEAD; current deployment lineage is UNKNOWN. Runtime and business-data effect tests are UNVERIFIED. Full reports 400–500 folder review was not completed through available GitHub tool access.

### Owner gates

- **P0-D:** complete external consumer review; then obtain exact owner approval for Report603 §8 SQL to revoke anon/authenticated DML while retaining authenticated company-scoped SELECT and service_role writer access. Not applied.
- **P0-R:** separately design and approve cumulative-return concurrency guard + supplier handover/acceptance/partial rejection lifecycle + correct stock/AP/GL posting. No migration drafted or applied.
- Owner applies Buyer UI text/toast/acknowledgement patch in Report603 §10; re-fetch the file SHA afterward.
- Do not touch main.html; do not create new Edge Functions; do not repeat already-applied invoice writer, receiving authorization, or custody acknowledgement controls; do not test Production with financial/inventory fixtures.

**STATUS:** return DML boundary and cumulative return guard are CONFIRMED gaps; supplier acceptance, market purchase, purchasing vehicle custody and general custody expense classification remain OPEN; Cloudflare artifact parity UNKNOWN; authenticated runtime/E2E UNVERIFIED; Buyer remains OPEN / NOT PRODUCTION-READY.


---

## 2026-11-03 — Buyer LVE-607: Safe Source Execution

**Starting checkpoint:** LVE-2026-11-03-606.  
**Operational HEAD / parent:** `5d7b10e4fd0fdf1bb2299c87805f9c86d381cc35` / `df7ad3aaa38b10dfaef6a3beb47780be4f5cfc9d`.  
**Buyer blob:** `7f82fceb0b2c2470d1f112aefeaa1341de5b71a8`.

### Executed
- Buyer supplier directory is read-only; create/edit route removed and guarded; no SAVE_SUPPLIER call remains.
- Supplier list and quotation/PO/invoice pickers require is_active=true. This is active status only, not proof of formal approval.
- Vehicle balance tab renamed «رصيدي». It no longer reads Fleet/Delivery assignments and explicitly avoids showing a fabricated balance while the central goods-custody ledger is absent.
- Parent main.html, Receiver, Core, DB and Production untouched.

### Not executed / blockers
- Quick Market invoice still Draft-only; no invoice-linked Receiver contract.
- No goods custody ledger; no SupplierReturn single-writer/acceptance; no generic custody expense categories/account mapping.
- No new Edge Function. Existing save-purchase-order v22 and receive-purchase v13 remain as-is.
- No fixtures/E2E: current Staging lacks Buyer invoice/custody schema; Production not used for test data. No Cloudflare deploy or authenticated runtime verification.

**Report607:** `doc/Draft/Reprots/Report607_BUYER_SAFE_SOURCE_EXECUTION_MASTER_SUPPLIER_AND_GOODS_CUSTODY_20261103.md` (commit `bb3a491bf30b8add280d8245b20f886d26ce2cb7`; blob `5f3164c10ede4584f142b28863251deb3ca871d8`).  
**Current State:** LVE-607 at top of `CURRENT_STATE.md`; commit `2e535fc8a0ca152ec9d4ca49cb38fde7efd9358f`; blob `81b10a79e766a0fc09cf8395bb18ae81be816e56`.

**STATUS:** Workstream A source-level complete; B–E open; overall Buyer OPEN / NOT PRODUCTION-READY.


---

## 2026-11-04 — Buyer LVE-610: PO/Invoice Parent Integration, Creator, Currency & Barcode Forensic Change Set

**Starting checkpoint:** LVE-2026-11-03-609 / Report609.  
**Operational HEAD:** 2b94681bf0ce93ca9ea55066a3f52c0d1add1084.  
**Buyer blob:** 7f82fceb0b2c2470d1f112aefeaa1341de5b71a8.  
**Parent blob:** 53b5a9e9d0433a785c3d5471a9c0d68c25497882.  
**Report610:** doc/Draft/Reprots/Report610_BUYER_PO_INVOICE_PARENT_CYCLE_UX_CURRENCY_BARCODE_FORENSIC_20261104.md (blob e88c15586a9a37025b04924b8b6553aa7fcfa5b2, commit db82d92f45e6b122000453cacdf01382f9035c93).

### Confirmed
- Buyer and Parent use the same central purchase_orders/purchase_invoices tables and existing save-purchase-order v22 RPC writers; no duplicate schema needed.
- created_by already stores the authenticated creator email in PO and Invoice; Parent currently omits it. Parent invoices show supplier_id UUID instead of supplier name.
- Parent Realtime subscribes to purchase_invoices but not purchase_orders.
- New document currency is derived server-side from app_settings.currency (EGP); purchase_settings.default_currency is separately editable and can diverge. Historical SAR docs must retain their stored currency.
- Buyer lacks camera scanning in PO/Invoice inputs; Parent inventory has a BarcodeDetector/getUserMedia implementation to adapt independently.
- Parent and Buyer data loading are limited to 300 and 500 rows respectively; Edge GET_DATA currently has no offset/server filters.
- Cloudflare Pages check for HEAD 2b94681 succeeded 2026-11-04 11:26:14 UTC; served artifact/runtime parity remains unverified.

### Change Set / verification boundary
Report610 proposes surgical Buyer list/form/scanner improvements; Parent creator/supplier/currency display, PO Realtime subscription and authoritative app_settings currency; and optional bounded extension of existing Edge v22 GET_DATA for pagination/exact barcode lookup. No new Edge Function or duplicate tables.

No Buyer/Parent/Core source write, no production DDL/RPC/RLS/ACL/data mutation, no Edge deploy, no Cloudflare deploy, no fixture or authenticated E2E. rawaea-staging remains non-parity. Exact owner approval remains required under Master CTO §77.2.

**STATUS:** REPORT610 READY / CHANGE SET APPROVAL OPEN / NO OPERATIONAL OR PRODUCTION WRITE / NOT E2E-VERIFIED.
