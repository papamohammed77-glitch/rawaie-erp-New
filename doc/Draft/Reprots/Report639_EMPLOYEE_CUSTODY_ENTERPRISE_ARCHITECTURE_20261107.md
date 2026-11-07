# Report639 — Employee Cash Custody Enterprise Architecture Assessment
**Date:** 2026-11-07 (Africa/Cairo)  
**Checkpoint:** LVE-2026-11-07-639  
**Scope:** Read-only revalidation of Parent Finance module and SMART ERP employee-custody accounting model; target architecture proposal.  
**Change classification:** Documentation and architecture assessment only. No operational source, database, permissions, Edge Functions, deployment, or business data were changed.

## 1. Executive decision

RAWAEA already has the accounting control account and a Buyer-specific cash-custody lifecycle. The enterprise requirement is therefore **not to create another cash-custody ledger**. The target should be one company-wide employee-custody subledger controlled by COA 127, exposed through Parent Finance and through each eligible employee's own operational app.

The Parent Finance screen currently provides treasury, chart of accounts, journals, receipts, payments, expenses, transfers and other finance tabs. Its generic payment flow is an expense-posting workflow and calls `finance_save_expense`; it must not be reused unchanged for employee-custody disbursement because that function debits expense accounts rather than employee-custody receivables.

Recommended accounting representation:
- COA **127 — عهد الموظفين** remains the single general-ledger control account (asset, debit normal balance).
- Employee and custody/mission detail is maintained in a subsidiary ledger (employee, branch, purpose/mission, custody document and currency).
- Parent Finance may visually render the employee subsidiary balances as child rows beneath account 127, but these rows should not be separate GL accounts by default.
- One actual cash disbursement is posted only after physical handover is evidenced and the employee acknowledges receipt.

## 2. Verified resumption and governance

- Prior checkpoint read first: **LVE-2026-11-06-638** in `CURRENT_STATE.md`.
- Operational repository: `papamohammed77-glitch/erp-frontend`, branch `main`.
- Operational HEAD at inspection: `b728c09e1bb4c482effc48a492546b393ff02c1f`.
- Current Parent file: `companies/company-1/main.html`, blob `59241e741abcbc318fa68d3c10775e40e2688927`; 1,807,487 characters / 33,475 lines.
- Current permanent constitution: `doc/Draft/Reprots/الدستور التشغيلي الدائم.md`, blob `d2afa896514b1cb6abd247d2af7a862251ce0604`, read in full before other project inspection.
- Relevant historical design: Report632, `Report632_BUYER_CASH_CUSTODY_OPERATIONAL_EXPENSES_QMP_HARDENING_20261105.md`.
- Previous LVE638 risks remain independently open; this report does not close or overwrite the Receiver/Audit risks in Report638.
- The constitution requires separation of draft/approval from actual cash movement and exact owner approval for any operational source, Production database, access, journal, balance or integration change. Parent and operational application files are not edited by this assistant.

## 3. Parent Finance source review — CONFIRMED

The current Parent source contains the standalone `RW_Finance` module.

Relevant source areas:
- Finance navigation menu: approximately lines 1548–1568.
- Finance subtab list and dispatch: approximately lines 18560–18605.
- COA tree renderer: approximately lines 19102 onward.
- Receipt flow: approximately lines 19762 onward.
- Payment-list and payment-entry flow: approximately lines 20778–20985.
- `RW_Finance` exported methods: approximately lines 22126 onward.

The existing Finance tabs include:
- خزائن وبنوك
- دليل الحسابات
- قائمة القيود اليومية / قيد يومي جديد
- القيود المتكررة
- سندات القبض
- سندات الصرف
- الإيرادات / المصروفات
- التحويلات
- الشيكات ومطابقة البنك
- الضرائب والأصول والإهلاك والموازنات والفترات والتقارير والتقسيط والعمولات

The current generic `payments` tab:
1. Displays `cash_box` rows where `type='Payment'`.
2. Opens a form with branch, treasury, beneficiary, reference and expense lines.
3. Collects one or more chart-of-account lines.
4. Calls `finance_save_expense` from `_savePayment`.

