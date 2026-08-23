# PROMPT — HYTHAM NEXT CLOSURE UNIT
## POS WRITE-SIDE / DRIVER LEDGER / RUNTIME CONVERGENCE

Production: SMART ERP (`fiilmooggumokxanwiyx`)
Repository: `rawaie-erp-New`

### Mission
You are Hytham. Do NOT reopen Inventory. Do NOT redesign the accounting architecture from scratch.

Your next closure unit is:

**POS WRITE-SIDE DRIVER-LEDGER CONVERGENCE + DEPLOYMENT/RUNTIME/CONCURRENCY PROOF**

### Current proven boundary
The live `save_sales_invoice_atomic` currently:
- resolves company from the authenticated `public.users` identity;
- requires operation identity;
- posts Physical Stock through `post_stock_movement`;
- posts cash through `post_cash_receipt_atomic`;
- posts credit sales through `post_journal_entry`;
- posts customer credit through `post_customer_ledger_entry`;
- STILL performs a direct `driver_ledger` INSERT for Van credit.

This direct driver-ledger write is the primary remaining write-side defect in the current sales path.

### Critical company rule
The Company Identity / Financial Tenant conflict is assigned to Khalid.

Until Khalid closes it:
- do NOT change company membership;
- do NOT move COA/Treasury ownership;
- do NOT create/restore companies;
- do NOT alter Accountant/Finance Manager tenant semantics.

You may continue independently only on code/schema/runtime facts that do not depend on that Owner-level identity decision.

### Step 1 — Fresh Production proof
Query directly:
- current `save_sales_invoice_atomic`;
- current `save-sales-invoice` Edge v15;
- current `driver_ledger` schema and constraints;
- all current functions touching `driver_ledger`;
- all Edge consumers calling them;
- all PWA consumers calling `save-sales-invoice`;
- `erp_operation_registry` keys used by the sales path.

Do not infer Driver Ledger ownership from the table name.

### Step 2 — Driver Ledger contract reconstruction
Determine from Production + Git + historical sources:
- Is driver_ledger an accounting ledger, operational liability ledger, or accounting projection?
- Does it require company identity even if the table does not have company_id?
- What is the authoritative source of driver identity?
- What is the authoritative balance rule?
- What is the reversal/settlement rule?
- How does Daily Settlement interact with it?
- How do Returns/shortages interact with it?

If any answer is not proven, classify it UNKNOWN and do not invent a core contract.

### Step 3 — Surgical core design
If the contract is proven:
- create/extend the canonical Driver Ledger capability;
- preserve operation identity and idempotency;
- validate tenant/driver identity;
- lock required rows for concurrency;
- write audit evidence;
- keep the operation atomic with the originating sales event where required.

If the contract is not proven, do not implement speculative mapping. Document the exact blocker and continue with all independent runtime/lineage work.

### Step 4 — Writer convergence
The direct `driver_ledger` write inside `save_sales_invoice_atomic` must either:
- be moved into the canonical Driver Ledger core; or
- be proven as the intended surviving contract and explicitly documented.

No third path.

### Step 5 — Git/Production synchronization
PR #23 is still Draft/Open/Unmerged. Therefore:
- compare deployed `save-sales-invoice` v15 with `Current/Edge_Functions/save-sales-invoice` in main;
- compare all changes in the branch against main;
- ensure the canonical source is in an authoritative Current location;
- do not count branch-only code as Current Git truth;
- do not claim Git/Production parity until verified.

### Step 6 — Runtime verification
Perform transactional tests with rollback first.
Then, where authorized and safe, perform authenticated runtime E2E.
Prove:
- POS credit sale;
- Van credit sale;
- retry of same operation;
- driver ledger entry exactly once;
- balanced journal;
- customer ledger exactly once;
- physical stock exactly once;
- failure rollback leaves no partial financial/stock state.

### Step 7 — Two-session concurrency
After the single-session contract is proven, use independent database sessions to test:
- same operation concurrently;
- same driver concurrently;
- same sales order concurrently;
- retry race.

A sequential duplicate test is NOT concurrency proof.

### Step 8 — Scope prohibition
Do NOT modify:
- `Current/PWA/accountant.html`;
- `Current/PWA/finance-manager.html`;
- company assignments;
- COA/Treasury master data;
- unrelated Inventory logic.

Modify only the exact Current/Edge or SQL object required by this closure. If a PWA change is required, prove the consumer contract first and replace only the affected function/consumer block.

### Completion gate
Close this unit only when:
- Driver Ledger ownership is proven;
- direct writer is converged or explicitly justified as the surviving contract;
- Production RPCs and Edge are aligned;
- Current Git is synchronized with the deployed artifact;
- authenticated HTTP runtime is proven;
- two-session concurrency is proven;
- no responsibility was lost;
- full evidence is stored under `Current/CTO/`;
- final status is one of: `100% CLOSED`, `OWNER DECISION`, or `MATERIAL UNKNOWN` — never a fabricated PASS.
