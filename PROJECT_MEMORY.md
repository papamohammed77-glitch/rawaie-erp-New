# SMART ERP — Daily Project Memory

This file is maintained as the project memory snapshot for the daily cross-system review.

## Sources
- GitHub repository: `papamohammed77-glitch/rawaie-erp-New`
- Supabase project: `SMART ERP` (`fiilmooggumokxanwiyx`)

## Purpose
Record, in one place, the important project state discovered during daily reviews: architecture, authentication, API/Edge Functions, database/RLS, deployments, recent code changes, risks, open items, and integration status.

## Current baseline
- SMART ERP Supabase project is active and healthy.
- GitHub repository is the source/recovery repository reviewed for the ERP application.
- Authentication flow uses Supabase Auth on the client and bearer JWTs for Edge Function requests.
- Edge Functions validate the presented user token server-side and map the authenticated user to the ERP `users` record/company context.
- ERP architecture separates UI from business truth; business capabilities are implemented in Core / Edge Functions / database RPCs according to repository architecture rules.
- Production authorization completeness remains an area to monitor, especially the full ERP-wide role/permission graph.

## Daily review protocol
1. Review recent GitHub commits, changed files, issues, pull requests, and workflow/CI results relevant to SMART ERP.
2. Review Supabase project health, Edge Functions, relevant logs, security/performance advisories, and schema/type changes.
3. Compare both sources and identify additions, removals, breaking changes, deployments, authentication/authorization changes, and unresolved risks.
4. Update this memory snapshot with only verified facts; do not invent missing state.
5. Preserve prior important context while appending a dated review section.

## Review history

### 2026-09-03
- Initial cross-system memory snapshot created.
- Supabase connectivity to SMART ERP verified from the connected integration.

### 2026-09-03 — Forensic CTO continuity verification
- Directly re-read `MASTER_CTO_UNIFIED_CONTINUITY_EXECUTION_GOLD_DIAMOND.md` in full through the repository API; its final command is a RECOVER → RECONCILE → FORENSICALLY VERIFY → CLASSIFY → SURGICALLY MODIFY → STATIC VERIFY → RUNTIME VERIFY → PRODUCTION CONTRACT VERIFY → GOLD → DIAMOND → PERSIST → UPDATE CURRENT_STATE → WRITE REPORT → RECHECK → CLOSE sequence.
- Directly verified `CURRENT_STATE.md` and `تقرير26.md`; both identify target-preserving P163 surgery as the next exact action and explicitly reject fragment-only reconstruction for persistence.
- Directly verified the active workflow `.github/workflows/_cto_close_newmain_20260903.yml`; it performs surgical P163 closure inside `Current/PWA/New-main`, runs Node syntax and browser smoke gates, then persists only after the gates pass.
- Supabase production checks were read-only. The current owner record has wildcard permissions `["*"]` and `owner_profile.license_status = active`; `users` and `owner_profile` both have RLS enabled. No production write was performed.
- Current GitHub `main` HEAD before this trigger was `30f1526fa8a926c638aa62bb63d9e88457f73670`.
- The present change exists solely to provide a new push trigger for the already-defined controlled executor; no ERP application source or production database was intentionally changed by this memory update.

### 2026-09-04 — Cross-system daily verification

#### GitHub direct evidence
- Repository `papamohammed77-glitch/rawaie-erp-New` is accessible and the default branch is `main`.
- Latest observed commits are documentation/continuity commits led by `085ac6e6fe08fe4ebf1b7dd2baa76a7eb03725f9`, `3b9b752e5fe046599d132e102e00c68bddc9d813`, and `705f7730f11cc87319b8be7d6abefe0a5c1e6c09`.
- `CURRENT_STATE.md` records the latest direct application-target change as commit `282cce040c51b2f4f926a8ca9227ef89ee742713`, with target blob `22f4ee1a666141be62127159337beffb05e8b146`; later commits are described there as continuity/documentation work.
- The current `Current/PWA/New-main` source visibly contains the Arabic RTL login shell, sidebar/main shell, company identity placeholders, password visibility control, manifest link `./manifest.json`, and the service-worker coordinator reference `./register-sw.js`.
- The latest queried combined commit status for `3b9b752e5fe046599d132e102e00c68bddc9d813` returned no status entries; this is not equivalent to a passing CI result.
- Open issue search returned older execution/continuity items including #64, #36, #25, and #26. Open/closed PR search returned historical closure/verifier PRs including #127, #126, #124, #125, #123, #122, #121, #120, #119, and #113. Their presence is recorded; no merge/closure claim is made here without a fresh per-PR status read.

