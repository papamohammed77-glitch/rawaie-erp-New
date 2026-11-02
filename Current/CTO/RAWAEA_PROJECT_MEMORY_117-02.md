## LVE-592 — 2026-11-03 — Sales Authorization & Permission Source Contracts

- confirm-order v4: JWT + active company + order status only; no orders/telesales permission. Parent main.html calls it.
- create-runsheet v26 / append-to-runsheet v8: Parent main consumers; Edge/RPC validate company and state but not effective permission (reconfirmed from LVE-590).
- delete-order v10 and update-order v6 enforce sales permissions; update-order combines user, roles and role_permissions.
- save-customer v4/delete-customer v3 check customers permission.
- sales-return-management RPCs check * or return; sales quotes use rawaea_quote_actor_ok (* or orders); sales-target-engine gateway has read/manage/approve tiers; save-sales-invoice and sales-payment-allocation enforce effective permissions.
- Permission implementation divergence: some paths combine role-derived permissions; others check users.permissions only (customer, sales-return, quotes, sales-target). Divergence confirmed; effect for role-only users UNKNOWN pending role data/sync-trigger review.
- Accountant UI retains pending cash voucher payload and operation_id in sessionStorage for retry; preserve this.
- No unauthorized HTTP call or business write. No source/DB/Edge/PR/deployment mutation. PR #10 remains Draft.
- Report: doc/Draft/Reprots/Report592_CTO_SALES_AUTHORIZATION_AND_PERMISSION_CONTRACT_AUDIT_20261103.md. Report commit 4f97a96672958bcd7bbf2d31c4275f3bf5946ca3. CURRENT_STATE commit 6bc6a9a7f9757a450830a7a8c8ff88f61d5b7807.
- Next: owner-approved permission matrix and exact changes for confirm-order, create-runsheet, append-to-runsheet and role-derived permission consistency. Reuse existing effective permission helpers; no parallel engine.

---

## LVE-591 — 2026-11-03 — Finance Authorization & Data Access

- Audited high-impact financial Edge/RPC paths after LVE-590.
- save-journal-entry v8: JWT + active company only; no finance permission; service_role calls post_journal_entry.
- save-payment-voucher v7: JWT + company + branch + treasury only; no finance permission; userClient calls finance_save_expense. Both SECURITY DEFINER overloads of finance_save_expense are executable by authenticated and check company context/period/accounts but not finance permission.
- save-receipt-voucher v8: generic receipt path has no finance permission and calls service_role-only post_cash_receipt_atomic. Van Sales collection path is more restricted because post_van_sales_collection_atomic validates current user's direct-sales role and customer assignment.
- save-transfer-voucher v4: no finance permission; service_role-only post_treasury_transfer_atomic.
- update-driver-ledger v2: no finance/driver-ledger permission; service_role-only post_driver_ledger_entry.
- get-cash-flow v1: JWT only; get_cash_flow callable by authenticated, company scoped through current_user_company_id, no finance permission. Edge service_role context may return empty due missing auth.uid; Runtime not tested.
- post_journal_entry, post_cash_receipt_atomic, post_treasury_transfer_atomic, post_driver_ledger_entry are service_role-only; their Edge wrappers are the effective security boundary.
- Positive patterns: save-sales-invoice v19 and sales-payment-allocation v2 enforce effective permissions.
- Findings CONFIRMED at source/RPC contract level; no HTTP exploit or financial write performed. No DDL/DML/ACL/Edge/deployment/merge.
- Report: doc/Draft/Reprots/Report591_CTO_FINANCE_AUTHORIZATION_AND_DATA_ACCESS_AUDIT_20261103.md. Report commit 28926bbed61c39d39cff3d9e53a49b88ea8508c6. CURRENT_STATE commit c6278354deea37ec4ed5add81b862985490b716e.
- Next priority: owner-approved Finance Authorization Matrix and exact permission changes for manual journals, expenses, generic receipts, treasury transfers, driver ledger, and cash-flow access; keep Van Sales collection separate. Explicit owner approval required.

---

## LVE-590 — 2026-11-03 — Cross-Module Authorization & Inventory Effects

- Starting point LVE-589. Reviewed high-impact Edge/RPC flows beyond Buyer.
- Confirmed server-side permission/assignment gaps at contract level:
  - create-runsheet v26 / create_runsheet_atomic: no effective permission check.
  - append-to-runsheet v8 / append_orders_to_runsheet_atomic: no effective permission check.
  - start-loading v6 / start_runsheet_loading: no warehouse/loader permission or assignment check.
  - complete-loading v11 / complete_runsheet_loading: no loader assignment match or permission check.
  - unload-runsheet v6 / complete_runsheet_unloading: no unloader assignment or warehouse permission check.
  - receive-purchase v12: no effective receiving/purchasing permission check.
  - complete-delivery v4: no deliverer assignment/permission check.
  - complete-order-delivery v14 / complete_order_delivery_atomic: no deliverer assignment or effective delivery permission check.
  - save-daily-settlement v4 / post_daily_settlement_atomic: no driver/settlement permission or assignment check.
- Positive authorization patterns: start-picking v35, complete-picking v18, start-return/complete-return, save-sales-invoice v19, save-purchase-order v22, delivery_supervisor_assign_deliverer_atomic.
- cancel-delivery v5 checks driver_id while driver.html and delivery_supervisor_assign_deliverer_atomic use deliverer_id.
- complete_order_delivery_atomic changes delivered quantities but does not call post_stock_movement; complete_return_atomic posts SalesReturn from NULL to main branch and does not decrement vehicle branch. No compensating triggers were found on orders/order_details/run_sheet_details.
- Production QA fixtures show RS-1 Delivered with 13 loaded/13 delivered while VAN-CHV branch retains 13; RS-2 Returned with 6 loaded/1 delivered/5 returned while VAN-VHL retains 6. inventory_log movement types have no Delivery/VanSale. Treat as QA evidence, not proven real business loss; do not delete.
- Source/DB contract findings CONFIRMED; runtime exploit and E2E UNVERIFIED. No writes or operational changes.
- Report: doc/Draft/Reprots/Report590_CTO_CROSS_MODULE_AUTHORIZATION_AND_INVENTORY_EFFECT_AUDIT_20261103.md. Report commit 17ddb6567736ca14daf57df827bbcaf0af0654e0. CURRENT_STATE commit ea1dd9fd2114457148e0f74c0072a20a280e0150.
- Next priority: owner-review package for Warehouse/Delivery/Settlement authorization and vehicle stock reconciliation, alongside Procurement findings. Explicit owner approval required before any Production change.

---

## LVE-589 — 2026-11-03 — CTO Initialization / Procurement Authorization & Contract Conflicts

- Re-read CURRENT_STATE first; starting LAST VERIFIED EVENT was LVE-588. Read permanent constitution (293 lines), Master CTO Governance (2,665 lines), and reviewed all 114 report files present in range 400–500; numbering duplicates exist and 490/491 files were not present. Report499 is the final daily revalidation in the range; Report500 is a mind map, not Production closure.
- Operational repo current main HEAD 7a14d51b4d4c225240b215879abf6b77b99888d3. PR #10 remains Draft/unmerged, head 209c318f2324d741e61b0dceaf5253f830af8c2e, 3 ahead / 2 behind, only Buyer HTML changed.
- Retrieved full Parent main.html through Git blob API: blob 53b5a9e9d0433a785c3d5471a9c0d68c25497882, 1,800,879 chars / 33,358 lines. Structural scan: 46 RW_ modules, 1,016 functions, 48 literal table references, 41 RPC references, 48 Edge endpoint references. Parent has separate RW_Purchases and RW_PurchaseGold; RW_PurchaseGold replaces RW_Purchases.renderOrders, while legacy purchase-pos remains a separate visible route.
- Current core.js blob f4c6a0df441e0da9105d4fe7ce94ad2d7a1735e1, 1,008 lines; modules RW_Auth, RW_DB, RW_API, RW_UI, RW_ImageCache, RW_SW, RW_Realtime.
- Production: 186 public tables, 297 public functions, 186 RLS-enabled tables, 247 public policies, 304 public triggers, 734 migrations, 100 Edge Functions.
- save-purchase-order v22 is ACTIVE/verify_jwt=true and byte-identical to Git source.
- receive-purchase v12 is ACTIVE/verify_jwt=true but checks JWT and company membership without effective warehouse/purchasing permission before calling receive_purchase_atomic through service_role. Backend authorization gap confirmed at source/contract level; no HTTP exploit test performed. Its deploy source is not in operational supabase/functions.
- Receiver source uses purchase_order_details.eq('po_code', code), but Production purchase_order_details has po_id and no po_code. Source/schema conflict confirmed; runtime behavior untested. Receiver uses parseInt on numeric qty_ordered; fractional-unit impact remains unverified.
- Parent legacy purchase-pos route remains reachable and RW_Purchases.savePO sends old orderHeader/itemsList payload without operation, while save-purchase-order v22 requires operation. Source contract conflict confirmed; no runtime E2E.
- purchase_invoices and purchase_invoice_details grant authenticated DML under company-only ALL RLS; current_user_company_id does not check purchases permission. Direct DML bypass of central gateway is confirmed at ACL/RLS level. purchase_attachments has similarly broad company-only policy; private storage lacks a verified buyer-purchase invoice path.
- Buyer and Parent CREATE_INVOICE omit stable operation_id; duplicate Draft on a fresh retry key remains a contract risk, not runtime-tested.
- Supplier AP duplicate trigger is now CLOSED in live Production: one projection trigger remains and stored AP equals supplier_ledger net (3,970; difference zero). Do not reopen without new evidence.
- Production current counts: purchase_invoices=3, details=6, purchase_attachments=0, buyer_custodies=0, advances=0, expenses=0, payments=0, purchase_orders=1, PO_details=1, receiving=0, receiving_details=0. Existing invoice/PO rows are explicit QA/test references; do not delete.
- Staging is ACTIVE_HEALTHY but has no purchase_invoices/details or save-purchase-order/receive-purchase; not Buyer E2E-ready.
- Cloudflare bot comments: rawaea-erp preview for 209c318 reports success; erp-frontend, rawaea-store and warehouse-supervisor project builds report failure. Served HTML/headers/runtime/E2E remain UNVERIFIED.
- Migration lineage: Production ledger versions 20261102150516/20261102151137; operational Git files are timestamped 20261102160000/20261102162000. Function bodies match after formatting normalization, but migration version/name lineage is not one-to-one. No db push.
- No source, DB, Edge, PR, or deployment mutation in LVE-589. Only documentation report/state/memory updates.
- Report: doc/Draft/Reprots/Report589_CTO_INITIALIZATION_AND_LIVE_RECONCILIATION_20261103.md. Report commit 846d960f92851dd39c5248b7d4567ba94bc816fe. CURRENT_STATE commit ae037108f62be375bbf7d200922d18b57f2accc6.
- Next priority: owner-review package for receive-purchase server authorization, Receiver po_id/quantity contract, legacy purchase-pos payload, invoice DML hardening preserving reads, and stable invoice operation_id. Keep PR #10 Draft; no Production write before exact owner approval.

---

## LVE-588 — 2026-11-02 — Buyer Workbench Live Revalidation / Invoice RLS-ACL Conflict

- Revalidated operational repo live: main HEAD 7a14d51; PR #10 branch cto/buyer-field-workbench-lve-587 head 209c318; 3 ahead / 2 behind; PR remains Draft/unmerged. Two main commits after merge base are docs-only. The old 5ae94d7 / 2-ahead handoff is stale.
- Current Buyer blob 100987d; nine tab actions retained, zero cost_price references, one inline script parses, seven source-algorithm search cases pass against 30 active Production items. PO CREATE now sends operation_id from 209c318.
- Buyer CREATE_INVOICE for a new invoice still sends no client operation_id; Edge generates a new UUID per request, so a retry with a new request key can create another Draft. The DB invoice operation_id unique index only deduplicates the same key.
- Existing line editors turn blank price into 0 through Number(el.value); preConfirm does not revalidate each line, and DB accepts zero. This behavior is also present on main, so it is pre-existing, not introduced by PR.
- Owner LVE-585 definition of «فواتيري» remains quick-market purchase register with invoice/item evidence and line specs. Current PR filters creator only; schema has no invoice_type/source marker, and no invoice photo or per-line notes path is implemented.
- Critical Production conflict: purchase_invoices and purchase_invoice_details have permissive ALL company-only RLS policies and authenticated effective SELECT/INSERT/UPDATE/DELETE. current_user_company_id returns company_id for any non-Inactive user, without purchases permission check. This permits direct invoice DML outside the central Edge/RPC workflow and conflicts with owner §77.4. Do not change grants/RLS until full consumer scan and exact owner approval.
- Parent main.html directly reads purchase_invoices and purchase_invoice_details for views/returns, but uses Edge API for invoice create/post; preserve SELECT if future DML hardening is approved.
- Production Edge save-purchase-order v22 remains active and byte-identical to Git; currency EGP. Migration ledger has 734 entries, latest 20261102150516 and 20261102151137; matching SQL source files not located at expected paths.
- Production logs: 11,637 HTTP 200 and two ~160s 504s in 24h, without execution_id/version or matching function error logs; root cause unknown.
- rawaea-staging is active but not Buyer-ready: no save-purchase-order Edge function and no purchase_invoices/details tables. Cloudflare reports rawaea-erp preview build success for 209c318, but served artifact/browser E2E remain unverified.
- No code, DB, RLS/grants, Edge, merge, or deployment writes in this run. PR #10 remains Draft. Next: exact owner-reviewed invoice contract remediation, consumer scan, staging parity, then E2E.
- Report: doc/Draft/Reprots/Report588_BUYER_FIELD_WORKBENCH_DAILY_REVALIDATION_20261102.md

---

## LVE-587 — 2026-11-02 — Buyer field workbench source patch

- Recovered current governance, Buyer commit history and Reports569/570/571/585. Preserved LVE-582/583 invoice tabs/history/detail row handler, Draft edit/delete, currency, auth, gateway, realtime and all nine current tabs.
- Changed only `companies/company-1/purchasing/buyer.html` on feature branch `cto/buyer-field-workbench-lve-587`; current main head remains base `aa8cbffbfa8d42253726381080dcfc24eaea838b`.
- Latest commit `5ae94d769a22b540f852d235694ccf4969862cfc`; file blob `ac8be3839e7c30689e757cb8ae61c2957a8063be`.
- Added mobile horizontal touch navigation; Picker-inspired image product cards; Arabic-normalized search of existing company-scoped items by name/code/barcode; exact barcode priority; empty query yields no list; up to 14 results.
- Removed every `cost_price` reference from Buyer. Purchase price is manual in quick purchase invoice and PO entry; blank price is rejected.
- «فواتيري» filters `created_by` against current authenticated email. Verified invoice creation passes user.email to DB created_by.
- Production item sample: 30 active; 20 barcode, 29 images. All 6 inline scripts parse; zero cost_price refs; search checks pass for one-character, full name, exact barcode and empty query. Existing LVE-583 row details click and Draft guards retained.
- Draft PR #10: https://github.com/papamohammed77-glitch/erp-frontend/pull/10.
- No merge, Production deployment, Cloudflare publish, database/Edge/RPC/RLS/ACL, stock, custody or GL changes. Master CTO §77.2 approval gate remains in force. Current gateway GET_DATA still max 500; server-side pagination/search is not included.
- Next: owner review of exact PR changeset, then browser/deployment verification after authorized merge. Subsequent separate units: invoice private media/specifications, backend catalog search/pagination, Receiver intake, cash custody and purchasing-car movement ledger.

