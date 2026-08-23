# RAWAEA ERP — FINAL FORENSIC REBASELINE
## Khalid / Hytham / Company Identity / Financial Master Data

Date: 2026-08-23
Production: SMART ERP (`fiilmooggumokxanwiyx`)
Repository: `rawaie-erp-New`

## 1. Truth hierarchy

Production runtime/database/deployed Edge definitions > Current Git > Current CTO/evidence records > historical/original sources > previous reports.

A historical closure statement is not current truth until re-proven against the live Production state.

## 2. Historical chain finding

The Hussin Prompt 11–45 sequence is an evolution/audit trail, not a live source of truth. It contains repeated corrections around voucher semantics, owner/permission semantics, auth identity, tenant isolation, inventory centralization, item identity, vehicle/mobile branch semantics, PWA consumer binding, and DirectSale target-stock behavior.

Prompt 49 and later governance directives establish the closure gate: no material unknown, conflict, unverified claim, unresolved Production/Git drift, lost responsibility, unclassified consumer, or unproven critical runtime path may be silently promoted to CLOSED.

## 3. Current Production — company topology

Direct Production verification on 2026-08-23 proves:

- `public.companies = 1`.
- The only surviving company is `00000000-0000-0000-0000-000000000001` (`الروائع`, `MAIN`, active).
- `users_without_company = 0`.
- `users_with_old_company = 0`.
- `branch_company_mismatch = 0`.
- `inventory_log_company_item_mismatch = 0`.
- `order_detail_company_item_mismatch = 0`.
- No current public rows remain under the old company IDs `73a...` and `da4...`.

Therefore the live tenant topology is now a single-company Production environment.

## 4. CRITICAL — this was retirement/deletion, not a data merge

The 2026-08-23 cleanup did not merge the old tenants' data into the surviving tenant.

The audit trail records deletion of:

- company `73a...`: 31 items, 10 suppliers, 1 customer, no branches/COA/treasury.
- company `da4...`: 2 items, 3 branches, 9 customers, 87 chart-of-accounts rows, 1 treasury, 1 operation-registry row.
- 33 items, 10 customers, 10 suppliers, and 1 treasury are explicitly represented as delete events in `audit_log`.
- The deleted companies themselves are recorded with the reason `Owner-directed consolidation to the single active Production tenant` and `kept_company_id = 000...001`.

However, `chart_of_accounts` and some cascaded tenant data do not have row-by-row audit snapshots sufficient to reconstruct the original 87 accounts.

Therefore:

**Single-company topology = CLOSED.**

**Complete historical-data merge/preservation = NOT PROVEN.**

Deleted data must not be recreated from memory or guessed values. Any recovery must use authoritative backup/source evidence.

## 5. CRITICAL — current financial master-data state

Direct Production verification now shows:

- `chart_of_accounts = 0`
- `active chart_of_accounts = 0`
- `treasury = 0`
- `active treasury = 0`
- `cash_box = 0`
- `journal_entries = 2`
- `journal_lines = 0`
- `customer_ledger = 0`
- `supplier_ledger = 0`
- `driver_ledger = 0`

This is a material live-system state gap. The financial cores are architecturally present, but the retained tenant has no Financial Master Data on which those cores can operate.

No synthetic COA, Treasury, Cash Box, customer, supplier, or accounting data has been created.

## 6. Company Identity remains a forensic closure unit

Historical evidence identifies `da4...` as the former financial/experimental tenant with 87 COA rows and a Treasury, while runtime activity strongly identifies `000...001` as the currently active operational tenant.

The owner requirement of one experimental company is clear. What is not yet proven is whether the intended canonical identity was the surviving `000...001`, the former `da4...`, or a specific canonicalized record assembled from both.

No user/company reassignment or master-data reconstruction should occur until this semantic identity is proven from authoritative evidence.

## 7. Khalid assessment

Khalid's work is directionally correct and appropriately conservative.

Strengths:
- strong historical/architectural continuity;
- correct use of Closure Units;
- correct refusal to guess Treasury/COA identity;
- surgically aligned `finance-manager.html` rather than rewriting the file;
- correct decision not to modify `accountant.html` before its Financial Consumer Contract is proven.

Current limitation:
- his Prompt-53 company/financial-tenant snapshot is now historical;
- the live one-company topology supersedes the old three-company snapshot;
- Financial Master Data is now missing from the surviving tenant;
- therefore his next task is Company/Financial Tenant Identity Recovery + Financial Master Data Canonicalization, not UI redesign.

