# Report722 — هوية دخول داخلية بلا بريد حقيقي أو SMTP أو SMS
**التاريخ:** 2026-11-14 (Africa/Cairo)  
**Last Verified Event:** LVE-2026-11-14-722  
**Previous checkpoint:** LVE-2026-11-14-721  
**SMART ERP:** `fiilmooggumokxanwiyx` — ACTIVE_HEALTHY — eu-west-1  
**Operational repository:** `papamohammed77-glitch/erp-frontend` / `main`  
**Operational HEAD verified:** `2fcccd240f5ce8acf53b438ac9ec7a65f54e11e0`  
**Status:** ZERO-COST NO-MAIL ARCHITECTURE CONFIRMED FROM EXISTING CODE; OWNER CHANGESET PREPARED FOR REVIEW; NO PRODUCTION CONFIG/CODE/DATA MUTATION.

## 1. Correction to prior recommendation
The earlier Report721's Brevo Free SMTP proposal is superseded for the current RAWAEA stage. The owner clarified that:
- `rawaea.com` is not a registered/controlled domain.
- All addresses such as `picker@rawaea.com` and `owner@alrawae.com` are artificial test login identifiers, not real mailboxes.
- The project requires zero external-service/domain/SMS spend, including in later phases unless commercial success justifies an explicit future decision.

There is no reason to acquire a domain, create a Brevo account, configure Gmail SMTP, use SMS, or pay for any delivery provider while these strings are only internal login identifiers.

## 2. Root cause — CONFIRMED
The owner-email UI currently uses the client-side Supabase Auth email-update flow (`auth.updateUser({email})`). That path is designed for real email identities and starts the confirmation-email flow; under Supabase built-in SMTP it encounters the project-wide quota (2 messages/hour while Confirm Email is enabled).

Employee account lifecycle is already implemented using a different no-mail server-side pattern:
- Production Edge Function `save-employee`, Version 10, ACTIVE, `verify_jwt=true`.
- It authenticates the acting user using a bearer token, checks company scope and owner/explicit `users` permission, and protects owner accounts from ordinary employee edits.
- For account creation it calls `db.auth.admin.createUser({ email, password, email_confirm: true, user_metadata: ... })`.
- For an employee email change it calls `db.auth.admin.updateUserById(existing.auth_id, { email, email_confirm: true, ... })`.
- These Auth Admin calls directly manage test login identities and do not ask the recipient to confirm a mailbox. This existing pattern is the correct design reference for artificial internal identifiers.

The owner differs because the owner UI uses public/client `updateUser`, not because the project must send mail for every account.

A second existing server-side component is suitable for a surgical owner-only path:
- Edge Function `save-settings`, Version 15, ACTIVE, `verify_jwt=true`.
- It already uses the service-role client only on the server.
- It validates the bearer token via `auth.getUser(token)`.
- It loads the public user by `auth_id`, verifies active status/company, checks the matching `owner_profile`, and checks owner metadata/wildcard before allowing owner-license settings changes.
- It already has the correct owner-gated route and needs no new Edge Function.

## 3. Live data/schema verification — READ ONLY
Current Auth/public identity join for the owner:
- Auth email: `owner@alrawae.com`
- public.users.email: `owner@alrawae.com`
- owner_profile.owner_email: `owner@alrawae.com`
- public.users.auth_id and owner_profile.auth_user_id both match the Auth user ID.
- Email confirmed; no pending change (`email_change` empty, `email_change_sent_at` NULL, confirmation status 0); not banned.
- Public user active, permissions `["*"]`, owner license active.

Catalog inspection for functions containing `email` or `owner` found:
- `auth.email()`
- `public.owner_license_admin_atomic(...)`
- No existing owner email synchronization RPC.
Previous investigation found no trigger synchronizing `auth.users.email`, `public.users.email`, and `public.owner_profile.owner_email`.

Existing `save-settings` passes the current Auth email as `p_actor_email` to central RPCs; `owner_license_admin_atomic` requires that value to match `public.users.email`. These three values must remain aligned after any owner identity update.

