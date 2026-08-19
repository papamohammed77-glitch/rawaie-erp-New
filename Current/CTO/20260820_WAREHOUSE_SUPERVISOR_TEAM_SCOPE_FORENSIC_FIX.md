# RAWAEA ERP — Warehouse Supervisor Team Scope Forensic Fix

Date: 2026-08-20

## Scope

This closure addresses the Warehouse Supervisor application requirement:

- The Warehouse Supervisor opens the application after authentication.
- The **فريقي** tab shows warehouse workers in the supervisor's active branch scope.
- The supervisor can change an individual worker's operational task among the currently approved warehouse tasks.
- The backend enforces the same branch boundary; the UI is not the security boundary.

## Historical / Current Source Reconciliation

Prompts 11–21 were reviewed as historical execution context only. They were not treated as Production truth.

The original `Original/PWA/warehouse/supervisor.html` established the historical roster concept and the operational task list:

- استلام
- تحضير
- تحميل
- مرتجعات
- تفريغ
- أذونات
- جرد
- احتياطي

The current `Current/PWA/warehouse.supervisor` already contained the later `set_active_warehouse_role` RPC integration and the Prompt-21 company-context fix (`users.id`, not `users.auth_id`).

## Production Facts Proven Before Change

Current Production uses `role = 'مخزني'` for warehouse workers. A direct Production query found 5 active users with this role in the supervisor's company. No active `role = 'أمين مخزن'` was present.

`warehouse.supervisor@rawaea.com` is the current Warehouse Supervisor and has `allowed_branch_ids = "BR-01"`.

The current worker records inspected for this company are also scoped to `BR-01`.

No new role name `أمين مخزن` was invented because it is not present in the current Production role model or in the current curated repository search.

## Root Cause / Gap Found

The existing Team UI was company-scoped only:

`users.company_id = supervisor.company_id AND role = 'مخزني'`

It did not restrict the visible team to the supervisor's branch.

The existing `set_active_warehouse_role` RPC also enforced company and warehouse-supervisor authorization but did not enforce branch membership.

Therefore the previous UI/backend pair could permit a supervisor-capable actor to attempt cross-branch reassignment.

## Surgical Implementation

### Application

`Current/PWA/warehouse.supervisor`

Updated to:

1. Resolve the supervisor's company using the existing Prompt-21-correct identity contract (`public.users.id`).
2. Resolve the supervisor branch scope from `default_branch_id` first, otherwise `allowed_branch_ids`.
3. Load branch metadata for the company and render the effective branch name(s).
4. Load active warehouse workers with `role = 'مخزني'` and filter the visible roster to workers whose branch scope intersects the supervisor's scope.
5. Show the supervisor's branch scope and each worker's scope in the Team tab.
6. Keep the approved operational task list unchanged.
7. Keep role changes on the existing `set_active_warehouse_role` RPC; no direct client-side write to `users` was introduced.

### Production RPC

`public.set_active_warehouse_role(uuid,text)` was updated as a surgical security/authorization closure.

It now:

- resolves the authenticated actor's company and branch scope;
- validates the target user belongs to the same company;
- validates the target is an active warehouse worker (`role = 'مخزني'`);
- compares actor and target branch scopes;
- rejects a target with no matching branch scope;
- preserves the existing warehouse-supervisor authorization and allowed operational roles.

No RLS policy was weakened and no password/Auth data was changed.

## Production Verification

### Positive transactional verification

Using the actual supervisor Auth identity:

- supervisor: `warehouse.supervisor@rawaea.com`
- target: `receiver@rawaea.com`
- actor branch scope: `BR-01`

The RPC successfully assigned `جرد`, returned `success=true`, and reported `branch_scope=["BR-01"]`.
The transaction was rolled back, so no persistent worker-role change was left by the test.

### Negative branch-isolation verification

Inside one transaction, the target worker's branch scope was temporarily changed to `BR-2`.

The same RPC call was then attempted by the real supervisor identity.

The RPC rejected the request with the proven branch-isolation error containing:

`خارج فرع المشرف`

The transaction was rolled back.

Verification result: **NEGATIVE_BRANCH_SCOPE_PASS**

## Git

Application commit:

`36db0401e9ab4e14932272687440689de52477fa`

The temporary workflow used during execution was removed immediately after the application commit.

## What Was Not Changed

- No new warehouse job title was invented.
- No RLS relaxation.
- No Auth/password changes.
- No direct browser update to `public.users`.
- No new task types beyond the already established eight-task contract.
- No change to inventory/accounting logic.

## Closure

Historical understanding: **RECONCILED**

Production identity/company context: **PROVEN**

Current Team UI: **UPDATED**

Branch-scoped backend authorization: **APPLIED + VERIFIED**

Cross-branch negative test: **PASS**

Persistent test-data contamination: **NONE (rollback verified)**

Remaining limitation: final interactive browser login with the real password is not asserted here because the password is not available to the agent. The previously diagnosed company-context lookup defect is already fixed at source level, and the team-scope backend contract is independently verified in Production.
