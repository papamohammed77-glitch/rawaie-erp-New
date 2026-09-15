# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-15 18:12 UTC Production snapshot; CURRENT Git/Parent/Mother reconciled in the same session.

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

Current Mother blob:
`bc268b9bb350991df64221e7f99b958264fb8d5f`

HEAD changes the first HTML timestamp only. The direct parent fixes `_openPO` button syntax near line 9577.

## CURRENT MOTHER / ASSEMBLY

Current Mother is the sole execution source.

Current file size from Git tree: 1,205,314 bytes.

`forensic_main_assembly.yml` is already correct:

```yaml
repository: papamohammed77-glitch/erp-frontend
path: companies/company-1/main.html
ref: main
mode: published_main_is_authoritative
fragment_mode: historical_reference_only
```

No path correction was required.

Previously proven EOF:

```html
</script>
</body>
</html>
```

## CURRENT FORENSIC PURCHASE SOURCE

Confirmed in CURRENT Mother:

- `RW_PurchaseGold` block exists.
- `requests(host)` contains the purchase request list and approval action.
- `createRequest()` begins at source line **9278**.
- `createRequest()` contains malformed `raw.split` at **9292–9293**.
- `createRFQ()` begins at **9373**.
- `createQuotation()` is approximately **9465**.
- `createInvoice`, `createReturn`, `createPayment`, `reports`, `settings` continue in the same `RW_PurchaseGold` block.

### Current parser blocker

The current Mother still contains the malformed `approveRequest` escaping associated with the known browser parser failure:

`main:9263:65 — Uncaught SyntaxError: Unexpected string`

Current malformed block:

```javascript
(x.status === 'PendingApproval' || x.status === 'Draft'
  ? '<button onclick="RW_PurchaseGold.approveRequest(\\'' + esc(x.id) + '\\')" class="px-3 py-1 rounded-lg bg-blue-600 text-white">اعتماد</button>'
  : '') +
```

Correct owner replacement:

```javascript
(x.status === 'PendingApproval' || x.status === 'Draft'
  ? '<button type="button" onclick="RW_PurchaseGold.approveRequest(\'' + esc(x.id) + '\')" class="px-3 py-1 rounded-lg bg-blue-600 text-white">اعتماد</button>'
  : '') +
```

Do not delete:

```javascript
'</td></tr>';
```

### `createRequest()` separator defect

Current lines **9292–9293**:

```javascript
        raw.split('\
').forEach(function (line) {
```

Correct line:

```javascript
        raw.split('\n').forEach(function (line) {
```

### Other current PurchaseGold action-string defects

The same malformed escape pattern is present in:

`sendRFQ`
`acceptQuotation`
`convertQuotation`
`postInvoice`
`postReturn`

Correct final pattern:

```javascript
onclick="RW_PurchaseGold.<FUNCTION>(\'' + esc(x.id) + '\')"
```

Do not change surrounding business logic.

## CURRENT PRODUCTION PURCHASE INFRASTRUCTURE

Production already contains the purchase relational model; no duplicate purchase tables were justified.

Tables currently present include:

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

Current Production transactional counts at snapshot `2026-09-15 18:12:31.583834+00`:

```text
Company الروائع (00000000-0000-0000-0000-000000000001)
requests    = 0
rfqs        = 0
quotations  = 0
orders      = 0
invoices    = 0
payments    = 0
returns     = 0
```

No live Purchase dataset is being treated as an E2E fixture.

## CURRENT PURCHASE RPC CONTRACT

Production currently exposes the purchase lifecycle through:

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

Important operation identity contracts are already present in Request, Quotation, Invoice, Return and Payment records.

## CURRENT PURCHASE REALTIME

`supabase_realtime` currently includes:

`purchase_requests`
`purchase_rfqs`
`purchase_quotations`
`purchase_invoices`
`purchase_payments`
`purchase_returns`

This proves database publication. Mother subscription/refresh behavior still requires browser evidence.

## CURRENT PRODUCTION SECURITY HARDENING

Migration applied:

`purchase_harden_public_rpc_execution_20260915`

Direct client execution was removed for these SECURITY DEFINER workflow-control functions:

`purchase_submit_request_atomic`
`purchase_reject_request_atomic`
`purchase_cancel_document_atomic`
`purchase_company_status_history`

Post-change privileges:

```text
anon          = absent
authenticated = absent
service_role  = present
```

## CURRENT EDGE / CAPABILITY LAYER

Current purchase capability layer:

`save-purchase-order`

Previously verified deployment state: version 6 with authenticated user Company context and purchase workflow routing. Any new version-specific claim must be freshly re-checked.

## CURRENT E2E GATE

