# Report723 — تنفيذ هوية المالك الداخلية وإلغاء مسارات تأكيد البريد

**التاريخ:** 2026-11-14 (Africa/Cairo)  
**Last Verified Event:** LVE-2026-11-14-723  
**Previous checkpoint:** LVE-2026-11-14-722  
**SMART ERP:** \`fiilmooggumokxanwiyx\` — ACTIVE_HEALTHY — eu-west-1  
**Operational repository:** \`papamohammed77-glitch/erp-frontend\` / \`main\`  
**Operational commit:** \`36a86359a0ba8d465eed2602cfefb590cd594c38\`  
**Supabase Edge Function:** \`save-settings\` v17 — ACTIVE — \`verify_jwt=true\`  
**Status:** OWNER INTERNAL-IDENTIFIER CHANGESET DEPLOYED + DATABASE RPC APPLIED + CI/REGRESSION TESTS PASS; LIVE OWNER CREDENTIAL CHANGE NOT EXECUTED; CLOUDflare PUBLICATION AND AUTH SECURITY-NOTIFICATION FLAGS NOT VERIFIED.

## 1. Executive result

The recurring Auth email quota failure was caused by the Parent owner form invoking \`supabase.auth.updateUser({email})\`, which starts the email-confirmation flow. That route has been removed from the owner credential screen.

Owner login identifiers are now treated as internal identifiers restricted to:
- \`@rawaea.com\`
- \`@alrawae.com\`

The implementation reuses the existing owner-gated \`save-settings\` Edge Function instead of adding another function. No domain, mailbox, SMTP account, SMS provider, or paid service was added. Global Auth confirmation/security settings were not modified.

## 2. Source changes committed

Operational commit: \`36a86359a0ba8d465eed2602cfefb590cd594c38\`.

| File | Change |
|---|---|
| \`companies/company-1/main.html\` | Owner credential panel now asks for current password, identifies email-shaped values as internal login aliases, restricts accepted domains, raises new-password minimum to 12 characters, and removes the Auth email-reset call. |
| \`supabase/functions/save-settings/index.ts\` | Source-of-truth copy of deployed v17; adds owner-only credential action within the existing JWT-verified server function. |
| \`supabase/migrations/20261114180000_owner_login_alias_sync_atomic.sql\` | Reproducible source for the already-applied owner alias synchronization function. |
| \`scripts/owner-login-alias-security.test.mjs\` | Seven automated security/source contract tests. |
| \`.github/workflows/owner_login_alias_security.yml\` | Runs the owner credential contract tests on relevant source changes and manual dispatch. |

The existing \`save-employee\` path was not changed.

## 3. Server-side security contract

The new \`owner-credentials\` action in \`save-settings\`:

1. Requires a valid bearer token; the deployed function still has \`verify_jwt=true\`.
2. Verifies the active public user, owner metadata, wildcard permission, matching \`owner_profile\`, and equality of Auth/public/profile login identifiers.
3. Requires a fresh sign-in within five minutes. The Parent explicitly re-authenticates using \`signInWithPassword\` and the current password before calling the Edge Function.
4. Accepts only one operation per request: internal alias update OR password update.
5. Uses server-side \`auth.admin.updateUserById\`; the browser never receives or uses the service-role key.
6. For alias changes, calls \`owner_login_alias_sync_atomic\` and compensates by restoring the previous Auth alias if database synchronization fails. If both synchronization and compensation fail, it returns a critical reconciliation error and does not report success.
7. For password changes, enforces 12–128 characters and records an audit event without storing the password or its hash in the audit log.
8. Does not change Auth UUID, role, permissions, company, license, stock, treasury, or accounting data.

Supabase documents that \`auth.admin.updateUserById\` applies changes directly without confirmation flows and is server-only:
https://supabase.com/docs/reference/javascript/auth-admin-updateuserbyid

## 4. Database RPC and privilege proof

Applied to SMART ERP:

\`public.owner_login_alias_sync_atomic(uuid,uuid,text,text,text)\`

The function:
- Requires the JWT role to be \`service_role\`.
- Locks the owner user and owner-profile rows.
- Serializes updates for the requested alias.
- Checks the active owner wildcard and all previous values before changing anything.
- Rejects aliases outside the two internal domains and detects duplicates.
- Updates exactly one \`public.users\` row and one linked \`public.owner_profile\` row.
- Writes an audit record in the same database transaction.
- Returns without DML when old and new values match.

Read-back privilege check after migration:

| Database role | EXECUTE |
|---|---|
| service_role | TRUE |
| authenticated | FALSE |
| anon | FALSE |

No grants were widened to application users.

## 5. Password reset and recovery boundary

The Parent no longer calls \`resetPasswordForEmail\`. The unauthenticated “account recovery” control now explains that synthetic login identifiers do not receive email and does not pretend to send a reset link.

The old \`owner-recover-gate-20260818-7f2d9c41\` remains a retired HTTP 410 endpoint; it was not reopened or weakened. Owner recovery when the current password is lost remains an administrator-controlled Supabase project recovery process. A self-service offline recovery-code issuance/consumption flow was not built in this changeset and remains OPEN for a separately tested security design. No recovery code was generated or stored.

## 6. Live checks and data safety

Read-only owner join after implementation still returned:
- Auth email = \`owner@alrawae.com\`
- \`public.users.email\` = \`owner@alrawae.com\`
- \`owner_profile.owner_email\` = \`owner@alrawae.com\`
- Same Auth UUID on both public links
- Status Active and public permissions \`["*"]\`

Alias regex check: accepts \`owner@alrawae.com\` and rejects a real external domain.

No live owner alias or password was changed. The current password was not requested or accessed. No test request was sent to Supabase Auth that could change the owner principal.

No inventory, treasury, cash, employee custody, supplier/customer balance, journal, or accounting data was inserted, updated, deleted, or posted. The production database change was a function definition and grants only; no business transaction or QA business row was created.

## 7. CI and regression evidence

All associated runs on commit \`36a86359a0ba8d465eed2602cfefb590cd594c38\` completed successfully:

- Owner Credential Security Contract — Run \`43624957462\` — SUCCESS (all seven Node tests).
- Parent full-file structural gate — Run \`43624957539\` — SUCCESS.
- Mother System Browser E2E — Run \`43624957467\` — SUCCESS.
- Mother Inventory Forensic E2E — Run \`43624957468\` — SUCCESS.
- Standalone Unified Warehouse E2E — Run \`43624957517\` — SUCCESS.

The owner contract test parses all inline Parent JavaScript and checks the new authorization/alias rules, current-password re-authentication, password length, service-role-only SQL grants, audit, rollback markers, and absence of the retired email-reset/client-email-change calls.

The browser and warehouse E2E workflows used their CI/local source fixtures; they did not execute a real owner credential mutation.

## 8. Explicitly UNVERIFIED / OPEN

1. **Cloudflare publication:** GitHub source and GitHub Actions are verified; a live Cloudflare Pages deployment serving this exact commit was not accessible through the connected tools. Do not assume the production URL is already serving this commit.
2. **Supabase security notification flags:** Supabase separates confirmation emails from optional project-level security notifications (email-changed/password-changed). The project-level notification toggles could not be read through the available project metadata tools and were deliberately not changed. Supabase documentation says these notification messages are controlled by project settings:
   https://supabase.com/docs/guides/auth/auth-email-templates
   Therefore, the new route does not request confirmation/reset email, but an absolute “zero notification email” claim remains UNVERIFIED until those project toggles are read.
3. **Live owner acceptance:** No current password was available to execute a real owner sign-in and credential mutation. The feature is deployed and automated contract/regression checks pass; successful change of the actual owner alias/password remains UNVERIFIED.
4. **Self-service owner recovery:** Recovery-code issuance/consumption remains OPEN; lost-password recovery is still through the trusted Supabase project administrator.

## 9. Decision / readiness

**READY FOR OWNER-INITIATED USE AFTER CONFIRMING CLOUDFLARE DEPLOYMENT AND AUTH SECURITY-NOTIFICATION SETTINGS.**

The repeated email-confirmation quota dependency is removed from the Parent owner alias/password workflow. Do not edit the current owner alias or password as a test. The owner should enter the existing current password only inside the secured Parent screen when intentionally changing credentials.

**No global Auth settings were disabled. No business balances or production business transactions were modified.**

---
