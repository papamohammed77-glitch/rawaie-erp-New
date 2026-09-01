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
- Latest verified HEAD at the latest reconciliation event: `e8da572a5b42a407c4d5f8d7493b9e4fe134f663`
- Production: Supabase `SMART ERP`, ref `fiilmooggumokxanwiyx`
- Staging: Supabase `rawaea-staging`, ref `hfzznsiprnwkpayskzhu`

## 3. MASTER COMMAND ADOPTION
The full `doc/Draft/medhat/MASTER - RAWAEA ERP.md` command was read end-to-end through section 60.
Its operating loop is mandatory:
`CURRENT_STATE -> LAST VERIFIED EVENT -> current reality -> reconcile -> identify target -> resolve critical unknowns -> trace owner/dependencies -> surgical change -> verify -> deploy/runtime verify -> CURRENT_STATE update -> reassess`.
It explicitly rejects historical-stage control, percentage-based control, artificial workflows/executors, duplicate architecture, report-only closure, and invented completion claims.

## 4. CURRENT BOOT / RECONCILIATION MEMORY
- Previous `CURRENT_STATE.md` states were repeatedly reconciled when Git advanced beyond the recorded checkpoint.
- The last confirmed commit that actually modified `Current/PWA/New-main` is `a4551e0fcfc55fd609f48109407c025b44e20641`.
- Comparing `a4551e0...` to current `e8da572...` shows no later New-main target modification; later commits primarily changed workflows, builders/parsers, prompt/reporting and verification infrastructure.
- A later documentation commit `a2092863...` renamed/normalized the master command file and did not modify Production.

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

## 6. CURRENT SECURITY / AUTHORIZATION EVIDENCE
Fresh Production privilege/RLS inspection confirmed:
- `orders` broad authenticated `ALL` policy plus broad store/anon insert paths.
- `order_details` broad authenticated `ALL` policy.
- `run_sheet_details` broad authenticated `ALL` policy.
- `daily_settlements` public `ALL` with `true/true`.
- Seven observed externally executable `SECURITY DEFINER` functions include vehicle context/guard functions, `create_vehicle_atomic`, `fn_vehicle_audit_trigger`, and `get_budget_vs_actual`.
- Auth leaked-password protection is disabled according to Security Advisor.
- Performance Advisor reports unindexed FKs, RLS init-plan inefficiencies, multiple permissive policies and unused indexes.
These findings are evidence-backed security/governance blockers, not permission for blind Production mutation.

## 7. STAGING OBSERVATION
Direct staging SQL observed one company. Therefore staging is not a two-company proof environment and cannot by itself prove tenant isolation.

## 8. BUSINESS DOMAIN MEMORY
### Sales
Channels include POS, Telesales, Order Taker, Van Sales and Online Store. Sales orders feed runsheet/fulfillment and may result in delivery, return, settlement and financial/ledger effects.

### Procurement
`Purchase Order -> Receiving -> Physical Stock -> Journal -> Supplier Ledger` through the inspected `receive-purchase -> receive_purchase_atomic` path.

### Warehouse / Fulfillment
`Runsheet -> Picking -> Loading -> Delivery/Return/Unloading`. Picking is reservation-oriented; loading/unloading inspected paths use the central physical-stock engine.

### Inventory
`stock_branches.qty` is physical quantity; `allocated_qty` is reservation state. `post_stock_movement` is the inspected physical movement authority.

### Accounting / Ledgers
`post_journal_entry` is the inspected journal core. Dedicated customer/supplier/driver ledger writers exist. Full writer exclusivity remains open.

## 9. CURRENT ARCHITECTURE MEMORY
- Multi-PWA frontend remains the current operational architecture.
- `Current/PWA/main.html` is protected from replacement.
- `Current/PWA/New-main` is the sole authorized clean-room candidate.
- `main1..main11` are logical modules/contracts, not byte slices.
- Authenticated identity maps through `public.users.auth_id -> users.company_id`.
- `app_private.current_user_company_id()` is the DB tenant resolver.
- Specialized PWAs delegate business writes to Edge/RPC/Core owners.
- Duplicate Physical Stock writers are forbidden.

