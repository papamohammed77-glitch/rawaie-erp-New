# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-15 19:20 UTC

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
Current HEAD: `f858fb2f909a074dfe97b90134ef5e05b5592cd9`
HEAD message: `Update comment timestamp in main.html`
Direct parent: `5767266ffdc853846193494db6d49ece19c3ef7f`
Parent message: `Refactor button generation loop in main.html`
Parent of parent: `9b39626e8679e35b8215adf2ba4977b838e1f5d2`

Current mother blob:
`a530b7adb2d590e0f7f476ce8c81f33dcd186e92`

The direct parent remains historically closed. Its button-generation change near the Purchase module is not reopened because the current blocker is a different malformed escape sequence in later PurchaseGold actions.

## CURRENT MOTHER FILE EVIDENCE

`companies/company-1/main.html` remains the sole execution source for the mother system. Current HEAD changes only the timestamp comment; the JavaScript body is unchanged from the direct parent.

The current mother content was inspected from the CURRENT blob, with anchors searched through the large source body, including PurchaseGold actions and the final EOF.

EOF verified:

```html
</script>
</body>
</html>
```

The GitHub connector does not expose a reliable line-map for the huge blob when range reads are requested; therefore exact line numbers are used only where independently confirmed by current Browser Console or by the current source sequence. No invented line numbers are accepted.

## CURRENT FORENSIC BLOCKER

Current Browser Console:

```text
main:9263 Uncaught SyntaxError: Unexpected string (at main:9263:65)
```

### Corrected diagnosis

The earlier Report198 diagnosis that treated `raw.split('\\n')` as the sole cause at line 9263 was stale/incomplete.

CURRENT SOURCE directly contains the actual blocker inside `requests(host)`:

```javascript
(x.status === 'PendingApproval' || x.status === 'Draft'
  ? '<button onclick="RW_PurchaseGold.approveRequest(\\'' + esc(x.id) + '\\')" class="px-3 py-1 rounded-lg bg-blue-600 text-white">اعتماد</button>'
  : '') +
```

The current parser failure is caused by the malformed `\\'` escaping in that JavaScript string.

### Secondary functional defect

Inside `RW_PurchaseGold.createRequest()` the current source contains:

```javascript
raw.split('\\
').forEach(function (line) {
```

This is not the same as the Browser-reported 9263 blocker. It is a separate source-level defect because the intended separator is `\n`; it must be corrected while closing the PurchaseGold E2E unit.

### Additional CURRENT PurchaseGold parser defects found

The same malformed escape pattern was found in these current actions:

`sendRFQ`
`acceptQuotation`
`convertQuotation`
`postInvoice`
`postReturn`

Therefore the PurchaseGold parser closure cannot safely stop after `approveRequest`; fixing only the first error would predictably expose another parser error later in the same module.

## OWNER SURGICAL ACTION — MOTHER FILE

The assistant must not modify:
`erp-frontend/companies/company-1/main.html`

The owner must apply the current surgical fixes exactly as documented in:

`doc/Draft/Reprots/Report199_MOTHER_E2E_PURCHASE_SYNTAX_FORENSIC_20260915.md`

### Confirmed line

`main.html` line `9263` is the current Browser-reported blocker.

### createRequest sequence

The current source sequence places `createRequest()` at approximately line `9271`, with the malformed `raw.split` sequence at approximately `9285–9286`. These coordinates are tied to the current source sequence used in the investigation, not to an old fragment.

## PRODUCTION DECISION

No Production table, Edge Function, RPC, Inventory, Accounting, or Auth change is justified for the current parser blocker.

Production purchase infrastructure was rechecked and is present, including:

`purchase_requests`
`purchase_rfqs`
`purchase_quotations`
`purchase_invoices`
`purchase_returns`
`purchase_payments`

and purchase RPCs such as:

`purchase_create_request_atomic`
`purchase_approve_request_atomic`
`purchase_create_rfq_atomic`
`purchase_send_rfq_atomic`
`purchase_create_quotation_atomic`
`purchase_accept_quotation_atomic`
`purchase_convert_quotation_to_po_atomic`
`purchase_create_invoice_atomic`
`purchase_post_invoice_atomic`
`purchase_post_payment_atomic`
`purchase_create_return_atomic`
`purchase_post_return_atomic`