No production data, Auth identity, confirmation configuration, schema, code, permissions, stock, cash, or journal entry changed in this event.

## 4. Selected permanent zero-cost architecture
Treat the current email-shaped strings as **internal login aliases**, not reachable email addresses:
- Keep the current aliases (for example `picker@rawaea.com`) as stable unique Auth identifiers unless an owner-controlled rename is actually required.
- No DNS domain, mailbox, SPF/DKIM, SMTP service, email API, or SMS provider is required to perform email/password sign-in against an already-created Auth user. Password sign-in verifies the stored identity and password; it does not deliver mail.
- Keep employee contact phone/email as optional profile/contact data and do not conflate them with authentication identity.
- Do not add phone OTP as a replacement; it requires a real SMS delivery provider and creates a per-message cost. Phone-number recycling also makes phone identity less stable.
- No bulk rename or deletion of the 36 Auth accounts is required.

### Owner email/login-alias update
Do not call client-side `supabase.auth.updateUser({ email })` for synthetic aliases.

Prepare an owner-only action in existing `save-settings`:
1. Validate bearer token using Auth server and obtain current user ID and current email.
2. Verify active public user, `user_metadata.isOwner=true`, `permissions=['*']`, and matching `owner_profile.auth_user_id`; re-check the exact owner contract before mutation.
3. Validate the new login alias; reject whitespace/invalid syntax; check Auth and public email uniqueness.
4. Capture old Auth/public/owner-profile values.
5. Call server-side `auth.admin.updateUserById(authUser.id, { email: newAlias, email_confirm: true })`. The Auth Admin API applies changes directly without the end-user confirmation flow and must only execute server-side.
6. Call a narrowly scoped SQL RPC (proposed name: `owner_email_sync_atomic`) to update `public.users.email` and `public.owner_profile.owner_email` in one DB transaction. The RPC must:
   - Require service-role execution only (revoke default PUBLIC/anon/authenticated execute grants).
   - Verify the target Auth user ID and old values still match the expected owner record.
   - Verify owner_profile linkage and wildcard/active user contract.
   - Reject duplicate new email aliases case-insensitively.
   - Update only the exact owner row and its owner_profile row; no other users.
   - Write an audit event containing old/new values and actor ID without including passwords/secrets.
7. If the DB RPC fails, restore the Auth email to the captured old value via server-side Admin API and report a hard failure. If compensation fails, return a critical reconciliation error and stop further owner operations; never report success.
8. Refresh the browser session after success, re-run `RW_Auth.init()`, and confirm the same Auth UUID, owner profile, wildcard permission, and aligned email values.
9. Leave the current user ID/auth_id unchanged. Do not touch password, role, permissions, license, or other identity metadata.

This is a compensating two-system transaction (Supabase Auth Admin API + Postgres RPC), not a literal single distributed transaction. The code must be idempotent and handle concurrent requests with a lock/compare-old-value guard.

### Password lifecycle without email
- Changing an already-authenticated user's password can remain an in-session operation after recent authentication/current-password validation.
- Employee administrative password reset is already supported through `save-employee` on an authorized server-side path (the function sets `authAttrs.password` when supplied).
- The current `resetPasswordForEmail` UI is not usable for fictitious addresses; it should be replaced by an internal “request administrator reset” process or an owner/admin controlled reset. No email recovery link should be offered for synthetic aliases.
- Owner account recovery must be via Supabase project-owner control plane/manual reset until a separately reviewed offline recovery mechanism is implemented. The two historical owner-recovery Edge Functions inspected here are retired stubs returning HTTP 410; do not rely on them.

