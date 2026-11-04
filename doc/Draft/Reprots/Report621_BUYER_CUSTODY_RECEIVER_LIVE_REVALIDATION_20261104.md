# RAWAEA ERP — Report621
# Buyer / Receiver / Supplier Return — Live Revalidation and Controlled Execution Gate

**Date:** 2026-11-04  
**Checkpoint:** LVE-2026-11-04-621  
**Status:** READ-ONLY REVALIDATION COMPLETE / CHANGESET PREPARATION OPEN / NOT CLOSED  
**Scope:** Buyer purchasing, Receiver, SupplierReturn, buyer goods custody, cash-custody settlement, related Production schema/RPC/Edge contracts.  
**No operational code or Production data was changed in this checkpoint.**

---

## 1. Governance, starting point, and evidence integrity

### 1.1 Required protocol read

- `doc/Draft/Reprots/Report614_NEW_P.md`
  - Blob SHA: `5ae52df7d302574266fb9368ddd6d02e62b14306`
  - 1,438 lines / 35,613 characters.
  - Retrieved in consecutive ranges 1–300, 301–600, 601–900, 901–1200, and 1201–1438. All ranges returned the same blob SHA; the final range reached the end of the file.
  - Read in full. The controlling sequence, source-verification requirements, evidence classifications, business-effect safeguards, owner approval gate, surgical-change requirements, testing, reporting, and closure rules were applied.

- `doc/Draft/Reprots/الدستور التشغيلي الدائم.md`
  - Blob SHA: `d2afa896514b1cb6abd247d2af7a862251ce0604`
  - 293 lines / 16,785 characters.
  - Retrieved as the live repository version and read before operational-source inspection.

- `CURRENT_STATE.md`
  - Blob SHA at checkpoint start: `82e6116d9f642eb0207c5812ef813f6392747a16`
  - 5,682 lines / 808,334 characters.
  - Base file still contains the 2026-11-03 Buyer checkpoint; subsequent LVE618/LVE619/LVE620 supplements were read and reconciled. The effective continuation point is LVE620, not the older base-file Buyer note.

### 1.2 Latest source and deployment lineage

- Operational repository: `papamohammed77-glitch/erp-frontend`, branch `main`.
- Current branch HEAD: `e8ab54c75572e15e71581212479d22be139c8020` — `forensic: persist current Mother HR extract`.
- Cloudflare Pages dashboard currently lists Production / main at the same commit `e8ab54c`, deployment alias `https://4a838965.rawaea-erp.pages.dev`, approximately three hours before inspection.
- The dashboard text did not expose a definitive success status for that row. The alias's Buyer asset could not be fetched through the available web reader. Therefore **deployed Buyer byte-for-byte parity is UNVERIFIED**, despite the dashboard's matching commit lineage.
- The currently open parent application tab renders the login overlay. No authenticated session was available for Buyer/Receiver UI E2E. No login, navigation, click, write, or test transaction was performed.
- The branch is not protected according to GitHub branch metadata. No branch, PR, or operational commit was created.

### 1.3 Current source blobs inspected

| File | Current blob SHA | Finding |
|---|---|---|
| `companies/company-1/purchasing/buyer.html` | `311f2673a90149df6f56d59a9a187a3379e6981c` | Buyer source inspected; see §3 |
| `companies/company-1/warehouse/receiver.html` | `3111b5e801d1bc021cf18fd66d633fbdc54ac0d6` | Receiver defects confirmed; see §4 |
| `companies/company-1/warehouse/vouchers.html` | `85e709d0f41c189c6624a6160965d3b1a41960ba` | SupplierReturn UI/currency path inspected; see §5 |

### 1.4 Current deployed Edge Functions

The live Supabase project `fiilmooggumokxanwiyx` was queried read-only. Current active versions and hashes:

