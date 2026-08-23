# KHALID — NEXT EXECUTION DIRECTIVE
## FINANCIAL MASTER DATA / SINGLE-TENANT RECOVERY

### Mission

Own the **financial master-data recovery** of the single live RAWAEA ERP tenant. Do not redesign UI and do not implement business writers in this assignment.

Current Production owner:

`00000000-0000-0000-0000-000000000001` / `MAIN` / `الروائع`

### What is already proven

- Only one live company remains.
- Treasury `CASH-01` has been restored exactly from Production `audit_log` into the current company.
- Original Treasury UUID and historical balances were preserved.
- `chart_of_accounts` currently has 0 rows.
- Historical retired company `da4ef704-88ac-4120-aa0e-65b92b2aa2bc` had exactly 87 chart-of-account rows.
- The 87 rows are NOT present in current row-level audit history.
- `rawaie-erp-review/PWA/main.html` exposes only a 14-row bootstrap seed and must NOT be treated as the missing 87.

### Hard prohibitions

- No synthetic 87-account tree.
- No inferred account names/codes from generic accounting practice.
- No “87 = 14 + invented 73”.
- No second live company.
- No migration of historical data by guessed account identity.
- No Current/PWA redesign.

### Required forensic sequence

1. Reconstruct every authoritative historical source that may contain the 87 exact rows.
2. Search Git commit history, blobs, migrations, seeds, deployment snapshots, and preserved Production evidence.
3. Search both `rawaie-erp-review` and `rawaie-erp-New`.
4. Compare any candidate 87-row source against the historical tenant metadata and existing financial consumers.
5. Prove parent-child relationships, account_code, account_name, account_type, normal_balance, active state, and all required IDs.
6. Determine whether the original UUIDs can be recovered. If not, design an FK-safe identity remapping only after proving every consumer that references them.
7. Identify all tables/functions that depend on account_code or account_id, including Treasury/Cash/Journals/Financial writers.
8. Build a complete migration/recovery plan that makes the single current company the sole owner of the historical financial master data.
9. Execute only after the exact source is proven.
10. Verify Production counts, hierarchy, account identity, FK integrity, consumer resolution, and application visibility.

### Required output

Produce a closure record containing:

- exact source of each restored account row;
- original identity vs new identity (if remapped);
- parent hierarchy proof;
- consumer/FK remapping proof;
- pre/post Production counts;
- reconciliation result;
- unresolved items;
- explicit declaration that no account was fabricated.

### Success gate

`87 exact historical accounts restored under MAIN` is only CLOSED when every row is source-proven and Production-verified.

Until then status = OPEN / BLOCKED BY MISSING SOURCE, never “approximately restored”.
