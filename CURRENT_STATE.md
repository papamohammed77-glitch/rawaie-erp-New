# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- `CURRENT_STATE.md` is the single operational state entry point for this repository.
- `LAST VERIFIED EVENT` is the only recency authority; `LAST REPORT` has no operational authority.
- Historical reports/prompts, historical repositories and assistant memory are evidence/navigation only.
- Any mismatch between this file, Git, Production, deployments or runtime must be marked `STALE` and reconciled before new engineering decisions.
- Production changes require root-cause, dependency, contract, test, deployment and post-deployment verification before closure.
- Project memory is maintained in `Current/CTO/RAWAEA_PROJECT_MEMORY_117-02.md`.

## PROJECT
- Project: RAWAEA ERP
- Current repository: `papamohammed77-glitch/rawaie-erp-New`
- Historical repository: `papamohammed77-glitch/rawaie-erp-review`
- Active Git branch: `main`
- Production Supabase: `SMART ERP` / `fiilmooggumokxanwiyx`
- Staging Supabase: `rawaea-staging` / `hfzznsiprnwkpayskzhu`

## CURRENT GIT — FRESHLY RECONCILED
- Branch: `main`
- Current HEAD: `a20928631202229cf9d1dc5ee4d67f10f06165b9`
- Latest user documentation commit only normalized the master command file name/newline; no Production mutation was introduced.
- Repository is public, not archived, and write permissions are available.

## CURRENT PRODUCTION — FRESHLY VERIFIED
- Project: `fiilmooggumokxanwiyx`
- Name: `SMART ERP`
- Region: `eu-west-1`
- Status: `ACTIVE_HEALTHY`
- PostgreSQL: 17.6.1.121 / engine 17 / GA channel
- Fresh SQL snapshot: 66 public tables, 76 public functions, 20 public triggers, 110 public RLS policies.
- Current business data remains: companies 1, users 24, branches 2, items 17, stock rows 20, inventory_log 3, orders 0, runsheets 0, journal_entries 2, journal_lines 0, customer_ledger 0, supplier_ledger 0, driver_ledger 0, daily_settlements 0, treasury 1.
- Authoritative identity path: authenticated user -> `public.users.auth_id` -> `public.users.company_id`.
- Database tenant resolver: `app_private.current_user_company_id()`.
- Physical-stock core: `post_stock_movement`.
- Inspected accounting/ledger cores: `post_journal_entry`, `post_customer_ledger_entry`, `post_supplier_ledger_entry`, driver-ledger path.

## CURRENT PRODUCTION SECURITY / AUTHORIZATION FINDINGS
- `orders` broad authenticated ALL policy plus broad store/anon INSERT policies.
- `order_details` broad authenticated ALL policy.
- `run_sheet_details` broad authenticated ALL policy.
- `daily_settlements` public ALL with `true/true`.
- Seven current `SECURITY DEFINER` functions are executable by `anon` and/or `authenticated`, including `create_vehicle_atomic`, vehicle context/guard helpers, `fn_vehicle_audit_trigger`, and `get_budget_vs_actual`.
- Auth leaked-password protection is disabled.
- Performance Advisor also reports unindexed FKs, RLS init-plan inefficiencies, multiple permissive policies and unused indexes.
- No security remediation has been applied in this execution; consumer/authorization proof remains required first.

## STAGING EVIDENCE
- Staging ref `hfzznsiprnwkpayskzhu` currently has 1 company, 1871 users, 2 branches, 1 item, 1 order, 2 runsheets, 2 stock rows, 14 inventory log rows.
- Staging therefore does not currently provide a two-company authorization harness by observation alone.

## CURRENT EDGE DEPLOYMENT INVENTORY
Production contains a large active Edge Function surface across sales, fulfillment, vouchers, purchasing, accounting, inventory, settlement/ledger, master data, vehicles/HR, reporting/support, plus dated E2E/canary/recovery/harness functions.
Important inspected versions:
- `save-sales-invoice` v15, JWT enabled
- `receive-purchase` v12, JWT enabled
- `complete-loading` v11, JWT enabled
- `send-stock-voucher` v19, platform JWT disabled but body explicitly authenticates Bearer credentials
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
- Active dated test/canary/recovery/harness functions are not treated as production consumers merely because they are deployed.

## CURRENT APPLICATION / NEW-MAIN
- `Current/PWA/main.html` is protected and has not been authorized for replacement.
- `Current/PWA/New-main` remains a clean-room candidate.
- New-main has authentication, tenant context, navigation, read models, delegated operational writes, dashboard/search, owner/permission surfaces, Service Worker wiring, and no direct stock/financial mutation.
- Open New-main gates: exhaustive parity, browser/runtime verification, Service Worker runtime proof, authenticated Production E2E, concurrency proof, deployment lineage, replacement certification.
- Logical `main1..main11` artifacts are modules/contracts, never byte slices.

## CURRENT ARCHITECTURAL CONTRACTS
- Sales channels converge through orders/runsheets/fulfillment.
- Physical stock authority: `post_stock_movement`.
- Reservation authority: `reserve_stock` / `release_stock_reservation`.
- Journal authority for inspected accounting paths: `post_journal_entry`.
- Dedicated customer/supplier/driver ledger writers exist.
- Sales, purchase receiving and loading inspected paths delegate physical movement to the canonical stock engine.
- Specialized PWAs remain responsible for POS, Telesales, Van Sales, Purchasing/Receiving, Picking, Loading, Delivery, Returns and Stock Vouchers.

