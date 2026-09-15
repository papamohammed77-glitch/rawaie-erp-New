# Report204 — Current Purchase Modal Closure / Production Hardening — 2026-09-15

## الحقيقة المعتمدة

التقارير السابقة استرشادية فقط. تمت إعادة المطابقة من CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.

النظام الأم المعتمد:
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

## Git verification

Mother repository:
`papamohammed77-glitch/erp-frontend`

Current HEAD:
`befa657277fc013c4fe4d3e326ed8fc5d1040b7b`

Direct parent:
`b6d35c5a1a362f381c9868bbc578de988b219c50`

HEAD changes only the HTML timestamp. The parent contains the previous `_openPO` syntax correction. Current Mother blob:
`bc268b9bb350991df64221e7f99b958264fb8d5f`.

## Criminal finding

The previous parser defect is not the present problem.

The current problem is the shallow implementation of the PurchaseGold modal layer. The current functions use basic SweetAlert inputs/selects and textareas where the target workflow needs document-style entry, line items, inherited source documents, validation, totals and multi-allocation.

Affected current functions:

- `createRequest()` 9271–9323
- `createRFQ()` 9365–9414
- `createQuotation()` 9461–9531
- `createInvoice()` 9616–9686
- `createReturn()` 9730–9787
- `createPayment()` 9828–9906
- `reports()` 9908–9949
- `settings()` 9951–9977
- `saveSettings()` 9979–10001

## Production findings

The relational Purchase infrastructure already exists. No duplicate tables were required.

The current Purchase Edge capability is `save-purchase-order` version 6, ACTIVE, JWT verified.

Purchase Realtime publication includes:
`purchase_requests`, `purchase_rfqs`, `purchase_quotations`, `purchase_invoices`, `purchase_payments`, `purchase_returns`.

Current live transaction counts checked during this closure are all zero for the primary Purchase documents of the live Company context. No permanent test data was created.

## Production changes actually executed

### Migration A
`purchase_reports_settings_tenant_hardening_20260915`

- fixed Company scoping of `purchase_get_reports.unbilled_receipts`.
- validated `default_branch_id` in `purchase_set_settings_atomic`.
- enabled persistence of return/payment prefixes and inventory-policy fields.

### Migration B
`purchase_modal_document_integrity_20260915`

- RFQ quotations now verify that the RFQ belongs to the same company and the supplier is an invited bidder.
- PO-linked invoices now verify company and supplier consistency.
- PO-linked invoice creation now honors `require_receiving_before_invoice`.
- supplier payments now verify treasury company context and honor `require_invoice_before_payment` when enabled.
- existing idempotency/allocation checks remain active.

Both migrations were applied directly to Production and the resulting RPC identities were re-read from Production.

## Mother changes — owner responsibility

The assistant did NOT modify the Mother HTML.

A complete owner surgical patch was prepared in:
`RAWAEA_Purchase_Modal_Owner_Patch_20260915.md`

It specifies exact delete/replace ranges for:

- Purchase realtime subscription helper.
- structured Request modal with validated item rows.
- RFQ modal with inherited request lines and multiple bidders.
- Quotation modal with inherited RFQ lines and editable commercial fields.
- Purchase Invoice modal with actual PO selection and inherited PO lines.
- Purchase Return modal with received-quantity limits.
- Supplier Payment modal with multi-invoice allocation.
- Reports through the authoritative `GET_REPORTS` capability.
- Complete Purchase Settings.
- Complete Settings save payload.

The patch package is a surgical replacement package, not a conceptual sketch.

## Why no new tables / Edge Functions were created

Production already contains the necessary Purchase schema, RPC lifecycle and Edge capability layer. Creating another infrastructure path would add duplicate business logic and debt instead of solving the actual gap.

## Industry reference

Odoo, Dynamics 365 and SAP were checked as design references. Their common pattern is a document-oriented header + item lines + vendor context + inherited source-document data + reviewable commercial values. The RAWAEA implementation follows that functional pattern without copying their UI verbatim.

## Tests and limitations

Verified:

- current Git HEAD and parent.
- current Mother source.
- current Purchase schema.
- current Purchase RPC layer.
- current Edge deployment.
- current Realtime publication.
- Production report/settings/document-integrity hardening.
- absence of permanent Purchase fixture data.

Not yet verified because Mother is owner-modified and must be merged first:

- fresh browser parser execution after the new modal patch.
- Console/PageError clean state.
- Network/HTTP 2xx for each Purchase operation through the UI.
- full Purchase workflow E2E against fresh Production documents.
- Realtime refresh behavior in the browser.

Therefore the correct status is **OPEN pending Owner merge + Fresh Browser E2E**, not falsely reported as 100% closed.

## Final Self-Audit

### What was proven

The current problem differs from the stale parser problem. The backend foundation already exists. The current defect is primarily Mother modal implementation depth, with several backend document-integrity safeguards now hardened in Production.

### What was not proven

Final browser closure and Gold/Diamond UX cannot be truthfully claimed before the owner applies the Mother patch and a new Browser/Console/Network/DB/Realtime run is captured.

## Instructions to the next assistant

1. Read `CURRENT_STATE.md` first, but treat it as a checkpoint, not a substitute for current evidence.
2. Re-open CURRENT Git HEAD and DIRECT PARENT.
3. Re-open the current Mother source around the exact target function before touching anything.
4. Confirm the Owner merged the surgical patch; if not, give exact full replacement blocks and do not invent browser PASS.
5. Read Production RPC/Edge/schema directly.
6. Use historical reports only to recover intent and business contract.
7. Do not repeat closed parser fixes unless a fresh source read proves they reopened.
8. Verify the Purchase modal itself: DOM, events, preConfirm validation, RPC payload and resulting DB state.
9. For Request/RFQ/Quotation/Invoice/Return/Payment, test one flow at a time and capture Console + Network + DB + audit effects.
10. After each test, take a Production snapshot in the same time window used by the report.
11. Re-check Realtime behavior separately; publication existence is not UI subscription proof.
12. Only after all modal operations pass should the PurchaseGold closure be marked Gold/Diamond closed.
13. Never recreate infrastructure already present in Production.
14. Never infer Company or Item identity from a report when Production can answer it directly.
15. If any current evidence conflicts with this report, CURRENT PRODUCTION wins.
