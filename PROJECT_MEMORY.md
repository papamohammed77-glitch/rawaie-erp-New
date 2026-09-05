# SMART ERP — Daily Project Memory

This file is the verified cross-system memory snapshot for the daily review.

## Sources
- GitHub: `papamohammed77-glitch/rawaie-erp-New` (default branch `main`)
- Supabase: `SMART ERP` (`fiilmooggumokxanwiyx`)

## Protected rules
- Do not store passwords, access tokens, service-role/secret keys, session secrets, or other credentials.
- PostgreSQL/Supabase production evidence outranks reports and self-attestation.
- Git chronology/source content does not prove deployment or browser runtime.
- `Current/PWA/New-main` is the canonical current application target; PWA consumers remain interface/orchestration surfaces, not business authorities.
- Preserve owner authorization semantics; do not replace owner wildcard permissions with guessed role enumerations.
- Do not reopen a closed knowledge baseline without fresh contradictory evidence.

## Historical context
### 2026-09-03 — initial and forensic continuity baseline
- Supabase connectivity verified.
- Prior reviews recorded the PWA/Core/Edge-Function/PostgreSQL separation, Supabase Auth + bearer JWT pattern, and owner/license continuity constraints.
- Production owner was verified as active with wildcard permissions `["*"]`, linked owner profile, and active license; no production write was performed in the baseline review.
- Earlier continuity notes recorded security/performance advisories, stale recovery/test function surface, and lack of fresh full-browser Gold/Diamond proof.

## Verified continuity — 2026-09-04
### Git chronology
- `67fd5b327139be15964e4ecaa98218b0b7345ccf` refreshed this memory with verified cross-system evidence.
- `4b93e9178397028b6345c3a863d65e659a696331` synchronized `CURRENT_STATE` with Report50 and corrected earlier main-ancestry assumptions.
- `391de3fb38cb63f5c9ea6a3e62a91a5a3727a1a` added Report50 forensic PWA consumer inventory/state reconciliation.
- `8d64f747cdf06cd4197a379b7697b1855ecefeca` synchronized CURRENT_STATE with Report49/V12.
- Subsequent continuity commits created during this recovery are documentation/knowledge closure only: `f66d38575d6e3d8c76e8536e3c63beb23aea43a5` (knowledge pack) and `71c9c3f5682cbadbfbc759392f8e0daa07a95b85` (Report51).
- New-main-targeting commits `2118dff...`, `94ffee...`, and `6d729...` exist in Git history on independent parent chains and are not, by message alone, evidence of current-main state.

### Knowledge baseline completion — Report51
- Direct current-main fetch proves `Current/PWA/New-main` is a full HTML/CSS/JS artifact, not a small descriptive placeholder.
- Inline current CSS directly contains the login dimensions (`rw-login-title=58px`, `rw-login-logo=88x88`) and current login identity surfaces.
- `Current/PWA/core.js` directly proves the shared runtime boundary (`RW_Auth`, `RW_DB`, `RW_API`, `RW_UI`), Supabase Auth metadata usage, owner/wildcard frontend permission semantics, Dexie/local sync, and bearer-token Edge Function calls.
- Direct historical `Current/PWA/main/main1.md` proves the historical parent/main HTML contract and Original-era visual values such as 64px title and 120x120 login logo; the difference is proven but regression is not.
- Current PWA consumer inventory is documented in `doc/Draft/Reprots/MASTER_RAWAEA_SYSTEM_PWA_KNOWLEDGE_PACK_2026-09-04.md`; consumers are not business authorities.
- Production Supabase is `ACTIVE_HEALTHY`, `eu-west-1`, PostgreSQL 17.6. Business Edge Functions observed directly include sales/orders, runsheet/picking/loading/delivery/returns, stock vouchers, purchasing, accounting/reporting, and audit/supporting workflows.
- Example deployed production versions observed directly: `save-sales-invoice v15`, `create-runsheet v26`, `start-picking v34`, `complete-picking v17`, `start-loading v5`, `complete-loading v11`, `start-delivery v7`, `complete-delivery v4`, `complete-return v25`, `unload-runsheet v6`, `send-stock-voucher v20`, `receive-stock-voucher v22`, `receive-purchase v12`, `save-journal-entry v8`.
- Owner production DB was freshly rechecked: `permissions=["*"]`, status `Active`, role `مدير النظام`, `auth_id` linked to `owner_profile`, `license_status=active`.
- License source contract remains confirmed, but browser tab visibility, deployed revision, and service-worker/cache state are not fresh-runtime verified.
- A fresh Edge Function log query returned no rows at the time of this review. Historical/current memory of repeated `owner-recovery-20260818` HTTP 410 calls remains an evidence lead, not a fresh log result from this exact query.

