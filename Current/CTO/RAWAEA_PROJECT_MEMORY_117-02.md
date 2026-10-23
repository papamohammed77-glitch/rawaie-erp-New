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


## 23. LAST VERIFIED MEMORY EVENT — LVE-2026-10-23-473
- Scope: Loader/Picker runsheet preview parity; owner-only patch to Picker.
- Current Loader SHA: `97b83d68a683df77c1e0557838c24a1b4fb65169`; current Picker SHA: `d483bd15b36585b975b63c2ef641481a01d5d084`.
- Fresh direct Production SQL: items.description and items.image_url exist; run_sheet_details.description is absent; item and runsheet FKs are present; current status count is Picked=2.
- Defect: Picker preview remains abbreviated and uses `.select('*')`; description must be sourced through `items!run_sheet_details_item_id_fkey(description)`. Active Picking session mapping needs the matching one-line nested-description correction.
- Complete surgical owner changeset is Report471 Patches A/A2/B/C/D. Report472 is historical pointer only where it defers to earlier reports; Report471 contains complete replacement blocks.
- No operational source or Production/business data was changed. No synthetic Production data was created or deleted. The memory file itself was restored from the immediately preceding commit after an empty-content write, then this event was appended.
- Status: OWNER PATCH READY / DEPLOYMENT + BROWSER E2E UNVERIFIED / NOT CLOSED.
- Next exact action: re-fetch Picker and verify SHA, apply only missing Report471 patches, deploy using the existing frontend path, verify served HTML and Browser E2E, and confirm inventory/reservations remain unchanged.
- Report: `doc/Draft/Reprots/Report473_PICKER_PREVIEW_PARITY_SESSION_REVALIDATION_20261023.md`.


## 24. LAST VERIFIED MEMORY EVENT — LVE-2026-10-23-474
- Target: Loader/Picker runsheet preview parity. Fresh source SHA Loader `97b83d68a683df77c1e0557838c24a1b4fb65169`; Picker `d483bd15b36585b975b63c2ef641481a01d5d084`.
- Loader current refactor commit: `152e5b1d22aab94d2cf01070778b357df4701aff`, parent `e69c9af4b56d99ba29a4fa74282f78438b9f7010`. It changes the preview to responsive inline summary/cards and event-bound buttons; therefore Report471 Patch B is visually stale and Report474 Patch B supersedes it.
- Fresh direct Production SQL: items.description/image_url exist; run_sheet_details.description absent; expected item and runsheet FKs exist; current runsheet count status Picked=2 only.
- Confirmed Picker defects: abbreviated preview; no joined description; active session reads nonexistent detail.description; inline onclick interpolates DB values; unsafe image/detail HTML interpolation.
- Owner surgical patches are A/A2/B/C/D in `doc/Draft/Reprots/Report474_PICKER_PREVIEW_PARITY_REBASE_AFTER_LOADER_REFACTOR_20261023.md`. No operational source or Production schema/data changes were made. No test rows were created/deleted.
- Status: OWNER PATCH READY / SOURCE + DB CONTRACT VERIFIED / DEPLOYMENT + BROWSER E2E UNVERIFIED / NOT CLOSED.
- Next: re-fetch Picker, verify SHA, apply only missing patches from Report474, test syntax and Staging E2E; confirm no stock/reservation changes; verify Cloudflare served HTML before closure.

- Report474 self-audit: Picker has no `RW_UI` namespace, so the patch now uses a local `formatPreviewNumber()`; image URL regex literals were corrected and re-fetched. Latest Report474 commit `68d6e9555219d0c41a32145f1fbc74131a410ae7`, blob `c9025663f8ee0bb79bc2e88ae6242be38d00f25c`.



## 25. LAST VERIFIED MEMORY EVENT — LVE-2026-10-23-475
- Scope: consolidated CTO re-investigation of Loader/Picker runsheet preview parity; owner-only operational source changes.
- Source repos separated: actual app source is `papamohammed77-glitch/erp-frontend` on `main`; this repository is continuity/governance/reporting. Historical reports are references, not current truth.
- Fresh app source: Loader `companies/company-1/warehouse/loader.html` SHA `97b83d68a683df77c1e0557838c24a1b4fb65169` (332 lines); Picker `companies/company-1/warehouse/picker.html` SHA `d483bd15b36585b975b63c2ef641481a01d5d084` (1058 lines). Neither operational file changed.
- Current Loader preview refactor: commit `152e5b1d22aab94d2cf01070778b357df4701aff`, parent `e69c9af4b56d99ba29a4fa74282f78438b9f7010`. Picker history reviewed for session recovery, Idempotency-Key/operation id, quantity validation, and insufficient-stock handling; preserve these contracts.
- Production SQL read-only snapshot at 2026-10-23 12:24:37 UTC: PostgreSQL 17.6; items=18, run_sheet_details=12; items.description/image_url exist; run_sheet_details.description absent; item_id FK and runsheet_id FK present; status count Picked=2 only, no Open/Confirmed rows in the queried counts. No DDL, RLS/RPC/Edge, or business-data writes; no test rows created/deleted.
- Confirmed root causes in Picker: abbreviated preview; detail query omits joined item description; active session reads absent detail.description; inline onclick interpolates DB values; unvalidated image src and unescaped item detail HTML.
- New self-contained current owner changeset: `doc/Draft/Reprots/Report475_PICKER_PREVIEW_PARITY_CONSOLIDATED_CTO_EXECUTION_20261023.md`, report commit `53ec7826a121ef5c8767c3fb7f1b4ce7059d0ff2`, report blob `496e18243085101728fba7f15870d72b33927943`. Includes patches A/A2/B/C/D, complete replacements, bounded scope, tests and rollback. Its JS blocks B/C/D were syntax-parsed successfully. Report474 Patch D had ambiguous/broken escaping around inline onerror; do not carry that historic block forward.
- Production and deployment state: source patch not applied; Cloudflare served HTML and browser E2E unverified; current production runsheets do not offer Open/Confirmed test cases. No operational source was edited. Status: ROOT CAUSE VERIFIED / OWNER PATCH READY / NOT DEPLOYED / NOT CLOSED.
- Next exact step: owner re-fetches Picker and checks SHA. If unchanged, apply patches A→A2→B→C→D from Report475 only; test in Staging, validate syntax/UX/auth/company boundaries and unchanged stock/reservations, then compare served Cloudflare HTML and run authenticated browser E2E. Do not edit Loader, main.html, or core.js for this display issue. Do not change Production for this task.
