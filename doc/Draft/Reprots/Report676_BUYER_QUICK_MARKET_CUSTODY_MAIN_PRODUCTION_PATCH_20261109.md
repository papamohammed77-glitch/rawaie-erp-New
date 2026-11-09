# Report 676 — Buyer Quick Market Custody & Supplier Return — Main/Production Patch

**Date:** 2026-11-09  
**Workstream:** RAWAEA ERP / Buyer / Quick Market goods custody  
**Checkpoint:** LVE-2026-11-09-676  
**Operational repository:** `papamohammed77-glitch/erp-frontend`  
**Governance repository:** `papamohammed77-glitch/rawaie-erp-New`  
**Supabase project:** SMART ERP — `fiilmooggumokxanwiyx`

## 1. Executive result

A surgical source patch was committed directly to `main` and the existing `save-purchase-order` Edge Function was deployed as version **40 (ACTIVE)**. The deployed Edge Function source was fetched again and compared byte-for-byte with the `main` source; they match.

The production database already contains migration `20261109190444 buyer_quick_market_invoice_derived_custody_and_supplier_return`, including the invoice-derived custody projection, supplier-return custody RPC, and receiving queue/receipt deductions. No new database migration or data mutation was performed in this checkpoint.

**This is not a fully E2E-verified release.** The Buyer page could not be exercised in an authenticated browser session; the connected ERP tab showed the login form. The database RPC rejects direct SQL-editor invocation without a valid authenticated user context (`BUYER_GOODS_AUTH_REQUIRED`). Cloudflare deployment of the new `main` commit was not independently verified. Do not represent the work as complete E2E acceptance until these gates pass.

## 2. Main repository writes

### Buyer page

File: `companies/company-1/purchasing/buyer.html`

- Commit: `36431ef45a175c989315d6fa7322dd4a85e64f4f`
- Blob after this write: `266a33b6104a1e7497529f525059dad53ae38c7e`

Surgical changes:
1. Replaced only the Quick Market invoice detail panel with the tested PR #11 presentation, displaying per-line invoice quantity, supplier handover, warehouse accepted quantity, supplier-returned quantity, and current buyer custody.
2. Disabled editing Quick Market invoice lines from the generic invoice editor; the invoice is the custody source and must not be edited through the generic path after it becomes a custody source.
3. Added the supplier-return action only when the current invoice belongs to the buyer, is in an eligible `Draft`/`PartiallyPaid` state, is not received, and has positive `current_custody_qty`.
4. Added the existing tested `recordQuickMarketSupplierReturn` modal/action implementation from PR #11.
5. Corrected the stale goods-custody empty-state and explanatory copy so it no longer claims that a separate handover event is required for initial Quick Market invoice custody.

No edits were made to `delivery/driver.html`; it remains a read-only semantic/UX reference.

### Existing Edge Function

File: `supabase/functions/save-purchase-order/index.ts`

- Commit: `85a1773430a6d76799cd31e85b1a03f79f132369`
- Blob after this write: `2f47c692c53f596e5abe35770a5e05659dcf2383`

Surgical changes:
1. Added the `REGISTER_QUICK_MARKET_SUPPLIER_RETURN` permission gate requiring effective `purchases` permission.
2. Added the dispatch operation that validates buyer ownership, invoice source, evidence path, stored evidence MIME/size, and operation ID, then calls the existing atomic custody RPC.
3. Corrected the RPC identifier to the exact deployed PostgreSQL identifier:
   `buyer_goods_custody_register_quick_market_supplier_return_atomi`.
   PostgreSQL stores identifiers at a 63-byte limit; the longer source spelling is truncated in the live catalog. Calling the long spelling from PostgREST would fail to resolve the actual production function.

No new Edge Function was created.

## 3. Production Supabase evidence

### Migration history

The production migration history contains:
- `20261109190444 buyer_quick_market_invoice_derived_custody_and_supplier_return`
- `20261109155413 buyer_supplier_return_send_complete_role_scope_guards_20261109`
- `20261109154258 buyer_custody_cash_claim_and_ownership_balances_20261109`

The live schema exposes:
- `buyer_goods_custody_get_balances_atomic(uuid,uuid)`
- `buyer_goods_custody_get_invoice_handover_progress_atomic(uuid,uuid)`
- `buyer_goods_custody_register_quick_market_supplier_return_atomi(uuid,uuid,jsonb,text,text,text)`
- `get_quick_market_receiving_queue_atomic(...)`
- `receive_quick_market_purchase_atomic(...)`

### Read-only invoice evidence

The live SMART ERP invoice rows still show:

| Invoice | Line items | Total units | Received | Custody events |
|---|---:|---:|---:|---:|
| PINV-1002 | 3 | 20 | 0 | 0 |
| PINV-1003 | 2 | 9 | 0 | 0 |
| **Total** | **5** | **29** | **0** | **0** |

The 29 units are derived from the invoice detail rows:
- PINV-1002: 5 packs of date biscuits + 10 guava juice shrink packs + 5 mango juice shrink packs.
- PINV-1003: 5 packs of date biscuits + 4 cartons of chips.

No custody event, warehouse receipt, supplier return, stock movement, payment, Treasury movement, journal or GL record was inserted or backfilled during this task.

