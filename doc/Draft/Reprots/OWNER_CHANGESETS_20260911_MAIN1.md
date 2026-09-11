# RAWAEA ERP — OWNER SOURCE CHANGE SET
## MAIN1 — 2026-09-11

## Governing rule
`Current/PWA/main2/main1.md` is owner-editable source. This file contains exact surgical replacements only; it does not modify the owner source automatically.

## Source
- File: `Current/PWA/main2/main1.md`
- Current SHA: `4d1b42250cfe2b3a8ec7d02b7b482eca8e27bade`
- Current EOF: line 1100
- Original SHA: `14b12a471c20ad23a2c18f456dbc4d59783a0d1f`

---

## MAIN1-A — Finance authorization on action submenu

### Proven defect
The Finance submenu is one source line at current source line 895. Its seven `showFinanceTab` action objects have neither `perm` nor `view`. The current `isAllowed(item)` therefore reaches `return true` for these actions. Production proves the intended capabilities are `finance` for the accountant, `finance_manager` for the finance manager, and `*` for the owner.

### Exact defective element
Replace the entire current line beginning exactly with:
```javascript
{ icon: 'fa-coins', label: 'إدارة الحسابات والمالية', submenu: [{ action: 'showFinanceTab', arg: 'treasury', label: 'الخزائن والبنوك' }, { action: 'showFinanceTab', arg: 'accounts', label: 'دليل الحسابات' }, { action: 'showFinanceTab', arg: 'journal', label: 'قيود يومية' }, { action: 'showFinanceTab', arg: 'receipts', label: 'سندات القبض' }, { action: 'showFinanceTab', arg: 'payments', label: 'سندات الصرف' }, { action: 'showFinanceTab', arg: 'transfers', label: 'التحويلات' }, { action: 'showFinanceTab', arg: 'reports', label: 'التقارير المالية' }, { view: 'settlement', label: 'إغلاق اليومية' }] },
```

### Full replacement
```javascript
{ icon: 'fa-coins', label: 'إدارة الحسابات والمالية', submenu: [{ action: 'showFinanceTab', arg: 'treasury', label: 'الخزائن والبنوك', perm: ['finance', 'finance_manager'] }, { action: 'showFinanceTab', arg: 'accounts', label: 'دليل الحسابات', perm: ['finance', 'finance_manager'] }, { action: 'showFinanceTab', arg: 'journal', label: 'قيود يومية', perm: ['finance', 'finance_manager'] }, { action: 'showFinanceTab', arg: 'receipts', label: 'سندات القبض', perm: ['finance', 'finance_manager'] }, { action: 'showFinanceTab', arg: 'payments', label: 'سندات الصرف', perm: ['finance', 'finance_manager'] }, { action: 'showFinanceTab', arg: 'transfers', label: 'التحويلات', perm: ['finance', 'finance_manager'] }, { action: 'showFinanceTab', arg: 'reports', label: 'التقارير المالية', perm: ['finance', 'finance_manager'] }, { view: 'settlement', label: 'إغلاق اليومية' }] },
```

### Explicit non-change
Do not add Finance permission to `settlement`; it remains governed by the `settlement` view permission.

---

## MAIN1-B — Array-aware authorization evaluator

### Exact current function
The current `isAllowed(item)` function is located in `RW_Navigation.buildSidebar()` and begins with the exact text:
```javascript
function isAllowed(item) {
```
Current source location: approximately lines 960-970; re-identify by exact function text, not by description.

### Full replacement
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

### Contract preserved
- Owner semantics remain `isOwner === true`.
- Existing single-string `perm` remains supported.
- Existing `view` fallback remains supported.
- New array form means OR semantics across alternative permissions.
- No wildcard semantics are reimplemented here; they remain inside `RW_Permissions_check`.

---

## MAIN1-C — CRM capability mapping

### Proven defect
Current Main1 menu line 902 is:
```javascript
{ view: 'crm', icon: 'fa-handshake', label: 'إدارة علاقات العملاء (CRM)' },
```
Main1 authorization derives the permission from `view`, producing `RW_Permissions_check('crm')`. Production has zero active users with `crm`, while seven active users have `customers`. Main10's router separately maps `crm` to `customers`. Therefore the current Main1 menu hides CRM from legitimate customer-capable users unless they are Owner.

### Full replacement
```javascript
{ view: 'crm', icon: 'fa-handshake', label: 'إدارة علاقات العملاء (CRM)', perm: 'customers' },
```

### Dependency
Main10 already maps `crm` to `customers`; no Main10 change is required for this specific capability once Main1 uses the explicit `customers` permission.

---

## MAIN1-D — HR capability consistency / cross-file dependency

### Proven cross-file conflict
Current Main1 menu line 901 is:
```javascript
{ view: 'hr', icon: 'fa-id-card', label: 'الموارد البشرية' },
```
Main1 authorization derives `hr`. Production has one active user with `hr`. Main10 currently maps `hr` to `users`, which would reject that legitimate HR user in the router even if Main1 displays the menu item.

### Main1 change
```javascript
{ view: 'hr', icon: 'fa-id-card', label: 'الموارد البشرية', perm: 'hr' },
```

### Required paired Main10 dependency
When Main10 is processed, replace only the `hr` permission-map entry:
```javascript
'hr': 'users',
```
with:
```javascript
'hr': 'hr',
```
This is intentionally not applied during Main1 closure because it belongs to the Main10 owner source and would otherwise create a half-fixed cross-file capability.

---

## MAIN1-E — Verified safe / no surgery
The following were inspected and deliberately left unchanged:
- `RW_Auth.login` uses `users.auth_id`; Production has `UNIQUE(auth_id)`.
- Company context is loaded from `public.users.company_id`.
- `RW_STATE.app.company.id` is the canonical frontend company state.
- `RW_Data.loadItems/loadCustomers/loadBranches` are company-scoped.
- `app_settings` access in Main1 is company-scoped.
- `notifications` are protected by own-user RLS; no unproven company-column retrofit is required.
- `audit_log` is owner-only through RLS; no schema retrofit was invented.
- `workflow_rules` are global by schema/contract and were not incorrectly forced into company scope.
- `RW_Views` is owned by Main10; no duplicate router was added to Main1.

## Required verification after owner merge
1. Re-read Main1 from line 1 through EOF.
2. Confirm current Main1 SHA has changed from `4d1b42250cfe2b3a8ec7d02b7b482eca8e27bade`.
3. Accountant with `finance` sees all seven Finance actions.
4. Finance manager with `finance_manager` sees all seven.
5. Owner with `*` sees all seven.
6. Cashier with `pos` sees none of those seven.
7. Delivery with `delivery` sees none of those seven.
8. `settlement` remains controlled by `settlement`.
9. Customer-capable users see CRM.
10. HR user sees HR only after Main10 router dependency is also corrected.
11. No duplicate `RW_Views` or second company-state source was introduced.

## Closure gate
`MAIN1 FORENSIC REVIEW = CLOSED`
`MAIN1 OWNER SOURCE = OPEN UNTIL MERGED AND SHA-VERIFIED`
`MAIN1 FUNCTIONAL CLOSURE = OPEN UNTIL MAIN1-A/C/D ARE MERGED AND MAIN10 HR DEPENDENCY IS CLOSED`
`GLOBAL GOLD/DIAMOND = OPEN`
