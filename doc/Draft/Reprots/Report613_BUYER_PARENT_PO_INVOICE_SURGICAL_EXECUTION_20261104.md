# Report613 — Buyer / Parent PO & Invoice Surgical Execution and Transactional QA

**Date:** 2026-11-04  
**Starting point:** LVE-2026-11-04-612 / Report612; Buyer workstream begins from LVE611/Report611 and Report610 Change Set 610.  
**Operational repository:** papamohammed77-glitch/erp-frontend / main  
**Production:** SMART ERP / fiilmooggumokxanwiyx  
**Status:** PARENT SOURCE PATCH COMMITTED / PRODUCTION RPC DRAFT TESTS PASSED WITH ROLLBACK / AUTHENTICATED BROWSER E2E OPEN / CANONICAL DEPLOYMENT NOT VERIFIED.

---

## 1. Starting state and source fingerprints

- Operational HEAD immediately before this execution: `68d222b20251049daddc2f159f2b8c80cd6ffb89`.
- Parent `companies/company-1/main.html` before patch: blob `53b5a9e9d0433a785c3d5471a9c0d68c25497882`.
- Buyer `companies/company-1/purchasing/buyer.html`: blob `311f2673a90149df6f56d59a9a187a3379e6981c`.
- Core `companies/company-1/core.js`: blob `f4c6a0df441e0da9105d4fe7ce94ad2d7a1735e1`.
- Existing Buyer commits already present before this execution:
  - `07ea8bb6175c3ae7db2cfd5d9754f88f7ab7e976`: Buyer PO/Invoice register enhancement and camera barcode scanning.
  - `68d222b20251049daddc2f159f2b8c80cd6ffb89`: await BarcodeDetector supported formats.
- These Buyer changes were not authored again or duplicated in this execution.
- Our Parent source commit: `3f4d48b6acfc5c5e70d2d6a09278a4bc3fd5d954`.
- Parent blob after patch: `f6ec4ab41dc517f86e17dd3d74a9d5f8add264ca`.
- Operational main later advanced one commit to `e8ab54c75572e15e71581212479d22be139c8020`, adding only `_forensic_current_main_extract.md`; comparison shows our Parent commit remains its direct ancestor and no later source change superseded it.

## 2. Parent surgical source changes actually committed

Only the targeted purchase-cycle code fragments in `main.html` changed; no whole-file rewrite, no unrelated application edits, no new branch, and no new Edge Function.

### 2.1 Parent PO list

- Added company-filtered lookup maps for suppliers and branches using existing `getData`.
- Added a bounded `purchase_order_details` lookup restricted to the already company-scoped PO IDs, selecting `po_id, qty_ordered, qty_received`.
- Added supplier name, branch, creator email, PO date, expected delivery date, per-document currency, and recorded ordered/received quantities.
- Kept the existing `RW_Purchases._openPO` detail action and existing PO business writer.
- Quantity progress is explicitly labelled as recorded quantities; it is not presented as independent proof of a warehouse Receiving document.

### 2.2 Parent invoices list

- Added company-scoped supplier, branch, and PO lookup maps.
- Replaced the raw supplier UUID display with supplier name.
- Added invoice date, linked PO code, branch, `created_by`, due date, stored currency, paid amount, and remaining amount.
- Preserved the existing Draft-only post action and existing central posting path.
- Each document is displayed using its stored currency; historic SAR documents are not converted to EGP.

### 2.3 Parent purchase Realtime

- Added `purchase_orders` to the existing company-filtered `purchase-gold-live-` channel.
- Reused the current channel and refresh callback; no second channel or new Realtime infrastructure was created.
- Live event-to-UI behavior remains unverified in a signed-in browser session.

### 2.4 Currency source

- Parent Purchase Settings now reads `app_settings.currency` and displays it read-only.
- Removed `default_currency` from this screen's `SAVE_SETTINGS` payload, so this UI no longer writes a competing currency.
- The database column `purchase_settings.default_currency` was not dropped or modified; no global consumer-removal migration was attempted.
- Current Production values were rechecked: `app_settings.currency=EGP`, `purchase_settings.default_currency=EGP`.

## 3. Buyer source state and outstanding Buyer correction

The current Buyer source already contains the Report610 UX scope: creator/branch/date/status/receipt filters, stored currency display, PO linkage, PO progress, camera scan controls, and a BarcodeDetector lifecycle helper. This execution did not duplicate that work.

**Important remaining integrity gap from Report611:** Buyer `receiptState(invoice)` still treats `is_received`, `received_date`, or detail received quantities as sufficient to label an invoice «مستلم بالكامل». Production currently contains a QA Draft invoice with `is_received=true` and received quantities but no Receiving header/detail. Whether physical delivery occurred is unknown. The flag/quantity alone must not be represented as approved Receiving evidence.

A narrowly targeted Buyer label correction was prepared but the GitHub write was rejected by the connector's security checks; no Buyer content change resulted. Therefore the receipt-evidence wording remains OPEN and must be corrected before calling the Buyer screen fully trustworthy. Do not alter the historical QA document without a separate reconciliation decision.

## 4. Production read-only baseline

Live SMART ERP checks during this execution:

- System currency: EGP.
- Purchase Settings currency: EGP.
- Purchase Orders: 1.
- Purchase Invoices: 3.
- Active item catalogue: 30.
- No schema, migration, RLS, grants, RPC definition, Edge Function, stock, supplier balance, treasury, or journal data was changed.

