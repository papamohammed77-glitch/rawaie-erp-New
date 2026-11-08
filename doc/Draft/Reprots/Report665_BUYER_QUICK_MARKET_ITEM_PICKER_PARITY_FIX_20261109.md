# Report665 — Buyer Quick-Market Invoice Item Picker Parity Repair

**Date:** 2026-11-09 (Africa/Cairo)  
**Task:** Restore item lookup, barcode-camera scan, item selection and manual purchase-price entry in Buyer → فواتيري → شراء سوق سريع.  
**Operational repository:** `papamohammed77-glitch/erp-frontend`, branch `main`.  
**Final source commit:** `c058125ee66e60ff627be6e49d90a7335ca69383`.  
**Final Buyer blob:** `7a4ae8472c21292895cf72e1ae637e04047a7dbf`.  
**Related generated CSS commit:** `ff8982e5b47bb1afd3648b1f93486192c7dcb949` (adds the one new `border-violet-300` utility used by the camera button).

## 1. Correctly identified the actual workflow

Buyer has three distinct item-entry surfaces that must not be conflated:

- `createPO()`: purchase-order item picker.
- `createPurchaseInvoice()`: PO supplier-invoice editor.
- `quickPurchase()`: direct market purchase invoice (`purchase_source = QUICK_MARKET`).

The previous LVE-662/663/664 investigation and fixes were concentrated on the PO invoice editor's `loadInvoiceItems()` / `searchInvoiceItems()` path. They did not restore the separate `quickPurchase()` market-invoice picker. The user was reporting the latter.

This was the principal workflow-scope miss: the item picker in the PO modal and the item picker in the market-purchase modal were implemented independently. A repair in the PO invoice editor cannot automatically change the market-purchase modal.

## 2. Source findings before the patch

The current `quickPurchase()` implementation showed:

1. It loaded items through `this.data('items')`, which could reuse the app's 20-second cache instead of forcing the same fresh central catalogue path already established for the PO invoice editor.
2. Its search renderer `renderQuickSearch()` used only lowercase substring matching across `name`, `item_code`, and `barcode`. It did not use the Arabic/Persian normalization and token matching already implemented by `invoiceNormalizeSearch()` / `invoiceSearchTokens()`; therefore character-form differences (including Persian Yeh in stored item names) could cause false no-results.
3. It had no camera scan button or scan event binding, despite the PO picker using the shared `buyerScanBarcode(items, callback)` helper.
4. Its search-result selection was implemented as inline `onclick` markup. Core `RW_UI.safeHTML()` was inspected and confirmed to assign `innerHTML` directly (it does not sanitize/strip inline handlers); therefore inline handlers were not falsely blamed as a proven root cause. The patch nevertheless replaces inline selection with explicit event listeners for a clearer and more reliable picker contract.
5. The quick-market cart already supported manual entry of the actual purchase price and quantity after item selection. The market purchase must continue to use the actual supplier invoice price, not substitute the catalogue's last cost.

## 3. Surgical correction

Only the market-purchase picker path was changed in `buyer.html`:

- `quickPurchase()` now loads items via `this.loadInvoiceItems()`, which forces a fresh `this.data('items', true)` read through the existing permission-aware `GET_DATA` gateway and retains active-item filtering. The returned active catalogue is also the catalogue used by `quickAddItem()`.
- Added a camera scan button to the quick-market item-search control and bound it to the same `buyerScanBarcode()` implementation used by the PO modal. A unique barcode/item-code match adds that item to the quick cart; ambiguous/unavailable camera cases retain the helper's explicit feedback and manual search/USB scanner path.
- Reworked `renderQuickSearch()` to use the shared Arabic-aware normalization and multi-token matching across item name, item code, barcode and search_label.
- Results now show item name, code, barcode and unit. Selection uses explicit `addEventListener` bindings, sets the search field to the selected item and adds the item to the quick cart.
- The cart continues to require the buyer to enter the actual purchase price manually. No catalogue last-cost value is substituted or presented as the transaction price.
- The PO creation modal was restored unchanged; the final net diff against the LVE-664 base does not include a `createPO()` behavior change.

## 4. Verification performed

| Check | Result |
|---|---|
| Final inline JavaScript syntax compilation | PASS |
| Quick-market path uses forced central catalogue loader | PASS |
| Quick-market camera button and scan callback | PASS (source wiring) |
| Partial Arabic search with Persian Yeh in stored item name (query `ويفر` vs `ویفر`) | PASS (controlled method harness) |
| Barcode and unit visible in result | PASS (controlled method harness) |
| Result selection listener is bound | PASS (controlled method harness) |
| Selection adds intended item to quick cart | PASS (controlled method harness) |
| New quick-cart line starts with blank/manual price (`unit_price: null`) | PASS |
| No inline `onclick` remains in quick-market search renderer | PASS |
| PO picker net behavior | Preserved; no final net change to `createPO()` |
| Live authenticated browser E2E / actual camera permission and physical scan | UNVERIFIED |
| Cloudflare terminal deployment Success and served-byte parity | UNVERIFIED |

The controlled harness used a representative catalogue row with item code `1011`, barcode `1224`, name `بسكوت ویفر 5ج`, and unit `قطعة`. It verified normalized partial search, visible item metadata, event binding, selection, and the manual-price state. This is a code-level harness, not a claim of a live authenticated browser test.

## 5. Business and data safety

No Supabase schema, RLS, grants, Edge Function, RPC, stock, supplier ledger, cash box, custody, treasury or accounting code was changed. No invoice create/update operation was invoked by the test harness. No production business rows were written.

The existing market-purchase contract remains intact: this document is a draft market invoice; item selection and entering a price do not themselves receive goods into branch stock, post supplier balances, pay cash, or create a journal. The existing invoice attachment, custody reservation and handover validations were not altered.

## 6. Deployment and remaining acceptance gates

GitHub main now contains the final source at commit `c058125ee66e60ff627be6e49d90a7335ca69383`. The generated Tailwind CSS commit adds the required violet border utility for the scan button. This does not by itself prove Cloudflare has completed a successful production deployment or that the served HTML/CSS bytes match the current GitHub files.

Required final acceptance:
1. Confirm Cloudflare Production deployment reaches terminal Success and serves the final `buyer.html` plus `buyer.tailwind.css`.
2. Sign in to Buyer, open **فواتيري → شراء سوق سريع**, type partial Arabic name, full name, code and barcode; select a result; confirm it appears in the cart.
3. Test camera scan on a supported browser/device with camera permission, and a USB scanner that types into the search field.
4. Enter quantity and actual supplier purchase price; verify cart total and save only a deliberate draft with a valid supplier invoice attachment and required custody/settlement data.
5. Confirm the draft appears in the Buyer invoice list and receiver flow as designed, with no premature stock or accounting posting.

**Final status:** WORKFLOW MIS-SCOPE IDENTIFIED · QUICK-MARKET PICKER REPAIRED IN SOURCE · ARABIC NORMALIZED SEARCH + CAMERA SCAN + MANUAL PRICE PATH WIRED · SCRIPT AND CONTROLLED PICKER TEST PASS · NO BUSINESS SIDE EFFECTS · LIVE BROWSER / CLOUDFLARE DEPLOYMENT ACCEPTANCE STILL OPEN.