The live `finance_save_expense` function posts the selected line accounts as debits, credits the configured cash control account, creates a `finance_expenses` record, creates a `cash_box` Payment record and updates the Treasury balance. This is correct for a paid expense but is the wrong accounting classification for handing an employee money for a future mission.

**Design implication:** introduce a distinct destination/mode in the Parent Finance cash-disbursement workflow, `عهدة موظف`, and route it to the custody posting contract. Do not pass a custody to `finance_save_expense` and do not represent the advance as an expense line.

## 4. SMART ERP Production read-only snapshot — CONFIRMED

Project: `fiilmooggumokxanwiyx`.

### 4.1 Chart of accounts

- Account **127 — عهد الموظفين** exists, active, type `asset`, normal balance `debit`, with notes identifying employee and cash-purchase custody.
- Account **121 — النقدية (الخزينة الرئيسية)** exists, active, type `asset`, normal balance `debit`.
- COA 127 currently has **zero child GL accounts**.
- `journal_lines` currently has **zero lines** against account 127.

Therefore the control account has been provisioned, but an employee subsidiary-account tree and real custody postings have not yet been established.

### 4.2 Existing custody structures

The following RLS-enabled structures exist:
- `buyer_custodies`
- `buyer_custody_advances`
- `buyer_custody_expenses`
- `buyer_custody_settlements`
- `buyer_custody_payments`
- `buyer_goods_custody_events`

Current rows at the read-only inspection:
- `buyer_custodies`: 0
- `buyer_custody_advances`: 0
- `buyer_custody_expenses`: 0
- `buyer_custody_settlements`: 0
- `buyer_custody_payments`: 0
- `cash_box`: 3 Payment rows, all source `POS_RETURN_REFUND`; 5 Receipt rows, all source `POS`.

The Buyer custody tables use `users.id` as `employee_id`, and connect custody, advances, expense claims, settlement, treasury, cash_box and journal-entry identifiers. Their current APIs and names are Buyer-specific; this is not yet proof of a general all-employee service.

### 4.3 Employee identity and treasury scope

- `users` has 31 active users for the current company.
- `employee_profiles` has zero rows. Its `employee_id` foreign key references `users.id`.
- Consequently, the present Buyer custody contract uses the company user as its current employee identity. The HR profile layer is not populated and cannot yet be treated as the complete authoritative employee register.
- Treasury currently includes a central `CASH-01` with `branch_id=NULL`, branch-scoped cashiers and a branch POS treasury. Branch ownership therefore needs an explicit rule, not an assumption that every treasury is branch-owned.
- The live `buyer_custody_issue_atomic` validates that the selected Treasury is active and belongs to the company and that the requested branch belongs to the company. It does **not** verify that the Treasury's `branch_id` matches the custody's `branch_id`. This is a confirmed contract gap for a branch-restricted disbursement workflow. A central Treasury exception must be explicit and separately authorized.

## 5. Existing Buyer custody posting model — CONFIRMED from live contracts and Report632

The existing Buyer design is a useful foundation and should be reused rather than duplicated.

### 5.1 Initial and additional advances

`buyer_custody_issue_atomic`:
- Requires authenticated active same-company actor with `finance` or `finance_manager`.
- Validates active target user, prohibits self-issue, validates company branch, active Treasury, positive amount, purpose and operation identifier.
- Creates the custody header and an Initial advance.
- Returns a pending employee-acknowledgement state.
- Does not itself post cash or a journal entry.

`buyer_custody_add_advance_atomic` adds a separately identified Additional advance. The additional cash must also pass the employee-acknowledgement/posting path.

### 5.2 Actual handover and journal

`buyer_custody_acknowledge_atomic` requires the authenticated recipient to own the custody and acknowledge it. The central posting route then calls `post_cash_payment_atomic` and records the associated `cash_box` and journal-entry identifiers.

Expected accounting:
- **Dr 127 — عهد الموظفين**
- **Cr 121 — النقدية / الحساب النقدي المقابل**

The treasury cash balance decreases only as part of the actual cash-posting transaction. The custody header or approval by itself is not the cash event.

### 5.3 Expense evidence and approval