| Existing function | Version | verify_jwt | SHA-256 |
|---|---:|---:|---|
| `save-purchase-order` | 22 | true | `a0885a8a636b0d57ef9ab54b476001be8e3dd1f4227b921f511b002f58642ffb` |
| `receive-purchase` | 13 | true | `50ab45ae026a0bb4d1de7837c872c4cc42da47b6a603f340e48d023d839310cc` |
| `create-stock-voucher` | 12 | false | `c4ee58c5c94538bcb02a2a76c247996fa9368be7c5b2f7b4d44c98336d29ea4d` |
| `send-stock-voucher` | 20 | true | `864129274b4a23d74b3378c44d8fbf8f2a269eb76d9b623350ad57c818c8805b` |
| `receive-stock-voucher` | 22 | true | `62f6e97936997ab0ab58379bb683a08431eb2a5c96d1063943e5a3e03d24bf29` |
| `complete-stock-voucher` | 4 | true | `8cf684456cd82f4f331c909ad4adf5afaf1ad46ffa34d9927fded06276fed855` |

No new Edge Function is justified. The existing functions are the extension points. `create-stock-voucher` has `verify_jwt=false`, but its source performs manual caller authentication/profile checks; any change must preserve and test those checks rather than treating the flag alone as proof of an unauthenticated path.

---

## 2. Production database — fresh read-only findings

### 2.1 Currency and live row counts

- `public.app_settings.currency = 'EGP'` for the active company. This confirms the parent system's configured currency.
- `public.stock_vouchers.return_currency` has a database default of `'SAR'`.
- Current row counts:
  - `purchase_returns`: 0
  - `purchase_return_details`: 0
  - `stock_vouchers` with `type='SupplierReturn'`: 0
  - `buyer_custodies`: 0
  - `buyer_custody_expenses`: 0
  - `receiving`: 0
  - `receiving_details`: 0
  - `purchase_invoices`: 3

The zero counts mean there is no live Buyer goods-custody ledger or supplier-return transaction history to reconcile yet. They do not prove the workflow is complete.

### 2.2 Existing purchase invoices — preserve history

| Invoice | Status | Currency | PO link | Amount | Receipt flag / received quantity | Verified effects |
|---|---|---|---|---:|---|---|
| PINV-1000 | Posted | SAR | none | 2,640 | true / 30 | 3 PurchaseIn inventory rows, supplier-ledger credit 2,640, Posted PurchaseInvoice journal |
| PINV-1001 | Posted | SAR | none | 1,330 | true / 20 | 2 PurchaseIn inventory rows, supplier-ledger credit 1,330, Posted PurchaseInvoice journal |
| QA-SR-INV-20260927 | Draft | SAR | linked PO | 375 | true / 5 | No matching inventory_log row, supplier-ledger row, or journal entry found |

**Control decision:** do not bulk-convert the two Posted SAR invoices to EGP. They have historical stock and accounting effects and must remain unchanged. The QA-labelled Draft row has inconsistent-looking receipt flags but no stock/AP/GL posting was found. Do not silently mark it received, post it, delete it, or treat it as a valid live receipt. It remains a historical QA residue requiring explicit source reconciliation and safe disposition.

### 2.3 Supplier return schema and direct-write exposure

- `purchase_returns.purchase_invoice_id` is currently NOT NULL and has an FK to `purchase_invoices`.
- `purchase_returns.status` CHECK is limited to `Draft`, `Posted`, `Cancelled`.
- `purchase_returns` has no `stock_voucher_id` column; the two return-document paths are not joined by a single source identifier.
- RLS policies are company-scoped, but `anon` and `authenticated` currently have direct INSERT/UPDATE/DELETE table grants on both `purchase_returns` and `purchase_return_details`. The authenticated path can therefore reach table DML subject to RLS, bypassing the intended single-writer business contract.
- The safe target is SELECT-only browser access with mutations exclusively through the authorized central SECURITY DEFINER writer(s). Do not broadly revoke unrelated grants or alter unrelated tables.

### 2.4 Existing reviewed schema scaffold

`Current/CTO/ChangeSets/20261104/02_buyer_goods_custody_schema_security_REVIEWED_DRAFT.sql` was read. It is a 710-line reviewed schema/security scaffold, not a deployable migration. It explicitly states that it contains no replacement business RPCs, trigger bodies, Edge changes, or application changes; it also preserves historical values and defers relaxing `purchase_returns.purchase_invoice_id NOT NULL` and changing existing status CHECKs until consumer scans and reconciliation are complete.

