# RAWAEA ERP — MAIN1 OWNER-SOURCE SURGERY
## 2026-09-11

This file is an exact surgical instruction generated after full Current/Original Main1 forensic review and fresh Production reconciliation.

**Important boundary:** `Current/PWA/main2/main1.md` is Owner Source Surgery territory under the governing MASTER CTO EXECUTION OS. Do not apply an unrelated rewrite, merge, formatting pass, or speculative refactor.

---

## SURGERY A — Finance Navigation Authorization

### File
`Current/PWA/main2/main1.md`

### Current source
In `RW_Navigation.menuTree`, the Finance submenu currently contains this exact object:

```javascript
{ icon: 'fa-coins', label: 'إدارة الحسابات والمالية', submenu: [{ action: 'showFinanceTab', arg: 'treasury', label: 'الخزائن والبنوك' }, { action: 'showFinanceTab', arg: 'accounts', label: 'دليل الحسابات' }, { action: 'showFinanceTab', arg: 'journal', label: 'قيود يومية' }, { action: 'showFinanceTab', arg: 'receipts', label: 'سندات القبض' }, { action: 'showFinanceTab', arg: 'payments', label: 'سندات الصرف' }, { action: 'showFinanceTab', arg: 'transfers', label: 'التحويلات' }, { action: 'showFinanceTab', arg: 'reports', label: 'التقارير المالية' }, { view: 'settlement', label: 'إغلاق اليومية' }] },
```

### Replacement
Replace that single line with:

```javascript
{ icon: 'fa-coins', label: 'إدارة الحسابات والمالية', submenu: [{ action: 'showFinanceTab', arg: 'treasury', perm: ['finance', 'finance_manager'], label: 'الخزائن والبنوك' }, { action: 'showFinanceTab', arg: 'accounts', perm: ['finance', 'finance_manager'], label: 'دليل الحسابات' }, { action: 'showFinanceTab', arg: 'journal', perm: ['finance', 'finance_manager'], label: 'قيود يومية' }, { action: 'showFinanceTab', arg: 'receipts', perm: ['finance', 'finance_manager'], label: 'سندات القبض' }, { action: 'showFinanceTab', arg: 'payments', perm: ['finance', 'finance_manager'], label: 'سندات الصرف' }, { action: 'showFinanceTab', arg: 'transfers', perm: ['finance', 'finance_manager'], label: 'التحويلات' }, { action: 'showFinanceTab', arg: 'reports', perm: ['finance', 'finance_manager'], label: 'التقارير المالية' }, { view: 'settlement', label: 'إغلاق اليومية' }] },
```

Do not add Finance permission to `settlement`; it remains a distinct `settlement` capability.

### Current `isAllowed(item)`
The current function is:

```javascript
function isAllowed(item) {
    if (item.perm === 'owner') {
        return (RW_STATE.app.currentUser && RW_STATE.app.currentUser.isOwner === true);
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

### Full replacement
Replace the entire function with:

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

### Why this is the selected repair
Production role data proves:
- Accountant capability: `finance`.
- Finance Manager capability: `finance_manager`.
- Owner capability: `*`, with `isOwner=true`.

The repair preserves all existing string permissions, owner semantics, and independent `settlement` access while closing the Finance action authorization gap.

---

## SURGERY B — DO NOT PATCH MAIN1 FOR THE FINANCE STATE MISMATCH

Current Main1 canonical state is:

```javascript
RW_STATE.app.company.id
```

Current Main8 `_companyId()` instead checks:

```javascript
RW_STATE.app.companyId
RW_STATE.user.companyId
```

This is a confirmed consumer mismatch. Do not create a second company-id source in Main1 to hide the defect.

Required later closure: repair `Current/PWA/main2/main8.md` `_companyId()` to consume `RW_STATE.app.company.id` as the canonical state.

---

## POST-SURGERY VERIFICATION — MANDATORY

1. Re-open `Current/PWA/main2/main1.md` from line 1 through EOF.
2. Confirm the seven Finance action entries carry `perm: ['finance', 'finance_manager']`.
3. Confirm `isAllowed(item)` is exactly the replacement above.
4. Confirm `settlement` is unchanged and still uses `view: 'settlement'`.
5. Confirm login/Auth/company-state code is otherwise unchanged.
6. Confirm `Original/PWA/main/main1.md` SHA remains `14b12a471c20ad23a2c18f456dbc4d59783a0d1f`.
7. Record the new Current Main1 SHA.
8. Run UI authorization checks with Production-matching permission sets:
   - `finance` => seven Finance actions visible.
   - `finance_manager` => seven Finance actions visible.
   - `*` / Owner => visible.
   - `pos` => hidden.
   - `delivery` => hidden.
   - `settlement` remains independently controlled.
9. Only after those checks can Main1-A move from `SURGERY READY` to `PRODUCTION-VERIFIED`.

No assembly or Gold/Diamond closure may be inferred from this surgery alone.
