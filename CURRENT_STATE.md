# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- CURRENT_STATE is the operational checkpoint.
- LAST VERIFIED EVENT is authoritative for recency.
- Historical reports/prompts are evidence only; Production and Git are current truth.
- Existing `Current/PWA/main.html` is NOT a repair target in this task.
- This task targets only the clean-room artifact `Current/PWA/New-main`.

## CURRENT GIT
- Repository: `papamohammed77-glitch/rawaie-erp-New`
- Branch: `main`
- Current HEAD at the last verified execution event: `688673d2934878d9b0d9d1f38739f54b1141e8ad`
- Latest verified New-main commit: `b83bbe6cb0b90277eb6f05b39c1ba53b0cdf0489`
- `Current/PWA/New-main` final verified blob SHA: `744c38a561fb414c35e92b6a0bd526c9c9ca8461`
- The state-update commit itself follows this checkpoint; on next boot, verify the Git HEAD again before proceeding.

## PRODUCTION BASELINE — DIRECTLY VERIFIED
- Project: `fiilmooggumokxanwiyx`
- Last direct invariant baseline captured: 2026-08-31 UTC during this execution.
- companies: 1
- users: 24
- branches: 2
- items: 17
- stock_branches: 20
- inventory_log: 3
- stock_vouchers: 0
- purchase_orders: 0
- orders: 0
- runsheets: 0
- audit_log: 1866
- negative physical qty: 0
- negative allocated qty: 0
- available_qty mismatches: 0
- cross-company stock rows: 0
- cross-company inventory-log rows: 0
- duplicate item_code values: 0

## ACTIVE PRODUCTION CONTRACTS RECONFIRMED FOR NEW-MAIN
- `users.auth_id` is the authoritative bridge from Auth user to `public.users`.
- `users.company_id` is the authoritative operational tenant context.
- `items`, `customers`, `suppliers`, `orders`, `runsheets`, `purchase_orders`, `stock_branches`, `journal_entries`, `cash_box`, and `treasury` reads in New-main are company-scoped where the schema exposes `company_id`.
- `post_stock_movement` remains Physical Stock authority.
- `reserve_stock` / `release_stock_reservation` remain reservation capabilities only.
- Financial writes remain owned by canonical Edge/Core paths; New-main contains no direct financial DML.
- Current critical financial/inventory Edge versions remain the Production source of truth, including `save-sales-invoice`, `receive-purchase`, `complete-return`, `complete-picking`, `complete-loading`, and `unload-runsheet`.

## NEW-MAIN TASK
Target: `Current/PWA/New-main`.
Forbidden target: `Current/PWA/main.html`.

### Verified execution
1. Read `doc/Draft/medhat/تقرير +برومبت 117-02`.
2. Read `CURRENT_STATE.md` before reconstruction.
3. Read `FINAL_MAIN_HTML_RECONSTRUCTION_COMMAND.md` through its final closure gates.
4. Reconciled the current New-main candidate against the current repository/Production contracts used by the clean-room shell.
5. Rebuilt `Current/PWA/New-main` manually as a clean-room shell rather than patching or repairing `Current/PWA/main.html`.
6. Ran self-audit against the persisted artifact and corrected the Supabase client key after detecting a malformed candidate value.
7. Recorded the final candidate as a Git artifact and created a verification evidence record.

## NEW-MAIN FINAL ARTIFACT
- Path: `Current/PWA/New-main`
- Final blob SHA: `744c38a561fb414c35e92b6a0bd526c9c9ca8461`
- Final artifact commit: `b83bbe6cb0b90277eb6f05b39c1ba53b0cdf0489`
- Verification evidence: `Current/CTO/20260831_HYTHAM_NEW_MAIN_CLEAN_ROOM_VERIFICATION.md`
- Verification evidence commit: `688673d2934878d9b0d9d1f38739f54b1141e8ad`

## NEW-MAIN CONTENT CONTRACT
The candidate currently provides:
- Supabase Auth sign-in/session bootstrap.
- Authoritative company resolution through `public.users.auth_id`.
- Current-company Owner/permission display semantics without replacing the existing wildcard behavior with an invented policy model.
- Company-scoped operational read models for customers, suppliers, items, orders, runsheets, purchases, inventory, finance, reports, HR, and settings.
- Explicit delegation links to specialized PWAs for POS, receiving, vouchers, Picker, Returns, and Van Sales.
- Read-only inventory and financial monitoring surfaces.
- Existing Service Worker registration through `register-sw.js`.
- Mobile responsive shell and navigation.
- No direct `INSERT`, `UPDATE`, `DELETE`, or stock/financial mutation path from New-main.

## SELF-AUDIT
### Corrected
- A malformed/incomplete Supabase client key was detected in the candidate during self-audit and corrected before the final artifact was recorded.

### Verified by source inspection
- Final candidate contains the current Supabase public client key used by `Current/PWA/core.js`.
- Company identity is derived from `public.users.auth_id`.
- No `user_metadata.company_id` is used as tenant authority.
- No hard-coded financial account UUID is used.
- No direct stock or financial DML is implemented in New-main.
- The final corrective commit changed only `Current/PWA/New-main`.
- `Current/PWA/main.html` was not the target and was not modified by the clean-room artifact commit.

## NOT YET PROVEN
- Full structural parity against every logical `main1..main11` contract.
- Complete functional parity for every historical/current Main feature.
- Browser smoke test for the final artifact.
- Service Worker runtime proof for the final artifact.
- Authenticated Production HTTP E2E for the final artifact.
- Production runtime verification of the final artifact as a deployed replacement.
- Complete concurrency proof for all critical operations.
- Authorization to replace `Current/PWA/main.html`.

## LAST VERIFIED EVENT
- Event ID: `LVE-2026-08-31-005`
- Event type: `NEW_MAIN_CLEAN_ROOM_ARTIFACT_VERIFIED`
- UTC: `2026-08-31T06:39Z`
- Source: direct GitHub repository + direct SMART ERP Production evidence
- Git SHA: `688673d2934878d9b0d9d1f38739f54b1141e8ad`
- Action: finalized and persisted the clean-room `Current/PWA/New-main` artifact; preserved `Current/PWA/main.html` outside the target; recorded self-audit evidence.
- Result: `CANDIDATE_ARTIFACT_VERIFIED / RUNTIME_AND_PARITY_STILL_OPEN`
- Evidence: `Current/CTO/20260831_HYTHAM_NEW_MAIN_CLEAN_ROOM_VERIFICATION.md`, final New-main blob `744c38a561fb414c35e92b6a0bd526c9c9ca8461`.
- Impact: The project now has a concrete reviewable New-main clean-room artifact distinct from the old main.html repair loop.
- Next authorized action: re-verify Git/Production freshness on next boot, then perform structural and functional parity verification of New-main. Do not modify `Current/PWA/main.html` without all closure gates.

## CLOSURE
`NEW-MAIN ARTIFACT = VERIFIED`
`CLEAN-ROOM RECONSTRUCTION ARTIFACT = VERIFIED`
`STRUCTURAL PARITY = OPEN`
`FUNCTIONAL PARITY = OPEN`
`CONTRACT PARITY = OPEN`
`VALIDATED CHANGE PARITY = OPEN`
`BROWSER RUNTIME = OPEN`
`PRODUCTION RUNTIME = OPEN`
`MAIN.HTML REPLACEMENT = NOT AUTHORIZED`
`MAIN.HTML RECONSTRUCTION COMMAND = NOT YET FULLY CLOSED`
