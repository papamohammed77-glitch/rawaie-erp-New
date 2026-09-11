# RAWAEA ERP — CTO EXECUTION LOG
## MAIN1 FORENSIC RECOVERY — 2026-09-11

### Execution mode
- Governing source: MASTER CTO EXECUTION OS — RAWAEA ERP — Forensic Recovery, Full Functional Completion & Gold-Diamond Closure.
- Historical reports are evidence only.
- Fresh Git and Production reconciliation performed before judgment.
- `Original/PWA/main/*` treated as immutable historical reference.
- `Current/PWA/main2/main1.md` treated as owner source; no direct source edit is performed by this execution log.

### Fresh synchronization
- Git `main` HEAD at execution start: `9772a0c9c882b0c3c25e2d81763ec8229740d5c4`.
- Current Main1 SHA: `4d1b42250cfe2b3a8ec7d02b7b482eca8e27bade`.
- Original Main1 SHA: `14b12a471c20ad23a2c18f456dbc4d59783a0d1f`.
- Production timestamp: `2026-09-11 04:27:11.929726+00 UTC`.
- Production snapshot: companies=1, branches=2, users=24, items=17, customers=3, orders=0, purchase_orders=0, stock_branches=20, inventory_log=3, audit_log=1869.
- Fresh Production state was re-queried after the prior task was stopped; stale historical snapshots were not used as truth.

### Main1 reading gate
- Current Main1 read from line 1 through EOF.
- Original Main1 read through EOF using the original blob.
- Original source was not modified.

### Confirmed Current-vs-Original preservation
The following Current changes are confirmed intentional hardening relative to Original:
- authenticated user is resolved against `public.users` using `auth_id`;
- company context is loaded from the authenticated user's database record;
- inactive users are rejected;
- `RW_STATE.app.company.id` is populated from the database company id;
- app settings are company-scoped;
- items/customers/branches/suppliers are company-scoped;
- JWT permissions are populated from user metadata and were directly matched against `public.users.permissions` in Production for all active users checked.

### Production permission evidence
- Accountant role uses `finance`.
- Finance manager role uses `finance_manager`.
- Owner retains wildcard `*` and `isOwner=true`.
- JWT permission arrays and `public.users.permissions` were matched for the active users queried; no observed permission drift was found.

### Defect MAIN1-A — Finance action authorization gap
Current Main1 `RW_Navigation.menuTree` contains Finance action entries:
`showFinanceTab/treasury`, `accounts`, `journal`, `receipts`, `payments`, `transfers`, `reports`.
These entries have no `perm` and no `view`. `buildSidebar().isAllowed()` returns `true` when neither is present. Therefore the Finance action buttons are exposed to users who do not carry Finance capability.

This is proven from the Current source structure and the Production permission model; it is not inferred from role names alone.

### Required owner-source surgery MAIN1-A
FILE: `Current/PWA/main2/main1.md`

Region: `RW_Navigation.menuTree`, around the Finance submenu in the Current file (the exact source line is the single Finance submenu entry beginning with `{ icon: 'fa-coins', label: 'إدارة الحسابات والمالية' ... }`).

DIRECT CHANGE:
Add `perm: ['finance','finance_manager']` to each of the seven `showFinanceTab` child objects only:
- treasury
- accounts
- journal
- receipts
- payments
- transfers
- reports

Do NOT add this permission to the `settlement` item because `settlement` is a distinct capability and is already represented by its own `view` key.

Region: `RW_Navigation.buildSidebar().isAllowed()`.

FULL REPLACEMENT REQUIRED:
Replace only the `isAllowed(item)` function with an implementation that preserves current owner semantics, single-string permissions, view permissions, and additionally accepts an array of alternative permissions:

```javascript
function isAllowed(item) {
    if (item.perm === 'owner') {
        return (RW_STATE.app.currentUser && RW_STATE.app.currentUser.isOwner === true);
    }
    if (Array.isArray(item.perm)) {
        for (var p = 0; p < item.perm.length; p++) {
            if (RW_Permissions_check(item.perm[p])) return true;
        }
        return false;
    }
    if (item.perm) {
        return RW_Permissions_check(item.perm);
    }
    if (item.view) {
        return RW_Permissions_check(item.view);
    }
    return true;
}
```

VERIFICATION after owner applies surgery:
1. Accountant JWT (`finance`) sees all seven Finance action entries.
2. Finance-manager JWT (`finance_manager`) sees all seven Finance action entries.
3. Owner wildcard sees all seven.
4. Cashier (`pos`) does not see Finance actions.
5. Delivery user (`delivery`) does not see Finance actions.
6. Settlement visibility remains governed by `settlement` and is not widened/narrowed by the Finance fix.
7. Reopen the full Main1 file to EOF and verify SHA/text after the owner edit.

### Defect MAIN1-B — Cross-file State Contract mismatch
Current Main1 defines the canonical state as `RW_STATE.app.company.id` and populates it from `public.users.company_id`.
Current Main8 `RW_Finance._companyId()` searches for `RW_STATE.app.companyId` or `RW_STATE.user.companyId` and does not reference `RW_STATE.app.company.id`.
This is a confirmed cross-file contract mismatch.

Required architectural choice:
- Keep `RW_STATE.app.company.id` as canonical because Main1 and its own data/bootstrap readers consistently use it.
- Fix the Main8 `_companyId()` consumer to read `RW_STATE.app.company.id` first.
- Do not add a second persistent company-id source in Main1 merely to mask the consumer defect.

Main1 itself is therefore not to be modified for MAIN1-B.

### Main1 closure status
- Reading: CLOSED.
- Historical pair reading: CLOSED.
- Historical preservation: CLOSED / Original untouched.
- Production synchronization gate: CLOSED for this execution cycle.
- Authorization defect: PROVEN / SURGERY READY.
- Cross-file Finance state defect: PROVEN / Main8 surgery required.
- Main1 source closure: NOT YET CLOSED because required owner-source surgery has not yet been applied and SHA-verified.

### False-closure protection
No Gold, Diamond, Assembly Ready, Runtime Closed, or Main1 Fully Closed claim is made from this log.
