# Report694 — Warehouse Module Data-Read Failures & Connection Verification

**Date:** 2026-11-10 (Africa/Cairo)
**Workstream:** RAWAEA ERP / Standalone Unified Warehouse
**Operational repository:** papamohammed77-glitch/erp-frontend / main
**Verified latest operational HEAD:** 172120584039fcdbdd4cda866d26870c9ac34a4c

## 1. Request and continuation point
Continued directly from LVE-2026-11-10-693 and operational HEAD a98625c. No rebuild or replacement of the native warehouse application was started. The request was to close remaining tab data-load failures and verify the actual Supabase connection.

## 2. Confirmed root cause — preparation workspace
The shared RW_Auth identity normalizer in companies/company-1/core.js returns a client profile with name, email, company_id, id, permissions, activeWarehouseRole and branch scope. It does not return Supabase auth.user.user_metadata.
The native Picker/Preparation workspace had already been switched to RW_Auth.init and stored that normalized object in currentUser. Its renderRunsheetLists() and renderAccount() continued to dereference currentUser.user_metadata.name. The two runsheet queries succeeded, then rendering threw a TypeError. The broad catch converted that JavaScript rendering failure into the misleading message: “فشل تحميل البيانات. تأكد من الاتصال.”
This is a client profile-contract mismatch, not a network disconnection or missing runsheet permission. The live request log confirms both preparation runsheet GETs returned HTTP 200 for the linked warehouse account at 2026-11-10T18:29:52Z.

## 3. Operational source repair
Only companies/company-1/warehouse/warehouse.html was changed in the application code. No shared core, child standalone application, parent main.html, SQL function, Edge Function, stock writer, accounting writer or posting contract was changed.
Applied fixes:
- Picker/Preparation pending list now reads currentUser.name and safely falls back to the email prefix or a neutral label.
- Picker/Preparation account renderer now reads the normalized shared profile name/email rather than nonexistent user_metadata.
- Picker pending and completed paths log the actual rejected/render exception while keeping safe user-facing messages.
- Loader pending path now checks both Supabase Promise.all result objects for .error before using .data; a returned PostgREST error can no longer be silently shown as an empty list.
- Unloader pending and completed paths now check returned Supabase errors before rendering and log the underlying failure.
- Returns completed list now checks the returned Supabase error; pending and completed rejected requests include diagnostic logging.
- Manual vouchers / supplier-return contract now checks the purchase-order and purchase-invoice reference query errors before rendering the contract. Existing contract RPC errors are propagated to the existing fail-closed error path instead of silently continuing with missing contract state.
- Counter completed inventory-count history now checks Supabase .error before treating data as a valid list and logs rejected request/render errors.

Application commits:
- f7ff4d74ae5b7f9f7a2ceae96a101a6aa5858503 — normalized Picker profile-name access and corrected pending Loader/Unloader/Counter result handling.
- ad40d8bfcca9863113b39a5614efc7898f97977d — Picker completed diagnostics, Returns completed result handling, and supplier-return contract reference fail-closed handling.
Latest application blob SHA: 1d04db1f8ae6e79dc9997fbfe58a51c38f067458.

## 4. Regression workflow
Updated .github/workflows/warehouse_hub_browser_e2e_20261110.yml.
- Static checks now reject a reintroduction of currentUser.user_metadata.name in Picker.
- Static checks require explicit result-error handling in Loader, Unloader, Returns, Counter and the SupplierReturn purchase-reference loader.
- Playwright now asserts the actual empty-state rendering of Picker/Preparation, Loader, Unloader and Returns. The Picker test also directly renders the account view against the normalized shared identity profile.
- Existing four-tab, seven-native-workspace, role-alias, branch-gate, logout/relogin and voucher contract tests remain.
Workflow commits:
- 42124a40b28131b8c1c82591b340aacd591961ab — Preparation/Loader/Unloader browser rendering regression tests.
- 172120584039fcdbdd4cda866d26870c9ac34a4c — Returns and supplier-reference error-path regression assertions.
Latest workflow blob SHA: 444576c74fe7945a51f29c5331fe7cfa1de0e86f.

