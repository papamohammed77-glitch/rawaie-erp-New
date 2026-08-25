# RAWAEA ERP — PHASE 1
# KHALID COA SOURCE REGISTER

**Execution date:** 2026-08-25
**Role:** Khalid — Forensic COA Recovery Owner
**Production project:** `fiilmooggumokxanwiyx`
**Current Git main HEAD at execution:** `1d9b3b21b8adc7a49fcdd4b574908d3014b73173`
**Current Production snapshot timestamp:** `2026-08-25 00:39:23.711724 UTC`

## 1. Authority and decision rule

Authority order:

`Current Production > Current Git main > Current evidence > Historical sources > Reports`

Objective: recover the **exact historical 87-row COA dataset** of retired company `da4ef704-88ac-4120-aa0e-65b92b2aa2bc`.

No count-only source qualifies. No inferred hierarchy, synthetic UUID, generated account, or reconstructed 87-row dataset is acceptable.

## 2. Current Production gate

| Item | Current Production |
|---|---:|
| Companies | 1 |
| Users | 24 |
| Branches | 2 |
| Items | 17 |
| Stock rows | 20 |
| Inventory log | 3 |
| Stock vouchers | 0 |
| Treasury | 1 |
| Chart of Accounts | 0 |
| Journal entries | 2 |
| Journal lines | 0 |
| Customer ledger | 0 |
| Supplier ledger | 0 |
| Driver ledger | 0 |
| Orders | 0 |
| Purchase orders | 0 |
| Runsheets | 0 |

Current Treasury was independently rechecked and exists as:

- `CASH-01`
- `الخزينة الرئيسية`
- company `00000000-0000-0000-0000-000000000001`
- opening/current balance `10000.00`
- active

No Treasury mutation was performed.

## 3. Source register

| Source ID | Location | Candidate material | Exact 87 rows | Row-level fields | UUID / Parent UUID | Integrity / authority result | Decision |
|---|---|---|---:|---|---|---|---|
| PROD-01 | Live Production `chart_of_accounts` | Current COA table | 0 | N/A | N/A | Production-authoritative; current table is empty | EXHAUSTED |
| PROD-02 | Live Production `audit_log` | Historical COA audit evidence | 0 recoverable COA snapshots | None sufficient | None sufficient | Production-authoritative but no recoverable deleted-COA row snapshots | EXHAUSTED |
| PROD-03 | Live Production `treasury` | Current Treasury contract | N/A | Treasury row only | Current Treasury UUID present | Verified current master data; does not prove historical COA mapping | REJECTED for COA recovery |
| GIT-01 | `rawaie-erp-New` current main | Current COA schema / bootstrap sources | 16 bootstrap/base accounts only | Partial account data | Historical 87 UUID set absent | Valid current-source evidence; not historical 87 | REJECTED for 87 recovery |
| GIT-02 | `rawaie-erp-New` reachable history | Tenant/consolidation/recovery commits | 0 exact 87-row dataset | Counts/decisions only | No complete historical row set | Reachable Git history searched; no row-level 87 dataset | EXHAUSTED |
| GIT-03 | `rawaie-erp-New` migrations/seeds | COA schema, `seedAccounts`, account references | No exact 87 dataset | Bootstrap/schema only | No historical 87 row set | No source-backed historical dataset | EXHAUSTED |
| GIT-04 | `rawaie-erp-New` financial writer references | Current/historical financial account references | No 87 dataset | Individual references only | No complete row set | Useful for downstream compatibility only; not historical recovery | REJECTED for 87 recovery |
| REV-01 | `rawaie-erp-review` accessible repository search/tree | Historical COA/tenant evidence | 0 exact 87-row dataset located | No complete row-level dataset located | No verified 87 UUID set located | Repository exists and is accessible; relevant searches did not yield the dataset | EXHAUSTED for accessible search |
| DOC-01 | `doc/Draft/medhat/تقرير مساعد خارجي حول الحسابات` | 16-account bootstrap table + narrative about 87 | 0 | 16 bootstrap rows only | No historical 87 UUID set | Explicitly states the 87 rows were not available to the author; report is non-authoritative for recovery | REJECTED |
| DOC-02 | Prior Khalid Prompt 56 certificate | Source-exhaustion record | 0 exact 87 dataset | Evidence inventory only | Historical tenant UUID recorded | Useful historical evidence of prior search, not source data | CONFIRMATORY ONLY |
| HIST-01 | Historical reports / CTO artifacts | Historical count and descriptions | 87 count only | Not sufficient | Not sufficient | Reports are chronological navigation evidence, not row-level authority | EXCLUDED |
| OBJ-01 | Unreachable / dangling Git objects | Unknown | Unknown | Unknown | Unknown | GitHub accessible API does not enumerate arbitrary unreachable objects without known SHA/object database access | UNKNOWN; NOT CERTIFIABLE |

## 4. Search dimensions executed

The recovery search explicitly covered the required dimensions:

- `chart_of_accounts`
- `account_code`
- `account_name`
- `account_type`
- `normal_balance`
- `parent_account_id`
- `company_id`
- historical tenant UUID `da4ef704-88ac-4120-aa0e-65b92b2aa2bc`
- `seedAccounts`
- `CASH-01`
- current/historical financial writer account references
- migrations / seeds / historical CTO artifacts
- reachable Git history and trees
- `rawaie-erp-review`
- current Production and `audit_log`

## 5. Material evidence

### Current COA schema

Current `public.chart_of_accounts` has the following contract columns:

`id`, `company_id`, `account_code`, `account_name`, `account_type`, `parent_account_id`, `normal_balance`, `is_active`, `notes`, `created_at`, `updated_at`.

### Bootstrap source

The externally documented `_seedAccounts` material contains 16 accounts only. It explicitly states that the 87 rows were not supplied and that the 16 rows must not be treated as the historical 87.

### Historical 87 count

The existence of a historical count of 87 is preserved in prior evidence, but no reachable authoritative source was found containing the 87 rows themselves.

## 6. Search boundary

All currently accessible/reachable authoritative source classes have been exhausted for an exact 87-row dataset.

The only unresolved technical surface is arbitrary unreachable/dangling Git objects for which no known object SHA exists. The available GitHub interface cannot enumerate that object database surface, so it cannot be honestly certified either present or absent.

## 7. Decision

`EXACT 87 SOURCE = NOT FOUND`

`SOURCE EXHAUSTION = CLOSED` for all accessible/reachable source surfaces.

`ROW-LEVEL RECOVERY = OPEN`

`NO FABRICATION = TRUE`

`PRODUCTION COA CHANGE = FORBIDDEN / NOT PERFORMED`

No replay dataset is produced because no exact source-backed 87-row dataset exists.

No further search cycle should be opened against the same evidence universe merely to repeat this result.
