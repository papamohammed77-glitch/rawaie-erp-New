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

## CURRENT GIT — FRESHLY VERIFIED
- Branch: `main`
- Current HEAD: `0bd48099d6263c520daa903f6883e0670cef1502`
- HEAD message: `docs(memory): create governed RAWAEA project memory ledger for 117-02`
- Repository is public, not archived, and current write permissions are available.
- This state file is being updated after the memory-ledger creation event.

## CURRENT PRODUCTION — FRESHLY VERIFIED
- Project: `fiilmooggumokxanwiyx`
- Name: `SMART ERP`
- Region: `eu-west-1`
- Status: `ACTIVE_HEALTHY`
- PostgreSQL: 17.6.1.121 / engine 17 / GA channel
- Authoritative identity path: authenticated Supabase user -> `public.users.auth_id` -> `public.users.company_id`.
- Database tenant resolver: `app_private.current_user_company_id()`.
- Physical-stock core: `post_stock_movement`.
- Accounting/ledger cores inspected: `post_journal_entry`, `post_customer_ledger_entry`, `post_supplier_ledger_entry`, driver-ledger path.

## CURRENT PRODUCTION DATA / INTEGRITY BASELINE
Latest directly verified business-data snapshot in this continuity chain:
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
- Allocated > qty: 0
- Available negative: 0
- Stock duplicate keys: 0
- Cross-company integrity mismatches: 0
- Customer/supplier ledger orphan count: 0
- Journal lines without headers: 0
- Journal headers without lines: 2 (`Cancelled` / `VoidInvoice`)
- Active/non-inactive users without auth link: 1

## CURRENT EDGE DEPLOYMENT INVENTORY
Production contains a large active Edge Function surface including sales, runsheet/fulfillment, stock vouchers, purchasing, accounting, inventory, settlement/ledger, customer/supplier/master data, vehicles/HR, reporting and support capabilities.
Important inspected versions:
- `save-sales-invoice` v15, JWT verification enabled
- `receive-purchase` v12, JWT verification enabled
- `complete-loading` v11, JWT verification enabled
- `send-stock-voucher` v19, platform JWT verification disabled but body explicitly validates Bearer authentication
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
- multiple dated E2E/canary/recovery/harness functions are also ACTIVE; existence alone is not proof of production consumption.

## CURRENT DATABASE SECURITY
### Confirmed sound patterns
- Tenant mapping is anchored on authenticated Supabase identity through `users.auth_id` and `company_id`.
- `app_private.current_user_company_id()` is `SECURITY DEFINER`, `STABLE`, with empty search_path.
- Many policies are company-scoped and permission-aware.
- Inspected atomic writers use controlled search paths and business validation.

### BLOCKING / OPEN SECURITY FINDINGS
1. `orders` broad authenticated `ALL` policy based only on authenticated role.
2. `order_details` broad authenticated `ALL` policy.
3. `run_sheet_details` broad authenticated `ALL` policy.
4. `daily_settlements` has `USING true / WITH CHECK true` policy with broad read exposure.
5. Broad anon/authenticated grants remain on core order/fulfillment tables.
6. Security Advisor reports externally executable `SECURITY DEFINER` functions, including vehicle guards and `create_vehicle_atomic`.
7. Auth leaked-password protection is disabled.
8. Several tables have RLS enabled but no policies; classification/remediation remains open.
9. Performance Advisor reports unindexed FKs, RLS init-plan inefficiencies, multiple permissive policies and unused indexes.

## CURRENT APPLICATION / NEW-MAIN STATUS
- `Current/PWA/main.html` remains protected: not modified and not authorized for replacement.
- `Current/PWA/New-main` remains a clean-room candidate, not certified Production replacement.
- New-main has authentication, tenant context, navigation, read models, delegated specialized writes, dashboard/search, owner/permission surfaces and no direct stock/financial DML.
- Open New-main gates: exhaustive parity, browser runtime, Service Worker runtime, authenticated Production E2E, concurrency proof and replacement authorization.
- Logical `main1..main11` artifacts are modules/contracts, never byte slices.

