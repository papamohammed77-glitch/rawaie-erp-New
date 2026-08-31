# RAWAEA ERP — PROJECT MEMORY LEDGER 117-02

## 0. PURPOSE
This file is the persistent, governed project-memory ledger derived from the `117-02` current-truth command and the `MASTER - RAWAEA ERP.md` continuity/execution command.
It is not a report and not a replacement for source systems.
Operational recency is governed by `CURRENT_STATE.md` and its `LAST VERIFIED EVENT`.

## 1. SOURCE OF TRUTH HIERARCHY
1. Production runtime and database evidence
2. PostgreSQL schema/functions/triggers/RLS/grants/constraints
3. Active deployed Edge Functions plus runtime evidence
4. Current Git `main`
5. Current application/core/PWA/SW files
6. Git history
7. Historical/original sources
8. Historical execution artifacts
9. Reports/prompts
10. Assistant memory

Historical sources explain intent and prior behavior. They do not prove current runtime state without re-verification.

## 2. CURRENT PROJECT IDENTITY
- Project: RAWAEA ERP
- Current repository: `papamohammed77-glitch/rawaie-erp-New`
- Historical repository: `papamohammed77-glitch/rawaie-erp-review`
- Current Git branch: `main`
- Latest observed Git HEAD after user documentation update: `a20928631202229cf9d1dc5ee4d67f10f06165b9`
- Production: Supabase `SMART ERP`, ref `fiilmooggumokxanwiyx`
- Staging: Supabase `rawaea-staging`, ref `hfzznsiprnwkpayskzhu`

## 3. MASTER COMMAND ADOPTION
The full `doc/Draft/medhat/MASTER - RAWAEA ERP.md` command was read end-to-end through section 60.
Its operational requirements are now adopted:
- `CURRENT_STATE.md` first, then fresh reality verification.
- `LAST VERIFIED EVENT`, never `LAST REPORT`, as the operational continuation point.
- No historical-stage lock-in and no percentage-based control signal.
- Unknown/conflict resolution before risky changes.
- No artificial workflows/executors/shadow implementations.
- Core ownership must be preserved; call the owner instead of copying it.
- Production changes require root cause -> dependency/contract proof -> surgical change -> test -> deploy -> runtime/data/audit verification -> `CURRENT_STATE` update.
- Closure is prohibited when critical unknowns/conflicts remain.

## 4. CURRENT BOOT / RECONCILIATION MEMORY
A fresh boot previously found `CURRENT_STATE.md` stale relative to Git and Production and reconciled it before memory work.
A later user documentation update advanced Git again; that drift was identified and inspected rather than ignored.
The latest user change was documentation-only: `a2092863...` renamed/normalized the master-command file and did not modify Production.

## 5. FRESH PRODUCTION SNAPSHOT — 2026-08-31
Direct SQL verification against Production observed:
- PostgreSQL 17.6
- Public tables: 66
- Public functions: 76
- Public triggers: 20
- Public policies: 110
- Companies: 1
- Users: 24
- Branches: 2
- Items: 17
- Stock rows: 20
- Inventory log: 3
- Orders: 0
- Runsheets: 0
- Journal entries: 2
- Journal lines: 0
- Customer ledger: 0
- Supplier ledger: 0
- Driver ledger: 0
- Daily settlements: 0
- Treasury: 1
Production status: `ACTIVE_HEALTHY`.

These counts supersede older historical counts only for current operational use; historical snapshots remain preserved as historical evidence.

## 6. CURRENT SECURITY / AUTHORIZATION EVIDENCE
Fresh Production privilege/RLS inspection confirmed:
- `orders` has broad authenticated `ALL` policy plus broad INSERT paths for store/anon flows.
- `order_details` has broad authenticated `ALL` policy.
- `run_sheet_details` has broad authenticated `ALL` policy.
- `daily_settlements` has public `ALL` policy with `true/true`.
- Public `SECURITY DEFINER` functions currently executable by `anon` and/or `authenticated` include `create_vehicle_atomic`, vehicle context/guard helpers, `fn_vehicle_audit_trigger`, and `get_budget_vs_actual` (7 functions in the observed set).
- Auth leaked-password protection is disabled according to the current Security Advisor snapshot.
- Performance Advisor also reports unindexed FKs, RLS init-plan inefficiencies, multiple permissive policies and unused indexes.

