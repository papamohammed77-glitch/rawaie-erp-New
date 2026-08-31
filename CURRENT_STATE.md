# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- `CURRENT_STATE.md` is the single operational state entry point for this repository.
- `LAST VERIFIED EVENT` is the only recency authority; `LAST REPORT` has no operational authority.
- Reports, prompts, historical repositories and assistant memory are evidence/navigation only.
- Any mismatch between this file, Git, Production, deployments or runtime must be marked `STALE` and reconciled before new engineering decisions.
- Production changes require root-cause, dependency, contract, test, deployment and post-deployment verification before closure.

## PROJECT
- Project: RAWAEA ERP
- Current repository: `papamohammed77-glitch/rawaie-erp-New`
- Historical repository: `papamohammed77-glitch/rawaie-erp-review`
- Active Git branch: `main`
- Production Supabase: `SMART ERP` / `fiilmooggumokxanwiyx`
- Staging Supabase: `rawaea-staging` / `hfzznsiprnwkpayskzhu`

## CURRENT GIT — FRESHLY VERIFIED
- Branch: `main`
- Current HEAD: `461f98f31a3c10e2db23225a9ac74ad7e028a928`
- HEAD message: `docs(cto): record final evidence matrix and open unknowns`
- Repository is public, not archived, and current write permissions are available.
- Current state file was reconciled after detecting drift from its previous recorded SHA/state.

## CURRENT PRODUCTION — FRESHLY VERIFIED
- Project: `fiilmooggumokxanwiyx`
- Name: `SMART ERP`
- Region: `eu-west-1`
- Status: `ACTIVE_HEALTHY`
- PostgreSQL: 17.6.1.121 / engine 17 / GA channel
- Directly verified Production contracts remain centered on authenticated user -> `public.users.auth_id` -> `public.users.company_id`.
- `app_private.current_user_company_id()` is the database-side tenant resolver.
- `post_stock_movement` is the inspected physical-stock core.
- `post_journal_entry`, `post_customer_ledger_entry`, `post_supplier_ledger_entry` are the inspected accounting/ledger writers.

## CURRENT PRODUCTION DATA / INTEGRITY BASELINE
Previous fresh integrity snapshot remains the latest directly verified business-data snapshot until a newer SQL snapshot is recorded:
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
- Negative stock: 0
- Allocated > qty: 0
- Available negative: 0
- Stock duplicate keys: 0
- Cross-company integrity mismatches: 0
- Customer/supplier ledger orphan count: 0
- Journal lines without headers: 0
- Journal headers without lines: 2 (both `Cancelled` / `VoidInvoice`)
- Active/non-inactive users without auth link: 1

## CURRENT EDGE DEPLOYMENT INVENTORY — FRESHLY VERIFIED
Production contains a large active Edge Function surface. Key inspected families include:
- sales: `save-sales-invoice`, `confirm-order`, `delete-order`, `update-order`, `submit-online-order`
- runsheets/fulfillment: `create-runsheet`, `append-to-runsheet`, `start-picking`, `complete-picking`, `start-loading`, `complete-loading`, `start-delivery`, `complete-delivery`, `start-return`, `complete-return`, `unload-runsheet`
- stock vouchers: `create-stock-voucher`, `send-stock-voucher`, `receive-stock-voucher`, `complete-stock-voucher`, `cancel-stock-voucher`
- purchasing: `save-purchase-order`, `receive-purchase`
- accounting: `save-journal-entry`, `save-receipt-voucher`, `save-payment-voucher`, `get-trial-balance`, `get-profit-loss`, `get-balance-sheet`, `get-cash-flow`, `get-pnl-by-cost-center`
- inventory: `save-inventory-count`, `bulk-stock-adjustment`, `seed-stock-branches`
- customer/supplier/master data: `save-item`, `delete-item`, `save-customer`, `delete-customer`, `save-supplier`, `delete-supplier`, `save-branch`, `delete-branch`, `save-category`
- settlement/ledger: `save-daily-settlement`, `update-driver-ledger`
- delivery/support: `save-delivery-item`, `cancel-delivery`, `force-unassign-runsheet`, `report-discrepancy`, `create-credit-note`
- vehicle/HR: `save-employee`, `delete-employee`, `create_vehicle_atomic` path, `setup-van-branch`
- historical/test/canary/verification functions remain deployed and ACTIVE in Production, including multiple dated E2E, canary, recovery and harness functions. These are not to be treated as production consumers without runtime/consumer evidence.

