# RAWAEA ERP — Accountant Control Center Forensic Execution

**Date:** 2026-08-28
**Authority:** Current Production Supabase + Current Git main
**Method:** forensic revalidation; historical reports treated as evidence only

## 1. Governing rule

No historical report, assistant statement, memory artifact, or prior percentage was accepted as Production truth. Current Production and current Git were re-read and reconciled before each material decision.

The governing modification sequence remains:

UNDERSTAND → HISTORICAL CONTRACT → CURRENT BEHAVIOR → DATA/AUTH FLOW → TARGET GAP → SURGICAL CHANGE → VERIFY

This follows the governing principle that study precedes modification and that historical behavior, current behavior, and target architecture must be distinguished before any change. fileciteturn1279file0

## 2. Current Production baseline — fresh revalidation

A fresh Production query was executed after the prior Accountant Control Center work and before this record was updated.

Current core counts:

- PostgreSQL 17.6
- Companies: 1
- Users: 24
- Branches: 2
- Items: 17
- Stock rows: 20
- Inventory log rows: 3
- Stock vouchers: 0
- Treasury rows: 1
- Chart of Accounts: 17
- Journal entries: 2
- Journal lines: 0
- Customer ledger rows: 0
- Supplier ledger rows: 0
- Driver ledger rows: 0
- Orders: 0
- Purchase orders: 0
- Runsheets: 0
- erp_operation_registry rows: 0
- Posted journal headers without lines: 0

A fresh security-advisor inspection currently reports only informational RLS-without-policy findings for `customer_ledger` / `supplier_ledger` and a WARN for leaked-password protection. No anonymous Financial Core execution warning was returned.

## 3. Historical assistant assessment

### Khalid

The historical 87-account recovery stop was methodologically correct. Source exhaustion was correctly distinguished from successful recovery of 87 authoritative rows. The later creation of 16/17 current COA accounts was treated as New Financial Master Data, not as historical reconstruction. fileciteturn1327file0 fileciteturn1329file0

The later financial convergence work was valuable and uncovered real Production defects, but its historical closure claims were not treated as current certification without re-reading Production. His report explicitly left runtime, concurrency, consumer, lineage, and security gates open. fileciteturn1335file0

### Hytham

The core architectural finding remains correct: `post_stock_movement` is the Physical Stock writer contract; `reserve_stock` and `release_stock_reservation` are reservation engines, not physical movement engines. Hytham also correctly distinguished SQL/Core evidence from authenticated HTTP and browser concurrency proof. fileciteturn1333file0 fileciteturn1336file0

## 4. What became stale vs what remained valid

`save-transfer-voucher` was previously described as open in older material, but current Production v4 is an adapter to `post_treasury_transfer_atomic`; no direct `cash_box` / `journal_entries` / `journal_lines` / `treasury` mutation was found in the deployed Edge source. The current Core is SECURITY DEFINER, company-scoped, operation-id based, and performs the treasury transfer atomically.

Therefore the old `save-transfer-voucher OPEN` classification is historical and must not be carried forward as a current defect. The same principle applies to any prior snapshot whose Production version has since advanced. fileciteturn1337file0

## 5. Fresh inventory Writer forensic sweep

The current Production PostgreSQL scan for definitions containing actual writes to `stock_branches` returns:

- `post_stock_movement`
- `post_inventory_adjustment_atomic`
- `reserve_stock`
- `release_stock_reservation`
- `setup_van_stock`

The current definitions confirm that `post_inventory_adjustment_atomic` delegates the physical change to `post_stock_movement`, while `reserve_stock` / `release_stock_reservation` operate on reservation state. `setup_van_stock` is initialization rather than a transaction movement engine.

A second, stricter scan for actual `INSERT/UPDATE/DELETE` statements against `inventory_log` returns **only `post_stock_movement`**. A prior broader text scan produced false positives because some functions contained the field name `inventory_log_written` in their JSON response. That false positive has been explicitly corrected and is not being carried into the final matrix.

This is important: the current Production evidence still supports the intended Physical Stock contract:

Physical Movement → `post_stock_movement` → `stock_branches` + `inventory_log`

## 6. Accountant PWA current-state review

`Current/PWA/accountant.html` is a substantial Accountant Control Center consumer, not the earlier 69-line regression. The current source contains authenticated context loading, multi-tab accounting/operations views, reporting, aging, inventory control, G/L, reconciliation, audit feed, period readiness, and operation-aware cash receipt/payment flows.

No direct Financial or Physical Stock DML was found in the Accountant PWA itself; business writes are routed through Edge/Core contracts.

The current PWA calls the following read surfaces, among others:

- `accountant_reconciliation_summary`
- `accountant_period_readiness`
- `accountant_exception_center`
- `accountant_runsheet_center`
- `accountant_order_center`
- `accountant_customer_aging`
- `accountant_supplier_aging`
- `accountant_inventory_control`
- `accountant_coa_tree`
- `accountant_audit_feed`
- `get_trial_balance`
- `get_profit_loss`
- `get_balance_sheet`
- `get_cash_flow`
- `get_pnl_by_cost_center`

