# Report643 — Daily CTO / Employee Custody Continuity Revalidation
**Date:** 2026-11-08 (Africa/Cairo)  
**Checkpoint:** LVE-2026-11-08-643  
**Previous verified checkpoint:** LVE-2026-11-08-642  
**Scope:** Current-state/constitution reconciliation; operational GitHub; SMART ERP Production contracts and business data; Parent Finance, Buyer, Core, HR distinction; Cloudflare deployment source parity.  
**Execution mode:** Read-only production revalidation plus governance documentation. No operational source, database, permission, Edge deployment, treasury, journal, inventory, or QA-fixture writes were made in this review.

---

## 1. Executive handover and current checkpoint

The current operational checkpoint is LVE642, already recorded at the end of CURRENT_STATE.md and RAWAEA_PROJECT_MEMORY_117-02.md. The first heading in both files still begins with LVE641, whose opening snapshot says the permanent SQL changes had not yet been applied. That opening snapshot is historical and was superseded by LVE642 and Report641 sections 18–19. This report records the subsequent live revalidation as LVE643 and the governance files should place it at the top.

The permanent SQL ChangeSet is **CONFIRMED APPLIED**. This was not inferred from the historical report: the current SMART ERP function hashes and the current received_at column definition exactly match Report641 section 18's post-application values.

The employee-custody feature itself is **not complete**. Parent Finance UI, Buyer branch/Treasury filtering, general employee self-service integration, authenticated Browser/PostgREST E2E, Realtime proof and operational prerequisites remain open.

## 2. Governance sources and continuity

- CURRENT_STATE.md was read, including its appended LVE642 section. Its blob at start of this review was 937f00803be50e6c10eb86001430d11fa3b6c1f2.
- The complete permanent constitution was read. Current SHA: 3a6b1e220af8509e314e94df76563bbc6f84910d.
- Constitution §6.4 dated 2026-11-08 requires the sole execution targets to be SMART ERP Production fiilmooggumokxanwiyx and erp-frontend/main/companies/company-1. No Staging branches/projects, Git branches, duplicate operational copies or parallel applications. Tagged disposable QA fixtures on Production are allowed subject to baseline, rollback/cleanup, full dependent-record and storage cleanup, and post-cleanup reconciliation. The specific-change approval gate remains mandatory.
- Report640 and Report641 were reviewed in full. Report641 sections 17–19 distinguish the earlier rollback-only QA from the later permanent production application and Cloudflare recheck.
- Conversation memory and available prior prompt context were considered. Archived conversation threads that are not available in this session were not independently retrievable; source-of-truth project documents were preferred over memory.

## 3. Source-code and repository state

Operational repository: papamohammed77-glitch/erp-frontend, branch main.  
Current HEAD: b728c09e1bb4c482effc48a492546b393ff02c1f.  
Latest commit: “Harden approved PO receiving list and quantity validation” (2026-11-05 17:43:10 UTC). Its diff changes only companies/company-1/warehouse/receiver.html (+80/-17) relative to the verified comparison base cf07aba424f5ca37cf75ac1804d756448841f4ea.

Current source blobs:
- Parent companies/company-1/main.html: 59241e741abcbc318fa68d3c10775e40e2688927.
- Core companies/company-1/core.js: f4c6a0df441e0da9105d4fe7ce94ad2d7a1735e1.
- Buyer companies/company-1/purchasing/buyer.html: 5ab9f4e268cbf266e6ff950fe41bf5c9a4c9390a.
- HR office/hr.html: ca4175ba414962855ed2fa95def942afbe570f65.

No operational source file has changed since this HEAD in the inspected comparison. Parent, Core and Buyer remain unchanged; the recent operational diff is in Receiver, not the employee-custody flow.

## 4. SMART ERP Production — permanent ChangeSet live verification

Project: fiilmooggumokxanwiyx. PostgreSQL 17.6.1.121. Migration history snapshot: 755 rows; latest version 20261104223538.

### 4.1 Current column and function fingerprints

The current live values match Report641 section 18 exactly:

| Function | Live MD5 |
|---|---|
| buyer_custody_acknowledge_advance_atomic | d4f498a50b5f122780a578e2d3f0b35a |
| buyer_custody_acknowledge_atomic | c723a3c5f7557fe3d0d173667d2eebe7 |
| buyer_custody_add_advance_atomic | c1cfdd85679917a43dd35e22c76e03b3 |
| buyer_custody_issue_atomic | a5dc356cf8d8ed2fa15417394b216138 |
| buyer_custody_settle_atomic | fbcec6d79c6f46bf4c6bea0e5f0cd3c7 |
| finance_save_expense (13-argument overload) | eafbdf9ba7d3b7b01a927816019555e1 |
| finance_save_expense (14-argument branch wrapper) | af1a15d07b0523ec70d6dce7d03aefd6 (unchanged) |