Report: `doc/Draft/Reprots/Report587_BUYER_FIELD_WORKBENCH_EXECUTION_20261102.md`

---

## LVE-586 — 2026-11-02 — Buyer Gold/Diamond Field Product Upgrade

**Status:** Review and product design documented; operational implementation not performed.

- Re-read current operational Buyer source and Picker reference. Buyer source remains the LVE-585 verified blob `73d746571a10b1720bdd31631004abce0ac9afa1`; do not claim broad UI changes are already committed.
- Confirmed `App.data(table)` sends `GET_DATA` with `limit:500`; the app uses client-side cached data. Item quick search only sees the loaded catalog, returns up to 20 matches, and quick-add defaults price to `cost_price||0`. A zero/stale cost must be labeled as unreliable, never presented as a trustworthy market price.
- Reviewed Today, Suppliers, PR, Quotations, Orders, فواتيري, عهدتي, رصيد السيارة and حسابي. Key product gap: current Buyer is largely a set of mobile-compressed data screens, not a cohesive field purchasing journey. Picker patterns to selectively adopt: image-led touch cards, instant search, readable details, visible progress. Preserve Buyer shared core/auth/gateway.
- Report586 defines mobile-first navigation/action center, catalog search, quick market purchase journey, evidence capture, offline draft/sync states, supplier/quotation intelligence, cash reconciliation, purchasing vehicle custody and phased stock/accounting integration. It includes invariants and acceptance tests.
- No operational Buyer/Receiver source, Production schema/data/RLS/Edge function, or deployment was changed in LVE-586.
- Do not redo LVE-583 invoice-row click/escaping or LVE-585 definition correction. Next engineering slice: Phase A field UX foundation plus catalog server-side search contract investigation. Follow project approval gates before Production changes.

Report: `doc/Draft/Reprots/Report586_BUYER_GOLD_DIAMOND_FIELD_PRODUCT_UPGRADE_REVIEW_20261102.md`
Commit: `7d65235207e399fb01c9167a9fc14e42599ae5f1`

---

## LVE-585 — 2026-11-02 — Owner correction: quick purchases, cash custody and purchasing-car stock

**This is the latest verified business definition and supersedes conflicting interpretations in earlier summaries/reports.**

### Owner-defined workflows
- **Buyer vehicle balance:** all physical goods currently in the purchasing officer's car, by item and quantity, regardless of whether loaded from warehouse, bought in the market and handed to the buyer, or issued from warehouse for an operational/customer need. It is not Driver stock, Van Sales stock, a mobile branch, a runsheet, or financial driver settlement.
- **Buyer cash custody:** money physically in the purchasing officer's possession and accountability. Quick purchase expense needs supplier invoice/proof of amount paid plus warehouse receipt. Fuel needs petrol-station receipt. Transport needs ticket/receipt. Other expenses need appropriate evidence. The display is advisory and must separate submitted/pending/approved/rejected/returned cash and the amount still accountable. Expense approval must not automatically be a supplier AP payment.
- **Buyer "فواتيري":** buyer's quick market purchase invoices; include supplier invoice image, item lines, quantities/prices/specifications and item photos; search/filter/detail view like PO/Parent Purchase Invoices. Keep current Draft edit/delete safeguards and barcode lookup.

### LVE-585 current source/Production evidence
- Operational Buyer source blob: 73d746571a10b1720bdd31631004abce0ac9afa1. Its invoice list is generic supplier invoices and lacks the quick-purchase scope and private invoice/item evidence. Existing Draft protections and barcode item lookup are strengths to retain.
- Receiver source blob: 3111b5e801d1bc021cf18fd66d633fbdc54ac0d6; only PO queue/receive by PO code; no invoice-based quick market receipt.
- purchase_invoice_details.notes exists but the current invoice create/update Draft RPCs do not persist per-line notes.
- purchase_invoices.supplier_id is NOT NULL/FK suppliers; status constraint currently Draft/Posted/PartiallyPaid/Paid/Cancelled; no explicit quick-purchase/payment-source marker. No-PO invoices must not all be presumed quick market purchases.
- purchase_post_invoice_atomic still rejects no-PO invoice posting with PURCHASE_QUICK_INVOICE_RECEIPT_REQUIRED.
- Current custody expense model has no expense_type and requires PO-linked Draft invoice + supplier + PO receipt docs. Current review RPC posts Dr supplier AP (211), Cr employee custody (127), marks invoice Paid, and reduces supplier ledger. This is not the correct path for quick purchases already paid from the buyer's cash custody.
- purchase_attachments company-only policy and broad authenticated/anon DML grants are not safe for invoice privacy. Private employee-documents bucket has no verified buyer-purchase subpath; public product-images is not appropriate for private invoices.
- Existing stock-voucher core types: Transfer, DirectSale, DirectReturn, SupplierReturn. Custodian trigger requires same-company active direct-sales rep + van-sales for DirectSale/DirectReturn; Transfer vehicle guard requires a same-company delivery driver. Both registered vehicles are Delivery (CHV-2025-01 and VHL-0422). These types/assignments must not be repurposed for buyer custody.
- Existing Branch→Supplier SupplierReturn remains intact.
- Active COA inspected includes 121 Treasury, 124 Inventory, 127 Employee Custody, 211 Suppliers, etc.; exact fuel/transport/other expense account mappings remain UNKNOWN.

### Accountability and control
- Earlier Production buyer/custody/purchase migrations are present, including 20261031233331, 20261031233923, 20261031234921, 20261031235057, 20261101003952, 20261101005616, 20261101005849, 20261101010224, 20261102150516 and 20261102151137. Migration existence does not itself prove exact owner approval. Do not claim approval without its evidence.
- LVE-585 was read-only (source fetches and SELECT queries). No Production rows, DDL, RLS/grants, RPCs, triggers, Edge deployment, app source or Cloudflare deployment were changed.
- Master §77.2 requires an exact source/SQL changeset with impacts, dependencies, failures, tests and rollback followed by explicit owner approval before production-sensitive writes. Operational source remains owner-applied under the project governance.

**Latest report:** doc/Draft/Reprots/Report585_BUYER_QUICK_PURCHASE_CUSTODY_PURCHASING_VEHICLE_CORRECTED_DESIGN_20261102.md  
**Report blob:** 1bf56c28ef76f2ef6987a9e2644271a59fcfc192  
**Report commit:** 7feaa2f5675d95fe527fb32009e5b243db2e9f1c

**Next work:** prepare the exact integrated changeset for Buyer invoice scope/media/specification, secure attachment storage, quick invoice receiving in Receiver, separate purchasing vehicle assignment and central stock movements, and custody expense categories PURCHASE/FUEL/TRANSPORT/OTHER. Preserve PO, existing SupplierReturn, Driver/mobile stock and Parent. Test idempotency, partial receiving, AP isolation, custody balance, tenant/RLS and regressions. No Production write/deploy before exact owner approval.

---

# RAWAEA ERP — PROJECT MEMORY LEDGER 117-02

## 0. PURPOSE
This file is the persistent, governed project-memory ledger derived from the `117-02` current-truth command and the `MASTER - RAWAEA ERP.md` continuity/execution command.
It is not a report and not a replacement for source systems.
Operational recency is governed by `CURRENT_STATE.md` and its `LAST VERIFIED EVENT`.

## 1. SOURCE OF TRUTH HIERARCHY
1. Production runtime and database evidence
2. PostgreSQL schema/functions/triggers/RLS/grants/constraints
3. Active deployed Edge Functions plus runtime evidence
4. Current Git `main`
5. Current application/core/PWA/SW files
6. Git history
7. Historical/original sources
8. Historical execution artifacts
9. Reports/prompts
10. Assistant memory

Historical sources explain intent and prior behavior. They do not prove current runtime state without re-verification.

## 2. CURRENT PROJECT IDENTITY
- Project: RAWAEA ERP
- Operational application-source repository: `papamohammed77-glitch/erp-frontend`, branch `main`; current verified HEAD at LVE-2026-10-31-568: `65799d282acc79359b17a1a13dcd68f62859e1fb`. Parent `companies/company-1/main.html` Blob: `53b5a9e9d0433a785c3d5471a9c0d68c25497882`; shared `companies/company-1/core.js` Blob: `a95ee6b29ff54b4a240ce4b81f9a535aa87686db`; Counter Blob: `32d0dc8ca0edb7cc68660f0fbd6246408117498d`; Loader Blob: `4375d3067f9fe5453b49f580339a1f906040967f`; Warehouse Supervisor Blob: `792f8bbff15a0c724e47b6e6e28f2ffec903b024`; Returns Blob: `16d02fff2d00759451879204abf218202898f9c0`; Driver Blob: `92ae03678b6516345a61d30bb5967046096d8cce`.
- Governance, continuity, and report repository: `papamohammed77-glitch/rawaie-erp-New`, branch `main`. `CURRENT_STATE.md` is the canonical continuity checkpoint; latest event is `LVE-2026-10-31-568` (state commit `12ef7e853533fc0ae6a6878a75fad21f75cec959`). The operational source repository also contains a separate `CURRENT_STATE.md` handoff, updated 2026-10-31 17:20:22Z; it was not modified in this run to avoid a possible uncontrolled Pages deployment. Re-fetch both live heads each run.
- Historical repository: `papamohammed77-glitch/rawaie-erp-review`.
- Production: Supabase `SMART ERP`, ref `fiilmooggumokxanwiyx`, status `ACTIVE_HEALTHY`; live metadata reports PostgreSQL `17.6.1.121` as of LVE-558.
- Staging: Supabase `rawaea-staging`, ref `hfzznsiprnwkpayskzhu`; current live project listing reports `ACTIVE_HEALTHY` as of LVE-558. No staging tests were run in this event.

## 3. MASTER COMMAND ADOPTION
The full `doc/Draft/medhat/MASTER - RAWAEA ERP.md` command was read end-to-end through section 60.
Its operating loop is mandatory:
`CURRENT_STATE -> LAST VERIFIED EVENT -> current reality -> reconcile -> identify target -> resolve critical unknowns -> trace owner/dependencies -> surgical change -> verify -> deploy/runtime verify -> CURRENT_STATE update -> reassess`.
It explicitly rejects historical-stage control, percentage-based control, artificial workflows/executors, duplicate architecture, report-only closure, and invented completion claims.

## 4. HISTORICAL MAIN1 / NEW-MAIN RECONCILIATION NOTES — 2026-08-31
- Previous `CURRENT_STATE.md` states were repeatedly reconciled when Git advanced beyond the recorded checkpoint.
- The last confirmed commit that actually modified `Current/PWA/New-main` is `a4551e0fcfc55fd609f48109407c025b44e20641`.
- Comparing `a4551e0...` to current `e8da572...` shows no later New-main target modification; later commits primarily changed workflows, builders/parsers, prompt/reporting and verification infrastructure.
- A later documentation commit `a2092863...` renamed/normalized the master command file and did not modify Production.

## 5. FRESH PRODUCTION SNAPSHOT — 2026-08-31
Direct SQL verification against Production observed:
- PostgreSQL 17.6
- Public tables: 66
- Public functions: 76
- Public triggers: 20
- Public policies: 110
- Companies: 1
- Users: 24
- Branches: 2
- Items: 17
- Stock rows: 20
- Inventory log: 3
- Orders: 0
- Runsheets: 0
- Journal entries: 2
- Journal lines: 0
- Customer ledger: 0
- Supplier ledger: 0
- Driver ledger: 0
- Daily settlements: 0
- Treasury: 1
Production status: `ACTIVE_HEALTHY`.

## 6. CURRENT SECURITY / AUTHORIZATION EVIDENCE
Fresh Production privilege/RLS inspection confirmed:
- `orders` broad authenticated `ALL` policy plus broad store/anon insert paths.
- `order_details` broad authenticated `ALL` policy.
- `run_sheet_details` broad authenticated `ALL` policy.
- `daily_settlements` public `ALL` with `true/true`.
- Seven observed externally executable `SECURITY DEFINER` functions include vehicle context/guard functions, `create_vehicle_atomic`, `fn_vehicle_audit_trigger`, and `get_budget_vs_actual`.
- Auth leaked-password protection is disabled according to Security Advisor.
- Performance Advisor reports unindexed FKs, RLS init-plan inefficiencies, multiple permissive policies and unused indexes.
These findings are evidence-backed security/governance blockers, not permission for blind Production mutation.

## 7. STAGING OBSERVATION
Direct staging SQL observed one company. Therefore staging is not a two-company proof environment and cannot by itself prove tenant isolation.

## 8. BUSINESS DOMAIN MEMORY
### Sales
Channels include POS, Telesales, Order Taker, Van Sales and Online Store. Sales orders feed runsheet/fulfillment and may result in delivery, return, settlement and financial/ledger effects.

### Procurement
`Purchase Order -> Receiving -> Physical Stock -> Journal -> Supplier Ledger` through the inspected `receive-purchase -> receive_purchase_atomic` path.

### Warehouse / Fulfillment
`Runsheet -> Picking -> Loading -> Delivery/Return/Unloading`. Picking is reservation-oriented; loading/unloading inspected paths use the central physical-stock engine.

### Inventory
`stock_branches.qty` is physical quantity; `allocated_qty` is reservation state. `post_stock_movement` is the inspected physical movement authority.

### Accounting / Ledgers
`post_journal_entry` is the inspected journal core. Dedicated customer/supplier/driver ledger writers exist. Full writer exclusivity remains open.

## 9. CURRENT ARCHITECTURE MEMORY
- Multi-PWA frontend remains the current operational architecture.
- `Current/PWA/main.html` is protected from replacement.
- `Current/PWA/New-main` is the sole authorized clean-room candidate.
- `main1..main11` are logical modules/contracts, not byte slices.
- Authenticated identity maps through `public.users.auth_id -> users.company_id`.
- `app_private.current_user_company_id()` is the DB tenant resolver.
- Specialized PWAs delegate business writes to Edge/RPC/Core owners.
- Duplicate Physical Stock writers are forbidden.

## 10. HISTORICAL INVENTORY MEMORY
Historical rescue evidence established the Inventory writer boundary around `post_stock_movement(10)`, separated reservation engines, and constrained legacy application execution. This was an Inventory boundary closure, not ERP-wide closure.
Historical Receive contract: cumulative `received_qty`; partial Receive remains Sent; full becomes Received; reject over-remaining; preserve allocation; one history row per physical movement; atomic transaction.

## 11. CURRENT CONSUMER MEMORY
Representative paths:
- Telesales/Main -> `save-sales-invoice` -> `save_sales_invoice_atomic`.
- Purchase receiving -> `receive-purchase` -> `receive_purchase_atomic`.
- Loading -> `complete-loading` -> `complete_runsheet_loading`.
- Voucher UI -> voucher Edge/Core paths.
- New-main -> specialized PWA/Edge/Core owners for operational mutations.
Full all-consumer graph remains unproven.

