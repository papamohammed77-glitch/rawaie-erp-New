# RAWAEA ERP — Accountant Regression Forensic Correction

**Event ID:** 20260827-ACCOUNTANT-REGRESSION-CORRECTION-01
**Date:** 2026-08-27
**Scope:** `Current/PWA/accountant.html` + financial reporting RPC correctness

## Source Authority

The governing hierarchy used for this correction was:

1. Current Production Supabase
2. Current `main` Git
3. Current CTO/evidence records
4. Historical source and assistant reports

Historical reports were treated as historical evidence only.

## Question Under Investigation

A concern was raised that `accountant.html` had been reduced from approximately 1020 lines to approximately 69 lines and that important working functions/features might have been deleted.

## Forensic Finding

The reduction in line count was caused by a deliberate rebuild at commit `76f9a926039ec9918cac17f3a9f7f2f3c96a61fe`, not by a line-preserving refactor.

The pre-rebuild version at parent commit `2d7f3f559b3a3b4d83a8c07c911c9791e936c831` was inspected in full through its source ranges.

The old file was not a complete accountant suite. It had four tabs only:

- Dashboard
- Receipts
- Payments
- Journal

Its journal screen was a placeholder, while receipt/payment operations already used the newer UUID/operation-id contract. It also contained a password-visibility toggle and a visible user-name header.

## Capabilities Proven Preserved or Expanded

The current rebuild retained the core financial workflow and expanded the accountant surface with:

- company-scoped financial context
- receipt creation through `save-receipt-voucher`
- payment creation through `save-payment-voucher`
- UUID-based treasury/account identities
- operation-id retry protection
- posted journal browsing and line drill-down
- Trial Balance
- Profit & Loss
- Balance Sheet
- Cost Center P&L
- Cash movement
- Customer/Supplier operational balances
- Core operation registry visibility

Therefore the line-count reduction did **not** correspond to deletion of an equivalent amount of business capability.

## Actual Regressions Found

The forensic comparison did identify real regressions/defects:

1. Password visibility toggle was removed.
2. The previous header user-name display was no longer populated.
3. Receipt/payment date and search controls were rendered but not wired to reload the query.
4. Journal date/search controls were rendered but not wired to reload the query.
5. Cash Flow reporting existed in PostgreSQL but had no accountant UI entry point.
6. The current `get_trial_balance` and `get_balance_sheet` SQL implementations used a LEFT JOIN to `journal_entries` with period/status predicates in the JOIN itself, while aggregating `journal_lines` without requiring the matching posted/period row. This could include line amounts outside the intended report scope.

## Corrections Applied

### PWA

`Current/PWA/accountant.html` was corrected without restoring the legacy architecture.

Restored:

- password visibility toggle
- user-name/role display

Corrected:

- interactive receipt/payment date filtering
- interactive receipt/payment search
- interactive journal date filtering
- interactive journal search
- Cash Flow report entry
- company-specific local operation-id storage keys
- CSV line endings and download cleanup

The financial write boundary remains:

PWA → Edge Adapter → Canonical Financial Core

No direct financial DML was added to the PWA.

### Reporting Core

Production RPCs were corrected:

- `get_trial_balance`
- `get_balance_sheet`

The correction preserves zero-balance account visibility while only aggregating journal lines attached to qualifying posted journal entries within the requested period.

## Git Result

The corrected PWA was committed on `main` as:

`906a10834a5a3b00ae1c4e98ba4331d3cd160373`

The previous accountant rebuild commit remains historical evidence and was not rewritten.

## Production Result

The reporting RPC correction was applied directly to Production through a migration.

No business data was deleted or rewritten by this correction.

## Verification Boundary

### Verified directly

- Historical/current source comparison.
- Current Production financial Core definitions.
- Current Production reporting RPC definitions.
- Financial read company scoping.
- Receipt/payment Core contract.

### Not claimed

- Browser-level PWA runtime verification.
- Production PWA hosting deployment verification.
- True two-session concurrency verification.

These remain separate runtime gates and were not converted into false PASS claims.

## Final Classification

**Accountant rebuild catastrophic data/function loss:** NOT PROVEN.

**Actual UX regressions found:** YES.

**Actual SQL reporting defect found:** YES.

**Corrections applied:** YES.

**Financial PWA direct-write reintroduced:** NO.

**Full Accountant Suite / global financial zero-debt:** NOT CERTIFIED.
