# CURRENT FORENSIC CHECKPOINT — 2026-09-30 — REPORT379 VAN SALES EXECUTION

Authoritative basis: CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.
Historical reports are guidance only.

## Latest verified frontend reality
- Frontend repository: papamohammed77-glitch/erp-frontend
- Target: companies/company-1/sales/van-sales.html
- Latest frontend HEAD: 1b89202949575eaebed4c5bf5512322129a114fb
- Parent: c67de5a0b601e2cc0690bf40c32d46632140f95e
- Current blob: 568db68e1465578cebf0231c9b1b653065608c52
- Latest commit fixes the malformed loadCustomerPatterns promise tail.

## Current Van Sales open defect
- showRecentCustomers() currently resolves public.users by id = this.currentUser.id.
- Production proves public.users.id differs from auth.users.id for active direct-sales users.
- Exact protected owner surgical patch: `.eq('id', this.currentUser.id)` -> `.eq('auth_id', this.currentUser.id)`.
- Do not modify picker.html, main.html, or warehouse/vouchers.html in this unit.

## Production backend / Inventory Rescue
- setup-van-branch v5 ACTIVE
- save-sales-invoice v15 ACTIVE
- save-receipt-voucher v8 ACTIVE
- save-inventory-count v5 ACTIVE
- save-daily-settlement v4 ACTIVE
- start-picking v14 ACTIVE
- complete-picking v13 ACTIVE
- start-loading v4 ACTIVE
- complete-loading v10 ACTIVE
- reopen-loading v2 ACTIVE
- unload-runsheet v5 ACTIVE
- post_stock_movement is the only direct UPDATE writer detected for public.stock_branches; reserve_stock/release_stock_reservation are reservation writers.
- inventory_log INSERT was detected in post_stock_movement only.

## Experimental data
- Executed historical vouchers IN-1, IN-8, IN-9 remain because they already generated stock/audit history and current integrity guards do not permit safe hard deletion.
- Inspected physical residual is neutralized/zero; known canary users/runsheets/orders/customers are absent.

## Current report
- Report379: doc/Draft/Reprots/Report379_VAN_SALES_FORENSIC_EXECUTION_20260930.md
- Report commit: ac278ad4a2aabde1094d35be45917f52b0ea5c57

---
# CURRENT FORENSIC CHECKPOINT — 2026-09-30 — REPORT378 VAN SALES PARSE FAILURE

Authoritative basis: CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.
Historical reports are guidance only.

## Latest verified frontend reality
- Frontend repository: papamohammed77-glitch/erp-frontend
- Target: companies/company-1/sales/van-sales.html
- Latest HEAD: c67de5a0b601e2cc0690bf40c32d46632140f95e
- Parent: e5f3e8ed0e2a491a243bce0029aeb2e73cc824dc
- Current blob: 012fba212bc2ecf0d21a8990fca76190c27701f8
- 3295 lines / 151087 chars
- JavaScript full-script parse: FAIL — Unexpected token ')'
- Parent 74b122f9c2721178f27dd8f495cfd61134bb5399 parses successfully.
- e5f3e8e... introduced the malformed loadCustomerPatterns tail; c67 did not repair it.

## Exact root cause
- Function: App.loadCustomerPatterns()
- Approximate defect line: 583
- Defective sequence:
  `    });`
  `        }).catch(function() {});`
- Surgical replacement:
  `    })`
  `        .catch(function() {});`
- Independent V8 parse of the corrected source: PASS.
- App is not defined is a consequence of the parse failure; picker.html is unrelated to this Van Sales syntax root cause.

## Latest Van Sales state
- Current source contains 65 App methods + global resolveCustomer.
- Historical baseline contains 65 App methods + _createVanBranch; _createVanBranch responsibility moved to setup-van-branch.
- repeatOrder and initiateEndOfDay changes are present in c67 and are not the parse root cause.
- Protected frontend files: van-sales.html, main.html, warehouse/vouchers.html. No automatic frontend edit performed.

## Production backend verified
- setup-van-branch v5 ACTIVE
- save-sales-invoice v15 ACTIVE
- save-receipt-voucher v8 ACTIVE
- save-inventory-count v5 ACTIVE
- save-daily-settlement v4 ACTIVE
- post_van_sales_collection_atomic exists
- post_daily_settlement_atomic exists
- get_van_sales_customer_accounts and get_van_sales_customer_account exist
- runsheets schema includes company_id, driver_id, vehicle_id, workflow timestamps, loading_cycle_id.

## Open Van Sales closure order
1. Owner applies Report378 syntax replacement and deployed frontend rebuild/cache refresh.
2. Browser E2E of van-sales.
3. Close remaining open units in existing order:
   repeatOrder
   initiateEndOfDay
   then any remaining direct-scope/consumer units proven open by fresh evidence.
4. Do not reopen closed units without new direct evidence.

## Report
- Report378: doc/Draft/Reprots/Report378_VAN_SALES_FORENSIC_CURRENT_REALITY_20260930.md
- Report commit: 6246f36793126ed7eee2a8a827a248ae6b744a98

---

# CURRENT SESSION — 2026-09-29 — REPORT370 VAN SALES COLLECT PAYMENT FORENSIC CHECKPOINT

> Authoritative evidence for this checkpoint: CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE. Historical reports are guidance only.

## Current frontend truth
- Frontend repository: papamohammed77-glitch/erp-frontend
- Target: companies/company-1/sales/van-sales.html
- Latest frontend HEAD: cf90684a3b1afd017a97e7b7802e9308d6ae158c
- Parent: 016a219419fbfcf6227135d99eea4813ea94e224
- Current van-sales.html blob: 0e6926a15d3d6ea59ed8e01fa7b1ce5adc140235
- Current source size: 2667 lines / 133773 chars
- Protected: van-sales.html, main.html, warehouse/vouchers.html — not automatically modified.

## Current production truth
- setup-van-branch v5, ACTIVE
- save-sales-invoice v15, ACTIVE
- save-receipt-voucher v8, ACTIVE
- post_van_sales_collection_atomic exists and is atomic/idempotent through erp_operation_registry.

## Current collectPayment finding
- The latest frontend refactor already supplies customerId + operationId to save-receipt-voucher v8.
- The remaining defect is that operationId is generated anew on every confirmation attempt.
- Therefore a committed collection followed by a lost response can be retried as a new operation and bypass the server idempotency registry.
- Exact surgical owner patch is recorded in:
  doc/Draft/Reprots/Report370_VAN_SALES_COLLECT_PAYMENT_FORENSIC_CLOSURE_20260929.md
- Required patch: persist pending operation identity until confirmed success; remove it only after confirmed success.

## Backend conclusion
- No Production DB/Edge change was required for this specific frontend defect.
- post_van_sales_collection_atomic already uses erp_operation_registry keyed by company_id + operation_type + operation_key and posts treasury + customer ledger atomically.
- post_cash_receipt_atomic and post_customer_ledger_entry were verified as atomic financial primitives.

## Existing applied work — do not repeat
- Report368 custody-source corrections are already present in current frontend HEAD.
- showRecentCustomers() live company/source-scoped path is present.
- _loadVehicleStock() live stock/source-scoped path is present.
- enterApp() stops on syncDown failure.
- setup-van-branch v5 uses authenticated user company and primary direct-sales assignment.
- save-sales-invoice v15 uses VanSale through post_stock_movement.