## 8. Hytham assessment

Hytham's work is technically strong and evidence-backed.

Confirmed strengths:
- `post_journal_entry` is deployed as a SECURITY DEFINER Core;
- `post_cash_receipt_atomic` exists;
- `post_cash_payment_atomic` exists;
- `post_customer_ledger_entry` exists;
- POS inventory remains centralized through `post_stock_movement`;
- operation identity/idempotency and transactional tests were treated seriously;
- he correctly refused to invent Treasury/COA mappings;
- he correctly left `Driver Ledger`, authenticated HTTP E2E, and two-session concurrency open.

Current limitation:
- PR #23 is still Draft/Open/Unmerged;
- Git main is therefore not identical to the deployed Production Edge source;
- direct financial writers still exist in Production outside the central cores;
- `receive_purchase_atomic` directly writes journal and supplier ledger;
- `complete_return_atomic` directly writes journal and customer ledger;
- `save_sales_invoice_atomic` still directly writes `driver_ledger` for Van Credit;
- `save-receipt-voucher`, `save-payment-voucher`, and `save-daily-settlement` remain legacy direct-write consumers.

Therefore Financial Writer Convergence is still OPEN.

## 9. Direct writer scan — current live Production

Current PostgreSQL function scan confirms direct financial writes remain in:

- `receive_purchase_atomic` → `journal_entries`, `journal_lines`, `supplier_ledger`
- `complete_return_atomic` → `journal_entries`, `journal_lines`, `customer_ledger`
- `save_sales_invoice_atomic` → `driver_ledger`

The canonical cores themselves are intentionally allowed to write their authoritative target tables.

## 10. Decisions that are CORRECT and should be preserved

1. Do not invent Treasury → COA mappings.
2. Do not patch `accountant.html` until its UUID-based Financial Consumer Contract is proven.
3. Do not change `pos.html` without a proven Consumer defect.
4. Do not call a Production deployment CLOSED because a report says so.
5. Do not restore deleted financial master data from memory.
6. Do not create a second company merely to recover missing finance data.
7. Do not let Inventory re-enter as a separate parallel project; Inventory is the established physical-stock foundation for the next ERP layer.

## 11. Required next closure order

### Khalid

**COMPANY / FINANCIAL TENANT IDENTITY RECOVERY**

then:

**FINANCIAL MASTER DATA CANONICALIZATION**

then:

**TREASURY ↔ COA CONTRACT + DEPLOYMENT LINEAGE + FINANCIAL CONSUMER MATRIX**

No PWA redesign is authorized until these are proven.

### Hytham

**WRITE-SIDE FINANCIAL CONVERGENCE**

starting with:

1. live Edge/Git lineage for `save-sales-invoice`;
2. Driver Ledger contract and Core design evidence;
3. authenticated HTTP E2E;
4. independent-session concurrency proof;
5. only then, and only after company identity/master-data contract is settled, converge the remaining financial writers one closure unit at a time.

Hytham must not alter company membership, COA ownership, Treasury ownership, or `accountant.html` during this closure.

## 12. Final status

| Area | Status |
|---|---|
| Single-company live topology | CLOSED |
| Historical old-company data fully merged | NOT PROVEN |
| Financial Master Data availability | BLOCKED / OPEN |
| Inventory physical-stock centralization | FOUNDATION ESTABLISHED |
| Accounting Core | DEPLOYED |
| Cash Receipt/Payment Cores | DEPLOYED |
| POS full financial convergence | OPEN |
| Supplier Ledger Core | OPEN |
| Driver Ledger Core | OPEN |
| Financial Writer Zero-Debt | OPEN |
| Financial Consumer Matrix | OPEN |
| Deployment Lineage | OPEN |
| Concurrency Proof | OPEN |
| Global Zero-Debt | OPEN |
| Autonomous CTO Readiness | NO |

## 13. Non-negotiable forensic conclusion

The correct current statement is NOT:

> "The three companies were merged successfully and finance is ready."

The correct statement is:

> "Production now contains one company only, but the previous financial tenant's master data was retired/deleted rather than proven merged. The surviving tenant currently has no COA/Treasury/Cash Box master data. Financial identity and master-data recovery are therefore the next blocking forensic closure units."

No synthetic recovery is authorized.
