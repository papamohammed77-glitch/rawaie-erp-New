# Report562 — RAWAEA Data Entry Master App: Source Study, Owner Candidate, and Production Security Gate

**Date:** 2026-10-30  
**Status:** `OWNER-READY HTML CANDIDATE GENERATED / NOT COMMITTED TO OPERATIONAL REPO / NOT DEPLOYED / CRITICAL PRODUCTION ACL FINDING OPEN / NOT PRODUCTION READY`

## 1. Executive decision

A standalone Arabic RTL candidate for the item-data entry application has been prepared as a downloadable artifact in the task conversation. It is intended for the canonical repository location:

`companies/company-1/warehouse/data.html`

No operational HTML file was created or modified in GitHub. This is required by the permanent operational constitution and Report545: the owner applies changes to `companies/company-1/main.html` and other operational HTML files. The candidate is **not** deployed, not yet connected to a browser session, and must not be described as a production-ready golden/diamond app.

A critical existing Production database privilege exposure was also confirmed while checking the item/category contracts. It predates this candidate and is not caused by the new HTML. Because its blast radius includes shared master tables and consumers outside this feature, no DDL, RLS, grant, data, or deployment change was made in this task. Resolve that security gate before exposing the new application to users.

## 2. Starting point and governance

- Read `CURRENT_STATE.md` first (current file Blob at start: `eb9c41ae3b4d7b1f076b5866ca0618bd7be86477`). The file had LVE-560 at its opening “latest” header but a later LVE-561 checkpoint appended near the end. This is a continuity defect; LVE-562 is to be promoted to the opening checkpoint while preserving prior history.
- Read the permanent operational constitution, Blob `365a5178810d8da37f55dba64bf422f328a966bd`.
- Read Report545, Blob `e153396709ecfcc0552347db84e37c98ad8bcdd6`. Its controlling boundary is explicit: operational HTML remains owner-applied; the assistant prepares exact owner changes and verifies other layers, and never conflates source, deployment, and runtime.
- Read Report560, Report561, and the operational memory ledger. The Returns issue remains an unrelated open lifecycle task; this task does not re-open or change its code.
- Operational repo: `papamohammed77-glitch/erp-frontend`, branch `main`, latest commit observed `2e9777a23f44e1b009810c0936513a76e64cc741` (“Update returns.html”; that commit changed only the Returns file).
- Current Parent `companies/company-1/main.html` Blob: `3a5d2e565a04262081d024f6e514e1372d372e84`. Shared `core.js` Blob: `ff2f581d9900543c16f7cb026e13446520c0329d`. Service worker Blob: `6123fce8b99391d70e6937bde5c4fcbd3f2d8f48`.
- Both `companies/company-1/warehouse/Data.html` and `companies/company-1/warehouse/data.html` were absent at inspection; the uppercase `companies/company-1/Warehouse/` path was also absent. Existing warehouse apps use the lowercase `warehouse/` directory and lowercase filenames. The candidate and owner link therefore use `warehouse/data.html` to avoid creating a parallel case-sensitive directory.

## 3. Deep Parent Items-tab study

The Parent file was fetched as a blob and analyzed (1,800,412 characters; 33,350 lines). The `RW_Items` module occupies approximately lines 4881–6740 (93,585 characters; 1,860 lines).

Confirmed functional baseline:

1. **Items list/table:** name, code, category, sales price, total stock, dynamic per-branch columns, stock state, product thumbnails, sorting, and pagination through `RW_Table.paginate` at 50 rows per page. Clicking the item opens the full item editor; clicking its image opens the large image viewer.
2. **Subtabs:** item list, stock-movement report, branch stock matrix, and Excel/CSV balance upload.
3. **Item editor:** three panels — basic data, prices/stock, marketing/offers — including barcode, name, category/category ID, base and alternate units, conversion quantity, cost/sales/old prices, reorder/max quantities, weight/volume, description, image, active/store visibility, discount dates, daily deal, badge, store display quantity, and sort order.
4. **Category modal:** list, create, rename, delete, and replacement category for linked items. The current service contract accepts `parent_id`, `image_url`, and `icon` on category updates; omitting them in an update would clear existing metadata. The candidate preserves those values.
5. **Movement report:** reads `inventory_log`, calculates opening and running balances, and supports item/date/branch filters. The Parent also lets users click total-stock and branch-stock cells to open the same movement report.
6. **Branch matrix:** reads `stock_branches`, distinguishes physical quantity from allocated quantity, and exposes branch/item movement navigation.
7. **Bulk upload:** the current UI supports `replace`, `add`, and `deduct`, previews before execution, and uses the existing central bulk-adjustment endpoint and atomic RPC.
8. **Image behavior:** product thumbnails, a large image viewer, and upload through the existing `product-images` storage bucket.

