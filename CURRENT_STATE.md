# RAWAEA ERP — CURRENT STATE

> هذا الملف Living Execution State وليس مصدرًا أعمى للحالة الحالية. يجب دائمًا مطابقة محتواه مع CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.

## Current Session

- **Date:** 2026-09-16
- **Current repository / Mother source:** `papamohammed77-glitch/erp-frontend`
- **Source of Truth:** `companies/company-1/main.html`
- **Current Mother HEAD:** `f1860e81f58def17090302a90b23289de37e93f1`
- **HEAD message:** `forensic: persist current Mother inventory extract`
- **HEAD parent:** `17f0b4d504d62e312f9ba59cee6aee2cf54eb71a`
- **Parent message:** `Add new render functions to RW_Finance`
- **Current Mother blob SHA:** `f45a5a943629ea2b5891a4ef0c99049c493ab474`
- **Current forensic extract:** 24,150 lines; SHA256 `7b7d3968f7cdf7be69f5dd1c7d20ad61a698548b8aba341853a3f6593a491754`

## Source-of-Truth Rule

`companies/company-1/main.html` in `erp-frontend` is the authoritative Mother source for current forensic/E2E work.

`Current/PWA/main2` and `Original/PWA/main` are historical/advisory references only.

`Current/PWA/main` and `Current/PWA/New-main` remain forbidden sources for reconstruction.

The `forensic_main_assembly.yml` currently defines:

```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
assembly_status:
  mode: published_main_is_authoritative
  fragment_mode: historical_reference_only
```

## Current Mother Finance Finding

### Console errors investigated

```text
main:14542 Uncaught ReferenceError: _renderPeriods is not defined
main:14541 Uncaught ReferenceError: _renderAssets is not defined
main:14540 Uncaught ReferenceError: _renderTax is not defined
main:14539 Uncaught ReferenceError: _renderBankReconcile is not defined
main:14538 Uncaught ReferenceError: _renderCheques is not defined
main:14537 Uncaught ReferenceError: _renderExpenses is not defined
main:14536 Uncaught ReferenceError: _renderRecurringJournals is not defined
main:14535 Uncaught ReferenceError: _renderJournalList is not defined
```

### Proven root cause

The current `RW_Finance.renderSubTab` dispatcher still calls local names:

```text
_renderJournalList()
_renderRecurringJournals()
_renderExpenses()
_renderCheques()
_renderBankReconcile()
_renderTax()
_renderAssets()
_renderPeriods()
```

The current source also contains the corresponding public namespace bindings:

```text
RW_Finance._renderJournalList
RW_Finance._renderRecurringJournals
RW_Finance._renderExpenses
RW_Finance._renderCheques
RW_Finance._renderBankReconcile
RW_Finance._renderTax
RW_Finance._renderAssets
RW_Finance._renderPeriods
```

The direct parent commit `17f0b4d...` added these bindings to `RW_Finance`.

Therefore the current defect is a **dispatcher-to-namespace mismatch**, not a missing Finance renderer and not a missing Production RPC.

## Required Mother Surgical Change — OWNER ONLY

The assistant must NOT modify `erp-frontend/companies/company-1/main.html`.

Owner must replace the exact current 8-line dispatcher element in `RW_Finance.renderSubTab`.

### Delete exactly

```text
else if (tab === 'journal-list') _renderJournalList();
else if (tab === 'recurring-journals') _renderRecurringJournals();
else if (tab === 'expenses') _renderExpenses();
else if (tab === 'cheques') _renderCheques();
else if (tab === 'bank-reconcile') _renderBankReconcile();
else if (tab === 'tax') _renderTax();
else if (tab === 'assets') _renderAssets();
else if (tab === 'periods') _renderPeriods();
```

The element ends exactly at:

```text
else if (tab === 'periods') _renderPeriods();
```

### Replace with exactly

```text
else if (tab === 'journal-list') RW_Finance._renderJournalList();
else if (tab === 'recurring-journals') RW_Finance._renderRecurringJournals();
else if (tab === 'expenses') RW_Finance._renderExpenses();
else if (tab === 'cheques') RW_Finance._renderCheques();
else if (tab === 'bank-reconcile') RW_Finance._renderBankReconcile();
else if (tab === 'tax') RW_Finance._renderTax();
else if (tab === 'assets') RW_Finance._renderAssets();
else if (tab === 'periods') RW_Finance._renderPeriods();
```

### Important

Do NOT re-add Gold action aliases. Current source already contains them, including:

```text
RW_Finance._goldAddAsset
RW_Finance._goldDepreciate
RW_Finance._goldDispose
RW_Finance._goldTaxCode
RW_Finance._goldTaxSettle
RW_Finance._goldOpenPeriod
RW_Finance._goldChequeTransition
```

Do NOT modify `Current/PWA/main2` for this fix.

## Current Production Findings

Supabase Production project:

`fiilmooggumokxanwiyx`

### Finance RPC existence

The Production database contains the Finance RPCs required by the current renderer, including:

- `finance_journal_list`
- `finance_list_recurring`
- `finance_list_expenses`
- `finance_list_cheques`
- `finance_list_assets`
- `finance_tax_report`
- `finance_open_period`
- `finance_close_period`
- `finance_reopen_period`
- `finance_open_bank_statement`
- `finance_close_bank_statement`
- `finance_save_expense`
- `finance_save_cheque`
- `finance_save_recurring`
- `finance_save_tax_code`
- `finance_tax_settle`
- `finance_transition_cheque`
- `save_fixed_asset`
- `post_fixed_asset_depreciation`
- `finance_dispose_asset`
- `get_budget_vs_actual`

