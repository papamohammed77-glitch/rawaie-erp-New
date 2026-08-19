# RAWAEA ERP — Warehouse Supervisor Company Context Forensic Fix

Date: 2026-08-20

## Production Finding

The Warehouse Supervisor application failed after successful authentication with:

`خطأ سياق الشركة غير محدد`

The deployed `Current/PWA/warehouse.supervisor` resolved company context with:

`supabase.from('users').select('company_id').eq('auth_id', user.id || '').maybeSingle()`

This lookup was incorrect against the current `Current/PWA/core.js` contract.

## Root Cause Proven From Source

`RW_Auth.checkWarehouseRole()` in `Current/PWA/core.js` loads `public.users.id` into `pubUserId` and returns it as `user.id`.

Therefore:

- `user.id` in the supervisor application = `public.users.id`
- `auth.users.id` is available as the Auth session user id internally in `RW_Auth`, but is not returned as `user.id`

The supervisor application incorrectly compared:

`public.users.auth_id = public.users.id`

instead of:

`public.users.id = public.users.id`

This caused the company lookup to return no row and the application to throw `خطأ سياق الشركة غير محدد`.

## Production Evidence

`public.users` currently contains:

- email: `warehouse.supervisor@rawaea.com`
- public users.id: `dd77fab4-fad5-4e54-b71c-5c8400804542`
- company_id: `00000000-0000-0000-0000-000000000001`
- auth_id: `4c71e1b7-006a-4df4-ad4c-33d10b043536`
- role: `مشرف مخازن`
- status: `Active`
- permission: `warehouse_supervisor`

`auth.users` confirms the same authentication identity:

- auth id: `4c71e1b7-006a-4df4-ad4c-33d10b043536`
- email: `warehouse.supervisor@rawaea.com`
- confirmed_at present

RLS on `public.users` already permits an authenticated user to select the row when `auth_id = auth.uid()`. No RLS relaxation was required or introduced.

## Surgical Fix

The single company-context lookup in `Current/PWA/warehouse.supervisor` was changed from:

`eq('auth_id', user.id || '')`

to:

`eq('id', user.id || '')`

No other behavior, authorization rule, RPC, RLS policy, or database data was changed for this fix.

## Git

Production source commit:

`f0b668bdf12615bc8965dd8f1090a4079b8da814`

Updated file blob:

`eba134d1cd9878b6e801782371d1c82dbcb94d84`

## Verification

- Old incorrect source pattern is no longer found by repository search.
- Current source explicitly uses `users.id = user.id` for company resolution.
- Production database identity mapping was independently verified before the code change.
- No password or authentication data was altered.
- No RLS policy was weakened.

## Closure State

Root cause: **PROVEN**

Code fix: **APPLIED TO MAIN**

Production data repair: **NOT REQUIRED**

RLS change: **NOT REQUIRED**

Runtime login re-test with the real user credentials: **PENDING USER-SIDE BROWSER VERIFICATION**

Reason: the assistant does not possess or infer the user's password and therefore cannot perform the final interactive password login itself.

The previously observed company-context failure is nevertheless directly eliminated by the deployed source change because the erroneous identifier crossing was proven at source level.