The Parent remains the canonical functional reference; the standalone app is not a second business-data authority.

## 4. “Golden/diamond” application standard — evidence, not invented labels

No official registry naming specific applications as “golden/diamond” was found in the checked CURRENT_STATE, Report500, Report545, Report560, or Report561 content. I will not invent such a classification. The closest verified design/architecture references are the Parent Items module and standalone warehouse applications `picker.html` / `loader.html` using the shared core and service-worker contract. The candidate follows these measurable criteria:

- shared `core.js` authentication/session and permission checks;
- company-scoped reads and server-authorized writes;
- reuse of existing Edge Functions/RPCs; no new table or Edge Function;
- explicit validation and post-save readback for key item fields;
- responsive Arabic RTL UI, product images, filters, sorting, pagination, modals, Excel export, and preview-before-bulk-write;
- separate permissions for item master data, branch reads, stock movement, and stock adjustments;
- no direct writes to `items`, `categories`, `stock_branches`, or `inventory_log` from the browser;
- explicit handling of ambiguous item-creation network failures and stable bulk-operation fingerprints for retries.

## 5. Existing Production contracts confirmed read-only

Active deployed functions inspected:

| Function | Active version | Deployed source SHA |
|---|---:|---|
| `save-item` | 15 | `21e55a8630858b6d008ba6fa1448f6bef1c33f02979e489a113b5dc3fd108351` |
| `delete-item` | 5 | `fab4e53f5d2f7b94fb04cf79dfbfe0971d81c121385a07b1bee7524001d4055a` |
| `save-category` | 5 | `fc0153a725846ad6b1194fa5b219a60f23bad09fc74b211fc1161160e71da07b` |
| `bulk-stock-adjustment` | 8 | `01d8fa207ab2296568a6b05688ff7b35dc282902ecb6a5c7aa1793321f6db24a` |

The existing create path calls `create_item_with_opening_stock`; the bulk adjustment endpoint calls `post_inventory_adjustment_atomic`. No new function was created.

The candidate includes a guard for a confirmed current contract mismatch: `save-item` v15 uses `Number(item.reorder_point) || 5`, so an input value of zero is silently changed to five. The candidate refuses to save a zero reorder point rather than silently changing it. It also treats `store_display_qty` as an integer, matching the deployed function's stated validation contract. These are safeguards in the candidate, not repairs to the deployed Edge Function.

## 6. Critical Production security blocker — no mutation performed

Read-only SQL confirmed RLS is enabled on `items`, `categories`, `branches`, and `stock_branches`. The same query confirmed:

- `anon` has table privileges `SELECT/INSERT/UPDATE/DELETE/TRUNCATE` on `items`, `categories`, and `branches`;
- `anon` also has `TRUNCATE` privilege on those three tables;
- `authenticated` has `TRUNCATE` privilege on those three tables;
- the `categories` policy `Allow all for all` has roles `{public}`, command `ALL`, and `qual = true`;
- `stock_branches` does not grant anon insert/update/delete/truncate in the same privilege check.

RLS does not constrain PostgreSQL `TRUNCATE`. Therefore this is a **critical privilege-layer exposure**. For `categories`, the broad public ALL policy plus anon DML privileges also allows public-policy authorization for direct mutations. I did not issue a destructive HTTP or SQL test, and I did not change grants or policies.

**Release gate:** do not deploy or expose the new app until a dedicated, consumer-aware least-privilege review determines the safe revocation/policy change for `items`, `categories`, and `branches`, checks public-store read requirements, and supplies a rollback plan. This is broader than the Data app and should not be “fixed” by a guessed single-table policy edit.

## 7. Candidate artifact and tests