Production signatures were re-queried directly and match the argument forms used by the read-only certification harness.

## 7. New defect found and fixed — multi-treasury contract drift

The Accountant PWA already models treasury selection and sends a selected `treasuryId`. However, Production `save-receipt-voucher` and `save-payment-voucher` previously required the company to have exactly one active treasury.

That was a real forward-compatibility defect: a valid multi-treasury company would be rejected despite the PWA exposing explicit treasury selection.

### Surgical fix

The deployed adapters were updated to:

- derive `company_id` from `public.users.auth_id`;
- require an explicit `treasuryId`;
- validate `treasury.id + company_id + is_active`;
- preserve explicit `cashAccountId` and `offsetAccountId`;
- delegate posting only to `post_cash_receipt_atomic` / `post_cash_payment_atomic`.

Production Edge versions are now:

- `save-receipt-voucher` v7
- `save-payment-voucher` v5

The same source changes were written to `Current/Edge_Functions/...` in Git.

Git commits:

- receipt adapter repair: `9e228be91c08adb39c9c7da9e24ee12a41c764f9`
- payment adapter repair: `380861dd1411195b097dad61081af62e825b4d77`

This change does not alter the accounting Core contract; it removes an incorrect adapter-side assumption.

## 8. Manual Voucher CREATE contract review

The current `create-stock-voucher` Edge consumer was re-read in Git and shown to derive company context from `users.auth_id`. The Production schema also proves `items.item_code` is globally UNIQUE, while `stock_branches` is keyed by `(branch_id,item_id)` and stock branch membership is branch/company scoped.

The canonical `create_manual_stock_voucher_atomic` Production function is company-scoped and validates the supplied branch IDs and the globally unique Item identity before creating the Draft voucher.

A transactional Production test using an Item whose metadata belongs to a different historical company context demonstrated the important contract distinction: the Item identity is global, while the stock location is company-owned. The test was rolled back and produced no persistent business residue.

## 9. Purchase Receiving — current contract

Production `receive_purchase_atomic` was re-read directly. It now uses a deterministic receiving operation identity stored in the existing UNIQUE `receiving.operation_id` field rather than inventing a new table-level identity column.

Its contract is:

Company → PO → receiving branch → PO detail → global Item identity → `post_stock_movement` → receiving details → accounting.

A key historical defect around receiving/journal result typing was already repaired in Production by the previous execution; current runtime source must still be certified through the live E2E harness before that path can be called browser-certified.

## 10. Financial Edge status currently verified

Current Production Edge inventory confirms:

- `save-sales-invoice` v15 — active
- `receive-purchase` v12 — active
- `save-journal-entry` v8 — active
- `save-receipt-voucher` v7 — active
- `save-payment-voucher` v5 — active
- `save-transfer-voucher` v4 — active
- `save-daily-settlement` v4 — active
- `update-driver-ledger` v2 — active

The current source of `save-transfer-voucher` delegates to `post_treasury_transfer_atomic`, and `save-daily-settlement` delegates to `post_daily_settlement_atomic`. The current `save-journal-entry` adapter resolves company and account UUIDs and delegates posting to `post_journal_entry`.

## 11. Read-model correctness checks

Production `chart_of_accounts.account_type` values are currently lowercase and distributed as:

- asset: 7
- liability: 4
- equity: 2
- revenue: 2
- expense: 2

Therefore the current reporting query casing is consistent with current Production data and is not a casing defect.

Production signatures for the accountant read models were re-read directly; the live certification harness uses the exact current signatures.

## 12. Persistent period close

Production still has no verified persistent accounting-period/lock contract. `accountant_period_readiness` remains a readiness model, not a period-close engine.

No period-close write contract is being invented during forensic repair. This remains a design/architecture decision, not a defect that can be silently “fixed” without an explicit contract.

## 13. Live Certification Harness added to Current

A new **read-only** file was added:

`Current/PWA/accountant-live-certification.html`

Its purpose is controlled browser/runtime proof after the user manually publishes the `Current` folder.

It performs:

1. authenticated session verification;
2. `users.auth_id → company_id` verification;
3. active Treasury and COA read checks;
4. all current Accountant read-model calls;
5. direct browser attempts to execute protected Financial/Stock Core RPCs, which must be rejected;
6. authenticated HTTP calls to receipt/payment/transfer adapters with intentionally invalid payloads, proving the HTTP route/authentication/validation boundary without performing a business mutation.

It explicitly does **not** perform a successful receipt/payment/transfer, so it leaves Production financially untouched.

This distinction is intentional: a safe read-only browser harness can prove session, routing, read models, authentication and negative protection; it cannot honestly certify a successful financial mutation or two-user race without a controlled business transaction.

## 14. Current hard gates that remain

### Not yet 100% certified

