# RAWAEA ERP — CURRENT STATE

> هذا الملف Living Execution State وليس مصدرًا أعمى للحالة الحالية. يجب دائمًا مطابقة محتواه مع CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.

## Current Session

- **Date:** 2026-09-16
- **Current repository / Mother source:** `papamohammed77-glitch/erp-frontend`
- **Source of Truth:** `companies/company-1/main.html`
- **Current Mother HEAD:** `3fe3c76674c7cbed8eb10201fee83ca6af2f1b07`
- **HEAD message:** `forensic: persist current Mother inventory extract`
- **HEAD parent:** `3b5fdce634e44b3a2faa6bbf2dd40db5e88a676a`
- **Current Mother blob SHA:** `744339a5cbe54a59e57bfc15bd3e3d4cce485d28`
- **Current forensic extract:** 24,150 lines; SHA256 `7f5bc99954c62d3359180dedb577e52ff498c020eb29de04adc0cf4646a89c84`

## Source-of-Truth Rule

`companies/company-1/main.html` in `erp-frontend` is the authoritative Mother source for current forensic/E2E work.

`Current/PWA/main2` and `Original/PWA/main` are historical/advisory references only.

`Current/PWA/main` and `Current/PWA/New-main` remain forbidden sources for reconstruction.

`forensic_main_assembly.yml` was verified as:

```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
assembly_status:
  mode: published_main_is_authoritative
  fragment_mode: historical_reference_only
```

## Previous Mother Finance Root Cause

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

The current source already contains the corresponding namespace bindings:

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

**OWNER surgical patch remains:**

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

Replace with:

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

## Current Production Finance State

Supabase project: `fiilmooggumokxanwiyx`.

Finance foundation exists in Production; this was re-verified rather than assumed from reports.

Existing finance entities include:

- `finance_expense_categories`
- `finance_expenses`
- `finance_expense_lines`
- `finance_cheques`
- `finance_cheque_events`
- `finance_bank_statements`
- `finance_bank_statement_lines`
- `finance_tax_codes`
- `finance_tax_transactions`
- `finance_tax_settlements`
- `fixed_assets`
- `fixed_asset_events`
- `finance_periods`
- `recurring_journal_templates`
- `recurring_journal_lines`
- `finance_recurring_runs`
- `journal_entries`
- `journal_lines`

Current counts re-verified:

```text
finance_periods                = 1
finance_expenses               = 0
finance_cheques                = 0
finance_bank_statements        = 0
finance_tax_codes              = 0
fixed_assets                    = 0
recurring_journal_templates     = 0
```

The single current period is `FY2026`, `2026-01-01 → 2026-12-31`, `OPEN`.

## Central Accounting Contract

`post_journal_entry` is the current central accounting engine. It enforces company context, period guard, valid company-scoped accounts, balanced debits/credits, operation idempotency, journal entry/line creation, and audit logging.

`post_cash_payment_atomic` and `post_cash_receipt_atomic` are the current cash engines and create `cash_box` records while updating treasury and posting the central journal.

No second Journal Engine was created.

## Finance Production Changes Executed This Session

### Accounting period contract

Migration: `20260916162000_finance_contract_integrity_close`

- Reject overlapping periods within the same company.
- Reject editing a closed period through `finance_open_period`.
- Require a real `OPEN` accounting period for every guarded posting date.
- Reject posting when no matching period exists.
- Audit period create/update operations.

### Bank statement contract

Within the same migration:

- Reconciled statements cannot be edited through the save path.
- Statement reference/date/balances are mandatory.
- Bank statement lines are validated before insertion.
- Company and Treasury scoping are enforced.

### Cheque lifecycle contract

Within the same migration:

- cheque number/type/amount/date are validated.
- due date cannot precede cheque date.
- linked accounts/treasury must belong to the company.
- only `ISSUED` cheques are editable.
- editing an existing cheque no longer creates an additional fake `ISSUED` lifecycle event.
- creation writes the initial `ISSUED` event exactly once.

### Cash expense integration

Migration: `20260916163500_finance_expense_cashflow_integrity`

- Keeps `post_journal_entry` as the central accounting posting path.
- Validates treasury sufficiency before posting.
- Cash expenses now create a `cash_box` Payment record with `source_type='Expense'`.
- Treasury balance is updated in the same transaction.
- Existing `operation_id` remains the idempotency anchor.

## Finance Security

Existing Finance anonymous/public execute closures remain active and verified:

```text
20260916115243_finance_close_public_read_rpc_surface
20260916115339_finance_lock_anonymous_rpc_surface
20260916115431_finance_security_surface_close
```

Expected posture:

```text
Finance RPC EXECUTE for PUBLIC/anon = 0
Authenticated/Service role execution = retained where required
```

## What Was Not Changed

- `erp-frontend/companies/company-1/main.html` was not modified by the assistant.
- `Current/PWA/main2` was not modified.
- `Original/PWA/main` was not modified.
- Inventory `post_stock_movement` contract was not altered.
- Picker / Loading / Delivery / Return / Unloading operations were not altered.
- No duplicate finance tables were created because the current schema already contains the required foundation.
- No new Edge Function was created where a current secure RPC already provides the capability.

## Mother UI Findings — Owner Action

Current `RW_Finance_GoldExtension` has the required public actions, but several modal designs remain thin and UUID-driven.

Current exact functions identified in the source:

```text
async function newRecurring(){ ... }
async function newCheque(){ ... }
async function newBank(){ ... }
async function goldAddAsset(){ ... }
async function goldTaxCode(){ ... }
async function goldOpenPeriod(){ ... }
```

Current functional gaps are:

- Recurring journal modal relies on raw JSON/UUID entry instead of account selection and an interactive line editor.
- Cheque modal leaves account and treasury fields null instead of selecting valid company-scoped accounts/treasury.
- Bank statement modal uses the first active treasury and has no line-entry editor.
- Fixed asset modal requires manual account UUID entry.
- Tax modal requires manual account UUID entry.
- Period modal does not surface overlap validation before submission.

The backend has been strengthened so the Mother UI should consume these contracts correctly rather than bypass them.

`newExpense` already loads Company-scoped categories/accounts/cost centers/tax and calls `finance_save_expense`; it should not be replaced merely for visual reasons without evidence of regression.

## Current Closure Status

```text
Finance schema foundation                 = PROVEN PRESENT
Central journal engine                    = PROVEN PRESENT
Finance anonymous/public RPC surface     = CLOSED / VERIFIED
Accounting period contract                = CLOSED / PRODUCTION
Bank statement edit protection             = CLOSED / PRODUCTION
Cheque lifecycle event duplication         = CLOSED / PRODUCTION
Cash expense → cash_box integration         = CLOSED / PRODUCTION
Mother dispatcher root cause               = PROVEN
Mother dispatcher patch                    = READY / OWNER ACTION
Browser Finance E2E                         = PENDING OWNER SOURCE CHANGE
Full Finance E2E                             = NOT YET CLOSED
```

## Current Session Report

`doc/Draft/Reprots/Report219_MOTHER_FINANCE_FORENSIC_E2E_20260916.md`

Previous finance forensic report:

`doc/Draft/Reprots/Report218_MOTHER_FINANCE_FORENSIC_E2E_20260916.md`

Previous reports remain historical and must not override live evidence.

## Next Session Truth-Recovery Procedure

Always start by obtaining CURRENT GIT first.

```text
1. GET real current Mother HEAD.
2. GET direct parent commit.
3. Inspect parent/current diff for the exact target area.
4. Open current Mother Source of Truth only:
   erp-frontend/companies/company-1/main.html
5. Match exact consumer → function → namespace → RPC → Production function → DB schema/constraints/privileges.
6. Query CURRENT PRODUCTION immediately before any percentage, score, or closure claim.
7. Treat reports only as historical evidence.
8. Open Original/Current fragment files only to reconstruct intent, never as current deployment truth.
9. Handle one Closure Unit at a time.
10. Production changes must be executed as reproducible migrations.
11. Mother changes must be returned to Owner as complete surgical delete/replace blocks.
12. Never repeat a closed fix without evidence of regression.
13. After every Owner source change, perform real browser reload + real click E2E.
```

## Final Self-Audit

### Proven

- Current Mother HEAD is `3fe3c766...`.
- Parent is `3b5fdce...`.
- Current Mother `main.html` is the Source of Truth.
- Finance database foundation exists.
- Central accounting engine exists.
- Period, bank statement, cheque, and expense cash-flow contracts were hardened in Production.

### Not Proven Yet

- Browser E2E after the Owner applies the dispatcher patch.
- Final UX/interaction completion of every Finance modal.
- Real authenticated browser validation for every Finance action.

### Governance rule

No future assistant should declare Finance fully closed until CURRENT PRODUCTION + CURRENT SOURCE + browser E2E are aligned in the same execution window.