**It was not executed.** Its own companion-contract list remains open. Do not run this file as-is.

---

## 3. Buyer application — current capability versus real closure

### 3.1 Existing tabs and current behavior

The current Buyer source contains the tabs:
- اليوم
- الموردون
- طلبات PR
- عروض أسعار
- أوامر PO
- فواتيري
- عهدتي
- رصيدي
- حسابي

The source reads the parent system currency through `GET_SETTINGS` and validates the three-letter code. This part is aligned with the parent currency source when the setting exists.

### 3.2 Confirmed gaps

1. **رصيدي is still a placeholder, not a ledger.** `renderVehicleBalance()` explicitly reports that the central goods-custody ledger does not exist. The new `buyer_goods_custody_events` table is absent from Production and its row count is zero. Do not substitute the delivery-fleet stock balance for the Buyer's physical custody.
2. **Quick Purchase is not a separate workflow.** `quickPurchase()` only delegates to `createPurchaseInvoice()`. It does not establish a distinct `QUICK_MARKET` source, a supplier-to-Buyer handover, a Buyer-held goods event, or a direct-invoice Receiver path.
3. **Quick search exposes `items.cost_price`.** It visibly renders “آخر تكلفة مرجعية”. The requested market workflow requires manually entered actual purchase price; last cost may be used as an internal advisory only and should not be displayed as if it were the purchase price.
4. **Cash-custody review is PO-centric.** The live `buyer_custody_review_expense_atomic` requires a Draft invoice linked to a valid PO and a matching completed PO receiving record. It checks PO line price/quantity and supplier liability before posting payment from employee custody. It has no explicit `QUICK_MARKET` branch for a no-PO supplier invoice and invoice-ID warehouse receipt.
5. **Cash custody and goods custody must remain separate ledgers.** Cash advances/expenses/settlements must not be used to infer physical goods possession. Goods custody must not post treasury cash or supplier AP by itself.
6. **No authenticated end-to-end test has been performed.** Static source and database evidence do not prove the Buyer tabs work in the deployed authenticated UI.

### 3.3 Required Quick Market contract

A real quick-market purchase must:
- select an active approved supplier from the parent supplier master; cash supplier is still an approved supplier, not free text;
- require supplier invoice/reference, item identity, manually entered actual unit price, quantity, and the parent-system currency;
- create a Draft invoice explicitly classified `purchase_source='QUICK_MARKET'` and `settlement_source='EMPLOYEE_CUSTODY'` when funded from the Buyer's cash custody;
- not require a PO, but must link the Buyer, cash custody, supplier, invoice, and actual receiving operation;
- record supplier → Buyer physical handover in the append-only goods-custody ledger;
- expose the invoice by invoice code/number in Receiver;
- transfer only accepted warehouse quantities from Buyer custody to warehouse stock;
- settle the expense only against the matching invoice and actual warehouse receipt, preserving the existing PO cash-settlement path;
- avoid creating a net supplier payable when the supplier has already been paid from the employee advance. If the accounting model posts AP first, the later custody-funded payment must clear that AP exactly once, with no duplicate treasury outflow.

---

## 4. Receiver — confirmed defects and exact surgical direction

### 4.1 Confirmed source/schema mismatch

Current `receiver.html`:
- loads only `purchase_orders` in Sent / Partially Received states;
- loads details using `purchase_order_details.select(...).eq('po_code', code)`;
- the live `purchase_order_details` schema has `po_id`, `qty_ordered`, and `qty_received`, but **does not have `po_code`**.

Therefore the details lookup uses a nonexistent column and cannot correctly resolve the PO lines. This is a confirmed contract defect, not a styling issue.

### 4.2 Additional receiving defects

- The line projection does not include `qty_received`, so the UI's `max` uses the original ordered quantity rather than the current remaining quantity.
- `submitReceiving()` uses `parseInt()`, which truncates legitimate fractional quantities.
- It sends every rendered line, including zero quantities.
- The UI sends no explicit operation ID.
- The Edge fallback derives the operation ID deterministically from user + company + identical PO/items payload. A later, legitimate second partial receipt with the same quantities can therefore reuse the previous operation ID and be mistaken for a retry.
- The live 5-argument `receive_purchase_atomic` skips every line with `received_qty <= 0` but does not reject an all-zero submission before inserting the `receiving` header. This can create an empty completed receiving header with no item movements.
- Receiver has no invoice-number / direct-market-invoice search path.

