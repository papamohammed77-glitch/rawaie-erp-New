# Report662 — Buyer «فواتيري» Central Item Catalog Search Fix

**Date:** 2026-11-09 (Africa/Cairo)  
**Task:** Fix item lookup in Buyer → فواتيري → purchase invoice editor.  
**Operational repository:** `papamohammed77-glitch/erp-frontend`, branch `main`.  
**Changed file:** `companies/company-1/purchasing/buyer.html` only.  
**Final source commit:** `00f38aeb7bb7fbbac947b5084838074dbea361b0`.  
**Final Buyer blob:** `2b8be5fb683b185ee3dbd6d44c296484ce26c18b`.

## 1. Evidence and current-state reconciliation

Read the requested execution prompt `writing-block-8-10.md` (1,300 lines), the permanent operating constitution (310 lines), current `CURRENT_STATE.md` beginning at LVE-661, and the relevant Buyer history:
- Report589: `Report589_BUYER_COMPREHENSIVE_APPLICATION_ASSESSMENT_20261103.md` (1,127 lines).
- Report600: `Report600_Buyer` (209 lines).
- Current operational Buyer source and its recent commits.
- Current `core.js`, the deployed `save-purchase-order` Edge Function (v37), SMART ERP schema/policies/RPCs, and the Parent source through its current GitHub file view.

Historical reports were used as navigation, not as proof. Current source and Production were rechecked independently.

## 2. Root cause

The invoice editor previously populated its item list from the shared cached `this.data('items')` snapshot and then performed all typing/filtering locally:

`items.filter([name, item_code, barcode] ...)`

Consequences:
- Typing in the invoice item field did not query `public.items`.
- The editor depended on the state and freshness of the generic GET_DATA/cache path.
- It had no explicit loading/error state for the catalog lookup and no server-side token matching/ranking.
- The same modal's barcode list was tied to the same generic snapshot.

This is a consumer-side catalog lookup defect. The inspected item table and the Buyer user's effective `purchases` permission are present; the database schema or invoice-writing RPC was not the cause.

## 3. Surgical source change

Only `companies/company-1/purchasing/buyer.html` changed. Parent `main.html`, `core.js`, Edge Functions, schema, grants, RLS, triggers, and RPC definitions were not changed.

Changes:
1. Added `loadInvoiceItems()`: reads active items directly from the authenticated Supabase client, explicitly scopes by the current `company_id`, and pages in 500-row ranges. The invoice editor and barcode scanner now use this central catalog read instead of the generic item cache.
2. Added `invoiceSearchTokens()` and `invoiceEscapeIlike()`, matching the Parent's existing smart item search tokenization and wildcard escaping.
3. Replaced the local-only invoice search with `searchInvoiceItems()`: queries `public.items` as the authenticated user, scopes by company and active status, searches item code/name/barcode/search_label, supports up to four ANDed search tokens, and ranks exact code/barcode and prefix matches above ordinary matches.
4. Added a 220 ms debounce, request sequence guard against stale responses, loading feedback, empty-result feedback, and a visible database error state. Selection still binds the returned item object to the invoice line; no price is auto-filled.

Final diff is limited to the catalog-loading and item-search path. Existing invoice payload, operation idempotency, price-entry rules, supplier/PO validation, and accounting/stock semantics remain unchanged.

## 4. Parent and database contract verification

**Parent read consumers:** current Parent `RW_PurchaseGold` uses the same central `items` table and has an existing `purchaseItemSearch()` implementation with tokenization, wildcard escaping, exact/prefix ranking, and active-item filtering. The Buyer search now follows that pattern while also explicitly scoping the query by `company_id`.

**Invoice read integration:** Parent `RW_PurchaseGold.invoices()` reads `purchase_invoices`; its dashboard reads the same table and its filtered Realtime channel subscribes to `purchase_invoices`. The Parent's invoice detail workflow reads `purchase_invoice_details`. No Parent change was necessary.

