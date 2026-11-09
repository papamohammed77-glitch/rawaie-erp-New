# Report680 — Purchasing Supervisor Procurement Cycle Expansion
**Date:** 2026-11-09 (Africa/Cairo)  
**Checkpoint:** LVE-2026-11-09-680  
**Workstream:** Purchasing Supervisor — company-wide procurement cycle visibility

## 1. Executive result

The Purchasing Supervisor application was expanded from three tabs to the complete parent-style procurement cycle, plus the existing Suppliers tab. The change is committed to operational `main` in a single file:

- Repository: `papamohammed77-glitch/erp-frontend`
- Branch: `main`
- Final commit: `4240285ab136c0e36451b8c7623b989257d183e9`
- Final file blob: `9ed398c3a14eefa34cb7857bbe3c82d6e71fda96`
- Changed path: `companies/company-1/purchasing/supervisor.html`
- Source: https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/purchasing/supervisor.html
- Commit: https://github.com/papamohammed77-glitch/erp-frontend/commit/4240285ab136c0e36451b8c7623b989257d183e9

The final commit was fetched again from GitHub. Its commit file list confirms that only `supervisor.html` changed. The final inline JavaScript parsed successfully.

**Release status: source committed; Cloudflare production deployment and authenticated browser E2E are NOT VERIFIED.** This report does not describe the feature as fully field-accepted or released.

## 2. Implemented tab structure

The app now exposes the ten procurement-cycle sections used by the parent, while retaining Suppliers as an additional section:

1. `dashboard` — لوحة المشتريات
2. `requests` — طلبات الشراء
3. `rfq` — طلبات عروض الأسعار
4. `quotations` — عروض الموردين
5. `orders` — أوامر الشراء
6. `invoices` — فواتير الشراء
7. `returns` — المرتجعات
8. `payments` — دفعات الموردين
9. `reports` — التقارير
10. `settings` — الإعدادات
11. `suppliers` — الموردون

Each route is registered in `App.switchTab` and `refreshCurrentTab`. The document lists provide search/status filtering and read-only detail views where the underlying child tables are available.

## 3. Data scope, role and RLS constraints

The Production Supabase project checked read-only was SMART ERP: `fiilmooggumokxanwiyx`.

The Purchases Supervisor role previously verified in Production has `purchases_supervisor` and `suppliers`, not the broader `purchases`, `branches`, `users`, or finance permissions. The implementation therefore uses company-scoped direct SELECTs governed by current RLS, rather than the existing generic `GET_DATA` Edge operation whose gate does not include `purchases_supervisor`.

Header reads use:
- Explicit `company_id = currentUser.company_id` filters.
- Deterministic pagination in 200-row ranges until the last partial page.
- No 300-row cap.
- Parent-ID filters for child tables, with the existing RLS policies remaining authoritative.

Invoice visibility is company-wide, not limited by the logged-in purchaser. The interface labels `created_by` as the document registrar, not as the purchasing employee; it does not query the broad employee directory or expose `purchaser_user_id` values as raw identifiers.

Branch enrichment is optional. Because the supervisor role cannot necessarily read `branches`, a branch lookup error no longer aborts the purchase-order screen. When a branch label cannot be read, the UI displays `غير متاح بصلاحية الحساب` and never prints the branch UUID.

Supplier reads are company-scoped under the existing `suppliers` permission. Supplier-supplied strings are escaped before insertion into the rendered HTML. RFQ invited-supplier detail uses the existing `purchase_rfq_suppliers` relation and permitted supplier labels.

## 4. Business and financial safety boundaries

This ChangeSet adds read-only views and summaries. It does not add create, convert, accept, invoice-post, return-post, payment-post, or settings-write actions.

The pre-existing purchase-order approval path remains the only existing mutating UI action. Its `APPROVE_PO` call was preserved; it was not expanded into receipt, stock, payable, cash, or journal posting.

The current Production schema was inspected before selecting columns. Two important constraints were handled explicitly:
- `purchase_returns` and `purchase_payments` do not carry a currency column in their current records. The report does not fabricate EGP or combine their values under an assumed currency.
- Invoice amounts and PO/quotation amounts are grouped by each document's currency; unlike currencies are not added together.

Purchase settings are displayed read-only. The raw `default_branch_id` is not shown. Document status/source values are mapped to readable Arabic labels where the live constraints establish their codes.

**No Production business mutation was made:** no SQL DDL/DML, migration, RLS policy, Edge Function, stock quantity, supplier balance, AP, Treasury, cash box, payment, return, journal, or GL record was written by this workstream.

## 5. Verification performed

