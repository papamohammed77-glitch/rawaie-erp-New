# Report652 — Parent Finance Employee Custody Event Binding Fix
**Date:** 2026-11-08 (Africa/Cairo)  
**Status:** PATCH COMMITTED — SOURCE REVERIFIED — DEPLOYMENT / AUTHENTICATED E2E UNVERIFIED

## 1. Executive result

The event-binding collision diagnosed in Report651 was corrected in the operational repository. The change is deliberately limited to one identifier in `companies/company-1/main.html`: the later, obsolete `bind(root)` declaration was renamed to `bindLegacy(root)`. This removes its function-declaration shadowing of the comprehensive register binder already present in the same IIFE.

The change is committed to `main`, and the current `main.html` blob was independently re-fetched from the current branch tree and verified to match the corrected blob exactly. A subsequent descendant commit changed only `_forensic_current_main_extract.md`; it did not alter or revert the corrected Parent file.

## 2. Source and commit lineage

- Operational repository: `papamohammed77-glitch/erp-frontend`
- Branch: `main`
- Parent commit before patch: `855810884e9184122c5f149b6d052479a840cc6f`
- Parent file before patch blob: `6b4d555d0da9efd3fb821aef4a9a2e832bb064e1`
- **Fix commit:** `d514060d88c8156f982b6d586715c7af7d7f4c6a`
- Corrected Parent blob: `879383859d0ec20927cc718e63a7af49fa18980c`
- Latest observed branch HEAD after a forensic-only descendant: `c8d40b32150d2cb0e7e5830bac4a9e3d0a846655`
- Latest observed `main.html` blob: `879383859d0ec20927cc718e63a7af49fa18980c` (same corrected blob)
- The compare `d514060...c8d40b3` is one commit ahead and modifies only `_forensic_current_main_extract.md` (+2/-2). It does not touch `main.html`.

## 3. Exact surgical patch

Inside `RW_Finance_Custody`, immediately after `function doc(path){...}`, the later legacy declaration changed:

```javascript
function bind(root){
```

to:

```javascript
function bindLegacy(root){
```

No function body, listener selector, render call, state variable, API helper or financial action was altered. The earlier comprehensive `bind(root)` remains the sole active declaration named `bind`; the legacy handler body remains present but no longer shadows it. The current render continues to call `bind(target)`.

## 4. Root cause and behavioral effect

Before the patch there were exactly two same-scope declarations named `bind(root)`. The later legacy declaration, positioned after `doc(path)`, overrode the earlier comprehensive binder according to JavaScript function declaration semantics.

The comprehensive binder already contains handlers for:

- `data-custody-apply` — apply date, employee and text filters.
- `data-custody-reset` — clear filters and return to the first page.
- `data-custody-page` — previous/next server page navigation.
- `data-custody-open-detail` — open the current-page detail drawer and scroll to the matching custody.
- `#custody-page-size` — page-size change listener for 25/50/100/200 rows.
- Existing advance, settle, review and document actions.

The later legacy declaration only contained advance, settle, review and document actions. Renaming it allows `render() → bind(target)` to resolve to the comprehensive binder. This is the minimal repair; it does not invent a second event system or duplicate the working business actions.

## 5. Verification performed

**Source-level verification — PASS**

1. Fetched the complete current Parent blob (1,840,734 characters) and checked the two declarations and their ordering.
2. Confirmed the first binder contains apply, reset, page, detail and page-size handlers.
3. Confirmed the later declaration is after `doc(path)` and was renamed.
4. Confirmed exactly one `function bind(root)` remains and exactly one `function bindLegacy(root)` exists.
5. Confirmed the active render still invokes `bind(target)`.
6. Reconstructed the expected patched source from the pre-change blob and verified byte-for-byte equality with the newly fetched current blob; no other source changes are present.
7. GitHub compare for the fix commit reports only `companies/company-1/main.html`, with one insertion and one deletion.
8. The branch update used an expected-HEAD lease against `8558108...`; no force update or branch creation was used.

**Current Parent page snapshot — PARTIAL**

The available browser snapshot displays the Employee Custody register, the date/employee/text filter controls, pagination controls, the custody details section, and one visible custody row. The snapshot is not an interaction test and does not establish which source version the browser tab currently serves. The visible text snapshot does not show the earlier `RW_API is not defined` message; browser console/network evidence was not available.

**CI / deployment / runtime — UNVERIFIED**

- GitHub combined commit status returned no status-check entries for the fix commit.
- The available Cloudflare dashboard snapshot shows automatic deployments enabled but its visible Production source is still `8558108...`; that snapshot predates or does not yet reflect the fix commit and is not proof of deployment.
- The deployment dashboard was not refreshed by the connected read-only Browser integration.
- No authenticated click-through test could be performed. Do not report the fix as deployed or E2E verified.

## 6. Data, finance and inventory safety

This patch changes JavaScript name resolution only. It does not alter any request payload, permission check, company/branch scope, API route, RPC, Edge Function, table, trigger, RLS policy, grant, journal, treasury, cash box, supplier balance, custody record or inventory quantity.

No Supabase DDL/DML, Edge deployment, migration, QA fixture or financial/inventory operation was executed as part of this fix. The correction cannot itself create, settle, advance or review a custody transaction; it only makes the already-authored UI event handlers reachable.

## 7. Remaining acceptance gates

1. Confirm a Cloudflare Production deployment whose source commit includes `d514060...` (or a later descendant carrying the same corrected blob).
2. Open a fresh Parent page and capture Console/Network plus the served artifact identity; confirm the stale `RW_API` runtime message is absent.
3. With an authorized Finance session, test date-from/date-to inclusive filtering, employee filtering, text search, reset, previous/next, page-size change and opening details/scroll target.
4. Verify the existing advance, settle, review and document controls still invoke their established flows. Opening controls is sufficient for UI reachability; do not commit a financial operation just to test a click.
5. Navigate away and back, then confirm listener cleanup/rebinding and absence of duplicate actions.

## 8. Rollback

If a regression is detected before further Parent changes, revert only the identifier at the later legacy declaration to `function bind(root)` in a new, non-force commit based on the then-current `main` HEAD. Do not reset or force-move the branch, and do not change the earlier comprehensive binder.

## 9. Closure classification

`PATCH COMMITTED — SOURCE REVERIFIED — DEPLOYMENT / AUTHENTICATED E2E UNVERIFIED`

Do not mark `FIXED AND E2E VERIFIED` until the served Production artifact and authenticated Finance interactions pass the acceptance gates above.
