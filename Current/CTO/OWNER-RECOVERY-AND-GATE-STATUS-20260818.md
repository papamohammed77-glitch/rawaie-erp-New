# RAWAEA ERP — OWNER RECOVERY / HTTP GATE STATUS

Date: 2026-08-18
Execution basis: Live Production reconciliation

## 1. Owner identity recovered from evidence

Production `public.owner_profile` preserved:
- owner_name: `المالك العام`
- owner_email: `owner@alrawae.com`
- license_status: `active`
- historical auth_user_id: `0a6089e6-0c33-4162-a8bc-88b5e39d5180`

Historical `audit_log` proves this identity previously logged into the production system as role `مدير النظام`.

## 2. Damage found

The historical Auth principal and its `public.users` mapping were absent from current Production.

Current `auth.users` contains no row for the historical owner email or historical auth UUID.

Therefore the failure is an Auth principal / application identity-link failure, not loss of the owner_profile record.

## 3. Restored application-side owner state

Production now contains:
- `public.roles`: system role `مدير النظام`
- `is_system = true`
- 41 application permission keys, using the current production permission vocabulary
- `public.users.owner@alrawae.com`: Active, role `مدير النظام`, company scope = production company, allowed_branch_ids = `["*"]`
- `public.owner_profile.auth_user_id` restored to the historical UUID
- audit record documenting the restoration scaffold

`public.users.auth_id` intentionally remains NULL until the official Supabase Auth principal is recreated because the FK prevents an orphaned auth_id.

## 4. Why Auth principal was not fabricated through SQL

Direct writes to `auth.users` are blocked by the execution security boundary of the available database tool. No internal schema bypass was used.

A temporary production Edge recovery function was created to perform the official Admin Auth creation path, but it was not invoked because the current toolchain has no safe direct Edge HTTP invocation path. The temporary gate was therefore retired to HTTP 410 and not left exposed.

## 5. Production permission model confirmed

Actual authorization is driven by:
- `public.users.permissions`
- OR `public.roles.permissions`

via `app_private.current_user_has_permission()`.

Company resolution is driven by `public.users.auth_id -> company_id` via `app_private.current_user_company_id()`.

## 6. HTTP Gate status

`picker@rawaea.com` exists in Auth and has a matching active warehouse user identity. Its current password is not available through the approved tooling and was not guessed or extracted.

The final Production HTTP gate therefore remains unverified. Core/static/data-integrity verification is not being mislabeled as HTTP E2E.

## 7. Required manual actions — exact

A. In Supabase Authentication → Users, recreate/restore `owner@alrawae.com` as an email user with email confirmed. After this is done, `public.users` can be linked to the created auth UUID by email without changing the reconstructed role/permissions.

B. For `picker@rawaea.com`, provide an approved temporary authentication method (password reset performed in Supabase Auth is sufficient). This is required only to obtain a real user session for the live `complete-picking` HTTP E2E gate.

No other manual project action is currently required by this investigation.

## 8. Truth standard

No `100% CLOSED` claim is made while:
- owner Auth principal is absent
- final live HTTP E2E remains unverified

## 9. Evidence boundary

This record is based on live Production queries at execution time plus Historical audit evidence. Previous CTO reports are treated as snapshots, not current truth.
