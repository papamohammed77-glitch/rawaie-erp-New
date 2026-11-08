# Report644 — Employee Cash Custody UI Integration, Surgical Runtime Corrections & Production Readiness
**Date:** 2026-11-08 (Africa/Cairo)  
**Checkpoint:** LVE-2026-11-08-644  
**Previous checkpoint:** LVE-2026-11-08-643  
**Scope:** Parent Finance, Buyer, shared Core employee-custody service, Delivery Driver employee self-service, SMART ERP Production contract revalidation, source syntax validation, Cloudflare deployment evidence.  
**Execution target:** erp-frontend/main and existing SMART ERP Production fiilmooggumokxanwiyx.  
**Change policy:** Direct-main surgical edits only; no staging project, no Git branch, no duplicate application, no new Edge Function, and no permanent database change in this cycle.

---

## 1. Executive result

The employee cash-custody UI integration already present in the live operational repository was revalidated against LVE643 findings and current SMART ERP Production contracts. The integration spans four operational files:

- companies/company-1/main.html: Finance custody subledger tab and Expense-only account dropdown.
- companies/company-1/purchasing/buyer.html: mandatory branch selection and same-branch Cash/non-POS Treasury filtering for issue, advance and settlement.
- companies/company-1/core.js: opt-in RW_EmployeeCustody self-service service using the authenticated employee profile, self-scoped RLS reads, existing ownership-checked RPCs and the private employee-documents bucket.
- companies/company-1/delivery/driver.html: a separate “عهدتي” cash-custody tab; existing “رصيدي” and vehicle-stock meanings remain distinct.

A surgical runtime race defect was then found in the integration: asynchronous custody rendering could overwrite a different tab after the user navigated away. This was corrected in Parent Finance and Driver, syntax-checked, and committed directly to main.

**Code status: INTEGRATED IN GITHUB MAIN — SOURCE SYNTAX PASS.**  
**Production runtime status: READY WITH LIMITATIONS.** Cloudflare dashboard evidence read during this cycle still showed the previous source commit 038a7bd, not the latest custody correction commit. Authenticated employee/Finance browser E2E, real JWT RLS self-vs-other proof, Realtime event delivery and full field workflow remain UNVERIFIED. Do not describe the feature as field-ready or fully deployed until those gates pass.

No SQL, table, RLS, ACL, Edge Function, treasury, journal, inventory, supplier balance, cash-box, storage object or QA-fixture write was made in this cycle.

## 2. Historical continuity and provenance

### 2.1 LVE643 baseline

LVE643 confirmed the permanent Report641 database ChangeSet was live and fingerprint-matched. It also identified the remaining UI and operational gaps: Parent Finance had no custody tab; Buyer Treasury selectors were too broad; ordinary employees had no self-service UI; and authenticated E2E was outstanding.

### 2.2 Existing integration commit

The operational history contains:

- 180d318d3be8d095daab557207d037aa87147267 — feat(custody): integrate employee cash custody across finance, buyer and driver.
- Its exact changed-file comparison against LVE643's previous operational HEAD b728c09e1bb4c482effc48a492546b393ff02c1f is four files only:
  - core.js: +84 / -1
  - driver.html: +31 / -16
  - main.html: +47 / -1
  - buyer.html: +72 / -33

The commit is the source of the integrated UI/service layer described in this report. It did not introduce a parallel ledger or a new Edge Function.

### 2.3 Surgical correction performed in this cycle

Commit:

68de9bfb6213d6ac7f975bff0aea76e14a1f874d  
Message: fix(custody): prevent stale employee and finance custody renders

Only these two files changed:

- companies/company-1/main.html
- companies/company-1/delivery/driver.html

A later repository commit 121c856508122e5b1f1008453526a2aece47f83a was independently compared with 68de9b. Its only changed path is _forensic_current_main_extract.md; it does not alter the four operational applications. Thus the latest observed repository HEAD is 121c856508122e5b1f1008453526a2aece47f83a, with the custody code correction preserved in its ancestry.

## 3. Surgical defect and exact correction

### 3.1 Parent Finance race

**Root cause:** RW_Finance_Custody.render() starts asynchronous data loading. If the user changes Finance sub-tabs before the request resolves, the old callback can write into the shared finance-content element belonging to the newly selected tab. In addition, concurrent initial renderSubTab() requests can complete out of order while _loadAllData() is still loading.

**Correction in main.html:**
1. Added a monotonically increasing Finance sub-tab request serial.
2. A callback returns without rendering if it is no longer the latest requested sub-tab.
3. Leaving employee-custody calls the custody module's stop/cancel method.
4. The custody renderer now has its own render serial; stale success and error callbacks are ignored.
5. The module exposes stop() to invalidate an in-flight render without changing database state.

