# Report404 — POS Returns: Current Production Reconciliation and Surgical Decision
**Date:** 2026-10-10  
**Scope:** POS return tab, invoice lookup, return posting and integration.  
**Production project:** `fiilmooggumokxanwiyx`  
**Frontend repository:** `papamohammed77-glitch/erp-frontend`  
**State repository:** `papamohammed77-glitch/rawaie-erp-New`

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** POS return must retrieve the original invoice, allow item-level or full returns, prevent quantities exceeding the sold/remaining quantity, restore eligible goods to stock through the central stock movement contract, create auditable return documents, and correctly refund the original payment source. A credit note is not a cash refund.
- **Architecture Understanding:** POS UI → authenticated `get_pos_invoice_data` RPC → existing `complete-return` Edge Function v26 → `complete_sales_return_credit_note_atomic` → `complete_return_atomic` → `post_stock_movement` for eligible stock returns. No new Edge Function is required or created.
- **Database Understanding:** Live schema has `orders`, `order_details`, `cash_box`, `treasury`, `credit_notes`, `journal_entries`, `customer_ledger`, and `erp_operation_registry`. The inspected schema does not establish a cashier shift/drawer entity.
- **Historical Understanding:** Report403 and CURRENT_STATE were read as navigation aids; the source and live database were checked again directly in this cycle. Historical POS code used the chosen payment method only for UI messaging; it did not send payment method, refund amount, or cashier drawer to the server.
- **Production Understanding:** Live Edge `complete-return` is v26, `verify_jwt=true`, and calls `complete_sales_return_credit_note_atomic`. Live SQL definitions and ACLs were queried again. No business rows were mutated.
- **Current Understanding:** Current frontend commit is `950abb6b78680d37c8d29f1beba78c8c1d6a51a4` (2026-10-10T17:33:22Z), current `pos.html` blob is `967d486147cf3ca9911c4dbd3ba89042c373577e`, 1,522 lines / 88,823 characters.
- **Execution Confidence:** High for current Git and inspected DB/Core facts. Not sufficient for claiming hosted UI parity, browser HTTP E2E, or a correctly reconciled cash refund.

### Required source checks

| Check | Result |
|---|---|
| Current frontend source | Read current `pos.html` and exact relevant function contexts |
| Latest commits | Confirmed latest two POS-related commits and parent progression |
| Live Edge | `complete-return` v26, JWT verification enabled |
| Live Core | Read current definitions of `complete_return_atomic` and `complete_sales_return_credit_note_atomic` |
| RPC ACL | `get_pos_invoice_data` is SECURITY DEFINER with empty search_path; anon denied, authenticated allowed, service_role allowed |
| Schema/triggers | Inspected relevant tables, constraints and triggers |
| Current POS sample rows | Read-only inspection of ORD-1004 / ORD-1005 and corresponding cash_box receipts |
| HTTP/browser E2E | Not performed in this cycle; no browser session evidence available |
| Hosted asset parity | Unverified |
| Production data changes | None |

## 1. Current source — do not repeat an obsolete patch

Latest frontend commit:
- `950abb6b78680d37c8d29f1beba78c8c1d6a51a4` — `Refactor switchView to use allowedViews array`.
- Parent relevant commit: `3b27e45adbdfcea4a08f414b2dc5a9082f1be422` — `Refactor return invoice search and data retrieval`.
- Current blob: `967d486147cf3ca9911c4dbd3ba89042c373577e`.

The current source already has:
- `self.renderReturnsView` (around line 823)
- `self._getPosInvoiceData` (around line 837)
- `self._searchReturnInvoice` (around line 858)
- `self.switchView` using `allowedViews = ['pos', 'suspended', 'invoices', 'returns']` (around line 1076)

The return search calls `get_pos_invoice_data` with action `return_lookup`; the “invoice not found in authorized POS branches” toast occurs only when the RPC returns a payload with no `order`. The latest source already contains the intended RPC path and view-navigation update. **No new surgical replacement in `pos.html` is justified by the source evidence.** Do not paste an older `_searchReturnInvoice` or `switchView` implementation over the current one.

## 2. Fresh Production evidence

### Live edge
- `complete-return`: version 26, `verify_jwt=true`.
- It authenticates the bearer token using `supabase.auth.getUser`, resolves `public.users` through `auth_id = user.id`, then calls `complete_sales_return_credit_note_atomic`.
- It does not accept or forward `refund_method`, `refund_amount`, `treasury_id`, or a cashier-shift/drawer identity.

### Live Core
`complete_sales_return_credit_note_atomic(uuid,text,text,boolean,text,jsonb,text)` creates a credit note after calling `complete_return_atomic`.

The live `complete_return_atomic(uuid,text,text,boolean,text,jsonb)`:
- uses an operation registry/fingerprint;
- locks the order/detail rows and caps the returned quantity at the remaining quantity;
- sends eligible good-condition returned stock through `post_stock_movement`;
- posts an inventory/COGS journal entry;
- then raises `RETURN_CUSTOMER_REQUIRED_FOR_FINANCIAL_POSTING` if a positive-value order return has `customer_id IS NULL`;
- does not issue a cash payment or card refund.

This is a **confirmed Core defect for cash POS orders**, not merely a UI issue. Simply deleting or skipping the customer requirement would make the request pass farther but would not implement the required cash refund or balanced revenue/cash accounting; that would be an unsafe half-fix.

