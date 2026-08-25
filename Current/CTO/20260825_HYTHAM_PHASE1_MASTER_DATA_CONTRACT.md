# RAWAEA ERP — PHASE 1 HYTHAM MASTER DATA CONTRACT

## Mission

Financial Master Data Contract / Staging Validation Owner.

This Phase 1 unit validates the technical contract required for any future source-backed COA dataset. It does **not** recover the historical 87 rows independently, does not invent rows, and does not mutate Production.

## Authority

`Production PostgreSQL > Current main > Current evidence > Historical sources > Reports`

## Verification timestamp

Production read-only verification: `2026-08-24 16:06:44.657473 UTC`

Staging verification: `2026-08-25` execution window.

Production project: `fiilmooggumokxanwiyx`
Staging project: `hfzznsiprnwkpayskzhu`

## Current topology

Production currently has one surviving company:

`00000000-0000-0000-0000-000000000001`

Production COA count = `0`.
Production Treasury count = `1`.

No Production COA mutation was performed.
No Production Treasury mutation was performed.

---

# 1. PRODUCTION COA SCHEMA CONTRACT

Direct `information_schema` verification produced:

| Column | Type | Nullable | Default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| company_id | uuid | NO | app_private.current_user_company_id() |
| account_code | varchar | NO | — |
| account_name | varchar | NO | — |
| account_type | varchar | NO | — |
| parent_account_id | uuid | YES | — |
| normal_balance | varchar | NO | — |
| is_active | boolean | YES | true |
| notes | text | YES | — |
| created_at | timestamptz | YES | now() |
| updated_at | timestamptz | YES | now() |

### Constraints

Verified directly:

- `chart_of_accounts_pkey` — PRIMARY KEY (`id`)
- `chart_of_accounts_company_id_account_code_key` — UNIQUE (`company_id`, `account_code`)
- `chart_of_accounts_company_id_fkey` — `company_id → companies.id`
- `chart_of_accounts_parent_account_id_fkey` — `parent_account_id → chart_of_accounts.id`

### Indexes

Verified directly:

- `chart_of_accounts_pkey`
- `chart_of_accounts_company_id_account_code_key`
- `idx_chart_of_accounts_company`

### Contract conclusion

A source-backed COA dataset must preserve:

1. UUID identity validity.
2. Current-company ownership.
3. Unique `(company_id, account_code)`.
4. Parent FK validity.
5. Non-null required account fields.
6. Active-state compatibility.
7. Production RLS/security model.

No schema redesign is authorized by this Phase 1 unit.

---

# 2. ACCOUNT IDENTITY CONTRACT

## 2.1 `post_journal_entry`

Production implementation requires each journal line to contain:

`account_id` as a UUID.

The function then resolves `chart_of_accounts.account_name` by UUID and requires:

- account UUID exists;
- account belongs to the submitted company;
- account is active;
- line is non-zero;
- debit/credit are not both positive;
- journal totals balance.

Therefore:

`account_name` is descriptive at posting time.
`account_id` is the authoritative account identity.

## 2.2 Cash cores

`post_cash_receipt_atomic` and `post_cash_payment_atomic` both require:

- `p_cash_account_id` UUID;
- `p_offset_account_id` UUID;
- both accounts must exist in the submitted company;
- both accounts must be active.

Treasury is separately identified by:

`p_treasury_id` UUID

and validated against:

- treasury UUID;
- company ownership;
- active state.

No Treasury account-code string is converted automatically into a COA UUID by these cores.

## 2.3 Compound writers

Current Production compound writers additionally contain code-based account lookup contracts:

### POS
`sales_cash / AR / sales / COGS / inventory` lookups currently use codes:

`121`, `123`, `41`, `51`, `124`

and then pass the resulting UUIDs to the canonical cores.

### Purchase Receiving
Uses codes:

`211`, `124`

then passes resolved UUIDs to `post_journal_entry` / `post_supplier_ledger_entry`.

### Returns
Uses codes:

`124`, `51`

then passes resolved UUIDs to `post_journal_entry`.

### Implication

A replay dataset is not contract-complete merely because its names “look right”.
The candidate dataset must explicitly validate account-code uniqueness and the existence/identity of the exact codes required by current write-side consumers.

