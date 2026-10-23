# Report476 — Picker Preview Parity: Fresh Production Revalidation and Owner Execution Record
**Date:** 2026-10-23  
**Scope:** `papamohammed77-glitch/erp-frontend/companies/company-1/warehouse/picker.html` only.  
**Status:** SOURCE/PRODUCTION CONTRACT REVALIDATED / OWNER PATCH REQUIRED / NOT CLOSED.

## PRE-CHANGE SELF-AUDIT

- **Business understanding:** Picker previews a runsheet, captures picked quantities/notes in a device-local draft, and submits picking through existing server contracts. Opening a preview must not mutate stock, reservations, or accounting.
- **Architecture understanding:** Loader uses shared `core.js` helpers; Picker currently uses its own Supabase client and Dexie session store. This task is UI/data-read integration only; do not merge auth architecture or rewrite lifecycle.
- **Database understanding:** Rechecked live Production schema, foreign keys, policies, and status aggregate at 2026-10-23 14:17–14:18 UTC.
- **Historical understanding:** Compared the New/Original picker and review-repository historical picker; both are SHA `7626ba320021a607854bf219f4bacd81fc3d1d92`. Read Report475 and the latest CURRENT_STATE checkpoints; older reports are context, not current truth.
- **Production understanding:** Project `fiilmooggumokxanwiyx`, PostgreSQL 17.6. No schema/RLS/RPC/Edge/data changes were made or are justified by this display defect.
- **Current understanding:** Loader source SHA `97b83d68a683df77c1e0557838c24a1b4fb65169`, 332 lines. Picker source SHA `d483bd15b36585b975b63c2ef641481a01d5d084`, 1058 lines. These are fresh full-source reads from the operational repository.
- **Execution confidence:** High for the source/schema defect and exact owner patch; not a runtime closure because the owner must apply the operational HTML change and run browser E2E.

### Confirmed facts
1. Current Picker still has an abbreviated non-active runsheet preview; it does not match the current responsive Loader preview.
2. Picker reads `run_sheet_details.select('*')`, but Production `run_sheet_details` has no `description` column.
3. Production has `items.description` and FK `run_sheet_details_item_id_fkey: run_sheet_details.item_id → items.id`; the description must be fetched through `items!run_sheet_details_item_id_fkey(description)`.
4. Current active-session mapping reads `items[i].description`, which is not a real `run_sheet_details` column and therefore needs to read the joined relation.
5. Current item-card construction interpolates DB values into inline click-handler strings. Current image/detail rendering also needs URL validation and text escaping. Report475's consolidated patches C–E handle these adjacent paths and preserve broken-image fallback in both preview and active session.
6. Production schema/RLS currently supports the intended read path for authorized warehouse users: `items_select_company` permits same-company `items` reads with `warehouse` or `items` permission; `run_sheet_details_select_current_tenant` scopes details through the same-company runsheet and warehouse/runsheets/reports permissions. Do not widen grants or alter RLS for this UI issue.
7. Live SQL at 2026-10-23 14:17:01 UTC returned PostgreSQL 17.6, 18 items, 12 run_sheet_details rows, and status aggregate `Picked: 2` only. No Open/Confirmed runsheet was available in this status result for safe Production start-picking tests.
8. Current operational source has not been edited by the assistant; no fixture/test row was created or deleted. Cloudflare served HTML parity and authenticated browser E2E remain unverified.

## CURRENT / HISTORICAL / TARGET COMPARISON

| Concern | Historical / Original | Current Loader | Current Picker | Target decision |
|---|---|---|---|---|
| Runsheet overview | Compact list of requested items | Responsive summary/cards | Abbreviated item list | Bring Picker preview presentation up to Loader quality while retaining Picker-specific meaning |
| Requested vs picked quantities | Basic item detail | Displays requested and prepared quantities | Basic requested quantity only | Show both requested and already-picked values; totals are requested quantities in Picker |
| Description | Item detail passed through existing data path | Reads available details | Reads nonexistent `run_sheet_details.description` | Join `items.description` using the verified FK |
| State gating | Start only through Picking lifecycle | Preview only for `Picked` | Preview for non-active states | Start button only for `Open`/`Confirmed`; `Picked` and other states read-only |
| Click handling | Inline handlers present historically | Event listeners for preview controls | DB values embedded in inline handler | Use data index + event listeners; preserve keyboard Enter/Space |
| Image fallback | Inline `onerror` | Shared image helper | Local `_img` helper | Validate URL and attach listeners without inline handlers; preserve fallback in active session |
| Stock / reservation | Existing transactional lifecycle | Preview states no stock change | Preview should be read-only | No stock/allocated_qty/inventory_log writes from preview |

## EXACT SURGICAL OWNER PATCH

**Do not edit Loader, main.html, core.js, Supabase schema/RLS/RPC, or any Edge Function. The owner applies the operational Picker patch.**

File: `erp-frontend/companies/company-1/warehouse/picker.html`  
Verified base SHA: `d483bd15b36585b975b63c2ef641481a01d5d084`

