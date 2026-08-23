# RAWAEA ERP — FORENSIC FINANCIAL MASTER-DATA DECISION

Date: 2026-08-23
Production: SMART ERP

## Authority order

1. Production PostgreSQL / deployed definitions
2. Current Git
3. Current CTO/evidence artifacts
4. Historical/original sources
5. Previous reports only as chronological evidence

## Proven Production facts

- Exactly one live company remains: `00000000-0000-0000-0000-000000000001` / `MAIN` / `الروائع`.
- Current user count: 24.
- `chart_of_accounts`: 0 rows before this recovery action.
- `treasury`: 0 rows before this recovery action.
- `cash_box`: 0 rows.
- `journal_entries`: 2 rows.
- `journal_lines`: 0 rows.
- customer/supplier/driver ledgers: 0 rows.
- Retired tenant `da4ef704-88ac-4120-aa0e-65b92b2aa2bc` previously had 87 chart-of-accounts rows and 1 treasury row.
- Retired tenant `73a141bd-157a-4c2c-8693-34e21325b943` was also removed during the single-tenant cleanup.

## Treasury recovery actually executed

Exact historical treasury row recovered from `audit_log`:

- id: `0a9d9357-b5f3-4dfa-886f-7c73de4f274e`
- old company: `da4ef704-88ac-4120-aa0e-65b92b2aa2bc`
- new owner company: `00000000-0000-0000-0000-000000000001`
- account_code: `CASH-01`
- account_name: `الخزينة الرئيسية`
- type: `Cash`
- opening_balance: `10000`
- current_balance: `10000`
- is_active: `true`
- notes: null
- original created_at: `2026-05-16T00:08:06.123874+00:00`
- original updated_at: `2026-05-16T00:08:06.123874+00:00`

The row was inserted into the current company without changing its UUID or historical balances. The normal audit trigger recorded the restoration as a `create` event at 2026-08-23 20:30:21.319524+00.

## 87-account decision

The exact 87 account rows are NOT currently recoverable from `audit_log`.

Direct audit inspection shows no row-level audit trail for `chart_of_accounts`; the tenant deletion evidence preserves only the count `87`, not the 87 account records.

Current `rawaie-erp-review/PWA/main.html` contains an application seed of only 14 accounts (including 1/11/12/121/123/124/2/21/211/216/3/31/4/41/5/51). This is an application bootstrap, NOT proof of the historical 87-account chart.

Therefore:

**DO NOT synthesize, infer, or expand the 87 from accounting conventions.**

The 87 can be restored only after an exact row-level source is found in:

- historical Git commit/tree/blob,
- an authoritative production snapshot/backup,
- a preserved migration/seed containing all rows,
- or another directly verifiable historical source.

Until that source is found, `87-account reconstruction` is an OPEN forensic recovery item, not an invitation to fabricate data.

## Current schema constraints verified

- `chart_of_accounts.parent_account_id -> chart_of_accounts.id` ON DELETE SET NULL.
- `journal_lines.account_id -> chart_of_accounts.id` ON DELETE RESTRICT.
- `treasury(company_id, account_code)` UNIQUE.
- `treasury.company_id -> companies.id` ON DELETE CASCADE.
- `cash_box.treasury_id -> treasury.id` ON DELETE RESTRICT.

## Critical errors discovered

1. Historical company consolidation deleted the old tenant before exact chart-of-accounts row preservation was proven.
2. Previous reports sometimes treated row counts and closure statements as proof of functional correctness.
3. The financial layer is not currently operationally complete: there are journal headers but zero journal lines and no active chart-of-accounts rows.
4. Current SQL confirms only a subset of expected financial RPCs exists under canonical names; receipt/payment/transfer/daily-settlement/driver-ledger convergence remains an open forensic task.
5. `rawaie-erp-review/PWA/main.html` seeds only 14 accounts, so it cannot be promoted to the historical 87-account source without further proof.

## Decision

- Treasury: RESTORED under the single live company.
- 87-account chart: NOT fabricated. OPEN pending exact source recovery.
- Financial writer convergence: OPEN and assigned to the next CTO execution track.
- Any report claiming the 87-account chart is already fully restored is rejected unless accompanied by row-level source evidence and Production verification.
