# Report664 — Buyer Invoice Item Catalog RLS / Permission Path Fix

**Date:** 2026-11-09 (Africa/Cairo)  
**Task:** Resolve Buyer → «فواتيري» → invoice editor item search still returning no items while typing partial Arabic names.  
**Operational repository:** `papamohammed77-glitch/erp-frontend`, branch `main`.  
**Changed file:** `companies/company-1/purchasing/buyer.html` only.  
**Previous commit:** `2c09b84f785aad06b51c8ec73cbe48d574de0ca5`.  
**Fix commit:** `1262c4603cb84219549b877b79f40d2d409761ee`.  
**Final Buyer blob:** `aac61d7e3127a4061b0afe57cdc3b2bf6e3e4519`.

## 1. Confirmed root cause — authorization contract mismatch

The prior LVE-662/663 code queried `public.items` directly using the authenticated Supabase client. The Buyer UI entry guard, however, explicitly allows users with any of:
- `purchases`
- `finance`
- `finance_manager`
- owner

The current `items` SELECT RLS policy only recognizes effective `items`, `warehouse`, `data-entry`, or `purchases` permissions. It does **not** recognize `finance` or `finance_manager`.

This mismatch was reproduced against current SMART ERP Production using the existing Finance and Buyer account identities in read-only rollback SQL contexts:

| Simulated authenticated role | Effective permission tested | Active items visible through direct RLS SELECT |
|---|---:|---:|
| Buyer / purchasing | `purchases=true` | 35 |
| Accountant / finance | `finance=true` | 0 |
| Finance manager | `finance_manager=true` | 0 |

The company has 35 active catalog items. A privileged read confirmed that partial Arabic name matching is available in the data itself: a single Arabic letter `ب` matches 26 active items, `بسكوت` matches 2, item code `1011` matches 1, and barcode `1224` matches 1.

Therefore the direct client query could legitimately return an empty array under Finance/Finance Manager RLS even though the same users were allowed into Buyer and authorized to use its invoice workflow. The empty result was silent at the UI level: it appeared as “no matching item”, not a missing catalogue.

## 2. Existing secure central read route

The current `save-purchase-order` Edge Function already provides the required authorized path; no new endpoint or broader RLS access was needed.

Verified current function contract:
- `GET_DATA` permits `purchases`, `finance`, and `finance_manager`.
- `items` is included in the explicit GET_DATA table allowlist.
- The route resolves the user's effective profile from the caller JWT before reading.
- The item query is performed by the existing server-side service-role client, explicitly constrained by the authenticated user's `company_id`.
- The current response limit is capped at 500 rows.

This route is the correct common access path for all user classes that the Buyer UI allows. It avoids weakening `items` RLS to make an invoice-editor widget work.

## 3. Surgical source correction

Only `companies/company-1/purchasing/buyer.html` was modified.

1. Replaced the direct authenticated `supabase.from('items')` paginated read in `loadInvoiceItems()` with a forced fresh call to the existing `this.data('items', true)` path. That method calls Buyer `GET_DATA`, then filters the returned central catalogue to active items.
2. Changed the invoice search helper to filter the already-loaded catalogue passed from the modal. This makes result selection immediate and avoids a separate direct RLS query on every keystroke.
3. Added Arabic-aware normalization using Unicode NFKC, tashkeel/tatweel removal, Alef normalization, and Arabic/Persian Yeh and Kaf normalization. This allows a query such as `ويفر` to match a stored product name containing Persian Yeh `ی`.
4. Preserved multi-token AND matching across `item_code`, `name`, `barcode`, and `search_label`, active-item filtering, the 220 ms debounce, stale-response guard, visible no-result/error feedback, manual purchase price entry, and existing invoice-line payload.
5. Updated the input handler to pass the catalogue loaded for the open invoice modal to `searchInvoiceItems(q, items)`.

No change was made to `main.html`, `core.js`, the Edge Function source/deployment, database schema, RLS, grants, RPCs, invoice write operations, stock, accounting, supplier balances, cash box, or treasury.

## 4. Verification

| Test | Result | Evidence |
|---|---|---|
| Production item dataset | PASS | 35 active items in company scope. |
| RLS permission mismatch | PASS / ROOT CAUSE REPRODUCED | Buyer identity sees 35; Finance and Finance Manager identities see 0 via direct RLS query. All checks were read-only and rolled back. |
| Current GET_DATA security contract | PASS (source inspection) | Explicit role check, allowlisted `items` table, company-scoped server-side read, limit 500. |
| Inline JavaScript parse | PASS | Buyer executable inline script compiles. |
| Forced gateway loader | PASS | Extracted production `loadInvoiceItems()` calls `this.data('items', true)`; no direct `items` SELECT remains in the invoice catalog path. |
| Partial Arabic letter | PASS | `ب` returns matching items in the method harness. |
| Partial Arabic word | PASS | `بسكوت` returns matching records. |
| Arabic/Persian character variant | PASS | User query `ويفر` matches stored `بسكوت ویفر 5ج`. |
| Item code / barcode | PASS | `1011` and `1224` return the matching item. |
| Multi-token search | PASS | `بسكوت 1011` returns the intended item. |
| Empty result | PASS | Non-matching `xyz` returns an empty result. |
| Finance invoice-modal event path | PASS (controlled harness) | Using a Finance-only user and a mocked authorized GET_DATA response, the real extracted Buyer methods loaded items, displayed a typed result, selected it, and added it to invoice lines. |
| Business side effects | PASS / NONE | Harness did not call invoice create/update. No production invoice, stock, supplier, payment, cash-box, journal, custody or treasury row was written. |
| Authenticated live Browser E2E | UNVERIFIED | No authenticated Buyer browser interaction surface was available. |

## 5. Cloudflare publication observation

Cloudflare Pages dashboard lists a new Production/main deployment entry for commit `1262c46`, automatic deployments enabled, preview URL:

`https://deb7f6ab.rawaea-erp.pages.dev`

The deployment record is present. The available dashboard text does not expose a terminal build-success state or deployed file-byte comparison, so served-artifact parity and authenticated live browser acceptance remain unverified.

## 6. Rollback and safety

Rollback is limited to reverting source commit `1262c4603cb84219549b877b79f40d2d409761ee`. No database cleanup is required. No RLS relaxation was performed; the repair uses the already permission-checked central GET_DATA route.

## 7. Remaining acceptance gate

Verify the current Cloudflare Production deployment reaches terminal Success and sign in using each relevant Buyer account class (purchases, finance, finance_manager, owner) to test partial Arabic, full Arabic, alternate Arabic characters, code, barcode, no-result, rapid typing, selection, line addition, and modal reopen. Then separately test an approved draft invoice create/update and Parent visibility without any premature stock or financial posting.

**Final status:** RLS/PERMISSION ROOT CAUSE CONFIRMED · CENTRAL AUTHORIZED READ PATH IMPLEMENTED · SOURCE COMMITTED · INLINE JS + CONTROLLED FINANCE MODAL EVENT-PATH TEST PASS · NO BUSINESS SIDE EFFECTS · CLOUDFLARE PRODUCTION ENTRY PRESENT · AUTHENTICATED LIVE E2E / SERVED BYTE PARITY UNVERIFIED.
