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
- Current HEAD before this state-only update: `a20928631202229cf9d1dc5ee4d67f10f06165b9`
- This update changes documentation/state only; no Production mutation was introduced.

## CURRENT PRODUCTION — FRESHLY VERIFIED
- Project: `fiilmooggumokxanwiyx`
- Name: `SMART ERP`
- Region: `eu-west-1`
- Status: `ACTIVE_HEALTHY`
- PostgreSQL: 17.6.1.121 / engine 17 / GA channel
- Fresh snapshot: 66 public tables, 76 public functions, 20 public triggers, 110 public RLS policies.
- Current business data: companies 1, users 24, branches 2, items 17, stock rows 20, inventory_log 3, orders 0, runsheets 0, journal_entries 2, journal_lines 0, customer_ledger 0, supplier_ledger 0, driver_ledger 0, daily_settlements 0, treasury 1.
- Authoritative identity path: authenticated user -> `public.users.auth_id` -> `public.users.company_id`.
- Database tenant resolver: `app_private.current_user_company_id()`.
- Physical-stock core: `post_stock_movement`.
- Inspected accounting/ledger cores: `post_journal_entry`, dedicated customer/supplier/driver ledger paths.

## CURRENT SECURITY / AUTHORIZATION FINDINGS — STILL OPEN
- `orders` has broad authenticated `ALL` policy and broad anon/authenticated INSERT paths.
- `order_details` has broad authenticated `ALL` policy.
- `run_sheet_details` has broad authenticated `ALL` policy.
- `daily_settlements` has public `ALL` with `USING true` / `WITH CHECK true`.
- Seven current SECURITY DEFINER functions were observed executable by anon/authenticated in the prior verified security snapshot.
- Auth leaked-password protection is disabled in the current Security Advisor snapshot.
- Performance Advisor reports unindexed FKs, RLS init-plan inefficiencies, multiple permissive policies and unused indexes.
- These are confirmed blockers/findings. No Production security mutation is authorized before consumer proof and a controlled multi-tenant harness.

## CURRENT ARCHITECTURAL CONTRACTS
- Sales channels: POS, Telesales, Order Taker, Van Sales, Online Store.
- Physical stock authority: `post_stock_movement`.
- Reservation authority: `reserve_stock` / `release_stock_reservation`.
- Journal authority: `post_journal_entry` for inspected accounting paths.
- Dedicated customer/supplier/driver ledger writers exist.
- Specialized PWAs remain owners for POS, Telesales, Van Sales, Purchasing/Receiving, Picking, Loading, Delivery, Returns and Stock Vouchers.
- `Current/PWA/main.html` remains protected.
- `Current/PWA/New-main` remains a candidate and is not authorized to replace `main.html`.

## MASTER CONTINUITY REVIEW — CURRENT SESSION
- `doc/Draft/medhat/MASTER - RAWAEA ERP.md` was read through the end of the command and its continuity rules were adopted for this session.
- Hytham `تقرير تنفيذي 1` and `تقرير تنفيذي 2` were reviewed as historical execution evidence only, not as current truth.
- Current `CURRENT_STATE.md` was re-read and found materially newer than the assistant's prior context; it correctly redirects the current target to security/consumer/deployment readiness rather than a historical numbered stage.
- `RAWAEA_PROJECT_MEMORY_117-02.md` was re-read and confirms the same current position.
- Direct Production SQL reconfirmed the canonical stock function structure: the 10-argument idempotent `post_stock_movement` is the physical-stock authority, while the 9-argument form is a compatibility wrapper; `post_manual_stock_voucher_atomic` is a SECURITY DEFINER wrapper around its core.
- Direct Production RLS inspection reconfirmed broad order/fulfillment policies and the open `daily_settlements` policy.
- Current `main1..main11` fragments remain logical contracts/modules, not byte slices.

