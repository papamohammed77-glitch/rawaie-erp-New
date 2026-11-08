# Report666 — Buyer Quick-Market Item Selection Race with Realtime Cache Invalidation

**Date:** 2026-11-09 (Africa/Cairo)  
**Task:** Fix Buyer → فواتيري → شراء سوق سريع: a visible item search result could fail to become a line in the invoice cart, preventing completion.  
**Operational repository:** `papamohammed77-glitch/erp-frontend`, branch `main`.  
**Changed file:** `companies/company-1/purchasing/buyer.html` only.  
**Previous Buyer commit:** `c058125ee66e60ff627be6e49d90a7335ca69383`.  
**Fix commit:** `0c5f1ed53e4d96d6cb5db52f938aa21298274cb0`.  
**Final Buyer blob:** `56b3ef8fed56f4ac788b4535c371aae16a8f901e`.

## 1. Exact root cause

The preceding LVE-665 work rendered the quick-market search results from the modal-local array `items`:

- `renderQuickSearch(items, query)` found the correct row from this local array.
- The result click handler then called `self.quickAddItem(index)`.
- The barcode callback also called `self.quickAddItem(items.indexOf(item))`.
- But `quickAddItem(index)` did **not** use the array that generated the result. It fetched the selected row from the mutable shared `this.cache.items` array.

This was an unsafe split source of truth. The Buyer app's Realtime `onEvent` handler calls `self.invalidate()` before checking whether the event is relevant to the current tab. `invalidate()` clears `this.cache` and `this.cacheAt`. Therefore a Realtime event arriving while the quick-market modal remained open could clear `cache.items`, while the modal-local `items` array and its visible result buttons remained alive.

On selection, the old function then read `this.cache.items[index]`; because that cache could now be empty (or no longer index-aligned), it returned without adding a line. The user could see and click a matching item, but the cart stayed empty and the invoice pre-confirm check rejected completion.

This relationship was confirmed by source inspection and reproduced in a controlled test by clearing `App.cache.items` after rendering the result but before clicking it.

## 2. Surgical repair

Only the quick-market item-selection path in `buyer.html` changed:

1. Search-result click now calls `quickAddItem(index, items)`.
2. Camera barcode callback now calls `quickAddItem(items.indexOf(item), items)`.
3. `quickAddItem(index, catalog)` uses the explicitly supplied modal catalogue whenever it is an array, falling back to the shared cache only for any legacy caller.
4. It validates that the index is an integer and within catalogue bounds, and that the selected row contains an item code before attempting to add it.
5. Existing duplicate-item handling, quick-cart row shape, quantity default, blank manual price, and render behavior remain unchanged.

The selected row now comes from the same catalogue snapshot that produced the visible search result. A later Realtime cache clear can no longer invalidate the user's in-progress selection.

## 3. Verification

| Test | Result |
|---|---|
| Final inline JavaScript syntax compilation | PASS |
| Reproduced old failure: local result remains visible after shared cache is cleared | PASS (failure reproduced) |
| Old behavior after cache clear: selected line is not added | PASS (failure reproduced) |
| Fixed behavior after cache clear: correct item is added from modal-local catalogue | PASS |
| Quick-cart row retains expected item code/name/unit and quantity 1 | PASS |
| Price remains null/blank for explicit manual supplier-price entry | PASS |
| Search result click handler passes modal catalogue | PASS (source + harness) |
| Camera callback passes modal catalogue | PASS (source wiring) |
| Invalid/out-of-range selection index safely rejected | PASS (guard added; source verified) |
| Final Git diff scope | PASS — only `buyer.html`, 9 additions / 4 deletions |
| Production invoice write / stock or accounting effect | NONE — no create/update/preConfirm business request executed in test |
| Authenticated live browser / physical camera test | UNVERIFIED |

The controlled harness ran the extracted production search and selection methods. Test catalogue row: code `1011`, barcode `1224`, name `بسكوت ویفر 5ج`, unit `قطعة`. The harness rendered the normalized partial search result, emptied the shared cache to model Realtime invalidation, then invoked the actual result click handler. The correct item was added to the cart and its purchase price remained blank.

## 4. Business/data safety

No DB schema, RLS, grant, Edge Function, RPC, invoice API, custody, supplier account, stock, payment, cash-box, accounting or treasury code was changed. No production row was inserted or updated. The patch only repairs which already-loaded item object is passed from the UI result to the in-memory invoice cart.

The market invoice continues to require supplier, branch, supplier invoice number, valid quantity, explicit positive actual purchase price, and the existing attachment/settlement conditions. It remains a draft workflow; this change does not receive stock, settle cash, post supplier debt, or create journal entries.

## 5. Deployment gate

GitHub main contains fix commit `0c5f1ed53e4d96d6cb5db52f938aa21298274cb0`. Cloudflare terminal Production Success and served-file byte parity were not proven during this repair. Authenticated Buyer browser acceptance is still required after deployment.

Acceptance scenario: open quick-market modal, enter supplier/branch/invoice number, search an item, trigger or wait for Realtime cache invalidation while the modal is open, select the visible result, enter quantity and actual price, attach supplier invoice image/PDF, and save a draft only after all existing guards are satisfied. Also verify barcode selection under camera permission.

**Final status:** ROOT CAUSE CONFIRMED · REALTIME CACHE / MODAL CATALOGUE RACE REPRODUCED · ITEM SELECTION FIX COMMITTED · REPRODUCTION HARNESS PASS · NO BUSINESS SIDE EFFECTS · LIVE BROWSER / CLOUDFLARE ACCEPTANCE OPEN.