## MASTER COMMAND EXECUTION — 2026-08-31
- Full `doc/Draft/medhat/MASTER - RAWAEA ERP.md` was read end-to-end through section 60.
- The command was adopted as the execution governance for this session.
- Current Target Discovery selected consumer/deployment/authorization graph proof rather than a historical numbered stage.
- Existing `Current/CTO/20260831_PHASE5_SYSTEM_DEPENDENCY_GRAPH.md` was found internally inconsistent: it was labeled CLOSED while admitting the runtime consumer graph was not complete.
- That inconsistency was corrected; Phase 5 is now `PARTIAL / OPEN` until consumer, runtime, deployment and authorization closure gates are proven.

## MEMORY 117-02
- `Current/CTO/RAWAEA_PROJECT_MEMORY_117-02.md` is the governed project memory ledger.
- It now contains the full Master-command operating rules, current Production snapshot, current security findings, staging limitation, historical Inventory/Receive lineage, consumer examples and closure units.
- It does not claim exhaustive consumer/deployment proof or Production readiness.

## KNOWN ANTIPATTERNS / FORBIDDEN ACTIONS
- Report != current truth.
- Historical PASS != current PASS.
- CI/Migration PASS != Production PASS.
- Git source != deployed code unless lineage is proven.
- Deployment existence != production consumption.
- Unknown != bug and Unknown != remove.
- No duplicate Physical Stock writers.
- No blind Production DDL/DML.
- No repair of data anomalies without provenance/downstream/audit analysis.
- No broad RLS/grant remediation before consumer proof.
- No byte-slicing logical PWA modules.
- No artificial workflow/executor/shadow architecture.
- No Main replacement before complete evidence.

## CURRENT OPEN CLOSURE UNITS
1. Full consumer graph: `CONSUMER -> CAPABILITY -> EDGE -> RPC -> TABLE`.
2. Full deployment lineage of critical writers.
3. Exhaustive Physical Stock writer exclusivity current proof.
4. Exhaustive journal/ledger/treasury writer matrix.
5. Two-tenant authorization proof via a real multi-tenant harness; current staging has one company.
6. P0 tenant isolation remediation.
7. Least-privilege grant/policy remediation.
8. Security Advisor remediation + regression suite.
9. Production/New-main authenticated E2E and browser parity.
10. Service Worker runtime proof.
11. Main replacement certification.
12. Historical inventory-log provenance reconciliation.
13. Provenance of the current auth-link/journal anomalies.

## LAST VERIFIED EVENT
- Event ID: `LVE-2026-08-31-018`
- Event Type: `MASTER_COMMAND_EXECUTION_AND_DEPENDENCY_GRAPH_RECONCILIATION`
- UTC: `2026-08-31T17:48:00Z` (execution window)
- Source: direct GitHub full-file read + direct SMART ERP SQL verification + staging SQL verification
- Git SHA: `a20928631202229cf9d1dc5ee4d67f10f06165b9`
- Production State: `ACTIVE_HEALTHY`
- Action: read and analyzed `MASTER - RAWAEA ERP.md` end-to-end through section 60; executed its current-target discovery and reconciliation rules; freshly verified Production and staging; identified the Phase 5 CLOSED/OPEN contradiction; corrected the existing dependency graph to `PARTIAL / OPEN`; updated the governed memory ledger and this state checkpoint.
- Result: `MASTER GOVERNANCE ACTIVE / PHASE5 CORRECTLY OPEN / SECURITY + CONSUMER + DEPLOYMENT PROOF GATES REMAIN`
- Evidence: master-command commit `a20928631202229cf9d1dc5ee4d67f10f06165b9`; dependency-graph reconciliation commit `50b40e6b7d8d0f0ddc29dc6681fac8059cc5e110`; memory ledger reconciliation commit `a3d6239a6eea6b786cf0c3d5f9df0a85ff17a93c`; direct Production SQL snapshot and privilege/RLS query observed during the execution window.
- Impact: project continuation is now governed by current verified evidence, and a misleading Phase 5 closure state has been removed.
- Next Authorized Action: continue exhaustive consumer/function/deployment lineage and controlled multi-tenant authorization proof; keep Production security mutation blocked until those proofs are sufficient.

## CURRENT CLOSURE STATUS
`CURRENT_STATE = SYNCHRONIZED`
`MASTER_CONTINUITY_COMMAND = ACTIVE`
`MEMORY_GOVERNANCE_117_02 = ACTIVE`
`PRODUCTION_HEALTH = ACTIVE_HEALTHY`
`PHASE_5_DEPENDENCY_GRAPH = PARTIAL / OPEN`
`TENANT_SECURITY = P0_OPEN`
`DIRECT_GRANT_LEAST_PRIVILEGE = OPEN`
`SECURITY_ADVISOR_FINDINGS = OPEN`
`CONSUMER_GRAPH = PARTIAL / OPEN`
`DEPLOYMENT_LINEAGE = PARTIAL / OPEN`
`INVENTORY_WRITER_EXCLUSIVITY = PARTIAL / OPEN`
`LEDGER_WRITER_EXCLUSIVITY = PARTIAL / OPEN`
`NEW_MAIN = CANDIDATE / NOT_PRODUCTION_REPLACEMENT`
`PRODUCTION_ENGINEERING = BLOCKED_UNTIL_READINESS_GATES`
