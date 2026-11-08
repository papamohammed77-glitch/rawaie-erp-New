# Report648 — Parent Finance Employee Custody Issue Action Fix
**Date:** 2026-11-08  
**Checkpoint:** LVE-2026-11-08-648  
**Status:** `FIX COMMITTED — STATICALLY VALIDATED — DEPLOYMENT / AUTHENTICATED E2E UNVERIFIED`

## 1. Scope and governing evidence

Executed the owner's request against the current operational source, not historical report claims. Read the execution prompt `doc/Draft/Reprots/writing-block-8-10.md`, the permanent constitution, and the current state checkpoint LVE647. Inspected the current Parent source blob, the actual finance-custody module, the Parent authentication/bootstrap flows, the deployed-browser context available in this session, the Supabase Production schema/policies/function definitions, and the active `save-purchase-order` Edge Function.

- Operational repository: `papamohammed77-glitch/erp-frontend`, branch `main`.
- Operational file changed: `companies/company-1/main.html` only.
- Base Parent blob: `4d25abf0d01b65acf48d7a76634293b8ea3e06ee`.
- Primary fix commit: `0c2327a8bba6303b81d874aad843cd3243dab9ef`.
- Follow-up integration commit: `d04e1dee9df5ac3ef940e8222b24a43400494d66` (adds the company scope required by Buyer/Core consumers).
- Final Parent blob after both commits: `4405f87169c62baf770b6b675c1582cc484772ba`.
- Latest observed branch HEAD: `9e12088352907404b53bde4cf4a0f2fe7483c9c0`, a later forensic-extraction-only descendant that preserves both custody commits.
- Production project: Supabase SMART ERP, `fiilmooggumokxanwiyx`, `ACTIVE_HEALTHY`.

## 2. Root cause — independently confirmed

The button path is:

`RW_Finance._issueEmployeeCustody` → `RW_Finance_Custody.issueFirst()` → `issue()`.

The first guard in `issue()` calls `_showToast(...)` when the permitted employee list or permitted branch list is empty. That identifier existed only inside the separate `RW_Finance` closure and was not lexically available to the sibling `RW_Finance_Custody` IIFE. The resulting `ReferenceError: _showToast is not defined` aborted the click before the SweetAlert form could open.

A second, directly related defect would have left the action unusable after merely adding a toast helper:

- `RW_Finance_Custody.actor()` asks for `RW_Auth.getUser()`, but the current `RW_Auth` object had no `getUser` method. Its fallback reads `RW_STATE.user`, while the Parent's canonical signed-in object is `RW_STATE.app.currentUser`.
- Both the password-login path and the existing-session restore path omitted the database user ID and branch scope from that canonical object. The login query selected only `company_id,status,permissions,name`; the restore query selected only `company_id,status`.
- The custody renderer therefore lacked authoritative `id`, `default_branch_id`, and `allowed_branch_ids` for self-exclusion and filtering branches to the user's own scope. The current console column (109) pointed to the first guard, consistent with the missing toast being the visible exception rather than proof that employee/branch data was unavailable.

The users table contains these columns. Its authenticated self-read policy permits a user to read their own row via `auth_id = auth.uid()`. The fix therefore reuses the existing Parent Supabase client and existing self-profile read; it does not weaken RLS or add an elevated data path.

## 3. Surgical source correction

Only `companies/company-1/main.html` changed; commit statistics are 14 additions / 3 deletions. No other operational app or source file was edited.

1. Added a custody-module-local `_showToast(m,t)` helper which delegates to the Parent's existing `showToast` and safely falls back to `alert`. Existing custody call sites remain unchanged.
2. Added the missing `RW_Auth.getUser()` method returning the canonical `RW_STATE.app.currentUser` object. This also makes the already-existing consumer at the customer-assignment action resolve the same canonical user API.
3. Extended the password-login self-profile select to include `id, company_id, default_branch_id, allowed_branch_ids`, and retained all four fields in `RW_STATE.app.currentUser`.
4. Extended the existing-session restore self-profile select with `id, company_id, default_branch_id, allowed_branch_ids` and populates them after the active-user checks. This is essential because the observed Parent browser boot log said `Session restored`; fixing login alone would not repair that path.

The existing `actor()` and branch filter now resolve through a real Parent API and have the fields they already expect. Employee self-exclusion and branch restrictions remain in place. The Buyer app also relies on `RW_Auth.getUser()` for the employee `id` and `company_id`, while `RW_Realtime.start()` rejects subscriptions unless the verified user's `company_id` matches the app tenant; the added company field keeps these existing contracts intact. Driver's separate Supabase-session/JWT path was inspected and was not modified. Server-side authorization remains authoritative.

## 4. Custody business contract and system-wide impact