### Inspected production versions
- `save-sales-invoice` v15; JWT verification enabled
- `receive-purchase` v12; JWT verification enabled
- `complete-loading` v11; JWT verification enabled
- `send-stock-voucher` v19; JWT verification currently disabled at platform layer but function body performs explicit Bearer-token authentication before business execution

## CURRENT DATABASE SECURITY — FRESHLY VERIFIED
### Confirmed sound patterns
- Tenant mapping is anchored on authenticated Supabase identity through `users.auth_id` and `company_id`.
- `app_private.current_user_company_id()` is `SECURITY DEFINER`, `STABLE`, with empty search_path.
- Many current RLS policies are company-scoped and permission-aware.
- Critical atomic writers are `SECURITY DEFINER` with controlled search paths and business validation.

### BLOCKING / OPEN SECURITY FINDINGS
1. `orders` broad `ALL` policy for authenticated users based only on `auth.role()='authenticated'`.
2. `order_details` same broad authenticated `ALL` policy.
3. `run_sheet_details` same broad authenticated `ALL` policy.
4. `daily_settlements` has `USING true` / `WITH CHECK true` policy and broad read exposure.
5. Core order/fulfillment tables retain broad anon/authenticated grants; least-privilege remediation requires consumer proof first.
6. Supabase Security Advisor currently reports several externally executable `SECURITY DEFINER` functions, including vehicle context/guard helpers and `create_vehicle_atomic`.
7. Supabase Auth leaked-password protection is currently disabled.
8. Supabase Performance Advisor reports unindexed FKs, auth-RLS initplan issues, multiple permissive policies and unused indexes. These are performance/governance backlog unless proven correctness-impacting.
9. Some ledger tables have RLS enabled without policies; this must be classified deliberately against the actual consumer contract, not patched blindly.

## CURRENT APPLICATION / NEW-MAIN STATUS
- `Current/PWA/main.html` remains protected: not modified and not authorized for replacement.
- `Current/PWA/New-main` remains a clean-room candidate, not certified production replacement.
- New-main is materially expanded with authentication, tenant context, navigation, read models, delegated specialized writes, dashboard/search, owner/permission surfaces, and no direct stock/financial DML.
- Current open New-main gates remain: exhaustive feature parity, structural parity, browser runtime, Service Worker runtime, authenticated Production E2E, concurrency proof, and replacement authorization.
- Current logical `main1..main11` artifacts are treated as logical modules/contracts, never as byte slices.

## CURRENT BUSINESS / ARCHITECTURAL CONTRACTS
- Sales channels converge into order/runsheet/fulfillment lifecycle.
- Physical stock authority: `post_stock_movement`.
- Reservation authority: `reserve_stock` / `release_stock_reservation`.
- Journal authority for inspected paths: `post_journal_entry`.
- Customer/supplier/driver ledger authorities exist as dedicated writers.
- Atomic/idempotent patterns are present in current sales, purchase, journal and stock paths.
- `complete-loading` delegates physical stock movement to `post_stock_movement`.
- `receive-purchase` delegates physical stock to `post_stock_movement` and financial consequences to journal + supplier ledger writers.
- `save-sales-invoice` delegates physical stock to `post_stock_movement` and financial consequences to cash/journal/ledger writers.
- Specialized PWA owners remain responsible for POS, Telesales, Van Sales, Purchasing/Receiving, Picking, Loading, Delivery, Returns and Stock Vouchers.