## 12. DEPENDENCY GRAPH RECONCILIATION
`Current/CTO/20260831_PHASE5_SYSTEM_DEPENDENCY_GRAPH.md` previously claimed `CLOSED` while admitting the full runtime graph was not proven. Under the Master Command this was inconsistent; it was corrected to `PARTIAL / OPEN` in commit `50b40e6b7d8d0f0ddc29dc6681fac8059cc5e110`.

## 13. DEPLOYMENT LINEAGE MEMORY
The complete chain
`Git SHA -> source file -> artifact/package -> Production version -> runtime consumer -> runtime evidence`
remains only partially proven. Deployment existence/version does not establish consumer use or runtime correctness.

## 14. NEW-MAIN / MAIN1 MEMORY — CURRENT
MAIN1 current/original contract evidence is verified. The New-main target at `a4551e0...` contains substantial shell/auth/tenant/navigation/permission/notification/workflow/audit surfaces, but closure is not established.

Verified remaining contract gaps:
- Owner calculation currently permits `owner_profile` existence to make `isOwner=true`; governing contract requires Auth metadata to establish owner semantics and preserves wildcard permissions.
- New-main contains only a lightweight `RW_OwnerLicense` object; full MAIN10 license-management UI/save/email/password contract is not present.
- Notification implementation lacks exact MAIN1 `_clickNotif`, `_renderAndSave`, `_updateBadge`, `markRead` behavior and related-record navigation.
- Audit rendering is simpler than the full MAIN1 `RW_Audit_*` contract set.
- Session reset/fail-closed lifecycle proof is incomplete.
- Workflow rules are not explicitly company-scoped in the current target surface; impact needs contract proof before any Production policy decision.

A previous executor attempt `6b339cc...` modified tooling rather than safely closing the target and was later reverted. Parser/browser-gate commits such as `02da996...`, `9507d0...`, `455e287...`, and `c2c316...` improve execution infrastructure but are not target implementation evidence.

## 15. MAIN1 EXECUTION SAFETY RESULT
The Master Command requires actual target modification plus verification. The available GitHub write path for `Current/PWA/New-main` performs a complete monolithic file replacement. This execution environment did not provide a safe way to reconstruct and submit the full target bytes without risking unrelated content loss. Therefore no unsafe whole-file rewrite was performed.

This is a tooling safety limitation only. It is not a business or architectural blocker and not evidence of completion.

## 16. CURRENT ANOMALY MEMORY
Production anomalies requiring provenance remain:
1. One active/non-inactive `users` row without `auth_id`.
2. Two cancelled `VoidInvoice` journal headers with zero lines.
3. Three `VoidInvoice` inventory-log rows.
No deletion or synthetic repair without provenance, downstream impact and audit analysis.

## 17. INCIDENT / FAILURE MEMORY
Never repeat:
- report == current truth;
- historical PASS == current PASS;
- CI PASS == Production PASS;
- Git source == deployed code without lineage;
- executor change == target implementation;
- deployment existence == consumer proof;
- broad RLS/grants == intended authorization;
- duplicate physical-stock writers;
- destructive repair without provenance;
- byte-slicing logical PWA modules;
- compacting a rich application into a feature-loss candidate;
- patching Production solely to satisfy CI.

## 18. OPEN CLOSURE UNITS
1. Safe actual MAIN1 target modification in `Current/PWA/New-main`.
2. MAIN1 static contract validation after modification.
3. Browser/runtime verification of New-main.
4. Auth/Owner/license lifecycle proof.
5. Notification and audit behavior parity.
6. Full consumer graph and deployment lineage.
7. Two-tenant authorization harness/proof.
8. P0 tenant-isolation remediation plan.
9. Security Advisor remediation + regression suite.
10. Exhaustive journal/ledger/treasury writer matrix.
11. Data provenance for current anomalies.
12. Service Worker runtime proof.
13. Main replacement certification.

## 19. FORBIDDEN ACTIONS
- No blind Production DDL/DML.
- No direct Physical Stock writer outside canonical engines.
- No direct financial mutation from New-main.
- No deletion of unknown legacy artifacts.
- No credential/token use because exposed in historical workflow source.
- No Main replacement before evidence closure.
- No artificial workflow/executor/parallel architecture.

## 20. MEMORY OPERATING LOOP
1. Read `CURRENT_STATE.md` first.
2. Read latest `LAST VERIFIED EVENT`.
3. Verify Git HEAD.
4. Verify relevant Production state.
5. Compare with this ledger.
6. Mark stale/conflict.
7. Resolve critical unknowns.
8. Identify true current target.
9. Prove owner/dependencies/root cause.
10. Implement minimum safe target change.
11. Verify source/runtime/data/audit as applicable.
12. Update `CURRENT_STATE.md` immediately.
13. Record material knowledge here.
14. Reassess target after closure.

## 21. HISTORICAL MEMORY BASELINE — LVE-2026-09-01-004
- Event ID: `LVE-2026-09-01-004`
- Event Type: `MASTER_CONTINUITY_MEMORY_RECONCILIATION_FINAL`
- UTC: `2026-09-01T00:24:00Z` execution window
- Source: full MASTER command 0-60 + current Git history + direct New-main + MAIN1 + MAIN10 inspection + current Production evidence
- Git SHA: `e8da572a5b42a407c4d5f8d7493b9e4fe134f663`
- Production State: `ACTIVE_HEALTHY`
- Action: finalized the project-memory reconciliation after fully reading the Master command; verified the latest New-main target change, separated target implementation from later tooling changes, recorded the remaining MAIN1 gaps, and preserved the no-unsafe-write decision.
- Result: `MEMORY SYNCHRONIZED / MAIN1 OPEN / NO UNSAFE TARGET REWRITE`
- Impact: future CTO continuity starts from the actual latest repository state and will not repeat the reverted executor/false-closure path.
- Next Authorized Action: continue from the proven MAIN1 gaps using a safe full-file target-write path, then run structural, syntax, browser/runtime, authenticated and Production-compatibility verification before closure.

## 22. CURRENT EXECUTION POSITION
- Master continuity command: ACTIVE
- 117-02 memory governance: ACTIVE
- Current State: LVE-2026-10-29-560; source truth is revalidated from live GitHub/Supabase/Cloudflare snapshot, not from this ledger.
- Operational app repo: `erp-frontend/main`, HEAD `416de1c1d829c48b7c82442242a2a039e3d7e48c`.
- Current target: standalone Returns eligibility. Main `returns.html` still contains the root cause; PR #8 is open/draft/unmerged with the main list eligibility fix. Search patches R8-S1-A/B remain owner-only and un-applied.
- Production: checked at `2026-10-29 19:03:17.860357+00`; `RS-1` Delivered, 5 detail rows, outstanding return quantity 0; `RS-2` Delivered, 7 detail rows, outstanding quantity 5. No current Returning/Returned rows in the inspected sample. No Production mutation occurred.
- Parent: commit `0351897` is in current Main history and corrected the Parent returns-table JS/HTML. Parent SHA is `3a5d2e565a04262081d024f6e514e1372d372e84`; don't repeat historical Parent patches without new evidence.
- Driver: current SHA `d7ace0b9be52c936aee1d5f5e1250b6d2e9a48f0`; no causal Driver defect was found for standalone Returns eligibility. No change required.
- Deployment: Cloudflare snapshot shows Production Main `416de1c` at `b469734c.rawaea-erp.pages.dev` and PR #8 Preview `3ad370c` at `da5fcdde.rawaea-erp.pages.dev`. Byte-identical served artifact and authenticated E2E remain UNKNOWN/UNVERIFIED; referenced failed build logs remain to be read before attributing causes.
- Security / older MAIN1 backlog: OPEN; this event does not close or authorize unrelated historical work.
- Status: RETURNS ROOT CAUSE CONFIRMED / CORE FIX ONLY IN DRAFT PR #8 / OWNER SEARCH PATCH REQUIRED / PRODUCTION READ-ONLY / SERVED ARTIFACT + AUTHENTICATED E2E UNVERIFIED / NOT CLOSED.

## 23. LAST VERIFIED MEMORY EVENT — LVE-2026-10-23-473
- Scope: Loader/Picker runsheet preview parity; owner-only patch to Picker.
- Current Loader SHA: `97b83d68a683df77c1e0557838c24a1b4fb65169`; current Picker SHA: `d483bd15b36585b975b63c2ef641481a01d5d084`.
- Fresh direct Production SQL: items.description and items.image_url exist; run_sheet_details.description is absent; item and runsheet FKs are present; current status count is Picked=2.
- Defect: Picker preview remains abbreviated and uses `.select('*')`; description must be sourced through `items!run_sheet_details_item_id_fkey(description)`. Active Picking session mapping needs the matching one-line nested-description correction.
- Complete surgical owner changeset is Report471 Patches A/A2/B/C/D. Report472 is historical pointer only where it defers to earlier reports; Report471 contains complete replacement blocks.
- No operational source or Production/business data was changed. No synthetic Production data was created or deleted. The memory file itself was restored from the immediately preceding commit after an empty-content write, then this event was appended.
- Status: OWNER PATCH READY / DEPLOYMENT + BROWSER E2E UNVERIFIED / NOT CLOSED.
- Next exact action: re-fetch Picker and verify SHA, apply only missing Report471 patches, deploy using the existing frontend path, verify served HTML and Browser E2E, and confirm inventory/reservations remain unchanged.
- Report: `doc/Draft/Reprots/Report473_PICKER_PREVIEW_PARITY_SESSION_REVALIDATION_20261023.md`.


## 24. LAST VERIFIED MEMORY EVENT — LVE-2026-10-23-474
- Target: Loader/Picker runsheet preview parity. Fresh source SHA Loader `97b83d68a683df77c1e0557838c24a1b4fb65169`; Picker `d483bd15b36585b975b63c2ef641481a01d5d084`.
- Loader current refactor commit: `152e5b1d22aab94d2cf01070778b357df4701aff`, parent `e69c9af4b56d99ba29a4fa74282f78438b9f7010`. It changes the preview to responsive inline summary/cards and event-bound buttons; therefore Report471 Patch B is visually stale and Report474 Patch B supersedes it.
- Fresh direct Production SQL: items.description/image_url exist; run_sheet_details.description absent; expected item and runsheet FKs exist; current runsheet count status Picked=2 only.
- Confirmed Picker defects: abbreviated preview; no joined description; active session reads nonexistent detail.description; inline onclick interpolates DB values; unsafe image/detail HTML interpolation.
- Owner surgical patches are A/A2/B/C/D in `doc/Draft/Reprots/Report474_PICKER_PREVIEW_PARITY_REBASE_AFTER_LOADER_REFACTOR_20261023.md`. No operational source or Production schema/data changes were made. No test rows were created/deleted.
- Status: OWNER PATCH READY / SOURCE + DB CONTRACT VERIFIED / DEPLOYMENT + BROWSER E2E UNVERIFIED / NOT CLOSED.
- Next: re-fetch Picker, verify SHA, apply only missing patches from Report474, test syntax and Staging E2E; confirm no stock/reservation changes; verify Cloudflare served HTML before closure.

- Report474 self-audit: Picker has no `RW_UI` namespace, so the patch now uses a local `formatPreviewNumber()`; image URL regex literals were corrected and re-fetched. Latest Report474 commit `68d6e9555219d0c41a32145f1fbc74131a410ae7`, blob `c9025663f8ee0bb79bc2e88ae6242be38d00f25c`.



## 25. LAST VERIFIED MEMORY EVENT — LVE-2026-10-23-475
- Scope: consolidated CTO re-investigation of Loader/Picker runsheet preview parity; owner-only operational source changes.
- Source repos separated: actual app source is `papamohammed77-glitch/erp-frontend` on `main`; this repository is continuity/governance/reporting. Historical reports are references, not current truth.
- Fresh app source: Loader `companies/company-1/warehouse/loader.html` SHA `97b83d68a683df77c1e0557838c24a1b4fb65169` (332 lines); Picker `companies/company-1/warehouse/picker.html` SHA `d483bd15b36585b975b63c2ef641481a01d5d084` (1058 lines). Neither operational file changed.
- Current Loader preview refactor: commit `152e5b1d22aab94d2cf01070778b357df4701aff`, parent `e69c9af4b56d99ba29a4fa74282f78438b9f7010`. Picker history reviewed for session recovery, Idempotency-Key/operation id, quantity validation, and insufficient-stock handling; preserve these contracts.
- Production SQL read-only snapshot at 2026-10-23 12:24:37 UTC: PostgreSQL 17.6; items=18, run_sheet_details=12; items.description/image_url exist; run_sheet_details.description absent; item_id FK and runsheet_id FK present; status count Picked=2 only, no Open/Confirmed rows in the queried counts. No DDL, RLS/RPC/Edge, or business-data writes; no test rows created/deleted.
- Confirmed root causes in Picker: abbreviated preview; detail query omits joined item description; active session reads absent detail.description; inline onclick interpolates DB values; unvalidated image src and unescaped item detail HTML.
- New self-contained current owner changeset: `doc/Draft/Reprots/Report475_PICKER_PREVIEW_PARITY_CONSOLIDATED_CTO_EXECUTION_20261023.md`, report commit `53ec7826a121ef5c8767c3fb7f1b4ce7059d0ff2`, report blob `496e18243085101728fba7f15870d72b33927943`. Includes patches A/A2/B/C/D, complete replacements, bounded scope, tests and rollback. Its JS blocks B/C/D were syntax-parsed successfully. Report474 Patch D had ambiguous/broken escaping around inline onerror; do not carry that historic block forward.
- Production and deployment state: source patch not applied; Cloudflare served HTML and browser E2E unverified; current production runsheets do not offer Open/Confirmed test cases. No operational source was edited. Status: ROOT CAUSE VERIFIED / OWNER PATCH READY / NOT DEPLOYED / NOT CLOSED.
- Next exact step: owner re-fetches Picker and checks SHA. If unchanged, apply patches A→A2→B→C→D from Report475 only; test in Staging, validate syntax/UX/auth/company boundaries and unchanged stock/reservations, then compare served Cloudflare HTML and run authenticated browser E2E. Do not edit Loader, main.html, or core.js for this display issue. Do not change Production for this task.


## 26. LAST VERIFIED MEMORY EVENT — LVE-2026-10-23-476
- Report475 was amended with Patch E to preserve image-error fallback in the active Picker session after replacing `_img`.
- Final report blob SHA: `130cca676845487a4106c3252ce531e88e430eff`. It contains patches A, A2, B, C, D and E.
- JavaScript parse checks passed for replacement blocks B/C/D/E. No inline `onerror` remains in the new image/detail replacement blocks.
- Picker SHA `d483bd15b36585b975b63c2ef641481a01d5d084` and Loader SHA `97b83d68a683df77c1e0557838c24a1b4fb65169` remain unchanged. No operational source or Production data was modified.
- Owner patch is not applied or deployed. Cloudflare served HTML and authenticated Browser E2E remain unverified. Continue with Staging verification before closure.


