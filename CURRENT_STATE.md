# RAWAEA ERP — CURRENT STATE

> هذا الملف Living Execution State وليس مصدرًا أعمى للحالة الحالية. يجب دائمًا مطابقة محتواه مع CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.

## Current Session

- **Date:** 2026-09-16
- **Current repository / Mother source:** `papamohammed77-glitch/erp-frontend`
- **Source of Truth:** `companies/company-1/main.html`
- **Current Mother HEAD at investigation start:** `3fe3c76674c7cbed8eb10201fee83ca6af2f1b07`
- **HEAD parent:** `3b5fdce634e44b3a2faa6bbf2dd40db5e88a676a`
- **Current Mother blob SHA observed:** `744339a5cbe54a59e57bfc15bd3e3d4cce485d28`
- **Forensic extract:** 24,150 lines; SHA256 `7f5bc99954c62d3359180dedb577e52ff498c020eb29de04adc0cf4646a89c84`

## Source-of-Truth Rule

`companies/company-1/main.html` in `erp-frontend` is the authoritative Mother source for current forensic/E2E work.

`Current/PWA/main2` and `Original/PWA/main` are historical/advisory references only.

`Current/PWA/main` and `Current/PWA/New-main` remain forbidden sources for reconstruction.

`forensic_main_assembly.yml` remains defined as:

```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
assembly_status:
  mode: published_main_is_authoritative
  fragment_mode: historical_reference_only
```

## Mother Finance Root Cause Already Proven

The prior browser errors were caused by a dispatcher-to-namespace mismatch in `RW_Finance.renderSubTab`:

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

The current source contains the namespace bindings:

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

### Owner surgical patch

Replace the old dispatcher block:

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

with:

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

## Current Production Finance Foundation

Supabase project: `fiilmooggumokxanwiyx`.

Existing finance entities re-verified in Production:

- finance_expense_categories
- finance_expenses
- finance_expense_lines
- finance_cheques
- finance_cheque_events
- finance_bank_statements
- finance_bank_statement_lines
- finance_tax_codes
- finance_tax_transactions
- finance_tax_settlements
- fixed_assets
- fixed_asset_events
- finance_periods
- recurring_journal_templates
- recurring_journal_lines
- finance_recurring_runs
- journal_entries
- journal_lines

Current counts at investigation:

```text
finance_periods                 = 1
finance_expenses                = 0
finance_cheques                 = 0
finance_bank_statements         = 0
finance_tax_codes               = 0
fixed_assets                    = 0
recurring_journal_templates     = 0
```

The current period is:

```text
company_id = 00000000-0000-0000-0000-000000000001
period_code = FY2026
start = 2026-01-01
end   = 2026-12-31
status = OPEN
```

## Central Accounting Contract

`post_journal_entry` is the central accounting engine. It enforces company context, period guard, valid company-scoped accounts, balanced journal lines, idempotency through `erp_operation_registry`, journal creation, and audit logging.

`post_cash_payment_atomic` / `post_cash_receipt_atomic` are the current cash engines and create `cash_box` movements while updating Treasury and calling `post_journal_entry`.

No second Journal Engine was created.

## Production Migrations Executed This Session

### `20260916162000_finance_contract_integrity_close`

- `finance_open_period`: Company-scoped, rejects invalid date ranges and overlapping periods, forbids edits to CLOSED periods, audits creation/update.
- `finance_period_guard`: requires an actual matching `OPEN` period; missing period and non-open period now block posting.
- `finance_save_bank_statement`: validates company/treasury/reference/date/balances and prevents editing reconciled statements.
- `finance_save_cheque`: validates lifecycle data and avoids duplicate `ISSUED` events when editing an existing issued cheque.

### `20260916163500_finance_expense_cashflow_integrity`

- `finance_save_expense` remains on central `post_journal_entry`.
- Cash-funded expenses require sufficient Treasury balance.
- Cash-funded expenses now create `cash_box` `Payment` with `source_type='Expense'`.
- Treasury balance is reduced in the same transaction.
- `operation_id` remains the idempotency anchor.
- PUBLIC/anon execution is revoked for this RPC and authenticated/service_role retain required execution.

### `20260916165000_finance_asset_tax_bank_contract_final`

- `save_fixed_asset`: early idempotency check before mutation, core field/date/cost/life validation, Company-scoped account validation, immutable disposed assets, period guard for acquisition, audit/operation registry completion.
- `finance_save_bank_statement`: an existing statement with any matched/excluded line cannot be rewritten.
- `finance_save_tax_code`: once a Tax Code is referenced by tax transactions, code/rate/account identity cannot be changed; create a new tax code for a new tax rule.
- `finance_transition_cheque`: lifecycle transition is period-guarded.

## Finance Security

Existing public/anonymous Finance execute closures remain in force:

```text
20260916115243_finance_close_public_read_rpc_surface
20260916115339_finance_lock_anonymous_rpc_surface
20260916115431_finance_security_surface_close
```

Expected posture:

```text
PUBLIC/anon Finance execute = 0
Authenticated/service_role = retained where required
```