## Verified continuity — 2026-09-05
### GitHub current snapshot
- Repository identity and permissions were rechecked directly: `papamohammed77-glitch/rawaie-erp-New`, default branch `main`, repository remains public and writable by the connected account.
- Latest visible commit is `c10631479e1e0a9168841636d976dcb51370f712` (`docs(memory): record 2026-09-05 verified GitHub and Supabase snapshot`, 2026-09-05T03:10:26Z). The immediately prior code-bearing commit is `8e5fe0d7427f8e16a8094da9e86a26e486c9cea3` (`Refactor functions and enhance voucher query logic`, 2026-09-05T01:42:35Z), describing escaping/JSON-stringify refactors, voucher date filters, and duplicate-barcode handling.
- `Current/PWA/New-main` was fetched directly. It is a full RTL Arabic HTML/CSS/JS artifact with the login page, password visibility control, sidebar shell, dashboard/layout styles, manifest link `./manifest.json`, and service-worker coordinator `./register-sw.js`. Current blob SHA returned by GitHub: `22f4ee1a666141be62127159337beffb05e8b146`.
- Latest Actions run observed for the current head is run `33941121039` for `CTO New-main Single Writer Closure 2026-09-03`; it completed with conclusion `skipped`. This is not a CI PASS and does not constitute fresh browser proof.
- Open PRs currently visible include #127, #126, #125, #123, #119, #118, #117, #115, and #113. Their descriptions are closure/execution triggers or target-only surgery plans; none is merged based on the current direct search result. Closed PRs in the same surface include #128, #124, #122, #121, #120, #116, #114, #112, #111, #110, and #109, with mixed merged/unmerged history.
- The GitHub snapshot contains many documentation/continuity commits after the prior memory update; commit messages alone were not treated as runtime or deployment proof.

### Supabase current snapshot
- Project `fiilmooggumokxanwiyx` remains `ACTIVE_HEALTHY` in `eu-west-1`, PostgreSQL `17.6.1.121`.
- The deployed Edge Function catalog remains broad and active. Business functions are predominantly `verify_jwt=true`; a distinct set of canary, fixture, runtime-E2E, gate, and recovery functions remains active with `verify_jwt=false`, including `start-picking-production-harness`, `cp-prod-auth-canary-20260814`, `cp-prod-fixture-canary-20260814`, `start-picking-e2e-fixture-20260815`, `start-picking-real-identity-e2e-20260815`, `send-stock-voucher-runtime-e2e-20260818`, `prompt2-complete-picking-http-e2e-20260818`, `complete-picking-runtime-e2e-20260818`, `owner-recovery-20260818`, `owner-recover-gate-20260818-7f2d9c41`, `auth-login-verification-20260818`, `complete-picking-picker-http-gate-20260818`, `receive-purchase-runtime-e2e-20260819`, and `save-sales-production-canary-20260819`.
- Fresh Edge Function logs for the last 24 hours returned an empty result. Therefore, no current incident is proven by this query; historical 410 evidence for `owner-recovery-20260818` remains unresolved historical evidence only.
- Fresh security advisors still report: anonymous/authenticated EXECUTE exposure for `public.create_item_with_opening_stock(...)` and `public.sync_company_main_branch_projection()`, both `SECURITY DEFINER`, plus leaked-password protection disabled.
- Fresh performance advisors still report unindexed foreign keys across multiple business tables, RLS init-plan warnings on multiple policies/tables, multiple permissive policies (notably `customer_assignments`, `receiving`, `receiving_details`), and unused-index notices. These are advisory findings, not proof of a production outage.

## Production risk baseline
- Separate historical/test/recovery/E2E Edge Functions remain active with `verify_jwt=false`; this is a confirmed attack-surface/lifecycle review item.
- Previously observed security advisories include anonymous/authenticated EXECUTE exposure on `public.create_item_with_opening_stock(...)` and `public.sync_company_main_branch_projection()`, plus disabled leaked-password protection.
- Previously observed performance advisories include unindexed foreign keys, RLS init-plan warnings, duplicate/multiple permissive policies, and unused indexes.
- Empty combined Git status is not equivalent to CI PASS.

## Canonical system model
```text
RAWAEA ERP BUSINESS SYSTEM
    ↓
PWA consumers / shared runtime
    ↓
Edge Functions / RPC contracts
    ↓
PostgreSQL / Supabase SSOT
```

PWA files are consumers/interfaces. Business authority remains in backend/database contracts.

Inventory continuity remains protected:
```text
post_stock_movement = physical stock movement authority
reserve_stock = reservation authority
allocated_qty != physical qty
PWA != stock authority
```

Owner continuity remains protected:
```text
OWNER
=
AUTH OWNER IDENTITY
+
isOwner=true
+
permissions=["*"]
+
VALID owner_profile
+
ACTIVE LICENSE
```

## Runtime / deployment confidence boundary
```text
STATIC SOURCE = CONFIRMED
SUPABASE OWNER/DB STATE = CONFIRMED
FRESH BROWSER E2E = UNKNOWN
DEPLOYED REVISION = UNKNOWN
SERVICE WORKER/CACHE = UNKNOWN
FRESH GOLD = NOT PROVEN
FRESH DIAMOND = NOT PROVEN
WHOLE-PROJECT 100% = NOT PROVEN
```

## Canonical successor files
- `doc/Draft/Reprots/MASTER_RAWAEA_SYSTEM_PWA_KNOWLEDGE_PACK_2026-09-04.md`
- `doc/Draft/Reprots/تقرير51.md`
- `CURRENT_STATE.md`

## Confidence boundary
- Confirmed: repository/project identity, current main continuity documents, canonical New-main source shape, shared runtime boundary, Supabase health/schema owner contract, broad Edge Function deployment surface, PWA consumer model, fresh 2026-09-05 security/performance advisor output, and fresh empty 24-hour Edge Function log result.
- Not confirmed: fresh browser E2E, exact deployed revision/cache identity, full PR/issue closure history, complete lifecycle classification of every `verify_jwt=false` function, and whole-system Gold/Diamond acceptance.