The employee submits an expense claim with supporting evidence. Submission reserves/commits available custody but does not post the final expense journal. Finance review approves or rejects it.

For an approved operational expense:
- **Dr selected operating-expense account**
- **Cr 127 — عهد الموظفين**

This settles part of the employee's custody balance without a second cash-out from Treasury.

Purchase of merchandise is not a generic operating expense. It must remain connected to the purchase invoice and actual receiving route, including the existing Buyer/Quick Market receipt controls. Do not debit a generic expense account for merchandise and bypass inventory/AP controls.

### 5.4 Cash return and closure

The existing settlement path blocks unreviewed claims, unacknowledged advances and open Quick Market reservations. An actual cash return is posted through the central receipt route:

- **Dr 121 — النقدية**
- **Cr 127 — عهد الموظفين**

The settlement stores cash-box and journal references and closes the custody only after reconciliation.

### 5.5 Open design limitation

Report632/live settlement logic indicates that an expense total exceeding the employee's issued custody is not yet a supported employee-payable outcome; the current path rejects that state rather than silently netting a credit balance into the asset control account. General employee custody must explicitly support or block this scenario with a separate employee-payable liability and a real payment workflow. Never auto-deduct payroll or leave a negative employee-asset balance as an undocumented substitute.

## 6. Recommended enterprise accounting design

### 6.1 One control account, one employee subledger

Use 127 as the single GL control account. Employee-specific and mission-specific balances should be represented by subledger dimensions:
- company_id
- employee user/staff identity
- branch_id
- custody/mission document id
- purpose/category
- cost_center/project (when applicable)
- currency
- due date
- issuing/approving/handing-over actors
- source application
- advance, expense, payment/return, journal and cash-box links

Parent Finance should display this as a tree:
- 127 — عهد الموظفين
  - عهدة [الموظف]
    - عهدة [المهمة / المستند]
      - حركة صرف
      - مصروفات معتمدة
      - مبالغ مرتجعة
      - الرصيد المفتوح

These are subsidiary-ledger groupings. Do not automatically create a new physical general-ledger account for every employee. This avoids account proliferation and maintains one reconcilable control account. If a documented statutory/accountant requirement later demands separate GL subaccounts, that should be a separate accounting decision with automatic reconciliation to 127.

### 6.2 Distinguish business custody from personal salary loans

- **Employee business custody:** temporary company cash entrusted for a defined business mission, purchasing run, customer route, field expense or other institutional task. Tracked under 127 and settled with expenses/evidence/returned cash.
- **Salary advance / personal employee loan:** a separate employee receivable/loan process with payroll-repayment terms, approvals and a distinct accounting mapping. Do not merge it into operating custody just because the recipient is the same employee.
- **Employee-paid expense:** where the employee used personal money, recognize an approved employee payable/reimbursement, not a reduction of company cash custody.
- **Company-paid card/bank expense:** reconcile against the relevant company payment source, not against the employee cash advance unless explicitly linked.

### 6.3 Parent Finance workflow

In the Finance cash-disbursement experience introduce a mandatory `وجهة الصرف`:
1. Direct expense / other already-supported payment route.
2. Employee custody.

When `عهدة موظف` is selected, show:
- branch and permitted Treasury
- employee/staff recipient
- task/mission or reason
- cost center/project if relevant
- date and settlement due date
- amount and company currency
- attachments/reference
- approver and payout authority
- custody/subledger reference under account 127

The form should display: `الحساب الرقابي 127 — عهد الموظفين`, then the employee subledger and custody/mission record. It should not ask for an ordinary expense account as the advance's debit.

### 6.4 Approval, physical handover and posting are separate stages

Recommended statuses:
- Draft
- Submitted
- Approved
- Awaiting handover
- Acknowledged / Active
- Partially settled
- Under finance review
- Settled
- Rejected / Cancelled before payment
- Overdue (derived indicator; not a deletion or accounting reversal)

