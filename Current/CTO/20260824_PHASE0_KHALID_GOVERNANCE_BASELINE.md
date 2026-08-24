# PHASE 0 — KHALID GOVERNANCE BASELINE

Date: 2026-08-24
Production: SMART ERP (`fiilmooggumokxanwiyx`)
Repository: `rawaie-erp-New`
Role: Financial / Governance / Evidence Baseline Owner
Status: `PHASE 0 = OPEN` pending independent Hytham baseline and final reconciliation.

## 1. Truth hierarchy

`Production runtime/database/deployed definitions > Current Git main > Current CTO/evidence records > historical/original sources > previous reports.`

Historical reports are retained as historical evidence only. They do not override a newer Production state.

## 2. Production re-baseline

Direct PostgreSQL execution timestamp:

`2026-08-24T16:05:40.448271+00:00`

| Item | Production | Status |
|---|---:|---|
| PostgreSQL | 17.6 | PRODUCTION VERIFIED |
| Companies | 1 | PRODUCTION VERIFIED |
| Users | 24 | PRODUCTION VERIFIED |
| Branches | 2 | PRODUCTION VERIFIED |
| Items | 17 | PRODUCTION VERIFIED |
| Stock rows | 20 | PRODUCTION VERIFIED |
| Inventory log | 3 | PRODUCTION VERIFIED |
| Stock vouchers | 0 | PRODUCTION VERIFIED |
| Treasury | 1 | PRODUCTION VERIFIED |
| Chart of Accounts | 0 | PRODUCTION VERIFIED |
| Journal entries | 2 | PRODUCTION VERIFIED |
| Journal lines | 0 | PRODUCTION VERIFIED |
| Customer ledger | 0 | PRODUCTION VERIFIED |
| Supplier ledger | 0 | PRODUCTION VERIFIED |
| Driver ledger | 0 | PRODUCTION VERIFIED |
| Orders | 0 | PRODUCTION VERIFIED |
| Purchase Orders | 0 | PRODUCTION VERIFIED |
| Runsheets | 0 | PRODUCTION VERIFIED |
| Latest migration | `20260824151259` | PRODUCTION VERIFIED |

Current live company:

`00000000-0000-0000-0000-000000000001` / `MAIN` / `الروائع` / active.

Current Treasury:

`0a9d9357-b5f3-4dfa-886f-7c73de4f274e` / `CASH-01` / `الخزينة الرئيسية` / active / opening 10000 / current 10000.

COA currently has zero rows.

## 3. Current Git truth

`main` HEAD:

`4a1adcee564f65f17abfa03624cd7673994e80cd`

Commit:

`Create برومبت 57`

Parent:

`819b8d1c0b72c29e640ed9ee1c7bc4b7a6f5b515`

Current `main` is therefore later than the initial Phase 0 assignment snapshot.

## 4. Current Truth Matrix

| Item | Production | Git main | Historical claim | Status |
|---|---|---|---|---|
| Company topology | exactly one live company | current main contains single-company governance | older three-company snapshots | PRODUCTION VERIFIED |
| Treasury | 1 current row, CASH-01 | recovery/governance artifacts exist | historical tenant previously owned treasury | PRODUCTION VERIFIED |
| COA | 0 rows | seeds/old docs contain smaller bootstrap sets, not exact 87 rows | historical count 87 | PRODUCTION VERIFIED / 87 RECOVERY OPEN |
| Inventory Core | post_stock_movement + reservation cores present | current inventory architecture documented | historical direct writers | PRODUCTION VERIFIED |
| Journal Core | post_journal_entry exists and is SECURITY DEFINER | canonical financial migration/source exists | older reports saying absent | PRODUCTION VERIFIED |
| Customer Ledger Core | post_customer_ledger_entry exists | current financial core artifacts present | older direct-writer era | PRODUCTION VERIFIED |
| Supplier Ledger Core | post_supplier_ledger_entry exists | current financial core artifacts present | older direct-writer era | PRODUCTION VERIFIED |
| Driver Ledger Core | post_driver_ledger_entry exists | production-aligned work exists outside closed PR #24 | earlier direct driver ledger writer | PRODUCTION VERIFIED |
| Financial Core execute privileges | service_role only for six canonical cores | security migration in main | older broader grants claim | PRODUCTION VERIFIED |
| Financial table RLS | mixed: some company-scoped, some broad legacy policies | current Git documents security closure, not full final state | older partial security claims | PRODUCTION VERIFIED |
| PR #24 | closed, unmerged, draft | branch exists, not current main | earlier report treated it as active review branch | GIT VERIFIED / HISTORICAL FOR CURRENT SOURCE |
| Main current save-sales-invoice | current file SHA `e85583546ab26af995e3237dbf07b5c6428c6301` | verified current file | older stale Current sources | GIT VERIFIED |
| Deployed save-sales-invoice | v15, deployed hash `af972338...` | source lineage is present but byte-for-byte deploy mapping is not fully closed here | earlier closure statements | PRODUCTION VERIFIED / LINEAGE OPEN |

## 5. Lineage Matrix — critical objects