## 27. LAST VERIFIED MEMORY EVENT — LVE-2026-10-23-477
- User required a complete CTO re-execution, full context recovery, and one consolidated owner report rather than references spread across old reports.
- Read current governance (2,606 lines), CURRENT_STATE, and memory; independently refreshed current app source, historical Picker baseline and relevant commits, and Production schema/RLS/Edge inventory.
- Single operative report: `doc/Draft/Reprots/Report477_PICKER_PREVIEW_PARITY_MASTER_CTO_REEXECUTION_20261023.md`, report commit `069f8f4ac53747675af8ae66eb8425007e0c5442`, blob SHA `1707a3dbbcac68728817aa2b67609f982159ece3`. It contains exact defective source elements plus complete patches A/A2/B/C/D/E; Patch B explicitly displays escaped item descriptions and summary totals.
- Current app HEAD `152e5b1d22aab94d2cf01070778b357df4701aff`; Picker SHA `d483bd15b36585b975b63c2ef641481a01d5d084`; Loader SHA `97b83d68a683df77c1e0557838c24a1b4fb65169`; core.js SHA `ff2f581d9900543c16f7cb026e13446520c0329d`. No operational app file was edited.
- Fresh Production read-only snapshot at `2026-10-23T14:26:56.133432Z`: PostgreSQL 17.6; items=18, run_sheet_details=12, runsheets=2; status Picked=2 only; items.description/image_url exist; run_sheet_details.description does not; item and runsheet FKs and company/permission RLS policies verified.
- Current related Edge versions: start-picking v35, complete-picking v18, cancel-picking v5, reopen-picking v9, start-loading v5, complete-loading v11; all ACTIVE, JWT verification enabled. No Production mutation was needed or performed.
- Replacement blocks B/C/D/E in Report477 were syntax-parsed successfully. This does not establish browser/runtime correctness.
- Deployment lineage remains UNKNOWN: Cloudflare Pages is documented and /picker redirects to the current path, but served HTML SHA and authenticated Browser E2E are not established. Owner source changes remain unapplied; task is NOT CLOSED.
- CURRENT_STATE was appended with the Report477 checkpoint in commit `0e06c9ccde376d842c062b5042cc7b11291bd5df`, content SHA `382e6ace2086739719e7dca13f89f8a0fba74736`.
- Next exact action: owner re-fetches Picker and checks SHA; if unchanged, applies only Report477 A→A2→B→C→D→E, runs Staging tests and confirms no stock/reservation/log delta, deploys through the approved frontend path, verifies Cloudflare-served HTML and authenticated Browser E2E, then updates state. Do not touch Loader, main.html, core.js, or Production for this display-only defect.


## LAST VERIFIED MEMORY EVENT — LVE-2026-10-23-478
- Re-read MASTER CTO governance and refreshed CURRENT_STATE and memory before examining operational source. No owner changes are reflected in the current Picker blob.
- App HEAD `152e5b1d22aab94d2cf01070778b357df4701aff`, parent `e69c9af4b56d99ba29a4fa74282f78438b9f7010`; Picker SHA `d483bd15b36585b975b63c2ef641481a01d5d084`; Loader SHA `97b83d68a683df77c1e0557838c24a1b4fb65169`.
- Fresh SQL at `2026-10-23T14:58:58.392162Z`: PostgreSQL 17.6; items=18, run_sheet_details=12, runsheets=2; status Picked=2 only; items.description/image_url exist; run_sheet_details.description absent; both expected FKs exist.
- Defects remain A/A2/B/C/D/E as documented in Report477. Report477 is still the authoritative full owner patch; Report478 records this session's fresh evidence.
- No operational source, Production schema, Edge/RPC, or business data changed. No synthetic Production data created/deleted.
- Cloudflare served artifact UNKNOWN; owner patch/Staging/Browser E2E UNVERIFIED; task NOT CLOSED.
- Report: `doc/Draft/Reprots/Report478_PICKER_PREVIEW_PARITY_CURRENT_STATE_RECHECK_20261023.md`; report commit `7051d21747913372a125ca5e660eb5d2b1db2c17`.
- Next exact action: owner verifies current Picker SHA, applies only missing Report477 patches A→A2→B→C→D→E, validates in Staging with zero inventory/reservation/log delta, then verifies served Cloudflare artifact and authenticated Browser E2E.

 
## LAST VERIFIED MEMORY EVENT — LVE-2026-10-23-481
- Resumed from CURRENT_STATE LVE-480 and independently re-fetched the current operational source and SMART ERP Production; this was read-only verification, not an application change.
- Current app HEAD remains `152e5b1d22aab94d2cf01070778b357df4701aff`; Picker SHA remains `d483bd15b36585b975b63c2ef641481a01d5d084`; Loader SHA remains `97b83d68a683df77c1e0557838c24a1b4fb65169`. Picker still has `.select('*')`, inline `onerror`, and does not contain the Report477 patch. No operational file was edited.
- Fresh read-only SQL at `2026-10-23T15:09:17.918546+00:00`, PostgreSQL 17.6: items=18, run_sheet_details=12, runsheets=2, status Picked=2 only. items.description/image_url exist; run_sheet_details.description does not; expected item/runsheet keys and relevant quantity/status columns exist.
- Current related Edge versions: start-picking v35, complete-picking v18, cancel-picking v5, reopen-picking v9, start-loading v5, complete-loading v11; all ACTIVE with JWT verification enabled. No Production schema/RLS/grant/RPC/Edge/business-data writes were performed or indicated.
- Report480 independently confirms the same Picker defect and identifies Report477 patches A/A2/B/C/D/E as the single operative owner changeset. Required FK relation for description is `items!run_sheet_details_item_id_fkey(description)`; no schema change is needed.
- Cloudflare Pages is documented and `/picker` maps to the Picker file, but served artifact SHA/deployment lineage remains UNKNOWN; Staging and authenticated Browser E2E remain UNVERIFIED.
- Status: ROOT CAUSE RECONFIRMED / OWNER PATCH NOT APPLIED / DEPLOYMENT UNKNOWN / BROWSER E2E UNVERIFIED / NOT CLOSED. No production fixtures were created/deleted.
- Next: re-fetch Picker and verify SHA; apply only missing Report477 patches if unchanged, validate in Staging with zero stock/allocated_qty/inventory_log delta, then verify Cloudflare-served HTML and authenticated Browser E2E. Do not edit Loader, main.html, core.js or Production for this presentation/query-shape defect.

## LAST VERIFIED MEMORY EVENT — LVE-2026-10-23-482

- Report481 audits the 50 report files in the Report432–Report480 window (including both Report458 files) and deeply reconciles Reports466–480.
- The current request's target is `erp-frontend/companies/company-1/warehouse/loader.html`, not Picker. Report466 originally targeted Loader; Reports467–480 drifted into a Picker preview-parity patch chain. Report477 is authoritative only for that Picker-specific task and must not be applied to Loader.
- Fresh source identities: operational repo HEAD `152e5b1d22aab94d2cf01070778b357df4701aff`; Loader SHA `97b83d68a683df77c1e0557838c24a1b4fb65169` (332 lines); Picker SHA `d483bd15b36585b975b63c2ef641481a01d5d084` (1,058 lines); Core SHA `ff2f581d9900543c16f7cb026e13446520c0329d`.
- Current Loader source already has card/search click handlers invoking `App.openRunsheet(code)`; the method loads runsheet details and renders the Picked preview inside `mainContent`, uses the active session for current user's Loading runsheet, and uses read-only rendering for other states. Therefore no code patch is justified from static source alone; served browser failure must first be reproduced.
- Reporting defects: Report473 incorrectly says Loader and Picker each have 1 line; Reports478–480 repeat unchanged source/state and continue prohibiting Loader edits for a task whose current target is Loader. Picker schema findings can be valid for Picker but are not the current Loader change request.
- No operational HTML/Core or Production change was made. Cloudflare served artifact identity and authenticated browser click behavior remain unverified.
- Exact next step: test the served Loader card and search-result click with an authorized runsheet; capture browser/Console/Network evidence; if failure is reproduced, apply the smallest evidence-backed fix to Loader only, then verify Staging/browser and zero `stock_branches.qty`/`allocated_qty`/`inventory_log` delta from opening details.
- Consolidated report: `doc/Draft/Reprots/Report481_LOADER_RUNSHEET_CLICK_DETAILS_SCOPE_CORRECTION_20261023.md`, commit `73c3f82c5a270bd97c8598eef5e6ac2778cb2e47`. CURRENT_STATE update commit: `0c421866da8d0a161cc9a53e87920a038ac5af91`.


## LAST VERIFIED MEMORY EVENT — LVE-2026-10-23-483

- Corrected the previous misinterpretation: user requested the full Loader-vs-Picker detail experience, not just card click-to-open. Required behaviors are runsheet details in the app, interactive item cards, large-photo item-detail modal, code/unit/qty/description, and parity in the active Loading item's edit modal while preserving its quantity workflow.
- Directly refreshed source: app HEAD 152e5b1d22aab94d2cf01070778b357df4701aff; Loader SHA 97b83d68a683df77c1e0557838c24a1b4fb65169; Picker SHA d483bd15b36585b975b63c2ef641481a01d5d084; Core SHA ff2f581d9900543c16f7cb026e13446520c0329d.
- Current Loader already has click handlers from run-sheet cards/search results and inline Picked preview. Missing parity: item cards in preview aren't clickable; no large item-detail modal; the active Loading editor uses a small image and lacks description/code; run_sheet_details query doesn't join image/description; Loader's list/search/open omit explicit company_id scoping and the open path lacks a guard for a Loading runsheet assigned to someone else.
- Direct Production read-only schema check confirms items.description, items.image_url, and FK run_sheet_details_item_id_fkey (run_sheet_details.item_id → items.id), while run_sheet_details itself has no description/image_url. No schema change or additional function is needed.
- Report482 is the consolidated owner-applied surgical changeset: doc/Draft/Reprots/Report482_LOADER_PICKER_RUNSHEET_ITEM_DETAIL_PARITY_20261023.md, latest commit 0845cb1590774796000196cb15e06cd27d885f15, blob 0a7518f5b90a4a077b2f19da39573640f202cbe3. It contains exact patches A–F.
- All 14 JavaScript snippets in Report482 passed syntax parsing after wrapping partial query/property snippets in their correct syntactic context. This does not constitute full-page parsing, browser tests, or deployment verification.
- No operational source, main.html, core.js, Picker, Supabase schema/RLS/RPC/Edge, or Production business data was changed; no Production test fixtures were created. Cloudflare served artifact, owner application, browser E2E, and zero-stock-delta test remain unverified.
- Next: owner confirms current Loader SHA and applies only Report482 A–F in the stated locations; parse the entire resulting script; test preview detail modal, image fallback, role/company isolation, active Loading editor, back/start flows in staging; verify unchanged stock_branches.qty, allocated_qty, inventory_log; then independently verify the Cloudflare-served file. Do not redirect task to Picker or modify main.html/core.js.
- Status: DIAGNOSIS CORRECTED / OWNER PATCH DOCUMENTED / NOT APPLIED / NOT CLOSED.


## LAST VERIFIED MEMORY EVENT — LVE-2026-10-23-484

- Scope: Loader-vs-Picker item-detail parity plus direct verification of loading completion dependencies. This event supersedes the older Loader/Picker checkpoint entries for operational recency; prior history is preserved.
- Read CURRENT_STATE.md first and read MASTER CTO governance SHA `b03feec14a417ca9032d714774f2687b4542a373` (2,606 lines). CURRENT_STATE now has an authoritative top pointer at LVE-484; the stale LVE-481 and LVE-483 headings were relabeled historical without deleting their content.
- Operational app source: `papamohammed77-glitch/erp-frontend`, main HEAD `152e5b1d22aab94d2cf01070778b357df4701aff`. Loader SHA `97b83d68a683df77c1e0557838c24a1b4fb65169`; Picker SHA `d483bd15b36585b975b63c2ef641481a01d5d084`; Core SHA `ff2f581d9900543c16f7cb026e13446520c0329d`. Report482 A–F remains unapplied.
- Report483: `doc/Draft/Reprots/Report483_LOADER_DAILY_REVALIDATION_LOADING_CONTRACT_CONFLICTS_20261023.md`, blob `c2cdb93dee417701f218bec760afd0a31a4739c3`, commit `4da0a37e02e09004b83ef08a9d73683fdf11e8ec`. It documents the daily evidence and adds safe Loader-local thumbnail Patch G; the helper snippet passed V8 syntax parsing only, not full-page or browser testing.
- Read-only Production at 2026-10-23T18:44:22Z: PostgreSQL 17.6; items=18, run_sheet_details=12, runsheets=2, stock_branches=57, inventory_log=28; runsheet status Picked=2 only. items.description/image_url and the item FK exist; run_sheet_details has no description/image_url/notes; order_details.notes exists. Authenticated UPDATE on run_sheet_details is false and no UPDATE policy exists.
- Confirmed loading contract conflict: Loader sends every item, including qty_loaded=0, and includes notes; Production complete-loading v11 rejects any loaded_qty<=0 and drops notes; complete_runsheet_loading also rejects req<=0 and does not persist notes. Actual user occurrence is unverified because no complete-loading invocation appeared in the targeted 24-hour log query and no Loading fixture exists.
- Production complete-loading v11 source differs slightly from Git snapshot `Current/Edge_Functions/complete-loading`; current repo tree has no matching `Current/Edge_Functions/start-loading` file although Production start-loading v5 is active.
- Supabase runtime logs show the published app made unscoped runsheets GETs and a select=* details GET at 2026-10-23 09:14–09:16 UTC, all HTTP 200. This matches current source query shapes but does not establish the served artifact SHA or E2E behavior.
- Deployment artifact/headers/cache and authenticated browser E2E remain UNKNOWN/UNVERIFIED. Direct Cloudflare fetch failed in this environment; no Cloudflare MCP/browser tool was available. Existing staging project `hfzznsiprnwkpayskzhu` is INACTIVE and was not restored.
- No operational app, Production schema/RLS/grants/RPC/Edge, or business data changed; no test fixture was created.
- Status: SOURCE REVALIDATED / REPORT482 NEEDS PATCH G / ZERO-QUANTITY + NOTES CONTRACT CONFLICT CONFIRMED / DEPLOYMENT UNKNOWN / E2E UNVERIFIED / NOT CLOSED.
- Next: do not apply Report482 A–F unchanged; incorporate Patch G and validate the full Loader in active isolated staging. Keep zero-quantity/notes behavior open and do not modify Production Core/Edge until the contract has a safe, tested plan.



## LAST VERIFIED MEMORY EVENT — LVE-2026-10-24-489