**Invoice write contract (read-only verified):**
- Buyer `CREATE_PO_INVOICE` is routed by existing `save-purchase-order` v37 to `purchase_create_po_invoice_atomic`.
- The RPC validates the authenticated active company user and effective `purchases` permission, PO/supplier/currency/company scope, item_code existence and active status, item-array limits, and operation idempotency.
- It delegates invoice creation to the existing central atomic invoice writer and classifies the result as `PURCHASE_ORDER` / `SUPPLIER_CREDIT`.
- The central `purchase_invoices` and `purchase_invoice_details` tables remain the common records consumed by Parent. Creating a draft invoice does not itself prove physical receiving, stock movement, or cash payment.

No database write or Edge deployment was performed.

## 5. Verification results

| Check | Result | Evidence / limitation |
|---|---|---|
| Final inline JavaScript parse | PASS | Entire Buyer inline executable script compiled with `new Function`. |
| Scope and item catalog read | PASS (SQL-context simulation) | Under a simulated authenticated Buyer identity with effective `purchases` access, scoped `items` query returned 35 active catalog rows. |
| Arabic multi-token search | PASS (SQL equivalent) | `بسكوت 1011` returned one matching active item under the same company scope. |
| Barcode search | PASS (SQL equivalent) | `1224` returned one matching active item. |
| Parent item-search contract | PASS (source comparison) | Parent uses the same central table, active filter, tokenization, escaping and ranking model. |
| Parent invoice visibility | PASS (source contract) | Parent reads `purchase_invoices` / `purchase_invoice_details` and subscribes to invoice Realtime changes. |
| Database / RPC regression | PASS (read-only inspection) | Existing v37 Edge and atomic RPC contracts were unchanged. |
| Production data safety | PASS | No QA invoice, stock, supplier, treasury, cash-box, journal, custody or other business row was created or modified. SQL checks were read-only and wrapped in rollback transactions. |
| Authenticated Browser E2E | UNVERIFIED | Connected browser exposed read-only tab context; no authenticated Buyer session or click/typing interaction was available. |
| Served-artifact parity | UNVERIFIED | Cloudflare created a Production deployment entry and preview URL for final commit, but the deployed HTML bytes and authenticated runtime behavior were not independently fetched/compared. |

## 6. Source and deployment references

Sequential source commits:
- `0ecab68a4f044c93764a03b02f4f16b28af1b90b` — first direct catalog lookup implementation.
- `8763561117e27eec59d457f926139c173bc1b7ee` — search-term normalization correction.
- `00f38aeb7bb7fbbac947b5084838074dbea361b0` — final alignment with Parent smart-search contract.

Cloudflare Pages dashboard showed a Production deployment entry for final commit `00f38ae`, preview URL:
`https://d0cdfbaa.rawaea-erp.pages.dev`

The final deployment status badge and served-file hash were not independently confirmed. Do not describe the final deployed artifact or authenticated browser behavior as fully verified.

## 7. Rollback and safety

The source change is isolated to Buyer invoice catalog loading/search. Revert the final source commit `00f38aeb7bb7fbbac947b5084838074dbea361b0` to restore the preceding implementation; if reverting the complete sequence, also revert `8763561` and `0ecab68` in reverse order. No database cleanup is required because no business data was written.

## 8. Remaining acceptance gates

1. Verify Cloudflare final deployment status and compare the served `buyer.html` with final Git blob `2b8be5fb683b185ee3dbd6d44c296484ce26c18b`.
2. Sign in with an authorized Buyer account and exercise the actual `فواتيري` invoice editor: Arabic name, partial name, multi-token query, item code, barcode, no-result state, rapid typing/race response, selection, line addition, and modal close/reopen.
3. Verify a safe draft invoice create/update only in an approved isolated/rollback QA context; prove the resulting invoice and lines are visible in Parent, and prove no stock/treasury/cash-box/journal/supplier-ledger movement occurs before actual receiving/payment.
4. Keep the overall Buyer program OPEN. This fix does not close market-purchase receiving, vehicle goods custody, supplier-return acceptance, or full purchasing E2E.

**Final status:** SOURCE FIX COMMITTED · JS PARSE PASS · READ-ONLY RLS/SEARCH CONTRACT CHECKS PASS · PARENT CONTRACT VERIFIED · CLOUDFLARE DEPLOYMENT ENTRY PRESENT · AUTHENTICATED BROWSER E2E AND FINAL SERVED-ARTIFACT PARITY UNVERIFIED.
