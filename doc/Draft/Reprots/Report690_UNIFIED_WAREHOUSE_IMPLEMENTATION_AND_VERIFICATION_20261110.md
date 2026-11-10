# Report690 — Unified Warehouse Hub Implementation & Verification
**Date:** 2026-11-10 (Africa/Cairo)  
**Workstream:** Unified Warehouse hub, role integration, backend authorization parity, CI/E2E  
**Status:** \`FIX APPLIED — E2E PARTIALLY VERIFIED\`

## 1. Executive result
The prior forensic finding was real: \`companies/company-1/warehouse/warehouse.html\` was a byte-identical Returns application copy, not a unified warehouse hub. This has now been replaced with a dedicated, responsive warehouse hub. Parent navigation, Supervisor role assignment UI, existing warehouse app role gates, Supabase snapshot access, and the relevant server-side guards have been integrated.

No business stock, supplier, cash, treasury, or journal transaction was executed. No QA fixture or synthetic business record was created. No existing role was assigned \`مخزن شامل\`; the active-user count for that role remains zero.

## 2. Operational source of truth
- Repository: \`papamohammed77-glitch/erp-frontend\`, branch \`main\`.
- Latest HEAD at verification: \`2221eea98a8edcdcb9c582ddde07e4f45edeef2e\`.
- Cloudflare Pages project \`rawaea-erp\`: deployment check succeeded for HEAD \`2221eea\`.
- Current per-commit preview: \`https://a4deebdc.rawaea-erp.pages.dev\`.
- Main published hub path: \`/companies/company-1/warehouse/warehouse.html\`.
- Governance baseline: Report689 and \`CURRENT_STATE.md\` LVE-2026-11-10-689.

### Relevant operational commits
| Commit | Change |
|---|---|
| \`be172a2a24f95e898c444b0c587b9f0d83c56616\` | Branch-scoped, read-only warehouse hub snapshot migration file |
| \`c7016097770659868ec9a3bc731cdb094972dba0\` | Dedicated hub, Parent entry point, app role gates, Supervisor role option |
| \`f843b6635e8ca20b37144ec0dd1da64a2019294b\` | Source-managed Edge Function role/branch guards |
| \`93b340e1ddaa55c7ef01116008d83e26fcf02968\` | Corrected and committed receiving Edge guard syntax |
| \`7aba3c020c0989677e7409f13c6af71b2eb8e7ef\` | Server-side unified-role guard migration file |
| \`d86d2b887c87cc6cc8d37e85768c21f042e842ad\` | Playwright runner stabilization and dedicated hub browser E2E |
| \`2221eea98a8edcdcb9c582ddde07e4f45edeef2e\` | Isolated voucher browser boot test from external CDN dependencies |

## 3. Frontend implementation
### Dedicated hub
\`companies/company-1/warehouse/warehouse.html\` is now a purpose-built interface with:
- **Today:** read-only operational KPIs and authorized branch scope.
- **Operations:** receiver, picker, loader, returns, unloader, counter.
- **Vouchers:** transfer, branch transfer receipt, direct-sale vehicle issue, direct-sale vehicle return, supplier return.
- **My Account:** authenticated user, active warehouse role, company, main-warehouse access, authorized branches.

The hub opens the original applications. It does not duplicate inventory, receipt, picking, loading, return, unloading, count, or voucher business logic. Existing app routes and posting engines remain the sources of truth.

### Parent and Supervisor
- Added a permission-gated \`المخزن الشامل\` entry under the existing warehouse operations menu in \`companies/company-1/main.html\`.
- The entry opens \`warehouse/warehouse.html\` in a new tab.
- Added \`مخزن شامل\` to Supervisor's warehouse-role options and icon mapping.
- Existing legacy warehouse menu entries were retained.

### Existing application role gates
The unified role was added to the frontend role gates in:
- \`receiver.html\`
- \`picker.html\`
- \`loader.html\`
- \`returns.html\`
- \`unloader.html\`
- \`counter.html\`
- \`vouchers.html\`

Only role authorization was extended; the operational workflows and posting logic were not rewritten.

## 4. Supabase Production — SMART ERP
Project: \`fiilmooggumokxanwiyx\`.

### Applied migrations
| Version | Migration | Result |
|---|---|---|
| \`20261109233602\` | \`unified_warehouse_role_and_scoped_inventory_counts\` | Already applied before this work; not reapplied |
| \`20261110003307\` | \`unified_warehouse_hub_snapshot\` | Applied |
| \`20261110004233\` | \`unified_warehouse_role_guards\` | Applied |

### Read-only snapshot RPC
Created \`public.get_warehouse_hub_snapshot()\`:
- \`SECURITY DEFINER\`, pinned empty \`search_path\`, explicit schema qualification.
- \`EXECUTE\` granted to \`authenticated\`; not granted to \`anon\` or \`PUBLIC\`.
- Validates the authenticated application user, active warehouse role, warehouse permission, company, and allowed branch scope.
- Returns only branch-scoped KPI aggregates and authorized branch labels.
- Does not write stock, reservations, invoices, supplier balances, treasury, or journals.

Verified under an authenticated existing warehouse user: the RPC returned only the user's authorized branch and expected KPI fields. A user without warehouse authorization was rejected. No unauthorized branch rows were returned.

### Server-side voucher and receiving guard parity
The migration uses \`CREATE OR REPLACE\` on existing RPC signatures; no new tables, triggers, or posting engines were introduced.

- \`receive_purchase_atomic\` and \`receive_quick_market_purchase_atomic\`: accept \`مخزن شامل\` only with warehouse permission. The legacy \`استلام\` path retains its existing warehouse/receiving permission behavior.
- 12-argument \`create_manual_stock_voucher_atomic\`: unified role is accepted for the default-source transfer rule; the unified role does **not** inherit the legacy \`أذونات\` branch-scope bypass.
- \`update_manual_stock_voucher_atomic\`: unified role can manage eligible drafts within existing branch checks.
- \`send_stock_voucher_atomic\` and \`complete_manual_stock_voucher_atomic\`: unified role can act on its own SupplierReturn only when \`created_by\` matches the authenticated application user's email. Existing \`أذونات\` and privileged manager behavior is preserved.
- \`post_manual_stock_voucher_atomic\`: unified role is accepted for DirectReturn receipt while the existing branch-scope checks remain.
- Existing SupplierReturn contract checks, transfer receiver binding, document status guards, and posting semantics were preserved.

No stock movement, voucher, supplier ledger, journal, cash, or treasury row was created or modified by these migrations.

## 5. Edge Function authorization parity
Existing Edge Functions were updated in place; no new Edge Function was created. Shared \`warehouse-auth.ts\` is imported by the functions that need warehouse role and main-branch validation.

| Function | Deployed version | Guard |
|---|---:|---|
| \`start-picking\` | 36 | unified role + warehouse permission + main-branch access |
| \`complete-picking\` | 19 | same; existing picker/RPC ownership retained |
| \`start-loading\` | 7 | loading role + warehouse permission + main-branch access |
| \`complete-loading\` | 12 | same, plus assigned \`loader_id\` must match the actor |
| \`unload-runsheet\` | 7 | unloading role + warehouse permission + main-branch access |
| \`start-return\` | 6 | returns role + warehouse permission + main-branch access |
| \`complete-return\` | 28 | same for runsheet returns; POS/order return path remains separate |
| \`receive-purchase\` | 18 | unified receiving role requires warehouse permission; legacy receiver path retained |

All eight deployments completed successfully. Existing JWT verification remains enabled. The loader assignment check is performed before calling the existing completion RPC; no RPC posting calculation was changed.

## 6. Verification and test results
### Source and static checks
- Inline JavaScript syntax: PASS for the new hub, Parent, and all seven modified warehouse apps.
- Parent menu action and permission entry: PASS.
- All six operation routes and voucher route references: PASS.
- Supervisor unified-role option and icon: PASS.
- No duplicate hub business engine or alternate stock-writing path introduced.

### Automated browser E2E
- **Unified Warehouse Hub Browser E2E:** PASS on commit \`d86d2b8\`. Uses synthetic mocked auth/RPC data; verifies login transition, dashboard metrics, all six operation links, five voucher entries, account branch display, unified-role access, and loader-only restriction for a \`تحميل\` role.
- **Warehouse Vouchers Browser E2E:** PASS on commit \`2221eea\`. HTTP 200; \`core.js\` 200; \`sw.js\` 200; login inputs and button present; no wrong warehouse-local service-worker path; no console or page errors.
- **Mother browser E2E:** PASS on commit \`2221eea\`.
- **Mother inventory forensic E2E:** PASS on commit \`2221eea\`.
- Helper/source forensic and canonical Mother checks: PASS.

The earlier browser workflow failures were environmental: Playwright 1.55.0 was being installed on Ubuntu 26.04, which it did not support. The affected workflows were pinned to \`ubuntu-24.04\`; the subsequent runs passed. The voucher smoke test was also isolated from external CDN availability.

### Database and security verification
- Read-only snapshot call under an authenticated warehouse user: PASS.
- Unauthorized snapshot access: DENIED as expected.
- \`anon\` execute privilege: false.
- \`authenticated\` execute privilege: true.
- Snapshot function is SECURITY DEFINER with pinned search path.
- Security advisor: the new snapshot appears only in the authenticated SECURITY DEFINER advisory category; it does not appear in the anon-executable category. This is intentional and protected by internal authorization checks.
- Performance advisor: no new finding attributable to the hub snapshot; existing unrelated database advisor findings were left untouched.

### No-business-write baseline
After implementation, observed counts remained:
- \`inventory_log\`: 78
- \`stock_branches\`: 58
- \`journal_entries\`: 21
- \`supplier_ledger\`: 3
- \`stock_vouchers\`: 0
- \`purchase_invoices\`: 5

No QA fixture was created. No stock, supplier, cash, treasury, or journal posting was executed.

## 7. Deployment and release status
- Cloudflare Pages \`rawaea-erp\` for current main HEAD \`2221eea\`: **DEPLOY SUCCESS**.
- Preview URL: \`https://a4deebdc.rawaea-erp.pages.dev\`.
- Hub path: \`/companies/company-1/warehouse/warehouse.html\`.
- Other separate Pages projects still report build failures (\`warehouse-supervisor\`, \`rawaea-store\`, \`erp-frontend\`). The same failures were present on earlier pre-task commits; the main \`rawaea-erp\` project is successful. These unrelated project build configurations were not changed.

## 8. Explicitly unverified / next controlled steps
- No active user is currently assigned \`مخزن شامل\`; no assignment was made automatically.
- The hub E2E uses mocked authentication and snapshot data. The real snapshot RPC was separately tested with an authenticated warehouse user, but a real authenticated browser session for the new role was not available in this run.
- No physical receipt, picking completion, loading, unloading, return, inventory count posting, voucher posting, supplier return, or financial settlement was executed. Those writer paths must be exercised only with identified synthetic QA fixtures and a proven cleanup/rollback path under the standing Production QA protocol.
- After the owner assigns the role to an authorized warehouse employee through Supervisor, perform authenticated browser navigation and read-only E2E across the six original apps. Then perform controlled reversible QA writer tests, one workflow at a time, with before/after stock, supplier, treasury, journal, and audit baselines.

**Closure:** \`FIX APPLIED — E2E PARTIALLY VERIFIED\`. The hub, navigation, role surfaces, read-only snapshot, backend authorization parity, Edge deployments, CI E2E, and main Cloudflare deployment are implemented and verified. Do not label the physical stock/finance workflows fully E2E-closed until their controlled writer tests are executed and cleaned.