### 4.3 Required surgical patch

1. Resolve the PO header by company-scoped `po_code` first; use the returned PO UUID to load lines by `po_id`.
2. Select `id, item_id, item_code, item_name, unit, qty_ordered, qty_received` (plus only fields required by the UI). Compute remaining quantity from ordered minus already received.
3. Render remaining quantity, not original ordered quantity, as the receiving ceiling. Do not allow over-receipt unless a separately authorized and reason-coded overage contract is explicitly approved.
4. Parse with `Number()` / `parseFloat()`, validate finite non-negative quantities and decimal precision, filter zero lines, and reject the submission if the accepted total is zero.
5. Generate one fresh operation UUID per new submission, retain it across retries of that same submission, and generate a new UUID for a distinct receipt event.
6. Add invoice-code search and the approved invoice-ID receiving branch for `QUICK_MARKET`, without breaking the existing PO branch or its role/branch authorization.
7. Add a server-side all-zero guard before creating the receiving header. The server must remain authoritative; UI validation alone is insufficient.
8. Keep stock increase tied only to the warehouse's accepted quantity. A Draft invoice, a supplier handover, or an unaccepted quantity must not increase warehouse stock.

No Buyer/Receiver source was changed in this checkpoint.

---

## 5. SupplierReturn — current dual-path risk and required custody/acceptance lifecycle

### 5.1 Confirmed current behavior

- The current SupplierReturn UI hydrates currency with `h.return_currency || 'SAR'`.
- The live `stock_vouchers.return_currency` column also defaults to `SAR`.
- The live `save_supplier_return_contract` RPC falls back to `'SAR'` when the payload and linked invoice currency are empty.
- The same RPC may fall back from the voucher line price to `items.cost_price`. A generic current cost is not a safe substitute for the original invoice/PO valuation or a documented approved return valuation.
- The trigger `enforce_stock_voucher_custodian()` clears `custodian_user_id` for every voucher type except `DirectSale` and `DirectReturn`. It currently cannot preserve a Buyer as the custodian of a SupplierReturn dispatch.
- `send_stock_voucher_atomic` posts the SupplierReturn stock movement and marks the voucher Sent. It does not atomically create a Buyer goods-custody event.
- `complete_manual_stock_voucher_atomic_core_20260828` requires the SupplierReturn contract, calculates totals from all voucher detail lines, and posts the full `return_total_amount` to supplier ledger and journal when the voucher is completed. There is no supplier-acceptance quantity ledger in that posting path.
- Separately, `purchase_post_return_atomic` loops through `purchase_return_details`, calls `post_stock_movement(...,'SupplierReturn',...)`, and posts supplier ledger/journal. This is another stock/financial writer.
- `purchase_returns` and `stock_vouchers` have no live source-link field joining those two return paths. Both currently have zero SupplierReturn rows, so no existing row is to be rewritten, but the dual-writer architecture must be resolved before enabling both paths.

### 5.2 Required target lifecycle

**Warehouse → Buyer (delegate mode):**
- authorized warehouse user creates SupplierReturn draft;
- explicit recipient mode = `BUYER_DELEGATE`, with same-company active Buyer user selected;
- dispatch posts the physical stock decrease once and, in the same transaction, appends Buyer custody IN events per item/quantity;
- vehicle is optional metadata, not the identity of the custodian.

**Warehouse → Supplier (direct mode):**
- explicit recipient mode = `SUPPLIER_DIRECT`;
- stock decreases on dispatch once;
- no Buyer custody event is created;
- supplier acceptance is still required before reducing supplier liability.

