# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- `CURRENT_STATE.md` is the operational checkpoint.
- `LAST VERIFIED EVENT` is authoritative for recency.
- Historical reports/prompts are evidence of past events, not current runtime truth.
- The current task targets only `Current/PWA/New-main`.
- `Current/PWA/main.html` is explicitly outside the write target and was not modified.

## CURRENT GIT
- Repository: `papamohammed77-glitch/rawaie-erp-New`
- Branch: `main`
- Latest New-main expansion commit: `ffdc712000488cecf0435b94704bc95153e6e58b`
- New-main current blob SHA: `e5376b78068e80d030a34ac77dac82efc8ebfd37`
- Latest state-update commit: this file update
- Temporary clean-room trigger file under `Current/PWA/main/` was removed after use.

## PRODUCTION BASELINE — DIRECTLY VERIFIED
- Project: `fiilmooggumokxanwiyx`
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
- Latest verified stock invariants remained clean during this execution.

## CURRENT PRODUCTION CONTRACTS USED BY NEW-MAIN
- Authenticated Supabase user is the identity entry point.
- `public.users.auth_id` -> `users.company_id` is the authoritative tenant mapping.
- Operational reads in New-main are company-scoped where the table exposes `company_id`.
- `post_stock_movement` remains the Physical Stock mutation authority.
- `reserve_stock` / `release_stock_reservation` remain reservation capabilities only.
- Financial writes remain delegated to canonical Edge/Core writers; New-main contains no financial DML.
- Current financial/stock Edge deployments remain the Production source of truth.

## NEW-MAIN SPECIFICATION REVIEW
### Source evidence reviewed
- `FINAL_MAIN_HTML_RECONSTRUCTION_COMMAND.md`
- `CURRENT/CTO/FORENSIC_FRAGMENT_INVENTORY.json`
- `Current/PWA/main/main1.md`
- `Current/PWA/main/main2.md`
- `Current/PWA/main/main3.md`
- `Current/PWA/main/main4.md`
- `Current/PWA/main/main5.md` and current fragment inventory references
- Current PWA companions including `core.js`, `register-sw.js`, `pos.html`, `picker.html`, `vouchers.html`, `Returns.html`, `accountant.html`, `buyer.html`, `telesales.html`, `van-sales.html`, `loader.html`, `unloader.html`
- Direct Production contracts used by the current Main shell

### SPECIFICATION ASSESSMENT
The previous New-main candidate was a shell and did not meet the full Main contract surface. It lacked several shared Main responsibilities and had insufficient semantic feature coverage.

### CURRENTLY IMPLEMENTED IN NEW-MAIN
- Authentication and session bootstrap.
- Authoritative user/company resolution through `users.auth_id` and `users.company_id`.
- Owner / permissions / license surfaces.
- Navigation across current operational, warehouse, financial, HR and settings areas.
- Company-scoped customer CRUD through current Edge contract.
- Company-scoped item CRUD through current Edge contract.
- Global search across customers/items/orders.
- Dashboard KPI/data reads.
- Orders, runsheets, suppliers, HR, inventory, finance and reports read models.
- Financial monitoring with COA/journal/customer-ledger/supplier-ledger/driver-ledger/treasury visibility.
- Owner-only audit read model.
- Notifications read model.
- CSV export for item data.
- Explicit delegation to specialized PWA owners for POS, Telesales, Purchasing/Receiving, Stock Vouchers, Picking, Loading, Delivery and Returns.
- Responsive mobile shell.
- Service Worker registration from the nested New-main location to the shared PWA root.
- No direct Physical Stock mutation.
- No direct Journal/Ledger/Treasury/Cash mutation.
- `MAIN_HTML_CURRENT_CONTRACT_LEDGER` embedded in the candidate.

## SELF-AUDIT
- The prior candidate was confirmed to be a shell, not a complete semantic Main surface.
- The expanded candidate corrected the missing reconstruction globals and the nested Service Worker path.
- Tenant authority is not taken from `user_metadata.company_id`.
- No financial account UUIDs are hard-coded.
- No direct stock or financial DML exists in New-main.
- Customer and Item writes use existing Edge owners rather than new direct database writers.
- The final write in this round changed only `Current/PWA/New-main`.
- The temporary workflow trigger was removed after use.

## IMPORTANT LIMITATION
New-main is now a substantially more complete clean-room Main candidate, but it is still not certified as a replacement for `Current/PWA/main.html`.

The current source evidence establishes many contracts, but it does not yet prove exhaustive semantic parity for every historical/current Main feature. Missing full coverage includes, at minimum, deep runtime behavior for offline/sync, realtime, full workflow/notification behavior, every specialized operations path, and every consumer/error path.

## VERIFICATION BOUNDARY
### Verified by source/static inspection
- Candidate is a valid HTML document structure.
- Required shell reconstruction globals are exposed.
- Tenant mapping uses authenticated user -> public users -> company.
- Company-scoped lookups are used where applicable.
- `app_settings` lookup is company-scoped.
- New-main contains no direct stock mutation DML.
- New-main contains no direct financial DML.
- Specialized writes are delegated to existing current applications/Edge owners.
- Existing `Current/PWA/main.html` remains outside the write target.

### STILL OPEN — NO FALSE CLOSURE
- Full structural parity against every logical `main1..main11` feature contract.
- Full functional parity against every current Main capability.
- Full validated-change parity from all current Production changes.
- Browser smoke of the persisted final artifact.
- Service Worker runtime proof for New-main.
- Authenticated Production HTTP E2E of New-main.
- Two-session concurrency proof for critical Main flows.
- Exhaustive runtime/error-path verification for all delegated applications.
- Production deployment/replacement certification.
- Authorization to replace `Current/PWA/main.html`.

## LAST VERIFIED EVENT
- Event ID: `LVE-2026-08-31-007`
- Event Type: `NEW_MAIN_CONTRACT_EXPANSION_AND_FORNSIC_REVIEW`
- UTC: `2026-08-31T07:xx:xxZ`
- Source: direct GitHub current repository + direct SMART ERP Production contract evidence
- Git SHA: `ffdc712000488cecf0435b94704bc95153e6e58b`
- Action: audited the previous New-main candidate against the reconstruction command and current logical-module evidence; expanded New-main with current shared Main contracts and specialized delegation; removed the temporary clean-room trigger.
- Result: `NEW-MAIN SUBSTANTIALLY EXPANDED / FULL PARITY AND RUNTIME CERTIFICATION OPEN`
- Evidence: `Current/PWA/New-main` blob `e5376b78068e80d030a34ac77dac82efc8ebfd37`.
- Impact: New-main now contains a materially broader clean-room Main surface while keeping legacy `Current/PWA/main.html` untouched.
- Next Authorized Action: continue structural/functional/runtime parity verification of New-main only. Do not modify `Current/PWA/main.html` until every required closure gate is actually proven.

## CLOSURE
`NEW-MAIN ARTIFACT = EXISTS`
`CURRENT CONTRACT SURFACE = SUBSTANTIALLY IMPLEMENTED`
`STRUCTURAL PARITY = OPEN`
`FUNCTIONAL PARITY = OPEN`
`CONTRACT PARITY = OPEN`
`VALIDATED CHANGE PARITY = OPEN`
`BROWSER RUNTIME = OPEN`
`SERVICE WORKER RUNTIME = OPEN`
`PRODUCTION RUNTIME = OPEN`
`MAIN.HTML REPLACEMENT = NOT AUTHORIZED`