buyer_custodies.received_at is nullable (YES) and has no default.

The six changed existing functions retain owner postgres, SECURITY DEFINER and the recorded search_path configuration. anon EXECUTE remains false and authenticated EXECUTE remains true for the inspected custody/expense signatures. No new table, no new Edge Function, no direct DML grant, no RLS policy change, and no new staging/migration branch were introduced by this ChangeSet.

### 4.2 Reconciliation of the finance_save_expense overloads

Parent _savePayment sends p_branch_id and therefore calls the 14-argument overload. That overload validates required branch and treasury context, then calls the 13-argument overload. The 13-argument overload now enforces account_type='expense' before accepting each expense line.

Therefore the Parent path is protected on the server. The earlier LVE640 warning that an Asset 127 line could be posted through the generic expense RPC is superseded by the permanent LVE642 guard. Do not repeat that old claim as a current server bypass.

The remaining issue is user experience: Parent _addPaymentLine still renders every active COA account, including Asset 127, rather than filtering account_type='expense'. The server rejects an invalid choice; the UI should prevent the invalid selection before submission. This is a P2 UI contract-consistency defect, not proof of a current incorrect posting.

### 4.3 Post-application business-data effects

Live read-only checks confirm:
- buyer_custodies: 0
- buyer_custody_advances: 0
- buyer_custody_expenses: 0
- buyer_custody_payments: 0
- buyer_custody_settlements: 0
- Posted journal_lines under COA 127: 0 lines, 0 debit, 0 credit
- cash_box custody/QA reference rows: 0
- erp_operation_registry custody/QA rows: 0
- employee-documents QA-CUSTODY objects: 0

The permanent SQL deployment itself created no custody, cash, journal, inventory or QA business data.

## 5. Live Chart of Accounts and Treasury constraints

COA 121 (cash) and 127 (employee custody) are active Asset/Debit accounts. Account 127 remains the correct control account for the custody subledger; it has no posted lines and no child GL accounts. Do not create one physical GL account per employee by default.

The current operational Expense account set is 5, 51 and 52. The operational-custody review RPC requires an active Expense leaf and excludes 51 and 52. No valid operating expense leaf for transportation, fuel and tolls was identified. Do not post these categories to cost-of-sales or stock-difference accounts. Approved Expense leaf accounts must be configured by Finance before approving those employee expense categories.

Treasury snapshot:
- CASH-01: central Cash treasury, branch_id NULL, 10,685 EGP.
- BR-01 branch Cash tills: active but each at 0 EGP.
- BR-01 POS: 190 EGP; POS is not a custody disbursement treasury.
- BR-2 Alexandria: active branch exists, but no active Cash treasury exists.

The current RPCs require same-branch Cash treasury and reject central/POS for branch custody. Consequently no branch custody issue can be completed with current balances/configuration. Do not bypass this with CASH-01 or POS. BR-01 must be funded through a real authorized treasury transfer; BR-2 requires a branch Cash treasury and actual funding before its custody operations can be enabled.

## 6. Employee identity, branch scope and HR distinction

The operative employee identity source is public.users, keyed technically by users.id and linked to Auth through auth_id. The HR UI and save-employee flow use users. Do not treat the empty employee_profiles table as absence of the employee master, and do not expose employee_profiles personal/sensitive HR fields to Finance.

Current user snapshot:
- 31 active company users.
- 0 have employee_id populated.
- 3 have default_branch_id.
- 9 allowed_branch_ids values are JSON arrays; 22 are JSON scalar strings.
- Branch eligibility counts: BR-01 has 30/31 eligible by default or allowed-branch membership; BR-2 has 3/31 eligible including wildcard allowance.

The allowed_branch_ids representation is inconsistent and should be normalized in a future controlled master-data improvement. A direct PostgreSQL JSONB membership check returned true for both scalar JSON strings and arrays, so the mixed type alone is not evidence that the current ? checks fail. Existing custody RPCs still validate employee and issuing actor branch scope; do not widen access to compensate for incomplete assignments.

### 6.1 HR salary advances are not operational cash custody

