# RAWAEA ERP — MAIN11 FORENSIC RECONSTRUCTION / CLOSURE RECORD

## EVENT ID
MAIN11-FORENSIC-20260830-01

## DATE
2026-08-30

## SOURCE
Current Git `main`; Current Production Supabase; Original/PWA/main/main11.md; historical governance prompts/reports 89–106.

## OBJECTIVE
Reconstruct `Current/PWA/main/main11.md` from verified current evidence, preserve public contracts and functionality, remove verified schema drift, and leave the fragment safe for eventual assembly into the single logical `main.html`.

## INPUT STATE
Current `main11.md` was already modified by a prior commit and therefore was treated as untrusted input. Production was independently queried before final decisions.

## HISTORICAL CONTRACT
The governing process requires: understand historical context → reconstruct contract → trace current behavior → trace data/auth/control flow → compare target → identify actual gap → minimal safe change → implement → verify. It explicitly rejects treating reports, memory, or assumptions as proof.

Main11 historical role:
- HR UI (`RW_HR`)
- CRM UI (`RW_CRM`)
- session restore / boot compatibility
- password reset compatibility
- QR invoice compatibility function
- user-table click compatibility
- no physical inventory/accounting writer responsibility

## CURRENT PRODUCTION FACT
Direct Production snapshot at `2026-08-30 07:11:56.77112+00`:
- companies: 1
- users: 24
- branches: 2
- items: 17
- customers: 3
- customer_followups: 0
- stock_branches: 20
- inventory_log: 3
- audit_log: 1866

Current Production `users` schema contains `permissions` but does not contain an `is_owner` column.
Current Production has one wildcard-permission owner record: role `مدير النظام`, permissions `["*"]`.
Current Production `customer_followups` has no `company_id` column. Its RLS policies delegate tenant isolation to `app_private.customer_belongs_to_current_company(customer_id)`.
`items.item_code` is globally UNIQUE in the current schema.

## CURRENT GIT FACT
Before reconstruction:
- main11 blob: `6648a5b230e03e7e8db0351030e830969bb45bb0`
- latest HEAD at investigation start: `0cfce694ebc1d3563738828e25dc21bf78937239`
- main10 router consumes `RW_HR.render` and `RW_CRM.render`.
- main1 owns the canonical `RW_ShellContext` and `RW_Data.loadCustomers` contracts.

After reconstruction:
- main11 blob: `80585c51062efc61a1566b8236927f3e6a70ceda`
- final source commit: `f5d5894c1c0089c4e9a7c47796561e5a2cae3c6f`

## HISTORICAL / ORIGINAL FACT
Original main11 (`cad8bafa94da839ffb3a61f1a4581f52b98289f4`) used unscoped users reads, direct customer/followup operations, and the same public compatibility surface. Historical reports 89–106 were used as context only and not as current truth.

## DISCOVERY
1. Current main11 selected `users.is_owner`, but that column is absent from Production.
2. Current main11 HR needed to preserve owner invisibility without inventing a schema field.
3. Current main11 CRM already followed tenant-safe customer resolution; this was retained and hardened.
4. Current main11 boot was made repeat-safe to protect against duplicate event binding in a fragmented assembly context.
5. Current main11 owns no physical-stock writer and no new database writer responsibility.

## ROOT CAUSE
Schema drift: a frontend fragment referenced a field not present in the live `users` schema. The prior implementation was therefore not production-safe despite having valid tenant scoping around the query.

## BUSINESS IMPACT
Without correction, the HR tab could fail its user query entirely. Owner visibility semantics could also be lost or implemented by unsafe role guessing.

## ARCHITECTURAL IMPACT
No business engine ownership changed. Main11 remains presentation/orchestration/UI compatibility only. Tenant authority remains in `RW_ShellContext` from main1.

## DATABASE IMPACT
No Production data or schema was changed by the main11 reconstruction. The implementation was aligned to existing Production schema rather than altering Production to satisfy the fragment.

## EDGE/RPC IMPACT
None for main11.

