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