**Impact:** A delayed custody read can no longer replace the user's currently selected Finance screen. No finance RPC, accounting logic, payment writer or database contract was changed.

### 3.2 Delivery Driver race

**Root cause:** RW_EmployeeCustody subscribes to custody Realtime events and periodically reconciles. Its renderer targets the shared mainContent element. Without stopping the module when leaving the custody tab, a later event/reconciliation could redraw custody over Dashboard, Orders, Map, Stock, Balance or Account.

**Correction in driver.html:**
- App.switchTab() now calls RW_EmployeeCustody.stop() whenever the selected tab is not cash-custody.
- The existing logout path also stops the service.
- The service's serial counter invalidates any in-flight load after stop.

**Impact:** Cash-custody rendering and its Realtime subscription are opt-in to the active tab. “رصيدي” and vehicle merchandise custody are not merged with monetary custody.

## 4. Current source inventory and hashes

Latest verified operational source blobs after the correction:

| File | Blob SHA |
|---|---|
| companies/company-1/main.html | 5a4aacf5af8100db6e3c434c49fea57784857594 |
| companies/company-1/core.js | 2d11b852862c523fc89e6a8b9c510462bb65cc4e |
| companies/company-1/purchasing/buyer.html | 2fd152a29b01dc355ffd7c5917efbf9a804f3d3f |
| companies/company-1/delivery/driver.html | 2a617e881ce61171f0aed01e8539e848e13e14e6 |

The latest observed repository HEAD is 121c856508122e5b1f1008453526a2aece47f83a. The latest operational code commit is 68de9bfb6213d6ac7f975bff0aea76e14a1f874d.

## 5. Application and integration review

### 5.1 Parent Finance

The new “عهد الموظفين” tab is a dedicated subledger, not a generic expense voucher and not a new GL account per employee.

- Finance reads and management actions remain on the existing restricted save-purchase-order Edge route.
- Issue, add-advance, expense review and settlement use their existing custody operations.
- The generic سند الصرف account dropdown now filters to account_type='expense'.
- The 13-argument finance_save_expense server-side Expense guard remains authoritative; the unchanged 14-argument branch wrapper delegates to it.
- Employee custody issue is not implemented through finance_save_expense.
- The UI presents the employee and branch analytical subledger under control account 127.

### 5.2 Buyer

The Buyer Treasury selector helper accepts only:
- active Treasury rows;
- type='Cash';
- branch_id equal to the custody branch;
- account codes not beginning POS-.

The issue modal requires a branch and refreshes eligible Treasury options when the branch changes. Additional advances and cash-return settlement use the same branch-specific filter and reject an empty eligible list before submission.

The backend RPC checks remain in place; UI filtering is an early usability guard, not a replacement for server validation. Buyer money custody remains separate from Buyer goods custody, vehicle stock and supplier purchase/return flows.

### 5.3 Shared Core employee self-service

RW_EmployeeCustody is a shared service in core.js, but it is not auto-mounted in every application. The Driver app explicitly invokes it from its separate cash-custody tab.

Identity is obtained from RW_Auth, which hydrates the effective public employee profile using get_my_effective_profile. The service requires both users.id and company_id; it does not search by email or create a missing employee row.

Employee reads use authenticated PostgREST queries with explicit company and employee filters, and rely on the existing RLS policies as the security boundary. Employee actions call only the existing self-ownership-checked acknowledgement and operational-expense submission RPCs. The employee does not receive Finance issue, review, approval or settlement capability.

Expense evidence is uploaded to the existing private employee-documents bucket using the company/user/custody path. Document viewing uses a short-lived signed URL. The bucket is not made public.

### 5.4 Delivery Driver

The new cash tab is distinct from:
- “السيارة” — vehicle merchandise/stock;
- “رصيدي” — the pre-existing driver balance workflow;
- “عهدتي” — monetary employee custody.

The login flow now uses the verified effective profile and company scope. It no longer inserts a missing users record as a login side effect. Existing delivery permission checks are evaluated against the hydrated effective profile.

## 6. Live SMART ERP Production contract revalidation

Project: fiilmooggumokxanwiyx.

The live database signatures inspected during this cycle match the direct UI/RPC call contracts:

| RPC | Live identity arguments |
|---|---|
| buyer_custody_acknowledge_atomic | p_company_id uuid, p_custody_id uuid |
| buyer_custody_acknowledge_advance_atomic | p_company_id uuid, p_advance_id uuid |
| buyer_custody_submit_other_expense_atomic | p_company_id uuid, p_custody_id uuid, p_expense_date date, p_expense_category text, p_expense_reference text, p_description text, p_amount numeric, p_currency text, p_document_name text, p_document_path text, p_mime_type text, p_operation_id text |
| buyer_custody_issue_atomic | p_company_id uuid, p_employee_id uuid, p_branch_id uuid, p_treasury_id uuid, p_purpose text, p_currency text, p_amount numeric, p_issued_date date, p_received_reference text, p_notes text, p_operation_id text |
| buyer_custody_add_advance_atomic | p_company_id uuid, p_custody_id uuid, p_treasury_id uuid, p_amount numeric, p_advance_date date, p_reference text, p_notes text, p_operation_id text |
| buyer_custody_settle_atomic | p_company_id uuid, p_custody_id uuid, p_treasury_id uuid, p_cash_returned numeric, p_finance_reference text, p_notes text |