These are current evidence-backed blockers/findings, not permission to mutate Production blindly.

## 7. STAGING OBSERVATION
Direct SQL against staging `hfzznsiprnwkpayskzhu` currently observed:
- Companies: 1
- Users: 1871
- Branches: 2
- Items: 1
- Orders: 1
- Runsheets: 2
- Stock rows: 2
- Inventory log: 14

Therefore the existing staging environment does not currently provide a two-company harness by data count alone. A two-tenant proof cannot be claimed from staging without first creating/obtaining a controlled multi-company test environment through an authorized, safe path.

## 8. BUSINESS DOMAIN MEMORY
### Sales
Channels include POS, Telesales, Order Taker, Van Sales and Online Store.
Orders feed runsheet/fulfillment and may end in delivery, return, settlement and ledger/accounting consequences.
Inspected sales invoice path:
`save-sales-invoice -> save_sales_invoice_atomic -> post_stock_movement + accounting/cash/ledger writers as applicable`.

### Procurement
`Purchase Order -> Receiving -> Physical Stock -> Journal -> Supplier Ledger`.
Inspected path:
`receive-purchase -> receive_purchase_atomic -> post_stock_movement + post_journal_entry + post_supplier_ledger_entry`.

### Warehouse / Fulfillment
`Runsheet -> Picking -> Loading -> Delivery/Return/Unloading`.
Picking reserves allocation; loading/unloading move physical stock via the central stock engine in inspected paths.

### Inventory
`stock_branches.qty` is physical quantity.
`allocated_qty` is reservation state; reservation is distinct from physical movement.
Physical movement authority remains `post_stock_movement` for inspected current paths.

### Accounting / Ledgers
`post_journal_entry` is the inspected journal core.
Known dedicated ledger writers include customer, supplier and driver paths.
The all-writer exclusivity matrix is still open.

## 9. CURRENT ARCHITECTURE MEMORY
- Multi-PWA frontend remains current operational architecture.
- `Current/PWA/main.html` is protected from replacement.
- `Current/PWA/New-main` is clean-room candidate only.
- `main1..main11` are logical modules/contracts, not byte slices.
- Authenticated identity maps through `public.users.auth_id -> users.company_id`.
- `app_private.current_user_company_id()` is the DB tenant resolver.
- Specialized PWAs delegate business writes to Edge/RPC/Core owners.
- No duplicate Physical Stock writer is permitted.

## 10. HISTORICAL INVENTORY MEMORY
Historical evidence recorded that the Inventory/Core rescue established:
- `post_stock_movement(10)` as canonical physical movement engine.
- `reserve_stock` / `release_stock_reservation` as reservation-only engines.
- `setup_van_stock` as initialization support.
- legacy physical writers removed/constrained for application execution.
- no stock/inventory trigger writer in the inspected Production scope.
This was an Inventory writer-boundary closure, not an ERP-wide closure.

Historical Receive contract evidence recorded:
- cumulative `received_qty`;
- partial Receive remains `Sent`;
- full Receive changes to `Received`;
- over-remaining rejection;
- preserved allocation;
- one inventory history row per successful physical receive;
- atomic DB transaction.

## 11. CURRENT CONSUMER MEMORY
Representative consumer paths remain:
- Telesales/Main sales flows -> `save-sales-invoice`.
- Purchase receiving UI -> `receive-purchase`.
- Picker/loader/unloader/returns PWAs -> respective fulfillment Edge/Core paths.
- Voucher UI -> voucher Edge/Core paths.
- New-main -> specialized PWA/Edge owners for operational mutations.

Critical distinction:
`EXISTS != ACTIVE != CONSUMED != PRODUCTION CONSUMER != CURRENT AUTHORITATIVE PATH`.
The complete all-consumer graph is not yet proven.

## 12. DEPENDENCY GRAPH RECONCILIATION
`Current/CTO/20260831_PHASE5_SYSTEM_DEPENDENCY_GRAPH.md` previously claimed `CLOSED` while explicitly admitting that the full runtime graph was not proven.
Under the Master Command this was a contract inconsistency.
The file was corrected in commit `50b40e6b...` to:
`PHASE 5 = PARTIAL / OPEN`.
It now records the fresh Production snapshot, current authorization findings, partial consumer graph, partial deployment lineage, and the precise closure requirements.