### Source and schema checks
- Final GitHub file fetched after commit; final blob SHA verified.
- Final inline script parsed with the JavaScript ECMAScript parser.
- Final commit metadata inspected; its only changed file is `companies/company-1/purchasing/supervisor.html`.
- Production column definitions were inspected read-only for requests, RFQs, quotations, orders, invoices, returns, payments, settings, suppliers, RFQ suppliers, and relevant child-detail/allocation tables.
- Production check constraints were queried read-only to verify actual status values.

### Behavioural harness (isolated synthetic fixtures; no Production writes)

The harness executed the actual extracted application methods and table configuration against a mocked Supabase client whose select lists were validated against the observed Production column allowlists.

| Test | Result |
|---|---|
| Requests list and schema-compatible SELECT | PASS |
| RFQ list and schema-compatible SELECT | PASS |
| Supplier quotations list | PASS |
| Invoice list including 451 company invoices across multiple 200-row pages | PASS |
| Foreign-company invoice excluded from results | PASS |
| Invoice tab includes all purchasing users, not only the logged-in purchaser | PASS |
| Returns list | PASS |
| Supplier payments list | PASS |
| Settings read-only display | PASS |
| Orders remain visible when the branch lookup is denied by RLS | PASS |
| Branch permission fallback shown instead of UUID | PASS |
| RFQ invited supplier label | PASS |
| Payment allocation detail select without duplicate `created_at` | PASS |
| Dashboard rendering and separated currency groups | PASS |
| Reports rendering without inventing payment currency | PASS |
| Company filter applied to all tested procurement headers | PASS |
| No direct database INSERT/UPDATE/UPSERT/DELETE in the new UI code | PASS |
| Existing PO approval is the sole `RW_API.call('save-purchase-order',...)` path | PASS |
| All 11 tab IDs/routes are present | PASS |

The 451-invoice fixture plus a foreign-tenant row tested pagination beyond both 200 and 300 records and tenant isolation. These are synthetic behavioural tests, not a substitute for authenticated Production E2E.

## 6. Realtime and refresh

The application subscribes through the existing `RW_Realtime` helper to company-scoped header tables: requests, RFQs, quotations, orders, invoices, returns, payments, purchase settings, and suppliers. Realtime/reconciliation refreshes the active tab. The implementation does not claim measured delivery latency or prove cross-device field synchronization; that requires a live authenticated E2E observation.

## 7. E2E, CI and deployment — current truth

**Authenticated browser E2E: NOT RUN.** The connected Parent ERP browser tab currently presents the sign-in form, not an authenticated Purchases Supervisor session. The available browser integration in this session exposes read-only tab inspection; it does not provide navigation/click/type or an authenticated supervisor browser context. No login credentials were requested, guessed, or used.

**Cloudflare production deployment: UNVERIFIED.** A Cloudflare dashboard tab existed, but its visible deployment snapshot identified a different earlier commit (`3efb9fe`, Buyer Tailwind build), not this supervisor commit. The current deployment pointer/artifact for `4240285` could not be refreshed or independently confirmed through the available tools. No manual deployment was initiated.

**GitHub checks:** the final commit has no combined status checks and no associated workflow runs returned by the GitHub API. This is not evidence of a passing CI pipeline.

Accordingly, the remaining release gates are:
1. Verify the Cloudflare Pages Production deployment points to `4240285ab136c0e36451b8c7623b989257d183e9` and that the published asset matches the final source.
2. Run authenticated E2E with a real supervisor account carrying only `purchases_supervisor,suppliers`; visit all eleven tabs, verify complete company invoice visibility, test search/status filters, details, branch-denied fallback and realtime refresh.
3. Confirm that no forbidden write controls are exposed and that no stock/finance effect occurs during the read-only test. Do not click PO approval during acceptance.
4. Record the E2E and deployment evidence before calling the feature field-accepted.

## 8. Rollback

The change is confined to one source file. The pre-change file blob SHA was `8d46c3c6d6df487ebd880c29d438bcdd2bd789bf`. Rollback, if required, is to restore that exact file content through the reviewed repository workflow, then verify the resulting commit and Cloudflare deployment. Do not revert unrelated files or database objects.

## 9. Final disposition

- **Code implementation:** committed to operational main.
- **Syntax:** passed.
- **Synthetic behavioural checks:** passed.
- **Production database writes / stock / finance:** none.
- **Cloudflare Production deployment:** unverified.
- **Authenticated supervisor E2E:** not run.
- **Release/field acceptance:** pending those two external verification gates.

This checkpoint is deliberately evidence-based. The feature is implemented at source level, but no claim of 100% operational correctness or production release is made without deployment and authenticated browser evidence.
