# Report693 — Unified Warehouse Login Role & Tab Responsiveness Repair
**Date:** 2026-11-10 (Africa/Cairo)  
**Workstream:** RAWAEA ERP / Standalone Unified Warehouse  
**Operational repository:** `papamohammed77-glitch/erp-frontend` / `main`  
**Last operational commit at report creation:** `a98625c51fc8f152e626752a4a5b8fb5494a3863`

## 1. Owner request and continuation point
Continued from Report692 and the existing native-workspace implementation. No rebuild was started. The requested work was limited to:
- Enable login for warehouse employees whose primary job title is `أمين مخزن`, `امين مخزن`, or `مخزني`.
- Correct the currently linked warehouse employee's assignment so the employee can enter the unified application.
- Diagnose and fix the apparent no-response condition when switching top-level tabs or opening workspaces.
- Preserve the standalone application boundary, shared session/client, original operation engines, database records, stock, supplier, accounting and treasury contracts.

## 2. Confirmed root cause — linked employee
Read-only SMART ERP inspection identified the current linked account:
- Email: `storekeeper@rawaea.com`
- User ID: `f9ce2c11-cd7f-4ed0-ab69-7d2ec5051c52`
- Primary job title: `أمين مخزن`
- Status: `Active`
- Existing branch scope: `BR-01`
- The canonical branch-scope helper returned `true` for the active Main Branch record.
- Before repair, `active_warehouse_role` was NULL and the user-level `warehouse` permission was absent. The linked role record also had no `warehouse` permission.

This was not a password or missing-auth-profile defect. The account existed and had a valid branch scope, but it had not been assigned the unified operational warehouse role and warehouse permission required by `get_warehouse_hub_snapshot()`.

## 3. Targeted production user assignment
The owner explicitly asked to repair the currently linked employee and allowed changing that assignment. A single guarded update targeted only the exact user ID + email, and required:
- Active account status.
- Primary role in the approved warehouse employee set.
- Existing access to the active `BR-01` branch through `app_private.user_can_access_warehouse_branch`.

Applied values:
- `active_warehouse_role = 'مخزن شامل'`
- Added only the user-level `warehouse` permission to the existing JSONB permission array.
- Preserved the primary job title `أمين مخزن`.
- Preserved `allowed_branch_ids = ["BR-01"]`.
- Did not invent or change a default branch.
- Did not alter other users, role definitions, or branch memberships.

Post-update read confirmed the intended role and permission on that exact account. The canonical branch helper had already confirmed the branch access. This is an access/role assignment only; it is not a stock or financial transaction.

**Important audit note:** the current-user assignment was made as a narrowly scoped, guarded database update because the linked employee was explicitly identified in the request and no owner-authenticated Supervisor browser session was available to invoke the UI RPC. The standard Supervisor RPC remains the supported path for future role changes.

## 4. Supervisor role spelling compatibility
The existing `set_active_warehouse_role(uuid,text)` function allowed target users whose primary role was exactly `مخزني` or `أمين مخزن`, but rejected the equivalent spelling `امين مخزن` without hamza.

Applied Supabase migration:
- Version: `20261110181631`
- Name: `warehouse_supervisor_accept_amin_makhzan_alias_20261110`
- Function changed: `public.set_active_warehouse_role(uuid,text)` only.
- Change: target warehouse employee role allowlist now includes `['مخزني','أمين مخزن','امين مخزن']`.
- Function signature, supervisor authorization, company check, branch-overlap check, active-user check, allowed operational-role values, SECURITY DEFINER and existing execution grants remain unchanged.
- Post-migration definition verified.
- Privileges verified: anon EXECUTE=false; authenticated EXECUTE=true.

The exact applied SQL was added to the operational repository:
`supabase/migrations/20261110181631_warehouse_supervisor_accept_amin_makhzan_alias_20261110.sql`  
Commit: `a98625c51fc8f152e626752a4a5b8fb5494a3863`.

## 5. Frontend login and boot responsiveness
Changed only `companies/company-1/warehouse/warehouse.html`:
- Added normalized warehouse employee-title recognition. Arabic hamza variants normalize to the same classification; `أمين مخزن`, `امين مخزن`, and `مخزني` are recognized as eligible warehouse employee titles.
- Recognition does not bypass the active operational role, server-side warehouse permission, identity/company match or branch-scope checks. The employee still needs an authorized active warehouse assignment such as `مخزن شامل`.
- Added a bounded 15-second timeout around the initial `get_warehouse_hub_snapshot` request. A stalled network/RPC now returns a visible actionable login message instead of leaving the shell in an indefinite boot state.
- Added a 20-second native-module initialization watchdog. If a module never signals ready/error, the workspace status displays a timeout message and explicitly says no movement was executed.
- The module watchdog is cleared on native ready/error events.
- Existing shared `RW_Auth`, shared `RW_SHARED_SUPABASE`, native module bundles, operation keys, and original operation functions remain intact.

