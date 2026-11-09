# Report670 — Buyer Financial Custody & Goods Custody Hardening
**Date:** 2026-11-09  
**Status:** Implemented in SMART ERP Production and committed to operational `main`; database/UI static and read-only runtime checks passed. Buyer browser E2E and latest Cloudflare runtime parity remain unverified.

## 1. Scope and verified baseline
This change is restricted to the Buyer financial custody and physical goods custody tabs and their existing database RPCs. It does not rebuild the purchase cycle, create a new Edge Function, modify the parent application, or change the driver/receiver/voucher applications.

- Operational repository: `papamohammed77-glitch/erp-frontend`
- Baseline operational source: `9490518bf7c1f3c12af9f187384af1573f55a437`
- Buyer file before patch: blob `0b4972979c60b638e51543bd202ea9102b3eedf8`
- Final Buyer file after patch: blob `94e2e95d13d2d1aa8687a8c0d394a8508176137e`
- Buyer UI commits: `f6b5f169f2fbd90bebaf4dc0b4961d8f3b167d47`, followed by `c5251859bd360fbf69f9875a8bb482bbd667fe4c`
- Automated Tailwind build commit after the first UI commit: `96ae1dbbea3ded0390859dfdf10196d225afbd9e`
- SMART ERP Production project: `fiilmooggumokxanwiyx`
- Applied migration: `20261109154258_buyer_custody_cash_claim_and_ownership_balances_20261109`

## 2. Database changes applied
### 2.1 Financial custody — preserve approved cash commitments
The live `buyer_custody_submit_quick_market_expense_atomic` function previously counted only `Submitted` expenses in its committed-cash calculation. The financial review RPC changes an approved QMP claim to `Approved` and increments the invoice's `paid_amount`; the remaining invoice reservation is reduced accordingly, but the cash actually used still has to remain in committed cash. The function now counts both `Submitted` and `Approved` expenses.

This aligns the backend calculation with the Buyer UI and prevents approved operational/QMP expenses from disappearing from available cash.

### 2.2 Invoice claims — permit distinct partial QMP receipt claims without duplicate posting
Replaced the invoice-only unique index `buyer_custody_expenses_invoice_uidx` with:
`buyer_custody_expenses_invoice_receipt_active_uidx(company_id, purchase_invoice_id, receiving_operation_id)`, scoped to `PURCHASE_INVOICE` rows in `Submitted` or `Approved` status.

Consequences:
- Separate completed QMP receipt operations for the same invoice can be submitted and settled independently.
- A repeated claim for the same invoice + receiving operation remains blocked.
- Rejected claims no longer permanently lock the invoice/receipt.
- PO invoices retain their one-active-claim rule: `buyer_custody_submit_expense_atomic` now locks the PO invoice `FOR UPDATE` and rejects another active invoice claim. Its operation-id duplicate check remains before this guard.

### 2.3 Goods custody — ownership/source-aware balance ledger
Replaced the body of `buyer_goods_custody_get_balances_atomic` while preserving its signature, SECURITY DEFINER posture, `search_path`, active-user check, effective permission gate, and self-versus-finance viewing scope.

Balances are now grouped by custodian, branch, item, ownership class, supplier, and originating document:
- `SUPPLIER_OWNED`: supplier-to-buyer Quick Market handover and its accepted delivery to warehouse.
- `COMPANY_OWNED_SUPPLIER_RETURN`: warehouse-to-buyer SupplierReturn, buyer-to-supplier acceptance, and buyer-to-warehouse return.
- `UNCLASSIFIED`: unknown/incomplete source classification, kept separate rather than merged into either ownership ledger.

Correction events inherit their ownership/source classification through `reverses_event_id`. The RPC now returns supplier identity, supplier name, source document type/id/code, supplier invoice number, evidence path, and movement history. SupplierReturn rows resolve through the original StockVoucher and its supplier; QMP rows resolve through PurchaseInvoice.

## 3. Buyer UI changes
Only `companies/company-1/purchasing/buyer.html` was changed.

- `عهدة بضاعتي` now displays independent sections for supplier-owned goods and company-owned SupplierReturn goods, with supplier, source document, supplier invoice number, branch, balance and last movement.
- Source invoice links open the relevant QMP invoice; evidence paths open through the existing signed-document viewer.
- Unclassified movements are displayed in a separate review section and are not merged into known ownership.
- The previous stale footer claiming that the acceptance path would be added later was removed. The new text explains the actual ledger boundary: a draft alone does not close custody; actual linked acceptance events do.
- The UI no longer sums quantities across unrelated units (for example cartons, pieces and kilograms). Summary cards count groups and associated suppliers instead.
- The custody expense receipt selector suppresses receipts already claimed in Submitted/Approved status. For QMP, only the same invoice + receipt is suppressed so a different partial receipt remains selectable; for PO, any active invoice claim suppresses another claim.
- Buyer custody Realtime relevance now includes `purchase_orders`, already present in the subscription set, so PO changes refresh the custody screen.

The pre-existing Quick Market handover action remains available from the invoice detail modal; no duplicate handover UI or parallel ledger was added.