## CURRENT BUSINESS / ARCHITECTURAL CONTRACTS
- Sales channels converge into order/runsheet/fulfillment lifecycle.
- Physical stock authority: `post_stock_movement`.
- Reservation authority: `reserve_stock` / `release_stock_reservation`.
- Journal authority for inspected accounting paths: `post_journal_entry`.
- Dedicated customer/supplier/driver ledger writers exist.
- Sales, purchase receiving and loading inspected paths delegate physical movement to the canonical stock engine.
- Atomic/idempotent patterns exist in inspected sales, purchasing, journal and stock paths.
- Specialized PWAs remain responsible for POS, Telesales, Van Sales, Purchasing/Receiving, Picking, Loading, Delivery, Returns and Stock Vouchers.

## HISTORICAL SOURCE STATUS
- `rawaie-erp-review/main` is historical architecture/contract/forensics evidence.
- Historical documents establish the PWA + Supabase + Edge + PostgreSQL architecture and business workflows.
- Historical reports may explain why behavior exists but do not override current Production truth.

## MEMORY 117-02
- `Current/CTO/RAWAEA_PROJECT_MEMORY_117-02.md` was created from the reconciled current truth plus explicitly classified historical contract evidence.
- It records business domains, architecture, current Production writers/deployments, tenant model, security findings, performance findings, historical evolution, incidents/antipatterns, open closure units and future boot rules.
- It does not claim exhaustive all-function consumer proof or Production readiness.

## KNOWN INCIDENT / ANTIPATTERN MEMORY
- Report != current truth.
- Historical PASS != current PASS.
- CI PASS/Migration PASS != Production PASS.
- Git source != deployed code unless lineage is proven.
- Do not create duplicate physical-stock writers.
- Do not repair financial anomalies without provenance and audit/downstream analysis.
- Do not use `LIMIT 1` to conceal company-scoped ambiguity.
- Do not treat active test/canary function deployment as a business consumer.
- Do not byte-slice logical PWA modules.
- Do not replace Main before parity and runtime certification.

## FORBIDDEN ACTIONS — ACTIVE
- No blind Production DDL/DML.
- No Production business-logic patch solely to satisfy CI.
- No direct Physical Stock writer outside canonical engines.
- No direct financial mutation from New-main.
- No deletion of unknown legacy artifacts.
- No credential/token use merely because exposed in historical workflow source.
- No replacement of `Current/PWA/main.html` without complete evidence.

## LAST VERIFIED EVENT
- Event ID: `LVE-2026-08-31-014`
- Event Type: `CURRENT_STATE_UPDATE_AFTER_MEMORY_LEDGER_CREATION`
- UTC: `2026-08-31T17:21:00Z` (execution window)
- Source: direct GitHub current repository
- Git SHA: `0bd48099d6263c520daa903f6883e0670cef1502`
- Production State: `ACTIVE_HEALTHY` (last fresh verified Production state)
- Action: updated `CURRENT_STATE.md` immediately after creating the governed 117-02 memory ledger, recording the new memory artifact and preserving the current production/security gates.
- Result: `CURRENT_STATE SYNCHRONIZED WITH MEMORY LEDGER`
- Evidence: memory ledger commit `0bd48099d6263c520daa903f6883e0670cef1502`; prior state reconciliation commit `2b13a6cc50d44cd7a12acc8a61524bedd5502349`.
- Impact: `CURRENT_STATE.md` now points future assistants to the permanent memory ledger while retaining explicit Production blockers and non-authorized actions.
- Next Authorized Action: deepen the memory through exhaustive consumer/function/deployment lineage and controlled two-tenant security proof; do not apply Production security migrations until that proof exists.

## CURRENT CLOSURE STATUS
`CURRENT_STATE = SYNCHRONIZED`
`MEMORY_GOVERNANCE_117_02 = ACTIVE`
`PROJECT_MEMORY_LEDGER = CREATED`
`PRODUCTION_HEALTH = ACTIVE_HEALTHY`
`TENANT_SECURITY = P0_OPEN`
`DIRECT_GRANT_LEAST_PRIVILEGE = OPEN`
`SECURITY_ADVISOR_FINDINGS = OPEN`
`CONSUMER_GRAPH = PARTIAL / OPEN`
`DEPLOYMENT_LINEAGE = PARTIAL / OPEN`
`INVENTORY_WRITER_EXCLUSIVITY = PARTIAL / OPEN`
`LEDGER_WRITER_EXCLUSIVITY = PARTIAL / OPEN`
`NEW_MAIN = CANDIDATE / NOT_PRODUCTION_REPLACEMENT`
`PRODUCTION_ENGINEERING = BLOCKED_UNTIL_READINESS_GATES`