## 13. DEPLOYMENT LINEAGE MEMORY
For inspected Edge functions, current Production versions are known and selected source wrappers are aligned at contract level.
However the exhaustive chain remains open:
`Git SHA -> source file -> package/deployment artifact -> Production version -> runtime consumer -> runtime evidence`.
Dated E2E/canary/recovery/harness functions remain potentially historical/test infrastructure unless consumer evidence proves otherwise.

## 14. NEW-MAIN MEMORY
New-main remains an expanded clean-room candidate with:
- auth/session bootstrap;
- tenant context;
- owner/permission/license surfaces;
- navigation;
- dashboard/search;
- customer/item CRUD through existing Edge owners;
- operational/finance/HR/read models;
- owner audit view;
- Service Worker wiring;
- explicit specialized PWA delegation;
- no direct stock or financial mutation.

It remains unauthorized to replace `Current/PWA/main.html` until parity, runtime, concurrency and deployment gates are proven.

## 15. CURRENT ANOMALY MEMORY
The latest continuity chain contains these Production anomalies requiring provenance:
1. One active/non-inactive `users` row without `auth_id`.
2. Two cancelled `VoidInvoice` journal headers with zero lines.
3. Three `VoidInvoice` inventory-log rows.
No deletion or synthetic repair is permitted without provenance, downstream impact and audit analysis.

## 16. INCIDENT / FAILURE MEMORY
Never repeat these failure modes:
- using a historical report as current truth;
- treating historical PASS as current PASS;
- assuming Git equals deployed code;
- assuming deployment existence means production consumption;
- treating broad RLS/grants as intended authorization design;
- creating duplicate stock writers;
- testing Production with persistent fake data when rollback/read-only evidence is possible;
- deleting unknown or suspicious records without provenance;
- byte-slicing logical PWA modules;
- compacting a rich legacy application into a feature-loss candidate;
- patching Production solely to satisfy CI.

## 17. OPEN CLOSURE UNITS
1. Full consumer graph: `CONSUMER -> CAPABILITY -> EDGE -> RPC -> TABLE`.
2. Full deployment lineage of critical writers.
3. Exhaustive Physical Stock writer exclusivity current proof.
4. Exhaustive journal/ledger/treasury writer matrix.
5. Two-tenant authorization proof via an authorized multi-tenant harness; current staging has only one company.
6. P0 tenant isolation remediation plan.
7. Least-privilege grant/policy remediation after consumer proof.
8. Security Advisor remediation plan and regression suite.
9. Provenance classification of auth-link anomaly and cancelled journal headers.
10. New-main authenticated Production E2E and browser/runtime parity.
11. Service Worker runtime proof.
12. Main replacement certification.
13. Historical inventory-log provenance reconciliation.

## 18. FORBIDDEN ACTIONS
- No blind Production DDL/DML.
- No Production business-logic patch solely for CI.
- No direct Physical Stock writer outside canonical engines.
- No direct financial mutation from New-main.
- No deletion of unknown legacy artifacts.
- No credential/token use because historical source exposes it.
- No Main replacement before closure evidence.
- No artificial workflow/executor/parallel architecture.

## 19. MEMORY OPERATING LOOP
For every task:
1. Read `CURRENT_STATE.md` first.
2. Read the latest `LAST VERIFIED EVENT`.
3. Verify Git HEAD.
4. Verify relevant Production state.
5. Compare with this memory ledger.
6. Mark stale/conflict.
7. Investigate historical contract only after current truth.
8. Classify: PRESERVE / RECONSTRUCT / REPLACE / RETIRE / UNKNOWN.
9. Prove root cause/ownership/dependencies.
10. Implement the minimum safe change in the actual authorized target.
11. Verify source, data, runtime and audit effects as applicable.
12. Update `CURRENT_STATE.md` immediately.
13. Record material knowledge changes here.
14. Reassess the current target after each closure.

## 20. CURRENT EXECUTION POSITION
- Master continuity command: ACTIVE
- 117-02 memory governance: ACTIVE
- Current State: MUST BE SYNCHRONIZED AFTER EACH REAL EVENT
- Production health: ACTIVE_HEALTHY
- Current critical blocker: security/authorization proof
- Consumer graph: PARTIAL / OPEN
- Deployment lineage: PARTIAL / OPEN
- Inventory physical-writer closure: historically verified for inspected scope; continuous proof remains open
- New-main: candidate only
- Legacy Main replacement: unauthorized
