# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-15 — current Git / current Mother source / current Production / current Database / current Deployment evidence were rechecked in this session.

## SOURCE OF TRUTH

Historical reports are reference-only. They are not current state.

The governing truth is:
`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

Full Browser/System E2E additionally requires:
`CURRENT BROWSER + CURRENT CONSOLE + CURRENT NETWORK`

**Mother System Source of Truth:**
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

Historical fragments only:
`Current/PWA/main2/*`
`Original/PWA/main/*`
`New-main`

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

Current Mother blob:
`bc268b9bb350991df64221e7f99b958264fb8d5f`

HEAD diff is timestamp-only. Parent contains the previously required `_openPO` onclick syntax correction near source line 9577.

## CURRENT MOTHER

The current Mother source was extracted directly from the current HEAD and the PurchaseGold block was read as the current source, not from historical fragments.

Current PurchaseGold functions:

`createRequest()` — lines 9271–9323
`createRFQ()` — lines 9365–9414
`createQuotation()` — lines 9461–9531
`createInvoice()` — lines 9616–9686
`createReturn()` — lines 9730–9787
`createPayment()` — lines 9828–9906
`reports()` — lines 9908–9949
`settings()` — lines 9951–9977
`saveSettings()` — lines 9979–10001

Current parser/action-string defects described in older reports are not the current blocker; the current source contains the corrected purchase action strings.

Current blocker:
**Purchase modals are functionally shallow and visually below the Gold/Diamond target.**

The current implementation uses basic `swal2-input`, `swal2-select`, and pipe-delimited textareas instead of structured document-entry forms.

## CURRENT PURCHASE MODAL FINDINGS

`createRequest` currently collects title/date/items/notes through a textarea. It does not present a real line-item editor or item verification UX.

`createRFQ` currently selects request/suppliers/date but does not show inherited request lines or a professional bidders workflow.

`createQuotation` currently collects lines through `item_code|qty|price|discount|tax` textarea and has no line grid or live totals.

`createInvoice` currently asks for raw `purchase_order_id` text and uses a textarea instead of an actual PO selector and inherited PO lines.

`createReturn` currently asks for `item_code|qty|reason` and does not display the invoice's received quantity as the return limit.

`createPayment` currently supports only one invoice allocation, despite Production supporting multiple invoice allocations.

`reports` currently reads two views directly and exposes only two report sections, despite Production exposing `purchase_get_reports`.

`settings` currently exposes only part of `purchase_settings` and does not expose return/payment prefixes, inventory policies, or default branch.

## CURRENT PURCHASE PRODUCTION

Project: `fiilmooggumokxanwiyx`

Current purchase capability layer:
`save-purchase-order` — ACTIVE — version 6 — verify_jwt=true.

Current Purchase schema exists and already includes the required relational entities; no duplicate Purchase tables were justified in this closure.

Current transactional counts for the live Company context checked in this session:

```text
purchase_requests    = 0
purchase_rfqs        = 0
purchase_quotations  = 0
purchase_orders      = 0
purchase_invoices    = 0
purchase_returns     = 0
purchase_payments    = 0
```

No permanent test fixtures were inserted.

## CURRENT PURCHASE RPC CONTRACT

Production currently exposes the required lifecycle through:

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
`receive_purchase_atomic`

Important idempotency contracts already exist in Request, Quotation, Invoice, Return and Payment records.

`receive_purchase_atomic` currently accepts an explicit UUID operation identity and performs duplicate detection through the existing `receiving.operation_id` UNIQUE contract.

## PRODUCTION CHANGE EXECUTED THIS SESSION

Migration applied directly to Production:

`purchase_reports_settings_tenant_hardening_20260915`

Canonical Git migration added:

`supabase/migrations/20260915_purchase_reports_settings_tenant_hardening.sql`

Changes:

1. `purchase_get_reports` now company-scopes `unbilled_receipts` through `purchase_orders`.
2. `purchase_set_settings_atomic` now validates `default_branch_id` against an active branch belonging to the same company.
3. Settings RPC now persists:
   `return_prefix`
   `payment_prefix`
   `require_inventory_on_invoice`
   `require_inventory_voucher_on_return`

Post-migration function definitions were re-read from Production.

## CURRENT PURCHASE REALTIME

The current `supabase_realtime` publication includes:

`purchase_requests`
`purchase_rfqs`
`purchase_quotations`
`purchase_invoices`
`purchase_payments`
`purchase_returns`

This proves database publication only. Mother subscription/refresh still requires Browser evidence.

## CURRENT OWNER PATCH

Mother HTML was intentionally NOT modified by the assistant.

Prepared complete surgical replacement package:

`RAWAEA_Purchase_Modal_Owner_Patch_20260915.md`

It contains exact replacements for:

- Purchase realtime subscription helper.
- Request modal.
- RFQ modal.
- Supplier quotation modal.
- Purchase invoice modal.
- Purchase return modal.
- Supplier payment multi-invoice allocation modal.
- Reports screen through `GET_REPORTS`.
- Complete Purchase Settings screen.
- Complete `saveSettings` payload.

The exact current line ranges and deletion anchors are documented inside the patch package.

## CURRENT FORENSIC REPORT

`doc/Draft/Reprots/Report203_CURRENT_MOTHER_PURCHASE_MODAL_FORENSIC_20260915.md`

Historical reports retained; none were deleted.

## FORENSIC METHOD — REQUIRED FOR NEXT SESSION

1. Treat reports as historical evidence, not current state.
2. Re-read CURRENT_STATE.
3. Re-read current Git HEAD and direct parent.
4. Re-open the current Mother source around the exact problem.
5. Re-open current Production RPCs, schema and Edge deployment.
6. Identify one Closure Unit.
7. Use historical code only to recover intent, never to replace current evidence.
8. Separate owner-only Mother work from Production work.
9. For Mother edits, provide exact full block with source start/end anchor and current line number.
10. For Production fixes, use canonical migration then re-read the deployed definition.
11. Do not create infrastructure that already exists.
12. Do not repair previously closed defects unless fresh evidence reopens them.
13. After the Owner merges Mother changes, re-read the current HEAD/blob again.
14. Run a fresh browser session and capture Console + PageError + Network.
15. Verify the RPC result, DB state, audit trail and realtime refresh for each critical operation.
16. Take the Production snapshot at the same time as the final report.
17. If a report conflicts with Production, Production wins.
18. Do not declare Gold/Diamond closure before Browser + Network + DB evidence is complete.

## CURRENT CLOSURE STATUS

```text
Current Git/Parent                         VERIFIED
Current Mother source                      VERIFIED
Current Production purchase schema         VERIFIED
Current Production purchase RPC layer     VERIFIED
Current save-purchase-order deployment    VERIFIED
Current Purchase Realtime publication     VERIFIED
Production report hardening               DEPLOYED + VERIFIED
Production settings hardening             DEPLOYED + VERIFIED
Current Purchase modal root cause         VERIFIED
Owner surgical patch                       READY
Fresh Browser Console                      NOT YET PROVEN
Fresh Browser Network                      NOT YET PROVEN
Full Purchase modal E2E                    OPEN
Gold/Diamond Purchase closure              OPEN UNTIL OWNER MERGE + FRESH E2E
```

## FINAL SELF-AUDIT

### What is proven

- The current Mother is the actual published Source of Truth.
- HEAD and direct parent were rechecked.
- The earlier parser issue is not the current modal blocker.
- Purchase backend infrastructure already exists.
- Current Production report/settings defects were hardened.
- Current Realtime publication exists.
- The current Purchase UX gap is in the Mother modal implementations.

### What is not proven

- Owner has not yet merged the new Mother surgical replacements.
- Fresh Browser execution has not yet been observed.
- Fresh Console/PageError/Network evidence for the new modal forms does not yet exist.
- Full live Purchase lifecycle has not yet been executed as a browser E2E.

### Next closure

`Owner merge → Fresh Browser → Request modal → RFQ modal → Quotation modal → Invoice modal → Return modal → Payment modal → Reports → Settings → Console/Network/DB/Realtime final proof`