## HISTORICAL SOURCE STATUS
- Historical repository `rawaie-erp-review/main` remains authoritative only for historical architecture/contracts/forensics.
- Historical docs establish the PWA + Supabase + Edge Function architecture and business workflows, but do not override current Production truth.
- Historical reports can explain why a behavior exists; Production decides whether it exists now.

## CURRENT INCIDENT / ANTIPATTERN MEMORY
- Do not convert a report into runtime truth.
- Do not treat a successful migration/CI/test as Production success.
- Do not assume Git source equals deployed code.
- Do not use `LIMIT 1` to hide unresolved company-scoped identity ambiguity.
- Do not create a new Physical Stock writer when a canonical stock core exists.
- Do not repair financial anomalies without provenance, downstream-impact analysis, rollback path and audit implications.
- Do not patch `Current/PWA/main.html` while New-main replacement remains uncertified.
- Do not infer that active dated test/canary Edge Functions are production business consumers.
- Do not use broad RLS/grants as proof of intended authorization contract.

## MEMORY / CURRENT-TRUTH RECOVERY STATUS
- `117-02` command has been adopted as the current memory-governance operating rule.
- Memory is represented as a verified-state system, not as narrative recollection.
- The project memory must preserve: current truth, historical contract, current-vs-target gaps, incident memory, open unknowns, and last verified event.
- Full semantic/all-function consumer graph is not yet proven exhaustively.

## FORBIDDEN ACTIONS — ACTIVE
- No blind Production DDL/DML.
- No direct physical-stock DML outside canonical stock writer paths.
- No direct financial mutation from New-main.
- No rewrite/byte-slice of logical main modules.
- No replacement of `Current/PWA/main.html` without complete parity/runtime/deployment evidence.
- No deletion of unknown/legacy artifacts without proven classification.
- No credential/token use from historical reports/workflows merely because it is visible in source.

## LAST VERIFIED EVENT
- Event ID: `LVE-2026-08-31-012`
- Event Type: `CURRENT_TRUTH_BOOT_RECONCILIATION`
- UTC: `2026-08-31T17:16:30Z` (verification window)
- Source: direct GitHub repository metadata + direct SMART ERP Supabase project/deployment/advisor verification
- Git SHA: `461f98f31a3c10e2db23225a9ac74ad7e028a928`
- Production State: `ACTIVE_HEALTHY`
- Action: Read `CURRENT_STATE.md` first as required by 117-02; re-verified Git main HEAD, Production project status, active Edge deployment inventory, and current Security/Performance Advisor state; detected and classified the prior state as stale before reconciliation.
- Result: `STATE RECONCILED / MEMORY RECOVERY CONTINUES / PRODUCTION CHANGES BLOCKED BY OPEN SECURITY + PROOF GATES`
- Evidence: Git HEAD `461f98f31a3c10e2db23225a9ac74ad7e028a928`; Supabase `fiilmooggumokxanwiyx`; Security Advisor observed `2026-08-31T17:16:25Z`; Performance Advisor observed `2026-08-31T17:16:30Z`.
- Impact: Previous New-main-focused state was stale as an operational memory entry and has now been synchronized to the wider current project/Production truth.
- Next Authorized Action: build the governed `117-02` project memory artifact from verified current state + historical contract sources, then update this file immediately after that execution.

## CURRENT CLOSURE STATUS
`CURRENT_STATE = RECONCILED`
`MEMORY_GOVERNANCE_117_02 = ACTIVE`
`PRODUCTION_HEALTH = ACTIVE_HEALTHY`
`TENANT_SECURITY = P0_OPEN`
`DIRECT_GRANT_LEAST_PRIVILEGE = OPEN`
`CONSUMER_GRAPH = PARTIAL / OPEN`
`DEPLOYMENT_LINEAGE = PARTIAL / OPEN`
`NEW_MAIN = CANDIDATE / NOT_PRODUCTION_REPLACEMENT`
`PRODUCTION_ENGINEERING = BLOCKED_UNTIL_READINESS_GATES`