- Candidate file generated locally for owner application: `/mnt/data/data.html`.
- SHA-256: `131b6655155ed353d7d1f766a0efc5b2b07de1579c406b60cbc5eb1ca1d9dd05`.
- Size: 82,081 bytes; 173 physical lines; inline JavaScript: 71,597 bytes.
- HTML parser: PASS.
- Node `--check` for all inline JavaScript: PASS.
- Static contract checks: PASS for shared core, company-scoped reads, existing Edge endpoints only, no direct business-table writes, no invented Edge endpoint, branch-cell movement navigation, cost validation for nonzero inventory adjustments, retry fingerprint preservation, uncertain-create reconciliation lock, and unique static IDs.
- No authenticated browser session was available for a real runtime test. No browser E2E, Production write, operational HTML change, deployment, or live data mutation occurred. Runtime, deployed artifact, and business-data effects remain UNVERIFIED.

## 8. Owner change set — exact and minimal

### A. New file

Add the candidate as:

`companies/company-1/warehouse/data.html`

Do not create a new uppercase `Warehouse/` directory. The candidate loads `../core.js`, `../manifest.json`, and `../sw.js`; the existing service worker fetches HTML/runtime/API requests from the network and does not maintain an HTML precache list, so no SW precache edit is required.

### B. Parent navigation insertion

In `companies/company-1/main.html`, inside the existing `إدارة المخازن والمخزون` submenu, immediately after:

```js
{ view: 'items', label: 'الأصناف' },
```

insert only:

```js
{ action: 'openWarehouseData', arg: '', label: 'مدخل بيانات الأصناف', icon: 'fa-keyboard', perm: ['items'] },
```

### C. Parent action handler insertion

Inside the existing `RW_Navigation._handleAction(action, arg)`, before the current `showFinanceTab` branch, insert:

```js
if (action === 'openWarehouseData') {
    this._hideTooltip();
    var base = window.location.pathname.replace(/\/main(?:\.html)?\/?$/, '/');
    if (base === window.location.pathname) base = window.location.pathname.replace(/[^/]*$/, '');
    window.location.href = base + 'warehouse/data.html';
    return;
}
```

These are **owner-applied patches only**. Re-fetch the current Parent blob and verify unique anchors before application. Do not edit the Parent file directly from the assistant. After owner application, re-parse the full inline JavaScript, verify permission visibility, navigate from Parent to Data and back, and confirm shared session/company scope.

## 9. External product-master references

The candidate adopts only principles that fit the current RAWAEA schema: one shared product definition, stable item identifier/barcode, category association, units/conversion, product image, search/filter, and controlled import/export. It does not invent product variants, multilingual fields, or external supplier/customer identifiers that are not represented by the current schema.

- Microsoft Dynamics 365 — Product information overview: https://learn.microsoft.com/en-us/dynamics365/supply-chain/pim/product-information
- Microsoft Dynamics 365 — Product identifiers: https://learn.microsoft.com/en-us/dynamics365/supply-chain/pim/product-identifiers
- SAP S/4HANA — Product Master: https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/bc6b9325fedd4344a84412b2195064fa/3643f8566afb45ab8703a1f6600d3d88.html

These references support centralized, consistent product master data and identifiers; they do not prove feature parity or runtime correctness in RAWAEA.

## 10. Final status and next action

**CONFIRMED:** Parent Items baseline studied; candidate HTML produced and statically checked; existing deployed contracts identified; critical database privileges found read-only.

**UNKNOWN/UNVERIFIED:** browser runtime/E2E, exact deployed artifact for the new app (it does not exist yet), user-role permission matrix in a real session, and whether the app can safely be released before ACL hardening.

**CONFLICT:** current state file opening checkpoint still named LVE-560 while LVE-561 existed later in the same file; the operational repository has a lowercase `warehouse/` directory while the requested path used uppercase `Warehouse/`.

**NOT DONE:** no operational Git commit, no Parent edit, no Production DDL/DML/RLS/grant change, no deployment, and no claim of production readiness.

**Next priority:** handle the confirmed `anon/authenticated TRUNCATE` and public category-policy exposure in a separate bounded security change after auditing consumers and rollback. Only then have the owner add the new HTML and Parent menu link, and run authenticated browser E2E.