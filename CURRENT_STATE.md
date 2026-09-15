# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-15 20:30 UTC

## SOURCE OF TRUTH

التقارير Historical/Reference فقط، ولا تُعامل كحالة حالية.

الحقيقة المعتمدة:
`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

ولإغلاق Browser/System E2E يلزم أيضًا:
`CURRENT BROWSER + CURRENT CONSOLE + CURRENT NETWORK`

**Source of Truth للنظام الأم:**
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

Historical fragments only:
`Current/PWA/main2/*`, `Original/PWA/main/*`, `New-main`.

## CURRENT FRONTEND GIT

Repository: `papamohammed77-glitch/erp-frontend`
Branch: `main`
Current HEAD:
`befa657277fc013c4fe4d3e326ed8fc5d1040b7b`

HEAD message:
`Update HTML comment timestamp`

Direct parent:
`b6d35c5a1a362f381c9868bbc578de988b219c50`

Parent message:
`Fix button onclick syntax in main.html`

Current mother blob:
`bc268b9bb350991df64221e7f99b958264fb8d5f`

HEAD changes the first HTML timestamp only. The direct parent contains the previous Purchase button syntax repair near line 9577.

## CURRENT MOTHER FILE / EOF

Current Mother is the sole execution source.

The current large blob was re-read through the GitHub resource and source-line ranges were used for the Purchase block. The connector does not reliably expose the entire huge file as a single line-mapped payload in every range call, but the current content itself was inspected and the Purchase anchors below were taken from that CURRENT source resource.

Previously proven EOF remains:

```html
</script>
</body>
</html>
```

## CURRENT FORENSIC PURCHASE SOURCE

Current Purchase source sequence confirmed:

- `createRequest()` begins at source line **9278**.
- Its malformed line separator is the two-line sequence at **9292–9293**.
- The approval button is inside `requests(host)` immediately before the function at 9320+ and must keep the corrected `type="button"` form.
- `createRFQ()` begins at source line **9373**.
- `createQuotation()` begins at approximately **9465** in the same CURRENT source sequence.
- Current purchase modal functions are later in the same `RW_PurchaseGold` block through `createInvoice`, `createReturn`, `createPayment`, `reports`, and `settings`.

The exact owner patch is recorded in:
`doc/Draft/Reprots/Report201_PURCHASE_MODAL_SURGICAL_CLOSURE_20260915.md`

## FORENSIC ASSEMBLY

`forensic_main_assembly.yml` remains correct:

```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
assembly_status:
  mode: published_main_is_authoritative
  fragment_mode: historical_reference_only
```

No path correction was necessary.

## CURRENT PRODUCTION PURCHASE INFRASTRUCTURE

Production contains the complete purchase table family:

`purchase_requests`
`purchase_request_details`
`purchase_rfqs`
`purchase_rfq_details`
`purchase_rfq_suppliers`
`purchase_quotations`
`purchase_quotation_details`
`purchase_quotation_comparison`
`purchase_orders`
`purchase_order_details`
`purchase_invoices`
`purchase_invoice_details`
`purchase_returns`
`purchase_return_details`
`purchase_payments`
`purchase_payment_allocations`
`purchase_attachments`
`purchase_document_links`
`purchase_status_history`
`purchase_supplier_balance`
`purchase_invoice_aging`
`purchase_settings`

Current Production row counts at reconciliation remain effectively empty for the transactional purchase family, so no fake E2E dataset has been treated as real purchase history.

## VERIFIED PURCHASE RPC CONTRACT

Current Production has these purchase RPCs:

`purchase_create_request_atomic`
`purchase_submit_request_atomic`
`purchase_approve_request_atomic`
`purchase_reject_request_atomic`
`purchase_create_rfq_atomic`
`purchase_send_rfq_atomic`
`purchase_create_quotation_atomic`
`purchase_accept_quotation_atomic`
`purchase_convert_quotation_to_po_atomic`
`purchase_create_invoice_atomic`
`purchase_post_invoice_atomic`
`purchase_create_return_atomic`
`purchase_post_return_atomic`
`purchase_post_payment_atomic`
`purchase_cancel_document_atomic`
`purchase_get_dashboard`
`purchase_get_reports`
`purchase_set_settings_atomic`
`purchase_next_code`
`receive_purchase_atomic`
`save_purchase_order_atomic`

The principal purchase write RPCs are executable by `service_role` and the Mother runtime reaches them through the authenticated `save-purchase-order` Edge function.

## SESSION 2026-09-15 — REPORT201

### Production changes executed

1. `purchase_set_settings_atomic(company_id, actor, settings)` was created and deployed.
2. `purchase_get_reports(company_id, as_of_date)` was created and deployed.
3. `save-purchase-order` Edge Function was redeployed as **version 6** with JWT required.
4. Version 6 routes Settings and Reports to the new authoritative RPCs rather than direct table mutation/calculation.
5. Version 6 preserves authenticated-user Company context and the existing purchase operations.

### Functional design decision

No duplicate purchase tables were created. The existing 22-table purchase model already covers the lifecycle.

No Inventory writer or Order/Runsheet engine was changed during this UI closure unit.

## CURRENT E2E STATUS

```text
Current Git/Parent                 = VERIFIED
Current Mother blob               = VERIFIED
Current Mother source anchors     = VERIFIED
Assembly Source of Truth          = VERIFIED
Production purchase schema        = VERIFIED
Purchase RPC foundation           = VERIFIED
Purchase settings RPC             = DEPLOYED
Purchase reports RPC              = DEPLOYED
save-purchase-order Edge v6       = DEPLOYED
Mother parser blocker             = OWNER PATCH REQUIRED
Professional modal UI             = OWNER PATCH REQUIRED
Fresh Browser Console             = NOT YET PROVEN CLEAN
Fresh Browser Network             = NOT YET PROVEN
Purchase functional E2E           = OPEN
Gold/Diamond Purchase closure     = OPEN until owner merge + fresh E2E
Overall task                      = OPEN
```

## OWNER SURGICAL ACTION — MOTHER FILE

The assistant must not modify Mother directly.

### 1. Parser blocker

Current source line **9292–9293** inside `RW_PurchaseGold.createRequest()` is malformed:

```javascript
        raw.split('\
').forEach(function (line) {
```

Delete these two complete physical lines and insert exactly:

```javascript
        raw.split('\n').forEach(function (line) {
```

### 2. Purchase approval action string

Inside `requests(host)` keep this exact corrected button line:

```javascript
          ? '<button type="button" onclick="RW_PurchaseGold.approveRequest(\'' + esc(x.id) + '\')" class="px-3 py-1 rounded-lg bg-blue-600 text-white">اعتماد</button>'
```

### 3. Remaining action-string blockers

Inside the CURRENT Mother source, correct the onclick escape in:

`sendRFQ`
`acceptQuotation`
`convertQuotation`
`postInvoice`
`postReturn`

The required final form is:

```javascript
onclick="RW_PurchaseGold.<FUNCTION>(\'' + esc(x.id) + '\')"
```

Do not change surrounding business logic.

### 4. Modal UI upgrade

After parser clean, replace the existing shallow modal bodies in:

`createRequest`
`createRFQ`
`createQuotation`
`createInvoice`
`createReturn`
`createPayment`

and upgrade the `reports` / `settings` views using the exact current functions and anchors in Report201.

The replacement target is:

`structured ERP form → validated fields → meaningful line entry → totals/summary → authoritative API action → refresh`

not a static textarea/CRUD dialog.

## PRODUCTION / UI CONTRACT

Request:
`purchase_create_request_atomic`

RFQ:
`purchase_create_rfq_atomic`

Quotation:
`purchase_create_quotation_atomic`

Invoice:
`purchase_create_invoice_atomic`

Return:
`purchase_create_return_atomic`

Payment:
`purchase_post_payment_atomic`

Settings:
`purchase_set_settings_atomic`

Reports:
`purchase_get_reports`

Physical stock remains outside the purchase UI and is controlled by the existing inventory architecture.

## GOVERNANCE RULE — DO NOT REGRESS

`CURRENT GIT → CURRENT SOURCE → CURRENT PRODUCTION → CURRENT DATABASE → CURRENT DEPLOYMENT → CURRENT BROWSER → CURRENT NETWORK → VERIFY → CLOSE`

Backend foundation does not equal modal completion.
Modal completion does not equal Browser E2E.
Browser E2E does not equal Production closure without current network/database evidence.

## NEXT CTO / ASSISTANT START HERE

```text
1. Re-read this CURRENT_STATE.
2. Verify CURRENT Git HEAD + direct parent.
3. Verify current Mother blob and current source anchors.
4. Verify current Production RPC/Edge versions.
5. Verify current Browser/Console/Network evidence.
6. Close the parser blocker first.
7. Open one Purchase modal only.
8. Test UI validation.
9. Test Edge/RPC.
10. Verify DB record + status history/audit + downstream relationship.
11. Refresh Mother and confirm the result is visible.
12. Verify network response and zero console errors.
13. Close the modal closure 100%.
14. Reconcile Git/Production again.
15. Move to the next genuinely open closure.
```

## DOCUMENTATION

Latest session report:
`doc/Draft/Reprots/Report201_PURCHASE_MODAL_SURGICAL_CLOSURE_20260915.md`

Previous forensic parser report:
`doc/Draft/Reprots/Report199_MOTHER_E2E_PURCHASE_SYNTAX_FORENSIC_20260915.md`

Previous Purchase forensic report:
`doc/Draft/Reprots/Report200_MOTHER_PURCHASE_MODALS_GOLD_DIAMOND_FORENSIC_20260915.md`
