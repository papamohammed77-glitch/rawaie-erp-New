# RAWAEA ERP — HYTHAM NEW-MAIN CLEAN-ROOM VERIFICATION

Date: 2026-08-31
Role: Hytham
Authority: Production SMART ERP > current Git main > current application files > historical evidence

## Scope
This evidence records the execution of `FINAL_MAIN_HTML_RECONSTRUCTION_COMMAND.md` against the explicitly required target:

`Current/PWA/New-main`

The existing `Current/PWA/main.html` was not used as a write target and was not modified.

## Memory / Continuity
- `doc/Draft/medhat/تقرير +برومبت 117-02` was read.
- `CURRENT_STATE.md` was read before reconstruction.
- `FINAL_MAIN_HTML_RECONSTRUCTION_COMMAND.md` was read in full.
- `CURRENT_STATE.md` was treated as operational state, not as historical authority.
- Historical reports were not used as proof of current runtime state.

## Current Production Facts Used
The current Production project is SMART ERP `fiilmooggumokxanwiyx`.
The current state baseline used during this execution identified one company and current tenant-scoped operational data. Current PostgreSQL/Edge contracts were inspected directly before reconstruction.

## Clean-room Candidate
Target:
`Current/PWA/New-main`

Final Git blob SHA after the self-audit correction:
`744c38a561fb414c35e92b6a0bd526c9c9ca8461`

Final commit:
`b83bbe6cb0b90277eb6f05b39c1ba53b0cdf0489`

## Candidate Design Decisions
- Authentication uses the current Supabase Auth client.
- Company context is resolved from `public.users.auth_id`.
- Company-scoped reads use the resolved `company_id`.
- Owner semantics retain the current metadata-based signals (`isOwner` / owner roles / wildcard permissions) without replacing them with a newly invented policy model.
- Physical stock is read-only in New-main; there is no stock mutation path in the candidate.
- Financial tables are read-only in New-main; no direct journal/ledger/treasury mutation path exists in the candidate.
- Business write actions are delegated to existing specialized PWAs/Edge/Core owners rather than duplicated in New-main.
- The Service Worker is integrated through the existing `register-sw.js` contract.

## Self-Audit Findings
### Corrected during execution
The first candidate write contained malformed/incomplete Supabase client key text. This was detected by reviewing the persisted candidate and was corrected immediately.

### Final checks
- Supabase public client key matches the current repository `Current/PWA/core.js` contract.
- Candidate uses `public.users.auth_id` for company identity.
- Candidate does not use `user_metadata.company_id` as the company source of truth.
- Candidate does not hard-code account UUIDs.
- Candidate does not contain direct financial DML.
- Candidate does not contain direct stock mutation DML.
- The corrective commit diff was confined to `Current/PWA/New-main`.
- No replacement of `Current/PWA/main.html` was performed.

## Important Evidence Boundary
This artifact proves the existence and content of the clean-room Candidate and the static code-boundary checks described above.

It does NOT claim:
- browser smoke PASS;
- authenticated Production HTTP E2E PASS;
- Service Worker runtime PASS;
- full historical functional parity PASS;
- complete feature parity PASS;
- Production runtime certification;
- authorization to replace `Current/PWA/main.html`.

## Current Closure
`NEW-MAIN CANDIDATE = VERIFIED AS A GIT ARTIFACT`
`STRUCTURAL PARITY = OPEN`
`FUNCTIONAL PARITY = OPEN`
`PRODUCTION RUNTIME = OPEN`
`MAIN.HTML REPLACEMENT = NOT AUTHORIZED`

## Next Authorized Action
Use the Candidate as the reviewable reconstruction artifact. Continue only with evidence-backed structural/functional/runtime verification. Do not modify `Current/PWA/main.html` unless all gates in `FINAL_MAIN_HTML_RECONSTRUCTION_COMMAND.md` are actually proven.
