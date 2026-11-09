# RAWAEA ERP — CURRENT STATE

**Last Verified Event:** LVE-2026-11-09-674  
**Last verified:** 2026-11-09 (Africa/Cairo)  
**Status:** Buyer Quick Market goods-custody and direct supplier-return forensic review completed. No operational source, Production SQL, Edge Function, or business data was changed. The exact Owner ChangeSet remains pending because the governing approval gate requires review of the concrete patch before implementation.

## Current verified production baseline

- Operational repository: `papamohammed77-glitch/erp-frontend`, branch `main`.
- Operational HEAD observed: `da37cbd27c0fd363bff95008919baee79622b654`.
- Buyer file: `companies/company-1/purchasing/buyer.html`.
- Buyer blob SHA: `072710c9db0184b0744eebd027fcdd3daf297269`.
- Cloudflare Pages `rawaea-erp`: Production / `main` deployment points to `da37cbd`, deployment ID `4036153b-5400-476e-a35a-74c2a7231480`. This confirms deployment pointer only; authenticated Buyer runtime E2E remains unverified.
- Supabase active Edge Functions: `save-purchase-order` v39; `receive-purchase` v15.
- Production database was queried read-only; no business rows were written.

## Buyer goods-custody findings

- Quick Market invoices PINV-1002 and PINV-1003 are Draft / EMPLOYEE_CUSTODY / EGP, with 20 and 9 total units respectively and zero warehouse-received units.
- Neither invoice has a linked `purchase_attachments` record or matching storage evidence object.
- `buyer_goods_custody_events` contains zero events for the current snapshot. Therefore confirmed goods custody is zero; the UI balance RPC is event-based, not invoice-header-based.
- The Buyer already has a separate `recordQuickMarketHandover` action that requires explicit physical handover confirmation and supplier evidence. Invoice creation alone does not create custody.
- Buyer `فواتيري` has no direct supplier-return modal/action.
- Parent `CREATE_RETURN/POST_RETURN` is limited to posted/part-paid/paid invoices and received quantities, and its posting path has branch-stock and financial effects. It is not valid for goods still in buyer custody.
- Warehouse `SupplierReturn` is a branch-stock return flow, not a direct return of supplier-owned Quick Market goods held by a buyer.

## Required next implementation

See `doc/Draft/Reprots/Report674_BUYER_GOODS_CUSTODY_QUICK_MARKET_RETURN_FORENSIC_20261109.md` for the complete evidence and proposed scope.

1. Keep confirmed custody event-based. Make unconfirmed Quick Market invoice quantities visible separately as **awaiting physical handover confirmation**; do not add them to confirmed balance without acknowledgement/evidence.
2. Promote the existing supplier-handover action to a clear first-class action.
3. Add a Buyer-only direct supplier-return modal for positive net Quick Market custody. Require accepted supplier evidence, reason, line quantities, and idempotency.
4. Record direct return as a negative `BUYER_TO_SUPPLIER_ACCEPTED` event sourced from `PurchaseInvoice`, with source line and supplier destination.
5. Make `buyer_goods_custody_get_balances_atomic` classify by source document type; update `get_quick_market_receiving_queue_atomic` and `receive_quick_market_purchase_atomic` to subtract supplier-returned quantities.
6. Add one operation branch to existing `save-purchase-order`; do not create a new Edge Function or reuse Parent `POST_RETURN` / warehouse `SupplierReturn` for this flow.
7. Keep the physical return separate from stock, Treasury, cash custody, supplier AP/ledger, and GL. Refunds and credit notes require their own authorized financial documents.

## Verification and safety status

- Read-only source/schema/data inspection completed.
- No application patch, SQL migration, Edge deployment, custody event, supplier return, stock receipt, journal, or cash movement was performed.
- No authenticated Buyer E2E was run; the available browser session exposed the Parent app and only read-only tab inspection.
- Do not describe this Buyer issue as fixed.
- Do not backfill PINV-1002 or PINV-1003 into goods custody without the buyer's actual physical handover evidence.
- The exact source/SQL ChangeSet must be prepared and explicitly approved under the governing operating instructions before any operational write.

## Previous checkpoint

LVE-2026-11-09-673 — Buyer cash-custody UX reorganization. The cash-custody UI changes are separate from the current goods-custody issue; the prior financial RPC contracts were preserved.