Thus the current blocker is frontend parser integrity, not missing backend infrastructure.

## ASSEMBLY

`forensic_main_assembly.yml` was re-read and is already correct:

```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
assembly_status:
  mode: published_main_is_authoritative
  fragment_mode: historical_reference_only
```

No path correction is required.

## CURRENT BROWSER E2E

Browser E2E remains OPEN until the owner publishes the surgical mother-file corrections and a fresh browser run is captured.

A static source finding or a previous browser result is not a current PASS.

Required closure evidence:

```text
owner edit
→ publish
→ verify published commit
→ fresh browser
→ Console
→ Page Errors
→ Login
→ authenticated shell
→ first navigation
→ PurchaseGold navigation
→ Purchase actions
→ Network
→ re-read current Git
→ EOF
→ close only proven closure
```

## SESSION 2026-09-15 — REPORT199

### What was newly established

1. Current HEAD/parent reconciliation was repeated.
2. Current mother blob remained `a530b7...`.
3. EOF remained verified.
4. `forensic_main_assembly.yml` remained correct.
5. The Browser-reported `9263` blocker was re-identified from CURRENT SOURCE itself.
6. Report198 was corrected: `raw.split` is a secondary functional defect, not the current 9263 parser root cause.
7. Five additional malformed PurchaseGold action strings were found in CURRENT SOURCE.
8. No backend/Production modification is justified for this closure.
9. Report199 was added with exact owner surgical replacements and next E2E sequence.

## TAILWIND WARNING

```text
cdn.tailwindcss.com should not be used in production
```

This is a separate production-warning concern. It is not the cause of `Unexpected string` at 9263 and does not block this parser closure.

## CURRENT CLOSURE MATRIX

```text
Current Git/Parent Reconciliation       = VERIFIED
Current Mother Blob Identity             = VERIFIED
Current Mother EOF                      = VERIFIED
forensic_main_assembly                  = VERIFIED
Current Browser SyntaxError              = PROVEN
Current Root Cause                      = PROVEN
Additional PurchaseGold syntax defects = PROVEN
Owner Mother Edit                       = REQUIRED
Production Change for Parser Blocker    = NOT REQUIRED
Fresh Browser E2E                        = REQUIRED
PurchaseGold Functional E2E             = OPEN
Overall current closure                 = OPEN
```

## NEXT CTO — START HERE

```text
CURRENT_STATE
→ CURRENT GIT HEAD
→ DIRECT PARENT
→ CURRENT MOTHER BLOB
→ CURRENT DEPLOYMENT
→ CURRENT CONSOLE
→ CURRENT NETWORK
```

Then:

```text
exact current console error
→ exact current source anchor
→ full surrounding function
→ current consumers
→ parent/current diff
→ historical intent only
→ exact surgical owner patch
→ publish
→ fresh browser
→ Console/Page/Network
→ re-read Current Source
→ close only what is proven
→ move directly to the next open E2E Closure
```

Do not trust stale reports as current state. Do not use historical fragments as Source of Truth. Do not invent line numbers. Do not modify Production for a frontend parser defect. Do not reopen a closed closure without new current evidence.

## REQUIRED OWNER PATCH SUMMARY

In `companies/company-1/main.html`:

1. At the current Browser error `9263`, replace the malformed `approveRequest` ternary line with the corrected `type="button"` version documented in Report199.
2. Inside `RW_PurchaseGold.createRequest()`, replace the malformed `raw.split` two-line sequence with `raw.split('\n').forEach(function (line) {`, or replace the entire function with the complete Report199 version.
3. In `sendRFQ`, `acceptQuotation`, `convertQuotation`, `postInvoice`, and `postReturn`, replace the malformed `\\'` escaping exactly as documented in Report199.

No other historical Purchase module change is to be reopened unless fresh E2E evidence requires it.

## DOCUMENTATION

New session report:
`doc/Draft/Reprots/Report199_MOTHER_E2E_PURCHASE_SYNTAX_FORENSIC_20260915.md`
