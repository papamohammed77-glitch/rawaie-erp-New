# Report721 — حل حصة بريد Supabase Auth دون تكلفة ثابتة
التاريخ: 2026-11-14 (Africa/Cairo)
Last Verified Event: LVE-2026-11-14-721
Previous checkpoint: LVE-2026-11-14-720
SMART ERP: fiilmooggumokxanwiyx — ACTIVE_HEALTHY — eu-west-1
Operational repo HEAD: 2fcccd240f5ce8acf53b438ac9ec7a65f54e11e0
Status: ROOT CAUSE CONFIRMED; ZERO-COST SMTP DESIGN SELECTED; NO PRODUCTION MUTATION; PRIVATE PROVIDER SETUP PENDING.

## 1. Executive finding
This is not storage exhaustion. Supabase Auth built-in SMTP currently allows 2 email sends per hour across the project. Deleting test records, Auth users, or audit logs does not refill the project email-send quota. The durable remedy is a custom SMTP provider or Send Email Hook, not data deletion.

Do not delete Auth logs, Auth users, public.users, owner_profile, or other QA records as a rate-limit remedy. Deletion does not reset the outbound-send bucket and may break auth-to-profile links, foreign keys, permissions, employee data, audit history, storage relationships, or business test evidence.

## 2. Live read-only evidence
Project fiilmooggumokxanwiyx returned ACTIVE_HEALTHY, region eu-west-1.

A read-only join of auth.users, public.users (by auth_id), and public.owner_profile (by auth_user_id) showed:
- Auth email = owner@alrawae.com; confirmed.
- email_change empty; email_change_sent_at NULL; email_change_confirm_status=0.
- banned_until NULL.
- public.users.email and owner_profile.owner_email both equal Auth email.
- public.users.auth_id and owner_profile.auth_user_id both match the Auth principal.
- Public user status Active; permissions ["*"]; owner license active.
- Last sign-in at read time: 2026-11-14 15:34:56.177887+00.

Counts:
- auth.users: 36.
- public.users: 32.
- public.users having auth_id: 31.
- public.users having NULL auth_id: 1.

The five Auth rows not counted among the 31 public links are NOT proven orphans; other links/roles need inspection. The one public row without an Auth link also needs identification and dependency tracing. These counts do not authorize deletion.

No delete, update, Auth email request, password change, DDL, RPC/Edge invocation, SMTP setting change, or business operation was performed.

## 3. Selected zero-cost design
Use Brevo Free as a custom SMTP relay for Supabase Auth only.

Current official Brevo Free terms:
- $0/month and no time limit.
- 300 email sends/day; quota resets daily and unused sends do not roll over.
- Free emails include “Sent with Brevo” branding.
- Transactional messages above the daily cap may be queued up to 1,000; this is not unlimited delivery.

SMTP relay configuration:
- Host: smtp-relay.brevo.com
- Port: 587
- Username: SMTP login shown in Brevo.
- Password: generated Brevo SMTP key, NOT the generic API key.
- A verified sending domain/sender and activated Transactional Email service are required. New accounts may need to ask Brevo to activate transactional sending.

Supabase custom SMTP starts with a low default of 30 emails/hour; it can be adjusted in Authentication > Rate Limits.

Recommended initial Supabase Auth email limit after verifying SMTP handoff: 10 emails/hour. This is conservative relative to the Brevo daily ceiling when sending steadily and retains abuse protection. It is a recommendation, not a promise of guaranteed delivery or unlimited free service.

Official references:
- Supabase SMTP: https://supabase.com/docs/guides/auth/auth-smtp
- Supabase Auth rate limits: https://supabase.com/docs/guides/auth/rate-limits
- Supabase hosted Auth test-flow limits: https://supabase.com/docs/guides/auth/testing-auth-flows
- Brevo Free limits: https://help.brevo.com/hc/en-us/articles/208580669-FAQs-What-are-the-limits-of-the-Free-plan
- Brevo SMTP relay: https://developers.brevo.com/docs/smtp-integration
- Brevo SMTP keys: https://help.brevo.com/hc/en-us/articles/7959631848850-Create-and-manage-your-SMTP-keys