The Parent Finance custody tab remains the administrative subledger; Buyer and Driver retain their existing employee-facing acknowledgement/expense workflows. No Buyer, Driver, Core, purchasing Edge Function, or shared database logic was changed.

Verified current request flow:

- The Finance renderer loads `GET_CUSTODY`, company-scoped branches and treasury rows, and eligible expense accounts through the existing `save-purchase-order` Edge Function (Production version 30, active, JWT verification enabled).
- The Edge Function derives the authenticated caller's effective profile, company and permissions. `ISSUE_CUSTODY` requires `finance` or `finance_manager` and invokes the existing `buyer_custody_issue_atomic` RPC using the caller-authenticated profile client.
- The RPC validates the active actor, company, Finance permission, actor and employee branch scope, active employee (not the actor), positive amount/purpose, active same-branch Cash treasury (excluding POS), system currency, and operation-id idempotency.
- Issuance creates the custody record and its initial advance in the **PendingEmployeeAcknowledgement** state. It does not by itself post a cash-box disbursement, cash movement, or journal entry. The existing employee acknowledgement remains the gate for actual cash posting.

No financial, treasury, cash-box, journal, AP, inventory or stock behavior was altered.

## 5. Validation and production data safety

**Source validation — PASS**
- Re-fetched the committed blob after saving and inspected the commit's actual patch.
- The Parent inline executable script compiled successfully with `new Function`; zero syntax errors.
- Static invariants confirm one custody-local toast helper and one `RW_Auth.getUser` definition.
- A controlled identity/branch-scope simulation passed: the current employee was excluded from the assignable employee list; the default branch and explicitly allowed branch were retained; an unauthorized branch and an inactive branch were excluded. A separate integration check confirmed that the canonical Parent user now provides both `id` and `company_id`, satisfying Buyer employee-custody identity and the Core realtime tenant-equality guard.
- The two owner-authored commits touch `companies/company-1/main.html` only; the combined surgical diff is 16 additions / 3 deletions. No changes to custody `issue()` business inputs, RPC argument contract, Edge Function endpoint, or acknowledgement gate.

**SMART ERP Production — read-only verification**
- Project status: `ACTIVE_HEALTHY`.
- Active users: 31; active branches: 4; active non-POS Cash treasuries: 3.
- Custody baseline and post-change counts are unchanged at zero:
  - `buyer_custodies`: 0
  - `buyer_custody_advances`: 0
  - `buyer_custody_expenses`: 0
  - `buyer_custody_payments`: 0
  - `buyer_custody_settlements`: 0
- No SQL, DDL, DML, migration, RPC, RLS/ACL, Edge Function, QA fixture, storage object, or financial/inventory transaction was created or changed.

## 6. Deployment and authenticated E2E — outstanding evidence

The available Cloudflare dashboard tab snapshot showed automatic deployments enabled but its displayed latest Production source was still `be4647d`, older than LVE647 and this commit. The connected Parent tab snapshot was also stale: it still displayed the prior `RW_API is not defined` runtime message from before LVE647, not a post-LVE648 test. Browser access in this session was read-only; no reload, login, click, authenticated issuance, acknowledgement, or Finance E2E was performed.

Consequently:
- Source correction: **COMMITTED**.
- Inline-script syntax and controlled helper/scope simulation: **PASS**.
- Production deployment parity for `0c2327a` or its later descendant: **UNVERIFIED**.
- Post-deployment Parent Finance tab render and button-click E2E: **UNVERIFIED**.
- Real custody creation and employee acknowledgement: **NOT TESTED**; no test custody was intentionally created.

The separate Tailwind CDN production warning is unchanged and unrelated to the unresponsive issue button. The prior `RW_API` runtime report is also a separate LVE647 deployment-parity issue; it must not be conflated with this `_showToast` source correction.

## 7. Exact continuation gate

1. Confirm Cloudflare Production has deployed `0c2327a8bba6303b81d874aad843cd3243dab9ef` or a later descendant containing Parent blob `49a5726ac969fe5a88dcf77c652472ac5c179508`.
2. Reload the Parent system and authenticate. Open Finance → Employee Custody.
3. Confirm the ledger renders, no `_showToast is not defined` occurs, and `إصدار عهدة` opens the form with only the current user's eligible employees and allowed branches; select a branch and verify only same-branch active Cash non-POS treasuries appear.
4. Before any committed business test, define a tagged disposable QA fixture and full cleanup/reconciliation plan. Do not issue a real custody merely to prove that the button opens. A committed issue/acknowledgement test must follow the production-QA and cleanup rules in the constitution.
5. Close only after deployment parity, authenticated UI click, permission/branch rejection, form validation, and no-side-effect-before-acknowledgement checks are evidenced.

**Closure label:** `FIX COMMITTED — STATICALLY VALIDATED — DEPLOYMENT / AUTHENTICATED E2E UNVERIFIED`.