## Current Mother UI Findings

Current `RW_Finance_GoldExtension` contains functional actions but these specific modals are still too shallow for a professional ERP interface:

```text
newRecurring
newCheque
newBank
goldAddAsset
goldTaxCode
goldOpenPeriod
```

Confirmed gaps in current source:

- Recurring journal: raw JSON/manual UUID line entry.
- Cheque: no treasury/account selectors; current RPC is called with null account/treasury IDs.
- Bank statement: chooses the first active treasury and sends empty lines.
- Fixed asset: manual account UUID entry.
- Tax code: manual account UUID entry.
- Period: no pre-submit overlap feedback.

`newExpense` is not replaced: it already loads Company-scoped categories/accounts/cost centers/tax codes/treasury and calls `finance_save_expense`.

## Exact Mother Surgical Replacements

Full replacements are recorded in:

`doc/Draft/Reprots/Report220_MOTHER_FINANCE_SURGICAL_UI_PATCHES_20260916.md`

The report contains full replacement functions for:

- `newRecurring`
- `newCheque`
- `newBank`
- `goldAddAsset`
- `goldTaxCode`
- `goldOpenPeriod`

The report also records the exact dispatcher replacement and explicitly leaves `newExpense` and `goldTaxSettle` untouched pending E2E evidence.

## What Was Not Changed

- Mother `erp-frontend/companies/company-1/main.html` was not modified by the assistant.
- `Current/PWA/main2` was not modified.
- `Original/PWA/main` was not modified.
- Field operation chains Picker/Loading/Delivery/Return/Unloading were not modified.
- Inventory central `post_stock_movement` was not modified.
- No duplicate finance schema was created.
- No extra Edge Function was introduced where an existing secure RPC already supplies the capability.

## Closure Status

```text
Finance schema foundation                 = PROVEN PRESENT
Central accounting engine                 = PROVEN PRESENT
Finance public/anon RPC surface          = CLOSED / VERIFIED
Accounting period integrity              = CLOSED / PRODUCTION
Bank statement protected-history guard    = CLOSED / PRODUCTION
Cheque lifecycle integrity               = CLOSED / PRODUCTION
Cash expense → Journal + CashBox         = CLOSED / PRODUCTION
Fixed asset master contract              = CLOSED / PRODUCTION
Tax-code history integrity               = CLOSED / PRODUCTION
Mother dispatcher root cause             = PROVEN
Mother dispatcher surgical patch         = READY / OWNER ACTION
Finance modal UX completion              = READY / OWNER ACTION
Browser Finance E2E after Owner merge    = PENDING
Full Finance Gold/Diamond E2E             = NOT YET CLOSED
```

## Reports

- `doc/Draft/Reprots/Report218_MOTHER_FINANCE_FORENSIC_E2E_20260916.md` — historical input only.
- `doc/Draft/Reprots/Report219_MOTHER_FINANCE_FORENSIC_E2E_20260916.md` — Production Finance closure report.
- `doc/Draft/Reprots/Report220_MOTHER_FINANCE_SURGICAL_UI_PATCHES_20260916.md` — exact Mother surgical replacements.

Reports are not current truth; they are historical evidence and execution logs.

## Next Session Truth-Recovery Procedure

Always begin from CURRENT reality:

```text
CURRENT GIT
→ latest Mother HEAD
→ direct parent commit
→ current main.html
→ CURRENT PRODUCTION
→ CURRENT DATABASE
→ CURRENT DEPLOYMENT
→ browser E2E
```

Then:

```text
CURRENT SOURCE
→ CURRENT CONSUMER
→ CURRENT FUNCTION / NAMESPACE
→ CURRENT RPC
→ CURRENT PRODUCTION FUNCTION
→ CURRENT TABLE / CONSTRAINT / PRIVILEGE
→ CURRENT DEPLOYMENT / RUNTIME
```

Use historical reports only to understand why a state may exist; never use them as the present state.

Handle one Closure Unit at a time.
Do not repeat a closed fix unless regression is proven.
Do not declare backend PASS as browser PASS.
Any change to Mother must be returned to Owner as a complete surgical delete/replace block with an exact starting identifier and exact ending text; never provide truncated lines.

## Final Self-Audit

### Proven

- Current Mother source of truth is `erp-frontend/companies/company-1/main.html`.
- The actual HEAD and direct parent were checked.
- Finance database foundation is present.
- Core Finance contracts were hardened directly in Production.
- No second accounting engine was created.
- No field-operation contract was disturbed.

### Not Proven Yet

- Browser E2E after the Owner applies the Mother surgical patches.
- Final visual/interaction Gold/Diamond status of all Finance modals.
- Authenticated browser validation of every Finance action.

### Final Governance Rule

No future assistant may declare Finance fully closed until CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT + authenticated browser E2E are aligned in the same execution window.

> **تذكير حاكم أخير:** `erp-frontend/companies/company-1/main.html` هو Source of Truth الحالي ويجب قراءته بعناية قبل أي تعديل أو Closure جديد.
