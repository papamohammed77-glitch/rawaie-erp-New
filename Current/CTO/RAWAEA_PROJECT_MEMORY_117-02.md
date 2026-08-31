# RAWAEA ERP — PROJECT MEMORY LEDGER 117-02

## 0. PURPOSE
This file is the persistent, governed project-memory ledger derived from the `117-02` current-truth command.
It is not a report and not a replacement for source systems.
Operational recency is governed by `CURRENT_STATE.md` and its `LAST VERIFIED EVENT`.

## 1. SOURCE OF TRUTH HIERARCHY
1. Production Supabase current state
2. PostgreSQL schema/functions/triggers/RLS/grants
3. Active deployed Edge Functions and runtime evidence
4. Git current `main`
5. Current application/core/PWA/SW files
6. Git history
7. Historical/original sources
8. Historical execution artifacts
9. Reports/prompts
10. Assistant memory

Historical sources explain why a behavior exists; Production proves whether it exists now.

## 2. CURRENT PROJECT IDENTITY
- Project: RAWAEA ERP
- Current repository: `papamohammed77-glitch/rawaie-erp-New`
- Historical repository: `papamohammed77-glitch/rawaie-erp-review`
- Current Git branch: `main`
- Current Git HEAD verified: `461f98f31a3c10e2db23225a9ac74ad7e028a928`
- Production: Supabase `SMART ERP`, ref `fiilmooggumokxanwiyx`
- Staging: Supabase `rawaea-staging`, ref `hfzznsiprnwkpayskzhu`

## 3. OPERATIONAL MEMORY RULE
Never use `LAST REPORT` as the current operational checkpoint.
Use `LAST VERIFIED EVENT` only.
After every real execution:
`ACTION -> VERIFY -> UPDATE CURRENT_STATE.md -> NEXT ACTION`

## 4. CURRENT STATE RECONCILIATION — 2026-08-31
A fresh boot comparison found the previous `CURRENT_STATE.md` stale relative to Git and Production.
The file was reconciled before continuing.
Latest reconciliation event:
- Event: `LVE-2026-08-31-012`
- Type: `CURRENT_TRUTH_BOOT_RECONCILIATION`
- Git HEAD: `461f98f31a3c10e2db23225a9ac74ad7e028a928`
- Production status: `ACTIVE_HEALTHY`
- Security Advisor observation: `2026-08-31T17:16:25Z`
- Performance Advisor observation: `2026-08-31T17:16:30Z`

## 5. BUSINESS DOMAIN MEMORY
### Sales
Sales channels include POS, Telesales, Order Taker, Van Sales and Online Store.
Sales orders flow into order/runsheet fulfillment and can end in delivery, return and settlement.
Current inspected sales invoice path:
`save-sales-invoice` Edge -> `save_sales_invoice_atomic` -> stock/journal/cash/ledger writers.

### Procurement
Purchase flow:
Purchase Order -> Receiving -> Physical Stock -> Journal -> Supplier Ledger.
Current inspected path:
`receive-purchase` Edge -> `receive_purchase_atomic` -> `post_stock_movement` + `post_journal_entry` + `post_supplier_ledger_entry`.

### Warehouse / Fulfillment
Runsheet lifecycle includes creation, picking, loading, delivery, return and unloading/reopen/cancel branches.
Current inspected loading path:
`complete-loading` Edge -> `complete_runsheet_loading` -> `post_stock_movement` for physical loading movement.

### Inventory
Physical quantity is held in `stock_branches.qty`.
Reservation is represented by `allocated_qty` and `available_qty` semantics.
Reservation and physical movement are separate responsibilities.

### Accounting
Current inspected accounting core validates minimum journal line count, positive balanced debit/credit and company-bound chart-of-accounts ownership before posting.

### Ledgers
Current known dedicated writers:
- `post_customer_ledger_entry`
- `post_supplier_ledger_entry`
- driver-ledger writer path(s)
Full historical/current all-writer matrix remains open.

## 6. CURRENT ARCHITECTURE MEMORY
### Frontend
- Multi-PWA architecture remains the current operational design.
- `Current/PWA/main.html` is legacy/current Main and is explicitly protected from replacement until certified.
- `Current/PWA/New-main` is a clean-room candidate, not certified Production replacement.
- Logical `main1..main11` fragments are modules/contracts, not byte slices.