The existing Production QA/legacy documents were preserved. No currency conversion was applied.

## 5. Transactional Production RPC tests — PASS

Following the established Report323 pattern, draft-only test documents were created inside explicit PostgreSQL transactions and the transactions were rolled back.

### Test A — PO draft creation

- Set transaction-local JWT claim context to the existing Buyer test-role account `buyer1@rawaea.com` / auth user `b0894a25-6a0a-484a-a730-4f64c88e23a4`.
- Called existing `purchase_create_po_atomic` with an existing active supplier and existing item `1001`; no new supplier, branch, item, or account was created.
- RPC returned `success=true`, `status=Draft`, `currency=EGP`, `total_amount=1`.
- Transaction ended with explicit `ROLLBACK`.

### Test B — PO + linked Invoice draft

Within one transaction:
1. Called `purchase_create_po_atomic`.
2. Used the returned PO ID to call existing `purchase_create_invoice_atomic_v2`.
3. Invoice RPC returned `success=true`, `status=Draft`, `currency=EGP`, `total_amount=1`, and retained the QA supplier invoice reference.
4. Compared before/after snapshots inside the transaction:
   - `inventory_log`: unchanged.
   - `supplier_ledger`: unchanged.
   - `journal_entries`: unchanged.
   - `stock_branches`: unchanged.
5. Explicitly rolled back the complete transaction.

### Cleanup verification

After rollback:
- The test PO row count for the returned PO ID: 0.
- The test Invoice row count for the returned Invoice ID: 0.
- Production totals remained exactly PO=1 and Invoice=3.

A second isolated PO rollback probe also returned a successful Draft EGP PO result and was rolled back. No persistent QA rows or operational balances were left by these probes.

**Scope of this evidence:** real Production PostgreSQL RPC execution in transaction-local claim context. This is not a signed Edge Function request, not a browser session, and not an end-to-end UI/Realtime test. No posted invoice, Receiving document, stock movement, AP entry, journal entry, or treasury event was created.

## 6. Source/build/deployment verification

For commit `3f4d48b6acfc5c5e70d2d6a09278a4bc3fd5d954`:

- `forensic-main-html`: completed / success.
- `verify-canonical-mother-source`: completed / success.
- `inventory-forensic`, `helper-forensic`, and `extract`: completed / success.
- `browser-e2e`: completed / failure.
- Cloudflare Pages `rawaea-erp`: still `in_progress` at last check; no successful deploy result or canonical served-artifact parity is claimed.
- Cloudflare Pages `warehouse-supervisor`, `rawaea-store`, and `erp-frontend`: failed on this commit. LVE611 had already recorded these project failures on the previous HEAD; logs/root cause and their impact remain unverified.
- Current connected browser tab shows the Parent shell with the login form visible. No authenticated Buyer/Parent browser interaction was performed.
- Camera permission, BarcodeDetector hardware behavior, Buyer-to-Parent Realtime refresh, and the actual served artifact hash remain UNVERIFIED.

## 7. Staging and test-data policy

- Existing `rawaea-staging` remains at 62 migrations and lacks Buyer invoice/custody schema; it is not a valid full Buyer E2E environment.
- No paid Supabase branch or new project was created.
- No permanent QA data was left in Production. All database test rows were transaction-scoped and rolled back immediately; post-rollback queries verified absence.
- Do not replace rollback-based tests with expiring persistent records in Production. If a future workflow truly needs persistent QA fixtures, it must use a dedicated QA namespace/run marker plus a database-enforced expiry/cleanup process and must prove that no inventory/finance writer can consume those fixtures.

## 8. Remaining blockers / exact next execution

1. Correct Buyer receipt wording and logic so invoice flags/quantities do not imply approved Receiving evidence without a real linked Receiving record.
2. Reconcile the known QA Draft PO/Invoice inconsistency; do not change those records without field/owner reconciliation.
3. Obtain an authenticated browser session and complete Buyer + Parent UI E2E: create PO, confirm creator/currency, verify Parent Realtime, create linked invoice Draft, verify supplier/PO/branch/creator/currency/remaining balance, edit/delete guards, and confirm no stock/AP/GL/Treasury effect.
4. Test camera on a physical phone, supported browser formats, permission denied, close/reopen cleanup, duplicate/unmatched barcode, and USB HID/manual fallback.
5. Verify Cloudflare `rawaea-erp` deployment completes and compare the served Buyer/Parent artifact with Git blobs.
6. Pagination remains open: Parent reads 300 rows; Buyer/Edge cap is 500. This execution did not change GET_DATA contract or add new Edge Functions.
7. Staging schema parity remains open; do not declare complete full-cycle E2E until that environment is repaired or a separately governed safe approach is proven.

**Final status:** Parent PO/Invoice list and currency-source source changes COMMITTED. Production draft PO+Invoice RPC test PASS with explicit rollback and unchanged inventory/AP/GL snapshots. Buyer receipt-evidence semantics OPEN. Authenticated browser E2E, physical camera test, Realtime runtime test, pagination, and canonical deployment parity OPEN. Buyer/Parent purchasing cycle is NOT YET CLOSED / NOT YET DECLARED PRODUCTION-READY.
