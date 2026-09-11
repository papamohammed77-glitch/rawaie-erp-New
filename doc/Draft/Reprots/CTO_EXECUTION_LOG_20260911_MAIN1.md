# RAWAEA ERP — CTO EXECUTION LOG
## MAIN1 FORENSIC RECOVERY — 2026-09-11

### Execution mode
- Governing source: MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.
- Historical reports are evidence only.
- Fresh Git and Production reconciliation performed before judgment.
- `Original/PWA/main/*` treated as immutable historical reference.
- `Current/PWA/main2/main1.md` treated as owner source; no direct source edit performed.

### Fresh synchronization — CONTINUATION
- Fresh Git `main` HEAD now verified: `a582fff10e5c9e24e187c7f77d16db608269f1d8`.
- Current Main1 SHA: `4d1b42250cfe2b3a8ec7d02b7b482eca8e27bade`.
- Original Main1 SHA: `14b12a471c20ad23a2c18f456dbc4d59783a0d1f`.
- Fresh Production timestamp: `2026-09-11 06:06:46.569077+00 UTC`.
- Production snapshot: companies=1, branches=2, users=24, items=17, customers=3, orders=0, purchase_orders=0, stock_branches=20, inventory_log=3, audit_log=1869.
- Fresh Production values supersede the earlier checkpoint timestamp; no business-data mutation was performed in this Main1 forensic review.

### MASTER reading gate
- MASTER CTO Governance & Continuous Execution OS SHA: `b03feec14a417ca9032d714774f2687b4542a373`.
- MASTER was read in consecutive chunks through EOF.
- EOF verified by the final marker `# END OF MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS`.

### Main1 reading gate
- Current Main1 read from line 1 through EOF.
- Current Main1 EOF verified at line 1100.
- Original Main1 read through EOF.
- Original source was not modified.

### Confirmed Main1 architecture
- Main1 owns the shell/control-plane layer: DOM shell, Auth bootstrap, canonical `RW_STATE`, permissions helper, workflow bootstrap, notifications, audit UI, data bootstrap, navigation.
- Main1 does not own `RW_Views`; the canonical view router is in `Current/PWA/main2/main10.md`.
- Canonical company state is `RW_STATE.app.company.id`.
- `users.auth_id` is protected by a UNIQUE constraint in Production.
- Active-user JWT metadata permissions currently match `public.users.permissions` for all active users queried.

### PROVEN MAIN1-A — Finance action authorization gap
Current Finance action entries on source line 895 have no `perm` or `view`. Since `RW_Navigation.buildSidebar().isAllowed()` currently returns true when neither exists, those action entries are exposed without Finance capability checks.

Production proof:
- Accountant: `finance`.
- Finance manager: `finance_manager`.
- Owner: `*` plus `isOwner=true`.
- Cashier: `pos`.
- Delivery users: `delivery`.

Owner surgery is stored in:
`doc/Draft/Reprots/OWNER_CHANGESETS_20260911_MAIN1.md`.

Surgery:
- Add `perm: ['finance','finance_manager']` to treasury, accounts, journal, receipts, payments, transfers, reports only.
- Do not add Finance permission to settlement.
- Replace the full `isAllowed(item)` function with the array-aware implementation in the Owner Change Set.

### PROVEN MAIN1-B — CRM capability mismatch
Current Main1 source line 902 is a `view: 'crm'` item, so authorization falls back to `RW_Permissions_check('crm')`.
Production proof: zero active users carry `crm`; seven active users carry `customers`.
Main10 maps `crm` to `customers`.

Required Main1 surgery:
```javascript
{ view: 'crm', icon: 'fa-handshake', label: 'إدارة علاقات العملاء (CRM)', perm: 'customers' },
```
No Main10 change is required for this CRM mapping once Main1 is merged.

### PROVEN MAIN1-C — HR cross-file capability conflict
Current Main1 source line 901 is:
```javascript
{ view: 'hr', icon: 'fa-id-card', label: 'الموارد البشرية' },
```
Production proof: one active user carries `hr`.
Main10 currently maps `hr` to `users`, so a legitimate HR user can be exposed by Main1 but rejected by the Main10 router.

Required Main1 surgery:
```javascript
{ view: 'hr', icon: 'fa-id-card', label: 'الموارد البشرية', perm: 'hr' },
```
Required paired Main10 dependency, to be handled during Main10 closure:
```javascript
'hr': 'hr',
```
replacing the current `hr -> users` mapping.

### Explicitly verified safe — no surgery
- `RW_Auth.login` uses `users.auth_id` and Production has `UNIQUE(auth_id)`.
- Company context is established from authenticated `public.users.company_id`.
- `RW_Data.loadItems/loadCustomers/loadBranches` are company-scoped.
- Main1 app settings lookup is company-scoped.
- Notifications are protected by own-user RLS and no unproven schema change is required.
- Audit log is protected by Owner RLS; no duplicate company column was invented in Main1.
- Workflow rules are global by current schema and were not incorrectly forced into company scope.
- No duplicate `RW_Views` was created.

### Exact owner-source surgery reference
Canonical Owner Change Set:
`doc/Draft/Reprots/OWNER_CHANGESETS_20260911_MAIN1.md`
Commit creating this artifact: `c98b31aad4275b1019fbbed1b5434d3fe634fa9f`.

### Verification gate after owner merge
1. Re-read Main1 to EOF.
2. Verify new Main1 SHA.
3. Accountant sees seven Finance actions.
4. Finance manager sees seven Finance actions.
5. Owner wildcard sees seven Finance actions.
6. Cashier sees none.
7. Delivery sees none.
8. Settlement remains controlled by `settlement`.
9. Customer-capable users see CRM.
10. HR user sees HR after Main10 dependency is closed.
11. No second company state or duplicate router is introduced.

### Closure status
- MASTER reading: CLOSED.
- Main1 current EOF reading: CLOSED.
- Main1 original EOF reading: CLOSED.
- Production synchronization: CLOSED for this Main1 cycle.
- Main1 forensic analysis: CLOSED.
- Main1-A: PROVEN / OWNER SURGERY READY.
- Main1-B CRM: PROVEN / OWNER SURGERY READY.
- Main1-C HR: PROVEN / OWNER SURGERY READY + Main10 dependency.
- Main1 source functional closure: OPEN until owner merges the prescribed surgical changes and affected routing is re-verified.
- Global Gold/Diamond: OPEN.

### False-closure protection
No claim is made that Main1 is functionally closed before its owner-source merge and SHA/runtime verification.