### Shared layers
- Supabase Auth provides authenticated identity.
- `public.users.auth_id` maps authenticated identity to `company_id`.
- `app_private.current_user_company_id()` is the DB tenant resolver.
- Specialized operational PWAs delegate business writes to Edge/RPC owners.

### Database transaction engines
- `post_stock_movement`: physical stock core.
- `reserve_stock` / `release_stock_reservation`: reservation engines.
- `post_journal_entry`: balanced journal writer.
- Customer/supplier/driver ledger writers: dedicated ledger engines.
- Idempotency patterns exist using operation registries / idempotency keys in inspected paths.

## 7. CURRENT PRODUCTION EDGE MEMORY
Verified active Production surface includes, among others:
- `save-sales-invoice` v15, JWT verified
- `receive-purchase` v12, JWT verified
- `complete-loading` v11, JWT verified
- `send-stock-voucher` v19, platform JWT verification disabled but body explicitly validates Bearer auth
- `complete-picking` v16
- `start-picking` v33
- `start-loading` v5
- `complete-return` v25
- `complete-order-delivery` v14
- `unload-runsheet` v6
- `create-stock-voucher` v9
- `receive-stock-voucher` v21
- `save-purchase-order` v3
- `save-journal-entry` v8
- `save-daily-settlement` v4
- `bulk-stock-adjustment` v6
- `submit-online-order` v7
- master-data, vehicle, HR, dashboard/reporting and support functions.

Production also contains many dated test/canary/recovery/harness functions that are `ACTIVE`; active deployment does not imply an active business consumer.

## 8. CURRENT DATA MEMORY
Latest directly verified business-data baseline available in project records:
- Companies: 1
- Users: 24
- Branches: 2
- Items: 17
- Stock rows: 20
- Inventory log: 3
- Stock vouchers: 0
- Purchase orders: 0
- Orders: 0
- Runsheets: 0
- Treasury: 1
- COA: 17
- Audit log: 1866
- Negative stock: 0
- Allocated greater than physical: 0
- Available negative: 0
- Stock duplicate keys: 0
- Cross-company data integrity mismatches: 0

Current anomalies requiring provenance:
1. One active/non-inactive `users` row without `auth_id`.
2. Two `Cancelled` `VoidInvoice` journal headers with zero lines.
3. Three `VoidInvoice` inventory-log rows.
These records are NOT to be deleted or synthesized without provenance and accounting/audit impact analysis.

## 9. TENANT / AUTH MEMORY
Authoritative path:
`auth.users` -> `public.users.auth_id` -> `public.users.company_id` -> company-scoped business records.
Do not treat `user_metadata.company_id` as authoritative tenant identity.
Do not use `LIMIT 1` to conceal unresolved company-scoped identity ambiguity.
Owner semantics such as `isOwner=true` and wildcard permissions are contractual special cases and must not be normalized away without evidence.

## 10. SECURITY MEMORY — CURRENT BLOCKERS
### Confirmed structural concerns
- `orders` broad authenticated `ALL` RLS policy based only on authenticated role.
- `order_details` broad authenticated `ALL` RLS policy.
- `run_sheet_details` broad authenticated `ALL` RLS policy.
- `daily_settlements` `USING true / WITH CHECK true` policy with broad read exposure.
- Broad anon/authenticated grants remain on core order/fulfillment tables.

### Current Supabase Security Advisor findings
- Several `SECURITY DEFINER` functions are externally executable, including vehicle context/guard functions and `create_vehicle_atomic`.
- Leaked password protection is disabled.
- Some RLS-enabled tables have no policies, including observed ledger/voucher-operation examples.

These are security findings, not authorization to patch Production blindly.
Consumer proof and controlled regression fixtures are required first.

## 11. PERFORMANCE MEMORY
Supabase Performance Advisor currently reports:
- unindexed foreign keys across multiple tables,
- auth RLS init-plan inefficiencies,
- multiple permissive policy combinations,
- unused indexes.
These are backlog findings unless proven to cause correctness problems.