Production contains hr_salary_advances, currently zero rows. Its structure includes employee_id, request_id, advance_no, amount, installment_count, installment_amount, start_period, remaining_balance, status, approved_by/approved_at, disbursed_at and operation_id. It has a separate HR read policy for HR staff or the employee.

This is a salary/employee advance and installment repayment model. It is not a substitute for buyer_custodies and must not be merged with operational cash custody for purchasing, fuel, transport, missions or receipts. Preserve separate business meanings and posting/repayment policies.

## 7. Existing custody contracts, RLS and self-service design

The current custody schema remains the one shared ledger. All five cash-custody tables have RLS enabled. Their SELECT policies constrain records to the employee who owns the custody or authorized Finance roles; direct employee INSERT/UPDATE is not the write path. Writes must use existing SECURITY DEFINER RPCs with authenticated identity checks.

The existing ownership-checked self-service path can support ordinary employees without granting them purchasing or finance permissions:
- read only the current employee's rows through authenticated PostgREST SELECT + RLS;
- acknowledge their own initial custody through buyer_custody_acknowledge_atomic;
- acknowledge their own advance through buyer_custody_acknowledge_advance_atomic;
- submit a general operational expense through buyer_custody_submit_other_expense_atomic after uploading the supporting document to the existing private employee-documents bucket under the prescribed company/user/custody path.

Review, issuing, adding an advance and settlement remain Finance operations. Employee submissions remain pending and do not create GL/cash impact until an authorized Finance reviewer approves the expense. No direct table writes or client-side accounting logic.

The specialized purchase-invoice expense RPC is not a generic fuel/transport route: buyer_custody_submit_expense_atomic requires the purchasing invoice/PO/receiving evidence. Use the separate other-expense RPC for operational expense submissions.

### 7.1 Existing Edge gate

save-purchase-order v30 is ACTIVE, verify_jwt=true, SHA 838f8c05d5e64f040dc4a346eae52816877d635bab41684d32d77eebeae304e6.

Its GET_CUSTODY, ACKNOWLEDGE_CUSTODY and SUBMIT_CUSTODY_EXPENSE operations are gated to purchases/finance/finance_manager. Do not widen this Edge permission gate to every employee. General employee self-service should use the existing self-owned RLS/RPC contracts directly from the employee UI. The Finance Parent continues using the restricted central finance view/issue/review/settlement path.

The employee-documents bucket is private. Existing storage policies check custody ownership and allow only the employee or authorized Finance access. Keep this protection; do not make the bucket public.

## 8. Parent Finance UI — source findings

Parent main.html blob is unchanged. RW_Finance is a private IIFE beginning at line 18465. Its finance tab list at lines 18564–18584 has no Employee Custody tab. The dispatch block at lines 18592–18610 has no employee-custody renderer.

The minimum safe UI patch is:
1. Add a separate employee-custody tab after payments and a dedicated renderer inside RW_Finance. It must use the existing central GET_CUSTODY/ISSUE_CUSTODY contract for Finance staff.
2. Keep custody issue separate from the generic payment form; never call finance_save_expense to issue employee custody.
3. Add the account_type='expense' filter in _addPaymentLine at lines 20868–20871.
4. Keep _newPayment and _savePayment otherwise unchanged; the server guard remains authoritative.
5. Employee summary rows under account 127 are virtual subledger/reporting rows, not new GL accounts per employee.

The exact original-source snippets and initial Parent change plan remain in Report641 section 8; re-extract exact current lines at the time of application if HEAD changes.

## 9. Buyer UI — source findings

Buyer blob remains 5ab9f4e268cbf266e6ff950fe41bf5c9a4c9390a; 1,530 lines.

- renderCustody at lines 1170 onward contains cash custody and a visibly separate goods-custody section. Keep monetary custody, goods custody and vehicle stock distinct.
- issueCustody begins at line 1253. It loads all active treasuries without filtering by selected branch and presents a blank branch option. Its API payload can send branch_id null; the server rejects this. UI and server contract are therefore misaligned.
- addCustodyAdvance begins at line 1281 and loads every active treasury.
- settleCustody begins at line 1464 and loads every active treasury for cash returns.
- All these Finance controls should expose only active Treasury rows with type='Cash', treasury.branch_id equal to the custody/selected branch, and account_code not beginning POS-. Central CASH-01 and POS must not be offered.
- Branch is required in issue UI. Branch-specific treasury options should be refreshed after branch selection. Existing server validation remains mandatory.