## FRONTEND IMPACT
- HR query now requests only verified current Production columns.
- Owner hiding preserves the established wildcard/identity contract.
- HR/CRM rendering gains stale-load protection.
- CRM customer resolution remains company-scoped.
- Boot/event registration is idempotent within the fragment.
- Existing public names and function surfaces are preserved.

## CHANGE MADE
Rewrote `Current/PWA/main/main11.md` from scratch as a governed fragment.

Public compatibility preserved:
- `window.RW_HR`
- `RW_HR.render`
- `RW_HR._openModal`
- `window.RW_CRM`
- `RW_CRM.render`
- `RW_CRM._filterCustomers`
- `RW_CRM._openFollowupModal`
- `window.resetPassword`
- `window.generateQRInvoiceBase64`
- DOMContentLoaded boot behavior
- `RW_Users._openModal` user-table compatibility listener

## WHY
The rewrite removes the proven schema defect without adding database debt or changing responsibility boundaries.

## ALTERNATIVES REJECTED
- Adding `is_owner` to Production solely to satisfy the old fragment: rejected because it changes schema for a UI assumption and conflicts with the existing owner contract.
- Inferring owner solely from `role = مدير النظام`: rejected because ordinary administrator roles must not be treated as owner without the wildcard/owner semantics.
- Deploying the fragment independently as production `main.html`: rejected because main11 is only one fragment and independent deployment would violate the assembly architecture.
- Creating new CRM company_id storage for followups: rejected because current Production already provides RLS tenant isolation through the customer relationship.

## MIGRATION
None for main11. No database migration required.

## DEPLOYMENT
Git source deployed to `main` through commit `f5d5894c1c0089c4e9a7c47796561e5a2cae3c6f`.
Production application deployment was intentionally NOT performed because main11 is a fragment and is not a standalone production artifact.

## COMMIT
`f5d5894c1c0089c4e9a7c47796561e5a2cae3c6f`

## TEST
Local JavaScript syntax validation: PASS (`node --check`).
Static contract validation: PASS.
Verified preservation of required public functions: PASS.
Verified no physical-stock writer references in executable fragment: PASS.

## RUNTIME TEST
Integrated browser runtime was not executed because this task intentionally changes only a fragment and the complete application is assembled from multiple parts later. Claiming integrated runtime PASS here would be false evidence.

## PRODUCTION VERIFY
Production schema was queried directly before reconstruction. No main11 database deployment occurred, so there was no Production data mutation to re-verify.

## DATA CLEANUP
No Production data cleanup was performed by this main11 task. This is intentional; there was no proven main11-owned data defect requiring mutation.

## AUDIT PRESERVATION
No Production rows were changed. Existing audit state therefore remains preserved.

## POST-CHANGE STATE
- Main11 source is tenant-aware.
- HR references only current schema fields.
- CRM resolves customers inside the active company before followup access.
- Event/boot registration is repeat-safe.
- Existing public contracts remain present.
- Fragment contains no physical stock engine.

## OBSOLETE STATE
The prior HR dependency on a non-existent `users.is_owner` field is obsolete.

## REMAINING OPEN ITEMS
No main11 source defect remains identified by current evidence.
Integrated whole-application browser/runtime verification remains intentionally deferred to the final multi-fragment assembly stage; it is not a main11 source defect.

## LATER CORRECTIONS
If final assembly reveals an interaction defect, it must be traced against the assembled `main.html` and not retroactively inferred from this fragment in isolation.

## CURRENT SURVIVING STATE
`Current/PWA/main/main11.md` is the canonical current source fragment for main11.

## SOURCE REFERENCES
- Governance: `doc/Draft/medhat/تقرير مبادئ حاكمة`
- Master execution directive: `doc/Draft/medhat/MASTER EXECUTION PROMPT.md`
- Historical prompts/reports: `doc/Draft/medhat/برومبت 89+ملحق تقرير`, `برومبت 90+تقرير`, `برومبت 91+ملحق تقرير`, `برومبت 92+ملحق تقرير`, `تقرير 93`, `تقرير 94`, `تقرير 95`, `تقرير 96`, `تقرير 97`, `تقرير98`, `تقرير 99`, `تقرير 100`, `تقرير 101`, `تقرير 102`, `تقرير103`, `تقرير 104`, `تقرير 105`, `تقرير 106`
- Current integration consumers: `Current/PWA/main/main10.md`, `Current/PWA/main/main1.md`, `Current/PWA/core.js`
- Historical original: `Original/PWA/main/main11.md`

