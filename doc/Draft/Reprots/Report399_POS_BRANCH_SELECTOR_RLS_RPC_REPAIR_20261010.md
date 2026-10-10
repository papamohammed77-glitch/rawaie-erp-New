# Report399 — POS Branch Selector RLS / Authenticated RPC Repair
**Date:** 2026-10-10  
**Scope:** Only the POS branch selector data path. `main.html` and the operational `erp-frontend/companies/company-1/sales/pos.html` were not edited.

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** POS needs a branch list before it can calculate the selected branch's available stock and submit a sale.
- **Architecture Understanding:** POS frontend → authenticated Supabase Data API/RPC → PostgreSQL. No new Edge Function is needed.
- **Database Understanding:** `branches` has `company_id`, `branch_code`, `is_active`; the existing RLS policies restrict ordinary SELECT to `branches`/ `warehouse` permissions, with a separate scoped rule for telesales/orders. A cashier with only `pos` does not match those SELECT policies.
- **Historical Understanding:** Report398 identified the current POS source and earlier integration defects. It did not establish a POS browser E2E. This report does not treat the prior report as live evidence.
- **Production Understanding:** Live Production was queried in this execution. Current function and ACL were checked after applying the migration.
- **Current Understanding:** Current frontend source was fetched from `erp-frontend/main`; the operational POS source was not modified by this assistant.
- **Execution Confidence:** High for the confirmed RLS root cause and database RPC behavior under the authenticated cashier identity; frontend/browser E2E remains unverified until the owner applies the surgical patch and publishes.

### Confirmed facts

1. Current POS source blob SHA: `b93548ae660f063567736fef294683eb2046bb0e`; 85,917 characters returned by GitHub.
2. `self.syncDown` fetches `branches` using `supabase.from('branches').select('*')`.
3. Production `branches_select_company` requires `branches` or `warehouse` permission. The cashier account `cashier@rawaea.com` has `permissions=["pos"]`, `allowed_branch_ids="BR-01"`, no default branch.
4. Live Production has active branch `BR-01` (“الفرع الرئيسي”) for the cashier's company.
5. Live RPC `get_my_effective_profile()` is unrelated to the branch-list query; there was no existing authenticated POS branch-list RPC.
6. A new authenticated RPC `public.get_pos_branches()` was added and deployed through migration `20261010_pos_authorized_branch_selector_rpc`.
7. The RPC was invoked in a transaction as database role `authenticated` with the cashier's JWT subject claim. It returned exactly the authorized active branch `BR-01`; the transaction was rolled back. This is a database-level identity simulation, **not** a real browser/HTTP test.

### Unknowns / conflicts resolved

- **Root cause:** not missing branch records and not a missing Edge Function. It is the mismatch between POS-only permission and the existing direct-table SELECT RLS policy.
- **Security requirement:** do not broaden `branches` RLS to all POS users without enforcing each user's allowed branch scope. The RPC filters by authenticated user, active company, active branches, POS permission, and default/allowed branch IDs/codes; the owner wildcard is honored only when the existing owner predicate is satisfied.
- **Still unverified:** served Cloudflare artifact and POS browser E2E, because the protected frontend file has not been changed/published in this task.

## Production and database evidence

- Supabase project: `fiilmooggumokxanwiyx`.
- RPC signature: `public.get_pos_branches()`.
- Security: `SECURITY DEFINER`, empty `search_path`, all table/function references schema-qualified.
- ACL after deployment: `anon EXECUTE=false`, `authenticated EXECUTE=true`, `service_role EXECUTE=true`.
- Live authenticated-context result for `cashier@rawaea.com`: only `BR-01`, company `00000000-0000-0000-0000-000000000001`.
- Migration committed in Git: `supabase/migrations/20261010_pos_authorized_branch_selector_rpc.sql`.
- Migration commit: `7664699f927f42d12d48e1a43bec3c3a076039cc`.
- No Edge Function was created or deployed. No business rows, branch rows, stock rows, orders, or accounting rows were modified.

## Exact surgical frontend patch — owner applies

**File:** `papamohammed77-glitch/erp-frontend/companies/company-1/sales/pos.html`  
**Function:** `self.syncDown`  
**Search anchor:** `self.syncDown = function() {`  
**Action:** replace the entire existing function with the following complete replacement. Do not edit `main.html` or `core.js`.