## 10. HISTORICAL INVENTORY MEMORY
Historical rescue evidence established the Inventory writer boundary around `post_stock_movement(10)`, separated reservation engines, and constrained legacy application execution. This was an Inventory boundary closure, not ERP-wide closure.
Historical Receive contract: cumulative `received_qty`; partial Receive remains Sent; full becomes Received; reject over-remaining; preserve allocation; one history row per physical movement; atomic transaction.

## 11. CURRENT CONSUMER MEMORY
Representative paths:
- Telesales/Main -> `save-sales-invoice` -> `save_sales_invoice_atomic`.
- Purchase receiving -> `receive-purchase` -> `receive_purchase_atomic`.
- Loading -> `complete-loading` -> `complete_runsheet_loading`.
- Voucher UI -> voucher Edge/Core paths.
- New-main -> specialized PWA/Edge/Core owners for operational mutations.
Full all-consumer graph remains unproven.

## 12. DEPENDENCY GRAPH RECONCILIATION
`Current/CTO/20260831_PHASE5_SYSTEM_DEPENDENCY_GRAPH.md` previously claimed `CLOSED` while admitting the full runtime graph was not proven. Under the Master Command this was inconsistent; it was corrected to `PARTIAL / OPEN` in commit `50b40e6b7d8d0f0ddc29dc6681fac8059cc5e110`.

## 13. DEPLOYMENT LINEAGE MEMORY
The complete chain
`Git SHA -> source file -> artifact/package -> Production version -> runtime consumer -> runtime evidence`
remains only partially proven. Deployment existence/version does not establish consumer use or runtime correctness.

## 14. NEW-MAIN / MAIN1 MEMORY — CURRENT
MAIN1 current/original contract evidence is verified. The New-main target at `a4551e0...` contains substantial shell/auth/tenant/navigation/permission/notification/workflow/audit surfaces, but closure is not established.

Verified remaining contract gaps:
- Owner calculation currently permits `owner_profile` existence to make `isOwner=true`; governing contract requires Auth metadata to establish owner semantics and preserves wildcard permissions.
- New-main contains only a lightweight `RW_OwnerLicense` object; full MAIN10 license-management UI/save/email/password contract is not present.
- Notification implementation lacks exact MAIN1 `_clickNotif`, `_renderAndSave`, `_updateBadge`, `markRead` behavior and related-record navigation.
- Audit rendering is simpler than the full MAIN1 `RW_Audit_*` contract set.
- Session reset/fail-closed lifecycle proof is incomplete.
- Workflow rules are not explicitly company-scoped in the current target surface; impact needs contract proof before any Production policy decision.

A previous executor attempt `6b339cc...` modified tooling rather than safely closing the target and was later reverted. Parser/browser-gate commits such as `02da996...`, `9507d0...`, `455e287...`, and `c2c316...` improve execution infrastructure but are not target implementation evidence.

## 15. MAIN1 EXECUTION SAFETY RESULT
The Master Command requires actual target modification plus verification. The available GitHub write path for `Current/PWA/New-main` performs a complete monolithic file replacement. This execution environment did not provide a safe way to reconstruct and submit the full target bytes without risking unrelated content loss. Therefore no unsafe whole-file rewrite was performed.

This is a tooling safety limitation only. It is not a business or architectural blocker and not evidence of completion.

## 16. CURRENT ANOMALY MEMORY
Production anomalies requiring provenance remain:
1. One active/non-inactive `users` row without `auth_id`.
2. Two cancelled `VoidInvoice` journal headers with zero lines.
3. Three `VoidInvoice` inventory-log rows.
No deletion or synthetic repair without provenance, downstream impact and audit analysis.