The production balance RPC definition now creates an invoice-derived custody projection for Quick Market lines, and a receipt projection that deducts accepted warehouse quantities without double-counting actual custody events. The invoice progress RPC separately computes:
- `handed_over_qty = invoice line qty` for the invoice-established custody model;
- warehouse accepted quantity from invoice received quantities / accepted warehouse events;
- supplier-returned quantity from accepted `BUYER_TO_SUPPLIER_ACCEPTED` events;
- `current_custody_qty = max(invoice qty - warehouse accepted qty - supplier returned qty, 0)`.

The receiving queue and atomic receipt function both subtract accepted supplier-return quantities from the amount available for warehouse receipt. These definitions were inspected directly in Production.

**Important access limitation:** invoking the balance RPC from the SQL editor failed with `BUYER_GOODS_AUTH_REQUIRED`, as expected from its `auth.uid()` and effective-permission guard. No attempt was made to bypass this guard or impersonate a user. The 29-unit amount above is a read-only calculation from invoice lines, not a successful authenticated RPC response.

## 4. Edge deployment verification

- Supabase function: `save-purchase-order`
- Deployed version: **40**
- Status: **ACTIVE**
- `verify_jwt`: true
- Deployed source SHA-256: `0b34ff18019def1b87f5ab5b2520aef2b96a6d57d5e0c0691d8a88183a05ea53`
- Re-fetched deployed `index.ts` matched the `main` source exactly.

No database migration was run in this checkpoint.

## 5. Safety and accounting boundaries preserved

- Cash custody (`عهدتي`) remains distinct from physical goods custody (`عهدة بضاعتي`).
- Quick Market invoice custody does not itself add branch inventory.
- Warehouse receipt is the only path that moves accepted quantities into branch stock.
- Supplier return reduces the buyer's goods custody only after the supplier-accepted return event is recorded.
- Supplier return does not post branch stock, supplier AP/ledger, cash, Treasury or GL.
- The RPC uses an operation ID and payload fingerprint for idempotency and verifies the same operation/evidence after uncertain transport.
- Supplier-owned `PurchaseInvoice` returns remain distinct from company-owned `StockVoucher` supplier returns.
- No test invoices, return events, stock receipts, payment records or financial entries were created.

## 6. Verification matrix

| Gate | Result | Evidence / limitation |
|---|---|---|
| Task file full read | PASS | `writing-block-8888-10.md`, 1,035 lines / 27,617 chars, read in consecutive chunks |
| Current state / reports / PR history | PASS | Compared current state, Reports 674/675, PR #11, commits and branch state |
| Production schema/functions | PASS (read-only) | Live catalog definitions inspected for balance, progress, return, receiving queue and atomic receiving |
| Invoice quantity audit | PASS (read-only) | PINV-1002 + PINV-1003 = 29 units; received 0; event count 0 |
| Buyer source write | PASS | Commit `36431ef` on `main` |
| Edge source write | PASS | Commit `85a1773` on `main` |
| Supabase Edge deployment | PASS | Version 40 ACTIVE; deployed source byte-equal to main source |
| SQL migration | NOT RUN | Existing Production migration already present; no new DDL needed |
| Live balance RPC as authenticated Buyer | BLOCKED | Available browser tab was unauthenticated; SQL editor invocation correctly rejected missing auth |
| Browser authenticated Buyer E2E | NOT RUN | Browser tab displayed the login form; Chat-mode browser tools are read-only |
| Cloudflare `main` deployment | NOT VERIFIED | Prior PR preview evidence is not proof for these newer main commits |
| Full automated CI / Node scenarios on these exact main commits | NOT RUN | No workflow-dispatch capability exposed; prior PR CI is not evidence for the new main commits |

## 7. Required final acceptance steps

1. Open an authenticated Buyer session and verify `PINV-1002` and `PINV-1003` show the invoice-derived line quantities in `عهدة بضاعتي` and in invoice details.
2. Verify the goods tab total equals 29 units before any receipt/return, grouped by item/unit/branch and linked to the two source invoices.
3. In a controlled business-approved scenario, verify a partial supplier-accepted return reduces only the selected invoice-line custody; verify duplicate operation retry is idempotent; verify over-return is rejected.
4. Verify Receiver queue quantity is reduced by supplier-accepted returns, and warehouse receipt reduces buyer custody exactly once while increasing branch stock only through the existing receipt workflow.
5. Verify no supplier AP, Treasury, cash custody, journal or GL movement is created by the physical return event.
6. Verify Cloudflare deployment for the current `main` commit and run the Buyer modal/inline-JS, Edge TypeScript and Tailwind tests against the exact main revision.

**Release status:** source patch committed and Edge Function deployed; functional E2E and Cloudflare main deployment remain unverified. Keep the issue open until steps 1–6 pass.

## 8. Next assistant handoff

Resume from LVE-2026-11-09-676. Do not reapply the Buyer or Edge patch. First read the current `main` blobs and live Edge version 40; then use an authenticated Buyer session for E2E. Do not create test operational records in Production. Any test of an actual supplier return or warehouse receipt must use a reversible, explicitly approved test document path and be cleaned up only if the full reversal is guaranteed.