## 4. QA / evidence
**CONFIRMED**
- Supabase migration applied successfully and appears as version `20261109154258`.
- New invoice/receipt partial unique index exists; old invoice-only unique index is absent.
- The three changed RPC signatures remain SECURITY DEFINER, owned by postgres, executable by `authenticated`, and not executable by `anon`.
- A read-only invocation of `buyer_goods_custody_get_balances_atomic` under the active Buyer identity (`buyer1@rawaea.com`) returned `success=true`, `can_view_all=false`, the Buyer's own custodian ID, and empty balances/events as expected. The call was wrapped in a transaction and rolled back; no data was written.
- Live production still contains one operational expense: Submitted, EGP 200, with no invoice link; there are zero invoice-linked custody expense claims and zero goods custody events. Thus an empty goods balance is the expected live data state, not evidence of a broken ledger.
- Static JavaScript parsing passed for `renderVehicleBalance`, `submitCustodyExpense`, `renderCustody`, and the complete inline Buyer script.
- GitHub shows the UI commit and subsequent automated Tailwind CSS build commit. The latest Buyer file SHA was re-fetched after the second UI commit.

**NOT VERIFIED**
- No production invoice, receiving, custody, supplier ledger, inventory, cash or journal test rows were created. The actual submission/review/receipt E2E was not run because there are no live invoice-linked receipt claims or handover/return rows to exercise, and production test data was not seeded.
- The live Buyer page was not opened in an authenticated browser after the commit. The current Cloudflare runtime deployment corresponding to `c5251859bd360fbf69f9875a8bb482bbd667fe4c` was not verified; do not claim it is deployed.
- Staging remains schema/security out of parity and was not used.

## 5. SupplierReturn acceptance gap intentionally left open
The SupplierReturn flow is **not** reported as complete for partial acceptance. The current `complete_manual_stock_voucher_atomic_core_20260828` posts the supplier ledger, tax and journal from the full `stock_voucher_details` totals; the current custody trigger rejects any `received_qty` different from the issued `qty`; and `complete-stock-voucher` v4 accepts only a voucher code, with no accepted-quantity payload, proof attachment or Buyer exception note.

Changing only the trigger or the custody event would make the custody ledger disagree with stock and supplier accounting. Therefore the partial-acceptance path was not altered. The remaining end-to-end change must atomically:
1. capture accepted quantities per line, supplier proof and the responsible receiving actor;
2. post supplier ledger, inventory credit, tax reversal and journal only for accepted quantities;
3. keep rejected quantities in the Buyer's company-owned return custody;
4. require a separate physical warehouse-return document/event for rejected quantities;
5. allow a Buyer-as-supplier-representative exception only when the assigned receiver submits a mandatory note and evidence;
6. enforce the applicable role/branch authorization server-side, not only by hiding UI buttons.

A follow-up production migration `20261109155413_buyer_supplier_return_send_complete_role_scope_guards_20261109` has now added server-side guards to the existing SupplierReturn send and complete RPC wrappers. Both require the same warehouse-management gate already used by the SupplierReturn contract endpoints (owner wildcard, active warehouse role `أذونات`, or role مدير عام / مدير مخازن / مشرف مخازن); completion also validates the source branch context and branch scope. Both wrappers remain service-role-only (`anon EXECUTE=false`, `authenticated EXECUTE=false`), so the existing authenticated Edge endpoints remain the entry point. A read-only role matrix confirmed the warehouse supervisor passes while the buyer and accountant do not. Do not infer security from UI action visibility alone; the wrapper checks are now the server-side control.

## 6. External ERP control comparison
The implemented separation follows established ERP control patterns:
- ERPNext distinguishes Purchase Order (commitment), Purchase Receipt (actual received/accepted quantity and stock event), Purchase Invoice (supplier payable), and Payment Entry. It supports multiple partial receipts and keeps rejected goods in a returns warehouse: https://docs.frappe.io/erpnext/purchase-receipt and https://docs.frappe.io/erpnext/purchase-return
- Microsoft Dynamics 365 consignment explicitly separates vendor-owned physical on-hand stock from company-owned stock, and records ownership change as a separate posted journal: https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/consignment
- These references support retaining independent event ledgers for money, physical custody and accounting ownership rather than treating a purchase draft or possession event as a financial posting.

## 7. Change boundaries
No other application file, Edge Function source, or live operational row was changed. No new Edge Function was deployed. The SQL changes are contained in one versioned migration; the UI changes are contained in Buyer HTML only. Existing SupplierReturn financial completion remains unchanged until an end-to-end accepted/rejected quantity design is implemented and tested.


## 8. SupplierReturn authorization follow-up (LVE671)
- Applied migration `20261109155413_buyer_supplier_return_send_complete_role_scope_guards_20261109`.
- `send_stock_voucher_atomic`: SupplierReturn send now requires owner wildcard, active warehouse role `أذونات`, or one of the established manager roles. Existing branch-scope logic remains intact.
- `complete_manual_stock_voucher_atomic`: SupplierReturn completion now applies the same role gate and validates an active source branch plus allowed-branch scope before calling the unchanged full-posting core. Other voucher types continue through the unchanged core without the new SupplierReturn branch.
- The wrappers are service-role-only; verified `anon EXECUTE=false` and `authenticated EXECUTE=false`. Edge v20/v4 remain the authenticated entry points; no Edge source or new function was added.
- Read-only role matrix: `warehouse.supervisor@rawaea.com` / مشرف مخازن passes; `buyer1@rawaea.com` / مسئول مشتريات and `accountant@rawaea.com` / محاسب do not pass this SupplierReturn role gate. No posting or voucher status change was attempted.
- The Buyer-as-supplier-representative exception remains unavailable because the current complete Edge contract does not accept a proof file and mandatory exception note. SupplierReturn partial quantity acceptance remains open for the atomic cross-ledger implementation in section 5.