Recommended responsibilities:
1. Employee or authorized requester creates/submits a mission request.
2. Line manager/branch manager approves mission, amount and due date.
3. Finance checks account, budget, existing outstanding exposure and branch.
4. Cashier/treasury officer physically hands cash to the named employee.
5. Employee acknowledges receipt in their own authenticated app (or approved signed evidence).
6. Only then does the central cash posting route create the cash-box payment and Dr127/Cr121 journal.
7. The employee submits expenses and evidence from their operational app.
8. Finance reviews and posts approved expense allocation.
9. Employee physically returns unused cash; cashier records actual receipt; central receipt route Dr121/Cr127.
10. Finance reconciles and closes the mission custody.

Approval alone never reduces Treasury or posts a GL journal. The employee acknowledgement must be tied to the actual handover event, not simply a button that can be clicked before cash is delivered.

### 6.5 Correct settlement accounting

For a normal custody:
- Disbursement: Dr 127 / Cr 121.
- Approved expense: Dr expense category / Cr 127.
- Unused cash physically returned: Dr 121 / Cr 127.
- Additional cash handed over: Dr 127 / Cr 121, with a separate advance document and idempotency key.

If a valid employee-paid expense exceeds the available advance:
- Recognize the additional approved amount as a payable to the employee (separate liability account/subledger).
- Pay that payable only through a separately evidenced cash/bank payment.
- Do not let the asset control account 127 silently become a credit balance.
- Do not create automatic payroll deductions without a separately approved policy and documented workflow.

A purchase invoice funded from the custody remains a purchase transaction: verify supplier, invoice, accepted warehouse receipt, quantity/value and supplier/AP effects. A draft invoice or expense submission alone does not complete a purchase or alter cash/stock.

## 7. Roles, RLS and segregation of duties

Recommended access model:
- Employee: see only their own custody, acknowledge their own cash receipt, submit only their own expenses and see settlement status.
- Line/branch manager: approve mission and limits only within authorized branch scope.
- Treasury cashier: record physical payout/return only for assigned Treasury and branch.
- Finance: validate supporting documents, approve expense claims, reconcile, close.
- Finance manager: thresholds, exceptions and controlled overrides with reason.
- Auditor/management: read-only ledgers and audit trails within authorized company/branch scope.

Mandatory controls:
- prohibit self-approval and self-review;
- prohibit issuing custody to an inactive or unrelated identity;
- require company and employee relationship checks;
- enforce branch/Treasury relationship inside the server-side RPC, not merely by filtering the dropdown;
- make central Treasury use an explicit privileged exception, never an accidental `branch_id=NULL` bypass;
- preserve immutable transaction/event history and use reversal/correction documents instead of editing posted entries;
- idempotency key per real payout intent; reuse only for retries of that same intent, never for a later independent payout with the same amount;
- lock relevant custody and Treasury rows during financial posting;
- never permit browser writes directly to cash_box, treasury balances, journal_lines or posted audit history.

## 8. Cross-application integration

Target behavior:
- Parent Finance owns the employee-custody control view and approvals/posting.
- Each employee's authenticated operational app presents a shared `عهدتي` surface backed by the same central custody contract.
- The Buyer app should continue showing Buyer-specific purchase/market and vehicle/goods responsibilities, but cash custody should be one shared source, not a Buyer-only balance duplicated for other apps.
- Sales reps, delivery staff, buyers and other employees see only the custody items assigned to their user identity.
- The shared module should use the existing central database/RPC path and established auth/permission model. Do not duplicate posting logic inside each app or introduce a parallel Edge Function.

Before generalizing Buyer-specific physical tables or RPC names, map every current Buyer consumer and contract. Keep current Buyer flows backward-compatible during any gradual refactor. Do not create a second employee-custody table set simply to remove the Buyer prefix.

## 9. Production gaps requiring closure before implementation