These are `SECURITY DEFINER` functions.

### Runtime database probes

Direct PostgreSQL probes for the current renderer dependencies returned:

```text
finance_journal_list    -> 2 rows
finance_list_recurring  -> 0 rows
finance_list_expenses   -> 0 rows
finance_list_cheques    -> 0 rows
finance_list_assets     -> 1 row
finance_tax_report      -> 0 rows
```

Therefore the current JavaScript `ReferenceError` is not caused by missing DB functions.

### Production security hardening performed in this session

The Finance RPC anonymous execute surface was wider than necessary. `PUBLIC/anon` access was present on multiple `finance_*` functions.

Production actions executed:

```text
20260916115243 finance_close_public_read_rpc_surface
20260916115339 finance_lock_anonymous_rpc_surface
20260916115431 finance_security_surface_close
```

The second and third migrations are idempotent ACL closure passes; they do not alter Finance business logic.

Final verification:

```text
Finance EXECUTE for PUBLIC/anon = 0 rows
```

Direct privilege checks:

```text
anon_journal  = false
anon_expenses = false
anon_cheques  = false
auth_journal  = true
auth_budget   = true
```

The earlier `get_budget_vs_actual` authenticated execute closure remains verified.

## Git Reconciliation Performed

The three Production security migrations were also recorded in the canonical `rawaie-erp-New/supabase/migrations` history so that the executed Production state is reproducible from Git:

- `20260916115243_finance_close_public_read_rpc_surface.sql`
- `20260916115339_finance_lock_anonymous_rpc_surface.sql`
- `20260916115431_finance_security_surface_close.sql`

No Finance business tables were created because the current schema already contains the required capabilities.

No Finance Edge Function was created because the current Mother renderer calls the existing PostgreSQL RPCs directly.

## What Is Closed

- Finance anonymous/public RPC execute surface: **CLOSED / PRODUCTION VERIFIED**.
- `get_budget_vs_actual` execute privilege: **CLOSED / PRODUCTION VERIFIED**.
- Root cause of the eight current ReferenceErrors: **PROVEN**.
- Gold action alias existence: **PROVEN PRESENT IN CURRENT SOURCE**.
- Finance renderer DB dependencies: **PROVEN PRESENT AND CALLABLE IN PRODUCTION**.
- `forensic_main_assembly.yml` Source-of-Truth routing: **VERIFIED**.

## What Is Not Yet Closed

- Owner application of the 8-line dispatcher replacement.
- Browser reload after owner change.
- Actual click E2E of the eight affected Finance tabs.
- First-new-console-error capture after that reload.
- Final Finance modal UX/business completion audit.

Do not re-fix the eight old errors unless a new regression proves they returned.

## Current Session Report

`doc/Draft/Reprots/Report218_MOTHER_FINANCE_FORENSIC_E2E_20260916.md`

## Required Next Session Start

1. Start from CURRENT GIT: obtain the real latest `erp-frontend` HEAD.
2. Open its direct parent and inspect the diff affecting the area under test.
3. Open current `companies/company-1/main.html`; it is the only current Mother Source of Truth.
4. Do not treat Report218 or this file as current truth without re-verification.
5. Trace any Console error in order:

```text
Browser consumer
→ dispatcher / onclick
→ local function or public namespace
→ return object / export
→ RPC
→ Production function
→ DB schema / privileges
```

6. For `ReferenceError`, inspect declaration + scope + return object + namespace binding before inventing any function.
7. For `is not a function`, inspect declaration + return object + public alias before any DB change.
8. For `403`, inspect `routine_privileges` and `has_function_privilege` before business logic.
9. Apply one surgical closure at a time.
10. Production changes are executed directly after proof; Mother source changes are owner-applied.
11. After owner applies a source fix, perform browser reload and real clicks before declaring E2E closed.
12. Never recreate a capability that CURRENT SOURCE/PRODUCTION already proves exists.
13. Never create a table or Edge Function unless current evidence proves the capability is absent.
14. Never use a historical fragment as the deployment Source of Truth.
15. Never repeat a closed fix without evidence of regression.

## Final Self-Audit

### Proven

- Current HEAD = `f1860e81...`.
- Current HEAD parent = `17f0b4d5...`.
- Parent added Finance renderer namespace bindings.
- Current dispatcher still used local renderer names and caused the ReferenceErrors.
- Current source already contains Gold aliases.
- Current Production Finance RPC dependencies exist and respond.
- Production Finance anonymous execute surface is closed.

### Not Proven

- Browser E2E after owner applies the dispatcher fix.
- Final visual/interaction quality of all Finance modals.

### Not Changed by Assistant

- `erp-frontend/companies/company-1/main.html`.
- Historical fragment files.
- Finance business logic functions/tables.
- Operational warehouse / fulfillment application flows.

### Final Status

```text
CURRENT FINANCE ROOT CAUSE      = PROVEN
PRODUCTION SECURITY             = CLOSED / VERIFIED
MOTHER SURGICAL PATCH           = READY / OWNER ACTION
BROWSER FINANCE E2E             = PENDING OWNER MERGE
FULL FINANCE E2E                 = NOT YET CLOSED
```