- Re-read CURRENT_STATE.md completely to EOF before other project actions; the starting checkpoint was LVE-2026-10-24-488. Re-read the full MASTER CTO governance file, SHA `b03feec14a417ca9032d714774f2687b4542a373`, 2,606 lines.
- Fresh operational source remains `papamohammed77-glitch/erp-frontend` / `main`, HEAD `152e5b1d22aab94d2cf01070778b357df4701aff`; Loader `97b83d68a683df77c1e0557838c24a1b4fb65169`, Picker `d483bd15b36585b975b63c2ef641481a01d5d084`, Core `ff2f581d9900543c16f7cb026e13446520c0329d`. Full current inline JavaScript parse passed for Loader, Picker, and Core; a proposed corrected Loader assembled in memory also passed full inline-script V8 parsing. No operational file was changed.
- Fresh Production snapshot at `2026-10-24 18:41:23.419779+00`: PostgreSQL 17.6, items=18, run_sheet_details=12, runsheets=2, Picked=2 only. RLS scopes runsheets/details to current company. Authenticated has SELECT but no UPDATE grant/policy on run_sheet_details.
- Confirmed contract conflict remains: Loader sends zero-quantity rows and notes; Production complete-loading v11 rejects any `loaded_qty<=0`, drops notes, and RPC `complete_runsheet_loading(uuid,uuid,jsonb,text)` also rejects zero and has no notes handling. Direct UI update to run_sheet_details ignores errors while authenticated UPDATE is denied. No Production schema/RLS/grant/RPC/Edge/business-data mutation was performed.
- Production Edge registry: complete-loading v11 ACTIVE; start-loading v5 ACTIVE. Git snapshot `Current/Edge_Functions/complete-loading` SHA `0dd221173aee7f3aa15d16202f034ae94f4104f3` differs from deployed source in JSON/code normalization; `Current/Edge_Functions/start-loading` is missing (404). Latest recorded migration is `20261021161758`; no later loading-contract repair was found.
- Corrected Report487 patch sequencing: original instruction to apply G first is invalid because its insertion anchor and modal handlers depend on E/F; original B also omitted return of the nested details Promise. Report488 supplies full replacements for A1/A2/B/D plus full image-fallback call-site replacements and specifies the corrected order. It preserves the current read-only behavior for a Loading runsheet assigned to another loader; missing explicit company filters are treated as defense-in-depth because RLS currently enforces tenant scope.
- Report: `doc/Draft/Reprots/Report488_LOADER_DAILY_REVALIDATION_PATCH_ORDER_CORRECTION_20261024.md`; current blob SHA `14f63e0526121e0e5597e12e6186101884d3fe0c`; original creation commit `e706b7545e1048bc863d800aa75ba7d7f5c72b3d`; self-contained patch addendum commit `6f2f5c4eaf1411fb347ea03cfde4cf9777eddbac`.
- CURRENT_STATE was updated append-only to LVE-489; current blob SHA `6d7a78709d86e274506761311daed6f3c82d5ca4`, initial checkpoint update commit `e80fa39f79edb01631e2e8d3e326fc1c0812996a`, latest report-fingerprint refresh commit `f8d3e1c2638668cc9745ce2e5f4f889166d6424a`. Prior checkpoints remain preserved.
- Deployment artifact and headers/cache remain UNKNOWN: Cloudflare Pages URL was inaccessible via web, Browser requires an originating browser context, and no Cloudflare MCP tool was available. Staging `hfzznsiprnwkpayskzhu` is INACTIVE and was not restored. No authenticated browser E2E or stock/reservation/log delta test ran. Targeted logs did not establish a matching Loading invocation; this absence is not proof of non-use.
- Status: SOURCE + PRODUCTION REVALIDATED / OWNER PATCH CORRECTED AND STATIC-PARSED IN MEMORY / LOADING CONTRACT CONFLICT OPEN / DEPLOYMENT UNKNOWN / STAGING + BROWSER E2E UNVERIFIED / NOT CLOSED.
- Next: owner re-fetches Loader and verifies SHA, applies Report488 to Loader only, checks full-file syntax on the saved artifact, then validates item detail/image fallback and zero stock/allocated_qty/inventory_log delta in an authorized active isolated Staging. The zero-quantity/notes/direct-save contract remains a separate blocker; do not claim production-ready loading until resolved.



## LAST VERIFIED MEMORY EVENT — LVE-2026-10-28-534 — Delivery Supervisor → Parent Assignment Display

- **Authority:** `CURRENT_STATE.md` LVE-2026-10-28-534 and Report534 are the current execution record; this ledger remains secondary continuity memory.
- **Operational source:** `papamohammed77-glitch/erp-frontend`, branch `main`; latest observed commit `8843150bdde99d36d477d6bb344a24df61dd2942`; Parent blob `0c1745081e8d17480433ed527d77cac9f5292021`; Supervisor blob `3e6db903cd7da411f9ed40a449f9ee5bece5f387`.
- **Production:** at `2026-10-28T18:57:09.323176Z`, RS-1 and RS-2 remained `Loaded` with `deliverer_id`; `delivery_agents` count remained 0. The live `delivery_logistics_query` body matched the current Git migration body exactly after whitespace normalization; migration version `20261027170454` is present.
- **Security:** relevant RPCs remain SECURITY DEFINER with authenticated/service_role EXECUTE and no anon grant; company/auth/permission checks are present in the inspected definitions. No schema, ACL/RLS, operational source, deployment, or business data was changed in this revalidation.
- **Current diagnosis:** the source renders `d.runsheet_assignments` separately and the live RPC returns that projection; source/Production contract drift is not the current proven defect. Do not repeat the Parent patch, create `delivery_agents` records to mirror assignments, change SQL/ACL, or bump Service Worker without new evidence.
- **Open gate:** exact Cloudflare-served artifact and fresh authenticated Parent DOM/Network/Console evidence remain UNVERIFIED because the available browser connector has no originating browser context and direct page fetch was unavailable.
- **Next:** a normally authenticated published Parent session must capture the `delivery_logistics_query(p_view='agents')` response, confirm RS-1/RS-2 in `runsheet_assignments`, inspect the assignment-table DOM, and capture the first Console error if the payload has rows but the table is absent. Preserve the historical MAIN1/security backlog; this event does not close it.


## LAST VERIFIED MEMORY EVENT — LVE-2026-10-29-558

- **Authority:** `CURRENT_STATE.md` LVE-558 and Report558 are the current operational checkpoint; this ledger remains secondary continuity memory.
- **Live source:** `papamohammed77-glitch/erp-frontend`, `main`, HEAD `416de1c1d829c48b7c82442242a2a039e3d7e48c`. Parent Blob `3a5d2e565a04262081d024f6e514e1372d372e84`; Returns main Blob `36c20e03c94dc734e015610dec1e8208697df32a`; PR #8 branch Blob `9cc013a419f6dac2c656471b72f0e629a622a5b6`, commit `3ad370c83f8f3c7880d7ace9ac24eabb5833f9cf`, open/draft/unmerged.
- **Returns patch:** R8-S1-A/B applied only in memory after re-fetching the exact PR #8 Blob. Each replacement anchor was unique; the resulting inline JavaScript passed V8 syntax parsing; isolated eligibility fixture excluded RS-1 (pending=0), included RS-2 (pending=5), included same-handler Returning, and excluded another handler. No operational file write occurred.
- **Production:** read-only SQL confirms RS-1 Delivered / 5 detail rows / pending 0; RS-2 Delivered / 7 detail rows / pending 5; no current Returning rows. RLS is enabled for runsheets/details; authenticated SELECT is granted; authenticated UPDATE on run_sheet_details is not granted. Active Edge functions start-return v4 and complete-return v26 were not modified.
- **New CI finding:** Main workflow Blob `7f821b2afdcb8d15f205782218b427d06da03a6e` still contains the obsolete Payroll assertion. Run `40928363996` / job `123639862789` failed on commit `0351897` before Parent JavaScript syntax validation or Playwright. PR #7's workflow-only fix remains draft/unmerged and is based on older commit `626df80fae8101fa6b1fe0ba0b6bc8d4ae69f8ca`; it has not been proven against current Parent source.
- **Deployment/runtime:** GitHub check-runs report `rawaea-erp` success on Main `416de1c` and Preview `3ad370c`; `erp-frontend`, `rawaea-store`, and `warehouse-supervisor` fail. Supabase logs at `2026-10-29T18:17:11Z` show old nested-count requests with HTTP 200, but Origin/Referer are blank. Browser connector could not access tabs without originating context; exact served bytes and authenticated E2E remain UNVERIFIED.
- **Staging metadata correction:** current live Supabase project listing reports `rawaea-staging` ref `hfzznsiprnwkpayskzhu` as `ACTIVE_HEALTHY`, replacing the older LVE-484 `INACTIVE` observation. Staging was not used or changed.
- **Mutation ledger:** no operational source, Production schema/RLS/grants/RPC/Edge functions, business data, stock/accounting, or Cloudflare configuration changed. No test data created.
- **Next:** owner applies R8-S1-A/B to the PR #8 branch after rechecking SHA/boundaries, reruns full inline-script parsing and eligibility checks, and does not merge/close until the CI gate is current, Cloudflare failure logs are understood, the served artifact is identified, and authenticated E2E passes.
- **Status:** ROOT CAUSE CONFIRMED / OWNER PATCH READY / MAIN CI GATE STALE / ARTIFACT + AUTHENTICATED E2E UNVERIFIED / NOT CLOSED.


## LAST VERIFIED MEMORY EVENT — LVE-2026-10-29-559

- **Authority:** `CURRENT_STATE.md` LVE-559 and Report559 govern the current Returns revalidation; ledger remains secondary.
- **Governance restored:** Read permanent operational constitution, Report545, LVE-558/Report558 and Report557 before investigating. Owner-only operational HTML boundary preserved.
- **Source:** `erp-frontend/main`, HEAD `416de1c1d829c48b7c82442242a2a039e3d7e48c`; Returns main Blob `36c20e03c94dc734e015610dec1e8208697df32a`. PR #8 remains open/draft/unmerged at `3ad370c83f8f3c7880d7ace9ac24eabb5833f9cf`, Blob `9cc013a419f6dac2c656471b72f0e629a622a5b6`.
- **Root cause:** main list and search do not filter Delivered runsheets by `qty_loaded - qty_delivered - qty_returned > 0`; the candidate PR fixes the core list/search quantity condition but requires R8-S1-A/B to scope Returning search results to the assigned handler and propagate nested Promise failures.
- **Production:** read-only values RS-1 pending=0, RS-2 pending=5; no current Returning rows in inspected sample. No writes or test data.
- **Deployment:** cloudflare bot recorded successful `rawaea-erp` Preview for commit `3ad370c`; three other project builds reported failure without examined logs. Exact Production artifact and authenticated E2E remain UNVERIFIED.
- **Mutation ledger:** only Report559, CURRENT_STATE, and this ledger updated in governance repository; operational repo, Production, and Cloudflare config untouched.
- **Next:** owner patch R8-S1-A/B on PR branch only, rerun syntax/isolated eligibility tests, inspect relevant build logs, verify exact served artifact and authenticated E2E; do not merge/close early.


## LAST VERIFIED MEMORY EVENT — LVE-2026-10-29-560

- **Authority:** `CURRENT_STATE.md` LVE-560 and [Report560_RETURNS_ELIGIBILITY_OWNER_PATCH_DEPLOYMENT_RECHECK_20261029.md](doc/Draft/Reprots/Report560_RETURNS_ELIGIBILITY_OWNER_PATCH_DEPLOYMENT_RECHECK_20261029.md), report commit `8e60085e6e6e184b0b0ff4b5f35864a7301d2fe6`.
- **Governance:** read permanent operational constitution SHA `365a5178810d8da37f55dba64bf422f328a966bd` and Report545 SHA `e153396709ecfcc0552347db84e37c98ad8bcdd6`. Operational HTML ownership rule remains active.
- **Source:** `erp-frontend/main` HEAD `416de1c1d829c48b7c82442242a2a039e3d7e48c`; Returns main Blob `36c20e03c94dc734e015610dec1e8208697df32a`; Parent Blob `3a5d2e565a04262081d024f6e514e1372d372e84`; Driver Blob `d7ace0b9be52c936aee1d5f5e1250b6d2e9a48f0`.
- **Root cause:** current Returns main list loads every `Delivered` runsheet, omits `qty_returned` from detail projection, counts rows by `qty_loaded > qty_delivered`, and never filters `available` by outstanding return quantity. Search lacks both remaining-quantity filter and Returning assignment scope.
- **Candidate:** PR #8 is open/draft/unmerged at commit `3ad370c83f8f3c7880d7ace9ac24eabb5833f9cf`, Returns Blob `9cc013a419f6dac2c656471b72f0e629a622a5b6`. Core list patch exists on this branch only. Report560 reproduces owner-only R8-S1-A/B: add `return_handler_id` to search select; return nested details Promise and filter Delivered by positive remaining and Returning by current handler.
- **Production read-only:** `2026-10-29 19:03:17.860357+00`, PostgreSQL 17.6; `RS-1` Delivered, 5 detail rows, pending return 0; `RS-2` Delivered, 7 detail rows, pending return 5; no Returning/Returned sample rows. No business data, schema, RLS/ACL, functions, stock, or accounts were changed.
- **Cloudflare:** dashboard shows Production Main `416de1c` at `https://b469734c.rawaea-erp.pages.dev/` and PR #8 Preview `3ad370c` at `https://da5fcdde.rawaea-erp.pages.dev/`. Exact artifact bytes and authenticated Parent → Driver → Returns E2E remain UNVERIFIED.
- **Isolated test:** synthetic in-memory predicate check passed (exclude Delivered pending=0; include pending>0; Returning only when assigned to current user; reject other state/handler). This did not alter source or DB and is not full-file syntax or E2E verification.
- **Mutation ledger:** only Report560, CURRENT_STATE and this ledger changed. No operational HTML, PR branch, Production, or Cloudflare settings changed.
- **Next:** owner re-fetches PR #8 and verifies current Blob SHA/unique anchors before applying R8-S1-A/B on that branch only; run full inline-JavaScript syntax and eligibility tests, investigate actual failed build logs, prove served artifact identity and authenticated E2E before merge/closure.
- **Status:** ROOT CAUSE CONFIRMED / OWNER SEARCH PATCH REQUIRED / PRODUCTION READ-ONLY / ARTIFACT + AUTHENTICATED E2E UNVERIFIED / NOT CLOSED.


---

## LVE-2026-10-30-562 — Data Entry Master App candidate and Production ACL gate