| Priority | Finding | Evidence / required closure |
|---|---|---|
| P1 | Custody RPC validates company ownership of Treasury but not Treasury branch match | Add server-side branch ownership check and an explicit central-Treasury exception |
| P1 | HR employee_profiles has zero rows while users has 31 active accounts | Establish authoritative employee identity/mapping and rules for app users who are not employees; do not assume every active login is an eligible custodian |
| P1 | Current issuance API is Finance-only and Buyer-named | Map consumers and define generic requester/manager/finance/cashier roles before exposing to all staff |
| P1 | Expense posting path can be misused if Parent generic payment is reused | Custody disbursement must route to custody issue/acknowledgement contract, not finance_save_expense |
| P2 | 127 has no child GL accounts and no posted ledger lines | Expected initial state; build employee subsidiary display and reconcile before opening operational use |
| P2 | Employee payable when expense exceeds advance is not implemented in existing custody settlement | Add a separate liability/payment path or explicitly disallow overspend with visible workflow |
| P2 | Branch and central treasury semantics need master-data governance | Define central vs branch scope, transfer/approval boundaries and permitted treasury list |
| P2 | Generic reports/aging/overdue and reconciliation not delivered for all employees | Provide balance by employee, branch, mission, age, approver, due date and GL reconciliation |
| P2 | Buyer-specific names/logic are not yet a common employee API | Consumer map first; then shared contract and backward-compatible refactor |

## 10. Competitor / ERP benchmark — official documentation