No code-to-account mapping is to be invented during replay.

---

# 3. PARENT RELATION CONTRACT

Production has a self-referential FK:

`parent_account_id → chart_of_accounts.id`

Therefore every non-null parent reference in a candidate dataset must resolve to another candidate/current row after company remap.

Required validations:

- parent exists;
- parent is not self;
- no cycle exists;
- parent belongs to same company;
- UUID remap preserves graph topology.

No hierarchy may be inferred from account-code prefixes or names.

---

# 4. TREASURY CONTRACT

Production Treasury schema was verified directly.

| Column | Type | Required |
|---|---|---|
| id | uuid | YES |
| company_id | uuid | YES |
| account_code | varchar | YES |
| account_name | varchar | YES |
| type | varchar | YES |
| opening_balance | numeric | NO |
| current_balance | numeric | NO |
| is_active | boolean | NO |
| notes | text | NO |
| created_at | timestamptz | NO |
| updated_at | timestamptz | NO |

Current Production row:

- id: `0a9d9357-b5f3-4dfa-886f-7c73de4f274e`
- company_id: `00000000-0000-0000-0000-000000000001`
- account_code: `CASH-01`
- account_name: `الخزينة الرئيسية`
- type: `Cash`
- opening_balance: `10000.00`
- current_balance: `10000.00`
- is_active: `true`

### Critical conclusion

Treasury currently has **no explicit FK to `chart_of_accounts`**.

The schema therefore does not prove a Treasury→COA identity relation.

Current cash cores accept the Treasury UUID and a separate COA cash-account UUID.

Therefore:

`CASH-01 → COA account` remains **UNPROVEN**.

No mapping is inferred from code/name similarity.

Treasury is preserved unchanged.

---

# 5. CURRENT PRODUCTION MASTER DATA STATE

At the current Production baseline:

- Companies = 1
- Treasury = 1
- COA = 0
- Journal Entries = 2
- Journal Lines = 0
- Customer Ledger = 0
- Supplier Ledger = 0
- Driver Ledger = 0
- Orders = 0
- Purchase Orders = 0
- Runsheets = 0

This means there is currently no live COA dataset against which to validate historical account UUID continuity.

---

# 6. KHALID DATASET STATUS

The latest accessible Khalid forensic certificate states:

`SOURCE EXHAUSTION = CLOSED`

`EXACT 87 COA RECOVERY = OPEN`

and explicitly states that no exact 87-row dataset was found in the accessible Production/Git/review/evidence surfaces.

Therefore no source-backed 87-row replay dataset is currently available to Hytham.

### Status

`KHALID DATASET = NOT DELIVERED`

This is not a validation failure. It is a source-evidence dependency.

No account row was invented.
No UUID was synthesized.
No parent relation was guessed.

---

# 7. STAGING CONTRACT VERIFICATION

Staging project:
`hfzznsiprnwkpayskzhu`

Current direct observations:

- PostgreSQL 17.6
- Companies = 1
- COA rows = 0
- Treasury rows = 1
- Journal Entries = 0
- Journal Lines = 0

Staging Treasury currently has:

- account_code = `CASH-01`
- account_name = `الخزينة الرئيسية`
- type = `Cash`
- opening_balance = `10000`
- current_balance = `10000`
- is_active = true

### Staging drift discovered

`chart_of_accounts` exists with the expected columns, but direct inspection currently shows:

- no visible table constraints;
- no visible indexes;
- RLS disabled.

This differs materially from Production, where COA has:

- PRIMARY KEY;
- `(company_id, account_code)` UNIQUE;
- company FK;
- parent self-FK;
- indexes;
- RLS enabled.

### Staging conclusion

The current Staging instance is **not yet a faithful structural replay target for Production COA validation**.

A COA replay executed against it in its current state would not prove Production compatibility.

No staging security weakening or schema modification was performed in this unit.

---

# 8. REQUIRED REPLAY VALIDATION CONTRACT

When Khalid supplies a source-backed dataset, Hytham will validate every row for:

1. exact source-backed values;
2. UUID syntax and uniqueness;
3. historical company ownership;
4. remap to current company;
5. account-code uniqueness;
6. required fields;
7. parent existence;
8. self-parent rejection;
9. cycle rejection;
10. current Production FK compatibility;
11. current Production UNIQUE compatibility;
12. `is_active` compatibility;
13. compatibility with all code-based account lookups currently present in POS/Purchase/Return;
14. compatibility with `post_journal_entry`;
15. compatibility with cash receipt/payment cores;
16. reporting compatibility;
17. rollback safety.

The candidate dataset must survive the complete chain:

`SOURCE → NORMALIZED REPLAY DATASET → VALIDATION → STAGING REPLAY → CORE COMPATIBILITY → ROLLBACK`

before any Production decision is considered.

---

# 9. TECHNICAL MATRIX

| Contract | Current Production | Historical Evidence | Khalid Dataset | Staging Result | Risk | Status |
|---|---|---|---|---|---|---|
| Account identity | UUID + company + active | Missing exact rows | Not delivered | Schema exists | High | VERIFIED CONTRACT / DATA BLOCKED |
| Parent relation | Self FK | Missing exact hierarchy | Not delivered | FK not present in staging | High | PRODUCTION VERIFIED / STAGING DRIFT |
| Company ownership | `company_id` FK | Historical tenant known | Not delivered | Single staging company | Medium | VERIFIED |
| Account-code uniqueness | `(company_id, account_code)` UNIQUE | Not enough row evidence | Not delivered | No visible constraint | High | PRODUCTION VERIFIED / STAGING DRIFT |
| Treasury identity | `CASH-01` UUID row | Treasury preserved | N/A | `CASH-01` staging row | Medium | VERIFIED |
| Treasury ↔ COA relation | No explicit FK | No authoritative mapping | Not delivered | No evidence | High | OPEN |
| Journal posting compatibility | UUID-based, company/active enforced | N/A | Not delivered | Core exists | High | VERIFIED CONTRACT |
| Cash-core compatibility | UUID treasury + UUID cash/offset account | N/A | Not delivered | Core contract exists | High | VERIFIED CONTRACT |
| Reporting compatibility | COA by company + journal lines | N/A | Not delivered | Functions available | Medium | VERIFIED STRUCTURE |

---

# 10. BLOCKERS / OWNER DECISIONS

## Blocker A — Exact source dataset

`EXACT 87 COA RECOVERY = OPEN`

Owner/dependency: Khalid / project owner.

No technical replay closure is possible without row-level source data.

## Blocker B — Treasury ↔ COA

`OPEN`

A valid future source dataset must establish which COA row is the cash account, by evidence, not by `CASH-01` naming convention.

## Blocker C — Staging structural parity

`OPEN`

Current staging COA does not visibly enforce Production's PK/FK/UNIQUE/RLS contract.

A replay against current staging alone cannot certify Production compatibility.

No staging DDL was applied by Hytham because this unit did not authorize schema mutation.

---

# 11. PRODUCTION SAFETY

Explicitly verified:

- Production COA INSERT = `NOT PERFORMED`
- Production COA UPDATE = `NOT PERFORMED`
- Production COA DELETE = `NOT PERFORMED`
- Treasury mutation = `NOT PERFORMED`
- Inventory mutation = `NOT PERFORMED`
- PWA mutation = `NOT PERFORMED`
- Financial writer mutation = `NOT PERFORMED`

---

# 12. PHASE 1 HYTHAM STATUS

`PHASE 1 HYTHAM MASTER DATA CONTRACT = OPEN / TECHNICAL CONTRACT PROVEN`

### Closed technical gates

- Production COA schema contract = **VERIFIED**
- Production account identity contract = **VERIFIED**
- Parent-FK semantics = **VERIFIED**
- Treasury schema/identity = **VERIFIED**
- Current cash-core account identity requirements = **VERIFIED**
- Reporting COA consumption contract = **VERIFIED STRUCTURE**
- Production safety gate = **VERIFIED**

### Open gates

- Exact 87-row source dataset = **OPEN**
- Khalid candidate dataset review = **BLOCKED / WAITING FOR SOURCE DATA**
- Staging structural parity = **OPEN DRIFT**
- Staging replay = **NOT YET EXECUTABLE AS A VALID PRODUCTION-COMPATIBILITY TEST**
- Treasury ↔ COA exact mapping = **OPEN**

No `COA RECOVERY = CLOSED` claim is made.

No Production restoration is authorized.
