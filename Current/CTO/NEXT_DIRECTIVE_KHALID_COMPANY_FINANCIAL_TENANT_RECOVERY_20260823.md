# MASTER CTO NEXT DIRECTIVE — KHALID
## Closure Unit: COMPANY / FINANCIAL TENANT IDENTITY + FINANCIAL MASTER DATA RECOVERY

Production: SMART ERP (`fiilmooggumokxanwiyx`)
Repository: `rawaie-erp-New`

### 0. Non-negotiable rule

Do not trust any previous report, including your own Prompt-53 report, as current truth. Re-read Production first.

The current live database proves there is exactly one company now: `00000000-0000-0000-0000-000000000001`.

However, this is not yet proof that the cleanup preserved the correct financial master data.

### 1. Current proven facts

Production currently has:

- companies = 1
- users = 24
- branches = 2
- items = 17
- chart_of_accounts = 0
- treasury = 0
- cash_box = 0
- journal_entries = 2
- journal_lines = 0
- customer_ledger = 0
- supplier_ledger = 0
- driver_ledger = 0

The previous tenants were:

- `73a141bd-157a-4c2c-8693-34e21325b943`
- `da4ef704-88ac-4120-aa0e-65b92b2aa2bc`

Audit evidence proves their deletion on 2026-08-23.

### 2. Your single responsibility

Determine the authoritative canonical Financial Tenant identity and the authoritative Financial Master Data source.

Do NOT redesign any PWA.
Do NOT modify accountant.html.
Do NOT modify finance-manager.html.
Do NOT move users.
Do NOT create a second company.
Do NOT synthesize COA/Treasury data.

### 3. Forensic evidence chain

Trace and document:

1. Production company history.
2. Authentication identities and last active users.
3. `users.company_id` and `auth_id` relationships.
4. `app_settings` ownership and MAIN branch ownership.
5. Treasury ownership/history.
6. COA ownership/history.
7. Historical `CTO/BACKUP_CTO/09_PRODUCTION_OBJECT_MEMORY.md`.
8. Historical Accounting/Ledger trace files.
9. Audit log snapshots for deleted tenants.
10. Current Git and migrations containing tenant/master-data creation.
11. Current PWA/Edge consumers that encode tenant or account assumptions.
12. Any authoritative backup/snapshot/source capable of restoring the deleted 87 COA rows and Treasury.

### 4. Required decision tree

You must produce exactly one of these outcomes:

A. `000...001` is proven canonical → recover/restore required financial master data under it from authoritative source.

B. `da4...` is proven canonical → design a single-company canonicalization migration that preserves all required operational users/data without introducing a second live tenant.

C. The evidence proves a canonicalized reconstruction is required → define the exact source and exact row mapping before any mutation.

If the evidence cannot prove the identity, STOP mutation and report the exact unresolved evidence gap. Do not guess.

### 5. Financial Master Data recovery

If authoritative source is found, perform recovery only through a reversible, auditable migration.

Before mutation, capture:

- row counts;
- primary keys;
- unique keys;
- FK dependencies;
- account codes/names;
- treasury identity;
- app_settings dependencies;
- consumer dependencies.

After mutation prove:

- one company only;
- all required master data belongs to that company;
- no orphaned references;
- no duplicate account codes inside the canonical contract;
- treasury↔COA identity is explicit;
- existing Cores can resolve their required identities;
- audit trail records the canonicalization.

### 6. Production safety

Any experiment must be transactionally reversible.

No permanent Production mutation without:

THEORETICAL
→ STAGING VERIFIED
→ PRODUCTION DEPLOYED
→ PRODUCTION RUNTIME VERIFIED
→ CLOSURE

### 7. Deliverable

Create/update a Current/CTO forensic report containing:

- Truth hierarchy
- Evidence matrix
- Company identity verdict
- Deleted-data classification
- Master-data recovery source
- Exact mapping
- Risks
- Tests
- Production verification
- Unknowns
- Conflicts
- Final closure status

Your task is CLOSED only when the canonical company identity and the required Financial Master Data source are proven. Otherwise keep it OPEN explicitly.