| Object | Production version/state | Git path | Git revision | Deployed? | Runtime verified? | Status |
|---|---|---|---|---|---|---|
| `save-sales-invoice` Edge | v15, SHA `af972338...` | `Current/Edge_Functions/save-sales-invoice` | blob SHA `e85583546ab26af995e3237dbf07b5c6428c6301` | PRODUCTION VERIFIED | previous controlled runtime evidence exists; current live business flow unavailable because orders=0 | PRODUCTION VERIFIED / LINEAGE OPEN |
| `receive-purchase` Edge | v12, SHA `bcf5f3...` | Current financial source exists in main | main has sync commit `ed1f2e83...` | PRODUCTION VERIFIED | live business-flow proof unavailable because purchase_orders=0 | PRODUCTION VERIFIED / RUNTIME OPEN |
| `complete-return` Edge | v24, SHA `4b2b23...` | current source lineage exists | current main history | PRODUCTION VERIFIED | live business-flow proof unavailable because orders/runsheets=0 | PRODUCTION VERIFIED / RUNTIME OPEN |
| `post_journal_entry` | SECURITY DEFINER, service_role only | canonical financial-core migration/source | financial-core commits in main | PRODUCTION VERIFIED | core definition verified; authenticated HTTP proof not closed | PRODUCTION VERIFIED / RUNTIME OPEN |
| `post_customer_ledger_entry` | SECURITY DEFINER, service_role only | canonical financial-core migration/source | financial-core commits in main | PRODUCTION VERIFIED | transactional core evidence exists historically; fresh HTTP proof open | PRODUCTION VERIFIED / RUNTIME OPEN |
| `post_supplier_ledger_entry` | SECURITY DEFINER, service_role only | canonical financial-core migration/source | financial-core commits in main | PRODUCTION VERIFIED | transactional core evidence exists historically; live purchase data absent | PRODUCTION VERIFIED / RUNTIME OPEN |
| `post_driver_ledger_entry` | SECURITY DEFINER, service_role only | financial core artifacts / Hytham branch history | PR #24 is closed/unmerged | PRODUCTION VERIFIED | transactional rollback proof documented; lineage/main parity open | PRODUCTION VERIFIED / LINEAGE OPEN |
| `post_cash_receipt_atomic` | SECURITY DEFINER, service_role only | canonical financial-core migration/source | security + cash-core commits | PRODUCTION VERIFIED | authenticated HTTP proof open | PRODUCTION VERIFIED / RUNTIME OPEN |
| `post_cash_payment_atomic` | SECURITY DEFINER, service_role only | canonical financial-core migration/source | security + cash-core commits | PRODUCTION VERIFIED | authenticated HTTP proof open | PRODUCTION VERIFIED / RUNTIME OPEN |

## 6. Edge / PWA reality

Production Edge inventory currently includes large numbers of active business functions plus historical canary/harness/recovery/E2E functions. Active presence does not imply active business consumption.

Current published PWA changes are outside Phase 0 scope and were not modified.

`accountant.html` and `finance-manager.html` remain separate consumer closure units; no Phase 0 UI change is authorized.

## 7. Branch / PR governance

Relevant branch set currently includes `main`, the Hytham financial branches, CTO continuity/recovery branches, inventory rescue branches, vouchers Gold Master branches, and earlier task-specific forensic branches.

PR #24:
- state: CLOSED
- merged: false
- draft: true
- head: `heytham/20260824-financial-writer-convergence`
- head SHA: `d78b24ae4f23c95d31df08710a5ff48cffdaccf8`
- base: `main`
- classification: HISTORICAL FOR CURRENT MAIN

No claim from PR #24 is treated as current main solely because the PR exists.

## 8. Current migration truth

Production migration head is `20260824151259`.

The recent financial sequence includes:

- `20260822032213_accounting_core_post_journal_entry_and_report_join`
- `20260822182631_create_atomic_cash_receipt_payment_cores_20260822_v2`
- `20260822182713_fix_atomic_cash_cores_registry_columns_20260822`
- `20260822182733_fix_post_journal_entry_schema_drift_20260822`
- `20260823175139_financial_reporting_tenant_scope_and_runtime_fix_20260823`
- `20260823175324_pos_financial_closure_core_v1`
- `20260823175400_pos_cash_treasury_lookup_fix`
- `20260823175432_pos_cash_treasury_lookup_fix_v2`
- `20260823175537_pos_credit_zero_cogs_fix`
- `20260823185253_retire_nonactive_companies_20260823_forensic_cleanup_v2`
- `20260824144317_create_driver_ledger_core_20260824`
- `20260824144329_converge_pos_driver_ledger_20260824`
- `20260824144437_create_supplier_ledger_core_20260824`
- `20260824144450_converge_purchase_receiving_finance_20260824`
- `20260824144609_converge_return_financial_writers_20260824_v3`
- `20260824145903_20260824_restrict_financial_core_execute_privileges_v2`
- `20260824151259_20260824_canonical_financial_writer_cores`

These are PRODUCTION VERIFIED as applied migration history. Migration-to-current-main/source reproducibility remains a separate lineage gate.

## 9. Security baseline

Direct Production checks prove all six canonical financial cores have EXECUTE only for `service_role` among the tested roles.

At table/RLS level, Production remains mixed. Correct company-scoped policies coexist with broad legacy policies such as `ALL USING true` on financial tables including `cash_box`, `customer_ledger`, `daily_settlements`, `journal_entries`, `journal_lines`, `supplier_ledger`, and `treasury`.

This is an OPEN security debt item. Phase 0 performs classification only and makes no security change.

## 10. Historical / Current separation

Historical-only claims include:

- pre-cleanup multi-company topology;
- former `da4...` financial tenant ownership;
- historical counts before cleanup;
- PR #24 as an active current source;
- old statements that the current financial cores did not exist.

Current truth is the single live company and current Production function/migration/security state above.

## 11. Mandatory 87-account distinction

`EXACT 87 COA RECOVERY = OPEN`

`SOURCE EXHAUSTION = CLOSED`

No account reconstruction, synthetic UUID, parent hierarchy invention, or Treasury remapping is authorized by this baseline.

## 12. Open-state conclusion

Khalid's Phase 0 governance deliverable is complete.

The overall Phase 0 gate remains:

`OPEN`

because independent Hytham technical baseline and final Khalid/Hytham reconciliation have not yet been verified.

No functional/business changes are made by this deliverable.