```javascript
self.syncDown = function() {
    if (!db) return Promise.reject(new Error('قاعدة البيانات المحلية غير مهيأة'));

    return Promise.all([
        supabase.from('customers').select('*'),
        supabase.from('items').select('*'),
        supabase.from('stock_branches').select('*'),
        supabase.rpc('get_pos_branches')
    ]).then(function(results) {
        var names = ['customers', 'items', 'stock_branches', 'الفروع المصرح بها'];
        for (var i = 0; i < results.length; i++) {
            if (results[i].error) {
                throw new Error('فشل تحميل ' + names[i] + ': ' + results[i].error.message);
            }
            if (!Array.isArray(results[i].data)) {
                throw new Error('استجابة غير صالحة من ' + names[i]);
            }
        }

        var customers = results[0].data;
        var items = results[1].data;
        var stock = results[2].data;
        var branches = results[3].data;

        return db.transaction('rw', db.customers, db.items, db.stock, db.branches, function() {
            return db.customers.clear()
                .then(function() { return customers.length ? db.customers.bulkPut(customers) : undefined; })
                .then(function() { return db.items.clear(); })
                .then(function() { return items.length ? db.items.bulkPut(items) : undefined; })
                .then(function() { return db.stock.clear(); })
                .then(function() { return stock.length ? db.stock.bulkPut(stock) : undefined; })
                .then(function() { return db.branches.clear(); })
                .then(function() { return branches.length ? db.branches.bulkPut(branches) : undefined; });
        }).then(function() {
            customersCache = customers;
            productsCache = items;
            return { success: true, offline: false, branchCount: branches.length };
        });
    });
};
```

### Expected effect

- A POS-only cashier no longer depends on direct `branches` table SELECT permission.
- The RPC returns only active branches within the caller's company and branch scope.
- Existing Dexie atomic replacement/error handling is preserved: all remote results are validated before any local table is cleared.
- No new Edge Function, no broad RLS grant, no change to the stock movement contract.

## Verification matrix

| Test | Evidence / expected result | Status |
|---|---|---|
| Live schema / branch rows | `BR-01` exists, active, in the cashier's company | VERIFIED |
| Existing RLS cause | POS-only cashier does not satisfy the direct-table SELECT policy | VERIFIED |
| RPC function deployed | Function exists in Production | VERIFIED |
| RPC ACL | anon denied; authenticated/service_role allowed | VERIFIED |
| Authenticated identity simulation | cashier gets only `BR-01`; no other company branch returned | VERIFIED |
| Duplicate branch creation / stock effects | No rows changed by the RPC or migration | VERIFIED (no mutation occurred) |
| POS UI displays branch | Requires frontend patch + published artifact | PENDING |
| Real authenticated HTTP/browser E2E | Not run; no claim made | PENDING |
| Offline/cache fallback | Existing error-aware sync remains; must regression-test after patch | PENDING |
| Served artifact provenance | Must verify after owner publishes | PENDING |

## Required post-merge test

1. Apply only the replacement of `self.syncDown` above, publish the frontend, and hard-refresh/clear the relevant service-worker cache.
2. Sign in as a POS-only cashier whose `allowed_branch_ids` is `"BR-01"`; verify the selector shows “الفرع الرئيسي”.
3. Verify a user with no allowed branch receives an empty list, and a user cannot receive branches from another company.
4. Force `get_pos_branches` to return an error in a test environment; verify Dexie tables are not cleared and the POS displays the existing stale-cache warning.
5. Re-read the served artifact and record its digest/blob identity; then run the authenticated POS checkout regression from Report398. Do not claim complete POS integration based only on the dropdown test.

## SELF-AUDIT FINAL

- **What I Proved:** Production RLS explains the empty branch list for a POS-only role; the deployed RPC returns only the cashier's authorized branch under an authenticated database context; ACL is restricted from anon.
- **What I Did Not Prove:** Real browser login/HTTP invocation, published Cloudflare artifact parity, and full POS checkout E2E.
- **What I Fixed:** Added and deployed the authenticated, company- and branch-scoped `get_pos_branches()` RPC; committed its migration.
- **What I Initially Missed:** The branch query is made directly against a table whose SELECT policies intentionally do not grant access to a role holding only `pos`.
- **What Could Still Be Wrong:** The frontend patch has not been applied/published; real JWT/browser transport and service-worker cache behavior remain to be tested.
- **Final Confidence:** High for the database root cause and RPC-level fix; not enough evidence to close the POS UI issue.
- **Final Closure Status:** `DATABASE FIX DEPLOYED / FRONTEND SURGERY PENDING / POS E2E PENDING / NOT CLOSED`.