- Read CURRENT_STATE first, the permanent operational constitution, Report545, Report500, Report560, Report561, and the current operational source. CURRENT_STATE previously had LVE-560 at the top while LVE-561 existed later in the same file; LVE-562 is now promoted to the opening checkpoint, preserving history.
- Operational repository: `papamohammed77-glitch/erp-frontend`, `main`, latest observed HEAD `2e9777a23f44e1b009810c0936513a76e64cc741`. Parent `main.html` Blob `3a5d2e565a04262081d024f6e514e1372d372e84`; shared `core.js` Blob `ff2f581d9900543c16f7cb026e13446520c0329d`.
- Studied Parent `RW_Items` module (approx. lines 4881–6740): list, filters/sort/pagination, 3-panel item form, category modal, product image viewer/upload, movement report, branch matrix, and Excel/CSV stock adjustment. Existing `picker.html` / `loader.html` are integration references, not an officially documented “golden/diamond” registry. Do not invent a formal gold-app list.
- Candidate `/mnt/data/data.html`, SHA-256 `131b6655155ed353d7d1f766a0efc5b2b07de1579c406b60cbc5eb1ca1d9dd05`, 82,081 bytes. Intended canonical path `companies/company-1/warehouse/data.html`; current repo uses lowercase `warehouse/`, and no uppercase `Warehouse/` directory exists. Candidate reuses `core.js`, current manifest/service worker, and existing Edge Functions; no direct browser writes to business tables and no new Edge function/table.
- Static HTML parse and Node inline-JavaScript syntax check PASS; static contract checks PASS. No browser E2E, deployment, operational HTML commit, or Production write occurred.
- CRITICAL CONFIRMED Production ACL exposure: read-only SQL showed anon has `TRUNCATE` on `items`, `categories`, and `branches`; authenticated also has `TRUNCATE` on those tables. RLS is enabled but does not restrict TRUNCATE. The `categories` policy `Allow all for all` applies to `{public}`, command `ALL`, `qual=true`; anon also has category DML privileges. No destructive test or grant/RLS change was made.
- Existing `save-item` v15 contract converts `reorder_point=0` to 5 due `Number(item.reorder_point) || 5`; candidate blocks zero to avoid silent mutation. Category update payload preserves `parent_id`, `image_url`, and `icon`. Bulk adjustment preview rejects nonzero inventory deltas where item cost is not configured and retains the operation fingerprint for safe retries.
- Governance: operational HTML remains owner-applied. Report562 records exact minimal Parent menu/action insertion and all evidence. Do not deploy the candidate until the ACL issue is reviewed and safely remediated with consumer impact and rollback checks.
- Authoritative report: `doc/Draft/Reprots/Report562_DATA_ENTRY_MASTER_APP_OWNER_HANDOFF_20261030.md` (report commit `20392c386cd8b125358875cb5ef8208ef3640bf5`). CURRENT_STATE update commit: `75172e727da21f98f4c89621eb806e290046bc76`.
- Status: `CANDIDATE GENERATED / STATIC PASS / CRITICAL ACL BLOCKER OPEN / OWNER PATCH PENDING / NO PRODUCTION MUTATION / NOT PRODUCTION READY / NOT CLOSED`.


## LAST VERIFIED MEMORY EVENT — LVE-2026-10-30-565

- **Authority:** Governance `CURRENT_STATE.md` LVE-565 and `Report565_RETURNS_LIVE_RECHECK_DEPLOYMENT_AND_DATA_EFFECTS_20261030.md`; this ledger is secondary.
- **Operational source:** `papamohammed77-glitch/erp-frontend`, `main`, HEAD `5745f36cd1e4e3707b84cead4d35aaf8a9882e75`. Returns Blob `16d02fff2d00759451879204abf218202898f9c0`; app router Blob `ec75f89c11620f6e8b8ef5996cf1a3289dcf20b4`.
- **Source status:** Owner commits `671a4cf` and `5745f36` now contain the Delivered pending-quantity filter, matching search filter, Returning assignment restriction, preview quantity logic, UUID identity, image relation/helper, and query error handling. Inline JS parsing PASS. No Browser E2E.
- **PR #8:** still open/draft/unmerged at `3ad370c83f8f3c7880d7ace9ac24eabb5833f9cf`; its branch does not contain the current Main search/image updates. Do not merge or reapply its old patches.
- **Production return event:** RS-2 completed on 2026-10-30 at 17:29:06Z; loaded 6, delivered 1, returned 5. Edge start/complete calls HTTP 200. One Posted credit note 528.00, balanced journal 528.00/528.00, five SalesReturn inventory movements, and 12/12 projection groups match. RS-1 is Delivered but has pending=0; RS-2 is Returned; no active Returning row.
- **Deployment:** last recorded Cloudflare source commit `9e3fe134` is four commits behind current Main. Its Returns blob lacks the new pending filter. Current served artifact, headers, and build lineage remain UNVERIFIED; the successful backend event does not prove which UI build was served.
- **Workflow contract:** authenticated UPDATE on `run_sheet_details` is not granted and no UPDATE RLS policy exists. `saveReturnItem` still attempts that update and ignores the result; drafts are device-local until `complete-return` commits through `complete_sales_return_credit_note_atomic`.
- **Cancellation:** `cancelReturn` does not delete Dexie `localChanges`; later sessions reload them. Whether cancel should preserve or discard is UNKNOWN and requires owner decision.
- **Security:** categories still has public ALL true/true; stock_discrepancies has public SELECT/INSERT true; anon/authenticated TRUNCATE privileges remain on sensitive operational tables. Critical ACL gate remains open; no grants/RLS changes.
- **Mutation ledger:** only Report565, CURRENT_STATE and this memory ledger changed. No operational source, PR, Cloudflare, Production schema/permissions/functions, business data, stock or accounting were changed.
- **Next:** verify Cloudflare Production commit/build lineage and served Returns/core bytes plus headers against Main `5745f36`, then authenticated read-only Browser E2E. Do not merge PR #8.
- **Status:** SOURCE PATCH PRESENT / BACKEND RETURN TRANSACTION CONFIRMED / DEPLOYMENT + UI E2E UNVERIFIED / LOCAL CANCEL-DRAFT INTENT OPEN / CRITICAL ACL BLOCKER OPEN / NOT PRODUCTION READY / NOT CLOSED.

## LAST VERIFIED MEMORY EVENT — LVE-2026-10-31-568 — Parent Realtime Authorization Contract

- **Authority:** Canonical `CURRENT_STATE.md` LVE-568 and Report568. The operational source repository's separate handoff remains Phase 3 Parent channel compatibility; it is newer than the former canonical LVE-567B checkpoint but predates the current operational HEAD.
- **Live source:** `papamohammed77-glitch/erp-frontend`, `main`, HEAD `65799d282acc79359b17a1a13dcd68f62859e1fb`. Parent blob `53b5a9e9d0433a785c3d5471a9c0d68c25497882`; Core blob `a95ee6b29ff54b4a240ce4b81f9a535aa87686db`.
- **Parent Realtime:** 11 direct `.channel()` call sites are present, while the operational handoff records 8. Four current channels are incompatible with Production: Sales Decision and Loyalty are not published and explicitly deny authenticated table access; Customer Payments and Commission are published but service_role-only. Parent does not load core.js, use RW_Realtime/get_my_effective_profile, or provide focus/visibility refresh for these modules.
- **Read APIs:** Sales Decision v1, Loyalty v1, and Customer Payment v2 Edge sources match active Production sources byte-for-byte. Commission v3 is active with JWT verification but has no source file in either GitHub repository.
- **Permission mismatch:** Production get_my_effective_profile merges users.permissions, roles.permissions, and role_permissions. Core uses it; Parent login reads only users.permissions, while session restore uses JWT metadata or defaults to `['*']`. Several Edge/RPC permission checks omit role_permissions. Production has 21 role_permissions rows across 3 roles; at least one active user relies on role_permissions alone for finance, orders, pos, purchases, and warehouse. Actual account behavior was not tested.
- **Production:** Realtime publication has 81 tables. Migrations 20261031153418 and 20261031171715 are applied but absent from the operational `supabase/migrations` directory. Inventory-count tenant policy remains scoped; inventory_counts has zero rows; no active authenticated Counter user exists; active auth-linked users are in one company only.
- **CI/runtime:** Four workflows on current HEAD passed, but no authenticated Parent Realtime E2E ran. Earlier Warehouse Vouchers Browser E2E run 41217489614 failed on commit 8140235 and was not rerun on 65799d2. Cloudflare artifact, browser event delivery, and two-company isolation remain UNVERIFIED.
- **Mutation ledger:** Read-only Production inspection and GitHub reads only. No operational source, Production schema/RLS/grants/publication/Edge deployment, business data, stock, accounting, or Cloudflare configuration changed. Report568, canonical CURRENT_STATE, and this ledger were updated only.
- **Next:** reconcile Parent and Edge Function authorization with the effective-profile contract including role_permissions, and version-control the active Commission v3 source. Then prepare the owner-applied surgical Parent refresh patch using the existing authenticated Edge read APIs; do not weaken RLS or broaden publication.
- **Status:** FOUR DIRECT CHANNEL CONTRACTS INCOMPATIBLE / PERMISSION RESOLVER DIVERGENCE CONFIRMED / COMMISSION SOURCE PROVENANCE GAP / DEPLOYMENT + AUTHENTICATED E2E UNVERIFIED / PHASE 3 OPEN.

## 14. BUYER PURCHASING WORKFLOW — LVE-2026-10-31-569
- Current operational Buyer: companies/company-1/purchasing/buyer.html, blob 6ba510cff5250ba196528b14237ae400e544771a, 137 lines; three tabs only (orders/new/suppliers). Realtime purchase_orders integration exists in source, but authenticated browser E2E and Cloudflare served artifact are unverified.
- Production save-purchase-order v7 (verify_jwt=true, SHA-256 8e8c419c94796d8b802976ff8f3bb9717c039a8701a1523736cb531b2cc6a6cd) matches canonical Current/Edge_Functions/save-purchase-order blob ade8ae3b34b55c00bb8c2e9986e2ec5b72013574 byte-for-byte. That canonical source is not present in operational repo tree. Buyer still sends legacy {orderHeader,itemsList} rather than {operation,payload}.
- Critical open authorization findings: Edge v7 validates JWT/company but does not check business permissions before service_role operations; purchase_get_dashboard(uuid) is SECURITY DEFINER with PUBLIC/anon/authenticated EXECUTE and no auth-bound company check; get_my_effective_profile includes role_permissions but app_private.current_user_has_permission omits them, while suppliers/items RLS relies on that helper.
- Critical PR defects: purchase_submit_request_atomic writes nonexistent changed_by/changed_at columns although purchase_status_history has action/actor_email/created_at and an existing trigger already writes history. purchase_create_request_atomic and purchase_create_invoice_atomic item lookups need company_id guards.
- Existing purchase backend supports PR/RFQ/quotation/PO/invoice/returns/payments/reports. Direct purchase invoice can be created without PO and posted through central stock movement, journal, and supplier ledger. Existing settings: require_inventory_on_invoice=true, require_receiving_before_invoice=false.
- Confirmed missing contracts in current schema/UI: PO expected delivery date/payment terms/send/approval operation; supplier email/A-B-C rating/visits; buyer-specific custody ledger; explicit transfer payment method; OCR operation. PR details lack department_id and received_qty; receipt qty is on PO details. No supplier visit/rating or dedicated buyer custody table found in inspected public schema.
- Production data snapshot during audit: PR 0; PO 1 Draft; invoices 3; quotations 0; payments 0; returns 0; status_history 5.
- Report: doc/Draft/Reprots/Report569_BUYER_PURCHASING_WORKFLOW_FORENSIC_AUDIT_20261031.md.
- No app, Edge, RLS/ACL/RPC, migration, business-data, stock, accounting, or deployment change was made. Continue with backend authorization and contract repair before expanding Buyer UI. Treat Report569 as an audit checkpoint, not task closure.


## LVE-2026-11-01-571 — Buyer Purchasing Integration / Production Contracts

- Buyer file directly modified in papamohammed77-glitch/erp-frontend: companies/company-1/purchasing/buyer.html. Six-tab controller now calls the existing save-purchase-order Edge contract; no direct Supabase table queries in Buyer. Shell, CSS, shared core, main.html and other operational apps were not modified.
- Buyer source blob: 8da37a94b24c86d4bba65fab81273263e6306eae. Latest operational HEAD at verification: c886554765af5b473513ab4d8ca25ce01145ce56.
- save-purchase-order Edge v11 ACTIVE, verify_jwt=true, deployed SHA-256 c5e0dd68dd3bf42cd8271fd3a9672d9a09c512df7036e4553d464e527e9615aa; exact byte match with Git source.
- Nine Production migrations applied and committed under supabase/migrations: company-scoped PR/Invoice/Quotation item lookup; dashboard anon/tenant/permission guard; supplier effective permissions; PR Submitted state and status history fixes; actor attribution; PO status history trigger; Receiver actor; audit_log receive action; wildcard permission alignment.
- Rollback-only SQL tests passed: PR submit/approve/reject/RFQ conversion, RFQ send, quotation create/accept/convert, PO creation, Receiver receipt with +1 stock effect and correct audit actors, direct invoice Draft with no stock/journal effect, supplier RPC, and dashboard anon denial/service-role success.
- All QA test writes rolled back. Final QA residue counts are zero; business entity counts match Report569 baseline.
- Buyer supports Today, Suppliers, PR, PO, Custody placeholder, Account; quick purchase only creates Draft invoice. Supplier visits/ratings/classification/email, custody ledger, PO manual create/send/approval/expected delivery/terms, direct no-PO receiving, OCR/camera and payment method are still open contracts.
- Lists are capped at 500 rows and client-side search; server pagination/search remains open.
- Report: doc/Draft/Reprots/Report571_BUYER_PURCHASING_INTEGRATION_EXECUTION_20261101.md (commit 6c9fc6e48c8009fd551ad31c027e4e5eee8d5c49).
- NOT VERIFIED: Cloudflare served artifact, authenticated browser E2E, multi-user HTTP Edge permission tests, and live PR/RFQ/PO Realtime.
- Next priority: define and implement PO expected-delivery/terms/approval/supplier-dispatch contract without bypassing Receiver or accounting/inventory controls.


## LVE-2026-11-01-572 — Buyer Realtime / Effective Permission / Edge Dispatch Repairs

- Verified operational repo `papamohammed77-glitch/erp-frontend`, branch `main`, HEAD `511efd0cd032183515e5834027abe949d9e55649`.
- Current Buyer blob `996bb04ebe6e3c8b34586e2cef2c52ec01400fbb`; app router `companies/company-1/app.html` blob `2e47a68fe83956e27d569e786a08dcee91af2924`; Buyer shared Core `core.js` remains `a95ee6b29ff54b4a240ce4b81f9a535aa87686db`.
- Buyer now subscribes through existing RW_Realtime to 12 published purchasing/master-data tables; reconcile interval 30s; cache invalidation maps events to Today/Suppliers/PR/PO/Account. The realtime connection indicator is implemented. This is source/configuration confirmation only: actual websocket SUBSCRIBED and event delivery remain UNVERIFIED until authenticated browser E2E.
- Buyer PR approval/rejection actions now appear for Submitted and PendingApproval; label changed to "مرسل للاعتماد".
- SAVE_SUPPLIER Edge preflight no longer invokes the RPC before the call helper/data variables are declared. Execution is after declaration and authorization. Source commit `91c1a20a90cd6372a811d7b8f46095aa2548b3d8`.
- Existing `save-purchase-order` Production is now v12 ACTIVE, verify_jwt=true, SHA256 `4748aede3bd45c6fce4b251408f4ca91a6368e7abeae36a3d87e182e4e723d37`; deployed `index.ts` exact-byte-matches operational Git blob `508aee8b7941ef3d631d4a61ab60e336f1ed8836`. No direct HTTP invocation was available; authenticated SAVE_SUPPLIER runtime remains UNVERIFIED.
- `app.html` now calls `get_my_effective_profile()` and routes on merged `users.permissions`, `roles.permissions`, `role_permissions`, `active_warehouse_role`, `isOwner`; errors fail closed instead of using stale JWT permission metadata. Commit `9016396ab29c88a9014ecff9f602ed94c50c7023`. Parent main.html was deliberately not edited (owner-only handoff).
- Applied six new Production migrations and committed exact SQL files to operational repo:
  1. `20261031230252_buyer_realtime_read_permission_alignment_20261101`
  2. `20261031230550_buyer_purchase_views_use_caller_rls_20261101`
  3. `20261031230557_buyer_purchase_requests_remove_end_user_truncate_20261101`
  4. `20261031230603_buyer_purchase_remove_end_user_truncate_grants_20261101`
  5. `20261031230748_buyer_purchase_reporting_views_revoke_anon_select_20261101`
  6. `20261031231142_buyer_purchase_trigger_functions_pin_search_path_20261101`