## Open Van Sales closure order
1. collectPayment() — APPLY Report370 exact surgical patch, then syntax + browser E2E + Production retry/ledger verification.
2. loadMyCustomers() — company/source + authoritative customer assignment review.
3. loadCustomerPatterns() — company/source + order_id-bounded details.
4. loadKPIs() — company/source + target-source verification.
5. loadHomeSalesSummary() — company/source.
6. loadMyInvoices() — company/source.
7. showCustomerDetail() — authorization + scope.
8. repeatOrder() — authorization + scope.
9. initiateEndOfDay() — bind to existing settlement contract; not a client-only lock.

## Financial-history caution
- Production driver_ledger contains identifiable QA cleanup/reversal entries and is financial/audit history.
- Do not delete ledger history blindly; handle in a separate forensic reconciliation closure.

## Governance
- No new Edge Function and no new RPC for collectPayment.
- Do not modify main.html or warehouse/vouchers.html.
- Do not declare collectPayment 100% until the exact owner patch is applied and the full verification chain succeeds.

---

# CURRENT SESSION — 2026-09-29 — REPORT369 VAN SALES COLLECT PAYMENT CLOSURE

> Authoritative evidence: CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE. Historical reports are guidance only.

## Verified checkpoint
- Frontend repo latest verified main commit: 016a219419fbfcf6227135d99eea4813ea94e224
- Target: companies/company-1/sales/van-sales.html
- Reports368 custody patches are already present in the current source and must not be repeated.
- Protected: main.html, warehouse/vouchers.html.

## Current verified production
- setup-van-branch v5
- save-sales-invoice v15
- save-receipt-voucher v8
- post_van_sales_collection_atomic exists and executed successfully inside ROLLBACK.

## Current open closure
- App.collectPayment() still sends legacy receipt payload without header.customerId/header.operationId.
- Production save-receipt-voucher v8 requires operationId and routes customer collections to post_van_sales_collection_atomic when customerId is provided.
- Exact surgical replacement is recorded in Report369.

## Required next action
- Owner applies ONLY Report369 replacement to App.collectPayment in van-sales.html.
- Do not modify main.html or vouchers.html.
- Then syntax gate → browser E2E → Production verification.
- Do not open the next Van Sales unit until collectPayment reaches 100% closed.

---

# CURRENT SESSION — 2026-09-29 — REPORT368 VAN SALES CUSTODY RECONCILIATION

> Authoritative evidence: CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE. Historical reports are guidance only.

## Verified checkpoint
- Frontend repo: papamohammed77-glitch/erp-frontend
- Current frontend main HEAD: 751c10723bfa5ed2ce6c3ae12561a179c5ecb56e
- Target: companies/company-1/sales/van-sales.html
- Current van-sales source has the prior showRecentCustomers syntax fix from commit 751c107...; the older CURRENT_STATE reference to 22e2 is stale.
- Protected frontend files remain untouched: main.html, vouchers.html, van-sales.html.

## Production facts verified
- CHV-2025-01 is canonically assigned to vansales@rawaea.com through fleet_vehicle_sales_rep_assignments; VHL-0422 to vansales2@rawaea.com.
- setup-van-branch is currently Production v5 and resolves direct-sales vehicle assignment through fleet_vehicle_sales_rep_assignments.
- save-sales-invoice is currently Production v15 and posts VanSale through the central post_stock_movement path.
- save-receipt-voucher is currently Production v8 and supports post_van_sales_collection_atomic.
- Van stock rows exist canonically in stock_branches. Production currently has 17 rows for each inspected VAN branch, including explicit zero-quantity rows.
- inventory_stock_snapshot confirms stock_value_at_cost is the central inventory valuation field; the current Van Sales UI uses sales_price for commercial display.

## Proven root causes for the custody/value discrepancy
1. loadHomeStockSummary reads local Dexie stock and calculates total value using only the first 5 stock rows.
2. _loadVehicleStock reads local Dexie stock and calculates total value across all rows.
3. Therefore «عهدتي الآن» and «سيارتي» can display different values for the same vehicle stock.
4. enterApp swallows syncDown failures and continues into loadVanBranch, allowing stale/empty cache to be presented as current custody data.
5. _renderVehicleStockHTML renders zero-quantity stock rows, making valid zero rows appear as active custody items.
6. «رصيدي» is a driver_ledger financial liability and is not the same measure as physical stock custody value; it must not be forced to equal stock value.

## Current surgical owner patch
Report: doc/Draft/Reprots/Report368_VAN_SALES_CUSTODY_RECONCILIATION_FORENSIC_20260929.md
- Patch 1: replace enterApp syncDown continuation to stop on sync failure instead of silently continuing.
- Patch 2: replace loadHomeStockSummary to read live stock_branches + company-scoped items and calculate value across all positive stock rows.
- Patch 3: replace _loadVehicleStock to use the same live source and same value basis, while scoping today's sales by company + source='van-sales' and hiding zero-quantity rows from the current-custody display.
- No Production DB/Edge change was required for this specific defect.

## Remaining open Van Sales units
- collectPayment: legacy frontend payload despite Production save-receipt-voucher v8 contract.
- loadMyCustomers / loadCustomerPatterns / loadKPIs / loadHomeSalesSummary / loadMyInvoices: company/source scoping gaps.
- showCustomerDetail / repeatOrder: consumer authorization/scope audit required.
- initiateEndOfDay: client-only lock; settlement contract remains open.
- Browser E2E after owner-applied van-sales source patch: open.

## Session rule
Apply only the exact owner patches in Report368 to van-sales.html. Do not modify main.html or vouchers.html for this closure. Re-run syntax, then Browser E2E, then Production read verification. Do not delete zero stock rows from Production merely because the UI hides them.

---

# CURRENT SESSION — 2026-09-29 — REPORT367 VAN SALES SYNTAX FORENSIC

> Authoritative evidence: CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.

## Latest verified checkpoint
- Frontend repo: papamohammed77-glitch/erp-frontend
- Current frontend main HEAD: 22e2b851fde0aa136eaf6f55c617d06a4b43ed50
- Parent: 3c03e72f79bc337f89a1b27100795a522d249301
- Target: companies/company-1/sales/van-sales.html
- Root cause: latest commit 22e2 introduced a JavaScript parse failure in App.showRecentCustomers at line 1522 (Unexpected string).
- Parent 3c03 source parses successfully; current HEAD fails full-script V8 parse.
- In-memory replacement of ONLY showRecentCustomers parses successfully.
- Protected frontend files were not modified.
- Exact surgical replacement is recorded in doc/Draft/Reprots/Report367_VAN_SALES_SYNTAX_FAILURE_FORENSIC_20260929.md

## Required owner action
- Replace only showRecentCustomers:function(){...}, in van-sales.html with the exact block in Report367.
- Do not modify main.html or warehouse/vouchers.html.
- After owner patch: syntax gate -> browser E2E -> close VAN-01.

## Current Van Sales open units
- VAN-01 showRecentCustomers: syntax defect introduced by latest refactor; surgical patch ready.
- VAN-02 collectPayment: open surgical patch.
- VAN-03 company/source scoping in sales queries: open surgical patch.
- VAN-04 loadCustomerPatterns order-id-bounded query: open surgical patch.
- EOD settlement/custody reconciliation: open business contract.

---

# CURRENT SESSION — 2026-09-29 — REPORT366 VAN SALES FORENSIC INTEGRATION

> Authoritative evidence: CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.