No Buyer UI code was changed in this review.

## 10. Core and other employee consumers

Core still exposes RW_Auth, RW_DB, RW_API, RW_UI, RW_ImageCache, RW_SW and RW_Realtime; no shared cash-custody UI/service exists. Core is loaded broadly. Do not add a new core-wide module before the Employee Self-Service contract and the first consumer are proven.

Recommended adoption sequence: Parent Finance and Buyer first; then implement the employee self-service panel in the specific employee app(s) in scope using direct RLS/RPC; after contract stability, share the UI helper without centralizing or duplicating accounting logic. Do not confuse the Van Sales label “عهدتي الآن” with monetary custody; it is vehicle merchandise custody.

Coverage is deliberately limited to Parent Finance, Core, Buyer, HR identity/advance table, the relevant Supabase contracts and the latest Receiver commit. Other operational apps were not re-audited in this daily cycle.

## 11. Cloudflare and Runtime

Cloudflare Pages project rawaea-erp shows Production source main at commit b728c09e1bb4c482effc48a492546b393ff02c1f and deployment URL https://c2f858c3.rawaea-erp.pages.dev/. This matches operational GitHub HEAD.

The dashboard extraction did not expose an explicit Success status. The deployed application URL rendered the login screen. No authenticated user session was used and no UI/E2E operation was executed. Therefore:
- source/deployment commit parity: CONFIRMED;
- route/login page delivery: CONFIRMED;
- authenticated custody UI behavior, employee self-only behavior, actual RLS under user JWT, RPC UI calls, Realtime delivery/latency and full Business E2E: UNVERIFIED.

Buyer configures RW_Realtime with company-scoped tables, 400ms debounce and 15-second reconciliation. This is code evidence only; event delivery and latency remain untested.

## 12. Evidence classification

### CONFIRMED
- LVE642 permanent database changes are live; all Report641 section 18 function hashes and received_at values match exactly.
- Custody RLS, private storage policies and ownership-checked RPC contracts are present.
- The 14-argument finance_save_expense wrapper delegates to the 13-argument account_type guard; Parent server posting path is protected.
- COA 121/127, current branch treasury balances and absence of BR-2 Cash treasury.
- 31 users and current employee/branch mapping shape.
- HR salary advances table is separate from buyer custody.
- Parent lacks custody tab; Buyer issue/add/settlement treasury filtering remains incomplete.
- Cloudflare Production commit matches operational GitHub HEAD.

### UNKNOWN
- Which additional non-Buyer employee roles should be eligible for operational cash custody as a business policy.
- Whether the owner/Finance wants distinct cost centers and mission identifiers mandatory for each custody.
- Business policy for employee overspend reimbursement and any salary-payable route. No automatic payroll deduction is authorized.
- When BR-01 tills will be funded and when BR-2 Cash treasury will be configured.

### CONFLICT / RECONCILIATION
- CURRENT_STATE.md's opening LVE641 snapshot says no permanent Production change, but its appended LVE642 section, Report641 sections 18–19 and live SQL hashes all show the permanent ChangeSet applied. Reconciled: LVE641 text is historical; LVE642 is the current prior checkpoint.
- Report640's pre-LVE642 statements about unguarded finance_save_expense are superseded by the live 13-argument Expense guard.
- Older Staging-only advice is superseded by Constitution §6.4.

### UNVERIFIED
- Authenticated Browser JWT E2E as an ordinary employee and Finance reviewer.
- Real PostgREST RLS self-vs-other enforcement from independent sessions.
- Expense review/approval/posting because no eligible Expense leaf exists.
- Realtime event delivery, reconnect and measured latency.
- Full Cloudflare deployment Success state and authenticated runtime operation.
- Field/multi-device business completion.

## 13. Error and priority register

