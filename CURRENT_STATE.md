# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-13  
**Current checkpoint:** Report150 — CTO E2E Login Runtime `_cashFlow` forensic closure.

## CRITICAL GOVERNANCE PRINCIPLE

**الـSource of Truth الوحيد لاختبار النظام الأم هو الملف المنشور الحالي:**

```text
https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/main.html
```

لا يتم استخدام `Current/PWA/main2` أو `Original/PWA/main` أو أي تقرير تاريخي كمصدر حقيقة للكود الحالي. هذه الملفات مرجعية/تاريخية فقط.

## Current Published Main Identity

```text
Repository = papamohammed77-glitch/erp-frontend
Branch = main
Latest inspected commit = a91bae00418b040a8687547cf2437036f8661b0d
Current main.html blob SHA = 26a8148682685e20f54b2cac074d898ee4ba5264
HTML source timestamp comment = 2026-09-13 07:00 UTC
```

Commit `a91bae00418b040a8687547cf2437036f8661b0d` is the direct descendant of Report149's inspected commit and contains the seven syntax corrections from Report149.

## Report149 Status Reconciled

Report149 originally identified seven JavaScript Syntax roots. The current published source has advanced beyond that failure: the present Console reaches runtime initialization and no longer reports those seven syntax errors.

Therefore:

```text
REPORT149 SYNTAX ROOT = NO LONGER ACTIVE IN CURRENT SOURCE
```

The seven Report149 fixes must not be re-applied unless future evidence proves a regression.

## Report150 — Current Runtime Root

```text
doc/Draft/Reprots/Report150_CTO_E2E_Login_Runtime_CashFlow_20260913.md
```

The current browser Console reports:

```text
main:174  ✅ Supabase Client initialized successfully
main:11967  Uncaught ReferenceError: _cashFlow is not defined
    at main:11967:12
    at main:11976:3
    at main:17476:3
```

### Root cause proven directly

Inside the current `RW_Finance` IIFE:

- `_renderReports()` contains a real `RW_Finance._cashFlow()` button.
- The public return object contains:
  ```javascript
  _cashFlow: _cashFlow,
  ```
- No `function _cashFlow() { ... }` declaration exists in the current Finance module.

This causes a top-level runtime `ReferenceError` while the Finance module is being evaluated, which can abort subsequent script initialization and therefore block Login from becoming operational.

### Exact current location

The current return object around line **11967** contains:

```javascript
_balanceSheet: _balanceSheet,
_cashFlow: _cashFlow,
_accountActivity: _accountActivity,
```

The missing function must be inserted before the current:

```javascript
    function _costCenterProfitLoss() {
```

which is currently around line **11756**.

## Production Contract Verified

Production Supabase currently contains:

```text
public.get_cash_flow(p_from_date date, p_to_date date)
```

Return contract:

```text
category
account_id
account_name
amount
```

The function resolves tenant context through:

```text
app_private.current_user_company_id()
```

and that helper resolves the company from `auth.uid()` against the `users` table.

A transactional runtime test using a real active company user context completed without an RPC error. No persistent Production data was changed by this test.

## Tailwind Warning

```text
cdn.tailwindcss.com should not be used in production
```

This remains a Warning and is not the current runtime root. It does not justify changing Login or the Finance bootstrap in this Closure Unit.

## Owner Surgical Fix — FIX-150-01

The assistant did **NOT** modify the Source-of-Truth `erp-frontend/companies/company-1/main.html`.

Owner action:

1. Open the current published `main.html`.
2. Find the exact line:
   ```javascript
       function _costCenterProfitLoss() {
   ```
   Current location: approximately **line 11756**.
3. Add the complete `_cashFlow()` function recorded verbatim in:
   ```text
   doc/Draft/Reprots/Report150_CTO_E2E_Login_Runtime_CashFlow_20260913.md
   ```
   directly above that line.
4. Do **not** delete or modify `_costCenterProfitLoss()`.
5. Do **not** delete `_cashFlow: _cashFlow,` from the return object at line **11967**.
6. The last complete line of the inserted function must be exactly:
   ```javascript
       }
   ```
7. Redeploy the same `companies/company-1/main.html`.

## Supabase / Production Changes in Report150

```text
SUPABASE CHANGE = NONE REQUIRED
```

The required cash-flow read contract already exists in Production. No new table, RPC, trigger, or column was invented for this frontend defect.

## Assembly Source-of-Truth

`forensic_main_assembly.yml` remains correctly aligned to the published main:

```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
```

`Current/PWA/main2` remains reference/history only and is not a current reconstruction source.

## Session Restore Defect

A separate previously proven defect remains open:

```text
boot() restores RW_STATE.app.company name/logo but not RW_STATE.app.company.id
```

This is a separate Closure Unit and must not be mixed into the current `_cashFlow` repair unless new E2E evidence requires it.

## What Was Changed in This Checkpoint

```text
rawwaie-erp-New/doc/Draft/Reprots/Report150_CTO_E2E_Login_Runtime_CashFlow_20260913.md = CREATED
rawwaie-erp-New/CURRENT_STATE.md = UPDATED

erp-frontend/companies/company-1/main.html = NOT MODIFIED BY ASSISTANT
Supabase Production = NOT MODIFIED
```

## Closure Status

```text
CURRENT MAIN SOURCE IDENTITY = VERIFIED
CURRENT PUBLISHED SHA = 26a8148682685e20f54b2cac074d898ee4ba5264
REPORT149 SYNTAX BLOCKER = SUPERSEDED / NO LONGER ACTIVE IN CURRENT SOURCE
CURRENT RUNTIME BLOCKER = `_cashFlow` MISSING
CURRENT ROOT CAUSE = PROVEN
PRODUCTION `get_cash_flow` CONTRACT = PROVEN
FIX-150-01 = READY / OWNER APPLICATION REQUIRED
POST-FIX NODE PARSE = PENDING
POST-FIX BROWSER RUNTIME = PENDING
POST-FIX LOGIN E2E = OPEN
SESSION RESTORE COMPANY-ID DEFECT = OPEN / SEPARATE
GLOBAL FUNCTIONAL GOLD/DIAMOND = OPEN
```

## Exact Next Checkpoint

After FIX-150-01 is applied and the file is redeployed:

```text
1. Re-read current Git SHA/blob.
2. Extract inline JavaScript preserving original line numbers.
3. node --check = PASS.
4. Open fresh incognito session.
5. Confirm `_cashFlow is not defined` is gone.
6. Confirm RW_Finance initializes.
7. Confirm login form binding initializes.
8. Submit valid Login.
9. Confirm auth session.
10. Confirm users/company context.
11. Confirm enterSystem().
12. Confirm dashboard appears.
13. Record the next actual Console/runtime issue, if any.
```

No new failure may be invented before this checkpoint.

# END CURRENT STATE