### Live sample evidence
Read-only production rows show:
- `ORD-1004`: POS, Invoiced, 275.00, `customer_id=NULL`, created by `cashier@rawaea.com`; matching `cash_box` Receipt for 275.00 points to the main treasury.
- `ORD-1005`: POS, Invoiced, 185.00, `customer_id=NULL`; matching `cash_box` Receipt for 185.00 points to the same main treasury.
- Both `orders` and the matching `cash_box` rows use company ID `00000000-0000-0000-0000-000000000001`.
- The verified schema has `cash_box` and `treasury`, but the inspected tables do not prove a per-cashier shift/drawer model. The receipts identify the cashier by `user_email`, but are posted to the same treasury.
- Do not delete or mutate these production invoices; they are linked to financial records.

### RPC security
The live `get_pos_invoice_data(text,text)` function is SECURITY DEFINER with an empty search_path; `anon EXECUTE=false`, `authenticated EXECUTE=true`, `service_role EXECUTE=true`. The lookup logic is branch-scoped through `get_pos_branches()`. Prior DB claim simulation retrieved ORD-1004/ORD-1005, but that remains DB simulation, not browser HTTP E2E.

## 3. Root cause and surgical decision

There are two distinct issues and they must not be conflated:

1. **Tab/lookup symptom:** current Git already contains the latest view-switch and RPC lookup changes, and DB-level lookup was previously shown to find the sample invoices for the authorized cashier. The served website asset and actual browser request have not been proven to match current Git. Therefore the next safe action is publish the current commit via the approved frontend hosting pipeline, invalidate the service-worker/cache, then capture the authenticated browser request/response. Do not rewrite source that is already correct.
2. **Financial return defect:** live Core rejects POS returns when `customer_id=NULL`, and no server-side cash/card refund contract exists. This cannot be safely repaired by removing one exception. A complete repair must atomically coordinate: returned quantity and stock movement; credit-note idempotency; refund-method/payment-origin resolution; authorization of the refund source; cash payment or external card-refund record; balanced revenue/refund journal entries; operation registry; and audit records.

**No Production SQL was changed in this cycle.** This is deliberate: the current schema/evidence does not prove a per-cashier drawer/shift contract or a card processor/refund integration. Posting an arbitrary `cash_box` Payment or merely bypassing `customer_id` could misstate cash balances and accounting. The exact missing prerequisite is not user-supplied source code; it is the business contract that determines whether refunds debit the shared treasury or an authenticated cashier-specific drawer, and how card refunds are executed. The live sample currently points to a shared treasury.

## 4. Exact action for the owner — frontend

No replacement block is warranted in the current `pos.html` based on source review.

Publish commit:
`950abb6b78680d37c8d29f1beba78c8c1d6a51a4`

Then:
1. Clear/invalidate the site's Service Worker cache and reload POS.
2. Sign in as an authorized cashier.
3. Capture the actual Network request to `rpc/get_pos_invoice_data` for `return_lookup` and its JSON response.
4. Verify `payload.order` is present for a known permitted POS invoice.
5. Verify the return view is entered and the current UI asset matches the Git blob.
6. Do not run a return against ORD-1004/ORD-1005 as a test; use a dedicated isolated fixture after the refund contract is implemented.

`main.html` and `companies/company-1/sales/pos.html` were not edited.

## 5. Closure state

- `CURRENT_SOURCE_LOOKUP_PATH: PRESENT`
- `CURRENT_SOURCE_VIEW_NAVIGATION: PRESENT`
- `PRODUCTION_LOOKUP_RPC_AND_ACL: VERIFIED`
- `DB_CLAIM_SIMULATION: VERIFIED IN PRIOR CHECKPOINT; NOT HTTP E2E`
- `PRODUCTION_EDGE_COMPLETE_RETURN: v26 VERIFIED`
- `CORE_CASH_POS_RETURN_CUSTOMER_ID_DEFECT: CONFIRMED`
- `CASH_REFUND / CASHIER_DRAWER_CONTRACT: NOT IMPLEMENTED / NOT PROVEN`
- `LIVE_BROWSER_HTTP_E2E: UNVERIFIED`
- `HOSTED_ARTIFACT_PARITY: UNVERIFIED`
- `POS_RETURN_CLOSURE: OPEN`

## SELF-AUDIT FINAL

- **What I Proved:** latest frontend commit/blob and relevant functions; live Edge version/JWT; live Core exception for cash POS returns; production invoice/cash receipt linkage; RPC ACL; absence of a verified per-cashier drawer entity in the inspected schema.
- **What I Did Not Prove:** current hosted HTML/SW parity, live browser HTTP behavior, successful end-to-end cash refund, or a card processor refund path.
- **What I Fixed:** no source or Production data was changed; I avoided overwriting current fixes and avoided an unsafe partial accounting bypass.
- **What I Initially Missed:** lookup/navigation and financial refund are separate defects; a lookup fix does not make the return transaction valid.
- **What Could Still Be Wrong:** deployed frontend may be stale; actual browser request may carry a different code or scope; existing account mappings/payment methods may have additional conventions not proven by the current sample.
- **Final Confidence:** high for source/Core/schema evidence; not sufficient for closure.
- **Final Closure Status:** `NOT CLOSED — CURRENT SOURCE PATCH PRESENT; LIVE UI PARITY AND SAFE FINANCIAL REFUND CONTRACT REMAIN OPEN`.
