# Report480 — Picker/Loader Preview Parity: Independent Current-Reality Audit
**Date:** 2026-10-23  
**Scope:** Read-only audit of current operational Picker and Loader source, live Production schema/data shape, and the owner-only surgical change required for Picker preview parity.  
**Status:** `ROOT CAUSE CONFIRMED / OWNER PATCH NOT APPLIED / PRODUCTION UI DEPLOYMENT UNKNOWN / NOT CLOSED`.

## 1. Fresh source identity
- Operational repository: `papamohammed77-glitch/erp-frontend`, branch `main`.
- Current HEAD: `152e5b1d22aab94d2cf01070778b357df4701aff`; parent: `e69c9af4b56d99ba29a4fa74282f78438b9f7010`.
- Current `companies/company-1/warehouse/loader.html`: SHA `97b83d68a683df77c1e0557838c24a1b4fb65169`, 332 lines.
- Current `companies/company-1/warehouse/picker.html`: SHA `d483bd15b36585b975b63c2ef641481a01d5d084`, 1,058 lines.
- Picker file history was checked: last file-specific commit `fbcd4c7e1845236455f026eb3f7ae0ccfa8ba407`; no later Picker file commit appears in the inspected history.
- Historical baseline was fetched independently from `rawaie-erp-review`: Picker SHA `7626ba320021a607854bf219f4bacd81fc3d1d92` (623 lines), Loader SHA `7e61b04d0d9a480d43763e8b7b21f9cbed78409a` (266 lines).
- Current source SHAs match the recent Reports 477–479 checkpoint; this independently confirms that the proposed Picker patch has not yet been applied to the current Git source.

## 2. Live Production checks (read-only)
Project: `SMART ERP`, ref `fiilmooggumokxanwiyx`, PostgreSQL 17.6.1.
- Current counts: `items=18`, `run_sheet_details=12`, `runsheets=2`.
- Current runsheet status aggregate: `Picked=2`; no `Open` or `Confirmed` runsheets are available in the current returned sample. Do not use those live Picked runsheets as mutation fixtures.
- `public.items` contains `description` and `image_url`.
- `public.run_sheet_details` does **not** contain `description`.
- FK `run_sheet_details_item_id_fkey`: `run_sheet_details.item_id → items.id`.
- FK `run_sheet_details_runsheet_id_fkey`: `run_sheet_details.runsheet_id → runsheets.id`.
- The required description read can use the existing FK relation `items!run_sheet_details_item_id_fkey(description)`; no schema alteration is warranted for this defect.
- No Production schema/RLS/RPC/Edge or business data was changed; no test rows were created or deleted.

## 3. Defects independently confirmed in current Picker source
1. In `App.openRunsheet(code)`, current lines 515–519 use `.from('run_sheet_details').select('*')`, so the related item description is not fetched.
2. In the active-session mapping at current line 532, `description: items[i].description || ''` reads a property from the detail row even though that table has no `description` column.
3. The non-active preview block at current lines 570–580 is abbreviated relative to Loader: no visible item description, no requested-quantity/value summary, and limited item cards.
4. Preview cards interpolate database fields into inline `onclick` handlers with only partial quote escaping.
5. `App._img(code)` at lines 585–588 inserts the image URL into HTML and uses inline `onerror`; `App.showItemDetail(...)` at lines 590–594 inserts item fields/image URL without complete escaping and URL validation.
6. Loader's preview is not a business-semantic template to copy blindly: it reports `qty_picked` because Loading starts after Picking. Picker's pre-picking preview should report `qty_ordered` as requested quantity and estimate requested value from `qty_ordered × unit_price`, while showing any existing `qty_picked` only as a separate informational field when relevant.

## 4. Surgical owner patch — source files not edited by assistant
The owner is responsible for operational HTML edits. Do **not** edit `loader.html`, `main.html`, or `core.js`. Do not change Production for this display/query-shape defect.

Use the full, consolidated, current-base replacement blocks in:
`doc/Draft/Reprots/Report477_PICKER_PREVIEW_PARITY_MASTER_CTO_REEXECUTION_20261023.md`
blob SHA `1707a3dbbcac68728817aa2b67609f982159ece3`.

Apply only after re-fetching Picker and verifying its SHA remains `d483bd15b36585b975b63c2ef641481a01d5d084`:
- **A:** in `App.openRunsheet(code)), replace the detail query's `.select('*')` with `.select('*, items!run_sheet_details_item_id_fkey(description)')`, preserving existing company scope and surrounding promise control flow.
- **A2:** replace only `description: items[i].description || ''` with `description: (items[i].items && items[i].items.description) || ''`.
- **B:** replace only the non-active preview HTML block after the active-session return, from its `var html = '';` through `safeHTML(byId('mainContent'), html);`, using Report477 Patch B. Preserve the existing surrounding promise closures. This provides the fuller responsive preview, escaped fields, status gating, requested quantity/value summary, and click/keyboard listeners.
- **C:** replace `App._img(code)` with Report477 Patch C to validate image URLs and remove inline `onerror`.
- **D:** replace `App.showItemDetail(code, name, unit, qty, desc)` with Report477 Patch D to escape text and validate the image URL.
- **E:** replace only the render-and-timer line in `App.renderActiveSession()` with Report477 Patch E so broken-image fallback remains functional after C, without changing session state or timer behavior.

Do not reconstruct replacements from older Reports 471/472/474. If the base SHA differs or any patch is already present, re-diff the new source and apply only the missing hunks.

## 5. Required proof before closure
1. Parse/check the complete modified Picker script.
2. In approved Staging, verify `Open`, `Confirmed`, `Picking`, and `Picked` preview behavior; Start Picking must appear only for `Open`/`Confirmed`.
3. Verify item description via the FK relation, requested quantity/value totals, unit price, line values, responsive layout, and empty runsheet behavior.
4. Test hostile text `< > & " '`, valid HTTPS/root-relative image URLs, `javascript:`, `data:`, `//host`, malformed and broken URLs; verify no execution or layout breakage.
5. Verify click and Enter/Space item-card interaction, back navigation, Dexie active-session restore, and broken-image fallback in both preview and active session.
6. Use authorized and unauthorized/wrong-company users to test tenant isolation.
7. Compare `stock_branches.qty`, `allocated_qty`, and `inventory_log` before/after opening the preview; expected delta is zero.
8. Deploy through the existing frontend pipeline, then independently verify Cloudflare-served HTML identity and authenticated browser E2E. Git commit alone is not deployment evidence.
9. Verify no test residue, then update the current state with source SHA, served artifact identity, test evidence, and remaining gaps.

## 6. Final decision
- **Proven:** current Git identities; current preview mismatch; wrong description property; Production column/FK contract; current Production data counts/status.
- **Not proven:** owner application of the patches, successful Staging tests, Cloudflare served HTML matching Git, authenticated browser E2E, or final deployment.
- **Production action:** none justified at this stage.
- **Operational app action by assistant:** none; owner-only.
- **Closure:** `NOT CLOSED`. Do not claim full completion until the source patch, Staging tests, served artifact, and authenticated browser E2E are verified.