## 4. Exact configuration contract
### Brevo
1. Create/retain the Free account.
2. Authenticate a domain controlled by the owner, using exactly the SPF/DKIM DNS records Brevo provides. Do not assume alrawae.com is controlled or use it until Brevo confirms domain ownership.
3. Create and verify a sender on the authenticated domain.
4. Ensure Transactional Email is activated.
5. Generate an SMTP key and keep it private. Never put it in Git, browser code, SQL, reports, or chat.

### Supabase Dashboard
Project: SMART ERP (fiilmooggumokxanwiyx).

Authentication > Emails > SMTP Settings:
- Enable Custom SMTP.
- Sender email: the verified Brevo sender.
- Sender name: RAWAEA ERP.
- Host: smtp-relay.brevo.com.
- Port: 587.
- Username: Brevo SMTP login.
- Password: Brevo SMTP key.

Authentication > Rate Limits:
- Set project email-send limit to 10/hour only after successful provider handoff.

Authentication > Sign In / Providers:
- Keep email confirmation enabled.
- Keep Secure Email Change enabled.
- Keep Auth auto-confirm disabled (mailer_autoconfirm=false).

Do not change Auth settings with direct SQL. Do not disable Secure Email Change to save one send. With Secure Email Change enabled, an email change deliberately sends a confirmation to both the existing and new addresses (two messages). This is an intentional security control.

## 5. Permanent testing/retry policy
- Automated browser tests mock Auth email actions and assert UI/handler contracts only; they never make repeated live email-update requests.
- Do not use actual owner email change as CI/E2E.
- Permit one deliberate live provider-delivery check to a mailbox controlled by the owner after SMTP setup. Verify Supabase Auth provider handoff/no 429 and Brevo transactional activity.
- After provider delivery succeeds, perform one owner email-change attempt only after the identity-sync issue below is resolved.
- Keep the existing frontend 429 retry guard. It prevents same-render duplicate attempts but does not replace server-side quota management.

## 6. Separate identity-sync risk — OPEN
Historical read-only investigation found no Production trigger synchronizing auth.users.email, public.users.email, and public.owner_profile.owner_email. Existing effective-profile and owner-license flows require those identities to remain aligned; save-settings reads Auth email and passes actor_email to a central RPC that expects public.users.email to match.

Current values are aligned, but after a confirmed email change they may diverge if there is no approved post-confirmation synchronization path. Therefore do not perform the actual owner email change immediately after SMTP setup. First review the current save-settings contract, Auth confirmation callback/event support, profile RPCs, and owner-license atomic RPC. Prepare an exact safe sync path that runs only after Supabase confirms the new address, is idempotent, fails closed, preserves the old identity if confirmation fails, and updates the three identity surfaces atomically where possible. This is a separate owner identity/authorization change requiring its own specific review and approval. No code or database change for this was made in this event.

## 7. Why SMTP activation was not completed by the assistant
Connected Supabase capabilities in this session permit project/database/log/function reads and database SQL, but expose no Auth project configuration write operation for SMTP credentials or rate limits. The connected browser surface is read-only. No Brevo account, verified sending domain, SMTP login/key, or DNS write access was available. The owner must enter the secret privately in the Brevo/Supabase dashboards; no secret was requested or stored.

This is a specific access/credential boundary, not an unresolved diagnosis.

## 8. Status
- CONFIRMED: quota is project-wide built-in SMTP rate limiting, not database/storage fullness.
- CONFIRMED: owner email/profile records remain aligned; no pending email change.
- CONFIRMED: deleting records does not solve the quota and is unsafe without dependency mapping.
- SELECTED: Brevo Free custom SMTP with 10/hour initial Auth limit, subject to domain verification and transactional activation.
- NOT EXECUTED: provider setup, Supabase Auth SMTP config, or rate-limit setting.
- OPEN: identity synchronization after a real verified email change.
- UNCHANGED: operational source, parent auth code except the previously pinned 429 retry guard, Supabase schema/data, permissions, stock, treasury, supplier/customer balances, custody, and journal entries.

Next checkpoint: owner privately activates Brevo Free, authenticates a domain, creates a sender and SMTP key, enters SMTP values in Supabase Dashboard; then verify provider handoff from logs without disclosing the key. Review and close identity synchronization before one controlled owner email-change verification.