```text
Current Git + Direct Parent      = VERIFIED
Current Mother blob              = VERIFIED
Assembly Source of Truth         = VERIFIED
Production purchase schema       = VERIFIED
Purchase RPC inventory           = VERIFIED
Purchase Realtime publication    = VERIFIED
Production RPC hardening         = CLOSED
Mother parser                    = OPEN
Professional modal UI            = OPEN
Fresh Browser Console             = NOT PROVEN CLEAN
Fresh Browser Network             = NOT PROVEN
Purchase functional E2E           = OPEN
Gold/Diamond Purchase closure     = OPEN
```

## EXECUTION DECISIONS

No new Purchase tables were created because current Production already contains the required relational model.

No new Purchase Edge Function was created because the current purchase capability layer exists.

No Inventory, Order/Runsheet, Stock Voucher, Accounting or Auth engine was changed merely because the Purchase UI is shallow; no current evidence tied those protected engines to this UI defect.

No fake live purchase history was inserted into Production.

Mother was not modified by the assistant because owner-only frontend responsibility is explicit.

## LATEST FORENSIC REPORT

Created in this session:

`doc/Draft/Reprots/Report202_CURRENT_MOTHER_PURCHASE_E2E_FORENSIC_20260915.md`

Previous reports retained:

`Report199_MOTHER_E2E_PURCHASE_SYNTAX_FORENSIC_20260915.md`
`Report200_MOTHER_PURCHASE_MODALS_GOLD_DIAMOND_FORENSIC_20260915.md`
`Report201_PURCHASE_MODAL_SURGICAL_CLOSURE_20260915.md`

## NEXT CTO / ASSISTANT — READ BEFORE ANY ACTION

ابدأ من **آخر حقيقة فقط**. لا تعتبر أي تقرير قديم Current State.

```text
1. اقرأ CURRENT_STATE.
2. ثبّت CURRENT Git HEAD.
3. افتح DIRECT PARENT واقرأ الـdiff الفعلي.
4. ثبّت CURRENT Mother blob SHA.
5. افتح CURRENT Mother source حول المشكلة واقرأ الدالة الكاملة قبل التعديل.
6. افتح CURRENT Production database مباشرة.
7. افتح CURRENT Edge deployment مباشرة.
8. ثبّت CURRENT Browser / Console / Network قبل إعلان E2E.
9. حدد Closure واحدة فقط.
10. استخدم Historical Contract لفهم intent فقط، لا لاستبدال Production evidence.
11. افصل Mother owner work عن Production work.
12. أصلح Production فقط عندما يثبت defect في Production.
13. للـMother أعطِ owner exact search/delete/replace block مع start/end anchor ورقم السطر المثبت فقط.
14. بعد owner merge أعد قراءة CURRENT Git HEAD/blob.
15. شغّل Fresh Browser وليس tab أو cache قديمًا.
16. اجمع Console + PageError + Network + HTTP result.
17. اربط كل action بنتيجة RPC/DB/Status/Audit/Realtime.
18. خذ Production snapshot في نفس لحظة التقرير.
19. إذا اختلف التقرير مع Production فـProduction هي الحقيقة.
20. لا تعيد إصلاح Closure ثبت إغلاقها؛ انتقل لأول Closure مفتوح حقيقي.
```

## NEXT EXECUTION ORDER

```text
PARSER CLEAN
→ REQUEST MODAL
→ REQUEST APPROVAL
→ RFQ MODAL
→ SUPPLIER SELECTION
→ QUOTATION MODAL
→ QUOTATION COMPARISON
→ PO CONVERSION
→ PURCHASE INVOICE
→ POST / MATCHING
→ SUPPLIER PAYMENT
→ ALLOCATION
→ RETURN LINKAGE
→ REPORTS
→ SETTINGS
→ FINAL BROWSER E2E
```

## FINAL SELF-AUDIT

### What I proved

- Current Git HEAD and direct parent.
- HEAD changed timestamp only.
- Current Mother blob identity.
- Current Source of Truth / assembly path.
- Current Purchase tables and relational infrastructure.
- Current Purchase RPC layer.
- Current Realtime publication.
- Production security hardening of key Purchase workflow-control functions.
- Current Mother Purchase parser/action-string defects.
- Current Production Purchase transactional tables are empty for the live Company snapshot used.

### What I did not prove

- Fresh authenticated browser login.
- Current Mother parser-clean after owner patch.
- Full Purchase modal opening/submission in browser.
- Current browser network waterfall for each purchase modal.
- Full Purchase lifecycle E2E against real Production records.
- Final Gold/Diamond UI closure.

### Remaining open point

`Mother parser clean → Purchase modal E2E → Reports → Settings → final synchronization verification`.

### Non-regression rule

Do not change Inventory, Order/Runsheet, Stock Voucher or Accounting engines merely because a Purchase UI is shallow. Those engines remain protected contracts until current evidence proves otherwise.
