# RAWAEA ERP — KHALID PROMPT 55
# CURRENT-COMPANY FINANCIAL MASTER RECOVERY

Date: 2026-08-24  
Role: Khalid — Financial Master Data Recovery / Reporting Governance  
Production: SMART ERP (`fiilmooggumokxanwiyx`)  
Repository: `rawaie-erp-New/main`

## 1. Authority

Production PostgreSQL > Current Git > Current evidence > Historical sources > Reports.

Prompt 55 was read in full. Its current-company directive was executed against the live single-company Production state and against Git/history sources.

## 2. Current Production tenant reality

Direct Production verification on 2026-08-24:

- `public.companies = 1`
- surviving company: `00000000-0000-0000-0000-000000000001` / `الروائع`
- active users: 24
- branches: 2
- `chart_of_accounts = 0`
- `treasury = 1`
- `cash_box = 0`
- `journal_entries = 2`
- `journal_lines = 0`

The retired companies are no longer present in the live `companies` table. Prompt 55 references staging/current-company identifiers from its preceding forensic run; those are treated as historical/staging evidence, not Production identity.

## 3. Treasury status

The current Production treasury row is already present under the surviving company:

- UUID: `0a9d9357-b5f3-4dfa-886f-7c73de4f274e`
- company: `00000000-0000-0000-0000-000000000001`
- account_code: `CASH-01`
- account_name: `الخزينة الرئيسية`
- type: `Cash`
- opening_balance: `10000`
- current_balance: `10000`
- is_active: true

No Treasury recreation was performed. No remapping was invented.

## 4. Exact 87-account recovery investigation

Authoritative-source sweep performed across:

- current `rawaie-erp-New` search surface;
- Git history/commits relevant to company consolidation and financial master data;
- historical `rawaie-erp-review` search surface;
- current CTO forensic records;
- application seed references;
- Production `audit_log` schema and row-level records;
- known historical tenant identifier references;
- exact financial account code references such as `121`, `124`, `41`, `51`, and `CASH-01`.

### Result

No authoritative row-level dataset containing the exact historical 87 COA rows was recovered.

The following are NOT accepted as row-level recovery:

- a report stating that the count was 87;
- the application seed of 14/16 base accounts;
- inferred accounts based on accounting conventions;
- invented parent-child relationships;
- reconstructed balances from memory.

The current audit table contains no `chart_of_accounts` audit rows, so it cannot reconstruct the deleted rows.

Therefore:

**87-account exact recovery remains OPEN.**

## 5. What was proven about the historical 87

The historical tenant `da4ef704-88ac-4120-aa0e-65b92b2aa2bc` previously contained 87 COA rows. This is a historical count, not a row-level recovery.

The application seed contains only the known base structure and explicitly cannot be promoted to the historical 87 without source proof.

## 6. Current company / financial master relationship

The live topology is now deliberately single-company.

The Production treasury has already been moved/preserved under the surviving company while retaining its historical UUID and balances.

The financial master is still incomplete because the surviving company currently has zero COA rows.

No automatic reconstruction was performed because doing so would create unverified accounting master data.

## 7. Production financial readiness consequence

The architectural cores may exist, but the retained company cannot be considered financially production-ready for journalized transactions until a source-backed COA is restored/canonicalized.

This is a Financial Master Data gate, not an Inventory Core gate.

Inventory Core was not modified and remains outside this Closure Unit.

## 8. Hytham integration boundary

Prompt 55 assigns Hytham to Financial Writer Convergence. Khalid did not modify the POS write side, financial writers, Inventory Core, or the financial PWAs.

The correct integration boundary is:

Khalid → Financial Master Data / COA / Treasury ownership evidence  
Hytham → Transactional financial writer convergence

Neither side should invent the missing COA.

## 9. Decisions preserved

1. Do not recreate the retired companies.
2. Do not recreate the missing 87 accounts from convention.
3. Do not remap Treasury to guessed account codes.
4. Do not modify `accountant.html` or `finance-manager.html` in this mission.
5. Do not modify POS write-side code.
6. Do not modify Inventory Core.
7. Do not treat report counts as row-level evidence.

## 10. Closure matrix

| Unit | Status |
|---|---|
| Single-company Production topology | **CLOSED / VERIFIED** |
| Current Treasury ownership | **CLOSED / VERIFIED** |
| Exact 87 COA row recovery | **OPEN / SOURCE NOT FOUND** |
| COA canonicalization | **BLOCKED BY SOURCE RECOVERY** |
| Treasury ↔ COA semantic contract | **OPEN** |
| Financial Writer Convergence | **HYTHAM TRACK / OPEN** |
| Accountant Consumer | **OPEN / OUT OF SCOPE** |
| Finance Manager Consumer | **OPEN / OUT OF SCOPE** |
| Inventory Core | **UNCHANGED** |

## 11. Required next evidence

Only one class of evidence can close the 87-account gate:

- authoritative historical database backup/export;
- exact Git blob/tree/seed/migration containing all 87 rows;
- preserved row-level snapshot with IDs, codes, parent IDs, types and normal balances;
- another directly verifiable historical source.

If such a source is recovered, the replay must be deterministic, current-company owned, FK-valid, uniqueness-valid, and staged before any Production replay.

## 12. Final status

`KHALID PROMPT 55 = EXECUTED`

`SINGLE-COMPANY RECOVERY CONTEXT = VERIFIED`

`TREASURY RECOVERY = VERIFIED`

`87 COA RECOVERY = OPEN`

`NO FABRICATION = CONFIRMED`

`AUTONOMOUS CTO READY = NO`
