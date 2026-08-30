# RAWAEA ERP — P0 Forensic Execution Log — 2026-08-30

## Governing command
MASTER EXECUTION PROMPT.md (SHA 528bb4e5f7ce7e9c40a04981ae84aa501eb2b260)

## Start state
- Git main re-read directly from GitHub.
- Production Supabase re-read directly from PostgreSQL.
- Current/PWA/main parts inspected directly.
- Prior reports and prior completion claims were not accepted as operational truth.

## Confirmed Production facts at execution start
- Production currently contains 1 company, 2 branches, 17 items, 20 stock rows, 0 orders, 0 purchase_orders, and 1 category at the forensic snapshot used for this closure.
- Production contains current PostgreSQL functions including complete_return_atomic and complete_order_delivery_atomic.
- Physical stock core function post_stock_movement is present.
- stock_branches has no company_id; item_code is globally UNIQUE on items.
- stock_vouchers is company-scoped and has an audit trigger; audit trigger function records actor from JWT with system fallback.

## Confirmed Git facts
- Current/PWA/main is physically split into source parts and main2.md is a source fragment, not a standalone deployable application.
- Current/PWA/main1.md exposes the shared RW_ShellContext.getCompanyId() tenant contract.
- main2.md pre-change blob SHA was 45d5e760a4b53e3be574346e3d9d192dbad309af.
- main2.md was read from its complete blob and then re-opened in bounded chunks through EOF before modification.

## P0 status
FORENSIC SOURCE CLOSURE EXECUTED — GLOBAL P0 PHASE STILL OPEN.

## Event: MAIN2-20260830-001
DATE: 2026-08-30 UTC
SOURCE: CURRENT GIT + DIRECT PRODUCTION POSTGRESQL + DIRECT FILE INSPECTION
OBJECTIVE: Repair Current/PWA/main/main2.md in place under the governed tenant-scope contract.

INPUT STATE:
- main2.md pre-change SHA: 45d5e760a4b53e3be574346e3d9d192dbad309af.
- Production baseline re-read immediately before implementation.

HISTORICAL CONTRACT:
- Understand historical/architectural context before modification.
- Production supersedes stale reports for current-state claims.
- PWA/reporting source must not become an independent Physical Stock writer.
- Tenant identity must come from the authenticated/shared company context, not a global settings row.

CURRENT PRODUCTION FACT:
- Current snapshot is one active data context with two branches and 17 items.
- No current orders or purchase orders were present, so no production transaction test was fabricated or persisted.

CURRENT GIT FACT:
- main2 was unscoped in several reporting reads while main1 already exposed shared tenant context.
- main2 itself contains no direct stock_branches mutation or inventory_log insertion.

CURRENT EVIDENCE:
- Global Dashboard reads existed for orders, purchase_orders, customers, and items.
- order_details has no company_id and was queried globally.
- stock_branches has no company_id and therefore must be constrained by company-owned branch IDs.
- Movement voucher/category/barcode reads also lacked consistent tenant scoping.

DISCOVERY:
- main2 inherited a legacy broad-read pattern rather than consuming the governed tenant context.

ROOT CAUSE:
- Source fragment predates the current shared tenant-scope convention.

BUSINESS IMPACT:
- Potential cross-tenant reporting disclosure under broad read policies.

ARCHITECTURAL IMPACT:
- main2 now depends on the shared Shell tenant identity and remains a read/report capability.

DATABASE IMPACT:
- No Production business rows were changed by this closure.

EDGE/RPC IMPACT:
- None. Existing mutation capabilities were not rewritten as part of this source closure.

FRONTEND IMPACT:
- Dashboard, item inventory, movement reports, category selection, and barcode lookup reads are now explicitly tenant scoped.

CHANGE MADE:
- Added fail-closed _rwCompanyId() backed by RW_ShellContext.getCompanyId().
- Added company_id scope to Dashboard order, previous-period order, purchase, customer, and item reads.
- Added id/customer_name to Dashboard order projection so top-customer reporting has the fields it actually consumes.
- Reworked top-item lookup to use tenant-scoped order IDs before querying order_details.
- Reworked stock matrix loading to query stock_branches only for current company branch IDs.
- Added company scope to stock voucher movement report reads.
- Added company scope to branch movement voucher reads.
- Added company scope to categories, category-delete checks, and barcode item lookup.
- Preserved existing mutation routing; no direct Physical Stock writer was introduced.
- Added MAIN2_GOVERNED_CLOSED:v1 marker.

WHY:
- Align main2 with the current authoritative tenant contract without inventing a second tenant source or rebuilding the module.

