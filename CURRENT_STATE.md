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
- Latest verified execution commit: `0fa2cf2755cd12032a988ccadf2ccb9a22439bde`
- New-main reconstruction commit: `7b913fb48374e390a0fc1bb5edc640b95fefe1d7`
- New-main final blob SHA: `2f252390b56cc408a8db62523edf303f3e24a3ad`
- Verification artifact commit: `0fa2cf2755cd12032a988ccadf2ccb9a22439bde`

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
- Checked current stock invariants remained clean during the latest forensic execution.

## CURRENT PRODUCTION CONTRACTS USED BY NEW-MAIN
- Authenticated Supabase user is the identity entry point.
- `public.users.auth_id` -> `users.company_id` is the authoritative tenant mapping.
- Operational reads in New-main are company-scoped where the table exposes `company_id`.
- `post_stock_movement` remains the Physical Stock mutation authority.
- `reserve_stock` / `release_stock_reservation` remain reservation capabilities only.
- Financial writes remain delegated to canonical Edge/Core writers; New-main contains no financial DML.
- Current financial/stock Edge deployments were checked directly and treated as current Production truth.

## NEW-MAIN EXECUTION
### Command chain executed
1. `doc/Draft/medhat/تقرير +برومبت 117-02` read for continuity/governance rules.
2. `CURRENT_STATE.md` read before reconstruction.
3. `FINAL_MAIN_HTML_RECONSTRUCTION_COMMAND.md` read and its clean-room/closure rules applied.
4. Current New-main artifact inspected as an incomplete prior candidate only; it was not treated as proof of completion.
5. `Current/PWA/New-main` was manually rewritten as a new standalone clean-room HTML artifact.
6. The legacy `Current/PWA/main.html` was not modified.
7. A dedicated verification artifact was updated with the final New-main SHA and evidence boundary.

## NEW-MAIN CONTRACT IMPLEMENTED
- Auth login/session bootstrap via current Supabase Auth client.
- Authoritative tenant resolution through `public.users.auth_id` and `users.company_id`.
- Owner/permissions/license surfaces retained without inventing a new permission model.
- Company-scoped reads for customers, suppliers, items, orders, runsheets, purchase orders, stock branches, financial monitors, users, and settings.
- Functional delegation links to specialized current PWAs for POS, purchasing/receiving, stock vouchers, picking, returns, and van sales.
- Read-only inventory monitor.
- Read-only financial monitor.
- Responsive shell for desktop/mobile.
- Required reconstruction globals exposed: `RW_ShellContext`, `RW_OwnerLicense`, `RW_Views`, `RW_Dashboard`, `RW_Items`, `RW_POS`, `RW_Orders`, `RW_Runsheets`, `RW_Purchases`, `RW_Warehouse`, `RW_Finance`, `RW_Reports`, `RW_HR`, `RW_CRM`.
- No direct stock or financial mutation implementation.
- Nested Service Worker registration targets the shared PWA root (`../sw.js`, scope `../`).

## SELF-AUDIT
- Prior candidate lacked reconstruction globals required by the clean-room execution gate.
- Prior candidate registered Service Worker from the wrong nested path.
- Both issues were corrected in the final New-main artifact.
- The final artifact was re-read from Git after write.
- No production database mutation was performed for the New-main reconstruction.

## VERIFICATION BOUNDARY
### Verified
- New-main exists as a concrete Git artifact.
- Static shell/contract markers required by the clean-room gate are present.
- Company identity does not come from `user_metadata.company_id`.
- No hard-coded financial account UUID exists.
- No direct stock mutation path exists.
- No direct journal/ledger/treasury DML exists.
- `app_settings` lookup is company-scoped.
- The reconstruction commit's write target was `Current/PWA/New-main` only.

### Still OPEN — no false closure
- Full browser smoke for the final persisted artifact.
- Service Worker runtime execution for the nested artifact.
- Authenticated Production HTTP E2E using the final artifact.
- Two-session concurrency proof for the final artifact's critical flows.
- Exhaustive semantic feature parity against every logical `main1..main11` contract.
- Full current-vs-historical validated-change parity certificate.
- Production deployment/replacement certification for New-main.
- Authorization to replace `Current/PWA/main.html`.

## LAST VERIFIED EVENT
- Event ID: `LVE-2026-08-31-006`
- Event Type: `NEW_MAIN_CLEAN_ROOM_RECONSTRUCTION_FINAL_ARTIFACT`
- UTC: `2026-08-31T06:39:00Z`
- Source: direct GitHub repository + direct SMART ERP Production evidence
- Git SHA: `0fa2cf2755cd12032a988ccadf2ccb9a22439bde`
- Action: manually reconstructed and persisted the independent `Current/PWA/New-main` artifact and synchronized the operational state record.
- Result: `NEW-MAIN ARTIFACT VERIFIED / FULL RUNTIME AND PARITY CERTIFICATION OPEN`
- Evidence: `Current/CTO/20260831_HYTHAM_NEW_MAIN_CLEAN_ROOM_VERIFICATION.md`; New-main blob `2f252390b56cc408a8db62523edf303f3e24a3ad`.
- Impact: The project now has a distinct clean-room Main candidate without reopening or modifying the historical `Current/PWA/main.html` repair loop.
- Next Authorized Action: verify the final candidate structurally and functionally, then perform supported browser/runtime gates. Do not modify `Current/PWA/main.html` before all required closure gates are proven.

## CLOSURE
`NEW-MAIN ARTIFACT = VERIFIED`
`STATIC CONTRACT = VERIFIED`
`STRUCTURAL PARITY = OPEN`
`FUNCTIONAL PARITY = OPEN`
`CONTRACT PARITY = OPEN`
`VALIDATED CHANGE PARITY = OPEN`
`BROWSER RUNTIME = OPEN`
`SERVICE WORKER RUNTIME = OPEN`
`PRODUCTION RUNTIME = OPEN`
`MAIN.HTML REPLACEMENT = NOT AUTHORIZED`