**Buyer → Supplier / supplier acceptance:**
- Buyer records actual handover evidence and quantities;
- supplier acceptance is recorded per item and may be partial;
- accepted quantities alone trigger supplier ledger/AP credit, GL and tax reversal, idempotently;
- rejected/unaccepted quantities remain in Buyer custody or follow an explicit return-to-Buyer/warehouse disposition; they must not silently disappear or reduce AP;
- replacement requested, credit requested, rejected, inspection pending/failed, and accepted outcomes remain distinct.

**Buyer → Warehouse:**
- warehouse receives returned goods through an authorized receipt document;
- accepted quantities increase warehouse stock and reduce Buyer custody in the same atomic business operation;
- rejected quantities do not increase sellable stock and require a disposition/quarantine path.

### 5.3 Single-writer and accounting rule

The implementation must choose one authoritative posting path for a given return source. The existing PO-linked `purchase_returns` path and stock-voucher SupplierReturn path must not both post the same physical quantity or supplier credit. Preserve the legacy function for existing/legacy records, but introduce source linkage / idempotency guards for new transactions and route the new Buyer-delegated flow through one central atomic writer.

Supplier AP credit and purchase-tax reversal must be based on **supplier-accepted quantity**, not merely on warehouse dispatch, Buyer handover, voucher Sent, or voucher Completed. Stock reduction at dispatch and AP reduction at supplier acceptance are separate events.

### 5.4 Currency rule

For every new document, resolve currency from the parent `app_settings` record or a valid linked source invoice. Fail closed if the configured currency is missing/invalid. Do not retain a browser or RPC SAR fallback for new EGP company transactions. Do not rewrite the three existing invoice rows or any historical SAR values.

---

## 6. Security and database contracts

1. Remove direct browser DML grants on `purchase_returns` and `purchase_return_details` from `PUBLIC`, `anon`, and `authenticated`; retain company-scoped SELECT for authorized authenticated users and server-only mutation through the approved RPC.
2. Preserve RLS and verify the new event/acceptance tables are append-only to browser roles.
3. The event ledger must use company-scoped identities, actor checks, role/permission checks, and unique operation IDs. A browser must not be able to directly insert, update, or delete custody balances/events.
4. Extend the existing `enforce_stock_voucher_custodian` trigger surgically: preserve all DirectSale/DirectReturn vehicle rules exactly, add only the explicit SupplierReturn Buyer-delegate case, and avoid clearing unrelated custody fields on other voucher types.
5. Extend existing Edge Functions only. Do not create a new Edge Function, generic executor, duplicate workflow engine, or second stock writer.
6. Recheck grants for each new/replaced SECURITY DEFINER RPC and set a fixed safe search_path. The Security Advisor currently reports broad SECURITY DEFINER execute warnings; do not blanket-revoke all 128 authenticated warnings without function-by-function consumer and trigger analysis.

---

## 7. Competitive benchmark — official sources

The current design direction is consistent with the business controls used by leading ERP platforms:

- **Microsoft Dynamics 365:** a purchase return is represented as a return PO, can be tied to the original vendor invoice, uses negative quantities, and records the shipment/product receipt; its return/disposition model separates physical handling from financial implications. It also supports partial quantities at line level.  
  - [Create a purchase return order](https://learn.microsoft.com/en-us/dynamics365/supply-chain/procurement/tasks/create-purchase-return-order)
  - [Specify how to dispose of returned items](https://learn.microsoft.com/en-us/dynamics365/supply-chain/sales-marketing/specify-how-to-dispose-of-returned-items)
  - [Receive partial deliveries of returned items](https://learn.microsoft.com/en-us/dynamics365/supply-chain/sales-marketing/receive-partial-deliveries-returned-items)

- **SAP S/4HANA:** supplier return document flow separates the return PO, outbound delivery/goods issue, and supplier credit memo. Replacement procurement is a linked but distinct follow-on process. This supports keeping physical dispatch and supplier credit as separately evidenced events.  
  - [Document Flow in Supplier Returns and Store Returns](https://help.sap.com/docs/SAP_S4HANA_CLOUD_PE/af9ef57f504840d2b81be8667206d485/cff87e426fed4ad9b3b0929aea4dedf6.html)
  - [Return-to-supplier scenario](https://learning.sap.com/courses/establishing-core-supply-chain-processes-in-sap-s-4hana-cloud-public-edition/exploring-the-return-to-supplier-bmk-scenario_c73e0390-45fc-4929-95d1-8af0a467f0a9)

- **Odoo 19/20:** bill control can be based on received quantities and 3-way matching, vendor refunds/credit notes are linked to vendor bills, and vendor returns reduce stock valuation. This reinforces matching the invoice, warehouse receipt, and supplier settlement rather than treating a Draft invoice as a completed purchase.  
  - [Manage vendor bills and 3-way matching](https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/purchase/manage_deals/manage.html)
  - [Credit notes and refunds](https://www.odoo.com/documentation/20.0/applications/finance/accounting/customer_invoices/credit_notes.html)
  - [Valuation of stock movements and vendor returns](https://www.odoo.com/documentation/19.0/applications/finance/accounting/inventory_valuation/operations_valuation.html)

- **Almarai — published 2025 business model:** the company describes an integrated, high-volume operating model with 129 sales depots, a fleet exceeding 12,000 vehicles, more than 2.3 billion kg handled/delivered annually, 220,000 outlets, SAP S/4HANA, real-time KPIs and forecasting. The relevant lesson for RAWAEA is event-level control across procurement, warehouse, vehicle/custodian, distribution, and finance—not imitation of scale claims.  
  - [Almarai 2025 Business Model](https://annualreport.almarai.com/strategy-and-performance/business-model/)

### Competitive decision

The target RAWAEA workflow should enforce a document/event chain with per-item quantities, partial acceptance, custody transfer, return disposition, supplier credit, and audit evidence. This is more important than adding more screens or a cosmetic dashboard.

---

## 8. Acceptance test matrix required before closure

| Area | Positive cases | Negative / integrity cases | Required evidence |
|---|---|---|---|
| Receiver PO | full receipt; partial receipt; multiple distinct partial receipts; decimal quantity | wrong PO; unknown item; all-zero; negative; over-receipt; duplicate retry; same-quantity new event; wrong branch/role | RPC response, receiving header/details, inventory_log, PO qty_received, audit |
| Quick Market | approved supplier; invoice-number lookup; supplier→Buyer handover; Buyer→warehouse partial receipt | no PO; invalid supplier; duplicate invoice; price missing; wrong company; rejected quantity | invoice, custody events, receiving, inventory, invoice state |
| Buyer goods custody | supplier receipt; return from warehouse; partial supplier acceptance; handover to supplier | direct edit/delete; cross-company user; duplicate operation; negative balance; missing evidence | append-only event ledger and derived per-item balance |
| SupplierReturn | direct supplier recipient; Buyer delegate; partial accepted; rejected/replacement/credit requested | completion before acceptance; duplicate acceptance; duplicate stock issue; same return through both posting paths | voucher, inventory_log, accepted quantities, supplier ledger, GL, tax |
| Cash custody | existing PO settlement remains valid; Quick Market expense linked to invoice and receipt; finance approval; cash settlement | self-review; missing receipt; amount mismatch; duplicate payment; duplicate treasury outflow | custody ledger, payment, supplier ledger, journal, treasury |
| Currency | new records inherit EGP from parent settings | missing/invalid setting; browser SAR payload; historical SAR invoice | app_settings + new-document persisted currency; legacy rows unchanged |
| Security | authorized roles can read and execute approved RPC | direct browser DML denied; cross-company read/write denied; unauthenticated calls denied | grants, RLS, function ACL, negative API tests |
| Sync / UX | Buyer and Receiver refresh after committed events | stale cache, disconnected Realtime, reload, duplicate event | event timing, UI refresh, browser Console/Network |

### Test-data policy

- Do not use the two historical Posted invoices as test fixtures.
- Do not post or mutate the QA-labelled Draft invoice merely to make the screen appear complete.
- Prefer rollback-contained SQL transaction tests for database logic and a disposable isolated environment for authenticated E2E.
- If a persistent fixture is ever necessary, it must have an explicit test marker, unique operation namespace, bounded lifetime, and verified cleanup before/after the test. Do not create untagged test data in Production.

---

## 9. Evidence classification and current readiness

| Layer | Classification | Evidence / limitation |
|---|---|---|
| Report614 and governing charter | CONFIRMED | Full file reads and stable blob SHAs |
| GitHub source | CONFIRMED | Current main HEAD and three source blobs |
| Supabase schema / RPC / grants | CONFIRMED | Read-only live catalog and function-definition queries |
| Production currency | CONFIRMED | app_settings = EGP |
| Existing invoice/stock/AP rows | CONFIRMED | Three invoices and matching inventory/supplier ledger/journal queries |
| Edge deployment versions | CONFIRMED | Live Edge function metadata and source retrieval |
| Cloudflare lineage | CONFIRMED | Dashboard lists Production/main at same HEAD commit |
| Served Buyer file byte parity | UNVERIFIED | Direct deployed asset fetch unavailable |
| Authenticated Buyer/Receiver E2E | UNVERIFIED | Parent tab is at login overlay; no authenticated session used |
| New custody/acceptance workflow | CONFIRMED ABSENT IN CURRENT PRODUCTION SCHEMA | Zero rows and no event table in current schema |
| Full change-set implementation | OPEN | Schema scaffold exists; companion RPC/trigger/Edge/app contracts are not yet a complete deployable set |

**Readiness:** READY WITH LIMITATIONS for read-only diagnosis and change-set preparation. **BLOCKED for Production implementation** until the exact complete code/SQL package, impacts, rollback, and acceptance tests are presented and explicitly approved under Report614 §14 and the permanent constitution. A general instruction to continue the project is not approval of unseen SQL or application code.

---

## 10. Change-control decision and next execution package

The owner has authorized the overall objective: close the Buyer / Receiver / goods-custody / SupplierReturn / settlement gaps. The governing protocol nevertheless requires approval of the exact proposed Production-impacting code and SQL, not an unreviewed blanket mutation.

Accordingly, this checkpoint did **not**:
- edit `buyer.html`, `receiver.html`, `vouchers.html`, `main.html`, or `core.js`;
- execute the 710-line schema scaffold or any migration/RPC/trigger/ACL change;
- deploy or modify an Edge Function;
- change invoices, inventory, supplier balances, journals, treasury, or any Production row;
- create test fixtures, branches, PRs, or duplicate workflows.

### One next priority

Prepare one reconciled, complete **Buyer/Receiver/SupplierReturn ChangeSet** from the current live sources, containing:
1. exact Receiver HTML surgical diff;
2. complete additive schema migration (reconciled to the fresh schema/grants and the reviewed scaffold);
3. full replacement bodies for every affected RPC/trigger, including one-writer/idempotency rules;
4. exact changes to the existing Edge Functions only;
5. exact Buyer/Vouchers UI diffs;
6. function ACL, RLS, Realtime, and rollback SQL;
7. transaction tests and authenticated E2E plan;
8. per-document accounting and stock posting matrices;
9. a preservation plan for historical SAR rows and the QA Draft residue.

The package must be internally consistent and deployable as a whole before it is presented for approval. Do not run the schema scaffold by itself. Do not deploy a UI that points to RPCs or columns that do not yet exist.

### Closure criteria

Close only when the complete package is approved, applied in controlled order, re-read from GitHub and Production, existing Edge Functions are verified at their new versions, the deployed Buyer/Receiver assets match the source, authenticated E2E passes, all stock/AP/GL/tax/custody effects reconcile exactly once, and every test fixture is removed or automatically expired with verified cleanup.

---

## 11. Final status

**CONFIRMED:** the current EGP parent setting, the Receiver PO-details column mismatch, zero-quantity receipt-header risk, repeated-payload idempotency collision risk, absent Buyer goods-custody ledger, Quick Purchase alias rather than a distinct market workflow, SupplierReturn SAR fallback, SupplierReturn custodian-trigger incompatibility, full-value completion posting without supplier-acceptance quantities, separate return posting paths, and direct DML grants on purchase-return tables.

**NOT CLOSED:** Buyer / Receiver / SupplierReturn / cash-settlement integration.

**No Production mutation was performed.** This is an evidence-backed revalidation and implementation gate, not a claim that the requested fixes have been deployed.