For the inspected custody RPC signatures:
- owner remains postgres;
- functions remain SECURITY DEFINER;
- anon EXECUTE=false;
- authenticated EXECUTE=true.

The SECURITY DEFINER warning from Supabase Advisors must be read in context: authenticated execution is required by this design, and the functions contain their own identity, company, branch, Finance permission or employee-ownership checks. This report does not authorize broadening grants or weakening those checks.

### 6.1 RLS evidence

Current policies for the five custody tables are scoped to authenticated users and current company. The employee branch of each read predicate resolves the current Auth user through users.auth_id=auth.uid() and compares that public users.id with the custody employee_id. Finance and Finance Manager effective permissions are the only additional read path. Payments and settlements are scoped through the owning custody row.

No employee direct INSERT/UPDATE path was added. The existing RPCs remain the write boundary.

### 6.2 Existing business-effect contract

- Issue/advance registration creates a pending employee acknowledgement; it is not yet a cash payment.
- The employee acknowledgement RPC posts the actual cash payment and Dr 127 / Cr 121 exactly once.
- Submitting an operational expense creates a pending claim and document; it does not create an expense journal or another cash movement.
- Finance approval posts Dr the selected valid Expense account / Cr 127.
- Physical cash return posts Dr 121 / Cr 127 through the existing settlement RPC.
- No payroll deduction, employee payable, stock movement, supplier payable or inventory movement is created by a generic operational-expense submission.

### 6.3 Additional advances and settlement amount

The current buyer_custody_add_advance_atomic increments buyer_custodies.issued_amount when the additional advance is registered. Settlement blocks while any advance is unacknowledged. Therefore the existing settlement RPC's issued_amount - approved expenses reconciliation includes acknowledged additional advances; the Buyer and Parent settlement screens use that same accumulated issued_amount. This was checked directly to avoid incorrectly changing settlement arithmetic.

## 7. Live business-data baseline

The five cash-custody tables currently return zero rows:

| Table | Current rows |
|---|---:|
| buyer_custodies | 0 |
| buyer_custody_advances | 0 |
| buyer_custody_expenses | 0 |
| buyer_custody_payments | 0 |
| buyer_custody_settlements | 0 |

No QA fixture or test transaction was created by this cycle.

Treasury snapshot remains:
- CASH-01 central/unassigned Cash: 10,685 EGP — excluded from branch custody.
- BR-01 branch Cash tills: active, each 0 EGP — no operational funding available.
- BR-01 POS: 190 EGP — excluded from custody.
- BR-2 Alexandria: no active Cash Treasury was present in the prior verified inventory.

**Operational blocker:** the UI correctly refuses to offer an unfunded or non-eligible branch Treasury. Do not bypass this with central CASH-01 or POS. BR-01 must receive an authorized, documented Treasury transfer. BR-2 requires a valid branch Cash Treasury and funding before it can issue or settle cash custody.

No active eligible Expense leaf for transport/fuel/tolls was identified in LVE643. Finance must configure the proper Expense leaf before operational expense approval can post. Do not substitute Cost of Sales (51) or inventory differences/waste (52).

## 8. Validation performed

### PASS
- Re-read LVE643 and its source evidence; reconciled the current branch history.
- Compared the integration commit against the LVE643 source baseline; the four-file scope is explicit.
- Re-read the exact main/driver blobs, made only the two race-correction edits, and committed them directly to main.
- Compiled every inline JavaScript block in the updated main.html and driver.html using a JavaScript parser (new Function) — both files passed.
- Re-fetched the new main and driver blobs after commit and repeated the syntax compilation — PASS.
- Compared HEAD 68de9b to the later HEAD 121c856; the later commit changes only the forensic extract file.
- Rechecked the live custody RPC signatures, function security attributes and grants.
- Rechecked the five custody table counts and current Treasury balances.

### NOT RUN / UNVERIFIED
- Authenticated Driver browser E2E using a real ordinary employee JWT.
- Independent employee-A vs employee-B RLS self/other test under separate authenticated sessions.
- Real employee ACK followed by exact cash_box/GL/treasury delta proof.
- Operational expense upload/submission, Finance review and approved Expense posting.
- Physical cash return and full custody settlement E2E.
- Realtime subscription status, event delivery, reconnect and measured latency.
- Multi-device/field workflow and mobile viewport usability.
- Successful Cloudflare Production deployment of the latest 68de9b source.

