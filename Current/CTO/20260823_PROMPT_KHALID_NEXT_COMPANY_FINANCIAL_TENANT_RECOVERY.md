# PROMPT — KHALID NEXT CLOSURE UNIT
## COMPANY / FINANCIAL TENANT FORENSIC RECOVERY

Production: SMART ERP (`fiilmooggumokxanwiyx`)
Repository: `rawaie-erp-New`

### Mission
You are Khalid. Your next closure unit is NOT a new reporting UI and NOT a return to Inventory.

Your mission is to resolve the **Company / Financial Tenant Identity Conflict** created by the historical split between:
- `00000000-0000-0000-0000-000000000001` — operationally active user tenant;
- `da4ef704-88ac-4120-aa0e-65b92b2aa2bc` — historically proven financial/experimental tenant.

The current Production database now contains only `000...001` because the owner-requested consolidation was executed. This current state is NOT yet semantically certified because historical production-object memory and financial evidence identify `da4e...` as the official active/experimental financial tenant.

### Non-negotiable source hierarchy
1. Current Production DB/runtime/Auth/Edge/logs.
2. Current Git main.
3. Current CTO/evidence records.
4. Historical Production memory / migration history / Git history.
5. Old reports/prompts.

### Mandatory first phase: reconstruction, not repair
Before any data recreation or reassignment:

1. Capture a fresh Production snapshot.
2. Capture current Git HEAD and current Production migration head.
3. Reconstruct every historical reference to both company IDs.
4. Trace `auth.users → public.users → company_id` consumers.
5. Trace `app_settings.main_branch_id` ownership historically and currently.
6. Trace the financial domain owner: Treasury, COA, cash accounts, customers, suppliers, journal entries, financial report consumers.
7. Trace the official experimental vehicle/mobile branch/test representative.
8. Inspect migration `20260821023255` and all surrounding cleanup evidence from direct source/history to determine what was intended to be removed at that stage.
9. Inspect audit_log snapshots for recoverable tenant rows.
10. Determine whether the intended single experimental company was `000...001` or `da4e...`.

### Prohibited actions
- Do NOT invent COA accounts.
- Do NOT invent Treasury rows.
- Do NOT create a replacement company ID.
- Do NOT move users between companies.
- Do NOT restore data from memory.
- Do NOT use a historical report as proof of current ownership.
- Do NOT modify PWA files in this closure unit.

### Recovery rule
If the evidence proves `da4e...` was the intended experimental company, build an exact recovery plan from recoverable Production/Git/audit evidence. Recreate only data that can be proven exact. For any missing non-reconstructible historical data, classify it explicitly as LOSS / NOT RECOVERABLE and stop before synthetic replacement.

If the evidence proves `000...001` was the intended experimental company, then keep the current one-company state and build the exact financial-master-data remediation required for that tenant, but only from proven source data.

### Financial tenant contract
Close the following or explicitly mark Owner Decision:
- Treasury owner
- COA owner
- cash-account UUID
- sales/revenue account UUID
- COGS account UUID
- inventory account UUID
- receipt/payment account semantics
- financial report tenant
- Accountant/POS consumer tenant

### Deployment lineage
Build the exact matrix:
`Git artifact → migration → Production definition → Edge version → PWA consumer → runtime verification`

At minimum include:
- financial reporting RPCs;
- `post_journal_entry`;
- `post_cash_receipt_atomic`;
- `post_cash_payment_atomic`;
- `post_customer_ledger_entry`;
- `save-sales-invoice` v15;
- `save-receipt-voucher`;
- `save-payment-voucher`;
- `save-daily-settlement`;
- `update-driver-ledger`.

### Completion gate
Do NOT declare closure until:
- company identity is proven;
- no contradictory material evidence remains;
- required financial master data ownership is proven;
- any recovery is exact or explicitly bounded as unrecoverable;
- Current Git/Production drift for this closure is identified;
- all findings are documented in `Current/CTO/`;
- no PWA change was made without a proven consumer contract.