#### Supabase direct evidence
- Project `SMART ERP` (`fiilmooggumokxanwiyx`) is `ACTIVE_HEALTHY`, region `eu-west-1`, database engine PostgreSQL 17.6.1.121.
- The project currently exposes a large active Edge Function surface. Observed business functions include item/customer/supplier/branch/employee/settings/role operations, sales and order operations, runsheet/picking/loading/delivery/return flows, stock-voucher flows, purchasing, accounting/reporting, and audit logging. Most observed business functions have `verify_jwt = true`.
- Separate historical/test or recovery-style functions also remain active with `verify_jwt = false`, including canary, fixture, runtime-E2E, and owner-recovery names. This is a confirmed surface-area risk requiring explicit lifecycle/authorization review; no deletion or deployment was performed.
- Edge-function logs show successful `log-action` POSTs with HTTP 200 and OPTIONS 204 on 2026-09-03, but also repeated HTTP 410 responses from `owner-recovery-20260818` across the same period. The 410s confirm a retired/expired recovery endpoint is still being called by some actor or test path.
- Security advisors currently report warnings for public execution of `SECURITY DEFINER` functions `public.create_item_with_opening_stock(...)` and `public.sync_company_main_branch_projection()`, plus disabled leaked-password protection in Supabase Auth.
- Performance advisors currently report unindexed foreign keys across multiple business tables, repeated RLS init-plan warnings where `auth.*()` / `current_setting()` are re-evaluated per row, multiple permissive policies on several tables, and a set of unused indexes. These are database-level findings, not New-main source changes.

#### Cross-source reconciliation
- No verified evidence in this run shows a new application-source change to `Current/PWA/New-main`; the latest direct target change remains the one recorded in `CURRENT_STATE.md`.
- GitHub continuity records state that `Current/PWA/New-main` is the sole current application target, while Supabase remains the authoritative backend for business operations. This matches the observed Edge Function surface and the repository’s no-islands architecture rules.
- The manifest contract is internally consistent in the current target/source pair observed today: `New-main` references `./manifest.json`, and repository records describe that manifest as the published manifest with `start_url = ./New-main`, `scope = ./`, `lang = ar`, and `dir = rtl`. No manifest merge or deletion was performed.
- Fresh Gold/Diamond status for the whole product is not asserted by this daily review. Current evidence is sufficient to record the project as healthy at the platform level but with open security, performance, retired-endpoint, CI-evidence, and product-completeness risks.

#### Verified open risks / follow-up
1. Review and constrain `SECURITY DEFINER` RPC execute grants for anonymous/authenticated roles where not intentionally public.
2. Enable leaked-password protection in Supabase Auth.
3. Triage repeated 410 calls to `owner-recovery-20260818`; identify the caller and remove or update the stale path.
4. Review all `verify_jwt = false` Edge Functions and classify each as intentionally public, test-only, or obsolete; retire obsolete functions.
5. Add/repair CI status visibility for the current head; an empty combined-status response is not a passing check.
6. Plan a controlled database-performance pass for missing FK indexes, RLS init-plan rewrites, duplicate permissive policies, and unused-index review.

## Current confidence boundary
- Confirmed directly in this run: repository/project identity, current Supabase health, current Edge Function inventory pattern, current advisory categories, current recent Edge Function log pattern, current New-main opening contract, and the latest observed GitHub commit/issue/PR search results.
- Not confirmed directly in this run: a fresh browser execution of the full New-main user journey, complete per-PR merge/status history, exact current production authentication success for a real user, and whole-system Gold/Diamond closure.

## Security
- Never store or reproduce secrets, private keys, access tokens, service-role keys, passwords, or user credentials in this file.