Relevant commits:
- `91f3e5aeb2b1f844c45a09cb4f7d41dd25089c1b` — bounded host/module boot waits and visible module failure.
- `c8205d175dde7075e7e811ed6fb7692220a6619e` — warehouse employee role alias normalization.
- `7e6befa721d7d8a23ffd9fea3fe257e6cb764809` — E2E role-alias and repeated-tab coverage.

## 6. CI failure diagnosis and repair
A later CI run at commit `021f47a11580368f2b7d1c699596c3c0e6669947` failed before Playwright started. The cause was a malformed, over-escaped JavaScript regular expression in the workflow's static source test:
`SyntaxError: Invalid regular expression ... Unterminated group`.

This was a test-harness defect, not a production database or application runtime failure. The static checks were repaired to use direct string-count/string-presence checks for:
- exactly one shared `RW_Auth.init` call per bundle,
- no duplicate `createClient(`,
- no unscoped `moduleApp.` references.

Workflow commit:
- `6c82f8fafde22d0bf17e68d100dc98f3a6d21510`.

## 7. Browser E2E — verified at commit 7e6befa
GitHub Actions:
- Workflow run: `42873621326`
- Job: `130031012788`
- Conclusion: **success**
- Tested commit: `7e6befa721d7d8a23ffd9fea3fe257e6cb764809`

Observed PASS markers:
- Four top-level tabs are responsive through two repeated navigation cycles.
- Shared auth and four-tab shell.
- Six native operation workspaces mount and become ready.
- Five manual-voucher actions open the native voucher application.
- SupplierReturn specialized contract UI remains present.
- Logout clears native modules and shared session; relogin reinitializes a workspace.
- Active operational-role gate still rejects a non-unified active role.
- All three primary warehouse job-title spellings are recognized when the active operational role is `مخزن شامل`.
- Main-branch vs scoped-branch operation gates remain enforced.
- Static checks: four-tab contract, no iframe/child navigation, seven native bundles, CSS scope mapping, shared core/session, Picker shared auth, and preservation of native workflows.

The synthetic Playwright test validates browser navigation and module readiness with mocked auth/RPC. It does not replace a real authenticated employee browser session.

## 8. Production data integrity
Post-change read-only row counts:
| Table | Rows |
|---|---:|
| `inventory_log` | 78 |
| `stock_branches` | 58 |
| `stock_vouchers` | 0 |
| `stock_voucher_details` | 0 |
| `purchase_invoices` | 5 |
| `supplier_ledger` | 3 |
| `journal_entries` | 21 |
| `inventory_counts` | 0 |
| `inventory_count_details` | 0 |

No stock movement, purchase receipt, manual voucher, supplier return, supplier balance, treasury, cash or journal entry was created or modified. No Edge Function, stock-posting RPC, inventory table, supplier ledger or accounting engine was changed.

## 9. Mutation ledger
| Layer | Change |
|---|---|
| `warehouse.html` | Role-title normalization, initial snapshot timeout, native workspace timeout |
| Workflow YAML | Fixed malformed static test; added repeated-tab and role-alias E2E |
| Supabase | One existing supervisor RPC definition extended by one accepted primary-role spelling |
| Current linked user | One guarded user-level role/permission assignment |
| Supabase migration source | Added exact migration file to operational repository |
| Parent `main.html` | Not changed |
| Supervisor UI | Not changed |
| Original six operation apps + vouchers app | Not changed |
| Shared `core.js` | Not changed |
| Stock/accounting/supplier/treasury records | No business writes |

## 10. Remaining verification boundary
- The current linked employee is now configured in SMART ERP, but a real browser login using that employee's actual credentials was not performed in this session.
- Browser connector access to the user's selected browser tab was unavailable during this continuation; no indirect browser-security bypass was attempted.
- CI proves the tab/workspace responsiveness with a synthetic browser profile.
- Cloudflare deployment of the latest operational HEAD after the final SQL migration source commit has not been confirmed here.
- Real stock/financial writer E2E remains intentionally unrun until a reversible QA fixture and complete cleanup proof exist.

**Last verified event:** the linked warehouse employee has the unified active role and warehouse permission; supervisor role assignment accepts the three requested Arabic job-title variants; the synthetic browser E2E passed repeated four-tab navigation and all seven native workspaces. Production business-row counts remain unchanged.

**Status:** `ROLE ASSIGNMENT APPLIED + LOGIN TITLE ALIASES SUPPORTED + TAB/NATIVE WORKSPACE E2E PASS + PRODUCTION BUSINESS DATA UNCHANGED / REAL EMPLOYEE BROWSER LOGIN AND LATEST DEPLOYMENT CHECK OPEN`.

**Next exact action:** verify Cloudflare deployment for operational HEAD `a98625c`, then perform a real read-only login using the existing linked employee account. Do not run stock, supplier, treasury or GL posting tests without a reversible fixture and cleanup proof.