## 5. Supabase Auth settings — preserve security, do not toggle globally
Do NOT turn off Confirm Email or Secure Email Change merely to overcome the issue:
- Confirm Email disabled implicitly confirms any email supplied and allows users to sign in without proof of mailbox ownership; Supabase explicitly warns that anyone could register using another person's address and that the 2/hour project mail limit is turned off. This is not required for the selected Admin API route.
- Secure Email Change only controls the end-user email-change confirmation path; disabling it reduces the old-address protection and is not needed when a server-side administrator updates a synthetic login alias.
- Keep public sign-up restrictions as currently configured until all account-provisioning paths in Parent and apps have been audited. `save-employee` is a privileged server route, but its existence alone does not prove that every provisioning path is server-controlled.
- Keep `verify_jwt=true` on the existing `save-settings` function.

Supabase documentation:
- Admin `updateUserById` applies changes directly without confirmation flows, and must only run on a server: https://supabase.com/docs/reference/javascript/auth-admin-updateuserbyid
- Supabase password-based auth accepts email/password identities: https://supabase.com/docs/guides/auth/passwords
- Confirm Email disabled implicitly trusts/auto-confirms email and removes the built-in hourly email cap but reduces identity proof: https://supabase.com/docs/guides/auth/testing-auth-flows
- Email change client flow sends confirmation by default: https://supabase.com/docs/reference/javascript/auth-updateuser

## 6. Exact owner changeset still required
Files/services:
- Existing frontend caller: `companies/company-1/main.html` (previously pinned retry guard commit `cbda0d4f910aa7b6992c965f076742b9c11fc757); caller currently uses client Auth email update.
- Existing backend: Supabase Edge Function `save-settings` Version 15 (reuse; do not create a new Edge Function).
- New narrowly scoped SQL function: `public.owner_email_sync_atomic` (must be inspected/implemented only after exact DDL review).
- Existing employee pattern reference: `save-employee` Version 10; do not change it.

Acceptance tests (no real email, SMS, inventory, finance, or business operation):
1. Mocked E2E for owner email alias update: no request to `/auth/v1/user` email-update client flow; exactly one authenticated `save-settings` owner action.
2. Owner gate rejects a non-owner, invalid metadata, missing owner_profile, inactive user, missing token, and wrong company.
3. Duplicate alias, malformed alias, stale old email, or DB RPC error cause Auth rollback and no public partial update.
4. Successful update preserves Auth UUID, user role, wildcard, permissions, license and session; all three emails match.
5. After session refresh, Core `RW_Auth.init()` and `owner_license_admin_atomic` continue to authorize correctly.
6. Employee account creation/change remains unchanged and still uses existing Admin API path.
7. Password reset by email is not invoked for synthetic aliases; logged-in password change and administrator reset paths are covered.
8. No outbound email/SMS call, no new Edge Function, no external provider, and zero cost.

## 7. Current disposition
- **CONFIRMED:** current email strings are fictitious test identifiers; user confirms no `rawaea.com` domain/mailboxes exist.
- **CONFIRMED:** current 429 is triggered by owner client-side email-change route, which requests email confirmation delivery.
- **CONFIRMED:** existing `save-employee` already uses no-mail Supabase Auth Admin create/update with `email_confirm=true`.
- **CONFIRMED:** existing `save-settings` provides an owner-verified server/service-role route that can host the surgical owner action.
- **CONFIRMED:** no existing SQL owner-email synchronization RPC exists; current Auth/public/owner_profile values are aligned.
- **SELECTED:** internal email-shaped aliases + password Auth; Admin API for owner alias updates; no SMTP/domain/SMS.
- **NOT IMPLEMENTED:** changes to `main.html`, `save-settings`, SQL RPC, account recovery UI, or Auth settings. No production mutation performed.
- **SUPERSEDES:** Report721 Brevo Free SMTP proposal; it is unnecessary for the current no-mail design.
- **OPEN:** exact review/implementation of owner alias synchronization and account-recovery behavior; comprehensive audit of every signup/provisioning path before any Auth global setting change.

**Next checkpoint:** prepare exact replacement of the owner-email handler to call an owner-gated action in existing `save-settings`, add the scoped atomic identity-sync RPC after full contract review, test with Auth/DB mocks, then verify a controlled synthetic alias change without generating mail and without changing business data.