### Daftra
The official Daftra help center documents a dedicated Employee Custody workflow: select the employee, due date, amount and currency, advance/custody account and cash/bank account; record the disbursement and journal; attach documents; and display custody transactions and settlement history. Daftra also documents employee subsidiary accounts under the employee-custody account. This closely matches the desired visible Parent tree, but RAWAEA should still prefer a controlled employee subledger under account 127 unless accounting policy requires physical GL subaccounts.  
References: [Create a new employee custody](https://docs.daftra.com/tutorial/إضافة-عهدة-موظف-جديدة/), [View employee custody](https://docs.daftra.com/tutorial/عرض-عهدة-موظف/).

### Microsoft Dynamics 365 Project Operations
Microsoft documents a request → workflow approval → accountant payment/posting process. An employee expense report can be matched to paid cash advances; excess advance is returned, while an expense above the advance creates an amount due to the employee. Microsoft also documents foreign-currency cash advance adjustments and explicit FX gain/loss handling.  
Reference: [Cash advance](https://learn.microsoft.com/en-us/dynamics365/project-operations/expense/cash-advance).

### Microsoft Dynamics 365 Business Central
Employee posting groups can map prepayments/cash advances to a dedicated Expense Prepayment Account, separately from reimbursement payable accounts and expense-line posting groups. This reinforces that a cash advance is not an ordinary expense debit.  
Reference: [Set up expense management](https://learn.microsoft.com/en-us/dynamics365/business-central/expense-management/expense-management-setup).

### SAP
SAP Travel Management documents employee trip advances by personnel number and request, with settlement results transferred to Accounting; its AO-1 form records the actual advance and prior employee advances. SAP Concur documents accounting for used and unused portions through expense reports or return of unused cash to the cash-advance administrator.  
References: [Add Cash Advance](https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/f4153779fcb742c094bb6157c0ff1cbe/750bcb5389d37214e10000000a174cb4.html), [Advance via Financial Accounting](https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/f4153779fcb742c094bb6157c0ff1cbe/da0ccb5389d37214e10000000a174cb4.html), [Returning or Utilizing Cash Advances](https://help.sap.com/docs/CONCUR_EXPENSE/bb83754b1c5541808d50c09901e11475/c88bb71703ef4b9d95f2bad1d82dc567.html).

### ERPNext
ERPNext Employee Advance separates Draft, Unpaid, Paid, Claimed, Returned and Partly Claimed and Returned; an actual Payment Entry/Journal Entry is required to mark the advance paid, and subsequent Expense Claims or return entries settle it. Employee Advance Summary groups outstanding amounts by employee, department, branch and advance account.  
References: [Employee Advance](https://docs.frappe.io/hr/employee-advance), [Employee Advance Summary](https://docs.frappe.io/hr/reports/employee-advance-summary).

### Odoo
Odoo Expense supports employee expense submission, manager approval, posting, reimbursement and analysis by employee/category. Its documented workflow is useful for the expense-claim/reimbursement side; this review does not treat the cited Odoo pages as proof of a dedicated cash-custody advance ledger.  
References: [Expenses](https://www.odoo.com/documentation/18.0/applications/finance/expenses.html), [Expense Reports](https://www.odoo.com/documentation/18.0/applications/finance/expenses/expense_reports.html), [Reimburse Employees](https://www.odoo.com/documentation/18.0/applications/finance/expenses/reimburse.html).

## 11. Acceptance tests for a future approved ChangeSet

All end-to-end testing must occur in isolated Staging with synthetic QA identities/data, not by creating custody activity in Production.

1. Create a 5,000 EGP custody request: no cash_box, no journal line, no Treasury balance change.
2. Approve the request: still no cash_box, journal or Treasury movement.
3. Hand over 5,000 EGP and record recipient acknowledgement: exactly one cash_box Payment and one balanced journal Dr127/Cr121; Treasury decreases exactly 5,000.
4. Retry with the same operation id: no duplicate; initiate a new independent payout for the same amount with a new operation id: a new valid event is posted.
5. Employee sees their own custody in their app; another employee cannot read, acknowledge or submit expenses against it.
6. Submitting a documented 600 EGP expense reserves it but creates no final expense journal or cash movement.
7. Finance approval posts Dr selected expense / Cr127 exactly once and does not move Treasury a second time.
8. Physically return 4,400 EGP: post Dr121/Cr127 once. The custody reconciles: 5,000 = 600 approved expenses + 4,400 cash returned.
9. Additional advance follows a separate approval/handover/acknowledgement and creates one more payment/journal only after actual handover.
10. Branch-A custodian cannot select or post against Branch-B Treasury; central Treasury is available only via explicit authorized exception.
11. Expense above cash advance follows configured employee-payable accounting or is blocked before posting with an explicit reason; no unexplained negative 127.
12. Trial-balance account 127 reconciles exactly to the total open employee-custody subsidiary balances.
13. Quick Market merchandise purchase still requires supplier invoice and accepted physical receiving; generic employee expense cannot bypass inventory/AP rules.
14. Test employee termination/transfer, overdue custody, rejected expense, cancellation before payout, reversal after posting, concurrent acknowledgement and simultaneous payout attempts.

## 12. Implementation sequence and approval gates

**Phase 0 — Contract/consumer map:** map every caller of `buyer_custody_*`, each Buyer custody tab and all app identity/branch consumers; confirm employee master source and central-vs-branch treasury policy.

**Phase 1 — Parent Finance:** prepare an exact surgical patch to add the employee-custody destination and employee subsidiary view to `RW_Finance`; route to the current custody RPC contract or an approved generic wrapper; keep expense payment route unchanged.

**Phase 2 — Employee app surface:** expose the same custody records and acknowledgement/claim functions in each eligible employee operational app, with employee-only RLS and no duplicated business posting code. Preserve the Buyer app's existing purchase/goods custody behavior.

**Phase 3 — Finance control/reporting:** employee/branch/mission ledger, open balance aging, due-date alerts, expense review, cash return, employee payable if approved, and 127 reconciliation.

**Phase 4 — Isolated QA/E2E:** run all acceptance tests with cleanup verification in Staging, then prepare a separate owner-reviewed Production ChangeSet and deployment plan.

Every change to Parent `main.html`, Buyer or other operational HTML, Supabase schema/RLS/RPCs, treasury postings, journal postings or permissions requires a specific ChangeSet containing current source text, exact replacement, impact/dependencies, tests, rollback and explicit owner approval. No new Edge Function is recommended.

## 13. Current status and next decision

- Verified and documented: Parent Finance implementation, control accounts 127/121, existing Buyer custody data model and posting lifecycle, HR profile gap, treasury branch-scope gap and the enterprise target.
- Unknown/unverified: deployed Parent artifact, browser Runtime, real employee acknowledgement E2E, Staging availability and field usability.
- No source code, Production schema, RLS, Edge Function, balance, journal, Treasury or business data was changed.
- Recommended next engineering step: complete the consumer map for every `buyer_custody_*` table/RPC and identity/branch contract, then prepare the exact Parent Finance + shared employee-custody ChangeSet. Do not implement until the owner reviews the exact ChangeSet and explicitly approves it.