## 12. HISTORICAL MEMORY
Historical `rawaie-erp-review` architecture documented:
- PWA + Supabase + Edge Functions + PostgreSQL architecture.
- 5-channel sales and fulfillment workflows.
- runsheet-driven warehouse lifecycle.
- six-quantity/order fulfillment semantics.
- historical security model using JWT/RLS/Edge verification.
- architectural decisions around Supabase, PWA, Dexie, core.js, specialized applications.
Historical documents are retained as contract/provenance evidence and do not override current Production.

## 13. KNOWN EVOLUTION
The system evolved from distributed business logic toward centralized atomic writers.
Current inspected code proves:
- sales invoice orchestration delegates stock to `post_stock_movement`;
- purchase receiving delegates stock to `post_stock_movement` and accounting/ledger writers;
- loading delegates physical stock to `post_stock_movement`.
This is a material architectural change from older documentation where more responsibility was attributed directly to Edge Functions.

## 14. NEW-MAIN MEMORY
New-main has substantial shell and semantic coverage including:
- authentication/session bootstrap,
- company resolution,
- owner/permissions/license surfaces,
- navigation,
- dashboard/search,
- customer and item CRUD via existing Edge owners,
- read models for orders/runsheets/inventory/finance/HR/settings,
- owner audit view,
- responsive shell and Service Worker wiring,
- explicit delegation to specialized PWA owners,
- no direct Physical Stock mutation,
- no direct journal/ledger/treasury/cash mutation.

It is still not authorized to replace `Current/PWA/main.html`.

## 15. DEPLOYMENT MEMORY
Git source and Production Edge deployments are currently only partially lineage-proven.
For inspected functions, current source wrappers match observed Production behavior, but the complete chain
`Git SHA -> file -> deployment artifact -> Production version -> runtime consumer -> runtime evidence`
is not yet exhaustively proven.

## 16. INCIDENT / ANTIPATTERN MEMORY
The project must actively prevent:
- treating reports as current truth;
- treating historical PASS as current PASS;
- treating CI PASS/Migration PASS as Production PASS;
- assuming Git source equals deployed code;
- creating duplicate stock writers;
- direct stock/financial DML from candidate shells;
- data repair without provenance;
- blindly removing `LIMIT 1` without contract classification;
- using active test/canary deployment existence as evidence of business consumption;
- byte-slicing logical PWA modules;
- replacing Main before runtime and parity certification.

## 17. OPEN CLOSURE UNITS
1. P0 tenant isolation remediation design and controlled two-tenant harness.
2. Least-privilege grants for core order/fulfillment tables after consumer matrix proof.
3. Full consumer graph: `CONSUMER -> CAPABILITY -> FUNCTION -> TABLE`.
4. Full deployment lineage proof for all critical writers.
5. Exhaustive Physical Stock writer exclusivity proof.
6. Exhaustive journal/ledger writer matrix.
7. Provenance classification of the orphan auth user and cancelled void headers.
8. Production/New-main runtime parity and authenticated E2E.
9. Service Worker runtime proof.
10. Replacement certification for `Current/PWA/main.html`.
11. Security Advisor remediation plan and regression suite.
12. Broader performance cleanup after correctness/security gates.

## 18. FORBIDDEN ACTIONS
- No blind Production DDL/DML.
- No Production business-logic patch solely to satisfy CI.
- No direct Physical Stock writer outside canonical engines.
- No direct financial mutation from New-main.
- No deletion of unknown legacy artifacts.
- No credential/token use merely because exposed in historical workflows.
- No replacement of Main before closure gates.

## 19. MEMORY OPERATING LOOP
For every future task:
1. Read `CURRENT_STATE.md` first.
2. Read `LAST VERIFIED EVENT`.
3. Fresh-verify Git HEAD.
4. Fresh-verify relevant Production state.
5. Compare against memory ledger.
6. Mark stale/conflict when necessary.
7. Investigate historical contract only after current truth is established.
8. Classify change: PRESERVE / RECONSTRUCT / REPLACE / RETIRE / UNKNOWN.
9. Implement only after root-cause and dependency proof.
10. Verify.
11. Update `CURRENT_STATE.md` immediately.
12. Record the event in this memory ledger when it materially changes project knowledge.

## 20. CURRENT EXECUTION POSITION
- 117-02 memory governance: ACTIVE
- Current State: RECONCILED
- Forensic readiness: READY
- Production engineering: BLOCKED until open security/proof gates close
- New-main: candidate only
- Legacy Main replacement: unauthorized