Use the complete, consolidated and corrected code blocks in **Report475**:
`doc/Draft/Reprots/Report475_PICKER_PREVIEW_PARITY_CONSOLIDATED_CTO_EXECUTION_20261023.md` (latest blob SHA recorded in CURRENT_STATE: `130cca676845487a4106c3252ce531e88e430eff)).

Apply in this order, only if a fresh re-fetch confirms the base SHA has not changed:

1. **Patch A — query:** In `App.openRunsheet(code)`, replace `.from('run_sheet_details').select('*').eq('runsheet_id', rs.id)` with `.from('run_sheet_details').select('*, items!run_sheet_details_item_id_fkey(description)').eq('runsheet_id', rs.id)`.
2. **Patch A2 — active-session mapping:** Replace `description: items[i].description || ''` with `description: (items[i].items && items[i].items.description) || ''`.
3. **Patch B — preview:** Replace only the non-active preview block beginning at its `var html = ''` after the active-session `return;` and ending at `safeHTML(byId('mainContent'), html);`, before the existing Promise closures. Keep all surrounding Promise/control-flow closures unchanged.
4. **Patch C — images:** Replace the complete `App._img(code)` function with Report475 Patch C.
5. **Patch D — item detail modal:** Replace the complete `App.showItemDetail(code, name, unit, qty, desc)` function with Report475 Patch D.
6. **Patch E — active-session fallback:** In `App.renderActiveSession()`, replace only `safeHTML(byId('mainContent'), html); this.startTimer();` with Report475 Patch E.

**Important:** Do not use older Report471/472/474 Patch B or the older inline-`onerror` Patch D. Report475 is the corrected consolidated set and includes the active-session image fallback correction. The exact full replacement blocks are intentionally kept in Report475 to avoid creating a second, divergent copy.

## PRODUCTION REVALIDATION — READ ONLY

Checked at 2026-10-23 14:17:01–14:18:09 UTC:
- PostgreSQL 17.6.
- `items`: `id, company_id, item_code, name, unit, description, image_url` present.
- `run_sheet_details`: `item_id, runsheet_id, item_code, item_name, unit, unit_price, qty_ordered, qty_picked` present; `description` absent.
- FK `run_sheet_details_item_id_fkey` and `run_sheet_details_runsheet_id_fkey` confirmed.
- `runsheets.company_id → companies.id` confirmed.
- RLS policies for same-company reads confirmed for the required authenticated warehouse flow.
- Status aggregate: `Picked: 2`; no `Open` or `Confirmed` rows in the returned aggregate.
- No Production DDL, policy/grant, RPC, Edge Function, or business data changes performed. Production changes are not appropriate for this presentation/query-shape defect.

## TEST / DEPLOY / CLOSURE CHECKLIST

After the owner applies the patch:
1. Re-fetch Picker and record its new blob SHA before edits; stop and rebase the patch if the SHA differs.
2. Run JavaScript syntax parsing against the full HTML script blocks.
3. In approved Staging, verify Open and Confirmed previews, Picked read-only preview, empty runsheet handling, back navigation, card click + Enter/Space, joined description, requested/picked totals, and estimate calculations.
4. Verify text such as `< > & " '` renders as text, not markup; test valid HTTPS/root-relative image URLs, `javascript:`, `data:`, `//host`, malformed URLs, and broken images.
5. Verify active Picking session restoration from Dexie and active-session image fallback; verify start/cancel/complete/reopen continue through the existing contracts.
6. Compare `stock_branches.qty`, `allocated_qty`, and `inventory_log` before/after preview. Expected delta: zero.
7. Test same-company authorized user and unauthorized/wrong-company user; verify no cross-company data leakage.
8. Deploy through the existing frontend pipeline; compare the served Cloudflare HTML with the intended Git artifact and run authenticated browser E2E. Do not use the two live Picked rows as mutation fixtures.
9. Verify no test residue remains and append evidence to CURRENT_STATE.

## SELF-AUDIT FINAL

- **What I proved:** Current Loader/Picker source identities; exact picker defect locations; Production columns, foreign keys, RLS read contract, PostgreSQL version, and current runsheet status aggregate.
- **What I did not prove:** Cloudflare-served HTML parity, owner-applied source changes, authenticated browser E2E, or successful Staging tests.
- **What I fixed:** No operational file was modified because project governance explicitly assigns operational-app edits to the owner. I refreshed Production evidence and documented the exact consolidated patch.
- **What I initially missed:** A prior preview patch alone would have removed inline image error handling also used by the active session; Report475 Patch E restores that fallback.
- **What could still be wrong:** A concurrent source edit could invalidate the base SHA; actual browser rendering, image failures, keyboard behavior, and authorized nested relation reads still require runtime testing.
- **Final confidence:** High for diagnosis and patch targeting; not enough to claim runtime closure.
- **Final closure status:** `OWNER PATCH READY / PRODUCTION CONTRACT VERIFIED / SOURCE NOT APPLIED / SERVED PARITY + BROWSER E2E OPEN / NOT CLOSED`.

## Instructions for the next session
Start by reading this report and the latest CURRENT_STATE checkpoint. Re-fetch the live operational Picker from `erp-frontend/main` and compare its SHA with `d483bd15b36585b975b63c2ef641481a01d5d084`. If changed, inspect the diff and rebase only the applicable surgical hunks. Do not re-open already-proven Production schema facts without a new contradiction. The owner applies the HTML changes; after that, perform syntax/Staging/served-artifact/browser verification and update CURRENT_STATE with evidence. Never report closure based on a report or Git alone.
