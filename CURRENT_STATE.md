# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- Operational truth: current Git main HEAD, Production Supabase, deployed Edge Functions, and runtime verification.
- Historical reports/prompts are evidence only.
- Authorized target: `Current/PWA/New-main`.
- `Current/PWA/main.html` is protected.
- Prompt 123/124 forbid reconstruction, overlay, new workflow, new file, or speculative production mutation.
- Every material operation is recorded here before closure.

## LAST VERIFIED EVENT
### P124-006 — FINAL_FORENSIC_RECONCILIATION_AND_PRODUCTION_AUTHORITY_CHECK
- `MASTER - RAWAEA ERP.md` and Prompt 124+ were read through their terminal execution commands before continuation.
- Actual Git `main` was reconciled directly; the branch head immediately before this state update was `8c2c21e4b103daa741e6713844e949a16728d7b0`.
- Exact `Current/PWA/New-main` content SHA remains `d657d6e4bdd90a9b60f658a8bf28560e1b10f755`.
- No reconstruction or replacement of the target artifact was performed.
- MAIN1 contract mapping remains complete at the static contract level; no evidence-backed missing MAIN1 contract was found.
- Existing duplicate/layered JavaScript definitions remain a maintainability risk, but no broad rewrite was justified without independent runtime regression evidence.

## PRODUCTION FIXES CONFIRMED
### P124-002 — WORKFLOW_NOTIFICATION_RLS_HARDENING
- Production RLS was reviewed and permissive workflow/template `ALL` exposure was removed in favor of restricted policies.
- No `company_id` column was invented for legacy workflow/template tables that do not contain one.

### P124-003 — MAIN1_DEPENDENCY_STOCK_AUTHORITY_HARDENING
- Historical/original `save-item` contained a direct `stock_branches.upsert` opening-balance path.
- Current Production `save-item` no longer writes opening stock directly.
- Production `save-item` is ACTIVE at version `12`, `verify_jwt=true`, SHA `ffc7e57e7fd57e60eaed861ebdd0f5187cc16347820007e900627fccf6486099`.
- The function derives tenant context from authenticated `users.company_id`, validates the opening branch against that tenant, then calls `create_item_with_opening_stock`.
- `create_item_with_opening_stock` is the atomic owner for create-item + optional opening balance and routes the balance through canonical `post_stock_movement('InventoryIncrease', ...)` with idempotency.
- Earlier Production rollback evidence recorded zero residual synthetic items and zero residual synthetic inventory logs.

## CORE VERIFICATION
- `post_stock_movement` exists as `SECURITY DEFINER` and enforces movement-type validation, branch/company validation, row locking, idempotency where supplied, `stock_branches` mutation, and `inventory_log` creation.
- `reserve_stock` and `post_journal_entry` exist as `SECURITY DEFINER`.
- MAIN1-sensitive tables inspected have RLS enabled, including `users`, `companies`, `customers`, `items`, `branches`, `orders`, `stock_branches`, `journal_entries`, `audit_log`, `owner_profile`, `notifications`, `workflow_rules`, and `workflow_log`.

## EDGE FUNCTION VERIFICATION
- `save-item`: v12 ACTIVE / JWT protected; source re-read after deployment confirms RPC-based opening-balance creation.
- `save-customer`: v3 ACTIVE / JWT protected / derives company context from authenticated identity.
- `log-action`: v2 ACTIVE / JWT protected.
- Core operational Edge Functions inspected are JWT protected.
- Historical E2E harness functions exposed by Production are retired or fixture-only where inspected; they are not accepted as current New-main browser evidence.

## INDUSTRY ARCHITECTURE VALIDATION
- The canonical stock design follows established ERP principles: inventory changes are represented through controlled posting/movement records with auditability, rather than arbitrary UI-side stock writes; multi-company access is governed by tenant-aware authorization rather than navigation alone.

## TARGET STATIC VERIFICATION
- Target contains MAIN1 shell, authentication/session, tenant context, owner/license, permissions, navigation, data bootstrap, audit, workflow, notification, search, PWA lifecycle, and delegated specialized-app routes.
- Required MAIN1 globals observed include `RW_ShellContext`, `RW_OwnerLicense`, `RW_Views`, `RW_Dashboard`, `RW_Items`, `RW_POS`, `RW_Orders`, `RW_Runsheets`, `RW_Purchases`, `RW_Warehouse`, `RW_Finance`, `RW_Reports`, `RW_HR`, and `RW_CRM`.
- Notification contract functions `_renderAndSave`, `_updateBadge`, `markRead`, `_clickNotif` exist in the target.
- Clean-room workflow definition contains Node syntax, DOM/contract, browser smoke, legacy-file protection, and checksum gates.

## EXACT EXECUTION STATUS
- Exact target artifact browser execution with authenticated Owner and Non-Owner identities remains **PENDING**.
- No qualifying browser PASS tied to exact target blob `d657d6e4bdd90a9b60f658a8bf28560e1b10f755` was found in accessible GitHub evidence.
- No credentialed browser/session is exposed by the current execution environment, and local network replay of the GitHub artifact is unavailable.
- Static markers, commit messages, CI configuration, historical reports, or retired harnesses are not accepted as substitutes for this gate.

## CLOSURE MATRIX
| Gate | Status |
|---|---|
| Master memory reconstruction read to EOF | PASS |
| Prompt 124+ read to END COMMAND | PASS |
| Git current-state reconciliation | PASS |
| Exact New-main target identity | PASS |
| MAIN1 Original/Current source mapping | PASS |
| MAIN1 → New-main contract mapping | PASS |
| Production RLS inspection | PASS |
| Canonical stock authority | PASS |
| Atomic opening-stock owner | PASS |
| save-item Production hardening | PASS |
| Exact static syntax/DOM independent certification | NOT INDEPENDENTLY CERTIFIED |
| Authenticated Owner browser E2E | PENDING |
| Authenticated Non-Owner authorization E2E | PENDING |
| Tenant-isolation browser E2E | PENDING |
| Service Worker browser runtime | PENDING |

## CURRENT CLASSIFICATION
`FORENSICALLY RECONCILED; PRODUCTION HARDENED; MAIN1 STATIC CONTRACT MAPPED; RUNTIME EVIDENCE GATE PENDING`

## ABSOLUTE CLOSURE RULE
Never mark `CLOSED 100% / GOLD / DIAMOND / COMPLETE` until the exact current `Current/PWA/New-main` artifact passes the required authenticated browser gates and those results are recorded here. A false 100% is explicitly prohibited.

## NEXT AUTHORIZED ACTION
`P124-007_AUTHENTICATED_BROWSER_RUNTIME_EXECUTION`
- Run the exact current artifact in a real browser with authorized Owner and Non-Owner identities.
- Verify login, authoritative tenant context, dashboard, navigation, owner/license gating, notification behavior, audit/logout/fail-closed behavior, console/network health, tenant isolation, and Service Worker runtime.
- On qualifying PASS, record exact artifact SHA plus run evidence and change classification to `CLOSED 100% / GOLD / DIAMOND / COMPLETE`.