## NEW-MAIN / GOLDEN FINDINGS
- The previously visible `Current/PWA/New-main` is an expanded clean-room candidate, not a certified replacement.
- Historical clean-room execution had previously passed syntax/structural gates and then failed Browser Smoke because the composed inline script was prematurely terminated by HTML parsing.
- A later experimental builder attempt on a branch failed at composition with `MAIN1_INLINE_SCRIPT_BLOCK_MISSING`; investigation showed that multiple builder/workflow lines exist and are not a single authoritative release path.
- The current `main` branch does not currently contain the experimental clean-room commits attempted during that prior round; the branch has reconciled back to the newer `a2092863...` state.
- The repository currently contains multiple historical CI workflows that run on every `main` push. Many fail for unrelated legacy gates; these failures must not be conflated with the Main replacement certification.
- The canonical `new_main_clean_room_20260831.yml` and older `master_reconstruction_forensic_20260830.yml` currently disagree on target/builder/contract expectations; this is a known workflow-lineage inconsistency requiring cleanup before any closure claim.

## CURRENT BLOCKERS — NO FALSE CLOSURE
1. Full consumer graph: `CONSUMER -> CAPABILITY -> EDGE -> RPC -> TABLE` is not exhaustively proven.
2. Full deployment lineage of critical writers is not cryptographically proven end-to-end.
3. Exhaustive Physical Stock writer exclusivity remains open beyond inspected paths.
4. Exhaustive journal/ledger/treasury writer matrix remains open.
5. No controlled two-company authorization harness currently exists in staging.
6. P0 tenant-isolation defects remain open in Production policies/grants.
7. Least-privilege grant/policy remediation remains blocked on consumer proof.
8. Security Advisor findings remain open.
9. Current auth-link anomaly and cancelled journal-header anomalies require provenance analysis before repair.
10. New-main browser/runtime parity is not certified.
11. Service Worker runtime proof is not certified.
12. Main replacement certification is not authorized.
13. Historical inventory-log provenance reconciliation remains open.

## KNOWN ANTIPATTERNS CONFIRMED THIS SESSION
- Treating a historical report as current truth.
- Treating a candidate/CI PASS as runtime/Production PASS.
- Using a stale workflow as the authority for a current artifact.
- Using a broad static gate that mistakes legitimate master-data CRUD (for example `treasury`) for transaction posting.
- Creating or retaining multiple competing builder/workflow paths for the same closure target.
- Modifying a candidate before the current target/ownership/consumer graph is proven.

## LAST VERIFIED EVENT
- Event ID: `LVE-2026-08-31-019`
- Event Type: `MASTER_CONTINUITY_FORENSIC_REVIEW_AND_CURRENT_TARGET_RECONCILIATION`
- UTC: `2026-08-31T18:00:00Z` (execution window)
- Source: direct GitHub current files + full Master command review + Hytham reports + direct Production SQL/RLS/function inspection
- Git SHA: `a20928631202229cf9d1dc5ee4d67f10f06165b9` (state before this documentation commit)
- Production State: `ACTIVE_HEALTHY`
- Action: re-entered the project from current truth; re-read the Master command end-to-end, reviewed the two historical execution reports, reconciled current Git/Production/Memory, verified stock-core and RLS contracts directly, classified the New-main/GOLD builder state, and identified workflow-lineage inconsistency and the actual current P0 security/consumer blockers.
- Result: `CURRENT TARGET = SECURITY + CONSUMER + DEPLOYMENT READINESS / NEW-MAIN REMAINS CANDIDATE`
- Impact: historical New-main reconstruction attempts are retained as evidence but are not treated as the active release path; Production mutation remains correctly blocked until readiness gates are satisfied.
- Next Authorized Action: prove the exhaustive consumer graph and deployment lineage, establish an authorized two-tenant non-production harness, then perform controlled security remediation and regression testing. Only after those gates are closed may New-main runtime/parity/replacement certification resume.

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
`GOLDEN_DIAMOND = NOT_CERTIFIED`