| Priority | Finding | Evidence | Required response |
|---|---|---|---|
| P1 | Employee self-service UI absent for ordinary staff | Current only Buyer view uses restricted Edge GET_CUSTODY gate | Integrate self-only PostgREST/RPC UI; do not widen Edge permissions |
| P1 | Employee-custody rollout blocked by treasury setup/funding | BR-01 Cash balances 0; BR-2 has no Cash Treasury; central unassigned and POS excluded | Authorized Treasury setup/funding only; no shortcut |
| P1 | No valid operational Expense leaf for transport/fuel/tolls | Other-expense review RPC requires Expense leaf and excludes 51/52 | Finance-approved COA setup before approval/expense posting |
| P2 | Parent payment account dropdown exposes non-Expense accounts | _addPaymentLine maps all active accounts; server now rejects non-Expense | Filter UI to account_type='expense'; keep server guard |
| P2 | Buyer Issue UI branch is optional and Treasury list is broad | lines 1253–1276; server rejects null/mismatch/POS | Require branch and filter active same-branch Cash treasury |
| P2 | Buyer advance and settlement Treasury lists are broad | lines 1281–1295 and 1464–1487 | Apply the same-branch Cash/non-POS filter |
| P2 | User allowed_branch_ids representation is mixed | 9 arrays / 22 scalar strings | Normalize the master data with a bounded, approved data-quality plan; current JSONB ? checks tested true for both |
| P2 | No dedicated shared self-service UI in Core/apps | Core modules inspected; no custody component | Start with first user app and prove contract before broad Core change |

No P0 was detected in the inspected scope. This is not a full-system P0 clearance.

## 14. Business and functional boundaries

- Employee cash custody is separate from employee salary advances, vehicle merchandise custody and Buyer goods custody.
- Draft/issue alone does not spend cash; employee acknowledgement triggers the actual treasury/cash/journal posting.
- Employee expense submission is pending only; Finance approval posts the expense against 127; actual cash return settles the remaining cash.
- Purchases of goods remain in PO/invoice/receiving and supplier AP workflows; do not recode merchandise purchases as fuel/transport expense.
- No payroll deduction, Employee Payable disbursement, or employee reimbursement shortcut is authorized.

## 15. Testing and cleanup

No QA fixture was created in this review. Live Production read-only checks were used. Existing Report641 rollback-only SQL/RPC test history is valid for the functions as tested at that time; current fingerprints independently confirm the permanent functions are those reported in §18.

Next E2E cycle must use the owner's §6.4 model:
1. baseline counts/balances for custody, cash_box, journal_lines, treasury, operation_registry and storage objects;
2. tagged disposable QA fixture IDs;
3. actual test employee and Finance JWT sessions;
4. tests for no effect before acknowledgment, one posting after acknowledgment, self-only access, unauthorized access rejection, submission pending/no posting, Finance approval once, physical cash return and full reconciliation;
5. complete dependent rows, files and operation_registry cleanup;
6. post-cleanup verification that baseline counts and balances are restored.

Do not run a committed test path that produces a non-reversible audit/journal effect until its cleanup/reversal contract is proven.

## 16. Twelve-domain maturity

Overall enterprise maturity scores remain UNKNOWN because this review covers a narrow employee-custody slice, not every operational app and process. The current custody DB contract is more mature than its UI adoption and field proof. No overall 0–5 score is fabricated.

## 17. Deployment and change record

This review created no operational source diff and no Production write. No Edge function was redeployed. Documentation updates only:
- this Report643;
- CURRENT_STATE.md latest checkpoint header;
- RAWAEA_PROJECT_MEMORY_117-02.md latest knowledge header.

## 18. Readiness and next priority

**READY WITH LIMITATIONS.** Database custody contract changes are applied and fingerprint-verified. Source/deployment commit parity is confirmed. Production runtime remains only partially verified; authenticated E2E and the three UI integration layers remain open. No mass rollout or field-ready claim is justified.

**Single next priority:** complete the owner-applied Parent Finance + Buyer UI ChangeSet against current source blobs, keeping the generic expense route separate from custody, then integrate employee self-service through direct self-owned RLS/RPC calls in the first employee app. Do not modify Core or broaden permissions before that first consumer passes authenticated E2E.

Related evidence:
- CURRENT_STATE.md: https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/CURRENT_STATE.md
- Constitution: https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/%D8%A7%D9%84%D8%AF%D8%B3%D8%AA%D9%88%D8%B1%20%D8%A7%D9%84%D8%AA%D8%B4%D8%BA%D9%8A%D9%84%D9%8A%20%D8%A7%D9%84%D8%AF%D8%A7%D8%A6%D9%85.md
- Report640: https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report640_EMPLOYEE_CUSTODY_PARENT_FINANCE_CONSUMER_REVALIDATION_20261107.md
- Report641: https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report641_EMPLOYEE_CUSTODY_SURGICAL_CHANGESET_20261108.md
- Operational HEAD: https://github.com/papamohammed77-glitch/erp-frontend/commit/b728c09e1bb4c482effc48a492546b393ff02c1f
