# KHALID — NEXT CTO EXECUTION PROMPT V2
## Closure Unit: COMPANY IDENTITY + EXACT 87 COA RECOVERY + TREASURY/COA CONTRACT

### 0. Mission
You own the forensic recovery of the financial master-data layer for the single live RAWAEA ERP tenant.

Production: SMART ERP (`fiilmooggumokxanwiyx`)
Canonical live company: `00000000-0000-0000-0000-000000000001` / `الروائع` / `MAIN`
Repository: `rawaie-erp-New`

Read and obey:
`Current/CTO/20260823_MASTER_SINGLE_TENANT_REPAIR_REPLAY_DIRECTIVE.md`

### 1. Current Production truth — re-read it yourself before doing anything

Do not trust this prompt as a substitute for the database.

At the current checkpoint, Production proves:
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

Treasury already present:
- UUID `0a9d9357-b5f3-4dfa-886f-7c73de4f274e`
- `CASH-01`
- `الخزينة الرئيسية`
- `Cash`
- opening/current = `10000`
- company = `000...001`

Do not create another treasury row.

### 2. Critical mission — recover the exact 87 historical accounts

The retired tenant is proven to have had exactly 87 COA rows.

You are forbidden to manufacture them.

The following are NOT acceptable evidence for the exact 87:
- the 14-account application bootstrap;
- generic accounting charts;
- inferred subaccounts;
- guessed account codes/names;
- screenshots without row-level identity;
- previous reports that only state “87”;
- model memory.

### 3. Forensic source hunt

Search all authoritative candidates:

A. Git history
- `rawaie-erp-New` full history before the 2026-08-23 tenant retirement;
- commits, trees, blobs, deleted files, migrations and seed data;
- search both the active branch and historical commits.

B. Historical repository
- `rawaie-erp-review` full history, especially Original/Current/PWA/main.html and any SQL/seed files.

C. Backup / continuity pack
- `CTO/BACKUP_CTO/*`
- production-object memory
- accounting/ledger source traces
- production snapshots
- task ledgers
- any preserved JSON/CSV/SQL exports.

D. Current Git evidence
Search for:
- account codes/names;
- chart_of_accounts inserts;
- historical UUIDs;
- account hierarchy exports;
- treasury links;
- financial consumer mappings.

E. Production forensic evidence
Inspect:
- audit_log;
- database functions referencing chart_of_accounts;
- information_schema foreign keys;
- operation registries;
- any remaining historical artifacts capable of exposing exact row identity.

### 4. Required proof for every account row

For each of the 87, prove:
- original UUID, if available;
- company ownership at source;
- account_code;
- account_name;
- account_type;
- parent_account_id / parent code;
- normal_balance;
- active state;
- notes where material;
- source artifact and exact location;
- confidence label.

If the original UUIDs are unavailable, do not silently remap them. First enumerate every FK consumer and prove a safe deterministic remapping strategy.

### 5. Treasury ↔ COA

Do not infer `CASH-01 → 121` or any other mapping.

Prove the intended mapping from source evidence and current consumer contracts.

The Treasury row is already present in the canonical company. Preserve its identity and balance unless direct evidence proves correction is required.

### 6. Historical repair replay

For every previous financial repair you encounter:

`historical change`
→ `current Production verification`
→ `current Git verification`
→ `still-required?`
→ `tenant-safe under 000...001?`
→ `reapply / preserve / reject`

Do not replay old company IDs.
Do not recreate deleted tenant data merely because an old report says it existed.

### 7. Database mutation gate

Do NOT mutate Production until the exact 87-row source is proven.

Once proven, recovery must be:
- transactional;
- reversible;
- auditable;
- FK-safe;
- company-scoped;
- idempotent;
- accompanied by before/after counts and row-level verification.

### 8. Required final evidence

Create/update a `Current/CTO/` closure record containing:
- exact source artifact for every row;
- original UUID/new UUID mapping;
- hierarchy proof;
- Treasury↔COA proof;
- FK dependency matrix;
- pre/post Production counts;
- audit entries;
- application consumer resolution;
- unresolved items;
- explicit “no fabricated account” statement.

### 9. Exit gate

CLOSE only if:

`87 exact historical accounts`
+
`all row identities proven`
+
`correct canonical company ownership`
+
`parent hierarchy proven`
+
`FK integrity proven`
+
`Treasury contract proven`
+
`Production runtime verified`

Otherwise remain:
`OPEN / BLOCKED BY MISSING AUTHORITATIVE SOURCE`

### 10. Prohibited scope

Do not modify:
- `Current/PWA/accountant.html`
- `Current/PWA/finance-manager.html`
- POS
- Inventory architecture
- unrelated Edge writers

Only make a Production or Current source change when this closure unit proves it is necessary.