# PRE-SWEEP SELF-AUDIT

Business Understanding: CONFIRMED for main11 responsibilities and consumers.
Architecture Understanding: CONFIRMED for fragment boundary and main1/main10 integration.
Database Understanding: CONFIRMED for users/customer_followups/schema/RLS relevant to main11.
Historical Understanding: CONFIRMED for original main11 and governing historical records reviewed.
Current Git Understanding: CONFIRMED against current main branch and current blob.
Current Production Understanding: CONFIRMED by direct live query and schema inspection.
Deployment Understanding: CONFIRMED; fragment source can be committed, but standalone Production deployment is unsafe.
Runtime Understanding: PARTIAL; integrated browser runtime is outside a safe fragment-only execution boundary.

Confirmed Facts: listed above.
Unknowns: integrated final main.html runtime after eventual assembly.
Conflicts: prior main11 used a non-existent HR schema column; resolved in source.
Unverified Claims: no claim of integrated Production browser PASS is made.

Production Opened: YES.
Current Git Opened: YES.
Historical Opened: YES.
Schema Checked: YES.
Triggers Checked: YES for relevant adjacent audit path; no customer_followups trigger found.
RLS Checked: YES for customer_followups and relevant company-scoped tables.
Permissions Checked: YES for current owner wildcard semantics and router contract.
Consumers Checked: YES.
Dependencies Checked: YES.
Git History Checked: YES for main11/current-head lineage used during this task.

# FINAL SELF-AUDIT

WHAT I PROVED
- The current Production `users` schema does not expose the field used by the previous main11 HR query.
- Current Production has one wildcard-permission owner record and current owner role `مدير النظام`.
- `customer_followups` is tenant-isolated by RLS through the customer code relation.
- main10 directly consumes the public main11 HR/CRM render contracts.
- main11 can operate without owning any physical stock engine.
- The reconstructed source parses successfully and preserves the required public surface.

WHAT I DID NOT PROVE
- Full browser execution of the final assembled application.
- Production browser runtime for a future merged `main.html`.

WHAT I FIXED
- Removed the invalid HR schema dependency.
- Added governed owner detection using verified current semantics.
- Preserved company-scoped CRM resolution.
- Added fragment-safe event/boot guards and stale-load protection.

WHAT I INITIALLY MISSED
- The current Production `users` schema had no dedicated owner flag while the prior fragment queried one.
- Static scanning can be fooled by explanatory comments; executable-source checks were therefore rerun after the comment cleanup.

WHAT BECAME OBSOLETE
- Dependency on the absent HR owner-flag column.

WHAT REMAINS OPEN
- Only integrated runtime verification at final assembly, not a source defect in main11.

WHAT COULD STILL BE WRONG
- An interaction defect can only be proven or disproven after all fragments are assembled and executed together.

PRODUCTION DEPLOYED? NO — intentionally not standalone-deployed.
PRODUCTION RUNTIME VERIFIED? NO — final integration required.
AUDIT VERIFIED? YES — no Production data changes occurred.
DATA VERIFIED? YES — relevant live schema/data facts directly queried.
CURRENT GIT ALIGNED? YES — canonical main11 source committed to `main`.

# FINAL CLOSURE STATUS
MAIN11 SOURCE CLOSURE = 100% COMPLETE
MAIN11 DATABASE CHANGE = NONE REQUIRED
MAIN11 PHYSICAL STOCK WRITER = NONE
MAIN11 TENANT SCOPING = GOVERNED
MAIN11 SCHEMA ALIGNMENT = CLOSED
INTEGRATED APPLICATION RUNTIME = DEFERRED TO FINAL ASSEMBLY BY DESIGN