## Latest checkpoint
- Report: \`doc/Draft/Reprots/Report366_VAN_SALES_FORENSIC_INTEGRATION_SURGICAL_COMPLETION_20260929.md\`
- Report commit: \`6e8f9938909c244435c5bd845bc472280f95d508\`
- Protected frontend: \`companies/company-1/sales/van-sales.html\` (NOT MODIFIED)
- Protected frontend: \`companies/company-1/warehouse/vouchers.html\` (NOT MODIFIED)
- Mother \`main.html\` (NOT MODIFIED)

## Production changes executed
- \`post_driver_ledger_entry\` hardened to recompute running balance from SUM(debit-credit) with row locking.
- \`post_customer_ledger_entry\` hardened to recompute running balance from SUM(debit-credit) with row locking.
- \`save_sales_invoice_atomic\` item lookups confirmed company-scoped.
- New RPC \`post_van_sales_collection_atomic\` created for atomic Van Sales customer collection.
- Existing \`save-receipt-voucher\` deployed as v8 with Van Sales collection routing to the new RPC.
- First collection test exposed unsupported \`min(uuid)\`; corrected in migration \`20260929191000_fix_van_sales_collection_treasury_uuid_selection\`.
- Collection rollback test subsequently succeeded with no residue.

## Confirmed Production data
- \`vansales@rawaea.com\` and \`vansales2@rawaea.com\` are Active direct-sales representatives.
- Primary vehicle assignments exist for CHV-2025-01 and VHL-0422.
- Both vehicle.driver_id values are NULL; Master Assignment is the canonical direct-sales identity.
- Exactly one active treasury exists for RAWAEA; standard COA 121 cash and 123 AR exist.
- Customer ledger currently has zero snapshot mismatches.
- \`vansales@rawaea.com\` historical driver ledger has net=383 while latest stored snapshot=443; future postings now recompute from mathematical ledger history. Historical rows were preserved.

## Van Sales frontend open units
- \`App.showRecentCustomers()\` at ~1435: dead Dexie \`db.orders\` source; owner surgical patch required.
- \`App.collectPayment()\` at ~951: legacy receipt payload; owner surgical patch required to use customerId + operationId with save-receipt-voucher v8.
- \`loadKPIs()\` ~595: add company/source scoping.
- \`loadHomeSalesSummary()\` ~679: add company/source scoping.
- \`loadCustomerPatterns()\` ~420: add company/source scoping and order-id-bounded details query.
- \`loadMyInvoices()\` ~1026: add company/source scoping.
- \`_loadVehicleStock()\` ~1081: add company/source scoping to sold-today query.
- \`initiateEndOfDay()\` ~1278: client-only lock; requires separate Van Sales settlement contract and must not be incorrectly tied to runsheet until contract is established.
- Browser-rendered E2E after owner-applied protected-file patches remains open.

## Inventory contract
- Physical stock movement remains centralized through \`post_stock_movement\`.
- Van Sale path: save-sales-invoice -> save_sales_invoice_atomic -> post_stock_movement -> mobile branch.
- \`reserve_stock\` remains Reservation-only.
- \`setup_van_stock\` remains Initialization-only.

## Session rule
The next unit starts from the open Van Sales frontend surgical patches above; do not modify protected files automatically.


# CURRENT SESSION — 2026-09-29 — Report365 Van Sales Core Authorization Closure

> Authoritative evidence: CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.

## Latest checkpoint
- Report: `doc/Draft/Reprots/Report365_VAN_SALES_CORE_AUTHORIZATION_CLOSURE_20260929.md`
- Report commit: `d15e10e17166b7416da06a349173b7551009a354`
- Canonical Van Sales source: `companies/company-1/sales/van-sales.html`
- Van Sales blob: `8d61382a8e0025a0d079e71dd94f33d106d9088e`
- Frontend HEAD verified: `3c03e72f79bc337f89a1b27100795a522d249301`
- Frontend parent: `609ab127410004ba9ee3161c8f0deaf630fbfd03`

## Production change executed
- Updated existing `public.post_stock_movement(uuid,text,uuid,uuid,uuid,numeric,text,text,text,text)`.
- VanSale authorization now supports active primary `fleet_vehicle_sales_rep_assignments` for Direct Sales Representatives while preserving `vehicles.driver_id` for delivery-driver fallback.
- Item resolution is now company-scoped.
- Migration source recorded at:
  `supabase/migrations/20260929150000_van_sales_post_stock_movement_assignment_auth.sql`
- Migration Git commit:
  `9e70657af60814c71efb8b93e046e2001b733d0e`
- Production positive test with `vansales2@rawaea.com` + `VHL-0422` succeeded inside rollback transaction.
- Negative mismatched-representative test was rejected.
- QA inventory log residue after rollback: 0.

## Van Sales OPEN items
- `App.showRecentCustomers()`: exact owner surgical patch required; source still uses unwritten Dexie `db.orders`.
- `collectPayment()`: payload incompatible with Production `save-receipt-voucher v7`; separate closure.
- Explicit `source='van-sales'` filters missing in sales/invoice/vehicle-stock queries; separate closure.
- `loadCustomerPatterns()`: broader-than-needed `order_details` query; separate closure.
- `initiateEndOfDay()`: client-only settlement flow; separate closure.
- Production `driver_ledger.balance` snapshot inconsistency for `vansales@rawaea.com`: sum debit-credit = 383 while latest stored balance = 443; requires controlled financial closure.
- Browser E2E against currently deployed frontend artifact remains open.

## Protected files not modified
- `erp-frontend/companies/company-1/sales/van-sales.html`
- `erp-frontend/companies/company-1/warehouse/vouchers.html`
- Mother `main.html`

# CURRENT SESSION — 2026-09-29 — Report361 Voucher Modal Print Forensic Closure

> **Authoritative checkpoint:** CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.
> Historical reports are guidance only and do not override current evidence.

## Current Git
- System repo evidence checkpoint (report commit): `bd955967fcb1590f65b43bb085eaa132e0d918d7`
- Parent at evidence checkpoint: `1c862e242a1b3fe23e11f586ecf0703bec35920a`
- `CURRENT_STATE.md` is then updated in a subsequent state commit whose parent is the report commit above.
- Report: `doc/Draft/Reprots/Report361_WAREHOUSE_VOUCHER_MODAL_PRINT_FORENSIC_CLOSURE_20260929.md`
- Report commit: `bd955967fcb1590f65b43bb085eaa132e0d918d7`

## Current Source
- Frontend HEAD: `1214f6bca0d5f851bec2be8bd3d466b4af758efd`
- Frontend parent: `386b003ccd1650444062844394a7ec6ac2f7032f`
- `companies/company-1/warehouse/vouchers.html` blob: `d231a6b1762fdd66a0c57e33a8c43a7200391a13`
- `vouchers.html`: 6625 lines / 215151 chars.
- `Current/PWA/main.html` blob: `27b777528665dcc985809648f006452c861ae36e`
- `companies/company-1/sales/van-sales.html` blob: `8d61382a8e0025a0d079e71dd94f33d106d9088e`
- main.html and vouchers.html were NOT modified by this session.

## Closed / Do Not Rework
- Owner wildcard / owner identity
- Main authorization and delegation
- DirectReturn DR-UI-01, DR-UI-02, DR-UI-03A/03B, DR-UI-04
- Transfer source/destination responsibility contract
- SupplierReturn backend
- Existing voucher lifecycle/stock/accounting contracts
- Existing edge/RPC infrastructure

## Current Defect Identified
File: `companies/company-1/warehouse/vouchers.html`
Object: `App`
Function: `printVoucher:function()`
Approximate current source location: line 1664.

Defective element:
`window.open('','_blank','noopener,noreferrer,width=1200,height=900')`

The next guard immediately returns on falsy `w`.

Root cause: the implementation requests `noopener,noreferrer` from `window.open()` while requiring a usable returned window reference. The current Web API behavior permits/defines a `null` return with `noopener`, matching the observed no-response printing failure.

## Required Owner Surgical Patch
The owner must replace ONLY the complete `printVoucher:function(){...},` element immediately before `exportVoucher:function()` with the full replacement in Report361.

No whole-function rewrites beyond this one element.
Do not modify `details()`, `actionFor()`, `renderList()`, `printDraftVoucher()`, `main.html`, or `van-sales.html`.

Required replacement characteristics:
- use `Swal.getHtmlContainer()` when available;
- do not pass `noopener,noreferrer` to `window.open()`;
- use named print context `rawaea-voucher-print`;
- guard duplicate print calls;
- keep existing modal HTML/CSS print output;
- do not invoke any DB mutation.

## Production / Database
Supabase project: `SMART ERP` / `fiilmooggumokxanwiyx` / ACTIVE_HEALTHY / PostgreSQL 17.6.1.121.

Current manual production data remains:
- Completed DirectSale = 1
- Completed SupplierReturn = 4
- Received DirectReturn = 1
- Received Transfer = 1
- Sent DirectSale = 1

Verified integrity:
- IN-1: 5 details / 5 inventory_log / 3 audit / 1 driver ledger.
- IN-9: 1 detail / 2 inventory_log / 4 audit / 1 driver ledger.
- QA-SR-UI-CONTRACT-20260927-01 has stock/audit/journal/supplier-ledger effects and was NOT deleted.

No new Edge Function.
No new RPC.
No migration.
No table/RLS change.
No stock/accounting/treasury mutation was required.

## Testing
- Forensic unit simulation: `PRINT_FORENSIC_UNIT=PASS current=blocked patched=printable`.
- Cause is independently supported by current Web API documentation for `window.open()` and the SweetAlert2 `getHtmlContainer()` API.
- Current frontend HEAD `1214f6...` has no workflow run evidence from the available commit-run lookup endpoint.
- Existing GitHub browser workflow remains available, but current-HEAD authenticated/browser E2E has not been executed through the available connector and therefore remains OPEN.
- Do not mark Browser E2E PASS until an actual browser run built from the patched frontend HEAD succeeds.

## Test Fixtures / Cleanup
Do not delete the existing QA history because it has real stock/audit/financial effects.
No new persistent test fixture was required for this client-only printing defect.

## Next Session Entry Sequence
1. Re-read current Git/source; do not start from Report360.
2. Verify frontend HEAD and vouchers blob.
3. Verify old print element count = 0 and new print element count = 1.
4. Run source syntax gate.
5. Apply/verify the owner surgical patch only.
6. Run browser E2E on Pending: IN-8 and IN-9.
7. Run browser E2E on Completed: IN-1 and QA-SR-UI-CONTRACT-20260927-01.
8. Confirm print window opens and voucher code/content exists.
9. Confirm no DB mutation after print.
10. Mark the browser-print defect CLOSED only on actual browser evidence.
11. Do not reopen any previously closed business contract.
12. Move to the next genuinely OPEN item.

## Continuity Rule
Current Git/source/Production/database/deployment evidence wins over historical reports.

---

# CURRENT SESSION — 2026-09-29 — Report360 Forensic Final

> **Authoritative checkpoint:** CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.
> Historical reports are guidance only and do not override current evidence.

## Current Git

- System repo HEAD before this state write: `af7bd6c2f22b308f732ec3503a8ad21163d37d02`
- System repo parent: `817aa8851e9fdd837ad11e994d2ce09c87acef1c`
- Latest report: `doc/Draft/Reprots/Report360_WAREHOUSE_VOUCHERS_DIRECTRETURN_FORENSIC_FINAL_20260929.md`
- Latest report commit: `af7bd6c2f22b308f732ec3503a8ad21163d37d02`

### Frontend current evidence

- Frontend repo HEAD: `386b003ccd1650444062844394a7ec6ac2f7032f`
- Frontend parent: `56fee06ac0145faffbc4f71d3d6031fcd3b46f87`
- `companies/company-1/warehouse/vouchers.html` blob: `9b538a49b9ee520aaa17a097fe881167a9230abf`
- Current vouchers source lines: 6599
- `Current/PWA/main.html` blob: `27b777528665dcc985809648f006452c861ae36e`
- `companies/company-1/sales/van-sales.html` blob: `8d61382a8e0025a0d079e71dd94f33d106d9088e`

## Current forensic conclusion

The latest frontend commit `386b...` partially applied Report359 but left the DirectReturn UI contract incomplete and introduced a new syntax/runtime defect.

### Proven current source defects

1. `pickArr:function(key)` — current DR-UI-01 patch references `v.id` before `v` exists inside the filter callback.
2. `pickSelect:function(key,id)` — current fallback is malformed and causes `SyntaxError: Invalid left-hand side in assignment`.
3. `pickSearch:function(key,q)` — second vehicle display mapping still resolves from `x.driver_id` only (DR-UI-03B missing).
4. `editVoucher:function(code)` — Draft DirectReturn reopening still resolves rep from `vv.driver_id` only (DR-UI-04 missing).

### Proven already correct and MUST NOT be redone

- DR-UI-03A first vehicle search mapping.
- `routeHtml:function()` DirectReturn field is not readonly.
- Current DirectReturn `submit()` assignment-first validation.
- Main authorization / Owner wildcard semantics.
- Main delegation to `vouchers.html`.
- DirectReturn Production backend.
- DirectSale backend.
- Transfer backend.
- SupplierReturn backend/contract.

## Surgical source action

The owner must modify only `companies/company-1/warehouse/vouchers.html` using the exact four replacements in Report360:

- DR-UI-01
- DR-UI-02
- DR-UI-03B
- DR-UI-04

Do not rewrite whole functions.
Do not modify `main.html`.
Do not modify `van-sales.html`.
Do not create new Edge Functions/RPC/tables for this defect.

The four replacements were applied In-Memory to the current source and the resulting inline JavaScript passed a full Syntax Gate.

## Production evidence

Current active Master Assignment proves:

- CHV-2025-01 → `vansales@rawaea.com`; `driver_id=NULL`
- VHL-0422 → `vansales2@rawaea.com`; `driver_id=NULL`

VHL-0422 currently has mobile stock enabled and an available quantity of item `1003`.

Current Production atomic Create/Send test for DirectReturn:

- vehicle: VHL-0422
- rep: `vansales2@rawaea.com`
- destination: BR-01
- item: 1003
- result before rollback: `Sent`, `custodian_user_id = rep2`, movement count = 1
- transaction was rolled back
- no `IN-10` residue remains

A current negative pairing attempt against the wrong rep is still protected by the Production assignment contract; the backend contract itself was already closed in Report359.

## Production infrastructure decision

No Production infrastructure change is required for this source-only defect.

Existing:
- `create_manual_stock_voucher_atomic`
- `create_manual_stock_voucher_atomic_core_12_20260828`
- `update_manual_stock_voucher_atomic`
- `send_stock_voucher_atomic`
- `receive-stock-voucher` Edge Function v22
- `complete_manual_stock_voucher_atomic`
- `cancel_manual_stock_voucher_atomic`

remain the active contract.

## QA history

No historical QA records with stock/audit/financial effects were deleted.

The ephemeral test created in this session was fully rolled back.

Current DirectReturn status counts:
- Draft = 0
- Sent = 0
- Received = 1
- Completed = 0
- IN-10 residue = 0

The existing Received record is historical and is not treated as test residue.

## Deployment

The current frontend HEAD `386b...` has no workflow run evidence returned by the available commit-run lookup endpoint.

The prior Browser E2E run `36483037124` was based on `56fee...`, not the current source.

Therefore Browser E2E remains **OPEN** until a run built from the fixed frontend HEAD completes successfully.

## Next session exact sequence

1. Start from current Git/Source, not Report360.
2. Verify the owner applied DR-UI-01, DR-UI-02, DR-UI-03B, DR-UI-04.
3. Run syntax gate.
4. Run Browser E2E from the new frontend HEAD.
5. Test `vansales2@rawaea.com` → `VHL-0422`.
6. Reopen Draft DirectReturn and verify `custodian_user_id` / Master Assignment.
7. Run Smart Search verification.
8. Run Create → Send → Receive.
9. Run wrong rep/vehicle negative test.
10. Verify stock, audit, custody, and no inappropriate financial/treasury side effect.
11. Only then mark DirectReturn UI CLOSED.
12. Move to the next genuinely open Business Contract.

## Continuity rule

Never re-fix what is proven closed.
If a historical report conflicts with current Git/source/Production/database/deployment evidence, current evidence wins.

---

# CURRENT SESSION — 2026-09-28 — Report359 Forensic Continuation

> **Authoritative checkpoint:** CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.
> Reports remain historical guidance only.

## Current Git
- System repo HEAD before this state write: `e5d0a760bc60345458ad6a261a9094072d48133d`
- System repo parent: `57ba850b16826fca0361757d781f3b796d8eb0cf`
- Frontend repo HEAD: `56fee06ac0145faffbc4f71d3d6031fcd3b46f87`
- Frontend parent: `31a255c6bac2e23f8ceb74734e66010039e9938c`
- Current `vouchers.html` blob: `e24eddf27d657a9baa6713b2c26b571c768cb28e`
- Current `main.html` blob: `27b777528665dcc985809648f006452c861ae36e`

## Latest report
`doc/Draft/Reprots/Report359_WAREHOUSE_VOUCHERS_DIRECTRETURN_MASTER_ASSIGNMENT_FORENSIC_CLOSURE_20260928.md`
- Report create commit: `5805225e71305830632aec8bcd117ece04e85874`

## Current forensic finding
The remaining source defect is **not** a Production DB/RPC defect.

Production's authoritative Sales Rep ⇄ Vehicle relationship is:
`fleet_vehicle_sales_rep_assignments`

Production currently proves:
- CHV-2025-01 → `vansales@rawaea.com`; `driver_id = NULL`
- VHL-0422 → `vansales2@rawaea.com`; `driver_id = NULL`

Current `vouchers.html` still contains legacy-first `vehicles.driver_id` usage in four UI locations:
1. `pickArr:function(key)` — DirectReturn vehicle list for direct-sales rep.
2. `pickSelect:function(key,id)` — DirectReturn rep selection fallback path.
3. `pickSearch:function(key,q)` — vehicle/rep resolution in result mapping, two occurrences.
4. `editVoucher:function(code)` — reopening Draft DirectReturn rep from `driver_id`.

## Owner surgical patch set
The owner must apply only the exact replacements in Report359:
- DR-UI-01
- DR-UI-02
- DR-UI-03A
- DR-UI-03B
- DR-UI-04

Do **not** rewrite whole functions.
Do **not** modify `main.html`.
Do **not** modify existing Production RPC/Edge contracts unless new evidence proves a backend defect.

## Closed and must not be reopened
- Main authorization / Owner wildcard semantics
- Main delegation to `vouchers.html`
- Transfer backend
- DirectSale backend
- SupplierReturn backend/contract
- DirectReturn backend
- Report357/Report358 closed items
- Existing assignment-first submit/route logic in `vouchers.html`

## Production verification completed
- DirectReturn Create → Send → Receive: PASS in transaction, rolled back.
- DirectReturn invalid vehicle/rep pairing: correctly rejected by Production RPC.
- Transfer Create → Send: PASS in transaction, rolled back.
- DirectSale Create → Send: PASS in transaction, rolled back; movement=1; custody ledger=true.
- Existing posted QA history was **not deleted** because it already has stock/audit/financial effects.
- No new persistent QA records were left by these tests.

## Deployment evidence
Workflow:
`.github/workflows/warehouse_vouchers_browser_e2e_20260920.yml`

Latest workflow source commit:
`56fee06ac0145faffbc4f71d3d6031fcd3b46f87`

The validator bug was in the test harness, not the app. Its embedded Node validator now parses successfully.

Latest observed workflow run:
- Run ID: `36483037124`
- Head SHA: `56fee06ac0145faffbc4f71d3d6031fcd3b46f87`
- Last observed status during this session: `in_progress`

Do not mark Browser E2E as PASS until completed/success evidence exists.

## Infrastructure decision
No new Edge Function was created.
No new RPC/table was required.
Existing atomic RPC/stock-voucher contract is sufficient for the current defect.
No Production infrastructure change was executed.

## Next-session exact sequence
1. Start from current Git, not from an old report.
2. Check Run `36483037124` or the newest Warehouse Vouchers Browser E2E run.
3. Open current `vouchers.html`.
4. Apply only DR-UI-01 → DR-UI-04 from Report359.
5. Syntax/source validation.
6. Browser E2E.
7. Test `vansales2@rawaea.com` and verify VHL-0422 appears as DirectReturn source vehicle.
8. Reopen a Draft DirectReturn and verify `custodian_user_id` is preserved.
9. Verify Smart Search resolves the rep from Master Assignment.
10. Run DirectReturn Create → Send → Receive.
11. Run negative pairing test.
12. Only after all evidence passes, mark DirectReturn UI contract CLOSED and update this file again.
13. Then move to the next genuinely open Business Contract gap.

## Self-audit rule
Never re-fix what is already proven closed.
If historical reports conflict with current Git/source/Production/database/deployment evidence, the current evidence wins.

---

# CURRENT STATE — 2026-09-28 — Report358 DirectReturn Rep Smart Search / Master Assignment Checkpoint

## AUTHORITATIVE CURRENT REALITY
This section supersedes earlier CURRENT_STATE sections for the DirectReturn representative-search closure unit. Earlier sections remain historical records only.

### CURRENT GIT — SYSTEM
- System HEAD immediately before this final CURRENT_STATE write: a5012fca02fb988fa0194f064cf20d9d20492a3f
- Parent of that execution commit: 04cb7741e84cedf7719515cab33ab967d214808c
- This CURRENT_STATE write is the continuity checkpoint; next session MUST re-read current Git to obtain the new state commit SHA before proceeding.
- Prior state commit: c5d20c5c9cd82afaa587a155b2ebe031d03f43fc
- Report: doc/Draft/Reprots/Report358_WAREHOUSE_VOUCHERS_DIRECTRETURN_REP_SMARTSEARCH_FORENSIC_CLOSURE_20260928.md
- Production migration source recorded at:
  supabase/migrations/20260928221500_vouchers_directreturn_rep_assignment_contract_fix_20260928.sql

### CURRENT GIT — FRONTEND
- Current Frontend HEAD: f28cbe21abe2dfc8d03d02fb0491cc984a273c13
- Parent verified by compare: 8b6b32145aafdb49ae10af8f36aa888e4d25d412
- Latest HEAD commit: Add draft voucher check for current user
- companies/company-1/warehouse/vouchers.html current blob: 60f4b85ecf3dc32e45cc944bbbbd512ac37ea2a2
- vouchers.html current size: 6,340 lines / 208,577 chars
- main.html remains protected and untouched
- van-sales.html remains protected and untouched

### CURRENT SOURCE — PROVEN ROOT CAUSE
Target:
companies/company-1/warehouse/vouchers.html

The DirectReturn representative picker had three coupled Consumer-Layer defects:

1. routeHtml() around line 4268 called:
   p('wsRep','مندوب البيع المباشر',true)
   so the search input was readonly.

2. pickArr() around line 3601 derived branch context from wsFrom. In DirectReturn wsFrom is a Vehicle ID, not a Branch ID. Therefore the generic wsRep path could resolve no branch and return an empty representative list.

3. pickSelect() around line 4116 resolved DirectReturn representative only through vehicle.driver_id and then made wsRepSearch readonly. Current Production vehicles use fleet_vehicle_sales_rep_assignments as the active primary relationship while driver_id is NULL.

A fourth coupled source defect existed in submit():
the DirectReturn validation derived rr from vv.driver_id rather than treating the selected/master-assigned representative as the current contract.

### CURRENT PRODUCTION — PROVEN RELATIONSHIP
Production authoritative relationship:
public.fleet_vehicle_sales_rep_assignments

Current active Primary assignments observed:
- CHV-2025-01 -> vansales@rawaea.com
- VHL-0422 -> vansales2@rawaea.com

For these vehicles Production shows driver_id = NULL.

Existing public.fleet_query('direct_sales_rep_assignments') returns the active Master Assignment rows correctly under an authenticated actor.

### PRODUCTION FIX EXECUTED
No new Edge Function.
No new table.
No new RPC.

Existing functions updated in-place:
- public.create_manual_stock_voucher_atomic_core_12_20260828
- public.update_manual_stock_voucher_atomic

DirectReturn representative validation now uses:
1. active primary fleet_vehicle_sales_rep_assignments
2. legacy vehicles.driver_id fallback

This preserves historical compatibility while aligning the current operation with the Mother system's authoritative Master Assignment.

### PRODUCTION QA — THIS SESSION
Pre-fix forensic fixture:
- An invalid DirectReturn pairing (CHV-2025-01 + vansales2) was accepted by the pre-fix Create contract as IN-9.

Post-fix:
- The same invalid pairing was rejected with:
  المركبة المصدر لا تتبع مندوب البيع المباشر المحدد
- A valid pairing (CHV-2025-01 + vansales@rawaea.com) created IN-10 successfully.
- Authenticated update of the valid Draft was executed inside a transaction and returned success; transaction was rolled back.
- IN-9 and IN-10 were deleted with the existing Draft deletion guard.
- Current transient Draft count after cleanup: 0
- Current DirectReturn voucher count after cleanup: 0

### OWNER FRONTEND PATCH — OPEN / NOT APPLIED BY ASSISTANT
The owner must patch only vouchers.html.

Required surgical elements are stored in Report358:
1. routeHtml() DirectReturn line: remove the literal readonly argument from the wsRep picker.
2. pickArr() wsRep block: add a DirectReturn branch that derives candidate representatives from active vehicle Master Assignment / legacy driver and uses wsTo as the receiving-branch authorization context.
3. pickSelect() DirectReturn wsFrom block: resolve the representative from vehicleRepMap first, driver_id second; keep wsRepSearch editable.
4. pickSelect() wsRep block: for DirectReturn, resolve the representative's current primary vehicle and synchronize wsFrom to it, with receiving-branch authorization.
5. submit() DirectReturn rr element: prefer the selected wsRep / current Master Assignment and reject selected-rep vs vehicle mismatches.

Do not replace whole functions. Use the exact element replacements in Report358.

### PROTECTED / DO NOT REOPEN
- main.html
- van-sales.html
- DirectSale Draft Report357 repair
- Transfer destination/receiver contract
- Transfer source binding
- DirectReturn SEND authorization branch correction
- DirectReturn mobile-branch correction
- SupplierReturn contract
- existing stock writer / idempotency path
- prior Report349–357 closures

### DEPLOYMENT / E2E
- Production database contract: VERIFIED
- Production invalid/valid Create tests: VERIFIED
- Authenticated Update transaction test: VERIFIED
- Frontend source patch: READY only
- Frontend source write by assistant: NOT DONE
- Browser E2E: OPEN
- Served/published artifact identity: OPEN

Browser/served closure MUST NOT be claimed before owner merge + publish + actual interactive DirectReturn test.

### NEXT EXACT RESUMPTION
1. Re-fetch current Frontend HEAD and vouchers blob.
2. Apply only the five surgical elements from Report358.
3. Read vouchers.html completely after merge.
4. Parse all inline JS using a script detector that accepts script-tag attributes.
5. Test DirectReturn picker:
   - focus wsRep
   - type Arabic/name/email fragment
   - receive filtered rows
   - select rep
   - verify mapped vehicle
   - select destination branch
   - verify branch authorization
6. Create Draft and reopen it.
7. Submit through current create-stock-voucher path.
8. Re-check Production Master Assignment and stock-voucher custodian_user_id.
9. Publish and verify served artifact identity.
10. Run authenticated Browser E2E.
11. Only then close this closure unit and move to the next genuinely open Business Contract.

### CLOSURE RULE
Do not re-fix a closed historical unit.
Do not treat a report as current truth.
Use:
CURRENT GIT → CURRENT SOURCE → CURRENT PRODUCTION → CURRENT DATABASE → CURRENT DEPLOYMENT EVIDENCE.

# CURRENT STATE — 2026-09-28 — Report357 DIRECTSALE DRAFT MODAL ACTIONS ROOT-CAUSE CHECKPOINT

## AUTHORITATIVE CURRENT REALITY

This section supersedes earlier CURRENT_STATE sections for this specific Warehouse Vouchers closure unit. Older sections remain historical records only.

### Current System Git
- Report357 commit: 5a854bc731dd28e8272b5e93a757116e8a17424b
- Parent: b99dc6f57ea43a3d19a23188da5377cb296745a6
- Report357: doc/Draft/Reprots/Report357_WAREHOUSE_VOUCHERS_DIRECTSALE_DRAFT_MODAL_ACTIONS_FORENSIC_CLOSURE_20260928.md
- The report records the proven root cause and the owner-only surgical source patch.

### Current Frontend Git
- HEAD: 8b6b32145aafdb49ae10af8f36aa888e4d25d412
- Parent: cd125b126cd40527a81f20508139506b8e48031f
- companies/company-1/warehouse/vouchers.html blob: bb0dd32e790fc55161a409e746f2ea778e44ae3b
- vouchers.html: 6327 lines / 208151 chars
- main.html blob: 810e4f5440f5975f55099a124deb42b086a49183 — protected / untouched
- van-sales.html blob: 8d61382a8e0025a0d079e71dd94f33d106d9088e — protected / untouched

### What changed in current HEAD and what did not
- Commit 8b6 already contains Report356's loadList → inventory_voucher_report migration.
- Existing codeJs quoting correction is already present; do not repeat.
- Existing modal topActions already contains Draft Edit/Delete/Send/Print handlers.
- Existing printDraftVoucher() is valid; do not modify.
- The current defect is not in main.html, van-sales.html, details(), cards(), loadList(), or print functions.

### ROOT CAUSE — PROVEN
File: companies/company-1/warehouse/vouchers.html
Function: actionFor:function(v)
Target element: the second generic if(v.status==='Draft') block around line 608.

Current defect:
- Production inventory_voucher_report securely returns an authorized user's Draft in Pending.
- For non-privileged users it deliberately redacts created_by.
- Current pending row therefore has status=Draft and created_by=null.
- actionFor() relied on creator = currentUser.email == voucher.created_by.
- creator becomes false, privileged is false, actionFor returns ''.
- details() therefore does not enter act='draft' and the in-modal Draft toolbar is not rendered.

### Production proof
- Controlled DirectSale Draft fixture was created through the existing create_manual_stock_voucher_atomic path.
- Pending list returned the Draft.
- VOUCHER_AUDIT returned Header + Item detail under the existing employee redaction contract.
- Unrelated employee detail access was blocked centrally with: غير مصرح بالوصول إلى هذا الإذن.
- Therefore the backend authorization contract is working and the UI authorization-decision layer is the defect.

### OWNER SURGICAL SOURCE CHANGE — ONLY OPEN SOURCE ACTION
File:
companies/company-1/warehouse/vouchers.html

Function:
actionFor:function(v)

Around line:
608

Delete exactly this second generic Draft element:
    if(v.status==='Draft'){
        return(
            creator||
            privileged
        )?'draft':'';
    }

    if(v.status==='Sent'){

Replace it completely with:
    if(v.status==='Draft'){
        var draftListedForCurrentUser=
            s.tabName==='pending'&&
            Array.isArray(s.vouchers)&&
            s.vouchers.some(function(row){
                return(
                    row&&
                    row.status==='Draft'&&
                    String(row.voucher_code||'')===
                    String(v.voucher_code||'')
                );
            });

        return(
            creator||
            privileged||
            draftListedForCurrentUser
        )?'draft':'';
    }

    if(v.status==='Sent'){

No Frontend write was made by the assistant.

### Verification
- Current source inline JavaScript parse: PASS.
- In-memory patched source parse: PASS.
- Current source contains the defective target exactly once.
- Patched action simulation returns draft for the authorized Draft present in Pending.
- Unlisted Draft returns no draft action in the same simulation.
- Expected in-modal actions: Edit / Delete / Send / Print.
- codeJs repair remains present and was not repeated.

### Production / Database
No new Production schema change, RPC, Edge Function, or migration is required for this root cause.
Existing inventory_voucher_report and inventory_control contracts remain authoritative.
No new Edge Function was created.

### QA cleanup
Final Manual voucher counts after cleanup:
- Draft = 0
- Sent = 0
- Received = 1
- Completed = 5
- IN-8 detail residue = 0
- IN-8 inventory movement residue = 0
The QA operation identity tombstone remains protected by the existing integrity guard.

### E2E / Deployment
- RPC/database reproduction: PASS.
- Authorization denial test: PASS.
- In-memory UI fix simulation: PASS.
- Authenticated Browser E2E: OPEN / UNVERIFIED.
- Served/published artifact identity: OPEN / UNVERIFIED.
Do not call these Browser/served checks complete until the owner source is merged, published, and tested.

### Separate OPEN hardening
editVoucher() and printDraftVoucher() use direct company-scoped table SELECTs. This is not the root cause of the current missing buttons and is not changed in this session. A separate consumer/RLS audit is required before hardening this path.

### Protected / DO NOT REOPEN
- main.html
- van-sales.html
- closed transfer source/destination contract
- receiver binding
- partial/full receive backend
- DirectReturn contract
- SupplierReturn contract
- existing Edge/RPC path
- prior Report349–356 repairs

### NEXT EXACT RESUMPTION POINT
1. Verify Frontend HEAD and vouchers blob above.
2. Apply only the one owner replacement in actionFor() around line 608.
3. Read vouchers.html completely after merge.
4. Parse complete inline JavaScript.
5. Verify draftListedForCurrentUser appears once.
6. Verify Draft modal renders Edit/Delete/Send/Print.
7. Publish/deploy.
8. Verify served artifact identity.
9. Run authenticated Browser E2E.
10. Re-run Production scope/redaction assertions.
11. Close this unit only after runtime evidence; then move to the next real open Business Contract.
### STATUS
ROOT CAUSE: PROVEN
PRODUCTION CONTRACT: VERIFIED
PRODUCTION CHANGE: NOT REQUIRED
OWNER SOURCE PATCH: OPEN
BROWSER E2E: OPEN
DEPLOYMENT EVIDENCE: OPEN

---

# CURRENT STATE — 2026-09-28 — Report356 VOUCHERS SCOPE/MODAL PRODUCTION CLOSURE CHECKPOINT

## AUTHORITATIVE CURRENT CHECKPOINT
This section supersedes earlier CURRENT_STATE sections for the Warehouse Vouchers closure unit. Historical sections below remain records only.

### Current Git — System
- Pre-state HEAD verified: `21d4171b8f3efbbd5340198eb6a640ac9bbe55c8`
- Pre-state parent verified: `4b62e4b5f730186263daa63a0c7fa3dcbf60f77a`
- Report356 commit: `10ff4e0bc930a409a860b3722849621dcdf1ff72`
- CURRENT_STATE is being updated immediately after Report356.

### Current Git — Frontend
- Frontend HEAD: `cd125b126cd40527a81f20508139506b8e48031f`
- Frontend parent: `85e825de61333f3b7da014580dd7275146818b2a`
- `companies/company-1/warehouse/vouchers.html` blob: `4b99d7f12ab0fb255b523ae29465b7d3a9f56047`
- `vouchers.html`: 6,332 lines / 210,062 chars
- `main.html` blob: `810e4f5440f5975f55099a124deb42b086a49183`
- `van-sales.html` blob: `8d61382a8e0025a0d079e71dd94f33d106d9088e`

### Source Truth — What is CLOSED
- Current `cd125...` already contains the corrected single-quoted `codeJs` construction in `cards()` and `details()`.
- Do NOT repeat the `codeJs` repair.
- Do NOT touch `printVoucher()`; its current print-window implementation is valid and uses `.no-print`.
- Do NOT touch `main.html`.
- Do NOT touch `van-sales.html`.

### Source Truth — ONLY OWNER FRONTEND ACTION
File: `companies/company-1/warehouse/vouchers.html`

1. `loadList:function(scope)` around line 648:
   replace the current direct `supabase.from('stock_vouchers')...` function with the exact Report356 PATCH 1 using existing RPC `inventory_voucher_report` and payload `workflow_scope=pending|completed`.

---

# CURRENT STATE APPEND — 2026-09-30 — EXPERIMENTAL STOCK DATA CLEANUP (REPORT 380)

- This session executed the requested cleanup of experimental stock-voucher records.
- Deleted successfully: IN-1 DirectSale; IN-7 Transfer; IN-8 DirectSale; IN-9 DirectReturn; IN-3 SupplierReturn; IN-4 SupplierReturn.
- Remaining target records: IN-5 SupplierReturn (Completed) and QA-SR-UI-CONTRACT-20260927-01 (Completed).
- The remaining two records are protected from hard deletion by the current Production integrity path for executed/manual vouchers. No triggers were disabled and no replication-role bypass was used.
- Production branch stock totals observed after cleanup: BR-01 71/0; BR-2 10/0; VAN-CHV-2025-01 0/0; VAN-VHL-0422 0/0.
- Latest frontend repository remains papamohammed77-glitch/erp-frontend. Latest known commit is 503fb79da0878f97af46c8adad5bdedb0b3c283f with parent 1b89202949575eaebed4c5bf5512322129a114fb. The latest Van Sales source already contains the showRecentCustomers auth_id fix; no duplicate patch was applied.
- System repo latest commit after this report is 58c64ad0ff2d33e80903000bda07bc4a02f07a65.
- Report: doc/Draft/Reprots/Report380_EXPERIMENTAL_DATA_CLEANUP_20260930.md
- Frontend deployment/browser E2E remains Owner-side verification and was not altered in this cleanup session.

---
# CURRENT STATE APPEND — 2026-09-30 — REPORT 381 / SUPPLIERRETURN CLEANUP + VAN SALES FORENSIC
- Executed Production cleanup of the two remaining experimental Completed SupplierReturn vouchers: IN-5 and QA-SR-UI-CONTRACT-20260927-01.
- Verified afterward: SupplierReturn records 0; targeted voucher records 0; targeted details 0; related inventory_log 0; related journal_entries 0; related finance_tax_transactions 0; related ERP operation registry matches 0.
- Verified 14 audit_log rows remain for the deleted test voucher identities.
- Temporary corrective deletion helper was retired and normal voucher/detail deletion guards were restored. No trigger disabling or replication-role bypass was used.
- Canonical post-cleanup migration record added: supabase/migrations/20260930_supplier_return_cleanup_final_baseline.sql
- Final report added: doc/Draft/Reprots/Report381_SUPPLIER_RETURN_CLEANUP_AND_VAN_SALES_EXECUTION_20260930.md
- Current Van Sales source verified at blob b754208f38a52b67794e9d02003ed8751f3a7c68, 3294 lines.
- Latest frontend commit: 503fb79da0878f97af46c8adad5bdedb0b3c283f; parent 1b89202949575eaebed4c5bf5512322129a114fb.
- Current Van Sales source contains the auth_id correction in showRecentCustomers and company-scoped syncDown. No new frontend defect was proven in this session; no frontend source was changed.
- Production setup-van-branch v5 resolves the authenticated user through public.users.auth_id and company_id, then resolves the vehicle/VAN branch inside that company.
- Production current relevant Edge versions observed in this session include save-sales-invoice v15, save-receipt-voucher v8, save-inventory-count v5, save-daily-settlement v4, start-picking v34, complete-picking v17, start-loading v5, complete-loading v11, reopen-loading v2, unload-runsheet v6, complete-return v26, complete-order-delivery v14, bulk-stock-adjustment v8, send-stock-voucher v7, receive-stock-voucher v5, receive-purchase v9.
- Physical stock UPDATE scan currently identifies post_stock_movement as the physical stock writer; reserve_stock/release_stock_reservation remain reservation writers.
- Van Sales browser-rendered E2E remains Owner-side open.

---
# CURRENT STATE APPEND — 2026-10-01 — REPORT 382 / DIRECTRETURN + REPRESENTATIVE COLUMN FORENSIC CLOSURE

## Current Git baseline used in this session
- System repository: papamohammed77-glitch/rawaie-erp-New
- main HEAD at session start: 8a175b78f09e382e7630efd09c6d97a7385e1876
- Parent: b0cab4f2f63b957c449c537a445e755593712bdb
- Current mother source: Current/PWA/main.html
- Current mother source SHA: 27b777528665dcc985809648f006452c861ae36e
- Mother source was NOT modified by this session; owner-side surgical patch is recorded in Report382.
- Frontend repository: papamohammed77-glitch/erp-frontend
- Current frontend HEAD: 503fb79da0878f97af46c8adad5bdedb0b3c283f
- Frontend parent: 1b89202949575eaebed4c5bf5512322129a114fb
- Current vouchers.html blob: 85e709d0f41c189c6624a6160965d3b1a41960ba

## Report 382 — DirectSale / DirectReturn Representative Projection
- Production/current-source forensic review proved that the authoritative representative identity for DirectSale and DirectReturn is stock_vouchers.custodian_user_id -> public.users.id.
- The embedded voucher table in Current/PWA/main.html currently lacks the representative column and does not resolve custodian_user_id to a representative name.
- The normal parent navigation delegates vouchers to ./vouchers.html; the standalone current vouchers.html already has representative lookup/custody context. The requested main.html change is therefore a compatibility/read-model patch, not a new operational workflow.
- Owner-side main.html patch is exactly four surgical substitutions. No function is to be replaced wholesale. See Report382 for exact search strings and replacements.

## Production defect discovered and fixed during current-state verification
- Current Production exposed a real DirectReturn RECEIVE defect that was not safe to consider closed from historical reports.
- post_manual_stock_voucher_atomic_core_20260828 previously mapped DirectReturn RECEIVE to movement_type='DirectReturn' while setting src=NULL.
- The central post_stock_movement contract requires a real source for movement_type='DirectReturn', and DirectReturn SEND had already removed the quantity from the vehicle mobile stock. A second decrement was therefore both impossible and semantically incorrect.
- Production canonical fix: DirectReturn RECEIVE now maps to movement_type='InventoryIncrease'. This adds the returned quantity to the destination branch without attempting a second vehicle deduction.
- No new Edge Function was created. Existing authenticated Edge/RPC path remains unchanged.
- Canonical migration added:
  supabase/migrations/20261001090000_fix_directreturn_receive_stock_direction_contract.sql
- Migration commit: 6ae450aa42bc2d6cf4bcc30879e96365dbdde4c7

## Production E2E evidence
A transactional rollback test used existing Production master data:
- Company: 00000000-0000-0000-0000-000000000001
- Branch BR-01: a38332b6-6cea-480a-ada1-6eb6ab0590db
- Vehicle CHV-2025-01: 69b08188-60ee-43af-9644-e1626a85bfa0
- Vehicle mobile branch: 2fffcf58-be04-4599-a289-8791362398ff
- Direct-sale representative: 111b0730-a977-4d11-bcd0-2427b178a9e5 / vansales@rawaea.com
- Item 1001: 7cf845d8-34b9-47d1-9b7f-d9f1f597dbf8
- Initial BR-01 stock: 8, allocated 0.

Observed:
- DirectSale CREATE -> Draft with custodian_user_id = representative.
- DirectSale SEND -> Sent; BR-01 8->7; mobile stock 0->1; custody debit 50.
- DirectReturn CREATE -> Draft with same custodian_user_id.
- DirectReturn SEND -> Sent; mobile stock 1->0; branch remains 7.
- DirectReturn RECEIVE -> Received; branch 7->8; mobile remains 0; custody credit 50.
- Repeated RECEIVE with same operation_id returned duplicate=true with no additional movement.
- Inventory log contained the expected three movement records for the two-stage cycle.
- driver_ledger rows 0->2 and balance returned 0 after debit 50 + credit 50.
- General journal remained unchanged: 10 entries and 16 lines before and after the test.
- The test deliberately raised an exception after collecting results so all QA data rolled back. Post-test Production checks showed zero QA voucher rows and BR-01 item 1001 back at qty 8 / allocated 0.

## Browser evidence boundary
- The existing erp-frontend warehouse-vouchers Playwright workflow remains the correct rendered browser gate.
- No workflow dispatch capability was available in this session; therefore browser-rendered E2E is NOT marked as PASS.
- Source-level syntax and representative mapping checks passed for the surgical patch.
- After the owner applies the main.html patch and deploys, rendered browser verification is the remaining owner-side gate.

## Files/areas intentionally not modified
- Current/PWA/main.html
- companies/company-1/warehouse/vouchers.html
- inventory_voucher_report()
- post_stock_movement()
- create-stock-voucher
- send-stock-voucher
- receive-stock-voucher
- navigation/permission contracts
- stock_vouchers schema
- vehicle/representative assignment schema

## Canonical continuity rule
Historical reports are advisory only. The current baseline is:
CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.
Do not re-apply a historical repair merely because a report describes it. Re-verify the current contract first.

## Current source of truth for next session
1. Read this append and Report382.
2. Re-verify post_manual_stock_voucher_atomic_core_20260828 contains DirectReturn -> InventoryIncrease for RECEIVE.
3. Do not touch that RPC again unless current Production contradicts this state.
4. Apply only the four main.html surgical substitutions recorded in Report382.
5. Validate main.html source syntax and representative mapping.
6. Deploy the changed main.html.
7. Run the existing warehouse-vouchers browser E2E workflow.
8. Verify DirectSale and DirectReturn rows display the representative name.
9. Verify non-rep voucher types remain '-'.
10. Verify refresh/reload and empty-state behavior.
11. Do not alter the operational stock workflow in response to a display-only change.

## Report
- doc/Draft/Reprots/Report382_WAREHOUSE_VOUCHERS_DIRECTRETURN_REP_COLUMN_FORENSIC_CLOSURE_20261001.md