## 17. INCIDENT / FAILURE MEMORY
Never repeat:
- report == current truth;
- historical PASS == current PASS;
- CI PASS == Production PASS;
- Git source == deployed code without lineage;
- executor change == target implementation;
- deployment existence == consumer proof;
- broad RLS/grants == intended authorization;
- duplicate physical-stock writers;
- destructive repair without provenance;
- byte-slicing logical PWA modules;
- compacting a rich application into a feature-loss candidate;
- patching Production solely to satisfy CI.

## 18. OPEN CLOSURE UNITS
1. Safe actual MAIN1 target modification in `Current/PWA/New-main`.
2. MAIN1 static contract validation after modification.
3. Browser/runtime verification of New-main.
4. Auth/Owner/license lifecycle proof.
5. Notification and audit behavior parity.
6. Full consumer graph and deployment lineage.
7. Two-tenant authorization harness/proof.
8. P0 tenant-isolation remediation plan.
9. Security Advisor remediation + regression suite.
10. Exhaustive journal/ledger/treasury writer matrix.
11. Data provenance for current anomalies.
12. Service Worker runtime proof.
13. Main replacement certification.

## 19. FORBIDDEN ACTIONS
- No blind Production DDL/DML.
- No direct Physical Stock writer outside canonical engines.
- No direct financial mutation from New-main.
- No deletion of unknown legacy artifacts.
- No credential/token use because exposed in historical workflow source.
- No Main replacement before evidence closure.
- No artificial workflow/executor/parallel architecture.

## 20. MEMORY OPERATING LOOP
1. Read `CURRENT_STATE.md` first.
2. Read latest `LAST VERIFIED EVENT`.
3. Verify Git HEAD.
4. Verify relevant Production state.
5. Compare with this ledger.
6. Mark stale/conflict.
7. Resolve critical unknowns.
8. Identify true current target.
9. Prove owner/dependencies/root cause.
10. Implement minimum safe target change.
11. Verify source/runtime/data/audit as applicable.
12. Update `CURRENT_STATE.md` immediately.
13. Record material knowledge here.
14. Reassess target after closure.

## 21. LAST VERIFIED MEMORY EVENT
- Event ID: `LVE-2026-09-01-004`
- Event Type: `MASTER_CONTINUITY_MEMORY_RECONCILIATION_FINAL`
- UTC: `2026-09-01T00:24:00Z` execution window
- Source: full MASTER command 0-60 + current Git history + direct New-main + MAIN1 + MAIN10 inspection + current Production evidence
- Git SHA: `e8da572a5b42a407c4d5f8d7493b9e4fe134f663`
- Production State: `ACTIVE_HEALTHY`
- Action: finalized the project-memory reconciliation after fully reading the Master command; verified the latest New-main target change, separated target implementation from later tooling changes, recorded the remaining MAIN1 gaps, and preserved the no-unsafe-write decision.
- Result: `MEMORY SYNCHRONIZED / MAIN1 OPEN / NO UNSAFE TARGET REWRITE`
- Impact: future CTO continuity starts from the actual latest repository state and will not repeat the reverted executor/false-closure path.
- Next Authorized Action: continue from the proven MAIN1 gaps using a safe full-file target-write path, then run structural, syntax, browser/runtime, authenticated and Production-compatibility verification before closure.

## 22. CURRENT EXECUTION POSITION
- Master continuity command: ACTIVE
- 117-02 memory governance: ACTIVE
- Current State: SYNCHRONIZED
- Production: ACTIVE_HEALTHY
- MAIN1 forensic contract: VERIFIED
- New-main MAIN1 parity: OPEN
- Target write: SAFETY LIMITATION
- Security: OPEN
- Consumer graph: PARTIAL / OPEN
- Deployment lineage: PARTIAL / OPEN
- New-main: candidate only
- Main replacement: unauthorized
