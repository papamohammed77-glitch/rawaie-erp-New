# Report675 — Buyer Quick Market Goods Custody / Supplier Return Implementation
**Date:** 2026-11-09
**Checkpoint:** LVE-2026-11-09-675
**Scope:** Buyer PWA — goods custody for Quick Market invoices, supplier-accepted returns, and receiver net-custody boundary.
**Status:** Source ChangeSet committed to a feature branch; CI passed on the latest commit. Production database and deployed Edge Function remain unchanged. Authenticated browser E2E and PostgreSQL runtime migration validation remain open.

---

## 1. Resume point and verified production baseline

This work resumes from LVE674; the forensic diagnosis was not repeated as a new starting point.

- Operational repository: \`papamohammed77-glitch/erp-frontend\`.
- Production base commit remains \`da37cbd27c0fd363bff95008919baee79622b654\`.
- Buyer baseline SHA from LVE674: \`072710c9db0184b0744eebd027fcdd3daf297269\`.
- Cloudflare Production \`rawaea-erp\` still points to the base commit above; no production deployment was initiated by this work.
- SMART ERP Production project: \`fiilmooggumokxanwiyx\`.
- Deployed Edge Function baseline was \`save-purchase-order\` v39; its original GitHub source was byte-identical to the deployed code.
- Production QMP invoice facts from the read-only inspection remain: PINV-1002 and PINV-1003 are Draft / EMPLOYEE_CUSTODY / NOT_RECEIVED, total EGP 1,430 and 29 units, with received quantity 0. No handover evidence or buyer goods custody events were present for these invoices. They were not backfilled or altered.

The established business boundary remains binding: invoice creation is not physical handover; the positive custody event requires the buyer to attest actual receipt and attach evidence. Likewise, the supplier return event is recorded only after the supplier actually accepts the goods. Neither event is a branch stock movement or an automatic supplier financial settlement.

## 2. ChangeSet implementation on feature branch

Feature branch:
\`fix/buyer-quick-market-supplier-return-lve675\`

Pull request:
\`#11 — Buyer: Quick Market supplier return and net custody\`
https://github.com/papamohammed77-glitch/erp-frontend/pull/11

Base: \`main\` at \`da37cbd27c0fd363bff95008919baee79622b654\`
Latest verified PR head: \`72b29072292908dd5e045723169e24734fffe16e\`
The PR is open and not merged.

### Files changed (five files only)

| File | Purpose | Latest content SHA |
|---|---|---|
| \`companies/company-1/purchasing/buyer.html\` | Buyer UI: return modal, net-custody details, separate pending-handover panel, explicit handover prompt, and corrected invoice modal closure | \`c1710250e1ca722526a64bc8625cb9936b4760e5\` |
| \`supabase/functions/save-purchase-order/index.ts\` | Adds authenticated \`REGISTER_QUICK_MARKET_SUPPLIER_RETURN\` operation to the existing Edge Function | \`8a3d07155a51179c213c542f4ab8d24424492e1e\` |
| \`supabase/migrations/20261109201500_buyer_quick_market_supplier_return_custody.sql\` | Complete proposed SQL: existing function replacements, new RPC, and narrow Storage policy changes | \`cd11f4dd08aa55e0a1326fcd44c089ea70f3bed4\` |
| \`tests/buyer_quick_market_supplier_return_contract.test.mjs\` | Buyer inline JavaScript syntax, UI/RPC wiring, mocked return scenarios, and SQL source-contract checks | \`7099963cdc65b741f55ed18c99c52807ba5ce6cf\` |
| \`.github/workflows/buyer-quick-market-return-ci.yml\` | Pull-request CI: contract tests, Edge TypeScript compilation, and Buyer Tailwind compilation | \`c415c125cfb39aa8a68fdfe4f33ecc0811115223\` |

The full proposed SQL is in the migration file above on the PR branch. It is not applied to Production.

### Functional details

**Buyer PWA**
- \`recordQuickMarketSupplierReturn\` displays the invoice line, original quantity, handover quantity, warehouse-accepted quantity, previous supplier returns, and current net custody.
- It accepts partial or full quantities only up to the current line-level custody.
- A reason and evidence file (PDF/JPEG/PNG/WebP, maximum 10 MB) are required.
- The operation uses one idempotency key. After an uncertain network response, the UI verifies the same operation ID and exact evidence path before treating it as committed.
- \`openInvoice\` now exposes handover and accepted-return actions independently of the edit-draft permission. This fixes the previous case where partial handover hid the next handover action.
- After creating a new Quick Market invoice, the buyer is explicitly asked whether physical handover occurred. The invoice remains excluded from confirmed custody unless the buyer continues and records the existing handover event.
- \`renderVehicleBalance\` displays pending handover quantities in a separate panel. It does not add pending quantities to confirmed goods custody.
- A modal-closing syntax defect found during source review was repaired. The complete inline Buyer script was parsed again after repair.

**Existing Edge Function**
- One new operation was added to \`save-purchase-order\`; no new Edge Function was created.
- The new operation is guarded by effective \`purchases\` permission and exact company, purchaser, invoice, evidence path, MIME and file-size checks.
- It calls the new RPC using the authenticated profile client.
- An uncertain RPC result is verified against \`return_events\`; an uploaded evidence object is removed through the Storage API only when the operation is confirmed not committed.
- Existing operations and Edge function versions in Production were not changed.

**Database migration**
- \`buyer_goods_custody_get_balances_atomic\`: classifies \`BUYER_TO_SUPPLIER_ACCEPTED\` according to source document. PurchaseInvoice events reduce supplier-owned goods; StockVoucher events retain the existing company-owned supplier-return classification. The function returns an additional \`pending_handover\` collection.
- \`buyer_goods_custody_get_invoice_handover_progress_atomic\`: returns handover, warehouse-accepted, supplier-returned and current net custody by invoice line, plus return and warehouse event histories.
- \`get_quick_market_receiving_queue_atomic\`: all three quantity aggregates subtract supplier-accepted returns and include purchaser/branch scoping and correction-root handling.
- \`receive_quick_market_purchase_atomic\`: applies the same net-custody calculation before accepting stock, preventing a supplier-returned unit from being received again.
- New RPC \`buyer_goods_custody_register_quick_market_supplier_return_atomic\`: appends negative \`BUYER_TO_SUPPLIER_ACCEPTED\` events linked to the original PurchaseInvoice and invoice line. It validates actor, purchaser, company, supplier, branch, invoice line, evidence object, MIME, size, reason, operation fingerprint and net custody. It locks the invoice and each line.
- The new RPC does not write stock, purchase invoice balances, supplier AP/ledger, treasury, cash custody, journal or GL tables.
- Storage policies remain private and owner-scoped. The proposal permits the new \`supplier-return-*\` evidence family and also allows a legitimate partially-paid invoice to upload a handover proof; no broad delete policy is added.
- The RPC's EXECUTE privilege is limited to \`authenticated\`; PUBLIC, anon and service_role are revoked. The Edge path uses the authenticated profile client.

No new table, no new Edge Function, no Parent \`main.html\`, no \`receiver.html\`, no Parent \`POST_RETURN\`, and no warehouse SupplierReturn route are used for this supplier-owned goods path.

## 3. Validation performed

### Passed

**Latest GitHub Actions run**
- Run ID: \`42676196171\`
- Commit: \`72b29072292908dd5e045723169e24734fffe16e\`
- Job: \`buyer-qmp-return\`
- Conclusion: **success**
- All relevant steps passed:
  1. Checkout exact PR revision.
  2. Setup Node.
  3. Buyer modal, idempotency and SQL contract scenarios.
  4. Compile Edge Function TypeScript syntax with esbuild.
  5. Compile Buyer Tailwind CSS.

**Behavioral tests**
The actual \`recordQuickMarketSupplierReturn\` method was isolated and executed in Node with mocked DOM, modal, Storage and API dependencies. Eight scenarios passed:
1. Partial accepted return calls the operation with the exact line and quantity.
2. Quantity greater than net custody is rejected before the RPC.
3. No confirmed custody prevents a supplier return.
4. Unsupported MIME is rejected.
5. File over 10 MB is rejected.
6. Non-owner buyer is rejected.
7. Ineligible invoice status is rejected.
8. Network timeout is accepted only when the server confirms the same operation ID and same uploaded evidence path.

The CI test script also confirms one inline Buyer script parses successfully and checks the Edge/RPC/UI wiring. The full Buyer inline script was separately parsed after the modal closure repair.

**Cloudflare Preview**
- For commit \`a19897a\`, the \`rawaea-erp\` Preview deployment succeeded. Preview URL: https://d068703f.rawaea-erp.pages.dev
- Branch Preview alias: https://fix-buyer-quick-market-suppl.rawaea-erp.pages.dev
- The latest \`rawaea-erp\` build for commit \`72b2907\` was still in progress at the time of the last status read; do not treat the earlier Preview deployment as proof that this final commit has deployed.
- The same PR also triggered separate Cloudflare projects \`rawaea-store\`, \`warehouse-supervisor\`, and \`erp-frontend\`, which reported build failures. No source files for those projects were changed in this PR. Their project logs have not been inspected, so the failures are recorded as unresolved separate-project build signals rather than being dismissed as harmless.

### Not passed / not yet performed

**PostgreSQL runtime validation**
- Supabase Branching could not create a SMART ERP development branch because the account/project plan requires Pro for Branching. A cost confirmation does not bypass this plan restriction.
- Existing \`rawaea-staging\` is not a valid target: it does not contain the Buyer goods custody or purchase invoice schema.
- Therefore the migration has not been executed against a schema-compatible database. The static CI assertions do not prove PostgreSQL syntax, privilege behavior, row-lock semantics or trigger compatibility.
- No test DDL or business data was written to Production.

**Authenticated browser E2E**
- The available connected browser is in Chat/read-only mode; its available tools only list tabs and read tab context, with no navigation/click control.
- The open RAWAEA parent tab currently presents a login screen (owner email prefilled, password blank); it is not an authenticated Buyer session.
- The public Cloudflare Preview URL exists, but the preview could not be opened and exercised in the available read-only browser surface.
- Consequently no authenticated Buyer-to-Receiver E2E was run. No claim is made that the supplier-return modal was clicked in a live browser or that the RPC succeeded in a test database.

## 4. Safety and production impact

- No merge to \`main\`.
- No Production Supabase migration or SQL function/policy change.
- No Production Edge Function deployment.
- No Cloudflare Production deployment.
- No purchase invoice, buyer custody event, stock balance, supplier balance, cash custody, treasury, journal or GL record changed.
- PINV-1002 and PINV-1003 remain untouched; their missing handover proof is not inferred.
- The new event is designed as append-only. Any later correction must use the established reversal-event contract; do not delete custody history.

## 5. Remaining release gates

1. Run the complete migration on a schema-compatible isolated PostgreSQL database with the same schema/function dependencies as SMART ERP. Validate function replacement, RLS policies, EXECUTE grants, row locks and event idempotency.
2. Use an authenticated Buyer browser session and the latest Cloudflare Preview to test the modal, evidence upload, API call, realtime update, refresh and Receiver queue.
3. Test the warehouse receive RPC after a supplier return and verify it refuses the returned quantity.
4. Inspect the failed Cloudflare build logs for the separate \`rawaea-store\`, \`warehouse-supervisor\` and \`erp-frontend\` projects.
5. Only after the above checks and the existing §77.2 change approval may the migration, Edge function and application be released to Production.

## 6. Rollback

Current feature branch can be abandoned by closing PR #11; no Production rollback is needed because nothing was released.
If a later approved release is applied:
- Revert Buyer and Edge source to their pre-release commit/version.
- Restore the previous live definitions for the four replaced functions and the prior two Storage policies from the pre-release snapshots.
- Revoke/drop only the new RPC after the application no longer calls it.
- Never delete append-only custody events. Any erroneous committed event must be reversed with a compensating event, not deleted.
- No historical invoice backfill is part of this change.

## 7. Final checkpoint

LVE675 records a completed source ChangeSet and passing CI, not a Production fix. The next operator must resume from PR #11 / head \`72b29072292908dd5e045723169e24734fffe16e\`, complete PostgreSQL runtime validation and authenticated browser E2E, then update this state before any release.