1. **Authenticated Browser E2E for successful business mutations** — requires a real authenticated browser session against the manually published Current URL.
2. **True two-session concurrency** — requires two authenticated sessions executing the same operation identity or competing operations during a controlled test.
3. **Full Edge Source ↔ Production deployment lineage** — current deployed versions are known; complete byte/hash mapping for every relevant Edge function remains a separate certification task.
4. **Van Sales / Returns / Loading / Unloading live business-path certification** — SQL/Core evidence exists for key paths, but browser-level success traces are not yet certified.
5. **Financial RLS policy design** — current security advisor still reports RLS-without-policy informational findings for customer/supplier ledgers; the correct tenant policy contract must be designed rather than guessed.
6. **Persistent period close** — no Production contract exists.

These are not being converted into false “100%” status merely because the underlying SQL Cores exist.

## 15. Live test procedure after manual publishing

After the owner publishes `Current` manually, the safest certification sequence is:

### Stage A — Static release gate

Verify the deployed `accountant.html`, `core.js`, and the added `accountant-live-certification.html` are the exact Current files approved in Git.

### Stage B — Browser session

Open the published Accountant PWA, sign in normally, and confirm the dashboard loads without authentication or company-context errors.

Open `accountant-live-certification.html` in the same authenticated browser profile and click **تشغيل الشهادة الحية**.

Expected mandatory results:

- SESSION = PASS
- COMPANY_CONTEXT = PASS
- TREASURY_READ = PASS
- COA_READ = PASS
- every Accountant READ_RPC = PASS
- every protected WRITE_SURFACE = PASS because the browser call is rejected
- every HTTP_VALIDATION adapter check = PASS with 4xx validation response

### Stage C — Functional read walkthrough

In `accountant.html`, manually open:

Dashboard → Receipts → Payments → Journals → Reports → Operations → Partners → Inventory → G/L → Reconciliation → Audit.

Check that every tab loads data or an explicit legitimate empty state, and that no tab creates console exceptions that block navigation.

### Stage D — Controlled successful business transaction

This stage cannot be safely faked with a read-only harness.

Use either:

- a dedicated test tenant/treasury/account environment; or
- a maintenance-window transaction explicitly approved for live Production testing, followed by a documented compensating transaction.

For the selected operation:

1. capture Treasury balance / GL balance / operation registry count;
2. submit once;
3. verify one business effect;
4. submit the exact same operation ID again;
5. verify `duplicate=true` and no second business effect;
6. compare Stock/GL/Treasury/Registry/Audit counts;
7. document the complete HTTP → Edge → Core → DB → Audit trace.

### Stage E — Two-session concurrency

Use two authenticated browser sessions with different authorized users.

Submit the same operation identity concurrently. Expected behavior is exactly one committed operation and one duplicate/conflict result, with no doubled Treasury/GL effect and no inconsistent registry state.

This must be performed only in a controlled environment because it intentionally exercises a real write race.

### Stage F — Final evidence package

Record:

- published URL
- publication timestamp
- Git release commit
- Production Edge versions
- browser certification output
- successful mutation operation IDs
- duplicate retry result
- two-session race result
- before/after financial balances
- audit evidence
- unresolved gates

Only after this package exists can the browser/runtime portion be marked certified.

## 16. Final forensic verdict

### Proven now

- Current Accountant PWA is a substantial Control Center consumer, not the old 69-line regression.
- Physical Stock direct-writer scan supports one physical movement core: `post_stock_movement`.
- Direct `inventory_log` writing is confined to `post_stock_movement`.
- `save-transfer-voucher` is currently a canonical adapter in Production, not an open direct writer.
- `save-receipt-voucher` and `save-payment-voucher` are now multi-treasury-compatible adapters in Production v7/v5.
- Current accountant read-model signatures match the read-only certification harness.
- Current account-type casing matches the report SQL.
- Posted zero-line journal headers currently equal 0.
- Current operation registry rows equal 0 at the fresh snapshot.

### Still not certified 100%

- browser successful-write E2E
- true two-session concurrency
- complete deployment-lineage certification
- full live business-path certification across all fulfillment flows
- final financial RLS policy certification
- persistent period-close architecture

Therefore the current evidence-backed status remains:

`ACCOUNTANT CONTROL CENTER CORE INTEGRITY = CLOSED`

`ACCOUNTANT CONTROL CENTER PRODUCTION CERTIFICATION = NOT 100% CERTIFIED`

No higher percentage is authorized without the missing runtime evidence.

## 17. Self-audit

**What was re-proven directly:** Production baseline, Edge versions, Financial/Inventory core boundaries, accountant read-model signatures, current COA type values, transfer adapter convergence, selected-treasury contract, and direct inventory-log writer scan.

**What was corrected during this round:** multi-treasury adapter mismatch; false-positive interpretation of `inventory_log` writer scan.

**What remains an explicit evidence gap:** authenticated successful browser mutations and two-session race proof.

**What was not invented:** Treasury→COA mapping, persistent period close, historical 87-row recovery, or browser success claims.