- RLS SELECT for suppliers/items/branches/stock_branches is aligned to effective purchase permission while retaining company scope and previous operational grants; no end-user INSERT/UPDATE/DELETE grants were opened.
- Three purchase reporting views now use security_invoker; anonymous SELECT revoked. Supplier-ledger policy includes effective purchases permission within tenant scope. TRUNCATE grants now zero for anon and authenticated across inspected purchase tables/views. Both purchase trigger functions have empty pinned search_path; their 7+7 triggers remain enabled.
- Read-only rollback tests: role_permissions-only purchaser profile includes purchases and can read company rows (supplier balance 4, invoice aging 3, items 30, stock rows 57); direct purchaser likewise sees expected rows; anon supplier/items/branch/stock returns zero/denied. No production business data, stock, or accounting rows were changed.
- Inline JS syntax parse succeeded for Buyer (48,979 chars) and app router (8,181 chars). This is not E2E.
- Missing business contracts remain OPEN: PO expected delivery/payment terms/approval/supplier dispatch; supplier email/A-B-C/rating/visits/GPS/photo/voice; independent Buyer custody and settlement; payment_method in post_payment RPC; supplier invoice number persistence and direct no-PO receiving/OCR; PR department/received remainder; server pagination/search over 500-row cap.
- Cloudflare Pages artifact and authenticated browser E2E remain UNVERIFIED. Browser tab showed login screen; available browser control was read-only. Realtime publication and RLS compatibility are confirmed, not actual websocket event delivery.
- Security Advisor no longer reports SECURITY DEFINER view warning for the three purchase views or mutable search_path for the two purchase trigger functions. System-wide warnings remain (24 RLS-without-policy INFO, 1 mutable search_path outside purchases, 19 anon SECURITY DEFINER, 121 authenticated SECURITY DEFINER, leaked-password protection disabled); do not claim global security closure.
- Detailed Arabic report: `doc/Draft/Reprots/Report572_BUYER_REALTIME_AND_ROUTER_PERMISSION_REPAIR_20261101.md`, latest report commit `53789915a414fcbd3caea851a788653aab55e599`.
- Realtime coverage limit: RW_Realtime subscribes INSERT/UPDATE only. Buyer’s 12 channels do not independently include all detail/history tables (e.g. purchase_request_details, purchase_rfq_details, purchase_quotation_details, purchase_invoice_details, purchase_payment_allocations, purchase_return_details, purchase_status_history). A detail-only change or DELETE is not guaranteed to trigger immediate UI refresh; parent-row change or 30s reconcile may refresh later. Live WebSocket remains UNVERIFIED.
- Status: `PARTIAL REPAIRS CONFIRMED / EDGE v12 BYTE-MATCHED / RLS READ CONTRACTS HARDENED / SOURCE REALTIME WIRED / DEPLOYMENT + WEBSOCKET RUNTIME UNVERIFIED / BUSINESS CONTRACTS OPEN / NOT CLOSED`.



## LVE-2026-11-01-573 — Buyer Custody / Auth / Realtime / Tailwind

**Verified at:** 2026-11-01 Africa/Cairo.  
**Operational repo HEAD:** `papamohammed77-glitch/erp-frontend/main` — `1db1db2927005d12a1531b7518d103c4c7b8140f`.  
**Production Edge:** `save-purchase-order v18 ACTIVE`, `verify_jwt=true`, exact source byte match; deployed SHA-256 `e9fab386b72cc9e3d10b49931324117dea1e2df6828cb50d9e8d010e0923996f`.

### Root cause and repair
- Browser console's `PURCHASE_AUTH_REQUIRED` was traced to `purchase_get_dashboard` checking `current_setting('request.jwt.claim.role', true)`. Under the service-role RPC context that setting was NULL while `auth.role()` returned `service_role` and `auth.uid()` was NULL. The old test misclassified service_role as a normal authenticated user and raised `PURCHASE_AUTH_REQUIRED`.
- The function now uses `auth.role()`; direct service-role dashboard test passes. Authenticated `finance_manager` dashboard test also passes.
- Edge `GET_SUMMARY` now calls the RPC using the caller JWT through `profileClient`, retaining user/company/effective-permission checks rather than using service_role for this read.
- Edge v18 dispatch and role gates include `finance` and `finance_manager` for custody administration and the required Buyer read surfaces.

### Buyer employee custody contract
- Added `buyer_custodies`, `buyer_custody_expenses`, `buyer_custody_settlements` with RLS and company/employee scope.
- Workflow: finance records manual issuance; employee acknowledges receipt; employee submits PDF/image expense documents; finance approves/rejects; settlement waits until all submitted expenses are reviewed and the full unspent cash is manually received/recorded.
- Enforced currency consistency, complete cash reconciliation before closure, and separation of duties (no self-approval or self-settlement).
- New SECURITY DEFINER RPCs are executable by authenticated only; anon execute is false. Direct authenticated INSERT/UPDATE/DELETE on custody tables is false; SELECT is RLS-scoped.
- Storage uses private `employee-documents`; path policies were corrected to qualify `storage.objects.name` (avoiding ambiguity with `users.name`), and an owner-only cleanup policy was added. Finance/finance_manager can read company custody documents.
- Full SQL workflow test (issue 100 SAR → employee document metadata insert → expense 40 SAR → finance approval → cash return 60 SAR → settlement balance 0) passed inside ROLLBACK. Employee and finance document SELECT policy checks both passed. This validates SQL/RLS metadata path, not real browser binary upload/download or Storage API delete.
- Buyer tab now supports employee submission and finance issue/review/settlement. Accountant and Finance Manager screens link to Buyer custody workspace. Parent `main.html` was not modified.

### Realtime and Core
- Buyer now subscribes to 26 tables covering PR/RFQ/quotation/PO, detail rows, invoices/payments/returns, history/attachments/document links/settings, custody, suppliers/items/branches/stock.
- Production query confirms all 26 tables have RLS enabled, authenticated SELECT, a SELECT/ALL policy, and membership in `supabase_realtime`.
- Shared `core.js` blob: `f4c6a0df441e0da9105d4fe7ce94ad2d7a1735e1`; normalizer supports per-table event selection while default remains INSERT/UPDATE.
- Buyer debounce 400ms; reconcile 15s; tab-specific invalidation; MutationObserver drains pending refresh after modal closure.
- DELETE is not subscribed; it is caught by reconciliation, so DELETE is not guaranteed instant. Live authenticated WebSocket delivery/reconnect E2E remains UNVERIFIED.

### Production CSS and source
- Buyer no longer references `cdn.tailwindcss.com`; it links local `buyer.tailwind.css` (blob `25b1b840e0a03c42d3de2593b08baf6af95d0f4b`, 15,038 chars).
- GitHub Actions workflow `.github/workflows/buyer-tailwind-build.yml` compiles CSS; build commit `1fa7a3d73dc73645b1dc88b2ad33c41ecfe37bec`.
- Buyer blob: `ee2fb5676a99a9c17371b3a7f44ab0b2bb320506`.
- Edge source blob: `6d6b6ce45a18e6275f043b6e397da528d2c58124`.
- Accountant blob: `74794dd24277eac92c652061b2540d5cb772425e`.
- Finance Manager blob: `db8a5c4ef7029833ec7777dd4f992f737475e85f`.
- Static JavaScript parse passed for Buyer, Core, Accountant and Finance Manager.
- Eight new migrations are applied and committed under operational `supabase/migrations/`, versions from `20261031233331` through `20261031235057` covering custody, publication, separation of duties, finance-manager permissions, dashboard auth.role, storage path policies, and currency/reconciliation.

### Unverified and open
- Cloudflare Pages served commit/artifact and local CSS delivery remain UNVERIFIED.
- Authenticated browser E2E, real Storage API file upload/download/delete, live WebSocket events and reconnect remain UNVERIFIED.
- Core only emits INSERT/UPDATE; DELETE refresh is periodic (15s), not instant.
- Business contracts still OPEN: PO expected delivery/payment terms/approval/send, supplier email/grade/rating/visits, payment_method in payment RPC, supplier invoice number persistence, direct no-PO receiving/OCR, PR department/received aggregates, and server-side paging/search beyond 500.
- Security Advisor still has system-wide findings outside this task: 24 RLS-enabled/no-policy INFO, 1 mutable search_path outside Buyer, 19 anon SECURITY DEFINER, 121 authenticated SECURITY DEFINER, leaked-password protection warning. Do not claim global security closure.

**Arabic report:** `doc/Draft/Reprots/Report573_BUYER_CUSTODY_AUTH_REALTIME_TAILWIND_20261101.md` (report commit `18577462ab54f7cf3f1dc8f9b4b42161f2730330`).  
**Status:** `PARTIAL REPAIRS CONFIRMED / ROOT CAUSE CONFIRMED / CUSTODY SQL+RLS ROLLBACK-TESTED / EDGE v18 BYTE-MATCHED / 26 TABLES RLS+PUBLICATION VERIFIED / TAILWIND CDN REMOVED FROM SOURCE / CLOUDFLARE+RUNTIME E2E UNVERIFIED / BUSINESS CONTRACTS OPEN / NOT CLOSED`.


---

## LVE-2026-11-01-574 — Buyer Currency / Modal Parity / Custody & PO Accounting

**Verified date:** 2026-11-01 Africa/Cairo.  
**Operational repository HEAD at checkpoint:** 488dfe79f6d9291e649ee0db78d1ffb3af70e91a.

- Production database SMART ERP company currency is EGP. The observed Cloudflare Production dashboard snapshot was still serving commit 1db1db2, whose Buyer source used SAR as a currency fallback. This explains the SAR display as a stale deployed Buyer artifact, not a parent app_settings value. The current Buyer source removes the SAR fallback and refreshes GET_SETTINGS before currency-sensitive supplier, PO, custody issue and account flows. Latest deployment of 488dfe7 remains unverified.
- Buyer source updated in commit 1904b620a62a6e8b07234752caf6d27ad934be0d; blob 6c26444fa80b198d305727b70791f400839a6f75. Inline JavaScript syntax parse PASS (100,666 chars). Supplier modal, purchase invoice draft modal and new PO modal are present; source-level layout/fields reviewed against parent main.html. Parent main.html was not modified.
- Database migration 20261101120225_buyer_currency_po_receipt_and_supplier_balance_reconciliation_20261101 applied to SMART ERP and saved in operational repo under supabase/migrations/20261101120225_buyer_currency_po_receipt_and_supplier_balance_reconciliation_20261101.sql. It enforces app_settings currency on invoice creation, prevents PO-linked invoice posting from duplicating stock and supplier liability already recorded by receiving, revalidates custody invoice/receipt line details at finance approval, and synchronizes suppliers.accounts_payable from supplier_ledger via a restricted app_private trigger.
- Custody workflow includes original cash issue, additional treasury-backed advances, employee acknowledgement per advance, supplier invoice + warehouse receipt documents, finance approval/payment journal and supplier-ledger debit, and exact cash-return settlement. Additional advances increase issued_amount and are not spendable until acknowledged. Authenticated end-to-end execution of this full top-up path and real Storage binary upload/download was not completed because no authenticated employee/finance browser session was available; do not claim it was tested.
- SQL rollback E2E PASS for PO fixture → warehouse receiving → linked invoice posting. PO header/details were inserted directly inside the rollback transaction; authenticated CREATE_PO RPC/UI was not exercised: SAR rejected; EGP accepted; stock quantity changed 1→2 on receiving and remained 2 after invoice posting; supplier accounts_payable and supplier_ledger both changed 0→10 on receiving and remained 10 after invoice posting; one receiving journal remained one (no duplicate posting). Entire transaction rolled back.
- Supplier accounts_payable vs ledger read-only precheck: 4 suppliers, 0 mismatches. Test residue query: 0 E2E PO, invoices, receiving, custody, expenses or Storage objects.
- Custody invoice approval currently requires PO-matching unit price with zero discount/tax until tax/discount accounting mappings are designed. Mismatches are rejected rather than silently posting an unsupported difference.
- Arabic report: doc/Draft/Reprots/Report574_BUYER_CURRENCY_MODAL_PARITY_CUSTODY_PO_ACCOUNTING_20261101.md (commit 6e844f1f7557484178b40b4e3bc82f1478eeb161).
- Current open gates: verify Cloudflare production deployment and live Buyer artifact; authenticated browser E2E for supplier/PO/invoice/custody top-up; real Storage API binary operations; tax/discount PO accounting design. Status remains PARTIAL / NOT CLOSED.


---

## LVE-2026-11-01-575 — Buyer Production Recheck / Migration Lineage / RLS / Supplier AP

**Verified date:** 2026-11-01 Africa/Cairo.
**Operational repo:** papamohammed77-glitch/erp-frontend, main, HEAD 488dfe79f6d9291e649ee0db78d1ffb3af70e91a (unchanged from LVE574).
**Buyer blob:** 6c26444fa80b198d305727b70791f400839a6f75.
**Edge source blob:** 49c85a4a4648bcef6892476d92037ca56745f633.
**Production:** SMART ERP fiilmooggumokxanwiyx; app_settings.currency = EGP.
**Production Edge:** save-purchase-order v21 ACTIVE, verify_jwt=true, deployed SHA-256 dab3eba49dd355080cadaa5bca4aea02056de19c4b6f3ba581f142cccfa0ea8c. The retrieved deployed index.ts matched current Git content exactly (21,007 chars).

### Confirmed current contracts
- Buyer CREATE_INVOICE calls save-purchase-order operation CREATE_INVOICE; Edge calls purchase_create_invoice_atomic_v2; Production wrapper delegates to purchase_create_invoice_atomic, which enforces company system currency from app_settings. Production has currency EGP.
- Buyer manual CREATE_PO calls purchase_create_po_atomic using caller JWT. Production function exists, checks active user/company/effective purchases permission, idempotency, supplier/branch, app currency and status history.
- Production custody add-advance / employee-acknowledgement / expense submit / finance review / settlement RPCs exist and were inspected. Add advance posts treasury accounting and increases issued_amount; employee must separately acknowledge the additional advance before it becomes spendable.
- Custody tables have RLS, authenticated SELECT only and no direct end-user DML/TRUNCATE ACL. purchase_requests, purchase_invoices and purchase_invoice_details have anon/authenticated TRUNCATE denied.
- Read-only supplier check: 4 suppliers, stored AP total 3,970 equals supplier_ledger net total 3,970; zero stored-vs-ledger mismatches.
- buyer_custody_payments currently has zero rows and no orphan/cross-company references in the snapshot.

