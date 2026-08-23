# HYTHAM — NEXT CTO EXECUTION PROMPT V2
## Closure Unit: FINANCIAL WRITE-SIDE CONVERGENCE + DRIVER LEDGER + RUNTIME PROOF

### 0. Mission
You own the write-side financial convergence track.

Production: SMART ERP (`fiilmooggumokxanwiyx`)
Canonical live company: `00000000-0000-0000-0000-000000000001` / `الروائع` / `MAIN`
Repository: `rawaie-erp-New`

Read and obey:
`Current/CTO/20260823_MASTER_SINGLE_TENANT_REPAIR_REPLAY_DIRECTIVE.md`

### 1. Current topology rule

Production is currently a single-company environment.

Do NOT:
- create another company;
- move company ownership;
- recreate deleted tenant data;
- modify COA ownership;
- create account mappings by inference;
- alter Treasury ownership.

Khalid owns the exact 87-account forensic recovery. You may continue independent writer work only where unresolved COA/Treasury policy is not a prerequisite.

### 2. Established Core

`post_journal_entry` is deployed and proven with:
- company validation;
- active account identity;
- operation identity;
- duplicate protection;
- balanced debit/credit;
- audit;
- SECURITY DEFINER.

Do not rebuild it merely for cosmetic reasons. Verify its live definition before extending it.

### 3. Your first closure unit — Driver Ledger

The unresolved direct writer in POS/Van Credit is `driver_ledger`.

Investigate before changing it:

1. Production schema of `driver_ledger`.
2. FK / ownership structure.
3. All current writers.
4. All readers/consumers.
5. Whether it is an accounting ledger or an operational projection.
6. Company ownership semantics.
7. Operation identity semantics.
8. Balance calculation semantics.
9. Reversal/correction behavior.
10. Existing driver settlement relationships.

If the contract can be proven without Owner policy, build a dedicated Core and migrate the single writer closure-unit style:

FOUND
→ CONTRACT
→ CORE
→ STAGING/TRANSACTIONAL PROOF
→ PRODUCTION DEPLOY
→ RUNTIME VERIFY
→ CLOSE

If not proven, record the exact evidence gap; do not invent `company_id` semantics.

### 4. POS residual closure

`save_sales_invoice_atomic` already routes:
- Physical Stock → `post_stock_movement`
- Journal → `post_journal_entry`
- Cash POS → `post_cash_receipt_atomic`
- Credit customer → `post_customer_ledger_entry`

Do not rewrite this path unnecessarily.

Close only the remaining proven gaps:
- Driver Ledger;
- authenticated HTTP E2E;
- independent-session concurrency;
- Git ↔ deployed Edge lineage.

### 5. Next writers — ordered closure units

After Driver Ledger, continue:

1. `save-receipt-voucher`
2. `save-payment-voucher`
3. `save-daily-settlement`
4. remaining sales/purchase/return writers not yet converged

For Receipt/Payment/Settlement, do not finalize accounting mappings until Khalid proves the Treasury↔COA contract. You may still perform:
- consumer tracing;
- operation identity design;
- transaction-boundary design;
- staging tests with fixtures;
- direct-writer discovery;
- lineage verification.

### 6. Tenant integrity

Every financial Edge Function must derive company context from authenticated identity and fail closed.

Reject:
- hard-coded `000...001` company IDs in business logic;
- `app_settings LIMIT 1` as tenant identity;
- global tenant lookup when the request is user-scoped.

Do not change the current company topology as a workaround.

### 7. Direct-write boundary

Once consumer coverage is proven, converge direct writers to their owning Core.

Then coordinate with Khalid’s security track before removing `anon/authenticated` DML from financial tables.

Never use permissive RLS or direct table DML as an excuse for a broken Core.

### 8. Runtime proof

For every closure unit prove separately:

A. Transactional SQL proof
B. Authenticated HTTP E2E
C. Retry with same operation identity
D. Independent-session concurrency
E. Production post-state
F. Git/deployed version alignment

A SQL transaction test alone is not HTTP E2E.
A sequential retry is not concurrency proof.
A Staging PASS is not Production PASS.

### 9. Financial domain invariant

For any posted accounting event:

Business Event
→ authoritative operation identity
→ balanced journal document
→ journal lines
→ ledger projection(s)
→ treasury/cash projection where applicable
→ audit/reversal linkage

Do not allow half-posted headers with no lines in new code.

### 10. Historical repair replay

When touching an area changed by Hussin 11–45, treat the historical repair as evidence:

HISTORICAL
→ CURRENT PRODUCTION
→ CURRENT GIT
→ TARGET CONTRACT
→ keep / repair / retire

Do not blindly restore old code or old company IDs.

### 11. Scope restrictions

Do not modify:
- `Current/PWA/accountant.html`
- `Current/PWA/finance-manager.html`
- `Current/PWA/pos.html` unless a proven Consumer defect requires it
- `Current/PWA/vouchers.html`
- company master data
- COA/Treasury ownership

Prefer Core/Edge changes and preserve existing consumer contracts until a change is proven necessary.

### 12. Required closure report

For each writer, record:
- Production version;
- Git source and SHA;
- direct tables previously written;
- owning Core;
- consumer(s);
- operation identity;
- company resolution method;
- transaction boundary;
- retry behavior;
- concurrency result;
- data impact;
- runtime evidence;
- what was intentionally NOT changed;
- remaining unknown/conflicts.

### 13. Global exit gate

Do not declare Financial Write-Side CLOSED until:

`all material financial writers discovered`
+
`all required writers converged`
+
`no parallel direct journal/ledger writer remains`
+
`tenant context proven`
+
`runtime E2E proven`
+
`concurrency proven`
+
`deployment lineage proven`

Khalid’s 87-account recovery remains a separate evidence gate. Do not fabricate or bypass it.
