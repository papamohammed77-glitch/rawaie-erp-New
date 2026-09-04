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
- Confirmed: repository/project identity, current main continuity documents, canonical New-main source shape, shared runtime boundary, Supabase health/schema owner contract, broad Edge Function deployment surface, and PWA consumer model.
- Not confirmed: fresh browser E2E, exact deployed revision/cache identity, full PR/issue closure history, complete lifecycle classification of every `verify_jwt=false` function, and whole-system Gold/Diamond acceptance.