## 5. Verification evidence
Completed locally through source inspection and tool execution:
- All seven embedded native workspace JavaScript bundles parse successfully with new Function().
- The workflow static-test JavaScript block parses successfully.
- The workflow Playwright browser-test block parses successfully as an async module body.
- All six source assertions for the Picker/Loader/Unloader/Returns/Voucher/Counter changes passed.
- Current source confirms the legacy Picker currentUser.user_metadata.name references are absent.

Live SMART ERP connection evidence for auth user 399ecb52-db10-418a-8611-9472c755cd3d (linked public.users profile f9ce2c11-cd7f-4ed0-ab69-7d2ec5051c52):
- get_warehouse_hub_snapshot returned HTTP 200 at 18:29:49.978Z and 18:29:57.054Z.
- Picker open/confirmed and assigned-picking runsheet reads returned HTTP 200 at 18:29:52.971Z.
- Loader picked/loading reads returned HTTP 200 at 18:25:10.220Z and 18:25:10.221Z.
- Unloader loaded/delivering runsheet read returned HTTP 200 at 18:22:48.842Z.
- Returns returning/delivered reads returned HTTP 200 at 18:23:19.324Z and 18:23:19.384Z.
These live HTTP 200 records were produced by the existing deployed build before the new UI fix; they prove connectivity and query access, not deployment of this new commit.

## 6. Production data integrity
Read-only post-change counts:
| Table | Rows |
|---|---:|
| inventory_log | 78 |
| stock_branches | 58 |
| stock_vouchers | 0 |
| stock_voucher_details | 0 |
| purchase_invoices | 5 |
| supplier_ledger | 3 |
| journal_entries | 21 |
| inventory_counts | 0 |
| inventory_count_details | 0 |
No stock, invoice, supplier ledger, cash, treasury, journal, GL or inventory-count business write was performed in this task. No migration, DDL, RLS or Edge deployment was performed.

## 7. Deployment and CI verification boundary — NOT CLOSED
- The Cloudflare dashboard tab last opened at 18:29:39Z and showed Production/main at commit a98625c. It was a pre-fix snapshot; later commits f7ff4d7, 42124a4, ad40d8b and 1721205 were not visible in that snapshot.
- Cloudflare automatic deployments were shown as enabled, but the latest Production deployment was not independently refreshed or verified. The public production URL was inaccessible through the available web/container fetch paths in this session.
- GitHub combined commit status returned no status entries. The available GitHub connector exposes no workflow-run listing/dispatch operation for push-triggered runs; the existing workflow is configured for automatic push execution, but its actual result for 1721205 could not be retrieved. Do not mark the new Playwright E2E as passed until the run is visible.
- A real interactive post-fix employee browser session could not be launched through the read-only Chat-mode browser connector. Supabase proves the existing employee session can authenticate and read scoped data; it does not prove the updated rendered HTML has been deployed and exercised.

## 8. Last verified event and exact resumption
Last verified source event: operational main contains the Picker normalized-profile fix and the additional module read-error checks; all seven module scripts and both workflow JavaScript blocks parse. Live Supabase connectivity is confirmed by the account-scoped HTTP 200 records above. Production business counts are unchanged.
Status: SOURCE FIX COMMITTED + SUPABASE CONNECTIVITY CONFIRMED + MODULE/WORKFLOW SYNTAX PASS + DATA COUNTS UNCHANGED / ACTUAL PLAYWRIGHT RUN AND LATEST CLOUDFLARE DEPLOYMENT UNVERIFIED.
Next required verification: refresh Cloudflare Pages deployment details and confirm Production/main points at a commit containing 172120584039fcdbdd4cda866d26870c9ac34a4c; then retrieve the workflow run and require all new browser rendering assertions to pass; finally test the employee's actual preparation account view without creating any stock or finance movement.