ALTERNATIVES REJECTED:
- Global app_settings LIMIT 1 inference.
- New independent tenant-context state in main2.
- Direct stock_branches mutation from PWA.
- Rebuilding the module from scratch.

MIGRATION:
- Source-only change; no Production schema migration.

DEPLOYMENT:
- Git main source commit only. main2 itself has no standalone deployment target.

COMMIT:
- main2 repair commit: b3ec4ae8da1622f0e3d3ef1cb0995fb7a66e2135.
- Temporary executor cleanup commits followed; current source remains on main.

TEST:
- Exact pre-change blob guard was used in the intended executor path.
- Structural invariant checks defined for tenant scoping and direct stock-writer absence.
- Node --check and git diff --check were part of the governed execution path; the repository Actions route did not reach a successful job, so these CI checks are not independently claimed as Production runtime evidence.

RUNTIME TEST:
- Not applicable as a standalone runtime: main2 is a source fragment.

PRODUCTION VERIFY:
- Production schema/function baseline was read immediately before source change.
- Production data counts remained a no-business-data-change baseline for this source closure.

DATA CLEANUP:
- No business data cleanup performed.
- Temporary execution workflow/script artifacts were removed where the GitHub tool permitted; one temporary trigger file remains pending tool-level write authorization and is explicitly not considered part of the intended product state.

AUDIT PRESERVATION:
- No audit triggers or historical audit rows were modified.

POST-CHANGE STATE:
- main2 now contains governed tenant context and the closure marker.

OBSOLETE STATE:
- The earlier claim that main2 had not been repaired is obsolete after commit b3ec4ae8da1622f0e3d3ef1cb0995fb7a66e2135.

WHAT I PROVED:
- Current Production was freshly inspected before the source repair.
- main2 was inspected from the complete pre-change blob and bounded through EOF.
- The repaired source contains explicit tenant scoping in the identified critical reads.
- main2 remains free of direct stock_branches and inventory_log writes by design.
- The repair was committed to Git main.

WHAT I DID NOT PROVE:
- An independent browser runtime verification of the assembled main application after integrating main2.
- Full RLS-policy semantics across every affected read path.
- Closure of unrelated backend inventory writer units.

WHAT I CHANGED:
- main2.md only, plus this execution ledger.

WHAT I DID NOT CHANGE:
- No Production business data.
- No stock quantities.
- No Edge/RPC business logic in this closure.
- No audit trigger implementation.

WHAT I DISCOVERED:
- Historical Production counts from older reports were stale versus current Production.
- main2 had a real tenant-read gap even though it was not a stock writer.

WHAT I INITIALLY MISSED:
- The top-customer projection in the legacy query did not include customer_name although the renderer consumed it.
- stock_branches cannot be company-filtered by a nonexistent company_id and must be scoped through company-owned branch IDs.

WHAT BECAME OBSOLETE:
- Prior reports asserting the old main2 blob as current truth.

WHAT REMAINS OPEN:
- Integrated main.html/browser runtime verification for the assembled application.
- Remaining P0 backend Writer Closure Units.
- Final global forensic sweep and governance residue check.

WHAT COULD STILL BE WRONG:
- A non-obvious consumer or RLS policy could impose behavior not visible from the source fragment alone.
- Current main2 formatting was normalized during direct replacement; functionality was preserved by targeted source reconstruction, but a full semantic diff against the original line-by-line should be performed in the integrated validation phase.

PRODUCTION DEPLOYED?
- No standalone main2 deployment exists. Source change is deployed to Git main only.

PRODUCTION RUNTIME VERIFIED?
- NO — not independently verified for assembled main runtime in this closure.

AUDIT VERIFIED?
- Database audit trigger path was inspected; no runtime audit event from main2 source was generated because no production business mutation occurred.

DATA VERIFIED?
- YES for no-business-data-change baseline at the Production snapshot level used by this closure.

CURRENT GIT ALIGNED?
- YES for main2 source and this ledger at the end of the direct Git writes. Temporary executor files were removed except the explicitly noted trigger artifact pending tool authorization.

FINAL CLOSURE STATUS
MAIN2 SOURCE TENANT-SCOPE CLOSURE = CLOSED.
GLOBAL INVENTORY P0 = NOT CLOSED.
Integrated browser runtime = OPEN.

## Trigger / Governance Note
A prior no-business-data-change workflow attempt for this closure failed before job execution; it does not count as a successful implementation or verification. The authoritative implementation is the direct Git commit above, followed by direct post-write inspection.

## Rule
Any future correction must reopen CURRENT PRODUCTION + CURRENT GIT + HISTORICAL CONTRACT before modification. No prior report or memory snapshot may be treated as current truth.