### New conflicts and security findings — do not patch speculatively
- Migration lineage conflict: Production records custody/auth migrations at versions 20261031233331..20261031235057, while current Git migration directory has corresponding logical files renumbered as 20261101010000..20261101018000. Production also records 20261101003853, 03952, 05159, 05218, 05616, 05849, and 10224, with no same-version/name SQL files in the inspected current migration directory. Production functions purchase_create_po_atomic and buyer_custody_add_advance_atomic were not defined by the inspected current Buyer migrations. Do not run supabase db push or new migrations until every applied version maps to its exact source file/blob/commit or its absence is explained.
- Production policy buyer_custody_payments_scoped_select contains c.company_id = c.company_id, a tautology rather than a correlation to buyer_custody_payments.company_id. Malformed policy predicate is confirmed; actual cross-tenant exposure is unverified because the table is empty and effective RLS context also applies.
- supplier_ledger has two active AFTER INSERT/UPDATE/DELETE triggers writing suppliers.accounts_payable: app_private.sync_supplier_accounts_payable() calculates SUM(credit-debit), and public.sync_supplier_accounts_payable_from_ledger() uses latest ledger balance. Current snapshot reconciles, but trigger order/behavior under ledger corrections or concurrent writes has not been tested. Neither trigger was changed.
- public.suppliers grants TRUNCATE to anon and authenticated despite RLS. Grant is confirmed; HTTP/PostgREST exploitability was not tested. This is distinct from purchase tables whose TRUNCATE grants are already revoked.

### Runtime and non-execution limits
- Cloudflare Pages current served commit/artifact, headers/cache and deployment lineage remain UNKNOWN.
- Authenticated Buyer browser E2E, Console/Network, actual Storage binary upload/download/delete, and Realtime WebSocket events/reconnect remain UNVERIFIED.
- No Production DDL, RLS/grant/trigger change, Edge deployment or business-data write was made during LVE575. All SQL in this pass was SELECT/read-only. Prior LVE574 rollback test is historical evidence and was not repeated.

### Required next step
Migration Lineage Reconciliation first: map each Production-applied migration version to exact SQL path/blob/commit, restore missing SQL from trusted history or document its origin, and explain renumbered migration files without changing Production. No db push. After reconciliation, separately design and test the custody payment RLS correction, choose one authoritative Supplier AP trigger, and revoke excess suppliers TRUNCATE privilege under a reviewed rollback plan.

**Arabic report:** doc/Draft/Reprots/Report575_BUYER_PRODUCTION_RERECHECK_MIGRATION_RLS_AP_20261101.md (latest update commit fff147ac5a22f5b8648f6495559594306f45d42d).
**CURRENT_STATE update:** commit f48fb6d37ce4f9707ecdcbb083704fdd4cef0ffb; new blob d459658f080a5c952dca244b661790c0e3aae804.
**Status:** LVE574 source/DB repairs remain present; Edge v21 source-byte-match confirmed; EGP confirmed; migration lineage conflict blocks safe migration; custody-payment RLS predicate defect confirmed; duplicate supplier AP triggers confirmed; suppliers TRUNCATE grant confirmed; Cloudflare/authenticated runtime UNVERIFIED; NOT CLOSED.

---

## LVE-2026-11-01-578 — Buyer Migration Lineage Reconciled / Supplier AP Trigger Still Dual

**Verified date:** 2026-11-01 Africa/Cairo.  
**Operational repository:** papamohammed77-glitch/erp-frontend, main, HEAD 40bd00c91f8c52260d867f5cf020104c9e71c161 (tree 4b4b36a5ee73868a058f01dde00229c510a91cdc).  
**Buyer blob:** 6c26444fa80b198d305727b70791f400839a6f75.  
**Edge source blob:** 49c85a4a4648bcef6892476d92037ca56745f633.  
**Production:** SMART ERP fiilmooggumokxanwiyx, ACTIVE_HEALTHY, PostgreSQL 17.6.1.121; app_settings.currency = EGP.  
**Edge:** save-purchase-order ACTIVE v21, verify_jwt=true, SHA-256 dab3eba49dd355080cadaa5bca4aea02056de19c4b6f3ba581f142cccfa0ea8c; retrieved deployed source matches Git byte-for-byte (21,007 chars).

### Confirmed changes since LVE575
- Production and Git now match all 33 Buyer migration versions and names in scope 20261031222956 through 20261101144244. There are 0 Buyer applied versions missing from Git and 0 Buyer migration files unapplied.
- Commits inspected: 8030364ebc53d33e02b971f30acda46f8b00c2ef (PO currency guard + custody payment policy); e9cda057f6168e9cf8304c0fc15d4996db8a3ccf (rename to applied version 20261101143644); 6f8b03ec5f79efb8fdb4fc5066f4654e33678ec3 (remove duplicate 20261101150000 file); caea2321c88bbb7640643be20672fe28aa9c502e (TRUNCATE revoke/default ACL); 40bd00c91f8c52260d867f5cf020104c9e71c161 (restore Buyer migration file/version alignment).
- buyer_custody_payments_scoped_select now correlates c.company_id = buyer_custody_payments.company_id. The table is empty, so cross-company row visibility is not functionally exercised.
- anon/authenticated have no TRUNCATE on any of 186 public tables; expanded public default ACL shows no TRUNCATE for these client roles.
- All five Buyer custody tables have RLS and authenticated SELECT only; no direct authenticated DML/TRUNCATE. Custody RPC signatures align with Edge v21 and have anon EXECUTE=false, authenticated EXECUTE=true, SECURITY DEFINER, search_path empty.
- Supplier AP remains numerically reconciled: 4 suppliers, stored AP 3,970, ledger net 3,970, 2 ledger rows, 0 running-balance mismatches.

### Remaining confirmed issue
- Two active triggers still update suppliers.accounts_payable:
  1. supplier_ledger_sync_accounts_payable → app_private.sync_supplier_accounts_payable(), SUM(credit-debit), updates old and new suppliers on supplier_id change, search_path empty.
  2. trg_sync_supplier_accounts_payable → public.sync_supplier_accounts_payable_from_ledger(), latest ledger balance, search_path=public, does not update the old supplier on supplier_id reassignment.
- Both are AFTER INSERT/UPDATE/DELETE. The old function has only its trigger dependency and no other direct function-source reference was found. Migration 20261101120225 creates the new trigger but does not remove the old one.
- Do not remove the legacy trigger in Production until insert/update/delete, supplier_id reassignment and concurrency behavior are tested and a rollback plan is prepared.

### Scope and verification limits
- Production ledger has 730 migration versions; current Git migrations directory has 43 files. The 33 Buyer files match; 10 additional Delivery files are outside this Buyer reconciliation. This does not establish that the full 730-version history is represented in Git. Do not run global db push.
- save-purchase-order v21 logs for 2026-11-01 show 5,563 POST/200, 18 POST/401 and 5,488 OPTIONS/200 in the inspected window; 401 causes are unknown and HTTP 200 does not prove a business transaction.
- Cloudflare Pages served artifact/commit, browser Console/Network, authenticated Buyer E2E, Storage binary operations and Realtime WebSocket behavior remain UNKNOWN/UNVERIFIED.
- No Production DDL, grant/RLS/trigger change, business-data write, Edge deployment or operational source edit was performed during this event. SQL was read-only.
- The previous LVE575 statement that Buyer migration lineage, custody-payment policy and suppliers TRUNCATE were still open is stale against current live evidence; CURRENT_STATE was superseded by LVE578.

**Arabic report:** doc/Draft/Reprots/Report578_BUYER_MIGRATION_LINEAGE_RECONCILIATION_SUPPLIER_AP_TRIGGER_20261101.md.  
**CURRENT_STATE:** updated to LVE-2026-11-01-578 in the governance/report repository.  
**Status:** BUYER MIGRATION SLICE RECONCILED / PAYMENT RLS FIX CONFIRMED / PUBLIC TRUNCATE REVOKED / EDGE v21 BYTE-MATCHED / SUPPLIER AP DATA RECONCILED / DUPLICATE AP TRIGGER OPEN / CLOUDFLARE + AUTHENTICATED E2E UNVERIFIED / NOT CLOSED.


---

## LVE-2026-11-02-584 — Buyer Tabs / Procurement Vehicle Custody / Cash Proof

**Verified date:** 2026-11-02 Africa/Cairo.
**Operational repo:** papamohammed77-glitch/erp-frontend, main, latest commit fetched aa8cbffbfa8d42253726381080dcfc24eaea838b.
**Buyer:** companies/company-1/purchasing/buyer.html, blob 73d746571a10b1720bdd31631004abce0ac9afa1.
**Driver:** companies/company-1/delivery/driver.html, blob 92ae03678b6516345a61d30bb5967046096d8cce.
**Edge:** save-purchase-order v22 ACTIVE / verify_jwt=true / byte-for-byte matches Git blob bc038be8c60a3d593f604c7b2ae445e807bacf57; deployed SHA-256 a0885a8a636b0d57ef9ab54b476001be8e3dd1f4227b921f511b002f58642ffb.
**Production:** SMART ERP fiilmooggumokxanwiyx; company currency EGP.

### Buyer tabs — current state
- The four owner-named tabs are already present in Buyer; do not recreate them.
- Invoices: list/detail/search/filter, create Draft, edit/delete Draft only; row click opens detail modal from commit 37d4e95e030bf3085c232655bdec6f059a335ca1. Preserve this work.
- Quotations: create/list/detail/accept/convert-to-PO. Production purchase_quotation_comparison view exists and is security_invoker=true, tenant scoped; Buyer source has zero references, though Edge GET_DATA allow-list permits the view. Current quotation count is zero. View ranks unit_price only; do not label an overall best supplier without total landed cost and terms.
- Custody: issue, employee acknowledgement, top-up, advance acknowledgement, expense documents (supplier invoice + warehouse receipt), finance review and settlement exist. The payment proof gap remains: finance approval currently creates payment/journal, marks invoice Paid and debits supplier_ledger without a separate proof that supplier actually received cash/instrument.
- Vehicle Balance: currently a placeholder. It resolves fleet_vehicle_assignments.driver_user_id, which is delivery driver assignment, not Buyer custodian assignment.

### Vehicle and inventory boundary
- Production counts at recheck: stock_vouchers=0, fleet_vehicle_assignments=0, buyer_custodies=0, purchase_quotations=0, purchase_invoices=3, mobile vehicles=2.
- Vehicle movement snapshot: CHV-2025-01 Loading 15 rows/qty39, Unloading 10 rows/qty26; VHL-0422 DirectReturn 1 row/qty1, Loading 12 rows/qty12, Unloading 6 rows/qty6. These are delivery operations, not procurement goods custody.
- Driver app reads run_sheet_details/orders and qty_loaded/qty_delivered/qty_returned; never reuse its delivery balance as buyer stock.
- fleet_vehicle_assignments has driver_user_id/fleet_driver_id, not buyer_user_id. vehicles has mobile_branch_id. stock_vouchers already has vehicle_id, custodian_user_id, purchase_order_id and purchase_invoice_id; stock voucher Core whitelist currently only supports Transfer, DirectSale, DirectReturn, SupplierReturn.
- Existing Warehouse SupplierReturn Branch→Supplier contract was closed in Reports 342/343. Preserve it; don't rebuild it or post AP credit at the time goods merely leave warehouse for buyer custody.
- Supplier→Buyer/Vehicle→Warehouse and Warehouse→Buyer/Vehicle→Supplier stages are not implemented. Do not add mobile vehicle stock to Buyer view, and don't add it to saleable stock before warehouse acceptance.

### Purchase, supplier, payment, custody contracts
- PO columns expected_delivery_date and payment_terms already exist; approved_by/sent_at columns and Edge SEND_PO/APPROVE_PO do not exist. Edge CREATE_PO exists and creates Draft PO without balance impact.
- purchase_post_invoice_atomic blocks unlinked quick invoice posting until an approved receiving contract exists. PO-linked posting validates receipt/qty/price and avoids duplicate stock/AP postings.
- purchase_payments.payment_method exists with default Cash, but purchase_post_payment_atomic and Edge POST_PAYMENT do not receive p_payment_method; end-to-end selection is incomplete.
- buyer_custody_issue_atomic and buyer_custody_add_advance_atomic post treasury cash immediately, before later employee acknowledgement; reference optional. buyer_custody_settle_atomic posts cash receipt but finance reference optional and no dedicated proof attachment fields are present.
- buyer_custody_review_expense_atomic checks supplier invoice/PO/warehouse receipt but then posts supplier AP debit and marks invoice Paid without separate supplier cash receipt proof. This conflicts with Owner Physical Handover policy (§77.1/77.4).
- suppliers lacks email/rating/grade and no supplier visits/ratings tables were found.
- Prior Report575 issues are resolved against live Production: LVE579 leaves one active Supplier AP trigger; suppliers TRUNCATE denied to anon/authenticated; buyer_custody_payments RLS company predicate corrected.
- Current DB migration registry for the two recent Buyer invoice changes is 20261102150516 / 20261102151137, while Git filenames are 20261102160000 / 20261102162000. Behavior is present in Production; version/file lineage must be reconciled before db push.

### Source recovery / current Edge source gap
- Production has create/send/receive/complete/cancel stock-voucher Edge functions; their current deploy sources are not present in operational supabase/functions directory. Historical snapshots in rawaie-erp-New/Current/Edge_Functions are incomplete/stale and must not be deployed. Recover the actual deployed source into operational Git before extending the existing functions. Do not create new Edge Functions.

### Owner policy and required approval
- Master CTO Governance §77.2 requires exact changeset (source diffs + complete SQL + effects + dependencies + tests + rollback) to be presented and expressly approved before any write/migration/RPC/trigger/RLS/deployment that can affect Production or business balances. General task direction and the procurement policy endorsement under §77.4 do not constitute approval of an exact code/DDL change.
- No operational source, Production row, RPC, migration, RLS/grant/trigger, Edge deployment or Cloudflare deployment was changed during LVE584. SQL was read-only.
- Cloudflare served artifact, authenticated Buyer browser E2E, Storage binary operations and Realtime WebSocket E2E remain UNVERIFIED.

### Required next action
Recover and reconcile the five deployed stock-voucher Edge source files into operational repo. Then prepare one precise Procurement Custody changeset: separate time-bounded Buyer/vehicle assignment, supplier→vehicle custody, warehouse acceptance and discrepancy handling, reverse return transit with supplier receipt, plus evidence gates for cash issue/top-up/supplier payment/settlement and payment_method. Preserve current delivery and direct SupplierReturn flows. No Production deployment until the owner approves the exact presented changeset.

**Arabic report:** doc/Draft/Reprots/Report584_BUYER_TABS_PROCUREMENT_CUSTODY_EVIDENCE_20261102.md (latest commit 725fa11d44468f7375b3163fdd987fdbe5460570; blob afa845159f291cdd33657ec853979c9289de7c86).
**CURRENT_STATE update:** commit e5201bb99fb50edea8a4b119fff7153428c52964; blob b6b28fc439900617de5747afbe2a626a467529bb.
**Status:** tabs present; comparison view not wired; buyer vehicle custody contract missing; supplier cash receipt proof gap confirmed; driver stock is not buyer stock; Edge v22 byte-match; Cloudflare/browser E2E unverified; no Production mutation; not closed.