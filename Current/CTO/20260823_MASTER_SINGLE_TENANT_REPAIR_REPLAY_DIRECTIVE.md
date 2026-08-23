# RAWAEA ERP — MASTER SINGLE-TENANT REPAIR / REPLAY DIRECTIVE
## Effective checkpoint: 2026-08-23

### Production / Repository
- Production: `SMART ERP` / `fiilmooggumokxanwiyx`
- Repository: `papamohammed77-glitch/rawaie-erp-New`
- Canonical live company: `00000000-0000-0000-0000-000000000001` / `الروائع` / `MAIN`

## 1. Authority hierarchy

1. Live Production PostgreSQL and deployed Edge definitions.
2. Current Git source.
3. Current CTO/evidence artifacts.
4. Historical/original source and execution reports.
5. General accounting/ERP practice only as benchmark, never as RAWAEA contract.

No historical PASS is a current PASS until re-proven.

## 2. Single-company rule

Production is currently a single-company topology. All new repairs, master data, financial data and operational changes must belong to the live company above.

The retired companies are historical evidence only. Do not recreate a second live tenant and do not silently resurrect deleted tenant rows.

## 3. What “replay previous repairs” means

Do NOT blindly replay historical SQL or old data.

For every historical repair:

`HISTORICAL CONTRACT`
→ `CURRENT PRODUCTION VERIFICATION`
→ `CURRENT GIT VERIFICATION`
→ `TENANT REBASELINE`
→ `SURGICAL REAPPLICATION ONLY IF STILL REQUIRED`
→ `STAGING / TRANSACTIONAL TEST`
→ `PRODUCTION DEPLOY`
→ `RUNTIME VERIFY`
→ `CLOSE`

The goal is to preserve the valid architectural/business effect of prior repairs under the current company, while rejecting obsolete, superseded, duplicate, destructive or tenant-incompatible changes.

## 4. Financial master-data fact pattern

Current Production verification on 2026-08-23:
- companies = 1
- users = 24
- branches = 2
- items = 17
- chart_of_accounts = 0
- treasury = 1
- cash_box = 0
- journal_entries = 2
- journal_lines = 0
- customer_ledger = 0
- supplier_ledger = 0
- driver_ledger = 0

Treasury is already restored under the live company:
- id = `0a9d9357-b5f3-4dfa-886f-7c73de4f274e`
- account_code = `CASH-01`
- account_name = `الخزينة الرئيسية`
- type = `Cash`
- opening_balance = `10000`
- current_balance = `10000`
- active = true
- original UUID preserved

Do NOT create a second CASH-01.

## 5. The 87-account gate

The historical retired tenant is proven to have had exactly 87 `chart_of_accounts` rows.

However:
- row-level `chart_of_accounts` audit snapshots are not available;
- current Production contains zero COA rows;
- `rawaie-erp-review/PWA/main.html` contains only a small bootstrap seed and is NOT evidence for the missing 87;
- no exact 87-row authoritative source has yet been proven.

Therefore:

**Never synthesize the 87.**

No account code, name, parent, UUID, type, normal balance or active state may be invented from generic accounting practice.

The only valid recovery sources are an exact historical Git blob/tree/commit, preserved migration/seed, authoritative Production snapshot/backup, or another directly verifiable row-level source.

## 6. Financial identity rule

`journal_lines.account_id` is a UUID foreign key to `chart_of_accounts.id`.

Account code is not the journal-line identity. Treasury code is not automatically a COA UUID.

Any Treasury↔COA mapping must be explicitly proven before a financial writer uses it.

## 7. Inventory rule

Inventory physical movement remains governed by:

`Business Event → post_stock_movement → stock_branches + inventory_log`

`reserve_stock` is reservation only.

Do not reopen Inventory as a parallel redesign unless new Production evidence reopens a regression gate.

## 8. Security and execution rules

- No direct financial table writes from authenticated/anonymous consumers when the target architecture requires Edge/Core capability boundaries.
- No hard-coded company UUIDs in financial consumers.
- No global `LIMIT 1` lookup where tenant identity is required.
- No direct journal/ledger mutation outside the owning core once that core contract is proven.
- Every experimental Production action must be reversible and audit-preserving.
- No “Production verified” claim from Staging alone.

## 9. Closure labels

Use only:
`CONFIRMED`, `HISTORICAL`, `TARGET`, `UNKNOWN`, `CONFLICT`, `OPEN`, `BLOCKED`, `PRODUCTION DEPLOYED`, `RUNTIME VERIFIED`, `CLOSED`.

Do not convert `UNKNOWN` into an assumption.

## 10. Required global rebase

Before every closure unit, capture:
- current company topology;
- current user/company mapping;
- app_settings/main branch ownership;
- relevant table counts;
- relevant function definitions and versions;
- Git file SHA / deployed version lineage;
- consumer path;
- current data ownership;
- unresolved conflicts.

This directive supersedes stale historical company snapshots.