No credentials were requested or exposed, no real employee was impersonated, and no synthetic business rows were committed merely to claim an E2E pass.

## 9. Supabase Advisor snapshot

The current project-wide Advisor response includes existing broad findings, including:
- RLS-enabled tables without policies;
- public SECURITY DEFINER functions callable by anon for public storefront catalog/tracking use cases;
- many authenticated SECURITY DEFINER functions, including the custody RPCs;
- multiple permissive policies and duplicate/unused indexes.

These are project-wide findings and were not introduced by the HTML-only correction. The custody RPCs inspected here deny anon execution and retain their explicit in-function authorization checks. Do not bulk-change unrelated policies, grants or indexes under this task. A separate scoped security remediation plan should classify each finding by exposure, intended API surface and compensating authorization before any DB change.

## 10. Cloudflare deployment evidence

The Cloudflare dashboard tab read during this cycle still showed Production main at commit 038a7bd5261f29c127eb0eaaecef8944b87370b9 and deployment URL https://95ab0057.rawaea-erp.pages.dev/. The operational source now includes 68de9bfb6213d6ac7f975bff0aea76e14a1f874d and later a forensic-only commit 121c856508122e5b1f1008453526a2aece47f83a.

The dashboard snapshot was not refreshed after the latest push, and no deployment record for 68de9b was visible in the retrieved page. Therefore source-to-deployment parity for the latest custody UI correction is **NOT CONFIRMED**. Do not claim Cloudflare has deployed the fix until the dashboard shows the matching source commit and a successful deployment, followed by runtime route verification.

## 11. Risk register and readiness

| Priority | Item | Current state | Required action |
|---|---|---|---|
| P1 | Cloudflare latest source parity | UNVERIFIED / dashboard snapshot still showed 038a | Verify a successful deployment containing 68de9b or later |
| P1 | Branch Treasury funding | BR-01 Cash tills 0; BR-2 Cash Treasury absent | Authorized branch Treasury setup/funding; no central/POS workaround |
| P1 | Expense account for fuel/transport/tolls | No eligible Expense leaf identified | Finance configures the correct Expense leaf |
| P1 | Authenticated employee/Finance E2E | UNVERIFIED | Run with real authorized test sessions and removable tagged QA records |
| P2 | Realtime delivery/reconnect | Code integrated; runtime unverified | Measure event, reconnect and 30-second reconciliation behavior |
| P2 | Global Advisor findings | Broad project-wide warnings | Separate risk-based remediation plan; do not mix into this change |

**Readiness: READY WITH LIMITATIONS — UI integration and surgical source corrections are in GitHub main; Production business readiness and deployment parity are not yet proven.**

## 12. Next execution sequence

1. Verify Cloudflare Production deployment source includes commit 68de9b or a later descendant; confirm successful status and open the deployed Parent, Buyer and Driver routes.
2. Use an authorized ordinary employee session to verify profile hydration, own-custody reads, no access to another employee's custody, initial acknowledgement and additional-advance acknowledgement.
3. Verify no posting before employee acknowledgement and exactly one cash/GL posting after acknowledgement; retry the same operation and verify no duplicate movement.
4. Submit a tagged operational expense with a private attachment; prove it remains pending with no GL/cash posting.
5. After Finance configures a valid Expense leaf, approve once and reconcile Dr Expense / Cr 127.
6. Receive actual returned cash into the same-branch Cash Treasury, settle once, and reconcile Treasury, cash_box, journal and subledger.
7. Measure Realtime and periodic reconciliation behavior. Clean all tagged QA records, files and permitted dependent records; prove post-cleanup counts and balances equal baseline.
8. Do not create a branch Cash Treasury, transfer funds, or configure a new Expense leaf without the appropriate authorized Finance/Treasury action.

## 13. Change and rollback record

- Operational source commit containing integration: 180d318d3be8d095daab557207d037aa87147267.
- Operational source correction commit: 68de9bfb6213d6ac7f975bff0aea76e14a1f874d.
- Latest observed operational HEAD: 121c856508122e5b1f1008453526a2aece47f83a (forensic extract only after the correction).
- Files changed by the correction: Parent main.html and Delivery driver.html only.
- No database migration, DDL, RPC replacement, RLS/ACL change, Edge deployment, treasury movement, journal entry, inventory movement or test data was created.

Rollback is limited to reverting commit 68de9b after reviewing the current source and confirming no later edits depend on its render guards. The broader integration commit 180d318 must not be reverted wholesale as a shortcut; any rollback of its four-file feature requires a separate impact review. No accounting reversal is needed because this cycle created no financial event.
