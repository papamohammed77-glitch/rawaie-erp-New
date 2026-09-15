# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-15 19:56 UTC

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

HEAD changes the first HTML timestamp only. The direct parent contains a previous Purchase button syntax repair near line 9577.

## CURRENT MOTHER FILE / EOF

Current Mother is the sole execution source. GitHub confirms the current blob identity above.

The connector does not currently provide a reliable complete line-map for this very large blob through range retrieval, therefore no new line number is invented.

Previously proven EOF remains:

```html
</script>
</body>
</html>
```

## CURRENT FORENSIC PURCHASE BLOCKER

Known current Browser error:

```text
main:9263 Uncaught SyntaxError: Unexpected string (at main:9263:65)
```

Current-source root cause previously re-proven:

```javascript
(x.status === 'PendingApproval' || x.status === 'Draft'
  ? '<button onclick="RW_PurchaseGold.approveRequest(\\'' + esc(x.id) + '\\')" class="px-3 py-1 rounded-lg bg-blue-600 text-white">اعتماد</button>'
  : '') +
```

Five additional malformed PurchaseGold action strings remain identified:

`sendRFQ`
`acceptQuotation`
`convertQuotation`
`postInvoice`
`postReturn`

`RW_PurchaseGold.createRequest()` also contains the malformed separator sequence previously identified at approximately `9285–9286`.

The exact owner surgical replacements are preserved in:

`doc/Draft/Reprots/Report199_MOTHER_E2E_PURCHASE_SYNTAX_FORENSIC_20260915.md`

## FORENSIC ASSEMBLY

`forensic_main_assembly.yml` is already correct and remains:

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

Production currently contains the complete purchase table family:

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

At reconciliation time these tables were almost entirely empty in Production; no real purchase transaction dataset existed to count as E2E production data.

Verified purchase RPCs include:

`purchase_create_request_atomic`
`purchase_approve_request_atomic`
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

## SESSION 2026-09-15 — REPORT200

### Production changes executed

1. `purchase_submit_request_atomic` deployed.
2. `purchase_reject_request_atomic` deployed.
3. `purchase_cancel_document_atomic` deployed.
4. `purchase_get_dashboard` deployed.
5. `purchase_quotation_comparison` view was aligned to show supplier/quotation/item price ranking.
6. `purchase_supplier_balance` view was aligned to combine supplier ledger and open purchase invoice balance.

These changes were made in Production because the underlying purchase infrastructure already existed and the missing controls were functional backend gaps, not a reason to create duplicate tables.

### What was deliberately not changed

`erp-frontend/companies/company-1/main.html` was not modified by the assistant.

No Inventory writer, Order/Runsheet lifecycle, Auth, or stock-voucher Supplier Return flow was changed as part of the Purchase Modal task.

No duplicate purchase table family was created.

## PURCHASE MODAL TARGET

The functional target remains:

```text
Purchase Request
→ Approval
→ RFQ
→ Multi-supplier replies
→ Quotation comparison
→ Accepted quotation
→ Purchase Order
→ Receipt
→ Purchase Invoice
→ Post / matching
→ Supplier Payment / allocation
→ Return / credit linkage
→ Reports
→ Settings
```

The current database already contains the necessary structural entities and policy controls for this lifecycle.

## CURRENT OWNER ACTION — MOTHER FILE

The owner must first close the parser blocker before functional modal E2E.

Exact surgical action:

1. In `requests(host)` at the confirmed Browser error `9263`, replace the malformed `approveRequest` three-line block using Report199 Section 6.
2. In `RW_PurchaseGold.createRequest()`, replace the malformed `raw.split` two-line sequence using Report199 Section 7, or replace the whole function with the complete Section 9 version.
3. In `sendRFQ`, `acceptQuotation`, `convertQuotation`, `postInvoice`, and `postReturn`, replace the malformed escape strings using Report199 Section 8.

Do not use historical fragments as the editing source.

## CURRENT E2E STATUS

```text
Current Git/Parent                 = VERIFIED
Current Mother blob               = VERIFIED
Assembly Source of Truth          = VERIFIED
Production purchase schema        = VERIFIED
Purchase RPC foundation           = VERIFIED
Purchase control extensions      = DEPLOYED
Current parser blocker            = PROVEN
Owner Mother edit                 = REQUIRED
Fresh Browser Console             = NOT YET PROVEN CLEAN
Purchase functional E2E           = OPEN
Gold/Diamond purchase modals      = OPEN
Overall task                      = OPEN
```

## IMPORTANT GOVERNANCE RULE

وجود Backend foundation لا يساوي اكتمال الـModal.
وجود Modal UI لا يساوي اكتمال Business Workflow.
وجود static analysis لا يساوي Production PASS.
وجود Browser result قديم لا يساوي Browser PASS حالي.

كل closure يجب أن يمر:

`CURRENT GIT → CURRENT SOURCE → CURRENT PRODUCTION → CURRENT DATABASE → CURRENT DEPLOYMENT → CURRENT BROWSER → CURRENT NETWORK → VERIFY → CLOSE`

## NEXT CTO / ASSISTANT START HERE

```text
1. Re-read CURRENT_STATE.
2. Verify current Git HEAD and direct parent.
3. Verify current Mother blob.
4. Verify current Production deployment.
5. Verify current Browser/Console/Network evidence.
6. Close the proven parser blocker first.
7. Run fresh PurchaseGold E2E.
8. Open exactly one modal Closure at a time.
9. For every modal: UI → validation → RPC/Edge → DB transition → history/audit → refresh → Network.
10. Do not invent backend tables when current schema already provides the responsibility.
11. Do not modify the Mother directly; provide exact owner surgical replacement.
12. After each proven closure, re-read Current Source and Current Production.
13. Move directly to the next genuinely open closure.
```

## DOCUMENTATION

Latest session report:
`doc/Draft/Reprots/Report200_MOTHER_PURCHASE_MODALS_GOLD_DIAMOND_FORENSIC_20260915.md`

Previous forensic parser report:
`doc/Draft/Reprots/Report199_MOTHER_E2E_PURCHASE_SYNTAX_FORENSIC_20260915.md`
